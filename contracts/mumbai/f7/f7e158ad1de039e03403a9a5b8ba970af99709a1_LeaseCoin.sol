/**
 *Submitted for verification at polygonscan.com on 2023-04-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >0.8.0;
 

contract LeaseCoin {

    string public name;
    string public symbol;
    uint8 public decimals =0;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;

    mapping (address => mapping (address=>uint256)) public allowance;

    constructor (string memory name_, string memory symbol_,uint256 _initialSupply) {
        name= name_;
        symbol= symbol_;
        _mint(msg.sender,_initialSupply * (10**decimals));

    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender]>=_value,"Insufficient balance");
        _burn(msg.sender,_value);
        _mint(_to,_value);
        success=true;
        emit Transfer(msg.sender,_to,_value);
    }

    function _mint(address _receipant, uint256 _value) internal {  
        balanceOf[_receipant]+=_value;
        totalSupply+=_value;
    }

    function _burn(address _from, uint256 _value) internal {  
        balanceOf[_from]-=_value;
        totalSupply-=_value;

    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(allowance[_from][_to]>=_value, "Insufficient Allowance");
        require(balanceOf[_from]>=_value, "Insufficient balance");
        allowance[_from][_to]-=_value;
        _burn(msg.sender,_value);
        _mint(_to,_value);

        success=true;        
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender]=_value;
        success=true;
        emit Approval(msg.sender,_spender,_value);
    }



}