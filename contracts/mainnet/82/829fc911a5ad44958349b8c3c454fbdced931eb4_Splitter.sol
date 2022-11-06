// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./IERC20.sol";
import "./ISwapFund.sol";


contract Splitter is IERC20 {
	string constant public name = "Drawership Splitter";
	string constant public symbol = "DRXS";
	uint8 constant public decimals = 3;

	address immutable public SWAP_FUND;
	address immutable public PAIRED_TOKEN;
	uint256 immutable public SWAPRATE_1;

	uint256 private _totalSupply;

	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;


	constructor (
						address _SWAP_FUND,
						address _owner,
						uint256 _SWAPRATE_1,
						uint256 _holdersSupply_1,
						uint256 _swapFundSupply_1)
	{
		SWAP_FUND = _SWAP_FUND;
		PAIRED_TOKEN = msg.sender;
		SWAPRATE_1 = _SWAPRATE_1;
		_totalSupply = _holdersSupply_1 + _swapFundSupply_1;
		_balances[_SWAP_FUND] = _swapFundSupply_1;
		_balances[_owner] = _holdersSupply_1;

		emit Transfer(address(0), _SWAP_FUND, _balances[_SWAP_FUND]);
		emit Transfer(address(0), _owner, _balances[_owner]);
	}

	function totalSupply() external view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address _of) external view returns (uint256) {
		return _balances[_of];
	}

	function transfer(address _recipient, uint256 _amount) external returns (bool) {
		require(_balances[msg.sender] >= _amount, "Transfer amount exceeds balance");
		require(_recipient != address(0) && _recipient != address(this) && _recipient != PAIRED_TOKEN,
						"Cannot transfer to zero or self/paired token contract");

		emit Transfer(msg.sender, _recipient, _amount);
		_balances[msg.sender] -= _amount;
		_balances[_recipient] += _amount;

		if (_recipient == SWAP_FUND && _recipient != msg.sender) {
			require(_amount > 0, "Swap amount cannot be 0");
			require(_amount >= SWAPRATE_1 && _amount % SWAPRATE_1 == 0, "Paired token amount not strict");
			require(ISwapFund(SWAP_FUND).swapReceivedWithPaired(msg.sender, _amount));
		}

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
		require(_spender != address(0) && _spender != address(this) && _spender != PAIRED_TOKEN && _spender != SWAP_FUND,
						"Cannot approve to zero, self/paired token or SwapFund contract");

		emit Approval(msg.sender, _spender, _amount);
		_allowances[msg.sender][_spender] = _amount;
		return true;
	}
}