// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "./BaseTest.t.sol";
import {IPredictionMarket} from "../interfaces/IPredictionMarket.sol";
import {Errors} from "../Errors.sol";

/**
 * @title TeamTest
 * @notice Tests for team creation and management
 */
contract TeamTest is BaseTest {

    function test_CreateTeam() public {
        uint256 teamId = market.createTeam("Manchester United", "ipfs://team3");

        IPredictionMarket.Team memory team = market.getTeam(teamId);
        assertEq(team.id, teamId);
        assertEq(team.name, "Manchester United");
        assertEq(team.metadata, "ipfs://team3");
        assertTrue(team.exists);
    }

    function test_UpdateTeam() public {
        market.updateTeam(teamHomeId, "Real Madrid CF", "ipfs://updated");

        IPredictionMarket.Team memory team = market.getTeam(teamHomeId);
        assertEq(team.name, "Real Madrid CF");
        assertEq(team.metadata, "ipfs://updated");
    }

    function test_GetTotalTeams() public {
        assertEq(market.getTotalTeams(), 2); // setUp creates 2 teams

        market.createTeam("Manchester United", "ipfs://team3");
        assertEq(market.getTotalTeams(), 3);
    }

    function test_RevertCreateTeamNonAdmin() public {
        vm.prank(user1);
        vm.expectRevert();
        market.createTeam("Test Team", "ipfs://test");
    }

    function test_RevertUpdateNonExistentTeam() public {
        vm.expectRevert(Errors.TeamDoesNotExist.selector);
        market.updateTeam(999, "Fake Team", "ipfs://fake");
    }

    function test_RevertGetNonExistentTeam() public {
        vm.expectRevert(Errors.TeamDoesNotExist.selector);
        market.getTeam(999);
    }
}

