/**
 *Submitted for verification at polygonscan.com on 2022-02-05
*/

pragma solidity ^0.4.19;

contract Faucet {
    function withdraw_amount(uint amount) public {
        require(amount <= 100000000000000000);
        msg.sender.transfer(amount);
    }

    function() public payable {}
}