// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title document.do
 * @dev Add, control and resolve document.do documents
 */
contract Document {

    address admin = 0x02DF17338e096047c91cde04b0b30439d1DbA481;
    
    struct Data
    {
        address owner;
        string content;
    }

    mapping(bytes32 => Data) public names;

    function add(bytes32 name, address owner) public {
        if(names[name].owner == 0x0000000000000000000000000000000000000000 && msg.sender == admin)
            names[name].owner = owner;
    }

    function setContent(bytes32 name, string calldata content) public {
        if(msg.sender == names[name].owner)
            names[name].content = content;
    }

    function setOwner(bytes32 name, address owner) public {
        if(msg.sender == names[name].owner)
            names[name].owner = owner;
    }

    function destroy(bytes32 name) public {
        if(msg.sender == names[name].owner)
            delete names[name];
    }

    function setAdmin(address adminAddress) public {
        if(msg.sender == admin)
            admin = adminAddress;
    }
}