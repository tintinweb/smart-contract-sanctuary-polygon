// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IContest.sol";
import "./interfaces/IHub.sol";
import "./libraries/DataTypes.sol";
import "./libraries/Events.sol";
import "./libraries/Errors.sol";

/**
 * Contract to recieve funds from the bet contract and send it to winners.
 */
contract Contest is IContest, OwnableUpgradeable {
    using Counters for Counters.Counter;

    address private _hubAddress;
    Counters.Counter private _counter;
    mapping(uint256 => DataTypes.ContestWave) private _waves;
    mapping(uint256 => DataTypes.ContestWaveParticipant[])
        private _waveParticipants;

    function initialize(address hubAddress) public initializer {
        __Ownable_init();
        _hubAddress = hubAddress;
    }

    function getHubAddress() public view returns (address) {
        return _hubAddress;
    }

    function setHubAddress(address hubAddress) public onlyOwner {
        _hubAddress = hubAddress;
    }

    function startWave(uint endTimestamp, uint winnersNumber) public onlyOwner {
        // Checks
        require(
            _counter.current() == 0 ||
                (_counter.current() != 0 &&
                    _waves[_counter.current()].closeTimestamp != 0),
            Errors.LAST_WAVE_IS_NOT_CLOSED
        );
        // Update counter
        _counter.increment();
        // Create wave
        DataTypes.ContestWave storage wave = _waves[_counter.current()];
        wave.startTimestamp = block.timestamp;
        wave.endTimestamp = endTimestamp;
        wave.winnersNumber = winnersNumber;
        emit Events.ContestWaveCreated(_counter.current(), wave);
    }

    function closeWave(uint id, address[] memory winners) public onlyOwner {
        // Checks
        require(_waves[id].startTimestamp != 0, Errors.WAVE_IS_NOT_STARTED);
        require(_waves[id].closeTimestamp == 0, Errors.WAVE_IS_ALREADY_CLOSED);
        require(
            _waves[id].endTimestamp < block.timestamp,
            Errors.WAVE_END_TIMESTAMP_HAS_NOT_COME
        );
        require(
            winners.length == _waves[id].winnersNumber,
            Errors.NUMBER_OF_WINNERS_IS_INCORRECT
        );
        // Close wave
        DataTypes.ContestWave storage wave = _waves[id];
        wave.closeTimestamp = block.timestamp;
        wave.winning = address(this).balance;
        wave.winners = winners;
        emit Events.ContestWaveClosed(id, wave);
        // Send winnings
        uint winningValue = address(this).balance / wave.winnersNumber;
        for (uint i = 0; i < winners.length; i++) {
            (bool sent, ) = winners[i].call{value: winningValue}("");
            require(sent, Errors.FAILED_TO_SEND_WINNING);
        }
    }

    function getCurrentCounter() public view returns (uint) {
        return _counter.current();
    }

    function getWave(
        uint id
    ) public view returns (DataTypes.ContestWave memory) {
        return _waves[id];
    }

    function getWaveParticipants(
        uint id
    ) public view returns (DataTypes.ContestWaveParticipant[] memory) {
        return _waveParticipants[id];
    }

    /**
     * Update last wave participant by data about closed bet participants.
     */
    function processClosedBetParticipants(
        DataTypes.BetParticipant[] memory betParticipants
    ) public {
        // Checks
        require(
            msg.sender == IHub(_hubAddress).getBetAddress(),
            Errors.ONLY_BET_CONTRACT_CAN_BE_SENDER
        );
        // Get and check last wave
        DataTypes.ContestWave storage wave = _waves[_counter.current()];
        if (
            wave.startTimestamp == 0 ||
            wave.endTimestamp < block.timestamp ||
            wave.closeTimestamp != 0
        ) {
            return;
        }
        // Get last wave participants
        DataTypes.ContestWaveParticipant[]
            storage waveParticipants = _waveParticipants[_counter.current()];
        // Process every bet participant
        for (uint i = 0; i < betParticipants.length; i++) {
            // Try find wave participant by bet participant
            bool isWaveParticipantFound = false;
            for (uint j = 0; j < waveParticipants.length; j++) {
                if (
                    waveParticipants[j].accountAddress ==
                    betParticipants[i].accountAddress
                ) {
                    isWaveParticipantFound = true;
                    // Update wave participant if found
                    if (betParticipants[i].isWinner) {
                        waveParticipants[j].successes++;
                    } else {
                        waveParticipants[j].failures++;
                    }
                    waveParticipants[j].variance =
                        waveParticipants[j].successes -
                        waveParticipants[j].failures;
                    // Emit event
                    emit Events.ContestWaveParticipantSet(
                        _counter.current(),
                        waveParticipants[j].accountAddress,
                        waveParticipants[j]
                    );
                }
            }
            // Create wave participant if not found by bet participant
            if (!isWaveParticipantFound) {
                // Create wave
                DataTypes.ContestWaveParticipant
                    memory waveParticipant = DataTypes.ContestWaveParticipant(
                        betParticipants[i].accountAddress,
                        betParticipants[i].isWinner ? int(1) : int(0),
                        !betParticipants[i].isWinner ? int(1) : int(0),
                        betParticipants[i].isWinner ? int(1) : int(-1)
                    );
                waveParticipants.push(waveParticipant);
                // Emit event
                emit Events.ContestWaveParticipantSet(
                    _counter.current(),
                    waveParticipant.accountAddress,
                    waveParticipant
                );
            }
        }
    }

    receive() external payable {
        emit Events.Received(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "../libraries/DataTypes.sol";

interface IContest {
    function processClosedBetParticipants(
        DataTypes.BetParticipant[] memory betParticipants
    ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IHub {
    function getBetAddress() external view returns (address);

    function getBetCheckerAddress() external view returns (address);

    function getContestAddress() external view returns (address);

    function getUsageAddress() external view returns (address);

    function getBioAddress() external view returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

library DataTypes {
    struct BetParams {
        uint createdTimestamp;
        address creatorAddress;
        uint creatorFee;
        string symbol;
        int targetMinPrice;
        int targetMaxPrice;
        uint targetTimestamp;
        uint participationDeadlineTimestamp;
        uint feeForSuccess;
        uint feeForFailure;
        bool isClosed;
        bool isSuccessful;
    }

    struct BetParticipant {
        uint addedTimestamp;
        address accountAddress;
        uint fee;
        bool isFeeForSuccess;
        bool isWinner;
        uint winning;
    }

    struct ContestWave {
        uint startTimestamp;
        uint endTimestamp;
        uint closeTimestamp;
        uint winnersNumber;
        uint winning;
        address[] winners;
    }

    struct ContestWaveParticipant {
        address accountAddress;
        int successes;
        int failures;
        int variance;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

library Errors {
    // Common
    string internal constant MESSAGE_VALUE_IS_INCORRECT =
        "Message value is incorrect";
    string internal constant TOKEN_DOES_NOT_EXIST = "Token does not exist";
    string internal constant TOKEN_IS_NON_TRANSFERABLE =
        "Token is non-transferable";

    // Bet contract
    string internal constant FEE_MUST_BE_EQUAL_TO_MESSAGE_VALUE =
        "Fee must equal to message value";
    string internal constant FEE_MUST_BE_GREATER_THAN_ZERO =
        "Fee must be greater than zero";
    string internal constant MAX_PRICE_MUST_BE_GREATER_THAN_MIN_PRICE =
        "Max price must be greater than min price";
    string
        internal constant MUST_BE_MORE_THAN_24_HOURS_BEFORE_TARGET_TIMESTAMP =
        "Must be more than 24 hours before target timestamp";
    string
        internal constant MUST_BE_MORE_THAN_8_HOURS_BEFORE_PARTICIPATION_DEADLINE =
        "Must be more than 8 hours before participation deadline";
    string internal constant SYMBOL_IS_NOT_SUPPORTED =
        "Symbol is not supported";
    string internal constant BET_IS_CLOSED = "Bet is closed";
    string internal constant PARTICIPATION_DEADLINE_IS_EXPIRED =
        "Participation deadline is expired";
    string internal constant SENDER_IS_ALREADY_PARTICIPATING_IN_BET =
        "Sender is already participating in bet";
    string internal constant TARGET_TIMESTAMP_HAS_NOT_COME =
        "Target timestamp has not come";
    string internal constant FAILED_TO_SEND_FEE_TO_CONTEST =
        "Failed to send fee to contest";
    string internal constant FAILED_TO_SEND_FEE_TO_USAGE =
        "Failed to send fee to usage";
    string internal constant FAILED_TO_SEND_FEE_AND_WINNING_TO_WINNERS =
        "Failed to send fee and winning to winners";

    // Bet checker contract
    string internal constant LENGTH_OF_INPUT_ARRAYS_MUST_BE_THE_SAME =
        "Lenghs of input arrays must be the same";
    string internal constant MIN_PRICE_MUST_BE_LOWER_THAN_MAX_PRICE =
        "Min price must be lower than max price";
    string internal constant DAY_START_TIMESTAMP_HAS_NOT_COME =
        "Day start timestamp has not come";
    string internal constant NOT_FOUND_FEED_FOR_SYMBOL =
        "Not found feed for symbol";

    // Contest contract
    string internal constant ONLY_BET_CONTRACT_CAN_BE_SENDER =
        "Only bet contract can be sender";
    string internal constant LAST_WAVE_IS_NOT_CLOSED =
        "Last wave is not closed";
    string internal constant WAVE_IS_NOT_STARTED = "Wave is not started";
    string internal constant WAVE_IS_ALREADY_CLOSED = "Wave is already closed";
    string internal constant WAVE_END_TIMESTAMP_HAS_NOT_COME =
        "Wave end timestamp has not come";
    string internal constant NUMBER_OF_WINNERS_IS_INCORRECT =
        "Number of winners is incorrect";
    string internal constant FAILED_TO_SEND_WINNING = "Failed to send winning";
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "../libraries/DataTypes.sol";

library Events {
    // Common
    event Received(address sender, uint value);
    event URISet(uint256 indexed tokenId, string tokenURI);

    // Bet
    event BetParamsSet(uint256 indexed tokenId, DataTypes.BetParams params);
    event BetParticipantSet(
        uint256 indexed tokenId,
        address indexed participantAccountAddress,
        DataTypes.BetParticipant participant
    );

    // Contest
    event ContestWaveCreated(uint id, DataTypes.ContestWave wave);
    event ContestWaveClosed(uint id, DataTypes.ContestWave wave);
    event ContestWaveParticipantSet(
        uint id,
        address indexed participantAccountAddress,
        DataTypes.ContestWaveParticipant participant
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
library Counters {
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}