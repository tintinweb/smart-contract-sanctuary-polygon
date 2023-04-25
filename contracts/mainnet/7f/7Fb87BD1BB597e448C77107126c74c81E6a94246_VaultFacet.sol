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
pragma solidity 0.8.4;

import {LibDiamond} from '../../libs/LibDiamond.sol';
import {LibMeta} from '../../libs/LibMeta.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

address constant MATIC = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

// AAVE
address constant AAVE_DATA_PROVIDER = 0x7551b5D2763519d4e37e8B81929D336De671d46d;
address constant AAVE_INCENTIVES = 0x357D51124f59836DeD84c8a1730D72B749d8BC23;

// QUICK
address constant QUICK = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
address constant DQUICK = 0xf28164A485B0B2C90639E47b0f377b4a438a16B1;

struct LpData {
    uint256 lpPrice;
    uint256 totalSupply;
    uint256 totalMarketUSD;
    uint112 reserves0;
    uint112 reserves1;
    address token0;
    address token1;
    string symbol0;
    string symbol1;
}

struct VeEthaInfo {
    address feeRecipient;
    uint256 minLockedAmount;
    uint256 penaltyRate;
    uint256 totalEthaLocked;
    uint256 totalVeEthaSupply;
    address multiFeeAddress;
    uint256 multiFeeTotalStaked;
    uint256 userVeEthaBalance;
    uint256 userEthaLocked;
    uint256 userLockEnds;
    uint256 multiFeeUserStake;
}

struct Rewards {
    address tokenAddress;
    uint256 rewardRate;
    uint periodFinish;
    uint balance;
    uint claimable;
}

struct SynthData {
    address stakingToken;
    address stakingContract;
    address rewardsToken;
    uint256 totalStaked;
    uint256 rewardsRate;
    uint256 periodFinish;
    uint256 rewardBalance;
}

struct ChefData {
    address stakingToken;
    address stakingContract;
    address rewardsToken;
    uint256 totalStaked;
    uint256 rewardsRate;
    uint256 periodFinish;
    uint256 rewardBalance;
}

struct VaultInfo {
    address depositToken;
    address rewardsToken;
    address strategy;
    address feeRecipient;
    address strategist;
    uint256 totalDeposits;
    uint256 performanceFee;
    uint256 withdrawalFee;
    uint256 lastDistribution;
}

struct QiVaultInfo {
    address stakingContract;
    address qiToken;
    address lpToken;
    address qiVault;
    uint poolId;
    uint debt;
    uint availableBorrow;
    uint collateral;
    uint safeLow;
    uint safeHigh;
    uint safeTarget;
}

