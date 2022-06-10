/**
 *Submitted for verification at polygonscan.com on 2022-06-10
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.7;

contract VerifySignature {

    uint256 public timestamp;

    constructor() {
        timestamp = block.timestamp;
    }

    function update() public {
        timestamp = block.timestamp;
    }
    
    function getMessageHash(
        address _to,
        uint _amount,
        string memory _message
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _message));
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


    function verifyAddress(
        address _signer,
        address _to,
        uint _amount,
        string memory _message,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
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

        // implicitly return (r, s, v)
    }
}