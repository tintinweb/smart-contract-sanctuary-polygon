/**
 *Submitted for verification at polygonscan.com on 2022-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Visitereum {
    struct Place {
        string userAddress;
        string description;
        string imageUrl;
        string latitude;
        string longitude;
        string typeOfPlace;
    }
    struct User {
        string cid;
        bool isCid;
    }
    // Array of address of all users
    address[] private Users;

    // Mapping of Unique ID of place with its data
    mapping(string => Place) private Places;

    // Mapping of array of Unique IDs of places with User's address
    mapping(address => string[]) private UserPlaces;

    // Mapping of user address with cid
    mapping(address => User) private UsersData;

    event PlaceAdded(
        string userAddress,
        string description,
        string imageUrl,
        string latitude,
        string longitude,
        string typeOfPlace
    );

    //Check if CID exists
    function isUser(address userAddress) public view returns (bool) {
        return UsersData[userAddress].isCid;
    }

    //Add User
    function addUser(address _Address, string memory _cid)
        public
        returns (bool)
    {
        require(!isUser(msg.sender), "User exists");
        Users.push(_Address);
        UsersData[_Address] = User({cid: _cid, isCid: true});
        return true;
    }

    //Add place
    function addPlace(
        string memory _id,
        string memory _userAddress,
        string memory _description,
        string memory _imageUrl,
        string memory _latitude,
        string memory _longitude,
        string memory _typeOfPlace
    ) public returns (bool) {
        //check if user does not exist
        require(isUser(msg.sender), "User does not exists");
        Place memory _place = Place({
            userAddress: _userAddress,
            description: _description,
            imageUrl: _imageUrl,
            latitude: _latitude,
            longitude: _longitude,
            typeOfPlace: _typeOfPlace
        });

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
    // Get user cid from address
    function getUserCid(address _Address) public view returns (string memory){
        return UsersData[_Address].cid;
    }

    //Get array of all user addresses
    function getUsers() public view returns (address[] memory) {
        return Users;
    }

    // Get ids of places by user address
    function getUserPlaces(address _visiter)
        public
        view
        returns (string[] memory)
    {
        return UserPlaces[_visiter];
    }

    // Get single place
    function getPlace(string memory _id) public view returns (Place memory) {
        return Places[_id];
    }
}