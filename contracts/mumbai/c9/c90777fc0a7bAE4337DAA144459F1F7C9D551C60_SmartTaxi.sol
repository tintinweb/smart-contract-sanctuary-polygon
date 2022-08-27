// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
// import "hardhat/console.sol";

contract SmartTaxi {
    uint public fee;
    address payable public owner;


    uint public counter;
    uint public platformBalance;

    struct Car {
        string model;
        string color;
        string number;
        uint year;
        uint rating;
        uint numOfRides;
        uint[] carRides;
    }

    struct Client {
        uint rating;
        uint numOfRides;
        uint[] clientRides;
    }

    mapping(uint => Ride) public rides;
    mapping(address => Car) public cars;
    mapping(address => Client) public clients;

    enum RideStatus {
        Initiated,
        Accepted,
        Arrived,
        Started,
        Completed,
        Evaluated,
        Rejected,
        Canceled
    }

    struct Ride {
        RideStatus status;
        string start;
        string dest;
        uint cost;
        address car;
        address client;
    }

    event PlaceRequest(address client, uint reqId, string start, string destination);
    event PlaceOffer(address car, uint reqId, uint cost, uint ttw);
    event RideInitiated(address car, uint rideId);
    event AcceptRide(address client, uint rideId);
    event Arrived(address client, uint rideId);
    event RideStarted(address client, uint rideId);
    event Completed(address car, uint rideId);
    event CancelRide(address initator, uint rideId, string reason);

    constructor(uint _fee) payable {
        fee = _fee;
        owner = payable(msg.sender);
    }

    function placeRequest(
        string memory start,
        string memory dest,
        /* can be hash of client address + start + dest */
        uint reqId
    ) public {
        emit PlaceRequest(msg.sender, reqId, start, dest);
    }

    function placeOffer(uint reqId, uint cost, uint ttw) public {
        require(cars[msg.sender].year != 0, "Car not registered");
        emit PlaceOffer(msg.sender, reqId, cost, ttw);
    }

    function initiateRide(
        address car,
        string memory start,
        string memory dest,
        uint cost
    ) public payable
    returns (uint) {
        counter = counter + 1;
        require(msg.value >= (cost + cost * fee / 100),
                "Not enough ether");

        /* what if the malicious client will initiate a ride even without an offer from a car? */
        Ride memory ride;
        ride.client = msg.sender;
        ride.car = car;
        ride.status = RideStatus.Initiated;
        ride.start = start;
        ride.dest = dest;
        ride.cost = cost;
        rides[counter] = ride;

        emit RideInitiated(car, counter);

        return counter;
    }

    function acceptRide(uint rideId) public {
        Ride storage ride = rides[rideId];
        require(msg.sender == ride.car,
                "Accept a ride can only a car specified");
        require(ride.status == RideStatus.Initiated,
                "The ride is not in the Initiated state");
        ride.status = RideStatus.Accepted;
        emit AcceptRide(ride.client, rideId);
    }

    function arrived(uint rideId) public {
        Ride storage ride = rides[rideId];
        require(msg.sender == ride.car,
                "Indicate arrival can only a car specified");
        require(ride.status == RideStatus.Accepted,
                "The ride is not in the Accepted state");
        ride.status = RideStatus.Arrived;
        emit Arrived(rides[rideId].client, rideId);
    }

    function startRide(uint rideId) public {
        Ride storage ride = rides[rideId];
        require(msg.sender == ride.client,
                "Start a ride can only a client specified");
        require(ride.status == RideStatus.Arrived,
                "The ride is not in the Arrived state");
        ride.status = RideStatus.Started;
        emit RideStarted(ride.client, rideId);
    }

    function completeRide(uint rideId, uint rate) public payable{
        Ride storage ride = rides[rideId];
        require(msg.sender == ride.client,
                "Complete a ride can only a client specified");
        require(ride.status == RideStatus.Started,
                "The ride is not in the Started state");
        ride.status = RideStatus.Completed;

        Car storage car = cars[ride.car];
        car.numOfRides = car.numOfRides + 1;
        car.rating = car.rating + rate;
        car.carRides.push(rideId);

        platformBalance += ride.cost * fee / 100;
        ride.cost += msg.value;

        emit Completed(ride.car, rideId);
    }

    function evaluateTheClient(uint rideId, uint rate) public payable {
        Ride storage ride = rides[rideId];
        require(ride.status == RideStatus.Completed,
                "The ride is not in the Completed state");
        require(ride.car == msg.sender,
                "Only carrier can withdraw money");
        ride.status = RideStatus.Evaluated;

        Client storage client = clients[ride.client];
        client.numOfRides = client.numOfRides + 1;
        client.rating = client.rating + rate;
        client.clientRides.push(rideId);

        (bool sent,) = payable(msg.sender).call{value: ride.cost}("");
        require(sent, "Failed to send Ether to carrier");
    }

    function cancelRide(uint rideId, string memory reason) public {
        Ride storage ride = rides[rideId];
        require((msg.sender == ride.client) ||
                (msg.sender == ride.car));
        ride.status = RideStatus.Canceled;
        emit CancelRide(msg.sender, rideId, reason);
        // unblock money
    }

    function withdraw() external payable {
        require(msg.sender == owner, "Only owner can withdraw ether");
        payable(msg.sender).transfer(platformBalance);
    }

    // required only because hardhat doesn't return arrays in a structure via direct access
    function getCar(address car) external view returns (Car memory){
        return cars[car];
    }

    function getClient(address client) external view returns (Client memory){
        return clients[client];
    }

    function registerCar(
        string memory model,
        string memory color,
        string memory number,
        uint year) external
    {
        /* Is it Ok to change car info? */
        Car storage car = cars[msg.sender];
        car.model = model;
        car.color = color;
        car.number = number;
        car.year = year;
    }
}