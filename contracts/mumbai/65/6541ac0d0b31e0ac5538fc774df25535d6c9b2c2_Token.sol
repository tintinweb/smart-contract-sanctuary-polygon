// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Token is Context, IERC20, Ownable{

    
    constructor () {
         _transferOwnership(_msgSender());
        balances[owner()] = _totalSupply;
    }
    string private constant _name = "TokenTest";
    string private constant _symbol = "TTS";
    uint256 private constant _decimals = 12;
    uint256 private _totalSupply = 21e18;

    mapping (address => uint256) balances;
    mapping (address => mapping(address => uint256)) allowances;


    
    using SafeMath for uint256;

   function name () public view returns (string memory){
        return _name;
   }
   function symbol () public view returns (string memory){
        return _symbol;
   }
   function decimals () public view returns (uint256){
        return _decimals;
   }
    function increaseSupply (uint256 amountToBeIncreased) external onlyOwner returns (bool) {
        _totalSupply.add(amountToBeIncreased);
        balances[owner()].add(amountToBeIncreased);
        return true;
    }
    function _transfer (address from, address to, uint256 amount) internal {
        require(from != address(0), "TTS: transfer should not be done by contract addresses");
        require(to != address(0), "TTS: token should not be sent to contracts: try approve");
        uint256 fromBalance = balances[from];
        require(fromBalance >= amount, "TTS: you do not have enough tokens");
        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(from, to, amount);
    }
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf (address account) external override view returns (uint256) {
        return balances[account];
    }
    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }
    function approve (address spender, uint256 amount) external override returns (bool) {
        address userAddress = _msgSender();
        require(userAddress != address(0), "TTS: contracts addreses should not approve");
        require(spender != address(0), "TTS: token should not be sent to contracts");
        uint256 userBalance = balances[_msgSender()];
        require(amount >= userBalance, "TTS: you do not have enough tokens");
        allowances[userAddress][spender].add(amount);
        emit Approval(userAddress, spender, amount);
        return true;
        
        
    }
    function transferFrom (address from, address to, uint256 amount) external override returns (bool){
        address spender = _msgSender();
        allowances[from][spender] = allowances[from][spender].sub(amount);
        _transfer(from, to, amount);
        emit Transfer(from, to, amount);
        return true;
    }
    function allowance (address owner, address spender) external override view returns (uint256){
        return allowances[owner][spender];
    }
    
}