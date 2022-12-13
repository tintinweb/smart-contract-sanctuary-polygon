// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ierc20.sol";
contract FlashareGasToken is IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name_;
    string private _symbol_;
    address private ManagerFlashareTokensAdd;

    constructor(string memory name_, string memory symbol_) {
        _name_ = name_;
        _symbol_ = symbol_;
        ManagerFlashareTokensAdd=msg.sender;
    }

    fallback()external{}

    function name() public view virtual returns (string memory) {
        return _name_;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol_;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address owner,address spender, uint256 addedValue) public virtual returns (bool) { //change owner
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
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
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address _account_, uint256 amount) public virtual {
        require(ManagerFlashareTokensAdd==msg.sender,"error!");
        require(_account_ != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), _account_, amount);

        _totalSupply += amount;
        unchecked {
            _balances[_account_] += amount;
        }
        emit Transfer(address(0), _account_, amount);

        _afterTokenTransfer(address(0), _account_, amount);
    }


    function _burn(address _account_, uint256 amount) public virtual {
        require(ManagerFlashareTokensAdd==msg.sender,"error!");
        require(_account_ != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(_account_, address(0), amount);

        uint256 accountBalance = _balances[_account_];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[_account_] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(_account_, address(0), amount);

        _afterTokenTransfer(_account_, address(0), amount);
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
    ) internal virtual view {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual view{}
}