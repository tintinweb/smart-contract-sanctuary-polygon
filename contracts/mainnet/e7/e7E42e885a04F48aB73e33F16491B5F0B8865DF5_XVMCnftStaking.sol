/**
 *Submitted for verification at polygonscan.com on 2022-06-05
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721Receiver.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: xvmc-contracts/NFT/NFTstaking.sol



pragma solidity 0.8.1;








interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function pendingEgg(uint256 _pid, address _user) external view returns (uint256);
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function emergencyWithdraw(uint256 _pid) external;
    function feeAddress() external view returns (address);
    function owner() external view returns (address);
}

interface IGovernance {
    function rebalancePools() external;
    function nftAllocationContract() external view returns (address);
    function treasuryWallet() external view returns (address);
	function nftStakingPoolID() external view returns (uint256);
}

interface IVoting {
    function addCredit(uint256 amount, address _beneficiary) external;
}

interface IacPool {
    function giftDeposit(uint256 _amount, address _toAddress, uint256 _minToServeInSecs) external;
}

interface INFTallocation {
    function getAllocation(address _tokenAddress, uint256 _tokenID, address _allocationContract) external view returns (uint256);
}

/**
 * XVMC NFT staking contract
 * !!! Warning: !!! Licensed under Business Source License 1.1 (BSL 1.1)
 */
