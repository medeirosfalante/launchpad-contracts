//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOrderContract {
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

    function listBySaleID(uint256 saleID)
        external
        view
        returns (Order[] memory orders);

    function listByUser() external view returns (Order[] memory orders);

    function addOrder(
        address buyer,
        uint256 price,
        uint256 buyAt,
        address tokenContract,
        address tokenPaymentContract,
        uint256 saleID,
        uint256 amountInToken
    ) external returns (uint256);

    function addContractRole(address ref) external;

    function rmContractRole(address ref) external;
}
