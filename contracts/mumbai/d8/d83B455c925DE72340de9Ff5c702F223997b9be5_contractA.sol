/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

pragma solidity 0.8.7;



contract contractA {

    string public str;
    uint public num;


    function setString(string memory newString) public {
        str = newString;
    } 
    function setNum(uint newNum) public {
        num = newNum;
    }
    function setBoth(string memory newString, uint newNum) public {
        str = newString;
        num = newNum;
    }



}