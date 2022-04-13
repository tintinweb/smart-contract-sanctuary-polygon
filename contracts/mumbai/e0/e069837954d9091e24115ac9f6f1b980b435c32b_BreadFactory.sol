/**
 *Submitted for verification at polygonscan.com on 2022-04-12
*/

pragma solidity ^0.8.7;

contract BreadFactory {
    Bread[] public breads;

    function createBread(string memory name) external {
        Bread b = new Bread(name);
        breads.push(b);
    }
}

contract Bread {
    string public name;

    constructor(string memory _name) public {
        name = _name;
    }
}