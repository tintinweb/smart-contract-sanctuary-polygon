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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library Array256Lib {
    function contains(uint256[] memory array, uint256 value) internal pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    function remove(uint256[] memory array, uint256 value) internal pure returns (uint256[] memory){
        uint256[] memory newArray = new uint256[](array.length - 1);
        uint idx = 0;
        for (uint i = 0; i < array.length; i++) {
            if (array[i] != value) {
                newArray[idx++] = array[i];
            }
        }
        require(newArray.length == array.length - 1, "Failed to remove");
        return newArray;
    }

    function removeAll(uint256[] memory array, uint256[] memory valuesToRemove) internal pure returns (uint256[] memory) {
        uint256[] memory newArray = new uint256[](array.length - valuesToRemove.length);
        uint idx = 0;
        for (uint i = 0; i < array.length; i++) {
            if (!contains(valuesToRemove, array[i])) {
                newArray[idx++] = array[i];
            }
        }
        require(newArray.length == array.length - valuesToRemove.length, "Failed to remove");
        return newArray;
    }

    function add(uint256[] memory array, uint256 value) internal pure returns (uint256[] memory){
        uint256[] memory newArray = new uint256[](array.length + 1);
        for (uint i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        newArray[array.length] = value;
        return newArray;
    }

    function addAll(uint256[] memory array, uint256[] memory valuesToAdd) internal pure returns (uint256[] memory){
        uint256[] memory newArray = new uint256[](array.length + valuesToAdd.length);
        for (uint i = 0; i < array.length; i++) {
            newArray[i] = array[i];
        }
        for (uint i = array.length; i < array.length + valuesToAdd.length; i++) {
            newArray[i] = valuesToAdd[i - array.length];
        }
        return newArray;
    }

    function containsAddress(address[] memory array, address value) internal pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    function removeAddr(address[] memory array, address value) internal pure returns (address[] memory){
        address[] memory newArray = new address[](array.length - 1);
        uint idx = 0;
        for (uint i = 0; i < array.length; i++) {
            if (array[i] != value) {
                newArray[idx++] = array[i];
            }
        }
        return newArray;
    }
}

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

//import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

interface IERC721Rentable is IERC721Enumerable {
    function isTokenRented(uint256 tokenId) external view returns (bool);

    function safeTransferFromForRent(address from, address to, uint256 tokenId, bytes memory _data) external;
}

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IRentingTypes.sol";

interface IMyListingsStorage is IRentingTypes {

    function rentalAssetsCount(TradedNft nft, address owner) external view returns (uint256);

    function rentalOwnersAssetByIndex(TradedNft nft, address owner, uint256 idx) external view returns (uint256);

    function getRentalAssetsByOwner(TradedNft nft, address owner, uint page, uint pageSize) external view returns (uint256[] memory);

    function add(TradedNft nft, address owner, uint256 id) external;

    function remove(TradedNft nft, address owner, uint256 id) external;

    function addAll(TradedNft nft, address owner, uint256[] memory ids) external;

    function removeAll(TradedNft nft, address owner, uint256[] memory ids) external;

}

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IRentingTypes.sol";

interface IRentingContractStorage is IRentingTypes {

    function getLandStatus(uint256 landId) external view returns (TokenRentingStatus);

    function getBotStatus(uint256 botId) external view returns (TokenRentingStatus);

    function renewRenting(uint256 id, uint256 renewTs, uint256 rentingEndTs) external;

    function getRentingInfo(uint256 landId) external view returns (RentingInfo memory);

    function getCollection(uint256 id) external view returns (Collection memory);

    function createRenting(BattleSet memory bs, RentingType rt, Coin coin, uint256 price, address owner, address renter,
        uint256 rentingEnd, uint256 collectionId, bool perpetual, address[] memory whitelist, uint revenueShare) external;

    function deleteListingInfo(uint256 landId) external;

    function getListingInfo(uint256 landId) external view returns (ListingInfo memory);

    function updateCollectionRentedAssets(uint256 id, uint256[] memory availableLands, uint256[] memory availableBotsIds,
        uint256[] memory rentedLandIds, uint256[] memory rentedBotsIds) external;

    function deleteRenting(uint256 landId) external;

    function createCollection(address assetsOwner, uint256[] memory landIds, uint256[] memory botIds,
        bool perpetual, address[] memory players, PaymentData memory pd) external returns (uint256);

    function editCollection(uint256 id, Coin coin, uint256 price, RentingType rentingType, bool perpetual, uint revenueShare) external;

    function addAssetsToCollection(uint id, uint256[] memory landIds, uint256[] memory botIds) external;

    function removeListedLand(uint id, uint256 landIdToRemove) external;

    function pushToBeRemovedLands(uint id, uint256 landIdToRemove) external;

    function pushToBeRemovedBots(uint id, uint256 botIdToRemove) external;

    function removeListedBot(uint id, uint256 botIdToRemove) external;

    function disbandCollection(uint256 id) external returns (bool);

    function processCollectionRentalEnd(RentingInfo memory ri) external returns (Collection memory);

    function createListingInfo(BattleSet memory bs, RentingType rt, address owner, Coin coin, uint256 price,
        bool perpetual, address[] memory whitelist, uint revenueShare) external;

    function addPlayersToCollection(uint id, address[] memory players) external;

    function removePlayersFromCollection(uint id, address player) external;

    function setRentingCancelTs(uint256 id, uint256 cancelTs) external;

    function getCollectionIdByIndex(uint256 idx) external view returns (uint256);

    function getCollectionsCount() external view returns (uint256);

    function getRentingIdByIndex(uint256 idx) external view returns (uint256);

    function getRentingsCount() external view returns (uint256);

    function getListingIdByIndex(uint256 idx) external view returns (uint256);

    function getListingCount() external view returns (uint256);
}

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRentingTypes {

    enum Coin {
        XOIL,
        RBLS,
        WETH,
        USDC,
        BUSD,
        USDT,
        DAI
    }

    enum RentingType {
        FIXED_PRICE,
        REVENUE_SHARE
    }

    enum TokenRentingStatus {
        AVAILABLE,
        LISTED_BATTLE_SET,
        LISTED_COLLECTION,
        RENTED
    }

    struct BattleSet {
        uint256 landId;
        uint256[] botsIds;
    }

    struct ListingInfo {
        BattleSet battleSet;
        RentingType rentingType;
        Coin chargeCoin;
        uint256 listingTs;
        address owner;
        uint256 price;
        bool perpetual;
        address[] whitelist;
        uint revenueShare;
    }

    struct RentingInfo {
        uint256 id;
        BattleSet battleSet;
        RentingType rentingType;
        Coin chargeCoin;
        uint256 price;
        address owner;
        address renter;
        uint256 rentingTs;
        uint256 renewTs;
        uint256 rentingEndTs;
        uint256 renewedPeriodEndTs;
        uint256 cancelTs;
        uint256 collectionId;
        bool perpetual;
        address[] whitelist;
        uint revenueShare;
    }

    struct Collection {
        uint256 id;
        address owner;
        uint256[] landIds;
        uint256[] botsIds;
        uint256[] rentedLandIds;
        uint256[] rentedBotsIds;
        uint256[] landsToRemove;
        uint256[] botsToRemove;
        address[] whitelist;
        RentingType rentingType;
        Coin chargeCoin;// probaby change to uint
        uint256 price;
        bool perpetual;
        uint256 disbandTs;
        uint revenueShare;
    }

    struct PaymentData {
        RentingType rentingType;
        Coin coin;
        uint256 price;
        uint revenueShare;
    }

    enum TradedNft {
        RBXL,
        RBFB
    }

}

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./Array256Lib.sol";
import "./IRentingTypes.sol";
import "./IERC721Rentable.sol";
import "./IRentingContractStorage.sol";
import "./IMyListingsStorage.sol";

interface IRentingHistory is IRentingTypes {
    function saveRentingInfo(RentingInfo memory ri) external;
}

contract RenterClient is Context, IRentingTypes, Ownable, Pausable {

    IERC721Rentable private landsContract;
    IERC721Rentable private botsContract;
    IMyListingsStorage private myListingsStorage;
    IRentingContractStorage private storageContract;
    IRentingHistory private rentingHistory;

    //    uint private constant defaultRentingDuration = 7 days;
    //    uint private constant rentingRenewalPeriodGap = 2 days;

    uint private defaultRentingDuration = 30 minutes;
    uint private rentingRenewalPeriodGap = 20 minutes;

    uint256[] private rentedLands;
    mapping(uint256 => uint256) private rentedLandsIndex;

    mapping(Coin => address) paymentContracts;

    uint256 private feePercent = 5;
    address private feeCollectorAddress;
    bool private chargeMinGuaranteeOnRenew;
    bool private chargeMinGuarantee;

    event RentBattleSetStart(uint256 indexed landId, uint256[] botIds, address renter, address owner);
    event RentCollectionStart(uint256 indexed landId, uint256[] botIds, uint256 collectionId, address renter, address owner);
    event RentRenewed(uint256 indexed landId);
    event RentEnd(uint256 indexed landId, uint256 collectionId, address renter, address owner);
    event CollectionDisband(uint256 id, bool completed);

    constructor(address storageContractAddress, address myListingsStorageAddress, address rentingHistoryAddr) {
        storageContract = IRentingContractStorage(storageContractAddress);
        myListingsStorage = IMyListingsStorage(myListingsStorageAddress);
        rentingHistory = IRentingHistory(rentingHistoryAddr);
        feeCollectorAddress = _msgSender();
    }


    function setTokensAddresses(address lands, address bots, address xoil, address rbls, address weth) onlyOwner external {
        paymentContracts[Coin.XOIL] = xoil;
        paymentContracts[Coin.RBLS] = rbls;
        paymentContracts[Coin.WETH] = weth;
        landsContract = IERC721Rentable(lands);
        botsContract = IERC721Rentable(bots);
    }

    function setListingSettings(
        uint newRentingDuration,
        uint newRentingRenewalPeriodGap,
        uint256 newFeePercent,
        address newFeeCollectorAddress,
        bool newChargeMinGuarantee,
        bool newChargeMinGuaranteeOnRenew
    ) onlyOwner external {
        defaultRentingDuration = newRentingDuration;
        rentingRenewalPeriodGap = newRentingRenewalPeriodGap;
        feePercent = newFeePercent;
        feeCollectorAddress = newFeeCollectorAddress;
        chargeMinGuaranteeOnRenew = newChargeMinGuaranteeOnRenew;
        chargeMinGuarantee = newChargeMinGuarantee;
    }

    function updateFeesConfiguration(uint256 newFeePercent, address newFeeCollectorAddress) external onlyOwner {
        require(newFeePercent < 100, "Incorrect fee");
        feePercent = newFeePercent;
        feeCollectorAddress = newFeeCollectorAddress;
    }

    function rentBattleSet(uint256 landId) whenNotPaused external {
        ListingInfo memory li = storageContract.getListingInfo(landId);
        require(li.listingTs != 0, "Listing not found");
        if (li.whitelist.length > 0) {
            require(Array256Lib.containsAddress(li.whitelist, _msgSender()), "Address not whitelisted");
        }

        if ((li.rentingType == RentingType.FIXED_PRICE || chargeMinGuarantee)  && !transferPayment(li.chargeCoin, li.price, _msgSender(), li.owner)) {
            revert("Failed to transfer payment");
        }

        storageContract.deleteListingInfo(landId);

        safeTransferFromForRent(address(storageContract), _msgSender(), li.battleSet.landId, li.battleSet.botsIds);

        storageContract.createRenting(li.battleSet, li.rentingType, li.chargeCoin, li.price, li.owner, _msgSender(), block.timestamp + defaultRentingDuration,
            0, li.perpetual, li.whitelist, li.revenueShare);

        addTokenToRentedTokensList(li.battleSet.landId);

        emit RentBattleSetStart(landId, li.battleSet.botsIds, _msgSender(), li.owner);
    }

    function rentFromCollection(uint256 id, uint256 landId, uint256[] memory botsIds) whenNotPaused external {
        Collection memory collection = storageContract.getCollection(id);
        require(collection.owner != address(0x0), "Collection not found");
        require(landId != 0 && botsIds.length == 3, "Incorrect token ids");
        require(collection.disbandTs == 0, "Collection disbanded");
        require(!userHasActiveRentings(collection, _msgSender()), "Already rented from this collection");
        if (collection.whitelist.length > 0) {
            require(Array256Lib.containsAddress(collection.whitelist, _msgSender()), "Address not whitelisted");
        }

        if ((collection.rentingType == RentingType.FIXED_PRICE || chargeMinGuarantee) && !transferPayment(collection.chargeCoin, collection.price, _msgSender(), collection.owner)) {
            revert("Cannot charge payment");
        }

        safeTransferFromForRent(address(storageContract), _msgSender(), landId, botsIds);

        storageContract.updateCollectionRentedAssets(id, Array256Lib.remove(collection.landIds, landId),
            Array256Lib.removeAll(collection.botsIds, botsIds), Array256Lib.add(collection.rentedLandIds, landId),
            Array256Lib.addAll(collection.rentedBotsIds, botsIds));

        BattleSet memory bs = BattleSet({landId : landId, botsIds : botsIds});
        storageContract.createRenting(bs, collection.rentingType, collection.chargeCoin, collection.price, collection.owner, _msgSender(),
            block.timestamp + defaultRentingDuration, collection.id, collection.perpetual, new address[](0), collection.revenueShare);

        addTokenToRentedTokensList(bs.landId);

        emit RentCollectionStart(landId, botsIds, id, _msgSender(), collection.owner);
    }

    function userHasActiveRentings(Collection memory collection, address renter) private view returns (bool) {
        for (uint i = 0; i < collection.rentedLandIds.length; i++) {
            if (landsContract.ownerOf(collection.rentedLandIds[i]) == renter) {
                return true;
            }
        }
        return false;
    }

    function renewRental(uint256 landId) whenNotPaused external {
        RentingInfo memory ri = storageContract.getRentingInfo(landId);
        require(ri.perpetual && ri.cancelTs == 0, "The listing is not perpetual or cancelled");
        require(ri.renewTs < ri.rentingEndTs - rentingRenewalPeriodGap, "Already renewed for next period");
        require(ri.renter == _msgSender(), "Caller is not renter");
        require(block.timestamp < ri.rentingEndTs && block.timestamp > ri.rentingEndTs - rentingRenewalPeriodGap, "Renew is not available yet");
        if (ri.collectionId != 0) {
            Collection memory collection = storageContract.getCollection(ri.collectionId);
            require(collection.disbandTs == 0, "Collection disbanded");
            require(collection.whitelist.length == 0 || Array256Lib.containsAddress(collection.whitelist, _msgSender()), "Player not whitelisted to renew listing");
            require(!ifCollectionAssetNeedsToBeRemoved(ri.collectionId, ri.battleSet.landId, ri.battleSet.botsIds), "Some asset removed from collection");
        }

        if ((ri.rentingType == RentingType.FIXED_PRICE || chargeMinGuaranteeOnRenew) && !transferPayment(ri.chargeCoin, ri.price, _msgSender(), ri.owner)) {
            revert("Cannot charge payment");
        }

        storageContract.renewRenting(landId, block.timestamp, ri.rentingEndTs + defaultRentingDuration);

        emit RentRenewed(landId);
    }

    function getTotalRentings() external view returns (uint256) {
        return rentedLands.length;
    }

    //    function rentedLandByIdx(uint idx) public view returns (uint256) {
    //        return rentedLands[idx];
    //    }

    function getFinishedRentingLands(uint256 searchIdxFrom, uint256 searchIdxTo) external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](searchIdxTo - searchIdxFrom);
        uint finishedCounter = 0;
        for (uint i = searchIdxFrom; i < searchIdxTo; i++) {
            uint256 landId = rentedLands[i];
            if (storageContract.getRentingInfo(landId).rentingEndTs <= block.timestamp) {
                ids[finishedCounter++] = landId;
            }
        }
        if (finishedCounter == 0) {
            return new uint[](0);
        }
        uint[] memory trimmedResult = new uint[](finishedCounter);
        for (uint j = 0; j < finishedCounter; j++) {
            trimmedResult[j] = ids[j];
        }
        return trimmedResult;
    }

    function transferPayment(Coin coin, uint256 price, address from, address to) private returns (bool) {
        IERC20 paymentContract = IERC20(paymentContracts[coin]);
        uint256 fee = (price * feePercent) / 100;
        return paymentContract.transferFrom(from, feeCollectorAddress, fee)
        && paymentContract.transferFrom(from, to, price - fee);
    }

    function completeRentings(uint256[] memory landIds) external {
        for (uint i = 0; i < landIds.length; i++) {
            completeRenting(landIds[i]);
        }
    }

    function completeRenting(uint256 landId) private {
        RentingInfo memory ri = storageContract.getRentingInfo(landId);
        if (ri.rentingTs == 0 || ri.rentingEndTs > block.timestamp) {
            return;
        }

        storageContract.deleteRenting(landId);
        rentingHistory.saveRentingInfo(ri);

        if (ri.collectionId != 0) {
            completeCollectionRental(ri);
        } else {
            completeBattleSetRental(ri);
        }

        _removeTokenFromRentedTokensList(landId);

        emit RentEnd(landId, ri.collectionId, ri.renter, ri.owner);
    }

    function completeCollectionRental(RentingInfo memory ri) private {
        Collection memory collection = storageContract.getCollection(ri.collectionId);

        if (Array256Lib.contains(collection.landsToRemove, ri.battleSet.landId)) {
            // owner removed lands from collection
            landsContract.transferFrom(ri.renter, ri.owner, ri.battleSet.landId);
            myListingsStorage.remove(TradedNft.RBXL, ri.owner, ri.battleSet.landId);
        } else {
            landsContract.transferFrom(ri.renter, address(storageContract), ri.battleSet.landId);
        }


        for (uint i = 0; i < 3; i++) {
            if (Array256Lib.contains(collection.botsToRemove, ri.battleSet.botsIds[i])) {
                botsContract.transferFrom(ri.renter, ri.owner, ri.battleSet.botsIds[i]);
                myListingsStorage.remove(TradedNft.RBFB, ri.owner, ri.battleSet.botsIds[i]);
            } else {
                botsContract.transferFrom(ri.renter, address(storageContract), ri.battleSet.botsIds[i]);
            }
        }

        collection = storageContract.processCollectionRentalEnd(ri);
        if (collection.disbandTs != 0 && collection.rentedLandIds.length == 0 && storageContract.disbandCollection(ri.collectionId)) {
            transferTokens(collection.landIds, collection.botsIds, address(storageContract), collection.owner);

            myListingsStorage.removeAll(TradedNft.RBXL, ri.owner, collection.landIds);
            myListingsStorage.removeAll(TradedNft.RBFB, ri.owner, collection.botsIds);

            emit CollectionDisband(ri.collectionId, true);
        }
    }

    function completeBattleSetRental(RentingInfo memory ri) private {
        address returnTo = ri.owner;
        if (ri.cancelTs == 0 && ri.perpetual) {
            storageContract.createListingInfo(ri.battleSet, ri.rentingType, ri.owner, ri.chargeCoin, ri.price, ri.perpetual,
                ri.whitelist, ri.revenueShare);
            returnTo = address(storageContract);
        } else {
            myListingsStorage.remove(TradedNft.RBXL, ri.owner, ri.battleSet.landId);
            myListingsStorage.removeAll(TradedNft.RBFB, ri.owner, ri.battleSet.botsIds);
        }

        landsContract.transferFrom(ri.renter, returnTo, ri.battleSet.landId);
        for (uint i = 0; i < 3; i++) {
            botsContract.transferFrom(ri.renter, returnTo, ri.battleSet.botsIds[i]);
        }
    }

    function transferTokens(uint256[] memory landIds, uint256[] memory botIds, address from, address to) private {
        for (uint i = 0; i < landIds.length; i++) {
            landsContract.transferFrom(from, to, landIds[i]);
        }
        for (uint i = 0; i < botIds.length; i++) {
            botsContract.transferFrom(from, to, botIds[i]);
        }
    }


    function addTokenToRentedTokensList(uint256 tokenId) private {
        rentedLandsIndex[tokenId] = rentedLands.length;
        rentedLands.push(tokenId);
    }


    function _removeTokenFromRentedTokensList(uint256 tokenId) private {
        uint256 lastTokenIndex = rentedLands.length - 1;
        uint256 tokenIndex = rentedLandsIndex[tokenId];

        uint256 lastTokenId = rentedLands[lastTokenIndex];

        rentedLands[tokenIndex] = lastTokenId;
        rentedLandsIndex[lastTokenId] = tokenIndex;

        delete rentedLandsIndex[tokenId];
        rentedLands.pop();
    }

    function safeTransferFromForRent(address from, address to, uint256 landId, uint256[] memory botIds) private {
        landsContract.safeTransferFromForRent(from, to, landId, "");
        for (uint i = 0; i < botIds.length; i++) {
            botsContract.safeTransferFromForRent(from, to, botIds[i], "");
        }
    }


    function ifCollectionAssetNeedsToBeRemoved(uint256 collectionId, uint256 landId, uint256[] memory botIds) private view returns (bool) {
        Collection memory collection = storageContract.getCollection(collectionId);
        if (Array256Lib.contains(collection.landsToRemove, landId)) {
            return true;
        }
        for (uint i = 0; i < botIds.length; i++) {
            if (Array256Lib.contains(collection.botsToRemove, botIds[i])) {
                return true;
            }
        }
        return false;
    }


    /**
    * @dev Pauses operations.
    */
    function setPaused(bool pause) external onlyOwner {
        if (pause) {
            _pause();
        } else {
            _unpause();
        }
    }
}