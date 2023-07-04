/**
 *Submitted for verification at polygonscan.com on 2023-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract OmnibalGasless {
    string public greetingText = "Hello World!";
    address public greetingSender;

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    struct Greeting {
        string text;
        uint deadline;
    }

    bytes32 DOMAIN_SEPARATOR;

    constructor () {
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: "Ether Mail",
            version: '1',
            chainId: block.chainid,
            verifyingContract: address(this)
        }));
    }

    function hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    function hash(Greeting memory greeting) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            keccak256("Greeting(string text,uint deadline)"),
            keccak256(bytes(greeting.text)),
            greeting.deadline
        ));
    }

    function verify(Greeting memory greeting, address sender, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hash(greeting)
        ));
        return ecrecover(digest, v, r, s) == sender;
    }

    function greet(Greeting memory greeting, address sender, uint8 v, bytes32 r, bytes32 s) public {
        require(verify(greeting, sender, v, r, s), "Invalid signature");
        require(block.timestamp <= greeting.deadline, "Deadline reached");
        greetingText = greeting.text;
        greetingSender = sender;
    }
}