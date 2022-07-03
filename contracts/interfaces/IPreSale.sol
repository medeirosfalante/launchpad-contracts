//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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
    }

    struct Price {
        uint256 price;
        string tokenName;
        string tokenSymbol;
        uint8 tokenDecimals;
        address tokenContract;
    }

    struct Category {
        // Bid Id
        uint256 id;
        string name;
        string icon;
    }

    struct Sale {
        bytes32 id;
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

    function claim(uint256 saleID) external returns (bool);

    function getClaimableAmount(address _user, uint256 saleID)
        external
        view
        returns (uint256 claimableAmount);

    function buy(uint256 amountInPaymentToken_, uint256 saleID) external;

    function pause() external;

    function unpause() external;

    function addSale(CreateSale memory createSale) external;

    function start(uint256 saleID) external;

    function stop(uint256 saleID) external;

    function getTokenPrice(uint256 saleID)
        external
        view
        returns (Price memory price);

    function getPairRouter(uint256 saleID) external view returns (address);

    function listOpenSales() external view returns (Sale[] memory sales);

    function listCategory()
        external
        view
        returns (Category[] memory categories);

    function getSale(uint256 saleID) external view returns (Sale memory);

    function getHighlight() external view returns (Sale memory sale);

    function defineHighlight(uint256 saleID) external returns (Sale memory);

    function toggleLike(uint256 saleID) external returns (Sale memory);

    function getTokenPriceUniSwap(uint256 saleID, uint256 amount)
        external
        view
        returns (uint256);
}
