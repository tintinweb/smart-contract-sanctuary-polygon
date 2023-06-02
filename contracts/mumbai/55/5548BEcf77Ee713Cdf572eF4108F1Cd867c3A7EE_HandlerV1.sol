// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address owner) {
        _transferOwnership(owner);
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
    function getOwner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(getOwner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: None
pragma solidity ^0.8.18;
import {IERC20} from "../interfaces/IERC20.sol";
import {IOps} from "../interfaces/IOps.sol";
import "../interfaces/IHandler.sol";
import "../Core/Ownable.sol";
import {LocalRouter} from "./LocalRouter.sol";

contract HandlerV1 is IHandler,Ownable,LocalRouter {
    IOps immutable gelatoOps;
    address immutable WRAPPED_NATIVE;
    address public NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _ops, address factory, address __owner, address _WRAPPED_NATIVE) Ownable(__owner) LocalRouter(factory,_WRAPPED_NATIVE) {
        gelatoOps = IOps(_ops);
        WRAPPED_NATIVE=_WRAPPED_NATIVE;
    }

    // dont send tokens directly
    receive() external payable {
        require(
            msg.sender != tx.origin,
            "dont send native tokens directly"
        );
    }

    // Need to be invoked in case when Gelato changes their native token address , very unlikely though
    function updateNativeTokenAddress(address newNativeTokenAddress) external onlyOwner {
        NATIVE_TOKEN = newNativeTokenAddress;
    }

    // Transfer native token
    function _transfer(uint256 _fee, address _feeToken, address payable to) internal {
        if (_feeToken == NATIVE_TOKEN) {
            (bool success, ) = to.call{value: _fee}("");
            require(success, "_transfer: NATIVE_TOKEN transfer failed");
        } else {
            IERC20(_feeToken).transfer(address(to), _fee);
        }
    }

    // Get transaction fee and feeToken from GelatoOps for the transaction execution
    function _getFeeDetails()
    internal
    view
    returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = gelatoOps.getFeeDetails();
    }

    // Checker for limit order
    function canExecuteLimitOrder(
        uint256 amountFeeToken,
        uint256 amountTokenA,
        bytes calldata swapData
    ) external view returns (bool) {
        // Decode data
        (
        uint96 deadline,
        uint256 minReturn,
        address pathNativeSwapTokenA,
        address pathNativeSwapTokenB,
        address pathTokenSwapTokenA,
        address pathTokenSwapTokenB,
        uint32 nativeSwapFee,
        uint32 tokenSwapFee
        ) = abi.decode(
            swapData,
                (uint96, uint256, address,address,address,address, uint32,uint32)
        );

        address[] memory pathNativeSwap = new address[](2);
        pathNativeSwap[0] = pathNativeSwapTokenA;
        pathNativeSwap[1] = pathNativeSwapTokenB;
        address[] memory pathTokenSwap =new address[](2);
        pathTokenSwap[0] = pathTokenSwapTokenA;
        pathTokenSwap[1] = pathTokenSwapTokenB;
        uint32[] memory feeNativeSwap =new uint32[](1);
        feeNativeSwap[0] = nativeSwapFee;
        uint32[] memory feeTokenSwap = new uint32[](1);
        feeTokenSwap[0] = tokenSwapFee;

        // Check order validity
        require(block.timestamp < deadline,"deadline passed");

        // Check if sufficient tokenB will be returned
        require(
            (
            getAmountsOut(
                amountTokenA,
                pathTokenSwap,
                feeTokenSwap
            )
            )[pathTokenSwap.length - 1] >= minReturn,
            "insufficient token B returned"
        );

        // Check if input FeeToken amount is sufficient to cover fees
        (uint256 FEES, ) = _getFeeDetails();

        require(
            (
            getAmountsOut(
                amountFeeToken,
                pathNativeSwap,
                feeNativeSwap
            )
            )[pathNativeSwap.length - 1] >= FEES,
            "insufficient NATIVE_TOKEN returned"
        );

        return true;
    }

    // Executor for limit order
    function executeLimitOrder(
        uint256 amountFeeToken,
        uint256 amountTokenA,
        address _owner,
        bytes calldata swapData
    ) external returns(uint256,uint256) {
        // Decode data
        (
        uint96 deadline,
        uint256 minReturn,
        address pathNativeSwapTokenA,
        address pathNativeSwapTokenB,
        address pathTokenSwapTokenA,
        address pathTokenSwapTokenB,
        uint32 nativeSwapFee,
        uint32 tokenSwapFee
        ) = abi.decode(
            swapData,
            (uint96, uint256, address,address,address,address, uint32,uint32)
        );

        address[] memory pathNativeSwap = new address[](2);
        pathNativeSwap[0] = pathNativeSwapTokenA;
        pathNativeSwap[1] = pathNativeSwapTokenB;
        address[] memory pathTokenSwap =new address[](2);
        pathTokenSwap[0] = pathTokenSwapTokenA;
        pathTokenSwap[1] = pathTokenSwapTokenB;
        uint32[] memory feeNativeSwap =new uint32[](1);
        feeNativeSwap[0] = nativeSwapFee;
        uint32[] memory feeTokenSwap = new uint32[](1);
        feeTokenSwap[0] = tokenSwapFee;

        // calculate feeToken amount from native fee
        uint256[] memory feeTokenAmountFromNativeFee;

        // get tx fee
        (uint256 FEES, address feeToken) = _getFeeDetails();

        // transfer the remaining welle back to owner
        _transfer(amountFeeToken - feeTokenAmountFromNativeFee[0],pathNativeSwap[0],payable(_owner));

        // call swap tokenA to tokenB
        uint256 bought = swapExactTokensForTokens(
            amountTokenA,
            minReturn,
            pathTokenSwap,
            feeTokenSwap,
            _owner,
            deadline
        );

        require(
            bought >= minReturn,
            "Insufficient return tokenB"
        );

        if (pathNativeSwap[0] == NATIVE_TOKEN)
        {
            // send gelato fees directly
            (bool success,) = gelatoOps.gelato().call{value:FEES}("");
            require(success, "failed sending native fees to gelato");
            return (bought,feeTokenAmountFromNativeFee[0]);
        }

        // swap and receive erc20 gelato tokens
        feeTokenAmountFromNativeFee = getAmountsIn(
            FEES,
            pathNativeSwap,
            feeNativeSwap
        );

        require(
            amountFeeToken >= feeTokenAmountFromNativeFee[0],
            "insufficient feeToken amount"
        );

        require(
            IERC20(pathNativeSwap[0]).balanceOf(address(this)) >=
            amountFeeToken,
            "insufficient balance of feeToken in handler"
        );

        // call swap tokenA to native token
        if (feeToken == NATIVE_TOKEN){
            require(pathNativeSwap[pathNativeSwap.length-1] == WRAPPED_NATIVE, "wrong fee native path");
            swapTokensForExactNative(
                FEES,
                feeTokenAmountFromNativeFee[0],
                pathNativeSwap,
                feeNativeSwap,
                address(this),
                deadline
            );

            // send gelato fees
            (bool success, ) = gelatoOps.gelato().call{value: FEES}("");
            require(success, "_transfer: NATIVE_TOKEN transfer failed");
        } else {
            require(pathNativeSwap[pathNativeSwap.length-1] == feeToken, "wrong erc20 fee native path");
            swapTokensForExactTokens(
                FEES,
                feeTokenAmountFromNativeFee[0],
                pathNativeSwap,
                feeNativeSwap,
                address(this),
                deadline
            );

            //send gelato fees
            IERC20(pathNativeSwap[pathNativeSwap.length-1]).transfer(gelatoOps.gelato(), FEES);
        }

        return (bought,feeTokenAmountFromNativeFee[0]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20PairToken.sol";

interface IERC20Pair is IERC20PairToken {
    function swap(
        uint256 amountOfAsset1,
        uint256 amountOfAsset2,
        address to,
        bytes calldata data
    ) external;

    function getReserves()
    external
    view
    returns (
        uint112 _reserve0,
        uint112 _reserve1,
        uint32 _blockTimestampLast
    );

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
    external
    returns (uint256 amount1, uint256 amount2);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20PairToken {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoolFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint32 feeNumerator
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function owner() external view returns (address);

    function ownerSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB,
        uint32 fee
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        uint32 feeNumerator
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRouter {
    function factory() external view returns (address);

    function WNative() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint32 fee,
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

    function addLiquidityNative(
        address token,
        uint32 fee,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountNativeMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountNative, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint32 fee,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityNative(
        address token,
        uint32 fee,
        uint liquidity,
        uint amountTokenMin,
        uint amountNativeMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountNative);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactNativeForTokens(uint amountOutMin, address[] calldata path, uint32[] calldata feePath, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactNative(uint amountOut, uint amountInMax, address[] calldata path, uint32[] calldata feePath, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function quoteByTokens(
        uint256 amountA,
        address tokenA,
        address tokenB,
        uint32 fee
    ) external view returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] memory path, uint32[] calldata feePath)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path, uint32[] calldata feePath)
    external
    view
    returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IERC20Pair.sol";
import "./SafeMath.sol";

import {ERC20Pair} from "./ERC20Pair.sol";

contract DEXLibrary {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "DEXLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "DEXLibrary: ZERO_ADDRESS");
    }

    /* function hashCode() public pure returns (bytes32){
         bytes memory bytecode = type(ERC20Pair).creationCode;
         return keccak256(abi.encodePacked(bytecode));
     }*/
    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        uint32 poolFee
    ) public pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encodePacked(token0, token1, poolFee)
                            ),
                            keccak256(
                                hex"9a8739aa071fea495e48db3c3be975ac38f4fd660612693118122f8b061c7fa2"
                            )
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB,
        uint32 poolFee
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IERC20Pair(
            pairFor(factory, tokenA, tokenB, poolFee)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "DEXLibrary: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "DEXLibrary: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "DEXLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "DEXLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(10 ** 5 - fee);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10 ** 5).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "DEXLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "DEXLibrary: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(10 ** 5);
        uint256 denominator = reserveOut.sub(amountOut).mul(10 ** 5 - fee);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path,
        uint32[] memory feePath
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "DEXLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1],
                feePath[i]
            );
            amounts[i + 1] = getAmountOut(
                amounts[i],
                reserveIn,
                reserveOut,
                feePath[i]
            );
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path,
        uint32[] memory feePath
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "DEXLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i],
                feePath[i - 1]
            );
            amounts[i - 1] = getAmountIn(
                amounts[i],
                reserveIn,
                reserveOut,
                feePath[i - 1]
            );
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.8.0;

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

// File: contracts/core/interfaces/IERC20PairToken.sol



interface IERC20PairToken {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// File: contracts/core/interfaces/IERC20Pair.sol



interface IERC20Pair is IERC20PairToken {
    function swap(
        uint256 amountOfAsset1,
        uint256 amountOfAsset2,
        address to,
        bytes calldata data
    ) external;

    function getReserves()
    external
    view
    returns (
        uint112 _reserve0,
        uint112 _reserve1,
        uint32 _blockTimestampLast
    );

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
    external
    returns (uint256 amount1, uint256 amount2);
}

// File: contracts/core/library/Math.sol



library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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
    }
}

