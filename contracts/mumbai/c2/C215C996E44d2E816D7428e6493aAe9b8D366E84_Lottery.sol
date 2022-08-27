/**
 *Submitted for verification at polygonscan.com on 2022-08-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Lottery {

    /**
     * @dev Return hashPick1 
     * @param _hash of 'bytes32'
     * @param _mod of 'uint'
     * @return value of 'uint'
     */
    function hashPick1(bytes32 _hash, uint _mod) public pure returns (uint) {
        return hashToUint(_hash) % _mod;
    }

    /**
     * @dev Return hashToUint 
     * @param _hash of 'bytes32'
     * @return value of 'uint256'
     */
    function hashToUint(bytes32 _hash) public pure returns (uint256) {
        return uint256(hash(_hash));
    }

    /**
     * @dev Return hash256 
     * @param _hash of 'bytes32'
     * @return value of 'bytes32'
     */
    function hash(bytes32 _hash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_hash));
    }

}