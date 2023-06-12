/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

// SPDX-License-Identifier: MIT
//pragma solidity ^0.8.0;

pragma solidity >=0.7.0 <0.9.0;

contract p_flow {
    bool public dummy;
    
    bool public paused;

    // event Paused(address indexed sender, bytes extraData);
    event Paused(address indexed sender);
    event Unpaused(address indexed sender);

    // function pause(bytes memory extraData) public 
    // {
    //     paused = true;
    //     extraData  = extraData;
    //     emit Paused(msg.sender, extraData);
    // }
    function pause() public 
    {
        paused = true;
        emit Paused(msg.sender);
    }
    
    function unpause() public 
    {
        paused = false;
        emit Unpaused(msg.sender);
    }
    function mysSecuredFunc() public 
    {
        dummy = true;
    }
}