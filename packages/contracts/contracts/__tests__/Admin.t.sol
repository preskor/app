// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseTest} from "./BaseTest.t.sol";

/**
 * @title AdminTest
 * @notice Tests for admin role management
 */
contract AdminTest is BaseTest {

    function test_AddAdmin() public {
        market.addAdmin(admin);
        assertTrue(market.isAdmin(admin));
    }

    function test_RemoveAdmin() public {
        market.addAdmin(admin);
        assertTrue(market.isAdmin(admin));

        market.removeAdmin(admin);
        assertFalse(market.isAdmin(admin));
    }

    function test_AdminCanCreateMarket() public {
        market.addAdmin(admin);

        vm.prank(admin);
        uint256 marketId = market.createMarket(
            teamHomeId,
            teamAwayId,
            block.timestamp + 1 hours,
            block.timestamp + 3 hours
        );

        assertEq(marketId, 1);
    }

    function test_AdminCanCreateTeam() public {
        market.addAdmin(admin);

        vm.prank(admin);
        uint256 teamId = market.createTeam("Chelsea", "ipfs://chelsea");

        assertEq(teamId, 3);
    }

    function test_RevertNonAdminCannotCreateMarket() public {
        vm.prank(user1);
        vm.expectRevert();
        market.createMarket(
            teamHomeId,
            teamAwayId,
            block.timestamp + 1 hours,
            block.timestamp + 3 hours
        );
    }

    function test_RevertNonAdminCannotAddAdmin() public {
        vm.prank(user1);
        vm.expectRevert();
        market.addAdmin(admin);
    }
}

