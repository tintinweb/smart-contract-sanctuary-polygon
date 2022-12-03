/**
 *Submitted for verification at polygonscan.com on 2022-12-02
*/

// SPDX-License-Identifier: MIT

// File: contracts/MessaageTwoFacet.sol


pragma solidity ^0.8.15;

contract MessageTwoFacet {
    uint256 a;
    bytes32 internal constant NAMESPAE = keccak256("messageTwo.facet");

    struct Storage {
        string message;
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = NAMESPAE;
        assembly {
            s.slot := position
        }
    }

    function setMessageTwo(string calldata _msg) external {
        Storage storage s = getStorage();
        s.message = _msg;
    }

    function getMessageTwo() external view returns (string memory) {
        return getStorage().message;
    }
}