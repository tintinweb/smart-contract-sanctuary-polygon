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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

interface IOriumFactory {
    function isTrustedNft(address _nft) external view returns (bool);

    function isPlatformTrustedNft(address _nft, uint256 _platform) external view returns (bool);

    function isNftVault(address _nftVault) external view returns (bool);

    function getPlatformNftType(uint256 _platform, address _nft) external view returns (uint256);

    function rentalImplementationOf(address _nftAddress) external view returns (address);

    function getOriumAavegotchiSplitter() external view returns (address);

    function oriumFee() external view returns (uint256);

    function getPlatformTokens(uint256 _platformId) external view returns (address[] memory);

    function getVaultInfo(
        address _nftVault
    ) external view returns (uint256 platform, address owner);

    function getScholarshipManagerAddress() external view returns (address);

    function getOriumAavegotchiPettingAddress() external view returns (address);

    function getAavegotchiDiamondAddress() external view returns (address);

    function isSupportedPlatform(uint256 _platform) external view returns (bool);

    function supportsRentalOffer(address _nftAddress) external view returns (bool);

    function getPlatformSharesLength(uint256 _platform) external view returns (uint256[] memory);

    function getAavegotchiGHSTAddress() external view returns (address);

    function getOriumSplitterFactory() external view returns (address);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

enum NftState {
    NOT_DEPOSITED,
    IDLE,
    LISTED,
    BORROWED,
    CLAIMABLE
}

interface IOriumNftVault {
    function initialize(
        address _owner,
        address _factory,
        address _scholarshipManager,
        uint256 _platform
    ) external;

    function getNftState(address _nft, uint256 tokenId) external view returns (NftState _nftState);

    function isPausedForListing(address _nftAddress, uint256 _tokenId) external view returns (bool);

    function setPausedForListings(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds,
        bool[] memory _isPauseds
    ) external;

    function withdrawNfts(address[] memory _nftAddresses, uint256[] memory _tokenIds) external;

    function maxRentalPeriodAllowedOf(
        address _nftAddress,
        uint256 _tokenId
    ) external view returns (uint256);

    function setMaxAllowedRentalPeriod(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds,
        uint256[] memory _maxAllowedPeriods
    ) external;

    function programOf(address _nftAddress, uint256 _tokenId) external view returns (uint256);
}

interface INftVaultPlatform {
    function platform() external view returns (uint256);

    function owner() external view returns (address);

    function createRentalOffer(uint256 _tokenId, address _nftAddress, bytes memory data) external;

    function cancelRentalOffer(uint256 _tokenId, address _nftAddress) external;

    function endRental(address _nftAddress, uint256 _tokenId) external;

    function endRentalAndRelist(address _nftAddress, uint256 _tokenId, bytes memory data) external;

    function claimTokensOfRentals(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds
    ) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

interface IOriumSplitter {
    function initialize(
        address _oriumTreasury,
        address _guildOwner,
        uint256 _scholarshipProgramId,
        address _factory,
        uint256 _platformId,
        address _scholarshipManager,
        address _vaultAddress,
        address _vaultOwner
    ) external;

    function getSharesWithOriumFee(
        uint256[] memory _shares
    ) external view returns (uint256[] memory _sharesWithOriumFee);

    function split() external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

interface IOriumSplitterFactory {
    function deploySplitter(uint256 _programId, address _vaultAddress) external returns (address);

    function isValidSplitterAddress(address _splitter) external view returns (bool);

    function getPlatformSupportsSplitter(uint256 _platform) external view returns (bool);

    function splitterOf(uint256 _programId, address _vaultAddress) external view returns (address);

    function splittersOfVault(address _vaultAddress) external view returns (address[] memory);

    function splittersOfProgram(uint256 _programId) external view returns (address[] memory);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

interface IScholarshipManager {
    function platformOf(uint256 _programId) external view returns (uint256);

    function isProgram(uint256 _programId) external view returns (bool);

    function onDelegatedScholarshipProgram(
        address _owner,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _programId,
        uint256 _maxAllowedPeriod
    ) external;

    function onUnDelegatedScholarshipProgram(
        address owner,
        address nftAddress,
        uint256 tokenId
    ) external;

    function onPausedNft(address _owner, address _nftAddress, uint256 _tokenId) external;

    function onUnPausedNft(address _owner, address _nftAddress, uint256 _tokenId) external;

    function sharesOf(
        uint256 _programId,
        uint256 _eventId
    ) external view returns (uint256[] memory);

    function programOf(address _nftAddress, uint256 _tokenId) external view returns (uint256);

    function onTransferredGHST(address _vault, uint256 _amount) external;

    function ownerOf(uint256 _programId) external view returns (address);

    function vaultOf(
        address _nftAddress,
        uint256 _tokenId
    ) external view returns (address _vaultAddress);

    function isNftPaused(address _nftAddress, uint256 _tokenId) external view returns (bool);

    function onRentalEnded(
        address nftAddress,
        uint256 tokenId,
        address vaultAddress,
        uint256 programId
    ) external;

