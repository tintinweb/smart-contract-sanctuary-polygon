/**
 *Submitted for verification at polygonscan.com on 2022-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Cont2 {
    uint _time;
    constructor (){
        _time = block.timestamp;
    }

    function test() view public returns(uint) {
        return _time;
    }
}

contract DeployContractFromContract {
    uint mm;
    event Deployed(address a);

    function deploys(uint _salt) public returns(uint){
        Cont2 c2 = new Cont2{ 
            salt:bytes32(_salt)
            }();
        emit Deployed(address(c2));
        mm = c2.test();
        return mm;
    }
}