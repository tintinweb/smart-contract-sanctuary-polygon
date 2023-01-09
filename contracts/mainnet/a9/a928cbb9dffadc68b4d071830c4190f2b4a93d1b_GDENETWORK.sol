/**
 *Submitted for verification at polygonscan.com on 2023-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract GDENETWORK {
    
    address owner;
    address  payable donde;
    uint[] ident;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

  	constructor() {
  	    owner = msg.sender;
    }

  	event Recarga_pay(address indexed user, uint indexed amount, uint time);
    event set_transfer(address indexed user,address indexed referrer,uint indexed amount, uint time);
  
    function fondos_contract(uint256 amount) public payable{
            require(msg.value == amount);
            emit Recarga_pay(msg.sender, amount,  block.timestamp);
    }

	function pay_now(address[] memory valor, uint256[] memory monto) public payable isOwner  {
	    uint i;
	    uint256 pagar;

      for ( i = 0; i < valor.length ; i++)
         {
            donde  =    payable(valor[i]);
            pagar  =    monto[i];
    
              donde.transfer(pagar);
             emit set_transfer(msg.sender, donde, pagar,  block.timestamp ); 
         } 
    
    }
    

  
    
}