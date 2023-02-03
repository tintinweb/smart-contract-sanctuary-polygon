/**
 *Submitted for verification at polygonscan.com on 2023-02-03
*/

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Upshot Technologies Inc. All Rights Reserved
pragma solidity 0.8.x;

// Copyright (c) 2022 Upshot Technologies Inc. All Rights Reserved

// Copyright (c) 2022 Upshot Technologies Inc. All Rights Reserved

enum PoolType {
    TOKEN,
    NFT,
    TRADE
}

struct CreatePairParamsErc20 {
    address token;                  // ERC20 token address
    address nft;                    // the address of the NFT collection that we are creating a pool for
    address bondingCurve;           // the address of the bonding curve contract, see sudoswap documentation
    address payable owner;          // owner creating the pool. Pool uses this info, but does not actually set it on the pair
    PoolType poolType;              // the pool type, see sudoswap documentation
    uint128 delta;                  // the delta of the pool, see sudoswap documentation
    uint96 fee;                     // the fee price of the pool for trades
    uint128 spotPrice;              // the spot price of the pool, see sudoswap documentation
    uint256[] tokenIdList;          // the token IDs of NFTs to deposit into the pool
    uint256 initialTokenBalance;    // the number of ERC20 tokens to transfer to the pool
}

struct CreatePairParamsEth {
    address nft;                   
    address bondingCurve;           
    address payable owner;         
    PoolType poolType;               
    uint128 delta;                  
    uint96 fee;                  
    uint128 spotPrice;             
    uint256[] tokenIdList;  
}

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                           EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_PERMIT_SIGNATURE");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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

// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

interface IOwnershipTransferCallback {
  function onOwnershipTransfer(address oldOwner) external;
}

abstract contract OwnableWithTransferCallback {
    using ERC165Checker for address;
    using Address for address;

    bytes4 constant TRANSFER_CALLBACK =
        type(IOwnershipTransferCallback).interfaceId;

    error Ownable_NotOwner();
    error Ownable_NewOwnerZeroAddress();

    address private _owner;

    event OwnershipTransferred(address indexed newOwner);

    /// @dev Initializes the contract setting the deployer as the initial owner.
    function __Ownable_init(address initialOwner) internal {
        _owner = initialOwner;
    }

    /// @dev Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        if (owner() != msg.sender) revert Ownable_NotOwner();
        _;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Disallows setting to the zero address as a way to more gas-efficiently avoid reinitialization
    /// When ownership is transferred, if the new owner implements IOwnershipTransferCallback, we make a callback
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert Ownable_NewOwnerZeroAddress();
        _transferOwnership(newOwner);

        // Call the on ownership transfer callback if it exists
        // @dev try/catch is around 5k gas cheaper than doing ERC165 checking
        if (newOwner.isContract()) {
            try
                IOwnershipTransferCallback(newOwner).onOwnershipTransfer(msg.sender)
            {} catch (bytes memory) {}
        }
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Internal function without access restriction.
    function _transferOwnership(address newOwner) internal virtual {
        _owner = newOwner;
        emit OwnershipTransferred(newOwner);
    }
}