struct AppStorage {
    mapping(address => address) aTokensV2;
    mapping(address => address) vTokensV2;
    mapping(address => address) aTokensV3;
    mapping(address => address) vTokensV3;
    mapping(address => address) priceFeeds;
    mapping(address => address) curvePools;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    function formatDecimals(address token, uint256 amount) internal view returns (uint256) {
        uint256 decimals = IERC20Metadata(token).decimals();

        if (decimals == 18) return amount;
        else return (amount * 1 ether) / (10 ** decimals);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {Modifiers, VaultInfo, QiVaultInfo} from './AppStorage.sol';
import {IVault} from '../../interfaces/IVault.sol';
import {IERC4626} from '../../interfaces/IERC4626.sol';
import {ICompStrategy} from '../../interfaces/ICompStrategy.sol';
import {IQiStrat} from '../../interfaces/qiDao/IQiStrat.sol';

contract VaultFacet is Modifiers {
    function getVolatileVaultInfo(IVault vault) external view returns (VaultInfo memory info) {
        info.depositToken = address(vault.underlying());
        info.rewardsToken = address(vault.target());
        info.strategy = address(vault.strat());
        info.totalDeposits = vault.calcTotalValue();
        info.lastDistribution = vault.lastDistribution();

        /*
            Need to try and catch because of different vault versions
            that have the fee manager vault contract inherited. Other vaults
            use the external fee manager.
        */

        try vault.performanceFee() returns (uint _performanceFee) {
            info.performanceFee = _performanceFee;
        } catch {
            info.performanceFee = vault.profitFee();
        }

        try vault.withdrawalFee() returns (uint _withdrawalFee) {
            info.withdrawalFee = _withdrawalFee;
        } catch {}

        try vault.feeRecipient() returns (address _feeRecipient) {
            info.feeRecipient = _feeRecipient;
        } catch {}

        info.strategist = info.feeRecipient;
    }

    function getCompoundVaultInfo(IERC4626 vault) external view returns (VaultInfo memory info) {
        info.depositToken = vault.asset();
        info.strategy = vault.strategy();
        info.totalDeposits = vault.totalAssets();
        info.performanceFee = ICompStrategy(info.strategy).profitFee();

        try ICompStrategy(info.strategy).output() returns (address output) {
            info.rewardsToken = output;
        } catch {}

        try ICompStrategy(info.strategy).lastHarvest() returns (uint lastHarvest) {
            info.lastDistribution = lastHarvest;
        } catch {}

        try ICompStrategy(info.strategy).ethaFeeRecipient() returns (address _ethaFeeRecipient) {
            info.feeRecipient = _ethaFeeRecipient;
        } catch {}

        try ICompStrategy(info.strategy).strategist() returns (address _strategist) {
            info.strategist = _strategist;
        } catch {}

        try ICompStrategy(info.strategy).withdrawalFee() returns (uint _withdrawalFee) {
            info.withdrawalFee = _withdrawalFee;
        } catch {
            info.withdrawalFee = vault.withdrawalFee();
        }
    }

    function getQiVaultInfo(IERC4626 vault) external view returns (QiVaultInfo memory info) {
        IQiStrat strat = IQiStrat(vault.strategy());

        info.stakingContract = strat.qiStakingRewards();
        info.qiToken = strat.qiToken();
        info.lpToken = strat.lpPairToken();
        info.qiVault = strat.qiVault();
        info.poolId = strat.qiVaultId();
        info.collateral = strat.getCollateralPercent();
        info.safeHigh = strat.SAFE_COLLAT_HIGH();
        info.safeLow = strat.SAFE_COLLAT_LOW();
        info.safeTarget = strat.SAFE_COLLAT_TARGET();
        info.debt = strat.getStrategyDebt();
        info.availableBorrow = strat.safeAmountToBorrow();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ICompStrategy {
    event StratHarvest(address indexed harvester, uint256 wantHarvested, uint256 tvl);

    event Deposit(uint256 tvl);

    event Withdraw(uint256 tvl);

    event ChargedFees(uint256 callFees, uint256 beefyFees, uint256 strategistFees);

    function callFee() external view returns (uint256);

    function poolId() external view returns (uint256);

    function strategistFee() external view returns (uint256);

    function profitFee() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function MAX_FEE() external view returns (uint256);

    function vault() external view returns (address);

    function want() external view returns (IERC20);

    function outputToNative() external view returns (address[] memory);

    function getStakingContract() external view returns (address);

    function native() external view returns (address);

    function output() external view returns (address);

    function beforeDeposit() external;

    function deposit() external;

    function getMaximumDepositLimit() external view returns (uint256);

    function withdraw(uint256) external;

    function balanceOfStrategy() external view returns (uint256);

    function balanceOfWant() external view returns (uint256);

    function balanceOfPool() external view returns (uint256);

    function lastHarvest() external view returns (uint256);

    function harvest() external;

    function harvestWithCallFeeRecipient(address) external;

    function retireStrat() external;

    function panic() external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);

    function unirouter() external view returns (address);

    function ethaFeeRecipient() external view returns (address);

    function strategist() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IERC4626 is IERC20 {
    function asset() external view returns (address assetTokenAddress);

    function totalAssets() external view returns (uint256 totalManagedAssets);

    function assetsPerShare() external view returns (uint256 assetsPerUnitShare);

    function maxDeposit(address caller) external view returns (uint256 maxAssets);

    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function maxMint(address caller) external view returns (uint256 maxShares);

    function previewMint(uint256 shares) external view returns (uint256 assets);

    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    function maxWithdraw(address caller) external view returns (uint256 maxAssets);

    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    function maxRedeem(address caller) external view returns (uint256 maxShares);

    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

    function claim() external;

    function strategy() external view returns (address);

    function name() external view returns (string memory);

    function withdrawalFee() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface IVault {
    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function claim() external returns (uint256 claimed);

    function harvest() external returns (uint256);

    function distribute(uint256 amount) external;

    function totalSupply() external view returns (uint256);

    function claimOnBehalf(address recipient) external;

    function rewards() external view returns (IERC20);

    function underlying() external view returns (IERC20Metadata);

    function target() external view returns (IERC20);

    function harvester() external view returns (address);

    function owner() external view returns (address);

    function strat() external view returns (address);

    function timelock() external view returns (address payable);

    function feeRecipient() external view returns (address);

    function lastDistribution() external view returns (uint256);

    function MAX_FEE() external view returns (uint256);

    function performanceFee() external view returns (uint256);

    function profitFee() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function totalYield() external returns (uint256);

    function calcTotalValue() external view returns (uint256);

    function unclaimedProfit(address user) external view returns (uint256);

    function pending(address user) external view returns (uint256);

    function name() external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQiStrat {
    // Getters
    function priceFeeds(address _token) external view returns (address);

    function balanceOfStrategy() external view returns (uint);

    function balanceOf() external view returns (uint256);

    function balanceOfWant() external view returns (uint256);

    function balanceOfPool() external view returns (uint256);

    function SAFE_COLLAT_TARGET() external view returns (uint256);

    function SAFE_COLLAT_LOW() external view returns (uint256);

    function SAFE_COLLAT_HIGH() external view returns (uint256);

    function rewardsAvailable() external view returns (uint256);

    function getCollateralPercent() external view returns (uint256 cdr_percent);

    function qiVaultId() external view returns (uint256);

    function getStrategyDebt() external view returns (uint256);

    function safeAmountToBorrow() external view returns (uint256);

    function qiStakingRewards() external view returns (address);

    function lpPairToken() external view returns (address);

    function qiVault() external view returns (address);

    function qiToken() external view returns (address);

    function assetToMai(uint index) external view returns (address);

    function maiToAsset(uint index) external view returns (address);

    function qiToAsset(uint index) external view returns (address);

    function maiToLp0(uint index) external view returns (address);

    function maiToLp1(uint index) external view returns (address);

    function lp0ToMai(uint index) external view returns (address);

    function lp1ToMai(uint index) external view returns (address);

    // Setters
    function setPriceFeed(address _token, address _feed) external;

    function rebalanceVault(bool _shouldRepay) external;

    function harvest() external;

    function repayDebtLp(uint256 _lpAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from '../interfaces/common/IDiamondCut.sol';

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256('diamond.standard.diamond.storage');

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, 'LibDiamond: Must be contract owner');
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert('LibDiamondCut: Incorrect FacetCutAction');
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, 'LibDiamondCut: No selectors in facet to cut');
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, 'LibDiamondCut: No selectors in facet to cut');
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, 'LibDiamondCut: No selectors in facet to cut');
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), 'LibDiamondCut: Remove facet address must be address(0)');
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, 'LibDiamondCut: New facet has no code');
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, 'LibDiamondCut: _init is address(0) but_calldata is not empty');
        } else {
            require(_calldata.length > 0, 'LibDiamondCut: _calldata is empty but _init is not address(0)');
            if (_init != address(this)) {
                enforceHasContractCode(_init, 'LibDiamondCut: _init address has no code');
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert('LibDiamondCut: _init function reverted');
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library LibMeta {
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes('EIP712Domain(string name,string version,uint256 salt,address verifyingContract)'));

    function domainSeparator(
        string memory name,
        string memory version
    ) internal view returns (bytes32 domainSeparator_) {
        domainSeparator_ = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                getChainID(),
                address(this)
            )
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}