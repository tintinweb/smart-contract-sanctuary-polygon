// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract PoC {

    function VerifyMessage(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    function VerifyMessageV2(bytes32 _hashedMessage, bytes memory _sig) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        (bytes32 _r, bytes32 _s, uint8 _v) = splitSignature(_sig);
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    function VerifyMessageV3(string memory _message, bytes memory _sig) public view returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 _hashedMessage = getMessageHash(_message);
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        (bytes32 _r, bytes32 _s, uint8 _v) = splitSignature(_sig);
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    function validateCall(bytes memory _sig, bytes32 _hashedMessage, string memory _yourName) 
    public view returns(string memory greeting){
        require(VerifyMessageV2(_hashedMessage, _sig) == msg.sender,"You are spammer!");
        return _yourName;
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
        // implicitly return (r, s, v)
    }

    function getMessageHash(string memory _message) public view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender, _message));
    }
        

}