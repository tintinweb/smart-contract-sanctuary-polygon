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

pragma solidity ^0.8.7;

/**
 *  @notice An error used to indicate that an action could not be completed because either the `msg.sender` or
 *  `msg.origin` is not authorized.
 */
error Activator__Unauthorized();

// @notice An error used to indicate that an action could not be completed because of invalid amount zero entered.
error Activator__NotAllowedZeroValue();

// @notice An error used to indicate that an action could not be completed because of invalid amount entered.
error Activator__InvalidAmount();

/**
 * @notice An error used to indicate that an action could not be completed because the contract either already existed
 * or entered an illegal condition which is not recoverable from.
 */
error IllegalState();

error IllegalArgument();

error InValidUnlockTime();

//  {
//     facetAddress: '0xCaB046675853E2e69D4014690AE585d778a63E0B',
//     action: 0,
//     functionSelectors: [
//       '0xcdffacc6',
//       '0x52ef6b2c',
//       '0xadfca15e',
//       '0x7a0ed627',
//       '0x01ffc9a7',
//       contract: [Contract],
//       remove: [Function: remove],
//       get: [Function: get]
//     ]
//   },
//   {
//     // OwnershipFacet
//     facetAddress: '0x71dad5B6FDcA7814628c70BA1E09dE70408B3689',
//     action: 0,
//     functionSelectors: [
//       '0x8da5cb5b', ideal_warn_timed(uint256,uint128) owner()
//       '0xf2fde38b',
//       contract: [Contract],
//       remove: [Function: remove],
//       get: [Function: get]
//     ]
//   },
//   {
//     facetAddress: '0xfec5967FC85Bb039F1B352fCbAce2B014B312BE5',
//     action: 0,
//     functionSelectors: [
//       '0xc5e2d2a6',
//       '0x602631ef',
//       '0x3087944c',
//       '0x81d62ec9',
//       '0xee719bc8',
//       '0xffc9896b',
//       '0x485cc955',
//       '0xbedb86fb',
//       '0xb8b4e9fb',
//       contract: [Contract],
//       remove: [Function: remove],
//       get: [Function: get]
//     ]
//   },
//   {

//     // ControllerFacet
//     facetAddress: '0x10A9aEceec8B4b0777b45B1aaC82445F85dF2B49',
//     action: 0,
//     functionSelectors: [
//       '0x4019fb33',
//       '0x505398eb',
//       '0x8796d43d',
//       '0xe73264b4',
//       '0xf6371fb4',
//       '0xb93a5f3c',
//       '0xe6ad0a38',
//       '0x017123d0',
//       '0xf86ccd41',
//       '0x0d662a1f',
//       '0x03105b04', approveToken(address,address)
//       '0x7878d768',
//       '0x1f1e5ba5',
//       '0x3edd1128',
//       '0xc957352f',
//       '0xe52e43da',
//       '0x9ec89bad',
//       '0xcc2a9a5b',
//       '0x01b60ef2',
//       '0x7c32afe6',
//       '0x65ce1c8d',
//       '0x9be9afa8',
//       '0x13966db5',
//       '0xaf14052c',
//       '0x5d907379', rebaseOptIn(address)
//       '0xe6260307', rebaseOptOut(address)
//       '0x458f5815',
//       '0x57c90441', //
//       '0xfa00f36f',
//       '0x821b22c5', //
//       '0x91b32b32',
//       '0xdf12d2d9', //
//       '0x426be0e9',
//       '0xd4c3eea0',
//       '0x61d027b3', treasury()
//       '0x45b16a22',
//       '0xafef3b10',
//       '0x92545ca9',
//       '0x11c4b9cb',
//       '0xfbfa77cf',
//       '0xf3fef3a3',
//       '0x7dff0a6d',
//       '0xca092ce8',
//       contract: [Contract],
//       remove: [Function: remove],
//       get: [Function: get]
//     ]
//   },
//   {
//     // LockFacet
//     facetAddress: '0x8Acf72DD5Fd7F8b21998887735A4e6D4aA65636C',
//     action: 0,
//     functionSelectors: [
//       '0xfe4b84df',
//       '0x8da5cb5b', ideal_warn_timed(uint256,uint128) owner()
//       '0x251c1aa3',
//       '0x3ccfd60b',
//       contract: [Contract],
//       remove: [Function: remove],
//       get: [Function: get]
//     ]
//   },
//   {

