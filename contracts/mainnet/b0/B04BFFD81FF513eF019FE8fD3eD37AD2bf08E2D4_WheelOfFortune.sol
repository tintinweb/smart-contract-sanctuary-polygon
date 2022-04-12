// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./interfaces/IWheelOfFortune.sol";
import "./interfaces/IRandomnessFarmer.sol";
import "./libraries/GameLibrary.sol";
import "../interfaces/IRegistryFarmerV2.sol";
import "../interfaces/IPotatoBurnable.sol";
import "../interfaces/IHonestFarmerClubV2.sol";

contract WheelOfFortune is
	IWheelOfFortune,
	RegistryFarmerV2Consumer,
	OwnableUpgradeable
{
	using GameLibrary for GameLibrary.Wheel;
	using GameLibrary for GameLibrary.Wager;
	using CountersUpgradeable for CountersUpgradeable.Counter;

	uint256 public minWagerAmountPotato;
	mapping(address => uint256) public lastFreeSpinByAccount; // Account => BlockNumber
	mapping(uint256 => uint256) public lastFreeSpinByFarmerId; // FarmerId => BlockNumber
	uint256 public freeSpinCooldownBlocks;

	mapping(uint256 => GameLibrary.Wheel) public wheelByWheelId; // WheelId => Wheel
	mapping(address => mapping(uint256 => GameLibrary.Wager))
		public lastWagerByAccountByWheelId; // Account => WheelId => WagerId

	CountersUpgradeable.Counter private wagerIdCounter;

	function initialize(address _registryFarmerV2) public initializer {
		_setRegistryFarmer(_registryFarmerV2);
	}

	modifier hasSufficientFreeSpinCooldown(uint256 farmerId) {
		uint256 lastFreeSpinBlockNumberForAccount = lastFreeSpinByAccount[
			msg.sender
		];
		uint256 blocksSinceLastFreeSpinForAccount = block.number -
			lastFreeSpinBlockNumberForAccount;
		require(
			blocksSinceLastFreeSpinForAccount >= freeSpinCooldownBlocks,
			"Free spin cooldown period for account not over yet"
		);

		uint256 lastFreeSpinBlockNumberForFarmer = lastFreeSpinByFarmerId[
			farmerId
		];
		uint256 blocksSinceLastFreeSpinForCharacter = block.number -
			lastFreeSpinBlockNumberForFarmer;
		require(
			blocksSinceLastFreeSpinForCharacter >= freeSpinCooldownBlocks,
			"Free spin cooldown period for character not over yet"
		);
		_;
	}

	modifier onlyValidPaidSpins(uint256 wheelId, uint256 wagerAmountPotato) {
		GameLibrary.Wheel memory wheel = wheelByWheelId[wheelId];
		GameLibrary.Wager memory lastWager = lastWagerByAccountByWheelId[
			msg.sender
		][wheelId];

		// Check min wager amount
		require(
			wagerAmountPotato >= minWagerAmountPotato,
			"Wager amount is too low"
		);
		// Check max wager amount
		require(
			wagerAmountPotato <= wheel.maxWagerAmountPotato,
			"Wager amount is too high"
		);

		// Check if wheel is active
		require(wheel.isActive, "Wheel is not active");

		// Check if wheel is non-free
		require(
			wheelId > 0,
			"Only non-free wheels can be spinned using this function"
		);

		// Check wheel cooldown
		uint256 lastSpinBlocktime = lastWager.blockNumber;
		uint256 blocksSinceLastSpin = block.number - lastSpinBlocktime;
		require(
			blocksSinceLastSpin >= wheel.cooldownBlocks,
			"Cooldown period not over yet"
		);

		// Check if previous wagers are determined
		(bool wagerOutcomeIsDetermined, uint256 wagerPayoff) = getWagerOutcome(
			msg.sender,
			wheelId
		);
		require(
			wagerOutcomeIsDetermined,
			"Last wager outcome for this wheel is not yet determined"
		);

		// Check if previous wager has unclaimed rewards
		bool hasRewardsToClaim = wagerPayoff > 0 && !lastWager.isClaimed;
		require(
			!hasRewardsToClaim,
			"Prevous winning wager payoffs need to be claimed"
		);

		_;
	}

	modifier onlyBettor(uint256 wheelId) {
		GameLibrary.Wager memory wager = lastWagerByAccountByWheelId[
			msg.sender
		][wheelId];

		require(
			msg.sender == wager.account,
			"Only bettor is allowed to call this function"
		);
		_;
	}

	modifier onlyFarmerHolder(uint256 farmerId) {
		IHonestFarmerClubV2 honestFarmerClub = IHonestFarmerClubV2(
			_getRegistryFarmer().getContract("HonestFarmerClub")
		);
		bool isHolder = honestFarmerClub.balanceOf(msg.sender, farmerId) == 1;

		require(isHolder, "Only holder is allowed to call this function");
		_;
	}

	function _requestRandomness()
		private
		returns (bytes32 _randomnessRequestId)
	{
		IRandomnessFarmer randomnessFarmer = IRandomnessFarmer(
			_getRegistryFarmer().getContract("RandomnessFarmer")
		);

		bytes32 requestId = randomnessFarmer.getRandomNumber();
		return requestId;
	}

	function _createWager(uint256 wheelId, uint256 wagerAmountPotato) private {
		// Generate wagerId
		wagerIdCounter.increment();
		uint256 wagerId = wagerIdCounter.current();

		// Request randomness from RandomnessFarmer
		bytes32 randomnessRequestId = _requestRandomness();

		// Save wager to state
		GameLibrary.Wager memory wager = GameLibrary.Wager(
			wagerId,
			wheelId,
			block.number,
			msg.sender,
			wagerAmountPotato,
			randomnessRequestId,
			false
		);
		lastWagerByAccountByWheelId[msg.sender][wheelId] = wager;

		emit SpinWheel(
			wagerId,
			wheelId,
			msg.sender,
			wagerAmountPotato,
			randomnessRequestId
		);
	}

	function _burnPotato(uint256 amount) private {
		IPotato potato = IPotato(_getRegistryFarmer().getContract("Potato"));
		potato.burnFrom(msg.sender, amount);
	}

	function spinFreeWheel(uint256 farmerId)
		public
		onlyFarmerHolder(farmerId)
		hasSufficientFreeSpinCooldown(farmerId)
	{
		_createWager(0, 0);
		lastFreeSpinByAccount[msg.sender] = block.number;
		lastFreeSpinByFarmerId[farmerId] = block.number;
	}

	function spinWheel(uint256 wheelId, uint256 wagerAmountPotato)
		public
		onlyValidPaidSpins(wheelId, wagerAmountPotato)
	{
		_burnPotato(wagerAmountPotato);
		_createWager(wheelId, wagerAmountPotato);
	}

	function claimReward(uint256 wheelId) public onlyBettor(wheelId) {
		GameLibrary.Wager memory lastWager = lastWagerByAccountByWheelId[
			msg.sender
		][wheelId];

		(bool wagerOutcomeIsDetermined, uint256 wagerPayoff) = getWagerOutcome(
			msg.sender,
			wheelId
		);
		require(wagerOutcomeIsDetermined, "Last wager is not yet determined");
		require(wagerPayoff > 0, "Wager does not have rewards to claim");
		require(!lastWager.isClaimed, "Wager already claimed");

		IPotato potato = IPotato(_getRegistryFarmer().getContract("Potato"));
		potato.mintAsDelegate(msg.sender, wagerPayoff, "WheelOfFortune");

		// Save claim to state
		lastWagerByAccountByWheelId[msg.sender][wheelId].isClaimed = true;

		emit ClaimWagerReward(
			lastWager.id,
			wheelId,
			msg.sender,
			wagerPayoff,
			lastWager.randomnessRequestId
		);
	}

	function claimRewardBatch(uint256[] memory wheelIds) public {
		for (uint256 i = 0; i < wheelIds.length; i++) {
			uint256 wheelId = wheelIds[i];
			claimReward(wheelId);
		}
	}

	// Views
	function isLive(uint256 wheelId) public view returns (bool _isLive) {
		GameLibrary.Wheel memory wheel = wheelByWheelId[wheelId];
		return wheel.isActive;
	}

	function isLiveBatch(uint256[] memory wheelIds)
		external
		view
		returns (bool[] memory _isLive)
	{
		bool[] memory _isLiveBatch = new bool[](wheelIds.length);
		for (uint256 i = 0; i < wheelIds.length; i++) {
			_isLiveBatch[i] = isLive(wheelIds[i]);
		}
		return _isLiveBatch;
	}

	function _getWagerRandomness(bytes32 randomnessRequestId)
		private
		view
		returns (uint256 _randomness)
	{
		IRandomnessFarmer randomnessFarmer = IRandomnessFarmer(
			_getRegistryFarmer().getContract("RandomnessFarmer")
		);
		uint256 randomness = randomnessFarmer.getRandomness(
			randomnessRequestId
		);

		return randomness;
	}

	function _getWagerOutcome(
		GameLibrary.Wheel memory wheel,
		GameLibrary.Wager memory wager
	) private view returns (bool _isDetermined, uint256 _wagerPayoffPotato) {
		uint256 randomness = _getWagerRandomness(wager.randomnessRequestId);
		if (randomness == 0) return (false, 0);

		uint256 n = randomness % 100;
		bool isWon = n < wheel.winChanceBasisPoints; // < instead of <=, because 0 is also a winning number
		if (!isWon) return (true, 0);

		// Free wheel
		if (wheel.id == 0) return (true, 10 * 10**18);

		// Non-free wheels
		uint256 wagerPayoffPotato = (wager.wagerPotato *
			wheel.rewardMultiplierBasisPoints) / 100;
		return (true, wagerPayoffPotato);
	}

	function getWagerOutcome(address account, uint256 wheelId)
		public
		view
		returns (bool _isDetermined, uint256 _wagerPayoffPotato)
	{
		GameLibrary.Wheel memory wheel = wheelByWheelId[wheelId];
		GameLibrary.Wager memory wager = lastWagerByAccountByWheelId[account][
			wheelId
		];

		return _getWagerOutcome(wheel, wager);
	}

	function getWagerOutcomeBatch(
		address[] memory accounts,
		uint256[] memory wheelIds
	)
		public
		view
		returns (
			bool[] memory _isDetermined,
			uint256[] memory _wagerPayoffPotato
		)
	{
		bool[] memory _isDeterminedBatch = new bool[](accounts.length);
		uint256[] memory _wagerPayoffPotatoBatch = new uint256[](
			accounts.length
		);
		for (uint256 i = 0; i < accounts.length; i++) {
			(bool isDetermined, uint256 wagerPayoffPotato) = getWagerOutcome(
				accounts[i],
				wheelIds[i]
			);

			_isDeterminedBatch[i] = isDetermined;
			_wagerPayoffPotatoBatch[i] = wagerPayoffPotato;
		}

		return (_isDeterminedBatch, _wagerPayoffPotatoBatch);
	}

	// Administrative
	function setWheel(GameLibrary.Wheel memory wheel) public onlyOwner {
		require(wheel.id > 0, "Cannot override free spin wheel");
		wheelByWheelId[wheel.id] = wheel;

		emit SetWheel(
			wheel.id,
			wheel.rewardMultiplierBasisPoints,
			wheel.maxWagerAmountPotato,
			wheel.winChanceBasisPoints,
			wheel.cooldownBlocks,
			wheel.isActive
		);
	}

	function setMinWagerAmountPotato(uint256 _minWagerAmountPotato)
		public
		onlyOwner
	{
		minWagerAmountPotato = _minWagerAmountPotato;
	}

	function setFreeSpinCooldown(uint256 _freeSpinCooldownBlocks)
		public
		onlyOwner
	{
		freeSpinCooldownBlocks = _freeSpinCooldownBlocks;
	}

	function removeWheel(uint256 wheelId) public onlyOwner {
		delete (wheelByWheelId[wheelId]);
	}

	function withdrawToken(address _token) public onlyOwner {
		IERC20 token = IERC20(_token);
		uint256 balance = token.balanceOf(address(this));

		token.approve(address(this), balance);
		token.transferFrom(address(this), msg.sender, balance);
	}

	function setRegistryFarmer(address _registryFarmerV2)
		public
		override
		onlyOwner
	{
		_setRegistryFarmer(_registryFarmerV2);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../libraries/GameLibrary.sol";

enum Character {
	HONEST_FARMER,
	FARM_GIRL
}

interface IWheelOfFortune {
	function spinFreeWheel(uint256 farmerId) external;

	function spinWheel(uint256 wheelId, uint256 wagerAmountPotato) external;

	function claimReward(uint256 wheelId) external;

	function setWheel(GameLibrary.Wheel memory wheel) external;

	function removeWheel(uint256 wheelId) external;

	function withdrawToken(address _token) external;

	// Views
	function getWagerOutcome(address account, uint256 wheelId)
		external
		view
		returns (bool _isDetermined, uint256 _wagerPayoffPotato);

	function getWagerOutcomeBatch(
		address[] memory accounts,
		uint256[] memory wheelIds
	)
		external
		view
		returns (
			bool[] memory _isDetermined,
			uint256[] memory _wagerPayoffPotato
		);

	function isLive(uint256 wheelId) external view returns (bool _isLive);

	function isLiveBatch(uint256[] memory wheelIds)
		external
		view
		returns (bool[] memory _isLive);

	// Events
	event SetWheel(
		uint256 wheelId,
		uint256 rewardMultiplierBasisPoints,
		uint256 maxWagerAmountPotato,
		uint256 winChanceBasisPoints,
		uint256 cooldownBlocks,
		bool isActive
	);

	event SpinWheel(
		uint256 indexed wagerId,
		uint256 indexed wheelId,
		address indexed account,
		uint256 wagerAmountPotato,
		bytes32 randomnessRequestId
	);

	event ClaimWagerReward(
		uint256 indexed wagerId,
		uint256 indexed wheelId,
		address indexed account,
		uint256 wagerPayoffPotato,
		bytes32 randomnessRequestId
	);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IRandomnessFarmer {
	function getRandomNumber() external returns (bytes32 requestId);

	function getRandomness(bytes32 requestId)
		external
		view
		returns (uint256 randomness);

	function setWhitelist(address account, bool isWhitelisted) external;

	function withdrawToken(address _token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library GameLibrary {
	struct Wheel {
		uint256 id;
		uint256 rewardMultiplierBasisPoints; // in basis points, 1x = 100
		uint256 maxWagerAmountPotato; // in potato, including 10^18 decimals
		uint256 winChanceBasisPoints; // in basis points, 100% = 100
		uint256 cooldownBlocks;
		bool isActive;
	}

	struct Wager {
		uint256 id;
		uint256 wheelId;
		uint256 blockNumber;
		address account;
		uint256 wagerPotato;
		bytes32 randomnessRequestId;
		bool isClaimed;
	}
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

interface IPotato is IERC20Metadata {
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

	function burn(uint256 amount) external;

	function burnFrom(address account, uint256 amount) external;
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