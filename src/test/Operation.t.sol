// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {Setup, IStrategyInterface, ERC20, Comet} from "./utils/Setup.sol";

contract OperationTest is Setup {
    function setUp() public virtual override {
        super.setUp();
    }

    function testSetupStrategyOK() public {
        console.log("address of strategy", address(strategy));
        assertTrue(address(0) != address(strategy));
        assertEq(strategy.asset(), address(asset));
        assertEq(strategy.management(), management);
        assertEq(strategy.performanceFeeRecipient(), performanceFeeRecipient);
        assertEq(strategy.keeper(), keeper);
        // TODO: add additional check on strat params
    }

    function test_operation(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        uint256 targetLTV = (strategy.getLiquidateCollateralFactor() *
            strategy.targetLTVMultiplier()) / MAX_BPS;
        // Deposit into strategy
        mintAndDepositIntoStrategy(strategy, user, _amount);

        checkStrategyTotals(strategy, _amount, _amount, 0);
        assertRelApproxEq(strategy.getCurrentLTV(), targetLTV, 1000);
        assertEq(strategy.balanceOfCollateral(), _amount, "collateral");
        assertApproxEq(
            strategy.balanceOfDebt(),
            strategy.balanceOfDepositor(),
            3
        );
        // Earn Interest
        skip(1 days);

        // Report profit
        vm.prank(keeper);
        (uint256 profit, uint256 loss) = strategy.report();

        // Check return Values
        assertGe(profit, 0, "!profit");
        assertEq(loss, 0, "!loss");

        skip(strategy.profitMaxUnlockTime());

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

    function test_partialWithdraw_highLTV(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        uint256 targetLTV = (strategy.getLiquidateCollateralFactor() *
            strategy.targetLTVMultiplier()) / MAX_BPS;
        // Deposit into strategy
        mintAndDepositIntoStrategy(strategy, user, _amount);

        checkStrategyTotals(strategy, _amount, _amount, 0);
        assertRelApproxEq(strategy.getCurrentLTV(), targetLTV, 1000);
        assertEq(strategy.balanceOfCollateral(), _amount, "collateral");
        assertApproxEq(
            strategy.balanceOfDebt(),
            strategy.balanceOfDepositor(),
            3
        );
        // Earn Interest
        skip(1 days);

        // Increase LTV
        uint256 toBorrow = (strategy.balanceOfCollateral() *
            ((strategy.getLiquidateCollateralFactor() *
                (strategy.targetLTVMultiplier() + 500)) / MAX_BPS)) / 1e18;

        toBorrow = _fromUsd(_toUsd(toBorrow, address(asset)), baseToken);

        vm.startPrank(address(strategy));
        Comet(comet).withdraw(
            address(baseToken),
            toBorrow - strategy.balanceOfDebt()
        );
        vm.stopPrank();

        assertGt(strategy.getCurrentLTV(), targetLTV);

        uint256 balanceBefore = asset.balanceOf(user);

        // Withdraw all funds
        vm.prank(user);
        strategy.redeem(_amount / 2, user, user, 1);

        assertGe(
            asset.balanceOf(user),
            ((balanceBefore + (_amount / 2)) * 9_999) / MAX_BPS,
            "!final balance"
        );
    }

    function test_partialWithdraw_lowerLTV(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        uint256 targetLTV = (strategy.getLiquidateCollateralFactor() *
            strategy.targetLTVMultiplier()) / MAX_BPS;
        // Deposit into strategy
        mintAndDepositIntoStrategy(strategy, user, _amount);

        checkStrategyTotals(strategy, _amount, _amount, 0);
        assertRelApproxEq(strategy.getCurrentLTV(), targetLTV, 1000);
        assertEq(strategy.balanceOfCollateral(), _amount, "collateral");
        assertApproxEq(
            strategy.balanceOfDebt(),
            strategy.balanceOfDepositor(),
            3
        );
        // Earn Interest
        skip(1 days);

        // lower LTV
        uint256 borrowed = strategy.balanceOfDebt();
        airdrop(ERC20(baseToken), address(strategy), borrowed / 4);

        vm.prank(management);
        strategy.manualRepayDebt();

        assertLt(strategy.getCurrentLTV(), targetLTV);

        uint256 balanceBefore = asset.balanceOf(user);

        // Withdraw all funds
        vm.prank(user);
        strategy.redeem(_amount / 2, user, user, 1);

        assertGe(
            asset.balanceOf(user),
            ((balanceBefore + (_amount / 2)) * 9_999) / MAX_BPS,
            "!final balance"
        );
    }

    function test_healthcheck(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        uint256 targetLTV = (strategy.getLiquidateCollateralFactor() *
            strategy.targetLTVMultiplier()) / MAX_BPS;
        // Deposit into strategy
        mintAndDepositIntoStrategy(strategy, user, _amount);

        checkStrategyTotals(strategy, _amount, _amount, 0);
        assertRelApproxEq(strategy.getCurrentLTV(), targetLTV, 1000);
        assertEq(strategy.balanceOfCollateral(), _amount, "collateral");
        assertApproxEq(
            strategy.balanceOfDebt(),
            strategy.balanceOfDepositor(),
            3
        );
        // Earn Interest
        skip(1 days);

        // Simulate loss of base token
        vm.startPrank(address(depositor));
        Comet(comet).withdraw(baseToken, strategy.balanceOfDebt() / 2);
        ERC20(baseToken).transfer(
            management,
            ERC20(baseToken).balanceOf(address(depositor))
        );
        vm.stopPrank();

        // Shouldn't aut record loss
        vm.expectRevert("healthCheck");
        vm.prank(keeper);
        strategy.report();

        vm.prank(management);
        strategy.setDoHealthCheck(false);

        vm.prank(keeper);
        (uint256 profit, uint256 loss) = strategy.report();

        // Check return Values
        assertEq(profit, 0, "!profit");
        assertGt(loss, 0, "!loss");

        // Make sure we got back to our Target LTV.
        assertRelApproxEq(strategy.getCurrentLTV(), targetLTV, 1000);

        uint256 balanceBefore = asset.balanceOf(user);

        // Withdraw all funds
        vm.prank(user);
        strategy.redeem(_amount, user, user);

        assertLt(
            asset.balanceOf(user),
            balanceBefore + _amount,
            "!final balance"
        );
    }

    function test_profitableReport(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        uint256 targetLTV = (strategy.getLiquidateCollateralFactor() *
            strategy.targetLTVMultiplier()) / MAX_BPS;
        // Deposit into strategy
        mintAndDepositIntoStrategy(strategy, user, _amount);

        checkStrategyTotals(strategy, _amount, _amount, 0);

        // Earn Interest
        skip(1 days);

        // Report profit
        vm.prank(keeper);
        (uint256 profit, uint256 loss) = strategy.report();

        assertRelApproxEq(strategy.getCurrentLTV(), targetLTV, 1000);
        assertGt(strategy.totalAssets(), _amount);
        // Check return Values
        assertGt(profit, 0, "!profit");
        assertEq(loss, 0, "!loss");

        skip(strategy.profitMaxUnlockTime());

        uint256 balanceBefore = asset.balanceOf(user);

        // Withdraw all funds
        vm.prank(user);
        strategy.redeem(_amount / 2, user, user);

        assertGe(
            asset.balanceOf(user),
            balanceBefore + (_amount / 2),
            "!final balance"
        );

        assertRelApproxEq(strategy.getCurrentLTV(), targetLTV, 1000);
    }

    function test_profitableReport_withFees(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);
        uint256 targetLTV = (strategy.getLiquidateCollateralFactor() *
            strategy.targetLTVMultiplier()) / MAX_BPS;

        // Set protocol fee to 0 and perf fee to 10%
        setFees(0, 1_000);

        // Deposit into strategy
        mintAndDepositIntoStrategy(strategy, user, _amount);

        checkStrategyTotals(strategy, _amount, _amount, 0);
        assertRelApproxEq(strategy.getCurrentLTV(), targetLTV, 1000);

        // Earn Interest
        skip(1 days);

        // Report profit
        vm.prank(keeper);
        (uint256 profit, uint256 loss) = strategy.report();
        assertRelApproxEq(strategy.getCurrentLTV(), targetLTV, 1000);
        // Check return Values
        assertGt(profit, 0, "!profit");
        assertEq(loss, 0, "!loss");

        skip(strategy.profitMaxUnlockTime());

        // Get the expected fee
        uint256 expectedShares = (profit * 1_000) / MAX_BPS;

        assertEq(strategy.balanceOf(performanceFeeRecipient), expectedShares);

        uint256 balanceBefore = asset.balanceOf(user);

        // Withdraw all funds
        vm.prank(user);
        strategy.redeem(_amount, user, user);

        assertGe(
            asset.balanceOf(user),
            balanceBefore + _amount,
            "!final balance"
        );

        //assertRelApproxEq(strategy.getCurrentLTV(), targetLTV, 1000);

        vm.prank(performanceFeeRecipient);
        strategy.redeem(
            expectedShares,
            performanceFeeRecipient,
            performanceFeeRecipient
        );

        checkStrategyTotals(strategy, 0, 0, 0);

        assertGe(
            asset.balanceOf(performanceFeeRecipient),
            expectedShares,
            "!perf fee out"
        );
    }

    function test_leaveDebtBehind_realizesLoss(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        vm.startPrank(management);
        strategy.setStrategyParams(
            strategy.depositLimit(),
            strategy.targetLTVMultiplier(),
            strategy.warningLTVMultiplier(),
            strategy.minAmountToSell(),
            strategy.slippage(),
            true,
            strategy.maxGasPriceToTend()
        );
        vm.stopPrank();

        uint256 targetLTV = (strategy.getLiquidateCollateralFactor() *
            strategy.targetLTVMultiplier()) / MAX_BPS;
        // Deposit into strategy
        mintAndDepositIntoStrategy(strategy, user, _amount);

        checkStrategyTotals(strategy, _amount, _amount, 0);
        assertRelApproxEq(strategy.getCurrentLTV(), targetLTV, 1000);
        assertEq(strategy.balanceOfCollateral(), _amount, "collateral");
        assertApproxEq(
            strategy.balanceOfDebt(),
            strategy.balanceOfDepositor(),
            3
        );
        // Earn unrealized profit.
        skip(1 days);

        uint256 balanceBefore = asset.balanceOf(user);

        // Redeem all funds. Default maxLoss == 10_000.
        vm.prank(user);
        strategy.redeem(_amount, user, user);

        // We should not have got the full amount out.
        assertLt(
            asset.balanceOf(user),
            balanceBefore + _amount,
            "!final balance"
        );
    }

    function test_availableWithdrawLimit(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        uint256 targetLTV = (strategy.getLiquidateCollateralFactor() *
            strategy.targetLTVMultiplier()) / MAX_BPS;
        // Deposit into strategy
        mintAndDepositIntoStrategy(strategy, user, _amount);

        checkStrategyTotals(strategy, _amount, _amount, 0);
        assertRelApproxEq(strategy.getCurrentLTV(), targetLTV, 1000);
        assertEq(strategy.balanceOfCollateral(), _amount, "collateral");
        assertApproxEq(
            strategy.balanceOfDebt(),
            strategy.balanceOfDepositor(),
            3
        );
        // Earn unrealized profit.
        skip(1 days);

        uint256 baseBalance = ERC20(baseToken).balanceOf(comet);
        uint256 debt = strategy.balanceOfDebt();

        // Simulate only enough liquidity to repay half our debt
        vm.prank(comet);
        ERC20(baseToken).transfer(management, baseBalance - (debt / 2));

        assertRelApproxEq(strategy.maxWithdraw(user), _amount / 2, 1000);
        assertRelApproxEq(strategy.maxRedeem(user), _amount / 2, 1000);

        uint256 balanceBefore = asset.balanceOf(user);

        // Redeem all funds. Default maxLoss == 10_000.
        vm.prank(user);
        strategy.redeem(_amount / 2, user, user);

        // We should not have got the full amount out.
        assertLt(
            asset.balanceOf(user),
            balanceBefore + (_amount / 2),
            "!final balance"
        );
    }

    function test_buffer(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        uint256 toBorrow = (_amount *
            ((strategy.getLiquidateCollateralFactor() *
                strategy.targetLTVMultiplier()) / MAX_BPS)) / 1e18;

        assertEq(depositor.buffer(), 100);

        uint256 initialNet = depositor.getNetRewardApr(toBorrow);
        uint256 initialSupply = depositor.getRewardAprForSupplyBase(toBorrow);
        uint256 initialBorrow = depositor.getRewardAprForBorrowBase(toBorrow);

        vm.expectRevert("!management");
        vm.prank(user);
        depositor.setBuffer(0);

        vm.expectRevert("higher than MAX_BPS");
        vm.prank(management);
        depositor.setBuffer(10_001);

        // Decrease buffer
        vm.prank(management);
        depositor.setBuffer(0);

        assertEq(depositor.buffer(), 0);
        // Reward APR should now be higher with less buffer
        assertGt(depositor.getNetRewardApr(toBorrow), initialNet);
        assertGt(depositor.getRewardAprForSupplyBase(toBorrow), initialSupply);
        assertGt(depositor.getRewardAprForBorrowBase(toBorrow), initialBorrow);

        // Increase buffer
        vm.prank(management);
        depositor.setBuffer(500);

        assertEq(depositor.buffer(), 500);
        // Reward APR should now be lower with more buffer
        assertLt(depositor.getNetRewardApr(toBorrow), initialNet);
        assertLt(depositor.getRewardAprForSupplyBase(toBorrow), initialSupply);
        assertLt(depositor.getRewardAprForBorrowBase(toBorrow), initialBorrow);
    }

    function test_tendTrigger(uint256 _amount) public {
        vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

        uint256 targetLTV = (strategy.getLiquidateCollateralFactor() *
            strategy.targetLTVMultiplier()) / MAX_BPS;

        // No assets should be false.
        (bool trigger, ) = strategy.tendTrigger();
        assertTrue(!trigger);

        // Deposit into strategy
        mintAndDepositIntoStrategy(strategy, user, _amount);

        (trigger, ) = strategy.tendTrigger();
        assertTrue(!trigger);

        // Skip some time
        skip(1 days);

        (trigger, ) = strategy.tendTrigger();
        assertTrue(!trigger);

        // Borrow too much.
        uint256 toBorrow = (strategy.balanceOfCollateral() *
            ((strategy.getLiquidateCollateralFactor() *
                strategy.warningLTVMultiplier()) / MAX_BPS)) / 1e18;

        toBorrow = _fromUsd(_toUsd(toBorrow, address(asset)), baseToken);

        vm.startPrank(address(strategy));
        Comet(comet).withdraw(
            address(baseToken),
            toBorrow - strategy.balanceOfDebt() + 100000
        );
        vm.stopPrank();

        (trigger, ) = strategy.tendTrigger();
        assertTrue(trigger, "warning ltv");

        // Even with a 0 for max Tend Base Fee its true
        vm.startPrank(management);
        strategy.setStrategyParams(
            strategy.depositLimit(),
            strategy.targetLTVMultiplier(),
            strategy.warningLTVMultiplier(),
            strategy.minAmountToSell(),
            strategy.slippage(),
            strategy.leaveDebtBehind(),
            0
        );
        vm.stopPrank();

        (trigger, ) = strategy.tendTrigger();
        assertTrue(trigger, "warning ltv 2");

        // Even with a 0 for max Tend Base Fee its true
        vm.startPrank(management);
        strategy.setStrategyParams(
            strategy.depositLimit(),
            strategy.targetLTVMultiplier(),
            strategy.warningLTVMultiplier(),
            strategy.minAmountToSell(),
            strategy.slippage(),
            strategy.leaveDebtBehind(),
            200e9
        );
        vm.stopPrank();

        vm.prank(keeper);
        strategy.tend();

        (trigger, ) = strategy.tendTrigger();
        assertTrue(!trigger, "post tend");

        vm.prank(keeper);
        strategy.report();

        // Lower LTV
        uint256 borrowed = strategy.balanceOfDebt();
        airdrop(ERC20(baseToken), address(strategy), borrowed / 2);

        vm.prank(management);
        strategy.manualRepayDebt();

        assertLt(strategy.getCurrentLTV(), targetLTV);

        (trigger, ) = strategy.tendTrigger();
        assertTrue(trigger);

        vm.prank(keeper);
        strategy.tend();

        (trigger, ) = strategy.tendTrigger();
        assertTrue(!trigger, "post tend");

        // Unlock Profits
        skip(strategy.profitMaxUnlockTime());

        (trigger, ) = strategy.tendTrigger();
        assertTrue(!trigger);

        vm.prank(user);
        strategy.redeem(_amount, user, user);

        (trigger, ) = strategy.tendTrigger();
        assertTrue(!trigger);
    }
}
