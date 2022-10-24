/**
 *Submitted for verification at polygonscan.com on 2022-10-24
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

contract CEND {

    // Admins
    mapping (address => bool) admins;

    // Map the message ID => Message
    mapping (string => string) private hashMap;

    constructor() {
        // Setup the default Admin
        admins[msg.sender] = true;
    }

    /*

    MODIFIERS

    */

    modifier onlyAdmins() {
        require(admins[msg.sender], "Only admins can call this function.");
        _;
    }


    /*

    ADMIN FUNCTIONS

    */

    function addAdmin(address newAdmin) public onlyAdmins{
        admins[newAdmin] = true;
    }

    function removeAdmin(address oldAdmin) public onlyAdmins{
        admins[oldAdmin] = false;
    }


    function saveHash(string memory GUID, string memory hash) public onlyAdmins {

        // Make sure we received a GUID
        require(bytes(GUID).length > 0, "Invalid GUID");

        // Make sure we received a Hash
        require(bytes(hash).length > 0, "Invalid Hash");

        // check to make sure we're not overwriting a GUID
        require(bytes(hashMap[GUID]).length == 0, "That GUID has already been writtedn");

        // Write the hash to the map
        hashMap[GUID] = hash;

        // Log the message post
        emit hashAdded(GUID, hash);
    }
    
    function retrieveHash(string memory GUID) public view returns(string memory hash){
        
        // Make sure we received a GUID
        require(bytes(GUID).length > 0, "Invalid GUID");
        
        return hashMap[GUID];
    }

    event hashAdded(string indexed GUID, string indexed hash);
}