//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
 
import "./ERC20.sol";

contract YSTToken is ERC20{

    // string  public  name = "LuckyCoin";
    // string public symbol = "LC";
    // uint8 public decimals = 18;
    // uint public INITIAL_SUPPLY = 12000;
   constructor() ERC20("YST","yst",100000){
      //_mint(msg.sender,initialSupply);
    }
}