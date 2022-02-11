/**
 *Submitted for verification at polygonscan.com on 2022-02-08
*/

pragma solidity ^0.8.0;

contract BatchSender {
    function batchSend(address payable[] memory _addresses, uint256 _amount) public payable {
        for (uint256 i = 0; i <= _addresses.length; i++) {
            _addresses[i].transfer(_amount);
        }
        payable(msg.sender).transfer(address(this).balance);
    }
}