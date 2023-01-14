pragma solidity ^0.8.0;

import "../interfaces/IWonderGameCharacterInventory.sol";
import "../interfaces/IWonderGameMinter.sol";
import "../interfaces/INFTMintInitiator.sol";

import "../interfaces/IMushroom.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract WonderGameAuction is Ownable, Pausable, INFTMintInitiator {
    event AuctionStarted(uint256 auctionid, uint256 nftId, uint256 startTime);
    event Bid(uint256 auctionid, address sender, uint256 amount, uint256 timeStamp);
    event AuctionEnded(uint256 auctionid, uint256 nftId, address winner, uint256 amount, uint256 timeStamp);

    IWonderGameMinter wonderGameMinter;
    IWonderGameCharacterInventory wonderGame;
    IMushroom shroomContract;

    struct BidHistory {
        address bidder;
        uint256 bidAmount;
        uint256 bidtime;
    }

    struct Auction {
        uint256 nftId;
        BidHistory[] bidHistorybyId;
        uint256 bidCounter;
        uint256 startTime;
        uint256 endTime;
        bool isClaimed;
        uint256 highestBid;
        address highestBidder;
    }

    struct AuctionRequest {
        uint256 nftId;
        uint256 bidCounter;
        uint256 startTime;
        uint256 endTime;
        bool isClaimed;
        uint256 highestBid;
        address highestBidder;
    }

    uint256 public bidtime;
    uint256 public auctionId = 2;
    uint256 public startingBid;
    uint256 public maxAuctionCount = 365;
    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    mapping(uint256 => bool) requestIds;
    mapping(uint256 => uint256) requestStartTime;
    mapping(uint256 => Auction) public auctionRegistry;

    function setAuctionRegistry(uint256 _auctionId, AuctionRequest memory auctionDetails) external onlyOwner {
        auctionRegistry[_auctionId].nftId = auctionDetails.nftId;
        auctionRegistry[_auctionId].bidCounter = auctionDetails.bidCounter;
        auctionRegistry[_auctionId].startTime = auctionDetails.startTime;
        auctionRegistry[_auctionId].endTime = auctionDetails.endTime;
        auctionRegistry[_auctionId].isClaimed = auctionDetails.isClaimed;
        auctionRegistry[_auctionId].highestBid = auctionDetails.highestBid;
        auctionRegistry[_auctionId].highestBidder = auctionDetails.highestBidder;
    }

    function setBidHistory(uint256 _auctionId, BidHistory[] memory _bids) external onlyOwner {
        uint256 loop = _bids.length;
        delete auctionRegistry[_auctionId].bidHistorybyId;
        for (uint256 i; i < loop; i++) {
            auctionRegistry[_auctionId].bidHistorybyId.push(_bids[i]);
        }
    }

    constructor(
        IWonderGameCharacterInventory _wonder,
        IWonderGameMinter _nftMinter,
        IMushroom _shroomContract
    ) {
        wonderGame = _wonder;
        wonderGameMinter = _nftMinter;
        shroomContract = _shroomContract;
        bidtime = 1200;
        shroomContract.approve(owner(), MAX_INT);
        wonderGame.setApprovalForAll(owner(), true);
    }

    function setBidTime(uint256 _time) external onlyOwner {
        bidtime = _time;
    }

    function setStartingBid(uint256 _startingBid) external onlyOwner {
        startingBid = _startingBid;
    }

    function setAuctionCount(uint256 _maxCount) external onlyOwner {
        maxAuctionCount = _maxCount;
    }

    function setWonderGameMinter(IWonderGameMinter _address) external onlyOwner {
        wonderGameMinter = _address;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function acknowledgeMint(
        uint256 _requestId,
        address _user,
        uint256[] memory _tokenIds
    ) external override {
        require(msg.sender == address(wonderGameMinter), "Unauthorized Access");
        require(_user == address(this), "Unauthorized");
        require(_tokenIds.length == 1, "Multiple tokens minted");
        require(!requestIds[_requestId], "request id already used");
        _start(_tokenIds[0], requestStartTime[_requestId]);
        requestIds[_requestId] = true;
    }

    function _start(uint256 _tokenId, uint256 _startTime) internal {
        auctionRegistry[auctionId].startTime = _startTime;
        auctionRegistry[auctionId].endTime = _startTime + bidtime;

        auctionRegistry[auctionId].nftId = _tokenId;
        auctionRegistry[auctionId].highestBid = startingBid;
        emit AuctionStarted(auctionId, _tokenId, _startTime);
    }

    function bid(uint256 _bidAmount) external whenNotPaused {
        uint256 _previousHighestBid = auctionRegistry[auctionId].highestBid;
        require(_bidAmount > _previousHighestBid, "bid value should be greater than current bid value");

        address _previousHighestBidder = auctionRegistry[auctionId].highestBidder;
        _bid(_bidAmount);

        if (msg.sender == _previousHighestBidder) {
            _bidAmount = _bidAmount - _previousHighestBid;
        }

        shroomContract.transferFrom(msg.sender, address(this), _bidAmount);

        if (msg.sender != _previousHighestBidder && _previousHighestBidder != address(0)) {
            shroomContract.transfer(_previousHighestBidder, _previousHighestBid);
        }
    }

    function _bid(uint256 _bidAmount) internal {
        address user = msg.sender;
        uint256 currentTimestamp = block.timestamp;

        require(currentTimestamp > auctionRegistry[auctionId].startTime, "Auction not started");
        require(currentTimestamp <= auctionRegistry[auctionId].endTime, "Auction ended");
        require(user != address(0), "Caller shouldnt be zero address");

        auctionRegistry[auctionId].highestBidder = user;
        auctionRegistry[auctionId].highestBid = _bidAmount;

        BidHistory memory tempBidHistory = BidHistory(user, _bidAmount, currentTimestamp);

        auctionRegistry[auctionId].bidHistorybyId.push(tempBidHistory);
        auctionRegistry[auctionId].bidCounter += 1;

        emit Bid(auctionId, user, _bidAmount, currentTimestamp);
    }

    function claim(uint256 _auctionId) external {
        address user = msg.sender;
        uint256 currentTimestamp = block.timestamp;

        require(currentTimestamp > auctionRegistry[_auctionId].endTime, "Auction not ended");
        require(auctionRegistry[_auctionId].highestBidder == user, "Only Winner can claim");
        require(!auctionRegistry[_auctionId].isClaimed, "Already claimed the winning NFT");

        auctionRegistry[_auctionId].isClaimed = true;

        wonderGame.safeTransferFrom(address(this), user, auctionRegistry[_auctionId].nftId);
    }

    function getBidHistoryById(
        uint256 _auctionid,
        uint256 _page,
        uint256 _pagelimit
    ) external view returns (BidHistory[] memory) {
        uint256 start = _page * _pagelimit;
        uint256 endindex;

        uint256 arraylength = auctionRegistry[_auctionid].bidHistorybyId.length;
        if (_pagelimit > arraylength - start) {
            endindex = arraylength - 1;
        } else {
            endindex = start + (_pagelimit - 1);
        }

        BidHistory[] memory History = new BidHistory[](endindex - start + 1);

        for (uint256 i = start; i <= endindex; i++) {
            History[i - start] = auctionRegistry[_auctionid].bidHistorybyId[i];
        }
        return History;
    }

    function end() external whenNotPaused {
        uint256 endtime = _end();
        if (auctionId <= maxAuctionCount) {
            uint256 requestId = wonderGameMinter.mint(address(this), 1);
            requestStartTime[requestId] = endtime;
        }
    }

    function _end() internal returns (uint256) {
        uint256 currentTimestamp = block.timestamp;
        uint256 _endTime = auctionRegistry[auctionId].endTime;

        require(currentTimestamp > _endTime, "Auction time is not over!");

        uint256 nftId = auctionRegistry[auctionId].nftId;

        if (auctionRegistry[auctionId].highestBidder != address(0)) {
            shroomContract.burn(auctionRegistry[auctionId].highestBid);
        } else {
            wonderGame.burn(nftId);
        }

        emit AuctionEnded(
            auctionId,
            nftId,
            auctionRegistry[auctionId].highestBidder,
            auctionRegistry[auctionId].highestBid,
            currentTimestamp
        );
        auctionId++;
        return _endTime;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public view returns (bytes4) {
        require(msg.sender == address(wonderGame), "Only wonder game is allowed");
        return this.onERC721Received.selector;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface IWonderGameCharacterInventory is IERC721 {
    function burn(uint256 _tokenId) external;
    function mint(address _to,uint256 _tokenId,string memory _secondaryTokenUri,uint256 _generation) external;
    function mintBatch(address _to, uint256[] memory _tokenIds) external;

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IWonderGameMinter {
    function mint(address _user, uint256 _numOfTokens) external returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface INFTMintInitiator {
    function acknowledgeMint(uint256 _requestId,address _user,uint256[] memory _tokenIds) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMushroom is IERC20 {
    function burnFrom(address account, uint256 amount) external;
    function burn(uint256 amount) external;
    function mint(address account,uint256 amount) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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