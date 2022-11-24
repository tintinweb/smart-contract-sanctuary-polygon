// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "./IAccountContract.sol";
import "./IArtListingNFT.sol";
import "./IArtLicenseNFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LicensTransactionContract is Ownable{
    
    IAccountContract accountContract;
    IArtListingNFT artListingNFT;
    IArtLicenseNFT artLicenseNFT;
    IERC20 public immutable usdt;
    uint256 taxPercent;
    mapping(uint256 => ListingDetails) public listingInfo;
    mapping(uint256 => bool) public blacklistListings;
    struct ListingDetails {
        uint256 id;
        string creativeCid;
        string licenseCid;
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

    
    uint256 totalListing;
    event ListingUpdated(
        ListingDetails listingDetails
    );
    event LicenseIssued(
        uint256 listingId,
        uint256 licenseNFTTokenId,
        address licensee,
        string licenseCid
    );
    event BlacklistStatusChanged(
        uint256 listingId,
        bool isBlacklisted
    );
    constructor(address _accountContract, address _artListingNFT, address _licenseNFT, address _usdt, uint256 _taxPercent){
        accountContract = IAccountContract(_accountContract);
        artListingNFT = IArtListingNFT(_artListingNFT);
        artLicenseNFT  = IArtLicenseNFT(_licenseNFT);
        usdt = IERC20(_usdt);
        taxPercent = _taxPercent;
    }
    function changeaccountContract(address _newaccountContract) external{
        accountContract = IAccountContract(_newaccountContract);
    }
    function changeArtListingNFTContract(address _newNFTContract) external{
        artListingNFT = IArtListingNFT(_newNFTContract);
    }
    function changeLicenseContract(address _newLicenseContract) external{
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

    function createListing(string memory _listingCID, string memory _licenseCID, uint256 _price, bool _isExclusive, uint256 _quantity, uint256 _exclusivitySurcharge, bool _isUnlimitedSupply) external {
        require(accountContract.isRegistered(msg.sender),"You have to create creator profile first !");
        totalListing++;
        uint256 tokenId = artListingNFT.safeMint(msg.sender,_listingCID);
        ListingDetails memory _listingInfo = ListingDetails(totalListing, _listingCID, _licenseCID, tokenId, msg.sender, _price,  _isExclusive, _quantity, _exclusivitySurcharge, _isUnlimitedSupply, 0, false);
        listingInfo[totalListing] = _listingInfo;
        emit ListingUpdated(listingInfo[totalListing]);
    }
    
    function updateListing(uint256 _listingId, string memory _listingCID, string memory _licenseCID, uint256 _nftTokenId, uint256 _price, bool _isExclusive, uint256 _quantity, uint256 _exclusivitySurcharge, bool _isUnlimitedSupply) external {
        ListingDetails memory listing = listingInfo[_listingId];
        require(msg.sender == listing.owner,"You have to be listing's owner to be able to update listing !");
        require(artListingNFT.ownerOf(listing.creativeNFTTokenId) == listing.owner, "You have to hold the original creative NFT to be able to update listing !");
        
        ListingDetails memory _listingInfo = ListingDetails(totalListing, _listingCID, _licenseCID, _nftTokenId, msg.sender, _price,  _isExclusive, _quantity, _exclusivitySurcharge, _isUnlimitedSupply, 0, false);
        listingInfo[totalListing] = _listingInfo;
        emit ListingUpdated(listingInfo[totalListing]);
    }


    function license(uint256 _listingId) external{
        ListingDetails memory listing = listingInfo[_listingId];
        require(!listing.saleClosed, "You cannot license this creative");
        if(listing.isExclusive){
            listingInfo[_listingId].saleClosed = true;
        }else{
            if(!listing.isUnlimitedSupply){
                if(listing.minted == listing.quantity){
                    listingInfo[_listingId].saleClosed = true;
                }
            }
           listingInfo[_listingId].minted++;
        }
        usdt.transferFrom(msg.sender, listing.owner, listing.price - (listing.price * taxPercent / 100));
        usdt.transferFrom(msg.sender, address(this), listing.price  * taxPercent / 100);
        require(artListingNFT.ownerOf(listing.creativeNFTTokenId) == listing.owner, "The owner no longer holding this creative's original NFT");
        artLicenseNFT.mint(msg.sender, _listingId, listing.licenseCid);
        emit LicenseIssued(_listingId, _listingId, msg.sender, listing.licenseCid);
    }
    function withdrawAll(address _to) external onlyOwner{
        require(_to != address(0) ,"Cannot be zero address");
        usdt.transfer(_to, usdt.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IAccountContract {
    function isRegistered(address _address) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IArtListingNFT {
    function safeMint(address _to, string memory _tokenUri) external returns(uint256);
    function ownerOf(uint256 tokenId) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IArtLicenseNFT {
    function mint(
        address _to,
        uint256 _tokenId,
        string memory _tokenUri
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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