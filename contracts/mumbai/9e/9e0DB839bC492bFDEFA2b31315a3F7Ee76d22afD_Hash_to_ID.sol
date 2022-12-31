/**
 *Submitted for verification at polygonscan.com on 2022-12-30
*/

//SPDX-License-Identifier:MIT

pragma solidity>=0.8.0;

contract Hash_to_ID
{
    mapping (string=> uint256)hash_to_id;
    mapping (bytes32=> uint256)bytesToID;

    function _setBytesToID(bytes32 hash,uint256 _id)public 
    {
        bytesToID[hash] = _id;
    }

    function _setStringToID(string memory hash,uint256 _id)public
    {
        hash_to_id[hash] = _id;
    }

    function getIDFromStringHash(string memory hash)public view returns(uint256)
    {
        return hash_to_id[hash];
    }
 
    function getIDFromBytesHash(bytes32 _hash) public view returns(uint256)
    {
        return bytesToID[_hash];
    }
}