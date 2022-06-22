/**
 *Submitted for verification at polygonscan.com on 2022-06-22
*/

pragma solidity 0.8.6;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

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

interface ISolidlyRouter01 {
    // A standard Solidly route used for routing through pairs.
    struct Route {
        address from;
        address to;
        bool stable;
    }

    // Adds liquidity to a pair on Solidly
    function addLiquidity(address tokenA, address tokenB, bool stable, uint256 amountA, uint256 amountB, uint256 aMin, uint256 bMin, address to, uint256 deadline) external;
    // Swaps tokens on Solidly via a specific route.
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, Route[] memory routes, address to, uint256 deadline) external returns (uint256[] memory);
    // Swaps tokens on Solidly from A to B through only one pair.
    function swapExactTokensForTokensSimple(uint256 amountIn, uint256 amountOutMin, address tokenFrom, address tokenTo, bool stable, address to, uint256 deadline) external returns (uint256[] memory);
}

interface I0xLens {
    function penPoolByDystPool(address) external view returns (address);
    function stakingRewardsByDystPool(address) external view returns (address);
    function isPartner(address) external view returns (bool);
}

interface I0xPool {
    function depositLp(uint256) external;
    function withdrawLp(uint256) external;
}

interface IStrategy {
    function unsalvagableTokens(address tokens) external view returns (bool);
    
    function governance() external view returns (address);
    function controller() external view returns (address);
    function underlying() external view returns (address);
    function vault() external view returns (address);

    function withdrawAllToVault() external;
    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()
    function pendingYield() external view returns (uint256[] memory);

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function doHardWork() external;
    function depositArbCheck() external view returns(bool);
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

interface IRewardPool {
    function rewardsToken() external view returns (address);
    function stakingToken() external view returns (address);
    function duration() external view returns (uint256);

    function periodFinish() external view returns (uint256);
    function rewardRate() external view returns (uint256);
    function rewardPerTokenStored() external view returns (uint256);

    function stake(uint256 amountWei) external;

    // `balanceOf` would give the amount staked. 
    // As this is 1 to 1, this is also the holder's share
    function balanceOf(address holder) external view returns (uint256);
    // Total shares & total lpTokens staked
    function totalSupply() external view returns(uint256);

    function withdraw(uint256 amountWei) external;
    function exit() external;

    // Get claimed rewards
    function earned(address holder) external view returns (uint256);

    // Claim rewards
    function getReward() external;

    // Notifies rewards to the pool
    function notifyRewardAmount(uint256 _amount) external;
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

interface IController {
    function whitelist(address) external view returns (bool);
    function feeExemptAddresses(address) external view returns (bool);
    function greyList(address) external view returns (bool);
    function keepers(address) external view returns (bool);

    function doHardWork(address) external;
    function batchDoHardWork(address[] memory) external;

    function salvage(address, uint256) external;
    function salvageStrategy(address, address, uint256) external;

