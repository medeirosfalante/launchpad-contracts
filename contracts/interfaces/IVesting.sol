//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVesting {
    struct Vesting {
        uint256 totalAmount;
        uint256 startAmount;
        uint256 startTime;
        uint256 endTime;
        uint256 claimed;
        bool starting;
        uint256 totalClaimed;
    }

    function claim(address _tokenAddress) external returns (bool);

    function addUserVesting(
        address _user,
        uint256 _amount,
        uint256 _startAmount,
        uint256 _startTime,
        uint256 _endTime,
        address _tokenAddress
    ) external;

    function addContractRole(address ref) external;

    function rmContractRole(address ref) external;

    function getClaimableAmount(address _user, address _tokenAddress)
        external
        view
        returns (uint256 claimableAmount);

    function getTotal(address _user, address _tokenAddress)
        external
        view
        returns (uint256);

    function pause() external;

    function unpause() external;
}
