/**
 *Submitted for verification at polygonscan.com on 2022-11-12
*/

pragma solidity ^0.4.20;


// TestByteGo25 tokenhash: 0xd54f4e5386d1df51c16b2ccbef3f9e43b713f02966727f2931751f8c90ee0cc3

// 定义ERC-20标准接口
contract send{
    function transferArray(address[] _to, uint256 _value) payable public{
        for(uint256 i = 0; i < _to.length; i++){
            _to[i].transfer( _value);
        }
    }
}