    function notifyFee(address, uint256) external;
    function profitSharingNumerator() external view returns (uint256);
    function profitSharingDenominator() external view returns (uint256);
}

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BEL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BEL#" part is a known constant
        // (0x42454C23): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x42454C23000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

/// @title Beluga Errors Library
/// @author Chainvisions
/// @author Forked and modified from Balancer (https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/solidity-utils/contracts/helpers/BalancerErrors.sol)
/// @notice Library for efficiently handling errors on Beluga contracts with reduced bytecode size additions.

library Errors {
    // Vault
    uint256 internal constant NUMERATOR_ABOVE_MAX_BUFFER = 0;
    uint256 internal constant UNDEFINED_STRATEGY = 1;
    uint256 internal constant CALLER_NOT_WHITELISTED = 2;
    uint256 internal constant VAULT_HAS_NO_SHARES = 3;
    uint256 internal constant SHARES_MUST_NOT_BE_ZERO = 4;
    uint256 internal constant LOSSES_ON_DOHARDWORK = 5;
    uint256 internal constant CANNOT_UPDATE_STRATEGY = 6;
    uint256 internal constant NEW_STRATEGY_CANNOT_BE_EMPTY = 7;
    uint256 internal constant VAULT_AND_STRATEGY_UNDERLYING_MUST_MATCH = 8;
    uint256 internal constant STRATEGY_DOES_NOT_BELONG_TO_VAULT = 9;
    uint256 internal constant CALLER_NOT_GOV_OR_REWARD_DIST = 10;
    uint256 internal constant NOTIF_AMOUNT_INVOKES_OVERFLOW = 11;
    uint256 internal constant REWARD_INDICE_NOT_FOUND = 12;
    uint256 internal constant REWARD_TOKEN_ALREADY_EXIST = 13;
    uint256 internal constant DURATION_CANNOT_BE_ZERO = 14;
    uint256 internal constant REWARD_TOKEN_DOES_NOT_EXIST = 15;
    uint256 internal constant REWARD_PERIOD_HAS_NOT_ENDED = 16;
    uint256 internal constant CANNOT_REMOVE_LAST_REWARD_TOKEN = 17;
    uint256 internal constant DENOMINATOR_MUST_BE_GTE_NUMERATOR = 18;
    uint256 internal constant CANNOT_UPDATE_EXIT_FEE = 19;
    uint256 internal constant CANNOT_TRANSFER_IMMATURE_TOKENS = 20;
    uint256 internal constant CANNOT_DEPOSIT_ZERO = 21;
    uint256 internal constant HOLDER_MUST_BE_DEFINED = 22;

    // VeManager
    uint256 internal constant GOVERNORS_ONLY = 23;
    uint256 internal constant CALLER_NOT_STRATEGY = 24;
    uint256 internal constant GAUGE_INFO_ALREADY_EXISTS = 25;
    uint256 internal constant GAUGE_NON_EXISTENT = 26;

    // Strategies
    uint256 internal constant CALL_RESTRICTED = 27;
    uint256 internal constant STRATEGY_IN_EMERGENCY_STATE = 28;
    uint256 internal constant REWARD_POOL_UNDERLYING_MISMATCH = 29;
    uint256 internal constant UNSALVAGABLE_TOKEN = 30;

    // Strategy splitter.
    uint256 internal constant ARRAY_LENGTHS_DO_NOT_MATCH = 31;
    uint256 internal constant WEIGHTS_DO_NOT_ADD_UP = 32;
    uint256 internal constant REBALANCE_REQUIRED = 33;
    uint256 internal constant INDICE_DOES_NOT_EXIST = 34;

    // Strategy-specific
    uint256 internal constant WITHDRAWAL_WINDOW_NOT_ACTIVE = 35;

    // 0xDAO Partnership Staking.
    uint256 internal constant CANNOT_WITHDRAW_MORE_THAN_STAKE = 36;

    // Active management strategies.
    uint256 internal constant TX_ORIGIN_NOT_PERMITTED = 37;
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

contract ControllableInit is GovernableInit {

  constructor() {}

  function __Controllable_init(address _storage) public initializer {
    __Governable_init_(_storage);
  }

  modifier onlyController() {
    require(Storage(_storage()).isController(msg.sender), "Controllable: Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((Storage(_storage()).isController(msg.sender) || Storage(_storage()).isGovernance(msg.sender)),
      "Controllable: The caller must be controller or governance");
    _;
  }

  function controller() public view returns (address) {
    return Storage(_storage()).controller();
  }
}

// SPDX-License-Identifier: UNLICENSED

contract BaseStrategyStorage {
    mapping(bytes32 => uint256) private uint256Storage;
    mapping(bytes32 => address) private addressStorage;
    mapping(bytes32 => bool) private boolStorage;

    function underlying() public view returns (address) {
        return _getAddress("underlying");
    }

    function vault() public view returns (address) {
        return _getAddress("vault");
    }

    function rewardPool() public view returns (address) {
        return _getAddress("rewardPool");
    }

    function sell() public view returns (bool) {
        return _getBool("sell");
    }

    function sellFloor() public view returns (uint256) {
        return _getUint256("sellFloor");
    }

    function pausedInvesting() public view returns (bool) {
        return _getBool("pausedInvesting");
    }

    function nextImplementation() public view returns (address) {
        return _getAddress("nextImplementation");
    }

    function nextImplementationTimestamp() public view returns (uint256) {
        return _getUint256("nextImplementationTimestamp");
    }

    function timelockDelay() public view returns (uint256) {
        return _getUint256("timelockDelay");
    }

    function _setUnderlying(address _value) internal {
        _setAddress("underlying", _value);
    }

    function _setVault(address _value) internal {
        _setAddress("vault", _value);
    }

    function _setRewardPool(address _value) internal {
        _setAddress("rewardPool", _value);
    }

    function _setSell(bool _value) internal {
        _setBool("sell", _value);
    }

    function _setSellFloor(uint256 _value) internal {
        _setUint256("sellFloor", _value);
    }

    function _setPausedInvesting(bool _value) internal {
        _setBool("pausedInvesting", _value);
    }

    function _setNextImplementation(address _value) internal {
        _setAddress("nextImplementation", _value);
    }

    function _setNextImplementationTimestamp(uint256 _value) internal {
        _setUint256("nextImplementationTimestamp", _value);
    }

    function _setTimelockDelay(uint256 _value) internal {
        _setUint256("timelockDelay", _value);
    }

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

/// @title Base Strategy
/// @author Chainvisions
/// @notice Base contract for Beluga strategies.

abstract contract BaseStrategy is ControllableInit, BaseStrategyStorage {
    using SafeTransferLib for IERC20;

    /// @notice A list of reward tokens farmed by the strategy.
    address[] internal _rewardTokens;

    /// @notice Emitted when performance fee collection is skipped.
    event ProfitsNotCollected(bool sell, bool floor);

    /// @notice Emitted when performance fees are collected by the strategy.
    event ProfitLogInReward(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);

    modifier restricted {
        _require(msg.sender == vault() || msg.sender == controller()
        || msg.sender == governance(),
        Errors.CALL_RESTRICTED);
        _;
    }

    // This is only used in `investAllUnderlying()`.
    // The user can still freely withdraw from the strategy.
    modifier onlyNotPausedInvesting {
        _require(!pausedInvesting(), Errors.STRATEGY_IN_EMERGENCY_STATE);
        _;
    }

    /// @notice Initializes the strategy proxy.
    /// @param _storage Address of the storage contract.
    /// @param _underlying Underlying token of the strategy.
    /// @param _vault Address of the strategy's vault.
    /// @param _rewardPool Address of the reward pool.
    /// @param _rewards Addresses of the reward tokens.
    /// @param _sell Whether or not `_rewardToken` should be liquidated.
    /// @param _sellFloor Minimum amount of `_rewardToken` to liquidate rewards.
    /// @param _timelockDelay Timelock for changing the proxy's implementation. 
    function initialize(
        address _storage,
        address _underlying,
        address _vault,
        address _rewardPool,
        address[] memory _rewards,
        bool _sell,
        uint256 _sellFloor,
        uint256 _timelockDelay
    ) public initializer {
        __Controllable_init(_storage);
        _setUnderlying(_underlying);
        _setVault(_vault);
        _setRewardPool(_rewardPool);

        _rewardTokens = _rewards;

        _setSell(_sell);
        _setSellFloor(_sellFloor);
        _setTimelockDelay(_timelockDelay);
        _setPausedInvesting(false);
    }

    /// @notice Collects protocol fees and sends them to the Controller.
    /// @param _rewardBalance The amount of rewards generated that is to have fees taken from.
    function notifyProfitInRewardToken(address _reward, uint256 _rewardBalance) internal {
        // Avoid additional SLOAD costs by reading the Controller from memory.
        IController _controller = IController(controller());

        if(_rewardBalance > 0 ){
            uint256 feeAmount = (_rewardBalance * _controller.profitSharingNumerator()) / _controller.profitSharingDenominator();
            emit ProfitLogInReward(_rewardBalance, feeAmount, block.timestamp);
            IERC20(_reward).safeApprove(address(_controller), 0);
            IERC20(_reward).safeApprove(address(_controller), feeAmount);

            _controller.notifyFee(
                _reward,
                feeAmount
            );
        } else {
            emit ProfitLogInReward(0, 0, block.timestamp);
        }
    }

    /// @notice Determines if the proxy can be upgraded.
    /// @return If an upgrade is possible and the address of the new implementation
    function shouldUpgrade() external view returns (bool, address) {
        return (
            nextImplementationTimestamp() != 0
                && block.timestamp > nextImplementationTimestamp()
                && nextImplementation() != address(0),
            nextImplementation()
        );
    }

    /// @notice A method for fetching the strategy's current pending yields.
    /// @return The current pending yield of the strategy.
    function pendingYield() external virtual view returns (uint256[] memory) {}

    /// @notice Schedules an upgrade to the strategy proxy.
    function scheduleUpgrade(address _impl) public onlyGovernance {
        _setNextImplementation(_impl);
        _setNextImplementationTimestamp(block.timestamp + timelockDelay());
    }

    /// @notice Adds a reward token to the strategy contract.
    /// @param _rewardToken Reward token to add to the contract.
    function addRewardToken(address _rewardToken) public onlyGovernance {
        _rewardTokens.push(_rewardToken);
    }

    /// @notice Removes a reward token from the strategy contract.
    /// @param _rewardToken Reward token to remove from the contract.
    function removeRewardToken(address _rewardToken) public onlyGovernance {
        // First we must find the index of the reward token in the array.
        bool didFindIndex;
        uint256 rewardIndex;
        for(uint256 i; i < _rewardTokens.length; i++) {
            if(_rewardTokens[i] == _rewardToken) {
                rewardIndex = i;
                didFindIndex = true;
            }
        }
        // If we cannot find it, we must revert the call.
        _require(didFindIndex, Errors.REWARD_INDICE_NOT_FOUND);

        // Now we can move the reward token to the last indice of the array and
        // pop the array, removing the reward token from the entire array.
        _rewardTokens[rewardIndex] = _rewardTokens[_rewardTokens.length - 1];
        _rewardTokens.pop();
    }

    /// @notice A list of all of the reward tokens on the strategy.
    /// @return The full `_rewardTokens` array.
    function rewardTokens() public view returns (address[] memory) {
        return (_rewardTokens);
    }

    function _finalizeUpgrade() internal {
        _setNextImplementation(address(0));
        _setNextImplementationTimestamp(0);
    }

    function _liquidateReward() internal {
        address[] memory rewards = _rewardTokens;
        uint256 nIndices = rewards.length;
        uint256[] memory rewardBalances = new uint256[](nIndices);
        for(uint256 i; i < nIndices; i++) {
            address reward = rewards[i];
            uint256 rewardBalance = IERC20(reward).balanceOf(address(this));

            // Check if the reward is enough for liquidation.
            bool _sell = sell();
            uint256 _sellFloor = sellFloor();
            if(!_sell || rewardBalance < _sellFloor) {
                emit ProfitsNotCollected(_sell, rewardBalance < _sellFloor);
                return;
            }
            
            // Notify performance fees.
            notifyProfitInRewardToken(reward, rewardBalance);

            // Push the balance after notifying fees.
            rewardBalances[i] = IERC20(reward).balanceOf(address(this));
        }

        _handleLiquidation(rewardBalances);
    }

    function _handleLiquidation(uint256[] memory _balances) internal virtual;

    function _isRewardToken(address _token) internal view returns (bool) {
        bool isReward;
        for(uint256 i; i < _rewardTokens.length; i++) {
            if(_rewardTokens[i] == _token) {
                isReward = true;
            }
        }

        return isReward;
    }
}

/// @title 0xDAO Maximizer Strategy
/// @author Chainvisions
/// @notice Maximizer strategy for 0xDAO.

contract Strategy0xDAOMaximizer is BaseStrategy {
    using SafeTransferLib for IERC20;

    // Structure for pairs, used to evade stack too deep errors. (-_-)
    struct Pair {
        address token0;
        address token1;
        uint256 toToken0;
        uint256 toToken1;
    }

    // Structure for storing token liquidation routes.
    struct SwapConfiguration {
        bool swapLess;
        bool singlePair;
        bool stableswap;
    }

    /// @notice Configuration for a specific Solidly swap.
    mapping(address => mapping(address => SwapConfiguration)) public swapConfig;

    /// @notice Routes for liquidation on Solidly.
    mapping(address => mapping(address => ISolidlyRouter01.Route[])) public routes;

    /// @notice Router contract for Solidly.
    ISolidlyRouter01 public constant SOLIDLY_ROUTER = ISolidlyRouter01(0xbE75Dd16D029c6B32B7aD57A0FD9C1c20Dd2862e);

    /// @notice 0xLens contract for reading DAO data.
    I0xLens public constant OX_LENS = I0xLens(0x1432c3553FDf7FBD593a84B3A4d380c643cbf7a2);

    /// @notice Initializes the strategy contract.
    /// @param _storage Storage contract for access control.
    /// @param _underlying Underlying token of the strategy.
    /// @param _vault Vault contract for the strategy.
    /// @param _rewards Vault reward tokens.
    function __Strategy_init(
        address _storage,
        address _underlying,
        address _vault,
        address[] memory _rewards,
        address _stakingRewards,
        bool _stableswap,
        address _targetVault
    )
    public initializer {
        BaseStrategy.initialize(
            _storage,
            _underlying,
            _vault,
            address(0),
            _rewards,
            true,
            1e2,
            12 hours
        );
        _setStableswap(_stableswap);
        _setOxPool(OX_LENS.penPoolByDystPool(_underlying));
        _setRewardPool(_stakingRewards);
        _setTargetVault(_targetVault);
    }

    /// @notice Harvests yields earned from farming and compounds them into
    /// the target token, this being either the underlying or target vault depending
    /// on if the vault is a maximizer or not.
    function doHardWork() external onlyNotPausedInvesting restricted {
        IRewardPool(rewardPool()).getReward();
        _liquidateReward();
        _notifyMaximizerRewards();
        _investAllUnderlying();
    }

    /// @notice Salvages tokens from the strategy contract. One thing that should be noted
    /// is that the only tokens that are possible to be salvaged from this contract are ones
    /// that are not part of `unsalvagableTokens()`, preventing a malicious owner from stealing tokens.
    /// @param _recipient Recipient of the tokens salvaged.
    /// @param _token Token to salvage.
    /// @param _amount Amount of `_token` to salvage from the strategy.
    function salvage(address _recipient, address _token, uint256 _amount) external restricted {
        _require(!unsalvagableTokens(_token), Errors.UNSALVAGABLE_TOKEN);
        IERC20(_token).transfer(_recipient, _amount);
    }

    /// @notice Finalizes the strategy upgrade by setting the pending implemention to 0.
    function finalizeUpgrade() external onlyGovernance {
        _finalizeUpgrade();
    }

    /// @notice Current amount of underlying invested in the strategy.
    function investedUnderlyingBalance() external view returns (uint256) {
        IRewardPool _rewardPool = IRewardPool(rewardPool());
        if (address(_rewardPool) == address(0)) {
            return IERC20(underlying()).balanceOf(address(this));
        }
        return (_rewardPool.balanceOf(address(this)) + IERC20(underlying()).balanceOf(address(this)));
    }

    /// @notice Withdrawals all underlying to the vault. This is used in the case of a strategy switch
    /// or potential bug that could undermine the safety of the users of the vault.
    function withdrawAllToVault() public restricted {
        IERC20 _underlying = IERC20(underlying());
        IRewardPool _rewardPool = IRewardPool(rewardPool());
        I0xPool _oxPool = I0xPool(oxPool());
        if(address(_rewardPool) != address(0)) {
            _rewardPool.exit();
            _oxPool.withdrawLp(IERC20(address(_oxPool)).balanceOf(address(this)));
        }
        _liquidateReward();
        _underlying.safeTransfer(vault(), _underlying.balanceOf(address(this)));
    }

    /// @notice Withdraws `amount` of underlying tokens to the vault.
    /// @param _amount Amount of tokens to withdraw from the pool.
    function withdrawToVault(uint256 _amount) public restricted {
        IERC20 _underlying = IERC20(underlying());
        IRewardPool stakingRewards = IRewardPool(rewardPool());
        // Typically there wouldn't be any amount here
        // however, it is possible because of the emergencyExit
        uint256 underlyingBalance = _underlying.balanceOf(address(this));
        if(_amount > underlyingBalance){
            // While we have the check above, we still using SafeMath below
            // for the peace of mind (in case something gets changed in between)
            uint256 needToWithdraw = (_amount - underlyingBalance);
            stakingRewards.withdraw(Math.min(stakingRewards.balanceOf(address(this)), needToWithdraw));
            I0xPool(oxPool()).withdrawLp(needToWithdraw);
        }

        _underlying.safeTransfer(vault(), _amount);
    }

    /// @notice Performs an emergency exit from the farming contract and
    /// pauses the strategy to prevent investing.
    function emergencyExit() public onlyGovernance {
        IRewardPool(rewardPool()).exit();
        I0xPool(oxPool()).withdrawLp(IERC20(oxPool()).balanceOf(address(this)));
        _setPausedInvesting(true);
    }

    /// @notice Continues investing into the reward pool.
    function continueInvesting() public onlyGovernance {
        _setPausedInvesting(false);
    }

    /// @notice Toggle for selling rewards or not.
    /// @param _sell Whether or not rewards should be sold.
    function setSell(bool _sell) public onlyGovernance {
        _setSell(_sell);
    }

    /// @notice Sets the minimum reward sell amount (or floor).
    /// @param _sellFloor The floor for selling rewards.
    function setSellFloor(uint256 _sellFloor) public onlyGovernance {
        _setSellFloor(_sellFloor);
    }

    /// @notice Checks whether or not a token can be salvaged from the strategy.
    /// @param _token Token to check for salvagability.
    /// @return Whether or not the token can be salvaged.
    function unsalvagableTokens(address _token) public view returns (bool) {
        return (_token == underlying() || _isRewardToken(_token));
    }

    /// @notice Whether or not the underlying LP is a stableswap LP.
    function stableswap() public view returns (bool) {
        return _getBool("stableswap");
    }

    /// @notice 0xPool contract for depositing into the DAO.
    function oxPool() public view returns (address) {
        return _getAddress("oxPool");
    }

    /// @notice Target vault to deposit into.
    function targetVault() public view returns (address) {
        return _getAddress("targetVault");
    }

    function _investAllUnderlying() internal onlyNotPausedInvesting {
        IERC20 lp = IERC20(underlying());
        I0xPool xPool = I0xPool(oxPool());
        IRewardPool stakingRewards = IRewardPool(rewardPool());

        uint256 underlyingBalance = IERC20(underlying()).balanceOf(address(this));
        if(underlyingBalance > 0) {
            lp.safeApprove(address(xPool), 0);
            lp.safeApprove(address(xPool), underlyingBalance);

            xPool.depositLp(underlyingBalance);
            IERC20(address(xPool)).safeApprove(address(stakingRewards), 0);
            IERC20(address(xPool)).safeApprove(address(stakingRewards), underlyingBalance);
            stakingRewards.stake(underlyingBalance);
        }
    }

    function _handleLiquidation(uint256[] memory _balances) internal override {
        address pool = IVault(targetVault()).underlying();
        Pair memory pair = Pair(IUniswapV2Pair(pool).token0(), IUniswapV2Pair(pool).token1(), 1, 1);

        address[] memory rewards = rewardTokens();
        for(uint256 i = 0; i < rewards.length; i++) {
            address reward = rewards[i];

            // Collect locking fee.
            IERC20(reward).safeTransfer(governance(), (_balances[i] * 150) / 10000);
            uint256 rewardBalance = IERC20(reward).balanceOf(address(this));

            pair.toToken0 = rewardBalance / 2;
            pair.toToken1 = rewardBalance - pair.toToken0;

            uint256 token0Amount;
            uint256 token1Amount;

            SwapConfiguration memory token0Route = swapConfig[reward][pair.token0];
            SwapConfiguration memory token1Route = swapConfig[reward][pair.token1];

            IERC20(reward).safeApprove(address(SOLIDLY_ROUTER), 0);
            IERC20(reward).safeApprove(address(SOLIDLY_ROUTER), rewardBalance);

            if(!token0Route.swapLess) {
                if(token0Route.singlePair) {
                    uint256[] memory amounts = SOLIDLY_ROUTER.swapExactTokensForTokensSimple(pair.toToken0, 0, reward, pair.token0, token0Route.stableswap, address(this), block.timestamp + 600);
                    token0Amount = amounts[amounts.length - 1];
                } else {
                    uint256[] memory amounts = SOLIDLY_ROUTER.swapExactTokensForTokens(pair.toToken0, 0, routes[reward][pair.token0], address(this), block.timestamp + 600);
                    token0Amount = amounts[amounts.length - 1];
                }
            } else {
                token0Amount = pair.toToken0;
            }

            if(!token1Route.swapLess) {
                if(token1Route.singlePair) {
                    uint256[] memory amounts = SOLIDLY_ROUTER.swapExactTokensForTokensSimple(pair.toToken1, 0, reward, pair.token1, token1Route.stableswap, address(this), block.timestamp + 600);
                    token1Amount = amounts[amounts.length - 1];
                } else {
                    uint256[] memory amounts = SOLIDLY_ROUTER.swapExactTokensForTokens(pair.toToken1, 0, routes[reward][pair.token1], address(this), block.timestamp + 600);
                    token1Amount = amounts[amounts.length - 1];
                }
            } else {
                token1Amount = pair.toToken1;
            }

            IERC20(pair.token0).safeApprove(address(SOLIDLY_ROUTER), 0);
            IERC20(pair.token0).safeApprove(address(SOLIDLY_ROUTER), token0Amount);

            IERC20(pair.token1).safeApprove(address(SOLIDLY_ROUTER), 0);
            IERC20(pair.token1).safeApprove(address(SOLIDLY_ROUTER), token1Amount);

            SOLIDLY_ROUTER.addLiquidity(pair.token0, pair.token1, stableswap(), token0Amount, token1Amount, 0, 0, address(this), block.timestamp + 600);
        }
    }

    function _notifyMaximizerRewards() internal {
        IVault vTarget = IVault(targetVault());
        IERC20 targetVaultUnderlying = IERC20(IVault(vTarget).underlying());
        IVault vaultToInject = IVault(vault());
        uint256 targetUnderlyingBalance = IERC20(targetVaultUnderlying).balanceOf(address(this));

        if(targetUnderlyingBalance > 0) {
            // Deposit the target token into the target vault.
            targetVaultUnderlying.safeApprove(address(vTarget), 0);
            targetVaultUnderlying.safeApprove(address(vTarget), targetUnderlyingBalance);
            vTarget.deposit(targetUnderlyingBalance);

            // Notify the rewards on the vault.
            uint256 targetVaultBalance = IERC20(address(vTarget)).balanceOf(address(this));
            IERC20(address(vTarget)).safeTransfer(address(vaultToInject), targetVaultBalance);
            vaultToInject.notifyRewardAmount(address(vTarget), targetVaultBalance);
        }
    }

    function _setStableswap(bool _value) internal {
        _setBool("stableswap", _value);
    }

    function _setOxPool(address _value) internal {
        _setAddress("oxPool", _value);
    }

    function _setTargetVault(address _value) internal {
        _setAddress("targetVault", _value);
    }
}

contract StrategyPenrose_USDC_FRAX is Strategy0xDAOMaximizer {

    address usdc_frax_diff;

    function initializeStrategy(
        address _store,
        address _vault
    ) public initializer {
        address usdc_frax_lp = address(0x53227c83a98Ba1035FEd912Da6cE26a0c11C7C66);
        address pen = address(0x9008D70A5282a936552593f410AbcBcE2F891A97);
        address dyst = address(0x39aB6574c289c3Ae4d88500eEc792AB5B947A5Eb);
        address wmatic = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

        address[] memory rewards = new address[](2);
        rewards[0] = dyst;
        rewards[1] = pen;
        
        __Strategy_init(
            _store, 
            usdc_frax_lp,
            _vault,
            rewards,
            0x3Fc54a65c1F125d48435279bDfe996a99A7bA2C7,
            false,
            0xf669895AB0493682090B0b5c11C774A483447C49
        );

        SwapConfiguration memory dystToPen;
        SwapConfiguration memory dystToWmatic;
        SwapConfiguration memory penToPen;
        SwapConfiguration memory penToWmatic;

        // DYST -> PEN
        dystToPen.swapLess = false;
        dystToPen.singlePair = false;
        dystToPen.stableswap = false;

        // DYST -> WMATIC
        dystToWmatic.swapLess = false;
        dystToWmatic.singlePair = true;
        dystToWmatic.stableswap = false;

        // PEN -> PEN
        penToPen.swapLess = true;
        penToPen.singlePair = true;
        penToPen.stableswap = false;

        // PEN -> WMATIC
        penToWmatic.swapLess = false;
        penToWmatic.singlePair = true;
        penToWmatic.stableswap = false;

        routes[dyst][pen].push(ISolidlyRouter01.Route(dyst, wmatic, false));
        routes[dyst][pen].push(ISolidlyRouter01.Route(wmatic, pen, false));

        swapConfig[dyst][pen] = dystToPen;
        swapConfig[dyst][wmatic] = dystToWmatic;
        swapConfig[pen][pen] = penToPen;
        swapConfig[pen][wmatic] = penToWmatic;

        _setSellFloor(1e2);
    }
}