//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/Ilike.sol";

contract Like is Pausable, Ilike, AccessControl {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    string public constant LIKE_ZERO_ADDRESS = "Like: Zero address";
    string public constant LIKE_ZERO_AMOUNT = "Like: Zero address";
    string public constant LIKE_WRONG_TOKEN_VALUES =
        "Like: Zero Wrong token values";

    string public constant LIKE_NO_CLAIMABLE_TOKENS_AVAILABLE =
        "Like: No claimable tokens available";
    string public constant LIKE_NO_LIKE_AVAILABLE_FOR_USER =
        "Like:  No vesting available for user";

    string public constant PROJECT_DONT_EXISTS =
        "Project Like: you need create sale";

    Counters.Counter private _itemIds;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    string[] private types = ["nft", "token"];

    mapping(string => mapping(uint256 => mapping(address => bool)))
        public likedSale;
    mapping(string => mapping(uint256 => Project)) public projects;

    constructor() {
        _setupRole(MANAGER_ROLE, msg.sender);
    }

    function addContractRole(address ref) public onlyRole(MANAGER_ROLE) {
        _setupRole(MANAGER_ROLE, ref);
    }

    function rmContractRole(address ref) public onlyRole(MANAGER_ROLE) {
        revokeRole(MANAGER_ROLE, ref);
    }

    function addProject(
        uint256 id,
        string memory typeRef,
        address contractReference
    ) public onlyRole(MANAGER_ROLE) returns (Project memory) {
        _itemIds.increment();
        uint256 current = _itemIds.current();
        projects[typeRef][id] = Project({
            id: current,
            contractReference: contractReference,
            typeRef:typeRef,
            liked:0
        });
        return projects[typeRef][id];
    }

    function toggleLike(uint256 id, string memory typeRef)
        public
        returns (Project memory)
    {
        Project memory project = projects[typeRef][id];
        require(project.id > 0, PROJECT_DONT_EXISTS);

        if (likedSale[typeRef][id][msg.sender] == false) {
            likedSale[typeRef][id][msg.sender] = true;
            projects[typeRef][id].liked = projects[typeRef][id].liked.add(1);
        } else {
            likedSale[typeRef][id][msg.sender] = false;
            projects[typeRef][id].liked = projects[typeRef][id].liked.sub(1);
        }
        return project;
    }

    function pause() public onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(MANAGER_ROLE) {
        _unpause();
    }
}
