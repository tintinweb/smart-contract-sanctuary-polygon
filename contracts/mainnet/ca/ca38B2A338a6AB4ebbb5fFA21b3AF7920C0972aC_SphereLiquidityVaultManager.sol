//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDystRouter.sol";
import "./interfaces/IPenroseProxy.sol";

interface ISphereLiquidityManager {
  function createVault() external;
  function addLiquidity(uint256, uint256) external returns (uint256);
  function removeLiquidity(uint256) external;
  function balanceOfSphere(address) external view returns (uint256);
  function claimRewards() external;
  function unstakeAndClaim() external;

  event CreateVault(address creator);
  event AddLiquidity(address sender, uint256 lpAmount);
  event RemoveLiquidity(address sender, uint256 lpAmount);
}

interface ISphereLiquidityVault {
  function depositLP(uint256 _lpAmount) external;
  function withdrawLP(uint256 _lpAmount) external;
  function claimRewards() external;
  function unstakeAndClaim() external;
}

contract SphereLiquidityVaultManager is ISphereLiquidityManager, Ownable {
  struct Vault {
    address addr;
    uint256 token0Balance;
    uint256 token1Balance;
    uint256 lpAmount;
  }

  mapping(address => Vault) public vaults;

  address public router;
  address public penroseProxy;
  address public token0;
  address public token1;

  constructor(address _router, address _penroseProxy, address _token0, address _token1) {
    require(_router != address(0), "Router address set to zero");
    router = _router;

    require(_penroseProxy != address(0), "Penrose proxy to zero");
    penroseProxy = _penroseProxy;

    require(_token0 != address(0), "Token 0 set to zero");
    token0 = _token0;

    require(_token1 != address(0), "Token 1 set to zero");
    token1 = _token1;

    IERC20(token0).approve(router, type(uint256).max);
    IERC20(token1).approve(router, type(uint256).max);

    address lpToken = IDystRouter(router).pairFor(token0, token1, false);
    IERC20(lpToken).approve(router, type(uint256).max);
  }

  function createVault() external override {
    require(vaults[msg.sender].addr == address(0), "Vault already exists");

    address lpToken = IDystRouter(router).pairFor(token0, token1, false);

    ISphereLiquidityVault vault = new SphereLiquidityVault(lpToken, msg.sender, penroseProxy);
    IERC20(lpToken).approve(address(vault), type(uint256).max);

    vaults[msg.sender] = Vault({
      addr: address(vault),
      token0Balance: 0,
      token1Balance: 0,
      lpAmount: 0
    });

  }

  function addLiquidity(uint256 _amount0, uint256 _amount1) external override returns (uint256) {
    require(vaults[msg.sender].addr != address(0), "No vault");
    Vault storage vault = vaults[msg.sender];

    (uint256 amountA, uint256 amountB, ) =
      IDystRouter(router).quoteAddLiquidity(token0, token1, false, _amount0, _amount1);

    IERC20(token0).transferFrom(msg.sender, address(this), amountA);
    IERC20(token1).transferFrom(msg.sender, address(this), amountB);

    (uint256 rAmountA, uint256 rAmountB, uint256 lpAmount) =
      IDystRouter(router).addLiquidity(
        token0, token1, false,
        amountA, amountB,
        amountA, 0,
        address(this), block.timestamp + 5 minutes
      );

    vault.token0Balance += rAmountA;
    vault.token1Balance += rAmountB;

    ISphereLiquidityVault(vault.addr).depositLP(lpAmount);

    vault.lpAmount += lpAmount;

    IERC20(token0).transfer(msg.sender, amountA - rAmountA);
    IERC20(token1).transfer(msg.sender, amountB - rAmountB);

    emit AddLiquidity(msg.sender, lpAmount);

    return lpAmount;
  }

  function removeLiquidity(uint256 _lpAmount) external override {
    require(vaults[msg.sender].addr != address(0), "No vault");
    Vault storage vault = vaults[msg.sender];

    address lpToken = IDystRouter(router).pairFor(token0, token1, false);
    require(IERC20(lpToken).balanceOf(vault.addr) >= _lpAmount, "Not enough LP");

    ISphereLiquidityVault(vault.addr).withdrawLP(_lpAmount);

    (uint256 amount0, uint256 amount1) =
      IDystRouter(router).quoteRemoveLiquidity(token0, token1, false, _lpAmount);

    (uint256 amountA, uint256 amountB) = IDystRouter(router).removeLiquidity(
      token0, token1, false,
      _lpAmount, amount0, amount1,
      address(this), block.timestamp + 5 minutes);

    vault.token0Balance -= amountA;
    vault.token1Balance -= amountB;
    vault.lpAmount -= _lpAmount;

    IERC20(token0).transfer(msg.sender, amountA);
    IERC20(token1).transfer(msg.sender, amountB);

    emit RemoveLiquidity(msg.sender, _lpAmount);
  }

  function claimRewards() external override {
    require(vaults[msg.sender].addr != address(0), "No vault");
    ISphereLiquidityVault(vaults[msg.sender].addr).claimRewards();
  }

  function unstakeAndClaim() external override {
    require(vaults[msg.sender].addr != address(0), "No vault");
    ISphereLiquidityVault(vaults[msg.sender].addr).unstakeAndClaim();
  }

  function balanceOfSphere(address _vaultOwner) external view returns (uint256) {
    if(vaults[_vaultOwner].addr == address(0)) {
      return 0;
    }

    return vaults[_vaultOwner].token0Balance;
  }

  function liquidityBalanceOf(address _vaultOwner) external view returns (uint256) {
    if(vaults[_vaultOwner].addr == address(0)) {
      return 0;
    }

    return vaults[_vaultOwner].lpAmount;
  }
}

