//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import '../base/BasePool.sol';

contract Pool is BasePool {
    constructor(uint64 _poolId, address _swapper) BasePool(_poolId, _swapper) {}

    /**
     * Invest entry asset and get kTokens
     */
    function invest(address investor, uint256 amount) public payable override {
        address entryAsset = PoolStorage.entryAsset();
        bool isNative = KedrLib.isNative(entryAsset);
        require(amount >= poolDetails.minInvestment, 'TOO_SMALL_INVESTMENT');
        uint256 totalValueBefore;
        if (isNative) {
            amount = msg.value;
            totalValueBefore = totalValue() - amount; // we deduct amount because msg.value already included in pool balance
        } else {
            totalValueBefore = totalValue();
        }
        uint256 entryFee = (amount * poolDetails.entryFee) / KedrConstants._FEE_DENOMINATOR;
        uint256 invested = amount - entryFee;
        uint256 sharePrice = PoolStorage.calculateSharePrice(totalValueBefore);
        address feeReceiver = PoolStorage.feeReceiver();

        if (!isNative) {
            TransferHelper.safeTransferFrom(entryAsset, msg.sender, address(this), invested);
            if (entryFee > 0) {
                TransferHelper.safeTransferFrom(entryAsset, msg.sender, feeReceiver, entryFee);
            }
            TransferHelper.safeApprove(entryAsset, address(Swapper), invested);
        } else {
            if (entryFee > 0) {
                TransferHelper.safeTransferETH(feeReceiver, entryFee);
            }
            //TransferHelper.safeTransferETH(address(Swapper), invested/2);
        }

        address[] memory assets = poolDetails.assets;
        uint24[] memory weights = poolDetails.weights;

        for (uint256 i; i < assets.length; ++i) {
            if (assets[i] != entryAsset) {
                uint256 entryAmount = (invested * weights[i]) / weightsSum;
                uint256 currentBalance = _assetBalance(entryAsset);
                uint256 adjustedAmount = currentBalance < entryAmount ? currentBalance : entryAmount;
                if (isNative) {
                    require(Swapper.swap{value: adjustedAmount}(entryAsset, assets[i], adjustedAmount, address(this)) != 0, 'NO_TOKENS_RECEIVED');
                } else {
                    require(Swapper.swap(entryAsset, assets[i], adjustedAmount, address(this)) != 0, 'NO_TOKENS_RECEIVED');
                }
            }
        }

        uint256 valueAdded = totalValue() - totalValueBefore; // we need to use "valueAdded" instead "invested" to exclude swap fee losses from calculating
        uint256 shares = PoolStorage.calculateSharesBySpecificPrice(valueAdded, sharePrice);
        PoolStorage.recordInvestment(investor, shares, sharePrice, invested, entryFee, invested - valueAdded);
    }

    /**
     * Burn kTokens and get entry asset
     * @param _shares - amount of kTokens to be burned to exchange for entryAsset
     */
    function withdraw(uint256 _shares) public override {
        require(_shares > 0, 'ZERO_AMOUNT');
        address entryAsset = entryAsset(); // gas saving
        uint256 sharePrice = PoolStorage.sharePrice();
        uint256 withdrawAmount = PoolStorage.calculateEntryAmountBySpeicificPrice(_shares, sharePrice);
        address[] memory assets = poolDetails.assets;
        uint24[] memory weights = poolDetails.weights;
        uint256 totalReceived;
        uint256 totalValueBefore = totalValue();

        for (uint256 i; i < assets.length; ++i) {
            uint256 amountOut = (withdrawAmount * weights[i]) / weightsSum;
            if (assets[i] != entryAsset) {
                totalReceived += _sellToExactAmount(assets[i], entryAsset, amountOut);
            } else {
                totalReceived += amountOut;
            }
        }

        _checkInaccuracy(withdrawAmount, totalReceived);

        uint256 swapFeesLoss = totalValueBefore - totalValue();
        withdrawAmount = totalReceived - swapFeesLoss; // adjust withdraw amount by possible INACCURACY and deduct swapFee losses
        uint256 successFee = _calcualteSuccessFee(withdrawAmount);
        withdrawAmount = withdrawAmount - successFee; // deduct successFee, withdrawAmount is the amount user really received

        address feeReceiver = PoolStorage.feeReceiver();
        if (KedrLib.isNative(entryAsset)) {
            TransferHelper.safeTransferETH(msg.sender, withdrawAmount);
            TransferHelper.safeTransferETH(feeReceiver, successFee);
        } else {
            TransferHelper.safeTransfer(entryAsset, msg.sender, withdrawAmount);
            TransferHelper.safeTransfer(entryAsset, feeReceiver, successFee);
        }
        PoolStorage.recordWithdrawal(msg.sender, _shares, sharePrice, withdrawAmount, successFee, swapFeesLoss);
    }

    function withdrawAll() public override {
        uint256 shares = PoolStorage.balanceOf(msg.sender);
        withdraw(shares);
    }

    function _sellToExactAmount(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut
    ) internal returns (uint256 received) {
        uint256 amountIn = Swapper.getAmountIn(_tokenIn, _tokenOut, _amountOut);
        uint256 actualBalance = _assetBalance(_tokenIn);
        uint256 amount = actualBalance < amountIn ? actualBalance : amountIn;
        TransferHelper.safeApprove(_tokenIn, address(Swapper), amount);
        received = Swapper.swap(_tokenIn, _tokenOut, amount, address(this));
    }

    function _checkInaccuracy(uint256 expectedValue, uint256 realValue) internal pure {
        if (expectedValue > realValue) {
            require(expectedValue - realValue <= KedrConstants._INACCURACY, 'INCORRECT_OPERATION');
        } else {
            require(realValue - expectedValue <= KedrConstants._INACCURACY, 'INCORRECT_OPERATION');
        }
    }

    receive() external payable {}
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../interfaces/IPool.sol';
import '../interfaces/IPoolStorage.sol';
import '../libraries/KedrConstants.sol';
import '../libraries/KedrLib.sol';
import '../interfaces/ISwapper.sol';

abstract contract BasePool is IPool, ReentrancyGuard {
    uint64 public override poolId;
    address public override factory;
    address public override poolStorage;
    uint24 public weightsSum;
    PoolDetails public poolDetails;
    IPoolStorage internal PoolStorage;
    ISwapper internal Swapper;
    bool public balanceable;

    constructor(uint64 _poolId, address _swapper) {
        factory = msg.sender;
        poolId = _poolId;
        Swapper = ISwapper(_swapper);
    }

    modifier onlyFactory() {
        require(msg.sender == factory, 'CALLER_IS_NOT_FACTORY');
        _;
    }

    // called once by the factory at time of deployment
    function initialize(PoolDetails calldata _poolDetails) external override onlyFactory {
        require(_poolDetails.assets.length == _poolDetails.weights.length, 'INVALID_ALLOCATIONS');
        // todo: check assets for pair existence
        poolDetails = _poolDetails;
        balanceable = _poolDetails.balanceable;
        weightsSum = _weightsSum(_poolDetails.weights);
    }

    function link(address _poolStorage) external override onlyFactory {
        require(_poolStorage != address(0), 'ZERO_ADDRESS');
        poolStorage = _poolStorage;
        PoolStorage = IPoolStorage(_poolStorage);
    }

    // resets poolStorage to address(0), used only during Factory.switchStorageToNewPool function
    function unlink() external override onlyFactory {
        poolStorage = address(0);
        PoolStorage = IPoolStorage(address(0));
    }

    // Must be called only inside Factory.switchStorageToNewPool function
    function moveFunds(address _newPool) external override onlyFactory {
        require(_newPool != address(0), 'ZERO_ADDRESS');
        address[] memory poolAssets = poolDetails.assets; // gas savings
        for (uint256 i; i < poolAssets.length; ++i) {
            address token = poolAssets[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                TransferHelper.safeTransfer(token, _newPool, balance);
            }
        }
    }

    function totalValue() public override view returns (uint256 _totalValue) {
        address[] memory poolAssets = poolDetails.assets; // gas savings
        address _entryAsset = entryAsset(); // gas savings
        for (uint256 i; i < poolAssets.length; ++i) {
            address asset = poolAssets[i];
            uint256 assetBalance = _assetBalance(asset);
            if (assetBalance > 0 && asset != _entryAsset) {
                uint256 valueConverted = Swapper.getAmountOut(asset, _entryAsset, assetBalance);
                require(valueConverted > 0, 'ORACLE_ERROR');
                _totalValue += valueConverted;
            }
        }
        _totalValue += _assetBalance(_entryAsset); // additional counting entryAsset balance
    }

    function entryAsset() public view override returns (address) {
        return PoolStorage.entryAsset();
    }

    /**
     * @param _weight - can be zero. in this case asset is excluded from portfolio for some time
     */
    function setWeight(address _asset, uint24 _weight) external override onlyFactory {
        address[] memory assets = poolDetails.assets; // gas savings
        bool updated;
        for (uint256 i; i < assets.length; ++i) {
            if (assets[i] == _asset) {
                poolDetails.weights[i] = _weight;
                updated = true;
                break;
            }
        }
        require(updated == true, 'UNSUPPORTED_ASSET');
    }

    /**
     * @dev this function updates allocation weights for all assets
     */
    function updateAllocations(uint24[] memory _weights) external override onlyFactory {
        require(_weights.length == poolDetails.assets.length, 'WRONG_LENGTH');
        poolDetails.weights = _weights;
        weightsSum = _weightsSum(_weights);
    }

    function poolSize() external view override returns (uint256) {
        return poolDetails.assets.length;
    }

    function details() external view override returns (PoolDetails memory) {
        return poolDetails;
    }

    /**
     * @dev must be implemented in inherited classes
     */
    function invest(address _investor, uint256 _amount) public payable virtual override {}

    /**
     * @dev must be implemented in inherited classes
     */
    function withdraw(uint256 _amount) public virtual override {}

    /**
     * @dev must be implemented in inherited classes
     */
    function withdrawAll() public virtual override {}

    function _assetBalance(address _asset) internal view returns (uint256) {
        return _asset == address(0) ? address(this).balance : IERC20(_asset).balanceOf(address(this));
    }

    function _calcualteSuccessFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * poolDetails.successFee) / KedrConstants._FEE_DENOMINATOR;
    }

    function _weightsSum(uint24[] memory weights) internal pure returns (uint24 sum) {
        for (uint256 i; i < weights.length; ++i) {
            sum += weights[i];
        }
    }
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

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

