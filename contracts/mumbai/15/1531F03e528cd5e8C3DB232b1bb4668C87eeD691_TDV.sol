/**
 *Submitted for verification at polygonscan.com on 2023-06-01
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.7;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function maxSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable {
    address private _owner;
    address private _tempOwner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(isOwner(), "Function accessible only by the owner !!");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function checkOwner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner returns (bool){
        require(newOwner != address(0));
        _tempOwner = newOwner;
         return true;
    }
    function acceptOwnership() public returns (bool){
        require(msg.sender == _tempOwner);
        _owner = _tempOwner;
        _tempOwner = address(0);
         return true;
    }
}


contract TDV is Context, IERC20, IERC20Metadata,Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public mintingSign;
    mapping(address => bool) public minterChangingSign;

    uint256 private _totalSupply;
    uint256 constant private _maxSupply = 5000000*10**18;
    string constant private _name = "TribeDigitalVentures";
    string constant private _symbol = "TDV";
    address public minterOne;
    address public minterTwo;

    event minterChanged(address indexed oldMinter, address indexed newMinter);

    constructor() {
        minterOne = 0xCf2107aBBe65109f8bdfF0d4dEfEce00ba3BC969;
        minterTwo = 0xCC63Db26a9de545327C5DE9b7870FaD9ADB76F60;
        uint256 x = 1000000*10**18;
        _mint(msg.sender, x); 
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function maxSupply() public view virtual override returns (uint256){
        return _maxSupply;
    }

    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

        function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint at the zero address");


        uint256 newAccountBalance = _balances[account] + amount;
        uint256 newTotalSupply = _totalSupply + amount;
        require(newTotalSupply <= maxSupply(), "ERC20: mint amount exceeds Maximum supply");
        unchecked {
            _balances[account] = newAccountBalance;
        }
        _totalSupply += amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }


    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

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
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
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

    function burn(uint256 amount) public onlyOwner virtual {
        _burn(_msgSender(), amount);
    }
    function mint(uint256 amount) public virtual {
        require (_msgSender() == minterOne || _msgSender() == minterTwo || _msgSender() == checkOwner());
        require(mintingSign[minterOne] && mintingSign[minterTwo]);
        _mint(_msgSender(), amount);
    }

    function changeMintSign() public{
        require (_msgSender() == minterOne || _msgSender() == minterTwo);
        bool y = mintingSign[_msgSender()];
        // require (!mintSign[_msgSender()]);
        mintingSign[_msgSender()] = !y;
    }
    function changeMinterSign() public{
        require (_msgSender() == minterOne || _msgSender() == minterTwo || _msgSender() == checkOwner());
        bool y = minterChangingSign[_msgSender()];
        // require (!minterChangeSign[_msgSender()]);
        minterChangingSign[_msgSender()] = !y;
    }
    function changeMinter( address oldMinter, address newMinter) public onlyOwner{
        require(minterChangingSign[checkOwner()]);
        require(minterChangingSign[minterOne] || minterChangingSign[minterTwo]);
        require(newMinter != address(0), "New minter cannot be a zero address");
        if (oldMinter == minterOne){
        minterOne = newMinter;
        emit minterChanged(oldMinter, newMinter);
        }
        else if (oldMinter == minterTwo){
        minterTwo = newMinter;
        emit minterChanged(oldMinter, newMinter);
        }
        else
        revert("Incorrect old minter address");
    }
}