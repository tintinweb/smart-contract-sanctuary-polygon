// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MessageFacet {

    bytes32 internal constant NAMESPACE = keccak256("message.facet");

    struct Storage {
        string message;
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }
}