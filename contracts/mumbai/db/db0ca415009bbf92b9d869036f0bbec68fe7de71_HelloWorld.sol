/**
 *Submitted for verification at polygonscan.com on 2022-02-20
*/

// My First Smart Contract 
pragma solidity ^0.8.4;
contract HelloWorld {
    function get()public pure returns (string memory){
        return 'Hello Contracts';
    }
}