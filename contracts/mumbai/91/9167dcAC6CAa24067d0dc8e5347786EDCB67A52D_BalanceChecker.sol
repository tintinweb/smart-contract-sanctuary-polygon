// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`.
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`.
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
}

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.19;

import { UUPSProxiable } from "../upgradability/UUPSProxiable.sol";
import { ISuperAgreement } from "../interfaces/superfluid/ISuperAgreement.sol";

/**
 * @title Superfluid agreement base boilerplate contract
 * @author Superfluid
 */
abstract contract AgreementBase is
    UUPSProxiable,
    ISuperAgreement
{
    address immutable internal _host;

    // Custom Erorrs
    error AGREEMENT_BASE_ONLY_HOST(); // 0x1601d91e

    constructor(address host)
    {
        _host = host;
    }

    function proxiableUUID()
        public view override
        returns (bytes32)
    {
        return ISuperAgreement(this).agreementType();
    }

    function updateCode(address newAddress)
        external override
    {
        if (msg.sender != _host) revert AGREEMENT_BASE_ONLY_HOST();
        return _updateCodeAddress(newAddress);
    }

}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.19;

import {
    ISuperfluidGovernance,
    ISuperfluid,
    ISuperfluidToken,
    ISuperApp,
    SuperAppDefinitions,
    ContextDefinitions
} from "../interfaces/superfluid/ISuperfluid.sol";
import { ISuperfluidToken } from "../interfaces/superfluid/ISuperfluidToken.sol";

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";


/**
 * @title Agreement Library
 * @author Superfluid
 * @dev Helper library for building super agreement
 */
library AgreementLibrary {

    using SafeCast for uint256;
    using SafeCast for int256;

    /**************************************************************************
     * Context helpers
     *************************************************************************/

    /**
     * @dev Authorize the msg.sender to access token agreement storage
     *
     * NOTE:
     * - msg.sender must be the expected host contract.
     * - it should revert on unauthorized access.
     */
    function authorizeTokenAccess(ISuperfluidToken token, bytes memory ctx)
        internal view
        returns (ISuperfluid.Context memory)
    {
        require(token.getHost() == msg.sender, "unauthorized host");
        require(ISuperfluid(msg.sender).isCtxValid(ctx), "invalid ctx");
        return ISuperfluid(msg.sender).decodeCtx(ctx);
    }

    /**************************************************************************
     * Agreement callback helpers
     *************************************************************************/

    struct CallbackInputs {
        ISuperfluidToken token;
        address account;
        bytes32 agreementId;
        bytes agreementData;
        uint256 appCreditGranted;
        int256 appCreditUsed;
        uint256 noopBit;
    }

    function createCallbackInputs(
        ISuperfluidToken token,
        address account,
        bytes32 agreementId,
        bytes memory agreementData
    )
       internal pure
       returns (CallbackInputs memory inputs)
    {
        inputs.token = token;
        inputs.account = account;
        inputs.agreementId = agreementId;
        inputs.agreementData = agreementData;
    }

    function callAppBeforeCallback(
        CallbackInputs memory inputs,
        bytes memory ctx
    )
        internal
        returns(bytes memory cbdata)
    {
        bool isSuperApp;
        bool isJailed;
        uint256 noopMask;
        (isSuperApp, isJailed, noopMask) = ISuperfluid(msg.sender).getAppManifest(ISuperApp(inputs.account));
        if (isSuperApp && !isJailed) {
            bytes memory appCtx = _pushCallbackStack(ctx, inputs);
            if ((noopMask & inputs.noopBit) == 0) {
                bytes memory callData = abi.encodeWithSelector(
                    _selectorFromNoopBit(inputs.noopBit),
                    inputs.token,
                    address(this) /* agreementClass */,
                    inputs.agreementId,
                    inputs.agreementData,
                    new bytes(0) // placeholder ctx
                );
                cbdata = ISuperfluid(msg.sender).callAppBeforeCallback(
                    ISuperApp(inputs.account),
                    callData,
                    inputs.noopBit == SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP,
                    appCtx);
            }
            // [SECURITY] NOTE: ctx should be const, do not modify it ever to ensure callback stack correctness
            _popCallbackStack(ctx, 0);
        }
    }

    function callAppAfterCallback(
        CallbackInputs memory inputs,
        bytes memory cbdata,
        bytes /* const */ memory ctx
    )
        internal
        returns (ISuperfluid.Context memory appContext, bytes memory newCtx)
    {
        bool isSuperApp;
        bool isJailed;
        uint256 noopMask;
        (isSuperApp, isJailed, noopMask) = ISuperfluid(msg.sender).getAppManifest(ISuperApp(inputs.account));

        newCtx = ctx;
        if (isSuperApp && !isJailed) {
            newCtx = _pushCallbackStack(newCtx, inputs);
            if ((noopMask & inputs.noopBit) == 0) {
                bytes memory callData = abi.encodeWithSelector(
                    _selectorFromNoopBit(inputs.noopBit),
                    inputs.token,
                    address(this) /* agreementClass */,
                    inputs.agreementId,
                    inputs.agreementData,
                    cbdata,
                    new bytes(0) // placeholder ctx
                );
                newCtx = ISuperfluid(msg.sender).callAppAfterCallback(
                    ISuperApp(inputs.account),
                    callData,
                    inputs.noopBit == SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP,
                    newCtx);

                appContext = ISuperfluid(msg.sender).decodeCtx(newCtx);

                // adjust credit used to the range [appCreditUsed..appCreditGranted]
                appContext.appCreditUsed = _adjustNewAppCreditUsed(
                    inputs.appCreditGranted,
                    appContext.appCreditUsed
                );
            }
            // [SECURITY] NOTE: ctx should be const, do not modify it ever to ensure callback stack correctness
            newCtx = _popCallbackStack(ctx, appContext.appCreditUsed);
        }
    }

    /**
     * @dev Determines how much app credit the app will use.
     * @param appCreditGranted set prior to callback based on input flow
     * @param appCallbackDepositDelta set in callback - sum of deposit deltas of callback agreements and
     * current flow owed deposit amount
     */
    function _adjustNewAppCreditUsed(
        uint256 appCreditGranted,
        int256 appCallbackDepositDelta
    ) internal pure returns (int256) {
        // NOTE: we use max(0, ...) because appCallbackDepositDelta can be negative and appCallbackDepositDelta
        // should never go below 0, otherwise the SuperApp can return more money than borrowed
        return max(
            0,
            
            // NOTE: we use min(appCreditGranted, appCallbackDepositDelta) to ensure that the SuperApp borrows
            // appCreditGranted at most and appCallbackDepositDelta at least (if smaller than appCreditGranted)
            min(
                appCreditGranted.toInt256(),
                appCallbackDepositDelta
            )
        );
    }

    function _selectorFromNoopBit(uint256 noopBit)
        private pure
        returns (bytes4 selector)
    {
        if (noopBit == SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP) {
            return ISuperApp.beforeAgreementCreated.selector;
        } else if (noopBit == SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP) {
            return ISuperApp.beforeAgreementUpdated.selector;
        } else if (noopBit == SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP) {
            return ISuperApp.beforeAgreementTerminated.selector;
        } else if (noopBit == SuperAppDefinitions.AFTER_AGREEMENT_CREATED_NOOP) {
            return ISuperApp.afterAgreementCreated.selector;
        } else if (noopBit == SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP) {
            return ISuperApp.afterAgreementUpdated.selector;
        } else /* if (noopBit == SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP) */ {
            return ISuperApp.afterAgreementTerminated.selector;
        }
    }

    function _pushCallbackStack(
        bytes memory ctx,
        CallbackInputs memory inputs
    )
        private
        returns (bytes memory appCtx)
    {
        // app credit params stack PUSH
        // pass app credit and current credit used to the app,
        appCtx = ISuperfluid(msg.sender).appCallbackPush(
            ctx,
            ISuperApp(inputs.account),
            inputs.appCreditGranted,
            inputs.appCreditUsed,
            inputs.token);
    }

    function _popCallbackStack(
        bytes memory ctx,
        int256 appCreditUsedDelta
    )
        private
        returns (bytes memory newCtx)
    {
        // app credit params stack POP
        return ISuperfluid(msg.sender).appCallbackPop(ctx, appCreditUsedDelta);
    }

    /**************************************************************************
     * Misc
     *************************************************************************/

    function max(int256 a, int256 b) internal pure returns (int256) { return a > b ? a : b; }
    function max(uint256 a, uint256 b) internal pure returns (uint256) { return a > b ? a : b; }

    function min(int256 a, int256 b) internal pure returns (int256) { return a > b ? b : a; }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.19;

import {
    IConstantFlowAgreementV1,
    ISuperfluidToken
} from "../interfaces/agreements/IConstantFlowAgreementV1.sol";
import {
    ISuperfluid,
    ISuperfluidGovernance,
    ISuperApp,
    ISuperToken,
    FlowOperatorDefinitions,
    SuperAppDefinitions,
    ContextDefinitions,
    SuperfluidGovernanceConfigs
} from "../interfaces/superfluid/ISuperfluid.sol";
import { IConstantOutflowNFT } from "../interfaces/superfluid/IConstantOutflowNFT.sol";
import { AgreementBase } from "./AgreementBase.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { AgreementLibrary } from "./AgreementLibrary.sol";
import { SafeGasLibrary } from "../libs/SafeGasLibrary.sol";

/**
 * @title ConstantFlowAgreementV1 contract
 * @author Superfluid
 * @dev Please read IConstantFlowAgreementV1 for implementation notes.
 * @dev For more technical notes, please visit protocol-monorepo wiki area.
 * 
 * Storage Layout Notes
 * Agreement State
 * NOTE The Agreement State slot is computed with the following function:
 * keccak256(abi.encode("AgreementState", msg.sender, account, slotId))
 * slotId           = 0
 * msg.sender       = address of CFAv1
 * account          = context.msgSender 
 * Flow Agreement State stores the global FlowData state for an account.
 * 
 * 
 * Agreement Data
 * NOTE The Agreement Data slot is calculated with the following function:
 * keccak256(abi.encode("AgreementData", agreementClass, agreementId))
 * agreementClass   = address of CFAv1
 * agreementId      = FlowId | FlowOperatorId
 * 
 * FlowId           = keccak256(abi.encode(flowSender, flowReceiver))
 * FlowId stores FlowData between a flowSender and flowReceiver.
 * 
 * FlowOperatorId   = keccak256(abi.encode("flowOperator", flowSender, flowOperator))
 * FlowOperatorId stores FlowOperatorData between a flowSender and flowOperator.
 */
contract ConstantFlowAgreementV1 is
    AgreementBase,
    IConstantFlowAgreementV1
{
    /**
     * @dev Default minimum deposit value
     *
     * NOTE:
     * - It may come as a surprise that it is not 0, this is the minimum friction we have in the system for the
     *   imperfect blockchain system we live in.
     * - It is related to deposit clipping, and it is always rounded-up when clipping.
     */
    uint256 public constant DEFAULT_MINIMUM_DEPOSIT = uint256(uint96(1 << 32));
    /// @dev Maximum deposit value
    uint256 public constant MAXIMUM_DEPOSIT = uint256(uint96(type(int96).max));

    /// @dev Maximum flow rate
    uint256 public constant MAXIMUM_FLOW_RATE = uint256(uint96(type(int96).max));

    bytes32 private constant CFAV1_PPP_CONFIG_KEY =
        keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1.PPPConfiguration");

    bytes32 private constant SUPERTOKEN_MINIMUM_DEPOSIT_KEY =
        keccak256("org.superfluid-finance.superfluid.superTokenMinimumDeposit");

    // An arbitrarily chosen safety limit for the external calls to protect against out-of-gas grief exploits.
    // solhint-disable-next-line var-name-mixedcase
    uint64 constant public CFA_HOOK_GAS_LIMIT = 250000;

    using SafeCast for uint256;
    using SafeCast for int256;

    struct FlowData {
        uint256 timestamp; // stored as uint32
        int96 flowRate; // stored also as int96
        uint256 deposit; // stored as int96 with lower 32 bits clipped to 0
        uint256 owedDeposit; // stored as int96 with lower 32 bits clipped to 0
    }

    struct FlowParams {
        bytes32 flowId;
        address sender;
        address receiver;
        address flowOperator;
        int96 flowRate;
        bytes userData;
    }

    struct FlowOperatorData {
        uint8 permissions;
        int96 flowRateAllowance;
    }

    // solhint-disable-next-line no-empty-blocks
    constructor(
        ISuperfluid host
    ) AgreementBase(address(host)) {}

    /**************************************************************************
     * ISuperAgreement interface
     *************************************************************************/

    /// @dev ISuperAgreement.realtimeBalanceOf implementation
    function realtimeBalanceOf(
        ISuperfluidToken token,
        address account,
        uint256 time
    )
        external
        view
        override
        returns (int256 dynamicBalance, uint256 deposit, uint256 owedDeposit)
    {
        (bool exist, FlowData memory state) = _getAccountFlowState(token, account);
        if(exist) {
            dynamicBalance = ((int256(time) - (int256(state.timestamp))) * state.flowRate);
            deposit = state.deposit;
            owedDeposit = state.owedDeposit;
        }
    }

    /**************************************************************************
     * IConstantFlowAgreementV1 interface
     *************************************************************************/

     function _getMaximumFlowRateFromDepositPure(
         uint256 liquidationPeriod,
         uint256 deposit)
         internal pure
         returns (int96 flowRate)
     {
        if (deposit > MAXIMUM_DEPOSIT) revert CFA_DEPOSIT_TOO_BIG();
         deposit = _clipDepositNumberRoundingDown(deposit);

         uint256 flowrate1 = deposit / liquidationPeriod;

         // NOTE downcasting is safe as we constrain deposit to less than
         // 2 ** 95 (MAXIMUM_DEPOSIT) so the resulting value flowRate1 will fit into int96
         return int96(int256(flowrate1));
     }

     function _getDepositRequiredForFlowRatePure(
         uint256 minimumDeposit,
         uint256 liquidationPeriod,
         int96 flowRate)
         internal pure
         returns (uint256 deposit)
     {
        if (flowRate < 0) revert CFA_INVALID_FLOW_RATE();
        if (uint256(int256(flowRate)) * liquidationPeriod > uint256(int256(type(int96).max))) {
            revert CFA_FLOW_RATE_TOO_BIG();
        }
         uint256 calculatedDeposit = _calculateDeposit(flowRate, liquidationPeriod);
         return AgreementLibrary.max(minimumDeposit, calculatedDeposit);
     }

     /// @dev IConstantFlowAgreementV1.getMaximumFlowRateFromDeposit implementation
     function getMaximumFlowRateFromDeposit(
         ISuperfluidToken token,
         uint256 deposit)
         external view override
         returns (int96 flowRate)
     {
         (uint256 liquidationPeriod, ) = _decode3PsData(token);
         flowRate = _getMaximumFlowRateFromDepositPure(liquidationPeriod, deposit);
     }

     /// @dev IConstantFlowAgreementV1.getDepositRequiredForFlowRate implementation
     function getDepositRequiredForFlowRate(
         ISuperfluidToken token,
         int96 flowRate)
         external view override
         returns (uint256 deposit)
     {
        // base case: 0 flow rate
        if (flowRate == 0) return 0;
         ISuperfluidGovernance gov = ISuperfluidGovernance(ISuperfluid(_host).getGovernance());
         uint256 minimumDeposit = gov.getConfigAsUint256(ISuperfluid(_host), token, SUPERTOKEN_MINIMUM_DEPOSIT_KEY);
         uint256 pppConfig = gov.getConfigAsUint256(ISuperfluid(_host), token, CFAV1_PPP_CONFIG_KEY);
         (uint256 liquidationPeriod, ) = SuperfluidGovernanceConfigs.decodePPPConfig(pppConfig);
         return _getDepositRequiredForFlowRatePure(minimumDeposit, liquidationPeriod, flowRate);
     }

    function isPatricianPeriodNow(
        ISuperfluidToken token,
        address account)
        external view override
        returns (bool isCurrentlyPatricianPeriod, uint256 timestamp)
    {
        timestamp = ISuperfluid(_host).getNow();
        isCurrentlyPatricianPeriod = isPatricianPeriod(token, account, timestamp);
    }

    function isPatricianPeriod(
        ISuperfluidToken token,
        address account,
        uint256 timestamp)
        public view override
        returns (bool)
    {
        (int256 availableBalance, ,) = token.realtimeBalanceOf(account, timestamp);
        if (availableBalance >= 0) {
            return true;
        }

        (uint256 liquidationPeriod, uint256 patricianPeriod) = _decode3PsData(token);
        (,FlowData memory senderAccountState) = _getAccountFlowState(token, account);
        int256 signedTotalCFADeposit = senderAccountState.deposit.toInt256();

        return _isPatricianPeriod(
            availableBalance,
            signedTotalCFADeposit,
            liquidationPeriod,
            patricianPeriod
        );
    }

    /// @dev IConstantFlowAgreementV1.createFlow implementation
    function createFlow(
        ISuperfluidToken token,
        address receiver,
        int96 flowRate,
        bytes calldata ctx
    )
        external
        override
        returns(bytes memory newCtx)
    {
        ISuperfluid.Context memory currentContext = AgreementLibrary.authorizeTokenAccess(token, ctx);

        _StackVars_createOrUpdateFlow memory flowVars;
        flowVars.token = token;
        flowVars.sender = currentContext.msgSender;
        flowVars.receiver = receiver;
        flowVars.flowRate = flowRate;

        newCtx = _createFlow(
            flowVars,
            ctx,
            currentContext
        );
    }

    /// @dev IConstantFlowAgreementV1.updateFlow implementation
    function updateFlow(
        ISuperfluidToken token,
        address receiver,
        int96 flowRate,
        bytes calldata ctx
    )
        external
        override
        returns(bytes memory newCtx)
    {
        ISuperfluid.Context memory currentContext = AgreementLibrary.authorizeTokenAccess(token, ctx);

        _StackVars_createOrUpdateFlow memory flowVars;
        flowVars.token = token;
        flowVars.sender = currentContext.msgSender;
        flowVars.receiver = receiver;
        flowVars.flowRate = flowRate;

        bytes32 flowId = _generateFlowId(flowVars.sender, flowVars.receiver);
        (bool exist, FlowData memory oldFlowData) = _getAgreementData(flowVars.token, flowId);

        newCtx = _updateFlow(
            flowVars,
            oldFlowData,
            exist,
            ctx,
            currentContext
        );
    }

    /// @dev IConstantFlowAgreementV1.deleteFlow implementation
    function deleteFlow(
        ISuperfluidToken token,
        address sender,
        address receiver,
        bytes calldata ctx
    )
        external
        override
        returns(bytes memory newCtx)
    {
        ISuperfluid.Context memory currentContext = AgreementLibrary.authorizeTokenAccess(token, ctx);
        (,uint8 permissions,) = getFlowOperatorData(token, sender, currentContext.msgSender);
        bool hasPermissions = _getBooleanFlowOperatorPermissions(permissions, FlowChangeType.DELETE_FLOW);

        _StackVars_createOrUpdateFlow memory flowVars;
        flowVars.token = token;
        flowVars.sender = sender;
        flowVars.receiver = receiver;
        flowVars.flowRate = 0;

        newCtx = _deleteFlow(flowVars, hasPermissions, ctx, currentContext);
    }

    /// @dev IConstantFlowAgreementV1.getFlow implementation
    function getFlow(
        ISuperfluidToken token,
        address sender,
        address receiver
    )
        external
        view
        override
        returns (
            uint256 timestamp,
            int96 flowRate,
            uint256 deposit,
            uint256 owedDeposit
        )
    {
        (, FlowData memory data) = _getAgreementData(
            token,
            _generateFlowId(sender, receiver));

        return(
            data.timestamp,
            data.flowRate,
            data.deposit,
            data.owedDeposit
        );
    }

    /// @dev IConstantFlowAgreementV1.getFlow implementation
    function getFlowByID(
        ISuperfluidToken token,
        bytes32 flowId
    )
        external
        view
        override
        returns(
            uint256 timestamp,
            int96 flowRate,
            uint256 deposit,
            uint256 owedDeposit
        )
    {
        (, FlowData memory data) = _getAgreementData(
            token,
            flowId
        );

        return (
            data.timestamp,
            data.flowRate,
            data.deposit,
            data.owedDeposit
        );
    }

    /// @dev IConstantFlowAgreementV1.getAccountFlowInfo implementation
    function getAccountFlowInfo(
        ISuperfluidToken token,
        address account
    )
        external view override
        returns (
            uint256 timestamp,
            int96 flowRate,
            uint256 deposit,
            uint256 owedDeposit)
    {
        (, FlowData memory state) = _getAccountFlowState(token, account);
        return (
            state.timestamp,
            state.flowRate,
            state.deposit,
            state.owedDeposit
        );
    }

    /// @dev IConstantFlowAgreementV1.getNetFlow implementation
    function getNetFlow(
        ISuperfluidToken token,
        address account
    )
        external view override
        returns (int96 flowRate)
    {
        (, FlowData memory state) = _getAccountFlowState(token, account);
        return state.flowRate;
    }

    /**************************************************************************
     * Internal Helper Functions
     *************************************************************************/

    // Stack variables for _createOrUpdateFlow function, to avoid stack too deep issue
    // solhint-disable-next-line contract-name-camelcase
    struct _StackVars_createOrUpdateFlow {
        ISuperfluidToken token;
        address sender;
        address receiver;
        int96 flowRate;
    }

    /**
     * @dev Checks conditions for both create/update flow
     * returns the flowId and flowParams
     */
    function _createOrUpdateFlowCheck(
        _StackVars_createOrUpdateFlow memory flowVars,
        ISuperfluid.Context memory currentContext
    )
        internal pure
        returns(bytes32 flowId, FlowParams memory flowParams)
    {
        if (flowVars.receiver == address(0)) {
            revert CFA_ZERO_ADDRESS_RECEIVER();
        }

        flowId = _generateFlowId(flowVars.sender, flowVars.receiver);
        flowParams.flowId = flowId;
        flowParams.sender = flowVars.sender;
        flowParams.receiver = flowVars.receiver;
        flowParams.flowOperator = currentContext.msgSender;
        flowParams.flowRate = flowVars.flowRate;
        flowParams.userData = currentContext.userData;
        if (flowParams.sender == flowParams.receiver) revert CFA_NO_SELF_FLOW();
        if (flowParams.flowRate <= 0) revert CFA_INVALID_FLOW_RATE();
    }

    
    /**
     * @notice Checks whether or not the NFT hook can be called.
     * @dev A staticcall, so `CONSTANT_OUTFLOW_NFT` must be a view otherwise the assumption is that it reverts
     * @param token the super token that is being streamed
     * @return constantOutflowNFTAddress the address returned by low level call
     */
    function _canCallNFTHook(
        ISuperfluidToken token
    ) internal view returns (address constantOutflowNFTAddress) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(ISuperToken.CONSTANT_OUTFLOW_NFT.selector)
        );

        if (success) {
            // @note We are aware this may revert if a Custom SuperToken's
            // CONSTANT_OUTFLOW_NFT does not return data that can be
            // decoded to an address. This would mean it was intentionally
            // done by the creator of the Custom SuperToken logic and is
            // fully expected to revert in that case as the author desired.
            constantOutflowNFTAddress = abi.decode(data, (address));
        }
    }

    function _handleOnCreateHook(
        _StackVars_createOrUpdateFlow memory flowVars
    ) internal {
        uint256 gasLeftBefore = gasleft();

        address constantOutflowNFTAddress = _canCallNFTHook(flowVars.token);

        if (constantOutflowNFTAddress != address(0)) {
            try
                IConstantOutflowNFT(constantOutflowNFTAddress).onCreate(
                    flowVars.token,
                    flowVars.sender,
                    flowVars.receiver
                )
            // solhint-disable-next-line no-empty-blocks
            {

            } catch {
                SafeGasLibrary._revertWhenOutOfGas(gasLeftBefore);
            }
        }
    }

    function _handleOnUpdateHook(
        _StackVars_createOrUpdateFlow memory flowVars
    ) internal {
        uint256 gasLeftBefore = gasleft();

        address constantOutflowNFTAddress = _canCallNFTHook(flowVars.token);

        if (constantOutflowNFTAddress != address(0)) {
            try
                IConstantOutflowNFT(constantOutflowNFTAddress).onUpdate(
                    flowVars.token,
                    flowVars.sender,
                    flowVars.receiver
                )
            // solhint-disable-next-line no-empty-blocks
            {

            } catch {
                SafeGasLibrary._revertWhenOutOfGas(gasLeftBefore);
            }
        }
    }

    function _handleOnDeleteHook(
        _StackVars_createOrUpdateFlow memory flowVars
    ) internal {
        uint256 gasLeftBefore = gasleft();

        address constantOutflowNFTAddress = _canCallNFTHook(flowVars.token);

        if (constantOutflowNFTAddress != address(0)) {
            try
                IConstantOutflowNFT(constantOutflowNFTAddress).onDelete(
                    flowVars.token,
                    flowVars.sender,
                    flowVars.receiver
                )
            // solhint-disable-next-line no-empty-blocks
            {

            } catch {
                SafeGasLibrary._revertWhenOutOfGas(gasLeftBefore);
            }
        }
    }

    function _createFlow(
        _StackVars_createOrUpdateFlow memory flowVars,
        bytes calldata ctx,
        ISuperfluid.Context memory currentContext
    )
        internal
        returns(bytes memory newCtx)
    {
        (bytes32 flowId, FlowParams memory flowParams) = _createOrUpdateFlowCheck(flowVars, currentContext);

        (bool exist, FlowData memory oldFlowData) = _getAgreementData(flowVars.token, flowId);
        if (exist) revert CFA_FLOW_ALREADY_EXISTS();

        if (ISuperfluid(msg.sender).isApp(ISuperApp(flowVars.receiver))) {
            newCtx = _changeFlowToApp(
                flowVars.receiver,
                flowVars.token, flowParams, oldFlowData,
                ctx, currentContext, FlowChangeType.CREATE_FLOW);
        } else {
            newCtx = _changeFlowToNonApp(
                flowVars.token, flowParams, oldFlowData,
                ctx, currentContext);
        }

        _requireAvailableBalance(flowVars.token, flowVars.sender, currentContext);

        _handleOnCreateHook(flowVars);
    }

    function _updateFlow(
        _StackVars_createOrUpdateFlow memory flowVars,
        FlowData memory oldFlowData,
        bool exist,
        bytes calldata ctx,
        ISuperfluid.Context memory currentContext
    )
        internal
        returns(bytes memory newCtx)
    {
        (, FlowParams memory flowParams) = _createOrUpdateFlowCheck(flowVars, currentContext);

        if (!exist) revert CFA_FLOW_DOES_NOT_EXIST();

        if (ISuperfluid(msg.sender).isApp(ISuperApp(flowVars.receiver))) {
            newCtx = _changeFlowToApp(
                flowVars.receiver,
                flowVars.token, flowParams, oldFlowData,
                ctx, currentContext, FlowChangeType.UPDATE_FLOW);
        } else {
            newCtx = _changeFlowToNonApp(
                flowVars.token, flowParams, oldFlowData,
                ctx, currentContext);
        }

        _requireAvailableBalance(flowVars.token, flowVars.sender, currentContext);

        _handleOnUpdateHook(flowVars);
    }

    function _deleteFlow(
        _StackVars_createOrUpdateFlow memory flowVars,
        bool hasPermissions,
        bytes calldata ctx,
        ISuperfluid.Context memory currentContext
    )
        internal
        returns(bytes memory newCtx)
    {
        FlowParams memory flowParams;
        if (flowVars.sender == address(0)) {
            revert CFA_ZERO_ADDRESS_SENDER();
        }
        if (flowVars.receiver == address(0)) {
            revert CFA_ZERO_ADDRESS_RECEIVER();
        }
        flowParams.flowId = _generateFlowId(flowVars.sender, flowVars.receiver);
        flowParams.sender = flowVars.sender;
        flowParams.receiver = flowVars.receiver;
        flowParams.flowOperator = currentContext.msgSender;
        flowParams.flowRate = 0;
        flowParams.userData = currentContext.userData;
        (bool exist, FlowData memory oldFlowData) = _getAgreementData(flowVars.token, flowParams.flowId);
        if (!exist) revert CFA_FLOW_DOES_NOT_EXIST();

        (int256 availableBalance,,) = flowVars.token.realtimeBalanceOf(flowVars.sender, currentContext.timestamp);

        // delete should only be called by sender, receiver or flowOperator
        // unless it is a liquidation (availale balance < 0)
        if (currentContext.msgSender != flowVars.sender &&
            currentContext.msgSender != flowVars.receiver &&
            !hasPermissions)
        {
            if (!ISuperfluid(msg.sender).isAppJailed(ISuperApp(flowVars.sender)) &&
                !ISuperfluid(msg.sender).isAppJailed(ISuperApp(flowVars.receiver))) {
                if (availableBalance >= 0) revert CFA_NON_CRITICAL_SENDER();
            }
        }

        if (availableBalance < 0) {
            _makeLiquidationPayouts(
                flowVars.token,
                availableBalance,
                flowParams,
                oldFlowData,
                currentContext.msgSender);
        }

        newCtx = ctx;
        // if the sender of the flow is deleting the flow
        if (currentContext.msgSender == flowVars.sender) {
            // if the sender is deleting a flow to a super app receiver
            if (ISuperfluid(msg.sender).isApp(ISuperApp(flowVars.receiver))) {
                newCtx = _changeFlowToApp(
                    flowVars.receiver,
                    flowVars.token, flowParams, oldFlowData,
                    newCtx, currentContext, FlowChangeType.DELETE_FLOW);
            } else {
                // if the receiver is not a super app (sender may be a super app or non super app)
                newCtx = _changeFlowToNonApp(
                    flowVars.token, flowParams, oldFlowData,
                    newCtx, currentContext);
            }
        // if the receiver of the flow is deleting the flow
        } else if (currentContext.msgSender == flowVars.receiver) {
            // if the flow being deleted by the receiver has a super app sender
            if (ISuperfluid(msg.sender).isApp(ISuperApp(flowVars.sender))) {
                newCtx = _changeFlowToApp(
                    flowVars.sender,
                    flowVars.token, flowParams, oldFlowData,
                    newCtx, currentContext, FlowChangeType.DELETE_FLOW);
            // if the receiver of the flow deleting the flow is a super app
            } else if (ISuperfluid(msg.sender).isApp(ISuperApp(flowVars.receiver))) {
                newCtx = _changeFlowToApp(
                    address(0),
                    flowVars.token, flowParams, oldFlowData,
                    newCtx, currentContext, FlowChangeType.DELETE_FLOW);
            // if the sender is not a super app (the stream is not coming to or from a super app)
            } else {
                newCtx = _changeFlowToNonApp(
                    flowVars.token, flowParams, oldFlowData,
                    newCtx, currentContext);
            }
        // flowOperator case OR liquidation case (when the msgSender isn't the sender or receiver)
        } else /* liquidations or flowOperator deleting a flow */ {
            // if the sender is an app and is critical
            // we jail the app
            if (ISuperfluid(msg.sender).isApp(ISuperApp(flowVars.sender)) && availableBalance < 0) {
                newCtx = ISuperfluid(msg.sender).jailApp(
                    newCtx,
                    ISuperApp(flowVars.sender),
                    SuperAppDefinitions.APP_RULE_NO_CRITICAL_SENDER_ACCOUNT);
            }
            // if the stream we're deleting (possibly liquidating) has a receiver that is a super app
            // always attempt to call receiver callback
            if (ISuperfluid(msg.sender).isApp(ISuperApp(flowVars.receiver))) {
                newCtx = _changeFlowToApp(
                    flowVars.receiver,
                    flowVars.token, flowParams, oldFlowData,
                    newCtx, currentContext, FlowChangeType.DELETE_FLOW);
            // if the stream we're deleting (possibly liquidating) has a receiver that is not a super app
            // or the sender is a super app or the sender is not a super app
            } else {
                newCtx = _changeFlowToNonApp(
                    flowVars.token, flowParams, oldFlowData,
                    newCtx, currentContext);
            }
        }

        _handleOnDeleteHook(flowVars);
    }

    /**************************************************************************
     * ACL Functions
     *************************************************************************/

    /// @dev IConstantFlowAgreementV1.createFlowByOperator implementation
    function createFlowByOperator(
        ISuperfluidToken token,
        address sender,
        address receiver,
        int96 flowRate,
        bytes calldata ctx
    )
        external override
        returns(bytes memory newCtx)
    {
        ISuperfluid.Context memory currentContext = AgreementLibrary.authorizeTokenAccess(token, ctx);
        if (currentContext.msgSender == sender) revert CFA_ACL_NO_SENDER_CREATE();

        {
            // check if flow operator has create permissions
            (
                bytes32 flowOperatorId,
                uint8 permissions,
                int96 flowRateAllowance
            ) = getFlowOperatorData(token, sender, currentContext.msgSender);
            if (!_getBooleanFlowOperatorPermissions(permissions, FlowChangeType.CREATE_FLOW)) {
                revert CFA_ACL_OPERATOR_NO_CREATE_PERMISSIONS();
            }

            // check if desired flow rate is allowed and update flow rate allowance
            int96 updatedFlowRateAllowance = flowRateAllowance == type(int96).max
                ? flowRateAllowance
                : flowRateAllowance - flowRate;
            if (updatedFlowRateAllowance < 0) revert CFA_ACL_FLOW_RATE_ALLOWANCE_EXCEEDED();
            _updateFlowRateAllowance(token, flowOperatorId, permissions, updatedFlowRateAllowance);
        }
        {
            _StackVars_createOrUpdateFlow memory flowVars;
            flowVars.token = token;
            flowVars.sender = sender;
            flowVars.receiver = receiver;
            flowVars.flowRate = flowRate;
            newCtx = _createFlow(
                flowVars,
                ctx,
                currentContext
            );
        }
    }

    /// @dev IConstantFlowAgreementV1.updateFlowByOperator implementation
    function updateFlowByOperator(
        ISuperfluidToken token,
        address sender,
        address receiver,
        int96 flowRate,
        bytes calldata ctx
    )
        external override
        returns(bytes memory newCtx)
    {
        ISuperfluid.Context memory currentContext = AgreementLibrary.authorizeTokenAccess(token, ctx);
        if (currentContext.msgSender == sender) revert CFA_ACL_NO_SENDER_UPDATE();

        // check if flow exists
        (bool exist, FlowData memory oldFlowData) = _getAgreementData(token, _generateFlowId(sender, receiver));

        {
            // check if flow operator has create permissions
            (
                bytes32 flowOperatorId,
                uint8 permissions,
                int96 flowRateAllowance
            ) = getFlowOperatorData(token, sender, currentContext.msgSender);
            if (!_getBooleanFlowOperatorPermissions(permissions, FlowChangeType.UPDATE_FLOW)) {
                revert CFA_ACL_OPERATOR_NO_UPDATE_PERMISSIONS();
            }

            // check if desired flow rate is allowed and update flow rate allowance
            int96 updatedFlowRateAllowance = flowRateAllowance == type(int96).max || oldFlowData.flowRate >= flowRate
                ? flowRateAllowance
                : flowRateAllowance - (flowRate - oldFlowData.flowRate);
            if (updatedFlowRateAllowance < 0) revert CFA_ACL_FLOW_RATE_ALLOWANCE_EXCEEDED();
            _updateFlowRateAllowance(token, flowOperatorId, permissions, updatedFlowRateAllowance);
        }

        {
            _StackVars_createOrUpdateFlow memory flowVars;
            flowVars.token = token;
            flowVars.sender = sender;
            flowVars.receiver = receiver;
            flowVars.flowRate = flowRate;
            newCtx = _updateFlow(
                flowVars,
                oldFlowData,
                exist,
                ctx,
                currentContext
            );
        }
    }

    /// @dev IConstantFlowAgreementV1.deleteFlowByOperator implementation
    function deleteFlowByOperator(
        ISuperfluidToken token,
        address sender,
        address receiver,
        bytes calldata ctx
    )
        external override
        returns(bytes memory newCtx)
    {
        ISuperfluid.Context memory currentContext = AgreementLibrary.authorizeTokenAccess(token, ctx);
        (,uint8 permissions,) = getFlowOperatorData(token, sender, currentContext.msgSender);
        bool hasPermissions = _getBooleanFlowOperatorPermissions(permissions, FlowChangeType.DELETE_FLOW);
        if (!hasPermissions) revert CFA_ACL_OPERATOR_NO_DELETE_PERMISSIONS();

        _StackVars_createOrUpdateFlow memory flowVars;
        flowVars.token = token;
        flowVars.sender = sender;
        flowVars.receiver = receiver;
        flowVars.flowRate = 0;

        newCtx = _deleteFlow(flowVars, hasPermissions, ctx, currentContext);
    }

    /// @dev IConstantFlowAgreementV1.updateFlowOperatorPermissions implementation
    function updateFlowOperatorPermissions(
        ISuperfluidToken token,
        address flowOperator,
        uint8 permissions,
        int96 flowRateAllowance, // flowRateBudget
        bytes calldata ctx
    ) public override returns(bytes memory newCtx) {
        newCtx = ctx;
        if (!FlowOperatorDefinitions.isPermissionsClean(permissions)) revert CFA_ACL_UNCLEAN_PERMISSIONS();
        ISuperfluid.Context memory currentContext = AgreementLibrary.authorizeTokenAccess(token, ctx);
        // [SECURITY] NOTE: we are holding the assumption here that ctx is correct and we validate it with
        // authorizeTokenAccess:
        if (currentContext.msgSender == flowOperator) revert CFA_ACL_NO_SENDER_FLOW_OPERATOR();
        if (flowRateAllowance < 0) revert CFA_ACL_NO_NEGATIVE_ALLOWANCE();
        FlowOperatorData memory flowOperatorData;
        flowOperatorData.permissions = permissions;
        flowOperatorData.flowRateAllowance = flowRateAllowance;
        bytes32 flowOperatorId = _generateFlowOperatorId(currentContext.msgSender, flowOperator);
        token.updateAgreementData(flowOperatorId, _encodeFlowOperatorData(flowOperatorData));

        emit FlowOperatorUpdated(token, currentContext.msgSender, flowOperator, permissions, flowRateAllowance);
    }

    /// @dev IConstantFlowAgreementV1.increaseFlowRateAllowance implementation
    function increaseFlowRateAllowance(
        ISuperfluidToken token,
        address flowOperator,
        int96 addedFlowRateAllowance, // flowRateBudget
        bytes calldata ctx
    ) public override returns (bytes memory newCtx) {
        newCtx = ctx;

        // [SECURITY] NOTE: we are holding the assumption here that ctx is correct and we validate it with
        // authorizeTokenAccess:
        ISuperfluid.Context memory currentContext = AgreementLibrary.authorizeTokenAccess(token, ctx);

        if (currentContext.msgSender == flowOperator) revert CFA_ACL_NO_SENDER_FLOW_OPERATOR();
        if (addedFlowRateAllowance < 0) revert CFA_ACL_NO_NEGATIVE_ALLOWANCE();
        
        (
            bytes32 flowOperatorId,
            uint8 oldPermissions,
            int96 oldFlowRateAllowance
        ) = getFlowOperatorData(token, currentContext.msgSender, flowOperator);

        // @note this will revert if it overflows
        int96 newFlowRateAllowance = oldFlowRateAllowance + addedFlowRateAllowance;
        _updateFlowRateAllowance(
            token,
            flowOperatorId,
            oldPermissions,
            newFlowRateAllowance
        );

        emit FlowOperatorUpdated(
            token,
            currentContext.msgSender,
            flowOperator,
            oldPermissions,
            newFlowRateAllowance
        );
    }

    /// @dev IConstantFlowAgreementV1.decreaseFlowRateAllowance implementation
    function decreaseFlowRateAllowance(
        ISuperfluidToken token,
        address flowOperator,
        int96 subtractedFlowRateAllowance, // flowRateBudget
        bytes calldata ctx
    ) public override returns (bytes memory newCtx) {
        newCtx = ctx;

        // [SECURITY] NOTE: we are holding the assumption here that ctx is correct and we validate it with
        // authorizeTokenAccess:
        ISuperfluid.Context memory currentContext = AgreementLibrary
            .authorizeTokenAccess(token, ctx);

        if (currentContext.msgSender == flowOperator) revert CFA_ACL_NO_SENDER_FLOW_OPERATOR();
        if (subtractedFlowRateAllowance < 0) revert CFA_ACL_NO_NEGATIVE_ALLOWANCE();

        (
            bytes32 flowOperatorId,
            uint8 oldPermissions,
            int96 oldFlowRateAllowance
        ) = getFlowOperatorData(token, currentContext.msgSender, flowOperator);
        
        int96 newFlowRateAllowance = oldFlowRateAllowance - subtractedFlowRateAllowance;

        // @note this defends against negative allowance
        if (newFlowRateAllowance < 0) revert CFA_ACL_NO_NEGATIVE_ALLOWANCE();

        _updateFlowRateAllowance(
            token,
            flowOperatorId,
            oldPermissions,
            newFlowRateAllowance
        );

        emit FlowOperatorUpdated(
            token,
            currentContext.msgSender,
            flowOperator,
            oldPermissions,
            newFlowRateAllowance
        );
    }

    /// @dev IConstantFlowAgreementV1.authorizeFlowOperatorWithFullControl implementation
    function authorizeFlowOperatorWithFullControl(
        ISuperfluidToken token,
        address flowOperator,
        bytes calldata ctx
    )
        external override
        returns(bytes memory newCtx)
    {
        newCtx = updateFlowOperatorPermissions(
            token,
            flowOperator,
            FlowOperatorDefinitions.AUTHORIZE_FULL_CONTROL,
            type(int96).max,
            ctx
        );
    }

    /// @dev IConstantFlowAgreementV1.revokeFlowOperatorWithFullControl implementation
    function revokeFlowOperatorWithFullControl(
        ISuperfluidToken token,
        address flowOperator,
        bytes calldata ctx
    )
        external override
        returns(bytes memory newCtx)
    {
        // NOTE: REVOKE_FULL_CONTROL = 0
        newCtx = updateFlowOperatorPermissions(token, flowOperator, 0, 0, ctx);
    }

    /// @dev IConstantFlowAgreementV1.getFlowOperatorData implementation
    function getFlowOperatorData(
        ISuperfluidToken token,
        address sender,
        address flowOperator
    )
        public view override
        returns(bytes32 flowOperatorId, uint8 permissions, int96 flowRateAllowance)
    {
        flowOperatorId = _generateFlowOperatorId(sender, flowOperator);
        (, FlowOperatorData memory flowOperatorData) = _getFlowOperatorData(token, flowOperatorId);
        permissions = flowOperatorData.permissions;
        flowRateAllowance = flowOperatorData.flowRateAllowance;
    }

    /// @dev IConstantFlowAgreementV1.getFlowOperatorDataByID implementation
    function getFlowOperatorDataByID(
        ISuperfluidToken token,
        bytes32 flowOperatorId
    )
        external view override
        returns(uint8 permissions, int96 flowRateAllowance)
    {
        (, FlowOperatorData memory flowOperatorData) = _getFlowOperatorData(token, flowOperatorId);
        permissions = flowOperatorData.permissions;
        flowRateAllowance = flowOperatorData.flowRateAllowance;
    }

    /**************************************************************************
     * Internal State Functions
     *************************************************************************/

    enum FlowChangeType {
        CREATE_FLOW,
        UPDATE_FLOW,
        DELETE_FLOW
    }

    function _getAccountFlowState
    (
        ISuperfluidToken token,
        address account
    )
        private view
        returns(bool exist, FlowData memory)
    {
        bytes32[] memory data = token.getAgreementStateSlot(address(this), account, 0 /* slotId */, 1 /* length */);
        return _decodeFlowData(uint256(data[0]));
    }

    function _getAgreementData
    (
        ISuperfluidToken token,
        bytes32 dId
    )
        private view
        returns (bool exist, FlowData memory)
    {
        bytes32[] memory data = token.getAgreementData(address(this), dId, 1);
        return _decodeFlowData(uint256(data[0]));
    }

    function _getFlowOperatorData
    (
        ISuperfluidToken token,
        bytes32 flowOperatorId
    )
        private view
        returns (bool exist, FlowOperatorData memory)
    {
        // 1 because we are storing the flowOperator data in one word
        bytes32[] memory data = token.getAgreementData(address(this), flowOperatorId, 1);
        return _decodeFlowOperatorData(uint256(data[0]));
    }

    function _updateFlowRateAllowance
    (
        ISuperfluidToken token,
        bytes32 flowOperatorId,
        uint8 existingPermissions,
        int96 updatedFlowRateAllowance
    )
        private
    {
        FlowOperatorData memory flowOperatorData;
        flowOperatorData.permissions = existingPermissions;
        flowOperatorData.flowRateAllowance = updatedFlowRateAllowance;
        token.updateAgreementData(flowOperatorId, _encodeFlowOperatorData(flowOperatorData));
    }

    function _updateAccountFlowState(
        ISuperfluidToken token,
        address account,
        int96 flowRateDelta,
        int256 depositDelta,
        int256 owedDepositDelta,
        uint256 currentTimestamp
    )
        private
        returns (int96 newNetFlowRate)
    {
        (, FlowData memory state) = _getAccountFlowState(token, account);
        int256 dynamicBalance = (currentTimestamp - state.timestamp).toInt256()
            * int256(state.flowRate);
        if (dynamicBalance != 0) {
            token.settleBalance(account, dynamicBalance);
        }
        state.flowRate = state.flowRate + flowRateDelta;
        state.timestamp = currentTimestamp;
        state.deposit = (state.deposit.toInt256() + depositDelta).toUint256();
        state.owedDeposit = (state.owedDeposit.toInt256() + owedDepositDelta).toUint256();

        token.updateAgreementStateSlot(account, 0 /* slot id */, _encodeFlowData(state));

        return state.flowRate;
    }

    /**
     * @dev update a flow to a non-app receiver
     */
    function _changeFlowToNonApp(
        ISuperfluidToken token,
        FlowParams memory flowParams,
        FlowData memory oldFlowData,
        bytes memory ctx,
        ISuperfluid.Context memory currentContext
    )
        private
        returns (bytes memory newCtx)
    {
        // owed deposit should have been always zero, since an app should never become a non app
        assert(oldFlowData.owedDeposit == 0);

        // STEP 1: update the flow
        int256 depositDelta;
        FlowData memory newFlowData;
        (depositDelta,,newFlowData) = _changeFlow(
            currentContext.timestamp,
            currentContext.appCreditToken,
            token, flowParams, oldFlowData);

        // STEP 2: update app credit used
        if (currentContext.appCreditToken == token) {
            newCtx = ISuperfluid(msg.sender).ctxUseCredit(
                ctx,
                depositDelta
            );
        } else {
            newCtx = ctx;
        }
    }

    /**
     * @dev change a flow to a app receiver
     */

    // Stack variables for _changeFlowToApp function, to avoid stack too deep issue
    // solhint-disable-next-line contract-name-camelcase
    struct _StackVars_changeFlowToApp {
        bytes cbdata;
        FlowData newFlowData;
        ISuperfluid.Context appContext;
    }
    function _changeFlowToApp(
        address appToCallback,
        ISuperfluidToken token,
        FlowParams memory flowParams,
        FlowData memory oldFlowData,
        bytes memory ctx,
        ISuperfluid.Context memory currentContext,
        FlowChangeType optype
    )
        private
        returns (bytes memory newCtx)
    {
        newCtx = ctx;
        // apply callbacks
        _StackVars_changeFlowToApp memory vars;

        // call callback
        if (appToCallback != address(0)) {
            AgreementLibrary.CallbackInputs memory cbStates = AgreementLibrary.createCallbackInputs(
                token,
                appToCallback,
                flowParams.flowId,
                abi.encode(flowParams.sender, flowParams.receiver)
            );

            // call the before callback
            if (optype == FlowChangeType.CREATE_FLOW) {
                cbStates.noopBit = SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP;
            } else if (optype == FlowChangeType.UPDATE_FLOW) {
                cbStates.noopBit = SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP;
            } else /* if (optype == FlowChangeType.DELETE_FLOW) */ {
                cbStates.noopBit = SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP;
            }
            vars.cbdata = AgreementLibrary.callAppBeforeCallback(cbStates, ctx);

            ISuperfluidGovernance gov = ISuperfluidGovernance(ISuperfluid(msg.sender).getGovernance());

            (,cbStates.appCreditGranted,) = _changeFlow(
                    currentContext.timestamp,
                    currentContext.appCreditToken,
                    token, flowParams, oldFlowData);


            // Rule CFA-2
            // https://github.com/superfluid-finance/protocol-monorepo/wiki/About-App-Credit
            // Allow apps to take an additional amount of app credit (minimum deposit)
            uint256 minimumDeposit = gov.getConfigAsUint256(
                ISuperfluid(msg.sender), token, SUPERTOKEN_MINIMUM_DEPOSIT_KEY);

            // NOTE: we do not provide additionalAppCreditAmount when cbStates.appCreditGranted is 0
            // (closing streams)
            uint256 additionalAppCreditAmount = cbStates.appCreditGranted == 0
                ? 0
                : AgreementLibrary.max(
                    DEFAULT_MINIMUM_DEPOSIT,
                    minimumDeposit
                );
            cbStates.appCreditGranted = cbStates.appCreditGranted + additionalAppCreditAmount;

            cbStates.appCreditUsed = oldFlowData.owedDeposit.toInt256();

            // - each app level can at least "relay" the same amount of input flow rate to others
            // - each app level gets the same amount of credit

            if (optype == FlowChangeType.CREATE_FLOW) {
                cbStates.noopBit = SuperAppDefinitions.AFTER_AGREEMENT_CREATED_NOOP;
            } else if (optype == FlowChangeType.UPDATE_FLOW) {
                cbStates.noopBit = SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP;
            } else /* if (optype == FlowChangeType.DELETE_FLOW) */ {
                cbStates.noopBit = SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP;
            }
            (vars.appContext, newCtx) = AgreementLibrary.callAppAfterCallback(cbStates, vars.cbdata, newCtx);

            // NB: the callback might update the same flow!!
            // reload the flow data
            (, vars.newFlowData) = _getAgreementData(token, flowParams.flowId);
        } else {
            (,,vars.newFlowData) = _changeFlow(
                    currentContext.timestamp,
                    currentContext.appCreditToken,
                    token, flowParams, oldFlowData);
        }

        // REVIEW the re-entrace assumptions from this point on

        // NOTE: vars.appContext.appCreditUsed will be adjusted by callAppAfterCallback
        // and its range will be [0, currentContext.appCreditGranted]
        {
            int256 appCreditDelta = vars.appContext.appCreditUsed
                - oldFlowData.owedDeposit.toInt256();

            // update flow data and account state with the credit delta
            {
                vars.newFlowData.deposit = (vars.newFlowData.deposit.toInt256()
                    + appCreditDelta).toUint256();
                vars.newFlowData.owedDeposit = (vars.newFlowData.owedDeposit.toInt256()
                    + appCreditDelta).toUint256();
                token.updateAgreementData(flowParams.flowId, _encodeFlowData(vars.newFlowData));
                // update sender and receiver deposit (for sender) and owed deposit (for receiver)
                _updateAccountFlowState(
                    token,
                    flowParams.sender,
                    0, // flow rate delta
                    appCreditDelta, // deposit delta
                    0, // owed deposit delta
                    currentContext.timestamp
                );
                _updateAccountFlowState(
                    token,
                    flowParams.receiver,
                    0, // flow rate delta
                    0, // deposit delta
                    appCreditDelta, // owed deposit delta
                    currentContext.timestamp
                );
            }

            if (address(currentContext.appCreditToken) == address(0) ||
                currentContext.appCreditToken == token)
            {
                newCtx = ISuperfluid(msg.sender).ctxUseCredit(
                    newCtx,
                    appCreditDelta
                );
            }

            // if receiver super app doesn't have enough available balance to give back app credit
            // revert (non termination callbacks),
            // or take it from the sender and jail the app
            if (ISuperfluid(msg.sender).isApp(ISuperApp(flowParams.receiver))) {
                int256 availableBalance;
                (availableBalance,,) = token.realtimeBalanceOf(flowParams.receiver, currentContext.timestamp);
                if (availableBalance < 0) {
                    // app goes broke, send the app to jail
                    if (optype == FlowChangeType.DELETE_FLOW) {
                        newCtx = ISuperfluid(msg.sender).jailApp(
                            newCtx,
                            ISuperApp(flowParams.receiver),
                            SuperAppDefinitions.APP_RULE_NO_CRITICAL_RECEIVER_ACCOUNT);
                        // calculate user's damage
                        int256 userDamageAmount = AgreementLibrary.min(
                            // user will take the damage if the app is broke,
                            -availableBalance,
                            // but user's damage is limited to the amount of app credit it gives to the app
                            // appCreditDelta should ALWAYS be negative because we are closing an agreement
                            // therefore the value will be positive due to the '-' sign in front of it
                            -appCreditDelta);
                        token.settleBalance(
                            flowParams.sender,
                            -userDamageAmount
                        );
                        token.settleBalance(
                            flowParams.receiver,
                            userDamageAmount
                        );
                    } else {
                        revert ISuperfluid.APP_RULE(SuperAppDefinitions.APP_RULE_NO_CRITICAL_RECEIVER_ACCOUNT);
                    }
                }
            }
        }
    }

    // Stack variables for _changeFlow function, to avoid stack too deep issue
    // solhint-disable-next-line contract-name-camelcase
    struct _StackVars_changeFlow {
        int96 totalSenderFlowRate;
        int96 totalReceiverFlowRate;
    }

    /**
     * @dev change flow between sender and receiver with new flow rate
     *
     * NOTE:
     * - leaving owed deposit unchanged for later adjustment
     * - depositDelta output is always clipped (see _clipDepositNumberRoundingUp)
     */
    function _changeFlow(
        uint256 currentTimestamp,
        ISuperfluidToken appCreditToken,
        ISuperfluidToken token,
        FlowParams memory flowParams,
        FlowData memory oldFlowData
    )
        private
        returns (
            int256 depositDelta,
            uint256 appCreditBase,
            FlowData memory newFlowData
        )
    {
        uint256 newDeposit;
        { // enclosed block to avoid stack too deep error
            uint256 minimumDeposit;
            // STEP 1: calculate deposit required for the flow
            {
                (uint256 liquidationPeriod, ) = _decode3PsData(token);
                ISuperfluidGovernance gov = ISuperfluidGovernance(ISuperfluid(msg.sender).getGovernance());
                minimumDeposit = gov.getConfigAsUint256(
                    ISuperfluid(msg.sender), token, SUPERTOKEN_MINIMUM_DEPOSIT_KEY);
                // rounding up the number for app credit too
                // CAVEAT:
                // - Now app could create a flow rate that is slightly higher than the incoming flow rate.
                // - The app may be jailed due to negative balance if it does this without its own balance.
                // Rule of thumbs:
                // - App can use app credit to create a flow that has the same incoming flow rate
                // - But due to deposit clipping, there is no guarantee that the sum of the out going flow
                //   deposit can be covered by the credit always.
                // - It is advisable for the app to check the credit usages carefully, and if possible
                //   Always have some its own balances to cover the deposits.

                // preliminary calc of new deposit required, may be changed later in step 2.
                // used as a variable holding the new deposit amount in the meantime
                appCreditBase = _calculateDeposit(flowParams.flowRate, liquidationPeriod);
            }

            // STEP 2: apply minimum deposit rule and calculate deposit delta
            // preliminary calc depositDelta (minimum deposit rule not yet applied)
            depositDelta = appCreditBase.toInt256()
                - oldFlowData.deposit.toInt256()
                + oldFlowData.owedDeposit.toInt256();

            // preliminary calc newDeposit (minimum deposit rule not yet applied)
            newDeposit = (oldFlowData.deposit.toInt256() + depositDelta).toUint256();

            // calc depositDelta and newDeposit with minimum deposit rule applied
            if (newDeposit < minimumDeposit && flowParams.flowRate > 0) {
                depositDelta = minimumDeposit.toInt256()
                    - oldFlowData.deposit.toInt256()
                    + oldFlowData.owedDeposit.toInt256();
                newDeposit = minimumDeposit;
            }

            // credit should be of the same token
            if (address(appCreditToken) != address(0) &&
                appCreditToken != token)
            {
                appCreditBase = 0;
            }

            // STEP 3: update current flow info
            newFlowData = FlowData(
                flowParams.flowRate > 0 ? currentTimestamp : 0,
                flowParams.flowRate,
                newDeposit,
                oldFlowData.owedDeposit // leaving it unchanged for later adjustment
            );
            token.updateAgreementData(flowParams.flowId, _encodeFlowData(newFlowData));
        }
        {
            _StackVars_changeFlow memory vars;
            // STEP 4: update sender and receiver account flow state with the deltas
            vars.totalSenderFlowRate = _updateAccountFlowState(
                token,
                flowParams.sender,
                oldFlowData.flowRate - flowParams.flowRate,
                depositDelta,
                0,
                currentTimestamp
            );
            vars.totalReceiverFlowRate = _updateAccountFlowState(
                token,
                flowParams.receiver,
                flowParams.flowRate - oldFlowData.flowRate,
                0,
                0, // leaving owed deposit unchanged for later adjustment
                currentTimestamp
            );

            // STEP 5: emit the FlowUpdated Event
            // NOTE we emit these two events one after the other
            // so the subgraph can properly handle this in the
            // mapping function
            emit FlowUpdated(
                token,
                flowParams.sender,
                flowParams.receiver,
                flowParams.flowRate,
                vars.totalSenderFlowRate,
                vars.totalReceiverFlowRate,
                flowParams.userData
            );
            emit FlowUpdatedExtension(
                flowParams.flowOperator,
                newDeposit
            );
        }
    }
    function _requireAvailableBalance(
        ISuperfluidToken token,
        address flowSender,
        ISuperfluid.Context memory currentContext
    )
        private view
    {
        // do not enforce balance checks during callbacks for the appCreditToken
        if (currentContext.callType != ContextDefinitions.CALL_INFO_CALL_TYPE_APP_CALLBACK ||
            currentContext.appCreditToken != token) {
            (int256 availableBalance,,) = token.realtimeBalanceOf(flowSender, currentContext.timestamp);
            if (availableBalance < 0) {
                revert CFA_INSUFFICIENT_BALANCE();
            }
        }
    }

    function _makeLiquidationPayouts(
        ISuperfluidToken token,
        int256 availableBalance,
        FlowParams memory flowParams,
        FlowData memory flowData,
        address liquidator
    )
        private
    {
        (,FlowData memory senderAccountState) = _getAccountFlowState(token, flowParams.sender);

        int256 signedSingleDeposit = flowData.deposit.toInt256();
        // TODO: GDA deposit should be considered here too
        int256 signedTotalCFADeposit = senderAccountState.deposit.toInt256();
        bytes memory liquidationTypeData;
        bool isCurrentlyPatricianPeriod;

        // Liquidation rules:
        //    - let Available Balance = AB (is negative)
        //    -     Agreement Single Deposit = SD
        //    -     Agreement Total Deposit = TD
        //    -     Total Reward Left = RL = AB + TD
        // #1 Can the total account deposit still cover the available balance deficit?
        int256 totalRewardLeft = availableBalance + signedTotalCFADeposit;

        // To retrieve patrician period
        // Note: curly brackets are to handle stack too deep overflow issue
        {
            (uint256 liquidationPeriod, uint256 patricianPeriod) = _decode3PsData(token);
            isCurrentlyPatricianPeriod = _isPatricianPeriod(
                availableBalance,
                signedTotalCFADeposit,
                liquidationPeriod,
                patricianPeriod
            );
        }

        // user is in a critical state
        if (totalRewardLeft >= 0) {
            // the liquidator is always whoever triggers the liquidation, but the
            // account which receives the reward will depend on the period (Patrician or Pleb)
            // #1.a.1 yes: then reward = (SD / TD) * RL
            int256 rewardAmount = signedSingleDeposit * totalRewardLeft / signedTotalCFADeposit;
            liquidationTypeData = abi.encode(1, isCurrentlyPatricianPeriod ? 0 : 1);
            token.makeLiquidationPayoutsV2(
                flowParams.flowId, // id
                liquidationTypeData, // (1 means "v1" of this encoding schema) - 0 or 1 for patrician or pleb
                liquidator, // liquidatorAddress

                // useDefaultRewardAccount: true in patrician period, else liquidator gets reward
                isCurrentlyPatricianPeriod,

                flowParams.sender, // targetAccount
                rewardAmount.toUint256(), // rewardAmount: remaining deposit of the flow to be liquidated
                rewardAmount * -1 // targetAccountBalanceDelta: amount deducted from the flow sender
            );
        } else {
            // #1.b.1 no: then the liquidator takes full amount of the single deposit
            int256 rewardAmount = signedSingleDeposit;
            liquidationTypeData = abi.encode(1, 2);
            token.makeLiquidationPayoutsV2(
                flowParams.flowId, // id
                liquidationTypeData, // (1 means "v1" of this encoding schema) - 2 for pirate/bailout period
                liquidator, // liquidatorAddress
                false, // useDefaultRewardAccount: out of patrician period, in pirate period, so always false
                flowParams.sender, // targetAccount
                rewardAmount.toUint256(), // rewardAmount: single deposit of flow
                totalRewardLeft * -1 // targetAccountBalanceDelta: amount to bring sender AB to 0
                // NOTE: bailoutAmount = rewardAmount + targetAccountBalanceDelta + paid by rewardAccount
            );
        }
    }

    /**************************************************************************
     * Deposit Calculation Pure Functions
     *************************************************************************/

    function _clipDepositNumberRoundingDown(uint256 deposit)
        internal pure
        returns(uint256)
    {
        return ((deposit >> 32)) << 32;
    }

    function _clipDepositNumberRoundingUp(uint256 deposit)
        internal pure
        returns(uint256)
    {
        // clipping the value, rounding up
        uint256 rounding = (deposit & type(uint32).max) > 0 ? 1 : 0;
        return ((deposit >> 32) + rounding) << 32;
    }

    function _calculateDeposit(
        int96 flowRate,
        uint256 liquidationPeriod
    )
        internal pure
        returns(uint256 deposit)
    {
        if (flowRate == 0) return 0;

        // NOTE: safecast for int96 with extra assertion
        assert(liquidationPeriod <= uint256(int256(type(int96).max)));
        deposit = uint256(int256(flowRate * int96(uint96(liquidationPeriod))));
        return _clipDepositNumberRoundingUp(deposit);
    }

    /**************************************************************************
     * Flow Data Pure Functions
     *************************************************************************/

    function _generateFlowId(address sender, address receiver) private pure returns(bytes32 id) {
        return keccak256(abi.encode(sender, receiver));
    }

    //
    // Data packing:
    //
    // WORD A: | timestamp  | flowRate | deposit | owedDeposit |
    //         | 32b        | 96b      | 64      | 64          |
    //
    // NOTE:
    // - flowRate has 96 bits length
    // - deposit has 96 bits length too, but 32 bits are clipped-off when storing

    function _encodeFlowData
    (
        FlowData memory flowData
    )
        internal pure
        returns(bytes32[] memory data)
    {
        // enable these for debugging
        // assert(flowData.deposit & type(uint32).max == 0);
        // assert(flowData.owedDeposit & type(uint32).max == 0);
        data = new bytes32[](1);
        data[0] = bytes32(
            ((uint256(flowData.timestamp)) << 224) |
            ((uint256(uint96(flowData.flowRate)) << 128)) |
            (uint256(flowData.deposit) >> 32 << 64) |
            (uint256(flowData.owedDeposit) >> 32)
        );
    }

    function _decodeFlowData
    (
        uint256 wordA
    )
        internal pure
        returns(bool exist, FlowData memory flowData)
    {
        exist = wordA > 0;
        if (exist) {
            flowData.timestamp = uint32(wordA >> 224);
            // NOTE because we are upcasting from type(uint96).max to uint256 to int256, we do not need to use safecast
            flowData.flowRate = int96(int256(wordA >> 128) & int256(uint256(type(uint96).max)));
            flowData.deposit = ((wordA >> 64) & uint256(type(uint64).max)) << 32 /* recover clipped bits*/;
            flowData.owedDeposit = (wordA & uint256(type(uint64).max)) << 32 /* recover clipped bits*/;
        }
    }

    /**************************************************************************
     * 3P's Pure Functions
     *************************************************************************/

    //
    // Data packing:
    //
    // WORD A: |    reserved    | patricianPeriod | liquidationPeriod |
    //         |      192       |        32       |         32        |
    //
    // NOTE:
    // - liquidation period has 32 bits length
    // - patrician period also has 32 bits length

    function _decode3PsData(
        ISuperfluidToken token
    )
        internal view
        returns(uint256 liquidationPeriod, uint256 patricianPeriod)
    {
        ISuperfluidGovernance gov = ISuperfluidGovernance(ISuperfluid(_host).getGovernance());
        uint256 pppConfig = gov.getConfigAsUint256(ISuperfluid(_host), token, CFAV1_PPP_CONFIG_KEY);
        (liquidationPeriod, patricianPeriod) = SuperfluidGovernanceConfigs.decodePPPConfig(pppConfig);
    }

    function _isPatricianPeriod(
        int256 availableBalance,
        int256 signedTotalCFADeposit,
        uint256 liquidationPeriod,
        uint256 patricianPeriod
    )
        internal pure
        returns (bool)
    {
        if (signedTotalCFADeposit == 0) {
            return false;
        }

        int256 totalRewardLeft = availableBalance + signedTotalCFADeposit;
        int256 totalCFAOutFlowrate = signedTotalCFADeposit / int256(liquidationPeriod);
        // divisor cannot be zero with existing outflow
        return totalRewardLeft / totalCFAOutFlowrate > int256(liquidationPeriod - patricianPeriod);
    }

    /**************************************************************************
     * ACL Pure Functions
     *************************************************************************/

    function _generateFlowOperatorId(address sender, address flowOperator) private pure returns(bytes32 id) {
        return keccak256(abi.encode("flowOperator", sender, flowOperator));
    }

    //
    // Data packing:
    //
    // WORD A: | reserved  | permissions | reserved | flowRateAllowance |
    //         | 120       | 8           | 32       | 96                |
    //
    // NOTE:
    // - flowRateAllowance has 96 bits length
    // - permissions is an 8-bit octo bitmask
    // - ...0 0 0 (...delete update create)

    function _encodeFlowOperatorData
    (
        FlowOperatorData memory flowOperatorData
    )
        internal pure
        returns(bytes32[] memory data)
    {
        // last line of defence against negative flowRateAllowance
        assert(flowOperatorData.flowRateAllowance >= 0); // flowRateAllowance must not be less than 0
        data = new bytes32[](1);
        data[0] = bytes32(
            uint256(flowOperatorData.permissions) << 128 |
            uint256(int256(flowOperatorData.flowRateAllowance))
        );
    }

    function _decodeFlowOperatorData
    (
        uint256 wordA
    )
        internal pure
        returns(bool exist, FlowOperatorData memory flowOperatorData)
    {
        exist = wordA > 0;
        if (exist) {
            // NOTE: For safecast, doing extra bitmasking to not to have any trust assumption of token storage
            flowOperatorData.flowRateAllowance = int96(int256(wordA & uint256(int256(type(int96).max))));
            flowOperatorData.permissions = uint8(wordA >> 128) & type(uint8).max;
        }
    }

    function _getBooleanFlowOperatorPermissions
    (
        uint8 permissions,
        FlowChangeType flowChangeType
    )
        internal pure
        returns (bool flowchangeTypeAllowed)
    {
        if (flowChangeType == FlowChangeType.CREATE_FLOW) {
            flowchangeTypeAllowed = permissions & uint8(1) == 1;
        } else if (flowChangeType == FlowChangeType.UPDATE_FLOW) {
            flowchangeTypeAllowed = (permissions >> 1) & uint8(1) == 1;
        } else { /** flowChangeType === FlowChangeType.DELETE_FLOW */
            flowchangeTypeAllowed = (permissions >> 2) & uint8(1) == 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import { ISuperAgreement } from "../superfluid/ISuperAgreement.sol";
import { ISuperfluidToken } from "../superfluid/ISuperfluidToken.sol";

/**
 * @title Constant Flow Agreement interface
 * @author Superfluid
 */
abstract contract IConstantFlowAgreementV1 is ISuperAgreement {

    /**************************************************************************
     * Errors
     *************************************************************************/
    error CFA_ACL_NO_SENDER_CREATE();               // 0x4b993136
    error CFA_ACL_NO_SENDER_UPDATE();               // 0xedfa0d3b
    error CFA_ACL_OPERATOR_NO_CREATE_PERMISSIONS(); // 0xa3eab6ac
    error CFA_ACL_OPERATOR_NO_UPDATE_PERMISSIONS(); // 0xac434b5f
    error CFA_ACL_OPERATOR_NO_DELETE_PERMISSIONS(); // 0xe30f1bff
    error CFA_ACL_FLOW_RATE_ALLOWANCE_EXCEEDED();   // 0xa0645c1f
    error CFA_ACL_UNCLEAN_PERMISSIONS();            // 0x7939d66c
    error CFA_ACL_NO_SENDER_FLOW_OPERATOR();        // 0xb0ed394d
    error CFA_ACL_NO_NEGATIVE_ALLOWANCE();          // 0x86e0377d
    error CFA_FLOW_ALREADY_EXISTS();                // 0x801b6863
    error CFA_FLOW_DOES_NOT_EXIST();                // 0x5a32bf24
    error CFA_INSUFFICIENT_BALANCE();               // 0xea76c9b3
    error CFA_ZERO_ADDRESS_SENDER();                // 0x1ce9b067
    error CFA_ZERO_ADDRESS_RECEIVER();              // 0x78e02b2a
    error CFA_HOOK_OUT_OF_GAS();                    // 0x9f76430b
    error CFA_DEPOSIT_TOO_BIG();                    // 0x752c2b9c
    error CFA_FLOW_RATE_TOO_BIG();                  // 0x0c9c55c1
    error CFA_NON_CRITICAL_SENDER();                // 0xce11b5d1
    error CFA_INVALID_FLOW_RATE();                  // 0x91acad16
    error CFA_NO_SELF_FLOW();                       // 0xa47338ef

    /// @dev ISuperAgreement.agreementType implementation
    function agreementType() external override pure returns (bytes32) {
        return keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1");
    }

    /**
     * @notice Get the maximum flow rate allowed with the deposit
     * @dev The deposit is clipped and rounded down
     * @param deposit Deposit amount used for creating the flow
     * @return flowRate The maximum flow rate
     */
    function getMaximumFlowRateFromDeposit(
        ISuperfluidToken token,
        uint256 deposit)
        external view virtual
        returns (int96 flowRate);

    /**
     * @notice Get the deposit required for creating the flow
     * @dev Calculates the deposit based on the liquidationPeriod and flowRate
     * @param flowRate Flow rate to be tested
     * @return deposit The deposit amount based on flowRate and liquidationPeriod
     * @custom:note 
     * - if calculated deposit (flowRate * liquidationPeriod) is less
     *   than the minimum deposit, we use the minimum deposit otherwise
     *   we use the calculated deposit
     */
    function getDepositRequiredForFlowRate(
        ISuperfluidToken token,
        int96 flowRate)
        external view virtual
        returns (uint256 deposit);

    /**
     * @dev Returns whether it is the patrician period based on host.getNow()
     * @param account The account we are interested in
     * @return isCurrentlyPatricianPeriod Whether it is currently the patrician period dictated by governance
     * @return timestamp The value of host.getNow()
     */
    function isPatricianPeriodNow(
        ISuperfluidToken token,
        address account)
        external view virtual
        returns (bool isCurrentlyPatricianPeriod, uint256 timestamp);

    /**
     * @dev Returns whether it is the patrician period based on timestamp
     * @param account The account we are interested in
     * @param timestamp The timestamp we are interested in observing the result of isPatricianPeriod
     * @return bool Whether it is currently the patrician period dictated by governance
     */
    function isPatricianPeriod(
        ISuperfluidToken token,
        address account,
        uint256 timestamp
    )
        public view virtual
        returns (bool);

    /**
     * @dev msgSender from `ctx` updates permissions for the `flowOperator` with `flowRateAllowance`
     * @param token Super token address
     * @param flowOperator The permission grantee address
     * @param permissions A bitmask representation of the granted permissions
     * @param flowRateAllowance The flow rate allowance the `flowOperator` is granted (only goes down)
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     */
    function updateFlowOperatorPermissions(
        ISuperfluidToken token,
        address flowOperator,
        uint8 permissions,
        int96 flowRateAllowance,
        bytes calldata ctx
    ) 
        external virtual
        returns(bytes memory newCtx);

    /**
     * @notice msgSender from `ctx` increases flow rate allowance for the `flowOperator` by `addedFlowRateAllowance`
     * @dev if `addedFlowRateAllowance` is negative, we revert with CFA_ACL_NO_NEGATIVE_ALLOWANCE
     * @param token Super token address
     * @param flowOperator The permission grantee address
     * @param addedFlowRateAllowance The flow rate allowance delta
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     * @return newCtx The new context bytes
     */
    function increaseFlowRateAllowance(
        ISuperfluidToken token,
        address flowOperator,
        int96 addedFlowRateAllowance,
        bytes calldata ctx
    ) external virtual returns(bytes memory newCtx);

    /**
     * @dev msgSender from `ctx` decreases flow rate allowance for the `flowOperator` by `subtractedFlowRateAllowance`
     * @dev if `subtractedFlowRateAllowance` is negative, we revert with CFA_ACL_NO_NEGATIVE_ALLOWANCE
     * @param token Super token address
     * @param flowOperator The permission grantee address
     * @param subtractedFlowRateAllowance The flow rate allowance delta
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     * @return newCtx The new context bytes
     */
    function decreaseFlowRateAllowance(
        ISuperfluidToken token,
        address flowOperator,
        int96 subtractedFlowRateAllowance,
        bytes calldata ctx
    ) external virtual returns(bytes memory newCtx);

    /**
     * @dev msgSender from `ctx` grants `flowOperator` all permissions with flowRateAllowance as type(int96).max
     * @param token Super token address
     * @param flowOperator The permission grantee address
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     */
    function authorizeFlowOperatorWithFullControl(
        ISuperfluidToken token,
        address flowOperator,
        bytes calldata ctx
    )
        external virtual
        returns(bytes memory newCtx);

     /**
     * @notice msgSender from `ctx` revokes `flowOperator` create/update/delete permissions
     * @dev `permissions` and `flowRateAllowance` will both be set to 0
     * @param token Super token address
     * @param flowOperator The permission grantee address
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     */
    function revokeFlowOperatorWithFullControl(
        ISuperfluidToken token,
        address flowOperator,
        bytes calldata ctx
    )
        external virtual
        returns(bytes memory newCtx);

    /**
     * @notice Get the permissions of a flow operator between `sender` and `flowOperator` for `token`
     * @param token Super token address
     * @param sender The permission granter address
     * @param flowOperator The permission grantee address
     * @return flowOperatorId The keccak256 hash of encoded string "flowOperator", sender and flowOperator
     * @return permissions A bitmask representation of the granted permissions
     * @return flowRateAllowance The flow rate allowance the `flowOperator` is granted (only goes down)
     */
    function getFlowOperatorData(
       ISuperfluidToken token,
       address sender,
       address flowOperator
    )
        public view virtual
        returns (
            bytes32 flowOperatorId,
            uint8 permissions,
            int96 flowRateAllowance
        );

    /**
     * @notice Get flow operator using flowOperatorId
     * @param token Super token address
     * @param flowOperatorId The keccak256 hash of encoded string "flowOperator", sender and flowOperator
     * @return permissions A bitmask representation of the granted permissions
     * @return flowRateAllowance The flow rate allowance the `flowOperator` is granted (only goes down)
     */
    function getFlowOperatorDataByID(
       ISuperfluidToken token,
       bytes32 flowOperatorId
    )
        external view virtual
        returns (
            uint8 permissions,
            int96 flowRateAllowance
        );

    /**
     * @notice Create a flow betwen ctx.msgSender and receiver
     * @dev flowId (agreementId) is the keccak256 hash of encoded sender and receiver
     * @param token Super token address
     * @param receiver Flow receiver address
     * @param flowRate New flow rate in amount per second
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     *
     * @custom:callbacks 
     * - AgreementCreated
     *   - agreementId - can be used in getFlowByID
     *   - agreementData - abi.encode(address flowSender, address flowReceiver)
     *
     * @custom:note 
     * - A deposit is taken as safety margin for the solvency agents
     * - A extra gas fee may be taken to pay for solvency agent liquidations
     */
    function createFlow(
        ISuperfluidToken token,
        address receiver,
        int96 flowRate,
        bytes calldata ctx
    )
        external virtual
        returns(bytes memory newCtx);

    /**
    * @notice Create a flow between sender and receiver
    * @dev A flow created by an approved flow operator (see above for details on callbacks)
    * @param token Super token address
    * @param sender Flow sender address (has granted permissions)
    * @param receiver Flow receiver address
    * @param flowRate New flow rate in amount per second
    * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
    */
    function createFlowByOperator(
        ISuperfluidToken token,
        address sender,
        address receiver,
        int96 flowRate,
        bytes calldata ctx
    )
        external virtual
        returns(bytes memory newCtx);

    /**
     * @notice Update the flow rate between ctx.msgSender and receiver
     * @dev flowId (agreementId) is the keccak256 hash of encoded sender and receiver
     * @param token Super token address
     * @param receiver Flow receiver address
     * @param flowRate New flow rate in amount per second
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     *
     * @custom:callbacks 
     * - AgreementUpdated
     *   - agreementId - can be used in getFlowByID
     *   - agreementData - abi.encode(address flowSender, address flowReceiver)
     *
     * @custom:note 
     * - Only the flow sender may update the flow rate
     * - Even if the flow rate is zero, the flow is not deleted
     * from the system
     * - Deposit amount will be adjusted accordingly
     * - No new gas fee is charged
     */
    function updateFlow(
        ISuperfluidToken token,
        address receiver,
        int96 flowRate,
        bytes calldata ctx
    )
        external virtual
        returns(bytes memory newCtx);

    /**
    * @notice Update a flow between sender and receiver
    * @dev A flow updated by an approved flow operator (see above for details on callbacks)
    * @param token Super token address
    * @param sender Flow sender address (has granted permissions)
    * @param receiver Flow receiver address
    * @param flowRate New flow rate in amount per second
    * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
    */
    function updateFlowByOperator(
        ISuperfluidToken token,
        address sender,
        address receiver,
        int96 flowRate,
        bytes calldata ctx
    )
        external virtual
        returns(bytes memory newCtx);

    /**
     * @dev Get the flow data between `sender` and `receiver` of `token`
     * @param token Super token address
     * @param sender Flow receiver
     * @param receiver Flow sender
     * @return timestamp Timestamp of when the flow is updated
     * @return flowRate The flow rate
     * @return deposit The amount of deposit the flow
     * @return owedDeposit The amount of owed deposit of the flow
     */
    function getFlow(
        ISuperfluidToken token,
        address sender,
        address receiver
    )
        external view virtual
        returns (
            uint256 timestamp,
            int96 flowRate,
            uint256 deposit,
            uint256 owedDeposit
        );

    /**
     * @notice Get flow data using agreementId
     * @dev flowId (agreementId) is the keccak256 hash of encoded sender and receiver
     * @param token Super token address
     * @param agreementId The agreement ID
     * @return timestamp Timestamp of when the flow is updated
     * @return flowRate The flow rate
     * @return deposit The deposit amount of the flow
     * @return owedDeposit The owed deposit amount of the flow
     */
    function getFlowByID(
       ISuperfluidToken token,
       bytes32 agreementId
    )
        external view virtual
        returns (
            uint256 timestamp,
            int96 flowRate,
            uint256 deposit,
            uint256 owedDeposit
        );

    /**
     * @dev Get the aggregated flow info of the account
     * @param token Super token address
     * @param account Account for the query
     * @return timestamp Timestamp of when a flow was last updated for account
     * @return flowRate The net flow rate of token for account
     * @return deposit The sum of all deposits for account's flows
     * @return owedDeposit The sum of all owed deposits for account's flows
     */
    function getAccountFlowInfo(
        ISuperfluidToken token,
        address account
    )
        external view virtual
        returns (
            uint256 timestamp,
            int96 flowRate,
            uint256 deposit,
            uint256 owedDeposit);

    /**
     * @dev Get the net flow rate of the account
     * @param token Super token address
     * @param account Account for the query
     * @return flowRate Net flow rate
     */
    function getNetFlow(
        ISuperfluidToken token,
        address account
    )
        external view virtual
        returns (int96 flowRate);

    /**
     * @notice Delete the flow between sender and receiver
     * @dev flowId (agreementId) is the keccak256 hash of encoded sender and receiver
     * @param token Super token address
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     * @param receiver Flow receiver address
     *
     * @custom:callbacks 
     * - AgreementTerminated
     *   - agreementId - can be used in getFlowByID
     *   - agreementData - abi.encode(address flowSender, address flowReceiver)
     *
     * @custom:note 
     * - Both flow sender and receiver may delete the flow
     * - If Sender account is insolvent or in critical state, a solvency agent may
     *   also terminate the agreement
     * - Gas fee may be returned to the sender
     */
    function deleteFlow(
        ISuperfluidToken token,
        address sender,
        address receiver,
        bytes calldata ctx
    )
        external virtual
        returns(bytes memory newCtx);

    /**
     * @notice Delete the flow between sender and receiver
     * @dev A flow deleted by an approved flow operator (see above for details on callbacks)
     * @param token Super token address
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     * @param receiver Flow receiver address
     */
    function deleteFlowByOperator(
        ISuperfluidToken token,
        address sender,
        address receiver,
        bytes calldata ctx
    )
        external virtual
        returns(bytes memory newCtx);
     
    /**
     * @dev Flow operator updated event
     * @param token Super token address
     * @param sender Flow sender address
     * @param flowOperator Flow operator address
     * @param permissions Octo bitmask representation of permissions
     * @param flowRateAllowance The flow rate allowance the `flowOperator` is granted (only goes down)
     */
    event FlowOperatorUpdated(
        ISuperfluidToken indexed token,
        address indexed sender,
        address indexed flowOperator,
        uint8 permissions,
        int96 flowRateAllowance
    );

    /**
     * @dev Flow updated event
     * @param token Super token address
     * @param sender Flow sender address
     * @param receiver Flow recipient address
     * @param flowRate Flow rate in amount per second for this flow
     * @param totalSenderFlowRate Total flow rate in amount per second for the sender
     * @param totalReceiverFlowRate Total flow rate in amount per second for the receiver
     * @param userData The user provided data
     *
     */
    event FlowUpdated(
        ISuperfluidToken indexed token,
        address indexed sender,
        address indexed receiver,
        int96 flowRate,
        int256 totalSenderFlowRate,
        int256 totalReceiverFlowRate,
        bytes userData
    );

    /**
     * @dev Flow updated extension event
     * @param flowOperator Flow operator address - the Context.msgSender
     * @param deposit The deposit amount for the stream
     */
    event FlowUpdatedExtension(
        address indexed flowOperator,
        uint256 deposit
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

/**
 * @title Super app definitions library
 * @author Superfluid
 */
library SuperAppDefinitions {

    /**************************************************************************
    / App manifest config word
    /**************************************************************************/

    /*
     * App level is a way to allow the app to whitelist what other app it can
     * interact with (aka. composite app feature).
     *
     * For more details, refer to the technical paper of superfluid protocol.
     */
    uint256 constant internal APP_LEVEL_MASK = 0xFF;

    // The app is at the final level, hence it doesn't want to interact with any other app
    uint256 constant internal APP_LEVEL_FINAL = 1 << 0;

    // The app is at the second level, it may interact with other final level apps if whitelisted
    uint256 constant internal APP_LEVEL_SECOND = 1 << 1;

    function getAppCallbackLevel(uint256 configWord) internal pure returns (uint8) {
        return uint8(configWord & APP_LEVEL_MASK);
    }

    uint256 constant internal APP_JAIL_BIT = 1 << 15;
    function isAppJailed(uint256 configWord) internal pure returns (bool) {
        return (configWord & SuperAppDefinitions.APP_JAIL_BIT) > 0;
    }

    /**************************************************************************
    / Callback implementation bit masks
    /**************************************************************************/
    uint256 constant internal AGREEMENT_CALLBACK_NOOP_BITMASKS = 0xFF << 32;
    uint256 constant internal BEFORE_AGREEMENT_CREATED_NOOP = 1 << (32 + 0);
    uint256 constant internal AFTER_AGREEMENT_CREATED_NOOP = 1 << (32 + 1);
    uint256 constant internal BEFORE_AGREEMENT_UPDATED_NOOP = 1 << (32 + 2);
    uint256 constant internal AFTER_AGREEMENT_UPDATED_NOOP = 1 << (32 + 3);
    uint256 constant internal BEFORE_AGREEMENT_TERMINATED_NOOP = 1 << (32 + 4);
    uint256 constant internal AFTER_AGREEMENT_TERMINATED_NOOP = 1 << (32 + 5);

    /**************************************************************************
    / App Jail Reasons
    /**************************************************************************/

    uint256 constant internal APP_RULE_REGISTRATION_ONLY_IN_CONSTRUCTOR = 1;
    uint256 constant internal APP_RULE_NO_REGISTRATION_FOR_EOA = 2;
    uint256 constant internal APP_RULE_NO_REVERT_ON_TERMINATION_CALLBACK = 10;
    uint256 constant internal APP_RULE_NO_CRITICAL_SENDER_ACCOUNT = 11;
    uint256 constant internal APP_RULE_NO_CRITICAL_RECEIVER_ACCOUNT = 12;
    uint256 constant internal APP_RULE_CTX_IS_READONLY = 20;
    uint256 constant internal APP_RULE_CTX_IS_NOT_CLEAN = 21;
    uint256 constant internal APP_RULE_CTX_IS_MALFORMATED = 22;
    uint256 constant internal APP_RULE_COMPOSITE_APP_IS_NOT_WHITELISTED = 30;
    uint256 constant internal APP_RULE_COMPOSITE_APP_IS_JAILED = 31;
    uint256 constant internal APP_RULE_MAX_APP_LEVEL_REACHED = 40;

    // Validate configWord cleaness for future compatibility, or else may introduce undefined future behavior
    function isConfigWordClean(uint256 configWord) internal pure returns (bool) {
        return (configWord & ~(APP_LEVEL_MASK | APP_JAIL_BIT | AGREEMENT_CALLBACK_NOOP_BITMASKS)) == uint256(0);
    }
}

/**
 * @title Context definitions library
 * @author Superfluid
 */
library ContextDefinitions {

    /**************************************************************************
    / Call info
    /**************************************************************************/

    // app level
    uint256 constant internal CALL_INFO_APP_LEVEL_MASK = 0xFF;

    // call type
    uint256 constant internal CALL_INFO_CALL_TYPE_SHIFT = 32;
    uint256 constant internal CALL_INFO_CALL_TYPE_MASK = 0xF << CALL_INFO_CALL_TYPE_SHIFT;
    uint8 constant internal CALL_INFO_CALL_TYPE_AGREEMENT = 1;
    uint8 constant internal CALL_INFO_CALL_TYPE_APP_ACTION = 2;
    uint8 constant internal CALL_INFO_CALL_TYPE_APP_CALLBACK = 3;

    function decodeCallInfo(uint256 callInfo)
        internal pure
        returns (uint8 appCallbackLevel, uint8 callType)
    {
        appCallbackLevel = uint8(callInfo & CALL_INFO_APP_LEVEL_MASK);
        callType = uint8((callInfo & CALL_INFO_CALL_TYPE_MASK) >> CALL_INFO_CALL_TYPE_SHIFT);
    }

    function encodeCallInfo(uint8 appCallbackLevel, uint8 callType)
        internal pure
        returns (uint256 callInfo)
    {
        return uint256(appCallbackLevel) | (uint256(callType) << CALL_INFO_CALL_TYPE_SHIFT);
    }

}

/**
 * @title Flow Operator definitions library
  * @author Superfluid
 */
 library FlowOperatorDefinitions {
    uint8 constant internal AUTHORIZE_FLOW_OPERATOR_CREATE = uint8(1) << 0;
    uint8 constant internal AUTHORIZE_FLOW_OPERATOR_UPDATE = uint8(1) << 1;
    uint8 constant internal AUTHORIZE_FLOW_OPERATOR_DELETE = uint8(1) << 2;
    uint8 constant internal AUTHORIZE_FULL_CONTROL =
        AUTHORIZE_FLOW_OPERATOR_CREATE | AUTHORIZE_FLOW_OPERATOR_UPDATE | AUTHORIZE_FLOW_OPERATOR_DELETE;
    uint8 constant internal REVOKE_FLOW_OPERATOR_CREATE = ~(uint8(1) << 0);
    uint8 constant internal REVOKE_FLOW_OPERATOR_UPDATE = ~(uint8(1) << 1);
    uint8 constant internal REVOKE_FLOW_OPERATOR_DELETE = ~(uint8(1) << 2);

    function isPermissionsClean(uint8 permissions) internal pure returns (bool) {
        return (
            permissions & ~(AUTHORIZE_FLOW_OPERATOR_CREATE
                | AUTHORIZE_FLOW_OPERATOR_UPDATE
                | AUTHORIZE_FLOW_OPERATOR_DELETE)
            ) == uint8(0);
    }
 }

/**
 * @title Batch operation library
 * @author Superfluid
 */
library BatchOperation {
    /**
     * @dev ERC20.approve batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationApprove(
     *     abi.decode(data, (address spender, uint256 amount))
     * )
     */
    uint32 constant internal OPERATION_TYPE_ERC20_APPROVE = 1;
    /**
     * @dev ERC20.transferFrom batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationTransferFrom(
     *     abi.decode(data, (address sender, address recipient, uint256 amount)
     * )
     */
    uint32 constant internal OPERATION_TYPE_ERC20_TRANSFER_FROM = 2;
    /**
     * @dev ERC777.send batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationSend(
     *     abi.decode(data, (address recipient, uint256 amount, bytes userData)
     * )
     */
    uint32 constant internal OPERATION_TYPE_ERC777_SEND = 3;
    /**
     * @dev ERC20.increaseAllowance batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationIncreaseAllowance(
     *     abi.decode(data, (address account, address spender, uint256 addedValue))
     * )
     */
    uint32 constant internal OPERATION_TYPE_ERC20_INCREASE_ALLOWANCE = 4;
    /**
     * @dev ERC20.decreaseAllowance batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationDecreaseAllowance(
     *     abi.decode(data, (address account, address spender, uint256 subtractedValue))
     * )
     */
    uint32 constant internal OPERATION_TYPE_ERC20_DECREASE_ALLOWANCE = 5;
    /**
     * @dev SuperToken.upgrade batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationUpgrade(
     *     abi.decode(data, (uint256 amount)
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERTOKEN_UPGRADE = 1 + 100;
    /**
     * @dev SuperToken.downgrade batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationDowngrade(
     *     abi.decode(data, (uint256 amount)
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERTOKEN_DOWNGRADE = 2 + 100;
    /**
     * @dev Superfluid.callAgreement batch operation type
     *
     * Call spec:
     * callAgreement(
     *     ISuperAgreement(target)),
     *     abi.decode(data, (bytes callData, bytes userData)
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERFLUID_CALL_AGREEMENT = 1 + 200;
    /**
     * @dev Superfluid.callAppAction batch operation type
     *
     * Call spec:
     * callAppAction(
     *     ISuperApp(target)),
     *     data
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERFLUID_CALL_APP_ACTION = 2 + 200;
}

/**
 * @title Superfluid governance configs library
 * @author Superfluid
 */
library SuperfluidGovernanceConfigs {

    bytes32 constant internal SUPERFLUID_REWARD_ADDRESS_CONFIG_KEY =
        keccak256("org.superfluid-finance.superfluid.rewardAddress");
    bytes32 constant internal CFAV1_PPP_CONFIG_KEY =
        keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1.PPPConfiguration");
    bytes32 constant internal SUPERTOKEN_MINIMUM_DEPOSIT_KEY =
        keccak256("org.superfluid-finance.superfluid.superTokenMinimumDeposit");

    function getTrustedForwarderConfigKey(address forwarder) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            "org.superfluid-finance.superfluid.trustedForwarder",
            forwarder));
    }

    function getAppRegistrationConfigKey(address deployer, string memory registrationKey) internal pure
        returns (bytes32)
    {
        return keccak256(abi.encode(
            "org.superfluid-finance.superfluid.appWhiteListing.registrationKey",
            deployer,
            registrationKey));
    }

    function getAppFactoryConfigKey(address factory) internal pure returns (bytes32)
    {
        return keccak256(abi.encode(
            "org.superfluid-finance.superfluid.appWhiteListing.factory",
            factory));
    }

    function decodePPPConfig(uint256 pppConfig) internal pure
        returns (uint256 liquidationPeriod, uint256 patricianPeriod)
    {
        liquidationPeriod = (pppConfig >> 32) & type(uint32).max;
        patricianPeriod = pppConfig & type(uint32).max;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import { ISuperToken } from "./ISuperToken.sol";
import { IFlowNFTBase } from "./IFlowNFTBase.sol";

interface IConstantInflowNFT is IFlowNFTBase {
    /**************************************************************************
     * Custom Errors
     *************************************************************************/
    error CIF_NFT_ONLY_CONSTANT_OUTFLOW(); // 0xe81ef57a

    /**************************************************************************
     * Write Functions
     *************************************************************************/

    /// @notice The mint function emits the "mint" `Transfer` event.
    /// @dev We don't modify storage as this is handled in ConstantOutflowNFT.sol and this function's sole purpose
    /// is to inform clients that search for events.
    /// @param to the flow receiver (inflow NFT receiver)
    /// @param newTokenId the new token id
    function mint(address to, uint256 newTokenId) external;

    /// @notice This burn function emits the "burn" `Transfer` event.
    /// @dev We don't modify storage as this is handled in ConstantOutflowNFT.sol and this function's sole purpose
    /// is to inform clients that search for events.
    /// @param tokenId desired token id to burn
    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import { ISuperfluidToken } from "./ISuperfluidToken.sol";
import { IFlowNFTBase } from "./IFlowNFTBase.sol";

interface IConstantOutflowNFT is IFlowNFTBase {
    /**************************************************************************
     * Custom Errors
     *************************************************************************/

    error COF_NFT_INVALID_SUPER_TOKEN();            // 0x6de98774
    error COF_NFT_MINT_TO_AND_FLOW_RECEIVER_SAME(); // 0x0d1d1161
    error COF_NFT_MINT_TO_ZERO_ADDRESS();           // 0x43d05e51
    error COF_NFT_ONLY_CONSTANT_INFLOW();           // 0xa495a718
    error COF_NFT_ONLY_FLOW_AGREEMENTS();           // 0xd367b64f
    error COF_NFT_TOKEN_ALREADY_EXISTS();           // 0xe2480183


    /**************************************************************************
     * Write Functions
     *************************************************************************/

    /// @notice The onCreate function is called when a new flow is created.
    /// @param token the super token passed from the CFA (flowVars)
    /// @param flowSender the flow sender
    /// @param flowReceiver the flow receiver
    function onCreate(ISuperfluidToken token, address flowSender, address flowReceiver) external;

    /// @notice The onUpdate function is called when a flow is updated.
    /// @param token the super token passed from the CFA (flowVars)
    /// @param flowSender the flow sender
    /// @param flowReceiver the flow receiver
    function onUpdate(ISuperfluidToken token, address flowSender, address flowReceiver) external;

    /// @notice The onDelete function is called when a flow is deleted.
    /// @param token the super token passed from the CFA (flowVars)
    /// @param flowSender the flow sender
    /// @param flowReceiver the flow receiver
    function onDelete(ISuperfluidToken token, address flowSender, address flowReceiver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {
    IERC721Metadata
} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { ISuperToken } from "./ISuperToken.sol";

interface IFlowNFTBase is IERC721Metadata {
    // FlowNFTData struct storage packing:
    // b = bits
    // WORD 1: | superToken      | FREE
    //         | 160b            | 96b
    // WORD 2: | flowSender      | FREE
    //         | 160b            | 96b
    // WORD 3: | flowReceiver    | flowStartDate | FREE
    //         | 160b            | 32b           | 64b
    struct FlowNFTData {
        address superToken;
        address flowSender;
        address flowReceiver;
        uint32 flowStartDate;
    }

    /**************************************************************************
     * Custom Errors
     *************************************************************************/

    error CFA_NFT_APPROVE_CALLER_NOT_OWNER_OR_APPROVED_FOR_ALL();   // 0xa3352582
    error CFA_NFT_APPROVE_TO_CALLER();                              // 0xd3c77329
    error CFA_NFT_APPROVE_TO_CURRENT_OWNER();                       // 0xe4790b25
    error CFA_NFT_INVALID_TOKEN_ID();                               // 0xeab95e3b
    error CFA_NFT_ONLY_SUPER_TOKEN_FACTORY();                       // 0xebb7505b
    error CFA_NFT_TRANSFER_CALLER_NOT_OWNER_OR_APPROVED_FOR_ALL();  // 0x2551d606
    error CFA_NFT_TRANSFER_FROM_INCORRECT_OWNER();                  // 0x5a26c744
    error CFA_NFT_TRANSFER_IS_NOT_ALLOWED();                        // 0xaa747eca
    error CFA_NFT_TRANSFER_TO_ZERO_ADDRESS();                       // 0xde06d21e

    /**************************************************************************
     * Events
     *************************************************************************/

    /// @notice Informs third-party platforms that NFT metadata should be updated
    /// @dev This event comes from https://eips.ethereum.org/EIPS/eip-4906
    /// @param tokenId the id of the token that should have its metadata updated
    event MetadataUpdate(uint256 tokenId);

    /**************************************************************************
     * View
     *************************************************************************/

    /// @notice An external function for querying flow data by `tokenId``
    /// @param tokenId the token id
    /// @return flowData the flow data associated with `tokenId`
    function flowDataByTokenId(
        uint256 tokenId
    ) external view returns (FlowNFTData memory flowData);

    /// @notice An external function for computing the deterministic tokenId
    /// @dev tokenId = uint256(keccak256(abi.encode(block.chainId, superToken, flowSender, flowReceiver)))
    /// @param superToken the super token
    /// @param flowSender the flow sender
    /// @param flowReceiver the flow receiver
    /// @return tokenId the tokenId
    function getTokenId(
        address superToken,
        address flowSender,
        address flowReceiver
    ) external view returns (uint256);

    /**************************************************************************
     * Write
     *************************************************************************/

    function initialize(
        string memory nftName,
        string memory nftSymbol
    ) external; // initializer;

    function triggerMetadataUpdate(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IPoolAdminNFT {}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IPoolMemberNFT {}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import { ISuperfluidToken } from "./ISuperfluidToken.sol";

/**
 * @title Super agreement interface
 * @author Superfluid
 */
interface ISuperAgreement {

    /**
     * @dev Get the type of the agreement class
     */
    function agreementType() external view returns (bytes32);

    /**
     * @dev Calculate the real-time balance for the account of this agreement class
     * @param account Account the state belongs to
     * @param time Time used for the calculation
     * @return dynamicBalance Dynamic balance portion of real-time balance of this agreement
     * @return deposit Account deposit amount of this agreement
     * @return owedDeposit Account owed deposit amount of this agreement
     */
    function realtimeBalanceOf(
        ISuperfluidToken token,
        address account,
        uint256 time
    )
        external
        view
        returns (
            int256 dynamicBalance,
            uint256 deposit,
            uint256 owedDeposit
        );

}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import { ISuperToken } from "./ISuperToken.sol";

/**
 * @title SuperApp interface
 * @author Superfluid
 * @dev Be aware of the app being jailed, when the word permitted is used.
 */
interface ISuperApp {

    /**
     * @dev Callback before a new agreement is created.
     * @param superToken The super token used for the agreement.
     * @param agreementClass The agreement class address.
     * @param agreementId The agreementId
     * @param agreementData The agreement data (non-compressed)
     * @param ctx The context data.
     * @return cbdata A free format in memory data the app can use to pass
     *          arbitary information to the after-hook callback.
     *
     * @custom:note 
     * - It will be invoked with `staticcall`, no state changes are permitted.
     * - Only revert with a "reason" is permitted.
     */
    function beforeAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    )
        external
        view
        returns (bytes memory cbdata);

    /**
     * @dev Callback after a new agreement is created.
     * @param superToken The super token used for the agreement.
     * @param agreementClass The agreement class address.
     * @param agreementId The agreementId
     * @param agreementData The agreement data (non-compressed)
     * @param cbdata The data returned from the before-hook callback.
     * @param ctx The context data.
     * @return newCtx The current context of the transaction.
     *
     * @custom:note 
     * - State changes is permitted.
     * - Only revert with a "reason" is permitted.
     */
    function afterAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external
        returns (bytes memory newCtx);

    /**
     * @dev Callback before a new agreement is updated.
     * @param superToken The super token used for the agreement.
     * @param agreementClass The agreement class address.
     * @param agreementId The agreementId
     * @param agreementData The agreement data (non-compressed)
     * @param ctx The context data.
     * @return cbdata A free format in memory data the app can use to pass
     *          arbitary information to the after-hook callback.
     *
     * @custom:note 
     * - It will be invoked with `staticcall`, no state changes are permitted.
     * - Only revert with a "reason" is permitted.
     */
    function beforeAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    )
        external
        view
        returns (bytes memory cbdata);


    /**
    * @dev Callback after a new agreement is updated.
    * @param superToken The super token used for the agreement.
    * @param agreementClass The agreement class address.
    * @param agreementId The agreementId
    * @param agreementData The agreement data (non-compressed)
    * @param cbdata The data returned from the before-hook callback.
    * @param ctx The context data.
    * @return newCtx The current context of the transaction.
    *
    * @custom:note 
    * - State changes is permitted.
    * - Only revert with a "reason" is permitted.
    */
    function afterAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external
        returns (bytes memory newCtx);

    /**
    * @dev Callback before a new agreement is terminated.
    * @param superToken The super token used for the agreement.
    * @param agreementClass The agreement class address.
    * @param agreementId The agreementId
    * @param agreementData The agreement data (non-compressed)
    * @param ctx The context data.
    * @return cbdata A free format in memory data the app can use to pass arbitary information to
    *         the after-hook callback.
    *
    * @custom:note 
    * - It will be invoked with `staticcall`, no state changes are permitted.
    * - Revert is not permitted.
    */
    function beforeAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    )
        external
        view
        returns (bytes memory cbdata);

    /**
    * @dev Callback after a new agreement is terminated.
    * @param superToken The super token used for the agreement.
    * @param agreementClass The agreement class address.
    * @param agreementId The agreementId
    * @param agreementData The agreement data (non-compressed)
    * @param cbdata The data returned from the before-hook callback.
    * @param ctx The context data.
    * @return newCtx The current context of the transaction.
    *
    * @custom:note 
    * - State changes is permitted.
    * - Revert is not permitted.
    */
    function afterAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external
        returns (bytes memory newCtx);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import { ISuperfluidGovernance } from "./ISuperfluidGovernance.sol";
