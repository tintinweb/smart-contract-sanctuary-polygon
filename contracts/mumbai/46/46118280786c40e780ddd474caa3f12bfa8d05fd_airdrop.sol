/**
 *Submitted for verification at polygonscan.com on 2022-03-15
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
	mapping (address => bool) isManager;
	uint256 lastAirdropTime;
	uint256 everydayAmount = 2000_000_000_000_000_000_000;
	uint256 remainAmount = everydayAmount;

	modifier onlyManager() {
		require(isManager[_msgSender()], "Not manager");
		_;
	}

	function reset() internal virtual {
		lastAirdropTime = block.timestamp;
		remainAmount = everydayAmount;
	}

	function setManager(address _manager, bool _flag) public onlyOwner {
		isManager[_manager] = _flag;
	}

	function setEverydayAmount(uint256 _amount) public onlyOwner {
		everydayAmount = _amount;
	}

	function AirTransferDiffValue(address[] memory _recipients, uint[] memory _values, address _tokenAddress) public onlyManager returns (bool) {
		require(block.timestamp - lastAirdropTime >= 24 * 60 * 60, "Already airdropped for today");
		require(_recipients.length > 0);
		require(_recipients.length == _values.length);

		Token token = Token(_tokenAddress);

		for(uint j = 0; j < _recipients.length; j++){
			token.transfer(_recipients[j], _values[j]);
			require(remainAmount - _values[j] > 0, "Everyday transfer amount insufficient");
			remainAmount -= _values[j];
		}

		// everyday amount has transferred, reset for next airdrop
		if(remainAmount == 0) reset();

		return true;
	}

	function AirTransfer(address[] memory _recipients, uint256 _value, address _tokenAddress) public onlyManager returns (bool) {
		require(block.timestamp - lastAirdropTime >= 24 * 60 * 60, "Already airdropped for today");
		require(remainAmount - _recipients.length * _value > 0, "Everyday transfer amount insufficient");
		require(_recipients.length > 0);
		Token token = Token(_tokenAddress);
		for(uint j = 0; j < _recipients.length; j++){
			token.transfer(_recipients[j], _value);
			remainAmount -= _value;
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