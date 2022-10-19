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
pragma solidity ^0.8.12;

/**
 * @title IRandomEngineConfig contract
 * @author Debet
 * @notice The interface for RandomEngineConfig contract
 */
interface IRandomEngineConfig {
    /**
     * @dev Emit on setRequestBaseFee function
     * @param requestBaseFee The amount of base Fee
     */
    event SetRequestBaseFee(uint128 requestBaseFee);

    /**
     * @dev Emit on setIntervalTimeToSwap function
     * @param intervalTimeToSwap The interval time
     */
    event SetIntervalTimeToSwap(uint32 intervalTimeToSwap);

    /**
     * @dev Emit on setCallbackGas function
     * @param engineCallbackGas The gas limit in randomEngine request function
     * @param distributionCallbackGas The gas limit in distribution rewards function
     */
    event SetCallbackGas(
        uint32 engineCallbackGas,
        uint32 distributionCallbackGas
    );

    /**
     * @dev Emit on setExtraCallbackGas function
     * @param extraCallbackGas The amount of extra gas
     */
    event SetExtraCallbackGas(uint32 extraCallbackGas);

    /**
     * @dev Emit on setMinLinkBalanceToSwap function
     * @param minLinkBalanceToSwap The minimum link balance of subscription account
     */
    event SetMinLinkBalanceToSwap(uint128 minLinkBalanceToSwap);

    /**
     * @dev Emit on setThresholdToAddRewards function
     * @param thresholdToAddRewards The rewards threshold to adding rewards to rewards pool
     */
    event SetThresholdToAddRewards(uint128 thresholdToAddRewards);

    /**
     * @dev Emit on setSwapProvider function
     * @param swapProvider The address of swap provider contract
     */
    event SetSwapProvider(address swapProvider);

    /**
     * @dev Emit on setStakingPool function
     * @param stakingPool The address of staking pool contract
     */
    event SetStakingPool(address stakingPool);

    /**
     * @dev Emit on setDistributionPool function
     * @param distributionPool The address of distribution pool contract
     */
    event SetDistributionPool(address distributionPool);

    /**
     * @dev Emit on setFactory function
     * @param factory The address of factory contract
     */
    event SetFactory(address factory);

    /**
     * @dev Emit on stopEngine function
     * @param linkReceiver The address to receive the remain link token in
     * subscription account
     */
    event StopEngine(address linkReceiver);

    /**
     * @notice Set the base fee that player pay each time they bet
     * @dev Emit the SetRequestBaseFee event
     * @param _requestBaseFee The amount of base Fee
     */
    function setRequestBaseFee(uint128 _requestBaseFee) external;

    /**
     * @notice Set the maximum interval time of swapping native token to link
     * @dev Emit the SetIntervalTimeToSwap event
     * @param _intervalTimeToSwap The interval time
     */
    function setIntervalTimeToSwap(uint32 _intervalTimeToSwap) external;

    /**
     * @notice Set the callback gas limit in random engine
     * @dev Emit the SetCallbackGas event
     * @dev Including gas in request function and distribute function
     * @param _engineCallbackGas The gas limit in randomEngine request function
     * @param _distributionCallbackGas The gas limit in distribution rewards function
     */
    function setCallbackGas(
        uint32 _engineCallbackGas,
        uint32 _distributionCallbackGas
    ) external;

    /**
     * @notice Set the extra gas added to callBackGasLimit when call chainlink vrf
     * @dev Emit the SetExtraCallbackGas event
     * @dev The extra gas would not be used in transaction
     * @param _extraCallbackGas The amount of extra gas
     */
    function setExtraCallbackGas(uint32 _extraCallbackGas) external;

    /**
     * @notice set the rewards threshold to adding rewards to rewards pool
     * @dev Emit the SetThresholdToAddRewards event
     * @param _thresholdToAddRewards The threshold
     */
    function setThresholdToAddRewards(uint128 _thresholdToAddRewards) external;

    /**
     * @notice Set the minimum link balance of subscription account
     * @dev Emit the SetMinLinkBalanceToSwap event
     * @dev Swap the native token to link if the link balance of
     * subscription account is less than this value
     * @param _minLinkBalanceToSwap The minimum link balance
     */
    function setMinLinkBalanceToSwap(uint128 _minLinkBalanceToSwap) external;

    /**
     * @notice Set the address of swap provider
     * @dev Emit the SetSwapProvider event
     * @param _swapProvider The address of swap provider contract
     */
    function setSwapProvider(address _swapProvider) external;

    /**
     * @notice Set the address of staking pool
     * @dev Emit the SetStakingPool event
     * @param _stakingPool The address of staking pool contract
     */
    function setStakingPool(address _stakingPool) external;

    /**
     * @notice Set the address of distribution pool
     * @dev Emit the SetDistributionPool event
     * @param _distributionPool The address of distribution pool contract
     */
    function setDistributionPool(address _distributionPool) external;

    /**
     * @notice Set the address of factory contract
     * @dev Emit the SetFactory event
     * @param _factory The address of factory contract
     */
    function setFactory(address _factory) external;

