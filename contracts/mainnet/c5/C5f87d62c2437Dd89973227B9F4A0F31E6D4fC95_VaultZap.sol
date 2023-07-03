// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
pragma solidity 0.8.19;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/Balancer/IBalancerRouter.sol";

interface IWMATIC is IERC20 {
    function deposit() external payable;
}

interface ICVAULT {
    function createStake(
        address lockTokenAddress,
        uint256 lockTokenAmount,
        uint256 vaultxAmount,
        uint256 secondsInTerm,
        address recipient
    ) external returns (uint256);

    function vaultXMinimum() external view returns (uint256);

    function vaultXMaximum() external view returns (uint256);
}

contract VaultZap is Ownable {
    address public swapRouterAddress;
    address public cVaultAddress;
    address public vaultXTokenAddress;
    address public treasury;
    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    uint8 public minVaultXRatio = 50;
    uint8 public maxVaultXRatio = 100;

    event LogSwapExecution(
        uint256 amountIn,
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    );

    event SwapRouterUpdated(address newSwapRouterAddress);
    event VaultXTokenUpdated(address newVaultXTokenAddress);
    event CVaultUpdated(address newCVaultAddress);

    constructor(
        address _swapRouter,
        address _cVaultAddress,
        address _vaultXtokenAddress,
        address _treasury
    ) {
        swapRouterAddress = _swapRouter;
        cVaultAddress = _cVaultAddress;
        vaultXTokenAddress = _vaultXtokenAddress;
        treasury = _treasury;
    }

    /// @notice Calls the swap, and then creates a CryptoVault
    /// @dev internally swaps the native token to WMATIC and then swaps it for lockToken and vaultxToken in a 50/50 ratio
    /// @param vaultXRatio The ratio of the vaultx to the second lock token
    /// @param lockTokenAddress The address selected lock token
    /// @param poolId1 The poolId of the balancer pool for the locked token swap
    /// @param poolId2 The poolId of the balancer pool for the vaultX swap
    /// @param secondsInTerm The amount of seconds for which the vault will be locked
    /// @param minAmountOut1 The minimum amount of lockToken to receive
    /// @param minAmountOut2 The minimum amount of vaultxToken to receive
    /// @return amountOut0 The amount of STMATIC received for swapping WMATIC
    /// @return amountOut1 The amount of DAI received for swapping WMATIC
    /// @return tokenId The tokenId of the newly created vault NFT
    function zapStake(
        uint8 vaultXRatio,
        address lockTokenAddress,
        bytes32 poolId1,
        bytes32 poolId2,
        uint256 secondsInTerm,
        uint256 minAmountOut1,
        uint256 minAmountOut2
    ) external payable returns (uint256, uint256, uint256 tokenId) {
        require(msg.value > 0, "Insufficient MATIC amount");
        require(
            vaultXRatio >= minVaultXRatio && vaultXRatio <= maxVaultXRatio,
            "Invalid vaultX ratio"
        );

        IWMATIC(WMATIC).deposit{value: msg.value}();

        // Calculate 0.3% Swap fee
        uint256 feeAmount = (msg.value * 3) / 1000;
        uint256 amountAfterFee = msg.value - feeAmount;

        TransferHelper.safeTransfer(WMATIC, treasury, feeAmount);

        uint256 wMaticToVaultXAmount = (amountAfterFee * vaultXRatio) / 100;
        uint256 wMaticToLockedTokenAmount = amountAfterFee -
            wMaticToVaultXAmount;

        TransferHelper.safeApprove(WMATIC, swapRouterAddress, amountAfterFee);

        uint256 lockTokenAmount = 0;
        if (lockTokenAddress != address(0) && vaultXRatio < 100) {
            lockTokenAmount = swapSingleHop(
                wMaticToLockedTokenAmount,
                lockTokenAddress,
                poolId1,
                minAmountOut1
            );

            // approve the vault to spend the locked token
            TransferHelper.safeApprove(
                lockTokenAddress,
                cVaultAddress,
                lockTokenAmount
            );
        }

        uint256 vaultXAmount = swapSingleHop(
            wMaticToVaultXAmount,
            vaultXTokenAddress,
            poolId2,
            minAmountOut2
        );

        vaultXAmount = verifyMaximum(vaultXAmount);

        // approve the vault to spend the vaultX token
        TransferHelper.safeApprove(
            vaultXTokenAddress,
            cVaultAddress,
            vaultXAmount
        );

        return (
            lockTokenAmount,
            vaultXAmount,
            ICVAULT(cVaultAddress).createStake(
                lockTokenAddress,
                lockTokenAmount,
                vaultXAmount,
                secondsInTerm,
                msg.sender
            )
        );
    }

    /// @notice Performs a multihop swap to zap into a vault
    function zapStakeMultiHop(
        uint8 vaultXRatio,
        address lockTokenAddress,
        bytes32 vaultxPoolId,
        uint256 secondsInTerm,
        uint256 vaultxMinAmountOut,
        BatchSwapStep[] memory swapSteps,
        IAsset[] memory assets,
        int256[] memory limits
    ) external payable returns (uint256 tokenId) {
        require(msg.value > 0, "Insufficient MATIC amount");
        require(
            vaultXRatio >= minVaultXRatio && vaultXRatio <= maxVaultXRatio,
            "Invalid vaultX ratio"
        );

        IWMATIC(WMATIC).deposit{value: msg.value}();

        // Calculate 0.3% Swap fee
        uint256 feeAmount = (msg.value * 3) / 1000;
        uint256 amountAfterFee = msg.value - feeAmount;

        TransferHelper.safeTransfer(WMATIC, treasury, feeAmount);

        uint256 wMaticToVaultXAmount = (amountAfterFee * vaultXRatio) / 100;
        uint256 wMaticToLockedTokenAmount = amountAfterFee -
            wMaticToVaultXAmount;

        TransferHelper.safeApprove(WMATIC, swapRouterAddress, amountAfterFee);

        uint256 vaultXAmount = swapSingleHop(
            wMaticToVaultXAmount,
            vaultXTokenAddress,
            vaultxPoolId,
            vaultxMinAmountOut
        );

        vaultXAmount = verifyMaximum(vaultXAmount);

        uint256 lockTokenAmount = 0;
        if (vaultXRatio < 100) {
            // set the initial amount in the first swap step
            swapSteps[0].amount = wMaticToLockedTokenAmount;
            lockTokenAmount = swapMultiHop(
                swapSteps,
                assets,
                limits,
                block.timestamp + 300
            );
            // approve the vault to spend the locked token
            TransferHelper.safeApprove(
                lockTokenAddress,
                cVaultAddress,
                lockTokenAmount
            );
        }

        // approve the vault to spend the vaultX token
        TransferHelper.safeApprove(
            vaultXTokenAddress,
            cVaultAddress,
            vaultXAmount
        );

        return (
            ICVAULT(cVaultAddress).createStake(
                lockTokenAddress,
                lockTokenAmount,
                vaultXAmount,
                secondsInTerm,
                msg.sender
            )
        );
    }

    function swapMultiHop(
        BatchSwapStep[] memory swapSteps,
        IAsset[] memory assets,
        int256[] memory limits,
        uint256 deadline
    ) private returns (uint256 amountOut) {
        FundManagement memory funds = FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        int256[] memory amountsOut = IBalancerRouter(swapRouterAddress)
            .batchSwap(
                SwapKind.GIVEN_IN,
                swapSteps,
                assets,
                funds,
                limits,
                deadline
            );

        // return the last amountOut
        return abs(amountsOut[amountsOut.length - 1]);
    }

    /// @notice Wraps the native token to WMATIC and swaps it for lockToken and vaultxToken in a 50/50 ratio
    /// @return amountOut The amount of tokens received for swapping WMATIC
    function swapSingleHop(
        uint256 amount,
        address tokenAddress,
        bytes32 poolId,
        uint256 minAmountOut
    ) private returns (uint256 amountOut) {
        SingleSwap memory tokenSwap = SingleSwap({
            poolId: poolId,
            kind: SwapKind.GIVEN_IN,
            assetIn: IAsset(WMATIC),
            assetOut: IAsset(tokenAddress),
            amount: amount,
            userData: ""
        });

        FundManagement memory funds = FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        amountOut = IBalancerRouter(swapRouterAddress).swap(
            tokenSwap,
            funds,
            minAmountOut,
            block.timestamp + 300
        );
    }

    /// @notice Updates the min and max vaultX ratio
    /// @param _minVaultXRatio The new min vaultX ratio
    /// @param _maxVaultXRatio The new max vaultX ratio
    function updateVaultXRatio(
        uint8 _minVaultXRatio,
        uint8 _maxVaultXRatio
    ) external onlyOwner {
        require(
            _minVaultXRatio < _maxVaultXRatio,
            "Invalid vaultX ratio range"
        );
        minVaultXRatio = _minVaultXRatio;
        maxVaultXRatio = _maxVaultXRatio;
    }

    /// @notice Updates the swap router address
    /// @param _swapRouterAddress The address of the new swap router
    function updateSwapRouter(address _swapRouterAddress) external onlyOwner {
        swapRouterAddress = _swapRouterAddress;
        emit SwapRouterUpdated(_swapRouterAddress);
    }

    /// @notice Updates the vaultX token address
    /// @param _vaultXtokenAddress The address of the new vaultX token
    function updateVaultXToken(address _vaultXtokenAddress) external onlyOwner {
        vaultXTokenAddress = _vaultXtokenAddress;
        emit VaultXTokenUpdated(_vaultXtokenAddress);
    }

    /// @notice Updates the CryptoVault address
    /// @param _cVaultAddress The address of the new CryptoVault
    function updateCVault(address _cVaultAddress) external onlyOwner {
        cVaultAddress = _cVaultAddress;
        emit CVaultUpdated(_cVaultAddress);
    }

    /// @notice Updates the treasury address
    /// @param _treasury The address of the new treasury
    function updateTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function abs(int256 num) internal pure returns (uint256) {
        if (num < 0) {
            return uint256(num * -1);
        }
        return uint256(num);
    }

    function verifyMaximum(uint256 vaultXAmount) internal returns (uint256) {
        // Due to the limitation in the vault the amount out for vaultX must be between the min and max specified in the vault contract
        // if the the amount is higher than the max send the difference to the owner
        uint256 vaultXMaximum = ICVAULT(cVaultAddress).vaultXMaximum();
        if (vaultXAmount > vaultXMaximum) {
            uint256 difference = vaultXAmount - vaultXMaximum;
            TransferHelper.safeTransfer(
                vaultXTokenAddress,
                msg.sender,
                difference
            );
        }
        return vaultXAmount > vaultXMaximum ? vaultXMaximum : vaultXAmount;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.19;

struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
}

interface IAsset {}
enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
}

struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    IAsset assetIn;
    IAsset assetOut;
    uint256 amount;
    bytes userData;
}

struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
}

interface IBalancerRouter {
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);
}