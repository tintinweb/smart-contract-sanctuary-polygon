/**
 *Submitted for verification at polygonscan.com on 2022-10-06
*/

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// File: erc721a/contracts/IERC721A.sol


// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// File: escrow.sol


pragma solidity ^0.8.0;





contract EscrowServices is Ownable, Pausable, IERC721Receiver {
    // =============================================================
    //                            STORAGE
    // =============================================================
    // Address receiving escrow fees
    address feeCollectorAddress;
    // Protocol Fee
    uint256 public FEE = 75;
    // Created escrow number
    uint256 public counter;

    // Escrow ID <-> Escrow mapping
    mapping(bytes32 => Escrow) nftEscrowList;
    // Wallet <-> Escrow ID mapping
    mapping(address => bytes32[]) ownerEscrowMapping;

    // =============================================================
    //                      enums
    // =============================================================

    // List of escrow actions
    enum Action {
        CREATE,
        BUY,
        CANCEL
    }
    // List of project states
    enum EscrowState {
        NFT_DEPOSITED, // 1
        CANCEL_NFT, // 1.1
        ETH_DEPOSITED, // 2
        CANCELED_BEFORE_DELIVERY, // 2.1
        DELIVERY_INITIATED, // 3        
        DELIVERED // 4
    }

    struct Escrow {
        bytes32 id;
        uint256 tokenId;
        address nftContractAddress;
        uint256 price;
        uint256 deliveryInitTimeStamp;
        address sellerAddress;
        address buyerAddress;
        EscrowState escrowState;
        bool buyerCancel;
        bool sellerCancel;
    }

    // =============================================================
    //                      Events
    // =============================================================
    event EscrowEvent(
        address indexed _from,
        bytes32 indexed _id,
        uint8 _action
    );

    constructor() {

    }

    // =============================================================
    //                      Methods
    // =============================================================

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev Creates as Escrow.
     *
     * @param _id ID of the escrow.
     * @param _tokenId NFT ID.
     * @param _nftContractAddress NFT contract contract address.
     * @param _price Price of the nft set by seller, cannot be zero.
     */
    function createEscrow(
        bytes32 _id,
        uint256 _tokenId,
        address _nftContractAddress,
        // uint256 calldata _nftQuantity,
        uint256 _price
    ) external whenNotPaused {
        require(
            nftEscrowList[_id].id != _id,"Escrow already exists!");
        require(_price > 0, "Price must be greater than zero!");

        Escrow memory localEscrow = Escrow({
            id: _id,
            tokenId: _tokenId,
            nftContractAddress: _nftContractAddress,
            // _nftQuantity: _nftQuantity,
            price: _price,
            deliveryInitTimeStamp: 0,
            sellerAddress: msg.sender,
            buyerAddress: address(0),
            escrowState: EscrowState.NFT_DEPOSITED,
            buyerCancel: false,
            sellerCancel: false
        });
        counter++;

        ownerEscrowMapping[msg.sender].push(_id);
        nftEscrowList[_id] = localEscrow;

        IERC721A erc721aNFT = IERC721A(address(_nftContractAddress));
        require(erc721aNFT.ownerOf(_tokenId) == msg.sender, "Not Owner");
        erc721aNFT.safeTransferFrom(msg.sender, address(this), _tokenId);

        emit EscrowEvent(msg.sender, _id, uint8(Action.CREATE));
    }

    /**
     * @dev Creates Escrow.
     *
     * @param _id ID of the escrow.
     * Only seller can call it. While calling it the Escrow state must be 'EscrowState.NFT_DEPOSITED'.
     */
    function cancelEscrow(bytes32 _id) public {
        Escrow memory localEscrow = nftEscrowList[_id];
        require(localEscrow.sellerAddress == msg.sender, "Not Seller!");
        require(localEscrow.escrowState == EscrowState.NFT_DEPOSITED, 'Cannot Cancel at this stage');

        localEscrow.escrowState = EscrowState.CANCEL_NFT;
        IERC721A(address(localEscrow.nftContractAddress)).safeTransferFrom(address(this), msg.sender, localEscrow.tokenId);

        nftEscrowList[_id] = localEscrow;

        emit EscrowEvent(msg.sender, _id, uint8(Action.CANCEL));
    }

    /**
     * @dev Buyer deposits ETH for escrow of nft, it wishes to buy.
     *
     * @param _id ID of the escrow.
     * Requires the amount ETH must be greater equal to price of nft.
     */
    function depositeETH(bytes32 _id) public payable {
        require(msg.value >= nftEscrowList[_id].price, 'Cannot buy with price');
        nftEscrowList[_id].buyerAddress = payable(msg.sender);
        nftEscrowList[_id].escrowState = EscrowState.ETH_DEPOSITED;
    }

    /**
     * @dev Cancels escrow selling process of the product before initiation of the delivery.
     *
     * @param _id ID of the escrow.
     * Both seller and buyer must call it to cancel the deal. While calling it the Escrow state must be 'EscrowState.ETH_DEPOSITED'.
     * Ethers must be deposited by buyer already for this escrow.
     */
    function cancelBeforeDelivery(bytes32 _id) public {
        Escrow memory localEscrow = nftEscrowList[_id];

        require(msg.sender == localEscrow.buyerAddress || msg.sender == localEscrow.sellerAddress, "Unknow caller!");
        require(localEscrow.escrowState == EscrowState.ETH_DEPOSITED, '1- Ethers not deposited');
       
        if (msg.sender == localEscrow.buyerAddress){
            localEscrow.sellerCancel = true;
            nftEscrowList[_id] = localEscrow;

        }
        else{
            localEscrow.buyerCancel = true;
            nftEscrowList[_id] = localEscrow;
        }

         if (localEscrow.sellerCancel && localEscrow.buyerCancel){
            // Transfer ownership back to seller and transefer ether to buyer
            localEscrow.escrowState = EscrowState.CANCELED_BEFORE_DELIVERY;
            
            IERC721A(localEscrow.nftContractAddress).safeTransferFrom(address(this),
                localEscrow.sellerAddress, localEscrow.tokenId);
            payable(localEscrow.buyerAddress).transfer(localEscrow.price);

            nftEscrowList[_id] = localEscrow;
        }
    }

    /**
     * @dev Initiates the delivery of the product.
     *
     * @param _id ID of the escrow.
     * Only seller can call it. While calling it the Escrow state must be 'EscrowState.ETH_DEPOSITED'.
     * Ethers must be deposited by buyer already for this escrow.
     */
    function initiateDelivery(bytes32 _id) public {
        Escrow memory localEscrow = nftEscrowList[_id];
    
        require(localEscrow.sellerAddress == msg.sender, "Not Seller!");
        require(localEscrow.escrowState == EscrowState.ETH_DEPOSITED, '2- Ethers not deposited');
        require(!localEscrow.buyerCancel && !localEscrow.sellerCancel, 'Dispute!!!');

        localEscrow.escrowState = EscrowState.DELIVERY_INITIATED;
        localEscrow.deliveryInitTimeStamp = block.timestamp;
        nftEscrowList[_id] = localEscrow;
    }

    /**
    * @dev Confirms the delivery of the product. As buyer confirms the delivery ownership of
    * the nft will be transfered from escrow to buyer. Seller will the the amount of price in ETH.
    *
    * @param _id ID of the escrow.
    * Buyer will call as receives the delivery. While calling it the Escrow state must be 'EscrowState.DELIVERY_INITIATED'.
    * If Buyer does not call it, seller can confirm delivery after 7 days.
    */
    function confirmDelivery(bytes32 _id) public {
        Escrow memory localEscrow = nftEscrowList[_id];
        require(localEscrow.escrowState == EscrowState.DELIVERY_INITIATED, 'Initiate delivery first!');
        
        if (msg.sender == localEscrow.buyerAddress) {
            nftEscrowList[_id].escrowState = EscrowState.DELIVERED;
            // Transfer ownership to buyer and transefer ether to seller
            IERC721A(localEscrow.nftContractAddress).safeTransferFrom(address(this), localEscrow.buyerAddress, localEscrow.tokenId);
            payable(nftEscrowList[_id].sellerAddress).transfer(nftEscrowList[_id].price);
        } else {
            // if Not buyer check for 7 days condition
            require(block.timestamp >= localEscrow.deliveryInitTimeStamp + 7 days, "Connot confirm now!");
            
            localEscrow.escrowState = EscrowState.DELIVERED;

            nftEscrowList[_id] = localEscrow;
            // Transfer ownership back to buyer and transefer ether to seller
            IERC721A(localEscrow.nftContractAddress).safeTransferFrom(address(this), localEscrow.buyerAddress, localEscrow.tokenId);
            payable(localEscrow.sellerAddress).transfer(localEscrow.price);
        }
    }

    // =============================================================
    //                      Privileged actions
    // =============================================================

    function changeFeeCollectorAddress(address _adr) external onlyOwner {
        feeCollectorAddress = _adr;
    }

    function changeFee(uint256 _fee) external onlyOwner{
        require(_fee <= 100); // 100 = 1%
        FEE = _fee;
    }
}