/**
 *Submitted for verification at polygonscan.com on 2023-06-22
*/

pragma solidity 0.8.17;



contract ERC20Token {

    // Identifer la valeur - le token

    function decimals() public view returns (uint8){
        return 0;
    }

    function symbol() public view returns (string memory){
        return "ALY";
    }

    function name() public view returns (string memory){
        return "AlyraToken";
    }

    function totalSupply() public view returns (uint256){
        return totalsupply;
    }

    // Stockage du total supply
    uint totalsupply;


    // Stockage de valeur
    mapping (address => uint) balances;

    // Transfer
    function transfer(address to, uint value) public {
        balances[msg.sender] = balances[msg.sender] - value;
        balances[to] = balances[to] + value;
    }

    //Récupere la balance de l'adresse
    function balanceOf(address adr) public view returns (uint){
        return balances[adr];
    }

    function mint(uint value) public {
        totalsupply += value;
        balances[msg.sender] = balances[msg.sender] + value;
    }

}