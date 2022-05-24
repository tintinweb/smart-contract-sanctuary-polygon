/**
 *Submitted for verification at polygonscan.com on 2022-05-23
*/

pragma solidity ^0.8.14;

contract Test {
    function test(address _to) public payable {
        uint256 half = msg.value / 2;
        payable(_to).transfer(half);
    }

    function withdrawal() public payable {
        payable(msg.sender).transfer(address(this).balance);
    }
}