/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract EtherSender4 {
    
    address owner;
    address signer1;
    address signer2;
    bool signer1aprov = false;
    bool signer2aprov = false;

    constructor(address _signer1, address _signer2) {
        owner = msg.sender;
        signer1 = _signer1;
        signer2 = _signer2;
    }
    
    function insertFunds() external payable {}

    function sign() external {
        
        if (msg.sender == signer1) {
            signer1aprov = true;
            
        } else if (msg.sender == signer2) {
            signer2aprov = true;

        } else {
            revert();
        } 
         
    }
    
    function send() external {
        
        if (address(this).balance > 0.001 ether && signer1aprov && signer2aprov) {
            
            (bool succes,) = owner.call { value : address(this).balance}("");
            require(succes, "Wrong");

            signer1aprov = false;
            signer2aprov = false;
          
        } else{
            revert();
        }
    }

    
}