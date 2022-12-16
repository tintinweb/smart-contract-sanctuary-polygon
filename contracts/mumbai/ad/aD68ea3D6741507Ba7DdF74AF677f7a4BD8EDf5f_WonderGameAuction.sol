// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../interfaces/IWonderGameCharacterInventory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IWonderGameMinter.sol";
import "../interfaces/INFTMintInitiator.sol";

contract WonderGameAuction is IERC721Receiver, Ownable, INFTMintInitiator {
    event AuctionStarted(uint256 auctionid, uint256 nftId, uint256 startTime);
    event Bid(
        uint256 auctionid,
        address indexed sender,
        uint256 amount,
        uint256 timeStamp
    );
    event AuctionEnded(
        uint256 auctionid,
        uint256 nftId,
        address winner,
        uint256 amount,
        uint256 timeStamp
    );

    IWonderGameCharacterInventory wonderGame;
    IWonderGameMinter wonderMinter;

    uint256 public bidtime = 3600;
    struct BidHistory {
        address bidder;
        uint256 bidAmount;
        uint256 bidtime;
    }

    struct Auction {
        uint256 id;
        uint256 nftId;
        BidHistory[] bidHistorybyId;
        uint256 bidCounter;
        uint256 startTime;
        uint256 endTime;
        bool started;
        bool ended;
        uint256 highestBid;
        address highestBidder;
    }
    mapping(uint256 => Auction) public auctionRegistry;
    uint256 public auctionId = 0;
    address public treasuryAddress;
    uint256 startingBid;

    constructor(
        IWonderGameCharacterInventory _wonder,
        IWonderGameMinter _minter,
        address _treasuryaddress
    ) {
        wonderGame = _wonder;
        treasuryAddress = _treasuryaddress;
        wonderMinter = _minter;
    }

    function setTreasury(address _treasuryaddress) external onlyOwner {
        treasuryAddress = _treasuryaddress;
    }

    function setBidTime(uint256 _time) external onlyOwner {
        bidtime = _time;
    }

    function setStartingBid(uint256 _startingBid) external onlyOwner {
        startingBid = _startingBid;
    }

    function startAuction() external onlyOwner {
        wonderMinter.mint(address(this), 1);
    }

    function acknowledgeMint(
        uint256,
        address,
        uint256[] memory
    ) external override {}

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

    function _start(uint256 _tokenId) internal {
        if (
            auctionRegistry[auctionId].started &&
            !auctionRegistry[auctionId].ended
        ) {
            _end();
        }

        auctionRegistry[auctionId].started = true;
        auctionRegistry[auctionId].ended = false;

        if (auctionId == 0) {
            auctionRegistry[auctionId].endTime = block.timestamp + bidtime;
        } else {
            auctionRegistry[auctionId].endTime =
                auctionRegistry[auctionId - 1].endTime +
                bidtime;
        }

        auctionRegistry[auctionId].nftId = _tokenId;
        auctionRegistry[auctionId].id = auctionId;
        auctionRegistry[auctionId].highestBid = startingBid;
        auctionRegistry[auctionId].startTime = block.timestamp;
        // auctionRegistry[auctionId].endTime = block.timestamp + bidtime;
        emit AuctionStarted(auctionId, _tokenId, block.timestamp);
    }

    function bid() external payable {
        require(auctionRegistry[auctionId].started, "not started");
        require(msg.sender != address(0), "caller shouldnt be zero address");
        require(block.timestamp < auctionRegistry[auctionId].endTime, "ended");
        require(
            msg.value > auctionRegistry[auctionId].highestBid,
            "bid value should be greater than current bid value"
        );
        address user = msg.sender;

        if (auctionRegistry[auctionId].highestBidder != address(0)) {
            payable(auctionRegistry[auctionId].highestBidder).transfer(
                auctionRegistry[auctionId].highestBid
            );
        }

        auctionRegistry[auctionId].highestBidder = user;
        auctionRegistry[auctionId].highestBid = msg.value;

        BidHistory memory tempBidHistory = BidHistory(
            user,
            auctionRegistry[auctionId].highestBid,
            block.timestamp
        );

        auctionRegistry[auctionId].bidHistorybyId.push(tempBidHistory);
        auctionRegistry[auctionId].bidCounter += 1;

        emit Bid(
            auctionId,
            user,
            auctionRegistry[auctionId].highestBid,
            block.timestamp
        );
    }

    function increaseBid() external payable {
        require(auctionRegistry[auctionId].started, "not started");
        require(msg.sender != address(0), "caller shouldnt be zero address");
        require(block.timestamp < auctionRegistry[auctionId].endTime, "ended");
        require(
            msg.sender == auctionRegistry[auctionId].highestBidder,
            "Only highest bidder can increase the bid!"
        );

        address user = msg.sender;
        auctionRegistry[auctionId].highestBidder = user;
        auctionRegistry[auctionId].highestBid += msg.value;

        BidHistory memory tempBidHistory = BidHistory(
            user,
            auctionRegistry[auctionId].highestBid,
            block.timestamp
        );

        auctionRegistry[auctionId].bidHistorybyId.push(tempBidHistory);
        auctionRegistry[auctionId].bidCounter += 1;

        emit Bid(
            auctionId,
            user,
            auctionRegistry[auctionId].highestBid,
            block.timestamp
        );
    }

    function getBidHistoryById(
        uint256 _auctionid,
        uint256 _page,
        uint256 _pagelimit
    ) external view returns (BidHistory[] memory) {
        uint256 start = _page * _pagelimit;
        uint256 endindex;

        uint256 arraylength = auctionRegistry[_auctionid].bidHistorybyId.length;
        require(arraylength >= start, "Invalid params");
        if (_pagelimit > (arraylength - start)) {
            endindex = arraylength - 1;
        } else {
            endindex = start + (_pagelimit - 1);
        }

        BidHistory[] memory History = new BidHistory[]((endindex - start) + 1);

        for (uint256 i = start; i <= endindex; i++) {
            History[i - start] = auctionRegistry[_auctionid].bidHistorybyId[i];
        }
        return History;
    }

    function end() external {
        _end();
    }

    function _end() internal {
        require(auctionRegistry[auctionId].started, "not started");
        require(
            block.timestamp >= auctionRegistry[auctionId].endTime,
            "not ended"
        );
        require(!auctionRegistry[auctionId].ended, "ended");

        auctionRegistry[auctionId].ended = true;
        auctionRegistry[auctionId].started = true;
        uint256 nftId = auctionRegistry[auctionId].nftId;
        if (auctionRegistry[auctionId].highestBidder != address(0)) {
            payable(treasuryAddress).transfer(
                auctionRegistry[auctionId].highestBid
            );
            wonderGame.safeTransferFrom(
                address(this),
                auctionRegistry[auctionId].highestBidder,
                nftId
            );
        } else {
            wonderGame.burn(nftId);
        }

        auctionId += 1;
        emit AuctionEnded(
            auctionId,
            nftId,
            auctionRegistry[auctionId].highestBidder,
            auctionRegistry[auctionId].highestBid,
            block.timestamp
        );
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface IWonderGameCharacterInventory is IERC721 {
    function burn(uint256 _tokenId) external;
    function mint(address _to,uint256 _tokenId,string memory _secondaryTokenUri,uint256 _generation) external;
    function mintBatch(address _to, uint256[] memory _tokenIds) external;

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IWonderGameMinter {
    function mint(address _user, uint256 _numOfTokens) external returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface INFTMintInitiator {
    function acknowledgeMint(
        uint256 _requestId,
        address _user,
        uint256[] memory _tokenIds
    ) external;
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