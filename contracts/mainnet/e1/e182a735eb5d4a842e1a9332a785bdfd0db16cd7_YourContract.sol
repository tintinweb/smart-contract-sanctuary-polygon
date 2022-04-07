/**
 *Submitted for verification at polygonscan.com on 2022-04-07
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// import "hardhat/console.sol";

// Graph Maxi Commit Reveal scheme
contract YourContract {
    event Commit(address committer, bytes32 commitment);
    event Reveal(address revealer, bytes32 commitment, string secret);

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