interface IPool {
    struct PoolDetails {
        address swapper; //todo: setter for swapper
        uint256 minInvestment;
        address[] assets;
        uint24[] weights;
        uint16 entryFee;
        uint16 successFee;
        bool balanceable;
    }

    struct PoolStorageDetails {
        string name;
        string symbol;
        address entryAsset;
    }

    function initialize(PoolDetails calldata _poolDetails) external;

    function link(address _poolStorage) external;

    function unlink() external;

    function moveFunds(address _newPool) external;

    function totalValue() external view returns (uint256);

    function entryAsset() external view returns (address);

    function factory() external view returns (address);

    function poolStorage() external view returns (address);

    function poolId() external view returns (uint64);

    function invest(address investor, uint256 amount) external payable;

    function withdraw(uint256 amount) external;

    function withdrawAll() external;

    function setWeight(address asset, uint24 weight) external; // updates allocation for specific token in pool

    function updateAllocations(uint24[] memory weights) external; // updates allocations for all tokens in pool

    function details() external view returns (PoolDetails memory);

    function poolSize() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

interface IPoolStorage {
    function entryAsset() external view returns (address);

    function pool() external view returns (address);

    function poolStorageId() external view returns (uint256);

    function link(address pool) external;

    function sharePrice() external view returns (uint256);

