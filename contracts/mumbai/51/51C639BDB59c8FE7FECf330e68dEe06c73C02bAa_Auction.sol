//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/utils/Strings.sol";
import "./NFTEscrow.sol";

contract Auction is NFTEscrow, Ownable {

    uint256 public highestBid;
    uint256 public auctionStartTime;
    uint256 public auctionEndTime;
    uint256 public auctionGracePeriod;
    uint256 public bonus;

    uint256 public minBid;
    uint256 public minIncrementBid;

    address public highestBidder;
    address public registryCreator;

    bool public auctionStarted;
    bool public auctionEnded;
    bool public registered;

    mapping(address => uint256) public deposits;
    //Need to tie the address to the NFT Auctions and an Id to the auctions
    mapping(address => NFTAuction) public nftauctions;
    // mapping(address => uint256) public myAuctions;  // Possible to have multiple auctions

    struct NFTAuction {
        //fix this
        address auctionCreator;
        address nftContract;
        uint256 nftTokenId;
        bool claimed;
     //  uint256 auctionNumber;
     //  address highestBidder;
     //  uint256 theHighestBid;
        
    }

     event AuctionRegistered(address creator, address _contractAddress, uint256 _tokenID, uint256 _minimumBid, uint256 _minimumIncrementBid);
     event AuctionStarted(address creator, uint256 _time);
     event NewBid(address minter, uint256 _amount, uint256 _bonus);
     event AuctionCompleted(address _winner, uint256 _amount, address _nftContract, uint256 _tokenID, address _auctioner, uint256 _payout);
     event AuctionCompletedByCommunity(address _winner, uint256 _amount, address _nftContract, uint256 _tokenID, address _auctioner, uint256 _payout, address _bountyHunter, uint256 _bounty);

    constructor() {}

    //step1 register
    function registerNFTAuction(address _contractAddress, uint256 _tokenId, uint256 _minBid, uint256 _minIncrement) public {
        //possibly make payable to stop trolling
        require(registered == false, "Registration is already live");
        nftauctions[msg.sender].auctionCreator = msg.sender;
        nftauctions[msg.sender].nftContract = _contractAddress;
        nftauctions[msg.sender].nftTokenId = _tokenId;
        nftauctions[msg.sender].claimed = false;
        // nftauctions[msg.sender].auctionNumber = 1; tbd //using counters
        
        registerAuction(_contractAddress, _tokenId);
        registryCreator = msg.sender;
        highestBidder = address(0);
        registered = true;
        minBid = _minBid;
        minIncrementBid = _minIncrement;
        auctionGracePeriod = block.timestamp + 300;

        //need timer to override this is they slacking

        emit AuctionRegistered(msg.sender, _contractAddress, _tokenId, minBid, minIncrementBid);
    }

    function startAuction(uint256 _time) public {
        //set a max time limit
        //time is in seconds
        require(nftauctions[msg.sender].auctionCreator == msg.sender, "Not Auction Creator.");
        require(auctionStarted == false, "Auction already started.");
        require(nftauctions[msg.sender].claimed == false, "No NFT to auction");
        require(_time >= 300 && _time <= 600, "Time must be between 5 and 10 minutes");
        auctionStarted = true;
        auctionStartTime = block.timestamp;
        auctionEndTime = (auctionStartTime + _time); 
        //possible time extender

        emit AuctionStarted(msg.sender, _time);
    }

    function bid() public payable {
        if(highestBidder == address(0)){
            require(msg.value >= minBid, "Bid is not high enough");
        }
        require(auctionStarted == true, "Auction Hasn't started.");
        require(block.timestamp < auctionEndTime, "Auction has already ended");
        require(msg.value >= highestBid + minIncrementBid, "New Bid is not high enough");   // possibly check for minimum increment bid and lowest bid

        // Return previous highest bidder's deposit
        if (highestBidder != address(0)) {
            bonus = calculateBonus(msg.value);
            (bool success, ) = payable(highestBidder).call{ value: bonus + deposits[highestBidder] }("");
            require(success, "payment not sent");
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        deposits[msg.sender] = msg.value;

        //last minute bids adds another minute to auction
        if(block.timestamp >= auctionEndTime - 60) { 
            auctionEndTime = (auctionEndTime + 60); 
        }

        emit NewBid(msg.sender, msg.value, bonus);
    }

    function calculateBonus(uint256 _bid) internal view returns (uint256) {
        // 5% bonus
        uint256 difference = (((_bid - highestBid) * 5) / 100);
        return difference;
    }

    function calculateNewMinBid() external view returns (uint256) {
        uint256 nextMinBid = (highestBid + minIncrementBid);
        return nextMinBid;
    }

    function willFinishAt() public view returns (uint256) {
        if (auctionStartTime == 0) {
            return 0;
        } else {
            return auctionEndTime;
        }
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawAuctionFunds() external {
        require(msg.sender == depositors[msg.sender].nftOwner, "Not Auctioneer");
        require(block.timestamp >= auctionEndTime, "Auction has not ended");
        if (highestBidder == address(0)) {
            withdrawToken(nftauctions[msg.sender].nftContract, nftauctions[msg.sender].nftTokenId,/* _depositId, */ nftauctions[msg.sender].auctionCreator);
            nftauctions[msg.sender].claimed = true;
        } else {
            withdrawToken(nftauctions[msg.sender].nftContract, nftauctions[msg.sender].nftTokenId,/* _depositId, */ highestBidder);
            nftauctions[msg.sender].claimed = true;
        }
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Payment not sent");

        //reset auction status
        auctionStarted = false;
        registered = false;
        registryCreator = address(0);
        auctionEndTime = 0;

        emit AuctionCompleted(highestBidder, highestBid, nftauctions[msg.sender].nftContract, nftauctions[msg.sender].nftTokenId, registryCreator, address(this).balance);
    }

    function communityAssistance() external { 
        require(block.timestamp >= auctionGracePeriod, "Auction in grace period");
        require(block.timestamp >= (auctionEndTime + 1 minutes), "Must wait to assist");
        if (highestBidder == address(0)) {
            withdrawToken(nftauctions[registryCreator].nftContract, nftauctions[registryCreator].nftTokenId,/* _depositId, */ nftauctions[registryCreator].auctionCreator);
            nftauctions[registryCreator].claimed = true;
        } else {
            withdrawToken(nftauctions[registryCreator].nftContract, nftauctions[registryCreator].nftTokenId,/* _depositId, */ highestBidder);
            nftauctions[registryCreator].claimed = true;
        }

        uint256 withdrawAmount_10 = (address(this).balance) * 10/100;  //10% tax
        //check if statment if there is balance in the contract
         if(address(this).balance > 0) {
            (bool complete, ) = payable(msg.sender).call{value: withdrawAmount_10}("");
            require(complete, "bounty funds not sent");
            (bool success, ) = payable(registryCreator).call{value: address(this).balance}("");
            require(success, "funds not sent");
         }

        //reset auction status
        auctionStarted = false;
        registered = false;
        registryCreator = address(0);
        auctionEndTime = 0;
        // timeout user?

        emit AuctionCompletedByCommunity(highestBidder, highestBid, nftauctions[registryCreator].nftContract, nftauctions[registryCreator].nftTokenId, registryCreator, address(this).balance, msg.sender, withdrawAmount_10);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./Interfaces/IERC721.sol";
import "./Interfaces/IERC721Reciever.sol";


contract NFTEscrow is IERC721Receiver {
    using Counters for Counters.Counter;
    Counters.Counter private _depositorIdCounter;
    
    // mapping(uint256 => address) public NFTOwner;
    // mapping(uint256 => uint256) public tknIdOwner;

     struct Depositor {
        address nftOwner;
        address nftContract;
        uint256 tknIdOwner;
        uint256 depositId;
        // uint256 finalBid;
        bool claimed;
        // mapping(address => bool) voters;
    }
    
    uint256 public _tokenIdCounter = 1;
    uint256 public tokensRecieved = 0;

    mapping(address => Depositor) public  depositors;
    //Depositor public depositor;
   // constructor(address nftContract)  {
    constructor()  {
      //  _depositorIdCounter.increment();
      //  paperNft = INFT(nftContract);
    }

    function registerAuction(address _contractAddress, uint256 tokenId) internal {

        uint256 depositId = _depositorIdCounter.current();
        _depositorIdCounter.increment();
        depositors[msg.sender].nftOwner = msg.sender;
        depositors[msg.sender].nftContract = _contractAddress;
        depositors[msg.sender].tknIdOwner = tokenId;
        depositors[msg.sender].depositId = depositId;
        depositors[msg.sender].claimed = false;
        IERC721(_contractAddress).safeTransferFrom(msg.sender, address(this), tokenId, "0x0");
        //event - NFT register for auction
    }

    function withdrawToken(address token, uint256 _tokenId, /*uint256 depositId,*/ address _winner) internal  {
       require(depositors[msg.sender].claimed == false, "Already Claimed");
       depositors[msg.sender].claimed = true;
       IERC721(token).safeTransferFrom(address(this), _winner, _tokenId, "0x0");
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public override returns (bytes4) {
       // require(paperNft.ownerOf(tokenId) == address(this), "MALICIOUS");
       // require(paperNft.ownerOf(tokenId) == from, "user must be the owner of the token");

        // depositor.nftOwner = from;
        // depositor.tknIdOwner = tokenId;
        ++_tokenIdCounter;
        ++tokensRecieved;
      
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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