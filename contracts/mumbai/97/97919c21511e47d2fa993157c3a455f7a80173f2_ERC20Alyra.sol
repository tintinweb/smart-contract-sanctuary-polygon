/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

pragma solidity 0.8.16;

contract ERC20Alyra {
    //Identification du token - Standard ERC 20
    string _name = "ALYRA";
    string _symbol = "ALY";
    uint _decimal = 18;


    //Spec : stocker la valeur
    mapping(address => uint) balances;

    //Spec : transfert de la valeur
    function transfer(address _to, uint _value) public {
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
    }

    //Spec : création de token
    function mint(uint _value) public {
        balances[msg.sender] = balances[msg.sender] + _value;
    }

    //Spec : Récupérer la balance d'une adresse spécifique
    function balanceOf(address _adr) public view returns (uint){
        return balances[_adr];
    }    



    //Identification du token - Standard ERC 20
    function name() public view returns (string memory){
        return _name;
    }
    function symbol() public view returns (string memory){
        return _symbol;
    }
    function decimal() public view returns (uint){
        return _decimal;
    }


}