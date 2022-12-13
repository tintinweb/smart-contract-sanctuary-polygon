/**
 *Submitted for verification at polygonscan.com on 2022-12-13
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: contracts/IWonderGameCharacterInventory.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface IWonderGameCharacterInventory is IERC721 {
    function burn(uint256 _tokenId) external;

    function mint(
        address _to,
        uint256 _tokenId,
        string memory _secondaryTokenUri,
        uint256 _generation
    ) external;

    function mintBatch(
        address _to,
        uint256[] memory _tokenIds,
        string[] memory _secondaryTokenUris,
        uint256 _generation
    ) external;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: contracts/1_Storage.sol


pragma solidity ^0.8.0;




contract wonderLandAuction is IERC721Receiver, Ownable {
    event Start(uint256 auctionid, uint256 nftId, uint256 startTime);
    event Bid(
        uint256 auctionid,
        address indexed sender,
        uint256 amount,
        uint256 timeStamp
    );
    event End(
        uint256 auctionid,
        uint256 nftId,
        address winner,
        uint256 amount,
        uint256 timeStamp
    );

    IWonderGameCharacterInventory wonderGame;

    bool public started;
    bool public ended;
    uint256 public highestBid;
    address public highestBidder;
    uint256 public bidtime = 600;
    struct BidHistory {
        address bidder;
        uint256 bidAmount;
        uint256 Bidtime;
    }
    struct Auction {
        uint256 nftId;
        BidHistory[] bidHistorybyId;
        uint256 bidCounter;
        uint256 auctionStartTime;
    }
    mapping(uint256 => Auction) public AuctionbyId;
    uint256 public AuctionId = 0;
    address public treasuryAddress;
    uint256 endtime;
    uint256 startingBid;

    constructor(IWonderGameCharacterInventory _wonder, address _treasuryaddress)
    {
        wonderGame = _wonder;
        treasuryAddress = _treasuryaddress;
    }

    function changeTreasuryAccount(address _treasuryaddress)
        external
        onlyOwner
    {
        treasuryAddress = _treasuryaddress;
    }

    function setBidTime(uint256 _time) external onlyOwner {
        bidtime = _time;
    }

    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes memory
    ) public override returns (bytes4) {
        require(
            address(wonderGame) == msg.sender,
            "This contract only accepts wondergame Nfts"
        );
        require(_from == owner(), "Only receives nft from admin account"); //nft sender role

        _start(_tokenId);
        return this.onERC721Received.selector;
    }

    function changeStartingBid(uint256 _startingBid) external onlyOwner {
        startingBid = _startingBid;
    }

    function _start(uint256 _tokenId) internal {
        if (started && !ended) {
            _end();
        }
        started = true;
        ended = false;

        if (AuctionId == 0) {
            endtime = block.timestamp + bidtime;
        } else {
            endtime += bidtime;
        }

        AuctionbyId[AuctionId].nftId = _tokenId;
        highestBid = startingBid;
        AuctionbyId[AuctionId].auctionStartTime = block.timestamp;
        emit Start(AuctionId, _tokenId, block.timestamp);
    }

    function bid() external payable {
        require(started, "not started");
        require(msg.sender != address(0), "caller shouldnt be zero address");
        require(block.timestamp < endtime, "ended");
        require(
            msg.value > highestBid,
            "bid value should be greater than current bid value"
        );
        address user = msg.sender;

        if (highestBidder != address(0)) {
            payable(highestBidder).transfer(highestBid);
        }

        highestBidder = user;
        highestBid = msg.value;

        BidHistory memory tempBidHistory = BidHistory(
            user,
            highestBid,
            block.timestamp
        );

        AuctionbyId[AuctionId].bidHistorybyId.push(tempBidHistory);
        AuctionbyId[AuctionId].bidCounter += 1;

        emit Bid(AuctionId, user, highestBid, block.timestamp);
    }

    function getBidHistoryById(
        uint256 _auctionid,
        uint256 _page,
        uint256 _pagelimit
    ) external view returns (BidHistory[] memory) {
        uint256 start = _page * _pagelimit;
        uint256 endindex;

        uint256 arraylength = AuctionbyId[_auctionid].bidHistorybyId.length;
        if (_pagelimit > arraylength - start) {
            endindex = arraylength - start - 1;
        } else {
            endindex = start + (_pagelimit - 1);
        }

        BidHistory[] memory History = new BidHistory[](endindex - start + 1);

        for (uint256 i = start; i <= endindex; i++) {
            History[i] = AuctionbyId[_auctionid].bidHistorybyId[i];
        }
        return History;
    }

    function end() external {
        _end();
    }

    function _end() internal {
        require(started, "not started");
        require(block.timestamp >= endtime, "not ended");
        require(!ended, "ended");

        ended = true;
        started = false;
        uint256 nftId = AuctionbyId[AuctionId].nftId;
        if (highestBidder != address(0)) {
            payable(treasuryAddress).transfer(highestBid);
            wonderGame.safeTransferFrom(address(this), highestBidder, nftId);
        } else {
            wonderGame.burn(nftId);
        }
        AuctionId += 1;

        emit End(AuctionId, nftId, highestBidder, highestBid, block.timestamp);
        delete highestBid;
        delete highestBidder;
    }
}