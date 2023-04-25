// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract BunyBank {
    address owner;
    mapping(address => uint256) tokenBalances;
    string public ContractName = "Buny Bank v1";
    
    constructor() {
        owner = msg.sender;
    }
    
    function deposit() public payable {
    }
    
    receive() external payable {}


    function withdraw(uint amount) public {
        require(msg.sender == owner, "Only the owner can withdraw funds.");
        require(amount <= address(this).balance, "Insufficient balance.");
        payable(msg.sender).transfer(amount);
    }
    
    function withdrawTo(address payable recipient, uint amount) public {
        require(msg.sender == owner, "Only the owner can withdraw funds.");
        require(amount <= address(this).balance, "Insufficient balance.");
        recipient.transfer(amount);
    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function receive(address token, uint256 amount) public {
        require(msg.sender == token, "Only the token contract can call this function.");
        require(ERC20(token).transferFrom(msg.sender, address(this), amount), "Token transfer failed.");
        tokenBalances[token] += amount;
    }
    
    function getTokenBalance(address token) public view returns (uint256) {
        return ERC20(token).balanceOf(address(this));
    }
    
  
}