contract XVMCnftStaking is ReentrancyGuard, ERC721Holder {
    using SafeERC20 for IERC20;

    struct UserInfo {
        address tokenAddress;
        uint256 tokenID;
        uint256 shares; // number of shares the NFT is worth in the pool
        uint256 debt; //the allocation for the NFT at the time of deposit(why named debt? idk)
        //basically debt because it counts as "artificial tokens"(we deposit a singular NFT worth an artificial amount)
        //simple substitute for using NFTs instead of regular tokens
		address allocContract; //contract that contains allocation details
    }
    struct UserSettings {
        address pool; //which pool to payout in
        uint256 harvestThreshold;
        uint256 feeToPay;
    }
    struct PoolPayout {
        uint256 amount;
        uint256 minServe;
    }

	uint256 public constant MINIMUM_ALLOCATION = 10000;
	
    IERC20 public immutable token; // XVMC token
	
	IERC20 public immutable oldToken = IERC20(0x6d0c966c8A09e354Df9C48b446A474CE3343D912);
    
    IERC20 public immutable dummyToken; 

    IMasterChef public masterchef;  

    mapping(address => UserInfo[]) public userInfo;
    mapping(address => UserSettings) public userSettings; 
    mapping(address => PoolPayout) public poolPayout; //determines the percentage received depending on withdrawal option
 
	uint256 public poolID; 
    uint256 public totalShares;
    address public admin; //admin = governing contract!
    address public treasury; //penalties
    address public allocationContract; // PROXY CONTRACT for looking up allocations

    address public votingCreditAddress;

    uint256 public tokenDebt; //sum of allocations of all deposited NFTs

    //if user settings not set, use default
    address defaultHarvest; //pool address to harvest into
    uint256 defaultHarvestThreshold = 1000000;
    uint256 defaultFeeToPay = 250; //fee for calling 2.5% default

    uint256 defaultDirectPayout = 500; //5% if withdrawn into wallet

    event Deposit(address indexed tokenAddress, uint256 indexed tokenID, address indexed depositor, uint256 shares, uint256 nftAllocation, address allocContract);
    event Withdraw(address indexed sender, uint256 stakeID, address indexed token, uint256 indexed tokenID, uint256 shares, uint256 harvestAmount);
    event UserSettingUpdate(address indexed user, address poolAddress, uint256 threshold, uint256 feeToPay);

    event AddVotingCredit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 _stakeID, address indexed token, uint256 tokenID);
    event Harvest(address indexed harvester, address indexed benficiary, address harvestInto, uint256 harvestAmount, uint256 penalty, uint256 callFee); //harvestAmount contains the callFee
    event SelfHarvest(address indexed user, address harvestInto, uint256 harvestAmount, uint256 penalty);

    /**
     * @notice Constructor
     * @param _token: XVMC token contract
     * @param _dummyToken: Dummy token contract
     * @param _masterchef: MasterChef contract
     * @param _admin: address of the admin
     * @param _treasury: address of the treasury (collects fees)
     */
    constructor(
        IERC20 _token,
        IERC20 _dummyToken,
        IMasterChef _masterchef,
        address _admin,
        address _treasury,
        uint256 _poolID,
        address _allocationContract
    ) {
        token = _token;
        dummyToken = _dummyToken;
        masterchef = _masterchef;
        admin = _admin;
        treasury = _treasury;
        poolID = _poolID;
        allocationContract = _allocationContract;

        IERC20(_dummyToken).safeApprove(address(_masterchef), type(uint256).max);
        poolPayout[0xfFB71361dD8Fc3ef0831871Ec8dd51B413ed093C].amount = 750;
        poolPayout[0xfFB71361dD8Fc3ef0831871Ec8dd51B413ed093C].minServe = 864000;

        poolPayout[0x9a9AEF66624C3fa77DaACcA9B51DE307FA09bd50].amount = 1500;
        poolPayout[0x9a9AEF66624C3fa77DaACcA9B51DE307FA09bd50].minServe = 2592000;

        poolPayout[0x1F8a5D98f1e2F10e93331D27CF22eD7985EF6a12].amount = 2500;
        poolPayout[0x1F8a5D98f1e2F10e93331D27CF22eD7985EF6a12].minServe = 5184000;

        poolPayout[0x30019481FC501aFa449781ac671103Feb0d6363C].amount = 5000;
        poolPayout[0x30019481FC501aFa449781ac671103Feb0d6363C].minServe = 8640000;

        poolPayout[0x8c96105ea574727e94d9C199c632128f1cA584cF].amount = 7000;
        poolPayout[0x8c96105ea574727e94d9C199c632128f1cA584cF].minServe = 20736000;

        poolPayout[0x605c5AA14BdBf0d50a99836e7909C631cf3C8d46].amount = 10000;
        poolPayout[0x605c5AA14BdBf0d50a99836e7909C631cf3C8d46].minServe = 31536000; 
    }
    
    /**
     * @notice Checks if the msg.sender is the admin
     */
    modifier adminOnly() {
        require(msg.sender == admin, "admin: wut?");
        _;
    }
	
    /**
     * Creates a NEW stake
     * allocationContract is the proxy
     * _allocationContract input is the actual contract containing the allocation data
     */
    function deposit(address _tokenAddress, uint256 _tokenID, address _allocationContract) external nonReentrant {
    	uint256 _allocationAmount = INFTallocation(allocationContract).getAllocation(_tokenAddress, _tokenID, _allocationContract);
        require(_allocationAmount > 0, "Invalid NFT, no allocation");
        harvest();
        uint256 pool = balanceOf();
        IERC721(_tokenAddress).safeTransferFrom(msg.sender, address(this), _tokenID);
        uint256 currentShares = 0;
        if (totalShares != 0) {
            currentShares = (_allocationAmount * totalShares) / (pool);
        } else {
			require(_allocationAmount > MINIMUM_ALLOCATION, "Minimum allocation not reached");
            currentShares = _allocationAmount;
            currentShares = currentShares - MINIMUM_ALLOCATION;
            totalShares = MINIMUM_ALLOCATION;
            userInfo[address(0)].push(
                UserInfo(address(0), 0, MINIMUM_ALLOCATION, 0, address(0))
            );

            emit Deposit(address(0), 0, address(0), MINIMUM_ALLOCATION, 0, address(0));
        }
        
        totalShares = totalShares + currentShares;
        tokenDebt = tokenDebt + _allocationAmount;
        
        userInfo[msg.sender].push(
                UserInfo(_tokenAddress, _tokenID, currentShares, _allocationAmount, _allocationContract)
            );

        emit Deposit(_tokenAddress, _tokenID, msg.sender, currentShares, _allocationAmount, _allocationContract);
    }

	
    /**
     * Harvests into pool
     */
    function harvest() public {
        IMasterChef(masterchef).withdraw(poolID, 0);
    }
  
    /**
    *
    */
    function setAdmin() external {
        admin = IMasterChef(masterchef).owner();
        treasury = IMasterChef(masterchef).feeAddress();
    }
    
    function updateAllocationContract() external {
        allocationContract = IGovernance(admin).nftAllocationContract();
		poolID = IGovernance(admin).nftStakingPoolID();
    }

    /**
     * @notice Withdraws the NFT and harvests earnings
     */
    function withdraw(uint256 _stakeID, address _harvestInto) public nonReentrant {
        harvest();
        require(_stakeID < userInfo[msg.sender].length, "invalid stake ID");
        UserInfo storage user = userInfo[msg.sender][_stakeID];

        uint256 currentAmount = (balanceOf() * (maxHarvest(user))) / (totalShares);
        totalShares = totalShares - user.shares;
        tokenDebt = tokenDebt - user.debt;

        uint256 _tokenID = user.tokenID;
		address _tokenAddress = user.tokenAddress;

		emit Withdraw(msg.sender, _stakeID, user.tokenAddress, _tokenID, user.shares, currentAmount);
		
        _removeStake(msg.sender, _stakeID); //delete the stake

        uint256 _toWithdraw;      
        if(_harvestInto == msg.sender) { 
            _toWithdraw = currentAmount * defaultDirectPayout / 10000;
            currentAmount = currentAmount - _toWithdraw;
            token.safeTransfer(msg.sender, _toWithdraw);
         } else {
            require(poolPayout[_harvestInto].amount != 0, "incorrect pool!");
            _toWithdraw = currentAmount * poolPayout[_harvestInto].amount / 10000;
            currentAmount = currentAmount - _toWithdraw;
            IacPool(_harvestInto).giftDeposit(_toWithdraw, msg.sender, poolPayout[_harvestInto].minServe);
        }
        token.safeTransfer(treasury, currentAmount); //penalty goes to governing contract

        IERC721(_tokenAddress).safeTransferFrom(address(this), msg.sender, _tokenID); //withdraw NFT
    } 

    function setUserSettings(address _poolAddress, uint256 _harvestThreshold, uint256 _feeToPay, address _harvestInto) external {
        require(_feeToPay <= 3000, "max 30%");
        if(_harvestInto != msg.sender) { require(poolPayout[_harvestInto].amount != 0, "incorrect pool!"); }
        UserSettings storage _setting = userSettings[msg.sender];
        _setting.harvestThreshold = _harvestThreshold;
        _setting.feeToPay = _feeToPay;
        _setting.pool = _harvestInto; //default pool to harvest into(or payout directly)
        emit UserSettingUpdate(msg.sender, _poolAddress, _harvestThreshold, _feeToPay);
    }

    //harvest own earnings
    //shares left MUST cover the user debt
    //_harvestInto are only trusted pools, no need for nonReentrant
    function selfHarvest(address _harvestInto) external {
        UserInfo[] storage user = userInfo[msg.sender];
		require(user.length > 0, "user has no stakes");
        harvest();
        uint256 _totalWithdraw = 0;
        uint256 _toWithdraw = 0;
        uint256 _payout = 0;
 
        for(uint256 i = 0; i<user.length; i++) {
            _toWithdraw = maxHarvest(user[i]); //SHARES
            user[i].shares = user[i].shares - _toWithdraw;
            _totalWithdraw+= _toWithdraw;
        }

        if(_harvestInto == msg.sender) {
            _toWithdraw = (balanceOf() * _totalWithdraw) / totalShares;
            _payout = _toWithdraw * defaultDirectPayout / 10000;
            token.safeTransfer(msg.sender, _payout); 
        } else {
            require(poolPayout[_harvestInto].amount != 0, "incorrect pool!");
            _toWithdraw = (balanceOf() * _totalWithdraw) / totalShares;
            _payout = _toWithdraw * poolPayout[_harvestInto].amount / 10000;
            IacPool(_harvestInto).giftDeposit(_payout, msg.sender, poolPayout[_harvestInto].minServe);
        }
        totalShares = totalShares - _totalWithdraw;
        uint256 _penalty = _toWithdraw - _payout;
        token.safeTransfer(treasury, _penalty); //penalty to treasury

        emit SelfHarvest(msg.sender, _harvestInto, _payout, _penalty);
    }
	//copy+paste of the previous function, can harvest custom stake ID
	//In case user has too many stakes, or if some are not worth harvesting
	function selfHarvestCustom(uint256[] calldata _stakeID, address _harvestInto) external {
        require(_stakeID.length <= userInfo[msg.sender].length, "incorrect Stake list");
        UserInfo[] storage user = userInfo[msg.sender];
        harvest();
        uint256 _totalWithdraw = 0;
        uint256 _toWithdraw = 0;
        uint256 _payout = 0;
 
        for(uint256 i = 0; i<_stakeID.length; i++) {
            _toWithdraw = maxHarvest(user[_stakeID[i]]); //SHARES
            user[_stakeID[i]].shares = user[_stakeID[i]].shares - _toWithdraw;
            _totalWithdraw+= _toWithdraw;
        }

        if(_harvestInto == msg.sender) {
            _toWithdraw = (balanceOf() * _totalWithdraw) / totalShares;
            _payout = _toWithdraw * defaultDirectPayout / 10000;
            token.safeTransfer(msg.sender, _payout); 
        } else {
            require(poolPayout[_harvestInto].amount != 0, "incorrect pool!");
            _toWithdraw = (balanceOf() * _totalWithdraw) / totalShares;
            _payout = _toWithdraw * poolPayout[_harvestInto].amount / 10000;
            IacPool(_harvestInto).giftDeposit(_payout, msg.sender, poolPayout[_harvestInto].minServe);
        }
        totalShares = totalShares - _totalWithdraw;
        uint256 _penalty = _toWithdraw - _payout;
        token.safeTransfer(treasury, _penalty); //penalty to treasury

        emit SelfHarvest(msg.sender, _harvestInto, _payout, _penalty);
    }

    //harvest earnings of another user(receive fees)
    function proxyHarvest(address _beneficiary) external {
        UserInfo[] storage user = userInfo[_beneficiary];
		require(user.length > 0, "user has no stakes");
        harvest();
        uint256 _totalWithdraw = 0;
        uint256 _toWithdraw = 0;
        uint256 _payout = 0;

        UserSettings storage _userSetting = userSettings[_beneficiary];

        address _harvestInto = _userSetting.pool;
        uint256 _minThreshold = _userSetting.harvestThreshold;
        uint256 _callFee = _userSetting.feeToPay;

        if(_minThreshold == 0) { _minThreshold = defaultHarvestThreshold; }
        if(_callFee == 0) { _callFee = defaultFeeToPay; }

        for(uint256 i = 0; i<user.length; i++) {
            _toWithdraw = maxHarvest(user[i]); //SHARES
            user[i].shares = user[i].shares - _toWithdraw;
            _totalWithdraw+= _toWithdraw;
        }

        if(_harvestInto == _beneficiary) {
            //fee paid to harvester
            _toWithdraw = (balanceOf() * _totalWithdraw) / totalShares;
            _payout = _toWithdraw * defaultDirectPayout / 10000;
            _callFee = _payout * _callFee / 10000;
            token.safeTransfer(msg.sender, _callFee); 
            token.safeTransfer(_beneficiary, (_payout - _callFee)); 
        } else {
            if(_harvestInto == address(0)) {
                _harvestInto = defaultHarvest; //default pool
            } //harvest Into is correct(checks if valid when user initiates the setting)
            
            _toWithdraw = (balanceOf() * _totalWithdraw) / totalShares;
            _payout = _toWithdraw * poolPayout[_harvestInto].amount / 10000;
            require(_payout > _minThreshold, "minimum threshold not met");
            _callFee = _payout * _callFee / 10000;
            token.safeTransfer(msg.sender, _callFee); 
            IacPool(_harvestInto).giftDeposit((_payout - _callFee), _beneficiary, poolPayout[_harvestInto].minServe);
        }
        totalShares = totalShares - _totalWithdraw;
        uint256 _penalty = _toWithdraw - _payout;
        token.safeTransfer(treasury, _penalty); //penalty to treasury

        emit Harvest(msg.sender, _beneficiary, _harvestInto, _payout, _penalty, _callFee);
    }

	//copy+paste of the previous function, can harvest custom stake ID
	//In case user has too many stakes, or if some are not worth harvesting
	function proxyHarvestCustom(address _beneficiary, uint256[] calldata _stakeID) external {
        require(_stakeID.length <= userInfo[_beneficiary].length, "incorrect Stake list");
        UserInfo[] storage user = userInfo[_beneficiary];
        harvest();
        uint256 _totalWithdraw = 0;
        uint256 _toWithdraw = 0;
        uint256 _payout = 0;

        UserSettings storage _userSetting = userSettings[_beneficiary];

        address _harvestInto = _userSetting.pool;
        uint256 _minThreshold = _userSetting.harvestThreshold;
        uint256 _callFee = _userSetting.feeToPay;

        if(_minThreshold == 0) { _minThreshold = defaultHarvestThreshold; }
        if(_callFee == 0) { _callFee = defaultFeeToPay; }

        for(uint256 i = 0; i<_stakeID.length; i++) {
            _toWithdraw = maxHarvest(user[_stakeID[i]]); //SHARES
            user[_stakeID[i]].shares = user[_stakeID[i]].shares - _toWithdraw;
            _totalWithdraw+= _toWithdraw;
        }

        if(_harvestInto == _beneficiary) {
            //fee paid to harvester
            _toWithdraw = (balanceOf() * _totalWithdraw) / totalShares;
            _payout = _toWithdraw * defaultDirectPayout / 10000;
            _callFee = _payout * _callFee / 10000;
            token.safeTransfer(msg.sender, _callFee); 
            token.safeTransfer(_beneficiary, (_payout - _callFee)); 
        } else {
            if(_harvestInto == address(0)) {
                _harvestInto = defaultHarvest; //default pool
            } //harvest Into is correct(checks if valid when user initiates the setting)
            
            _toWithdraw = (balanceOf() * _totalWithdraw) / totalShares;
            _payout = _toWithdraw * poolPayout[_harvestInto].amount / 10000;
            require(_payout > _minThreshold, "minimum threshold not met");
            _callFee = _payout * _callFee / 10000;
            token.safeTransfer(msg.sender, _callFee); 
            IacPool(_harvestInto).giftDeposit((_payout - _callFee), _beneficiary, poolPayout[_harvestInto].minServe);
        }
        totalShares = totalShares - _totalWithdraw;
        uint256 _penalty = _toWithdraw - _payout;
        token.safeTransfer(treasury, _penalty); //penalty to treasury
        
        emit Harvest(msg.sender, _beneficiary, _harvestInto, _payout, _penalty, _callFee);
    }

    //NOT COUNTING IN min withdraw, just based on shares
    //calculates amount of shares that cover the debt. Subtract from total to get maximum harvest amount
    function maxHarvest(UserInfo memory _user) internal view returns (uint256) {
        uint256 _maximum = (_user.debt * totalShares) / balanceOf();
        return (_user.shares - _maximum - 1);
    }
	
	function maxHarvestPublic(address _staker, uint256 _stakeID) external view returns (uint256) {
		UserInfo storage _user = userInfo[_staker][_stakeID];
		uint256 _maximum = (_user.debt * totalShares) / publicBalanceOf();
        return (_user.shares - _maximum - 1);
	}
    
    function viewStakeEarnings(address _user, uint256 _stakeID) external view returns (uint256) {
        uint256 _tokens = (balanceOf() * userInfo[_user][_stakeID].shares) / totalShares;
        return(_tokens - userInfo[_user][_stakeID].debt);
    }

    function viewUserTotalEarnings(address _user) external view returns (uint256) {
        (uint256 _userShares, uint256 _userDebt) = getUserTotals(_user);
        //convert shares into tokens and deduct debt
        uint256 _tokens = (balanceOf() * _userShares) / totalShares;
        return (_tokens - _userDebt);
    }
	
    /**
     * Ability to withdraw tokens from the stake, and add voting credit
     * At the time of launch there is no option(voting with credit), but can be added later on
    */
	function votingCredit(uint256 _shares, uint256 _stakeID) public {
        require(votingCreditAddress != address(0), "disabled");
        require(_stakeID < userInfo[msg.sender].length, "invalid stake ID");
		
		harvest();
        
        UserInfo storage user = userInfo[msg.sender][_stakeID];
        require(_shares < maxHarvest(user), "insufficient shares");

        uint256 currentAmount = (balanceOf() * (_shares)) / (totalShares);
        user.shares = user.shares - _shares;
        totalShares = totalShares - _shares;
		
        token.safeTransfer(votingCreditAddress, currentAmount);
		IVoting(votingCreditAddress).addCredit(currentAmount, msg.sender); //in the votingCreditAddress regulate how much is credited, depending on where it's coming from (msg.sender)

        emit AddVotingCredit(msg.sender, currentAmount);
    } 

	function cashoutAllToCredit() external {
        require(votingCreditAddress != address(0), "disabled");
        require(userInfo[msg.sender].length > 0, "no active stakes");
		
		harvest();

        uint256 _toWithdraw = 0;
        uint256 _totalWithdraw = 0;
        UserInfo[] storage user = userInfo[msg.sender];

        for(uint256 i=0; i<user.length; i++) {
            _toWithdraw = maxHarvest(user[i]); //SHARES
            user[i].shares = user[i].shares - _toWithdraw;
            _totalWithdraw+= _toWithdraw;
        }
        uint256 currentAmount = (balanceOf() * (_totalWithdraw)) / (totalShares);
        totalShares = totalShares - _totalWithdraw;
		
        token.safeTransfer(votingCreditAddress, currentAmount);
		IVoting(votingCreditAddress).addCredit(currentAmount, msg.sender); //in the votingCreditAddress regulate how much is credited, depending on where it's coming from (msg.sender)

        emit AddVotingCredit(msg.sender, currentAmount);
    } 

    // if allocation for the NFT changes, anyone can rebalance
	// if allocation contract is replaced(rare event), an "evil" third party can push the NFT out of the staking
	// responsibility of the owner to re-deposit (or rebalance first)
    function rebalanceNFT(address _staker, uint256 _stakeID, bool isAllocationContractReplaced, address _allocationContract) external {
		require(_stakeID < userInfo[_staker].length, "invalid stake ID");
		harvest();
        UserInfo storage user = userInfo[_staker][_stakeID];
		uint256 _alloc;
		if(isAllocationContractReplaced) {
			require(user.allocContract != _allocationContract, "must set allocation replaced setting as FALSE");
			_alloc = INFTallocation(allocationContract).getAllocation(user.tokenAddress, user.tokenID, _allocationContract);
			require(_alloc != 0, "incorrect _allocationContract");
		} else {
			_alloc = INFTallocation(allocationContract).getAllocation(user.tokenAddress, user.tokenID, user.allocContract);
		}
        if(_alloc == 0) { //no longer valid, anyone can push out and withdraw NFT to the owner (copy+paste withdraw option)
            uint256 currentAmount = (balanceOf() * (maxHarvest(user))) / (totalShares);
            totalShares = totalShares - user.shares;
            tokenDebt = tokenDebt - user.debt;

            uint256 _tokenID = user.tokenID;
			address _tokenAddress = user.tokenAddress;

            emit Withdraw(_staker, _stakeID, user.tokenAddress, _tokenID, user.shares, currentAmount);
            
            _removeStake(_staker, _stakeID); //delete the stake

            address _harvestInto = userSettings[_staker].pool;
            if(_harvestInto == address(0)) { _harvestInto = defaultHarvest; } 

            uint256 _toWithdraw;      
            if(_harvestInto == _staker) { 
                _toWithdraw = currentAmount * defaultDirectPayout / 10000;
                currentAmount = currentAmount - _toWithdraw;
                token.safeTransfer(_staker, _toWithdraw);
            } else {
                _toWithdraw = currentAmount * poolPayout[_harvestInto].amount / 10000;
                currentAmount = currentAmount - _toWithdraw;
                IacPool(_harvestInto).giftDeposit(_toWithdraw, _staker, poolPayout[_harvestInto].minServe);
            }
            token.safeTransfer(treasury, currentAmount); //penalty goes to governing contract

            IERC721(_tokenAddress).safeTransferFrom(address(this), _staker, _tokenID); //withdraw NFT
        } else if(_alloc != user.debt) { //change allocation
            uint256 _profitShares = maxHarvest(user); 
            uint256 _profitTokens = (balanceOf() * _profitShares) / totalShares;
            //artificial withdraw, then re-deposit with new allocaiton, along with profited tokens
            totalShares = totalShares - user.shares; //as if ALL shares and ALL DEBT was withdrawn (actual profit tokens remain inside!)
            tokenDebt = tokenDebt - user.debt;
            user.shares = ((_alloc+_profitTokens) * totalShares) / (balanceOf() - _profitTokens); 
            tokenDebt = tokenDebt + _alloc;
            user.debt = _alloc;
            totalShares = totalShares + user.shares;
        }
    }
	
	// emergency withdraw, without caring about rewards
	function emergencyWithdraw(uint256 _stakeID) public {
		require(_stakeID < userInfo[msg.sender].length, "invalid stake ID");
		UserInfo storage user = userInfo[msg.sender][_stakeID];
		totalShares-= user.shares;
		tokenDebt-= user.debt; 
		address _token = user.tokenAddress;
		uint256 _tokenID = user.tokenID;
		
		_removeStake(msg.sender, _stakeID); //delete the stake
        emit EmergencyWithdraw(msg.sender, _stakeID, _token, _tokenID);
		IERC721(_token).safeTransferFrom(address(this), msg.sender, _tokenID); //withdraw NFT
	}
	// withdraw all without caring about rewards
	// self-harvest to harvest rewards, then emergency withdraw all(easiest to withdraw all+earnings)
	// (non-rentrant in regular withdraw)
	function emergencyWithdrawAll() external {
		uint256 _stakeID = userInfo[msg.sender].length;
		while(_stakeID > 0) {
			_stakeID--;
			emergencyWithdraw(_stakeID);
		}
	}

    //need to set pools before launch or perhaps during contract launch
    //determines the payout depending on the pool. could set a governance process for it(determining amounts for pools)
	//allocation contract contains the decentralized proccess for updating setting, but so does the admin(governor)
    function setPoolPayout(address _poolAddress, uint256 _amount, uint256 _minServe) external {
        require(msg.sender == allocationContract || msg.sender == admin, "must be set by allocation contract or admin");
		if(_poolAddress == address(0)) {
			require(_amount <= 10000, "out of range");
			defaultDirectPayout = _amount;
		} else if (_poolAddress == address(1)) {
			defaultHarvestThreshold = _amount;
		} else if (_poolAddress == address(2)) {
			require(_amount <= 1000, "out of range"); //max 10%
			defaultFeeToPay = _amount;
		} else {
			require(_amount <= 10000, "out of range"); 
			poolPayout[_poolAddress].amount = _amount;
        	poolPayout[_poolAddress].minServe = _minServe; //mandatory lockup(else stake for 5yr, withdraw with 82% penalty and receive 18%)
		}
    }
    
    function updateSettings(address _defaultHarvest, uint256 _threshold, uint256 _defaultFee, uint256 _defaultDirectHarvest) external adminOnly {
        defaultHarvest = _defaultHarvest; //longest pool should be the default
        defaultHarvestThreshold = _threshold;
        defaultFeeToPay = _defaultFee;
        defaultDirectPayout = _defaultDirectHarvest;
    }

    function updateVotingCreditAddress(address _newAddress) external adminOnly {
        votingCreditAddress = _newAddress;
    }

    /**
     * Returns number of stakes for a user
     */
    function getNrOfStakes(address _user) public view returns (uint256) {
        return userInfo[_user].length;
    }
    
    /**
     * Returns all shares and debt for a user
     */
    function getUserTotals(address _user) public view returns (uint256, uint256) {
        UserInfo[] storage _stake = userInfo[_user];
        uint256 nrOfUserStakes = _stake.length;

		uint256 countShares = 0;
        uint256 countDebt = 0;
		
		for(uint256 i=0; i < nrOfUserStakes; i++) {
			countShares += _stake[i].shares;
            countDebt += _stake[i].debt;
		}
		
		return (countShares, countDebt);
    }
	

    /**
     * @return Returns total pending xvmc rewards
     */
    function calculateTotalPendingXVMCRewards() external view returns (uint256) {
        return(IMasterChef(masterchef).pendingEgg(poolID, address(this)));
    }

    /**
     * @notice Calculates the price per share
     */
    function getPricePerFullShare() external view returns (uint256) {
        return totalShares == 0 ? 1e18 : balanceOf() * (1e18) / (totalShares);
    }
    
    /**
     * @notice returns number of shares for a certain stake of an user
     */
    function getUserShares(address _wallet, uint256 _stakeID) public view returns (uint256) {
        return userInfo[_wallet][_stakeID].shares;
    }
	
    /**
     * calculates pending rewards + balance of tokens in this address + artificial token debt(how much each NFT is worth)
	 * we harvest before every action, pending rewards not needed
     */
    function balanceOf() internal view returns (uint256) {
        return token.balanceOf(address(this)) + tokenDebt; 
    }
	//public lookup for UI
    function publicBalanceOf() public view returns (uint256) {
        uint256 amount = IMasterChef(masterchef).pendingEgg(poolID, address(this)); 
        return token.balanceOf(address(this)) + amount + tokenDebt; 
    }
	
	/*
	 * Unlikely, but Masterchef can be changed if needed to be used without changing pools
	 * masterchef = IMasterChef(token.owner());
	 * Must stop earning first(withdraw tokens from old chef)
	*/
	function setMasterChefAddress(IMasterChef _masterchef, uint256 _newPoolID) external adminOnly {
		masterchef = _masterchef;
		poolID = _newPoolID; //in case pool ID changes
		
		uint256 _dummyAllowance = IERC20(dummyToken).allowance(address(this), address(masterchef));
		if(_dummyAllowance == 0) {
			IERC20(dummyToken).safeApprove(address(_masterchef), type(uint256).max);
		}
	}
	
    /**
     * When contract is launched, dummyToken shall be deposited to start earning rewards
     */
    function startEarning() external adminOnly {
		IMasterChef(masterchef).deposit(poolID, dummyToken.balanceOf(address(this)));
    }
	
    /**
     * Dummy token can be withdrawn if ever needed(allows for flexibility)
     */
	function stopEarning(uint256 _withdrawAmount) external adminOnly {
		if(_withdrawAmount == 0) { 
			IMasterChef(masterchef).withdraw(poolID, dummyToken.balanceOf(address(masterchef)));
		} else {
			IMasterChef(masterchef).withdraw(poolID, _withdrawAmount);
		}
	}
	
    /**
     * Withdraws dummyToken to owner(who can burn it if needed)
     */
    function withdrawDummy(uint256 _amount) external adminOnly {	
        if(_amount == 0) { 
			dummyToken.safeTransfer(admin, dummyToken.balanceOf(address(this)));
		} else {
			dummyToken.safeTransfer(admin, _amount);
		}
    }
	
	
	/**
	 * option to withdraw wrongfully sent tokens(but requires change of the governing contract to do so)
	 * If you send wrong tokens to the contract address, consider them lost. Though there is possibility of recovery
	 */
	function withdrawStuckTokens(address _tokenAddress) external adminOnly {
		require(_tokenAddress != address(token), "wrong token");
		require(_tokenAddress != address(dummyToken), "wrong token");
		
		IERC20(_tokenAddress).safeTransfer(IGovernance(admin).treasuryWallet(), IERC20(_tokenAddress).balanceOf(address(this)));
	}

    
    /**
     * removes the stake
     */
    function _removeStake(address _staker, uint256 _stakeID) private {
        UserInfo[] storage stakes = userInfo[_staker];
        uint256 lastStakeID = stakes.length - 1;
        
        if(_stakeID != lastStakeID) {
            stakes[_stakeID] = stakes[lastStakeID];
        }
        
        stakes.pop();
    }
}