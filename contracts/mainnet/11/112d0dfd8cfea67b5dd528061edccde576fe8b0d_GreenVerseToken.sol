//SPDX-License-Identifier: MIT

pragma solidity 0.5.8;

import "./ERC20Mintable.sol";
import "./ERC20Detailed.sol";

contract GreenVerseToken is ERC20Mintable, ERC20Detailed {
    uint8 private constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 1000000 * (10 ** uint256(DECIMALS));

    constructor () public ERC20Detailed("GreenVerse", "GVC", DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}