import { ISuperfluidToken } from "./ISuperfluidToken.sol";
import { ISuperToken } from "./ISuperToken.sol";
import { ISuperTokenFactory } from "./ISuperTokenFactory.sol";
import { ISuperAgreement } from "./ISuperAgreement.sol";
import { ISuperApp } from "./ISuperApp.sol";
import {
    BatchOperation,
    ContextDefinitions,
    FlowOperatorDefinitions,
    SuperAppDefinitions,
    SuperfluidGovernanceConfigs
} from "./Definitions.sol";
import { TokenInfo } from "../tokens/TokenInfo.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC777 } from "@openzeppelin/contracts/token/ERC777/IERC777.sol";

/**
 * @title Host interface
 * @author Superfluid
 * @notice This is the central contract of the system where super agreement, super app
 * and super token features are connected.
 *
 * The Superfluid host contract is also the entry point for the protocol users,
 * where batch call and meta transaction are provided for UX improvements.
 *
 */
interface ISuperfluid {

    /**************************************************************************
     * Errors
     *************************************************************************/
    // Superfluid Custom Errors
    error HOST_AGREEMENT_CALLBACK_IS_NOT_ACTION();              // 0xef4295f6
    error HOST_CANNOT_DOWNGRADE_TO_NON_UPGRADEABLE();           // 0x474e7641
    error HOST_CALL_AGREEMENT_WITH_CTX_FROM_WRONG_ADDRESS();    // 0x0cd0ebc2
    error HOST_CALL_APP_ACTION_WITH_CTX_FROM_WRONG_ADDRESS();   // 0x473f7bd4
    error HOST_INVALID_CONFIG_WORD();                           // 0xf4c802a4
    error HOST_MAX_256_AGREEMENTS();                            // 0x7c281a78
    error HOST_NON_UPGRADEABLE();                               // 0x14f72c9f
    error HOST_NON_ZERO_LENGTH_PLACEHOLDER_CTX();               // 0x67e9985b
    error HOST_ONLY_GOVERNANCE();                               // 0xc5d22a4e
    error HOST_UNKNOWN_BATCH_CALL_OPERATION_TYPE();             // 0xb4770115
    error HOST_AGREEMENT_ALREADY_REGISTERED();                  // 0xdc9ddba8
    error HOST_AGREEMENT_IS_NOT_REGISTERED();                   // 0x1c9e9bea
    error HOST_MUST_BE_CONTRACT();                              // 0xd4f6b30c
    error HOST_ONLY_LISTED_AGREEMENT();                         // 0x619c5359
    error HOST_NEED_MORE_GAS();                                 // 0xd4f5d496

