/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

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

interface IERC721 {

    function safeTransferFromForRent(address from, address to, uint256 tokenId, bytes memory _data) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isTokenRented(uint256 tokenId) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IRentingContract {

    enum TokenRentingStatus {
        AVAILABLE,
        LISTED_BATTLE_SET,
        LISTED_COLLECTION,
        RENTED
    }
}

interface IRentingContractStorage is IRentingContract {

    function getLandStatus(uint256 landId) external view returns (TokenRentingStatus);

    function getBotStatus(uint256 botId) external view returns (TokenRentingStatus);
}


interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);
}


interface IXoiliumMarketplace {
    event TokenListed(address indexed seller, TradedNft indexed nft, uint256 indexed tokenId, uint256 price, address allowedBuyer);
    event TokenListingUpdated(address indexed seller, TradedNft indexed nft, uint256 indexed tokenId, uint256 price, address allowedBuyer);
    event ListingCanceled(address indexed seller, TradedNft indexed nft, uint256 indexed tokenId);
    event TokenBought(address indexed buyer, TradedNft indexed nft, uint256 indexed tokenId, Coin coin, uint256 price);

    struct Listing {
        TradedNft nft;
        uint256 tokenId;
        Coin coin;
        uint256 price;
        address seller;
        uint256 endTs;
        address allowedBuyer;
    }

    enum Coin {
        XOIL,
        RBLS,
        WETH,
        USDC,
        USDT,
        BUSD
    }

    enum TradedNft {
        RBXL,
        RBFB
    }
}

interface IXoiliumMarketplaceStorage is IXoiliumMarketplace {
    function setListing(TradedNft nft, uint256 tokenId, Coin coin, uint256 price, address seller, uint256 endTs, address allowedBuyer) external;

    function deleteListing(TradedNft nft, uint256 tokenId) external;

    function getListing(TradedNft nft, uint256 tokenId) external view returns (Listing memory);

    function getListingByIdx(TradedNft nft, uint idx) external view returns (Listing memory);
}


