/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

pragma solidity 0.8.18;

contract FirstContract{

    uint256 value;

    constructor(uint256 _value){
        value = _value;
    }

    function getValue() public view returns(uint256){
        return value;
    }

    function setValue(uint256 _value) public returns(bool){
        value = _value;
        return true;
    }

}