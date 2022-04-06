/**
 *Submitted for verification at polygonscan.com on 2022-04-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract popWallet {
    
    uint256 internal _satoshiTotal = 0;
    
    uint256 internal _satoshiIn = 0;
    
    uint256 internal _satoshiOut = 0;
    
    uint256 internal totalHolders = 0;

    address internal Moderator;
    
    struct account {
        uint256 amount;
        bool exsist;
    }

    mapping(string => account) internal accounts;
    mapping(uint256 => string) internal holders;
    // Contract name
    string public name = "POP Wallet";
    // Contract symbol
    string public symbol = "POPW";
    
    event satohiIn(string btcAddr, uint256 amount);
    event withdrawal(string btcAddr, uint256 amount);
    event Transfer(string from, string to, uint256 amount);

    constructor() {
        Moderator = msg.sender;
    }
    
    function addSatoshi(string memory btcAddr, uint256 amount) public onlyModerator {
        _satoshiIn += amount;
        _satoshiTotal += amount;
        if(accounts[btcAddr].exsist){
            accounts[btcAddr].amount += amount;
        } else {
            totalHolders += 1;
            holders[totalHolders] = btcAddr;
            accounts[btcAddr] = account(amount, true);
        }
        emit satohiIn(btcAddr, amount);
    }

    function withdrawSatoshi(string memory btcAddr, uint256 amount) public onlyModerator {
        require(accounts[btcAddr].amount >= amount,"Insufficient Satoshi in balance");
        _satoshiOut += amount;
        _satoshiTotal -= amount;
        accounts[btcAddr].amount -= amount;
        emit withdrawal(btcAddr, amount);
    }

    function transferSatoshi(string memory from, string memory to, uint256 amount) public onlyModerator {
        require(accounts[from].amount >= amount,"Insufficient Satoshi in balance");
        accounts[from].amount -= amount;
        if(accounts[to].exsist){
            accounts[to].amount += amount;
        } else {
            totalHolders += 1;
            holders[totalHolders] = to;
            accounts[to] = account(amount, true);
        }
        emit Transfer(from, to, amount);
    }

    function satoshiTotal() public view returns(uint256) {
        return _satoshiTotal;
    }

    function satoshi_In() public view returns(uint256) {
        return _satoshiIn;
    }

    function satoshi_Out() public view returns(uint256) {
        return _satoshiOut;
    }

    function satoshiBalance(string memory btcAddr) public view returns(uint256) {
        return accounts[btcAddr].amount;
    }

    function holder(uint256 index) public view onlyModerator returns(string memory) {
        return holders[index];
    }

    function withdraw() public payable onlyModerator{
        require(payable(msg.sender).send(address(this).balance));
    }

    modifier onlyModerator {
        require(msg.sender == Moderator, "Only Moderator function");
        _;
    }

}