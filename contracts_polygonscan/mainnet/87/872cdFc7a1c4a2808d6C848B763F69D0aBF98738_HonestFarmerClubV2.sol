// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 *
 *  __    __   ______   __       __  _______   __      __
 * 	/  |  /  | /      \\ /  |  _  /  |/       \\ /  \\    /  |
 * 	$$ |  $$ |/$$$$$$  |$$ | / \\ $$ |$$$$$$$  |$$  \\  /$$/
 * 	$$ |__$$ |$$ |  $$ |$$ |/$  \\$$ |$$ |  $$ | $$  \\/$$/
 * 	$$    $$ |$$ |  $$ |$$ /$$$  $$ |$$ |  $$ |  $$  $$/
 * 	$$$$$$$$ |$$ |  $$ |$$ $$/$$ $$ |$$ |  $$ |   $$$$/
 * 	$$ |  $$ |$$ \\__$$ |$$$$/  $$$$ |$$ |__$$ |    $$ |
 * 	$$ |  $$ |$$    $$/ $$$/    $$$ |$$    $$/     $$ |
 * 	$$/   $$/  $$$$$$/  $$/      $$/ $$$$$$$/      $$/
 *
 * Just some honest farmers loving open source software, check out our Discord!
 *
 */

// Interfaces
import "./ERC1155.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./IHonestFarmerClubV2.sol";
import "./IMetaFarmer.sol";
import "./IWhitelistFarmer.sol";
import "./IMigrationTractor.sol";
import "./IRegistryFarmer.sol";

import "./LibraryFarmer.sol";

