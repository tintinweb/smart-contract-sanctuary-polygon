/**
 *Submitted for verification at polygonscan.com on 2022-07-28
*/

// File: contracts/AirbnBoat.sol


// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract AirbnBoat {

    address public owner;
    uint private counter;

    constructor() {
        owner = msg.sender;
        counter = 0;
    }


    struct rentalInfo {
        uint id;
        string name;
        string city;
        string lat;
        string long;
        string unoDescription;
        string dosDescription;
        string imgUrl;
        uint8 maxGuests;
        uint8 pricePerDay;
        string [] datesBooked;
        address renter;
    }


    event rentalCreated (
        uint id,
        string name,
        string city,
        string lat,
        string long,
        string unoDescription,
        string dosDescription,
        string imgUrl,
        uint8 maxGuests,
        uint8 pricePerDay,
        string [] datesBooked,
        address renter
    );

    event newDatesBooked (
         string[] datesBooked,
         uint id,
         address booker,
         string city,
         string imgUrl
    );

    mapping(uint => rentalInfo) rentals;
    uint[]  public rentalIds;


    function addRentals(
         string memory _name, 
         string memory  _city, 
         string memory _lat, 
         string memory _long, 
         string memory _unoDescription, 
         string memory _dosDescription, 
         string memory _imgUrl, 
         uint8 _maxGuests, 
         uint8 _pricePerDay,
         string[] memory _datesBooked
        )  public {
        require(msg.sender == owner, "Only the owner of the smart contract can put up rentals");

        rentalInfo storage newRental = rentals[counter];
        newRental.name = _name;
        newRental.city = _city;
        newRental.lat = _lat;
        newRental.long = _long;
        newRental.unoDescription = _unoDescription;
        newRental.dosDescription = _dosDescription;
        newRental.imgUrl = _imgUrl;
        newRental.maxGuests = _maxGuests;
        newRental.pricePerDay = _pricePerDay;
        newRental.datesBooked = _datesBooked;
        newRental.id = counter;
        newRental.renter = owner;

        rentalIds.push(counter);

        emit rentalCreated (counter, _name, _city, _lat, _long, _unoDescription, _dosDescription, _imgUrl, _maxGuests, _pricePerDay, _datesBooked, owner);

        counter++;
    }
 function checkBookings(uint256 _id, string[] memory _newBookings) private view returns (bool){
        
        for (uint i = 0; i < _newBookings.length; i++) {
            for (uint j = 0; j < rentals[_id].datesBooked.length; j++) {
                if (keccak256(abi.encodePacked(rentals[_id].datesBooked[j])) == keccak256(abi.encodePacked(_newBookings[i]))) {
                    return false;
                }
            }
        }
        return true;
    }

    function addDatesBooked (uint _id, string[] memory _newBookings) public payable {
        require(_id < counter, "Sorry, No such rental");
        require(checkBookings(_id, _newBookings), "Already booked for requested date");
        require(msg.value == (rentals[_id].pricePerDay * 1 ether * _newBookings.length), "Please submit the asking price in order to complete the purchase");

        for (uint i = 0; i < _newBookings.length; i++) {
            rentals[_id].datesBooked.push(_newBookings[i]);
        }

        payable(owner).transfer(msg.value);
        emit newDatesBooked(_newBookings, _id, msg.sender, rentals[_id].city, rentals[_id].imgUrl);

    }

    function getRental(uint _id) public view returns(string memory, uint, string[] memory){
        require(_id < counter, "No such rental");

        rentalInfo storage s = rentals[_id];
        return (s.name, s.pricePerDay, s.datesBooked);
    }

}