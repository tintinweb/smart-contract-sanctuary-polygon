// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract Azure is ERC20 {
    constructor() ERC20("Azure", "AZURE") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}