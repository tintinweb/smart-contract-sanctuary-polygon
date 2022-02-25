/**
 *Submitted for verification at polygonscan.com on 2022-02-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/**
 * This smart contract allows you to set a key -> value pair.
 * The key can be anything and is unique on a per wallet bases.
 * 
 * The intended purpose here is to have a key that remains the same.
 * You can then set (and later update) the value for this key.
 * 
 * This could be used for IPFS.
 * You could for example have a "settings" -> "CID sha 256 hash" 
 * 
 */
 
 contract ChainKV
 {
    struct ValueData
    {
        address owner;
        uint256 value;
    }

    mapping(bytes32 => ValueData) private kvMapping;
    
    event valueChanged(string key, uint256 value, address owner);
    
    constructor()
    {}

    // Only the owner of a key can change it. Or anyone if the address is 0.
    modifier keyExists(bytes32 key, address owner)
    {
        ValueData memory data = kvMapping[key];
        require(data.owner == owner || data.owner == address(0), "You're not the owner of this record.");
        _;
    }

    function setValue(string calldata key, uint256 value) public keyExists(composeKeyHash(key, msg.sender), msg.sender)
    {
        bytes32 hashValue = composeKeyHash(key, msg.sender);
        kvMapping[hashValue] = ValueData(msg.sender, value);

        // Emitted for any change, including newly added values.
        emit valueChanged(key, value, msg.sender);
    }

    function composeKeyHash(string calldata key, address owner) internal pure returns(bytes32)
    {
        return sha256(bytes.concat(bytes(key), abi.encodePacked(owner)));
    }

    function getValue(string calldata key, address owner) public view returns(uint256)
    {
        ValueData memory data = kvMapping[composeKeyHash(key, owner)];
        return data.value;
    }
 }