    function onRentalOfferCancelled(
        address nftAddress,
        uint256 tokenId,
        address vaultAddress,
        uint256 programId
    ) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IOriumFactory } from "./interface/IOriumFactory.sol";
import { IScholarshipManager } from "./interface/IScholarshipManager.sol";
import { IOriumNftVault, NftState } from "./interface/IOriumNftVault.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title  Orium Nft Vault
 * @notice is a contract that hold NFTs to be used in Orium Scholarships .
 * @dev This is a base contract.
 * @author Orium Network Team - [email protected]
 */
contract OriumNftVault is IOriumNftVault, Initializable, OwnableUpgradeable {
    // Vault Control Variables
    IOriumFactory public factory;
    IScholarshipManager public scholarshipManager;
    uint256 public platform;

    // Token Control Variables
    mapping(address => mapping(uint256 => bool)) internal _pausedNfts;
    mapping(address => mapping(uint256 => uint256)) internal _tokenToIdToMaxAllowedRentalPeriod;
    mapping(address => mapping(uint256 => uint256)) internal _tokenToIdToScholarshipProgram;

    event DepositedNfts(address indexed depositnftsor, address[] nftAddresses, uint256[] tokenIds);
    event WithdrewNfts(address indexed owner, address[] nftAddresses, uint256[] tokenIds);

    event PausedNft(address indexed owner, address indexed nftAddress, uint256 indexed tokenId);
    event UnPausedNft(address indexed owner, address indexed nftAddress, uint256 indexed tokenId);

    event DelegatedScholarshipProgram(
        address owner,
        address vaultAddress,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 indexed programId,
        uint256 maxAllowedPeriod
    );
    event UnDelegatedScholarshipProgram(
        address owner,
        address vaultAddress,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event MaxAllowedRentalPeriodChanged(
        address owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 maxAllowedPeriod
    );

    // Modifiers
    modifier onlyTrustedNFT(address _nftAddress) {
        require(
            factory.isPlatformTrustedNft(_nftAddress, platform),
            "OriumNftVault:: NFT is not trusted"
        );
        _;
    }

    modifier onlyScholarshipManager() {
        require(
            msg.sender == address(scholarshipManager),
            "OriumNftVault:: Only scholarshipManager can call this function"
        );
        _;
    }

    // External Functions
    /**
     * @notice initialize the contract
     * @param _owner the owner of the contract
     * @param _factory the Orium Factory contract address
     * @param _scholarshipManager the Orium Scholarships Manager contract address
     * @param _platform is the platform id
     */
    function initialize(
        address _owner,
        address _factory,
        address _scholarshipManager,
        uint256 _platform
    ) public virtual initializer {
        require(_owner != address(0), "OriumNftVault:: Invalid owner");
        require(_factory != address(0), "OriumNftVault:: Invalid factory");
        require(_scholarshipManager != address(0), "OriumNftVault:: Invalid scholarships manager");
        require(_platform != 0, "OriumNftVault:: Invalid platform");

        __Ownable_init();

        factory = IOriumFactory(_factory);
        platform = _platform;
        scholarshipManager = IScholarshipManager(_scholarshipManager);

        transferOwnership(_owner);
    }

    /**
     * @notice depositNfts NFTs to the contract
     * @param _nftAddresses is the array of NFT addresses
     * @param _tokenIds is the array of NFT token ids
     */
    function depositNfts(address[] memory _nftAddresses, uint256[] memory _tokenIds) external {
        require(_nftAddresses.length == _tokenIds.length, "OriumNftVault:: Invalid input");

        for (uint256 i = 0; i < _nftAddresses.length; i++) {
            _depositNfts(_nftAddresses[i], _tokenIds[i]);
        }

        emit DepositedNfts(msg.sender, _nftAddresses, _tokenIds);
    }

    function _depositNfts(
        address _nftAddress,
        uint256 _tokenId
    ) internal onlyTrustedNFT(_nftAddress) {
        address tokenOwner = IERC721(_nftAddress).ownerOf(_tokenId);
        require(msg.sender == tokenOwner, "OriumNftVault:: Only token owner can depositNfts");

        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);
    }

    /**
     * @notice withdrawNfts NFTs from the contract
     * @param _nftAddresses is the array of NFT addresses
     * @param _tokenIds is the array of NFT token ids
     */
    function withdrawNfts(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds
    ) public virtual override onlyOwner {
        for (uint256 i = 0; i < _nftAddresses.length; i++) {
            _withdrawNfts(_nftAddresses[i], _tokenIds[i]);
        }
        emit WithdrewNfts(msg.sender, _nftAddresses, _tokenIds);
    }

    function _withdrawNfts(
        address _nftAddress,
        uint256 _tokenId
    ) internal virtual onlyTrustedNFT(_nftAddress) {
        require(
            getNftState(_nftAddress, _tokenId) != NftState.BORROWED,
            "OriumNftVault:: Token is not withdrawable"
        );

        if (_pausedNfts[_nftAddress][_tokenId]) {
            delete _pausedNfts[_nftAddress][_tokenId];
            emit UnPausedNft(msg.sender, _nftAddress, _tokenId);
            scholarshipManager.onUnPausedNft(msg.sender, _nftAddress, _tokenId);
        }

        if (_tokenToIdToScholarshipProgram[_nftAddress][_tokenId] != 0) {
            delete _tokenToIdToScholarshipProgram[_nftAddress][_tokenId];
            emit UnDelegatedScholarshipProgram(msg.sender, address(this), _nftAddress, _tokenId);
            scholarshipManager.onUnDelegatedScholarshipProgram(msg.sender, _nftAddress, _tokenId);
        }
        delete _tokenToIdToMaxAllowedRentalPeriod[_nftAddress][_tokenId];

        IERC721(_nftAddress).transferFrom(address(this), msg.sender, _tokenId);
    }

    function withdrawTokens() public virtual onlyOwner {
        address[] memory tokens = factory.getPlatformTokens(platform);
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amount = IERC20(tokens[i]).balanceOf(address(this));
            if (amount > 0) {
                IERC20(tokens[i]).transfer(msg.sender, amount);
            }
        }
    }

