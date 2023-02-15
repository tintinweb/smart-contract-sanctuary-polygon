// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import '../storage/DiamondFactoryStorageV3.sol';
import "../interfaces/IDiamondFactoryV3.sol";
import "../interfaces/IBalanceVaultV3.sol";
import "../interfaces/IDiamondFactoryHelper.sol";
import {AutomationRegistryInterface, State, Config} from "../interfaces/AutomationRegistryInterface1_2.sol";
import {LinkTokenInterface} from "../interfaces/LinkTokenInterface.sol";

interface KeeperRegistrarInterface {
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source,
        address sender
    ) external;
}

contract LimitOrder is OwnableUpgradeable {
    using SafeMath for uint256;

    struct Order {
        bool direction; // 大於還是小餘 tick
        int24 tick; // 觸發 tick
        address factory; // unibot factory address
        StrategyParams params; // unibot open position params
    }

    /// @notice unibot balance vault address
    address public balanceVault;

    /// @notice unibot helper address
    address public helper;

    /// @notice ERC677 link token address
    address public link;

    /// @notice chainlink automation registrar address
    address public registrar;

    /// @notice chainlink automation registry address
    address public registry;

    /// @notice chainlink automation register function signature
    bytes4 public registerSig;

    /// @notice chainlink automation register id
    uint256 public chainlinkId;

    /// @notice unibot open position merkle proof
    bytes32[] public proof;

    /// @notice limit orders
    Order[] public orders;

    /*=====================
    *       Events       *
    *====================*/
    event CreateOrder(address indexed token, bool direction, int24 tick, uint256 amount);
    event CancelOrder(address indexed token, bool direction, int24 tick, uint256 amount);
    event Withdraw(address indexed token, uint256 amount);
    event PerformUpkeep(address indexed token, bool direction, int24 tick, uint256 amount);

    constructor(
        address _balanceVault,
        address _helper,
        address _link,
        address _registrar,
        address _registry
    ) {
        init(
            _balanceVault,
            _helper,
            _link,
            _registrar,
            _registry
        );
    }

    function init(
        address _balanceVault,
        address _helper,
        address _link,
        address _registrar,
        address _registry
    ) public initializer {
        require(_balanceVault != address(0), "Invalid balance vault address");
        require(_helper != address(0), "Invalid helper address");
        require(_link != address(0), "Invalid link address");
        require(_registrar != address(0), "Invalid registrar address");
        require(_registry != address(0), "Invalid registry address");
        balanceVault = _balanceVault;
        helper = _helper;
        link = _link;
        registrar = _registrar;
        registry = _registry;
        registerSig = KeeperRegistrarInterface.register.selector;
        __Ownable_init();
    }

    function getLatestPriceTick(address _factory) external view returns (int24 latestTick) {
        return IDiamondFactoryV3(_factory).getLatestPrice();
    }

    function getAccountPositionIds(address _factory) public view returns (uint256[] memory) {
        return IDiamondFactoryV3(_factory).getAccountPositionIds(address(this));
    }

    function getPositionTokenAmount(address _factory, uint256 _positionId) public view returns (
        uint256 wantTokenAmount,
        uint256 borrowTokenAmount,
        uint256 wantTokenFee,
        uint256 borrowTokenFee
    ) {
        address uniswapPool = DiamondFactoryStorageV3(_factory).uniswapPool();
        bool wantTokenIsToken0 = DiamondFactoryStorageV3(_factory).wantTokenIsToken0();
        return IDiamondFactoryHelper(helper).getPositionTokenAmount(uniswapPool, _positionId, wantTokenIsToken0);
    }

    function getPositionValueMeasuredInWantToken(address _factory, uint256 _positionId) public view returns (uint256 positionValue) {
        address wantToken = DiamondFactoryStorageV3(_factory).wantToken();
        address borrowToken = DiamondFactoryStorageV3(_factory).borrowToken();
        address uniswapPool = DiamondFactoryStorageV3(_factory).uniswapPool();
        bool wantTokenIsToken0 = DiamondFactoryStorageV3(_factory).wantTokenIsToken0();
        uint32 oracleTimeWeightedSec = DiamondFactoryStorageV3(_factory).oracleTimeWeightedSec();
        return IDiamondFactoryHelper(helper).getPositionValueMeasuredInWantToken(wantToken, borrowToken, uniswapPool, _positionId, wantTokenIsToken0, oracleTimeWeightedSec);
    }

    function getWithdrawableBalance(address _token) public view returns (uint256 balance) {
        return IBalanceVaultV3(balanceVault).balances(_token, address(this));
    }

    /**
     * @notice create limit order, will pull token from user
     * @param _order limit order data
     */
    function createOrder(Order calldata _order) public onlyOwner {
        address wantTokenAddress = DiamondFactoryStorageV3(_order.factory).wantToken();
        IERC20(wantTokenAddress).transferFrom(owner(), address(this), _order.params.wantTokenAmount);
        if (!IBalanceVaultV3(balanceVault).userApproveFactories(address(this), _order.factory)) {
            IBalanceVaultV3(balanceVault).approve(_order.factory, wantTokenAddress);
        }
        orders.push(_order);
        emit CreateOrder(wantTokenAddress, _order.direction, _order.tick, _order.params.wantTokenAmount);
    }

    /**
     * @notice cancel limit order, will transfer token to user
     * @param _index the order index which user want to cancel
     */
    function cancelOrder(uint256 _index) public onlyOwner {
        Order memory order = orders[_index];
        address wantTokenAddress = DiamondFactoryStorageV3(order.factory).wantToken();
        IERC20(wantTokenAddress).transfer(owner(), order.params.wantTokenAmount);
        orders[_index] = orders[orders.length - 1];
        orders.pop();
        emit CancelOrder(wantTokenAddress, order.direction, order.tick, order.params.wantTokenAmount);
    }

    /**
     * @notice withdraw the balance in balance vault
     * @param _token the token which user want to withdraw
     * @dev when the order is closed/stopLoss/liquidate, the balance will stay in balance vault.
     * user have to withdraw the balance manually.
     */
    function withdraw(address _token) public onlyOwner {
        uint256 vaultBalance = IBalanceVaultV3(balanceVault).balances(_token, address(this));
        if (vaultBalance > 0) {
            IBalanceVaultV3(balanceVault).withdraw(_token, vaultBalance);
            IERC20(_token).transfer(owner(), vaultBalance);
            emit Withdraw(_token, vaultBalance);
        }
    }

    function closePosition(
        address _factory,
        uint256 _positionId,
        int24 _spotPriceTick,
        uint256 _slippage
    ) public onlyOwner {
        IDiamondFactoryV3(_factory).closePosition(
            _positionId,
            _spotPriceTick,
            _slippage,
            proof
        );
    }

    /**
     * @notice check is there any limit order should be triggered.
     * Will only return one order at a time.
     * @param checkData check upkeep data
     * @dev we do not use calldata at current design, so the calldata should be "0x".
     * Chainlink automation will call checkUpkeep with calldata to check
     * is there any limit order should be triggered. If checkUpkeep return true,
     * chainlink automation will call performUpkeep with the returned performData.
     * Since the chainlink automation gas limit is 5 million and performUpkeep cost around 3 million,
     * execute multiple limit order at the same time may exceed the gas limit, so we only handle
     * one order at atime.
     */
    function checkUpkeep(
        bytes calldata checkData
    )
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        for (uint256 i = 0; i < orders.length; i++) {
            int24 latestTick = IDiamondFactoryV3(orders[i].factory).getLatestPrice();
            if (orders[i].direction) {
                if(orders[i].tick <= latestTick) {
                    upkeepNeeded = true;
                    performData = abi.encode(i);
                    break;
                }
            } else {
                if (orders[i].tick >= latestTick) {
                    upkeepNeeded = true;
                    performData = abi.encode(i);
                    break;
                }
            }
        }
    }

    /**
     * @notice perform upkeep
     * @param _performData check upkeep data
     * @dev this function do not have access control, so we have to valid the input.
     * Since the chainlink automation gas limit is 5 million and performUpkeep cost around 3 million,
     * execute multiple limit order at the same time may exceed the gas limit, so we only handle
     * one order at atime.
     */
    function performUpkeep(bytes calldata _performData) external {
        (uint256 index) = abi.decode(
            _performData,
            (uint256)
        );
        Order memory order = orders[index];
        int24 latestTick = IDiamondFactoryV3(order.factory).getLatestPrice();
        require (
            (
                (order.direction && order.tick <= latestTick) ||
                (!order.direction && order.tick >= latestTick)
            ), "Invalid performData"
        );
        address wantTokenAddress = DiamondFactoryStorageV3(order.factory).wantToken();
        IERC20(wantTokenAddress).approve(balanceVault, order.params.wantTokenAmount);
        IBalanceVaultV3(balanceVault).deposit(wantTokenAddress, order.params.wantTokenAmount);
        IDiamondFactoryV3(order.factory).openPosition(orders[index].params, proof);
        orders[index] = orders[orders.length - 1];
        orders.pop();
        emit PerformUpkeep(wantTokenAddress, order.direction, order.tick, order.params.wantTokenAmount);
    }

    /**
     * @notice register this contract to chainlink automation
     * @param _name upkeep name
     * @param _encryptedEmail not in use, should be "0x"
     * @param _gasLimit performUpkeep gas limit, maximum is 5 milion
     * @param _adminAddress admin address which can fund the upkeep
     * @param _checkData check data used in checkUpkeep, should be "0x"
     * @param _amount amount of link to fund the upkeep, minimum is 5 ether
     * @param _source not in use, should be "0x"
     * @dev the chainlink automation document about these parameters
     * https://docs.chain.link/chainlink-automation/register-upkeep/#registerandpredictid-parameters
     */
    function register(
        string memory _name,
        bytes calldata _encryptedEmail,
        uint32 _gasLimit,
        address _adminAddress,
        bytes calldata _checkData,
        uint96 _amount,
        uint8 _source
    ) external {
        (State memory state, Config memory _c, address[] memory _k) = AutomationRegistryInterface(registry).getState();
        uint256 oldNonce = state.nonce;
        bytes memory payload = abi.encode(
            _name,
            _encryptedEmail,
            address(this),
            _gasLimit,
            _adminAddress,
            _checkData,
            _amount,
            _source,
            address(this)
        );
        LinkTokenInterface(link).transferAndCall(
            registrar,
            _amount,
            abi.encodePacked(registerSig, payload)
        );
        (state, _c, _k) = AutomationRegistryInterface(registry).getState();
        uint256 newNonce = state.nonce;
        if (newNonce == oldNonce + 1) {
            chainlinkId = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        registry,
                        uint32(oldNonce)
                    )
                )
            );
            // DEV - Use the upkeepID however you see fit
        } else {
            revert("auto-approve disabled");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../libraries/Positions.sol";

contract DiamondFactoryStorageV3 {
    /// @notice whether wantToken is token0 or not
    /// token0 and token1 comes from Uniswap, the token in the pair with lower address value will be
    /// token0 and the other is token1
    bool public wantTokenIsToken0;

    /// @notice Uniswap v3 liquidity pool address
    address public uniswapPool;

    /// @notice Uniswap position manager address
    address public constant UNI_POSITION_MANAGER =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    /// @notice Uniswap router address
    address public constant UNISWAP_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;

    /// @notice want token address
    address public wantToken;

    /// @notice borrow token address
    address public borrowToken;

    /// @notice lending pool address
    address public lendingPool;

    /// @notice global state controller address
    address public controller;

    /// @notice use to handle denomination
    uint256 public constant DENOMINATION_MULTIPLIER = 1e18;

    /// @notice Basis Points, 10000 means 100%
    uint256 public constant BPS = 10000;

    /// @notice 887272 is the maximum tick computed from log base 1.0001 of 2**128
    int24 public constant MAX_TICK = 887272;

    /// @notice -887272 is the minimum tick computed from log base 1.0001 of 2**-128
    int24 public constant MIN_TICK = -887272;

    /// @notice Basis Points, 10000 means 100%
    uint256 public liquidationThreshold;

    /// @notice time weighted oracle price period
    uint32 public oracleTimeWeightedSec;

    /// @notice pool tick spacing, provide liquidity range have to be multiple of TICK_SPACING, no remainder
    int24 public tickSpacing;

    /// @notice Uniswap pool swap fee, 500 means 0.05%, this is Uniswap setting, NOT calculate in BPS
    uint24 public uniFee;

    /// @notice the max available want amount when open position, to prevent lending
    /// pool balance not enough in beta test
    uint256 public openPositionMaximumAmount;

    /// @notice the min available want amount when open position
    uint256 public openPositionMinimumAmount;

    /// @notice max borrow ratio allowed in BPS, 20000 means 200%
    uint256 public borrowRatioMax;

    /// @notice min borrow ratio allowed in BPS, 3000 means 30%
    uint256 public borrowRatioMin;

    /// @notice max reserve ratio allowed in BPS, 3000 means 30%
    uint256 public reserveRatioMax;

    /// @notice stop loss fee amount in wantToken
    uint256 public stopLossFee;

    /// @notice provide liquidity multiplier
    uint256 public linearApproximationMultiplier;

    /// @notice vault is in emergency or not
    bool public isEmergency;

    /// @notice Uniswap position info
    mapping(uint256 => Positions.Position) public positions;

    /// @notice Uniswap position id by user
    mapping(address => uint256[]) public userPositionIds;

    /// @notice Total amount of positions
    uint256 public totalPositions;
}

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

struct StrategyParams {
    // want token amount
    uint256 wantTokenAmount;
    // borrow ratio measure in BPS, should between 5000 ~ 30000
    // for example, want amount = 100 USDC and reserveRatio is 0, borrow ratio is 20000,
    // means borrow worth 200% WETH and sell 50% WETH to USDC,
    // provide 150 USDC + worth 150 WETH to Uniswap
    uint256 borrowRatio;
    // current price tick when user send this tx
    int24 spotPriceTick;
    // price slippage tolerance measured in BPS
    uint256 slippage;
    // reserve ratio measure in BPS, should between 0 ~ 10000
    // for example, want amount = 100 USDC and reserveRatio is 5000, borrow ratio is 20000,
    // means borrow worth 200% WETH and sell (200 - 50) / 2 WETH to USDC,
    // provide 125 USDC + worth 125 WETH to Uniswap and left 50 USDC as reserve
    uint256 reserveRatio;
    // stop loss upper bound, keeper should can stop loss when price higher than this value
    int24 stopLossUpperPriceTick;
    // stop loss lower bound, keeper should can stop loss when price lower than this value
    int24 stopLossLowerPriceTick;
    // tick is uniswap v3 price calculation mechanism, can roughly covert 1000 tick ~= 10%
    // for example, if user want to provide liquidity in [current price * 0.85 ~ current price * 1.15]
    // this range, the tick range should be 1500
    int24 tickRange;
    // min amount0 when provide liquidity to uniswap
    uint256 amount0Min;
    // min amount1 when provide liquidity to uniswap
    uint256 amount1Min;
}

interface IDiamondFactoryV3 {
    /**
     * @notice set the liquidation threshold in BPS, 10000 means 100%
     * if position value * liquidation threshold < debt value then it will be liquidate
     * @dev only contract owner can execute
     * @param _liquidationThreshold the new liquidation threshold
     */
    function setLiquidationThreshold(uint256 _liquidationThreshold) external;

    /**
     * @notice set the oracle time weighted price period in sec
     * @dev only contract owner can execute
     * @param _oracleTimeWeightedSec time period in sec. Notice that it cannot be 0 or go beyond the oldest observation recorded in the pool
     */
    function setOracleTimeWeightedSec(uint32 _oracleTimeWeightedSec) external;

    /**
     * @notice get uniswap v3 latest price in tick
     */
    function getLatestPrice()
        external
        view
        returns (int24 latestTick);

    /**
     * @notice get the health factor of the position, if the health factor < 1 means it can be liquidated
     * health factor = position value * liquidation threshold / debt value
     * when calculating Diamond's position value, the reserveAmount also needs to be included
     * e.g if the reserve factor > 0, the position will leave some want token in the contract as reserveAmount,
     * which also needs to be included in the calculation of the position value
     * @dev will be reverted if the position with _positionId does not exist
     * @param _positionId the uniswap position id to be checked
     */
    function getHealthFactor(uint256 _positionId)
        external
        view
        returns (uint256);

    /**
     * @notice check the position value and the debt to decide if the position can be liquidated or not
     * @dev will be reverted if the position with _positionId does not exist
     * @param _positionId the uniswap position id to be liquidated
     */
    function canLiquidate(uint256 _positionId)
        external
        view
        returns (bool canLiquidate);

    /**
     * @notice check the position value and stop loss prices of the position to decide whether it can be executed stop loss
     * @dev will be reverted if the position with _positionId does not exist
     * @param _positionId the uniswap position id to be executed stop loss
     */
    function canStopLoss(uint256 _positionId)
        external
        view
        returns (bool canStopLoss);

    /**
     * @notice open Uniswap position
     * @param _strategyParams is the struct with strategy data
     * @param _proof merkle proof
     */
    function openPosition(
        StrategyParams calldata _strategyParams,
        bytes32[] memory _proof
    ) external;

    /**
     * @notice close the position
     * @param _positionId the uniswap position id to be closed
     * @param _spotPriceTick current price tick when user send this tx
     * @param _slippage price slippage tolerance measured in BPS
     * @param _proof merkle proof
     */
    function closePosition(
        uint256 _positionId,
        int24 _spotPriceTick,
        uint256 _slippage,
        bytes32[] memory _proof
    ) external;

    /**
     * @notice add collateral to a position
     * @param _amount add collateral amount
     * @param _positionId the uniswap position id to be added collateral
     * @param _proof merkle proof
     */
    function addCollateral(
        uint256 _amount,
        uint256 _positionId,
        bytes32[] memory _proof
    ) external;

    /**
     * @notice decrease collateral from a position
     * @param _amount decrease collateral amount
     * @param _positionId the uniswap position id to be decreased collateral
     * @param _proof the merkle proof
     */
    function decreaseCollateral(
        uint256 _amount,
        uint256 _positionId,
        bytes32[] memory _proof
    ) external;

    /**
     * @notice collect fee for the position
     * @param _positionId the uniswap position id to be collected fee from
     * @param _spotPriceTick current price tick when user send this tx
     * @param _slippage price slippage tolerance measured in BPS
     */
    function collectFee(
        uint256 _positionId,
        int24 _spotPriceTick,
        uint256 _slippage
    ) external;

    /**
     * @notice if canLiquidate == true, close the position and repay debt, will pay liquidation bonus to msg.sender
     * @param _account the targeted address to be liquidated
     * @param _positionId the uniswap position id to be liquidated
     * @param _spotPriceTick current price tick when user send this tx
     * @param _slippage price slippage tolerance measured in BPS
     */
    function liquidate(
        address _account,
        uint256 _positionId,
        int24 _spotPriceTick,
        uint256 _slippage
    ) external;

    /**
     * @notice if canStopLoss == true, close the position and repay debt
     * @param _account the targeted address to be executed stop loss
     * @param _positionId the uniswap position id to be executed stop loss
     * @param _spotPriceTick current price tick when user send this tx
     * @param _slippage price slippage tolerance measured in BPS
     */
    function stopLoss(
        address _account,
        uint256 _positionId,
        int24 _spotPriceTick,
        uint256 _slippage
    ) external;

    /**
     * @notice get the list of position id which are owned by the _account address
     * @param _account the address of the position owner
     */
    function getAccountPositionIds(address _account)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice update stop loss prices of the position
     * @param _positionId the uniswap position id to be updated
     * @param _stopLossUpperPriceTick the new stop loss upper price tick
     * @param _stopLossLowerPriceTick the new stop loss lower price tick
     * @param _proof the merkle proof
     */
    function updateStopLossPrice(
        uint256 _positionId,
        int24 _stopLossUpperPriceTick,
        int24 _stopLossLowerPriceTick,
        bytes32[] memory _proof
    ) external;

    /**
     * @notice remove token which is not want or borrow asset (token) from this contract
     * @param _token the address of the token
     * @param _amount the amount of the token
     */
    function sweep(address _token, uint256 _amount) external;

    /**
     * @notice set open position max wantToken amount
     * @dev only contract owner can execute
     * @param _openPositionMaximumAmount open position max wantToken amount
     */
    function setOpenPositionMaximumAmount(uint256 _openPositionMaximumAmount)
        external;

    /**
     * @notice set open position min wantToken amount
     * @dev only contract owner can execute
     * @param _openPositionMinimumAmount open position min wantToken amount
     */
    function setOpenPositionMinimumAmount(uint256 _openPositionMinimumAmount)
        external;

    /**
     * @notice set the max borrow ratio that the user can borrow
     * @dev only contract owner can execute
     * @param _borrowRatioMax the max borrow ratio
     */
    function setBorrowRatioMax(uint256 _borrowRatioMax) external;

    /**
     * @notice set min borrow ratio user can have
     * @param _borrowRatioMin min borrow ratio
     */
    function setBorrowRatioMin(uint256 _borrowRatioMin) external;

    /**
     * @notice set the max reserve ratio that the user can have
     * @dev only contract owner can execute
     * @param _reserveRatioMax the max reserve ratio
     */
    function setReserveRatioMax(uint256 _reserveRatioMax) external;

    /**
     * @notice set the stop loss fee
     * @dev only contract owner can execute
     * @param _fee the amount of stop loss fee
     */
    function setStopLossFee(uint256 _fee) external;

    /**
     * @notice set the emergency state, will disable deposit/withdraw/transferBalanceFromVault if the state is emergency
     * @dev only contract owner can execute
     * @param _isEmergency is emergency state or not
     */
    function setEmergencyState(bool _isEmergency) external;

    /**
     * @notice set global state management contract
     * @dev only contract owner can execute
     * @param _controller the address of the management contract
     */
    function setController(address _controller) external;

    /**
     * @notice set provide liquidity linear approximation multiplier
     * @dev only contract owner can execute
     * @param _linearApproximationMultiplier provide liquidity linear approximation multiplier
     */
    function setLinearApproximationMultiplier(
        uint256 _linearApproximationMultiplier
    ) external;
}

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IBalanceVaultV3 {
    /**
     * @notice vault is in emergency or not
     */
    function isEmergency() external view returns (bool);

    /**
     * @notice check if the token is in supportTokens
     * @param _token the address of the token
     */
    function supportTokens(address _token) external view returns (bool);

    /**
     * @notice get user token balance in the vault
     * mapping(token address => mapping(user address => balance))
     * @param _token the address of the token
     * @param _account the address of the user
     */
    function balances(address _token, address _account)
        external
        view
        returns (uint256);

    /**
     * @notice check if the _factory with _token is in whiteFactories, only whitelisted factory can take _token to open position
     * mapping(factory => mapping(token address => bool))
     * @param _factory the address of the factory
     * @param _token the address of the token
     */
    function whiteFactories(address _factory, address _token)
        external
        view
        returns (bool);

    /**
     * @notice check if user gave approval for factory to use their balance
     * mapping(user => mapping(factory => bool))
     * @param _account the address of the user
     * @param _factory the address of the factory
     */
    function userApproveFactories(address _account, address _factory)
        external
        view
        returns (bool);

    /**
     * @notice allow the owner to set the emergency state, deposit/withdraw/transferBalanceFromVault will be disabled if the state is emergency
     * @dev only contract owner can change the emergency state
     * @param _isEmergency state is emergency or not
     */
    function setEmergencyState(bool _isEmergency) external;

    /**
     * @notice add the token into supportTokens
     * @dev only contract owner can add the token
     * @param _token address of the token that needs to be added
     */
    function addSupportToken(address _token) external;

    /**
     * @notice remove the supported token from supportTokens
     * @dev only contract owner can remove the token
     * @param _token address of the token that needs to be removed
     */
    function removeSupportToken(address _token) external;

    /**
     * @notice add factory to whiteFactories, allowing factory to use _token in this vault
     * @dev only contract owner can add the factory
     * @param _factory the factory address that needs to be added
     * @param _token the address of the token used in factory
     */
    function addWhiteFactory(address _factory, address _token) external;

    /**
     * @notice remove the factory from whiteFactories
     * @dev only contract owner can remove the factory
     * @param _factory the factory address that needs to be removed
     * @param _token the address of the token used in factory
     */
    function removeWhiteFactory(address _factory, address _token) external;

    /**
     * @notice allow the msg.sender to give approval for the _factory to use its balance
     * @param _factory the address of the factory
     * @param _token the address of the token used in factory
     */
    function approve(address _factory, address _token) external;

    /**
    * @notice set commitedProxyDeployer as proxyDeployer
    * @param _proxyDeployer new proxy deployer address
    */
    function setProxyDeployer(address _proxyDeployer) external;

    /**
     * @notice allow the msg.sender to withdraw approval for the _factory to use its balance
     * @param _factory the address of the factory
     * @param _token the address of the token used in factory
     */
    function disapprove(address _factory, address _token) external;

    /**
     * @notice get account's token balance
     * @param _account account address
     * @param _token token address
     */
    function getAccountBalance(address _account, address _token)
        external
        view
        returns (uint256 balance);

    /**
     * @notice deposit token into the vault
     * @dev can only be executed in the non-emergency state
     * @param _token token address
     * @param _amount deposit amount
     */
    function deposit(address _token, uint256 _amount) external;

    /**
     * @notice withdraw token from the vault
     * @dev can only be executed in the non-emergency state
     * @param _token token address
     * @param _amount withdraw amount
     */
    function withdraw(address _token, uint256 _amount) external;

    /**
     * @notice transfer token from vault to factory, only whiteFactories can call this function
     * @dev can only be executed in the non-emergency state
     * @param _account the user address which will account for this transfer
     * @param _token the address of the token to be transferred
     * @param _amount the amount of the token to be transferred
     */
    function transferBalanceFromVault(
        address _account,
        address _token,
        uint256 _amount
    ) external;

    /**
     * @notice transfer token from factory to vault, only whiteFactories can call this function
     * @param _account the user address which will account for this transfer
     * @param _token the address of the token to be transferred
     * @param _amount the amount of the token to be transferred
     */
    function transferBalanceToVault(
        address _account,
        address _token,
        uint256 _amount
    ) external;

    /**
     * @notice remove the token which is not the managed asset (token) of the vault
     * @param _token token address
     * @param _amount token amount
     */
    function sweep(address _token, uint256 _amount) external;
}

pragma solidity 0.7.6;

interface IDiamondFactoryHelper {
    /**
     * @notice Get position's token amount and fee amount
     * @param _uniswapPool the address of the uniswap v3 pool
     * @param _positionId the uniswap v3 position id
     * @param _wantTokenIsToken0 whether the wantToken is token0 or not
     */
    function getPositionTokenAmount(
        address _uniswapPool,
        uint256 _positionId,
        bool _wantTokenIsToken0
    )
        external
        view
        returns (
            uint256 wantTokenAmount,
            uint256 borrowTokenAmount,
            uint256 wantTokenFee,
            uint256 borrowTokenFee
        );

    /**
     * @notice Calculate how much should we borrow from the lending pool
     * @param _wantToken the address of the want token
     * @param _borrowToken the address of the borrow token
     * @param _wantTokenBalance the balance of the want token
     * @param _tick current uniswap pool tick
     * @param _borrowRatio borrow ratio measured in BPS
     */
    function calculateBorrowAmount(
        address _wantToken,
        address _borrowToken,
        uint256 _wantTokenBalance,
        int24 _tick,
        uint256 _borrowRatio
    ) external view returns (uint256 quoteAmount, uint256 borrowAmount);

    /**
     * @notice Get position value measured in want token
     * @param _wantToken the address of the want token
     * @param _borrowToken the address of the borrow token
     * @param _uniswapPool the address of the uniswap pool which the position is at
     * @param _positionId the uniswap position id
     * @param _wantTokenIsToken0 whether the want token is token0 or not
     * @param _oracleTimeWeightedSec oracle time weighted second
     */
    function getPositionValueMeasuredInWantToken(
        address _wantToken,
        address _borrowToken,
        address _uniswapPool,
        uint256 _positionId,
        bool _wantTokenIsToken0,
        uint32 _oracleTimeWeightedSec
    ) external view returns (uint256 positionValue);

    /**
     * @notice Get borrow debt value measured in want token
     * @param _borrower the address of the borrower
     * @param _wantToken the address of the want token
     * @param _borrowToken the address of the borrow token
     * @param _uniswapPool the address of the uniswap pool which the position is at
     * @param _lendingPool the address of the lending pool which the position borrowed from
     * @param _borrowId the borrow id of the position
     * @param _oracleTimeWeightedSec oracle time weighted second
     */
    function getDebtValueMeasuredInWantToken(
        address _borrower,
        address _wantToken,
        address _borrowToken,
        address _uniswapPool,
        address _lendingPool,
        uint256 _borrowId,
        uint32 _oracleTimeWeightedSec
    ) external view returns (uint256 debtValue);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member blockCountPerTurn number of blocks each oracle has during their turn to
 * perform upkeep before it will be the next keeper's turn to submit
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */
struct Config {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint24 blockCountPerTurn;
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice state of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @member ownerLinkBalance withdrawable balance of LINK by contract owner
 * @member expectedLinkBalance the expected balance of LINK of the registry
 * @member numUpkeeps total number of upkeeps on the registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint256 numUpkeeps;
}

interface AutomationRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  ) external returns (uint256 id);

  function performUpkeep(uint256 id, bytes calldata performData) external returns (bool success);

  function cancelUpkeep(uint256 id) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function getUpkeep(uint256 id)
    external
    view
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber,
      uint96 amountSpent
    );

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getKeeperInfo(address query)
    external
    view
    returns (
      address payee,
      bool active,
      uint96 balance
    );

  function getState()
    external
    view
    returns (
      State memory,
      Config memory,
      address[] memory
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface AutomationRegistryInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    view
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      int256 gasWei,
      int256 linkEth
    );
}

interface AutomationRegistryExecutableInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      uint256 adjustedGasWei,
      uint256 linkEth
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

/// @dev Positions store info of all user's positions
library Positions {
    // Info for each position
    struct Position {
        // Uniswap position NFT id
        uint256 positionId;
        // positino owner, aka open position msg.sender
        address owner;
        // borrow id, idealy this should be the same as position NFT id but the id
        // is not generated yet when borow from lending pool
        uint256 borrowId;
        // want token amount when open position
        uint256 wantTokenAmountAtStart;
        // want token reserve amount at beginning, for frontend calculation
        uint256 reserveAmountAtStart;
        // the timestamp when this position created
        uint256 positionCreateTimestamp;
        // borrow token price when open position
        int24 startPriceTick;
        // borrow ratio measured in BPS, 20000 means 200%
        uint256 borrowRatio;
        // want reserve amount (can be updated)
        uint256 reserveAmount;
        // stop loss upper bound, keeper should can stop loss when price higher than this value (can be updated)
        int24 stopLossUpperPriceTick;
        // stop loss lower bound, keeper should can stop loss when price lower than this value (can be updated)
        int24 stopLossLowerPriceTick;
    }

    /**
     * @notice add new position info into Positions
     * @param self the Positions
     * @param newPosition the new position info to be added into Positions
     */
    function add(
        mapping(uint256 => Position) storage self,
        Position memory newPosition
    ) internal {
        self[newPosition.positionId] = newPosition;
    }

    /**
     * @notice remove the position info from Positions
     * @param self the Positions
     * @param positionId the position id of the position to be removed
     */
    function remove(
        mapping(uint256 => Position) storage self,
        uint256 positionId
    ) internal {
        delete self[positionId];
    }

    /**
     * @notice update the position info
     * @param self the Positions
     * @param positionId the position id of the position to be updated
     * @param action the update action, 1: update reserve amount / 2: update stop loss pirces
     * @param reserveAmount the new reserve amount of the position
     * @param stopLossUpperPriceTick the new stop loss upper price tick
     * @param stopLossLowerPriceTick the new stop loss lower price tick
     */
    function update(
        mapping(uint256 => Position) storage self,
        uint256 positionId,
        uint8 action,
        uint256 reserveAmount,
        int24 stopLossUpperPriceTick,
        int24 stopLossLowerPriceTick
    ) internal {
        if (action == 1) {
            self[positionId].reserveAmount = reserveAmount;
        } else if (action == 2) {
            if (stopLossUpperPriceTick <= stopLossLowerPriceTick) {
                revert("invalid stop loss upper and lower tick");
            }
            self[positionId].stopLossUpperPriceTick = stopLossUpperPriceTick;
            self[positionId].stopLossLowerPriceTick = stopLossLowerPriceTick;
        } else {
            revert("Invalid action");
        }
    }

    /**
     * @notice check if the position exist in Positions
     * @param self the Positions
     * @param positionId the position id to be checked
     */
    function findOrRevert(
        mapping(uint256 => Position) storage self,
        uint256 positionId
    ) internal view returns (bool positionExist) {
        positionExist = self[positionId].owner != address(0);
        require(positionExist, "Position not exist");
        return positionExist;
    }

    /**
     * @notice get the position info
     * @param self the Positions
     * @param positionId the position id of the position
     * @param ownerCheck whether only position owner can get the position info
     */
    function getOrRevert(
        mapping(uint256 => Position) storage self,
        uint256 positionId,
        bool ownerCheck
    ) internal view returns (Position memory position) {
        findOrRevert(self, positionId);
        position = self[positionId];
        if (ownerCheck) {
            require(position.owner == msg.sender, "Invalid position owner");
        }
        return position;
    }
}