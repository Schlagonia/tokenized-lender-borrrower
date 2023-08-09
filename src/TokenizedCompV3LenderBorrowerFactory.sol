// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import "./Depositer.sol";
import "./Strategy.sol";

import {IStrategyInterface} from "./interfaces/IStrategyInterface.sol";

contract TokenizedCompV3LenderBorrowerFactory {

    address public immutable managment;
    address public immutable rewards;
    address public immutable keeper;

    event Deployed(address indexed depositer, address indexed strategy);

    constructor(
        address _managment,
        address _rewards,
        address _keeper
    ) {
        managment = _managment;
        rewards = _rewards;
        keeper = _keeper;
    }

    function name() external pure returns (string memory) {
        return "Yearnv3-TokeinzedCompV3LenderBorrowerFactory";
    }

    function newCompV3LenderBorrower(
        address _asset,
        string memory _name,
        address _comet,
        uint24 _ethToAssetFee
    ) external returns (address, address) {
        Depositer depositer = new Depositer();
        depositer.initialize(_comet);

        // Need to give the address the correct interface.
        IStrategyInterface strategy = IStrategyInterface(
            address(new Strategy(
                _asset,
                _name,
                _comet,
                _ethToAssetFee,
                address(depositer)
            ))
        );

        // Set strategy on Depositer.
        depositer.setStrategy(address(strategy));

        // Set the initial Strategy Params.
        strategy.setStrategyParams(
            7_000, // targetLTVMultiplier (default: 7_000)
            8_000, // warningLTVMultiplier default: 8_000
            1e10, // min rewards to sell
            false, // leave debt behind (default: false)
            40 * 1e9 // max base fee to perform non-emergency tends (default: 40 gwei)
        );

        // Set the addresses.
        strategy.setPerformanceFeeRecipient(rewards);
        strategy.setKeeper(keeper);
        strategy.setPendingManagement(managment);

        emit Deployed(address(depositer), address(strategy));
        return (address(depositer), address(strategy));
    }
}