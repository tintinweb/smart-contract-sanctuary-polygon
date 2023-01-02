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

// SPDX-License-Identifier: No License
pragma solidity >=0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract AssetRiskRateRegistry is Ownable {
    struct AssetRiskRate {
        address asset;
        uint32 riskRate;
    }

    mapping(address => uint32) public assetRiskRates;

    event AssetRiskRateDefined(address asset, uint32 riskRate);

    // solhint-disable-next-line no-empty-blocks
    constructor() Ownable() {}

    // for now onlyOwner, later probably through specific allow list
    function defineAssetRiskRates(AssetRiskRate[] calldata _assetRiskRates)
        external
        onlyOwner
    {
        uint256 _assetsLength = _assetRiskRates.length;
        for (uint256 i; i < _assetsLength; ) {
            assetRiskRates[_assetRiskRates[i].asset] = _assetRiskRates[i]
                .riskRate;

            emit AssetRiskRateDefined(
                _assetRiskRates[i].asset,
                _assetRiskRates[i].riskRate
            );

            // gas optimized for loop
            unchecked {
                ++i;
            }
        }
    }

    function assetRiskRate(address asset) external view returns (uint32) {
        return assetRiskRates[asset];
    }
}

// SPDX-License-Identifier: No License
pragma solidity >=0.8.17;

import {IBasketBlueprintRegistry} from "./interfaces/IBasketBlueprintRegistry.sol";
import {AssetRiskRateRegistry} from "./AssetRiskRateRegistry.sol";

error BasketBlueprintRegistry__BasketBlueprintNotDefined();
error BasketBlueprintRegistry__Unauthorized();
error BasketBlueprintRegistry__InvalidParams();
error BasketBlueprintRegistry__RiskRateMismatch();

