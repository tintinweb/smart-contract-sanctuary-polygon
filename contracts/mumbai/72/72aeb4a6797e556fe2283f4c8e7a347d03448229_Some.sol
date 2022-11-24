/**
 *Submitted for verification at polygonscan.com on 2022-11-23
*/

pragma solidity ^0.8.0;

contract Some{

    address public owner;

    constructor (){
        owner = msg.sender;
    }

    event EventPessoa(string indexed nome,uint indexed idade);

    struct Pessoa{
        string Nome;
        uint Idade;
    }

    mapping(address => Pessoa[]) public MapStructArray;

    modifier OnlyOwner(){
        require(owner == msg.sender,"not owner of contract");
        _;
    }

    function SetArray(string memory _nome,uint _idade) public OnlyOwner {
        MapStructArray[msg.sender].push(Pessoa({
            Nome: _nome,
            Idade: _idade
        }));

        emit EventPessoa(_nome,_idade);
    }


}