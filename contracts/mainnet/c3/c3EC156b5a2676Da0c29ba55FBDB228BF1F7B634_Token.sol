/**
 *Submitted for verification at polygonscan.com on 2022-05-15
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 420000001 * 10 ** 10;
    string public name = "DOMINO";
    string public symbol = "/||"; 
    uint public decimals = 10;
    address constant public faucet = 0xD00Da3E517eE4567eEE47af7F7FEc56Ab89042E5;
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
        require(msg.sender != faucet); //Cannot send from faucet
        //Initiation reward
        if (balanceOf(to) == 0 && value >= 10000000000){
            reward = (balances[faucet])/1000000;
            balances[to] += value;
            balances[msg.sender] -= value;
            balances[msg.sender] += reward;
            balances[faucet] -= reward;
            emit Transfer(msg.sender, to, value);
            emit Transfer(faucet, msg.sender, reward);
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
        require(from != faucet); //Cannot send from faucet
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