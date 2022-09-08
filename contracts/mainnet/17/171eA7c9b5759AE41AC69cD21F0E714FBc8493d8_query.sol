// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "IUniswapV2Pair.sol";
import "operator.sol";
import "IRewardPool.sol";


contract query is Operator {

    struct Farm_refreshTombUsdc{
        uint256 balanceOfRewardPool;
        uint256 totalsupply;
        uint256 index_token0_amount;
        uint256 index_token1_amount;
        uint256 share_token0_amount;
        uint256 share_token1_amount;
        uint256 BebuPerSecond;
        uint256 totalAllocPoint;
        IRewardPool.PoolInfo poolInfo;
        address index_token0;
        address share_token0;
        uint256 pendingShare;
        IRewardPool.UserInfo userInfo;
        uint256 balanceOfUser;
        uint256 allowance;
    }

    function farm_refreshTombUsdc(
        IUniswapV2Pair lp_index, 
        IUniswapV2Pair lp_share, 
        IRewardPool pool, 
        address user,
        uint256 pid
      ) external view returns (Farm_refreshTombUsdc memory _farm_refreshTombUsdc) {
          _farm_refreshTombUsdc.balanceOfRewardPool = lp_index.balanceOf(address(pool));
          _farm_refreshTombUsdc.totalsupply = lp_index.totalSupply();
          (_farm_refreshTombUsdc.index_token0_amount, _farm_refreshTombUsdc.index_token1_amount, ) = lp_index.getReserves();
          (_farm_refreshTombUsdc.share_token0_amount, _farm_refreshTombUsdc.share_token1_amount, ) = lp_share.getReserves();
          _farm_refreshTombUsdc.BebuPerSecond = pool.BebuPerSecond();
          _farm_refreshTombUsdc.totalAllocPoint = pool.totalAllocPoint();
          _farm_refreshTombUsdc.poolInfo = pool.poolInfo(pid);
          _farm_refreshTombUsdc.index_token0 = lp_index.token0();
          _farm_refreshTombUsdc.share_token0 = lp_share.token0();
          _farm_refreshTombUsdc.pendingShare = pool.pendingShare(pid, user);
          _farm_refreshTombUsdc.userInfo = pool.userInfo(pid, user);
          _farm_refreshTombUsdc.balanceOfUser = lp_index.balanceOf(user);
          _farm_refreshTombUsdc.allowance = lp_index.allowance(user, address(pool));
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "Context.sol";
import "Ownable.sol";

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() internal {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IRewardPool {

    struct PoolInfo {
        address token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Bebus to distribute per block.
        uint256 lastRewardTime; // Last time that Bebus distribution occurs.
        uint256 accBebuPerShare; // Accumulated Bebus per share, times 1e18. See below.
        bool isStarted; // if lastRewardTime has passed
    }

    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    function BebuPerSecond() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

    function pendingShare(uint256 _pid, address _user) external view returns (uint256);

    function userInfo(uint256 _pid, address _addr) external view returns (UserInfo memory);
}