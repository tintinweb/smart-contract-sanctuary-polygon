/**
 *Submitted for verification at polygonscan.com on 2023-06-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

contract Token {
    //Spec : Variables globals identifiant le token
    string _name = "ALYRA";
    string _symbol = "ALY";

    //Spec : Variable global sauvegardant la balance de chaque adresse
    mapping(address => uint) _balances;

    //Spec : fonction de création de x token
    function mint(uint _number) public {
        _balances[msg.sender] += _number;
    }

    //Spec : fonction de transfert de fond de l'appelant vers la personne indiquée, d'un monntant x
    function transfer(address _to, uint _value) public {
        _balances[_to] += _value;
        _balances[msg.sender] -= _value;
    }

    //Spec : fonction de récupération des infos de la balance
    function balanceOf(address _account) public view returns (uint256){
        return _balances[_account];
    }

    //Spec : fonction de récupération des infos de nom (necessaire selon le standard ERC 20)
    function name() public view returns (string memory){
        return _name;
    }
    //Spec : fonction de récupération des infos de symbole (necessaire selon le standard ERC 20)
    function symbol() public view returns (string memory){
        return _symbol;
    }
    //Spec : fonction de récupération des infos de décimal (necessaire selon le standard ERC 20)
    function decimals() public pure returns (uint8) {
        return 18;
    }

}