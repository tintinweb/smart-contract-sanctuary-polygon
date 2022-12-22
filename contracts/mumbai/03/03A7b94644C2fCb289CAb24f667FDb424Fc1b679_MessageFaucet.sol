//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract MessageFaucet { 

    bytes32 internal constant NAMESPACE = keccak256("diamond.standard.messagefaucet");

    struct Storage {
        string message;
    }


    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function setMessage(string calldata message) external {
        Storage storage s = getStorage();
        s.message = message;
    }

    function getMessage() external view returns (string memory) {
        Storage storage s = getStorage();
        return s.message;
    }

}