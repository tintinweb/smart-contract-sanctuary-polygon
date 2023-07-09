/**
 *Submitted for verification at polygonscan.com on 2023-07-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract DonationContract {
    address public owner;
    mapping (string => mapping(address => bool)) public registeredNGOs;
    mapping (string => address[]) public registeredNGOAddresses;
    mapping (string => uint256) public domainBalance;
    uint256 public domainDonationThreshold = 1;
    event DonationReceived(string indexed domain, address indexed donor, uint256 amount);
    event NGORegistered(string indexed domain, address indexed ngoAddress);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action");
        _;
    }

    function donate(string memory domain) public payable {
        require(msg.value > 0, "Donation amount must be greater than zero");

        domainBalance[domain] += msg.value;
        emit DonationReceived(domain, msg.sender, msg.value);

        if (domainBalance[domain] >= domainDonationThreshold) {
            distributeDonationsToNGOs(domain);
        }
    }

    function registerNGO(string memory domain, address ngoAddress) public onlyOwner {
        require(!registeredNGOs[domain][ngoAddress], "NGO address is already registered");

        registeredNGOs[domain][ngoAddress] = true;
        registeredNGOAddresses[domain].push(ngoAddress);
        emit NGORegistered(domain, ngoAddress);
    }

    function distributeDonationsToNGOs(string memory domain) private {
        uint256 balance = domainBalance[domain];
        require(balance > 0, "No funds available for donation");

        uint256 donationAmount = balance / registeredNGOAddresses[domain].length;

        for (uint256 i = 0; i < registeredNGOAddresses[domain].length; i++) {
            address ngoAddress = registeredNGOAddresses[domain][i];
            (bool success, ) = ngoAddress.call{value: donationAmount}("");
            require(success, "Failed to distribute donation to NGO");

            domainBalance[domain] -= donationAmount;
            if (domainBalance[domain] < domainDonationThreshold) {
                break;
            }
        }
    }
}