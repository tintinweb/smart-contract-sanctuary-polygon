/**
 *Submitted for verification at polygonscan.com on 2022-09-11
*/

// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol


pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: @chainlink/contracts/src/v0.8/KeeperBase.sol


pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/KeeperCompatible.sol


pragma solidity ^0.8.0;



abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// File: interfaces/IMarketplace.sol



pragma solidity ^0.8.0;

interface IMarketplace{
  function buy(address _collection,uint256 _tokenId) external payable returns (bool);
  function getItemPrice(address _collection,uint256 _tokenId) external view returns (uint256);
  function getItemStatus(address _collection,uint256 _tokenId) external view returns (bool);
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


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/utils/Counters.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: SemoProtocol.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;







/**
 * @title SemoProtocol
 * @author Semo Team
 * @notice Semo Protocol Smart Contract
 */
contract SemoProtocol is Ownable, Pausable {

  /**
  * @notice Offer
  * @dev struct to store Offer details
  * @param offerCID: IPFS CID hash for get offer metadata
  * @param buyerAddress: buyerAddress wallet address
  * @param amount: max amount that buyer wanna pay
  * @param offerProposalCount: number of proposals for offer
  * @param isActive: offer status
  */
  struct Offer {
    string offerCID;
    address buyerAddress;
    uint256 amount;
    uint256 offerProposalCount;
    bool isActive;
  }

  /**
  * @notice Proposal
  * @dev struct to store Proposal details
  * @param proposalCID: IPFS CID hash for get proposal metadata
  * @param curatorAddress: address of curator
  * @param collection: nft collection address
  * @param tokenId: nft tokenId price
  * @param isListed: nft listed status at marketplace
  */
  struct Proposal {
    string proposalCID;
    address curatorAddress;
    address collection;
    uint256 tokenId;
    bool isListed;
  }

  IMarketplace public marketplaceContract;

  /**
  * @notice offers
  * @dev mapping with offer Id as key to store offers
  * @dev return Offer
  */
  mapping (uint256 => Offer) public offers; 

  /**
  * @notice proposals
  * @dev mapping with offer Id and proposal Id as keys to store proposals
  * @dev return Proposal
  */
  mapping (uint256 => mapping (uint256 => Proposal)) public proposals; 

  /**
  * @notice offerIdCounter
  * @dev variable to store total offers
  */
  uint256 public offerIdCounter;

  /**
  * @notice proposalIdCounter
  * @dev variable to store total proposals
  */
  uint256 public proposalIdCounter;

  /**
  * @notice fee
  * @dev variable to store fee
  * @return uint256
  */
  uint256 public fee;

  /**
  * @notice offerURI
  * @dev variable to store URI of offers metadata
  * @return string
  */
  string public offerURI;

  /**
  * @notice proposalURI
  * @dev variable to store URI of proposals metatada
  * @return string
  */
  string public proposalURI;

  /**
  * @notice interval
  * @dev variable to store keepers interval
  * @return uint256
  */
  uint256 public immutable interval;

  /**
  * @notice lastTimeStamp
  * @dev variable to store keepers lastTimeStamp
  * @return uint256
  */
  uint256 public lastTimeStamp;

  /**
  * @notice NewOffer
  * @dev event that is trigged when offer is created
  */
  event NewOffer(uint256 indexed offerId, string offerCID, address indexed buyerAddress, uint256 amount);

  /**
  * @notice NewProposal
  * @dev event that is trigged when proposal is created
  */
  event NewProposal(uint256 indexed offerId, uint256 indexed proposalId, string proposalCID, address collection, uint256 tokenId);

  /**
  * @notice Buy
  * @dev event that is trigged when one proposal is accept and NFT bought
  */
  event Buy(uint256 indexed offerId, uint256 indexed proposalId, uint256 value, uint256 fee);

  /**
  * @notice constructor
  * @dev The constructor set the block.timestamp as lastTimeStamp for be used by Chainlink keepers functions
  * @param _offerURI: IPFS offer URI to store offers metadata
  * @param _proposalURI: IPFS proposal URI to store proposals metadata
  * @param _fee: fee value
  * @param _marketplaceAddress: NFT marketplace address
  * @param _interval: Keepers interval in seconds
  */
  constructor(
    string memory _offerURI,
    string memory _proposalURI,
    uint256 _fee,
    address _marketplaceAddress,
    uint256 _interval
  ) {
    offerURI = _offerURI;
    proposalURI = _proposalURI;
    fee = _fee;
    marketplaceContract = IMarketplace(_marketplaceAddress);
    interval = _interval;
    lastTimeStamp = block.timestamp;
  }

  /**
  * @notice offer
  * @dev function to create new offer
  * @dev emit NewOffer event
  * @param _offerCID: IPFS CID hash for get offer metadata
  * @param _amount: max amount that msg.sender wanna pay
  * @return true
  */
  function offer(
    string memory _offerCID,
    uint256 _amount
  ) public returns(bool) {
    uint256 offerId = offerIdCounter + 1;
    offers[offerId] = Offer(_offerCID, msg.sender, _amount, 0, true);
    offerIdCounter = offerId;
    emit NewOffer(offerId, _offerCID, msg.sender, _amount);
    return true;
  }

  /**
  * @notice proposal
  * @dev function to create new offer
  * @dev the offer needs to be active
  * @dev emit NewProposal event
  * @param _offerId: offer id
  * @param _proposalCID: IPFS CID hash for get proposal metadata
  * @param _collection: nft collection address
  * @param _tokenId: nft token Id
  * @return true
  */
  function proposal(
    uint256 _offerId,
    string memory _proposalCID,
    address _collection,
    uint256 _tokenId
  ) public returns(bool) {
    require(offers[_offerId].isActive, "Semo: offer is not active");
    require(marketplaceContract.getItemStatus(_collection, _tokenId), "Semo: NFT not listed");
    uint256 proposalId = proposalIdCounter + 1;
    proposals[_offerId][proposalId] = Proposal(_proposalCID, msg.sender, _collection, _tokenId, true);
    proposalIdCounter = proposalId;
    offers[_offerId].offerProposalCount += 1;
    emit NewProposal(_offerId, proposalId, _proposalCID, _collection, _tokenId);
    return true;
  }

  /**
  * @notice acceptProposal
  * @dev function to accept one proposal
  * @dev the NFT of proposal needs to be listed by marketplace
  * @dev emit Buy event
  * @param _offerId: offer id
  * @param _proposalId: proposal id
  * @return true
  */
  function acceptProposal(
    uint256 _offerId, 
    uint256 _proposalId
  ) public payable returns(bool) {
    Proposal memory acceptedProposal = proposals[_offerId][_proposalId];
    require(acceptedProposal.isListed, "Semo: proposal is not listed");
    (uint256 nftValue, uint256 feeValue) = getPrice(_offerId, _proposalId);
    require(msg.value == nftValue + feeValue, "Semo: incorrect msg.value");
    offers[_offerId].isActive = false;
    marketplaceContract.buy{value: nftValue}(acceptedProposal.collection, acceptedProposal.tokenId);
    payable(acceptedProposal.curatorAddress).transfer(feeValue);
    IERC721 nftContract = IERC721(acceptedProposal.collection);
    nftContract.safeTransferFrom(address(this), msg.sender, acceptedProposal.tokenId);
    emit Buy(_offerId, _proposalId, nftValue, feeValue);
    return true;
  }

  /**
  * @notice getPrice
  * @dev view function to get item price and fee value
  * @param _offerId: offer id
  * @param _proposalId: proposal id
  * @return uint256 uint256
  */
  function getPrice(uint256 _offerId, uint256 _proposalId) public view returns(uint256, uint256) {
    Proposal memory item = proposals[_offerId][_proposalId];
    uint256 nftValue = marketplaceContract.getItemPrice(item.collection, item.tokenId);
    uint256 feeValue = nftValue * fee / 100;
    return (nftValue, feeValue);
  }

  /**
  * @notice checkUpkeep
  * @dev view function to check upkeeper interval
  */
  function checkUpkeep(
    bytes calldata /* checkData */
  ) external view returns (bool upkeepNeeded, bytes memory performData) {
    upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    return (upkeepNeeded, '');
  }

  /**
  * @notice performUpkeep
  * @dev function to perform upkeeper task
  * @dev this function checks listing status of proposals NFTs in marketplace
  * @dev if NFT it is not listed anymore, isListed status of proposal is automatically set to false
  */
  function performUpkeep(
    bytes calldata /* performData */
  ) external {
    if ((block.timestamp - lastTimeStamp) > interval ) {
      for (uint256 i = 0; i < offerIdCounter; i++) {
        if(offers[i].isActive) {
          for (uint256 j = 0; j < offers[i].offerProposalCount; j++) {
            if(proposals[i][j].isListed) {
              bool itemStatus = marketplaceContract.getItemStatus(proposals[i][j].collection, proposals[i][j].tokenId);
              if(!itemStatus) {
                proposals[i][j].isListed = false;
              }
            }
          }
        }
      }
    }
  }

  /**
  * @notice setFee
  * @dev function to set fee value
  * @param _newFee: new fee value
  * @return true
  */
  function setFee(uint256 _newFee) public onlyOwner returns(bool) {
    fee = _newFee;
    return true;
  }

  /**
  * @notice setURIs
  * @dev function to set fee value
  * @param _newOfferURI: new IPFS offer URI to store offers metadata
  * @param _newProposalURI: new IPFS proposal URI to store proposals metadata
  * @return true
  */
  function setURIs(
    string memory _newOfferURI,
    string memory _newProposalURI
  ) public onlyOwner returns(bool) {
    offerURI = _newOfferURI;
    proposalURI = _newProposalURI;
    return true;
  }
}