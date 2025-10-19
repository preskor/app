// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IPredictionMarket} from "./interfaces/IPredictionMarket.sol";
import {TeamManager} from "./TeamManager.sol";
import {MarketManager} from "./MarketManager.sol";
import {BettingEngine} from "./BettingEngine.sol";

/**
 * @title PredictionMarket
 * @notice Main orchestration contract for USDC-based prediction markets
 * @dev Lightweight coordinator that delegates to specialized contracts
 */
contract PredictionMarket is IPredictionMarket, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    TeamManager public immutable teamManager;
    MarketManager public immutable marketManager;
    BettingEngine public immutable bettingEngine;

    constructor(address usdcAddress) {
        // Deploy sub-contracts
        teamManager = new TeamManager();
        marketManager = new MarketManager(address(teamManager));
        bettingEngine = new BettingEngine(usdcAddress, address(marketManager));

        // Link betting engine to market manager
        marketManager.setBettingEngine(address(bettingEngine));

        // Setup roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    // ============ Team Management (Delegated) ============

    function createTeam(
        string calldata name,
        string calldata metadata
    ) external override onlyRole(ADMIN_ROLE) returns (uint256) {
        return teamManager.createTeam(name, metadata);
    }

    function updateTeam(
        uint256 teamId,
        string calldata name,
        string calldata metadata
    ) external override onlyRole(ADMIN_ROLE) {
        teamManager.updateTeam(teamId, name, metadata);
    }

    function getTeam(uint256 teamId) external view override returns (Team memory) {
        return teamManager.getTeam(teamId);
    }

    // ============ Market Management (Delegated) ============

    function createMarket(
        uint256 homeTeamId,
        uint256 awayTeamId,
        uint256 startTime,
        uint256 endTime
    ) external override onlyRole(ADMIN_ROLE) returns (uint256) {
        return marketManager.createMarket(homeTeamId, awayTeamId, startTime, endTime);
    }

    function resolveMarket(
        uint256 marketId,
        MatchOutcome outcome
    ) external override onlyRole(ADMIN_ROLE) {
        marketManager.resolveMarket(marketId, outcome);
    }

    function cancelMarket(uint256 marketId) external override onlyRole(ADMIN_ROLE) {
        marketManager.cancelMarket(marketId);
    }

    function getMarket(uint256 marketId) external view override returns (Market memory) {
        return marketManager.getMarket(marketId);
    }

    function getOdds(uint256 marketId) external view override returns (Odds memory) {
        return marketManager.getOdds(marketId);
    }

    function getTotalMarkets() external view override returns (uint256) {
        return marketManager.getTotalMarkets();
    }

    // ============ Betting (Delegated with coordination) ============

    function placeBet(
        uint256 marketId,
        MatchOutcome outcome,
        uint256 amount
    ) external override {
        // Get market info
        Market memory market = marketManager.getMarket(marketId);

        // Place bet through betting engine (it will update market stakes)
        bettingEngine.placeBet(marketId, msg.sender, outcome, amount, market);
    }

    function claimWinnings(uint256 marketId) external override {
        Market memory market = marketManager.getMarket(marketId);
        bettingEngine.claimWinnings(marketId, msg.sender, market);
    }

    function getUserBet(
        uint256 marketId,
        address user
    ) external view override returns (MatchOutcome outcome, uint256 amount) {
        return bettingEngine.getUserBet(marketId, user);
    }

    function calculatePotentialWinnings(
        uint256 marketId,
        address user
    ) external view override returns (uint256) {
        Market memory market = marketManager.getMarket(marketId);
        return bettingEngine.calculatePotentialWinnings(marketId, user, market);
    }

    // ============ Admin & Fee Management (Delegated) ============

    function addAdmin(address admin) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ADMIN_ROLE, admin);
        teamManager.addAdmin(admin);
        marketManager.addAdmin(admin);
    }

    function removeAdmin(address admin) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(ADMIN_ROLE, admin);
        teamManager.removeAdmin(admin);
        marketManager.removeAdmin(admin);
    }

    function isAdmin(address account) external view override returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }

    function withdrawFees() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        marketManager.withdrawFees(msg.sender);
    }

    function getAccumulatedFees() external view override returns (uint256) {
        return marketManager.getAccumulatedFees();
    }

    function getTotalTeams() external view override returns (uint256) {
        return teamManager.getTotalTeams();
    }
}
