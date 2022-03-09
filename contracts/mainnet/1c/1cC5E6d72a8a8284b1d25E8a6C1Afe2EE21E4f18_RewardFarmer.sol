// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC1155MetadataURI.sol";

import "./libraries/LibraryFarmer.sol";
import "./interfaces/IRegistryFarmer.sol";
import "./interfaces/IRewardFarmer.sol";
import "./interfaces/ITheFarm.sol";
import "./interfaces/IMetaFarmer.sol";
import "./interfaces/IRevealFarmer.sol";
import "./interfaces/IPotato.sol";

contract RewardFarmer is IRewardFarmer, OwnableUpgradeable {
	using LibraryFarmer for LibraryFarmer.FarmerContract;

	// Infrastructure
	IRegistryFarmer public registryFarmer;
	ITheFarm public theFarm;
	IPotato public rewardToken;

	// Reward types
	mapping(RewardType => uint8) rewardTypeIdByRewardType;

	// Characters
	mapping(Character => address) public characterToContract;
	mapping(Character => bool) public isRewardableByCharacter;
	mapping(Character => mapping(uint256 => uint256))
		public rewardedBlocksByCharacterByCharacterId;

	// Airdrops
	mapping(address => uint256) public airdropAllocationByAddress;
	mapping(Character => mapping(uint256 => uint256))
		public airdropAllocationByIdByCharacter;

	modifier isRewardable(Character character) {
		require(
			isRewardableByCharacter[character],
			"Character is not rewardable"
		);
		_;
	}

	modifier onlyDepositor(Character character, uint256 id) {
		bool isOwner = owner() == msg.sender;
		require(
			isOwner || _isCharacterDepositor(character, id, msg.sender),
			"Only depositor can claim rewards"
		);
		_;
	}

	function initialize(
		address _rewardToken,
		address _theFarm,
		address _registryFarmer
	) public initializer {
		__Ownable_init();

		// Setup infrastructure
		rewardToken = IPotato(_rewardToken);
		theFarm = ITheFarm(_theFarm);
		registryFarmer = IRegistryFarmer(_registryFarmer);
		characterToContract[Character.HONEST_FARMER] = registryFarmer.contracts(
			LibraryFarmer.FarmerContract.HonestFarmerClubV2
		);

		// Reward Types
		rewardTypeIdByRewardType[RewardType.TAX] = 0;
		rewardTypeIdByRewardType[RewardType.STAKING] = 1;
		rewardTypeIdByRewardType[RewardType.AIRDROP] = 2;
		rewardTypeIdByRewardType[RewardType.HONEST_WORK] = 3;
		rewardTypeIdByRewardType[RewardType.TREASURY] = 3;
		rewardTypeIdByRewardType[RewardType.LP_FARMING] = 4;
	}

	// Minting
	function _mintTax(uint256 amount, address taxPayer) private {
		rewardToken.mintReward(
			_getRewardTypeId(RewardType.TAX),
			address(this),
			amount
		);
		emit MintTax(RewardType.TAX, taxPayer, amount);
	}

	function _mintReward(
		RewardType rewardType,
		address recipient,
		uint256 amount
	) private {
		rewardToken.mintReward(_getRewardTypeId(rewardType), recipient, amount);
		emit MintReward(rewardType, recipient, amount);
	}

	function _mintRewardWithTax(
		RewardType rewardType,
		address recipient,
		uint256 amount
	) private {
		uint256 taxAmount = amount / 5;
		uint256 rewardAmount = amount - taxAmount;

		_mintReward(rewardType, recipient, rewardAmount);
		_mintTax(taxAmount, recipient);
	}

	// Staking Rewards
	function _claimStakingReward(Character character, uint256 characterId)
		private
		isRewardable(character)
	{
		uint256 numberOfBlocksLocked = getNumberOfBlocksLocked(
			character,
			characterId
		);
		uint256 rewardMultiplier = getRewardMultiplier(character, characterId);
		uint256 rewardableBlocks = getRewardableBlocks(character, characterId);
		(uint256 rewardAmount, uint256 rewardedBlocks) = getRewardablePotato(
			rewardableBlocks,
			numberOfBlocksLocked,
			rewardMultiplier
		);

		require(rewardAmount > 0, "No claimable staking reward");

		// Mint reward
		_claimBlocks(character, characterId);
		_mintRewardWithTax(RewardType.STAKING, msg.sender, rewardAmount);
		emit RewardStaking(character, characterId, rewardedBlocks);

		// Track rewarded blocks
		rewardedBlocksByCharacterByCharacterId[character][
			characterId
		] += rewardedBlocks;
	}

	function claimStakingReward(Character character, uint256 characterId)
		public
		onlyDepositor(character, characterId)
	{
		_claimStakingReward(character, characterId);
	}

	function claimStakingRewardBatch(
		Character character,
		uint256[] memory characterIds
	) public {
		for (uint256 id = 0; id < characterIds.length; id++) {
			claimStakingReward(character, characterIds[id]);
		}
	}

	// Airdrop Rewards
	function _claimAirdrop(address account, uint256 amount) private {
		_mintRewardWithTax(RewardType.AIRDROP, account, amount);
	}

	function claimAirdrop() public {
		uint256 airdropAllocation = getAirdropAllocation(msg.sender);
		require(airdropAllocation > 0, "No airdrop found");

		_claimAirdrop(msg.sender, airdropAllocation);
		airdropAllocationByAddress[msg.sender] = 0;
		emit ClaimAirdrop(msg.sender, airdropAllocation);
	}

	function claimCharacterAirdrop(Character character, uint256 characterId)
		public
		onlyDepositor(character, characterId)
		isRewardable(character)
	{
		uint256 airdropAllocation = getCharacterAirdropAllocation(
			character,
			characterId
		);
		require(airdropAllocation > 0, "No character airdrop found");

		_claimAirdrop(msg.sender, airdropAllocation);
		airdropAllocationByIdByCharacter[character][characterId] = 0;
		emit ClaimCharacterAirdrop(
			character,
			characterId,
			msg.sender,
			airdropAllocation
		);
	}

	function claimCharacterAirdropBatch(
		Character character,
		uint256[] memory characterIds
	) public {
		for (uint256 id = 0; id < characterIds.length; id++) {
			claimCharacterAirdrop(character, characterIds[id]);
		}
	}

	function setAirdrop(address recipient, uint256 amount) public onlyOwner {
		airdropAllocationByAddress[recipient] += amount;
	}

	function setAirdropBatch(
		address[] memory recipients,
		uint256[] memory amounts
	) public onlyOwner {
		for (uint256 i = 0; i < recipients.length; i++) {
			setAirdrop(recipients[i], amounts[i]);
		}
	}

	function setCharacterAirdrop(
		Character character,
		uint256 id,
		uint256 amount
	) public onlyOwner {
		airdropAllocationByIdByCharacter[character][id] += amount;
	}

	function setCharacterAirdropBatch(
		Character[] memory characters,
		uint256[] memory ids,
		uint256[] memory amounts
	) public onlyOwner {
		for (uint256 i = 0; i < characters.length; i++) {
			setCharacterAirdrop(characters[i], ids[i], amounts[i]);
		}
	}

	function setIsRewardableByCharacter(Character character, bool _isRewardable)
		public
		onlyOwner
	{
		isRewardableByCharacter[character] = _isRewardable;
		emit SetCharacterIsRewardadble(character, _isRewardable);
	}

	function withdrawToken(address _token) public onlyOwner {
		IERC20 token = IERC20(_token);
		uint256 balance = token.balanceOf(address(this));
		token.transferFrom(address(this), msg.sender, balance);
	}

	function claimReward(RewardType rewardType, uint256 amount)
		public
		onlyOwner
	{
		_mintReward(rewardType, msg.sender, amount);
	}

	function updateRegistryFarmer(address _registryFarmer) public onlyOwner {
		registryFarmer = IRegistryFarmer(_registryFarmer);
	}

	function updateRewardToken(address _rewardToken) public onlyOwner {
		rewardToken = IPotato(_rewardToken);
	}

	function updateTheFarm(address _theFarm) public onlyOwner {
		theFarm = ITheFarm(_theFarm);
	}

	// Views
	function getRewardableBlocks(Character character, uint256 characterId)
		public
		view
		returns (uint256 _rewardableBlocks)
	{
		if (!isRewardableByCharacter[character]) return 0;

		uint256 rewardedBlocks = rewardedBlocksByCharacterByCharacterId[
			character
		][characterId];
		uint256 claimedBlocks = theFarm.claimedBlocksByFarmerId(characterId);
		uint256 claimableBlocks = theFarm.getClaimableBlocks(characterId);

		uint256 rewardableBlocks = (claimedBlocks + claimableBlocks) -
			rewardedBlocks;

		return rewardableBlocks;
	}

	function getNumberOfBlocksLocked(Character character, uint256 characterId)
		public
		view
		returns (uint256 _numberOfBlocksLocked)
	{
		if (character != Character.HONEST_FARMER) return 0;

		uint256 depositBlockNumber = theFarm.getLatestDepositBlock(characterId);
		uint256 unlockBlockByFarmerId = theFarm.unlockBlockByFarmerId(
			characterId
		);
		uint256 numberOfBlocksLocked = unlockBlockByFarmerId -
			depositBlockNumber;

		return numberOfBlocksLocked;
	}

	function getRewardMultiplier(Character character, uint256 characterId)
		public
		view
		returns (uint256 multiplier)
	{
		return _isSpecialCharacter(character, characterId) ? 5 : 1;
	}

	function getRewardablePotato(
		uint256 rewardableBlocks,
		uint256 numberOfBlocksLocked,
		uint256 rewardMultiplier
	) public view returns (uint256 _rewardAmount, uint256 _rewardedBlocks) {
		// Potato Rewards
		uint256 potatoPerDay = theFarm.potatoPerDayByLockingDuration(
			numberOfBlocksLocked
		);

		// Time
		// 1/4 hour = 450 blocks > 432 blocks = 1% of a day = 0.1 POTATO
		uint256 BLOCKS_PER_MINUTE = 30;
		uint256 BLOCKS_PER_HOUR = BLOCKS_PER_MINUTE * 60; // 1,800 blocks = 0.4 POTATO, 72 blocks unclaimed
		uint256 BLOCKS_PER_DAY = BLOCKS_PER_HOUR * 24; // 43,200 blocks = 10 POTATO, 0 blocks unclaimed

		uint256 BLOCKS_PER_ONE_HUNDRETH_DAY = BLOCKS_PER_DAY / 100; // 432 blocks = 0.1 POTATO, 0 blocks unclaimed

		// Blocks
		uint256 unrewardedBlocks = rewardableBlocks %
			BLOCKS_PER_ONE_HUNDRETH_DAY;
		uint256 rewardedBlocks = rewardableBlocks - unrewardedBlocks;
		uint256 rewardableHundrethDays = rewardedBlocks /
			BLOCKS_PER_ONE_HUNDRETH_DAY;

		// Multiply by 10^16 instead of 10^18, because shortest claimable period represents 1/100th of a day
		uint256 potato = (potatoPerDay * 10**16) *
			rewardableHundrethDays *
			rewardMultiplier;

		return (potato, rewardedBlocks);
	}

	function getAirdropAllocation(address account)
		public
		view
		returns (uint256 _potato)
	{
		return airdropAllocationByAddress[account];
	}

	function getAirdropAllocationBatch(address[] memory accounts)
		public
		view
		returns (uint256[] memory _potato)
	{
		uint256[] memory potato = new uint256[](accounts.length);
		for (uint256 i = 0; i < accounts.length; i++) {
			potato[i] = getAirdropAllocation(accounts[i]);
		}

		return potato;
	}

	function getCharacterAirdropAllocation(Character character, uint256 id)
		public
		view
		returns (uint256 _potato)
	{
		return airdropAllocationByIdByCharacter[character][id];
	}

	function getCharacterAirdropAllocationBatch(
		Character character,
		uint256[] memory ids
	) public view returns (uint256[] memory _potato) {
		uint256[] memory potato = new uint256[](ids.length);
		for (uint256 i = 0; i < ids.length; i++) {
			potato[i] = getCharacterAirdropAllocation(character, ids[i]);
		}

		return potato;
	}

	// Utils
	function _isCharacterDepositor(
		Character character,
		uint256 characterId,
		address account
	) private view returns (bool _isDepositor) {
		return
			(character == Character.HONEST_FARMER)
				? theFarm.getDepositor(characterId) == account
				: false;
	}

	function _claimBlocks(Character character, uint256 characterId) private {
		if (character == Character.HONEST_FARMER) {
			theFarm.claimBlocks(characterId);
		}
	}

	function _isSpecialCharacter(Character character, uint256 characterId)
		private
		view
		returns (bool _isSpecial)
	{
		if (character != Character.HONEST_FARMER) return false;

		IRevealFarmer revealFarmer = IRevealFarmer(
			registryFarmer.contracts(LibraryFarmer.FarmerContract.RevealFarmer)
		);
		IMetaFarmer metafarmer = IMetaFarmer(
			registryFarmer.contracts(LibraryFarmer.FarmerContract.MetaFarmer)
		);

		uint256 internalId = revealFarmer.getInternalTokenId(characterId);
		bool isSpecial = metafarmer.isSpecialByInternalTokenId(internalId);

		return isSpecial;
	}

	function _getRewardTypeId(RewardType rewardType)
		private
		view
		returns (uint8)
	{
		return rewardTypeIdByRewardType[rewardType];
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/extensions/IERC1155MetadataURI.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library LibraryFarmer {
	// Metadata
	enum Passion {
		Harvesting,
		Fishing,
		Planting
	}

	enum Skill {
		Degen,
		Honesty,
		Fitness,
		Strategy,
		Patience,
		Agility
	}

	enum VisualTraitType {
		Background,
		Skin,
		Clothing,
		Mouth,
		Nose,
		Head,
		Eyes,
		Ears
	}

	struct FarmerMetadata {
		uint256 internalTokenId;
		uint8[8] visualTraitValueIds;
		bool isSpecial;
		string ipfsHash;
	}

	// Mint
	enum MintType {
		PUBLIC,
		WHITELIST,
		FREE
	}

	function isWhitelistMintType(LibraryFarmer.MintType mintType)
		public
		pure
		returns (bool)
	{
		return mintType == LibraryFarmer.MintType.WHITELIST;
	}

	// Infrastructure
	enum FarmerContract {
		HonestFarmerClubV1,
		HonestFarmerClubV2,
		EnergyFarmer,
		MetaFarmer,
		MigrationTractor,
		OnchainArtworkFarmer,
		RevealFarmer,
		WhitelistFarmer
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../libraries/LibraryFarmer.sol";

interface IRegistryFarmer {
	function contracts(LibraryFarmer.FarmerContract _contract)
		external
		view
		returns (address);

	function updateContract(
		LibraryFarmer.FarmerContract _contract,
		address _address
	) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

enum Character {
	HONEST_FARMER,
	FARM_GIRL,
	ANIMAL,
	LAND,
	HONORARY
}

enum RewardType {
	TAX,
	STAKING,
	AIRDROP,
	HONEST_WORK,
	TREASURY,
	LP_FARMING
}

interface IRewardFarmer {
	function claimStakingReward(Character character, uint256 characterId)
		external;

	function claimStakingRewardBatch(
		Character character,
		uint256[] memory characterIds
	) external;

	function claimAirdrop() external;

	function claimCharacterAirdrop(Character character, uint256 characterId)
		external;

	function claimCharacterAirdropBatch(
		Character character,
		uint256[] memory characterIds
	) external;

	// Views
	function getRewardableBlocks(Character character, uint256 characterId)
		external
		view
		returns (uint256 _rewardableBlocks);

	function getNumberOfBlocksLocked(Character character, uint256 characterId)
		external
		view
		returns (uint256 _numberOfBlocksLocked);

	function getRewardMultiplier(Character character, uint256 characterId)
		external
		view
		returns (uint256 multiplier);

	function getRewardablePotato(
		uint256 rewardableBlocks,
		uint256 numberOfBlocksLocked,
		uint256 rewardMultiplier
	) external view returns (uint256 _rewardAmount, uint256 _rewardedBlocks);

	function getAirdropAllocation(address account)
		external
		view
		returns (uint256 _potato);

	function getAirdropAllocationBatch(address[] memory accounts)
		external
		view
		returns (uint256[] memory _potato);

	function getCharacterAirdropAllocation(Character character, uint256 id)
		external
		view
		returns (uint256 _potato);

	function getCharacterAirdropAllocationBatch(
		Character character,
		uint256[] memory ids
	) external view returns (uint256[] memory _potato);

	// Events
	event MintReward(
		RewardType indexed rewardType,
		address indexed recipient,
		uint256 amount
	);

	event MintTax(
		RewardType indexed rewardType,
		address indexed taxPayer,
		uint256 amount
	);

	event RewardStaking(
		Character indexed character,
		uint256 indexed characterId,
		uint256 rewardedBlocks
	);

	event ClaimAirdrop(address indexed account, uint256 amount);

	event ClaimCharacterAirdrop(
		Character indexed character,
		uint256 indexed characterId,
		address indexed account,
		uint256 amount
	);

	event SetCharacterIsRewardadble(
		Character indexed character,
		bool indexed isRewardable
	);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ITheFarm {
	// Stake
	function stakeFarmer(uint256 farmerId, uint256 lockingDurationDays)
		external;

	function stakeFarmerBatch(
		uint256[] memory farmerIds,
		uint256 lockingDurationDays
	) external;

	// Claiming
	function claimBlocks(uint256 farmerId) external;

	function claimBlocksBatch(uint256[] memory farmerIds) external;

	// Withdraw
	function withdrawFarmer(uint256 farmerId) external;

	function withdrawFarmerBatch(uint256[] memory farmerIds) external;

	// Emission Delegation
	function addDelegate(address delegate) external;

	function removeDelegate(address delegate) external;

	// Admin
	function toggleIsClaimable() external;

	function setPotatoRewards(uint256 lockingDurationDays, uint256 potatoPerDay)
		external;

	function withdrawFunds() external;

	function emergencyWithdrawFarmers(uint256[] memory farmerIds) external;

	// Views
	function potatoPerDayByLockingDuration(uint256 lockingDurationDays)
		external
		view
		returns (uint256 _potatoPerDay);

	function claimedBlocksByFarmerId(uint256 farmerId)
		external
		view
		returns (uint256 _claimedBlocks);

	function isUnlocked(uint256 farmerId)
		external
		view
		returns (bool _isUnlocked);

	function getLatestDepositBlock(uint256 farmerId)
		external
		view
		returns (uint256);

	function getClaimableBlocksByBlock(uint256 farmerId, uint256 blockNumber)
		external
		view
		returns (uint256);

	function getClaimableBlocks(uint256 farmerId)
		external
		view
		returns (uint256);

	function unlockBlockByFarmerId(uint256 farmerId)
		external
		view
		returns (uint256);

	function getClaimableBlocksByBlockBatch(
		uint256[] memory farmerIds,
		uint256 blockNumber
	) external view returns (uint256[] memory _claimableBlocks);

	function getClaimableBlocksBatch(uint256[] memory farmerIds)
		external
		view
		returns (uint256[] memory _claimableBlocks);

	function getDepositor(uint256 farmerId)
		external
		view
		returns (address _depositor);

	function getDepositorBatch(uint256[] memory farmerIds)
		external
		view
		returns (address[] memory _depositors);

	function isStaked(uint256 farmerId) external view returns (bool);

	function isStakedBatch(uint256[] memory farmerIds)
		external
		view
		returns (bool[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IMetaFarmer {
	function uri(uint256 internalTokenId) external view returns (string memory);

	function isSpecialByInternalTokenId(uint256 internalTokenId)
		external
		view
		returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../libraries/LibraryFarmer.sol";

interface IRevealFarmer {
	function getInternalTokenId(uint256 tokenId)
		external
		view
		returns (uint256 internalTokenId);

	function isRevealed(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

interface IPotato {
	function mintReward(
		uint8 rewardType,
		address recipient,
		uint256 amount
	) external;

	function mintAsDelegate(
		address recipient,
		uint256 amount,
		string memory reason
	) external;

	function emergencyFreeze() external;

	function unfreeze() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}