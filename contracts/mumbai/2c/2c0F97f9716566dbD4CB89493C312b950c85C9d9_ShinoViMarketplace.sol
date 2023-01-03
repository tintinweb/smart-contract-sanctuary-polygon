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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IShinoViNFTFactory {

    function createNFTCollection(
        string memory _name,
        string memory _symbol,
        address _owner,
        uint256 _royaltyFee,
        address _royaltyRecipient
    ) external returns (address);

    function isShinoViNFT(address _nft) external view returns (bool);

}

interface IShinoViNFT {

    function getRoyaltyFee() external view returns (uint256);

    function getRoyaltyRecipient() external view returns (address);

}

struct PlatformFee {
    address recipient;
    uint256 fee;
}

struct Auction {
    address nft;
    uint256 tokenId;
    address creator;
    address paymentToken;
    uint256 initialPrice;
    uint256 minBid;
    uint256 startTime;
    uint256 endTime;
    uint256 bidPrice;
    address winningBidder;
    bool success;
}

struct Listing {
    address nft;
    uint256 tokenId;
    address owner;
    uint256 price;
    uint256 chainId;
    address paymentToken;
    bool sold;
}

struct Offer {
    address nft;
    uint256 tokenId;
    address offerer;
    uint256 offerPrice;
    address paymentToken;
    bool accepted;
}

