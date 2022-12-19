// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/ITheFarmV2.sol";
import "./interfaces/IRegistryFarmerV2.sol";
import "./interfaces/IPotato.sol";
import "../v3/PotatoChip/interfaces/IPotatoChip.sol";

// Collections
import "./interfaces/IHonestFarmerClubV2.sol";
import "./interfaces/IRevealFarmer.sol";
import "./interfaces/IMetaFarmer.sol";
import "./FarmGirls/interfaces/IFarmGirlsERC1155.sol";
import "./interfaces/IHonestFarmerClubV2.sol";

struct Stake {
	address depositor;
	uint256 depositBlock;
	uint256 lockingDurationEpochs;
	uint256 claimedBlocks;
}

contract TheFarmV4 is
	ITheFarmV2,
	RegistryFarmerV2Consumer,
	OwnableUpgradeable,
	ERC1155HolderUpgradeable
{
	uint256 public epochBlocks;
	mapping(Character => uint256) potatoPerEpochByCharacter; // Character => uint256
	mapping(Character => mapping(uint256 => Stake))
		public stakeByCharacterByCharacterId; // Character => CharacterId => Stake
	mapping(uint256 => uint256)
		public multipliersBasisPointsByLockingDurationEpochs; // LockingDurationInDays => Multiplier in Basispoints

	// Delegation
	mapping(address => bool) isDelegateByAddress; // Address => bool

	// v3 variables
	uint256 public rewardTax;
	address public taxTreasury;

	//Mega Release Update
	mapping(Character => mapping(uint256 => Stake)) stakeByCharacterByCharacterIdV2;

	function initialize(address _registryFarmerV2) public initializer {
		__Ownable_init();
		__ERC1155Holder_init();

		epochBlocks = 432; // ~15 minutes, with blocktime @2s
		potatoPerEpochByCharacter[Character.HONEST_FARMER] = 10**17; // 0.1 $POTATO
		potatoPerEpochByCharacter[Character.HONEST_FARMER] = 10**16 * 5; // 0.05 $POTATO

		multipliersBasisPointsByLockingDurationEpochs[0] = 100;
		multipliersBasisPointsByLockingDurationEpochs[100 * 50] = 120;
		multipliersBasisPointsByLockingDurationEpochs[100 * 100] = 150;

		_setRegistryFarmer(_registryFarmerV2);
	}

	modifier onlyDepositor(Character character, uint256 characterId) {
		address depositor = getDepositor(character, characterId);

		require(
			depositor == msg.sender,
			"Only depositor is allowed to perform this action"
		);
		_;
	}

	modifier onlyDepositorV2(Character character, uint256 characterId) {
		//changed to getDepositorV2
		address depositor = getDepositorV2(character, characterId);

		require(
			depositor == msg.sender,
			"Only V2 depositor is allowed to perform this action"
		);
		_;
	}

	modifier isUnlockedCharacter(Character character, uint256 characterId) {
		Stake memory stake = stakeByCharacterByCharacterId[character][
			characterId
		];

		uint256 unlockBlock = stake.depositBlock +
			stake.lockingDurationEpochs *
			epochBlocks;

		require(block.number >= unlockBlock, "Character is locked");
		_;
	}

	function stakeCharacter(
		Character character,
		uint256 characterId,
		uint256 lockingDurationEpochs
	) public {
		Stake memory stake = Stake(
			msg.sender,
			block.number,
			lockingDurationEpochs,
			0
		);

		stakeByCharacterByCharacterIdV2[character][characterId] = stake;
		_transferCharacter(character, characterId, msg.sender, address(this));

		emit StakeCharacter(character, characterId, lockingDurationEpochs);
	}

	function stakeCharacterBatch(
		Character[] memory characters,
		uint256[] memory characterIds,
		uint256[] memory lockingDurationEpochs
	) public {
		for (uint256 i = 0; i < characters.length; i++) {
			stakeCharacter(
				characters[i],
				characterIds[i],
				lockingDurationEpochs[i]
			);
		}
	}

	//Mint Staking

	function _mintStakingReward(address recipient, uint256 amount) private {
		IPotato potato = IPotato(_getRegistryFarmer().getContract("Potato"));
		potato.mintAsDelegate(recipient, amount, "Staking");
	}

	function _claimEpochs(Character character, uint256 characterId) private {
		require(
			isStaked(character, characterId),
			"The Farm :: Character not staked!"
		);
		(uint256 claimableEpochs, uint256 claimableBlocks) = getClaimableEpochs(
			character,
			characterId
		);
		// Calculate reward
		uint256 lockingDurationEpochs = stakeByCharacterByCharacterId[
			character
		][characterId].lockingDurationEpochs;
		uint256 baseRewardPotato = claimableEpochs *
			potatoPerEpochByCharacter[character];

		uint256 multiplierBasisPoints = multipliersBasisPointsByLockingDurationEpochs[
				lockingDurationEpochs
			];
		uint256 boostedRewardPotato = (baseRewardPotato *
			multiplierBasisPoints) / 100;

		// v3 :: tax implementation
		uint256 divisor = 1000;
		if (rewardTax > 999) divisor = 10000;
		uint256 rewardPotatoTax = (boostedRewardPotato * rewardTax) / divisor;
		uint256 totalRewardPotato = boostedRewardPotato - rewardPotatoTax;

		// Mint reward
		if (boostedRewardPotato > 0) {
			_mintStakingReward(msg.sender, totalRewardPotato);
			_mintStakingReward(taxTreasury, rewardPotatoTax);

			emit MintStakingReward(character, characterId, totalRewardPotato);
		}

		//  Update stake
		stakeByCharacterByCharacterId[character][characterId]
			.claimedBlocks += claimableBlocks;
	}

	function claimEpochs(Character character, uint256 characterId)
		public
		onlyDepositor(character, characterId)
	{
		_claimEpochs(character, characterId);
	}

	function claimEpochsBatch(
		Character[] memory characters,
		uint256[] memory characterIds
	) public {
		for (uint256 i = 0; i < characters.length; i++) {
			claimEpochs(characters[i], characterIds[i]);
		}
	}

	function _withdrawCharacter(Character character, uint256 characterId)
		private
	{
		_claimEpochs(character, characterId);
		delete stakeByCharacterByCharacterId[character][characterId];

		_transferCharacter(character, characterId, address(this), msg.sender);
		emit WithdrawCharacter(character, characterId);
	}

	function withdrawCharacter(Character character, uint256 characterId)
		public
		onlyDepositor(character, characterId)
		isUnlockedCharacter(character, characterId)
	{
		_withdrawCharacter(character, characterId);
	}

	function withdrawCharacterBatch(
		Character[] memory characters,
		uint256[] memory characterIds
	) public {
		for (uint256 i = 0; i < characters.length; i++) {
			withdrawCharacter(characters[i], characterIds[i]);
		}
	}

	/**
	 * Mega Release Update
	 */
	function _mintStakingPotatoChipReward(address recipient, uint256 amount)
		private
	{
		IPotatoChip potato = IPotatoChip(
			_getRegistryFarmer().getContract("PotatoChip")
		);
		potato.mintAsDelegate(recipient, amount, "Staking");
	}

	function _claimEpochsV2(Character character, uint256 characterId) private {
		//Added require
		require(
			isStakedV2(character, characterId),
			"The Farm :: Character not staked!"
		);
		(
			uint256 claimableEpochs,
			uint256 claimableBlocks
		) = getClaimableEpochsV2(character, characterId);

		// Calculate reward
		uint256 lockingDurationEpochs = stakeByCharacterByCharacterIdV2[
			character
		][characterId].lockingDurationEpochs;
		uint256 baseRewardPotato = claimableEpochs *
			potatoPerEpochByCharacter[character];

		uint256 multiplierBasisPoints = multipliersBasisPointsByLockingDurationEpochs[
				lockingDurationEpochs
			];
		uint256 boostedRewardPotato = (baseRewardPotato *
			multiplierBasisPoints) / 100;

		// v3 :: tax implementation
		uint256 divisor = 1000;
		if (rewardTax > 999) divisor = 10000;
		uint256 rewardPotatoTax = (boostedRewardPotato * rewardTax) / divisor;
		uint256 totalRewardPotato = boostedRewardPotato - rewardPotatoTax;

		// Mint reward
		if (boostedRewardPotato > 0) {
			_mintStakingPotatoChipReward(msg.sender, totalRewardPotato);
			_mintStakingPotatoChipReward(taxTreasury, rewardPotatoTax);

			emit MintStakingReward(character, characterId, totalRewardPotato);
		}

		//  Update stake
		stakeByCharacterByCharacterIdV2[character][characterId]
			.claimedBlocks += claimableBlocks;
	}

	function claimEpochsV2(Character character, uint256 characterId)
		public
		onlyDepositorV2(character, characterId)
	{
		_claimEpochsV2(character, characterId);
	}

	function claimEpochsBatchV2(
		Character[] memory characters,
		uint256[] memory characterIds
	) public {
		for (uint256 i = 0; i < characters.length; i++) {
			claimEpochsV2(characters[i], characterIds[i]);
		}
	}

	function _withdrawCharacterV2(Character character, uint256 characterId)
		private
	{
		_claimEpochsV2(character, characterId);
		delete stakeByCharacterByCharacterIdV2[character][characterId];

		_transferCharacter(character, characterId, address(this), msg.sender);
		emit WithdrawCharacter(character, characterId);
	}

	function withdrawCharacterV2(Character character, uint256 characterId)
		public
		onlyDepositorV2(character, characterId)
		isUnlockedCharacter(character, characterId)
	{
		//Changed to v2
		_withdrawCharacterV2(character, characterId);
	}

	function withdrawCharacterBatchV2(
		Character[] memory characters,
		uint256[] memory characterIds
	) public {
		for (uint256 i = 0; i < characters.length; i++) {
			withdrawCharacterV2(characters[i], characterIds[i]);
		}
	}

	// Administrative
	function emergencyWithdrawCharacter(
		Character character,
		uint256 characterId
	) public onlyOwner {
		_withdrawCharacter(character, characterId);
	}

	function setEpochBlocks(uint256 _epochBlocks) public onlyOwner {
		epochBlocks = _epochBlocks;
	}

	function setPotatoPerEpoch(Character character, uint256 _potatoPerEpoch)
		public
		onlyOwner
	{
		potatoPerEpochByCharacter[character] = _potatoPerEpoch;
	}

	function setRegistryFarmer(address _registryFarmerV2)
		public
		override
		onlyOwner
	{
		_setRegistryFarmer(_registryFarmerV2);
	}

	function setRewardTax(uint256 _rewardTax) external onlyOwner {
		rewardTax = _rewardTax;
	}

	function setTaxTreasury(address _taxTreasury) external onlyOwner {
		taxTreasury = _taxTreasury;
	}

	// Views
	function isStaked(Character character, uint256 characterId)
		public
		view
		returns (bool)
	{
		Stake memory stake = stakeByCharacterByCharacterId[character][
			characterId
		];

		return stake.depositor != address(0);
	}

	function isStakedBatch(
		Character[] memory characters,
		uint256[] memory characterIds
	) public view returns (bool[] memory) {
		bool[] memory result = new bool[](characters.length);

		for (uint256 i = 0; i < characters.length; i++) {
			result[i] = isStaked(characters[i], characterIds[i]);
		}

		return result;
	}

	//Mega Release
	function isStakedV2(Character character, uint256 characterId)
		public
		view
		returns (bool)
	{
		Stake memory stake = stakeByCharacterByCharacterIdV2[character][
			characterId
		];

		return stake.depositor != address(0);
	}

	function isStakedBatchV2(
		Character[] memory characters,
		uint256[] memory characterIds
	) public view returns (bool[] memory) {
		bool[] memory result = new bool[](characters.length);

		for (uint256 i = 0; i < characters.length; i++) {
			result[i] = isStakedV2(characters[i], characterIds[i]);
		}

		return result;
	}

	function isUnlocked(Character character, uint256 characterId)
		public
		view
		returns (bool _isUnlocked, uint256 _lockingDurationEpochs)
	{
		Stake memory stake = stakeByCharacterByCharacterIdV2[character][
			characterId
		];

		uint256 unlockBlock = stake.depositBlock +
			stake.lockingDurationEpochs *
			epochBlocks;

		return (block.number >= unlockBlock, stake.lockingDurationEpochs);
	}

	function isUnlockedBatch(
		Character[] memory characters,
		uint256[] memory characterIds
	)
		public
		view
		returns (
			bool[] memory _isUnlocked,
			uint256[] memory _lockingDurationEpochs
		)
	{
		bool[] memory resultIsUnlocked = new bool[](characters.length);
		uint256[] memory resultLockingDurationEpochs = new uint256[](
			characters.length
		);

		for (uint256 i = 0; i < characters.length; i++) {
			(
				bool _isUnlockedCharacter,
				uint256 _lockingDurationEpochsForCharacter
			) = isUnlocked(characters[i], characterIds[i]);

			resultIsUnlocked[i] = _isUnlockedCharacter;
			resultLockingDurationEpochs[i] = _lockingDurationEpochsForCharacter;
		}

		return (resultIsUnlocked, resultLockingDurationEpochs);
	}

	function getDepositor(Character character, uint256 characterId)
		public
		view
		returns (address _depositor)
	{
		Stake memory stake = stakeByCharacterByCharacterId[character][
			characterId
		];

		return stake.depositor;
	}

	function getDepositorBatch(
		Character[] memory characters,
		uint256[] memory characterIds
	) public view returns (address[] memory _depositors) {
		address[] memory result = new address[](characters.length);

		for (uint256 i = 0; i < characters.length; i++) {
			result[i] = getDepositor(characters[i], characterIds[i]);
		}

		return result;
	}

	function getClaimableEpochs(Character character, uint256 characterId)
		public
		view
		returns (uint256 _claimableEpochs, uint256 _claimableBlocks)
	{
		Stake memory stake = stakeByCharacterByCharacterId[character][
			characterId
		];
		uint256 blocksSinceDeposit = block.number - stake.depositBlock;
		uint256 prevClaimedBlocks = stake.claimedBlocks;
		uint256 unclaimedBlocks = blocksSinceDeposit - prevClaimedBlocks;

		uint256 claimableEpochs = unclaimedBlocks / epochBlocks;
		uint256 claimableBlocks = claimableEpochs * epochBlocks;

		return (claimableEpochs, claimableBlocks);
	}

	function getClaimableEpochsBatch(
		Character[] memory characters,
		uint256[] memory characterIds
	)
		public
		view
		returns (
			uint256[] memory _claimableEpochs,
			uint256[] memory _claimableBlocks
		)
	{
		uint256[] memory resultClaimableEpochs = new uint256[](
			characters.length
		);
		uint256[] memory resultClaimableBlocks = new uint256[](
			characters.length
		);

		for (uint256 i = 0; i < characters.length; i++) {
			(
				uint256 _claimableEpochsForCharacter,
				uint256 _claimableBlocksForCharacter
			) = getClaimableEpochs(characters[i], characterIds[i]);

			resultClaimableEpochs[i] = _claimableEpochsForCharacter;
			resultClaimableBlocks[i] = _claimableBlocksForCharacter;
		}

		return (resultClaimableEpochs, resultClaimableBlocks);
	}

	//Mega Release Update
	function getDepositorV2(Character character, uint256 characterId)
		public
		view
		returns (address _depositor)
	{
		Stake memory stake = stakeByCharacterByCharacterIdV2[character][
			characterId
		];

		return stake.depositor;
	}

	function getDepositorBatchV2(
		Character[] memory characters,
		uint256[] memory characterIds
	) public view returns (address[] memory _depositors) {
		address[] memory result = new address[](characters.length);

		for (uint256 i = 0; i < characters.length; i++) {
			result[i] = getDepositorV2(characters[i], characterIds[i]);
		}

		return result;
	}

	function getClaimableEpochsV2(Character character, uint256 characterId)
		public
		view
		returns (uint256 _claimableEpochs, uint256 _claimableBlocks)
	{
		Stake memory stake = stakeByCharacterByCharacterIdV2[character][
			characterId
		];
		uint256 blocksSinceDeposit = block.number - stake.depositBlock;
		uint256 prevClaimedBlocks = stake.claimedBlocks;
		uint256 unclaimedBlocks = blocksSinceDeposit - prevClaimedBlocks;

		uint256 claimableEpochs = unclaimedBlocks / epochBlocks;
		uint256 claimableBlocks = claimableEpochs * epochBlocks;

		return (claimableEpochs, claimableBlocks);
	}

	function getClaimableEpochsBatchV2(
		Character[] memory characters,
		uint256[] memory characterIds
	)
		public
		view
		returns (
			uint256[] memory _claimableEpochs,
			uint256[] memory _claimableBlocks
		)
	{
		uint256[] memory resultClaimableEpochs = new uint256[](
			characters.length
		);
		uint256[] memory resultClaimableBlocks = new uint256[](
			characters.length
		);

		for (uint256 i = 0; i < characters.length; i++) {
			(
				uint256 _claimableEpochsForCharacter,
				uint256 _claimableBlocksForCharacter
			) = getClaimableEpochsV2(characters[i], characterIds[i]);

			resultClaimableEpochs[i] = _claimableEpochsForCharacter;
			resultClaimableBlocks[i] = _claimableBlocksForCharacter;
		}

		return (resultClaimableEpochs, resultClaimableBlocks);
	}

	// Utils
	function _transferFarmer(
		uint256 characterId,
		address from,
		address to
	) private {
		IHonestFarmerClubV2 farmerNft = IHonestFarmerClubV2(
			_getRegistryFarmer().getContract("HonestFarmerClub")
		);

		farmerNft.safeTransferFrom(from, to, characterId, 1, "");
	}

	function _transferFarmGirl(
		uint256 characterId,
		address from,
		address to
	) private {
		IFarmGirls farmGirls = IFarmGirls(
			_getRegistryFarmer().getContract("FarmGirls")
		);

		farmGirls.safeTransferFrom(from, to, characterId, 1, "");
	}

	function _transferCharacter(
		Character character,
		uint256 characterId,
		address from,
		address to
	) private {
		if (character == Character.HONEST_FARMER) {
			_transferFarmer(characterId, from, to);
		} else if (character == Character.FARM_GIRL) {
			_transferFarmGirl(characterId, from, to);
		} else {
			revert("Character not supported yet");
		}
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
pragma solidity ^0.8.13;

enum Character {
	HONEST_FARMER,
	FARM_GIRL
}

interface ITheFarmV2 {
	function stakeCharacter(
		Character character,
		uint256 characterId,
		uint256 lockingDurationEpochs
	) external;

	function stakeCharacterBatch(
		Character[] memory characters,
		uint256[] memory characterIds,
		uint256[] memory lockingDurationEpochs
	) external;

	function claimEpochs(Character character, uint256 characterId) external;

	function claimEpochsBatch(
		Character[] memory characters,
		uint256[] memory characterIds
	) external;

	function withdrawCharacter(Character character, uint256 characterId)
		external;

	function withdrawCharacterBatch(
		Character[] memory characters,
		uint256[] memory characterIds
	) external;

	// Administrative
	function emergencyWithdrawCharacter(
		Character character,
		uint256 characterId
	) external;

	function setEpochBlocks(uint256 _epochBlocks) external;

	function setPotatoPerEpoch(Character character, uint256 _potatoPerEpoch)
		external;

	// Views

	function isStaked(Character character, uint256 characterId)
		external
		view
		returns (bool);

	function isStakedBatch(
		Character[] memory characters,
		uint256[] memory characterIds
	) external view returns (bool[] memory);

	function isUnlocked(Character character, uint256 characterId)
		external
		view
		returns (bool _isUnlocked, uint256 _lockingDurationEpochs);

	function isUnlockedBatch(
		Character[] memory character,
		uint256[] memory characterId
	)
		external
		view
		returns (
			bool[] memory _isUnlocked,
			uint256[] memory _lockingDurationEpochs
		);

	function getDepositor(Character character, uint256 characterId)
		external
		view
		returns (address _depositor);

	function getDepositorBatch(
		Character[] memory characters,
		uint256[] memory characterIds
	) external view returns (address[] memory _depositors);

	function getDepositorV2(Character character, uint256 characterId)
		external
		view
		returns (address _depositor);

	function getDepositorBatchV2(
		Character[] memory characters,
		uint256[] memory characterIds
	) external view returns (address[] memory _depositors);

	function getClaimableEpochs(Character character, uint256 characterId)
		external
		view
		returns (uint256 _claimableEpochs, uint256 _claimableBlocks);

	function getClaimableEpochsBatch(
		Character[] memory characters,
		uint256[] memory characterIds
	)
		external
		view
		returns (
			uint256[] memory _claimableEpochs,
			uint256[] memory _claimableBlocks
		);

	// Events
	event StakeCharacter(
		Character indexed character,
		uint256 indexed characterId,
		uint256 lockingDurationEpochs
	);

	event MintStakingReward(
		Character indexed character,
		uint256 indexed characterId,
		uint256 potato
	);

	event WithdrawCharacter(Character character, uint256 characterId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IRegistryFarmerV2 {
	function setContract(string memory contractName, address _address) external;

	function getContract(string memory contractName)
		external
		view
		returns (address);

	event SetContract(string contractName, address indexed _address);
}

abstract contract RegistryFarmerV2Consumer {
	address public registryFarmerV2;

	function _setRegistryFarmer(address _registryFarmerV2) internal {
		registryFarmerV2 = _registryFarmerV2;
	}

	function _getRegistryFarmer() internal view returns (IRegistryFarmerV2) {
		return IRegistryFarmerV2(registryFarmerV2);
	}

	function setRegistryFarmer(address _registryFarmerV2) public virtual;
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
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

interface IPotatoChip {
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
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";

import "../libraries/LibraryFarmer.sol";

interface IHonestFarmerClubV2 is IERC1155 {
	function mintFarmers(uint256 numberOfHonestFarmers) external payable;

	function mintWhitelistFarmers(uint256 numberOfHonestFarmers)
		external
		payable;

	function mintFreeFarmers() external;

	function migrateFarmers(address to, uint256[] memory ids) external;

	function setMintPrices(
		uint256 _mintPriceMATIC,
		uint256 _mintPriceMATICWhitelist
	) external;

	function toggleMint(LibraryFarmer.MintType mintType) external;

	function numberOfPostMigrationFarmersMinted()
		external
		view
		returns (uint256);

	function tokenCount() external view returns (uint256);

	function MAX_FARMER_SUPPLY() external view returns (uint256);
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
pragma solidity ^0.8.11;

interface IMetaFarmer {
	function uri(uint256 internalTokenId) external view returns (string memory);

	function isSpecialByInternalTokenId(uint256 internalTokenId)
		external
		view
		returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";

interface IFarmGirls is IERC1155 {
	function mintWeddingRing(
		uint256 numberOfWeddingRings,
		uint256 husbandId,
		uint256 bestManId
	) external;

	function breedFarmGirls(uint256 numberOfFarmGirls) external;

	function uriBatch(uint256[] memory ids)
		external
		view
		returns (string[] memory _uris);

	function setBreedingIsLive(bool _breedingIsLive) external;

	function setWeddingRingCost(uint256 potato) external;

	event MintWeddingRings(
		address indexed minter,
		uint256 indexed husbandId,
		uint256 indexed bestManId,
		uint256 numberOfWeddingRings,
		uint256 totalPotatoCost
	);

	event BreedFarmGirl(address indexed minter, uint256 indexed farmGirlId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

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