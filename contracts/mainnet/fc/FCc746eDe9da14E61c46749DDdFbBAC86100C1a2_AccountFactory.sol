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

import { ByteHasher } from "./libraries/ByteHasher.sol";
import { IAccount, UserOperationVariant } from "./interfaces/IAccount.sol";
import { IQuickSwapV3Router } from "./dependencies/IQuickSwapV3Router.sol";
import { IWorldIDRouter } from "./interfaces/IWorldIDRouter.sol";
import { WorldIDVerification } from "./interfaces/WorldIDVerification.sol";

contract Account is IAccount {
    using ByteHasher for bytes;

    event AccountCreated(address addr);

    address public immutable wETH;
    address public immutable worldIDRouter;

    constructor(address _wETH, address _worldIDRouter) {
        wETH = _wETH;
        worldIDRouter = _worldIDRouter;

        emit AccountCreated(address(this));
    }

    receive() external payable {}

    function validateUserOp(
        UserOperationVariant calldata op
    ) external returns (uint256 validationData) {}

    function verify(
        WorldIDVerification calldata verif
    ) external returns (bool) {
        uint256 signalHash = abi.encodePacked(verif.signal).hashToField();
        uint256 appIDHash = abi.encodePacked(verif.appID).hashToField();
        uint256 externalNullifierHash = abi
            .encodePacked(appIDHash, verif.actionID)
            .hashToField();

        try
            IWorldIDRouter(worldIDRouter).verifyProof(
                verif.root,
                verif.group, // `0` for phone and `1` for orb.
                signalHash,
                verif.nullifierHash,
                externalNullifierHash,
                verif.proof
            )
        {} catch {
            revert("Account: invalid WorldIDVerification");
        }

        return true;
    }

    function exactInputSingle(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address tokenOut
    ) external payable returns (uint256 amountOut) {
        if (tokenIn != wETH) {
            IERC20(tokenIn).approve(router, amountIn);
        }

        IQuickSwapV3Router.ExactInputSingleParams
            memory params = IQuickSwapV3Router.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                limitSqrtPrice: 0
            });

        if (tokenIn != wETH) {
            amountOut = IQuickSwapV3Router(router).exactInputSingle(params);
        } else {
            amountOut = IQuickSwapV3Router(router).exactInputSingle{
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
    address public immutable worldIDRouter;

    constructor(address _wETH, address _worldIDRouter) {
        wETH = _wETH;
        worldIDRouter = _worldIDRouter;
    }

    function createAccount() external returns (address account) {
        account = address(new Account(wETH, worldIDRouter));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

interface IQuickSwapV3Router {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 limitSqrtPrice;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import { UserOperationVariant } from "./UserOperationVariant.sol";
import { WorldIDVerification } from "./WorldIDVerification.sol";

interface IAccount {
    struct CommitmentProof {
        bytes commitment;
        bytes proof;
    }

    function validateUserOp(
        UserOperationVariant calldata userOp
    ) external returns (uint256 validationData);

    function verify(
        WorldIDVerification calldata worldIDVerification
    ) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

interface IAccountFactory {
    function createAccount() external returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

interface IWorldIDRouter {
    function verifyProof(
        uint256 groupId,
        uint256 root,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifierHash,
        uint256[8] calldata proof
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import { WorldIDVerification } from "./WorldIDVerification.sol";

struct UserOperationVariant {
    address sender;
    WorldIDVerification worldIDVerification;
    bytes callData;
    uint256 callGasLimit;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

struct WorldIDVerification {
    uint256 root;
    uint256 group;
    string signal;
    uint256 nullifierHash;
    string appID;
    string actionID;
    uint256[8] proof;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library ByteHasher {
    function hashToField(bytes memory value) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(value))) >> 8;
    }
}