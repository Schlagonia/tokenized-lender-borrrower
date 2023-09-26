// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import {IBaseHealthCheck} from "@periphery/HealthCheck/IBaseHealthCheck.sol";
import {IUniswapV3Swapper} from "@periphery/swappers/interfaces/IUniswapV3Swapper.sol";

interface IStrategyInterface is IBaseHealthCheck, IUniswapV3Swapper {
    function baseToken() external view returns (address);

    function depositor() external view returns (address);

    function setStrategyParams(
        uint16 _targetLTVMultiplier,
        uint16 _warningLTVMultiplier,
        uint256 _minToSell,
        bool _leaveDebtBehind,
        uint256 _maxGasPriceToTend
    ) external;

    function initializeCompV3LenderBorrower(
        address _comet,
        uint24 _ethToAssetFee,
        address _depositer
    ) external;
}
