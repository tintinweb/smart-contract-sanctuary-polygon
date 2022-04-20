/**
 *Submitted for verification at polygonscan.com on 2022-04-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Distribution {
    address public owner;
    uint public claimAmount;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public transferred;
    mapping(address => uint) public failedCredits;

    constructor() {
        owner = msg.sender;
        whitelist[msg.sender] = true;
        claimAmount = 1 ether;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier isWhitelisted(address _address) {
        require(whitelist[_address], "User not whitelisted");
        _;
    }

    function whitelistUser(address user) public onlyOwner {
        whitelist[user] = true;
    }

    function claimMatic(address _to) public isWhitelisted(msg.sender) {
        require(!transferred[_to], "Already claimed");
        require(address(this).balance >= claimAmount, "Insufficient amount on contract");

        (bool sent, ) = payable(_to).call{value: claimAmount}("");

        if(!sent){
            failedCredits[_to] = claimAmount;
        }
    }

    function withdrawFailedCredits() public {
        require(failedCredits[msg.sender] != 0, "No amount to withdraw");
        payable(msg.sender).transfer(claimAmount);
    }

    function withdrawMatic(uint amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient amount on contract");
        payable(msg.sender).transfer(amount);
    }

    function changeClaimAmount(uint _claimAmount) public onlyOwner {
        require(_claimAmount != 0, "Cannot set to zero");
        claimAmount = _claimAmount;
    }

    function changeOwnership(address _owner) public onlyOwner {
        require(_owner != address(0), "Cannot set to zero address");
        owner = _owner;
    }


}