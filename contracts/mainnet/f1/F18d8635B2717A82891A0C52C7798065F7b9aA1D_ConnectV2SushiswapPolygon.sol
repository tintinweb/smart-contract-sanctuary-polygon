// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title SushiSwap.
 * @dev Decentralized Exchange.
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract SushiswapResolver is Helpers, Events {
    /**
     * @dev Deposit Liquidity.
     * @notice Deposit Liquidity to a SushiSwap pool.
     * @param tokenA The address of token A.(For Matic: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param tokenB The address of token B.(For Matic: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amtA The amount of A tokens to deposit.
     * @param unitAmt The unit amount of of amtB/amtA with slippage.
     * @param slippage Slippage amount.
     * @param getId ID to retrieve amtA.
     * @param setId ID stores the amount of pools tokens received.
    */
    function deposit(
        address tokenA,
        address tokenB,
        uint256 amtA,
        uint256 unitAmt,
        uint256 slippage,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amtA);

        (uint _amtA, uint _amtB, uint _uniAmt) = _addLiquidity(
                                            tokenA,
                                            tokenB,
                                            _amt,
                                            unitAmt,
                                            slippage
                                        );
        setUint(setId, _uniAmt);
        
        _eventName = "LogDepositLiquidity(address,address,uint256,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(tokenA, tokenB, _amtA, _amtB, _uniAmt, getId, setId);
    }

    /**
     * @dev Withdraw Liquidity.
     * @notice Withdraw Liquidity from a SushiSwap pool.
     * @param tokenA The address of token A.(For Matic: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param tokenB The address of token B.(For Matic: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param uniAmt The amount of pool tokens to withdraw.
     * @param unitAmtA The unit amount of amtA/uniAmt with slippage.
     * @param unitAmtB The unit amount of amtB/uniAmt with slippage.
     * @param getId ID to retrieve uniAmt.
     * @param setIds Array of IDs to store the amount tokens received.
    */
    function withdraw(
        address tokenA,
        address tokenB,
        uint256 uniAmt,
        uint256 unitAmtA,
        uint256 unitAmtB,
        uint256 getId,
        uint256[] calldata setIds
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, uniAmt);

        (uint _amtA, uint _amtB, uint _uniAmt) = _removeLiquidity(
            tokenA,
            tokenB,
            _amt,
            unitAmtA,
            unitAmtB
        );

        setUint(setIds[0], _amtA);
        setUint(setIds[1], _amtB);
        
        _eventName = "LogWithdrawLiquidity(address,address,uint256,uint256,uint256,uint256,uint256[])";
        _eventParam = abi.encode(tokenA, tokenB, _amtA, _amtB, _uniAmt, getId, setIds);
    }

    /**
     * @dev Buy Matic/ERC20_Token.
     * @notice Buy a token using a SushiSwap
     * @param buyAddr The address of the token to buy.(For Matic: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr The address of the token to sell.(For Matic: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param buyAmt The amount of tokens to buy.
     * @param unitAmt The unit amount of sellAmt/buyAmt with slippage.
     * @param getId ID to retrieve buyAmt.
     * @param setId ID to store the amount of tokens sold.
    */
    function buy(
        address buyAddr,
        address sellAddr,
        uint256 buyAmt,
        uint256 unitAmt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _buyAmt = getUint(getId, buyAmt);
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeMaticAddress(buyAddr, sellAddr);
        address[] memory paths = getPaths(address(_buyAddr), address(_sellAddr));

        uint _slippageAmt = convert18ToDec(_sellAddr.decimals(),
            wmul(unitAmt, convertTo18(_buyAddr.decimals(), _buyAmt))
        );

        checkPair(paths);
        uint _expectedAmt = getExpectedSellAmt(paths, _buyAmt);
        require(_slippageAmt >= _expectedAmt, "Too much slippage");

        bool isMatic = address(_sellAddr) == wmaticAddr;
        convertMaticToWmatic(isMatic, _sellAddr, _expectedAmt);
        approve(_sellAddr, address(router), _expectedAmt);

        uint _sellAmt = router.swapTokensForExactTokens(
            _buyAmt,
            _expectedAmt,
            paths,
            address(this),
            block.timestamp + 1
        )[0];

        isMatic = address(_buyAddr) == wmaticAddr;
        convertWmaticToMatic(isMatic, _buyAddr, _buyAmt);

        setUint(setId, _sellAmt);

        _eventName = "LogBuy(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
    }

    /**
     * @dev Sell Matic/ERC20_Token.
     * @notice Sell a token using a SushiSwap
     * @param buyAddr The address of the token to buy.(For Matic: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAddr The address of the token to sell.(For Matic: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param sellAmt The amount of the token to sell.
     * @param unitAmt The unit amount of buyAmt/sellAmt with slippage.
     * @param getId ID to retrieve sellAmt.
     * @param setId ID stores the amount of token brought.
    */
    function sell(
        address buyAddr,
        address sellAddr,
        uint256 sellAmt,
        uint256 unitAmt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _sellAmt = getUint(getId, sellAmt);
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeMaticAddress(buyAddr, sellAddr);
        address[] memory paths = getPaths(address(_buyAddr), address(_sellAddr));

        if (_sellAmt == uint(-1)) {
            _sellAmt = sellAddr == maticAddr ?
                address(this).balance :
                _sellAddr.balanceOf(address(this));
        }

        uint _slippageAmt = convert18ToDec(_buyAddr.decimals(),
            wmul(unitAmt, convertTo18(_sellAddr.decimals(), _sellAmt))
        );

        checkPair(paths);
        uint _expectedAmt = getExpectedBuyAmt(paths, _sellAmt);
        require(_slippageAmt <= _expectedAmt, "Too much slippage");

        bool isMatic = address(_sellAddr) == wmaticAddr;
        convertMaticToWmatic(isMatic, _sellAddr, _sellAmt);
        approve(_sellAddr, address(router), _sellAmt);

        uint _buyAmt = router.swapExactTokensForTokens(
            _sellAmt,
            _expectedAmt,
            paths,
            address(this),
            block.timestamp + 1
        )[1];

        isMatic = address(_buyAddr) == wmaticAddr;
        convertWmaticToMatic(isMatic, _buyAddr, _buyAmt);

        setUint(setId, _buyAmt);

        _eventName = "LogSell(address,address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(buyAddr, sellAddr, _buyAmt, _sellAmt, getId, setId);
    }
}

