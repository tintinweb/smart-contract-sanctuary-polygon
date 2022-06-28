// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
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

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.6.2;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface StakingDualRewardsInterface {
    function stakingToken() external view returns (address);

    function stake(uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function getReward() external;

    function exit() external;

    function rewardsTokenA() external view returns (address);

    function rewardsTokenB() external view returns (address);

    function earnedA(address account) external view returns (uint256);

    function earnedB(address account) external view returns (uint256);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./StakingDualRewardsInterface.sol";

/**
 * Manage the staking of liquidity pool tokens in Quickswap's dual rewards pool.
 * @dev The StakingDualRewardsManager doesn't check balances from the rewards
 * pool. If any transactions fail because of no rewards, the manager should be
 * deactivated.
 */
contract StakingDualRewardsManager is KeeperCompatibleInterface, Ownable {
    address public stakingDualRewards;
    address private _uniswapV2Router02;
    address[] private _tokenABestPath;
    address[] private _tokenBBestPath;
    address public rewardsPool;

    uint256 private _interval;
    uint256 public keeperTimestamp;

    constructor(
        address stakingDualRewards_,
        address uniswapV2Router02,
        address[] memory tokenABestPath,
        address[] memory tokenBBestPath,
        address rewardsPool_
    ) {
        stakingDualRewards = stakingDualRewards_;
        _uniswapV2Router02 = uniswapV2Router02;
        _tokenABestPath = tokenABestPath;
        _tokenBBestPath = tokenBBestPath;
        rewardsPool = rewardsPool_;

        _interval = 24 * 60 * 60;
        keeperTimestamp = block.timestamp;
    }

    /**
     * Add LP tokens to the staking dual rewards pool.
     * @dev Let the underlying ERC20 token error if not enough allowance.
     */
    function addLPTokensToPool() external onlyOwner {
        address stakingToken = StakingDualRewardsInterface(stakingDualRewards)
            .stakingToken();

        uint256 amount = IERC20(stakingToken).balanceOf(owner());
        TransferHelper.safeTransferFrom(
            stakingToken,
            owner(),
            address(this),
            amount
        );
        TransferHelper.safeApprove(stakingToken, stakingDualRewards, amount);
        StakingDualRewardsInterface(stakingDualRewards).stake(amount);
    }

    /**
     * @notice Checks whether the upkeep should be run.
     * @return upkeepNeeded True if the upkeep time has elapsed, false
     * otherwise.
     */
    function checkUpkeep(bytes calldata checkData)
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /*performData*/
        )
    {
        upkeepNeeded = (block.timestamp - keeperTimestamp) >= _interval;
    }

    /**
     * @notice Perform the upkeep if required.
     * @dev Balances are not checked as LP tokens are assumed to have been
     * deposited and the pool should be generating time-based rewards
     * immediately. If this is not the case, the keeper should be
     * decommissioned.
     */
    function performUpkeep(bytes calldata performData) external override {
        (bool upkeepNeeded, ) = checkUpkeep(performData);

        require(upkeepNeeded, "StakingDualRewardsManager/checkUpkeep-not-met");

        StakingDualRewardsInterface(stakingDualRewards).getReward();

        // swap the more valuable token first for a better rate.

        // Swap token B rewards for FID.
        _transferTokenReward(
            StakingDualRewardsInterface(stakingDualRewards).rewardsTokenB(),
            _tokenBBestPath
        );

        // Swap token A rewards for FID.
        _transferTokenReward(
            StakingDualRewardsInterface(stakingDualRewards).rewardsTokenA(),
            _tokenABestPath
        );

        keeperTimestamp = block.timestamp;
    }

    /**
     * @dev Do not check balances, it's an extraneous condition which costs gas
     * without providing any benefit. Just let the tx fail as the dual pools
     * shouldn't work anyway without both rewards returning something.
     */
    function _transferTokenReward(address token, address[] memory tokenBestPath)
        internal
    {
        uint256 balance = IERC20(token).balanceOf(address(this));

        IUniswapV2Router02 router = IUniswapV2Router02(_uniswapV2Router02);

        uint256[] memory amounts = router.getAmountsOut(balance, tokenBestPath);

        // 1% slippage.
        uint256 minAmountOut = amounts[amounts.length - 1] -
            (amounts[amounts.length - 1] * 1) /
            100;

        TransferHelper.safeApprove(token, _uniswapV2Router02, balance);

        router.swapExactTokensForTokens(
            balance,
            minAmountOut,
            tokenBestPath,
            rewardsPool,
            block.timestamp + 1 * 60
        );
    }

    /**
     * Withdraw the staked tokens along with any rewards.
     */
    function withdrawLPTokens() external onlyOwner {
        StakingDualRewardsInterface(stakingDualRewards).exit();

        uint256 amountRewardsA = IERC20(
            StakingDualRewardsInterface(stakingDualRewards).rewardsTokenA()
        ).balanceOf(address(this));

        if (amountRewardsA > 0) {
            TransferHelper.safeTransfer(
                StakingDualRewardsInterface(stakingDualRewards).rewardsTokenA(),
                owner(),
                amountRewardsA
            );
        }

        uint256 amountRewardsB = IERC20(
            StakingDualRewardsInterface(stakingDualRewards).rewardsTokenB()
        ).balanceOf(address(this));

        if (amountRewardsB > 0) {
            TransferHelper.safeTransfer(
                StakingDualRewardsInterface(stakingDualRewards).rewardsTokenB(),
                owner(),
                amountRewardsB
            );
        }

        address stakingToken = StakingDualRewardsInterface(stakingDualRewards)
            .stakingToken();
        uint256 amountLP = IERC20(stakingToken).balanceOf(address(this));

        if (amountLP > 0) {
            TransferHelper.safeTransfer(stakingToken, owner(), amountLP);
        }
    }

    function changeRewardsPool(address newPool) external onlyOwner {
        address oldPool = rewardsPool;
        rewardsPool = newPool;

        emit RewardsPoolChanged(oldPool, newPool);
    }

    event RewardsPoolChanged(address indexed oldPool, address indexed newPool);
}