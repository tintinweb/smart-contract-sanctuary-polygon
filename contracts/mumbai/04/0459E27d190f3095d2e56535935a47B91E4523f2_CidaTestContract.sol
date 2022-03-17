//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

contract CidaTestContract {
    string private name;

    constructor(string memory _name) {
        name = _name;
    }

    function changeName(string memory _name) public {
        name = _name;
    }

    function getName() public view returns (string memory) {
        return name;
    }
}