//     facetAddress: '0xeca36a4D7D776C6106d13e245102C23e3b18434c',
//     action: 0,
//     functionSelectors: [
//       '0x41976e09',
//       '0x00e4768b',
//       '0x84ba3f69',
//       contract: [Contract],
//       remove: [Function: remove],
//       get: [Function: get]
//     ]
//   },
//   {
//     // SafeManagerFacet
//     facetAddress: '0x3A1693d5Ae55Dce45f20898E0435D2161859D6FC',
//     action: 0,
//     functionSelectors: [
//       '0xbc8acacf',
//       '0x298c4ef1',
//       '0xda52aa88',
//       '0xddb3c25a',
//       '0x35b7bb47',
//       '0xf2c0dfd4',
//       '0x55d12f03',
//       '0x992ff970',
//       '0x91d19e5c',
//       '0xb5d5d0d6',
//       '0x05632798',
//       '0x9ba45648',
//       '0xc4d66de8',
//       '0xdf800ccc',
//       '0x466d4d50',
//       '0x70aa44c9',
//       '0x741bef1a', priceFeed()
//       '0x5d907379', rebaseOptIn(address)
//       '0xe6260307', rebaseOptOut(address)
//       '0x457d1f2d',
//       '0x821b22c5', //
//       '0x9dda6348',
//       '0x1a48a6a1',
//       '0xdf12d2d9', //
//       '0x23c3cf14',
//       '0xdcda439b',
//       '0xf3466f96',
//       contract: [Contract],
//       remove: [Function: remove],
//       get: [Function: get]
//     ]
//   },
//   {
//     // SafeOperationsFacet
//     facetAddress: '0xf17fdC05CD1230fDe30802C395B09Fb931814FeF',
//     action: 0,
//     functionSelectors: [
//       '0x9da2a903',
//       '0x0be3cfb7',
//       '0x10f29204',
//       '0xc3108081',
//       '0x4448d486',
//       '0x1c228377',
//       '0x88c662aa',
//       '0xc0c53b8b',
//       '0x575c51c2',
//       '0x2fac0266',
//       '0xc0970c36',
//       '0xb8bb5c42',
//       '0x24cb725d',
//       '0x741bef1a',	priceFeed()
//       '0xd8aed145',
//       '0x57c90441', //
//       '0x821b22c5',
//       '0x7b7d6c68',
//       '0xdf12d2d9',//
//       '0xf0f44260',
//       '0x520082e0',
//       '0xf82bd179',
//       '0x01cc2a00',
//       '0x61d027b3', treasury()
//       '0x246adc8f',
//       contract: [Contract],
//       remove: [Function: remove],
//       get: [Function: get]
//     ]
//   },
//   {
//     // TreasuryFacet
//     facetAddress: '0x9296c108Ab39a43c3E78516618383687b1b6CeAb',
//     action: 0,
//     functionSelectors: [
//       '0xb864594e',
//       '0xe1d27d96',
//       '0x03105b04', approveToken(address,address)
//       '0xfd0aa031',
//       '0x8da5cb5b', ideal_warn_timed(uint256,uint128) owner()
//       '0x5d907379',rebaseOptIn(address)
//       '0xe6260307',rebaseOptOut(address)
//       '0x715018a6',
//       '0x821b22c5', //
//       '0xdf12d2d9', //
//       '0xf2fde38b',  transferOwnership(address)
//       contract: [Contract],
//       remove: [Function: remove],
//       get: [Function: get]
//     ]
//   }
// ]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import "../libraries/TokenUtils.sol";
import "../base/Error.sol";
import "../libraries/SafeCast.sol";
import "../libraries/AppStorage.sol";

