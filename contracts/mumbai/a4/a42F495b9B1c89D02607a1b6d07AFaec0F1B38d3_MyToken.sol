/**
 *Submitted for verification at polygonscan.com on 2023-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MyToken  {

    uint256 contador;

    function get_contador() public view returns(uint256){
        return contador;
    }

    function set_contador() public {
        contador+=1;
    }


}