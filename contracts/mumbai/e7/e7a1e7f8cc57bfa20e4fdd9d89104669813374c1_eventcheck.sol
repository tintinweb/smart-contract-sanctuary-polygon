/**
 *Submitted for verification at polygonscan.com on 2022-04-04
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.12;

contract eventcheck{
    event NotEven();
    error NotEvenErr();

    function isEven(uint number) public  returns (bool){
        if (number % 2 != 0 ) {
            emit NotEven();
            return false;
            }
        return true;
    }

    function isEvenErr(uint number) public pure returns (bool){
        if (number % 2 != 0 ) revert NotEvenErr();
        return true;
    }

    function isEvenRevert(uint number) public  returns (bool){
        if (number % 2 != 0 ) revert("isEvenRevert: Not a Even number");
        return true;
    }

    function isEvenRequire(uint number ) public  returns(bool){
        require(number % 2 != 0,"isEvenRequire: Not a Even Number");
        return true;
    }

    function isEvenRequirePure(uint number ) public pure returns(bool){
        require(number % 2 != 0,"isEvenRequirePure: Not a Even Number");
        return true;
    }


}