// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./IAlleleEscrow.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract AlleleEscrow is IAlleleEscrow, Ownable, ERC1155Holder {
    using Counters for Counters.Counter;

    address public gen2Contract;
    address public gen3Contract;
    address public agtContract;

    Counters.Counter private _orderId;
    Counters.Counter private _marketId;

    mapping(uint256 => Order) private orders;

    mapping(uint256 => Market) private markets;

    constructor() {}

    function sell(
        uint256 _tokenID,
        uint256 _generation,
        uint256 _amount,
        uint256 _price
    ) external override {
        require(_generation >= 2 && _generation <= 3, "Invalid generation");
        // Transfer token to this
        address contractAddress = _generation == 2
            ? gen2Contract
            : gen3Contract;
        IERC1155(contractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenID,
            _amount,
            ""
        );

        // Create a new Market
        uint256 marketID = _marketId.current();
        markets[marketID] = Market({
            tokenID: _tokenID,
            generation: _generation,
            price: _price,
            seller: msg.sender,
            amount: _amount
        });

        _marketId.increment();
        emit MarketAdded(marketID, _tokenID, _generation, _amount, _price, msg.sender);
    }

    function buy(
        uint256 _marketID,
        uint256 _amount,
        string memory _metadataURI
    ) external override {
        // Transfer AGT to this
        Market storage marketData = markets[_marketID];

        require(
            marketData.amount >= _amount,
            "Market is less than your buying amount"
        );
        require(marketData.price > 0, "Market not found");

        IERC20(agtContract).transferFrom(
            msg.sender,
            address(this),
            marketData.price
        );

        // Create a new Order

        uint256 orderID = _orderId.current();

        orders[orderID] = Order({
            tokenId: marketData.tokenID,
            generation: marketData.generation,
            price: marketData.price,
            deliveryCharge: 2 * 1e18,
            seller: marketData.seller,
            buyer: msg.sender,
            distributor: address(0),
            metadataURI: _metadataURI,
            status: DeliveryStatus.PENDING,
            amount: _amount
        });

        _orderId.increment();

        // UPDATE Market
        marketData.amount -= _amount;
        emit OrderCreated(
            orderID,
            marketData.tokenID,
            marketData.generation,
            msg.sender,
            marketData.seller,
            marketData.amount,
            marketData.price,
            _metadataURI
        );
    }

    function startProcessing(uint256 _orderID) external override {
        //  Verify Caller is seller
        Order storage order = orders[_orderID];
        require(order.status == DeliveryStatus.PENDING, "Order is not pending");
        require(order.seller == msg.sender, "You are not seller");
        // Change status to processing
        order.status = DeliveryStatus.PROCESSING;
        emit OrderProceed(_orderID);
    }

    function markAsShipped(uint256 _orderID, address _distributor)
        external
        override
    {
        // Verify Caller is seller
        Order storage order = orders[_orderID];
        require(
            order.status == DeliveryStatus.PENDING ||
                order.status == DeliveryStatus.PROCESSING,
            "Order is not pending or processing"
        );
        require(order.seller == msg.sender, "You are not seller");
        // Change status to shipped
        order.distributor = _distributor;
        order.status = DeliveryStatus.SHIPPED;
        emit OrderShipped(_orderID, _distributor);
    }

    function delivered(uint256 _orderID) external override {
        //  Verify Caller is distributor
        // Verify Caller is seller
        Order storage order = orders[_orderID];
        require(order.status == DeliveryStatus.SHIPPED, "Order is not shipped");
        require(order.distributor == msg.sender, "You are not distributor");

        //  Change status to delivered
        order.status = DeliveryStatus.DELIVERED;
        emit OrderDerlivered(_orderID);
    }

    function _complete(Order memory order, uint256 _orderID) internal {
        order.status = DeliveryStatus.COMPLETED;

        // Transfer agt to seller and transfer token to buyer
        IERC20(agtContract).transfer(order.seller, order.price);
        address contractAddress = order.generation == 2
            ? gen2Contract
            : gen3Contract;
        IERC1155(contractAddress).safeTransferFrom(
            address(this),
            order.buyer,
            order.tokenId,
            order.amount,
            ""
        );
        emit OrderCompleted(_orderID);
    }

    function completeByBuyer(uint256 _orderID) external override {
        Order storage order = orders[_orderID];
        require(
            order.status == DeliveryStatus.DELIVERED,
            "Order is not delivered"
        );
        require(order.buyer == msg.sender, "You are not buyer");
        _complete(order, _orderID);
    }

    function dispute(uint256 _orderID, string memory _reasonURI)
        external
        override
    {
        // verify Caller is buyer or seller or distributor
        Order storage order = orders[_orderID];
        require(
            order.seller == msg.sender ||
                order.buyer == msg.sender ||
                order.distributor == msg.sender,
            "You are not buyer nor seller nor distributor"
        );
        order.status = DeliveryStatus.DISPUTED;
        emit OrderDisputed(_orderID, _reasonURI);
    }

    function cancel(uint256 _orderID, string memory _reasonURI)
        external
        override
    {
        // Verify caller is admin
        Order storage order = orders[_orderID];
        require(msg.sender == owner(), "You are not Admin");
        require(
            order.status == DeliveryStatus.DISPUTED,
            "Order is not disputed"
        );
        // Change status to cancelled
        order.status = DeliveryStatus.CANCELLED;
        // Return money to buyer and return ownership to seller
        IERC20(agtContract).transfer(order.buyer, order.price);
        address contractAddress = order.generation == 2
            ? gen2Contract
            : gen3Contract;
        IERC1155(contractAddress).safeTransferFrom(
            address(this),
            order.seller,
            order.tokenId,
            order.amount,
            ""
        );
        emit OrderCancelled(_orderID, _reasonURI);
    }

    function getOrder(uint256 _orderID)
        external
        view
        override
        returns (Order memory)
    {
        return orders[_orderID];
    }

    function setGen2(address _gen2Address) external onlyOwner {
        gen2Contract = _gen2Address;
    }

    function setGen3(address _gen3Address) external onlyOwner {
        gen3Contract = _gen3Address;
    }
    function setAGT(address _agtAddress) external onlyOwner {
        agtContract = _agtAddress;
    }

    function completeByAdmin(uint256 _orderID) external override {
        Order storage order = orders[_orderID];
        require(
            order.status == DeliveryStatus.DISPUTED,
            "Order is not disputed"
        );
        require(owner() == msg.sender, "You are not admin");
        _complete(order, _orderID);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAlleleEscrow {

    event MarketAdded(uint256 indexed marketID, uint256 indexed tokenID, uint256 indexed generation, uint256 amount, uint256 price, address seller);
    event OrderCreated(uint256 indexed orderID, uint256 indexed tokenID, uint256 indexed generation, address buyer, address seller, uint256 amount, uint256 price, string marketURI);
    event OrderProceed(uint256 indexed orderID);
    event OrderShipped(uint256 indexed orderID, address indexed distributor);
    event OrderDerlivered(uint256 indexed orderID);
    event OrderCompleted(uint256 indexed orderID);
    event OrderDisputed(uint256 indexed orderID, string reason);
    event OrderCancelled(uint256 indexed orderID, string reason);

    enum DeliveryStatus {
        PENDING,
        PROCESSING,
        SHIPPED,
        DELIVERED,
        CANCELLED,
        DISPUTED,
        COMPLETED
    }

    struct Order {
        uint tokenId;
        uint generation;
        uint price;
        uint deliveryCharge;
        uint amount;
        address seller;
        address buyer;
        address distributor;
        string metadataURI;
        DeliveryStatus status;
    }

    struct Market {
        uint tokenID;
        uint generation;
        uint price;
        address seller;
        uint amount;
    }

    function sell(uint256 _tokenID,
        uint256 _generation,
        uint256 _amount,
        uint256 _price) external;

    function buy(uint256 _marketID, uint256 _amount, string memory _metadataURI) external;

    function startProcessing(uint256 _orderID) external;

    function markAsShipped(uint _orderID, address _distributor) external;

    function delivered(uint256 _orderID) external;

    function completeByBuyer(uint256 _orderID) external;

    function completeByAdmin(uint256 _orderID) external;

    function dispute(uint256 _orderID, string memory _reasonURI) external;

    function cancel(uint256 _orderID, string memory _reasonURI) external;

    function getOrder(uint256 _orderID) external view returns(Order memory);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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