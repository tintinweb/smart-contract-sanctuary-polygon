/**
 *Submitted for verification at polygonscan.com on 2022-06-17
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


interface ERC20{
    function _totalSupply() external view returns (uint256);
    function _balanceOf(address _owner) external view returns (uint256 balance);
    function _transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function _approve(address _spender, uint256 _value) external returns (bool success);
    function _allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract EternalProxy {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public pure returns (string memory){
        return "Eternal Token v2";
    }

    function symbol() public pure returns (string memory){
        return "ETRN";
    }

    function decimals() public pure returns (uint8){
        return 18;
    }

    function totalSupply() public view returns (uint256){
        return proxy._totalSupply();
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return proxy._balanceOf(_owner);
    }

    function getOwner() external view returns (address){
        return owner;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if(proxy._transferFrom(msg.sender, _to, _value)){
            emit Transfer(msg.sender, _to, _value);
            return true;
        }

        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if(proxy._transferFrom(_from, _to, _value)){
            emit Transfer(_from, _to, _value);
            return true;
        }

        return false;
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        proxy._approve( _spender, _value);

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return proxy._allowance(_owner, _spender);
    }

    address owner;
    ERC20 proxy;
    address proxyAddress;

    constructor(){
        owner = msg.sender;
    }

    function setProxy(address _proxy) public{
        require(msg.sender == owner);
        proxy = ERC20(_proxy);
        proxyAddress = _proxy;
    }

    function proxyType() public pure returns (uint256 proxyTypeId){
        return 2;
    }

    function implementation() public view returns (address codeAddr){
        return proxyAddress;
    }

}