// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// FORKED FROM https://github.com/stargate-protocol/stargate

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IStargatePool.sol";

interface IStargateFactory {
    function allPools(uint256) external view returns (IStargatePool);

    function allPoolsLength() external view returns (uint256);
}

// FORKED FROM https://github.com/stargate-protocol/stargate

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IStargatePool.sol";

interface IStargateFeeLibrary {
    function getFees(
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        uint16 _dstChainId,
        address _from,
        uint256 _amountSD
    ) external view returns (IStargatePool.SwapObj memory s);
}

// FORKED FROM https://github.com/stargate-protocol/stargate

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStargatePool {
    struct ChainPath {
        bool ready;
        uint16 dstChainId;
        uint256 dstPoolId;
        uint256 weight;
        uint256 balance;
        uint256 lkb;
        uint256 credits;
        uint256 idealBalance;
    }

    struct SwapObj {
        uint256 amount;
        uint256 eqFee;
        uint256 eqReward;
        uint256 lpFee;
        uint256 protocolFee;
        uint256 lkbRemove;
    }

    function poolId() external view returns (uint256);

    function token() external view returns (address);

    function convertRate() external view returns (uint256);

    function feeLibrary() external view returns (address);

    function chainPaths(uint256) external view returns (ChainPath memory);

    function getChainPathsLength() external view returns (uint256);

    function getChainPath(
        uint16 _dstChainId,
        uint256 _dstPoolId
    ) external view returns (ChainPath memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapV2Pair.sol";

interface IUniswapV2Factory {
    function getPair(address, address) external view returns (IUniswapV2Pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112, uint112, uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../interfaces/IStargatePool.sol";
import "../interfaces/IStargateFeeLibrary.sol";

library StargateHelper {
    using SafeMath for uint256;

    function quote(
        IStargatePool pool,
        uint16 _dstChainId,
        uint256 _dstPoolId,
        uint256 _amountLD
    ) internal view returns (uint256 amount) {
        uint256 amountSD = amountLDtoSD(pool, _amountLD);
        address _from;
        IStargatePool.SwapObj memory s = IStargateFeeLibrary(pool.feeLibrary()).getFees(
            pool.poolId(),
            _dstPoolId,
            _dstChainId,
            _from,
            amountSD
        );
        amount = amountSD.sub(s.eqFee).sub(s.protocolFee).sub(s.lpFee);
    }

    function amountLDtoSD(IStargatePool pool, uint256 _amount) private view returns (uint256) {
        return _amount.div(pool.convertRate());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IUniswapV2Factory.sol";

library UniswapV2Helper {
    using SafeMath for uint256;

    function quote(
        IUniswapV2Factory factory,
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) internal view returns (uint256 amountOut) {
        try factory.getPair(tokenIn, tokenOut) returns (IUniswapV2Pair pair) {
            if (address(pair) != address(0)) {
                try pair.getReserves() returns (uint112 reserveIn, uint112 reserveOut, uint32) {
                    if (tokenIn > tokenOut) (reserveIn, reserveOut) = (reserveOut, reserveIn);
                    amountOut = amountIn.mul(reserveOut).div(amountIn.add(reserveIn));
                } catch {}
            }
        } catch {}
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/StargateHelper.sol";
import "./libraries/UniswapV2Helper.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IStargateFactory.sol";

contract Router {
    using StargateHelper for IStargatePool;
    using UniswapV2Helper for IUniswapV2Factory;

    struct Route {
        uint256 poolId;
        IUniswapV2Factory factory;
        address connector;
        uint256 amountOut;
    }

    mapping(uint256 => bool) internal pools;

    /// Quotes routes using Uniswap v2 factories, connector tokens and Stargate pools
    /// @notice should only by used off-chain
    /// @param amountIn tokenIn amount
    /// @param tokenIn input token
    /// @param dstChainId destination chain id
    /// @param factory Stargate factory
    /// @param factories Uniswap factories
    /// @param connectors connecor tokens to route through
    /// @return routes max route for each dstPoolId
    /// @return amounts max connector amount
    function quote(
        uint256 amountIn,
        address tokenIn,
        uint16 dstChainId,
        IStargateFactory factory,
        IUniswapV2Factory[] calldata factories,
        address[] calldata connectors
    ) external returns (Route[] memory routes, uint256[] memory amounts) {
        amounts = new uint256[](connectors.length);

        uint256 routesLength;
        uint256 allPoolsLength = factory.allPoolsLength();

        for (uint i; i < allPoolsLength; i++) {
            IStargatePool pool = factory.allPools(i);
            uint256 chainPathsLength = pool.getChainPathsLength();
            for (uint j; j < chainPathsLength; j++) {
                IStargatePool.ChainPath memory cp = pool.chainPaths(j);
                if (cp.ready && cp.dstChainId == dstChainId) {
                    if (!pools[cp.dstPoolId]) {
                        pools[cp.dstPoolId] = true;
                        routesLength++;
                    }
                }
            }
        }

        routes = new Route[](routesLength);

        for (uint i; i < allPoolsLength; i++) {
            IStargatePool pool = factory.allPools(i);
            address token = pool.token();

            uint256 amountOut;
            address maxConnector;
            IUniswapV2Factory maxFactory;

            for (uint j; j < factories.length; j++) {
                IUniswapV2Factory uniFactory = factories[j];
                uint256 amount = uniFactory.quote(amountIn, tokenIn, token);
                if (amount > amountOut) {
                    amountOut = amount;
                    maxFactory = uniFactory;
                    delete maxConnector;
                }

                for (uint k; k < connectors.length; k++) {
                    address connector = connectors[k];
                    amount = uniFactory.quote(amountIn, tokenIn, connector);
                    if (amount > amounts[k]) {
                        amounts[k] = amount;
                    }
                    amount = uniFactory.quote(amount, connector, token);
                    if (amount > amountOut) {
                        amountOut = amount;
                        maxFactory = uniFactory;
                        maxConnector = connector;
                    }
                }
            }

            uint256 chainPathsLength = pool.getChainPathsLength();

            for (uint k; k < chainPathsLength; k++) {
                IStargatePool.ChainPath memory cp = pool.chainPaths(k);
                if (cp.ready && cp.dstChainId == dstChainId) {
                    uint256 amount = amountOut;
                    if (cp.balance < amountOut) {
                        amount = cp.balance;
                    }
                    for (uint w; w < routesLength; w++) {
                        Route memory route = routes[w];
                        if (route.poolId == 0 || amount > route.amountOut) {
                            route.poolId = cp.dstPoolId;
                            route.factory = maxFactory;
                            route.connector = maxConnector;
                            route.amountOut = amount;
                        }
                    }
                }
            }
        }
    }
}