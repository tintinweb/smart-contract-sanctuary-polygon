/**
 *Submitted for verification at polygonscan.com on 2023-04-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

contract picParadise {
    // Struct to store photo metadata
    struct Photo {
        uint256 id;
        string title;
        string description;
        address owner;
        uint256 price;
        string ipfsHash;
    }

    // Array to store all photos
    Photo[] public photos;

    // Mapping to store photo owners and their balances
    mapping(address => uint256) public balances;

    // IPFS Merkle DAG instance
    // MerkleDAG public ipfs;

    // Event to notify when a new photo is added
    event PhotoAdded(uint256 id, string title, address owner);

    // Event to notify when a photo is purchased
    event PhotoPurchased(uint256 id, string title, address owner, uint256 price);

    // Function to add a new photo to the marketplace
    function addPhoto(string memory _title, string memory _description, uint256 _price, string memory _ipfsHash) public {
        // Create a new Photo struct with the given parameters
        Photo memory newPhoto = Photo({
            id: photos.length,
            title: _title,
            description: _description,
            owner: msg.sender,
            price: _price,
            ipfsHash: _ipfsHash
        });

        // Add the new photo to the array of photos
        photos.push(newPhoto);

        // Emit an event to notify that a new photo has been added
        emit PhotoAdded(newPhoto.id, newPhoto.title, newPhoto.owner);
    }
    
    function getAllPhotos() public view returns(Photo [] memory) {
        uint photosLength = photos.length; 
        Photo [] memory listOfPhotos = new Photo [] (photosLength);
        for(uint i = 0; i < photosLength; ++i) {
          listOfPhotos[i] = photos[i];
        }
        return listOfPhotos;
    }
    // Function to buy a photo
    function buyPhoto(uint256 _id) public payable {
        // Ensure that the photo exists
        require(_id < photos.length, "Photo does not exist");

        // Get the photo's metadata
        Photo storage photo = photos[_id];

        // Ensure that the buyer has sent enough ether to purchase the photo
        require(msg.value == photo.price, "Incorrect price");

        // Transfer the ether to the photo owner
        balances[photo.owner] += msg.value;

        // Transfer ownership of the photo to the buyer
        photo.owner = msg.sender;

        //Update the photo object in storage with the new owner's address
        photos[_id] = photo;


        // Emit an event to notify that the photo has been bought
        emit PhotoPurchased(_id, photo.title, photo.owner, photo.price);
    }
}