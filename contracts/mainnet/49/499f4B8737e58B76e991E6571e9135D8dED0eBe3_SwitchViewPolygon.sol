pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "../ISwitchView.sol";
import "./SwitchRootPolygon.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwitchViewPolygon is ISwitchView, SwitchRootPolygon {

    function(CalculateArgs memory args) view returns(uint256[] memory)[PATHS_COUNT] pathFunctions = [
        calculate,
        calculateETH,
        calculateRealETH
    ];

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts
    )
    public
    view
    returns(
        uint256 returnAmount,
        uint256[] memory distribution
    )
    {
        (returnAmount, distribution) = getExpectedReturn(
            ReturnArgs({
            fromToken: fromToken,
            destToken: destToken,
            amount: amount,
            parts: parts
            })
        );
    }

    function getExpectedReturn(
        ReturnArgs memory returnArgs
    )
    internal
    view
    returns(
        uint256 returnAmount,
        uint256[] memory mergedDistribution
    )
    {
        uint256[] memory distribution = new uint256[](DEXES_COUNT*PATHS_COUNT*PATHS_SPLIT);
        mergedDistribution = new uint256[](DEXES_COUNT*PATHS_COUNT);

        if (returnArgs.fromToken == returnArgs.destToken) {
            return (returnArgs.amount, distribution);
        }

        int256[][] memory matrix = new int256[][](DEXES_COUNT*PATHS_COUNT*PATHS_SPLIT);
        bool atLeastOnePositive = false;
        for (uint l = 0; l < DEXES_COUNT; l++) {
            uint256[] memory rets;
            for (uint m = 0; m < PATHS_COUNT; m++) {
                for (uint k = 0; k < PATHS_SPLIT; k++) {
                    uint256 i = l*PATHS_COUNT*PATHS_SPLIT+m*PATHS_SPLIT+k;
                    rets = pathFunctions[m](CalculateArgs({
                        fromToken:returnArgs.fromToken,
                        destToken:returnArgs.destToken,
                        factory:IUniswapFactory(factories[l]),
                        amount:returnArgs.amount,
                        parts:returnArgs.parts
                    }));

                    // Prepend zero
                    matrix[i] = new int256[](returnArgs.parts + 1);
                    for (uint j = 0; j < rets.length; j++) {
                        matrix[i][j + 1] = int256(rets[j]);
                        atLeastOnePositive = atLeastOnePositive || (matrix[i][j + 1] > 0);
                    }
                }
            }
        }

        if (!atLeastOnePositive) {
            for (uint i = 0; i < DEXES_COUNT*PATHS_COUNT*PATHS_SPLIT; i++) {
                for (uint j = 1; j < returnArgs.parts + 1; j++) {
                    if (matrix[i][j] == 0) {
                        matrix[i][j] = VERY_NEGATIVE_VALUE;
                    }
                }
            }
        }

        (, distribution) = _findBestDistribution(returnArgs.parts, matrix);

        returnAmount = _getReturnByDistribution(Args({
            fromToken: returnArgs.fromToken,
            destToken: returnArgs.destToken,
            amount: returnArgs.amount,
            parts: returnArgs.parts,
            distribution: distribution,
            matrix: matrix,
            pathFunctions: pathFunctions,
            dexes: factories
        })
        );
        for (uint i = 0; i < DEXES_COUNT*PATHS_COUNT*PATHS_SPLIT; i++) {
            mergedDistribution[i/PATHS_SPLIT] += distribution[i];
        }
        return (returnAmount, mergedDistribution);
    }

    struct Args {
        IERC20 fromToken;
        IERC20 destToken;
        uint256 amount;
        uint256 parts;
        uint256[] distribution;
        int256[][] matrix;
        function(CalculateArgs memory) view returns(uint256[] memory)[PATHS_COUNT] pathFunctions;
        IUniswapFactory[DEXES_COUNT] dexes;
    }

    function _getReturnByDistribution(
        Args memory args
    ) internal view returns(uint256 returnAmount) {
        bool[DEXES_COUNT*PATHS_COUNT*PATHS_SPLIT] memory exact = [
        true,  // "Quickswap"
        true,  // "Quickswap (MATIC)"
        true,  // "Quickswap (WETH)"
        true,  // "Quickswap"
        true,  // "Quickswap (MATIC)"
        true,  // "Quickswap (WETH)"
        true, // Sushiswap
        true, // Sushiswap (MATIC)
        true, // Sushiswap (WETH)
        true, // Sushiswap
        true, // Sushiswap (MATIC)
        true, // Sushiswap (WETH)
        true, // Dyfn
        true, // Dyfn (MATIC)
        true, // Dyfn (WETH)
        true, // Dyfn
        true, // Dyfn (MATIC)
        true, // Dyfn (WETH)
        true, // Dinoswap
        true, // Dinoswap (MATIC)
        true, // Dinoswap (WETH)
        true, // Dinoswap
        true, // Dinoswap (MATIC)
        true, // Dinoswap (WETH)
        true, // Apeswap
        true, // Apeswap (MATIC)
        true, // Apeswap (WETH)
        true, // Apeswap
        true, // Apeswap (MATIC)
        true // Apeswap (WETH)
        ];

        for (uint i = 0; i < DEXES_COUNT*PATHS_COUNT*PATHS_SPLIT; i++) {
            if (args.distribution[i] > 0) {
                if (args.distribution[i] == args.parts || exact[i]) {
                    int256 value = args.matrix[i][args.distribution[i]];
                    returnAmount = returnAmount.add(uint256(
                            (value == VERY_NEGATIVE_VALUE ? 0 : value)
                        ));
                }
                else {
                    uint256[] memory rets = args.pathFunctions[(i/PATHS_SPLIT)%PATHS_COUNT](CalculateArgs({
                    fromToken: args.fromToken,
                    destToken: args.destToken,
                    factory: args.dexes[i/(PATHS_COUNT*PATHS_SPLIT)],
                    amount: args.amount.mul(args.distribution[i]).div(args.parts),
                    parts: 1
                    }));
                    returnAmount = returnAmount.add(rets[0]);
                }
            }
        }
    }

    // View Helpers

    struct Balances {
        uint256 src;
        uint256 dst;
    }



    function _linearInterpolation100(
        uint256 value,
        uint256 parts
    ) internal pure returns(uint256[100] memory rets) {
        for (uint i = 0; i < parts; i++) {
            rets[i] = value.mul(i + 1).div(parts);
        }
    }


    function _calculateUniswapFormula(uint256 fromBalance, uint256 toBalance, uint256 amount) internal pure returns(uint256) {
        if (amount == 0) {
            return 0;
        }
        return amount.mul(toBalance).mul(997).div(
            fromBalance.mul(1000).add(amount.mul(997))
        );
    }



    function calculate(
        CalculateArgs memory args
    ) public view returns(uint256[] memory rets) {
        return _calculate(
            args.fromToken,
            args.destToken,
            args.factory,
            _linearInterpolation(args.amount, args.parts)
        );
    }

    function calculateETH(
        CalculateArgs memory args
    ) internal view returns(uint256[] memory rets) {
        if (args.fromToken.isETH() || args.fromToken == weth || args.destToken.isETH() || args.destToken == weth) {
            return new uint256[](args.parts);
        }

        return _calculateOverMidToken(
            args.fromToken,
            weth,
            args.destToken,
            args.factory,
            args.amount,
            args.parts
        );
    }


    function calculateRealETH(
        CalculateArgs memory args
    ) internal view returns(uint256[] memory rets) {
        if (args.fromToken == realWeth || args.destToken == realWeth) {
            return new uint256[](args.parts);
        }

        return _calculateOverMidToken(
            args.fromToken,
            realWeth,
            args.destToken,
            args.factory,
            args.amount,
            args.parts
        );
    }



    function _calculate(
        IERC20 fromToken,
        IERC20 destToken,
        IUniswapFactory factory,
        uint256[] memory amounts
    ) internal view returns(uint256[] memory rets) {
        rets = new uint256[](amounts.length);

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 destTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapExchange exchange = factory.getPair(fromTokenReal, destTokenReal);
        if (exchange != IUniswapExchange(0)) {
            uint256 fromTokenBalance = fromTokenReal.universalBalanceOf(address(exchange));
            uint256 destTokenBalance = destTokenReal.universalBalanceOf(address(exchange));
            for (uint i = 0; i < amounts.length; i++) {
                rets[i] = _calculateUniswapFormula(fromTokenBalance, destTokenBalance, amounts[i]);
            }
            return rets;
        }
    }

    function _calculateOverMidToken(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        IUniswapFactory factory,
        uint256 amount,
        uint256 parts
    ) internal view returns(uint256[] memory rets) {
        rets = _linearInterpolation(amount, parts);

        rets = _calculate(fromToken, midToken, factory, rets);
        rets = _calculate(midToken, destToken, factory, rets);
        return rets;
    }

    function _calculateNoReturn(
        IERC20 /*fromToken*/,
        IERC20 /*destToken*/,
        uint256 /*amount*/,
        uint256 parts
    ) internal view returns(uint256[] memory rets) {
        this;
        return new uint256[](parts);
    }
}

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IUniswapFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ISwitchView {

    struct ReturnArgs {
        IERC20 fromToken;
        IERC20 destToken;
        uint256 amount;
        uint256 parts;
    }

    struct CalculateArgs {
        IERC20 fromToken;
        IERC20 destToken;
        IUniswapFactory factory;
        uint256 amount;
        uint256 parts;
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts
    )
    public
    view
    returns(
        uint256 returnAmount,
        uint256[] memory distribution
    );
}

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "../ISwitchView.sol";
import "../IWETH.sol";
import "../lib/DisableFlags.sol";
import "../lib/UniversalERC20.sol";
import "../interfaces/IUniswapFactory.sol";
import "../lib/UniswapExchangeLib.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwitchRootPolygon is ISwitchView {
    using SafeMath for uint256;
    using DisableFlags for uint256;

    using UniversalERC20 for IERC20;
    using UniversalERC20 for IWETH;
    using UniswapExchangeLib for IUniswapExchange;

    uint256 constant internal DEXES_COUNT = 5;
    uint256 constant internal PATHS_COUNT = 3;
    uint256 constant internal PATHS_SPLIT = 2;
    IERC20 constant internal ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 constant internal ZERO_ADDRESS = IERC20(0);

    IWETH constant internal weth = IWETH(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    IWETH constant internal realWeth = IWETH(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);

    IUniswapFactory[DEXES_COUNT] public factories = [
        IUniswapFactory(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32), // quickswap,
        IUniswapFactory(0xc35DADB65012eC5796536bD9864eD8773aBc74C4), // sushiswap,
        IUniswapFactory(0xE7Fb3e833eFE5F9c441105EB65Ef8b261266423B), // dyfn,
        IUniswapFactory(0xc35DADB65012eC5796536bD9864eD8773aBc74C4), // dinoswap,
        IUniswapFactory(0xCf083Be4164828f00cAE704EC15a36D711491284) // apeswap
    ];

    int256 internal constant VERY_NEGATIVE_VALUE = -1e72;

    function _findBestDistribution(
        uint256 s,                // parts
        int256[][] memory amounts // exchangesReturns
    )
    internal
    pure
    returns(
        int256 returnAmount,
        uint256[] memory distribution
    )
    {
        uint256 n = amounts.length;

        int256[][] memory answer = new int256[][](n); // int[n][s+1]
        uint256[][] memory parent = new uint256[][](n); // int[n][s+1]

        for (uint i = 0; i < n; i++) {
            answer[i] = new int256[](s + 1);
            parent[i] = new uint256[](s + 1);
        }

        for (uint j = 0; j <= s; j++) {
            answer[0][j] = amounts[0][j];
            for (uint i = 1; i < n; i++) {
                answer[i][j] = -1e72;
            }
            parent[0][j] = 0;
        }

        for (uint i = 1; i < n; i++) {
            for (uint j = 0; j <= s; j++) {
                answer[i][j] = answer[i - 1][j];
                parent[i][j] = j;

                for (uint k = 1; k <= j; k++) {
                    if (answer[i - 1][j - k] + amounts[i][k] > answer[i][j]) {
                        answer[i][j] = answer[i - 1][j - k] + amounts[i][k];
                        parent[i][j] = j - k;
                    }
                }
            }
        }

        distribution = new uint256[](DEXES_COUNT*PATHS_COUNT*PATHS_SPLIT);

        uint256 partsLeft = s;
        for (uint curExchange = n - 1; partsLeft > 0; curExchange--) {
            distribution[curExchange] = partsLeft - parent[curExchange][partsLeft];
            partsLeft = parent[curExchange][partsLeft];
        }

        returnAmount = (answer[n - 1][s] == VERY_NEGATIVE_VALUE) ? 0 : answer[n - 1][s];
    }


    function _linearInterpolation(
        uint256 value,
        uint256 parts
    ) internal pure returns(uint256[] memory rets) {
        rets = new uint256[](parts);
        for (uint i = 0; i < parts; i++) {
            rets[i] = value.mul(i + 1).div(parts);
        }
    }

    function _tokensEqual(IERC20 tokenA, IERC20 tokenB) internal pure returns(bool) {
        return ((tokenA.isETH() && tokenB.isETH()) || tokenA == tokenB);
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IUniswapExchange.sol";

interface IUniswapFactory {
    function getPair(IERC20 tokenA, IERC20 tokenB) external view returns (IUniswapExchange pair);
}

pragma solidity ^0.5.0;

interface IUniswapExchange {
    function getReserves() external view returns(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
}

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

pragma solidity ^0.5.0;

library DisableFlags {
    function check(uint256 flags, uint256 flag) internal pure returns(bool) {
        return (flags & flag) != 0;
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

library UniversalERC20 {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private constant ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(IERC20 token, address to, uint256 amount) internal returns(bool) {
        if (amount == 0) {
            return true;
        }

        if (isETH(token)) {
            address(uint160(to)).transfer(amount);
        } else {
            token.transfer(to, amount);
            return true;
        }
    }

    function universalTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            require(from == msg.sender && msg.value >= amount, "Wrong useage of ETH.universalTransferFrom()");
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalTransferFromSenderToThis(IERC20 token, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            if (msg.value > amount) {
                // Return remainder if exist
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function universalApprove(IERC20 token, address to, uint256 amount) internal {
        if (!isETH(token)) {
            if (amount > 0 && token.allowance(address(this), to) > 0) {
                token.safeApprove(to, 0);
            }
            token.safeApprove(to, amount);
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function isETH(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(ZERO_ADDRESS) || address(token) == address(ETH_ADDRESS));
    }

    function notExist(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(-1));
    }
}

pragma solidity ^0.5.0;

import "../interfaces/IUniswapExchange.sol";
import "./Math.sol";
import "./UniversalERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library UniswapExchangeLib {
    using Math for uint256;
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    function getReturn(
        IUniswapExchange exchange,
        IERC20 fromToken,
        IERC20 destToken,
        uint amountIn
    ) internal view returns (uint256 result, bool needSync, bool needSkim) {
        uint256 reserveIn = fromToken.universalBalanceOf(address(exchange));
        uint256 reserveOut = destToken.universalBalanceOf(address(exchange));
        (uint112 reserve0, uint112 reserve1,) = exchange.getReserves();
        if (fromToken > destToken) {
            (reserve0, reserve1) = (reserve1, reserve0);
        }
        needSync = (reserveIn < reserve0 || reserveOut < reserve1);
        needSkim = !needSync && (reserveIn > reserve0 || reserveOut > reserve1);

        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(Math.min(reserveOut, reserve1));
        uint256 denominator = Math.min(reserveIn, reserve0).mul(1000).add(amountInWithFee);
        result = (denominator == 0) ? 0 : numerator.div(denominator);
    }
}

pragma solidity ^0.5.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.5;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}