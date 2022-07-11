//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IPreSale {
    struct CreateSale {
        uint256 total;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        bool hasVesting;
        uint248 initalPercentVesting;
        uint256 startTimeVesting;
        uint256 finishTimeVesting;
        uint256 totalPercentLiquidPool;
        uint256 softCap;
        uint256 hardCap;
        uint256 minPerUser;
        uint256 maxPerUser;
        string urlProperties;
        address token_;
        address paymentToken_;
        uint256 category;
        bool createLiquidPool;
        Forward[] forwards;
        uint256 discontPrice;
        bool uniswapPrice;
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
        uint248 initalPercentVesting;
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
        uint256 raised;
        uint256 price;
        uint256 finalPrice;
        uint256 discontPrice;
        bool initiated;
        string urlProperties;
        bool highlight;
        uint256 liked;
        uint256 softCap;
        uint256 hardCap;
        uint256 minPerUser;
        uint256 maxPerUser;
        address receiverLiquid;
        bool hasLiquidPool;
        bool uniswapPrice;
    }

    struct Forward {
        address addressReceiver;
        string name;
        uint256 percent;
        uint256 saleID;
    }

    function buy(uint256 amountInPaymentToken_, uint256 saleID) external;

    function pause() external;

    function unpause() external;

    function addSale(CreateSale memory createSale) external;

    function start(uint256 saleID) external;

    function listOpenSales() external view returns (Sale[] memory sales);

    function getSale(uint256 saleID) external view returns (Sale memory);

    function listForwards(uint256 saleID)
        external
        view
        returns (Forward[] memory forwards);

    function getTokenPriceUniSwap(uint256 saleID)
        external
        view
        returns (uint256[] memory);
}
