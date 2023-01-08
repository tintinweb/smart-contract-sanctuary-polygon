/**
 *Submitted for verification at polygonscan.com on 2023-01-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DriveStorage{

    address public owner;
    mapping(address => Data) links;

    struct Data{
        string[] link;
        string[] fileName;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setter(address user, string memory _link , string memory _fileName) public {
        require(msg.sender ==  user, "You can't add this as parameter");
        Data storage c = links[user];
        c.link.push(_link);
        c.fileName.push(_fileName);
    }

    function getLink(address user) public view returns(string[] memory){
        require(msg.sender ==  user, "You can't add this as parameter");
        Data storage c = links[user];
            return c.link;
    }

    function getFileName(address user) public view returns(string[] memory){
        require(msg.sender ==  user, "You can't add this as parameter");
        Data storage c = links[user];
            return c.fileName;
    }
}