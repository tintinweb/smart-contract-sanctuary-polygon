pragma solidity 0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '../interfaces/IPool.sol';
import '../interfaces/IPoolStorage.sol';
import '../libraries/KedrLib.sol';
import '../pools/Pool.sol';
import './PoolStorage.sol';

contract Factory is Ownable, ReentrancyGuard {
    address public defaultFeeReceiver; // default feeReceiver is used during each deployment of poolStorage
    address public swapper;
    address[] public pools;
    address[] public poolStorages;

    event PoolCreated(address _address, uint256 _id);
    event PoolStorageCreated(address _address, uint256 _id);

    constructor(address _defaultFeeReceiver, address _swapper) {
        require(_defaultFeeReceiver != address(0) && _swapper != address(0), 'ZERO_ADDRESS');
        defaultFeeReceiver = _defaultFeeReceiver;
        swapper = _swapper;
    }

    function poolsCount() external view returns (uint256) {
        return pools.length;
    }

    function poolsStorageCount() external view returns (uint256) {
        return poolStorages.length;
    }

    /**
     * The main function for Pool Creation. Creates new Pool & PoolStorage and link each other.
     */
    function create(IPool.PoolDetails memory poolDetails, address _entryAsset)
        external
        onlyOwner
        returns (address pool, address poolStorage)
    {
        poolStorage = _createPoolStorage(_entryAsset);
        pool = createPool(poolDetails, swapper);
        _link(pool, poolStorage);
    }

    /**
     * This function is used to switch on new Pool
     * IMPORTANT: It's going to move all funds from old Pool to the new one.
     */
    function switchStorageToNewPool(address _newPool, address _poolStorage) external onlyOwner {
        address oldPool = IPoolStorage(_poolStorage).pool();
        IPool(oldPool).moveFunds(_newPool);
        IPool(oldPool).unlink();
        IPool(_newPool).link(_poolStorage);
        IPoolStorage(_poolStorage).link(_newPool);
    }

    /**
     * Creates new Pool without linking to storage
     */
    function createPool(IPool.PoolDetails memory poolDetails, address _swapper) public returns (address pool) {
        uint256 poolId = pools.length + 1;
        bytes memory poolBytecode = abi.encodePacked(type(Pool).creationCode, abi.encode(poolId, _swapper));
        pool = KedrLib.deploy(poolBytecode);
        IPool(pool).initialize(poolDetails);
        pools.push(pool);
        emit PoolCreated(pool, poolId);
    }

    /**
     * Creates new PoolStorage without linking to Pool
     */
    function _createPoolStorage(address _entryAsset) internal returns (address poolStorage) {
        uint256 id = poolStorages.length + 1;
        string memory entrySymbol = IERC20Metadata(_entryAsset).symbol();
        bytes memory symbol = abi.encodePacked('k', entrySymbol);
        bytes memory name = abi.encodePacked('KEDR_', entrySymbol);
        bytes memory storageBytecode = abi.encodePacked(type(PoolStorage).creationCode, abi.encode(id, _entryAsset, defaultFeeReceiver, symbol, name));
        poolStorage = KedrLib.deploy(storageBytecode);
        poolStorages.push(poolStorage);
        emit PoolStorageCreated(poolStorage, id);
    }

    /**
     * Links pool and poolStorage.
     */
    function _link(address _pool, address _poolStorage) internal {
        IPoolStorage(_poolStorage).link(_pool);
        IPool(_pool).link(_poolStorage);
    }

    // ADMIN SETTERS:

    function setDefaultFeeReceiver(address _receiver) external onlyOwner {
        require(_receiver != address(0), 'ZERO_ADDRESS');
        defaultFeeReceiver = _receiver;
    }

    function setFeeReceiver(address _poolStorage, address _receiver) external onlyOwner {
        IPoolStorage(_poolStorage).setFeeReceiver(_receiver);
    }

    function updateAllocations(address _pool, uint24[] memory _weights) external onlyOwner {
        IPool(_pool).updateAllocations(_weights);
    }

    function setWeight(address _pool, address asset, uint24 weight) external onlyOwner {
        IPool(_pool).setWeight(asset, weight);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

    function totalValue() external returns (uint256);

    function entryAsset() external view returns (address);

    function factory() external view returns (address);

    function poolStorage() external view returns (address);

    function poolId() external view returns (uint64);

    function invest(address investor, uint256 amount) external payable;

    function withdraw(uint256 amount) external;

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

    function calculateShares(uint256 entryAmount) external returns (uint256);

    function calculateSharesBySpecificPrice(uint256 entryAmount, uint256 sharePrice) external returns (uint256);

    function calculateEntryAmount(uint256 shares) external returns (uint256);

    function calculateEntryAmountBySpeicificPrice(uint256 shares, uint256 sharePrice) external returns (uint256);

    function recordInvestment(address investor, uint256 shares, uint256 sharePrice, uint256 amountInvested, uint256 entryFee, uint256 swapFeesLoss) external;

    function recordWithdrawal(address investor, uint256 shares, uint256 sharePrice, uint256 withdrawAmount, uint256 successFee, uint256 swapFeesLoss) external;

    function totalReceivedEntryAssetAmount() external view returns (uint256);

    function totalEntryFeeCollected() external view returns (uint256);

    function totalSuccessFeeAmountCollected() external view returns (uint256);

    function feeReceiver() external returns (address);

    function setFeeReceiver(address feeReceiver) external;
    
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
        uint256 entryFee = (amount * poolDetails.entryFee) / KedrConstants._FEE_DENOMINATOR;
        uint256 invested = amount - entryFee;
        uint256 sharePrice = PoolStorage.sharePrice();
        uint256 totalValueBefore = totalValue();

        KedrLib.uniTransferFrom(entryAsset, msg.sender, address(this), amount);

        // transfer fee from user to feeReceiver
        address feeReceiver = PoolStorage.feeReceiver();
        if (entryFee > 0) {
            KedrLib.uniTransfer(entryAsset, feeReceiver, entryFee);
        }

        address[] memory assets = poolDetails.assets;
        uint24[] memory weights = poolDetails.weights;

        if (!isNative) {
            TransferHelper.safeApprove(entryAsset, address(Swapper), invested);
        } else {
            TransferHelper.safeTransferETH(address(Swapper), invested);
        }

        for (uint256 i; i < assets.length; ++i) {
            if (assets[i] != entryAsset) {
                uint256 entryAmount = (invested * weights[i]) / weightsSum;
                uint256 currentBalance = _assetBalance(entryAsset);
                uint256 adjustedAmount = currentBalance < entryAmount ? currentBalance : entryAmount;
                require(Swapper.swap(entryAsset, assets[i], adjustedAmount, address(this)) != 0, "NO_TOKENS_RECEIVED");
            }
        }

        uint256 valueAdded = totalValue() - totalValueBefore; // we need to use "valueAdded" instead "invested" to exclude swap fee losses from calculating
        uint256 shares = PoolStorage.calculateSharesBySpecificPrice(valueAdded, sharePrice);
        PoolStorage.recordInvestment(
            investor,
            shares,
            sharePrice,
            invested,
            entryFee,
            invested - valueAdded
        );
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

    function _sellToExactAmount(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut
    ) internal returns (uint256 received) {
        uint256 amountIn = Swapper.getAmountIn(_tokenIn, _tokenOut, _amountOut);
        require(_assetBalance(_tokenIn) >= amountIn, 'INSUFFIENT_FUNDS');
        TransferHelper.safeApprove(_tokenIn, address(Swapper), amountIn);
        received = Swapper.swap(_tokenIn, _tokenOut, amountIn, address(this));
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

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../libraries/KedrConstants.sol';
import '../interfaces/IPoolStorage.sol';
import '../interfaces/IPool.sol';

contract PoolStorage is ERC20 {
    using SafeMath for uint256;

    address public factory;
    address public pool;
    uint256 public poolStorageId;
    address public feeReceiver;
    address public entryAsset;
    uint256 public totalSuccessFeeCollected = 0;
    uint256 public totalEntryFeeCollected = 0;
    uint256 public totalReceivedEntryAsset = 0;
    uint256 public totalWithdrawnEntryAsset = 0;
    uint256 public totalSwapFeesLoss = 0;
    uint256 internal constant NUMERATOR = 1e18;
    IPool internal Pool;

    event Withdrawal(address indexed user, address indexed entryAsset, uint256 shares, uint256 sharePrice, uint256 amountReceived, uint256 successFee, uint256 swapFeesLoss);
    event Investment(address indexed user, address indexed entryAsset, uint256 shares, uint256 sharePrice, uint256 amountInvested, uint256 entryFee, uint256 swapFeesLoss);

    modifier onlyFactory() {
        require(msg.sender == factory, 'CALLER_IS_NOT_FACTORY');
        _;
    }

    modifier onlyPool() {
        require(msg.sender == pool, 'CALLER_IS_NOT_POOL');
        _;
    }

    constructor(
        uint256 _poolStorageId,
        address _entryAsset,
        address _feeReceiver,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        poolStorageId = _poolStorageId;
        require(_feeReceiver != address(0) && _entryAsset != address(0), 'ZERO_ADDRESS');
        factory = msg.sender;
        feeReceiver = _feeReceiver;
        entryAsset = _entryAsset;
    }

    function link(address _pool) external onlyFactory {
        require(_pool != address(0), 'ZERO_ADDRESS');
        pool = _pool;
        Pool = IPool(_pool);
    }
 
    function recordInvestment(address _investor, uint256 _shares, uint256 _sharePrice, uint256 _amount, uint256 _entryFee, uint256 _swapFeesLoss) external onlyPool {
        require(_shares > 0, "ZERO_SHARES_AMOUNT");
        _mint(_investor, _shares);
        totalReceivedEntryAsset += _amount;
        totalEntryFeeCollected += _entryFee;
        totalSwapFeesLoss += _swapFeesLoss;
        emit Investment(_investor, entryAsset, _shares, _sharePrice, _amount, _entryFee, _swapFeesLoss);
    }

    function recordWithdrawal(address _investor, uint256 _shares, uint256 _sharePrice, uint256 _withdrawAmount, uint256 _successFee, uint256 _swapFeesLoss) external onlyPool {
        require(_withdrawAmount > 0, "ZERO_WITHDRAW_AMOUNT");
        _burn(_investor, _shares);
        totalWithdrawnEntryAsset += _withdrawAmount;
        totalSuccessFeeCollected += _successFee;
        totalSwapFeesLoss += _swapFeesLoss;
        emit Withdrawal(_investor, entryAsset, _shares, _sharePrice, _withdrawAmount, _successFee, _swapFeesLoss);
    }

    function setFeeReceiver(address _feeReceiver) external onlyFactory {
        require(_feeReceiver != address(0), 'ZERO_ADDRESS');
        feeReceiver = _feeReceiver;
    }

    function sharePrice() public returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            return NUMERATOR; // initial price
        }
        uint256 totalValue = Pool.totalValue();
        return totalValue * NUMERATOR / _totalSupply; // check: maybe need to add multiplier here, not sure
    }

    function calculateShares(uint256 _entryAmount) public returns (uint256) {
        return _entryAmount * NUMERATOR / sharePrice();
    }

    function calculateSharesBySpecificPrice(uint256 _entryAmount, uint256 _sharePrice) public pure returns (uint256) {
        return _entryAmount * NUMERATOR / _sharePrice;
    }

    function calculateEntryAmount(uint256 _shares) public returns (uint256) {
        return _shares * sharePrice() / NUMERATOR;
    }

    function calculateEntryAmountBySpeicificPrice(uint256 _shares, uint256 _sharePrice) public returns (uint256) {
        return _shares * _sharePrice / NUMERATOR;
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

    function totalValue() public override returns (uint256 _totalValue) {
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

    function _assetBalance(address _asset) internal view returns (uint256) {
        return _asset == address(0) ? address(this).balance : IERC20(_asset).balanceOf(address(this));
    }

    function _calcualteSuccessFee(uint256 _amount) internal view returns(uint256) {
        return (_amount  * poolDetails.successFee) / KedrConstants._FEE_DENOMINATOR;
    }

    function _weightsSum(uint24[] memory weights) internal pure returns (uint24 sum) {
        for (uint256 i; i < weights.length; ++i) {
            sum += weights[i];
        }
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

library KedrConstants {
    uint16 internal constant _FEE_DENOMINATOR = 10000;
    uint16 internal constant _DEFAULT_FEE_NUMERATOR = 10000; // 0% fee by default
    uint16 internal constant _MAX_ENTRY_FEE = 1000; // 10%
    uint16 internal constant _MAX_SUCCESS_FEE = 500; // 5%

    uint8 internal constant _ROUTER_TYPE_BALANCER = 1; 
    uint8 internal constant _ROUTER_TYPE_V2 = 2;
    uint8 internal constant _ROUTER_TYPE_V3 = 3;

    uint8 internal constant _INACCURACY = 5; // max permissible innacuracy in the calculation of swaps
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

interface ISwapper {
    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        address _recipient
    ) external returns (uint256);

    function getAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) external returns (uint256);

    function getAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}