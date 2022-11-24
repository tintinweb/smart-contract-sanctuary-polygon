/**
 *Submitted for verification at polygonscan.com on 2022-11-22
*/

// SPDX-License-Identifier: MIT
// Using OpenZeppelin Contracts v4.7
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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

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

interface IShooterPalsChips {
    function grantMintAllowance(address account, uint256 amount) external;
    function grantMintAllowanceLocked(address account, uint256 amount) external;
    function getMintAllowance(address account) external view returns(uint256);
    function getMintAllowanceLocked(address account) external view returns(uint256);
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function cap() external view returns (uint256);
    function getSender() external view returns (address);
    function coreTeamMint(uint256 amount, bool locked) external;
    function advisorsMint(uint256 amount, bool locked) external;
    function faucetMint(address account, uint256 amount) external;
    function liquidityMint(address account, uint256 amount) external;
    function communityMint(address account, uint256 amount, bool locked) external;
    function reserveMint(address account, uint256 amount) external;

    event MintAllowanceGranted(address indexed grantedTo, uint256 amount, bool locked);
    event CoreTeamMint(address indexed mintedTo, uint256 amount, bool locked);
    event AdvisorMint(address indexed mintedTo, uint256 amount, bool locked);
    event CommunityMint(address indexed mintedTo, uint256 amount, bool locked);
    event FaucetMint(address indexed mintedTo, uint256 amount);
    event LiquidityMint(address indexed mintedTo, uint256 amount);
    event ReserveMint(address indexed mintedTo, uint256 amount);
}


interface IShooterPalsMarketplace {
    function isCollectionSupported(address _erc1155Address) external view returns (bool);
    function setCollectionSupported(address _erc1155Address, bool _isSupported) external;
    function isTokenSupported(address _erc20Address) external view returns (bool);
    function setTokenSupported(address _erc20Address, bool _supported, uint256 _tokenSellerFee, uint256 _tokenBurnFee) external;
    function tokenFeeMarket(address _erc20Address) external view returns (uint256);
    function tokenFeeBurn(address _erc20Address) external view returns (uint256);
    function tokenFeeTotal(address _erc20Address) external view returns (uint256);
    function getMarketplaceTokenBalance(address erc20Token) external view returns(uint256);
    function withdrawMarketplaceTokenBalance(address to, address erc20Token, uint256 amount) external;
    function burnMarketplaceTokenBalance(address erc20Token, uint256 amount) external;
    function listItem(uint256 listingType, address nftContract, uint256 tokenId, address paymentToken, uint256 amount, uint256 price, uint256 contractDuration) external;
    function cancelListing(address nftContract, uint256 itemId) external;
    function createMarketSale(uint256 itemId, uint256 amount) external;
    function createMarketRent(uint256 itemId) external;

    event CollectionSupportedUpdated(address erc1155Address, bool isSupported);
    event TokenSupportUpdated(address indexed erc20TokenAddress, bool isSupported, uint256 tokenSellerFee, uint256 tokenBurnFee);
    event MarketplaceWithdrawal(address to, address erc20Token, uint256 amount);
    event MarketplaceBurn(address erc20Token, uint256 amount);
    event MarketItemListed (
        uint indexed itemId,    
        uint256 listingType,
        address indexed nftContract,
        uint256 indexed tokenId,
        address acceptedERC20PaymentToken,
        uint256 amount,
        address seller,
        uint256 price,
        uint256 contractDuration
    );
    event MarketItemAccepted (
        uint256 indexed itemId,
        uint256 listingType,
        address seller,
        address buyerOrLessee,
        uint256 contractDuration,
        uint256 contractExpiration
    );
    event MarketListingCancelled(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId
    );
    event MarketSale (
        uint256 itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed paymentToken,
        uint256 amount,
        uint256 unitPrice,
        uint256 totalPrice,
        uint256 sellerProceeds,
        uint256 marketplaceFee,
        uint256 burnFee
    );
    event MarketRent (
        uint256 itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed paymentToken,
        uint256 totalPrice,
        uint256 contractDuration,
        uint256 contractExpiration,
        uint256 sellerProceeds,
        uint256 marketplaceFee,
        uint256 burnFee
    );
    event MarketReceivedItem (
        address indexed owner,  //The market
        address indexed from,
        uint256 tokenId,
        uint256 amount,
        bytes data
    );
    event MarketReceivedBatchedItem (
        address indexed owner,  //The market
        address indexed from,
        uint256[] tokenIds,
        uint256[] amounts,
        bytes data
    );
}

