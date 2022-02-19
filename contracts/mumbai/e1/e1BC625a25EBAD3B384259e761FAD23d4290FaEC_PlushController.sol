// SPDX-License-Identifier: UNLISCENSED

pragma solidity ^0.8.2;

contract PlushController {
    mapping (address => uint) index;
    address[] withdrawalAddresses;
    address owner;

    constructor ()
    {
        owner = msg.sender;
    }

    modifier onlyOwner
    {
        require(msg.sender == owner, "PlushControllerError: Caller not owner");
        _;
    }

    function addNewWithdrawalAddress(address _withdrawalAddress) external onlyOwner
    {
        require(!withdrawalAddressExist(_withdrawalAddress), 'This address already exists.');

        index[_withdrawalAddress] = withdrawalAddresses.length + 1;
        withdrawalAddresses.push(_withdrawalAddress);
    }

    function withdrawalAddressExist(address _address) public view returns (bool)
    {
        if (index[_address] > 0) {
            return true;
        }

        return false;
    }

    function withdrawal() external
    {
        require(withdrawalAddressExist(msg.sender), 'Withdrawal is not available for this address.');
    }
}