    /**
     * @notice pause NFTs from the contrac
     * @dev this function is used to pause NFTs that are in a rental to prevent them from being rented again
     * @param _nftAddresses address of NFT
     * @param _tokenIds token id of NFT
     * @param _arePaused is the NFT paused or not
     */
    function setPausedForListings(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds,
        bool[] memory _arePaused
    ) public virtual override onlyOwner {
        require(
            _nftAddresses.length == _tokenIds.length && _nftAddresses.length == _arePaused.length,
            "OriumNftVault: Invalid input"
        );

        for (uint256 i = 0; i < _nftAddresses.length; i++) {
            _setPausedForListing(_nftAddresses[i], _tokenIds[i], _arePaused[i]);
        }
    }

    function _setPausedForListing(
        address _nftAddress,
        uint256 _tokenId,
        bool _isPaused
    ) internal onlyTrustedNFT(_nftAddress) {
        require(
            getNftState(_nftAddress, _tokenId) != NftState.NOT_DEPOSITED,
            "OriumNftVault:: Token is not deposited"
        );

        _pausedNfts[_nftAddress][_tokenId] = _isPaused;

        if (_isPaused) {
            emit PausedNft(msg.sender, _nftAddress, _tokenId);
            scholarshipManager.onPausedNft(msg.sender, _nftAddress, _tokenId);
        } else {
            emit UnPausedNft(msg.sender, _nftAddress, _tokenId);
            scholarshipManager.onUnPausedNft(msg.sender, _nftAddress, _tokenId);
        }
    }

    /**
     * @notice delegate a scholarship program to an NFT
     * @dev this function allow a scholarship program create,cancel or end rentals for an NFT that is delegated to it
     * @param _nftAddresses is the array of NFT addresses
     * @param _tokenIds is the array of NFT token ids
     * @param _programIds is the array of scholarship program ids
     * @param _maxAllowedRentalPeriods is the array of max allowed periods that the scholarship program can rent the NFT
     */
    function delegateScholarshipProgram(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds,
        uint256[] memory _programIds,
        uint256[] memory _maxAllowedRentalPeriods
    ) external onlyOwner {
        require(_nftAddresses.length == _tokenIds.length, "OriumNftVault:: Invalid input");
        require(_nftAddresses.length == _programIds.length, "OriumNftVault:: Invalid input");
        require(
            _nftAddresses.length == _maxAllowedRentalPeriods.length,
            "OriumNftVault:: Invalid input"
        );

        for (uint256 i = 0; i < _nftAddresses.length; i++) {
            _delegateScholarshipProgram(
                _nftAddresses[i],
                _tokenIds[i],
                _programIds[i],
                _maxAllowedRentalPeriods[i]
            );
        }
    }

    function _delegateScholarshipProgram(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _programId,
        uint256 _maxAllowedRentalPeriod
    ) internal virtual onlyTrustedNFT(_nftAddress) {
        require(
            getNftState(_nftAddress, _tokenId) != NftState.BORROWED &&
                getNftState(_nftAddress, _tokenId) != NftState.NOT_DEPOSITED,
            "OriumNftVault:: Token is borrowed or not deposited"
        );
        require(_maxAllowedRentalPeriod > 0, "OriumNftVault:: Invalid allowed period");
        require(
            scholarshipManager.isProgram(_programId),
            "OriumNftVault:: Invalid scholarship program"
        );
        require(
            scholarshipManager.platformOf(_programId) == platform,
            "OriumNftVault:: Invalid scholarship platform"
        );

        _tokenToIdToMaxAllowedRentalPeriod[_nftAddress][_tokenId] = _maxAllowedRentalPeriod;
        _tokenToIdToScholarshipProgram[_nftAddress][_tokenId] = _programId;

        if (_pausedNfts[_nftAddress][_tokenId]) {
            delete _pausedNfts[_nftAddress][_tokenId];
            emit UnPausedNft(msg.sender, _nftAddress, _tokenId);
            scholarshipManager.onUnPausedNft(msg.sender, _nftAddress, _tokenId);
        }

        emit DelegatedScholarshipProgram(
            msg.sender,
            address(this),
            _nftAddress,
            _tokenId,
            _programId,
            _maxAllowedRentalPeriod
        );
        scholarshipManager.onDelegatedScholarshipProgram(
            msg.sender,
            _nftAddress,
            _tokenId,
            _programId,
            _maxAllowedRentalPeriod
        );
    }

    /**
     * @notice un delegate a scholarship program from an NFT
     * @dev this function remove the delegation of a scholarship program from an NFT
     * @param _nftAddresses is the array of NFT addresses
     * @param _tokenIds is the array of NFT token ids
     */
    function unDelegateScholarshipProgram(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds
    ) external onlyOwner {
        require(_nftAddresses.length == _tokenIds.length, "OriumNftVault:: Invalid input");

        for (uint256 i = 0; i < _nftAddresses.length; i++) {
            _unDelegateScholarshipProgram(_nftAddresses[i], _tokenIds[i]);
        }
    }

    function _unDelegateScholarshipProgram(
        address _nftAddress,
        uint256 _tokenId
    ) internal virtual onlyTrustedNFT(_nftAddress) {
        require(
            getNftState(_nftAddress, _tokenId) != NftState.BORROWED &&
                getNftState(_nftAddress, _tokenId) != NftState.NOT_DEPOSITED,
            "OriumNftVault:: Token is borrowed or not deposited"
        );

        delete _tokenToIdToScholarshipProgram[_nftAddress][_tokenId];

        emit UnDelegatedScholarshipProgram(msg.sender, address(this), _nftAddress, _tokenId);

        scholarshipManager.onUnDelegatedScholarshipProgram(msg.sender, _nftAddress, _tokenId);
    }

    /**
     * @notice set the max allowed period for a scholarship program
     * @dev this function is used to set the max allowed period for a scholarship program, called only by the nft vault owner
     * @param _nftAddresses array of NFT addresses
     * @param _tokenIds array of NFT token ids
     * @param _maxAllowedRentalPeriods array of max allowed periods that the scholarship program can rent the NFT
     */

