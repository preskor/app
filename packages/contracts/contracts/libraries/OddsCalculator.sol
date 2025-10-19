// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IPredictionMarket} from "../interfaces/IPredictionMarket.sol";

/**
 * @title OddsCalculator
 * @notice Library for calculating odds and winnings
 * @dev Pure functions for odds calculation logic
 */
library OddsCalculator {
    uint256 public constant ODDS_PRECISION = 10000;
    uint256 public constant PERFORMANCE_FEE_PERCENTAGE = 2;

    /**
     * @notice Calculate current odds for a market
     * @param totalStake Total amount staked in the market
     * @param homeStake Amount staked on home win
     * @param awayStake Amount staked on away win
     * @param drawStake Amount staked on draw
     * @return odds Odds struct with calculated odds
     */
    function calculateOdds(
        uint256 totalStake,
        uint256 homeStake,
        uint256 awayStake,
        uint256 drawStake
    ) internal pure returns (IPredictionMarket.Odds memory odds) {
        if (totalStake == 0) {
            // No bets yet, return even odds
            return IPredictionMarket.Odds({
                homeOdds: ODDS_PRECISION,
                awayOdds: ODDS_PRECISION,
                drawOdds: ODDS_PRECISION
            });
        }

        // Calculate prize pool after performance fee
        uint256 feeAmount = (totalStake * PERFORMANCE_FEE_PERCENTAGE) / 100;
        uint256 prizePool = totalStake - feeAmount;

        // Calculate odds: (prizePool / stake) * ODDS_PRECISION
        odds.homeOdds = homeStake > 0
            ? (prizePool * ODDS_PRECISION) / homeStake
            : type(uint256).max;

        odds.awayOdds = awayStake > 0
            ? (prizePool * ODDS_PRECISION) / awayStake
            : type(uint256).max;

        odds.drawOdds = drawStake > 0
            ? (prizePool * ODDS_PRECISION) / drawStake
            : type(uint256).max;

        return odds;
    }

    /**
     * @notice Calculate winnings for a winning bet
     * @param totalStake Total amount staked in the market
     * @param winningStake Total amount staked on winning outcome
     * @param betAmount User's bet amount
     * @return Payout amount
     */
    function calculateWinnings(
        uint256 totalStake,
        uint256 winningStake,
        uint256 betAmount
    ) internal pure returns (uint256) {
        if (winningStake == 0) return 0;

        // Prize pool after performance fee
        uint256 performanceFee = (totalStake * PERFORMANCE_FEE_PERCENTAGE) / 100;
        uint256 prizePool = totalStake - performanceFee;

        // User's share of prize pool based on their stake
        return (betAmount * prizePool) / winningStake;
    }

    /**
     * @notice Calculate performance fee for a market
     * @param totalStake Total amount staked in the market
     * @return Performance fee amount
     */
    function calculatePerformanceFee(uint256 totalStake) internal pure returns (uint256) {
        return (totalStake * PERFORMANCE_FEE_PERCENTAGE) / 100;
    }
}

