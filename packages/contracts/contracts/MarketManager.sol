// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IPredictionMarket} from "./interfaces/IPredictionMarket.sol";
import {OddsCalculator} from "./libraries/OddsCalculator.sol";
import {Errors} from "./Errors.sol";

/**
 * @title MarketManager
 * @notice Manages market lifecycle (creation, resolution, cancellation)
 * @dev Separate contract for market management to reduce main contract size
 */
contract MarketManager is AccessControl, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address public immutable teamManager;
    address public bettingEngine;

    uint256 private _marketIdCounter;
    uint256 private _accumulatedFees;

    mapping(uint256 => IPredictionMarket.Market) private _markets;

    event MarketCreated(
        uint256 indexed marketId,
        uint256 indexed homeTeamId,
        uint256 indexed awayTeamId,
        uint256 startTime,
        uint256 endTime
    );

    event MarketResolved(
        uint256 indexed marketId,
        IPredictionMarket.MatchOutcome outcome,
        uint256 performanceFee
    );

    event MarketCancelled(uint256 indexed marketId);
    event PerformanceFeeCollected(uint256 amount);

    modifier onlyBettingEngine() {
        if (msg.sender != bettingEngine) revert Errors.OnlyBettingEngine();
        _;
    }

    constructor(address _teamManager) {
        if (_teamManager == address(0)) revert Errors.InvalidTeamManager();

        teamManager = _teamManager;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Set betting engine address (one-time setup)
     * @param _bettingEngine BettingEngine contract address
     */
    function setBettingEngine(address _bettingEngine) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (bettingEngine != address(0)) revert Errors.BettingEngineAlreadySet();
        if (_bettingEngine == address(0)) revert Errors.InvalidAddress();
        bettingEngine = _bettingEngine;
    }

    /**
     * @notice Create a new prediction market
     * @param homeTeamId Home team ID
     * @param awayTeamId Away team ID
     * @param startTime Match start timestamp
     * @param endTime Match end timestamp
     * @return Market ID
     */
    function createMarket(
        uint256 homeTeamId,
        uint256 awayTeamId,
        uint256 startTime,
        uint256 endTime
    ) external onlyRole(ADMIN_ROLE) returns (uint256) {
        if (homeTeamId == awayTeamId) revert Errors.TeamsMustBeDifferent();
        if (startTime <= block.timestamp) revert Errors.StartTimeMustBeInFuture();
        if (endTime <= startTime) revert Errors.EndTimeMustBeAfterStartTime();

        // Verify teams exist (call to TeamManager)
        (bool success, bytes memory data) = teamManager.call(
            abi.encodeWithSignature("teamExists(uint256)", homeTeamId)
        );
        if (!success || !abi.decode(data, (bool))) revert Errors.HomeTeamDoesNotExist();

        (success, data) = teamManager.call(
            abi.encodeWithSignature("teamExists(uint256)", awayTeamId)
        );
        if (!success || !abi.decode(data, (bool))) revert Errors.AwayTeamDoesNotExist();

        _marketIdCounter++;
        uint256 marketId = _marketIdCounter;

        _markets[marketId] = IPredictionMarket.Market({
            id: marketId,
            homeTeamId: homeTeamId,
            awayTeamId: awayTeamId,
            startTime: startTime,
            endTime: endTime,
            status: IPredictionMarket.MarketStatus.Open,
            outcome: IPredictionMarket.MatchOutcome.Pending,
            totalHomeStake: 0,
            totalAwayStake: 0,
            totalDrawStake: 0,
            totalStake: 0
        });

        emit MarketCreated(marketId, homeTeamId, awayTeamId, startTime, endTime);
        return marketId;
    }

    /**
     * @notice Update market stakes after a bet is placed
     * @param marketId Market ID
     * @param homeIncrease Home stake increase
     * @param awayIncrease Away stake increase
     * @param drawIncrease Draw stake increase
     */
    function updateMarketStakes(
        uint256 marketId,
        uint256 homeIncrease,
        uint256 awayIncrease,
        uint256 drawIncrease
    ) external onlyBettingEngine {
        IPredictionMarket.Market storage market = _markets[marketId];

        market.totalHomeStake += homeIncrease;
        market.totalAwayStake += awayIncrease;
        market.totalDrawStake += drawIncrease;
        market.totalStake += (homeIncrease + awayIncrease + drawIncrease);
    }

    /**
     * @notice Resolve a market with final outcome
     * @param marketId Market ID to resolve
     * @param outcome Final match outcome
     */
    function resolveMarket(
        uint256 marketId,
        IPredictionMarket.MatchOutcome outcome
    ) external onlyRole(ADMIN_ROLE) {
        IPredictionMarket.Market storage market = _markets[marketId];
        if (market.id == 0) revert Errors.MarketDoesNotExist();
        if (market.status != IPredictionMarket.MarketStatus.Open) revert Errors.MarketNotOpen();
        if (block.timestamp < market.endTime) revert Errors.MatchNotEnded();
        if (
            outcome != IPredictionMarket.MatchOutcome.HomeWin &&
            outcome != IPredictionMarket.MatchOutcome.AwayWin &&
            outcome != IPredictionMarket.MatchOutcome.Draw
        ) revert Errors.InvalidOutcome();

        market.status = IPredictionMarket.MarketStatus.Resolved;
        market.outcome = outcome;

        // Calculate and accumulate performance fee
        uint256 performanceFee = OddsCalculator.calculatePerformanceFee(market.totalStake);
        _accumulatedFees += performanceFee;

        emit MarketResolved(marketId, outcome, performanceFee);
        emit PerformanceFeeCollected(performanceFee);
    }

    /**
     * @notice Cancel a market and allow refunds
     * @param marketId Market ID to cancel
     */
    function cancelMarket(uint256 marketId) external onlyRole(ADMIN_ROLE) {
        IPredictionMarket.Market storage market = _markets[marketId];
        if (market.id == 0) revert Errors.MarketDoesNotExist();
        if (market.status != IPredictionMarket.MarketStatus.Open) revert Errors.MarketNotOpen();

        market.status = IPredictionMarket.MarketStatus.Cancelled;
        emit MarketCancelled(marketId);
    }

    /**
     * @notice Get market information
     * @param marketId Market ID
     * @return Market struct
     */
    function getMarket(uint256 marketId) external view returns (IPredictionMarket.Market memory) {
        if (_markets[marketId].id == 0) revert Errors.MarketDoesNotExist();
        return _markets[marketId];
    }

    /**
     * @notice Get current odds for a market
     * @param marketId Market ID
     * @return Odds struct
     */
    function getOdds(uint256 marketId) external view returns (IPredictionMarket.Odds memory) {
        IPredictionMarket.Market memory market = _markets[marketId];
        if (market.id == 0) revert Errors.MarketDoesNotExist();

        return OddsCalculator.calculateOdds(
            market.totalStake,
            market.totalHomeStake,
            market.totalAwayStake,
            market.totalDrawStake
        );
    }

    /**
     * @notice Get total number of markets
     * @return Total market count
     */
    function getTotalMarkets() external view returns (uint256) {
        return _marketIdCounter;
    }

    /**
     * @notice Get accumulated fees
     * @return Total accumulated fees
     */
    function getAccumulatedFees() external view returns (uint256) {
        return _accumulatedFees;
    }

    /**
     * @notice Withdraw accumulated fees (only owner)
     * @param recipient Recipient address
     */
    function withdrawFees(address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (bettingEngine == address(0)) revert Errors.BettingEngineNotSet();
        uint256 amount = _accumulatedFees;
        if (amount == 0) revert Errors.NoFeesToWithdraw();

        _accumulatedFees = 0;

        // Call betting engine to transfer USDC
        (bool success, ) = bettingEngine.call(
            abi.encodeWithSignature("transferUSDC(address,uint256)", recipient, amount)
        );
        if (!success) revert Errors.TransferFailed();
    }

    /**
     * @notice Add a new admin
     * @param admin Address to grant admin role
     */
    function addAdmin(address admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (admin == address(0)) revert Errors.InvalidAdminAddress();
        grantRole(ADMIN_ROLE, admin);
    }

    /**
     * @notice Remove an admin
     * @param admin Address to revoke admin role
     */
    function removeAdmin(address admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(ADMIN_ROLE, admin);
    }

    /**
     * @notice Pause the contract (only owner)
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause the contract (only owner)
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}

