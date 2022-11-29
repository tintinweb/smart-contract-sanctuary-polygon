/**
 *Submitted for verification at polygonscan.com on 2022-11-29
*/

pragma solidity >=0.7.0 <0.9.0;


contract Callee {
    error OrderAlreadyFilled();

    uint256 public data;

    function buy(uint256 _data) public {
        revert OrderAlreadyFilled();
    }

    function buyV2(uint256 _data) public {
        data = _data;
    }
}