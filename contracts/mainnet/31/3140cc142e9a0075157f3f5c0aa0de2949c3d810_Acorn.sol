// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract Acorn is ERC20 {
    constructor() ERC20("Acorn", "ACRN") {
        _mint(msg.sender, 10000000 * 10 ** decimals());
    }
}