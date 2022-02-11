// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "Ownable.sol";
contract TWARCoin is Ownable {
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
    constructor() {
        _name = "TradingWarriors Coin";
        _symbol = "TWAR";
        _decimals = 18;
        _totalSupply = 10000000000000000000000000000;
        _balances[address(0x30Db02EbA4EeCE65954ea1D1BBc358e0fC3e12D5)] = 500000000000000000000000000;
        _balances[address(0x2eFd81e42B86148DAB243E6bD6F4C7EE3A594DD7)] = 6900000000000000000000000000;
        _balances[address(0x9d971C3cAf066556A1A92986275D6d2218dE0e37)] = 200000000000000000000000000;
        _balances[address(0xF8Edf21EbC3024280af1F45D8C16464144C79419)] = 2400000000000000000000000000;
        emit Transfer(address(0), address(0x30Db02EbA4EeCE65954ea1D1BBc358e0fC3e12D5), 500000000000000000000000000); //Team
        emit Transfer(address(0), address(0x2eFd81e42B86148DAB243E6bD6F4C7EE3A594DD7), 6900000000000000000000000000); //Play to earn
        emit Transfer(address(0), address(0x9d971C3cAf066556A1A92986275D6d2218dE0e37), 200000000000000000000000000); //Marketing
        emit Transfer(address(0), address(0xF8Edf21EbC3024280af1F45D8C16464144C79419), 2400000000000000000000000000); //Liquidity mining
    }
    function decimals() external view returns (uint8) {
        return _decimals;
    }
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "cannot burn from zero address");
        require( _balances[account] >= amount,"Cannot burn more than the account owns");
        _balances[account] = _balances[account] - amount;
        emit Transfer(account, address(0), amount);
    }
    function burn(address account, uint256 amount)public onlyOwner returns (bool)
    {
        _burn(account, amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function multipleTransfer(address[] calldata _addr, uint256 amount)
        external
        returns (bool)
    {
         for (uint256 i = 0; i < _addr.length; i++) {
           _transfer(msg.sender, _addr[i], amount);
        }
        
        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "transfer from zero address");
        require(recipient != address(0), "transfer to zero address");
        require(
            _balances[sender] >= amount,
            "cant transfer more than your account holds"
        );
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(
            owner != address(0),
            "approve cannot be done from zero address"
        );
        require(spender != address(0), "approve cannot be to zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        require(
            _allowances[spender][msg.sender] >= amount,
            "You cannot spend that much amount on this account"
        );
        _transfer(spender, recipient, amount);
        _approve(
            spender,
            msg.sender,
            _allowances[spender][msg.sender] - amount
        );
        return true;
    }
    
}