// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";


contract Banana is IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint8 private immutable _decimals = 18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory name_, string memory symbol_){
        require(bytes(name_).length > 0, "BNN:constructor::name_ is undefined");
        require(bytes(symbol_).length > 0, "BNN:constructor::symbol_ is undefined");
        _name = name_;
        _symbol = symbol_;
    }

    // === Public ===
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool) {
        require(spender != address(0), "BNN::increaseAllowance:spender must be different than 0");

        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool) {
        require(spender != address(0), "BNN::decreaseAllowance:spender must be different than 0");

        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BNN::decreaseAllowance: decreased allowance below zero");

        _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (sender != _msgSender() && _allowances[sender][msg.sender] != type(uint).max) {
            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(currentAllowance >= amount, "BNN::transferFrom: transfer amount exceeds allowance");
            _approve(sender, _msgSender(), currentAllowance.sub(amount));
        }

        _transfer(sender, recipient, amount);
        return true;
    }

    function mint(address to, uint256 value) external override onlyOwner() returns (bool) {
        _mint(to, value);
        return true;
    }

    function burn(uint256 amount) external override returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function withdraw() public onlyOwner {
        (bool success,) = payable(msg.sender).call{value : address(this).balance}("");
        require(success);
    }

    function withdrawERC20(address _token) public onlyOwner {
        IERC20 token = IERC20(_token);
        require(token.balanceOf(address(this)) > 0, "BNN: Balance already 0");

        bytes memory data = abi.encodeWithSelector(token.transfer.selector, owner(), token.balanceOf(address(this)));
        bytes memory return_data = address(_token).functionCall(data, "BNN: low-level call failed");
        if (return_data.length > 0) {
            // Return data is optional to support crappy tokens like BNB and others not complying to ERC20 interface
            require(abi.decode(return_data, (bool)), "BNN: ERC20 operation did not succeed");
        }
    }

    // === Views ===
    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address sender, address spender) external view override returns (uint256) {
        return _allowances[sender][spender];
    }

    // === Internals ===
    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "BNN::_approve: approve from the zero address");
        require(spender != address(0), "BNN::_approve: approve to the zero address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BNN::_mint:mint to the zero address");
        require(amount > 0, "BNN::_mint:amount must be greater than zero");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BNN::_burn:burn from the zero address");
        require(amount > 0, "BNN::_burn:amount must be greater than zero");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BNN::_burn:burn amount exceeds balance");

        _balances[account] = accountBalance.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BNN::_transfer: transfer from the zero address");
        require(recipient != address(0), "BNN::_transfer: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BNN::_transfer: transfer amount exceeds balance");

        _balances[sender] = senderBalance.sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }
}