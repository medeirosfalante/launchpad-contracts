//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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

    struct Price {
        uint256 price;
        string tokenName;
        string tokenSymbol;
        uint8 tokenDecimals;
        address tokenContract;
    }


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
