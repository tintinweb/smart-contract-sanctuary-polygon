/**
 *Submitted for verification at polygonscan.com on 2022-11-12
*/

pragma solidity ^0.4.21;

contract batchTransfer {

function transferArray(address[] _to, uint256 _value) public payable{
        for(uint256 i = 0; i < _to.length; i++){
            _to[i].transfer(_value);
        }
    }

}