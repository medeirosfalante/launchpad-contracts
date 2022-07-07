//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IOrderContract.sol";

contract OrderContract is Pausable, IOrderContract, AccessControl {
    using Address for address;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;

    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    mapping(uint256 => Order) private _orders;

    constructor() {
        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(CONTRACT_ROLE, msg.sender);
    }

    function pause() public onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    function addContractRole(address ref) public onlyRole(MANAGER_ROLE) {
        _setupRole(CONTRACT_ROLE, ref);
    }

    function rmContractRole(address ref) public onlyRole(MANAGER_ROLE) {
        revokeRole(CONTRACT_ROLE, ref);
    }

    function listBySaleID(uint256 saleID)
        public
        view
        returns (Order[] memory orders)
    {
        uint256 totalItemCount = _itemIds.current();
        uint256 totalItemCountlist = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (_orders[i + 1].saleID == saleID) {
                itemCount += 1;
            }
        }

        orders = new Order[](itemCount);
        for (uint256 i = 0; i < totalItemCountlist; i++) {
            if (_orders[i + 1].saleID == saleID) {
                uint256 currentId = i + 1;
                Order storage currentItem = _orders[currentId];
                itemCount += 1;
                orders[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
    }

    function listByUser() public view returns (Order[] memory orders) {
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
                uint256 currentId = i + 1;
                Order storage currentItem = _orders[currentId];
                itemCount += 1;
                orders[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
    }

    function addOrder(
        address buyer,
        uint256 price,
        uint256 buyAt,
        address tokenContract,
        address tokenPaymentContract,
        uint256 saleID,
        uint256 amountInToken
    ) public onlyRole(CONTRACT_ROLE) returns (uint256) {
        _itemIds.increment();
        _orders[_itemIds.current()] = Order({
            id: _itemIds.current(),
            buyer: buyer,
            price: price,
            buyAt: buyAt,
            tokenContract: tokenContract,
            tokenPaymentContract: tokenPaymentContract,
            saleID: saleID,
            amountInToken: amountInToken
        });
        return _itemIds.current();
    }
}