contract HonestFarmerClubV2 is IHonestFarmerClubV2, ERC1155, Ownable {
	using LibraryFarmer for LibraryFarmer.MintType;
	using LibraryFarmer for LibraryFarmer.FarmerContract;
	using Counters for Counters.Counter;

	// Events
	event MintFarmers(
		LibraryFarmer.MintType indexed mintType,
		uint256 numberOfFarmers
	);

	// Infrastructure
	IRegistryFarmer registryFarmer;

	// Metadata
	string public name = "Honest Farmer Club";
	string public symbol = "HFC";
	string public contractURI;
	uint256 private constant _MAX_FARMER_SUPPLY = 3000;
	Counters.Counter private _numberOfPostMigrationFarmersMinted;

	// Minting
	bool public mintIsLive = false;
	bool public whitelistMintIsLive = false;
	bool public freeFarmerMintIsLive = false;
	uint256 public mintPriceMATIC;
	uint256 public mintPriceMATICWhitelist;
	uint256 public constant MINT_WHALE_TX_CAP = 10;

	constructor(IRegistryFarmer _registryFarmer, string memory _contractURI)
		ERC1155("")
	{
		// Infrastructure
		registryFarmer = _registryFarmer;

		// Royalties
		contractURI = _contractURI;
	}

	modifier mintTypeIsLive(LibraryFarmer.MintType mintType) {
		if (mintType == LibraryFarmer.MintType.PUBLIC) {
			require(mintIsLive, "Minting is not live");
			_;
		}
		if (mintType == LibraryFarmer.MintType.WHITELIST) {
			require(whitelistMintIsLive, "Whitelist mint is not live");
			_;
		}
		if (mintType == LibraryFarmer.MintType.FREE) {
			require(freeFarmerMintIsLive, "Free farmer mint is not live");
			_;
		}
	}

	modifier hasPaidEnoughMATIC(
		uint256 paidAmountMATIC,
		uint256 numberOfHonestFarmers,
		bool isWhitelist
	) {
		require(
			paidAmountMATIC >=
				getTotalMATICPayableAmount(numberOfHonestFarmers, isWhitelist),
			"Not enough MATIC paid"
		);
		_;
	}

	modifier noWhalesInHere(uint256 numberOfHonestFarmers) {
		require(
			numberOfHonestFarmers <= MINT_WHALE_TX_CAP,
			"No whales in here, sorry"
		);
		_;
	}

	modifier onlyMigrationTractor() {
		require(
			msg.sender ==
				registryFarmer.contracts(
					LibraryFarmer.FarmerContract.MigrationTractor
				),
			"Only migration tractor can migrate"
		);
		_;
	}

	function _mintFarmers(address to, uint256 numberOfHonestFarmers) private {
		IMigrationTractor migrationTractor = IMigrationTractor(
			registryFarmer.contracts(
				LibraryFarmer.FarmerContract.MigrationTractor
			)
		);
		uint256 newFarmerSupply = numberOfPostMigrationFarmersMinted() +
			migrationTractor.PRE_MIGRATION_TOKEN_COUNT() +
			numberOfHonestFarmers;
		require(
			newFarmerSupply <= _MAX_FARMER_SUPPLY,
			"Mint would exceed MAX_FARMER_SUPPLY"
		);

		uint256[] memory ids = new uint256[](numberOfHonestFarmers);
		uint256[] memory amounts = new uint256[](numberOfHonestFarmers);

		for (uint256 i = 0; i < numberOfHonestFarmers; i++) {
			_numberOfPostMigrationFarmersMinted.increment();

			uint256 id = numberOfPostMigrationFarmersMinted() +
				migrationTractor.PRE_MIGRATION_TOKEN_COUNT();

			ids[i] = id;
			amounts[i] = 1;
		}

		_mintBatch(to, ids, amounts, "");
	}

	function mintFarmers(uint256 numberOfHonestFarmers)
		public
		payable
		mintTypeIsLive(LibraryFarmer.MintType.PUBLIC)
		hasPaidEnoughMATIC(msg.value, numberOfHonestFarmers, false)
		noWhalesInHere(numberOfHonestFarmers)
	{
		_mintFarmers(msg.sender, numberOfHonestFarmers);
		emit MintFarmers(LibraryFarmer.MintType.PUBLIC, numberOfHonestFarmers);
	}

	function mintWhitelistFarmers(uint256 numberOfHonestFarmers)
		public
		payable
		mintTypeIsLive(LibraryFarmer.MintType.WHITELIST)
		hasPaidEnoughMATIC(msg.value, numberOfHonestFarmers, true)
	{
		IWhitelistFarmer whitelistFarmer = IWhitelistFarmer(
			registryFarmer.contracts(
				LibraryFarmer.FarmerContract.WhitelistFarmer
			)
		);
		uint256 allocation = whitelistFarmer.getAllocation(
			LibraryFarmer.MintType.WHITELIST,
			msg.sender
		);
		require(
			allocation >= numberOfHonestFarmers,
			"Mint would exceed whitelist allocation"
		);

		_mintFarmers(msg.sender, numberOfHonestFarmers);
		whitelistFarmer.decreaseAllocation(
			LibraryFarmer.MintType.WHITELIST,
			msg.sender,
			numberOfHonestFarmers
		);

		emit MintFarmers(
			LibraryFarmer.MintType.WHITELIST,
			numberOfHonestFarmers
		);
	}

	function mintFreeFarmers()
		public
		mintTypeIsLive(LibraryFarmer.MintType.FREE)
	{
		IWhitelistFarmer whitelistFarmer = IWhitelistFarmer(
			registryFarmer.contracts(
				LibraryFarmer.FarmerContract.WhitelistFarmer
			)
		);
		uint256 freeFarmerAllocation = whitelistFarmer.getAllocation(
			LibraryFarmer.MintType.FREE,
			msg.sender
		);
		require(
			freeFarmerAllocation > 0,
			"No allocation found or already minted"
		);

		_mintFarmers(msg.sender, freeFarmerAllocation);
		whitelistFarmer.decreaseAllocation(
			LibraryFarmer.MintType.FREE,
			msg.sender,
			freeFarmerAllocation
		);

		emit MintFarmers(LibraryFarmer.MintType.FREE, freeFarmerAllocation);
	}

	function migrateFarmers(address to, uint256[] memory ids)
		external
		onlyMigrationTractor
	{
		uint256[] memory amounts = new uint256[](ids.length);

		for (uint256 i = 0; i < ids.length; i++) {
			amounts[i] = 1;
		}

		_mintBatch(to, ids, amounts, "");
	}

	function uri(uint256 tokenId) public view override returns (string memory) {
		IMetaFarmer metaFarmer = IMetaFarmer(
			registryFarmer.contracts(LibraryFarmer.FarmerContract.MetaFarmer)
		);
		return metaFarmer.uri(tokenId);
	}

	function setMintPrices(
		uint256 _mintPriceMATIC,
		uint256 _mintPriceMATICWhitelist
	) public onlyOwner {
		require(_mintPriceMATIC > 0, "Mint price must be greater than 0");
		require(
			_mintPriceMATICWhitelist > 0,
			"Whitelist mint price must be greater than 0"
		);

		mintPriceMATIC = _mintPriceMATIC;
		mintPriceMATICWhitelist = _mintPriceMATICWhitelist;
	}

	function toggleMint(LibraryFarmer.MintType mintType) public onlyOwner {
		require(
			mintPriceMATIC > 0 && mintPriceMATICWhitelist > 0,
			"Mint prices must be set"
		);

		if (mintType == LibraryFarmer.MintType.PUBLIC) {
			mintIsLive = !mintIsLive;
		}
		if (mintType == LibraryFarmer.MintType.WHITELIST) {
			whitelistMintIsLive = !whitelistMintIsLive;
		}
		if (mintType == LibraryFarmer.MintType.FREE) {
			freeFarmerMintIsLive = !freeFarmerMintIsLive;
		}
	}

	function withdrawFunds() public onlyOwner {
		uint256 maticBalance = address(this).balance;
		payable(msg.sender).transfer(maticBalance);
	}

	function setContractURI(string memory _contractURI) public onlyOwner {
		contractURI = _contractURI;
	}

	function getTotalMATICPayableAmount(
		uint256 numberOfHonestFarmers,
		bool isWhitelist
	) public view returns (uint256) {
		return
			(isWhitelist ? mintPriceMATICWhitelist : mintPriceMATIC) *
			numberOfHonestFarmers;
	}

	function numberOfPostMigrationFarmersMinted()
		public
		view
		returns (uint256)
	{
		return _numberOfPostMigrationFarmersMinted.current();
	}

	function tokenCount() public view returns (uint256) {
		IMigrationTractor migrationTractor = IMigrationTractor(
			registryFarmer.contracts(
				LibraryFarmer.FarmerContract.MigrationTractor
			)
		);
		return
			numberOfPostMigrationFarmersMinted() +
			migrationTractor.migrationCount();
	}

	function MAX_FARMER_SUPPLY() public view returns (uint256) {
		return _MAX_FARMER_SUPPLY;
	}
}