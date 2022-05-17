// SPDX-License-Identifier: MIT

//                                                 ______   __                                                   
//                                                /      \ /  |                                                  
//   _______   ______    ______   _______        /$$$$$$  |$$/  _______    ______   _______    _______   ______  
//  /       | /      \  /      \ /       \       $$ |_ $$/ /  |/       \  /      \ /       \  /       | /      \ 
// /$$$$$$$/ /$$$$$$  |/$$$$$$  |$$$$$$$  |      $$   |    $$ |$$$$$$$  | $$$$$$  |$$$$$$$  |/$$$$$$$/ /$$$$$$  |
// $$ |      $$ |  $$ |$$ |  $$/ $$ |  $$ |      $$$$/     $$ |$$ |  $$ | /    $$ |$$ |  $$ |$$ |      $$    $$ |
// $$ \_____ $$ \__$$ |$$ |      $$ |  $$ |      $$ |      $$ |$$ |  $$ |/$$$$$$$ |$$ |  $$ |$$ \_____ $$$$$$$$/ 
// $$       |$$    $$/ $$ |      $$ |  $$ |      $$ |      $$ |$$ |  $$ |$$    $$ |$$ |  $$ |$$       |$$       |
//  $$$$$$$/  $$$$$$/  $$/       $$/   $$/       $$/       $$/ $$/   $$/  $$$$$$$/ $$/   $$/  $$$$$$$/  $$$$$$$/
//                         .-.
//         .-""`""-.    |(@ @)
//      _/`oOoOoOoOo`\_ \ \-/
//     '.-=-=-=-=-=-=-.' \/ \
//       `-=.=-.-=.=-'    \ /\
//          ^  ^  ^       _H_ \

pragma solidity 0.8.13;

import "./interfaces/IController.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


