// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract Aure is ERC20, ERC20Burnable, Pausable, Ownable {

    uint256 public constant TOKEN_MAX_SUPPLY = 125000000*1e18;

    constructor(address treasury, uint256 initialSupply) ERC20("Aure", "AURE") {
        _mint(treasury, initialSupply);
    }

    function pause() 
        public 
        onlyOwner 
    {
        _pause();
    }

    function unpause() 
        public
        onlyOwner 
    {
        _unpause();
    }

    function mint(address to, uint256 amount) 
        public 
        whenNotPaused 
        onlyOwner 
    {
        require(totalSupply() + amount <= TOKEN_MAX_SUPPLY, "Exceeded the maximum supply of tokens");
        _mint(to, amount);
    }

    function burn(uint256 amount) 
        public 
        whenNotPaused 
        onlyOwner 
        override 
    {
        _burn(_msgSender(), amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}