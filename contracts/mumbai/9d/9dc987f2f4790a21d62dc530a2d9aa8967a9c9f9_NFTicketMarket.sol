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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./interfaces/INFTicket.sol";
import "./interfaces/INFTicketMarket.sol";

contract NFTicketMarket is INFTicketMarket, IERC721Receiver {
    using SafeERC20 for IERC20;

    mapping(uint256 => TicketForSellData) public ticketsForSell;

    mapping(address => mapping(address => uint256)) public sellerBalance;

    address public immutable NFTicket;

    constructor(address _NFTicket) {
        NFTicket = _NFTicket;
    }

    function setTicketForSell(uint256 ticketId, uint256 price) external override {
        if (INFTicket(NFTicket).ownerOf(ticketId) != msg.sender) {
            revert MsgSenderIsNotTicketOwner();
        }

        ticketsForSell[ticketId].ticketOwner = msg.sender;
        ticketsForSell[ticketId].isActive = true;
        ticketsForSell[ticketId].price = price;

        INFTicket(NFTicket).safeTransferFrom(msg.sender, address(this), ticketId);
    }

    function updateTicketPrice(uint256 ticketId, uint256 newPrice) external override {
        if (!ticketsForSell[ticketId].isActive) {
            revert TicketIsNotOnSell();
        }
        if (ticketsForSell[ticketId].ticketOwner != msg.sender) {
            revert MsgSenderIsNotTicketOwner();
        }

        ticketsForSell[ticketId].price = newPrice;
    }

    function removeTicketForSell(uint256 ticketId) external override {
        if (!ticketsForSell[ticketId].isActive) {
            revert TicketIsNotOnSell();
        }
        if (ticketsForSell[ticketId].ticketOwner != msg.sender) {
            revert MsgSenderIsNotTicketOwner();
        }

        ticketsForSell[ticketId].isActive = false;
        INFTicket(NFTicket).safeTransferFrom(address(this), msg.sender, ticketId);
    }

    function buyTicket(uint256 ticketId) external override {
        if (!ticketsForSell[ticketId].isActive) {
            revert TicketIsNotOnSell();
        }
        if (ticketsForSell[ticketId].ticketOwner == msg.sender) {
            revert MsgSenderIsTicketOwner();
        }

        ticketsForSell[ticketId].isActive = false;

        uint256 ticketPrice = ticketsForSell[ticketId].price;
        if (ticketPrice > 0) {
            uint64 eventId = INFTicket(NFTicket).getEventIdFromTicketId(ticketId);
            (,,,, address tokenAddress,,) = INFTicket(NFTicket).events(eventId);
            sellerBalance[ticketsForSell[ticketId].ticketOwner][tokenAddress] =
                sellerBalance[ticketsForSell[ticketId].ticketOwner][tokenAddress] + ticketPrice;
            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), ticketPrice);
        }

        INFTicket(NFTicket).safeTransferFrom(address(this), msg.sender, ticketId);
    }

    function withdraw(address tokenAddress, uint256 amount) external override {
        if (sellerBalance[msg.sender][tokenAddress] < amount) {
            revert NoEnoughRequestedAmountForThisToken();
        }
        sellerBalance[msg.sender][tokenAddress] = sellerBalance[msg.sender][tokenAddress] - amount;
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFTicket is IERC721 {
    struct EventData {
        bytes32 merkleTreeRoot;
        address organiser;
        uint256 ticketSellStartTime;
        uint256 ticketSellEndTime;
        address tokenAddress;
        bool blockTicketSell;
        bool allowToSetTicketSoldFlag;
    }

    struct TicketPriceData {
        uint256 price;
        bool isFree;
    }

    struct TokenData {
        bool exist;
        bool isActive;
    }

    /// @dev Error thrown when only admin allowed to execute the transaction
    error OnlyAdminAllowed();

    /// @dev Error thrown when only admin or SET_TICKET_SOLD role allowed to execute the transaction
    error OnlyAdminOrSetFlagsAllowed();

    /// @dev Error thrown when organiser is not in approved status
    error OrganiserNotInApprovedStatus();

    /// @dev Error thrown when event with already exist
    error EventAlreadyExist();

    /// @dev Error thrown when event is not exist
    error EventIsNotExist();

    /// @dev Error thrown when token already added
    error TokenAlreadyExist();

    /// @dev Error thrown when token does not exist
    error TokenDoesNotExist();

    /// @dev Error thrown when event organiser is not msg.sender
    error MsgSenderIsNotEventOrganiser();

    /// @dev Error thrown when ticket sell is already started
    error TicketSellAlreadyStarted();

    /// @dev Error thrown when ticket sell start is not in future
    error TicketSellStartMustBeInFuture();

    /// @dev Error thrown when ticket sell start is after ticket sell end
    error TicketSellStartIsAfterTicketSellEnd();

    /// @dev Error thrown when token is not active
    error TokenIsNotActive();

    /// @dev Error thrown when organiser ID is not correct
    error OrganiserIdIsNotCorrect();

    /// @dev Error thrown when organiser event ID is not correct
    error OrganiserEventIdIsNotCorrect();

    /// @dev Error thrown when only event organiser has allowed to run transaction
    error OnlyEventOrganiserAllowed();

    /// @dev Error thrown when ticket with this ticketId and proof does not exist in event
    error TicketDoesNotExist();

    /// @dev Error thrown when ticket is set as sold
    error TicketIsSetAsSold();

    /// @dev Error thrown when ticket sell is not yet start
    error TicketSellIsNotStart();

    /// @dev Error thrown when ticket sell is finished
    error TicketSellIsFinished();

    /// @dev Error thrown when ticket sell is blocked
    error TicketSellIsBlocked();

    /// @dev Error thrown when ticket price is not set
    error TicketPriceIsNotSet();

    /// @dev Error thrown when ticket already minted (sold)
    error TicketAlreadyMinted();

    /// @dev Error thrown when set ticket sold flag not allowed
    error SetTicketSoldFlagNotAllowed();

    /// @dev Error thrown when there is no enough requested amount in this token
    error NoEnoughRequestedAmountForThisToken();

    /// @dev Error thrown because there is more than 8 levels
    error MoreThanEightLevels();

    /// @dev Get event data for a specific event ID
    /// @param eventId Event ID for which is event data requested
    function events(uint64 eventId) external view returns (bytes32, address, uint256, uint256, address, bool, bool);

    /// @dev Get address for organiser access control contract
    function organiserAccessControl() external view returns (address);

    /// @dev Get ticket levels price for a specific @param ticketLevel
    /// @param ticketLevel Ticket level for which is ticket price requested
    function ticketLevelsPrice(uint256 ticketLevel) external view returns (uint256, bool);

    /// @dev Get information about the token (token is set per event and in that token ticket could be bought/sold/resell)
    /// @param tokenAddress Address of an ERC20 token for which is getting base information
    function tokens(address tokenAddress) external view returns (bool, bool);

    /// @dev Get organiser balance per token
    /// @param organiser Organiser address
    /// @param tokenAddress Address of an ERC20 token in which gets paid
    function organisersBalance(address organiser, address tokenAddress) external view returns (uint256);

    /// @dev Get information if a ticket with @param ticketId sold on some other platform or not
    /// @param ticketId TicketID which is checked
    function soldTickets(uint256 ticketId) external view returns (bool);

    /// @dev Get last occupied event ID for @param ograniser
    /// @param organiser The organiser address
    function organiserEventIdCounter(address organiser) external view returns (uint32);

    /// @dev Add ERC20 token in a mapping
    /// @param tokenAddress Address of an ERC20 token which is adding in a mapping
    function addToken(address tokenAddress) external;

    /// @dev Change ERC20 token active status
    /// @param tokenAddress Address of an ERC20 token for which is changing active status
    /// @param isActive New active status
    function changeTokenActiveStatus(address tokenAddress, bool isActive) external;

    /// @dev Create event with a specific parameters
    /// @param eventId Event ID for which is creating an event
    /// @param merkleTreeRoot The Merkle tree root hash value which is generated for a tree with all tickets
    /// @param ticketSellStartTime Timestamp which tells when is allowed to start ticket sell
    /// @param ticketSellEndTime Timestamp which tells when is finished ticket sell
    /// @param tokenAddress Address of an ERC20 token in which event tickets will be bought/sold/resell
    /// @param allowToSetTicketSoldFlag The event owner allows/does not allow to contract owner to set a ticket as sold
    function createEvent(
        uint64 eventId,
        bytes32 merkleTreeRoot,
        uint256 ticketSellStartTime,
        uint256 ticketSellEndTime,
        address tokenAddress,
        bool allowToSetTicketSoldFlag
    ) external;

    /// @dev Update merkle tree root for a @param eventId
    /// @param eventId Event ID for which will be @param merkleTreeRoot updated
    function updateMerkleTreeRoot(uint64 eventId, bytes32 merkleTreeRoot) external;

    /// @dev Update ticket sell times
    /// @param eventId Event ID for which will be @param ticketSellStartTime and @param ticketSellEndTime updated
    /// @param ticketSellStartTime Timestamp which tells when is allowed to start ticket sell
    /// @param ticketSellEndTime Timestamp which tells when is finished ticket sell
    function updateTicketSellTimes(uint64 eventId, uint256 ticketSellStartTime, uint256 ticketSellEndTime) external;

    /// @dev Update token address
    /// @param eventId Event ID for which will be @param tokenAddress updated
    /// @param tokenAddress Address of an ERC20 token in which event tickets will be bought/sold/resell
    function updateTokenAddress(uint64 eventId, address tokenAddress) external;

    /// @dev Update block ticket sell flag on event
    /// @param eventId Event ID for which will be @param blockTicketSell updated
    /// @param blockTicketSell true/false values if the ticket sell should be blocked
    function setBlockTicketSellOnEvent(uint64 eventId, bool blockTicketSell) external;

    /// @dev Set that ticketID is sell / not sell on some other platform
    /// @param ticketId TicketID which is set
    /// @param proof An array of hash values which are packed in an array and represent proof that @param ticketId exists in the event
    /// @param ticketSoldFlag `true` if we want to set that ticketID is was sold on other platform, `false` if we reset that
    function setTicketSoldFlag(uint256 ticketId, bytes32[] calldata proof, bool ticketSoldFlag) external;

    /// @dev Mint a NFT (ticket)
    /// @param ticketId TicketID which is buying (mint)
    /// @param proof An array of hash values which are packed in an array and represent proof that @param ticketId exists in the event
    function mint(uint256 ticketId, bytes32[] calldata proof) external;

    /// @dev Withdraw ERC20 token from organiser side
    /// @param tokenAddress Address of an ERC20 token which withdrawing
    /// @param amount Amount that is withdrawing
    function withdraw(address tokenAddress, uint256 amount) external;

    /// @dev Set up ticket price for a ticket level
    /// @param ticketLevel Ticket level for which is set price
    /// @param price Price that is set for a ticket level
    function setupTicketPrice(uint256 ticketLevel, uint256 price) external;

    /// @dev Get next event ID for organiser with address @param account
    /// @param account Organiser address for which is get next free event ID
    function getNextOrganiserEventId(address account) external view returns (uint32);

    /// @dev Check is @param account has administrator role
    /// @param account The account address which will be checked
    function isAdminRole(address account) external view returns (bool);

    /// @dev Check is @param account has SET_TICKET_SOLD role
    /// @param account The account address which will be checked
    function isSetFlagsRole(address account) external view returns (bool);

    /// @dev Encode levels array into ticket ID
    /// @param levels The array of levels that should be encoded into ticketId
    //                  (max is 8 levels, the first level is event id)
    function encodeTicketID(uint32[] calldata levels) external pure returns (uint256);

    /// @dev Decode ticket ID into array of levels
    /// @param ticketId The ticketId that should be decoded into levels
    function decodeTicketID(uint256 ticketId) external pure returns (uint32[] memory);

    /// @dev Check if a ticket with @param ticketId exist (could be generated)
    ///         For this check is used MerkleTree.verify function
    /// @param ticketId Ticket ID which is check
    /// @param proof An array of hash values which are packed in an array and represent proof that @param ticketId exists in the event
    function isTicketExist(uint256 ticketId, bytes32[] calldata proof) external view returns (bool);

    /// @dev Get organiser ID from ticket ID
    /// @param ticketId Ticket ID from which is getting organiser ID
    function getOrganiserIdFromTicketId(uint256 ticketId) external pure returns (uint32);

    /// @dev Get organiser event ID from ticket ID
    /// @param ticketId Ticket ID from which is getting organiser event ID
    function getOrganiserEventIdFromTicketId(uint256 ticketId) external pure returns (uint32);

    /// @dev Get event ID from ticket ID
    /// @param ticketId Ticket ID from which is getting event ID
    function getEventIdFromTicketId(uint256 ticketId) external pure returns (uint64);

    /// @dev Get ticket price for @param ticketId
    /// @param ticketId Ticket ID for which is getting ticket price
    function getTicketPrice(uint256 ticketId) external view returns (TicketPriceData memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface INFTicketMarket {
    struct TicketForSellData {
        address ticketOwner;
        bool isActive;
        uint256 price;
    }

    /// @dev Error thrown when msg.sender is not owner for ticketId
    error MsgSenderIsNotTicketOwner();

    /// @dev Error thrown when ticket with id=ticketId is not on sell
    error TicketIsNotOnSell();

    /// @dev Error thrown when ticket owner is msg.sender
    error MsgSenderIsTicketOwner();

    /// @dev Error thrown when there is no enough requested amount in this token
    error NoEnoughRequestedAmountForThisToken();

    /// @dev Get information about a ticket that is set for sell
    /// @param ticketId Ticket ID for which is sell data requested
    function ticketsForSell(uint256 ticketId) external view returns (address, bool, uint256);

    /// @dev Get seller balance per user and per token address
    /// @param seller The address of a seller
    /// @param tokenAddress The address of a token
    function sellerBalance(address seller, address tokenAddress) external view returns (uint256);

    /// @dev Set ticket for sell in token that is set for the event
    /// @param ticketId TicketID which is set for sell
    /// @param price Price that is requested
    function setTicketForSell(uint256 ticketId, uint256 price) external;

    /// @dev Update ticket price in token that is set for the event
    /// @param ticketId TicketID which is update price for sell
    /// @param newPrice New price that is requested
    function updateTicketPrice(uint256 ticketId, uint256 newPrice) external;

    /// @dev Remove ticket for sell
    /// @param ticketId TicketID which is remove for sell
    function removeTicketForSell(uint256 ticketId) external;

    /// @dev Buy ticket with @param ticketId
    /// @param ticketId TicketID which is set for sell and with this function is buying
    function buyTicket(uint256 ticketId) external;

    /// @dev Withdraw the amount in the token address which tickets seller earned
    /// @param tokenAddress The address of a token
    /// @param amount The amount that the tickets seller wants to withdraw
    function withdraw(address tokenAddress, uint256 amount) external;
}