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
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (uint256);    
}

contract Swap is Ownable {
  IERC20 swapToken;
  uint256 public tokenPerMaticBuy  = 25e16;  //250000000000000000
  uint256 public tokenPerMaticSell = 24e16;  //240000000000000000
  event BuyTokens(address indexed buyer, uint256 amountOfMATIC, uint256 amountOfTokens);
  event SellTokens(address indexed seller, uint256 amountOfMATIC, uint256 amountOfTokens);
  constructor(address tokenAddress) {
    swapToken = IERC20(tokenAddress);
  }

  receive() external payable { }

  function buyTokens() external payable {
    require(msg.value > 0, "You need to send some MATIC to proceed");
    uint256 amountToBuy = (msg.value * tokenPerMaticBuy) / 1 ether;

    uint256 swapBalance = swapToken.balanceOf(address(this));
    require(swapBalance >= amountToBuy, "Swap has insufficient tokens");

    (bool sent) = swapToken.transfer(msg.sender, amountToBuy);
    require(sent, "Failed to transfer token to user");

    emit BuyTokens(msg.sender, msg.value, amountToBuy);
  }
  function sellTokens(uint256 tokenAmountToSell) external {

    require(tokenAmountToSell > 0, "Specify an amount of token greater than zero");

    uint256 userBalance = swapToken.balanceOf(msg.sender);
    require(userBalance >= tokenAmountToSell, "You have insufficient tokens");

    uint256 amountOfMATICToTransfer = (tokenAmountToSell * 1 ether) / tokenPerMaticSell;
    uint256 ownerMATICBalance = address(this).balance;
    require(ownerMATICBalance >= amountOfMATICToTransfer, "Vendor has insufficient funds");
    swapToken.transferFrom(msg.sender, address(this), tokenAmountToSell);
    (bool sent,) = msg.sender.call{value: amountOfMATICToTransfer}("");
    require(sent, "Failed to transfer Matic to user");
    emit SellTokens(msg.sender, amountOfMATICToTransfer, tokenAmountToSell);
  }

  function withdraw() public onlyOwner {
    require(address(this).balance > 0, "No MATIC present in Swap");
    (bool sent,) = msg.sender.call{value: address(this).balance}("");
    require(sent, "Failed to withdraw");
  }

  function withdrawTokens() public onlyOwner {
    uint balance = swapToken.balanceOf(address(this));
    require(balance > 0, "No Tokens present in Swap");
    swapToken.transfer(owner(), balance);
  }

   function setBuyTokenPrice(uint256 _priceBuy) public onlyOwner {
        tokenPerMaticBuy = _priceBuy;
    }

    function setSellTokenPrice(uint256 _priceSell) public onlyOwner {
        tokenPerMaticSell = _priceSell;
    }
}