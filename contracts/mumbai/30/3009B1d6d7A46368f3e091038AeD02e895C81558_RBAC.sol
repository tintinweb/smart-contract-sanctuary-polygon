/**
 *Submitted for verification at polygonscan.com on 2022-04-18
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File contracts/RBAC.sol

pragma solidity ^0.6.12;

contract RBAC {
    // Listing all admins
    address [] public admins;

    // Modifier for easier checking if user is admin
    mapping(address => bool) public isAdmin;

    event AddAdmin(address _admin);
    event RemoveAdmin(address _admin);

    // Modifier restricting access to only admin
    modifier onlyAdmin {
        require(isAdmin[msg.sender] == true, "Restricted only to admin address.");
        _;
    }

    // Constructor to set initial admins during deployment
    constructor (address [] memory _admins) public {
        for(uint i = 0; i < _admins.length; i++) {
            admins.push(_admins[i]);
            isAdmin[_admins[i]] = true;
        }
    }

    function addAdmin(
        address _adminAddress
    )
    external
    onlyAdmin
    {
        // Can't add 0x address as an admin
        require(_adminAddress != address(0x0), "[RBAC] : Admin must be != than 0x0 address");
        // Can't add existing admin
        require(isAdmin[_adminAddress] == false, "[RBAC] : Admin already exists.");
        // Add admin to array of admins
        admins.push(_adminAddress);
        // Set mapping
        isAdmin[_adminAddress] = true;

        emit AddAdmin(_adminAddress);
    }

    function removeAdmin(
        address _adminAddress
    )
    external
    onlyAdmin
    {
        // Admin has to exist
        require(isAdmin[_adminAddress] == true, "Admin has not exist.");

        uint i = 0;

        while(admins[i] != _adminAddress) {
            if(i == admins.length) {
                revert("Passed admin address does not exist");
            }
        }

        // Copy the last admin position to the current index
        admins[i] = admins[admins.length-1];

        isAdmin[_adminAddress] = false;

        // Remove the last admin, since it's double present
        admins.pop();

        emit RemoveAdmin(_adminAddress);
    }

    // Fetch all admins
    function getAllAdmins()
    external
    view
    returns (address [] memory)
    {
        return admins;
    }

}