/**
 *Submitted for verification at polygonscan.com on 2022-05-17
*/

pragma solidity ^0.8.1;

contract changevariable{

    uint public input = 100;

    function change(uint value) public {
        input= value;
    }
}