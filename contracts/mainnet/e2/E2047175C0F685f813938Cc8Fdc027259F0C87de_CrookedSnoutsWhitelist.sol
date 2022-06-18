//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract CrookedSnoutsWhitelist {

    uint16 public maxWhitelistedAddresses;
    uint16 public publicWhitelistSpots;
    uint16 public ownerWhitelistSpots;
    uint16 public publicSpotsTaken;
    uint16 public ownerSpotsTaken;

    uint256 public whitelistOpen;
    uint256 public whitelistClose;

    address public owner;

    mapping(address => bool) public whitelistedAddresses;


    constructor() {
        maxWhitelistedAddresses = 500;
        publicWhitelistSpots = 400;
        ownerWhitelistSpots = 100;
        whitelistOpen = block.timestamp + 3 days;
        whitelistClose = whitelistOpen + 21 days;
        owner = msg.sender;
    }

    function addAddressToWhitelist() public whitelistStart whitelistOpened {
        require(!whitelistedAddresses[msg.sender], "Sender is already whitelisted");
        require(publicSpotsTaken < publicWhitelistSpots, "Public whitelist spots limit reached");

        whitelistedAddresses[msg.sender] = true;
        publicSpotsTaken += 1;
    }

    function ownerAddAddressToWhitelist(address addressToAdd) public onlyOwner whitelistStart whitelistOpened {
        require(!whitelistedAddresses[addressToAdd], "Address is already whitelisted");
        require(ownerSpotsTaken < ownerWhitelistSpots, "Whitelisted addresses limit reached");

        whitelistedAddresses[addressToAdd] = true;
        ownerSpotsTaken += 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    modifier whitelistOpened() {
        require(block.timestamp <= whitelistClose, "Whitelist closed");
        _;
    }

    modifier whitelistStart() {
        require(block.timestamp >= whitelistOpen, "whitelist not started yet");
        _;
    }
}