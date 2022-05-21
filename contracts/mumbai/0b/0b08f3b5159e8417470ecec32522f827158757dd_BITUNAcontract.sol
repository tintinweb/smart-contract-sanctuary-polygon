// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract BITUNAcontract is ERC20 {
    constructor() ERC20("BITUNA" , "BITUNA") {
        _mint(msg.sender , 11303828 * (10 ** uint256(decimals())));
    }
}