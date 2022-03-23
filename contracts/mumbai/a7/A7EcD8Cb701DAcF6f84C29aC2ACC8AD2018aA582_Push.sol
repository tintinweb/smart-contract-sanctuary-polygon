/**
 *Submitted for verification at polygonscan.com on 2022-03-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Push {

    address payable private owner;
    uint256 private toPay;
    uint256 private round;
    mapping(uint256 => mapping(address => uint256)) private deposits;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor() {
        owner = payable(msg.sender);
        round = 0;
        toPay = 0;
        emit OwnerSet(address(0), owner);
    }

    function deposit() external payable{
        deposits[round][msg.sender] += msg.value;
        toPay += (msg.value * 9 ) / 10;
    }
    function payWinner(address payable winner) external isOwner {
        require(deposits[round][winner] > 0);
        winner.transfer(toPay);
        owner.transfer(address(this).balance);
        toPay = 0;
        round += 1;
    }
    function changeOwner(address payable newOwner) external isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }



    function getRound() view external returns(uint256){
        return round;
    }
    function getToPay() view external returns(uint256){
        return toPay;
    }
    function getDeposit() view external returns(uint256){
        return deposits[round][msg.sender];
    }
}