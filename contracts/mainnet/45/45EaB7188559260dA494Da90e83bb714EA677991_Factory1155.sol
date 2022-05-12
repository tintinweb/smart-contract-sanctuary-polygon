//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./MarleyDigitalMediaUserToken1155.sol";

contract Factory1155 {
	event Deployed(address owner, address contractAddress);

	function deploy(bytes32 _salt, string memory name, string memory symbol, string memory tokenURIPrefix) external returns(address addr) {
		addr = address(new MarleyDigitalMediaUserToken1155{salt: _salt}(name, symbol, tokenURIPrefix));
		MarleyDigitalMediaUserToken1155 token = MarleyDigitalMediaUserToken1155(address(addr));
		token.transferOwnership(msg.sender);
		emit Deployed(msg.sender, addr);
	}
}