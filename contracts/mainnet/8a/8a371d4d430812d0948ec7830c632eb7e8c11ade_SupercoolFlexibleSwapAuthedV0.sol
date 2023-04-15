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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnershipTransferred(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function transferOwnership(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Auth, Authority} from "../Auth.sol";

/// @notice Role based Authority that supports up to 256 roles.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/authorities/RolesAuthority.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-roles/blob/master/src/roles.sol)
contract RolesAuthority is Auth, Authority {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);

    event PublicCapabilityUpdated(address indexed target, bytes4 indexed functionSig, bool enabled);

    event RoleCapabilityUpdated(uint8 indexed role, address indexed target, bytes4 indexed functionSig, bool enabled);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*//////////////////////////////////////////////////////////////
                            ROLE/USER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => bytes32) public getUserRoles;

    mapping(address => mapping(bytes4 => bool)) public isCapabilityPublic;

    mapping(address => mapping(bytes4 => bytes32)) public getRolesWithCapability;

    function doesUserHaveRole(address user, uint8 role) public view virtual returns (bool) {
        return (uint256(getUserRoles[user]) >> role) & 1 != 0;
    }

    function doesRoleHaveCapability(
        uint8 role,
        address target,
        bytes4 functionSig
    ) public view virtual returns (bool) {
        return (uint256(getRolesWithCapability[target][functionSig]) >> role) & 1 != 0;
    }

    /*//////////////////////////////////////////////////////////////
                           AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) public view virtual override returns (bool) {
        return
            isCapabilityPublic[target][functionSig] ||
            bytes32(0) != getUserRoles[user] & getRolesWithCapability[target][functionSig];
    }

    /*//////////////////////////////////////////////////////////////
                   ROLE CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setPublicCapability(
        address target,
        bytes4 functionSig,
        bool enabled
    ) public virtual requiresAuth {
        isCapabilityPublic[target][functionSig] = enabled;

        emit PublicCapabilityUpdated(target, functionSig, enabled);
    }

    function setRoleCapability(
        uint8 role,
        address target,
        bytes4 functionSig,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getRolesWithCapability[target][functionSig] |= bytes32(1 << role);
        } else {
            getRolesWithCapability[target][functionSig] &= ~bytes32(1 << role);
        }

        emit RoleCapabilityUpdated(role, target, functionSig, enabled);
    }

    /*//////////////////////////////////////////////////////////////
                       USER ROLE ASSIGNMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function setUserRole(
        address user,
        uint8 role,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getUserRoles[user] |= bytes32(1 << role);
        } else {
            getUserRoles[user] &= ~bytes32(1 << role);
        }

        emit UserRoleUpdated(user, role, enabled);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "solmate/auth/authorities/RolesAuthority.sol";

contract SupercoolFlexibleSwapV0 is ReentrancyGuard {
    ISwapRouter public immutable swapRouter;
    // This should be WETH or WMATIC or something like that
    INativeWrapper public immutable nativeWrapper;

    constructor(address _routerAddress, address _nativeWrapper) {
        // These addresses can be taken from https://docs.uniswap.org/contracts/v3/reference/deployments
        swapRouter = ISwapRouter(_routerAddress);
        nativeWrapper = INativeWrapper(_nativeWrapper);
    }

    /// @notice swapExactOutputSingle swaps a minimum possible amount of SOURCE ERC-20 for a fixed amount of DESTINATION ERC-20.
    /// @dev The calling address must approve this contract to spend its SOURCE token for this function to succeed. As the amount of input SOURCE is variable,
    /// the calling address will need to approve for a slightly higher amount, anticipating some variance.
    /// @param amountOut The exact amount of DESTINATION token to receive from the swap.
    /// @param amountInMaximum The amount of SOURCE token we are willing to spend to receive the specified amount of DESTINATION.
    /// @param poolFee The pool tier for Uniswap swaps
    /// @param source The source ERC-20 contract address
    /// @param destination The destination ERC-20 contract address
    /// @param fromAddress The owner from which we take `source` tokens for swapping
    /// @param sqrtPriceLimitX96 Limit for the price the swap will push the pool to. Zero makes it inactive.
    function swapExactOutputSingle(
        uint256 amountOut,
        uint256 amountInMaximum,
        uint24 poolFee,
        address source,
        address destination,
        address fromAddress,
        address recipient,
        uint160 sqrtPriceLimitX96
    ) public virtual returns (uint256 amountIn) {
        // Transfer SOURCE token amount into this contract from the fromAddress
        TransferHelper.safeTransferFrom(source, fromAddress, address(this), amountInMaximum);
        amountIn = _swapExactOutput(
            amountOut,
            amountInMaximum,
            poolFee,
            source,
            destination,
            recipient,
            sqrtPriceLimitX96
        );
        if (amountIn < amountInMaximum) {
            // Transfer remainder of SOURCE tokens to the sender
            TransferHelper.safeTransfer(source, fromAddress, amountInMaximum - amountIn);
        }
        return amountIn;
    }

    function swapExactOutputSingle(
        uint256 amountOut,
        uint256 amountInMaximum,
        uint24 poolFee,
        address source,
        address destination,
        address fromAddress,
        address recipient
    ) public virtual returns (uint256 amountIn) {
        return
            swapExactOutputSingle(
                amountOut,
                amountInMaximum,
                poolFee,
                source,
                destination,
                fromAddress,
                recipient,
                0
            );
    }

    // Every swap gets routed through here, so this is the only place where we
    // need a reentrancy guard.
    function _swapExactOutput(
        uint256 amountOut,
        uint256 amountInMaximum,
        uint24 poolFee,
        address source,
        address destination,
        address recipient,
        uint160 sqrtPriceLimitX96
    ) internal nonReentrant returns (uint256 amountIn) {
        // Approve the router to spend SOURCE tokens
        TransferHelper.safeApprove(source, address(swapRouter), amountInMaximum);

        // Formulate swap request.
        // Field definitions can be found here: https://docs.uniswap.org/contracts/v3/guides/swaps/single-swaps
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            // The contract address of the inbound token
            tokenIn: source,
            // The contract address of the outbound token
            tokenOut: destination,
            // This is the fee that the protocol takes
            fee: poolFee,
            // The contract that receives DESTINATION token. In this case it will be this contract.
            recipient: recipient,
            // Unix timestamp after which the swap will fail (Safety mechanism for long-pending transactions)
            deadline: block.timestamp,
            // The amount of `tokenOut` to swap to.
            amountOut: amountOut,
            // The maximum amount of `tokenIn` the contract will willing to spend to receive `tokenOut`
            // IMPORTANT: In production use the SDK to quote the correct price
            amountInMaximum: amountInMaximum,
            // Limit for the price the swap will push the pool to. Zero makes it inactive.
            // IMPORTANT: In production using this field can help protect against price impact
            // Uniswap docs recommend using an Oracle here to determine this value.
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });

        // This swaps SOURCE tokens to DESTINATION tokens, but caps the transfer to the `tokenOut` amount. Whatever is left gets refunded
        amountIn = swapRouter.exactOutputSingle(params);

        // For exact output swaps, the amountInMaximum may not have been spent
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund
        if (amountIn < amountInMaximum) {
            // Revoke approval privileges for SOURCE ERC-20 from swapRouter
            TransferHelper.safeApprove(source, address(swapRouter), 0);
        }
        return amountIn;
    }

    function swapExactOutputFromNative(
        uint256 amountOut,
        uint256 amountInMaximum,
        uint24 poolFee,
        address destination,
        address recipient,
        uint160 sqrtPriceLimitX96
    ) public payable virtual returns (uint256 amountIn) {
        nativeWrapper.deposit{value: msg.value}();
        amountIn = _swapExactOutput(
            amountOut,
            amountInMaximum,
            poolFee,
            address(nativeWrapper),
            destination,
            recipient,
            sqrtPriceLimitX96
        );
        if (amountIn < amountInMaximum) {
            nativeWrapper.withdraw(amountInMaximum - amountIn);
            _transfer(payable(msg.sender), amountInMaximum - amountIn);
        }
        return amountIn;
    }

    function swapExactOutputFromNative(
        uint256 amountOut,
        uint256 amountInMaximum,
        uint24 poolFee,
        address destination,
        address recipient
    ) public payable virtual returns (uint256 amountIn) {
        // TODO does the payable work here when we call the overloaded function?
        return
            swapExactOutputFromNative(
                amountOut,
                amountInMaximum,
                poolFee,
                destination,
                recipient,
                0
            );
    }

    function swapExactOutputToNative(
        uint256 amountOut,
        uint256 amountInMaximum,
        uint24 poolFee,
        address source,
        address fromAddress,
        address payable recipient,
        uint160 sqrtPriceLimitX96
    ) public virtual returns (uint256 amountIn) {
        amountIn = swapExactOutputSingle(
            amountOut,
            amountInMaximum,
            poolFee,
            source,
            address(nativeWrapper),
            fromAddress,
            address(this),
            sqrtPriceLimitX96
        );
        nativeWrapper.withdraw(amountOut);
        _transfer(recipient, amountOut);
        return amountIn;
    }

    function swapExactOutputToNative(
        uint256 amountOut,
        uint256 amountInMaximum,
        uint24 poolFee,
        address source,
        address fromAddress,
        address payable recipient
    ) public virtual returns (uint256 amountIn) {
        return
            swapExactOutputToNative(
                amountOut,
                amountInMaximum,
                poolFee,
                source,
                fromAddress,
                recipient,
                0
            );
    }

    // We need to use a `.call` to transfer ETH because when we use `transfer`
    // it only forwards a fixed amount of gas. This breaks Gnosis Safe, for
    // example. This `.call` forwards all gas. Because of this, we must be
    // careful for reentrancy attacks.
    function _transfer(address payable recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH");
    }

    // Necessary so that we can receive Ether to this contract
    receive() external payable {}
}

contract SupercoolFlexibleSwapAuthedV0 is SupercoolFlexibleSwapV0, RolesAuthority {
    uint8 public immutable SWAPPER_ROLE = 0;

    constructor(
        address _routerAddress,
        address _nativeWrapper,
        address _owner
    )
        SupercoolFlexibleSwapV0(_routerAddress, _nativeWrapper)
        // We make ourselves the Authority
        RolesAuthority(_owner, Authority(address(this)))
    {}

    function swapExactOutputSingle(
        uint256 amountOut,
        uint256 amountInMaximum,
        uint24 poolFee,
        address source,
        address destination,
        address fromAddress,
        address recipient
    ) public override requiresAuth returns (uint256) {
        return
            super.swapExactOutputSingle(
                amountOut,
                amountInMaximum,
                poolFee,
                source,
                destination,
                fromAddress,
                recipient
            );
    }

    function swapExactOutputSingle(
        uint256 amountOut,
        uint256 amountInMaximum,
        uint24 poolFee,
        address source,
        address destination,
        address fromAddress,
        address recipient,
        uint160 sqrtPriceLimitX96
    ) public override requiresAuth returns (uint256) {
        return
            super.swapExactOutputSingle(
                amountOut,
                amountInMaximum,
                poolFee,
                source,
                destination,
                fromAddress,
                recipient,
                sqrtPriceLimitX96
            );
    }

    function swapExactOutputFromNative(
        uint256 amountOut,
        uint256 amountInMaximum,
        uint24 poolFee,
        address destination,
        address recipient,
        uint160 sqrtPriceLimitX96
    ) public payable override requiresAuth returns (uint256 amountIn) {
        return
            super.swapExactOutputFromNative(
                amountOut,
                amountInMaximum,
                poolFee,
                destination,
                recipient,
                sqrtPriceLimitX96
            );
    }

    function swapExactOutputFromNative(
        uint256 amountOut,
        uint256 amountInMaximum,
        uint24 poolFee,
        address destination,
        address recipient
    ) public payable override requiresAuth returns (uint256 amountIn) {
        return
            super.swapExactOutputFromNative(
                amountOut,
                amountInMaximum,
                poolFee,
                destination,
                recipient
            );
    }

    function swapExactOutputToNative(
        uint256 amountOut,
        uint256 amountInMaximum,
        uint24 poolFee,
        address source,
        address fromAddress,
        address payable recipient,
        uint160 sqrtPriceLimitX96
    ) public override requiresAuth returns (uint256 amountIn) {
        return
            super.swapExactOutputToNative(
                amountOut,
                amountInMaximum,
                poolFee,
                source,
                fromAddress,
                recipient,
                sqrtPriceLimitX96
            );
    }

    function swapExactOutputToNative(
        uint256 amountOut,
        uint256 amountInMaximum,
        uint24 poolFee,
        address source,
        address fromAddress,
        address payable recipient
    ) public override requiresAuth returns (uint256 amountIn) {
        return
            super.swapExactOutputToNative(
                amountOut,
                amountInMaximum,
                poolFee,
                source,
                fromAddress,
                recipient
            );
    }
}

library SwapperAuth {
    bytes4 constant swapExactOutputSingleNoPriceLimit =
        bytes4(
            keccak256(
                "swapExactOutputSingle(uint256,uint256,uint24,address,address,address,address)"
            )
        );
    bytes4 constant swapExactOutputSinglePriceLimit =
        bytes4(
            keccak256(
                "swapExactOutputSingle(uint256,uint256,uint24,address,address,address,address,uint160)"
            )
        );

    bytes4 constant swapExactOutputFromNativePriceLimit =
        bytes4(
            keccak256("swapExactOutputFromNative(uint256,uint256,uint24,address,address,uint160)")
        );

    bytes4 constant swapExactOutputFromNativeNoPriceLimit =
        bytes4(keccak256("swapExactOutputFromNative(uint256,uint256,uint24,address,address)"));

    bytes4 constant swapExactOutputToNativeNoPriceLimit =
        bytes4(
            keccak256("swapExactOutputToNative(uint256,uint256,uint24,address,address,address)")
        );

    bytes4 constant swapExactOutputToNativePriceLimit =
        bytes4(
            keccak256(
                "swapExactOutputToNative(uint256,uint256,uint24,address,address,address,uint160)"
            )
        );

    function setSwapperCapabilities(SupercoolFlexibleSwapAuthedV0 swapper) internal {
        swapper.setRoleCapability(
            swapper.SWAPPER_ROLE(),
            address(swapper),
            swapExactOutputSingleNoPriceLimit,
            true
        );
        swapper.setRoleCapability(
            swapper.SWAPPER_ROLE(),
            address(swapper),
            swapExactOutputSinglePriceLimit,
            true
        );

        swapper.setRoleCapability(
            swapper.SWAPPER_ROLE(),
            address(swapper),
            swapExactOutputFromNativePriceLimit,
            true
        );
        swapper.setRoleCapability(
            swapper.SWAPPER_ROLE(),
            address(swapper),
            swapExactOutputFromNativeNoPriceLimit,
            true
        );

        swapper.setRoleCapability(
            swapper.SWAPPER_ROLE(),
            address(swapper),
            swapExactOutputToNativePriceLimit,
            true
        );
        swapper.setRoleCapability(
            swapper.SWAPPER_ROLE(),
            address(swapper),
            swapExactOutputToNativeNoPriceLimit,
            true
        );
    }
}

interface INativeWrapper {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);

    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad) external returns (bool);
}