    // App Related Custom Errors
    // uses SuperAppDefinitions' App Jail Reasons as _code
    error APP_RULE(uint256 _code);                              // 0xa85ba64f

    error HOST_INVALID_OR_EXPIRED_SUPER_APP_REGISTRATION_KEY(); // 0x19ab84d1
    error HOST_NOT_A_SUPER_APP();                               // 0x163cbe43
    error HOST_NO_APP_REGISTRATION_PERMISSIONS();               // 0x5b93ebf0
    error HOST_RECEIVER_IS_NOT_SUPER_APP();                     // 0x96aa315e
    error HOST_SENDER_IS_NOT_SUPER_APP();                       // 0xbacfdc40
    error HOST_SOURCE_APP_NEEDS_HIGHER_APP_LEVEL();             // 0x44725270
    error HOST_SUPER_APP_IS_JAILED();                           // 0x02384b64
    error HOST_SUPER_APP_ALREADY_REGISTERED();                  // 0x01b0a935
    error HOST_UNAUTHORIZED_SUPER_APP_FACTORY();                // 0x289533c5

    /**************************************************************************
     * Time
     *
     * > The Oracle: You have the sight now, Neo. You are looking at the world without time.
     * > Neo: Then why can't I see what happens to her?
     * > The Oracle: We can never see past the choices we don't understand.
     * >       - The Oracle and Neo conversing about the future of Trinity and the effects of Neo's choices
     *************************************************************************/

