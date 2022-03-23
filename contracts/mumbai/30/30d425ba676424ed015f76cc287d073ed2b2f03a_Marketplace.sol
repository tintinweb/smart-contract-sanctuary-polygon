/**
 *Submitted for verification at polygonscan.com on 2022-03-22
*/

/**
 *Submitted for verification at polygonscan.com on 2022-03-14
*/

// SPDX-License-Identifier: MIT

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

abstract contract TokenEnumerable {
  uint256[] private _allTokens;
  mapping(uint256 => uint256) private _allTokensIndex;

  /**
   * @dev Private function to add a token to this extension's token tracking data structures.
   * @param tokenId uint256 ID of the token to be added to the tokens list
   */
  function _addTokenToAllTokensEnumeration(uint256 tokenId) internal {
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  /**
   * @dev Private function to remove a token from this extension's token tracking data structures.
   * This has O(1) time complexity, but alters the order of the _allTokens array.
   * @param tokenId uint256 ID of the token to be removed from the tokens list
   */
  function _removeTokenFromAllTokensEnumeration(uint256 tokenId) internal {
    // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = _allTokens.length - 1;
    uint256 tokenIndex = _allTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
    // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
    // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
    uint256 lastTokenId = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
    _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

    // This also deletes the contents at the last position of the array
    delete _allTokensIndex[tokenId];
    _allTokens.pop();
  }

  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < _allTokens.length, "TokenEnumerable: global index out of bounds");
    return _allTokens[index];
  }
}

interface IERC20 {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function balanceOf(address owner) external view returns (uint256 balance);
  function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC721 {
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

struct ListingInfo {
  address owner;
  uint256 price;
}

contract Marketplace is Context, Ownable, TokenEnumerable {
  event Buy(address indexed buyer, address indexed seller, uint256 indexed tokenId, uint256 amount);
  event List(address indexed seller, uint256 indexed tokenId, uint256 price);
  event Unlist(uint256 indexed tokenId);

  address public feesWallet;
  uint256 public feesPercent;

  IERC20 public ERC20Token;
  IERC721 public ERC721Nft;

  mapping(uint256 => ListingInfo) public listing;

  constructor(address ERC20Token_, address ERC721Nft_) {
    ERC20Token = IERC20(ERC20Token_);
    ERC721Nft = IERC721(ERC721Nft_);

    feesWallet = _msgSender();
    feesPercent = 10;
  }

  function setFeesWallet(address feesWallet_) external onlyOwner {
    feesWallet = feesWallet_;
  }

  function setFeesPercent(uint256 feesPercent_) external onlyOwner {
    require(feesPercent_ >= 0 && feesPercent_ <= 100, "Fees percent must be between 0 and 100");
    feesPercent = feesPercent_;
  }

  function unlist(uint256 tokenId) external {
    address nftOwner = ERC721Nft.ownerOf(tokenId);

    require(nftOwner == _msgSender(), "Error: you need to be the token owner");
    require(listing[tokenId].price > 0, "Token is not listed");

    _removeTokenFromAllTokensEnumeration(tokenId);
    delete listing[tokenId];
     emit Unlist(tokenId);
  }

  function list(uint256 tokenId, uint256 price) external {
    address nftOwner = ERC721Nft.ownerOf(tokenId);

    require(nftOwner == _msgSender(), "Error: you need to be the token owner");
    require(price > 0, "Invalid price");

    if (listing[tokenId].price == 0) {
      _addTokenToAllTokensEnumeration(tokenId);
    }

    listing[tokenId] = ListingInfo(nftOwner, price);

    emit List(_msgSender(), tokenId, price);
  }

  function buy(uint256 tokenId, uint256 amount) external {
    address nftOwner = ERC721Nft.ownerOf(tokenId);

    require(listing[tokenId].price > 0, "Token is not listed");
    require(listing[tokenId].owner == nftOwner, "Token is not listed by the current owner");
    require(amount >= listing[tokenId].price, "The amount must be greater than or equal to the price");

    uint256 fees = amount * feesPercent / 100;
    ERC20Token.transferFrom(_msgSender(), nftOwner, amount - fees);
    ERC20Token.transferFrom(_msgSender(), feesWallet, fees);
    ERC721Nft.safeTransferFrom(nftOwner, _msgSender(), tokenId);

    _removeTokenFromAllTokensEnumeration(tokenId);
    delete listing[tokenId];

    emit Buy(_msgSender(), nftOwner, tokenId, amount);
  }

  function withdraw() external payable onlyOwner {
    (bool payment, ) = payable(owner()).call{value: address(this).balance}("");
    require(payment);
  }

  function withdrawToken(address tokenAddress) external onlyOwner {
    IERC20 tokenContract = IERC20(tokenAddress);
    uint256 balance = tokenContract.balanceOf(address(this));
    require(balance > 0, "Insufficient funds.");

    tokenContract.transfer(owner(), balance);
  }
}