contract Marketplace is IXoiliumMarketplace, ReentrancyGuard, Ownable, Pausable {

    using SafeMath for uint256;

    mapping(TradedNft => IERC721) nftContracts;
    mapping(Coin => address) paymentContracts;
    IRentingContractStorage internal rentingStorageContract;
    IXoiliumMarketplaceStorage internal marketplaceStorage;

    uint8 private constant PAGE_SIZE = 3;
    uint256 private feePercent = 30;
    address private feeCollectorAddress;
    Coin[] private supportedCoins = [Coin.WETH];


    constructor(address marketplaceStorageAddress, address landsContractAddress, address botsContractAddress,
        address xoilAddress, address rblsAddress, address wethAddress) {
        paymentContracts[Coin.XOIL] = xoilAddress;
        paymentContracts[Coin.RBLS] = rblsAddress;
        paymentContracts[Coin.WETH] = wethAddress;
        marketplaceStorage = IXoiliumMarketplaceStorage(marketplaceStorageAddress);
        nftContracts[TradedNft.RBXL] = IERC721(landsContractAddress);
        nftContracts[TradedNft.RBFB] = IERC721(botsContractAddress);
        feeCollectorAddress = _msgSender();
    }


    function setSupportedCoins(Coin[] memory newCoins) external onlyOwner {
        supportedCoins = newCoins;
    }

    function setRentingStorageContract(address storageContractAddress) external onlyOwner {
        rentingStorageContract = IRentingContractStorage(storageContractAddress);
    }


    function updateFees(uint256 newFeePercent, address newFeeCollectorAddress) external onlyOwner {
        require(newFeePercent >= 0 && newFeePercent < 100, "Incorrect fee");
        require(newFeeCollectorAddress != address(0), "Incorrect fee");
        feePercent = newFeePercent;
        feeCollectorAddress = newFeeCollectorAddress;
    }


    function listToken(TradedNft nft, uint256 tokenId, uint256 price, Coin coin, uint256 duration, address allowedBuyer) external whenNotPaused {
        require(isOwnerOf(nft, tokenId, _msgSender()), "Caller is not an owner");
        require(containsCoin(supportedCoins, coin), "Not supported payment currency");
        require(price >= 100, "Price is to loo");
        require(marketplaceStorage.getListing(nft, tokenId).seller != _msgSender(), "Token already listed");
        require(!isTokenListedForRent(nft, tokenId), "Token already listed for the renting");
        require(allowedBuyer == address(0) || allowedBuyer != _msgSender(), "Whitelisted buyer incorrect");

        require(isApproved(nft, tokenId), "Not approved");

        marketplaceStorage.setListing(nft, tokenId, coin, price, _msgSender(), block.timestamp + duration, allowedBuyer);
        emit TokenListed(msg.sender, nft, tokenId, price, allowedBuyer);
    }

    function cancelListing(TradedNft nft, uint256 tokenId) external whenNotPaused {
        require(isOwnerOf(nft, tokenId, _msgSender()), "Caller is not an owner");

        marketplaceStorage.deleteListing(nft, tokenId);

        emit ListingCanceled(msg.sender, nft, tokenId);
    }


    function updateListing(TradedNft nft, uint256 tokenId, uint256 price, Coin coin, uint256 duration, address allowedBuyer) external nonReentrant whenNotPaused {
        Listing memory listing = marketplaceStorage.getListing(nft, tokenId);
        require(isOwnerOf(nft, tokenId, _msgSender()), "Caller is not an owner");
        require(containsCoin(supportedCoins, coin), "Not supported payment currency");
        require(price >= 100, "Price is to low");
        require(listing.seller != address(0), "Token is not listed");
        require(listing.endTs >= block.timestamp, "Listing expired");
        marketplaceStorage.setListing(nft, tokenId, coin, price, _msgSender(), block.timestamp + duration, allowedBuyer);
        emit TokenListingUpdated(msg.sender, nft, tokenId, price, allowedBuyer);
    }

    function buyItem(TradedNft nft, uint256 tokenId) external nonReentrant whenNotPaused {
        Listing memory listing = marketplaceStorage.getListing(nft, tokenId);
        require(isOwnerOf(nft, tokenId, listing.seller), "Incorrect owner of the token");
        require(listing.endTs >= block.timestamp, "Listing expired");
        require(listing.allowedBuyer == address(0) || listing.allowedBuyer == _msgSender(), "Address not whitelisted");

        if (!transferPayment(listing.coin, listing.price, listing.seller)) {
            revert("Failed to transfer payment");
        }

        marketplaceStorage.deleteListing(nft, tokenId);

        IERC721(nftContracts[nft]).safeTransferFrom(listing.seller, _msgSender(), tokenId);
        emit TokenBought(_msgSender(), nft, tokenId, listing.coin, listing.price);
    }

    function transferPayment(Coin coin, uint256 price, address seller) private returns (bool) {
        IERC20 paymentContract = IERC20(paymentContracts[coin]);
        uint256 fee = getPlatformFee(price);
        uint256 sellerAward = price - fee;
        if (!paymentContract.transferFrom(_msgSender(), feeCollectorAddress, fee) || !paymentContract.transferFrom(_msgSender(), seller, sellerAward)) {
            return false;
        }
        return true;
    }

    function getListing(TradedNft nft, uint256 tokenId) external view returns (Listing memory) {
        Listing memory listing = marketplaceStorage.getListing(nft, tokenId);
        if (isOwnerOf(nft, tokenId, listing.seller) && listing.endTs > block.timestamp) {
            return listing;
        }
        revert('Not found');
    }

    function validListingExists(TradedNft nft, uint256 tokenId) public view returns (bool) {
        Listing memory listing = marketplaceStorage.getListing(nft, tokenId);
        if (isOwnerOf(nft, tokenId, listing.seller) && listing.endTs > block.timestamp) {
            return true;
        }
        return false;
    }

    function anyListingsExist(TradedNft nft, uint256[] memory tokenIds) external view returns (bool) {
        for (uint i = 0; i < tokenIds.length; i++) {
            if (validListingExists(nft, tokenIds[i])) {
                return true;
            }
        }
        return false;
    }

    function deleteNotValidListings(TradedNft nft, uint256 searchFromIdx, uint256 searchToIdx) external {
        require(searchFromIdx < searchToIdx, "Incorrect parameters");
        for (uint i = searchFromIdx; i < searchToIdx; i++) {
            Listing memory listing = marketplaceStorage.getListingByIdx(nft, i);
            if ((listing.seller != address(0) && !isOwnerOf(nft, listing.tokenId, listing.seller)) || listing.endTs <= block.timestamp) {
                marketplaceStorage.deleteListing(nft, listing.tokenId);
            }
        }
    }

    function getListings(TradedNft nft, uint page) external returns (Listing[] memory, bool) {
        require(page > 0, "Incorrect indexes");
        Listing[] memory result = new Listing[](PAGE_SIZE);
        uint counter = 0;
        for (uint i = PAGE_SIZE * page; i < PAGE_SIZE * (page + 1); i++) {
            Listing memory listing = marketplaceStorage.getListingByIdx(nft, i);
            if (isOwnerOf(nft, listing.tokenId, listing.seller) && listing.endTs > block.timestamp) {
                result[counter++] = listing;
            }
        }

        Listing[] memory trimmedResult = new Listing[](counter);
        for (uint j = 0; j < counter; j++) {
            trimmedResult[j] = result[j];
        }
        return (trimmedResult, marketplaceStorage.getListingByIdx(nft, PAGE_SIZE * (page + 1)).seller != address(0));
    }

    function isOwnerOf(TradedNft nft, uint256 tokenId, address owner) private view returns (bool) {
        return nftContracts[nft].ownerOf(tokenId) == owner;
    }

    function isApproved(TradedNft nft, uint256 tokenId) private view returns (bool) {
        return nftContracts[nft].getApproved(tokenId) == address(this);
    }

    function isTokenListedForRent(TradedNft nft, uint256 tokenId) private view returns (bool) {
        if (nft == TradedNft.RBXL) {
            return rentingStorageContract.getLandStatus(tokenId) != IRentingContract.TokenRentingStatus.AVAILABLE;
        } else if (nft == TradedNft.RBFB) {
            return rentingStorageContract.getBotStatus(tokenId) != IRentingContract.TokenRentingStatus.AVAILABLE;
        }
        return false;
    }



    function getPlatformFee(uint256 price) private view returns (uint256){
        return price.mul(feePercent).div(100);
    }

    function containsCoin(Coin[] memory array, Coin value) private pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    /**
    * @dev Pauses operations.
    */
    function pause() public onlyOwner {
        _pause();
    }

    /**
    * @dev Unpauses operations.
    */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     *
     * @dev Allow owner to transfer ERC-20 token from contract
     *
     * @param tokenContract contract address of corresponding token
     * @param amount amount of token to be transferred
     *
     */
    function withdrawToken(address tokenContract, uint256 amount) external onlyOwner {
        //        if (IERC20(tokenContract).transfer(msg.sender, amount)) {
        //            emit TokenWithdrawn(tokenContract, amount);
        //        }
    }


}