// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC20.sol";
import "Ownable.sol";

// @custom:security-contact [email protected]
contract Virtu is ERC20, Ownable {
    constructor() ERC20("Virtu", "VTU") {
        _mint(msg.sender, 5000000 * 10 ** decimals());
    }
}