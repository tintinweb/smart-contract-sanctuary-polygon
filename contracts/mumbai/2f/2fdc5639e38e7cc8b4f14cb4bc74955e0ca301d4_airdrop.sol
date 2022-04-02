/**
 *Submitted for verification at polygonscan.com on 2022-04-02
*/

// Copyright (C) 2022 Cycan Technologies

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}

contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() {
		_transferOwnership(_msgSender());
	}

	function owner() public view virtual returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		_transferOwnership(address(0));
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

interface Token {
	function balanceOf(address _owner) external returns (uint256 );
	function transfer(address _to, uint256 _value) external ;
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract airdrop is Ownable {
	mapping (address => bool) private managers;
	uint256 public zeroClock = 1647273600;  // 2022-03-15 00:00:00
	uint256 public remainAmount;
	uint256 public everydayAmount;

	constructor() {
		// init zeroClock as deploy day's zero o'clock
		zeroClock = block.timestamp - (block.timestamp - zeroClock) % 86400;
		everydayAmount = 2000_000_000_000_000_000_000;
		remainAmount = everydayAmount;
	}

	modifier onlyManager() {
		require(managers[_msgSender()], "Not manager");
		_;
	}

	function reset() internal virtual {
		zeroClock += 86400; // tomorrow's zero o'clock
		remainAmount = everydayAmount; // update remainAmount as everydayAmount
	}

	function setManager(address _manager, bool _flag) public onlyOwner {
		managers[_manager] = _flag;
	}

	function isManager(address _manager) public view returns (bool) {
		return managers[_manager];
	}

	function setEverydayAmount(uint256 _amount) public onlyOwner {
		// if setEverydayAmount() is called between today's airdrop, like the following case:
		// airdrop is in three batches, the first batch has been completed
		// in this case, don't change today's airdrop amount.
		if (remainAmount == everydayAmount) {
			remainAmount = _amount;
		}
		everydayAmount = _amount; // must be set successfully at any time.
	}

	function AirTransferDiffValue(address[] memory _recipients, uint[] memory _values, address _tokenAddress) public onlyManager returns (bool) {
		require( block.timestamp > zeroClock, "Already airdropped for today");
		require(_recipients.length > 0);
		require(_recipients.length == _values.length);

		// Empty the unused 'remainAmount' of the previous days
		if (block.timestamp - zeroClock > 1 days) {
			// set zeroClock as today's zero o'clock
			zeroClock = block.timestamp - (block.timestamp - zeroClock) % 86400;
			// Empty the previous days' unused 'remainAmount' and update remainAmount as a new everydayAmount.
			remainAmount = everydayAmount;
		}

		Token token = Token(_tokenAddress);

		uint256 _transferredAmount = 0;
		for(uint j = 0; j < _recipients.length; j++){
			token.transfer(_recipients[j], _values[j]);
			_transferredAmount += _values[j];
		}
		require(remainAmount >= _transferredAmount, "Everyday transfer amount insufficient");
		remainAmount -= _transferredAmount;

		// everyday amount has transferred, reset for next airdrop
		if(remainAmount == 0) reset();

		return true;
	}

	function AirTransfer(address[] memory _recipients, uint256 _value, address _tokenAddress) public onlyManager returns (bool) {
		require(block.timestamp > zeroClock, "Already airdropped for today");
		require(_recipients.length > 0);

		// Empty the unused 'remainAmount' of the previous days
		if (block.timestamp - zeroClock > 1 days) {
			// set zeroClock as today's zero o'clock
			zeroClock = block.timestamp - (block.timestamp - zeroClock) % 86400;
			// Empty the previous days' unused 'remainAmount' and update remainAmount as a new everydayAmount.
			remainAmount = everydayAmount;
		}

		require(remainAmount >= _recipients.length * _value, "Everyday transfer amount insufficient");
		remainAmount -= _recipients.length * _value;

		Token token = Token(_tokenAddress);
		for(uint j = 0; j < _recipients.length; j++){
			token.transfer(_recipients[j], _value);
		}
		// everyday amount has transferred, reset for next airdrop
		if(remainAmount == 0) reset();

		return true;
	}

	function withdrawalToken(address _tokenAddress) public onlyOwner {
		Token token = Token(_tokenAddress);
		token.transfer(owner(), token.balanceOf(address(this)));
	}
}