/**
 * @title Activator
 * @notice A contract which facilitates the exchange of synthetic assets for their underlying
 * asset. This contract guarantees that synthetic assets are exchanged exactly 1:1
 * for the underlying asset.
 */

contract ActivatorFacet is Initializable, ReentrancyGuardUpgradeable {
    AppStorage s;

    // struct ActivatorAccount {
    //     // The total number of unexchanged tokens that an account has deposited into the system
    //     uint256 unexchangedBalance;
    //     // The total number of exchanged tokens that an account has had credited
    //     uint256 exchangedBalance;
    // }

    struct UpgradeActivatorAccount {
        // The owner address whose account will be modified
        address user;
        // The amount to change the account's unexchanged balance by
        int256 unexchangedBalance;
        // The amount to change the account's exchanged balance by
        int256 exchangedBalance;
    }

    /// @dev The amount of decimal places needed to normalize collateral to debtToken
    uint256 public conversionFactor;

    /**
     * @notice Emitted when the system is paused or unpaused.
     * @param flag `true` if the system has been paused, `false` otherwise.
     */
    event Paused(bool flag);

    event Deposit(address indexed user, uint256 unexchangedBalance);

    event Withdraw(
        address indexed user,
        uint256 unexchangedBalance,
        uint256 exchangedBalance
    );

    event Claim(
        address indexed user,
        uint256 unexchangedBalance,
        uint256 exchangedBalance
    );

    constructor() {}

    function initialize(address _syntheticToken, address _underlyingToken)
        external
        initializer
    {
        LibDiamond.enforceIsContractOwner();
        s.syntheticToken = _syntheticToken;
        s.underlyingToken = _underlyingToken;
        s.isPaused = false;
    }

    // @dev A modifier which checks whether the Activator is unpaused.
    modifier notPaused() {
        if (s.isPaused) {
            revert IllegalState();
        }
        _;
    }

    function setPause(bool pauseState) external {
        LibDiamond.enforceIsContractOwner();
        s.isPaused = pauseState;
        emit Paused(s.isPaused);
    }

    function depositSynthetic(uint256 amount) external nonReentrant {
        // IERC20(s.syntheticToken).approve(address(this), amount);
        _updateAccount(
            UpgradeActivatorAccount({
                user: msg.sender,
                unexchangedBalance: SafeCast.toInt256(amount),
                exchangedBalance: 0
            })
        );
        TokenUtils.safeTransferFrom(
            s.syntheticToken,
            msg.sender,
            address(this),
            amount
        );
        emit Deposit(msg.sender, amount);
    }

    function withdrawSynthetic(uint256 amount) external nonReentrant {
        _updateAccount(
            UpgradeActivatorAccount({
                user: msg.sender,
                unexchangedBalance: -SafeCast.toInt256(amount),
                exchangedBalance: 0
            })
        );
        TokenUtils.safeTransfer(s.syntheticToken, msg.sender, amount);
        emit Withdraw(
            msg.sender,
            s.accounts[msg.sender].unexchangedBalance,
            s.accounts[msg.sender].exchangedBalance
        );
    }

    function claimUnderlying(uint256 amount) external nonReentrant {
        _updateAccount(
            UpgradeActivatorAccount({
                user: msg.sender,
                unexchangedBalance: -SafeCast.toInt256(amount),
                exchangedBalance: SafeCast.toInt256(amount)
            })
        );
        TokenUtils.safeTransfer(s.underlyingToken, msg.sender, amount);
        TokenUtils.safeBurn(s.syntheticToken, amount);
        emit Claim(
            msg.sender,
            s.accounts[msg.sender].unexchangedBalance,
            s.accounts[msg.sender].exchangedBalance
        );
    }

    function _updateAccount(UpgradeActivatorAccount memory param) internal {
        ActivatorAccount storage _account = s.accounts[param.user];
        int256 updateUnexchange = int256(_account.unexchangedBalance) +
            param.unexchangedBalance;
        int256 updateExchange = int256(_account.exchangedBalance) +
            param.exchangedBalance;
        if (updateUnexchange < 0 || updateExchange < 0) {
            revert IllegalState();
        }
        _account.unexchangedBalance = uint256(updateUnexchange);
        _account.exchangedBalance = uint256(updateExchange);
    }

    function getSyntheticToken() external view returns (address) {
        return s.syntheticToken;
    }

    function getUnderlyingToken() external view returns (address) {
        return s.underlyingToken;
    }

    function getUserData(address user)
        external
        view
        returns (uint256, uint256)
    {
        ActivatorAccount storage _account = s.accounts[user];
        uint256 unexchange = _account.unexchangedBalance;
        uint256 exchange = _account.exchangedBalance;
        return (unexchange, exchange);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

/**
 * @title Activated Stoa Token Interface
 * @author stoa.money
 * @notice
 *  Interface that provides functions for interacting with activated Stoa tokens.
 */
interface IActivated {
    function mint(address _account, uint _amount) external;

    function burn(address _account, uint _amount) external;

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint _value
    ) external returns (bool);

    function convertToAssets(uint _creditBalance) external view returns (uint);

    function convertToCredits(uint _tokenBalance) external view returns (uint);

    function changeSupply(uint _newTotalSupply) external;

    function rebaseOptIn() external;

    function rebaseOptOut() external;

    function rebasingCreditsPerToken() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title  IERC20Burnable
/// @author Forked from https://github.com/alchemix-finance/v2-foundry/blob/master/src/interfaces/IERC20Burnable.sol
interface IERC20Burnable is IERC20 {
    /// @notice Burns `amount` tokens from the balance of `msg.sender`.
    ///
    /// @param amount The amount of tokens to burn.
    ///
    /// @return If burning the tokens was successful.
    function burn(uint256 amount) external returns (bool);

    /// @notice Burns `amount` tokens from `owner`'s balance.
    ///
    /// @param owner  The address to burn tokens from.
    /// @param amount The amount of tokens to burn.
    ///
    /// @return If burning the tokens was successful.
    function burnFrom(address owner, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ERC4626 Interface
 * @author yearn.finance
 */
interface IERC4626 is IERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    function asset() external view returns (address);

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver)
        external
        returns (uint256 shares); /* {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }*/

    /**
     * @dev Addition for depositing on behalf of depositor.
     */
    function deposit(
        uint256 assets,
        address receiver,
        address depositor
    ) external returns (uint256 shares);

    function mint(uint256 shares, address receiver)
        external
        returns (uint256 assets); /* {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }*/

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares); /* {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }*/

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets); /* {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }*/

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256); /* {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }*/

    function convertToAssets(uint256 shares) external view returns (uint256); /* {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }*/

    function previewDeposit(uint256 assets) external view returns (uint256); /* {
        return convertToShares(assets);
    }*/

    function previewMint(uint256 shares) external view returns (uint256); /* {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }*/

    function previewWithdraw(uint256 assets) external view returns (uint256); /* {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }*/

    function previewRedeem(uint256 shares) external view returns (uint256); /* {
        return convertToAssets(shares);
    }*/

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) external view returns (uint256); /* {
        return type(uint256).max;
    }*/

    function maxMint(address) external view returns (uint256); /* {
        return type(uint256).max;
    }*/

    function maxWithdraw(address owner) external view returns (uint256); /* {
        return convertToAssets(balanceOf[owner]);
    }*/

    function maxRedeem(address owner) external view returns (uint256); /* {
        return balanceOf[owner];
    }*/

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/
    /*
    function beforeWithdraw(uint256 assets, uint256 shares) internal {}

    function afterDeposit(uint256 assets, uint256 shares) internal {}
    */
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

