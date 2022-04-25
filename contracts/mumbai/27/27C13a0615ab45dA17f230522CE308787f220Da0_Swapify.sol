// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Swapify {
    struct Swap {
        Status status; // [0]
        string description; // [1]
        address seller; //
        address buyer; // 0
        address[] swapTokens; //
        uint256[] swapTokenIds; //
        uint256 swapId; //
    }

    struct Offer {
        Status status;
        address buyer;
        address[] offerTokens;
        uint256[] offerTokenIds;
        uint256 swapId;
    }

    uint256 public swapCount;

    // 5 swaps

    mapping(uint256 => Swap) public swaps;
    mapping(uint256 => Offer[]) public offers;
    mapping(address => Swap[]) public userSwaps; // contract.userSwaps(address)
    mapping(address => Offer[]) public userOffers;
    mapping(address => uint256) public userSwapCount;
    mapping(address => uint256) public userOffersCount;

    event SwapCreated(address seller, address[] tokens, uint256[] tokenIds);
    event OfferProposed(address buyer, address[] tokens, uint256[] tokenIds);
    event OfferRejected();
    event OfferCancelled(address buyer, uint256 swapId, uint256 offerId);
    event OfferAccepted(
        address seller,
        address[] swapTokens,
        uint256[] swapTokenIds,
        address buyer,
        address[] offerTokens,
        uint256[] offerTokenIds
    );

    enum Status {
        BLANK,
        CREATED,
        REJECTED,
        ACCEPTED,
        CANCELLED
    }

    modifier onlySeller(uint256 _swapId) {
        require(swaps[_swapId].seller == msg.sender, "Only Seller Allowed");
        _;
    }

    modifier onlyBuyer(uint256 _swapId, uint256 _offerId) {
        require(
            offers[_swapId][_offerId].buyer == msg.sender,
            "Only Buyer Allowed"
        );
        _;
    }

    modifier isApproved(address _tokenContract, uint256 _tokenId) {
        // add Approval
        require(
            IERC721(_tokenContract).getApproved(_tokenId) == address(this),
            "!approved"
        );
        _;
    }

    /**
     * @dev Initialize the contract settings, and owner to the deployer.
     */
    constructor() {}

    /**
     * @dev Creates a new order with status : `CREATED` and sets the escrow contract settings : token address and token id.
     * Can only be called is contract state is BLANK
     */
    function createSwap(
        address[] memory _swapTokens,
        uint256[] memory _swapTokenIds,
        string memory _description
    ) public {
        // checks lenghts
        require(_swapTokens.length == _swapTokenIds.length, "!length");

        // create swap
        uint256 swapId = swapCount;
        Swap memory swap_ = Swap(
            Status.CREATED, // [0]
            _description, // [1]
            msg.sender, //
            address(0), // 0
            _swapTokens, //
            _swapTokenIds, //
            swapId
        );
        // populate mappings/arrays
        userSwapCount[msg.sender]++;
        swaps[swapId] = swap_;
        userSwaps[msg.sender].push(swap_);
        swapCount++;

        emit SwapCreated(msg.sender, _swapTokens, _swapTokenIds);
    }

    function proposeOffer(
        uint256 _swapId,
        address[] memory _offerTokens,
        uint256[] memory _offerTokenIds
    ) public {
        // check lengths
        require(_offerTokens.length == _offerTokenIds.length, "!length");
        //create offer
        Offer memory offer_ = Offer(
            Status.CREATED,
            msg.sender,
            _offerTokens,
            _offerTokenIds,
            _swapId
        );

        offers[_swapId].push(offer_);
        userOffers[msg.sender].push(offer_);
        userOffersCount[msg.sender]++;

        emit OfferProposed(msg.sender, _offerTokens, _offerTokenIds);
    }

    function cancelOffer(uint256 _swapId, uint256 _offerId)
        public
        onlyBuyer(_swapId, _offerId)
    {
        require(
            offers[_swapId][_offerId].status == Status.CREATED,
            "Can't Cancell now"
        );
        offers[_swapId][_offerId].status = Status.CANCELLED;
        emit OfferCancelled(msg.sender, _swapId, _offerId);
    }

    function updateOffer() public {}

    function acceptOffer(uint256 _swapId, uint256 _offerId)
        public
        onlySeller(_swapId)
    {
        require(
            offers[_swapId][_offerId].status == Status.CREATED,
            "Can't Accept now"
        );
        // addresses
        address seller = swaps[_swapId].seller;
        address buyer = offers[_swapId][_offerId].buyer;

        // swap seller token
        address[] memory swapTokens = swaps[_swapId].swapTokens;
        uint256[] memory swapTokenIds = swaps[_swapId].swapTokenIds;
        for (uint256 i = 0; i < swapTokens.length; i++) {
            IERC721(swapTokens[i]).safeTransferFrom(
                seller,
                buyer,
                swapTokenIds[i]
            );
        }

        // swap buyer token
        address[] memory offerTokens = offers[_swapId][_offerId].offerTokens;
        uint256[] memory offerTokenIds = offers[_swapId][_offerId]
            .offerTokenIds;
        for (uint256 i = 0; i < offerTokens.length; i++) {
            IERC721(offerTokens[i]).safeTransferFrom(
                buyer,
                seller,
                offerTokenIds[i]
            );
        }

        // update some mappings
        swaps[_swapId].status = Status.ACCEPTED;
        swaps[_swapId].buyer = buyer;
        offers[_swapId][_offerId].status = Status.ACCEPTED;

        // emit event
        emit OfferAccepted(
            seller,
            swapTokens,
            swapTokenIds,
            buyer,
            offerTokens,
            offerTokenIds
        );
    }

    function rejectOffer() public {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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