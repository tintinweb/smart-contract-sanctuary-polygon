/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
contract calculator { // from Sir Abhishek
    //Pauseable/Unpauseable
    //Ownable - Owner can only pause or unpause
    //Making functions payable, you need to pay at the time of using calculator
    //Events - Emit event when ever we will receive money
    //Whenever any user will use any functionality
    bool private paused;
    address payable immutable private owner;
    uint public fee;
    event DonationReceived(address indexed from, uint amount);
    constructor(uint _fee) {
        owner = payable(msg.sender);
        fee = _fee;
    }
    modifier checkOwner() {
        require(owner == msg.sender, "You are not the owner!");
        _;
    }
    modifier tocheckPaused() {
        require(paused != true, "Its Paused!");
        _;
    }
    function toDonate() public payable {
        emit DonationReceived(msg.sender, msg.value);
    }
    function toDecideFee(uint _fee) public checkOwner  {
        fee = _fee;
    }
    function transferBalanceToOwner() public checkOwner {
        owner.transfer(address(this).balance);
    }
    function checkBalance() public view returns(uint) {
        return address(this).balance;
    }
    function toPause() public checkOwner {
        paused = true;
    }
    function toUnpause() public checkOwner {
        paused = false;
    }
    function add(uint _x, uint _y) public payable tocheckPaused returns(uint) {
        require(fee <= msg.value, "You are not paying enough fees!");
        owner.transfer(msg.value);
        return _x + _y ;
    }
    function subtract(uint _x, uint _y) public payable tocheckPaused checkFee returns(uint) {
        return _x - _y;
    }
    function multiplication(uint _x, uint _y) public payable tocheckPaused checkFee returns(uint) {
        return _x*_y;
    }
    function division(uint _x, uint _y) public payable tocheckPaused checkFee returns(uint) {
        return _x/_y;
    }
    modifier checkFee() {
        require(msg.value >= fee, "Please pay the right fee");
        owner.transfer(msg.value);
        _;
    }
}