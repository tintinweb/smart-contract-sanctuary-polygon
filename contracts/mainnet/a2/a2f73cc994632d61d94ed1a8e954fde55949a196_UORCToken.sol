// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

import "./UORCUpgradeableToken.sol";

contract UORCToken is UORCUpgradeableToken {

    
    function initialize(address mintAddress_, uint256 initialSupply_) initializer public {
      __ERC20_init("UORCoin", "UORC", mintAddress_, initialSupply_);
     }
    
    
}