// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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

// SPDX-License-Identifier: GNU GPLv3

pragma solidity ^0.8.0;

import "./IStabl3StakingStruct.sol";
import "./IERC20.sol";

interface IROI is IStabl3StakingStruct {

    function timeWeightedAPR() external view returns (TimeWeightedAPR memory);
    function updateAPRLast() external view returns (uint256);
    function updateTimestampLast() external view returns (uint256);

    function contractCreationTime() external view returns (uint256);

    function getTimeWeightedAPRs(uint256) external view returns (TimeWeightedAPR memory);
    function getAPRs(uint256) external view returns (uint256);

    function permitted(address) external returns (bool);

    function searchTimeWeightedAPR(uint256 _startTimeWeight, uint256 _endTimeWeight) external view returns (TimeWeightedAPR memory);

    function getTotalRewardDistributed() external view returns (uint256);

    function getReserves() external view returns (uint256);

    function getAPR() external view returns (uint256);

    function validatePool(
        IERC20 _token,
        uint256 _amountToken,
        uint8 _stakingType,
        bool _isLending
    ) external view returns (uint256 maxPool, uint256 currentPool);

    function distributeReward(
        address _user,
        IERC20 _rewardToken,
        uint256 _amountRewardToken,
        uint8 _rewardPoolType
    ) external;

    function updateAPR() external;

    function returnFunds(IERC20 _token, uint256 _amountToken) external;
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IStabl3StakingStruct {

    struct TimeWeightedAPR {
        uint256 APR;
        uint256 timeWeight;
    }

    struct Staking {
        uint256 index;
        address user;
        bool status;
        uint8 stakingType;
        IERC20 token;
        uint256 amountTokenStaked;
        uint256 startTime;
        TimeWeightedAPR timeWeightedAPRLast;
        uint256 rewardWithdrawn;
        uint256 rewardWithdrawTimeLast;
        bool isLending;
        uint256 amountStabl3Lending;
        bool isDormant;
        bool isRealEstate;
    }

    struct Record {
        uint256 totalAmountTokenStaked;
        uint256 totalRewardWithdrawn;
        uint256 totalAmountStabl3Withdrawn;
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ITreasury {

    function exchangeFee() external view returns (uint256);

    function rateInfo() external view returns (uint256 rate, uint256 totalValueLocked, uint256 stabl3CirculatingSupply);

    function isReservedToken(IERC20) external view returns (bool);

    function allReservedTokens(uint) external view returns (IERC20);

    function getTreasuryPool(uint8, IERC20) external view returns (uint256);
    function getROIPool(uint8, IERC20) external view returns (uint256);
    function getHQPool(uint8, IERC20) external view returns (uint256);

    function permitted(address) external view returns (bool);

    function allReservedTokensLength() external view returns (uint256);

    function allPools(uint8 _type, IERC20 _token) external view returns (uint256, uint256, uint256);

    function sumOfAllPools(uint8 _type, IERC20 _token) external view returns (uint256);

    function getReserves() external view returns (uint256);

    function getTotalValueLocked() external view returns (uint256);

    function reservedTokenSelector() external view returns (IERC20);

    function getLockedAmount() external view returns (uint256);

    function getRate() external view returns (uint256);

    function getRateImpact(IERC20 _token, uint256 _amountToken) external view returns (uint256);

    function getAmountOut(IERC20 _token, uint256 _amountToken) external view returns (uint256);

    function getAmountIn(uint256 _amountStabl3, IERC20 _token) external view returns (uint256);

    function getBaseAmountOut(uint256 _amountToken) external view returns (uint256);

    function getBaseAmountIn(uint256 _amountStabl3) external view returns (uint256);

    function getExchangeAmountOut(IERC20 _exchangingToken, IERC20 _token, uint256 _amountToken) external view returns (uint256);

    function getExchangeAmountIn(IERC20 _exchangingToken, uint256 _amountExchangingToken, IERC20 _token) external view returns (uint256);

    function updatePool(
        uint8 _type,
        IERC20 _token,
        uint256 _amountTokenTreasury,
        uint256 _amountTokenROI,
        uint256 _amountTokenHQ,
        bool _isIncrease
    ) external;

    function updateStabl3CirculatingSupply(uint256 _amountStabl3, bool _isIncrease) external;

    function updateRateHistoryTotal() external;

    function updateRate(IERC20 _token, uint256 _amountToken) external;
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IUCD is IERC20 {

    function permitted(address contractAddress) external view returns (bool);

    function mint(address account, uint256 amount) external returns (bool);

    function burnFrom(address account, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Address.sol";
import "./IERC20.sol";
import "./IERC20Permit.sol";

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
        if (value > 0) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
        }
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        if (value > 0) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
        }
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }

    /**
     * @dev Returns the current rounding of the division of two numbers.
     *
     * This differs from standard division with `/` in that it can round up and
     * down depending on the floating point.
     */
    function roundDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a * 10 / b;
        if (result % 10 >= 5) {
            result = a / b + (a % b == 0 ? 0 : 1);
        }
        else {
            result = a / b;
        }

        return result;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, without an overflow flag
     */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b > a) return 0;
            return a - b;
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, without an overflow flag
     */
    function checkSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b > a) return a;
            else return a - b;
        }
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.19;

