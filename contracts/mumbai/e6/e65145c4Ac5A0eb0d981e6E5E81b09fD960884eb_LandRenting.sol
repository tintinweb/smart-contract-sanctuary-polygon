// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./utils/IBalanceVault.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
* @dev Land NFT rental system.
* Has function for list land for rent, along with edit and delete listed land detials.
* Has function for rent listed land.
* Has function for calculate rental fee according to a period of input rental time.
* Has function for claim rental fee [perform by land owners].
* Has fuction for calculate platform commission.
*/
contract LandRenting is OwnableUpgradeable, ReentrancyGuard {

    IBalanceVault public balanceVault;
    uint256 totalUnpaidBalance;
    uint256 platformCommission;
    uint256 totalPlatformCommission;

    struct landDetail {
        address owner;
        address renter;
        uint256 rentalPrice;
        uint256 rentalPeriod;
        uint256 rentalStart;
        uint256 lastClaimedTime;
        bool isReccurent;
    }
    mapping(address => mapping (uint256 => landDetail)) public lands;

    function initialize(
        address _balanceVaultAddress,
        uint256 _platformCommission
    ) public initializer {
        balanceVault = IBalanceVault(_balanceVaultAddress);
        platformCommission = _platformCommission;

      ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
      __Ownable_init();
   }

    modifier onlyLandOwner(uint256 tokenId, address nftAddress) {
        require(msg.sender == IERC721Upgradeable(nftAddress).ownerOf(tokenId), "[LandRenting.onlyLandOwner] Not land owner.");
        _;
    }

    modifier isNotRented(address _landAddress, uint256 _landId) {
        require(lands[_landAddress][_landId].renter == address(0), "[LandRenting.isNotRented] Land already rented.");
        _;
    }

    function setPlatformCommission(uint256 _platformCommission) public onlyOwner {
        platformCommission = _platformCommission;
    }

    function getLandPrice(address _landAddress, uint256 _landId) public view returns(uint256) {
        return lands[_landAddress][_landId].rentalPrice;
    }

    /**
    * @dev list and for rent.
    * unclaimed fee need to be 0 before land owners can list their lands.
    * owner, rentalPrice will be input to landDetail.
    * @param _landAddress - address of prefered land.
    * @param _landId -  ID of prefered land.
    * @param _rentalPrice -  prefered rental price per day.
    */
    function listLand(address _landAddress, uint256 _landId, uint256 _rentalPrice) 
        public 
        onlyLandOwner(_landId, _landAddress) 
        isNotRented(_landAddress, _landId) 
    {
        require(getUnclaimedFee(_landAddress, _landId) == 0, "[LandRenting.listLand] Need to claim remaining rental fee first");
        lands[_landAddress][_landId].owner = msg.sender;
        lands[_landAddress][_landId].rentalPrice = _rentalPrice;
    }

    /**
    * @dev cancel listed order.
    * @param _landAddress - address of prefered land.
    * @param _landId -  ID of prefered land.
    */
    function cancelListedOrder(address _landAddress, uint256 _landId) 
        public 
        onlyLandOwner(_landId, _landAddress)
        isNotRented(_landAddress, _landId) 
    {
        delete lands[_landAddress][_landId];
    }

    /**
    * @dev renter's address will be input in landDetail.
    * calculate total rental price and decrease tokens from renter's balanceVault according to the calculated amount.
    * startPeriod will be input to landDetail according to current timestamp.
    * @param _landAddress - address of prefered land.
    * @param _landId -  ID of prefered land.
    * @param _rentalPeriod -  prefered rental period [day(s)].
    */
    function executeRent(address _landAddress, uint256 _landId, uint256 _rentalPeriod) public isNotRented(_landAddress, _landId) {
        require(lands[_landAddress][_landId].renter == address(0), "[LandRenting.executeRent] Land already rented");
        //pay rental price
        lands[_landAddress][_landId].rentalPeriod = _rentalPeriod;
        balanceVault.decreaseBalance(msg.sender, (lands[_landAddress][_landId].rentalPrice * _rentalPeriod));
        // update deducted fee amount from renter to totalUnpaidBalance
        totalUnpaidBalance += lands[_landAddress][_landId].rentalPrice * _rentalPeriod;
        lands[_landAddress][_landId].renter = msg.sender;
        // get current time as start period
        lands[_landAddress][_landId].rentalStart = block.timestamp;
        lands[_landAddress][_landId].lastClaimedTime = lands[_landAddress][_landId].rentalStart;
    }

    /**
    * @dev calculate unclaimed rental fee. This will be used in ClaimFee function.
    * Formular - [ (current day - last time that owner claim fee) * rentalPrice(in day) ]
    * if current day exceed endDate (rental contract already ended), current date will be set to equal to endDate.
    * 86400 = amount of seconds per day. 
    * @param _landAddress - address of prefered land.
    * @param _landId -  ID of prefered land.
    */
    function getUnclaimedFee(address _landAddress, uint256 _landId) public view returns(uint256) {
        landDetail memory land = lands[_landAddress][_landId];
        uint256 currentDate = (block.timestamp - (block.timestamp % 86400)) / 86400;
        uint256 startDate = (land.rentalStart - (land.rentalStart % 86400)) / 86400;
        uint256 endDate = startDate + land.rentalPeriod;
        uint256 lastClaimedDay = (land.lastClaimedTime - (land.lastClaimedTime % 86400)) / 86400;
        if (currentDate > endDate) {
            currentDate = endDate;
        }
        uint256 dayPassed = currentDate - lastClaimedDay;
        uint256 totalFee = dayPassed * land.rentalPrice;
        return totalFee;
    }

    /**
    * @dev claim rental fee.
    * calculate and deduct platform commission from fee amount when land owner claim rental fee.
    * update total platform commission. 
    * totalPlatformCommission - refers to total amount of commission remaining in balanceVault.
    * update total unpaid balance. 
    * totalUnpaidBalance - refers to total unpaid balance that has been deducted from renter's wallet but not yet transfered to owner's wallet.
    * reset lastClaimedTime to current timestamp.
    * @param _landAddress - address of prefered land.
    * @param _landId -  ID of prefered land.
    */
    function claimFee(address _landAddress, uint256 _landId) public onlyLandOwner(_landId, _landAddress) nonReentrant {
        landDetail memory land = lands[_landAddress][_landId];
        uint256 unclaimedFee = getUnclaimedFee(_landAddress, _landId);
        uint256 platformFee = (getUnclaimedFee(_landAddress, _landId) * platformCommission) / 100;
        uint256 endDate = ((land.rentalStart - (land.rentalStart % 86400)) / 86400) + land.rentalPeriod;
        balanceVault.increaseBalance(msg.sender, unclaimedFee - platformFee);
        totalPlatformCommission += platformFee;
        totalUnpaidBalance -= unclaimedFee - platformFee;
        lands[_landAddress][_landId].lastClaimedTime = block.timestamp;
        // reset renter
        if (block.timestamp > endDate) {
            land.renter = address(0);
        }

    }

    /**g
    * @dev contract owner claim platform commission.
    */
    function claimPlatformCommission() public onlyOwner {
        balanceVault.increaseBalance(msg.sender, totalPlatformCommission);
    }

    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IBalanceVault{
    function depositNaka(uint256 _nakaAmount) external;

    function withdrawNaka(uint256 _nakaAmount) external;

    function increaseBalance(address _userAddress, uint256 _nakaAmount) external;

    function decreaseBalance(address _userAddress, uint256 _nakaAmount) external;

    function getBalance(address _address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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