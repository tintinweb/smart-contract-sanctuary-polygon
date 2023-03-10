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

import { OriumNftVault } from "../base/OriumNftVault.sol";
import { IGotchiLendingFacet } from "./interface/IGotchiLendingFacet.sol";
import { LibAavegotchiNftVault } from "./libraries/LibAavegotchiNftVault.sol";
import { IOriumNftVault, NftState } from "../base/interface/IOriumNftVault.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IOriumAavegotchiSplitter, WithdrawVoucher, SignatureData } from "./interface/IOriumAavegotchiSplitter.sol";
import { ILendingGetterAndSetterFacet } from "./interface/ILendingGetterAndSetterFacet.sol";
import { IOriumAavegotchiPetting } from "./interface/IOriumAavegotchiPetting.sol";

/**
 * @title Aavegotchi Orium Nft Vault
 * @notice AavegotchiNftVault is a contract that manages the NFTs of Aavegotchis
 * to be used in the Orium Scholarships .
 * @dev This contract is a child contract of OriumNftVault.
 * @author Orium Network Team - [email protected]
 */
contract AavegotchiNftVault is OriumNftVault {
    mapping(bytes32 => bool) public isContentSigned;

    /**
     * @dev Initialize the contract with Orium Aavegotchi Petting as Operator for all gotchis
     * @param _owner address of the owner of the contract
     * @param _factory address of the Orium factory
     * @param _scholarshipManager address of the orium scholarships manager address
     * @param _platform uint256 id of the platform
     */
    function initialize(
        address _owner,
        address _factory,
        address _scholarshipManager,
        uint256 _platform
    ) public override initializer {
        super.initialize(_owner, _factory, _scholarshipManager, _platform);
        address _aavegotchiDiamond = factory.getAavegotchiDiamondAddress();
        address _oriumAavegotchiPetting = factory.getOriumAavegotchiPettingAddress();
        if (block.chainid != 80001) {
            ILendingGetterAndSetterFacet(_aavegotchiDiamond).setPetOperatorForAll(
                _oriumAavegotchiPetting,
                true
            );
            IOriumAavegotchiPetting(_oriumAavegotchiPetting).enablePetOperator();
        }
    }

    //Scholarship Manager functions
    /**
     * @notice Function to create a rental offer
     * @dev This function is called by the Orium Scholarships Manager
     * @param _tokenId uint256 id of the NFT
     * @param _nftAddress address of the NFT contract
     * @param data bytes data to be passed to the NFT contract
     */
    function createRentalOffer(uint256 _tokenId, address _nftAddress, bytes memory data) external {
        LibAavegotchiNftVault.createRentalOffer(
            _tokenId,
            _nftAddress,
            data,
            address(factory),
            address(this)
        );
    }

    /**
     * @notice Function to cancel a rental offer
     * @dev This function is called by the Orium Scholarships Manager
     * @param _tokenId uint256 id of the NFT
     * @param _nftAddress address of the NFT contract
     */
    function cancelRentalOffer(uint256 _tokenId, address _nftAddress) public {
        LibAavegotchiNftVault.cancelRentalOffer(
            _tokenId,
            _nftAddress,
            address(factory),
            address(this)
        );
    }

    /**
     * @notice Function to end a rental
     * @dev This function is called by the Orium Scholarships Manager
     * @param _nftAddress address of the NFT contract
     * @param _tokenId uint256 id of the NFT
     */
    function endRental(address _nftAddress, uint256 _tokenId) external {
        LibAavegotchiNftVault.endRental(
            _nftAddress,
            uint32(_tokenId),
            address(factory),
            address(this)
        );
    }

    /**
     * @notice Function to end rental and relist the NFT
     * @dev This function is called by the Orium Scholarships Manager
     * @param _nftAddress address of the NFT contract
     * @param _tokenId uint256 id of the NFT
     */
    function endRentalAndRelist(
        address _nftAddress,
        uint256 _tokenId,
        bytes memory _data
    ) external {
        LibAavegotchiNftVault.endRentalAndRelist(
            _nftAddress,
            uint32(_tokenId),
            address(factory),
            address(this),
            _data
        );
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
        LibAavegotchiNftVault.claimTokensOfRentals(_nftAddresses, _tokenIds, address(factory));
    }

    /**
     * @notice Function to claim tokens in splitter contract and withdrawNfts them
     * @dev This function is called by the Nft Vault owner
     * @param _voucher WithdrawVoucher struct
     * @param _signature SignatureData struct
     */
    function withdrawAndClaimSplitterTokens(
        WithdrawVoucher calldata _voucher,
        SignatureData calldata _signature
    ) external onlyOwner {
        LibAavegotchiNftVault.claimTokens(_voucher, _signature, factory);
        withdrawTokens();
    }

    // Nft Vault Overrides
    /**
     * @notice look parent function for more details
     */
    function withdrawNfts(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds
    ) public virtual override onlyOwner {
        LibAavegotchiNftVault.transferPendingGHSTBalance(factory, address(this));
        require(_nftAddresses.length == _tokenIds.length, "OriumNftVault:: Invalid input");

        for (uint256 i = 0; i < _nftAddresses.length; i++) {
            uint256 nftTypeId = factory.getPlatformNftType(platform, _nftAddresses[i]);
            if (nftTypeId == LibAavegotchiNftVault.NFT_TYPE_AAVEGOTCHI) {
                LibAavegotchiNftVault.recoverAavegotchiIfPossible(
                    _nftAddresses[i],
                    _tokenIds[i],
                    address(factory),
                    address(this)
                );
            }
            _withdrawNfts(_nftAddresses[i], _tokenIds[i]);
        }

        emit WithdrewNfts(msg.sender, _nftAddresses, _tokenIds);
    }

    /**
     * @notice look parent function for more details
     */
    function getNftState(
        address _nftAddress,
        uint256 _tokenId
    )
        public
        view
        virtual
        override(OriumNftVault)
        onlyTrustedNFT(_nftAddress)
        returns (NftState _nftState)
    {
        _nftState = LibAavegotchiNftVault.getNftState(
            _nftAddress,
            _tokenId,
            platform,
            address(factory)
        );
    }

    /**
     * @notice Sign content to be verified by ERC-1271
     */
    function signMessage(bytes32 _hash) external onlyOwner {
        isContentSigned[_hash] = true;
    }

    /**
     * @notice ERC-1271 function to check if a hash has been signed by this contract.
     * Even though the parameter "_signature" is not used, it is required by the ERC-1271 standard.
     * @param _hash bytes32 hash of the content
     * @param _signature bytes signature of the content
     */
    function isValidSignature(
        bytes32 _hash,
        bytes memory _signature
    ) public view returns (bytes4 magicValue_) {
        if (isContentSigned[_hash]) {
            magicValue_ = 0x1626ba7e;
        } else {
            magicValue_ = 0xffffffff;
        }
    }

    function _unDelegateScholarshipProgram(
        address _nftAddress,
        uint256 _tokenId
    ) internal override onlyTrustedNFT(_nftAddress) {
        if (
            factory.getPlatformNftType(platform, _nftAddress) ==
            LibAavegotchiNftVault.NFT_TYPE_AAVEGOTCHI
        ) {
            LibAavegotchiNftVault.recoverAavegotchiIfPossible(
                _nftAddress,
                _tokenId,
                address(factory),
                address(this)
            );
        }
        NftState nftState = getNftState(_nftAddress, _tokenId);
        require(
            nftState != NftState.BORROWED && nftState != NftState.NOT_DEPOSITED,
            "OriumNftVault:: Token is borrowed or not deposited"
        );

        delete _tokenToIdToScholarshipProgram[_nftAddress][_tokenId];

        emit UnDelegatedScholarshipProgram(msg.sender, address(this), _nftAddress, _tokenId);

        scholarshipManager.onUnDelegatedScholarshipProgram(msg.sender, _nftAddress, _tokenId);
    }

    function _delegateScholarshipProgram(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _programId,
        uint256 _maxAllowedRentalPeriod
    ) internal override onlyTrustedNFT(_nftAddress) {
        if (
            factory.getPlatformNftType(platform, _nftAddress) ==
            LibAavegotchiNftVault.NFT_TYPE_AAVEGOTCHI
        ) {
            LibAavegotchiNftVault.recoverNftIfPossible(
                _nftAddress,
                _tokenId,
                address(factory),
                address(this)
            );
        }
        NftState nftState = getNftState(_nftAddress, _tokenId);
        require(
            nftState != NftState.BORROWED && nftState != NftState.NOT_DEPOSITED,
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
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

interface IGotchiLendingFacet {
    // @param _erc721TokenId The identifier of the NFT to lend
    // @param _initialCost The lending fee of the aavegotchi in $GHST
    // @param _period The lending period of the aavegotchi, unit: second
    // @param _revenueSplit The revenue split of the lending, 3 values, sum of the should be 100
    // @param _originalOwner The account for original owner, can be set to another address if the owner wishes to have profit split there.
    // @param _thirdParty The 3rd account for receive revenue split, can be address(0)
    // @param _whitelistId The identifier of whitelist for agree lending, if 0, allow everyone
    struct AddGotchiListing {
        uint32 tokenId;
        uint96 initialCost;
        uint32 period;
        uint8[3] revenueSplit;
        address originalOwner;
        address thirdParty;
        uint32 whitelistId;
        address[] revenueTokens;
    }

    // @notice Allow aavegotchi lenders (msg sender) or their lending operators to add request for lending
    // @dev If the lending request exist, cancel it and replaces it with the new one
    // @dev If the lending is active, unable to cancel
    function addGotchiListing(AddGotchiListing memory p) external;

    // @notice Allow a borrower to agree an lending for the NFT
    // @dev Will throw if the NFT has been lent or if the lending has been canceled already
    // @param _listingId The identifier of the lending to agree
    function agreeGotchiLending(
        uint32 _listingId,
        uint32 _erc721TokenId,
        uint96 _initialCost,
        uint32 _period,
        uint8[3] calldata _revenueSplit
    ) external;

    function cancelGotchiLending(uint32 _listingId) external;

    function claimGotchiLending(uint32 _tokenId) external;

    function claimAndEndGotchiLending(uint32 _tokenId) external;

    function claimAndEndAndRelistGotchiLending(uint32 _tokenId) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.9;

import { AavegotchiInfo, GotchiLending, LendingOperatorInputs } from "../libraries/LibAavegotchiStorage.sol";

interface ILendingGetterAndSetterFacet {
    event GotchiLendingAdded(
        uint32 indexed listingId,
        address indexed lender,
        uint32 indexed tokenId,
        uint96 initialCost,
        uint32 period,
        uint8[3] revenueSplit,
        address originalOwner,
        address thirdParty,
        uint32 whitelistId,
        address[] revenueTokens,
        uint256 timeCreated
    );
    event GotchiLendingExecuted(
        uint32 indexed listingId,
        address indexed lender,
        address indexed borrower,
        uint32 tokenId,
        uint96 initialCost,
        uint32 period,
        uint8[3] revenueSplit,
        address originalOwner,
        address thirdParty,
        uint32 whitelistId,
        address[] revenueTokens,
        uint256 timeAgreed
    );
    event GotchiLendingCanceled(
        uint32 indexed listingId,
        address indexed lender,
        uint32 indexed tokenId,
        uint96 initialCost,
        uint32 period,
        uint8[3] revenueSplit,
        address originalOwner,
        address thirdParty,
        uint32 whitelistId,
        address[] revenueTokens,
        uint256 timeCanceled
    );
    event GotchiLendingClaimed(
        uint32 indexed listingId,
        address indexed lender,
        address indexed borrower,
        uint32 tokenId,
        uint96 initialCost,
        uint32 period,
        uint8[3] revenueSplit,
        address originalOwner,
        address thirdParty,
        uint32 whitelistId,
        address[] revenueTokens,
        uint256[] amounts,
        uint256 timeClaimed
    );
    event GotchiLendingEnded(
        uint32 indexed listingId,
        address indexed lender,
        address indexed borrower,
        uint32 tokenId,
        uint96 initialCost,
        uint32 period,
        uint8[3] revenueSplit,
        address originalOwner,
        address thirdParty,
        uint32 whitelistId,
        address[] revenueTokens,
        uint256 timeEnded
    );

    /// @notice Enable or disable approval for a third party("operator") to help pet LibMeta.msgSender()'s gotchis
    ///@dev Emits the PetOperatorApprovalForAll event
    ///@param _operator Address to disable/enable as a pet operator
    ///@param _approved True if operator is approved,False if approval is revoked

    function setPetOperatorForAll(address _operator, bool _approved) external;

    // @notice Get an aavegotchi lending details through an identifier
    // @dev Will throw if the lending does not exist
    // @param _listingId The identifier of the lending to query
    // @return listing_ A struct containing certain details about the lending like timeCreated etc
    // @return aavegotchiInfo_ A struct containing details about the aavegotchi
    function getGotchiLendingListingInfo(uint32 _listingId) external view returns (GotchiLending memory listing_, AavegotchiInfo memory aavegotchiInfo_);

    // @notice Get an ERC721 lending details through an identifier
    // @dev Will throw if the lending does not exist
    // @param _listingId The identifier of the lending to query
    // @return listing_ A struct containing certain details about the ERC721 lending like timeCreated etc
    function getLendingListingInfo(uint32 _listingId) external view returns (GotchiLending memory listing_);

    // @notice Get an aavegotchi lending details through an NFT
    // @dev Will throw if the lending does not exist
    // @param _erc721TokenId The identifier of the NFT associated with the lending
    // @return listing_ A struct containing certain details about the lending associated with an NFT of contract identifier `_erc721TokenId`
    function getGotchiLendingFromToken(uint32 _erc721TokenId) external view returns (GotchiLending memory listing_);

    function getGotchiLendingIdByToken(uint32 _erc721TokenId) external view returns (uint32);

    function isAavegotchiLent(uint32 _erc721TokenId) external view returns (bool);

    function isAavegotchiListed(uint32 _erc721TokenId) external view returns (bool);

    function aavegotchiClaimTime(uint256 _tokenId) external view returns (uint256 claimTime_);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

interface IOriumAavegotchiPetting {
    // @notice Enable this contract to pet all msg.sender aavegotchis
    // @dev Emits EnablePetOperator
    function enablePetOperator() external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

struct WithdrawVoucher {
    address recipient;
    address[] tokens;
    uint256[] amounts;
    uint256 userNonce;
}

struct SignatureData {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

interface IOriumAavegotchiSplitter {
    function withdraw(WithdrawVoucher calldata voucher, SignatureData calldata signature)
        external;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.9;

interface IRealmGettersAndSettersFacet {
    event ParcelAccessRightSet(uint256 _realmId, uint256 _actionRight, uint256 _accessRight);
    event ParcelWhitelistSet(uint256 _realmId, uint256 _actionRight, uint256 _whitelistId);

    function setParcelsAccessRightWithWhitelists(
        uint256[] calldata _realmIds,
        uint256[] calldata _actionRights,
        uint256[] calldata _accessRights,
        uint32[] calldata _whitelistIds
    ) external;

    function getParcelsAccessRights(uint256[] calldata _parcelIds, uint256[] calldata _actionRights) external view returns (uint256[] memory output_);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGotchiLendingFacet } from "../interface/IGotchiLendingFacet.sol";
import { ILendingGetterAndSetterFacet } from "../interface/ILendingGetterAndSetterFacet.sol";
import { IOriumNftVault, NftState, INftVaultPlatform } from "../../base/interface/IOriumNftVault.sol";
import { IOriumFactory } from "../../base/interface/IOriumFactory.sol";
import { IRealmGettersAndSettersFacet } from "../interface/IRealmGettersAndSettersFacet.sol";
import { GotchiLending } from "../libraries/LibAavegotchiStorage.sol";
import { IOriumAavegotchiSplitter, WithdrawVoucher, SignatureData } from "../interface/IOriumAavegotchiSplitter.sol";
import { IScholarshipManager } from "../../base/interface/IScholarshipManager.sol";

import { LibAavegotchiNftVaultExtension } from "./LibAavegotchiNftVaultExtension.sol";

library LibAavegotchiNftVault {
    uint256 public constant NFT_TYPE_AAVEGOTCHI = 1;
    uint256 public constant NFT_TYPE_LAND = 2;
    uint256 public constant CHANNELING = 0;
    uint256 public constant EMPTY_RESERVOIR = 1;

    function onlyScholarshipManager(address _factory) public view {
        require(
            msg.sender == address(IOriumFactory(_factory).getScholarshipManagerAddress()),
            "OriumNftVault:: Only scholarshipManager can call this function"
        );
    }

    function transferPendingGHSTBalance(IOriumFactory factory, address vault) public {
        IScholarshipManager _scholarshipManager = IScholarshipManager(
            factory.getScholarshipManagerAddress()
        );
        IERC20 _ghst = IERC20(factory.getAavegotchiGHSTAddress());
        if (address(_ghst) == address(0)) return;
        uint256 _ghstBalance = _ghst.balanceOf(vault);
        if (_ghstBalance <= 0) return;
        address _splitter = factory.getOriumAavegotchiSplitter();
        _ghst.transfer(_splitter, _ghstBalance);
        _scholarshipManager.onTransferredGHST(vault, _ghstBalance);
    }

    function createRentalOffer(
        uint256 _tokenId,
        address _nftAddress,
        bytes memory data,
        address _factory,
        address _nftVault
    ) external {
        onlyScholarshipManager(_factory);
        transferPendingGHSTBalance(IOriumFactory(_factory), _nftVault);
        uint256 nftTypeId = IOriumFactory(_factory).getPlatformNftType(
            INftVaultPlatform(address(_nftVault)).platform(),
            _nftAddress
        );
        require(nftTypeId != 0, "LibAavegotchiNftVault:: NFT is not trusted");
        require(
            IOriumNftVault(_nftVault).isPausedForListing(_nftAddress, _tokenId) == false,
            "LibAavegotchiNftVault:: NFT is paused for listing"
        );

        if (nftTypeId == NFT_TYPE_AAVEGOTCHI) {
            _createAavegotchiNftRentalOffer(_tokenId, _nftAddress, data, _factory, _nftVault);
        } else if (nftTypeId == NFT_TYPE_LAND) {
            _createLandRentalOffer(_tokenId, _nftAddress, data, _factory);
        } else {
            revert("LibAavegotchiNftVault:: NFT is not trusted");
        }
    }

    function cancelRentalOffer(
        uint256 _tokenId,
        address _nftAddress,
        address _factory,
        address _nftVault
    ) public {
        onlyScholarshipManager(_factory);
        transferPendingGHSTBalance(IOriumFactory(_factory), _nftVault);
        uint256 nftTypeId = IOriumFactory(_factory).getPlatformNftType(
            INftVaultPlatform(address(_nftVault)).platform(),
            _nftAddress
        );
        require(nftTypeId != 0, "LibAavegotchiNftVault:: NFT is not trusted");

        if (nftTypeId == NFT_TYPE_AAVEGOTCHI) {
            _cancelAavegotchiListing(_nftAddress, uint32(_tokenId), _factory);
        } else if (nftTypeId == NFT_TYPE_LAND) {
            _cancelLandRental(_nftAddress, _tokenId, _factory);
        } else {
            revert("LibAavegotchiNftVault:: NFT is not trusted");
        }
    }

    function endRental(
        address _nftAddress,
        uint32 _tokenId,
        address _factory,
        address _nftVault
    ) public {
        onlyScholarshipManager(_factory);
        transferPendingGHSTBalance(IOriumFactory(_factory), _nftVault);
        uint256 nftTypeId = IOriumFactory(_factory).getPlatformNftType(
            INftVaultPlatform(address(_nftVault)).platform(),
            _nftAddress
        );
        require(nftTypeId != 0, "LibAavegotchiNftVault:: NFT is not trusted");

        if (nftTypeId == NFT_TYPE_AAVEGOTCHI) {
            _claimAndEndGotchiLending(_nftAddress, _tokenId, _factory);
        } else if (nftTypeId == NFT_TYPE_LAND) {
            _cancelLandRental(_nftAddress, _tokenId, _factory);
        } else {
            revert("LibAavegotchiNftVault:: NFT is not trusted");
        }
    }

    function endRentalAndRelist(
        address _nftAddress,
        uint32 _tokenId,
        address _factory,
        address _nftVault,
        bytes memory _data
    ) external {
        onlyScholarshipManager(_factory);
        transferPendingGHSTBalance(IOriumFactory(_factory), _nftVault);
        address _rentalImplementation = IOriumFactory(_factory).rentalImplementationOf(_nftAddress);
        require(
            _rentalImplementation != address(0),
            "LibAavegotchiNftVault:: NFT is not supported"
        );

        uint256 nftTypeId = IOriumFactory(_factory).getPlatformNftType(
            INftVaultPlatform(address(_nftVault)).platform(),
            _nftAddress
        );
        require(nftTypeId != 0, "LibAavegotchiNftVault:: NFT is not trusted");

        if (nftTypeId == NFT_TYPE_AAVEGOTCHI) {
            if (_data.length == 0) {
                IGotchiLendingFacet(_rentalImplementation).claimAndEndAndRelistGotchiLending(
                    _tokenId
                );
            } else {
                IGotchiLendingFacet(_rentalImplementation).claimAndEndGotchiLending(_tokenId);
                _createAavegotchiNftRentalOffer(_tokenId, _nftAddress, _data, _factory, _nftVault);
            }
        } else if (nftTypeId == NFT_TYPE_LAND) {
            _cancelLandRental(_nftAddress, _tokenId, _factory);
            _createLandRentalOffer(_tokenId, _nftAddress, _data, _factory);
        } else {
            revert("LibAavegotchiNftVault:: NFT is not trusted");
        }
    }

    function claimTokens(
        WithdrawVoucher calldata _voucher,
        SignatureData calldata _signature,
        IOriumFactory _factory
    ) external {
        address splitter = _factory.getOriumAavegotchiSplitter();
        IOriumAavegotchiSplitter(splitter).withdraw(_voucher, _signature);
    }

    function claimTokensOfRentals(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds,
        address _factory
    ) public {
        require(
            _nftAddresses.length == _tokenIds.length,
            "LibAavegotchiNftVault:: Arrays must be equal"
        );
        for (uint256 i = 0; i < _nftAddresses.length; i++) {
            claimTokensOfRental(_nftAddresses[i], _tokenIds[i], _factory);
        }
    }

    function claimTokensOfRental(address _nftAddress, uint256 _tokenId, address _factory) public {
        uint256 nftTypeId = IOriumFactory(_factory).getPlatformNftType(
            INftVaultPlatform(address(this)).platform(),
            _nftAddress
        );
        require(nftTypeId != 0, "LibAavegotchiNftVault:: NFT is not trusted");

        address rentalImplementation = IOriumFactory(_factory).rentalImplementationOf(_nftAddress);
        require(rentalImplementation != address(0), "LibAavegotchiNftVault:: NFT is not supported");
        IGotchiLendingFacet(rentalImplementation).claimGotchiLending(uint32(_tokenId));
    }

    function recoverNftIfPossible(
        address _nftAddress,
        uint256 _tokenId,
        address _factory,
        address _nftVault
    ) public {
        uint256 nftTypeId = IOriumFactory(_factory).getPlatformNftType(
            INftVaultPlatform(address(_nftVault)).platform(),
            _nftAddress
        );

        if (nftTypeId == NFT_TYPE_AAVEGOTCHI) {
            recoverAavegotchiIfPossible(_nftAddress, _tokenId, _factory, _nftVault);
        } else if (nftTypeId == NFT_TYPE_LAND) {
            recoverLandIfPossible(_nftAddress, _tokenId, _factory, _nftVault);
        } else {
            revert("LibAavegotchiNftVault:: NFT is not trusted");
        }
    }

    function recoverAavegotchiIfPossible(
        address _nftAddress,
        uint256 _tokenId,
        address _factory,
        address _nftVault
    ) public {
        NftState nftState = IOriumNftVault(_nftVault).getNftState(_nftAddress, _tokenId);
        uint32 tokenId = uint32(_tokenId);
        address _scholarshipManager = IOriumFactory(_factory).getScholarshipManagerAddress();
        uint256 _programId = IOriumNftVault(_nftVault).programOf(_nftAddress, _tokenId);

        if (nftState == NftState.CLAIMABLE) {
            _claimAndEndGotchiLending(_nftAddress, tokenId, _factory);
            /**
             * @dev carefully consider the impacts before deleting the line above!
             * @dev this event is needed for subgraph
             */
            IScholarshipManager(_scholarshipManager).onRentalEnded(
                _nftAddress,
                tokenId,
                _nftVault,
                _programId
            );
        } else if (nftState == NftState.LISTED) {
            _cancelAavegotchiListing(_nftAddress, tokenId, _factory);
            /**
             * @dev carefully consider the impacts before deleting the line above!
             * @dev this event is needed for subgraph
             */
            IScholarshipManager(_scholarshipManager).onRentalOfferCancelled(
                _nftAddress,
                tokenId,
                _nftVault,
                _programId
            );
        }
    }

    function recoverLandIfPossible(
        address _nftAddress,
        uint256 _tokenId,
        address _factory,
        address _nftVault
    ) public {
        NftState nftState = IOriumNftVault(_nftVault).getNftState(_nftAddress, _tokenId);

        if (nftState == NftState.CLAIMABLE) {
            address _scholarshipManager = IOriumFactory(_factory).getScholarshipManagerAddress();
            uint256 _programId = IOriumNftVault(_nftVault).programOf(_nftAddress, _tokenId);

            _cancelLandRental(_nftAddress, _tokenId, _factory);
            /**
             * @dev carefully consider the impacts before deleting the line above!
             * @dev this event is needed for subgraph
             */
            IScholarshipManager(_scholarshipManager).onRentalEnded(
                _nftAddress,
                _tokenId,
                _nftVault,
                _programId
            );
        }
    }

    // Private Functions
    function _createAavegotchiNftRentalOffer(
        uint256 _tokenId,
        address _nftAddress,
        bytes memory data,
        address _factory,
        address _nftVault
    ) internal {
        uint96 initialCost;
        uint32 period;
        uint32 whitelistId;
        address thirdPartyAddress;
        address[] memory alchemicaTokens;
        uint8[3] memory shares;

        (initialCost, period, whitelistId) = abi.decode(data, (uint96, uint32, uint32));

        (thirdPartyAddress, alchemicaTokens, shares) = LibAavegotchiNftVaultExtension
            .getAavegotchiListingHelpers(_factory, _nftVault, _nftAddress, _tokenId);

        require(
            period <= IOriumNftVault(_nftVault).maxRentalPeriodAllowedOf(_nftAddress, _tokenId),
            "LibAavegotchiNftVault:: NFT is not allowed to be rented for this period"
        );

        IGotchiLendingFacet.AddGotchiListing memory listing = _createValidAavegotchiListingStruct(
            _tokenId,
            initialCost,
            period,
            whitelistId,
            _nftVault,
            _factory,
            thirdPartyAddress,
            alchemicaTokens,
            shares
        );

        _createAavegotchiListing(_nftAddress, listing, _factory);
    }

    function _createLandRentalOffer(
        uint256 _tokenId,
        address _nftAddress,
        bytes memory data,
        address _factory
    ) internal {
        (
            uint256 _channellingAccessRight,
            uint256 _emptyReservoirAccessRight,
            uint32 _channellingWhitelistId,
            uint32 _emptyReservoirWhitelistId
        ) = abi.decode(data, (uint256, uint256, uint32, uint32));

        _createLandRental(
            _nftAddress,
            _tokenId,
            _channellingAccessRight,
            _emptyReservoirAccessRight,
            _channellingWhitelistId,
            _emptyReservoirWhitelistId,
            _factory
        );
    }

    function _createAavegotchiListing(
        address _nftAddress,
        IGotchiLendingFacet.AddGotchiListing memory listing,
        address factory
    ) public {
        address rentalImplementation = IOriumFactory(factory).rentalImplementationOf(_nftAddress);
        IGotchiLendingFacet(rentalImplementation).addGotchiListing(listing);
    }

    function _cancelAavegotchiListing(
        address _nftAddress,
        uint32 _tokenId,
        address _factory
    ) private {
        address _rentalImplementation = IOriumFactory(_factory).rentalImplementationOf(_nftAddress);
        uint32 _listingId = ILendingGetterAndSetterFacet(_rentalImplementation)
            .getGotchiLendingIdByToken(_tokenId);
        IGotchiLendingFacet(_rentalImplementation).cancelGotchiLending(_listingId);
    }

    function _claimAndEndGotchiLending(
        address _nftAddress,
        uint32 _tokenId,
        address factory
    ) private {
        address _rentalImplementation = IOriumFactory(factory).rentalImplementationOf(_nftAddress);
        IGotchiLendingFacet(_rentalImplementation).claimAndEndGotchiLending(_tokenId);
    }

    function _createLandRental(
        address _nftAddress,
        uint256 _parcelId,
        uint256 _channellingAccessRight,
        uint256 _emptyReservoirAccessRight,
        uint32 _channellingWhitelistId,
        uint32 _emptyReservoirWhitelistId,
        address factory
    ) private {
        LibAavegotchiNftVaultExtension.validateCreateLandRental(
            _channellingAccessRight,
            _emptyReservoirAccessRight,
            _channellingWhitelistId,
            _emptyReservoirWhitelistId
        );

        uint256[] memory parcelIds = new uint256[](2);
        parcelIds[0] = _parcelId;
        parcelIds[1] = _parcelId;

        uint256[] memory actionRights = new uint256[](2);
        actionRights[0] = CHANNELING;
        actionRights[1] = EMPTY_RESERVOIR;

        uint256[] memory accessRights = new uint256[](2);
        accessRights[0] = _channellingAccessRight;
        accessRights[1] = _emptyReservoirAccessRight;

        uint32[] memory whitelistIds = new uint32[](2);
        whitelistIds[0] = _channellingWhitelistId;
        whitelistIds[1] = _emptyReservoirWhitelistId;

        address _rentalImplementation = IOriumFactory(factory).rentalImplementationOf(_nftAddress);
        IRealmGettersAndSettersFacet(_rentalImplementation).setParcelsAccessRightWithWhitelists(
            parcelIds,
            actionRights,
            accessRights,
            whitelistIds
        );
    }

    function _cancelLandRental(address _nftAddress, uint256 _parcelId, address factory) private {
        address _rentalImplementation = IOriumFactory(factory).rentalImplementationOf(_nftAddress);

        uint256[] memory _actionRights = new uint256[](2);
        _actionRights[0] = 0; // 0: Channeling
        _actionRights[1] = 1; // 1: Empty Reservoir

        uint256[] memory _accessRights = new uint256[](2);
        _accessRights[0] = 0; // 0: Only Owner
        _accessRights[1] = 0; // 0: Only Owner

        uint32[] memory _whitelistIds = new uint32[](2);
        _whitelistIds[0] = 0; // 0: No Whitelist
        _whitelistIds[1] = 0; // 0: No Whitelist

        uint256[] memory parcelId = new uint256[](2);
        parcelId[0] = _parcelId;
        parcelId[1] = _parcelId;

        IRealmGettersAndSettersFacet(_rentalImplementation).setParcelsAccessRightWithWhitelists(
            parcelId,
            _actionRights,
            _accessRights,
            _whitelistIds
        );
    }

    // Helpers
    function _createValidAavegotchiListingStruct(
        uint256 _tokenId,
        uint96 _initialCost,
        uint32 _period,
        uint32 _whitelistId,
        address _nftVault,
        address _factory,
        address _thirdPartyAddress,
        address[] memory _alchemicaTokens,
        uint8[3] memory _revenueSplit
    ) internal pure returns (IGotchiLendingFacet.AddGotchiListing memory _listings) {
        _listings = IGotchiLendingFacet.AddGotchiListing({
            tokenId: uint32(_tokenId),
            initialCost: _initialCost,
            period: _period,
            revenueSplit: _revenueSplit,
            originalOwner: _nftVault,
            thirdParty: _thirdPartyAddress,
            whitelistId: _whitelistId,
            revenueTokens: _alchemicaTokens
        });
    }

    //Getters
    function getAavegotchiState(
        address _rentalImplementation,
        uint32 _tokenId
    ) public view returns (NftState) {
        if (ILendingGetterAndSetterFacet(_rentalImplementation).isAavegotchiLent(_tokenId)) {
            if (
                LibAavegotchiNftVaultExtension.isLendingClaimable(_tokenId, _rentalImplementation)
            ) {
                return NftState.CLAIMABLE;
            } else {
                return NftState.BORROWED;
            }
        } else if (
            ILendingGetterAndSetterFacet(_rentalImplementation).isAavegotchiListed(_tokenId)
        ) {
            return NftState.LISTED;
        } else if (IERC721(_rentalImplementation).ownerOf(_tokenId) == address(this)) {
            return NftState.IDLE;
        } else {
            return NftState.NOT_DEPOSITED;
        }
    }

    function getLandState(
        address _rentalImplementation,
        uint256 _parcelId
    ) public view returns (NftState) {
        if (IERC721(_rentalImplementation).ownerOf(_parcelId) != address(this)) {
            return NftState.NOT_DEPOSITED;
        }

        // check default access right is 0 to action 0 and 1 (challing and empty resevoir)
        // land is claimable not borrowed
        uint256[] memory _parcelIds = new uint256[](2);
        _parcelIds[0] = _parcelId;
        _parcelIds[1] = _parcelId;

        uint256[] memory _actionRights = new uint256[](2);
        _actionRights[0] = 0; // 0: Channeling
        _actionRights[1] = 1; // 1: Empty Reservoir

        uint256[] memory _accessRights = IRealmGettersAndSettersFacet(_rentalImplementation)
            .getParcelsAccessRights(_parcelIds, _actionRights);
        // 2: Whitelisted Only
        if (_accessRights[0] != 0 || _accessRights[1] != 0) {
            return NftState.CLAIMABLE;
        } else {
            return NftState.IDLE;
        }
    }

    function getNftState(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _platform,
        address _factory
    ) public view returns (NftState _nftState) {
        uint256 nftTypeId = IOriumFactory(_factory).getPlatformNftType(_platform, _nftAddress);
        address _rentalImplementation = IOriumFactory(_factory).rentalImplementationOf(_nftAddress);

        if (nftTypeId == NFT_TYPE_AAVEGOTCHI) {
            _nftState = getAavegotchiState(_rentalImplementation, uint32(_tokenId));
        } else if (nftTypeId == NFT_TYPE_LAND) {
            _nftState = getLandState(_rentalImplementation, _tokenId);
        } else {
            revert("OriumNftVault:: Invalid NFT type");
        }
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGotchiLendingFacet } from "../interface/IGotchiLendingFacet.sol";
import { ILendingGetterAndSetterFacet } from "../interface/ILendingGetterAndSetterFacet.sol";
import { IOriumNftVault, NftState, INftVaultPlatform } from "../../base/interface/IOriumNftVault.sol";
import { IOriumFactory } from "../../base/interface/IOriumFactory.sol";
import { IRealmGettersAndSettersFacet } from "../interface/IRealmGettersAndSettersFacet.sol";
import { GotchiLending } from "../libraries/LibAavegotchiStorage.sol";
import { IOriumAavegotchiSplitter, WithdrawVoucher, SignatureData } from "../interface/IOriumAavegotchiSplitter.sol";
import { IScholarshipManager } from "../../base/interface/IScholarshipManager.sol";

library LibAavegotchiNftVaultExtension {
    function onlyScholarshipManager(address _factory) public view {
        require(
            msg.sender == address(IOriumFactory(_factory).getScholarshipManagerAddress()),
            "OriumNftVault:: Only scholarshipManager can call this function"
        );
    }

    function transferPendingGHSTBalance(IOriumFactory factory, address vault) public {
        IScholarshipManager _scholarshipManager = IScholarshipManager(
            factory.getScholarshipManagerAddress()
        );
        IERC20 _ghst = IERC20(factory.getAavegotchiGHSTAddress());
        if (address(_ghst) == address(0)) return;
        uint256 _ghstBalance = _ghst.balanceOf(vault);
        if (_ghstBalance <= 0) return;
        address _splitter = factory.getOriumAavegotchiSplitter();
        _ghst.transfer(_splitter, _ghstBalance);
        _scholarshipManager.onTransferredGHST(vault, _ghstBalance);
    }

    // Helpers
    function createValidAavegotchiListingStruct(
        uint256 _tokenId,
        uint96 _initialCost,
        uint32 _period,
        uint32 _whitelistId,
        address _nftVault,
        address _factory,
        address _thirdPartyAddress,
        address[] memory _alchemicaTokens,
        uint8[3] memory _revenueSplit
    ) public pure returns (IGotchiLendingFacet.AddGotchiListing memory _listings) {
        _listings = IGotchiLendingFacet.AddGotchiListing({
            tokenId: uint32(_tokenId),
            initialCost: _initialCost,
            period: _period,
            revenueSplit: _revenueSplit,
            originalOwner: _nftVault,
            thirdParty: _thirdPartyAddress,
            whitelistId: _whitelistId,
            revenueTokens: _alchemicaTokens
        });
    }

    function getAavegotchiListingHelpers(
        address _factory,
        address _nftVault,
        address _nftAddress,
        uint256 _tokenId
    ) public view returns (address, address[] memory, uint8[3] memory) {
        uint256 _platform = INftVaultPlatform(_nftVault).platform();
        address thirdPartyAddress = IOriumFactory(_factory).getOriumAavegotchiSplitter();
        address[] memory alchemicaTokens = IOriumFactory(_factory).getPlatformTokens(_platform);
        address _scholarshipManager = IOriumFactory(_factory).getScholarshipManagerAddress();

        uint256 _programId = IOriumNftVault(_nftVault).programOf(_nftAddress, _tokenId);
        uint256[] memory shares = IScholarshipManager(_scholarshipManager).sharesOf(_programId, 1);
        require(
            shares.length == IOriumFactory(_factory).getPlatformSharesLength(_platform)[0],
            "Orium: Invalid shares"
        );
        uint8[3] memory validShares = getValidRevenueSplit(shares, _factory);

        return (thirdPartyAddress, alchemicaTokens, validShares);
    }

    function getValidRevenueSplit(
        uint256[] memory shares,
        address _factory
    ) public view returns (uint8[3] memory _revenueSplit) {
        uint256 sharesLength = 4;
        require(shares.length == sharesLength, "Orium: Invalid shares");

        uint256 _totalShares = sumShares(shares);
        uint256 _oriumFee = IOriumFactory(_factory).oriumFee();

        require(_totalShares == 100 ether, "Orium: Invalid shares");

        uint256 _totalSharesWithoutOriumFee = _totalShares - _oriumFee;

        uint256[] memory _validShares = new uint256[](sharesLength + 1);

        for (uint256 i = 0; i < sharesLength; i++) {
            _validShares[i] = recalculateShare(shares[i], _totalSharesWithoutOriumFee);
        }

        _validShares[sharesLength] = _oriumFee;

        _revenueSplit = convertSharesToAavegotchi(_validShares);
    }

    function convertSharesToAavegotchi(
        uint256[] memory shares
    ) public pure returns (uint8[3] memory _revenueSplit) {
        _revenueSplit[0] = uint8(shares[0] / 1 ether);
        _revenueSplit[1] = uint8(shares[1] / 1 ether);
        _revenueSplit[2] = uint8((shares[2] + shares[3] + shares[4]) / 1 ether);

        uint8 _sum = sumAavegotchiShares(_revenueSplit);

        _revenueSplit[0] += 100 - _sum;
    }

    function sumShares(uint256[] memory shares) public pure returns (uint256 _sum) {
        for (uint256 i = 0; i < shares.length; i++) {
            _sum += shares[i];
        }
    }

    function sumAavegotchiShares(uint8[3] memory shares) public pure returns (uint8 _sum) {
        for (uint256 i = 0; i < shares.length; i++) {
            _sum += shares[i];
        }
    }

    function recalculateShare(
        uint256 _share,
        uint256 _totalSharesWithoutOriumFee
    ) public pure returns (uint256 _newShare) {
        _newShare = (_share * _totalSharesWithoutOriumFee) / 100 ether;
        _newShare = ceilDown(_newShare, 1 ether);
    }

    function ceilDown(uint256 _value, uint256 _ceil) internal pure returns (uint256 _result) {
        _result = _value - (_value % _ceil);
    }

    function isLendingClaimable(
        uint32 tokenId,
        address _rentalImplementation
    ) public view returns (bool) {
        GotchiLending memory lending = ILendingGetterAndSetterFacet(_rentalImplementation)
            .getGotchiLendingFromToken(tokenId);
        return (lending.timeAgreed + lending.period) < block.timestamp;
    }

    function validateCreateLandRental(
        uint256 _channellingAccessRight,
        uint256 _emptyReservoirAccessRight,
        uint32 _channelingWhitelistId,
        uint32 _emptyReservoirWhitelistId
    ) public pure {
        require(
            _channellingAccessRight != 0 && _emptyReservoirAccessRight != 0,
            "LibAavegotchiNftVault:: Wrong access right"
        );

        if (_emptyReservoirAccessRight == 2) {
            require(
                _emptyReservoirWhitelistId != 0,
                "LibAavegotchiNftVault:: Whitelist id cannot be 0"
            );
        }

        if (_channellingAccessRight == 2) {
            require(
                _channelingWhitelistId != 0,
                "LibAavegotchiNftVault:: Whitelist id cannot be 0"
            );
        }
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

uint256 constant EQUIPPED_WEARABLE_SLOTS = 16;
uint256 constant NUMERIC_TRAITS_NUM = 6;

// @notice Define what action gelato needs to perform with the lending
enum LendingAction {
    DO_NOTHING, // Don't do anything
    REMOVE, // Remove Nft from Scheduling
    LIST, // List NFT for rent
    CLAIM_AND_LIST // Claim and end current rent, and list NFT for rent again
}

struct NftLendingAction {
    uint32 tokenId;
    LendingAction action;
}

struct GotchiLending {
    address lender;
    uint96 initialCost;
    address borrower;
    uint32 listingId;
    uint32 erc721TokenId;
    uint32 whitelistId;
    address originalOwner;
    uint40 timeCreated;
    uint40 timeAgreed;
    bool canceled;
    bool completed;
    address thirdParty;
    uint8[3] revenueSplit;
    uint40 lastClaimed;
    uint32 period;
    address[] revenueTokens;
}

struct Dimensions {
    uint8 x;
    uint8 y;
    uint8 width;
    uint8 height;
}

struct ItemType {
    string name;
    string description;
    string author;
    int8[NUMERIC_TRAITS_NUM] traitModifiers;
    bool[EQUIPPED_WEARABLE_SLOTS] slotPositions;
    uint8[] allowedCollaterals;
    Dimensions dimensions;
    uint256 ghstPrice;
    uint256 maxQuantity;
    uint256 totalQuantity;
    uint32 svgId;
    uint8 rarityScoreModifier;
    bool canPurchaseWithGhst;
    uint16 minLevel;
    bool canBeTransferred;
    uint8 category;
    int16 kinshipBonus;
    uint32 experienceBonus;
}

struct ItemTypeIO {
    uint256 balance;
    uint256 itemId;
    ItemType itemType;
}

struct AavegotchiInfo {
    uint256 tokenId;
    string name;
    address owner;
    uint256 randomNumber;
    uint256 status;
    int16[NUMERIC_TRAITS_NUM] numericTraits;
    int16[NUMERIC_TRAITS_NUM] modifiedNumericTraits;
    uint16[EQUIPPED_WEARABLE_SLOTS] equippedWearables;
    address collateral;
    address escrow;
    uint256 stakedAmount;
    uint256 minimumStake;
    uint256 kinship;
    uint256 lastInteracted;
    uint256 experience;
    uint256 toNextLevel;
    uint256 usedSkillPoints;
    uint256 level;
    uint256 hauntId;
    uint256 baseRarityScore;
    uint256 modifiedRarityScore;
    bool locked;
    ItemTypeIO[] items;
}
struct LendingOperatorInputs {
    uint32 _tokenId;
    bool _isLendingOperator;
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