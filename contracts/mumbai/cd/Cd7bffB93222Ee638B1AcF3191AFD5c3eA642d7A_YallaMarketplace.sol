/**
 *Submitted for verification at polygonscan.com on 2022-06-29
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// File: yallahMarketplace.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;





interface IYallaNFT {

    function balanceOf(address account, uint256 id) external view returns (uint256);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function totalSupply(uint256 id) external view returns (uint256);

    //IERC1155MetadataURI
    function uri(uint256 id) external view returns (string memory);

    //
    function setResellCommission(uint256 commission) external ;
    function setCustomUri(uint256 tokenId, string memory newUri) external;
    function mint(address initialOwner, uint256 tokenId, uint256 initialSupply, bytes memory data) external returns(uint256);
    function lazyMint(address initialOwner, address tokenHolder, uint256 tokenId, uint256 initialSupply, bytes memory data) external returns(uint256);
    function proxyMint(address initialOwner, uint256 tokenId, uint256 initialSupply, bytes memory data) external returns(uint256);
    function createToken(address initialOwner, uint256 tokenId, uint256 initialSupply, bytes memory data) external returns(uint256);
    function batchMint(address initialOwner, uint256[] memory tokenIds, uint256[] memory initialSupplies, bytes memory data) external;
    function burn(uint256 tokenId, uint256 quantity) external;
    function batchBurn(uint256[] memory tokenIds, uint256[] memory quantities) external;
    function getCreator( uint256 tokenId ) external view returns(address);
    function getTokenHolder( uint256 tokenId ) external view returns(address);
    function getTokenCatgeory(uint256 tokenId ) external view returns(uint256);


}
contract YallaMarketplace is ReentrancyGuard {

    using SafeMath for uint256;

    struct NFTBidData {
        uint64 expiringOnTimestampUTC;
        uint256 minTokenPrice;
    }

    event NFTPriceChanged(uint256 tokenId, uint256 tokenPrice);
    event NFTListedForOpenSale(uint256 tokenId, uint256 tokenPrice);

    event NFTLockedForUserOfferedPrice(uint256 tokenId, address userAddress, uint256 tokenPrice);
    event NFTLockRemovedFromOfferedUser(uint256 tokenId);

    event NFTListedForBidding(uint256 tokenId, uint256 expiredOn);
    event NFTRemovedFromBidding( uint256 tokenId );
    event NFTBidWinnerAssigned( uint256 tokenId, address bidWinnerAddress, uint256 tokenPrice );

    event NFTSell( 
        address recipient, 
        uint256 tokenId, 
        uint256 noOfTokens, 
        address tokenHolder, 
        uint256 totalAmountReceived,
        uint256 commissionAmount,
        uint256 tokenHolderAmount,
        uint256 commission
        );
    

    address admin;
    address initialTokenOwner; //intital token for lazy minting then transfered to buyer

    address private YallaNFTAddress; 
    address payable public marketplaceWalletAddress;

    mapping(uint256 => uint256) public tokenPrices;

    mapping(uint256 => uint256) public tokenOffers;

    
    mapping(uint256 => bool) public tokenListedForBidding;
    mapping(uint256 => bool) public tokenListedForSale;
    mapping(uint256 => bool) public tokenLockedForUser;

    mapping(uint256 => address) public tokenBidWinner;
    mapping(uint256 => uint256) public tokenBidWinnerPrice;
    mapping(uint256 => uint256) public tokenBidExpiringOnTimestampUTC;

    mapping(uint256 => address) public lockedTokenAssignedUser;

    mapping(uint256 => uint256) public firstSaleCommission;
    mapping(uint256 => uint256) public resellCommission;

    uint256 adminCommission;
    uint256 tokenHolderCommission;

    uint256 firstCommission;
    uint256 secongCommission;
    uint256 thirdCommission;
 
    constructor(address _YallahNFT) {
        admin = msg.sender;
        initialTokenOwner = msg.sender;
        marketplaceWalletAddress = payable(msg.sender);
        YallaNFTAddress = _YallahNFT;
    }

    modifier onlyOwner() {
        require(admin == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyTokenHolder(uint256 _tokenId) {
        require(IYallaNFT(YallaNFTAddress).getTokenHolder(_tokenId ) == msg.sender, "TokeHolder: caller is not the owner");
        _;
    }


    /**
    * @dev to set commission for first sale of token
    * @param commission commission for first sale of the token and the commission can be zero
    * @param catgeoryId category id
    */
    function setFirstSaleCategoryCommission(uint256 commission, uint256 catgeoryId) public onlyOwner { 
        // require(commission > 0, "Commision percentage should be greater than zero");
        firstSaleCommission[ catgeoryId ] = commission;
    }

    /**
    * @dev to set commission for reselling of token
    * @param commission commission for reselling the token and the commission can be zero
    * @param catgeoryId category id
    */
    function setReSellCategoryCommission(uint256 commission, uint256 catgeoryId) public onlyOwner { 
        // require(commission > 0, "Commision percentage should be greater than zero");
        resellCommission[ catgeoryId ] = commission;
    }


    /**
    * @dev to set marketplace wallet address to receive the ether
    * @param pMarketplaceWalletAddress wallet address
    */
    function setMarketPlaceWalletAddress(address payable pMarketplaceWalletAddress) public onlyOwner {
        marketplaceWalletAddress = pMarketplaceWalletAddress;
    }

    /**
    * @dev to change a token price, for inital selling and reselling the same identifier is used
            The price can only be changed by owner/tokenholder
            due to lazy minting, will check the token supply, 
            if its zero then it can only be changed by admin otherwise only by tokenholder
    * @param tokenId YallahNFT token Id
    * @param tokenPrice token price in wei 
    */
    function changeTokenPrice(uint256 tokenId, uint256 tokenPrice) public  {

        require(tokenListedForSale[tokenId] , "Token isn't listed for open sale");
        require(IYallaNFT(YallaNFTAddress).totalSupply(tokenId) > 0 , "Not enough token supply");

        if(IYallaNFT(YallaNFTAddress).getTokenHolder(tokenId ) == msg.sender 
            || admin == msg.sender ) {
            tokenPrices[ tokenId ] = tokenPrice;
            emit NFTPriceChanged( tokenId, tokenPrice);
        }
        else 
            revert("You are not admin or owner");
    }

    /**
    * @dev to list token for bidding 
            The listing can only be changed by owner/tokenholder
    * @param tokenId YallahNFT token Id
    * @param expiringOnTimestamp token price in wei 
    */
    function  listTokenFromBidding(uint256 tokenId, uint64 expiringOnTimestamp) public {

        require(IYallaNFT(YallaNFTAddress).totalSupply(tokenId) > 0 , "Not enough token supply");

        if(IYallaNFT(YallaNFTAddress).getTokenHolder(tokenId ) == msg.sender 
            || admin == msg.sender ) {

            tokenListedForBidding[ tokenId ] = true;
            tokenBidExpiringOnTimestampUTC[ tokenId ] = expiringOnTimestamp;
            
            emit NFTListedForBidding( tokenId, expiringOnTimestamp);
        }
        else 
            revert("You are not admin or owner");
    }

     /**
    * @dev assign token to bidwinner
    * @param tokenId YallahNFT token Id,
    * @param bidWinnerAddress YallahNFT token Id
    * @param tokenPrice token price in wei 
    */
    function assignTokenToBidWinner(uint256 tokenId, address bidWinnerAddress, uint256 tokenPrice) public {

        
        require(IYallaNFT(YallaNFTAddress).totalSupply(tokenId) > 0 , "Not enough token supply");

        if(IYallaNFT(YallaNFTAddress).getTokenHolder(tokenId ) == msg.sender 
            || admin == msg.sender ) {

            tokenBidWinner[ tokenId  ] = bidWinnerAddress;
            tokenPrices [ tokenId ] = tokenPrice;
            emit NFTBidWinnerAssigned( tokenId, bidWinnerAddress, tokenPrice );
        }
        else 
            revert("You are not admin or owner");
    }


    /**
    * @dev to remove token from bidding 
            The listing can only be changed by owner/tokenholder
    * @param tokenId YallahNFT token Id
    */
    function removeTokenFromBidding(uint256 tokenId) public  {
        
        require(IYallaNFT(YallaNFTAddress).totalSupply(tokenId) > 0 , "Not enough token supply");

        if(IYallaNFT(YallaNFTAddress).getTokenHolder(tokenId ) == msg.sender 
            || admin == msg.sender ) {

            tokenListedForBidding[ tokenId ] = false;
            emit NFTRemovedFromBidding( tokenId );
        }
        else 
            revert("You are not admin or owner");
    
    }

    /**
    * @dev to list the token for sale
    * @param tokenId YallahNFT token Id
    * @param tokenPrice token price in wei 
    */
    function listTokenForSale(uint256 tokenId, uint256 tokenPrice) public  {
        require(IYallaNFT(YallaNFTAddress).totalSupply(tokenId) > 0 , "Not enough token supply");

        if(IYallaNFT(YallaNFTAddress).getTokenHolder(tokenId ) == msg.sender 
            || admin == msg.sender ) {
            tokenPrices[tokenId] = tokenPrice;
            tokenListedForSale[ tokenId ] = true;
            tokenListedForBidding[ tokenId ] = false;
            
            emit NFTListedForOpenSale(tokenId, tokenPrice);
        }
        else 
            revert("You are not admin or owner");
    }

    /**
    * @dev to assign a token to a user, who has offered a acceptable price to current token holder
    * @param tokenId YallahNFT token Id
    * @param tokenPrice token price in wei
    * @param tokenAssignedUserAddress user who offered a acceptable price
    */
    function assignTokenToOfferUser(uint256 tokenId, uint256 tokenPrice, address tokenAssignedUserAddress) public {
        require(IYallaNFT(YallaNFTAddress).totalSupply(tokenId) > 0 , "Not enough token supply");

        if(IYallaNFT(YallaNFTAddress).getTokenHolder(tokenId ) == msg.sender 
            || admin == msg.sender ) {
            tokenPrices[tokenId] = tokenPrice;
            tokenListedForSale[ tokenId ] = false;
            tokenListedForBidding[ tokenId ] = false;
            tokenLockedForUser[ tokenId ] = true;
            lockedTokenAssignedUser[ tokenId ] = tokenAssignedUserAddress;
            emit NFTLockedForUserOfferedPrice(tokenId, tokenAssignedUserAddress, tokenPrice);
        }
        else 
            revert("You are not admin or owner");
    }

    /**
    * @dev token removed from locked user
    * @param tokenId YallahNFT token Id
    */
    function removeAssignedTokenFromOfferUser(uint256 tokenId) public {

        require(IYallaNFT(YallaNFTAddress).totalSupply(tokenId) > 0 , "Not enough token supply");

        if(IYallaNFT(YallaNFTAddress).getTokenHolder(tokenId ) == msg.sender 
            || admin == msg.sender ) {
            tokenListedForSale[ tokenId ] = false;
            tokenListedForBidding[ tokenId ] = false;
            tokenLockedForUser[ tokenId ] = false;

            emit NFTLockRemovedFromOfferedUser(tokenId);
        }
        else 
            revert("You are not admin or owner");
    }

    /**
    * @dev to get the current token price
    * @param tokenId YallahNFT token Id
    * @return tokenPrice token price in wei 
    */
    function getCurrentTokenPrice(uint256 tokenId) public view returns(uint256) {
        return tokenPrices[tokenId];
    }


    /**
    * @dev to get the current token status
    * @param tokenId YallahNFT token Id
    * @return token status
    */
    function getTokenStatus(uint256 tokenId) public view returns(uint256) {

        uint256 tSellStatus = 0;

        if(tokenListedForBidding[tokenId] ) 
            tSellStatus = 2;
        else if(tokenLockedForUser[ tokenId ]) 
            tSellStatus = 3;
        else if( tokenListedForSale[ tokenId ]) 
            tSellStatus = 1;

        
        return tSellStatus;
        

    }

    /**
    * @dev transfer balance to owner balance
    */
    function withdrawBalance() public onlyOwner returns(uint256) {
        uint256 wBalance = address(this).balance;
        payable(marketplaceWalletAddress).transfer( wBalance );
        return wBalance;
    }

    /**
    * @dev return the marketplace balance
    */
    function marketplaceAccountBalance() public 
    // onlyOwner
    view returns(uint256) {
        return address(this).balance;
    }
    function set2ndSalRoyality( uint256 _firstCommission, uint256 _secondCommission, uint256 _thirdCommission) public onlyOwner {
        firstCommission = _firstCommission;
        secongCommission = _secondCommission;
        thirdCommission = _thirdCommission;
    }
    function set1stSaleROyality(uint256 _adminCommission, uint256 _tokenHolderCommission) public onlyOwner {
        adminCommission = _adminCommission;
        tokenHolderCommission = _tokenHolderCommission;
    }


    function secondCommitionDistribution(uint256 _value) internal view returns(uint256,uint256,uint256){
        uint256 first = _value/100*firstCommission;
        uint256 second= _value/100*secongCommission;
        uint256 third = _value/100*thirdCommission;
        return (first,second,third);
    }
    function firstCommitionDistribution(uint256 _value) internal view returns(uint256,uint256){
        uint256 first = _value/100*adminCommission;
        uint256 second= _value/100*tokenHolderCommission;
        return (first,second);
    }
    uint256 tokenPriceReceived;
    uint256 commissionRemainderAmount;
    uint256 tokenHolderAmount;
    function processBuy(address recipient, uint256 tokenId, uint256 noOfTokens, address tokenHolder, uint256 commission) private returns (uint256) {

        tokenPriceReceived = msg.value;
        commissionRemainderAmount = 0;
        tokenHolderAmount = tokenPriceReceived;//0;
        uint256 commission_Amount = 0;
        address tokenCreator = IYallaNFT(YallaNFTAddress).getCreator( tokenId );
            

        if(commission> 0) {
            commission_Amount = tokenPriceReceived.mul( commission ).div(100);
            commissionRemainderAmount = tokenPriceReceived.mul( commission ).mod(100);
            tokenHolderAmount = tokenPriceReceived.sub( commission_Amount.add(commissionRemainderAmount) );
        }
        IYallaNFT(YallaNFTAddress).safeTransferFrom(tokenHolder, recipient, tokenId, noOfTokens, '0x');

        payable(tokenHolder).transfer(tokenHolderAmount);
        if(commission_Amount > 0){
        if(tokenHolder==tokenCreator){
            (uint256 a,uint256 b) = firstCommitionDistribution(commission_Amount);
            payable(marketplaceWalletAddress).transfer(a);
            payable(tokenCreator).transfer(b);
        }else{
           (uint256 a,uint256 b,uint256 c) = secondCommitionDistribution(commission_Amount);
            payable(marketplaceWalletAddress).transfer(a);
            payable(tokenCreator).transfer(b);
            payable(tokenHolder).transfer(c);

        }
        
        emit NFTSell( msg.sender, tokenId, noOfTokens, tokenHolder, tokenPriceReceived, commission_Amount,tokenHolderAmount, commission);

        return commission_Amount;
    }
    }

    /**
    * @dev this will create the token only when the contract receicve the ether for buying the token
    * @param tokenId YallahNFT token Id
    * @param noOfTokens number of tokens to transfer
    */
    function buyToken( uint256 tokenId, uint256 noOfTokens) external nonReentrant payable {
        
        require(msg.value >= tokenPrices[tokenId], "Not enough amount to buy the NFT");
        require(IYallaNFT(YallaNFTAddress).totalSupply(tokenId) > 0, "Not enough supply");
        require(IYallaNFT(YallaNFTAddress).totalSupply(tokenId) >= noOfTokens, "Not enough token available to buy");

        address tokenHolder = IYallaNFT(YallaNFTAddress).getTokenHolder( tokenId );
        address tokenCreator = IYallaNFT(YallaNFTAddress).getCreator( tokenId );
        uint256 categoryId = IYallaNFT(YallaNFTAddress).getTokenCatgeory(tokenId);
        uint256 commission = 0;
        uint256 commissionAmount = 0;

        if( tokenHolder == tokenCreator ) 
            commission = firstSaleCommission[categoryId];

        else 
            commission = resellCommission[categoryId];


        if(tokenListedForBidding[tokenId] ) {

            if(msg.sender == tokenBidWinner[tokenId]) {

                commissionAmount = processBuy(msg.sender, tokenId, noOfTokens, tokenHolder, commission);
                tokenListedForBidding[ tokenId ] = false;

            }
            else 
                revert("You are not a bid winner");
            
        }
        else if(tokenLockedForUser[ tokenId ]) {

            if(msg.sender == lockedTokenAssignedUser[tokenId]) {

                commissionAmount = processBuy(msg.sender, tokenId, noOfTokens, tokenHolder, commission);
                tokenListedForBidding[ tokenId ] = false;
            }
            else 
                revert("You are not the offered user");
            
        }
        else if( tokenListedForSale[ tokenId ]) {
            commissionAmount = processBuy(msg.sender, tokenId, noOfTokens, tokenHolder, commission);
            tokenListedForSale[ tokenId ] = false;
        }
        else
            revert("Token not approved for sale");
    }
}