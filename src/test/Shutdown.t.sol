pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {Setup, ERC20} from "./utils/Setup.sol";

contract ShutdownTest is Setup {
    function setUp() public override {
        super.setUp();
    }

    function test_shutdownCanWithdraw(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        // Deposit into strategy
        mintAndDepositIntoStrategy(strategy, user, _amount);

        checkStrategyTotals(strategy, _amount, _amount, 0);

        // Earn Interest
        skip(1 days);

        // Shutdown the strategy
        vm.prank(management);
        strategy.shutdownStrategy();

        checkStrategyTotals(strategy, _amount, _amount, 0);

        // Make sure we can still withdraw the full amount
        uint256 balanceBefore = asset.balanceOf(user);

        // Withdraw all funds
        vm.prank(user);
        strategy.redeem(_amount, user, user);

        assertGe(
            asset.balanceOf(user),
            balanceBefore + _amount,
            "!final balance"
        );
    }

    function test_emergencyWithdraw(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        // Deposit into strategy
        mintAndDepositIntoStrategy(strategy, user, _amount);

        checkStrategyTotals(strategy, _amount, _amount, 0);

        // Earn Interest
        skip(1 days);

        // Shutdown the strategy
        vm.prank(management);
        strategy.shutdownStrategy();

        checkStrategyTotals(strategy, _amount, _amount, 0);

        vm.prank(management);
        strategy.emergencyWithdraw(type(uint256).max);

        assertEq(ERC20(strategy.baseToken()).balanceOf(address(strategy)), 0);
        assertEq(ERC20(strategy.baseToken()).balanceOf(address(depositor)), 0);
        assertEq(depositor.cometBalance(), 0);
        assertGt(strategy.totalIdle(), 0);
        assertLt(strategy.totalDebt(), _amount);
        assertLt(strategy.balanceOfCollateral(), _amount);

        // Make sure we can still withdraw the full amount
        uint256 balanceBefore = asset.balanceOf(user);

        // Withdraw all funds
        vm.prank(user);
        strategy.redeem(_amount, user, user);

        assertGe(
            asset.balanceOf(user),
            balanceBefore + _amount,
            "!final balance"
        );
    }

    function test_unwindBySettingBufferToMaxBps(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        // Deposit into strategy
        mintAndDepositIntoStrategy(strategy, user, _amount);

        checkStrategyTotals(strategy, _amount, _amount, 0);

        // Earn Interest
        skip(1 days);

        checkStrategyTotals(strategy, _amount, _amount, 0);

        uint256 ltv = strategy.getCurrentLTV();

        assertEq(ERC20(strategy.baseToken()).balanceOf(address(depositor)), 0);
        assertEq(ERC20(strategy.baseToken()).balanceOf(address(strategy)), 0);

        uint256 balance = depositor.cometBalance();

        vm.prank(management);
        depositor.setBuffer(10_000);

        // Tend trigger should be true
        (bool trigger, ) = strategy.tendTrigger();
        assertTrue(trigger);

        vm.prank(management);
        strategy.tend();

        // Tend trigger should be now be false
        (trigger, ) = strategy.tendTrigger();
        assertTrue(!trigger);

        // Tend should have pulled the full amounts out.
        checkStrategyTotals(strategy, _amount, 0, _amount);
        assertEq(strategy.balanceOfCollateral(), 0);
        assertGe(asset.balanceOf(address(strategy)), _amount);

        // Lower deposit limit to 0
        vm.startPrank(management);
        strategy.setStrategyParams(
            0,
            strategy.targetLTVMultiplier(),
            strategy.warningLTVMultiplier(),
            strategy.minAmountToSell(),
            strategy.slippage(),
            strategy.leaveDebtBehind(),
            strategy.maxGasPriceToTend()
        );
        vm.stopPrank();

        // deposit shouldn't work now
        assertEq(strategy.maxDeposit(user), 0);

        // And reports do not re-lever
        vm.prank(management);
        (uint256 gain, ) = strategy.report();

        assertGt(gain, 0);
        checkStrategyTotals(strategy, _amount + gain, 0, _amount + gain);
        assertEq(strategy.balanceOfCollateral(), 0);
        assertGe(asset.balanceOf(address(strategy)), _amount + gain);

        // Make sure we can still withdraw the full amount
        uint256 balanceBefore = asset.balanceOf(user);

        // Withdraw par of the funds
        vm.prank(user);
        strategy.redeem(_amount, user, user);

        assertGe(
            asset.balanceOf(user),
            balanceBefore + _amount,
            "!final balance"
        );
    }

    function test_manualWithdraw_noShutdown(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        // Deposit into strategy
        mintAndDepositIntoStrategy(strategy, user, _amount);

        checkStrategyTotals(strategy, _amount, _amount, 0);

        // Earn Interest
        skip(1 days);

        checkStrategyTotals(strategy, _amount, _amount, 0);

        uint256 ltv = strategy.getCurrentLTV();

        assertEq(ERC20(strategy.baseToken()).balanceOf(address(depositor)), 0);
        assertEq(ERC20(strategy.baseToken()).balanceOf(address(strategy)), 0);
        assertRelApproxEq(strategy.getCurrentLTV(), ltv, 10);

        uint256 balance = depositor.cometBalance();

        vm.expectRevert("!emergency authorized");
        vm.prank(user);
        depositor.manualWithdraw(balance);

        vm.prank(management);
        depositor.manualWithdraw(balance);

        assertEq(ERC20(strategy.baseToken()).balanceOf(address(depositor)), 0);
        assertEq(depositor.cometBalance(), 0);
        assertEq(
            ERC20(strategy.baseToken()).balanceOf(address(strategy)),
            balance
        );
        assertRelApproxEq(strategy.getCurrentLTV(), ltv, 10);

        vm.expectRevert("!emergency authorized");
        vm.prank(user);
        strategy.claimAndSellRewards();

        vm.prank(management);
        strategy.claimAndSellRewards();

        vm.expectRevert("!emergency authorized");
        vm.prank(user);
        strategy.manualRepayDebt();

        vm.prank(management);
        strategy.manualRepayDebt();

        assertEq(ERC20(strategy.baseToken()).balanceOf(address(depositor)), 0);
        assertEq(depositor.cometBalance(), 0);
        assertEq(ERC20(strategy.baseToken()).balanceOf(address(strategy)), 0);
        assertEq(strategy.getCurrentLTV(), 0);

        checkStrategyTotals(strategy, _amount, _amount, 0);

        // Set the LTV to 1 so it doesn't lever up
        vm.startPrank(management);
        strategy.setStrategyParams(
            strategy.depositLimit(),
            1,
            strategy.warningLTVMultiplier(),
            strategy.minAmountToSell(),
            strategy.slippage(),
            strategy.leaveDebtBehind(),
            strategy.maxGasPriceToTend()
        );
        vm.stopPrank();

        vm.prank(management);
        strategy.tend();

        // Make sure we can still withdraw the full amount
        uint256 balanceBefore = asset.balanceOf(user);

        // Withdraw par of the funds
        vm.prank(user);
        strategy.redeem(_amount / 2, user, user);

        assertGe(
            asset.balanceOf(user),
            balanceBefore + (_amount / 2),
            "!final balance"
        );
    }
}
