/**
 *Submitted for verification at polygonscan.com on 2022-10-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

contract Ownable
{	
// Variable that maintains
// owner address
address private _owner;

// Sets the original owner of
// contract when it is deployed
constructor()
{
	_owner = msg.sender;
}

// Publicly exposes who is the
// owner of this contract
function owner() public view returns(address)
{
	return _owner;
}

// onlyOwner modifier that validates only
// if caller of function is contract owner,
// otherwise not
modifier onlyOwner()
{
	require(isOwner(),
	"Function accessible only by the owner !!");
	_;
}

// function for owners to verify their ownership.
// Returns true for owners otherwise false
function isOwner() public view returns(bool)
{
	return msg.sender == _owner;
}
}

contract Notarizer is Ownable
{
    uint256 public prevBlock;
    event RootHash(bytes32 rootHash, uint256 indexed prevBlock);

    //Store proof AKA hash 
    function storeNewRootHash(bytes32 _rootHash) onlyOwner external {
        emit RootHash(_rootHash, prevBlock);
        prevBlock = block.number;
    }

    function verify(bytes32 root, bytes32 leaf, bytes32[] memory proof) external pure returns (bool) {
    bytes32 computedHash = leaf;
    for (uint256 i = 0; i < proof.length; i++) {
        bytes32 proofElement = proof[i];
        if (computedHash < proofElement) {
            // Hash(current computed hash + current element of the proof)
            computedHash = keccak256(
                abi.encodePacked(computedHash, proofElement)
            );
        } else {
            // Hash(current element of the proof + current computed hash)
            computedHash = keccak256(
                abi.encodePacked(proofElement, computedHash)
            );
        }
    }
    // Check if the computed hash (root) is equal to the provided root
    return computedHash == root;
    }
}