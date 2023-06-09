/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Signature {    

    // The server's Ethereum address
    address public serverAddress = 0x05b2d51cF31B8683F1B91B7A04b457beFDd5DE09;

    // Prefixes hashes to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    // Helper function to recover the signer of a message
    function recoverSigner(bytes32 message, bytes memory sig) public pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    // Helper function to split a signature into (v, r, s)
    function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    //test Signature
    function testSig(uint256[] memory tokenIds, uint256 nonce, bytes memory userSignature, bytes memory serverSignature) public view returns (bytes32,bool,bool,address,address){
        bytes32 message = keccak256(abi.encodePacked(msg.sender, tokenIds, nonce));
        bool userSig = false;
        bool serverSig = false;
        bytes32 ethSignedMessage = prefixed(message);
        address recoverSignerUser = recoverSigner(ethSignedMessage, userSignature);
        address recoverSignerServer = recoverSigner(ethSignedMessage, serverSignature);
        if(recoverSignerUser == msg.sender){
            userSig= true;
        }
        if(recoverSignerServer == serverAddress){
            serverSig= true;
        }
        return (message, userSig, serverSig, recoverSignerUser, recoverSignerServer);
    }
}