contract ShooterPalsMarketplace is IShooterPalsMarketplace, Ownable, ReentrancyGuard, IERC1155Receiver {

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;

    //ShooterPals contracts
    address private CHIPS_ADDRESS = 0x436bC8008616952A23F53CadfD8d7a8Ba1B001a0;

    //Listing Types
    uint256 public constant SALE = 0;
    uint256 public constant RENT = 1;
    
    //Supported NFT collections
    mapping (address => bool) private collectionSupported;

    //Supported ERC20 Payment Tokens and their associated trading fee (paid by seller)
    mapping (address => bool) private tokenSupported;
    mapping (address => uint256) private tokenSellerFee;    //PERCENTAGE expressed in Basis points (100 = 1%). Applies to SALE and RENT listing types.
    mapping (address => uint256) private tokenBurnFee;    //PERCENTAGE expressed in Basis points. Applies to SALE and RENT listing types.

    function isCollectionSupported(address _erc1155Address) external virtual override view returns (bool) {
        return collectionSupported[_erc1155Address];
    }
    function setCollectionSupported(address _erc1155Address, bool _isSupported) external virtual override onlyOwner {
        collectionSupported[_erc1155Address] = _isSupported;
        emit CollectionSupportedUpdated(_erc1155Address, _isSupported);
    }
    modifier onlySupportedCollections(address nftAddress) {
        require (collectionSupported[nftAddress], "Unsupported nft collection.");
        _;
    }

    function isTokenSupported(address _erc20Address) external virtual override view returns (bool) {
        return tokenSupported[_erc20Address];
    }

    function tokenFeeTotal(address _erc20Address) external virtual override view returns (uint256) {
        return tokenSellerFee[_erc20Address]+tokenBurnFee[_erc20Address];
    }

    function tokenFeeMarket(address _erc20Address) external virtual override view returns (uint256) {
        return tokenSellerFee[_erc20Address];
    }

    function tokenFeeBurn(address _erc20Address) external virtual override view returns (uint256) {
        return tokenBurnFee[_erc20Address];
    }
    
    function setTokenSupported(address _erc20Address, bool _supported, uint256 _tokenSellerFee, uint256 _tokenBurnFee) external virtual override onlyOwner {
        tokenSupported[_erc20Address] = _supported;
        tokenSellerFee[_erc20Address] = _tokenSellerFee;
        tokenBurnFee[_erc20Address] = _tokenBurnFee;
        emit TokenSupportUpdated(_erc20Address, _supported, _tokenSellerFee, _tokenBurnFee);
    }

    modifier onlySupportedTokens(address tokenAddress) {
        require (tokenSupported[tokenAddress], "Unsupported payment token.");
        _;
    }

    function getMarketplaceTokenBalance(address erc20Token) external virtual override view returns(uint256) {
        return IERC20(erc20Token).balanceOf(address(this));
    }
    
    function withdrawMarketplaceTokenBalance(address to, address erc20Token, uint256 amount) external virtual override onlyOwner {
        require(IERC20(erc20Token).balanceOf(address(this))>=amount, "Insufficient token balance on Marketplace.");
        IERC20(erc20Token).transfer(to, amount);
        emit MarketplaceWithdrawal(to, erc20Token, amount);
    }
    
    function burnMarketplaceTokenBalance(address erc20Token, uint256 amount) external virtual override onlyOwner {
        require (erc20Token == CHIPS_ADDRESS);  //Only burn CHIPS
        require(IERC20(erc20Token).balanceOf(address(this))>=amount, "Insufficient token balance on Marketplace.");
        IShooterPalsChips(erc20Token).burn(amount);
        emit MarketplaceBurn(erc20Token, amount);
    }

    function calculateMarketplaceFee(address paymentToken, uint256 sellAmount) internal view returns (uint256) {
        require((sellAmount / 10000) * 10000 == sellAmount, "Number too small"); 
        require(tokenSellerFee[paymentToken]>0, "Payment token doesn't have a marketplace fee.");
        return sellAmount * tokenSellerFee[paymentToken] / 10000;
    }

    function calculateBurnFee(address paymentToken, uint256 sellAmount) internal view returns (uint256) {
        require(paymentToken == CHIPS_ADDRESS); //Check burn authority first
        require((sellAmount / 10000) * 10000 == sellAmount, "Number too small"); 
        require(tokenBurnFee[paymentToken]>0, "Payment token doesn't have a burn fee.");
        return sellAmount * tokenBurnFee[paymentToken] / 10000;
    }

    constructor() {
        //Supported Collections
        collectionSupported[0x7fB03e2aeDFCDcFB67e034ef66a804D2D6Cf6231] = true; //Launch Collection
        collectionSupported[0x702493b1067506B49519558ae6d85AbcAdD307ff] = true; //Launch Backpacks
        collectionSupported[0x4fB96880bFB512Acb146B023f2D1220881eaB0BE] = true; //Bot King
        collectionSupported[0x9653323d23339C5780fD99d0ed9052baf130D4Ca] = true; //Mythic APE
        //Supported Tokens
        tokenSupported[0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619] = true;  //WETH
        tokenSellerFee[0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619] = 500;   //5% Fee to marketplace (500 basis points)
        tokenSupported[CHIPS_ADDRESS] = true;  //CHIPS
        tokenSellerFee[CHIPS_ADDRESS] = 200;   //2% Fee to marketplace (200 basis points)
        tokenBurnFee[CHIPS_ADDRESS] = 200; //2% fee to burn (4% total combined fee for CHIPS transactions)
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }

    mapping(uint256 => MarketItem) internal idToMarketItem;
    uint256[] internal activeListingIds;
    
    struct MarketItem {
        uint256 itemId;
        uint256 activePointer;
        uint256 listingType;
        address nftContract;
        uint256 tokenId;
        address acceptedPaymentToken; 
        uint256 amount;
        address payable seller;
        address payable lessee;
        uint256 price;
        bool active;
        uint256 contractDuration;
        uint256 contractExpiration;
    }

    function getActiveListingCount() public view returns (uint256) {
        return activeListingIds.length;
    }
    function getActiveListingId(uint256 atIndex) public view returns(uint256) {
        return activeListingIds[atIndex];
    }
    function getListing(uint256 id) public view returns (MarketItem memory) {
        return idToMarketItem[id];
    }
    
    //CREATE LISTING
    function listItem(uint256 listingType, address nftContract, uint256 tokenId, address paymentToken, uint256 amount, uint256 price, uint256 contractDuration) external virtual override nonReentrant onlySupportedCollections(nftContract) onlySupportedTokens(paymentToken) {
        require(IERC1155(nftContract).balanceOf(msg.sender, tokenId)>=amount, "Must own NFT to list on the marketplace");  //require ownership of said NFT and amount
        require(IERC1155(nftContract).isApprovedForAll(msg.sender, address(this)), "You must first approve Marketplace to transfer this NFT collection on your behalf to make a Sale listing");
        require(price > 0, "Price must be greater than 0 for Sale and Rental listings");
        require(paymentToken != address(0), "Listings must accept an ERC20 payment token.");

        if (listingType == RENT) {
            require(amount == 1, "Rentals must be listed one at a time.");
            require(contractDuration>0, "Rental listings require a contract duration");
        } else if (listingType == SALE) {
            require(contractDuration == 0, "Sale listings must not indicate a contract duration.");
        }

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        //For Sale listings, the seller keeps ownership until a Sale happens (or listing cancellation). No lessee
        address payable newLessee = payable(address(0));

        //For Rent listings, Marketplace will take ownership of the NFT (player retains use rights as lessee unless rented out)
        if (listingType == RENT) {
            IERC1155(nftContract).safeTransferFrom(msg.sender, address(this), tokenId, amount, ""); //Transfer NFT to Marketplace
            newLessee = payable(msg.sender);
        }

        activeListingIds.push(itemId);

        idToMarketItem[itemId] = MarketItem(
            itemId,
            activeListingIds.length - 1,
            listingType,
            nftContract,
            tokenId,
            paymentToken,
            amount,
            payable(msg.sender),    //seller
            payable(newLessee),   //lessee = rights to use in game (cosmetics and earnings boost). Applicable to RENT listings
            price,
            true,   //listing starts active, until sold or cancelled
            contractDuration,
            0  //expiration not set until rental is accepted
        );

        emit MarketItemListed(itemId, listingType, nftContract, tokenId, paymentToken, amount, msg.sender, price, contractDuration);
    }

    //CANCEL LISTING
    function cancelListing(address nftContract, uint256 itemId) external virtual override nonReentrant {

        require(nftContract == idToMarketItem[itemId].nftContract, "Check failed. Provided nftContract address does not match the NFT for sale at this listed itemId");
        require(idToMarketItem[itemId].active == true, "Listing is no longer active, no need to cancel.");

        //CHECKS
        if (idToMarketItem[itemId].listingType == SALE) {
            require(idToMarketItem[itemId].seller == msg.sender || msg.sender == owner(), "Only seller or contract owner can cancel a Sale listing.");
            require(idToMarketItem[itemId].amount>0, "Cannot cancel, no supply left in listing.");
        } else if (idToMarketItem[itemId].listingType == RENT) {
            require(idToMarketItem[itemId].seller == msg.sender || msg.sender == owner(), "Only seller or contract owner can cancel a Rent listing.");
            require(idToMarketItem[itemId].active == true, "Listing is no longer active.");
            require(block.timestamp>=idToMarketItem[itemId].contractExpiration, "Cannot cancel while rental under contract. Wait until expiration.");
        }

        //ACTIONS
        if (idToMarketItem[itemId].listingType == RENT) {
            //NFT is transferred back to the seller / true owner when rental and scholarship listings are cancelled
            IERC1155(nftContract).safeTransferFrom(address(this), idToMarketItem[itemId].seller, idToMarketItem[itemId].tokenId, idToMarketItem[itemId].amount, ""); //Transfer NFT to Marketplace
            idToMarketItem[itemId].lessee = payable(address(0));
        } 

        //Remove from active listings
        removeActiveListing(itemId);

        idToMarketItem[itemId].amount = 0;
        idToMarketItem[itemId].active = false;
        emit MarketListingCancelled(itemId, nftContract, idToMarketItem[itemId].tokenId);
    }

    function removeActiveListing(uint256 itemId) private {
        uint256 rowToDelete = idToMarketItem[itemId].activePointer;
        uint256 keyToMove = activeListingIds[activeListingIds.length-1];
        activeListingIds[rowToDelete] = keyToMove;
        idToMarketItem[keyToMove].activePointer = rowToDelete;
        activeListingIds.pop();
    }

    //Market Sale
    function createMarketSale(uint256 itemId, uint256 amount) external virtual override nonReentrant {
        require(idToMarketItem[itemId].active == true, "Listing no longer active");
        require(idToMarketItem[itemId].listingType == SALE, "This listing is for Rent, use createMarketRent instead.");
        require(IERC1155(idToMarketItem[itemId].nftContract).balanceOf(idToMarketItem[itemId].seller,idToMarketItem[itemId].tokenId)>=amount, "Seller no longer owns the NFT(s)");
        require(IERC20(idToMarketItem[itemId].acceptedPaymentToken).balanceOf(msg.sender)>=amount.mul(idToMarketItem[itemId].price), "Insufficient payment token balance");
        require(IERC20(idToMarketItem[itemId].acceptedPaymentToken).allowance(msg.sender,address(this))>=amount.mul(idToMarketItem[itemId].price), "Insufficient token allowance. Unlock token spend with Marketplace first.");

        //Marketplace fee and burn
        uint256 sellerProceeds = amount.mul(idToMarketItem[itemId].price);
        uint256 fee;
        uint256 burn;
        if (tokenSellerFee[idToMarketItem[itemId].acceptedPaymentToken]>0) {
            fee = calculateMarketplaceFee(idToMarketItem[itemId].acceptedPaymentToken, amount.mul(idToMarketItem[itemId].price));
            sellerProceeds = sellerProceeds.sub(fee);
        }
        if (tokenBurnFee[idToMarketItem[itemId].acceptedPaymentToken]>0) {
            burn = calculateBurnFee(idToMarketItem[itemId].acceptedPaymentToken, amount.mul(idToMarketItem[itemId].price));
            sellerProceeds = sellerProceeds.sub(burn);
        }

        //Transfer tokens
        IERC20(idToMarketItem[itemId].acceptedPaymentToken).transferFrom(msg.sender,idToMarketItem[itemId].seller,sellerProceeds);
        if (fee>0)  IERC20(idToMarketItem[itemId].acceptedPaymentToken).transferFrom(msg.sender,address(this),fee);
        if (burn>0) IShooterPalsChips(idToMarketItem[itemId].acceptedPaymentToken).burnFrom(msg.sender,burn);   //Only CHIPS will burn
        IERC1155(idToMarketItem[itemId].nftContract).safeTransferFrom(idToMarketItem[itemId].seller, msg.sender, idToMarketItem[itemId].tokenId, amount, "");

        //Record on the marketplace
        idToMarketItem[itemId].amount = idToMarketItem[itemId].amount.sub(amount);
        if (idToMarketItem[itemId].amount<1) {
            idToMarketItem[itemId].active = false;
            removeActiveListing(itemId);
        }

        //Let the world know
        emit MarketSale(itemId,idToMarketItem[itemId].nftContract,idToMarketItem[itemId].tokenId,idToMarketItem[itemId].acceptedPaymentToken,amount,idToMarketItem[itemId].price,idToMarketItem[itemId].price.mul(amount),sellerProceeds,fee,burn);
    }

    //Market Rent
    function createMarketRent(uint256 itemId) external virtual override nonReentrant {
        require(idToMarketItem[itemId].active == true, "Listing no longer active");
        require(idToMarketItem[itemId].listingType == RENT, "This listing is for Sale, use createMarketSale instead.");
        require(block.timestamp >= idToMarketItem[itemId].contractExpiration, "Rental under contract, wait for expiration.");
        require(IERC1155(idToMarketItem[itemId].nftContract).balanceOf(address(this),idToMarketItem[itemId].tokenId)>0, "NFT must be held by Marketplace.");
        require(IERC20(idToMarketItem[itemId].acceptedPaymentToken).balanceOf(msg.sender)>=idToMarketItem[itemId].price, "Insufficient payment token balance");
        require(IERC20(idToMarketItem[itemId].acceptedPaymentToken).allowance(msg.sender,address(this))>=idToMarketItem[itemId].price, "Insufficient token allowance. Unlock token spend with Marketplace first.");

        //Marketplace fee and burn
        uint256 sellerProceeds = idToMarketItem[itemId].price;
        uint256 fee;
        uint256 burn;
        if (tokenSellerFee[idToMarketItem[itemId].acceptedPaymentToken]>0) {
            fee = calculateMarketplaceFee(idToMarketItem[itemId].acceptedPaymentToken, idToMarketItem[itemId].price);
            sellerProceeds = sellerProceeds.sub(fee);
        }
        if (tokenBurnFee[idToMarketItem[itemId].acceptedPaymentToken]>0) {
            burn = calculateBurnFee(idToMarketItem[itemId].acceptedPaymentToken, idToMarketItem[itemId].price);
            sellerProceeds = sellerProceeds.sub(burn);
        }

        //Transfer tokens
        IERC20(idToMarketItem[itemId].acceptedPaymentToken).transferFrom(msg.sender,idToMarketItem[itemId].seller,sellerProceeds);
        if (fee>0)  IERC20(idToMarketItem[itemId].acceptedPaymentToken).transferFrom(msg.sender,address(this),fee);
        if (burn>0) IShooterPalsChips(idToMarketItem[itemId].acceptedPaymentToken).burnFrom(msg.sender,burn);   //Only CHIPS will burn

        //Record on the marketplace
        idToMarketItem[itemId].lessee = payable(address(msg.sender));
        idToMarketItem[itemId].contractExpiration = block.timestamp + idToMarketItem[itemId].contractDuration;

        //Emit event for server processing of Rental
        emit MarketRent(itemId,idToMarketItem[itemId].nftContract,idToMarketItem[itemId].tokenId,idToMarketItem[itemId].acceptedPaymentToken,idToMarketItem[itemId].price,idToMarketItem[itemId].contractDuration, idToMarketItem[itemId].contractExpiration,sellerProceeds,fee,burn);
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes memory data) public virtual override returns (bytes4) {
        emit MarketReceivedItem(operator, from, id, value, data);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] memory ids, uint256[] memory values, bytes memory data) public virtual override returns (bytes4) {
        emit MarketReceivedBatchedItem(operator, from, ids, values, data);
        return this.onERC1155BatchReceived.selector; 
    }
}