contract ShinoViMarketplace is ReentrancyGuard  {

    IShinoViNFTFactory private immutable shinoViNFTFactory;

    // onwer
    address owner;

    // data structures
    PlatformFee[] private platformFees;
    // psyable tokens
    address[] private tokens;

    // token => isPayable
    mapping(address => bool) private payableToken;
    // nft => tokenId => listing 
    mapping(address => mapping(uint256 => Listing)) private listings;
    // nft => tokenId => auction 
    mapping(address => mapping(uint256 => Auction)) private auctions;
    // nft => tokenId => offer array
    mapping(address => mapping(uint256 => Offer[])) private offers;

    // events
    event ListedNFT(
        address indexed nft,
        uint256 indexed tokenId,
        address paymentToken,
        uint256 price,
        address indexed owner
    );

    event SoldNFT(
        address indexed nft,
        uint256 indexed tokenId,
        address paymentToken,
        uint256 price,
        address owner,
        address indexed buyer
    );

    event OfferredNFT(
        address indexed nft,
        uint256 indexed tokenId,
        address paymentToken,
        uint256 offerPrice,
        address indexed offerer
    );

    event CanceledOffer(
        address indexed nft,
        uint256 indexed tokenId,
        address paymentToken,
        uint256 offerPrice,
        address indexed offerer
    );

    event AcceptedOffer(
        address indexed nft,
        uint256 indexed tokenId,
        address paymentToken,
        uint256 offerPrice,
        address offerer,
        address indexed nftOwner
    );

    event CreatedAuction(
        address indexed nft,
        uint256 indexed tokenId,
        address paymentToken,
        uint256 price,
        uint256 minBid,
        uint256 startTime,
        uint256 endTime,
        address indexed creator
    );

    event PlacedBid(
        address indexed nft,
        uint256 indexed tokenId,
        address paymentToken,
        uint256 bidPrice,
        address indexed bidder
    );

    event AuctionResult(
        address indexed nft,
        uint256 indexed tokenId,
        address creator,
        address indexed winner,
        uint256 price,
        address caller
    );

    constructor(
      IShinoViNFTFactory _shinoViNFTFactory
    ) {
      shinoViNFTFactory = _shinoViNFTFactory;
    }

    // modifiers
    modifier isOwner() {
        require(msg.sender == owner, "unrecognized NFT collection");
        _;
    }

    modifier isShinoViNFT(address _nft) {
        require(shinoViNFTFactory.isShinoViNFT(_nft) == true, "unrecognized NFT collection");
        _;
    }

    modifier isListed(address _nft, uint256 _tokenId) {
        require(
             listings[_nft][_tokenId].owner != address(0) &&  listings[_nft][_tokenId].sold == false,
            "not listed"
        );
        _;
    }

    modifier isPayableToken(address _paymentToken) {
        require(
            _paymentToken != address(0) && payableToken[_paymentToken],
            "invalid pay token"
        );
        _;
    }

    modifier isAuction(address _nft, uint256 _tokenId) {
        require(
            auctions[_nft][_tokenId].nft != address(0) && auctions[_nft][_tokenId].success == false,
            "auction already created"
        );
        _;
    }

    modifier isNotAuction(address _nft, uint256 _tokenId) {
        require(
            auctions[_nft][_tokenId].nft == address(0) || auctions[_nft][_tokenId].success,
            "auction already created"
        );
        _;
    }

    modifier isOfferred(
        address _nft,
        uint256 _tokenId,
        address _offerer,
        uint256 _index
    ) {
        require(
            offers[_nft][_tokenId][_index].offerPrice > 0 && offers[_nft][_tokenId][_index].offerer != address(0),
            "not offerred nft"
        );
        _;
    }

    function listNFT(
        address _nft,
        uint256 _tokenId,
        uint256 _price,
        uint256 _chainId,
        address _paymentToken
    ) external isShinoViNFT(_nft) isPayableToken(_paymentToken) {
        IERC721 nft = IERC721(_nft);
        require(nft.ownerOf(_tokenId) == msg.sender, "access denied");
        nft.transferFrom(msg.sender, address(this), _tokenId);

        listings[_nft][_tokenId] = Listing({
            nft: _nft,
            tokenId: _tokenId,
            owner: msg.sender,
            price: _price,
            chainId: _chainId,
            paymentToken: _paymentToken,
            sold: false
        });

        emit ListedNFT(_nft, _tokenId, _paymentToken, _price, msg.sender);
    }

    // delist the nft
    function deListing(address _nft, uint256 _tokenId)
        external
        isListed(_nft, _tokenId)
    {
        Listing memory thisNFT = listings[_nft][_tokenId];
        require(thisNFT.owner == msg.sender, "access denied");
        require(thisNFT.sold == false, "nft has already been sold");
        IERC721(_nft).transferFrom(address(this), msg.sender, _tokenId);
        delete listings[_nft][_tokenId];
    }

    // purchase listing
    function purchaseNFT(
        address _nft,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _price
    ) external isListed(_nft, _tokenId) {
        Listing storage thisNFT = listings[_nft][_tokenId];
        require(
            _paymentToken != address(0) && _paymentToken == thisNFT.paymentToken,
            "invalid pay token"
        );
        require(thisNFT.sold == false, "nft has already been sold");
        require(_price >= thisNFT.price, "invalid price");
        thisNFT.sold = true; 

        processTransaction(_nft, _tokenId, _price, _paymentToken, thisNFT.owner, msg.sender, true);

        emit SoldNFT(
            thisNFT.nft,
            thisNFT.tokenId,
            thisNFT.paymentToken,
            _price,
            thisNFT.owner,
            msg.sender
        );

    }

    function createOffer(
        address _nft,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _offerPrice
    ) external isListed(_nft, _tokenId) {
        require(_offerPrice > 0, "price must be greater than zero.");

        Listing memory nft = listings[_nft][_tokenId];

        IERC20(nft.paymentToken).transferFrom(
            msg.sender,
            address(this),
            _offerPrice
        );

        offers[_nft][_tokenId].push(Offer({
            nft: nft.nft,
            tokenId: nft.tokenId,
            offerer: msg.sender,
            paymentToken: _paymentToken,
            offerPrice: _offerPrice,
            accepted: false
        }));

        emit OfferredNFT(
            nft.nft,
            nft.tokenId,
            nft.paymentToken,
            _offerPrice,
            msg.sender
        );

    }

    function cancelOffer(address _nft, uint256 _tokenId, uint _index)
        external
        isOfferred(_nft, _tokenId, msg.sender, _index)
    {
        Offer memory offer = offers[_nft][_tokenId][_index];
        require(offer.offerer == msg.sender, "not offerer");
        require(offer.accepted == false, "offer already accepted");
        delete offers[_nft][_tokenId][_index];
        IERC20(offer.paymentToken).transfer(offer.offerer, offer.offerPrice);
        
        emit CanceledOffer(
            offer.nft,
            offer.tokenId,
            offer.paymentToken,
            offer.offerPrice,
            msg.sender
        );
       
    }

    function acceptOffer(
        address _nft,
        uint256 _tokenId,
        address _offerer,
        uint256 _index
    )
        external
        isOfferred(_nft, _tokenId, _offerer, _index)
        isListed(_nft, _tokenId)
    {
        require(
            listings[_nft][_tokenId].owner == msg.sender,
            "not listed owner"
        );
        Offer storage offer = offers[_nft][_tokenId][_index];
        Listing storage list = listings[offer.nft][offer.tokenId];
        require(list.sold == false, "item already sold");
        require(offer.accepted == false, "offer already accepted");

        list.sold = true;
        offer.accepted = true;

        processTransaction(_nft, _tokenId, offer.offerPrice, offer.paymentToken, msg.sender, offer.offerer, false);

        emit AcceptedOffer(
            offer.nft,
            offer.tokenId,
            offer.paymentToken,
            offer.offerPrice,
            offer.offerer,
            list.owner
        );
       
    }

    //
    function createAuction(
        address _nft,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _price,
        uint256 _minBid,
        uint256 _startTime,
        uint256 _endTime
    ) external isPayableToken(_paymentToken) isNotAuction(_nft, _tokenId) {
        IERC721 nft = IERC721(_nft);
        require(nft.ownerOf(_tokenId) == msg.sender, "not nft owner");
        require(_endTime > _startTime, "invalid end time");

        nft.transferFrom(msg.sender, address(this), _tokenId);

        auctions[_nft][_tokenId] = Auction({
            nft: _nft,
            tokenId: _tokenId,
            creator: msg.sender,
            paymentToken: _paymentToken,
            initialPrice: _price,
            minBid: _minBid,
            startTime: _startTime,
            endTime: _endTime,
            winningBidder: address(0),
            bidPrice: _price,
            success: false
        });

        emit CreatedAuction(
            _nft,
            _tokenId,
            _paymentToken,
            _price,
            _minBid,
            _startTime,
            _endTime,
            msg.sender
        );
       
    }

    // 
    function cancelAuction(address _nft, uint256 _tokenId)
        external
        isAuction(_nft, _tokenId)
    {
        Auction memory auction = auctions[_nft][_tokenId];
        require(auction.creator == msg.sender, "not auction creator");
        require(block.timestamp < auction.startTime, "auction already started");
        require(auction.winningBidder == address(0), "already have bidder");

        IERC721 nft = IERC721(_nft);
        nft.transferFrom(address(this), msg.sender, _tokenId);
        delete auctions[_nft][_tokenId];
    }

    function placeBid(
        address _nft,
        uint256 _tokenId,
        uint256 _bidPrice
    ) external isAuction(_nft, _tokenId) {
        require(
            block.timestamp >= auctions[_nft][_tokenId].startTime,
            "auction not started"
        );
        require(
            block.timestamp <= auctions[_nft][_tokenId].endTime,
            "auction has ended"
        );
        require(
            _bidPrice >=
                 auctions[_nft][_tokenId].minBid,
            "bid price less than minimum"
        );
        require(
            _bidPrice >=
                auctions[_nft][_tokenId].bidPrice,
            "bid price less than current"
        );
        Auction storage auction = auctions[_nft][_tokenId];
        IERC20 paymentToken = IERC20(auction.paymentToken);
        paymentToken.transferFrom(msg.sender, address(this), _bidPrice);

        if (auction.winningBidder != address(0)) {
            address winningBidder = auction.winningBidder;
            uint256 lastBidPrice = auction.bidPrice;

            // Return funds to previous bidder
            paymentToken.transfer(winningBidder, lastBidPrice);
        }

        // Set new winning bid 
        auction.winningBidder = msg.sender;
        auction.bidPrice = _bidPrice;

        emit PlacedBid(_nft, _tokenId, auction.paymentToken, _bidPrice, msg.sender);
    }

    function finalizeAuction(address _nft, uint256 _tokenId) external {

        Auction storage auction = auctions[_nft][_tokenId];
        require(auction.success == false, "auction already finished");
        require(
            msg.sender == owner ||
                msg.sender == auction.creator ||
                msg.sender == auction.winningBidder,
            "access denied"
        );
        require(
            block.timestamp > auction.endTime,
            "auction still in progress"
        );

        IERC20 paymentToken = IERC20(auction.paymentToken);
        IERC721 nft = IERC721(auction.nft);

        auction.success = true;

        processTransaction(_nft, _tokenId, auction.bidPrice, auction.paymentToken, auction.creator, auction.winningBidder, false);

        emit AuctionResult(
            _nft,
            _tokenId,
            auction.creator,
            auction.winningBidder,
            auction.bidPrice,
            msg.sender
        );

    }

    function processTransaction(
      address _nft,
      uint256 _tokenId,
      uint256 _price,
      address paymentToken,
      address seller,
      address buyer,
      bool transferFrom) private {

        IShinoViNFT nft = IShinoViNFT(_nft);

        uint256 totalAmount = _price;
        address royaltyRecipient = nft.getRoyaltyRecipient();
        uint256 royaltyFee = nft.getRoyaltyFee();

        if (royaltyFee > 0) {

            uint256 royaltyAmount = (_price * royaltyFee) / 10000;

            // Process royalty
            if (transferFrom == true) {
                IERC20(paymentToken).transferFrom(
                    buyer,
                    royaltyRecipient,
                    royaltyAmount
                );
            } else {
                IERC20(paymentToken).transfer(
                    royaltyRecipient,
                    royaltyAmount
                );
            }
            totalAmount -= royaltyAmount;

        }

        // process platform fees
        for (uint i = 0; i < platformFees.length-1; i++) {

            uint256 platformFee = (_price * platformFees[i].fee) / 10000;
            if (transferFrom == true) {
                IERC20(paymentToken).transferFrom(
                    buyer,
                    platformFees[i].recipient,
                    platformFee
                );
            } else {
                IERC20(paymentToken).transfer(
                    platformFees[i].recipient,
                    platformFee
                );
            }
            totalAmount -= platformFee;

        }

        // Transfer to nft owner
        if (transferFrom == true) {

            IERC20(paymentToken).transferFrom(
                buyer,
                seller,
                totalAmount
            );
            IERC721(_nft).safeTransferFrom(
                seller,
                buyer,
                _tokenId
            );

        } else {

            IERC20(paymentToken).transfer(
                seller,
                totalAmount
            );
            IERC721(_nft).safeTransferFrom(
                address(this),
                buyer,
                _tokenId
            );

        }

    }

    function getListedNFT(address _nft, uint256 _tokenId)
        public
        view
        returns (Listing memory)
    {
        return listings[_nft][_tokenId];
    }

    function getPayableTokens() external view returns (address[] memory) {
        return tokens;
    }

    function addPayableToken(address _token) external isOwner {
        require(_token != address(0), "invalid token");
        require(payableToken[_token] == false, "already payable token");
        payableToken[_token] = true;
        tokens.push(_token);
    }

    function updatePlatformFee(uint256 _platformFee) external isOwner {
        require(_platformFee <= 10000, "can't more than 10 percent");
        // platformFee = _platformFee;
    }

    function changeFeeRecipient(address _feeRecipient) external isOwner {
        require(_feeRecipient != address(0), "can't be 0 address");
        // feeRecipient = _feeRecipient;
    }

}