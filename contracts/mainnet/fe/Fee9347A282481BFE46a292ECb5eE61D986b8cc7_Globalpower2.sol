/**
 *Submitted for verification at polygonscan.com on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

contract Globalpower2 {
    address payable public owner;
    address payable public users;
    using SafeMath for uint256;

    constructor() {
        users = payable(msg.sender);
        owner = payable(msg.sender);
    }

    function setOwner(address payable _owner) public returns (bool) {
        require(msg.sender == users, "GlobalPower: unauthorized");
        require(_owner != address(0), "GlobalPower: zero address");
        owner = _owner;
        return true;
    }

    function setUsers(address payable _users) public returns (bool) {
        require(msg.sender == users, "GlobalPower: unauthorized");
        require(_users != address(0), "GlobalPower: zero address");
        users = _users;
        return true;
    }

function register(address payable address1, address payable address2, address payable[] memory receiverAddresses) public payable returns (bool) {
    require(msg.value > 10 , "GlobalPower: invalid amount");
    uint256 amountToSend = msg.value.mul(40).div(100);
    if (address1 != address(0) && address2 != address(0)) {
    address1.transfer(amountToSend);
    address2.transfer(amountToSend);
    uint256 remainingAmount = msg.value.sub(amountToSend.mul(2));
   distributeAmount(receiverAddresses, remainingAmount);
}
return true;
}

function distributeAmount(address payable[] memory receiverAddresses, uint256 remainingAmount) internal {
    require(receiverAddresses.length == 10, "GlobalPower: invalid receiver addresses");
    require(remainingAmount >= 4 , "GlobalPower: insufficient amount");

    uint256[] memory distribution = new uint256[](10);

    distribution[0] = 20;
    distribution[1] = 20;
    distribution[2] = 10;
    distribution[3] = 10;
    distribution[4] = 10;
    distribution[5] = 10;
    distribution[6] = 5;
    distribution[7] = 5;
    distribution[8] = 5;
    distribution[9] = 5;

    uint256 totalAmount = remainingAmount;

    for (uint256 i = 0; i < receiverAddresses.length; i++) {
        uint256 amountToSend = totalAmount * distribution[i] / 100;
        receiverAddresses[i].transfer(amountToSend);
    }
}

function upgrade(address payable address1) public payable returns (bool) {
    require(msg.value > 10 , "GlobalPower: invalid amount");
    uint256 amountToSend = msg.value;
    if (address1 != address(0)) {
    address1.transfer(amountToSend);
}
return true;
}


function boosting() public payable returns (bool) {
require(msg.value > 9 , "GlobalPower: invalid amount");
uint256 trc20or10 = msg.value;
if (trc20or10 > 9) {
owner.transfer(msg.value);
}
return true;
}

    function withdraw(address payable _to, uint256 _amount) public returns (bool) {
        require(msg.sender == users, "GlobalPower: unauthorized");
        require(_to != address(0), "GlobalPower: zero address");
        require(_amount > 0, "GlobalPower: invalid amount");
        require(_amount <= address(this).balance, "GlobalPower: insufficient balance");
        _to.transfer(_amount);
        return true;
    }

    function transfer() public returns (bool) {
        require(msg.sender == owner, "GlobalPower: unauthorized");
        uint256 totalAmount = address(this).balance;
        uint256 amountToSend = totalAmount.mul(4).div(10);
        uint256 sendonly = totalAmount.sub(amountToSend);
        require(amountToSend > 6 , "GlobalPower: insufficient balance");
        users.transfer(amountToSend);
        owner.transfer(sendonly);
        return true;
    }

    function deposit1() public payable returns (bool) {
require(msg.value > 0 , "GlobalPower: invalid amount");
return true;
}
}