// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../HandlerBase.sol";
import "./ICurveHandler.sol";

contract HCurve is HandlerBase {
    using SafeERC20 for IERC20;

    function getContractName() public pure override returns (string memory) {
        return "HCurve";
    }

    /// @notice Curve exchange
    function exchange(
        address handler,
        address tokenI,
        address tokenJ,
        int128 i,
        int128 j,
        uint256 amount,
        uint256 minAmount
    ) external payable returns (uint256) {
        (uint256 _amount, uint256 balanceBefore, uint256 ethAmount) =
            _exchangeBefore(handler, tokenI, tokenJ, amount);
        try
            ICurveHandler(handler).exchange{value: ethAmount}(
                i,
                j,
                _amount,
                minAmount
            )
        {} catch Error(string memory reason) {
            _revertMsg("exchange", reason);
        } catch {
            _revertMsg("exchange");
        }

        return _exchangeAfter(handler, tokenI, tokenJ, balanceBefore);
    }

    /// @notice Curve exchange with uint256 ij
    function exchangeUint256(
        address handler,
        address tokenI,
        address tokenJ,
        uint256 i,
        uint256 j,
        uint256 amount,
        uint256 minAmount
    ) external payable returns (uint256) {
        (uint256 _amount, uint256 balanceBefore, uint256 ethAmount) =
            _exchangeBefore(handler, tokenI, tokenJ, amount);
        try
            ICurveHandler(handler).exchange{value: ethAmount}(
                i,
                j,
                _amount,
                minAmount
            )
        {} catch Error(string memory reason) {
            _revertMsg("exchangeUint256", reason);
        } catch {
            _revertMsg("exchangeUint256");
        }

        return _exchangeAfter(handler, tokenI, tokenJ, balanceBefore);
    }

    /// @notice Curve exchange with uint256 ij and ether flag
    function exchangeUint256Ether(
        address handler,
        address tokenI,
        address tokenJ,
        uint256 i,
        uint256 j,
        uint256 amount,
        uint256 minAmount
    ) external payable returns (uint256) {
        (uint256 _amount, uint256 balanceBefore, uint256 ethAmount) =
            _exchangeBefore(handler, tokenI, tokenJ, amount);
        try
            ICurveHandler(handler).exchange{value: ethAmount}(
                i,
                j,
                _amount,
                minAmount,
                true
            )
        {} catch Error(string memory reason) {
            _revertMsg("exchangeUint256Ether", reason);
        } catch {
            _revertMsg("exchangeUint256Ether");
        }

        return _exchangeAfter(handler, tokenI, tokenJ, balanceBefore);
    }

    /// @notice Curve exchange underlying
    function exchangeUnderlying(
        address handler,
        address tokenI,
        address tokenJ,
        int128 i,
        int128 j,
        uint256 amount,
        uint256 minAmount
    ) external payable returns (uint256) {
        (uint256 _amount, uint256 balanceBefore, uint256 ethAmount) =
            _exchangeBefore(handler, tokenI, tokenJ, amount);
        try
            ICurveHandler(handler).exchange_underlying{value: ethAmount}(
                i,
                j,
                _amount,
                minAmount
            )
        {} catch Error(string memory reason) {
            _revertMsg("exchangeUnderlying", reason);
        } catch {
            _revertMsg("exchangeUnderlying");
        }

        return _exchangeAfter(handler, tokenI, tokenJ, balanceBefore);
    }

    /// @notice Curve exchange underlying with factory zap
    function exchangeUnderlyingFactoryZap(
        address handler,
        address pool,
        address tokenI,
        address tokenJ,
        int128 i,
        int128 j,
        uint256 amount,
        uint256 minAmount
    ) external payable returns (uint256) {
        (uint256 _amount, uint256 balanceBefore, uint256 ethAmount) =
            _exchangeBefore(handler, tokenI, tokenJ, amount);
        try
            ICurveHandler(handler).exchange_underlying{value: ethAmount}(
                pool,
                i,
                j,
                _amount,
                minAmount
            )
        {} catch Error(string memory reason) {
            _revertMsg("exchangeUnderlyingFactoryZap", reason);
        } catch {
            _revertMsg("exchangeUnderlyingFactoryZap");
        }

        return _exchangeAfter(handler, tokenI, tokenJ, balanceBefore);
    }

    /// @notice Curve exchange underlying with uint256 ij
    function exchangeUnderlyingUint256(
        address handler,
        address tokenI,
        address tokenJ,
        uint256 i,
        uint256 j,
        uint256 amount,
        uint256 minAmount
    ) external payable returns (uint256) {
        (uint256 _amount, uint256 balanceBefore, uint256 ethAmount) =
            _exchangeBefore(handler, tokenI, tokenJ, amount);
        try
            ICurveHandler(handler).exchange_underlying{value: ethAmount}(
                i,
                j,
                _amount,
                minAmount
            )
        {} catch Error(string memory reason) {
            _revertMsg("exchangeUnderlyingUint256", reason);
        } catch {
            _revertMsg("exchangeUnderlyingUint256");
        }

        return _exchangeAfter(handler, tokenI, tokenJ, balanceBefore);
    }

    function _exchangeBefore(
        address handler,
        address tokenI,
        address tokenJ,
        uint256 amount
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        _notMaticToken(tokenI);
        amount = _getBalance(tokenI, amount);
        uint256 balanceBefore = _getBalance(tokenJ, type(uint256).max);

        // Approve erc20 token or set eth amount
        uint256 ethAmount;
        if (tokenI != NATIVE_TOKEN_ADDRESS) {
            _tokenApprove(tokenI, handler, amount);
        } else {
            ethAmount = amount;
        }

        return (amount, balanceBefore, ethAmount);
    }

    function _exchangeAfter(
        address handler,
        address tokenI,
        address tokenJ,
        uint256 balanceBefore
    ) internal returns (uint256) {
        uint256 balance = _getBalance(tokenJ, type(uint256).max);
        _requireMsg(
            balance > balanceBefore,
            "_exchangeAfter",
            "after <= before"
        );

        if (tokenI != NATIVE_TOKEN_ADDRESS) _tokenApproveZero(tokenI, handler);

        if (tokenJ != NATIVE_TOKEN_ADDRESS) _updateToken(tokenJ);

        return balance - balanceBefore;
    }

    /// @notice Curve add liquidity
    function addLiquidity(
        address handler,
        address pool,
        address[] calldata tokens,
        uint256[] calldata amounts,
        uint256 minPoolAmount
    ) external payable returns (uint256) {
        (uint256[] memory _amounts, uint256 balanceBefore, uint256 ethAmount) =
            _addLiquidityBefore(handler, pool, tokens, amounts);

        // Execute add_liquidity according to amount array size
        if (_amounts.length == 2) {
            uint256[2] memory amts = [_amounts[0], _amounts[1]];
            try
                ICurveHandler(handler).add_liquidity{value: ethAmount}(
                    amts,
                    minPoolAmount
                )
            {} catch Error(string memory reason) {
                _revertMsg("addLiquidity", reason);
            } catch {
                _revertMsg("addLiquidity");
            }
        } else if (_amounts.length == 3) {
            uint256[3] memory amts = [_amounts[0], _amounts[1], _amounts[2]];
            try
                ICurveHandler(handler).add_liquidity{value: ethAmount}(
                    amts,
                    minPoolAmount
                )
            {} catch Error(string memory reason) {
                _revertMsg("addLiquidity", reason);
            } catch {
                _revertMsg("addLiquidity");
            }
        } else if (_amounts.length == 4) {
            uint256[4] memory amts =
                [_amounts[0], _amounts[1], _amounts[2], _amounts[3]];
            try
                ICurveHandler(handler).add_liquidity{value: ethAmount}(
                    amts,
                    minPoolAmount
                )
            {} catch Error(string memory reason) {
                _revertMsg("addLiquidity", reason);
            } catch {
                _revertMsg("addLiquidity");
            }
        } else if (_amounts.length == 5) {
            uint256[5] memory amts =
                [
                    _amounts[0],
                    _amounts[1],
                    _amounts[2],
                    _amounts[3],
                    _amounts[4]
                ];
            try
                ICurveHandler(handler).add_liquidity{value: ethAmount}(
                    amts,
                    minPoolAmount
                )
            {} catch Error(string memory reason) {
                _revertMsg("addLiquidity", reason);
            } catch {
                _revertMsg("addLiquidity");
            }
        } else if (_amounts.length == 6) {
            uint256[6] memory amts =
                [
                    _amounts[0],
                    _amounts[1],
                    _amounts[2],
                    _amounts[3],
                    _amounts[4],
                    _amounts[5]
                ];
            try
                ICurveHandler(handler).add_liquidity{value: ethAmount}(
                    amts,
                    minPoolAmount
                )
            {} catch Error(string memory reason) {
                _revertMsg("addLiquidity", reason);
            } catch {
                _revertMsg("addLiquidity");
            }
        } else {
            _revertMsg("addLiquidity", "invalid amount[] size");
        }

        return
            _addLiquidityAfter(handler, pool, tokens, amounts, balanceBefore);
    }

    /// @notice Curve add liquidity with underlying true flag
    function addLiquidityUnderlying(
        address handler,
        address pool,
        address[] calldata tokens,
        uint256[] calldata amounts,
        uint256 minPoolAmount
    ) external payable returns (uint256) {
        (uint256[] memory _amounts, uint256 balanceBefore, uint256 ethAmount) =
            _addLiquidityBefore(handler, pool, tokens, amounts);

        // Execute add_liquidity according to amount array size
        if (_amounts.length == 2) {
            uint256[2] memory amts = [_amounts[0], _amounts[1]];
            try
                ICurveHandler(handler).add_liquidity{value: ethAmount}(
                    amts,
                    minPoolAmount,
                    true
                )
            {} catch Error(string memory reason) {
                _revertMsg("addLiquidityUnderlying", reason);
            } catch {
                _revertMsg("addLiquidityUnderlying");
            }
        } else if (_amounts.length == 3) {
            uint256[3] memory amts = [_amounts[0], _amounts[1], _amounts[2]];
            try
                ICurveHandler(handler).add_liquidity{value: ethAmount}(
                    amts,
                    minPoolAmount,
                    true
                )
            {} catch Error(string memory reason) {
                _revertMsg("addLiquidityUnderlying", reason);
            } catch {
                _revertMsg("addLiquidityUnderlying");
            }
        } else if (_amounts.length == 4) {
            uint256[4] memory amts =
                [_amounts[0], _amounts[1], _amounts[2], _amounts[3]];
            try
                ICurveHandler(handler).add_liquidity{value: ethAmount}(
                    amts,
                    minPoolAmount,
                    true
                )
            {} catch Error(string memory reason) {
                _revertMsg("addLiquidityUnderlying", reason);
            } catch {
                _revertMsg("addLiquidityUnderlying");
            }
        } else if (_amounts.length == 5) {
            uint256[5] memory amts =
                [
                    _amounts[0],
                    _amounts[1],
                    _amounts[2],
                    _amounts[3],
                    _amounts[4]
                ];
            try
                ICurveHandler(handler).add_liquidity{value: ethAmount}(
                    amts,
                    minPoolAmount,
                    true
                )
            {} catch Error(string memory reason) {
                _revertMsg("addLiquidityUnderlying", reason);
            } catch {
                _revertMsg("addLiquidityUnderlying");
            }
        } else if (_amounts.length == 6) {
            uint256[6] memory amts =
                [
                    _amounts[0],
                    _amounts[1],
                    _amounts[2],
                    _amounts[3],
                    _amounts[4],
                    _amounts[5]
                ];
            try
                ICurveHandler(handler).add_liquidity{value: ethAmount}(
                    amts,
                    minPoolAmount,
                    true
                )
            {} catch Error(string memory reason) {
                _revertMsg("addLiquidityUnderlying", reason);
            } catch {
                _revertMsg("addLiquidityUnderlying");
            }
        } else {
            _revertMsg("addLiquidityUnderlying", "invalid amount[] size");
        }

        return
            _addLiquidityAfter(handler, pool, tokens, amounts, balanceBefore);
    }

    /// @notice Curve add liquidity with factory zap
    function addLiquidityFactoryZap(
        address handler,
        address pool,
        address[] calldata tokens,
        uint256[] calldata amounts,
        uint256 minPoolAmount
    ) external payable returns (uint256) {
        (uint256[] memory _amounts, uint256 balanceBefore, uint256 ethAmount) =
            _addLiquidityBefore(handler, pool, tokens, amounts);

        // Execute add_liquidity according to amount array size
        if (_amounts.length == 3) {
            uint256[3] memory amts = [_amounts[0], _amounts[1], _amounts[2]];
            try
                ICurveHandler(handler).add_liquidity{value: ethAmount}(
                    pool,
                    amts,
                    minPoolAmount
                )
            {} catch Error(string memory reason) {
                _revertMsg("addLiquidityFactoryZap", reason);
            } catch {
                _revertMsg("addLiquidityFactoryZap");
            }
        } else if (_amounts.length == 4) {
            uint256[4] memory amts =
                [_amounts[0], _amounts[1], _amounts[2], _amounts[3]];
            try
                ICurveHandler(handler).add_liquidity{value: ethAmount}(
                    pool,
                    amts,
                    minPoolAmount
                )
            {} catch Error(string memory reason) {
                _revertMsg("addLiquidityFactoryZap", reason);
            } catch {
                _revertMsg("addLiquidityFactoryZap");
            }
        } else if (_amounts.length == 5) {
            uint256[5] memory amts =
                [
                    _amounts[0],
                    _amounts[1],
                    _amounts[2],
                    _amounts[3],
                    _amounts[4]
                ];
            try
                ICurveHandler(handler).add_liquidity{value: ethAmount}(
                    pool,
                    amts,
                    minPoolAmount
                )
            {} catch Error(string memory reason) {
                _revertMsg("addLiquidityFactoryZap", reason);
            } catch {
                _revertMsg("addLiquidityFactoryZap");
            }
        } else if (_amounts.length == 6) {
            uint256[6] memory amts =
                [
                    _amounts[0],
                    _amounts[1],
                    _amounts[2],
                    _amounts[3],
                    _amounts[4],
                    _amounts[5]
                ];
            try
                ICurveHandler(handler).add_liquidity{value: ethAmount}(
                    pool,
                    amts,
                    minPoolAmount
                )
            {} catch Error(string memory reason) {
                _revertMsg("addLiquidityFactoryZap", reason);
            } catch {
                _revertMsg("addLiquidityFactoryZap");
            }
        } else {
            _revertMsg("addLiquidityFactoryZap", "invalid amount[] size");
        }

        return
            _addLiquidityAfter(handler, pool, tokens, amounts, balanceBefore);
    }

    function _addLiquidityBefore(
        address handler,
        address pool,
        address[] memory tokens,
        uint256[] memory amounts
    )
        internal
        returns (
            uint256[] memory,
            uint256,
            uint256
        )
    {
        _notMaticToken(tokens);
        uint256 balanceBefore = IERC20(pool).balanceOf(address(this));

        // Approve non-zero amount erc20 token and set eth amount
        uint256 ethAmount;
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] == 0) continue;
            amounts[i] = _getBalance(tokens[i], amounts[i]);
            if (tokens[i] == NATIVE_TOKEN_ADDRESS) {
                ethAmount = amounts[i];
                continue;
            }
            _tokenApprove(tokens[i], handler, amounts[i]);
        }

        return (amounts, balanceBefore, ethAmount);
    }

    function _addLiquidityAfter(
        address handler,
        address pool,
        address[] memory tokens,
        uint256[] memory amounts,
        uint256 balanceBefore
    ) internal returns (uint256) {
        uint256 balance = IERC20(pool).balanceOf(address(this));
        _requireMsg(
            balance > balanceBefore,
            "_addLiquidityAfter",
            "after <= before"
        );

        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] == 0) continue;
            if (tokens[i] != NATIVE_TOKEN_ADDRESS)
                _tokenApproveZero(tokens[i], handler);
        }

        // Update post process
        _updateToken(address(pool));

        return balance - balanceBefore;
    }

    /// @notice Curve remove liquidity one coin
    function removeLiquidityOneCoin(
        address handler,
        address pool,
        address tokenI,
        uint256 poolAmount,
        int128 i,
        uint256 minAmount
    ) external payable returns (uint256) {
        (uint256 _poolAmount, uint256 balanceBefore) =
            _removeLiquidityOneCoinBefore(handler, pool, tokenI, poolAmount);
        try
            ICurveHandler(handler).remove_liquidity_one_coin(
                _poolAmount,
                i,
                minAmount
            )
        {} catch Error(string memory reason) {
            _revertMsg("removeLiquidityOneCoin", reason);
        } catch {
            _revertMsg("removeLiquidityOneCoin");
        }

        return
            _removeLiquidityOneCoinAfter(handler, pool, tokenI, balanceBefore);
    }

    /// @notice Curve remove liquidity one coin with uint256 i
    function removeLiquidityOneCoinUint256(
        address handler,
        address pool,
        address tokenI,
        uint256 poolAmount,
        uint256 i,
        uint256 minAmount
    ) external payable returns (uint256) {
        (uint256 _poolAmount, uint256 balanceBefore) =
            _removeLiquidityOneCoinBefore(handler, pool, tokenI, poolAmount);
        try
            ICurveHandler(handler).remove_liquidity_one_coin(
                _poolAmount,
                i,
                minAmount
            )
        {} catch Error(string memory reason) {
            _revertMsg("removeLiquidityOneCoinUint256", reason);
        } catch {
            _revertMsg("removeLiquidityOneCoinUint256");
        }

        return
            _removeLiquidityOneCoinAfter(handler, pool, tokenI, balanceBefore);
    }

    /// @notice Curve remove liquidity one coin underlying
    function removeLiquidityOneCoinUnderlying(
        address handler,
        address pool,
        address tokenI,
        uint256 poolAmount,
        int128 i,
        uint256 minAmount
    ) external payable returns (uint256) {
        (uint256 _poolAmount, uint256 balanceBefore) =
            _removeLiquidityOneCoinBefore(handler, pool, tokenI, poolAmount);
        try
            ICurveHandler(handler).remove_liquidity_one_coin(
                _poolAmount,
                i,
                minAmount,
                true
            )
        {} catch Error(string memory reason) {
            _revertMsg("removeLiquidityOneCoinUnderlying", reason);
        } catch {
            _revertMsg("removeLiquidityOneCoinUnderlying");
        }

        return
            _removeLiquidityOneCoinAfter(handler, pool, tokenI, balanceBefore);
    }

    /// @notice Curve remove liquidity one coin underlying with uint256 i
    function removeLiquidityOneCoinUnderlyingUint256(
        address handler,
        address pool,
        address tokenI,
        uint256 poolAmount,
        uint256 i,
        uint256 minAmount
    ) external payable returns (uint256) {
        (uint256 _poolAmount, uint256 balanceBefore) =
            _removeLiquidityOneCoinBefore(handler, pool, tokenI, poolAmount);
        try
            ICurveHandler(handler).remove_liquidity_one_coin(
                _poolAmount,
                i,
                minAmount,
                true
            )
        {} catch Error(string memory reason) {
            _revertMsg("removeLiquidityOneCoinUnderlyingUint256", reason);
        } catch {
            _revertMsg("removeLiquidityOneCoinUnderlyingUint256");
        }

        return
            _removeLiquidityOneCoinAfter(handler, pool, tokenI, balanceBefore);
    }

    /// @notice Curve remove liquidity one coin with with factory zap
    function removeLiquidityOneCoinFactoryZap(
        address handler,
        address pool,
        address tokenI,
        uint256 poolAmount,
        int128 i,
        uint256 minAmount
    ) external payable returns (uint256) {
        (uint256 _poolAmount, uint256 balanceBefore) =
            _removeLiquidityOneCoinBefore(handler, pool, tokenI, poolAmount);
        try
            ICurveHandler(handler).remove_liquidity_one_coin(
                pool,
                _poolAmount,
                i,
                minAmount
            )
        {} catch Error(string memory reason) {
            _revertMsg("removeLiquidityOneCoinFactoryZap", reason);
        } catch {
            _revertMsg("removeLiquidityOneCoinFactoryZap");
        }

        return
            _removeLiquidityOneCoinAfter(handler, pool, tokenI, balanceBefore);
    }

    function _removeLiquidityOneCoinBefore(
        address handler,
        address pool,
        address tokenI,
        uint256 poolAmount
    ) internal returns (uint256, uint256) {
        uint256 balanceBefore = _getBalance(tokenI, type(uint256).max);
        poolAmount = _getBalance(pool, poolAmount);
        _tokenApprove(pool, handler, poolAmount);

        return (poolAmount, balanceBefore);
    }

    function _removeLiquidityOneCoinAfter(
        address handler,
        address pool,
        address tokenI,
        uint256 balanceBefore
    ) internal returns (uint256) {
        _tokenApproveZero(pool, handler);
        uint256 balance = _getBalance(tokenI, type(uint256).max);
        _requireMsg(
            balance > balanceBefore,
            "_removeLiquidityOneCoinAfter",
            "after <= before"
        );

        // Update post process
        if (tokenI != NATIVE_TOKEN_ADDRESS) _updateToken(tokenI);

        return balance - balanceBefore;
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interface/IERC20Usdt.sol";

import "../Config.sol";
import "../Storage.sol";

abstract contract HandlerBase is Storage, Config {
    using SafeERC20 for IERC20;
    using LibStack for bytes32[];

    address public constant NATIVE_TOKEN_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant MATIC_TOKEN =
        0x0000000000000000000000000000000000001010;

    function postProcess() external payable virtual {
        revert("Invalid post process");
        /* Implementation template
        bytes4 sig = stack.getSig();
        if (sig == bytes4(keccak256(bytes("handlerFunction_1()")))) {
            // Do something
        } else if (sig == bytes4(keccak256(bytes("handlerFunction_2()")))) {
            bytes32 temp = stack.get();
            // Do something
        } else revert("Invalid post process");
        */
    }

    function _updateToken(address token) internal {
        _notMaticToken(token);
        stack.setAddress(token);
        // Ignore token type to fit old handlers
        // stack.setHandlerType(uint256(HandlerType.Token));
    }

    function _updatePostProcess(bytes32[] memory params) internal {
        for (uint256 i = params.length; i > 0; i--) {
            stack.set(params[i - 1]);
        }
        stack.set(msg.sig);
        stack.setHandlerType(HandlerType.Custom);
    }

    function getContractName() public pure virtual returns (string memory);

    function _revertMsg(string memory functionName, string memory reason)
        internal
        pure
    {
        revert(
            string(
                abi.encodePacked(
                    getContractName(),
                    "_",
                    functionName,
                    ": ",
                    reason
                )
            )
        );
    }

    function _revertMsg(string memory functionName) internal pure {
        _revertMsg(functionName, "Unspecified");
    }

    function _requireMsg(
        bool condition,
        string memory functionName,
        string memory reason
    ) internal pure {
        if (!condition) _revertMsg(functionName, reason);
    }

    function _uint2String(uint256 n) internal pure returns (string memory) {
        if (n == 0) {
            return "0";
        } else {
            uint256 len = 0;
            for (uint256 temp = n; temp > 0; temp /= 10) {
                len++;
            }
            bytes memory str = new bytes(len);
            for (uint256 i = len; i > 0; i--) {
                str[i - 1] = bytes1(uint8(48 + (n % 10)));
                n /= 10;
            }
            return string(str);
        }
    }

    function _getBalance(address token, uint256 amount)
        internal
        view
        returns (uint256)
    {
        if (amount != type(uint256).max) {
            return amount;
        }

        // ETH case
        if (token == address(0) || token == NATIVE_TOKEN_ADDRESS) {
            return address(this).balance;
        }
        // ERC20 token case
        return IERC20(token).balanceOf(address(this));
    }

    function _tokenApprove(
        address token,
        address spender,
        uint256 amount
    ) internal {
        try IERC20Usdt(token).approve(spender, amount) {} catch {
            IERC20(token).safeApprove(spender, 0);
            IERC20(token).safeApprove(spender, amount);
        }
    }

    function _tokenApproveZero(address token, address spender) internal {
        if (IERC20Usdt(token).allowance(address(this), spender) > 0) {
            try IERC20Usdt(token).approve(spender, 0) {} catch {
                IERC20Usdt(token).approve(spender, 1);
            }
        }
    }

    // Do not support matic token (0x0000...1010)
    function _notMaticToken(address token) internal pure {
        require(token != MATIC_TOKEN, "Not support matic token");
    }

    function _notMaticToken(address[] memory tokens) internal pure {
        for (uint256 i = 0; i < tokens.length; i++) {
            require(tokens[i] != MATIC_TOKEN, "Not support matic token");
        }
    }

    function _isNotNativeToken(address token) internal pure returns (bool) {
        return (token != address(0) && token != NATIVE_TOKEN_ADDRESS);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICurveHandler {
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool boolean // use_eth
    ) external payable;

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy_underlying(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function exchange_underlying(
        address pool,
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool boolean // use_eth
    ) external payable;

    // Curve add liquidity function only support static array
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external
        payable;

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
        external
        payable;

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount)
        external
        payable;

    function add_liquidity(uint256[5] calldata amounts, uint256 min_mint_amount)
        external
        payable;

    function add_liquidity(uint256[6] calldata amounts, uint256 min_mint_amount)
        external
        payable;

    // Curve add liquidity underlying
    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 min_mint_amount,
        bool boolean // use_underlying
    ) external payable;

    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool boolean // use_underlying
    ) external payable;

    function add_liquidity(
        uint256[4] calldata amounts,
        uint256 min_mint_amount,
        bool boolean // use_underlying
    ) external payable;

    function add_liquidity(
        uint256[5] calldata amounts,
        uint256 min_mint_amount,
        bool boolean // use_underlying
    ) external payable;

    function add_liquidity(
        uint256[6] calldata amounts,
        uint256 min_mint_amount,
        bool boolean // use_underlying
    ) external payable;

    function calc_token_amount(uint256[2] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[4] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[5] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[6] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    // Curve add liquidity factory metapool deposit zap
    function add_liquidity(
        address pool,
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function add_liquidity(
        address pool,
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function add_liquidity(
        address pool,
        uint256[5] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function add_liquidity(
        address pool,
        uint256[6] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function calc_token_amount(
        address pool,
        uint256[3] calldata amounts,
        bool deposit
    ) external view returns (uint256);

    function calc_token_amount(
        address pool,
        uint256[4] calldata amounts,
        bool deposit
    ) external view returns (uint256);

    function calc_token_amount(
        address pool,
        uint256[5] calldata amounts,
        bool deposit
    ) external view returns (uint256);

    function calc_token_amount(
        address pool,
        uint256[6] calldata amounts,
        bool deposit
    ) external view returns (uint256);

    // Curve remove liquidity
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 min_amount
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount,
        bool boolean // donate_dust or use_underlying
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 min_uamount,
        bool boolean
    ) external;

    // Curve remove liquidity factory metapool deposit zap
    function remove_liquidity_one_coin(
        address pool,
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, uint256 i)
        external
        view
        returns (uint256);

    // Curve factory metapool deposit zap
    function calc_withdraw_one_coin(
        address pool,
        uint256 _token_amount,
        int128 i
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.0;

interface IERC20Usdt {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external;

    function transferFrom(address sender, address recipient, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Config {
    // function signature of "postProcess()"
    bytes4 public constant POSTPROCESS_SIG = 0xc2722916;

    // The base amount of percentage function
    uint256 public constant PERCENTAGE_BASE = 1 ether;

    // Handler post-process type. Others should not happen now.
    enum HandlerType {Token, Custom, Others}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/LibCache.sol";
import "./lib/LibStack.sol";

/// @notice A cache structure composed by a bytes32 array
contract Storage {
    using LibCache for mapping(bytes32 => bytes32);
    using LibStack for bytes32[];

    bytes32[] public stack;
    mapping(bytes32 => bytes32) public cache;

    // keccak256 hash of "msg.sender"
    // prettier-ignore
    bytes32 public constant MSG_SENDER_KEY = 0xb2f2618cecbbb6e7468cc0f2aa43858ad8d153e0280b22285e28e853bb9d453a;

    modifier isStackEmpty() {
        require(stack.length == 0, "Stack not empty");
        _;
    }

    modifier isInitialized() {
        require(_getSender() != address(0), "Sender is not initialized");
        _;
    }

    modifier isNotInitialized() {
        require(_getSender() == address(0), "Sender is initialized");
        _;
    }

    function _setSender() internal isNotInitialized {
        cache.setAddress(MSG_SENDER_KEY, msg.sender);
    }

    function _resetSender() internal {
        cache.setAddress(MSG_SENDER_KEY, address(0));
    }

    function _getSender() internal view returns (address) {
        return cache.getAddress(MSG_SENDER_KEY);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibCache {
    function set(
        mapping(bytes32 => bytes32) storage _cache,
        bytes32 _key,
        bytes32 _value
    ) internal {
        _cache[_key] = _value;
    }

    function setAddress(
        mapping(bytes32 => bytes32) storage _cache,
        bytes32 _key,
        address _value
    ) internal {
        _cache[_key] = bytes32(uint256(uint160(_value)));
    }

    function setUint256(
        mapping(bytes32 => bytes32) storage _cache,
        bytes32 _key,
        uint256 _value
    ) internal {
        _cache[_key] = bytes32(_value);
    }

    function getAddress(
        mapping(bytes32 => bytes32) storage _cache,
        bytes32 _key
    ) internal view returns (address ret) {
        ret = address(uint160(uint256(_cache[_key])));
    }

    function getUint256(
        mapping(bytes32 => bytes32) storage _cache,
        bytes32 _key
    ) internal view returns (uint256 ret) {
        ret = uint256(_cache[_key]);
    }

    function get(mapping(bytes32 => bytes32) storage _cache, bytes32 _key)
        internal
        view
        returns (bytes32 ret)
    {
        ret = _cache[_key];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Config.sol";

library LibStack {
    function setAddress(bytes32[] storage _stack, address _input) internal {
        _stack.push(bytes32(uint256(uint160(_input))));
    }

    function set(bytes32[] storage _stack, bytes32 _input) internal {
        _stack.push(_input);
    }

    function setHandlerType(bytes32[] storage _stack, Config.HandlerType _input)
        internal
    {
        _stack.push(bytes12(uint96(_input)));
    }

    function getAddress(bytes32[] storage _stack)
        internal
        returns (address ret)
    {
        ret = address(uint160(uint256(peek(_stack))));
        _stack.pop();
    }

    function getSig(bytes32[] storage _stack) internal returns (bytes4 ret) {
        ret = bytes4(peek(_stack));
        _stack.pop();
    }

    function get(bytes32[] storage _stack) internal returns (bytes32 ret) {
        ret = peek(_stack);
        _stack.pop();
    }

    function peek(bytes32[] storage _stack)
        internal
        view
        returns (bytes32 ret)
    {
        uint256 length = _stack.length;
        require(length > 0, "stack empty");
        ret = _stack[length - 1];
    }

    function peek(bytes32[] storage _stack, uint256 _index)
        internal
        view
        returns (bytes32 ret)
    {
        uint256 length = _stack.length;
        require(length > 0, "stack empty");
        require(length > _index, "not enough elements in stack");
        ret = _stack[length - _index - 1];
    }
}