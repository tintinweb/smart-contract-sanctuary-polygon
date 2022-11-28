pragma solidity ^0.5.1;

import "./ERC20.sol";


contract soundME is ERC20 {

   
    constructor () public ERC20Detailed("soundME", "SDM", 18) {
        mint(msg.sender, 1000000000000 * (10 ** uint(decimals())));
    }

 

}