// SPDX-license-Identifier: MIT 
pragma solidity >=0.4.21 <0.9.0;

contract Poster {
    event NewPost(address indexed user, string content, string indexed tag);

    function post(string memory content, string memory tag) public {
        emit NewPost(msg.sender, content, tag);
    }
}