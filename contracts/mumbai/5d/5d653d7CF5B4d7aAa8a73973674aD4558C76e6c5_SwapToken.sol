// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface DAI {
    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface UniswapV2Factory {
    function getPair(address token0, address token1) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface UniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface UniswapV2Router {
    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) external view returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        //amount of tokens we are sending in
        uint256 amountIn,
        //the minimum amount of tokens we want out of the trade
        uint256 amountOutMin,
        //list of token addresses we are going to trade in.  this is necessary to calculate amounts
        address[] calldata path,
        //this is the address we are going to send the output tokens to
        address to,
        //the last time that the trade is valid for
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface USDC {
    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface USDT {
    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interface/IUSDC.sol";
import "./Interface/IUSDT.sol";
import "./Interface/IDAI.sol";
import "./Interface/IUniswapV2Factory.sol";
import "./Interface/IUniswapV2Pair.sol";
import "./Interface/IUniswapV2Router.sol";

contract SwapToken is ReentrancyGuard, Ownable {
    USDC public usdc;
    USDT public usdt;
    DAI public dai;
    UniswapV2Router public uniswapV2Router;
    UniswapV2Pair public uniswapV2Pair;
    UniswapV2Factory public uniswapV2Factory;
    uint256 public ratio = 1000;

    mapping(address => uint256[3]) userBalance;

    //address of the uniswap v2 router
    address private constant UNISWAP_V2_ROUTER =
        0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    //address of WMATIC token
    address private constant WMATIC =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    constructor(
        address usdcContractAddress,
        address usdtContractAddress,
        address daiContractAddress
    ) {
        usdc = USDC(usdcContractAddress);
        usdt = USDT(usdtContractAddress);
        dai = DAI(daiContractAddress);
        uniswapV2Router = UniswapV2Router(UNISWAP_V2_ROUTER);
    }

    function depositFund(uint256 _amount, uint8 _coinIdx) external {
        if (_coinIdx == 0) {
            require(
                usdc.balanceOf(msg.sender) >= _amount,
                "Not enough balance in user wallet"
            );

            usdc.transferFrom(msg.sender, address(this), _amount);
        } else if (_coinIdx == 1) {
            require(
                usdt.balanceOf(msg.sender) >= _amount,
                "Not enough balance in user wallet"
            );

            usdt.transferFrom(msg.sender, address(this), _amount);
        } else {
            require(
                dai.balanceOf(msg.sender) >= _amount,
                "Not enough balance in user wallet"
            );

            dai.transferFrom(msg.sender, address(this), _amount);
        }

        userBalance[msg.sender][_coinIdx] += _amount;
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to,
        uint8 _coinIdx
    ) external {
        if (_coinIdx == 0) {
            require(
                usdc.balanceOf(msg.sender) >= _amountIn,
                "Not enough balance in user wallet"
            );
            usdc.transferFrom(
                msg.sender,
                address(this),
                (_amountIn * ratio) / 1000
            );
            usdc.approve(UNISWAP_V2_ROUTER, _amountIn);
        } else if (_coinIdx == 1) {
            require(
                usdt.balanceOf(msg.sender) >= _amountIn,
                "Not enough balance in user wallet"
            );
            usdt.transferFrom(
                msg.sender,
                address(this),
                (_amountIn * ratio) / 1000
            );
            usdt.approve(UNISWAP_V2_ROUTER, _amountIn);
        } else {
            require(
                dai.balanceOf(msg.sender) >= _amountIn,
                "Not enough balance in user wallet"
            );
            dai.transferFrom(
                msg.sender,
                address(this),
                (_amountIn * ratio) / 1000
            );
            dai.approve(UNISWAP_V2_ROUTER, _amountIn);
        }

        address[] memory path;
        if (_tokenIn == WMATIC || _tokenOut == WMATIC) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WMATIC;
            path[2] = _tokenOut;
        }

        uniswapV2Router.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            _to,
            block.timestamp
        );
    }

    function getAmountOutMin(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256) {
        address[] memory path;
        if (_tokenIn == WMATIC || _tokenOut == WMATIC) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WMATIC;
            path[2] = _tokenOut;
        }

        uint256[] memory amountOutMins = uniswapV2Router.getAmountsOut(
            _amountIn,
            path
        );
        return amountOutMins[path.length - 1];
    }

    function changeRatio(uint256 _newRatio) external onlyOwner {
        ratio = _newRatio;
    }

    function calculateAPY() external view onlyOwner returns (uint256) {
        return (1 + ratio / 365000) ** 365 - 1;
    }

    function withdrawFund(
        uint256 _amount,
        uint8 _coinIdx
    ) external nonReentrant {
        require(
            userBalance[msg.sender][_coinIdx] >= _amount,
            "You have not enough balance to withdraw"
        );

        if (_coinIdx == 0) {
            require(
                usdc.balanceOf(address(this)) >= _amount,
                "Not enough balance in the pool"
            );

            usdc.approve(msg.sender, _amount);
            usdc.transfer(msg.sender, _amount);
        } else if (_coinIdx == 1) {
            require(
                usdt.balanceOf(address(this)) >= _amount,
                "Not enough balance in the pool"
            );

            usdt.approve(msg.sender, _amount);
            usdt.transfer(msg.sender, _amount);
        } else {
            require(
                dai.balanceOf(address(this)) >= _amount,
                "Not enough balance in the pool"
            );

            dai.approve(msg.sender, _amount);
            dai.transfer(msg.sender, _amount);
        }

        userBalance[msg.sender][_coinIdx] -= _amount;
    }
}