interface ISafeManager {
    function getSafeInit(address _owner, uint _index)
        external
        view
        returns (
            address,
            address,
            address
        );

    function getSafeVal(address _owner, uint _index)
        external
        view
        returns (
            uint,
            uint,
            uint,
            uint
        );

    function getSafeStatus(address _owner, uint _index)
        external
        view
        returns (uint);

    function initializeSafe(
        address _owner,
        address _activeToken,
        uint _amount,
        // Leave fees for now, however not part of demo
        uint _mintFeeApplied,
        uint _redemptionFeeApplied
    ) external;

    function adjustSafeBal(
        address _owner,
        uint _index,
        uint _amount,
        // uint _mintFeeApplied,
        // uint _redemptionFeeApplied,
        bool _add
    ) external;

    function adjustSafeDebt(
        address _owner,
        uint _index,
        address _debtToken,
        uint _amount,
        uint _fee,
        bool _add
    ) external;

    function setSafeStatus(
        address _owner,
        uint _index,
        address _activeToken,
        uint _num
    ) external;

    function initializeBorrow(
        address _owner,
        uint _index,
        // address _activeToken,
        // uint _toLock,
        address _debtToken
        // uint _amount,
        // uint _fee
    ) external;

    function getActiveToDebtTokenMCR(address _activeToken, address _debtToken)
        external
        view
        returns (uint _MCR);

