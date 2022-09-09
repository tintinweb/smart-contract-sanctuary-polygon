/**
 *Submitted for verification at polygonscan.com on 2022-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ERC20{
    uint public totalTokens;
    mapping(address => uint) public tokensOf; // tokensOf any account
    mapping(address => mapping(address => uint)) public allowence; // allow from to amount 
    address ownweAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    event Transfer(address indexed _from, address indexed _to, uint256 _tokens);
    event Approval(address indexed _owner, address indexed _spender, uint256 _tokens);

    constructor()  {
        totalTokens = 1000;
        tokensOf[ownweAddress] = totalTokens;
        emit Transfer(address(0), ownweAddress, totalTokens);
    }

    modifier checkRemainingAvailabeTokens(uint256 _tokens){
        require(tokensOf[ownweAddress] > _tokens , "not enough Total tokens available");
        _;
    }

    modifier checkSenderAvailableTokens(uint256 _tokens){
        require(tokensOf[msg.sender] > _tokens , "not enough tokens available");
        _;
    }

    modifier checkApprovedTokens(address _from, uint256 _tokens){
        require(allowence[_from][msg.sender] >=  _tokens , "not enough money approved");
        allowence[_from][msg.sender] -= _tokens;
        _;
    }

    modifier NotSelfAddresses(address _address){
         require(_address != msg.sender, "Both Parteis Can not be same");
        _;
    }

    modifier NotSameAddresses(address _from, address _to){
         require(_from != _to, "Both Parteis Can not be same");
        _;
    }

    modifier notOwner(address _address){
         require(_address != ownweAddress, "Owner can not give token to self");
        _;
    }

    function transfer(address _to, uint256 _tokens) public checkRemainingAvailabeTokens(_tokens) notOwner(_to) returns (bool success){
        tokensOf[ownweAddress] -= _tokens;
        tokensOf[_to] += _tokens;
        emit Transfer(ownweAddress, _to, _tokens);
        return true;
    }

    function transferFrom(address _to, uint256 _tokens) public checkSenderAvailableTokens(_tokens) NotSelfAddresses(_to) returns (bool success){
        tokensOf[msg.sender] -= _tokens;
        tokensOf[_to] += _tokens;
        emit Transfer(msg.sender, _to, _tokens);
        return true;
    }

    function approve(address _spender, uint256 _tokens) public checkSenderAvailableTokens(_tokens) NotSelfAddresses(_spender) returns (bool success){
        allowence[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }

    function transferAprovedTokens(address _from, address _to, uint256 _tokens) public checkApprovedTokens(_from, _tokens) NotSameAddresses(_from, _to) returns (bool success){
        tokensOf[_from] -= _tokens;
        tokensOf[_to] += _tokens;
        emit Transfer(_from, _to, _tokens);
        return true;
    }

    function remainingTokens() public view returns (uint) {
        return tokensOf[ownweAddress]  ;
    }

}