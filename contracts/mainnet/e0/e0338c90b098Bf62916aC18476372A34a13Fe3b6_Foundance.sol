// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./storage/FoundanceStorage.sol";

import "./interfaces/IFoundance.sol";
import "./interfaces/IDaoRegistry.sol";

import "../adapters/interfaces/IDynamicEquityAdapter.sol";
import "../extensions/interfaces/IVotingExtension.sol";
import "../extensions/interfaces/IERC20Extension.sol";
import "../extensions/interfaces/IMemberExtension.sol";
import "../extensions/interfaces/IDynamicEquityExtension.sol";

import "hardhat/console.sol";

/// @title Foundance
/// @author B. Teke
/// @author L. Eich @lSoonami
/// @notice This contract is used to manage and create modular DAO Agreements
/// @dev Intended to be used with Lighthouse Proxy
contract Foundance is FoundanceStorage, IFoundance {
	/**
	 * MODIFIER
	 */

	/**
	 * @dev This modifier is used to prevent reentrancy attacks on the contract
	 * @param foundanceId the unique identifier of a project
	 */
	modifier reentrancyGuard(uint32 foundanceId) {
		LockedAt storage lockedAt = _lockedAt();

		if (lockedAt.data[foundanceId] == block.number) revert Foundance_ProjectLocked(foundanceId);

		lockedAt.data[foundanceId] = block.number;
		_;

		lockedAt.data[foundanceId] = 0;
	}

	/**
	 * @dev This modifier is used to check if the caller is the Creator of a Foundance Agreement
	 * @param foundanceName the name of the Foundance Agreement
	 */
	modifier onlyCreator(string calldata foundanceName) {
		FoundanceConfigs storage foundanceConfigs = _foundanceConfigs();

		if (foundanceConfigs.data[foundanceName].creatorAddress != msg.sender)
			revert Foundance_OnlyCreator();

		_;
	}

	/**
	 * @dev This modifier is used to check if the caller is an Admin
	 */
	modifier onlyAdmin() {
		IsAdmin storage isAdmin = _isAdmin();

		if (!isAdmin.data[msg.sender]) revert Foundance_OnlyAdmin();

		_;
	}

	function initialize() external {
		IsAdmin storage isAdmin = _isAdmin();

		if (_initialized().data) revert Foundance_AlreadyInitialized();

		isAdmin.data[msg.sender] = true;
	}

	/**
	 * EXTERNAL FUNCTIONS
	 */

	/// @inheritdoc IFoundance
	function registerFoundance(
		string calldata foundanceName,
		uint32 foundanceId,
		FoundanceLibrary.FoundanceMemberConfig[] memory foundanceMemberConfigArray,
		BankExtensionLibrary.TokenConfig calldata tokenConfig,
		VotingExtensionLibrary.VotingConfig calldata votingConfig,
		DaoRegistryLibrary.EpochConfig calldata epochConfig,
		DynamicEquityExtensionLibrary.DynamicEquityConfig calldata dynamicEquityConfig,
		VestedEquityExtensionLibrary.VestedEquityConfig calldata vestedEquityConfig,
		CommunityEquityExtensionLibrary.CommunityEquityConfig calldata communityEquityConfig,
		bytes memory documentHash
	) external reentrancyGuard(foundanceId) {
		FoundanceNames storage foundanceNames = _foundanceNames();
		FoundanceMemberConfigIndex
			storage foundanceMemberConfigIndex = _foundanceMemberConfigIndex();
		FoundanceConfigs storage foundanceConfigs = _foundanceConfigs();
		FoundanceLibrary.FoundanceConfig storage foundance = foundanceConfigs.data[foundanceName];

		if (foundance.foundanceStatus == FoundanceLibrary.FoundanceStatus.LIVE)
			revert Foundance_IsAlreadyLive();

		if (
			foundance.foundanceStatus == FoundanceLibrary.FoundanceStatus.REGISTERED ||
			(foundance.foundanceStatus == FoundanceLibrary.FoundanceStatus.APPROVED &&
				foundance.foundanceId != 0)
		) {
			if (msg.sender != foundance.creatorAddress) revert Foundance_OnlyCreator();

			FoundanceLibrary.FoundanceMemberConfig[] memory tempfactoryMemberConfigArray = foundance
				.foundanceMemberConfigArray;
			for (uint256 i = 0; i < tempfactoryMemberConfigArray.length; i++) {
				foundanceMemberConfigIndex.data[foundanceName][
					tempfactoryMemberConfigArray[i].memberAddress
				] = 0;
				foundance.foundanceMemberConfigArray.pop();
			}

			emit FoundanceUpdatedEvent(msg.sender, foundanceId);
		} else {
			if (
				_modules().data.daoFactory.getDaoAddressByName(foundanceName) != address(0x0) ||
				foundance.creatorAddress != address(0x0)
			) revert Foundance_NameAlreadyTaken();

			if (bytes(foundanceNames.data[foundanceId]).length != 0)
				revert Foundance_IdAlreadyTaken();

			foundanceNames.data[foundanceId] = foundanceName;

			foundance.creatorAddress = msg.sender;
			foundance.foundanceId = foundanceId;

			emit FoundanceRegisteredEvent(msg.sender, foundanceId, foundanceName);
		}

		foundance.tokenConfig = tokenConfig;
		foundance.votingConfig = votingConfig;
		foundance.epochConfig = epochConfig;
		foundance.dynamicEquityConfig = dynamicEquityConfig;
		foundance.vestedEquityConfig = vestedEquityConfig;
		foundance.communityEquityConfig = communityEquityConfig;
		foundance.documentHash = documentHash;

		for (uint256 i = 0; i < foundanceMemberConfigArray.length; i++) {
			foundanceMemberConfigArray[i].foundanceApproved = false;
			foundance.foundanceMemberConfigArray.push(foundanceMemberConfigArray[i]);
			foundanceMemberConfigIndex.data[foundanceName][
				foundanceMemberConfigArray[i].memberAddress
			] = i + 1;
		}

		foundance
			.foundanceMemberConfigArray[
				foundanceMemberConfigIndex.data[foundanceName][msg.sender] - 1
			]
			.foundanceApproved = true;
		foundance.foundanceStatus = FoundanceLibrary.FoundanceStatus.REGISTERED;
	}

	/// @inheritdoc IFoundance
	function approveFoundance(string calldata foundanceName) external {
		FoundanceConfigs storage foundanceConfigs = _foundanceConfigs();
		FoundanceMemberConfigIndex
			storage foundanceMemberConfigIndex = _foundanceMemberConfigIndex();
		FoundanceLibrary.FoundanceConfig storage foundance = foundanceConfigs.data[foundanceName];

		if (foundance.creatorAddress == address(0x0)) revert Foundance_DoesNotExist();

		if (foundanceMemberConfigIndex.data[foundanceName][msg.sender] == 0)
			revert Foundance_MemberDoesntExists();

		foundance
			.foundanceMemberConfigArray[
				foundanceMemberConfigIndex.data[foundanceName][msg.sender] - 1
			]
			.foundanceApproved = true;

		if (_isFoundanceApproved(foundance))
			foundance.foundanceStatus = FoundanceLibrary.FoundanceStatus.APPROVED;

		emit FoundanceApprovedEvent(msg.sender, foundance.foundanceId, foundanceName);
	}

	/// @inheritdoc IFoundance
	//slither-disable-next-line reentrancy-events
	function createFoundance(string calldata foundanceName) external onlyCreator(foundanceName) {
		FoundanceLibrary.Modules storage modules = _modules().data;
		FoundanceLibrary.FoundanceConfig storage foundance = _foundanceConfigs().data[
			foundanceName
		];
		ModuleAddresses storage moduleAddresses = _moduleAddresses();
		DaoAddresses storage daoAddresses = _daoAddresses();

		if (!_isFoundanceApproved(foundance)) revert Foundance_NotApproved();

		foundance.foundanceStatus = FoundanceLibrary.FoundanceStatus.LIVE;

		modules.daoFactory.createDao(foundanceName, msg.sender, address(modules.lighthouse));

		address daoAddress = modules.daoFactory.getDaoAddressByName(foundanceName);

		IDaoRegistry daoRegistry = IDaoRegistry(daoAddress);

		daoAddresses.data.push(daoAddress);

		modules.daoFactory.setConfiguration(daoRegistry, _configurations().data);

		for (uint256 i = 0; i < modules.moduleArray.length; i++) {
			FoundanceLibrary.Module storage module = modules.moduleArray[i];

			if (module.moduleType == DaoFactoryLibrary.ModuleType.EXTENSION) {
				modules.extensionFactory.create(
					daoRegistry,
					address(modules.lighthouse),
					module.moduleId
				);

				module.moduleAddress = modules.extensionFactory.getExtension(
					address(daoRegistry),
					module.moduleId
				);

				daoRegistry.addExtension(module.moduleId, IExtension(module.moduleAddress));
			} else if (module.moduleType == DaoFactoryLibrary.ModuleType.ADAPTER)
				if (moduleAddresses.data[address(this)][module.moduleId] != address(0x0))
					module.moduleAddress = moduleAddresses.data[address(this)][module.moduleId];

			daoRegistry.replaceAdapter(
				module.moduleId,
				module.moduleAddress,
				module.daoRegistryAclFlags,
				new bytes32[](0),
				new uint256[](0)
			);

			moduleAddresses.data[address(daoRegistry)][module.moduleId] = module.moduleAddress;
		}

		for (uint256 i = 0; i < modules.moduleArray.length; i++) {
			FoundanceLibrary.Module storage module = modules.moduleArray[i];
			if (module.moduleType == DaoFactoryLibrary.ModuleType.EXTENSION) {
				for (uint256 j = 0; j < module.extensionAclFlags.length; j++) {
					daoRegistry.setAclToExtensionForAdapter(
						module.moduleAddress,
						moduleAddresses.data[address(daoRegistry)][module.extensionAclIds[j]],
						module.extensionAclFlags[j]
					);
				}
			}
		}

		_createFoundanceInternal(daoRegistry, foundance);

		daoRegistry.finalizeDao();

		daoRegistry.replaceAdapter(
			DaoLibrary.FOUNDANCE,
			address(0x0),
			0,
			new bytes32[](0),
			new uint256[](0)
		);

		emit FoundanceLiveEvent(msg.sender, foundance.foundanceId, address(daoRegistry));
	}

	/// @inheritdoc IFoundance
	function addAdmins(address[] calldata admins) external onlyAdmin {
		IsAdmin storage isAdmin = _isAdmin();

		for (uint256 i = 0; i < admins.length; i++) {
			isAdmin.data[admins[i]] = true;
		}
	}

	/// @inheritdoc IFoundance
	function removeAdmins(address[] calldata admins) external onlyAdmin {
		IsAdmin storage isAdmin = _isAdmin();

		for (uint256 i = 0; i < admins.length; i++) {
			isAdmin.data[admins[i]] = false;
		}
	}

	/// @inheritdoc IFoundance
	function setIdtoDaoName(uint32 foundanceId, string calldata foundanceName) external onlyAdmin {
		FoundanceNames storage foundanceNames = _foundanceNames();

		foundanceNames.data[foundanceId] = foundanceName;
	}

	/// @inheritdoc IFoundance
	function setModules(
		address lighthouseAddress,
		address daoFactoryAddress,
		address extensionFactoryAddress,
		FoundanceLibrary.Module[] memory moduleArray,
		bytes32[] memory adapterIds,
		address[] memory adapterAddresses
	) external onlyAdmin {
		_setModules(
			lighthouseAddress,
			daoFactoryAddress,
			extensionFactoryAddress,
			moduleArray,
			adapterIds,
			adapterAddresses
		);
	}

	/// @inheritdoc IFoundance
	function setConfigurations(
		DaoFactoryLibrary.Configuration[] memory newConfigurations
	) external onlyAdmin {
		_setConfigurations(newConfigurations);
	}

	function setImplementation(
		address[] memory newImplementationAddresses,
		bytes32[] memory newImplementationIds
	) external onlyAdmin {
		_setImplementation(newImplementationAddresses, newImplementationIds);
	}

	/**
	 * INTERNAL FUNCTIONS
	 */

	/**
	 * @param newConfigurations setConfigurations()
	 **/
	function _setConfigurations(
		DaoFactoryLibrary.Configuration[] memory newConfigurations
	) internal {
		Configurations storage configurations = _configurations();
		configurations.data = new DaoFactoryLibrary.Configuration[](newConfigurations.length);

		for (uint256 i = 0; i < newConfigurations.length; i++) {
			configurations.data[i] = DaoFactoryLibrary.Configuration({
				key: newConfigurations[i].key,
				configType: newConfigurations[i].configType,
				numericValue: newConfigurations[i].numericValue,
				addressValue: newConfigurations[i].addressValue
			});
		}

		configurations.data = newConfigurations;
	}

	function _setModules(
		address lighthouseAddress,
		address daoFactoryAddress,
		address extensionFactoryAddress,
		FoundanceLibrary.Module[] memory moduleArray,
		bytes32[] memory adapterIds,
		address[] memory adapterAddresses
	) internal {
		ModuleAddresses storage moduleAddresses = _moduleAddresses();

		FoundanceLibrary.Modules storage modules = _modules().data;

		modules.lighthouse = ILighthouse(lighthouseAddress);

		if (modules.lighthouse.isInitialized(address(this)))
			modules.lighthouse.initializeSource(address(this), address(this));

		modules.daoFactory = IDaoFactory(daoFactoryAddress);
		moduleAddresses.data[address(this)][DaoLibrary.DAO_EXT_FACTORY] = daoFactoryAddress;

		modules.extensionFactory = IExtensionFactory(extensionFactoryAddress);
		moduleAddresses.data[address(this)][DaoLibrary.EXT_FACTORY] = extensionFactoryAddress;

		modules.moduleArray = moduleArray;

		modules.adapterIds = adapterIds;

		for (uint256 i = 0; i < adapterIds.length; i++)
			moduleAddresses.data[address(this)][adapterIds[i]] = adapterAddresses[i];
	}

	/**
	 * @param newImplementationAddresses setImplementation()
	 * @param newImplementationIds setImplementation()
	 **/
	function _setImplementation(
		address[] memory newImplementationAddresses,
		bytes32[] memory newImplementationIds
	) internal {
		ImplementationAddresses storage implementationAddresses = _implementationAddresses();
		ImplementationIds storage implementationIds = _implementationIds();
		FoundanceLibrary.Modules storage modules = _modules().data;

		implementationAddresses.data = newImplementationAddresses;
		implementationIds.data = newImplementationIds;

		ILighthouse lighthouse = ILighthouse(modules.lighthouse);
		lighthouse.changeImplementationBatch(
			address(this),
			newImplementationAddresses,
			newImplementationIds
		);
	}

	function _createFoundanceInternal(
		IDaoRegistry daoRegistry,
		FoundanceLibrary.FoundanceConfig storage foundanceConfig
	) internal {
		ModuleAddresses storage moduleAddresses = _moduleAddresses();

		if (moduleAddresses.data[address(daoRegistry)][DaoLibrary.VOTING_EXT] != address(0x0)) {
			IVotingExtension voting = IVotingExtension(
				moduleAddresses.data[address(daoRegistry)][DaoLibrary.VOTING_EXT]
			);

			voting.setVotingConfig(daoRegistry, foundanceConfig.votingConfig, bytes32(0));
			voting.setDocument(
				daoRegistry,
				bytes32(0x0),
				DaoLibrary.CONTRACT,
				foundanceConfig.documentHash
			);
		}

		if (moduleAddresses.data[address(daoRegistry)][DaoLibrary.BANK_EXT] != address(0x0)) {
			IBankExtension bank = IBankExtension(
				moduleAddresses.data[address(daoRegistry)][DaoLibrary.BANK_EXT]
			);

			bank.registerPotentialNewInternalToken(daoRegistry, DaoLibrary.UNITS);
		}

		if (moduleAddresses.data[address(daoRegistry)][DaoLibrary.ERC20_EXT] != address(0x0)) {
			IERC20Extension erc20 = IERC20Extension(
				moduleAddresses.data[address(daoRegistry)][DaoLibrary.ERC20_EXT]
			);

			erc20.setName(daoRegistry, foundanceConfig.tokenConfig.tokenName);

			erc20.setToken(daoRegistry, DaoLibrary.UNITS);

			erc20.setSymbol(daoRegistry, foundanceConfig.tokenConfig.tokenSymbol);

			erc20.setDecimals(daoRegistry, foundanceConfig.tokenConfig.decimals);
		}

		if (moduleAddresses.data[address(daoRegistry)][DaoLibrary.MEMBER_EXT] != address(0x0)) {
			IMemberExtension member = IMemberExtension(
				moduleAddresses.data[address(daoRegistry)][DaoLibrary.MEMBER_EXT]
			);

			member.setMemberEnvironment(
				daoRegistry,
				foundanceConfig.dynamicEquityConfig,
				foundanceConfig.vestedEquityConfig,
				foundanceConfig.communityEquityConfig,
				foundanceConfig.epochConfig
			);

			for (uint256 i = 0; i < foundanceConfig.foundanceMemberConfigArray.length; i++) {
				FoundanceLibrary.FoundanceMemberConfig memory factoryMemberConfig = foundanceConfig
					.foundanceMemberConfigArray[i];

				if (
					factoryMemberConfig.dynamicEquityMemberConfig.memberAddress !=
					factoryMemberConfig.memberAddress
				) factoryMemberConfig.dynamicEquityMemberConfig.memberAddress == address(0x0);

				if (
					factoryMemberConfig.vestedEquityMemberConfig.memberAddress ==
					factoryMemberConfig.memberAddress
				) factoryMemberConfig.vestedEquityMemberConfig.memberAddress == address(0x0);

				if (
					factoryMemberConfig.communityEquityMemberConfig.memberAddress ==
					factoryMemberConfig.memberAddress
				) factoryMemberConfig.communityEquityMemberConfig.memberAddress == address(0x0);

				member.setMember(daoRegistry, factoryMemberConfig.memberConfig);

				member.setMemberSetup(
					daoRegistry,
					factoryMemberConfig.dynamicEquityMemberConfig,
					factoryMemberConfig.vestedEquityMemberConfig,
					factoryMemberConfig.communityEquityMemberConfig
				);
			}
		}
	}

	/**
	 * READ-ONLY FUNCTIONS
	 */

	function getConfigurations() external view returns (DaoFactoryLibrary.Configuration[] memory) {
		// DaoFactoryLibrary.Configuration[] data;
		return _configurations().data;
	}

	function getIsAdmin(address adminAddress) external view returns (bool) {
		// mapping(address => bool) data;
		return _isAdmin().data[adminAddress];
	}

	function getFoundanceName(uint32 foundanceId) external view returns (string memory) {
		// mapping(uint32 => string) data;
		return _foundanceNames().data[foundanceId];
	}

	function getDaoAddresses(address[] memory) external view returns (address[] memory) {
		// address[] data;
		return _daoAddresses().data;
	}

	function getFoundanceMemberConfigIndex(
		string memory foundanceName,
		address memberAddress
	) external view returns (uint256) {
		// mapping(string => mapping(address => uint256)) data;
		return _foundanceMemberConfigIndex().data[foundanceName][memberAddress];
	}

	function getFoundanceConfigs(
		string memory foundanceName
	) external view returns (FoundanceLibrary.FoundanceConfig memory) {
		// mapping(string => FoundanceLibrary.FoundanceConfig) data;
		return _foundanceConfigs().data[foundanceName];
	}

	function getImplementationAddresses() external view returns (address[] memory) {
		// address[] data;
		return _implementationAddresses().data;
	}

	function getModuleAddress(
		address daoAddress,
		bytes32 moduleId
	) external view returns (address) {
		// mapping(address => mapping(bytes32 => address)) data;
		return _moduleAddresses().data[daoAddress][moduleId];
	}

	function getImplementationIds() external view returns (bytes32[] memory) {
		// bytes32[] data;
		return _implementationIds().data;
	}

	function isFoundanceApproved(string calldata foundanceName) external view returns (bool) {
		return _isFoundanceApproved(_foundanceConfigs().data[foundanceName]);
	}

	function isNameUnique(string calldata foundanceName) external returns (bool) {
		return
			_modules().data.daoFactory.getDaoAddressByName(foundanceName) == address(0x0) &&
			_foundanceConfigs().data[foundanceName].creatorAddress == address(0x0);
	}

	/**
	 * @notice
	 * @dev
	 * @param foundance The foundanceConfig to check within if all member approved.
	 **/
	function _isFoundanceApproved(
		FoundanceLibrary.FoundanceConfig storage foundance
	) internal view returns (bool) {
		for (uint256 i = 0; i < foundance.foundanceMemberConfigArray.length; i++) {
			if (!foundance.foundanceMemberConfigArray[i].foundanceApproved) return false;
		}

		return true;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libraries/FoundanceLibrary.sol";

/// @title Foundance Storage
/// @notice This contract defines the storage struct and memory pointer for the Foundance contract
contract FoundanceStorage {
	/**
	 * STORAGE STRUCTS
	 */

	struct LockedAt {
		mapping(uint32 => uint256) data;
	}

	struct Initialized {
		bool data;
	}

	struct ModuleAddresses {
		mapping(address => mapping(bytes32 => address)) data;
	}

	struct Configurations {
		DaoFactoryLibrary.Configuration[] data;
	}

	struct IsAdmin {
		mapping(address => bool) data;
	}

	struct Modules {
		FoundanceLibrary.Modules data;
	}

	struct FoundanceConfigs {
		mapping(string => FoundanceLibrary.FoundanceConfig) data;
	}

	struct FoundanceNames {
		mapping(uint32 => string) data;
	}

	struct DaoAddresses {
		address[] data;
	}

	struct FoundanceMemberConfigIndex {
		// foundanceName => memberAddress
		mapping(string => mapping(address => uint256)) data;
	}

	struct ImplementationAddresses {
		address[] data;
	}

	struct ImplementationIds {
		bytes32[] data;
	}

	/**
	 * STORAGE POINTER
	 */

	function _lockedAt() internal pure returns (LockedAt storage data) {
		// data = keccak256("foundance.lockedAt")
		assembly {
			data.slot := 0xae96678acca7fb560a17e9cec6f6423d3090cff0cb9b9f75ea732274bc7b5231
		}
	}

	function _initialized() internal pure returns (Initialized storage data) {
		// data = keccak256("foundance.initialized")
		assembly {
			data.slot := 0x813c6c424f698283e8f7d0314b881f7b8719dcb0d48f91faaf17a86f4322bf54
		}
	}

	function _moduleAddresses() internal pure returns (ModuleAddresses storage data) {
		// data = keccak256("foundance.moduleAddresses.v.1.3")
		assembly {
			data.slot := 0xcdb6f751dd27c0f74b0daa6020ecbb8d30d52b2b828e6eaeaf22e4ec4423ffbb
		}
	}

	function _configurations() internal pure returns (Configurations storage data) {
		// data = keccak256("foundance.configurations")
		assembly {
			data.slot := 0x0acfeb94b8688dd8c2b325de686296a253329b9b3d6f0fd66422c5f5182c7108
		}
	}

	function _isAdmin() internal pure returns (IsAdmin storage data) {
		// data = keccak256("foundance.isAdmin")
		assembly {
			data.slot := 0x2ad86702861487df20d79544f0c3c004aae2ee65296a8ed3835c0076f5e92220
		}
	}

	function _modules() internal pure returns (Modules storage data) {
		// data = keccak256("foundance.modules.v.1.3")
		assembly {
			data.slot := 0x276c57c1ba640ca9f30a808ec2b52ccdab71fc1a598013cfd5732ff373dfee2e
		}
	}

	function _foundanceConfigs() internal pure returns (FoundanceConfigs storage data) {
		// data = keccak256("foundance.foundanceConfigs.v.1.3")
		assembly {
			data.slot := 0xe67a7ded34a878a3d724d6b3c3a33b1a7502e1acd4fdc825a7334a8fcc9079be
		}
		//0xfe377a103518da8c8cc318a4523befad4c7228a7a7876fb07eaf7b9e9b5874aa
		// data = keccak256("foundance.foundanceConfigs.2")
		//assembly {data.slot := 0x2742fea6aa2cdeecb5008546448d6544e7eeab4623562534d05917a3481f9810}
	}

	function _foundanceNames() internal pure returns (FoundanceNames storage data) {
		// data = keccak256("foundance.foundanceNames")
		assembly {
			data.slot := 0x765c6f0582e22feed38d854bb1aa7e7463b46395cdc53c0decebdef344e9ddd1
		}
	}

	function _daoAddresses() internal pure returns (DaoAddresses storage data) {
		// data = keccak256("foundance.daoAddresses")
		assembly {
			data.slot := 0x8143abdf0b87b10b5514b7b282b31b4bf6b60d18f183312e730ca3fc281d5d09
		}
	}

	function _foundanceMemberConfigIndex()
		internal
		pure
		returns (FoundanceMemberConfigIndex storage data)
	{
		// data = keccak256("foundance.foundanceMemberConfigIndex")
		assembly {
			data.slot := 0xa543b813c50bcc7b9cdb4dfd0e1c0a50fe3eb79ae637bfa0e899e4aa26cbc661
		}
	}

	function _implementationAddresses()
		internal
		pure
		returns (ImplementationAddresses storage data)
	{
		// data = keccak256("foundance.implementationAddresses")
		assembly {
			data.slot := 0xe4318a10b09ddf72f023160e019db43ac3712ebacd14b79ecd9a49ba32ef1e36
		}
	}

	function _implementationIds() internal pure returns (ImplementationIds storage data) {
		// data = keccak256("foundance.implementationIds")
		assembly {
			data.slot := 0x79d3499be8bf2bfe69155466e6c78f38e6174515603d11718c1a0bce4e35c320
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../core/factories/libraries/DaoFactoryLibrary.sol";
import "../../extensions/libraries/BankExtensionLibrary.sol";
import "../../extensions/libraries/MemberExtensionLibrary.sol";
import "../../extensions/libraries/DynamicEquityExtensionLibrary.sol";
import "../../extensions/libraries/VestedEquityExtensionLibrary.sol";
import "../../extensions/libraries/CommunityEquityExtensionLibrary.sol";
import "../../extensions/libraries/VotingExtensionLibrary.sol";
import "../../extensions/libraries/ERC20ExtensionLibrary.sol";

import "./events/IFoundanceEvents.sol";
import "./errors/IFoundanceErrors.sol";

import "../libraries/FoundanceLibrary.sol";
import "../libraries/DaoRegistryLibrary.sol";
import "../../libraries/DaoLibrary.sol";

/// @title Interface for Foundance
/// @notice This interface defines the enums, structs, functions for Foundance
interface IFoundance is IFoundanceEvents, IFoundanceErrors {
	/**
	 * EXTERNAL FUNCTIONS
	 */

	/**
	 * @notice Register a Foundance Dao
	 * @dev The foundanceName must be unique and not previously registered.
	 * @param foundanceName Name of the Dao
	 * @param projectId The internal project identifier for correlating projects and DAOs
	 * @param foundanceMemberConfigArray FoundanceMemberConfig Array including all relevant data
	 * @param tokenConfig TokenConfig for the BankExtension
	 * @param votingConfig VotingConfig for the VotingAdapter
	 * @param epochConfig EpochConfig for DynamicEquityExtension and CommunityEquityExtension
	 * @param dynamicEquityConfig DynamicEquityConfig for the DynamicEquityExtension
	 * @param vestedEquityConfig VestedEquityConfig for the VestedEquityExtension
	 * @param communityEquityConfig CommunityEquityConfig for the CommunityEquityExtension
	 * @param documentHash 
	 **/
	function registerFoundance(
		string calldata foundanceName,
		uint32 projectId,
		FoundanceLibrary.FoundanceMemberConfig[] memory foundanceMemberConfigArray,
		BankExtensionLibrary.TokenConfig calldata tokenConfig,
		VotingExtensionLibrary.VotingConfig calldata votingConfig,
		DaoRegistryLibrary.EpochConfig calldata epochConfig,
		DynamicEquityExtensionLibrary.DynamicEquityConfig calldata dynamicEquityConfig,
		VestedEquityExtensionLibrary.VestedEquityConfig calldata vestedEquityConfig,
		CommunityEquityExtensionLibrary.CommunityEquityConfig calldata communityEquityConfig,
		bytes memory documentHash
	) external;

	/**
	 * @notice Create a Foundance-DAO based upon an already approved Foundance-Agreement
	 * @dev The Foundance-Agreement must be approved by all members
	 * @dev This function must be accessed by the Foundance-Agreement creator
	 * @param foundanceName Name of the Foundance-DAO
	 **/
	function createFoundance(string calldata foundanceName) external;

	/**
	 * @notice Set the Id of a DAO to the DaoName
	 * @param projectId Project Id
	 * @param name DaoName
	 **/
	function setIdtoDaoName(uint32 projectId, string calldata name) external;

	/**
	 * @notice Approve a Foundance-Agreement
	 * @param foundanceName Foundance-Agreement name
	 **/
	function approveFoundance(string calldata foundanceName) external;

	/**
	 * @notice Add admins to the Foundance
	 * @param admins Array of admin addresses
	 **/
	function addAdmins(address[] calldata admins) external;

	/**
	 * @notice Remove admins from the Foundance
	 * @param admins Array of admin addresses
	 **/
	function removeAdmins(address[] calldata admins) external;

	function setModules(
		address lighthouseAddress,
		address daoFactoryAddress,
		address extensionFactoryAddress,
		FoundanceLibrary.Module[] memory moduleArray,
		bytes32[] memory adapterIds,
		address[] memory adapterAddresses
	) external;

	/**
	 * @notice Set the configurations of the Foundance
	 * @param newConfigurations Configuration struct
	 **/
	function setConfigurations(DaoFactoryLibrary.Configuration[] memory newConfigurations) external;
}

// SPDX-License-Identifier: MITis
pragma solidity 0.8.17;

import "./events/IDaoRegistryEvents.sol";
import "./errors/IDaoRegistryErrors.sol";
import "../../proxy/interfaces/ILighthouse.sol";
import "../../extensions/interfaces/IExtension.sol";

import "../libraries/DaoRegistryLibrary.sol";

/// @title Dao Registry interface
/// @notice This interface defines the functions that can be called on the DaoRegistry contract
interface IDaoRegistry is IDaoRegistryEvents, IDaoRegistryErrors {
	/**
	 * EXTERNAL FUNCTIONS
	 */

	/**
	 * @notice Initialises the DAO
	 * @dev Involves initialising available tokens, checkpoints, and membership of creator
	 * @dev Can only be called once
	 * @param creator The DAO"s creator, who will be an initial member
	 * @param payer The account which paid for the transaction to create the DAO, who will be an initial member
	 */

	function initialize(address creator, address payer) external;

	/**
	 * @dev Sets the state of the dao to READY
	 */
	function finalizeDao() external;

	/**
	 * @notice Contract lock strategy to lock only the caller is an adapter or extension.
	 */
	function lockSession() external;

	/**
	 * @notice Contract lock strategy to release the lock only the caller is an adapter or extension.
	 */
	function unlockSession() external;

	/**
	 * @notice Sets a configuration value
	 * @dev Changes the value of a key in the configuration mapping
	 * @param key The configuration key for which the value will be set
	 * @param value The value to set the key
	 */
	function setConfiguration(bytes32 key, uint256 value) external;

	/**
	 * @notice Sets an configuration value
	 * @dev Changes the value of a key in the configuration mapping
	 * @param key The configuration key for which the value will be set
	 * @param value The value to set the key
	 */
	function setAddressConfiguration(bytes32 key, address value) external;

	/**
	 * @notice Replaces an adapter in the registry in a single step.
	 * @notice It handles addition and removal of adapters as special cases.
	 * @dev It removes the current adapter if the adapterId maps to an existing adapter address.
	 * @dev It adds an adapter if the adapterAddress parameter is not zeroed.
	 * @param adapterId The unique identifier of the adapter
	 * @param adapterAddress The address of the new adapter or zero if it is a removal operation
	 * @param acl The flags indicating the access control layer or permissions of the new adapter
	 * @param keys The keys indicating the adapter configuration names.
	 * @param values The values indicating the adapter configuration values.
	 */
	function replaceAdapter(
		bytes32 adapterId,
		address adapterAddress,
		uint128 acl,
		bytes32[] calldata keys,
		uint256[] calldata values
	) external;

	/**
	 * @notice Adds a new extension to the registry
	 * @param extensionId The unique identifier of the new extension
	 * @param extension The address of the extension
	 */
	function addExtension(bytes32 extensionId, IExtension extension) external;

	/**
	 * @notice Removes an adapter from the registry
	 * @param extensionId The unique identifier of the extension
	 */
	function removeExtension(bytes32 extensionId) external;

	/**
	 * @notice It sets the ACL flags to an Adapter to make it possible to access specific functions of an Extension.
	 */
	function setAclToExtensionForAdapter(
		address extensionAddress,
		address adapterAddress,
		uint256 acl
	) external;

	/**
	 * @notice Submit proposals to the DAO registry
	 */
	function submitProposal(bytes32 proposalId) external;

	/**
	 * @notice Sponsor proposals that were submitted to the DAO registry
	 * @dev adds SPONSORED to the proposal flag
	 * @param proposalId The ID of the proposal to sponsor
	 * @param sponsoringMember The member who is sponsoring the proposal
	 */
	function sponsorProposal(
		bytes32 proposalId,
		address sponsoringMember,
		address votingAdapterAddr
	) external;

	/**
	 * @notice Mark a proposal as processed in the DAO registry
	 * @param proposalId The ID of the proposal that is being processed
	 */
	function processProposal(bytes32 proposalId) external;

	/**
	 * @notice Sets true for the JAILED flag.
	 * @param memberAddress The address of the member to update the flag.
	 */
	function jailMember(address memberAddress) external;

	/**
	 * @notice Sets false for the JAILED flag.
	 * @param memberAddress The address of the member to update the flag.
	 */
	function unjailMember(address memberAddress) external;

	/**
	 * @notice Updates the delegate key of a member
	 * @param memberAddr The member doing the delegation
	 * @param newDelegateKey The member who is being delegated to
	 */
	function updateDelegateKey(address memberAddr, address newDelegateKey) external;

	function setDelegatedSource(address lighthouseAddress, address delegatedSource) external;

	function setImplementationBatch(
		address lighthouse,
		address[] calldata newImplementationAddresses,
		bytes32[] calldata newImplementationIds
	) external;

	function potentialNewMember(address memberAddress) external;

	function getNbMembers() external view returns (uint256);

	function getLockedAt() external view returns (uint256);

	function getMemberAddress(uint256 index) external view returns (address);

	function getPreviousDelegateKey(address memberAddr) external view returns (address);

	function getAddressIfDelegated(address checkAddr) external view returns (address);

	function getCurrentDelegateKey(address memberAddr) external view returns (address);

	function getState() external view returns (DaoRegistryLibrary.DaoState);

	function isMember(address addr) external view returns (bool);

	function isAdapter(address adapterAddress) external view returns (bool);

	function getExtensionAddress(bytes32 extensionId) external view returns (address);

	function hasAdapterAccess(
		address adapterAddress,
		DaoRegistryLibrary.AclFlag flag
	) external view returns (bool);

	function getAdapterAddress(bytes32 adapterId) external view returns (address);

	function getVotingAdapter(bytes32 votingAdapterId) external view returns (address);

	function getProposals(
		bytes32 proposalId
	) external view returns (DaoRegistryLibrary.Proposal memory);

	function getAddressConfiguration(bytes32 key) external view returns (address);

	function getExtensions(bytes32 extensionId) external view returns (address);

	function getIsProposalUsed(bytes32 proposalId) external view returns (bool);

	function getProposalFlag(
		bytes32 proposalId,
		DaoRegistryLibrary.ProposalFlag flag
	) external view returns (bool);

	function hasAdapterAccessToExtension(
		address adapterAddress,
		address extensionAddress,
		uint8 flag
	) external view returns (bool);

	function notJailed(address memberAddress) external view returns (bool);

	function getMainConfiguration(bytes32 id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./events/IDynamicEquityAdapterEvents.sol";
import "./errors/IDynamicEquityAdapterErrors.sol";
import "../../core/interfaces/IDaoRegistry.sol";

import "../../extensions/libraries/DynamicEquityExtensionLibrary.sol";
import "../../core/libraries/DaoRegistryLibrary.sol";

/// @title Dynamic Equity Adapter Interface
/// @notice This interface defines the functions that a dynamic equity adapter must implement
interface IDynamicEquityAdapter is IDynamicEquityAdapterEvents, IDynamicEquityAdapterErrors {
	/**
	 * EXTERNAL FUNCTIONS
	 */

	function submitSetDynamicEquityProposal(
		IDaoRegistry daoRegistry,
		bytes32 proposalId,
		bytes calldata data,
		DynamicEquityExtensionLibrary.DynamicEquityConfig calldata dynamicEquityConfig,
		DaoRegistryLibrary.EpochConfig calldata epochConfig
	) external;

	function submitSetDynamicEquityEpochProposal(
		IDaoRegistry daoRegistry,
		bytes32 proposalId,
		bytes calldata data,
		uint256 lastEpoch,
		uint32 lastIndex
	) external;

	function submitSetDynamicEquityMemberProposal(
		IDaoRegistry daoRegistry,
		bytes32 proposalId,
		bytes calldata data,
		DynamicEquityExtensionLibrary.DynamicEquityMemberConfig calldata dynamicEquityMemberConfig
	) external;

	function submitSetDynamicEquityMemberSuspendProposal(
		IDaoRegistry daoRegistry,
		bytes32 proposalId,
		bytes calldata data,
		address memberAddress,
		uint256 suspendedUntil
	) external;

	function submitSetDynamicEquityMemberExpenseProposal(
		IDaoRegistry daoRegistry,
		bytes32 proposalId,
		bytes calldata data,
		address memberAdress,
		uint256 expenseAmount,
		uint256 authorizedUntil
	) external;

	function submitSetDynamicEquityMemberEpochProposal(
		IDaoRegistry daoRegistry,
		bytes32 proposalId,
		bytes calldata data,
		DynamicEquityExtensionLibrary.DynamicEquityMemberConfig calldata dynamicEquityMemberConfig
	) external;

	function submitSetDynamicEquityMemberEpochDefaultProposal(
		IDaoRegistry daoRegistry,
		bytes32 proposalId,
		bytes calldata data,
		DynamicEquityExtensionLibrary.DynamicEquityMemberConfig calldata dynamicEquityMemberConfig
	) external;

	function submitRemoveDynamicEquityMemberProposal(
		IDaoRegistry daoRegistry,
		bytes32 proposalId,
		bytes calldata data,
		address memberAdress
	) external;

	function submitRemoveDynamicEquityMemberEpochProposal(
		IDaoRegistry daoRegistry,
		bytes32 proposalId,
		bytes calldata data,
		address memberAdress
	) external;

	function processSetDynamicEquityProposal(IDaoRegistry daoRegistry, bytes32 proposalId) external;

	function processSetDynamicEquityEpochProposal(
		IDaoRegistry daoRegistry,
		bytes32 proposalId
	) external;

	function processSetDynamicEquityMemberProposal(
		IDaoRegistry daoRegistry,
		bytes32 proposalId
	) external;

	function processSetDynamicEquityMemberSuspendProposal(
		IDaoRegistry daoRegistry,
		bytes32 proposalId
	) external;

	function processSetDynamicEquityMemberExpenseProposal(
		IDaoRegistry daoRegistry,
		bytes32 proposalId,
		uint256 expenseAmount
	) external;

	function processSetDynamicEquityMemberEpochProposal(
		IDaoRegistry daoRegistry,
		bytes32 proposalId
	) external;

	function processRemoveDynamicEquityMemberProposal(
		IDaoRegistry daoRegistry,
		bytes32 proposalId
	) external;

	function processRemoveDynamicEquityMemberEpochProposal(
		IDaoRegistry daoRegistry,
		bytes32 proposalId
	) external;

	function actDynamicEquityMemberEpochCancel(
		IDaoRegistry daoRegistry,
		uint32 epochIndex
	) external;

	function actDynamicEquityMemberEpochDefaultCancel(
		IDaoRegistry daoRegistry,
		uint32 epochIndex
	) external;

	function actDynamicEquityEpochDistribute(
		IDaoRegistry daoRegistry,
		uint256 maxIterations
	) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IExtension.sol";
import "./events/IVotingExtensionEvents.sol";
import "./errors/IVotingExtensionErrors.sol";
import "../../core/interfaces/IDaoRegistry.sol";

import "../libraries/VotingExtensionLibrary.sol";

/// @title Voting Extension Interface
/// @notice This interface defines the functions for the Voting Extension
interface IVotingExtension is IExtension, IVotingExtensionEvents, IVotingExtensionErrors {
	/**
	 * EXTERNAL FUNCTIONS
	 */

	function setVotingConfig(
		IDaoRegistry daoRegistry,
		VotingExtensionLibrary.VotingConfig memory newVotingConfig,
		bytes32 votingConfigId
	) external;

	function setDocument(
		IDaoRegistry daoRegistry,
		bytes32 proposalId,
		string memory documentName,
		bytes memory documentHash
	) external;

	function startVoting(
		IDaoRegistry daoRegistry,
		bytes32 proposalId,
		bytes memory data,
		bytes32 proposalType,
		address msgSender
	) external;

	function startVotingWithConfig(
		IDaoRegistry daoRegistry,
		bytes32 proposalId,
		bytes memory data,
		bytes32 proposalType,
		VotingExtensionLibrary.VotingConfig memory votingConfig,
		address msgSender
	) external;

	function processVoting(
		IDaoRegistry daoRegistry,
		bytes32 proposalId
	) external returns (VotingExtensionLibrary.ProposalStatus);

	function cancelVoting(IDaoRegistry daoRegistry, bytes32 proposalId) external;

	function submitVote(
		IDaoRegistry daoRegistry,
		bytes32 proposalId,
		uint256 voteValue,
		uint256 weightedVoteValue,
		address memberAddress
	) external;

	function getVotingFunctionConfigOrVotingConfig(
		bytes32 proposalType
	) external view returns (VotingExtensionLibrary.VotingConfig memory);

	function getVotingConfig() external view returns (VotingExtensionLibrary.VotingConfig memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IExtension.sol";
import "./errors/IERC20ExtensionErrors.sol";
import "../../core/interfaces/IDaoRegistry.sol";

/// @title Bank Extension Interface
/// @notice This interface defines the functions for the Bank Extension
interface IERC20Extension is IExtension, IERC20ExtensionErrors, IERC20 {
	function setToken(IDaoRegistry daoRegistry, address newTokenAddress) external;

	function setName(IDaoRegistry daoRegistry, string memory newTokenName) external;

	function setSymbol(IDaoRegistry daoRegistry, string memory newTokenSymbol) external;

	function setDecimals(IDaoRegistry daoRegistry, uint8 newTokenDecimals) external;

	/**
	 * READ-ONLY FUNCTIONS
	 */

	/**
	 * @dev Returns the name of the token.
	 */
	function getTokenName() external view returns (string memory);

	/**
	 * @dev Returns the symbol of the token, usually a shorter version of the
	 * name.
	 */
	function getTokenSymbol() external view returns (string memory);

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 * For example, if `decimals` equals `2`, a balance of `505` tokens should
	 * be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 */
	function getTokenDecimals() external view returns (uint8);

	function decimals() external view returns (uint8);

	/**
	 * @dev Returns the amount of tokens owned by `account` considering the snapshot.
	 */
	function getPriorAmount(address account, uint256 snapshot) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IExtension.sol";
import "./errors/IMemberExtensionErrors.sol";
import "../../core/interfaces/IDaoRegistry.sol";

import "../libraries/MemberExtensionLibrary.sol";
import "../libraries/DynamicEquityExtensionLibrary.sol";
import "../libraries/VestedEquityExtensionLibrary.sol";
import "../libraries/CommunityEquityExtensionLibrary.sol";
import "../../core/libraries/DaoRegistryLibrary.sol";

/// @title Member Extension Interface
/// @notice This interface defines the functions for the Member Extension
interface IMemberExtension is IExtension, IMemberExtensionErrors {
	/**
	 * EXTERNAL FUNCTIONS
	 */

	function setMember(
		IDaoRegistry daoRegistry,
		MemberExtensionLibrary.MemberConfig calldata memberConfig
	) external;

	function setMemberSetup(
		IDaoRegistry daoRegistry,
		DynamicEquityExtensionLibrary.DynamicEquityMemberConfig calldata dynamicEquityMemberConfig,
		VestedEquityExtensionLibrary.VestedEquityMemberConfig calldata vestedEquityMemberConfig,
		CommunityEquityExtensionLibrary.CommunityEquityMemberConfig
			calldata communityEquityMemberConfig
	) external;

	function setMemberAppreciationRight(
		IDaoRegistry daoRegistry,
		address memberAddress,
		bool appreciationRight
	) external;

	function setMemberEnvironment(
		IDaoRegistry daoRegistry,
		DynamicEquityExtensionLibrary.DynamicEquityConfig memory dynamicEquityConfig,
		VestedEquityExtensionLibrary.VestedEquityConfig memory vestedEquityConfig,
		CommunityEquityExtensionLibrary.CommunityEquityConfig memory communityEquityConfig,
		DaoRegistryLibrary.EpochConfig memory epochConfig
	) external;

	function removeMember(IDaoRegistry daoRegistry, address memberAddress) external;

	function removeMemberSetup(IDaoRegistry daoRegistry, address memberAddress) external;

	function getIsMember(address memberAddress) external view returns (bool);

	function getMemberConfig(
		address memberAddress
	) external view returns (MemberExtensionLibrary.MemberConfig memory);

	function getMemberConfigsFiltered()
		external
		view
		returns (MemberExtensionLibrary.MemberConfig[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IExtension.sol";
import "./events/IDynamicEquityExtensionEvents.sol";
import "./errors/IDynamicEquityExtensionErrors.sol";
import "../../core/interfaces/IDaoRegistry.sol";

import "../libraries/DynamicEquityExtensionLibrary.sol";
import "../../core/libraries/DaoRegistryLibrary.sol";

/// @title DynamicEquity Extension Interface
/// @notice This interface defines the functions for the DynamicEquity Extension
interface IDynamicEquityExtension is
	IExtension,
	IDynamicEquityExtensionEvents,
	IDynamicEquityExtensionErrors
{
	function setDynamicEquityConfig(
		IDaoRegistry daoRegistry,
		DynamicEquityExtensionLibrary.DynamicEquityConfig calldata dynamicEquiytyConfig
	) external;

	function setEpochConfig(
		IDaoRegistry daoRegistry,
		DaoRegistryLibrary.EpochConfig calldata epochConfig
	) external;

	function setEpochConfigEpochLast(
		IDaoRegistry daoRegistry,
		uint32 epochIndex,
		uint256 newEpochLast
	) external;

	function setDynamicEquityMemberConfig(
		IDaoRegistry daoRegistry,
		DynamicEquityExtensionLibrary.DynamicEquityMemberConfig memory dynamicEquityMemberConfig
	) external;

	function setDynamicEquityMemberConfigBatch(
		IDaoRegistry daoRegistry,
		DynamicEquityExtensionLibrary.DynamicEquityMemberConfig[] memory dynamicEquityMemberConfig
	) external;

	function setDynamicEquityMemberConfigSuspend(
		IDaoRegistry daoRegistry,
		address _member,
		uint256 suspendedUntil
	) external;

	function setDynamicEquityMemberEpochConfig(
		IDaoRegistry daoRegistry,
		DynamicEquityExtensionLibrary.DynamicEquityMemberConfig calldata config
	) external;

	function setEpochDuration(
		IDaoRegistry daoRegistry,
		uint32 epochIndex,
		uint256 epochDuration
	) external;

	function removeDynamicEquityMemberEpochConfig(
		IDaoRegistry daoRegistry,
		address _member
	) external;

	function removeDynamicEquityMember(IDaoRegistry daoRegistry, address _member) external;

	function getIsNotReviewPeriod() external view returns (bool);

	function getNextEpoch() external view returns (uint256);

	function getNextEpochIndex() external view returns (uint32);

	function getVotingPeriod() external view returns (uint256);

	function getEpochConfig() external view returns (DaoRegistryLibrary.EpochConfig memory);

	function getIsDynamicEquityMember(address memberAddress) external view returns (bool);

	function getDynamicEquityMemberSuspendedUntil(
		address memberAddress
	) external view returns (uint256 suspendedUntil);

	function getDynamicEquityMemberEpochAmount(address memberAddress) external view returns (uint);

	function getMemberConfig()
		external
		view
		returns (DynamicEquityExtensionLibrary.DynamicEquityMemberConfig[] memory);

	function getDynamicEquityConfig()
		external
		view
		returns (DynamicEquityExtensionLibrary.DynamicEquityConfig memory);

	function getEpochDuration(uint32 epochIndex) external view returns (uint256);

	function getDynamicEquityMemberConfig(
		address memberAddress
	) external view returns (DynamicEquityExtensionLibrary.DynamicEquityMemberConfig memory);

	function getDynamicEquityMemberConfigs()
		external
		view
		returns (DynamicEquityExtensionLibrary.DynamicEquityMemberConfig[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../extensions/factories/ExtensionFactory.sol";

import "../../core/factories/interfaces/IDaoFactory.sol";
import "../../proxy/interfaces/ILighthouse.sol";

import "./DaoRegistryLibrary.sol";
import "../factories/libraries/DaoFactoryLibrary.sol";
import "../../extensions/libraries/BankExtensionLibrary.sol";
import "../../extensions/libraries/MemberExtensionLibrary.sol";
import "../../extensions/libraries/DynamicEquityExtensionLibrary.sol";
import "../../extensions/libraries/VestedEquityExtensionLibrary.sol";
import "../../extensions/libraries/CommunityEquityExtensionLibrary.sol";
import "../../extensions/libraries/VotingExtensionLibrary.sol";

/// @title Foundance Library
/// @notice This library contains all the structs and enums used by the Foundance contract
library FoundanceLibrary {
	/**
	 * ENUM
	 */

	enum FoundanceStatus {
		APPROVED,
		REGISTERED,
		LIVE
	}

	/**
	 * STRUCT
	 */

	struct Module {
		DaoFactoryLibrary.ModuleType moduleType;
		bytes32 moduleId;
		address moduleAddress;
		uint128 daoRegistryAclFlags;
		bytes32[] extensionAclIds;
		uint128[] extensionAclFlags;
	}

	struct Modules {
		ILighthouse lighthouse;
		IDaoFactory daoFactory;
		IExtensionFactory extensionFactory;
		Module[] moduleArray;
		bytes32[] adapterIds;
	}

	struct FoundanceConfig {
		address creatorAddress;
		uint32 foundanceId;
		FoundanceStatus foundanceStatus;
		FoundanceMemberConfig[] foundanceMemberConfigArray;
		BankExtensionLibrary.TokenConfig tokenConfig;
		VotingExtensionLibrary.VotingConfig votingConfig;
		DaoRegistryLibrary.EpochConfig epochConfig;
		DynamicEquityExtensionLibrary.DynamicEquityConfig dynamicEquityConfig;
		VestedEquityExtensionLibrary.VestedEquityConfig vestedEquityConfig;
		CommunityEquityExtensionLibrary.CommunityEquityConfig communityEquityConfig;
		bytes documentHash;
	}

	struct FoundanceConfigLive {
		FoundanceMemberConfig[] foundanceMemberConfigArray;
		BankExtensionLibrary.TokenConfig tokenConfig;
		VotingExtensionLibrary.VotingConfig votingConfig;
		DaoRegistryLibrary.EpochConfig epochConfig;
		DynamicEquityExtensionLibrary.DynamicEquityConfig dynamicEquityConfig;
		VestedEquityExtensionLibrary.VestedEquityConfig vestedEquityConfig;
	}

	struct FoundanceMemberConfig {
		address memberAddress;
		bool foundanceApproved;
		MemberExtensionLibrary.MemberConfig memberConfig;
		DynamicEquityExtensionLibrary.DynamicEquityMemberConfig dynamicEquityMemberConfig;
		VestedEquityExtensionLibrary.VestedEquityMemberConfig vestedEquityMemberConfig;
		CommunityEquityExtensionLibrary.CommunityEquityMemberConfig communityEquityMemberConfig;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./storage/ExtensionFactoryStorage.sol";
import "../../proxy/LighthouseProxy.sol";

import "./interfaces/IExtensionFactory.sol";
import "../interfaces/IExtension.sol";

import "../../libraries/DaoLibrary.sol";

/// @title Extension Factory
/// @notice This contract is used to create a new Extension
contract ExtensionFactory is ExtensionFactoryStorage, IExtensionFactory, ReentrancyGuard {
	/**
	 * EXTERNAL FUNCTIONS
	 */

	function create(
		IDaoRegistry daoRegistry,
		address lighthouseAddress,
		bytes32 extensionId
	) external nonReentrant {
		Extensions storage extensions = _extensions();

		address daoAddress = address(daoRegistry);

		if (daoAddress == address(0x0)) revert ExtensionFactory_InvalidDaoAddress();

		LighthouseProxy extensionProxy = new LighthouseProxy(
			lighthouseAddress,
			daoAddress,
			extensionId,
			false
		);

		address extensionAddr = address(extensionProxy);

		extensions.data[daoAddress][extensionId] = extensionAddr;

		IExtension extension = IExtension(extensionAddr);

		extension.initialize(daoRegistry);

		emit ExtensionFactory_ExtensionCreated(daoAddress, address(extension), extensionId);
	}

	/**
	 * READ-ONLY FUNCTIONS
	 */

	function getExtension(
		address daoRegistry,
		bytes32 extensionId
	) external view override returns (address) {
		Extensions storage extensions = _extensions();

		return extensions.data[daoRegistry][extensionId];
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./events/IDaoFactoryEvents.sol";
import "./errors/IDaoFactoryErrors.sol";
import "../../interfaces/IDaoRegistry.sol";

import "../libraries/DaoFactoryLibrary.sol";

/// @title DAO Factory
/// @notice This contract is used to create new DAOs.
interface IDaoFactory is IDaoFactoryErrors, IDaoFactoryEvents {
	/**
	 * EXTERNAL FUNCTIONS
	 */

	/**
	 * @notice Creates and initializes a new DaoRegistry with the DAO creator and the transaction sender.
	 * @notice Enters the new DaoRegistry in the DaoFactory state.
	 * @dev The daoName must not already have been taken.
	 * @param daoName The name of the DAO which, after being hashed, is used to access the address.
	 * @param creator The DAO's creator, who will be an initial member.
	 */
	function createDao(
		string calldata daoName,
		address creator,
		address lighthouseAddress
	) external;

	/**
	 * @notice
	 * @dev
	 * @param dao DaoRegistry for which the configurations are being configured.
	 * @param configurations Configuration struct
	 */
	function setConfiguration(
		IDaoRegistry dao,
		DaoFactoryLibrary.Configuration[] calldata configurations
	) external;

	/**
	 * @notice Removes an adapter with a given ID from a DAO, and adds a new one of the same ID.
	 * @dev The message sender must be an active member of the DAO.
	 * @dev The DAO must be in `CREATION` state.
	 * @param dao DAO to be updated.
	 * @param adapter Adapter that will be replacing the currently-existing adapter of the same ID.
	 */
	function updateAdapter(IDaoRegistry dao, DaoFactoryLibrary.Adapter calldata adapter) external;

	function getDaoAddressByName(string calldata daoName) external returns (address);

	function getAddress(bytes32 daoId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./errors/ILighthouseErrors.sol";
import "./events/ILighthouseEvents.sol";

/// @title Lighthouse
/// @notice This interface defines the functions that a Lighthouse must implement
interface ILighthouse is ILighthouseErrors, ILighthouseEvents {
	/**
	 * EXTERNAL FUNCTIONS
	 */

	/**
	 * @dev address must be contract
	 */

	function initializeSource(address sourceOwner, address delegatedSource) external;

	function changeImplementationBatch(
		address source,
		address[] memory implementationAddresses,
		bytes32[] memory implementationIds
	) external;

	function changeDelegatedSource(address source, address newDelegatedSource) external;

	function isInitialized(address source) external view returns (bool);

	function getImplementation(address source, bytes32 id) external view returns (address);

	function getSourceOwner(address source) external view returns (address);

	function getDelegatedSource(address source) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IDaoRegistry.sol";

import "../../libraries/DaoLibrary.sol";

/// @title Dao Registry Library
/// @notice This library contains all the structs and enums used by the DaoRegistry contract
library DaoRegistryLibrary {
	/**
	 * ENUMS
	 */

	enum DaoState {
		CREATION,
		READY
	}

	enum MemberFlag {
		EXISTS,
		JAILED
	}

	enum ProposalFlag {
		EXISTS,
		SPONSORED,
		PROCESSED
	}

	enum AclFlag {
		REPLACE_ADAPTER,
		SUBMIT_PROPOSAL,
		UPDATE_DELEGATE_KEY,
		SET_CONFIGURATION,
		ADD_EXTENSION,
		REMOVE_EXTENSION,
		NEW_MEMBER,
		JAIL_MEMBER,
		SET_PROXY_IMPLEMENTATION
	}

	/**
	 * STRUCTS
	 */

	/// @notice The structure to track all the proposals in the DAO
	struct Proposal {
		///@notice the adapter address that called the functions to change the DAO state
		address adapterAddress;
		///@notice flags to track the state of the proposal: exist, sponsored, processed, canceled, etc.
		uint256 flags;
	}

	///@notice the structure to track all the members in the DAO
	struct Member {
		///@notice flags to track the state of the member: exists, etc
		uint256 flags;
	}

	///@notice A checkpoint for marking number of votes from a given block
	struct Checkpoint {
		uint96 fromBlock;
		uint160 amount;
	}

	struct EpochConfig {
		uint256 epochDuration;
		uint256 epochReview;
		uint256 epochStart;
		uint256 epochLast;
		uint32 epochLastIndex;
	}

	///@notice A checkpoint for marking the delegate key for a member from a given block
	struct DelegateCheckpoint {
		uint96 fromBlock;
		address delegateKey;
	}

	struct AdapterEntry {
		bytes32 id;
		uint256 acl;
	}

	struct ExtensionEntry {
		bytes32 id;
		mapping(address => uint256) acl;
		bool deleted;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Dao FactoryLibrary
/// @notice This library contains all the structs and enums used by the DaoFactory contract
library DaoFactoryLibrary {
	/**
	 * ENUMS
	 */

	enum ConfigType {
		NUMERIC,
		ADDRESS
	}

	enum ModuleType {
		UNKNOWN,
		ADAPTER,
		EXTENSION
	}

	/**
	 * STRUCTS
	 */

	struct Adapter {
		bytes32 id;
		address addr;
		uint128 flags;
	}

	struct Configuration {
		ConfigType configType;
		bytes32 key;
		uint256 numericValue;
		address addressValue;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Bank Extension Library
/// @notice This library defines the structs used by the Bank Extension
library BankExtensionLibrary {
	/**
	 * ENUMS
	 */

	enum AclFlag {
		ADD_TO_BALANCE,
		SUB_FROM_BALANCE,
		INTERNAL_TRANSFER,
		WITHDRAW,
		REGISTER_NEW_TOKEN,
		REGISTER_NEW_INTERNAL_TOKEN,
		UPDATE_TOKEN
	}

	/**
	 * STRUCTS
	 */

	struct TokenConfig {
		string tokenName;
		string tokenSymbol;
		uint8 maxExternalTokens;
		uint8 decimals;
	}

	struct Checkpoint {
		// A checkpoint for marking number of votes from a given block
		uint96 fromBlock;
		uint160 amount;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./DynamicEquityExtensionLibrary.sol";
import "./VestedEquityExtensionLibrary.sol";
import "./CommunityEquityExtensionLibrary.sol";

/// @title Member Extension Library
/// @notice This library defines the structs used by the Member Extension
library MemberExtensionLibrary {
	/**
	 * ENUMS
	 */

	enum AclFlag {
		SET_MEMBER,
		REMOVE_MEMBER,
		ACT_MEMBER
	}

	/**
	 * STRUCTS
	 */

	struct MemberSetupConfig {
		MemberConfig memberConfig;
		DynamicEquityExtensionLibrary.DynamicEquityMemberConfig dynamicEquityMemberConfig;
		VestedEquityExtensionLibrary.VestedEquityMemberConfig vestedEquityMemberConfig;
		CommunityEquityExtensionLibrary.CommunityEquityMemberConfig communityEquityMemberConfig;
	}

	struct MemberConfig {
		address memberAddress;
		uint256 initialAmount;
		uint256 initialPeriod;
		bool appreciationRight;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Dynamic Equity Extension Library
/// @notice This library defines the structs used by the Dynamic Equity Extension
library DynamicEquityExtensionLibrary {
	/**
	 * ENUMS
	 */

	enum AclFlag {
		SET_DYNAMIC_EQUITY,
		REMOVE_DYNAMIC_EQUITY,
		ACT_DYNAMIC_EQUITY
	}

	/**
	 * STRUCTS
	 */

	struct DynamicEquityMemberConfig {
		address memberAddress;
		uint256 suspendedUntil;
		uint256 availability;
		uint256 availabilityThreshold;
		uint256 salary;
		uint256 salaryYear;
		uint256 withdrawal;
		uint256 withdrawalThreshold;
		uint256 expense;
		uint256 expenseThreshold;
		uint256 expenseCommitted;
		uint256 expenseCommittedThreshold;
	}

	struct DynamicEquityConfig {
		uint256 riskMultiplier;
		uint256 timeMultiplier;
		bool automaticDistribution;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Vested Equity Extension Library
/// @notice This library defines the structs used by the Vested Equity Extension
library VestedEquityExtensionLibrary {
	/**
	 * STRUCTS
	 */

	struct VestedEquityMemberConfig {
		address memberAddress;
		uint256 tokenAmount;
		uint256 duration;
		uint256 start;
		uint256 cliff;
	}

	struct VestedEquityConfig {
		uint256 vestingCadenceInS;
	}

	/**
	 * ENUMS
	 */

	enum AclFlag {
		SET_VESTED_EQUITY,
		REMOVE_VESTED_EQUITY,
		ACT_VESTED_EQUITY
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Community Equity Extension Library
/// @notice This library defines the structs used by the Community Equity Extension
library CommunityEquityExtensionLibrary {
	/**
	 * ENUMS
	 */

	enum AclFlag {
		SET_COMMUNITY_EQUITY,
		REMOVE_COMMUNITY_EQUITY,
		ACT_COMMUNITY_EQUITY
	}

	enum AllocationType {
		POOL,
		EPOCH
	}

	/**
	 * STRUCTS
	 */

	struct CommunityEquityConfig {
		AllocationType allocationType;
		uint256 allocationTokenAmount;
		uint256 tokenAmount;
	}

	struct CommunityEquityMemberConfig {
		address memberAddress;
		uint256 singlePaymentAmountThreshold;
		uint256 totalPaymentAmountThreshold;
		uint256 totalPaymentAmount;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Voting Extension Library
/// @notice This library defines the structs used by the Voting Extension
library VotingExtensionLibrary {
	/**
	 * ENUMS
	 */

	enum AclFlag {
		SET_VOTING,
		REMOVE_VOTING,
		ACT_VOTING
	}

	enum ProposalStatus {
		NOT_STARTED,
		IN_PROGRESS,
		DONE,
		FAILED
	}

	enum VotingType {
		PROPORTIONAL,
		PLACEHOLDER_0,
		QUADRATIC,
		PLACEHOLDER_1,
		COOPERATIVE
	}

	enum VotingState {
		NOT_STARTED,
		TIE,
		PASS,
		NOT_PASS,
		IN_PROGRESS,
		GRACE_PERIOD,
		DISPUTE_PERIOD
	}

	/**
	 * STRUCTS
	 */

	struct VotingConfig {
		VotingType votingType;
		uint256 votingPeriod;
		uint256 gracePeriod;
		uint256 disputePeriod;
		uint256 passRateMember;
		uint256 passRateToken;
		uint256 supportRequired;
		uint256 enactEarlySupportRequired;
		uint256 enactEarlyPassRateToken;
		bool enactEarly;
		bool weightedVoting;
		bool optimistic;
	}

	struct Voting {
		uint256 nbYes;
		uint256 nbNo;
		uint256 nbMembers;
		uint256 nbTokens;
		uint256 startingTime;
		uint256 graceStartingTime;
		uint256 disputeStartingTime;
		uint256 blockNumber;
		bytes32 proposalId;
		bytes32 votingConfigId;
		bytes data;
		address submittedBy;
		bytes32 proposalType;
		VotingState votingState;
	}

	struct VotingView {
		Voting voting;
		VotingConfig votingConfig;
	}

	struct Document {
		string documentName;
		bytes documentHash;
		bytes32 documentVersionId;
		bytes32 proposalId;
		uint256 blockTimestamp;
		uint128 documentVersion;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Extension Factory Storage
/// @notice This contract defines the storage struct and memory pointer used by a Extension Factory contract
contract ExtensionFactoryStorage {
	/**
	 * STORAGE STRUCTS
	 */

	struct Extensions {
		/// @notice daoAddress => extensionId => extensionAddress
		mapping(address => mapping(bytes32 => address)) data;
	}

	/**
	 * STORAGE POINTER
	 */

	function _extensions() internal pure returns (Extensions storage data) {
		// data = keccak256("extensionFactory.extensions")
		assembly {
			data.slot := 0x691f3825bc5bedbda7c35b3be2df0e13fc5eb128a6d71575c703fd94207a7cfd
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ILighthouse.sol";
import "./utils/StorageSlot.sol";

/// @title Lighthouse Proxy
/// @notice This Proxy contract implements a proxy that gets the implementation address for each call from an {Lighthouse}.
/// @dev The Lighthouse address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
/// @dev conflict with the storage layout of the implementation behind the proxy according to EIP1967.

contract LighthouseProxy {
	/**
	 * PRIVATE VARIABLES
	 */

	/**
	 * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
	 * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
	 */
	bytes32 internal constant _BEACON_SLOT =
		0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

	/**
	 * @dev Storage slot with the admin of the contract.
	 * This is the keccak-256 hash of "eip1967.proxy.source" subtracted by 1, and is
	 * validated in the constructor.
	 */
	bytes32 internal constant _SOURCE_SLOT =
		0xc8e02da233ea119f9b72934d78dac4416a7f0691681a180cf06cc79f0e95530e;

	/**
	 * @dev Storage slot with the admin of the contract.
	 * This is the keccak-256 hash of "eip1967.proxy.id" subtracted by 1, and is
	 * validated in the constructor.
	 */
	bytes32 internal constant _ID_SLOT =
		0xff20752f1dc1586dbd693d291954fd6d516fbdb1a42f9093d167a94dde7e0a2c;

	/**
	 * INITIALIZE
	 */

	constructor(address lighthouse, address source, bytes32 id, bool initializeSource) {
		StorageSlot.getAddressSlot(_BEACON_SLOT).value = lighthouse;

		if (initializeSource) {
			StorageSlot.getAddressSlot(_SOURCE_SLOT).value = address(this);
			ILighthouse(lighthouse).initializeSource(address(this), address(0x0));
		} else StorageSlot.getAddressSlot(_SOURCE_SLOT).value = source;

		StorageSlot.getBytes32Slot(_ID_SLOT).value = id;
	}

	/**
	 * EXTERNAL FUNCTIONS
	 */

	/**
	 * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
	 * function in the contract matches the call data.
	 */
	fallback() external payable virtual {
		_fallback();
	}

	/**
	 * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
	 * is empty.
	 */
	receive() external payable virtual {
		_fallback();
	}

	/**
	 * INTERNAL FUNCTIONS
	 */

	/**
	 * @dev Delegates the current call to the address returned by `_implementation()`.
	 *
	 * This function does not return to its internal call site, it will return directly to the external caller.
	 */
	function _fallback() internal virtual {
		_delegate(
			_implementation(
				StorageSlot.getAddressSlot(_SOURCE_SLOT).value,
				StorageSlot.getBytes32Slot(_ID_SLOT).value
			)
		);
	}

	/**
	 * @dev Delegates the current call to `implementation`.
	 *
	 * This function does not return to its internal call site, it will return directly to the external caller.
	 */
	function _delegate(address implementation) internal virtual {
		assembly {
			// Copy msg.data. We take full control of memory in this inline assembly
			// block because it will not return to Solidity code. We overwrite the
			// Solidity scratch pad at memory position 0.
			calldatacopy(0, 0, calldatasize())

			// Call the implementation.
			// out and outsize are 0 because we don't know the size yet.
			let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

			// Copy the returned data.
			returndatacopy(0, 0, returndatasize())

			switch result
			// delegatecall returns 0 on error.
			case 0 {
				revert(0, returndatasize())
			}
			default {
				return(0, returndatasize())
			}
		}
	}

	/**
	 * READ-ONLY FUNCTIONS
	 */

	/**
	 * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
	 * and {_fallback} should delegate.
	 * Returns the current implementation address of the associated lighthouse.
	 */
	function _implementation(
		address _sourceAddress,
		bytes32 _id
	) internal view virtual returns (address) {
		return
			ILighthouse(StorageSlot.getAddressSlot(_BEACON_SLOT).value).getImplementation(
				_sourceAddress,
				_id
			);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./errors/IExtensionFactoryErrors.sol";
import "./events/IExtensionFactoryEvents.sol";
import "../../../core/interfaces/IDaoRegistry.sol";

/// @title Extension Factory Interface
/// @notice This interface defines the functions for the Extension Factory
interface IExtensionFactory is IExtensionFactoryErrors, IExtensionFactoryEvents {
	function create(
		IDaoRegistry daoRegistry,
		address lighthouseAddress,
		bytes32 extensionId
	) external;

	/**
	 * READ-ONLY FUNCTIONS
	 */

	/**
	 * @notice Do not rely on the result returned by this right after the new extension is cloned,
	 * because it is prone to front-running attacks. During the extension creation it is safer to
	 * read the new extension address from the event generated in the create call transaction.
	 */
	function getExtension(address dao, bytes32 extensionId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./errors/IExtensionErrors.sol";
import "../../core/interfaces/IDaoRegistry.sol";

/// @title Extension Interface
/// @notice This interface defines the functions for the Extension
interface IExtension is IExtensionErrors {
	/**
	 * EXTERNAL FUNCTIONS
	 */

	function initialize(IDaoRegistry daoRegistry) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../core/interfaces/IDaoRegistry.sol";
import "../extensions/interfaces/IBankExtension.sol";

import "../core/libraries/DaoRegistryLibrary.sol";

library DaoLibrary {
	/**
	 * ERROR
	 */

	error DaoLibrary_InvalidMemberAddress(address memberAddress);

	error DaoLibrary_InvalidDelegateKey();

	/**
	 * PRIVATE VARIABLES
	 */

	///@notice Foundance
	bytes32 internal constant FOUNDANCE = keccak256("foundance");

	///@notice Dao Registry
	bytes32 internal constant DAO_EXT = keccak256("dao-ext");

	///@notice Bank Extension
	bytes32 internal constant BANK_EXT = keccak256("bank-ext");

	///@notice ERC20 Extension
	bytes32 internal constant ERC20_EXT = keccak256("erc20-ext");

	///@notice Voting Extension
	bytes32 internal constant VOTING_EXT = keccak256("voting-ext");

	///@notice Member Extension
	bytes32 internal constant MEMBER_EXT = keccak256("member-ext");

	///@notice Dynamic Equity Extension
	bytes32 internal constant DYNAMIC_EQUITY_EXT = keccak256("dynamic-equity-ext");

	///@notice Vested Equity Extension
	bytes32 internal constant VESTED_EQUITY_EXT = keccak256("vested-equity-ext");

	///@notice Community Equity Extension
	bytes32 internal constant COMMUNITY_EQUITY_EXT = keccak256("community-equity-ext");

	///@notice Dao Factory
	bytes32 internal constant DAO_EXT_FACTORY = keccak256("dao-ext-factory");

	///@notice Extension Factory
	bytes32 internal constant EXT_FACTORY = keccak256("ext-factory");

	///@notice ERC20 Adapter
	bytes32 internal constant ERC20_ADPT = keccak256("erc20-adpt");

	///@notice Member Adapter
	bytes32 internal constant MANAGER_ADPT = keccak256("manager-adpt");

	///@notice Voting Adapter
	bytes32 internal constant VOTING_ADPT = keccak256("voting-adpt");

	///@notice Member Adapter
	bytes32 internal constant MEMBER_ADPT = keccak256("member-adpt");

	///@notice Dynamic Equity Adapter
	bytes32 internal constant DYNAMIC_EQUITY_ADPT = keccak256("dynamic-equity-adpt");

	///@notice Vested Equity Adapter
	bytes32 internal constant VESTED_EQUITY_ADPT = keccak256("vested-equity-adpt");

	///@notice Community Equity Adapter
	bytes32 internal constant COMMUNITY_EQUITY_ADPT = keccak256("community-equity-adpt");

	///@notice GUILD Address
	address internal constant GUILD = address(0xdead);

	///@notice ESCROW Address
	address internal constant ESCROW = address(0x4bec);

	///@notice TOTAL Address
	address internal constant TOTAL = address(0xbabe);

	///@notice UNITS Address
	address internal constant UNITS = address(0xFF1CE);

	///@notice LOOT Address
	address internal constant LOOT = address(0xB105F00D);

	///@notice ETH_TOKEN Address
	address internal constant ETH_TOKEN = address(0x0);

	///@notice MEMBER_COUNT Address
	address internal constant MEMBER_COUNT = address(0xDECAFBAD);

	///@notice Contract
	string internal constant CONTRACT = "contract";

	///@notice config COMMUNITY_EQUITY_ID for the Community Equity Extension initial pool
	bytes32 internal constant COMMUNITY_EQUITY = keccak256("community-equity");

	///@notice config floating point precision
	uint256 internal constant FOUNDANCE_PRECISION = 5;

	///@notice config MAX_TOKENS_GUILD_BANK for the Bank Extension
	uint8 internal constant MAX_TOKENS_GUILD_BANK = 200;

	/**
	 * INTERNAL FUNCTIONS
	 */

	function _potentialNewMember(
		address memberAddress,
		IDaoRegistry daoRegistry,
		IBankExtension bankExtension
	) internal {
		daoRegistry.potentialNewMember(memberAddress);

		if (memberAddress == address(0x0)) revert DaoLibrary_InvalidMemberAddress(memberAddress);

		if (address(bankExtension) != address(0x0)) {
			if (bankExtension.balanceOf(memberAddress, DaoLibrary.MEMBER_COUNT) == 0) {
				bankExtension.addToBalance(daoRegistry, memberAddress, DaoLibrary.MEMBER_COUNT, 1);
			}
		}
	}

	/**
	 * READ-ONLY FUNCTIONS
	 */

	function _getFlag(uint256 flags, uint256 flag) internal pure returns (bool) {
		return (flags >> uint8(flag)) % 2 == 1;
	}

	function _setFlag(uint256 flags, uint256 flag, bool value) internal pure returns (uint256) {
		if (_getFlag(flags, flag) != value) {
			if (value) return flags + 2 ** flag;
			else return flags - 2 ** flag;
		} else return flags;
	}

	/**
	 * @notice Checks if a given address is zeroed.
	 */
	function _isNotZeroAddress(address addr) internal pure returns (bool) {
		return addr != address(0x0);
	}

	/**
	 * @notice Checks if a given address is reserved.
	 */
	function _isNotReservedAddress(address addr) internal pure returns (bool) {
		return addr != GUILD && addr != TOTAL && addr != ESCROW;
	}

	function _msgSender(IDaoRegistry daoRegistry, address addr) internal view returns (address) {
		address memberAddress = daoRegistry.getAddressIfDelegated(addr);
		address delegatedAddress = daoRegistry.getCurrentDelegateKey(addr);

		if (memberAddress != delegatedAddress && delegatedAddress != addr)
			revert DaoLibrary_InvalidDelegateKey();

		return memberAddress;
	}

	/**
	 * A DAO is in creation mode is the state of the DAO is equals to CREATION and
	 * 1. The number of members in the DAO is ZERO or,
	 * 2. The sender of the tx is a DAO memberAddress (usually the DAO owner) or,
	 * 3. The sender is an adapter.
	 */
	// slither-disable-next-line calls-loop
	function _isInCreationModeAndHasAccess(IDaoRegistry daoRegistry) internal view returns (bool) {
		return
			daoRegistry.getState() == DaoRegistryLibrary.DaoState.CREATION &&
			(daoRegistry.getNbMembers() == 0 ||
				daoRegistry.isMember(msg.sender) ||
				daoRegistry.isAdapter(msg.sender));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StorageSlot {
	struct AddressSlot {
		address value;
	}

	struct Bytes32Slot {
		bytes32 value;
	}

	/**
	 * @dev Returns an `AddressSlot` with member `value` located at `slot`.
	 */
	function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
		/// @solidity memory-safe-assembly
		assembly {
			r.slot := slot
		}
	}

	/**
	 * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
	 */
	function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
		/// @solidity memory-safe-assembly
		assembly {
			r.slot := slot
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Lighthouse Errors
/// @notice This interface defines the errors for Lighthouse
interface ILighthouseErrors {
	/**
	 * ERRORS
	 */

	error Lighthouse_ImplementationNotContract();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Events emitted by the Lighthouse
/// @notice Contains all events emitted by the Lighthouse
/// @dev Manages the source and implementation changes for a contract.
interface ILighthouseEvents {
	/**
	 * EVENTS
	 */

	/**
	 * @dev Emitted when the source address is changed.
	 * @param previousSource The previous source address.
	 * @param newSource The new source address.
	 */
	event SourceChanged(address previousSource, address newSource);

	/**
	 * @dev Emitted when the ID is changed.
	 * @param previousId The previous ID.
	 * @param newId The new ID.
	 */
	event IdChanged(bytes32 previousId, bytes32 newId);

	/**
	 * @dev Emitted when the implementation returned by the lighthouse is changed.
	 * @param source The source address.
	 * @param id The ID.
	 * @param implementation The new implementation address.
	 */
	event ImplementationChanged(address source, bytes32 id, address implementation);

	/**
	 * @dev Emitted when the ownership of the source address is transferred.
	 * @param source The source address.
	 * @param previousOwner The previous owner address.
	 * @param newOwner The new owner address.
	 */
	event SourceOwnerTransferred(address source, address previousOwner, address newOwner);

	/**
	 * @dev Emitted when the delegated source address is changed.
	 * @param source The source address.
	 * @param newDelegatedSource The new delegated source address.
	 */
	event DelegatedSourceChanged(address source, address newDelegatedSource);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Extension Factory Errors
/// @notice This interface defines the errors for the Extension Factory
interface IExtensionFactoryErrors {
	/**
	 * ERRORS
	 */

	error ExtensionFactory_InvalidAddress();

	error ExtensionFactory_InvalidDaoAddress();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Extension Factory Events
/// @notice This interface defines the events for the Extension Factory
interface IExtensionFactoryEvents {
	/**
	 * EVENTS
	 */

	event ExtensionFactory_ExtensionCreated(
		address daoAddress,
		address extensionAddress,
		bytes32 extensionFactory
	);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title DaoRegistry Events
/// @notice This interface defines the events for DaoRegistry
interface IDaoRegistryEvents {
	/**
	 * EVENTS
	 */

	event SubmittedProposal(bytes32 proposalId, uint256 flags);

	event SponsoredProposal(bytes32 proposalId, uint256 flags, address votingAdapter);

	event ProcessedProposal(bytes32 proposalId, uint256 flags);

	event AdapterAdded(bytes32 adapterId, address adapterAddress, uint256 flags);

	event AdapterRemoved(bytes32 adapterId);

	event ExtensionAdded(bytes32 extensionId, address extensionAddress);

	event ExtensionRemoved(bytes32 extensionId);

	event UpdateDelegateKey(address memberAddress, address newDelegateKey);

	event UpdateProxyConfiguration(address lighthouse, address delegatedSource);

	event SetImplementationBatch(
		address lighthouse,
		address source,
		address[] implementationAddresses,
		bytes32[] implementationIds
	);

	event SetDelegatedSource(address lighthouse, address source, address delegatedSource);

	event ConfigurationUpdated(bytes32 key, uint256 value);

	event AddressConfigurationUpdated(bytes32 key, address value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title DaoRegistry Errors
/// @notice This interface defines the errors for DaoRegistry
interface IDaoRegistryErrors {
	/**
	 * ERRORS
	 */

	error DaoRegistry_AlreadyInitialized();

	error DaoRegistry_AccessDenied();

	error DaoRegistry_NotAllowedToFinalize();

	error DaoRegistry_EmptyExtensionId();

	error DaoRegistry_RegisteredExtensionId();

	error DaoRegistry_UnregisteredExtensionId();

	error DaoRegistry_DeletedExtension();

	error DaoRegistry_AdapterNotFound();

	error DaoRegistry_AdapterMismatch();

	error DaoRegistry_EmptyAdapterId();

	error DaoRegistry_RegisteredAdapterId();

	error DaoRegistry_UnregisteredAdapterId();

	error DaoRegistry_AlreadySetFlag();

	error DaoRegistry_InvalidProposalId();

	error DaoRegistry_NotExistingProposalId();

	error DaoRegistry_NotUniqueProposalId();

	error DaoRegistry_AlreadyProcessedProposalId();

	error DaoRegistry_InvalidMember();

	error DaoRegistry_NotExistingMember();

	error DaoRegistry_BlockNumberNotFinalized();

	error DaoRegistry_InvalidDelegateKey();

	error DaoRegistry_DelegateKeyAlreadyTaken();

	error DaoRegistry_DelegateKeyAddressAlreadyTaken();

	error DaoRegistry_MemberAddressAlreadyUsedAsDelegate();

	error DaoRegistry_InvalidLighthouseAddress();

	error DaoRegistry_InvalidImplementationArrayLength();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Extension Errors
/// @notice This interface defines the errors for the Extension
interface IExtensionErrors {
	/**
	 * ERRORS
	 */

	error Extension_ReservedAddress();

	error Extension_NotAMember(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IExtension.sol";
import "./errors/IBankExtensionErrors.sol";
import "./events/IBankExtensionEvents.sol";
import "../../core/interfaces/IDaoRegistry.sol";

/// @title Bank Extension Interface
/// @notice This interface defines the functions for the Bank Extension
interface IBankExtension is IExtension, IBankExtensionErrors, IBankExtensionEvents {
	/**
	 * EXTERNAL FUNCTIONS
	 */

	function withdraw(
		IDaoRegistry daoRegistry,
		address payable member,
		address tokenAddr,
		uint256 amount
	) external;

	function withdrawTo(
		IDaoRegistry daoRegistry,
		address memberFrom,
		address payable memberTo,
		address tokenAddr,
		uint256 amount
	) external;

	/**
	 * @notice Sets the maximum amount of external tokens allowed in the bank
	 * @param maxTokens The maximum amount of token allowed
	 */
	function setMaxExternalTokens(uint8 maxTokens) external;

	/**
	 * @notice Registers a potential new token in the bank
	 * @dev Cannot be a reserved token or an available internal token
	 * @param token The address of the token
	 */
	function registerPotentialNewToken(IDaoRegistry daoRegistry, address token) external;

	/**
	 * @notice Registers a potential new internal token in the bank
	 * @dev Can not be a reserved token or an available token
	 * @param token The address of the token
	 */
	function registerPotentialNewInternalToken(IDaoRegistry daoRegistry, address token) external;

	function updateToken(IDaoRegistry daoRegistry, address tokenAddr) external;

	function getPriorAmount(
		address account,
		address tokenAddr,
		uint256 blockNumber
	) external view returns (uint256);

	function addToBalance(
		IDaoRegistry daoRegistry,
		address member,
		address token,
		uint256 amount
	) external payable;

	function addToBalanceBatch(
		IDaoRegistry daoRegistry,
		address[] memory member,
		address token,
		uint256[] memory amount
	) external payable;

	function subtractFromBalance(
		IDaoRegistry daoRegistry,
		address member,
		address token,
		uint256 amount
	) external;

	function balanceOf(address member, address tokenAddr) external view returns (uint160);

	function internalTransfer(
		IDaoRegistry daoRegistry,
		address from,
		address to,
		address token,
		uint256 amount
	) external;

	function isInternalToken(address token) external view returns (bool);

	function getMaxExternalTokens() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Bank Extension Errors
/// @notice This interface defines the errors for Bank Extension
interface IBankExtensionErrors {
	/**
	 * ERRORS
	 */

	error Bank_AccessDenied();

	error Bank_AlreadyInitialized();

	error Bank_NotEnoughFunds();

	error Bank_TooManyExternalTokens();

	error Bank_TooManyInternalTokens();

	error Bank_ExternalTokenAmountLimitExceeded();

	error Bank_InternalTokenAmountLimitExceeded();

	error Bank_UnregisteredToken();

	error Bank_BlockNumberNotFinalized();

	error Bank_NoTransferFromJailedMember(address member);

	error Bank_NoTransferToJailedMember(address member);

	error Bank_NotImplemented();

	error Bank_MaxExternalTokensOutOfRange();

	error Bank_TokenAlreadyInternal(address token);

	error Bank_TokenAlreadyExternal(address token);

	error Bank_TokenNotRegistered(address token);

	error Bank_NotAMember(address member);

	error Bank_DaoLocked();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Bank Extension Events
/// @notice This interface defines the events for Bank Extension
interface IBankExtensionEvents {
	/**
	 * EVENTS
	 */

	event NewBalance(address member, address tokenAddr, uint160 amount);

	event Withdraw(address account, address tokenAddr, uint160 amount);

	event WithdrawTo(address accountFrom, address accountTo, address tokenAddr, uint160 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title DAO Factory Events
/// @notice This interface defines the events for DAO Factory
interface IDaoFactoryEvents {
	/**
	 * EVENTS
	 */

	/**
	 * @notice Event emitted when a new DAO has been created.
	 * @param _address The DAO address.
	 * @param _name The DAO name.
	 */
	event DaoFactory_DaoCreated(address _address, string _name);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title DAO Factory Errors
/// @notice This interface defines the errors for DAO Factory
interface IDaoFactoryErrors {
	/**
	 * ERRORS
	 */

	error DaoFactory_DaoAlreadyExists();

	error DaoFactory_InvalidAddress();

	error DaoFactory_NotMember();

	error DaoFactory_DaoNameTaken(string daoName);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title ERC20 Extension Library
/// @notice This library defines the structs used by the ERC20 Extension
library ERC20ExtensionLibrary {
	/**
	 * ENUMS
	 */

	enum AclFlag {
		REGISTER_TRANSFER,
		SET_CONFIGURATION
	}

	enum ApprovalType {
		NONE,
		STANDARD,
		SPECIAL
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Foundance Events
/// @notice This interface defines the events for Foundance
interface IFoundanceEvents {
	/**
	 * EVENTS
	 */

	/**
	 * @notice Event emitted when a new Foundance-Agreement has been registered
	 * @param  userAddress The address of the interacting user
	 * @param  projectId The Foundance project Id
	 * @param  name The Foundance agreement name
	 */
	event FoundanceRegisteredEvent(address userAddress, uint32 projectId, string name);

	/**
	 * @notice Event emitted when a new Foundance-Agreement has been approved
	 * @dev
	 * @param  userAddress The address of the interacting member
	 * @param  projectId The Foundance project Id
	 * @param  name The Foundance agreement name
	 */
	event FoundanceApprovedEvent(address userAddress, uint32 projectId, string name);

	/**
	 * @notice Event emitted when a new Foundance-Agreement has been updated
	 * @dev
	 * @param  userAddress The address of the interacting member
	 * @param  projectId The Foundance project Id
	 */
	event FoundanceUpdatedEvent(address userAddress, uint32 projectId);

	event FoundanceLiveEvent(address creatorAddress, uint32 projectId, address daoAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Foundance Errors
/// @notice This interface defines the errors for Foundance
interface IFoundanceErrors {
	/**
	 * ERRORS
	 */

	error Foundance_AlreadyInitialized();

	error Foundance_DoesNotExist();

	error Foundance_OnlyCreator();

	error Foundance_OnlyAdmin();

	error Foundance_NameAlreadyTaken();

	error Foundance_IdAlreadyTaken();

	error Foundance_MemberDoesntExists();

	error Foundance_NotApproved();

	error Foundance_SubnodeOwnerZeroAddress();

	error Foundance_DomainOwnerZeroAddress();

	error Foundance_IsAlreadyLive();

	error Foundance_ProjectLocked(uint32 projectId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../../extensions/libraries/DynamicEquityExtensionLibrary.sol";
import "../../../core/libraries/DaoRegistryLibrary.sol";

/// @title Events emitted by the DynamicEquityAdapter
/// @notice Contains all events emitted by the DynamicEquityAdapter
interface IDynamicEquityAdapterEvents {
	/**
	 * EVENTS
	 */

	event SubmitSetDynamicEquityProposalEvent(
		address daoAddress,
		address senderAddress,
		bytes data,
		bytes32 proposalId,
		DynamicEquityExtensionLibrary.DynamicEquityConfig dynamicEquityConfig,
		DaoRegistryLibrary.EpochConfig epochConfig
	);

	event SubmitSetDynamicEquityEpochProposalEvent(
		address daoAddress,
		address senderAddress,
		bytes data,
		bytes32 proposalId,
		uint256 lastEpoch,
		uint32 lastIndex
	);

	event SubmitSetDynamicEquityMemberProposalEvent(
		address daoAddress,
		address senderAddress,
		bytes data,
		bytes32 proposalId,
		DynamicEquityExtensionLibrary.DynamicEquityMemberConfig dynamicEquityMemberConfig
	);

	event SubmitSetDynamicEquityMemberSuspendProposalEvent(
		address daoAddress,
		address senderAddress,
		bytes data,
		bytes32 proposalId,
		address memberAddress,
		uint256 suspendUntil
	);

	event SubmitSetDynamicEquityMemberExpenseProposalEvent(
		address daoAddress,
		address senderAddress,
		bytes data,
		bytes32 proposalId,
		address memberAddress,
		uint256 expenseAmount,
		uint256 authorizedUntil
	);

	event SubmitSetDynamicEquityMemberEpochProposalEvent(
		address daoAddress,
		address senderAddress,
		bytes data,
		bytes32 proposalId,
		DynamicEquityExtensionLibrary.DynamicEquityMemberConfig dynamicEquityMemberConfig
	);

	event SubmitSetDynamicEquityMemberEpochDefaultProposalEvent(
		address daoAddress,
		address senderAddress,
		bytes data,
		bytes32 proposalId,
		DynamicEquityExtensionLibrary.DynamicEquityMemberConfig dynamicEquityMemberConfig
	);

	event SubmitRemoveDynamicEquityMemberProposalEvent(
		address daoAddress,
		address senderAddress,
		bytes data,
		bytes32 proposalId,
		address memberAddress
	);

	event SubmitRemoveDynamicEquityMemberEpochProposalEvent(
		address daoAddress,
		address senderAddress,
		bytes data,
		bytes32 proposalId,
		address memberAddress
	);

	event ProcessSetDynamicEquityProposalEvent(
		address daoAddress,
		address senderAddress,
		bytes32 proposalId,
		DynamicEquityExtensionLibrary.DynamicEquityConfig dynamicEquityConfig,
		DaoRegistryLibrary.EpochConfig epochConfig
	);

	event ProcessSetDynamicEquityEpochProposalEvent(
		address daoAddress,
		address senderAddress,
		bytes32 proposalId,
		uint32 lastIndex,
		uint256 lastEpoch
	);

	event ProcessSetDynamicEquityMemberProposalEvent(
		address daoAddress,
		address senderAddress,
		bytes32 proposalId,
		DynamicEquityExtensionLibrary.DynamicEquityMemberConfig dynamicEquityMemberConfig
	);

	event ProcessSetDynamicEquityMemberSuspendProposalEvent(
		address daoAddress,
		address senderAddress,
		bytes32 proposalId,
		address memberAddress,
		uint256 suspendUntil
	);

	event ProcessSetDynamicEquityMemberEpochProposalEvent(
		address daoAddress,
		address senderAddress,
		bytes32 proposalId,
		DynamicEquityExtensionLibrary.DynamicEquityMemberConfig dynamicEquityMemberConfig
	);

	event ProcessSetDynamicEquityMemberEpochDefaultProposalEvent(
		address daoAddress,
		address senderAddress,
		bytes32 proposalId,
		DynamicEquityExtensionLibrary.DynamicEquityMemberConfig dynamicEquityMemberConfig
	);

	event ProcessSetDynamicEquityMemberExpenseProposalEvent(
		address daoAddress,
		address senderAddress,
		bytes32 proposalId,
		address memberAddress,
		uint256 requestAmount,
		uint256 expenseAmount,
		uint256 authorizedUntil
	);

	event ProcessRemoveDynamicEquityMemberProposalEvent(
		address daoAddress,
		address senderAddress,
		bytes32 proposalId,
		address memberAddress
	);

	event ProcessRemoveDynamicEquityMemberEpochProposalEvent(
		address daoAddress,
		address senderAddress,
		bytes32 proposalId,
		address memberAddress
	);

	event ActDynamicEquityMemberEpochDistributeEvent(
		address daoAddress,
		address senderAddress,
		address memberAddress,
		address tokenAddress,
		uint256 tokenAmount
	);

	event ActDynamicEquityEpochDistributeEvent(
		address daoAddress,
		address senderAddress,
		uint32 distributionIndex,
		uint256 distributionEpoch
	);

	event ActDynamicEquityMemberEpochProposalCancelEvent(
		address daoAddress,
		address senderAddress,
		bytes32 proposalId
	);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Dynamic Equity Adapter Errors
/// @notice This interface contains all the errors emitted by the DynamicEquityAdapter
interface IDynamicEquityAdapterErrors {
	/**
	 * ERRORS
	 */

	error DynamicEquityAdapter_ProposalAlreadyProcessed();

	error DynamicEquityAdapter_OngoingProposal();

	error DynamicEquityAdapter_NotAvailableDuringReviewPeriod();

	error DynamicEquityAdapter_OnlyMemberCanProcess();

	error DynamicEquityAdapter_ExpenseAmountTooHigh();

	error DynamicEquityAdapter_NoOngoingProposal();

	error DynamicEquityAdapter_InvalidMemberAddress();

	error DynamicEquityAdapter_InvalidProposalId();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../libraries/VotingExtensionLibrary.sol";

/// @title Voting Extension Events
/// @notice This interface defines the events for Voting Extension
interface IVotingExtensionEvents {
	/**
	 * EVENTS
	 */

	event Voting_StartNewVotingForProposalEvent(
		address daoAddress,
		bytes32 proposalId,
		VotingExtensionLibrary.Voting voting,
		VotingExtensionLibrary.VotingConfig votingConfig
	);

	event Voting_ProcessVotingEvent(
		address daoAddress,
		bytes32 proposalId,
		VotingExtensionLibrary.VotingState votingState
	);

	event Voting_CancelVotingEvent(address daoAddress, bytes32 proposalId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Voting Extension Errors
/// @notice This interface defines the errors for the Extension
interface IVotingExtensionErrors {
	/**
	 * ERRORS
	 */

	error Voting_AccessDenied();

	error Voting_AlreadyInitialized();

	error Voting_InvalidVote();

	error Voting_InvalidWeight();

	error Voting_InvalidConfiguration();

	error Voting_VotingPeriodOver();

	error Voting_VotingNotStarted();

	error Voting_MemberAlreadyVoted();

	error Voting_MemberHasNoVotingPower();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title ERC20 Extension Errors
/// @notice This interface defines the errors for ERC20 Extension
interface IERC20ExtensionErrors {
	/**
	 * ERRORS
	 */

	error ERC20_AlreadyInitialized();

	error ERC20_InvalidTokenAddress();

	error ERC20_MissingTokenName();

	error ERC20_MissingTokenSymbol();

	error ERC20_MissingTokenDecimals();

	error ERC20_ReservedTokenAddress();

	error ERC20_InvalidSender();

	error ERC20_InvalidSpender();

	error ERC20_SenderNotMember();

	error ERC20_SpenderReservedAddress();

	error ERC20_InvalidRecipient();

	error ERC20_TransferNotAllowed();

	error ERC20_InsufficientAllowance();

	error ERC20_AccessDenied();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Member Extension Errors
/// @notice This interface defines the errors for Member Extension
interface IMemberExtensionErrors {
	/**
	 * ERRORS
	 */

	error Member_AccessDenied();

	error Member_AlreadyInitialized();

	error Member_UndefinedMember();

	error Member_ReservedAddress();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../libraries/VotingExtensionLibrary.sol";

/// @title Dynamic Equity Extension Events
/// @notice This interface defines the events for Dynamic Equity Extension
interface IDynamicEquityExtensionEvents {
	/**
	 * EVENTS
	 */

	event EpochConfigChangedEvent(address daoAddress, uint32 newEpochLastIndex, uint256 newEpochLast);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Dynamic Equity Extension Errors
/// @notice This interface defines the errors for Dynamic Equity Extension
interface IDynamicEquityExtensionErrors {
	/**
	 * ERRORS
	 */

	error DynamicEquity_AccessDenied();

	error DynamicEquity_AlreadyInitialized();

	error DynamicEquity_InvalidEpoch();

	error DynamicEquity_InvalidCommunityEquity();

	error DynamicEquity_UndefinedMember();

	error DynamicEquity_ReservedAddress();

	error DynamicEquity_AvailabilityOutOfBound();

	error DynamicEquity_ExpenseOutOfBound();

	error DynamicEquity_ExpenseCommittedOutOfBound();

	error DynamicEquity_WithdrawalOutOfBound();

	error DynamicEquity_EpochIndexOutOfBound();
}