// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "./BaseTest.t.sol";
import {IPredictionMarket} from "../interfaces/IPredictionMarket.sol";
import {Errors} from "../Errors.sol";
import {TeamManager} from "../TeamManager.sol";

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

    function test_CreateBulkTeams() public {
        string[] memory names = new string[](3);
        names[0] = "Arsenal FC";
        names[1] = "Chelsea FC";
        names[2] = "Tottenham Hotspur";

        string[] memory metadata = new string[](3);
        metadata[0] = "ipfs://arsenal";
        metadata[1] = "ipfs://chelsea";
        metadata[2] = "ipfs://tottenham";

        uint256[] memory teamIds = market.createBulkTeams(names, metadata);

        assertEq(teamIds.length, 3);
        assertEq(teamIds[0], 3); // First new team after the 2 setup teams
        assertEq(teamIds[1], 4);
        assertEq(teamIds[2], 5);

        // Verify teams were created correctly
        IPredictionMarket.Team memory team1 = market.getTeam(teamIds[0]);
        assertEq(team1.name, "Arsenal FC");
        assertEq(team1.metadata, "ipfs://arsenal");
        assertTrue(team1.exists);

        IPredictionMarket.Team memory team2 = market.getTeam(teamIds[1]);
        assertEq(team2.name, "Chelsea FC");
        assertEq(team2.metadata, "ipfs://chelsea");
        assertTrue(team2.exists);

        IPredictionMarket.Team memory team3 = market.getTeam(teamIds[2]);
        assertEq(team3.name, "Tottenham Hotspur");
        assertEq(team3.metadata, "ipfs://tottenham");
        assertTrue(team3.exists);

        assertEq(market.getTotalTeams(), 5); // Original 2 + 3 new
    }

    function test_RevertBulkCreateTeamsArrayLengthMismatch() public {
        string[] memory names = new string[](2);
        names[0] = "Team 1";
        names[1] = "Team 2";

        string[] memory metadata = new string[](1); // Different length
        metadata[0] = "ipfs://team1";

        vm.expectRevert(Errors.ArrayLengthMismatch.selector);
        market.createBulkTeams(names, metadata);
    }

    function test_RevertBulkCreateTeamsBatchSizeTooLarge() public {
        string[] memory names = new string[](51); // Over limit
        string[] memory metadata = new string[](51);

        for (uint256 i = 0; i < 51; i++) {
            names[i] = string(abi.encodePacked("Team ", i));
            metadata[i] = string(abi.encodePacked("ipfs://team", i));
        }

        vm.expectRevert(Errors.BatchSizeTooLarge.selector);
        market.createBulkTeams(names, metadata);
    }

    function test_RevertBulkCreateTeamsEmptyName() public {
        string[] memory names = new string[](2);
        names[0] = "Valid Team";
        names[1] = ""; // Empty name

        string[] memory metadata = new string[](2);
        metadata[0] = "ipfs://valid";
        metadata[1] = "ipfs://empty";

        vm.expectRevert(Errors.TeamNameRequired.selector);
        market.createBulkTeams(names, metadata);
    }

    function test_RevertBulkCreateTeamsEmptyArray() public {
        string[] memory names = new string[](0);
        string[] memory metadata = new string[](0);

        vm.expectRevert(Errors.TeamNameRequired.selector);
        market.createBulkTeams(names, metadata);
    }

    function test_RevertBulkCreateTeamsNonAdmin() public {
        string[] memory names = new string[](1);
        names[0] = "Test Team";

        string[] memory metadata = new string[](1);
        metadata[0] = "ipfs://test";

        vm.prank(user1);
        vm.expectRevert();
        market.createBulkTeams(names, metadata);
    }
}

