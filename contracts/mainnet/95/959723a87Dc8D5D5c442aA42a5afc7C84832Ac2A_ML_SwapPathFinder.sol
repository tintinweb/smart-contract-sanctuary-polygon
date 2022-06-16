/**
 *Submitted for verification at polygonscan.com on 2022-06-16
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: contracts/interfaces/IToken.sol



pragma solidity ^0.8.0;


interface IToken is IERC20
{
	function decimals() external view returns (uint8);	
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
}
// File: contracts/interfaces/ITokenPair.sol



pragma solidity ^0.8.0;


interface ITokenPair is IToken
{	
	function token0() external view returns (address);
	
	function token1() external view returns (address);
	
	function getReserves() external view returns (uint112, uint112, uint32);	
}
// File: contracts/interfaces/IFactory.sol



pragma solidity ^0.8.0;

interface IFactory
{
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
// File: contracts/interfaces/IRouter.sol



pragma solidity ^0.8.0;

interface IUniRouterV1
{
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

interface IUniRouterV2 is IUniRouterV1
{
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
// File: contracts/libs/Moon Labs/ML_SwapPathFinder.sol


pragma solidity ^0.8.0;





contract ML_SwapPathFinder
{
    //========================
    // STRUCT
    //========================

    struct SwapPathInfo
    {        
        IUniRouterV2 router;        //used router
        address[] path;             //swap path
        uint256 amountOut;          //out amount
    }

    //========================
    // INFO FUNCTIONS
    //========================

    function findSwapPathes(
        IToken _from, 
        IToken _to, 
        uint256 _amountIn, 
        IUniRouterV2[] calldata _routers, 
        IToken[] calldata _additionalTokens
    ) public returns (SwapPathInfo[] memory)
    {        
        SwapPathInfo[] memory pathInfo = new SwapPathInfo[](_routers.length * (_additionalTokens.length + 1));
        
        //iterate over all routers and pathes
        for (uint256 n = 0; n < _routers.length; n++)
        {
            uint256 routerIdx = n * (_additionalTokens.length + 1);

            //check direct path
            pathInfo[routerIdx] = getSwapPathInfo(
                _routers[n],
                _from,
                _to,
                IToken(address(0)),
                _amountIn
            );

            //check additional tokens
            for (uint256 m = 0; m < _additionalTokens.length; m++)
            {
                if (_additionalTokens[m] == _from
                    || _additionalTokens[m] == _to)
                {
                    continue;
                }

                //check indirect with 1 hop
                pathInfo[routerIdx + m + 1] = getSwapPathInfo(
                    _routers[n],
                    _from,
                    _to,
                    _additionalTokens[m],
                    _amountIn
                );
            }
        }

        return removeEmptyPathes(pathInfo);
    }

    //========================
    // SWAP INFO FUNCTIONS
    //========================

    function getSwapEstimate(uint256 _amountIn, IUniRouterV2 _router, address[] memory _path) public view virtual returns (uint256)
    {
        uint256[] memory estimateOuts = _router.getAmountsOut(_amountIn, _path);
        return estimateOuts[estimateOuts.length - 1];
    }

    function makeSwapPath(IToken _from, IToken _to, IToken _swapOver) internal pure returns (address[] memory)
	{
	    address[] memory path;
		if (_from == _swapOver
			|| _to == _swapOver
            || address(_swapOver) == address(0))
		{
            //direct
			path = new address[](2);
			path[0] = address(_from);
			path[1] = address(_to);
		}
		else
		{
            //indirect over wrapped coin
			path = new address[](3);
			path[0] = address(_from);
			path[1] = address(_swapOver);
			path[2] = address(_to);
		}
		
		return path;
	}

    //========================
    // HELPER
    //========================    

    function getSwapPathInfo(
        IUniRouterV2 _router, 
        IToken _from, 
        IToken _to, 
        IToken _swapOver, 
        uint256 _amountIn
    ) private view returns (SwapPathInfo memory)
    {
        SwapPathInfo memory spi;

        //validate pair
        if (address(_swapOver) == address(0))
        {
            if (!checkPairValid(_router, _from, _to))
            {
                return spi;
            }
        }
        else if (!checkPairValid(_router, _from, _swapOver)
            || !checkPairValid(_router, _from, _swapOver))
        {
            return spi;
        }

        //get info
        spi.router = _router;
        spi.path = makeSwapPath(_from, _to, _swapOver);
        spi.amountOut = getSwapEstimate(_amountIn, _router, spi.path);
        return spi;
    }

    function checkPairValid(IUniRouterV2 _router, IToken _token0, IToken _token1) private view returns (bool)
    {
        //get pair
        ITokenPair pair = ITokenPair(IFactory(_router.factory())
            .getPair(
                address(_token0),
                address(_token1)));
        if (address(pair) == address(0))
        {
            return false;
        }

        //check if real or precalculated
        try pair.token0() {}
        catch
        {
            return false;
        }
        return true;
    }

    function removeEmptyPathes(SwapPathInfo[] memory _pathes) private pure returns (SwapPathInfo[] memory)
    {
        //count used
        uint256 used = 0;
        for (uint256 n = 0; n < _pathes.length; n++)
        {
            if (_pathes[n].amountOut != 0)
            {
                used += 1;
            }
        }

        //make new list without empty
        SwapPathInfo[] memory pathesUsed = new SwapPathInfo[](used);
        if (used == 0)
        {
            return pathesUsed;
        }
        uint256 newIndex = 0;
        for (uint256 n = 0; n < _pathes.length; n++)
        {
            if (_pathes[n].amountOut != 0)
            {
                pathesUsed[newIndex] = _pathes[n];
                newIndex += 1;
                if (newIndex == used)
                {
                    break;
                }
            }
        }
        return pathesUsed;
    }
}