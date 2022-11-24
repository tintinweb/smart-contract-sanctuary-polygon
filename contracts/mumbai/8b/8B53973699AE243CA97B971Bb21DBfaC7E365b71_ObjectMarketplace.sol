// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IObjectMarketplace.sol";
import "./interfaces/INftCommon.sol";
import "./MarketplaceManager.sol";


contract ObjectMarketplace is IObjectMarketplace, Ownable {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    //Royalties interface
    bytes4 private constant _INTERFACE_ID_ERC2981 = type(IERC2981).interfaceId;//0x2a55205a
    
    //Address of marketplaceManager contract
    MarketplaceManager private _marketplaceManager;

    //Keeps track of total listings ever generated
    uint256 public listingIdIndex;

    //Allows us to retrieve the info of a ListingID
    mapping(uint256 => Listing) public listingById;

    modifier onlySeller(uint256 listingId){
        Listing storage _listing = listingById[listingId];
        if(msg.sender == _listing.seller){
            _;
        }else {
            revert NotAllowedUser();
        }
    }

    modifier noZeroAddress(address newAddress){
        if(newAddress == address(0)){
            revert ZeroAddress();
        } else {
            _;
        }
    }

    constructor(address manager) {
        _marketplaceManager = MarketplaceManager(manager);
        listingIdIndex = 1;
    }

    receive() external payable{
        revert();
    }

    /// @notice changes the address of marketplaceManager contract
    /**
     * @param newManager new address of marketplaceManager contract
     */
    function setMarketplaceManager(address newManager) external noZeroAddress(newManager) onlyOwner{
        _marketplaceManager = MarketplaceManager(newManager);

        emit NewManagerSet(newManager);
    }

    /// @notice creates new listing
    /**
     * @dev anyone can call this function
     * @param currency either an allowed ERC20 or the chain's native token
     * @param nft address of nft collection to be listed
     * @param tokenId within the collection. If @param nft is ERC1155, only 1 unit is allowed to be listed
     * @param price in wei of the token listed.
    */
    function createListing(
        address currency, 
        address nft, 
        uint256 tokenId, 
        uint256 price
    ) external {
        uint256 currentIndex = listingIdIndex;
        bool authorizedToken = _marketplaceManager.checkAuthorizedERC20(currency);
        bool authorizedObject = _marketplaceManager.checkAuthorizedObject(nft);
        listingIdIndex += 1;
        
        //Check if the seller is the owner of the token
        bool isOwner =  objectOwner(nft, tokenId, msg.sender);
        
        if (!isOwner) {
            revert NotOwner();
        }

        //Check if the nft is authorized by objectMarketplaceManager
        if(!authorizedToken && (currency != address(0))){
            revert UnauthorizedERC20();
        }

        //Check if the nft is authorized by objectMarketplaceManager
        if(!authorizedObject || nft == address(0)){
            revert UnauthorizedObject();
        }

        //Check if the token owner has approved the marketplace to move the tokens
        if(!INftCommon(nft).isApprovedForAll(msg.sender, address(this))){
            revert NotApproved();
        }
    
        //Create new listing
        listingById[currentIndex] = Listing(
        currentIndex,
        msg.sender,
        currency,
        nft,
        tokenId,
        price,
        true);

        emit ListingCreated(currentIndex, msg.sender, currency, nft, tokenId, price, true);

    }

    /// @notice Allows seller to update either @param currency or @param price from listing
    /** 
     * @dev only Seller can call this function
     * @param currency new currency for listing
     * @param listingId to identify listing
     * @param price new price of listing
    */
    function updateListing(
        uint256 listingId, 
        address currency, 
        uint256 price
    ) external onlySeller(listingId) {
        Listing storage _listing =  listingById[listingId];
        bool authorizedToken = _marketplaceManager.checkAuthorizedERC20(currency);
        
        if(!_listing.exist){
            revert NonExistingListing();
         }
        if(!authorizedToken && (currency != address(0))){
            revert UnauthorizedERC20();
        }
        
        listingById[listingId].currency = currency;
        listingById[listingId].price = price;

        emit ListingUpdated(listingId, msg.sender, currency, _listing.nft, _listing.tokenId, price);
    }

    /// @notice allows to cancel listing by Seller
    /**
     * @dev only original seller can call this function
     * @param listingId Id of the listing to be eliminated.
     */
    function cancelListing(uint256 listingId) external onlySeller(listingId){
        _cancelListing(listingId);
    }

    /// @notice cancel listing if original seller is not the owner of the token anymore
    /**
     * @dev This function can be called by anyone.
     * @param listingId Id of the listing to be eliminated.
     */
    function cancelInvalidListing(uint256 listingId) external {
        Listing memory _listing =  listingById[listingId];
        _cancelListing(listingId);
        bool isOwner=  objectOwner(_listing.nft, _listing.tokenId, _listing.seller);
        if (isOwner) {
            revert ListingIsValid();
        } 
    }

    /// @notice buys nft from existing listing. 
    /**
     * @dev Separates fee payment, royalty payment and amount to be paid for seller.
     * @dev Admits payments in native token and authorized ERC20.
     * @param listingId Id of the listing to be purchased.
    */
    function buyToken(uint256 listingId) external payable {
        Listing memory _listing =  listingById[listingId];
        uint256 marketplaceFeePoints = _marketplaceManager.marketplaceFeePoints();
        address feeReceiver = _marketplaceManager.feeReceiver();

        //Cancel listing
        _cancelListing(listingId);

        if(!_listing.exist){
            revert NonExistingListing();
        }

        //We check if the seller is still the owner
        bool isOwner = objectOwner(_listing.nft, _listing.tokenId, _listing.seller);
        if (!isOwner) {
            revert InvalidListing();
        }

        //Calculate fees and prices 
        uint256 marketplaceFee = (_listing.price * marketplaceFeePoints) / 10000;
        (address receiver, uint256 royaltyAmount) =  checkRoyalties(_listing.nft, _listing.tokenId, _listing.price);
        uint256 priceToSeller = _listing.price - marketplaceFee - royaltyAmount;

        //We transfer the tokens to Seller, either ERC20 or native token
        if(_listing.currency == address(0)){
            if(msg.value != _listing.price){
                revert NotEnoughEther();
            }
            (bool successFee, ) = payable(feeReceiver).call{value:marketplaceFee}("");
            (bool successRoyalty, ) = payable(receiver).call{value:royaltyAmount}("");
            (bool successPayment, ) = payable(_listing.seller).call{value:priceToSeller}("");

            if(!successFee || !successRoyalty || !successPayment ) {
                revert MarketplaceError();
            }
            
        } else {
            IERC20 paymentToken = IERC20(_listing.currency);

            paymentToken.safeTransferFrom(msg.sender, feeReceiver, marketplaceFee);
            if(receiver != address(0) && royaltyAmount > 0){
                paymentToken.safeTransferFrom(msg.sender, receiver, royaltyAmount);
            }
            paymentToken.safeTransferFrom(msg.sender, _listing.seller, priceToSeller);
        }
        
        //Transfer the NFT to buyer
        bool successTransfer =  _safeTransferObject(INftCommon(_listing.nft), _listing.seller, msg.sender, _listing.tokenId);

        if(!successTransfer) {
            revert MarketplaceError();
        }

        emit ItemSold(listingId, _listing.nft,  _listing.seller, msg.sender, _listing.currency, _listing.price);
    }

    ///@dev used in different cancel listing situations
    /**
     * @param listingId Id of the listing to be eliminated.
     */
    function _cancelListing(uint256 listingId) internal {
        delete(listingById[listingId]);
        emit ListingCancelled(listingId);
    }

    
    ///@dev utility function to transfer both ERC721 and ERC1155
    /**
     * @param nft the NFT to be transferred 
     * @param from original owner of the token
     * @param to new owner of the token
     * @param tokenId the token to be transferred
     */
    function _safeTransferObject(
        INftCommon nft, 
        address from, 
        address to, 
        uint256 tokenId
    ) internal returns (bool) {
        //ERC1155 interface Id
        if(nft.supportsInterface(0xd9b67a26)){
            nft.safeTransferFrom(from, to, tokenId, 1, "");
            return true;
            //ERC721 interface Id
        } else if (nft.supportsInterface(0x80ac58cd)){
            nft.safeTransferFrom(from, to, tokenId);
            return true;
        }else{
            revert();
        }
    }
    
    ///@dev utility function to check ownership of both ERC721 and ERC1155
    /**
     * @param nft NFT to be checked for ownership
     * @param tokenId Token to be checked for ownership
     * @param seller address of user who wants to list/have listed the NFT
     */ 
    function objectOwner(
        address nft, 
        uint256 tokenId, 
        address seller
    ) internal returns (bool) {
        //ERC1155 interface
        if (nft.supportsInterface(0xd9b67a26)){
            INftCommon token =INftCommon(nft);
            uint256 balance = token.balanceOf(seller, tokenId);
            if (balance > 0){
                return true;
            } else {
                return false;
            }
        //ERC721 interface
        } else if (nft.supportsInterface(0x80ac58cd)){
            INftCommon token =INftCommon(nft);
            address ownerAddress = token.ownerOf(tokenId);
            if (ownerAddress == seller){
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    ///@dev checks compatibility with ERC2981 and returns royalties receiver and amount to be paid
    /**
     * @param nft NFT which royalties are being checked
     * @param tokenId Id of token checked
     * @param sellPrice price of token purchase, to calculate distribution of royalties
     */
    function checkRoyalties(
        address nft, 
        uint256 tokenId, 
        uint256 sellPrice) 
        public view returns (address receiver, uint256 royaltyAmount) 
        { INftCommon token = INftCommon(nft);
        if(token.supportsInterface(_INTERFACE_ID_ERC2981)) {
            (receiver, royaltyAmount) = token.royaltyInfo(tokenId, sellPrice);
        } else {
            (receiver, royaltyAmount) = (address(0), 0);
        }
    } 
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IObjectMarketplaceManager.sol";

contract MarketplaceManager is IObjectMarketplaceManager, Ownable {
    
    uint256 public marketplaceFeePoints;
    address public feeReceiver;

    mapping(address => bool) private authorizedERC20;
    mapping(address => bool) private authorizedObject;

    modifier noZeroAddress(address newAddress){
        if(newAddress == address(0)){
            revert ZeroAddress();
        } else {
            _;
        }
    }

    constructor(uint256 marketplaceFee, address initialFeeReceiver, address[] memory initialERC20, address[] memory initialObject) noZeroAddress(initialFeeReceiver) {

        marketplaceFeePoints = marketplaceFee;
        feeReceiver  = initialFeeReceiver;

        for (uint256 i = 0; i < initialERC20.length; i++){
            addAuthorizedERC20(initialERC20[i]);
        }

        for (uint256 i = 0; i < initialObject.length; i++){
            addAuthorizedObject(initialObject[i]);
        }
    }
    
    /// @notice changes marketplace fee
    /** 
     * @dev 1% fee is 100 points in @param newFee
     * @param newFee is the amount set as the marketplace fee for every item sold
     * */
    function setMarketplaceFees(uint256 newFee) external onlyOwner {
        marketplaceFeePoints = newFee;

        emit MarketplaceFeeChanged(newFee, block.timestamp);
    }

    /// @notice modify receiver of marketplace fees 
    /**
     * @param newReceiver address of new marketplace fees receiver
     */
    function setFeeReceiver(address newReceiver) external onlyOwner {
        feeReceiver = newReceiver;

        emit FeeReceiverChanged(newReceiver, block.timestamp);
    }

    /// @notice Adds ERC20 token to the list of authorized tokens to be used in the marketplace.
    /**
     * @param newToken token to be added to permissions
     */
    function addAuthorizedERC20(address newToken) public noZeroAddress(newToken) onlyOwner{

        if(authorizedERC20[newToken] == true){
            revert AlreadyAuthorized();
        }
        authorizedERC20[newToken] = true;

        emit AddedPermission(newToken, block.timestamp);
    }
    
    /// @notice delete previously authorized ERC20 token from the list of tokens allowed for trading.
    /**
     * @param token token to be revoked permission
     */
    function deleteAuthorizedERC20(address token) external noZeroAddress(token) onlyOwner{

        if(authorizedERC20[token] == false){
            revert UnauthorizedERC20();
        }

        authorizedERC20[token] = false;

        emit EliminatedPermission(token, block.timestamp);
    }

    /// @notice Adds ERC20 token to the list of authorized tokens to be used in the marketplace.
    /**
     * @param newObject new NFT object to be added to the authorized list
     */
    function addAuthorizedObject(address newObject) public noZeroAddress(newObject) onlyOwner{

        if(authorizedObject[newObject] == true){
            revert AlreadyAuthorized();
        }
        authorizedObject[newObject] = true;

        emit AddedPermission(newObject, block.timestamp);
    }
    
    /// @notice delete previously authorized ERC20 token from the list of tokens allowed for trading.
    /** 
     * @param object NFT to be revoked authorization
     */
    function deleteAuthorizedObject(address object) external noZeroAddress(object) onlyOwner{

        if(authorizedObject[object] == false){
            revert UnauthorizedObject();
        }

        authorizedObject[object] = false;

        emit EliminatedPermission(object, block.timestamp);
    }

    /// @notice check if token is authorized
    /**
     * @param token token to be checked
     */
    function checkAuthorizedERC20(address token) external view returns (bool){
        return authorizedERC20[token];
    }

    /// @notice check if object is authorized
    /**
     * @param object object to be checked
     */
    function checkAuthorizedObject(address object) external view returns (bool){
        return authorizedObject[object];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IERC2981.sol";

interface INftCommon is IERC1155, IERC2981 {

    //IERC1155 functions for common interface 

        ///@notice checks total balance of token in any given account
    /**
     * @param account the address to be checked
     * @param id the token id to be checked
     */
    function balanceOf(address account, uint256 id) external view override(IERC1155) returns(uint256);

    ///@notice Transfers tokens from owner address to recipient address
    /**
     * @param from origin address
     * @param to recipient address
     * @param tokenId token Id to be sent
     * @param amount total amount of tokens to send
     * @param data optional additional calldata
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data) external override(IERC1155);

    //IERC721 functions for common interface

    ///@notice checks if user is the owner of the token id
    /**
     * @param tokenId token to be checked
     */
    function ownerOf(uint256 tokenId) external returns (address);

        ///@notice Transfers tokens from owner address to recipient address
    /**
     * @param from origin address
     * @param to recipient address
     * @param tokenId token Id to be sent
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


interface IObjectMarketplace {
    
    error AlreadyExistingListing();
    error InvalidListing();
    error ItemAlreadySold();
    error ListingIsValid();
    error MarketplaceError();
    error NotEnoughEther();
    error NonExistingListing();
    error NotAllowedUser();
    error NotApproved();
    error NotOwner();
    error UnauthorizedERC20();
    error UnauthorizedObject();
    error ZeroAddress();

    struct Listing {
        // Ever increasing listing Id of tokens
        uint256 listingId;
        // Address of seller
        address seller;
        // Address of listing currency, either an authorized ERC20 or address(0) if native token
        address currency;
        // Address of NFT contract
        address nft;
        // Address of token to be listed
        uint256 tokenId;
        //Desired price by seller
        uint256 price;
        //Check if listing exists
        bool exist;
    }

    // Emitted when a valid listed item is sold at the requested price
    event ItemSold(uint256 listingId, address nft, address seller, address buyer, address currency, uint256 price);
    // Emitted when a valid lsiting is created
    event ListingCreated(uint256 listingId, address seller, address currency, address nft, uint256 tokenId, uint256 price, bool exist);
    // Emitted when a valid listing is updated by the Seller
    event ListingUpdated(uint256 listingId, address seller, address currency, address nft, uint256 tokenId, uint256 price);
    // Emitted when a listing is cancelled either by the Seller or another user if the listing was invalid
    event ListingCancelled(uint256 listingId);
    // Emitted when the objectMarketplaceManager contract is successfully replaced
    event NewManagerSet(address newManager);
    
    
    
    /// @notice buys nft from existing listing. 
    /**
     * @dev Separates fee payment, royalty payment and amount to be paid for seller.
     * @dev Admits payments in native token and authorized ERC20.
     * @param listingId Id of the listing to be purchased.
    */
    function buyToken(uint256 listingId) external payable; 

    /// @notice cancel listing if original seller is not the owner of the token anymore
    /**
     * @dev This function can be called by anyone.
     * @param listingId Id of the listing to be eliminated.
     */
    function cancelInvalidListing(uint256 listingId) external;

    /// @notice allows to cancel listing by user
    /**
     * @dev only original seller can call this function
     * @param listingId Id of the listing to be eliminated.
     */
    function cancelListing(uint256 listingId) external;

    /// @notice creates new listing
    /**
     * @dev anyone can call this function
     * @param currency either an allowed ERC20 or the chain's native token
     * @param nft address of nft collection to be listed
     * @param tokenId within the collection. If @param nft is ERC1155, only 1 unit is allowed to be listed
     * @param price in wei of the token listed.
    */
    function createListing(address currency, address nft, uint256 tokenId, uint256 price) external;

    /// @notice changes the address of marketplaceManager contract
    /**
     * @param newManager new address of marketplaceManager contract
     */
    function setMarketplaceManager(address newManager) external;

    /// @notice Allows seller to update either @param currency or @param price from listing
    /** 
     * @dev only Seller can call this function
     * @param currency new currency for listing
     * @param listingId to identify listing
     * @param price new price of listing
    */
    function updateListing(uint256 listingId, address currency, uint256 price) external;
}

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
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IObjectMarketplaceManager {
    
    error AlreadyAuthorized();
    error UnauthorizedERC20();
    error UnauthorizedObject();
    error ZeroAddress();
    
    // Emitted after granting authorization to a new NFT/ERC20 address
    event AddedPermission(address authorized, uint256 timestamp);
    // Emitted after revoking authorization to a previously authorized NFT/ERC20 address
    event EliminatedPermission(address Unauthorized, uint256 timestamp);
    // Emitted after changing the recipient of marketplace fees
    event FeeReceiverChanged(address newReceiver, uint256 timestamp);
    // Emitted after changing the marketplace fee amount
    event MarketplaceFeeChanged(uint256 newFee, uint256 timestamp);

    /// @notice Adds ERC20 token to the list of authorized tokens to be used in the marketplace.
    /**
     * @param newToken token to be added to permissions
     */
    function addAuthorizedERC20(address newToken) external;

    /// @notice Adds ERC20 token to the list of authorized tokens to be used in the marketplace.
    /**
     * @param newObject new NFT object to be added to the authorized list
     */
    function addAuthorizedObject(address newObject) external;
    
    /// @notice check if token is authorized
    /**
     * @param token token to be checked
     */
    function checkAuthorizedERC20(address token) external view returns (bool);

    /// @notice check if object is authorized
    /**
     * @param object object to be checked
     */
    function checkAuthorizedObject(address object) external view returns (bool);

    /// @notice delete previously authorized ERC20 token from the list of tokens allowed for trading.
    /**
     * @param token token to be revoked permission
     */
    function deleteAuthorizedERC20(address token) external;

    /// @notice delete previously authorized ERC20 token from the list of tokens allowed for trading.
    /** 
     * @param object NFT to be revoked authorization
     */
    function deleteAuthorizedObject(address object) external;

    /// @notice changes marketplace fee
    /** 
     * @dev 1% fee is 100 points in @param newFee
     * @param newFee is the amount set as the marketplace fee for every item sold
     * */
    function setMarketplaceFees(uint256 newFee) external;

    /// @notice modify receiver of marketplace fees 
    /**
     * @param newReceiver address of new marketplace fees receiver
     */
    function setFeeReceiver(address newReceiver) external;
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
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";


interface IERC2981 is IERC165 {

    function royaltyInfo( uint256 tokenId, uint256 _salePrice) external view returns(address receiver, uint256 royaltyAmount);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}