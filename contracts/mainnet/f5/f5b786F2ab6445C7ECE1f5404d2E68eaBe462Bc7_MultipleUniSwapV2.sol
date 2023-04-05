// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import './uniswap/TransferHelper.sol';
import "./ERC20Transfer.sol";

contract MultipleUniSwapV2 is ERC20Transfer {

    event OrderCreated(address indexed _owner, uint256 _orderId);
    event SwapProcessed(address indexed _owner, uint256 _itemId, uint256 _status, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);
    event ChangeFee(uint256 _fee);
    event ChangeMaxDeadline(uint256 _maxDeadline);

    uint256 constant SWAP_PENDING = 0;
    uint256 constant SWAP_SUCCESS = 1;
    uint256 constant SWAP_EXPIRED = 2;
    uint256 constant SWAP_FAIL = 3;
    uint256 constant SWAP_IN_PROGRESS = 4;

    uint256 constant BASE = 10000;

    ISwapRouter public immutable _swapRouter;

    uint256 private _currentOrderId;
    uint256 private _fee;
    uint256 private _maxDeadline;

    mapping(address => uint256[]) private _userOrders;
    mapping(uint256 => uint256[]) private _orderItemIndexes;
    mapping(uint256 => uint24[]) private _itemSwapFeeInfo;
    mapping(uint256 => address[]) private _itemSwapIntermediateTokenOut;

    struct SwapTokensPair {
        address _owner;
        address _tokenIn;
        address _tokenOut;
        uint256 _amountIn;
        uint256 _amountOutMinimum;
        uint256 _status;
        uint256 _deadline;
        uint256 _amountInReal;
        uint256 _amountOutReal;
        uint256 _createdAt;
        uint256 _orderId;
    }

    SwapTokensPair[] private _items;

    constructor(ISwapRouter swapRouter, uint256 fee, uint256 maxDeadline) {
        _swapRouter = swapRouter;
        _fee = fee;
        _maxDeadline = maxDeadline;
        _currentOrderId = 0;
    }

    function createOrder(
        uint256 deadline,
        address tokenIn,
        address[] memory tokenOutList,
        uint256[] memory amountInList,
        uint256[] memory amountOutMinimumList
    ) external {
        require(tokenOutList.length > 0, "Length=0");
        require(tokenOutList.length == amountInList.length, "Different length");
        require(tokenOutList.length == amountOutMinimumList.length, "Different length");
        require(deadline < _maxDeadline, "Incorrect deadline");
        _requireNonZeroAddress(tokenIn);
        _requireNonZeroAddressList(tokenOutList);

        _currentOrderId++;
        _userOrders[msg.sender].push(_currentOrderId);

        uint256 total = tokenOutList.length;

        for (uint256 i = 0; i < total; ++i) {
            _items.push(SwapTokensPair(msg.sender, tokenIn, tokenOutList[i], amountInList[i], amountOutMinimumList[i], SWAP_PENDING, block.timestamp + deadline, 0, 0, block.timestamp, _currentOrderId));
            _orderItemIndexes[_currentOrderId].push(_items.length - 1);
        }

        emit OrderCreated(msg.sender, _currentOrderId);
    }

    function swap(uint256 index, uint24[] memory poolFeeList, address[] memory intermediateTokenOutList) external {
        require(index < getItemsLength(), "Index isn't correct");
        require(poolFeeList.length > 0, "Fee list is empty");
        require(poolFeeList.length - 1 == intermediateTokenOutList.length, "Different length");
        _requireNonZeroAddressList(intermediateTokenOutList);

        SwapTokensPair storage _swapTokensPair = _items[index];
        require(_swapTokensPair._status == SWAP_PENDING, "Already processed");

        _swapTokensPair._status = SWAP_IN_PROGRESS;

        if (block.timestamp > _swapTokensPair._deadline) {
            _swapTokensPair._status = SWAP_EXPIRED;
        } else {
            TransferHelper.safeTransferFrom(_swapTokensPair._tokenIn, _swapTokensPair._owner, address(this), _swapTokensPair._amountIn);

            _swapTokensPair._amountInReal = (_swapTokensPair._amountIn * (BASE - _fee)) / BASE;

            TransferHelper.safeApprove(_swapTokensPair._tokenIn, address(_swapRouter), _swapTokensPair._amountInReal);

            _swapTokensPair._amountOutReal = _swap(_swapTokensPair, poolFeeList, intermediateTokenOutList);

            if (_swapTokensPair._amountOutReal > 0) {
                _swapTokensPair._status = SWAP_SUCCESS;
            } else {
                _swapTokensPair._status = SWAP_FAIL;
            }

            _setSwapFee(index, poolFeeList);
            _setSwapIntermediateTokens(index, intermediateTokenOutList);
        }

        emit SwapProcessed(_swapTokensPair._owner, index, _swapTokensPair._status, _swapTokensPair._tokenIn, _swapTokensPair._tokenOut, _swapTokensPair._amountInReal, _swapTokensPair._amountOutReal);
    }

    function getTotalUserOrders(address account) public view returns (uint256) {
        return _userOrders[account].length;
    }

    function getUserOrderIdByIndex(address account, uint256 index) external view returns (uint256) {
        require(index < getTotalUserOrders(account), "Index isn't correct");
        return _userOrders[account][index];
    }

    function getTotalOrderItems(uint256 orderId) public view returns (uint256) {
        return _orderItemIndexes[orderId].length;
    }

    function getOrderItemByIndex(uint256 orderId, uint256 index) external view returns (SwapTokensPair memory) {
        require(index < getTotalOrderItems(orderId), "Index isn't correct");
        return getItem(_orderItemIndexes[orderId][index]);
    }

    function getOrderItemIndex(uint256 orderId, uint256 index) external view returns (uint256) {
        require(index < getTotalOrderItems(orderId), "Index isn't correct");
        return _orderItemIndexes[orderId][index];
    }

    function getItemsLength() public view returns (uint256) {
        return _items.length;
    }

    function getItem(uint256 index) public view returns(SwapTokensPair memory) {
        require(index < getItemsLength(), "Index isn't correct");
        return _items[index];
    }

    function getItemSwapFeeListLength(uint256 index) public view returns (uint256) {
        require(index < getItemsLength(), "Index isn't correct");
        return _itemSwapFeeInfo[index].length;
    }

    function getItemFeeByIndex(uint256 itemId, uint256 index) external view returns (uint24) {
        require(itemId < getItemsLength(), "Index isn't correct");
        require(index < getItemSwapFeeListLength(itemId), "Index isn't correct");

        return _itemSwapFeeInfo[itemId][index];
    }

    function getItemIntermediateTokenOutListLength(uint256 index) public view returns (uint256) {
        require(index < getItemsLength(), "Index isn't correct");
        return _itemSwapIntermediateTokenOut[index].length;
    }

    function getItemIntermediateTokenOutByIndex(uint256 itemId, uint256 index) external view returns (address) {
        require(itemId < getItemsLength(), "Index isn't correct");
        require(index < getItemIntermediateTokenOutListLength(itemId), "Index isn't correct");

        return _itemSwapIntermediateTokenOut[itemId][index];
    }

    function getFee() external view returns (uint256) {
        return _fee;
    }

    function setFee(uint256 fee) external onlyOwner {
        require(fee < BASE, "Fee>BASE");

        _fee = fee;
        emit ChangeFee(fee);
    }

    function getMaxDeadline() external view returns (uint256) {
        return _maxDeadline;
    }

    function setMaxDeadline(uint256 maxDeadline) external onlyOwner {
        _maxDeadline = maxDeadline;
        emit ChangeMaxDeadline(maxDeadline);
    }

    function _setSwapFee(uint256 index, uint24[] memory poolFeeList) internal {
        uint256 total = poolFeeList.length;

        for (uint256 i = 0; i < total; ++i) {
            _itemSwapFeeInfo[index].push(poolFeeList[i]);
        }
    }

    function _setSwapIntermediateTokens(uint256 index, address[] memory intermediateTokenOutList) internal {
        uint256 total = intermediateTokenOutList.length;

        for (uint256 i = 0; i < total; ++i) {
            _itemSwapIntermediateTokenOut[index].push(intermediateTokenOutList[i]);
        }
    }

    function _requireNonZeroAddressList(address[] memory accountList) internal view virtual {
        uint256 total = accountList.length;

        for (uint256 i = 0; i < total; ++i) {
            _requireNonZeroAddress(accountList[i]);
        }
    }

    function _requireNonZeroAddress(address account) internal view virtual {
        require(account != address(0), "Zero address");
    }

    function _swap(
        SwapTokensPair storage _swapTokensPair,
        uint24[] memory poolFeeList,
        address[] memory intermediateTokenOutList
    ) internal returns (uint256) {
        if (poolFeeList.length > 1) {
            bytes memory path = abi.encodePacked(_swapTokensPair._tokenIn);

            for (uint256 j = 0; j < intermediateTokenOutList.length; j++) {
                path = abi.encodePacked(path, poolFeeList[j], intermediateTokenOutList[j]);
            }

            path = abi.encodePacked(path, poolFeeList[poolFeeList.length - 1], _swapTokensPair._tokenOut);

            ISwapRouter.ExactInputParams memory exactInputParams =
            ISwapRouter.ExactInputParams({
                path: path,
                recipient: _swapTokensPair._owner,
                deadline: block.timestamp,
                amountIn: _swapTokensPair._amountInReal,
                amountOutMinimum: _swapTokensPair._amountOutMinimum
            });

            try _swapRouter.exactInput(exactInputParams) returns (uint256 amountOut) {
                return amountOut;
            } catch {
                return 0;
            }
        }

        ISwapRouter.ExactInputSingleParams memory exactInputSingleParams =
        ISwapRouter.ExactInputSingleParams({
            tokenIn : _swapTokensPair._tokenIn,
            tokenOut : _swapTokensPair._tokenOut,
            fee : poolFeeList[0],
            recipient : _swapTokensPair._owner,
            deadline : block.timestamp,
            amountIn : _swapTokensPair._amountInReal,
            amountOutMinimum : _swapTokensPair._amountOutMinimum,
            sqrtPriceLimitX96 : 0
        });

        try _swapRouter.exactInputSingle(exactInputSingleParams) returns (uint256 amountOut) {
            return amountOut;
        } catch {
            return 0;
        }
    }
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

import '../open-zeppelin/IERC20.sol';

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "./Ownable.sol";
import './open-zeppelin/IERC20.sol';

abstract contract ERC20Transfer is Ownable {
    function withdraw(address erc20Address) external onlyOwner {
        IERC20 token = IERC20(erc20Address);

        token.transfer(owner(), token.balanceOf(address(this)));
    }
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
pragma solidity 0.8.7;

/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
    * @return the address of the owner.
  */
    function owner() public view returns(address) {
        return _owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
  */
    modifier onlyOwner() {
        require(isOwner(), 'Not owner');
        _;
    }

    /**
    * @return true if `msg.sender` is the owner of the contract.
  */
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

    /**
    * @dev Allows the current owner to relinquish control of the contract.
  * @notice Renouncing to ownership will leave the contract without an owner.
  * It will not be possible to call the functions with the `onlyOwner`
  * modifier anymore.
  */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}