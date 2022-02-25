/**
 *Submitted for verification at polygonscan.com on 2022-02-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/**
 * A smart contract with the sole purpose of having a stupidly simple key -> binary store on the blockchain.
 * This binary specific key value store allows you to store 1 uint256 per key.
 * 
 * A usecase for this is for example storing the address of a IPFS CID. The CID consists of multiple parts
 * making it quite a bit longer. But the core of it is a sha256 hash which fits perfectly fine in one uint256!
 * In this specific case it's up to the caller of the contract to extract said sha256 and to re-compose the CID
 * it represents. But this allows for quite efficient storage of those CID's.
 * 
 * How you can use it, as a general key value store, is to convert your data into the uint256 representation.
 * This is essentially binary "encoding".
 * 
 * You can access a GUI for this on https://binkv.sc2.nl
 * 
 */
 
 contract BinKV
 {
     mapping(address => uint256[]) private kvMapping;
     event valueChanged(address addr, uint256 key, uint256 value);
     
     modifier keyExists(address addr, uint256 key)
     {
         uint256 mappingLength = kvMapping[addr].length;
         require(key < mappingLength && key >= 0, "key doesn't exist");
         _;
     }
     
    /**
     * Store a new value
     */
     function setValue(uint256 value) public
     {
         kvMapping[msg.sender].push(value);
     }

    /**
     * Update an existing value. You need to know the key of the value you want to update.
     */
     function updateValue(uint256 key, uint256 value) public keyExists(msg.sender, key)
     {
         kvMapping[msg.sender][key] = value;
         emit valueChanged(msg.sender, key, value);
     }
     
    /**
     * Get the value by key. Uses your wallet address.
     */
     function getValue(uint256 key) public view returns(uint256)
     {
         return getValue(msg.sender, key);
     }

    /**
     * Get the value by key. Uses the key you provide.
     */
     function getValue(address addr, uint256 key) public view keyExists(addr, key) returns(uint256)
     {
         return kvMapping[addr][key];
     }
 }