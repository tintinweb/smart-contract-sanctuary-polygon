/**
 *Submitted for verification at polygonscan.com on 2022-06-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Sumar {

    uint result;
    event onResult(uint _result);

    function sumar(uint numero1, uint numero2) public returns (uint) {
        result = numero1 + numero2;
        emit onResult(result);
        return result;
    }



}