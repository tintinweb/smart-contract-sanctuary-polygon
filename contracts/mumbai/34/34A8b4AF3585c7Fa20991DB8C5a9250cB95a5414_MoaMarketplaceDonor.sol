// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../IMoaCultivation.sol";
import "./IMoaMarketplaceDonor.sol";

contract MoaMarketplaceDonor is IMoaMarketplaceDonor, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _donateItemIdCounter;
    Counters.Counter private _donateItemsComplete;
    Counters.Counter private _donateItemRevoke;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor() {}

    mapping(uint256 => DonateItem) public idToDonorItem;
    mapping(address => mapping(uint256 => uint256)) public getItemIdFromAddress;

    modifier isDonateItemDonor(uint256 itemId, address spender) {
        require(idToDonorItem[itemId].donor == spender);
        _;
    }

    /// @dev Prevent market item being duplicate
    modifier isUnqiueOnDonateItem(
        address _nftAddress,
        uint256 _tokenId,
        address spender
    ) {
        uint256 _itemId = getItemIdFromAddress[_nftAddress][_tokenId];
        DonateItem storage _donateItem = idToDonorItem[_itemId]; // note: idToDonorItem[0] is not used, so
        require(
            (_donateItem.donateItemId == 0) || // no previous record created
                (_donateItem.complete || _donateItem.revoke) || // is already complete or revoked
                (_donateItem.donor != spender), // the previous sale is not make by the same person (i.e. the token have a new owner)
            "already exists"
        );
        _;
    }

    /// @dev list a token for sale
    function listForSale(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 donationDays
    )
        public
        override
        isUnqiueOnDonateItem(nftContract, tokenId, _msgSender())
        nonReentrant
        returns (uint256)
    {
        require(price > 0, "Price must > 0");
        require(donationDays > 0, "Last at least 1 days");
        require(donationDays <= 60, "Last at most 60 days");
        require(
            IERC721(nftContract).ownerOf(tokenId) == _msgSender(),
            "Not owner"
        );
        require(
            IMoaLendCultivation(nftContract).isAllowStartCultivationForAll(
                _msgSender(),
                address(this)
            ),
            "Insufficient permission"
        );

        // effect
        _donateItemIdCounter.increment(); // 1-based, so increment first
        uint256 _donateItemId = _donateItemIdCounter.current();

        idToDonorItem[_donateItemId] = DonateItem({
            donateItemId: _donateItemId,
            nftContract: nftContract,
            tokenId: tokenId,
            donor: payable(_msgSender()),
            donee: payable(address(0)),
            price: price,
            complete: false,
            revoke: false,
            donationDays: donationDays,
            donationFinishTime: uint64(
                block.timestamp + (donationDays * 1 days)
            )
        });

        getItemIdFromAddress[nftContract][tokenId] = _donateItemId;

        emit DonateItemCreated(
            _donateItemId,
            nftContract,
            tokenId,
            _msgSender(),
            price,
            uint64(donationDays),
            uint64(block.timestamp + (donationDays * 1 days))
        );

        return _donateItemId;
    }

    /// @dev _msgSender() lends the MoA to start cultivate
    function buyAndStartCultivation(uint256 itemId, uint256 coreId)
        public
        payable
        override
        nonReentrant
    {
        //check
        require(_exists(itemId) == true);
        uint256 price = idToDonorItem[itemId].price;
        uint256 tokenId = idToDonorItem[itemId].tokenId;
        address nftContract = idToDonorItem[itemId].nftContract;
        address donor = idToDonorItem[itemId].donor;
        bool complete = idToDonorItem[itemId].complete;
        uint64 donationFinishTime = idToDonorItem[itemId].donationFinishTime;
        require(complete != true, "Sale closed");
        require(donationFinishTime >= block.timestamp, "Sale expired");
        require(
            IERC721(nftContract).ownerOf(coreId) == _msgSender(),
            "Not owner"
        );
        require(
            IERC721(nftContract).ownerOf(tokenId) == donor,
            "Invalid sale: Not Owner"
        );
        uint256 autoBirthFee = IMoaCultivation(nftContract).getAutoBirthfee();
        require(msg.value >= (price + autoBirthFee), "Insufficient value");
        require(
            IMoaLendCultivation(nftContract).isAllowStartCultivationForAll(
                _msgSender(),
                address(this)
            ),
            "Insufficient permission"
        );
        require(
            IMoaLendCultivation(nftContract).isAllowStartCultivationForAll(
                donor,
                address(this)
            ),
            "Invalid sale: Insufficient permission"
        );

        idToDonorItem[itemId].donee = payable(_msgSender()); // Update the donee
        idToDonorItem[itemId].complete = true; // Update the donateItem to complete true
        _donateItemsComplete.increment(); // Increase the donateItemComplete counter

        // interactions :
        // Call Cultivation and provide autoBirthfee
        IMoaCultivation(nftContract).startCultivation{value: autoBirthFee}(
            coreId,
            tokenId
        );
        // transfer price to owner
        payable(idToDonorItem[itemId].donor).transfer(price);

        emit DonateItemComplete(
            itemId,
            nftContract,
            tokenId,
            price,
            donor,
            _msgSender()
        );
    }

    function revokeSale(uint256 itemId)
        public
        override
        isDonateItemDonor(itemId, _msgSender())
        nonReentrant
    {
        require(_exists(itemId), "Invalid item");
        DonateItem storage _donateItem = idToDonorItem[itemId];
        // only on-sale item can be de-listing
        require(!_donateItem.complete && !_donateItem.revoke, "Already closed");

        // Effect
        _donateItem.revoke = true;
        _donateItemRevoke.increment();

        // Event
        emit DonateItemRevoke(
            itemId,
            _donateItem.nftContract,
            _donateItem.tokenId,
            _msgSender()
        );
    }

    function updateSale(
        uint256 itemId,
        uint256 price,
        uint256 extraDonationDays
    ) public override isDonateItemDonor(itemId, _msgSender()) nonReentrant {
        require(_exists(itemId) == true, "Invalid item");
        require(price > 0, "Price must > 0");
        DonateItem storage _donateItem = idToDonorItem[itemId];
        require(!_donateItem.complete && !_donateItem.revoke, "Sale closed"); // the sale is not complete or reovked
        require(
            extraDonationDays + _donateItem.donationDays <= 60,
            "Last at most 60 days"
        );

        // Effect
        _donateItem.price = price;
        _donateItem.donationDays += extraDonationDays;
        _donateItem.donationFinishTime += uint64(extraDonationDays * 1 days);

        // Event
        emit DonateItemUpdate(
            itemId,
            _donateItem.nftContract,
            _donateItem.tokenId,
            _msgSender(),
            price,
            _donateItem.donationDays,
            _donateItem.donationFinishTime
        );
    }

    function getItemId(address _nftContract, uint256 _tokenId)
        public
        view
        override
        returns (uint256 donateItemId)
    {
        donateItemId = getItemIdFromAddress[_nftContract][_tokenId];
    }

    function _exists(uint256 itemId) internal view virtual returns (bool) {
        return idToDonorItem[itemId].donor != address(0);
    }

    function getItem(uint256 itemId)
        public
        view
        override
        returns (DonateItem memory)
    {
        require(_exists(itemId), "Not exists");
        return idToDonorItem[itemId];
    }

    /// @dev withdraw funds from this contract, for whatever reason that it have some balance
    function withdraw(address to, uint256 amount) public onlyOwner {
        require(address(this).balance >= amount);
        payable(to).transfer(amount);
    }
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