    function getNow() external view returns (uint256);

    /**************************************************************************
     * Governance
     *************************************************************************/

    /**
     * @dev Get the current governance address of the Superfluid host
     */
    function getGovernance() external view returns(ISuperfluidGovernance governance);

    /**
     * @dev Replace the current governance with a new one
     */
    function replaceGovernance(ISuperfluidGovernance newGov) external;
    /**
     * @dev Governance replaced event
     * @param oldGov Address of the old governance contract
     * @param newGov Address of the new governance contract
     */
    event GovernanceReplaced(ISuperfluidGovernance oldGov, ISuperfluidGovernance newGov);

    /**************************************************************************
     * Agreement Whitelisting
     *************************************************************************/

    /**
     * @dev Register a new agreement class to the system
     * @param agreementClassLogic Initial agreement class code
     *
     * @custom:modifiers 
     * - onlyGovernance
     */
    function registerAgreementClass(ISuperAgreement agreementClassLogic) external;
    /**
     * @notice Agreement class registered event
     * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
     * @param agreementType The agreement type registered
     * @param code Address of the new agreement
     */
    event AgreementClassRegistered(bytes32 agreementType, address code);

    /**
    * @dev Update code of an agreement class
    * @param agreementClassLogic New code for the agreement class
    *
    * @custom:modifiers 
    *  - onlyGovernance
    */
    function updateAgreementClass(ISuperAgreement agreementClassLogic) external;
    /**
     * @notice Agreement class updated event
     * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
     * @param agreementType The agreement type updated
     * @param code Address of the new agreement
     */
    event AgreementClassUpdated(bytes32 agreementType, address code);