    function setMaxAllowedRentalPeriod(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds,
        uint256[] memory _maxAllowedRentalPeriods
    ) external onlyOwner {
        require(_nftAddresses.length == _tokenIds.length, "OriumNftVault:: Invalid input");
        require(
            _nftAddresses.length == _maxAllowedRentalPeriods.length,
            "OriumNftVault:: Invalid input"
        );

        for (uint256 i = 0; i < _nftAddresses.length; i++) {
            _setMaxAllowedRentalPeriod(_nftAddresses[i], _tokenIds[i], _maxAllowedRentalPeriods[i]);
        }
    }

    function _setMaxAllowedRentalPeriod(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _maxAllowedRentalPeriod
    ) internal onlyTrustedNFT(_nftAddress) {
        require(
            getNftState(_nftAddress, _tokenId) != NftState.NOT_DEPOSITED,
            "OriumNftVault:: Token is not deposited"
        );

        _tokenToIdToMaxAllowedRentalPeriod[_nftAddress][_tokenId] = _maxAllowedRentalPeriod;
        emit MaxAllowedRentalPeriodChanged(
            msg.sender,
            _nftAddress,
            _tokenId,
            _maxAllowedRentalPeriod
        );
    }

    // Internal Functions
    /**
     * @notice check if an NFT is paused for listing
     * @dev this function is used to check if an NFT is paused for listing
     * @param _nftAddress is the NFT address
     * @param _tokenId is the NFT token id
     */
    function isPausedForListing(address _nftAddress, uint256 _tokenId) public view returns (bool) {
        return _pausedNfts[_nftAddress][_tokenId];
    }

    /**
     * @notice get the NFT state
     * @param _nftAddress is the NFT address
     * @param _tokenId is the NFT token id
     * @return _nftState the NFT state
     */
    function getNftState(
        address _nftAddress,
        uint256 _tokenId
    ) public view virtual returns (NftState _nftState) {
        _nftState = IERC721(_nftAddress).ownerOf(_tokenId) == address(this)
            ? NftState.IDLE
            : NftState.NOT_DEPOSITED;
    }

    /**
     * @notice get max allowed period for a scholarship program
     * @dev this function is used to get max allowed period for a scholarship program
     * @param _nftAddress is the NFT address
     * @param _tokenId is the NFT token id
     */
    function maxRentalPeriodAllowedOf(
        address _nftAddress,
        uint256 _tokenId
    ) public view returns (uint256) {
        return _tokenToIdToMaxAllowedRentalPeriod[_nftAddress][_tokenId];
    }

