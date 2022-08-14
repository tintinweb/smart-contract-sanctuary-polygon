/**
 *Submitted for verification at polygonscan.com on 2022-08-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.15;

contract HashirasCTF0x00{
    address public owner;
    address[] public whitelisted;
    mapping(address => bool) public isWhitelisted;

    constructor(){
        owner = msg.sender;
    }

    function solvedBy() external view returns(address[] memory){
        return whitelisted;
    }

    function getWhitelisted(bytes memory signature) external{
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        require(ecrecover(ethSignedMessageHash, v, r, s) == owner,"Try Again");
        require(!isWhitelisted[msg.sender],"Already whitelisted !!!");
        whitelisted.push(msg.sender);
        isWhitelisted[msg.sender] = true;
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}