// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Ownable.sol";
import "./Strings.sol";
import "./MtGoxNFT.sol";
import "./MtGoxNFTmetaLinkInterface.sol";

// The MtGoxNFT contract is based on the ERC-721 standard with some extra features such as NFT weight

contract MtGoxNFTmetaLink is Ownable, MtGoxNFTmetaLinkInterface {
	constructor() {
	}

	function tokenURI(MtGoxInfoApi _contract, uint256 _tokenId) external view returns (string memory) {
		// string(abi.encodePacked(...)) means concat strings
		// Strings.toString() returns an int value
		// Strings.toHexString() returns a hex string starting with 0x
		// see: https://docs.opensea.io/docs/metadata-standards

		string memory tokenIdStr = Strings.toString(_tokenId);
		string memory tokenUrl = _contract.getUrl(_tokenId);
		if (bytes(tokenUrl).length == 0) {
			tokenUrl = string(abi.encodePacked("https://data.mtgoxnft.net/by-id/", tokenIdStr, ".png"));
		}

		string memory tokenName;
		if (_tokenId > 0xffffffff) {
			// if anonymous token, do not show the token id
			tokenName = "Anonymous MtGox NFT";
		} else {
			// show the token id (= MtGox account ID)
			tokenName = string(abi.encodePacked("MtGox NFT %23", tokenIdStr));
		}

		// TODO keep this as data uri or just point to a static file? Seems json takes a lot of room in the contract code

		return string(abi.encodePacked(
			// name
			"data:application/json,{%22name%22:%22",
			tokenName,
			// external_url
			"%22,%22external_url%22:%22https://data.mtgoxnft.net/by-id/",
			tokenIdStr,
			// image
			"%22,%22image%22:%22",
			tokenUrl,
			// attributes → Registered (date)
			"%22,%22attributes%22:[{%22display_type%22:%22date%22,%22trait_type%22:%22Registered%22,%22value%22:",
			Strings.toString(_contract.registrationDate(_tokenId)),
			// attributes → Fiat
			"},{%22trait_type%22:%22Fiat%22,%22value%22:",
			Strings.toString(_contract.fiatWeight(_tokenId)),
			"},{%22trait_type%22:%22Bitcoin%22,%22value%22:",
			Strings.toString(_contract.satoshiWeight(_tokenId)),
			"},{%22trait_type%22:%22Trade Volume%22,%22value%22:",
			Strings.toString(_contract.tradeVolume(_tokenId)),
			"}]}"
		));
	}
}