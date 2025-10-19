// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "./BaseTest.t.sol";
import {IPredictionMarket} from "../interfaces/IPredictionMarket.sol";
import {Errors} from "../Errors.sol";

/**
 * @title ResolutionTest
 * @notice Tests for market resolution and winnings claims
 */
contract ResolutionTest is BaseTest {

    // ============ Resolution Tests ============

    function test_ResolveMarket() public {
        uint256 startTime = block.timestamp + 100;
        uint256 endTime = startTime + 1 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        vm.warp(endTime + 1);
        market.resolveMarket(marketId, IPredictionMarket.MatchOutcome.HomeWin);

        IPredictionMarket.Market memory mkt = market.getMarket(marketId);
        assertEq(uint256(mkt.status), uint256(IPredictionMarket.MarketStatus.Resolved));
        assertEq(uint256(mkt.outcome), uint256(IPredictionMarket.MatchOutcome.HomeWin));
    }

    function test_ResolveMarketWithDraw() public {
        uint256 startTime = block.timestamp + 100;
        uint256 endTime = startTime + 1 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        vm.warp(endTime + 1);
        market.resolveMarket(marketId, IPredictionMarket.MatchOutcome.Draw);

        IPredictionMarket.Market memory mkt = market.getMarket(marketId);
        assertEq(uint256(mkt.outcome), uint256(IPredictionMarket.MatchOutcome.Draw));
    }

    function test_RevertResolveMarketBeforeEnd() public {
        uint256 startTime = block.timestamp + 100;
        uint256 endTime = startTime + 1 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        vm.expectRevert(Errors.MatchNotEnded.selector);
        market.resolveMarket(marketId, IPredictionMarket.MatchOutcome.HomeWin);
    }

    function test_RevertResolveMarketTwice() public {
        uint256 startTime = block.timestamp + 100;
        uint256 endTime = startTime + 1 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        vm.warp(endTime + 1);
        market.resolveMarket(marketId, IPredictionMarket.MatchOutcome.HomeWin);

        vm.expectRevert(Errors.MarketNotOpen.selector);
        market.resolveMarket(marketId, IPredictionMarket.MatchOutcome.AwayWin);
    }

    function test_RevertResolveMarketNonAdmin() public {
        uint256 startTime = block.timestamp + 100;
        uint256 endTime = startTime + 1 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        vm.warp(endTime + 1);
        vm.prank(user1);
        vm.expectRevert();
        market.resolveMarket(marketId, IPredictionMarket.MatchOutcome.HomeWin);
    }

    // ============ Claim Winnings Tests ============

    function test_ClaimWinnings() public {
        uint256 startTime = block.timestamp + 100;
        uint256 endTime = startTime + 1 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        uint256 betAmount1 = 100e6;
        uint256 betAmount2 = 100e6;

        // User1 bets on HomeWin
        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), betAmount1);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, betAmount1);
        vm.stopPrank();

        // User2 bets on AwayWin
        vm.startPrank(user2);
        usdc.approve(address(market.bettingEngine()), betAmount2);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.AwayWin, betAmount2);
        vm.stopPrank();

        vm.warp(endTime + 1);
        market.resolveMarket(marketId, IPredictionMarket.MatchOutcome.HomeWin);

        uint256 balanceBefore = usdc.balanceOf(user1);

        vm.prank(user1);
        market.claimWinnings(marketId);

        uint256 balanceAfter = usdc.balanceOf(user1);

        // User1 should receive prize pool (200 - 2% fee = 196)
        assertEq(balanceAfter, balanceBefore + 196e6);
    }

    function test_ClaimWinningsMultipleWinners() public {
        uint256 startTime = block.timestamp + 100;
        uint256 endTime = startTime + 1 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        // User1 bets 100 on HomeWin
        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), 100e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, 100e6);
        vm.stopPrank();

        // User2 bets 100 on HomeWin
        vm.startPrank(user2);
        usdc.approve(address(market.bettingEngine()), 100e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, 100e6);
        vm.stopPrank();

        vm.warp(endTime + 1);
        market.resolveMarket(marketId, IPredictionMarket.MatchOutcome.HomeWin);

        // Both users claim
        vm.prank(user1);
        market.claimWinnings(marketId);

        vm.prank(user2);
        market.claimWinnings(marketId);

        // Each should get 98 USDC (196 / 2)
        assertTrue(usdc.balanceOf(user1) >= 9998e6); // Close to 10000 - 100 + 98
        assertTrue(usdc.balanceOf(user2) >= 9998e6);
    }

    function test_ClaimRefundCancelled() public {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 2 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        uint256 betAmount = 100e6;

        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), betAmount);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, betAmount);
        vm.stopPrank();

        market.cancelMarket(marketId);

        uint256 balanceBefore = usdc.balanceOf(user1);

        vm.prank(user1);
        market.claimWinnings(marketId);

        uint256 balanceAfter = usdc.balanceOf(user1);

        // User1 should get full refund
        assertEq(balanceAfter, balanceBefore + betAmount);
    }

    function test_CalculatePotentialWinnings() public {
        uint256 startTime = block.timestamp + 100;
        uint256 endTime = startTime + 1 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), 100e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, 100e6);
        vm.stopPrank();

        vm.startPrank(user2);
        usdc.approve(address(market.bettingEngine()), 100e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.AwayWin, 100e6);
        vm.stopPrank();

        vm.warp(endTime + 1);
        market.resolveMarket(marketId, IPredictionMarket.MatchOutcome.HomeWin);

        uint256 potentialWinnings = market.calculatePotentialWinnings(marketId, user1);
        assertEq(potentialWinnings, 196e6); // 200 - 2% = 196
    }

    function test_RevertClaimWinningsLoser() public {
        uint256 startTime = block.timestamp + 100;
        uint256 endTime = startTime + 1 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), 100e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, 100e6);
        vm.stopPrank();

        vm.warp(endTime + 1);
        market.resolveMarket(marketId, IPredictionMarket.MatchOutcome.AwayWin);

        vm.prank(user1);
        vm.expectRevert(Errors.NoWinningsToClaim.selector);
        market.claimWinnings(marketId);
    }

    function test_RevertClaimWinningsTwice() public {
        uint256 startTime = block.timestamp + 100;
        uint256 endTime = startTime + 1 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), 100e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, 100e6);
        vm.stopPrank();

        vm.warp(endTime + 1);
        market.resolveMarket(marketId, IPredictionMarket.MatchOutcome.HomeWin);

        vm.startPrank(user1);
        market.claimWinnings(marketId);

        vm.expectRevert(Errors.AlreadyClaimed.selector);
        market.claimWinnings(marketId); // Should fail
        vm.stopPrank();
    }
}

