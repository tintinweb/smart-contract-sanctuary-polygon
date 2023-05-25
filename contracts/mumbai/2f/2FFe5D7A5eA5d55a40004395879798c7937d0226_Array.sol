/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

pragma solidity >=0.8.0 <0.8.20;

contract Array {

    uint[] array;

    function setArray(uint[] calldata _array) public  {
        array = _array;
    }

    function whatValue(uint _n) public view returns(uint){
        return  array[_n];
    }
}


// setArray must be called with data in the following format 
// ["1","2","3"]