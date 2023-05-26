// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

/// @title Strikers Pass Interface, as used by Strikers DAO
/// @author 0x7777779E886D655C55D8a23d015dAED61a179627
/// @notice Strikes DAO changes Strikers Pass's purchase token when DAO's share token is changed
abstract contract IStrikersPass {
  function setPurchaseToken(address newToken) public virtual;
}

/// @title Strikers DAO Interface, as used by Strikers Pass
/// @author 0x7777779E886D655C55D8a23d015dAED61a179627
/// @notice Strikes Pass resets (to 0) the entitled revenue (in DAO) of any address which transfers out all of their Strikers Passes
abstract contract IStrikersDAO {
  function setRevShareBps(address who, uint16 _revSharingAmount) public virtual;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./abstract.sol";

/// @title Strikers DAO
/// @author 0x7777779E886D655C55D8a23d015dAED61a179627
/// notice Features revenue sharing and awarding
contract StrikersDAO {
  event RevenueClaimed(address beneficiary, uint16 bpsClaimed, uint256 amountClaimed, address tokenClaimedAddress);
  event OneTimeAward(address beneficiary, uint256 awardAmount, address awardTokenAddress);
  event RevenueSharingIntervalStart(uint256 totalRevenue);

  IERC20 private shareToken;
  IStrikersPass private strikersPass;

  mapping(address => uint16) private revSharingBps;
  mapping(address => uint256) private revSharingLastClaim;

  /// @notice The interval that must be between two consecutive revenue claiming intervals
  uint256 public revSharingClaimInterval;
  // array with [total revenue amount (in tokens), revenue share interval start time]
  uint256[2] private lastRevShareInterval;

  /// @notice Owner of the smart contract
  address public owner;

  constructor(uint256 _revSharingClaimInterval,
    address _shareToken) {
    owner = msg.sender;
    revSharingClaimInterval = _revSharingClaimInterval;
    shareToken = IERC20(_shareToken);
  }

  // Modifiers

  modifier ownerOnly() {
    require(msg.sender == owner, "Strikers DAO: Caller is not contract owner.");
    _;
  }

  modifier ownerOrContractOnly() {
    require(msg.sender == owner ||
      msg.sender == address(strikersPass),
      "Strikers DAO: Caller is not owner or Strikers smart contract");

    _;
  }

  /// @notice Begin a revenue sharing interval
  function startRevSharingClaimInterval() public ownerOnly {
    require(block.timestamp > lastRevShareInterval[1] + revSharingClaimInterval,
      "Strikers Pass: Too early to start a new claiming interval.");

    uint256 _totalRevenue = shareToken.balanceOf(address(this));
    // 1st element is the total amount of tokens (revenue) to share
    // 2nd element is when the revenue shareing interval started
    lastRevShareInterval = [
      _totalRevenue,
      block.timestamp
    ];

    emit RevenueSharingIntervalStart(_totalRevenue);
  }

  /// @notice Claim your revenue if you are entitled to any
  function claimRevShare() public {
    require(revSharingBps[msg.sender] > 0, "Strikers DAO: You are not entitled to any revenue.");
    require(lastRevShareInterval[1] > revSharingLastClaim[msg.sender],
      "Strikers DAO: You have alredy claimed your revenue for this period.");
    require(lastRevShareInterval[0] > 0, "Strikers DAO: There is no revenue to share.");

    uint256 tokenBalance = shareToken.balanceOf(address(this));
    uint256 entitledTokens = (tokenBalance * revSharingBps[msg.sender]) / 10000;

    revSharingLastClaim[msg.sender] = block.timestamp;

    shareToken.transfer(msg.sender, entitledTokens);

    emit RevenueClaimed(msg.sender, revSharingBps[msg.sender], entitledTokens, address(shareToken));
  }

  /// @notice Set the entitled revenue of an address in basis points (BPS, or 0.01%)
  /// @param who Address to set entitled revenue for
  /// @param _revSharingBps How much revenue `who` is entitled to (in BPS)
  function setRevShareBps(address who, uint16 _revSharingBps) public ownerOrContractOnly {
    revSharingBps[who] = _revSharingBps;
  }

  /// @notice Get the entitled revenue of an address in basis points (BPS, or 0.01%)
  /// @param who Address to get entitled revenue for
  /// @return Amount of revenue `who` is entitled to (in BPS)
  function getRevShareBps(address who) public view returns(uint16) {
    return revSharingBps[who];
  }

  /// @notice Transfer tokens from DAO treasurey as one-time award
  /// @param who Recipient of the award
  /// @param awardAmount Amount of the award, in units of the DAO's set shareToken
  function grantOneTimeAward(address who, uint256 awardAmount) public ownerOnly {
    shareToken.transfer(who, awardAmount);

    emit OneTimeAward(msg.sender, awardAmount, address(shareToken));
  }

  // Other functions

  /// @notice Get the address of the ERC-20 token the DAO uses for revenue sharing and award
  /// @return Address of the DAO's set shareToken
  function getShareToken() public view returns(address) {
    return address(shareToken);
  }

  /// @notice Set the address of the ERC-20 token the DAO uses for revenue sharing and award
  /// @param newToken The new revenue sharing token
  function setShareToken(address newToken) public ownerOnly {
    require(newToken != address(shareToken), "Strikers DAO: New token address must be different than old.");
    shareToken = IERC20(newToken);
    strikersPass.setPurchaseToken(newToken);
  }

  /// @notice Get the address of Strikers Pass
  /// @return The address of the current set Strikers Pass smart contract
  function getStrikersPassAddress() public view returns(address) {
    return address(strikersPass);
  }

  /// @notice Set the address of Strikers Pass
  /// @param _strikersPass The new address for Strikers Pass smart contract
  function setStrikersPassAddress(address _strikersPass) public ownerOnly {
    require(_strikersPass != address(strikersPass), "Strikers DAO: New Strikers Pass address must be different than old.");
    strikersPass = IStrikersPass(_strikersPass);
  }

  /// @notice Withdraw shareToken from the smart contract
  /// @param _amount Amount of token to withdraw
  function withdrawShareTokenFromContract(uint256 _amount) public ownerOnly {
    shareToken.transfer(msg.sender, _amount);
  }
}