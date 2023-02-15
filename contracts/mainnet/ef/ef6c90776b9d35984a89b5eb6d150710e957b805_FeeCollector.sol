/**
 *Submitted for verification at polygonscan.com on 2023-02-15
*/

/**
 *Submitted for verification at gnosisscan.io on 2023-02-14
*/

// Sources flattened with hardhat v2.12.0 https://hardhat.org

pragma solidity 0.8.7;

address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

interface I1InchAggregatorV5 {
    struct SwapDescription {
        address srcToken;
        address dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    function swap(
        address executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 gasLeft);
}

contract FeeCollector {
    
    address public oneInchAggregationRouter;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    constructor(address _oneInchAggregationRouter) {
        oneInchAggregationRouter = _oneInchAggregationRouter;
        owner = msg.sender;
    }

    function setAggregationRouterAddress(address _address) external onlyOwner {
        oneInchAggregationRouter = _address;
    }

    function swap(
        uint256 minOut,
        bytes calldata _data
    ) external onlyOwner {
        (
            address executor,
            I1InchAggregatorV5.SwapDescription memory description,
            bytes memory permit,
            bytes memory data
        ) = abi.decode(
                _data[4:],
                (address, I1InchAggregatorV5.SwapDescription, bytes, bytes)
            );

        bool isNative = address(description.srcToken) == NATIVE_TOKEN;

        if (!isNative) {
            IERC20(description.srcToken).approve(
                oneInchAggregationRouter,
                description.amount
            );
        }

        (uint256 returnAmount, ) = isNative
            ? I1InchAggregatorV5(oneInchAggregationRouter).swap{
                value: description.amount
            }(executor, description, permit, data)
            : I1InchAggregatorV5(oneInchAggregationRouter).swap(
                executor,
                description,
                permit,
                data
            );

        require(returnAmount >= minOut);
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
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