    /**
     * @notice get the NFT scholarship program
     * @param _nftAddress is the NFT address
     * @param _tokenId is the NFT token id
     * @return _programId the NFT scholarship program
     */
    function programOf(address _nftAddress, uint256 _tokenId) public view returns (uint256) {
        return _tokenToIdToScholarshipProgram[_nftAddress][_tokenId];
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import { OriumNftVault } from "../base/OriumNftVault.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IOriumFactory } from "../base/interface/IOriumFactory.sol";
import { IOriumSplitterFactory } from "../base/interface/IOriumSplitterFactory.sol";
import { IComethSplitter } from "./interface/IComethSplitter.sol";
import { NftState } from "../base/interface/IOriumNftVault.sol";
import { IRentalProtocol } from "./interface/IRentalProtocol.sol";
import { LibComethNftVault } from "./libraries/LibComethNftVault.sol";

/**
 * @title Cometh Orium Nft Vault
 * @notice ComethNftVault is a contract that manages the NFTs of Cometh
 * to be used in the Orium Scholarships
 * @dev This contract is a child contract of OriumNftVault
 * @author Orium Network Team - [email protected]
 */
contract ComethNftVault is OriumNftVault {
    /**
     * @notice Function to create a rental offer
     * @dev This function is called by the Orium Scholarships Manager
     * @param _tokenId uint256 id of the NFT
     * @param _nftAddress address of the NFT contract
     * @param data bytes data to be passed to the NFT contract
     */
    function createRentalOffer(uint256 _tokenId, address _nftAddress, bytes memory data) external {
        LibComethNftVault.createRentalOffer(
            _tokenId,
            _nftAddress,
            data,
            address(factory),
            address(scholarshipManager),
            address(this)
        );
    }

    /**
     * @notice Function to cancel a rental offer
     * @dev This function is called by the Orium Scholarships Manager
     * @param _tokenId uint256 id of the NFT
     * @param _nftAddress address of the NFT contract
     */
    function cancelRentalOffer(uint256 _tokenId, address _nftAddress) external {
        LibComethNftVault.cancelRentalOffer(
            _tokenId,
            _nftAddress,
            address(factory),
            address(scholarshipManager)
        );
    }

    /**
     * @notice Function to end a rental
     * @dev This function is called by the Orium Scholarships Manager
     * @param _nftAddress address of the NFT contract
     * @param _tokenId uint256 id of the NFT
     */
    function endRental(address _nftAddress, uint256 _tokenId) external {
        LibComethNftVault.endRental(
            _nftAddress,
            _tokenId,
            address(factory),
            address(scholarshipManager)
        );
    }

    /**
     * @notice Function to end rental and relist the NFT
     * @dev This function is called by the Orium Scholarships Manager
     * @param _nftAddress address of the NFT contract
     * @param _tokenId uint256 id of the NFT
     * @param data bytes data to be passed to the NFT contract
     */
    function endRentalAndRelist(address _nftAddress, uint256 _tokenId, bytes memory data) external {
        LibComethNftVault.endRentalAndRelist(
            _nftAddress,
            _tokenId,
            data,
            address(factory),
            address(scholarshipManager),
            address(this)
        );
    }

    // Nft Vault Overrides
    function _delegateScholarshipProgram(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _programId,
        uint256 _maxAllowedRentalPeriod
    ) internal override onlyTrustedNFT(_nftAddress) onlyOwner {
        address _previousGuildSplitter = LibComethNftVault.getGuildSplitterOfNft(
            _nftAddress,
            _tokenId,
            address(factory),
            address(scholarshipManager)
        );

        if (_previousGuildSplitter != address(0)) {
            _unDelegateScholarshipProgram(_nftAddress, _tokenId);
        }

        super._delegateScholarshipProgram(
            _nftAddress,
            _tokenId,
            _programId,
            _maxAllowedRentalPeriod
        );

        address _guildSplitter = LibComethNftVault.getGuildSplitterOfProgram(
            _programId,
            address(factory)
        );

        if (_guildSplitter == address(0)) {
            address _splitterFactory = IOriumFactory(address(factory)).getOriumSplitterFactory();

            _guildSplitter = IOriumSplitterFactory(_splitterFactory).deploySplitter(
                _programId,
                address(this)
            );
        }

        IERC721(_nftAddress).transferFrom(address(this), _guildSplitter, _tokenId);
    }

    function _unDelegateScholarshipProgram(
        address _nftAddress,
        uint256 _tokenId
    ) internal override onlyTrustedNFT(_nftAddress) onlyOwner {
        uint256 _programId = programOf(_nftAddress, _tokenId);
        address _guildSplitter = LibComethNftVault.getGuildSplitterOfProgram(
            _programId,
            address(factory)
        );
        require(_guildSplitter != address(0), "ComethNftVault: Guild splitter not found");
        IComethSplitter(_guildSplitter).unDelegateNft(_nftAddress, _tokenId);

        super._unDelegateScholarshipProgram(_nftAddress, _tokenId);
    }

    function _withdrawNfts(
        address _nftAddress,
        uint256 _tokenId
    ) internal override onlyTrustedNFT(_nftAddress) {
        uint256 _programId = programOf(_nftAddress, _tokenId);
        if (_programId != 0) {
            address _guildSplitter = LibComethNftVault.getGuildSplitterOfProgram(
                _programId,
                address(factory)
            );
            IComethSplitter(_guildSplitter).unDelegateNft(_nftAddress, _tokenId);
        }

        super._withdrawNfts(_nftAddress, _tokenId);
    }

    function getNftState(
        address _nftAddress,
        uint256 _tokenId
    ) public view override returns (NftState) {
        return
            LibComethNftVault.getNftState(
                _nftAddress,
                _tokenId,
                address(factory),
                address(scholarshipManager)
            );
    }

    function withdrawEarnings(bytes memory _data) public onlyOwner {
        address[] memory _splitters = abi.decode(_data, (address[]));
        address _splitterFactory = IOriumFactory(address(factory)).getOriumSplitterFactory();

        for (uint256 i = 0; i < _splitters.length; i++) {
            require(
                IOriumSplitterFactory(_splitterFactory).isValidSplitterAddress(_splitters[i]),
                "OriumScholarshipManager:: Invalid splitter address"
            );
            IComethSplitter(_splitters[i]).split();
        }
    }

       /**
     * @notice Function to claim rental tokens without ending the rental
     * @dev This function can be called by anyone since the tokens always go to the respective beneficiaries
     * @param _nftAddresses address[] of the NFT contracts
     * @param _tokenIds uint256[] of the NFT ids
     */
    function claimTokensOfRentals(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds
    ) external {
        LibComethNftVault.claimTokensOfRentals(_nftAddresses, _tokenIds, address(factory), address(scholarshipManager));
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import { IOriumSplitter } from "../../base/interface/IOriumSplitter.sol";

interface IComethSplitter is IOriumSplitter {
    function createRentalOffer(
        uint256 _tokenId,
        address _nftAddress,
        uint64 _duration,
        uint256 _nonce,
        uint256 _feeAmount,
        uint256 _deadline,
        address _taker
    ) external;

    function cancelRentalOffer(uint256 _tokenId, address _nftAddress) external;

    function endRental(address _nftAddress, uint256 _tokenId) external;

    function endRentalAndRelist(
        address _nftAddress,
        uint256 _tokenId,
        uint64 _duration,
        uint256 _nonce,
        uint256 _feeAmount,
        uint256 _deadline,
        address _taker
    ) external;

    function unDelegateNft(address _nftAddress, uint256 _tokenId) external;

    function nonceOf(address _nftAddress, uint256 _tokenId) external view returns (uint256);

    function deadlineOf(uint256 _nonce) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title Rental Protocol
 *
 * @notice A rental can only begin when a `RentalOffer` has been created either on-chain (`preSignRentalOffer`)
 * or off-chain. When a rental is started (`rent`), a `LentNFT` and `BorrowedNFT` are minted and given
 * respectively to the lender and the tenant. A rental can be also sublet to a specific borrower, at the
 * choosing of the tenant.
 *
 *
 * Rental NFTs:
 * - `LentNFT`: anyone having one can reclaim the original NFT at the end of the rental
 * - `BorrowedNFT`: allowed the tenant to play the game and earn some rewards as if he owned the original NFT
 * - `SubLentNFT`: a sublender is given this NFT in order to reclaim the `BorrowedNFT` when the sublet ends
 */
interface IRentalProtocol {
    enum SignatureType {
        PRE_SIGNED,
        EIP_712,
        EIP_1271
    }
    struct Rental {
        uint256 end;
        uint256 lenderFee;
        uint256 sublenderFee;
    }
    struct RentalOffer {
        /// address of the user renting his NFTs
        address maker;
        /// address of the allowed tenant if private rental or `0x0` if public rental
        address taker;
        /// NFTs included in this rental offer
        NFT[] nfts;
        /// address of the ERC20 token for rental fees
        address feeToken;
        /// amount of the rental fee
        uint256 feeAmount;
        /// nonce
        uint256 nonce;
        /// until when the rental offer is valid
        uint256 deadline;
    }

    // guild -> manager -> vault -> splitter

    struct NFT {
        /// address of the contract of the NFT to rent
        address token;
        /// specific NFT to be rented
        uint256 tokenId;
        /// how long the rent should be
        uint64 duration;
        /// percentage of rewards for the lender, in basis points format
        uint16 basisPoints;
    }

    struct Fee {
        // fee collector
        address to;
        /// percentage of rewards for the lender or sublender, in basis points format
        uint256 basisPoints;
    }

    /**
     * @param nonce nonce of the rental offer
     * @param maker address of the user renting his NFTs
     * @param taker address of the allowed tenant if private rental or `0x0` if public rental
     * @param nfts details about each NFT included in the rental offer
     * @param feeToken address of the ERC20 token for rental fees
     * @param feeAmount amount of the upfront rental cost
     * @param deadline until when the rental offer is valid
     */
    event RentalOfferCreated(
        uint256 indexed nonce,
        address indexed maker,
        address taker,
        NFT[] nfts,
        address feeToken,
        uint256 feeAmount,
        uint256 deadline
    );
    /**
     * @param nonce nonce of the rental offer
     * @param maker address of the user renting his NFTs
     */
    event RentalOfferCancelled(uint256 indexed nonce, address indexed maker);

    /**
     * @param nonce nonce of the rental offer
     * @param lender address of the lender
     * @param tenant address of the tenant
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     * @param duration how long the NFT is rented
     * @param basisPoints percentage of rewards for the lender, in basis points format
     * @param start when the rent begins
     * @param end when the rent ends
     */
    event RentalStarted(
        uint256 indexed nonce,
        address indexed lender,
        address indexed tenant,
        address token,
        uint256 tokenId,
        uint64 duration,
        uint16 basisPoints,
        uint256 start,
        uint256 end
    );
    /**
     * @param lender address of the lender
     * @param tenant address of the tenant
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     */
    event RentalEnded(
        address indexed lender,
        address indexed tenant,
        address token,
        uint256 tokenId
    );

    /**
     * @param lender address of the lender
     * @param tenant address of the tenant
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     * @param basisPoints percentage of rewards for the sublender, in basis points format
     */
    event SubletStarted(
        address indexed lender,
        address indexed tenant,
        address token,
        uint256 tokenId,
        uint16 basisPoints
    );
    /**
     * @param lender address of the lender
     * @param tenant address of the tenant
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     */
    event SubletEnded(
        address indexed lender,
        address indexed tenant,
        address token,
        uint256 tokenId
    );

    /**
     * @param requester address of the first party (lender or tenant) requesting to end the rental prematurely
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     */
    event RequestToEndRentalPrematurely(
        address indexed requester,
        address indexed token,
        uint256 indexed tokenId
    );

    /**
     * @notice Link `originalNFT` to `lentNFT`, `borrowedNFT` and `subLentNFT`.
     * @param originalNFT address of the contract of the NFT to rent
     * @param lentNFT address of the `LentNFT` contract associated to `originalNFT`
     * @param borrowedNFT address of the `BorrowedNFT` contract associated to `originalNFT`
     * @param subLentNFT address of the `SubLentNFT` contract associated to `originalNFT`
     */
    event AssociatedNFTs(
        address originalNFT,
        address lentNFT,
        address borrowedNFT,
        address subLentNFT
    );

    event FeesCollectorChanged(address feeCollector);
    event FeesBasisPointsChanged(uint16 basisPoints);

    /**
     * @notice Create a new on-chain rental offer.
     * @notice In order to create a private offer, specify the `taker` address, otherwise use the `0x0` address
     * @dev When using pre-signed order, pass `SignatureType.PRE_SIGNED` as the `signatureType` for `rent`
     * @param offer the rental offer to store on-chain
     */
    function preSignRentalOffer(RentalOffer calldata offer) external;

    /**
     * @notice Cancel an on-chain rental offer.
     * @param nonce the nonce of the rental offer to cancel
     */
    function cancelRentalOffer(uint256 nonce) external;

    /**
     * @notice Start a rental between the `offer.maker` and `offer.taker`.
     * @param offer the rental offer
     * @param signatureType the signature type
     * @param signature optional signature when using `SignatureType.EIP_712` or `SignatureType.EIP_1271`
     * @dev `SignatureType.EIP_1271` is not yet supported, call will revert
     */
    function rent(
        RentalOffer calldata offer,
        SignatureType signatureType,
        bytes calldata signature
    ) external;

    /**
     * @notice End a rental when its duration is over.
     * @dev A rental can only be ended by the lender or the tenant.
     *      If there is a sublet it will be automatically ended.
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     */
    function endRental(address token, uint256 tokenId) external;

    /**
     * @notice End a rental *before* its duration is over.
     *         Doing so need both the lender and the tenant to call this function.
     * @dev If there is an ongoing sublet the call will revert.
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     */
    function endRentalPrematurely(address token, uint256 tokenId) external;

    /**
     * @notice Sublet a rental.
     * @dev Only a single sublet depth is allowed.
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     * @param subtenant address of whom the sublet is done for
     * @param basisPoints how many basis points the tenant keeps
     */
    function sublet(address token, uint256 tokenId, address subtenant, uint16 basisPoints) external;

    /**
     * @notice End a sublet. Can be called by the tenant / sublender at any time.
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     */
    function endSublet(address token, uint256 tokenId) external;

    /**
     * Fees table for a given `token` and `tokenId`.
     *
     * `pencentage` is not based on the rewards to be distributed, but the what these
     * specific users keeps for themselves.
     * If lender keeps 30% and tenant keeps 20%, the 20% are 20% of the remaining 70%.
     * This is stored as `3000` and `2000` and maths should be done accordingly at
     * rewarding time.
     *
     * @param token address of the contract of the NFT rented
     * @param tokenId tokenId of the rented NFT
     * @return fees table
     */
    function getFeesTable(address token, uint256 tokenId) external view returns (Fee[] memory);

    /**
     * @notice Set the address which will earn protocol fees.
     * @param feesCollector address collecting protocol fees
     */
    function setFeesCollector(address feesCollector) external;

    /**
     * @notice Set the protocol fee percentage as basis points.
     * @param basisPoints percentage of the protocol fee
     */
    function setFeesBasisPoints(uint16 basisPoints) external;

    function invalidNonce(address maker, uint256 nonce) external view returns (bool);

    function rentals(address token, uint256 tokenId) external view returns (Rental memory);

    function endRentalPrematurelyRequests(
        address token,
        uint256 tokenId
    ) external view returns (address);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import { IOriumNftVault, NftState, INftVaultPlatform } from "../../base/interface/IOriumNftVault.sol";
import { IOriumFactory } from "../../base/interface/IOriumFactory.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IRentalProtocol } from "../interface/IRentalProtocol.sol";
import { IScholarshipManager } from "../../base/interface/IScholarshipManager.sol";
import { IComethSplitter } from "../interface/IComethSplitter.sol";
import { IOriumSplitterFactory } from "../../base/interface/IOriumSplitterFactory.sol";

library LibComethNftVault {
    function onlyScholarshipManager(address _factory) public view {
        require(
            msg.sender == address(IOriumFactory(_factory).getScholarshipManagerAddress()),
            "OriumNftVault:: Only scholarshipManager can call this function"
        );
    }

    /**
     * @notice Function to create a rental offer
     * @dev This function is called by the Orium Scholarships Manager
     * @param _tokenId uint256 id of the NFT
     * @param _nftAddress address of the NFT contract
     * @param data bytes data to be passed to the NFT contract
     */
    function createRentalOffer(
        uint256 _tokenId,
        address _nftAddress,
        bytes memory data,
        address _factory,
        address _scholarshipManager,
        address _vault
    ) external {
        onlyScholarshipManager(_factory);
        require(
            getNftState(_nftAddress, _tokenId, _factory, _scholarshipManager) == NftState.IDLE,
            "ComethNftVault: NFT is not IDLE"
        );
        
        (
            uint64 _duration,
            uint256 _nonce,
            uint256 _feeAmount,
            uint256 _deadline,
            address _taker
        ) = abi.decode(data, (uint64, uint256, uint256, uint256, address));

        validateDurationAndDeadline(_duration, _deadline, _vault, _nftAddress, _tokenId);

        address _guildSplitter = getGuildSplitterOfNft(
            _nftAddress,
            _tokenId,
            _factory,
            _scholarshipManager
        );
        IComethSplitter(_guildSplitter).createRentalOffer(
            _tokenId,
            _nftAddress,
            _duration,
            _nonce,
            _feeAmount,
            _deadline,
            _taker
        );
    }

    /**
     * @notice Function to cancel a rental offer
     * @dev This function is called by the Orium Scholarships Manager
     * @param _tokenId uint256 id of the NFT
     * @param _nftAddress address of the NFT contract
     */
    function cancelRentalOffer(
        uint256 _tokenId,
        address _nftAddress,
        address _factory,
        address _scholarshipManager
    ) external {
        onlyScholarshipManager(_factory);
        // This is needed to not allow to cancel a expired rental offer
        require(
            getNftState(_nftAddress, _tokenId, _factory, _scholarshipManager) == NftState.LISTED,
            "ComethNftVault: NFT is not LISTED"
        );
        address _guildSplitter = getGuildSplitterOfNft(
            _nftAddress,
            _tokenId,
            _factory,
            _scholarshipManager
        );
        IComethSplitter(_guildSplitter).cancelRentalOffer(_tokenId, _nftAddress);
    }

    /**
     * @notice Function to end a rental
     * @dev This function is called by the Orium Scholarships Manager
     * @param _nftAddress address of the NFT contract
     * @param _tokenId uint256 id of the NFT
     */
    function endRental(
        address _nftAddress,
        uint256 _tokenId,
        address _factory,
        address _scholarshipManager
    ) external {
        onlyScholarshipManager(_factory);
        address _guildSplitter = getGuildSplitterOfNft(
            _nftAddress,
            _tokenId,
            _factory,
            _scholarshipManager
        );
        IComethSplitter(_guildSplitter).endRental(_nftAddress, _tokenId);
    }

    /**
     * @notice Function to end rental and relist the NFT
     * @dev This function is called by the Orium Scholarships Manager
     * @param _nftAddress address of the NFT contract
     * @param _tokenId uint256 id of the NFT
     * @param data bytes data to be passed to the NFT contract
     */
    function endRentalAndRelist(
        address _nftAddress,
        uint256 _tokenId,
        bytes memory data,
        address _factory,
        address _scholarshipManager,
        address _vault
    ) external {
        onlyScholarshipManager(_factory);
        (
            uint64 _duration,
            uint256 _nonce,
            uint256 _feeAmount,
            uint256 _deadline,
            address _taker
        ) = abi.decode(data, (uint64, uint256, uint256, uint256, address));

        validateDurationAndDeadline(_duration, _deadline, _vault, _nftAddress, _tokenId);

        address _guildSplitter = getGuildSplitterOfNft(
            _nftAddress,
            _tokenId,
            _factory,
            _scholarshipManager
        );
        IComethSplitter(_guildSplitter).endRentalAndRelist(
            _nftAddress,
            _tokenId,
            _duration,
            _nonce,
            _feeAmount,
            _deadline,
            _taker
        );
    }

    function getNftState(
        address _nftAddress,
        uint256 _tokenId,
        address _factory,
        address _scholarshipManager
    ) public view returns (NftState) {
        address _nftOwner = IERC721(_nftAddress).ownerOf(_tokenId);
        if (_nftOwner == address(this)) {
            return NftState.IDLE;
        }

        address _rentalImplementation = IOriumFactory(_factory).rentalImplementationOf(_nftAddress);
        if (_nftOwner == _rentalImplementation) {
            uint256 _end = IRentalProtocol(_rentalImplementation)
                .rentals(_nftAddress, _tokenId)
                .end;
            if (_end > block.timestamp) {
                address requester = IRentalProtocol(_rentalImplementation)
                    .endRentalPrematurelyRequests(_nftAddress, _tokenId);
                if (requester != address(0)) return NftState.CLAIMABLE;
                else return NftState.BORROWED;
            } else {
                return NftState.CLAIMABLE;
            }
        }

        address _guildSplitter = getGuildSplitterOfNft(
            _nftAddress,
            _tokenId,
            _factory,
            _scholarshipManager
        );
        if (_nftOwner == _guildSplitter) {
            uint256 _nonce = IComethSplitter(_guildSplitter).nonceOf(_nftAddress, _tokenId);
            bool _isInvalidNonce = IRentalProtocol(_rentalImplementation).invalidNonce(
                _guildSplitter,
                _nonce
            );
            if (_isInvalidNonce) {
                return NftState.IDLE;
            } else {
                uint256 _deadline = IComethSplitter(_guildSplitter).deadlineOf(_nonce);
                if (_deadline > block.timestamp) {
                    return NftState.LISTED;
                } else {
                    return NftState.IDLE;
                }
            }
        } else {
            return NftState.NOT_DEPOSITED;
        }
    }

    function getGuildSplitterOfNft(
        address _nftAddress,
        uint256 _tokenId,
        address _factory,
        address _scholarshipManager
    ) public view returns (address _guildSplitter) {
        uint256 _programId = IScholarshipManager(_scholarshipManager).programOf(
            _nftAddress,
            _tokenId
        );
        _guildSplitter = getGuildSplitterOfProgram(_programId, _factory);
    }

    function getGuildSplitterOfProgram(
        uint256 _programId,
        address _factory
    ) public view returns (address _guildSplitter) {
        address _splitterFactory = IOriumFactory(address(_factory)).getOriumSplitterFactory();

        _guildSplitter = IOriumSplitterFactory(_splitterFactory).splitterOf(
            _programId,
            address(this)
        );
    }

    function validateDurationAndDeadline(
        uint256 _duration,
        uint256 _deadline,
        address _vault,
        address _nftAddress,
        uint256 _tokenId
    ) public view {
        require(
            _duration <= IOriumNftVault(_vault).maxRentalPeriodAllowedOf(_nftAddress, _tokenId),
            "ComethNftVault: Rental period exceeds max allowed"
        );
        require(_deadline >= block.timestamp, "ComethNftVault: Deadline is in the past");
    }

     function claimTokensOfRentals(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds,
        address _factory,
        address _scholarshipManager
    ) public {
        require(
            _nftAddresses.length == _tokenIds.length,
            "LibComethNftVault:: Arrays must be equal"
        );
        address[] memory _guildSplitters = getUniqueSplitters(_nftAddresses, _tokenIds, _factory, _scholarshipManager);

        for (uint256 i = 0; i < _guildSplitters.length; i++) {
            IComethSplitter(_guildSplitters[i]).split();
        }
    }

    function validateAndFetchSplitter(
        address _nftAddress,
        uint256 _tokenId,
        address _factory,
        address _scholarshipManager
    ) public view returns (address _splitter) {
        uint256 nftTypeId = IOriumFactory(_factory).getPlatformNftType(
            INftVaultPlatform(address(this)).platform(),
            _nftAddress
        );
        require(nftTypeId != 0, "LibAavegotchiNftVault:: NFT is not trusted");
    
        uint256 _programId = IScholarshipManager(_scholarshipManager).programOf(
            _nftAddress,
            _tokenId
        );
        require(_programId != 0, "LibComethNftVault:: NFT is not delegated to a program");

        _splitter = getGuildSplitterOfProgram(_programId, _factory);
    }

    function getUniqueSplitters(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds,
        address _factory,
        address _scholarshipManager
    ) public view returns (address[] memory _uniqueSplitters) {

        _uniqueSplitters = new address[](_nftAddresses.length);
        _uniqueSplitters[0] = validateAndFetchSplitter(_nftAddresses[0], _tokenIds[0], _factory, _scholarshipManager);
        uint256 _uniqueSplittersLength = 1;

        for (uint256 i = 1; i < _nftAddresses.length; i++) {
            bool _isDuplicate = false;
            address _splitter = validateAndFetchSplitter(_nftAddresses[i], _tokenIds[i], _factory, _scholarshipManager);

            for (uint256 j = 0; j < _uniqueSplittersLength; j++) {
                if (_splitter == _uniqueSplitters[j]) {
                    _isDuplicate = true;
                    break;
                }
            }
            if (!_isDuplicate) {
                _uniqueSplitters[_uniqueSplittersLength] = _splitter;
                _uniqueSplittersLength++;
            }
        }

        assembly {
            // resize the array to the correct size (truncate the trailing zeros)
            mstore(_uniqueSplitters, _uniqueSplittersLength)
        }
    }
}