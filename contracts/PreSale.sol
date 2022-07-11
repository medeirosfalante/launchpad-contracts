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
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";

import "./interfaces/IPreSale.sol";
import "./interfaces/IVesting.sol";
import "./interfaces/ICategoryContract.sol";
import "./interfaces/IOrderContract.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract PreSale is Pausable, IPreSale, AccessControl {
    using Address for address;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    address private _cryptoSoulReceiverSale;
    address private _metaExpReceiverSale;
    address private immutable vestingAddress;
    address private immutable categoryAddress;
    address private immutable orderAddress;
    IUniswapFactory private uniswapFactory;
    IVesting private vestingFactory;
    ICategoryContract private immutable categoryContractFactory;
    IOrderContract private immutable orderContractFactory;

    IUniswapRouter02 private uniswapV2Router;
    Counters.Counter private _totalCategory;
    Counters.Counter private _totalSales;
    Counters.Counter private _forwardIds;

    uint256 private factor = 50;
    uint256 private factorPercent = 5000;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    mapping(uint256 => Sale) private _sales;
    mapping(uint256 => Forward) private _forwardAddresses;
    mapping(uint256 => mapping(address => uint256)) private _maxPerUsers;
    mapping(uint256 => mapping(address => bool)) private _activeUser;

    string public constant DONT_WAVE_BALANCE_IN_PAYMENT_TOKEN =
        "PreSale: you dont have balance in token";
    string public constant DONT_WAVE_BALANCE_IN_TOKEN =
        "PreSale: you dont have balance in token";

    string public constant PAYMENT_TOKEN_IS_INVALID =
        "PreSale: you dont have balance in token";
    string public constant SALE_DONT_EXISTS = "Sale: you need create sale";
    string public constant SALE_ENDED = "Sale: ended";
    string public constant SALE_INITIATED = "Sale: initiated";
    string public constant SALE_DONT_INITIATED = "Sale: dont initiated";
    string public constant DONT_HAVE_ACCESS = "Sale: dont have access";
    string public constant MIN_PER_USER =
        "Sale: did not reach the mandatory minimum";
    string public constant MAX_PER_USER =
        "Sale: you reached the maximum for the sale";
    event AddSale(Sale sale);
    event BuySale(Sale sale);

    constructor(
        address _uniswapRouterAddress,
        address _vestingAddress,
        address _categoryAddress,
        address _orderAddress
    ) {
        _setupRole(MANAGER_ROLE, msg.sender);
        uniswapV2Router = IUniswapRouter02(_uniswapRouterAddress);
        vestingFactory = IVesting(_vestingAddress);
        categoryContractFactory = ICategoryContract(_categoryAddress);
        orderContractFactory = IOrderContract(_orderAddress);
        vestingAddress = _vestingAddress;
        categoryAddress = _categoryAddress;
        orderAddress = _orderAddress;
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
        address uniswapV2Pair = address(0);
        uint256 totalPercentLiquidPool = 0;

        if (createSale.createLiquidPool) {
            uniswapFactory = IUniswapFactory(uniswapV2Router.factory());
            uniswapV2Pair = uniswapFactory.getPair(
                createSale.token_,
                createSale.paymentToken_
            );
            if (uniswapV2Pair == address(0)) {
                uniswapV2Pair = uniswapFactory.createPair(
                    createSale.token_,
                    createSale.paymentToken_
                );
            }
            totalPercentLiquidPool = createSale.totalPercentLiquidPool;
        }
        IERC20Metadata erc20Token = IERC20Metadata(createSale.token_);

        _totalSales.increment();
        uint256 current = _totalSales.current();
        uint256 totalPercent = 100;

        // (5000*50)/10**4

        uint256 totalfactor = factorPercent.sub(
            createSale.discontPrice.mul(factor)
        );
        uint256 totalsend = createSale
            .total
            .div(10**(erc20Token.decimals() - 2))
            .mul(totalfactor);
        require(
            erc20Token.balanceOf(msg.sender) >
                createSale.total.add(
                    totalsend * 10**(erc20Token.decimals() - 6)
                ),
            DONT_WAVE_BALANCE_IN_TOKEN
        );

        erc20Token.transferFrom(
            msg.sender,
            address(this),
            totalsend * 10**(erc20Token.decimals() - 6)
        );
        erc20Token.transferFrom(msg.sender, address(this), createSale.total);

        _sales[current] = Sale({
            id: current,
            totalLocked: 0,
            totalPercentLiquidPool: createSale.totalPercentLiquidPool,
            totalPercentForward: totalPercent.sub(totalPercentLiquidPool),
            startTime: createSale.startTime,
            endTime: createSale.endTime,
            finished: false,
            hasVesting: createSale.hasVesting,
            initalPercentVesting: createSale.initalPercentVesting,
            startVesting: createSale.startTimeVesting,
            finishVesting: createSale.finishTimeVesting,
            tokenPaymentContract: createSale.paymentToken_,
            tokenContract: createSale.token_,
            pair: uniswapV2Pair,
            category: createSale.category,
            creator: msg.sender,
            total: createSale.total,
            totalSell: 0,
            raised: 0,
            balance: createSale.total,
            price: createSale.price,
            finalPrice: createSale.price.sub(
                createSale.price.div(100).mul(createSale.discontPrice)
            ),
            initiated: false,
            urlProperties: createSale.urlProperties,
            highlight: false,
            liked: 0,
            softCap: createSale.softCap,
            hardCap: createSale.hardCap,
            minPerUser: createSale.minPerUser,
            maxPerUser: createSale.maxPerUser,
            receiverLiquid: msg.sender,
            hasLiquidPool: createSale.createLiquidPool,
            uniswapPrice: createSale.uniswapPrice,
            discontPrice: createSale.discontPrice
        });

        for (uint256 i = 0; i < createSale.forwards.length; i++) {
            _forwardIds.increment();
            _forwardAddresses[_forwardIds.current()] = Forward({
                name: createSale.forwards[i].name,
                percent: createSale.forwards[i].percent,
                addressReceiver: createSale.forwards[i].addressReceiver,
                saleID: current
            });
        }

        emit AddSale(_sales[current]);
    }

    function buy(uint256 amountInPaymentToken_, uint256 saleID)
        public
        whenNotPaused
    {
        Sale memory sale = _sales[saleID];
        require(_sales[saleID].id > 0, SALE_DONT_EXISTS);
        if (block.timestamp >= sale.endTime) {
            sale.finished = true;
        }
        if (_activeUser[saleID][msg.sender] == false) {
            _activeUser[saleID][msg.sender] = true;
            _maxPerUsers[saleID][msg.sender] = sale.maxPerUser;
        }
        require(amountInPaymentToken_ > sale.minPerUser, MIN_PER_USER);
        require(
            amountInPaymentToken_ < _maxPerUsers[saleID][msg.sender],
            MAX_PER_USER
        );

        require(sale.finished == false, SALE_ENDED);
        require(sale.initiated == true, SALE_DONT_INITIATED);

        require(
            sale.tokenPaymentContract != address(0),
            PAYMENT_TOKEN_IS_INVALID
        );
        IERC20Metadata erc20Payment = IERC20Metadata(sale.tokenPaymentContract);
        IERC20Metadata erc20Token = IERC20Metadata(sale.tokenContract);
        require(
            erc20Payment.balanceOf(msg.sender) >= amountInPaymentToken_,
            DONT_WAVE_BALANCE_IN_PAYMENT_TOKEN
        );

        if (sale.uniswapPrice) {
            // uint256 price = getTokenPriceUniSwap(saleID);
            // if (price > 0) {
            //     sale.price = price;
            //     sale.finalPrice = sale.price.sub(
            //         sale.price.div(100).mul(sale.discontPrice)
            //     );
            // }
        } else {
            sale.finalPrice = sale.price.sub(
                sale.price.div(100).mul(sale.discontPrice)
            );
        }
        erc20Payment.transferFrom(
            msg.sender,
            address(this),
            amountInPaymentToken_
        );
        uint256 totalTokenInDolar = amountInPaymentToken_.div(sale.finalPrice);

        uint256 totalSendToPool = 0;

        if (sale.hasLiquidPool) {
            totalSendToPool = amountInPaymentToken_.div(100).mul(
                sale.totalPercentLiquidPool
            );
            address router = getPairRouter(saleID);
            if (router == address(0)) {
                router = uniswapFactory.createPair(
                    sale.tokenContract,
                    sale.tokenPaymentContract
                );
            }
            uint256 totalTokenInDolarForPool = totalSendToPool.div(sale.price);

            erc20Token.approve(
                router,
                totalTokenInDolarForPool * 10**erc20Token.decimals()
            );
            erc20Payment.approve(router, totalSendToPool);
            erc20Token.approve(
                address(uniswapV2Router),
                totalTokenInDolarForPool * 10**erc20Token.decimals()
            );
            erc20Payment.approve(address(uniswapV2Router), totalSendToPool);
            // add the liquidity
            uniswapV2Router.addLiquidity(
                sale.tokenContract,
                sale.tokenPaymentContract,
                totalTokenInDolarForPool * 10**erc20Token.decimals(),
                totalSendToPool,
                totalTokenInDolarForPool * 10**erc20Token.decimals(),
                totalSendToPool,
                sale.receiverLiquid,
                block.timestamp + 100
            );
        }

        uint256 forwardValue = amountInPaymentToken_.sub(totalSendToPool);

        Forward[] memory forwards = listForwards(saleID);

        for (uint256 i = 0; i < forwards.length; i++) {
            erc20Payment.transfer(
                forwards[i].addressReceiver,
                forwardValue.div(100).mul(forwards[i].percent)
            );
        }

        orderContractFactory.addOrder(
            msg.sender,
            sale.finalPrice,
            block.timestamp,
            sale.tokenContract,
            sale.tokenPaymentContract,
            saleID,
            totalTokenInDolar
        );

        sale.balance = sale.balance.sub(totalTokenInDolar);
        sale.totalSell = sale.totalSell.add(totalTokenInDolar);
        sale.raised = sale.raised.add(amountInPaymentToken_);
        _sales[saleID] = sale;

        if (sale.hasVesting) {
            erc20Token.transfer(
                vestingAddress,
                totalTokenInDolar * 10**erc20Token.decimals()
            );
            vestingFactory.addUserVesting(
                msg.sender,
                totalTokenInDolar,
                totalTokenInDolar.div(100).mul(sale.initalPercentVesting),
                sale.startVesting,
                sale.finishVesting,
                sale.tokenContract
            );
        } else {
            erc20Token.transfer(
                msg.sender,
                totalTokenInDolar * 10**erc20Token.decimals()
            );
        }
        emit BuySale(sale);
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

    function listForwards(uint256 saleID)
        public
        view
        returns (Forward[] memory forwards)
    {
        uint256 totalItemCount = _forwardIds.current();
        uint256 totalItemCountlist = _forwardIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (_forwardAddresses[i + 1].saleID == saleID) {
                itemCount += 1;
            }
        }

        forwards = new Forward[](itemCount);
        for (uint256 i = 0; i < totalItemCountlist; i++) {
            if (_forwardAddresses[i + 1].saleID == saleID) {
                uint256 currentId = i + 1;
                Forward storage currentItem = _forwardAddresses[currentId];
                forwards[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
    }

    function getTokenPriceUniSwap(uint256 saleID)
        public
        view
        returns (uint256[] memory)
    {
        Sale memory sale = _sales[saleID];
        require(_sales[saleID].id > 0, SALE_DONT_EXISTS);
        address[] memory path;
        path[0] = sale.tokenPaymentContract;
        path[1] = sale.tokenContract;
        uint256[] memory amounts = uniswapV2Router.getAmountsOut(
            10000000000,
            path
        );
        return amounts; // return amount of token0 needed to buy token1
    }
}
