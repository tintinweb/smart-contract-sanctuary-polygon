// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interface/IPositions.sol";
import "./interface/IAsset.sol";
import "./interface/IShortStaking.sol";
import "./interface/IShortLock.sol";
import "./interface/IMint.sol";
import "./interface/IChainlinkAggregator.sol";
contract Auction is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Extended;

    // Using the struct to avoid Stack too deep error
    struct VarsInFuncs {
        uint256 assetPrice;
        uint8 assetPriceDecimals;
        uint256 collateralPrice;
        uint8 collateralPriceDecimals;
    }

    struct VarsInAuction {
        uint256 returnedCollateralAmount;
        uint256 refundedAssetAmount;
        uint256 liquidatedAssetAmount;
        uint256 leftAssetAmount;
        uint256 leftCAssetAmount;
        uint256 protocolFee_;
    }

    IPositions public positions;
    IAsset public asset;
    // 0 ~ 1000, fee = amount * feeRate / 1000.
    uint16 public feeRate;
    /// @notice token address => total fee amount
    mapping(address => uint256) public protocolFee;
    /// @notice Short staking contract address.
    IShortStaking public staking;
    /// @notice Short lock contract address.
    IShortLock public lock;
    // oracle max delay.
    uint256 public oracleMaxDelay;
    IMint public mint;

    /// @notice Triggered when auction.
    /// @param positionId The index of this position.
    /// @param assetAmount asset amount.
    event AuctionPosition(uint256 positionId, uint256 assetAmount);

    function initialize(
        IPositions _positions,
        IAsset _asset,
        uint16 _feeRate,
        IShortStaking _staking,
        IShortLock _lock
    ) external initializer {
        __Ownable_init();

        positions = _positions;
        asset = _asset;
        feeRate = _feeRate;
        staking = _staking;
        lock = _lock;
        oracleMaxDelay = 300;
    }

    /// @notice The position can be liquidited if the C-Ratio is less than the min C-Ratio.
    /// @notice During the liquidating, system will sell the collateral at a discounted price.
    /// @notice Everyone can buy it.
    /// @param positionId position id
    /// @param assetAmount nAsset amount
    function auction(uint256 positionId, uint256 assetAmount) public {
        Position memory position = positions.getPosition(positionId);
        require(position.assigned, "no such a position");
        require(
            (assetAmount > 0) && assetAmount <= position.assetAmount,
            "wrong amount"
        );

        AssetConfig memory assetConfig = asset.asset(
            address(position.assetToken)
        );
        require(!assetConfig.delisted, "wrong asset");

        CAssetConfig memory cAssetConfig = asset.cAsset(
            address(position.cAssetToken)
        );

        VarsInFuncs memory v = VarsInFuncs(0, 0, 0, 0);

        (v.assetPrice, v.assetPriceDecimals) = getPrice(
            assetConfig.token,
            false
        );
        (v.collateralPrice, v.collateralPriceDecimals) = getPrice(
            cAssetConfig.token,
            true
        );

        require(_checkPositionInAuction(position, v), "safe position");

        uint256 maxAssetAmount = _amountInAuction(
            assetConfig,
            cAssetConfig,
            position,
            v
        );

        VarsInAuction memory va = VarsInAuction(0, 0, 0, 0, 0, 0);
        va.liquidatedAssetAmount = min(assetAmount, maxAssetAmount);
        va.returnedCollateralAmount = _cAmountInAuction(
            assetConfig,
            cAssetConfig,
            v,
            va.liquidatedAssetAmount
        );

        va.leftAssetAmount = position.assetAmount - va.liquidatedAssetAmount;
        va.leftCAssetAmount =
            position.cAssetAmount -
            va.returnedCollateralAmount;

        bool closedPosition = false;

        if (va.leftCAssetAmount == 0) {
            closedPosition = true;
            mint.removePosition(positionId);
        } else if (va.leftAssetAmount == 0) {
            closedPosition = true;
            mint.removePosition(positionId);
            // refunds left collaterals to position owner
            position.cAssetToken.safeTransferFrom(
                address(mint),
                position.owner,
                va.leftCAssetAmount
            );
        } else {
            position.cAssetAmount = va.leftCAssetAmount;
            position.assetAmount = va.leftAssetAmount;
            mint.updatePosition(position);
        }

        position.assetToken.burnFrom(msg.sender, va.liquidatedAssetAmount);

        {
            uint256 aDecimalDivisor = 10**assetConfig.token.decimals();
            uint256 cDecimalDivisor = 10**cAssetConfig.token.decimals();
            uint256 aPriceDecimalDivisor = 10**v.assetPriceDecimals;
            uint256 cPriceDecimalDivisor = 10**v.collateralPriceDecimals;

            va.protocolFee_ =
                (va.liquidatedAssetAmount *
                    v.assetPrice *
                    feeRate *
                    cPriceDecimalDivisor *
                    cDecimalDivisor) /
                aDecimalDivisor /
                aPriceDecimalDivisor /
                v.collateralPrice /
                1000;
            protocolFee[address(position.cAssetToken)] += va.protocolFee_;
        }

        va.returnedCollateralAmount =
            va.returnedCollateralAmount -
            va.protocolFee_;
        position.cAssetToken.safeTransferFrom(
            address(mint),
            msg.sender,
            va.returnedCollateralAmount
        );

        emit AuctionPosition(positionId, va.liquidatedAssetAmount);

        if (position.isShort) {
            mint.withdrawStaking(
                assetConfig.poolId,
                va.liquidatedAssetAmount,
                position.owner
            );
            if (closedPosition) {
                mint.releaseLock(positionId);
            }
        }
    }

    /// @notice View function, can shows the max nAsset amount and collateral amount in an auction.
    /// @param positionId Index of a position.
    /// @return 1.max nAsset amount(can be burned)
    /// @return 2.max collateral amount(in auction)
    function amountInAuction(uint256 positionId)
        external
        view
        returns (uint256, uint256)
    {
        Position memory position = positions.getPosition(positionId);
        AssetConfig memory assetConfig = asset.asset(
            address(position.assetToken)
        );
        CAssetConfig memory cAssetConfig = asset.cAsset(
            address(position.cAssetToken)
        );

        if ((!position.assigned) || assetConfig.delisted) {
            return (0, 0);
        }

        VarsInFuncs memory v = VarsInFuncs(0, 0, 0, 0);

        (v.assetPrice, v.assetPriceDecimals) = getPrice(
            assetConfig.token,
            false
        );
        (v.collateralPrice, v.collateralPriceDecimals) = getPrice(
            cAssetConfig.token,
            true
        );

        if (_checkPositionInAuction(position, v) == false) {
            return (0, 0);
        }

        uint256 maxAssetAmount = _amountInAuction(
            assetConfig,
            cAssetConfig,
            position,
            v
        );

        uint256 returnedCAssetAmount = _cAmountInAuction(
            assetConfig,
            cAssetConfig,
            v,
            maxAssetAmount
        );

        return (maxAssetAmount, returnedCAssetAmount);
    }

    function _amountInAuction(
        AssetConfig memory assetConfig,
        CAssetConfig memory cAssetConfig,
        Position memory position,
        VarsInFuncs memory v
    ) private view returns (uint256 maxAssetAmount) {
        uint256 aDecimalDivisor = 10**assetConfig.token.decimals();
        uint256 cDecimalDivisor = 10**cAssetConfig.token.decimals();
        uint256 aPriceDecimalDivisor = 10**v.assetPriceDecimals;
        uint256 cPriceDecimalDivisor = 10**v.collateralPriceDecimals;

        uint256 curRatio = (position.cAssetAmount *
            v.collateralPrice *
            aDecimalDivisor *
            aPriceDecimalDivisor *
            100000) /
            cDecimalDivisor /
            cPriceDecimalDivisor /
            position.assetAmount /
            v.assetPrice;

        uint256 discountRatio = (1000 * 100000) / assetConfig.auctionDiscount;

        if (curRatio > discountRatio) {
            uint256 a = (position.assetAmount *
                v.assetPrice *
                assetConfig.targetRatio *
                10000) /
                1000 /
                aPriceDecimalDivisor /
                aDecimalDivisor;
            uint256 b = (position.cAssetAmount * 10000 * v.collateralPrice) /
                cPriceDecimalDivisor /
                cDecimalDivisor;
            uint256 c = (v.assetPrice * assetConfig.targetRatio * 10000) /
                1000 /
                aPriceDecimalDivisor;
            uint256 d = (v.assetPrice * 1000 * 10000) /
                aPriceDecimalDivisor /
                assetConfig.auctionDiscount;
            maxAssetAmount = ((a - b) * aDecimalDivisor) / (c - d);
        } else {
            maxAssetAmount =
                (position.cAssetAmount *
                    aPriceDecimalDivisor *
                    v.collateralPrice *
                    aDecimalDivisor *
                    assetConfig.auctionDiscount) /
                (v.assetPrice * cDecimalDivisor * cPriceDecimalDivisor * 1000);
        }
    }

    function _cAmountInAuction(
        AssetConfig memory assetConfig,
        CAssetConfig memory cAssetConfig,
        VarsInFuncs memory v,
        uint256 assetAmount
    ) private view returns (uint256 returnedCAssetAmount) {
        uint256 aDecimalDivisor = 10**assetConfig.token.decimals();
        uint256 cDecimalDivisor = 10**cAssetConfig.token.decimals();
        
        uint256 c = assetAmount *
            v.assetPrice *
            (10**v.collateralPriceDecimals) *
            cDecimalDivisor *
            1000;
        returnedCAssetAmount =
            c /
            (10**v.assetPriceDecimals) /
            v.collateralPrice /
            assetConfig.auctionDiscount /
            aDecimalDivisor;
    }

    /// @notice Query whether a certain position is in liquidation status
    /// @param positionId position id
    /// @return bool - is in liquidation status
    function isInAuction(uint256 positionId) external view returns (bool) {
        VarsInFuncs memory v = VarsInFuncs(0, 0, 0, 0);
        Position memory position = positions.getPosition(positionId);
        AssetConfig memory assetConfig = asset.asset(
            address(position.assetToken)
        );
        CAssetConfig memory cAssetConfig = asset.cAsset(
            address(position.cAssetToken)
        );

        if (!position.assigned) {
            return false;
        }

        (v.assetPrice, v.assetPriceDecimals) = getPrice(
            assetConfig.token,
            false
        );
        (v.collateralPrice, v.collateralPriceDecimals) = getPrice(
            cAssetConfig.token,
            true
        );

        return _checkPositionInAuction(position, v);
    }

    function getPrice(IERC20Extended token, bool isCollateral)
        public
        view
        returns (uint256, uint8)
    {
        IChainlinkAggregator oracle;
        if (isCollateral) {
            require(asset.cAsset(address(token)).assigned, "wrong collateral");
            if (address(asset.cAsset(address(token)).oracle) == address(0x0)) {
                // Stablecoin
                return (uint256(100000000), uint8(8));
            }
            if (
                asset.asset(address(token)).assigned &&
                asset.asset(address(token)).delisted
            ) {
                // It is collateral and nAssets, and it has been delisted
                return (
                    asset.asset(address(token)).endPrice,
                    asset.asset(address(token)).endPriceDecimals
                );
            }
            oracle = asset.cAsset(address(token)).oracle;
        } else {
            require(asset.asset(address(token)).assigned, "wrong asset");
            if (asset.asset(address(token)).delisted) {
                // delisted nAsset
                return (
                    asset.asset(address(token)).endPrice,
                    asset.asset(address(token)).endPriceDecimals
                );
            }
            oracle = asset.asset(address(token)).oracle;
        }

        (, int256 price, uint256 startedAt, , ) = oracle.latestRoundData();

        require(
            (block.timestamp - startedAt) < oracleMaxDelay,
            "Price expired."
        );
        require(price >= 0, "Price is incorrect.");

        uint8 decimals = oracle.decimals();

        return (uint256(price), decimals);
    }

    function _checkPositionInAuction(
        Position memory position,
        VarsInFuncs memory v
    ) private view returns (bool) {
        CAssetConfig memory cAssetConfig = asset.cAsset(
            address(position.cAssetToken)
        );
        AssetConfig memory assetConfig = asset.asset(
            address(position.assetToken)
        );
        uint256 assetValueInCollateral = (position.assetAmount *
            v.assetPrice *
            (10**v.collateralPriceDecimals) *
            (10**position.cAssetToken.decimals())) /
            (10**v.assetPriceDecimals) /
            v.collateralPrice /
            (10**position.assetToken.decimals());

        uint256 expectedAmount = ((assetValueInCollateral *
            assetConfig.minCRatio) / 1000) * cAssetConfig.multiplier;

        return (expectedAmount >= position.cAssetAmount);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function setMint(IMint _mint) external onlyOwner {
        mint = _mint;
    }

    function updateState(
        address positions_,
        address asset_,
        uint16 feeRate_,
        address staking_,
        address lock_,
        uint oracleMaxDelay_
    ) external {
        require(msg.sender == address(mint), "Only mint");
        positions = IPositions(positions_);
        asset = IAsset(asset_);
        feeRate = feeRate_;
        staking = IShortStaking(staking_);
        lock = IShortLock(lock_);
        oracleMaxDelay = oracleMaxDelay_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IAssetToken.sol";

struct Position {
    uint256 id;
    address owner;
    // collateral asset token.
    IERC20Extended cAssetToken;
    uint256 cAssetAmount;
    // nAsset token.
    IAssetToken assetToken;
    uint256 assetAmount;
    // if is it short position
    bool isShort;
    // 判断该空间是否已被分配
    bool assigned;
}

interface IPositions {
    function openPosition(
        address owner,
        IERC20Extended cAssetToken,
        uint256 cAssetAmount,
        IAssetToken assetToken,
        uint256 assetAmount,
        bool isShort
    ) external returns (uint256 positionId);

    function updatePosition(Position memory position_) external;

    function removePosition(uint256 positionId) external;

    function getPosition(uint256 positionId)
        external
        view
        returns (Position memory);

    function getNextPositionId() external view returns (uint256);

    function getPositions(
        address ownerAddr,
        uint256 startAt,
        uint256 limit
    ) external view returns (Position[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IChainlinkAggregator.sol";
import "./IAssetToken.sol";

struct IPOParams {
    uint256 mintEnd;
    uint256 preIPOPrice;
    // >= 1000
    uint16 minCRatioAfterIPO;
}

struct AssetConfig {
    IAssetToken token;
    IChainlinkAggregator oracle;
    uint16 auctionDiscount;
    uint16 minCRatio;
    uint16 targetRatio;
    uint256 endPrice;
    uint8 endPriceDecimals;
    // is in preIPO stage
    bool isInPreIPO;
    IPOParams ipoParams;
    // is it been delisted
    bool delisted;
    // the Id of the pool in ShortStaking contract.
    uint256 poolId;
    // if it has been assined
    bool assigned;
}

// Collateral Asset Config
struct CAssetConfig {
    IERC20Extended token;
    IChainlinkAggregator oracle;
    uint16 multiplier;
    // if it has been assined
    bool assigned;
}

interface IAsset {
    function asset(address nToken) external view returns (AssetConfig memory);

    function cAsset(address token) external view returns (CAssetConfig memory);

    function isCollateralInPreIPO(address cAssetToken)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IStakingToken.sol";

interface IShortStaking {
    function pendingNSDX(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _realUser
    ) external;

    function withdraw(
        uint256 _pid,
        uint256 _amount,
        address _realUser
    ) external;

    function poolLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

struct PositionLockInfo {
    uint256 positionId;
    address receiver;
    IERC20Upgradeable lockedToken; // address(1) means native token, such as ETH or MITIC.
    uint256 lockedAmount;
    uint256 unlockTime;
    bool assigned;
}

interface IShortLock {
    function lock(
        uint256 positionId,
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function unlock(uint256 positionId) external;

    function release(uint256 positionId) external;

    function lockInfoMap(uint256 positionId)
        external
        view
        returns (PositionLockInfo memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IPositions.sol";

interface IMint {
    function removePosition(uint positionId) external;

    function updatePosition(Position memory position) external;

    function withdrawStaking(uint _pid, uint _amount, address _realUser) external;

    function releaseLock(uint positionId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IChainlinkAggregator {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20Extended.sol";

interface IAssetToken is IERC20Extended {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function owner() external view;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20Extended is IERC20Upgradeable {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20Extended.sol";

interface IStakingToken is IERC20Extended {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function owner() external view returns (address);
}