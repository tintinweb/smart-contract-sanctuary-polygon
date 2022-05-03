//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./Brilliance1155.sol";

contract Factory {
	event Deployed(address owner, address contractAddress);

	function deploy(bytes32 _salt, string memory name, string memory symbol, string memory tokenURIPrefix) external returns(address addr) {
		addr = address(new BrillianceUserToken1155{salt: _salt}(name, symbol, tokenURIPrefix));
		BrillianceUserToken1155 token = BrillianceUserToken1155(address(addr));
		token.transferOwnership(msg.sender);
		emit Deployed(msg.sender, addr);
	}
}