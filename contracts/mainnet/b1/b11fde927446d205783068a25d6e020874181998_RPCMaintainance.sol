/**
 *Submitted for verification at polygonscan.com on 2022-03-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract RPCMaintainance {

    mapping(address => uint256) public amount;
    uint256 public totalAmount;
    address public wallet;
    address public owner;
    uint256 public DEPOSITAMOUNT = 0;

    constructor(){
        owner = msg.sender;
        wallet = msg.sender;
    }

    modifier onlyOwner (){
        require(msg.sender == owner);
        _;
    }

    modifier onlyWallet (){
        require(msg.sender == wallet);
        _;
    }

    function setOwner(address _owner) external onlyOwner{
        require(owner != address(0), "invalid _owner");
        owner = _owner;
    }

    function setDepositAmount(uint256 _amount) external onlyOwner{
        DEPOSITAMOUNT = _amount;
    }

    function setWallet(address _wallet) external onlyOwner{
        require(owner != address(0), "invalid _wallet");
        wallet = _wallet;
    }

    function depositMaintenance() external payable {
        require(msg.value == DEPOSITAMOUNT, "Invalid Deposit");
        amount[msg.sender] += msg.value;
        totalAmount += msg.value;
    }

    function withdraw() external onlyWallet {   
        (bool sent, bytes memory data) = wallet.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

}