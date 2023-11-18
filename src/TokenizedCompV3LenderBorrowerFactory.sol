// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import "./Depositor.sol";
import "./Strategy.sol";

import {IStrategyInterface} from "./interfaces/IStrategyInterface.sol";

contract TokenizedCompV3LenderBorrowerFactory {
    /// @notice Address of the contract managing the strategies
    address public management;
    /// @notice Address where performance fees are sent
    address public rewards;
    /// @notice Address of the keeper bot
    address public keeper;

    /// @notice Address of the original depositor contract used for cloning
    address public immutable originalDepositor;

    /// @notice Mapping of an asset => its deployed strategy if exists
    mapping (address => address) public deployedStrategy;

    /**
     * @notice Emitted when a new depositor and strategy are deployed
     * @param depositor Address of the deployed depositor contract
     * @param strategy Address of the deployed strategy contract
     */
    event Deployed(address indexed depositor, address indexed strategy);

    /**
     * @param _management Address of the management contract
     * @param _rewards Address where performance fees will be sent
     * @param _keeper Address of the keeper bot
     */
    constructor(address _management, address _rewards, address _keeper) {
        management = _management;
        rewards = _rewards;
        keeper = _keeper;
        /// Deploy an original depositor to clone
        originalDepositor = address(new Depositor());
    }

    function name() external pure returns (string memory) {
        return "TokenizedCompV3LenderBorrowerFactory";
    }

    /**
     * @notice Deploys a new tokenized Compound v3 lender/borrower pair
     * @param _asset Underlying asset address
     * @param _name Name for strategy
     * @param _comet Comet observatory address
     * @param _ethToAssetFee Conversion fee for ETH to asset
     * @return depositor Address of the deployed depositor
     * @return strategy Address of the deployed strategy
     */
    function newCompV3LenderBorrower(
        address _asset,
        string memory _name,
        address _comet,
        uint24 _ethToAssetFee
    ) external returns (address, address) {
        require(deployedStrategy[_asset] == address(0), "already deployed");

        address depositor = Depositor(originalDepositor).cloneDepositor(_comet);

        /// Need to give the address the correct interface.
        IStrategyInterface strategy = IStrategyInterface(
            address(
                new Strategy(
                    _asset,
                    _name,
                    _comet,
                    _ethToAssetFee,
                    address(depositor)
                )
            )
        );

        /// Set strategy on Depositor.
        Depositor(depositor).setStrategy(address(strategy));

        /// Set the addresses.
        strategy.setPerformanceFeeRecipient(rewards);
        strategy.setKeeper(keeper);
        strategy.setPendingManagement(management);

        // Add to the mapping.
        deployedStrategy[_asset] = address(strategy);

        emit Deployed(depositor, address(strategy));
        return (depositor, address(strategy));
    }

    function setAddresses(
        address _management,
        address _rewards,
        address _keeper
    ) external {
        require(msg.sender == management, "!management");
        management = _management;
        rewards = _rewards;
        keeper = _keeper;
    }
}
