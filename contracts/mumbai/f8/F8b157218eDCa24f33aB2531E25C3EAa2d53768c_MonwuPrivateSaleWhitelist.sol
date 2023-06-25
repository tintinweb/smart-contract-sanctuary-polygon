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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MonwuPrivateSaleWhitelist is Ownable {

  struct WhitelistedInvester {
    address investor; 
    uint256 allocation;
    uint256 etherAmountToPay;
  }

  address whitelistOwner = 0x76bAf177d89B124Fd331764d48faf5bc6849A442;

  mapping(address => WhitelistedInvester) public whitelist;

  constructor () {
    transferOwnership(whitelistOwner);
  }


  event AddressAddedToWhitelist(address investor, uint256 allocation, uint256 etherAmountToPay);
  event EditedWhitelistedAddress(address investor,  uint256 newAllocation, uint256 newEtherAmountToPay);
  event AddressRemovedFromWhitelist(address investor);


  // ====================================================================================
  //                                  OWNER INTERFACE
  // ====================================================================================

  /// Allowing owner to add certein address to whitelist, set its allocation and amount to pay
  /// @param investor - address of an investor
  /// @param allocation - allocation given to certain investor
  /// @param etherAmountToPay - amount of ETH that investor has to pay to secure his allocation
  function addToWhitelist(address investor, uint256 allocation, uint256 etherAmountToPay) 
    external onlyOwner nonZeroAddress(investor) uniqueInvestor(investor) {

    WhitelistedInvester memory whitelistedInvestor = WhitelistedInvester(
      investor,
      allocation,
      etherAmountToPay
    );

    whitelist[investor] = whitelistedInvestor;

    emit AddressAddedToWhitelist(investor, allocation, etherAmountToPay);
  }

  /// Allowing owner to edit certein address on whitelist, set new allocation and new amount to pay
  /// @param investorToEdit - address of an investor
  /// @param editedAllocation - allocation given to certain investor
  /// @param editedEtherAmountToPay - amount of ETH that investor has to pay to secure his allocation
  function editWhitelistedInvestor(address investorToEdit, uint256 editedAllocation, uint256 editedEtherAmountToPay)
    external onlyOwner nonZeroAddress(investorToEdit) {

    whitelist[investorToEdit].allocation = editedAllocation;
    whitelist[investorToEdit].etherAmountToPay = editedEtherAmountToPay;

    emit EditedWhitelistedAddress(investorToEdit, editedAllocation, editedEtherAmountToPay);
  }

  /// Allowing owner to remove certain address from whitelist
  /// If investor didn't buy out the allocation he will no longer be able to do it
  /// If investor already bought the allocation, it will have no affect on the investor allocation
  /// @param investor - address of an investor
  function removeFromWhitelist(address investor)
    external onlyOwner nonZeroAddress(investor) {

    whitelist[investor].investor = address(0);
    whitelist[investor].allocation = 0;
    whitelist[investor].etherAmountToPay = 0;

    emit AddressRemovedFromWhitelist(investor);
  }

  // ====================================================================================
  //                                 PUBLIC INTERFACE
  // ====================================================================================

  /// Function to read invesotrs data
  /// @param investor - address of an invesor
  function getWhitelistedAddressData(address investor) external view returns(address, uint256, uint256) {
    return (whitelist[investor].investor, whitelist[investor].allocation, whitelist[investor].etherAmountToPay);
  }


  // ====================================================================================
  //                                     MODIFIERS
  // ====================================================================================

  modifier nonZeroAddress(address investor) {
    require(investor != address(0), "Address cannot be zero");
    _;
  }

  modifier uniqueInvestor(address investor) {
    require(whitelist[investor].investor == address(0), "Investor already whitelisted");
    _;
  }
}