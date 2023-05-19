/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

// File: contracts/Timer.sol


pragma solidity 0.8.7;

/**
 * @title Universal store of current contract time for testing environments.
 */
contract Timer {
    uint256 private currentTime;

    constructor() public {
        currentTime = block.timestamp;
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set `currentTime` to.
     */
    function setCurrentTime(uint256 time) external {
        currentTime = time;
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint256 for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        return currentTime;
    }
}
// File: contracts/Testable.sol


pragma solidity 0.8.7;


/**
 * @title Base class that provides time overrides, but only if being run in test mode.
 */
abstract contract Testable {
    // If the contract is being run on the test network, then `timerAddress` will be the 0x0 address.
    // Note: this variable should be set on construction and never modified.
    address public timerAddress;

    /**
     * @notice Constructs the Testable contract. Called by child contracts.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(address _timerAddress) internal {
        timerAddress = _timerAddress;
    }

    /**
     * @notice Reverts if not running in test mode.
     */
    modifier onlyIfTest {
        require(timerAddress != address(0x0));
        _;
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set current Testable time to.
     */
    function setCurrentTime(uint256 time) external onlyIfTest {
        Timer(timerAddress).setCurrentTime(time);
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        if (timerAddress != address(0x0)) {
            return Timer(timerAddress).getCurrentTime();
        } else {
            return block.timestamp;
        }
    }
}
// File: contracts/IRandomNumberGenerator.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRandomNumberGenerator {

    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(
        uint256 lotteryId
    )
    external
    returns (uint256 requestId);
}
// File: contracts/ILotteryNFT.sol

pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

interface ILotteryNFT {

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function getTotalSupply() external view returns(uint256);

    function getTicketNumber(
        uint256 _ticketID
    )
    external
    view
    returns(uint256);

    function getOwnerOfTicket(
        uint256 _ticketID
    )
    external
    view
    returns(address);

    function getTicketClaimStatus(
        uint256 _ticketID
    )
    external
    view
    returns(bool);

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    //-------------------------------------------------------------------------

    function batchMint(
        address _to,
        uint256 _lottoID,
        uint256 _numberOfTickets,
        uint256[] calldata _numbers
    )
    external
    returns(uint256[] memory);

    function claimTicket(uint256 _ticketId, uint256 _lotteryId) external returns(bool);
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: @openzeppelin/contracts/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/Lottery.sol

pragma solidity 0.8.7;









contract Lottery is Ownable, Initializable, Testable {

    using SafeERC20 for IERC20;
    using Address for address;
    IERC20 internal usdToken;
    ILotteryNFT internal lotteryNft;
    IRandomNumberGenerator public randomGenerator;
    uint256 internal requestId;
    uint256 private lotteryIdCounter;

    address lotteryFeeRecipient;

    event RequestNumber(uint256 lotteryId, uint256 requestId);
    event LotteryOpen(uint256 lotteryId, uint256 ticketSupply);
    event LotteryClose(uint256 lotteryId, uint256 ticketSupply);

    event NewBatchMint(
        address indexed minter,
        uint256[] ticketIDs,
        uint256[] numbers,
        uint256 totalCost
    );

    event RequestNumbers(uint256 lotteryId, uint256 requestId);

    event UpdatedSizeOfLottery(
        address admin,
        uint8 newLotterySize
    );

    event UpdatedMaxRange(
        address admin,
        uint16 newMaxRange
    );

    event UpdatedBuckets(
        address admin,
        uint8 bucketOneMax,
        uint8 bucketTwoMax,
        uint8 discountForBucketOne,
        uint8 discountForBucketTwo,
        uint8 discountForBucketThree
    );

    event ClaimReward(uint256 matchingNumber, uint256 prizeAmount);


    //-------------------------------------------------------------------------
    // MODIFIERS
    //-------------------------------------------------------------------------

    modifier onlyRandomGenerator() {
        require(
            msg.sender == address(randomGenerator),
            "Only random generator"
        );
        _;
    }

    modifier notContract() {
        require(!address(msg.sender).isContract(), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    enum Status {
        NotStarted,     // The lottery has not started yet
        Open,           // The lottery is open for ticket purchases
        Closed,         // The lottery is no longer open for ticket purchases
        Completed       // The lottery has been closed and the numbers drawn
    }

    struct LottoInfo {
        uint256 lotteryID;          // ID for lotto
        Status lotteryStatus;       // Status for lotto
        uint256 nTokensSold;        // Amount of tokens sold
        uint256 percentForPlatform; //% of prize Pool for Platform Fee (IN 10000) | 2.75 -> 275
        uint256 prizePoolInUSD;    // The amount of USD for prize money
        uint256 costPerTicket;      // Cost per ticket in $cake
        uint256 startingTimestamp;      // Block timestamp for star of lotto
        uint256 closingTimestamp;       // Block timestamp for end of entries
        uint256 winningNumber;     // The winning number
    }

    mapping(uint256 => LottoInfo) internal allLotteries;

    constructor(
        address _usdToken,
        address _timer,
        address _lotteryFeeRecipient
    )
    Testable(_timer)
    public
    {

        require(
            _usdToken != address(0),
            "Contracts cannot be 0 address"
        );

        usdToken = IERC20(_usdToken);
        lotteryFeeRecipient = _lotteryFeeRecipient;
    }

    function initialize(
        address _lotteryNFT,
        address _IRandomNumberGenerator
    )
    external
    initializer
    onlyOwner
    {
        require(
            _lotteryNFT != address(0) &&
            _IRandomNumberGenerator != address(0),
            "Contracts cannot be 0 address"
        );
        lotteryNft = ILotteryNFT(_lotteryNFT);
        randomGenerator = IRandomNumberGenerator(_IRandomNumberGenerator);
    }

    function costToBuyTickets(
        uint256 _lotteryId,
        uint256 _numberOfTickets
    )
    external
    view
    returns(uint256 totalCost)
    {
        uint256 pricePer = allLotteries[_lotteryId].costPerTicket;
        totalCost = pricePer * _numberOfTickets;
    }

    function costToBuyTicketsWithDiscount(
        uint256 _lotteryId,
        uint256 _numberOfTickets
    )
    external
    view
    returns(
        uint256 cost
    )
    {
        cost = this.costToBuyTickets(_lotteryId, _numberOfTickets);
    }

    function getBasicLottoInfo(uint256 _lotteryId) external view returns(
        LottoInfo memory
    )
    {
        return(
            allLotteries[_lotteryId]
        );
    }

    function drawWinningNumber(
        uint256 _lotteryId
    )
    external
    onlyOwner
    {
        // Checks that the lottery is past the closing block
        require(
            allLotteries[_lotteryId].closingTimestamp <= getCurrentTime(),
            "Cannot set winning numbers during lottery"
        );
        // Checks lottery numbers have not already been drawn
        require(
            allLotteries[_lotteryId].lotteryStatus == Status.Open,
            "Lottery State incorrect for draw"
        );
        // Sets lottery status to closed
        allLotteries[_lotteryId].lotteryStatus = Status.Closed;
        // Requests a random number from the generator
        requestId = randomGenerator.getRandomNumber(_lotteryId);
        // Emits that random number has been requested
        emit RequestNumber(_lotteryId, requestId);
    }

    function numberDrawn(
        uint256 _lotteryId,
        uint256 _requestId,
        uint256 _randomNumber
    )
    external
    onlyRandomGenerator()
    {
        require(
            allLotteries[_lotteryId].lotteryStatus == Status.Closed,
            "Draw numbers first"
        );


        uint256 moduleNumber = allLotteries[_lotteryId].nTokensSold;
        if (moduleNumber == 0) {
            moduleNumber = 7;
        }

        uint256 randomNumber = (_randomNumber % moduleNumber) + 1;

        if(requestId == _requestId) {
            allLotteries[_lotteryId].lotteryStatus = Status.Completed;
            allLotteries[_lotteryId].winningNumber = randomNumber;
        }

        emit LotteryClose(_lotteryId, lotteryNft.getTotalSupply());
    }

    function createNewLotto(
        uint256 _costPerTicket,
        uint256 _percentForPlatform,
        uint256 _startingTimestamp,
        uint256 _closingTimestamp
    )
    external
    onlyOwner
    returns(uint256 lotteryId)
    {
        require(
            _startingTimestamp != 0 &&
            _startingTimestamp < _closingTimestamp,
            "Timestamps for lottery invalid"
        );
        // Incrementing lottery ID
        lotteryIdCounter++;
        lotteryId = lotteryIdCounter;
        Status lotteryStatus;
        if(_startingTimestamp >= getCurrentTime()) {
            lotteryStatus = Status.Open;
        } else {
            lotteryStatus = Status.NotStarted;
        }
        // Saving data in struct
        LottoInfo memory newLottery = LottoInfo(
            lotteryId,
            lotteryStatus,
            0,
            _percentForPlatform,
            0,
            _costPerTicket,
            _startingTimestamp,
            _closingTimestamp,
            0
        );
        allLotteries[lotteryId] = newLottery;

        // Emitting important information around new lottery.
        emit LotteryOpen(
            lotteryId,
            lotteryNft.getTotalSupply()
        );
    }

    function batchBuyLottoTicket(
        uint256 _lotteryId,
        uint256 _numberOfTickets
    )
    external
    notContract()
    {
        // Ensuring the lottery is within a valid time
        require(
            getCurrentTime() >= allLotteries[_lotteryId].startingTimestamp,
            "Invalid time for mint:start"
        );
        require(
            getCurrentTime() < allLotteries[_lotteryId].closingTimestamp,
            "Invalid time for mint:end"
        );
        if(allLotteries[_lotteryId].lotteryStatus == Status.NotStarted) {
            if(allLotteries[_lotteryId].startingTimestamp >= getCurrentTime()) {
                allLotteries[_lotteryId].lotteryStatus = Status.Open;
            }
        }
        require(
            allLotteries[_lotteryId].lotteryStatus == Status.Open,
            "Lottery not in state for mint"
        );
        require(
            _numberOfTickets <= 50,
            "Batch mint too large"
        );
        // Getting the cost and discount for the token purchase
        (
        uint256 totalCost
        ) = this.costToBuyTickets(_lotteryId, _numberOfTickets);
        // Transfers the required cake to this contract
        usdToken.transferFrom(
            msg.sender,
            address(this),
            totalCost
        );

        allLotteries[_lotteryId].prizePoolInUSD = allLotteries[_lotteryId].prizePoolInUSD + totalCost;

        uint256[] memory chosenNumberForEachTicket = new uint256[](_numberOfTickets);

        uint256 numberForTicket = allLotteries[_lotteryId].nTokensSold + 1;

        for (uint256 i = 0; i < _numberOfTickets; i++) {
            chosenNumberForEachTicket[i] = numberForTicket;
            numberForTicket++;
        }
        allLotteries[_lotteryId].nTokensSold = allLotteries[_lotteryId].nTokensSold + _numberOfTickets;

        // Batch mints the user their tickets
        uint256[] memory ticketIds = lotteryNft.batchMint(
            msg.sender,
            _lotteryId,
            _numberOfTickets,
            chosenNumberForEachTicket
        );
        // Emitting event with all information
        emit NewBatchMint(
            msg.sender,
            ticketIds,
            chosenNumberForEachTicket,
            totalCost
        );
    }

    function claimReward(uint256 _lotteryId, uint256 _tokenId) external notContract() {
        // Checking the lottery is in a valid time for claiming
        require(
            allLotteries[_lotteryId].closingTimestamp <= getCurrentTime(),
            "Wait till end to claim"
        );
        // Checks the lottery winning numbers are available
        require(
            allLotteries[_lotteryId].lotteryStatus == Status.Completed,
            "Winning Numbers not chosen yet"
        );
        require(
            lotteryNft.getOwnerOfTicket(_tokenId) == msg.sender,
            "Only the owner can claim"
        );
        // Sets the claim of the ticket to true (if claimed, will revert)
        require(
            lotteryNft.claimTicket(_tokenId, _lotteryId),
            "Numbers for ticket invalid"
        );
        // Getting the number of matching tickets
        uint8 matchingNumber = _getNumberOfMatching(
            lotteryNft.getTicketNumber(_tokenId),
            allLotteries[_lotteryId].winningNumber
        );

        uint256 prizeAmount = 0;

        if (matchingNumber > 0) {
            // Getting the prize amount for those matching tickets
            prizeAmount = _prizeForMatching(
                matchingNumber,
                _lotteryId
            );

            uint256 prizeAmountForWinner =
                prizeAmount / 10000
                *
                (
                    10000 - allLotteries[_lotteryId].percentForPlatform
                );

            uint256 amountForFeeRecipient = prizeAmount - prizeAmountForWinner;

            // Transfering the user their winnings
            usdToken.safeTransfer(msg.sender, prizeAmountForWinner);
            usdToken.safeTransfer(lotteryFeeRecipient, amountForFeeRecipient);
        }

        emit ClaimReward(matchingNumber, prizeAmount);

    }

    function batchClaimRewards(
        uint256 _lotteryId,
        uint256[] calldata _tokeIds
    )
    external
    notContract()
    {
        require(
            _tokeIds.length <= 50,
            "Batch claim too large"
        );
        // Checking the lottery is in a valid time for claiming
        require(
            allLotteries[_lotteryId].closingTimestamp <= getCurrentTime(),
            "Wait till end to claim"
        );
        // Checks the lottery winning numbers are available
        require(
            allLotteries[_lotteryId].lotteryStatus == Status.Completed,
            "Winning Numbers not chosen yet"
        );
        // Creates a storage for all winnings
        uint256 totalPrize = 0;
        // Loops through each submitted token
        for (uint256 i = 0; i < _tokeIds.length; i++) {
            // Checks user is owner (will revert entire call if not)
            require(
                lotteryNft.getOwnerOfTicket(_tokeIds[i]) == msg.sender,
                "Only the owner can claim"
            );
            // If token has already been claimed, skip token
            if(
                lotteryNft.getTicketClaimStatus(_tokeIds[i])
            ) {
                continue;
            }
            // Claims the ticket (will only revert if numbers invalid)
            require(
                lotteryNft.claimTicket(_tokeIds[i], _lotteryId),
                "Numbers for ticket invalid"
            );
            // Getting the number of matching tickets
            uint8 matchingNumber = _getNumberOfMatching(
                lotteryNft.getTicketNumber(_tokeIds[i]),
                allLotteries[_lotteryId].winningNumber
            );
            // Getting the prize amount for those matching tickets
            uint256 prizeAmount = _prizeForMatching(
                matchingNumber,
                _lotteryId
            );

            totalPrize = totalPrize + prizeAmount;

            emit ClaimReward(matchingNumber, prizeAmount);
        }
        // Transferring the user their winnings

        if (totalPrize > 0) {
            uint256 prizeAmountForWinner =
                totalPrize / 10000
                *
                (
                10000 - allLotteries[_lotteryId].percentForPlatform
                );

            uint256 amountForFeeRecipient = totalPrize - prizeAmountForWinner;

            usdToken.safeTransfer(msg.sender, prizeAmountForWinner);
            usdToken.safeTransfer(lotteryFeeRecipient, amountForFeeRecipient);
        }
    }

    function _getNumberOfMatching(
        uint256 _usersNumber,
        uint256 _winningNumber
    )
    internal
    pure
    returns(uint8 noOfMatching)
    {
        noOfMatching = 0;
        if (_usersNumber == _winningNumber) {
            noOfMatching = 1;
        }
    }

    function _prizeForMatching(
        uint8 _noOfMatching,
        uint256 _lotteryId
    )
    internal
    view
    returns(uint256)
    {
        // If user has no matching numbers their prize is 0
        if(_noOfMatching == 0) {
            return 0;
        }

        return allLotteries[_lotteryId].prizePoolInUSD;
    }

    function setLotteryFeeRecipient(address _lotteryFeeRecipient) external onlyOwner {
        lotteryFeeRecipient = _lotteryFeeRecipient;
    }
}