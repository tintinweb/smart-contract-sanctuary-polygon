// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//........................................................................................
//..####...######..#####...######..##..##...####...#####...######...........####....####..
//.##......##......##..##..##......###.##..##..##..##..##..##..............##..##..##..##.
//..####...####....#####...####....##.###..######..##..##..####............##......##..##.
//.....##..##......##..##..##......##..##..##..##..##..##..##........##....##..##..##..##.
//..####...######..##..##..######..##..##..##..##..#####...######....##.....####....####..
//........................................................................................
//
// Hello from Serenade!
//
// DIGITAL COLLECTIBLES MADE BY ROCKSTARS
// COLLECT YOUR FAVOURITE ARTISTS
//
// https://serenade.co/
//

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./Account/IAccountFactory.sol";
import "./Royalty/IRoyaltyFactory.sol";
import "./Royalty/IRoyaltySplitter.sol";
import "./Store/IStorage.sol";

contract Serenade is Ownable, ReentrancyGuard {
  // ============ Storage ============

  //reference for the store
  IStorage private _store;
  //reference for the account factory (deploys account contracts)
  IAccountFactory private _accountFactory;
  //reference for the royalty factory (deploys royalty contracts)
  IRoyaltyFactory private _royaltyFactory;

  // ============ Deploy ============

  constructor(
    IStorage store, 
    IAccountFactory accountFactory, 
    IRoyaltyFactory royaltyFactory,
    address admin
  ) {
    _transferOwnership(admin);
    _store = store;
    _accountFactory = accountFactory;
    _royaltyFactory = royaltyFactory;
  }

  // ============ Account Methods ============

  /**
   * @dev Returns account information
   */
  function account(uint256 accountId) external view returns(
    // Type
    string memory typeOf,
    // Token name
    string memory name,
    // Token symbol
    string memory symbol,
    // Metadata URI
    string memory uri,
    // current supply (how many tokens minted)
    uint256 currentSupply,
    //operator address
    address operator,
    //exists flag
    bool exists
  ) {
    return _store.account(accountId);
  }

  /**
   * @dev Returns the account id of a product
   */
  function accountOf(uint256 productId) external view returns(uint256) {
    return _store.accountOf(productId);
  }

  /**
   * @dev Returns the balance of a `recipient` in an account
   */
  function balanceOf(uint256 accountId, address recipient) 
    external view returns(uint256) 
  {
    return _store.balanceOf(accountId, recipient);
  }

  /**
   * @dev Deploys an account contract and adds to the store
   */
  function createAccount(
    uint256 id,
    string memory typeOf,
    string memory name,
    string memory symbol,
    string memory uri,
    address owner
  ) external onlyOwner {
    //let the account factory deploy the account
    _accountFactory.deploy(id, _store, owner);
    //next set the account
    setAccount(
      id, 
      typeOf, 
      name, 
      symbol, 
      uri, 
      _accountFactory.account(id)
    );
  }

  /**
   * @dev Adds or updates an account
   */
  function setAccount(
    uint256 id,
    string memory typeOf,
    string memory name,
    string memory symbol,
    string memory uri,
    address operator
  ) public onlyOwner {
    _store.setAccount(id, typeOf, name, symbol, uri, operator);
  }

  // ============ Product Methods ============

  /**
   * @dev Returns product information
   */
  function product(uint256 productId) external view returns(
    //fixed metadata uri
    string memory uri,
    //max supply size
    uint256 maxSupply,
    //current supply size (editions)
    uint256 currentSupply,
    //royalty percent
    uint16 royaltyPercent,
    //royalty recipient
    address royaltyRecipient,
    //exists flag
    bool exists
  ) {
    return _store.product(productId);
  }

  /**
   * @dev Returns the product id of a token
   */
  function productOf(uint256 tokenId) external view returns(uint256) {
    return _store.productOf(tokenId);
  }

  /**
   * @dev Deploys a royalty splitter contract and adds to the store
   */
  function createProduct(
    uint256 accountId,
    uint256 productId,
    uint256 maxSupply,
    string memory uri,
    uint16 royaltyPercent,
    address[] memory payees,
    uint256[] memory shares
  ) external onlyOwner {
    //let the royalty factory deploy the royalty
    _royaltyFactory.deploy(
      productId, 
      payees, 
      shares, 
      owner(), 
      address(this)
    );
    //next set the product
    setProduct(
      accountId, 
      productId, 
      maxSupply, 
      uri, 
      royaltyPercent, 
      _royaltyFactory.royalty(productId)
    );
  }
  
  /**
   * @dev Adds or updates a product
   */
  function setProduct(
    uint256 accountId,
    uint256 productId,
    uint256 maxSupply,
    string memory uri,
    uint16 royaltyPercent,
    address royaltyRecipient
  ) public onlyOwner {
    _store.setProduct(
      accountId, 
      productId, 
      maxSupply, 
      uri, 
      royaltyPercent, 
      royaltyRecipient
    );
  }

  // ============ Token Methods ============

  /**
   * @dev Returns the owner of a token
   */
  function ownerOf(uint256 tokenId) external view returns(address) {
    return _store.ownerOf(tokenId);
  }
  
  /**
   * @dev Returns the token URI by using the base uri and index
   */
  function tokenURI(uint256 tokenId) external view returns(string memory) {
    return _store.tokenURI(tokenId);
  }

  /**
   * @dev Mints a token
   */
  function mint(
    uint256 productId, 
    uint256 tokenId, 
    address recipient
  ) external onlyOwner {
    _store.mint(productId, tokenId, recipient);
  }

  /**
   * @dev Transfers a token (Could be dangerous)
   */
  function transfer(address to, uint256 tokenId) external onlyOwner {
    _store.transfer(to, tokenId);
  }

  // ============ Royalty Methods ============

  /**
   * @dev Returns the royalty address of a product
   */
  function royaltyOf(uint256 productId) public view returns(address) {
    return _store.royaltyOf(productId);
  }

  /**
   * @dev Getter for the address of the recipient number `index`.
   */
  function royaltyIndexRecipient(uint256 productId, uint256 index) 
    external view returns(address) 
  {
    return IRoyaltySplitter(royaltyOf(productId)).recipient(index);
  }
  
  /**
   * @dev Calculates the eth that can be releasable to `account`
   */
  function royaltyReleasable(uint256 productId, address recipient) 
    external view returns(uint256) 
  {
    return IRoyaltySplitter(royaltyOf(productId)).releasable(recipient);
  }

  /**
   * @dev Calculates the ERC20 that can be releasable to `account`
   */
  function royaltyReleasable(uint256 productId, IERC20 token, address recipient) 
    external view returns(uint256)
  {
    return IRoyaltySplitter(royaltyOf(productId)).releasable(token, recipient);
  }

  /**
   * @dev Triggers a transfer to `account` of the amount of Ether they 
   * are owed, according to their percentage of the total shares and 
   * their previous withdrawals.
   */
  function royaltyRelease(uint256 productId, address payable recipient) 
    external nonReentrant 
  {
    IRoyaltySplitter(royaltyOf(productId)).release(recipient);
  }

  /**
   * @dev Triggers a transfer to `account` of the amount of `token` 
   * tokens they are owed, according to their percentage of the total 
   * shares and their previous withdrawals. `token` must be the address 
   * of an IERC20 contract.
   */
  function royaltyRelease(uint256 productId, IERC20 token, address recipient) 
    external nonReentrant
  {
    IRoyaltySplitter(royaltyOf(productId)).release(token, recipient);
  }

  /**
   * @dev Getter for the amount of Ether already released to a payee.
   */
  function royaltyReleased(uint256 productId, address recipient) 
    external view returns(uint256) 
  {
    return IRoyaltySplitter(royaltyOf(productId)).released(recipient);
  }

  /**
   * @dev Getter for the amount of `token` tokens already released to a 
   * payee. `token` should be the address of an IERC20 contract.
   */
  function royaltyReleased(uint256 productId, IERC20 token, address recipient) 
    external view returns(uint256) 
  {
    return IRoyaltySplitter(royaltyOf(productId)).released(token, recipient);
  }

  /**
   * @dev Getter for the amount of shares held by an account.
   */
  function royaltyShares(uint256 _productId, address _recipient) 
    external view returns(uint256) 
  {
    return IRoyaltySplitter(royaltyOf(_productId)).shares(_recipient);
  }

  /**
   * @dev Getter for the total amount of Ether already released.
   */
  function royaltyTotalReleased(uint256 productId) 
    external view returns(uint256)
  {
    return IRoyaltySplitter(royaltyOf(productId)).totalReleased();
  }

  /**
   * @dev Getter for the total amount of `token` already released. 
   * `token` should be the address of an IERC20 contract.
   */
  function royaltyTotalReleased(
    uint256 productId, 
    IERC20 token
  ) external view returns(uint256) {
    return IRoyaltySplitter(royaltyOf(productId)).totalReleased(token);
  }

  /**
   * @dev Getter for the total shares held by recipients.
   */
  function royaltyTotalShares(uint256 productId) 
    external view returns(uint256)
  {
    return IRoyaltySplitter(royaltyOf(productId)).totalShares();
  }

  /**
   * @dev Considers tokens that can be vaulted
   */
  function royaltyAcceptToken(uint256 productId, IERC20 token) 
    external onlyOwner 
  {
    IRoyaltySplitter(royaltyOf(productId)).accept(token);
  }

  /**
   * @dev Add a new `account` to the contract.
   */
  function royaltyAddRecipient(
    uint256 productId, 
    address recipient, 
    uint256 shares
  ) external onlyOwner {
    IRoyaltySplitter(royaltyOf(productId)).addRecipient(recipient, shares);
  }

  function royaltyBatchUpdate(
    uint256 productId, 
    address[] memory recipients, 
    uint256[] memory shares
  ) external onlyOwner {
    IRoyaltySplitter(royaltyOf(productId)).batchUpdate(recipients, shares);
  }

  /**
   * @dev Removes a `recipient`
   */
  function royaltyRemoveRecipient(
    uint256 productId, 
    uint256 index
  ) external onlyOwner {
    IRoyaltySplitter(royaltyOf(productId)).removeRecipient(index);
  }

  /**
   * @dev Update a `recipient`
   */
  function royaltyUpdateRecipient(
    uint256 productId, 
    address recipient, 
    uint256 shares
  ) external onlyOwner {
    IRoyaltySplitter(royaltyOf(productId)).updateRecipient(recipient, shares);
  }

  // ============ Admin Methods ============

  /**
   * @dev Pauses transactions
   */
  function pause() external onlyOwner {
    _store.pause();
  }

  /**
   * @dev Unpauses transactions
   */
  function unpause() external onlyOwner {
    _store.unpause();
  }

  /**
   * @dev Updates the location of the account factory
   */
  function updateAccountFactory(IAccountFactory factory) 
    external onlyOwner 
  {
    _accountFactory = factory;
  }

  /**
   * @dev Updates the location of the store
   */
  function updateStore(IStorage store) external onlyOwner {
    _store = store;
  }

  /**
   * @dev Updates the location of the royalty factory
   */
  function updateRoyaltyFactory(IRoyaltyFactory factory) 
    external onlyOwner 
  {
    _royaltyFactory = factory;
  }

  /**
   * @dev A way that this contract can transfer factory ownership 
   * to another contract
   */
  function transferFactoryOwnership(address operator) external onlyOwner {
    _accountFactory.transferOwnership(operator);
    _royaltyFactory.transferOwnership(operator);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Store/IStorage.sol";

interface IAccountFactory {
  // ============ Read Methods ============

  /**
   * @dev returns the account address
   */
  function account(uint256 id) external view returns(address);

  // ============ Write Methods ============

  /**
   * @dev Deploys an account contract and adds to the store
   */
  function deploy(uint256 _id, IStorage _store, address _owner) 
    external;

  /**
   * @dev Allows contracts to pass ownership
   */
  function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRoyaltyFactory {
  // ============ Read Methods ============

  /**
   * @dev Returns the royalty address
   */
  function royalty(uint256 id) external view returns(address);

  // ============ Write Methods ============

  /**
   * @dev Deploys a royalty splitter contract and adds to the store
   */
  function deploy(
    uint256 _id,
    address[] memory _payees,
    uint256[] memory _shares,
    address _owner,
    address _operator
  ) external;

  /**
   * @dev Allows contracts to pass ownership
   */
  function transferOwnership(address newOwner) external;
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
   * @dev Calculates the eth that can be releasable to `account`
   */
  function releasable(address account) external view returns(uint256);

  /**
   * @dev Calculates the ERC20 that can be releasable to `account`
   */
  function releasable(IERC20 token, address account) 
    external view returns(uint256);

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

pragma solidity ^0.8.0;

import "../Account/IProduct.sol";

interface IStorage is IProduct {

  // ============ Structs ============

  struct Account {
    // Token name
    string name;
    // Token symbol
    string symbol;
    // Metadata URI
    string uri;
    // Type
    string typeOf;
    // current supply (how many tokens minted)
    uint256 currentSupply;
    //operator address
    address operator;
    //exists flag
    bool exists;
  }

  // ============ Read Methods ============

  /**
   * @dev Returns account information
   */
  function account(uint256 accountId) external view returns(
    // Type
    string memory typeOf,
    // Token name
    string memory name,
    // Token symbol
    string memory symbol,
    // Metadata URI
    string memory uri,
    // current supply (how many tokens minted)
    uint256 currentSupply,
    //operator address
    address operator,
    //exists flag
    bool exists
  );

  /**
   * @dev Returns the account id of a product
   */
  function accountOf(uint256 productId) external view returns(uint256);

  /**
   * @dev Returns the balance of a `recipient` in an account
   */
  function balanceOf(uint256 accountId, address recipient) 
    external view returns(uint256); 

  /**
   * @dev Returns the owner of a token
   */
  function ownerOf(uint256 tokenId) external view returns(address);

  /**
   * @dev Returns the royalty address of a product
   */
  function royaltyOf(uint256 productId) external view returns(address);

  /**
   * @dev Returns the token URI by using the base uri and index
   */
  function tokenURI(uint256 tokenId) external view returns(string memory); 

  // ============ Write Methods ============ 
  
  /**
   * @dev Mints a token
   */
  function mint(
    uint256 productId, 
    uint256 tokenId, 
    address recipient
  ) external;

  /**
   * @dev Pauses transactions
   */
  function pause() external;

  /**
   * @dev Adds an account
   */
  function setAccount(
    uint256 accountId,
    string memory typeOf,
    string memory name,
    string memory symbol,
    string memory uri,
    address operator
  ) external;
  
  /**
   * @dev Adds a product
   */
  function setProduct(
    uint256 accountId,
    uint256 productId,
    uint256 maxSupply,
    string memory uri,
    uint16 royaltyPercent,
    address royaltyRecipient
  ) external;
  
  /**
   * @dev Transfers a token
   */
  function transfer(address to, uint256 tokenId) external;

  /**
   * @dev Pauses transactions
   */
  function unpause() external;
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

pragma solidity ^0.8.0;

interface IProduct {

  // ============ Structs ============

  struct Product {
    //fixed metadata uri
    string uri;
    //max supply size
    uint256 maxSupply;
    //current supply size (editions)
    uint256 currentSupply;
    //royalty percent
    uint16 royaltyPercent;
    //royalty recipient
    address royaltyRecipient;
    //exists flag
    bool exists;
  }

  // ============ Read Methods ============ 

  /**
   * @dev Returns product information
   */
  function product(uint256 productId) external view returns(
    //fixed metadata uri
    string memory uri,
    //max supply size
    uint256 maxSupply,
    //current supply size (editions)
    uint256 currentSupply,
    //royalty percent
    uint16 royaltyPercent,
    //royalty recipient
    address royaltyRecipient,
    //exists flag
    bool exists
  );

  /**
   * @dev Returns the product id of a token
   */
  function productOf(uint256 tokenId) external view returns(uint256);
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