//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IUniswapRouter02.sol";
import "./IUniswapFactory.sol";

interface IPreSale {
    function setPairLiquidPool(address token_, address paymentToken_) external;
}
