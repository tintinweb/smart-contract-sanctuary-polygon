// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Gamble {
  address owner;
  mapping(address => uint256) public deposited;  
  address payable withdrawer;
  constructor() {
    owner = msg.sender;
    
  }

    receive() payable external{
        deposit();
    }

    function deposit()public payable{
        deposited[msg.sender] += msg.value;
    }
    function withdraw(uint256 _amount) public {
      require(_amount <= deposited[msg.sender],"Not enough funds");
      require(_amount > 0,"more than 0");
        withdrawer = payable(msg.sender);
        deposited[withdrawer] -= _amount;
        
      payable(withdrawer).transfer(_amount);
    }
    function getUserBalance() public view returns(uint){
      return deposited[msg.sender];
    }
    function getBalance() public view returns(uint){
      // require(msg.sender == owner);
      return address(this).balance;
    }
}