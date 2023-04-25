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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;
pragma abicoder v2;

import "./Exchange.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./../interfaces/exchange/curve/ICurve.sol";
import "./../interfaces/exchange/IExchange.sol";

/**
 * @title Curve swapping functionality
 * @notice Functions for swapping tokens via Curve
 **/
contract CurveExchange is IExchange {
    /// @dev Holds a mapping of curve pools and coins to indexses
    mapping(address => mapping(address => int128)) public _tokens;

    /// @dev Holds a mapping of curve pools
    mapping(address => bool) public _pools;

    /// @dev Holds a mapping of paris to curve pools
    mapping(address => mapping(address => address[])) public algo_map;

    /// @dev USDT token address
    address public USDT;

    constructor(address usdt) {
        USDT = usdt;
    }

    /**
     * @notice Set token `pairs`  by curve pools for exchange
     * @param pairs Array or token pairs
     * @param routes Array of curve pools
     * @dev Example: algo_map[address_in_weth][address_out_usdt] = [pool_3crypto]
     * algo_map[address_in_weth][any] = [pool_3crypto, 3_pool]
     * algo_map[address_in_usdt][address_out_weth] = [pool_3crypto]
     * algo_map[any][address_out_weth] = [3_pool, pool_3crypto]
     * algo_map[any][any] = [3_pool]
     * , where any - USDC, DAI
     */
    function setAlgo(
        address[][] calldata pairs,
        address[][] calldata routes,
        uint256[] calldata poolSizes
    ) external {
        require(pairs.length == routes.length);

        for (uint256 i = 0; i < pairs.length; i++) {
            algo_map[pairs[i][0]][pairs[i][1]] = routes[i];

            for (uint256 j = 0; j < routes[i].length; j++) {
                if (!_pools[routes[i][j]]) {
                    for (uint256 k = 0; k < poolSizes[i]; k++) {
                        address coin = ICurve(routes[i][j]).coins(k);

                        _tokens[routes[i][j]][coin] = int128(int256(k));
                    }
                    _pools[routes[i][j]] = true;
                }
            }
        }
    }

    /**
     * @notice Get `amountOut` of the received token
     * @param tokenIn Address of the input token
     * @param tokenOut ddress of the received token
     * @param amountIn The amount of the input token
     * @return amountOut The amount of the received token
     */
    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 amountOut) {
        address[] memory pools = algo_map[tokenIn][tokenOut];
        address tokenOut_ = pools.length == 2 ? USDT : tokenOut;

        for (uint256 k = 0; k < pools.length; k++) {
            int128 i = _tokens[pools[k]][tokenIn];
            int128 j = _tokens[pools[k]][tokenOut_];
            uint256 dx = amountIn;

            amountOut = ICurve(pools[k]).get_dy(i, j, dx);

            amountIn = amountOut;
            tokenIn = USDT;
            tokenOut_ = tokenOut;
        }
    }

    /**
     * @notice Swaps `amountIn` of one token for as much as possible of another token
     * @param params The parameters necessary for the swap, encoded as `IExchange.SwapParams` in memory
     * @return amountIn The amount of the input token
     * @return amountOut The amount of the received token
     */
    function swap(
        IExchange.SwapParams memory params
    ) external override returns (uint256 amountIn, uint256 amountOut) {
        TransferHelper.safeTransferFrom(
            params.tokenIn,
            msg.sender,
            address(this),
            params.amountIn
        );

        uint256 oldBalance = IERC20(params.tokenOut).balanceOf(address(this));

        address[] memory pools = algo_map[params.tokenIn][params.tokenOut];
        require(pools.length > 0, "CurveExchange: empty pools");

        address tokenOut = pools.length == 2 ? USDT : params.tokenOut;
        address tokenIn = params.tokenIn;
        amountIn = params.amountIn;

        for (uint256 k = 0; k < pools.length; k++) {
            TransferHelper.safeApprove(tokenIn, pools[k], amountIn);
            ICurve(pools[k]).exchange(
                _tokens[pools[k]][tokenIn],
                _tokens[pools[k]][tokenOut],
                amountIn,
                0
            );

            if (pools.length == 2) {
                amountIn = amountOut;
                tokenIn = USDT;
                tokenOut = params.tokenOut;
            }
        }

        uint256 newBalance = IERC20(params.tokenOut).balanceOf(address(this));
        amountOut = newBalance - oldBalance;

        TransferHelper.safeTransfer(params.tokenOut, msg.sender, amountOut);
    }

    // TODO: Implementation!
    function getAmountIn(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) external view returns (uint256 amountIn) {
        return 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;
pragma abicoder v2;

import "./../interfaces/exchange/IExchange.sol";
import "./../interfaces/IFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

contract Exchange is Ownable {
    IFactory public _factory;

    function setFactory(IFactory factory) external {
        _factory = factory;
    }

    function swap(
        IExchange.SwapParams memory params
    ) external virtual returns (uint256 amountIn, uint256 amountOut) {
        IExchange exchange = _factory.getExchange(params.dexType);
        require(address(exchange) != address(0), "Exchange: ZERO_ADDRESS");

        TransferHelper.safeApprove(
            params.tokenIn,
            address(exchange),
            params.amountIn
        );

        (amountIn, amountOut) = exchange.swap(params);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICurve {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function coins(uint256 i) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IExchange {
    enum DEX {
        UNISWAP,
        CURVE
    }

    struct SwapParams {
        uint256 amountIn;
        uint256 amountOut; // if > 0 we used oracle price
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 timestamp;
        bytes path;
        DEX dexType;
    }

    function swap(
        SwapParams memory params
    ) external returns (uint256 amountIn, uint256 amountOut);

    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function getAmountIn(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) external view returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./exchange/IExchange.sol";

interface IFactory {
    /// @notice Emitted when a pool is created
    /// @param token The token of the pool
    /// @param alp The address of the created alp
    event AlpCreated(address indexed token, address alp, uint256 count);

    /// @notice Returns the current address resolver of the factory
    function resolver() external view returns (address);

    // /// @notice Returns the current keeper of the factory
    // function keeper() external view returns (address);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param token The token of the pool
    /// @return alp The pool address
    function getAlp(address token) external view returns (address alp);

    function getExchange(
        IExchange.DEX type_
    ) external view returns (IExchange exchange);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param token The token of the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return alp The address of the newly created pool
    function createAlp(
        address token,
        string memory name
    ) external returns (address alp);

    function getTokens() external view returns (address[] calldata);

    function addToken(address token) external;

    function removeToken(address token) external;
}