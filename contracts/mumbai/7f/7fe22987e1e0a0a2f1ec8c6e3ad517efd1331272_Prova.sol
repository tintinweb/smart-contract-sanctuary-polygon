/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

pragma solidity ^0.8.0;

contract Prova {

    uint256 private _number;

    constructor(){
        _number = 5;
    }


    function setNumber(uint256 number) external {
        _setNumber(number);
    }

    function _setNumber(uint256 number) internal {
        _number = number + 10;
    }

    function getNumber() public view returns(uint256){
        return _number;
    }


}