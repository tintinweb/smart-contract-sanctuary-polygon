// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;
contract Poster {

 uint public counts = 0; // state variable
  
  struct Post{
    uint id;
    string content;
    string tag;
  }

  constructor() public {
    createPost('Hello World', '123');
  }
  
  mapping(uint => Post) public posts;

  function createPost(string memory _content, string memory _tag) public {
    counts++;
    posts[counts] = Post(counts, _content, _tag);
  }

}