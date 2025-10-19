// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "./BaseTest.t.sol";
import {IPredictionMarket} from "../interfaces/IPredictionMarket.sol";

/**
 * @title IntegrationTest
 * @notice End-to-end integration tests for complete market lifecycle
 */
contract IntegrationTest is BaseTest {

    function test_CompleteMarketLifecycle() public {
        // Create market
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 2 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        // User1 places bet on HomeWin
        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), 100e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, 100e6);
        vm.stopPrank();

        // User2 places bet on AwayWin
        vm.startPrank(user2);
        usdc.approve(address(market.bettingEngine()), 200e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.AwayWin, 200e6);
        vm.stopPrank();

        // Check market state before resolution
        IPredictionMarket.Market memory mkt = market.getMarket(marketId);
        assertEq(mkt.totalStake, 300e6);
        assertEq(mkt.totalHomeStake, 100e6);
        assertEq(mkt.totalAwayStake, 200e6);

        // Resolve market
        vm.warp(endTime + 1);
        market.resolveMarket(marketId, IPredictionMarket.MatchOutcome.HomeWin);

        // User1 claims winnings
        uint256 user1BalanceBefore = usdc.balanceOf(user1);
        vm.prank(user1);
        market.claimWinnings(marketId);
        uint256 user1BalanceAfter = usdc.balanceOf(user1);

        // User1 should receive: 300 * 0.98 = 294 USDC (entire prize pool minus 2% fee)
        assertEq(user1BalanceAfter - user1BalanceBefore, 294e6);

        // Verify fees collected
        uint256 fees = market.getAccumulatedFees();
        assertEq(fees, 6e6); // 2% of 300 = 6

        // Owner withdraws fees
        uint256 ownerBalanceBefore = usdc.balanceOf(owner);
        market.withdrawFees();
        uint256 ownerBalanceAfter = usdc.balanceOf(owner);

        assertEq(ownerBalanceAfter - ownerBalanceBefore, 6e6);
        assertEq(market.getAccumulatedFees(), 0);
    }

    function test_MultipleMarketsSimultaneous() public {
        // Create two markets
        uint256 marketId1 = market.createMarket(
            teamHomeId,
            teamAwayId,
            block.timestamp + 1 hours,
            block.timestamp + 3 hours
        );

        uint256 marketId2 = market.createMarket(
            teamHomeId,
            teamAwayId,
            block.timestamp + 2 hours,
            block.timestamp + 4 hours
        );

        // Place bets on both markets
        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), 200e6);
        market.placeBet(marketId1, IPredictionMarket.MatchOutcome.HomeWin, 100e6);
        market.placeBet(marketId2, IPredictionMarket.MatchOutcome.AwayWin, 100e6);
        vm.stopPrank();

        // Verify both markets
        IPredictionMarket.Market memory mkt1 = market.getMarket(marketId1);
        IPredictionMarket.Market memory mkt2 = market.getMarket(marketId2);

        assertEq(mkt1.totalStake, 100e6);
        assertEq(mkt2.totalStake, 100e6);
        assertEq(uint256(mkt1.status), uint256(IPredictionMarket.MarketStatus.Open));
        assertEq(uint256(mkt2.status), uint256(IPredictionMarket.MarketStatus.Open));
    }

    function test_CancelledMarketRefunds() public {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 2 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        // Multiple users place bets
        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), 100e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, 100e6);
        vm.stopPrank();

        vm.startPrank(user2);
        usdc.approve(address(market.bettingEngine()), 200e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.AwayWin, 200e6);
        vm.stopPrank();

        // Cancel market
        market.cancelMarket(marketId);

        // Both users claim refunds
        uint256 user1BalanceBefore = usdc.balanceOf(user1);
        vm.prank(user1);
        market.claimWinnings(marketId);
        assertEq(usdc.balanceOf(user1) - user1BalanceBefore, 100e6);

        uint256 user2BalanceBefore = usdc.balanceOf(user2);
        vm.prank(user2);
        market.claimWinnings(marketId);
        assertEq(usdc.balanceOf(user2) - user2BalanceBefore, 200e6);
    }

    function test_DrawOutcome() public {
        uint256 startTime = block.timestamp + 100;
        uint256 endTime = startTime + 1 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        // User1 bets on Draw
        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), 100e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.Draw, 100e6);
        vm.stopPrank();

        // User2 bets on HomeWin
        vm.startPrank(user2);
        usdc.approve(address(market.bettingEngine()), 100e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, 100e6);
        vm.stopPrank();

        // Resolve as Draw
        vm.warp(endTime + 1);
        market.resolveMarket(marketId, IPredictionMarket.MatchOutcome.Draw);

        // User1 should win
        uint256 user1BalanceBefore = usdc.balanceOf(user1);
        vm.prank(user1);
        market.claimWinnings(marketId);
        uint256 user1BalanceAfter = usdc.balanceOf(user1);

        // Prize pool = 200 - 2% = 196
        assertEq(user1BalanceAfter - user1BalanceBefore, 196e6);
    }

    function test_AdminWorkflow() public {
        // Owner adds admin
        market.addAdmin(admin);
        assertTrue(market.isAdmin(admin));

        // Admin creates team
        vm.prank(admin);
        uint256 teamId = market.createTeam("Chelsea", "ipfs://chelsea");
        assertEq(teamId, 3);

        // Admin creates market
        vm.prank(admin);
        uint256 marketId = market.createMarket(
            teamHomeId,
            teamId,
            block.timestamp + 1 hours,
            block.timestamp + 3 hours
        );
        assertEq(marketId, 1);

        // Owner removes admin
        market.removeAdmin(admin);
        assertFalse(market.isAdmin(admin));

        // Admin can no longer create markets
        vm.prank(admin);
        vm.expectRevert();
        market.createMarket(
            teamHomeId,
            teamId,
            block.timestamp + 4 hours,
            block.timestamp + 6 hours
        );
    }

    function test_HighVolumeMarket() public {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 2 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        // User1 places large bet
        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), 5000e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, 5000e6);
        vm.stopPrank();

        // User2 places even larger bet
        vm.startPrank(user2);
        usdc.approve(address(market.bettingEngine()), 10000e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.AwayWin, 10000e6);
        vm.stopPrank();

        IPredictionMarket.Market memory mkt = market.getMarket(marketId);
        assertEq(mkt.totalStake, 15000e6);

        // Resolve and claim
        vm.warp(endTime + 1);
        market.resolveMarket(marketId, IPredictionMarket.MatchOutcome.HomeWin);

        vm.prank(user1);
        market.claimWinnings(marketId);

        // Verify fee collection
        uint256 expectedFee = 15000e6 * 2 / 100; // 2% of 15000 = 300
        assertEq(market.getAccumulatedFees(), expectedFee);
    }
}

