pragma solidity =0.8.14;

contract Deposit{ 
     event Deposited(uint256 amount); 
     function deposit() external payable{      
       emit Deposited(msg.value); 
     } 
}