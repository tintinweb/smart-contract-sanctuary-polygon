/**
 *Submitted for verification at polygonscan.com on 2022-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

abstract contract Signatures {
    
    function getSigner(string memory _publicKey, bytes memory _sig) public pure returns(address) {
        bytes32 message = keccak256(abi.encode("Set public key for e-mail client: ", _publicKey));
        return recoverSigner(message, _sig);
   }

   function recoverSigner(bytes32 message, bytes memory sig)
       internal
       pure
       returns (address)
     {
       uint8 v;
       bytes32 r;
       bytes32 s;
       (v, r, s) = splitSignature(sig);
       return ecrecover(message, v, r, s);
   }

   function splitSignature(bytes memory sig)
       internal
       pure
       returns (uint8, bytes32, bytes32)
     {
       require(sig.length == 65);

       bytes32 r;
       bytes32 s;
       uint8 v;

       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }
 
       return (v, r, s);
   }
}

pragma solidity 0.8.7;

contract w3Mail is Signatures {

    mapping(address => string) private publicKeys;

    event Transfer(address indexed from, address indexed to, string email, uint256 timestamp);

    function setPublicKey(string memory _publicKey, bytes memory _signature) public {
        address signer = getSigner(_publicKey, _signature);
        publicKeys[signer] = _publicKey;
    }

    function getPublicKey(address _user) public view returns (string memory) {
        return publicKeys[_user];
    }

    function sendEmail(address from, address to, string memory _email) public {
        require(bytes(publicKeys[from]).length != 0, "From address not registered.");
        require(bytes(publicKeys[to]).length != 0, "To address not registered.");
        emit Transfer(from, to, _email, block.timestamp);
    }

}