/**
 *Submitted for verification at polygonscan.com on 2022-03-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage  {

    string solution;

    constructor(string memory input) {
        solution = input;
    }
    
    function retrieve() public view returns (string memory){
        return solution;
    }
}