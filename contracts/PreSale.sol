//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IUniswapRouter02.sol";
import "./interfaces/IUniswapFactory.sol";
import "./interfaces/IUniswapV2Pair.sol";

import "./interfaces/IPreSale.sol";
import "./interfaces/IVesting.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract PreSale is Pausable, IPreSale, AccessControl {
    using Address for address;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    address private _cryptoSoulReceiverSale;
    address private _metaExpReceiverSale;
    address private vestingAddress;
    IUniswapFactory private uniswapFactory;
    IVesting private vestingFactory;
    IUniswapRouter02 private uniswapV2Router;
    Counters.Counter private _itemIds;
    Counters.Counter private _totalCategory;
    Counters.Counter private _totalSales;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    mapping(address => Order[]) private _ordersByUsers;
    mapping(uint256 => Order) private _orders;
    mapping(uint256 => Sale) private _sales;
    mapping(uint256 => Category) private _categories;

    string public constant DONT_WAVE_BALANCE_IN_PAYMENT_TOKEN =
        "PreSale: you dont have balance in token";
    string public constant DONT_WAVE_BALANCE_IN_TOKEN =
        "PreSale: you dont have balance in token";

    string public constant PAYMENT_TOKEN_IS_INVALID =
        "PreSale: you dont have balance in token";

    string public constant CATEGORY_DONT_EXISTS =
        "Category: you need create category";
    string public constant CATEGORY_NAME_EMPATY =
        "Category: Name cannot be empty";
    string public constant CATEGORY_ICON_EMPATY =
        "Category: Icon cannot be empty";
    string public constant TYPE_NAME_EMPATY = "Type: Name cannot be empty";
    string public constant TYPE_DONT_EXISTS = "Type: you need create sale";
    string public constant SALE_DONT_EXISTS = "Sale: you need create sale";
    string public constant SALE_ENDED = "Sale: ended";
    string public constant SALE_INITIATED = "Sale: initiated";
    string public constant SALE_DONT_INITIATED = "Sale: dont initiated";
    string public constant DONT_HAVE_ACCESS = "Sale: dont have access";
    event AddSale(Sale sale);

    constructor(address _uniswapRouterAddress, address _vestingAddress) {
        _setupRole(MANAGER_ROLE, msg.sender);
        uniswapV2Router = IUniswapRouter02(_uniswapRouterAddress);
        vestingFactory = IVesting(_vestingAddress);
        vestingAddress = _vestingAddress;
    }

    function start(uint256 saleID) public onlyRole(MANAGER_ROLE) {
        Sale memory sale = _sales[saleID];
        require(sale.id > 0, SALE_DONT_EXISTS);
        require(_sales[saleID].initiated == false, SALE_INITIATED);
        require(_sales[saleID].creator == msg.sender, DONT_HAVE_ACCESS);
        _sales[saleID].initiated = true;
    }

    function stop(uint256 saleID) public onlyRole(MANAGER_ROLE) {
        Sale memory sale = _sales[saleID];
        require(sale.id > 0, SALE_DONT_EXISTS);
        require(_sales[saleID].initiated == false, SALE_INITIATED);
        require(_sales[saleID].creator == msg.sender, DONT_HAVE_ACCESS);
        _sales[saleID].initiated = false;
    }

    function addSale(CreateSale memory createSale)
        public
        onlyRole(MANAGER_ROLE)
    {
        // uniswapFactory = IUniswapFactory(uniswapV2Router.factory());
        address uniswapV2Pair = address(0);
        _totalSales.increment();
        uint256 totalPercent = 100;

        uint256 current = _totalSales.current();

        IERC20Metadata erc20Token = IERC20Metadata(createSale.token_);
        require(
            erc20Token.balanceOf(msg.sender) > createSale.total,
            DONT_WAVE_BALANCE_IN_TOKEN
        );

        erc20Token.transferFrom(msg.sender, address(this), createSale.total);

        _sales[current] = Sale({
            id: current,
            totalLocked: 0,
            totalPercentLiquidPool: createSale.totalPercentLiquidPool,
            totalPercentForward: totalPercent.sub(
                createSale.totalPercentLiquidPool
            ),
            startTime: createSale.startTime,
            endTime: createSale.endTime,
            finished: false,
            hasVesting: createSale.hasVesting,
            startVesting: createSale.startTimeVesting,
            finishVesting: createSale.finishTimeVesting,
            tokenPaymentContract: createSale.paymentToken_,
            tokenContract: createSale.token_,
            pair: uniswapV2Pair,
            category: createSale.category,
            creator: msg.sender,
            total: createSale.total,
            totalSell: 0,
            balance: createSale.total,
            price: createSale.price,
            initiated: false,
            urlProperties: createSale.urlProperties,
            highlight: false,
            liked: 0,
            softCap: createSale.softCap,
            hardCap: createSale.hardCap,
            minPerUser: createSale.minPerUser,
            maxPerUser: createSale.maxPerUser,
            receiverLiquid: msg.sender
        });

        emit AddSale(_sales[current]);
    }

    function buy(uint256 amountInPaymentToken_, uint256 saleID)
        public
        whenNotPaused
    {
        Sale memory sale = _sales[saleID];
        require(_sales[saleID].id > 0, SALE_DONT_EXISTS);
        if (sale.endTime >= block.timestamp) {
            sale.finished = true;
        }
        require(sale.finished == false, SALE_ENDED);
        require(sale.initiated == true, SALE_DONT_INITIATED);

        require(
            sale.tokenPaymentContract != address(0),
            PAYMENT_TOKEN_IS_INVALID
        );
        IERC20Metadata erc20Payment = IERC20Metadata(sale.tokenPaymentContract);
        IERC20Metadata erc20Token = IERC20Metadata(sale.tokenContract);
        require(
            erc20Payment.balanceOf(msg.sender) <= amountInPaymentToken_,
            DONT_WAVE_BALANCE_IN_PAYMENT_TOKEN
        );

        erc20Payment.transferFrom(
            msg.sender,
            address(this),
            amountInPaymentToken_
        );
        uint256 totalTokenInDolar = amountInPaymentToken_.div(sale.price);
        erc20Token.approve(address(uniswapV2Router), amountInPaymentToken_);
        uint256 totalSendToPool = amountInPaymentToken_
            .mul(sale.totalPercentLiquidPool)
            .div(100);

        uint256 totalSendToSaleReceiver = amountInPaymentToken_
            .sub(totalSendToPool)
            .div(2);

        erc20Payment.transferFrom(
            _cryptoSoulReceiverSale,
            address(this),
            totalSendToSaleReceiver
        );
        erc20Payment.transferFrom(
            _metaExpReceiverSale,
            address(this),
            totalSendToSaleReceiver
        );

        uint256 totalTokenInDolarForPool = totalSendToPool.div(sale.price);

        uniswapV2Router.addLiquidityETH{value: totalSendToPool}(
            sale.tokenContract,
            totalTokenInDolarForPool,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            sale.receiverLiquid,
            block.timestamp
        );

        Order memory order = Order({
            buyer: msg.sender,
            price: sale.price,
            buyAt: block.timestamp,
            tokenContract: sale.tokenContract,
            tokenPaymentContract: sale.tokenPaymentContract,
            saleID: saleID,
            amountInToken: totalTokenInDolar
        });
        _orders[_itemIds.current()] = order;
        vestingFactory.addUserVesting(
            msg.sender,
            totalTokenInDolar,
            totalTokenInDolar,
            sale.startVesting,
            sale.finishVesting,
            sale.tokenContract
        );

        erc20Payment.transferFrom(
            vestingAddress,
            address(this),
            totalTokenInDolar
        );
    }

    function pause() public onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    function getPairRouter(uint256 saleID) public view returns (address) {
        Sale memory sale = _sales[saleID];
        require(_sales[saleID].id > 0, SALE_DONT_EXISTS);
        address pairAddress = uniswapFactory.getPair(
            sale.tokenContract,
            sale.tokenPaymentContract
        );
        return pairAddress;
    }

    function getSale(uint256 saleID) public view returns (Sale memory) {
        require(_sales[saleID].id > 0, SALE_DONT_EXISTS);
        return _sales[saleID];
    }

    function createCategory(string memory name, string memory icon)
        public
        onlyRole(MANAGER_ROLE)
        returns (uint256)
    {
        bytes memory nameBytes = bytes(name);
        bytes memory iconBytes = bytes(icon);
        require(nameBytes.length > 0, CATEGORY_NAME_EMPATY);
        require(iconBytes.length > 0, CATEGORY_ICON_EMPATY);
        _totalCategory.increment();
        _categories[_totalCategory.current()] = Category({
            id: _totalCategory.current(),
            name: name,
            icon: icon
        });
        return _totalCategory.current();
    }

    function listCategory() public view returns (Category[] memory categories) {
        uint256 totalItemCount = _totalCategory.current();
        uint256 currentIndex = 0;
        categories = new Category[](totalItemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            uint256 currentId = i + 1;
            Category storage currentItem = _categories[currentId];
            categories[currentIndex] = currentItem;
            currentIndex += 1;
        }
    }

    function getHighlight() public view returns (Sale memory sale) {
        uint256 totalItemCount = _totalSales.current();
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                _sales[i + 1].finished == false &&
                _sales[i + 1].initiated == true &&
                _sales[i + 1].highlight == true
            ) {
                sale = _sales[i + 1];
            }
        }
    }

    function defineHighlight(uint256 saleID)
        public
        onlyRole(MANAGER_ROLE)
        returns (Sale memory)
    {
        Sale memory sale = _sales[saleID];
        require(sale.id > 0, SALE_DONT_EXISTS);
        uint256 totalItemCount = _totalSales.current();
        for (uint256 i = 0; i < totalItemCount; i++) {
            _sales[i + 1].highlight = false;
        }
        _sales[saleID].highlight = true;
        return sale;
    }

    function listOpenSales() public view returns (Sale[] memory sales) {
        uint256 totalItemCount = _totalSales.current();
        uint256 totalItemCountlist = _totalSales.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                _sales[i + 1].finished == false &&
                _sales[i + 1].initiated == true
            ) {
                itemCount += 1;
            }
        }
        sales = new Sale[](itemCount);
        for (uint256 i = 0; i < totalItemCountlist; i++) {
            if (
                _sales[i + 1].finished == false &&
                _sales[i + 1].initiated == true
            ) {
                 uint256 currentId = i + 1;
                Sale storage currentItem = _sales[currentId];
                itemCount += 1;
                sales[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
    }

    function getMyOrders() public view returns (Order[] memory orders) {
        uint256 totalItemCount = _itemIds.current();
        uint256 totalItemCountlist = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (_orders[i + 1].buyer == msg.sender) {
                itemCount += 1;
            }
        }

        orders = new Order[](itemCount);
        for (uint256 i = 0; i < totalItemCountlist; i++) {
            if (_orders[i + 1].buyer == msg.sender) {
                uint256 currentId = 1;
                Order storage currentItem = _orders[currentId];
                itemCount += 1;
                orders[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
    }

    function getTokenPriceUniSwap(uint256 saleID, uint256 amount)
        public
        view
        returns (uint256)
    {
        address pairAddress = getPairRouter(saleID);

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        IERC20Metadata token1 = IERC20Metadata(pair.token1());
        (uint256 Res0, uint256 Res1, ) = pair.getReserves();

        // decimals
        uint256 res0 = Res0 * (10**token1.decimals());
        return ((amount * res0) / Res1); // return amount of token0 needed to buy token1
    }
}
