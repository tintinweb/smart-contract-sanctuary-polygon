/**
 *Submitted for verification at polygonscan.com on 2023-01-05
*/

// File: contracts/Donation.sol



pragma solidity >=0.7.0 <0.9.0;

contract Donation {
    address public owner;
    address[] public recipients;
    bool public autoDistribute;

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
        autoDistribute = true;

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

    function setAutoDistribute(bool _autoDistribute) public onlyOwner {
        autoDistribute = _autoDistribute;
    }

    function _setRecipients(address[] memory _recipients) private {
        require(_recipients.length > 0, "Must have recipients");

        recipients = _recipients;

        emit RecipientsChanged(msg.sender, recipients); // owner or factory
    }

    receive() external payable {
        emit DonationReceived(msg.sender, msg.value);

        // auto distribute if balance is >= 10 matic
        if (autoDistribute && address(this).balance >= 10 ether) {
            distribute();
        }
    }
}