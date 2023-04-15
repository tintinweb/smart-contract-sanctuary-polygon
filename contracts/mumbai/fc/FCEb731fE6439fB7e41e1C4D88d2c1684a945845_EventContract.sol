// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract EventContract {

    struct Event{
      uint256 tokenId;
      address payable organizer;
      string name;
      uint256 date;
      uint256 price;
      uint256 ticketCount;
      uint256 ticketRemain;
    }

    mapping(uint256=>Event) public events;
    mapping(address=>mapping(uint256=>uint256)) public tickets;
    uint256 public nextId=0;

    function createEvent(string memory name,uint256 date,uint256 price,uint256 ticketCount) external{
      require(date>block.timestamp,"You can organize event only for future date");
      require(ticketCount>0,"You can organize event only if you create more than 0 tickets");
      events[nextId] = Event(nextId,payable(msg.sender),name,date,price,ticketCount,ticketCount);
      nextId++;
    }


    function buyTicket(uint256 id,uint256 quantity) external payable{
      require(events[id].date!=0,"Event does not exist");
      require(events[id].date>block.timestamp,"Event has already occured");
      require(msg.value==(events[id].price*quantity),"Ethere is not enough");
      require(events[id].ticketRemain>=quantity,"Not enough tickets");
      events[id].ticketRemain-=quantity;
      tickets[msg.sender][id]+=quantity;
      payable(events[id].organizer).transfer(msg.value);
    }


    function transferTicket(uint256 id,uint256 quantity,address to) external{
      require(events[id].date!=0,"Event does not exist");
      require(events[id].date>block.timestamp,"Event has already occured");
      require(tickets[msg.sender][id]>=quantity,"You do not have enough tickets");
      tickets[msg.sender][id]-=quantity;
      tickets[to][id]+=quantity;
    }

    //This will return all the events
    function getAllEvents() public view returns (Event[] memory) {
        Event[] memory allEvents = new Event[](nextId);
        uint256 currentIndex = 0;

        for(uint256 i=0;i<nextId;i++)
        {
            Event storage currentItem = events[i];
            allEvents[currentIndex] = currentItem;
            currentIndex += 1;
        }
        return allEvents;
    }

    //Returns all the Event that the current user is owner
    function getMyEvents() public view returns (Event[] memory) {
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        //Important to get a count of all the Event that belong to the user before we can make an array for them
        for(uint256 i=0;i<nextId;i++)
        {
            if(events[i].organizer == msg.sender){
                itemCount += 1;
            }
        }
        //Once you have the count of relevant Event, create an array then store all the Event in it
        Event[] memory myEvents = new Event[](itemCount);
        for(uint256 i=0;i<nextId;i++) {
            if(events[i].organizer == msg.sender) {
                Event storage currentItem = events[i];
                myEvents[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return myEvents;
    }

}