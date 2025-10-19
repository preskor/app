// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "./BaseTest.t.sol";
import {IPredictionMarket} from "../interfaces/IPredictionMarket.sol";
import {Errors} from "../Errors.sol";

/**
 * @title BettingTest
 * @notice Tests for bet placement and validation
 */
contract BettingTest is BaseTest {

    function test_PlaceBet() public {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 2 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        uint256 betAmount = 100e6; // 100 USDC

        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), betAmount);

        vm.expectEmit(true, true, false, true);
        emit BetPlaced(marketId, user1, IPredictionMarket.MatchOutcome.HomeWin, betAmount);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, betAmount);
        vm.stopPrank();

        (IPredictionMarket.MatchOutcome outcome, uint256 amount) = market.getUserBet(marketId, user1);
        assertEq(uint256(outcome), uint256(IPredictionMarket.MatchOutcome.HomeWin));
        assertEq(amount, betAmount);
    }

    function test_PlaceBetOnAwayWin() public {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 2 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        uint256 betAmount = 50e6;

        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), betAmount);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.AwayWin, betAmount);
        vm.stopPrank();

        IPredictionMarket.Market memory mkt = market.getMarket(marketId);
        assertEq(mkt.totalAwayStake, betAmount);
    }

    function test_PlaceBetOnDraw() public {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 2 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        uint256 betAmount = 75e6;

        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), betAmount);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.Draw, betAmount);
        vm.stopPrank();

        IPredictionMarket.Market memory mkt = market.getMarket(marketId);
        assertEq(mkt.totalDrawStake, betAmount);
    }

    function test_RevertPlaceBetTooLow() public {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 2 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        uint256 betAmount = 0.5e6; // 0.5 USDC (below 1 USDC minimum)

        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), betAmount);
        vm.expectRevert(Errors.BetAmountTooLow.selector);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, betAmount);
        vm.stopPrank();
    }

    function test_RevertPlaceBetAfterCutoff() public {
        uint256 startTime = block.timestamp + 100;
        uint256 endTime = startTime + 1 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        // Warp to 5 minutes before end (cutoff is 10 minutes)
        vm.warp(endTime - 5 minutes);

        uint256 betAmount = 100e6;

        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), betAmount);
        vm.expectRevert(Errors.BettingPeriodEnded.selector);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, betAmount);
        vm.stopPrank();
    }

    function test_PlaceBetBeforeCutoff() public {
        uint256 startTime = block.timestamp + 100;
        uint256 endTime = startTime + 1 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        // Warp to 15 minutes before end (still before 10-minute cutoff)
        vm.warp(endTime - 15 minutes);

        uint256 betAmount = 100e6;

        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), betAmount);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, betAmount);
        vm.stopPrank();

        (,uint256 amount) = market.getUserBet(marketId, user1);
        assertEq(amount, betAmount);
    }

    function test_RevertPlaceBetTwice() public {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 2 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        uint256 betAmount = 100e6;

        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), betAmount * 2);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, betAmount);

        vm.expectRevert(Errors.BetAlreadyPlaced.selector);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.AwayWin, betAmount);
        vm.stopPrank();
    }

    function test_RevertPlaceBetWithoutApproval() public {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 2 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        uint256 betAmount = 100e6;

        vm.startPrank(user1);
        // Don't approve USDC transfer
        vm.expectRevert();
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, betAmount);
        vm.stopPrank();
    }

    function test_MultipleBettors() public {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 2 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        // User1 bets on HomeWin
        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), 100e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, 100e6);
        vm.stopPrank();

        // User2 bets on AwayWin
        vm.startPrank(user2);
        usdc.approve(address(market.bettingEngine()), 150e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.AwayWin, 150e6);
        vm.stopPrank();

        IPredictionMarket.Market memory mkt = market.getMarket(marketId);
        assertEq(mkt.totalHomeStake, 100e6);
        assertEq(mkt.totalAwayStake, 150e6);
        assertEq(mkt.totalStake, 250e6);
    }

    function test_GetOdds() public {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 2 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        // User1 bets 100 on HomeWin
        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), 100e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.HomeWin, 100e6);
        vm.stopPrank();

        // User2 bets 200 on AwayWin
        vm.startPrank(user2);
        usdc.approve(address(market.bettingEngine()), 200e6);
        market.placeBet(marketId, IPredictionMarket.MatchOutcome.AwayWin, 200e6);
        vm.stopPrank();

        IPredictionMarket.Odds memory odds = market.getOdds(marketId);

        // Prize pool = 300 - 2% = 294
        // HomeWin odds = 294 / 100 = 2.94
        // AwayWin odds = 294 / 200 = 1.47
        assertTrue(odds.homeOdds > 0);
        assertTrue(odds.awayOdds > 0);
        assertTrue(odds.homeOdds > odds.awayOdds); // More money on away, so home has better odds
    }
}

