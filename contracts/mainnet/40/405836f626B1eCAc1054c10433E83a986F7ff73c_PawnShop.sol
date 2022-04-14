/**
 *Submitted for verification at polygonscan.com on 2022-04-14
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

pragma solidity 0.8.9;

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


// File contracts/extensions/Ownable.sol
// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity 0.8.9;

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

pragma solidity 0.8.9;

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

pragma solidity 0.8.9;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}


// File @openzeppelin/contracts/token/ERC1155/[email protected]

pragma solidity 0.8.9;

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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


// File @openzeppelin/contracts/utils/math/[email protected]

pragma solidity 0.8.9;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File @openzeppelin/contracts/security/[email protected]

pragma solidity 0.8.9;

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
     * by making the `nonReentrant` function external, and make it call a
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


// File @openzeppelin/contracts/security/[email protected]

pragma solidity 0.8.9;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File contracts/interfaces/IPawnShopEvents.sol

pragma solidity 0.8.9;

interface IPawnShopEvents {

    event OfferCreated(
        bytes16 indexed offerId,
        address collection,
        uint256 tokenId,
        address owner,
        bytes32 offerHash
    );

    event OfferApplied(
        bytes16 indexed offerId,
        address collection,
        uint256 tokenId,
        address lender
    );

    event Repay(
        bytes16 indexed offerId,
        address collection,
        uint256 tokenId,
        address repayer,
        uint256 borrowAmount
    );

    event OfferUpdated(
        bytes16 indexed offerId,
        address collection,
        uint256 tokenId,
        uint256 borrowAmount,
        uint256 borrowPeriod,
        bytes32 offerHash
    );

    event OfferCancelled(bytes16 indexed offerId, address collection, uint256 tokenId);

    event ExtendLendingTimeRequested(
        bytes16 indexed offerId,
        address collection,
        uint256 tokenId,
        uint256 lendingEndAt,
        uint256 lendingFeeAmount,
        uint256 serviceFeeAmount
    );

    event NFTClaim(
        bytes16 indexed offerId,
        address collection,
        uint256 tokenId,
        address taker
    );
}


// File contracts/interfaces/IPawnShopOwnerActions.sol

pragma solidity 0.8.9;

interface IPawnShopOwnerActions {

    function setServiceFeeRates(address[] memory _tokens, uint256[] memory _fees) external;

    function setServiceFeeRate(address _token, uint256 _feeRate) external;

    function removeSupportedTokens(address[] memory _tokens) external;

    function updateTreasury(address _newTreasury) external;
}


// File contracts/interfaces/IPawnShopUserActions.sol

pragma solidity 0.8.9;

interface IPawnShopUserActions {

    struct OfferCreateParam{
        bytes16 offerId;
        address collection;
        uint256 tokenId;
        address to;
        uint256 borrowAmount;
        address borrowToken;
        uint256 borrowPeriod;
        uint256 startApplyAt;
        uint256 closeApplyAt;
        uint256 lenderFeeRate;
        uint256 nftAmount;
    }

    function createOffer721(OfferCreateParam memory params) external;

    function createOffer1155(OfferCreateParam memory params) external;

    function getOfferHash(bytes16 _offerId) external view returns(bytes32);

    function applyOffer(bytes16 _offerId, bytes32 _hash) external payable;

    function repay(bytes16 _offerId) external payable;

    function updateOffer(bytes16 _offerId, uint256 _amount, uint256 _borrowPeriod, uint256 _lenderFeeRate) external;

    function cancelOffer(bytes16 _offerId) external;

    function extendLendingTime(bytes16 _offerId, uint256 _borrowPeriod) external payable;

    function claim(bytes16 _offerId, address _to) external;

    function quoteFees(uint256 _borrowAmount, uint256 _lenderFeeRate, uint256 _serviceFeeRate, uint256 _lendingPeriod) external view returns (uint256 lenderFee, uint256 serviceFee);

    function quoteExtendFees(bytes16 _offerId, uint256 _borrowPeriod) external view returns (uint256 lenderFee, uint256 serviceFee);

    function quoteApplyAmounts(bytes16 _offerId) external view returns (uint256 lenderFee, uint256 serviceFee, uint256 approvedAmount);
}


// File contracts/interfaces/IPawnShop.sol

pragma solidity 0.8.9;



interface IPawnShop is IPawnShopEvents, IPawnShopOwnerActions, IPawnShopUserActions {
}


// File contracts/libraries/PawnShopLibrary.sol

pragma solidity 0.8.9;

library PawnShopLibrary {
    using SafeMath for uint256;

    uint256 public constant YEAR_IN_SECONDS = 31536000;

    // 1000000 is 100% * 10_000 PERCENT FACTOR
    function getFeeAmount(uint256 borrowAmount, uint256 feeRate, uint256 lendingPeriod) internal pure returns (uint256) {
        return lendingPeriod.mul(borrowAmount).mul(feeRate).div(YEAR_IN_SECONDS).div(1000000);
    }

    // Hash to check offer's data integrity 
    function offerHash(
        bytes16 _offerId,
        address _collection,
        uint256 _tokenId,
        uint256 _borrowAmount,
        uint256 _lenderFeeRate,
        uint256 _serviceFeeRate,
        address _borrowToken,
        uint256 _borrowPeriod,
        uint256 _nftAmount
    ) internal pure returns(bytes32 _hash) {
        _hash = keccak256(abi.encode(
            _offerId,
            _collection,
            _tokenId,
            _borrowAmount,
            _lenderFeeRate,
            _serviceFeeRate,
            _borrowToken,
            _borrowPeriod,
            _nftAmount
        ));
    }
}


// File contracts/PawnShop.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;








contract PawnShop is IPawnShop, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // EIP712 Domain Name value
    string constant private EIP712_DOMAIN_NAME = "PawnShop";

    // EIP712 Domain Version value
    string constant private EIP712_DOMAIN_VERSION = "1";

    // Hash of the EIP712 Domain Separator Schema
    /* solium-disable-next-line indentation */
    bytes32 constant private EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = keccak256(abi.encodePacked(
        "EIP712Domain(",
        "string name,",
        "string version,",
        "uint256 chainId,",
        "address verifyingContract",
        ")"
    ));

    struct FeeRate {
        uint256 lenderFeeRate;
        uint256 serviceFeeRate;
    }

    enum OfferState { OPEN, LENDING, CANCELED, REPAID, CLAIMED }

    struct Offer {
        address owner;
        address lender;
        uint256 borrowAmount;
        address borrowToken;
        address to;
        uint256 startApplyAt;
        uint256 closeApplyAt;
        uint256 borrowPeriod;
        uint256 startLendingAt;
        uint256 lenderFeeRate;
        uint256 serviceFeeRate;
        uint256 nftType;
        uint256 nftAmount;
        address collection;
        uint256 tokenId;
        OfferState state;
    }

    // Hash of the EIP712 Domain Separator data
    bytes32 public EIP712_DOMAIN_HASH;

    // EIP191 header for EIP712 prefix
    bytes2 constant private EIP191_HEADER = 0x1901;

    // Hash of the EIP712 Offer struct
    /* solium-disable-next-line indentation */
    bytes32 constant private EIP712_OFFER_STRUCT_SCHEMA_HASH = keccak256(abi.encodePacked(
        "Offer(",
        "address owner,",
        "address lender,",
        "uint256 borrowAmount,",
        "address borrowToken,",
        "address to,",
        "uint256 startApplyAt,",
        "uint256 closeApplyAt",
        "uint256 borrowPeriod,",
        "uint256 startLendingAt,",
        "uint256 lenderFeeRate,",
        "uint256 serviceFeeRate,",
        "uint256 nftType,",
        "uint256 nftAmount,",
        "address collection,",
        "uint256 tokenId,",
        "OfferState state,",
        ")"
    ));

    mapping(bytes16 => Offer) private _offers;

    mapping(address => uint256) private _serviceFeeRates;

    mapping(address => bool) public supportedTokens;

    address payable public treasury;

    address constant private ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 constant private MIN_LENDER_FEE_RATE = 60000; // 6 %
    uint256 constant private MAX_LENDER_FEE_RATE = 720000; // 72 %
    uint256 constant private MAX_SERVICE_FEE_RATE = 280000; // 28 %

    constructor(address payable _treasury, address _multisigWallet) {
        treasury = _treasury;
        _transferOwnership(_multisigWallet);
        /* solium-disable-next-line indentation */
        EIP712_DOMAIN_HASH = keccak256(abi.encode(
            EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
            keccak256(bytes(EIP712_DOMAIN_NAME)),
            keccak256(bytes(EIP712_DOMAIN_VERSION)),
            block.chainid,
            address(this)
        ));
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev functions affected by this modifier can only be invoked if the provided _amount input parameter
     * is not zero.
     * @param _amount the amount provided
     **/
    modifier onlyAmountGreaterThanZero(uint256 _amount) {
        requireAmountGreaterThanZero(_amount);
        _;
    }

    /**
    * @dev functions affected by this modifier can only be invoked if the provided borrowPeriod input parameter
    * is not zero.
    **/
    modifier onlyBorrowPeriodGreaterThanZero(uint256 _borrowPeriod) {
        requireBorrowPeriodGreaterThanZero(_borrowPeriod);
        _;
    }

    function getServiceFeeRate(address _token) external view returns (uint256) {
        return _serviceFeeRates[_token];
    }

    function setServiceFeeRates(address[] memory _tokens, uint256[] memory _feeRates) external override onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            setServiceFeeRate(_tokens[i], _feeRates[i]);
        }
    }

    function updateTreasury(address _newTreasury) external override onlyOwner {
        require(_newTreasury != address(0), "invalid_address");
        treasury = payable(_newTreasury);
    }

    function _addSupportedToken(address _token) internal onlyOwner {
        supportedTokens[_token] = true;
    }

    function removeSupportedTokens(address[] memory _tokens) external override onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            supportedTokens[_tokens[i]] = false;
        }
    }

    function setServiceFeeRate(address _token, uint256 _feeRate) public override onlyOwner {
        require(_feeRate < MAX_SERVICE_FEE_RATE, "invalid_service_fee"); // 28%
        _addSupportedToken(_token);
        _serviceFeeRates[_token] = _feeRate;
    }

    function getOffer(bytes16 _offerId) external view returns(Offer memory offer){
        return _offers[_offerId];
    }

    function createOffer721(OfferCreateParam memory params)
        external
        override
        whenNotPaused
        nonReentrant
    {
        require(IERC721(params.collection).getApproved(params.tokenId) == address(this), "please approve NFT first");
        require(params.nftAmount == 1, "nft_amount_should_be_1");
        // Send NFT to this contract to escrow
        _nftSafeTransfer(msg.sender, address(this), params.collection, params.tokenId, params.nftAmount, 721);
        _createOffer(params, 721);
    }

    function createOffer1155(OfferCreateParam memory params)
        external
        override
        whenNotPaused
        nonReentrant
    {
        require(IERC1155(params.collection).isApprovedForAll(msg.sender, address(this)) == true, "please approve NFT first");
        // Send NFT to this contract to escrow
        _nftSafeTransfer(msg.sender, address(this), params.collection, params.tokenId, params.nftAmount, 1155);
        _createOffer(params, 1155);
    }

    function _nftSafeTransfer(address _from, address _to, address _collection, uint256 _tokenId, uint256 _nftAmount, uint256 _nftType) internal {
        if (_nftType  == 1155) {
            IERC1155(_collection).safeTransferFrom(_from, _to, _tokenId, _nftAmount, "0x");
        } else if (_nftType == 721) {
            IERC721(_collection).transferFrom(_from, _to, _tokenId);
        }
    }

    function _safeTransfer(address _token, address _from, address _to, uint256 _amount) internal {
        if (_token == ETH_ADDRESS) {
            payable(_to).transfer(_amount);
        } else {
            IERC20(_token).transferFrom(_from, _to, _amount);
        }
    }

    function _createOffer(
        OfferCreateParam memory params,
        uint256 _nftType
    )
        internal
        whenNotPaused
        onlyAmountGreaterThanZero(params.borrowAmount)
        onlyBorrowPeriodGreaterThanZero(params.borrowPeriod)
    {
        // Validations
        if (params.closeApplyAt != 0) require(params.closeApplyAt >= block.timestamp, "invalid closed-apply time");

        require(params.borrowToken != address(0), "invalid-payment-token");
        require(_offers[params.offerId].collection == address(0), "offer-existed");
        require(params.lenderFeeRate >= MIN_LENDER_FEE_RATE, "lt_min_lender_fee_RATE");
        require(params.lenderFeeRate <= MAX_LENDER_FEE_RATE, "gt_max_lender_fee_RATE");
        require(supportedTokens[params.borrowToken] == true, "invalid_borrow_token");
        require(params.borrowPeriod <= PawnShopLibrary.YEAR_IN_SECONDS, "over-max-extend-lending-time");

        // Init offer
        Offer memory offer;
        offer.lenderFeeRate = params.lenderFeeRate;
        offer.serviceFeeRate = _serviceFeeRates[params.borrowToken];
        {
            (uint256 lenderFee, uint256 serviceFee) = quoteFees(params.borrowAmount, offer.lenderFeeRate, offer.serviceFeeRate, params.borrowPeriod);
            require(lenderFee > 0, "required minimum lender fee");
            require(serviceFee >= 0, "invalid_service_fee");
        }
        // Set offer informations
        offer.owner = msg.sender;
        offer.borrowAmount = params.borrowAmount;
        offer.borrowToken = params.borrowToken;
        offer.to = params.to;
        offer.collection = params.collection;
        offer.tokenId = params.tokenId;
        offer.startApplyAt = params.startApplyAt;
        if (offer.startApplyAt == 0) offer.startApplyAt = block.timestamp;
        offer.closeApplyAt = params.closeApplyAt;
        offer.borrowPeriod = params.borrowPeriod;
        offer.nftType = _nftType;
        offer.nftAmount = params.nftAmount;
        offer.state = OfferState.OPEN;

        _offers[params.offerId] = offer;

        bytes32 offerHash = getOfferHashOfferInfo(offer);
        // Emit event
        emit OfferCreated(
            params.offerId,
            offer.collection,
            offer.tokenId,
            msg.sender,
            offerHash
        );
    }


    /**
     * Returns the EIP712 hash of an offer.
     */
    function getOfferHash(bytes16 _offerId)
        public
        override
        view
        returns (bytes32)
    {
        Offer memory offer = _offers[_offerId];

        return getOfferHashOfferInfo(offer);
    }

    function getOfferHashOfferInfo(Offer memory _offer) public view returns (bytes32) {
        // compute the overall signed struct hash
        /* solium-disable-next-line indentation */
        bytes32 structHash = keccak256(abi.encode(
            EIP712_OFFER_STRUCT_SCHEMA_HASH,
            _offer
        ));

        // compute eip712 compliant hash
        /* solium-disable-next-line indentation */
        return keccak256(abi.encodePacked(
            EIP191_HEADER,
            EIP712_DOMAIN_HASH,
            structHash
        ));
    }

    // Lender call this function to accepted the offer immediatel
    function applyOffer(bytes16 _offerId, bytes32 _offerHash)
        external
        whenNotPaused
        override
        payable
        nonReentrant
    {
        Offer storage offer = _offers[_offerId];

        // Validations
        require(offer.state == OfferState.OPEN, "apply-non-open-offer");
        if (offer.closeApplyAt != 0) require(offer.closeApplyAt >= block.timestamp, "expired-order");
        // Check data integrity of the offer
        // Make sure the borrower does not change any information at applying time
        bytes32 offerHash = getOfferHashOfferInfo(offer);
        require(offerHash == _offerHash, "offer informations has changed");

        // Update offer informations
        offer.lender = msg.sender;
        offer.startLendingAt = block.timestamp;

        // Calculate Fees
        (uint256 lenderFee, uint256 serviceFee, ) = quoteApplyAmounts(_offerId);
        uint256 borrowAmountAfterFee = offer.borrowAmount.sub(lenderFee).sub(serviceFee);
        if (offer.borrowToken == ETH_ADDRESS) require(msg.value == (borrowAmountAfterFee.add(serviceFee)), "invalid-amount");

        if (serviceFee > 0) _safeTransfer(offer.borrowToken, msg.sender, treasury, serviceFee);
        _safeTransfer(offer.borrowToken, msg.sender, offer.to, borrowAmountAfterFee);

        // Update end times
        offer.state = OfferState.LENDING;
        emit OfferApplied(_offerId, offer.collection, offer.tokenId, msg.sender);
    }

    // Borrower pay
    function repay(bytes16 _offerId)
        external
        override
        payable
        nonReentrant
    {
        Offer storage offer = _offers[_offerId];

        // Validations
        require(offer.state == OfferState.LENDING, "repay-in-progress-offer-only");
        require(offer.startLendingAt.add(offer.borrowPeriod) >= block.timestamp, "overdue loan");
        require(offer.owner == msg.sender, "only owner can repay and get NFT");

        // Repay token to lender
        if (offer.borrowToken == ETH_ADDRESS) require(msg.value >= offer.borrowAmount, "invalid-amount");
        _safeTransfer(offer.borrowToken, msg.sender, offer.lender, offer.borrowAmount);

        // Send NFT back to borrower
        _nftSafeTransfer(address(this), msg.sender, offer.collection, offer.tokenId, offer.nftAmount, offer.nftType);

        offer.state = OfferState.REPAID;
        emit Repay(_offerId, offer.collection, offer.tokenId, msg.sender, offer.borrowAmount);
    }

    function updateOffer(bytes16 _offerId, uint256 _borrowAmount, uint256 _borrowPeriod, uint256 _lenderFeeRate)
        external
        whenNotPaused
        override
    {
        Offer storage offer = _offers[_offerId];

        // Validations
        require(offer.state == OfferState.OPEN, "only update unapply offer");
        require(offer.owner == msg.sender, "only owner can update offer");
        require(offer.lender == address(0), "only update unapply offer");
        require(_lenderFeeRate >= MIN_LENDER_FEE_RATE, "lt_min_lender_fee_RATE");
        require(_lenderFeeRate <= MAX_LENDER_FEE_RATE, "gt_max_lender_fee_RATE");
        require(_borrowPeriod <= PawnShopLibrary.YEAR_IN_SECONDS, "exceeded borrow period");

        // Update offer if has changed?
        if (_borrowPeriod > 0) offer.borrowPeriod = _borrowPeriod;
        if (_borrowAmount > 0) offer.borrowAmount = _borrowAmount;
        offer.lenderFeeRate = _lenderFeeRate;

        (uint256 lenderFee, uint256 serviceFee) = quoteFees(offer.borrowAmount, offer.lenderFeeRate, offer.serviceFeeRate, offer.borrowPeriod);

        // Validations
        require(lenderFee > 0, "required minimum lender fee");
        require(serviceFee >= 0, "invalid_service_fee");
        bytes32 offerHash = getOfferHashOfferInfo(offer);
        emit OfferUpdated(_offerId, offer.collection, offer.tokenId, offer.borrowAmount, offer.borrowPeriod, offerHash);
    }

    function cancelOffer(bytes16 _offerId)
        external
        whenNotPaused
        override
    {
        Offer storage offer = _offers[_offerId];

        // Validations
        require(
            offer.owner == msg.sender,
            "only owner can cancel offer"
        );
        require(offer.lender == address(0), "only update unapply offer");
        require(offer.state == OfferState.OPEN, "can only cancel open offer");
        offer.state = OfferState.CANCELED;

        // Send NFT back to borrower
        _nftSafeTransfer(address(this), msg.sender, offer.collection, offer.tokenId, offer.nftAmount, offer.nftType);
        emit OfferCancelled(_offerId, offer.collection, offer.tokenId);
    }

    //
    // @dev
    // Borrower can know how much they can receive before creating offer
    //
    function quoteFees(uint256 _borrowAmount, uint256 _lenderFeeRate, uint256 _serviceFeeRate, uint256 _lendingPeriod)
        public
        override
        view
        returns (uint256 lenderFee, uint256 serviceFee)
    {
        lenderFee = PawnShopLibrary.getFeeAmount(_borrowAmount, _lenderFeeRate, _lendingPeriod);
        serviceFee = PawnShopLibrary.getFeeAmount(_borrowAmount, _serviceFeeRate, _lendingPeriod);
    }

    // Borrower call this function to estimate how much fees need to paid to extendTimes
    function quoteExtendFees(bytes16 _offerId, uint256 _extendPeriod)
        public
        override
        view
        returns (uint256 lenderFee, uint256 serviceFee)
    {
        Offer storage offer = _offers[_offerId];
        (lenderFee, serviceFee) = quoteFees(offer.borrowAmount, offer.lenderFeeRate, offer.serviceFeeRate, _extendPeriod);
    }

    //
    // @dev
    // approvedAmount: Token amount lender need to approved to take this offer
    //
    function quoteApplyAmounts(bytes16 _offerId)
        public
        override
        view
        returns (uint256 lenderFee, uint256 serviceFee, uint256 approvedAmount)
    {
        Offer storage offer = _offers[_offerId];
        (lenderFee, serviceFee) = quoteFees(offer.borrowAmount, offer.lenderFeeRate, offer.serviceFeeRate, offer.borrowPeriod);
        approvedAmount = offer.borrowAmount.sub(lenderFee);
    }

    // Borrower interest only and extend deadline
    // The total loan period cannot exceed 1 year
    function extendLendingTime(bytes16 _offerId, uint256 _extendPeriod)
        external
        override
        payable
        nonReentrant
        onlyBorrowPeriodGreaterThanZero(_extendPeriod)
    {
        Offer storage offer = _offers[_offerId];

        // Validations
        require(offer.borrowPeriod.add(_extendPeriod) <= PawnShopLibrary.YEAR_IN_SECONDS, "over-max-extend-lending-time");
        require(offer.owner == msg.sender, "only-owner-can-extend-lending-time");
        require(offer.state == OfferState.LENDING, "can only extend in progress offer");
        require(offer.startLendingAt.add(offer.borrowPeriod) >= block.timestamp, "lending-time-closed");

        // Calculate Fees
        (uint256 lenderFee, uint256 serviceFee) = quoteFees(offer.borrowAmount, offer.lenderFeeRate, offer.serviceFeeRate, _extendPeriod);
        require(lenderFee > 0, "required minimum lender fee");
        require(serviceFee >= 0, "invalid_service_fee");

        if (offer.borrowToken == ETH_ADDRESS) require(msg.value >= (lenderFee + serviceFee), "invalid-amount");
        if (serviceFee > 0) _safeTransfer(offer.borrowToken, msg.sender, treasury, serviceFee);
        _safeTransfer(offer.borrowToken, msg.sender, offer.lender, lenderFee);

        // Update end times
        offer.borrowPeriod = offer.borrowPeriod.add(_extendPeriod);

        emit ExtendLendingTimeRequested(
            _offerId,
            offer.collection,
            offer.tokenId,
            offer.startLendingAt.add(offer.borrowPeriod),
            lenderFee,
            serviceFee
        );
    }

    /**
     *
     * In liquidation period, only lender can claim NFT
     * After liquidation period, anyone with fast hand can claim NFT
     *
     **/
    function claim(bytes16 _offerId, address _to)
        external
        override
        nonReentrant
    {
        Offer storage offer = _offers[_offerId];

        // Validations
        require(offer.state == OfferState.LENDING, "offer not lending");
        require(block.timestamp > offer.startLendingAt.add(offer.borrowPeriod), "can not claim in lending period");
        require(offer.lender == msg.sender, "only lender can claim NFT at this time");
        if (_to == address(0)) _to = offer.lender;

        // Send NFT to taker
        _nftSafeTransfer(address(this), _to, offer.collection, offer.tokenId, offer.nftAmount, offer.nftType);
        offer.state = OfferState.CLAIMED;
        emit NFTClaim(_offerId, offer.collection, offer.tokenId, _to);
    }

    /**
    * @notice internal function to save on code size for the onlyAmountGreaterThanZero modifier
    **/
    function requireAmountGreaterThanZero(uint256 _amount) internal pure {
        require(_amount > 0, "Amount must be greater than 0");
    }

    /**
    * @notice internal function to save on code size for the onlyAmountGreaterThanZero modifier
    **/
    function requireBorrowPeriodGreaterThanZero(uint256 _borrowAmount) internal pure {
        require(_borrowAmount >= 1, "Borrow period number must be greater than or equal 0");
    }

    /**
     * @notice internal function to save on code size for the onlyAmountGreaterThanZero modifier
     **/
    function requireAmountGreaterThanOrEqualMinAmount(
        uint256 _min,
        uint256 _amount
    ) internal pure {
        require(_amount >= _min, "Min amount must be greatr than or equal expected amount");
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

}