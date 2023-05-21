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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IAccount, UserOperationVariant } from "./interfaces/IAccount.sol";
import { IUniswapV3Router } from "./dependencies/IUniswapV3Router.sol";

contract Account is IAccount {
    address public immutable wETH;

    constructor(address _wETH) {
        wETH = _wETH;
    }

    function validateUserOp(UserOperationVariant calldata userOp) external {}

    function verify(bytes calldata proof) external view returns (bool) {
        // TODO: Not implemented.
        return true;
    }

    function exactInputSingle(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address tokenOut,
        uint24 poolFee
    ) external payable returns (uint256 amountOut) {
        if (tokenIn != wETH) {
            IERC20(tokenIn).approve(router, amountIn);
        }

        IUniswapV3Router.ExactInputSingleParams memory params = IUniswapV3Router
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });

        if (tokenIn != wETH) {
            amountOut = IUniswapV3Router(router).exactInputSingle(params);
        } else {
            amountOut = IUniswapV3Router(router).exactInputSingle{
                value: amountIn
            }(params);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import { IAccountFactory } from "./interfaces/IAccountFactory.sol";
import { Account } from "./Account.sol";

contract AccountFactory is IAccountFactory {
    address public immutable wETH;

    constructor(address _wETH) {
        wETH = _wETH;
    }

    function createAccount() external returns (address account) {
        account = address(new Account(wETH));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IUniswapV3Router {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import { UserOperationVariant } from "./UserOperationVariant.sol";

interface IAccount {
    function validateUserOp(UserOperationVariant calldata userOp) external;

    function verify(bytes calldata proof) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

interface IAccountFactory {
    function createAccount() external returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

struct UserOperationVariant {
    address sender;
    bytes callData;
    bytes proof;
    uint256 callGasLimit;
}