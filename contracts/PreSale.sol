//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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
    address public  uniswapV2Pair;

    string public constant DONT_WAVE_BALANCE_IN_PAYMENT_TOKEN =
        "PreSale: you dont have balance in token";

    string public constant PAYMENT_TOKEN_IS_INVALID =
        "PreSale: you dont have balance in token";

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    address public factory;

    constructor(address factory_) {
        _setupRole(MANAGER_ROLE, msg.sender);
        factory = factory_;
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
        IERC20Metadata erc20 = IERC20Metadata(paymentToken);
        require(
            erc20.balanceOf(msg.sender) <= amountInPaymentToken_,
            DONT_WAVE_BALANCE_IN_PAYMENT_TOKEN
        );
    }
}
