/**
 *Submitted for verification at polygonscan.com on 2022-11-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract daySeventeen{

    function search(uint256[] memory array, uint16 length, uint256 inputElement) public pure returns(uint8){
        uint8 elementCheck = 0;

        for(uint32 i = 0; i < length; i++){
            if(array[i] == inputElement){
                elementCheck = 1;
            }
        }

        return elementCheck;
    }
    
}