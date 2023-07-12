/**
 *Submitted for verification at polygonscan.com on 2023-07-11
*/

/**
 *Submitted for verification at BscScan.com on 2023-07-07
*/

/**
 *Submitted for verification at polygonscan.com on 2023-05-01
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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

contract Auction is Ownable, IERC721Receiver {
    uint256 public id;
    address public immutable paymentToken;
    uint256 public projectCut;

    /**
     * @notice A struct that contains the details of a specific order.
     * @param creator The address of the user who created the order.
     * @param NFT The address of the NFT contract being traded in the order.
     * @param tokenID The ID of the NFT being traded in the order.
     * @param price The initial price of the order.
     * @param endTime The timestamp indicating when the order ends.
     */
    struct Order {
        address creator;
        address NFT;
        uint256 tokenID;
        uint256 price;
        uint256 endTime;
    }

    /**
     * @notice A struct that contains the details of a specific bid.
     * @param bidder The address of the user who made the bid.
     * @param amount The amount of the bid.
     */
    struct Bid {
        address bidder;
        uint256 amount;
    }

    /**
     * @notice A mapping that tracks the current highest bid for a given order ID.
     * @dev The key is the order ID and the value is a `Bid` struct that contains the bidder's address and bid amount.
     */
    mapping(uint256 => Bid) public bid;

    /**
     * @notice A mapping that tracks the details of a specific order.
     * @dev The key is the order ID and the value is an `Order` struct that contains the creator's address, the NFT contract address, the NFT ID, the initial price, and the end time.
     */
    mapping(uint256 => Order) public order;

    /**
     * @notice A mapping that tracks whether a specific NFT contract is allowed to be traded on this marketplace.
     * @dev The key is the NFT contract address and the value is a boolean indicating whether the contract is allowed.
     */
    mapping(address => bool) public allowedNFT;

    /**
     * @dev Emitted when the percentage of the project cut changes.
     * @param previousValue The previous value of the project cut percentage.
     * @param newValue The new value of the project cut percentage.
     * @param timestamp The timestamp when the event was emitted.
     */
    event ProjectCutUpdated(
        uint256 previousValue,
        uint256 newValue,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a new NFT address is added to the contract.
     * @param NFTAddress The address of the new NFT contract.
     * @param timestamp The timestamp when the event was emitted.
     */
    event NFTAddressAdded(address indexed NFTAddress, uint256 timestamp);

    /**
     * @dev Emitted when an NFT address is removed from the contract.
     * @param NFTAddress The address of the NFT contract that was removed.
     * @param timestamp The timestamp when the event was emitted.
     */
    event NFTAddressRemoved(address indexed NFTAddress, uint256 timestamp);

    /**
     * @dev Emitted when a new order is created.
     * @param _orderId The ID of the new order.
     * @param _order The order data.
     * @param timestamp The timestamp when the event was emitted.
     */
    event OrderCreated(
        uint256 indexed _orderId,
        Order _order,
        uint256 timestamp
    );

    /**
     * @dev Emitted when an order is removed.
     * @param _orderId The ID of the order that was removed.
     * @param _order The order data.
     * @param timestamp The timestamp when the event was emitted.
     */
    event OrderRemoved(
        uint256 indexed _orderId,
        Order _order,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a new bid is placed on an order.
     * @param _orderId The ID of the order that the bid was placed on.
     * @param _bidder The address of the bidder who placed the bid.
     * @param amount The amount of the bid.
     * @param timestamp The timestamp when the event was emitted.
     */
    event BidPlaced(
        uint256 indexed _orderId,
        address indexed _bidder,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @dev Emitted when an order is claimed by a bidder.
     * @param _orderId The ID of the order that was claimed.
     * @param _bidder The address of the bidder who claimed the order.
     * @param timestamp The timestamp when the event was emitted.
     */
    event Claimed(
        uint256 indexed _orderId,
        address indexed _bidder,
        uint256 timestamp
    );

    /**
     * @notice Creates an Auction contract instance.
     * @param _NFTs an array of ERC721 token addresses allowed to be traded in this contract.
     * @param _paymentToken the ERC20 token address used for bidding and payment.
     * @dev Throws a require error if `_paymentToken` is the zero address.
     */
    constructor(
        address[] memory _NFTs,
        address _paymentToken,
        uint256 _projectCut
    ) {
        require(_paymentToken != address(0), "Zero payment token address");
        paymentToken = _paymentToken;
        addNFTs(_NFTs);
        setProjectCut(_projectCut);
    }

    /**
     * @dev Updates the project cut on each sale.
     * @param _projectCut New project cut amount.
     */
    function setProjectCut(uint256 _projectCut) public onlyOwner {
        require(_projectCut <= 1500, "Invalid Project Cut");
        uint256 previousValue = projectCut;
        projectCut = _projectCut;
        emit ProjectCutUpdated(previousValue, _projectCut, block.timestamp);
    }

    /**
     * @dev Adds multiple ERC721 contracts to the allowed list.
     * @param _NFTs Array of ERC721 contract addresses to be added.
     */
    function addNFTs(address[] memory _NFTs) public onlyOwner {
        require(_NFTs.length > 0, "Zero NFTs length");
        for (uint i; i < _NFTs.length; ) {
            try
                IERC721(_NFTs[i]).supportsInterface(type(IERC721).interfaceId)
            returns (bool value) {
                require(value, "Non ERC721 implementer");
                allowedNFT[_NFTs[i]] = true;
                emit NFTAddressAdded(_NFTs[i], block.timestamp);
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Not a ERC721 standard contract");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Removes multiple ERC721 contracts from the allowed list.
     * @param _NFTs Array of ERC721 contract addresses to be removed.
     */
    function removeNFTs(address[] calldata _NFTs) external onlyOwner {
        require(_NFTs.length > 0, "Zero NFTs length");
        for (uint i; i < _NFTs.length; ) {
            allowedNFT[_NFTs[i]] = false;
            emit NFTAddressRemoved(_NFTs[i], block.timestamp);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Creates an order for a specific NFT token.
     * @param _NFT The address of the NFT contract.
     * @param _tokenId The ID of the NFT token.
     * @param _price The price of the NFT token in the payment token.
     * @param _endTime The timestamp when the order expires.
     * @return Returns a boolean indicating if the order was successfully created.
     * @notice The NFT must be allowed by the marketplace contract and the price and end time must be valid.
     * @notice Transfers the ownership of the NFT token from the caller to the marketplace contract.
     */

    function createOrder(
        address _NFT,
        uint256 _tokenId,
        uint256 _price,
        uint256 _endTime
    ) external returns (bool) {
        require(allowedNFT[_NFT], "Invalid NFT address");
        require(_price > 0, "Zero price");
        require(_endTime > block.timestamp, "Invalid end time");
        order[id] = Order(msg.sender, _NFT, _tokenId, _price, _endTime);
        emit OrderCreated(id, order[id], block.timestamp);
        id++;
        IERC721(_NFT).safeTransferFrom(msg.sender, address(this), _tokenId, "");
        return true;
    }

    /**
     * @notice Removes an order for a specific order ID.
     * @dev Only the creator of the order can remove it, provided no bid exists for it.
     * @param _orderId The ID of the order to be removed.
     * @return A boolean indicating whether the order was successfully removed.
     * @dev Throws an error if the order ID is invalid, or if the order has already been removed.
     * @dev Throws an error if the caller is not the creator of the order, or if a bid already exists for the order.
     */
    function removeOrder(uint256 _orderId) external returns (bool) {
        require(_orderId < id, "Invalid Order ID");
        Order memory _order = order[_orderId];
        Bid memory _bid = bid[_orderId];
        require(_order.NFT != address(0), "Order removed already");
        require(_order.creator == msg.sender, "Not the creator");
        require(_bid.bidder == address(0), "Bid exists");
        IERC721(_order.NFT).safeTransferFrom(
            address(this),
            msg.sender,
            _order.tokenID,
            ""
        );
        emit OrderRemoved(_orderId, _order, block.timestamp);
        delete order[_orderId];
        return true;
    }

    /**
     * @notice Places a bid on a specific order ID with a given amount.
     * @param _orderId The ID of the order to place the bid on.
     * @param amount The amount of tokens to bid.
     * @return A boolean indicating whether the bid was successfully placed.
     * @dev Throws an error if the order ID is invalid, or if the order has already been removed or has ended.
     * @dev Throws an error if the bid amount is not higher than the current maximum bid or the initial price.
     * @dev If the bid is the first for the order, it sets a new end time 48 hours from the current block timestamp.
     * @dev If the bid is not the first, it transfers the tokens back to the previous bidder before updating the new bid.
     * @dev Transfers the bid amount from the bidder to this contract.
     */
    function placeBid(
        uint256 _orderId,
        uint256 amount
    ) external returns (bool) {
        require(_orderId < id, "Invalid Order ID");
        Order memory _order = order[_orderId];
        Bid memory _bid = bid[_orderId];
        require(_order.creator != address(0), "Order removed");
        require(_order.endTime >= block.timestamp, "Sale ended");
        require(msg.sender != _order.creator, "Creator can't place a bid");
        require(
            amount > _bid.amount && amount >= _order.price,
            "Bid amount should be higher than current max bid or initial price"
        );

        if (_bid.bidder == address(0)) {
            order[_orderId].endTime = block.timestamp + 48 hours;
        } else {
            IERC20(paymentToken).transfer(_bid.bidder, _bid.amount);
        }
        bid[_orderId] = Bid(msg.sender, amount);
        IERC20(paymentToken).transferFrom(msg.sender, address(this), amount);
        emit BidPlaced(_orderId, msg.sender, amount, block.timestamp);
        return true;
    }

    /**
     * @notice Claims an NFT and transfers the bid amount to the creator of a specific order ID.
     * @param _orderId The ID of the order to claim.
     * @return A boolean indicating whether the claim was successful.
     * @dev Throws an error if the order ID is invalid, or if the sale has not yet ended or if no bid exists.
     * @dev Transfers the bid amount to the creator of the order and transfers the NFT to the bidder.
     * @dev Removes the order and bid data from the mappings.
     */
    function claim(uint256 _orderId) external returns (bool) {
        require(_orderId < id, "Invalid Order ID");
        Order memory _order = order[_orderId];
        Bid memory _bid = bid[_orderId];
        require(_order.endTime < block.timestamp, "Sale not ended yet");
        require(_bid.bidder != address(0), "No bid exists");

        if (projectCut > 0) {
            uint256 projectShare = (_bid.amount * projectCut) / 10000;
            IERC20(paymentToken).transfer(owner(), projectShare);
            _bid.amount -= projectShare;
        }

        IERC20(paymentToken).transfer(_order.creator, _bid.amount);
        IERC721(_order.NFT).safeTransferFrom(
            address(this),
            _bid.bidder,
            _order.tokenID,
            ""
        );

        emit Claimed(_orderId, _bid.bidder, block.timestamp);

        delete order[_orderId];
        delete bid[_orderId];
        return true;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}