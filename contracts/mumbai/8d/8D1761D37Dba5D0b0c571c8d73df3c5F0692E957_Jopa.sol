/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// created by cryptodo.app
//   _____                      _          _____         
//  / ____|                    | |        |  __ \        
// | |      _ __  _   _  _ __  | |_  ___  | |  | |  ___  
// | |     | '__|| | | || '_ \ | __|/ _ \ | |  | | / _ \ 
// | |____ | |   | |_| || |_) || |_| (_) || |__| || (_) |
//  \_____||_|    \__, || .__/  \__|\___/ |_____/  \___/ 
//                 __/ || |                              
//                |___/ |_|      

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            'Ownable: new owner is the zero address'
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract ERC20 is Context, IERC20 {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;
    uint8 internal _decimals;
    string private _name;
    string private _symbol;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(
            currentAllowance >= subtractedValue,
            'ERC20: decreased allowance below zero'
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), 'ERC20: transfer from the zero address');
        require(to != address(0), 'ERC20: transfer to the zero address');

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            'ERC20: transfer amount exceeds balance'
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                'ERC20: insufficient allowance'
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract ERC20Burnable is Context, ERC20 {
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), 'ERC20: burn from the zero address');

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, 'ERC20: burn amount exceeds balance');
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

abstract contract ERC20Mintable is Ownable, ERC20 {
    uint256 private immutable _cap;

    constructor(uint256 cap_) {
        require(cap_ > 0, 'ERC20Capped: cap is 0');
        _cap = cap_;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), 'ERC20: mint to the zero address');

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(
            totalSupply() + amount <= _cap,
            'Total supply cannot exceed cap'
        );
        _mint(to, amount);
    }
}

abstract contract ERC20Blacklist is Ownable {
    event Blacklisted(address account);

    event Whitelisted(address account);

    mapping(address => bool) internal _blacklist;

    modifier onlyWhitelisted() {
        require(!_blacklist[_msgSender()], 'Wallet is blacklisted');
        _;
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklist[account];
    }

    function addToBlacklist(address account) external onlyOwner {
        require(account != address(0), 'Zero address not allowed');
        require(!_blacklist[account], 'Address is already blacklisted');
        _blacklist[account] = true;
        emit Blacklisted(account);
    }

    function removeFromBlacklist(address account) external onlyOwner {
        require(account != address(0), 'Zero address not allowed');
        require(_blacklist[account], 'Address is not blacklisted');
        _blacklist[account] = false;
        emit Whitelisted(account);
    }
}

abstract contract Pausable is Context, Ownable {
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), 'Pausable: paused');
        _;
    }

    modifier whenPaused() {
        require(paused(), 'Pausable: not paused');
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract Jopa is
    Ownable,
    ERC20
    ,ERC20Burnable
    ,ERC20Mintable
    ,ERC20Blacklist
    ,Pausable  
{
    constructor(
        address initialOwner_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_
        ,uint256 cap_
    )
        Ownable(initialOwner_)
        ERC20(name_, symbol_, decimals_, totalSupply_)
        ERC20Mintable(cap_)
    {
        _balances[initialOwner_] = totalSupply_;
    }
       
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) whenNotPaused onlyWhitelisted {
        super._beforeTokenTransfer(from, to, amount);
    }
}