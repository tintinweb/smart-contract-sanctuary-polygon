/**
 *Submitted for verification at polygonscan.com on 2023-05-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Signature Verification

contract VerifySignature {
    
    /* MessageHash
    to = 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8
    fee = 1000
    tokenId=10
    message = "SignMessage"
    Messagehash :  0xab644bc8aa4b665cf95aebaa30e2158c134e9520632996e985a50314b12dbfe0
    */
    function getMessageHash(
        address _to,
        uint256 _fee,
        uint256 _tokenId,
        string memory _message
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _fee, _tokenId, _message));
    }


    /* Sign message hash

    to = 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8
    fee = 1000
    tokenId=10
    message = "SignMessage"
    SignedMessageHash: 0xd71a5c37addf7cbffc0f6e4d6f7de73187ba9cfa5cbd531d12061a44bc52e214
    */
    function getSignedMessageHash(
        address _to,
        uint256 _fee,
        uint256 _tokenId,
        string memory _message
        )
        public
        pure
        returns (bytes32)
    {   

        bytes32 _messageHash = getMessageHash(_to, _fee, _tokenId, _message);
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    /* Verify signature
    signer = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    to = 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8
    fee = 1000
    tokenId=10
    message = "SignMessage"
    signature : 0xc7773598d3ec8d0b483e6340c2b2f96e3b5426972adca0d6684fc839a52a112a7daf5e14ea16620ae1cedaa7fd8b918011f49c74fb7fda1b8bcfcb46caf940031c
    */
    function verify(
        address _signer,
        address _to,
        uint256 _fee,
        uint256 _tokenId,
        string memory _message,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 _signedMessageHash = getSignedMessageHash(_to, _fee, _tokenId, _message);

        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        ecrecover(_signedMessageHash, v, r, s);

        return ecrecover(_signedMessageHash, v, r, s) == _signer;
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
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function secretFunction(string memory f) external pure returns(uint256){
        require(
            keccak256(bytes(f)) !=
                0x097798381ee91bee7e3420f37298fe723a9eedeade5440d4b2b5ca3192da2428,
            "invalid"
        );

        return 10;
    }
}