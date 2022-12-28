// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./IERC721Receiver.sol";
import "./IERC721Enumerable.sol";
import "./IERC721.sol";

contract NFTDispenser is ERC20, IERC721Receiver {
	event AddedNFT(address indexed operator, address indexed from, uint256 indexed tokenId, bytes data);
	event RetrievedNFT(address indexed recipient, uint256 indexed tokenId, bytes data);

	address public constant nftContract = address(0x3370Bb7f2F214507255115a509A274EDEAEEB247);

	constructor() ERC20("MOGOK Redeemable Ticket", "MRT") {}

	function token() external pure returns (address) {
		return nftContract;
	}

	function redeem(address recipient, uint256 tokenId, bytes calldata data) public {
		require(recipient != address(0), "MRT: invalid recipient");
		emit RetrievedNFT(recipient, tokenId, data);
		_burn(_msgSender(), 10 ** decimals());
		IERC721(nftContract).safeTransferFrom(address(this), recipient, tokenId, data);
	}

	function redeemAny(address recipient, bytes calldata data) external {
		uint256 tokenId = IERC721Enumerable(nftContract).tokenOfOwnerByIndex(address(this), 0);
		redeem(recipient, tokenId, data);
	}

	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
		require(_msgSender() == nftContract, "MRT: invalid NFT for this recipient");
		emit AddedNFT(operator, from, tokenId, data);
		if (from == address(0)) {
			// this is minted directly to this contract → issue token to their addr
			from = address(0xA961B746090b0Cf7519e7dEeFC6F641E3226fEA2);
		}
		_mint(from, 10 ** decimals());
		return IERC721Receiver.onERC721Received.selector;
	}
}