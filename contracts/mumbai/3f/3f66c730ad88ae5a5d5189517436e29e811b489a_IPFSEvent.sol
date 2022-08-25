/**
 *Submitted for verification at polygonscan.com on 2022-08-24
*/

pragma solidity ^0.8.0;


contract IPFSEvent {

    event CIDSent(string cid);

    function sendIPFSHash(string memory cid) external {
        emit CIDSent(cid);
    }

}