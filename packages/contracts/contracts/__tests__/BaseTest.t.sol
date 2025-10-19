// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {PredictionMarket} from "../PredictionMarket.sol";
import {TeamManager} from "../TeamManager.sol";
import {MarketManager} from "../MarketManager.sol";
import {BettingEngine} from "../BettingEngine.sol";
import {IPredictionMarket} from "../interfaces/IPredictionMarket.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Errors} from "../Errors.sol";

/**
 * @title MockUSDC
 * @notice Mock USDC token for testing
 */
contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

/**
 * @title BaseTest
 * @notice Base test contract with common setup and utilities
 * @dev All test contracts should inherit from this
 */
contract BaseTest is Test {
    PredictionMarket public market;
    MockUSDC public usdc;

    address public owner;
    address public admin;
    address public user1;
    address public user2;

    uint256 public teamHomeId;
    uint256 public teamAwayId;

    // Common time variables
    uint256 public startTime;

    // Events
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
        IPredictionMarket.MatchOutcome outcome,
        uint256 amount
    );

    function setUp() public virtual {
        owner = address(this);
        admin = address(0xAD);
        user1 = address(0x1);
        user2 = address(0x2);

        // Deploy mock USDC
        usdc = new MockUSDC();

        // Deploy prediction market (which deploys all sub-contracts)
        market = new PredictionMarket(address(usdc));

        // Mint USDC to users
        usdc.mint(user1, 10000e6); // 10,000 USDC
        usdc.mint(user2, 10000e6);

        // Create teams
        teamHomeId = market.createTeam("Real Madrid", "ipfs://team1");
        teamAwayId = market.createTeam("Barcelona", "ipfs://team2");

        // Set common start time
        startTime = block.timestamp + 100;
    }

    /**
     * @notice Helper to create a basic market
     */
    function _createBasicMarket() internal returns (uint256) {
        uint256 endTime = startTime + 1 hours;
        return market.createMarket(teamHomeId, teamAwayId, startTime, endTime);
    }

    /**
     * @notice Helper to create a market with custom times
     */
    function _createMarket(uint256 _startTime, uint256 _endTime) internal returns (uint256) {
        return market.createMarket(teamHomeId, teamAwayId, _startTime, _endTime);
    }

    /**
     * @notice Helper to place a bet as user1
     */
    function _placeBetAsUser1(
        uint256 marketId,
        IPredictionMarket.MatchOutcome outcome,
        uint256 amount
    ) internal {
        vm.startPrank(user1);
        usdc.approve(address(market.bettingEngine()), amount);
        market.placeBet(marketId, outcome, amount);
        vm.stopPrank();
    }

    /**
     * @notice Helper to place a bet as user2
     */
    function _placeBetAsUser2(
        uint256 marketId,
        IPredictionMarket.MatchOutcome outcome,
        uint256 amount
    ) internal {
        vm.startPrank(user2);
        usdc.approve(address(market.bettingEngine()), amount);
        market.placeBet(marketId, outcome, amount);
        vm.stopPrank();
    }
}

