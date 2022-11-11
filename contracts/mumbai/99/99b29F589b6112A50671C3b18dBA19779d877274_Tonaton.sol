//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * A time-based auction marketplace. Think of it as ebay for blockchain where individuales
 * can create auctions for their various items, set an auction ellapse time, and a minimum bid amount
 * for their auction.
 * The auction charges 10 gwei for each auction which is deducted at the end of an auction when
 * there is successful highest bidder.
 */
contract Tonaton is IERC721Receiver {
    using Counters for Counters.Counter;
    event AuctionCreated(
        uint256 indexed auction,
        address indexed owner,
        address nft,
        uint256 tokenId,
        uint256 leastBid
    );
    event AuctionStarted(uint256 indexed auction, uint256 startedTime);
    event BidPlaced(
        uint256 indexed auction,
        address indexed bidder,
        uint256 amount
    );
    event AuctionEnded(uint256 indexed auction, uint256 endTime);

    address private _admin;
    uint256 fee = 10 gwei;
    uint256 private _chargedFees;
    mapping(uint256 => Auction) public auctions;
    Counters.Counter public _auctionCounter;

    struct Auction {
        address seller;
        address nft;
        uint256 tokenId;
        uint256 leastBid;
        uint256 highestBid;
        address highestBidder;
        uint256 startTime;
        uint256 endTime;
        mapping(address => uint256) bids;
    }

    modifier onlyOwner(uint256 auctionIndex) {
        require(
            msg.sender == auctions[auctionIndex].seller,
            "You do not own this auction"
        );
        _;
    }

    modifier auctionHasStarted(uint256 auctionIndex) {
        require(
            auctionIndex <= _auctionCounter.current(),
            "Index out of range"
        );
        Auction storage _auction = auctions[auctionIndex];
        require(
            _auction.startTime > 0 && (_auction.startTime < block.timestamp),
            "Auction has not started"
        );
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "You are unauthorized for this action");
        _;
    }

    constructor() {
        //set contract admin
        _admin = msg.sender;
    }

    /**
     *@dev create an auction for any nft
     * @param _nft address of the nft contract
     * @param _tokenId ID of the nft on the contract
     * @param _leastBid the minimum bid for the auction
     */
    function createAuction(
        address _nft,
        uint256 _tokenId,
        uint256 _leastBid
    ) external {
        _auctionCounter.increment();
        require(_nft != address(0), "Invalid contract address");
        require(
            IERC721(_nft).ownerOf(_tokenId) == msg.sender &&
                IERC721(_nft).getApproved(_tokenId) == address(this),
            "Invalid caller or contract hasn't been approved"
        );
        IERC721(_nft).transferFrom(msg.sender, address(this), _tokenId);

        Auction storage _auction = auctions[_auctionCounter.current()];
        _auction.seller = msg.sender;
        _auction.nft = _nft;
        _auction.tokenId = _tokenId;
        _auction.leastBid = _leastBid;

        emit AuctionCreated(
            _auctionCounter.current(),
            msg.sender,
            _nft,
            _tokenId,
            _leastBid
        );
    }

    /**
     * start an auctions if you are the one who created it
     * @param index auction ID
     * @param endTime timestamp for when auction should end
     */
    function start(uint256 index, uint256 endTime) external onlyOwner(index) {
        Auction storage _auction = auctions[index];
        require(
            _auction.startTime == 0 && _auction.endTime == 0,
            "Auction has already started"
        );
        _auction.startTime = block.timestamp;
        _auction.endTime = block.timestamp + endTime;
        emit AuctionStarted(index, _auction.startTime);
    }

    /**
     * bid in an auction
     * @param index auction ID
     */
    function bid(uint256 index) external payable auctionHasStarted(index) {
        Auction storage _auction = auctions[index];
        require(
            msg.value > _auction.highestBid && msg.value >= _auction.leastBid,
            "Amount is too small"
        );
        require(
            msg.sender != _auction.highestBidder,
            "You can't outbid yourself"
        );
        require(_auction.endTime > block.timestamp, "Auction is over");
        if (msg.value > _auction.highestBid) {
            _auction.highestBid = msg.value;
            _auction.highestBidder = msg.sender;
        }

        _auction.bids[msg.sender] += msg.value;
        emit BidPlaced(index, msg.sender, msg.value);
    }

    /**
     * End auction, send nft to highest bidder, pay charges and
     * withdraw highest bid amount if you are the owner
     * @param index auction ID
     */
    function end(uint256 index)
        external
        payable
        onlyOwner(index)
        auctionHasStarted(index)
    {
        Auction storage _auction = auctions[index];

        require(block.timestamp >= _auction.endTime, "Auction time has not elapsed");

        if(_auction.highestBidder == address(0)){
             IERC721(_auction.nft).safeTransferFrom(address(this), _auction.seller, _auction.tokenId);
             emit AuctionEnded(index, block.timestamp);
             return;
        }

        address winner = _auction.highestBidder;

        //deduct auction fee
        uint256 amount = _auction.highestBid - fee;
        _chargedFees += fee;

        IERC721(_auction.nft).safeTransferFrom(address(this), winner, _auction.tokenId);
        
        _auction.highestBid = 0;

        (bool sent, ) = payable(_auction.seller).call{value: amount}("");

        require(sent, "Failed to transfer amount");

        emit AuctionEnded(index, block.timestamp);
    }

    /**
     * withdraw bid funds.
     * @param index auction ID
     */
    function withdraw(uint256 index) external payable {
        Auction storage auction = auctions[index];
        require(msg.sender != address(0), "Invalid address");
        require(auction.bids[msg.sender] > 0, "No bid");
        require(
            msg.sender != auction.highestBidder,
            "Highest bidder cannot withdraw"
        );

        uint256 amount = auction.bids[msg.sender];
        auction.bids[msg.sender] = 0;

        (bool sent, ) = payable(msg.sender).call{value: amount}("");

        require(sent, "Failed to send amount");
    }

    ///@dev withdraw fees charged for successful auctions
    function withdrawChargedFees() external onlyAdmin {
        uint amount = _chargedFees;
        _chargedFees = 0;
        (bool sent,) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send amount");
    }

    function getChargedFees() public view returns (uint256) {
        return _chargedFees;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return bytes4(this.onERC721Received.selector);
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