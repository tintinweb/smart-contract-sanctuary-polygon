/**
 *Submitted for verification at polygonscan.com on 2022-12-30
*/

// SPDX-License-Identifier: GPL-3.0

// File: contracts/Donation.sol



pragma solidity >=0.7.0 <0.9.0;

contract Donation {
    address public owner;
    address[] public recipients;

    event DonationReceived(address indexed from, uint indexed amount);
    event DonationDistributed(address[] indexed recipients, uint indexed amountPerRecipient);

    event OwnerChanged(address indexed newOwner);
    event RecipientsChanged(address indexed owner, address[] indexed recipients);

    modifier onlyOwner() {
        require(owner == msg.sender, "You are not the owner");
        _;
    }

    constructor(address _owner, address[] memory _recipients) {
        owner = _owner;

        _setRecipients(_recipients);
    }

    function distribute() public {
        uint amount = address(this).balance / recipients.length;

        for (uint i = 0; i < recipients.length; i += 1) {
            (bool success,) = recipients[i].call{value: amount}("");

            require(success);
        }

        emit DonationDistributed(recipients, amount);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;

        emit OwnerChanged(_newOwner);
    }

    function getRecipients() public view returns (address[] memory) {
        return recipients;
    }

    function setRecipients(address[] memory _recipients) public onlyOwner {
        _setRecipients(_recipients);
    }

    function _setRecipients(address[] memory _recipients) private {
        delete recipients; // reset array

        for (uint i = 0; i < _recipients.length; i += 1) {
            recipients.push(_recipients[i]);
        }

        emit RecipientsChanged(msg.sender, recipients); // owner or factory
    }

    receive() external payable {
        emit DonationReceived(msg.sender, msg.value);

        // auto distribute if balance is >= 5 ether/matic
        if (address(this).balance >= 5 ether) {
            distribute();
        }
    }
}
// File: contracts/DonationFactory.sol



pragma solidity >=0.7.0 <0.9.0;


contract DonationFactory {
    address public owner;
    address[] public donationAddresses;

    event DonationAddressCreated(address indexed contractAddress, address indexed owner);

    modifier onlyOwner() {
        require(owner == msg.sender, "You are not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createDonationAddress(address _owner, address[] memory _recipients) public {
        Donation donation = new Donation(_owner, _recipients);

        donationAddresses.push(address(donation));
        
        emit DonationAddressCreated(address(donation), _owner);
    }

    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function getAddresses() public view returns (address[] memory) {
        return donationAddresses;
    }
}