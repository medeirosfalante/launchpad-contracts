//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IUniswapRouter02.sol";
import "./IUniswapFactory.sol";

interface Ilike {
    struct Project {
        uint256 id;
        address contractReference;
        string typeRef;
        uint256 liked;
    }

    function addProject(
        uint256 id,
        string memory typeRef,
        address contractReference
    ) external returns (Project memory);

    function toggleLike(uint256 id, string memory typeRef)
        external
        returns (Project memory);

    function addContractRole(address ref) external;

    function rmContractRole(address ref) external;

    function pause() external;

    function unpause() external;
}
