// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./IERC20.sol";

contract SimpleToken is IERC20 {
	string constant public name = "Simple";
	string constant public symbol = "STK";
	uint8 constant public decimals = 1;

	uint256 private _totalSupply;

	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;


	constructor ()
	{
		_totalSupply = 10000;

		_balances[msg.sender] = _totalSupply;

		emit Transfer(address(0), msg.sender, _balances[msg.sender]);
	}

	function totalSupply() external view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address _of) external view returns (uint256) {
		return _balances[_of];
	}

	function transfer(address _recipient, uint256 _amount) external returns (bool) {
		require(_balances[msg.sender] >= _amount, "Transfer amount exceeds balance");
		require(_recipient != address(0) && _recipient != address(this),
						"Cannot transfer to zero or self contract");

		emit Transfer(msg.sender, _recipient, _amount);
		_balances[msg.sender] -= _amount;
		_balances[_recipient] += _amount;

		return true;
	}

	function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool) {
		require(_allowances[_sender][msg.sender] >= _amount, "Transfer amount exceeds allowance");
		require(_balances[_sender] >= _amount, "Transfer amount exceeds balance");

		emit Transfer(_sender, _recipient, _amount);
		_allowances[_sender][msg.sender] -= _amount;
		_balances[_sender] -= _amount;
		_balances[_recipient] += _amount;
		return true;
	}

	function allowance(address _owner, address _spender) external view returns (uint256) {
		return _allowances[_owner][_spender];
	}

	function approve(address _spender, uint256 _amount) external returns (bool) {
		require(_spender != address(0) && _spender != address(this),
						"Cannot approve to zero or self contract");

		emit Approval(msg.sender, _spender, _amount);
		_allowances[msg.sender][_spender] = _amount;
		return true;
	}
}