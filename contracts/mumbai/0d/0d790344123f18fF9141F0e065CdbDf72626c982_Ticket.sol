// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Ticket {
    uint256 public minValue;
    address public owner;
    mapping(address => uint) public favNum;
    mapping(address => uint) public balance;

    event SetFavNumber(uint256 indexed num, address user);
    event Deposited(uint256 indexed amount, address depositor);
    event Withdrawal(uint amount);

    constructor(uint val) {
        minValue = val;
        owner = msg.sender;
    }

    function setNum(uint num) public {
        require(balance[msg.sender] >= minValue, "Not enough Eth");
        favNum[msg.sender] = num;
    }

    function deposit() public payable {
        balance[msg.sender] = msg.value;
        emit Deposited(msg.value, msg.sender);
    }

    function withdraw() external returns (uint256 amount) {
        amount = address(this).balance;
        payable(owner).transfer(amount);
        emit Withdrawal(amount);
    }
}