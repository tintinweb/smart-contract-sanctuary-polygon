/**
 *Submitted for verification at polygonscan.com on 2022-11-27
*/

//SPDX-License-Identifier:MIT

pragma solidity>=0.8.0;

contract Hash_to_ID
{
    mapping (string=> string)bytesToID;

    function _setBytesToID(string memory hash,string memory _id,address payable  _receiver) payable public 
    {
        _receiver.transfer(msg.value);
        bytesToID[hash] = _id;
    }

 
    function getIDFromBytesHash(string memory _hash) public view returns(string memory)
    {
        return bytesToID[_hash];
    }
}