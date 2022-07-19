/**
 *Submitted for verification at polygonscan.com on 2022-07-18
*/

//SPDX-License-Identifier:MIT
pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
}

contract Dev721 is IERC20{
    string _name;
    string _symbol;
    uint8 _decimals=18;
    uint256 _totalsupply;
    mapping(address=>uint256) accounts;
    mapping(address=>mapping(address=>uint256)) _allowance;

    constructor(string memory token_name,string memory token_symbol,uint256 total_supply){
        _name=token_name;
        _symbol=token_symbol;
        _totalsupply=total_supply*(10**18);
        accounts[msg.sender]=total_supply*(10**18);
    }

    function name() public view override returns(string memory){return _name;}
    function symbol() public view override returns(string memory){return _symbol;}
    function decimals() public view override returns(uint8){return _decimals;}
    function totalSupply() public view override returns(uint256){return _totalsupply;}
    function balanceOf(address account) public view override returns(uint256){return accounts[account];}
    function allowance(address owner, address spender) public view override returns (uint256){return _allowance[owner][spender];}

    function transfer(address to,uint256 amount) public override returns(bool){
        require(accounts[msg.sender] >= amount,"not enough balance");
        accounts[to]+=amount;
        accounts[msg.sender]-=amount;
        emit Transfer(msg.sender,to,amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool){
        require(amount >= accounts[msg.sender],"not enough balance to approve");
        require(spender != address(0),"can not approve allowance to null address");
        
        _allowance[msg.sender][spender]=amount;
        emit Approval(msg.sender , spender , amount);
        
        return true;
    }

    function transferFrom(address from,address to,uint256 amount) public override returns (bool){
        require(_allowance[from][to] >= amount,"not enough allowance");
        
        _allowance[from][to]-= amount;
        emit Approval(from,to,_allowance[from][to]-amount);        
        
        accounts[to]+=amount;
        accounts[from]-=amount;
        emit Transfer(from,to,amount);
        
        return true;
    }
}