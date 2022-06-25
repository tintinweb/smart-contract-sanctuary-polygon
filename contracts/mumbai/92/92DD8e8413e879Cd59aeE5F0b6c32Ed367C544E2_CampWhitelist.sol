// SPDX-License-Identifier: MIT

/**
 * License Based Service Contract
 * @author Liu
 */

pragma solidity ^0.8.4;

contract CampWhitelist {
    address owner; // variable that will contain the address of the contract deployer

    mapping(address => uint256) whitelist; // variables that have been added to whitelist

    constructor() {
        owner = msg.sender; // setting the owner the contract deployer
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner!");
        _;
    }

    function transferOwnership(address _newOwner)
        external
        onlyOwner
        returns (bool)
    {
        require(
            _newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        owner = _newOwner;
        return true;
    }

    // add user to whitelist
    function addUser(address _address, uint256 _type)
        public
        onlyOwner
        returns (bool success)
    {
        if (
            !(whitelist[_address] == 1 &&
                whitelist[_address] == 2 &&
                whitelist[_address] == 3)
        ) {
            whitelist[_address] = _type; // add to whitelist
            success = true;
        }
    }

    // unwhitelisted user from whitelist
    function removeUser(address _address)
        public
        onlyOwner
        returns (bool success)
    {
        if (
            whitelist[_address] == 1 ||
            whitelist[_address] == 2 ||
            whitelist[_address] == 3
        ) {
            whitelist[_address] = 0; // unwhitelisted from whitelist
            success = true;
        }
    }

    function isWhitelisted(address _address) external view returns (bool) {
        return (whitelist[_address] == 1 ||
            whitelist[_address] == 2 ||
            whitelist[_address] == 3);
    }
}