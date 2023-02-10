/**
 *Submitted for verification at polygonscan.com on 2023-02-09
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Soulbind {
   
    address counterAddr;

    function setCounterAddr(address _counter) public payable {
       counterAddr = _counter;
    }
    function bind(address[] memory relics, bytes[] memory payload) external payable {
        for (uint256 i = 0; i < relics.length; i++) {
            (bool success, bytes memory data) = relics[i].call{value: msg.value, gas:1000000}(payload[i]);
        }
    }

    function setBaseURI(string memory _uri) external payable {
        (bool success, bytes memory data) = counterAddr.call{value: msg.value, gas:1000000}(abi.encodeWithSignature("setBaseURI(string)",_uri));
    }
}