    function getUnactiveCounterpart(address _activeToken)
        external
        view
        returns (address unactiveToken);

    function getActivePool(address _token)
        external
        view
        returns (address activePool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

interface ITreasury {
    function adjustAPTokenBal(address _activePool, uint _amount) external;

    function adjustBackingReserve(
        address _wildToken,
        address _backingToken,
        int _amount
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

/**
 * @title Unactivated Stoa Token Interface
 * @author stoa.money
 * @notice
 *  Interface that provides functions for interacting with unactivated Stoa tokens.
 */
interface IUnactivated {
    function mint(address _to, uint _amount) external;

    function burn(address _from, uint _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../interfaces/IERC4626.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IActivated.sol";
import "../interfaces/IUnactivated.sol";
import "../interfaces/ISafeManager.sol";

struct ActivatorAccount {
    // The total number of unexchanged tokens that an account has deposited into the system
    uint256 unexchangedBalance;
    // The total number of exchanged tokens that an account has had credited
    uint256 exchangedBalance;
}

// struct UpgradeActivatorAccount {
//     // The owner address whose account will be modified
//     address user;
//     // The amount to change the account's unexchanged balance by
//     int256 unexchangedBalance;
//     // The amount to change the account's exchanged balance by
//     int256 exchangedBalance;
// }

struct AppStorage {
    //Activator Facet
    // @dev the synthetic token to be exchanged
    address syntheticToken;
    // @dev the underlyinToken token to be received
    address underlyingToken;
    // @dev contract pause state
    bool isPaused;
    mapping(address => ActivatorAccount) accounts;
    // ControllerFacet
    address safeManager;
    // /**
    //  * @notice
    //  *  Collects fees, backing tokens (+ yield) and
    //  *  liquidation gains.
    //  *  Allocates as necessary (e.g., depositing USDST backing
    //  *  tokens into the Curve USDST AcivePool).
    //  */
    address treasury;
    address activeToken;
    address unactiveToken;
    address inputToken;
    // PriceFeedFacet
    mapping(address => uint) tokenPrice;
    // SafeOperationsFacet

    mapping(address => address) tokenToController;
    /**
     * @dev
     *  Later use for self-repaying loan logic.
     */
    mapping(address => bool) isActiveToken;
    mapping(address => address) activeToInputToken;
    mapping(address => uint) originationFeesCollected;
    // TreasuryFacet

    /**
     * @notice Amount of apTokens of a given ActivePool owned by the Treasury.
     */
    mapping(address => mapping(address => int)) backingReserve;
    mapping(address => uint) apTokens;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(
    address _initializationContractAddress,
    bytes _calldata
);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress)
        internal
    {
        enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(
            _init,
            "LibDiamondCut: _init address has no code"
        );
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IllegalArgument} from "../base/Error.sol";

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        if (y >= 2**255) {
            revert IllegalArgument();
        }
        z = int256(y);
    }

    /// @notice Cast a int256 to a uint256, revert on underflow
    /// @param y The int256 to be casted
    /// @return z The casted integer, now type uint256
    function toUint256(int256 y) internal pure returns (uint256 z) {
        if (y < 0) {
            revert IllegalArgument();
        }
        z = uint256(y);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IERC20Burnable.sol";

/// @title  TokenUtils
/// @author Forked From https://github.com/alchemix-finance/v2-foundry/blob/master/src/libraries/TokenUtils.sol
library TokenUtils {
    /// @notice An error used to indicate that a call to an ERC20 contract failed.
    ///
    /// @param target  The target address.
    /// @param success If the call to the token was a success.
    /// @param data    The resulting data from the call. This is error data when the call was not a success. Otherwise,
    ///                this is malformed data when the call was a success.
    error ERC20CallFailed(address target, bool success, bytes data);

    /// @dev A safe function to get the decimals of an ERC20 token.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
    ///
    /// @param token The target token.
    ///
    /// @return The amount of decimals of the token.
    function expectDecimals(address token) internal view returns (uint8) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );

        if (token.code.length == 0 || !success || data.length < 32) {
            revert ERC20CallFailed(token, success, data);
        }

        return abi.decode(data, (uint8));
    }

    /// @dev Gets the balance of tokens held by an account.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
    ///
    /// @param token   The token to check the balance of.
    /// @param account The address of the token holder.
    ///
    /// @return The balance of the tokens held by an account.
    function safeBalanceOf(address token, address account)
        internal
        view
        returns (uint256)
    {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, account)
        );

        if (token.code.length == 0 || !success || data.length < 32) {
            revert ERC20CallFailed(token, success, data);
        }

        return abi.decode(data, (uint256));
    }

    /// @dev Transfers tokens to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer failed or returns an unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransfer(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount)
        );

        if (
            token.code.length == 0 ||
            !success ||
            (data.length != 0 && !abi.decode(data, (bool)))
        ) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Approves tokens for the smart contract.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the approval fails or returns an unexpected value.
    ///
    /// @param token   The token to approve.
    /// @param spender The contract to spend the tokens.
    /// @param value   The amount of tokens to approve.
    function safeApprove(
        address token,
        address spender,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, spender, value)
        );

