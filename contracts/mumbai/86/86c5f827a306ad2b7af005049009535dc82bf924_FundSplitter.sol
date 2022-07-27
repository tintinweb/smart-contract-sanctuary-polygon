/**
 *Submitted for verification at polygonscan.com on 2022-07-26
*/

pragma solidity ^0.8.15;

contract FundSplitter {
    address payable [] public receiver;
    event TransferReceived(address _from, uint _amount);

    constructor(address payable [] memory _address) {
        for(uint i=0; i<_address.length; i++) {
            receiver.push(_address[i]);
        }
    }
    receive() payable external {
        uint256 share = msg.value / receiver.length;
        for (uint i=0; i < receiver.length; i++) {
            receiver[i].transfer(share);
        }
        emit TransferReceived(msg.sender, msg.value);
    }
}