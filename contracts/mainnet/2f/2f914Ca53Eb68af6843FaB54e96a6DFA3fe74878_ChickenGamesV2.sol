// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./interfaces/IChickenGames.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../HonestChickens/interfaces/IMetaChickensV2.sol";
import "./interfaces/IRandomnessFarmer.sol";
import "../interfaces/IRegistryFarmerV2.sol";
import "../interfaces/IPotatoBurnable.sol";

/// @author Howdy Games
/// @title Chicken Games
contract ChickenGamesV2 is
	IChickenGames,
	RegistryFarmerV2Consumer,
	Initializable,
	OwnableUpgradeable
{
	mapping(uint256 => uint256) public lastPlayedTimestampByChickenId;
	mapping(uint256 => uint256) public prevEnergyByChickenId;
	mapping(uint256 => bytes32) public prevRequestIdByChickenId;
	mapping(uint256 => bool) public prevRewardHasBeenClaimed;
	mapping(uint256 => uint256) public rewardBalanceByChickenId;

	uint256 public constant MAX_ENERGY = 12;

	function initialize(address _registryFarmerV2) public initializer {
		__Ownable_init();

		_setRegistryFarmer(_registryFarmerV2);
	}

	modifier onlyChickenOwner(uint256 chickenId) {
		IERC1155 honestChickens = IERC1155(
			_getRegistryFarmer().getContract("HonestChickens")
		);

		require(
			honestChickens.balanceOf(msg.sender, chickenId) == 1,
			"Only chicken holder is allowed to play"
		);
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

	function playChickenGames(uint256 chickenId)
		public
		onlyChickenOwner(chickenId)
	{
		uint256 energy = getChickenEnergy(chickenId);
		require(energy > 0, "Chicken has no energy");

		// Claim previous game reward
		if (
			!prevRewardHasBeenClaimed[chickenId] &&
			lastPlayedTimestampByChickenId[chickenId] > 0
		) {
			claimChickenGameReward(chickenId);
		}

		// Set last played timestamp to the beginning of the last 2 hour sequence
		uint256 currentTimestamp = block.timestamp -
			(block.timestamp % (2 hours));
		lastPlayedTimestampByChickenId[chickenId] = currentTimestamp;

		// Request new randomness
		bytes32 randomnessRequestId = _requestRandomness();
		prevEnergyByChickenId[chickenId] = energy - 1;
		prevRequestIdByChickenId[chickenId] = randomnessRequestId;

		// Record gameplay to boost chicken levels
		IMetaChickensV2(_getRegistryFarmer().getContract("MetaChickens"))
			.recordChickenGame(chickenId);
		prevRewardHasBeenClaimed[chickenId] = false;
	}

	function playChickenGamesAsDelegate(uint256 chickenId) public {
		require(false, "Not yet released");
	}

	function claimChickenGameReward(uint256 chickenId)
		public
		onlyChickenOwner(chickenId)
	{
		(bool isDetermined, uint256 reward) = getGameReward(chickenId);
		require(isDetermined, "Outcome not yet determined");
		if (reward > 0) rewardBalanceByChickenId[chickenId] += reward;
		prevRewardHasBeenClaimed[chickenId] = true;
	}

	function withdrawRewardsBalance(uint256 chickenId)
		public
		onlyChickenOwner(chickenId)
	{
		uint256 balance = rewardBalanceByChickenId[chickenId];
		require(balance > 0, "No rewards available");

		IPotato potato = IPotato(_getRegistryFarmer().getContract("Potato"));
		potato.mintAsDelegate(msg.sender, balance, "ChickenGames");
		rewardBalanceByChickenId[chickenId] = 0;
	}

	// Views
	function getChickenEnergy(uint256 chickenId)
		public
		view
		returns (uint256 _energy)
	{
		uint256 lastPlayedTimestamp = lastPlayedTimestampByChickenId[chickenId];
		uint256 offsetSeconds = block.timestamp - lastPlayedTimestamp;
		uint256 offsetHours = offsetSeconds / 1 hours;

		bool isInitializedChicken = lastPlayedTimestamp > 0;
		uint256 prevEnergy = isInitializedChicken
			? prevEnergyByChickenId[chickenId]
			: MAX_ENERGY;

		uint256 additionalEnergy = offsetHours * 2;
		uint256 newEnergy = (prevEnergy + additionalEnergy) > MAX_ENERGY
			? MAX_ENERGY
			: prevEnergy + additionalEnergy;

		return newEnergy;
	}

	function getWhiteChickenReward(uint256 n)
		public
		pure
		returns (uint256 _potato)
	{
		if (n <= 30) return 0;
		if (n <= 40) return 2 * 20 * 10**16; // 0.2
		if (n <= 50) return 2 * 25 * 10**16; // 0.25
		if (n <= 65) return 2 * 30 * 10**16; // 0.3
		if (n <= 80) return 2 * 40 * 10**16;
		// 0.4
		else return 2 * 50 * 10**16; // 0.5
	}

	function getYellowChickenReward(uint256 n)
		public
		pure
		returns (uint256 _potato)
	{
		if (n <= 28) return 0;
		if (n <= 38) return 2 * 20 * 10**16; // 0.2
		if (n <= 48) return 2 * 25 * 10**16; // 0.25
		if (n <= 64) return 2 * 30 * 10**16; // 0.3
		if (n <= 80) return 2 * 40 * 10**16;
		// 0.4
		else return 2 * 50 * 10**16; // 0.5
	}

	function getGreenChickenReward(uint256 n)
		public
		pure
		returns (uint256 _potato)
	{
		if (n <= 25) return 0;
		if (n <= 35) return 2 * 20 * 10**16; // 0.2
		if (n <= 45) return 2 * 25 * 10**16; // 0.25
		if (n <= 62) return 2 * 30 * 10**16; // 0.3
		if (n <= 79) return 2 * 40 * 10**16;
		// 0.4
		else return 2 * 50 * 10**16; // 0.5
	}

	function getBlueChickenReward(uint256 n)
		public
		pure
		returns (uint256 _potato)
	{
		if (n <= 25) return 0;
		if (n <= 35) return 2 * 20 * 10**16; // 0.2
		if (n <= 45) return 2 * 25 * 10**16; // 0.25
		if (n <= 60) return 2 * 30 * 10**16; // 0.3
		if (n <= 75) return 2 * 40 * 10**16; // 0.4
		if (n <= 95) return 2 * 50 * 10**16;
		// 0.5
		else return 2 * 70 * 10**16; // 0.7
	}

	function getRedChickenReward(uint256 n)
		public
		pure
		returns (uint256 _potato)
	{
		if (n <= 23) return 0;
		if (n <= 33) return 2 * 20 * 10**16; // 0.2
		if (n <= 43) return 2 * 25 * 10**16; // 0.25
		if (n <= 60) return 2 * 30 * 10**16; // 0.3
		if (n <= 75) return 2 * 40 * 10**16; // 0.4
		if (n <= 95) return 2 * 50 * 10**16;
		// 0.5
		else return 2 * 100 * 10**16; // 1.0
	}

	function getPurpleChickenReward(uint256 n)
		public
		pure
		returns (uint256 _potato)
	{
		if (n <= 20) return 0;
		if (n <= 40) return 2 * 20 * 10**16; // 0.2
		if (n <= 50) return 2 * 25 * 10**16; // 0.25
		if (n <= 60) return 2 * 30 * 10**16; // 0.3
		if (n <= 75) return 2 * 40 * 10**16; // 0.4
		if (n <= 90) return 2 * 50 * 10**16;
		// 0.5
		else return 2 * 100 * 10**16; // 1.0
	}

	function getGameReward(uint256 chickenId)
		public
		view
		returns (bool _isDetermined, uint256 _rewardPotato)
	{
		if (prevRewardHasBeenClaimed[chickenId]) return (false, 0);

		CHICKEN_LEVEL_COLOR color = IMetaChickensV2(
			_getRegistryFarmer().getContract("MetaChickens")
		).getColor(chickenId);
		bytes32 randomnessRequestId = prevRequestIdByChickenId[chickenId];

		IRandomnessFarmer randomnessFarmer = IRandomnessFarmer(
			_getRegistryFarmer().getContract("RandomnessFarmer")
		);
		uint256 randomness = randomnessFarmer.getRandomness(
			randomnessRequestId
		);
		if (randomness == 0) return (false, 0);
		uint256 n = randomness % 100;

		if (color == CHICKEN_LEVEL_COLOR.WHITE)
			return (true, getWhiteChickenReward(n));
		if (color == CHICKEN_LEVEL_COLOR.YELLOW)
			return (true, getYellowChickenReward(n));
		if (color == CHICKEN_LEVEL_COLOR.GREEN)
			return (true, getGreenChickenReward(n));
		if (color == CHICKEN_LEVEL_COLOR.BLUE)
			return (true, getBlueChickenReward(n));
		if (color == CHICKEN_LEVEL_COLOR.RED)
			return (true, getRedChickenReward(n));
		if (color == CHICKEN_LEVEL_COLOR.PURPLE)
			return (true, getPurpleChickenReward(n));
	}

	// Administrative
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
pragma solidity ^0.8.14;

interface IChickenGames {
	function playChickenGames(uint256 chickenId) external;

	function playChickenGamesAsDelegate(uint256 chickenId) external;

	function claimChickenGameReward(uint256 chickenId) external;

	function getChickenEnergy(uint256 chickenId)
		external
		view
		returns (uint256 _energy);

	function getGameReward(uint256 chickenId)
		external
		view
		returns (bool _isDetermined, uint256 _rewardPotato);
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
pragma solidity ^0.8.14;

enum CHICKEN_LEVEL_COLOR {
	WHITE,
	YELLOW,
	GREEN,
	BLUE,
	RED,
	PURPLE
}

interface IMetaChickensV2 {
	function uri(uint256 id) external view returns (string memory);

	function setIpfsHashByColor(
		CHICKEN_LEVEL_COLOR color,
		string memory ipfsHash
	) external;

	function recordChickenGame(uint256 id) external;

	function getColor(uint256 chickenId)
		external
		view
		returns (CHICKEN_LEVEL_COLOR color);
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