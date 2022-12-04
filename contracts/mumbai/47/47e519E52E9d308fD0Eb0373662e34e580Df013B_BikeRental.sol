//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract BikeRental {
    address owner;
    uint256 ownerBalance;

    constructor () {
        owner = msg.sender;
    }

    /* Add a person as a renter with struct property */
    struct Renter {
        address walletAddress;
        string firstName;
        string lastName;
        bool canRent;
        bool active;
        uint256 balance;
        uint256 due;
        uint256 start;
        uint256 end;
    }

    mapping(address => Renter) public renters;

    modifier isRenter(address walletAddress) {
        require(msg.sender == walletAddress, "You can only manage your account");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are denied access to the function");
        _;
    }


    function addRenter (
        address walletAddress,
        string memory firstName,
        string memory lastName,
        bool canRent,
        bool active,
        uint256 balance,
        uint256 due,
        uint256 start,
        uint256 end 
        ) public isRenter(walletAddress) {
        renters[msg.sender] = Renter(
            walletAddress, 
            firstName, 
            lastName, 
            canRent, 
            active, 
            balance,
            due,
            start, 
            end
        );
    }

    /* Checkout a bike */

    function checkOut(address walletAddress) public isRenter(walletAddress) {
        require(renters[walletAddress].due == 0, "You have a pending balance");
        require(renters[walletAddress].canRent == true, "You cannot rent at this time");      
        renters[msg.sender].active = true;
        renters[msg.sender].start = block.timestamp;
        renters[msg.sender].canRent = false;
    }

    /* Checkin a bike */
    function checkIn(address walletAddress) public isRenter(walletAddress) {
        require(renters[walletAddress].active == true, "Please check out a bike first");
        renters[msg.sender].active = false;
        renters[msg.sender].end = block.timestamp;
        setDue(walletAddress);

    }


    /* Get total duration of bike used */
    function renterTimespan (uint start, uint end) public pure returns (uint256) {
        uint256 difference = end - start;
        return difference;
    }
    function getTotalDuration (address walletAddress) public isRenter(walletAddress) view returns (uint256) {
        if ( renters[walletAddress].start == 0 || renters[walletAddress].end == 0) {
            return 0;
        } else {
            uint256 timespan = renterTimespan(renters[walletAddress].start , renters[walletAddress].end);
            uint256 timespanInMinutes = timespan / 60;
            return timespanInMinutes;
        }
        
    }

    /* Get contract Balance */
    function balanceOf () public onlyOwner() view returns (uint256) {
        return address(this).balance;
    }

    function getOwnerBalance() public onlyOwner() view returns (uint256) {
        return ownerBalance;
    }

    function withdrawOwnerBalance() public payable {
        ownerBalance = 0;
        payable(owner).transfer(ownerBalance);      
    }

    /* Get renters Balance */
    function balanceOfRenter (address walletAddress) public isRenter(walletAddress) view returns (uint256) {
        return renters[walletAddress].balance;
    }

    /* Set due amount */
    function setDue ( address walletAddress) internal {
        uint256  timespanMinutes = getTotalDuration(walletAddress);
        uint256 oneMinuteIncrements = timespanMinutes / 1 ;
        renters[walletAddress].due = oneMinuteIncrements * 5000000000000000;
    }

    /* can Rent a Bike */
    function canRentBike (address walletAddress) public isRenter(walletAddress) view returns (bool) {
        return renters[walletAddress].canRent;
    }

    /* Deposit */
    function deposit (address walletAddress) payable public isRenter(walletAddress) {
        renters[walletAddress].balance += msg.value;       
    }

    /* make Payment */
    function makePayment (address walletAddress, uint amount) public isRenter(walletAddress) {
        require(renters[walletAddress].due > 0, "You don't have anything due this time");
        require(renters[walletAddress].balance > amount, "You do not have enough funds to cover payments. Please make a deposit");
        renters[walletAddress].balance -= amount;
        ownerBalance += amount;
        renters[walletAddress].canRent = true;
        renters[walletAddress].due = 0;
        renters[walletAddress].start = 0;
        renters[walletAddress].end = 0;
    }

    /* get Due balance */
    function getDue (address walletAddress) public isRenter(walletAddress) view returns (uint256) {
        return renters[walletAddress].due;
    }

    function getRenter (address walletAddress) public isRenter(walletAddress) view 
    returns (
        string memory firstName, 
        string memory lastName, 
        bool canRent, 
        bool active
    ) {
        firstName = renters[walletAddress].firstName;
        lastName = renters[walletAddress].lastName;
        canRent = renters[walletAddress].canRent;
        active = renters[walletAddress].active;
    }

    function renterExists (address walletAddress) public isRenter(walletAddress) view returns (bool) {
        if (renters[walletAddress].walletAddress != address(0)) {
            return true;
        }
        return false;
    }
}