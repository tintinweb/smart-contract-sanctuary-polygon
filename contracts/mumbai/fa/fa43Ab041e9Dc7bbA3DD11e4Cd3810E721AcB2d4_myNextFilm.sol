/**
 *Submitted for verification at polygonscan.com on 2022-09-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;
contract myNextFilm {
    address Owner;    
    mapping(bytes32 =>mapping(string=>string)) public preview;       //preview[email][_previewName] = uri
    
    constructor(){
        Owner = msg.sender;
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == Owner,"Only Mnf can call this function");
        require(newOwner != address(0), "Ownable: new owner is the zero address");        
        Owner = newOwner;
    }
   
    function createPreView(bytes32 _EncryptEmail,string memory _previewName, string memory _url) public{
        require(msg.sender == Owner,"Only Mnf can call this function");
        preview[_EncryptEmail][_previewName] = _url;
    }
    
}