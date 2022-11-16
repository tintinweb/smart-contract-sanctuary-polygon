/**
 *Submitted for verification at polygonscan.com on 2022-11-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;


contract Token {
    string private _name = "ALYRA";
    string private _symbol = "ALY";

    // Variable global sauvegaradant la balances de chaque adresse
    mapping(address => uint) _balances;

    // Spec : récupération de x token
    function mint(uint _number) public {
        _balances[msg.sender] += _number;
    }

    // Spec : transfère de fond de l'appelant à la personne indiquée, d'un montant x 
    function transfer(address _to, uint _value) public {
        _balances[_to] += _value;
        _balances[msg.sender] -= _value;
    }


    // Spec : récupération des infos pour l'extérieur de la BC
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    } 
    function name() public view returns (string memory) {
        return _name;
    } 
    function symbol() public view returns (string memory) {
        return _symbol;
    } 

}