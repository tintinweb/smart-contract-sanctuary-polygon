/**
 *Submitted for verification at polygonscan.com on 2022-07-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

struct MetaTransaction {
		uint256 nonce;
		address from;
}

contract DisperseEther {
    mapping(address => uint256) public nonces;

    fallback() external payable {
    }
    receive() external payable {
    }

    // transfer ether from **this** contract to *recipients*
    // #todo add sender checking & contract's balance checking
    // will only keep this function as public for testing purpose, but it should be `internal` instead
    function disperseEther(address payable[] memory recipients, uint256[] memory values) public {
        for (uint256 i = 0; i < recipients.length; i++)
            recipients[i].transfer(values[i]);
    }
    function disperseEtherToAll(address payable[] memory recipients, uint256 total) public {
        for (uint256 i = 0; i < recipients.length; i++)
            recipients[i].transfer(total/recipients.length);
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));
    bytes32 internal constant META_TRANSACTION_TYPEHASH = keccak256(bytes("MetaTransaction(uint256 nonce,address from)"));
    bytes32 internal DOMAIN_SEPARATOR = keccak256(abi.encode(
    EIP712_DOMAIN_TYPEHASH,
		keccak256(bytes("DisperseEther")),
		keccak256(bytes("1")),
		80001, // Polygon Mumbai
		address(this)
    ));
    // #todo add sender checking
    function disperseEtherMeta(address sender, address payable[] memory recipients, uint256[] memory values, bytes32 r, bytes32 s, uint8 v) public {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[sender],
            from: sender
        });
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(META_TRANSACTION_TYPEHASH, metaTx.nonce, metaTx.from))
            )
        );

        require(sender == ecrecover(digest, v, r, s), "invalid-signatures");
            
        disperseEther(recipients, values);
        nonces[sender]++;
    }
    function disperseEtherToAllMeta(address sender, address payable[] memory recipients, uint256 total, bytes32 r, bytes32 s, uint8 v) public {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[sender],
            from: sender
        });
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(META_TRANSACTION_TYPEHASH, metaTx.nonce, metaTx.from))
            )
        );

        require(sender == ecrecover(digest, v, r, s), "invalid-signatures");
            
        disperseEtherToAll(recipients, total);
        nonces[sender]++;
    }
}