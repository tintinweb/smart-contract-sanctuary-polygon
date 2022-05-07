//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "./OwnBafNft1155.sol";

contract Factory1155 {
	event Deployed(address owner, address contractAddress);

	function deploy(bytes32 _salt, string memory name, string memory symbol, string memory tokenURIPrefix) external returns(address addr) {
		addr = address(new AfrofuturismUserToken1155{salt: _salt}(name, symbol, tokenURIPrefix));
		AfrofuturismUserToken1155 token = AfrofuturismUserToken1155(address(addr));
		token.transferOwnership(msg.sender);
		emit Deployed(msg.sender, addr);
	}
}