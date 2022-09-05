// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract Sale is ERC721Holder, Ownable {
  event CancelSellToken(uint256 indexed tokenId);
  event SetReceiver(address indexed receiver);
  event SetNftOwner(address indexed nftOwner);
  event UpdatePrice(uint256 indexed tokenId, uint256 indexed price);
  event UpdatePriceBatch(uint256[] tokenId, uint256[] price);
  event UpdateReferrer(uint256 indexed tokenId, address indexed referrer, uint256 indexed referrerPercentage);
  event UpdateReferrerBatch(uint256[] tokenId, address indexed referrer, uint256 indexed referrerPercentage);
  event Buy(address indexed from, address indexed to, uint256 indexed tokenId, uint256 price);

  struct AskEntry {
      uint256 tokenId;
      uint256 price;
      address referrer;
      uint256 referrerPercentage;
      bool exist;
  }

  IERC721 public nft;

  mapping(uint256 => mapping(uint256 => AskEntry)) private asks;
  uint256[] public tokenIds;
  address payable public receiver;
  address nftOwner;
  uint256 public _period = 1;

  constructor(address _nft, address yieldWallet) {
    require(_nft != address(0) && _nft != address(this), "Sale: invalid address");
    nft = IERC721(_nft);
    receiver = payable(yieldWallet);
    nftOwner = _msgSender();
  }

  function setAsk(uint256 _tokenId, uint256 _price) internal {
    AskEntry storage askEntry = asks[_period][_tokenId];

    askEntry.tokenId = _tokenId;
    askEntry.price = _price;
    askEntry.exist = true;

    tokenIds.push(_tokenId);
  }

  function addNewToken(uint256 _tokenId, uint256 _price) external onlyOwner {
    require(_price >= 0, 'Sale: price must be a positive value');

    if(!asks[_period][_tokenId].exist){
      setAsk(_tokenId, _price);
    }
  }

  function addNewTokenBatch(
    uint256[] memory _tokenIds,
    uint256[] memory _price,
    uint256[] memory _priceInBNB
  ) external onlyOwner {
    require(_tokenIds.length == _price.length && _tokenIds.length == _priceInBNB.length, "Sale: ids and price length mismatch");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      if(!asks[_period][_tokenIds[i]].exist){
        setAsk(_tokenIds[i], _price[i]);
      }
    }
  }

  function updateTokenPrice(uint256 _tokenId, uint256 _price) external onlyOwner {
    require(_price > 0, 'Sale: price must be granter than zero');
    AskEntry storage askEntry = asks[_period][_tokenId];
    askEntry.price = _price;
    emit UpdatePrice(_tokenId,_price);
  }

  function updateTokenPriceBatch(
    uint256[] memory _tokenIds,
    uint256[] memory _price
  ) external onlyOwner {
    require(_tokenIds.length == _price.length, "Sale: price length mismatch");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      AskEntry storage askEntry = asks[_period][_tokenIds[i]];
      askEntry.price = _price[i];
    }
    emit UpdatePriceBatch(_tokenIds,_price);
  }

  function updateReferrer(uint256 _tokenId, address _referrer, uint256 _referrerPercentage) external onlyOwner {
    AskEntry storage askEntry = asks[_period][_tokenId];
    askEntry.referrer = _referrer;
    askEntry.referrerPercentage = _referrerPercentage;
    emit UpdateReferrer(_tokenId, _referrer, _referrerPercentage);
  }

  function updateReferrerBatch(
    uint256[] memory _tokenIds,
    address _referrer,
    uint256 _referrerPercentage
  ) external onlyOwner{
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      AskEntry storage askEntry = asks[_period][_tokenIds[i]];
      askEntry.referrer = _referrer;
      askEntry.referrerPercentage = _referrerPercentage;
    }
    emit UpdateReferrerBatch(_tokenIds, _referrer, _referrerPercentage);
  }

  function cancelSellToken(uint256 _tokenId) external onlyOwner {
    AskEntry storage askEntry = asks[_period][_tokenId];
    require(askEntry.exist, 'Sale: not in sell book');
    askEntry.exist = false;
    emit CancelSellToken(_tokenId);
  }

  function cancelAll() external onlyOwner{
    _period += 1;
  }

  function getAsks(uint256 _tokenId) external view returns(uint256, uint256, bool, address, uint256) {
    return (
      asks[_period][_tokenId].tokenId,
      asks[_period][_tokenId].price,
      asks[_period][_tokenId].exist,
      asks[_period][_tokenId].referrer,
      asks[_period][_tokenId].referrerPercentage
    );
  }

  function setReceiver(address _address) external onlyOwner{
    require(_address != address(0) && _address != address(this), 'Sale: wrong receiver');
    receiver = payable(_address);
    emit SetReceiver(_address);
  }

  function setNftOwner(address _address) external onlyOwner{
    require(_address != address(0) && _address != address(this), 'Sale: wrong nft owner');
    nftOwner = _address;
    emit SetNftOwner(_address);
  }

  function buyToken(uint256 _tokenId) public payable {
    require(msg.sender != address(0) && msg.sender != address(this), 'Sale: wrong sender');

    address owner = nft.ownerOf(_tokenId);
    require(nftOwner == owner, "Sale: token already sold");
    AskEntry storage askEntry = asks[_period][_tokenId];
    require(askEntry.exist, "Sale: token not in sale");
    require(msg.value == askEntry.price, 'Sale: balance too low');

    askEntry.exist = false;

    uint256 refRewards;

    if(askEntry.referrerPercentage > 0 && askEntry.referrer != address(0)){
      refRewards = (askEntry.price * askEntry.referrerPercentage) / 10000;
      (bool sentReward, ) = payable(askEntry.referrer).call{value: refRewards}("");
      require(sentReward, "Sale: failed to send referrer reward");
    }

    (bool sent, ) = payable(receiver).call{value: askEntry.price - refRewards}("");
    require(sent, "Failed to send");

    nft.safeTransferFrom(nftOwner, msg.sender, askEntry.tokenId);
    emit Buy(nftOwner, msg.sender, askEntry.tokenId, askEntry.price);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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