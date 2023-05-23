/**
 *Submitted for verification at polygonscan.com on 2023-05-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Testament {
    mapping(string => uint) private _testaments;
    address private owner = msg.sender;

    function setTestament(string memory name, uint amount) public {
        require(msg.sender == owner, "Only the owner can set a testament");
        _testaments[name] = amount;
    }

    /*
        Visilibity: public, private, internal, external
        public: can be called from anywhere
        private: can only be called from inside the contract
        internal: can only be called from inside the contract or from contracts that inherit from it
        external: can only be called from outside the contract
    */
    function getTestament(string memory name) public view returns (uint) {
        return _testaments[name];
    }
}