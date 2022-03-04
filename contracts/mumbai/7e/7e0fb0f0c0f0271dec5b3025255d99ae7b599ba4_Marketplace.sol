/**
 *Submitted for verification at polygonscan.com on 2022-03-03
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

interface IERC20 {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function balanceOf(address owner) external view returns (uint256 balance);
  function transfer(address to, uint256 amount) external returns (bool);
}

contract Marketplace is Context, Ownable {
    event Buy(address indexed from, string indexed cardId, uint256 amount);
    event Clear(string indexed cardId);

    address public recipientWallet;
    uint256 public minimumAmount = 200 * (uint256(10) ** 18);
    IERC20 public ERC20Token;

    mapping(string => uint256) public cardIds;

    constructor(address ERC20Token_) {
        ERC20Token = IERC20(ERC20Token_);
        recipientWallet = _msgSender();
    }

    function setRecipientWallet(address recipientWallet_) external onlyOwner {
        recipientWallet = recipientWallet_;
    }

    function setMinimumAmount(uint256 minimumAmount_) external onlyOwner {
        require(minimumAmount_ >= 0, "Invalid amount");
        minimumAmount = minimumAmount_;
    }

    function setERC20Token(address ERC20Token_) external onlyOwner {
        ERC20Token = IERC20(ERC20Token_);
    }

    function clear(string memory cardId) external onlyOwner {
        require(cardIds[cardId] > 0, "Card not minted");
        delete cardIds[cardId];
        emit Clear(cardId);
    }

    function buy(string memory cardId, uint256 amount) external {
        require(cardIds[cardId] == 0, "Card is already minted");
        require(amount >= minimumAmount, "Amount too low");

        ERC20Token.transferFrom(_msgSender(), recipientWallet, amount);
        
        cardIds[cardId] = amount;
        emit Buy(_msgSender(), cardId, amount);
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