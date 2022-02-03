/**
 *Submitted for verification at polygonscan.com on 2022-02-03
*/

// SPDX-License-Identifier: NONE
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {
    mapping(uint256 => bytes32) public hashMap;
    event Stored  (uint256 indexed id);

    function store(uint256 id, bytes32 hash) public {
        hashMap[id] = hash;
        emit Stored(id);
    }

    function retrieve(uint256 id) public view returns (bytes32){
        return hashMap[id];
    }
}