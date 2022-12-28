/**
 *Submitted for verification at polygonscan.com on 2022-12-28
*/

pragma solidity 0.7.6;
// SPDX-License-Identifier: Unlicensed

// this is RaptorChain data feed
// basically, it's supposed to store immutable (only write-able once) slots of data, in order to pass them to RaptorChain
// since they can't change after being written, it allows simpler management on raptorchain-side

interface CrossChainFallback {
	function crossChainCall(address from, bytes memory data) external;
}

contract DataFeed {
	struct Slot {
		address owner;
		bytes32 variable;	// variable key
		bytes data;
		uint256 timestamp;
		bool written;
	}
	
	struct Variable {
		bytes32[] history;
	}
	
	struct User {
		mapping (bytes32 => Slot) slots;
		mapping (bytes32 => Variable) variables;
	}
	
	address public operator;
	mapping (address => User) users;
	
	event SlotWritten(address indexed slotOwner, bytes32 indexed variableKey, bytes32 indexed slotKey, bytes data);
	event CallExecuted(address indexed from, address indexed to, bool indexed success, uint256 gasLimit, bytes data);
	
	modifier onlyOperator {
		require(msg.sender == operator, "ONLY_OPERATOR_CAN_DO_THAT");
		_;
	}
	
	constructor(address _operator) {
		operator = _operator;
	}
	
	function isWritten(address owner, bytes32 key) public view returns (bool) {
		return users[owner].slots[key].written;
	}
	
	function getSlotData(address owner, bytes32 key) public view returns (bytes memory) {
		return users[owner].slots[key].data;
	}
	
	function getVariableData(address owner, bytes32 key) public view returns (bytes memory) {
		User storage user = users[owner];
		Variable storage _var = user.variables[key];
		if (_var.history.length == 0) {
			return "";
		}
		return user.slots[_var.history[_var.history.length-1]].data;
	}
	
	function write(bytes32 variableKey, bytes memory slotData) public returns (bytes32) {
		bytes32 slotKey = keccak256(abi.encodePacked(variableKey, blockhash(block.number-1)));
		require(!isWritten(msg.sender, slotKey), "ALREADY_WRITTEN");
		User storage user = users[msg.sender];
		Variable storage _var = user.variables[variableKey];
		_var.history.push(slotKey);
		Slot memory newSlot = Slot({ owner: msg.sender, variable: variableKey, data: slotData, timestamp: block.timestamp , written: true });
		user.slots[slotKey] = newSlot;
		emit SlotWritten(msg.sender, variableKey, slotKey, slotData);
		return slotKey;
	}
	
	function decodeCall(bytes memory _call) public pure returns (address from, address to, uint256 gasLimit, bytes memory data) {
		(from, to, gasLimit, data) = abi.decode(_call, (address, address, uint256, bytes));
	}
	
	function execBridgeCall(bytes memory _data) public onlyOperator {
		(address from, address to, uint256 gasLimit, bytes memory data) = abi.decode(_data, (address, address, uint256, bytes));
		(bool success, ) = to.call{gas: gasLimit}(abi.encodeWithSelector(bytes4(keccak256("crossChainCall(address,bytes)")), from, data));
		emit CallExecuted(from, to, success, gasLimit, data);
	}
}