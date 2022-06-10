/**
 *Submitted for verification at polygonscan.com on 2022-06-09
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface INfmController {
    function _checkWLSC(address Controller, address Client)
        external
        pure
        returns (bool);

    function _getNFM() external pure returns (address);

    function _getTimer() external pure returns (address);

    function _getSwap() external pure returns (address);

    function _getLiquidity() external pure returns (address);

    function _getUV2Pool() external pure returns (address);

    function _getExchange() external pure returns (address);

    function _getDistribute() external pure returns (address);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface INfmTimer {
    function _getStartTime() external pure returns (uint256);

    function _getUV2_RemoveLiquidityTime() external pure returns (uint256);
}

contract NFMUV2Pool {
    using SafeMath for uint256;
    struct Exchanges {
        uint256 AmountA;
        uint256 AmountB;
        address currency;
        uint256 timer;
    }

    struct LiquidityAdded {
        uint256 AmountA;
        uint256 AmountB;
        uint256 LP;
        address currency;
        uint256 timer;
    }

    struct LiquidityRemove {
        uint256 AmountA;
        uint256 AmountB;
        uint256 LP;
        address currency;
        uint256 timer;
    }
    event Swap(
        address indexed Coin,
        address indexed NFM,
        uint256 AmountCoin,
        uint256 AmountNFM
    );
    event Liquidity(
        address indexed Coin,
        address indexed NFM,
        uint256 AmountCoin,
        uint256 AmountNFM
    );
    event rmLiquidity(
        address indexed Coin,
        address indexed NFM,
        uint256 AmountCoin,
        uint256 AmountNFM
    );
    event UV2Pair(address indexed Coin, address indexed NFM, address Pair);

    address private _Owner;
    address private _SController;
    INfmController private _Controller;
    IUniswapV2Router02 public _uniswapV2Router;
    mapping(address => address) public _UV2Pairs;
    mapping(uint256 => Exchanges) public _RealizedSwaps;
    mapping(uint256 => LiquidityAdded) public _AddedLiquidity;
    mapping(uint256 => LiquidityRemove) public _RemovedLiquidity;
    uint256 private _LiquidityCounter = 0;
    uint256 private _SwapingCounter = 0;
    uint256 private _RemoveLPCounter = 0;
    address[] private _Coins;

    modifier onlyOwner() {
        require(
            _Controller._checkWLSC(_SController, msg.sender) == true ||
                _Owner == msg.sender,
            "oO"
        );
        require(msg.sender != address(0), "0A");
        _;
    }

    constructor(address Controller, address UniswapRouter) {
        _Owner = msg.sender;
        _SController = Controller;
        INfmController Cont = INfmController(Controller);
        _Controller = Cont;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(UniswapRouter);
        _uniswapV2Router = uniswapV2Router;
    }

    //Store StructSwap
    function storeSwap(
        uint256 AmountA,
        uint256 AmountB,
        address currency
    ) internal virtual onlyOwner {
        _RealizedSwaps[_SwapingCounter] = Exchanges(
            AmountA,
            AmountB,
            currency,
            block.timestamp
        );
        _SwapingCounter++;
    }

    //Show Struct Swap
    function getSwapsArray(uint256 Elements)
        public
        view
        returns (Exchanges[] memory)
    {
        if (Elements == 0) {
            Exchanges[] memory lExchanges = new Exchanges[](_SwapingCounter);
            for (uint256 i = 0; i < _SwapingCounter; i++) {
                Exchanges storage lExchang = _RealizedSwaps[i];
                lExchanges[i] = lExchang;
            }
            return lExchanges;
        } else {
            Exchanges[] memory lExchanges = new Exchanges[](Elements);
            for (
                uint256 i = _SwapingCounter - Elements;
                i < _SwapingCounter;
                i++
            ) {
                Exchanges storage lExchang = _RealizedSwaps[i];
                lExchanges[i] = lExchang;
            }
            return lExchanges;
        }
    }

    //Store StructLiquidty
    function storeLiquidity(
        uint256 AmountA,
        uint256 AmountB,
        uint256 LP,
        address currency
    ) internal virtual onlyOwner {
        _AddedLiquidity[_LiquidityCounter] = LiquidityAdded(
            AmountA,
            AmountB,
            LP,
            currency,
            block.timestamp
        );
        _LiquidityCounter++;
    }

    //Show StructLiquidty
    function getLPArray(uint256 Elements)
        public
        view
        returns (LiquidityAdded[] memory)
    {
        if (Elements == 0) {
            LiquidityAdded[] memory lLiquidityAdded = new LiquidityAdded[](
                _LiquidityCounter
            );
            for (uint256 i = 0; i < _LiquidityCounter; i++) {
                LiquidityAdded storage lLiquidityAdd = _AddedLiquidity[i];
                lLiquidityAdded[i] = lLiquidityAdd;
            }
            return lLiquidityAdded;
        } else {
            LiquidityAdded[] memory lLiquidityAdded = new LiquidityAdded[](
                Elements
            );
            for (
                uint256 i = _LiquidityCounter - Elements;
                i < _LiquidityCounter;
                i++
            ) {
                LiquidityAdded storage lLiquidityAdd = _AddedLiquidity[i];
                lLiquidityAdded[i] = lLiquidityAdd;
            }
            return lLiquidityAdded;
        }
    }

    //Store StructRemoveLP
    function storeLiquidityRemove(
        uint256 AmountA,
        uint256 AmountB,
        uint256 LP,
        address currency
    ) internal virtual onlyOwner {
        _RemovedLiquidity[_RemoveLPCounter] = LiquidityRemove(
            AmountA,
            AmountB,
            LP,
            currency,
            block.timestamp
        );
        _RemoveLPCounter++;
    }

    //Show StructRemoveLP
    function getRemoveLPArray(uint256 Elements)
        public
        view
        returns (LiquidityRemove[] memory)
    {
        if (Elements == 0) {
            LiquidityRemove[] memory lLiquidityRemove = new LiquidityRemove[](
                _RemoveLPCounter
            );
            for (uint256 i = 0; i < _RemoveLPCounter; i++) {
                LiquidityRemove storage lLiquidityRem = _RemovedLiquidity[i];
                lLiquidityRemove[i] = lLiquidityRem;
            }
            return lLiquidityRemove;
        } else {
            LiquidityRemove[] memory lLiquidityRemove = new LiquidityRemove[](
                Elements
            );
            for (
                uint256 i = _RemoveLPCounter - Elements;
                i < _RemoveLPCounter;
                i++
            ) {
                LiquidityRemove storage lLiquidityRem = _RemovedLiquidity[i];
                lLiquidityRemove[i] = lLiquidityRem;
            }
            return lLiquidityRemove;
        }
    }

    //Add Coins to the Uniswap Protocol by creating Pools
    function _addUV2Pair(address Coin) public onlyOwner returns (bool) {
        _UV2Pairs[Coin] = IUniswapV2Factory(
            IUniswapV2Router02(_uniswapV2Router).factory()
        ).createPair(
                address(_Controller._getNFM()),
                address(
                    Coin /*COIN ADDRESS */
                )
            );
        _Coins.push(Coin);
        emit UV2Pair(Coin, _Controller._getNFM(), _UV2Pairs[Coin]);
        _Controller._checkWLSC(address(_SController), address(_UV2Pairs[Coin]));
        return true;
    }

    //Show Coins array
    function _returnCoinsArray() public view returns (address[] memory) {
        return _Coins;
    }

    //Show Liquidity Pool Token Balances on each Coin
    function _showLPBalances(address Coin) public view returns (uint256) {
        return IERC20(address(_UV2Pairs[Coin])).balanceOf(address(this));
    }

    //Show Coin Balances on the Contract
    function _showContractBalanceOf(address Coin)
        public
        view
        returns (uint256)
    {
        return IERC20(address(Coin)).balanceOf(address(this));
    }

    //Show Array length of all Coins on the Protocol
    function _showPairNum() public view returns (uint256) {
        return _Coins.length;
    }

    //SWAPCHECK FUNCTION TO SEE RETURNS BEFORE SWAPPING
    //Amount NFM => COIN ADDRESS
    function getamountOutOnSwap(uint256 amount, address Coin)
        public
        view
        returns (uint256)
    {
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(
            address(_UV2Pairs[Coin])
        ).getReserves();
        uint256 amountOut = IUniswapV2Router02(_uniswapV2Router).getAmountOut(
            amount,
            reserve0,
            reserve1
        );
        return amountOut;
    }

    //ADD LIQUIDITY ON POOLS
    //First Amount is always NFM second Amount is Coin
    function addLiquidity(
        uint256 AmountTA,
        uint256 AmountTB,
        address Coin
    ) public virtual onlyOwner returns (bool) {
        // approve token transfer to cover all possible scenarios
        IERC20(address(_Controller._getNFM())).approve(
            address(_uniswapV2Router),
            AmountTA
        );
        IERC20(address(Coin)).approve(address(_uniswapV2Router), AmountTB);

        // add the liquidity
        (uint256 amountA, uint256 amountB, uint256 liquidity) = _uniswapV2Router
            .addLiquidity(
                address(_Controller._getNFM()),
                address(Coin),
                AmountTA,
                AmountTB,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                address(this),
                block.timestamp + 1
            );
        storeLiquidity(amountA, amountB, liquidity, address(Coin));
        emit Liquidity(
            address(Coin),
            address(_Controller._getNFM()),
            amountB,
            amountA
        );
        return true;
    }

    //SWAP NFM AGAINST LIQUIDITY
    //SEND ADDRESS COIN AND AMOUNT NFM
    function swapNFMforTokens(address Coin, uint256 amount)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        uint256 OBalA = IERC20(address(_Controller._getNFM())).balanceOf(
            address(this)
        );
        uint256 OBalB = IERC20(address(Coin)).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(_Controller._getNFM());
        path[1] = address(Coin);

        IERC20(address(_Controller._getNFM())).approve(
            address(_uniswapV2Router),
            amount
        );

        _uniswapV2Router.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp + 1
        );

        uint256 NBalA = IERC20(address(_Controller._getNFM())).balanceOf(
            address(this)
        );
        uint256 NBalB = IERC20(address(Coin)).balanceOf(address(this));
        uint256 AmountA = 0;
        uint256 AmountB = 0;
        if (NBalA == 0) {
            AmountA = OBalA;
        } else {
            AmountA = SafeMath.sub(OBalA, NBalA);
        }
        if (NBalB == 0) {
            AmountB = OBalB;
        } else {
            AmountB = SafeMath.sub(NBalB, OBalB);
        }
        storeSwap(AmountA, AmountB, address(Coin));
        emit Swap(
            address(Coin),
            address(_Controller._getNFM()),
            AmountB,
            AmountA
        );
        return true;
    }

    //REMOVE LIQUIDITY ON POOLS
    //LP Tokens are Locked for 11 Years. Checkout LP Timer Lock for more information
    function removeLiquidity(address Coin)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        require(
            INfmTimer(address(_Controller._getTimer()))._getStartTime() > 0 &&
                INfmTimer(address(_Controller._getTimer()))
                    ._getUV2_RemoveLiquidityTime() <
                block.timestamp,
            "NIT"
        );
        uint256 LPTokenBalance = _showLPBalances(Coin);
        // approve token transfer to cover all possible scenarios
        IERC20(address(_UV2Pairs[Coin])).approve(
            address(_uniswapV2Router),
            LPTokenBalance
        );
        // remove the liquidity
        (uint256 amountA, uint256 amountB) = _uniswapV2Router.removeLiquidity(
            address(_Controller._getNFM()),
            address(Coin),
            LPTokenBalance,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp + 1
        );
        storeLiquidityRemove(amountA, amountB, LPTokenBalance, address(Coin));
        emit rmLiquidity(
            address(Coin),
            address(_Controller._getNFM()),
            amountB,
            amountA
        );
        return true;
    }

    //WithdrawFunction for funds will be managed by Governance and other contracts.
    function _getWithdraw(
        address Coin,
        address To,
        uint256 amount,
        bool percent
    ) public onlyOwner returns (bool) {
        require(To != address(0), "0A");
        uint256 CoinAmount = IERC20(address(Coin)).balanceOf(address(this));
        if (percent == true) {
            //makeCalcs on Percentatge
            uint256 AmountToSend = SafeMath.div(
                SafeMath.mul(CoinAmount, amount),
                100
            );
            IERC20(address(Coin)).transfer(To, AmountToSend);
            return true;
        } else {
            if (amount == 0) {
                IERC20(address(Coin)).transfer(To, CoinAmount);
            } else {
                IERC20(address(Coin)).transfer(To, amount);
            }
            return true;
        }
    }
}