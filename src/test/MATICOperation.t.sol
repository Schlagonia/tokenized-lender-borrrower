// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {OperationTest, ERC20} from "./Operation.t.sol";
import {ShutdownTest} from "./Shutdown.t.sol";

contract WMATICOperationTest is OperationTest {
    function setUp() public override {
        super.setUp();

        asset = ERC20(tokenAddrs["WMATIC"]);
        decimals = asset.decimals();
        minFuzzAmount = 400e18;
        maxFuzzAmount = 1e24;

        (depositor, strategy) = setUpStrategy();
    }
}

contract WMATICShutdownTest is ShutdownTest {
    function setUp() public override {
        super.setUp();

        asset = ERC20(tokenAddrs["WMATIC"]);
        decimals = asset.decimals();
        minFuzzAmount = 400e18;
        maxFuzzAmount = 1e24;

        (depositor, strategy) = setUpStrategy();
    }
}
