/**
 *Submitted for verification at polygonscan.com on 2023-04-29
*/

// File: SignatureProcessor.sol


pragma solidity ^0.8.17;

library SignatureProcessor {
    function _isSigned(bytes memory _signature, bytes32 _secret, address _address, uint256 _secretNum) public pure returns (bool, uint256) {
        bytes32 hashedMsg = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _secret)
            );
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature); 
        address signer = ecrecover(hashedMsg, v, r, s); 
        return (signer == _address, _secretNum+1);
    }

    function _splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    //use address location of SecretStorage smart contract
    function _getSecret(address _location) public returns (string memory,uint256) {
        (bool success, bytes memory data) = _location.call(abi.encodeWithSignature("getSecret()"));
        (string memory secret,uint256 secretNum) = abi.decode(data, (string, uint256));
        require(success, "Wrong secret storage");
        (bool successDestroy,) = _location.call(abi.encodeWithSignature("destroy()"));
        require(successDestroy, "Cannot destroy");
        return (secret, secretNum);
    }
}