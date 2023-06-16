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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

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

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;
}

interface IStargateReceiver {
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external payable;
}

interface IInvestor {
    function deposit(
        address account,
        address token,
        uint256 tokenAmt,
        uint256 nftId
    ) external;
}

contract TestBridge is IStargateReceiver {
    address public immutable sgRouter;

    address public immutable investor;

    constructor(address _sgRouter, address _investor) {
        sgRouter = _sgRouter;
        investor = _investor;
    }

    function sgReceive(
        uint16,
        bytes memory,
        uint256,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external payable override {
        (address sender, uint256 nftId) = abi.decode(
            payload,
            (address, uint256)
        );

        IERC20(_token).approve(investor, amountLD);
        IInvestor(investor).deposit(sender, _token, amountLD, nftId);
    }

    function sendRequest(
        uint16 _dstChainId,
        uint256 _dstPoolId,
        uint256 _srcPoolId,
        uint256 _tokenAmt,
        address _token,
        IStargateRouter.lzTxObj calldata _params,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable {
        IERC20(_token).transferFrom(msg.sender, address(this), _tokenAmt);

        IERC20(_token).approve(sgRouter, _tokenAmt);
        IStargateRouter(sgRouter).swap{value: msg.value}(
            _dstChainId,
            _srcPoolId, // 1 => USDC
            _dstPoolId,
            payable(msg.sender),
            _tokenAmt,
            0,
            _params,
            _to,
            _payload
        );
    }
}