// File: contracts/core/library/SafeMath.sol



library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

// File: contracts/core/library/UQ112x112.sol



library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// File: contracts/core/ERC20PairToken.sol



contract ERC20PairToken is IERC20PairToken {
    string public constant name = "ERC20 Pair Token";
    string public constant symbol = "LPTKN";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
    0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + (value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - (value);
        totalSupply = totalSupply - (value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from] - (value);
        balanceOf[to] = balanceOf[to] + (value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender] - (value);
        }
        _transfer(from, to, value);
        return true;
    }

}

// File: contracts/core/interfaces/IPoolFactory.sol



interface IPoolFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint32 feeNumerator
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function owner() external view returns (address);

    function ownerSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB,
        uint32 fee
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        uint32 feeNumerator
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// File: contracts/core/interfaces/IPairCallee.sol



interface IPairCallee {
    function pairCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}


// EVM slot size = 256 bits
contract ERC20Pair is IERC20Pair, ERC20PairToken {
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    address public factory;

    address public token0; //address of the first token in the pair
    address public token1; //address of the second token in the pair

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint32 public feeNumerator;
    uint32 public protocolFee;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event
    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;
    uint256 private unlocked = 1;

    constructor() {
        factory = msg.sender;
    }

    modifier lock() {
        require(unlocked == 1, "ERC20Pair: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

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

    function getReserves()
    public
    view
    override
    returns (
        uint112 _reserve0,
        uint112 _reserve1,
        uint32 _blockTimestampLast
    )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ERC20Pair: TRANSFER_FAILED"
        );
    }

    // called once by the factory at time of deployment
    function initialize(
        address _token0,
        address _token1,
        uint32 _feeNumerator,
        uint32 _protocolFee
    ) external {
        require(msg.sender == factory, "ERC20Pair: FORBIDDEN");
        // sufficient check
        token0 = _token0;
        token1 = _token1;
        feeNumerator = _feeNumerator;
        protocolFee = _protocolFee;
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1)
    private
    returns (bool feeOn)
    {
        address feeTo = IPoolFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast;
        // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0).mul(_reserve1));
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint256 denominator =  rootK * ((feeNumerator / protocolFee) - 1) + rootKLast;
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external override lock {
        require(
            amount0Out > 0 || amount1Out > 0,
            "ERC20Pair: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint112 _reserve0, uint112 _reserve1,) = this.getReserves();
        // gas savings
        require(
            amount0Out < _reserve0 && amount1Out < _reserve1,
            "ERC20Pair: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "ERC20Pair: INVALID_TO");
            // optimistically transfer tokens
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
            // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);
            if (data.length > 0)
                IPairCallee(to).pairCall(
                    msg.sender,
                    amount0Out,
                    amount1Out,
                    data
                );
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out
        ? balance0 - (_reserve0 - amount0Out)
        : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out
        ? balance1 - (_reserve1 - amount1Out)
        : 0;
        require(
            amount0In > 0 || amount1In > 0,
            "ERC20Pair: INSUFFICIENT_INPUT_AMOUNT"
        );
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0.mul(10 ** 5).sub(
                amount0In.mul(feeNumerator)
            );
            uint256 balance1Adjusted = balance1.mul(10 ** 5).sub(
                amount1In.mul(feeNumerator)
            );
            require(
                balance0Adjusted.mul(balance1Adjusted) >=
                uint256(_reserve0).mul(_reserve1).mul(10 ** 10),
                "ERC20Pair: K"
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function mint(address to)
    external
    override
    lock
    returns (uint256 liquidity)
    {
        (uint112 _reserve0, uint112 _reserve1,) = this.getReserves();
        // gas savings
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply;
        // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY);
            // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(
                amount0.mul(_totalSupply) / _reserve0,
                amount1.mul(_totalSupply) / _reserve1
            );
        }
        require(liquidity > 0, "ERC20Pair: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).mul(reserve1);
        // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    function burn(address to)
    external
    override
    lock
    returns (uint256 amount0, uint256 amount1)
    {
        (uint112 _reserve0, uint112 _reserve1,) = this.getReserves();
        // gas savings
        address _token0 = token0;
        // gas savings
        address _token1 = token1;
        // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply;
        // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply;
        // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply;
        // using balances ensures pro-rata distribution
        require(
            amount0 > 0 && amount1 > 0,
            "ERC20Pair: INSUFFICIENT_LIQUIDITY_BURNED"
        );
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).mul(reserve1);
        // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(
            balance0 <= type(uint112).max && balance1 <= type(uint112).max,
            "ERC20Pair: OVERFLOW"
        );
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast +=
            uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) *
            timeElapsed;
            price1CumulativeLast +=
            uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) *
            timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0;
        // gas savings
        address _token1 = token1;
        // gas savings
        _safeTransfer(
            _token0,
            to,
            IERC20(_token0).balanceOf(address(this)).sub(reserve0)
        );
        _safeTransfer(
            _token1,
            to,
            IERC20(_token1).balanceOf(address(this)).sub(reserve1)
        );
    }

    // force reserves to match balances
    function sync() external lock {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.18;
import {DEXLibrary} from "./libs/DEXLibraryContract.sol";
import "./interfaces/IERC20Pair.sol";
import "./interfaces/IWETH.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import "./interfaces/IPoolFactory.sol";
import {IERC20} from "../interfaces/IERC20.sol";

contract LocalRouter is DEXLibrary{

    address public immutable factory;
    address public immutable WNative;

    constructor(address _factory, address _WNative) {
        factory = _factory;
        WNative = _WNative;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "LocalRouter: EXPIRED");
        _;
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(
        address[] memory path,
        uint32[] memory feePath,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output, uint32 fees) = (
            path[i],
            path[i + 1],
            feePath[i]
            );
            (address token0, ) = DEXLibrary.sortTokens(input, output);
            IERC20Pair pair = IERC20Pair(
                DEXLibrary.pairFor(factory, input, output, fees)
            );
            uint256 amountInput;
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) = input == token0
                ? (reserve0, reserve1)
                : (reserve1, reserve0);
                amountInput =
                IERC20(input).balanceOf(address(pair)) -
                reserveInput;
                amountOutput = DEXLibrary.getAmountOut(
                    amountInput,
                    reserveInput,
                    reserveOutput,
                    fees
                );
            }
            address to = i < path.length - 2  ? DEXLibrary.pairFor(factory, output, path[i + 2], fees)  : _to;

            {
                (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));
                pair.swap(amount0Out, amount1Out, to, new bytes(0));
            }
        }
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        uint32[] memory feePath,
        address to,
        uint256 deadline
    )
    internal
    ensure(deadline)
    returns (uint256[] memory amounts)
    {
        amounts = DEXLibrary.getAmountsIn(factory, amountOut, path, feePath);
        require(amounts[0] <= amountInMax, "Router: EXCESSIVE_INPUT_AMOUNT");
        safeTransferFrom(
            path[0],
            msg.sender,
            DEXLibrary.pairFor(factory, path[0], path[1], feePath[0]),
            amounts[0]
        );
        _swap(amounts, path, feePath, to);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint32[] memory feePath,
        address to,
        uint256 deadline
    )
    internal
    virtual
    ensure(deadline)
    returns(uint256 tokenBReceived)
    {
        safeTransferFrom(
            path[0],
            msg.sender,
            DEXLibrary.pairFor(factory, path[0], path[1], feePath[0]),
            amountIn
        );
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to); //?
        _swapSupportingFeeOnTransferTokens(path, feePath, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - (balanceBefore) >=
            amountOutMin,
            "RouterV2: INSUFFICIENT_OUTPUT_AMOUNT"
        );

        return IERC20(path[path.length - 1]).balanceOf(to) - (balanceBefore);
    }

    function swapTokensForExactNative(
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        uint32[] memory feePath,
        address to,
        uint256 deadline
    )
    internal
    virtual
    ensure(deadline)
    returns (uint256[] memory amounts)
    {
        require(path[path.length - 1] == WNative, "Router: INVALID_PATH");
        amounts = DEXLibrary.getAmountsIn(factory, amountOut, path, feePath);
        require(amounts[0] <= amountInMax, "Router: EXCESSIVE_INPUT_AMOUNT");
        safeTransferFrom(
            path[0],
            msg.sender,
            DEXLibrary.pairFor(factory, path[0], path[1], feePath[0]),
            amounts[0]
        );
        _swap(amounts, path, feePath, address(this));
        IWETH(WNative).withdraw(amounts[amounts.length - 1]);
        safeTransferNative(to, amounts[amounts.length - 1]);
    }

    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        uint32[] memory feePath,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = DEXLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
            ? (uint256(0), amountOut)
            : (amountOut, uint256(0));
            address to = i < path.length - 2
            ? DEXLibrary.pairFor(factory, output, path[i + 2], feePath[i])
            : _to;
            IERC20Pair(DEXLibrary.pairFor(factory, input, output, feePath[i]))
            .swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Router::transferFrom: transferFrom failed"
        );
    }

    function safeTransferNative(address to, uint256 value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, "Router::safeTransferNative: Native transfer failed");
    }

    function getAmountsOut(
        uint256 amountIn,
        address[] memory path,
        uint32[] memory feePath
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "INVALID_PATH");
        for (uint256 i; i < path.length - 1; i++) {
            address poolAddress = IPoolFactory(factory).getPair(
                path[i],
                path[i + 1],
                feePath[i]
            );
            if (poolAddress == address(0)) {
                amounts = new uint256[](2);
                amounts[0] = 0;
                amounts[1] = 0;
                return amounts;
            }
        }
        return DEXLibrary.getAmountsOut(factory, amountIn, path, feePath);
    }

    function getAmountsIn(
        uint256 amountOut,
        address[] memory path,
        uint32[] memory feePath
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "INVALID_PATH");
        for (uint256 i; i < path.length - 1; i++) {
            address poolAddress = IPoolFactory(factory).getPair(
                path[i],
                path[i + 1],
                feePath[i]
            );
            if (poolAddress == address(0)) {
                amounts = new uint256[](2);
                amounts[0] = 0;
                amounts[1] = 0;
                return amounts;
            }
        }
        return DEXLibrary.getAmountsIn(factory, amountOut, path, feePath);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct VaultData{
    uint256 tokenBalance;
    uint256 feeTokenBalance;
    bytes32 taskId;
}