interface IMoaMarketplaceDonor {
    event DonateItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address donor,
        uint256 price,
        uint256 donationDays,
        uint64 donationFinishTime
    );

    event DonateItemComplete(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 price,
        address donor,
        address donee
    );

    event DonateItemRevoke(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address donor
    );

    event DonateItemUpdate(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address donor,
        uint256 updatedPrice,
        uint256 updatedDonationDays,
        uint64 updatedDonationFinishTime
    );

    struct DonateItem {
        uint256 donateItemId;
        address nftContract;
        uint256 tokenId;
        address donor;
        address donee;
        uint256 price;
        bool complete;
        bool revoke;
        uint256 donationDays;
        uint64 donationFinishTime;
    }

    /// @dev List a MoA for sale of as Support MoA.
    /// @dev msg.sender must be the owner
    /// @param nftContract MoA contracts
    /// @param tokenId MoA id
    /// @param price sale price
    /// @param donationDays how long to be listed
    function listForSale(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 donationDays
    ) external returns (uint256);

    ///@dev Create a donate item sale on the marketplace. The process will invoke the call cultivation immediately
    ///@param itemId The donation item id with the lended MoA
    ///@param coreId The core MoA for this leasing cultivation
    function buyAndStartCultivation(uint256 itemId, uint256 coreId)
        external
        payable;

    ///@dev Update a donate item
    function updateSale(
        uint256 itemId,
        uint256 price,
        uint256 extraDonationDays
    ) external;

    ///@dev Revoke a donate item
    function revokeSale(uint256 itemId) external;

    /// @dev Find itemId by tokenId and NFT address
    function getItemId(address nftContract, uint256 tokenId)
        external
        view
        returns (uint256);

    /// @dev get sale item details
    function getItem(uint256 itemId) external view returns (DonateItem memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IMoaCore.sol";

interface IMoaLendCultivation is IMoaCore {
    /// @dev allow token ID to be called siring from the address
    /// @param to address to be allowed to call startCultivation
    /// @param supportMoaId tokenId to be allowed to startCultivation
    function lendMoa(address to, uint256 supportMoaId) external;
 
    /// @dev revoke a lending promise
    function revokeLending(uint256 tokenId) external;

    /// @dev Set pre-defined operaotrs for calling startCultivation
    /// This is subjected to elimate the gas-fee by whitelist the MoA marketplace to call srartCultivation
    function setPredefinedOperatorforCultivation(address operator, bool approved) external;

    /// @dev Return an address that the MoA is being allowed to cultivate
    function getLendedMoaAddress(uint256 supportMoaId) external returns (address);

    /// @dev Set operator to call startCultivation
    function setApproveCultivationForAll(address operator, bool approved) external;

    /// @dev Check whether operator allowed to call startCultivate
    function isAllowStartCultivationForAll(address owner, address operator) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IMoaLendCultivation.sol";

interface IMoaCultivation is IMoaLendCultivation {
    event StartCultivation(address indexed owner, uint256 indexed coreId, uint256 indexed supportId);
    event CompleteCultivation(address indexed owner, uint256 indexed babyId, uint256 indexed babyGenes);
    event AutoBirth(uint256 indexed coreId, uint256 indexed birthCooldownEndTime);

    /// @dev update the autoBirthFee
    function setAutoBirthFee(uint256 _autoBirthFee) external;

    function getAutoBirthfee() external returns (uint256);

    /// @dev start a Cultivation process between 2 MoA.
    /// @dev always AutoBirth now
    function startCultivation(uint256 _coreId, uint256 _supportId)
        external
        payable returns (uint64);

    /// @dev end a Cultivation process and a new MoA is born!
    function completeCultivation(uint256 _coreId) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

///@dev MoaCore provide methods to update contract information
interface IMoaCore {
    /// @dev pause the Contract
    function pause() external;

    /// @dev unpause the Contract
    function unpause() external;

    /// @dev update the GeneScience contract adress
    function setGeneScienceAddress(address _address) external;

    /// @dev mint a Gen0 MoA to the msg.sender.
    function mintGen0(uint256 _genes) external returns (uint256);

    /// @dev mint a Gen1 MoA to the "to" address.
    function mintGen1(uint256 _coreId, uint256 _supportId, address _to) external returns (uint256);

    /// @dev Retrieve a Moa struct by given tokenId
    function getMoa(uint256 _moaId)
        external
        view
        returns (
            bool isCultivating,
            bool isReadyToComplete,
            bool isReadyToCultivate,
            uint256 restingCooldownIndex,
            uint256 birthCooldownIndex,
            uint256 cultivatingWithId,
            uint256 birthTime,
            uint256 coreId,
            uint256 supportId,
            uint256 generation,
            uint256 genes,
            uint256 autoBirthFee
        );

    /// @dev update Royalty Info
    /// @param _receiver MoA's artist address
    /// @param _royaltyFeesInBips precentage of the royalty fee
    function setRoyaltyInfo( address _receiver, uint96 _royaltyFeesInBips) external;

    /// @dev add/remove prefined operator permission
    function setPredefinedOperators(address operator, bool approved) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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