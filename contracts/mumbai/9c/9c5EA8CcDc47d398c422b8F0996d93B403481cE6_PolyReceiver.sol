/**
 *Submitted for verification at polygonscan.com on 2022-04-19
*/

pragma solidity ^0.8.0; 



contract PolyReceiver {
    constructor(){

    }

    function receiveMessage() public returns (address) {
        return tx.origin; 
    }


}