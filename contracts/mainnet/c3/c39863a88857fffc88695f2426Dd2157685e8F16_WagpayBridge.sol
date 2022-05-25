// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IDex {

   function swapExactInputERC20(address _tokenIn, address _tokenOut, uint256 amountIn) external;

   function swapExactOutputERC20(address _tokenIn, address _tokenOut, uint256 amountOut, uint256 amountInMaximum) external;

   function swapExactEthToERC20(address _tokenOut) external payable;

   function swapEthToExactERC20(address _tokenOut,uint256 tokenOutAmount) external payable;

}

interface IBridge {
    function transferNative(uint amount, address receiver, uint256 toChainId, string calldata tag) external payable;
    function transferERC20(uint256 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount,
        string calldata tag ) external;

}

contract WagpayBridge {
	address private constant NATIVE_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    struct DexData {
        address dex;
        uint amountIn;
        uint fees;
        uint chainId;
        address fromToken;
        address toToken;
    }

    struct RouteData {
        address receiver;
        address bridge;
        uint toChain;
        address fromToken;
        uint amount;
        bool dexRequired;
        DexData dex;
    }

    function transfer(RouteData memory _route) external payable {

        IDex idex = IDex(_route.dex.dex);
        IBridge bridge = IBridge(_route.bridge);

        if(_route.dexRequired) {
            
            // Dex
            if(_route.dex.fromToken == NATIVE_TOKEN_ADDRESS) {
                idex.swapExactEthToERC20{value: _route.amount}(_route.dex.toToken);
            } else {
                IERC20(_route.dex.fromToken).approve(_route.dex.dex, _route.amount);
                idex.swapExactInputERC20(_route.dex.fromToken, _route.dex.toToken, _route.dex.amountIn);
            }

            // Bridge
            if(_route.fromToken == NATIVE_TOKEN_ADDRESS) {
                bridge.transferNative{value: _route.dex.amountIn}(_route.dex.amountIn, _route.receiver, _route.toChain, "WagPay");
            } else {
                IERC20(_route.fromToken).approve(_route.bridge, _route.dex.amountIn);
                bridge.transferERC20(_route.toChain, _route.fromToken, _route.receiver, _route.dex.amountIn, "WagPay");
            }
        } else {
            // Bridge
            if(_route.fromToken == NATIVE_TOKEN_ADDRESS) {
                bridge.transferNative{value: _route.amount}(_route.amount, _route.receiver, _route.toChain, "WagPay");
            } else {
                IERC20(_route.fromToken).approve(_route.bridge, _route.amount);
                bridge.transferERC20(_route.toChain, _route.fromToken, _route.receiver, _route.amount, "WagPay");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}