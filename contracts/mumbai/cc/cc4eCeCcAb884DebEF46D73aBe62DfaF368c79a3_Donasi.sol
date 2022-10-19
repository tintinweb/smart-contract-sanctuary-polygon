// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Donasi {
    address payable owner;
    address payable[] charityAddresses;
    uint256 totalDonationsAmount;
    uint256 highestDonation;
    address payable highestDonor;

    /// @param addresses_ The list of charity addresses to store in order to send donations to.
    constructor(address payable[] memory addresses_)  {
        owner = payable(msg.sender);
        charityAddresses = addresses_;
        totalDonationsAmount = 0;
        highestDonation = 0;
    }

    /// Restricts the access only to the user who deployed the contract.
    modifier restrictToOwner() {
        require(msg.sender == owner, 'Method available only to the to the user that deployed the contract');
        _;
    }

    /// Validates that the sender originated the transfer is different than the target destination.
    modifier validateDestination(address payable destinationAddress) {
        require(msg.sender != destinationAddress, 'Sender and recipient cannot be the same.');
        _;
    }

    //// Validates that the charity index number provided is a valid one.
    ///
    /// @param charityIndex The target charity index to validate. Indexes start from 0 and increment by 1.
    modifier validateCharity(uint256 charityIndex) {
        require(charityIndex <= charityAddresses.length - 1, 'Invalid charity index.');
        _;
    }

    /// Validates that the amount to transfer is not zero.
    modifier validateTransferAmount() {
        require(msg.value > 0, 'Transfer amount has to be greater than 0.');
        _;
    }

    /// Validates that the donated amount is within acceptable limits.
    ///
    /// @param donationAmount The target donation amount.
    /// @dev donated amount >= 1% of the total transferred amount and <= 50% of the total transferred amount.
    modifier validateDonationAmount(uint256 donationAmount) {
        require(donationAmount >= msg.value / 100 && donationAmount <= msg.value / 2,
            'Donation amount has to be from 1% to 50% of the total transferred amount');
        _;
    }

    /// Transmits the address of the donor and the amount donated.
    event Donation(
        address indexed _donor,
        uint256 _value
    );

    /// Redirects 10% of the total transferred funds to the target charity and transfers the rest to the target address.
    /// Whenever a transfer of funds is complete, it emits the event `Donation`.
    ///
    /// @param destinationAddress The target address to send fund to.
    /// @param charityIndex The target index of the charity to send the 10% of the funds.
    function deposit(address payable destinationAddress, uint256 charityIndex) public validateDestination(destinationAddress)
    validateTransferAmount() validateCharity(charityIndex) payable {
        uint256 donationAmount = msg.value / 10;
        uint256 actualDeposit = msg.value - donationAmount;

        charityAddresses[charityIndex].transfer(donationAmount);
        destinationAddress.transfer(actualDeposit);

        emit Donation(msg.sender, donationAmount);

        totalDonationsAmount += donationAmount;

        if (donationAmount > highestDonation) {
            highestDonation = donationAmount;
            highestDonor = payable(msg.sender);
        }
    }

    /// Redirects the specified amount to the target charity and transfers the rest to the target address.
    /// Whenever a transfer of funds is complete, it emits the event `Donation`.
    ///
    /// @param destinationAddress The target address to send fund to.
    /// @param charityIndex The target index of the charity to send the specified amount.
    /// @param donationAmount The amount to send to the target charity.
    function deposit(address payable destinationAddress, uint256 charityIndex, uint256 donationAmount) public
    validateDestination(destinationAddress) validateTransferAmount() validateCharity(charityIndex)
    validateDonationAmount(donationAmount) payable {
        uint256 actualDeposit = msg.value - donationAmount;

        charityAddresses[charityIndex].transfer(donationAmount);
        destinationAddress.transfer(actualDeposit);

        emit Donation(msg.sender, donationAmount);

        totalDonationsAmount += donationAmount;

        if (donationAmount > highestDonation) {
            highestDonation = donationAmount;
            highestDonor = payable(msg.sender);
        }
    }

    /// Returns all the available charity addresses.
    /// @return charityAddresses
    function getAddresses() public view returns (address payable[] memory) {
        return charityAddresses;
    }

    /// Returns the total amount raised by all donations (in wei) towards any charity.
    /// @return totalDonationsAmount
    function getTotalDonationsAmount() public view returns (uint256) {
        return totalDonationsAmount;
    }

    /// Returns the address that made the highest donation, along with the amount donated.
    /// @return (highestDonation, highestDonor)
    function getHighestDonation() public view restrictToOwner() returns (uint256, address payable)  {
        return (highestDonation, highestDonor);
    }

    // Destroys the contract and renders it unusable.
    function destroy() public restrictToOwner() {
        selfdestruct(owner);
    }
}