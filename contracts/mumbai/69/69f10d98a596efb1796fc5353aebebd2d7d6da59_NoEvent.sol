/**
 *Submitted for verification at polygonscan.com on 2022-11-26
*/

pragma solidity >=0.7.0 <0.9.0;


contract NoEvent {

    uint256 public val;

    function updateVariable(uint256 _val) public {
        val = _val;
    }

}