    /**
    * @notice Check if the agreement type is whitelisted
    * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
    */
    function isAgreementTypeListed(bytes32 agreementType) external view returns(bool yes);

    /**
    * @dev Check if the agreement class is whitelisted
    */
    function isAgreementClassListed(ISuperAgreement agreementClass) external view returns(bool yes);

    /**
    * @notice Get agreement class
    * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
    */
    function getAgreementClass(bytes32 agreementType) external view returns(ISuperAgreement agreementClass);

    /**
    * @dev Map list of the agreement classes using a bitmap
    * @param bitmap Agreement class bitmap
    */
    function mapAgreementClasses(uint256 bitmap)
        external view
        returns (ISuperAgreement[] memory agreementClasses);

    /**
    * @notice Create a new bitmask by adding a agreement class to it
    * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
    * @param bitmap Agreement class bitmap
    */
    function addToAgreementClassesBitmap(uint256 bitmap, bytes32 agreementType)
        external view
        returns (uint256 newBitmap);

    /**
    * @notice Create a new bitmask by removing a agreement class from it
    * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
    * @param bitmap Agreement class bitmap
    */
    function removeFromAgreementClassesBitmap(uint256 bitmap, bytes32 agreementType)
        external view
        returns (uint256 newBitmap);

    /**************************************************************************
    * Super Token Factory
    **************************************************************************/

