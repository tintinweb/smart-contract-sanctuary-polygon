/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File contracts/Token.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2 <0.9.0;



contract Token {

    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    mapping(address => uint) internal balance;
    mapping(address => mapping(address => uint)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint indexed _amount);
    event Approval(address owner, address spender, uint amount);


    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = msg.sender;

        mint(100_000 * 10 ** decimals);
    }


    function mint(uint amount) public onlyOwner{
        balance[owner] += amount;
        totalSupply += amount;

        emit Transfer(address(0), owner, amount);
    }


    function balanceOf(address _owner) external view returns(uint){
        return balance[_owner] / 10 * decimals;
    }


    function transfer(address to, uint amount) external returns(bool success){
        balance[msg.sender] -= amount;
        balance[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }


    function transferFrom(address from, address to, uint amount) external returns(bool success) {
        allowance[from][msg.sender] -= amount;
        balance[from] -= amount;
        balance[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }


    function approve(address spender, uint amount) external returns(bool success) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function burn(uint amount) external onlyOwner{
        balance[owner] -= amount;
        totalSupply -= amount;
        emit Transfer(owner, address(0), amount);
    }


    modifier onlyOwner(){
        require(owner == msg.sender, "Token: Only owner!");
        _;
    } 

}