// Forked from OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol), 
// removed initializer check as we already do that in our modified Ownable

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
abstract contract ReentrancyGuard {
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

    function __ReentrancyGuard_init() internal {
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
}

enum CurveErrorCode {
    OK, // No error
    INVALID_NUMITEMS, // The numItem value is 0
    SPOT_PRICE_OVERFLOW // The updated spot price doesn't fit into 128 bits
}

interface ICurve {
    /**
     * @dev Returns the type of curve as a string.
     */
    function name() external view returns (string memory);

    /**
        @notice Validates if a delta value is valid for the curve. The criteria for
        validity can be different for each type of curve, for instance ExponentialCurve
        requires delta to be greater than 1.
        @param delta The delta value to be validated
        @return valid True if delta is valid, false otherwise
     */
    function validateDelta(uint128 delta) external pure returns (bool valid);

    /**
        @notice Validates if a new spot price is valid for the curve. Spot price is generally assumed to be the immediate sell price of 1 NFT to the pool, in units of the pool's paired token.
        @param newSpotPrice The new spot price to be set
        @return valid True if the new spot price is valid, false otherwise
     */
    function validateSpotPrice(uint128 newSpotPrice)
        external
        view
        returns (bool valid);

    /**
        @notice Given the current state of the pair and the trade, computes how much the user
        should pay to purchase an NFT from the pair, the new spot price, and other values.
        @param spotPrice The current selling spot price of the pair, in tokens
        @param delta The delta parameter of the pair, what it means depends on the curve
        @param numItems The number of NFTs the user is buying from the pair
        @param feeMultiplier Determines how much fee the LP takes from this trade, 18 decimals
        @param protocolFeeMultiplier Determines how much fee the protocol takes from this trade, 18 decimals
        @return error Any math calculation errors, only Error.OK means the returned values are valid
        @return newSpotPrice The updated selling spot price, in tokens
        @return newDelta The updated delta, used to parameterize the bonding curve
        @return inputValue The amount that the user should pay, in tokens
        @return protocolFee The amount of fee to send to the protocol, in tokens
     */
    function getBuyInfo(
        uint128 spotPrice,
        uint128 delta,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier
    )
        external
        view
        returns (
            CurveErrorCode error,
            uint128 newSpotPrice,
            uint128 newDelta,
            uint256 inputValue,
            uint256 protocolFee
        );

    /**
        @notice Given the current state of the pair and the trade, computes how much the user
        should receive when selling NFTs to the pair, the new spot price, and other values.
        @param spotPrice The current selling spot price of the pair, in tokens
        @param delta The delta parameter of the pair, what it means depends on the curve
        @param numItems The number of NFTs the user is selling to the pair
        @param feeMultiplier Determines how much fee the LP takes from this trade, 18 decimals
        @param protocolFeeMultiplier Determines how much fee the protocol takes from this trade, 18 decimals
        @return error Any math calculation errors, only Error.OK means the returned values are valid
        @return newSpotPrice The updated selling spot price, in tokens
        @return newDelta The updated delta, used to parameterize the bonding curve
        @return outputValue The amount that the user should receive, in tokens
        @return protocolFee The amount of fee to send to the protocol, in tokens
     */
    function getSellInfo(
        uint128 spotPrice,
        uint128 delta,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier
    )
        external
        view
        returns (
            CurveErrorCode error,
            uint128 newSpotPrice,
            uint128 newDelta,
            uint256 outputValue,
            uint256 protocolFee
        );
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

interface ILSSVMPairFactoryLike {
    enum PairVariant {
        ENUMERABLE_ETH,
        MISSING_ENUMERABLE_ETH,
        ENUMERABLE_ERC20,
        MISSING_ENUMERABLE_ERC20
    }

    function protocolFeeMultiplier() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address payable);

    function callAllowed(address target) external view returns (bool);

    function routerStatus(LSSVMRouter router)
        external
        view
        returns (bool allowed, bool wasEverAllowed);

    function isPair(address potentialPair, PairVariant variant)
        external
        view
        returns (bool);
}

contract LSSVMRouter {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    struct PairSwapAny {
        LSSVMPair pair;
        uint256 numItems;
    }

    struct PairSwapSpecific {
        LSSVMPair pair;
        uint256[] nftIds;
    }

    struct RobustPairSwapAny {
        PairSwapAny swapInfo;
        uint256 maxCost;
    }

    struct RobustPairSwapSpecific {
        PairSwapSpecific swapInfo;
        uint256 maxCost;
    }

    struct RobustPairSwapSpecificForToken {
        PairSwapSpecific swapInfo;
        uint256 minOutput;
    }

    struct NFTsForAnyNFTsTrade {
        PairSwapSpecific[] nftToTokenTrades;
        PairSwapAny[] tokenToNFTTrades;
    }

    struct NFTsForSpecificNFTsTrade {
        PairSwapSpecific[] nftToTokenTrades;
        PairSwapSpecific[] tokenToNFTTrades;
    }

    struct RobustPairNFTsFoTokenAndTokenforNFTsTrade {
        RobustPairSwapSpecific[] tokenToNFTTrades;
        RobustPairSwapSpecificForToken[] nftToTokenTrades;
        uint256 inputAmount;
        address payable tokenRecipient;
        address nftRecipient;
    }

    modifier checkDeadline(uint256 deadline) {
        _checkDeadline(deadline);
        _;
    }

    ILSSVMPairFactoryLike public immutable factory;

    constructor(ILSSVMPairFactoryLike _factory) {
        factory = _factory;
    }

    /**
        ETH swaps
     */

    /**
        @notice Swaps ETH into NFTs using multiple pairs.
        @param swapList The list of pairs to trade with and the number of NFTs to buy from each.
        @param ethRecipient The address that will receive the unspent ETH input
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent ETH amount
     */
    function swapETHForAnyNFTs(
        PairSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    )
        external
        payable
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        return
            _swapETHForAnyNFTs(swapList, msg.value, ethRecipient, nftRecipient);
    }

    /**
        @notice Swaps ETH into specific NFTs using multiple pairs.
        @param swapList The list of pairs to trade with and the IDs of the NFTs to buy from each.
        @param ethRecipient The address that will receive the unspent ETH input
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent ETH amount
     */
    function swapETHForSpecificNFTs(
        PairSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    )
        external
        payable
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        return
            _swapETHForSpecificNFTs(
                swapList,
                msg.value,
                ethRecipient,
                nftRecipient
            );
    }

    /**
        @notice Swaps one set of NFTs into another set of specific NFTs using multiple pairs, using
        ETH as the intermediary.
        @param trade The struct containing all NFT-to-ETH swaps and ETH-to-NFT swaps.
        @param minOutput The minimum acceptable total excess ETH received
        @param ethRecipient The address that will receive the ETH output
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ETH received
     */
    function swapNFTsForAnyNFTsThroughETH(
        NFTsForAnyNFTsTrade calldata trade,
        uint256 minOutput,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ETH
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        outputAmount = _swapNFTsForToken(
            trade.nftToTokenTrades,
            0,
            payable(address(this))
        );

        // Add extra value to buy NFTs
        outputAmount += msg.value;

        // Swap ETH for any NFTs
        // cost <= inputValue = outputAmount - minOutput, so outputAmount' = (outputAmount - minOutput - cost) + minOutput >= minOutput
        outputAmount =
            _swapETHForAnyNFTs(
                trade.tokenToNFTTrades,
                outputAmount - minOutput,
                ethRecipient,
                nftRecipient
            ) +
            minOutput;
    }

    /**
        @notice Swaps one set of NFTs into another set of specific NFTs using multiple pairs, using
        ETH as the intermediary.
        @param trade The struct containing all NFT-to-ETH swaps and ETH-to-NFT swaps.
        @param minOutput The minimum acceptable total excess ETH received
        @param ethRecipient The address that will receive the ETH output
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ETH received
     */
    function swapNFTsForSpecificNFTsThroughETH(
        NFTsForSpecificNFTsTrade calldata trade,
        uint256 minOutput,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ETH
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        outputAmount = _swapNFTsForToken(
            trade.nftToTokenTrades,
            0,
            payable(address(this))
        );

        // Add extra value to buy NFTs
        outputAmount += msg.value;

        // Swap ETH for specific NFTs
        // cost <= inputValue = outputAmount - minOutput, so outputAmount' = (outputAmount - minOutput - cost) + minOutput >= minOutput
        outputAmount =
            _swapETHForSpecificNFTs(
                trade.tokenToNFTTrades,
                outputAmount - minOutput,
                ethRecipient,
                nftRecipient
            ) +
            minOutput;
    }

    /**
        ERC20 swaps

        Note: All ERC20 swaps assume that a single ERC20 token is used for all the pairs involved.
        Swapping using multiple tokens in the same transaction is possible, but the slippage checks
        & the return values will be meaningless, and may lead to undefined behavior.

        Note: The sender should ideally grant infinite token approval to the router in order for NFT-to-NFT
        swaps to work smoothly.
     */

    /**
        @notice Swaps ERC20 tokens into NFTs using multiple pairs.
        @param swapList The list of pairs to trade with and the number of NFTs to buy from each.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
     */
    function swapERC20ForAnyNFTs(
        PairSwapAny[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapERC20ForAnyNFTs(swapList, inputAmount, nftRecipient);
    }

    /**
        @notice Swaps ERC20 tokens into specific NFTs using multiple pairs.
        @param swapList The list of pairs to trade with and the IDs of the NFTs to buy from each.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
     */
    function swapERC20ForSpecificNFTs(
        PairSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapERC20ForSpecificNFTs(swapList, inputAmount, nftRecipient);
    }

    /**
        @notice Swaps NFTs into ETH/ERC20 using multiple pairs.
        @param swapList The list of pairs to trade with and the IDs of the NFTs to sell to each.
        @param minOutput The minimum acceptable total tokens received
        @param tokenRecipient The address that will receive the token output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total tokens received
     */
    function swapNFTsForToken(
        PairSwapSpecific[] calldata swapList,
        uint256 minOutput,
        address tokenRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        return _swapNFTsForToken(swapList, minOutput, payable(tokenRecipient));
    }

    /**
        @notice Swaps one set of NFTs into another set of specific NFTs using multiple pairs, using
        an ERC20 token as the intermediary.
        @param trade The struct containing all NFT-to-ERC20 swaps and ERC20-to-NFT swaps.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param minOutput The minimum acceptable total excess tokens received
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ERC20 tokens received
     */
    function swapNFTsForAnyNFTsThroughERC20(
        NFTsForAnyNFTsTrade calldata trade,
        uint256 inputAmount,
        uint256 minOutput,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ERC20
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        // output tokens are sent to msg.sender
        outputAmount = _swapNFTsForToken(
            trade.nftToTokenTrades,
            0,
            payable(msg.sender)
        );

        // Add extra value to buy NFTs
        outputAmount += inputAmount;

        // Swap ERC20 for any NFTs
        // cost <= maxCost = outputAmount - minOutput, so outputAmount' = outputAmount - cost >= minOutput
        // input tokens are taken directly from msg.sender
        outputAmount =
            _swapERC20ForAnyNFTs(
                trade.tokenToNFTTrades,
                outputAmount - minOutput,
                nftRecipient
            ) +
            minOutput;
    }

    /**
        @notice Swaps one set of NFTs into another set of specific NFTs using multiple pairs, using
        an ERC20 token as the intermediary.
        @param trade The struct containing all NFT-to-ERC20 swaps and ERC20-to-NFT swaps.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param minOutput The minimum acceptable total excess tokens received
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ERC20 tokens received
     */
    function swapNFTsForSpecificNFTsThroughERC20(
        NFTsForSpecificNFTsTrade calldata trade,
        uint256 inputAmount,
        uint256 minOutput,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ERC20
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        // output tokens are sent to msg.sender
        outputAmount = _swapNFTsForToken(
            trade.nftToTokenTrades,
            0,
            payable(msg.sender)
        );

        // Add extra value to buy NFTs
        outputAmount += inputAmount;

        // Swap ERC20 for specific NFTs
        // cost <= maxCost = outputAmount - minOutput, so outputAmount' = outputAmount - cost >= minOutput
        // input tokens are taken directly from msg.sender
        outputAmount =
            _swapERC20ForSpecificNFTs(
                trade.tokenToNFTTrades,
                outputAmount - minOutput,
                nftRecipient
            ) +
            minOutput;
    }

    /**
        Robust Swaps
        These are "robust" versions of the NFT<>Token swap functions which will never revert due to slippage
        Instead, users specify a per-swap max cost. If the price changes more than the user specifies, no swap is attempted. This allows users to specify a batch of swaps, and execute as many of them as possible.
     */

    /**
        @dev We assume msg.value >= sum of values in maxCostPerPair
        @notice Swaps as much ETH for any NFTs as possible, respecting the per-swap max cost.
        @param swapList The list of pairs to trade with and the number of NFTs to buy from each.
        @param ethRecipient The address that will receive the unspent ETH input
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
     */
    function robustSwapETHForAnyNFTs(
        RobustPairSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    )
        external
        payable
        virtual
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        remainingValue = msg.value;

        // Try doing each swap
        uint256 pairCost;
        CurveErrorCode error;
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate actual cost per swap
            (error, , , pairCost, ) = swapList[i].swapInfo.pair.getBuyNFTQuote(
                swapList[i].swapInfo.numItems
            );

            // If within our maxCost and no error, proceed
            if (
                pairCost <= swapList[i].maxCost &&
                error == CurveErrorCode.OK
            ) {
                // We know how much ETH to send because we already did the math above
                // So we just send that much
                remainingValue -= swapList[i].swapInfo.pair.swapTokenForAnyNFTs{
                    value: pairCost
                }(
                    swapList[i].swapInfo.numItems,
                    pairCost,
                    nftRecipient,
                    true,
                    msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
        @dev We assume msg.value >= sum of values in maxCostPerPair
        @param swapList The list of pairs to trade with and the IDs of the NFTs to buy from each.
        @param ethRecipient The address that will receive the unspent ETH input
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
     */
    function robustSwapETHForSpecificNFTs(
        RobustPairSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    )
        public
        payable
        virtual
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        remainingValue = msg.value;
        uint256 pairCost;
        CurveErrorCode error;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate actual cost per swap
            (error, , , pairCost, ) = swapList[i].swapInfo.pair.getBuyNFTQuote(
                swapList[i].swapInfo.nftIds.length
            );

            // If within our maxCost and no error, proceed
            if (
                pairCost <= swapList[i].maxCost &&
                error == CurveErrorCode.OK
            ) {
                // We know how much ETH to send because we already did the math above
                // So we just send that much
                remainingValue -= swapList[i]
                    .swapInfo
                    .pair
                    .swapTokenForSpecificNFTs{value: pairCost}(
                    swapList[i].swapInfo.nftIds,
                    pairCost,
                    nftRecipient,
                    true,
                    msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
        @notice Swaps as many ERC20 tokens for any NFTs as possible, respecting the per-swap max cost.
        @param swapList The list of pairs to trade with and the number of NFTs to buy from each.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount

     */
    function robustSwapERC20ForAnyNFTs(
        RobustPairSwapAny[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    )
        external
        virtual
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        remainingValue = inputAmount;
        uint256 pairCost;
        CurveErrorCode error;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate actual cost per swap
            (error, , , pairCost, ) = swapList[i].swapInfo.pair.getBuyNFTQuote(
                swapList[i].swapInfo.numItems
            );

            // If within our maxCost and no error, proceed
            if (
                pairCost <= swapList[i].maxCost &&
                error == CurveErrorCode.OK
            ) {
                remainingValue -= swapList[i].swapInfo.pair.swapTokenForAnyNFTs(
                        swapList[i].swapInfo.numItems,
                        pairCost,
                        nftRecipient,
                        true,
                        msg.sender
                    );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Swaps as many ERC20 tokens for specific NFTs as possible, respecting the per-swap max cost.
        @param swapList The list of pairs to trade with and the IDs of the NFTs to buy from each.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps

        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
     */
    function robustSwapERC20ForSpecificNFTs(
        RobustPairSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) public virtual checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = inputAmount;
        uint256 pairCost;
        CurveErrorCode error;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate actual cost per swap
            (error, , , pairCost, ) = swapList[i].swapInfo.pair.getBuyNFTQuote(
                swapList[i].swapInfo.nftIds.length
            );

            // If within our maxCost and no error, proceed
            if (
                pairCost <= swapList[i].maxCost &&
                error == CurveErrorCode.OK
            ) {
                remainingValue -= swapList[i]
                    .swapInfo
                    .pair
                    .swapTokenForSpecificNFTs(
                        swapList[i].swapInfo.nftIds,
                        pairCost,
                        nftRecipient,
                        true,
                        msg.sender
                    );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Swaps as many NFTs for tokens as possible, respecting the per-swap min output
        @param swapList The list of pairs to trade with and the IDs of the NFTs to sell to each.
        @param tokenRecipient The address that will receive the token output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ETH/ERC20 received
     */
    function robustSwapNFTsForToken(
        RobustPairSwapSpecificForToken[] calldata swapList,
        address payable tokenRecipient,
        uint256 deadline
    ) public virtual checkDeadline(deadline) returns (uint256 outputAmount) {
        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            uint256 pairOutput;

            // Locally scoped to avoid stack too deep error
            {
                CurveErrorCode error;
                (error, , , pairOutput, ) = swapList[i]
                    .swapInfo
                    .pair
                    .getSellNFTQuote(swapList[i].swapInfo.nftIds.length);
                if (error != CurveErrorCode.OK) {
                    unchecked {
                        ++i;
                    }
                    continue;
                }
            }

            // If at least equal to our minOutput, proceed
            if (pairOutput >= swapList[i].minOutput) {
                // Do the swap and update outputAmount with how many tokens we got
                outputAmount += swapList[i].swapInfo.pair.swapNFTsForToken(
                    swapList[i].swapInfo.nftIds,
                    0,
                    tokenRecipient,
                    true,
                    msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Buys NFTs with ETH and sells them for tokens in one transaction
        @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
        - ethToNFTSwapList The list of NFTs to buy
        - nftToTokenSwapList The list of NFTs to sell
        - inputAmount The max amount of tokens to send (if ERC20)
        - tokenRecipient The address that receives tokens from the NFTs sold
        - nftRecipient The address that receives NFTs
        - deadline UNIX timestamp deadline for the swap
     */
    function robustSwapETHForSpecificNFTsAndNFTsToToken(
        RobustPairNFTsFoTokenAndTokenforNFTsTrade calldata params
    )
        external
        payable
        virtual
        returns (uint256 remainingValue, uint256 outputAmount)
    {
        {
            remainingValue = msg.value;
            uint256 pairCost;
            CurveErrorCode error;

            // Try doing each swap
            uint256 numSwaps = params.tokenToNFTTrades.length;
            for (uint256 i; i < numSwaps; ) {
                // Calculate actual cost per swap
                (error, , , pairCost, ) = params
                    .tokenToNFTTrades[i]
                    .swapInfo
                    .pair
                    .getBuyNFTQuote(
                        params.tokenToNFTTrades[i].swapInfo.nftIds.length
                    );

                // If within our maxCost and no error, proceed
                if (
                    pairCost <= params.tokenToNFTTrades[i].maxCost &&
                    error == CurveErrorCode.OK
                ) {
                    // We know how much ETH to send because we already did the math above
                    // So we just send that much
                    remainingValue -= params
                        .tokenToNFTTrades[i]
                        .swapInfo
                        .pair
                        .swapTokenForSpecificNFTs{value: pairCost}(
                        params.tokenToNFTTrades[i].swapInfo.nftIds,
                        pairCost,
                        params.nftRecipient,
                        true,
                        msg.sender
                    );
                }

                unchecked {
                    ++i;
                }
            }

            // Return remaining value to sender
            if (remainingValue > 0) {
                params.tokenRecipient.safeTransferETH(remainingValue);
            }
        }
        {
            // Try doing each swap
            uint256 numSwaps = params.nftToTokenTrades.length;
            for (uint256 i; i < numSwaps; ) {
                uint256 pairOutput;

                // Locally scoped to avoid stack too deep error
                {
                    CurveErrorCode error;
                    (error, , , pairOutput, ) = params
                        .nftToTokenTrades[i]
                        .swapInfo
                        .pair
                        .getSellNFTQuote(
                            params.nftToTokenTrades[i].swapInfo.nftIds.length
                        );
                    if (error != CurveErrorCode.OK) {
                        unchecked {
                            ++i;
                        }
                        continue;
                    }
                }

                // If at least equal to our minOutput, proceed
                if (pairOutput >= params.nftToTokenTrades[i].minOutput) {
                    // Do the swap and update outputAmount with how many tokens we got
                    outputAmount += params
                        .nftToTokenTrades[i]
                        .swapInfo
                        .pair
                        .swapNFTsForToken(
                            params.nftToTokenTrades[i].swapInfo.nftIds,
                            0,
                            params.tokenRecipient,
                            true,
                            msg.sender
                        );
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
        @notice Buys NFTs with ERC20, and sells them for tokens in one transaction
        @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
        - ethToNFTSwapList The list of NFTs to buy
        - nftToTokenSwapList The list of NFTs to sell
        - inputAmount The max amount of tokens to send (if ERC20)
        - tokenRecipient The address that receives tokens from the NFTs sold
        - nftRecipient The address that receives NFTs
        - deadline UNIX timestamp deadline for the swap
     */
    function robustSwapERC20ForSpecificNFTsAndNFTsToToken(
        RobustPairNFTsFoTokenAndTokenforNFTsTrade calldata params
    )
        external
        payable
        virtual
        returns (uint256 remainingValue, uint256 outputAmount)
    {
        {
            remainingValue = params.inputAmount;
            uint256 pairCost;
            CurveErrorCode error;

            // Try doing each swap
            uint256 numSwaps = params.tokenToNFTTrades.length;
            for (uint256 i; i < numSwaps; ) {
                // Calculate actual cost per swap
                (error, , , pairCost, ) = params
                    .tokenToNFTTrades[i]
                    .swapInfo
                    .pair
                    .getBuyNFTQuote(
                        params.tokenToNFTTrades[i].swapInfo.nftIds.length
                    );

                // If within our maxCost and no error, proceed
                if (
                    pairCost <= params.tokenToNFTTrades[i].maxCost &&
                    error == CurveErrorCode.OK
                ) {
                    remainingValue -= params
                        .tokenToNFTTrades[i]
                        .swapInfo
                        .pair
                        .swapTokenForSpecificNFTs(
                            params.tokenToNFTTrades[i].swapInfo.nftIds,
                            pairCost,
                            params.nftRecipient,
                            true,
                            msg.sender
                        );
                }

                unchecked {
                    ++i;
                }
            }
        }
        {
            // Try doing each swap
            uint256 numSwaps = params.nftToTokenTrades.length;
            for (uint256 i; i < numSwaps; ) {
                uint256 pairOutput;

                // Locally scoped to avoid stack too deep error
                {
                    CurveErrorCode error;
                    (error, , , pairOutput, ) = params
                        .nftToTokenTrades[i]
                        .swapInfo
                        .pair
                        .getSellNFTQuote(
                            params.nftToTokenTrades[i].swapInfo.nftIds.length
                        );
                    if (error != CurveErrorCode.OK) {
                        unchecked {
                            ++i;
                        }
                        continue;
                    }
                }

                // If at least equal to our minOutput, proceed
                if (pairOutput >= params.nftToTokenTrades[i].minOutput) {
                    // Do the swap and update outputAmount with how many tokens we got
                    outputAmount += params
                        .nftToTokenTrades[i]
                        .swapInfo
                        .pair
                        .swapNFTsForToken(
                            params.nftToTokenTrades[i].swapInfo.nftIds,
                            0,
                            params.tokenRecipient,
                            true,
                            msg.sender
                        );
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    receive() external payable {}

    /**
        Restricted functions
     */

    /**
        @dev Allows an ERC20 pair contract to transfer ERC20 tokens directly from
        the sender, in order to minimize the number of token transfers. Only callable by an ERC20 pair.
        @param token The ERC20 token to transfer
        @param from The address to transfer tokens from
        @param to The address to transfer tokens to
        @param amount The amount of tokens to transfer
        @param variant The pair variant of the pair contract
     */
    function pairTransferERC20From(
        ERC20 token,
        address from,
        address to,
        uint256 amount,
        ILSSVMPairFactoryLike.PairVariant variant
    ) external {
        // verify caller is a trusted pair contract
        require(factory.isPair(msg.sender, variant), "Not pair");

        // verify caller is an ERC20 pair
        require(
            variant == ILSSVMPairFactoryLike.PairVariant.ENUMERABLE_ERC20 ||
                variant ==
                ILSSVMPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ERC20,
            "Not ERC20 pair"
        );

        // transfer tokens to pair
        token.safeTransferFrom(from, to, amount);
    }

    /**
        @dev Allows a pair contract to transfer ERC721 NFTs directly from
        the sender, in order to minimize the number of token transfers. Only callable by a pair.
        @param nft The ERC721 NFT to transfer
        @param from The address to transfer tokens from
        @param to The address to transfer tokens to
        @param id The ID of the NFT to transfer
        @param variant The pair variant of the pair contract
     */
    function pairTransferNFTFrom(
        IERC721 nft,
        address from,
        address to,
        uint256 id,
        ILSSVMPairFactoryLike.PairVariant variant
    ) external {
        // verify caller is a trusted pair contract
        require(factory.isPair(msg.sender, variant), "Not pair");

        // transfer NFTs to pair
        nft.safeTransferFrom(from, to, id);
    }

    /**
        Internal functions
     */

    /**
        @param deadline The last valid time for a swap
     */
    function _checkDeadline(uint256 deadline) internal view {
        require(block.timestamp <= deadline, "Deadline passed");
    }

    /**
        @notice Internal function used to swap ETH for any NFTs
        @param swapList The list of pairs and swap calldata
        @param inputAmount The total amount of ETH to send
        @param ethRecipient The address receiving excess ETH
        @param nftRecipient The address receiving the NFTs from the pairs
        @return remainingValue The unspent token amount
     */
    function _swapETHForAnyNFTs(
        PairSwapAny[] calldata swapList,
        uint256 inputAmount,
        address payable ethRecipient,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        uint256 pairCost;
        CurveErrorCode error;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate the cost per swap first to send exact amount of ETH over, saves gas by avoiding the need to send back excess ETH
            (error, , , pairCost, ) = swapList[i].pair.getBuyNFTQuote(
                swapList[i].numItems
            );

            // Require no error
            require(error == CurveErrorCode.OK, "Bonding curve error");

            // Total ETH taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pair.swapTokenForAnyNFTs{
                value: pairCost
            }(
                swapList[i].numItems,
                remainingValue,
                nftRecipient,
                true,
                msg.sender
            );

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
        @notice Internal function used to swap ETH for a specific set of NFTs
        @param swapList The list of pairs and swap calldata
        @param inputAmount The total amount of ETH to send
        @param ethRecipient The address receiving excess ETH
        @param nftRecipient The address receiving the NFTs from the pairs
        @return remainingValue The unspent token amount
     */
    function _swapETHForSpecificNFTs(
        PairSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address payable ethRecipient,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        uint256 pairCost;
        CurveErrorCode error;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate the cost per swap first to send exact amount of ETH over, saves gas by avoiding the need to send back excess ETH
            (error, , , pairCost, ) = swapList[i].pair.getBuyNFTQuote(
                swapList[i].nftIds.length
            );

            // Require no errors
            require(error == CurveErrorCode.OK, "Bonding curve error");

            // Total ETH taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pair.swapTokenForSpecificNFTs{
                value: pairCost
            }(
                swapList[i].nftIds,
                remainingValue,
                nftRecipient,
                true,
                msg.sender
            );

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
        @notice Internal function used to swap an ERC20 token for any NFTs
        @dev Note that we don't need to query the pair's bonding curve first for pricing data because
        we just calculate and take the required amount from the caller during swap time.
        However, we can't "pull" ETH, which is why for the ETH->NFT swaps, we need to calculate the pricing info
        to figure out how much the router should send to the pool.
        @param swapList The list of pairs and swap calldata
        @param inputAmount The total amount of ERC20 tokens to send
        @param nftRecipient The address receiving the NFTs from the pairs
        @return remainingValue The unspent token amount
     */
    function _swapERC20ForAnyNFTs(
        PairSwapAny[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Tokens are transferred in by the pair calling router.pairTransferERC20From
            // Total tokens taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pair.swapTokenForAnyNFTs(
                swapList[i].numItems,
                remainingValue,
                nftRecipient,
                true,
                msg.sender
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Internal function used to swap an ERC20 token for specific NFTs
        @dev Note that we don't need to query the pair's bonding curve first for pricing data because
        we just calculate and take the required amount from the caller during swap time.
        However, we can't "pull" ETH, which is why for the ETH->NFT swaps, we need to calculate the pricing info
        to figure out how much the router should send to the pool.
        @param swapList The list of pairs and swap calldata
        @param inputAmount The total amount of ERC20 tokens to send
        @param nftRecipient The address receiving the NFTs from the pairs
        @return remainingValue The unspent token amount
     */
    function _swapERC20ForSpecificNFTs(
        PairSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Tokens are transferred in by the pair calling router.pairTransferERC20From
            // Total tokens taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pair.swapTokenForSpecificNFTs(
                swapList[i].nftIds,
                remainingValue,
                nftRecipient,
                true,
                msg.sender
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Swaps NFTs for tokens, designed to be used for 1 token at a time
        @dev Calling with multiple tokens is permitted, BUT minOutput will be
        far from enough of a safety check because different tokens almost certainly have different unit prices.
        @param swapList The list of pairs and swap calldata
        @param minOutput The minimum number of tokens to be receieved from the swaps
        @param tokenRecipient The address that receives the tokens
        @return outputAmount The number of tokens to be received
     */
    function _swapNFTsForToken(
        PairSwapSpecific[] calldata swapList,
        uint256 minOutput,
        address payable tokenRecipient
    ) internal virtual returns (uint256 outputAmount) {
        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Do the swap for token and then update outputAmount
            // Note: minExpectedTokenOutput is set to 0 since we're doing an aggregate slippage check below
            outputAmount += swapList[i].pair.swapNFTsForToken(
                swapList[i].nftIds,
                0,
                tokenRecipient,
                true,
                msg.sender
            );

            unchecked {
                ++i;
            }
        }

        // Aggregate slippage check
        require(outputAmount >= minOutput, "outputAmount too low");
    }
}

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// Copyright (c) 2022 Upshot Technologies Inc. All Rights Reserved

interface IUpshotPool {
    // ===================== View ========================

    function admin() external view returns (address _admin);

    function initialized() external view returns (bool _initialized);

    function nft() external view returns (IERC721 _nft);

    function bondingCurve() external view returns (ICurve _bondingCurve);

    function token() external view returns (IERC20 _token);

    function poolType() external view returns (PoolType _poolType);

    function fee() external view returns (uint96 _fee);
    
    //linear and exponential only, xyk uses for a different purpose
    function delta() external view returns (uint128 _delta);
    
    function spotPrice() external view returns (uint128 _spotPrice);

    function sudoSwapPairFactory() external view returns (address factory_);

    function upshotPoolFactory() external view returns (address upshotFactory_);

    function getLpPositionCollection() external view returns (address lpc_);

    function getPairForTokenId(uint256 tokenId_) external view returns (address pair);

    function permitter() external view returns (address permitter);

    function enforceOnlyPermitter(address candidate) external view;

    // ================ User Interface ===================
    // add function(s) for adding/removing only eth, only nfts...
    function addLiquidityEth(uint256[] calldata tokenIdList, address lpPositionRecipient) external payable returns (address pair, uint256 lpPositionTokenId);

    function addLiquidityErc20(uint256[] calldata tokenIdList, uint256 countERC20, address lpPositionRecipient) external returns (address pair, uint256 lpPositionTokenId);

    function addLiquidityEthToExisting(uint256[] calldata tokenIdList_, uint256 lpPositionTokenId_) external payable returns (uint newTokenId);

    function addLiquidityErc20ToExisting(uint256[] calldata tokenIdList_, uint256 countERC20_, uint256 lpPositionTokenId_) external returns (uint newTokenId);

    function pullLiquidityEth(uint256[] calldata tokenIdList_, uint256 valueInWei_, uint256 lpPositionTokenId_) external returns (uint newTokenId);

    function pullLiquidityErc20(uint256[] calldata tokenIdList_, uint256 countERC20_, uint256 lpPositionTokenId_) external returns (uint newTokenId);

    function updateLpPositionMetadataOnTrade() external;

    // ============== Admin Operations ===================
    // SPIKE: how do people index events for sudeoswap rn
    function changeSpotPrice(uint128 newSpotPrice) external;

    function changeDelta(uint128 newDelta) external;

    function changeFee(uint96 newFee) external;

}

/// @title The base contract for an NFT/TOKEN AMM pair
/// @author boredGenius and 0xmons
/// @notice This implements the core swap logic from NFT to TOKEN
abstract contract LSSVMPair is
    OwnableWithTransferCallback,
    ReentrancyGuard,
    ERC1155Holder
{

    IUpshotPool public _pool; 
    //TODO: instead of having pool variables we can use owner() and wrap it as pool
    //also for nft()

    // 90%, must <= 1 - MAX_PROTOCOL_FEE (set in LSSVMPairFactory)
    uint256 internal constant MAX_FEE = 0.90e18;

    // The current price of the NFT
    // @dev this is generally used to mean the immediate sell price for the next marginal nft.
    // however, this should not be assumed, as future bonding curves may use spotprice in different ways.
    // use getbuynftquote and getsellnftquote for accurate pricing info.

    // delegated to the upshotSwap Pool
    //uint128 public spotPrice;

    // The parameter for the pair's bonding curve.
    // Units and meaning are bonding curve dependent.
    //
    // delegated to UpshotSwap Pool
    //uint128 public delta;

    // The spread between buy and sell prices, set to be a multiplier we apply to the buy price
    // Fee is only relevant for TRADE pools
    // Units are in base 1e18
    //
    // delegated to UpshotSwap Pool
    //uint96 public fee;

    // If set to 0, NFTs/tokens sent by traders during trades will be sent to the pair.
    // Otherwise, assets will be sent to the set address. Not available for TRADE pools.
    address payable public assetRecipient;

    // Events
    event SwapNFTInPair();
    event SwapNFTOutPair();
    event SpotPriceUpdate(uint128 newSpotPrice);
    event TokenDeposit(uint256 amount);
    event TokenWithdrawal(uint256 amount);
    event NFTWithdrawal();
    event DeltaUpdate(uint128 newDelta);
    event FeeUpdate(uint96 newFee);
    event AssetRecipientChange(address a);

    // Parameterized Errors
    error BondingCurveError(CurveErrorCode error);

    /**
      @notice Called during pair creation to set initial parameters
      @dev Only called once by factory to initialize.
      We verify this by making sure that the current owner is address(0). 
      The Ownable library we use disallows setting the owner to be address(0), so this condition
      should only be valid before the first initialize call. 
      @param _owner The owner of the pair
      @param _assetRecipient The address that will receive the TOKEN or NFT sent to this pair during swaps. NOTE: If set to address(0), they will go to the pair itself.
     */
    function initialize(
        address _owner,
        address payable _assetRecipient
    ) external payable {
        require(owner() == address(0), "Initialized");
        __Ownable_init(_owner);
        __ReentrancyGuard_init();

        _pool = IUpshotPool(owner());

        ICurve _bondingCurve = bondingCurve();
        PoolType _poolType = poolType();

        if ((_poolType == PoolType.TOKEN) || (_poolType == PoolType.NFT)) {
            require(_pool.fee() == 0, "Only Trade Pools can have nonzero fee");
            assetRecipient = _assetRecipient;
        } else if (_poolType == PoolType.TRADE) {
            require(_pool.fee() < MAX_FEE, "Trade fee must be less than 90%");
            require(
                _assetRecipient == address(0),
                "Trade pools can't set asset recipient"
            );
        }
        require(_bondingCurve.validateDelta(_pool.delta()), "Invalid delta for curve");
        require(
            _bondingCurve.validateSpotPrice(_pool.spotPrice()),
            "Invalid new spot price for curve"
        );
    }

    /**
     * Modifiers
     */
    modifier onlyPermitter() {
        _pool.enforceOnlyPermitter(msg.sender);
        _;
    }

    /**
     * External state-changing functions
     */

    /**
        @notice Sends token to the pair in exchange for any `numNFTs` NFTs
        @dev To compute the amount of token to send, call bondingCurve.getBuyInfo.
        This swap function is meant for users who are ID agnostic
        @param numNFTs The number of NFTs to purchase
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param nftRecipient The recipient of the NFTs
        @param isRouter True if calling from LSSVMRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
        @return inputAmount The amount of token used for purchase
     */
    function swapTokenForAnyNFTs(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable virtual nonReentrant onlyPermitter returns (uint256 inputAmount) {
        // Store locally to remove extra calls
        ILSSVMPairFactoryLike _factory = factory();
        ICurve _bondingCurve = bondingCurve();
        IERC721 _nft = nft();

        // Input validation
        {
            PoolType _poolType = poolType();
            require(
                _poolType == PoolType.NFT || _poolType == PoolType.TRADE,
                "Wrong Pool type"
            );
            require(
                (numNFTs > 0) && (numNFTs <= _nft.balanceOf(address(this))),
                "Ask for > 0 and <= balanceOf NFTs"
            );
        }

        // Call bonding curve for pricing information
        uint256 protocolFee;
        (protocolFee, inputAmount) = _calculateBuyInfoAndUpdatePoolParams(
            numNFTs,
            maxExpectedTokenInput
        );

        _pullTokenInputAndPayProtocolFee(
            inputAmount,
            isRouter,
            routerCaller,
            _factory,
            protocolFee
        );

        _sendAnyNFTsToRecipient(nftRecipient, numNFTs);

        _refundTokenToSender(inputAmount);

        emit SwapNFTOutPair();
        _pool.updateLpPositionMetadataOnTrade();
    }

    /**
        @notice Sends token to the pair in exchange for a specific set of NFTs
        @dev To compute the amount of token to send, call bondingCurve.getBuyInfo
        This swap is meant for users who want specific IDs. Also higher chance of
        reverting if some of the specified IDs leave the pool before the swap goes through.
        @param nftIds The list of IDs of the NFTs to purchase
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param nftRecipient The recipient of the NFTs
        @param isRouter True if calling from LSSVMRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
        @return inputAmount The amount of token used for purchase
     */
    function swapTokenForSpecificNFTs(
        uint256[] calldata nftIds,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable virtual nonReentrant onlyPermitter returns (uint256 inputAmount) {
        // Store locally to remove extra calls
        ILSSVMPairFactoryLike _factory = factory();
        ICurve _bondingCurve = bondingCurve();

        // Input validation
        {
            PoolType _poolType = poolType();
            require(
                _poolType == PoolType.NFT || _poolType == PoolType.TRADE,
                "Wrong Pool type"
            );
            require((nftIds.length > 0), "Must ask for > 0 NFTs");
        }

        // Call bonding curve for pricing information
        uint256 protocolFee;
        (protocolFee, inputAmount) = _calculateBuyInfoAndUpdatePoolParams(
            nftIds.length,
            maxExpectedTokenInput
        );

        _pullTokenInputAndPayProtocolFee(
            inputAmount,
            isRouter,
            routerCaller,
            _factory,
            protocolFee
        );

        _sendSpecificNFTsToRecipient(nftRecipient, nftIds);

        _refundTokenToSender(inputAmount);

        emit SwapNFTOutPair();
        _pool.updateLpPositionMetadataOnTrade();
    }

    /**
        @notice Sends a set of NFTs to the pair in exchange for token
        @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
        @param nftIds The list of IDs of the NFTs to sell to the pair
        @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
        amount is less than this value, the transaction will be reverted.
        @param tokenRecipient The recipient of the token output
        @param isRouter True if calling from LSSVMRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
        @return outputAmount The amount of token received
     */
    function swapNFTsForToken(
        uint256[] calldata nftIds,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller
    ) external virtual nonReentrant onlyPermitter returns (uint256 outputAmount) {
        // Store locally to remove extra calls
        ILSSVMPairFactoryLike _factory = factory();
        ICurve _bondingCurve = bondingCurve();

        // Input validation
        {
            PoolType _poolType = poolType();
            require(
                _poolType == PoolType.TOKEN || _poolType == PoolType.TRADE,
                "Wrong Pool type"
            );
            require(nftIds.length > 0, "Must ask for > 0 NFTs");
        }

        // Call bonding curve for pricing information
        uint256 protocolFee;
        (protocolFee, outputAmount) = _calculateSellInfoAndUpdatePoolParams(
            nftIds.length,
            minExpectedTokenOutput
        );

        _sendTokenOutput(tokenRecipient, outputAmount);

        _payProtocolFeeFromPair(_factory, protocolFee);

        _takeNFTsFromSender(nftIds, isRouter, routerCaller);

        emit SwapNFTInPair();
        _pool.updateLpPositionMetadataOnTrade();
    }

    /**
     * View functions
     */

    /**
        @dev Used as read function to query the bonding curve for buy pricing info
        @param numNFTs The number of NFTs to buy from the pair
     */
    function getBuyNFTQuote(uint256 numNFTs)
        external
        view
        returns (
            CurveErrorCode error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 inputAmount,
            uint256 protocolFee
        )
    {
        (
            error,
            newSpotPrice,
            newDelta,
            inputAmount,
            protocolFee
        ) = bondingCurve().getBuyInfo(
            _pool.spotPrice(),
            _pool.delta(),
            numNFTs,
            _pool.fee(),
            factory().protocolFeeMultiplier()
        );
    }

    /**
        @dev Used as read function to query the bonding curve for sell pricing info
        @param numNFTs The number of NFTs to sell to the pair
     */
    function getSellNFTQuote(uint256 numNFTs)
        external
        view
        returns (
            CurveErrorCode error,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 outputAmount,
            uint256 protocolFee
        )
    {
        (
            error,
            newSpotPrice,
            newDelta,
            outputAmount,
            protocolFee
        ) = bondingCurve().getSellInfo(
            _pool.spotPrice(),
            _pool.delta(),
            numNFTs,
            _pool.fee(),
            factory().protocolFeeMultiplier()
        );
    }

    /**
        @notice Returns all NFT IDs held by the pool
     */
    function getAllHeldIds() external view virtual returns (uint256[] memory);

    /**
        @notice Returns the pair's variant (NFT is enumerable or not, pair uses ETH or ERC20)
     */
    function pairVariant()
        public
        pure
        virtual
        returns (ILSSVMPairFactoryLike.PairVariant);

    function factory() public view returns (ILSSVMPairFactoryLike _factory) {
        return ILSSVMPairFactoryLike(_pool.sudoSwapPairFactory());
    }

    /**
        @notice Returns the type of bonding curve that parameterizes the pair
     */
    function bondingCurve() public view returns (ICurve _bondingCurve) {
        return ICurve(_pool.bondingCurve());
    }

    /**
        @notice Returns the NFT collection that parameterizes the pair
     */
    function nft() public view returns (IERC721 _nft) {
        return IERC721(_pool.nft());
    }

    /**
        @notice Returns the pair's type (TOKEN/NFT/TRADE)
     */
    function poolType() public view returns (PoolType _poolType) {
        return PoolType(_pool.poolType());
    }

    /**
        @notice Returns the address that assets that receives assets when a swap is done with this pair
        Can be set to another address by the owner, if set to address(0), defaults to the pair's own address
     */
    function getAssetRecipient()
        public
        view
        returns (address payable _assetRecipient)
    {
        // If it's a TRADE pool, we know the recipient is 0 (TRADE pools can't set asset recipients)
        // so just return address(this)
        if (poolType() == PoolType.TRADE) {
            return payable(address(this));
        }

        // Otherwise, we return the recipient if it's been set
        // or replace it with address(this) if it's 0
        _assetRecipient = assetRecipient;
        if (_assetRecipient == address(0)) {
            // Tokens will be transferred to address(this)
            _assetRecipient = payable(address(this));
        }
    }

    /**
     * Internal functions
     */

    /**
        @notice Calculates the amount needed to be sent into the pair for a buy and adjusts spot price or delta if necessary
        @param numNFTs The amount of NFTs to purchase from the pair
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param protocolFee The percentage of protocol fee to be taken, as a percentage
        @return protocolFee The amount of tokens to send as protocol fee
        @return inputAmount The amount of tokens total tokens receive
     */
    function _calculateBuyInfoAndUpdatePoolParams(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput
    ) internal returns (uint256 protocolFee, uint256 inputAmount) {
        CurveErrorCode error;
        // Save on 2 SLOADs by caching
        uint128 currentSpotPrice = _pool.spotPrice();
        uint128 newSpotPrice;
        uint128 currentDelta = _pool.delta();
        uint128 newDelta;
        (
            error,
            newSpotPrice,
            newDelta,
            inputAmount,
            protocolFee
        ) = bondingCurve().getBuyInfo(
            currentSpotPrice,
            currentDelta,
            numNFTs,
            _pool.fee(),
            factory().protocolFeeMultiplier()
        );

        // Revert if bonding curve had an error
        if (error != CurveErrorCode.OK) {
            revert BondingCurveError(error);
        }

        // Revert if input is more than expected
        require(inputAmount <= maxExpectedTokenInput, "In too many tokens");

        // Consolidate writes to save gas
        if (currentSpotPrice != newSpotPrice || currentDelta != newDelta) {
            _pool.changeSpotPrice(newSpotPrice);
            _pool.changeDelta(newDelta);
        }

        // Emit spot price update if it has been updated
        if (currentSpotPrice != newSpotPrice) {
            emit SpotPriceUpdate(newSpotPrice);
        }

        // Emit delta update if it has been updated
        if (currentDelta != newDelta) {
            emit DeltaUpdate(newDelta);
        }
    }

    /**
        @notice Calculates the amount needed to be sent by the pair for a sell and adjusts spot price or delta if necessary
        @param numNFTs The amount of NFTs to send to the the pair
        @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
        amount is less than this value, the transaction will be reverted.
        @param protocolFee The percentage of protocol fee to be taken, as a percentage
        @return protocolFee The amount of tokens to send as protocol fee
        @return outputAmount The amount of tokens total tokens receive
     */
    function _calculateSellInfoAndUpdatePoolParams(
        uint256 numNFTs,
        uint256 minExpectedTokenOutput
    ) internal returns (uint256 protocolFee, uint256 outputAmount) {
        CurveErrorCode error;
        // Save on 2 SLOADs by caching
        uint128 currentSpotPrice = _pool.spotPrice();
        uint128 newSpotPrice;
        uint128 currentDelta = _pool.delta();
        uint128 newDelta;
        (
            error,
            newSpotPrice,
            newDelta,
            outputAmount,
            protocolFee
        ) = bondingCurve().getSellInfo(
            currentSpotPrice,
            currentDelta,
            numNFTs,
            _pool.fee(),
            factory().protocolFeeMultiplier()
        );

        // Revert if bonding curve had an error
        if (error != CurveErrorCode.OK) {
            revert BondingCurveError(error);
        }

        // Revert if output is too little
        require(
            outputAmount >= minExpectedTokenOutput,
            "Out too little tokens"
        );

        // Consolidate writes to save gas
        if (currentSpotPrice != newSpotPrice || currentDelta != newDelta) {
            _pool.changeSpotPrice(newSpotPrice);
            _pool.changeDelta(newDelta);
        }

        // Emit spot price update if it has been updated
        if (currentSpotPrice != newSpotPrice) {
            emit SpotPriceUpdate(newSpotPrice);
        }

        // Emit delta update if it has been updated
        if (currentDelta != newDelta) {
            emit DeltaUpdate(newDelta);
        }
    }

    /**
        @notice Pulls the token input of a trade from the trader and pays the protocol fee.
        @param inputAmount The amount of tokens to be sent
        @param isRouter Whether or not the caller is LSSVMRouter
        @param routerCaller If called from LSSVMRouter, store the original caller
        @param _factory The LSSVMPairFactory which stores LSSVMRouter allowlist info
        @param protocolFee The protocol fee to be paid
     */
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool isRouter,
        address routerCaller,
        ILSSVMPairFactoryLike _factory,
        uint256 protocolFee
    ) internal virtual;

    /**
        @notice Sends excess tokens back to the caller (if applicable)
        @dev We send ETH back to the caller even when called from LSSVMRouter because we do an aggregate slippage check for certain bulk swaps. (Instead of sending directly back to the router caller) 
        Excess ETH sent for one swap can then be used to help pay for the next swap.
     */
    function _refundTokenToSender(uint256 inputAmount) internal virtual;

    /**
        @notice Sends protocol fee (if it exists) back to the LSSVMPairFactory from the pair
     */
    function _payProtocolFeeFromPair(
        ILSSVMPairFactoryLike _factory,
        uint256 protocolFee
    ) internal virtual;

    /**
        @notice Sends tokens to a recipient
        @param tokenRecipient The address receiving the tokens
        @param outputAmount The amount of tokens to send
     */
    function _sendTokenOutput(
        address payable tokenRecipient,
        uint256 outputAmount
    ) internal virtual;

    /**
        @notice Sends some number of NFTs to a recipient address, ID agnostic
        @dev Even though we specify the NFT address here, this internal function is only 
        used to send NFTs associated with this specific pool.
        @param nftRecipient The receiving address for the NFTs
        @param numNFTs The number of NFTs to send  
     */
    function _sendAnyNFTsToRecipient(
        address nftRecipient,
        uint256 numNFTs
    ) internal virtual;

    /**
        @notice Sends specific NFTs to a recipient address
        @dev Even though we specify the NFT address here, this internal function is only 
        used to send NFTs associated with this specific pool.
        @param nftRecipient The receiving address for the NFTs
        @param nftIds The specific IDs of NFTs to send  
     */
    function _sendSpecificNFTsToRecipient(
        address nftRecipient,
        uint256[] calldata nftIds
    ) internal virtual;

    /**
        @notice Takes NFTs from the caller and sends them into the pair's asset recipient
        @dev This is used by the LSSVMPair's swapNFTForToken function. 
        @param nftIds The specific NFT IDs to take
        @param isRouter True if calling from LSSVMRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
     */
    function _takeNFTsFromSender(
        uint256[] calldata nftIds,
        bool isRouter,
        address routerCaller
    ) internal virtual {
        {
            address _assetRecipient = getAssetRecipient();
            uint256 numNFTs = nftIds.length;

            if (isRouter) {
                // Verify if router is allowed
                LSSVMRouter router = LSSVMRouter(payable(msg.sender));
                (bool routerAllowed, ) = factory().routerStatus(router);
                require(routerAllowed, "Not router");

                // Call router to pull NFTs
                // If more than 1 NFT is being transfered, we can do a balance check instead of an ownership check, as pools are indifferent between NFTs from the same collection
                if (numNFTs > 1) {
                    uint256 beforeBalance = nft().balanceOf(_assetRecipient);
                    for (uint256 i = 0; i < numNFTs; ) {
                        router.pairTransferNFTFrom(
                            nft(),
                            routerCaller,
                            _assetRecipient,
                            nftIds[i],
                            pairVariant()
                        );

                        unchecked {
                            ++i;
                        }
                    }
                    require(
                        (nft().balanceOf(_assetRecipient) - beforeBalance) ==
                            numNFTs,
                        "NFTs not transferred"
                    );
                } else {
                    router.pairTransferNFTFrom(
                        nft(),
                        routerCaller,
                        _assetRecipient,
                        nftIds[0],
                        pairVariant()
                    );
                    require(
                        nft().ownerOf(nftIds[0]) == _assetRecipient,
                        "NFT not transferred"
                    );
                }
            } else {
                // Pull NFTs directly from sender
                for (uint256 i; i < numNFTs; ) {
                    nft().safeTransferFrom(
                        msg.sender,
                        _assetRecipient,
                        nftIds[i]
                    );

                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

    /**
        @dev Used internally to grab pair parameters from calldata, see LSSVMPairCloner for technical details
     */
    function _immutableParamsLength() internal pure virtual returns (uint256);

    /**
     * Owner functions
     */

    /**
        @notice Rescues a specified set of NFTs owned by the pair to the owner address. (onlyOwnable modifier is in the implemented function)
        @dev If the NFT is the pair's collection, we also remove it from the id tracking (if the NFT is missing enumerable).
        @param a The NFT to transfer
        @param nftIds The list of IDs of the NFTs to send to the owner
     */
    function withdrawERC721(IERC721 a, uint256[] calldata nftIds)
        external
        virtual;

    /**
        @notice Rescues ERC20 tokens from the pair to the owner. Only callable by the owner (onlyOwnable modifier is in the implemented function).
        @param a The token to transfer
        @param amount The amount of tokens to send to the owner
     */
    function withdrawERC20(ERC20 a, uint256 amount) external virtual;

    /**
        @notice Rescues ERC1155 tokens from the pair to the owner. Only callable by the owner.
        @param a The NFT to transfer
        @param ids The NFT ids to transfer
        @param amounts The amounts of each id to transfer
     */
    function withdrawERC1155(
        IERC1155 a,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyOwner {
        a.safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");
    }

    /**
        @notice Changes the address that will receive assets received from
        trades. Only callable by the owner.
        @param newRecipient The new asset recipient
     */
    function changeAssetRecipient(address payable newRecipient)
        external
        onlyOwner
    {
        PoolType _poolType = poolType();
        require(_poolType != PoolType.TRADE, "Not for Trade pools");
        if (assetRecipient != newRecipient) {
            assetRecipient = newRecipient;
            emit AssetRecipientChange(newRecipient);
        }
    }

    /**
        @notice Allows the pair to make arbitrary external calls to contracts
        whitelisted by the protocol. Only callable by the owner.
        @param target The contract to call
        @param data The calldata to pass to the contract
     */
    function call(address payable target, bytes calldata data)
        external
        onlyOwner
    {
        ILSSVMPairFactoryLike _factory = factory();
        require(_factory.callAllowed(target), "Target must be whitelisted");
        (bool result, ) = target.call{value: 0}(data);
        require(result, "Call failed");
    }

    /**
      @param _returnData The data returned from a multicall result
      @dev Used to grab the revert string from the underlying call
     */
    function _getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /*************************************************************************
     *                    Upshot Swap delegation functions                   *
     ************************************************************************/
    /**
     * @notice This is generally used to mean the immediate sell price for the next marginal NFT.
     * However, this should NOT be assumed, as future bonding curves may use spotPrice in different ways.
     * Use getBuyNFTQuote and getSellNFTQuote for accurate pricing info.
     * 
     * @return spotPrice of the next NFT
     */
    function spotPrice() external view returns(uint128) {
        return _pool.spotPrice();
    }

    /**
     * @notice The parameter for the pair's bonding curve.
     * Units and meaning are bonding curve dependent.
     * 
     * @return delta for the bonding curve
     */
    function delta() external view returns(uint128) {
        return _pool.delta();
    }

    /**
     * @notice The spread between buy and sell prices, set to be a multiplier we apply to the buy price
     * Fee is only relevant for TRADE pools
     * Units are in base 1e18
     * 
     * @return fee to purchase NFTs
     */
    function fee() external view returns(uint96) {
        return _pool.fee();
    }
}

/**
    @title An NFT/Token pair where the token is ETH
    @author boredGenius and 0xmons
 */
abstract contract LSSVMPairETH is LSSVMPair {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 61;

    /// @inheritdoc LSSVMPair
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool, /*isRouter*/
        address, /*routerCaller*/
        ILSSVMPairFactoryLike _factory,
        uint256 protocolFee
    ) internal override {
        require(msg.value >= inputAmount, "Sent too little ETH");

        // Transfer inputAmount ETH to assetRecipient if it's been set
        address payable _assetRecipient = getAssetRecipient();
        if (_assetRecipient != address(this)) {
            _assetRecipient.safeTransferETH(inputAmount - protocolFee);
        }

        // Take protocol fee
        if (protocolFee > 0) {
            // Round down to the actual ETH balance if there are numerical stability issues with the bonding curve calculations
            if (protocolFee > address(this).balance) {
                protocolFee = address(this).balance;
            }

            if (protocolFee > 0) {
                payable(address(factory())).safeTransferETH(protocolFee);
            }
        }
    }

    /// @inheritdoc LSSVMPair
    function _refundTokenToSender(uint256 inputAmount) internal override {
        // Give excess ETH back to caller
        if (msg.value > inputAmount) {
            payable(msg.sender).safeTransferETH(msg.value - inputAmount);
        }
    }

    /// @inheritdoc LSSVMPair
    function _payProtocolFeeFromPair(
        ILSSVMPairFactoryLike _factory,
        uint256 protocolFee
    ) internal override {
        // Take protocol fee
        if (protocolFee > 0) {
            // Round down to the actual ETH balance if there are numerical stability issues with the bonding curve calculations
            if (protocolFee > address(this).balance) {
                protocolFee = address(this).balance;
            }

            if (protocolFee > 0) {
                payable(address(_factory)).safeTransferETH(protocolFee);
            }
        }
    }

    /// @inheritdoc LSSVMPair
    function _sendTokenOutput(
        address payable tokenRecipient,
        uint256 outputAmount
    ) internal override {
        // Send ETH to caller
        if (outputAmount > 0) {
            tokenRecipient.safeTransferETH(outputAmount);
        }
    }

    /// @inheritdoc LSSVMPair
    // @dev see LSSVMPairCloner for params length calculation
    function _immutableParamsLength() internal pure override returns (uint256) {
        return IMMUTABLE_PARAMS_LENGTH;
    }

    /**
        @notice Withdraws all token owned by the pair to the owner address.
        @dev Only callable by the owner.
     */
    function withdrawAllETH() external onlyOwner {
        withdrawETH(address(this).balance);
    }

    /**
        @notice Withdraws a specified amount of token owned by the pair to the owner address.
        @dev Only callable by the owner.
        @param amount The amount of token to send to the owner. If the pair's balance is less than
        this value, the transaction will be reverted.
     */
    function withdrawETH(uint256 amount) public onlyOwner {
        payable(owner()).safeTransferETH(amount);

        // emit event since ETH is the pair token
        emit TokenWithdrawal(amount);
    }

    /// @inheritdoc LSSVMPair
    function withdrawERC20(ERC20 a, uint256 amount)
        external
        override
        onlyOwner
    {
        //a.safeTransfer(msg.sender, amount);
        a.transfer(msg.sender, amount);
    }

    /**
        @dev All ETH transfers into the pair are accepted. This is the main method
        for the owner to top up the pair's token reserves.
     */
    receive() external payable {
        emit TokenDeposit(msg.value);
    }

    /**
        @dev All ETH transfers into the pair are accepted. This is the main method
        for the owner to top up the pair's token reserves.
     */
    fallback() external payable {
        // Only allow calls without function selector
        require (msg.data.length == _immutableParamsLength()); 
        emit TokenDeposit(msg.value);
    }
}

// Copyright (c) 2022 Upshot Technologies Inc. All Rights Reserved

abstract contract AdminTwoStep {
    address public _admin;
    address public pendingAdmin;

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    function _setAdmin(address initialAdmin) internal {
        _admin = initialAdmin;
    }

    /*****************************************************
     * =============== User Interface ================== *
     *****************************************************/
    function transferAdmin(address newAdmin) external virtual onlyAdmin {
        pendingAdmin = newAdmin;
    }

    function claimAdmin() external onlyPendingAdmin {
        emit AdminTransferred(_admin, pendingAdmin);
        _admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    /*****************************************************
     * ================== Modifiers ==================== *
     *****************************************************/
    modifier onlyAdmin() {
        _requireOnlyAdmin();
        _;
    }

    modifier onlyPendingAdmin() {
        _requireOnlyPendingAdmin();
        _;
    }

    /*****************************************************
     * ==================== Auth ======================= *
     *****************************************************/
    // NOTE: These functions are broken out to minimize contract size.
    //   Internal calls require only jump statements,
    //   but require strings take a minimum of 32 bytes per string.
    //   modifiers copy their whole bytecode into the modified function.
    function _requireAuthorized(bool authorized) internal pure {
        require(authorized, "AdminTwoStep: invalid msg.sender");
    }

    function _requireOnlyAdmin() internal view {
        _requireAuthorized(msg.sender == _admin);
    }

    function _requireOnlyPendingAdmin() internal view {
        _requireAuthorized(msg.sender == pendingAdmin);
    }
}

// Copyright (c) 2022 Upshot Technologies Inc. All Rights Reserved

interface ILSSVMPair {
    function assetRecipient() external view returns (address);
    function owner() external view returns (address);
    //function nft() external pure returns (address _nft);
    function withdrawAllETH() external;
    function withdrawETH(uint256 amount) external;
    //function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external;
    function withdrawERC721(address a, uint256[] calldata nftIds) external;
    function changeAssetRecipient(address payable newRecipient) external;
    function getAssetRecipient() external view returns (address payable _assetRecipient);
    function withdrawERC20(address a, uint256 amount) external;
}

// Copyright (c) 2022 Upshot Technologies Inc. All Rights Reserved

interface ILSSVMPairFactory {
    function createPairERC20(CreatePairParamsErc20 calldata params) external returns (address pair);
    function createPairETH(
        address _nft,
        address _bondingCurve,
        address payable _assetRecipient,
        PoolType _poolType,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] calldata _initialNFTIDs
    ) external payable returns (address pair);
}

// Copyright (c) 2022 Upshot Technologies Inc. All Rights Reserved

//todo licensing forking solmate, we're MIT, they are AGPL

// Copyright (c) 2022 Upshot Technologies Inc. All Rights Reserved

struct SoLaLa {
    string curve;
    string delta;
    string fee;
    string nft;
    string xymbol;
    string admin; 
    string pool; 
}

// Copyright (c) 2022 Upshot Technologies Inc. All Rights Reserved

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

contract MetadataGenerator {

    string[] _topRight;
    
    string[] _topLeft;
    string[] _topLeftRare;
    string[] _bottomRight;
    string[] _bottomRightRare;

    string _topRightRare;
    string _bottomLeftRare;

    string[] _color;

    constructor() {
        _color.push("#ff00cd"); //pink 
        _color.push("#ff4300"); //orange
        _color.push("#0091ff"); //blue 
    }

    /**
     */
    function _getRandomNumber(uint256 max) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % max;
    }

    function _getRandomNumbers(string memory seed, uint256 upperBound) public view returns (uint256[3] memory) {
        uint256 randomKeccak = uint256(keccak256(abi.encodePacked(seed, block.difficulty, block.timestamp, block.number)));
        return [
        randomKeccak % upperBound,
        randomKeccak / upperBound % upperBound,
        randomKeccak / upperBound / upperBound % upperBound
        ];
    }

    /**
     * plants
     */
    function setTopRight(string memory svg_) external {
        _topRight.push(svg_);
    }

    //string _topRightRare;
    function setTopRightRare(string memory svg_) external {
        _topRightRare = svg_;
    }

    /**
     * squiggle
     */
    function setTopLeft(string memory svg_) public {
        _topLeft.push(svg_);
    }

    //string[] _topLeftRare;
    function setTopLeftRare(string memory svg_) public {
        _topLeftRare.push(svg_);
    }

    /**
     * spaceship
     */
    function setBottomRight(string memory svg_) public {
        _bottomRight.push(svg_);
    }

    //string[] _bottomRightRare;
    function setBottomRightRare(string memory svg_) public {
        _bottomRightRare.push(svg_);
    }

    /**
     * mountain (rare)
     */

    //string _bottomLeftRare; 
    function setBottomLeftRare(string memory svg_) public {
        _bottomLeftRare = svg_;
    }

    /**
     */
    function substring(string memory str, uint startIndex, uint endIndex) public pure returns (string memory ) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    /**
     * pink - #ff00cd
     * 
     * orange - #ff4300
     * 
     * blue - #0091ff
     */
    function _getComponent00() public view returns (string memory) {
        uint[3] memory randomNumbers = _getRandomNumbers(Strings.toHexString(uint256(uint160(msg.sender)), 20), 3);
        string memory color00 = _color[randomNumbers[0]];
        string memory color01 = _color[randomNumbers[1]];
        string memory color02 = _color[randomNumbers[2]];
        string memory svg00 = string(abi.encodePacked(
            '<defs>'
                '<style>'
                    '.color00 {',
                        bytes.concat(bytes('fill: '),bytes(color00),bytes(';')), 
                    '}'
                    '.color01 {',
                        bytes.concat(bytes('fill: '),bytes(color01),bytes(';')), 
                    '}'
                    '.color02 {',
                        bytes.concat(bytes('fill: '),bytes(color02),bytes(';')), 
                    '}'
                '</style>'
            '</defs>'
        ));
        return svg00;
    }

    /**
     * planet and addresses, curved text
     */
    function _getComponent01(bool rare, string memory admin, string memory pool) public view returns (string memory) {
        string memory svg00 = string(abi.encodePacked(
            rare ? _topRightRare : _topRight[_getRandomNumber(3)],
            '<path id="curve00" fill="transparent" d="M625.6,103.9c-45.4,97.4-50.2,212.3-3.9,324.8,80,194.3,288.1,321.2,503.4,323.5"/>'
            '<text font-family="monospace" font-size="1.75em">'
            '<textPath xlink:href="#curve00" fill="white">',
            string(abi.encodePacked('admin: ', admin)),
            '</textPath>'
            '</text>'
            '<path id="curve01" fill="transparent" d="M701,53.3c-61,88-72.5,242.4-30.6,344,72.3,175.5,260.2,290.1,454.7,292.2"/>'
            '<text font-family="monospace" font-size="1.75em">'
            '<textPath xlink:href="#curve01" class="color02">',
            string(abi.encodePacked('pool: ', pool)),
            '</textPath>'
            '</text>'));
        return svg00;
    }

    function _getComponent02(string memory curve, string memory delta, string memory fee, string memory nft) public pure returns (string memory) {
        string memory svg01 = string(abi.encodePacked(
            '<path class="color01" d="m177.47,584.01h-41.4v-41.5h41.4v41.5Zm-39.4-2h37.4v-37.5h-37.4v37.5Z" transform="translate(-90,0)"/>'
            '<path class="color01" d="m176.37,543.41c0,8.8,0,28.9-20.6,36.4-2.7,1-5.7,1.7-9.2,2.2-2.9.4-6.1.6-9.6.6v.2h39.5l-.1-39.4h0Z" transform="translate(-90,0)"/>'
            '<text x="95" y="575" font-family="monospace" font-size="1.75em" fill="white">',
            curve,
            '</text>'
            '<polygon class="color01" points="176.47 631.72 137.07 631.72 156.77 592.31 176.47 631.72" transform="translate(-90,5)"/>'
            '<text x="95" y="629" font-family="monospace" font-size="1.75em" fill="white">',
            delta,
            '</text>'
            '<ellipse class="color01" cx="67" cy="656.82" rx="19.75" ry="5.61"/>'
            '<path class="color01" transform="translate(-90,10)" d="m137.07,650.34v24.77c0,3.1,8.84,5.61,19.75,5.61s19.75-2.51,19.75-5.61v-24.77c-4.09,3.14-13.56,4.09-19.75,4.09s-15.66-.94-19.75-4.09Z"/>'
            '<text x="95" y="683" font-family="monospace" font-size="1.75em" fill="white"> ',
            fee,
            '</text>'
            '<rect class="color01" x="47" y="732.51" width="39.5" height="39.5"/>'
            '<text x="95" y="763" font-family="monospace" font-size="1.75em" fill="white">',
            nft,
            '</text>'
            ));
        return svg01;
    }

    function _getComponent03(bool rare, string memory xymbol) public view returns (string memory) {
        string memory svg02 = string(abi.encodePacked(
            '<path class="color01" d="m156.77,784.22h0c10.9,0,19.7,8.8,19.7,19.7h0c0,10.9-8.8,19.7-19.7,19.7h0c-10.9,0-19.7-8.8-19.7-19.7h0c0-10.9,8.8-19.7,19.7-19.7Z" transform="translate(-90,0)"/>'
            '<text x="95" y="816" font-family="monospace" font-size="1.75em" fill="white">',
            xymbol,
            '</text>',
            rare ? _topLeftRare[_getRandomNumber(3)] : _topLeft[_getRandomNumber(4)], //_topLeft[_getRandomNumber(4)],
            '<path d="M1087 779.7H602.3a37.3 37.3 0 0 1-37.3-37.3v-705A37.3 37.3 0 0 1 602.3 0H565V0h-42.3A37.3 37.3 0 0 1 560 37.4v271h-.3a37.3 37.3 0 0 1-37.3 37.3S0 345.6 0 345.6v5h522.5a37.3 37.3 0 0 1 37.2 37.3h.3v699.9a37.3 37.3 0 0 1-37.3 37.2h79.5a37.3 37.3 0 0 1-37.2-37.3V822a37.3 37.3 0 0 1 37.3-37.3h485.4A37.3 37.3 0 0 1 1125 822v-79.6a37.3 37.3 0 0 1-37.3 37.3Z" fill="white"/>',
            rare ? _bottomRightRare[_getRandomNumber(3)] : _bottomRight[_getRandomNumber(6)] , //_bottomRight[_getRandomNumber(6)],
            '<path d="M664.1 576.7c0-49.6-35.7-91-82.8-99.8A37.3 37.3 0 0 1 565 446h-5c0 12.7-6.5 24-16.3 30.7a101.8 101.8 0 0 0-20 193.8h-1 1c6 2.5 12.4 4.4 18.9 5.7A37.3 37.3 0 0 1 560 708h5c0-13.3 7-25 17.4-31.6 6.6-1.3 12.8-3.2 18.8-5.7h1-.9a101.8 101.8 0 0 0 62.8-93.9Zm-78.9 93.9h-45.4a96.8 96.8 0 0 1-2-187.3h49.5c41.3 11 71.8 48.7 71.8 93.4s-31.5 83.7-73.9 93.9Z" fill="white"/>'
            '<circle cx="50%" cy="51.26%" r="99" fill="', 
            rare ? "#083cfc" : "black", 
            '"/>'
            '<circle cx="50%" cy="51.26%" r="65" class="color00"/>'
            '<path d="M590.2 532.7c-2.8-2.4.4-6.7 3.5-4.8a53 53 0 0 1 16 16.3c8.6 13.5 9 30.7 3.2 30.7-4.6 0-8.6-1-8.6-15.1a36 36 0 0 0-14.1-27.1ZM571.4 520.7c4-.5 8 0 11.7 1.7 1.4.6 2.8 1.4 3.2 2.8a4 4 0 0 1-.4 2.7c-.2.3-.4.7-.7.8-.4.2-.7.2-1.1 0-1.4-.3-2.8-1-4-1.8a25 25 0 0 0-8.5-2.7c-.7 0-1.4-.2-1.8-.6-.6-.5-.5-1.5-.2-2.1.5-.8 1.5-1.3 1.7-.8ZM504.7 583a45.6 45.6 0 0 0 30.9 31.7c11.6 2.8 17-7.2 8.6-10.1-6-2.1-8.8 2-20.8-2.9-8-3.1-12.6-8.2-18.7-18.6ZM519 613.6a60.6 60.6 0 0 0 51.9 23.2 43 43 0 0 1-1.5-7c-1.5.5-3.1.6-4.7.6a71.4 71.4 0 0 1-45.7-16.8ZM572.1 629.9c.9 2 1.6 4 2 6.1 4.6-.8 9.1-2.2 13.2-4.2a20.5 20.5 0 0 1-2.5-7c-4 1.9-8.3 3.5-12.7 5Z" fill="white"/>'
            '<path d="M596 585c0 18.7-11 30-31.4 30-6.1 0-11.5-1-16-3 10.3-4.5 15.8-14 15.8-27v-5.6c0-.6-.6-1.1-1.2-1.1h-30.6v-36.8h4.5c1.6 3.2 4 5.7 6.8 7.6 2.2-3.4 5.3-6 9.4-7.6h.2c1.6 3.2 4 5.7 6.8 7.6 2.1-3.2 5-5.7 8.7-7.3 4.1.4 7.9 1.3 11.1 2.7-10.2 4.5-15.7 14-15.7 27v5c0 .9.8 1.7 1.8 1.7h30l-.1 6.7Z"/>'
            ));
        return svg02;
    }

    /**
     * 
     */
    function generateImage(string memory curve_,
                           string memory delta_,
                           string memory fee_,
                           string memory nft_,
                           string memory xymbol_,
                           string memory admin_, 
                           string memory pool_
    ) view internal returns (string memory) {
        //bool rare = _getRandomNumber(100) == 1 ? true : false;
        bool rare = _getRandomNumber(2) == 1 ? true : false;

        string memory colorRare = "#083cfc";
        string memory svg = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1125 1125">',
            _getComponent00(),
            rare ? string(abi.encodePacked('<rect width="100%" height="100%" fill="', colorRare, '"/>')) : '<rect width="100%" height="100%" fill="black"/>',
            _getComponent01(rare, admin_, pool_),
            _getComponent02(curve_, delta_, fee_, nft_),
            rare ? _bottomLeftRare : '', //montains
            _getComponent03(rare, xymbol_),
            '</svg>'));
        return svg;
    }

    /**
     * 
     */
    function _payloadTokenUri(SoLaLa memory input, uint256 tokenId_) view public returns (string memory) {
        string memory description = 'Upshot Swap is an NFT AMM that allows for autonomously providing liquidity and trading NFTs completely on-chain, without an off-chain orderbook. '
                                    'Liquidity providers deposit NFTs into Upshot Swap pools and are given NFT LP tokens to track their ownership of that liquidity. '
                                    'These NFT LP tokens represent liquidity in the AMM. '
                                    'When withdrawing liquidity, liquidity providers burn their NFT LP token(s) and are sent back the corresponding liquidity from the pool.';
        
        return
            string(abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(bytes(abi.encodePacked(
                        '{"name":"',
                            string(abi.encodePacked('Upshot Swap #', Strings.toString(tokenId_))),
                        '", "description":"',
                            description,
                        '", "image": "',
                            'data:image/svg+xml;base64,',
                            Base64.encode(bytes(generateImage(input.curve, input.delta, input.fee, input.nft, input.xymbol, input.admin, input.pool))),
                        '"}'
                    )))
            ));
    }

}

// Copyright (c) 2022 Upshot Technologies Inc. All Rights Reserved

interface IERC4906 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.    
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

interface ILpPosition is IERC4906 {
    function getLpPositionValue(uint _tokenId) external view returns (uint);
    function getLpPositionValueNft(uint _tokenId) external view returns (uint);
    function getLpPositionValueEthToken(uint _tokenId) external view returns (uint);
    function getNumNftsHeld(uint _tokenId) external view returns (uint);
    function getAllHeldIds(uint _tokenId) external view returns (uint256[] memory);
    function getPairForTokenId(uint _tokenId) external view returns (address);
    function getPoolForTokenId(uint256 tokenId_) external view returns (address);
    function getNftForTokenId(uint256 tokenId_) external view returns (address);
    function setApprovedUpshotPool(address upshotPool_, address nft_) external;
    function mint(address to, address _pair) external returns (uint256 id);
    function burn(uint256 tokenId_) external;
}

/**
    @title An NFT/Token pair where the token is an ERC20
    @author boredGenius and 0xmons
 */
abstract contract LSSVMPairERC20 is LSSVMPair {
    using SafeTransferLib for ERC20;

    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 81;

    /**
        @notice Returns the ERC20 token associated with the pair
        @dev See LSSVMPairCloner for an explanation on how this works
     */
    function token() public view returns (ERC20 _token) {
        return ERC20(address(_pool.token()));
    }

    /// @inheritdoc LSSVMPair
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool isRouter,
        address routerCaller,
        ILSSVMPairFactoryLike _factory,
        uint256 protocolFee
    ) internal override {
        require(msg.value == 0, "ERC20 pair");

        ERC20 _token = token();
        address _assetRecipient = getAssetRecipient();

        if (isRouter) {
            // Verify if router is allowed
            LSSVMRouter router = LSSVMRouter(payable(msg.sender));

            // Locally scoped to avoid stack too deep
            {
                (bool routerAllowed, ) = factory().routerStatus(router);
                require(routerAllowed, "Not router");
            }

            // Cache state and then call router to transfer tokens from user
            uint256 beforeBalance = _token.balanceOf(_assetRecipient);
            router.pairTransferERC20From(
                _token,
                routerCaller,
                _assetRecipient,
                inputAmount - protocolFee,
                pairVariant()
            );

            // Verify token transfer (protect pair against malicious router)
            require(
                _token.balanceOf(_assetRecipient) - beforeBalance ==
                    inputAmount - protocolFee,
                "ERC20 not transferred in"
            );

            router.pairTransferERC20From(
                _token,
                routerCaller,
                address(_factory),
                protocolFee,
                pairVariant()
            );

            // Note: no check for factory balance's because router is assumed to be set by factory owner
            // so there is no incentive to *not* pay protocol fee
        } else {
            // Transfer tokens directly
            _token.safeTransferFrom(
                msg.sender,
                _assetRecipient,
                inputAmount - protocolFee
            );

            // Take protocol fee (if it exists)
            if (protocolFee > 0) {
                _token.safeTransferFrom(
                    msg.sender,
                    address(_factory),
                    protocolFee
                );
            }
        }
    }

    /// @inheritdoc LSSVMPair
    function _refundTokenToSender(uint256 inputAmount) internal override {
        // Do nothing since we transferred the exact input amount
    }

    /// @inheritdoc LSSVMPair
    function _payProtocolFeeFromPair(
        ILSSVMPairFactoryLike _factory,
        uint256 protocolFee
    ) internal override {
        // Take protocol fee (if it exists)
        if (protocolFee > 0) {
            ERC20 _token = token();

            // Round down to the actual token balance if there are numerical stability issues with the bonding curve calculations
            uint256 pairTokenBalance = _token.balanceOf(address(this));
            if (protocolFee > pairTokenBalance) {
                protocolFee = pairTokenBalance;
            }
            if (protocolFee > 0) {
                _token.safeTransfer(address(_factory), protocolFee);
            }
        }
    }

    /// @inheritdoc LSSVMPair
    function _sendTokenOutput(
        address payable tokenRecipient,
        uint256 outputAmount
    ) internal override {
        // Send tokens to caller
        if (outputAmount > 0) {
            token().safeTransfer(tokenRecipient, outputAmount);
        }
    }

    /// @inheritdoc LSSVMPair
    // @dev see LSSVMPairCloner for params length calculation
    function _immutableParamsLength() internal pure override returns (uint256) {
        return IMMUTABLE_PARAMS_LENGTH;
    }

    /// @inheritdoc LSSVMPair
    function withdrawERC20(ERC20 a, uint256 amount)
        external
        override
        onlyOwner
    {
        a.safeTransfer(msg.sender, amount);

        if (a == token()) {
            // emit event since it is the pair token
            emit TokenWithdrawal(amount);
        }
    }
}

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

contract LpPosition is ILpPosition, ERC721 {

    MetadataGenerator public _renderer;

    address public immutable _upshotPoolFactory;
    uint256 public nextId = 1;
    uint256 public totalSupply;

    mapping(uint256 => address) internal _idToPair;
    mapping(address => uint256) internal _pairToId;

    mapping(uint256 => address) internal _idToPool;

    mapping(address => address) public _upshotPoolToNFT;

    constructor(address renderer_) ERC721("Upshot LP Positions NFT", "ULP") {
        _renderer = MetadataGenerator(renderer_);
        _upshotPoolFactory = msg.sender;
    }

    modifier onlyUpshotPoolFactory() {
        require(msg.sender == _upshotPoolFactory, "ONLY_UPFACTORY");
        _;
    }
    
    modifier onlyApprovedUpshotPools() {
        require(_upshotPoolToNFT[msg.sender] != address(0), "UPSHOT_POOL_ONLY");
        _;
    }

    /*************************************************************************
     *           _        _              _                                   *
     *       ___| |_ __ _| |_ ___    ___| |__   __ _ _ __   __ _  ___        *
     *      / __| __/ _` | __/ _ \  / __| '_ \ / _` | '_ \ / _` |/ _ \       *
     *      \__ \ || (_| | ||  __/ | (__| | | | (_| | | | | (_| |  __/       *
     *      |___/\__\__,_|\__\___|  \___|_| |_|\__,_|_| |_|\__, |\___|       *
     *                                                     |___/             *
     ************************************************************************/
    function setApprovedUpshotPool(address upshotPool_, address nft_) public onlyUpshotPoolFactory {
        _upshotPoolToNFT[upshotPool_] = nft_;
    }

    function mint(address _to, address _pair) public onlyApprovedUpshotPools returns (uint256 id) {
        id = nextId;

        _idToPair[id] = _pair;
        _idToPool[id] = msg.sender;
        _pairToId[_pair] = id;

        _safeMint(_to, id);

        unchecked { 
            nextId++; 
            totalSupply++;
        }

        return id;
    }

    function burn(uint256 tokenId_) external override onlyApprovedUpshotPools {
        delete _pairToId[_idToPair[tokenId_]];
        delete _idToPair[tokenId_];
        delete _idToPool[tokenId_];

        unchecked { totalSupply--; }

        _burn(tokenId_);
    }

    function emitMetadataUpdate(uint256 tokenId_) external onlyApprovedUpshotPools {
        emit MetadataUpdate(tokenId_);
    }

    /*************************************************************************
     *                             _                                         *
     *                      __   _(_) _____      __                          *
     *                      \ \ / / |/ _ \ \ /\ / /                          *
     *                       \ V /| |  __/\ V  V /                           *
     *                        \_/ |_|\___| \_/\_/                            *
     ************************************************************************/
    function getPairForTokenId(uint256 tokenId_) external view returns (address) {
        return _idToPair[tokenId_];
    }

    function getPoolForTokenId(uint256 tokenId_) external view returns (address) {
        return _idToPool[tokenId_];
    }

    function getNftForTokenId(uint256 tokenId_) external view returns (address){
        return address(LSSVMPair(_idToPair[tokenId_]).nft());
    }
    
    function getTokenIdForPair(address pair_) external view returns (uint256) {
        return _pairToId[pair_];
    }

    function getLpPositionValueEthToken(uint _tokenId) public view returns (uint) {
        LSSVMPair p = LSSVMPair(_idToPair[_tokenId]);
        ILSSVMPairFactoryLike.PairVariant pv = p.pairVariant();
        if(pv == ILSSVMPairFactoryLike.PairVariant.ENUMERABLE_ETH
            || pv == ILSSVMPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ETH
        ) {
            return address(p).balance;
        } else { 
            // (pv == ILSSVMPairFactoryLike.PairVariant.ENUMERABLE_ERC20) 
            // || (pv == ILSSVMPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ERC20)
            LSSVMPairERC20 pair20 = LSSVMPairERC20(_idToPair[_tokenId]);
            ERC20 token = ERC20(pair20.token());
            return token.balanceOf(address(pair20));
        }
    }

    function getAllHeldIds(uint _tokenId) external view returns (uint256[] memory) {
        LSSVMPair p = LSSVMPair(_idToPair[_tokenId]);
        return p.getAllHeldIds();
    }

    function getNumNftsHeld(uint256 tokenId) public view returns (uint256 balanceOf){
        IUpshotPool pool = IUpshotPool(_idToPool[tokenId]);
        address pair = _idToPair[tokenId];
        return IERC721(pool.nft()).balanceOf(pair); 
    }
    
    function getLpPositionValueNft(uint _tokenId) external view returns (uint) {
        LSSVMPair p = LSSVMPair(_idToPair[_tokenId]);
        return this.getNumNftsHeld(_tokenId) * p.spotPrice();
    }

    function getLpPositionValue(uint _tokenId) external view returns (uint) {
        return this.getLpPositionValueEthToken(_tokenId) + this.getLpPositionValueNft(_tokenId);
    }

    /**
     * 
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {

        IUpshotPool pool = IUpshotPool(_idToPool[tokenId]);
        
        ICurve bondingCurve = pool.bondingCurve();
        string memory curve = bondingCurve.name();
        string memory delta = string(abi.encodePacked('delta: ', Strings.toString(pool.delta()), '%'));
        string memory fee = string(abi.encodePacked('fee: ', Strings.toString(pool.fee()), '%'));
         string memory xool = Strings.toHexString(uint256(uint160(address(pool))), 20);
        string memory admin = Strings.toHexString(uint256(uint160(pool.admin())), 20);

        //TODO: truncate to 13 characters
        //TODO: truncate to '...million', etc
        string memory nft = string(abi.encodePacked(IERC721Metadata(address(pool.nft())).symbol(), ': ', Strings.toString(getNumNftsHeld(tokenId))));

        //TODO: truncate to '...million', etc
        string memory xymbol;
        IERC20 poolToken = pool.token();
        if(address(poolToken) == address(0)) {
            xymbol = string(abi.encodePacked('ETH: ', Strings.toString(getLpPositionValueEthToken(tokenId))));
        } else {
            //TODO: truncate to 13 characters
            xymbol = string(abi.encodePacked(IERC20Metadata(address(poolToken)).symbol(), ': ', Strings.toString(getLpPositionValueEthToken(tokenId))));
        }
        SoLaLa memory soLaLa = SoLaLa(curve, delta, fee, nft, xymbol, admin, xool);
        return _renderer._payloadTokenUri(soLaLa, tokenId);
    }

    //**************************************************************************
    //      _                  _               _                _____ ____  _  *
    //  ___| |_ __ _ _ __   __| | __ _ _ __ __| |   ___ _ __ __|___  |___ \/ | *
    // / __| __/ _` | '_ \ / _` |/ _` | '__/ _` |  / _ \ '__/ __| / /  __) | | *
    // \__ \ || (_| | | | | (_| | (_| | | | (_| | |  __/ | | (__ / /  / __/| | *
    // |___/\__\__,_|_| |_|\__,_|\__,_|_|  \__,_|  \___|_|  \___/_/  |_____|_| *
    //**************************************************************************
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x49064906 || // ERC165 Interface ID for ERC4906
            interfaceId == 0x5b5e139f;   // ERC165 Interface ID for ERC721Metadata
    }

    /**
     * TODO: remove me
     */
    function erase() public { 
        selfdestruct(payable(address(this))); 
    }
}

// Copyright (c) 2022 Upshot Technologies Inc. All Rights Reserved

//import {MetadataGenerator} from "../metadata/MetadataGenerator.sol";

contract UpshotPoolFactory is AdminTwoStep {

    address public _sudoswapPairFactory;
    
    UpshotPool public immutable _upshotPool;
    LpPosition public immutable _lpNft;

    event UpshotPoolCreated(address upshotPool);
    event LpPositionCollectionCreated(address nftCollection, address lpPosition);

    /**
     * @notice Create a new UpshotPoolFactory
     *
     * @param sudoswapPairFactory_ address of the SudoswapPairFactory to use for creating new pairs
     */
    constructor(address sudoswapPairFactory_, address renderer) {
        _sudoswapPairFactory = sudoswapPairFactory_;
        _upshotPool = new UpshotPool();
        _lpNft = new LpPosition(renderer);
        _setAdmin(msg.sender);
    }

    /**
     * @notice set a new SudoswapPairFactory to use for creating new pairs
     *
     * @param sudoswapPairFactory_ address of the SudoswapPairFactory to use for creating new pairs
     */
    function setFactoryPair(address sudoswapPairFactory_) external onlyAdmin {
        _sudoswapPairFactory = sudoswapPairFactory_;
    }

    /** 
     * @notice Create an Upshot Pool, transfer the NFT(s) and eth to the pool.
     * 
     * @dev User required to approve this smartcontract, so
     * that it can transfer 'tokenIdList' to the clone, which we won't know
     * the address of until it's created.
     * Then execute the function on {UpshotPool} that transfers the tokens
     * it _itself_, so that it can initialize a new pair which becomes
     * the ultimate holder of the NFT(s).
     *
     * @param params_ CreatePairParamsEth struct - see CreatePairParams.sol
     * @return upshotPool address of new upshotPool
     * @return sudoswapPair address of new sudoswapPair if liquidity is deposited together when creating the pool
     * @return lpPositionTokenId tokenId of the lpPosition if liquidity is deposited together when creating the pool
     */
    function createUpshotPoolEth(
        CreatePairParamsEth calldata params_
    ) external payable returns (
        IUpshotPool upshotPool, 
        address sudoswapPair, 
        uint256 lpPositionTokenId
    ) {
        return createUpshotPoolEthWithPermitter(params_, address(0));
    }

    function createUpshotPoolEthWithPermitter(
        CreatePairParamsEth calldata params_,
        address permitter_
    ) public payable returns (
        IUpshotPool upshotPool, 
        address sudoswapPair, 
        uint256 lpPositionTokenId
    ) {
        address payable poolClone = payable(_createClone(address(_upshotPool)));
        sudoswapPair = address(0);
        lpPositionTokenId = 0;

        emit UpshotPoolCreated(poolClone);

        upshotPool = IUpshotPool(poolClone);

        _lpNft.setApprovedUpshotPool(poolClone, params_.nft);

        UpshotPool(poolClone).initPoolEth(params_, _sudoswapPairFactory, _lpNft, permitter_);

        bool areNftsToAdd = params_.tokenIdList.length != 0;

        if(msg.value != 0 || areNftsToAdd)  {
            if (areNftsToAdd) {
                _transferNfts(IERC721(params_.nft), params_.owner, address(this), params_.tokenIdList);
                IERC721(params_.nft).setApprovalForAll(poolClone, true);
            }

            (sudoswapPair, lpPositionTokenId) = 
                UpshotPool(poolClone).addLiquidityEth{value: msg.value}(params_.tokenIdList, params_.owner);

            if (areNftsToAdd) IERC721(params_.nft).setApprovalForAll(poolClone, false);
        }

        // TODO ensure that the lp position ownership goes to the right place
    }

    /** 
     * @notice Create an Upshot Pool, transfer the NFT(s) and ERC20 to the pool.
     * 
     * @dev User required to approve this smartcontract, so
     * that it can transfer 'tokenIdList' to the clone, which we won't know
     * the address of until it's created.
     * Then execute the function on {UpshotPool} that transfers the tokens
     * it _itself_, so that it can initialize a new pair which becomes
     * the ultimate holder of the NFT(s).
     * 
     * The same token forwarding flow happens with the ERC20 tokens for the pool.
     * so the ERC20 token will need an approval set before calling this function.
     * 
     * @param params_ CreatePairParamsErc20 struct - see CreatePairParams.sol
     * @return upshotPool address of new upshotPool
     * @return sudoswapPair address of new sudoswapPair if liquidity is deposited together when creating the pool
     * @return lpPositionTokenId tokenId of the lpPosition if liquidity is deposited together when creating the pool
     */
    function createUpshotPoolErc20(
        CreatePairParamsErc20 calldata params_
    ) external returns (
        IUpshotPool upshotPool,
        address sudoswapPair,
        uint256 lpPositionTokenId
    ) {
        return createUpshotPoolErc20WithPermitter(params_, address(0));
    }

    function createUpshotPoolErc20WithPermitter(
        CreatePairParamsErc20 calldata params_,
        address permitter_
    ) public returns (
        IUpshotPool upshotPool,
        address sudoswapPair,
        uint256 lpPositionTokenId
    ) {
        address payable poolClone = payable(_createClone(address(_upshotPool)));
        sudoswapPair = address(0);
        lpPositionTokenId = 0;

        emit UpshotPoolCreated(poolClone);

        upshotPool = IUpshotPool(poolClone);

        _lpNft.setApprovedUpshotPool(poolClone, params_.nft);

        UpshotPool(poolClone).initPoolErc20(params_, _sudoswapPairFactory, _lpNft, permitter_);

        bool areNftsToAdd = params_.tokenIdList.length != 0;
        bool areErc20sToAdd = params_.initialTokenBalance != 0;

        if (areErc20sToAdd || areNftsToAdd) {
            if (areErc20sToAdd) {
                SafeERC20.safeTransferFrom(IERC20(params_.token), params_.owner, address(this), params_.initialTokenBalance);
                SafeERC20.safeApprove(IERC20(params_.token), poolClone, params_.initialTokenBalance);
            }
            if (areNftsToAdd) {
                _transferNfts(IERC721(params_.nft), params_.owner, address(this), params_.tokenIdList);
                IERC721(params_.nft).setApprovalForAll(poolClone, true);
            }

            (sudoswapPair, lpPositionTokenId) = 
                UpshotPool(poolClone).addLiquidityErc20(params_.tokenIdList, params_.initialTokenBalance, params_.owner);

            if (areNftsToAdd) IERC721(params_.nft).setApprovalForAll(poolClone, false);
        }

        // TODO ensure that the lp position ownership goes to the right place
    }

    /**
     * @notice Transfer the NFTs to the clone, so that it can create the factory which will send them to the pair.
     *
     * @param nft_ address of the NFT collection
     * @param from_ address to transfer from
     * @param to_ address to transfer to
     * @param tokenIdList_ array of token IDs for the NFT to transfer
     */
    function _transferNfts(IERC721 nft_, address from_, address to_, uint256[] calldata tokenIdList_) private {
        for (uint256 i = 0; i < tokenIdList_.length; ) {
            uint256 tokenId = tokenIdList_[i];
            nft_.transferFrom(from_, to_, tokenId);
            unchecked { ++i; }
        }
    }

    /**
     * @notice Creates clone of the UpshotPool contract, sharing business logic from the original,
     * but with its own storage.
     *
     * @param target address of the contract to clone.
     */
    function _createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

    function admin() external view returns (address) {
        return _admin;
    }

    /**
     * @notice no valid reason to send the factory ETH
     */
    receive() external payable {
        revert("UpshotFactory: no fallback function");
    }

    /**
     * @notice returns the sudoswap pair factory used to create new pairs for this pool
     */
    function factory() external view returns (address factory_) {
        return _sudoswapPairFactory;
    }

    /**
     * @notice returns the address of the single source of truth nft that all the liquidity 
     * position nfts are minted from
     */
    function lpPosition() external view returns (LpPosition lpPosition_) {
        return _lpNft;
    }
}

contract UpshotPool is IUpshotPool, AdminTwoStep {

    event PoolInitialized(
        address creator, 
        PoolType poolType,
        uint128 delta,
        uint96 fee,
        uint128 spotPrice,
        address bondingCurve
    );
    event PairCreated(address pair_);
    event LiquidityAdded(address pair_);

    event SpotPriceUpdate(uint128 newSpotPrice);
    event DeltaUpdate(uint128 newDelta);
    event FeeUpdate(uint96 newFee);

    UpshotPoolFactory public immutable _upshotPoolFactory;
    LpPosition public _lpNft;
    address public _permitter;

    bool private _initialized;
    IERC20 private _token;

    PoolType private _poolType;
    IERC721 private _nft;
    address private _sudoswapPairFactory;
    address private _bondingCurve;

    uint96 private _fee;
    uint128 private _delta;
    uint128 private _spotPrice;

    /***************************************************
     * ====== Administration and Access control ====== *
     ***************************************************/

    /**
     * @notice Constructor that creates the contract
     */
    constructor () {
        _upshotPoolFactory = UpshotPoolFactory(payable(msg.sender));
    }

    /**
     * @notice modifier to restrict access to the admin or a pair
     */
    modifier onlyAdminOrPair() {
        require(
            msg.sender == _admin || _lpNft.getTokenIdForPair(msg.sender) != 0, 
            "UpshotPool: not admin or pair");
        _;
    }

    function _onlyPermitter(address candidate) internal view {
        address _permitter_ = _permitter;
        require(
            _permitter_ == address(0) || 
            candidate == _permitter_ ||
            candidate == address(_upshotPoolFactory), 'UpshotPool: not permitter');
    }

    /**
     * @notice modifier to restrict access to the admin or a pair
     */
    modifier onlyPermitter() {
        _onlyPermitter(msg.sender);
        _;
    }

    /**
     * @notice modifier to restrict access to upshotPoolFactory
     */
    modifier onlyUpshotPoolFactory() {
        require(msg.sender == address(_upshotPoolFactory), "UpshotPool: not upshot pool factory");
        _;
    }

    /***************************************************
     * === Functions to Create new UpshotSwap Pools == *
     ***************************************************/
    /// Note these functions are called by the upshotPoolFactory NOT the end user

    /**
     * TODO: Determine if we want a return value here
     * TODO: what are the gas implication of struct vs individual params?
     * 
     * @notice Sets the parameters of the pool and instantiates the initial pair. 
     */
    function initPoolEth(
        CreatePairParamsEth calldata params,
        address sudoswapPairFactory_,
        LpPosition lpNft_,
        address permitter_
    ) external onlyUpshotPoolFactory {
        require(!_initialized, "UpshotPool: already initialized");
        _initialized = true;

        _nft = IERC721(params.nft);
        _sudoswapPairFactory = sudoswapPairFactory_;
        _lpNft = lpNft_;
        _permitter = permitter_;

        _fee = params.fee;
        _delta = params.delta;
        _poolType = PoolType(params.poolType);
        _spotPrice = params.spotPrice;
        _bondingCurve = params.bondingCurve;
        _setAdmin(params.owner);

        // So that the sudoswap factory can transfer tokens from this contract
        IERC721(_nft).setApprovalForAll(_sudoswapPairFactory, true);

        emit PoolInitialized(params.owner, _poolType, _delta, _fee, _spotPrice, _bondingCurve);
    }

    /**
     * TODO: Determine if we want a return value here
     *
     * @notice Sets the parameters of the pool and instantiates the initial pair. 
     */
    function initPoolErc20(
        CreatePairParamsErc20 calldata params,
        address sudoswapPairFactory_,
        LpPosition lpNft_,
        address permitter_
    ) external onlyUpshotPoolFactory {
        require(!_initialized, "UpshotPool: already initialized");
        _initialized = true;

        _nft = IERC721(params.nft);
        _token = IERC20(params.token);
        _sudoswapPairFactory = sudoswapPairFactory_;
        _lpNft = lpNft_;
        _permitter = permitter_;

        _fee = params.fee;
        _delta = params.delta;
        _poolType = PoolType(params.poolType);
        _spotPrice = params.spotPrice;
        _bondingCurve = params.bondingCurve;
        _setAdmin(params.owner);

        // So that the sudoswap factory can transfer tokens from this contract
        IERC721(_nft).setApprovalForAll(_sudoswapPairFactory, true);
        SafeERC20.safeApprove(_token, _sudoswapPairFactory, type(uint256).max);

        //TODO: switch initialTokenBalance to actual BalanceOf on ERC20
        emit PoolInitialized(params.owner, _poolType, params.delta, params.fee, params.spotPrice, params.bondingCurve);
    }

     /***************************************************
     * === DEPOSITING Liquidity into the protocol ==== *
     ***************************************************
     ***************************************************
     * === Functions to Create new Sudoswap Pairs ==== *
     ***************************************************/
    /// Note these functions CAN be called by the end user to create new liquidity positions with the UpshotPool
    /**
     * @notice Creates a new liquidity position with this UpshotSwap pool. In doing so, creates a new sudoswap pair.
     * 
     * Trade pools can't set asset recipient, and 
     * only Trade Pools can have a non-zero fee
     */
    function addLiquidityEth(
        uint256[] calldata tokenIdList_, 
        address lpPositionRecipient
    ) external payable onlyPermitter returns (address pair, uint256 lpPositionTokenId) { 
        _transferNfts(msg.sender, address(this), tokenIdList_);

        pair = ILSSVMPairFactory(_sudoswapPairFactory).createPairETH{value: msg.value}(
            address(_nft),
            _bondingCurve,
            payable(address(0)),
            _poolType,
            _delta,
            _fee,
            _spotPrice,
            tokenIdList_
        );

        if (PoolType(_poolType) != PoolType.TRADE) {
            LSSVMPair(pair).changeAssetRecipient(payable(pair));
        }

        lpPositionTokenId = _lpNft.mint(lpPositionRecipient, pair);

        emit PairCreated(pair);

        return (pair, lpPositionTokenId);
    }

    /**
     * @notice Creates a new liquidity position with this UpshotSwap pool. In doing so, creates a new sudoswap pair.
     * 
     * Trade pools can't set asset recipient, and 
     * only Trade Pools can have a non-zero fee
     */
    function addLiquidityErc20(
        uint256[] calldata tokenIdList_,
        uint256 initialTokenBalance, 
        address lpPositionRecipient
    ) external onlyPermitter returns (address pair, uint256 lpPositionTokenId) { 
        _transferNfts(msg.sender, address(this), tokenIdList_);
        SafeERC20.safeTransferFrom(_token, msg.sender, address(this), initialTokenBalance);

        CreatePairParamsErc20 memory params = CreatePairParamsErc20(
            address(_token),
            address(_nft),
            _bondingCurve,
            payable(address(0)),
            _poolType,
            _delta,
            _fee,
            _spotPrice,
            tokenIdList_,
            initialTokenBalance
        );
        pair = ILSSVMPairFactory(_sudoswapPairFactory).createPairERC20(params);

        if (PoolType(_poolType) != PoolType.TRADE) {
            LSSVMPair(pair).changeAssetRecipient(payable(pair));
        }
        
        lpPositionTokenId = _lpNft.mint(lpPositionRecipient, pair);

        emit PairCreated(pair);

        return (pair, lpPositionTokenId);
    }

    /***************************************************
     * === DEPOSITING Liquidity into the protocol ==== *
     ***************************************************
     ***************************************************
     * === Modifying existing liquidity positions ==== *
     ***************************************************/

    /**
     * @notice Allows user to add liquidity to an existing LP position. 
     * this function will DESTROY the existing LP position and mint a new one to the user
     */
    function addLiquidityEthToExisting(
        uint256[] calldata tokenIdList_, 
        uint256 lpPositionTokenId_
    ) external payable onlyPermitter returns (uint256 newLpPositionTokenId_) {
        require(_lpNft.ownerOf(lpPositionTokenId_) == msg.sender, "UpshotPool: msg.sender not LP Position owner");

        address pair = _lpNft.getPairForTokenId(lpPositionTokenId_);
        require(pair != address(0), "UpshotPool: LP Position not found");

        _lpNft.burn(lpPositionTokenId_);

        _transferNfts(msg.sender, pair, tokenIdList_);
        _transferEth(pair, msg.value);

        newLpPositionTokenId_ = _lpNft.mint(msg.sender, pair);

        emit LiquidityAdded(msg.sender);
    }

    /** 
     * @notice Allows user to add liquidity to an existing LP position. 
     * this function will DESTROY the existing LP position and mint a new one to the user
     */
    function addLiquidityErc20ToExisting(
        uint256[] calldata tokenIdList_, 
        uint256 countERC20_, 
        uint256 lpPositionTokenId_
    ) external onlyPermitter returns (uint256 newLpPositionTokenId_) {
        require(_lpNft.ownerOf(lpPositionTokenId_) == msg.sender, "UpshotPool: msg.sender not LP Position owner");

        address pair = _lpNft.getPairForTokenId(lpPositionTokenId_);
        require(pair != address(0), "UpshotPool: LP Position not found");

        _lpNft.burn(lpPositionTokenId_);

        _transferNfts(msg.sender, pair, tokenIdList_);
        SafeERC20.safeTransferFrom(_token, msg.sender, pair, countERC20_);

        newLpPositionTokenId_ = _lpNft.mint(msg.sender, pair);

        emit LiquidityAdded(msg.sender);
    }

   /***************************************************
     * ==== REMOVING Liquidity from the protocol ===== *
     ***************************************************
     ***************************************************
     * === Modifying existing liquidity positions ==== *
     ***************************************************/
    /**
     * @notice Allows user to remove liquidity from an existing ETH LP position. 
     * this function will DESTROY the existing LP position and mint a new one to the user
     */
    function pullLiquidityEth(
        uint256[] calldata tokenIdList_, 
        uint256 valueInWei_, 
        uint256 lpPositionTokenId_
    ) external onlyPermitter returns (uint newTokenId_) {
        require(_lpNft.ownerOf(lpPositionTokenId_) == msg.sender, "UpshotPool: msg.sender not LP Position owner");
        address pair = _lpNft.getPairForTokenId(lpPositionTokenId_);
        require(pair != address(0), "UpshotPool: LP Position not found");

        if (tokenIdList_.length > 0) {
            ILSSVMPair(pair).withdrawERC721(address(_nft), tokenIdList_);
            _transferNfts(address(this), msg.sender, tokenIdList_);
        }
        if (valueInWei_ > 0) {
            ILSSVMPair(pair).withdrawETH(valueInWei_);
            _transferEth(msg.sender, valueInWei_);
        }

        _lpNft.burn(lpPositionTokenId_);

        if (_ethPairHasValue(pair)) newTokenId_ = _lpNft.mint(msg.sender, pair);

        // TODO emit event
    }

    /**
     * @notice Allows user to remove liquidity from an existing ERC20 LP position. 
     * this function will DESTROY the existing LP position and mint a new one to the user
     */
    function pullLiquidityErc20(
        uint256[] calldata tokenIdList_, 
        uint256 countERC20_, 
        uint256 lpPositionTokenId_
    ) external onlyPermitter returns (uint newTokenId_) {
        require(_lpNft.ownerOf(lpPositionTokenId_) == msg.sender, "UpshotPool: msg.sender not LP Position owner");
        address pair = _lpNft.getPairForTokenId(lpPositionTokenId_);
        require(pair != address(0), "UpshotPool: LP Position not found");

        if (tokenIdList_.length > 0) {
            ILSSVMPair(pair).withdrawERC721(address(_nft), tokenIdList_);
            _transferNfts(address(this), msg.sender, tokenIdList_);
        }
        if (countERC20_ > 0) {
            ILSSVMPair(pair).withdrawERC20(address(_token), countERC20_);
            SafeERC20.safeTransfer(_token, msg.sender, countERC20_);
        }

        _lpNft.burn(lpPositionTokenId_);

        if (_erc20PairHasValue(pair)) newTokenId_ = _lpNft.mint(msg.sender, pair);

        // TODO emit event
    }

    /*****************************************************
     * ============== Helper Functions ================= *
     *****************************************************/

    /**
     * @notice internal helper function that transfers a list of NFTs from a sender to a recipient
     */
    function _transferNfts(address from_, address to_, uint256[] calldata tokenIdList_) private {
        for (uint256 i = 0; i < tokenIdList_.length; ) {
            _nft.transferFrom(from_, to_, tokenIdList_[i]);
            unchecked { ++i; }
        }      
    }

    function _transferEth(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'Transfer Eth Failed.');
    }

    function _ethPairHasValue(address pair_) private view returns (bool) {
        return pair_.balance > 0 || LSSVMPair(pair_).getAllHeldIds().length > 0;
    }

    function _erc20PairHasValue(address pair_) private view returns (bool) {
        return _token.balanceOf(pair_) > 0 || LSSVMPair(pair_).getAllHeldIds().length > 0;
    }

    /*****************************************************
     * =========== TRADING WITH THE PROTOCOL =========== *
     *****************************************************/
    function updateLpPositionMetadataOnTrade() external {
        uint256 tokenId = _lpNft.getTokenIdForPair(msg.sender);
        require(tokenId != 0, "UpshotPool: msg.sender is not a pair");
        _lpNft.emitMetadataUpdate(tokenId);
    }

    /*****************************************************
     * ===================== View ====================== *
     *****************************************************/

    /**
     * @notice returns the status of whether this contract has been initialized
     * see factory clone paradigm
     * 
     * @return initialized whether the contract has been initialized
     */
    function initialized() external view returns (bool) {
        return _initialized;
    }

    /**
     * @notice returns the fee associated with trading with any pair of this pool
     */
    function fee() external view returns (uint96 fee_) {
        return _fee;
    }
    
    /**
     * @notice returns the delta parameter for 
     * the bonding curve associated with the pairs of this pool
     * see sudoswap documentation for details on bonding curves
     */
    function delta() external view returns (uint128 delta_) {
        return _delta;
    }
    
    /**
     * @notice returns the spot price to purchase the next NFT from any pair of this pool
     */
    function spotPrice() external view returns (uint128 spotPrice_) {
        return _spotPrice;
    }

    /**
     * @notice returns the sudoswap pair factory used to create new pairs for this pool
     */
    function sudoSwapPairFactory() external view returns (address factory_) {
        return _sudoswapPairFactory;
    }

    /**
     * @notice returns the upshot factory for the contract
     */
    function upshotPoolFactory() external view returns (address) {
        return address(_upshotPoolFactory);
    }

    /**
     * @notice returns the LP Position NFT collection for this pool
     */
    function getLpPositionCollection() external view returns (address) {
        return address(_lpNft);
    }

    /**
     * @notice convienence function to get the pair from the LP position collection for you
     */
    function getPairForTokenId(uint256 tokenId_) external view returns (address pair) {
        return _lpNft.getPairForTokenId(tokenId_);
    }

    /**
     * @notice returns the price bonding curve for the next NFT in this pool
     * see sudoswap documentation for details on bonding curves
     */
    function bondingCurve() public view returns (ICurve bondingCurve_) {
        return ICurve(_bondingCurve);
    }

    /**
     * @notice returns the nft collection that this pool trades
     */
    function nft() external view returns (IERC721 nft_) {
        return _nft;
    }

    function admin() external view returns (address) {
        return _admin;
    }

    /**
     * @notice returns the ERC20 token that this pool trades with
     * If this is the zero address, then this pool trades with ETH
     */
    function token() external view returns (IERC20 token_) {
        return _token;
    }

    /**
     * @notice returns the poolType for pairs of this pool
     * See sudoswap documentation for details on pool types
     */
    function poolType() public view returns (PoolType) {
        return _poolType;
    }

    /**
     * @notice returns the permitter 
     */
    function permitter() public view returns (address) {
        return _permitter;
    }

    function enforceOnlyPermitter(address candidate) public view {
        _onlyPermitter(candidate);
    }

    /***************************************************
     * ========== Receiving tokens or ETH ============ *
     ***************************************************/
    /**
     * TODO: is there a way to prevent people from 
     * transferring ERC20s to this address?
     */

    /**
     * @notice recieve ether function. necessary because sudoswap sends first to this contract
     * before being forwarded to the end user in the pullLiquidity functions
     */
    receive() external payable {}

    /**
     * @notice recieve NFT function. necessary because sudoswap sends first to this contract
     * before being forwarded to the end user in the pullLiquidity functions
     */
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return 0x150b7a02;
    }

    /***************************************************
     * ============== Config Options ================= *
     ***************************************************/

    /**
     * @notice Change the spot price charged to buy an NFT from the pair
     */
    function changeSpotPrice(uint128 newSpotPrice) external onlyAdminOrPair {
        require(
            bondingCurve().validateSpotPrice(newSpotPrice),
            "UpshotPool: Invalid new spot price for curve"
        );
        if (_spotPrice != newSpotPrice) {
            _spotPrice = newSpotPrice;
            if (msg.sender == _admin) {
                emit SpotPriceUpdate(newSpotPrice);
            }
        }
    }

    /**
     * @notice Change the delta parameter associated with the bonding curve
     * see the sudoswap documentation on bonding curves for additional information
     */
    function changeDelta(uint128 newDelta) external onlyAdminOrPair {
        require(
            bondingCurve().validateDelta(newDelta),
            "UpshotPool: invalid delta for curve"
        );
        if (_delta != newDelta) {
            _delta = newDelta;
            if (msg.sender == _admin) {
                emit DeltaUpdate(newDelta);
            }
        }
    }

    /**
     * @notice Change the pair's fee charged by the pair for trades with it
     */
    function changeFee(uint96 newFee) external onlyAdminOrPair {
        require(poolType() == PoolType.TRADE, "UpshotPool: only for Trade pools");
        require(newFee < 0.90e18, "UpshotPool: fee must be less than 90%");
        if (_fee != newFee) {
            _fee = newFee;
            if (msg.sender == _admin) {
                emit FeeUpdate(newFee);
            }
        }
    }

}