    /**
     * @dev Get the super token factory
     * @return factory The factory
     */
    function getSuperTokenFactory() external view returns (ISuperTokenFactory factory);

    /**
     * @dev Get the super token factory logic (applicable to upgradable deployment)
     * @return logic The factory logic
     */
    function getSuperTokenFactoryLogic() external view returns (address logic);

    /**
     * @dev Update super token factory
     * @param newFactory New factory logic
     */
    function updateSuperTokenFactory(ISuperTokenFactory newFactory) external;
    /**
     * @dev SuperToken factory updated event
     * @param newFactory Address of the new factory
     */
    event SuperTokenFactoryUpdated(ISuperTokenFactory newFactory);

    /**
     * @notice Update the super token logic to the latest
     * @dev Refer to ISuperTokenFactory.Upgradability for expected behaviours
     */
    function updateSuperTokenLogic(ISuperToken token) external;
    /**
     * @dev SuperToken logic updated event
     * @param code Address of the new SuperToken logic
     */
    event SuperTokenLogicUpdated(ISuperToken indexed token, address code);

    /**************************************************************************
     * App Registry
     *************************************************************************/

    /**
     * @dev Message sender (must be a contract) declares itself as a super app.
     * @custom:deprecated you should use `registerAppWithKey` or `registerAppByFactory` instead,
     * because app registration is currently governance permissioned on mainnets.
     * @param configWord The super app manifest configuration, flags are defined in
     * `SuperAppDefinitions`
     */
    function registerApp(uint256 configWord) external;
    /**
     * @dev App registered event
     * @param app Address of jailed app
     */
    event AppRegistered(ISuperApp indexed app);

    /**
     * @dev Message sender declares itself as a super app.
     * @param configWord The super app manifest configuration, flags are defined in `SuperAppDefinitions`
     * @param registrationKey The registration key issued by the governance, needed to register on a mainnet.
     * @notice See https://github.com/superfluid-finance/protocol-monorepo/wiki/Super-App-White-listing-Guide
     * On testnets or in dev environment, a placeholder (e.g. empty string) can be used.
     * While the message sender must be the super app itself, the transaction sender (tx.origin)
     * must be the deployer account the registration key was issued for.
     */
    function registerAppWithKey(uint256 configWord, string calldata registrationKey) external;

    /**
     * @dev Message sender (must be a contract) declares app as a super app
     * @param configWord The super app manifest configuration, flags are defined in `SuperAppDefinitions`
     * @notice On mainnet deployments, only factory contracts pre-authorized by governance can use this.
     * See https://github.com/superfluid-finance/protocol-monorepo/wiki/Super-App-White-listing-Guide
     */
    function registerAppByFactory(ISuperApp app, uint256 configWord) external;

    /**
     * @dev Query if the app is registered
     * @param app Super app address
     */
    function isApp(ISuperApp app) external view returns(bool);

    /**
     * @dev Query app callbacklevel
     * @param app Super app address
     */
    function getAppCallbackLevel(ISuperApp app) external view returns(uint8 appCallbackLevel);

    /**
     * @dev Get the manifest of the super app
     * @param app Super app address
     */
    function getAppManifest(
        ISuperApp app
    )
        external view
        returns (
            bool isSuperApp,
            bool isJailed,
            uint256 noopMask
        );

    /**
     * @dev Query if the app has been jailed
     * @param app Super app address
     */
    function isAppJailed(ISuperApp app) external view returns (bool isJail);

    /**
     * @dev Whitelist the target app for app composition for the source app (msg.sender)
     * @param targetApp The target super app address
     */
    function allowCompositeApp(ISuperApp targetApp) external;

    /**
     * @dev Query if source app is allowed to call the target app as downstream app
     * @param app Super app address
     * @param targetApp The target super app address
     */
    function isCompositeAppAllowed(
        ISuperApp app,
        ISuperApp targetApp
    )
        external view
        returns (bool isAppAllowed);

    /**************************************************************************
     * Agreement Framework
     *
     * Agreements use these function to trigger super app callbacks, updates
     * app credit and charge gas fees.
     *
     * These functions can only be called by registered agreements.
     *************************************************************************/

