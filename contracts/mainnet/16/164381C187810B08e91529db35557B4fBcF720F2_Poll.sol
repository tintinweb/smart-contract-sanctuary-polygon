/**
 *Submitted for verification at polygonscan.com on 2022-06-11
*/

/* File: @openzeppelin/contracts/utils/Context.sol */

/* SPDX-License-Identifier: MIT */
/* OpenZeppelin Contracts v4.4.1 (utils/Context.sol) */

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

/* File: @openzeppelin/contracts/access/Ownable.sol */

/* OpenZeppelin Contracts v4.4.1 (access/Ownable.sol) */

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

/* File: contracts/interfaces/IPoll.sol */
pragma solidity >=0.8.0 <0.9.0;

interface IPoll {
  function getVoteTopic() external view returns (string memory, string memory, string[] memory);
  function totalVotesFor(uint8 __) external view returns (uint256);
  function vote(address _address, uint8 decision) external;
  function canVote(address _address) external view returns (bool);
}

/* File: contracts/interfaces/IGameManager.sol */
pragma solidity >=0.8.0 <0.9.0;

interface IGameManager {
  struct AttributeData {
    uint256 speed; /* CLNY earning speed */
    uint256 earned;
    uint8 baseStation; /* 0 or 1 */
    uint8 transport; /* 0 or 1, 2, 3 (levels) */
    uint8 robotAssembly; /* 0 or 1, 2, 3 (levels) */
    uint8 powerProduction; /* 0 or 1, 2, 3 (levels) */
  }

  function MCAddress() external view returns (address);

  function getAttributesMany(uint256[] calldata tokenIds) external view returns (AttributeData[] memory);
}

/* File: contracts/GameConnection.sol */
pragma solidity >=0.8.0 <0.9.0;


abstract contract GameConnection {
  address public GameManager;
  address public DAO;

  uint256[50] private ______gc_gap;

  function __GameConnection_init(address _DAO) internal {
    require (DAO == address(0));
    DAO = _DAO;
  }

  modifier onlyDAO {
    require(msg.sender == DAO, 'Only DAO');
    _;
  }

  modifier onlyGameManager {
    require(msg.sender == GameManager, 'Only GameManager');
    _;
  }

  function setGameManager(address _GameManager) external onlyDAO {
    GameManager = _GameManager;
  }

  function transferDAO(address _DAO) external onlyDAO {
    DAO = _DAO;
  }
}

/* File: @openzeppelin/contracts/utils/introspection/IERC165.sol */
/* OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol) */

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

/* File: @openzeppelin/contracts/token/ERC721/IERC721.sol */
/* OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol) */

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

/* File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol */

/* OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol) */

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

/* File: contracts/Poll.sol */

pragma solidity >=0.8.0 <0.9.0;


contract Poll is IPoll, Ownable, GameConnection {
  mapping (uint256 => bool) public tokenVoted;

  bool public started = false;
  uint256 public voteCount = 0;

  string public caption;
  string public description;
  string[] public items;

  mapping (uint256 => uint256) private votedFor;
  mapping (uint256 => uint256) private totalVotesFor_;

  struct VotePair {
    uint256 voteCount;
    string option;
  }

  event Vote (address indexed voter, uint256 decision);

  function totalVotesFor(uint8 option) external view returns (uint256) {
    return totalVotesFor_[uint256(option)];
  }

  constructor (address _DAO, string memory _caption, string memory _description, string[] memory _items) {
    description = _description;
    caption = _caption;
    items = _items;
    GameConnection.__GameConnection_init(_DAO);
  }

  function getResults(uint256 option) external view returns (VotePair memory result) {
    result.option = items[option];
    result.voteCount = totalVotesFor_[option];
  }

  function getMC() private view returns (address) {
    return IGameManager(GameManager).MCAddress();
  }

  function getVoteTopic() external view override returns (string memory, string memory, string[] memory) {
    return (description, caption, items);
  }

  function canVote(address _address) external view override returns (bool) {
    if (!started) {
      return false;
    }
    IERC721Enumerable MC = IERC721Enumerable(getMC());
    uint256 tokenCount = MC.balanceOf(_address);
    if (tokenCount == 0) {
      return false;
    }
    for (uint256 i = 0; i < tokenCount; i++) {
      if (!tokenVoted[MC.tokenOfOwnerByIndex(_address, i)]) {
        return true;
      }
    }
    return false;
  }
  
  function vote(address _address, uint8 decision) external override onlyGameManager {
    require (started, 'not started');
    IERC721Enumerable MC = IERC721Enumerable(getMC());
    uint256 tokenCount = MC.balanceOf(_address);
    require (tokenCount > 0, 'you cannot vote');
    for (uint256 i = 0; i < tokenCount; i++) {
      uint256 tokenId = MC.tokenOfOwnerByIndex(_address, i);
      if (!tokenVoted[tokenId]) {
        votedFor[tokenId] = uint256(decision);
        totalVotesFor_[uint256(decision)]++;
        voteCount++;
        tokenVoted[tokenId] = true;
      }
    }
    emit Vote(_address, uint256(decision));
  }

  function start() external onlyOwner {
    require (!started, 'already started');
    started = true;
  }
}