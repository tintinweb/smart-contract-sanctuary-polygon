// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IPenroseProxy.sol";

contract Vault is IVault {
  address public lpToken;
  address public manager;
  address public owner;
  address public penroseProxy;

  address public dyst; // 0x39aB6574c289c3Ae4d88500eEc792AB5B947A5Eb;
  address public pen; // 0x9008D70A5282a936552593f410AbcBcE2F891A97;
  address public constant PENDYST = 0x5b0522391d0A5a37FD117fE4C43e8876FB4e91E6;

  string public constant VERSION = "0.0.1";

  modifier onlyOwner {
    require(msg.sender == owner, "Not allowed there");
    _;
  }

  modifier onlyManager {
    require(msg.sender == manager, "Not allowed there");
    _;
  }

  modifier onlyOwnerOrManager {
    require(msg.sender == owner || msg.sender == manager, "Not allowed here");
    _;
  }

  function initialize(
    address _lp,
    address _user,
    address _penroseProxy,
    address _pen,
    address _dyst
  ) public override {

    require(lpToken == address(0), "Already initialized");

    require(_lp != address(0), "LP address to zero");
    lpToken = _lp;
    IERC20(lpToken).approve(msg.sender, type(uint256).max);

    require(_user != address(0), "User to zero");
    owner = _user;

    require(_penroseProxy != address(0), "Penrose proxy set to zero");
    penroseProxy = _penroseProxy;

    IERC20(lpToken).approve(penroseProxy, type(uint256).max);

    require(_pen != address(0), "Pen token address to zero");
    pen = _pen;
    IERC20(pen).approve(penroseProxy, type(uint256).max);

    require(_dyst != address(0), "Dyst token address to zero");
    dyst = _dyst;
    IERC20(dyst).approve(penroseProxy, type(uint256).max);
    

    manager = msg.sender;
  }

  function depositLP(uint256 _lpAmount) external override onlyManager {
    require(IERC20(lpToken).balanceOf(msg.sender) >= _lpAmount, "Not enough LP");
    require(IERC20(lpToken).allowance(msg.sender, address(this)) >= _lpAmount, "Insufficient allowance");
    IERC20(lpToken).transferFrom(msg.sender, address(this), _lpAmount);

    IPenroseProxy(penroseProxy).depositLpAndStake(lpToken, _lpAmount);
  }

  function withdrawLP(uint256 _lpAmount) external override onlyManager {
    IPenroseProxy(penroseProxy).unstakeLpAndWithdraw(lpToken, _lpAmount);

    IERC20(lpToken).transfer(msg.sender, _lpAmount);
  }

  function claimRewards() external override onlyOwnerOrManager {
    IPenroseProxy(penroseProxy).claimStakingRewards();
    IPenroseProxy(penroseProxy).convertDystToPenDystAndStake();
    IERC20(pen).transfer(msg.sender, IERC20(pen).balanceOf(address(this)));
  }

  function unstakeAndClaim() external override onlyOwnerOrManager {
    IPenroseProxy(penroseProxy).unstakePenDyst();
    IERC20(PENDYST).transfer(msg.sender, IERC20(PENDYST).balanceOf(msg.sender));
  }

  function withdraw(address _token) external override onlyOwner {
    IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(msg.sender));
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

pragma solidity ^0.8.13;

interface IVault {
  function initialize(address _lp, address _user, address _penroseProxy, address _pen, address _dyst) external;
  function depositLP(uint256 _lpAmount) external;
  function withdrawLP(uint256 _lpAmount) external;
  function claimRewards() external;
  function unstakeAndClaim() external;
  function withdraw(address _token) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IPenroseProxy {
  function depositLpAndStake(address dystPoolAddress, uint256 amount) external;
  function depositLp(address dystPoolAddress) external;
  function depositLp(address dystPoolAddress, uint256 amount) external;
  function unstakeLpWithdrawAndClaim(address dystPoolAddress) external;
  function unstakeLpWithdrawAndClaim(address dystPoolAddress, uint256 amount) external;
  function unstakeLpAndWithdraw(address dystPoolAddress) external;
  function unstakeLpAndWithdraw(address dystPoolAddress, uint256 amount) external;
  function withdrawLp(address dystPoolAddress) external;
  function withdrawLp(address dystPoolAddress, uint256 amount) external;
  function stakePenLp(address penPoolAddress) external;
  function stakePenLp(address penPoolAddress, uint256 amount) external;
  function unstakePenLp(address penPoolAddress) external;
  function unstakePenLp(address penPoolAddress, uint256 amount) external;
  function claimStakingRewards(address stakingPoolAddress) external;
  function claimStakingRewards() external;
  function convertDystToPenDyst() external;
  function convertDystToPenDyst(uint256 amount) external;
  function convertDystToPenDystAndStake() external;
  function convertDystToPenDystAndStake(uint256 amount) external;
  function convertNftToPenDyst(uint256 tokenId) external;
  function convertNftToPenDystAndStake(uint256 tokenId) external;
  function stakePenDyst() external;
  function stakePenDyst(uint256 amount) external;
  function stakePenDystInPenV1() external;
  function stakePenDystInPenV1(uint256 amount) external;
  function unstakePenDyst() external;
  function unstakePenDyst(uint256 amount) external;
  function unstakePenDystInPenV1(uint256 amount) external;
  function unstakePenDyst(address stakingAddress, uint256 amount) external;
  function claimPenDystStakingRewards() external;
  function voteLockPen(uint256 amount, uint256 spendRatio) external;
  function withdrawVoteLockedPen(uint256 spendRatio) external;
  function relockVoteLockedPen(uint256 spendRatio) external;
  function claimVlPenStakingRewards() external;
  function vote(address poolAddress, int256 weight) external;
  // function vote(IUserProxy.Vote[] memory votes) external;
  function removeVote(address poolAddress) external;
  function resetVotes() external;
  function setVoteDelegate(address accountAddress) external;
  function clearVoteDelegate() external;
  function whitelist(address tokenAddress) external;
  function claimAllStakingRewards() external;
}