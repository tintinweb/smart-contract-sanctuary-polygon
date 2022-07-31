/**
 *Submitted for verification at polygonscan.com on 2022-07-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract Helper {
    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";
    bytes32 private constant APPROVAL_SIGNATURE_HASH =
        keccak256("SetMasterContractApproval(string warning,address user,address masterContract,bool approved,uint256 nonce)");

    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_SIGNATURE_HASH, keccak256("BentoBox V1"), 1, 0xd96f48665a1410C0cd669A88898ecA36B9Fc2cce));
    }

    function getDigest(
        address user,
        address masterContract,
        bool approved,
        uint256 nonce
    ) public returns (bytes32) {
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            APPROVAL_SIGNATURE_HASH,
                            approved
                                ? keccak256("Give FULL access to funds in (and approved to) BentoBox?")
                                : keccak256("Revoke access to BentoBox?"),
                            user,
                            masterContract,
                            approved,
                            nonce
                        )
                    )
                )
            );
        
        return digest;
    }
}