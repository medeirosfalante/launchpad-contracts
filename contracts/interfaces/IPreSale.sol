//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IUniswapRouter02.sol";
import "./IUniswapFactory.sol";

interface IPreSale {
    struct Vesting {
        uint256 totalAmount;
        uint256 startAmount;
        uint256 startTime;
        uint256 endTime;
        uint256 claimed;
    }

    struct Price {
        uint256 price;
        string tokenName;
        string tokenSymbol;
        uint8 tokenDecimals;
        address tokenContract;
    }

    struct Sale {
        uint256 id;
        uint256 totalLocked;
        uint256 totalPercentLiquidPool;
        uint256 totalPercentForward;
        uint256 startTime;
        uint256 endTime;
        bool finished;
        bool hasVesting;
        uint256 startVesting;
        uint256 finishVesting;
        address tokenPaymentContract;
        address tokenContract;
        address pair;
        uint256 category;
        address creator;
        uint256 total;
        uint256 totalSell;
        uint256 balance;
        uint256 price;
        bool initiated;
        string urlProperties;
    }

    struct Order {
        address buyer;
        uint256 price;
        uint256 buyAt;
        address tokenContract;
        address tokenPaymentContract;
        uint256 saleID;
        uint256 amountInToken;
    }
        external
        view
        returns (uint256 claimableAmount);

    function take(uint256 amountInPaymentToken_) external;

    function startVesting() external;

    function pause() external;

    function unpause() external;

    function getTokenPrice(address pairAddress) external view  returns (uint256);
}
