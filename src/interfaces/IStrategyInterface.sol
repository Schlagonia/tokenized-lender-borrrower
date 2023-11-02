// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import {IBaseHealthCheck} from "@periphery/HealthCheck/IBaseHealthCheck.sol";
import {IUniswapV3Swapper} from "@periphery/swappers/interfaces/IUniswapV3Swapper.sol";

interface IStrategyInterface is IBaseHealthCheck, IUniswapV3Swapper {
    struct TokenInfo {
        address priceFeed;
        uint96 decimals;
    }

    function tokenInfo(address) external view returns (TokenInfo memory);

    function baseToken() external view returns (address);

    function targetLTVMultiplier() external view returns (uint16);

    function warningLTVMultiplier() external view returns (uint16);

    function slippage() external view returns (uint256);

    function depositor() external view returns (address);

    function setStrategyParams(
        uint16 _targetLTVMultiplier,
        uint16 _warningLTVMultiplier,
        uint256 _minToSell,
        uint256 _slippage,
        bool _leaveDebtBehind,
        uint256 _maxGasPriceToTend
    ) external;

    function initializeCompV3LenderBorrower(
        address _comet,
        uint24 _ethToAssetFee,
        address _depositor
    ) external;

    function leaveDebtBehind() external view returns (bool);

    function maxGasPriceToTend() external view returns (uint256);

    function balanceOfAsset() external view returns (uint256);

    function balanceOfCollateral() external view returns (uint256);

    function balanceOfBaseToken() external view returns (uint256);

    function balanceOfDepositor() external view returns (uint256);

    function balanceOfDebt() external view returns (uint256);

    function baseTokenOwedBalance() external view returns (uint256);

    function rewardsInAsset() external view returns (uint256);

    function getNetBorrowApr(uint256 newAmount) external view returns (uint256);

    function getNetRewardApr(uint256 newAmount) external view returns (uint256);

    function getLiquidateCollateralFactor() external view returns (uint256);

    function getCurrentLTV() external view returns (uint256);

    function claimAndSellRewards() external;

    function manualRepayDebt() external;

    function manualWithdraw() external;
}
