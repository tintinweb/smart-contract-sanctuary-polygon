/**
 *Submitted for verification at polygonscan.com on 2023-04-21
*/

// File: verify.sol


pragma solidity ^0.8.17;


library SignatureProcessor {
    function _isSigned(bytes memory _signature, bytes32 _secret, address _address) public pure returns (bool) {
        bytes32 hashedMsg = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _secret)
            );
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature); 
        address signer = ecrecover(hashedMsg, v, r, s); 
        return signer == _address;
    }

    function _splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}