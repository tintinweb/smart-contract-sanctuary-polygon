/**
 *Submitted for verification at polygonscan.com on 2022-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract MessageFacet {
    uint256 a;
    bytes32 internal constant NAMESPAE = keccak256("message.facet");

    struct Storage {
        string message;
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = NAMESPAE;
        assembly {
            s.slot := position
        }
    }

    function setMessage(string calldata _msg) external {
        Storage storage s = getStorage();
        s.message = _msg;
    }

    function getMessage() external view returns (string memory) {
        return getStorage().message;
    }
}