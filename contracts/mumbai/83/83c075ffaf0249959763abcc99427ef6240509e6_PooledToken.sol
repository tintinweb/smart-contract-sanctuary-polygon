/**
 *Submitted for verification at polygonscan.com on 2022-09-25
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.x;

interface Token
{
	function balanceOf (address) external view returns (uint);
	function approve (address, uint) external returns (bool);
	function transfer (address, uint) external returns (bool);
}

interface NativeToken is Token
{
	function deposit () external payable;
}

interface Factory
{
	function getPair (address, address) external returns (address);
}

interface Exchange
{
	function WETH() pure external returns (Token);
	function factory() pure external returns (Factory);

	function addLiquidity(address a, address b, uint a_desired, uint b_desired, uint a_min, uint b_min, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
	function removeLiquidity(address a, address b, uint liquidity, uint a_min, uint b_min, address to, uint deadline) external returns (uint amountA, uint amountB);

	function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
	function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

	function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
	function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

contract FixedToken is Token
{
	address public owner;

	string public name;
	string public symbol;
	uint8 public decimals;
	uint public totalSupply;

	mapping(address => uint) public balanceOf;
	mapping(address => mapping(address => uint)) public allowance;

	event Transfer (address indexed from, address indexed to, uint amount);
	event Approval (address indexed from, address indexed to, uint amount);

	constructor (string memory _name, string memory _symbol, uint8 _decimals, uint _totalSupply)
	{
		owner = msg.sender;

		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		totalSupply = _totalSupply;

		balanceOf[owner] = totalSupply;
	}

	function approve (address target, uint amount) public returns (bool)
	{
		allowance[msg.sender][target] = amount;

		emit Approval(msg.sender, target, amount);

		return true;
	}

	function transfer (address target, uint amount) public returns (bool)
	{
		doTransfer(msg.sender, target, amount);

		return true;
	}

	function transferFrom (address from, address to, uint amount) external
	{
		if (from != msg.sender)
		{
			allowance[from][msg.sender] -= amount;
		}

		doTransfer(from, to, amount);
	}

	function doTransfer (address from, address to, uint amount) internal
	{
		balanceOf[from] -= amount;
		balanceOf[to] += amount;

		emit Transfer(from, to, amount);
	}
}

contract PooledToken
{
	address public owner;

	Exchange public exchange;
	Token public token_a;
	Token public token_b;
	Token public lp_token;

	constructor (string memory _name, string memory _symbol, uint8 _decimals, uint _price, Exchange _exchange) payable
	{
		owner = msg.sender;

		exchange = _exchange;

		token_b = exchange.WETH();

		NativeToken(address(token_b)).deposit{value: msg.value}();

		uint token_b_amount = msg.value;
		uint token_a_amount = msg.value / (_price * 10**(18-_decimals));

		token_a = new FixedToken(_name, _symbol, _decimals, token_a_amount);

		token_a.approve(address(exchange), token_a_amount);
		token_b.approve(address(exchange), token_b_amount);

		exchange.addLiquidity(address(token_a), address(token_b), token_a_amount, token_b_amount, 0, 0, address(this), block.timestamp);

		lp_token = Token(Factory(exchange.factory()).getPair(address(token_a), address(token_b)));
	}

	function withdraw () external
	{
		require(msg.sender == owner);

		uint lp_token_amount = lp_token.balanceOf(address(this));

		lp_token.approve(address(exchange), lp_token_amount);

		(uint amountA, uint amountB) = exchange.removeLiquidity(address(token_a), address(token_b), lp_token_amount, 0, 0, address(this), block.timestamp);

		token_a.transfer(owner, amountA);
		token_b.transfer(owner, amountB);
	}

	function path (Token from, Token to) pure internal returns (address[] memory)
	{
		address[] memory result = new address[](2);
		result[0] = address(from);
		result[1] = address(to);
		return result;
	}
}