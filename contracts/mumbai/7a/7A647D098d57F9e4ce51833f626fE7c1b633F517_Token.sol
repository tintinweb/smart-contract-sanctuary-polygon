// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Token {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    address _owner;

    mapping (address => uint256) balances; // Tracker for tha balances
    mapping (address => mapping (address => uint256)) _allowance; //Tracker for allowances

    // Transfer event is emitted when any token transfer happens
    event TransferEvent(
        address from,
        address to,
        uint256 amount
    );

    // Mint event will be emitted when any new tokens are minted 
    event MintEvent(
        address to,
        uint256 amount
    );

    // Burn events will be emitted when any tokens are burned
    event BurnEvent(
        address from,
        uint256 amount
    );

    // Only owner midifier is used to restrict that aprticular function to the owner's access
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can call this function");
        _;
    }

    constructor(string memory name_, string memory symbol_){
        _name = name_;
        _symbol = symbol_;
        _totalSupply = 0;
        _owner = msg.sender;
    }

    // This function returns the symbol of the token
    function symbol() public view returns(string memory){
        return _symbol;
    }


    // This function returns the name of the token
    function name() public view returns(string memory){
        return _name;
    }


    // This function return the total supply of the tokens
    function totalSupply() public view returns(uint256){
        return _totalSupply;
    }

    // This function returns the balance of a particular user asked for
    function balanceOf(address _account) public view returns(uint256){
        return balances[_account];
    }

    // This function will be used to transfer funds from caller's wallet to the address the caller wants to
    function transfer(uint256 _amount,address _to) public {
        require(_to != address(0), "Address can't be zero");
        require(balances[msg.sender] >= _amount, "Not enough balance");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit TransferEvent(msg.sender, _to, _amount);
    }

    // This function will return the allownace of that particular wallet from the caller's account
    function getAllowance(address _to) public view returns(uint256){
        return _allowance[msg.sender][_to];
    }

    // This function will create new allowance amount from the caller's account to the desired address
    function addAllowance(uint256 _amount, address _to) public{
        require(balances[msg.sender] >= _amount, "Not enough balance");
        require(_to!=address(0), "Give a valid address");
        _allowance[msg.sender][_to] = _amount;
    }

    // This fucntion is used to remove all the allowances for that particular address from the caller's account
    function removeAllowance(address _to) public{
        require(_to!=address(0), "Give a valid address");
        _allowance[msg.sender][_to] = 0;
    }

    // After allowance is set, this particular function can be called upon to transfer funds
    // This function will comer handy when any third party like an escrow smart contract will try to transact funds
    function transferThirdParty(address _from, address _to, uint256 _amount) public{
        require(_to != address(0), "Address can't be zero");
        require(_from != address(0), "Address can't be zero");
        require(_allowance[_from][_to] >= _amount, "Allowance not enough");
        require(balances[_from] >= _amount, "Balance not enough");
        balances[_from] -= _amount;
        balances[_to] += _amount;
        _allowance[_from][_to] = 0;
        emit TransferEvent(_from, _to, _amount);
    }

    // This function is used to mint new tokens
    function mint(uint256 _amount, address _to) public onlyOwner{
        balances[_to] += _amount;
        _totalSupply += _amount;
        emit MintEvent(_to, _amount);
    }

    // This function will be used to burn tokens
    function burn(uint256 _amount) public{
        require(balances[msg.sender] >= _amount, "Not enough balance to burn");
        balances[msg.sender] -= _amount;
        _totalSupply -= _amount;
        emit BurnEvent(msg.sender, _amount);
    }

}