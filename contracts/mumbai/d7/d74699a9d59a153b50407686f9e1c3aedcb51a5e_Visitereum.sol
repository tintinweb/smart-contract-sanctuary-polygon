/**
 *Submitted for verification at polygonscan.com on 2022-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Visitereum {
    struct Place {
        //optional for users
        string userAddress;
        string description;
        string imageUrl;
        string latitude;
        string longitude;
        string typeOfPlace;
    }

    address[] Users;
    mapping(address => bool) private userExists;
    mapping(string => Place) private Places;
    mapping(address => string[]) private UserPlaces;

    event PlaceAdded(
        string userAddress,
        string description,
        string imageUrl,
        string latitude,
        string longitude,
        string typeOfPlace
    );

    //add place
    function addPlace(
        string memory _id,
        string memory _userAddress,
        string memory _description,
        string memory _imageUrl,
        string memory _latitude,
        string memory _longitude,
        string memory _typeOfPlace
    ) public returns (bool) {
        //check if user alrd exist
        if (!userExists[msg.sender]) {
            Users.push(msg.sender);
            userExists[msg.sender] = true;
        }

        Place memory _place;
        _place.userAddress = _userAddress;
        _place.description = _description;
        _place.imageUrl = _imageUrl;
        _place.latitude = _latitude;
        _place.longitude = _longitude;
        _place.typeOfPlace = _typeOfPlace;

        UserPlaces[msg.sender].push(_id);
        Places[_id] = _place;

        emit PlaceAdded(
            _userAddress,
            _description,
            _imageUrl,
            _latitude,
            _longitude,
            _typeOfPlace
        );
        return true;
    }

    //get all user address
    function getUsers() public view returns (address[] memory) {
        return Users;
    }

    function getUserPlaces(address _visiter)
        public
        view
        returns (string[] memory)
    {
        return UserPlaces[_visiter];
    }

    function getPlace(string memory _id) public view returns (Place memory) {
        return Places[_id];
    }
}