// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract Market {

    event NewListing(uint listingId, string name, string category, string description, string image_id, uint price_in_wei);
    event BoughtListing(uint listingId, uint price_in_wei, bool available);

    struct Listing {
        string name;
        string description;
        string image_id;
        string category;
        uint price_in_wei;
        bool available;
    }

    Listing[] public listings;

    mapping (uint => address) public listingToOwner;
    mapping (address => uint) ownerListingCount;

    function getListingCount() public view returns(uint) {
        return listings.length;
    }

    function createListing(
        string memory _name,
        string memory _description,
        string memory _image_id,
        string memory _category,
        uint  _price_in_wei
    ) public {
        listings.push(Listing(_name, _description, _category, _image_id, _price_in_wei, true));
        uint _id = listings.length - 1;
        listingToOwner[_id] = msg.sender;
        ownerListingCount[msg.sender]++;
        emit NewListing(_id, _name, _description, _category, _image_id, _price_in_wei);
    }

    function getListingName(uint _id) external view returns(string memory) {
        return(listings[_id].name);
    }

    function getListingDescription(uint _id) external view returns(string memory) {
        return(listings[_id].description);
    }

    function getListingImageId(uint _id) external view returns(string memory) {
        return(listings[_id].image_id);
    }

    function getListingPrice(uint _id) external view returns(uint) {
        return(listings[_id].price_in_wei);
    }

    function getListingAvailability(uint _id) external view returns(bool) {
        return(listings[_id].available);
    }

    function getListingOwnerById(uint _id) external view returns(address) {
        return(listingToOwner[_id]);
    }

    function buyListing(address payable _to, uint _id) public payable {
        // Does this transfer the right amount of ether (msg.value measured in wei)?
        require(msg.value == listings[_id].price_in_wei && listings[_id].available == true);
        listings[_id].available = false;
        emit BoughtListing(_id, msg.value, false);

        _to.transfer(msg.value);

    }
}