/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract EtherSender4 {
    
    address owner = 0xA9ff4017F09b35F3F6c5554Aec0E20E91cFcDA5a;
    address signer1 = 0x23169b7B7f13Fd1428bA0A462F58E31f9DF9357d;
    address signer2 = 0x8Ab4d89CA5564D828Af77b32628761d6CD20CBCf;
    bool signer1aprov = false;
    bool signer2aprov = false;

    function insertFounds() external payable {}

    function sign(address _signer) external {
        
        if (_signer == signer1) {
            signer1aprov = true;
            
        } else if (_signer == signer2) {
            signer2aprov = true;
        }
         
    }
    
    function send() external {
        
        if (address(this).balance > 0.001 ether && signer1aprov && signer2aprov) {
            
            (bool succes,) = owner.call { value : address(this).balance}("");
            require(succes, "requirements are missing");

            signer1aprov = false;
            signer2aprov = false;
        }
    }

    
}