contract ConnectV2SushiswapPolygon is SushiswapResolver {
    string public constant name = "Sushiswap-v1";
}

pragma solidity ^0.7.0;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
    function gemJoinMapping(bytes32) external view returns (address);
}

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
    function isAuth(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import {TokenInterface} from "../../common/interfaces.sol";
import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import {ISushiSwapRouter, ISushiSwapFactory} from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    /**
     * @dev ISushiSwapRouter
     */
    ISushiSwapRouter internal constant router =
        ISushiSwapRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    function getExpectedBuyAmt(address[] memory paths, uint256 sellAmt)
        internal
        view
        returns (uint256 buyAmt)
    {
        uint256[] memory amts = router.getAmountsOut(sellAmt, paths);
        buyAmt = amts[1];
    }

    function getExpectedSellAmt(address[] memory paths, uint256 buyAmt)
        internal
        view
        returns (uint256 sellAmt)
    {
        uint256[] memory amts = router.getAmountsIn(buyAmt, paths);
        sellAmt = amts[0];
    }

    function checkPair(address[] memory paths) internal view {
        address pair = ISushiSwapFactory(router.factory()).getPair(
            paths[0],
            paths[1]
        );
        require(pair != address(0), "No-exchange-address");
    }

    function getPaths(address buyAddr, address sellAddr)
        internal
        pure
        returns (address[] memory paths)
    {
        paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
    }

    function getMinAmount(
        TokenInterface token,
        uint256 amt,
        uint256 slippage
    ) internal view returns (uint256 minAmt) {
        uint256 _amt18 = convertTo18(token.decimals(), amt);
        minAmt = wmul(_amt18, sub(WAD, slippage));
        minAmt = convert18ToDec(token.decimals(), minAmt);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 _amt,
        uint256 unitAmt,
        uint256 slippage
    )
        internal
        returns (
            uint256 _amtA,
            uint256 _amtB,
            uint256 _liquidity
        )
    {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeMaticAddress(
            tokenA,
            tokenB
        );

        _amtA = _amt == uint256(-1)
            ? getTokenBal(TokenInterface(tokenA))
            : _amt;
        _amtB = convert18ToDec(
            _tokenB.decimals(),
            wmul(unitAmt, convertTo18(_tokenA.decimals(), _amtA))
        );

        bool isMatic = address(_tokenA) == wmaticAddr;
        convertMaticToWmatic(isMatic, _tokenA, _amtA);

        isMatic = address(_tokenB) == wmaticAddr;
        convertMaticToWmatic(isMatic, _tokenB, _amtB);

        approve(_tokenA, address(router), _amtA);
        approve(_tokenB, address(router), _amtB);

        uint256 minAmtA = getMinAmount(_tokenA, _amtA, slippage);
        uint256 minAmtB = getMinAmount(_tokenB, _amtB, slippage);
        (_amtA, _amtB, _liquidity) = router.addLiquidity(
            address(_tokenA),
            address(_tokenB),
            _amtA,
            _amtB,
            minAmtA,
            minAmtB,
            address(this),
            block.timestamp + 1
        );
    }

    function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 _amt,
        uint256 unitAmtA,
        uint256 unitAmtB
    )
        internal
        returns (
            uint256 _amtA,
            uint256 _amtB,
            uint256 _uniAmt
        )
    {
        TokenInterface _tokenA;
        TokenInterface _tokenB;
        (_tokenA, _tokenB, _uniAmt) = _getRemoveLiquidityData(
            tokenA,
            tokenB,
            _amt
        );
        {
            uint256 minAmtA = convert18ToDec(
                _tokenA.decimals(),
                wmul(unitAmtA, _uniAmt)
            );
            uint256 minAmtB = convert18ToDec(
                _tokenB.decimals(),
                wmul(unitAmtB, _uniAmt)
            );
            (_amtA, _amtB) = router.removeLiquidity(
                address(_tokenA),
                address(_tokenB),
                _uniAmt,
                minAmtA,
                minAmtB,
                address(this),
                block.timestamp + 1
            );
        }

        bool isMatic = address(_tokenA) == wmaticAddr;
        convertWmaticToMatic(isMatic, _tokenA, _amtA);

        isMatic = address(_tokenB) == wmaticAddr;
        convertWmaticToMatic(isMatic, _tokenB, _amtB);
    }

    function _getRemoveLiquidityData(
        address tokenA,
        address tokenB,
        uint256 _amt
    )
        internal
        returns (
            TokenInterface _tokenA,
            TokenInterface _tokenB,
            uint256 _uniAmt
        )
    {
        (_tokenA, _tokenB) = changeMaticAddress(tokenA, tokenB);
        address exchangeAddr = ISushiSwapFactory(router.factory()).getPair(
            address(_tokenA),
            address(_tokenB)
        );
        require(exchangeAddr != address(0), "pair-not-found.");

        TokenInterface uniToken = TokenInterface(exchangeAddr);
        _uniAmt = _amt == uint256(-1)
            ? uniToken.balanceOf(address(this))
            : _amt;
        approve(uniToken, address(router), _uniAmt);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
    event LogDepositLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint256 amtA,
        uint256 amtB,
        uint256 uniAmount,
        uint256 getId,
        uint256 setId
    );

    event LogWithdrawLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 uniAmount,
        uint256 getId,
        uint256[] setId
    );
    
    event LogBuy(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    event LogSell(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );
}

