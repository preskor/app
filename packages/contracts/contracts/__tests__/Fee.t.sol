// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "./BaseTest.t.sol";
import {IPredictionMarket} from "../interfaces/IPredictionMarket.sol";

/**
 * @title FeeTest
 * @notice Tests for fee collection and withdrawal
 */
contract FeeTest is BaseTest {

    function test_CollectPerformanceFee() public {
        uint256 startTime = block.timestamp + 100;
        uint256 endTime = startTime + 1 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        // User1 bets 100 USDC
        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), 100e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, 100e6);
        vm.stopPrank();

        // User2 bets 100 USDC
        vm.startPrank(user2);
        usdc.approve(address(market.bettingEngine()), 100e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.AwayWin, 100e6);
        vm.stopPrank();

        uint256 feesBefore = market.getAccumulatedFees();

        vm.warp(endTime + 1);
        market.resolveMarket(marketId, IPredictionMarket.MatchOutcome.HomeWin);

        uint256 feesAfter = market.getAccumulatedFees();

        // Fee should be 2% of 200 USDC = 4 USDC
        assertEq(feesAfter, feesBefore + 4e6);
    }

    function test_WithdrawFees() public {
        uint256 startTime = block.timestamp + 100;
        uint256 endTime = startTime + 1 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        // User1 bets 100 USDC
        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), 100e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, 100e6);
        vm.stopPrank();

        // User2 bets 100 USDC
        vm.startPrank(user2);
        usdc.approve(address(market.bettingEngine()), 100e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.AwayWin, 100e6);
        vm.stopPrank();

        vm.warp(endTime + 1);
        market.resolveMarket(marketId, IPredictionMarket.MatchOutcome.HomeWin);

        uint256 feesBefore = market.getAccumulatedFees();
        uint256 ownerBalanceBefore = usdc.balanceOf(owner);

        market.withdrawFees();

        uint256 ownerBalanceAfter = usdc.balanceOf(owner);

        assertEq(ownerBalanceAfter, ownerBalanceBefore + feesBefore);
        assertEq(market.getAccumulatedFees(), 0);
    }

    function test_WithdrawFeesMultipleMarkets() public {
        // Create and resolve first market
        uint256 startTime1 = block.timestamp + 100;
        uint256 endTime1 = startTime1 + 1 hours;
        uint256 marketId1 = market.createMarket(teamHomeId, teamAwayId, startTime1, endTime1);

        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), 100e6);
        market.placeBet(marketId1, IPredictionMarket.MatchOutcome.HomeWin, 100e6);
        vm.stopPrank();

        vm.warp(endTime1 + 1);
        market.resolveMarket(marketId1, IPredictionMarket.MatchOutcome.HomeWin);

        // Create and resolve second market
        uint256 startTime2 = block.timestamp + 100;
        uint256 endTime2 = startTime2 + 1 hours;
        uint256 marketId2 = market.createMarket(teamHomeId, teamAwayId, startTime2, endTime2);

        vm.startPrank(user2);
        usdc.approve(address(market.bettingEngine()), 100e6);
        market.placeBet(marketId2, IPredictionMarket.MatchOutcome.AwayWin, 100e6);
        vm.stopPrank();

        vm.warp(endTime2 + 1);
        market.resolveMarket(marketId2, IPredictionMarket.MatchOutcome.AwayWin);

        uint256 feesBefore = market.getAccumulatedFees();

        market.withdrawFees();

        // Fee from market1 (2% of 100) + Fee from market2 (2% of 100) = 2 + 2 = 4
        assertEq(feesBefore, 4e6);
        assertEq(market.getAccumulatedFees(), 0);
    }

    function test_RevertWithdrawFeesNonOwner() public {
        uint256 startTime = block.timestamp + 100;
        uint256 endTime = startTime + 1 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), 100e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, 100e6);
        vm.stopPrank();

        vm.warp(endTime + 1);
        market.resolveMarket(marketId, IPredictionMarket.MatchOutcome.HomeWin);

        vm.prank(user1);
        vm.expectRevert();
        market.withdrawFees();
    }
}

