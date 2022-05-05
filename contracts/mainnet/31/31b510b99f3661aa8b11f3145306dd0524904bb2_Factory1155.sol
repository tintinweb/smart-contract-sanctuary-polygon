//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "./SPARKUserToken1155.sol";

contract Factory1155 {
	event Deployed(address owner, address contractAddress);

	function deploy(bytes32 _salt, string memory name, string memory symbol, string memory tokenURIPrefix) external returns(address addr) {
		addr = address(new SPARKUserToken1155{salt: _salt}(name, symbol, tokenURIPrefix));
		SPARKUserToken1155 token = SPARKUserToken1155(address(addr));
		token.transferOwnership(msg.sender);
		emit Deployed(msg.sender, addr);
	}
}