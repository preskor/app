// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IPredictionMarket} from "./interfaces/IPredictionMarket.sol";
import {Errors} from "./Errors.sol";

/**
 * @title TeamManager
 * @notice Manages team entities with onchain and offchain data
 * @dev Separate contract for team management to reduce main contract size
 */
contract TeamManager is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 private _teamIdCounter;
    mapping(uint256 => IPredictionMarket.Team) private _teams;

    event TeamCreated(uint256 indexed teamId, string name, string metadata);
    event TeamUpdated(uint256 indexed teamId, string name, string metadata);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Create a new team entity
     * @param name Team name
     * @param metadata IPFS hash or external data reference
     * @return Team ID
     */
    function createTeam(
        string calldata name,
        string calldata metadata
    ) external onlyRole(ADMIN_ROLE) returns (uint256) {
        if (bytes(name).length == 0) revert Errors.TeamNameRequired();

        _teamIdCounter++;
        uint256 teamId = _teamIdCounter;

        _teams[teamId] = IPredictionMarket.Team({
            id: teamId,
            name: name,
            metadata: metadata,
            exists: true
        });

        emit TeamCreated(teamId, name, metadata);
        return teamId;
    }

    /**
     * @notice Update team information
     * @param teamId Team ID to update
     * @param name New team name
     * @param metadata New metadata
     */
    function updateTeam(
        uint256 teamId,
        string calldata name,
        string calldata metadata
    ) external onlyRole(ADMIN_ROLE) {
        if (!_teams[teamId].exists) revert Errors.TeamDoesNotExist();
        if (bytes(name).length == 0) revert Errors.TeamNameRequired();

        IPredictionMarket.Team storage team = _teams[teamId];
        team.name = name;
        team.metadata = metadata;

        emit TeamUpdated(teamId, name, metadata);
    }

    /**
     * @notice Get team information
     * @param teamId Team ID
     * @return Team struct
     */
    function getTeam(uint256 teamId) external view returns (IPredictionMarket.Team memory) {
        if (!_teams[teamId].exists) revert Errors.TeamDoesNotExist();
        return _teams[teamId];
    }

    /**
     * @notice Check if team exists
     * @param teamId Team ID
     * @return True if team exists
     */
    function teamExists(uint256 teamId) external view returns (bool) {
        return _teams[teamId].exists;
    }

    /**
     * @notice Get total number of teams
     * @return Total team count
     */
    function getTotalTeams() external view returns (uint256) {
        return _teamIdCounter;
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
}

