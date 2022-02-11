pragma solidity ^0.8.0;

contract Dummy {
    string[] public things;

    function setSomething(string[] memory _somethings) public {
        for (uint i = 0; i < _somethings.length; i++) {
            things[i + things.length] = _somethings[i];
        }
    }
}