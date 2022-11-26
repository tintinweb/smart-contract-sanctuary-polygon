abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface IStargateReceiver {
    function sgReceive(
        uint16 _srcChainId, // the remote chainId sending the tokens
        bytes memory _srcAddress, // the remote Bridge address
        uint256 _nonce,
        address _token, // the token contract on the local chain
        uint256 amountLD, // the qty of local _token contract tokens
        bytes memory payload
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;
import "./UniswapV3/ISwapRouter.sol";
import "./UniswapV3/TransferHelper.sol";
import "./Access/Ownable.sol";
import "./Stargate/IStargateRouter.sol";
import "./Stargate/IStargateReceiver.sol";
import "./Tokens/IWrapToken.sol";

/// @title StargateComposed
/// @author JstD
/// @dev Stargate combine with UniswapV3
contract StargateComposed is Ownable {
    /// Events
    event ReceivedOnDestination(address token, uint256 amount);
    /// Properties
    address public WNative;
    mapping(uint16 => address) public poolToToken;
    uint24 public poolFee;
    address swapRouter;
    address stargateRouter;
    address Native = 0x0000000000000000000000000000000000000000;
    mapping(uint256 => bool) public processed;
    struct SrcChain {
        address tokenIn;
        uint16 srcPoolId;
        uint256 amountIn;
    }
    struct DestChain {
        address tokenOut;
        uint16 dstChainId;
        uint16 dstPoolId;
        address to;
        uint256 amountOutMin;
        address destStargateComposed;
    }

    /// Methods
    constructor(
        address _WNative,
        address _swapRouter,
        address _stargateRouter
    ) {
        WNative = _WNative;
        swapRouter = _swapRouter;
        stargateRouter = _stargateRouter;
        poolFee = 3000;
    }

    // @notice Contract Owner can change poolFee (dynamic with UniswapV3)
    // @param Documents new_pool_fee
    // @return Documents poolFee change
    function changePoolFee(uint24 new_pool_fee) external onlyOwner {
        poolFee = new_pool_fee;
    }

    // @notice Contract Owner can change WNative
    // @param Documents new_WNative
    // @return Documents WNative change
    function changeWNative(address new_WNative) external onlyOwner {
        WNative = new_WNative;
    }

    function changePoolToken(uint16 poolId, address token) external onlyOwner {
        poolToToken[poolId] = token;
    }

    // @param dstChainId The message ordering nonce
    // @param srcPoolId The token contract on the local chain
    // @param dstPoolId The qty of local _token contract tokens
    // @param amountIn The amount of token coming in on source
    // @param to The address to send the destination tokens to
    // @param amountOutMin The minimum amount of stargatePoolId token to get out of amm router
    // @param amountOutMinSg The minimum amount of stargatePoolId token to get out on destination chain
    // @param amountOutMinDest The minimum amount of native token to receive on destination
    // @param deadline The overall deadline
    // @param destStargateComposed The destination contract address that must implement sgReceive()
    function swapCrosschainToken(
        SrcChain memory srcChain,
        DestChain calldata dstChain,
        uint256 deadline,
        uint256 fee,
        uint256 dstFee
    ) external payable {
        uint256 amountIn = srcChain.amountIn;
        // if native
        if (srcChain.tokenIn == Native) {
            require(amountIn <= msg.value - fee, "Not enough native coin");
            IWToken(WNative).deposit{value: amountIn}();
            srcChain.tokenIn = WNative;
        } else {
            TransferHelper.safeTransferFrom(
                srcChain.tokenIn,
                msg.sender,
                address(this),
                amountIn
            );
        }
        /*
        Action: Using Uniswap!
        Desc: Swap tokenIn to token which can use Stargate
        */

        // approve token
        // Only swap if not same token
        if (srcChain.tokenIn != poolToToken[srcChain.srcPoolId]) {
            TransferHelper.safeApprove(srcChain.tokenIn, swapRouter, amountIn);
            // create swap params
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams({
                    tokenIn: srcChain.tokenIn,
                    tokenOut: poolToToken[srcChain.srcPoolId],
                    fee: poolFee,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amountIn,
                    amountOutMinimum: dstChain.amountOutMin,
                    sqrtPriceLimitX96: 0
                });
            //call swap, get
            amountIn = ISwapRouter(swapRouter).exactInputSingle(params);
        }

        /*
        Action: Using stargate
        Desc: use stargate to transfer acceptable token to destination chain.
        */
        TransferHelper.safeApprove(
            poolToToken[srcChain.srcPoolId],
            stargateRouter,
            amountIn
        );
        bytes memory data;
        {
            data = abi.encode(
                dstChain.tokenOut,
                deadline,
                dstChain.amountOutMin,
                dstChain.to
            );
        }
        IStargateRouter(stargateRouter).swap{value: fee}(
            dstChain.dstChainId,
            srcChain.srcPoolId,
            dstChain.dstPoolId,
            payable(msg.sender),
            amountIn,
            dstChain.amountOutMin,
            IStargateRouter.lzTxObj(dstFee, 0, "0x"),
            abi.encodePacked(dstChain.destStargateComposed),
            data
        );
    }

    // @param _chainId The remote chainId sending the tokens
    // @param _srcAddress The remote Bridge address
    // @param _nonce The message ordering nonce
    // @param _token The token contract on the local chain
    // @param amountLD The qty of local _token contract tokens
    // @param _payload The bytes containing the _tokenOut, _deadline, _amountOutMin, _toAddr
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external payable {
        require(
            msg.sender == address(stargateRouter),
            "only stargate router can call sgReceive!"
        );
        (
            address _tokenOut,
            uint256 _deadline,
            uint256 _amountOutMin,
            address _toAddr
        ) = abi.decode(payload, (address, uint256, uint256, address));

        // check same token
        if (_token == _tokenOut) {
            TransferHelper.safeTransfer(_token, _toAddr, amountLD);
            emit ReceivedOnDestination(_token, amountLD);
        } else {
            address tokenOut = _tokenOut;
            if (_tokenOut == Native) {
                tokenOut = WNative;
            }
            // swap _token to _tokenOut
            TransferHelper.safeApprove(_token, swapRouter, amountLD);
            // create swap params
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams({
                    tokenIn: _token,
                    tokenOut: tokenOut,
                    fee: poolFee,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amountLD,
                    amountOutMinimum: _amountOutMin,
                    sqrtPriceLimitX96: 0
                });
            //call swap, get
            uint256 amountOut = ISwapRouter(swapRouter).exactInputSingle(
                params
            );
            if (_tokenOut == Native) {
                IWToken(WNative).withdraw(amountOut);
                bool sent = payable(_toAddr).send(amountOut);
                require(sent, "Failed to send Ether");
            } else {
                TransferHelper.safeTransfer(_tokenOut, _toAddr, amountOut);
            }
            emit ReceivedOnDestination(_tokenOut, amountOut);
        }
    }

    receive() external payable {}
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;
pragma abicoder v2;

interface IWToken {
    function deposit() external payable;

    function withdraw(uint256) external payable;
}

interface ISwapRouter {
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
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

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
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

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
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

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
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;
import "../Tokens/IERC20.sol";

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
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "STF"
        );
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
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ST"
        );
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
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SA"
        );
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }
}