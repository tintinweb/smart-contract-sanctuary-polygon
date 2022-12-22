// SPDX-License-Identifier: MIT

// Try to hack this contract 
// the challenge is to force this  
// contract to receive eth (mumbai test net)
// Hint: create another contract to attack this one.
// After you can send eth (mumbai test net) to this contract 
// call the withdraw function and you will receive the eth to your wallet.



pragma solidity ^0.6.0;

contract Target {

    function withdraw() public {
        require(address(this).balance !=0 wei, "Failed");
        msg.sender.transfer(address(this).balance);
    }
}