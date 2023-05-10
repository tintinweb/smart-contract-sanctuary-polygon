/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract Calculator {
    // Must Pausible/Unpausible
    // Ownable
    // Payable
    // Events

    bool private status;
    address payable immutable private owner;
    uint public fee;

    constructor(uint _fee) {
        owner = payable(msg.sender);
        fee = _fee;
    }

    modifier checkOwner() {
        require(msg.sender == owner, "You are not the owner!");
        _;
    }

    modifier checkStatus() {
        require(status != true, "The calculator is turned off");
        _;
    }

    modifier checkFee() {
        require(msg.value >= fee, "Please pay the right fee");
        owner.transfer(msg.value);
        _;
    }

    // msg.sender
    // msg.value

    event donateLog(address indexed sender, uint indexed val);

    function toDonate() public payable {   
        emit donateLog(msg.sender, msg.value);
    }

    function toDecideFee(uint _fee) public checkOwner {
        fee = _fee;
    }

    function transferBalancetoOwner() public checkOwner {
        owner.transfer(address(this).balance);
    }

    function checkBalance() public view returns(uint) {
        return address(this).balance;
    }

    function toPause() public {
        status = true;
    }

    function toUnpause() public {
        status = false;
    }

    function add(uint _x, uint _y) public payable checkStatus checkFee returns (uint) {
        owner.transfer(msg.value);
        return _x + _y;
    }

    function subtract(uint _x, uint _y) public payable checkStatus checkFee returns (uint) {
        owner.transfer(msg.value);
        return _x - _y;
    }

    function multiply(uint _x, uint _y) public payable checkStatus checkFee returns (uint) {
        owner.transfer(msg.value);
        return _x * _y;
    }

    function divide(uint _x, uint _y) public payable checkStatus checkFee returns (uint) {
        owner.transfer(msg.value);
        return _x / _y;
    }

}