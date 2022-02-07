/**
 *Submitted for verification at polygonscan.com on 2022-02-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract TokenComrade{

    // GLobal Variables
    address payable owner;
    uint numEvents;
    bool fundPulled;

    struct Holder {
        address wallet;
        uint inventory;
    }
        
    struct Event{
        address payable organizer;
        string name;
        uint initialSupply;
        uint supply;
        uint price; //wei
        bool soldOut;
        uint256 redeemableBalance;
        mapping(address => bool) scanners; // stores boolean to check whether an address is an approved scanner.
    }

    mapping(address => Holder) holders;
    mapping (uint => Event) events;

    constructor(){
        owner = payable(msg.sender);
    }
    
    
    function createEvent(uint _supply, string memory _name, uint _price) external payable returns (uint eventID){
        eventID = numEvents++;
        Event storage e = events[eventID];
        e.initialSupply = _supply;
        e.supply = _supply;
        e.name = _name;
        e.price = _price*10**18;
        e.organizer = payable(msg.sender);
        e.soldOut = false;
        e.redeemableBalance = 0;
        return (eventID);
    }
    
    function mint(uint eventID, uint _quantity) external payable{
        Event storage e = events[eventID];
        require(msg.value >= e.price, "incorrect value");
        require(e.supply >= _quantity, "Not Enough Supply");
        address holderID = msg.sender;
        Holder storage h = holders[holderID];
        e.supply -= _quantity;
        h.inventory += _quantity;
        h.wallet = msg.sender;
        if(e.supply == 0){
            sellOut(eventID);
        }
    }

    function scan(uint eventID, address _holderID, uint _quantity) external {
        Event storage e = events[eventID];
        Holder storage h = holders[_holderID];
        require(e.scanners[msg.sender], "You are not an approved scanner");
        require(h.inventory >= _quantity, "Not enough tokens");
        h.inventory -= _quantity;
        e.redeemableBalance += (_quantity * e.price);
    }

    function approveScanner(address _scanner, uint eventID) public{
        Event storage e = events[eventID];
        require(e.organizer == msg.sender);
        e.scanners[_scanner] = true;
    }

    function removeScanner(address _scanner, uint eventID) public{
        Event storage e = events[eventID];
        require(e.organizer == msg.sender);
        e.scanners[_scanner] = false;
    }

    function sellOut(uint eventID) internal {
        Event storage e = events[eventID];
        e.soldOut = true;
    }

    function pullFunds(uint eventID) external {
        Event storage e = events[eventID];
        require(msg.sender == e.organizer, "Only the organizer can Redeem funds");
        require(e.redeemableBalance>0);
        e.organizer.transfer(e.redeemableBalance);
        e.redeemableBalance = 0;
    }

}