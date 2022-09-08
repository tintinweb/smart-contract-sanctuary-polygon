/**
 *Submitted for verification at polygonscan.com on 2022-09-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Ballot {
   

    bytes32 public baseNode;

    constructor(bytes32 _baseNode) public {
        baseNode = _baseNode;
    }
    

    function makeCommitmentWithConfig(string memory name)public view returns(bytes32) {
        bytes32 label = keccak256(bytes(name));
        return keccak256(abi.encodePacked(baseNode, label));
    }
}