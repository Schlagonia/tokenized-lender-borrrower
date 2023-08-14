// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;
pragma experimental ABIEncoderV2;

import {IStrategyInterface} from "./interfaces/IStrategyInterface.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {CometStructs} from "./interfaces/Compound/V3/CompoundV3.sol";
import {Comet} from "./interfaces/Compound/V3/CompoundV3.sol";
import {CometRewards} from "./interfaces/Compound/V3/CompoundV3.sol";

contract Depositer {
    using SafeERC20 for ERC20;
    //Used for cloning
    bool public original = true;

    //Used for Comp apr calculations
    uint64 internal constant DAYS_PER_YEAR = 365;
    uint64 internal constant SECONDS_PER_DAY = 60 * 60 * 24;
    uint64 internal constant SECONDS_PER_YEAR = 365 days;

    // price feeds for the reward apr calculation, can be updated manually if needed
    address public rewardTokenPriceFeed;
    address public baseTokenPriceFeed;

    // scaler used in reward apr calculations
    uint256 internal SCALER;

    // This is the address of the main V3 pool
    Comet public comet;
    // This is the token we will be borrowing/supplying
    ERC20 public baseToken;
    // The contract to get Comp rewards from
    CometRewards public constant rewardsContract =
        CometRewards(0x1B0e765F6224C21223AeA2af16c1C46E38885a40);

    IStrategyInterface public strategy;

    //The reward Token
    address internal constant comp = 0xc00e94Cb662C3520282E6f5717214004A7f26888;

    modifier onlyManagement() {
        checkManagement();
        _;
    }

    modifier onlyStrategy() {
        checkStrategy();
        _;
    }

    function checkManagement() internal view {
        require(msg.sender == strategy.management(), "!authorized");
    }

    function checkStrategy() internal view {
        require(msg.sender == address(strategy), "!authorized");
    }

    event Cloned(address indexed clone);

    function cloneDepositer(
        address _comet
    ) external returns (address newDepositer) {
        require(original, "!original");
        newDepositer = _clone(_comet);
    }

    function _clone(address _comet) internal returns (address newDepositer) {
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(
                clone_code,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(
                add(clone_code, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            newDepositer := create(0, clone_code, 0x37)
        }

        Depositer(newDepositer).initialize(_comet);
        emit Cloned(newDepositer);
    }

    function initialize(address _comet) public {
        require(address(comet) == address(0), "!initiliazd");
        comet = Comet(_comet);
        baseToken = ERC20(comet.baseToken());

        baseToken.safeApprove(_comet, type(uint256).max);

        //For APR calculations
        uint256 BASE_MANTISSA = comet.baseScale();
        uint256 BASE_INDEX_SCALE = comet.baseIndexScale();

        // this is needed for reward apr calculations based on decimals of Asset
        // we scale rewards per second to the base token decimals and diff between comp decimals and the index scale
        SCALER = (BASE_MANTISSA * 1e18) / BASE_INDEX_SCALE;

        // default to the base token feed given
        baseTokenPriceFeed = comet.baseTokenPriceFeed();
        // default to the COMP/USD feed
        rewardTokenPriceFeed = 0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5;
    }

    function setStrategy(address _strategy) external {
        // Can only set the strategy once
        require(address(strategy) == address(0), "set");

        strategy = IStrategyInterface(_strategy);

        // make sure it has the same base token
        require(address(baseToken) == strategy.baseToken(), "!base");
        // Make sure this contract is set as the depositer
        require(address(this) == address(strategy.depositer()), "!depositer");
    }

    function setPriceFeeds(
        address _baseTokenPriceFeed,
        address _rewardTokenPriceFeed
    ) external onlyManagement {
        // just check the call doesnt revert. We dont care about the amount returned
        comet.getPrice(_baseTokenPriceFeed);
        comet.getPrice(_rewardTokenPriceFeed);
        baseTokenPriceFeed = _baseTokenPriceFeed;
        rewardTokenPriceFeed = _rewardTokenPriceFeed;
    }

    function cometBalance() external view returns (uint256) {
        return comet.balanceOf(address(this));
    }

    // Non-view function to accrue account for the most accurate accounting
    function accruedCometBalance() public returns (uint256) {
        comet.accrueAccount(address(this));
        return comet.balanceOf(address(this));
    }

    function withdraw(uint256 _amount) external onlyStrategy {
        if (_amount == 0) return;
        ERC20 _baseToken = baseToken;

        comet.withdraw(address(_baseToken), _amount);

        uint256 balance = _baseToken.balanceOf(address(this));
        require(balance >= _amount, "!bal");
        _baseToken.safeTransfer(address(strategy), balance);
    }

    function deposit() external onlyStrategy {
        ERC20 _baseToken = baseToken;
        // msg.sender has been checked to be strategy
        uint256 _amount = _baseToken.balanceOf(msg.sender);
        if (_amount == 0) return;

        _baseToken.safeTransferFrom(msg.sender, address(this), _amount);
        comet.supply(address(_baseToken), _amount);
    }

    function claimRewards() external onlyStrategy {
        rewardsContract.claim(address(comet), address(this), true);

        uint256 compBal = ERC20(comp).balanceOf(address(this));

        if (compBal > 0) {
            ERC20(comp).safeTransfer(address(strategy), compBal);
        }
    }

    // ----------------- COMET VIEW FUNCTIONS -----------------

    // We put these in the depositer contract to save byte code in the main strategy \\

    /*
     * Gets the amount of reward tokens due to this contract and the base strategy
     */
    function getRewardsOwed() external view returns (uint256) {
        CometStructs.RewardConfig memory config = rewardsContract.rewardConfig(
            address(comet)
        );
        uint256 accrued = comet.baseTrackingAccrued(address(this)) +
            comet.baseTrackingAccrued(address(strategy));
        if (config.shouldUpscale) {
            accrued *= config.rescaleFactor;
        } else {
            accrued /= config.rescaleFactor;
        }
        uint256 claimed = rewardsContract.rewardsClaimed(
            address(comet),
            address(this)
        ) + rewardsContract.rewardsClaimed(address(comet), address(strategy));

        return accrued > claimed ? accrued - claimed : 0;
    }

    function getNetBorrowApr(
        uint256 newAmount
    ) public view returns (uint256 netApr) {
        uint256 newUtilization = ((comet.totalBorrow() + newAmount) * 1e18) /
            (comet.totalSupply() + newAmount);
        uint256 borrowApr = getBorrowApr(newUtilization);
        uint256 supplyApr = getSupplyApr(newUtilization);
        // supply rate can be higher than borrow when utilization is very high
        netApr = borrowApr > supplyApr ? borrowApr - supplyApr : 0;
    }

    /*
     * Get the current supply APR in Compound III
     */
    function getSupplyApr(
        uint256 newUtilization
    ) public view returns (uint256) {
        unchecked {
            return
                comet.getSupplyRate(
                    newUtilization // New utilization
                ) * SECONDS_PER_YEAR;
        }
    }

    /*
     * Get the current borrow APR in Compound III
     */
    function getBorrowApr(
        uint256 newUtilization
    ) public view returns (uint256) {
        unchecked {
            return
                comet.getBorrowRate(
                    newUtilization // New utilization
                ) * SECONDS_PER_YEAR;
        }
    }

    function getNetRewardApr(uint256 newAmount) public view returns (uint256) {
        unchecked {
            return
                getRewardAprForBorrowBase(newAmount) +
                getRewardAprForSupplyBase(newAmount);
        }
    }

    /*
     * Get the current reward for supplying APR in Compound III
     * @param newAmount The new amount we will be supplying
     * @return The reward APR in USD as a decimal scaled up by 1e18
     */
    function getRewardAprForSupplyBase(
        uint256 newAmount
    ) public view returns (uint256) {
        Comet _comet = comet;
        unchecked {
            uint256 rewardToSuppliersPerDay = _comet.baseTrackingSupplySpeed() *
                SECONDS_PER_DAY *
                SCALER;
            if (rewardToSuppliersPerDay == 0) return 0;
            return
                ((_comet.getPrice(rewardTokenPriceFeed) *
                    rewardToSuppliersPerDay) /
                    ((_comet.totalSupply() + newAmount) *
                        _comet.getPrice(baseTokenPriceFeed))) * DAYS_PER_YEAR;
        }
    }

    /*
     * Get the current reward for borrowing APR in Compound III
     * @param newAmount The new amount we will be borrowing
     * @return The reward APR in USD as a decimal scaled up by 1e18
     */
    function getRewardAprForBorrowBase(
        uint256 newAmount
    ) public view returns (uint256) {
        // borrowBaseRewardApr = (rewardTokenPriceInUsd * rewardToBorrowersPerDay / (baseTokenTotalBorrow * baseTokenPriceInUsd)) * DAYS_PER_YEAR;
        Comet _comet = comet;
        unchecked {
            uint256 rewardToBorrowersPerDay = _comet.baseTrackingBorrowSpeed() *
                SECONDS_PER_DAY *
                SCALER;
            if (rewardToBorrowersPerDay == 0) return 0;
            return
                ((_comet.getPrice(rewardTokenPriceFeed) *
                    rewardToBorrowersPerDay) /
                    ((_comet.totalBorrow() + newAmount) *
                        _comet.getPrice(baseTokenPriceFeed))) * DAYS_PER_YEAR;
        }
    }

    function manualWithdraw() external onlyManagement {
        // Withdraw everything we have
        comet.withdraw(address(baseToken), accruedCometBalance());
    }
}