pragma solidity ^0.7.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

contract DSMath {
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function add(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(x, y);
  }

  function sub(uint x, uint y) internal virtual pure returns (uint z) {
    z = SafeMath.sub(x, y);
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.mul(x, y);
  }

  function div(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.div(x, y);
  }

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
  }

  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
  }

  function toInt(uint x) internal pure returns (int y) {
    y = int(x);
    require(y >= 0, "int-overflow");
  }

  function toRad(uint wad) internal pure returns (uint rad) {
    rad = mul(wad, 10 ** 27);
  }

}

pragma solidity ^0.7.0;

import { TokenInterface } from "./interfaces.sol";
import { Stores } from "./stores.sol";
import { DSMath } from "./math.sol";

abstract contract Basic is DSMath, Stores {

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function getTokenBal(TokenInterface token) internal view returns(uint _amt) {
        _amt = address(token) == maticAddr ? address(this).balance : token.balanceOf(address(this));
    }

    function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr) internal view returns(uint buyDec, uint sellDec) {
        buyDec = address(buyAddr) == maticAddr ?  18 : buyAddr.decimals();
        sellDec = address(sellAddr) == maticAddr ?  18 : sellAddr.decimals();
    }

    function encodeEvent(string memory eventName, bytes memory eventParam) internal pure returns (bytes memory) {
        return abi.encode(eventName, eventParam);
    }

    function changeMaticAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == maticAddr ? TokenInterface(wmaticAddr) : TokenInterface(buy);
        _sell = sell == maticAddr ? TokenInterface(wmaticAddr) : TokenInterface(sell);
    }

    function approve(TokenInterface token, address spender, uint256 amount) internal {
        try token.approve(spender, amount) {

        } catch {
            token.approve(spender, 0);
            token.approve(spender, amount);
        }
    }

    function convertMaticToWmatic(bool isMatic, TokenInterface token, uint amount) internal {
        if(isMatic) token.deposit{value: amount}();
    }

    function convertWmaticToMatic(bool isMatic, TokenInterface token, uint amount) internal {
        if(isMatic) {
            approve(token, address(token), amount);
            token.withdraw(amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface ISushiSwapRouter {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface ISushiSwapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.7.0;

import { MemoryInterface, InstaMapping } from "./interfaces.sol";


abstract contract Stores {

  /**
   * @dev Return ethereum address
   */
  address constant internal maticAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
   * @dev Return Wrapped ETH address
   */
  address constant internal wmaticAddr = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

  /**
   * @dev Return memory variable address
   */
  MemoryInterface constant internal instaMemory = MemoryInterface(0x6C7256cf7C003dD85683339F75DdE9971f98f2FD);

  /**
   * @dev Get Uint value from InstaMemory Contract.
   */
  function getUint(uint getId, uint val) internal returns (uint returnVal) {
    returnVal = getId == 0 ? val : instaMemory.getUint(getId);
  }

  /**
  * @dev Set Uint value in InstaMemory Contract.
  */
  function setUint(uint setId, uint val) virtual internal {
    if (setId != 0) instaMemory.setUint(setId, val);
  }

}