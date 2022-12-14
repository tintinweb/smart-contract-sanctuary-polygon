// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC1155/IERC1155Upgradeable.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total overall supply on top of the
 *      per-id supply tracking of ERC1155SupplyUpgradeable.
 *
 * Used to implement the ERC-4626 tokenized vault with shares tied to investment rounds.
 *
 * @author Roberto Cano <robercano>
 */
interface IERC1155FullSupplyUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Total amount of tokens in existence for all minted ids
     */
    function totalSupplyAll() external view returns (uint256);

    /**
     * @dev Total amount of tokens in existence with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Returns the sum of amounts of all ids owned by `account`
     */
    function balanceOfAll(address account) external view returns (uint256);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC20/IERC20Upgradeable.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";

import "../interfaces/IBaseRoundsVault.sol";

/**
    @notice This helper contract allows the user to exchange a receipt from the RoundsInputVault
    for a ticket from the RoundsOutputVault. This is done by burning the receipt in exchange
    for the corresponding amount of the main vault shares in the RoundsInputVault, and then
    depositing this shares into the RoundsOutputVault, which will mint the corresponding
    receipt to the user.

    After this operation is completed, the user has a receipt that can be exchanged for the main vaults
    underlying once the current round is over.
 */
contract RoundsVaultExchanger is Context {
    /**
      @notice Exchanges a receipt from the RoundsInputVault for a receipt from
      the RoundsOutputVault by redeeming the input receipt in the input vault for
      shares and then depositing these shares into the output vault in exchange for an output
      receipt

      @param inputVault The address of the RoundsInputVault
      @param outputVault The address of the RoundsOutputVault
      @param id The id of the receipt to exchange
      @param amount The amount of the receipt to exchange

      @dev The receipt must be for a previous round. If it is for the current round
      the transaction will revert

      @return The amount of shares deposited in the output vault
    */
    function exchangeInputForOutput(
        IBaseRoundsVault inputVault,
        IBaseRoundsVault outputVault,
        uint256 id,
        uint256 amount
    ) external returns (uint256) {
        uint256 sharesAmount = inputVault.redeemExchangeAsset(id, amount, address(this), _msgSender());

        SafeERC20.safeApprove(IERC20(inputVault.exchangeAsset()), address(outputVault), sharesAmount);

        return outputVault.deposit(sharesAmount, _msgSender());
    }

    /**
      @notice Exchanges a list of receipts from the RoundsInputVault for a receipt from
      the RoundsOutputVault by redeeming the input receipts in the input vault for
      shares and then depositing these shares into the output vault in exchange for an output
      receipt

      @param inputVault The address of the RoundsInputVault
      @param outputVault The address of the RoundsOutputVault
      @param ids The ids of the receipts to exchange
      @param amounts The amounts of the receipts to exchange

      @dev All receipts must be for a previous round. If any of the receipts is for the current round
      the transaction will revert

      @return The amount of shares deposited in the output vault
    */
    function exchangeInputForOutputBatch(
        IBaseRoundsVault inputVault,
        IBaseRoundsVault outputVault,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external returns (uint256) {
        uint256 sharesAmount = inputVault.redeemExchangeAssetBatch(ids, amounts, address(this), _msgSender());

        SafeERC20.safeApprove(IERC20(inputVault.exchangeAsset()), address(outputVault), sharesAmount);

        return outputVault.deposit(sharesAmount, _msgSender());
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "../interfaces/IEmergencyLock.sol";
import "../interfaces/IRefundsHelper.sol";
import "../interfaces/IRolesManager.sol";
import "../interfaces/IVaultDeferredOperationUpgradeable.sol";

/**
    @title BaseRoundsVaultUpgradeable

    @notice Provides a way of investing in a target tokenized vault that has investment periods in 
    which the vault is locked. During these locked periods, the vault does not accept deposits, so
    investors need to be on the lookout for the unlocked period to deposit their funds.

    Instead this contract allows investors to deposit their funds at any point in time. In exchange
    they receive a tokenized receipt that is tied to the investment round and contains the amount of
    assets deposited.

    On each round transition, this contract will use the available funds to deposit them into the
    target vault, getting an exchange asset in return. This exchange asset is typically the target
    vault shares when the underlying asset of this vault is the same as the underlying asset of the
    target vault. Otherwise, the exchange asset is the target vault underlying asset.

    The receipts belonging to the current round can always be redeemed immediately for the underlying
    token. 

    The user can also decide to exchange the receipts belonging to previous rounds for the ERC-20 exchange
    asset kept in this contract. The exchange asset can be immediately witdrawn by burning the corresponding
    receipts.

    This contract tracks the current round and also stores the shares price of the each finished round. This
    share price is used to calculate the amount of shares that the user will receive when redeeming a receipt
    for a finished round
            
    @author Roberto Cano <robercano>
 */

// TODO: We are having hierarchy linearization issues here because of the interfaces. Remove them and
// TODO: wait for the next release of the compiler to fix it
interface IBaseRoundsVault is IVaultDeferredOperationUpgradeable {
    // EVENTS
    event NextRound(uint256 indexed newRoundNumber, uint256 prevRoundExchangeRate);
    event WithdrawExchangeAsset(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 exchangeAssetAmount,
        uint256 receiptId,
        uint256 receiptAmount
    );
    event WithdrawExchangeAssetBatch(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 exchangeAssetAmount,
        uint256[] receiptIds,
        uint256[] receiptAmounts
    );

    // PUBLIC FUNCTIONS

    /**
        @notice Stores the exchange rate for the last round, operates to push or pull from
        the target vault starts a new round
     
        @dev Only the operator can call this function
     */
    function nextRound() external;

    /**
        @notice Redeems a receipt for a certain amount of target vault shares. The amount of shares is
                calculated based on the receipt's round share price and the amount of underlying tokens
                that the receipt represents

        @param id The id of the receipt to be redeemed
        @param amount The amount of the receipt to be redeemed
        @param receiver The address that will receive the target vault shares
        @param owner The address that owns the receipt, in case the caller is not the owner
     */
    function redeemExchangeAsset(
        uint256 id,
        uint256 amount,
        address receiver,
        address owner
    ) external returns (uint256);

    /**
        @notice Same functionality as { redeemForShares } but for multiple receipts at the once

        @dev See { redeemForShares } for more details
     */
    function redeemExchangeAssetBatch(
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
        @notice Returns the current round number
     */
    function getCurrentRound() external view returns (uint256);

    /**
        @notice Returns the asset used for the exchange
     */
    function exchangeAsset() external view returns (address);

    /**
        @notice Returns the exchange rate for the underlying to the exchange asset for a given round

        @dev It gives the amount of exchange asset that can be obtained for 1 underlying token, with the
        exchange asset decimals
     */
    function getExchangeRate(uint256 round) external view returns (uint256);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title EmergencyLock

    @author Roberto Cano <robercano>
    
    @notice Helper contract that allows the Admin to pause all the functionality of the vault in case
    of an emergency
 */

interface IEmergencyLock {
    // FUNCTIONS

    /**
        @notice Pauses the contract
     */
    function pause() external;

    /**
        @notice Unpauses the contract
     */
    function unpause() external;
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title IRefundsHelper

    @author Roberto Cano <robercano>
    
    @notice Helper contract that allows the Admin to refund tokens or ETH sent to the vault
    by mistake. At construction time it receives the list of tokens that cannot be refunded.
    Those tokens are typically the asset managed by the vault and any intermediary tokens
    that the vault may use to manage the asset.
 */
interface IRefundsHelper {
    /// FUNCTIONS

    /**
        @notice Refunds the given amount of tokens to the given address
        @param token address of the token to be refunded
        @param amount amount of tokens to be refunded
        @param recipient address to which the tokens will be refunded
     */
    function refund(
        address token,
        uint256 amount,
        address recipient
    ) external;

    /**
        @notice Refunds the given amount of ETH to the given address
        @param amount amount of tokens to be refunded
        @param recipient address to which the tokens will be refunded
     */
    function refundETH(uint256 amount, address payable recipient) external;

    /// GETTERS

    /**
        @notice Returns whether the given token is refundable or not

        @param token address of the token to be checked

        @return true if the token is refundable, false otherwise
     */
    function canRefund(address token) external view returns (bool);

    /**
        @notice Returns whether the ETH is refundable or not

        @return true if ETH is refundable, false otherwise
     */
    function canRefundETH() external view returns (bool);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable-4.7.3/access/IAccessControlEnumerableUpgradeable.sol";

/**
    @title IRolesManager

    @author Roberto Cano <robercano>
    
    @notice The RolesManager contract is a helper contract that provides a three access roles: Admin,
    Strategist and Operator. The scope of the different roles is as follows:
      - Admin: The admin role is the only role that can change the other roles, including the Admin
      role itself. 
      - Strategist: The strategist role is the one that can change the vault and action parameters
      related to the investment strategy. Things like slippage percentage, maximum premium, principal
      percentages, etc...
      - Operator: The operator role is the one that can cycle the vault and the action through its
      different states

    @dev The Admin can always change the Strategist address, Operator address and also change the Admin address.
    The Strategist and Operator roles have no special access except the access given explcitiely by their
    respective modifiers `onlyStrategist` and `onlyOperator`.
 */

/* solhint-disable-next-line no-empty-blocks */
interface IRolesManager is IAccessControlEnumerableUpgradeable {
    // Empty on purpose
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IVaultWithReceiptsUpgradeable.sol";

/**
 * @notice Interface of the ERC4626 "Tokenized Vault Standard", modified to emit ERC-1155 share tokens
 *         When depositing, the user of this contract must indicate for which id they are depositing. The
 *         emitted ERC-1155 token will be minted used that id, thus generating a receipt for the deposit
 *
 * @dev The `withdraw` function, along with the `previewWithdraw` and `maxWithdraw` functions
 *      have been removed because the only way to implement them is to support enumeration
 *      for the ERC-1155 tokens, which is quite heavy in gas costs.
 *
 * @author Roberto Cano <robercano>
 */
interface IVaultDeferredOperationUpgradeable is IVaultWithReceiptsUpgradeable {
    /**
     * @dev Returns the target vault for which this vault is accepting deposits
     */
    function vault() external view returns (address vaultAddress);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable-4.7.3/token/ERC1155/IERC1155Upgradeable.sol";
import "../extensions/interfaces/IERC1155FullSupplyUpgradeable.sol";

/**
    @notice Interface of the ERC4626 "Tokenized Vault Standard", modified to emit ERC-1155 receipts.
    When depositing a receipt is generated using an id provided by implementor of this interface.
    The receipt should contain the deposit amount. The id can be used freely to identify extra information
    about the deposit.
    
    @dev The `withdraw` function, along with the `previewWithdraw` and `maxWithdraw` functions
    have been removed because the only way to implement them is to support enumeration
    for the ERC-1155 tokens, which is quite heavy in gas costs.

    @dev Although the only withdrawal functions are `redeem` and `reedeemBatch` the events have been
    kept with the original names `Withdraw` and `WithdrawBatch` for backwards consistency.
 
    @dev This interface is a copy-paste of OpenZeppelin's `IERC4626Upgradeable.sol` with some modifications to
    support the ERC-1155 receipts.

    @author Roberto Cano <robercano>
 */
interface IVaultWithReceiptsUpgradeable is IERC1155FullSupplyUpgradeable {
    event DepositWithReceipt(address indexed caller, address indexed receiver, uint256 id, uint256 assets);

    event RedeemReceipt(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 id,
        uint256 amount
    );
    event RedeemReceiptBatch(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256[] ids,
        uint256[] amounts
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Mints shares Vault shares with the given id to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 sharesId,
        uint256 sharesAmount,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    /**
     * @dev Burns each batch of shares and the specific amounts and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the WithdrawBatch event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeemBatch(
        uint256[] memory sharesIds,
        uint256[] memory sharesAmounts,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}