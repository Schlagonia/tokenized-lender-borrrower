// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import {BaseTokenizedStrategy} from "@tokenized-strategy/BaseTokenizedStrategy.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {CometStructs} from "./interfaces/Compound/V3/CompoundV3.sol";
import {Comet} from "./interfaces/Compound/V3/CompoundV3.sol";
import {CometRewards} from "./interfaces/Compound/V3/CompoundV3.sol";

// Uniswap V3 Swapper
import {UniswapV3Swapper} from "@periphery/swappers/UniswapV3Swapper.sol";

import {Depositer} from "./Depositer.sol";

interface IBaseFeeGlobal {
    function basefee_global() external view returns (uint256);
}

contract Strategy is BaseTokenizedStrategy, UniswapV3Swapper {
    using SafeERC20 for ERC20;

    // If set to true, the strategy will not try to repay debt by selling rewards or asset.
    bool public leaveDebtBehind;

    // The address of the main V3 pool.
    Comet public immutable comet;
    // The token we will be borrowing/supplying.
    address public immutable baseToken;
    // The contract to get Comp rewards from.
    CometRewards public constant rewardsContract =
        CometRewards(0x1B0e765F6224C21223AeA2af16c1C46E38885a40);

    // The Contract that will deposit the baseToken back into Compound
    Depositer public immutable depositer;

    // The reward Token
    address internal immutable rewardToken;

    // mapping of price feeds. Management can customize if needed
    mapping(address => address) public priceFeeds;

    // NOTE: LTV = Loan-To-Value = debt/collateral
    // Target LTV: ratio up to which which we will borrow up to liquidation threshold
    uint16 public targetLTVMultiplier = 7_000;

    // Warning LTV: ratio at which we will repay
    uint16 public warningLTVMultiplier = 8_000; // 80% of liquidation LTV

    uint16 internal constant MAX_BPS = 10_000; // 100%

    //Thresholds
    uint256 internal immutable minThreshold;

    // The max the base fee will be for a tend.
    uint256 public maxGasPriceToTend = 70 * 1e9;

    constructor(
        address _asset,
        string memory _name,
        address _comet,
        uint24 _ethToAssetFee,
        address _depositer
    ) BaseTokenizedStrategy(_asset, _name) {
        comet = Comet(_comet);

        //Get the baseToken we wil borrow and the min
        baseToken = comet.baseToken();
        minThreshold = comet.baseBorrowMin();

        depositer = Depositer(_depositer);
        require(baseToken == address(depositer.baseToken()), "!base");

        // Set the rewardToken token we will get.
        rewardToken = rewardsContract.rewardConfig(_comet).token;

        // to supply asset as collateral
        ERC20(asset).safeApprove(_comet, type(uint256).max);
        // to repay debt
        ERC20(baseToken).safeApprove(_comet, type(uint256).max);
        // for depositer to pull funds to deposit
        ERC20(baseToken).safeApprove(_depositer, type(uint256).max);
        // to sell reward tokens
        ERC20(rewardToken).safeApprove(address(router), type(uint256).max);

        // Set the needed variables for the Uni Swapper
        // Base will be weth.
        base = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        // UniV3 mainnet router.
        router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        // Set the min amount for the swapper to sell
        minAmountToSell = 1e10;

        //Default to .3% pool for comp/eth and to .05% pool for eth/baseToken
        _setFees(3000, 500, _ethToAssetFee);

        // set default price feeds
        priceFeeds[baseToken] = comet.baseTokenPriceFeed();
        // default to COMP/USD
        priceFeeds[rewardToken] = 0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5;
        // default to given feed for asset
        priceFeeds[asset] = comet.getAssetInfoByAddress(asset).priceFeed;
    }

    // ----------------- SETTERS -----------------
    // we put all together to save contract bytecode (!)
    function setStrategyParams(
        uint16 _targetLTVMultiplier,
        uint16 _warningLTVMultiplier,
        uint256 _minToSell,
        bool _leaveDebtBehind,
        uint256 _maxGasPriceToTend
    ) external onlyManagement {
        require(
            _warningLTVMultiplier <= 9_000 &&
                _targetLTVMultiplier < _warningLTVMultiplier
        );
        targetLTVMultiplier = _targetLTVMultiplier;
        warningLTVMultiplier = _warningLTVMultiplier;
        minAmountToSell = _minToSell;
        leaveDebtBehind = _leaveDebtBehind;
        maxGasPriceToTend = _maxGasPriceToTend;
    }

    function setPriceFeed(
        address _token,
        address _priceFeed
    ) external onlyManagement {
        // just check it doesnt revert
        comet.getPrice(_priceFeed);
        priceFeeds[_token] = _priceFeed;
    }

    function setFees(
        uint24 _rewardToEthFee,
        uint24 _ethToBaseFee,
        uint24 _ethToAssetFee
    ) external onlyManagement {
        _setFees(_rewardToEthFee, _ethToBaseFee, _ethToAssetFee);
    }

    function _setFees(
        uint24 _rewardToEthFee,
        uint24 _ethToBaseFee,
        uint24 _ethToAssetFee
    ) internal {
        address _weth = base;
        _setUniFees(rewardToken, _weth, _rewardToEthFee);
        _setUniFees(baseToken, _weth, _ethToBaseFee);
        _setUniFees(asset, _weth, _ethToAssetFee);
    }

    /*//////////////////////////////////////////////////////////////
                NEEDED TO BE OVERRIDEN BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Should deploy up to '_amount' of 'asset' in the yield source.
     *
     * This function is called at the end of a {deposit} or {mint}
     * call. Meaning that unless a whitelist is implemented it will
     * be entirely permsionless and thus can be sandwhiched or otherwise
     * manipulated.
     *
     * @param _amount The amount of 'asset' that the strategy should attemppt
     * to deposit in the yield source.
     */
    function _deployFunds(uint256 _amount) internal override {
        _leveragePosition(_amount);
    }

    /**
     * @dev Will attempt to free the '_amount' of 'asset'.
     *
     * The amount of 'asset' that is already loose has already
     * been accounted for.
     *
     * This function is called during {withdraw} and {redeem} calls.
     * Meaning that unless a whitelist is implemented it will be
     * entirely permsionless and thus can be sandwhiched or otherwise
     * manipulated.
     *
     * Should not rely on asset.balanceOf(address(this)) calls other than
     * for diff accounting puroposes.
     *
     * Any difference between `_amount` and what is actually freed will be
     * counted as a loss and passed on to the withdrawer. This means
     * care should be taken in times of illiquidity. It may be better to revert
     * if withdraws are simply illiquid so not to realize incorrect losses.
     *
     * @param _amount, The amount of 'asset' to be freed.
     */
    function _freeFunds(uint256 _amount) internal override {
        _liquidatePosition(_amount);
    }

    /**
     * @dev Internal function to harvest all rewards, redeploy any idle
     * funds and return an accurate accounting of all funds currently
     * held by the Strategy.
     *
     * This should do any needed harvesting, rewards selling, accrual,
     * redepositing etc. to get the most accurate view of current assets.
     *
     * NOTE: All applicable assets including loose assets should be
     * accounted for in this function.
     *
     * Care should be taken when relying on oracles or swap values rather
     * than actual amounts as all Strategy profit/loss accounting will
     * be done based on this returned value.
     *
     * This can still be called post a shutdown, a strategist can check
     * `TokenizedStrategy.isShutdown()` to decide if funds should be
     * redeployed or simply realize any profits/losses.
     *
     * @return _totalAssets A trusted and accurate account for the total
     * amount of 'asset' the strategy currently holds including idle funds.
     */
    function _harvestAndReport()
        internal
        override
        returns (uint256 _totalAssets)
    {
        if (!TokenizedStrategy.isShutdown()) {
            // 1. claim rewards, 2. even baseToken deposits and borrows 3. sell remainder of rewards to asset.
            // This will accrue this account as well as the depositer so all future calls are accurate
            _claimAndSellRewards();

            // Leverage all the asset we have or up to the supply cap.
            // We want check our leverage even if balance of asset is 0.
            _leveragePosition(
                Math.min(balanceOfAsset(), availableDepositLimit(address(this)))
            );
        } else {
            // Accrue the balances of both contracts.
            comet.accrueAccount(address(this));
            comet.accrueAccount(address(depositer));
        }

        //base token owed should be 0 here but we count it just in case
        _totalAssets =
            balanceOfAsset() +
            balanceOfCollateral() -
            baseTokenOwedInAsset();
    }

    /*//////////////////////////////////////////////////////////////
                    OPTIONAL TO OVERRIDE BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Optional function for strategist to override that can
     *  be called in between reports.
     *
     * If '_tend' is used tendTrigger() will also need to be overridden.
     *
     * This call can only be called by a persionned role so may be
     * through protected relays.
     *
     * This can be used to harvest and compound rewards, deposit idle funds,
     * perform needed poisition maintence or anything else that doesn't need
     * a full report for.
     *
     *   EX: A strategy that can not deposit funds without getting
     *       sandwhiched can use the tend when a certain threshold
     *       of idle to totalAssets has been reached.
     *
     * The TokenizedStrategy contract will do all needed debt and idle updates
     * after this has finished and will have no effect on PPS of the strategy
     * till report() is called.
     *
     * @param _totalIdle The current amount of idle funds that are available to deploy.
     */
    function _tend(uint256 _totalIdle) internal override {
        // Accrue account for accurate balances
        comet.accrueAccount(address(this));

        // If the cost to borrow > rewards rate we will pull out all funds to not report a loss
        if (getNetBorrowApr(0) > getNetRewardApr(0)) {
            // Liquidate everything so not to report a loss
            _liquidatePosition(balanceOfCollateral());
            // Return since we dont asset to do anything else
            return;
        }

        // Else we need to either adjust LTV up or down.
        _leveragePosition(
            Math.min(_totalIdle, availableDepositLimit(address(this)))
        );
    }

    /**
     * @notice Returns wether or not tend() should be called by a keeper.
     * @dev Optional trigger to override if tend() will be used by the strategy.
     * This must be implemented if the strategy hopes to invoke _tend().
     *
     * @return . Should return true if tend() should be called by keeper or false if not.
     */
    function tendTrigger() public view override returns (bool) {
        if (comet.isSupplyPaused() || comet.isWithdrawPaused()) return false;

        // if we are in danger of being liquidated tend no matter what
        if (comet.isLiquidatable(address(this))) return true;

        // we adjust position if:
        // 1. LTV ratios are not in the HEALTHY range (either we take on more debt or repay debt)
        // 2. costs are acceptable
        uint256 collateralInUsd = _toUsd(balanceOfCollateral(), asset);

        uint256 currentLTV = (_toUsd(balanceOfDebt(), baseToken) * 1e18) /
            collateralInUsd;
        uint256 targetLTV = _getTargetLTV();

        // Check if we are over our warning LTV
        if (currentLTV > _getWarningLTV()) {
            // We have a higher tolerance for gas cost here since we are closer to liquidation
            return
                IBaseFeeGlobal(0xf8d0Ec04e94296773cE20eFbeeA82e76220cD549)
                    .basefee_global() <= maxGasPriceToTend;
        }

        // If Borrowing costs are to high.
        if (getNetBorrowApr(0) > getNetRewardApr(0)) {
            // Tend if we are still levered and base fee is acceptable.
            return currentLTV != 0 ? _isBaseFeeAcceptable() : false;
        } else if ((currentLTV < targetLTV && targetLTV - currentLTV > 1e17)) {
            // Borrowing costs are healthy and WE NEED TO TAKE ON MORE DEBT
            // (we need a 10p.p (1000bps) difference)
            return _isBaseFeeAcceptable();
        }

        return false;
    }

    /**
     * @notice Gets the max amount of `asset` that an adress can deposit.
     * @dev Defaults to an unlimited amount for any address. But can
     * be overriden by strategists.
     *
     * This function will be called before any deposit or mints to enforce
     * any limits desired by the strategist. This can be used for either a
     * traditional deposit limit or for implementing a whitelist etc.
     *
     *   EX:
     *      if(isAllowed[_owner]) return super.availableDepositLimit(_owner);
     *
     * This does not need to take into account any conversion rates
     * from shares to assets. But should know that any non max uint256
     * amounts may be converted to shares. So it is recommended to keep
     * custom amounts low enough as not to cause overflow when multiplied
     * by `totalSupply`.
     *
     * @param . The address that is depositing into the strategy.
     * @return . The avialable amount the `_owner` can deposit in terms of `asset`
     */
    function availableDepositLimit(
        address /*_owner*/
    ) public view override returns (uint256) {
        // We need to be able to both supply and withdraw on deposits.
        if (comet.isSupplyPaused() || comet.isWithdrawPaused()) return 0;

        return
            uint256(
                comet.getAssetInfoByAddress(asset).supplyCap -
                    comet.totalsCollateral(asset).totalSupplyAsset
            );
    }

    /**
     * @notice Gets the max amount of `asset` that can be withdrawn.
     * @dev Defaults to an unlimited amount for any address. But can
     * be overriden by strategists.
     *
     * This function will be called before any withdraw or redeem to enforce
     * any limits desired by the strategist. This can be used for illiquid
     * or sandwhichable strategies. It should never be lower than `totalIdle`.
     *
     *   EX:
     *       return TokenIzedStrategy.totalIdle();
     *
     * This does not need to take into account the `_owner`'s share balance
     * or conversion rates from shares to assets.
     *
     * @param . The address that is withdrawing from the strategy.
     * @return . The avialable amount that can be withdrawn in terms of `asset`
     */
    function availableWithdrawLimit(
        address /*_owner*/
    ) public view override returns (uint256) {
        // Default liquidity is the balance of base token
        uint256 liquidity = balanceOfCollateral();

        // If we can't withdraw or supply, set liquidity = 0.
        if (comet.isSupplyPaused() || comet.isWithdrawPaused()) {
            liquidity = 0;

            // If there is not enough liquidity to pay back our full debt.
        } else if (
            ERC20(baseToken).balanceOf(address(comet)) < balanceOfDebt()
        ) {
            // Adjust liquidity based on withdrawing the full amount of debt.
            unchecked {
                liquidity =
                    liquidity -
                    (
                        ((_fromUsd(
                            _toUsd(
                                balanceOfDebt() -
                                    ERC20(baseToken).balanceOf(address(comet)),
                                baseToken
                            ),
                            asset
                        ) * MAX_BPS) / _getTargetLTV())
                    );
            }
        }

        return TokenizedStrategy.totalIdle() + liquidity;
    }

    // ----------------- INTERNAL FUNCTIONS SUPPORT ----------------- \\

    function _leveragePosition(uint256 _amount) internal {
        // Supply will check _amount for 0.
        _supply(asset, _amount);

        // NOTE: debt + collateral calcs are done in USD
        uint256 collateralInUsd = _toUsd(balanceOfCollateral(), asset);

        // convert debt to USD
        uint256 debtInUsd = _toUsd(balanceOfDebt(), baseToken);

        // LTV numbers are always in 1e18
        uint256 currentLTV = (debtInUsd * 1e18) / collateralInUsd;
        uint256 targetLTV = _getTargetLTV(); // 70% under default liquidation Threshold

        // decide in which range we are and act accordingly:
        // SUBOPTIMAL(borrow) (e.g. from 0 to 70% liqLTV)
        // HEALTHY(do nothing) (e.g. from 70% to 80% liqLTV)
        // UNHEALTHY(repay) (e.g. from 80% to 100% liqLTV)

        if (targetLTV > currentLTV) {
            // SUBOPTIMAL RATIO: our current Loan-to-Value is lower than what we want

            // we need to take on more debt
            uint256 targetDebtUsd = (collateralInUsd * targetLTV) / 1e18;

            uint256 amountToBorrowUsd;
            unchecked {
                amountToBorrowUsd = targetDebtUsd - debtInUsd; // safe bc we checked ratios
            }

            // convert to BaseToken
            uint256 amountToBorrowBT = _fromUsd(amountToBorrowUsd, baseToken);

            // We want to make sure that the reward apr > borrow apr so we dont reprot a loss
            // Borrowing will cause the borrow apr to go up and the rewards apr to go down
            if (
                getNetBorrowApr(amountToBorrowBT) >
                getNetRewardApr(amountToBorrowBT)
            ) {
                // If we would push it over the limit dont borrow anything
                amountToBorrowBT = 0;
            }

            // Need to have at least the min set by comet
            if (balanceOfDebt() + amountToBorrowBT > minThreshold) {
                _withdraw(baseToken, amountToBorrowBT);
            }
        } else if (currentLTV > _getWarningLTV()) {
            // UNHEALTHY RATIO
            // we repay debt to set it to targetLTV
            uint256 targetDebtUsd = (targetLTV * collateralInUsd) / 1e18;

            // Withdraw the difference from the Depositer
            _withdrawFromDepositer(
                _fromUsd(debtInUsd - targetDebtUsd, baseToken)
            ); // we withdraw from BaseToken depositer

            _repayTokenDebt(); // we repay the BaseToken debt.
        }

        if (balanceOfBaseToken() > 0) {
            depositer.deposit();
        }
    }

    function _liquidatePosition(uint256 _needed) internal {
        // NOTE: amountNeeded is in asset
        // NOTE: repayment amount is in BaseToken
        // NOTE: collateral and debt calcs are done in USD

        // Cache balance for withdraw checks
        uint256 balance = balanceOfAsset();

        // Accrue account for accurate balances
        comet.accrueAccount(address(this));

        // We first repay whatever we need to repay to keep healthy ratios
        _withdrawFromDepositer(_calculateAmountToRepay(_needed));

        // we repay the BaseToken debt with the amount withdrawn from the vault
        _repayTokenDebt();

        // Withdraw as much as we can up to the amount needed while maintaning a health ltv
        _withdraw(asset, Math.min(_needed, _maxWithdrawal()));

        // we check if we withdrew less than expected, we have not more baseToken
        // left AND should harvest or buy BaseToken with asset (potentially realising losses)
        if (
            _needed > balanceOfAsset() - balance && // if we didn't get enough
            balanceOfDebt() > 0 && // still some debt remaining
            balanceOfDepositer() == 0 && // but no capital to repay
            !leaveDebtBehind // if set to true, the strategy will not try to repay debt by selling asset
        ) {
            // using this part of code may result in losses but it is necessary to unlock full collateral in case of wind down
            // This should only occur when depleting the strategy so we asset to swap the full amount of our debt
            // we buy BaseToken first with available rewards then with asset
            _buyBaseToken();

            // we repay debt to actually unlock collateral
            // after this, balanceOfDebt should be 0
            _repayTokenDebt();

            // then we try withdraw once more
            // still withdraw with target LTV since management can potentially save any left over manually
            _withdraw(asset, _maxWithdrawal());
        }
    }

    function _withdrawFromDepositer(uint256 _amountBT) internal {
        uint256 balancePrior = balanceOfBaseToken();
        // Only withdraw what we dont already have free
        _amountBT = balancePrior >= _amountBT ? 0 : _amountBT - balancePrior;
        if (_amountBT == 0) return;

        // Make sure we have enough balance. This accrues the account first.
        _amountBT = Math.min(_amountBT, depositer.accruedCometBalance());
        // need to check liquidity of the comet
        _amountBT = Math.min(
            _amountBT,
            ERC20(baseToken).balanceOf(address(comet))
        );

        depositer.withdraw(_amountBT);
    }

    /*
     * Supply an asset that this contract holds to Compound III
     * This is used both to supply collateral as well as the baseToken
     */
    function _supply(address _asset, uint256 amount) internal {
        if (amount == 0) return;
        comet.supply(_asset, amount);
    }

    /*
     * Withdraws an _asset from Compound III to this contract
     * for both collateral and borrowing baseToken
     */
    function _withdraw(address _asset, uint256 amount) internal {
        if (amount == 0) return;
        comet.withdraw(_asset, amount);
    }

    function _repayTokenDebt() internal {
        // we cannot pay more than loose balance or more than we owe
        _supply(baseToken, Math.min(balanceOfBaseToken(), balanceOfDebt()));
    }

    function _maxWithdrawal() internal view returns (uint256) {
        uint256 collateral = balanceOfCollateral();
        uint256 debt = balanceOfDebt();

        // If there is no debt we can withdraw everything
        if (debt == 0) return collateral;

        uint256 debtInUsd = _toUsd(balanceOfDebt(), baseToken);

        // What we need to maintain a health LTV
        uint256 neededCollateral = _fromUsd(
            (debtInUsd * 1e18) / _getTargetLTV(),
            asset
        );
        // We need more collateral so we cant withdraw anything
        if (neededCollateral > collateral) {
            return 0;
        }

        // Return the difference in terms of asset
        unchecked {
            return collateral - neededCollateral;
        }
    }

    function _calculateAmountToRepay(
        uint256 amount
    ) internal view returns (uint256) {
        if (amount == 0) return 0;
        uint256 collateral = balanceOfCollateral();
        // to unlock all collateral we must repay all the debt
        if (amount >= collateral) return balanceOfDebt();

        // we check if the collateral that we are withdrawing leaves us in a risky range, we then take action
        uint256 newCollateralUsd = _toUsd(collateral - amount, asset);

        uint256 targetDebtUsd = (newCollateralUsd * _getTargetLTV()) / 1e18;
        uint256 targetDebt = _fromUsd(targetDebtUsd, baseToken);
        uint256 currentDebt = balanceOfDebt();
        // Repay only if our target debt is lower than our current debt
        return targetDebt < currentDebt ? currentDebt - targetDebt : 0;
    }

    // ----------------- INTERNAL CALCS -----------------

    // Returns the _amount of _token in terms of USD, i.e 1e8
    function _toUsd(
        uint256 _amount,
        address _token
    ) internal view returns (uint256) {
        if (_amount == 0) return _amount;
        // usd price is returned as 1e8
        unchecked {
            return
                (_amount * getCompoundPrice(_token)) /
                (10 ** ERC20(_token).decimals());
        }
    }

    // Returns the _amount of usd (1e8) in terms of _token
    function _fromUsd(
        uint256 _amount,
        address _token
    ) internal view returns (uint256) {
        if (_amount == 0) return _amount;
        unchecked {
            return
                (_amount * (10 ** ERC20(_token).decimals())) /
                getCompoundPrice(_token);
        }
    }

    function balanceOfAsset() public view returns (uint256) {
        return ERC20(asset).balanceOf(address(this));
    }

    function balanceOfCollateral() public view returns (uint256) {
        return uint256(comet.userCollateral(address(this), asset).balance);
    }

    function balanceOfBaseToken() public view returns (uint256) {
        return ERC20(baseToken).balanceOf(address(this));
    }

    function balanceOfDepositer() public view returns (uint256) {
        return depositer.cometBalance();
    }

    function balanceOfDebt() public view returns (uint256) {
        return comet.borrowBalanceOf(address(this));
    }

    // Returns the negative position of base token. i.e. borrowed - supplied
    // if supplied is higher it will return 0
    function baseTokenOwedBalance() public view returns (uint256) {
        uint256 have = balanceOfDepositer() + balanceOfBaseToken();
        uint256 owe = balanceOfDebt();

        // If they are the same or supply > debt return 0
        if (have >= owe) return 0;

        unchecked {
            return owe - have;
        }
    }

    function baseTokenOwedInAsset() internal view returns (uint256 owed) {
        // Don't do conversions unless it's a non-zero false.
        uint256 owedInBase = baseTokenOwedBalance();
        if (owedInBase != 0) {
            owed = _fromUsd(_toUsd(owedInBase, baseToken), asset);
        }
    }

    function rewardsInAsset() public view returns (uint256) {
        // underreport by 10% for safety
        return
            (_fromUsd(_toUsd(depositer.getRewardsOwed(), rewardToken), asset) *
                9_000) / MAX_BPS;
    }

    // We put the logic for these APR functions in the depositer contract to save byte code in the main strategy \\
    function getNetBorrowApr(uint256 newAmount) public view returns (uint256) {
        return depositer.getNetBorrowApr(newAmount);
    }

    function getNetRewardApr(uint256 newAmount) public view returns (uint256) {
        return depositer.getNetRewardApr(newAmount);
    }

    /*
     * Get the liquidation collateral factor for an asset
     */
    function getLiquidateCollateralFactor() public view returns (uint256) {
        return
            uint256(
                comet.getAssetInfoByAddress(asset).liquidateCollateralFactor
            );
    }

    /*
     * Get the price feed address for an asset
     */
    function getPriceFeedAddress(
        address _asset
    ) internal view returns (address priceFeed) {
        priceFeed = priceFeeds[_asset];
        if (priceFeed == address(0)) {
            priceFeed = comet.getAssetInfoByAddress(_asset).priceFeed;
        }
    }

    /*
     * Get the current price of an _asset from the protocol's persepctive
     */
    function getCompoundPrice(
        address _asset
    ) internal view returns (uint256 price) {
        price = comet.getPrice(getPriceFeedAddress(_asset));
        // If weth is base token we need to scale response to e18
        if (price == 1e8 && _asset == base) price = 1e18;
    }

    // External function used to easisly calculate the current LTV of the strat
    function getCurrentLTV() external view returns (uint256) {
        unchecked {
            return
                (_toUsd(balanceOfDebt(), baseToken) * 1e18) /
                _toUsd(balanceOfCollateral(), asset);
        }
    }

    function _getTargetLTV() internal view returns (uint256) {
        unchecked {
            return
                (getLiquidateCollateralFactor() * targetLTVMultiplier) /
                MAX_BPS;
        }
    }

    function _getWarningLTV() internal view returns (uint256) {
        unchecked {
            return
                (getLiquidateCollateralFactor() * warningLTVMultiplier) /
                MAX_BPS;
        }
    }

    // ----------------- HARVEST / TOKEN CONVERSIONS -----------------

    function claimRewards() external onlyKeepers {
        _claimRewards();
    }

    function _claimRewards() internal {
        rewardsContract.claim(address(comet), address(this), true);
        // Pull rewards from depositer even if not incentivised to accrue the account
        depositer.claimRewards();
    }

    function _claimAndSellRewards() internal {
        _claimRewards();

        uint256 rewardTokenBalance;
        uint256 baseNeeded = baseTokenOwedBalance();

        if (baseNeeded > 0) {
            rewardTokenBalance = ERC20(rewardToken).balanceOf(address(this));
            // We estimate how much we will need in order to get the amount of base
            // Accounts for slippage and diff from oracle price, just to assure no horrible sandwhich
            uint256 maxRewardToken = (_fromUsd(
                _toUsd(baseNeeded, baseToken),
                rewardToken
            ) * 10_500) / MAX_BPS;
            if (maxRewardToken < rewardTokenBalance) {
                // If we have enough swap an exact amount out
                _swapTo(rewardToken, baseToken, baseNeeded, maxRewardToken);
            } else {
                // if not swap everything we have
                _swapFrom(rewardToken, baseToken, rewardTokenBalance, 0);
            }
        }

        rewardTokenBalance = ERC20(rewardToken).balanceOf(address(this));
        _swapFrom(rewardToken, asset, rewardTokenBalance, 0);
    }

    // This should only ever get called when withdrawing all funds from the strategy if there is debt left over.
    // It will first try and sell rewards for the needed amount of base token. then will swap asset
    // Using this in a normal withdraw can cause it to be sandwhiched which is why we use rewards first
    function _buyBaseToken() internal {
        // We should be able to get the needed amount from rewards tokens.
        // We first try that before swapping asset and reporting losses.
        _claimAndSellRewards();

        uint256 baseStillOwed = baseTokenOwedBalance();
        // Check if our debt balance is still greater than our base token balance
        if (baseStillOwed > 0) {
            // Need to account for both slippage and diff in the oracle price.
            // Should be only swapping very small amounts so its just to make sure there is no massive sandwhich
            uint256 maxAssetBalance = (_fromUsd(
                _toUsd(baseStillOwed, baseToken),
                asset
            ) * 10_500) / MAX_BPS;
            // Under 10 can cause rounding errors from token conversions, no need to swap that small amount
            if (maxAssetBalance <= 10) return;

            _swapFrom(asset, baseToken, baseStillOwed, maxAssetBalance);
        }
    }

    function _isBaseFeeAcceptable() internal view returns (bool) {
        return true;
    }

    /**
     * @dev Optional function for a strategist to override that will
     * allow management to manually withdraw deployed funds from the
     * yield source if a strategy is shutdown.
     *
     * This should attempt to free `_amount`, noting that `_amount` may
     * be more than is currently deployed.
     *
     * NOTE: This will not realize any profits or losses. A seperate
     * {report} will be needed in order to record any profit/loss. If
     * a report may need to be called after a shutdown it is important
     * to check if the strategy is shutdown during {_harvestAndReport}
     * so that it does not simply re-deploy all funds that had been freed.
     *
     * EX:
     *   if(freeAsset > 0 && !TokenizedStrategy.isShutdown()) {
     *       depositFunds...
     *    }
     *
     * @param _amount The amount of asset to attempt to free.
     */
    function _emergencyWithdraw(uint256 _amount) internal override {
        if (_amount > 0) {
            depositer.withdraw(_amount);
        }
        _repayTokenDebt();
    }
}
