/**
 *Submitted for verification at polygonscan.com on 2023-04-14
*/

pragma solidity ^0.8.0;

contract LoadTest {

    uint256 public counter; 

    constructor() {
        counter=0;
        }

    function increment () external {
        counter+=1;
    }
}