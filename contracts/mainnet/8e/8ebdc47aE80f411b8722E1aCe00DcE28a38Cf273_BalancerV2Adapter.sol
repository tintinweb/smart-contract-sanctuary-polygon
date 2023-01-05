// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "../../base/AdapterBase.sol";
import "../../../interfaces/balancer/v2/IVault.sol";
import "../../../interfaces/balancer/v2/IAsset.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BalancerV2Adapter is AdapterBase, ReentrancyGuard {
    address public constant vaultAddr =
        0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "BalancerV2Adapter")
    {}

    event BalancerSingleSwap(
        address account,
        IVault.SingleSwap singleSwapParam,
        IVault.FundManagement funds,
        uint256 limit
    );

    event BalancerBatchSwap(
        address account,
        uint8 kind,
        IVault.BatchSwapStep[],
        address[] assets,
        int256[] limits
    );

    function batchSwap(address account, bytes calldata encodedData)
        external
        payable
        nonReentrant
        onlyAdapterManager
    {
        (
            uint8 kind, //0:in  1:out
            IVault.BatchSwapStep[] memory swaps,
            address[] memory assets,
            int256[] memory limits
        ) = abi.decode(
                encodedData,
                (uint8, IVault.BatchSwapStep[], address[], int256[])
            );

        IVault.FundManagement memory funds = IVault.FundManagement(
            address(this),
            false,
            payable(account),
            false
        );

        // zero address means MATIC in balancer
        if (assets[0] != maticAddr && assets[0] != address(0)) {
            require(msg.value == 0, "invalid msgValue");
            uint256 tokenBeforePull = IERC20(assets[0]).balanceOf(address(this));
            pullAndApprove(assets[0], account, vaultAddr, uint256(limits[0]));
            uint256 tokenBeforeSwap = IERC20(assets[0]).balanceOf(address(this));
            if(tokenBeforeSwap - tokenBeforePull < uint256(limits[0]))
                limits[0] = int256(tokenBeforeSwap - tokenBeforePull);
            IVault(vaultAddr).batchSwap(
                kind,
                swaps,
                assets,
                funds,
                limits,
                block.timestamp
            );
            uint256 tokenAfterSwap = IERC20(assets[0]).balanceOf(address(this));
            if(tokenBeforeSwap - tokenAfterSwap < uint256(limits[0]))
                returnAsset(assets[0], account, uint256(limits[0]) + tokenAfterSwap - tokenBeforeSwap);
                
        } else {
            require(
                msg.value == uint256(limits[0]),
                "BalancerV2: AmountIn and msgValue mismatch."
            );
            uint256 maticBefore = address(this).balance;
            IVault(vaultAddr).batchSwap{value: msg.value}(
                kind,
                swaps,
                assets,
                funds,
                limits,
                block.timestamp
            );
            uint256 maticAfter = address(this).balance;
            if(maticBefore - maticAfter < msg.value)
                returnAsset(maticAddr, account, msg.value + maticAfter - maticBefore);
        }

        emit BalancerBatchSwap(account, kind, swaps, assets, limits);
    }

    function singleSwap(address account, bytes calldata encodedData)
        external
        payable
        nonReentrant
        onlyAdapterManager
    {
        (
            IVault.SingleSwap memory singleSwapParam,
            uint256[] memory limits
        ) = abi.decode(encodedData, (IVault.SingleSwap, uint256[]));

        require(limits.length == 2, "BalancerV2: Wrong length of limits.");
        uint256 limit = singleSwapParam.kind == IVault.SwapKind.GIVEN_IN
            ? limits[1]
            : limits[0];

        IVault.FundManagement memory funds = IVault.FundManagement(
            address(this),
            false,
            payable(account),
            false
        );

        if (
            singleSwapParam.assetIn != IAsset(maticAddr) &&
            singleSwapParam.assetIn != IAsset(address(0)) //matic address in balancer is 0x0
        ) {
            require(msg.value == 0, "invalid msgValue");
            uint256 tokenBeforePull = IERC20(address(singleSwapParam.assetIn)).balanceOf(address(this));
            pullAndApprove(
                address(singleSwapParam.assetIn),
                account,
                vaultAddr,
                limits[0]
            );
            uint256 tokenBeforeSwap = IERC20(address(singleSwapParam.assetIn)).balanceOf(address(this));
            if(tokenBeforeSwap - tokenBeforePull < limits[0])
                limits[0] = tokenBeforeSwap - tokenBeforePull;
            IVault(vaultAddr).swap(
                singleSwapParam,
                funds,
                limit,
                block.timestamp
            );
            uint256 tokenAfterSwap = IERC20(address(singleSwapParam.assetIn)).balanceOf(address(this));
            if(tokenBeforeSwap - tokenAfterSwap < limits[0])
                returnAsset(address(singleSwapParam.assetIn), account, limits[0] + tokenAfterSwap - tokenBeforeSwap);
        } else {
            require(
                msg.value == limits[0],
                "BalancerV2: AmountIn and msgValue mismatch."
            );
            uint256 maticBefore = address(this).balance;
            IVault(vaultAddr).swap{value: msg.value}(
                singleSwapParam,
                funds,
                limit,
                block.timestamp
            );
            uint256 maticAfter = address(this).balance;
            if(maticBefore - maticAfter < msg.value)
                returnAsset(maticAddr, account, msg.value + maticAfter - maticBefore);
        }

        emit BalancerSingleSwap(account, singleSwapParam, funds, limit);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../timelock/TimelockCallable.sol";
import "../../common/Basic.sol";

abstract contract AdapterBase is Basic, Ownable, TimelockCallable {
    using SafeERC20 for IERC20;

    address public ADAPTER_MANAGER;
    address public immutable ADAPTER_ADDRESS;
    string public ADAPTER_NAME;
    mapping(address => mapping(address => bool)) private approved;

    receive() external payable {}

    modifier onlyAdapterManager() {
        require(
            ADAPTER_MANAGER == msg.sender,
            "Caller is not the adapterManager."
        );
        _;
    }

    modifier onlyDelegation() {
        require(ADAPTER_ADDRESS != address(this), "Only for delegatecall.");
        _;
    }

    constructor(
        address _adapterManager,
        address _timelock,
        string memory _name
    ) TimelockCallable(_timelock) {
        ADAPTER_MANAGER = _adapterManager;
        ADAPTER_ADDRESS = address(this);
        ADAPTER_NAME = _name;
    }

    function pullTokensIfNeeded(
        address _token,
        address _from,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;
        require(_token != address(0) && _token != maticAddr);
        uint256 balance = IERC20(_token).balanceOf(_from);
        uint256 currentAmount = balance < _amount ? balance : _amount;
        IERC20(_token).safeTransferFrom(_from, address(this), currentAmount);
    }

    function approveToken(
        address _token,
        address _spender,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;
        if (!approved[_token][_spender]) {
            IERC20 token = IERC20(_token);
            token.safeApprove(_spender, 0);
            token.safeApprove(_spender, type(uint256).max);
            approved[_token][_spender] = true;
        }
    }

    /// @dev get the token from sender, and approve to the user in one step
    function pullAndApprove(
        address _token,
        address _from,
        address _spender,
        uint256 _amount
    ) internal {
        pullTokensIfNeeded(_token, _from, _amount);
        approveToken(_token, _spender, _amount);
    }

    function returnAsset(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            if (_token == maticAddr) {
                safeTransferMATIC(_to, _amount);
            } else {
                require(_token != address(0), "Token error!");
                IERC20(_token).safeTransfer(_to, _amount);
            }
        }
    }

    function toCallback(
        address _target,
        bytes4 _selector,
        bytes memory _callData
    ) internal {
        (bool success, bytes memory returnData) = _target.call(
            abi.encodePacked(_selector, _callData)
        );
        require(success, string(returnData));
    }

    //Handle when someone else accidentally transfers assets to this contract
    function sweep(address[] memory tokens, address receiver)
        external
        onlyTimelock
    {
        require(address(this) == ADAPTER_ADDRESS, "!Invalid call");
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == address(0)) continue;
            uint256 amount = IERC20(token).balanceOf(address(this));
            if (amount > 0) {
                IERC20(token).safeTransfer(receiver, amount);
            }
        }

        uint256 balance = address(this).balance;
        if (balance > 0) {
            safeTransferMATIC(receiver, balance);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IFlashLoanRecipient.sol";
import "./IProtocolFeesCollector.sol";
import "./IAsset.sol";

interface IVault is IFlashLoanRecipient {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    enum PoolBalanceChangeKind {
        JOIN,
        EXIT
    }

    enum PoolBalanceOpKind {
        WITHDRAW,
        DEPOSIT,
        UPDATE
    }

    enum UserBalanceOpKind {
        DEPOSIT_INTERNAL,
        WITHDRAW_INTERNAL,
        TRANSFER_INTERNAL,
        TRANSFER_EXTERNAL
    }

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    function WETH() external view returns (address);

    function batchSwap(
        uint8 kind,
        BatchSwapStep[] calldata swaps,
        address[] calldata assets,
        FundManagement calldata funds,
        int256[] calldata limits,
        uint256 deadline
    ) external payable returns (int256[] memory assetDeltas);

    function deregisterTokens(bytes32 poolId, address[] calldata tokens)
        external;

    function exitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        ExitPoolRequest calldata request
    ) external;

    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    function getActionId(bytes4 selector) external view returns (bytes32);

    function getAuthorizer() external view returns (address);

    function getDomainSeparator() external view returns (bytes32);

    function getInternalBalance(address user, address[] calldata tokens)
        external
        view
        returns (uint256[] memory balances);

    function getNextNonce(address user) external view returns (uint256);

    function getPausedState()
        external
        view
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        );

    function getPool(bytes32 poolId) external view returns (address, uint8);

    function getPoolTokenInfo(bytes32 poolId, address token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function getProtocolFeesCollector() external view returns (address);

    function hasApprovedRelayer(address user, address relayer)
        external
        view
        returns (bool);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest calldata request
    ) external;

    function managePoolBalance(PoolBalanceOp[] calldata ops) external;

    function manageUserBalance(UserBalanceOp[] calldata ops) external;

    function queryBatchSwap(
        uint8 kind,
        BatchSwapStep[] calldata swaps,
        address[] calldata assets,
        FundManagement calldata funds
    ) external returns (int256[] memory);

    function registerPool(uint8 specialization) external returns (bytes32);

    function registerTokens(
        bytes32 poolId,
        address[] calldata tokens,
        address[] calldata assetManagers
    ) external;

    function setAuthorizer(address newAuthorizer) external;

    function setPaused(bool paused) external;

    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external;

    function swap(
        SingleSwap calldata singleSwap,
        FundManagement calldata funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256 amountCalculated);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

abstract contract TimelockCallable {
    address public TIMELOCK_ADDRESS;

    event SetTimeLock(address newTimelock);

    constructor(address _timelock) {
        TIMELOCK_ADDRESS = _timelock;
    }

    modifier onlyTimelock() {
        require(TIMELOCK_ADDRESS == msg.sender, "Caller is not the timelock.");
        _;
    }

    function setTimelock(address newTimelock) external onlyTimelock {
        require(newTimelock != address(0));
        TIMELOCK_ADDRESS = newTimelock;
        emit SetTimeLock(newTimelock);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

abstract contract Basic {
    /// @dev Return MATIC address
    address public constant maticAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Return Wrapped MATIC address
    address public constant wmaticAddr =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    function safeTransferMATIC(address to, uint256 value) internal {
        if (value != 0) {
            (bool success, ) = to.call{value: value}(new bytes(0));
            require(
                success,
                "helper::safeTransferMATIC: MATIC transfer failed"
            );
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

interface IProtocolFeesCollector {
    function getFlashLoanFeePercentage() external view returns (uint256);
}