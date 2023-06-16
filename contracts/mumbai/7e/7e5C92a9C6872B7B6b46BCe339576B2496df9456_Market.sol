// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
pragma solidity ^0.8.19;

contract MarketEvent {
  event RegistryAddressUpdated(address newRoleAddress);
  event LogItemUpdate(uint id);
  event LogTrade(
    address indexed securityToken,
    address indexed paymentToken,
    uint256 securityAmount,
    uint256 paymentAmount
  );

  event LogMake(
    bytes32 indexed id,
    bytes32 indexed pair,
    address indexed maker,
    address securityToken,
    address paymentToken,
    uint256 securityAmount,
    uint256 paymentAmount,
    uint64 timestamp
  );

  event LogTake(
    bytes32 id,
    bytes32 indexed pair,
    address indexed maker,
    address securityToken,
    address paymentToken,
    address indexed taker,
    uint256 takeAmt,
    uint256 giveAmt,
    uint64 timestamp
  );

  event LogCanceled(
    uint256 indexed id,
    bytes32 indexed pair,
    address indexed maker,
    address securityToken,
    address paymentToken,
    uint256 takeAmt,
    uint256 giveAmt,
    uint64 timestamp
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./event/MarketEvent.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../registry/interface/IAddressRegistry.sol";
import "../registry/interface/ITokenRegistry.sol";

/**
 * MAR01: Sender is missing role
 * MAR02: Sender is missing role to buy
 * MAR03: Sender is missing role to cancel
 * MAR04: Sender is blocklisted nor missing role
 * MAR05: Token does not exist
 * MAR06: Token is paused nor blocklisted
 * MAR07: Offer is flagged as deleted
 */

contract Market is MarketEvent {
  using SafeERC20 for IERC20Permit;
  using SafeERC20 for IERC20;

  uint256 public last_offer_id;

  address internal _addressRegistry;

  mapping(uint256 => OfferInfo) public offers;

  bytes32 public constant MARKET_ADMIN_ROLE = keccak256("MARKET_ADMIN_ROLE");
  bytes32 public constant BLOCKLISTED_ROLE = keccak256("BLOCKLISTED_ROLE");

  bool locked;

  struct OfferInfo {
    address owner;
    address securityToken;
    uint256 securityAmount;
    address paymentToken;
    uint256 paymentAmount;
    uint256 timestamp;
    bool canceled;
  }

  modifier onlyRole(bytes32 _role) {
    address _roleAddress = getRoleAddr();
    require((IAccessControl(_roleAddress).hasRole(_role, msg.sender)));
    _;
  }

  modifier synchronized() {
    require(!locked);
    locked = true;
    _;
    locked = false;
  }

  modifier can_buy(uint256 id) {
    require(isCanceled(id), "MAR07");
    require(isActive(id));
    _;
  }

  modifier can_cancel(uint id) {
    require(isCanceled(id), "MAR07");
    require(isActive(id));
    require(getOwner(id) == msg.sender || hasRole(MARKET_ADMIN_ROLE), "MAR02");
    _;
  }

  modifier can_offer() {
    require(!hasRole(BLOCKLISTED_ROLE) || hasRole(MARKET_ADMIN_ROLE), "MAR04");
    _;
  }

  constructor(address addressRegistry_) {
    _addressRegistry = addressRegistry_;
  }

  // -----------------------------------------
  // Main functions MAKE ( offer ) / TAKE ( buy ) / KILL - CANCEL
  // -----------------------------------------
  function makeOffer(
    address owner,
    address secToken,
    uint256 secAmt,
    address payToken,
    uint256 payAmt,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public can_offer synchronized returns (uint id) {
    require(payAmt > 0);
    require(payToken != address(0));
    require(secAmt > 0);
    require(payToken != address(0));
    require(payToken != secToken);

    uint256 secVal = _convertInDecimal(secToken, secAmt);
    uint256 payVal = _convertInDecimal(payToken, payAmt);

    _checkSecTok(secToken);
    _checkPayTok(payToken);

    // check signature
    _checkApproval(secToken, owner, address(this), secVal, deadline, v, r, s);

    OfferInfo memory info;
    info.owner = owner;
    info.securityToken = secToken;
    info.securityAmount = secVal;
    info.paymentToken = payToken;
    info.paymentAmount = payVal;
    info.timestamp = uint64(block.timestamp);
    id = _next_id();
    offers[id] = info;

    IERC20(secToken).safeTransferFrom(owner, address(this), secAmt);

    emit LogItemUpdate(id);
    emit LogMake(
      bytes32(id),
      keccak256(abi.encodePacked(secToken, payToken)),
      msg.sender,
      secToken,
      payToken,
      secVal,
      payVal,
      uint64(block.timestamp)
    );
  }

  function buy(
    address buyer,
    uint256 id,
    uint256 quantity,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public can_buy(id) synchronized returns (bool) {
    OfferInfo memory offer = offers[id];
    uint256 spend = (quantity * offer.securityAmount) / offer.paymentAmount;

    if (quantity == 0 || quantity > offer.securityAmount || spend > offer.paymentAmount) {
      return false;
    }

    // check signature
    _checkApproval(offers[id].paymentToken, buyer, address(this), spend, deadline, v, r, s);

    offers[id].securityAmount = offer.securityAmount - quantity;
    offers[id].paymentAmount = offer.paymentAmount - spend;

    IERC20(offers[id].paymentToken).safeTransferFrom(buyer, offers[id].owner, spend);
    IERC20(offers[id].securityToken).safeTransfer(buyer, quantity);

    emit LogItemUpdate(id);
    emit LogTake(
      bytes32(id),
      keccak256(abi.encodePacked(offer.securityToken, offer.paymentToken)),
      offer.owner,
      offer.securityToken,
      offer.paymentToken,
      buyer,
      quantity,
      spend,
      uint64(block.timestamp)
    );
    emit LogTrade(offer.securityToken, offer.paymentToken, quantity, spend);

    return true;
  }

  function cancel(uint256 id) public can_cancel(id) synchronized returns (bool success) {
    offers[id].canceled = true;

    OfferInfo memory offer = offers[id];

    IERC20(offer.securityToken).safeTransfer(offer.owner, offer.securityAmount);

    emit LogItemUpdate(id);
    emit LogCanceled(
      id,
      keccak256(abi.encodePacked(offer.securityToken, offer.paymentToken)),
      offer.owner,
      offer.securityToken,
      offer.paymentToken,
      offer.securityAmount,
      offer.paymentAmount,
      uint64(block.timestamp)
    );

    success = true;
  }

  // ------------------  // -----------------------
  // Setters -- restricted
  // -----------------------------------------

  function setNewRegistryAddress(address newAddress) external onlyRole(MARKET_ADMIN_ROLE) {
    require(newAddress != address(0));
    require(newAddress != _addressRegistry);
    _addressRegistry = newAddress;
    emit RegistryAddressUpdated(newAddress);
  }

  // ---- Public entrypoints ---- //

  // -----------------------------------------
  // Getters registry addresses
  // -----------------------------------------

  function getTokenRegAddr() public view returns (address) {
    return IAddressRegistry(_addressRegistry).getTokenRegAddr();
  }

  function getRoleAddr() public view returns (address) {
    return IAddressRegistry(_addressRegistry).getRoleRegAddr();
  }

  // function getEventAddr() public view returns (address) {
  //   return IAddressRegistry(_addressRegistry).getEventRegAddr();
  // }

  // ---- Internal Utils ---- //
  function _checkApproval(
    address token,
    address owner,
    address spender,
    uint256 val,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal {
    IERC20Permit(token).safePermit(owner, spender, val, deadline, v, r, s);
  }

  function _checkPayTok(address token) internal view {
    address registryAddr = getTokenRegAddr();
    (string memory name, , bool isPaused, bool isBlocklisted) = ITokenRegistry(registryAddr).getStab(token);
    require(bytes(name).length != 0, "MAR05");
    require(!isPaused && isBlocklisted, "MAR06");
  }

  function _checkSecTok(address token) internal view {
    address registryAddr = getTokenRegAddr();
    (string memory name, , bool isPaused, bool isBlocklisted) = ITokenRegistry(registryAddr).getSec(token);
    require(bytes(name).length != 0, "MAR05");
    require(!isPaused && isBlocklisted, "MAR06");
  }

  function _next_id() internal returns (uint) {
    last_offer_id++;
    return last_offer_id;
  }

  function _convertInDecimal(address _token, uint256 _val) internal view returns (uint256) {
    return _val * 10 ** IERC20Metadata(_token).decimals();
  }

  // ---- Public  Utils ---- //

  function getAllOffersFor(address owner) public view returns (uint256[] memory id) {}

  function hasRole(bytes32 role) public view returns (bool) {
    address _rolesAddress = getRoleAddr();
    return IAccessControl(_rolesAddress).hasRole(role, msg.sender);
  }

  function isCanceled(uint256 id) public view returns (bool deleted) {
    return offers[id].canceled;
  }

  function isActive(uint256 id) public view returns (bool active) {
    return offers[id].timestamp > 0;
  }

  function getOwner(uint256 id) public view returns (address owner) {
    return offers[id].owner;
  }
}

pragma solidity ^0.8.19;

/**
 * @title IAddressRegistry
 * @dev IAddressRegistry contract
 *
 * @author surname name - <>
 * SPDX-License-Identifier: MIT
 *
 * Error messages
 * ADDR01: Cannot set the same value as new value
 *
 */

interface IAddressRegistry {
  function REGISTRY_MANAGEMENT_ROLE() external view returns (bytes32);

  function getCrowdsaleFactAddr() external view returns (address);

  function getTokenFactAddr() external view returns (address);

  function getCrowdsaleEventAddr() external view returns (address);

  function getSettlementEventAddr() external view returns (address);

  function getStableSwapEvent() external view returns (address);

  function getMarketAddr() external view returns (address);

  function getPriceFeedAddr() external view returns (address);

  function getRoleRegAddr() external view returns (address);

  function getPairFactoryAddr() external view returns (address);

  function getTokenRegAddr() external view returns (address);

  function getUserRegAddr() external view returns (address);

  function setCrowdsaleFactAddr(address newAddr) external;

  function setTokenFactAddr(address newAddr) external;

  function setCrowdsaleEventAddr(address newAddr) external;

  function setMarketAddr(address newAddr) external;

  function setPriceFeedAddr(address newAddr) external;

  function setRoleRegAddr(address newAddr) external;

  function setPairFactoryAddr(address newAddr) external;

  function setTokenRegAddr(address newAddr) external;
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.19;

interface ITokenRegistry {
  function ORACLE_ADMIN_ROLE() external view returns (bytes32);

  function add(address key, bool isStab) external;

  function blockListSec(address key) external;

  function blockListStab(address key) external;

  function delSec(address key) external;

  function delStab(address key) external;

  function getSettlementAddr() external view returns (address);

  function securityTokenExists(address key) external view returns (bool);

  function getSec(address key) external view returns (string memory, string memory, bool, bool);

  function getStab(address key) external view returns (string memory, string memory, bool, bool);

  function getTokenAddrAtIndex(uint256 id, bool isStab) external view returns (address);

  function getStabArrSize() external view returns (uint256);

  function pauseSec(address key) external;

  function pauseStab(address key) external;

  function unBlockListSec(address key) external;

  function unBlockListStab(address key) external;

  function unPauseSec(address key) external;

  function unPauseStab(address key) external;

  function getStableAddress(string memory symbol) external view returns (address);

  function getDecimals(address token) external view returns (uint8);
}