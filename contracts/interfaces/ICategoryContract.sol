//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICategoryContract {
    struct Category {
        uint256 id;
        string name;
        string icon;
    }

    function list()
        external
        view
        returns (Category[] memory categories);

    function create(string memory name, string memory icon)
        external
        returns (uint256);
}
