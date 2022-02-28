// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "./TestB.sol";
contract TestA is TestB{
    string public uri;
    address public activityAdd;
    constructor(string memory _uri,address addr){
          uri=_uri;
          activityAdd=addr;
    }
    string public lastName="jack";
    function sayB()public view returns(string memory){
          return name;
    }
}