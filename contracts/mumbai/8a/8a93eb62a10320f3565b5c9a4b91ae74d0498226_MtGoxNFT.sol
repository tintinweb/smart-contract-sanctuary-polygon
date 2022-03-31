// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./draft-ERC721Votes.sol";
import "./MtGoxNFTmetaLinkInterface.sol";

// The MtGoxNFT contract is based on the ERC-721 standard with some extra features such as NFT weight

contract MtGoxNFT is ERC721, ERC721Enumerable, Ownable, EIP712, ERC721Votes, MtGoxInfoApi {
	mapping(address => bool) _issuers;

	// meta-data stored for each NFT
	struct MetaInfo {
		uint64 fiatWeight;
		uint64 satoshiWeight;
		uint32 registrationDate;
		uint256 tradeVolume;
		string url;
	}
	mapping(uint256 => MetaInfo) private _meta;

	// total values for in circulation NFTs
	uint256 public totalFiatWeight;
	uint256 public totalSatoshiWeight;
	uint256 public totalTradeVolume;

	MtGoxNFTmetaLinkInterface private _linkInterface;
	bool private _linkInterfaceLocked;

	event LinkInterfaceChanged(MtGoxNFTmetaLinkInterface newInterface);
	event IssuerGranted(address indexed issuer);
	event IssuerRevoked(address indexed issuer);

	// *** CODE

	constructor() ERC721("MtGoxNFT", "MGN") EIP712("MtGoxNFT", "1") {}

	// return value from link interface
	function contractURI() public view returns (string memory) {
		if (address(_linkInterface) != address(0)) {
			return _linkInterface.contractURI(this);
		}

		return "";
	}

	// return value from link interface
	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		if (address(_linkInterface) != address(0)) {
			return _linkInterface.tokenURI(this, _tokenId);
		}

		return "";
	}

	// method to update the link interface if it has not been locked
	function setLinkInterface(MtGoxNFTmetaLinkInterface _intf) external onlyOwner {
		require(!_linkInterfaceLocked, "MtGoxNFT: cannot change interface (locked)");
		_linkInterface = _intf;
		emit LinkInterfaceChanged(_intf);
	}

	// method to lock the link interface
	function lockLinkInterface() external onlyOwner {
		require(!_linkInterfaceLocked, "MtGoxNFT: link interface already locked");
		_linkInterfaceLocked = true;
	}

	// mint NFT as issuer directly (not through sign)
	function mint(uint256 tokenId, address recipient, uint64 paramFiatWeight, uint64 paramSatoshiWeight, uint32 paramRegDate, uint256 paramTradeVolume, string memory url) external onlyIssuer {
		_meta[tokenId] = MetaInfo({
			fiatWeight: paramFiatWeight,
			satoshiWeight: paramSatoshiWeight,
			registrationDate: paramRegDate,
			tradeVolume: paramTradeVolume,
			url: url
		});
		totalFiatWeight = totalFiatWeight + paramFiatWeight;
		totalSatoshiWeight = totalSatoshiWeight + paramSatoshiWeight;
		totalTradeVolume = totalTradeVolume + paramTradeVolume;

		_safeMint(recipient, tokenId); // _mint will fail if this NFT was already issued
	}

	// store url for a given token
	// this sets the final url for a token, when the image is stored to IPFS
	function setUrl(uint256 tokenId, string memory url) external onlyIssuer {
		require(_exists(tokenId), "MtGoxNFT: setUrl for nonexistent NFT");
		require(bytes(_meta[tokenId].url).length == 0, "MtGoxNFT: cannot set an URL twice");

		// should we emit an event for the updated url?

		_meta[tokenId].url = url;
	}

	// return stored url for a given token
	function getUrl(uint256 tokenId) external view returns (string memory) {
		require(_exists(tokenId), "MtGoxNFT: weight query for nonexistent NFT");

		return _meta[tokenId].url;
	}

	function fiatWeight(uint256 tokenId) external view returns (uint64) {
		require(_exists(tokenId), "MtGoxNFT: weight query for nonexistent NFT");

		return _meta[tokenId].fiatWeight;
	}

	function satoshiWeight(uint256 tokenId) external view returns (uint64) {
		require(_exists(tokenId), "MtGoxNFT: weight query for nonexistent NFT");

		return _meta[tokenId].satoshiWeight;
	}

	function registrationDate(uint256 tokenId) external view returns (uint32) {
		require(_exists(tokenId), "MtGoxNFT: registration date query for nonexistent NFT");

		return _meta[tokenId].registrationDate;
	}

	function tradeVolume(uint256 tokenId) external view returns (uint256) {
		require(_exists(tokenId), "MtGoxNFT: trade volume query for nonexistent NFT");

		return _meta[tokenId].tradeVolume;
	}

	// issuer management
	function grantIssuer(address account) external onlyOwner {
		_issuers[account] = true;
		emit IssuerGranted(account);
	}

	function revokeIssuer(address account) external onlyOwner {
		delete _issuers[account];
		emit IssuerRevoked(account);
	}

	// allow a issuer to revoke itself
	function revokeIssuerSelf() external onlyIssuer {
		delete _issuers[_msgSender()];
		emit IssuerRevoked(_msgSender());
	}

	modifier onlyIssuer {
		require(_issuers[_msgSender()], "MtGoxNFT: method only available to issuers");
		_;
	}

	// The following functions are overrides required by Solidity.

	function _beforeTokenTransfer(address from, address to, uint256 tokenId)
		internal
		override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function _afterTokenTransfer(address from, address to, uint256 tokenId)
		internal
		override(ERC721, ERC721Votes) {
		super._afterTokenTransfer(from, to, tokenId);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, ERC721Enumerable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
}