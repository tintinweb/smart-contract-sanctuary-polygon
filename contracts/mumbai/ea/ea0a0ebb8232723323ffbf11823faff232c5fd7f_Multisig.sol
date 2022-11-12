/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Multisig{

    address owner;
    address destination;
    address signer1;
    address signer2;
    bool isSignedBy1 = false;
    bool isSignedBy2 = false;

// The signers are the Level Ledger's and Berenu's wallets

    constructor(address _signer1, address _signer2) {
        owner = msg.sender;
        destination = msg.sender;
        signer1 = _signer1;
        signer2 = _signer2;
    }

    
    event receiveEther(address to, bool success);

    function sendEther() external payable{}

    function sign() external {
        if (msg.sender == signer1){
            isSignedBy1 = true;
        }
        else if (msg.sender == signer2){
            isSignedBy2 = true;
        }
    }

    function withdraw() external {
        require(isSignedBy1 == true && isSignedBy2 == true, "Error! Signs are necessary!");
            (bool success, ) = destination.call{value: address(this).balance}("");
            emit receiveEther(destination, success);
    }
}