contract BasketBlueprintRegistry is
    AssetRiskRateRegistry,
    IBasketBlueprintRegistry
{
    uint32 public constant riskRateMaxValue = 100_000_000;
    uint32 public constant defaultWeight = 10_000_000;

    mapping(bytes32 => address) internal _basketBlueprintOwners;
    mapping(bytes32 => BasketAsset[]) internal _basketBlueprintAssets;

    modifier basketBlueprintExists(bytes32 basketBlueprintName) {
        if (!basketBlueprintDefined(basketBlueprintName)) {
            revert BasketBlueprintRegistry__BasketBlueprintNotDefined();
        }
        _;
    }

    modifier onlyBasketBlueprintOwner(bytes32 basketBlueprintName) {
        address _basketBlueprintOwner = basketBlueprintOwner(
            basketBlueprintName
        );

        if (
            _basketBlueprintOwner != address(0) && // must be defined
            _basketBlueprintOwner != msg.sender // and msg.sender must be owner
        ) {
            revert BasketBlueprintRegistry__Unauthorized();
        }
        _;
    }

    // solhint-disable-next-line no-empty-blocks
    constructor() AssetRiskRateRegistry() {}

    function basketBlueprintDefined(bytes32 basketBlueprintName)
        public
        view
        returns (bool)
    {
        return basketBlueprintOwner(basketBlueprintName) != address(0);
    }

    function basketBlueprintOwner(bytes32 basketBlueprintName)
        public
        view
        returns (address)
    {
        return _basketBlueprintOwners[basketBlueprintName];
    }

    function basketBlueprintAssets(bytes32 basketBlueprintName)
        public
        view
        returns (BasketAsset[] memory)
    {
        return _basketBlueprintAssets[basketBlueprintName];
    }

    function defineBasketBlueprint(
        bytes32 basketBlueprintName,
        BasketAsset[] memory assets,
        address owner
    ) external onlyBasketBlueprintOwner(basketBlueprintName) {
        assets = _validateBasketBlueprint(assets);

        uint256 _assetsLength = assets.length;

        for (uint256 i; i < _assetsLength; ) {
            _basketBlueprintAssets[basketBlueprintName].push(assets[i]);

            // gas optimized for loop
            unchecked {
                ++i;
            }
        }

        _basketBlueprintOwners[basketBlueprintName] = owner;

        emit BasketBlueprintDefined(basketBlueprintName, owner);
    }

    function transferBasketBlueprintOwnership(
        bytes32 basketBlueprintName,
        address newOwner
    ) external onlyBasketBlueprintOwner(basketBlueprintName) {
        address previousOwner = basketBlueprintOwner(basketBlueprintName);

        _basketBlueprintOwners[basketBlueprintName] = newOwner;

        emit BasketBlueprintOwnerChanged(
            basketBlueprintName,
            previousOwner,
            newOwner
        );
    }

    function basketBlueprintRiskRate(bytes32 basketBlueprintName)
        external
        view
        basketBlueprintExists(basketBlueprintName)
        returns (uint256 riskRate)
    {
        BasketAsset[] memory assets = basketBlueprintAssets(
            basketBlueprintName
        );

        uint256 _assetsLength = assets.length;

        // FORMULA = SUM(asset risk rate * asset weight) / SUM(asset weights)
        uint256 weightedRiskRatesSum; // = SUM (asset risk rate * asset weight)
        uint256 weightsSum; // = SUM (asset weights)

        for (uint256 i; i < _assetsLength; ) {
            // unchecked is ok here because riskRate is max uint32 (actually even riskRateMaxValue)
            // and asset weight is max uint32, multiplied fits easily into uint256
            unchecked {
                weightedRiskRatesSum +=
                    (uint256(assets[i].riskRate) * uint256(assets[i].weight)) /
                    1e6; // weight has decimals 1e6
                weightsSum += assets[i].weight;
            }

            // gas optimized for loop
            unchecked {
                ++i;
            }
        }

        if (weightsSum == 0) {
            return 0;
        }

        unchecked {
            riskRate = (weightedRiskRatesSum * 1e6) / weightsSum; // weight has decimals 1e6
        }
    }

    /// @notice Ensures valid values for all basket assets and sets default weight if necessary
    function _validateBasketBlueprint(BasketAsset[] memory assets)
        internal
        view
        returns (BasketAsset[] memory)
    {
        uint256 _assetsLength = assets.length;

        for (uint256 i; i < _assetsLength; ) {
            if (
                address(assets[i].asset) == address(0) ||
                assets[i].riskRate == 0 ||
                assets[i].riskRate > riskRateMaxValue ||
                assets[i].assetType > 1 // this has to be adjusted if more walletIdTypes become available...
                // contract upgradeable or have a MAX_ASSET_TYPE adjustable and configurable by an owner?
            ) {
                revert BasketBlueprintRegistry__InvalidParams();
            }

            // if no weight is set for this asset set it to the default weight
            if (assets[i].weight == 0) {
                assets[i].weight = defaultWeight;
            }

            // risk rate must match the protocol risk rate for the asset, if defined
            // Todo: when updating asset risk rate in AssetRiskRateRegistry then it should be updated
            // for all configured baskets too, not just at initial config...
            uint32 protocolAssetRiskRate = assetRiskRates[
                address(assets[i].asset)
            ];
            if (
                protocolAssetRiskRate != 0 &&
                protocolAssetRiskRate != assets[i].riskRate
            ) {
                revert BasketBlueprintRegistry__RiskRateMismatch();
            }

            // gas optimized for loop
            unchecked {
                ++i;
            }
        }

        return assets;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBasketBlueprintRegistry {
    // tightly packed to 32 bytes
    struct BasketAsset {
        IERC20 asset; // 20 bytes
        // risk rate should be 1e6, i.e. a risk rate of 1% would be 1_000_000. 10% 10_000_000 etc.
        // must be >0 and <=100% (1 and 100_000_000)
        uint32 riskRate; // 4 bytes
        // weight should be 1e6, i.e. a weight of 1 would be 1_000_000. default weight is 10_000_000
        // must be >0
        uint32 weight; // 4 bytes
        // assetType is basically an Enum that is mapped to ChargedParticles walletManagerId
        // 0 = "generic.B" (for generic all ERC20 tokens)
        // 1 = "aave.B" (for yield bearing Aave tokens)
        uint32 assetType; // 4 bytes
    }

    // later maybe: basketBluePrintNames array[]
    // verified status of basketBluePrint

    event BasketBlueprintDefined(bytes32 basketBlueprintName, address owner);
    event BasketBlueprintOwnerChanged(
        bytes32 basketBlueprintName,
        address previousOwner,
        address newOwner
    );

    function riskRateMaxValue() external view returns (uint32);

    function defaultWeight() external view returns (uint32);

    function basketBlueprintDefined(bytes32 basketBlueprintName)
        external
        view
        returns (bool);

    function basketBlueprintOwner(bytes32 basketBlueprintName)
        external
        view
        returns (address);

    function basketBlueprintAssets(bytes32 basketBlueprintName)
        external
        view
        returns (BasketAsset[] memory);

    function defineBasketBlueprint(
        bytes32 basketBlueprintName,
        BasketAsset[] calldata assets,
        address owner
    ) external;

    function transferBasketBlueprintOwnership(
        bytes32 basketBlueprintName,
        address newOwner
    ) external;

    function basketBlueprintRiskRate(bytes32 basketBlueprintName)
        external
        view
        returns (uint256 riskRate);
}