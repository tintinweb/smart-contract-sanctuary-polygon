//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract QTMarket {
     address payable owner;
     uint256 private counter;

    constructor() {
        owner = payable(msg.sender);
        counter = 0;
    }

    struct RealestateInfo {
        uint256 itemId;
        string title;
        uint256 pricePerDay;
        string imageURL;
        uint256 maxGuests;
        string addressRs;
        string[] datesBooked;
        address payable renter;
    }

    //event for user create real estate
    event realEstateCreated(
        uint256 itemId,
        string title,
        uint256 pricePerDay,
        string imageURL,
        uint256 maxGuests,
        string addressRs,
        string[] datesBooked,
        address renter
    );

    // event for user booking real estate
    event newDatesBooked(
        uint256 itemId,
        string imageURL,
        string addressRs,   
        string[] datesBooked,
        address renter
    );

    mapping(uint256 => RealestateInfo) idToRealEstateInfo;
    uint256[] public realEstateIds;

    function createRealEstate(
        string memory title, 
        uint256 pricePerDay, 
        string memory imageURL,
        uint256 maxGuests,
        string memory addressRs,
        string[] memory datesBooked
        ) 
    public payable{ 
        require(pricePerDay > 0, "Price must be at least one ether.");
        require(msg.sender == owner, "Only owner of smart contract can put up rentals.");

        RealestateInfo storage newRealEstate = idToRealEstateInfo[counter];
        newRealEstate.title = title;
        newRealEstate.pricePerDay = pricePerDay;
        newRealEstate.imageURL = imageURL;
        newRealEstate.maxGuests = maxGuests;
        newRealEstate.addressRs = addressRs;
        newRealEstate.datesBooked = datesBooked;
        newRealEstate.itemId = counter;
        newRealEstate.renter = owner;
        realEstateIds.push(counter);
        emit realEstateCreated(counter, title, pricePerDay, imageURL, maxGuests, addressRs, datesBooked, owner);
        counter++;
    }

    //Check day booking
    function checkBooking(uint256 id, string[] memory newBookings) private view returns (bool) {
        for(uint256 i = 0; i < newBookings.length; i++) {
            for(uint256 j = 0 ; j < idToRealEstateInfo[id].datesBooked.length; j++){
                if(keccak256(abi.encodePacked(idToRealEstateInfo[id].datesBooked[j])) == keccak256(abi.encodePacked(newBookings[j])) ){
                    return false;
                }
            }
        }
        return true;
    }

    function addDatesBooked(uint256 id, string[] memory newBookings) public payable {
        require(id < counter, "No one rental.");
        require(checkBooking(id, newBookings), "Already booked");
        require(msg.value == (idToRealEstateInfo[id].pricePerDay * 1 ether * newBookings.length), "Please submit the asking price in order to complete the purchase");

        for(uint256 i = 0; i < newBookings.length; i++) {
            idToRealEstateInfo[id].datesBooked.push(newBookings[i]);
        }

        payable(owner).transfer(msg.value);
        emit newDatesBooked(id, idToRealEstateInfo[id].imageURL, idToRealEstateInfo[id].addressRs, newBookings, msg.sender);
    }

    function fetchRealEstateRental(uint256 id) public view returns (string memory, uint256, string[] memory) {
        require(id < counter, "No one rental");
        RealestateInfo storage s = idToRealEstateInfo[id];
        return (s.title, s.pricePerDay, s.datesBooked);
    }
    
}