// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract EventContract {

    struct Event{
      address organizer;
      string name;
      uint date;
      uint price;
      uint ticketCount;
      uint ticketRemain;
    }

    mapping(uint=>Event) public events;
    mapping(address=>mapping(uint=>uint)) public tickets;
    uint public nextId;

    function createEvent(string memory name,uint date,uint price,uint ticketCount) external{
      require(date>block.timestamp,"You can organize event only for future date");
      require(ticketCount>0,"You can organize event only if you create more than 0 tickets");
      events[nextId] = Event(msg.sender,name,date,price,ticketCount,ticketCount);
      nextId++;
    }


    function buyTicket(uint id,uint quantity) external payable{
      require(events[id].date!=0,"Event does not exist");
      require(events[id].date>block.timestamp,"Event has already occured");
      require(msg.value==(events[id].price*quantity),"Ethere is not enough");
      require(events[id].ticketRemain>=quantity,"Not enough tickets");
      events[id].ticketRemain-=quantity;
      tickets[msg.sender][id]+=quantity;
    }


    function transferTicket(uint id,uint quantity,address to) external{
      require(events[id].date!=0,"Event does not exist");
      require(events[id].date>block.timestamp,"Event has already occured");
      require(tickets[msg.sender][id]>=quantity,"You do not have enough tickets");
      tickets[msg.sender][id]-=quantity;
      tickets[to][id]+=quantity;
    }
}