/**
 *Submitted for verification at polygonscan.com on 2022-09-25
*/

pragma solidity ^0.8.13;

contract sendEth {
    function sendGasTo(address payable _to) public payable {
        _to.transfer(msg.value);
    }
}