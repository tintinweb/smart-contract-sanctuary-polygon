/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Calculatorr {

    bool private paused;
    address payable immutable private owner;
    uint public fee;

    constructor(uint _fee) {
        owner = payable(msg.sender);
        fee = _fee;
    }

    modifier checkOwner() {
        require(msg.sender == owner, "You are not the owner.");
        _;
    }

    event DonationReceived(address indexed from, uint amount);

    modifier toCheckPaused() {
        require(paused != true, "Its paused.");
        _;
    }

    function toPaused() public checkOwner {
        paused = true;
    }

    function toUnPaused() public  checkOwner  {
        paused = false;
    }

    function toDonate() public payable {
        emit DonationReceived(msg.sender, msg.value);
    }

    function checkBalance() public view returns(uint) {
        return address(this).balance;
    }

    function transferFunds() public checkOwner{
        owner.transfer(address(this).balance);
    }

    function toDecideFee(uint _fee) public checkOwner {
        fee = _fee;
    }

    function add(uint _x, uint _y) public payable toCheckPaused returns(uint){
        require(msg.value >= fee, "Insufficient fee amount");
        return _x + _y;
    }

    function subtract (uint _x, uint _y) public payable toCheckPaused checkFee returns(uint) {
        return _x - _y;
    }

    function multiplication (uint _x, uint _y) public payable toCheckPaused checkFee returns(uint) {
        return _x * _y;
    }

    function division (uint _x, uint _y) public payable toCheckPaused checkFee returns(uint) {
        return _x / _y;
    }

    modifier checkFee() {
        require(msg.value >= fee, "Please pay the right fee");
        owner.transfer(msg.value);
        _;
    }
}