// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract WhitelistNFT {

    bool whitelistEnabled;

    mapping(address => bool) adminAddresses;

    mapping(address => bool) whitelistedAddresses;

    constructor() {
        adminAddresses[0x2Fcb0D87605F054CF8df0a689bf2f2DcE0FCdD34] = true;
        whitelistEnabled = false;
    }

    modifier onlyOwner() {
        require(adminAddresses[msg.sender], "Error: Caller is not the owner");
        _;
    }

    function addAdmin(address _address) public onlyOwner {
        adminAddresses[_address] = true;
    }

    function removeAdmin(address _address) public onlyOwner {
        adminAddresses[_address] = false;
    }

    function setWhitelistEnabled() public onlyOwner {
        whitelistEnabled = true;
    }

    function setWhitelistDisabled() public onlyOwner {
        whitelistEnabled = false;
    }

    function getWhitelistInformation() public view returns(bool) {
        return whitelistEnabled;
    }

    function addAddressToWhitelist(address _address) public onlyOwner {
        require(!whitelistedAddresses[_address], "Error: Sender already been whitelisted");

        whitelistedAddresses[_address] = true;
    }

    function addAddressesToWhitelist(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            addAddressToWhitelist(_addresses[i]);
        }
    }

    function removeAddressFromWhitelist(address _addresses) public onlyOwner {
        require(whitelistedAddresses[_addresses], "Error: Sender is not whitelisted");

        whitelistedAddresses[_addresses] = false;
    }

    function removeAddressesToWhitelist(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            removeAddressFromWhitelist(_addresses[i]);
        }
    }

    function verifyUserAddress(address _whitelistedAddress) public view returns(bool) {
        bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
        return userIsWhitelisted;
    }

    function verifyUserAdminAddress(address _userAddress) public view returns(bool) {
        bool userIsAdmin = adminAddresses[_userAddress];
        return userIsAdmin;
    }

}