// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FracDealERC.sol";

contract FracDeal is ERC20 {
    constructor() ERC20("FracDeal TEST", "FRX04") {
        _mint(msg.sender, 1000000000);
    }
}