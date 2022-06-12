/**
 *Submitted for verification at polygonscan.com on 2022-06-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface ITokenLocker {
    function lock(address, uint256) external;
    function lock(address, uint256, uint256) external;
    function processExpiredLocks(bool) external;
    function getReward() external;
    function getReward(address) external;
    function rewardTokens() external view returns (address[] memory);
}

interface ISnapshotDelegation {
    function setDelegate(bytes32, address) external;
    function clearDelegate(bytes32) external;
    function delegation(address, bytes32) external;
}

interface IUpgradeSource {
  function finalizeUpgrade() external;
  function shouldUpgrade() external view returns (bool, address);
}

interface IVault {
    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    function underlying() external view returns (address);
    function strategy() external view returns (address);

    function setStrategy(address) external;
    function setVaultFractionToInvest(uint256) external;

    function deposit(uint256) external;
    function depositFor(address, uint256) external;

    function withdrawAll() external;
    function withdraw(uint256) external;

    function getReward() external;
    function getRewardByToken(address) external;
    function notifyRewardAmount(address, uint256) external;

    function underlyingUnit() external view returns (uint256);
    function getPricePerFullShare() external view returns (uint256);
    function underlyingBalanceWithInvestmentForHolder(address) external view returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;
    function rebalance() external;
}

/// @title Eternal Storage Pattern.
/// @author Chainvisions
/// @notice A mapping-based storage pattern, allows for collision-less storage.

contract EternalStorage {
    mapping(bytes32 => uint256) private uint256Storage;
    mapping(bytes32 => address) private addressStorage;
    mapping(bytes32 => bool) private boolStorage;

    function _setUint256(string memory _key, uint256 _value) internal {
        uint256Storage[keccak256(abi.encodePacked(_key))] = _value;
    }

    function _setAddress(string memory _key, address _value) internal {
        addressStorage[keccak256(abi.encodePacked(_key))] = _value;
    }

    function _setBool(string memory _key, bool _value) internal {
        boolStorage[keccak256(abi.encodePacked(_key))] = _value;
    }

    function _getUint256(string memory _key) internal view returns (uint256) {
        return uint256Storage[keccak256(abi.encodePacked(_key))];
    }

    function _getAddress(string memory _key) internal view returns (address) {
        return addressStorage[keccak256(abi.encodePacked(_key))];
    }

    function _getBool(string memory _key) internal view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked(_key))];
    }
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

contract Storage {

  address public governance;
  address public controller;

  constructor() {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Storage: Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "Storage: New governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "Storage: New controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

/**
 * @dev Contract for access control where the governance address specified
 * in the Storage contract can be granted access to specific functions
 * on a contract that inherits this contract.
 *
 * The difference between GovernableInit and Governable is that GovernableInit supports proxy
 * smart contracts.
 */

contract GovernableInit is Initializable {

  bytes32 internal constant _STORAGE_SLOT = 0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc;

  modifier onlyGovernance() {
    require(Storage(_storage()).isGovernance(msg.sender), "Governable: Not governance");
    _;
  }

  constructor() {
    assert(_STORAGE_SLOT == bytes32(uint256(keccak256("eip1967.governableInit.storage")) - 1));
  }

  function __Governable_init_(address _store) public initializer {
    _setStorage(_store);
  }

  function _setStorage(address newStorage) private {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newStorage)
    }
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "Governable: New storage shouldn't be empty");
    _setStorage(_store);
  }

  function _storage() internal view returns (address str) {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function governance() public view returns (address) {
    return Storage(_storage()).governance();
  }
}

/// @title Beluga Anchor Pool
/// @author Chainvisions
/// @notice A fixed rate swap contract for closely pegged tokens.
/// @dev We have to tokens, `base` and `pegged`. `base` is the token `pegged` is pegged to.
/// For instance, for a fBEETS/beBEETS anchor pool, `base` would be fBEETS and `pegged` would be beBEETS.

