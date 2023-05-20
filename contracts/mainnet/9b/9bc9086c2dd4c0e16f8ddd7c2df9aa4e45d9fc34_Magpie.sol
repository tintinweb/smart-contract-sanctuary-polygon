// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract Magpie is ERC20 {
    constructor() ERC20("Magpie", "MAGPIE") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}