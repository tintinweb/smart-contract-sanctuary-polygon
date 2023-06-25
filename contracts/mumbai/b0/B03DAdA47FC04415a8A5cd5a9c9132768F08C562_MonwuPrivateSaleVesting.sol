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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./MonwuPrivateSaleWhitelist.sol";

interface MonwuTokenERC20 is IERC20 {
  function burn(uint256 amount) external;
  function decimals() external view returns(uint8);
}

contract MonwuPrivateSaleVesting is Ownable {

  struct PrivateInvestor {
    address investor; 
    uint256 allocation;
    uint256 released;
    uint256 start;
    uint256 cliffEnd;
    uint256 vestingEnd;
  }

  MonwuTokenERC20 public monwuToken;
  MonwuPrivateSaleWhitelist public monwuPrivateSaleWhitelist;

  uint256 public privateSaleAllocation;
  uint256 public privateSoldTokens;

  uint256 public burnDeadline;

  uint256 public constant cliffDuration = 52 weeks;
  uint256 public constant vestingDuration = 52 weeks;
  uint256 public constant releaseDuration = 91 days;
  uint8 public constant numberOfUnlocks = 5;

  mapping(address => PrivateInvestor) public addressToPrivateInvestor;


  event OwnerWithdrawEther(uint256 indexed amount);
  event InvestorPaidAllocation(address indexed investor, uint256 indexed startTimestamp);
  event InvestorReleaseTokens(address indexed investor, uint256 indexed amount);


  constructor(address monwuTokenAddress, address whitelistAddress) {
    monwuPrivateSaleWhitelist = MonwuPrivateSaleWhitelist(whitelistAddress);
    monwuToken = MonwuTokenERC20(monwuTokenAddress);

    privateSaleAllocation = 150_000_000 * (10 ** monwuToken.decimals());

    burnDeadline = block.timestamp + (52 weeks * 3);

    transferOwnership(0xB1E6B6A058CB64987D51f99ced8f1B08a8297E03);
  }


  // ====================================================================================
  //                                  OWNER INTERFACE
  // ====================================================================================

  /// Allowing an owner to withdraw ETH
  /// @param amount - amount to withdraw
  function withdrawEther(uint256 amount) external onlyOwner {
    require(amount <= address(this).balance, "Not enough ether");

    (bool success,) = owner().call{ value: amount }("");
    require(success, "Transfer failed");

    emit OwnerWithdrawEther(amount);
  }

  /// Allowing owner to burn all MONWU token leftovers
  /// Investors have 3 years in total to release their allocation
  function burnLeftovers() external onlyOwner onlyAfterBurnDeadline {
    uint256 tokenBalance = monwuToken.balanceOf(address(this));
    monwuToken.burn(tokenBalance);
  }
  // ====================================================================================



  // ====================================================================================
  //                               INVESTORS INTERFACE
  // ====================================================================================

  /// Function for whitelisted addresses to buyout their allocation
  function buyPrivateSaleMonwu() external payable onlyWhitelisted {

    (address investor, uint256 allocation, uint256 amountToPay) = monwuPrivateSaleWhitelist.getWhitelistedAddressData(msg.sender);

    require(msg.value >= amountToPay, "Not enough ether");
    require(addressToPrivateInvestor[investor].investor == address(0), "Already added");
    require(privateSoldTokens + allocation <= privateSaleAllocation, "Private allocation exceeded");

    uint256 startCliff = block.timestamp;
    uint256 endCliff = startCliff + cliffDuration;
    uint256 endVesting = endCliff + vestingDuration;

    PrivateInvestor memory privateInvestor = PrivateInvestor(
      investor, 
      allocation, 
      0,
      startCliff,
      endCliff,
      endVesting
    );

    addressToPrivateInvestor[investor] = privateInvestor;
    privateSoldTokens += allocation;

    emit InvestorPaidAllocation(msg.sender, startCliff);
  }

  /// Allowing investors to realease their whole or partial allocation
  /// @param amount amount to withdraw
  function investorRelease(uint256 amount) external onlyInvestor cantReleaseMoreThanAllocation(amount) {

    uint256 releasableAmount = computeReleasableAmount();
    require(releasableAmount >= amount, "Can't withdraw more than is released");

    addressToPrivateInvestor[msg.sender].released += amount;
    monwuToken.transfer(msg.sender, amount);

    emit InvestorReleaseTokens(msg.sender, amount);
  }
  // ====================================================================================



  // ====================================================================================
  //                                     HELPERS
  // ====================================================================================

  function computeReleasableAmount() internal view returns(uint256) {

    uint256 releasableAmount;
    uint256 totalReleasedTokens;

    PrivateInvestor memory privateInvestor = addressToPrivateInvestor[msg.sender];

    // if cliff duration didn't end yet, releasable amount is zero.
    if(block.timestamp < privateInvestor.cliffEnd) return 0;

    // if cliff and vesting ended, rest tokens are claimable
    if(block.timestamp >= privateInvestor.vestingEnd) return privateInvestor.allocation - privateInvestor.released;

    totalReleasedTokens = (((block.timestamp - privateInvestor.cliffEnd) / releaseDuration) + 1) * (privateInvestor.allocation / numberOfUnlocks);
    releasableAmount = totalReleasedTokens - privateInvestor.released;

    return releasableAmount;
  }
  // ====================================================================================



  // ====================================================================================
  //                                     MODIFIERS
  // ====================================================================================

  modifier onlyInvestor() {
    require(addressToPrivateInvestor[msg.sender].investor == msg.sender, "Not an investor");
    _;
  }

  modifier onlyWhitelisted() {
    (address investor, , ) = monwuPrivateSaleWhitelist.getWhitelistedAddressData(msg.sender);
    require(investor == msg.sender, "Address not whitelisted");
    _;
  }

  modifier onlyAfterBurnDeadline() {
    require(block.timestamp > burnDeadline, "Burning deadline not reached yet");
    _;
  }

  modifier cantReleaseMoreThanAllocation(uint256 amount) {
    require(addressToPrivateInvestor[msg.sender].released + amount <= addressToPrivateInvestor[msg.sender].allocation, "Release exceeds allocation");
    _;
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