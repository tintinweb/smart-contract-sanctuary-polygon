// SPDX-License-Identifier: GPL-3.0
// NOT audited code, use at your own risk

pragma solidity 0.8.19;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IAavegotchi {
    function batchClaimGotchiLending(uint32[] calldata _tokenIds) external;
}

contract Dumper is Ownable {
    address constant QUICKSWAP_ROUTER_ADDRESS =
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    uint256 constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    address ghst = 0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7;

    address fud = 0x403E967b044d4Be25170310157cB1A4Bf10bdD0f;
    address fomo = 0x44A6e0BE76e1D9620A7F76588e4509fE4fa8E8C8;
    address alpha = 0x6a3E7C3c6EF65Ee26975b12293cA1AAD7e1dAeD2;
    address kek = 0x42E5E06EF5b90Fe15F853F59299Fc96259209c5C;

    address usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    address diamond = 0x86935F11C86623deC8a25696E1C19a8659CbF95d;

    constructor() {
        IERC20(ghst).approve(QUICKSWAP_ROUTER_ADDRESS, MAX_INT);
        IERC20(fud).approve(QUICKSWAP_ROUTER_ADDRESS, MAX_INT);
        IERC20(fomo).approve(QUICKSWAP_ROUTER_ADDRESS, MAX_INT);
        IERC20(alpha).approve(QUICKSWAP_ROUTER_ADDRESS, MAX_INT);
        IERC20(kek).approve(QUICKSWAP_ROUTER_ADDRESS, MAX_INT);
    }

    function batchClaim(uint32[] calldata _tokenIds) external {
        IAavegotchi(diamond).batchClaimGotchiLending(_tokenIds);
    }

    function simulateUsdc(
        uint256 _slippage,
        address _user
    ) external view returns (uint256) {
        // Get All Alch Bal
        uint256 fudBal = IERC20(fud).balanceOf(_user);
        uint256 fomoBal = IERC20(fomo).balanceOf(_user);
        uint256 alphaBal = IERC20(alpha).balanceOf(_user);
        uint256 kekBal = IERC20(kek).balanceOf(_user);

        // Swap Alchs for GHST
        uint256 ghstReceived = 0;
        if (fudBal > 0)
            ghstReceived += _getAmountOutMin(fudBal, fud, ghst, _slippage);
        if (fomoBal > 0)
            ghstReceived += _getAmountOutMin(fomoBal, fomo, ghst, _slippage);
        if (alphaBal > 0)
            ghstReceived += _getAmountOutMin(alphaBal, alpha, ghst, _slippage);
        if (kekBal > 0)
            ghstReceived += _getAmountOutMin(kekBal, kek, ghst, _slippage);

        uint256 usdcReceived = _getAmountOutMin(
            ghstReceived,
            ghst,
            usdc,
            _slippage
        );

        return usdcReceived;
    }

    // WARNING: Slippage in BPS, 100 = 1 %
    function swapAllAlchsToGht(uint256 _slippage) external {
        require(_slippage >= 50, "Dumper: Slippage too low");

        // Get All Alch Bal
        uint256 fudBal = IERC20(fud).balanceOf(msg.sender);
        uint256 fomoBal = IERC20(fomo).balanceOf(msg.sender);
        uint256 alphaBal = IERC20(alpha).balanceOf(msg.sender);
        uint256 kekBal = IERC20(kek).balanceOf(msg.sender);

        // Transfer to this contract
        IERC20(fud).transferFrom(msg.sender, address(this), fudBal);
        IERC20(fomo).transferFrom(msg.sender, address(this), fomoBal);
        IERC20(alpha).transferFrom(msg.sender, address(this), alphaBal);
        IERC20(kek).transferFrom(msg.sender, address(this), kekBal);

        // Swap Alchs for GHST
        if (fudBal > 0) _swap(fud, ghst, fudBal, msg.sender, _slippage);
        if (fomoBal > 0) _swap(fomo, ghst, fomoBal, msg.sender, _slippage);
        if (alphaBal > 0) _swap(alpha, ghst, alphaBal, msg.sender, _slippage);
        if (kekBal > 0) _swap(kek, ghst, kekBal, msg.sender, _slippage);

        require(
            IERC20(fud).balanceOf(address(this)) == 0,
            "Dumper: Fud in Contract"
        );
        require(
            IERC20(fomo).balanceOf(address(this)) == 0,
            "Dumper: fomo in Contract"
        );
        require(
            IERC20(alpha).balanceOf(address(this)) == 0,
            "Dumper: alpha in Contract"
        );
        require(
            IERC20(kek).balanceOf(address(this)) == 0,
            "Dumper: kek in Contract"
        );
    }

    function swapAllAlchsToUsdc(uint256 _slippage) external {
        require(_slippage >= 50, "Dumper: Slippage too low");

        // Get All Alch Bal
        uint256 fudBal = IERC20(fud).balanceOf(msg.sender);
        uint256 fomoBal = IERC20(fomo).balanceOf(msg.sender);
        uint256 alphaBal = IERC20(alpha).balanceOf(msg.sender);
        uint256 kekBal = IERC20(kek).balanceOf(msg.sender);

        // Transfer to this contract
        IERC20(fud).transferFrom(msg.sender, address(this), fudBal);
        IERC20(fomo).transferFrom(msg.sender, address(this), fomoBal);
        IERC20(alpha).transferFrom(msg.sender, address(this), alphaBal);
        IERC20(kek).transferFrom(msg.sender, address(this), kekBal);

        // Swap Alchs for GHST
        if (fudBal > 0) _swap(fud, ghst, fudBal, address(this), _slippage);
        if (fomoBal > 0) _swap(fomo, ghst, fomoBal, address(this), _slippage);
        if (alphaBal > 0)
            _swap(alpha, ghst, alphaBal, address(this), _slippage);
        if (kekBal > 0) _swap(kek, ghst, kekBal, address(this), _slippage);

        // Get new bal of GHST => Swap received into USDC
        uint256 ghstBal = IERC20(ghst).balanceOf(address(this));

        if (ghstBal > 0) _swap(ghst, usdc, ghstBal, msg.sender, _slippage);

        require(
            IERC20(ghst).balanceOf(address(this)) == 0,
            "Dumper: GHST in Contract"
        );
    }

    function _swap(
        address _from,
        address _to,
        uint256 _amount,
        address _user,
        uint256 _slippage
    ) private {
        uint256 deadline = block.timestamp + 15;
        uint256 amountOutMin = _getAmountOutMin(_amount, _from, _to, _slippage);

        address[] memory path = new address[](2);
        path[0] = _from;
        path[1] = _to;
        IUniswapV2Router02(QUICKSWAP_ROUTER_ADDRESS).swapExactTokensForTokens(
            _amount,
            amountOutMin,
            path,
            _user,
            deadline
        );
    }

    function _getAmountOutMin(
        uint256 _amountIn,
        address _from,
        address _to,
        uint256 _slippage
    ) private view returns (uint256) {
        // Get the current price for the path
        address[] memory path = new address[](2);
        path[0] = _from;
        path[1] = _to;

        uint[] memory amounts = IUniswapV2Router02(QUICKSWAP_ROUTER_ADDRESS)
            .getAmountsOut(_amountIn, path);

        // Define your acceptable slippage
        uint acceptableSlippage = (amounts[1] * _slippage) / 10000; // we use 10000 to account for percentage (2 decimal places)

        // Calculate amountOutMin based on the current price and acceptable slippage
        return amounts[1] - acceptableSlippage;
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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