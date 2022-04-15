/**
 *Submitted for verification at polygonscan.com on 2022-04-14
*/

pragma solidity ^0.8.0;


contract TEST {

    uint256 public val;

/// @notice Hapur:ae ka hai.
    function set() public {

        if(val > 0){
            delete val;
           // console.log(val);
        }
        else{
            revert("dfdd");
        }
    }
}