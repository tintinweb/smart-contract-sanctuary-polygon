/**
 *Submitted for verification at polygonscan.com on 2023-06-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
interface IERC20{
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals()external view returns(uint8);
    function totalsupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256 balance); 
    function transfer(address to,uint256 amount) external returns(bool success);
    function transferFrom(address from,address to,uint256 amount) external returns(bool success);
    function approve(address spender,uint256 amount)external returns (bool success);
    function allowance(address owner,address spender) external returns(uint256 remaining);    
}



contract Mytoken  {

    string public name ="Sudo Token";
    string public symbol= "SUDO";
    uint256 public decimals = 9;
    uint256 public initialsupply = 100000 * 10 * 1e9;
    uint256 public totalsupply = 1000000 * 10 * 1e9;

    address public owner;
    address public minter;
   
   
   uint256 public maxtxn = totalsupply / 10000 ;
   uint256 public  maxwallet=(totalsupply * 5)/100;

    bool public paused;
    mapping (address=>uint256) private balances;
    mapping (address=>mapping (address=>uint256)) private allowed;
    mapping(address=>bool) public Maxwallet;
    mapping(address=>bool) public blacklist;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    constructor(){
       owner = msg.sender;
    //    balances[msg.sender] = totalsupply;
    }
    modifier onlyminter(){
        require(msg.sender == minter,"Minter: caller is not the Minter");
        _;
    }
     modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

     function setPaused(bool _paused) onlyOwner public {
        paused = _paused;
    }

      function addToBlacklist(address account) public  {
        blacklist[account] = true;
    }

    function removeFromBlacklist(address account) public  {
        blacklist[account] = false;
    }

    function isBlacklisted(address account) public view returns (bool) {
        return blacklist[account];
    }
    function balanceOf(address _owner) view public returns (uint256) {
        return balances[_owner];
    }
    function allowance(address _owner, address _spender) view public returns (uint256) {
      return allowed[_owner][_spender];
    }
    function mint(address account, uint256 amount) public onlyminter  {
        require(totalsupply + amount <= totalsupply, "Exceeds total supply");
        balances[account]+=amount;
        totalsupply+=amount;
    }

    function burn(address to,uint256 amount) public onlyminter {
        balances[to]-=amount;
        totalsupply-=amount;
    }
    function transfer(address _to, uint256 _amount) public returns (bool success) {
       
        
        require( _amount <=maxtxn , "BEP20: amount can not be zero");
        require (balances[_to] +_amount<=maxwallet, "BEP20: user balance is insufficient");
       
        require(blacklist[_to]!=true,"the user is blacklisted");
        
       
        emit Transfer(msg.sender,_to, _amount);
        
        return true;
    }
}