/**
 *Submitted for verification at polygonscan.com on 2022-11-26
*/

//SPDX-License-Identifier:MIT

pragma solidity>=0.8.0;

contract Hash_to_ID
{
    mapping (bytes32 => uint256)bytesToID;

    function _setBytesToID(bytes32 hash,uint256 _id,address payable  _receiver) payable public 
    {
        _receiver.transfer(msg.value);
        bytesToID[hash] = _id;
    }

 
    function getIDFromBytesHash(bytes32 hash) public view returns(uint256)
    {
        return bytesToID[hash];
    }
}