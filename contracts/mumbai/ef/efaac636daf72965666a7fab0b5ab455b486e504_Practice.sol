pragma solidity ^0.8.13;

import "./Istract.sol";

contract Practice {
    mapping(address => IStract.userInfo) public userInfo;    
    
    function say() public returns (string memory){
        if (keccak256(abi.encodePacked(userInfo[msg.sender].contry)) ==
            keccak256("Japan"))
        {
            return  "Hi";
        } else {
            return "Hello world!";
        }
    }
    function setInfo(IStract.userInfo memory _info) public{
        userInfo[msg.sender] = _info;
    } 


    }

pragma solidity ^0.8.13;

interface IStract {
    struct userInfo {
    string name;
    string contry;
  }
}