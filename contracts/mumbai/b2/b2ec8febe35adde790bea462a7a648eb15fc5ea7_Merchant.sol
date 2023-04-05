/**
 *Submitted for verification at polygonscan.com on 2023-04-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

// import "erc-payable-token/contracts/token/ERC1363/IERC1363Receiver.sol";
interface IERC1363Receiver {
	/*
	 * Note: the ERC-165 identifier for this interface is 0x88a7ca5c.
	 * 0x88a7ca5c === bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
	 */

	/**
	 * @notice Handle the receipt of ERC1363 tokens.
	 * @dev Any ERC1363 smart contract calls this function on the recipient
	 * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
	 * transfer. Return of other than the magic value MUST result in the
	 * transaction being reverted.
	 * Note: the token contract address is always the message sender.
	 * @param spender address The address which called `transferAndCall` or `transferFromAndCall` function
	 * @param sender address The address which are token transferred from
	 * @param amount uint256 The amount of tokens transferred
	 * @param data bytes Additional data with no specified format
	 * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))` unless throwing
	 */
	function onTransferReceived(address spender, address sender, uint256 amount, bytes calldata data) external returns (bytes4);
}

/*
    @name Merchant
    @description A guy who can receive payments
    @date April 4th 2023
    @author William Doyle
 */
contract Merchant is IERC1363Receiver {
	uint256 public callCount = 0;

	function onTransferReceived(address spender, address sender, uint256 amount, bytes calldata data) external returns (bytes4) {
		callCount++;
        return bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"));
	}

	function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
		return interfaceId == type(IERC1363Receiver).interfaceId;
	}
}