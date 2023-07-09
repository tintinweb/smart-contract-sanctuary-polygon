// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
pragma solidity ^0.8.1;

import "../../../pool-components/slim-pool/PoolCatalogLogicSlim.sol";

contract AuctionPoolCatalogOngoingSlim is PoolCatalogLogicSlim {
    /**
     * @param _minValue The minimum listing price for nft
     * @param _faceValue The maximum listing price for nft
     * @param _roundDuration The duration of a round in seconds
     * @param _bidFee The fee in weth paid per bid
     * @param _maxOffer The maximum bid offer in weth
     * @param _decimals Dictates the minimum offer value (which will set amount slots between min and max offer) == 1 ether / (10**slotDecimals)
     * @param _minBids The minimum amount of none-bonus bids required to close an auction
     * @param _coolOffPeriodTime The duration in seconds of coolOff period
     * @param _factory The factory
     */
    function initialize(
        uint256 _faceValue,
        uint256 _minValue,
        uint256 _roundDuration,
        uint256 _minBids,
        uint256 _bidFee,
        uint256 _maxOffer,
        uint256 _decimals,
        uint256 _coolOffPeriodTime,
        address _factory
    )
        public
        initializer
        basePoolInitialization(
            _faceValue,
            _roundDuration,
            _minBids,
            _bidFee,
            _maxOffer,
            _decimals,
            _coolOffPeriodTime
        )
        catalogPoolInitialization(_minValue)
        baseBidFeesEnforcement
    {
        factory = IAuctionFactory(_factory);
    }

    function getOnMinBidsInitTime() internal view override returns (uint256 _nextRoundStartTime) {
        return roundStartTime[roundCount] + roundDuration;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IAuctionBonus {
    function onBidMinting(address _user) external;

    function mint(address _user, uint256 _amount, bool _alsoBurn) external;

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IAuctionCredit {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function routerProtectPoolExpiry(address _pool) external;

    function promoterMint(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

struct Tokens {
    address feeToken;
    address credit;
    address bonus;
}

interface IAuctionFactory {
    function feeToken() external view returns (address);

    function creditToken() external view returns (address);

    function bonusToken() external view returns (address);

    function stakingTreasury() external view returns (address);

    function bidRouter() external view returns (address);

    function pools(uint256 id) external view returns (address);

    function isOperator(address _operator) external view returns (bool);

    function addUserVolume(address _user, uint256 _amount) external;

    function getTokens() external view returns (Tokens memory);

    function isPool(address _pool) external view returns (bool);

    function poolLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./IAuctionFactory.sol";


interface IAuctionPoolSlim {
    function bid(address _bidder, uint256 _roundId, string[] calldata _ciphers, bytes32[] calldata _hash, bool _isBonus) external;

    function bidFee() external view returns (uint256);

    function factory() external view returns (IAuctionFactory);

    function alive() external view returns (bool);

    function getRoundStatus(uint256 _roundId) external view returns (uint8 _status);

    function settlementTime(uint256 _roundId) external view returns (uint256);

    function roundIdToBidListId(uint256 _roundId) external view returns (uint256);

    function highestValidBid(uint256 _roundId) external view returns (uint256);

    function roundStartTime(uint256 roundId) external view returns (uint256);

    function roundDuration() external view returns (uint256);

    function roundCount() external view returns (uint256);

    function valuedBidsLength(uint256 _bidListId) external view returns (uint256);

    function coolOffPeriodStartTime() external view returns (uint256);

    function coolOffPeriodTime() external view returns (uint256);

    function totalBidListCount() external view returns (uint256);

    function whichRoundInitedMyBids(uint256 bidListId) external view returns (uint256);

    function whichRoundFinalizedMyBids(uint256 bidList) external view returns (uint256);

    function pid() external view returns (uint256);

    function maxOffer() external view returns (uint256);

    function slotDecimals() external view returns (uint256);

    function bidListLength(uint256 bidListId) external view returns (uint256);

    function faceValue() external view returns (uint256);

    function bidListSlotsDataReindexer(uint256 bidListId) external view returns (uint256);

    function SlotsData(uint256 reindexerId, uint256 slotIndex) external view returns (uint256);

    function periodOfExtension() external view returns (uint256);

    function bidsForExtension() external view returns (uint256);

    function roundExtensionChunk() external view returns (uint256);

    function extenderBids(uint256 roundId) external view returns (uint256);

    function roundExtension(uint256 roundId) external view returns (uint256);

    function extensionsHad(uint256 roundId) external view returns (uint256);

    function extensionStep() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IBidRouter {

    function isPool(address _pool) external view returns (bool);

    function teamAddress() external view returns (address);

    function gasReceiver() external view returns (address);

    /// @notice pool function used when refunding a bid for credits
    function poolTransferTo(address _user, uint256 _amount) external;

    function onExpireThresholdReset(address _user) external;

    function gasFee() external view returns (uint256);

    function bid(
        address _token,
        uint256 _factoryId,
        uint256 _poolId,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hashes,
        uint256 _nftListId
    ) external payable;

    function bidOnBehalf(
        address _user,
        address _token,
        uint256 _factoryId,
        uint256 _poolId,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hashes,
        uint256 _nftListId
    ) external;

    function factoryDeclarePool(address _pool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../structs/PoolBaseStructs.sol";

abstract contract PoolBaseEvent {
    /// @notice New round was initialized with corresponding bidListId. note that roundStartTime isn't block.timestamp
    event RoundInited(uint256 indexed bidListId, uint256 indexed roundId, uint256 indexed roundStartTime);
    /// @notice CoolOffPeriod started. note that coolOffPeriodStartTime isn't block.timestamp
    event CoolOffPeriodInited(uint256 indexed coolOffPeriodStartTime);
    /// @notice Player have place a bid in give round. This information is transferred to scrt contract
    event PlayerBid(
        address indexed bidder,
        uint256 indexed bidListId,
        uint256 bidId,
        uint256 indexed roundId,
        uint256 poolId,
        string cipher,
        bytes32 _hash,
        bool isBonus,
        bool minValuedBidReached
    );
    /// @notice Admin have revealed all bids of a round after getting values from scrt when key release condition was met
    event RoundRevealed(uint256 indexed roundId, uint256 indexed bidListId);
    /// @notice Emergency reveal reset occurred
    event EmergencyReset(uint256 roundId);
    /// @notice User collected his rewards that are based on his relative bids-life-span to total-bids-life-span
    event BidPerformanceFeeCollected(address indexed bidder, uint256 indexed bidListId, uint256 indexed roundId, uint256 rewardAmount);
    /// @notice Bid refunded event
    event BidRefunded(uint256 indexed bidListId, uint256 indexed bidId);
    /// @notice Bid revealed
    event BidRevealed(uint256 bidListId, uint256 bidId, uint256 amount, BidInfoStatus isValid);
    /// @notice new extension variable
    event SetRoundExtensionVariables(uint256 periodOfExtension, uint256 bidsForExtension, uint256 roundExtensionChunk, uint256 extensionStep);
    /// @notice set the extension of an active round
    event RoundExtensionSet(uint256 roundId, uint256 extension);
    /// @notice all pools go to heaven
    event PoolEternalRest();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

abstract contract PoolCatalogEvent {
    /// @notice A seller listed an NFT which has recieved nftListId identifier on this contract
    event NftListed(address indexed nftAddress, uint256 nftId, uint256 indexed roundId, uint256 nftListId);
    /// @notice NFT was delisted. allowing withdrawal if not won before lastActiveBidList was settled
    event NftDelisted(
        address indexed seller,
        address indexed nftAddress,
        uint256 nftId,
        uint256 roundId,
        uint256 indexed lastActiveBidList,
        uint256 nftListId
    );
    /// @notice NFT was withdrawn, either due to being delisted or during coolOffPeriod/redButtonPressed(killed pool)
    event NftWithdrawn(address indexed nftAddress, uint256 nftId, uint256 indexed nftListId);
    /// @notice NFT was reserved. If bidder's bid wins this would be his reward unless being withdrawn due to some game scenraios
    event NftReserve(address indexed bidder, address indexed nftAddress, uint256 nftId, uint256 nftListId, uint256 indexed roundId);
    /// @notice Player have place a bid in give round. This information is transfered to scrt contract
    /// @notice Rewards for reserve-count score of an NFT seller were collected
    event ReserveIncomeCollected(uint256 indexed bidListId, uint256 indexed roundId, uint256 rewardAmount);
    /// @notice Winning bidder delta was no enough to pay for his offer so he actively payed it to collect the nft
    event WonNftCollected(address indexed bidder, uint256 indexed roundId, uint256 indexed nftListId, bool autoCollect);
    /// @notice Round was finalized and winner got their rightful winning according to game rules.
    event RoundFinalized(
        uint256 indexed roundId,
        uint256 indexed bidListId,
        address indexed winner,
        address winningSeller,
        uint256 stakersShare
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../storage/PoolBaseStorageSlim.sol";
import "../events/PoolBaseEvents.sol";
import "../../interfaces/IAuctionBonus.sol";
import "../../interfaces/IAuctionFactory.sol";
import "../../interfaces/IAuctionCredit.sol";
import "../../interfaces/IBidRouter.sol";
import "../../interfaces/IAuctionPoolSlimPure.sol";

interface IDecimalsToken {
    function decimals() external view returns (uint8);
}

abstract contract PoolBaseLogicSlim is
    PoolBaseStorageSlim,
    PoolBaseEvent,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    modifier onlyFactory() {
        require(msg.sender == address(factory), "1"); //Note: "1=="Not factory"
        _;
    }

    modifier onlyRouter() {
        require(msg.sender == factory.bidRouter(), "D"); //Note: D=="Not router"
        _;
    }

    /// @notice Operators reveal and finalize auctions
    modifier onlyOperator() {
        require(factory.isOperator(msg.sender), "Not operator");
        _;
    }

    /// @notice Modifier used to init a round when required. Since round initiation is passive (not controlled by team but by laws)
    modifier safeRoundInit() {
        if (
            ((roundDuration + roundStartTime[roundCount]) < block.timestamp) &&
            (coolOffPeriodStartTime + coolOffPeriodTime < block.timestamp)
        ) {
            _initRound();
        }
        _;
    }

    /// @notice if pool is not alive we can't bid or list nfts. And users can refund bids of none-finalized/none-finalizable rounds and instantly withdraw listed nfts.
    modifier poolAlive() {
        require(alive, "3"); //Note: 3 == "pool is dead or not born yet"
        _;
    }

    /// @notice Some functions require a round to be pending finalization
    modifier roundPendingFinalization(uint256 _roundId) {
        require(getRoundStatus(_roundId) == 3, "E"); //Note: E=="Not pending"
        _;
    }

    /// @notice basic pool mandatory initialization
    modifier basePoolInitialization(
        uint256 _faceValue,
        uint256 _roundDuration,
        uint256 _minBids,
        uint256 _bidFee,
        uint256 _maxOffer,
        uint256 _decimals,
        uint256 _coolOffPeriodTime
    ) {
        require(_roundDuration > 0, "No time");
        faceValue = _faceValue;
        minBids = _minBids;
        bidFee = _bidFee;
        roundDuration = _roundDuration;
        slotDecimals = _decimals;
        maxOffer = _maxOffer;
        coolOffPeriodTime = _coolOffPeriodTime;
        amountNormalization = 1 ether / (10 ** slotDecimals);
        roundStartTime[0] =
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff -
            _roundDuration;

        _;
        //19+ decimal tokens will revert, contract supports up to 18 decimals. If using future compilers, confirm that this still reverts.
        decimalsDelta =
            10 ** (18 - IDecimalsToken(factory.feeToken()).decimals());
        require(_bidFee % decimalsDelta == 0, "!match");
    }

    /// @notice this modifier must come after basePoolInitialization
    /// @notice enforces the facevalue to be at least the sum of minimum bid fees of a single auction.
    modifier baseBidFeesEnforcement() {
        require(bidFee * minBids >= (faceValue), "4"); //Note: 4=="Face value doesn't match bidFee and minBid"
        _;
    }

    function bid(
        address _bidder,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hashes,
        bool _isBonus
    ) external virtual poolAlive safeRoundInit onlyRouter {}

    function bid(
        address _bidder,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hashes,
        uint256 _nftListId,
        bool _isBonus
    ) external virtual poolAlive safeRoundInit onlyRouter {}

    function getRoundStatus(
        uint256 _roundId
    ) public view virtual returns (uint8 _status) {}

    /// @notice Reveal phase conducted by operator in which bid amount value are fed from scrt contract to this contract
    /**
     * @param _roundId The round id being revealed
     * @param _bidIds The bid ids of round's bidlist being revealed in this iteration. Corresponding in index with _bidAmounts and _nonces
     * @param _bidAmounts The bid offers of the bids
     * @param _nonces The nonces which were SHA256ed with the bid amount and fed tp the contract during bid
     */
    function reveal(
        uint256 _roundId,
        string[] memory _nonces,
        uint256[] memory _bidIds,
        uint256[] memory _bidAmounts
    ) external virtual onlyOperator roundPendingFinalization(_roundId) {}

    /// @notice After reveal phase is over finalize will iterate over the bids and conclude the auction
    /**
     * @param _limit The amount of bids being finalized
     * @param _roundId The round being finalized
     */
    function finalize(
        uint256 _limit,
        uint256 _roundId
    ) external virtual onlyOperator roundPendingFinalization(_roundId) {}

    /// @notice Passive round initiation. Technical round start is dictated by rules. But the state changing transaction happen at any time
    function _initRound() internal {
        if (!alive) return;
        unchecked {
            if (
                (roundDuration + roundStartTime[roundCount]) <
                block.timestamp &&
                valuedBidsLength[roundIdToBidListId[roundCount]] < minBids
            ) {
                bool _isCoolOff;

                uint256 _lastFreshRound = whichRoundInitedMyBids[
                    totalBidListCount
                ];
                uint256 _lastSuccessfulBidListInit = roundStartTime[
                    _lastFreshRound
                ];

                uint256 roundsTimePerChunk = 3 * roundDuration;
                uint256 _timeDelta = (block.timestamp -
                    _lastSuccessfulBidListInit);
                uint256 _chunkTime = (roundsTimePerChunk + coolOffPeriodTime);

                uint256 latestPartialChunkTime = _timeDelta % _chunkTime;
                if ((latestPartialChunkTime) > roundsTimePerChunk) {
                    _isCoolOff = true;
                } else {
                    _isCoolOff = false;
                }

                uint256 _chunksCount = _timeDelta / _chunkTime;

                uint256 _deadCount;
                if (
                    (roundDuration <= coolOffPeriodTime) &&
                    (latestPartialChunkTime) >= 4 * roundDuration
                ) {
                    _deadCount = 3 + _chunksCount * 3;
                } else {
                    _deadCount =
                        ((latestPartialChunkTime) / roundDuration) +
                        _chunksCount *
                        3;
                }

                //roundCount += _deadCount;
                roundCount = _lastFreshRound + _deadCount;

                if (_isCoolOff) {
                    roundCount -= 1; // Not counting coolOff as a round
                    coolOffPeriodStartTime =
                        _lastSuccessfulBidListInit +
                        _chunksCount *
                        _chunkTime +
                        roundsTimePerChunk;
                    emit CoolOffPeriodInited(coolOffPeriodStartTime);
                    return;
                } else {
                    roundStartTime[roundCount] =
                        _lastSuccessfulBidListInit +
                        (_chunksCount * coolOffPeriodTime) +
                        (((_deadCount) * roundDuration));
                }
            } else {
                roundCount += 1;

                totalBidListCount += 1;
                whichRoundInitedMyBids[totalBidListCount] = roundCount;

                bidListSlotsDataReindexer[
                    totalBidListCount
                ] = totalBidListCount;
            }

            roundIdToBidListId[roundCount] = totalBidListCount;

            emit RoundInited(
                totalBidListCount,
                roundCount,
                roundStartTime[roundCount]
            );
        }
    }

    function tryInitRound() external safeRoundInit {}

    /// @notice sets the round extension variable
    function setRoundExtensionVariables(
        uint256 _periodOfExtension,
        uint256 _bidsForExtension,
        uint256 _roundExtensionChunk,
        uint256 _extensionStep
    ) external onlyOperator {
        require(_periodOfExtension <= roundDuration, "!time");
        roundExtensionChunk = _roundExtensionChunk;
        periodOfExtension = _periodOfExtension;
        bidsForExtension = _bidsForExtension;
        extensionStep = _extensionStep;
        emit SetRoundExtensionVariables(
            _periodOfExtension,
            _bidsForExtension,
            _roundExtensionChunk,
            _extensionStep
        );
    }

    /// @notice help function to control round extension
    function manualExtensionSet(
        uint256 _roundId,
        uint256 _extraTime
    ) external onlyOperator {
        require(getRoundStatus(_roundId) == 1, "!active");
        roundExtension[_roundId] = _extraTime;
        emit RoundExtensionSet(_roundId, _extraTime);
    }

    /// @notice called on bid function once min bids were reached, extends according to rules
    function tryExtendRound(uint256 _roundId, uint256 _bidCount) internal {
        if (bidsForExtension != 0) {
            uint256 roundBaseEndTime = roundDuration + roundStartTime[_roundId];
            if (roundBaseEndTime - periodOfExtension < block.timestamp) {
                require(
                    roundBaseEndTime + roundExtension[_roundId] >=
                        block.timestamp,
                    "Opened the box, shredinger's round is dead"
                );
                uint256 helperDelta;
                uint256 baseExtensionsHad = extensionsHad[_roundId];
                extenderBids[_roundId] += _bidCount;
                uint256 extraChunks = extenderBids[_roundId] / bidsForExtension;

                if (extraChunks == 0) return;

                if (extraChunks + baseExtensionsHad > extensionStep * 2) {
                    //2nd
                    if (baseExtensionsHad < extensionStep) {
                        //0,1,2 types case
                        //double delta case
                        uint256 helperDoubleDelta = extensionStep -
                            baseExtensionsHad; //How many extensions of base type
                        helperDelta =
                            extraChunks -
                            helperDoubleDelta -
                            extensionStep; //how many type 2nd extensions
                        roundExtension[_roundId] +=
                            (helperDoubleDelta * roundExtensionChunk) +
                            ((helperDelta * roundExtensionChunk) / 6) +
                            ((extraChunks - helperDoubleDelta - helperDelta) *
                                roundExtensionChunk) /
                            2;
                    } else {
                        //no double delta
                        if (baseExtensionsHad > extensionStep * 2) {
                            //2type case
                            //0 delta
                            roundExtension[_roundId] +=
                                (extraChunks * roundExtensionChunk) /
                                6;
                        } else {
                            //1type and 2type case
                            helperDelta =
                                (extraChunks + baseExtensionsHad) -
                                2 *
                                extensionStep; //how many extensions are of 2nd
                            roundExtension[_roundId] +=
                                ((extraChunks - helperDelta) *
                                    roundExtensionChunk) /
                                2 +
                                (helperDelta * roundExtensionChunk) /
                                6;
                        }
                    }
                } else if (
                    extraChunks + baseExtensionsHad > extensionStep //1st
                ) {
                    if (baseExtensionsHad < extensionStep) {
                        // 0type and 1type
                        helperDelta =
                            (extraChunks + baseExtensionsHad) -
                            extensionStep; //how many extensions are of new version
                        roundExtension[_roundId] +=
                            (extraChunks - helperDelta) *
                            roundExtensionChunk +
                            (helperDelta * roundExtensionChunk) /
                            2;
                    } else {
                        //just 1type
                        roundExtension[_roundId] +=
                            (extraChunks * roundExtensionChunk) /
                            2;
                    }
                } else {
                    //none
                    roundExtension[_roundId] +=
                        extraChunks *
                        roundExtensionChunk;
                }
                //extensionStep 1st
                //extensionStep*2 2nd
                //1st implications /2
                //2nd implications /6
                extenderBids[_roundId] -= extraChunks * bidsForExtension;
                extensionsHad[_roundId] += extraChunks;
            }
        }
    }

    /// Note Slim pools do not differentiate on bid struct level if bid is bonus or not. Thus user can refund any bid as credit, as long as he has more "valued" bids placed
    /// @notice During coolOffPeriod or if pool was killed users may receive credits/bonus accordingly by refunding their bids
    /**
     * @param _bidListId The bidListId in which bids were taking place
     * @param _bidIds The array of user's bid ids being refunded
     */
    function refundBids(
        uint256 _bidListId,
        uint256[] memory _bidIds
    ) public safeRoundInit nonReentrant {
        require(
            userValuedBids[msg.sender][_bidListId] >= _bidIds.length,
            "Not enough none-bonus bids"
        );
        unchecked {
            if (alive) {
                require(
                    block.timestamp <=
                        coolOffPeriodStartTime + coolOffPeriodTime &&
                        block.timestamp >= coolOffPeriodStartTime,
                    "Not in coolOff"
                );
                require(
                    _bidListId == totalBidListCount,
                    "Not the bidlist under coolOff"
                );
            } else {
                // If red button is pressed (pool killed) we are in constant cool off period
                require(
                    valuedBidsLength[_bidListId] < minBids,
                    "BidList is finalizable"
                );
                require(
                    whichRoundFinalizedMyBids[_bidListId] == 0,
                    "BidList was finalized"
                );
            }

            for (uint256 i; i < _bidIds.length; ++i) {
                BidInfoSlim storage _bidData = bidsList[_bidListId][_bidIds[i]];
                require(
                    _bidData.status != BidInfoStatus.Revoked,
                    "Bid already revoked"
                );
                require(
                    _bidData.bidder == msg.sender,
                    "Sender is not the bidder"
                );
                //Set bid status to revoked
                _bidData.status = BidInfoStatus.Revoked;
                emit BidRefunded(_bidListId, _bidIds[i]);
            }

            //Since we give away credits, we need to reduce from the valuedBids count
            userValuedBids[msg.sender][_bidListId] -= _bidIds.length; //This will never underflow because we require "userValuedBids[msg.sender][_bidListId]>=_bidIds.length"
            valuedBidsLength[_bidListId] -= _bidIds.length; //This will never underflow, because you can only refund valued bids, and for each valued bids this was incremented by 1
            IBidRouter(factory.bidRouter()).poolTransferTo(
                msg.sender,
                bidFee * _bidIds.length
            );
        }
    }

    /**
     * @param _roundId The round id having his reveal phase values reset
     */
    /// @notice Operator error recovery case if fed bad reveal values
    function emergencyRevealReset(
        uint256 _roundId
    ) external virtual onlyOperator roundPendingFinalization(_roundId) {}

    /// @notice Factory has to init the first round on deployment
    function initFirstRound(
        uint256 _firstRoundStart,
        uint256 _pid
    ) external onlyFactory {
        alive = true;
        roundStartTime[1] = _firstRoundStart;
        pid = _pid;
        _initRound();
    }

    /// @notice Killing the pool will allow all active bid and NFTs to be withdrawn
    /// Note If any round requires finalization either do it before killing the pool or never.
    function killPool() external onlyOperator {
        alive = false; //No going back. Everybody will now be able to withdraw their NFTs
        emit PoolEternalRest(); //Ether-nal ;)
    }

    function validBidsLength(
        uint256 _reindexerIndex
    ) external view returns (uint256) {
        return validBids[_reindexerIndex].length;
    }

    function getOnMinBidsInitTime()
        internal
        view
        virtual
        returns (uint256 _nextRoundStartTime)
    {
        require(false, "Must override this function");
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./PoolBaseLogicSlim.sol";
import "../events/PoolCatalogEvents.sol";
import "../storage/PoolCatalogStorage.sol";

abstract contract PoolCatalogLogicSlim is
    PoolBaseLogicSlim,
    PoolCatalogStorage,
    PoolCatalogEvent,
    ERC721HolderUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice init min value for nft listing
    modifier catalogPoolInitialization(uint256 _minValue) {
        minValue = _minValue;
        reserveIncomeRatio = 0;
        //stakersRatio = 10000 - reserveIncomeRatio
        _;
    }

    /// @notice Callable reserve function
    /**
     * @param _roundId The round for which user is reserving
     * @param _nftListId The nftListId identifying nfts in the this pool contract. The NFT being reserved
     */
    function reserve(
        uint256 _roundId,
        uint256 _nftListId
    ) external poolAlive safeRoundInit {
        require(
            coolOffPeriodStartTime + coolOffPeriodTime < block.timestamp,
            "/"
        ); //Can't reserve in coolOff
        require(getRoundStatus(_roundId) == 1);
        _reserve(msg.sender, _roundId, _nftListId);
    }

    function _reserve(
        address _user,
        uint256 _roundId,
        uint256 _nftListId
    ) internal {
        require(nftExists[_nftListId], "B"); //Note: B=="nft isn't available"
        NFTInfo memory _nft = nftInfo[_nftListId];
        uint256 _bidListId = roundIdToBidListId[_roundId];
        require(
            _nft.lastActiveBidList == 0 || _nft.lastActiveBidList >= _bidListId,
            "C"
        ); //Note: C=="NFT not reservable for this round"

        reservations[_bidListId][_user] = _nftListId;

        emit NftReserve(
            _user,
            _nft.nftAddress,
            _nft.nftId,
            _nftListId,
            _roundId
        );
    }

    /// @notice Router only function through which bids are conducted on pool level
    /**
     * @param _bidder The address of the bidding user
     * @param _roundId The id of the round in which the bid takes place
     * @param _ciphers The encrypted values that include the bid amount which can only be decrypted on scrt when game rules were met
     * @param _hashes The hash of user amount + nonce generated in the scrt contract which is encrypted in the cipher
     * @param _nftListId The nft the user reserves
     * @param _isBonus Is the bid being payed with bonus?
     */
    function bid(
        address _bidder,
        uint256 _roundId,
        string[] calldata _ciphers,
        bytes32[] calldata _hashes,
        uint256 _nftListId,
        bool _isBonus
    ) external override poolAlive safeRoundInit onlyRouter {
        unchecked {
            uint256 _bidListId = roundIdToBidListId[_roundId];
            if (reservations[_bidListId][_bidder] != _nftListId) {
                _reserve(_bidder, _roundId, _nftListId);
            } else {
                require(nftExists[_nftListId], "Z");
            }

            if (!_isBonus) {
                valuedBidsLength[_bidListId] += _ciphers.length;
                userValuedBids[_bidder][_bidListId] += _ciphers.length;
            }

            bool _minValuedBidReached;
            if (valuedBidsLength[_bidListId] >= minBids) {
                _minValuedBidReached = true;
                if (roundStartTime[_roundId + 1] == 0) {
                    roundStartTime[_roundId + 1] = getOnMinBidsInitTime();
                    _initRound();
                }
                tryExtendRound(_roundId, _ciphers.length);
            }

            uint256 _bidId = bidListLength[_bidListId];
            bidListLength[_bidListId] += _ciphers.length;

            for (uint256 i; i < _ciphers.length; ++i) {
                bidsList[_bidListId][++_bidId] = BidInfoSlim(
                    _bidder,
                    _hashes[i],
                    BidInfoStatus.Untouch
                );

                emit PlayerBid(
                    _bidder,
                    _bidListId,
                    _bidId,
                    _roundId,
                    pid,
                    _ciphers[i],
                    _hashes[i],
                    _isBonus,
                    _minValuedBidReached
                );
            }

            // /// Increase the reserve count of the NFT for the specific game
            // NftReserveBidCount[_bidListId][_nftListId] += _hashs.length;
            /// Increase the total reserve count for the specific game
            reserveCount[_bidListId] += _hashes.length;
            /// Increase sellers total reserve count for the specific game
            sellerTotalGameReserves[_bidListId][
                nftInfo[_nftListId].owner
            ] += _hashes.length;
        }
    }

    /// @notice Returns the status of an auction based on game rules.
    /// {0 - Was born yet, 1 active, 2 dead, 3 pending finalization, 4 sealed, 5 dead and skipped}
    /**
     * @param _roundId The round for which we are checking status
     */
    function getRoundStatus(
        uint256 _roundId
    ) public view override returns (uint8 _status) {
        //note: Due to contract size limitation and gas opt "getRoundStatus" on contract will not return accurate status for -
        //note: -  post coolOff period future rounds This is not logic breaking. And getRoundStatus on UI help will consider coolOff period times
        uint256 _initTime = roundStartTime[_roundId];
        unchecked {
            if (_roundId > roundCount) {
                uint256 _lastInitedRoundInitTime = roundStartTime[roundCount];
                //lastRound_InitTime + roundDuration lastRound end time thus adding 1
                uint256 _roundDelta = _roundId - roundCount;
                //At this point endTime value is pseudo! since we have a case where we CAN'T KNOW the end time because and cases where we have to calculate it
                //*we don't know how many coolOff periods/normal-inited-rounds-by-minBids-reached-on-previous-round will be* We can't know the endTime here.
                uint256 _roundDeltaExtraTime = (1 + _roundDelta) *
                    roundDuration;
                uint256 endTime = _lastInitedRoundInitTime +
                    _roundDeltaExtraTime; // endTime = pseudoEndTime
                //Since this is "the future" we will calculate init time
                //(the roundId<=roundCount case requires init to be tested for 0 as that would imply past dead round)
                //This is pseudo init time because of pseudo end time BUT for the case where we have a living round this end is NOT pseudo thus init time is correct
                //And since we use init time in the condition, it being correct for that specific condition is important
                _initTime = endTime - roundDuration;
                //uint256 notInitedDeadRoundEndTime = 2*roundDuration + _lastInitedRoundInitTime;
                if (endTime < block.timestamp) {
                    //round ended but never inited, thus is dead
                    _status = 5;
                } else if (
                    _initTime <= block.timestamp
                ) // and endTime >= blockTimestamp
                {
                    //not inited living round
                    _status = 1;
                }
                // else {
                //status = 0 //this is default value
                // }
            } else {
                if (_initTime > 0) {
                    //Round was inited, now we will check if it is alive, dead, or finalize
                    //endTime = _initTime + roundDuration;
                    if (settlementTime[_roundId] > 0) {
                        //Round was finalized
                        _status = 4; //sealed
                    } else {
                        if (
                            _initTime +
                                roundDuration +
                                roundExtension[_roundId] >
                            block.timestamp
                        ) {
                            //init + duration big/equal time means we are in the round's running time
                            if (_initTime <= block.timestamp) {
                                _status = 1; //active
                            } // else {
                            //     //This is a very rare edge case for the first round. As the first round is the only round that could start AFTER block.timestamp
                            //     //_status = 0;, not born yet, default value
                            // }
                        } else {
                            //Round is either dead or reached min bids and is pending finalization
                            if (
                                valuedBidsLength[
                                    roundIdToBidListId[_roundId]
                                ] >=
                                minBids &&
                                roundIdToBidListId[_roundId] + 1 ==
                                roundIdToBidListId[_roundId + 1]
                            ) {
                                _status = 3;
                            } else {
                                //Round is inited and dead
                                _status = 2;
                            }
                        }
                    }
                } else {
                    //round uninited "skipped" case dead round (unlike case of roundId>roundCount this round will never be inited as it was completely skipped)
                    //This dead case has a unique return value (compared to normal dead case)
                    _status = 5;
                }
            }
        }
    }

    /// @notice Reveal phase conducted by operator in which bid amount value are fed from scrt contract to this contract
    /**
     * @param _roundId The round id being revealed
     * @param _bidIds The bid ids of round's bidlist being revealed in this iteration. Corresponding in index with _bidAmounts and _nonces
     * @param _bidAmounts The bid offers of the bids
     * @param _nonces The nonces which were SHA256ed with the bid amount and fed tp the contract during bid
     */
    function reveal(
        uint256 _roundId,
        string[] memory _nonces,
        uint256[] memory _bidIds,
        uint256[] memory _bidAmounts
    ) external override onlyOperator roundPendingFinalization(_roundId) {
        uint256 _bidListId = roundIdToBidListId[_roundId];
        require(
            whichRoundFinalizedMyBids[_bidListId - 1] != 0 || _bidListId == 1,
            "Y"
        );

        uint256 _reindexerIndex = bidListSlotsDataReindexer[_bidListId];
        uint256 _slotIndex;
        uint256 _bidId;
        uint256 _slotData;
        for (uint256 i; i < _bidIds.length; i++) {
            _bidId = _bidIds[i];
            require(_bidId == lastRevealedBid[_bidListId] + 1, "F");
            lastRevealedBid[_bidListId] = _bidId;
            BidInfoSlim storage _bidData = bidsList[_bidListId][_bidId];
            bidAmounts[_bidListId][_bidId] = _bidAmounts[i];
            //_slotIndex = _bidAmounts[i] / amountNormalization;
            if (_bidData.status != BidInfoStatus.Revoked) {
                _slotIndex = _bidAmounts[i] / amountNormalization;
                if (
                    keccak256(abi.encodePacked(_bidAmounts[i], _nonces[i])) ==
                    _bidData.bidHash &&
                    _bidAmounts[i] % amountNormalization == 0 &&
                    _bidAmounts[i] <= maxOffer &&
                    !isHashUsed[_reindexerIndex][_bidData.bidHash]
                ) {
                    isHashUsed[_reindexerIndex][_bidData.bidHash] = true;
                    _bidData.status = BidInfoStatus.Valid; // Valid
                    SlotsData[_reindexerIndex][_slotIndex] += 1;

                    validBids[_reindexerIndex].push(_bidId);

                    //State data for living time logic
                    _slotData = SlotsData[_reindexerIndex][_slotIndex];
                    if (_slotData == 2) {
                        //BURNED SLOT!
                        //This is pseudo "lastLivingBid"
                        //"lastLivingBid" is only relevant in finalization if all bids are burned, in that case, it isn't pseudo
                        lastLivingBid[_bidListId] = firstBidOnSlot[_bidListId][
                            _slotIndex
                        ];
                    } else if (_slotData == 1) {
                        firstBidOnSlot[_bidListId][_slotIndex] = _bidId;
                    }
                } else {
                    _bidData.status = BidInfoStatus.Invalid; // Invalid
                }
                emit BidRevealed(
                    _bidListId,
                    _bidId,
                    _bidAmounts[i],
                    _bidData.status
                );
            }
        }

        totalBidsRevealed[_bidListId] += _bidIds.length;

        //Checking if last bid revealed is indeed the last bid
        //Allowing _bidIds[_bidIds.length - 1] > bidListLength[_bidListId] to enter loop in order to revert with G making admin mistake revert
        if (_bidIds[_bidIds.length - 1] >= bidListLength[_bidListId]) {
            //roundStatus[_roundId] = RoundStatus.Revealed;
            isRoundRevealed[_roundId] = true;
            require(
                totalBidsRevealed[_bidListId] == bidListLength[_bidListId],
                "G"
            ); //Must reset
            emit RoundRevealed(_roundId, _bidListId);
        }
    }

    /// @notice After reveal phase is over finalize will iterate over the bids and conclude the auction
    /**
     * @param _limit The amount of bids being finalized
     * @param _roundId The round being finalized
     */
    function finalize(
        uint256 _limit,
        uint256 _roundId
    ) external override onlyOperator roundPendingFinalization(_roundId) {
        require(isRoundRevealed[_roundId], "H");
        uint256 _bidListId = roundIdToBidListId[_roundId];
        unchecked {
            uint256 _safeLimit = validBids[
                bidListSlotsDataReindexer[_bidListId]
            ].length >= _limit + finalizedBidsCount[_bidListId]
                ? _limit + finalizedBidsCount[_bidListId]
                : validBids[bidListSlotsDataReindexer[_bidListId]].length;

            uint256 _highestBidValue = bidAmounts[_bidListId][
                highestValidBid[_bidListId]
            ];
            //bidAmounts[_bidListId][_bidId]
            uint256 _slotIndex;
            uint256 _bidId;
            uint256 _tempAmount;
            for (
                uint256 i = finalizedBidsCount[_bidListId];
                i < _safeLimit;
                i++
            ) {
                _bidId = validBids[bidListSlotsDataReindexer[_bidListId]][i];
                //BidInfoSlim memory _theBid = bidsList[_bidListId][_bidId];
                _tempAmount = bidAmounts[_bidListId][_bidId];
                _slotIndex = _tempAmount / amountNormalization;
                if (
                    SlotsData[bidListSlotsDataReindexer[_bidListId]][
                        _slotIndex
                    ] < 2
                ) {
                    if (_highestBidValue < _tempAmount) {
                        _highestBidValue = _tempAmount;
                        highestValidBid[_bidListId] = _bidId;
                    }
                }
            }
            finalizedBidsCount[_bidListId] = _safeLimit;
            if (
                _safeLimit ==
                validBids[bidListSlotsDataReindexer[_bidListId]].length
            ) {
                if (highestValidBid[_bidListId] == 0) {
                    highestValidBid[_bidListId] = lastLivingBid[_bidListId];
                }
                settlementTime[_roundId] = block.timestamp;

                BidInfoSlim memory _winningBid = bidsList[_bidListId][
                    highestValidBid[_bidListId]
                ];

                IAuctionCredit(IAuctionFactory(factory).creditToken()).withdraw(
                    valuedBidsLength[_bidListId] * bidFee
                );

                IERC20Upgradeable _feeToken = IERC20Upgradeable(
                    factory.feeToken()
                );

                uint256 _wonNftListId = reservations[_bidListId][
                    _winningBid.bidder
                ];
                NFTInfo storage _wonNft = nftInfo[_wonNftListId];

                address _winningSeller = _wonNft.owner;

                if (
                    (_wonNft.lastActiveBidList == 0 ||
                        _wonNft.lastActiveBidList >= _bidListId) &&
                    nftExists[_wonNftListId]
                ) {
                    roundInWhichNftWasWon[_wonNftListId] = _roundId;

                    _safeLimit = faceValue - _wonNft.listPrice;

                    wasNFTCollected[_roundId] = true;
                    IERC721 theNFT = IERC721(_wonNft.nftAddress);
                    try
                        theNFT.safeTransferFrom(
                            address(this),
                            _winningBid.bidder,
                            _wonNft.nftId
                        )
                    {
                        _feeToken.safeTransfer(
                            _wonNft.owner,
                            (_wonNft.listPrice) / decimalsDelta
                        );

                        _wonNft.status = NFTInfoStatus.Withdrawn;
                        emit WonNftCollected(
                            _winningBid.bidder,
                            _roundId,
                            _wonNftListId,
                            true
                        );
                    } catch {
                        _wonNft.lastActiveBidList = _roundId;
                        _wonNft.status = NFTInfoStatus.Delisted;
                        roundInWhichNftWasWon[_wonNftListId] = 0;
                        _feeToken.safeTransfer(
                            _winningBid.bidder,
                            faceValue / decimalsDelta
                        );
                        _winningSeller = address(0);
                    }
                } else {
                    if (_winningBid.bidder == address(0)) {
                        //note: If all bids were invalid winner is address(0)
                        _feeToken.safeTransfer(
                            msg.sender,
                            faceValue / decimalsDelta
                        );
                    } else {
                        _feeToken.safeTransfer(
                            _winningBid.bidder,
                            faceValue / decimalsDelta
                        );
                    }

                    wasNFTCollected[_roundId] = true;

                    _winningSeller = address(0);
                }

                nftExists[_wonNftListId] = false;

                whichRoundFinalizedMyBids[_bidListId] = _roundId;

                uint256 _distributedFunds = valuedBidsLength[_bidListId] *
                    bidFee -
                    faceValue;
                if (reserveIncomeRatio > 0) {
                    totalReserveIncome[_bidListId] =
                        (_distributedFunds * reserveIncomeRatio) /
                        10000;

                    //STACK DEPTH REDUCTION
                    //Reusing "_distributedFunds" variable to store the "_totalStakersShare" spirituality
                    _distributedFunds =
                        _distributedFunds -
                        totalReserveIncome[_bidListId];
                }

                _feeToken.safeTransfer(
                    factory.stakingTreasury(),
                    _distributedFunds / decimalsDelta
                );

                emit RoundFinalized(
                    _roundId,
                    _bidListId,
                    _winningBid.bidder,
                    _winningSeller,
                    _distributedFunds
                );
            }
        }
    }

    /// @notice NFT seller may collect his reservation income from a game (a bidList)
    /**
     * @param _bidListId the bid list id in which reservation uncome is being collected
     */
    function collectReservationIncome(uint256 _bidListId) public nonReentrant {
        uint256 finalizingRound = whichRoundFinalizedMyBids[_bidListId];
        require(finalizingRound != 0, "L");
        require(!didSellerCollectReserveIncome[_bidListId][msg.sender], "M");

        uint256 _reward = ((sellerTotalGameReserves[_bidListId][msg.sender] *
            totalReserveIncome[_bidListId]) / reserveCount[_bidListId]);
        IERC20Upgradeable(factory.feeToken()).safeTransfer(
            msg.sender,
            _reward / decimalsDelta
        );
        didSellerCollectReserveIncome[_bidListId][msg.sender] = true;
        emit ReserveIncomeCollected(_bidListId, finalizingRound, _reward);
    }

    /// @notice Seller lists his nft
    /**
     * @param _nftAddress The contract address of listed nft
     * @param _nftId The id of the nft in its contract
     * @param _listPrice Seller listing price in feeToken, to be received if NFT was selected by winning bidder
     */
    function listNFT(
        address _nftAddress,
        uint256 _nftId,
        uint256 _listPrice
    ) external nonReentrant poolAlive {
        require(_listPrice <= faceValue && _listPrice >= minValue, "5"); //Note: 5=="listing price not in range"

        IERC721 _nft = IERC721(_nftAddress);
        _nft.safeTransferFrom(msg.sender, address(this), _nftId);

        nftListId += 1;
        nftExists[nftListId] = true;
        nftInfo[nftListId] = NFTInfo(
            _nftAddress,
            _nftId,
            NFTInfoStatus.Active,
            0,
            _listPrice,
            msg.sender
        );

        emit NftListed(_nftAddress, _nftId, roundCount, nftListId);
    }

    /// @notice Seller delist his nft and can withdraw it after latest auction is concluded
    /**
     * @param _nftListId The nftListId identifying nfts in the this pool contract
     */
    function delistNFT(uint256 _nftListId) external {
        NFTInfo storage _nft = nftInfo[_nftListId];
        require(_nft.owner == msg.sender, "6"); //Note: 6=="Not owner of nft"
        require(_nft.status == NFTInfoStatus.Active, "7"); //Note: 7 == "NFT status isn't active"

        _nft.status = NFTInfoStatus.Delisted;

        _nft.lastActiveBidList = totalBidListCount;

        emit NftDelisted(
            msg.sender,
            _nft.nftAddress,
            _nft.nftId,
            roundCount,
            totalBidListCount,
            _nftListId
        );
    }

    /// @notice Seller may withdraw his nft if he delisted it and the required auction was finalized, in coolOffPeriod or when pool is dead
    /**
     * @param _nftListId The nftListId identifying nfts in the this pool contract
     */
    function withdrawNFT(
        uint256 _nftListId
    ) external safeRoundInit nonReentrant {
        NFTInfo storage _nft = nftInfo[_nftListId];
        require(_nft.owner == msg.sender, "6"); //Note: 6=="Not owner of nft"
        if (
            (block.timestamp < coolOffPeriodStartTime + coolOffPeriodTime) ||
            !alive
        ) {
            require(_nft.status != NFTInfoStatus.Withdrawn, "8"); //Note: 8=="NFT was withdrawn"
        } else {
            require(_nft.status == NFTInfoStatus.Delisted, "9"); //Note: 9=="NFT must be delisted before withdrawing if not in cool off"
            require(
                whichRoundFinalizedMyBids[_nft.lastActiveBidList] != 0,
                "A"
            ); //Note: A=="Last active bidlist not finalize"
        }

        require(nftExists[_nftListId]);

        nftExists[_nftListId] = false;

        _nft.status = NFTInfoStatus.Withdrawn;

        IERC721(_nft.nftAddress).safeTransferFrom(
            address(this),
            _nft.owner,
            _nft.nftId
        );

        emit NftWithdrawn(_nft.nftAddress, _nft.nftId, _nftListId);
    }

    /// @notice sets the reward distribution variables
    function setRewardDistribution(
        uint256 _reserveIncomeRatio
    ) external onlyOperator {
        require(_reserveIncomeRatio <= 10000);
        //stakersRatio = 10000 - reserveIncomeRatio
        reserveIncomeRatio = _reserveIncomeRatio;
    }

    /**
     * @param _roundId The round id having his reveal phase values reset
     */
    /// @notice Operator error recovery case if fed bad reveal values
    function emergencyRevealReset(
        uint256 _roundId
    )
        external
        override
        onlyOperator
        nonReentrant
        roundPendingFinalization(_roundId)
    {
        uint256 _bidListId = roundIdToBidListId[_roundId];
        lastLivingBid[_bidListId] = 0;
        lastRevealedBid[_bidListId] = 0;
        finalizedBidsCount[_bidListId] = 0;
        highestValidBid[_bidListId] = 0;
        isRoundRevealed[_roundId] = false;
        totalBidsRevealed[_bidListId] = 0;
        bidListSlotsDataReindexer[_bidListId] = uint256(
            keccak256(abi.encodePacked(block.number))
        );
        emit EmergencyReset(_roundId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../../interfaces/IAuctionFactory.sol";
import "../structs/PoolBaseStructs.sol";
import "../structs/SlimBidStruct.sol";
import "../../interfaces/IAuctionPoolSlimPure.sol";

abstract contract PoolBaseStorageSlim is IAuctionPoolSlim{
    /// @notice The address of the factory contract
    IAuctionFactory public factory;
    /// @notice The duration of the round
    uint256 public roundDuration;
    /// @notice The maximum price listing of an NFT in the room
    uint256 public faceValue;
    /// @notice The minimum amount of value bearing(none bonus) bids required to close an auction
    uint256 public minBids;
    /// @notice The maximum offer a user can make
    uint256 public maxOffer;
    /// @notice The duration of coolOffPeriod in a room. Starting the end of 3 consecutive dead rounds
    uint256 public coolOffPeriodTime;
    /// @notice Dictates the min offer "1 ether / (10**slotDecimals)" and along with maxOffer dictates the amount slots in the room
    uint256 public slotDecimals;
    /// @notice The fee paid per bid
    uint256 public bidFee;
    /// @notice The pool id
    uint256 public pid;
    /// @notice a precalculated value used to normalize bid value to slot index
    uint256 amountNormalization;
    /// @notice a precalculated value used to normalize interaction with a feeToken that does not have 18 decimals
    uint256 decimalsDelta;
    /// @notice The total number of rounds (correct if an action was conducted recently) (Dictates roundId which starts from 1)
    uint256 public roundCount;
    /// @notice The total number of bid list
    uint256 public totalBidListCount;
    /// @notice The time where last coolOffPeriodStarted
    uint256 public coolOffPeriodStartTime;
    /// @notice The amount of non-bonus bids in a bidList (bidsListId => count)
    mapping(uint256 => uint256) public valuedBidsLength;
    /// @notice Mapping roundId to it's corresponding bidsListId (dead rounds transfer their bid list forwards) (roundId => bidsListId)
    mapping(uint256 => uint256) public roundIdToBidListId;
    /// @notice Mapping The amount of bids in a bidsList (bidsListId => count)
    mapping(uint256 => uint256) public bidListLength;
    /// @notice Mapping of the bids info in a bidsList (bidsListId => (bidId => info))
    mapping(uint256 => mapping(uint256 => BidInfoSlim)) public bidsList;
    /// @notice Which round created the bid list (bidsListId => roundId)
    mapping(uint256 => uint256) public whichRoundInitedMyBids;
    /// @notice In which round did the bidList reach min bids and was finalized (bidsListId => roundId)
    mapping(uint256 => uint256) public whichRoundFinalizedMyBids;
    /// @notice Help mapping for reveal phase (bidsListId => bidId)
    mapping(uint256 => uint256) public lastRevealedBid;
    /// @notice Help mapping for finalization phase (bidsListId => count)
    mapping(uint256 => uint256) public finalizedBidsCount; //can be private
    /// @notice Help mapping for reveal phase (bidsListId => count)
    mapping(uint256 => uint256) public totalBidsRevealed; //can be private
    /// @notice Help mapping for reveal phase (bidListSlotsDataReindexer[bidsListId] => array of bidIds)
    mapping(uint256 => uint256[]) public validBids;
    /// @notice the revealed amounts of bids (bidlistid => bidid => amount)
    mapping(uint256 => mapping(uint256 => uint256)) public bidAmounts;
    /// @notice An help variable used to find the last living bid in a "all burned" scenario. Otherwise value is pesudo and irelveanet
    mapping(uint256 => uint256) public lastLivingBid;
    /// @notice The wining of an auction, either highest none-burned or in case of "all burned" the last alive (bidsList => bidId)
    mapping(uint256 => uint256) public highestValidBid;
    /// @notice Count array of slots (when values is 2 on a slot it is burned) (bidListSlotsDataReindexer[bidListId] => slot => value)
    mapping(uint256 => mapping(uint256 => uint256)) public SlotsData;
    /// @notice Help-mapping that is used is finding "lastLivingBid" bidListId => slot => bidId
    mapping(uint256 => mapping(uint256 => uint256)) firstBidOnSlot;
    /// @notice Did the round finish reveal phase?
    mapping(uint256 => bool) public isRoundRevealed;
    /// @notice Mapping round id to start time
    mapping(uint256 => uint256) public roundStartTime; //(if 0, round isn't inited)
    /// @notice Mapping round id to settlement time
    mapping(uint256 => uint256) public settlementTime;
    /// @notice Index-helping mapping to allow O(1) data reset in case of emergency reveal reset (bidListId => bidListId_index_for_SlotsData_and_validBids) (bidListId -> index)
    mapping(uint256 => uint256) public bidListSlotsDataReindexer;
    /// @notice Use to prevent the same hash from being used again as an attack vector of burning anyone above you
    // bidListSlotsDataReindexer[bidsListId] => hash => is_used
    mapping(uint256 => mapping(bytes32 => bool)) public isHashUsed;
    /// @notice If false, pool is dead or not born yet(added to factory), all active bids and nfts can be withdrawn
    bool public alive;
    /// @notice The amount of time before initial round's end, in which's time delta extension occur
    uint256 public periodOfExtension;
    /// @notice Amount of bids required to cause roundExtension[round] to add roundExtensionChunk
    uint256 public bidsForExtension;
    /// @notice The amount of time added per bidsForExtension
    uint256 public roundExtensionChunk;
    /// @notice The bids made since the "intial round's end"-periodOfExtension time arrive.
    // Once a time chunk is added, amount of bids is deducted from externderBids
    //roundId => extender bids made
    mapping(uint256 => uint256) public extenderBids;
    /// @notice The amount of extra time for a round
    //roundId => extension in seconds
    mapping(uint256 => uint256) public roundExtension;
    /// @notice extensions had (roundId => amount)
    mapping(uint256 => uint256) public extensionsHad;
    /// @notice The amount of extensions required for extra time reduction ()
    uint256 public extensionStep;
    /// @notice This is the amount of "valued" (none bonus) bids of a user for a bidlist, this server for refunding bids.
    //user => bidlistid => valued bids count
    mapping(address => mapping(uint256 => uint256)) public userValuedBids;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../structs/PoolCatalogStructs.sol";

contract PoolCatalogStorage {
    /// @notice The minimum price listing of an NFT in the room
    uint256 public minValue;
    /// @notice (nftListId => is it avilable for reserve?)
    mapping(uint256 => bool) public nftExists;
    /// @notice Was the NFT which was won in an auction collected? (bidsListId => bool) (bool is also true for auction with missing/bad nft)
    mapping(uint256 => bool) public wasNFTCollected;
    /// @notice The mapping of the auction-contract internal nft index to struct of nft information (nftListId => info)
    mapping(uint256 => NFTInfo) public nftInfo;
    /// @notice The incrementing auction-contract internal nft index (nftListId starts from 1)
    uint256 public nftListId; //can be private
    /// @notice The time a winner of an auction has to collect his nft if it couldn't be automatically collected
    uint256 constant winnerCollectionPeriod = 90 days;
    /// @notice 5% of auction_funds-facevalue go for reservation income
    uint256 public reserveIncomeRatio;
    /// @notice Reserves mapping (bidsListId => user_address => nftListId)
    mapping(uint256 => mapping(address => uint256)) public reservations;
    /// @notice Total on-bid reserves in a bidList (bidListId => count)
    mapping(uint256 => uint256) public reserveCount;
    /// @notice Mapping an nft to the round in which it was won (nftListId => round)
    mapping(uint256 => uint256) public roundInWhichNftWasWon;
    /// @notice Total on-bid reserves of a seller
    /// bidListId => seller => total_reserves
    mapping(uint256 => mapping(address => uint256))
        public sellerTotalGameReserves;
    /// @notice (bidListId => seller => did?)
    mapping(uint256 => mapping(address => bool))
        public didSellerCollectReserveIncome;
    /// @notice (bidListId => rewards in weth for nft sellers reserve income)
    mapping(uint256 => uint256) public totalReserveIncome;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

enum BidInfoStatus {
    Untouch,
    Valid,
    Invalid,
    Revoked
}

struct BidInfo {
    address bidder;
    uint256 nftListId;
    uint256 amount;
    uint256 bidAt;
    string cipher;
    bytes32 bidHash;
    BidInfoStatus status;
    bool isBonus;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

enum NFTInfoStatus {
    Active,
    Delisted,
    Withdrawn
}
struct NFTInfo {
    address nftAddress;
    uint256 nftId;
    NFTInfoStatus status;
    uint256 lastActiveBidList;
    uint256 listPrice;
    address owner;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./PoolBaseStructs.sol";

struct BidInfoSlim {
    address bidder;
    bytes32 bidHash;
    BidInfoStatus status;
}