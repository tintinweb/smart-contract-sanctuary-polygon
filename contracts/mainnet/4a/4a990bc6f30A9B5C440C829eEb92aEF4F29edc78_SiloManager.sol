// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
                version == 1 && !Address.isContract(address(this)),
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/ISiloManagerFactory.sol";
import "../../interfaces/ISiloFactory.sol";
import "../../interfaces/ISiloSubFactory.sol";

import "../../interfaces/ISilo.sol";
import "../../interfaces/ILinkToken.sol";
import "../../interfaces/IPegSwap.sol";
import "../../interfaces/IKeepersRegistry.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./V2/interfaces/IChainLinkAutoCreator.sol";

contract SiloManager is Initializable, KeeperCompatibleInterface {
    address public owner;
    address public managerFactory;
    ISiloManagerFactory ManagerFactory;

    uint256 public autoType = 1;

    uint256 public addFundsThreshold;
    uint256 public upkeepId;
    uint96 public riskBuffer; //based off a number 10000 -> ∞
    uint96 public rejoinBuffer;

    uint96 public bufferPerSilo;

    bool public autoTopup;

    address public creator;

    IERC20 ERC20Link;
    ILinkToken ERC677Link;
    IPegSwap PegSwap;

    address private lastSilo;
    uint256 private lastUpkeep;
    uint256 public fastGap;
    mapping(address => bool) public detected;
    bool public enableBurnCheck;

    event SiloManagerAutoTopup(address owner, uint256 upkeepId, uint256 amount);
    event FastBurn(address silo, uint256 time);

    modifier onlyAdmin() {
        require(
            msg.sender == managerFactory ||
                msg.sender == creator ||
                msg.sender == owner ||
                tx.origin == owner,
            "Caller is not the admin"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function initialize(
        address _mangerFactory,
        address _creator,
        address _owner
    ) external initializer {
        managerFactory = _mangerFactory;
        ManagerFactory = ISiloManagerFactory(managerFactory);
        owner = _owner;
        creator = _creator;
        ERC20Link = IERC20(IChainLinkAutoCreator(creator).ERC20_LINK_ADDRESS());
        ERC677Link = ILinkToken(
            IChainLinkAutoCreator(creator).ERC677_LINK_ADDRESS()
        );
        PegSwap = IPegSwap(IChainLinkAutoCreator(creator).PEGSWAP_ADDRESS());
        addFundsThreshold = 500000000000000000;
        riskBuffer = 10000;
        rejoinBuffer = 10000;
        bufferPerSilo = ManagerFactory.bufferPerSilo();
        autoTopup = true;
        fastGap = 20;
    }

    function setEnableBurnCheck(bool _flag) external onlyOwner {
        enableBurnCheck = _flag;
    }

    function initDetected(address _silo) external onlyOwner {
        detected[_silo] = false;
    }

    function initFastBurn() external onlyOwner {
        lastSilo = address(0);
        lastUpkeep = 0;
    }

    function setFastGap(uint256 _gap) external onlyOwner {
        require(_gap > 0, "wrong duration");
        fastGap = _gap;
    }

    function setAutoTopup(bool _flag) external onlyOwner {
        autoTopup = _flag;
    }

    function adjustThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold > 0, "zero threshold");
        addFundsThreshold = _newThreshold;
    }

    function checkUpkeep(
        bytes calldata checkData
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (upkeepId > 0) {
            uint96 balance = IChainLinkAutoCreator(creator).getBalance(
                upkeepId
            );
            uint96 minBalance = (getRiskBuffer() *
                IChainLinkAutoCreator(creator).getMinBalance(upkeepId)) /
                uint96(10000);

            if (autoTopup) {
                if (balance < minBalance) {
                    // not healthy status
                    uint256 ERC20LinkBal = ERC20Link.balanceOf(address(this));
                    uint256 linkToAdd = ERC677Link.balanceOf(address(this));
                    if (
                        ERC20LinkBal <=
                        PegSwap.getSwappableAmount(
                            address(ERC20Link),
                            address(ERC677Link)
                        )
                    ) {
                        linkToAdd += ERC20LinkBal;
                    }
                    if (linkToAdd >= addFundsThreshold) {
                        upkeepNeeded = true;

                        uint256 addAmount = minBalance - balance;

                        addAmount = (addAmount * 110) / 100;

                        uint256 topupAmount = addAmount > linkToAdd
                            ? linkToAdd
                            : addAmount;

                        bytes memory taskInfo = abi.encode(2, topupAmount);
                        performData = abi.encode(address(this), taskInfo);
                    }
                }
            }

            if (!upkeepNeeded) {
                ISiloFactory SiloFactory = ISiloFactory(
                    ManagerFactory.siloFactory()
                );
                ISiloSubFactory subFactory = ISiloSubFactory(
                    SiloFactory.subFactory()
                );
                uint256 siloID;
                bytes memory siloPerformData;
                ISilo Silo;
                for (uint256 i; i < SiloFactory.balanceOf(owner); ) {
                    siloID = SiloFactory.tokenOfOwnerByIndex(owner, i);
                    Silo = ISilo(SiloFactory.siloMap(siloID));
                    if (
                        Silo.getStatus() == Statuses.PAUSED ||
                        Silo.autoType() != autoType ||
                        detected[address(Silo)]
                    ) {
                        unchecked {
                            i++;
                        }
                        continue; //skip this silo
                    }
                    if (Silo.highRiskAction()) {
                        //need to check if balance is above the min required  by some percent
                        // uint96 balance = IChainLinkAutoCreator(creator)
                        //     .getBalance(upkeepId);
                        // uint96 minBalance = (getRiskBuffer() *
                        //     ManagerFactory.getMinBalance(upkeepId)) /
                        //     uint96(10000);
                        if (balance < minBalance) {
                            if (
                                Silo.getStatus() == Statuses.MANAGED &&
                                Silo.deposited()
                            ) {
                                //high risk silo is currently managed, and manager is underfunded
                                upkeepNeeded = true;
                                siloPerformData = abi.encode(true, 3);
                                performData = abi.encode(
                                    address(Silo),
                                    siloPerformData
                                );
                                return (upkeepNeeded, performData); //this will change the status of the silo to dormant
                            } else {
                                //silo has already been exitted out of high risk strategy
                                unchecked {
                                    i++;
                                }
                                continue; //advance to check next silo
                            }
                        } else if (Silo.getStatus() == Statuses.DORMANT) {
                            //check if balance has returned to a healthy level
                            // uint96 minRejoinBalance = getRejoinBuffer() * ManagerFactory.getMinBalance(upkeepId) / uint96(10000);
                            if (
                                balance > minBalance &&
                                Silo.possibleReinvestSilo()
                            ) {
                                //silo balance has returned to a healthy level and silo is dormant so re enter the strategy
                                upkeepNeeded = true;
                                siloPerformData = abi.encode(false, 4);
                                performData = abi.encode(
                                    address(Silo),
                                    siloPerformData
                                );
                                return (upkeepNeeded, performData);
                            } else {
                                unchecked {
                                    i++;
                                }
                                continue;
                            }
                        }
                    }
                    //check to see if any actions in the strategy have been deprecated logically or by the team, and if so have manager make silo exit strategy
                    if (
                        !upkeepNeeded &&
                        (!subFactory.skipActionValidTeamCheck(owner) ||
                            !subFactory.skipActionValidLogicCheck(owner))
                    ) {
                        (bool team, bool logic) = Silo
                            .showActionStackValidity();
                        if (
                            (!subFactory.skipActionValidTeamCheck(owner) &&
                                !team) ||
                            (!subFactory.skipActionValidLogicCheck(owner) &&
                                !logic)
                        ) {
                            if (Silo.getStatus() == Statuses.MANAGED) {
                                upkeepNeeded = true;
                                siloPerformData = abi.encode(true, 5);
                                performData = abi.encode(
                                    address(Silo),
                                    siloPerformData
                                );
                                return (upkeepNeeded, performData);
                            } else {
                                unchecked {
                                    i++;
                                }
                                continue;
                            }
                        }
                    }

                    if (!upkeepNeeded) {
                        (upkeepNeeded, siloPerformData) = Silo.checkUpkeep(
                            checkData
                        );
                        if (upkeepNeeded) {
                            performData = abi.encode(
                                address(Silo),
                                siloPerformData
                            );
                            return (upkeepNeeded, performData);
                        }
                    }
                    unchecked {
                        i++;
                    }
                }
            }
        }
    }

    //Should check to see if any LINK is sitting in the contract, if so it deposits it
    function performUpkeep(bytes calldata performData) external override {
        require(
            msg.sender == IChainLinkAutoCreator(creator).getKeeperRegistry(),
            "Caller must be keeper registry"
        );

        (address silo, bytes memory siloPerformData) = abi.decode(
            performData,
            (address, bytes)
        );
        if (silo != address(this)) {
            if (enableBurnCheck) {
                if (
                    lastSilo == silo && lastUpkeep + fastGap > block.timestamp
                ) {
                    detected[silo] = true;
                    emit FastBurn(silo, block.timestamp);
                } else {
                    ISilo(silo).performUpkeep(siloPerformData);
                }
                lastSilo = silo;
                lastUpkeep = block.timestamp;
            } else {
                ISilo(silo).performUpkeep(siloPerformData);
            }
        } else {
            //maintaining the managers funds
            require(upkeepId > 0, "no upkeep ID"); //conditional checked in checkUpkeep to
            (uint256 task, ) = abi.decode(siloPerformData, (uint256, uint256));
            // if(task == 0 || task == 1){
            //     (uint mvb, uint96 bal)  = ManagerFactory.getOldMaxValidBlockAndBalance(upkeepId);
            //     uint balance = uint(bal);
            //     if(task == 0){
            //         require(ManagerFactory.currentUpkeepToMigrate() == upkeepId && balance >= ManagerFactory.minMigrationBalance(), "Logic does not check out to cancel");
            //         ManagerFactory.migrationCancel();
            //     }
            //     else if(task == 1){
            //         require(balance > 0 && block.number > mvb, "Logic does not check out to withdraw");
            //         ManagerFactory.migrationWithdraw();
            //     }
            // }
            if (task == 2) {
                //check if ERC20 balance of Link is enough
                uint256 ERC20LinkBal = ERC20Link.balanceOf(address(this));
                if (
                    ERC20LinkBal > 0 &&
                    ERC20LinkBal <=
                    PegSwap.getSwappableAmount(
                        address(ERC20Link),
                        address(ERC677Link)
                    )
                ) {
                    ERC20Link.approve(address(PegSwap), ERC20LinkBal);
                    PegSwap.swap(
                        ERC20LinkBal,
                        address(ERC20Link),
                        address(ERC677Link)
                    );
                }
                uint256 balance = ERC677Link.balanceOf(address(this));
                //Check if ERC677 Balance of Link is enough
                if (balance >= addFundsThreshold) {
                    //conditional checked in checkUpkeep to
                    // uint96 balance = IChainLinkAutoCreator(creator).getBalance(
                    //     upkeepId
                    // );
                    uint96 minBalance = (getRiskBuffer() *
                        IChainLinkAutoCreator(creator).getMinBalance(
                            upkeepId
                        )) / uint96(10000);

                    uint256 addAmount = minBalance -
                        IChainLinkAutoCreator(creator).getBalance(upkeepId);
                    addAmount = (addAmount * 110) / 100;

                    uint256 topupAmount = addAmount > balance
                        ? balance
                        : addAmount;

                    address registry = IChainLinkAutoCreator(creator)
                        .getKeeperRegistry();
                    ERC677Link.approve(registry, topupAmount);

                    IKeepersRegistry(registry).addFunds(
                        upkeepId,
                        uint96(topupAmount)
                    ); //add funds to CURRENT registry

                    emit SiloManagerAutoTopup(owner, upkeepId, topupAmount);
                }
            } else {
                revert("Unkown Task!");
            }
        }
    }

    function setUpkeepId(uint256 id) external {
        require(msg.sender == creator, "Only factory can set upkeep id");
        upkeepId = id;
    }

    function ownerWithdraw(address _token, uint256 _amount) external {
        require(msg.sender == owner, "Only owner can withdraw ERC20s");
        SafeERC20.safeTransfer(IERC20(_token), msg.sender, _amount);
    }

    /**
     * @dev setting riskBuffer to 10000 means the factories risk buffer will be used
     * @dev setting riskBuffer to more than 10000 means that the users risk buffer will be used
     */
    function setCustomRiskBuffer(uint96 _buffer) external onlyAdmin {
        ISiloFactory SiloFactory = ISiloFactory(ManagerFactory.siloFactory());
        uint256 siloBalance = SiloFactory.balanceOf(owner);

        uint96 risk = uint96(10000) + uint96(siloBalance * bufferPerSilo);

        require(_buffer >= risk, "Risk Buffer not valid");

        riskBuffer = _buffer;
    }

    function setCustomRejoinBuffer(uint96 _buffer) external onlyAdmin {
        ISiloFactory SiloFactory = ISiloFactory(ManagerFactory.siloFactory());
        uint256 siloBalance = SiloFactory.balanceOf(owner);

        uint96 risk = uint96(10000) + uint96(siloBalance * bufferPerSilo);

        uint96 rejoin = (risk * 150) / 100;

        require(_buffer >= rejoin, "Risk Buffer not valid");

        rejoinBuffer = _buffer;
    }

    function getRiskBuffer() public view returns (uint96) {
        ISiloFactory SiloFactory = ISiloFactory(ManagerFactory.siloFactory());
        uint256 siloBalance = SiloFactory.balanceOf(owner);

        uint96 risk = uint96(10000) + uint96(siloBalance * bufferPerSilo);

        if (risk > riskBuffer) {
            return risk;
        } else {
            return riskBuffer;
        }
    }

    function getRejoinBuffer() public view returns (uint96) {
        ISiloFactory SiloFactory = ISiloFactory(ManagerFactory.siloFactory());
        uint256 siloBalance = SiloFactory.balanceOf(owner);

        uint96 risk = uint96(10000) + uint96(siloBalance * bufferPerSilo);

        uint96 rejoin = (risk * 150) / 100;

        if (rejoin > rejoinBuffer) {
            return rejoin;
        } else {
            return rejoinBuffer;
        }
    }

    function getMinBuffers()
        public
        view
        returns (uint96 minRisk, uint96 minRejoin)
    {
        ISiloFactory SiloFactory = ISiloFactory(ManagerFactory.siloFactory());
        uint256 siloBalance = SiloFactory.balanceOf(owner);

        minRisk = uint96(10000) + uint96(siloBalance * bufferPerSilo);
        minRejoin = (minRisk * 150) / 100;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IChainLinkAutoCreator {
    function getKeeperRegistry() external view returns (address);

    function ERC20_LINK_ADDRESS() external view returns (address);

    function ERC677_LINK_ADDRESS() external view returns (address);

    function PEGSWAP_ADDRESS() external view returns (address);

    function REGISTRAR_ADDRESS() external view returns (address);

    function managerApproved(address _user) external view returns (bool);

    function getTarget(uint _id) external view returns (address);

    function getBalance(uint _id) external view returns (uint96);

    function getMinBalance(uint _id) external view returns (uint96);

    function getAutoManagerHighBalance(
        address _manager
    ) external view returns (uint96);

    function getAutoManagerBalance(
        address _manager
    ) external view returns (uint96 balance);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IKeepersRegistry {
    function addFunds(uint256 id, uint96 amount) external;
    function getUpkeep(uint256 id) external view returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber
    );
    function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);
    function cancelUpkeep(uint id) external;
    function withdrawFunds(uint id, address to) external;
    function getMinBalanceForUpkeep(uint _id) external view returns(uint96);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILinkToken {
    function transferAndCall(address receiver, uint amount, bytes calldata data) external returns (bool success);
    function balanceOf(address user) external view returns(uint);
    function approve(address spender, uint amount) external;
    function transfer(address _to, uint _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPegSwap{
    function swap(uint256 amount, address source, address target) external;
    function getSwappableAmount(address source, address target) external view returns(uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct PriceOracle {
    address oracle;
    uint256 actionPrice;
}

enum Statuses {
    PAUSED,
    DORMANT,
    MANAGED,
    UNWIND
}

interface ISilo {
    function initialize(
        uint256 siloID,
        uint256 main,
        address factory,
        uint256 autoType
    ) external;

    function autoType() external view returns (uint256);

    function deposit() external;

    function withdraw(uint256 _requestedOut) external;

    function maintain() external;

    function exitSilo(address caller) external;

    function adminCall(address target, bytes memory data) external;

    function setStrategy(
        address[5] memory input,
        bytes[] memory _configurationData,
        address[] memory _implementations
    ) external;

    function getConfig() external view returns (bytes memory config);

    function withdrawToken(address token, address recipient) external;

    function adjustSiloDelay(uint256 _newDelay) external;

    function checkUpkeep(
        bytes calldata checkData
    ) external view returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;

    function siloDelay() external view returns (uint256);

    function name() external view returns (string memory);

    function lastTimeMaintained() external view returns (uint256);

    function setName(string memory name) external;

    function deposited() external view returns (bool);

    function isNew() external view returns (bool);

    function status() external view returns (Statuses);

    function setStrategyName(string memory _strategyName) external;

    function setStrategyCategory(uint256 _strategyCategory) external;

    function strategyName() external view returns (string memory);

    function tokenMinimum(address token) external view returns (uint256);

    function strategyCategory() external view returns (uint256);

    function main() external view returns (uint256);

    function lastPid() external view returns (uint256);

    function adjustStrategy(
        uint256 _index,
        bytes memory _configurationData,
        address _implementation
    ) external;

    function viewStrategy()
        external
        view
        returns (address[] memory actions, bytes[] memory configData);

    function highRiskAction() external view returns (bool);

    function showActionStackValidity() external view returns (bool, bool);

    function getInputTokens() external view returns (address[5] memory);

    function getStatus() external view returns (Statuses);

    function pause() external;

    function unpause() external;

    function setActive() external;

    function possibleReinvestSilo() external view returns (bool possible);

    function getExtraSiloInfo()
        external
        view
        returns (
            uint256 strategyType,
            uint256 currentBalance,
            uint256 possibleWithdraw,
            uint256 availableBlock,
            uint256 pendingReward,
            uint256 lastPid
        );

    function getReferralInfo()
        external
        view
        returns (uint256 fee, address recipient);

    function setReferralInfo(bytes32 _code) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ISiloFactory is IERC721Enumerable{
    function tokenMinimum(address _token) external view returns(uint _minimum);
    function balanceOf(address _owner) external view returns(uint);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function managerFactory() external view returns(address);
    function siloMap(uint _id) external view returns(address);
    function tierManager() external view returns(address);
    function ownerOf(uint _id) external view returns(address);
    function siloToId(address silo) external view returns(uint);
    // function createSilo(address recipient) external returns(uint);
    function setActionStack(uint siloID, address[5] memory input, address[] memory _implementations, bytes[] memory _configurationData) external;
    // function withdraw(uint siloID) external;
    function getFeeInfo(address _action) external view returns(uint fee, address recipient);
    function strategyMaxGas() external view returns(uint);
    function strategyName(string memory _name) external view returns(uint);
    
    function getCatalogue(uint _type) external view returns(string[] memory);
    function getStrategyInputs(uint _id) external view returns(address[5] memory inputs);
    function getStrategyActions(uint _id) external view returns(address[] memory actions);
    function getStrategyConfigurationData(uint _id) external view returns(bytes[] memory configurationData);
    function useCustom(address _action) external view returns(bool);
    // function getFeeList(address _action) external view returns(uint[4] memory);
    function feeRecipient(address _action) external view returns(address);
    function defaultFeeList() external view returns(uint[4] memory);
    function defaultRecipient() external view returns(address);
    // function getTier(address _silo) external view returns(uint);

    function getFeeInfoNoTier(address _action) external view returns(uint[4] memory);
    function highRiskActions(address _action) external view returns(bool);
    function actionValid(address _action) external view returns(bool);
    function skipActionValidTeamCheck(address _user) external view returns(bool);
    function skipActionValidLogicCheck(address _user) external view returns(bool);
    function isSilo(address _silo) external view returns(bool);

    function isSiloManager(address _silo,address _manager) external view returns(bool);

    function currentStrategyId() external view returns(uint);
    function minBalance() external view returns(uint);

    function mainActoins(string memory strategyName) external view returns(uint);
    
    function subFactory() external view returns(address);
    function referral() external view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum AutoStatus {
    NOT,
    APPROVED,
    MANUAL,
    NORMAL,
    HIGH
}

interface ISiloManager {
    function createUpkeep(address _owner, uint _amount) external;

    function setUpkeepId(uint id) external;

    function owner() external view returns (address);

    function upkeepId() external view returns (uint);

    function initialize(
        address _mangerFactory,
        address _creator,
        address _owner
    ) external;

    function getRiskBuffer() external view returns (uint96);

    function checkUpkeep(
        bytes calldata checkData
    ) external returns (bool, bytes memory);

    function setCustomRiskBuffer(uint96 _buffer) external;

    function setCustomRejoinBuffer(uint96 _buffer) external;

    function getRejoinBuffer() external view returns (uint96);

    function getMinBuffers()
        external
        view
        returns (uint96 minRisk, uint96 minRejoin);

    function autoTopup() external view returns (bool);

    function addFundsThreshold() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AutoStatus} from "./ISiloManager.sol";

interface ISiloManagerFactory {
    function checkManager(
        address _owner,
        address _manager,
        uint256 _autoType
    ) external view returns (bool);

    function userToManager(
        address _user,
        uint256 _autoType
    ) external view returns (address);

    function managerCount(uint256 _autoType) external view returns (uint256);

    function siloFactory() external view returns (address);

    function riskBuffer() external view returns (uint96);

    function rejoinBuffer() external view returns (uint96);

    function bufferPerSilo() external view returns (uint96);

    function getAutoCreator(uint256 _autoType) external view returns (address);

    function getAutoTypesSize() external view returns (uint256);

    function getAutoTypeAt(
        uint256 index
    ) external view returns (uint256 autoType, address creator);

    function getAutoStatus(
        address _user,
        uint256 _autoType
    ) external view returns (AutoStatus);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISiloSubFactory {
    function acceptTransfersFrom(address to, address from)
        external
        view
        returns (bool);

    function skipActionValidTeamCheck(address user)
        external
        view
        returns (bool);

    function skipActionValidLogicCheck(address user)
        external
        view
        returns (bool);

    function checkActionsLogicValid(
        address user,
        address[] memory _actions,
        bytes[] memory _configurationData
    ) external view returns (bool);

    function checkActionLogicValid(
        address user,
        address _implementation,
        bytes memory _configurationData
    ) external view returns(bool);
}