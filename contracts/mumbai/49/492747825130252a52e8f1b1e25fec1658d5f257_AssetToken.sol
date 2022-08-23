/**
 *Submitted for verification at polygonscan.com on 2022-08-23
*/

// SPDX-License-Identifier: MIT
// File: contracts/Token.sol



pragma solidity ^0.8.6;

abstract contract isAdmin {
	address public admin;

    constructor() {
		admin = msg.sender;

	}
    
	modifier onlyAdmin() {
		require(msg.sender == admin, "User is not admin") ;
		_;
	}

	function transferAdminship(address newAdmin) onlyAdmin public {
		admin = newAdmin;
	}

}

contract Token {

	mapping (address => uint256) public balanceOf;
	// balanceOf[address] = 5;
	string public name;
	string public symbol;
	uint8 public decimal; 
	uint256 public totalSupply;
	event Transfer(address indexed from, address indexed to, uint256 value);


	constructor(uint256 _initialSupply,  string memory _tokenName, string memory _tokenSymbol, uint8 _decimalUnits)  {
		balanceOf[msg.sender] = _initialSupply;
		totalSupply = _initialSupply;
		decimal = _decimalUnits;
		symbol = _tokenSymbol;
		name = _tokenName;
	}

	function transfer(address _to, uint256 _value) virtual public {
		require(balanceOf[msg.sender] > _value) ;
		require(balanceOf[_to] + _value > balanceOf[_to]) ;
		//if(admin)

		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
		emit Transfer(msg.sender, _to, _value);
	}

}

 contract AssetToken is isAdmin, Token{
	constructor(uint256 _initialSupply, string memory _tokenName, string memory _tokenSymbol, uint8 _decimalUnits, address _centralAdmin) Token (0, _tokenName, _tokenSymbol, _decimalUnits ) {
		totalSupply = _initialSupply;
		if(_centralAdmin != address(0)){
		admin = _centralAdmin;
		}
		else{
			admin = msg.sender;
			}
		balanceOf[admin] = _initialSupply;
		totalSupply = _initialSupply;	
	}

	function mintToken(address target, uint256 mintedAmount) onlyAdmin public {
		balanceOf[target] += mintedAmount;
		totalSupply += mintedAmount;
		emit Transfer(address(0), address(this), mintedAmount);
		emit Transfer(address(this), target, mintedAmount);
	}

	function transfer(address _to, uint256 _value) override public {
		require(balanceOf[msg.sender] >= 0) ;
		require(balanceOf[msg.sender] > _value) ;
		require(balanceOf[_to] + _value > balanceOf[_to]) ;
		//if(admin)
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
		emit Transfer(msg.sender, _to, _value);
	}

}