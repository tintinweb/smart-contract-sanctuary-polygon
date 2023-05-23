/**
 *Submitted for verification at polygonscan.com on 2023-05-22
*/

pragma solidity ^0.8.9;

contract Counter {
    uint256 public count;

    event updateCount(uint newCount);

    function incrementCount() public returns(uint256) {
        count +=1;
        emit updateCount(count);
        return count;
    }
}