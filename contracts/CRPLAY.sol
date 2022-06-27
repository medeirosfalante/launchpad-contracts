// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CRPLAY is ERC20 {
    constructor() ERC20("CryptoSoul Roleplay", "CRPLAY") {
        _mint(msg.sender, 1000000000 * 10**10);
    }

    function decimals() public view virtual override returns (uint8) {
        return 10;
    }
}
