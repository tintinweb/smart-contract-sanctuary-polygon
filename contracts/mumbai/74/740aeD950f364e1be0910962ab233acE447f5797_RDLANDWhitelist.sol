// SPDX-License-Identifier: MIT

/**
 * License Based Service Contract
 * @author Liu
 */

pragma solidity ^0.8.4;

contract RDLANDWhitelist {
    address owner; // variable that will contain the address of the contract deployer

    mapping(address => uint256) whitelist; // variables that have been added to whitelist

    event Added(address account);
    event Removed(address account);

    constructor() {
        owner = msg.sender; // setting the owner the contract deployer
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner!");
        _;
    }

    function isOwner() external view returns (address) {
        return owner;
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
    function addUser(address _address, uint256 _type) public onlyOwner {
        require(_address != address(0), "address is the zero address");
        require(_type == 1 || _type == 2 || _type == 3, "type invalid");

        whitelist[_address] = _type; // add to whitelist
        emit Added(_address);
    }

    // unwhitelisted user from whitelist
    function removeUser(address _address) public onlyOwner {
        require(_address != address(0), "address is the zero address");

        whitelist[_address] = 0; // unwhitelisted from whitelist
        emit Removed(_address);
    }

    function isWhitelisted(address _address) external view returns (bool) {
        require(_address != address(0), "address is the zero address");

        return (whitelist[_address] == 1 ||
            whitelist[_address] == 2 ||
            whitelist[_address] == 3);
    }

    function levelWhitelist(address _address) external view returns (uint256) {
        require(_address != address(0), "address is the zero address");

        return whitelist[_address];
    }
}