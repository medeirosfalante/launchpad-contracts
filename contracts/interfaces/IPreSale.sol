//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IPreSale {
    struct CreateSale {
        uint256 total;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        bool hasVesting;
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
    }

    struct Category {
        uint256 id;
        string name;
        string icon;
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
        bool highlight;
        uint256 liked;
        uint256 softCap;
        uint256 hardCap;
        uint256 minPerUser;
        uint256 maxPerUser;
        address receiverLiquid;
        bool hasLiquidPool;
    }

    struct Order {
        uint256 id;
        address buyer;
        uint256 price;
        uint256 buyAt;
        address tokenContract;
        address tokenPaymentContract;
        uint256 saleID;
        uint256 amountInToken;
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

    function getPairRouter(uint256 saleID) external view returns (address);

    function listOpenSales() external view returns (Sale[] memory sales);

    function listCategory()
        external
        view
        returns (Category[] memory categories);

    function getSale(uint256 saleID) external view returns (Sale memory);

    function listForwards(uint256 saleID)
        external
        view
        returns (Forward[] memory forwards);

    function addLiquidity(
        uint256 tokenAmount,
        uint256 ethAmount,
        uint256 saleID
    ) external;
}
