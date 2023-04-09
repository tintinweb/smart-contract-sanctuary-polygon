/**
 *Submitted for verification at polygonscan.com on 2023-04-08
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract PaymentMandate {

    address private owner;
    uint private expiry = 2 minutes; // 1 day = 86400 sec
    mapping(address => transaction) public tnxID;
    address private zero_address;

    struct transaction {
        address payee;
        uint256 amt;
        uint256 startDate;
        bool status;
    }

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only Owner authorize to use this function");
        _;
    }

    function setExpiry(uint _expiry) public onlyOwner {
        expiry = getDays(_expiry);
    }

    function getExpiry() public view returns (uint) {
        return expiry;
    }

    function currentTime() public view returns (uint256){
        return block.timestamp;
    }

    function getMinutes(uint256 _min) public pure returns (uint256) {
        return _min * 60;
    }

    function getDays(uint256 _days) public pure returns (uint256) {
        return _days * 86400;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    receive() external payable {}

    function generateTnx(address _payee, uint _startDate) external payable onlyOwner {
        require(!tnxID[_payee].status, "Transaction already exits");
        uint256 stime = getMinutes(_startDate) + block.timestamp; // change to days before deploy to mainnet;
        require(stime > block.timestamp, "Date should be greater than current date");
        tnxID[_payee] = transaction(_payee, msg.value, stime, true);
        payable(address(this)).transfer(msg.value); // recieve callback here
    }

    function executeTnx() external {
        require(tnxID[msg.sender].payee == msg.sender, "You are not authorize to carry out this transaction");
        require(tnxID[msg.sender].status, "Transaction already executed");
        require(tnxID[msg.sender].startDate < block.timestamp, "Cannot execute early");
        require((tnxID[msg.sender].startDate + expiry) > block.timestamp, "Cannot Execute, Transaction Expire");
        payable(msg.sender).transfer(tnxID[msg.sender].amt); // this will debit address(this).balance
        tnxID[msg.sender] = transaction(zero_address, 0, 0, false);
    }

    function withdraw(address _payee) external onlyOwner {
        require(tnxID[_payee].status, "Transaction either executed or not initialized");
        require((tnxID[_payee].startDate + expiry) < block.timestamp, "Cannot Withdraw, Transaction is in active state");
        payable(msg.sender).transfer(tnxID[_payee].amt); // this will debit address(this).balance
        tnxID[_payee] = transaction(zero_address, 0, 0, false);
    }

    function getElapsetime(address _payee) public view returns(uint) {
        if(tnxID[_payee].startDate > block.timestamp) {
            return tnxID[_payee].startDate - block.timestamp;
        }
        else {
            return 0;
        }
    }

    function getTnxExpiry(address _payee) public view returns(uint) {
        if((tnxID[_payee].startDate + expiry) > block.timestamp) {
            return (tnxID[_payee].startDate + expiry) - block.timestamp;
        }
        else {
            return 0;
        }
    }
}