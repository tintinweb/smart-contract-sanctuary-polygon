// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./VaultProxy.sol";
import "./Vault.sol";
import "../interfaces/IDystRouter.sol";
import "../interfaces/IPenroseProxy.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultManager.sol";

contract VaultManager is IVaultManager {
  struct Vault {
    address addr;
    uint256 token0Balance;
    uint256 token1Balance;
    uint256 lpAmount;
  }

  mapping(address => Vault) public vaults;

  address public owner;
  address public vaultImplementationAddress;

  address public router;
  address public penroseProxy;
  address public token0;
  address public token1;

  modifier onlyOwner {
    require(owner == msg.sender, "Not allowed here");
    _;
  }

  function initialize(address _router, address _penroseProxy, address _token0, address _token1) public {
    require(owner == address(0), "Already initialized");
    owner = msg.sender;

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

  function setVaultImplementationAddress(address _addr) external override onlyOwner {
    require(_addr != address(0), "Vault implementation address to zero");
    vaultImplementationAddress = _addr;

    updateVaults();
  }

  function updateVaults() internal {}

  function transferOwnership(address _newOwner) external override onlyOwner {
    require(_newOwner != owner, "Owner did not changed");
    owner = _newOwner;
  }

  function createVault() external override returns (address) {
    require(vaultImplementationAddress != address(0), "Vault implementation not set");
    require(vaults[msg.sender].addr == address(0), "Vault already exists");

    vaults[msg.sender] = Vault({
      addr: address(new VaultProxy(vaultImplementationAddress, msg.sender)),
      token0Balance: 0,
      token1Balance: 0,
      lpAmount: 0
    });

    address lpToken = IDystRouter(router).pairFor(token0, token1, false);
    IVault(vaults[msg.sender].addr).initialize(lpToken, msg.sender, penroseProxy);
    IERC20(lpToken).approve(vaults[msg.sender].addr, type(uint256).max);

    return vaults[msg.sender].addr;
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

    IVault(vault.addr).depositLP(lpAmount);

    vault.lpAmount += lpAmount;

    IERC20(token0).transfer(msg.sender, amountA - rAmountA);
    IERC20(token1).transfer(msg.sender, amountB - rAmountB);

    emit AddLiquidity(msg.sender, lpAmount);

    return lpAmount;
  }

  function removeLiquidity(uint256 _lpAmount) external override {
    require(vaults[msg.sender].addr != address(0), "No vault");
    Vault storage vault = vaults[msg.sender];

    require(vaults[msg.sender].lpAmount >= _lpAmount, "Not enough LP");

    IVault(vault.addr).withdrawLP(_lpAmount);

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
    IVault(vaults[msg.sender].addr).claimRewards();
  }

  function unstakeAndClaim() external override {
    require(vaults[msg.sender].addr != address(0), "No vault");
    IVault(vaults[msg.sender].addr).unstakeAndClaim();
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

contract VaultProxy {
  bytes32 constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc; // keccak256('eip1967.proxy.implementation')
  bytes32 constant OWNER_SLOT =
      0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // keccak256('eip1967.proxy.admin')

  constructor(address _implementationAddress, address _ownerAddress) {
    assembly {
      sstore(IMPLEMENTATION_SLOT, _implementationAddress)
      sstore(OWNER_SLOT, _ownerAddress)
    }
  }

  function implementationAddress() external view returns (address _implementationAddress) {
    assembly {
      _implementationAddress := sload(IMPLEMENTATION_SLOT)
    }
  }

  function ownerAddress() public view returns (address _ownerAddress) {
    assembly {
      _ownerAddress := sload(OWNER_SLOT)
    }
  }

  function updateImplementationAddress(address _implementationAddress) external {
    require(msg.sender == ownerAddress(), "Only owners can update implementation");
    assembly {
      sstore(IMPLEMENTATION_SLOT, _implementationAddress)
    }
  }

  function updateOwnerAddress(address _ownerAddress) external {
    require(msg.sender == ownerAddress(), "Only owners can update owners");
    assembly {
      sstore(OWNER_SLOT, _ownerAddress)
    }
  }

  fallback() external {
    assembly {
      let contractLogic := sload(IMPLEMENTATION_SLOT)
      calldatacopy(0x0, 0x0, calldatasize())
      let success := delegatecall(
        gas(),
        contractLogic,
        0x0,
        calldatasize(),
        0,
        0
      )
      let returnDataSize := returndatasize()
      returndatacopy(0, 0, returnDataSize)
      switch success
      case 0 {
        revert(0, returnDataSize)
      }
      default {
        return(0, returnDataSize)
      }
    }
  }
}

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

  address public constant DYST = 0x39aB6574c289c3Ae4d88500eEc792AB5B947A5Eb;
  address public constant PEN = 0x9008D70A5282a936552593f410AbcBcE2F891A97;
  address public constant PENDYST = 0x5b0522391d0A5a37FD117fE4C43e8876FB4e91E6;

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

  function initialize(address _lp, address _user, address _penroseProxy) public {
    require(_lp != address(0), "LP address to zero");
    lpToken = _lp;
    IERC20(lpToken).approve(msg.sender, type(uint256).max);

    require(_user != address(0), "User to zero");
    owner = _user;

    require(_penroseProxy != address(0), "Penrose proxy set to zero");
    penroseProxy = _penroseProxy;

    IERC20(lpToken).approve(penroseProxy, type(uint256).max);
    // IERC20(DYST).approve(penroseProxy, type(uint256).max);
    // IERC20(PEN).approve(penroseProxy, type(uint256).max);

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
    IERC20(PEN).transfer(msg.sender, IERC20(PEN).balanceOf(address(this)));
  }

  function unstakeAndClaim() external override onlyOwnerOrManager {
    IPenroseProxy(penroseProxy).unstakePenDyst();
    IERC20(PENDYST).transfer(msg.sender, IERC20(PENDYST).balanceOf(msg.sender));
  }

  function withdraw(address _token) public onlyOwner {
    IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(msg.sender));
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

pragma solidity ^0.8.13;

interface IVault {
  function initialize(address _lp, address _user, address _penroseProxy) external;
  function depositLP(uint256 _lpAmount) external;
  function withdrawLP(uint256 _lpAmount) external;
  function claimRewards() external;
  function unstakeAndClaim() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVaultManager {
  function setVaultImplementationAddress(address _addr) external;
  function transferOwnership(address _newOwner) external;

  function createVault() external returns (address);
  function addLiquidity(uint256, uint256) external returns (uint256);
  function removeLiquidity(uint256) external;
  function balanceOfSphere(address) external view returns (uint256);
  function claimRewards() external;
  function unstakeAndClaim() external;

  event CreateVault(address creator);
  event AddLiquidity(address sender, uint256 lpAmount);
  event RemoveLiquidity(address sender, uint256 lpAmount);
}