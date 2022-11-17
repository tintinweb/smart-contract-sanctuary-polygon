// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./utils/IBalanceVault.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
* @dev NFT NFT rental system.
* Has function for list NFT for rent, along with edit and delete listed NFT detials.
* Has function for rent listed NFT.
* Has function for calculate rental fee according to a period of input rental time.
* Has function for claim rental fee [perform by NFT owners].
* Has fuction for calculate platform commission.
*/
contract NFTRenting is OwnableUpgradeable, AccessControlUpgradeable, PausableUpgradeable {

    IBalanceVault public balanceVault;
    uint256 totalUnpaidBalance;
    uint256 platformCommission;
    uint256 totalPlatformCommission;

    //uint256 OneMonth = 2629743;
    //uint256 OneMinute = 60;

    bytes32 public constant WORKER_ROLE = keccak256("WORKER_ROLE");

    struct RentingNFTDetail {
        bytes32 orderIdRentingNFT;
        address owner;
        address renter;
        uint256 rentalPrice;
        uint256 rentalPeriod;
        uint256 rentalStart;
        uint256 rentalEnd;
        uint256 lastClaimedTime;
        bool isReccurent;
    }

    struct RentingDetailsbyOwnerOrderId {
        address nftAddress;
        uint256 nftTokenID;
        address renter;
        uint256 rentalPrice;
        uint256 rentalPeriod;
        uint256 rentalStart;
        uint256 rentalEnd;
        uint256 lastClaimedTime;
    }

    mapping(address => mapping(uint256 => RentingNFTDetail)) public RentingNFTs; //input address of NFT and token id to output Renting Details
    mapping(address => mapping(bytes32 => RentingDetailsbyOwnerOrderId)) public RentingDetailsbyOwnerOrderIds; // input owner address and order renting id to output Renting Details
    mapping(address => bytes32[]) public ownerToListedRentingOrderIds; //input owner address to output Renting Order Ids

    /**
     * @dev Declare event for use emit `MintNFT`,`MintWithPrice`.
     */
    event ListRentingNFT(address NFTaddress, uint256 NFTID, bytes32 orderIdRentingNFT, uint256 rentalPrice, address NFTOwner);
    event CancelListedRentingNFT(address NFTaddress, uint256 NFTID, address NFTOwner);
    event EditListedRentingNFT(address NFTaddress, uint256 NFTID, uint256 newRentalPrice, address NFTOwner);
    event ExecuteRent(address NFTaddress, uint256 NFTID, uint256 rentalPeriod, address renter, uint256 rentalStart, uint256 rentalEnd, uint256 totalRenterSpent);
    event ClaimFeeRenting(address NFTaddress, uint256 NFTID, address NFTOwner, uint256 NFTOwnerReceivedAmount, uint256 unclaimedFee, uint256 platformFee, uint256 lastClaimedTime, uint256 totalUnpaidBalance);
    event ChangeOwnerRentingNFT(address NFTaddress, uint256 NFTID, address newOwner);

    function initialize(
        address _balanceVaultAddress,
        uint256 _platformCommission
    ) public initializer {
        balanceVault = IBalanceVault(_balanceVaultAddress);
        platformCommission = _platformCommission;

      ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
      __Pausable_init();
      __Ownable_init();
      __AccessControl_init();
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
   }

    modifier onlyNFTOwnerANDadmin(uint256 tokenId, address nftAddress) {
        require(msg.sender == IERC721Upgradeable(nftAddress).ownerOf(tokenId) || hasRole(WORKER_ROLE, msg.sender) , "[NFTRenting.onlyNFTOwnerANDadmin] Not NFT owner or Admin.");
        _;
    }

    modifier onlyNFTOwner(uint256 tokenId, address nftAddress) {
        require(msg.sender == IERC721Upgradeable(nftAddress).ownerOf(tokenId) , "[NFTRenting.onlyNFTOwner] Not NFT owner.");
        _;
    }

    function setPlatformCommission(uint256 _platformCommission) public {
        platformCommission = _platformCommission;
    }

    /**
    * @dev list and for rent.
    * unclaimed fee need to be 0 before NFT owners can list their RentingNFTs.
    * owner, rentalPrice will be input to RentingNFTDetail.
    * @param _NFTAddress - address of prefered NFT.
    * @param _NFTId -  ID of prefered NFT.
    * @param _rentalPrice -  prefered rental price per day.
    */
    function listRentingNFT(address _NFTAddress, uint256 _NFTId, uint256 _rentalPrice) public onlyNFTOwner(_NFTId, _NFTAddress) whenNotPaused{   
        require(_rentalPrice != 0, "[NFTRenting.listRentingNFT] Rental price can't be zero.");
        require(RentingNFTs[_NFTAddress][_NFTId].orderIdRentingNFT == 0, "[NFTRenting.listRentingNFTxw] Renting order is still running");
        require(RentingNFTs[_NFTAddress][_NFTId].owner == 0x0000000000000000000000000000000000000000, "[NFTRenting.listRentingNFT] NFT already listed");

        bytes32 _orderIdRentingNFT = keccak256(
            abi.encodePacked(
                block.timestamp,
                _NFTAddress,
                _NFTId,
                msg.sender,
                _rentalPrice
            )
        );

        RentingNFTs[_NFTAddress][_NFTId] = RentingNFTDetail({
            orderIdRentingNFT: _orderIdRentingNFT,
            owner: msg.sender,
            renter: 0x0000000000000000000000000000000000000000,
            rentalPrice: _rentalPrice,
            rentalPeriod: 0,
            rentalStart: 0,
            rentalEnd: 0,
            lastClaimedTime: 0,
            isReccurent: false
        });

        RentingDetailsbyOwnerOrderIds[msg.sender][_orderIdRentingNFT] = RentingDetailsbyOwnerOrderId({
            nftAddress: _NFTAddress,
            nftTokenID: _NFTId,
            renter: 0x0000000000000000000000000000000000000000,
            rentalPrice: 0,
            rentalPeriod: 0,
            rentalStart: 0,
            rentalEnd: 0,
            lastClaimedTime: 0
        });

        ownerToListedRentingOrderIds[msg.sender].push(_orderIdRentingNFT);

        emit ListRentingNFT(_NFTAddress, _NFTId, _orderIdRentingNFT, _rentalPrice, RentingNFTs[_NFTAddress][_NFTId].owner);
    }

    /**
    * @dev cancel listed order.
    * @param _NFTAddress - address of prefered NFT.
    * @param _NFTId -  ID of prefered NFT.
    */
    function cancelListedRentingOrder(address _NFTAddress, uint256 _NFTId) public onlyNFTOwnerANDadmin(_NFTId, _NFTAddress) whenNotPaused{
        RentingNFTDetail memory NFT = RentingNFTs[_NFTAddress][_NFTId];

        require(NFT.orderIdRentingNFT != 0, "[NFTRenting.cancelListedRentingOrder] Renting NFT not published");
        require(NFT.renter == 0x0000000000000000000000000000000000000000, "[NFTRenting.cancelListedRentingOrder] This Renting order already has a renter");

        removeOwner(NFT.orderIdRentingNFT, NFT.owner);
        delete RentingDetailsbyOwnerOrderIds[NFT.owner][NFT.orderIdRentingNFT];
        delete RentingNFTs[_NFTAddress][_NFTId];

        emit CancelListedRentingNFT(_NFTAddress, _NFTId, RentingNFTs[_NFTAddress][_NFTId].owner);
    }

    /**
    * @dev edit detail(s) of listed order.
    * @param _NFTAddress - address of prefered NFT.
    * @param _NFTId -  ID of prefered NFT.
    * @param _rentalPrice -  prefered rental price per day.
    */
    function editListedRentingOrder(address _NFTAddress, uint256 _NFTId, uint256 _rentalPrice) public onlyNFTOwnerANDadmin(_NFTId, _NFTAddress) whenNotPaused{
        RentingNFTDetail memory NFT = RentingNFTs[_NFTAddress][_NFTId];

        require(NFT.orderIdRentingNFT != 0, "[NFTRenting.editListedRentingOrder] Renting NFT not published");
        require(NFT.renter == 0x0000000000000000000000000000000000000000, "[NFTRenting.editListedRentingOrder] This Renting order already has a renter");
        
        RentingNFTs[_NFTAddress][_NFTId].rentalPrice = _rentalPrice;
        RentingDetailsbyOwnerOrderIds[NFT.owner][NFT.orderIdRentingNFT].rentalPrice = _rentalPrice;

        emit EditListedRentingNFT(_NFTAddress, _NFTId, _rentalPrice, RentingNFTs[_NFTAddress][_NFTId].owner);
    }

    /**
    * @dev renter's address will be input in RentingNFTDetail.
    * calculate total rental price and decrease tokens from renter's balanceVault according to the calculated amount.
    * startPeriod will be input to RentingNFTDetail according to current timestamp.
    * @param _NFTAddress - address of prefered NFT.
    * @param _NFTId -  ID of prefered NFT.
    * @param _rentalPeriod -  prefered rental period [day(s)].
    */
    function executeRent(address _NFTAddress, uint256 _NFTId, uint256 _rentalPeriod) public whenNotPaused{
        require(RentingNFTs[_NFTAddress][_NFTId].renter == 0x0000000000000000000000000000000000000000, "[NFTRenting.executeRent] NFT already rented");
        RentingNFTDetail memory NFT = RentingNFTs[_NFTAddress][_NFTId];
        require(NFT.orderIdRentingNFT != 0, "[NFTRenting.executeRent] Renting NFT not published");
        require(_rentalPeriod != 0, "[NFTRenting.executeRent] Rental period can't be zero");
        require(NFT.owner != msg.sender,"[NFTRenting.executeRent] Can't rent your own nft.");

        balanceVault.decreaseBalance(msg.sender, (RentingNFTs[_NFTAddress][_NFTId].rentalPrice * _rentalPeriod));
        // update deducted fee amount from renter to totalUnpaidBalance
        totalUnpaidBalance += RentingNFTs[_NFTAddress][_NFTId].rentalPrice * _rentalPeriod;

        uint256 _rentalEnd = block.timestamp + (_rentalPeriod * 1 minutes);

        RentingNFTs[_NFTAddress][_NFTId] = RentingNFTDetail({
            orderIdRentingNFT: NFT.orderIdRentingNFT,
            owner: NFT.owner,
            renter: msg.sender,
            rentalPrice: NFT.rentalPrice,
            rentalPeriod: _rentalPeriod, //pay rental price
            rentalStart: block.timestamp, // get current time as start period
            rentalEnd: _rentalEnd,
            lastClaimedTime: block.timestamp, // get current time as start period
            isReccurent: true
        });

        RentingDetailsbyOwnerOrderIds[NFT.owner][NFT.orderIdRentingNFT] = RentingDetailsbyOwnerOrderId({
            nftAddress: _NFTAddress,
            nftTokenID: _NFTId,
            renter: msg.sender,
            rentalPrice: NFT.rentalPrice,
            rentalPeriod: _rentalPeriod, //pay rental price
            rentalStart: block.timestamp, // get current time as start period
            rentalEnd: _rentalEnd,
            lastClaimedTime: block.timestamp // get current time as start period
        });

        emit ExecuteRent(_NFTAddress, _NFTId, _rentalPeriod, msg.sender, RentingNFTs[_NFTAddress][_NFTId].rentalStart, RentingNFTs[_NFTAddress][_NFTId].rentalEnd, RentingNFTs[_NFTAddress][_NFTId].rentalPrice * _rentalPeriod);
    }

    /**
    * @dev claim rental fee.
    * calculate and deduct platform commission from fee amount when NFT owner claim rental fee.
    * update total platform commission. 
    * totalPlatformCommission - refers to total amount of commission remaining in balanceVault.
    * update total unpaid balance. 
    * totalUnpaidBalance - refers to total unpaid balance that has been deducted from renter's wallet but not yet transfered to owner's wallet.
    * reset lastClaimedTime to current timestamp.
    * @param _NFTAddress - address of prefered NFT.
    * @param _NFTId -  ID of prefered NFT.
    */
    function claimFeeRenting(address _NFTAddress, uint256 _NFTId) public onlyNFTOwnerANDadmin(_NFTId, _NFTAddress) whenNotPaused{
        require(block.timestamp >= RentingNFTs[_NFTAddress][_NFTId].rentalEnd, "[NFTRenting.claimFeeRenting] Renting period has not ended yet");

        RentingNFTDetail memory NFT = RentingNFTs[_NFTAddress][_NFTId];

        require(NFT.orderIdRentingNFT != 0, "[NFTRenting.claimFeeRenting] Renting NFT not published");
        require(NFT.renter != 0x0000000000000000000000000000000000000000, "[NFTRenting.claimFeeRenting] This NFT has no renter");

        uint256 unclaimedFee = NFT.rentalPrice * NFT.rentalPeriod;
        uint256 platformFee = (unclaimedFee * platformCommission) / 100;
        balanceVault.increaseBalance(msg.sender, unclaimedFee - platformFee);
        totalPlatformCommission += platformFee;
        totalUnpaidBalance -= unclaimedFee;
        RentingNFTs[_NFTAddress][_NFTId].lastClaimedTime = block.timestamp;
        RentingDetailsbyOwnerOrderIds[NFT.owner][NFT.orderIdRentingNFT].lastClaimedTime = block.timestamp;

        removeOwner(NFT.orderIdRentingNFT, NFT.owner);
        delete RentingDetailsbyOwnerOrderIds[NFT.owner][NFT.orderIdRentingNFT];
        delete RentingNFTs[_NFTAddress][_NFTId];

        emit ClaimFeeRenting(_NFTAddress, _NFTId, RentingNFTs[_NFTAddress][_NFTId].owner, unclaimedFee - platformFee, unclaimedFee, platformFee, RentingNFTs[_NFTAddress][_NFTId].lastClaimedTime, totalUnpaidBalance);
    }

    /**
    * @dev contract owner claim platform commission.
    */
    function claimPlatformCommission() public onlyOwner {
        balanceVault.increaseBalance(msg.sender, totalPlatformCommission);
    }

    /**
    * @dev set new owner for backend
    */
    function changeOwnerRentingNFT(address _NFTAddress, uint256 _NFTId, address _newOwner) public onlyRole(WORKER_ROLE) {
        RentingNFTs[_NFTAddress][_NFTId].owner = _newOwner;

         emit ChangeOwnerRentingNFT(_NFTAddress, _NFTId, _newOwner);
    }

    function getNFTRentingDetails(address _NFTAddress, uint256 _NFTId) public view returns(RentingNFTDetail memory) {
        RentingNFTDetail memory NFT = RentingNFTs[_NFTAddress][_NFTId];

        require(NFT.owner != 0x0000000000000000000000000000000000000000, "[NFTRenting.getNFTRentingDetails] NFT is not listed");

        return NFT;
    }

    /**
     * @dev Get all listed Renting NFTs of specific address.
     */
    function getOwnerListedRentingNFTs(address _owner) public view returns (bytes32[] memory nfts){
        bytes32[] memory owerNFTs = ownerToListedRentingOrderIds[_owner];
        nfts = new bytes32[](ownerToListedRentingOrderIds[_owner].length);
        for (uint256 i; i < ownerToListedRentingOrderIds[_owner].length; i++) {
            nfts[i] = owerNFTs[i];
        }
        return nfts;
    }

    /**
     * @dev remove ownership from previous owner when order is executed.
     */
    function removeOwner(bytes32 _orderId, address _owner) private {
        uint256 index = findIndex(_orderId, _owner);
        ownerToListedRentingOrderIds[_owner][index] = ownerToListedRentingOrderIds[_owner][
            ownerToListedRentingOrderIds[_owner].length - 1
        ];
        ownerToListedRentingOrderIds[_owner].pop();
    }

    /**
     * @dev find index of item to remove.
     */
    function findIndex(bytes32 _orderId, address _owner) private view returns (uint256){
        for (uint256 i; i < ownerToListedRentingOrderIds[_owner].length; i++) {
            if (ownerToListedRentingOrderIds[_owner][i] == _orderId) {
                return i;
            }
        }
        revert(
            "[NFTRenting.findIndex] Can't find the ownership of this NFT."
        );
    }

    function getTotalUnpaidBalance() public view returns(uint256) {
        return totalUnpaidBalance;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}