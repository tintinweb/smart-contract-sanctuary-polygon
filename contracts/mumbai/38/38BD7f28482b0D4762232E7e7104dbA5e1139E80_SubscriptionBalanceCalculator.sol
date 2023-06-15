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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IApplicationNFT is IERC721Upgradeable {

    function NFT_Address() external view returns(address);
    
    function getBytes32OfRole(string memory _roleName)
    external
    pure
    returns (bytes32);
    
    function hasRole(uint _appId, bytes32 role, address account) external view returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IContractBasedDeployment {
    
    function getComputesOfSubnet(uint256 NFTid, uint256 subnetId) external view returns(uint32[] memory);

    function getActiveSubnetsOfNFT(
        uint256 nftID
    )
    external
    view
    returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IRegistration {
    struct SubnetAttributes {
        uint256 subnetType;
        bool sovereignStatus;
        uint256 cloudProviderType;
        bool subnetStatusListed;
        uint256[] unitPrices;
        uint256[] otherAttributes; // eg. [1,2]
        uint256 maxClusters;
        uint256 supportFeeRate; // 1000 = 1%
        uint256 stackFeesReqd;
    }

    struct Cluster {
        address ClusterDAO;
        string DNSIP;
        uint8 listed;
        uint NFTidLocked;
    }

    struct PriceChangeRequest {
        uint256 timestamp;
        uint256[] unitPrices;
    }

    function isClusterListed(uint256 subnetID, uint256 clusterID)
    external
    view
    returns(bool);

    function getClusterWalletAddress(uint256 subnetID, uint256 clusterID)
    external
    view
    returns(address);

    function getClusterCount(uint256 subnetID)
    external
    view
    returns(
        uint256
    );

    function getUnitPrices(uint256 subnetID)
    external
    view
    returns(
        uint256[] memory
    );

    function checkSubnetStatus1(uint256 subnetID)
    external
    view
    returns(bool);

    function checkSubnetStatus(uint256[] memory subnetList)
    external
    view
    returns(bool[] memory);

    function totalSubnets() external view returns (uint256);

    function subnetAttributes(uint256 _subnetId) external view returns(SubnetAttributes memory);

    function subnetClusters(uint256 _subnetId, uint256 _clusterId) external view returns(Cluster memory);

    function getSubnetAttributes(uint256 _subnetId) external view returns(uint256 subnetType, bool sovereignStatus, uint256 cloudProviderType, bool subnetStatusListed, uint256[] memory unitPrices, uint256[] memory otherAttributes, uint256 maxClusters, uint256 supportFeeRate, uint256 stackFeeReqd);

    function getClusterAttributes(uint256 _subnetId, uint256 _clusterId) external view returns(address ClusterDAO, string memory DNSIP, uint8 listed, uint NFTIdLocked);

    function subnetLocalDAO(uint256 subnetId) external view returns (address);

    function daoRate() external view returns (uint256);

    function hasPermissionToClusterList(uint256 subnetId, address user) external view returns (bool);

    function GLOBAL_DAO_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface ISubnetDAODistributor {

    function setSubnetRevenue(uint subnetId, uint revenue) external;
    function setClusterWeight(
        uint256 subnetID,
        uint256 clusterID,
        uint256 weight
    )
    external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface ISubscription {

    struct NFTAttribute {
        uint256 createTime;
        // address[] factorAddressList;
    }

    struct PlatformAddress {
        uint256 platformPercentage;
        uint256 discountPercentage;
        uint256 referralPercentage;
        uint256 referralExpiryDuration;
        bool active;
    }

    function PAUSER_ROLE()
    external
    view
    returns (bytes32);

    function getCreateTime(uint256 nftID)
    external
    view
    returns (uint256);

   function isBridgeRole()
    external
    view
    returns (bool);

    function getSubnetsOfNFT(
        uint256 nftID
    )
    external
    view
    returns(uint256[] memory);

    function getNFTSubscription(uint256 nftID)
    external
    view
    returns(NFTAttribute memory nftAttribute);

    function getPlatformFactors(address platformAddress)
    external
    view
    returns (
        PlatformAddress memory
    );

    function hasRole(bytes32 role, address account) external view returns(bool);

    function getSupportFeesForNFT(uint256 nftID, uint256 subnetID)
    view
    external
    returns (uint256 supportFee);

    function GLOBAL_DAO_ADDRESS() external view returns (address);

    function subscribe(
        uint256 nftID,
        address[] memory addressList,
        uint256[] memory licenseFactor
    ) external;

    function getLicenseFactor(uint256 nftID)
    external
    view
    returns (uint256[] memory);

    function getSupportFactor(uint256 nftID)
    external
    view
    returns (uint256[] memory);

    function getNFTFactorAddress(uint256 nftID, uint256 factorID)
    external
    view
    returns(address);


    function checkBridgeRole(address bridge)
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface ISubscriptionBalance {
    struct NFTBalance {
        uint256 lastBalanceUpdateTime;
        uint256[3] prevBalance; // prevBalance[0] = Credit wallet, prevBalance[1] = External Deposit, prevBalance[3] = Owner wallet
        uint256[] subnetIds; // cannot be changed unless delisted
        uint256 mintTime;
        uint256 endOfXCTBalance;
    }

    function getBalanceEndTime(uint256 nftID)
    external
    view
    returns(uint256);

    function nftBalances(uint256 nftId)
        external
        view
        returns (NFTBalance memory);

    function totalSubnets(uint256 nftId) external view returns (uint256);

    function ReferralPercent() external view returns (uint256);

    function ReferralRevExpirySecs() external view returns (uint256);

    function subscribeNew(
        uint256 nftID
    ) external;

    function addBalanceWithoutUpdate(address nftOwner, uint256 nftID, uint256 balanceToAdd)
    external;

    function addBalance(address nftOwner, uint256 nftID, uint256 _balanceToAdd)
        external
        returns (
            bool
        );

    function prevBalances(uint256 nftID)
        external
        view
        returns (uint256[3] memory);

    function updateBalance(uint256 _nftId) external;

    function updateBalanceImmediate(
        uint256 nftID
    )
    external;

    function addSubnetToNFT(uint256 _nftId, uint256 _subnetId)
        external
        returns (bool);


    function isBalancePresent(uint256 _nftId) external view returns (bool);

    function estimateUpdatedBalance(uint256 NFTid)
        external
        view
        returns (uint256[3] memory);

    function estimateTotalUpdatedBalance(uint256 NFTid)
        external
        view
        returns (uint256);
    
    function totalPrevBalance(uint256 nftID) external view returns (uint256);


    function addRevBalance(address account, uint256 balance)
    external;

    function receiveRevenue()
    external;

    function receiveRevenueForAddressBulk(address[] memory _userAddresses)
    external;

    function receiveRevenueForAddress(address _userAddress)
    external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./interfaces/ISubscriptionBalance.sol";
import "./interfaces/ISubnetDAODistributor.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./interfaces/IContractBasedDeployment.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IRegistration.sol";
import "./interfaces/ISubscription.sol";
import "./interfaces/IApplicationNFT.sol";

contract SubscriptionBalanceCalculator is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;


    IRegistration public RegistrationContract;
    ISubscription public SubscriptionContract;
    ISubscriptionBalance public SubscriptionBalance;
    ISubnetDAODistributor public SubnetDAODistributor;
    IContractBasedDeployment public AppDeployment;

    uint32 constant public PERCENT_COUNT = 6;
    uint32 constant public ADDR_ID_1 = 0;
    uint32 constant public ADDR_ID_R = 1;
    uint32 constant public ADDR_ID_S = 2;
    uint32 constant public ADDR_ID_T = 3;
    uint32 constant public ADDR_ID_U = 4;
    uint32 constant public ADDR_ID_V = 5;


    uint32 constant public DRF_ID_R1 = 0;
    uint32 constant public DRF_ID_R2 = 1;
    uint32 constant public DRF_ID_T1 = 2;
    uint32 constant public DRF_ID_T2 = 3;
    uint32 constant public DRF_ID_U = 4;
    uint32 constant public DRF_ID_V = 5;
    uint32 constant public DRF_ID_W = 6;

    uint256 public constant PLATFORM_ADDR_ID = 0;
    uint256 public constant SUPPORT_ADDR_ID = 1;
    uint256 public constant LICENSE_ADDR_ID = 2;
    uint256 public constant REFERRAL_ADDR_ID = 3;



    struct UpdateBalance {
        uint256 dripRate;
        uint256 spentBalance;
        uint256 computeCost;
        uint256 duration;
    }

    function initialize(
        IRegistration _RegistrationContract
    ) public initializer {
        __Ownable_init_unchained();
        RegistrationContract = _RegistrationContract;
    }

    modifier onlySubscriptionBalance() {
        require(
            address(SubscriptionBalance) == _msgSender(),
            "Only callable by SubBalance"
        );
        _;
    }

    function setSubscriptionContract(address _Subscription) external onlyOwner {
        SubscriptionContract = ISubscription(_Subscription);
    }

    function setSubscriptionBalanceContract(address _SubscriptionBalance)
        external
        onlyOwner
    {
        SubscriptionBalance = ISubscriptionBalance(_SubscriptionBalance);
    }

    function setSubnetDAODistributor(
        ISubnetDAODistributor _SubnetDAODistributor
    ) external onlyOwner {
        SubnetDAODistributor = _SubnetDAODistributor;
    }

    function setAppDeployment(
        IContractBasedDeployment _AppDeployment
    )
    external onlyOwner {
        AppDeployment = _AppDeployment;
    }

    function s_GlobalDAOAddress() public view returns (address) {
        return RegistrationContract.GLOBAL_DAO_ADDRESS();
    }


    function s_GlobalDAORate() public view returns (uint256) {
        return RegistrationContract.daoRate();
    }

    function dripRatePerSec(uint256 nftID)
        public
        view
        returns (uint256)
    {
        uint256[] memory subnetList = AppDeployment.getActiveSubnetsOfNFT(nftID);

        uint256 cost;
        for (uint256 i = 0; i < subnetList.length; i++)
        {
            uint32[] memory computeRequired = AppDeployment
            .getComputesOfSubnet(nftID, subnetList[i]);

            cost += getComputeCosts(subnetList[i], computeRequired, 1);
        }

        // ISubscription.NFTAttribute memory nftAttrib = SubscriptionContract.getNFTSubscription(nftID);
        ISubscription.PlatformAddress memory platformAttrib
            = SubscriptionContract.getPlatformFactors(SubscriptionContract.getNFTFactorAddress(nftID, PLATFORM_ADDR_ID));

        uint256 u_referralFactor = platformAttrib.referralPercentage;
        uint256[] memory t_supportFactor = SubscriptionContract.getSupportFactor(nftID);
        uint256 v_platformFactor = platformAttrib.platformPercentage;
        uint256 w_discountFactor = platformAttrib.discountPercentage;
        uint256[] memory r_licenseFactor = SubscriptionContract.getLicenseFactor(nftID);

        uint256 factor = s_GlobalDAORate()
            .add(t_supportFactor[0])
            .add(r_licenseFactor[0])
            .add(v_platformFactor)
            .add(u_referralFactor)
            .add(100000);

        if((SubscriptionContract.getNFTFactorAddress(nftID, REFERRAL_ADDR_ID) != address(0))
            && (SubscriptionContract.getCreateTime(nftID).add(platformAttrib.referralExpiryDuration) > block.timestamp)
        ) {
            factor = factor.sub(w_discountFactor);
        }

        if(cost == 0)
            return 0;

        return factor.mul(cost).div(100000) + r_licenseFactor[1] + t_supportFactor[1];
    }

    function dripRatePerSecOfSubnet(uint256 nftID, uint256 subnetID)
        public
        view
        returns (uint256)
    {

        uint32[] memory computeRequired = AppDeployment
        .getComputesOfSubnet(nftID, subnetID);

        uint256 cost = getComputeCosts(subnetID, computeRequired, 1);

        if(cost == 0)
            return 0;

        // ISubscription.NFTAttribute memory   = SubscriptionContract.getNFTSubscription(nftID);
        ISubscription.PlatformAddress memory platformAttrib
            = SubscriptionContract.getPlatformFactors(SubscriptionContract.getNFTFactorAddress(nftID, PLATFORM_ADDR_ID));

        uint256 u_referralFactor = platformAttrib.referralPercentage;
        uint256[] memory t_supportFactor = SubscriptionContract.getSupportFactor(nftID);
        uint256 v_platformFactor = platformAttrib.platformPercentage;
        uint256 w_discountFactor = platformAttrib.discountPercentage;
        uint256[] memory r_licenseFactor = SubscriptionContract.getLicenseFactor(nftID);

        uint256 factor = s_GlobalDAORate()
            .add(t_supportFactor[0])
            .add(r_licenseFactor[0])
            .add(v_platformFactor)
            .add(u_referralFactor)
            .add(100000);

        uint256 createTime = SubscriptionContract.getCreateTime(nftID);
        if( SubscriptionContract.getNFTFactorAddress(nftID, REFERRAL_ADDR_ID) != address(0) &&
            createTime.add(platformAttrib.referralExpiryDuration) > block.timestamp) {
            factor = factor.sub(w_discountFactor);
        }

        return factor.mul(cost).div(100000) + r_licenseFactor[1] + t_supportFactor[1];
    }


    function estimateDripRatePerSec (
        uint256[] calldata subnetList,
        uint256[] calldata dripFactor,
        uint32[][] calldata computeRequired
    )
    public
    view
    returns (uint256)
    {
        uint256 factor = s_GlobalDAORate()
            + dripFactor[DRF_ID_R1]
            + dripFactor[DRF_ID_T1]
            + dripFactor[DRF_ID_U]
            + dripFactor[DRF_ID_V]
            - dripFactor[DRF_ID_W]
            + 100000;

        uint256 cost;
        for(uint256 i = 0; i < subnetList.length ; i++)
        {
            cost += getComputeCosts(subnetList[i], computeRequired[i], 1);
        }


        if(cost == 0)
            return 0;
    
        return factor.mul(cost).div(100000) + dripFactor[DRF_ID_R2] + dripFactor[DRF_ID_T2];
    }

    function getComputeCosts(
        uint256 subnetID,
        uint32[] memory computeRequired,
        uint256 duration
    )
    public
    view
    returns (uint256 computeCost)
    {
        uint256 computeCostPerSec = 0;
        
        uint256[] memory unitPrices = RegistrationContract
            .getUnitPrices(subnetID);

        uint256 minLen = Math.min(unitPrices.length, computeRequired.length);
        for (uint256 j = 0; j < minLen; j++)
        {
            computeCostPerSec = computeCostPerSec.add(
                uint256(computeRequired[j]).mul(unitPrices[j])
            );
        }

        computeCost = computeCostPerSec.mul(
            duration
        );
    }

    function distributeAccumulatedRevenue(
        uint256 nftID,
        uint256 revenue,
        uint256 duration
    )
    public
    onlySubscriptionBalance
    returns (uint256)
    {
        uint cost;
        uint256 totalCost;

        ISubscription.NFTAttribute memory nftAttrib = SubscriptionContract.getNFTSubscription(nftID);
        ISubscription.PlatformAddress memory platformAttrib
            = SubscriptionContract.getPlatformFactors(SubscriptionContract.getNFTFactorAddress(nftID, PLATFORM_ADDR_ID));
        uint256 daoRate = s_GlobalDAORate();
        address daoAddress = s_GlobalDAOAddress();

        uint256[] memory supportFactor = SubscriptionContract.getSupportFactor(nftID);
        uint256[] memory licenseFactor = SubscriptionContract.getLicenseFactor(nftID);

        cost = revenue.mul(daoRate).div(100000);
        totalCost = totalCost.add(cost);
        SubscriptionBalance.addRevBalance(daoAddress, cost);


        cost = revenue.mul(licenseFactor[0]).div(100000);
        cost = cost.add(licenseFactor[1].mul(duration));
        totalCost = totalCost.add(cost);
        SubscriptionBalance.addRevBalance(SubscriptionContract.getNFTFactorAddress(nftID, LICENSE_ADDR_ID), cost);


        cost = revenue.mul(supportFactor[0]).div(100000);
        cost = cost.add(supportFactor[1].mul(duration));
        totalCost = totalCost.add(cost);
        SubscriptionBalance.addRevBalance(SubscriptionContract.getNFTFactorAddress(nftID, SUPPORT_ADDR_ID), cost);

        cost = revenue.mul(platformAttrib.referralPercentage).div(100000);
        totalCost = totalCost.add(cost);


        if (
            SubscriptionContract.getNFTFactorAddress(nftID, REFERRAL_ADDR_ID) != address(0) &&
            nftAttrib.createTime.add(platformAttrib.referralExpiryDuration) > block.timestamp)
        {
            SubscriptionBalance.addRevBalance(SubscriptionContract.getNFTFactorAddress(nftID, REFERRAL_ADDR_ID),
            cost);

            cost = revenue.mul(platformAttrib.platformPercentage 
                - platformAttrib.discountPercentage).div(100000);
            totalCost = totalCost.add(cost);
            // dripRate = dripRate.add(sendCost);
            SubscriptionBalance.addRevBalance(SubscriptionContract.getNFTFactorAddress(nftID, PLATFORM_ADDR_ID), cost);
        }
        else 
        {
            SubscriptionBalance.addRevBalance(daoAddress, cost);
            cost = revenue.mul(platformAttrib.platformPercentage).div(100000);
            totalCost = totalCost.add(cost);
            // dripRate = dripRate.add(sendCost);
            SubscriptionBalance.addRevBalance(SubscriptionContract.getNFTFactorAddress(nftID, PLATFORM_ADDR_ID), cost);
        }


        return totalCost;
    }

    function getUpdatedSubnetBalance(
        uint256 nftID,
        uint256 lastUpdateTime,
        uint256 totalBalance,
        uint256[] memory subnetList
    )
    internal
    onlySubscriptionBalance
    returns (uint256, uint256, uint256)
    {
        uint256 totalComputeCost;
        uint256[] memory computeCost = new uint256[](subnetList.length);

        for (uint256 i = 0; i < subnetList.length; i++)
        {
            uint32[] memory computeRequired = AppDeployment
            .getComputesOfSubnet(nftID, subnetList[i]);

            uint256 cost = getComputeCosts(subnetList[i], computeRequired, 1);
            computeCost[i] = cost;
            totalComputeCost += cost;
        }

        if(totalComputeCost == 0)
            return (0, 0, 0);
            // return updateBal;

        ISubscription.PlatformAddress memory platformAttrib;
        uint256 createTime = SubscriptionContract.getCreateTime(nftID);
        {
            address platformAddress = SubscriptionContract.getNFTFactorAddress(nftID, PLATFORM_ADDR_ID);
            platformAttrib
                = SubscriptionContract.getPlatformFactors(platformAddress);
        }
    

        if(createTime == 0)
            return (0, 0, 0);
            // return updateBal;


        uint256[] memory supportFactor = SubscriptionContract.getSupportFactor(nftID);
        uint256 dripRate;

        {
            uint256[] memory licenseFactor = SubscriptionContract.getLicenseFactor(nftID);
            dripRate = s_GlobalDAORate()
                .add(supportFactor[0])
                .add(licenseFactor[0])
                .add(platformAttrib.platformPercentage)
                .add(platformAttrib.referralPercentage)
                .add(100000);
            
            supportFactor[0] = licenseFactor[1];
        }

        
        if(SubscriptionContract.getNFTFactorAddress(nftID, REFERRAL_ADDR_ID) != address(0))
        {
            if(
                createTime.add(platformAttrib.referralExpiryDuration) > block.timestamp)
            {
                dripRate = dripRate.sub(platformAttrib.discountPercentage);
            }
        }


        dripRate = dripRate.mul(totalComputeCost).div(100000);
        // dripRate = dripRate.add(supportFactor[1]).add(licenseFactor[1]);
        dripRate = dripRate.add(supportFactor[1]).add(supportFactor[0]);


        createTime = totalBalance.div(dripRate);
        if((lastUpdateTime + createTime) > block.timestamp) {
            createTime = block.timestamp - lastUpdateTime;
        }

        if(createTime == 0)
            return (0, 0, 0);
            // return updateBal;

        for(uint i = 0; i < subnetList.length; i++)
        {
            uint256 curCost = computeCost[i].mul(createTime);

            SubnetDAODistributor.setSubnetRevenue(
                subnetList[i],
                curCost
            );
        }

        totalComputeCost = totalComputeCost.mul(createTime);
        dripRate = dripRate.mul(createTime);

        // SubscriptionBalance.addRevBalance(address(SubnetDAODistributor), totalComputeCost);
        // updateBal.dripRate = dripRate;
        // updateBal.spentBalance = dripRate.mul(createTime);
        // updateBal.computeCost = totalComputeCost;
        // updateBal.duration = createTime;

        return (dripRate, totalComputeCost, createTime);
    }

    function getUpdatedBalanceImmediate(
        uint256 nftID,
        uint256 lastUpdateTime,
        uint256 totalBalance
    )
    external
    onlySubscriptionBalance
    returns (uint256, uint256, uint256)
    {
        uint256[] memory subnetList = AppDeployment.getActiveSubnetsOfNFT(nftID);

        (uint256 totalCostIncurred, uint256 remCost, uint256 balanceDuration)
        // UpdateBalance memory updateBal
            = getUpdatedSubnetBalance(
                nftID,
                lastUpdateTime,
                totalBalance,
                subnetList
        );

        return (totalCostIncurred, remCost, balanceDuration);
        // return (updateBal.spentBalance, updateBal.computeCost, updateBal.duration);
        // return updateBal;
    }

    function getUpdatedBalance(
        uint256 nftID,
        uint256 lastUpdateTime,
        uint256 totalBalance,
        uint256 accumComputeCost,
        uint256 accumDuration
    )
    external
    onlySubscriptionBalance
    returns (uint256) 
    {
        uint256[] memory subnetList = AppDeployment.getActiveSubnetsOfNFT(nftID);

        (uint256 totalCostIncurred, uint256 remCost, uint256 balanceDuration) 
        // UpdateBalance memory updateBal
            = getUpdatedSubnetBalance(
                nftID,
                lastUpdateTime,
                totalBalance,
                subnetList
        );

        accumComputeCost += remCost;
        accumDuration += balanceDuration;
        // accumComputeCost += updateBal.computeCost;
        // accumDuration += updateBal.duration;
        
        distributeAccumulatedRevenue(
            nftID,
            accumComputeCost,
            accumDuration
        );

        return totalCostIncurred;
        // return updateBal.spentBalance;
    }
}