// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "./interfaces/IExchangeConnector.sol";
import "../uniswap/v2-periphery/interfaces/IUniswapV2Router02.sol";
import "../uniswap/v2-core/interfaces/IUniswapV2Pair.sol";
import "../uniswap/v2-core/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract UniswapV2Connector is IExchangeConnector, Ownable, ReentrancyGuard {


    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "UniswapV2Connector: zero address");
        _;
    }

    string public override name;
    address public override exchangeRouter;
    address public override liquidityPoolFactory;
    address public override wrappedNativeToken;

    /// @notice                          This contract is used for interacting with UniswapV2 contract
    /// @param _name                     Name of the underlying DEX
    /// @param _exchangeRouter           Address of the DEX router contract
    constructor(string memory _name, address _exchangeRouter) {
        name = _name;
        exchangeRouter = _exchangeRouter;
        liquidityPoolFactory = IUniswapV2Router02(exchangeRouter).factory();
        wrappedNativeToken = IUniswapV2Router02(exchangeRouter).WETH();
    }

    function renounceOwnership() public virtual override onlyOwner {}

    /// @notice                             Setter for exchange router
    /// @dev                                Gets address of liquidity pool factory from new exchange router
    /// @param _exchangeRouter              Address of the new exchange router contract
    function setExchangeRouter(address _exchangeRouter) external nonZeroAddress(_exchangeRouter) override onlyOwner {
        exchangeRouter = _exchangeRouter;
        liquidityPoolFactory = IUniswapV2Router02(exchangeRouter).factory();
        wrappedNativeToken = IUniswapV2Router02(exchangeRouter).WETH();
    }

    /// @notice            Setter for liquidity pool factory
    /// @dev               Gets address from exchange router
    function setLiquidityPoolFactory() external override onlyOwner {
        liquidityPoolFactory = IUniswapV2Router02(exchangeRouter).factory();
    }

    /// @notice            Setter for wrapped native token
    /// @dev               Gets address from exchange router
    function setWrappedNativeToken() external override onlyOwner {
        wrappedNativeToken = IUniswapV2Router02(exchangeRouter).WETH();
    }

    /// @notice                     Returns required input amount to get desired output amount
    /// @dev                        Returns (false, 0) if liquidity pool of inputToken-outputToken doesn't exist
    ///                             Returns (false, 0) if desired output amount is greater than or equal to output reserve
    /// @param _outputAmount        Desired output amount
    /// @param _inputToken          Address of the input token
    /// @param _outputToken         Address of the output token
    function getInputAmount(
        uint _outputAmount,
        address _inputToken,
        address _outputToken
    ) external view nonZeroAddress(_inputToken) nonZeroAddress(_outputToken) override returns (bool, uint) {

        // Checks that the liquidity pool exists
        address liquidityPool = IUniswapV2Factory(liquidityPoolFactory).getPair(_inputToken, _outputToken);

        if (
            liquidityPool == address(0)
        ) {
            if (
                IUniswapV2Factory(liquidityPoolFactory).getPair(_inputToken, wrappedNativeToken) == address(0) ||
                IUniswapV2Factory(liquidityPoolFactory).getPair(wrappedNativeToken, _outputToken) == address(0)
            ) {
                return (false, 0);
            } 

            address[] memory path = new address[](3);
            path[0] = _inputToken;
            path[1] = wrappedNativeToken;
            path[2] = _outputToken;
            uint[] memory result = IUniswapV2Router02(exchangeRouter).getAmountsIn(_outputAmount, path);

            return (true, result[0]);

        } else {

            address[] memory path = new address[](2);
            path[0] = _inputToken;
            path[1] = _outputToken;
            uint[] memory result = IUniswapV2Router02(exchangeRouter).getAmountsIn(_outputAmount, path);

            return (true, result[0]);
        }
        
    }

    /// @notice                     Returns amount of output token that user receives 
    /// @dev                        Returns (false, 0) if liquidity pool of inputToken-outputToken doesn't exist
    /// @param _inputAmount         Amount of input token
    /// @param _inputToken          Address of the input token
    /// @param _outputToken         Address of the output token
    function getOutputAmount(
        uint _inputAmount,
        address _inputToken,
        address _outputToken
    ) external view nonZeroAddress(_inputToken) nonZeroAddress(_outputToken) override returns (bool, uint) {

        // Checks that the liquidity pool exists
        address liquidityPool = IUniswapV2Factory(liquidityPoolFactory).getPair(_inputToken, _outputToken);

        if (
            liquidityPool == address(0)
        ) {
            if (
                IUniswapV2Factory(liquidityPoolFactory).getPair(_inputToken, wrappedNativeToken) == address(0) ||
                IUniswapV2Factory(liquidityPoolFactory).getPair(wrappedNativeToken, _outputToken) == address(0)
            ) {
                return (false, 0);
            }

            address[] memory path = new address[](3);
            path[0] = _inputToken;
            path[1] = wrappedNativeToken;
            path[2] = _outputToken;
            uint[] memory result = IUniswapV2Router02(exchangeRouter).getAmountsOut(_inputAmount, path);
            return (true, result[2]);
            
        } else {

            address[] memory path = new address[](2);
            path[0] = _inputToken;
            path[1] = _outputToken;
            uint[] memory result = IUniswapV2Router02(exchangeRouter).getAmountsOut(_inputAmount, path);

            return (true, result[1]);
        }
    }

    /// @notice                     Exchanges input token for output token through exchange router
    /// @dev                        Checks exchange conditions before exchanging
    ///                             We assume that the input token is not WETH (it is teleBTC)
    /// @param _inputAmount         Amount of input token
    /// @param _outputAmount        Amount of output token
    /// @param _path                List of tokens that are used for exchanging
    /// @param _to                  Receiver address
    /// @param _deadline            Deadline of exchanging tokens
    /// @param _isFixedToken        True if the input token amount is fixed
    /// @return _result             True if the exchange is successful
    /// @return _amounts            Amounts of tokens that are involved in exchanging
    function swap(
        uint256 _inputAmount,
        uint256 _outputAmount,
        address[] memory _path,
        address _to,
        uint256 _deadline,
        bool _isFixedToken
    ) external nonReentrant nonZeroAddress(_to) override returns (bool _result, uint[] memory _amounts) {
        
        if (_path.length == 2) {
            address liquidityPool = IUniswapV2Factory(liquidityPoolFactory).getPair(_path[0], _path[1]);

            if (liquidityPool == address(0)) {
                address[] memory thePath = new address[](3);

                thePath[0] = _path[0];
                thePath[1] = wrappedNativeToken;
                thePath[2] = _path[1];

                _path = thePath;
            }
        }

        uint neededInputAmount;
        (_result, neededInputAmount) = _checkExchangeConditions(
            _inputAmount,
            _outputAmount,
            _path,
            _deadline,
            _isFixedToken
        );
        
        if (_result) {
            // Gets tokens from user
            IERC20(_path[0]).transferFrom(_msgSender(), address(this), neededInputAmount);

            // Gives allowance to exchange router
            IERC20(_path[0]).approve(exchangeRouter, neededInputAmount);

            if (_isFixedToken == false && _path[_path.length-1] != wrappedNativeToken) {
                _amounts = IUniswapV2Router02(exchangeRouter).swapTokensForExactTokens(
                    _outputAmount,
                    _inputAmount,
                    _path,
                    _to,
                    _deadline
                );
            }

            if (_isFixedToken == false && _path[_path.length-1] == wrappedNativeToken) {
                _amounts = IUniswapV2Router02(exchangeRouter).swapTokensForExactETH(
                    _outputAmount,
                    _inputAmount,
                    _path,
                    _to,
                    _deadline
                );
            }

            if (_isFixedToken == true && _path[_path.length-1] != wrappedNativeToken) {
                _amounts = IUniswapV2Router02(exchangeRouter).swapExactTokensForTokens(
                    _inputAmount,
                    _outputAmount,
                    _path,
                    _to,
                    _deadline
                );
            }

            if (_isFixedToken == true && _path[_path.length-1] == wrappedNativeToken) {
                _amounts = IUniswapV2Router02(exchangeRouter).swapExactTokensForETH(
                    _inputAmount,
                    _outputAmount,
                    _path,
                    _to,
                    _deadline
                );
            }
            emit Swap(_path, _amounts, _to);
        }
    }

    /// @notice                     Returns true if the exchange path is valid
    /// @param _path                List of tokens that are used for exchanging
    function isPathValid(address[] memory _path) public view override returns (bool _result) {
        address liquidityPool;

        // Checks that path length is greater than one
        if (_path.length < 2) {
            return false;
        }

        for (uint i = 0; i < _path.length - 1; i++) {
            liquidityPool =
                IUniswapV2Factory(liquidityPoolFactory).getPair(_path[i], _path[i + 1]);
            if (liquidityPool == address(0)) {
                return false;
            }
        }

        return true;
    }

    /// @notice                     Checks if exchanging can happen successfully
    /// @dev                        Avoids reverting the execution by exchange router
    /// @param _inputAmount         Amount of input token
    /// @param _outputAmount        Amount of output token
    /// @param _path                List of tokens that are used for exchanging
    /// @param _deadline            Deadline of exchanging tokens
    /// @param _isFixedToken        True if the input token amount is fixed
    /// @return                     True if exchange conditions are satisfied
    /// @return                     Needed amount of input token
    function _checkExchangeConditions(
        uint256 _inputAmount,
        uint256 _outputAmount,
        address[] memory _path,
        uint256 _deadline,
        bool _isFixedToken
    ) private view returns (bool, uint) {

        // Checks deadline has not passed
        if (_deadline < block.timestamp) {
            return (false, 0);
        }

        // Checks that the liquidity pool exists
        if (!isPathValid(_path)) {
            return (false, 0);
        }

        // Finds maximum output amount
        uint[] memory outputResult = IUniswapV2Router02(exchangeRouter).getAmountsOut(
            _inputAmount,
            _path
        );

        // Checks that exchanging is possible or not
        if (_outputAmount > outputResult[_path.length - 1]) {
            return (false, 0);
        } else {
            if (_isFixedToken == true) {
                return (true, _inputAmount);
            } else {
                uint[] memory inputResult = IUniswapV2Router02(exchangeRouter).getAmountsIn(
                    _outputAmount, 
                    _path
                );
                return (true, inputResult[0]);
            }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

interface IExchangeConnector {

    // Events
    
    event Swap(address[] path, uint[] amounts, address receiver);

    // Read-only functions

    function name() external view returns (string memory);

    function exchangeRouter() external view returns (address);

    function liquidityPoolFactory() external view returns (address);

    function wrappedNativeToken() external view returns (address);

    function getInputAmount(
        uint _outputAmount,
        address _inputToken,
        address _outputToken
    ) external view returns (bool, uint);

    function getOutputAmount(
        uint _inputAmount,
        address _inputToken,
        address _outputToken
    ) external view returns (bool, uint);

    // State-changing functions

    function setExchangeRouter(address _exchangeRouter) external;

    function setLiquidityPoolFactory() external;

    function setWrappedNativeToken() external;

    function swap(
        uint256 _inputAmount,
        uint256 _outputAmount,
        address[] memory _path,
        address _to,
        uint256 _deadline,
        bool _isFixedToken
    ) external returns (bool, uint[] memory);

    function isPathValid(address[] memory _path) external view returns(bool);
}

// SPDX-License-Identifier: MIT
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
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    constructor() {
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

// SPDX-License-Identifier: MIT

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