// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
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
pragma solidity ^0.8.9;

interface IAccountContract {
    function isRegistered(address _address) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IArtLicenseNFT {
    function safeMint(uint256 _tokenId, address _to, string memory _tokenUri) external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IArtListingNFT {
    function safeMint(uint256 _tokenId, address _to, string memory _tokenUri) external returns(uint256);
    function ownerOf(uint256 tokenId) external view returns(address);
    function setTokenURI(uint256 _tokenId, string memory _tokenUri) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract LicenseIDGenerator {
    mapping(uint256 => bool) private _usedIDs;
    uint256 private _currentID = 1;

    function getNewLicenseID() external returns (uint256) {
        uint256 newLicenseID = _currentID;
        while (_usedIDs[newLicenseID]) {
            newLicenseID++;
        }
        _usedIDs[newLicenseID] = true;
        _currentID = newLicenseID + 1;
        return newLicenseID;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./IAccountContract.sol";
import "./IArtListingNFT.sol";
import "./IArtLicenseNFT.sol";
import "./ListingIDGenerator.sol";
import "./LicenseIDGenerator.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";


contract LicensTransactionContract is Ownable, ReentrancyGuard, ERC2771Recipient{
    
    IAccountContract accountContract;
    IArtListingNFT artListingNFT;
    IArtLicenseNFT artLicenseNFT;
    ListingIDGenerator private _listingIdGenerator;
    LicenseIDGenerator private _licenseIdGenerator;
    address usdcPayoutAddress;
    mapping (address => uint256) public unpaidPayout;

    IERC20 public usdc;
    uint256 taxPercent;
    uint256 minimumFee;

    mapping(uint256 => ListingDetails) public listingInfo;
    mapping(uint256 => bool) public blacklistListings;

    mapping(uint256 => RoyaltyPayout) public royaltyDist;

    struct ListingDetails {
        uint256 id; // this is the listing id, as well token id
        string listingCid;
        string creativeCid;
        string licenseCid;        
        uint256 creativeNFTTokenId; // this counts how many nft minted per user address
        address owner;
        uint256 price;
        bool isExclusive;
        uint256 quantity;
        uint256 exclusivitySurcharge;
        bool isUnlimitedSupply;
        uint256 minted;
        bool saleClosed;
        address[] royaltyAddresses; // Array to store royalty addresses
        uint256[] royaltyShares; // Array to store royalty shares
    }

    struct ListingParams {
        string listingCID;
        string creativeCID;
        string licenseCID;
        uint256 price;
        bool isExclusive;
        uint256 quantity;
        uint256 exclusivitySurcharge;
        bool isUnlimitedSupply;
        address[] royaltyAddresses;
        uint256[] royaltyShares;
    }

    struct RoyaltyPayout {
        uint256 listingId;
        uint256 licenseId;
        address[] royaltyAddresses;
        uint256[] royaltyShares;
        uint256 afterTax;
        uint256 price;
        uint256 tax;
        bool paid;
        uint256 paidTimestamp;
    }
    
    event ListingUpdated(
        ListingDetails listingDetails
    );

    event LicenseIssued(
        uint256 listingId,
        uint256 licenseNFTTokenId,
        string transactionId,
        address licensee,
        string licenseCid,
        bool isExclusive
    );
    event BlacklistStatusChanged(
        uint256 listingId,
        bool isBlacklisted
    );

    event RoyaltyPaid(RoyaltyPayout RoyaltyPayout);
    event UsdcPayoutAddressUpdated(
        address newAddress
    );

    constructor(address _accountContract, 
                address _artListingNFT, 
                address _licenseNFT, 
                ListingIDGenerator listingIdGenerator,
                LicenseIDGenerator licenseIdGenerator,
                address forwarder,
                address usdcAddress,
                uint256 _taxPercent,
                uint256 _minimumFee
                )  {

        require(_accountContract != address(0),"Account contract cannot be zero address");
        require(_artListingNFT != address(0),"ArtListingNFT contract cannot be zero address");
        require(_licenseNFT != address(0),"License NFT contract cannot be zero address");

        accountContract = IAccountContract(_accountContract);
        artListingNFT = IArtListingNFT(_artListingNFT);
        artLicenseNFT  = IArtLicenseNFT(_licenseNFT);

        _listingIdGenerator = listingIdGenerator;
        _licenseIdGenerator = licenseIdGenerator;
        _setTrustedForwarder(forwarder);

        usdc = IERC20(usdcAddress);
    }

    // Override _msgSender and _msgData to fix the inheritance conflict.
    function _msgSender() internal override(Context, ERC2771Recipient) view returns (address) {
        return ERC2771Recipient._msgSender();
    }

    function _msgData() internal override(Context, ERC2771Recipient) view returns (bytes calldata) {
        return ERC2771Recipient._msgData();
    }
    function updateUsdcPayoutAddress(address _newAddress) external onlyOwner{
        usdcPayoutAddress = _newAddress;
        emit UsdcPayoutAddressUpdated(_newAddress);
    }

    function blacklistListing(uint256 _listingId) external onlyOwner{
        blacklistListings[_listingId] = true;
        emit BlacklistStatusChanged(_listingId, true);
    }

    function unblacklistListing(uint256 _listingId) external onlyOwner{
        blacklistListings[_listingId] = false;
        emit BlacklistStatusChanged(_listingId, false);
    }

    function createListing (
        ListingParams calldata params
        ) external nonReentrant {

        require(accountContract.isRegistered(_msgSender()),"You have to create creator profile first !");
        require(params.royaltyAddresses.length == params.royaltyShares.length, "Royalty Arrays length mismatch");

        uint256 newID = _listingIdGenerator.getNewListingID(); // Generate a new unique ID using the ListingIDGenerator

        listingInfo[newID] = ListingDetails({
            id: newID,
            listingCid: params.listingCID,
            creativeCid: params.creativeCID,
            licenseCid: params.licenseCID,
            owner: _msgSender(),
            price: params.price,
            isExclusive: params.isExclusive,
            quantity: params.quantity,
            exclusivitySurcharge: params.exclusivitySurcharge,
            isUnlimitedSupply: params.isUnlimitedSupply,
            creativeNFTTokenId: 0,
            minted: 0,
            saleClosed: false,
            royaltyAddresses: params.royaltyAddresses,
            royaltyShares: params.royaltyShares
        });
        
        listingInfo[newID].creativeNFTTokenId = artListingNFT.safeMint(newID, _msgSender(), params.listingCID);
        
        require(artListingNFT.ownerOf(newID) == _msgSender(), "the owner of creativeNFTtoken is not msgSender");
        
        emit ListingUpdated(listingInfo[newID]);
        }

  
    function updateListing(
        uint256 _listingId,
        ListingParams calldata params
        ) external nonReentrant {

        require(artListingNFT.ownerOf(_listingId) == listingInfo[_listingId].owner, "The current owner of the NFT is not the original owner, so the listing cannot be updated");
        require(_msgSender() == listingInfo[_listingId].owner, "msgSender is not listing's owner!");
        require(params.royaltyAddresses.length == params.royaltyShares.length, "Royalty Arrays length mismatch");

        ListingDetails memory listing = listingInfo[_listingId];

        listing.listingCid = params.listingCID; 
        listing.creativeCid = params.creativeCID;
        listing.licenseCid = params.licenseCID;

        listing.price = params.price;
        listing.isExclusive = params.isExclusive;
        listing.quantity = params.quantity;
        listing.exclusivitySurcharge = params.exclusivitySurcharge;
        listing.isUnlimitedSupply = params.isUnlimitedSupply;

        listing.royaltyAddresses = params.royaltyAddresses;
        listing.royaltyShares = params.royaltyShares;
        artListingNFT.setTokenURI(_listingId, params.listingCID);

        emit ListingUpdated(listing);
    }
    
    function license(uint256 _listingId, address _to, string calldata _transactionId, bool _exclusivePurchase) public nonReentrant {
        ListingDetails memory listing = listingInfo[_listingId];

        require(!listing.saleClosed, "You cannot license this creative");
        require(!blacklistListings[_listingId],"This listing has been blacklisted");
        uint256 price = listing.price;
        
        uint256 newID = _licenseIdGenerator.getNewLicenseID(); // Generate a new unique ID using the LicenseIDGenerator

        if(_exclusivePurchase){
            require(listing.isExclusive, "Listing do not allow exclusive license");
            require(listing.minted == 0,"Someone has minted first");
            listingInfo[_listingId].minted++;
            listingInfo[_listingId].saleClosed = true;
            price = listing.price + listing.exclusivitySurcharge;
        }else{
            if(!listing.isUnlimitedSupply){
                if(listing.minted == listing.quantity){
                    listingInfo[_listingId].saleClosed = true;
                }
            }
           listingInfo[_listingId].minted++;
        }

        require(artListingNFT.ownerOf(_listingId) == listing.owner, "The owner no longer holding this creative's original NFT");
        uint256 licenseNFTTokenId = artLicenseNFT.safeMint(newID, _msgSender(), listing.licenseCid);
        
        uint256 taxAmount = price  * taxPercent / 100;
        if(taxAmount < minimumFee){
            taxAmount = minimumFee;
        }

        uint256 afterTax = price - taxAmount;

        bool isPaid;
        if(usdc.allowance(usdcPayoutAddress, address(this)) >= afterTax &&  usdc.balanceOf(usdcPayoutAddress) >= afterTax){
            for(uint64 i; i < listing.royaltyAddresses.length; i++){
                usdc.transferFrom(usdcPayoutAddress, listing.royaltyAddresses[i], afterTax * listing.royaltyShares[i] / 100);
            }
            isPaid = true;
            emit RoyaltyPaid(royaltyDist[licenseNFTTokenId]);
        }
        royaltyDist[licenseNFTTokenId] = RoyaltyPayout({
            listingId: _listingId,
            licenseId: licenseNFTTokenId,
            royaltyAddresses: listing.royaltyAddresses,
            royaltyShares: listing.royaltyShares,
            afterTax: afterTax,
            price: price,
            tax: taxAmount,
            paid: isPaid,
            paidTimestamp: 0
        });

        emit LicenseIssued(_listingId, licenseNFTTokenId, _transactionId, _msgSender(), listing.licenseCid, _exclusivePurchase);
    }

    function mint(uint256 _listingId, address _to, string calldata _transactionId, bool _exclusivePurchase) external nonReentrant {
        require(_to == _msgSender(), "msgSender is not the same as the passed address");
        license(_listingId, _to, _transactionId, _exclusivePurchase);
    }

    function payUnpaidRoyalties(uint256[] calldata _licenseIds) external onlyOwner {
        for (uint256 i = 0; i < _licenseIds.length; i++) {
            royaltiesPayment(_licenseIds[i]);
        }
    }

    function royaltiesPayment(uint256 _licenseId) internal nonReentrant onlyOwner {
        RoyaltyPayout memory payout = royaltyDist[_licenseId];
        
        require(payout.paid == false, "Royalty is already paid");
        require(usdc.balanceOf(usdcPayoutAddress) >= payout.afterTax, "Insufficient contract balance");
        require(payout.royaltyAddresses.length == payout.royaltyShares.length, "Royalty Arrays length mismatch");
    
        for (uint256 i = 0; i < payout.royaltyAddresses.length; i++) {
            if (payout.royaltyAddresses[i] != address(0) && payout.royaltyShares[i] != 0) {
                usdc.transferFrom(usdcPayoutAddress, payout.royaltyAddresses[i], payout.royaltyShares[i] * payout.afterTax);
            }
        }

        payout.paid = true;
        payout.paidTimestamp = block.timestamp;
        
        emit RoyaltyPaid(payout);
    }

    function updateMinimumFee(uint256 _newMinFee) external onlyOwner{
        minimumFee = _newMinFee;
    }

    function updateTaxPercent(uint256 _newTax) external onlyOwner{
        taxPercent = _newTax;
    }

    function withdrawAll(address _to) external onlyOwner{
        require(_to != address(0) ,"Cannot be zero address");
        usdc.transfer(_to, usdc.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ListingIDGenerator {
    mapping(uint256 => bool) private _usedIDs;
    uint256 private _currentID = 1;

    function getNewListingID() external returns (uint256) {
        uint256 newListingID = _currentID;
        while (_usedIDs[newListingID]) {
            newListingID++;
        }
        _usedIDs[newListingID] = true;
        _currentID = newListingID + 1;
        return newListingID;
    }
}