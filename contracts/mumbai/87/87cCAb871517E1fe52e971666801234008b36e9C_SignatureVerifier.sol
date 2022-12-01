// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @author Simon Samuel
 * @notice This contract is HEAVILY inspired by https://solidity-by-example.org/signature/
 *
 */
contract SignatureVerifier {
    string REGISTRATION_MESSAGE =
        "I hereby authorize this smart contract to have ownership over my deposited funds and grant it authorization to send it to ONLY my provided Next of Kin address if I am unable to provide a validation of Life.";

    function getMessageHash(string memory _message)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_message));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verify(address _signer, bytes memory signature)
        public
        view
        returns (bool)
    {
        bytes32 messageHash = getMessageHash(REGISTRATION_MESSAGE);
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