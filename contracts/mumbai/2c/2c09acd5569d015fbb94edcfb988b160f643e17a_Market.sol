/**
 *Submitted for verification at polygonscan.com on 2022-11-30
*/

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

// File: .deps/market.sol


pragma solidity ^0.8.7;





error ItemNotForSale(address nftAddress, uint256 tokenId);
error NotListed(address nftAddress, uint256 tokenId);
error AlreadyListed(address nftAddress, uint256 tokenId);
error NoProceeds();
error NotOwner();
error NotApproved();
error NoFreeSales();
error NotEnoughCoin();
error NotEnoughCoinApproved();

error RaffleDoesNotExist(uint256 ID);
error RaffleAlreadyExists(uint256 ID);
error AlreadyMaxEntry();
error WillExceedMaxEntry();
error NoZeroEntry();
error TooManyEntries();
error RaffleNotLive();

contract Market is ReentrancyGuard, Ownable {
    address public coinAddress = 0x5e98f08e4C2b80474a655649cFF4eB5fAB1EA78E;

    function setCoin(address _coinAddress) public onlyOwner {
        coinAddress = _coinAddress;
    }

    //RAFFLE
    struct Raffle { 
        uint256 price;
        uint256 maxPerWallet;
        uint256 numEntries;
        uint256 maxTotalEntries;
        bool raffleLive;
    }

    struct RaffleEntry {
        uint256 entries;
    }

    event RaffleCreated (
        uint256 indexed id,
        uint256 price,
        uint256 maxPerWallet,
        uint256 maxTotalEntries
    );

    event WinnerDrawn (
        uint256 indexed raffleId,
        uint256 indexed winnerId,
        address indexed winnerAddress
    );


    event RaffleEntered (
        uint256 indexed id,
        uint256 entries
    );

    event RaffleCanceled (
        uint256 indexed id
    );


    mapping(uint256 => Raffle) private s_raffles; 
    mapping(uint256 => mapping(address => RaffleEntry)) private s_raffleentries; 
    mapping(uint256 => mapping(uint256 => address)) private s_entryList; 
    

    modifier raffleExistsForDelete(uint256 id) {
        Raffle memory raffle = s_raffles[id];
        if (raffle.price <= 0) {
            revert RaffleDoesNotExist(id);
        }
        _;
    }

    modifier raffleExists(uint256 id) {
        Raffle memory raffle = s_raffles[id];
        if (raffle.price > 0) {
            revert RaffleAlreadyExists(id);
        }
        _;
    }
    
    function createRaffle(
        uint256 id,
        uint256 price,
        uint256 maxPerWallet,
        uint256 maxTotalEntries
    )
        external
        onlyOwner
        raffleExists(id)
    { 
        if (price <= 0) {
            revert NoFreeSales(); 
        }
        s_raffles[id] = Raffle(price, maxPerWallet, 0, maxTotalEntries, true);
        emit RaffleCreated(id, price, maxPerWallet, maxTotalEntries);
    }

    function getRaffle(uint256 raffleId)
        external
        view
        returns (Raffle memory)
    {
        return s_raffles[raffleId];
    }

    function getEntries(uint256 raffleId, address addy)
        external
        view
        returns (RaffleEntry memory)
    {
        return s_raffleentries[raffleId][addy];
    }

    function setRafflePauseState(uint256 raffleId)
        external
        onlyOwner
        raffleExistsForDelete(raffleId)
    {
        s_raffles[raffleId].raffleLive = !s_raffles[raffleId].raffleLive;
    }

    function setRafflePrice(uint256 raffleId, uint256 newPrice)
        external
        onlyOwner
        raffleExistsForDelete(raffleId)
    {
        s_raffles[raffleId].price = newPrice;
    }

    function setRaffleMaxPerWallet(uint256 raffleId, uint256 newMax)
        external
        onlyOwner
        raffleExistsForDelete(raffleId)
    {
        s_raffles[raffleId].maxPerWallet = newMax;
    }

    function setRaffleMaxEntries(uint256 raffleId, uint256 newMax)
        external
        onlyOwner
        raffleExistsForDelete(raffleId)
    {
        s_raffles[raffleId].maxTotalEntries = newMax;
    }

    function deleteRaffle(uint256 raffleId)
        external
        onlyOwner
        raffleExistsForDelete(raffleId)    
    {
        delete (s_raffles[raffleId]);
        emit RaffleCanceled(raffleId);
    }

    function joinRaffle(uint256 raffleId, uint256 entryCount)
        external
        nonReentrant
        raffleExistsForDelete(raffleId)
    { 
        Raffle memory raffle = s_raffles[raffleId];
        uint256 totalEntries = raffle.numEntries;

        uint256 currentUserNumEntries = s_raffleentries[raffleId][msg.sender].entries;
        uint256 buyerBalance = IERC20(coinAddress).balanceOf(msg.sender);


        if(!raffle.raffleLive){
            revert RaffleNotLive();
        }

        if(raffle.numEntries + entryCount > raffle.maxTotalEntries){
            revert TooManyEntries(); 
        }

        if(currentUserNumEntries == raffle.maxPerWallet){ 
            revert AlreadyMaxEntry();
        }

        if(currentUserNumEntries + entryCount > raffle.maxPerWallet){
            revert WillExceedMaxEntry(); 
        }
        
        if(entryCount <= 0){
            revert NoZeroEntry(); 
        }

        if(buyerBalance < (raffle.price * entryCount)) { 
            revert NotEnoughCoin();
        }
        if (IERC20(coinAddress).allowance(msg.sender, address(this)) < (raffle.price * entryCount)) {
            revert NotEnoughCoinApproved(); 
        }

        for(uint256 i = 1; i <= entryCount; i++) {
            s_entryList[raffleId][i + totalEntries] = msg.sender;
        }

        s_raffleentries[raffleId][msg.sender].entries += entryCount; 
        s_raffles[raffleId].numEntries += entryCount;
        IERC20(coinAddress).transferFrom(msg.sender, address(this), (raffle.price * entryCount));
        emit RaffleEntered(raffleId, entryCount);
    }
    

    function drawRaffle(uint256 raffleId, uint256 seed)
        external
        onlyOwner
        raffleExistsForDelete(raffleId)
        returns(address)
    { //draw the winner of a raffle
        //todo
        Raffle memory raffle = s_raffles[raffleId];
        uint256 totalEntries = raffle.numEntries;

        uint256 draw = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, totalEntries, raffleId, seed)));

        uint256 winner = draw % totalEntries;
        while (winner == 0){
            winner = draw % totalEntries;
        }
        emit WinnerDrawn(raffleId, winner, s_entryList[raffleId][winner]);
        return address(s_entryList[raffleId][winner]);

    }

    //NFT Sales
    struct Listing {
        uint256 price;
        address seller;
    }

    event ItemListed(
        address indexed seller, 
        address indexed nftAddress,
        uint256 indexed tokenId, 
        uint256 price
    );

    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    mapping(address => mapping(uint256 => Listing)) private s_listings; 

    modifier isOwner( 
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress); 
        address owner = nft.ownerOf(tokenId); 
        if (spender != owner) {
            revert NotOwner(); 
        }
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert NotListed(nftAddress, tokenId);
        }
        _;
    }

    modifier notListed(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        onlyOwner
        isOwner(nftAddress, tokenId, msg.sender) 
        notListed(nftAddress, tokenId, msg.sender) 
    { 
        if (price <= 0) {
            revert NoFreeSales(); 
        }
        IERC721 nft = IERC721(nftAddress); 
        if (nft.getApproved(tokenId) != address(this)) {
            revert NotApproved(); 
        }
        s_listings[nftAddress][tokenId] = Listing(price, msg.sender); 
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    function getListing(address nftAddress, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return s_listings[nftAddress][tokenId];
    }

    function updateListing(
            address nftAddress,
            uint256 tokenId,
            uint256 newPrice
        )
            external
            onlyOwner
            isListed(nftAddress, tokenId)
            nonReentrant
            isOwner(nftAddress, tokenId, msg.sender)
    {
        if (newPrice == 0) {
            revert NoFreeSales();
        }

        s_listings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
    }

    function deleteItem(address nftAddress, uint256 tokenId)
        external
        onlyOwner
        isOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId)    
    {  
        delete (s_listings[nftAddress][tokenId]);
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }

    function buyItem(address nftAddress, uint256 tokenId)
        external
        isListed(nftAddress, tokenId)
        nonReentrant
        { 
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        uint256 buyerBalance = IERC20(coinAddress).balanceOf(msg.sender);
        if(buyerBalance < listedItem.price) {
            revert NotEnoughCoin();
        }
        if (IERC20(coinAddress).allowance(msg.sender, address(this)) < listedItem.price) {
            revert NotEnoughCoinApproved();
        }

        delete (s_listings[nftAddress][tokenId]);
        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        IERC20(coinAddress).transferFrom(msg.sender, address(this), listedItem.price);
    
        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
        }
}