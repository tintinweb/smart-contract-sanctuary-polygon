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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../../interfaces/IAction.sol";
import "../../interfaces/ISiloFactory.sol";
import {Statuses} from "../../interfaces/ISilo.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "../../interfaces/ISiloManagerFactory.sol";
import "../../interfaces/ITierManager.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "../../interfaces/iGovernance.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../../interfaces/ISiloReferral.sol";

struct ActionInfo {
    bytes configurationData; //things like what token addresses are involved
    address implementation;
}

contract Silo is Initializable, KeeperCompatibleInterface, IERC721Receiver {
    Statuses public status;

    address public factory;
    // ISiloFactory Factory;

    ActionInfo[] public strategy;

    bytes public configurationData; //For silos this will only ever be the input and output token

    address[10] public tokensInPlay;

    string public name;

    string public strategyName;

    uint256 public strategyCategory;

    uint256 public SILO_ID;
    uint256 public siloDelay; //used to determine how often it is maintained
    uint256 public lastTimeMaintained;

    bool public highRiskAction;
    bool public deposited;
    bool public isNew;
    bool public withdrawLimitAction;

    uint256 private withdrawBlock;
    uint256 private withdrawAmount;

    address private constant GOV = 0xEe5578a3Bab33F7A56575785bb4846B90Be37d50;
    address private constant GFI = 0x874e178A2f3f3F9d34db862453Cd756E7eAb0381;

    uint256 public minGravityGovernance = 1000000000000000000;

    mapping(address => uint256) public tokenMinimum;

    event StrategyFailed(uint256 siloID, uint256 i);

    event SiloUpkeepCall(uint256 siloID, bool mode, uint256 task);

    event SiloGovHarvest(uint256 siloID, uint256 amount);

    modifier onlyFactory() {
        require(msg.sender == factory, "not factory");
        _;
    }

    modifier onlySiloManager() {
        require(
            ISiloManagerFactory(ISiloFactory(factory).managerFactory())
                .isManager(msg.sender),
            "not manager"
        );
        _;
    }

    function initialize(uint256 siloID) external initializer {
        factory = msg.sender;
        // Factory = ISiloFactory(factory);
        SILO_ID = siloID;
        isNew = true;
        minGravityGovernance = 1000000000000000000;
    }

    function setName(string memory _name) external onlyFactory {
        name = _name;
    }

    function adjustSiloDelay(uint256 _newDelay) external onlyFactory {
        //make sure delay isn't too long or too
        siloDelay = _newDelay;
    }

    function setStrategyName(string memory _strategyName) external onlyFactory {
        strategyName = _strategyName;
    }

    function setMinGravityReward(uint256 _reward) external {
        require(
            msg.sender == ISiloFactory(factory).ownerOf(SILO_ID) ||
                msg.sender == factory,
            "wrong caller"
        );
        require(_reward > 0, "zero reward");
        minGravityGovernance = _reward;
    }

    function setStrategyCategory(uint256 _strategyCategory)
        external
        onlyFactory
    {
        strategyCategory = _strategyCategory;
    }

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (status == Statuses.UNWIND) {
            performData = abi.encode(true, 1);
            if (
                withdrawAmount > 0 &&
                block.number >= withdrawBlock &&
                withdrawBlock != 0
            ) {
                upkeepNeeded = true;
            }
        } else {
            performData = abi.encode(false, 0);

            if (
                siloDelay != 0 &&
                (deposited || possibleReinvestSilo()) &&
                status == Statuses.MANAGED
            ) {
                //If delay is zero, maintenance is only conditional based
                upkeepNeeded = (block.timestamp >=
                    (lastTimeMaintained + siloDelay));
                if (upkeepNeeded) {
                    for (uint256 i; i < strategy.length; ) {
                        upkeepNeeded = IAction(strategy[i].implementation)
                            .checkUpkeep(strategy[i].configurationData);
                        if (!upkeepNeeded) {
                            return (false, performData);
                        }
                        unchecked {
                            i++;
                        }
                    }
                }
            }
            if (!upkeepNeeded) {
                //if time up keep is not needed check strategy
                for (uint256 i; i < strategy.length; ) {
                    if (i == 0 || (i != 0 && deposited)) {
                        upkeepNeeded = IAction(strategy[i].implementation)
                            .checkMaintain(strategy[i].configurationData);

                        if (i == 0 && upkeepNeeded) {
                            (bool team, bool logic) = showActionStackValidity();

                            if (!logic || !team) {
                                upkeepNeeded = false;
                            }
                        }
                    }

                    if (upkeepNeeded) {
                        if (i == 0) {
                            performData = abi.encode(false, 6);
                        } else {
                            performData = abi.encode(false, 7);
                        }

                        break;
                    }
                    unchecked {
                        i++;
                    }
                }
            }
        }

        // if (!upkeepNeeded) {
        //     iGovernance gfiGov = iGovernance(GOV);
        //     uint256 pendingReward = gfiGov.pendingEarnings(address(this));

        //     if (pendingReward >= minGravityGovernance) {
        //         performData = abi.encode(true, 2);
        //         upkeepNeeded = true;
        //     }
        // }
    }

    function checkAutoMaintain()
        public
        view
        returns (bool upkeepNeeded, uint256 index)
    {
        for (uint256 i; i < strategy.length; ) {
            if (i == 0 || (i != 0 && deposited)) {
                upkeepNeeded = IAction(strategy[i].implementation)
                    .checkMaintain(strategy[i].configurationData);
            }

            if (upkeepNeeded) {
                index = i;
                break;
            }
            unchecked {
                i++;
            }
        }
    }

    //Only silo managers can call this, and silo managers will only ever call
    //this silo if the owner of the silo manager owns this silo
    function performUpkeep(bytes calldata performData)
        external
        override
        onlySiloManager
    {
        (bool keeperExit, uint256 task) = abi.decode(
            performData,
            (bool, uint256)
        );
        if (task == 2) {
            //claim gravity governance reward
            // claimGFIReward();
        } else {
            if (keeperExit) {
                if (status != Statuses.UNWIND) {
                    status = Statuses.DORMANT;
                }

                if (deposited) {
                    //if there is money in the strategy then remove it
                    _exitStrategy(0);
                }
            } else {
                _runStrategy();
            }
        }

        emit SiloUpkeepCall(SILO_ID, keeperExit, task);
    }

    function showActionStackValidity() public view returns (bool, bool) {
        bool team = true;
        bool logic = true;
        bool tmpTeam;
        bool tmpLogic;
        for (uint256 i; i < strategy.length; ) {
            //go through every action, and call actionValid
            (tmpTeam, tmpLogic) = IAction(strategy[i].implementation)
                .actionValid(strategy[i].configurationData);
            if (!tmpTeam) {
                team = tmpTeam;
            }
            if (!tmpLogic) {
                logic = tmpLogic;
            }
            unchecked {
                i++;
            }
        }
        return (team, logic);
    }

    //Enter the strategy
    function deposit() external onlyFactory {
        uint256 gas = gasleft();
        _runStrategy();
        uint256 gasUsed = gas - gasleft();
        if (gasUsed > ISiloFactory(factory).strategyMaxGas()) {
            string memory errorMessage = string(
                abi.encodePacked(
                    "Strategy Excedes Keepers Gas Limit, Gas Used: ",
                    Strings.toString(gasUsed)
                )
            );
            revert(errorMessage);
        }
    }

    //Exit the strategy
    function withdraw(uint256 _requestedOut) external onlyFactory {
        _exitStrategy(_requestedOut);
    }

    function exitSilo(address caller) external onlyFactory {
        //Send all tokens to owner
        // claimGFIReward();
        withdrawTokens(caller);
        uint256 maticBalance = address(this).balance;
        if (maticBalance > 0) {
            payable(caller).call{value: maticBalance}("");
        }
    }

    function withdrawToken(address token, address recipient)
        external
        onlyFactory
    {
        IERC20 Token = IERC20(token);
        SafeERC20.safeTransfer(
            Token,
            recipient,
            Token.balanceOf(address(this))
        );
    }

    function withdrawTokens(address recipient) private {
        uint256 balance;
        IERC20 token;
        for (uint256 i; i < tokensInPlay.length; ) {
            if (tokensInPlay[i] != address(0)) {
                token = IERC20(tokensInPlay[i]);
                balance = token.balanceOf(address(this));
                if (balance > 0) {
                    SafeERC20.safeTransfer(token, recipient, balance);
                }
            }
            unchecked {
                i++;
            }
        }
    }

    //used to recover users funds if for some reason the strategy fails
    function adminCall(address target, bytes memory data) external onlyFactory {
        (bool success, ) = target.call(data);
        require(success, "Call failed");
    }

    function setStrategy(
        address[5] memory _inputs,
        bytes[] memory _configurationData,
        address[] memory _implementations
    ) external onlyFactory {
        //needs to exit current strategy, if it is in one
        require(status == Statuses.PAUSED, "remove assets before update");
        require(!deposited, "Silo has funds now");
        require(
            _configurationData.length == _implementations.length,
            "Inputs do not match"
        );
        delete strategy; //deletes the current strategy
        address[5] memory actionInput;
        address[5] memory actionOutput = _inputs;
        address[5] memory tmpOutput;
        bytes memory storedConfig;

        highRiskAction = false; //reset it
        ActionInfo memory action;
        uint256 actionCount = _implementations.length;
        for (uint256 i; i < actionCount; ) {
            //Confirm inputs and outputs match
            storedConfig = IAction(_implementations[i]).getConfig();
            if (storedConfig.length > 0) {
                if (i == actionCount - 1) {
                    (actionInput) = abi.decode(storedConfig, (address[5]));
                    tmpOutput = actionInput;
                } else {
                    (actionInput, tmpOutput) = abi.decode(
                        storedConfig,
                        (address[5], address[5])
                    );
                }

                require(
                    IAction(_implementations[i]).validateConfig(storedConfig),
                    "Stored configuration not valid"
                );
            } else {
                if (i == actionCount - 1) {
                    (actionInput) = abi.decode(
                        _configurationData[i],
                        (address[5])
                    );

                    tmpOutput = actionInput;
                } else {
                    (actionInput, tmpOutput) = abi.decode(
                        _configurationData[i],
                        (address[5], address[5])
                    );
                }

                if (
                    !IAction(_implementations[i]).validateConfig(
                        _configurationData[i]
                    )
                ) {
                    string memory errorMessage = string(
                        abi.encodePacked(
                            "Configuration Not Valid At: ",
                            Strings.toString(i)
                        )
                    );
                    revert(errorMessage);
                }
            }
            require(
                actionInput.length == actionOutput.length,
                "different output/input lengths"
            );
            for (uint256 j; j < actionInput.length; ) {
                require(
                    actionInput[j] == actionOutput[j],
                    "input/output do not match"
                );
                unchecked {
                    j++;
                }
            }
            actionOutput = tmpOutput;

            action = ActionInfo({
                configurationData: _configurationData[i],
                implementation: _implementations[i]
            });
            strategy.push(action);
            if (
                !highRiskAction &&
                ISiloFactory(factory).highRiskActions(_implementations[i])
            ) {
                highRiskAction = true;
            }
            //if we are on the last action, then set the config data for this silo
            if (i == actionCount - 1) {
                _setConfigData(_inputs, actionOutput);
            }

            if (i == 0) {
                _setTriggerConfigData(_configurationData[i]);
            }

            status = Statuses.MANAGED;

            unchecked {
                i++;
            }
        }
        (bool isLimit, , , , ) = getExtraSiloInfo();
        withdrawLimitAction = isLimit;
    }

    function adjustStrategy(
        uint256 _index,
        bytes memory _configurationData,
        address _implementation
    ) external onlyFactory {
        address[5] memory currentInputs;
        address[5] memory currentOutputs;
        address[5] memory proposedInputs;
        address[5] memory proposedOutputs;

        if (_index == strategy.length - 1) {
            (currentInputs) = abi.decode(
                strategy[_index].configurationData,
                (address[5])
            );
            currentOutputs = currentInputs;
            (proposedInputs) = abi.decode(_configurationData, (address[5]));
            proposedOutputs = proposedInputs;
        } else {
            (currentInputs, currentOutputs) = abi.decode(
                strategy[_index].configurationData,
                (address[5], address[5])
            );

            (proposedInputs, proposedOutputs) = abi.decode(
                _configurationData,
                (address[5], address[5])
            );
        }

        //if strategy is not already high risk, then check if the new action is high risk
        if (
            !highRiskAction &&
            ISiloFactory(factory).highRiskActions(_implementation)
        ) {
            highRiskAction = true;
        }

        for (uint256 i; i < 5; ) {
            if (currentInputs[i] != proposedInputs[i]) {
                string memory errorMessage = string(
                    abi.encodePacked(
                        "Proposed Input does not match Current Input At: ",
                        Strings.toString(i)
                    )
                );
                revert(errorMessage);
            }
            if (currentOutputs[i] != proposedOutputs[i]) {
                string memory errorMessage = string(
                    abi.encodePacked(
                        "Proposed Output does not match Current Output At: ",
                        Strings.toString(i)
                    )
                );
                revert(errorMessage);
            }
            unchecked {
                i++;
            }
        }
        require(
            IAction(_implementation).validateConfig(_configurationData),
            "Configuration is not valid"
        );

        //If above all checks out, then overwrite the strategy at _index
        strategy[_index] = ActionInfo({
            configurationData: _configurationData,
            implementation: _implementation
        });

        if (_index == 0) {
            _setTriggerConfigData(_configurationData);
        }
    }

    function pause() external onlyFactory {
        require(!highRiskAction, "Cannot pause high risk silos"); //user needs to exit using exitSiloStrategy
        require(status == Statuses.MANAGED, "silo is not managed status");
        status = Statuses.PAUSED;
    }

    //user could flip this to managed without setting a strategy, but UI is only set up for new silos to have a strategy
    function unpause() external onlyFactory {
        require(status == Statuses.PAUSED, "silo is not paused status");
        status = Statuses.MANAGED;
    }

    function setActive() external onlyFactory {
        require(status == Statuses.UNWIND, "silo is not unwind status");
        status = Statuses.MANAGED;
    }

    function viewStrategy()
        external
        view
        returns (address[] memory actions, bytes[] memory configData)
    {
        actions = new address[](strategy.length);
        configData = new bytes[](strategy.length);
        unchecked {
            for (uint256 i; i < strategy.length; i++) {
                actions[i] = strategy[i].implementation;
                configData[i] = strategy[i].configurationData;
            }
        }
    }

    /****************************Public Functions*****************************/
    //Here so that silos match the design pattern of actions
    function getConfig() public view returns (bytes memory) {
        return configurationData;
    }

    function getInputTokens() public view returns (address[5] memory inputs) {
        unchecked {
            for (uint256 i; i < 5; i++) {
                inputs[i] = tokensInPlay[i];
            }
        }
    }

    function getStatus() public view returns (Statuses) {
        return status;
    }

    /****************************Internal Functions*****************************/
    function _investSilo() internal returns (uint256[5] memory amounts) {
        address[5] memory depositTokens = abi.decode(
            configurationData,
            (address[5])
        );
        for (uint256 i; i < 5; ) {
            uint256 tokenAmount;
            if (depositTokens[i] != address(0)) {
                tokenAmount = IERC20(depositTokens[i]).balanceOf(address(this));
                if (
                    tokenAmount > 0 &&
                    tokenAmount >= tokenMinimum[depositTokens[i]]
                ) {
                    amounts[i] = tokenAmount;
                    //if tokenAmount is non zero and greater than the minimum, then set deposited to true
                    if (!deposited) {
                        deposited = true;
                    }
                    if (status == Statuses.DORMANT) {
                        status = Statuses.MANAGED; //change it back to managed
                    }
                    if (isNew) {
                        //track if a silo has ever had anything deposited into it
                        isNew = false;
                    }
                }
            }
            unchecked {
                i++;
            }
        }
    }

    function possibleReinvestSilo() public view returns (bool possible) {
        address[5] memory depositTokens = abi.decode(
            configurationData,
            (address[5])
        );
        for (uint256 i; i < 5; ) {
            uint256 tokenAmount;
            if (depositTokens[i] != address(0)) {
                tokenAmount = IERC20(depositTokens[i]).balanceOf(address(this));
                if (
                    tokenAmount > 0 &&
                    tokenAmount >= tokenMinimum[depositTokens[i]]
                ) {
                    return true;
                }
            }
            unchecked {
                i++;
            }
        }
        return false;
    }

    function _runStrategy() internal {
        uint256[5] memory amounts = _investSilo();
        bytes memory inputData = abi.encode(amounts);
        for (uint256 i; i < strategy.length; ) {
            (bool success, bytes memory result) = strategy[i]
                .implementation
                .delegatecall(
                    abi.encodeWithSignature(
                        "enter(address,bytes,bytes)",
                        strategy[i].implementation,
                        strategy[i].configurationData,
                        inputData
                    )
                );
            if (!success) {
                string memory errorMessage = string(
                    abi.encodePacked(
                        "Strategy Failed At: ",
                        Strings.toString(i)
                    )
                );
                revert(errorMessage);
            }
            inputData = result;
            unchecked {
                i++;
            }
        }
        lastTimeMaintained = block.timestamp;
    }

    // function claimGFIReward() public {
    //     iGovernance gfiGov = iGovernance(GOV);

    //     uint256 pendingReward = gfiGov.pendingEarnings(address(this));

    //     if (pendingReward > 0) {
    //         uint256 currentBalance = IERC20(GFI).balanceOf(address(this));

    //         if (currentBalance > 0) {
    //             gfiGov.claimFee();
    //         } else {
    //             gfiGov.withdrawFee();
    //         }
    //         emit SiloGovHarvest(SILO_ID, pendingReward);
    //     }
    // }

    function _exitStrategy(uint256 _requestedOut) internal {
        require(deposited, "No strategy balance");

        uint256[5] memory amounts = [_requestedOut, 0, 0, 0, 0];
        bytes memory exitData = abi.encode(amounts);
        for (uint256 i; i < strategy.length; ) {
            (bool success, bytes memory result) = strategy[i]
                .implementation
                .delegatecall(
                    abi.encodeWithSignature(
                        "exit(address,bytes,bytes)",
                        strategy[i].implementation,
                        strategy[i].configurationData,
                        exitData
                    )
                );
            if (!success) {
                string memory errorMessage = string(
                    abi.encodePacked(
                        "Withdraw Failed At: ",
                        Strings.toString(i)
                    )
                );
                revert(errorMessage);
            }
            exitData = result;
            unchecked {
                i++;
            }
        }

        if (withdrawLimitAction) {
            (
                ,
                uint256 currentBalance,
                uint256 possibleWithdraw,
                uint256 availableBlock,

            ) = getExtraSiloInfo();
            withdrawBlock = availableBlock;
            withdrawAmount = possibleWithdraw;

            if (status == Statuses.UNWIND) {
                withdrawTokens(ISiloFactory(factory).ownerOf(SILO_ID));
            }

            if (currentBalance <= ISiloFactory(factory).minBalance()) {
                deposited = false;
                status = Statuses.DORMANT;
            } else {
                if (_requestedOut == 0 && status != Statuses.UNWIND) {
                    status = Statuses.UNWIND;
                }
            }
        } else {
            if (_requestedOut == 0) {
                deposited = false;
            }
        }
    }

    function getExtraSiloInfo()
        public
        view
        returns (
            bool isLimit,
            uint256 currentBalance,
            uint256 possibleWithdraw,
            uint256 availableBlock,
            uint256 pendingReward
        )
    {
        for (uint256 i; i < strategy.length; ) {
            (
                currentBalance,
                possibleWithdraw,
                availableBlock,
                pendingReward
            ) = IAction(strategy[i].implementation).extraInfo(
                strategy[i].configurationData
            );
            if (possibleWithdraw > 0 || availableBlock > 0) {
                return (
                    true,
                    currentBalance,
                    possibleWithdraw,
                    availableBlock,
                    pendingReward
                );
            }
            if (pendingReward > 0 && availableBlock == 0) {
                return (
                    false,
                    currentBalance,
                    possibleWithdraw,
                    availableBlock,
                    pendingReward
                );
            }

            unchecked {
                i++;
            }
        }
        return (false, 0, 0, 0, 0);
    }

    function _setConfigData(address[5] memory _input, address[5] memory _output)
        internal
    {
        configurationData = abi.encode(_input, _output);
        unchecked {
            for (uint256 i; i < 5; i++) {
                tokensInPlay[i] = _input[i];
                tokensInPlay[i + 5] = _output[i];
            }
        }
    }

    function _setTriggerConfigData(bytes memory configData) internal {
        (address[5] memory _inputs, , uint256[5] memory _triggers) = abi.decode(
            configData,
            (address[5], address[5], uint256[5])
        );
        unchecked {
            for (uint256 i; i < 5; i++) {
                tokenMinimum[_inputs[i]] = _triggers[i];
            }
        }
    }

    function getReferralInfo()
        public
        view
        returns (uint256 fee, address recipient)
    {
        return
            ISiloReferral(ISiloFactory(factory).referral()).siloReferralInfo(
                address(this)
            );
    }

    function setReferralInfo(bytes32 _code) external onlyFactory {
        try
            ISiloReferral(ISiloFactory(factory).referral()).setSiloReferrer(
                address(this),
                _code
            )
        {} catch (bytes memory reason) {}
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct ActionBalance {
    uint256 collateral;
    uint256 debt;
    address collateralToken;
    address debtToken;
    uint256 collateralConverted;
    address collateralConvertedToken;
    string lpUnderlyingBalances;
    string lpUnderlyingTokens;
}

interface IAction {
    function getConfig() external view returns (bytes memory config);

    function checkMaintain(bytes memory configuration)
        external
        view
        returns (bool);

    function checkUpkeep(bytes memory configuration)
        external
        view
        returns (bool);

    function extraInfo(bytes memory configuration)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function validateConfig(bytes memory configData)
        external
        view
        returns (bool);

    function getMetaData() external view returns (string memory);

    function getFactory() external view returns (address);

    function getDecimals() external view returns (uint256);

    function showFee(address _action)
        external
        view
        returns (string memory actionName, uint256[4] memory fees);

    function showBalances(address _silo, bytes memory _configurationData)
        external
        view
        returns (ActionBalance memory);

    function showDust(address _silo, bytes memory _configurationData)
        external
        view
        returns (address[] memory, uint256[] memory);

    function vaultInfo(address _silo, bytes memory configuration)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function actionValid(bytes memory _configurationData)
        external
        view
        returns (bool, bool);

    function getIsSilo(address _silo) external view returns (bool);

    function getIsSiloManager(address _silo, address _manager)
        external
        view
        returns (bool);

    function setFactory(address _siloFactory) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface iGovernance {
    /**
     * Assume claimFee uses msg.sender, and returns the amount of WETH sent to the caller
     */
    function delegateFee(address reciever) external returns (uint256);

    function claimFee() external returns (uint256);

    function tierLedger(address user, uint index) external returns(uint);

    function depositFee(uint256 amountWETH, uint256 amountWBTC) external;

    function withdrawFee() external;

    function Tiers(uint index) external view returns(uint);

    function pendingEarnings(address _address) external view returns(uint256);
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
    function initialize(uint256 siloID) external;

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

    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;

    function siloDelay() external view returns (uint256);

    function name() external view returns (string memory);

    function lastTimeMaintained() external view returns (uint256);

    function setName(string memory name) external;

    function deposited() external view returns (bool);

    function isNew() external view returns (bool);

    function setStrategyName(string memory _strategyName) external;

    function setStrategyCategory(uint256 _strategyCategory) external;

    function strategyName() external view returns (string memory);

    function tokenMinimum(address token) external view returns (uint256);

    function strategyCategory() external view returns (uint256);

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
            bool isLimit,
            uint256 currentBalance,
            uint256 possibleWithdraw,
            uint256 availableBlock,
            uint256 pendingReward
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
    
    function subFactory() external view returns(address);
    function referral() external view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISiloManagerFactory{
    function isManager(address _manager) external view returns(bool);
    function getKeeperRegistry() external view returns(address);
    function alphaRegistry() external view returns(address);
    function betaRegistry() external view returns(address);
    function migrate() external view returns(bool);
    function migrationCancel() external;
    function migrationWithdraw() external;
    function minMigrationBalance() external view returns(uint);
    function currentUpkeepToMigrate() external view returns(uint);
    function getOldMaxValidBlockAndBalance(uint _id) external view returns(uint mvb, uint96 bal);
    function siloFactory() external view returns(address);
    function ERC20_LINK_ADDRESS() external view returns(address);
    function ERC677_LINK_ADDRESS() external view returns(address);
    function PEGSWAP_ADDRESS() external view returns(address);
    function REGISTRAR_ADDRESS() external view returns(address);
    function getUpkeepBalance(address _user) external view returns(uint96 balance);
    function managerApproved(address _user) external view returns(bool);
    function userToManager(address _user) external view returns(address);
    function getTarget(uint _id) external view returns(address);
    function riskBuffer() external view returns(uint96);
    function rejoinBuffer() external view returns(uint96);
    function getBalance(uint _id) external view returns(uint96);
    function getMinBalance(uint _id) external view returns(uint96);
    function getMinimumUpkeepBalance(address _user) external view returns(uint96);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISiloReferral {
    function setSiloReferrer(address _silo, bytes32 _code) external;

    function siloReferralInfo(address _silo) external view returns(uint256,address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface ITierManager {
    function checkTier(address caller) external view returns(uint);
    function checkTierIncludeSnapshot(address caller) external view returns(uint);
    function viewIDOTier(address caller) external view returns(uint);
}