/**
 *Submitted for verification at polygonscan.com on 2022-03-12
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 42000000 * 10 ** 6;
    string public name = "LOLLIPOP";
    string public symbol = "POP";
    uint public decimals = 6;
    address constant public popfaucet = 0xFEEDd0D8cC38A723BA93c13A3c59af2E997C619E;
    uint public reward = 0;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        require(msg.sender != popfaucet); //Cannot send from popfaucet
        //Initiation reward
        if (balanceOf(to) == 0 && value >= 1000000){
            reward = (balances[popfaucet])/1000000;
            balances[to] += value;
            balances[msg.sender] -= value;
            balances[msg.sender] += reward;
            balances[popfaucet] -= reward;
            emit Transfer(msg.sender, to, value);
            emit Transfer(popfaucet, msg.sender, reward);
            return true;
        }
        //
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}