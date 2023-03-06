// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;



// This contract will be responsible for generating and verifying time bound signatures
contract Signature{

    // generate the hashed message with the inputs
    function getMessageHash(
        address _to,
        string memory _msg,
        uint _timestamp
    ) public view returns(bytes32){
        return keccak256(abi.encodePacked(_to,_msg,_timestamp));
    }


    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }


    // function to verify the signer and expiration of the signature
    function verify(
        address _to,
        string memory _msg,
        uint _timestamp,
        bytes memory _signature

    ) public view returns(bool){

        // recreate the msghash
        bytes32  msgHash = getMessageHash(_to, _msg,_timestamp);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(msgHash);
        require(recoverSigner(ethSignedMessageHash, _signature) == _to, "not the original signer");
        require(_timestamp >= block.timestamp,"signature expired");
        return true;
    }


    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
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