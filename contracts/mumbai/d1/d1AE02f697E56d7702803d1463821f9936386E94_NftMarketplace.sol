// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NftMarketplace is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    // --- VARIABLES ---

    address payable walletAddress;
    IERC721 nftContractAddress;
    IERC20 tokenContractAddress;

    uint256 listingFee = 0.1 ether;
    Counters.Counter private nftsSold;
    Counters.Counter private nftsCount;

    // --- STRUCTURES ---

    struct MarketSaleItems {
        uint256 tokenId;
        address seller;
        uint256 price;
        uint256 listedDate;
    }

    MarketSaleItems[] private saleItems;
    mapping(uint256 => uint256) private indexToTokenId;
    mapping(address => uint256) private itemToOwner;

    // --- EVENTS ---
    event MarketItemSaleCreated(address indexed seller, uint256 indexed tokenId, uint256 price, uint256 listedDate);
    event MarketItemSaleCancelled(address indexed seller, uint256 indexed tokenId, uint256 cancelledDate);
    event MarketItemUpdated(uint256 indexed tokenId, uint256 newPrice, uint256 updatedDate);
    event MarketItemSold(address seller, address buyer, uint256 tokenId, uint256 price, uint256 soldDate);

    // --- CONTRACT START ---

    constructor(
        IERC721 _nftContractAddr,
        IERC20 _tokenContractAddr,
        address payable _walletAddress
    ) {
        nftContractAddress = _nftContractAddr;
        tokenContractAddress = _tokenContractAddr;
        walletAddress = _walletAddress;
    }

    // --- MAIN FUNCTIONS ---

    function createMarketItemSale(uint256 _tokenId, uint256 _price) public payable{

        require( msg.sender == nftContractAddress.ownerOf(_tokenId), "User is not owner of the token!");
        require(_price > 0, "Token price cannot be 0!");
        require(msg.value >= listingFee, "Check the Listing Fee! Price must be equal to listing price.");  
        require(indexToTokenId[_tokenId] == 0, "Item already in sale!");

        (bool success, ) = walletAddress.call{value: msg.value}("");
        require(success, "Transfer failed");

        nftContractAddress.transferFrom(msg.sender, address(this), _tokenId);
        saleItems.push(MarketSaleItems(_tokenId, msg.sender, _price, block.timestamp));
        indexToTokenId[_tokenId] = saleItems.length;
        itemToOwner[msg.sender] += 1;
        nftsCount.increment();

        emit MarketItemSaleCreated(msg.sender, _tokenId, _price, block.timestamp);
    }

    function removeMarketItem(uint256 _tokenId) public{

        uint256 tokenIndex = indexToTokenId[_tokenId];
        require(msg.sender == saleItems[tokenIndex - 1].seller,"User is not owner of the NFT!");
        require(tokenIndex > 0, "Item is not listed");
                
        nftContractAddress.transferFrom(address(this), saleItems[tokenIndex - 1].seller, _tokenId);

        MarketSaleItems memory lastItem = saleItems[saleItems.length - 1];
        saleItems[tokenIndex - 1] = lastItem;
        indexToTokenId[lastItem.tokenId] = tokenIndex;
        indexToTokenId[_tokenId] = 0;
        itemToOwner[msg.sender] -= 1;
        nftsCount.decrement();
        saleItems.pop();

        emit MarketItemSaleCancelled(msg.sender, _tokenId, block.timestamp);
    }

    function updateMarketItem(uint256 _tokenId, uint256 _price) public{

        uint256 tokenIndex = indexToTokenId[_tokenId];

        require(msg.sender == saleItems[tokenIndex - 1].seller, "Sender is not owner of NFT!");
        require(tokenIndex > 0, "Item is not in sale!");
        require(_price > 0, "Item price cannot be 0!");

        saleItems[tokenIndex - 1].price = _price;
        saleItems[tokenIndex - 1].listedDate = block.timestamp;

        emit MarketItemUpdated(_tokenId, _price, block.timestamp);
    }

    function buyMarketItem(uint256 _tokenId) public payable{

        uint256 tokenIndex = indexToTokenId[_tokenId];
        uint256 tokenPrice = saleItems[tokenIndex - 1].price;
        address seller = saleItems[tokenIndex - 1].seller;

        require(tokenIndex > 0, "Item is not listed for Sale!");
        require(seller != msg.sender, "Buyer cannot be seller!");
        require(msg.value >= tokenPrice, "Not enough token to buy this item!");
        //require(tokenAddress.balanceOf(buyer) > tokenPrice, "Not enough CFISH token to buy!");

        //tokenAddress.transferFrom(buyer, seller, tokenPrice);
        
        MarketSaleItems memory lastItem = saleItems[saleItems.length - 1];

        saleItems[tokenIndex - 1] = lastItem;
        indexToTokenId[lastItem.tokenId] = tokenIndex;
        indexToTokenId[_tokenId] = 0;
        saleItems.pop();
        nftsSold.increment();
        itemToOwner[seller] -= 1;
        nftsCount.decrement();
        nftContractAddress.transferFrom(address(this), msg.sender, _tokenId);
        (bool success, ) = payable(seller).call{value: msg.value}("");
        require(success, "Transfer failed");

        emit MarketItemSold(seller, msg.sender, _tokenId, tokenPrice, block.timestamp);
    }    


    // --- SET FUNCTİONS ---

    function updateNftContractAddress(IERC721 _newNftAddress) public onlyOwner {
        nftContractAddress = _newNftAddress;
    }

    function updateTokenContractAddress(IERC20 _newTokenAddress)
        public
        onlyOwner
    {
        tokenContractAddress = _newTokenAddress;
    }

    function updateWalletAddress(address payable _newWalletAddress)
        public
        onlyOwner
    {
        walletAddress = _newWalletAddress;
    }

    function updateListingFee(uint256 _newFee) public onlyOwner {
        listingFee = _newFee;
    }

    // ---GET FUNCTIONS ---

    function getNFTContractAddress() public view returns (IERC721) {
        return nftContractAddress;
    }

    function getTokenContractAddress() public view returns (IERC20) {
        return tokenContractAddress;
    }

    function getListingFee() public view returns (uint256) {
        return listingFee;
    }

    function getSoldNFTCount() public view returns (uint256) {
        return nftsSold.current();
    }

    function getListedNFTCount() public view returns (uint256) {
        return nftsCount.current();
    }

    
    function getTokenPrice(uint256 _tokenId) public view returns (uint256) {
        uint256 tokenIndex = indexToTokenId[_tokenId];
        return saleItems[tokenIndex - 1].price;
    }

    function getMarketSaleItems() public view returns(MarketSaleItems[] memory){
        
        require(nftsCount.current() >0 , "No NFT in sale :(");
        uint256 counter = 0;

        MarketSaleItems[] memory tempSaleArray = new MarketSaleItems[](nftsCount.current());

        for(uint256 i = 0; i < saleItems.length; i++){
            if(saleItems[i].price > 0){
                tempSaleArray[counter] = saleItems[i];
                counter++;
            }
        }

        return tempSaleArray;
    }


    function getItemById(uint256 _tokenId) public view returns(MarketSaleItems memory item){
        
        require(indexToTokenId[_tokenId] > 0, "Item is not in sale!");
        
        uint256 tokenIndex = indexToTokenId[_tokenId] - 1;
        MarketSaleItems memory tempItem = saleItems[tokenIndex];

        return tempItem;
    }


    function getItemsByAddress(address _address) public view returns (MarketSaleItems[] memory){
        
        require(itemToOwner[_address] > 0, "No listed item for Address!");
        
        MarketSaleItems[] memory tempItem = new MarketSaleItems[](itemToOwner[_address]);

        uint256 counter = 0;
        
        for(uint256 i = 0; i< saleItems.length; i++){
            if(_address == saleItems[i].seller && saleItems[i].price > 0){
                tempItem[counter] = saleItems[i];
                counter++;
            }
        }

        return tempItem;
    }    

    // --- CONTRACT END ---
}