/**
 *Submitted for verification at polygonscan.com on 2023-05-05
*/

pragma solidity ^0.8.0;

contract Example {
    uint []a;
    function updateValues() public returns (uint) {
        uint[] memory aa = new uint[](2);
        uint[] memory b = new uint[](1);
        
        a[0] = 10;
        a[1] = 20;
        b[0]=a.push();
        //b[0] = a[0];
        
        a[0] = 14; // Update the value of a[0]
        return b[0];
        // The value of b[0] will also be updated to 14
        //require(b[0] == 0);
    }
}