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
import "./interfaces/IVesting.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract Vesting is Pausable, IVesting, AccessControl {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    string public constant VESTING_ZERO_ADDRESS = "Vesting: Zero address";
    string public constant VESTING_ZERO_AMOUNT = "Vesting: Zero address";
    string public constant VESTING_WRONG_TOKEN_VALUES =
        "Vesting: Zero Wrong token values";

    string public constant VESTING_NO_CLAIMABLE_TOKENS_AVAILABLE =
        "Vesting: No claimable tokens available";
    string public constant VESTING_NO_VESTING_AVAILABLE_FOR_USER =
        "Vesting:  No vesting available for user";

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    event UsersUpdated(address indexed token, uint256 users, uint256 amount);
    event Claimed(address indexed token, address indexed user, uint256 amount);

    mapping(address => mapping(address => Vesting)) public userVesting;

    constructor() {
        _setupRole(MANAGER_ROLE, msg.sender);
    }

    function addContractRole(address ref)
        public
        onlyRole(MANAGER_ROLE)
    {
        _setupRole(MANAGER_ROLE, ref);
    }

    function rmContractRole(address ref)
        public
        onlyRole(MANAGER_ROLE)
    {
        revokeRole(MANAGER_ROLE, ref);
    }

    function addUserVesting(
        address _user,
        uint256 _amount,
        uint256 _startAmount,
        uint256 _startTime,
        uint256 _endTime,
        address _tokenAddress
    ) public onlyRole(MANAGER_ROLE) {
        require(_user != address(0), VESTING_ZERO_ADDRESS);
        require(_startAmount > 0, VESTING_ZERO_AMOUNT);
        require(_startAmount <= _amount, VESTING_WRONG_TOKEN_VALUES);
        userVesting[_tokenAddress][_user] = Vesting(
            _amount,
            _startAmount,
            _startTime,
            _endTime,
            0,
            true,
            0
        );
    }

    function claim(address _tokenAddress) public whenNotPaused returns (bool) {
        uint256 tokens = getClaimableAmount(msg.sender, _tokenAddress);
        require(tokens > 0, VESTING_NO_CLAIMABLE_TOKENS_AVAILABLE);
        userVesting[_tokenAddress][msg.sender].claimed =
            userVesting[_tokenAddress][msg.sender].claimed +
            tokens;
        userVesting[_tokenAddress][msg.sender].totalClaimed =
            userVesting[_tokenAddress][msg.sender].totalClaimed +
            tokens;
        IERC20Metadata erc20Token = IERC20Metadata(_tokenAddress);
        erc20Token.transferFrom(msg.sender, address(this), tokens);
        emit Claimed(_tokenAddress, msg.sender, tokens);
        return true;
    }

    function getClaimableAmount(address _user, address _tokenAddress)
        public
        view
        returns (uint256 claimableAmount)
    {
        Vesting storage _vesting = userVesting[_tokenAddress][_user];
        require(
            _vesting.totalAmount > 0,
            VESTING_NO_VESTING_AVAILABLE_FOR_USER
        );
        if (_vesting.totalAmount == _vesting.claimed) return 0;

        if (_vesting.startTime > block.timestamp) return 0;

        if (block.timestamp < _vesting.endTime) {
            uint256 timePassedRatio = ((block.timestamp - _vesting.startTime) *
                10**18) / (_vesting.endTime - _vesting.startTime);

            claimableAmount =
                (((_vesting.totalAmount - _vesting.startAmount) *
                    timePassedRatio) / 10**18) +
                _vesting.startAmount;
        } else {
            claimableAmount = _vesting.totalAmount;
        }

        claimableAmount = claimableAmount - _vesting.claimed;
    }

    function pause() public onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(MANAGER_ROLE) {
        _unpause();
    }
}
