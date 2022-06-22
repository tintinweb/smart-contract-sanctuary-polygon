/**
 *Submitted for verification at polygonscan.com on 2022-06-21
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

interface IYallahNFT {

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

// File: YallahMarketplace.sol

pragma solidity ^0.8.3;








contract YallahMarketplace is ReentrancyGuard {

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

    address private YallahNFTAddress; 
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

    constructor(address _YallahNFT) {
        admin = msg.sender;
        initialTokenOwner = msg.sender;
        marketplaceWalletAddress = payable(msg.sender);
        YallahNFTAddress = _YallahNFT;
    }

    modifier onlyOwner() {
        require(admin == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyTokenHolder(uint256 _tokenId) {
        require(IYallahNFT(YallahNFTAddress).getTokenHolder(_tokenId ) == msg.sender, "TokeHolder: caller is not the owner");
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
        require(IYallahNFT(YallahNFTAddress).totalSupply(tokenId) > 0 , "Not enough token supply");

        if(IYallahNFT(YallahNFTAddress).getTokenHolder(tokenId ) == msg.sender 
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
    function listTokenForBidding(uint256 tokenId, uint64 expiringOnTimestamp) public {

        require(IYallahNFT(YallahNFTAddress).totalSupply(tokenId) > 0 , "Not enough token supply");

        if(IYallahNFT(YallahNFTAddress).getTokenHolder(tokenId ) == msg.sender 
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

        
        require(IYallahNFT(YallahNFTAddress).totalSupply(tokenId) > 0 , "Not enough token supply");

        if(IYallahNFT(YallahNFTAddress).getTokenHolder(tokenId ) == msg.sender 
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
        
        require(IYallahNFT(YallahNFTAddress).totalSupply(tokenId) > 0 , "Not enough token supply");

        if(IYallahNFT(YallahNFTAddress).getTokenHolder(tokenId ) == msg.sender 
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
        require(IYallahNFT(YallahNFTAddress).totalSupply(tokenId) > 0 , "Not enough token supply");

        if(IYallahNFT(YallahNFTAddress).getTokenHolder(tokenId ) == msg.sender 
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
        require(IYallahNFT(YallahNFTAddress).totalSupply(tokenId) > 0 , "Not enough token supply");

        if(IYallahNFT(YallahNFTAddress).getTokenHolder(tokenId ) == msg.sender 
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

        require(IYallahNFT(YallahNFTAddress).totalSupply(tokenId) > 0 , "Not enough token supply");

        if(IYallahNFT(YallahNFTAddress).getTokenHolder(tokenId ) == msg.sender 
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
    function marketplaceAccountBalance() public onlyOwner view returns(uint256) {
        return address(this).balance;


    }

    function processBuy(address recipient, uint256 tokenId, uint256 noOfTokens, address tokenHolder, uint256 commission) private returns (uint256) {

        uint256 tokenPriceReceived = msg.value;
        
        uint256 commissionRemainderAmount = 0;
        uint256 tokenHolderAmount = tokenPriceReceived;//0;
        uint256 commissionAmount = 0;

        if(commission > 0) {
            commissionAmount = tokenPriceReceived.mul( commission ).div(100);
            commissionRemainderAmount = tokenPriceReceived.mul( commission ).mod(100);
            tokenHolderAmount = tokenPriceReceived.sub( commissionAmount.add(commissionRemainderAmount) );
        }

        IYallahNFT(YallahNFTAddress).safeTransferFrom(tokenHolder, recipient, tokenId, noOfTokens, '0x');

        payable(tokenHolder).transfer(tokenHolderAmount);

        if(commissionAmount > 0)
            payable(marketplaceWalletAddress).transfer(commissionAmount);


        emit NFTSell( msg.sender, tokenId, noOfTokens, tokenHolder, tokenPriceReceived, commissionAmount,tokenHolderAmount, commission);

        return commissionAmount;
    }

    /**
    * @dev this will create the token only when the contract receicve the ether for buying the token
    * @param tokenId YallahNFT token Id
    * @param noOfTokens number of tokens to transfer
    */
    function buyToken( uint256 tokenId, uint256 noOfTokens) external nonReentrant payable {
        
        require(msg.value >= tokenPrices[tokenId], "Not enough amount to buy the NFT");
        require(IYallahNFT(YallahNFTAddress).totalSupply(tokenId) > 0, "Not enough supply");
        require(IYallahNFT(YallahNFTAddress).totalSupply(tokenId) >= noOfTokens, "Not enough token available to buy");

        address tokenHolder = IYallahNFT(YallahNFTAddress).getTokenHolder( tokenId );
        address tokenCreator = IYallahNFT(YallahNFTAddress).getCreator( tokenId );
        uint256 categoryId = IYallahNFT(YallahNFTAddress).getTokenCatgeory(tokenId);
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