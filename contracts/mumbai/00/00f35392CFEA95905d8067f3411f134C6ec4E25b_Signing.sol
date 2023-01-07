//SPDX-License-Identifier:MIT

pragma solidity >=0.5.0 <0.9.0;

//This is the contract address
//0xE8c3B7E5d73a151901091b6A4C35e30E08f1782b

//This is the link
//https://mumbai.polygonscan.com/address/0xE8c3B7E5d73a151901091b6A4C35e30E08f1782b#code


contract Signing{

    //This is the verify function which takes three inputs
    //1-) The address of the message signer
    //2-)The message that was signed by the signer
    //3-) The hash of the signed message

    function verify(address _sender,string memory _message,bytes memory hash) external pure returns(bool)
    {
        //Now from the following two functions we are obtaining the hashed message that was signed by the signer off chain
        bytes32 signedMessagehash=getMessageHash(_message);
        bytes32 signedEthMessagehash=getSignedEthMessageHash(signedMessagehash);

        // The signedEthMessagehash is the message that was signed off chain by the sender of the message

        //Now we once we have the signed message and the signature we can create a verify function to get the signer
        return recoverSigner(signedEthMessagehash,hash)==_sender;
    }

    function getMessageHash(string memory _message) public pure returns(bytes32)
    {
        return keccak256(abi.encodePacked(_message));
    }

    function getSignedEthMessageHash(bytes32 _message) public pure returns(bytes32)
    {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",_message));
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
}