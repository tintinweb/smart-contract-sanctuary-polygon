//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

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
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {
    address private owner;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

interface IToken {
    function sellFeeRecipient() external view returns (address);
}

contract LPFeeReceiver is Ownable {
    address public LP_TWO_TOKENS;
    address public LP_ETH;
    address public STS;
    address public STSP;
    address public treasury;
    IUniswapV2Router02 public router;

    modifier notZeroOrDead(address addr) {
        require(addr != address(0), "Cannot be 0");
        require(
            addr != address(0x000000000000000000000000000000000000dEaD),
            "Cannot be dead"
        );
        _;
    }

    //events

    event SetLPAddresses(address newLPTwoTokens, address newLPEth);
    event SetRouter(address newRouter);
    event SetTreasury(address newTreasury);
    event SetSTSP(address newSTSP);
    event SetSTS(address newSTS);

    constructor(
        address LP_TWO,
        address LP_ETH_,
        address router_,
        address STS_,
        address STSP_,
        address treasury_
    )
        notZeroOrDead(LP_TWO)
        notZeroOrDead(LP_ETH_)
        notZeroOrDead(router_)
        notZeroOrDead(STS_)
        notZeroOrDead(STSP_)
        notZeroOrDead(treasury_)
    {
        LP_TWO_TOKENS = LP_TWO;
        LP_ETH = LP_ETH_;
        router = IUniswapV2Router02(router_);
        STS = STS_;
        STSP = STSP_;
        treasury = treasury_;
    }

    function withdraw(address token) external onlyOwner {
        IERC20(token).transfer(
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
    }

    function withdrawETH() external onlyOwner {
        (bool s, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(s, "ETH Transfer Failed");
    }

    function setLPAddresses(
        address LP_TWO_TOKENS_,
        address LP_ETH_
    ) external onlyOwner notZeroOrDead(LP_TWO_TOKENS_) notZeroOrDead(LP_ETH_) {
        LP_TWO_TOKENS = LP_TWO_TOKENS_;
        LP_ETH = LP_ETH_;
        emit SetLPAddresses(LP_TWO_TOKENS, LP_ETH);
    }

    function setRouter(
        address router_
    ) external onlyOwner notZeroOrDead(router_) {
        router = IUniswapV2Router02(router_);
        emit SetRouter(router_);
    }

    function setTreasury(
        address treasury_
    ) external onlyOwner notZeroOrDead(treasury_) {
        treasury = treasury_;
        emit SetTreasury(treasury_);
    }

    function setSTSP(address STSP_) external onlyOwner notZeroOrDead(STSP_) {
        STSP = STSP_;
        emit SetSTSP(STSP_);
    }

    function setSTS(address STS_) external onlyOwner notZeroOrDead(STS_) {
        STS = STS_;
        emit SetSTS(STS_);
    }

    function trigger() external {
        uint256 bal_two_tokens = IERC20(LP_TWO_TOKENS).balanceOf(address(this));
        uint256 bal_eth = IERC20(LP_ETH).balanceOf(address(this));

        if (bal_two_tokens > 0) {
            // approve router
            IERC20(LP_TWO_TOKENS).approve(address(router), bal_two_tokens);

            // remove LP
            router.removeLiquidity(
                STS,
                STSP,
                bal_two_tokens,
                1,
                1,
                address(this),
                block.timestamp + 100
            );
        }

        if (bal_eth > 0) {
            // approve router
            IERC20(LP_ETH).approve(address(router), bal_eth);

            // remove LP
            router.removeLiquidityETH(
                STS,
                bal_eth,
                1,
                1,
                address(this),
                block.timestamp + 100
            );
        }

        // send all STS to Sell Receiver
        if (IERC20(STS).balanceOf(address(this)) > 0) {
            IERC20(STS).transfer(
                IToken(STS).sellFeeRecipient(),
                IERC20(STS).balanceOf(address(this))
            );
        }

        // send rest to Treasury
        if (IERC20(STSP).balanceOf(address(this)) > 0) {
            IERC20(STSP).transfer(
                treasury,
                IERC20(STSP).balanceOf(address(this))
            );
        }

        if (address(this).balance > 0) {
            (bool s, ) = payable(treasury).call{value: address(this).balance}(
                ""
            );
            require(s, "ETH Treasury Payment Failed");
        }
    }

    receive() external payable {}
}