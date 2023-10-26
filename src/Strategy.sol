// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {CometStructs} from "./interfaces/Compound/V3/CompoundV3.sol";
import {Comet} from "./interfaces/Compound/V3/CompoundV3.sol";
import {CometRewards} from "./interfaces/Compound/V3/CompoundV3.sol";

/// Uniswap V3 Swapper
import {UniswapV3Swapper} from "@periphery/swappers/UniswapV3Swapper.sol";
import {BaseHealthCheck, ERC20} from "@periphery/HealthCheck/BaseHealthCheck.sol";

import {Depositor} from "./Depositor.sol";

/**
 * @title CompV3LenderBorrower
 * @notice A Yearn V3 lender borrower strategy for Compound V3.
 */
contract Strategy is BaseHealthCheck, UniswapV3Swapper {
    using SafeERC20 for ERC20;

    struct TokenInfo {
        address priceFeed;
        uint96 decimals;
    }

    /// If set to true, the strategy will not try to repay debt by selling rewards or asset.
    bool public leaveDebtBehind;

    // The address of the main V3 pool.
    Comet public immutable comet;
    /// The token we will be borrowing/supplying.
    address public immutable baseToken;
    /// The contract to get Comp rewards from.
    CometRewards public constant rewardsContract =
        CometRewards(0x45939657d1CA34A8FA39A924B71D28Fe8431e581);

    address internal constant weth = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

    /// The Contract that will deposit the baseToken back into Compound
    Depositor public immutable depositor;

    /// The reward Token (COMP).
    address public immutable rewardToken;

    /// Mapping from token => struct containing its reused info
    mapping(address => TokenInfo) public tokenInfo;

    /// @notice Target Loan-To-Value (LTV) multiplier.
    /// @dev Represents the ratio up to which we will borrow, relative to the liquidation threshold.
    /// LTV is the debt-to-collateral ratio. Default is set to 80% of the liquidation LTV.
    uint16 public targetLTVMultiplier = 8_000;

    /// @notice Warning Loan-To-Value (LTV) multiplier
    /// @dev Represents the ratio at which we will start repaying the debt to avoid liquidation
    /// Default is set to 90% of the liquidation LTV
    uint16 public warningLTVMultiplier = 9_000; // 90% of liquidation LTV

    /// @notice Slippage tolerance (in basis points) for swaps
    /// Default is set to 5%.
    uint256 public slippage = 500;

    /// Thresholds: lower limit on how much base token can be borrowed at a time.
    uint256 internal immutable minThreshold;

    /// The max the base fee (in gwei) will be for a tend
    uint256 public maxGasPriceToTend = 200 * 1e9;

    /**
     * @param _asset The address of the asset we are lending/borrowing.
     * @param _name The name of the strategy.
     * @param _ethToAssetFee The fee for swapping eth to asset.
     * @param _depositor The address of the depositor contract.
     */
    constructor(
        address _asset,
        string memory _name,
        address _comet,
        uint24 _ethToAssetFee,
        address _depositor
    ) BaseHealthCheck(_asset, _name) {
        comet = Comet(_comet);

        /// Get the baseToken we wil borrow and the min
        baseToken = comet.baseToken();
        minThreshold = comet.baseBorrowMin();

        depositor = Depositor(_depositor);
        require(baseToken == address(depositor.baseToken()), "!base");

        /// Set the rewardToken token we will get.
        rewardToken = rewardsContract.rewardConfig(_comet).token;

        /// To supply asset as collateral
        asset.safeApprove(_comet, type(uint256).max);
        /// To repay debt
        ERC20(baseToken).safeApprove(_comet, type(uint256).max);
        /// For depositor to pull funds to deposit
        ERC20(baseToken).safeApprove(_depositor, type(uint256).max);
        /// To sell reward tokens
        ERC20(rewardToken).safeApprove(address(router), type(uint256).max);

        /// Set the needed variables for the Uni Swapper
        /// Base will be weth
        base = weth;
        /// UniV3 mainnet router
        router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        /// Set the min amount for the swapper to sell
        minAmountToSell = 1e10;

        /// Default to .3% pool for comp/eth and to .05% pool for eth/baseToken
        _setFees(3000, 500, _ethToAssetFee);

        tokenInfo[baseToken] = TokenInfo({
            priceFeed: comet.baseTokenPriceFeed(),
            decimals: uint96(10 ** ERC20(baseToken).decimals())
        });

        tokenInfo[address(asset)] = TokenInfo({
            priceFeed: comet.getAssetInfoByAddress(address(asset)).priceFeed,
            decimals: uint96(10 ** ERC20(address(asset)).decimals())
        });

        tokenInfo[rewardToken] = TokenInfo({
            priceFeed: 0x2A8758b7257102461BC958279054e372C2b1bDE6,
            decimals: uint96(10 ** ERC20(rewardToken).decimals())
        });
    }

    /// ----------------- SETTERS -----------------

    /**
     * @notice Set the parameters for the strategy
     * @dev Updates multiple strategy parameters to optimize contract bytecode size.
     * Ensure `_warningLTVMultiplier` is less than 9000 and `_targetLTVMultiplier` is less than `_warningLTVMultiplier`
     * Can only be called by management
     * @param _targetLTVMultiplier Desired target loan-to-value multiplier
     * @param _warningLTVMultiplier Warning threshold for loan-to-value multiplier
     * @param _minToSell Minimum amount to sell
     * @param _slippage Allowed slippage percentage
     * @param _leaveDebtBehind Bool to prevent debt repayment
     * @param _maxGasPriceToTend Maximum gas price for the tend operation
     */
    function setStrategyParams(
        uint16 _targetLTVMultiplier,
        uint16 _warningLTVMultiplier,
        uint256 _minToSell,
        uint256 _slippage,
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
        require(_slippage < MAX_BPS, "slippage");
        leaveDebtBehind = _leaveDebtBehind;
        maxGasPriceToTend = _maxGasPriceToTend;
    }

    /**
     * @notice Set the price feed for a given token
     * @dev Updates the price feed for the specified token after a revert check
     * Can only be called by management
     * @param _token Address of the token for which to set the price feed
     * @param _priceFeed Address of the price feed contract
     */
    function setPriceFeed(
        address _token,
        address _priceFeed
    ) external onlyManagement {
        // just check it doesn't revert
        comet.getPrice(_priceFeed);
        tokenInfo[_token].priceFeed = _priceFeed;
    }

    /**
     * @notice Set the fees for different token swaps
     * @dev Configures fees for token swaps and can only be called by management
     * @param _rewardToEthFee Fee for swapping reward tokens to ETH
     * @param _ethToBaseFee Fee for swapping ETH to base token
     * @param _ethToAssetFee Fee for swapping ETH to asset token
     */
    function setFees(
        uint24 _rewardToEthFee,
        uint24 _ethToBaseFee,
        uint24 _ethToAssetFee
    ) external onlyManagement {
        _setFees(_rewardToEthFee, _ethToBaseFee, _ethToAssetFee);
    }

    /**
     * @notice Internal function to set the fees for token swaps involving `weth`
     * @dev Sets the swap fees for rewardToken to WETH, baseToken to WETH, and asset to WETH
     * @param _rewardToEthFee Fee for swapping reward tokens to WETH
     * @param _ethToBaseFee Fee for swapping ETH to base token
     * @param _ethToAssetFee Fee for swapping ETH to asset token
     */
    function _setFees(
        uint24 _rewardToEthFee,
        uint24 _ethToBaseFee,
        uint24 _ethToAssetFee
    ) internal {
        address _weth = base;
        _setUniFees(rewardToken, _weth, _rewardToEthFee);
        _setUniFees(baseToken, _weth, _ethToBaseFee);
        _setUniFees(address(asset), _weth, _ethToAssetFee);
    }

    /**
     * @notice Swap the base token between `asset` and `weth`
     * @dev This can be used for management to change which pool to trade reward tokens.
     */
    function swapBase() external onlyManagement {
        base = base == address(asset) ? weth : address(asset);
    }

    /*//////////////////////////////////////////////////////////////
                NEEDED TO BE OVERRIDDEN BY STRATEGIST
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Should deploy up to '_amount' of 'asset' in the yield source.
     *
     * This function is called at the end of a {deposit} or {mint}
     * call. Meaning that unless a whitelist is implemented it will
     * be entirely permissionless and thus can be sandwiched or otherwise
     * manipulated.
     *
     * @param _amount The amount of 'asset' that the strategy should attempt
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
     * entirely permissionless and thus can be sandwiched or otherwise
     * manipulated.
     *
     * Should not rely on asset.balanceOf(address(this)) calls other than
     * for diff accounting purposes.
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
        /// Accrue the balances of both contracts for balances.
        comet.accrueAccount(address(this));
        comet.accrueAccount(address(depositor));

        /// 1. claim rewards, 2. even baseToken deposits and borrows 3. sell remainder of rewards to asset.
        /// This will accrue this account as well as the depositor so all future calls are accurate
        _claimAndSellRewards();

        /// Leverage all the asset we have or up to the supply cap.
        /// We want check our leverage even if balance of asset is 0.
        _leveragePosition(
            Math.min(balanceOfAsset(), availableDepositLimit(address(this)))
        );

        /// Base token owed should be 0 here but we count it just in case
        _totalAssets =
            balanceOfAsset() +
            balanceOfCollateral() -
            _baseTokenOwedInAsset();

        /// Health check the amount to report.
        _executeHealthCheck(_totalAssets);
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
     * This call can only be called by a permissioned role so may be
     * through protected relays.
     *
     * This can be used to harvest and compound rewards, deposit idle funds,
     * perform needed position maintenance or anything else that doesn't need
     * a full report for.
     *
     *   EX: A strategy that can not deposit funds without getting
     *       sandwiched can use the tend when a certain threshold
     *       of idle to totalAssets has been reached.
     *
     * The TokenizedStrategy contract will do all needed debt and idle updates
     * after this has finished and will have no effect on PPS of the strategy
     * till report() is called.
     *
     * @param _totalIdle The current amount of idle funds that are available to deploy.
     */
    function _tend(uint256 _totalIdle) internal override {
        /// If the cost to borrow > rewards rate we will pull out all funds to not report a loss
        if (getNetBorrowApr(0) > getNetRewardApr(0)) {
            /// Liquidate everything so not to report a loss
            _liquidatePosition(balanceOfCollateral());
            /// Return since we don't asset to do anything else
            return;
        }

        /// Accrue account for accurate balances
        comet.accrueAccount(address(this));
        comet.accrueAccount(address(depositor));

        /// Else we need to either adjust LTV up or down.
        _leveragePosition(
            Math.min(_totalIdle, availableDepositLimit(address(this)))
        );
    }

    /**
     * @dev Optional trigger to override if tend() will be used by the strategy.
     * This must be implemented if the strategy hopes to invoke _tend().
     *
     * @return . Should return true if tend() should be called by keeper or false if not.
     */
    function _tendTrigger() internal view override returns (bool) {
        if (TokenizedStrategy.totalAssets() == 0) return false;

        if (comet.isSupplyPaused() || comet.isWithdrawPaused()) return false;

        /// If we are in danger of being liquidated tend no matter what
        if (comet.isLiquidatable(address(this))) return true;

        /// We adjust position if:
        /// 1. LTV ratios are not in the HEALTHY range (either we take on more debt or repay debt)
        /// 2. costs are acceptable
        uint256 collateralInUsd = _toUsd(balanceOfCollateral(), address(asset));
        uint256 debtInUsd = _toUsd(balanceOfDebt(), baseToken);
        uint256 currentLTV = collateralInUsd > 0
            ? (debtInUsd * 1e18) / collateralInUsd
            : 0;

        /// Check if we are over our warning LTV
        if (currentLTV > _getWarningLTV()) {
            // Make sure the gas price isn't to high.
            return _isBaseFeeAcceptable();
        }

        uint256 targetLTV = _getTargetLTV();

        /// If we are still levered and Borrowing costs are too high.
        if (currentLTV != 0 && getNetBorrowApr(0) > getNetRewardApr(0)) {
            /// Tend if base fee is acceptable.
            return _isBaseFeeAcceptable();

            /// IF we are lower than our target. (we need a 10% (1000bps) difference)
        } else if ((currentLTV < targetLTV && targetLTV - currentLTV > 1e17)) {
            /// Make sure the increase in debt would keep borrowing costs healthy.
            uint256 targetDebtUsd = (collateralInUsd * targetLTV) / 1e18;

            uint256 amountToBorrowUsd;
            unchecked {
                amountToBorrowUsd = targetDebtUsd - debtInUsd; // safe bc we checked ratios
            }

            /// Convert to BaseToken
            uint256 amountToBorrowBT = _fromUsd(amountToBorrowUsd, baseToken);

            if (amountToBorrowBT == 0) return false;

            /// We want to make sure that the reward apr > borrow apr so we don't report a loss
            /// Borrowing will cause the borrow apr to go up and the rewards apr to go down
            if (
                getNetBorrowApr(amountToBorrowBT) <
                getNetRewardApr(amountToBorrowBT)
            ) {
                /// Borrowing costs are healthy and WE NEED TO TAKE ON MORE DEBT
                return _isBaseFeeAcceptable();
            }
        }

        return false;
    }

    /**
     * @notice Gets the max amount of `asset` that an address can deposit.
     * @dev Defaults to an unlimited amount for any address. But can
     * be overridden by strategists.
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
     * @return . The available amount the `_owner` can deposit in terms of `asset`
     */
    function availableDepositLimit(
        address /*_owner*/
    ) public view override returns (uint256) {
        /// We need to be able to both supply and withdraw on deposits.
        if (comet.isSupplyPaused() || comet.isWithdrawPaused()) return 0;

        return
            uint256(
                comet.getAssetInfoByAddress(address(asset)).supplyCap -
                    comet.totalsCollateral(address(asset)).totalSupplyAsset
            );
    }

    /**
     * @notice Gets the max amount of `asset` that can be withdrawn.
     * @dev Defaults to an unlimited amount for any address. But can
     * be overridden by strategists.
     *
     * This function will be called before any withdraw or redeem to enforce
     * any limits desired by the strategist. This can be used for illiquid
     * or sandwichable strategies. It should never be lower than `totalIdle`.
     *
     *   EX:
     *       return TokenIzedStrategy.totalIdle();
     *
     * This does not need to take into account the `_owner`'s share balance
     * or conversion rates from shares to assets.
     *
     * @param . The address that is withdrawing from the strategy.
     * @return . The available amount that can be withdrawn in terms of `asset`
     */
    function availableWithdrawLimit(
        address /*_owner*/
    ) public view override returns (uint256) {
        /// Default liquidity is the balance of collateral
        uint256 liquidity = balanceOfCollateral();

        /// If we can't withdraw or supply, set liquidity = 0.
        if (comet.isSupplyPaused() || comet.isWithdrawPaused()) {
            liquidity = 0;

            /// If there is not enough liquidity to pay back our full debt.
        } else if (
            ERC20(baseToken).balanceOf(address(comet)) < balanceOfDebt()
        ) {
            /// Adjust liquidity based on withdrawing the full amount of debt.
            unchecked {
                liquidity =
                    ((_fromUsd(
                        _toUsd(
                            ERC20(baseToken).balanceOf(address(comet)),
                            baseToken
                        ),
                        address(asset)
                    ) * MAX_BPS) / _getTargetLTV()) -
                    1; // Minus 1 for rounding.
            }
        }

        return TokenizedStrategy.totalIdle() + liquidity;
    }

    /// ----------------- INTERNAL FUNCTIONS SUPPORT ----------------- \\

    /**
     * @notice Adjusts the leverage position of the strategy based on current and target Loan-to-Value (LTV) ratios.
     * @dev All debt and collateral calculations are done in USD terms. LTV values are represented in 1e18 format.
     * @param _amount The amount to be supplied to adjust the leverage position,
     */
    function _leveragePosition(uint256 _amount) internal {
        /// Supply the given amount to the strategy.
        // This function internally checks for zero amounts.
        _supply(address(asset), _amount);

        uint256 collateralInUsd = _toUsd(balanceOfCollateral(), address(asset));

        /// Convert debt to USD
        uint256 debtInUsd = _toUsd(balanceOfDebt(), baseToken);

        /// LTV numbers are always in 1e18
        uint256 currentLTV = collateralInUsd > 0
            ? (debtInUsd * 1e18) / collateralInUsd
            : 0;
        uint256 targetLTV = _getTargetLTV(); // 80% under default liquidation Threshold

        /// decide in which range we are and act accordingly:
        /// SUBOPTIMAL(borrow) (e.g. from 0 to 80% liqLTV)
        /// HEALTHY(do nothing) (e.g. from 80% to 90% liqLTV)
        /// UNHEALTHY(repay) (e.g. from 90% to 100% liqLTV)

        if (targetLTV > currentLTV) {
            /// SUBOPTIMAL RATIO: our current Loan-to-Value is lower than what we want

            /// we need to take on more debt
            uint256 targetDebtUsd = (collateralInUsd * targetLTV) / 1e18;

            uint256 amountToBorrowUsd;
            unchecked {
                amountToBorrowUsd = targetDebtUsd - debtInUsd; // safe bc we checked ratios
            }

            /// convert to BaseToken
            uint256 amountToBorrowBT = _fromUsd(amountToBorrowUsd, baseToken);

            /// We want to make sure that the reward apr > borrow apr so we don't report a loss
            /// Borrowing will cause the borrow apr to go up and the rewards apr to go down
            if (
                getNetBorrowApr(amountToBorrowBT) >
                getNetRewardApr(amountToBorrowBT)
            ) {
                /// If we would push it over the limit don't borrow anything
                amountToBorrowBT = 0;
            }

            /// Need to have at least the min set by comet
            if (balanceOfDebt() + amountToBorrowBT > minThreshold) {
                _withdraw(baseToken, amountToBorrowBT);
            }
        } else if (currentLTV > _getWarningLTV()) {
            /// UNHEALTHY RATIO
            /// we repay debt to set it to targetLTV
            uint256 targetDebtUsd = (targetLTV * collateralInUsd) / 1e18;

            /// Withdraw the difference from the Depositor
            _withdrawFromDepositor(
                _fromUsd(debtInUsd - targetDebtUsd, baseToken)
            );

            /// Repay the BaseToken debt.
            _repayTokenDebt();
        }

        // Deposit any loose base token that was borrowed.
        if (balanceOfBaseToken() > 0) {
            depositor.deposit();
        }
    }

    /**
     * @notice Liquidates the position to ensure the needed amount while maintaining healthy ratios.
     * @dev All debt, collateral, and needed amounts are calculated in USD. The needed amount is represented in the asset.
     * @param _needed The amount required in the asset.
     */
    function _liquidatePosition(uint256 _needed) internal {
        /// Cache balance for withdraw checks
        uint256 balance = balanceOfAsset();

        /// Accrue account for accurate balances
        comet.accrueAccount(address(this));

        /// We first repay whatever we need to repay to keep healthy ratios
        _withdrawFromDepositor(_calculateAmountToRepay(_needed));

        /// we repay the BaseToken debt with the amount withdrawn from the vault
        _repayTokenDebt();

        // Withdraw as much as we can up to the amount needed while maintaining a health ltv
        _withdraw(address(asset), Math.min(_needed, _maxWithdrawal()));

        /// We check if we withdrew less than expected, and we do have not more baseToken
        /// left AND should harvest or buy BaseToken with asset (potentially realising losses)
        if (
            /// if we didn't get enough
            _needed > balanceOfAsset() - balance &&
            /// still some debt remaining
            balanceOfDebt() > 0 &&
            /// but no capital to repay
            balanceOfDepositor() == 0 &&
            /// And the leave debt flag is false.
            !leaveDebtBehind
        ) {
            /// using this part of code may result in losses but it is necessary to unlock full collateral
            /// in case of wind down. This should only occur when depleting the strategy so we buy the full
            /// amount of our remaining debt. We buy BaseToken first with available rewards then with asset.
            _buyBaseToken();

            /// we repay debt to actually unlock collateral
            /// after this, balanceOfDebt should be 0
            _repayTokenDebt();

            /// then we try withdraw once more
            /// still withdraw with target LTV since management can potentially save any left over manually
            _withdraw(address(asset), _maxWithdrawal());
        }
    }

    /**
     * @notice Withdraws the required amount from the depositor, ensuring it doesn't exceed available balances.
     * @dev The function ensures that withdrawals only happen for amounts not already available and considers both the accrued comet balance and liquidity.
     * @param _amountBT The amount required in BaseToken.
     */
    function _withdrawFromDepositor(uint256 _amountBT) internal {
        uint256 balancePrior = balanceOfBaseToken();
        /// Only withdraw what we don't already have free
        _amountBT = balancePrior >= _amountBT ? 0 : _amountBT - balancePrior;
        if (_amountBT == 0) return;

        /// Make sure we have enough balance. This accrues the account first.
        _amountBT = Math.min(_amountBT, depositor.accruedCometBalance());
        /// need to check liquidity of the comet
        _amountBT = Math.min(
            _amountBT,
            ERC20(baseToken).balanceOf(address(comet))
        );

        depositor.withdraw(_amountBT);
    }

    /**
     * @notice Supplies a specified amount of an asset from this contract to Compound III.
     * @dev Can be used to supply both collateral and baseToken.
     * @param _asset The asset to be supplied.
     * @param amount The amount of the asset to supply.
     */
    function _supply(address _asset, uint256 amount) internal {
        if (amount == 0) return;
        comet.supply(_asset, amount);
    }

    /**
     * @notice Withdraws a specified amount of an asset from Compound III to this contract.
     * @dev Used for both collateral and borrowing baseToken.
     * @param _asset The asset to be withdrawn.
     * @param amount The amount of the asset to withdraw.
     */
    function _withdraw(address _asset, uint256 amount) internal {
        if (amount == 0) return;
        comet.withdraw(_asset, amount);
    }

    /**
     * @notice Repays outstanding debt with available base tokens
     * @dev Repays debt by supplying base tokens up to the min of available balance and debt amount
     */
    function _repayTokenDebt() internal {
        /// We cannot pay more than loose balance or more than we owe
        _supply(baseToken, Math.min(balanceOfBaseToken(), balanceOfDebt()));
    }

    /**
     * @notice Calculates max amount that can be withdrawn while maintaining healthy LTV ratio
     * @dev Considers current collateral and debt amounts
     * @return The max amount of collateral available for withdrawal
     */
    function _maxWithdrawal() internal view returns (uint256) {
        uint256 collateral = balanceOfCollateral();
        uint256 debt = balanceOfDebt();

        /// If there is no debt we can withdraw everything
        if (debt == 0) return collateral;

        uint256 debtInUsd = _toUsd(debt, baseToken);

        /// What we need to maintain a health LTV
        uint256 neededCollateral = _fromUsd(
            (debtInUsd * 1e18) / _getTargetLTV(),
            address(asset)
        );
        /// We need more collateral so we cant withdraw anything
        if (neededCollateral > collateral) {
            return 0;
        }

        /// Return the difference in terms of asset
        unchecked {
            return collateral - neededCollateral;
        }
    }

    /**
     * @notice Calculates amount of debt to repay to maintain healthy LTV ratio
     * @dev Considers target LTV, amount being withdrawn, and current collateral/debt
     * @param amount The withdrawal amount
     * @return The amount of debt to repay
     */
    function _calculateAmountToRepay(
        uint256 amount
    ) internal view returns (uint256) {
        if (amount == 0) return 0;
        uint256 collateral = balanceOfCollateral();
        /// To unlock all collateral we must repay all the debt
        if (amount >= collateral) return balanceOfDebt();

        /// We check if the collateral that we are withdrawing leaves us in a risky range, we then take action
        uint256 newCollateralUsd = _toUsd(collateral - amount, address(asset));

        uint256 targetDebtUsd = (newCollateralUsd * _getTargetLTV()) / 1e18;
        uint256 targetDebt = _fromUsd(targetDebtUsd, baseToken);
        uint256 currentDebt = balanceOfDebt();
        /// Repay only if our target debt is lower than our current debt
        return targetDebt < currentDebt ? currentDebt - targetDebt : 0;
    }

    // ----------------- INTERNAL CALCS -----------------

    /**
     * @notice Converts a token amount to USD value
     * @dev Uses Compound price feed and token decimals
     * @param _amount The token amount
     * @param _token The token address
     * @return The USD value scaled by 1e8
     */
    function _toUsd(
        uint256 _amount,
        address _token
    ) internal view returns (uint256) {
        if (_amount == 0) return _amount;
        /// usd price is returned as 1e8
        unchecked {
            return
                (_amount * _getCompoundPrice(_token)) /
                (uint256(tokenInfo[_token].decimals));
        }
    }

    /**
     * @notice Converts a USD amount to token value
     * @dev Uses Compound price feed and token decimals
     * @param _amount The USD amount (scaled by 1e8)
     * @param _token The token address
     * @return The token amount
     */
    function _fromUsd(
        uint256 _amount,
        address _token
    ) internal view returns (uint256) {
        if (_amount == 0) return _amount;
        unchecked {
            return
                (_amount * (uint256(tokenInfo[_token].decimals))) /
                _getCompoundPrice(_token);
        }
    }

    /**
     * @notice Gets available balance of asset token
     * @return The asset token balance
     */
    function balanceOfAsset() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    /**
     * @notice Gets supplied collateral balance
     * @return Collateral balance
     */
    function balanceOfCollateral() public view returns (uint256) {
        return
            uint256(
                comet.userCollateral(address(this), address(asset)).balance
            );
    }

    /**
     * @notice Gets available base token balance
     * @return Base token balance
     */
    function balanceOfBaseToken() public view returns (uint256) {
        return ERC20(baseToken).balanceOf(address(this));
    }

    /**
     * @notice Gets depositor's Comet market balance
     * @return Depositor Comet balance
     */
    function balanceOfDepositor() public view returns (uint256) {
        return depositor.cometBalance();
    }

    /**
     * @notice Gets current borrow balance
     * @return Borrow balance
     */
    function balanceOfDebt() public view returns (uint256) {
        return comet.borrowBalanceOf(address(this));
    }

    /**
     * @notice Gets net owed base tokens (borrowed - supplied)
     * @return Net base tokens owed
     */
    function baseTokenOwedBalance() public view returns (uint256) {
        uint256 have = balanceOfDepositor() + balanceOfBaseToken();
        uint256 owe = balanceOfDebt();

        /// If they are the same or supply > debt return 0
        if (have >= owe) return 0;

        unchecked {
            return owe - have;
        }
    }

    /**
     * @notice Gets base tokens owed in asset terms
     * @return owed tokens owed in asset value
     */
    function _baseTokenOwedInAsset() internal view returns (uint256 owed) {
        /// Don't do conversions unless it's a non-zero false.
        uint256 owedInBase = baseTokenOwedBalance();
        if (owedInBase != 0) {
            owed = _fromUsd(_toUsd(owedInBase, baseToken), address(asset));
        }
    }

    /**
     * @notice Estimates accrued rewards in asset terms
     * @return Estimated rewards in asset value
     */
    function rewardsInAsset() public view returns (uint256) {
        /// Under report by 10% for safety
        return
            (_fromUsd(
                _toUsd(depositor.getRewardsOwed(), rewardToken),
                address(asset)
            ) * 9_000) / MAX_BPS;
    }

    /**
     * @notice Gets net borrow APR from depositor
     * @param newAmount Simulated supply amount
     * @return Net borrow APR
     */
    function getNetBorrowApr(uint256 newAmount) public view returns (uint256) {
        return depositor.getNetBorrowApr(newAmount);
    }

    /**
     * @notice Gets net reward APR from depositor
     * @param newAmount Simulated supply amount
     * @return Net reward APR
     */
    function getNetRewardApr(uint256 newAmount) public view returns (uint256) {
        return depositor.getNetRewardApr(newAmount);
    }

    /**
     * @notice Gets liquidation collateral factor for asset
     * @return Liquidation collateral factor
     */
    function getLiquidateCollateralFactor() public view returns (uint256) {
        return
            uint256(
                comet
                    .getAssetInfoByAddress(address(asset))
                    .liquidateCollateralFactor
            );
    }

    /**
     * @notice Gets price feed address for an asset
     * @param _asset The asset address
     * @return priceFeed price feed address
     */
    function _getPriceFeedAddress(
        address _asset
    ) internal view returns (address priceFeed) {
        priceFeed = tokenInfo[_asset].priceFeed;
        if (priceFeed == address(0)) {
            priceFeed = comet.getAssetInfoByAddress(_asset).priceFeed;
        }
    }

    /**
     * @notice Gets asset price from Compound
     * @dev Handles scaling for WETH
     * @param _asset The asset address
     * @return price asset price
     */
    function _getCompoundPrice(
        address _asset
    ) internal view returns (uint256 price) {
        price = comet.getPrice(_getPriceFeedAddress(_asset));
        /// If weth is base token we need to scale response to e18
        if (price == 1e8 && _asset == weth) price = 1e18;
    }

    /**
     * @notice Calculates current loan-to-value ratio
     * @dev Converts collateral and debt values to USD
     * @return Current LTV in 1e18 format
     */
    function getCurrentLTV() external view returns (uint256) {
        unchecked {
            return
                (_toUsd(balanceOfDebt(), baseToken) * 1e18) /
                _toUsd(balanceOfCollateral(), address(asset));
        }
    }

    /**
     * @notice Gets target loan-to-value ratio
     * @dev Calculates based on liquidation threshold and multiplier
     * @return Target LTV in 1e18 format
     */
    function _getTargetLTV() internal view returns (uint256) {
        unchecked {
            return
                (getLiquidateCollateralFactor() * targetLTVMultiplier) /
                MAX_BPS;
        }
    }

    /**
     * @notice Gets warning loan-to-value ratio
     * @dev Calculates based on liquidation threshold and multiplier
     * @return Warning LTV in 1e18 format
     */
    function _getWarningLTV() internal view returns (uint256) {
        unchecked {
            return
                (getLiquidateCollateralFactor() * warningLTVMultiplier) /
                MAX_BPS;
        }
    }

    /// ----------------- HARVEST / TOKEN CONVERSIONS -----------------

    /**
     * @notice Claims earned reward tokens
     */
    function claimRewards() external onlyKeepers {
        _claimRewards(true);
    }

    /**
     * @notice Claims reward tokens from Comet and depositor
     */
    function _claimRewards(bool _accrue) internal {
        rewardsContract.claim(address(comet), address(this), _accrue);
        /// Pull rewards from depositor even if not incentivized to accrue the account
        depositor.claimRewards(_accrue);
    }

    /**
     * @notice Claims and sells available reward tokens
     * @dev Handles claiming, selling rewards for base tokens if needed, and selling remaining rewards for asset
     */
    function _claimAndSellRewards() internal {
        // Claim rewards should have already been accrued.
        _claimRewards(false);

        uint256 rewardTokenBalance;
        uint256 baseNeeded = baseTokenOwedBalance();

        if (baseNeeded > 0) {
            rewardTokenBalance = ERC20(rewardToken).balanceOf(address(this));
            /// We estimate how much we will need in order to get the amount of base
            /// Accounts for slippage and diff from oracle price, just to assure no horrible sandwich
            uint256 maxRewardToken = (_fromUsd(
                _toUsd(baseNeeded, baseToken),
                rewardToken
            ) * (MAX_BPS + slippage)) / MAX_BPS;
            if (maxRewardToken < rewardTokenBalance) {
                /// If we have enough swap an exact amount out
                _swapTo(rewardToken, baseToken, baseNeeded, maxRewardToken);
            } else {
                /// if not swap everything we have
                _swapFrom(
                    rewardToken,
                    baseToken,
                    rewardTokenBalance,
                    _getAmountOut(rewardTokenBalance, rewardToken, baseToken)
                );
            }
        }

        rewardTokenBalance = ERC20(rewardToken).balanceOf(address(this));
        _swapFrom(
            rewardToken,
            address(asset),
            rewardTokenBalance,
            _getAmountOut(rewardTokenBalance, rewardToken, address(asset))
        );
    }

    /**
     * @dev Buys the base token using the strategy's assets.
     * This function should only ever be called when withdrawing all funds from the strategy if there is debt left over.
     * Initially, it tries to sell rewards for the needed amount of base token, then it will swap assets.
     * Using this function in a standard withdrawal can cause it to be sandwiched, which is why rewards are used first.
     */
    function _buyBaseToken() internal {
        /// Try to obtain the required amount from rewards tokens before swapping assets and reporting losses.
        _claimAndSellRewards();

        uint256 baseStillOwed = baseTokenOwedBalance();
        /// Check if our debt balance is still greater than our base token balance
        if (baseStillOwed > 0) {
            /// Need to account for both slippage and diff in the oracle price.
            /// Should be only swapping very small amounts so its just to make sure there is no massive sandwich
            uint256 maxAssetBalance = (_fromUsd(
                _toUsd(baseStillOwed, baseToken),
                address(asset)
            ) * (MAX_BPS + slippage)) / MAX_BPS;
            /// Under 10 can cause rounding errors from token conversions, no need to swap that small amount
            if (maxAssetBalance <= 10) return;

            _swapFrom(
                address(asset),
                baseToken,
                baseStillOwed,
                maxAssetBalance
            );
        }
    }

    /**
     * @notice Estimates swap output accounting for slippage
     * @param _amount Input amount
     * @param _from Input token
     * @param _to Output token
     * @return Estimated output amount
     */
    function _getAmountOut(
        uint256 _amount,
        address _from,
        address _to
    ) internal view returns (uint256) {
        if (_amount == 0) return 0;

        return
            (_fromUsd(_toUsd(_amount, _from), _to) * (MAX_BPS - slippage)) /
            MAX_BPS;
    }

    /**
     * @notice Checks if base fee is acceptable
     * @return True if base fee is below threshold
     */
    function _isBaseFeeAcceptable() internal view returns (bool) {
        return block.basefee <= maxGasPriceToTend;
    }

    /**
     * @dev Optional function for a strategist to override that will
     * allow management to manually withdraw deployed funds from the
     * yield source if a strategy is shutdown.
     *
     * This should attempt to free `_amount`, noting that `_amount` may
     * be more than is currently deployed.
     *
     * NOTE: This will not realize any profits or losses. A separate
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
            depositor.withdraw(
                Math.min(_amount, depositor.accruedCometBalance())
            );
        }
        // Repay everything we can.
        _repayTokenDebt();

        // Withdraw all that makes sense.
        _withdraw(address(asset), _maxWithdrawal());
    }

    // Manually repay debt with loose baseToken already in the strategy.
    function manualRepayDebt() external onlyEmergencyAuthorized {
        _repayTokenDebt();
    }
}
