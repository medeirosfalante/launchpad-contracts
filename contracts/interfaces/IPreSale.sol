//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IUniswapRouter02.sol";
import "./IUniswapFactory.sol";

interface IPreSale {
    function setPairLiquidPool(address token_, address paymentToken_) external;

    function claim() external returns (bool);

    function getClaimableAmount(address _user)
        external
        view
        returns (uint256 claimableAmount);

    function take(uint256 amountInPaymentToken_) external;

    function startVesting() external;

    function pause() external;

    function unpause() external;

    function getTokenPrice(address pairAddress) external view  returns (uint256);
}