import "./Ownable.sol";

import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IERC721.sol";
import "./ITreasury.sol";
import "./IROI.sol";
import "./IUCD.sol";

contract Stabl3Borrowing is Ownable {
    using SafeMath for uint256;

    uint8 private constant STAKE_POOL = 2;
    uint8 private constant LEND_POOL = 5;

    uint8 private constant UCD_BORROW_POOL = 8;
    uint8 private constant UCD_PAYBACK_POOL = 9;
    uint8 private constant UCD_TO_TOKEN_EXCHANGE_POOL = 10;
    uint8 private constant STABL3_COLLATERAL_POOL = 11;

    address public donationWallet;

    ITreasury public TREASURY;
    IROI public ROI;

    IERC20 public immutable STABL3;

    IUCD public UCD;

    IERC721 public INVESTORS;

    uint256 public borrowFee;
    uint256 public exchangeUCDFee;

    uint8[] public returnBorrowingPools;

    uint256 private burnedUCD;

    Borrowing public getBorrowing;

    bool public borrowState;

    // structs

    struct Borrowing {
        uint256 amountUCD;
        uint256 amountStabl3;
        uint256 amountFee;
        uint256 amountStabl3Fee;
    }

    // events

    event UpdatedDonationWallet(address newDonationWallet, address oldDonationWallet);

    event UpdatedTreasury(address newTreasury, address oldTreasury);

    event UpdatedROI(address newROI, address oldROI);

    event UpdatedBorrowFee(uint256 newBorrowFee, uint256 oldBorrowFee);

    event UpdatedExchangeUCDFee(uint256 newExchangeUCDFee, uint256 oldExchangeUCDFee);

    event Borrow(
        address indexed user,
        uint256 amountUCD,
        uint256 amountStabl3,
        uint256 rate,
        uint256 timestamp
    );

    event Payback(
        address indexed user,
        uint256 amountUCD,
        uint256 amountStabl3,
        uint256 rate,
        uint256 timestamp
    );

    event ExchangeUCD(
        address indexed user,
        IERC20 exchangingToken,
        uint256 amountExchangingToken,
        uint256 amountUCD,
        uint256 fee,
        uint256 timestamp
    );

    // constructor

    constructor(address _TREASURY, address _ROI) {
        // TODO change
        donationWallet = 0x3edCe801a3f1851675e68589844B1b412EAc6B07;

        TREASURY = ITreasury(_TREASURY);
        ROI = IROI(_ROI);

        // TODO change
        STABL3 = IERC20(0xc3Bf0c0172E3638d383361801e9BF63B4FfE0d6e);

        // TODO change
        UCD = IUCD(0x78Ef94529fC06F08756a43f6Bdfe61395C0e1428);

        // TODO change
        INVESTORS = IERC721(0xE8CCB5e6c591414e767602688ff1F50B3990C206);

        borrowFee = 50;
        exchangeUCDFee = 25;

        returnBorrowingPools = [0, 1, 2, 5];
    }

    function updateDonationWallet(address _donationWallet) external onlyOwner {
        require(donationWallet != _donationWallet, "Stabl3Borrowing: Donation Wallet is already this address");
        emit UpdatedDonationWallet(_donationWallet, donationWallet);
        donationWallet = _donationWallet;
    }

    function updateTreasury(address _TREASURY) external onlyOwner {
        require(address(TREASURY) != _TREASURY, "Stabl3Borrowing: Treasury is already this address");
        emit UpdatedTreasury(_TREASURY, address(TREASURY));
        TREASURY = ITreasury(_TREASURY);
    }

    function updateROI(address _ROI) external onlyOwner {
        require(address(ROI) != _ROI, "Stabl3Borrowing: ROI is already this address");
        emit UpdatedROI(_ROI, address(ROI));
        ROI = IROI(_ROI);
    }

    function updateUCD(address _ucd) external onlyOwner {
        require(address(UCD) != _ucd, "Stabl3Borrowing: UCD is already this address");
        UCD = IUCD(_ucd);
    }

    function updateBorrowFee(uint256 _borrowFee) external onlyOwner {
        require(borrowFee != _borrowFee, "Stabl3Borrowing: Borrow Fee is already this value");
        emit UpdatedBorrowFee(_borrowFee, borrowFee);
        borrowFee = _borrowFee;
    }

    function updateExchangeUCDFee(uint256 _exchangeUCDFee) external onlyOwner {
        require(exchangeUCDFee != _exchangeUCDFee, "Stabl3Borrowing: Exchange Fee for UCD is already this value");
        emit UpdatedExchangeUCDFee(_exchangeUCDFee, exchangeUCDFee);
        exchangeUCDFee = _exchangeUCDFee;
    }

    function updateReturnBorrowingPools(uint8[] memory _returnBorrowingPools) external onlyOwner {
        returnBorrowingPools = _returnBorrowingPools;
    }

    function updateState(bool _state) external onlyOwner {
        require(borrowState != _state, "Stabl3Borrowing: Borrow State is already this state");
        borrowState = _state;
    }

    function getReservesUCD() public view returns (uint256 availableUCD, uint256 borrowedUCD, uint256 returnedUCD) {
        uint256 totalExtraLiquidity;

        for (uint256 i = 0 ; i < TREASURY.allReservedTokensLength() ; i++) {
            IERC20 reservedToken = TREASURY.allReservedTokens(i);

            if (TREASURY.isReservedToken(reservedToken)) {
                uint256 stakeAmount = TREASURY.getTreasuryPool(STAKE_POOL, reservedToken);
                uint256 lendAmount = TREASURY.getTreasuryPool(LEND_POOL, reservedToken);

                uint256 decimals = reservedToken.decimals();

                totalExtraLiquidity +=
                    decimals < 18 ?
                    (stakeAmount * (10 ** (18 - decimals))) + (lendAmount * (10 ** (18 - decimals))) :
                    stakeAmount + lendAmount;
            }
        }

        availableUCD = TREASURY.getReserves() + ROI.getReserves();
        availableUCD = availableUCD.safeSub(totalExtraLiquidity);
        availableUCD /= 10 ** (18 - UCD.decimals());
        uint256 ucdTotalSupply = UCD.totalSupply();
        availableUCD = availableUCD.safeSub(ucdTotalSupply);

        borrowedUCD = ucdTotalSupply;

        returnedUCD = burnedUCD;
    }

    /**
     * @dev This function allows users to deposit STABL3 and to receive UCD at current protocol rates
     * @dev Fees are cut in the form of stablecoins by reducing amount of UCD
     */
    function borrow(uint256 _amountStabl3) external borrowActive {
        require(_amountStabl3 > 0, "Stabl3Borrowing: Insufficient amount");

        uint256 amountUCD = TREASURY.getBaseAmountIn(_amountStabl3);

        uint256 fee;
        uint256 stabl3Fee;
        if (INVESTORS.balanceOf(msg.sender) == 0) {
            fee = amountUCD.mul(borrowFee).div(1000);
            stabl3Fee = TREASURY.getAmountOut(UCD, fee);
        }
        uint256 amountUCDWithFee = amountUCD - fee;
        uint256 amountStabl3WithFee = _amountStabl3 - stabl3Fee;

        (uint256 availableUCD, , ) = getReservesUCD();
        require(amountUCDWithFee <= availableUCD, "Stabl3Borrowing: Insufficient available UCD");

        getBorrowing.amountUCD += amountUCDWithFee;
        getBorrowing.amountStabl3 += amountStabl3WithFee;
        getBorrowing.amountFee += fee;
        getBorrowing.amountStabl3Fee += stabl3Fee;

        IERC20 reservedToken = TREASURY.reservedTokenSelector();

        uint256 decimalsReservedToken = reservedToken.decimals();
        uint256 decimalsUCD = UCD.decimals();

        if (decimalsReservedToken > decimalsUCD) {
            fee *= 10 ** (decimalsReservedToken - decimalsUCD);
        }
        else if (decimalsReservedToken < decimalsUCD) {
            fee /= 10 ** (decimalsUCD - decimalsReservedToken);
        }

        _returnBorrowingFunds(reservedToken, fee, true);

        SafeERC20.safeTransferFrom(reservedToken, address(TREASURY), address(ROI), fee);

        STABL3.transferFrom(msg.sender, address(TREASURY), _amountStabl3);

        UCD.mint(msg.sender, amountUCDWithFee);

        TREASURY.updatePool(UCD_BORROW_POOL, UCD, amountUCDWithFee, 0, 0, true);
        TREASURY.updatePool(STABL3_COLLATERAL_POOL, STABL3, _amountStabl3, 0, 0, true);
        TREASURY.updateStabl3CirculatingSupply(_amountStabl3, false);
        TREASURY.updateRateHistoryTotal();

        ROI.updateAPR();

        emit Borrow(msg.sender, amountUCDWithFee, _amountStabl3, TREASURY.getRate(), block.timestamp);
    }

    /**
     * @dev This function allows users to repay their borrowed UCD in return for STABL3 at current protocol rates
     * @dev No fees are cut in this function
     */
    function payback(uint256 _amountUCD) external borrowActive {
        require(_amountUCD > 0, "Stabl3Borrowing: Insufficient amount");
        require(getBorrowing.amountUCD > 0, "Stabl3Borrowing: No debt to payback");

        uint256 amountStabl3 = TREASURY.getBaseAmountOut(_amountUCD);

        uint256 amountStabl3ToUncollateralize = (getBorrowing.amountStabl3 * _amountUCD) / getBorrowing.amountUCD;
        uint256 amountFeeToUncollateralize = (getBorrowing.amountFee * _amountUCD) / getBorrowing.amountUCD;
        uint256 amountStabl3FeeToUncollateralize = (getBorrowing.amountStabl3Fee * _amountUCD) / getBorrowing.amountUCD;

        getBorrowing.amountUCD -= _amountUCD;
        getBorrowing.amountStabl3 -= amountStabl3ToUncollateralize;
        getBorrowing.amountFee -= amountFeeToUncollateralize;
        getBorrowing.amountStabl3Fee -= amountStabl3FeeToUncollateralize;

        UCD.burnFrom(msg.sender, _amountUCD);
        burnedUCD += _amountUCD;

        uint256 leftoverCollateralStabl3 = amountStabl3ToUncollateralize.safeSub(amountStabl3);

        STABL3.transferFrom(address(TREASURY), msg.sender, amountStabl3);
        if (leftoverCollateralStabl3 > 0) {
            // donation
            STABL3.transferFrom(address(TREASURY), donationWallet, leftoverCollateralStabl3);
        }

        TREASURY.updatePool(UCD_PAYBACK_POOL, UCD, _amountUCD, 0, 0, true);
        // amountStabl3ToUncollateralize is unlocked and transferred out as amountStabl3 and leftoverCollateralStabl3
        // amountStabl3FeeToUncollateralize is unlocked and stays in the treasury to be purchasable
        TREASURY.updatePool(
            STABL3_COLLATERAL_POOL,
            STABL3,
            amountStabl3ToUncollateralize + amountStabl3FeeToUncollateralize,
            0,
            0,
            false
        );

        TREASURY.updateStabl3CirculatingSupply(amountStabl3ToUncollateralize, true);
        TREASURY.updateRateHistoryTotal();

        emit Payback(msg.sender, _amountUCD, amountStabl3, TREASURY.getRate(), block.timestamp);
    }

    /**
     * @dev Fees are cut from amount of exchanging token
     */
    function exchangeUCD(IERC20 _exchangingToken, uint256 _amountUCD) external borrowActive reserved(_exchangingToken) {
        require(_amountUCD > 0, "Stabl3Borrowing: Insufficient amount");
        require(getBorrowing.amountUCD > 0, "Stabl3Borrowing: No debt to payback");

        uint256 amountStabl3 = TREASURY.getBaseAmountOut(_amountUCD);

        uint256 amountStabl3ToUncollateralize = (getBorrowing.amountStabl3 * _amountUCD) / getBorrowing.amountUCD;
        uint256 amountFeeToUncollateralize = (getBorrowing.amountFee * _amountUCD) / getBorrowing.amountUCD;
        uint256 amountStabl3FeeToUncollateralize = (getBorrowing.amountStabl3Fee * _amountUCD) / getBorrowing.amountUCD;

        getBorrowing.amountUCD -= _amountUCD;
        getBorrowing.amountStabl3 -= amountStabl3ToUncollateralize;
        getBorrowing.amountFee -= amountFeeToUncollateralize;
        getBorrowing.amountStabl3Fee -= amountStabl3FeeToUncollateralize;

        UCD.burnFrom(msg.sender, _amountUCD);
        burnedUCD += _amountUCD;

        uint256 leftoverCollateralStabl3 = amountStabl3ToUncollateralize.safeSub(amountStabl3);

        if (leftoverCollateralStabl3 > 0) {
            // donation
            STABL3.transferFrom(address(TREASURY), donationWallet, leftoverCollateralStabl3);
        }

        // leftoverCollateralStabl3 is the only amount unlocked and the rest of the amountStabl3ToUncollateralize stays locked
        // amountStabl3FeeToUncollateralize is unlocked as this is not linked to the exact borrowing amount
        TREASURY.updatePool(
            STABL3_COLLATERAL_POOL,
            STABL3,
            amountStabl3ToUncollateralize + amountStabl3FeeToUncollateralize,
            0,
            0,
            false
        );

        TREASURY.updateStabl3CirculatingSupply(leftoverCollateralStabl3, true);

        uint256 amountExchangingToken = _amountUCD;

        uint256 decimalsExchangingToken = _exchangingToken.decimals();
        uint256 decimalsUCD = UCD.decimals();

        if (decimalsExchangingToken > decimalsUCD) {
            amountExchangingToken *= 10 ** (decimalsExchangingToken - decimalsUCD);
        }
        else if (decimalsExchangingToken < decimalsUCD) {
            amountExchangingToken /= 10 ** (decimalsUCD - decimalsExchangingToken);
        }

        uint256 fee;
        if (INVESTORS.balanceOf(msg.sender) == 0) {
            fee = amountExchangingToken.mul(exchangeUCDFee).div(1000);
        }
        uint256 amountExchangingTokenWithFee = amountExchangingToken - fee;

        if (amountExchangingToken > _exchangingToken.balanceOf(address(TREASURY))) {
            ROI.returnFunds(_exchangingToken, amountExchangingToken - _exchangingToken.balanceOf(address(TREASURY)));
        }

        _returnBorrowingFunds(_exchangingToken, fee, true);
        _returnBorrowingFunds(_exchangingToken, amountExchangingTokenWithFee, false);

        SafeERC20.safeTransferFrom(_exchangingToken, address(TREASURY), address(ROI), fee);
        SafeERC20.safeTransferFrom(_exchangingToken, address(TREASURY), msg.sender, amountExchangingTokenWithFee);

        TREASURY.updatePool(UCD_TO_TOKEN_EXCHANGE_POOL, _exchangingToken, amountExchangingTokenWithFee, 0, 0, true);
        TREASURY.updatePool(UCD_TO_TOKEN_EXCHANGE_POOL, UCD, _amountUCD, 0, 0, true);
        TREASURY.updateRateHistoryTotal();

        ROI.updateAPR();

        emit ExchangeUCD(msg.sender, _exchangingToken, amountExchangingTokenWithFee, _amountUCD, fee, block.timestamp);
    }

    /**
     * @dev Calls TREASURY's updatePool to reduce the TREASURY amounts
     */
    function _returnBorrowingFunds(IERC20 _token, uint256 _amountToken, bool _isUpdate) internal {
        uint256 amountToUpdate = _amountToken;

        for (uint8 i = 0 ; i < returnBorrowingPools.length ; i++) {
            uint256 amountPool = TREASURY.getTreasuryPool(returnBorrowingPools[i], _token);

            if (amountPool != 0) {
                if (amountPool < amountToUpdate) {
                    TREASURY.updatePool(returnBorrowingPools[i], _token, amountPool, 0, 0, false);
                    if (_isUpdate) {
                        TREASURY.updatePool(returnBorrowingPools[i], _token, 0, amountPool, 0, true);
                    }

                    amountToUpdate -= amountPool;
                }
                else {
                    TREASURY.updatePool(returnBorrowingPools[i], _token, amountToUpdate, 0, 0, false);
                    if (_isUpdate) {
                        TREASURY.updatePool(returnBorrowingPools[i], _token, 0, amountToUpdate, 0, true);
                    }

                    amountToUpdate = 0;
                    break;
                }
            }
        }

        require(amountToUpdate == 0, "Stabl3Borrowing: Not enough funds in the specified pools");
    }

    // modifiers

    modifier borrowActive() {
        require(borrowState, "Stabl3Borrowing: Borrow not yet started");
        _;
    }

    modifier reserved(IERC20 _token) {
        require(TREASURY.isReservedToken(_token), "Stabl3Borrowing: Not a reserved token");
        _;
    }
}