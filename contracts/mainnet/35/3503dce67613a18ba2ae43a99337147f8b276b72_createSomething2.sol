/**
 *Submitted for verification at polygonscan.com on 2022-06-15
*/

pragma solidity ^0.7.0;

contract createSomething2 {
    event Received(address, uint);
    event notReceived(address, uint);
        
    function kill(address payable addr) public payable {
        selfdestruct(addr);
    }
    
    function deposit() public payable {
        
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}