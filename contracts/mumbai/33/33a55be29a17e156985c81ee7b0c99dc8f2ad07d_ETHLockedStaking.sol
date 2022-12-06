/**
 *Submitted for verification at polygonscan.com on 2022-12-05
*/

pragma solidity ^0.5.0;

contract ETHLockedStaking {
address public owner;
mapping (address => uint256) public balances;
uint256 public totalSupply;
uint256 public APR;
uint256 public developerFee;
mapping (address => bool) public isReinvesting;
mapping (address => address) public referrer;

constructor() public {
owner = msg.sender;
APR = 1;
developerFee = 1;
}

function deposit(uint256 _amount) public payable {
require(msg.value == _amount, "Incorrect amount sent.");
balances[msg.sender] += _amount;
totalSupply += _amount;
APR *= 2;
}

function reinvest() public {
require(isReinvesting[msg.sender] == false, "Already reinvesting.");
isReinvesting[msg.sender] = true;
}

function withdraw() public {
require(isReinvesting[msg.sender] == false, "Cannot withdraw while reinvesting.");
uint256 amountToWithdraw = (balances[msg.sender] * APR) / 100;
balances[msg.sender] -= amountToWithdraw;
totalSupply -= amountToWithdraw;
msg.sender.transfer(amountToWithdraw);
APR /= 2;
}

function invite(address _referred) public {
require(referrer[_referred] == address(0), "Address has already been referred.");
referrer[_referred] = msg.sender;
}

function getReferrer(address _address) public view returns(address) {
return referrer[_address];
}

function() external payable {
require(msg.value > 0, "Must deposit a positive value.");
deposit(msg.value);
}
}