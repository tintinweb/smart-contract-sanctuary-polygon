/**
 *Submitted for verification at polygonscan.com on 2022-11-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract dayTwenty{
    function secondMax(int256[] memory arr, uint32 length) public pure returns(int256){
        require(length > 2, "Invalid length of the array. Should contain atleast 3 elements");

        int256 _secondMax = 0;

        for(uint32 i = 0; i < length - 1; i++){
            for(uint32 j = 0; j < length - 1; j++){
                if(arr[j] > arr[j + 1]){
                    int256 currentValue = arr[j];
                    arr[j] = arr[j + 1];
                    arr[j + 1] = currentValue;
                }
            }
        }

        for(uint32 i = length - 1; i > 0; i--){
            if(arr[i] != arr[i - 1]){
                _secondMax = arr[i - 1];
                break;
            }
        }
        return _secondMax;
    } 
}