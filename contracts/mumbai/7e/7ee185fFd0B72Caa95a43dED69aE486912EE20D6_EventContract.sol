// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract EventContract {

    struct Event{
      uint256 tokenId;
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
      events[nextId] = Event(nextId,msg.sender,name,date,price,ticketCount,ticketCount);
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

    //This will return all the events
    function getAllEvents() public view returns (Event[] memory) {
        Event[] memory allEvents = new Event[](nextId);
        uint currentIndex = 0;

        for(uint i=0;i<nextId;i++)
        {
            uint currentId = i + 1;
            Event storage currentItem = events[currentId];
            allEvents[currentIndex] = currentItem;
            currentIndex += 1;
        }
        return allEvents;
    }

    //Returns all the Event that the current user is owner
    function getMyEvents() public view returns (Event[] memory) {
        uint totalItemCount = nextId;
        uint itemCount = 0;
        uint currentIndex = 0;
        
        //Important to get a count of all the Event that belong to the user before we can make an array for them
        for(uint i=0; i < totalItemCount; i++)
        {
            if(events[i+1].organizer == msg.sender){
                itemCount += 1;
            }
        }

        //Once you have the count of relevant Event, create an array then store all the Event in it
        Event[] memory myEvents = new Event[](itemCount);
        for(uint i=0; i < totalItemCount; i++) {
            if(events[i+1].organizer == msg.sender) {
                uint currentId = i+1;
                Event storage currentItem = events[currentId];
                myEvents[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return myEvents;
    }

}