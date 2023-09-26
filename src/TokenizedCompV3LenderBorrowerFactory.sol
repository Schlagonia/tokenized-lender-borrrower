// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import "./Depositer.sol";
import "./Strategy.sol";

import {IStrategyInterface} from "./interfaces/IStrategyInterface.sol";

contract TokenizedCompV3LenderBorrowerFactory {
    address public immutable managment;
    address public immutable rewards;
    address public immutable keeper;
    address public immutable originalDepositer;

    event Deployed(address indexed depositer, address indexed strategy);

    constructor(address _managment, address _rewards, address _keeper) {
        managment = _managment;
        rewards = _rewards;
        keeper = _keeper;
        // Deploy an original depositer to clone
        originalDepositer = address(new Depositer());
    }

    function name() external pure returns (string memory) {
        return "TokenizedCompV3LenderBorrowerFactory";
    }

    function newCompV3LenderBorrower(
        address _asset,
        string memory _name,
        address _comet,
        uint24 _ethToAssetFee
    ) external returns (address, address) {
        address depositer = Depositer(originalDepositer).cloneDepositer(_comet);

        // Need to give the address the correct interface.
        IStrategyInterface strategy = IStrategyInterface(
            address(
                new Strategy(
                    _asset,
                    _name,
                    _comet,
                    _ethToAssetFee,
                    address(depositer)
                )
            )
        );

        // Set strategy on Depositer.
        Depositer(depositer).setStrategy(address(strategy));

        // Set the addresses.
        strategy.setPerformanceFeeRecipient(rewards);
        strategy.setKeeper(keeper);
        strategy.setPendingManagement(managment);

        emit Deployed(depositer, address(strategy));
        return (depositer, address(strategy));
    }
}
