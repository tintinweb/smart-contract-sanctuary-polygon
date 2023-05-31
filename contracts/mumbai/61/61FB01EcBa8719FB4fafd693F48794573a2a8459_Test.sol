// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

pragma solidity ^0.8.9;

contract Test {

    uint256 a = 12;
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function getA() public view returns (uint256) {
        return a;
    }
    function setA(uint256 _a) public {
        require(msg.sender == owner, "Only owner can set A");
        a = _a;
    }
}