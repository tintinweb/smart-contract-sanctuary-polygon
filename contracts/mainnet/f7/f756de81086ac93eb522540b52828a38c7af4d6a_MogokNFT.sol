// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./AccessControl.sol";

// 0x625786cbf7c2b0b4d369536ca30bbf9955dfe781
interface URIProvider {
	function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// 0x9a686c68AfD68cd66431EAF89ACA196e6Df6a077
interface mogokDataProvider {
	function mogokExists(uint256 x, uint256 y, uint256 z) external view returns (bool);
}

contract MogokNFT is ERC721, ERC721Burnable, AccessControl {
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	mogokDataProvider public constant dataProvider = mogokDataProvider(address(0x9a686c68AfD68cd66431EAF89ACA196e6Df6a077));
	URIProvider public uriProvider = URIProvider(address(0x625786CBf7C2b0B4D369536CA30Bbf9955Dfe781));

	event updatedUriProvider(address indexed provider);

	constructor() ERC721("MogokNFT", "MOGOK") {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_grantRole(MINTER_ROLE, msg.sender);
	}

	function safeMint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
		require(mogokExists(tokenId));
		_safeMint(to, tokenId);
	}

	function setUriProvider(address provider) external onlyRole(DEFAULT_ADMIN_ROLE) {
		uriProvider = URIProvider(provider);
		emit updatedUriProvider(provider);
	}

	function mogokExists(uint256 _tokenId) internal view returns (bool) {
		uint256 x = (_tokenId >> 16) & 0xff;
		uint256 y = (_tokenId >> 8) & 0xff;
		uint256 z = _tokenId & 0xff;

		return dataProvider.mogokExists(x, y, z);
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(mogokExists(_tokenId));

		return uriProvider.tokenURI(_tokenId);
	}

	// The following functions are overrides required by Solidity.

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, AccessControl)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
}