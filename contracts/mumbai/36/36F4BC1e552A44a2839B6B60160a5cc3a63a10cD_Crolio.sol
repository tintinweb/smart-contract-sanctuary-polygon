// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
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

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error UNAUTHORIZED();
error UNEQUAL_TOKENS_AND_WEIGHTS();
error WEIGHTAGE_NOT_100();
error INVESTED_AMOUNT_0();
error INSUFFICIENT_FEES();

contract Crolio {

    address private immutable _admin;
    address private immutable _USDCContract;
    ISwapRouter private immutable _swapRouter;

    uint24 private constant poolFee = 100;

    constructor(address swapRouter, address USDCContract) {
        _swapRouter = ISwapRouter(swapRouter);
        _USDCContract = USDCContract;
        _admin = msg.sender;
    }

    // struct to store a bucket details
    struct Bucket {
        string name;
        string description;
        address[] tokens;
        uint256[] weightages;
        address creator;
    }

    // struct to maintain User Investments
    struct UserInvestment {
        uint256 totalUSDCInvested;
        uint256[] holdings;
    }

    // mapping to track user investments, username -> bucketId -> investment struct
    mapping (address => mapping(uint256 => UserInvestment)) private _userInvestments;

    // mapping to track every bucket
    mapping (uint256 => Bucket) public bucketDetails;

    // private counter to maintain the number of buckets
    uint256 private _counter = 0;

    // array of supported tokens
    address[] public supportedTokens;

    // event for bucket creation
    event BucketCreated(uint256 bucketId, string bucketName, string description, address[] tokens, uint256[] weightages, address creator);
    event InvestedInBucket(uint256 bucketId, uint256 amountInvested, address investorAddress, address[] tokens, uint256[] holdingsBought);
    event WithdrawnFromBucket(uint256 bucketId, uint256 amountOut, address investorAddress, address[] tokens, uint256[] holdingsSold);

    // function to create a bucket - onlyOwner
    function createBucket(string memory name, string memory description, address[] memory tokens, uint256[] memory weightage) external returns (bool) {
        if (tokens.length != weightage.length) {
            revert UNEQUAL_TOKENS_AND_WEIGHTS();
        }

        uint256 totalWeightage = 0;

        for (uint256 i = 0; i < weightage.length; i++) {
            totalWeightage += weightage[i];
        }

        if (totalWeightage != 10000) {
            revert WEIGHTAGE_NOT_100();
        }

        bucketDetails[_counter] = Bucket({
            name: name,
            description: description,
            tokens: tokens,
            weightages: weightage,
            creator: msg.sender
        });

        emit BucketCreated(_counter, name, description, tokens, weightage, msg.sender);

        _counter++;
        return true;
    }

    // fetch a bucket - return struct
    function fetchBucketDetails(uint256 _bucketId) external view returns (Bucket memory) {
        return bucketDetails[_bucketId];
    }

    // Invest util
    function swapUSDCToToken(uint256 amountIn, address _tokenOut) internal returns (uint256 amountOut) {
        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _USDCContract,
                tokenOut: _tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        // The call to `exactInputSingle` executes the swap.
        amountOut = _swapRouter.exactInputSingle(params);
    }

    // Withdraw util
    function swapTokenToUSDC(uint256 amountIn, address _tokenIn) internal returns (uint256 amountOut) {
        // Approve the router to spend _tokenIn.
        TransferHelper.safeApprove(_tokenIn, address(_swapRouter), amountIn);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _USDCContract,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = _swapRouter.exactInputSingle(params);
    }

    // function usdcFraction
    function calculateInvestedAmountForToken(uint256 weightage, uint256 investedAmount) internal pure returns (uint256) {
        return (investedAmount / 10000) * weightage;
    }

    // Invest function
    function invest(uint256 _bucketId, uint256 _investValue, uint256 _deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool) {
        IERC20Permit(_USDCContract).permit(msg.sender, address(this), _investValue, _deadline, v, r, s);
        TransferHelper.safeTransferFrom(_USDCContract, msg.sender, address(this), _investValue);
        TransferHelper.safeTransferFrom(_USDCContract, msg.sender, address(this), _investValue);
        TransferHelper.safeApprove(_USDCContract, address(_swapRouter), _investValue);

        Bucket memory bucket = bucketDetails[_bucketId];
        address[] memory tokens = bucket.tokens;
        uint256[] memory weights = bucket.weightages;

        uint256[] memory holdings = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i += 1) {
            uint256 usdcInvestAmountForToken = calculateInvestedAmountForToken(weights[i], _investValue);
            holdings[i] = swapUSDCToToken(usdcInvestAmountForToken, tokens[i]);
        }

        uint256[] memory currentHoldings = _userInvestments[msg.sender][_bucketId].holdings;

        if (_userInvestments[msg.sender][_bucketId].totalUSDCInvested == 0) {
            _userInvestments[msg.sender][_bucketId].totalUSDCInvested = _investValue;
            _userInvestments[msg.sender][_bucketId].holdings = holdings;
        } else {
            _userInvestments[msg.sender][_bucketId].totalUSDCInvested += _investValue;
            uint256 _bucket = _bucketId;
            uint256[] memory updatedHoldings = new uint256[](currentHoldings.length);
            for (uint256 j = 0; j < currentHoldings.length; j += 1) {
                updatedHoldings[j] = currentHoldings[j] + holdings[j];
            }
            _userInvestments[msg.sender][_bucket].holdings = updatedHoldings;
        }

        emit InvestedInBucket(_bucketId, _investValue, msg.sender, tokens, holdings);
        return true;
    }

    // Withdraw function
    function withdraw(uint256 _bucketId) external returns (bool) {
        if (_userInvestments[msg.sender][_bucketId].totalUSDCInvested <= 0) {
            revert INVESTED_AMOUNT_0();
        }

        Bucket memory bucket = bucketDetails[_bucketId];
        address[] memory tokens = bucket.tokens;

        UserInvestment memory investment = _userInvestments[msg.sender][_bucketId];
        uint256[] memory holdings = investment.holdings;

        uint256 amountOut = 0;

        for (uint256 i = 0; i < holdings.length; i += 1) {
            amountOut += swapTokenToUSDC(holdings[i], tokens[i]);
        }

        delete _userInvestments[msg.sender][_bucketId];
        emit WithdrawnFromBucket(_bucketId, amountOut, msg.sender, tokens, holdings);
        return true;
    }

    // get user investment details
    function getAllUserInvestmentDetails(uint256 _bucketId) external view returns (UserInvestment memory) {
        return _userInvestments[msg.sender][_bucketId];
    }
}