/**
 *Submitted for verification at polygonscan.com on 2022-11-23
*/

// File: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol

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

// File: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: NFT/buybackXVMCnburn.sol


pragma solidity 0.8.0;



interface IXVMC {
	function governor() external view returns (address);
	function burn(uint256 amount) external;
}

interface IGovernor {
	function treasuryWallet() external view returns (address);
}

contract BuybackXVMC {
    address public constant UNISWAP_ROUTER_ADDRESS = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address public constant XVMC = 0x970ccEe657Dd831e9C37511Aa3eb5302C1Eb5EEe;

    IUniswapV2Router02 public uniswapRouter;

    address public immutable wETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
	address public immutable usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
	
	bool public toBurn = true;

    constructor() {
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        IERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619).approve(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff, type(uint256).max); // infinite allowance for wETH to quickswap router
        IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174).approve(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff, type(uint256).max); // infinite allowance for USDC to quickswap router
    }

    function buybackMATIC() public {
        uint deadline = block.timestamp + 15; 
        uint[] memory _minOutT = getEstimatedXVMCforETH();
        uint _minOut = _minOutT[_minOutT.length-1] * 99 / 100;
        uniswapRouter.swapETHForExactTokens{ value: address(this).balance }(_minOut, getMATICpath(), address(this), deadline);
    }

    function buybackWETH() public {
        uint deadline = block.timestamp + 15; 
        uint[] memory _minOutT = getEstimatedXVMCforWETH();
        uint _minOut = _minOutT[_minOutT.length-1] * 99 / 100;
        uniswapRouter.swapTokensForExactTokens(_minOut, IERC20(wETH).balanceOf(address(this)), getWETHpath(), address(this), deadline);
    }

    function buybackUSDC() public {
        uint deadline = block.timestamp + 15; 
        uint[] memory _minOutT = getEstimatedXVMCforUSDC();
        uint _minOut = _minOutT[_minOutT.length-1] * 99 / 100;
        uniswapRouter.swapTokensForExactTokens(_minOut, IERC20(usdc).balanceOf(address(this)), getUSDCpath(), address(this), deadline);
    }
	
	function buybackAndBurn(bool _matic, bool _weth, bool _usdc) external {
		if(_matic) {
			buybackMATIC();
		}
		if(_weth) {
			buybackWETH();
		}
		if(_usdc) {
			buybackUSDC();
		}
		burnTokens();
	}
	
    function burnTokens() public {
		if(toBurn) {
			IXVMC(XVMC).burn(IERC20(XVMC).balanceOf(address(this)));
		} else {
        	require(IERC20(XVMC).transfer(treasury(), IERC20(XVMC).balanceOf(address(this))));
		}
    }

    function withdraw() external {
        require(msg.sender == governor(), "only thru decentralized Governance");
        payable(treasury()).transfer(address(this).balance);
        IERC20(XVMC).transfer(treasury(), IERC20(XVMC).balanceOf(address(this)));
        IERC20(usdc).transfer(treasury(), IERC20(usdc).balanceOf(address(this)));
        IERC20(wETH).transfer(treasury(), IERC20(wETH).balanceOf(address(this)));
    }
	
	function switchBurn(bool _option) external {
		require(msg.sender == governor(), "only thru decentralized Governance");
		toBurn = _option;
	}

    //with gets amount in you provide how much you want out
    function getEstimatedXVMCforETH() public view returns (uint[] memory) {
        return uniswapRouter.getAmountsOut(address(this).balance, getMATICpath()); //NOTICE: ETH is matic MATIC
    }

    function getEstimatedXVMCforWETH() public view returns (uint[] memory) {
        return uniswapRouter.getAmountsOut(IERC20(wETH).balanceOf(address(this)), getWETHpath());
    }

    function getEstimatedXVMCforUSDC() public view returns (uint[] memory) {
        return uniswapRouter.getAmountsOut(IERC20(usdc).balanceOf(address(this)), getUSDCpath());
    }

    function getMATICpath() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = XVMC;

        return path;
    }

    function getWETHpath() private view returns (address[] memory) {
        address[] memory path = new address[](3);
        path[0] = wETH; //wETH is wrapped Ethereum on Polygon
        path[1] = uniswapRouter.WETH(); // uni.WETH == wrapped MATIC 
        path[2] = XVMC;

        return path;
    }

    function getUSDCpath() private view returns (address[] memory) {
        address[] memory path = new address[](3);
        path[0] = usdc;
        path[1] = uniswapRouter.WETH();
        path[2] = XVMC;

        return path;
    }

	function governor() public view returns (address) {
		return IXVMC(XVMC).governor();
	}

  	function treasury() public view returns (address) {
		return IGovernor(governor()).treasuryWallet();
	}

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}