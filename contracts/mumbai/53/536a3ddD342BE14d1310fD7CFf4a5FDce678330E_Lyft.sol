/**
 *Submitted for verification at polygonscan.com on 2022-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


contract Lyft {

    enum State{
        IDLE,
        DRIVER_ASSIGNED, 
        COMPLETE,
        CANCELLED
    }

    struct Trip {
        address booker;
        address driver;
        uint256 priceAgreed;
        uint256 maxBidPrice;
        string pickupLocation;
        string dropLocation;
        State tripState;
        uint256 givenStars;
    }

    struct Driver {
        string name;
        string vehicle_no;
        uint256 credits;
        uint256 starsGained;
        bool banned;
    }

    struct Customer {
        string name;
        uint256 credits;
    }

    struct Bid {
        address bidder;
        uint256 amount;
    }

    mapping(bytes32 => Trip) public trips;
    mapping(address => bool) public driverState;
    mapping(address => Driver) public drivers;
    mapping(address => Customer) public customers;
    mapping(bytes32 => mapping(bytes32 => Bid)) public bids;

    event NewTrip(
        bytes32 tripID,
        address booker,
        uint256 maxBidPrice,
        string pickupLocation,
        string dropLocation,
        State tripState
    );

    event NewBid(
        bytes32 tripID,
        bytes32 bidID,
        address bidder,
        uint256 bid
    );

    event AcceptBid(
        bytes32 tripID,
        bytes32 bidID,
        uint256 _amount,
        address bidder
    );

    event StateChange(
        bytes32 tripID,
        State tripState,
        string reason
    );

    event NewCustomer(
        string name
    );

    event NewDriver(
        string name,
        string vehicle_no
    );


    function addCustomer(string memory name) public {

        Customer storage customer = customers[msg.sender];
        customer.name = name;
        
        emit NewCustomer(name);
    }

    function addDriver(
        string memory name,
        string memory vehicle_no
    ) public {

        Driver storage driver = drivers[msg.sender];

        driver.name = name;
        driver.vehicle_no = vehicle_no;

        emit NewDriver(name, vehicle_no);
    }

    function _initTrip(
        uint256 _maxBidPrice,
        string memory _pickupLocation,
        string memory _dropLocation       
    ) public {

        bytes32 tripID = keccak256(abi.encodePacked(
            msg.sender,
            block.timestamp,
            block.difficulty
        ));

        Trip storage trip = trips[tripID];

        trip.booker = msg.sender;
        trip.maxBidPrice = _maxBidPrice;
        trip.dropLocation = _dropLocation;
        trip.pickupLocation = _pickupLocation;
        trip.tripState = State.IDLE;

        emit NewTrip(
            tripID,
            msg.sender,
            _maxBidPrice,
            _pickupLocation,
            _dropLocation,
            State.IDLE
        );
    }

    function bidForTrip(bytes32 _tripID, uint256 _bid) public {
        
        bytes32 bidID = keccak256(abi.encodePacked(
            msg.sender,
            _tripID,
            block.timestamp,
            block.difficulty
        ));

        bids[_tripID][bidID] = Bid({
            bidder: msg.sender,
            amount: _bid
        });

        emit NewBid(_tripID, bidID, msg.sender, _bid);
    }

    function acceptBid(bytes32 _tripID, bytes32 _bidID) public {

        require(trips[_tripID].tripState == State.IDLE, "Trip bidding done");

        Bid storage _bid = bids[_tripID][_bidID];
        Trip storage _trip = trips[_tripID];

        customers[msg.sender].credits -= _bid.amount;
        drivers[_bid.bidder].credits += _bid.amount;

        _trip.tripState = State.DRIVER_ASSIGNED;

        _trip.driver = _bid.bidder;
        _trip.priceAgreed = _bid.amount;

        emit AcceptBid(_tripID, _bidID, _bid.amount, _bid.bidder);
    }

    function completeTrip(bytes32 _tripID) public {
        require(trips[_tripID].booker == msg.sender, "Not booker");

        trips[_tripID].tripState = State.COMPLETE;

        driverState[trips[_tripID].driver] = false;

        emit StateChange(_tripID, State.COMPLETE, "");
    }

    function addBalanceforuser(address user, uint256 balance) public {
        customers[user].credits += balance;
    }


    function addBalancefordriver(address user, uint256 balance) public {
        drivers[user].credits += balance;
    }
}