/**
* @title Corn Finance Path Finding Resolver 
* @author C.W.B.
*
* @notice When resolver contracts are called, the returned data is used as the
* input data on a seperate call. This means that the call to the resolver contract
* does not affect the gas used on the state-changing function call.
*
* This resolver contract is used for finding the best swap path across numerous
* Uniswap V2 Routers. Paths will be either:
*   a.) from token --> to token
*   b.) from token --> connector token #1 --> to token
*   c.) from token --> connector token #1 --> connector token #2 --> to token
*/
contract Resolver is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct SwapInfo {
        address router;
        address[] path;
        uint256[] amounts;
    }

    IUniswapV2Router02[] public routers = [
        IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff), // Quickswap
        IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506), // Sushiswap
        IUniswapV2Router02(0x94930a328162957FF1dd48900aF67B5439336cBD), // Polycat
        IUniswapV2Router02(0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607), // ApeSwap
        IUniswapV2Router02(0xA102072A4C07F06EC3B4900FDC4C7B80b6c57429), // Dfyn
        IUniswapV2Router02(0x3a1D87f206D12415f5b0A33E786967680AAb4f6d)  // WaultSwap
    ];
    address[] public connectorTokens = [
        address(0),
        0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063, // DAI
        0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174, // USDC
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270, // WMATIC
        0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619, // WETH
        0xc2132D05D31c914a87C6611C10748AEb04B58e8F, // USDT
        0x831753DD7087CaC61aB5644b308642cc1c33Dc13, // QUICK
        0xa3Fa99A148fA48D14Ed51d610c367C61876997F1, // miMATIC
        0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6  // WBTC
    ];

    // --------------------------------------------------------------------------------

    /**
    * @dev Gelato executor will call this function before calling 'fillOrderGelato()'
    * in the Controller contract.
    * @param _vaultId: Vault that holds the order
    * @param _orderId: Order to fill
    * @param _fromToken: ERC20 token being swapped
    * @param _toToken: ERC20 token received from swap
    * @param _fromAmount: Amount of '_fromToken' going into the swap
    * @return (true: Gelato executor call 'fillOrderGelato()'; false: Gelato executor 
    * will not call 'fillOrderGelato()', Input data for 'fillOrderGelato()')
    */
    function checker(
        uint256 _vaultId, 
        uint256 _orderId, 
        address _fromToken, 
        address _toToken, 
        uint256 _fromAmount
    ) public view returns (bool, bytes memory) {
        // Find the best Uniswap V2 router and path for swapping tokens
        (address router, address[] memory path, ) = findBestPathExactIn(_fromToken, _toToken, _fromAmount);

        // Encode input data for when the Gelato executor calls 'fillOrderGelato()'
        return (
            true, 
            abi.encodeWithSelector(
                IController.fillOrderGelato.selector, 
                _vaultId, 
                _orderId, 
                router, 
                path
            )
        );
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Find the path on the router that returns the highest amount out for a given 
    * swap with a fixed amount in.
    * @param _fromToken: ERC20 token being swapped
    * @param _toToken: ERC20 token received from swap
    * @param _amountIn: Amount of '_fromToken' going into the swap 
    */
    function findBestPathExactIn(
        address _fromToken, 
        address _toToken, 
        uint256 _amountIn
    ) public view returns (address, address[] memory, uint256) {
        uint256 bestAmountOut = 0;
        address bestRouter;
        address[4] memory bestPath;

        (address[4][] memory paths, uint256 pathCount) = getAllPaths(_fromToken, _toToken);

        // Loop through all of the routers
        for(uint i = 0; i < routers.length; i++) {
            // Loop through all of the connector tokens
            for(uint j = 0; j < pathCount; j++) {
                // Get the 'to' amount from the swap
                uint256 amountOut = getAmountOut(
                    routers[i], 
                    _amountIn, 
                    paths[j]
                );

                // Current router and path produce the most amount out yet
                if(amountOut > bestAmountOut) {
                    bestAmountOut = amountOut;
                    bestRouter = address(routers[i]);
                    bestPath = paths[j];
                }
            }
        }

        address[] memory path;

        if(bestPath[3] == address(0)) {
            if(bestPath[2] == address(0)) {
                path = new address[](2);
                path[0] = bestPath[0];
                path[1] = bestPath[1];
            }
            else {
                path = new address[](3);
                path[0] = bestPath[0];
                path[1] = bestPath[1];
                path[2] = bestPath[2];
            }
        }
        else {
            path = new address[](4);
            path[0] = bestPath[0];
            path[1] = bestPath[1];
            path[2] = bestPath[2];
            path[3] = bestPath[3];
        }
        return (bestRouter, path, bestAmountOut);
    }

    // --------------------------------------------------------------------------------

    /**
    * @dev Find the path on the router that returns the lowest amount in for a given 
    * swap with a fixed amount out.
    * @param _fromToken: ERC20 token being swapped
    * @param _toToken: ERC20 token received from swap
    * @param _amountOut: Amount of '_toToken' received from the swap 
    */
    function findBestPathExactOut(
        address _fromToken, 
        address _toToken, 
        uint256 _amountOut
    ) public view returns (address, address[] memory, uint256) {
        uint256 bestAmountIn = type(uint256).max;
        address bestRouter;
        address[4] memory bestPath;

        (address[4][] memory paths, uint256 pathCount) = getAllPaths(_fromToken, _toToken);

        // Loop through all of the routers
        for(uint i = 0; i < routers.length; i++) {
            // Loop through all of the connector tokens
            for(uint j = 0; j < pathCount; j++) {
                // Get the 'to' amount from the swap
                uint256 amountIn = getAmountIn(
                    routers[i], 
                    _amountOut, 
                    paths[j]
                );

                // Current router and path produce the most amount out yet
                if(amountIn < bestAmountIn) {
                    bestAmountIn = amountIn;
                    bestRouter = address(routers[i]);
                    bestPath = paths[j];
                }
            }
        }

        address[] memory path;

        if(bestPath[3] == address(0)) {
            if(bestPath[2] == address(0)) {
                path = new address[](2);
                path[0] = bestPath[0];
                path[1] = bestPath[1];
            }
            else {
                path = new address[](3);
                path[0] = bestPath[0];
                path[1] = bestPath[1];
                path[2] = bestPath[2];
            }
        }
        else {
            path = new address[](4);
            path[0] = bestPath[0];
            path[1] = bestPath[1];
            path[2] = bestPath[2];
            path[3] = bestPath[3];
        }
        return (bestRouter, path, bestAmountIn);
    }

    // --------------------------------------------------------------------------------

    /**
    * @param _router: Router used to perform a swap
    * @param _amountIn: Amount of '_fromToken' going into the swap
    * @return Amount of '_toToken' received from the swap
    */
    function getAmountOut(
        IUniswapV2Router02 _router, 
        uint256 _amountIn, 
        address[4] memory _path
    ) public view returns (uint256) {
        address[] memory path;

        if(_path[3] == address(0)) {
            if(_path[2] == address(0)) {
                path = new address[](2);
                path[0] = _path[0];
                path[1] = _path[1];
            }
            else {
                path = new address[](3);
                path[0] = _path[0];
                path[1] = _path[1];
                path[2] = _path[2];
            }
        }
        else {
            path = new address[](4);
            path[0] = _path[0];
            path[1] = _path[1];
            path[2] = _path[2];
            path[3] = _path[3];
        }

        // Get the 'to' amount from the swap
        try _router.getAmountsOut(_amountIn, path) returns (uint256[] memory amountsOut) {
            return amountsOut[path.length.sub(1)];
        }
        // Call reverted
        catch {
            return 0;
        }
    }

    // --------------------------------------------------------------------------------

    /**
    * @param _router: Router used to perform a swap
    * @param _amountOut: Amount of '_toToken' received from the swap
    * @param _path: List of tokens to perform the swap
    * @return Amount of '_toToken' needed for the swap
    */
    function getAmountIn(
        IUniswapV2Router02 _router, 
        uint256 _amountOut,
        address[4] memory _path 
    ) public view returns (uint256) {
        address[] memory path;

        if(_path[3] == address(0)) {
            if(_path[2] == address(0)) {
                path = new address[](2);
                path[0] = _path[0];
                path[1] = _path[1];
            }
            else {
                path = new address[](3);
                path[0] = _path[0];
                path[1] = _path[1];
                path[2] = _path[2];
            }
        }
        else {
            path = new address[](4);
            path[0] = _path[0];
            path[1] = _path[1];
            path[2] = _path[2];
            path[3] = _path[3];
        }

        // Get the 'to' amount from the swap
        try _router.getAmountsIn(_amountOut, path) returns (uint256[] memory amountsIn) {
            return amountsIn[0];
        }
        // Call reverted
        catch {
            return type(uint256).max;
        }
    }

    // --------------------------------------------------------------------------------

    function swapExactIn(
        IUniswapV2Router02 _router, 
        uint256 _amountIn, 
        uint256 _amountOutMin, 
        address[] memory _path, 
        address _to, 
        uint _deadline
    ) external returns (uint256[] memory) {
        IERC20 tokenIn = IERC20(_path[0]);

        // Transfer tokens from caller to this contract
        tokenIn.safeTransferFrom(msg.sender, address(this), _amountIn);

        // Approve router for swap
        tokenIn.approve(address(_router), _amountIn);

        // Swap
        return _router.swapExactTokensForTokens(_amountIn, _amountOutMin, _path, _to, _deadline);
    }

    // --------------------------------------------------------------------------------

    function getAllPaths(address _fromToken, address _toToken) public view returns (address[4][] memory paths, uint256 pathCount) {
        paths = new address[4][](((connectorTokens.length - 1) ** 2) + 1); 
        pathCount = 0;

        paths[pathCount++] = [_fromToken, _toToken, address(0), address(0)];
        for(uint256 i = 1; i < connectorTokens.length; i++) {
            for(uint256 j = 0; j < connectorTokens.length; j++) {
                if(connectorTokens[i] != _fromToken && connectorTokens[i] != _toToken &&
                    connectorTokens[j] != _fromToken && connectorTokens[j] != _toToken &&
                    connectorTokens[i] != connectorTokens[j]
                ) {
                    if(connectorTokens[j] == address(0)) {
                        paths[pathCount++] = [_fromToken, connectorTokens[i], _toToken, address(0)];
                    }
                    else {
                        paths[pathCount++] = [_fromToken, connectorTokens[i], connectorTokens[j], _toToken];
                    }
                }
            }
        }
    }

    // --------------------------------------------------------------------------------

    /**
    * @notice ERC20 tokens are never stored in this contract. This function is only used
    * for claiming ERC20 tokens sent to this contract in error.
    */
    function emergencyWithdraw(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.safeTransfer(owner(), _amount);
    } 
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IUniswapV2Router02.sol";


interface IController {
    function fillOrderGelato(
        uint256 _vaultId, 
        uint256 _orderId, 
        IUniswapV2Router02 _router, 
        address[] memory _path
    ) external;
}

// SPDX-License-Identifier: MIT

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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