contract SphereLiquidityVault is ISphereLiquidityVault, Ownable {
  address public lpToken;
  address public manager;
  address public penroseProxy;

  address constant DYST = 0x39aB6574c289c3Ae4d88500eEc792AB5B947A5Eb;
  address constant PEN = 0x9008D70A5282a936552593f410AbcBcE2F891A97;
  address constant PENDYST = 0x5b0522391d0A5a37FD117fE4C43e8876FB4e91E6;

  modifier onlyManager {
    require(msg.sender == manager, "Not allowed there");
    _;
  }

  modifier onlyOwnerOrManager {
    require(msg.sender == owner() || msg.sender == manager, "Not allowed here");
    _;
  }

  constructor(address _lp, address _user, address _penroseProxy) {
    require(_lp != address(0), "LP address to zero");
    lpToken = _lp;
    IERC20(lpToken).approve(msg.sender, type(uint256).max);

    require(_user != address(0), "User to zero");
    transferOwnership(_user);

    require(_penroseProxy != address(0), "Penrose proxy set to zero");
    penroseProxy = _penroseProxy;

    IERC20(lpToken).approve(penroseProxy, type(uint256).max);
    IERC20(DYST).approve(penroseProxy, type(uint256).max);
    IERC20(PEN).approve(penroseProxy, type(uint256).max);

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
    IPenroseProxy(penroseProxy).claimAllStakingRewards();
    IPenroseProxy(penroseProxy).convertDystToPenDystAndStake();
    IERC20(PEN).transfer(owner(), IERC20(PEN).balanceOf(address(this)));
  }

  function unstakeAndClaim() external override onlyOwnerOrManager {
    IPenroseProxy(penroseProxy).unstakePenDyst();
    IERC20(PENDYST).transfer(owner(), IERC20(PENDYST).balanceOf(owner()));
  }

  function withdraw(address _token) public onlyOwner {
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

pragma solidity 0.8.13;

interface IDystRouter {
  function quoteAddLiquidity(
    address tokenA, address tokenB, bool stable,
    uint amountADesired, uint amountBDesired
  ) external view returns (uint amountA, uint amountB, uint liquidity);

  function quoteRemoveLiquidity(
    address tokenA, address tokenB, bool stable, uint liquidity
  ) external view returns (uint amountA, uint amountB);

  function addLiquidity(
    address tokenA, address tokenB, bool stable,
    uint amountADesired, uint amountBDesired,
    uint amountAMin, uint amountBMin,
    address to, uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
  
  function removeLiquidity(
    address tokenA, address tokenB, bool stable,
    uint liquidity,
    uint amountAMin, uint amountBMin,
    address to, uint deadline
  ) external returns (uint amountA, uint amountB);

  function pairFor(address tokenA, address tokenB, bool stable) external view returns (address pair);
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