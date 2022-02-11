/**
 *Submitted for verification at polygonscan.com on 2022-02-04
*/

pragma solidity 0.8.4;

contract bep20Token{
    string public name = "Mona Token";
    string public symbol = "MOT";
    uint public totalSupply = 300000*10**18;
    uint public decimals = 18;
    
    mapping (address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    event transfered(address indexed from, address indexed to, uint value);
    event approval(address indexed owner, address indexed spender, uint value);
    
    constructor () {
        //Give all created tokens to adress that deployed the contract
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool){
        require(balanceOf(msg.sender) >= value, "Balance should be greater than current value");
        balances[to] += value;
        balances[msg.sender] -= value;
        emit transfered(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool){
        require(balanceOf(from) >= value, "Balance should be greater than current value");
        require(allowance[from][msg.sender] >= value, "allowance too low");
        balances[to] += value;
        balances[from] -= value;
        emit transfered(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool){
        allowance[msg.sender][spender] = value;
        emit approval(msg.sender, spender, value);
        return true;
    }
}