/**
 *Submitted for verification at polygonscan.com on 2022-04-06
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title Graph Maxi Commit Reveal scheme
/// @author nicholas
contract YourContract {
    event Commit(address, bytes32);
    event Reveal(address, bytes32, string);

    function getHash(string calldata _input) public pure returns (bytes32) {
        return keccak256(abi.encode(_input));
    }

    function commit(bytes32 _hash) external {
        emit Commit(msg.sender, _hash);
    }

    function reveal(string calldata _input) external {
        bytes32 _hash = getHash(_input);
        emit Reveal(msg.sender, _hash, _input);
    }
}