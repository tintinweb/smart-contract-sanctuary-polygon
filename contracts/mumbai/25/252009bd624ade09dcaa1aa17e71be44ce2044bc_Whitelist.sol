//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

error ONLY_OWNER_CAN_ACT();
error ALREADY_MEMBER();

contract Whitelist {
    // Create a mapping of whitelistedAddresses
    // if an address is whitelisted, we would set it to true, it is false by default for all other addresses.
    mapping(address => bool) public whitelistedAddresses;

    // numAddressesWhitelisted would be used to keep track of how many addresses have been whitelisted
    uint16 public numAddressesWhitelisted; // 65,536
    address public owner;

    constructor(address _ownerAddr) {
        owner = _ownerAddr;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert ONLY_OWNER_CAN_ACT();
        }
        _;
    }

    /**
        addAddressToWhitelist - This function adds the address of the sender to the
        whitelist
     */
    function addAddressToWhitelist(address _address) public onlyOwner {
        if (whitelistedAddresses[_address]) {
            revert ALREADY_MEMBER();
        }
        whitelistedAddresses[_address] = true;
        // Increase the number of whitelisted addresses
        numAddressesWhitelisted += 1;
    }
}