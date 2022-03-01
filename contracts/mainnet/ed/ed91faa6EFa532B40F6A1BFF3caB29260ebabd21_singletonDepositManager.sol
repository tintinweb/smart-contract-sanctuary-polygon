/**
 *Submitted for verification at polygonscan.com on 2022-03-01
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: AGPL-3.0-or-later
//OpenCEX inteligent deposits manager
interface IERC20 {
	function transfer(address to, uint256 value) external;
	function balanceOf(address account) external view returns (uint256);
}
interface sweeper{
	function sweep(address token, address payable to, uint256 limit) external;
}
contract singletonDepositManager{
	bytes32 private immutable codehash;
	constructor(){
		codehash = keccak256(type(singletonDepositAddress).creationCode);
	}
	function isContract(address account) internal view returns (bool) {
		return account.code.length > 0;
	}
	function deploy(
		uint256 amount,
		bytes32 salt,
		bytes memory bytecode
	) private returns (address) {
		address addr;
		require(address(this).balance >= amount, "Create2: insufficient balance");
		require(bytecode.length != 0, "Create2: bytecode length is zero");
		assembly {
			addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
		}
		require(addr != address(0), "Create2: Failed on deploy");
		return addr;
	}

	function computeAddress(bytes32 salt, bytes32 bytecodeHash) private view returns (address) {
		return computeAddress(salt, bytecodeHash, address(this));
	}

	function computeAddress(
		bytes32 salt,
		bytes32 bytecodeHash,
		address deployer
	) private pure returns (address) {
		bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
		return address(uint160(uint256(_data)));
	}

	function sweep(address token, bytes32 salt, uint256 limit) external{
		require(msg.sender == tx.origin, "Calls from contracts are not allowed!");
		bytes32 realsalt = keccak256(abi.encode(msg.sender, salt));
		address addy = computeAddress(realsalt, codehash);
		if(!isContract(addy)){
			deploy(0, realsalt, type(singletonDepositAddress).creationCode);
		}
		sweeper(addy).sweep(token, payable(msg.sender), limit);
	}

	function calculateDepositAddress(address sender, bytes32 salt) public view returns (address){
		return computeAddress(keccak256(abi.encode(sender, salt)), codehash);
	}

	function pendingDeposit(address sender, address token, bytes32 salt) external view returns (uint256){
		address singleton = calculateDepositAddress(sender, salt);
		if(token == 0x0000000000000000000000000000000000000000){
			return singleton.balance;
		} else{
			return IERC20(token).balanceOf(singleton);
		}
	}
}
contract singletonDepositAddress is sweeper{
	address immutable owner;
	constructor(){
		owner = msg.sender;
	}
	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionCall(target, data, "Address: low-level call failed");
	}
	function isContract(address account) internal view returns (bool) {
		return account.code.length > 0;
	}

	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) private returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) private returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}

	function verifyCallResult(
		bool success,
		bytes memory returndata,
		string memory errorMessage
	) private pure returns (bytes memory) {
		if (success) {
			return returndata;
		} else {
			if (returndata.length > 0) {
				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			} else {
				revert(errorMessage);
			}
		}
	}
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) private returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		require(isContract(target), "Address: call to non-contract");

		(bool success, bytes memory returndata) = target.call{value: value}(data);
		return verifyCallResult(success, returndata, errorMessage);
	}

	function safeTransfer(
		IERC20 token,
		address to,
		uint256 value
	) private {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
	}

	function _callOptionalReturn(IERC20 token, bytes memory data) private {

		bytes memory returndata = functionCall(address(token), data, "SafeERC20: low-level call failed");
		if (returndata.length > 0) {
			require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
		}
	}

	function sweep(address token, address payable to, uint256 limit) external override{
		require(msg.sender == owner, "SingletonDeposit: You are not the owner.");
		if(token == 0x0000000000000000000000000000000000000000){
			require(address(this).balance >= limit, "SingletonDeposit: Insufficent ETH balance!");
			(bool result, ) = to.call{value: limit}('');
			require(result, "SingletonDeposit: Send ether failed!");
		} else{
			require(IERC20(token).balanceOf(address(this)) >= limit, "SingletonDeposit: Insufficent token balance!");
			safeTransfer(IERC20(token), to, limit);
		}   
	}
	receive() payable external{

	}
}