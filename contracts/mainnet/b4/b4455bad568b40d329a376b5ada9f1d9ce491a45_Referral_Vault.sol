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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../utils/Ownable.sol";

interface RefContract is IERC721 {
    function mint(string calldata code, address recipient)
        external
        returns (uint256);

    function getCodeFromId(uint256 id) external view returns (string memory);

    function getIdFromCode(string memory code)
        external
        view
        returns (uint256 id);
}

interface IOracleWrapper {
    function getValue(uint256 amount) external view returns (uint256);
}

/// @notice Referral_Vault
/// @notice Every NFT can be a Child and a parent.
/// @notice nfts have a volume and generic market data attached to them, gets populated as 'deposit' gets called from games
/// @notice a tier is based on the market data of a token (i.e volume), tiers are created by 'owner' and ranked by id.
/// @notice the tier determines how much of a cut the nft gets 'getReferralShare'.
/// @notice each parent nft can decide how much of the tier delta gets shared to the child nft. (child tier, 10bp , parent tier 50bp, delta = 40)
/// @notice parents can remove children under them, child nfts can run away from parents.
/// @notice child nfts can set their parent.
abstract contract ReferralFamily {
    RefContract public refContract;
    event ChildDisowned(uint256 childId, uint256 parentId);
    event ChildAdoptedBy(uint256 childId, uint256 parentId);
    mapping(uint256 => uint256) public ChildToParent;

    function registerParent(uint256 childId, uint256 parentId) external {
        require(
            refContract.ownerOf(childId) == msg.sender,
            "Not referral owner"
        );
        string memory parentCode = refContract.getCodeFromId(parentId);
        require(bytes(parentCode).length != 0, "parent invalid");

        _registerParent(childId, parentId);
    }

    function _registerParent(uint256 childId, uint256 parentId) internal {
        ChildToParent[childId] = parentId;
        emit ChildAdoptedBy(childId, parentId);
    }

    function mintChild(string calldata code, uint256 parentId) external {
        string memory parentCode = refContract.getCodeFromId(parentId);
        require(bytes(parentCode).length != 0, "parent invalid");
        //.mint checks internally if code is taken, so we mint to msg.sender
        uint256 childId = refContract.mint(code, msg.sender);

        _registerParent(childId, parentId);
    }

    // Helper for Linking & Un-Linking //

    function _disownChild(uint256 childId, uint256 parentId) internal {
        require(refContract.ownerOf(parentId) == msg.sender, "not owner");

        //check if child is getting kidnapped
        require(ChildToParent[childId] == parentId, "not parent");

        //register parent to 0 for childId
        _registerParent(childId, 0);

        emit ChildDisowned(childId, parentId);
    }

    function disownChild(uint256 childId, uint256 parentId) external {
        return _disownChild(childId, parentId);
    }

    function disownChild(string calldata childCode, string calldata parentCode)
        external
    {
        uint256 parentId = refContract.getIdFromCode(parentCode);
        uint256 childId = refContract.getIdFromCode(childCode);
        _disownChild(childId, parentId);
    }

    function findParents(string calldata childCode, string calldata parentCode)
        external
    {
        uint256 parentId = refContract.getIdFromCode(parentCode);
        uint256 childId = refContract.getIdFromCode(childCode);

        // check if child is there out of own will
        require(refContract.ownerOf(childId) == msg.sender, "not owner of nft");
        require(parentId != 0, "parent not existing");

        // child becomes part of family
        _registerParent(childId, parentId);
    }

    function _runAway(uint256 childId) internal {
        require(refContract.ownerOf(childId) == msg.sender, "not owner of nft");

        // child ends up on the streets of defi
        _registerParent(childId, 0);
    }

    function runAway(uint256 nftId) external {
        _runAway(nftId);
    }

    function runAway(string calldata code) external {
        uint256 nftId = refContract.getIdFromCode(code);
        _runAway(nftId);
    }
}

