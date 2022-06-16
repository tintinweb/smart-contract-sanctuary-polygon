/**
 *Submitted for verification at polygonscan.com on 2022-06-16
*/

// File: contracts/fatex/IRewardSchedule.sol



pragma solidity 0.6.12;

interface IRewardSchedule {

    function getFatePerBlock(
        uint _startBlock,
        uint _fromBlock,
        uint _toBlock
    )
    external
    view
    returns (uint);


    function calculateCurrentIndex(
        uint _startBlock
    )
    external
    view
    returns (uint);

}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
}

// File: contracts/uniswap-v2/interfaces/IUniswapV2Factory.sol



pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPairInitCode() external pure returns (bytes memory);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// File: contracts/uniswap-v2/interfaces/IUniswapV2Pair.sol



pragma solidity >=0.5.0;

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
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: contracts/fatex/IMigratorChef.sol



pragma solidity 0.6.12;


interface IMigratorChef {
    // Perform LP token migration from legacy UniswapV2 to FATEx DEX.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // FATEx DEX must mint EXACTLY the same amount of FATEx DEX LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// File: contracts/fatex/IFateRewardController.sol



pragma solidity 0.6.12;





abstract contract IFateRewardController is Ownable, IMigratorChef {

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of FATEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accumulatedFatePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accumulatedFatePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. FATEs to distribute per block.
        uint256 lastRewardBlock; // Last block number that FATEs distribution occurs.
        uint256 accumulatedFatePerShare; // Accumulated FATEs per share, times 1e12. See below.
    }

    function fate() external virtual view returns (IERC20);
    function vault() external virtual view returns (address);
    function migrator() external virtual view returns (IMigratorChef);
    function poolInfo(uint _pid) external virtual view returns (IERC20 lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accumulatedFatePerShare);
    function userInfo(uint _pid, address _user) external virtual view returns (uint256 amount, uint256 rewardDebt);
    function poolLength() external virtual view returns (uint);
    function startBlock() external virtual view returns (uint);
    function totalAllocPoint() external virtual view returns (uint);
    function pendingFate(uint256 _pid, address _user) external virtual view returns (uint256);

    function setMigrator(IMigratorChef _migrator) external virtual;
    function setVault(address _vault) external virtual;
    function migrate(uint256 _pid) external virtual;

    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) external virtual;

}

// File: @openzeppelin/contracts/math/SafeMath.sol



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

// File: contracts/governance/VotingPowerToken.sol



pragma solidity 0.6.12;






