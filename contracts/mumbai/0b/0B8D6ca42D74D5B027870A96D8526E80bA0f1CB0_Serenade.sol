// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Account/IAccount.sol";
import "./Account/IAccountFactory.sol";
import "./Royalty/IRoyaltySplitter.sol";

contract Serenade is Ownable {

  // ============ Storage ============

  //account
  IAccountFactory private _accounts;

  //mapping of account id to type
  mapping(uint256 => string) public typeOf;

  // ============ Deploy ============

  /**
   * @dev Sets owner
   */
  constructor(IAccountFactory accounts, address owner) {
    _accounts = accounts;
    _transferOwnership(owner);
  }

  // ============ Account Read Methods ============

  /**
   * Returns an account contract address
   */
  function accountAddress(uint256 accountId) 
    public view virtual returns(address) 
  {
    return _accounts.accountAddress(accountId);
  }

  // ============ Product Read Methods ============

  /**
   * @dev Returns true if product exists
   */
  function productExists(uint256 accountId, uint256 productId) 
    public virtual view returns(bool) 
  {
    address account = accountAddress(accountId);
    return IAccount(account).productExists(productId);
  }

  /**
   * @dev Returns the token URI by using the base uri and index
   */
  function tokenURI(uint256 accountId, uint256 tokenId) 
    public virtual view returns(string memory) 
  {
    address account = accountAddress(accountId);
    return IAccount(account).tokenURI(tokenId);
  }

  // ============ Royalty Read Methods ============

  /**
   * Returns a royalty splitter contract address
   */
  function royaltyAddress(uint256 accountId, uint256 productId) 
    public virtual view returns(address)
  {
    address account = accountAddress(accountId);
    return IAccount(account).royaltyAddress(productId);
  }

  /** 
   * @dev Returns the royalty percent of `productId`
   */
  function royaltyPercent(uint256 accountId, uint256 productId) 
    public virtual view returns(uint16)
  {
    address account = accountAddress(accountId);
    return IAccount(account).royaltyPercent(productId);
  }

  /**
   * @dev Getter for the address of the payee number `index`.
   */
  function royaltyRecipient(
    uint256 accountId, 
    uint256 productId, 
    uint256 index
  ) public virtual view returns(address) {
    IAccount account = IAccount(
      accountAddress(accountId)
    );
    IRoyaltySplitter royalty = IRoyaltySplitter(
      account.royaltyAddress(productId)
    );

    return royalty.recipient(index);
  }

  /**
   * @dev Getter for the amount of shares held by an account.
   */
  function royaltyShares(
    uint256 accountId, 
    uint256 productId,
    address recipient
  ) public virtual view returns(uint256) {
    IAccount account = IAccount(
      accountAddress(accountId)
    );
    IRoyaltySplitter royalty = IRoyaltySplitter(
      account.royaltyAddress(productId)
    );

    return royalty.shares(recipient);
  }

  /**
   * @dev Getter for the total amount of Ether already released.
   */
  function royaltyTotalReleased(uint256 accountId, uint256 productId) 
    public virtual view returns(uint256)
  {
    IAccount account = IAccount(
      accountAddress(accountId)
    );
    IRoyaltySplitter royalty = IRoyaltySplitter(
      account.royaltyAddress(productId)
    );

    return royalty.totalReleased();
  }

  /**
   * @dev Getter for the total amount of `token` already released. 
   * `token` should be the address of an IERC20 contract.
   */
  function royaltyTotalReleased(
    uint256 accountId, 
    uint256 productId, 
    IERC20 token
  ) public virtual view returns(uint256) {
    IAccount account = IAccount(
      accountAddress(accountId)
    );
    IRoyaltySplitter royalty = IRoyaltySplitter(
      account.royaltyAddress(productId)
    );

    return royalty.totalReleased(token);
  }

  /**
   * @dev Getter for the total shares held by recipients.
   */
  function royaltyTotalShares(uint256 accountId, uint256 productId) 
    public virtual view returns(uint256)
  {
    IAccount account = IAccount(
      accountAddress(accountId)
    );
    IRoyaltySplitter royalty = IRoyaltySplitter(
      account.royaltyAddress(productId)
    );

    return royalty.totalShares();
  }

  // ============ Account Write Methods ============

  /**
   * Creates an account
   */
  function addAccount(
    uint256 accountId, 
    string memory accountType, 
    IAccount account
  ) public virtual onlyOwner {
    //make new contract
    _accounts.addAccount(accountId, account);
    //add type
    typeOf[accountId] = accountType;
  }

  /**
   * Creates an account
   */
  function createAccount(
    uint256 accountId,
    string memory accountType, 
    string memory name, 
    string memory symbol, 
    string memory uri
  ) public virtual onlyOwner {
    _accounts.createAccount(accountId, name, symbol, uri);
    //add type
    typeOf[accountId] = accountType;
  }

  // ============ Product Write Methods ============

  /**
   * @dev Allows admin to mint a token for someone
   */
  function mint(
    uint256 accountId, 
    uint256 productId, 
    uint256 tokenId, 
    address recipient
  ) public virtual onlyOwner {
    _getAccount(accountId).mint(productId, tokenId, recipient);
  }

  /**
   * @dev Sets a fixed `uri` and max supply `size` for a `productId`
   *      Will not add `uri` if empty string. Use `setProductURI` instead
   *      Will not add `size` if zero. Use `setProductSize` instead
   */
  function setProduct(
    uint256 accountId, 
    uint256 productId, 
    uint256 size, 
    string memory uri
  ) public virtual onlyOwner {
    _getAccount(accountId).setProduct(productId, size, uri);
  }

  /**
   * @dev Sets a max supply `size` for a `productId`
   */
  function setProductSize(
    uint256 accountId, 
    uint256 productId, 
    uint256 size
  ) public virtual onlyOwner {
    _getAccount(accountId).setProductSize(productId, size);
  }

  /**
   * @dev Sets a fixed `uri` for a `productId`
   */
  function setProductURI(
    uint256 accountId, 
    uint256 productId, 
    string memory uri
  ) public virtual onlyOwner {
    _getAccount(accountId).setProductURI(productId, uri);
  }

  // ============ Royalty Write Methods ============

  /**
   * @dev Adds a royalty splitter
   */
  function addRoyalty(
    uint256 accountId, 
    uint256 productId, 
    uint16 percent, 
    IRoyaltySplitter royalty
  ) public virtual onlyOwner {
    _getAccount(accountId).addRoyalty(productId, percent, royalty);
  }

  /**
   * @dev Creates a royalty splitter
   */
  function createRoyalty(
    uint256 accountId, 
    uint256 productId,
    uint16 percent,
    address[] memory payees,
    uint256[] memory shares
  ) public virtual onlyOwner {
    _getAccount(accountId).createRoyalty(
      productId, 
      percent, 
      payees, 
      shares 
    );
  }

  /**
   * @dev Considers tokens that can be vaulted
   */
  function royaltyAcceptToken(
    uint256 accountId, 
    uint256 productId, 
    IERC20 token
  ) public virtual onlyOwner {
    _getRoyalty(accountId, productId).accept(token);
  }

  /**
   * @dev Add a new `account` to the contract.
   */
  function royalltyAddRecipient(
    uint256 accountId, 
    uint256 productId, 
    address recipient, 
    uint256 shares
  ) public virtual onlyOwner {
    _getRoyalty(accountId, productId).addRecipient(recipient, shares);
  }

  function royaltyBatchUpdate(
    uint256 accountId, 
    uint256 productId, 
    address[] memory recipients, 
    uint256[] memory shares
  ) public virtual onlyOwner {
    _getRoyalty(accountId, productId).batchUpdate(recipients, shares);
  }

  /**
   * @dev Removes a `recipient`
   */
  function royaltyRemoveRecipient(
    uint256 accountId, 
    uint256 productId, 
    uint256 index
  ) public virtual onlyOwner {
    _getRoyalty(accountId, productId).removeRecipient(index);
  }

  /**
   * @dev Update a `recipient`
   */
  function royaltyUpdateRecipient(
    uint256 accountId, 
    uint256 productId, 
    address recipient, 
    uint256 shares
  ) public virtual onlyOwner {
    _getRoyalty(accountId, productId).updateRecipient(recipient, shares);
  }

  // ============ Admin Write Methods ============

  /**
   * @dev Pauses all token transfers.
   */
  function pause(uint256 accountId) public virtual {
    _getAccount(accountId).pause();
  }

  /**
   * @dev Unpauses all token transfers.
   */
  function unpause(uint256 accountId) public virtual {
    _getAccount(accountId).unpause();
  }

  // ============ Internal Methods ============

  function _getAccount(uint256 accountId) 
    internal virtual returns(IAccount) 
  {
    return IAccount(accountAddress(accountId));
  }

  function _getRoyalty(uint256 accountId, uint256 productId) 
    internal virtual returns(IRoyaltySplitter) 
  {
    return IRoyaltySplitter(
      _getAccount(accountId).royaltyAddress(productId)
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "../Royalty/IRoyaltySplitter.sol";

interface IAccount is IERC721, IERC721Metadata {
  // ============ Read Methods ============

  /**
   * @dev Returns true if product exists
   */
  function productExists(uint256 productId) external view returns(bool);

  /**
   * Returns a royalty splitter contract address
   */
  function royaltyAddress(uint256 productId) external view returns(address);

  /**
   * @dev implements ERC2981 `royaltyInfo()`
   */
  function royaltyInfo(uint256 productId, uint256 salePrice) 
    external 
    view 
    returns(address receiver, uint256 royaltyAmount);

  /** 
   * @dev Returns the royalty percent of `productId`
   */
  function royaltyPercent(uint256 productId) 
    external view returns(uint16);

  // ============ Minting Methods ============

  /**
   * @dev Allows admin to mint a token for someone
   */
  function mint(
    uint256 productId, 
    uint256 tokenId, 
    address recipient
  ) external;

  // ============ Product Methods ============

  /**
   * @dev Sets a fixed `uri` and max supply `size` for a `productId`
   *      Will not add `uri` if empty string. Use `setProductURI` instead
   *      Will not add `size` if zero. Use `setProductSize` instead
   */
  function setProduct(
    uint256 productId, 
    uint256 size, 
    string memory uri
  ) external;

  /**
   * @dev Sets a max supply `size` for a `productId`
   */
  function setProductSize(uint256 productId, uint256 size) external;

  /**
   * @dev Sets a fixed `uri` for a `productId`
   */
  function setProductURI(uint256 productId, string memory uri) external;

  // ============ Royalty Methods ============

  /**
   * @dev Adds a royalty splitter
   */
  function addRoyalty(
    uint256 productId, 
    uint16 percent, 
    IRoyaltySplitter royalty
  ) external;

  /**
   * @dev Creates a royalty splitter
   */
  function createRoyalty(
    uint256 productId,
    uint16 percent,
    address[] memory payees,
    uint256[] memory shares
  ) external;

  // ============ Admin Methods ============

  /**
   * @dev Pauses all token transfers.
   */
  function pause() external;

  /**
   * @dev Unpauses all token transfers.
   */
  function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccount.sol";

interface IAccountFactory {
  // ============ Read Methods ============

  /**
   * Returns an account contract address
   */
  function accountAddress(uint256 accountId) 
    external view returns(address);

  // ============ Factory Methods ============

  /**
   * Creates an account
   */
  function createAccount(
    uint256 accountId,
    string memory name, 
    string memory symbol, 
    string memory uri
  ) external;

  /**
   * Creates an account
   */
  function addAccount(uint256 accountId, IAccount account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRoyaltySplitter {
  // ============ Events ============

  event RecipientAdded(address account, uint256 shares);
  event RecipientUpdated(address account, uint256 shares);
  event RecipientRemoved(address account);
  event RecipientsPurged();
  event PaymentReleased(address to, uint256 amount);
  event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  // ============ Read Methods ============

  /**
   * @dev Getter for the address of the payee number `index`.
   */
  function recipient(uint256 index) external view returns(address);

  /**
   * @dev Getter for the amount of Ether already released to a payee.
   */
  function released(address account) external view returns(uint256);

  /**
   * @dev Getter for the amount of `token` tokens already released to a 
   * payee. `token` should be the address of an IERC20 contract.
   */
  function released(IERC20 token, address account) 
    external view returns(uint256);

  /**
   * @dev Getter for the amount of shares held by an account.
   */
  function shares(address account) external view returns(uint256);

  /**
   * @dev Getter for the total amount of Ether already released.
   */
  function totalReleased() external view returns(uint256);

  /**
   * @dev Getter for the total amount of `token` already released. 
   * `token` should be the address of an IERC20 contract.
   */
  function totalReleased(IERC20 token) external view returns(uint256);

  /**
   * @dev Getter for the total shares held by recipients.
   */
  function totalShares() external view returns(uint256);

  // ============ Write Methods ============

  /**
   * @dev Triggers a transfer to `account` of the amount of Ether they 
   * are owed, according to their percentage of the total shares and 
   * their previous withdrawals.
   */
  function release(address payable account) 
    external;

  /**
   * @dev Triggers a transfer to `account` of the amount of `token` 
   * tokens they are owed, according to their percentage of the total 
   * shares and their previous withdrawals. `token` must be the address 
   * of an IERC20 contract.
   */
  function release(IERC20 token, address account) 
    external;

  // ============ Admin Methods ============

  /**
   * @dev Considers tokens that can be vaulted
   */
  function accept(IERC20 token) 
    external;

  /**
   * @dev Add a new `account` to the contract.
   */
  function addRecipient(address account, uint256 shares_) 
    external;

  function batchUpdate(
    address[] memory recipients_, 
    uint256[] memory shares_
  ) external;

  /**
   * @dev Removes a `recipient`
   */
  function removeRecipient(uint256 index) 
    external;

  /**
   * @dev Update a `recipient`
   */
  function updateRecipient(address account, uint256 shares_) 
    external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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