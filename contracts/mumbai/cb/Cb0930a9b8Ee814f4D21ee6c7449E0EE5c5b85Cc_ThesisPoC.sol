/**
 *Submitted for verification at polygonscan.com on 2022-11-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// this smart contract will store the root hashes of Merkle Trees of projects to ensure that the project data was note changed in the filesystem of the backend server

/// @title Smart contract for the bachelors thesis of Daniel Rein
/// @author Daniel Rein
contract ThesisPoC {
    // string public author = "Daniel Rein";
    // address public thesisPoCContractAddress = address(this);
    // address public lastSenderAddress;

    mapping(string => string) public merkleTreeRootHashValues;

    uint256 contractDeploymentTime = block.timestamp;

    // this function takes a project id and will return the merkle tree root hash vale that was stored for this project id if there is one
    function getMerkleTreeRootOfProjectWithId(string memory _projectId) public view returns (string memory) {
        return merkleTreeRootHashValues[_projectId];
    }

    /// @notice this function takes a merkle tree root hash value and a project id and will store both of these values in a mapping
    function saveMerkleTreeRootHashValueForProjectWithId(string memory _merkleTreeHashValue, string memory _projectId) public {
        merkleTreeRootHashValues[_projectId] = _merkleTreeHashValue;
    }
}