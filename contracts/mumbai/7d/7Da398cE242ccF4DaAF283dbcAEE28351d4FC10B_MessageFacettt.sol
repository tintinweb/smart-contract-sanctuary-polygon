/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract MessageFacettt {

    bytes32 internal constant NAMESPACE = keccak256("message.facett");

    struct Storage {
        string message;
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = NAMESPACE;
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

    mapping(address => uint) ages;

    // public function to save the user's age
    function saveAge(uint _num) public {
        ages[msg.sender] = _num;
    }

    // public function to read the user's age by address
    function getAge(address _myAddress) public view returns (uint) {
        return ages[_myAddress];
    }

}