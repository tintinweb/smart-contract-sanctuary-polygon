/**
 *Submitted for verification at polygonscan.com on 2023-06-19
*/

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: Nfanst/MarketNFTSNuevo.sol


pragma solidity ^0.8.6;







interface NFTS{
    function artistOf(uint256 _tokenId) external view returns(address);
    function totalNftOwned(address wallet) external view returns(uint[] memory ids, uint [] memory quantity);
}

interface Tickets{
    function totalNftOwned(address wallet) external view returns(uint[] memory ids, uint [] memory quantity);
}

contract Marketplace is Ownable, ReentrancyGuard, ERC1155Holder {
 using Counters for Counters.Counter;
    Counters.Counter public totalOrders;

    address public payTokenContract;
    address public NftsContract;
    address public ticketsContract;

    uint256 public sellFeePercentage;   // example: 500 = 5%
    uint256 public primarySellFeePercentage = 5000;   // example: 500 = 5%
    uint256 public secondarySellFeePercentage = 5000;   // example: 500 = 5%
    address public primaryWalletReceivingSellFee;
    address public secondaryWalletReceivingSellFee;

    uint256 public minIncrement; // example: 500 = 5% (min increment for new bids from highest)

    bool public lockNewSellOrders;
    mapping(uint256 => SellOrder) public marketList;
    mapping(uint256 => Bid) private _bids;

    struct SellOrder {
        uint256 token_id;
        uint256 amount;
        uint256 price;
        address seller;
        bool status; // false:closed, true: open
        uint256 sell_method; // 1 : fixed, 2 : bids
        uint256 expire_at;
        uint256 royalty;
    }

    struct Bid {
        address bidder;
        uint256 amount;
    }

    // Events
    event OrderAdded(
        uint256 order_id,
        uint256 indexed token_id,
        address indexed seller,
        uint256 price,
        uint256 amount,
        uint256 sell_method,
        uint256 expire_at
    );
    event OrderSuccessful(
        uint256 order_id,
        uint256 indexed token_id,
        address indexed seller,
        uint256 price,
        uint256 amount,
        address indexed buyer
    );
    event OrderAuctionResolved(
        uint256 order_id,
        uint256 indexed token_id,
        address indexed seller,
        uint256 totalPrice,
        uint256 amount,
        address indexed buyer
    );
    event OrderCanceled(
        uint256 order_id,
        uint256 indexed token_id,
        address indexed seller,
        uint256 price
    );

    event SetPriceOfSellOrder(
        uint256 order_id,
        uint256 newPrice
    );

    event SetArtistFee(uint256 oldValue, uint256 newValue);

    event SetSellFee(uint256 oldValue, uint256 newValue);

    event RefundCoinsFromAuction(uint256 indexed orderId, address indexed bidder, uint256 amount);
    event NewHighestBid(uint256 indexed orderId, address indexed bidder, uint256 newHighestBid);

    event Set_TokenContracts(address payTokenContract, address NftsContract);
    event Set_TicketsContract(address _ticketsContract);

    event Set_WalletReceivingSellFee(address _primaryWalletReceivingSellFee, address _secondaryWalletReceivingSellFee);

    event Set_LockNewSellOrders(bool lockStatus);

    event Set_MinIncrementForBids(uint256 minIncrement);

    event WalletsPercentages(uint256 primaryWalletPercentage, uint256 secondaryWalletPercentage); 

    event Change_SellOrder(uint256 indexed orderId, uint256 price, uint256 expire_at);

    constructor(uint256 _minIncrementForBids, uint256 _sellFeePercentage, address _primaryWalletReceivingSellFee, address _secondaryWalletReceivingSellFee, address _payTokenContract, address _NftsContract, address _ticketsContract) {
        setMinIncrementForBids(_minIncrementForBids);
        setSellFeePercentage(_sellFeePercentage);
        setWalletReceivingSellFee(_primaryWalletReceivingSellFee,_secondaryWalletReceivingSellFee);
        setContractsAddress(_payTokenContract, _NftsContract);
        setTicketsContract(_ticketsContract);
    }

    function setContractsAddress(address _payTokenContract, address _NftsContract) public onlyOwner {
        payTokenContract = _payTokenContract;
        NftsContract = _NftsContract;
        emit Set_TokenContracts(_payTokenContract, _NftsContract);
    }

    function setTicketsContract(address _ticketsContract) public onlyOwner {
        ticketsContract = _ticketsContract;
        emit Set_TicketsContract(_ticketsContract);
    }

    function setWalletReceivingSellFee(address _primaryWalletReceivingSellFee,address _secondaryWalletReceivingSellFee ) public onlyOwner {
        primaryWalletReceivingSellFee = _primaryWalletReceivingSellFee;
        secondaryWalletReceivingSellFee = _secondaryWalletReceivingSellFee;
        emit Set_WalletReceivingSellFee(_primaryWalletReceivingSellFee,_secondaryWalletReceivingSellFee);
    }

    function setWalletsPercentages(uint _primaryPercentage, uint _secondaryPercentage) public onlyOwner{
        primarySellFeePercentage = _primaryPercentage;   // example: 500 = 5%
        secondarySellFeePercentage = _secondaryPercentage;
        emit WalletsPercentages(_primaryPercentage,_secondaryPercentage); 
    }


    function setLockNewSellOrders(bool _newVal) external onlyOwner{
        lockNewSellOrders = _newVal;
        emit Set_LockNewSellOrders(_newVal);
    }

    function setMinIncrementForBids(uint256 _newVal) public onlyOwner {
        minIncrement = _newVal;
        emit Set_MinIncrementForBids(_newVal);
    }

    function setSellFeePercentage(uint256 _newVal) public onlyOwner {
        require(_newVal <= 9900, "the new value should range from 0 to 9900");
        emit SetSellFee(sellFeePercentage, _newVal);
        sellFeePercentage = _newVal;
    }

    function _computePercent(uint256 _amount, uint256 _feePercentage) internal pure returns (uint256) {
        return (_amount*_feePercentage)/(10**4);
    }

    function newSellOrder(uint256 _token_id, uint256 _amount, uint256 _price, uint256 _sell_method, uint256 _expire_at, uint256 _royalty) external returns (uint256) {
        require(lockNewSellOrders == false, "cannot currently create new sales orders");
        require(IERC1155(NftsContract).balanceOf(msg.sender, _token_id) >= _amount, "you don't have enough balance to sell");
        require(_price > 0, "price must be greater than 0");
        require(_sell_method>=1 && _sell_method<=2, "_sell_method parameter is wrong");
        IERC1155(NftsContract).safeTransferFrom(msg.sender, address(this), _token_id, _amount, "");

        totalOrders.increment();
        uint256 newOrderId = totalOrders.current();
        marketList[newOrderId] = SellOrder(
            _token_id,
            _amount,
            _price,
            msg.sender,
            true,
            _sell_method,
            _expire_at,
            _royalty
        );

        emit OrderAdded(newOrderId, _token_id, msg.sender, _price, _amount, _sell_method, _expire_at);
        return newOrderId;
    }


    function cancelSellOrder(uint256 _orderId) external nonReentrant{
        require(marketList[_orderId].seller == msg.sender, "you are not authorized to cancel this order");
        require(marketList[_orderId].status == true, "this order sell already closed");
        if(marketList[_orderId].sell_method == 2){
            require(block.timestamp >= marketList[_orderId].expire_at, 'MARKET: time no expired yet');
            require(_bids[_orderId].bidder == address(0) && _bids[_orderId].amount == 0, "MARKET: there is a pending auction to be resolved");
        }

        marketList[_orderId].status = false;
        IERC1155(NftsContract).safeTransferFrom(address(this), marketList[_orderId].seller, marketList[_orderId].token_id, marketList[_orderId].amount, "");
        emit OrderCanceled(_orderId, marketList[_orderId].token_id, marketList[_orderId].seller, marketList[_orderId].price);
    }


    function buy(uint256 _orderId, uint256 _amountToBuy) external nonReentrant{
        require(msg.sender != address(0) && msg.sender != marketList[_orderId].seller, "current sender is already owner of this token");
        require(marketList[_orderId].status == true, "this sell order is closed");
        require(marketList[_orderId].sell_method == 1, "this sell order is on auction");
        require(marketList[_orderId].amount >= _amountToBuy, "the amount to buy is not available");

        marketList[_orderId].amount -= _amountToBuy;
        if(marketList[_orderId].amount <= 0){
            marketList[_orderId].status = false;
        }

        uint256 totalPay = marketList[_orderId].price * _amountToBuy;        
        uint256 artistFee = _computePercent(totalPay, marketList[_orderId].royalty);
        uint256 sellFee = _computePercent(totalPay, sellFeePercentage);
        uint256 sellerProfit = totalPay - (artistFee + sellFee);
        
        address artistAddress = NFTS(NftsContract).artistOf(marketList[_orderId].token_id);
        IERC20(payTokenContract).transferFrom(msg.sender, marketList[_orderId].seller, sellerProfit);
        IERC20(payTokenContract).transferFrom(msg.sender, artistAddress, artistFee);
        sendFeeTransaction(sellFee);
        IERC1155(NftsContract).safeTransferFrom(address(this), msg.sender, marketList[_orderId].token_id, _amountToBuy, "");
        emit OrderSuccessful(_orderId, marketList[_orderId].token_id, marketList[_orderId].seller, marketList[_orderId].price, _amountToBuy, msg.sender);
    }

    function reverseOrders(uint256[] memory _orders_id) external onlyOwner{
        for (uint256 i=0; i<_orders_id.length; i++) {
            if(marketList[_orders_id[i]].status == true){
                
                if(marketList[_orders_id[i]].sell_method == 2){
                    if(block.timestamp >= marketList[_orders_id[i]].expire_at && _bids[_orders_id[i]].bidder == address(0) && _bids[_orders_id[i]].amount == 0){
                        // the order has already expired and there are no bids
                    }else{
                        continue;
                    }
                }

                marketList[_orders_id[i]].status = false;
                IERC1155(NftsContract).safeTransferFrom(address(this), marketList[_orders_id[i]].seller, marketList[_orders_id[i]].token_id, marketList[_orders_id[i]].amount, "");
                emit OrderCanceled(_orders_id[i], marketList[_orders_id[i]].token_id, marketList[_orders_id[i]].seller, marketList[_orders_id[i]].price);
            }
        }
    }


    modifier isOpenToAuctions(uint256 _orderId) {
        require(block.timestamp < marketList[_orderId].expire_at, 'MARKET: Time expired to do bids');
        _;
    }

    modifier auctionsEnded(uint256 _orderId) {
        require(block.timestamp >= marketList[_orderId].expire_at, 'MARKET: Time no expired yet');
        _;
    }

    modifier isOnAuctions(uint256 _orderId) {
        require(marketList[_orderId].sell_method == 2, "MARKET: It's not open to bids");
        require(marketList[_orderId].status == true, "MARKET: It's not for sale currently");
        _;
    }

    function minAmountForBid(uint256 _orderId) public view isOpenToAuctions(_orderId) returns (uint256){
        uint256 totalOrderPrice = marketList[_orderId].price * marketList[_orderId].amount;
        uint256 maxValue = (totalOrderPrice  >= _bids[_orderId].amount) ? totalOrderPrice : _bids[_orderId].amount;
        uint256 amountRequired = _computePercent(maxValue, minIncrement);
        return maxValue + amountRequired;
    }

    function bid(uint256 _orderId, uint256 _amount) external isOnAuctions(_orderId) isOpenToAuctions(_orderId) nonReentrant{
        require(marketList[_orderId].seller != msg.sender, "MARKET: Owner can't bid on its token");
        uint256 amountRequired = minAmountForBid(_orderId);
        require(_amount >= amountRequired, 'MARKET: Bid amount lower than current min bids');

        address oldBidder = _bids[_orderId].bidder;
        uint256 oldAmount = _bids[_orderId].amount;

        _bids[_orderId] = Bid({ bidder: msg.sender, amount: _amount });

        if (oldBidder != address(0) && oldAmount > 0) {
            IERC20(payTokenContract).transfer(oldBidder, oldAmount);
            emit RefundCoinsFromAuction(_orderId, oldBidder, oldAmount);
        }

        IERC20(payTokenContract).transferFrom(msg.sender, address(this), _amount);
        emit NewHighestBid(_orderId, msg.sender, _amount);
    }

      function resolveAuction(uint256 _orderId) external isOnAuctions(_orderId) auctionsEnded(_orderId) nonReentrant{
        SellOrder memory order = marketList[_orderId];
        uint256 totalOrderPrice = order.price * order.amount;
        require(_bids[_orderId].amount >= totalOrderPrice, "MARKET: There is nothing pending to solve");

        marketList[_orderId].status = false;
        address tokenSeller = order.seller;
        uint256 sellerProceeds = _bids[_orderId].amount;
        address bidder = _bids[_orderId].bidder;
        uint256 artistFee = _computePercent(sellerProceeds, order.royalty);
        uint256 sellFee = _computePercent(sellerProceeds, sellFeePercentage);
        uint256 feesByTransfer = artistFee + sellFee;
        address artistAddress = NFTS(NftsContract).artistOf(order.token_id);
        IERC20(payTokenContract).transfer(tokenSeller, sellerProceeds - feesByTransfer);
        IERC20(payTokenContract).transfer(artistAddress, artistFee);
        sendFeeTransaction(sellFee);
        IERC1155(NftsContract).safeTransferFrom(address(this), bidder, order.token_id, order.amount, "");
        delete _bids[_orderId];
        emit OrderAuctionResolved(_orderId, order.token_id, tokenSeller, sellerProceeds, order.amount, bidder);
    }


    function changeSellOrder(uint256 _orderId, uint256 _price, uint256 _expire_at) external nonReentrant{
        require(marketList[_orderId].seller == msg.sender, "you are not authorized to change this order");
        require(marketList[_orderId].status == true, "this sell order is closed");
        if(marketList[_orderId].sell_method == 2){
            require(block.timestamp >= marketList[_orderId].expire_at, 'MARKET: time no expired yet');
            require(_bids[_orderId].bidder == address(0) && _bids[_orderId].amount == 0, "MARKET: there is a pending auction to be resolved");
        }

        marketList[_orderId].price = _price;
        marketList[_orderId].expire_at = _expire_at;
        
        emit Change_SellOrder(_orderId, _price, _expire_at);
    }

    function sendFeeTransaction(uint256 sellFee) internal {
        uint256 primarySellFee = _computePercent(sellFee, primarySellFeePercentage);
        uint256 secondarySellFee = _computePercent(sellFee, secondarySellFeePercentage);
        require(IERC20(payTokenContract).transfer(primaryWalletReceivingSellFee, primarySellFee));
        require(IERC20(payTokenContract).transfer(secondaryWalletReceivingSellFee, secondarySellFee));
    }

    
    function ResolveOrder(uint256 _orderId, uint256 _amountToBuy, address _buyer) external onlyOwner nonReentrant{
        require(msg.sender == marketList[_orderId].seller, "you are not authorized to resolve this order");
        require(marketList[_orderId].status == true, "this sell order is closed");
        require(marketList[_orderId].sell_method == 1, "this sell order is on auction");
        require(marketList[_orderId].amount >= _amountToBuy, "the amount to buy is not available");

        marketList[_orderId].amount -= _amountToBuy;
        if(marketList[_orderId].amount <= 0){
            marketList[_orderId].status = false;
        }

        IERC1155(NftsContract).safeTransferFrom(address(this), _buyer, marketList[_orderId].token_id, _amountToBuy, "");
        emit OrderSuccessful(_orderId, marketList[_orderId].token_id, marketList[_orderId].seller, marketList[_orderId].price, _amountToBuy, _buyer);
    }

      function getTicketsOwned(address _wallet) public view returns(uint[] memory ids, uint[] memory quantity){
        return Tickets(ticketsContract).totalNftOwned(_wallet);
    }

    function getNftsOwned(address _wallet) public view returns(uint[] memory ids, uint[] memory quantity){
        return Tickets(NftsContract).totalNftOwned(_wallet);
    }



}