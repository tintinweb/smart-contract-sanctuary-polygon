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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
 
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Renting is ERC721Holder, Ownable  {
  
    address public marketPlaceOwner;
    
    struct Lending {
        address owner;
        address renter;
        uint256 id;
        address nftContract;
        uint256 tokenId;
        uint256 pricePerDay;
        uint256 collateralFee;
        uint256 collateralReturnFee;
        uint256 startDateUNIX; // when the nft can start being rented
        uint256 endDateUNIX; // when the nft can no longer be rented
        uint256 expires; // when the renter can no longer rent it
        bool isRented;
    }

    mapping (address =>mapping( uint => Lending)) public lendings;
    Lending[] public LentNFT_CollateralFeeForSale;
    mapping(address => mapping(uint256 => bool)) LentActiveItems;
  
    // ************* events *****************//
    event LentNFT_CollateralFee(
        uint256 id,
        address owner,
        address renter,
        address nftContract,
        uint256 tokenId,
        uint256 pricePerDay,
       uint256 collateralFee,
        uint256 startDateUNIX,
        uint256 endDateUNIX,
        uint256 expires
    );

    event RentedNFT_CollateralFee(
        uint256 id,
        address owner,
        address renter,
        // uint256  renterNftId,
        address nftContract,
        uint256 tokenId,
        uint256 startDateUNIX,
        uint256 endDateUNIX,
        uint64 expires,
        uint256 rentalFee
    );

    event StoppedLending_CollateralFee(
        uint256 id,
        address unlistSender,
        address nftContract,
        uint256 tokenId
        // uint256 refund
    );

    event CollateralClaimed(
        uint256 id,
        address Owner,
        address Renter,
        address nftContract,
        uint256 tokenId,
        uint256 ReturnFee
    );

    event FeeReturned(
        uint256 id,
        address Owner,
        address nftContract,
        uint256 tokenId,
        uint256 ReturnFee
    );
   
// ************* Checks *****************//

    modifier OnlyItemOwner(address tokenAddress, uint256 tokenId) {
        IERC721 tokenContract = IERC721(tokenAddress);
        require(
            tokenContract.ownerOf(tokenId) == msg.sender,
            "BlueMoon:only owner"
        );
        _;
    }

    modifier HasTransferApproval(address tokenAddress, uint256 tokenId) {
        IERC721 tokenContract = IERC721(tokenAddress);
        require(
            tokenContract.getApproved(tokenId) == address(this),
            "BlueMoon:approvel"
        );
        _;
    }

    modifier IsItemExists(uint256 id) {
        require(
            id < LentNFT_CollateralFeeForSale.length && LentNFT_CollateralFeeForSale[id].id == id,
            "BlueMoon:Could not find Item"
        );
        _;
    }

    modifier ItemIsForSale(uint256 id) {
        require(
            LentNFT_CollateralFeeForSale[id].isRented== false,
            "BlueMoon:  Item is already rented"
        );
        _;
    }
      
    constructor(address _marketplaceOwner) {
      marketPlaceOwner = _marketplaceOwner;
    }

    // ************* functionalities *****************//
      /**
     * List Nft to Rent 
     */

    function lendNFT_CollateralFee( address nftContract, uint256 tokenId, uint256 pricePerDay, uint256 collateralFee, uint256 startDateUNIX, uint256 endDateUNIX) public 
        HasTransferApproval(nftContract, tokenId) {

        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "BlueMoon: Not a nft owner");   
        require( LentActiveItems[nftContract][tokenId] == false,"BlueMoon:Item is already up for Sale" );  
        require(pricePerDay > 0, "BlueMoon:Rental price should be greater than 0");
        require(startDateUNIX >= block.timestamp, "BlueMoon:Start date cannot be in the past");
        require(endDateUNIX >= startDateUNIX, "BlueMoon:End date cannot be before the start date");

        uint daysOfRental = (endDateUNIX- startDateUNIX)/86400;
        require(daysOfRental>=1, "Rent time should be greater than 1 day");

        uint256 newItemId = LentNFT_CollateralFeeForSale.length;

        LentNFT_CollateralFeeForSale.push(
            Lending(
            msg.sender,  // owner
            address(0), // renter
            newItemId, // id (in array -- its place)
            nftContract, // nftcontract
            tokenId, // nft token id 
            pricePerDay, // price per day
            collateralFee, // collateral fee
            0, // collateral return fee
            startDateUNIX,
            endDateUNIX,
            0,  //expires
            false    // isRented
            )
        );
        LentActiveItems[nftContract][tokenId] = true;
        IERC721(nftContract).safeTransferFrom(msg.sender,address(this),tokenId);
        emit LentNFT_CollateralFee( newItemId,IERC721(nftContract).ownerOf(tokenId), address(0), nftContract, tokenId, pricePerDay, collateralFee, startDateUNIX, endDateUNIX, 0 );
    }

    /**
     *  Rent Nft
     */

    function rentNFT_CollateralFee( uint256 id, uint64 expires ) public payable IsItemExists(id) ItemIsForSale(id){
        require( msg.sender != LentNFT_CollateralFeeForSale[id].owner, "BlueMoon:Owner can't rent"  );
        require(block.timestamp > LentNFT_CollateralFeeForSale[id].expires, "BlueMoon:NFT already rented");
        require(LentNFT_CollateralFeeForSale[id].expires <= LentNFT_CollateralFeeForSale[id].endDateUNIX, "BlueMoon:Rental period exceeds max date rentable");
        uint256 numDays = ( expires - block.timestamp )/60/60/24;
        require(numDays> 0,"Remaining Lending Time should be greater than 1 day");
        uint256 rentalFee = LentNFT_CollateralFeeForSale[id].pricePerDay * numDays;

        uint256 totalfee = rentalFee + LentNFT_CollateralFeeForSale[id].collateralFee; 

        require(msg.value >= totalfee, "BlueMoon:Not enough ether to cover rental period");

        LentNFT_CollateralFeeForSale[id].collateralReturnFee = msg.value - rentalFee;
        payable(LentNFT_CollateralFeeForSale[id].owner).transfer(rentalFee);
        // save remaining fee in the contract

        payable(address(this)).transfer(LentNFT_CollateralFeeForSale[id].collateralReturnFee);

        LentNFT_CollateralFeeForSale[id].renter = msg.sender;
        LentNFT_CollateralFeeForSale[id].expires = expires;
        IERC721(LentNFT_CollateralFeeForSale[id].nftContract).safeTransferFrom(address(this),msg.sender,LentNFT_CollateralFeeForSale[id].tokenId);
        LentNFT_CollateralFeeForSale[id].isRented = true;
        emit RentedNFT_CollateralFee(
            id,
            IERC721(LentNFT_CollateralFeeForSale[id].nftContract).ownerOf(LentNFT_CollateralFeeForSale[id].tokenId),
            msg.sender,
            LentNFT_CollateralFeeForSale[id].nftContract,
            LentNFT_CollateralFeeForSale[id].tokenId,
            LentNFT_CollateralFeeForSale[id].startDateUNIX,
            LentNFT_CollateralFeeForSale[id].endDateUNIX,
            expires,
            rentalFee
        );
    }
    /**
     * Owner redeem the collateralFee if renter would not come after Expiration
     */
    
    function redeemFunds(uint256 id) public   IsItemExists(id){
         require(block.timestamp > LentNFT_CollateralFeeForSale[id].expires, "BlueMoon:time is not ended yet");
         require(
            msg.sender == LentNFT_CollateralFeeForSale[id].owner,
            "BlueMoon: Only Owner can call this method"
        );
          require(
             msg.sender != IERC721(LentNFT_CollateralFeeForSale[id].nftContract).ownerOf(LentNFT_CollateralFeeForSale[id].tokenId),
            "BlueMoon:can't Redeem"
        );
        payable(LentNFT_CollateralFeeForSale[id].owner).transfer(LentNFT_CollateralFeeForSale[id].collateralReturnFee);
        LentActiveItems[LentNFT_CollateralFeeForSale[id].nftContract][LentNFT_CollateralFeeForSale[id].tokenId] = false;
         emit FeeReturned(
         id,
         LentNFT_CollateralFeeForSale[id].owner,
         LentNFT_CollateralFeeForSale[id].nftContract,
         LentNFT_CollateralFeeForSale[id].tokenId,
         LentNFT_CollateralFeeForSale[id].collateralReturnFee
    );
      
    }
    /**
     * Renter claim the collateralFee and return the NFT back to owner after expiration time
     */

    function claimCollateral(uint256 id) public payable 
      HasTransferApproval(LentNFT_CollateralFeeForSale[id].nftContract, LentNFT_CollateralFeeForSale[id].tokenId)
       IsItemExists(id) {
           require(
            msg.sender == LentNFT_CollateralFeeForSale[id].renter,
            "BlueMoon: Only Renter can claim"
        );
        require(block.timestamp > LentNFT_CollateralFeeForSale[id].expires, "BlueMoon: time is not ended yet");
        require(
            LentNFT_CollateralFeeForSale[id].collateralReturnFee > 0,
            "BlueMoon: can't claim"
        );
        uint256 num_days = (block.timestamp - LentNFT_CollateralFeeForSale[id].expires)/60/60/24;
        uint256 fine = LentNFT_CollateralFeeForSale[id].pricePerDay * num_days;
        require(msg.value >= fine, "BlueMoon:Not enough ether to cover fine");
        payable(LentNFT_CollateralFeeForSale[id].owner).transfer(msg.value);
        IERC721(LentNFT_CollateralFeeForSale[id].nftContract).safeTransferFrom(msg.sender,LentNFT_CollateralFeeForSale[id].owner,LentNFT_CollateralFeeForSale[id].tokenId);
        payable(LentNFT_CollateralFeeForSale[id].renter).transfer(LentNFT_CollateralFeeForSale[id].collateralReturnFee);
        LentActiveItems[LentNFT_CollateralFeeForSale[id].nftContract][LentNFT_CollateralFeeForSale[id].tokenId] = false;
        emit CollateralClaimed(
         id,
         LentNFT_CollateralFeeForSale[id].owner,
         LentNFT_CollateralFeeForSale[id].renter,
         LentNFT_CollateralFeeForSale[id].nftContract,
         LentNFT_CollateralFeeForSale[id].tokenId,
         LentNFT_CollateralFeeForSale[id].collateralReturnFee
    );

    }
      /**
     * unlist your rental
     */
     function cancelLending_CollateralFee(uint256 id) external IsItemExists(id) ItemIsForSale(id) {
        require( LentNFT_CollateralFeeForSale[id].isRented == false, "Can't: Nft On Rent");
        require( msg.sender == LentNFT_CollateralFeeForSale[id].owner, "BlueMoon:Only Owner can call this method" );
        // LentNFT_CollateralFeeForSale[id].isRented = true;
        LentActiveItems[LentNFT_CollateralFeeForSale[id].nftContract]  [ LentNFT_CollateralFeeForSale[id].tokenId ] = false;
        IERC721(LentNFT_CollateralFeeForSale[id].nftContract)
            .safeTransferFrom(
                address(this),
                msg.sender,
                LentNFT_CollateralFeeForSale[id].tokenId
            );
         emit StoppedLending_CollateralFee(
             id,
            msg.sender,
            LentNFT_CollateralFeeForSale[id].nftContract,
            LentNFT_CollateralFeeForSale[id].tokenId
        );
    }
}