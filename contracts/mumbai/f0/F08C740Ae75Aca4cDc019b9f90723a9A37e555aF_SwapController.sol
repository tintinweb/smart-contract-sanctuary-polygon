// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ISwapController.sol";
import "../interfaces/IUniswapV2Router.sol";
import "./OrcusProtocol.sol";
import "../libraries/TransferHelper.sol";


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address account) external view returns (uint256);
}

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0, 'ds-math-division-by-zero');
        c = a / b;
    }
}

contract SwapController is ISwapController, OrcusProtocol {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    uint256 private constant TIMEOUT = 300;

    IUniswapV2Router private fbRouter;
    IUniswapV2Factory private fbFactory;
    IUniswapV2Pair private fbOruPair;
    IUniswapV2Pair private fbOusdPair;

    address public WBNB;  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   

    uint public maxResidual = 100; // 1%, set 10000 to disable

    IERC20 public oru;
    IERC20 public ousd;
    IERC20 public usdc;
    IERC20 public wastr;

    address[] public fbOruPairPath;
    address[] public fbOusdPairPath;
    address[] public fbWAstrPairPath;

    uint8[] private fbDexIdsFB;
    uint8[] private fbDexIdsQuick;

    event LogSetContracts(
        address fbRouter,
        address fbFactory,
        address fbOruPair,
        address fbOusdPair
    );
    event LogSetPairPaths(
        address[] fbOruPairPath,
        address[] fbOusdPairPath,
        address[] fbWAstrPairPath
    );
    event LogSetDexIds(uint8[] fbDexIdsFB, uint8[] fbDexIdsQuick);

    constructor(
        address _router,
        address _factory,
        address _OruPair,
        address _OusdPair,
        //address _WAstrPair, // 0x6e7a5FAFcec6BB1e78bAE2A1F0B612012BF14827
        address _oru,
        address _ousd,
        address _usdc, // 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
        address _wastr // 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270
    ) {
        require(
                _router != address(0) &&
                _factory != address(0) &&
                _OruPair != address(0) &&
                _OusdPair != address(0),
            "Swap: Invalid Address"
        );

        setContracts( _router, _factory, _OruPair, _OusdPair);

        address[] memory _OruPairPath = new address[](2);
        _OruPairPath[0] = _oru;
        _OruPairPath[1] = _usdc;
        address[] memory _OusdPairPath = new address[](2);
        _OusdPairPath[0] = _ousd;
        _OusdPairPath[1] = _usdc;
        address[] memory _WAstrPairPath = new address[](2);
        _WAstrPairPath[0] = _wastr;
        _WAstrPairPath[1] = _usdc;
        setPairPaths(_OruPairPath, _OusdPairPath, _WAstrPairPath);

        uint8[] memory _fbDexIdsFB = new uint8[](1);
        _fbDexIdsFB[0] = 0;
        uint8[] memory _fbDexIdsQuick = new uint8[](1);
        _fbDexIdsQuick[0] = 1;
        setDexIds(_fbDexIdsFB, _fbDexIdsQuick);

        oru = IERC20(_oru);
        ousd = IERC20(_ousd);
        usdc = IERC20(_usdc);
        wastr = IERC20(_wastr);

        WBNB = _wastr;
    }

    // Swap functions
    function swapUsdcToOusd(uint256 _amount, uint256 _minOut)
        external
        override
        nonReentrant
    {
        usdc.safeTransferFrom(msg.sender, address(this), _amount);
        usdc.safeApprove(address(fbRouter), 0);
        usdc.safeApprove(address(fbRouter), _amount);

        fbRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            _minOut,
            fbOusdPairPath,
            msg.sender,
            block.timestamp + TIMEOUT
        );
    }

    function swapUsdcToOru(uint256 _amount, uint256 _minOut)
        external
        override
        nonReentrant
    {
        usdc.safeTransferFrom(msg.sender, address(this), _amount);
        usdc.safeApprove(address(fbRouter), 0);
        usdc.safeApprove(address(fbRouter), _amount);

        fbRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            _minOut,
            fbOruPairPath,
            msg.sender,
            block.timestamp + TIMEOUT
        );
    }

    function swapOruToUsdc(uint256 _amount, uint256 _minOut)
        external
        override
        nonReentrant
    {
        oru.safeTransferFrom(msg.sender, address(this), _amount);
        oru.safeApprove(address(fbRouter), 0);
        oru.safeApprove(address(fbRouter), _amount);

        fbRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            _minOut,
            fbOruPairPath,
            msg.sender,
            block.timestamp + TIMEOUT
        );
    }

    function swapOusdToUsdc(uint256 _amount, uint256 _minOut)
        external
        override
        nonReentrant
    {
        ousd.safeTransferFrom(msg.sender, address(this), _amount);
        ousd.safeApprove(address(fbRouter), 0);
        ousd.safeApprove(address(fbRouter), _amount);

        fbRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            _minOut,
            fbOusdPairPath,
            msg.sender,
            block.timestamp + TIMEOUT
        );
    }

    function swapWAstrToUsdc(uint256 _amount, uint256 _minOut)
        external
        override
        nonReentrant
    {
        wastr.safeTransferFrom(msg.sender, address(this), _amount);
        wastr.safeApprove(address(fbRouter), 0);
        wastr.safeApprove(address(fbRouter), _amount);

        fbRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            _minOut,
            fbWAstrPairPath,
            msg.sender,
            block.timestamp + TIMEOUT
        );
    }

    function zapInOru(
        uint256 _amount,
        uint256 _minUsdc,
        uint256 _minLp
    ) external override nonReentrant returns (uint256) {
        oru.safeTransferFrom(msg.sender, address(this), _amount);

        uint256[] memory _amounts = new uint256[](3);
        _amounts[0] = _amount; // amount_from (ORU)
        _amounts[1] = _minUsdc; // minTokenB (USDC)
        _amounts[2] = _minLp; // minLp

        uint256 _lpAmount = _zapInToken(
            address(oru),
            _amounts,
            address(fbOruPair),
            true
        );

        require(_lpAmount > 0, "Swap: No lp");
        require(
            fbOruPair.transfer(msg.sender, _lpAmount),
            "Swap: Faild to transfer"
        );
        return _lpAmount;
    }

    function zapInUsdc(
        uint256 _amount,
        uint256 _minOru,
        uint256 _minLp
    ) external override nonReentrant returns (uint256) {
        usdc.safeTransferFrom(msg.sender, address(this), _amount);

        uint256[] memory _amounts = new uint256[](3);
        _amounts[0] = _amount; // amount_from (USDC)
        _amounts[1] = _minOru; // minTokenB (ORU)
        _amounts[2] = _minLp; // minLp

        uint256 _lpAmount = _zapInToken(
            address(usdc),
            _amounts,
            address(fbOruPair),
            true
        );

        require(_lpAmount > 0, "Swap: No lp");
        require(
            fbOruPair.transfer(msg.sender, _lpAmount),
            "Swap: Faild to transfer"
        );

        return _lpAmount;
    }

    function zapOutOru(uint256 _amount, uint256 _minOut)
        external
        override
        nonReentrant
        returns (uint256)
    {
        require(
            fbOruPair.transferFrom(msg.sender, address(this), _amount),
            "Swap: Failed to transfer pair"
        );


        uint256 _oruAmount = _zapOut(
            address(fbOruPair),
            _amount,
            address(oru),
            _minOut
        );

        

        require(_oruAmount > 0, "Swap: Oru amount is 0");
        oru.safeTransfer(msg.sender, _oruAmount);
        return _oruAmount;
    }

    // Setters
    function setContracts(
        address _router,
        address _factory,
        address _OruPair,
        address _OusdPair
    ) public onlyOwner {

        if (_router != address(0)) {
            fbRouter = IUniswapV2Router(_router);
        }
        if (_factory != address(0)) {
            fbFactory = IUniswapV2Factory(_factory);
        }
        if (_OruPair != address(0)) {
            fbOruPair = IUniswapV2Pair(_OruPair);
        }
        if (_OusdPair != address(0)) {
            fbOusdPair = IUniswapV2Pair(_OusdPair);
        }

        emit LogSetContracts(
            _router,
            _factory,
            _OruPair,
            _OusdPair
        );
    }

    function setPairPaths(
        address[] memory _OruPairPath,
        address[] memory _OusdPairPath,
        address[] memory _WAstrPairPath
    ) public onlyOwner {
        fbOruPairPath = _OruPairPath;
        fbOusdPairPath = _OusdPairPath;
        fbWAstrPairPath = _WAstrPairPath;

        emit LogSetPairPaths(fbOruPairPath, fbOusdPairPath, fbWAstrPairPath);
    }

    function setDexIds(
        uint8[] memory _fbDexIdsFB,
        uint8[] memory _fbDexIdsQuick
    ) public onlyOwner {
        fbDexIdsFB = _fbDexIdsFB;
        fbDexIdsQuick = _fbDexIdsQuick;

        emit LogSetDexIds(fbDexIdsFB, fbDexIdsQuick);
    }

    function _zapInToken(address _from, uint[] memory amounts, address _to, bool transferResidual) private returns (uint256 lpAmt) {
        _approveTokenIfNeeded(_from);

        if (_from == IUniswapV2Pair(_to).token0() || _from == IUniswapV2Pair(_to).token1()) {
            // swap half amount for other
            address other;
            uint256 sellAmount;
            {
                address token0 = IUniswapV2Pair(_to).token0();
                address token1 = IUniswapV2Pair(_to).token1();
                other = _from == token0 ? token1 : token0;
                sellAmount = calculateSwapInAmount(_to, _from, amounts[0], token0);
            }
            uint otherAmount = _swap(_from, sellAmount, other, address(this), _to);
            require(otherAmount >= amounts[1], "Zap: Insufficient Receive Amount");

            lpAmt = _pairDeposit(_to, _from, other, amounts[0].sub(sellAmount), otherAmount, msg.sender, false, transferResidual);
        } else {
            uint bnbAmount = _swapTokenForBNB(_from, amounts[0], address(this), address(0));
            lpAmt = _swapBNBToLp(IUniswapV2Pair(_to), bnbAmount, msg.sender, 0, transferResidual);
        }

        require(lpAmt >= amounts[2], "Zap: High Slippage In");
        return lpAmt;
    }

    function _zapOut (address _from, uint amount, address _toToken, uint256 _minTokensRec) private returns (uint256) {
        _approveTokenIfNeeded(_from);

        address token0;
        address token1;
        uint256 amountA;
        uint256 amountB;
        {
            IUniswapV2Pair pair = IUniswapV2Pair(_from);
            token0 = pair.token0();
            token1 = pair.token1();
            (amountA, amountB) = fbRouter.removeLiquidity(token0, token1, amount, 1, 1, address(this), block.timestamp);        
        }

        uint256 tokenBought;
        _approveTokenIfNeeded(token0);
        _approveTokenIfNeeded(token1);
        if (_toToken == WBNB) {
            address _lpOfFromAndTo = WBNB == token0 || WBNB == token1 ? _from : address(0);
            tokenBought = _swapTokenForBNB(token0, amountA, address(this), _lpOfFromAndTo);
            tokenBought = tokenBought + (_swapTokenForBNB(token1, amountB, address(this), _lpOfFromAndTo));
        } else {
            address _lpOfFromAndTo = _toToken == token0 || _toToken == token1 ? _from : address(0);
            tokenBought = _swap(token0, amountA, _toToken, address(this), _lpOfFromAndTo);
            tokenBought = tokenBought + (_swap(token1, amountB, _toToken, address(this), _lpOfFromAndTo));
        }

        require(tokenBought >= _minTokensRec, "Zap: High Slippage Out");
        if (_toToken == WBNB) {
            TransferHelper.safeTransferETH(msg.sender, tokenBought);
        } else {
            IERC20(_toToken).safeTransfer(msg.sender, tokenBought);
        }

        return tokenBought;
    }

    function _approveTokenIfNeeded(address token) private {
        if (IERC20(token).allowance(address(this), address(fbRouter)) == 0) {
            IERC20(token).safeApprove(address(fbRouter), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        }
    }

   
    function _swapTokenForBNB(address token, uint amount, address _receiver, address lpTokenBNB) private returns (uint) {
        if (token == WBNB) {
            _transferToken(WBNB, _receiver, amount);
            return amount;
        }

        address[] memory path = new address[](2); 
        path[0] = token;
        path[1] = WBNB;
        uint[] memory amounts;
        if (path.length > 0) {
            amounts = fbRouter.swapExactTokensForETH(amount, 1, path, _receiver, block.timestamp);
        } else if (lpTokenBNB != address(0)) {
            path = new address[](1);
            path[0] = lpTokenBNB;
            amounts = fbRouter.swapExactTokensForETH(amount, 1, path, _receiver, block.timestamp);
        } else {
            revert("FireBirdZap: !path TokenBNB");
        }

        return amounts[amounts.length - 1];
    }

    function _swap(address _from, uint _amount, address _to, address _receiver, address _lpOfFromTo) internal returns (uint) {
        if (_from == _to) {
            if (_receiver != address(this)) {
                IERC20(_from).safeTransfer(_receiver, _amount);
            }
            return _amount;
        }
        address[] memory path = new address[](2); 
        path[0] = _from;
        path[1] = _to;
        uint[] memory amounts;
        if (path.length > 0) {// use fireBird
            amounts = fbRouter.swapExactTokensForTokens(_amount, 1, path, _receiver, block.timestamp);
        } else if (_lpOfFromTo != address(0)) {
            path = new address[](1);
            path[0] = _lpOfFromTo;
            amounts = fbRouter.swapExactTokensForTokens(_amount, 1, path, _receiver, block.timestamp);
        } else {
            revert("FireBirdZap: !path swap");
        }

        return amounts[amounts.length - 1];
    }

    function _transferToken(address token, address to, uint amount) internal {
        if (amount == 0) {
            return;
        }

        if (token == WBNB) {
            IWETH(WBNB).withdraw(amount);
            if (to != address(this)) {
                TransferHelper.safeTransferETH(to, amount);
            }
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
        return;
    }

    function calculateSwapInAmount(address pair, address tokenIn, uint256 userIn, address pairToken0) internal view returns (uint256) {
        (uint32 tokenWeight0, uint32 tokenWeight1) = (50,50); // ????????????????????????????
        uint swapFee = 0; // ?????????????????????
        if (tokenWeight0 == 50) {
            (uint256 res0, uint256 res1,) = IUniswapV2Pair(pair).getReserves();
            uint reserveIn = tokenIn == pairToken0 ? res0 : res1;
            uint256 rMul = uint256(10000).sub(uint256(swapFee));
            return _getExactSwapInAmount(reserveIn, userIn, rMul);
        } else {
             uint256 otherWeight = tokenIn == pairToken0 ? uint256(tokenWeight1) : uint256(tokenWeight0);
            return userIn.mul(otherWeight).div(100);
        }
    }

    function _getExactSwapInAmount(
    uint256 reserveIn,
    uint256 userIn,
    uint256 rMul
  ) internal pure returns (uint256) {
    return Babylonian.sqrt(reserveIn.mul(userIn.mul(40000).mul(rMul) + reserveIn.mul(rMul.add(10000)).mul(rMul.add(10000)))).sub(reserveIn.mul(rMul.add(10000))) / (rMul.mul(2));
  }

  function _pairDeposit(
        address _pair,
        address _poolToken0,
        address _poolToken1,
        uint256 token0Bought,
        uint256 token1Bought,
        address receiver,
        bool isfireBirdPair,
        bool transferResidual
    ) internal returns (uint256 lpAmt) {
        _approveTokenIfNeeded(_poolToken0);
        _approveTokenIfNeeded(_poolToken1);

        uint256 amountA;
        uint256 amountB;
        (amountA, amountB, lpAmt) = fbRouter.addLiquidity(_poolToken0, _poolToken1, token0Bought, token1Bought, 1, 1, receiver, block.timestamp);

        uint amountAResidual = token0Bought.sub(amountA);
        if (transferResidual || amountAResidual > token0Bought.mul(maxResidual).div(10000)) {
            if (amountAResidual > 0) {
                //Returning Residue in token0, if any.
                _transferToken(_poolToken0, msg.sender, amountAResidual);
            }
        }

        uint amountBRedisual = token1Bought.sub(amountB);
        if (transferResidual || amountBRedisual > token1Bought.mul(maxResidual).div(10000)) {
            if (amountBRedisual > 0) {
                //Returning Residue in token1, if any
                _transferToken(_poolToken1, msg.sender, amountBRedisual);
            }
        }

        return lpAmt;
    }

        function _swapBNBToLp(IUniswapV2Pair pair, uint amount, address receiver, uint _minTokenB, bool transferResidual) private returns (uint256 lpAmt) {
        address lp = address(pair);

        // Lp
        if (pair.token0() == WBNB || pair.token1() == WBNB) {
            address token = pair.token0() == WBNB ? pair.token1() : pair.token0();
            uint swapValue = calculateSwapInAmount(lp, WBNB, amount, pair.token0());
            uint tokenAmount = _swapBNBForToken(token, swapValue, address(this), lp);
            require(tokenAmount >= _minTokenB, "Zap: Insufficient Receive Amount");

            uint256 wbnbAmount = amount.sub(swapValue);
            IWETH(WBNB).deposit{value : wbnbAmount}();
            lpAmt = _pairDeposit(lp, WBNB, token, wbnbAmount, tokenAmount, receiver, false, transferResidual);
        } else {
            address token0 = pair.token0();
            address token1 = pair.token1();
            uint token0Amount;
            uint token1Amount;
            {
                uint32 tokenWeight0 = 50; // ??????????????????????
                uint swap0Value = amount.mul(uint(tokenWeight0)).div(100);
                token0Amount = _swapBNBForToken(token0, swap0Value, address(this), address(0));
                token1Amount = _swapBNBForToken(token1, amount.sub(swap0Value), address(this), address(0));
            }

            lpAmt = _pairDeposit(lp, token0, token1, token0Amount, token1Amount, receiver, false, transferResidual);
        }
    }

    function _swapBNBForToken(address token, uint value, address _receiver, address lpBNBToken) private returns (uint) {
        if (token == WBNB) {
            IWETH(WBNB).deposit{value : value}();
            if (_receiver != address(this)) {
                IERC20(WBNB).safeTransfer(_receiver, value);
            }
            return value;
        }
        address[] memory path = new address[](2); 
        path[0] = WBNB;
        path[1] = token;
        uint[] memory amounts;
        if (path.length > 0) {
            amounts = fbRouter.swapExactETHForTokens{value : value}(1, path, _receiver, block.timestamp);
        } else if (lpBNBToken != address(0)) {
            path = new address[](1);
            path[0] = lpBNBToken;
            amounts = fbRouter.swapExactETHForTokens{value : value}(1, path, _receiver, block.timestamp);
        } else {
            revert("FireBirdZap: !path BNBToken");
        }

        return amounts[amounts.length - 1];
    }

}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
pragma solidity 0.8.4;

interface ISwapController {
    function swapUsdcToOusd(uint256 _amount, uint256 _minOut) external;

    function swapUsdcToOru(uint256 _amount, uint256 _minOut) external;

    function swapOruToUsdc(uint256 _amount, uint256 _minOut) external;

    function swapOusdToUsdc(uint256 _amount, uint256 _minOut) external;

    function zapInOru(
        uint256 _amount,
        uint256 _minUsdc,
        uint256 _minLp
    ) external returns (uint256);

    function zapInUsdc(
        uint256 _amount,
        uint256 _minOru,
        uint256 _minLp
    ) external returns (uint256);

    function zapOutOru(uint256 _amount, uint256 _minOut)
        external
        returns (uint256);

    function swapWAstrToUsdc(uint256 _amount, uint256 _minOut) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


interface IUniswapV2Router {
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

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

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
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract OrcusProtocol is Ownable, ReentrancyGuard {
    uint256 internal constant RATIO_PRECISION = 1e6;
    uint256 internal constant PRICE_PRECISION = 1e6;
    uint256 internal constant USDC_PRECISION = 1e6;
    uint256 internal constant MISSING_PRECISION = 1e12;
    uint256 internal constant OUSD_PRECISION = 1e18;
    uint256 internal constant ORU_PRECISION = 1e18;
    uint256 internal constant SWAP_FEE_PRECISION = 1e4;

    address internal constant ADDRESS_USDC =
        0x6a2d262D56735DbA19Dd70682B39F6bE9a931D98;
    address internal constant ADDRESS_WASTR =
        0xAeaaf0e2c81Af264101B9129C00F4440cCF0F720;

    address public operator;

    event OperatorUpdated(address indexed newOperator);

    constructor() {
        setOperator(msg.sender);
    }

    modifier onlyNonContract() {
        require(msg.sender == tx.origin, "Orcus: sender != origin");
        _;
    }

    modifier onlyOwnerOrOperator() {
        require(
            msg.sender == owner() || msg.sender == operator,
            "Orcus: sender != operator"
        );
        _;
    }

    function setOperator(address _operator) public onlyOwner {
        require(_operator != address(0), "Orcus: Invalid operator");
        operator = _operator;
        emit OperatorUpdated(operator);
    }

    function _currentBlockTs() internal view returns (uint64) {
        return SafeCast.toUint64(block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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