/**
 *Submitted for verification at polygonscan.com on 2022-11-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract token {
    
    // Variables
    string _name = "NICO";
    string _symbol = "NWA";
    
    // variable globale pour le stockage de la valeur ETH
    mapping(address => uint) _balances;
    uint _totalsupply;
    
    function mint(uint _number) public {
        _balances[msg.sender] = _balances[msg.sender] + _number;
        _totalsupply = _totalsupply + _number;
    }
    
        function transfert(address _to, uint _number) public{
        _balances[msg.sender] = _balances[msg.sender] - _number;
        _balances[_to] = _balances[_to] + _number;
    }
    
    function balanceOf(address _adr) public view returns (uint){
        return _balances[_adr];
    }

    function total_supply() public view returns (uint){
        return _totalsupply;
    }
    
    function name() public view returns (string memory){
        return _name;
    }
        
    function symbol() public view returns (string memory){
        return _symbol;
    }
}