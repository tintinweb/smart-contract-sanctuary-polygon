/**
 *Submitted for verification at polygonscan.com on 2022-03-04
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.4;

interface BEP20 {
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract FounderStake {
    
    address public owner;
    BEP20 public token;
    uint public time;
    address public claimAddress;
    address public claimTokenAddress = 0x64d524fC08317517fb1D1164676645B50FA557fD; // live token
    
    struct Claim{
        uint[] amounts;
        uint[] times;
        bool[] withdrawn;
    }
    
    mapping(address => Claim) claim;
    
    event Claimed(address user,uint amount, uint time);
    event Received(address, uint);
    event OwnershipTransferred(address to);
    
    constructor() {
        owner = msg.sender;
        claimAddress =  msg.sender;
        token = BEP20(claimTokenAddress);
        time = block.timestamp; 

        uint tokens = 90000000 * (10**18);
        uint claimAmount = tokens * 10 / 100;
        
        Claim storage clm = claim[claimAddress];

        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);
        clm.amounts.push(claimAmount);


        clm.times.push(time + 5 minutes);
        clm.times.push(time + 10 minutes);
        clm.times.push(time + 15 minutes);
        clm.times.push(time + 20 minutes);
        clm.times.push(time + 25 minutes);
        clm.times.push(time + 30 minutes);
        clm.times.push(time + 35 minutes);
        clm.times.push(time + 40 minutes);
        clm.times.push(time + 45 minutes);
        clm.times.push(time + 50 minutes);
       

        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        clm.withdrawn.push(false);
        
    }

    
    // Claim function
    function claimAll() public {
        address addr = msg.sender;
        uint len = claim[addr].amounts.length;
        uint amt = 0;
        for(uint i = 0; i < len; i++){
            if(block.timestamp > claim[addr].times[i] && claim[addr].withdrawn[i]==false) {
                amt += claim[addr].amounts[i];
            }
        }
        require(token.balanceOf(address(this)) >= amt, "Insufficient amount on contract");
        require(amt != 0, "Already claimed");
        token.transfer(addr, amt);
        for(uint i = 0; i < len; i++){
            if(block.timestamp > claim[addr].times[i]) {
               claim[addr].withdrawn[i] = true;
            }
        }
       
        emit Claimed(addr,amt, block.timestamp);
    }
    
    // View details
    function userDetails(address addr) public view returns (uint[] memory amounts, uint[] memory times, bool[] memory withdrawn) {
        uint len = claim[addr].amounts.length;
        amounts = new uint[](len);
        times = new uint[](len);
        withdrawn = new bool[](len);
        for(uint i = 0; i < len; i++){
            amounts[i] = claim[addr].amounts[i];
            times[i] = claim[addr].times[i];
            withdrawn[i] = claim[addr].withdrawn[i];
        }
        return (amounts, times, withdrawn);
    }
    

    
    // View details
    function userDetailsAll(address addr) public view returns (uint,uint,uint,uint) {
        uint len = claim[addr].amounts.length;
        uint totalAmount = 0;
        uint available = 0;
        uint withdrawn = 0;
        uint nextWithdrawnDate = 0;
        bool nextWithdrawnFound;
        for(uint i = 0; i < len; i++){
            totalAmount += claim[addr].amounts[i];
            if(claim[addr].withdrawn[i]==false){
                nextWithdrawnDate = (nextWithdrawnFound==false) ?  claim[addr].times[i] : nextWithdrawnDate;
                nextWithdrawnFound = true;
            }
            if(block.timestamp > claim[addr].times[i] && claim[addr].withdrawn[i]==false){
                available += claim[addr].amounts[i];
            }
            if(claim[addr].withdrawn[i]==true){
                withdrawn += claim[addr].amounts[i];
            }
        }
        return (totalAmount,available,withdrawn,nextWithdrawnDate);
    }
    
    // Get owner 
    function getOwner() public view returns (address) {
        return owner;
    }
 
    
    // transfer ownership
    function ownershipTransfer(address to) public {
        require(to != address(0), "Cannot set to zero address");
        require(msg.sender == owner, "Only owner");
        Claim storage clm = claim[owner];
        owner = to;
        claim[to] = clm;
        delete claim[msg.sender];
        
        emit OwnershipTransferred(to);
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
}