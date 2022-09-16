/**
 *Submitted for verification at polygonscan.com on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
contract Taller1 {
    
    struct _metadata {
        string data;
        uint256 value;
    }

    mapping (address=>_metadata) public _Data;

    constructor()  {
       _Data[msg.sender] = _metadata("Hola Satoshi",0);
    }
    
    function getData(address _onwer) external view returns (_metadata memory) {
        return (_Data[_onwer]);
    }

    function setData(string memory _s_data, uint256 _value) public {
        
        _Data[msg.sender] = _metadata(_s_data,_value);
    }
}