    function calculateSharePrice(uint256 totalValue) external view returns (uint256);

    function calculateShares(uint256 entryAmount) external view returns (uint256);

    function calculateSharesBySpecificPrice(uint256 entryAmount, uint256 sharePrice) external view returns (uint256);

    function calculateEntryAmount(uint256 shares) external view returns (uint256);

    function calculateEntryAmountBySpeicificPrice(uint256 shares, uint256 sharePrice) external view returns (uint256);

    function recordInvestment(address investor, uint256 shares, uint256 sharePrice, uint256 amountInvested, uint256 entryFee, uint256 swapFeesLoss) external;

    function recordWithdrawal(address investor, uint256 shares, uint256 sharePrice, uint256 withdrawAmount, uint256 successFee, uint256 swapFeesLoss) external;

    function totalReceivedEntryAssetAmount() external view returns (uint256);

    function totalEntryFeeCollected() external view returns (uint256);

    function totalSuccessFeeAmountCollected() external view returns (uint256);

    function feeReceiver() external returns (address);

    function setFeeReceiver(address feeReceiver) external;

    function balanceOf(address account) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

library KedrConstants {
    uint16 internal constant _FEE_DENOMINATOR = 10000;
    uint16 internal constant _DEFAULT_FEE_NUMERATOR = 10000; // 0% fee by default
    uint16 internal constant _MAX_ENTRY_FEE = 1000; // 10%
    uint16 internal constant _MAX_SUCCESS_FEE = 500; // 5%
    uint16 internal constant _INACCURACY = 500; // max permissible innacuracy in the calculation of swaps

    uint8 internal constant _ROUTER_TYPE_BALANCER = 1;
    uint8 internal constant _ROUTER_TYPE_V2 = 2;
    uint8 internal constant _ROUTER_TYPE_V3 = 3;
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

library KedrLib {
    /**
     * @dev deploys new contract using create2 with check of deployment
     */
    function deploy(bytes memory bytecode) external returns (address _contract) {
        assembly {
            _contract := create2(0, add(bytecode, 32), mload(bytecode), '')
            if iszero(extcodesize(_contract)) {
                revert(0, 0)
            }
        }
        return _contract;
    }

    function isNative(address token) internal pure returns (bool) {
        return token == address(0);
    }

    function uniTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (isNative(token)) {
            TransferHelper.safeTransferETH(to, amount);
        } else {
            TransferHelper.safeTransferFrom(token, from, to, amount);
        }
    }

    function uniTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        if (isNative(token)) {
            TransferHelper.safeTransferETH(to, amount);
        } else {
            TransferHelper.safeTransfer(token, to, amount);
        }
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

interface ISwapper {
    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        address _recipient
    ) external payable returns (uint256);

    function getAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) external view returns (uint256);

    function getAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut
    ) external view returns (uint256);
}