interface IHandler {

    /// @notice receive ETH
    receive() external payable;

    /**
     * @notice Executes an order
     * @param _inputAmountFeeToken - uint256 of the input FeeToken amount (order amount)
     * @param _inputAmountTokenA - uint256 of the input token amount (order amount)
     * @param _owner - Address of the order's owner
     * @param _data - Bytes of the order's data
     * @return bought - amount of output token bought
     */
    function executeLimitOrder(
        uint256 _inputAmountFeeToken,
        uint256 _inputAmountTokenA,
        address _owner,
        bytes calldata _data
    ) external returns (uint256,uint256);

    /**
     * @notice Check whether an order can be executed or not
     * @param amountFeeToken - uint256 of the input FeeToken token amount (order amount)
     * @param amountTokenA - uint256 of the input token token amount (order amount)
     * @param swapData - Bytes of the order's data
     * @return bool - whether the order can be executed or not
     */
    function canExecuteLimitOrder(
        uint256 amountFeeToken,
        uint256 amountTokenA,
        bytes calldata swapData
    ) external view returns (bool);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.18;
    enum Module {
        RESOLVER,
        TIME,
        PROXY,
        SINGLE_EXEC
    }

    struct ModuleData {
        Module[] modules;
        bytes[] args;
    }

interface IOps {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}