/**
 *Submitted for verification at polygonscan.com on 2022-04-19
*/

pragma solidity ^0.8.0; 



contract PolyReceiver {

    address public lastOrigin = address(0); 
    constructor(){

    }

    function receiveMessage() public returns (address) {
        lastOrigin = address(tx.origin); 
        return tx.origin; 
    }


}