contract VotingPowerToken {
    using SafeMath for uint;

    IERC20 fate;
    IERC20 xFate;
    IFateRewardController controller;
    IUniswapV2Factory factory;

    enum PairType {
        FATE, X_FATE
    }

    struct LpTokenPair {
        address lpToken;
        PairType pairType;
    }

    constructor(
        address _fate,
        address _xFate,
        address _controller,
        address _factory
    ) public {
        fate = IERC20(_fate);
        xFate = IERC20(_xFate);
        controller = IFateRewardController(_controller);
        factory = IUniswapV2Factory(_factory);
    }

    function name() public pure returns (string memory) {
        return "FATE Voting Power";
    }

    function symbol() public pure returns (string memory) {
        return "FATE-GOV";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function allowance(address, address) public pure returns (uint256) {
        return 0;
    }

    function transfer(address, uint256) public pure returns (bool) {
        return false;
    }

    function approve(address, uint256) public pure returns (bool) {
        return false;
    }

    function transferFrom(address, address, uint256) public pure returns (bool) {
        return false;
    }

    function totalSupply() public view returns (uint) {
        LpTokenPair[] memory lpTokens = _getAllFateLpTokens();
        address _fate = address(fate);
        address _xFate = address(xFate);
        uint lpTotalSupply = 0;
        for (uint i = 0; i < lpTokens.length; i++) {
            if (lpTokens[i].lpToken != address(0)) {
                (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(lpTokens[i].lpToken).getReserves();
                uint reserves;
                if (lpTokens[i].pairType == PairType.FATE) {
                    reserves = IUniswapV2Pair(lpTokens[i].lpToken).token0() == _fate ? reserve0 : reserve1;
                } else {
                    require(lpTokens[i].pairType == PairType.X_FATE, "totalSupply: invalid pairType");

                    reserves = IUniswapV2Pair(lpTokens[i].lpToken).token0() == _xFate ? reserve0 : reserve1;
                    reserves = _xFateToFate(reserves);
                }
                lpTotalSupply = lpTotalSupply.add(reserves);
            }
        }

        return fate.totalSupply().add(_xFateToFate(xFate.totalSupply())).add(lpTotalSupply);
    }

    function balanceOf(address user) public view returns (uint) {
        LpTokenPair[] memory lpTokens = _getAllFateLpTokens();
        address _fate = address(fate);
        address _xFate = address(xFate);
        uint lpBalance = 0;
        for (uint i = 0; i < lpTokens.length; i++) {
            if (lpTokens[i].lpToken != address(0)) {
                uint userBalance = _getUserFateBalance(lpTokens[i], i, _fate, _xFate, user);
                lpBalance = lpBalance.add(userBalance);
            }
        }

        return fate.balanceOf(user).add(_xFateToFate(xFate.balanceOf(user))).add(lpBalance);
    }

    function _xFateToFate(uint amount) private view returns (uint) {
        uint _totalSupply = xFate.totalSupply();
        if (_totalSupply == 0) {
            return 0;
        } else {
            return amount.mul(fate.balanceOf(address(xFate))).div(_totalSupply);
        }
    }

    function _getUserFateBalance(
        LpTokenPair memory pair,
        uint lpTokenIndex,
        address _fate,
        address _xFate,
        address user
    ) private view returns (uint) {
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair.lpToken).getReserves();
        if (reserve0 == 0 || reserve1 == 0) {
            return 0;
        }

        IERC20 token = IERC20(pair.lpToken);

        uint reserves;
        if (pair.pairType == PairType.FATE) {
            reserves = IUniswapV2Pair(pair.lpToken).token0() == _fate ? reserve0 : reserve1;
        } else {
            require(pair.pairType == PairType.X_FATE, "totalSupply: invalid pairType");

            reserves = IUniswapV2Pair(pair.lpToken).token0() == _xFate ? reserve0 : reserve1;
            reserves = _xFateToFate(reserves);
        }

        (uint lpBalance,) = controller.userInfo(lpTokenIndex, user);
        lpBalance = lpBalance.add(token.balanceOf(user));

        return lpBalance.mul(reserves).div(token.totalSupply());
    }

    function _getAllFateLpTokens() private view returns (LpTokenPair[] memory) {
        uint poolLength = controller.poolLength();
        LpTokenPair[] memory pairs = new LpTokenPair[](poolLength);
        address _fate = address(fate);
        address _xFate = address(xFate);
        for (uint i = 0; i < poolLength; i++) {
            (IERC20 lpToken,,,) = controller.poolInfo(i);
            IUniswapV2Pair pair = IUniswapV2Pair(address(lpToken));
            address token0 = _callToken(pair, pair.token0.selector);
            address token1 = _callToken(pair, pair.token1.selector);
            if (token0 == _fate || token1 == _fate) {
                pairs[i] = LpTokenPair(address(lpToken), PairType.FATE);
            } else if (token0 == _xFate || token1 == _xFate) {
                pairs[i] = LpTokenPair(address(lpToken), PairType.X_FATE);
            }
        }
        return pairs;
    }

    function _callToken(IUniswapV2Pair pair, bytes4 selector) private view returns (address) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        (bool success, bytes memory returnData) = address(pair).staticcall(abi.encodePacked(selector));
        if (!success || returnData.length == 0) {
            return address(0);
        } else {
            return abi.decode(returnData, (address));
        }
    }

}