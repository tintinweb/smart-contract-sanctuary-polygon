/**
 *Submitted for verification at polygonscan.com on 2022-08-22
*/

pragma solidity ^0.8.0;


contract IPFSEvent {

    event CID(string cid);

    function sendIPFSHash(string memory cid) external {
        emit CID(cid);
    }

}

// 0x86102D54f28C6EACa8d36b049dD1290CF96B7C09