    /**
     * @notice Stop the Random engine and cancel subscription of chainlink vrf
     * @dev Emit the StopEngine event
     * @param linkReceiver The address to receive the remain link token in
     * subscription account
     */
    function stopEngine(address linkReceiver) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title IRandomEngineLogic interface
 * @author Debet
 * @notice The interface for RandomEngineLogic contract
 */
interface IRandomEngineLogic {
    /**
     * @dev Emit on request function
     * @param caller the address of caller contract
     * @param rewardsReceiver The address receive rewards of random engine and refund gas
     * @param requestId The request id from chainlink vrf service
     */
    event RandomRequest(
        address caller,
        address rewardsReceiver,
        uint256 requestId
    );

    /**
     * @dev Emit on fulfillRandomWords function
     * @param caller the address of caller contract
     * @param rewardsReceiver the address receive rewards of random engine and refund gas
     * @param requestId The request id from chainlink vrf service
     * @param rewards The amount of random engine rewards
     */
    event RandomCallback(
        address caller,
        address rewardsReceiver,
        uint256 requestId,
        uint256 rewards
    );

    /**
     * @dev Emit on setCaller function
     * @param caller the address of caller contract
     * @param enable Whether enable the caller or not
     */
    event SetCaller(address caller, bool enable);

    /**
     * @dev Emit on set TopUpLink function
     * @param linkAmount The amount of link to top up
     */
    event TopUpLink(uint256 linkAmount);

    /**
     * @notice Request the random works
     * @dev Emit the RandomRequest event
     * @dev Only valid caller set by factory can call ths function
     * @param callbackGasLimit The gas required by the callback
     * function of caller contract
     * @param numWords The number of random words that caller required
     * @param rewardsReceiver The address receive rewards of random engine and refund gas
     * @return requestId The request id from chainlink vrf service
     */
    function request(
        uint32 callbackGasLimit,
        uint32 numWords,
        address rewardsReceiver
    ) external payable returns (uint256 requestId);

    /**
     * @notice Top up link token for subcription account of random engine
     * @dev Emit the TopUpLink event
     */
    function topUpLink() external payable;

    /**
     * @notice Set the caller enable or not
     * @dev Emit the SetCaller event
     * @param caller The address of the caller
     * @param enable Whether enable the caller or not
     */
    function setCaller(address caller, bool enable) external;

