// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IMoaAllowSiringV1.sol";
import "./IMoaCoreV1.sol";
import "./IMoaMarketplaceDonor.sol";

contract MoaMarketplaceDonor is IMoaMarketplaceDonor, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _donateItemIds;
    Counters.Counter private _donateItemsComplete;
    Counters.Counter private _donateItemRevoke;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    mapping(uint256 => DonateItem) public idToDonorItem;
    mapping(address => mapping(uint256 => uint256)) public getItemIdFromAddress;

    modifier isDonateItemDonor(
        address nftAddress,
        uint256 itemId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address _itemDonor = idToDonorItem[itemId].donor;
        address _owner = nft.ownerOf(idToDonorItem[itemId].tokenId);

        require(_itemDonor == spender);
        require(_owner == spender);
        _;
    }

    //Prevent donate item being duplicate in the donateItem list
    modifier isUnqiueOnDonateItem(address _nftAddress, uint256 _tokenId) {
        uint256 _itemId = getItemIdFromAddress[_nftAddress][_tokenId];
        DonateItem storage _donateItem = idToDonorItem[_itemId];
        require(
            (_donateItem.donateItemId == 0) ||
                (_donateItem.complete != false &&
                    _donateItem.donateItemId != 0) ||
                (_donateItem.revoke != false && _donateItem.donateItemId != 0),
            "already exists"
        );
        _;
    }

    // Below is the function for borrow siring MoA
    function createDonateItem(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price
    )
        public
        payable
        override
        isUnqiueOnDonateItem(_nftContract, _tokenId)
        nonReentrant
    {
        //check
        require(_price > 0, "Price must be greater than 0");
        require(
            IERC721(_nftContract).ownerOf(_tokenId) == msg.sender,
            "Sender does not own the NFT"
        );
        require(
            (IMoaAllowSiringV1(_nftContract).getApprovedCallApproveSiring(_tokenId) == address(this)) || 
            (IMoaAllowSiringV1(_nftContract).isApprovedCallApproveSiringForAll(address(this), msg.sender)),
            "Marketplace not the operator of the tokenId to allow siring"
        );

        //effect
        _donateItemIds.increment();
        uint256 _donateItemId = _donateItemIds.current();

        idToDonorItem[_donateItemId] = DonateItem({
            donateItemId: _donateItemId,
            nftContract: _nftContract,
            tokenId: _tokenId,
            donor: payable(msg.sender),
            donee: payable(address(0)),
            price: _price,
            complete: false,
            revoke: false
        });

        getItemIdFromAddress[_nftContract][_tokenId] = _donateItemId;

        emit DonateItemCreated(
            _donateItemId,
            _nftContract,
            _tokenId,
            msg.sender,
            address(0),
            _price,
            false,
            false
        );
    }

    function createDonateSale(uint256 itemId)
        public
        payable
        override
        nonReentrant
    {
        require(_exists(itemId) == true);
        uint256 price = idToDonorItem[itemId].price;
        uint256 tokenId = idToDonorItem[itemId].tokenId;
        address nftContract = idToDonorItem[itemId].nftContract;
        bool complete = idToDonorItem[itemId].complete;
        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );
        require(complete != true, "This Sale has alredy finnished");

        // Transfer the receviced eth to donor
        idToDonorItem[itemId].donor.transfer(msg.value);

        // Approve the MoA to be sired by sender
        IMoaAllowSiringV1(nftContract).approveSiring(msg.sender, tokenId);

        // Update the donee
        idToDonorItem[itemId].donee = payable(msg.sender);

        // Increase the donateItemComplete counter
        _donateItemsComplete.increment();

        // Update the donateItem to complete true
        idToDonorItem[itemId].complete = true;

        emit DonateItemComplete(itemId, tokenId, price, msg.sender);
    }

    function revokeDonateItem(address _nftContract, uint256 _itemId)
        public
        override
        isDonateItemDonor(_nftContract, _itemId, msg.sender)
        nonReentrant
    {
        DonateItem storage _donateItem = idToDonorItem[_itemId];
        // only on-sale item can be de-listing
        require(_donateItem.complete == false);

        // Effect
        uint256 tokenId = _donateItem.tokenId;
        _donateItem.revoke = true;
        _donateItemRevoke.increment();

        // Event
        emit DonateItemRevoke(_itemId, tokenId, msg.sender);
    }

    function updateDonateItem(
        address _nftContract,
        uint256 _itemId,
        uint256 _price
    )
        public
        override
        isDonateItemDonor(_nftContract, _itemId, msg.sender)
        nonReentrant
    {
        DonateItem storage _donateItem = idToDonorItem[_itemId];
        // Only on-sale item can be update
        // Check the item is listing on sale
        require(_donateItem.complete == false && _donateItem.revoke == false);
        require(_price > 0, "Price must be greater than 0");

        // Effect
        uint256 tokenId = _donateItem.tokenId;
        _donateItem.price = _price;

        // Event
        emit DonateItemUpdate(_itemId, _price, tokenId, msg.sender);
    }

    function fetchDonateItems()
        public
        view
        override
        returns (DonateItem[] memory)
    {
        uint256 itemCount = _donateItemIds.current();
        uint256 onDonateItemCount = _donateItemIds.current() -
            _donateItemsComplete.current() -
            _donateItemRevoke.current();
        uint256 currentIndex = 0;

        DonateItem[] memory items = new DonateItem[](onDonateItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            // Check the market item not yet sold and revoke
            if (
                idToDonorItem[i + 1].complete == false &&
                idToDonorItem[i + 1].revoke == false
            ) {
                uint256 currentId = i + 1;
                DonateItem storage currentItem = idToDonorItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchCompleteDonateItems()
        public
        view
        override
        returns (DonateItem[] memory)
    {
        uint256 itemCount = _donateItemIds.current();
        uint256 completeItemCount = _donateItemsComplete.current();
        uint256 currentIndex = 0;

        DonateItem[] memory items = new DonateItem[](completeItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            // Check the market item not yet sold and revoke
            if (
                idToDonorItem[i + 1].complete == true &&
                idToDonorItem[i + 1].donee != address(0)
            ) {
                uint256 currentId = i + 1;
                DonateItem storage currentItem = idToDonorItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchRevokeDonateItems()
        public
        view
        override
        returns (DonateItem[] memory)
    {
        uint256 itemCount = _donateItemIds.current();
        uint256 revokeItemCount = _donateItemRevoke.current();
        uint256 currentIndex = 0;

        DonateItem[] memory items = new DonateItem[](revokeItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            // Check the market item not yet sold and revoke
            if (
                idToDonorItem[i + 1].revoke == true &&
                idToDonorItem[i + 1].donee == address(0)
            ) {
                uint256 currentId = i + 1;
                DonateItem storage currentItem = idToDonorItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getDonateItemByTokenId(address _nftContract, uint256 _tokenId)
        internal
        view
        returns (uint256 donateItemId)
    {
        return getItemIdFromAddress[_nftContract][_tokenId];
    }

    function _exists(uint256 _itemId) internal view virtual returns (bool) {
        return idToDonorItem[_itemId].donor != address(0);
    }
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

interface IMoaMarketplaceDonor {
    event DonateItemCreated(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address donor,
        address donee,
        uint256 price,
        bool complete,
        bool revoke
    );

    event DonateItemComplete(uint indexed itemId, uint256 indexed tokenId, uint256 price, address donee);

    event DonateItemRevoke(uint indexed itemId, uint indexed tokenId, address donor);

    event DonateItemUpdate(uint indexed itemId, uint256 updated, uint indexed tokenId, address donor);

    struct DonateItem {
        uint donateItemId;
        address nftContract;
        uint256 tokenId;
        address payable donor;
        address payable donee;
        uint256 price;
        bool complete;
        bool revoke;
    }

    ///@dev Create a donate item on the marketplace 
    function createDonateItem(address _nftContract, uint256 _tokenId, uint256 _price ) external payable;

    ///@dev Create a donate item sale on the marketplace.
    /// The process will invloved the marketplace call allowSiring to the message sender
    /// After that, the sender can call cultivation with the allowed MoA 
    function createDonateSale(uint256 itemId) external payable;

    ///@dev Revoke a donate item
    function revokeDonateItem(address _nftContract, uint256 _itemId) external; 

    ///@dev Update a donate item
    function updateDonateItem(address _nftContract, uint256 _itemId, uint256 _price) external;

    ///@dev Fetch on-donation donate items
    function fetchDonateItems() external view returns (DonateItem[] memory);

    ///@dev Fetch complete donation donate items
    function fetchCompleteDonateItems() external view returns (DonateItem[] memory);

    ///@dev Fetch revoke donation donate item
    function fetchRevokeDonateItems() external view returns (DonateItem[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMoaCoreV1 {
    /// @dev pause the Contract
    function pause() external;

    /// @dev unpause the Contract
    function unpause() external;

    /// @dev set Boss address
    function setBoss(address bossAddress) external;

    /// @dev mint a Gen0 MoA to the msg.sender.
    function mintGen0(uint256 _genes) external returns (uint256);

    /// @dev Retrieve a Moa struct by given tokenId
    function getMoa(uint256 _moaId)
        external
        view
        returns (
            bool isGestating,
            bool isReadyToGiveBirth,
            bool isReadyToGetPregnant,
            uint256 restingCooldownIndex,
            uint256 birthCooldownIndex,
            uint256 siringWithId,
            uint256 birthTime,
            uint256 matronId,
            uint256 sireId,
            uint256 generation,
            uint256 genes
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMoaAllowSiringV1 {
    event ApproveCallApproveSiringForAll(address indexed owner, address indexed operator, bool approved);

    /// @dev allow token ID to be called siring from the address
    function approveSiring(address _addr, uint256 _sireId) external;

    ///@dev allow token ID to be call approveSiring from the address e.g. 
    // Approve markerplace address to call approveSiring when someone want to 
    // put their MoA to the market place for siring renting
    function approveCallApproveSiring(address _addr, uint256 _sireId) external;

    ///@dev remove the approved address to call "approve siring" of targeted MoA ID
    function removeApproveCallApproveSiring(uint256 _sireId) external;

    ///@dev return the approved address to call "aprove siring" of targeted MoA ID
    function getApprovedCallApproveSiring(uint256 _sireId) external returns (address);

    ///@dev allow operator address to call approveSiring for all MoA of the msd.msg.sender
    function setApproveCallApproveSiringForAll(address operator, bool _approved) external;

    ///@dev return the approved status of the owner's operator
    function isApprovedCallApproveSiringForAll(address owner, address operator) external returns (bool);
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