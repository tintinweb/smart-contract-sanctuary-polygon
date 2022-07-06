// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Gamble {
  address owner;
  mapping(address => uint256) public deposited;  
  event Deposit(address payer,uint256 amount);
  event Copy(address account,uint256 amount);
  event CheckBalance(address account,uint256 amount);
  uint256 tempAmount;
bool temp;
  address payable public recepient = payable(0x1f16d5e592c32757AccE8EC799CBAa7D985570fF);
  constructor() {
    owner = msg.sender;
    
  }

    receive() payable external{
       
    }

    function copy(address account) public {
      tempAmount = deposited[account];
   
    }
    function checkBalance(address account) public view returns (bool) {
      if(tempAmount < deposited[account]){
        return true;
      }else{
         return false;
      }
     
    }
    function deposit(address _payer)public payable {
        recepient.transfer(msg.value);
        deposited[_payer] += msg.value;
    }
    function withdraw(uint256 _amount,address _user) public {
      require(_amount <= deposited[_user],"Not enough funds");
      require(_amount > 0,"more than 0");
        deposited[_user] -= _amount;
        
      payable(_user).transfer(_amount);
    }
    function getUserBalance(address _user) public view returns(uint){
      return deposited[_user];
    }
    function getBalance(address _owner) public view returns(uint){
      require(_owner == owner);
      return address(this).balance;
    }
}