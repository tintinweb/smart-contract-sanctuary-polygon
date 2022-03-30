/**
 *Submitted for verification at polygonscan.com on 2022-03-29
*/

pragma solidity ^0.8.0;
contract Revert1{
    function f() public {
        revert("revert1");
    }
}

contract Revert2{
    function f() public{
        revert("revert2");
    }
}

contract TestRevert {
Revert1 r1;
Revert2 r2;
constructor() public{
    r1=new Revert1();
    r2=new Revert2();
}

function f() public{
    address(r1).call{value: 0}(msg.data);
    address(r2).call{value: 0}(msg.data);
}

function test() public payable{
    address(msg.sender).call{value: msg.value}(msg.data);
}
}