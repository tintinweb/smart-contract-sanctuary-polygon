/**
 *Submitted for verification at polygonscan.com on 2022-04-01
*/

// contracts/Deal.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/* Basic concept with no comissions */
contract SmartDeal {

    enum State { Created, Started,/* Accepted,*/ Completed }
    struct Deal {
        State state;
        string description;
        address payable creator;
        uint price;
        address payable client;
    }

    uint64 nextId;
    mapping(uint64 => Deal) public deals;

    function create(string memory description, uint price) external returns (uint64) {
        deals[nextId] = Deal({
            state: State.Created,
            description: description,
            creator: payable(msg.sender),
            price: price,
            client: payable(address(0))
        });
        nextId++;
        return nextId-1;
    }

    function start(uint64 id) external payable {
        Deal storage deal = deals[id];
        require(deal.state == State.Created, 'Deal not available');
        require(msg.value == deal.price, 'Wrong amount');
        require(msg.sender != deal.creator, 'This deal is yours');
        deal.client = payable(msg.sender);
        deal.state = State.Started;
    }

    function del(uint64 id) external { // only by creator when
        require(deals[id].state == State.Created, 'State is not "Created"');
        require(msg.sender == deals[id].creator, "This deal isn't yours");
        delete deals[id];
    }

    /* For further adding Accepted(by creator) state */
    // function cancel(uint64 id) external { // only by client before accepting by creator
    //     require(deals[id].state == State.Started, 'State is not "Started"');
    //     require(msg.sender == deals[id].client, "You aren't client");
    //     deals[id].client.transfer(deals[id].price);
    //     deals[id].state = State.Created;
    // }

    /* When client has reseived and tested product */
    function complete(uint64 id) external {
        Deal storage deal = deals[id];
        require(deal.state == State.Started, 'State is not "Started"');
        require(msg.sender == deal.client, "You aren't client");
        deal.creator.transfer(deal.price);
        deal.state = State.Completed;
    }
}