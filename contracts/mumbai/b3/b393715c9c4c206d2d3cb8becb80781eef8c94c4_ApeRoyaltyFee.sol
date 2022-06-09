/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/test2.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract ApeRoyaltyFee is Ownable {
  event Received(address, uint);

  address public publicGoodsAddress = address(0);
  address public teamFundAddress = address(0);

  uint256 public publicGoodsRateMultiplier = 0;
  uint256 public publicGoodsRateDivider = 1;

  uint256 public totalFeeReceived = 0;
  uint256 public totalPublicGoodsFeeReceived = 0;
  uint256 public totalTeamFundReceived = 0;

  constructor() {
  }

  function setPublicGoodsAddress(address addr) public onlyOwner {
    publicGoodsAddress = addr;
  }

  function setTeamFundAddress(address addr) public onlyOwner {
    teamFundAddress = addr;
  }

  function setPublicGoodsRateMultiplier(uint256 multiplier) public onlyOwner {
    publicGoodsRateMultiplier = multiplier;
  }

  function setPublicGoodsRateDivider(uint256 divider) public onlyOwner {
    publicGoodsRateDivider = divider;
  }

  ////////////////////////////////////////////////////
  // Withdrawal, in case if there is something wrong
  ////////////////////////////////////////////////////

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /////////////
  // Fallback
  /////////////

  receive() external payable {
    require(publicGoodsAddress != address(0), "Public goods address is not yet set");
    require(teamFundAddress != address(0), "Team fund address is not yet set");

    uint256 to_public_goods = msg.value * publicGoodsRateMultiplier / publicGoodsRateDivider;
    uint256 to_team = msg.value - to_public_goods;

    payable(publicGoodsAddress).transfer(to_public_goods);
    payable(teamFundAddress).transfer(to_team);

    totalFeeReceived = totalFeeReceived + msg.value;
    totalPublicGoodsFeeReceived = totalPublicGoodsFeeReceived + to_public_goods;
    totalTeamFundReceived = totalTeamFundReceived + to_team;

    emit Received(msg.sender, msg.value);
  }
}