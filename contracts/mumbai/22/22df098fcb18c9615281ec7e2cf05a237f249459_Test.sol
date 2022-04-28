/**
 *Submitted for verification at polygonscan.com on 2022-04-27
*/

pragma solidity >=0.7.0 <0.9.0;

contract Test {
    event Test1(uint256 a, uint256 b);
    event Test2(address account);

    function set1() public {
        emit Test1(1, 2);
    }

    function set2() public {
        emit Test2(msg.sender);
    }
}