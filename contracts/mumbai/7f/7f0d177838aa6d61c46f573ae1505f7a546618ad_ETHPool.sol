/**
 *Submitted for verification at polygonscan.com on 2022-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract ETHPool {
    mapping (address => uint256) public Balance;
    address[] public Deposers;
    address public owner;
    mapping (address => bool) public team;
    bool exist;
    bool  locked;
    modifier noReenter() {
        require(!locked,"No Rentrancy!!");
        locked = true;
        _;
        locked = false;
    }
    modifier onlyOwner(){
        require(msg.sender == owner,"Not a admin");
        _;
    }
    modifier onlyTeam(address addr){
        bool ex=team[addr];
        require(ex,"Not Team admin");
        _;
    }
    constructor () {
        owner = msg.sender;
        team[owner] = true;
    }
    
    fallback () external {

    }


    function getBalance(address addr) public view returns(uint256) {
        return Balance[addr];
    }

    function getDepLen() public view returns(uint) {
        return Deposers.length;
    }

    /// @notice Depositing `msg.sender` to the Pool
    function deposit() public payable {
        require(msg.value > 0,"None was Deposite!");
        Balance[msg.sender] += msg.value;
        bool ex = false;
        for (uint i=0; i < Deposers.length; i++){
            if(msg.sender == Deposers[i]) {ex = true;}
        }
        if(!ex) Deposers.push(msg.sender);
    }
    
    /// @notice Depositing `amount` to the Pool
    function withdraw(uint inWei) public payable noReenter {
        require(inWei <= Balance[msg.sender],"Don't have the amount");
        Balance[msg.sender] -= inWei;

        (bool os, ) = payable(msg.sender).call{value: inWei}("");
            require(os);
    }

    function addTeam(address addrs) public onlyTeam(msg.sender){
        bool ex=team[addrs];
        require(!ex,"Already in the team");
        team[addrs] = true;
        ex = false;
    }

    function getContactBalance() public view returns(uint) {
        return address(this).balance / (10**18);
    }

    function addBonus() public payable onlyTeam(msg.sender) returns(uint) {
        uint amount = msg.value;
        uint total = address(this).balance - amount;
        uint share;
        uint test;
        for(uint i=0; i < Deposers.length; i++) {
            share = (Balance[Deposers[i]]*100 / total);
            Balance[Deposers[i]] += (amount*share)/100;
            test += Balance[Deposers[i]];
        }
        return test;
    }
}