    /**
     * @notice get the amount of native token required as gas when call the request function
     * @param callbackGasLimit The gas required by the callback
     * function of caller contract
     * @param gasPriceWei Estimated gas price at time of request
     * @return The amount of native token required
     */
    function calculateNativeTokenRequired(
        uint32 callbackGasLimit,
        uint256 gasPriceWei
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IRandomEngineConfig.sol";
import "./IRandomEngineLogic.sol";

/**
 * @title IRandomEngine interface
 * @author Debet
 * @notice The interface for RandomEngine
 */
interface IRandomEngine is IRandomEngineConfig, IRandomEngineLogic {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/IDiceLogic.sol";
import "../../interfaces/IRandomEngine.sol";
import "../../interfaces/IFactory.sol";
import "../../interfaces/IPool.sol";
import "../../interfaces/external/INativeWrapper.sol";

import "./DiceStorage.sol";

/**
 * @title DiceLogic contract
 * @author Debet
 * @notice Core logic functions of the Dice contract
 */
abstract contract DiceLogic is IDiceLogic, DiceStorage {
    using SafeERC20 for IERC20;

    receive() external payable {}

    /**
     * @notice Player can bet ERC20 token in this function
     * @dev Emit the Bet event
     * @param token The address of the underlying token
     * @param amount The amount od token to bet in the game
     * @param referrer The address of referrer who recommends player to bet
     * @param number The number player bet on
     * @param direction The direction of the bet (0 for UNDER, 1 for OVER)
     * UNDER means the user wins when the lucky number is less than the number the user bet on
     * OVER  means the user wins when the lucky number is greater than the number the user bet on
     */
    function bet(
        address token,
        uint256 amount,
        address referrer,
        uint256 number,
        Direction direction
    ) external payable override nonReentrant {
        address pool = IFactory(factory).tokenPools(token);
        require(pool != address(0), "this token pool is no exists");

        IERC20(token).safeTransferFrom(msg.sender, pool, amount);

        _bet(pool, amount, msg.value, referrer, number, direction, false);
    }

    /**
     * @notice Player can bet native token in this function
     * @dev Emit the Bet event
     * @param amount The amount of native token to bet in the game
     * @param referrer The address of referrer who recommends player to bet
     * @param number The number player bet on
     * @param direction The direction of the bet (0 for UNDER, 1 for OVER)
     * UNDER means the user wins when the lucky number is less than the number the user bet on
     * OVER  means the user wins when the lucky number is greater than the number the user bet on
     */
    function betNativeToken(
        uint256 amount,
        address referrer,
        uint256 number,
        Direction direction
    ) external payable override nonReentrant {
        address pool = IFactory(factory).tokenPools(nativeWrapper);
        require(pool != address(0), "this token pool is no exists");

        require(msg.value >= amount, "insufficient bet amount");
        INativeWrapper(nativeWrapper).deposit{value: amount}();
        IERC20(nativeWrapper).safeTransfer(pool, amount);

        uint256 gasAmount = msg.value - amount;
        _bet(pool, amount, gasAmount, referrer, number, direction, true);
    }

    /**
     * @notice Anyone can cancel a game that has not been drawn within the cancellation period
     * @dev Emit the Cancel event
     * @param requestId The id of the game which is requested to cancel
     */
    function cancel(uint256 requestId) external override nonReentrant {
        Game memory game = games[requestId];

        require(
            game.status == GameStatus.PENDING,
            "game has been canceled or rolled"
        );

        require(
            block.timestamp >= game.betTime + cancelPeriod,
            "it's not time to cancel yet"
        );

        _cancel(requestId, game);
    }

    /**
     * @notice Roll for a game
     * @dev Emit the Roll event
     * @dev Only random engine contract can call this function
     * @param requestId The id of the game which is rolled
     * @param randomWords The random works array (only 1 element in the array)
     * @param rewards The amount of random engine rewards
     */
    function callback(
        uint256 requestId,
        uint256[] memory randomWords,
        uint256 rewards
    ) external override nonReentrant {
        require(
            msg.sender == address(IFactory(factory).randomEngine()),
            "caller is not random engine"
        );
        _callback(requestId, randomWords, rewards);
    }

    /**
     * @notice Get the sepecified game information by requestId
     * @param requestId The id of the game
     * @return gameInfo The game information
     */
    function getGameInfo(uint256 requestId)
        external
        view
        override
        returns (GameInfo memory gameInfo)
    {
        gameInfo.game = games[requestId];
        IPool pool = IPool(gameInfo.game.pool);
        gameInfo.lock = pool.lockInfo(gameInfo.game.gameId);
    }

    /**
     * @notice get the amount of native token required as gas when player bet
     * @param gasPriceWei Estimated gas price at time of request
     * @return Amount of native token required
     */
    function calculateGasRequired(uint256 gasPriceWei)
        external
        view
        override
        returns (uint256)
    {
        IRandomEngine randomEngine = IRandomEngine(
            IFactory(factory).randomEngine()
        );
        return
            randomEngine.calculateNativeTokenRequired(
                uint32(callbackGasLimit),
                gasPriceWei
            );
    }

    function _bet(
        address pool,
        uint256 amount,
        uint256 gasAmount,
        address referrer,
        uint256 number,
        Direction direction,
        bool isNativeToken
    ) internal {
        IRandomEngine randomEngine = IRandomEngine(
            IFactory(factory).randomEngine()
        );

        _verifyBetParams(referrer, amount, number, direction);
        PoolType.BetAmountInfo memory betAmountInfo = _calculateAmount(
            amount,
            number,
            direction
        );

        uint256 gameId = IPool(pool).receiveAndLock(
            msg.sender,
            referrer,
            betAmountInfo
        );

        uint256 requestId = randomEngine.request{value: gasAmount}(
            callbackGasLimit,
            1,
            msg.sender
        );

        Game memory game = Game(
            requestId,
            gameId,
            pool,
            msg.sender,
            block.timestamp,
            number,
            0,
            direction,
            GameResult.LOSE,
            GameStatus.PENDING,
            isNativeToken
        );
        games[requestId] = game;

        emit Bet(msg.sender, requestId);
    }

    function _verifyBetParams(
        address referrer,
        uint256 amount,
        uint256 number,
        Direction direction
    ) internal view {
        require(referrer != msg.sender, "the referrer cannot be yourself");
        require(amount > 0, "need non-zero amount");

        if (direction == Direction.UNDER) {
            // 1-99
            require(number > 0 && number < MAX_NUMBER, "invalid bet number ");
        } else {
            // 0-98
            require(number < MAX_NUMBER - 1, "invalid bet number");
        }
    }

    function _calculateAmount(
        uint256 amount,
        uint256 number,
        Direction direction
    ) internal view returns (PoolType.BetAmountInfo memory betAmountInfo) {
        betAmountInfo.totalBetAmount = amount;
        betAmountInfo.referralFee =
            (amount * referralFeeRate) /
            RATE_DENOMINATOR;
        betAmountInfo.actualBetAmount = amount - betAmountInfo.referralFee;

        uint256 probabilityOfPool;
        uint256 probabilityOfUser;
        uint256 userRate = RATE_DENOMINATOR - bankerAdvantageFeeRate;

        if (direction == Direction.UNDER) {
            probabilityOfPool = MAX_NUMBER - number;
            probabilityOfUser = number;
        } else {
            probabilityOfPool = number + 1;
            probabilityOfUser = MAX_NUMBER - number - 1;
        }

        betAmountInfo.frozenPoolAmount =
            (betAmountInfo.actualBetAmount * probabilityOfPool * userRate) /
            (probabilityOfUser * RATE_DENOMINATOR);
    }

    function _cancel(uint256 requestId, Game memory game) internal {
        game.status = GameStatus.CANCELLED;
        games[requestId] = game;

        if (!game.isNativeToken) {
            IPool(game.pool).releaseAndSend(
                game.gameId,
                PoolType.GameResult.CANCEL,
                game.player
            );
        } else {
            uint256 amount = IPool(game.pool).releaseAndSend(
                game.gameId,
                PoolType.GameResult.CANCEL,
                address(this)
            );
            INativeWrapper(nativeWrapper).withdraw(amount);
            (bool success, ) = payable(game.player).call{
                value: amount,
                gas: 8000
            }("");
            require(success, "transfer native token failed");
        }

        emit Cancel(requestId);
    }

    function _callback(
        uint256 requestId,
        uint256[] memory randomWords,
        uint256 rewards
    ) internal {
        Game memory game = games[requestId];
        require(
            game.status == GameStatus.PENDING,
            "game has been canceled or rolled"
        );

        game.status = GameStatus.ROOLED;
        game.luckyNumber = randomWords[0] % MAX_NUMBER;
        if (game.direction == Direction.UNDER) {
            game.result = game.luckyNumber < game.betNumber
                ? GameResult.WIN
                : GameResult.LOSE;
        } else {
            game.result = game.luckyNumber > game.betNumber
                ? GameResult.WIN
                : GameResult.LOSE;
        }
        games[requestId] = game;

        PoolType.GameResult result = (game.result == GameResult.WIN)
            ? PoolType.GameResult.WIN
            : PoolType.GameResult.LOSE;

        uint256 totalPrize;
        if (!game.isNativeToken) {
            totalPrize = IPool(game.pool).releaseAndSend(
                game.gameId,
                result,
                game.player
            );
        } else {
            totalPrize = IPool(game.pool).releaseAndSend(
                game.gameId,
                result,
                address(this)
            );
            if (totalPrize > 0) {
                INativeWrapper(nativeWrapper).withdraw(totalPrize);
                (bool success, ) = payable(game.player).call{
                    value: totalPrize,
                    gas: 8000
                }("");
                require(success, "transfer native token failed");
            }
        }

        emit Roll(
            requestId,
            game.luckyNumber,
            game.result,
            totalPrize,
            rewards
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./DiceType.sol";

/**
 * @title IDiceLogic interface
 * @author Debet
 * @notice The interface for DiceLogic
 */
interface IDiceLogic is DiceType {
    /**
     * @dev Emit on bet and betNativeToken function
     * @param player The address of the player
     * @param requestId The request id from chainlink vrf service
     */
    event Bet(address indexed player, uint256 requestId);

    /**
     * @dev Emit on callback function
     * @param requestId The id of the game which is rolled
     * @param luckyNumber The luckey number from random engine
     * @param result The result of the game (0 for lose, 1 for win)
     * @param totalPrize The amount of payout from pool (0 id user lose)
     * @param rewards The amount of random engine rewards
     */
    event Roll(
        uint256 indexed requestId,
        uint256 luckyNumber,
        GameResult result,
        uint256 totalPrize,
        uint256 rewards
    );

    /**
     * @dev Emit on cancel function
     * @param requestId The id of the game which is requested to cancel
     */
    event Cancel(uint256 requestId);

    /**
     * @notice Player can bet ERC20 token in this function
     * @dev Emit the Bet event
     * @param token The address of the underlying token
     * @param amount The amount od token to bet in the game
     * @param referrer The address of referrer who recommends player to bet
     * @param number The number player bet on
     * @param direction The direction of the bet (0 for UNDER, 1 for OVER)
     * UNDER means the user wins when the lucky number is less than the number the user bet on
     * OVER  means the user wins when the lucky number is greater than the number the user bet on
     */
    function bet(
        address token,
        uint256 amount,
        address referrer,
        uint256 number,
        Direction direction
    ) external payable;

    /**
     * @notice Player can bet native token in this function
     * @dev Emit the Bet event
     * @param amount The amount of native token to bet in the game
     * @param referrer The address of referrer who recommends player to bet
     * @param number The number player bet on
     * @param direction The direction of the bet (0 for UNDER, 1 for OVER)
     * UNDER means the user wins when the lucky number is less than the number the user bet on
     * OVER  means the user wins when the lucky number is greater than the number the user bet on
     */
    function betNativeToken(
        uint256 amount,
        address referrer,
        uint256 number,
        Direction direction
    ) external payable;

    /**
     * @notice Anyone can cancel a game that has not been drawn within the cancellation period
     * @dev Emit the Cancel event
     * @param requestId The id of the game which is requested to cancel
     */
    function cancel(uint256 requestId) external;

    /**
     * @notice Roll for a game
     * @dev Emit the Roll event
     * @dev Only random engine contract can call this function
     * @param requestId The id of the game which is rolled
     * @param randomWords The random works array (only 1 element in the array)
     * @param rewards The amount of random engine rewards
     */
    function callback(
        uint256 requestId,
        uint256[] memory randomWords,
        uint256 rewards
    ) external;

    /**
     * @notice Get the sepecified game information by requestId
     * @param requestId The id of the game
     * @return gameInfo The game information
     */
    function getGameInfo(uint256 requestId)
        external
        view
        returns (GameInfo memory gameInfo);

    /**
     * @notice get the amount of native token required as gas when player bet
     * @param gasPriceWei Estimated gas price at time of request
     * @return Amount of native token required
     */
    function calculateGasRequired(uint256 gasPriceWei)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IFactoryStorage.sol";
import "./IFactoryConfig.sol";
import "./IFactoryLogic.sol";

/**
 * @title IFactory interface
 * @author Debet
 * @notice The interface for Factory
 */
interface IFactory is IFactoryStorage, IFactoryConfig, IFactoryLogic {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./PoolType.sol";

/**
 * @title IPool interface
 * @author Debet
 * @notice The interface for pool contract
 */
interface IPool is PoolType {
    /**
     * @dev Emit on mint function
     * @param banker The address of user who add liquidity
     * @param tokenAmount The amount of underlying token banker added to pool
     * @param shareAmount The amount of share in token pool banker received
     */
    event Mint(
        address indexed banker,
        uint256 tokenAmount,
        uint256 shareAmount
    );

    /**
     * @dev Emit on burn function
     * @param banker The address of user who remove liquidity
     * @param tokenAmount The amount of underlying token banker received
     * @param shareAmount The amount of share in token pool banker burned
     */
    event Burn(
        address indexed banker,
        uint256 tokenAmount,
        uint256 shareAmount
    );

    /**
     * @dev Emit on receiveAndLock function
     * @param player The address of player
     * @param gameId The unique request id in the toke pool
     * @param received The amount od underlying token pool received actually
     * @param locked The amount of underlying token pool locked
     */
    event ReceiveAndLock(
        address indexed player,
        uint256 indexed gameId,
        uint256 received,
        uint256 locked
    );

    /**
     * @dev Emit on releaseAndSend function
     * @param gameId The unique request id in the toke pool
     * @param result The result of the sepecified game (0 for lose, 1 for success, 2 for cancel)
     */
    event ReleaseAndSend(uint256 indexed gameId, GameResult result);

    /**
     * @notice Add liquidity to this pool
     * @dev only the factory contract can call this function
     * @dev Emit the Mint event
     * @param banker The address of the user who added liquidity
     * @return receivedAmount The amount of token actual received by the pool
     * @return share The amount of the pool share that mint to user
     */
    function mint(address banker)
        external
        returns (uint256 receivedAmount, uint256 share);

    /**
     * @notice remove liquidity from this pool
     * @dev only the factory contract can call this function
     * @dev Emit the Burn event
     * @param banker The address of the user who removed liquidity
     * @param share The amount of pool share to burn
     * @param receiver The address of user that receive the return token
     * @return withdrawAmount The amount of token to return
     */
    function burn(
        address banker,
        uint256 share,
        address receiver
    ) external returns (uint256 withdrawAmount);

    /**
     * @notice Receive the bet amount of user and lock the payout amountof pool
     * @dev Only invalid game contract can call this function
     * @dev Emit the ReceiveAndLock event
     * @param player The address of the player
     * @param referrer The address of the referrer who recommends the user to play
     * @param betAmountInfo The information of bet
     * @return gameId The id of the request in this pool
     */
    function receiveAndLock(
        address player,
        address referrer,
        BetAmountInfo memory betAmountInfo
    ) external returns (uint256 gameId);

    /**
     * @notice Release the lock amount of pool and send the prize out if player win
     * @dev Only invalid game contract can call this function
     * @dev Emit the ReleaseAndSend event
     * @param gameId The id of the sepecified request in this pool
     * @param result The result of this game (0 for lose, 1 for success, 2 for cancel)
     * @param receiver The address of user that receive the prize if the game winner is player
     * @return totalPrize The amount of the prize to return
     */
    function releaseAndSend(
        uint256 gameId,
        GameResult result,
        address receiver
    ) external returns (uint256 totalPrize);

    /**
     * @notice Get the address of underlying token
     * @return The address of underlying token
     */
    function token() external view returns (address);

    /**
     * @notice Get the address of factory contract
     * @return The address of actory contract
     */
    function factory() external view returns (address);

    /**
     * @notice Get the curent pool id
     * @dev current pool id is also the amount of all requests
     * @return The curent pool id
     */
    function poolId() external view returns (uint256);

    /**
     * @notice Get the total amount of underlying token in the pool
     * @return The total amount of underlying token in the pool
     */
    function totalAmount() external view returns (uint256);

    /**
     * @notice Get the current rewards in the pool waiting to be added to rewards pool
     * @return The amount of current rewards in the pool
     */
    function totalRewards() external view returns (uint256);

    /**
     * @notice Get the number of times the pool receive rewards
     * @return The number of times the pool receive rewards
     */
    function addRewardsCounts() external view returns (uint256);

    /**
     * @notice Get the information of this pool
     * @return The information of this pool
     */
    function poolInfo() external view returns (PoolInfo memory);

    /**
     * @notice Get the lock information of a sepecified request
     * @param gameId The id of the sepecified request in this pool
     */
    function lockInfo(uint256 gameId) external view returns (LockInfo memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface INativeWrapper {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../../interfaces/IDiceStorage.sol";

import "../../utils/DebetBase.sol";

/**
 * @title DiceStorage contract
 * @author Debet
 * @notice Storage of the Dice contract
 */
abstract contract DiceStorage is
    IDiceStorage,
    OwnableUpgradeable,
    ReentrancyGuard,
    DebetBase
{
    /// @notice The player must bet less than this value
    uint256 public constant MAX_NUMBER = 100;

    /// @notice The gas limit in callback function
    uint32 public override callbackGasLimit;
    /// @notice The cancel period
    uint256 public override cancelPeriod;
    /// @notice The ratio of referral fees in bet amount
    uint256 public override referralFeeRate;
    /// @notice The advantage ratio of the banker in the game
    uint256 public override bankerAdvantageFeeRate;
    /// @notice The address of factory contract
    address public override factory;
    /// @notice The address of wrapped native token contract
    address public override nativeWrapper;
    /// @notice The mapping from request id to record information of bet
    mapping(uint256 => Game) internal games;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./PoolType.sol";

interface DiceType {
    enum Direction {
        UNDER,
        OVER
    }

    enum GameStatus {
        PENDING,
        ROOLED,
        CANCELLED
    }

    enum GameResult {
        LOSE,
        WIN
    }

    struct Game {
        uint256 requestId;
        uint256 gameId;
        address pool;
        address player;
        uint256 betTime;
        uint256 betNumber;
        uint256 luckyNumber;
        Direction direction;
        GameResult result;
        GameStatus status;
        bool isNativeToken;
    }

    struct GameInfo {
        Game game;
        PoolType.LockInfo lock;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface PoolType {
    enum GameResult {
        LOSE,
        WIN,
        CANCEL
    }

    struct PoolInfo {
        uint256 freeAmount;
        uint256 frozenAmount;
    }

    struct BetAmountInfo {
        uint256 totalBetAmount;
        uint256 actualBetAmount;
        uint256 referralFee;
        uint256 frozenPoolAmount;
    }

    struct LockInfo {
        uint256 id;
        address player;
        address referrer;
        uint256 betAmount;
        uint256 referralFee;
        uint256 rewardsFee;
        uint256 frozenPoolAmount;
        bool handled;
        GameResult result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title IFactoryStorage interface
 * @author Debet
 * @notice The interface for FactoryStorage
 */
interface IFactoryStorage {
    /**
     * @notice Get wether the address is a valid caller
     * @param caller The address of the caller
     * @return Wether the caller is valid or not
     */
    function isValidCaller(address caller) external view returns (bool);

    /**
     * @notice Get the ratio of the rawards pool fee in the referral fee
     * @return The ratio of the rawards pool fee in the referral fee
     */
    function protocolInReferralFee() external view returns (uint256);

    /**
     * @notice Get the maximum ratio of pool free amount to payout
     * @return The maximum ratio of pool free amount to payout
     */
    function maxPrizeRate() external view returns (uint256);

    /**
     * @notice Get the address of the rewards pool contract
     * @return The address of the rewards pool contract
     */
    function rewardsPool() external view returns (address);

    /**
     * @notice Get the address of the random engine contract
     * @return The address of the random engine contract
     */
    function randomEngine() external view returns (address);

    /**
     * @notice Get the address of the wrapped native token
     * @return The address of the wrapped native token
     */
    function nativeWrapper() external view returns (address);

    /**
     * @notice Get the token pool address by sepecified token address
     * @return pool The token pool address
     */
    function tokenPools(address token) external view returns (address pool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title IFactoryConfig interface
 * @author Debet
 * @notice The interface for FactoryConfig
 */
interface IFactoryConfig {
    /**
     * @dev Emit on setDefaultCountsToAddRewards function
     * @param defaultCounts The default number of times
     */
    event UpdateDefaultCountsToAddRewards(uint256 defaultCounts);

    /**
     * @dev Emit on setCountsToAddRewards function
     * @param token The specified token address
     * @param counts The number of times
     */
    event UpdateCountsToAddRewards(address token, uint256 counts);

    /**
     * @dev Emit on setProtocolInReferralFee function
     * @param newProtocolInReferralFee The percentage
     */
    event UpdateProtocolInReferralFee(uint256 newProtocolInReferralFee);

    /**
     * @dev Emit on setMaxPrizeRate function
     * @param newMaxPrizeRate The maximun ratio
     */
    event UpdateMaxPrizeRate(uint256 newMaxPrizeRate);

    /**
     * @dev Emit on setRandomEngine function
     * @param newRandomEngine The address of random engine
     */
    event UpdateRandomEngine(address newRandomEngine);

    /**
     * @dev Emit on setRewardsPool function
     * @param newRewardsPool The address of rewards pool
     */
    event UpdateRewardsPool(address newRewardsPool);

    /**
     * @dev Emit on setGame function
     * @param game The address of game contract
     * @param enable Whether to enable or disable
     */
    event SetGame(address game, bool enable);

    /**
     * @notice Set the default number of times the pool receive rewards before
     * adding rewards to rewards pool for all tokens
     * @dev Only owner can call this function
     * @param defaultCounts The default number of times
     */
    function setDefaultCountsToAddRewards(uint256 defaultCounts) external;

    /**
     * @notice Set the number of times the pool receive rewards before adding
     * rewards to rewards pool for specified token
     * @dev Only owner can call this function
     * @param token The specified token address
     * @param counts The number of times
     */
    function setCountsToAddRewards(address token, uint256 counts) external;

    /**
     * @notice Set the ratio of the rawards pool fee in the referral fee
     * @dev Only owner can call this function
     * @param newProtocolInReferralFee The percentage
     */
    function setProtocolInReferralFee(uint256 newProtocolInReferralFee)
        external;

    /**
     * @notice Set the maximum ratio of the total free amount
     * in a token pool that will be paid out at one time
     * @dev Only owner can call this function
     * @param newMaxPrizeRate The maximun ratio
     */
    function setMaxPrizeRate(uint256 newMaxPrizeRate) external;

    /**
     * @notice Set the address of the random engine contract
     * @dev Only owner can call this function
     * @param newRandomEngine The address of random engine
     */
    function setRandomEngine(address newRandomEngine) external;

    /**
     * @notice Set the address of the rewards pool contract
     * @dev Only owner can call this function
     * @param newRewardsPool The address of rewards pool
     */
    function setRewardsPool(address newRewardsPool) external;

    /**
     * @notice Enable or disable a game contract to call token pools
     * @dev Only owner can call this function
     * @param game The address of game contract
     * @param enable Whether to enable or disable
     */
    function setGame(address game, bool enable) external;

    /**
     * @notice Query the number of times the specified token pool
     * receive rewards before adding rewards to rewards pool.
     * @param token the specified token address
     * @return the number of times
     */
    function countsToAddRewards(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./PoolType.sol";

/**
 * @title IFactoryLogic interface
 * @author Debet
 * @notice The interface for FactoryLogic
 */
interface IFactoryLogic {
    /**
     * @dev Emit on createPool function
     * @param token The address of underlying token
     * @param pool The address of new pool
     */
    event CreatePool(address token, address pool);

    /**
     * @dev Emit on mint and mintNative function
     * @param pool The address of token pool
     * @param banker The address of user who add liquidity
     * @param token The address of underlying token
     * @param amount The amount of underlying token added to pool
     * @param share The amount of share in pool banker received
     */
    event Mint(
        address indexed pool,
        address indexed banker,
        address token,
        uint256 amount,
        uint256 share
    );

    /**
     * @dev Emit on burn and burnNative function
     * @param pool The address of token pool
     * @param banker The address of user who remove liquidity
     * @param token The address of underlying token
     * @param amount The amount of underlying token banker received
     * @param share The amount of share in pool banker burned
     */
    event Burn(
        address indexed pool,
        address indexed banker,
        address token,
        uint256 amount,
        uint256 share
    );

    /**
     * @notice Add liquidity to a specified token pool
     * @param token The specified roken address
     * @param amount Amount of the token
     */
    function mint(address token, uint256 amount) external;

    /**
     * @notice Add liquidity to the wrapped native token pool
     * with native token
     */
    function mintNative() external payable;

    /**
     * @notice remove liquidity from the sepecified token pool
     * @param token The sepecified token address
     * @param share The amount of the token pool share
     */
    function burn(address token, uint256 share) external;

    /**
     * @notice Remove liquidity from the wrapped native token pool
     * and reveive the native token
     * @param share The amount of the token pool share
     */
    function burnNative(uint256 share) external;

    /**
     * @notice create a new token pool
     * @param token The address of the token
     */
    function createPool(address token) external;

    /**
     * @notice query the token pool address by token address
     * @param token The address of the token
     * @return poolInfo The information of the specified token pool
     */
    function getPoolInfo(address token)
        external
        view
        returns (PoolType.PoolInfo memory poolInfo);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
pragma solidity ^0.8.12;

import "./DiceType.sol";

/**
 * @title IDiceStorage interface
 * @author Debet
 * @notice The interface for DiceStorage
 */
interface IDiceStorage is DiceType {
    /**
     * @notice Get the gas limit in callback function
     * @return The gas limit in callback function
     */
    function callbackGasLimit() external view returns (uint32);

    /**
     * @notice Get the cancel period
     * @dev Users can cancel their bets if there is no  ddraw after the cancellation time
     * @return The cancel period
     */
    function cancelPeriod() external view returns (uint256);

    /**
     * @notice Get the ratio of referral fees in bet amount
     * @return The ratio of referral fees in bet amount
     */
    function referralFeeRate() external view returns (uint256);

    /**
     * @notice Get the advantage ratio of the banker in the game
     * @return The advantage ratio of the banker in the game
     */
    function bankerAdvantageFeeRate() external view returns (uint256);

    /**
     * @notice Get the address of factory contract
     * @return The address of factory contract
     */
    function factory() external view returns (address);

    /**
     * @notice Get the address of wrapped native token contract
     * @return The address of wrapped native token contract
     */
    function nativeWrapper() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

abstract contract DebetBase {
    uint256 public constant RATE_DENOMINATOR = 10000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IDiceConfig.sol";
import "./IDiceLogic.sol";
import "./IDiceStorage.sol";

/**
 * @title IDice interface
 * @author Debet
 * @notice The interface for Dice
 */
interface IDice is IDiceStorage, IDiceConfig, IDiceLogic {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title IDiceConfig interface
 * @author Debet
 * @notice The interface for DiceConfig
 */
interface IDiceConfig {
    /**
     * @dev Emit on setCallbackGasLimit function
     * @param newCallbackGasLimit The gas limit in callback function
     */
    event UpdateCallbackGasLimit(uint32 newCallbackGasLimit);

    /**
     * @dev Emit on setCancelPeriod function
     * @param newCancelPeriod The cancel period
     */
    event UpdateCancelPeriod(uint256 newCancelPeriod);

    /**
     * @dev Emit on setReferralFeeRate function
     * @param newReferralFeeRate The ratio of referral fees in bet amount
     */
    event UpdateReferralFeeRate(uint256 newReferralFeeRate);

    /**
     * @dev Emit on setBankerAdvantageFeeRate function
     * @param newBankerAdvantageFeeRate The advantage ratio of the banker in the game
     */
    event UpdateBankerAdvantageFeeRate(uint256 newBankerAdvantageFeeRate);

    /**
     * @notice Set the gas limit in callback function
     * @dev Emit the UpdateCallbackGasLimit event
     * @dev Only owner can call this function
     * @param newCallbackGasLimit The gas limit in callback function
     */
    function setCallbackGasLimit(uint32 newCallbackGasLimit) external;

    /**
     * @notice Set the cancel period
     * @dev Emit the UpdateCancelPeriod event
     * @dev Only owner can call this function
     * @dev Users can cancel their bets if there is no
     * draw after the cancellation time
     * @param newCancelPeriod The cancel period
     */
    function setCancelPeriod(uint256 newCancelPeriod) external;

    /**
     * @notice Set the ratio of referral fees in bet amount
     * @dev Emit the UpdateReferralFeeRate event
     * @dev Only owner can call this function
     * @param newReferralFeeRate The ratio of referral fees in bet amount
     */
    function setReferralFeeRate(uint256 newReferralFeeRate) external;

    /**
     * @notice Set the advantage ratio of the banker in the game
     * @dev Emit the UpdateBankerAdvantageFeeRate event
     * @dev Only owner can call this function
     * @param newBankerAdvantageFeeRate The advantage ratio of the banker in the game
     */
    function setBankerAdvantageFeeRate(uint256 newBankerAdvantageFeeRate)
        external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../interfaces/IDiceConfig.sol";

import "./DiceStorage.sol";

/**
 * @title DiceConfig contract
 * @author Debet
 * @notice Configuration of the Dice contract
 */
abstract contract DiceConfig is IDiceConfig, DiceStorage {
    /**
     * @notice Set the gas limit in callback function
     * @dev Emit the UpdateCallbackGasLimit event
     * @dev Only owner can call this function
     * @param newCallbackGasLimit The gas limit in callback function
     */
    function setCallbackGasLimit(uint32 newCallbackGasLimit)
        external
        override
        onlyOwner
    {
        callbackGasLimit = newCallbackGasLimit;
        emit UpdateCallbackGasLimit(newCallbackGasLimit);
    }

    /**
     * @notice Set the cancel period
     * @dev Emit the UpdateCancelPeriod event
     * @dev Only owner can call this function
     * @dev Users can cancel their bets if there is no
     * draw after the cancellation time
     * @param newCancelPeriod The cancel period
     */
    function setCancelPeriod(uint256 newCancelPeriod)
        external
        override
        onlyOwner
    {
        cancelPeriod = newCancelPeriod;
        emit UpdateCancelPeriod(newCancelPeriod);
    }

    /**
     * @notice Set the ratio of referral fees in bet amount
     * @dev Emit the UpdateReferralFeeRate event
     * @dev Only owner can call this function
     * @param newReferralFeeRate The ratio of referral fees in bet amount
     */
    function setReferralFeeRate(uint256 newReferralFeeRate)
        external
        override
        onlyOwner
    {
        require(newReferralFeeRate < RATE_DENOMINATOR, "invalid params");
        referralFeeRate = newReferralFeeRate;
        emit UpdateReferralFeeRate(newReferralFeeRate);
    }

    /**
     * @notice Set the advantage ratio of the banker in the game
     * @dev Emit the UpdateBankerAdvantageFeeRate event
     * @dev Only owner can call this function
     * @param newBankerAdvantageFeeRate The advantage ratio of the banker in the game
     */
    function setBankerAdvantageFeeRate(uint256 newBankerAdvantageFeeRate)
        external
        override
        onlyOwner
    {
        require(newBankerAdvantageFeeRate < RATE_DENOMINATOR, "invalid params");
        bankerAdvantageFeeRate = newBankerAdvantageFeeRate;
        emit UpdateBankerAdvantageFeeRate(newBankerAdvantageFeeRate);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./DiceConfig.sol";
import "./DiceLogic.sol";

/**
 * @title Dice contract
 * @author Debet
 * @notice Implemention of the Dice contract in debet protocol
 */
contract Dice is DiceConfig, DiceLogic {
    /**
     * @notice Initialize the dice contract
     * @param _factory TThe address of factory contract
     * @param _nativeWrapper The address of wrapped native token contract
     * @param _callbackGasLimit The gas limit in callback function
     */
    function initialize(
        address _factory,
        address _nativeWrapper,
        uint32 _callbackGasLimit
    ) external initializer {
        __Ownable_init();

        factory = _factory;
        nativeWrapper = _nativeWrapper;
        callbackGasLimit = _callbackGasLimit;
        referralFeeRate = 100;
        bankerAdvantageFeeRate = 200;
        cancelPeriod = 3 hours;
    }
}