// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @title FreeStylers Esport UNIVERS
 * @author FreesTylers Esport HEXSEC Blockchain AUDIT
 * @notice Token, ERC20, Mintable
 * @custom:version 1.0.7
 * @custom:address 5
 * @custom:default-precision 18
 * @custom:simple-description Token that allows the owner to mint as many tokens as desired.
 * @dev ERC20 token with the following features:
 *
 *  - Premint your initial supply.
 *  - Mint as many tokens as you want with no cap.
 *  - Only the contract owner can mint new tokens.
 *
 */

contract MintableToken is ERC20, Ownable {
    /**
     * @param name FreeStylers Esport UNIVERS
     * @param symbol FSEUN
     * @param initialSupply 500000000
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) payable ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `to`, increasing
     * the total supply. Only accessible by the contract owner.
     */
    function mint(uint256 amount, address to) external onlyOwner {
        _mint(to, amount);
    }
    
   
}