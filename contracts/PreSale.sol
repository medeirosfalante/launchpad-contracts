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
import "./interfaces/IUniswapRouter02.sol";
import "./interfaces/IUniswapFactory.sol";

import "./interfaces/IPreSale.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract PreSale is Pausable, IPreSale, AccessControl {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    address public paymentToken;
    address public token;
    IUniswapRouter02 private uniswapV2Router02_;
    address public uniswapV2Pair;
    uint256 public totalVested;
    uint256 public totalClaimed;
    uint256 private DayVesting = 30;
    uint256 private startVesting;
    uint256 public _percentToPool = 50;
    address private _receiverLiquid;
    address private _receiverSale;

    string public constant DONT_WAVE_BALANCE_IN_PAYMENT_TOKEN =
        "PreSale: you dont have balance in token";

    string public constant PAYMENT_TOKEN_IS_INVALID =
        "PreSale: you dont have balance in token";

    string public constant VESTING_ZERO_ADDRESS = "Vesting: Zero address";
    string public constant VESTING_ZERO_AMOUNT = "Vesting: Zero address";
    string public constant VESTING_WRONG_TOKEN_VALUES =
        "Vesting: Zero Wrong token values";

    string public constant VESTING_NO_CLAIMABLE_TOKENS_AVAILABLE =
        "Vesting: No claimable tokens available";
    string public constant VESTING_NO_VESTING_AVAILABLE_FOR_USER =
        "Vesting:  No vesting available for user";

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    address public factory;

    struct Vesting {
        uint256 totalAmount;
        uint256 startAmount;
        uint256 startTime;
        uint256 endTime;
        uint256 claimed;
    }

    mapping(address => Vesting) public userVesting;

    constructor(address factory_) {
        _setupRole(MANAGER_ROLE, msg.sender);
        _receiverLiquid = msg.sender;
        _receiverSale = msg.sender;
        factory = factory_;
    }

    function startVesting(uint256 amountInPaymentToken_)
        public
        whenNotPaused
        onlyRole(MANAGER_ROLE)
    {
        startVesting = block.timestamp;
    }

    function setPairLiquidPool(address token_, address paymentToken_)
        public
        onlyRole(MANAGER_ROLE)
    {
        IUniswapRouter02 _uniswapV2Router = IUniswapRouter02(factory);
        uniswapV2Pair = IUniswapFactory(_uniswapV2Router.factory()).createPair(
            token_,
            paymentToken_
        );
        uniswapV2Router02_ = _uniswapV2Router;
        paymentToken = paymentToken_;
        token = token_;
    }

    function take(uint256 amountInPaymentToken_) public whenNotPaused {
        require(paymentToken != address(0), PAYMENT_TOKEN_IS_INVALID);
        IERC20Metadata erc20Payment = IERC20Metadata(paymentToken);
        require(
            erc20Payment.balanceOf(msg.sender) <= amountInPaymentToken_,
            DONT_WAVE_BALANCE_IN_PAYMENT_TOKEN
        );

        erc20Payment.transferFrom(
            msg.sender,
            address(this),
            amountInPaymentToken_
        );
        uint256 total;
        _approve(address(this), address(factory), amountInPaymentToken_);
        uint256 totalSendToPool = amountInPaymentToken_.mul(_percentToPool).div(
            100
        );

        uint256 totalSendToSaleReceiver = amountInPaymentToken_.sub(
            totalSendToPool
        );

        erc20Payment.transferFrom(
            _receiverSale,
            address(this),
            totalSendToSaleReceiver
        );

        pancakeV2Router.addLiquidityETH{value: totalSendToPool}(
            token,
            total,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _receiverLiquid,
            block.timestamp
        );

        finishVesting = block.timestamp.add(DayVesting * 1 days);
        addUserVesting(msg.sender, total, total, startVesting, finishVesting);
    }

    function addUserVesting(
        address _user,
        uint256 _amount,
        uint256 _startAmount,
        uint256 _startTime,
        uint256 _endTime
    ) private {
        require(_user != address(0), VESTING_ZERO_ADDRESS);
        require(_amount > 0, VESTING_ZERO_AMOUNT);
        require(_startAmount <= _amount, VESTING_WRONG_TOKEN_VALUES);
        userVesting[_user] = Vesting(
            _amount,
            _startAmount,
            _startTime,
            _endTime,
            0
        );
    }

    function claim() external whenNotPaused returns (bool) {
        uint256 tokens = getClaimableAmount(msg.sender);
        require(tokens > 0, VESTING_NO_CLAIMABLE_TOKENS_AVAILABLE);
        userVesting[msg.sender].claimed =
            userVesting[msg.sender].claimed +
            tokens;
        totalClaimed = totalClaimed + tokens;
        IERC20Metadata erc20Token = IERC20Metadata(token);
        erc20Token.safeTransfer(msg.sender, tokens);
        emit Claimed(tokenAddress, msg.sender, tokens);
        return true;
    }

    function getClaimableAmount(address _user)
        public
        view
        returns (uint256 claimableAmount)
    {
        Vesting storage _vesting = userVesting[_user];
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
