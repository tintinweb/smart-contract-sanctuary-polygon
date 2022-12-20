/**
 *Submitted for verification at polygonscan.com on 2022-12-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// ball janitor alone pigeon drop knife minor mandate tip january column only order butter damp cherry
contract Collect {

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        require(msg.value == 1 ether, "please send two ether");
    }

    function withdraw() external {
        require(msg.sender == owner, "No");
        // payable(msg.sender).transfer(address(this).balance);
        
        (bool sent, ) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function withdrawto(address receiver) external {
        // require(msg.sender == owner, "No");
        // payable(msg.sender).transfer(address(this).balance);
        
        (bool sent, ) = receiver.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    // this is observable without help from the contract, could be left out or included as a courtesy

    function balance() external view returns(uint balanceEth) {
        balanceEth = address(this).balance;
    }
}