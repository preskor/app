// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPredictionMarket} from "./interfaces/IPredictionMarket.sol";
import {OddsCalculator} from "./libraries/OddsCalculator.sol";
import {Errors} from "./Errors.sol";

/**
 * @title BettingEngine
 * @notice Handles bet placement and winnings claims
 * @dev Separate contract for betting logic to reduce main contract size
 */
contract BettingEngine is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable usdc;
    address public immutable marketManager;

    uint256 public constant MIN_BET_AMOUNT = 1e6; // 1 USDC (6 decimals)
    uint256 public constant BETTING_CUTOFF_TIME = 10 minutes;

    struct Bet {
        IPredictionMarket.MatchOutcome outcome;
        uint256 amount;
    }

    // marketId => user => Bet
    mapping(uint256 => mapping(address => Bet)) private _bets;
    // marketId => user => claimed
    mapping(uint256 => mapping(address => bool)) private _claimed;

    event BetPlaced(
        uint256 indexed marketId,
        address indexed user,
        IPredictionMarket.MatchOutcome outcome,
        uint256 amount
    );

    event WinningsClaimed(
        uint256 indexed marketId,
        address indexed user,
        uint256 amount
    );

    modifier onlyMarketManager() {
        if (msg.sender != marketManager) revert Errors.OnlyMarketManager();
        _;
    }

    constructor(address usdcAddress, address _marketManager) {
        if (usdcAddress == address(0)) revert Errors.InvalidUSDCAddress();
        if (_marketManager == address(0)) revert Errors.InvalidMarketManagerAddress();

        usdc = IERC20(usdcAddress);
        marketManager = _marketManager;
    }

    /**
     * @notice Place a bet on a market outcome
     * @param marketId Market ID
     * @param user User placing the bet
     * @param outcome Predicted outcome
     * @param amount USDC amount to bet
     * @param market Market struct from MarketManager
     */
    function placeBet(
        uint256 marketId,
        address user,
        IPredictionMarket.MatchOutcome outcome,
        uint256 amount,
        IPredictionMarket.Market memory market
    ) external nonReentrant {
        if (market.id == 0) revert Errors.MarketDoesNotExist();
        if (market.status != IPredictionMarket.MarketStatus.Open) revert Errors.MarketNotOpen();
        if (block.timestamp >= market.endTime - BETTING_CUTOFF_TIME) revert Errors.BettingPeriodEnded();
        if (amount < MIN_BET_AMOUNT) revert Errors.BetAmountTooLow();
        if (
            outcome != IPredictionMarket.MatchOutcome.HomeWin &&
            outcome != IPredictionMarket.MatchOutcome.AwayWin &&
            outcome != IPredictionMarket.MatchOutcome.Draw
        ) revert Errors.InvalidOutcome();
        if (_bets[marketId][user].amount != 0) revert Errors.BetAlreadyPlaced();

        // Transfer USDC from user
        usdc.safeTransferFrom(user, address(this), amount);

        // Record bet
        _bets[marketId][user] = Bet({
            outcome: outcome,
            amount: amount
        });

        // Update market stakes directly
        uint256 homeIncrease = 0;
        uint256 awayIncrease = 0;
        uint256 drawIncrease = 0;

        if (outcome == IPredictionMarket.MatchOutcome.HomeWin) {
            homeIncrease = amount;
        } else if (outcome == IPredictionMarket.MatchOutcome.AwayWin) {
            awayIncrease = amount;
        } else {
            drawIncrease = amount;
        }

        // Call market manager to update stakes
        (bool success, ) = marketManager.call(
            abi.encodeWithSignature(
                "updateMarketStakes(uint256,uint256,uint256,uint256)",
                marketId,
                homeIncrease,
                awayIncrease,
                drawIncrease
            )
        );
        if (!success) revert Errors.FailedToUpdateMarketStakes();

        emit BetPlaced(marketId, user, outcome, amount);
    }

    /**
     * @notice Claim winnings from a resolved market
     * @param marketId Market ID
     * @param user User claiming winnings
     * @param market Market struct from MarketManager
     */
    function claimWinnings(
        uint256 marketId,
        address user,
        IPredictionMarket.Market memory market
    ) external nonReentrant {
        if (market.id == 0) revert Errors.MarketDoesNotExist();

        Bet memory userBet = _bets[marketId][user];
        if (userBet.amount == 0) revert Errors.NoBetPlaced();
        if (_claimed[marketId][user]) revert Errors.AlreadyClaimed();

        uint256 payout = 0;

        if (market.status == IPredictionMarket.MarketStatus.Cancelled) {
            // Refund original bet
            payout = userBet.amount;
        } else if (market.status == IPredictionMarket.MarketStatus.Resolved) {
            // Pay winners
            if (userBet.outcome == market.outcome) {
                uint256 winningStake = _getWinningStake(market);
                payout = OddsCalculator.calculateWinnings(
                    market.totalStake,
                    winningStake,
                    userBet.amount
                );
            }
        } else {
            revert Errors.MarketNotFinalized();
        }

        if (payout == 0) revert Errors.NoWinningsToClaim();

        _claimed[marketId][user] = true;
        usdc.safeTransfer(user, payout);

        emit WinningsClaimed(marketId, user, payout);
    }

    /**
     * @notice Get user's bet information
     * @param marketId Market ID
     * @param user User address
     * @return outcome User's predicted outcome
     * @return amount User's bet amount
     */
    function getUserBet(
        uint256 marketId,
        address user
    ) external view returns (IPredictionMarket.MatchOutcome outcome, uint256 amount) {
        Bet memory bet = _bets[marketId][user];
        return (bet.outcome, bet.amount);
    }

    /**
     * @notice Check if user has claimed winnings
     * @param marketId Market ID
     * @param user User address
     * @return True if claimed
     */
    function hasClaimed(uint256 marketId, address user) external view returns (bool) {
        return _claimed[marketId][user];
    }

    /**
     * @notice Calculate potential winnings for a user
     * @param marketId Market ID
     * @param user User address
     * @param market Market struct
     * @return Potential payout amount
     */
    function calculatePotentialWinnings(
        uint256 marketId,
        address user,
        IPredictionMarket.Market memory market
    ) external view returns (uint256) {
        Bet memory userBet = _bets[marketId][user];

        if (userBet.amount == 0) return 0;
        if (market.status == IPredictionMarket.MarketStatus.Cancelled) return userBet.amount;
        if (market.status != IPredictionMarket.MarketStatus.Resolved) return 0;
        if (userBet.outcome != market.outcome) return 0;

        uint256 winningStake = _getWinningStake(market);
        return OddsCalculator.calculateWinnings(market.totalStake, winningStake, userBet.amount);
    }

    /**
     * @dev Get winning stake based on outcome
     */
    function _getWinningStake(IPredictionMarket.Market memory market) private pure returns (uint256) {
        if (market.outcome == IPredictionMarket.MatchOutcome.HomeWin) {
            return market.totalHomeStake;
        } else if (market.outcome == IPredictionMarket.MatchOutcome.AwayWin) {
            return market.totalAwayStake;
        } else {
            return market.totalDrawStake;
        }
    }

    /**
     * @notice Transfer USDC to market manager (for fee collection)
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function transferUSDC(address to, uint256 amount) external onlyMarketManager {
        usdc.safeTransfer(to, amount);
    }
}

