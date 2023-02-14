/**
 *Submitted for verification at polygonscan.com on 2023-02-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract Story {
  string[] public chapters;

  function writeChapter(string memory newChapter) public {
    chapters.push(newChapter);
  }
}