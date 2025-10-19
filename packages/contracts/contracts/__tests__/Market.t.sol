// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "./BaseTest.t.sol";
import {IPredictionMarket} from "../interfaces/IPredictionMarket.sol";
import {Errors} from "../Errors.sol";

/**
 * @title MarketTest
 * @notice Tests for market creation and lifecycle management
 */
contract MarketTest is BaseTest {

    function test_CreateMarket() public {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 2 hours;

        vm.expectEmit(true, true, true, true);
        emit MarketCreated(1, teamHomeId, teamAwayId, startTime, endTime);

        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        IPredictionMarket.Market memory mkt = market.getMarket(marketId);
        assertEq(mkt.id, marketId);
        assertEq(mkt.homeTeamId, teamHomeId);
        assertEq(mkt.awayTeamId, teamAwayId);
        assertEq(mkt.startTime, startTime);
        assertEq(mkt.endTime, endTime);
        assertEq(uint256(mkt.status), uint256(IPredictionMarket.MarketStatus.Open));
        assertEq(uint256(mkt.outcome), uint256(IPredictionMarket.MatchOutcome.Pending));
    }

    function test_GetMarketInfo() public {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 2 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        IPredictionMarket.Market memory mkt = market.getMarket(marketId);

        assertEq(mkt.id, marketId);
        assertEq(mkt.homeTeamId, teamHomeId);
        assertEq(mkt.awayTeamId, teamAwayId);
        assertEq(uint256(mkt.status), uint256(IPredictionMarket.MarketStatus.Open));
    }

    function test_GetTotalMarkets() public {
        assertEq(market.getTotalMarkets(), 0);

        uint256 marketId1 = market.createMarket(
            teamHomeId,
            teamAwayId,
            block.timestamp + 1 hours,
            block.timestamp + 3 hours
        );

        uint256 marketId2 = market.createMarket(
            teamHomeId,
            teamAwayId,
            block.timestamp + 4 hours,
            block.timestamp + 6 hours
        );

        assertEq(marketId1, 1);
        assertEq(marketId2, 2);
        assertEq(market.getTotalMarkets(), 2);
    }

    function test_RevertCreateMarketSameTeams() public {
        vm.expectRevert(Errors.TeamsMustBeDifferent.selector);
        market.createMarket(
            teamHomeId,
            teamHomeId,
            block.timestamp + 1 hours,
            block.timestamp + 3 hours
        );
    }

    function test_RevertCreateMarketPastStartTime() public {
        vm.expectRevert(Errors.StartTimeMustBeInFuture.selector);
        market.createMarket(
            teamHomeId,
            teamAwayId,
            block.timestamp, // Current time is not in the future
            block.timestamp + 1 hours
        );
    }

    function test_RevertCreateMarketEndBeforeStart() public {
        vm.expectRevert(Errors.EndTimeMustBeAfterStartTime.selector);
        market.createMarket(
            teamHomeId,
            teamAwayId,
            block.timestamp + 3 hours,
            block.timestamp + 1 hours
        );
    }

    function test_CreateMarketNonExistentTeam() public {
        vm.expectRevert(Errors.HomeTeamDoesNotExist.selector);

        market.createMarket(
            999,
            teamAwayId,
            block.timestamp + 1 hours,
            block.timestamp + 3 hours
        );
    }

    function test_CancelMarket() public {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 2 hours;
        uint256 marketId = market.createMarket(teamHomeId, teamAwayId, startTime, endTime);

        market.cancelMarket(marketId);

        IPredictionMarket.Market memory mkt = market.getMarket(marketId);
        assertEq(uint256(mkt.status), uint256(IPredictionMarket.MarketStatus.Cancelled));
    }
}

