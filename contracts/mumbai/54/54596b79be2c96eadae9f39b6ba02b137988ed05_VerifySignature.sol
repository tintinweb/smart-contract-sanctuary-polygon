/**
 *Submitted for verification at polygonscan.com on 2023-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VerifySignature {

    function getMessageHash(
        address _invoicer,
        uint _amount,
        uint _dueDate,
        address _payer,
        uint _id
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_invoicer, _amount, _dueDate, _payer, _id));
    }

    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) public pure returns (bytes32) {

        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function verify(
        address _signer,
        address _invoicer,
        address _payer,
        uint _amount,
        uint _dueDate,
        uint _id,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_invoicer, _amount, _dueDate,_payer, _id);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "");

        assembly {

            r := mload(add(sig, 32))

            s := mload(add(sig, 64))

            v := byte(0, mload(add(sig, 96)))
        }

    }
}