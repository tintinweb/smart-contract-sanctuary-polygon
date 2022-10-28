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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
pragma solidity ^0.8.13;

import "openzeppelin-contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "./interfaces/IStablePool.sol";
import "./interfaces/IBalancerVault.sol";
import "./interfaces/ISmartVault.sol";
import "./interfaces/IDepositHelper.sol";
// import "forge-std/console.sol";

contract TetuQiPoolDepositor is Ownable {
  IStablePool constant POOL = IStablePool(0x4b3Fd0347B7fb1b7BafA61da841E40d5BF6Fe0F5);
  IBalancerVault constant BALANCER_VAULT =
    IBalancerVault(payable(0xBA12222222228d8Ba445958a75a0704d566BF2C8));
  bytes32 POOL_ID = 0x4b3fd0347b7fb1b7bafa61da841e40d5bf6fe0f5000200000000000000000868;
  IERC20 constant TETU_QI = IERC20(0x4Cd44ced63d9a6FEF595f6AD3F7CED13fCEAc768);
  IERC20 constant QI = IERC20(0x580A84C73811E1839F75d86d75d88cCa0c241fF4);

  constructor() {
    QI.approve(address(BALANCER_VAULT), type(uint256).max);
    TETU_QI.approve(address(BALANCER_VAULT), type(uint256).max);
  }

  function deposit() external {
    address[] memory assets = new address[](2);
    assets[0] = address(TETU_QI);
    assets[1] = address(QI);
    uint256[] memory amounts = new uint[](2);
    amounts[0] = TETU_QI.balanceOf(address(this));
    amounts[1] = QI.balanceOf(address(this));
    IVault.JoinPoolRequest memory jpr =
      IVault.JoinPoolRequest(assets, amounts, abi.encode(0, amounts, 0), false);
    BALANCER_VAULT.joinPool(POOL_ID, address(this), address(this), jpr);
  }

  function rescueToken(address _token, uint256 _amount) external onlyOwner {
    if (_token == address(0)) {
      payable(owner()).transfer(_amount);
    } else {
      IERC20(_token).transfer(owner(), _amount);
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IBalancerVault {
  event AuthorizerChanged(address indexed newAuthorizer);
  event ExternalBalanceTransfer(
    address indexed token, address indexed sender, address recipient, uint256 amount
  );
  event FlashLoan(
    address indexed recipient, address indexed token, uint256 amount, uint256 feeAmount
  );
  event InternalBalanceChanged(address indexed user, address indexed token, int256 delta);
  event PausedStateChanged(bool paused);
  event PoolBalanceChanged(
    bytes32 indexed poolId,
    address indexed liquidityProvider,
    address[] tokens,
    int256[] deltas,
    uint256[] protocolFeeAmounts
  );
  event PoolBalanceManaged(
    bytes32 indexed poolId,
    address indexed assetManager,
    address indexed token,
    int256 cashDelta,
    int256 managedDelta
  );
  event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, uint8 specialization);
  event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);
  event Swap(
    bytes32 indexed poolId,
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 amountIn,
    uint256 amountOut
  );
  event TokensDeregistered(bytes32 indexed poolId, address[] tokens);
  event TokensRegistered(bytes32 indexed poolId, address[] tokens, address[] assetManagers);

  function WETH() external view returns (address);

  function batchSwap(
    uint8 kind,
    IVault.BatchSwapStep[] memory swaps,
    address[] memory assets,
    IVault.FundManagement memory funds,
    int256[] memory limits,
    uint256 deadline
  ) external payable returns (int256[] memory assetDeltas);

  function deregisterTokens(bytes32 poolId, address[] memory tokens) external;

  function exitPool(
    bytes32 poolId,
    address sender,
    address recipient,
    IVault.JoinPoolRequest memory request
  ) external;

  function flashLoan(
    address recipient,
    address[] memory tokens,
    uint256[] memory amounts,
    bytes memory userData
  ) external;

  function getActionId(bytes4 selector) external view returns (bytes32);

  function getAuthorizer() external view returns (address);

  function getDomainSeparator() external view returns (bytes32);

  function getInternalBalance(address user, address[] memory tokens)
    external
    view
    returns (uint256[] memory balances);

  function getNextNonce(address user) external view returns (uint256);

  function getPausedState()
    external
    view
    returns (bool paused, uint256 pauseWindowEndTime, uint256 bufferPeriodEndTime);

  function getPool(bytes32 poolId) external view returns (address, uint8);

  function getPoolTokenInfo(bytes32 poolId, address token)
    external
    view
    returns (uint256 cash, uint256 managed, uint256 lastChangeBlock, address assetManager);

  function getPoolTokens(bytes32 poolId)
    external
    view
    returns (address[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

  function getProtocolFeesCollector() external view returns (address);

  function hasApprovedRelayer(address user, address relayer) external view returns (bool);

  function joinPool(
    bytes32 poolId,
    address sender,
    address recipient,
    IVault.JoinPoolRequest memory request
  ) external payable;

  function managePoolBalance(IVault.PoolBalanceOp[] memory ops) external;

  function manageUserBalance(IVault.UserBalanceOp[] memory ops) external payable;

  function queryBatchSwap(
    uint8 kind,
    IVault.BatchSwapStep[] memory swaps,
    address[] memory assets,
    IVault.FundManagement memory funds
  ) external returns (int256[] memory);

  function registerPool(uint8 specialization) external returns (bytes32);

  function registerTokens(bytes32 poolId, address[] memory tokens, address[] memory assetManagers)
    external;

  function setAuthorizer(address newAuthorizer) external;

  function setPaused(bool paused) external;

  function setRelayerApproval(address sender, address relayer, bool approved) external;

  function swap(
    IVault.SingleSwap memory singleSwap,
    IVault.FundManagement memory funds,
    uint256 limit,
    uint256 deadline
  ) external payable returns (uint256 amountCalculated);

  receive() external payable;
}

interface IVault {
  struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
  }

  struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address recipient;
    bool toInternalBalance;
  }

  struct JoinPoolRequest {
    address[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  struct PoolBalanceOp {
    uint8 kind;
    bytes32 poolId;
    address token;
    uint256 amount;
  }

  struct UserBalanceOp {
    uint8 kind;
    address asset;
    uint256 amount;
    address sender;
    address recipient;
  }

  struct SingleSwap {
    bytes32 poolId;
    uint8 kind;
    address assetIn;
    address assetOut;
    uint256 amount;
    bytes userData;
  }
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"contract IAuthorizer","name":"authorizer","type":"address"},{"internalType":"contract IWETH","name":"weth","type":"address"},{"internalType":"uint256","name":"pauseWindowDuration","type":"uint256"},{"internalType":"uint256","name":"bufferPeriodDuration","type":"uint256"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"contract IAuthorizer","name":"newAuthorizer","type":"address"}],"name":"AuthorizerChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"contract IERC20","name":"token","type":"address"},{"indexed":true,"internalType":"address","name":"sender","type":"address"},{"indexed":false,"internalType":"address","name":"recipient","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"ExternalBalanceTransfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"contract IFlashLoanRecipient","name":"recipient","type":"address"},{"indexed":true,"internalType":"contract IERC20","name":"token","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"feeAmount","type":"uint256"}],"name":"FlashLoan","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"user","type":"address"},{"indexed":true,"internalType":"contract IERC20","name":"token","type":"address"},{"indexed":false,"internalType":"int256","name":"delta","type":"int256"}],"name":"InternalBalanceChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"paused","type":"bool"}],"name":"PausedStateChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"poolId","type":"bytes32"},{"indexed":true,"internalType":"address","name":"liquidityProvider","type":"address"},{"indexed":false,"internalType":"contract IERC20[]","name":"tokens","type":"address[]"},{"indexed":false,"internalType":"int256[]","name":"deltas","type":"int256[]"},{"indexed":false,"internalType":"uint256[]","name":"protocolFeeAmounts","type":"uint256[]"}],"name":"PoolBalanceChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"poolId","type":"bytes32"},{"indexed":true,"internalType":"address","name":"assetManager","type":"address"},{"indexed":true,"internalType":"contract IERC20","name":"token","type":"address"},{"indexed":false,"internalType":"int256","name":"cashDelta","type":"int256"},{"indexed":false,"internalType":"int256","name":"managedDelta","type":"int256"}],"name":"PoolBalanceManaged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"poolId","type":"bytes32"},{"indexed":true,"internalType":"address","name":"poolAddress","type":"address"},{"indexed":false,"internalType":"enum IVault.PoolSpecialization","name":"specialization","type":"uint8"}],"name":"PoolRegistered","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"relayer","type":"address"},{"indexed":true,"internalType":"address","name":"sender","type":"address"},{"indexed":false,"internalType":"bool","name":"approved","type":"bool"}],"name":"RelayerApprovalChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"poolId","type":"bytes32"},{"indexed":true,"internalType":"contract IERC20","name":"tokenIn","type":"address"},{"indexed":true,"internalType":"contract IERC20","name":"tokenOut","type":"address"},{"indexed":false,"internalType":"uint256","name":"amountIn","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"amountOut","type":"uint256"}],"name":"Swap","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"poolId","type":"bytes32"},{"indexed":false,"internalType":"contract IERC20[]","name":"tokens","type":"address[]"}],"name":"TokensDeregistered","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"poolId","type":"bytes32"},{"indexed":false,"internalType":"contract IERC20[]","name":"tokens","type":"address[]"},{"indexed":false,"internalType":"address[]","name":"assetManagers","type":"address[]"}],"name":"TokensRegistered","type":"event"},{"inputs":[],"name":"WETH","outputs":[{"internalType":"contract IWETH","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"enum IVault.SwapKind","name":"kind","type":"uint8"},{"components":[{"internalType":"bytes32","name":"poolId","type":"bytes32"},{"internalType":"uint256","name":"assetInIndex","type":"uint256"},{"internalType":"uint256","name":"assetOutIndex","type":"uint256"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"bytes","name":"userData","type":"bytes"}],"internalType":"struct IVault.BatchSwapStep[]","name":"swaps","type":"tuple[]"},{"internalType":"contract IAsset[]","name":"assets","type":"address[]"},{"components":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"bool","name":"fromInternalBalance","type":"bool"},{"internalType":"address payable","name":"recipient","type":"address"},{"internalType":"bool","name":"toInternalBalance","type":"bool"}],"internalType":"struct IVault.FundManagement","name":"funds","type":"tuple"},{"internalType":"int256[]","name":"limits","type":"int256[]"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"batchSwap","outputs":[{"internalType":"int256[]","name":"assetDeltas","type":"int256[]"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"poolId","type":"bytes32"},{"internalType":"contract IERC20[]","name":"tokens","type":"address[]"}],"name":"deregisterTokens","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"poolId","type":"bytes32"},{"internalType":"address","name":"sender","type":"address"},{"internalType":"address payable","name":"recipient","type":"address"},{"components":[{"internalType":"contract IAsset[]","name":"assets","type":"address[]"},{"internalType":"uint256[]","name":"minAmountsOut","type":"uint256[]"},{"internalType":"bytes","name":"userData","type":"bytes"},{"internalType":"bool","name":"toInternalBalance","type":"bool"}],"internalType":"struct IVault.ExitPoolRequest","name":"request","type":"tuple"}],"name":"exitPool","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"contract IFlashLoanRecipient","name":"recipient","type":"address"},{"internalType":"contract IERC20[]","name":"tokens","type":"address[]"},{"internalType":"uint256[]","name":"amounts","type":"uint256[]"},{"internalType":"bytes","name":"userData","type":"bytes"}],"name":"flashLoan","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes4","name":"selector","type":"bytes4"}],"name":"getActionId","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getAuthorizer","outputs":[{"internalType":"contract IAuthorizer","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getDomainSeparator","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"},{"internalType":"contract IERC20[]","name":"tokens","type":"address[]"}],"name":"getInternalBalance","outputs":[{"internalType":"uint256[]","name":"balances","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"}],"name":"getNextNonce","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getPausedState","outputs":[{"internalType":"bool","name":"paused","type":"bool"},{"internalType":"uint256","name":"pauseWindowEndTime","type":"uint256"},{"internalType":"uint256","name":"bufferPeriodEndTime","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"poolId","type":"bytes32"}],"name":"getPool","outputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"enum IVault.PoolSpecialization","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"poolId","type":"bytes32"},{"internalType":"contract IERC20","name":"token","type":"address"}],"name":"getPoolTokenInfo","outputs":[{"internalType":"uint256","name":"cash","type":"uint256"},{"internalType":"uint256","name":"managed","type":"uint256"},{"internalType":"uint256","name":"lastChangeBlock","type":"uint256"},{"internalType":"address","name":"assetManager","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"poolId","type":"bytes32"}],"name":"getPoolTokens","outputs":[{"internalType":"contract IERC20[]","name":"tokens","type":"address[]"},{"internalType":"uint256[]","name":"balances","type":"uint256[]"},{"internalType":"uint256","name":"lastChangeBlock","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getProtocolFeesCollector","outputs":[{"internalType":"contract ProtocolFeesCollector","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"},{"internalType":"address","name":"relayer","type":"address"}],"name":"hasApprovedRelayer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"poolId","type":"bytes32"},{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"components":[{"internalType":"contract IAsset[]","name":"assets","type":"address[]"},{"internalType":"uint256[]","name":"maxAmountsIn","type":"uint256[]"},{"internalType":"bytes","name":"userData","type":"bytes"},{"internalType":"bool","name":"fromInternalBalance","type":"bool"}],"internalType":"struct IVault.JoinPoolRequest","name":"request","type":"tuple"}],"name":"joinPool","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"components":[{"internalType":"enum IVault.PoolBalanceOpKind","name":"kind","type":"uint8"},{"internalType":"bytes32","name":"poolId","type":"bytes32"},{"internalType":"contract IERC20","name":"token","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"internalType":"struct IVault.PoolBalanceOp[]","name":"ops","type":"tuple[]"}],"name":"managePoolBalance","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"components":[{"internalType":"enum IVault.UserBalanceOpKind","name":"kind","type":"uint8"},{"internalType":"contract IAsset","name":"asset","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"address","name":"sender","type":"address"},{"internalType":"address payable","name":"recipient","type":"address"}],"internalType":"struct IVault.UserBalanceOp[]","name":"ops","type":"tuple[]"}],"name":"manageUserBalance","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"enum IVault.SwapKind","name":"kind","type":"uint8"},{"components":[{"internalType":"bytes32","name":"poolId","type":"bytes32"},{"internalType":"uint256","name":"assetInIndex","type":"uint256"},{"internalType":"uint256","name":"assetOutIndex","type":"uint256"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"bytes","name":"userData","type":"bytes"}],"internalType":"struct IVault.BatchSwapStep[]","name":"swaps","type":"tuple[]"},{"internalType":"contract IAsset[]","name":"assets","type":"address[]"},{"components":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"bool","name":"fromInternalBalance","type":"bool"},{"internalType":"address payable","name":"recipient","type":"address"},{"internalType":"bool","name":"toInternalBalance","type":"bool"}],"internalType":"struct IVault.FundManagement","name":"funds","type":"tuple"}],"name":"queryBatchSwap","outputs":[{"internalType":"int256[]","name":"","type":"int256[]"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"enum IVault.PoolSpecialization","name":"specialization","type":"uint8"}],"name":"registerPool","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"poolId","type":"bytes32"},{"internalType":"contract IERC20[]","name":"tokens","type":"address[]"},{"internalType":"address[]","name":"assetManagers","type":"address[]"}],"name":"registerTokens","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"contract IAuthorizer","name":"newAuthorizer","type":"address"}],"name":"setAuthorizer","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"paused","type":"bool"}],"name":"setPaused","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"relayer","type":"address"},{"internalType":"bool","name":"approved","type":"bool"}],"name":"setRelayerApproval","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"components":[{"internalType":"bytes32","name":"poolId","type":"bytes32"},{"internalType":"enum IVault.SwapKind","name":"kind","type":"uint8"},{"internalType":"contract IAsset","name":"assetIn","type":"address"},{"internalType":"contract IAsset","name":"assetOut","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"bytes","name":"userData","type":"bytes"}],"internalType":"struct IVault.SingleSwap","name":"singleSwap","type":"tuple"},{"components":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"bool","name":"fromInternalBalance","type":"bool"},{"internalType":"address payable","name":"recipient","type":"address"},{"internalType":"bool","name":"toInternalBalance","type":"bool"}],"internalType":"struct IVault.FundManagement","name":"funds","type":"tuple"},{"internalType":"uint256","name":"limit","type":"uint256"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"swap","outputs":[{"internalType":"uint256","name":"amountCalculated","type":"uint256"}],"stateMutability":"payable","type":"function"},{"stateMutability":"payable","type":"receive"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.4. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IDepositHelper {
  function VERSION() external view returns (string memory);

  function depositToVault(address vault_, uint256 underlyingAmount_) external;

  function getAllRewards(address vault_) external;

  function salvage(address token_, uint256 amount_) external;

  function withdrawFromVault(address vault_, uint256 shareTokenAmount_) external;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"VERSION","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"vault_","type":"address"},{"internalType":"uint256","name":"underlyingAmount_","type":"uint256"}],"name":"depositToVault","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"vault_","type":"address"}],"name":"getAllRewards","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"token_","type":"address"},{"internalType":"uint256","name":"amount_","type":"uint256"}],"name":"salvage","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"vault_","type":"address"},{"internalType":"uint256","name":"shareTokenAmount_","type":"uint256"}],"name":"withdrawFromVault","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface ISmartVault {
  event AddedRewardToken(address indexed token);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event ContractInitialized(address controller, uint256 ts, uint256 block);
  event Deposit(address indexed beneficiary, uint256 amount);
  event Invest(uint256 amount);
  event RemovedRewardToken(address indexed token);
  event RewardAdded(address rewardToken, uint256 reward);
  event RewardDenied(address indexed user, address rewardToken, uint256 reward);
  event RewardMovedToController(address rewardToken, uint256 amount);
  event RewardPaid(address indexed user, address rewardToken, uint256 reward);
  event RewardRecirculated(address indexed token, uint256 amount);
  event RewardSentToController(address indexed token, uint256 amount);
  event Staked(address indexed user, uint256 amount);
  event StrategyAnnounced(address newStrategy, uint256 time);
  event StrategyChanged(address newStrategy, address oldStrategy);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event UpdatedAddressSlot(string indexed name, address oldValue, address newValue);
  event UpdatedBoolSlot(string indexed name, bool oldValue, bool newValue);
  event UpdatedUint256Slot(string indexed name, uint256 oldValue, uint256 newValue);
  event Withdraw(address indexed beneficiary, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);

  function DEPOSIT_FEE_DENOMINATOR() external view returns (uint256);

  function LOCK_PENALTY_DENOMINATOR() external view returns (uint256);

  function TO_INVEST_DENOMINATOR() external view returns (uint256);

  function VERSION() external view returns (string memory);

  function active() external view returns (bool);

  function addRewardToken(address rt) external;

  function allowance(address owner, address spender) external view returns (uint256);

  function alwaysInvest() external view returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);

  function availableToInvestOut() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function changeActivityStatus(bool _active) external;

  function changeAlwaysInvest(bool _active) external;

  function changeDoHardWorkOnInvest(bool _active) external;

  function changePpfsDecreaseAllowed(bool _value) external;

  function changeProtectionMode(bool _active) external;

  function controller() external view returns (address);

  function created() external view returns (uint256 ts);

  function createdBlock() external view returns (uint256 ts);

  function decimals() external view returns (uint8);

  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

  function deposit(uint256 amount) external;

  function depositAndInvest(uint256 amount) external;

  function depositFeeNumerator() external view returns (uint256);

  function depositFor(uint256 amount, address holder) external;

  function disableLock() external;

  function doHardWork() external;

  function doHardWorkOnInvest() external view returns (bool);

  function duration() external view returns (uint256);

  function earned(address rt, address account) external view returns (uint256);

  function earnedWithBoost(address rt, address account) external view returns (uint256);

  function exit() external;

  function getAllRewards() external;

  function getAllRewardsFor(address rewardsReceiver) external;

  function getPricePerFullShare() external view returns (uint256);

  function getReward(address rt) external;

  function getRewardTokenIndex(address rt) external view returns (uint256);

  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

  function initializeControllable(address __controller) external;

  function initializeSmartVault(
    string memory _name,
    string memory _symbol,
    address _controller,
    address __underlying,
    uint256 _duration,
    bool _lockAllowed,
    address _rewardToken,
    uint256 _depositFee
  ) external;

  function initializeVaultStorage(
    address _underlyingToken,
    uint256 _durationValue,
    bool __lockAllowed
  ) external;

  function isController(address _value) external view returns (bool);

  function isGovernance(address _value) external view returns (bool);

  function lastTimeRewardApplicable(address rt) external view returns (uint256);

  function lastUpdateTimeForToken(address) external view returns (uint256);

  function lockAllowed() external view returns (bool);

  function lockPenalty() external view returns (uint256);

  function lockPeriod() external view returns (uint256);

  function name() external view returns (string memory);

  function notifyRewardWithoutPeriodChange(address _rewardToken, uint256 _amount) external;

  function notifyTargetRewardAmount(address _rewardToken, uint256 amount) external;

  function overrideName(string memory value) external;

  function overrideSymbol(string memory value) external;

  function periodFinishForToken(address) external view returns (uint256);

  function ppfsDecreaseAllowed() external view returns (bool);

  function protectionMode() external view returns (bool);

  function rebalance() external;

  function removeRewardToken(address rt) external;

  function rewardPerToken(address rt) external view returns (uint256);

  function rewardPerTokenStoredForToken(address) external view returns (uint256);

  function rewardRateForToken(address) external view returns (uint256);

  function rewardTokens() external view returns (address[] memory);

  function rewardTokensLength() external view returns (uint256);

  function rewardsForToken(address, address) external view returns (uint256);

  function setLockPenalty(uint256 _value) external;

  function setLockPeriod(uint256 _value) external;

  function setStrategy(address newStrategy) external;

  function setToInvest(uint256 _value) external;

  function stop() external;

  function strategy() external view returns (address);

  function symbol() external view returns (string memory);

  function toInvest() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  function underlying() external view returns (address);

  function underlyingBalanceInVault() external view returns (uint256);

  function underlyingBalanceWithInvestment() external view returns (uint256);

  function underlyingBalanceWithInvestmentForHolder(address holder) external view returns (uint256);

  function underlyingUnit() external view returns (uint256);

  function userBoostTs(address) external view returns (uint256);

  function userLastDepositTs(address) external view returns (uint256);

  function userLastWithdrawTs(address) external view returns (uint256);

  function userLockTs(address) external view returns (uint256);

  function userRewardPerTokenPaidForToken(address, address) external view returns (uint256);

  function withdraw(uint256 numberOfShares) external;

  function withdrawAllToVault() external;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"token","type":"address"}],"name":"AddedRewardToken","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"controller","type":"address"},{"indexed":false,"internalType":"uint256","name":"ts","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"block","type":"uint256"}],"name":"ContractInitialized","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"beneficiary","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Deposit","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Invest","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"token","type":"address"}],"name":"RemovedRewardToken","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"rewardToken","type":"address"},{"indexed":false,"internalType":"uint256","name":"reward","type":"uint256"}],"name":"RewardAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"user","type":"address"},{"indexed":false,"internalType":"address","name":"rewardToken","type":"address"},{"indexed":false,"internalType":"uint256","name":"reward","type":"uint256"}],"name":"RewardDenied","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"rewardToken","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"RewardMovedToController","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"user","type":"address"},{"indexed":false,"internalType":"address","name":"rewardToken","type":"address"},{"indexed":false,"internalType":"uint256","name":"reward","type":"uint256"}],"name":"RewardPaid","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"token","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"RewardRecirculated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"token","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"RewardSentToController","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"user","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Staked","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"newStrategy","type":"address"},{"indexed":false,"internalType":"uint256","name":"time","type":"uint256"}],"name":"StrategyAnnounced","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"newStrategy","type":"address"},{"indexed":false,"internalType":"address","name":"oldStrategy","type":"address"}],"name":"StrategyChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"string","name":"name","type":"string"},{"indexed":false,"internalType":"address","name":"oldValue","type":"address"},{"indexed":false,"internalType":"address","name":"newValue","type":"address"}],"name":"UpdatedAddressSlot","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"string","name":"name","type":"string"},{"indexed":false,"internalType":"bool","name":"oldValue","type":"bool"},{"indexed":false,"internalType":"bool","name":"newValue","type":"bool"}],"name":"UpdatedBoolSlot","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"string","name":"name","type":"string"},{"indexed":false,"internalType":"uint256","name":"oldValue","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"newValue","type":"uint256"}],"name":"UpdatedUint256Slot","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"beneficiary","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Withdraw","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"user","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Withdrawn","type":"event"},{"inputs":[],"name":"DEPOSIT_FEE_DENOMINATOR","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"LOCK_PENALTY_DENOMINATOR","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"TO_INVEST_DENOMINATOR","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"VERSION","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"active","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"rt","type":"address"}],"name":"addRewardToken","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"alwaysInvest","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"availableToInvestOut","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bool","name":"_active","type":"bool"}],"name":"changeActivityStatus","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"_active","type":"bool"}],"name":"changeAlwaysInvest","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"_active","type":"bool"}],"name":"changeDoHardWorkOnInvest","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"_value","type":"bool"}],"name":"changePpfsDecreaseAllowed","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"_active","type":"bool"}],"name":"changeProtectionMode","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"controller","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"created","outputs":[{"internalType":"uint256","name":"ts","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"createdBlock","outputs":[{"internalType":"uint256","name":"ts","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"subtractedValue","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"deposit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"depositAndInvest","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"depositFeeNumerator","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"address","name":"holder","type":"address"}],"name":"depositFor","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"disableLock","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"doHardWork","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"doHardWorkOnInvest","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"duration","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"rt","type":"address"},{"internalType":"address","name":"account","type":"address"}],"name":"earned","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"rt","type":"address"},{"internalType":"address","name":"account","type":"address"}],"name":"earnedWithBoost","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"exit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"getAllRewards","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"rewardsReceiver","type":"address"}],"name":"getAllRewardsFor","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"getPricePerFullShare","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"rt","type":"address"}],"name":"getReward","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"rt","type":"address"}],"name":"getRewardTokenIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"addedValue","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"__controller","type":"address"}],"name":"initializeControllable","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"_name","type":"string"},{"internalType":"string","name":"_symbol","type":"string"},{"internalType":"address","name":"_controller","type":"address"},{"internalType":"address","name":"__underlying","type":"address"},{"internalType":"uint256","name":"_duration","type":"uint256"},{"internalType":"bool","name":"_lockAllowed","type":"bool"},{"internalType":"address","name":"_rewardToken","type":"address"},{"internalType":"uint256","name":"_depositFee","type":"uint256"}],"name":"initializeSmartVault","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_underlyingToken","type":"address"},{"internalType":"uint256","name":"_durationValue","type":"uint256"},{"internalType":"bool","name":"__lockAllowed","type":"bool"}],"name":"initializeVaultStorage","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_value","type":"address"}],"name":"isController","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_value","type":"address"}],"name":"isGovernance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"rt","type":"address"}],"name":"lastTimeRewardApplicable","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"lastUpdateTimeForToken","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lockAllowed","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lockPenalty","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lockPeriod","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_rewardToken","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"notifyRewardWithoutPeriodChange","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_rewardToken","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"notifyTargetRewardAmount","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"value","type":"string"}],"name":"overrideName","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"value","type":"string"}],"name":"overrideSymbol","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"periodFinishForToken","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"ppfsDecreaseAllowed","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"protectionMode","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"rebalance","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"rt","type":"address"}],"name":"removeRewardToken","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"rt","type":"address"}],"name":"rewardPerToken","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"rewardPerTokenStoredForToken","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"rewardRateForToken","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"rewardTokens","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"rewardTokensLength","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"rewardsForToken","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_value","type":"uint256"}],"name":"setLockPenalty","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_value","type":"uint256"}],"name":"setLockPeriod","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newStrategy","type":"address"}],"name":"setStrategy","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_value","type":"uint256"}],"name":"setToInvest","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"stop","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"strategy","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"toInvest","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"underlying","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"underlyingBalanceInVault","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"underlyingBalanceWithInvestment","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"holder","type":"address"}],"name":"underlyingBalanceWithInvestmentForHolder","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"underlyingUnit","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"userBoostTs","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"userLastDepositTs","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"userLastWithdrawTs","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"userLockTs","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"userRewardPerTokenPaidForToken","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"numberOfShares","type":"uint256"}],"name":"withdraw","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"withdrawAllToVault","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IStablePool {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);

  function decimals() external view returns (uint8);

  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function totalSupply() external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"subtractedValue","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"addedValue","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"address","name":"recipient","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"}]
*/