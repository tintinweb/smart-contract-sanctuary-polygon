/**
 *Submitted for verification at polygonscan.com on 2023-01-07
*/

// File: test_story.sol


pragma solidity ^0.8.12;
contract FirstClass {
    string count = "";
    function my_function1() public view returns(string memory){
        return count;
    }
    function my_function2(string memory txt) public {
        count = string.concat(count, " ",txt);
    }
}