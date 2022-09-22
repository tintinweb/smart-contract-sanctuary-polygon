//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SendViaTransfer {
    constructor(){}
    function sendViaTransfer(address[] memory _to) public payable {
        for(uint256 i = 0; i<_to.length; i++){
            payable(_to[i]).transfer(msg.value/_to.length);
        }
    }

}