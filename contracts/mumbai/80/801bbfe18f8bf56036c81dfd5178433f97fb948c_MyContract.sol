/**
 *Submitted for verification at polygonscan.com on 2023-03-05
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract MyContract{

    address public owner;

    string public ownerName;

    constructor() {

        //owner
        owner  = msg.sender;

        ownerName = "Smartcontract-Polygon Network";

    }
    
    string class;
    //modifier to restrict contract address limit to creater

    modifier restricted() {

        require(msg.sender == owner, "Permission denied, Admin account only");

        _;

    }

    
  event d___h___2(
        
        address from, address to
        

    );

    function d___h___2Emitter (address from, address to) public restricted{

        emit d___h___2(from, to);

    }
}