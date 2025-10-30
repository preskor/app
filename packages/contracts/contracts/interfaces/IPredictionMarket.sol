// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IPredictionMarket
 * @notice Interface for the Prediction Market contract with USDC betting
 * @dev Supports team entities, role-based access, and odds calculation
 */
interface IPredictionMarket {
    enum MatchOutcome {
        Pending,
        HomeWin,
        AwayWin,
        Draw
    }

    enum MarketStatus {
        Open,
        Locked,
        Resolved,
        Cancelled
    }

    struct Team {
        uint256 id;
        string name;
        string metadata; // IPFS hash or external data reference
        bool exists;
    }

    struct Market {
        uint256 id;
        uint256 homeTeamId;
        uint256 awayTeamId;
        uint256 startTime;
        uint256 endTime;
        MarketStatus status;
        MatchOutcome outcome;
        uint256 totalHomeStake;
        uint256 totalAwayStake;
        uint256 totalDrawStake;
        uint256 totalStake;
    }

    struct Odds {
        uint256 homeOdds; // Scaled by 10000 (e.g., 15000 = 1.5x)
        uint256 awayOdds;
        uint256 drawOdds;
    }

    // Team Events
    event TeamCreated(uint256 indexed teamId, string name, string metadata);
    event TeamUpdated(uint256 indexed teamId, string name, string metadata);

    // Market Events
    event MarketCreated(
        uint256 indexed marketId,
        uint256 indexed homeTeamId,
        uint256 indexed awayTeamId,
        uint256 startTime,
        uint256 endTime
    );

    event BetPlaced(
        uint256 indexed marketId,
        address indexed user,
        MatchOutcome outcome,
        uint256 amount
    );

    event MarketResolved(
        uint256 indexed marketId,
        MatchOutcome outcome,
        uint256 performanceFee
    );

    event MarketCancelled(uint256 indexed marketId);

    event WinningsClaimed(
        uint256 indexed marketId,
        address indexed user,
        uint256 amount
    );

    event PerformanceFeeCollected(uint256 amount);

    // Admin Events
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);

    // Team Management
    function createTeam(string calldata name, string calldata metadata) external returns (uint256);
    function createBulkTeams(
        string[] calldata names,
        string[] calldata metadataList
    ) external returns (uint256[] memory);
    function updateTeam(uint256 teamId, string calldata name, string calldata metadata) external;
    function getTeam(uint256 teamId) external view returns (Team memory);

    // Market Management
    function createMarket(
        uint256 homeTeamId,
        uint256 awayTeamId,
        uint256 startTime,
        uint256 endTime
    ) external returns (uint256);

    function resolveMarket(uint256 marketId, MatchOutcome outcome) external;
    function cancelMarket(uint256 marketId) external;

    // Betting
    function placeBet(
        uint256 marketId,
        MatchOutcome outcome,
        uint256 amount
    ) external;

    function claimWinnings(uint256 marketId) external;

    // Odds & Calculations
    function getOdds(uint256 marketId) external view returns (Odds memory);
    function calculatePotentialWinnings(
        uint256 marketId,
        address user
    ) external view returns (uint256);

    // View Functions
    function getMarket(uint256 marketId) external view returns (Market memory);
    function getUserBet(
        uint256 marketId,
        address user
    ) external view returns (MatchOutcome outcome, uint256 amount);
    function getTotalMarkets() external view returns (uint256);
    function getTotalTeams() external view returns (uint256);

    // Admin Management
    function addAdmin(address admin) external;
    function removeAdmin(address admin) external;
    function isAdmin(address account) external view returns (bool);

    // Fee Management
    function withdrawFees() external;
    function getAccumulatedFees() external view returns (uint256);
}