        if (
            token.code.length == 0 ||
            !success ||
            (data.length != 0 && !abi.decode(data, (bool)))
        ) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Transfer tokens from one address to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer fails or returns an unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param owner     The address of the owner.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransferFrom(
        address token,
        address owner,
        address recipient,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                owner,
                recipient,
                amount
            )
        );

        if (
            token.code.length == 0 ||
            !success ||
            (data.length != 0 && !abi.decode(data, (bool)))
        ) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Burns tokens.
    ///
    /// Reverts with a `CallFailed` error if execution of the burn fails or returns an unexpected value.
    ///
    /// @param token  The token to burn.
    /// @param amount The amount of tokens to burn.
    function safeBurn(address token, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20Burnable.burn.selector, amount)
        );

        if (
            token.code.length == 0 ||
            !success ||
            (data.length != 0 && !abi.decode(data, (bool)))
        ) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Burns tokens from its total supply.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the burn fails or returns an unexpected value.
    ///
    /// @param token  The token to burn.
    /// @param owner  The owner of the tokens.
    /// @param amount The amount of tokens to burn.
    function safeBurnFrom(
        address token,
        address owner,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20Burnable.burnFrom.selector,
                owner,
                amount
            )
        );

        if (
            token.code.length == 0 ||
            !success ||
            (data.length != 0 && !abi.decode(data, (bool)))
        ) {
            revert ERC20CallFailed(token, success, data);
        }
    }
}