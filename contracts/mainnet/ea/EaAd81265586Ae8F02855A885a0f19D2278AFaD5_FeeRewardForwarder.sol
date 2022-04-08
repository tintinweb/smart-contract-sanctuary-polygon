// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "./interfaces/swaps/IUniswapV2Router02.sol";
import {SafeTransferLib} from "./lib/SafeTransferLib.sol";
import {Governable} from "./lib/Governable.sol";

/// @title Beluga FeeRewardForwarder
/// @author Chainvisions
/// @notice Contract for handling the conversion of Beluga's protocol fees.

contract FeeRewardForwarder is Governable {
    using SafeTransferLib for IERC20;

    /// @notice Percentage to be sent as a gas rebate for doHardWork calls.
    uint256 public rebateNumerator;

    /// @notice Token to convert all fees into for the protocol to hold. Typically is wFTM.
    address public reserveToken;

    /// @notice Multisig to receive protocol fees.
    address public belugaMultisig;

    /// @notice Needed for tokens with transfer fees.
    mapping(address => bool) public transferFeeTokens;

    /// @notice Route for token conversion.
    mapping(address => mapping(address => address[])) public tokenConversionRoute;

    /// @notice Router to use for token conversion.
    mapping(address => mapping(address => address)) public tokenConversionRouter;

    /// @notice If a route uses more than one router, this is needed.
    mapping(address => mapping(address => address[])) public tokenConversionRouters;

    /// @notice Allows for management through the multisig.
    modifier onlyGovernanceOrMultisig {
        require(
            msg.sender == governance() || 
            msg.sender == belugaMultisig,
            "FeeRewardForwarder: Caller is not Governance or Beluga Multisig"
        );
        _;
    }

    constructor(
        address _store,
        address _belugaMultisig,
        address _reserveToken
    ) Governable(_store) {
        rebateNumerator = 1000; // Start off with 10% buyback.
        belugaMultisig = _belugaMultisig;
        reserveToken = _reserveToken;

        // Predefined routes.
        address reserve = reserveToken;

        address boo = address(0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE);

        address spookyRouter = address(0xF491e7B69E4244ad4002BC14e878a34207E38c29);

        tokenConversionRoute[boo][reserve] = [boo, reserve];

        tokenConversionRouter[boo][reserve] = spookyRouter;
    }

    /// @notice Converts `_tokenFrom` into Beluga's target tokens.
    /// @param _tokenFrom Token to convert from.
    /// @param _fee Performance fees to convert into the target tokens.
    function performTokenConversion(address _tokenFrom, uint256 _fee) external {
        IERC20 reserve = IERC20(reserveToken);
        // If the token is the reserve token, send it to the multisig.
        if(_tokenFrom == address(reserve)) {
            IERC20(_tokenFrom).safeTransferFrom(msg.sender, belugaMultisig, _fee);
            return;
        }
        // Else, the token needs to be converted to wFTM.
        address[] memory targetRouteToReward = tokenConversionRoute[_tokenFrom][reserveToken]; // Save to memory to save gas.
        if(targetRouteToReward.length > 1) {
            // Perform conversion if a route to wFTM from `_tokenFrom` is specified.
            IERC20(_tokenFrom).safeTransferFrom(msg.sender, address(this), _fee);
            uint256 feeAfter = IERC20(_tokenFrom).balanceOf(address(this)); // In-case the token has transfer fees.
            IUniswapV2Router02 targetRouter = IUniswapV2Router02(tokenConversionRouter[_tokenFrom][address(reserve)]);
            if(address(targetRouter) != address(0)) {
                // We can safely perform a regular swap.
                uint256 endAmount = _performSwap(targetRouter, IERC20(_tokenFrom), feeAfter, targetRouteToReward);

                // Calculate and distribute split.
                uint256 rebateAmount = (endAmount * rebateNumerator) / 10000;
                uint256 remainingAmount = (endAmount - rebateAmount);
                reserve.safeTransfer(tx.origin, rebateAmount);
                reserve.safeTransfer(belugaMultisig, remainingAmount);
            } else {
                // Else, we need to perform a cross-dex liquidation.
                address[] memory targetRouters = tokenConversionRouters[_tokenFrom][address(reserve)];
                uint256 endAmount = _performMultidexSwap(targetRouters, _tokenFrom, feeAfter, targetRouteToReward);

                // Calculate and distribute split.
                uint256 rebateAmount = (endAmount * rebateNumerator) / 10000;
                uint256 remainingAmount = (endAmount - rebateAmount);
                reserve.safeTransfer(tx.origin, rebateAmount);
                reserve.safeTransfer(belugaMultisig, remainingAmount);
            }
        } else {
            // Else, leave the funds in the Controller.
            return;
        }
    }

    /// @notice Salvages any tokens that are stuck in the contract.
    /// @param _token Token to salvage from the contract.
    /// @param _amount Amount to salvage from the contract.
    function salvage(address _token, uint256 _amount) external onlyGovernanceOrMultisig {
        IERC20(_token).safeTransfer(belugaMultisig, _amount);
    }

    /// @notice Sets the percentage of fees that are to be used for gas rebates.
    /// @param _rebateNumerator Percentage to use for buybacks.
    function setRebateNumerator(uint256 _rebateNumerator) public onlyGovernanceOrMultisig {
        require(_rebateNumerator <= 10000, "FeeRewardForwarder: New numerator is higher than the denominator");
        rebateNumerator = _rebateNumerator;
    }

    /// @notice Sets the address of the Beluga Multisig.
    /// @param _belugaMultisig New multisig address.
    function setBelugaMultisig(address _belugaMultisig) public onlyGovernance {
        belugaMultisig = _belugaMultisig;
    }

    /// @notice Sets the address of the reserve token.
    /// @param _reserveToken Reserve token for the protocol to collect.
    function setReserveToken(address _reserveToken) public onlyGovernance {
        reserveToken = _reserveToken;
    }

    /// @notice Adds a token to the list of transfer fee tokens.
    /// @param _transferFeeToken Token to add to the list.
    function addTransferFeeToken(address _transferFeeToken) public onlyGovernanceOrMultisig {
        transferFeeTokens[_transferFeeToken] = true;
    }

    /// @notice Removes a token from the transfer fee tokens list.
    /// @param _transferFeeToken Address of the transfer fee token.
    function removeTransferFeeToken(address _transferFeeToken) public onlyGovernanceOrMultisig {
        transferFeeTokens[_transferFeeToken] = false;
    }

    /// @notice Sets the route for token conversion.
    /// @param _tokenFrom Token to convert from.
    /// @param _tokenTo Token to convert to.
    /// @param _route Route used for conversion.
    function setTokenConversionRoute(
        address _tokenFrom,
        address _tokenTo,
        address[] memory _route
    ) public onlyGovernance {
        tokenConversionRoute[_tokenFrom][_tokenTo] = _route;
    }

    /// @notice Sets the router for token conversion.
    /// @param _tokenFrom Token to convert from.
    /// @param _tokenTo Token to convert to.
    /// @param _router Target router for the swap.
    function setTokenConversionRouter(
        address _tokenFrom,
        address _tokenTo,
        address _router
    ) public onlyGovernance {
        tokenConversionRouter[_tokenFrom][_tokenTo] = _router;
    }

    /// @notice Sets the routers used for token conversion.
    /// @param _tokenFrom Token to convert from.
    /// @param _tokenTo Token to convert to.
    /// @param _routers Target routers for the swap.
    function setTokenConversionRouters(
        address _tokenFrom,
        address _tokenTo,
        address[] memory _routers
    ) public onlyGovernance {
        tokenConversionRouters[_tokenFrom][_tokenTo] = _routers;
    }

    function _performSwap(
        IUniswapV2Router02 _router,
        IERC20 _tokenFrom,
        uint256 _amount,
        address[] memory _route
    ) internal returns (uint256 endAmount) {
        _tokenFrom.safeApprove(address(_router), 0);
        _tokenFrom.safeApprove(address(_router), _amount);
        if(!transferFeeTokens[address(_tokenFrom)]) {
            uint256[] memory amounts = _router.swapExactTokensForTokens(_amount, 0, _route, address(this), (block.timestamp + 600));
            endAmount = amounts[amounts.length - 1];
        } else {
            _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount, 0, _route, address(this), (block.timestamp + 600));
            endAmount = IERC20(_route[_route.length - 1]).balanceOf(address(this));
        }
    }

    function _performMultidexSwap(
        address[] memory _routers,
        address _tokenFrom,
        uint256 _amount,
        address[] memory _route
    ) internal returns (uint256 endAmount) {
        for(uint256 i = 0; i < _routers.length; i++) {
            // Create swap route.
            address swapRouter = _routers[i];
            address[] memory conversionRoute = new address[](2);
            conversionRoute[0] = _route[i];
            conversionRoute[1] = _route[i+1];

            // Fetch balances.
            address routeStart = conversionRoute[0];
            uint256 routeStartBalance;
            if(routeStart == _tokenFrom) {
                routeStartBalance = _amount;
            } else {
                routeStartBalance = IERC20(routeStart).balanceOf(address(this));
            }
            
            // Perform swap.
            if(conversionRoute[1] != _route[_route.length - 1]) {
                _performSwap(IUniswapV2Router02(swapRouter), IERC20(routeStart), routeStartBalance, conversionRoute);
            } else {
                endAmount = _performSwap(IUniswapV2Router02(swapRouter), IERC20(routeStart), routeStartBalance, conversionRoute);
            }
        }
    }
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
pragma solidity >=0.5.0;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../Storage.sol";

/**
 * @dev Contract for access control where the governance address specified
 * in the Storage contract can be granted access to specific functions
 * on a contract that inherits this contract.
 */

contract Governable {

  Storage public store;

  constructor(address _store) {
    require(_store != address(0), "Governable: New storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Governable: Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "Governable: New storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

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
pragma solidity ^0.8.0;

contract Storage {

  address public governance;
  address public controller;

  constructor() {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Storage: Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "Storage: New governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "Storage: New controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}