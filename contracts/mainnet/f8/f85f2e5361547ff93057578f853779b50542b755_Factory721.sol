//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "./SPARKUserToken721.sol";

contract Factory721 {

	event Deployed(address owner, address contractAddress);

	function deploy(bytes32 _salt, string memory name, string memory symbol, string memory tokenURIPrefix) external returns(address addr) {
		addr = address(new SPARKUserToken721{salt: _salt}(name, symbol, tokenURIPrefix));
		SPARKUserToken721 token = SPARKUserToken721(address(addr));
		token.transferOwnership(msg.sender);
		emit Deployed(msg.sender, addr);
	}
}