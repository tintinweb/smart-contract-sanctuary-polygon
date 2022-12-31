/**
 *Submitted for verification at polygonscan.com on 2022-12-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function goal() external view returns (uint256);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function wallets() external view returns (address[] memory);

    //Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    function investment() external payable;

    function refund() external payable;

    function getFinance() external payable;

    function _beforeTokenTransfer() external;

    event InvestmentDone(address indexed _to, uint256 indexed _amount);

    event RefundDone(address indexed _to, uint256 _amount);

    event FinanceCreated(address indexed _to, uint256 _amount);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

contract ERC20 is Context, IERC20{
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _goal;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address private admin;
    address[] private _wallets;

    constructor (string memory name_, string memory symbol_, uint256 goal_) {
        _name = name_;
        _symbol = symbol_;
        _goal = goal_ * 10**uint(decimals());
        admin = _msgSender();
    }

    modifier onlyOwner(){
        require(admin == msg.sender, "not owner");
        _;
    }

    // Returns the name of the token.
    function name() public view virtual returns (string memory) {
        return _name;
    }

     // Returns the symbol of the token.
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    // Returns the amount to reach the goal.
    function goal() public view virtual returns (uint256){
        return _goal;
    }
    
    //Returns the number of decimals used to get its user representation.
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    // See {IERC20-totalSupply}.
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    // Return the addresses that invested.
    function wallets() public view virtual returns (address[] memory){
        return _wallets;
    }

    // See {IERC20-balanceOf}.
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function investment() public payable{
        require(msg.value > 0,"Insuficient balance");

        _beforeTokenTransfer();
        _totalSupply += msg.value;
        _balances[_msgSender()] += msg.value;
    }

    //The Ethereum balance is refunded with tokens, the tokens are pratically burned.
    function refund() public payable{
        require(_totalSupply >= _balances[_msgSender()] && _totalSupply != 0 && _balances[_msgSender()] > 0,"Insuficient balance to refund");
        require(_goal > _totalSupply,"You reached the goal");

            //The transfer is not paid in wei, gwei or finney but in Ethereum
        payable(_msgSender()).transfer(_balances[_msgSender()]);

        _totalSupply -= _balances[_msgSender()];
        _balances[_msgSender()] -= _balances[_msgSender()];

        emit RefundDone(_msgSender(), _balances[_msgSender()]);
    }

    function getFinance() public payable onlyOwner{
        require(_goal <= _totalSupply,"You didn't reach the goal");

        payable(admin).transfer(_totalSupply);

        _totalSupply -= _totalSupply;
        
        emit FinanceCreated(admin, _totalSupply);
    }

    //Hooks are to include some information before the investor put his money in the finance project, this is optional.
    function _beforeTokenTransfer() public { 
    }
}