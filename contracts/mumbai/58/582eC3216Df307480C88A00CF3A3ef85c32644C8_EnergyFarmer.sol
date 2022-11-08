// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IEnergyFarmer.sol";

import "./libraries/LibraryFarmer.sol";

contract EnergyFarmer is IEnergyFarmer, Ownable {
	using LibraryFarmer for LibraryFarmer.Skill;

	event LevelUp(
		uint256 indexed internalTokenId,
		LibraryFarmer.Skill indexed skillId,
		uint256 prevLevel,
		uint256 indexed newLevel
	);
	event IncreaseXP(uint256 indexed internalTokenId, uint256 xpIncrement);

	uint8 public constant MAX_SKILL_LEVEL = 30;
	uint256 public levelUpRequirementMultiplier = 1000;

	mapping(uint256 => mapping(LibraryFarmer.Skill => uint8))
		public skilLevelsByInternalTokenIdBySkill;
	mapping(uint256 => uint256) public xpByInternalTokenId;

	mapping(address => bool) public isDelegateByAddress;

	modifier isValidTokenId(uint256 tokenId) {
		require(tokenId >= 1 && tokenId <= 3000, "Invalid tokenId");
		_;
	}

	modifier onlyDelegates() {
		require(isDelegateByAddress[msg.sender], "Only delegates are allowed");
		_;
	}

	function getLevelUpXPRequirement(uint8 currentLevel)
		public
		view
		returns (uint256)
	{
		require(
			currentLevel >= 1 && currentLevel <= MAX_SKILL_LEVEL,
			"Invalid level"
		);
		return uint256(currentLevel) * levelUpRequirementMultiplier;
	}

	function setLevelUpRequirementMultiplier(uint256 multiplier)
		public
		onlyDelegates
	{
		levelUpRequirementMultiplier = multiplier;
	}

	function getSkillLevel(LibraryFarmer.Skill skillId, uint256 internalTokenId)
		public
		view
		returns (uint8)
	{
		uint8 skillLevel = skilLevelsByInternalTokenIdBySkill[internalTokenId][
			skillId
		];
		return skillLevel > 1 ? skillLevel : 1;
	}

	function increaseXP(uint256 internalTokenId, uint256 xpIncrement)
		public
		isValidTokenId(internalTokenId)
		onlyDelegates
	{
		xpByInternalTokenId[internalTokenId] += xpIncrement;
		emit IncreaseXP(internalTokenId, xpIncrement);
	}

	function levelUp(LibraryFarmer.Skill skillId, uint256 internalTokenId)
		public
		isValidTokenId(internalTokenId)
	{
		uint8 currentLevel = getSkillLevel(skillId, internalTokenId);
		uint256 currentXp = xpByInternalTokenId[internalTokenId];
		uint256 xpRequired = getLevelUpXPRequirement(currentLevel);

		require(currentXp >= xpRequired, "Not enough XP to level up");

		uint8 newLevel = currentLevel == 0 ? 2 : currentLevel + 1;

		xpByInternalTokenId[internalTokenId] -= xpRequired;
		skilLevelsByInternalTokenIdBySkill[internalTokenId][skillId] = newLevel;

		emit LevelUp(internalTokenId, skillId, currentLevel, newLevel);
	}

	function addDelegate(address delegate) public onlyOwner {
		isDelegateByAddress[delegate] = true;
	}

	function removeDelegate(address delegate) public onlyOwner {
		isDelegateByAddress[delegate] = false;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../libraries/LibraryFarmer.sol";

interface IEnergyFarmer {
	function MAX_SKILL_LEVEL() external view returns (uint8);

	function getSkillLevel(LibraryFarmer.Skill skillId, uint256 internalTokenId)
		external
		view
		returns (uint8);

	function increaseXP(uint256 internalTokenId, uint256 xpIncrement) external;

	function levelUp(LibraryFarmer.Skill skillId, uint256 internalTokenId)
		external;
}

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}