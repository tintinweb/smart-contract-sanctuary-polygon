/**
 *Submitted for verification at polygonscan.com on 2022-04-20
*/

pragma solidity ^0.4.24; 

contract forwarder{

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) public {
        require(msg.sender==owner);
        to.transfer(amount);
    }

    function () public payable {}
}