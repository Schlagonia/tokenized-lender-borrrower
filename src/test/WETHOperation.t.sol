// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {OperationTest, ERC20} from "./Operation.t.sol";
import {ShutdownTest} from "./Shutdown.t.sol";

contract WETHOperationTest is OperationTest {
    function setUp() public override {
        super.setUp();

        asset = ERC20(tokenAddrs["WETH"]);
        decimals = asset.decimals();
        minFuzzAmount = 1e18;
        maxFuzzAmount = 1e21;

        (depositor, strategy) = setUpStrategy();
    }
}

contract WETHShutdownTest is ShutdownTest {
    function setUp() public override {
        super.setUp();

        asset = ERC20(tokenAddrs["WETH"]);
        decimals = asset.decimals();
        minFuzzAmount = 1e18;
        maxFuzzAmount = 1e21;

        (depositor, strategy) = setUpStrategy();
    }
}
