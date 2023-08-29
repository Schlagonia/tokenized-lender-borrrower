/// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import {IStrategyInterface} from "./interfaces/IStrategyInterface.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {CometStructs} from "./interfaces/Compound/V3/CompoundV3.sol";
import {Comet} from "./interfaces/Compound/V3/CompoundV3.sol";
import {CometRewards} from "./interfaces/Compound/V3/CompoundV3.sol";

/**
 * @notice This contract abstracts interactions with Compound V3 protocol, streamlining operations for the main Strategy
 * @dev The Depositor performs several functions:
 *      - Holds and deposits base tokens into Comet, allowing the Strategy to withdraw when repaying debt
 *      - Claims reward tokens from Comet
 *      - Provides view functions for estimating supply, borrow, and reward APRs
 *      - Handles the clone logic, being initially deployed via a Factory and subsequently cloned for each Strategy
 */
contract Depositor {
    using SafeERC20 for ERC20;

    /// Used for cloning
    bool public original = true;

    /// Used for COMP APR calculations
    uint64 internal constant DAYS_PER_YEAR = 365;
    uint64 internal constant SECONDS_PER_DAY = 60 * 60 * 24;
    uint64 internal constant SECONDS_PER_YEAR = 365 days;

    /// Price feeds for the reward apr calculation, can be updated manually if needed
    address public rewardTokenPriceFeed;
    address public baseTokenPriceFeed;

    /// Scaler used in reward apr calculations
    uint256 internal SCALER;

    /// This is the address of the main V3 pool
    Comet public comet;
    /// This is the token we will be borrowing/supplying
    ERC20 public baseToken;
    /// The contract to get rewards from
    CometRewards public constant rewardsContract = CometRewards(0x45939657d1CA34A8FA39A924B71D28Fe8431e581);

    IStrategyInterface public strategy;

    /// The reward token.
    address internal rewardToken;

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

    /**
     * @notice Clones the depositor contract for a new strategy
     * @param _comet The address of the Compound market
     * @return newDepositor The address of the cloned depositor contract
     */
    function cloneDepositor(address _comet) external returns (address newDepositor) {
        require(original, "!original");
        newDepositor = _clone(_comet);
    }

    function _clone(address _comet) internal returns (address newDepositor) {
        /// Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            /// EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newDepositor := create(0, clone_code, 0x37)
        }

        Depositor(newDepositor).initialize(_comet);
        emit Cloned(newDepositor);
    }

    /**
     * @notice Initializes the depositor after cloning
     * @param _comet The address of the Compound market
     */
    function initialize(address _comet) public {
        require(address(comet) == address(0), "!initiliazed");
        comet = Comet(_comet);
        baseToken = ERC20(comet.baseToken());

        baseToken.safeApprove(_comet, type(uint256).max);

        rewardToken = rewardsContract.rewardConfig(_comet).token;

        /// For APR calculations
        uint256 BASE_MANTISSA = comet.baseScale();
        uint256 BASE_INDEX_SCALE = comet.baseIndexScale();

        /// Adjusts reward rate for APR calculations, accounting for decimal differences between reward and base tokens.
        SCALER = (BASE_MANTISSA * 1e18) / BASE_INDEX_SCALE;

        /// Default to the base token feed given
        baseTokenPriceFeed = comet.baseTokenPriceFeed();

        /// Default to the COMP/USD feed
        rewardTokenPriceFeed = 0x2A8758b7257102461BC958279054e372C2b1bDE6;
    }

    /**
     * @notice Sets the linked strategy contract
     * @param _strategy The address of the strategy contract
     */
    function setStrategy(address _strategy) external {
        /// Can only set the strategy once
        require(address(strategy) == address(0), "set");

        strategy = IStrategyInterface(_strategy);

        /// Make sure it has the same base token
        require(address(baseToken) == strategy.baseToken(), "!base");
        /// Make sure this contract is set as the depositor
        require(address(this) == address(strategy.depositor()), "!depositor");
    }

    /**
     * @notice Allows management to update price feed addresses
     * @param _baseTokenPriceFeed New base token price feed address
     * @param _rewardTokenPriceFeed New reward token price feed address
     */
    function setPriceFeeds(address _baseTokenPriceFeed, address _rewardTokenPriceFeed) external onlyManagement {
        /// Just check the call doesnt revert. We dont care about the amount returned
        comet.getPrice(_baseTokenPriceFeed);
        comet.getPrice(_rewardTokenPriceFeed);
        baseTokenPriceFeed = _baseTokenPriceFeed;
        rewardTokenPriceFeed = _rewardTokenPriceFeed;
    }

    /**
     * @notice Returns the Compound market balance for this depositor
     * @return The Compound market balance
     */
    function cometBalance() external view returns (uint256) {
        return comet.balanceOf(address(this));
    }

    /**
     * @notice Non-view function to accrue account for the most accurate accounting
     * @return The Compound market balance including accrued interest
     */
    function accruedCometBalance() public returns (uint256) {
        comet.accrueAccount(address(this));
        return comet.balanceOf(address(this));
    }

    /**
     * @notice Withdraws tokens from the Compound market
     * @param _amount The amount of tokens to withdraw
     */
    function withdraw(uint256 _amount) external onlyStrategy {
        if (_amount == 0) return;
        ERC20 _baseToken = baseToken;

        comet.withdraw(address(_baseToken), _amount);

        uint256 balance = _baseToken.balanceOf(address(this));
        require(balance >= _amount, "!bal");
        _baseToken.safeTransfer(address(strategy), balance);
    }

    /**
     * @notice Deposits tokens into the Compound market
     */
    function deposit() external onlyStrategy {
        ERC20 _baseToken = baseToken;
        /// msg.sender has been checked to be strategy
        uint256 _amount = _baseToken.balanceOf(msg.sender);
        if (_amount == 0) return;

        _baseToken.safeTransferFrom(msg.sender, address(this), _amount);
        comet.supply(address(_baseToken), _amount);
    }

    /**
     * @notice Claims accrued reward tokens from the Compound market
     */
    function claimRewards() external onlyStrategy {
        rewardsContract.claim(address(comet), address(this), true);

        uint256 rewardTokenBalance = ERC20(rewardToken).balanceOf(address(this));

        if (rewardTokenBalance > 0) {
            ERC20(rewardToken).safeTransfer(address(strategy), rewardTokenBalance);
        }
    }

    /// ----------------- COMET VIEW FUNCTIONS -----------------

    /// We put these in the depositor contract to save byte code in the main strategy

    /**
     * @notice Calculates accrued reward tokens due to this contract and the base strategy
     * @return The amount of accrued reward tokens
     */
    function getRewardsOwed() external view returns (uint256) {
        CometStructs.RewardConfig memory config = rewardsContract.rewardConfig(address(comet));
        uint256 accrued = comet.baseTrackingAccrued(address(this)) + comet.baseTrackingAccrued(address(strategy));
        if (config.shouldUpscale) {
            accrued *= config.rescaleFactor;
        } else {
            accrued /= config.rescaleFactor;
        }
        uint256 claimed = rewardsContract.rewardsClaimed(address(comet), address(this))
            + rewardsContract.rewardsClaimed(address(comet), address(strategy));

        return accrued > claimed ? accrued - claimed : 0;
    }

    /**
     * @notice Estimates net borrow APR with a given supply amount
     * @param newAmount The amount to supply
     * @return netApr The estimated net borrow APR
     */
    function getNetBorrowApr(uint256 newAmount) public view returns (uint256 netApr) {
        uint256 newUtilization = ((comet.totalBorrow() + newAmount) * 1e18) / (comet.totalSupply() + newAmount);
        uint256 borrowApr = getBorrowApr(newUtilization);
        uint256 supplyApr = getSupplyApr(newUtilization);
        /// Supply rate can be higher than borrow when utilization is very high
        netApr = borrowApr > supplyApr ? borrowApr - supplyApr : 0;
    }

    /**
     * @notice Gets supply APR with a given utilization ratio
     * @param newUtilization The utilization ratio
     * @return The supply APR
     */
    function getSupplyApr(uint256 newUtilization) public view returns (uint256) {
        unchecked {
            return comet.getSupplyRate(
                newUtilization /// New utilization
            ) * SECONDS_PER_YEAR;
        }
    }

    /**
     * @notice Gets borrow APR with a given utilization ratio
     * @param newUtilization The utilization ratio
     * @return The borrow APR
     */
    function getBorrowApr(uint256 newUtilization) public view returns (uint256) {
        unchecked {
            return comet.getBorrowRate(
                newUtilization /// New utilization
            ) * SECONDS_PER_YEAR;
        }
    }

    /**
     * @notice Gets net reward APR with a given supply amount
     * @param newAmount The amount to supply
     * @return The net reward APR
     */
    function getNetRewardApr(uint256 newAmount) public view returns (uint256) {
        unchecked {
            return getRewardAprForBorrowBase(newAmount) + getRewardAprForSupplyBase(newAmount);
        }
    }

    /**
     * @notice Gets reward APR for supplying with a given amount
     * @param newAmount The new amount to supply
     * @return The reward APR in USD as a decimal scaled up by 1e18
     */
    function getRewardAprForSupplyBase(uint256 newAmount) public view returns (uint256) {
        unchecked {
            uint256 rewardToSuppliersPerDay = comet.baseTrackingSupplySpeed() * SECONDS_PER_DAY * SCALER;
            if (rewardToSuppliersPerDay == 0) return 0;
            return (
                (comet.getPrice(rewardTokenPriceFeed) * rewardToSuppliersPerDay)
                    / ((comet.totalSupply() + newAmount) * comet.getPrice(baseTokenPriceFeed))
            ) * DAYS_PER_YEAR;
        }
    }

    /**
     * @notice Gets reward APR for borrowing with a given amount
     * @param newAmount The new amount to borroww
     * @return The reward APR in USD as a decimal scaled up by 1e18
     */
    function getRewardAprForBorrowBase(uint256 newAmount) public view returns (uint256) {
        /// borrowBaseRewardApr = (rewardTokenPriceInUsd * rewardToBorrowersPerDay / (baseTokenTotalBorrow * baseTokenPriceInUsd)) * DAYS_PER_YEAR;
        unchecked {
            uint256 rewardToBorrowersPerDay = comet.baseTrackingBorrowSpeed() * SECONDS_PER_DAY * SCALER;
            if (rewardToBorrowersPerDay == 0) return 0;
            return (
                (comet.getPrice(rewardTokenPriceFeed) * rewardToBorrowersPerDay)
                    / ((comet.totalBorrow() + newAmount) * comet.getPrice(baseTokenPriceFeed))
            ) * DAYS_PER_YEAR;
        }
    }

    /**
     * @notice Allows management to manually withdraw funds
     * @param _amount The amount of tokens to withdraw
     */
    function manualWithdraw(uint256 _amount) external onlyManagement {
        if (_amount != 0) {
            /// Withdraw directly from the comet
            comet.withdraw(address(baseToken), _amount);
        }
        /// Transfer the full loose balance to the strategy
        baseToken.safeTransfer(address(strategy), baseToken.balanceOf(address(this)));
    }
}
