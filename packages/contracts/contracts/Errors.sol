// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title Errors
 * @notice Custom error definitions for the prediction market protocol
 * @dev Using custom errors instead of require strings for gas efficiency
 */
library Errors {
    // ============ Access Control Errors ============
    error OnlyBettingEngine();
    error OnlyMarketManager();
    error InvalidAdminAddress();

    // ============ Address Validation Errors ============
    error InvalidTeamManager();
    error InvalidUSDCAddress();
    error InvalidMarketManagerAddress();
    error InvalidAddress();

    // ============ Team Errors ============
    error TeamNameRequired();
    error TeamDoesNotExist();
    error HomeTeamDoesNotExist();
    error AwayTeamDoesNotExist();
    error TeamsMustBeDifferent();

    // ============ Market Errors ============
    error MarketDoesNotExist();
    error MarketNotOpen();
    error MarketNotFinalized();
    error MatchNotEnded();
    error StartTimeMustBeInFuture();
    error EndTimeMustBeAfterStartTime();
    error BettingPeriodEnded();
    error InvalidOutcome();

    // ============ Betting Errors ============
    error BetAmountTooLow();
    error BetAlreadyPlaced();
    error NoBetPlaced();
    error AlreadyClaimed();
    error NoWinningsToClaim();

    // ============ Fee & Transfer Errors ============
    error NoFeesToWithdraw();
    error TransferFailed();
    error FailedToUpdateMarketStakes();

    // ============ Setup Errors ============
    error BettingEngineAlreadySet();
    error BettingEngineNotSet();
}

