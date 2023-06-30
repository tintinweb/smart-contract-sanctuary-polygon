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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILP {
    function asset() external view returns (uint256);

    function liability() external view returns (uint256);

    function decimals() external view returns (uint8);

    function updateAssetLiability(uint256 assetAmount, bool assetIncrease, uint256 liabilityAmount, bool liabilityIncrease, bool checkLimit) external;

    function mint(address recipient, address user, uint256 amount) external;

    function burnFrom(address account, address user, uint256 amount) external;

    function withdrawUnderlyer(address recipient, uint256 amount) external;

    function approve(address spender, uint256 amount) external returns (bool);
    
    function totalSupply() external view returns (uint256);

    function getEmissionWeightage() external view returns (uint256);

    function resetPeriod() external;

    function getLR() external view returns (uint256);

    function getMaxLR() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMasterMantis {
    function deposit(address _user, uint256 _pid, uint256 _amount) external;

    function withdrawFor(address recipient, uint256 _pid, uint256 _amount) external;

    function getTokenPid(address token) external view returns (uint256);

    function updateRewardFactor(address _user) external;

    function resetVote(address user) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPoolHelper {
    function getSlippage(uint256 cov, uint256 slippageA, uint256 slippageN, uint256 slippageK) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {OwnableUpgradeable as Ownable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {PausableUpgradeable as Pausable} from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import {ReentrancyGuardUpgradeable as ReentrancyGuard} from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/AggregatorV3Interface.sol";
import "./interfaces/ILP.sol";
import "./interfaces/IMasterMantis.sol";
import "./interfaces/IPoolHelper.sol";

contract Pool is Initializable, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event AddLP(address indexed token, address indexed lpToken, address indexed _feed);
    event RemoveLP(address indexed token);
    event LPRatioUpdated(uint256 indexed lpRatio);
    event BaseFeeUpdated(uint256 indexed baseFee);
    event RiskUpdated(address indexed token, uint256 risk);

    event Deposit(address indexed caller, address indexed receiver, address indexed token, uint256 amount, uint256 lpAmount, bool autoStake);
    event Withdraw(address indexed caller, address indexed receiver, address indexed token, uint256 lpAmount, uint256 amount);
    event WithdrawOther(address indexed caller, address indexed receiver, address indexed token, address otherToken, uint256 lpAmount, uint256 otherAmount);
    event Swap(address indexed caller, address indexed receiver, address indexed from, uint256 fromAmount, address to, uint256 toAmount);
    event OneTapped(address indexed caller, address indexed receiver, address indexed from, address to, uint256 fromLpAmount, uint256 toLpAmount);

    IMasterMantis public masterMantis;
    IPoolHelper private poolHelper;
    address public treasury;

    uint256 public lpRatio;         // 6 decimals
    uint256 private constant ONE_18 = 1e18;

    // Prevents stack too deep error
    struct SwapHelper {
        ILP fromLp;
        ILP toLp;
        uint256 toAmount;
        uint256 treasuryFees;
        uint256 lpAmount;
    }

    // Prevents stack too deep error
    struct OneTapHelper {
        uint256 withdrawAmount;
        uint256 withdrawFees;
        uint256 depositLpAmount;
        uint256 depositFees;
        uint256 fromTreasuryFees;
        uint256 toTreasuryFees;
        uint256 fromAsset;
        uint256 fromLiability;
        uint256 toAsset;
        uint256 toLiability;
    }

    // token -> LP
    mapping(address => address) public tokenLPs;
    ILP[] public lpList;

    // LP -> feed
    mapping(address => address) public priceFeeds;

    uint256 public slippageA;       // Determines the max slippage of the curve. It has 1 decimal place, so 8 = 0.8
    uint256 public slippageN;       // Determines the slope of the curve. Must be > 0.
    uint256 public slippageK;       // The liquidity ratio where the curve equation changes. Value is 18 decimals

    bool public swapAllowed;

    // LP -> risk
    mapping(address => uint256) public riskProfile;

    uint256 public baseFee;


    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, 'Expired');
        _;
    }

    modifier checkZeroAmount(uint256 amount) {
        require(amount > 0, 'ZERO');
        _;
    }

    modifier checkNullAddress(address _address) {
        require(_address != address(0), 'ZERO');
        _;
    }

    function initialize(address _masterMantis, address _treasury, address _poolHelper) external initializer {
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        require(_treasury != address(0), "ZERO");
        require(_poolHelper != address(0), "ZERO");
        if (_masterMantis != address(0)) {
        	masterMantis = IMasterMantis(_masterMantis);
        }
        treasury = _treasury;
        poolHelper = IPoolHelper(_poolHelper);
        slippageA = 8;
        slippageN = 16;
        slippageK = ONE_18;

        baseFee = 100;      // 0.01%
    }

    function setSlippageParams(uint256 _slippageA, uint256 _slippageN) external onlyOwner {
        require(_slippageA > 0, "ZERO");
        require(_slippageN > 0, "ZERO");
        slippageA = _slippageA;
        slippageN = _slippageN;
    }

    function setPoolHelper(address _poolHelper) external onlyOwner checkNullAddress(_poolHelper) {
        poolHelper = IPoolHelper(_poolHelper);
    }

    function setMasterMantis(address _masterMantis) external onlyOwner checkNullAddress(_masterMantis) {
    	masterMantis = IMasterMantis(_masterMantis);
    }

    function setTreasury(address _treasury) external onlyOwner checkNullAddress(_treasury) {
        treasury = _treasury;
    }

    function setRiskProfile(address _token, uint256 _risk) external onlyOwner checkNullAddress(_token) {
        address _lpToken = tokenLPs[_token];
        riskProfile[_lpToken] = _risk;
        emit RiskUpdated(_token, _risk);
    }

    function setSwapAllowed(bool _swapAllowed) external onlyOwner {
        swapAllowed = _swapAllowed;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addLP(address _token, address _lpToken, address _feed) external checkNullAddress(_token) checkNullAddress(_lpToken) checkNullAddress(_feed) onlyOwner {
        tokenLPs[_token] = _lpToken;
        priceFeeds[_lpToken] = _feed;
        lpList.push(ILP(_lpToken));
        emit AddLP(_token, _lpToken, _feed);
    }

    function setLPFeed(address _token, address _feed) external checkNullAddress(_token) checkNullAddress(_feed) onlyOwner {
        address _lpToken = tokenLPs[_token];
        priceFeeds[_lpToken] = _feed;
    }

    function removeLP(address _token, uint index) external checkNullAddress(_token) onlyOwner {
        ILP lpToken = getLP(_token);
        require(lpList[index] == lpToken, "Wrong index");
        tokenLPs[_token] = address(0);
        uint lastLpIndex = lpList.length - 1;
        lpList[index] = lpList[lastLpIndex];
        lpList.pop();
        emit RemoveLP(_token);
    }

    function setLpRatio(uint256 _lpRatio) external onlyOwner {
        require(_lpRatio <= baseFee, "> baseFee");
        lpRatio = _lpRatio;
        emit LPRatioUpdated(_lpRatio);
    }

    function setBaseFee(uint256 _baseFee) external onlyOwner {
        require(_baseFee >= lpRatio, "< lpRatio");
        baseFee = _baseFee;
        emit BaseFeeUpdated(_baseFee);
    }

    function getLP(address _token) public view returns (ILP) {
        require(tokenLPs[_token] != address(0), "No LP");
        return ILP(tokenLPs[_token]);
    }

    /// @notice Get the current treasury fees
    /// @return fees in 6 decimal places. 1e6 = 100%
    function _getTreasuryRatio(uint256 nlr) internal pure returns (uint256) {
        if (nlr < ONE_18) {
            return 0;
        } else if (nlr < 1.05e18) {
            return 4e5;
        } else {
            return 8e5;
        }
    }

    /// @notice Get the current one tap factor
    /// @return value in 6 decimal places. 1e6 = 100% fees
    function _getOneTapFactor(uint256 nlr) internal pure returns (uint256) {
        if (nlr < ONE_18) {
            return 1e6;
        } else if (nlr < 1.05e18) {
            return 8e5;
        } else {
            return 6e5;
        }
    }

    /// @notice Get the current swap fees excluding lp fees
    /// @return swapFee in 6 decimal places. 1e6 = 100%
    function _getSwapFeeRatio(uint256 nlr) internal view returns (uint256 swapFee) {
        if (nlr < 0.96e18) {
            swapFee = 4 * baseFee;
        } else if (nlr < ONE_18) {
            swapFee = 2 * baseFee;
        } else {
            swapFee = baseFee;
        }
        return swapFee - lpRatio;
    }

    function _getSlippage(uint256 lr) internal view returns (uint256) {
        return poolHelper.getSlippage(lr, slippageA, slippageN, slippageK);
    }

    function getNetLiquidityRatio() public view returns (uint256) {
        (uint256 totalAsset, uint256 totalLiability) = _getTotalAssetLiability(address(0), address(0), 0);
        if (totalLiability == 0) {
            return ONE_18;
        } else {
            return (totalAsset * ONE_18) / totalLiability;
        }
    }

    function checkRiskProfile(address fromLp, address toLp, uint256 toAmount) public view returns (bool) {
        uint256 risk = riskProfile[address(fromLp)];
        if (risk == 0) {
            return true;
        }
        (uint256 totalAsset, uint256 totalLiability) = _getTotalAssetLiability(fromLp, toLp, toAmount);
        if (totalLiability == 0) {
            return true;
        } else {
            return ((totalAsset * ONE_18) / totalLiability) >= risk;
        }
    }

    function _getTotalAssetLiability(address fromLp, address toLp, uint256 toAmount) internal view returns (uint256 totalAsset, uint256 totalLiability) {
        for (uint i = 0; i < lpList.length; i++) {
            ILP lp = lpList[i];
            if (address(lp) != fromLp) {
                uint256 price = tokenOraclePrice(address(lp));
                uint256 lpAsset = lp.asset();
                if (address(lp) == toLp) {
                    lpAsset -= toAmount;
                }
                totalAsset += (lpAsset * price) / (10 ** lp.decimals());
                totalLiability += (lp.liability() * price) / (10 ** lp.decimals());
            }
        }
    }

    /// @notice Deposit stable assets into the pool
    /// @param token Token address
    /// @param recipient Recipient address
    /// @param amount Amount of token to deposit
    /// @param autoStake If the lp tokens obtained should be auto-staked into the MasterMantis contract
    /// @param deadline Timestamp before which the txn should be completed
    function deposit(
        address token,
        address recipient,
        uint256 amount,
        bool autoStake,
        uint256 deadline
    ) external whenNotPaused nonReentrant checkDeadline(deadline) checkZeroAmount(amount) checkNullAddress(recipient) {
        ILP lpToken = getLP(token);
        address lpTokenAddress = address(lpToken);
        IERC20(token).safeTransferFrom(msg.sender, lpTokenAddress, amount);
        uint256 lpAmount;
        if (autoStake) {
            lpAmount = _deposit(lpToken, address(this), amount);
            uint256 pid = masterMantis.getTokenPid(lpTokenAddress);
            lpToken.approve(address(masterMantis), lpAmount);
            masterMantis.deposit(recipient, pid, lpAmount);
        } else {
            lpAmount = _deposit(lpToken, recipient, amount);
        }
        emit Deposit(msg.sender, recipient, token, amount, lpAmount, autoStake);
    }

    /// @notice Mints the required no. of LP tokens to recipient
    /// @param lpToken LP Token address
    /// @param recipient Recipient address
    /// @param amount Amount of token to deposit
    /// @return LP tokens minted
    function _deposit(ILP lpToken, address recipient, uint256 amount) internal returns (uint256) {
        (uint256 lpAmount, uint256 fees, uint256 treasuryFees) = getDepositAmount(lpToken, amount, false, 0);
        require(lpAmount > 0, "ERR");
        
        lpToken.mint(recipient, recipient, lpAmount);
        if (treasuryFees > 0) {
            lpToken.withdrawUnderlyer(treasury, treasuryFees);
        }
        lpToken.updateAssetLiability(amount - treasuryFees, true, amount - fees, true, true);
        return lpAmount;
    }

    /// @notice Calculates the amount of LP tokens to be minted on deposit and the corresponding fees
    /// @param lpToken LP Token address
    /// @param amount Amount of token to deposit
    /// @param isOneTap Whether One-Tap functionality is being used. This only affects the fees to be charged
    /// @param asset Asset value of the token. Required only when isOneTap is true
    /// @return lpAmount LP tokens to be minted
    /// @return fees Total Fees to be charged
    /// @return treasuryFees Part of fees transferred to treasury
    function getDepositAmount(ILP lpToken, uint256 amount, bool isOneTap, uint256 asset) public view returns (uint256 lpAmount, uint256 fees, uint256 treasuryFees) {
        if (!isOneTap) {
            asset = lpToken.asset();
        }
        uint256 liability = lpToken.liability();

        if (liability > 0) {
            uint256 currentLR = (asset * ONE_18) / liability;
            if (currentLR > ONE_18) {
                uint256 newLR = ((asset + amount) * ONE_18) / (liability + amount);
                uint256 nlr = getNetLiquidityRatio();
                uint256 maxLR = lpToken.getMaxLR();
                uint256 positiveFees = ((liability + amount) * _getSlippage(newLR)) + (liability * _getSlippage(maxLR));
                uint256 negativeFees = (liability * _getSlippage(currentLR)) + ((liability + amount) * _getSlippage((maxLR*liability+ONE_18*amount) / (liability + amount)));
                if (positiveFees > negativeFees) {
                    fees = (positiveFees - negativeFees) / ONE_18;
                    if (fees > amount) fees = amount;
                }
                if (isOneTap) {
                    fees = fees * _getOneTapFactor(nlr) / 1e6;
                }
                treasuryFees = fees * _getTreasuryRatio(nlr) / 1e6;
            }
        }

        lpAmount = liability == 0 ? amount : (amount - fees) * lpToken.totalSupply() / liability;
    }

    /// @notice Withdraw stable assets back from the pool
    /// @param token Token address of the underlying LP
    /// @param recipient Recipient address
    /// @param lpAmount Amount of LP token being used to withdraw
    /// @param minAmount The minimum amount of token accepted, below which the txn will fail
    /// @param deadline Timestamp before which the txn should be completed
    function withdraw(
        address token,
        address recipient,
        uint256 lpAmount,
        uint256 minAmount,
        uint256 deadline
    ) external whenNotPaused nonReentrant checkDeadline(deadline) checkZeroAmount(lpAmount) checkNullAddress(recipient) {
        ILP lpToken = getLP(token);
        (uint256 amount, uint256 fees, uint256 treasuryFees) = getWithdrawAmount(lpToken, lpAmount, false);
        uint256 finalAmount = amount - fees;
        require(finalAmount >= minAmount, "TOO LOW");

        lpToken.burnFrom(msg.sender, msg.sender, lpAmount);
        lpToken.withdrawUnderlyer(recipient, finalAmount);
        if (treasuryFees > 0) {
            lpToken.withdrawUnderlyer(treasury, treasuryFees);
        }
        lpToken.updateAssetLiability(finalAmount + treasuryFees, false, amount, false, false);
        emit Withdraw(msg.sender, recipient, token, lpAmount, finalAmount);
    }

    /// @notice Withdraw stable assets back from the pool
    /// @param token Token address of the underlying
    /// @param otherToken Token address of the asset which will be withdrawn
    /// @param recipient Recipient address
    /// @param lpAmount Amount of LP token being used to withdraw
    /// @param minAmount The minimum amount of token accepted, below which the txn will fail
    /// @param deadline Timestamp before which the txn should be completed
    function withdrawOther(
        address token,
        address otherToken,
        address recipient,
        uint256 lpAmount,
        uint256 minAmount,
        uint256 deadline
    ) external whenNotPaused nonReentrant checkDeadline(deadline) checkZeroAmount(lpAmount) checkNullAddress(recipient) {
        SwapHelper memory vars;
        vars.fromLp = getLP(token);
        vars.toLp = getLP(otherToken);
        uint256 amount;
        // lpAmount is 'from' lp token to be burned, vars.lpAmount is lp fees earned by LPs of 'other' token
        (amount, vars.toAmount, vars.treasuryFees, vars.lpAmount) = getWithdrawAmountOtherToken(vars.fromLp, vars.toLp, lpAmount);
        require(vars.toAmount >= minAmount, "LOW AMT");

        vars.fromLp.burnFrom(msg.sender, msg.sender, lpAmount);
        vars.fromLp.updateAssetLiability(0, false, amount, false, false);
        vars.toLp.updateAssetLiability(vars.toAmount + vars.treasuryFees, false, vars.lpAmount, true, false);
        vars.toLp.withdrawUnderlyer(recipient, vars.toAmount);
        if (vars.treasuryFees > 0) {
            vars.toLp.withdrawUnderlyer(treasury, vars.treasuryFees);
        }
        emit WithdrawOther(msg.sender, recipient, token, otherToken, lpAmount, vars.toAmount);
    }

    /// @notice Calculates the amount of tokens to be withdrawn and the corresponding fees
    /// @param lpToken LP Token address
    /// @param lpAmount Amount of LP tokens to burn
    /// @param isOneTap Whether One-Tap functionality is being used. This only affects the fees to be charged
    /// @return amount token amount to be withdrawn
    /// @return fees Total Fees to be charged
    /// @return treasuryFees Part of fees transferred to treasury
    function getWithdrawAmount(ILP lpToken, uint256 lpAmount, bool isOneTap) public view returns (uint256 amount, uint256 fees, uint256 treasuryFees) {
        uint256 asset = lpToken.asset();
        uint256 liability = lpToken.liability();
        amount = lpAmount * liability / lpToken.totalSupply();
        require(asset >= amount, "LOW ASSET");
        if(liability > amount) {
            uint256 currentLR = (asset * ONE_18) / liability;
            if (currentLR < ONE_18) {
                uint256 newLR = ((asset - amount) * ONE_18) / (liability - amount);
                uint256 currentSlippage = _getSlippage(currentLR);
                uint256 newSlippage = _getSlippage(newLR);
                uint256 nlr = getNetLiquidityRatio();
                fees = (newSlippage - currentSlippage) * (liability - amount) / ONE_18;
                if (nlr < ONE_18 && amount > fees) {
                    fees += (amount - fees) * (ONE_18 - nlr) / ONE_18;
                }
                if (isOneTap) {
                    fees = fees * _getOneTapFactor(nlr) / 1e6;
                }
                treasuryFees = fees * _getTreasuryRatio(nlr) / 1e6;
            }
        }
    }

    /// @notice Calculates the amount of tokens to be withdrawn in other token (no fees)
    /// @param lpToken LP Token address
    /// @param otherLpToken Other LP Token address
    /// @param lpAmount Amount of LP tokens to burn
    /// @return amount token amount which should have been withdrawn. This is used to update liability
    /// @return otherAmount Amount of other tokens to withdraw
    function getWithdrawAmountOtherToken(ILP lpToken, ILP otherLpToken, uint256 lpAmount) public view returns (uint256 amount, uint256 otherAmount, uint256 treasuryFees, uint256 lpFees) {
        uint256 otherLiability = otherLpToken.liability();
        require(otherLiability > 0, "ERR");

        uint256 otherLpAmount = (lpAmount * (10 ** otherLpToken.decimals())) / (10 ** lpToken.decimals());
        otherAmount = otherLpAmount * otherLiability / otherLpToken.totalSupply();

        uint256 otherLR = ((otherLpToken.asset() - otherAmount) * ONE_18) / otherLiability;
        require(otherLR >= ONE_18, "LR low");
        
        uint256 lpTokenLiability = lpToken.liability();
        amount = lpAmount * lpTokenLiability / lpToken.totalSupply();
        require(lpTokenLiability > amount, "DIV BY 0");
        uint256 lpTokenLR = (lpToken.asset() * ONE_18) / (lpTokenLiability - amount);
        require(otherLR >= lpTokenLR, "From LR higher");

        uint256 nlr = getNetLiquidityRatio();
        uint256 feeAmount = otherAmount * _getSwapFeeRatio(nlr) / 1e6;
        lpFees = otherAmount * lpRatio / 1e6;
        otherAmount = otherAmount - (feeAmount + lpFees);
        treasuryFees = feeAmount * _getTreasuryRatio(nlr) / 1e6;
    }

    /// @notice Swap between from and to tokens.
    /// @param from From token address 
    /// @param from To token address 
    /// @param recipient Address of recipient
    /// @param amount Amount of from tokens
    /// @param minAmount Minimum amount of to tokens accepted, below which txn fails
    /// @param deadline Timestamp before which the txn should be completed
    function swap(
        address from,
        address to,
        address recipient,
        uint256 amount,
        uint256 minAmount,
        uint256 deadline
    ) external whenNotPaused nonReentrant checkDeadline(deadline) checkZeroAmount(amount) checkNullAddress(recipient) {
        SwapHelper memory vars;
        vars.fromLp = getLP(from);
        vars.toLp = getLP(to);
        require(vars.fromLp != vars.toLp, "ERR");
        (vars.toAmount, , vars.treasuryFees, vars.lpAmount) = getSwapAmount(vars.fromLp, vars.toLp, amount, false, 0, 0);
        require(vars.toAmount >= minAmount, "LOW AMT");
        IERC20(from).safeTransferFrom(msg.sender, address(vars.fromLp), amount);
        vars.fromLp.updateAssetLiability(amount, true, 0, false, false);
        vars.toLp.withdrawUnderlyer(recipient, vars.toAmount);
        if (vars.treasuryFees > 0) {
            vars.toLp.withdrawUnderlyer(treasury, vars.treasuryFees);
        }
        vars.toLp.updateAssetLiability(vars.toAmount + vars.treasuryFees, false, vars.lpAmount, true, false);
        emit Swap(msg.sender, recipient, from, amount, to, vars.toAmount);
    }

    /// @notice Get expected amount on a swap
    /// @param fromLp From LP token address 
    /// @param toLp To LP token address 
    /// @param amount Amount of from tokens
    /// @param isOneTap Whether One-Tap functionality is being used. This only affects the fees to be charged
    /// @param fromAsset Asset value of from token. Required only when isOneTap is true
    /// @param fromLiability Liability value of from token. Required only when isOneTap is true
    /// @return toAmount Amount of to tokens
    /// @return feeAmount Swap fees charged
    /// @return treasuryFees Part of swap fees given to treasury
    /// @return lpAmount LP fees given to LPs
    function getSwapAmount(
        ILP fromLp,
        ILP toLp,
        uint256 amount,
        bool isOneTap,
        uint256 fromAsset,
        uint256 fromLiability
    ) public view returns (uint256 toAmount, uint256 feeAmount, uint256 treasuryFees, uint256 lpAmount) {
        require(swapAllowed, "CANNOT");
        uint256 adjustedToAmount = ( amount * (10 ** toLp.decimals()) ) / (10 ** fromLp.decimals());
        if (!isOneTap) {
            fromAsset = fromLp.asset();
            fromLiability = fromLp.liability();
        }
        uint256 toAsset = toLp.asset();
        uint256 toLiability = toLp.liability();

        require(toAsset >= adjustedToAmount, "LOW ASSET");

        toAmount = adjustedToAmount * _getSwapSlippageFactor(
            fromAsset * ONE_18 / fromLiability,
            (fromAsset + amount) * ONE_18 / fromLiability,
            toAsset * ONE_18 / toLiability,
            (toAsset - adjustedToAmount) * ONE_18 / toLiability
        ) / ONE_18;
        require(checkRiskProfile(address(fromLp), address(toLp), toAmount), "ERR");
        
        // uint256 nlr = getNetLiquidityRatio();
        feeAmount = toAmount * _getSwapFeeRatio(ONE_18) / 1e6;
        if (!isOneTap) {
            lpAmount = toAmount * lpRatio / 1e6;
        }
        toAmount = toAmount - (feeAmount + lpAmount);
    }

    /// @notice Get swap slippage during a swap
    /// @param oldFromLR Liquidity ratio of from token before swap
    /// @param newFromLR Liquidity ratio of from token after swap
    /// @param oldToLR Liquidity ratio of to token before swap
    /// @param newToLR Liquidity ratio of to token after swap
    function _getSwapSlippageFactor(
        uint256 oldFromLR,
        uint256 newFromLR,
        uint256 oldToLR,
        uint256 newToLR
    ) internal view returns (uint256 toFactor) {
        int256 negativeFromSlippage;
        int256 negativeToSlippage;
        int256 basisPoint = 1e18;
        if (newFromLR > oldFromLR) {
            negativeFromSlippage = (int256(_getSlippage(oldFromLR)) - int256(_getSlippage(newFromLR))) * basisPoint / int256(newFromLR - oldFromLR);
        }
        if (oldToLR > newToLR) {
            negativeToSlippage = (int256(_getSlippage(newToLR)) - int256(_getSlippage(oldToLR))) * basisPoint / int256(oldToLR - newToLR);
        }

        int256 toFactorSigned = basisPoint + negativeFromSlippage - negativeToSlippage;
        if (toFactorSigned > 2e18) toFactorSigned = 2e18;
        else if (toFactorSigned < 0) toFactorSigned = 0;
        toFactor = uint256(toFactorSigned);
    }

    /// @notice Condenses the operations Withdraw->Swap->Deposit into a sinple operation.
    /// @notice If user is staked, allow user to use the staked amount directly
    /// @notice Provides a fees discount on withdraw/swap/deposit depending on nlr value.
    /// @param from address of from token
    /// @param to address of to token
    /// @param recipient address of recipient
    /// @param lpAmount Amount of from LP tokens to be used in one-tap
    /// @param minAmount Minimum amount of to LP tokens desired, below which txn fails
    /// @param autoWithdraw Uses the from LP tokens which are staked in MasterMantis contract
    /// @param autoStake Stakes the to LP tokens received into MasterMantis contract
    /// @return helper Contains all the amount and fees information during the one-tap
    function oneTap(
        address from,
        address to,
        address recipient,
        uint256 lpAmount,
        uint256 minAmount,
        bool autoWithdraw,
        bool autoStake
    ) external whenNotPaused nonReentrant checkZeroAmount(lpAmount) returns (OneTapHelper memory helper) {
        ILP fromLp = getLP(from);
        ILP toLp = getLP(to);
        helper = getOneTapAmount(fromLp, toLp, lpAmount);
        require(helper.depositLpAmount >= minAmount, "Below minimum");

        fromLp.updateAssetLiability(
            fromLp.asset() > helper.fromAsset ? fromLp.asset() - helper.fromAsset : 0,
            false,
            helper.withdrawAmount,
            false,
            false
        );
        toLp.updateAssetLiability(
            toLp.asset() > helper.toAsset ? toLp.asset() - helper.toAsset : 0,
            false,
            helper.toLiability - toLp.liability(),
            true,
            true
        );
        
        fromLp.withdrawUnderlyer(treasury, helper.fromTreasuryFees);
        toLp.withdrawUnderlyer(treasury, helper.toTreasuryFees);

        if (autoWithdraw) {
            uint256 pid = masterMantis.getTokenPid(address(fromLp));
            masterMantis.withdrawFor(msg.sender, pid, lpAmount);
            fromLp.burnFrom(address(this), msg.sender, lpAmount);
        } else {
            fromLp.burnFrom(msg.sender, msg.sender, lpAmount);
        }
        if (autoStake) {
            toLp.mint(address(this), recipient, helper.depositLpAmount);
            uint256 pid = masterMantis.getTokenPid(address(toLp));
            toLp.approve(address(masterMantis), helper.depositLpAmount);
            masterMantis.deposit(recipient, pid, helper.depositLpAmount);
        } else {
            toLp.mint(recipient, recipient, helper.depositLpAmount);
        }

        emit OneTapped(msg.sender, recipient, from, to, lpAmount, helper.depositLpAmount);
    }

    /// @notice Get the one tap amount and fees info if a one-tap is performed
    /// @param fromLp address of from LP token
    /// @param toLp address of to LP token
    /// @param lpAmount Amount of from LP tokens to be used in one-tap
    /// @return helper Contains all the amount and fees information during the one-tap
    function getOneTapAmount(ILP fromLp, ILP toLp, uint256 lpAmount) public view returns (OneTapHelper memory helper) {
        // Withdraw process
        (helper.withdrawAmount, helper.withdrawFees, helper.fromTreasuryFees) = getWithdrawAmount(fromLp, lpAmount, true);
        require(helper.withdrawAmount > helper.withdrawFees, "HIGH FEES");
        
        uint256 amountForSwap = helper.withdrawAmount - helper.withdrawFees;
        // Update asset and liability of from token
        helper.fromAsset = fromLp.asset() - amountForSwap - helper.fromTreasuryFees;
        helper.fromLiability = fromLp.liability() - helper.withdrawAmount;
        
        // Swap process
        (uint256 toAmount, , uint256 treasuryFees, ) = getSwapAmount(fromLp, toLp, amountForSwap, true, helper.fromAsset, helper.fromLiability);
        // Update asset of from token after swap
        helper.fromAsset += amountForSwap;
        // Update asset of to token after swap
        helper.toAsset = toLp.asset() - toAmount - treasuryFees;
        helper.toTreasuryFees = treasuryFees;

        // Deposit process
        (helper.depositLpAmount, helper.depositFees, treasuryFees) = getDepositAmount(toLp, toAmount, true, helper.toAsset);
        helper.toTreasuryFees += treasuryFees;
        // Update asset and liability of to token
        helper.toAsset += toAmount - treasuryFees;
        helper.toLiability = toLp.liability() + (toAmount - helper.depositFees);

        uint256 toLiquidityRatio = helper.toAsset * ONE_18 / helper.toLiability;
        require(toLiquidityRatio > 1e18, "To lr < 1");
        require(helper.fromAsset * ONE_18 / helper.fromLiability < toLiquidityRatio, "From lr > to lr");
    }

    function tokenOraclePrice(address _address) public view returns (uint256) {
        AggregatorV3Interface feed = AggregatorV3Interface(priceFeeds[_address]);
        ( , int price, , , ) = feed.latestRoundData();
        return uint(price) * ONE_18 / (10 ** feed.decimals());
    }
}