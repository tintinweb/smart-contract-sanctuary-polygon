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
  bool tempForAmount = true;
  constructor() {
    owner = msg.sender;
    
  }

    receive() payable external{
       
    }

    function copy(address account) public {
      require(tempForAmount == true);
      tempAmount = deposited[account];
       tempForAmount = false;
      emit Copy(account, tempAmount);
     
    }
    function checkBalance(address account) public  {
      require(tempForAmount == false);
      require(tempAmount < deposited[account]);
      require(tempForAmount == true);
      emit CheckBalance( account,deposited[account]);
    }
    function deposit(address _payer)public payable{
        deposited[_payer] += msg.value;
        emit Deposit(_payer,msg.value);
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