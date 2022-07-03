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
import "./interfaces/IUniswapV2Pair.sol";

import "./interfaces/IPreSale.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract PreSale is Pausable, IPreSale, AccessControl {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    uint256 public totalVested;
    uint256 public totalClaimed;
    address private _receiverLiquid;
    address private _cryptoSoulReceiverSale;
    address private _metaExpReceiverSale;
    uint256 private tokensToPool = 4500 * 10**10;
    IUniswapFactory private uniswapFactory;
    IUniswapRouter02 private uniswapV2Router;
    Counters.Counter private _itemIds;
    Counters.Counter private _totalCategory;
    Counters.Counter private _totalTypes;
    Counters.Counter private _totalSales;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    mapping(address => Order[]) private _ordersByUsers;
    mapping(uint256 => Order) private _orders;
    mapping(uint256 => Sale) private _sales;
    mapping(uint256 => Category) private _categories;
    mapping(uint256 => Type) private _types;

    string public constant DONT_WAVE_BALANCE_IN_PAYMENT_TOKEN =
        "PreSale: you dont have balance in token";
    string public constant DONT_WAVE_BALANCE_IN_TOKEN =
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

    string public constant CATEGORY_DONT_EXISTS =
        "Category: you need create category";
    string public constant CATEGORY_NAME_EMPATY =
        "Category: Name cannot be empty";
    string public constant CATEGORY_ICON_EMPATY =
        "Category: Icon cannot be empty";
    string public constant TYPE_NAME_EMPATY = "Type: Name cannot be empty";
    string public constant SALE_DONT_EXISTS = "Sale: you need create sale";
    string public constant SALE_ENDED = "Sale: ended";
    string public constant SALE_INITIATED = "Sale: initiated";
    string public constant SALE_DONT_INITIATED = "Sale: dont initiated";
    string public constant DONT_HAVE_ACCESS = "Sale: dont have access";
    event UsersUpdated(address indexed token, uint256 users, uint256 amount);
    event Claimed(address indexed token, address indexed user, uint256 amount);

    event AddSale(Sale sale);

    mapping(bytes32 => mapping(address => bool)) public likedSale;

    mapping(uint256 => mapping(address => Vesting)) public userVesting;

    constructor(
        address _uniswapRouterAddress,
        address cryptoSoulReceiverSale_,
        address metaExpReceiverSale_
    ) {
        _setupRole(MANAGER_ROLE, msg.sender);
        _receiverLiquid = msg.sender;
        uniswapV2Router = IUniswapRouter02(_uniswapRouterAddress);
        _cryptoSoulReceiverSale = cryptoSoulReceiverSale_;
        _metaExpReceiverSale = metaExpReceiverSale_;
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
        uniswapFactory = IUniswapFactory(uniswapV2Router.factory());
        address uniswapV2Pair = uniswapFactory.createPair(
            createSale.token_,
            createSale.paymentToken_
        );
        _totalSales.increment();
        bytes32 saleId = keccak256(
            abi.encodePacked(
                block.timestamp,
                msg.sender,
                createSale.token_,
                createSale.paymentToken_,
                createSale.category,
                _totalSales.current()
            )
        );

        uint256 totalPercent = 100;

        IERC20Metadata erc20Token = IERC20Metadata(createSale.token_);
        require(
            erc20Token.balanceOf(msg.sender) > createSale.total,
            DONT_WAVE_BALANCE_IN_TOKEN
        );

        erc20Token.transferFrom(msg.sender, address(this), createSale.total);

        _sales[_totalSales.current()] = Sale({
            id: saleId,
            totalLocked: 0,
            totalPercentLiquidPool: 0,
            totalPercentForward: 0,
            startTime: 0,
            endTime: 0,
            finished: false,
            hasVesting: false,
            startVesting: 0,
            finishVesting: 0,
            tokenPaymentContract: createSale.paymentToken_,
            tokenContract: createSale.token_,
            pair: uniswapV2Pair,
            category: createSale.category,
            creator: msg.sender,
            total: 0,
            totalSell: 0,
            balance: 0,
            price: 0,
            initiated: false,
            urlProperties: createSale.urlProperties,
            highlight: false,
            liked: 0,
            softCap: 0,
            hardCap: 0,
            minPerUser: 0,
            maxPerUser: 0
        });
        _sales[_totalSales.current()].total = createSale.total;
        _sales[_totalSales.current()].price = createSale.price;
        _sales[_totalSales.current()].balance = createSale.total;
        _sales[_totalSales.current()].startTime = createSale.startTime;
        _sales[_totalSales.current()].endTime = createSale.endTime;
        _sales[_totalSales.current()].hasVesting = createSale.hasVesting;
        _sales[_totalSales.current()].startVesting = createSale
            .startTimeVesting;
        _sales[_totalSales.current()].finishVesting = createSale
            .finishTimeVesting;

        _sales[_totalSales.current()].totalPercentLiquidPool = createSale
            .totalPercentLiquidPool;
        _sales[_totalSales.current()].totalPercentForward = totalPercent.sub(
            createSale.totalPercentLiquidPool
        );
        _sales[_totalSales.current()].softCap = createSale.softCap;
        _sales[_totalSales.current()].hardCap = createSale.hardCap;
        _sales[_totalSales.current()].minPerUser = createSale.minPerUser;
        _sales[_totalSales.current()].maxPerUser = createSale.maxPerUser;

        emit AddSale(_sales[_totalSales.current()]);
    }

    function buy(uint256 amountInPaymentToken_, uint256 saleID)
        public
        whenNotPaused
    {
        Sale memory sale = _sales[saleID];
        require(_sales[saleID].id > 0, SALE_DONT_EXISTS);
        if (_sales[saleID].endTime >= block.timestamp) {
            _sales[saleID].finished = true;
        }
        require(_sales[saleID].finished == false, SALE_ENDED);
        require(_sales[saleID].initiated == true, SALE_DONT_INITIATED);

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
        uint256 totalTokenInDolar = amountInPaymentToken_.div(
            _sales[saleID].price
        );
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

        uint256 totalTokenInDolarForPool = totalSendToPool.div(
            _sales[saleID].price
        );

        uniswapV2Router.addLiquidityETH{value: totalSendToPool}(
            _sales[saleID].tokenContract,
            totalTokenInDolarForPool,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _receiverLiquid,
            block.timestamp
        );

        Order memory order = Order({
            buyer: msg.sender,
            price: _sales[saleID].price,
            buyAt: block.timestamp,
            tokenContract: _sales[saleID].tokenContract,
            tokenPaymentContract: _sales[saleID].tokenPaymentContract,
            saleID: saleID,
            amountInToken: totalTokenInDolar
        });

        uint256 finishVesting = _sales[saleID].finishVesting;
        uint256 startVesting = _sales[saleID].startVesting;
        _itemIds.increment();
        uint256 itemId = _itemIds.current();
        _orders[itemId] = order;
        addUserVesting(order, startVesting, finishVesting);
    }

    function addUserVesting(
        Order memory _order,
        uint256 _startTime,
        uint256 _endTime
    ) private {
        require(_order.buyer != address(0), VESTING_ZERO_ADDRESS);
        require(_order.amountInToken > 0, VESTING_ZERO_AMOUNT);
        // require(_startAmount <= _amount, VESTING_WRONG_TOKEN_VALUES);
        userVesting[_order.saleID][_order.buyer] = Vesting(
            _order.amountInToken,
            _order.amountInToken,
            _startTime,
            _endTime,
            0
        );
    }

    function claim(uint256 saleID) external whenNotPaused returns (bool) {
        Sale memory sale = _sales[saleID];
        require(sale.id > 0, SALE_DONT_EXISTS);
        uint256 tokens = getClaimableAmount(msg.sender, saleID);
        require(tokens > 0, VESTING_NO_CLAIMABLE_TOKENS_AVAILABLE);
        userVesting[saleID][msg.sender].claimed =
            userVesting[saleID][msg.sender].claimed +
            tokens;
        totalClaimed = totalClaimed + tokens;
        IERC20Metadata erc20Token = IERC20Metadata(sale.tokenContract);
        erc20Token.transferFrom(msg.sender, address(this), tokens);
        emit Claimed(sale.tokenContract, msg.sender, tokens);
        return true;
    }

    function getClaimableAmount(address _user, uint256 saleID)
        public
        view
        returns (uint256 claimableAmount)
    {
        Sale memory sale = _sales[saleID];
        require(sale.id > 0, SALE_DONT_EXISTS);

        Vesting storage _vesting = userVesting[saleID][_user];
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

    function getPairRouter(uint256 saleID) public view returns (address) {
        Sale memory sale = _sales[saleID];
        require(sale.id > 0, SALE_DONT_EXISTS);
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

    function getTokenPrice(uint256 saleID)
        public
        view
        returns (Price memory price)
    {
        require(_sales[saleID].id > 0, SALE_DONT_EXISTS);

        IERC20Metadata erc20Payment = IERC20Metadata(
            _sales[saleID].tokenPaymentContract
        );

        price.price = _sales[saleID].price;
        price.tokenName = erc20Payment.name();
        price.tokenSymbol = erc20Payment.symbol();
        price.tokenDecimals = erc20Payment.decimals();
        // (uint256 Res0, uint256 Res1, ) = pair.getReserves();
        // // decimals
        // uint256 res0 = Res0 * (10**erc20Payment.decimals());
        // return (res0 / Res1); // return amount of token0 needed to buy token1
        return price;
    }

    function createType(string memory name)
        public
        onlyRole(MANAGER_ROLE)
        returns (uint256)
    {
        bytes memory nameBytes = bytes(name);
        require(nameBytes.length > 0, TYPE_NAME_EMPATY);
        _totalTypes.increment();

        bytes32 id = keccak256(
            abi.encodePacked(
                block.timestamp,
                msg.sender,
                name,
                _totalSales.current()
            )
        );

        _types[_totalTypes.current()] = Category({name: name, id: id});
        return _totalTypes.current();
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

    function listType() public view returns (Type[] memory types) {
        uint256 totalItemCount = _totalTypes.current();
        uint256 currentIndex = 0;
        types = new Type[](totalItemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            uint256 currentId = i + 1;
            Type storage currentItem = _types[currentId];
            types[currentIndex] = currentItem;
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

    function toggleLike(uint256 saleID)
        public
        onlyRole(MANAGER_ROLE)
        returns (Sale memory)
    {
        Sale memory sale = _sales[saleID];
        require(sale.id > 0, SALE_DONT_EXISTS);

        if (likedSale[sale.id][msg.sender] == false) {
            likedSale[sale.id][msg.sender] = true;
            _sales[saleID].liked = _sales[saleID].liked.add(1);
        } else {
            likedSale[sale.id][msg.sender] = false;
        }
        sale.highlight = true;
        _sales[saleID] = sale;
        return sale;
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
                uint256 currentId = 1;
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
