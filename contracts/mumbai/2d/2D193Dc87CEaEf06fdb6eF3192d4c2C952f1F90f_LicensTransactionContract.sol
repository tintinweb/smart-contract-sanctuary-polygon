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
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
//import "@openzeppelin/contracts/interfaces/IERC2771.sol";



/**
 * @dev Context variant with ERC2771 support.
 */
contract ERC2771ContextLocal is Context{
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
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
    function safeMint(address _to, string memory _tokenUri) external returns(uint256);
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
import "./IAccountContract.sol";
import "./IArtListingNFT.sol";
import "./IArtLicenseNFT.sol";
import "./ListingIDGenerator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC2771ContextLocal.sol";


contract LicensTransactionContract is Ownable, ReentrancyGuard, ERC2771ContextLocal{
    
    IAccountContract accountContract;
    IArtListingNFT artListingNFT;
    IArtLicenseNFT artLicenseNFT;
    ListingIDGenerator private _idGenerator;

    mapping(uint256 => ListingDetails) public listingInfo;
    mapping(uint256 => bool) public blacklistListings;

    struct ListingDetails {
        uint256 id;
        string[3] cidArray; //Array to store listingCid, creativeCid, licenseCid in order
        uint256 creativeNFTTokenId;
        address owner;
        uint256 price;
        bool isExclusive;
        uint256 quantity;
        uint256 exclusivitySurcharge;
        bool isUnlimitedSupply;
        uint256 minted;
        bool saleClosed;
    }

    event ListingUpdated(
        ListingDetails listingDetails
    );
    event LicenseIssued(
        uint256 listingId,
        uint256 licenseNFTTokenId,
        address licensee,
        string licenseCid,
        bool isExclusive
    );
    event BlacklistStatusChanged(
        uint256 listingId,
        bool isBlacklisted
    );

    constructor(address _accountContract, 
                address _artListingNFT, 
                address _licenseNFT, 
                ListingIDGenerator idGenerator,
                address trustedForwarder
                ) ERC2771ContextLocal(trustedForwarder) {

        require(_accountContract != address(0),"Account contract cannot be zero address");
        require(_artListingNFT != address(0),"ArtListingNFT contract cannot be zero address");
        require(_licenseNFT != address(0),"License NFT contract cannot be zero address");

        accountContract = IAccountContract(_accountContract);
        artListingNFT = IArtListingNFT(_artListingNFT);
        artLicenseNFT  = IArtLicenseNFT(_licenseNFT);

        _idGenerator = idGenerator;
    }

    function _msgSender() internal view override(Context, ERC2771ContextLocal) returns (address sender) {
        return ERC2771ContextLocal._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771ContextLocal) returns (bytes calldata) {
        return ERC2771ContextLocal._msgData();
    }

    function changeaccountContract(address _newaccountContract) external onlyOwner{
        require(_newaccountContract != address(0),"Account contract cannot be zero address");
        accountContract = IAccountContract(_newaccountContract);
    }

    function changeArtListingNFTContract(address _newNFTContract) external onlyOwner{
        require(_newNFTContract != address(0),"ArtListingNFT contract cannot be zero address");
        artListingNFT = IArtListingNFT(_newNFTContract);
    }

    function changeLicenseContract(address _newLicenseContract) external onlyOwner{
        require(_newLicenseContract != address(0),"License NFT contract cannot be zero address");
        artLicenseNFT  = IArtLicenseNFT(_newLicenseContract);
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
        string calldata _listingCID, 
        string calldata _creativeCID, 
        string calldata _licenseCID, 
        uint256 _price, 
        bool _isExclusive, 
        uint256 _quantity, 
        uint256 _exclusivitySurcharge, 
        bool _isUnlimitedSupply
        ) external nonReentrant {

        require(accountContract.isRegistered(_msgSender()),"You have to create creator profile first !");

        uint256 newID = _idGenerator.getNewID(); // Generate a new unique ID using the ListingIDGenerator

        listingInfo[newID] = ListingDetails({
            id: newID,
            cidArray: [_listingCID, _creativeCID, _licenseCID],
            owner: _msgSender(),
            price: _price,
            isExclusive: _isExclusive,
            quantity: _quantity,
            exclusivitySurcharge: _exclusivitySurcharge,
            isUnlimitedSupply: _isUnlimitedSupply,
            creativeNFTTokenId: 0, // Set the initial value, which will be updated in the next line
            minted: 0,
            saleClosed: false
        });
        
        listingInfo[newID].creativeNFTTokenId = artListingNFT.safeMint(newID, _msgSender(), _listingCID);

        emit ListingUpdated(listingInfo[newID]);
        }

    function updateListing(
        uint256 _listingId, 
        string calldata _listingCID, 
        string calldata _creativeCID, 
        string calldata _licenseCID,
        uint256 _price, 
        bool _isExclusive, 
        uint256 _quantity, 
        uint256 _exclusivitySurcharge,
        bool _isUnlimitedSupply
        ) external nonReentrant {

        uint256 tokenId = listingInfo[_listingId].creativeNFTTokenId;
        require(artListingNFT.ownerOf(tokenId) == _msgSender(), "msgSender is not listing's owner!");

        //require(artListingNFT.ownerOf(listingInfo[_listingId].creativeNFTTokenId) == listingInfo[_listingId].owner, "The current owner of the NFT is not the original owner, so the listing cannot be updated");
        //require(_msgSender() == listingInfo[_listingId].owner, "msgSender is not listing's owner!");
        //require(_creator == _msgSender(), "msgSender is not the same as the passed address");

        ListingDetails storage listing = listingInfo[_listingId];

        listing.cidArray[0] = _listingCID;
        listing.cidArray[1] = _creativeCID;
        listing.cidArray[2] = _licenseCID;

        listing.price = _price;
        listing.isExclusive = _isExclusive;
        listing.quantity = _quantity;
        listing.exclusivitySurcharge = _exclusivitySurcharge;
        listing.isUnlimitedSupply = _isUnlimitedSupply;

        artListingNFT.setTokenURI(_listingId, _listingCID);

        emit ListingUpdated(listing);
    }

    function license(uint256 _listingId, address _to, bool _exclusivePurchase) external nonReentrant {
        ListingDetails memory listing = listingInfo[_listingId];
        require(!listing.saleClosed, "You cannot license this creative");
        require(!blacklistListings[_listingId],"This listing has been blacklisted");
        require(_to == _msgSender(), "msgSender is not the same as the passed address");
        uint256 price = listing.price;
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
 
        require(artListingNFT.ownerOf(listing.creativeNFTTokenId) == listing.owner, "The owner no longer holding this creative's original NFT");
        uint256 licenseNFTTokenId = artLicenseNFT.safeMint(_msgSender(), listing.cidArray[2]);
        emit LicenseIssued(_listingId, licenseNFTTokenId, _msgSender(), listing.cidArray[2], _exclusivePurchase);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ListingIDGenerator {
    mapping(uint256 => bool) private _usedIDs;
    uint256 private _currentID = 1;

    function getNewID() external returns (uint256) {
        uint256 newID = _currentID;
        while (_usedIDs[newID]) {
            newID++;
        }
        _usedIDs[newID] = true;
        _currentID = newID + 1;
        return newID;
    }
}