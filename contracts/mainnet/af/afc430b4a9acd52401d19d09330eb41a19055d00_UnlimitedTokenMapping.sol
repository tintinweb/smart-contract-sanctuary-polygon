/**
 *Submitted for verification at polygonscan.com on 2022-02-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}


library SafeMath {
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


abstract contract AdminControl is Ownable {
    mapping(address => bool) private _admins;

    event AdminGranted(address indexed account, address indexed sender);

    event AdminRevoked(address indexed account, address indexed sender);

    modifier onlyAdmin() {
        require(_admins[_msgSender()], "AdminControl: caller is not the admin");
        _;
    }

    function hasAdmin(address account) public view returns(bool) {
        return _admins[account];
    }

    function grantAdmin(address account) public onlyOwner {
        _admins[account] = true;
        emit AdminGranted(account, _msgSender());
    }

    function revokeAdmin(address account) public onlyOwner {
        _admins[account] = false;
        emit AdminRevoked(account, _msgSender());
    }
}

abstract contract BlackListControl is Ownable {

    mapping(address => bool) private _blackLists;

    event BlackListGranted(address indexed account, address indexed sender);

    event BlackListRevoked(address indexed account, address indexed sender);

    function hasBlackList(address account) public view returns(bool) {
        return _blackLists[account];
    }

    function grantBlackList(address account) public onlyOwner {
        _blackLists[account] = true;
        emit BlackListGranted(account, _msgSender());
    }

    function revokeBlackList(address account) public onlyOwner {
        _blackLists[account] = false;
        emit BlackListRevoked(account, _msgSender());
    }

}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


interface ITokenMapping {
    
    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;
}

contract TokenMapping is ERC20, AdminControl, BlackListControl, ITokenMapping {
    
    using SafeMath for uint256;

    uint256 public total = 10_0000_0000 ether;
    
    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    constructor (string memory name_, string memory symbol_) public ERC20(name_, symbol_) {
        grantAdmin(msg.sender);
    }

    function mint(address account, uint256 amount) public override onlyAdmin {
        require(amount.add(totalSupply()) <= total, "TokenMapping: Exceeding the maximum limit");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyAdmin {
        _burn(account, amount);
    }

    function burn(uint256 amount) public override {
        _burn(_msgSender(), amount);
    }

    function destroyBlackFunds(address account) public onlyAdmin {
        uint dirtyFunds = balanceOf(account);
        _burn(account, dirtyFunds);
        emit DestroyedBlackFunds(account, dirtyFunds);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override { 
        require(!hasBlackList(to), "TokenMapping: It can't be a blacklist to");
        require(!hasBlackList(from) || to == address(0x0) , "TokenMapping: It can't be a blacklist from");
    }
}

contract UnlimitedTokenMapping is ERC20, AdminControl, BlackListControl, ITokenMapping {
    
    using SafeMath for uint256;
 
    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    constructor (string memory name_, string memory symbol_) public ERC20(name_, symbol_) {
        grantAdmin(msg.sender);
    }

    function mint(address account, uint256 amount) public override onlyAdmin {
        _mint(account, amount);
    }
    
    function batchMint(address[] memory accounts,uint256[] memory amounts) public onlyAdmin {
        require(accounts.length == amounts.length , "UnlimitedTokenMapping: accounts and amounts length mismatch");
        
        for(uint i = 0; i < accounts.length; i++){
            mint(accounts[i], amounts[i]);
        }
    }

    function burn(address account, uint256 amount) public onlyAdmin {
        _burn(account, amount);
    }

    function burn(uint256 amount) public override {
        _burn(_msgSender(), amount);
    }

    function destroyBlackFunds(address account) public onlyAdmin {
        uint dirtyFunds = balanceOf(account);
        _burn(account, dirtyFunds);
        emit DestroyedBlackFunds(account, dirtyFunds);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override { 
        require(!hasBlackList(to), "TokenMapping: It can't be a blacklist to");
        require(!hasBlackList(from) || to == address(0x0) , "TokenMapping: It can't be a blacklist from");
    }
}