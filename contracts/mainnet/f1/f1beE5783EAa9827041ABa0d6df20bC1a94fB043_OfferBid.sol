// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface NFTContract is IERC721 {
  function getTokenInfo(uint256 _tokenId) external view returns (uint256, uint256);
}

contract OfferBid is Ownable, Pausable {

  event OfferCreated(
    uint offerId,
    uint tokenId,
    address offererAddress,
    uint ttl,
    address ownerAddress,
    uint offerAmount,
    uint amountOwnerWillGet,
    uint regularTaxAmount,
    uint influencerTaxAmount,
    address influencerAddress,
    uint createdAt
  );
  event OfferRefunded(
    uint offerId,
    uint tokenId,
    address offererAddress,
    uint ttl,
    address ownerAddress,
    uint offerAmount,
    uint amountOwnerWillGet,
    uint regularTaxAmount,
    uint influencerTaxAmount,
    address influencerAddress,
    uint createdAt
  );
  event OfferOverwritten(
    uint offerId,
    uint tokenId,
    address offererAddress,
    uint ttl,
    address ownerAddress,
    uint offerAmount,
    uint amountOwnerWillGet,
    uint regularTaxAmount,
    uint influencerTaxAmount,
    address influencerAddress,
    uint createdAt
  );
  event OfferAccepted(
    uint offerId,
    uint tokenId,
    address offererAddress,
    uint ttl,
    address ownerAddress,
    uint offerAmount,
    uint amountOwnerWillGet,
    uint regularTaxAmount,
    uint influencerTaxAmount,
    address influencerAddress,
    uint createdAt
  );

  struct Offer {
    uint tokenId;
    address offererAddress;
    address ownerAddress;
    uint ttl;
    uint offerAmount;
    uint amountOwnerWillGet;
    uint regularTaxAmount;
    uint influencerTaxAmount;
    address influencerAddress;
    uint createdAt;
  }

  struct TokenOffersCollection {
    uint[] offerIndices;
    uint highestBid;
  }

  struct InfluencerPair {
    uint influencerId;
    address influencerAddress;
  }

  NFTContract public nftContract;
  IERC20 public currencyTokenContract;
  address public feesRecipient; 
  mapping(uint => address) public influencers;
  uint16 public influencerTaxPermille;
  uint16 public regularTaxPermille;
  uint public minInitialBidAmount;

  uint public minTtl;
  uint public maxTtl;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdTracker;
  mapping(uint => Offer) public offers;

  mapping(address => mapping(address => mapping(uint => uint))) public offerIdByTokenIdByOffererByOwner;
  mapping(uint => mapping(address => TokenOffersCollection)) public tokenOffersCollectionsByOwnerByTokenId;

  function getTokenOfferIds(uint tokenId, address ownerAddress) public view returns(uint[] memory) {
    return tokenOffersCollectionsByOwnerByTokenId[tokenId][ownerAddress].offerIndices;
  }

  constructor(
    address _nftAddress, 
    address _currencyTokenAddress, 
    address _feesRecipient, 
    uint16 _influencerTaxPermille, 
    uint16 _regularTaxPermille,
    uint _minTtl,
    uint _maxTtl
  ) {
    nftContract = NFTContract(_nftAddress);
    currencyTokenContract = IERC20(_currencyTokenAddress);
    setFeesRecipient(_feesRecipient);
    setInfluencerTaxPermille(_influencerTaxPermille);
    setRegularTaxPermille(_regularTaxPermille);
    setTtlLimits(_minTtl, _maxTtl);
    setMinInitialBidAmount(100 * 10 ** 18);
    // item with id 0 will allways be empty
    _tokenIdTracker.increment();
  }

  function setFeesRecipient(address _feesRecipient) public onlyOwner {
    feesRecipient = _feesRecipient;
  }

  function setMinInitialBidAmount(uint _minInitialBidAmount) public onlyOwner {
    minInitialBidAmount = _minInitialBidAmount;
  }

  function setInfluencer(uint tokenId, address influencer) public onlyOwner {
    influencers[tokenId] = influencer;
  }

  function setInfluencers(InfluencerPair[] memory influencerPairs) public onlyOwner {
    for(uint i = 0; i < influencerPairs.length; i ++) {
        influencers[influencerPairs[i].influencerId] = influencerPairs[i].influencerAddress;
    }
  }

  function setInfluencerTaxPermille(uint16 _influencerTaxPermille) public onlyOwner {
    influencerTaxPermille = _influencerTaxPermille;
  }

  function setRegularTaxPermille(uint16 _regularTaxPermille) public onlyOwner {
    regularTaxPermille = _regularTaxPermille;
  }

  function setTtlLimits(uint _minTtl, uint _maxTtl) public onlyOwner {
    minTtl = _minTtl;
    maxTtl = _maxTtl;
  }

  function _offerExists(uint tokenId, address offererAddress, address ownerAddress) internal view returns(bool) {
    return offerIdByTokenIdByOffererByOwner[ownerAddress][offererAddress][tokenId] != 0 && offers[offerIdByTokenIdByOffererByOwner[ownerAddress][offererAddress][tokenId]].offerAmount > 0;
  }

  function createOffer(uint tokenId, uint offerAmount, uint ttl) public whenNotPaused {
    // get ownerAddress
    address ownerAddress = nftContract.ownerOf(tokenId);

    require(offerAmount >= minInitialBidAmount, "Offer amount too low");

    require(ownerAddress != msg.sender, "Can't make offer on an item you own");
    require(ttl >= minTtl && ttl <= maxTtl, "Time to live is out of bounds");

    uint regularTaxAmount = (offerAmount * regularTaxPermille) / 1000;
    uint influencerTaxAmount = 0;
    address influencerAddress = address(0);

    (uint256 tokenTypeNumber,) = nftContract.getTokenInfo(tokenId);
    bool isInfluencerCard = tokenTypeNumber / 1000 == 3;
    if(isInfluencerCard) {
      uint influencerId = tokenTypeNumber % 1000;
      if(influencers[influencerId] != address(0)) {
        influencerTaxAmount = (offerAmount * influencerTaxPermille) / 1000;
        influencerAddress = influencers[influencerId];
      }
    }

    uint amountOwnerWillGet = offerAmount - regularTaxAmount - influencerTaxAmount;
    uint amountToTransferFromOfferer = offerAmount;

    // check higher than previous bids
    require(
      tokenOffersCollectionsByOwnerByTokenId[tokenId][ownerAddress].highestBid + 
      (tokenOffersCollectionsByOwnerByTokenId[tokenId][ownerAddress].highestBid / 100)  <= offerAmount, "Offer amount is lower than previous offers");

    if(_offerExists(tokenId, msg.sender, ownerAddress)) {
      uint previousOfferId = offerIdByTokenIdByOffererByOwner[ownerAddress][msg.sender][tokenId];
      Offer storage previousOffer = offers[previousOfferId];

      amountToTransferFromOfferer -= previousOffer.offerAmount;
      _removeOffer(tokenId, msg.sender, ownerAddress, false);

      emit OfferOverwritten(
        previousOfferId,
        previousOffer.tokenId,
        previousOffer.offererAddress,
        previousOffer.ttl,
        previousOffer.ownerAddress,
        previousOffer.offerAmount,
        previousOffer.amountOwnerWillGet,
        previousOffer.regularTaxAmount,
        previousOffer.influencerTaxAmount,
        previousOffer.influencerAddress,
        previousOffer.createdAt
      );
    }

    // check has enough balance
    require(amountToTransferFromOfferer <= currencyTokenContract.balanceOf(msg.sender), "Balance not high enough");

    // check allowance
    require(amountToTransferFromOfferer <= currencyTokenContract.allowance(msg.sender, address(this)), "Allowance not high enough");

    currencyTokenContract.transferFrom(msg.sender, address(this), amountToTransferFromOfferer);

    uint offerId = _tokenIdTracker.current();
    _tokenIdTracker.increment();

    offers[offerId] = Offer({
        tokenId: tokenId, 
        offererAddress: msg.sender, 
        ownerAddress: ownerAddress, 
        ttl: ttl, 
        offerAmount: offerAmount, 
        amountOwnerWillGet: amountOwnerWillGet,
        regularTaxAmount: regularTaxAmount,
        influencerTaxAmount: influencerTaxAmount,
        influencerAddress: influencerAddress,
        createdAt: block.timestamp
    });

    tokenOffersCollectionsByOwnerByTokenId[tokenId][ownerAddress].offerIndices.push(offerId);
    offerIdByTokenIdByOffererByOwner[ownerAddress][msg.sender][tokenId] = offerId;
    tokenOffersCollectionsByOwnerByTokenId[tokenId][ownerAddress].highestBid = offerAmount;

    emit OfferCreated(
      offerId,
      offers[offerId].tokenId,
      offers[offerId].offererAddress,
      offers[offerId].ttl,
      offers[offerId].ownerAddress,
      offers[offerId].offerAmount,
      offers[offerId].amountOwnerWillGet,
      offers[offerId].regularTaxAmount,
      offers[offerId].influencerTaxAmount,
      offers[offerId].influencerAddress,
      offers[offerId].createdAt
    );
  }

  function acceptOffer(uint tokenId, address offererAddress) public whenNotPaused {
    require(offerIdByTokenIdByOffererByOwner[msg.sender][offererAddress][tokenId] > 0, "Offer not found");

    Offer storage offer = offers[offerIdByTokenIdByOffererByOwner[msg.sender][offererAddress][tokenId]];

    require(offer.createdAt + offer.ttl >= block.timestamp, "Offer expired");

    address ownerAddress = nftContract.ownerOf(tokenId);

    require(ownerAddress == msg.sender, "Token doesn't belong to you");
    require(nftContract.getApproved(tokenId) == address(this), "Token not approved for this contract");

    if(offer.influencerAddress != address(0) && offer.influencerTaxAmount > 0) {
        currencyTokenContract.transfer(offer.influencerAddress, offer.influencerTaxAmount);
    }

    currencyTokenContract.transfer(ownerAddress, offer.amountOwnerWillGet);
    currencyTokenContract.transfer(feesRecipient, offer.regularTaxAmount);
    nftContract.safeTransferFrom(ownerAddress, offererAddress, tokenId);

    emit OfferAccepted(
      offerIdByTokenIdByOffererByOwner[msg.sender][offererAddress][tokenId],
      tokenId,
      offererAddress,
      offer.ttl,
      ownerAddress,
      offer.offerAmount,
      offer.amountOwnerWillGet,
      offer.regularTaxAmount,
      offer.influencerTaxAmount,
      offer.influencerAddress,
      offer.createdAt
    ); 

    _removeOffer(tokenId, offererAddress, ownerAddress, false);
  }

  function cancelOffer(uint tokenId, address ownerAddress) public {
    require(_offerExists(tokenId, msg.sender, ownerAddress), "Offer not found");
    _removeOffer(tokenId, msg.sender, ownerAddress, true);
  }

  function removeOffers(uint tokenId, address ownerAddress) public onlyOwner {
    _removeOffersForToken(tokenId, ownerAddress);
  }

  function removeExpiredOffers(uint[] memory offerIds) public onlyOwner {
    for(uint i; i < offerIds.length; i++) {
      Offer storage offer = offers[offerIds[i]];
      if(offer.offererAddress != address(0) && offer.createdAt + offer.ttl < block.timestamp) {
        _removeOffer(offer.tokenId, offer.offererAddress, offer.ownerAddress, true);
      }
    }
  }

  function _removeOffersForToken(uint tokenId, address ownerAddress) internal {
    TokenOffersCollection storage tokenOffersCollection = tokenOffersCollectionsByOwnerByTokenId[tokenId][ownerAddress];
  
    for(uint i = 0; i < tokenOffersCollection.offerIndices.length; i++) {
      Offer storage offer = offers[tokenOffersCollection.offerIndices[i]];
      currencyTokenContract.transfer(offer.offererAddress, offer.offerAmount);
      
      offerIdByTokenIdByOffererByOwner[ownerAddress][offer.offererAddress][tokenId] = 0;

      emit OfferRefunded(
        tokenOffersCollection.offerIndices[i],
        tokenId,
        offer.offererAddress,
        offer.ttl,
        ownerAddress,
        offer.offerAmount,
        offer.amountOwnerWillGet,
        offer.regularTaxAmount,
        offer.influencerTaxAmount,
        offer.influencerAddress,
        offer.createdAt
      ); 

      delete offers[tokenOffersCollection.offerIndices[i]];
    }

    uint256[] memory newIndices;
    tokenOffersCollectionsByOwnerByTokenId[tokenId][ownerAddress] = TokenOffersCollection(newIndices, 0);
  }

  function _removeOffer(uint tokenId, address offererAddress, address ownerAddress, bool sendTokensBack) internal {
    if(!_offerExists(tokenId, offererAddress, ownerAddress)) {
      return;
    }

    uint offerId = offerIdByTokenIdByOffererByOwner[ownerAddress][offererAddress][tokenId];

    Offer storage offer = offers[offerId];

    TokenOffersCollection storage tokenOffersCollection = tokenOffersCollectionsByOwnerByTokenId[tokenId][ownerAddress];
    for(uint i; i < tokenOffersCollection.offerIndices.length; i++) {
      if(tokenOffersCollection.offerIndices[i] == offerId) {
        tokenOffersCollection.offerIndices[i] = tokenOffersCollection.offerIndices[tokenOffersCollection.offerIndices.length - 1];
        tokenOffersCollection.offerIndices.pop();
        break;
      }
    }

    // find a new highest bid value
    if(tokenOffersCollection.highestBid == offer.offerAmount) {
      uint highestBid = 0;
      for(uint i; i < tokenOffersCollection.offerIndices.length; i++) {
        if(offers[tokenOffersCollection.offerIndices[i]].offerAmount > highestBid) {
          highestBid = offers[tokenOffersCollection.offerIndices[i]].offerAmount;
        }
      }

      tokenOffersCollection.highestBid = highestBid;
    }

    offerIdByTokenIdByOffererByOwner[offer.ownerAddress][offererAddress][tokenId] = 0;

    uint offerAmount = offer.offerAmount;

    if(sendTokensBack) {
      emit OfferRefunded(
        offerId,
        tokenId,
        offererAddress,
        offer.ttl,
        ownerAddress,
        offer.offerAmount,
        offer.amountOwnerWillGet,
        offer.regularTaxAmount,
        offer.influencerTaxAmount,
        offer.influencerAddress,
        offer.createdAt
      );

      currencyTokenContract.transfer(offererAddress, offerAmount);
    }

    delete offers[offerId];
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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