//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "./libraries/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract Arbitrager is IUniswapV2Callee, Ownable {
    event Succeeded(uint256 blockDiff, uint256 profit);
    event Failed(uint256 blockDiff, uint256 errorCode);

    constructor() {}

    using SafeMath for uint256;

    struct CallbackData {
        address[] pairs;
        address[] tokensIn;
        uint256[] amountsIn;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function run(
        address[] memory pairs,
        address[] memory tokensIn,
        uint256[] memory amountsIn,
        uint256 triggeredBlockNumber
    ) external onlyOwner {
        uint256[] memory latestAmountsIn = new uint256[](amountsIn.length);
        latestAmountsIn[0] = amountsIn[0];
        for (uint256 i = 0; i < pairs.length; i++) {
            IUniswapV2Pair pair = IUniswapV2Pair(pairs[i]);
            uint256 reserveIn;
            uint256 reserveOut;
            if (pair.token0() == tokensIn[i]) {
                (reserveIn, reserveOut, ) = pair.getReserves();
            } else if (pair.token1() == tokensIn[i]) {
                (reserveOut, reserveIn, ) = pair.getReserves();
            } else {
                require(false, "token mismatch");
            }
            latestAmountsIn[i + 1] = getAmountOut(
                latestAmountsIn[i],
                reserveIn,
                reserveOut
            );
        }
        // console.log("amountsIn");
        // for (uint256 i = 0; i < amountsIn.length; i++) {
        //     console.log(amountsIn[i], latestAmountsIn[i]);
        // }
        uint256 profit = latestAmountsIn[amountsIn.length - 1] -
            latestAmountsIn[0];
        if (profit <= 0) {
            emit Failed(block.number - triggeredBlockNumber, 9);
            return;
        }
        IUniswapV2Pair loanPair = IUniswapV2Pair(pairs[0]);
        uint256 amount0Out = loanPair.token0() == tokensIn[1]
            ? latestAmountsIn[1]
            : 0;
        uint256 amount1Out = loanPair.token1() == tokensIn[1]
            ? latestAmountsIn[1]
            : 0;
        CallbackData memory callbackData = CallbackData(
            pairs,
            tokensIn,
            latestAmountsIn
        );
        loanPair.swap(
            amount0Out,
            amount1Out,
            address(this),
            bytes(abi.encode(callbackData))
        );

        // send profit
        IERC20(tokensIn[0]).transfer(owner(), profit);
        emit Succeeded(block.number - triggeredBlockNumber, profit);
    }

    function uniswapV2Call(
        address _sender,
        uint256 _amount0Out,
        uint256 _amount1Out,
        bytes calldata data
    ) external override {
        CallbackData memory callbackData = abi.decode(data, (CallbackData));
        address[] memory pairs = callbackData.pairs;
        address[] memory tokensIn = callbackData.tokensIn;
        uint256[] memory amountsIn = callbackData.amountsIn;
        uint256 N = pairs.length;
        require(tokensIn.length == N + 1, "E: tokensIn");
        require(amountsIn.length == N + 1, "E: amountsIn");
        for (uint256 i = 1; i < callbackData.pairs.length; i++) {
            IERC20(tokensIn[i]).transfer(pairs[i], amountsIn[i]);
            IUniswapV2Pair pair = IUniswapV2Pair(pairs[i]);
            uint256 amount0Out = pair.token0() == tokensIn[i + 1]
                ? amountsIn[i + 1]
                : 0;
            uint256 amount1Out = pair.token1() == tokensIn[i + 1]
                ? amountsIn[i + 1]
                : 0;
            pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
        }
        IERC20(tokensIn[0]).transfer(pairs[0], amountsIn[0]);
    }

    function transfer(
        address token,
        uint256 amount,
        address to
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }
}

pragma solidity ^0.8.4;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

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

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
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

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
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