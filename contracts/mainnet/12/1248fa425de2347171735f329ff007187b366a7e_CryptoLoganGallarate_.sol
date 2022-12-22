// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC20.sol";

contract CryptoLoganGallarate_ is ERC20 {
    constructor() ERC20("Crypto Logan Gallarate", "CLG") {
        _mint(msg.sender, 21000000 * 10 ** decimals());
    }
}