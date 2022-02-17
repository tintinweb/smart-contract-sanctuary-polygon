pragma solidity ^0.5.0;

import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";

contract GAS is Context, ERC20, ERC20Detailed {
    constructor () public ERC20Detailed("Poly-Peg GAS", "GAS", 8) {
        _mint(0x28FF66a1B95d7CAcf8eDED2e658f768F44841212, 100000000*10**8);
    }
}