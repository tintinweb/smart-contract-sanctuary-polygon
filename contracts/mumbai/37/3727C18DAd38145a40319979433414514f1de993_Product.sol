// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Product {
    uint expirationTimestamp;
    string metadata;
    bool onShelf;
    address owner;

    constructor(uint _expirationTimestamp, string memory _metadata) {
        expirationTimestamp = _expirationTimestamp;
        metadata = _metadata;
        onShelf = true;
        owner = msg.sender;
    }

    modifier isOwner {
        require(msg.sender == owner, "Allowed only to owner");
        _;
    }

    modifier isFresh {
        require(block.timestamp < expirationTimestamp, "Product has expired");
        require(onShelf, "Product is not for sale");
        _;
    }

    function takeOffShelf() public isOwner {
        onShelf = false;
    }

    function transferOwnership(address reciever) public isOwner isFresh {
        owner = reciever;
    }

    function getExpirationTimestamp() public view returns (uint) {
        return expirationTimestamp;
    }

    function getMetadata() public view returns (string memory) {
        return metadata;
    }

    function getOnShelf() public view returns (bool) {
        return onShelf;
    }

    function getOwner() public view returns (address) {
        return owner;
    }
}