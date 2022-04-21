// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

import "./R91UpgradeableTokenChild.sol";

contract R91TokenChild is R91UpgradeableTokenChild {

    
    function initialize() initializer public {
      __ERC20_init("Rovi91", "R91", 0xb5505a6d998549090530911180f38aC5130101c6);
     }
    
    
}