    /**
     * @dev (For agreements) StaticCall the app before callback
     * @param  app               The super app.
     * @param  callData          The call data sending to the super app.
     * @param  isTermination     Is it a termination callback?
     * @param  ctx               Current ctx, it will be validated.
     * @return cbdata            Data returned from the callback.
     */
    function callAppBeforeCallback(
        ISuperApp app,
        bytes calldata callData,
        bool isTermination,
        bytes calldata ctx
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns(bytes memory cbdata);

    /**
     * @dev (For agreements) Call the app after callback
     * @param  app               The super app.
     * @param  callData          The call data sending to the super app.
     * @param  isTermination     Is it a termination callback?
     * @param  ctx               Current ctx, it will be validated.
     * @return newCtx            The current context of the transaction.
     */
    function callAppAfterCallback(
        ISuperApp app,
        bytes calldata callData,
        bool isTermination,
        bytes calldata ctx
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns(bytes memory newCtx);

    /**
     * @dev (For agreements) Create a new callback stack
     * @param  ctx                     The current ctx, it will be validated.
     * @param  app                     The super app.
     * @param  appCreditGranted        App credit granted so far.
     * @param  appCreditUsed           App credit used so far.
     * @return newCtx                  The current context of the transaction.
     */
    function appCallbackPush(
        bytes calldata ctx,
        ISuperApp app,
        uint256 appCreditGranted,
        int256 appCreditUsed,
        ISuperfluidToken appCreditToken
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns (bytes memory newCtx);

    /**
     * @dev (For agreements) Pop from the current app callback stack
     * @param  ctx                     The ctx that was pushed before the callback stack.
     * @param  appCreditUsedDelta      App credit used by the app.
     * @return newCtx                  The current context of the transaction.
     *
     * @custom:security
     * - Here we cannot do assertValidCtx(ctx), since we do not really save the stack in memory.
     * - Hence there is still implicit trust that the agreement handles the callback push/pop pair correctly.
     */
    function appCallbackPop(
        bytes calldata ctx,
        int256 appCreditUsedDelta
    )
        external
        // onlyAgreement
        returns (bytes memory newCtx);

    /**
     * @dev (For agreements) Use app credit.
     * @param  ctx                      The current ctx, it will be validated.
     * @param  appCreditUsedMore        See app credit for more details.
     * @return newCtx                   The current context of the transaction.
     */
    function ctxUseCredit(
        bytes calldata ctx,
        int256 appCreditUsedMore
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns (bytes memory newCtx);

    /**
     * @dev (For agreements) Jail the app.
     * @param  app                     The super app.
     * @param  reason                  Jail reason code.
     * @return newCtx                  The current context of the transaction.
     */
    function jailApp(
        bytes calldata ctx,
        ISuperApp app,
        uint256 reason
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns (bytes memory newCtx);

    /**
     * @dev Jail event for the app
     * @param app Address of jailed app
     * @param reason Reason the app is jailed (see Definitions.sol for the full list)
     */
    event Jail(ISuperApp indexed app, uint256 reason);

    /**************************************************************************
     * Contextless Call Proxies
     *
     * NOTE: For EOAs or non-app contracts, they are the entry points for interacting
     * with agreements or apps.
     *
     * NOTE: The contextual call data should be generated using
     * abi.encodeWithSelector. The context parameter should be set to "0x",
     * an empty bytes array as a placeholder to be replaced by the host
     * contract.
     *************************************************************************/

     /**
      * @dev Call agreement function
      * @param agreementClass The agreement address you are calling
      * @param callData The contextual call data with placeholder ctx
      * @param userData Extra user data being sent to the super app callbacks
      */
     function callAgreement(
         ISuperAgreement agreementClass,
         bytes calldata callData,
         bytes calldata userData
     )
        external
        //cleanCtx
        //isAgreement(agreementClass)
        returns(bytes memory returnedData);

    /**
     * @notice Call app action
     * @dev Main use case is calling app action in a batch call via the host
     * @param callData The contextual call data
     *
     * @custom:note See "Contextless Call Proxies" above for more about contextual call data.
     */
    function callAppAction(
        ISuperApp app,
        bytes calldata callData
    )
        external
        //cleanCtx
        //isAppActive(app)
        //isValidAppAction(callData)
        returns(bytes memory returnedData);

    /**************************************************************************
     * Contextual Call Proxies and Context Utilities
     *
     * For apps, they must use context they receive to interact with
     * agreements or apps.
     *
     * The context changes must be saved and returned by the apps in their
     * callbacks always, any modification to the context will be detected and
     * the violating app will be jailed.
     *************************************************************************/

    /**
     * @dev Context Struct
     *
     * @custom:note on backward compatibility:
     * - Non-dynamic fields are padded to 32bytes and packed
     * - Dynamic fields are referenced through a 32bytes offset to their "parents" field (or root)
     * - The order of the fields hence should not be rearranged in order to be backward compatible:
     *    - non-dynamic fields will be parsed at the same memory location,
     *    - and dynamic fields will simply have a greater offset than it was.
     * - We cannot change the structure of the Context struct because of ABI compatibility requirements
     */
    struct Context {
        //
        // Call context
        //
        // app callback level
        uint8 appCallbackLevel;
        // type of call
        uint8 callType;
        // the system timestamp
        uint256 timestamp;
        // The intended message sender for the call
        address msgSender;

        //
        // Callback context
        //
        // For callbacks it is used to know which agreement function selector is called
        bytes4 agreementSelector;
        // User provided data for app callbacks
        bytes userData;

        //
        // App context
        //
        // app credit granted
        uint256 appCreditGranted;
        // app credit wanted by the app callback
        uint256 appCreditWantedDeprecated;
        // app credit used, allowing negative values over a callback session
        // the appCreditUsed value over a callback sessions is calculated with:
        // existing flow data owed deposit + sum of the callback agreements
        // deposit deltas 
        // the final value used to modify the state is determined by the
        // _adjustNewAppCreditUsed function (in AgreementLibrary.sol) which takes 
        // the appCreditUsed value reached in the callback session and the app
        // credit granted
        int256 appCreditUsed;
        // app address
        address appAddress;
        // app credit in super token
        ISuperfluidToken appCreditToken;
    }

    function callAgreementWithContext(
        ISuperAgreement agreementClass,
        bytes calldata callData,
        bytes calldata userData,
        bytes calldata ctx
    )
        external
        // requireValidCtx(ctx)
        // onlyAgreement(agreementClass)
        returns (bytes memory newCtx, bytes memory returnedData);

    function callAppActionWithContext(
        ISuperApp app,
        bytes calldata callData,
        bytes calldata ctx
    )
        external
        // requireValidCtx(ctx)
        // isAppActive(app)
        returns (bytes memory newCtx);

    function decodeCtx(bytes memory ctx)
        external pure
        returns (Context memory context);

    function isCtxValid(bytes calldata ctx) external view returns (bool);

    /**************************************************************************
    * Batch call
    **************************************************************************/
    /**
     * @dev Batch operation data
     */
    struct Operation {
        // Operation type. Defined in BatchOperation (Definitions.sol)
        uint32 operationType;
        // Operation target
        address target;
        // Data specific to the operation
        bytes data;
    }

    /**
     * @dev Batch call function
     * @param operations Array of batch operations
     */
    function batchCall(Operation[] calldata operations) external;

    /**
     * @dev Batch call function for trusted forwarders (EIP-2771)
     * @param operations Array of batch operations
     */
    function forwardBatchCall(Operation[] calldata operations) external;

    /**************************************************************************
     * Function modifiers for access control and parameter validations
     *
     * While they cannot be explicitly stated in function definitions, they are
     * listed in function definition comments instead for clarity.
     *
     * TODO: turning these off because solidity-coverage doesn't like it
     *************************************************************************/

     /* /// @dev The current superfluid context is clean.
     modifier cleanCtx() virtual;

     /// @dev Require the ctx being valid.
     modifier requireValidCtx(bytes memory ctx) virtual;

     /// @dev Assert the ctx being valid.
     modifier assertValidCtx(bytes memory ctx) virtual;

     /// @dev The agreement is a listed agreement.
     modifier isAgreement(ISuperAgreement agreementClass) virtual;

     // onlyGovernance

     /// @dev The msg.sender must be a listed agreement.
     modifier onlyAgreement() virtual;

     /// @dev The app is registered and not jailed.
     modifier isAppActive(ISuperApp app) virtual; */
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import { ISuperAgreement } from "./ISuperAgreement.sol";
import { ISuperToken } from "./ISuperToken.sol";
import { ISuperfluidToken  } from "./ISuperfluidToken.sol";
import { ISuperfluid } from "./ISuperfluid.sol";


/**
 * @title Superfluid governance interface
 * @author Superfluid
 */
interface ISuperfluidGovernance {
    
    /**************************************************************************
     * Errors
     *************************************************************************/
    error SF_GOV_ARRAYS_NOT_SAME_LENGTH();                  // 0x27743aa6
    error SF_GOV_INVALID_LIQUIDATION_OR_PATRICIAN_PERIOD(); // 0xe171980a
    error SF_GOV_MUST_BE_CONTRACT();                        // 0x80dddd73

    /**
     * @dev Replace the current governance with a new governance
     */
    function replaceGovernance(
        ISuperfluid host,
        address newGov) external;

    /**
     * @dev Register a new agreement class
     */
    function registerAgreementClass(
        ISuperfluid host,
        address agreementClass) external;

    /**
     * @dev Update logics of the contracts
     *
     * @custom:note 
     * - Because they might have inter-dependencies, it is good to have one single function to update them all
     */
    function updateContracts(
        ISuperfluid host,
        address hostNewLogic,
        address[] calldata agreementClassNewLogics,
        address superTokenFactoryNewLogic
    ) external;

    /**
     * @dev Update supertoken logic contract to the latest that is managed by the super token factory
     */
    function batchUpdateSuperTokenLogic(
        ISuperfluid host,
        ISuperToken[] calldata tokens) external;
    
    /**
     * @dev Set configuration as address value
     */
    function setConfig(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key,
        address value
    ) external;
    
    /**
     * @dev Set configuration as uint256 value
     */
    function setConfig(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key,
        uint256 value
    ) external;

    /**
     * @dev Clear configuration
     */
    function clearConfig(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key
    ) external;

    /**
     * @dev Get configuration as address value
     */
    function getConfigAsAddress(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key) external view returns (address value);

    /**
     * @dev Get configuration as uint256 value
     */
    function getConfigAsUint256(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key) external view returns (uint256 value);

}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import { ISuperAgreement } from "./ISuperAgreement.sol";

/**
 * @title Superfluid token interface
 * @author Superfluid
 */
interface ISuperfluidToken {

    /**************************************************************************
     * Errors
     *************************************************************************/
    error SF_TOKEN_AGREEMENT_ALREADY_EXISTS();  // 0xf05521f6
    error SF_TOKEN_AGREEMENT_DOES_NOT_EXIST();  // 0xdae18809
    error SF_TOKEN_BURN_INSUFFICIENT_BALANCE(); // 0x10ecdf44
    error SF_TOKEN_MOVE_INSUFFICIENT_BALANCE(); // 0x2f4cb941
    error SF_TOKEN_ONLY_LISTED_AGREEMENT();     // 0xc9ff6644
    error SF_TOKEN_ONLY_HOST();                 // 0xc51efddd

    /**************************************************************************
     * Basic information
     *************************************************************************/

    /**
     * @dev Get superfluid host contract address
     */
    function getHost() external view returns(address host);

    /**
     * @dev Encoded liquidation type data mainly used for handling stack to deep errors
     *
     * @custom:note 
     * - version: 1
     * - liquidationType key:
     *    - 0 = reward account receives reward (PIC period)
     *    - 1 = liquidator account receives reward (Pleb period)
     *    - 2 = liquidator account receives reward (Pirate period/bailout)
     */
    struct LiquidationTypeData {
        uint256 version;
        uint8 liquidationType;
    }

    /**************************************************************************
     * Real-time balance functions
     *************************************************************************/

    /**
    * @dev Calculate the real balance of a user, taking in consideration all agreements of the account
    * @param account for the query
    * @param timestamp Time of balance
    * @return availableBalance Real-time balance
    * @return deposit Account deposit
    * @return owedDeposit Account owed Deposit
    */
    function realtimeBalanceOf(
       address account,
       uint256 timestamp
    )
        external view
        returns (
            int256 availableBalance,
            uint256 deposit,
            uint256 owedDeposit);

    /**
     * @notice Calculate the realtime balance given the current host.getNow() value
     * @dev realtimeBalanceOf with timestamp equals to block timestamp
     * @param account for the query
     * @return availableBalance Real-time balance
     * @return deposit Account deposit
     * @return owedDeposit Account owed Deposit
     */
    function realtimeBalanceOfNow(
       address account
    )
        external view
        returns (
            int256 availableBalance,
            uint256 deposit,
            uint256 owedDeposit,
            uint256 timestamp);

    /**
    * @notice Check if account is critical
    * @dev A critical account is when availableBalance < 0
    * @param account The account to check
    * @param timestamp The time we'd like to check if the account is critical (should use future)
    * @return isCritical Whether the account is critical
    */
    function isAccountCritical(
        address account,
        uint256 timestamp
    )
        external view
        returns(bool isCritical);

    /**
    * @notice Check if account is critical now (current host.getNow())
    * @dev A critical account is when availableBalance < 0
    * @param account The account to check
    * @return isCritical Whether the account is critical
    */
    function isAccountCriticalNow(
        address account
    )
        external view
        returns(bool isCritical);

    /**
     * @notice Check if account is solvent
     * @dev An account is insolvent when the sum of deposits for a token can't cover the negative availableBalance
     * @param account The account to check
     * @param timestamp The time we'd like to check if the account is solvent (should use future)
     * @return isSolvent True if the account is solvent, false otherwise
     */
    function isAccountSolvent(
        address account,
        uint256 timestamp
    )
        external view
        returns(bool isSolvent);

    /**
     * @notice Check if account is solvent now
     * @dev An account is insolvent when the sum of deposits for a token can't cover the negative availableBalance
     * @param account The account to check
     * @return isSolvent True if the account is solvent, false otherwise
     */
    function isAccountSolventNow(
        address account
    )
        external view
        returns(bool isSolvent);

    /**
    * @notice Get a list of agreements that is active for the account
    * @dev An active agreement is one that has state for the account
    * @param account Account to query
    * @return activeAgreements List of accounts that have non-zero states for the account
    */
    function getAccountActiveAgreements(address account)
       external view
       returns(ISuperAgreement[] memory activeAgreements);


   /**************************************************************************
    * Super Agreement hosting functions
    *************************************************************************/

    /**
     * @dev Create a new agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    function createAgreement(
        bytes32 id,
        bytes32[] calldata data
    )
        external;
    /**
     * @dev Agreement created event
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    event AgreementCreated(
        address indexed agreementClass,
        bytes32 id,
        bytes32[] data
    );

    /**
     * @dev Get data of the agreement
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @return data Data of the agreement
     */
    function getAgreementData(
        address agreementClass,
        bytes32 id,
        uint dataLength
    )
        external view
        returns(bytes32[] memory data);

    /**
     * @dev Create a new agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    function updateAgreementData(
        bytes32 id,
        bytes32[] calldata data
    )
        external;
    /**
     * @dev Agreement updated event
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    event AgreementUpdated(
        address indexed agreementClass,
        bytes32 id,
        bytes32[] data
    );

    /**
     * @dev Close the agreement
     * @param id Agreement ID
     */
    function terminateAgreement(
        bytes32 id,
        uint dataLength
    )
        external;
    /**
     * @dev Agreement terminated event
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     */
    event AgreementTerminated(
        address indexed agreementClass,
        bytes32 id
    );

    /**
     * @dev Update agreement state slot
     * @param account Account to be updated
     *
     * @custom:note 
     * - To clear the storage out, provide zero-ed array of intended length
     */
    function updateAgreementStateSlot(
        address account,
        uint256 slotId,
        bytes32[] calldata slotData
    )
        external;
    /**
     * @dev Agreement account state updated event
     * @param agreementClass Contract address of the agreement
     * @param account Account updated
     * @param slotId slot id of the agreement state
     */
    event AgreementStateUpdated(
        address indexed agreementClass,
        address indexed account,
        uint256 slotId
    );

    /**
     * @dev Get data of the slot of the state of an agreement
     * @param agreementClass Contract address of the agreement
     * @param account Account to query
     * @param slotId slot id of the state
     * @param dataLength length of the state data
     */
    function getAgreementStateSlot(
        address agreementClass,
        address account,
        uint256 slotId,
        uint dataLength
    )
        external view
        returns (bytes32[] memory slotData);

    /**
     * @notice Settle balance from an account by the agreement
     * @dev The agreement needs to make sure that the balance delta is balanced afterwards
     * @param account Account to query.
     * @param delta Amount of balance delta to be settled
     *
     * @custom:modifiers 
     *  - onlyAgreement
     */
    function settleBalance(
        address account,
        int256 delta
    )
        external;

    /**
     * @dev Make liquidation payouts (v2)
     * @param id Agreement ID
     * @param liquidationTypeData Data regarding the version of the liquidation schema and the type
     * @param liquidatorAccount Address of the executor of the liquidation
     * @param useDefaultRewardAccount Whether or not the default reward account receives the rewardAmount
     * @param targetAccount Account to be liquidated
     * @param rewardAmount The amount the rewarded account will receive
     * @param targetAccountBalanceDelta The delta amount the target account balance should change by
     *
     * @custom:note 
     * - If a bailout is required (bailoutAmount > 0)
     *   - the actual reward (single deposit) goes to the executor,
     *   - while the reward account becomes the bailout account
     *   - total bailout include: bailout amount + reward amount
     *   - the targetAccount will be bailed out
     * - If a bailout is not required
     *   - the targetAccount will pay the rewardAmount
     *   - the liquidator (reward account in PIC period) will receive the rewardAmount
     *
     * @custom:modifiers 
     *  - onlyAgreement
     */
    function makeLiquidationPayoutsV2
    (
        bytes32 id,
        bytes memory liquidationTypeData,
        address liquidatorAccount,
        bool useDefaultRewardAccount,
        address targetAccount,
        uint256 rewardAmount,
        int256 targetAccountBalanceDelta
    ) external;
    /**
     * @dev Agreement liquidation event v2 (including agent account)
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param liquidatorAccount Address of the executor of the liquidation
     * @param targetAccount Account of the stream sender
     * @param rewardAmountReceiver Account that collects the reward or bails out insolvent accounts
     * @param rewardAmount The amount the reward recipient account balance should change by
     * @param targetAccountBalanceDelta The amount the sender account balance should change by
     * @param liquidationTypeData The encoded liquidation type data including the version (how to decode)
     *
     * @custom:note 
     * Reward account rule:
     * - if the agreement is liquidated during the PIC period
     *   - the rewardAmountReceiver will get the rewardAmount (remaining deposit), regardless of the liquidatorAccount
     *   - the targetAccount will pay for the rewardAmount
     * - if the agreement is liquidated after the PIC period AND the targetAccount is solvent
     *   - the rewardAmountReceiver will get the rewardAmount (remaining deposit)
     *   - the targetAccount will pay for the rewardAmount
     * - if the targetAccount is insolvent
     *   - the liquidatorAccount will get the rewardAmount (single deposit)
     *   - the default reward account (governance) will pay for both the rewardAmount and bailoutAmount
     *   - the targetAccount will receive the bailoutAmount
     */
    event AgreementLiquidatedV2(
        address indexed agreementClass,
        bytes32 id,
        address indexed liquidatorAccount,
        address indexed targetAccount,
        address rewardAmountReceiver,
        uint256 rewardAmount,
        int256 targetAccountBalanceDelta,
        bytes liquidationTypeData
    );

    /**************************************************************************
     * Function modifiers for access control and parameter validations
     *
     * While they cannot be explicitly stated in function definitions, they are
     * listed in function definition comments instead for clarity.
     *
     * NOTE: solidity-coverage not supporting it
     *************************************************************************/

     /// @dev The msg.sender must be host contract
     //modifier onlyHost() virtual;

    /// @dev The msg.sender must be a listed agreement.
    //modifier onlyAgreement() virtual;

    /**************************************************************************
     * DEPRECATED
     *************************************************************************/

    /**
     * @dev Agreement liquidation event (DEPRECATED BY AgreementLiquidatedBy)
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param penaltyAccount Account of the agreement to be penalized
     * @param rewardAccount Account that collect the reward
     * @param rewardAmount Amount of liquidation reward
     *
     * @custom:deprecated Use AgreementLiquidatedV2 instead
     */
    event AgreementLiquidated(
        address indexed agreementClass,
        bytes32 id,
        address indexed penaltyAccount,
        address indexed rewardAccount,
        uint256 rewardAmount
    );

    /**
     * @dev System bailout occurred (DEPRECATED BY AgreementLiquidatedBy)
     * @param bailoutAccount Account that bailout the penalty account
     * @param bailoutAmount Amount of account bailout
     *
     * @custom:deprecated Use AgreementLiquidatedV2 instead
     */
    event Bailout(
        address indexed bailoutAccount,
        uint256 bailoutAmount
    );

    /**
     * @dev Agreement liquidation event (DEPRECATED BY AgreementLiquidatedV2)
     * @param liquidatorAccount Account of the agent that performed the liquidation.
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param penaltyAccount Account of the agreement to be penalized
     * @param bondAccount Account that collect the reward or bailout accounts
     * @param rewardAmount Amount of liquidation reward
     * @param bailoutAmount Amount of liquidation bailouot
     *
     * @custom:deprecated Use AgreementLiquidatedV2 instead
     *
     * @custom:note 
     * Reward account rule:
     * - if bailout is equal to 0, then
     *   - the bondAccount will get the rewardAmount,
     *   - the penaltyAccount will pay for the rewardAmount.
     * - if bailout is larger than 0, then
     *   - the liquidatorAccount will get the rewardAmouont,
     *   - the bondAccount will pay for both the rewardAmount and bailoutAmount,
     *   - the penaltyAccount will pay for the rewardAmount while get the bailoutAmount.
     */
    event AgreementLiquidatedBy(
        address liquidatorAccount,
        address indexed agreementClass,
        bytes32 id,
        address indexed penaltyAccount,
        address indexed bondAccount,
        uint256 rewardAmount,
        uint256 bailoutAmount
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import { ISuperfluid } from "./ISuperfluid.sol";
import { ISuperfluidToken } from "./ISuperfluidToken.sol";
import { TokenInfo } from "../tokens/TokenInfo.sol";
import { IERC777 } from "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IConstantOutflowNFT } from "./IConstantOutflowNFT.sol";
import { IConstantInflowNFT } from "./IConstantInflowNFT.sol";
import { IPoolAdminNFT } from "./IPoolAdminNFT.sol";
import { IPoolMemberNFT } from "./IPoolMemberNFT.sol";

/**
 * @title Super token (Superfluid Token + ERC20 + ERC777) interface
 * @author Superfluid
 */
interface ISuperToken is ISuperfluidToken, TokenInfo, IERC20, IERC777 {

    /**************************************************************************
     * Errors
     *************************************************************************/
    error SUPER_TOKEN_CALLER_IS_NOT_OPERATOR_FOR_HOLDER();       // 0xf7f02227
    error SUPER_TOKEN_NOT_ERC777_TOKENS_RECIPIENT();             // 0xfe737d05
    error SUPER_TOKEN_INFLATIONARY_DEFLATIONARY_NOT_SUPPORTED(); // 0xe3e13698
    error SUPER_TOKEN_NO_UNDERLYING_TOKEN();                     // 0xf79cf656
    error SUPER_TOKEN_ONLY_SELF();                               // 0x7ffa6648
    error SUPER_TOKEN_ONLY_HOST();                               // 0x98f73704
    error SUPER_TOKEN_ONLY_GOV_OWNER();                          // 0xd9c7ed08
    error SUPER_TOKEN_APPROVE_FROM_ZERO_ADDRESS();               // 0x81638627
    error SUPER_TOKEN_APPROVE_TO_ZERO_ADDRESS();                 // 0xdf070274
    error SUPER_TOKEN_BURN_FROM_ZERO_ADDRESS();                  // 0xba2ab184
    error SUPER_TOKEN_MINT_TO_ZERO_ADDRESS();                    // 0x0d243157
    error SUPER_TOKEN_TRANSFER_FROM_ZERO_ADDRESS();              // 0xeecd6c9b
    error SUPER_TOKEN_TRANSFER_TO_ZERO_ADDRESS();                // 0xe219bd39
    error SUPER_TOKEN_NFT_PROXY_ADDRESS_CHANGED();               // 0x6bef249d

    /**
     * @dev Initialize the contract
     */
    function initialize(
        IERC20 underlyingToken,
        uint8 underlyingDecimals,
        string calldata n,
        string calldata s
    ) external;

    /**************************************************************************
    * Immutable variables
    *************************************************************************/

    // solhint-disable-next-line func-name-mixedcase
    function CONSTANT_OUTFLOW_NFT() external view returns (IConstantOutflowNFT);
    // solhint-disable-next-line func-name-mixedcase
    function CONSTANT_INFLOW_NFT() external view returns (IConstantInflowNFT);

    /**************************************************************************
    * TokenInfo & ERC777
    *************************************************************************/

    /**
     * @dev Returns the name of the token.
     */
    function name() external view override(IERC777, TokenInfo) returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view override(IERC777, TokenInfo) returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * @custom:note SuperToken always uses 18 decimals.
     *
     * This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view override(TokenInfo) returns (uint8);

    /**************************************************************************
    * ERC20 & ERC777
    *************************************************************************/

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view override(IERC777, IERC20) returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address account) external view override(IERC777, IERC20) returns(uint256 balance);

    /**************************************************************************
    * ERC20
    *************************************************************************/

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * @return Returns Success a boolean value indicating whether the operation succeeded.
     *
     * @custom:emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external override(IERC20) returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     *         allowed to spend on behalf of `owner` through {transferFrom}. This is
     *         zero by default.
     *
     * @notice This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external override(IERC20) view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * @return Returns Success a boolean value indicating whether the operation succeeded.
     *
     * @custom:note Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * @custom:emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external override(IERC20) returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     *         allowance mechanism. `amount` is then deducted from the caller's
     *         allowance.
     *
     * @return Returns Success a boolean value indicating whether the operation succeeded.
     *
     * @custom:emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override(IERC20) returns (bool);

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * @custom:emits an {Approval} event indicating the updated allowance.
     *
     * @custom:requirements 
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * @custom:emits an {Approval} event indicating the updated allowance.
     *
     * @custom:requirements 
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
     function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**************************************************************************
    * ERC777
    *************************************************************************/

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     *         means all token operations (creation, movement and destruction) must have
     *         amounts that are a multiple of this number.
     *
     * @custom:note For super token contracts, this value is always 1
     */
    function granularity() external view override(IERC777) returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * @dev If send or receive hooks are registered for the caller and `recipient`,
     *      the corresponding functions will be called with `data` and empty
     *      `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * @custom:emits a {Sent} event.
     *
     * @custom:requirements 
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(address recipient, uint256 amount, bytes calldata data) external override(IERC777);

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply and transfers the underlying token to the caller's account.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * @custom:emits a {Burned} event.
     *
     * @custom:requirements 
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external override(IERC777);

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external override(IERC777) view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * @custom:emits an {AuthorizedOperator} event.
     *
     * @custom:requirements 
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external override(IERC777);

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * @custom:emits a {RevokedOperator} event.
     *
     * @custom:requirements 
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external override(IERC777);

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external override(IERC777) view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * @custom:emits a {Sent} event.
     *
     * @custom:requirements 
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external override(IERC777);

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * @custom:emits a {Burned} event.
     *
     * @custom:requirements 
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external override(IERC777);

    /**************************************************************************
     * SuperToken custom token functions
     *************************************************************************/

    /**
     * @dev Mint new tokens for the account
     *
     * @custom:modifiers 
     *  - onlySelf
     */
    function selfMint(
        address account,
        uint256 amount,
        bytes memory userData
    ) external;

   /**
    * @dev Burn existing tokens for the account
    *
    * @custom:modifiers 
    *  - onlySelf
    */
   function selfBurn(
       address account,
       uint256 amount,
       bytes memory userData
   ) external;

   /**
    * @dev Transfer `amount` tokens from the `sender` to `recipient`.
    * If `spender` isn't the same as `sender`, checks if `spender` has allowance to
    * spend tokens of `sender`.
    *
    * @custom:modifiers 
    *  - onlySelf
    */
   function selfTransferFrom(
        address sender,
        address spender,
        address recipient,
        uint256 amount
   ) external;

   /**
    * @dev Give `spender`, `amount` allowance to spend the tokens of
    * `account`.
    *
    * @custom:modifiers 
    *  - onlySelf
    */
   function selfApproveFor(
        address account,
        address spender,
        uint256 amount
   ) external;

    /**************************************************************************
     * SuperToken extra functions
     *************************************************************************/

    /**
     * @dev Transfer all available balance from `msg.sender` to `recipient`
     */
    function transferAll(address recipient) external;

    /**************************************************************************
     * ERC20 wrapping
     *************************************************************************/

    /**
     * @dev Return the underlying token contract
     * @return tokenAddr Underlying token address
     */
    function getUnderlyingToken() external view returns(address tokenAddr);

    /**
     * @dev Upgrade ERC20 to SuperToken.
     * @param amount Number of tokens to be upgraded (in 18 decimals)
     *
     * @custom:note It will use `transferFrom` to get tokens. Before calling this
     * function you should `approve` this contract
     */
    function upgrade(uint256 amount) external;

    /**
     * @dev Upgrade ERC20 to SuperToken and transfer immediately
     * @param to The account to receive upgraded tokens
     * @param amount Number of tokens to be upgraded (in 18 decimals)
     * @param data User data for the TokensRecipient callback
     *
     * @custom:note It will use `transferFrom` to get tokens. Before calling this
     * function you should `approve` this contract
     * 
     * @custom:warning
     * - there is potential of reentrancy IF the "to" account is a registered ERC777 recipient.
     * @custom:requirements 
     * - if `data` is NOT empty AND `to` is a contract, it MUST be a registered ERC777 recipient otherwise it reverts.
     */
    function upgradeTo(address to, uint256 amount, bytes calldata data) external;

    /**
     * @dev Token upgrade event
     * @param account Account where tokens are upgraded to
     * @param amount Amount of tokens upgraded (in 18 decimals)
     */
    event TokenUpgraded(
        address indexed account,
        uint256 amount
    );

    /**
     * @dev Downgrade SuperToken to ERC20.
     * @dev It will call transfer to send tokens
     * @param amount Number of tokens to be downgraded
     */
    function downgrade(uint256 amount) external;

    /**
     * @dev Downgrade SuperToken to ERC20 and transfer immediately
     * @param to The account to receive downgraded tokens
     * @param amount Number of tokens to be downgraded (in 18 decimals)
     */
    function downgradeTo(address to, uint256 amount) external;

    /**
     * @dev Token downgrade event
     * @param account Account whose tokens are downgraded
     * @param amount Amount of tokens downgraded
     */
    event TokenDowngraded(
        address indexed account,
        uint256 amount
    );

    /**************************************************************************
    * Batch Operations
    *************************************************************************/

    /**
    * @dev Perform ERC20 approve by host contract.
    * @param account The account owner to be approved.
    * @param spender The spender of account owner's funds.
    * @param amount Number of tokens to be approved.
    *
    * @custom:modifiers 
    *  - onlyHost
    */
    function operationApprove(
        address account,
        address spender,
        uint256 amount
    ) external;

    function operationIncreaseAllowance(
        address account,
        address spender,
        uint256 addedValue
    ) external;

    function operationDecreaseAllowance(
        address account,
        address spender,
        uint256 subtractedValue
    ) external;

    /**
    * @dev Perform ERC20 transferFrom by host contract.
    * @param account The account to spend sender's funds.
    * @param spender The account where the funds is sent from.
    * @param recipient The recipient of the funds.
    * @param amount Number of tokens to be transferred.
    *
    * @custom:modifiers 
    *  - onlyHost
    */
    function operationTransferFrom(
        address account,
        address spender,
        address recipient,
        uint256 amount
    ) external;

    /**
    * @dev Perform ERC777 send by host contract.
    * @param spender The account where the funds is sent from.
    * @param recipient The recipient of the funds.
    * @param amount Number of tokens to be transferred.
    * @param data Arbitrary user inputted data
    *
    * @custom:modifiers 
    *  - onlyHost
    */
    function operationSend(
        address spender,
        address recipient,
        uint256 amount,
        bytes memory data
    ) external;

    /**
    * @dev Upgrade ERC20 to SuperToken by host contract.
    * @param account The account to be changed.
    * @param amount Number of tokens to be upgraded (in 18 decimals)
    *
    * @custom:modifiers 
    *  - onlyHost
    */
    function operationUpgrade(address account, uint256 amount) external;

    /**
    * @dev Downgrade ERC20 to SuperToken by host contract.
    * @param account The account to be changed.
    * @param amount Number of tokens to be downgraded (in 18 decimals)
    *
    * @custom:modifiers 
    *  - onlyHost
    */
    function operationDowngrade(address account, uint256 amount) external;

    // Flow NFT events
    /**
     * @dev Constant Outflow NFT proxy created event
     * @param constantOutflowNFT constant outflow nft address
     */
    event ConstantOutflowNFTCreated(
        IConstantOutflowNFT indexed constantOutflowNFT
    );

    /**
     * @dev Constant Inflow NFT proxy created event
     * @param constantInflowNFT constant inflow nft address
     */
    event ConstantInflowNFTCreated(
        IConstantInflowNFT indexed constantInflowNFT
    );

    /**************************************************************************
    * Function modifiers for access control and parameter validations
    *
    * While they cannot be explicitly stated in function definitions, they are
    * listed in function definition comments instead for clarity.
    *
    * NOTE: solidity-coverage not supporting it
    *************************************************************************/

    /// @dev The msg.sender must be the contract itself
    //modifier onlySelf() virtual

}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import { ISuperToken } from "./ISuperToken.sol";

import {
    IERC20,
    ERC20WithTokenInfo
} from "../tokens/ERC20WithTokenInfo.sol";

/**
 * @title Super token factory interface
 * @author Superfluid
 */
interface ISuperTokenFactory {

    /**************************************************************************
     * Errors
     *************************************************************************/
    error SUPER_TOKEN_FACTORY_ALREADY_EXISTS();                 // 0x91d67972
    error SUPER_TOKEN_FACTORY_DOES_NOT_EXIST();                 // 0x872cac48
    error SUPER_TOKEN_FACTORY_UNINITIALIZED();                  // 0x1b39b9b4
    error SUPER_TOKEN_FACTORY_ONLY_HOST();                      // 0x478b8e83
    error SUPER_TOKEN_FACTORY_NON_UPGRADEABLE_IS_DEPRECATED();  // 0x478b8e83
    error SUPER_TOKEN_FACTORY_ZERO_ADDRESS();                   // 0x305c9e82

    /**************************************************************************
    * Immutable Variables
    **************************************************************************/

    /**
     * @dev Get superfluid host contract address
     */
    function getHost() external view returns(address host);

    /// @dev Initialize the contract
    function initialize() external;

    /**
     * @notice Get the canonical super token logic.
     */
    function getSuperTokenLogic() external view returns (ISuperToken superToken);

    /**
     * @dev Upgradability modes
     */
    enum Upgradability {
        /// Non upgradable super token, `host.updateSuperTokenLogic` will revert
        NON_UPGRADABLE,
        /// Upgradable through `host.updateSuperTokenLogic` operation
        SEMI_UPGRADABLE,
        /// Always using the latest super token logic
        FULL_UPGRADABLE
    }

    /**
     * @notice Create new super token wrapper for the underlying ERC20 token
     * @param underlyingToken Underlying ERC20 token
     * @param underlyingDecimals Underlying token decimals
     * @param upgradability Upgradability mode
     * @param name Super token name
     * @param symbol Super token symbol
     * @return superToken The deployed and initialized wrapper super token
     */
    function createERC20Wrapper(
        IERC20 underlyingToken,
        uint8 underlyingDecimals,
        Upgradability upgradability,
        string calldata name,
        string calldata symbol
    )
        external
        returns (ISuperToken superToken);

    /**
     * @notice Create new super token wrapper for the underlying ERC20 token with extra token info
     * @param underlyingToken Underlying ERC20 token
     * @param upgradability Upgradability mode
     * @param name Super token name
     * @param symbol Super token symbol
     * @return superToken The deployed and initialized wrapper super token
     * NOTE:
     * - It assumes token provide the .decimals() function
     */
    function createERC20Wrapper(
        ERC20WithTokenInfo underlyingToken,
        Upgradability upgradability,
        string calldata name,
        string calldata symbol
    )
        external
        returns (ISuperToken superToken);

    /**
     * @notice Creates a wrapper super token AND sets it in the canonical list OR reverts if it already exists
     * @dev salt for create2 is the keccak256 hash of abi.encode(address(_underlyingToken))
     * @param _underlyingToken Underlying ERC20 token
     * @return ISuperToken the created supertoken
     */
    function createCanonicalERC20Wrapper(ERC20WithTokenInfo _underlyingToken)
        external
        returns (ISuperToken);

    /**
     * @notice Computes/Retrieves wrapper super token address given the underlying token address
     * @dev We return from our canonical list if it already exists, otherwise we compute it
     * @dev note that this function only computes addresses for SEMI_UPGRADABLE SuperTokens
     * @param _underlyingToken Underlying ERC20 token address
     * @return superTokenAddress Super token address
     * @return isDeployed whether the super token is deployed AND set in the canonical mapping
     */
    function computeCanonicalERC20WrapperAddress(address _underlyingToken)
        external
        view
        returns (address superTokenAddress, bool isDeployed);

    /**
     * @notice Gets the canonical ERC20 wrapper super token address given the underlying token address
     * @dev We return the address if it exists and the zero address otherwise
     * @param _underlyingTokenAddress Underlying ERC20 token address
     * @return superTokenAddress Super token address
     */
    function getCanonicalERC20Wrapper(address _underlyingTokenAddress)
        external
        view
        returns (address superTokenAddress);

    /**
     * @dev Creates a new custom super token
     * @param customSuperTokenProxy address of the custom supertoken proxy
     */
    function initializeCustomSuperToken(
        address customSuperTokenProxy
    )
        external;

    /**
      * @dev Super token logic created event
      * @param tokenLogic Token logic address
      */
    event SuperTokenLogicCreated(ISuperToken indexed tokenLogic);

    /**
      * @dev Super token created event
      * @param token Newly created super token address
      */
    event SuperTokenCreated(ISuperToken indexed token);

    /**
      * @dev Custom super token created event
      * @param token Newly created custom super token address
      */
    event CustomSuperTokenCreated(ISuperToken indexed token);

}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { TokenInfo } from "./TokenInfo.sol";

/**
 * @title ERC20 token with token info interface
 * @author Superfluid
 * @dev Using abstract contract instead of interfaces because old solidity
 *      does not support interface inheriting other interfaces
 * solhint-disable-next-line no-empty-blocks
 *
 */
// solhint-disable-next-line no-empty-blocks
abstract contract ERC20WithTokenInfo is IERC20, TokenInfo {}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

/**
 * @title ERC20 token info interface
 * @author Superfluid
 * @dev ERC20 standard interface does not specify these functions, but
 *      often the token implementations have them.
 */
interface TokenInfo {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.19;

/// @title SafeGasLibrary
/// @author Superfluid
/// @notice An internal library used to handle out of gas errors
library SafeGasLibrary {
    error OUT_OF_GAS(); // 0x20afada5

    function _isOutOfGas(uint256 gasLeftBefore) internal view returns (bool) {
        return gasleft() <= gasLeftBefore / 63;
    }

    /// @dev A function used in the catch block to handle true out of gas errors
    /// @param gasLeftBefore the gas left before the try/catch block
    function _revertWhenOutOfGas(uint256 gasLeftBefore) internal view {
// If the function actually runs out of gas, not just hitting the safety gas limit, we revert the whole transaction.
// This solves an issue where the gas estimaton didn't provide enough gas by default for the function to succeed.
// See https://medium.com/@wighawag/ethereum-the-concept-of-gas-and-its-dangers-28d0eb809bb2
        if (_isOutOfGas(gasLeftBefore)) {
            revert OUT_OF_GAS();
        }
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.19;

import { UUPSUtils } from "./UUPSUtils.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title UUPS (Universal Upgradeable Proxy Standard) Proxiable contract.
 */
abstract contract UUPSProxiable is Initializable {

    /**
     * @dev Get current implementation code address.
     */
    function getCodeAddress() public view returns (address codeAddress)
    {
        return UUPSUtils.implementation();
    }

    function updateCode(address newAddress) external virtual;

    // allows to mark logic contracts as initialized in order to reduce the attack surface
    // solhint-disable-next-line no-empty-blocks
    function castrate() external initializer { }

    /**
     * @dev Proxiable UUID marker function, this would help to avoid wrong logic
     *      contract to be used for upgrading.
     *
     * NOTE: The semantics of the UUID deviates from the actual UUPS standard,
     *       where it is equivalent of _IMPLEMENTATION_SLOT.
     */
    function proxiableUUID() public view virtual returns (bytes32);

    /**
     * @dev Update code address function.
     *      It is internal, so the derived contract could setup its own permission logic.
     */
    function _updateCodeAddress(address newAddress) internal
    {
        // require UUPSProxy.initializeProxy first
        require(UUPSUtils.implementation() != address(0), "UUPSProxiable: not upgradable");
        require(
            proxiableUUID() == UUPSProxiable(newAddress).proxiableUUID(),
            "UUPSProxiable: not compatible logic"
        );
        require(
            address(this) != newAddress,
            "UUPSProxiable: proxy loop"
        );
        UUPSUtils.setImplementation(newAddress);
        emit CodeUpdated(proxiableUUID(), newAddress);
    }

    event CodeUpdated(bytes32 uuid, address codeAddress);

}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.19;

/**
 * @title UUPS (Universal Upgradeable Proxy Standard) Shared Library
 */
library UUPSUtils {

    /**
     * @dev Implementation slot constant.
     * Using https://eips.ethereum.org/EIPS/eip-1967 standard
     * Storage slot 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
     * (obtained as bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)).
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev Get implementation address.
    function implementation() internal view returns (address impl) {
        assembly { // solium-disable-line
            impl := sload(_IMPLEMENTATION_SLOT)
        }
    }

    /// @dev Set new implementation address.
    function setImplementation(address codeAddress) internal {
        assembly {
            // solium-disable-line
            sstore(
                _IMPLEMENTATION_SLOT,
                codeAddress
            )
        }
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";
import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/agreements/ConstantFlowAgreementV1.sol";

contract BalanceChecker {
    address public vitalikAddress;
    ISuperToken public fUSDCx;
    IConstantFlowAgreementV1 CFA; // 0xcfA132E353cB4E398080B9700609bb008eceB125

    constructor(address _vitalikAddress, address _fUSDCx, address _CFA) {
        vitalikAddress = _vitalikAddress;
        fUSDCx = ISuperToken(_fUSDCx);
        CFA = IConstantFlowAgreementV1(_CFA);
    }

    function balanceOf(address _sender) public view returns (uint8) {
        (uint256 timestamp, , , ) = CFA.getFlow(
            fUSDCx,
            _sender,
            vitalikAddress
        );

        if (timestamp != 0) return 1;

        return 0;
    }
}