contract AssetAnchor is GovernableInit, IUpgradeSource, EternalStorage {
    using SafeTransferLib for IERC20;

    // Enum for handling reward liquidation.
    enum LiquidationHandling {
        SwapOnUniLike,
        VaultSharesSingleAsset,
        VaultSharesLiquidityToken
    }

    /// @notice Snapshot.page delegation contract.
    ISnapshotDelegation public constant SNAPSHOT_DELEGATION = ISnapshotDelegation(0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446);

    /// @notice Tokens farmed by `pegged` holding.
    /// @dev Since beTokens are interest bearing, we use our reserves to maximize our yield.
    IERC20[] public yield;

    /// @notice Method for handling liquidation for a specific token.
    mapping(IERC20 => LiquidationHandling) public liquidationHandling;

    /// @notice Router for liquidating a token on Uniswap-like AMMs.
    mapping(IERC20 => mapping(IERC20 => address)) public uniSwapRouter;

    /// @notice Liquidation route for liquidating a token on a Uniswap-like AMMs.
    mapping(IERC20 => mapping(IERC20 => address[])) public uniLiquidationRoute;

    /// @notice Emitted on a new anchor swap.
    event Swap(IERC20 indexed tokenIn, uint256 output);

    /// @notice Emitted when a new implementation upgrade is queued.
    event UpgradeAnnounced(address newImplementation);

    /// @notice Initializes the anchor pool.
    /// @param _store Storage contract for access control.
    /// @param _base Base token of the anchor pool.
    /// @param _pegged Pegged token of the anchor pool.
    function __Anchor_init(
        address _store,
        address _base,
        address _pegged
    ) external initializer {
        __Governable_init_(_store);
        _setBase(_base);
        _setPegged(_pegged);
        _setUpgradeTimelock(12 hours);
    }

    /// @notice Swaps `base` to `pegged`.
    /// @param _amountIn Amount of tokens to swap to `pegged`.
    function swapToPegged(uint256 _amountIn) external {
        IERC20 _base = base();
        IERC20 _pegged = pegged();
        // No matter what, we offer the same rate.
        uint256 outputAmount = (_amountIn * 102) / 100;
        require(_pegged.balanceOf(address(this)) >= outputAmount, "AssetAnchor: Insufficient reserves for pegged");

        _base.safeTransferFrom(msg.sender, address(this), _amountIn);
        _pegged.safeTransfer(msg.sender, outputAmount);
        emit Swap(_base, outputAmount);
    }

    /// @notice Swaps `pegged` to `base`.
    /// @param _amountIn Amount of tokens to swap to `base`.
    function swapFromPegged(uint256 _amountIn) external {
        IERC20 _base = base();
        IERC20 _pegged = pegged();
        // No matter what, we offer the same rate.
        uint256 outputAmount = (_amountIn * 995) / 1000;
        require(_base.balanceOf(address(this)) >= outputAmount, "AssetAnchor: Insufficient reserves for base");
        
        _pegged.safeTransferFrom(msg.sender, address(this), _amountIn);
        _base.safeTransfer(msg.sender, outputAmount);
        emit Swap(_pegged, outputAmount);
    }

    /// @notice Used for capital efficiency. Harvests yield from `pegged`.
    function doHardWork() external {
        // We keep track of these numbers to ensure we do not lose reserves.
        IERC20 _base = base();
        IERC20 _pegged = pegged();

        IERC20[] memory rewardTokens = yield; // Pegged is almost always interest-bearing.
        IVault(address(_pegged)).getReward();
        for(uint256 i; i < rewardTokens.length; i++) {
            IERC20 reward = rewardTokens[i];
            
            // Check if the token is a reserve token.
            if(address(reward) == address(_pegged)) {
                continue;
            } else if(address(reward) == address(_base)) {
                // For base
                continue;
            }
            
            // Now we can liquidate.
            uint256 rewardBal = reward.balanceOf(address(this));
            if(rewardBal == 0) continue;
            reward.safeTransfer(tx.origin, (rewardBal * 50) / 10000); // Incentive for maintaining capital efficiency.
            rewardBal = reward.balanceOf(address(this));

            // Determine the liquidation method.
            LiquidationHandling liqHandling = liquidationHandling[reward];
            if(liqHandling == LiquidationHandling.SwapOnUniLike) {
                IUniswapV2Router02(uniSwapRouter[reward][_base]).swapExactTokensForTokens(rewardBal, 0, uniLiquidationRoute[reward][_base], address(this), block.timestamp + 600);
            } else if (liqHandling == LiquidationHandling.VaultSharesSingleAsset) {
                // We assume shares mean `base` in a vault.
                IVault(address(reward)).withdraw(reward.balanceOf(address(this)));
            } else if (liqHandling == LiquidationHandling.VaultSharesLiquidityToken) {
                IVault(address(reward)).withdraw(rewardBal);
                reward = IERC20(IVault(address(reward)).underlying());
                rewardBal = reward.balanceOf(address(this));

                // Fetch reserves of the LP and remove liquidity.
                IERC20[] memory tokens = new IERC20[](2);
                tokens[0] = IERC20(IUniswapV2Pair(address(reward)).token0());
                tokens[1] = IERC20(IUniswapV2Pair(address(reward)).token1());
                reward.safeApprove(uniSwapRouter[reward][_base], 0);
                reward.safeApprove(uniSwapRouter[reward][_base], rewardBal);
                IUniswapV2Router02(uniSwapRouter[reward][_base]).removeLiquidity(address(tokens[0]), address(tokens[1]), rewardBal, 0, 0, address(this), block.timestamp + 600);

                // Liquidate token0 and token1.
                uint256[] memory tokenBalances = new uint256[](2); // The stack gets too deep so we must use an array.
                if(tokens[0] != _base) {
                    tokenBalances[0] = tokens[0].balanceOf(address(this));
                    IUniswapV2Router02 token0SwapRouter = IUniswapV2Router02(uniSwapRouter[tokens[0]][_base]);
                    tokens[0].safeApprove(address(token0SwapRouter), 0);
                    tokens[0].safeApprove(address(token0SwapRouter), tokenBalances[0]);

                    token0SwapRouter.swapExactTokensForTokens(tokenBalances[0], 0, uniLiquidationRoute[tokens[0]][_base], address(this), block.timestamp + 600);
                }

                if(tokens[1] != _base) {
                    tokenBalances[1] = tokens[1].balanceOf(address(this));
                    IUniswapV2Router02 token1SwapRouter = IUniswapV2Router02(uniSwapRouter[tokens[1]][_base]);
                    tokens[1].safeApprove(address(token1SwapRouter), 0);
                    tokens[1].safeApprove(address(token1SwapRouter), tokenBalances[1]);

                    token1SwapRouter.swapExactTokensForTokens(tokenBalances[1], 0, uniLiquidationRoute[tokens[1]][_base], address(this), block.timestamp + 600);
                }
            }
        }
    }

    /// @notice Delegates voting power on Snapshot.
    /// @param _space Space to delegate voting power on to governance.
    function delegate(bytes32 _space) external onlyGovernance {
        SNAPSHOT_DELEGATION.setDelegate(_space, governance());
    }

    /// @notice Finalizes or cancels upgrades by setting the next implementation address to 0.
    function finalizeUpgrade() external override onlyGovernance {
        _setNextImplementation(address(0));
        _setNextImplementationTimestamp(0);
    }

    /// @notice Whether or not the proxy should upgrade.
    /// @return If the proxy can be upgraded and the new implementation address.
    function shouldUpgrade() external view override returns (bool, address) {
        return (
            nextImplementationTimestamp() != 0
                && block.timestamp > nextImplementationTimestamp()
                && nextImplementation() != address(0),
            nextImplementation()
        );
    }

    /// @notice Sets liquidation handling method for a token.
    function setLiquidationHandling(IERC20 _rewardToken, LiquidationHandling _handling) public onlyGovernance {
        liquidationHandling[_rewardToken] = _handling;
    }

    /// @notice Sets the liquidation router for a token swap.
    /// @param _tokenIn Token to swap in from.
    /// @param _tokenOut Token to swap out to.
    /// @param _router Router used for swapping.
    function setLiquidationRouter(IERC20 _tokenIn, IERC20 _tokenOut, address _router) public onlyGovernance {
        uniSwapRouter[_tokenIn][_tokenOut] = _router;
    }

    /// @notice Sets the liquidation route for a token swap.
    /// @param _tokenIn Token to swap in from.
    /// @param _tokenOut Token to swap out to.
    /// @param _route Route for swapping from `tokenIn` to `tokenOut`.
    function setLiquidationRoute(IERC20 _tokenIn, IERC20 _tokenOut, address[] memory _route) public onlyGovernance {
        uniLiquidationRoute[_tokenIn][_tokenOut] = _route;
    }

    /// @notice Adds a yield token to the anchor.
    /// @param _yield Yield to add to the anchor.
    function addYield(IERC20 _yield) external onlyGovernance {
        yield.push(_yield);
    }

    /// @notice Schedules an upgrade to the vault.
    /// @param _impl Address of the new implementation.
    function scheduleUpgrade(address _impl) public onlyGovernance {
        _setNextImplementation(_impl);
        _setNextImplementationTimestamp(block.timestamp + upgradeTimelock());
        emit UpgradeAnnounced(_impl);
    }

    /// @notice Next implementation contract for the proxy.
    function nextImplementation() public view returns (address) {
        return _getAddress("nextImplementation");
    }

    /// @notice Timestamp of when the next upgrade can be executed.
    function nextImplementationTimestamp() public view returns (uint256) {
        return _getUint256("nextImplementationTimestamp");
    }

    /// @notice Timelock for contract upgrades.
    function upgradeTimelock() public view returns (uint256) {
        return _getUint256("upgradeTimelock");
    }

    /// @notice Base token of the pair.
    function base() public view returns (IERC20) {
        return IERC20(_getAddress("base"));
    }

    /// @notice Pegged token of the pair.
    function pegged() public view returns (IERC20) {
        return IERC20(_getAddress("pegged"));
    }

    /// @notice Incentive for managing capital efficiency.
    function efficiencyIncentive() public view returns (uint256) {
        return _getUint256("efficiencyIncentive");
    }

    function _setNextImplementation(address _address) internal {
        _setAddress("nextImplementation", _address);
    }

    function _setNextImplementationTimestamp(uint256 _value) internal {
        _setUint256("nextImplementationTimestamp", _value);
    }

    function _setUpgradeTimelock(uint256 _value) internal {
        _setUint256("upgradeTimelock", _value);
    }

    function _setBase(address _value) internal {
        _setAddress("base", _value);
    }

    function _setPegged(address _value) internal {
        _setAddress("pegged", _value);
    }
}