abstract contract ReferralEvents {
    event OracleAdded(address token, address oracle);
    event EpochConfigUpdate(uint256 startTime, uint256 length);
    event AdvanceEpoch(uint256 nftId, uint256 epoch);
    event UpdateVolume(
        uint256 nftId,
        address Token,
        uint256 addVolume,
        uint256 totalTokenVolume,
        uint256 totalVolume
    );

    event AdvanceTierUp(uint256 nftId, uint256 tierId);
    event UpdateRoyalty(uint256 nftId, uint256 Royalty, address caller);
    event TierUpdated(
        uint256 tierId,
        string name,
        uint256 tierShare,
        uint256 volumeRequirement
    );

    event Claim(address Token, uint256 Amount);

    event Deposit(address player, address token, uint256 amount, uint256 nftId);
    event DistributeRoyalties(
        uint256 childNftId,
        uint256 parentNftId,
        address token,
        uint256 totalAmount,
        uint256 childAmount,
        uint256 parentAmount
    );
    event Distribute(uint256 nftId, address token, uint256 amount);
}

contract Referral_Vault is ReferralEvents, ReferralFamily, Ownable {
    using SafeERC20 for IERC20;
    uint256 public epochLength = 30 days;
    uint256 public epochStart;
    uint256 public tierCount = 0;

    // oracles
    mapping(address => IOracleWrapper) TokenToOracle;

    mapping(address => bool) GameWhitelist;
    mapping(address => uint256) public lastUsedCodes;

    // Tiers
    struct Tiers {
        uint256 TierId;
        string Name;
        uint256 TierShare;
        uint256 VolumeRequirement;
    }
    mapping(uint256 => Tiers) TiersById;

    // NFT Specific
    struct Metadata {
        uint256 Royalty;
        mapping(uint256 => uint256) TierIdPerEpoch;
        mapping(uint256 => uint256) VolumePerEpoch;
        mapping(address => mapping(uint256 => uint256)) TokenToVolume; // Per Epoch
        mapping(address => uint256) TokenToBalance;
    }
    mapping(uint256 => Metadata) NftMetadata;

    constructor(address _refContract) {
        refContract = RefContract(_refContract);
        epochStart = block.timestamp;
    }

    function epoch() public view returns (uint256) {
        return (block.timestamp - epochStart) / uint256(epochLength);
    }

    // Logic
    function deposit(
        uint256 amount,
        address player,
        address token,
        uint256 nftId
    ) external {
        require(GameWhitelist[msg.sender] == true, "Not game or inactive");
        if (nftId == 0) {
            // no nftId, no share
            return;
        }
        //check if epoch has started and parent exists, otherwise just distribute normally
        if ((ChildToParent[nftId] != 0) && (epochStart < block.timestamp)) {
            uint256 parentNftId = ChildToParent[nftId];

            Metadata storage childMetadata = NftMetadata[nftId];
            Metadata storage parentMetadata = NftMetadata[parentNftId];
            uint256 e = epoch();

            uint256 childBoost = TiersById[childMetadata.TierIdPerEpoch[e]]
                .TierShare;

            uint256 parentBoost = TiersById[parentMetadata.TierIdPerEpoch[e]]
                .TierShare;

            (uint256 childAmount, uint256 parentAmount) = _calculateBoost(
                childBoost,
                parentBoost,
                parentMetadata.Royalty,
                amount
            );

            childMetadata.TokenToBalance[token] += childAmount;
            parentMetadata.TokenToBalance[token] += parentAmount;

            emit DistributeRoyalties(
                nftId,
                parentNftId,
                token,
                amount,
                childAmount,
                parentAmount
            );
        } else {
            NftMetadata[nftId].TokenToBalance[token] += amount;
            emit Distribute(nftId, token, amount);
        }

        /*
		// refactored
		uint256 volume = volumeFromOracle(token, amount);
        ///only update volume if it actually exists
        if (volume > 0) {
            _updateVolume(nftId, token, volume);
        }
		
		*/
        ////check if tier can be updated
        _checkTierUpgrade(nftId);

        //actually transfer coins to vault
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(player, token, amount, nftId);
    }

    function updateVolume(
        address player,
        uint256 nftId,
        address token,
        uint256 amount
    ) public {
        if (nftId == 0 || (GameWhitelist[msg.sender] == false)) {
            // no nftId, no volume
            return;
        }
        lastUsedCodes[player] = nftId;
        uint256 volume = volumeFromOracle(token, amount);
        ///only update volume if it actually exists
        if (volume > 0) {
            _updateVolume(nftId, token, volume);
        }
    }

    function claim(address token, uint256 nftId) external {
        require(refContract.ownerOf(nftId) == msg.sender, "Not owner");

        Metadata storage md = NftMetadata[nftId];
        uint256 balance = md.TokenToBalance[token];
        md.TokenToBalance[token] -= balance;

        if (balance > IERC20(token).balanceOf(address(this))) {
            balance = IERC20(token).balanceOf(address(this));
        }
        IERC20(token).transfer(msg.sender, balance);
        /* _safeTransfer(token, address(this), msg.sender, balance);*/
        emit Claim(token, balance);
    }

    function getReferralShare(uint256 nftId) external view returns (uint256) {
        uint256 _epoch = epoch();
        uint256 childTierId = NftMetadata[nftId].TierIdPerEpoch[_epoch];
        uint256 parentTierId = NftMetadata[ChildToParent[nftId]].TierIdPerEpoch[
            _epoch
        ];

        //if child tier is higher than parent, ignore parent
        if (childTierId >= parentTierId) {
            return TiersById[childTierId].TierShare;
        }
        return TiersById[parentTierId].TierShare;
    }

    function _calculateBoost(
        uint256 childBoost,
        uint256 parentBoost,
        uint256 royalty,
        uint256 rootAmount
    ) internal pure returns (uint256, uint256) {
        if (childBoost >= parentBoost) return (rootAmount, 0);

        uint256 parentAmount = ((rootAmount -
            (rootAmount * ((childBoost * 100_00) / parentBoost)) /
            100_00) * (100_00 - royalty)) / 100_00;

        uint256 childAmount = rootAmount - parentAmount;
        return (childAmount, parentAmount);
    }

    // Internal //

    function _updateVolume(
        uint256 nftId,
        address token,
        uint256 volume
    ) internal {
        uint256 _epoch = epoch();

        NftMetadata[nftId].VolumePerEpoch[_epoch] += volume;
        NftMetadata[nftId].TokenToVolume[token][_epoch] += volume;

        emit UpdateVolume(
            nftId,
            token,
            volume,
            NftMetadata[nftId].TokenToVolume[token][_epoch],
            NftMetadata[nftId].VolumePerEpoch[_epoch]
        );
    }

    function _checkTierUpgrade(uint256 nftId) internal {
        uint256 _epoch = epoch();
        Metadata storage md = NftMetadata[nftId];

        uint256 tierId = md.TierIdPerEpoch[_epoch];
        //check if next tier exists
        if ((tierId + 1) <= tierCount) {
            uint256 nextTierVolumeRequirements = TiersById[tierId + 1]
                .VolumeRequirement;

            //check if can lvl up one tier
            if (md.VolumePerEpoch[_epoch] >= nextTierVolumeRequirements) {
                NftMetadata[nftId].TierIdPerEpoch[_epoch] += 1;

                emit AdvanceTierUp(nftId, tierId + 1);
            }
        }
    }

    function getCodeId(string memory code, address player)
        external
        view
        returns (uint256)
    {
        uint256 nftId = refContract.getIdFromCode(code);

        //lastUsedCodes[player] is 0 if he never used a code before.
        return nftId != 0 ? nftId : lastUsedCodes[player];
    }

    // Logic
    // nft owner can decide the royalty
    // define how much of the detla goes back to the parent.
    // 100_00 = everything goes to parent; child keeps his own tierShare and remainer goes to parent
    // 0 = child gets everything, parent gets 0
    function setRoyalty(uint256 nftId, uint256 royalty) external {
        require(refContract.ownerOf(nftId) == msg.sender, "not owner");
        require(royalty <= 100_00 && royalty >= 0, "invalid royalty range");

        NftMetadata[nftId].Royalty = royalty;
        emit UpdateRoyalty(nftId, royalty, msg.sender);
    }

    // View Functions //
    function volumeFromOracle(address token, uint256 amount)
        public
        view
        returns (uint256)
    {
        IOracleWrapper oracle = TokenToOracle[token];
        if (address(oracle) == address(0)) return 0;
        return oracle.getValue(amount);
    }

    function viewMetadataTokenBalance(uint256 nftId, address token)
        external
        view
        returns (uint256)
    {
        Metadata storage md = NftMetadata[nftId];
        return md.TokenToBalance[token];
    }

    function viewMetadataTokenVolume(
        uint256 nftId,
        address token,
        uint256 _epoch
    ) external view returns (uint256) {
        Metadata storage md = NftMetadata[nftId];
        return md.TokenToVolume[token][_epoch];
    }

    function viewMetadataTotalVolumeHistorical(uint256 nftId, uint256 _epoch)
        external
        view
        returns (uint256)
    {
        Metadata storage md = NftMetadata[nftId];
        return md.VolumePerEpoch[_epoch];
    }

    function viewMetadataTokenVolumeCurrent(uint256 nftId, address token)
        external
        view
        returns (uint256)
    {
        Metadata storage md = NftMetadata[nftId];
        return md.TokenToVolume[token][epoch()];
    }

    function viewMetadataTotalVolumeCurrent(uint256 nftId)
        external
        view
        returns (uint256)
    {
        Metadata storage md = NftMetadata[nftId];
        return md.VolumePerEpoch[epoch()];
    }

    function viewMetadataCurrentTier(uint256 nftId)
        external
        view
        returns (uint256)
    {
        Metadata storage md = NftMetadata[nftId];
        return md.TierIdPerEpoch[epoch()];
    }

    // Admin //

    function addGame(address _game, bool _isActive) external onlyOwner {
        GameWhitelist[_game] = _isActive;
    }

    function addOracle(address token, address oracle) external onlyOwner {
        TokenToOracle[token] = IOracleWrapper(oracle);
        emit OracleAdded(token, oracle);
    }

    function recoverToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function generateTier(
        uint256 tierId,
        string calldata name,
        uint256 tierShare,
        uint256 volumeRequirement
    ) external onlyOwner returns (uint256) {
        if (tierId > tierCount) {
            tierCount++;
        }

        TiersById[tierId].Name = name;
        TiersById[tierId].TierId = tierId;
        TiersById[tierId].TierShare = tierShare;
        TiersById[tierId].VolumeRequirement = volumeRequirement;

        emit TierUpdated(tierId, name, tierShare, volumeRequirement);

        return tierId;
    }

    function setEpochConfig(uint256 _epochStart, uint256 _epochLength)
        external
        onlyOwner
    {
        epochStart = _epochStart;
        epochLength = _epochLength;

        emit EpochConfigUpdate(epochStart, epochLength);
    }

    function setVolumeMetadataForEpoch(
        uint256 _nftId,
        uint256 _epochToSet,
        uint256 _volumeToSet
    ) external onlyOwner {
        Metadata storage md = NftMetadata[_nftId];
        md.VolumePerEpoch[_epochToSet] = _volumeToSet;

        for (uint256 index = 0; index < tierCount; index++) {
            if (TiersById[index].VolumeRequirement > _volumeToSet) break;
            _checkTierUpgrade(_nftId);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev basic openzeppelin implementation without _msgSender() and Context.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
}