//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "contracts/Greeter.sol";

contract Registry { 
    address[] private greets;

    modifier notEmpty(uint index){
        require(greets.length >= index);
        _;
    }

    function createGreet(string memory _greeting) public  {
        address newGreet = address(new Greeter(_greeting));
        greets.push(newGreet);
    }

    function getGreets() public view returns (address[] memory) {
        return greets;
    }

    function getGreet(uint index) public view notEmpty(index) returns (string memory){
        Greeter greeter = Greeter(greets[index]);
        return greeter.greet();
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    string private greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }


    function greet() public view returns (string memory) {
        return greeting;
    }
}