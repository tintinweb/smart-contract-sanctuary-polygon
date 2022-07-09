/**
 *Submitted for verification at polygonscan.com on 2022-07-08
*/

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

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


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


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// File: Collection.sol

//SPDX-License-Identifier: UNLICENSED

/// @title Simple Marketplace Collection contract
/// @author Ace
/// @notice This contract represents a single collection in a custodial marketplace
/// @dev Use this contract with factory to create a complete marketplace

pragma solidity ^0.8.0;




contract Collection is Ownable{

    // IERC721 NFT;
    IERC20 PaymentToken;

    struct directListing{
        address owner;
        uint price;
    }

    struct auctionListing{
        address owner;
        uint duration;
        uint timeEnd;
        uint highestBid;
        address highestBidder;
    }

    struct collectionInfo{
        address creator;
        uint royaltyPercentage;
        uint royaltyBalance;
    }

    uint public FEE = 200; //2% since we divide by 10_000
    uint public FEEBalance;
    uint public differentialAmount = 1 ether;

    mapping(address=>bool) public isApproved;
    mapping(address=>bool) public whitelistContracts;
    mapping(address=>collectionInfo) public royaltyInfo;

    mapping(address=>mapping(uint=>uint)) public listed; //0 - not, 1 = direct, 2 = auction

    mapping(address=>mapping(uint=>directListing)) public directSales;
    mapping(address=>mapping(uint=>auctionListing)) public auctionSales;

    event tokenListed(address indexed _contract,address indexed owner,uint indexed tokenId,uint8 listingType,uint price,uint duration);
    event tokenBought(address indexed _contract,address indexed buyer,uint indexed tokenId);
    event receivedBid(address indexed _contract,address indexed bidder,uint indexed tokenId,uint amount);
    event tokenDeListed(address indexed _contract,uint indexed tokenId,uint8 listingType);
    event marketplaceStarted(address indexed _contract,address indexed creator,uint royaltyPercentage);

    constructor(address _paymentToken) {
        PaymentToken = IERC20(_paymentToken);
    }

    //@notice direct listing
    function listToken(address _contract,uint tokenId,uint price) external {
        require(whitelistContracts[_contract],"Contract not listed");
        IERC721 NFT = IERC721(_contract);
        require(NFT.ownerOf(tokenId) == msg.sender,"Not owner");
        require(price != 0,"Can't sell for free");
        NFT.transferFrom(msg.sender, address(this), tokenId);
        listed[_contract][tokenId] = 1;
        directSales[_contract][tokenId] = directListing(msg.sender,price);
        emit tokenListed(_contract,msg.sender, tokenId,1,price,0);
    }

    //@notice auction listing
    function listToken(address _contract,uint tokenId,uint price,uint duration) external {
        require(whitelistContracts[_contract],"Contract not listed");
        IERC721 NFT = IERC721(_contract);
        require(NFT.ownerOf(tokenId) == msg.sender,"Not owner");
        require(duration < 14 days,"Auction can't last more than 14 days");
        require(price != 0,"Can't start at 0");
        NFT.transferFrom(msg.sender,address(this),tokenId);
        listed[_contract][tokenId] = 2;
        auctionSales[_contract][tokenId] = auctionListing(msg.sender,duration,0,price,address(0));
        emit tokenListed(_contract,msg.sender, tokenId,2,price,duration);
    }

    function buyToken(address _contract,uint tokenId) external {
        IERC721 NFT = IERC721(_contract);
        require(listed[_contract][tokenId] == 1,"Token not direct listed");
        directListing storage listing = directSales[_contract][tokenId];
        require(listing.owner != msg.sender,"Can't buy own token");
        // require(amount >= listing.price,"Not enough paid");
        require(PaymentToken.transferFrom(msg.sender,address(this),listing.price),"Payment not received");
        uint fee = listing.price * FEE/10_000;
        uint royalty = listing.price * royaltyInfo[_contract].royaltyPercentage / 10_000;
        PaymentToken.transfer(listing.owner,listing.price-fee-royalty);
        FEEBalance += fee;
        royaltyInfo[_contract].royaltyBalance += royalty;
        NFT.transferFrom(address(this),msg.sender,tokenId);
        delete directSales[_contract][tokenId];
        delete listed[_contract][tokenId];
        emit tokenBought(_contract,msg.sender,tokenId);
    }

    function bidToken(address _contract,uint tokenId,uint amount) external {
        require(listed[_contract][tokenId] == 2,"Token not auction listed");
        auctionListing storage listing = auctionSales[_contract][tokenId];
        require(listing.owner != msg.sender,"Can't buy own token");
        require(msg.sender != listing.highestBidder,"Can't bid twice");
        require(block.timestamp < listing.timeEnd || listing.timeEnd == 0,"Auction over");
        if(listing.highestBidder != address(0)){
            require(amount >= listing.highestBid + differentialAmount,"Bid higher");
            PaymentToken.transfer(listing.highestBidder,listing.highestBid);
        }
        else{
            require(amount >= listing.highestBid,"Bid higher");
            listing.timeEnd = block.timestamp + listing.duration;
        }
        require(PaymentToken.transferFrom(msg.sender, address(this), amount),"Payment not made");
        listing.highestBid = amount;
        listing.highestBidder = msg.sender;
        emit receivedBid(_contract,msg.sender,tokenId,amount);
    }

    function retrieveToken(address _contract,uint tokenId) external{
        IERC721 NFT = IERC721(_contract);
        require(listed[_contract][tokenId] == 2,"Token not auction listed");
        auctionListing storage listing = auctionSales[_contract][tokenId];
        require(block.timestamp >= listing.timeEnd,"Auction not over");
        require(listing.highestBidder != address(0),"Token not sold");
        require(msg.sender == listing.highestBidder || msg.sender == listing.owner,"Not highest bidder or owner");  
        uint fee = listing.highestBid * FEE/10_000;
        uint royalty = listing.highestBid * royaltyInfo[_contract].royaltyPercentage/10_000;
        PaymentToken.transfer(listing.owner,listing.highestBid-fee-royalty);
        FEEBalance += fee;
        royaltyInfo[_contract].royaltyBalance += royalty;
        NFT.transferFrom(address(this),listing.highestBidder,tokenId);
        emit tokenBought(_contract,listing.highestBidder,tokenId);
        delete auctionSales[_contract][tokenId];
        delete listed[_contract][tokenId];
    }

    function delistToken(address[] calldata _contract,uint[] calldata tokenId) external{
        uint length = tokenId.length;
        for(uint i=0;i<length;i++){
            require(listed[_contract[i]][tokenId[i]] != 0,"Token not listed");
            IERC721 NFT = IERC721(_contract[i]);
            if(listed[_contract[i]][tokenId[i]] == 1){
                require(directSales[_contract[i]][tokenId[i]].owner == msg.sender,"Not owner");
                NFT.transferFrom(address(this),msg.sender,tokenId[i]);
                delete directSales[_contract[i]][tokenId[i]];
                delete listed[_contract[i]][tokenId[i]];
                emit tokenDeListed(_contract[i],tokenId[i], 1);
            }
            else{
                require(auctionSales[_contract[i]][tokenId[i]].owner == msg.sender,"Not owner");
                require(auctionSales[_contract[i]][tokenId[i]].timeEnd > block.timestamp || auctionSales[_contract[i]][tokenId[i]].highestBidder == address(0),"Auction over or received bids");
                NFT.transferFrom(address(this),msg.sender,tokenId[i]);
                if(auctionSales[_contract[i]][tokenId[i]].highestBidder != address(0)){
                    PaymentToken.transfer(auctionSales[_contract[i]][tokenId[i]].highestBidder,auctionSales[_contract[i]][tokenId[i]].highestBid);
                }
                delete auctionSales[_contract[i]][tokenId[i]];
                delete listed[_contract[i]][tokenId[i]];
                emit tokenDeListed(_contract[i],tokenId[i],2);
            }
        }
    }

    function whitelistContract(address _contract,bool _whitelist) external onlyOwner{
        whitelistContracts[_contract] = _whitelist;
    }

    function retrieveFee(address _to) external {
        require(msg.sender == owner() || isApproved[msg.sender],"Not owner or approved");
        uint amount = FEEBalance;
        FEEBalance = 0;
        PaymentToken.transfer(_to,amount);
    }

    function setMarketplace(address _contract,address _creator,uint royaltyPercentage) external onlyOwner{
        royaltyInfo[_contract] = collectionInfo(_creator,royaltyPercentage,0);
        whitelistContracts[_contract] = true;
        emit marketplaceStarted(_contract, _creator, royaltyPercentage);
    }

    function editMarketplace(address _contract,address _creator,uint royaltyPercentage) external onlyOwner{
        royaltyInfo[_contract].creator = _creator;
        royaltyInfo[_contract].royaltyPercentage = royaltyPercentage;
    }

    function setApproved(address _address,bool _approve) external onlyOwner{
        isApproved[_address] = _approve;
    }

    function retrieveRoyalty(address _contract,address _to) external {
        require(royaltyInfo[_contract].creator == msg.sender,"Not creator");
        uint amount = royaltyInfo[_contract].royaltyBalance;
        royaltyInfo[_contract].royaltyBalance = 0;
        PaymentToken.transfer(_to,amount);
    }

    function setPaymentToken(address _token) external onlyOwner{
        PaymentToken = IERC20(_token);
    }

    function setFee(uint _fee) external onlyOwner{
        FEE = _fee;
    }

    function setPriceDifferential(uint _amount) external onlyOwner{
        differentialAmount = _amount;
    }

}