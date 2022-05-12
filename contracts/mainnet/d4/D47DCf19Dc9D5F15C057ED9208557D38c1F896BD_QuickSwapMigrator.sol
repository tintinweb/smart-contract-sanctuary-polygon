// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IPolydexPair.sol";
import "../interfaces/IPolydexRouter.sol";
import "../interfaces/IPolydexFactory.sol";
import "../interfaces/IFarm.sol";
import "../interfaces/IDappFactoryFarm.sol";
import "../interfaces/IRewardManager.sol";
import "../libraries/TransferHelper.sol";

// QuickSwapMigrator helps you migrate your Polydex LP tokens to Quickswap LP tokens
contract QuickSwapMigrator is Ownable, ReentrancyGuard {
    IPolydexFactory public immutable polydexFactory;
    IPolydexFactory public immutable quickswapFactory;

    IPolydexRouter public immutable polydexRouter;
    IPolydexRouter public immutable quickswapRouter;

    IFarm public polydexFarm;
    IDappFactoryFarm public quickswapFarm;

    IRewardManager public rewardManager;

    address public immutable wmatic;
    address public immutable cnt;

    uint256 private constant DEADLINE =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    struct LiquidityVars {
        address tokenA;
        address tokenB;
        uint256 amountAReceived;
        uint256 amountBReceived;
        uint256 amountAadded;
        uint256 amountBadded;
        uint256 amountAleft;
        uint256 amountBleft;
        uint256 lpReceived;
    }

    LiquidityVars private liquidityVars;

    event LiquidityMigrated(
        uint256 tokenAadded,
        uint256 tokenBadded,
        uint256 newLPAmount
    );

    modifier ensureNonZeroAddress(address addressToCheck) {
        require(
            addressToCheck != address(0),
            "QuickSwapMigrator: No zero address"
        );
        _;
    }

    constructor(
        IPolydexRouter _polydexRouter,
        IPolydexRouter _quickswapRouter,
        IFarm _polydexFarm,
        IDappFactoryFarm _quickswapFarm,
        IRewardManager _rewardManger,
        address _cnt
    ) {
        require(_cnt != address(0), "QuickSwapMigrator: No zero address");
        polydexRouter = _polydexRouter;
        quickswapRouter = _quickswapRouter;
        polydexFactory = IPolydexFactory(_polydexRouter.factory());
        quickswapFactory = IPolydexFactory(_quickswapRouter.factory());
        wmatic = _polydexRouter.WETH();
        polydexFarm = _polydexFarm;
        quickswapFarm = _quickswapFarm;
        rewardManager = _rewardManger;
        cnt = _cnt;
    }

    // need to call addUserToWhiteList before this
    //Prerequisite: in RewardManager excludedAddresses[LiquidityMigrator_Contract] & rewardDistributor[LiquidityMigrator_Contract] should be set to true
    function migrate(
        uint256 _oldPid,
        uint256 _lpAmount,
        IPolydexPair _oldLPAddress,
        IPolydexPair _newLPAddress
    )
        external
        nonReentrant
        ensureNonZeroAddress(address(_oldLPAddress))
        ensureNonZeroAddress(address(_newLPAddress))
    {
        //general checks
        require(
            _lpAmount > 0,
            "QuickSwapMigrator: LP Amount should be greater than zero"
        );
        require(_oldPid == 0, "QuickSwapMigrator: Invalid pid");

        //validate LP addresses
        IPolydexPair oldLPAddress = IPolydexPair(
            polydexFactory.getPair(wmatic, cnt)
        );
        IPolydexPair newLPAddress = IPolydexPair(
            quickswapFactory.getPair(wmatic, cnt)
        );
        require(
            _oldLPAddress == oldLPAddress && _newLPAddress == newLPAddress,
            "QuickSwapMigrator: Invalid LP token addresses"
        );

        //Withdraw old LP tokens
        polydexFarm.withdrawFor(_oldPid, _lpAmount, msg.sender);
        require(
            oldLPAddress.balanceOf(address(this)) >= _lpAmount,
            "QuickSwapMigrator: Insufficient old LP Balance"
        );

        //Migrator vests users's CNT to reward manager for the user
        uint256 cntBalance = IERC20(cnt).balanceOf(address(this));
        if (cntBalance > 0) {
            TransferHelper.safeTransfer(
                address(cnt),
                address(rewardManager),
                cntBalance
            );
            rewardManager.handleRewardsForUser(
                msg.sender,
                cntBalance,
                block.timestamp,
                _oldPid,
                0
            );
        }

        //transform liquidity from polydex to quickswap
        _transFormLiquidity(_oldLPAddress, _lpAmount);

        //Check pending balances of tokens in the old LP
        liquidityVars.amountAleft = IERC20(liquidityVars.tokenA).balanceOf(
            address(this)
        );
        liquidityVars.amountBleft = IERC20(liquidityVars.tokenB).balanceOf(
            address(this)
        );

        //Transfer pending tokens with any remaining dust
        if (liquidityVars.amountAleft > 0)
            TransferHelper.safeTransfer(
                liquidityVars.tokenA,
                msg.sender,
                liquidityVars.amountAleft
            );
        if (liquidityVars.amountBleft > 0)
            TransferHelper.safeTransfer(
                liquidityVars.tokenB,
                msg.sender,
                liquidityVars.amountBleft
            );

        if (newLPAddress.balanceOf(address(this)) >= liquidityVars.lpReceived)
            _depositLP(
                address(newLPAddress),
                liquidityVars.lpReceived,
                msg.sender
            );

        emit LiquidityMigrated(
            liquidityVars.amountAadded,
            liquidityVars.amountBadded,
            liquidityVars.lpReceived
        );
    }

    function _depositLP(
        address _pairAddress,
        uint256 _lpAmount,
        address _user
    ) internal {
        TransferHelper.safeApprove(
            address(_pairAddress),
            address(quickswapFarm),
            _lpAmount
        );
        quickswapFarm.depositFor(_lpAmount, _user);
    }

    // Rescue any tokens that have not been able to processed by the contract
    function rescueFunds(address _token) external onlyOwner nonReentrant {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance > 0, "QuickSwapMigrator: Insufficient token balance");
        TransferHelper.safeTransfer(address(_token), msg.sender, balance);
    }

    function _transFormLiquidity(IPolydexPair _oldLPAddress, uint256 _lpAmount)
        internal
    {
        liquidityVars.tokenA = _oldLPAddress.token0();
        liquidityVars.tokenB = _oldLPAddress.token1();

        //Approve old LP to the router
        TransferHelper.safeApprove(
            address(_oldLPAddress),
            address(polydexRouter),
            _lpAmount
        );

        //Remove liquidity
        (
            liquidityVars.amountAReceived,
            liquidityVars.amountBReceived
        ) = polydexRouter.removeLiquidity(
            liquidityVars.tokenA,
            liquidityVars.tokenB,
            _lpAmount,
            1,
            1,
            address(this),
            DEADLINE
        );

        TransferHelper.safeApprove(
            address(liquidityVars.tokenA),
            address(quickswapRouter),
            liquidityVars.amountAReceived
        );

        TransferHelper.safeApprove(
            address(liquidityVars.tokenB),
            address(quickswapRouter),
            liquidityVars.amountBReceived
        );

        (
            liquidityVars.amountAadded,
            liquidityVars.amountBadded,
            liquidityVars.lpReceived
        ) = quickswapRouter.addLiquidity(
            liquidityVars.tokenA,
            liquidityVars.tokenB,
            liquidityVars.amountAReceived,
            liquidityVars.amountBReceived,
            1,
            1,
            address(this),
            DEADLINE
        );

        require(
            liquidityVars.lpReceived > 0,
            "QuickSwapMigrator: Add Liquidity Error"
        );
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPolydexPair {
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

pragma solidity >=0.6.0 <0.8.0;

interface IPolydexRouter {
    function factory() external view returns (address);
    function WETH() external view returns (address);

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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPolydexFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IFarm {
    function withdrawFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;

    function poolLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IDappFactoryFarm {
    function withdrawFor(uint256 _amount, address _user) external;

    function depositFor(uint256 _amount, address _user) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IRewardManager {
    event Vested(address indexed _beneficiary, uint256 indexed value);

    event DrawDown(
        address indexed _beneficiary,
        uint256 indexed _amount,
        uint256 indexed bonus
    );

    event PreMatureDrawn(
        address indexed _beneficiary,
        uint256 indexed burntAmount,
        uint256 indexed userEffectiveWithdrawn
    );

    function startDistribution() external view returns (uint256);

    function endDistribution() external view returns (uint256);

    function updatePreMaturePenalty(uint256 _newpreMaturePenalty) external;

    function updateBonusPercentage(uint256 _newBonusPercentage) external;

    function updateDistributionTime(
        uint256 _updatedStartTime,
        uint256 _updatedEndTime
    ) external;

    function updateUpfrontUnlock(uint256 _newUpfrontUnlock) external;

    function updateWhitelistAddress(address _excludeAddress, bool status)
        external;

    function handleRewardsForUser(
        address user,
        uint256 rewardAmount,
        uint256 timestamp,
        uint256 pid,
        uint256 rewardDebt
    ) external;

    function vestingInfo(address _user)
        external
        view
        returns (
            uint256 totalVested,
            uint256 totalDrawnAmount,
            uint256 amountBurnt,
            uint256 claimable,
            uint256 bonusRewards,
            uint256 stillDue
        );

    function drawDown(address _user) external;

    function preMatureDraw(address _beneficiary) external;

    function addBonusRewards(uint256 _bonusRewards) external;

    function removeBonusRewards(address _owner) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

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