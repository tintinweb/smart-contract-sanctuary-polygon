/**
 *Submitted for verification at polygonscan.com on 2022-09-15
*/

pragma solidity ^0.8.7;
contract doTest {
    uint public counter1 = 1;
    uint public counter2 = 1000;
    uint public counter3 = 10000;
    uint public counter4 = 100000;
    function executeFunc () external {
        counter1++;
        counter2++;
        counter3++;
        counter4++;
    }
}