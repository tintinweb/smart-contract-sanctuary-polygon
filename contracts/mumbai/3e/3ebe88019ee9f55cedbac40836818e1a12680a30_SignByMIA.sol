/**
 *Submitted for verification at polygonscan.com on 2023-06-09
*/

/* SPDX-License-Identifier: MIT */
pragma solidity ^0.8.6;

contract SignByMIA {
    address private owner;
    mapping(address => uint256) public _nonce; 
    event DocumentHashLog(
        uint256 indexed signatureId,
        string documentHash,
        address sender
    );

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function signEvent(
        uint256 signatureId,
        string memory documentHash
    ) public isOwner {
        _signEvent(signatureId, documentHash, msg.sender);
    }

    function signEventContent(
        uint256 signatureId,
        string memory documentHash,
        address from,
        bytes memory sig
    ) public isOwner {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0),
                this,
                //_nonce[from][id],
                from,
                "signEventContent",
                signatureId,
                documentHash
            )
        );

        address signer = checkSignature(from, sig, hash);
        _signEvent(signatureId, documentHash, signer);
    }

    function _signEvent(
        uint256 signatureId,
        string memory documentHash,
        address sender
    ) private {
        emit DocumentHashLog(signatureId, documentHash, sender);
    }

    function checkSignature(
        address identity,
        bytes memory sig,
        bytes32 hash
    ) internal returns (address) {
        address signer = ecrecovery(hash, sig);
        require(signer == identity, "signer <> identity");
        _nonce[signer]++;
        return signer;
    }

    function ecrecovery(bytes32 hash, bytes memory sig)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65) {
            return address(0);
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        return ecrecover(hash, v, r, s);
    }
}