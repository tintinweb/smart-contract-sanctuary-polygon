pragma solidity ^0.8.0;

import "./ERC20.sol";

contract SNMToken is ERC20 {
    constructor(uint256 initialSupply) public ERC20("Saynomore", "SNM") {
        _mint(msg.sender, initialSupply);
    }
}