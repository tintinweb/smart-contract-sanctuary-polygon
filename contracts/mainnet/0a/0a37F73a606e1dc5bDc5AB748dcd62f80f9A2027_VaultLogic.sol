// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {LibDiamond} from "../../libs/LibDiamond.sol";
import {LibMeta} from "../../libs/LibMeta.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

address constant AVAX = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
address constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

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
    address distribution;
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
    mapping(address => address) priceFeeds;
    mapping(address => address) curvePools;
    address ethaRegistry;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract AvaModifiers {
    AppStorage internal s;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    function formatDecimals(address token, uint256 amount) internal view returns (uint256) {
        uint256 decimals = IERC20Metadata(token).decimals();

        if (decimals == 18) return amount;
        else return (amount * 1 ether) / (10**decimals);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

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
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
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
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
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
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
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

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
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
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
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
        keccak256(bytes("EIP712Domain(string name,string version,uint256 salt,address verifyingContract)"));

    function domainSeparator(string memory name, string memory version) internal view returns (bytes32 domainSeparator_) {
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {AvaModifiers, VaultInfo, QiVaultInfo} from "./AppStorage.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {IERC4626} from "../../interfaces/IERC4626.sol";
import {IStrategy} from "../../interfaces/IStrategy.sol";
import {IQiStrat} from "../../interfaces/IQiStrat.sol";
import "../../interfaces/IFeeManager.sol";
import "../../interfaces/IRegistry.sol";

contract AvaVaultFacet is AvaModifiers {
    function getVolatileVaultInfo(IVault vault) external view returns (VaultInfo memory info) {
        info.depositToken = address(vault.underlying());
        info.rewardsToken = address(vault.target());
        info.strategy = address(vault.strat());
        info.distribution = vault.distribution();
        info.totalDeposits = vault.calcTotalValue();
        info.lastDistribution = vault.lastDistribution();
        info.performanceFee = vault.profitFee();
        info.withdrawalFee = vault.withdrawalFee();
        info.feeRecipient = vault.feeRecipient();
        info.strategist = info.feeRecipient;
    }

    function getCompoundVaultInfo(IERC4626 vault) external view returns (VaultInfo memory info) {
        info.depositToken = vault.asset();
        info.strategy = vault.strategy();
        info.distribution = vault.distribution();
        info.totalDeposits = vault.totalAssets();
        info.performanceFee = IStrategy(info.strategy).profitFee();
        info.rewardsToken = IStrategy(info.strategy).output();
        info.strategist = IStrategy(info.strategy).strategist();
        info.feeRecipient = IStrategy(info.strategy).ethaFeeRecipient();
        info.lastDistribution = IStrategy(info.strategy).lastHarvest();

        try vault.withdrawalFee() returns (uint _withdrawalFee) {
            info.withdrawalFee = _withdrawalFee;
        } catch {
            info.withdrawalFee = IStrategy(info.strategy).withdrawalFee();
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Detailed is IERC20 {
    function decimals() external view returns (uint8);
}

interface IVault {
    function totalSupply() external view returns (uint256);

    function harvest() external returns (uint256);

    function distribute(uint256 amount) external;

    function rewards() external view returns (IERC20);

    function underlying() external view returns (IERC20Detailed);

    function target() external view returns (IERC20);

    function harvester() external view returns (address);

    function owner() external view returns (address);

    function distribution() external view returns (address);

    function strat() external view returns (address);

    function timelock() external view returns (address payable);

    function feeRecipient() external view returns (address);

    function claimOnBehalf(address recipient) external;

    function lastDistribution() external view returns (uint256);

    function performanceFee() external view returns (uint256);

    function profitFee() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function totalYield() external returns (uint256);

    function calcTotalValue() external view returns (uint256);

    function deposit(uint256 amount) external;

    function depositAndWait(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function withdrawPending(uint256 amount) external;

    function changePerformanceFee(uint256 fee) external;

    function claim() external returns (uint256 claimed);

    function unclaimedProfit(address user) external view returns (uint256);

    function pending(address user) external view returns (uint256);

    function name() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    function maxRedeem(address caller) external view returns (uint256 maxShares);

    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    function claim() external;

    function distribution() external view returns (address);

    function strategy() external view returns (address);

    function name() external view returns (string memory);

    function withdrawalFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStrategy {
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeManager {
	function MAX_FEE() external view returns (uint256);

	function getVaultFee(address _vault) external view returns (uint256);

	function setVaultFee(address _vault, uint256 _fee) external;

	function getLendingFee(address _asset) external view returns (uint256);

	function setLendingFee(address _asset, uint256 _fee) external;

	function getSwapFee() external view returns (uint256);

	function setSwapFee(uint256 _swapFee) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RegistryInterface Interface
 */
interface IRegistry {
	function logic(address logicAddr) external view returns (bool);

	function implementation(bytes32 key) external view returns (address);

	function notAllowed(address erc20) external view returns (bool);

	function deployWallet() external returns (address);

	function wallets(address user) external view returns (address);

	function getFee() external view returns (uint256);

	function getFeeManager() external view returns (address);

	function feeRecipient() external view returns (address);

	function memoryAddr() external view returns (address);

	function distributionContract(address token)
		external
		view
		returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IProtocolDistribution.sol";
import "../interfaces/IProtocolDistribution.sol";
import "../interfaces/IDistributionFactory.sol";
import "../interfaces/IRegistry.sol";
import "../interfaces/IWallet.sol";
import "../interfaces/IAaveIncentives.sol";

/**
 * @title Claim ETHA rewards for interacting with Lending Protocols
 */
contract ClaimResolver {
    event Claim(address indexed erc20, uint256 tokenAmt);

    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    /**
     * @dev get vault distribution factory address
     */
    function getVaultDistributionFactory() public pure returns (address) {
        return 0xdB05A386810c809aD5a77422eb189D36c7f24402;
    }

    /**
     * @dev get Aave MATIC incentives distribution contract
     */
    function getAaveIncentivesAddress() public pure returns (address) {
        return 0x357D51124f59836DeD84c8a1730D72B749d8BC23;
    }

    /**
     * @dev get lending distribution contract address
     */
    function getLendingDistributionAddress(address token) public view returns (address) {
        return IRegistry(IWallet(address(this)).registry()).distributionContract(token);
    }

    /**
     * @notice read aave rewards in MATIC
     */
    function getRewardsAave(address[] memory tokens, address user) external view returns (uint256) {
        return IAaveIncentives(getAaveIncentivesAddress()).getRewardsBalance(tokens, user);
    }

    /**
     * @notice read lending rewards in ETHA
     */
    function getRewardsLending(address erc20, address user) external view returns (uint256) {
        return IProtocolDistribution(getLendingDistributionAddress(erc20)).earned(user);
    }

    /**
     * @notice read vaults rewards in ETHA
     */
    function getRewardsVaults(address erc20, address user) external view returns (uint256) {
        address dist = IDistributionFactory(getVaultDistributionFactory()).stakingRewardsInfoByStakingToken(erc20);

        return IProtocolDistribution(dist).earned(user);
    }

    /**
     * @notice claim vault ETHA rewards
     */
    function claimRewardsVaults(address erc20) external {
        address dist = IDistributionFactory(getVaultDistributionFactory()).stakingRewardsInfoByStakingToken(erc20);

        uint256 _earned = IProtocolDistribution(dist).earned(address(this));
        address distToken = IProtocolDistribution(dist).rewardsToken();

        IProtocolDistribution(dist).getReward(address(this));

        emit Claim(distToken, _earned);
    }

    /**
     * @notice claim lending ETHA rewards
     */
    function claimRewardsLending(address erc20) external {
        uint256 _earned = IProtocolDistribution(getLendingDistributionAddress(erc20)).earned(address(this));

        if (_earned > 0) {
            IProtocolDistribution(getLendingDistributionAddress(erc20)).getReward(address(this));

            address distToken = IProtocolDistribution(getLendingDistributionAddress(erc20)).rewardsToken();

            emit Claim(distToken, _earned);
        }
    }

    /**
     * @notice claim Aave MATIC rewards
     */
    function claimAaveRewards(address[] calldata tokens, uint256 amount) external {
        IAaveIncentives(getAaveIncentivesAddress()).claimRewards(tokens, amount, address(this));

        emit Claim(WMATIC, amount);
    }

    /**
     * @notice claim lending ETHA rewards (old contract)
     */
    function claimRewardsLendingOld(address _stakingContract) external {
        uint256 _earned = IProtocolDistribution(_stakingContract).earned(address(this));

        if (_earned > 0) {
            IProtocolDistribution(_stakingContract).getReward(address(this));

            address distToken = IProtocolDistribution(_stakingContract).rewardsToken();

            emit Claim(distToken, _earned);
        }
    }
}

contract ClaimLogic is ClaimResolver {
    string public constant name = "ClaimLogic";
    uint8 public constant version = 1;

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProtocolDistribution {
	function stake(uint256 amount) external;

	function withdraw(uint256 amount) external;

	function getReward(address user) external;

	function earned(address user) external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function rewardsToken() external view returns (address);

	function rewardPerToken() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDistributionFactory {
	function stakingRewardsInfoByStakingToken(address erc20)
		external
		view
		returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWallet {
    event LogMint(address indexed erc20, uint256 tokenAmt);
    event LogRedeem(address indexed erc20, uint256 tokenAmt);
    event LogBorrow(address indexed erc20, uint256 tokenAmt);
    event LogPayback(address indexed erc20, uint256 tokenAmt);
    event LogDeposit(address indexed erc20, uint256 tokenAmt);
    event LogWithdraw(address indexed erc20, uint256 tokenAmt);
    event LogSwap(address indexed src, address indexed dest, uint256 amount);
    event LogLiquidityAdd(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB);
    event LogLiquidityRemove(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB);
    event VaultDeposit(address indexed vault, address indexed erc20, uint256 tokenAmt);
    event VaultWithdraw(address indexed vault, address indexed erc20, uint256 tokenAmt);
    event VaultClaim(address indexed vault, address indexed erc20, uint256 tokenAmt);
    event Claim(address indexed erc20, uint256 tokenAmt);
    event DelegateAdded(address delegate);
    event DelegateRemoved(address delegate);
    event Staked(address indexed erc20, uint256 tokenAmt);
    event Unstaked(address indexed erc20, uint256 tokenAmt);

    event VoteEscrowDeposit(address indexed veETHA, uint256 amountToken, uint256 amtDays);
    event VoteEscrowWithdraw(address indexed veETHA, uint256 amountToken);
    event VoteEscrowIncrease(address indexed veETHA, uint256 amountToken, uint256 amtDays);

    function executeMetaTransaction(bytes memory sign, bytes memory data) external;

    function execute(address[] calldata targets, bytes[] calldata datas) external payable;

    function owner() external view returns (address);

    function registry() external view returns (address);

    function DELEGATE_ROLE() external view returns (bytes32);

    function hasRole(bytes32, address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAaveIncentives {
	function REWARD_TOKEN() external view returns (address);

	function getRewardsBalance(address[] calldata _assets, address user)
		external
		view
		returns (uint256);

	function assets(address aToken)
		external
		view
		returns (
			uint128 emissionPerSecond,
			uint128 lastUpdateTimestamp,
			uint256 index
		);

	function getUserUnclaimedRewards(address _user)
		external
		view
		returns (uint256);

	function claimRewards(
		address[] calldata _assets,
		uint256 amount,
		address to
	) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IMemory.sol";
import "../../interfaces/ICToken.sol";
import "../../interfaces/IAaveIncentives.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Modifiers, LendingBalance, MATIC, WMATIC, AAVE_DATA_PROVIDER, AAVE_INCENTIVES, IERC20Metadata} from "./AppStorage.sol";

interface IProtocolDataProvider {
    function getUserReserveData(address reserve, address user) external view returns (uint256 currentATokenBalance);

    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );
}

contract AaveFacet is Modifiers {
    function getAaveRewards(address[] memory _tokens)
        public
        view
        returns (uint256[] memory _rewardsLending, uint256[] memory _rewardsBorrowing)
    {
        _rewardsLending = new uint256[](_tokens.length);
        _rewardsBorrowing = new uint256[](_tokens.length);

        (, int256 maticPrice, , , ) = AggregatorV3Interface(s.priceFeeds[MATIC]).latestRoundData();

        for (uint256 i = 0; i < _tokens.length; i++) {
            (, int256 tokenPrice, , , ) = AggregatorV3Interface(s.priceFeeds[_tokens[i]]).latestRoundData();

            // Lending Data
            {
                IERC20Metadata token_ = IERC20Metadata(s.aTokens[_tokens[i]]);
                uint256 totalSupply = formatDecimals(address(token_), token_.totalSupply());

                (uint256 emissionPerSecond, , ) = IAaveIncentives(AAVE_INCENTIVES).assets(address(token_));

                if (emissionPerSecond > 0) {
                    _rewardsLending[i] =
                        (emissionPerSecond * uint256(maticPrice) * 365 days * 1 ether) /
                        (totalSupply * uint256(tokenPrice));
                }
            }

            // Borrowing Data
            {
                IERC20Metadata token_ = IERC20Metadata(s.debtTokens[_tokens[i]]);
                uint256 totalSupply = formatDecimals(address(token_), token_.totalSupply());

                (uint256 emissionPerSecond, , ) = IAaveIncentives(AAVE_INCENTIVES).assets(address(token_));

                if (emissionPerSecond > 0) {
                    _rewardsBorrowing[i] =
                        (emissionPerSecond * uint256(maticPrice) * 365 days * 1 ether) /
                        (totalSupply * uint256(tokenPrice));
                }
            }
        }
    }

    function getAaveBalanceV2(address token, address account) public view returns (uint256) {
        (, , , , , , , , bool isActive, ) = IProtocolDataProvider(AAVE_DATA_PROVIDER).getReserveConfigurationData(
            token == MATIC ? WMATIC : token
        );

        if (!isActive) return 0;

        return IProtocolDataProvider(AAVE_DATA_PROVIDER).getUserReserveData(token == MATIC ? WMATIC : token, account);
    }

    function getCreamBalance(address token, address user) public view returns (uint256) {
        address cToken = s.crTokens[token];

        if (cToken == address(0)) return 0;

        (, uint256 balance, , uint256 rate) = ICToken(cToken).getAccountSnapshot(user);

        return (balance * rate) / 1 ether;
    }

    function getLendingBalances(address[] calldata tokens, address user) external view returns (LendingBalance[] memory) {
        LendingBalance[] memory balances = new LendingBalance[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i].aave = getAaveBalanceV2(tokens[i], user);
            balances[i].cream = getCreamBalance(tokens[i], user);
        }

        return balances;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMemory {
	function getUint(uint256) external view returns (uint256);

	function setUint(uint256 id, uint256 value) external;

	function getAToken(address asset) external view returns (address);

	function setAToken(address asset, address _aToken) external;

	function getCrToken(address asset) external view returns (address);

	function setCrToken(address asset, address _crToken) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICToken {
	function redeem(uint256 redeemTokens) external returns (uint256);

	function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

	function borrow(uint256 borrowAmount) external returns (uint256);

	function liquidateBorrow(
		address borrower,
		uint256 repayAmount,
		address cTokenCollateral
	) external returns (uint256);

	function liquidateBorrow(address borrower, address cTokenCollateral)
		external
		payable;

	function exchangeRateCurrent() external returns (uint256);

	function getCash() external view returns (uint256);

	function borrowRatePerBlock() external view returns (uint256);

	function supplyRatePerBlock() external view returns (uint256);

	function totalReserves() external view returns (uint256);

	function totalBorrows() external view returns (uint256);

	function reserveFactorMantissa() external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256 balance);

	function borrowBalanceStored(address owner)
		external
		view
		returns (uint256 balance);

	function allowance(address, address) external view returns (uint256);

	function approve(address, uint256) external;

	function transfer(address, uint256) external returns (bool);

	function transferFrom(
		address,
		address,
		uint256
	) external returns (bool);

	function decimals() external view returns (uint8);

	function symbol() external view returns (string memory);

	function getAccountSnapshot(address)
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256
		);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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
pragma solidity 0.8.4;

import {LibDiamond} from "../../libs/LibDiamond.sol";
import {LibMeta} from "../../libs/LibMeta.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

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
    address distribution;
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

struct LendingBalance {
    uint256 aave;
    uint256 cream;
}

struct AppStorage {
    mapping(address => address) aTokens;
    mapping(address => address) debtTokens;
    mapping(address => address) crTokens;
    mapping(address => address) priceFeeds;
    mapping(address => address) curvePools;
    address[] creamMarkets;
    address ethaRegistry;
    address feeManager;
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
        else return (amount * 1 ether) / (10**decimals);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {Modifiers, VaultInfo, QiVaultInfo} from "./AppStorage.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {IERC4626} from "../../interfaces/IERC4626.sol";
import {IStrategy} from "../../interfaces/IStrategy.sol";
import {IQiStrat} from "../../interfaces/IQiStrat.sol";
import "../../interfaces/IFeeManager.sol";
import "../../interfaces/IRegistry.sol";

contract VaultFacet is Modifiers {
    function getVolatileVaultInfo(IVault vault) external view returns (VaultInfo memory info) {
        info.depositToken = address(vault.underlying());
        info.rewardsToken = address(vault.target());
        info.strategy = address(vault.strat());
        info.distribution = vault.distribution();
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
        } catch {
            info.withdrawalFee = IFeeManager(s.feeManager).getVaultFee(address(vault));
        }

        try vault.feeRecipient() returns (address _feeRecipient) {
            info.feeRecipient = _feeRecipient;
        } catch {
            info.feeRecipient = IRegistry(s.ethaRegistry).feeRecipient();
        }

        info.strategist = info.feeRecipient;
    }

    function getCompoundVaultInfo(IERC4626 vault) external view returns (VaultInfo memory info) {
        info.depositToken = vault.asset();
        info.strategy = vault.strategy();
        info.distribution = vault.distribution();
        info.totalDeposits = vault.totalAssets();
        info.performanceFee = IStrategy(info.strategy).profitFee();

        try IStrategy(info.strategy).output() returns (address output) {
            info.rewardsToken = output;
        } catch {}

        try IStrategy(info.strategy).lastHarvest() returns (uint lastHarvest) {
            info.lastDistribution = lastHarvest;
        } catch {}

        try IStrategy(info.strategy).ethaFeeRecipient() returns (address _ethaFeeRecipient) {
            info.feeRecipient = _ethaFeeRecipient;
        } catch {}

        try IStrategy(info.strategy).strategist() returns (address _strategist) {
            info.strategist = _strategist;
        } catch {}

        try IStrategy(info.strategy).withdrawalFee() returns (uint _withdrawalFee) {
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IStrat.sol";
import "../../interfaces/IVault.sol";
import "./DividendToken.sol";
import "./FeeManagerVaultV2.sol";
import "../../utils/Timelock.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../../interfaces/IMasterChefDistribution.sol";
import "../../interfaces/IFeeManager.sol";

contract VaultV2 is FeeManagerVaultV2, Pausable, DividendToken {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Detailed;
    using SafeERC20 for IERC20;

    // EVENTS
    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event Claim(address indexed user, uint amount);
    event HarvesterChanged(address newHarvester);
    event StrategyChanged(address newStrat);
    event DepositLimitUpdated(uint256 newLimit);
    event NewDistribution(address newDistribution);

    IERC20Detailed public underlying;
    IERC20 public rewards;
    IStrat public strat;
    Timelock public timelock;

    address public harvester;

    // if depositLimit = 0 then there is no deposit limit
    uint256 public depositLimit;
    uint256 public lastDistribution;
    address public distribution;

    modifier onlyHarvester() {
        require(msg.sender == harvester);
        _;
    }

    constructor(
        IERC20Detailed underlying_,
        IERC20 target_,
        IERC20 rewards_,
        address harvester_,
        string memory name_,
        string memory symbol_
    ) DividendToken(target_, name_, symbol_, underlying_.decimals()) {
        underlying = underlying_;
        rewards = rewards_;
        harvester = harvester_;
        // feeRecipient = msg.sender;
        depositLimit = 20000 * (10**underlying_.decimals()); // 20k initial deposit limit
        timelock = new Timelock(msg.sender, 3 days);
        _pause(); // paused until a strategy is connected
    }

    function _payWithdrawalFees(uint256 amt) internal returns (uint256 feesPaid) {
        if (withdrawalFee > 0 && amt > 0) {
            require(feeRecipient != address(0), "ZERO ADDRESS");

            feesPaid = amt.mul(withdrawalFee).div(MAX_FEE);

            underlying.safeTransfer(feeRecipient, feesPaid);
        }
    }

    function calcTotalValue() public view returns (uint256 underlyingAmount) {
        return strat.calcTotalValue();
    }

    function totalYield() public returns (uint256) {
        return strat.totalYield();
    }

    function deposit(uint256 amount) external whenNotPaused {
        require(amount > 0, "ZERO-AMOUNT");

        if (depositLimit > 0) {
            // if deposit limit is 0, then there is no deposit limit
            require(totalSupply().add(amount) <= depositLimit);
        }

        uint initialValue = calcTotalValue();

        underlying.safeTransferFrom(msg.sender, address(strat), amount);
        strat.invest();

        uint deposited = calcTotalValue() - initialValue;

        // Update MasterChefDistribution contract state and distribute unclaimed rewards(if any)
        if (distribution != address(0)) {
            IMasterChefDistribution(distribution).stake(msg.sender, deposited);
        }

        _mint(msg.sender, deposited);

        emit Deposit(msg.sender, deposited);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "ZERO-AMOUNT");

        uint initialValue = calcTotalValue();

        strat.divest(amount);

        uint withdrawn = initialValue - calcTotalValue();

        // Update MasterChefDistribution contract state and distribute unclaimed rewards(if any)
        if (distribution != address(0)) {
            IMasterChefDistribution(distribution).withdraw(msg.sender, withdrawn);
        }

        _burn(msg.sender, withdrawn);

        // Withdrawal fees
        uint feesPaid = _payWithdrawalFees(withdrawn);

        underlying.safeTransfer(msg.sender, withdrawn - feesPaid);

        emit Withdraw(msg.sender, withdrawn);
    }

    function unclaimedProfit(address user) external view returns (uint256) {
        return withdrawableDividendOf(user);
    }

    function claim() public returns (uint256 claimed) {
        claimed = withdrawDividend(msg.sender);

        if (distribution != address(0)) {
            IMasterChefDistribution(distribution).getReward(msg.sender);
        }

        emit Claim(msg.sender, claimed);
    }

    // Used to claim on behalf of certain contracts e.g. Uniswap pool
    function claimOnBehalf(address recipient) external {
        require(msg.sender == harvester || msg.sender == owner());
        withdrawDividend(recipient);
    }

    // ==== ONLY OWNER ===== //

    function updateDistribution(address newDistribution) public onlyOwner {
        distribution = newDistribution;
        emit NewDistribution(newDistribution);
    }

    function pauseDeposits(bool trigger) external onlyOwner {
        if (trigger) _pause();
        else _unpause();
    }

    function changeHarvester(address harvester_) external onlyOwner {
        require(harvester_ != address(0), "!ZERO ADDRESS");

        harvester = harvester_;

        emit HarvesterChanged(harvester_);
    }

    // if limit == 0 then there is no deposit limit
    function setDepositLimit(uint256 limit) external onlyOwner {
        depositLimit = limit;

        emit DepositLimitUpdated(limit);
    }

    // Any tokens (other than the target) that are sent here by mistake are recoverable by the owner
    function sweep(address _token) external onlyOwner {
        require(_token != address(target));
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    // ==== ONLY HARVESTER ===== //

    function harvest() external onlyHarvester returns (uint256 afterFee) {
        // Divest and claim rewards
        uint256 claimed = strat.claim();

        require(claimed > 0, "Nothing to harvest");

        if (profitFee > 0) {
            // Calculate fees on underlying
            uint256 fee = claimed.mul(profitFee).div(MAX_FEE);
            afterFee = claimed.sub(fee);
            rewards.safeTransfer(feeRecipient, fee);
        } else {
            afterFee = claimed;
        }

        // Transfer rewards to harvester
        rewards.safeTransfer(harvester, afterFee);
    }

    function distribute(uint256 amount) external onlyHarvester {
        distributeDividends(amount);
        lastDistribution = block.timestamp;
    }

    // ==== ONLY TIMELOCK ===== //

    // The owner has to wait 2 days to confirm changing the strat.
    // This protects users from an upgrade to a malicious strategy
    // Users must watch the timelock contract on Etherscan for any transactions
    function setStrat(IStrat strat_, bool force) external {
        if (address(strat) != address(0)) {
            require(msg.sender == address(timelock), "Only Timelock");
            uint256 prevTotalValue = strat.calcTotalValue();
            strat.divest(prevTotalValue);
            underlying.safeTransfer(address(strat_), underlying.balanceOf(address(this)));
            strat_.invest();
            if (!force) {
                require(strat_.calcTotalValue() >= prevTotalValue);
                require(strat.calcTotalValue() == 0);
            }
        } else {
            require(msg.sender == owner());
            _unpause();
        }
        strat = strat_;

        emit StrategyChanged(address(strat));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract IStrat {
    function invest() external virtual; // underlying amount must be sent from vault to strat address before

    function divest(uint256 amount) external virtual; // should send requested amount to vault directly, not less or more

    function totalYield() external virtual returns (uint256);

    function calcTotalValue() external view virtual returns (uint256);

    function claim() external virtual returns (uint256 claimed);

    function router() external virtual returns (address);

    function outputToTarget() external virtual returns (address[] memory);

    function setSwapRoute(address[] memory) external virtual;

    function setRouter(address) external virtual;

    function rescue(
        address _token,
        address _to,
        uint256 _amount
    ) external virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../libs/SafeMathUint.sol";
import "../../libs/SafeMathInt.sol";

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute a target token
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendToken is ERC20 {
	using SafeMath for uint256;
	using SafeMathUint for uint256;
	using SafeMathInt for int256;
	using SafeERC20 for IERC20;

	IERC20 public target;

	uint8 _decimals;

	// With `MAGNITUDE`, we can properly distribute dividends even if the amount of received target is small.
	// For more discussion about choosing the value of `MAGNITUDE`,
	//  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
	uint256 internal constant MAGNITUDE = 2**165;

	uint256 internal magnifiedDividendPerShare;

	// About dividendCorrection:
	// If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
	//   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
	// When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
	//   `dividendOf(_user)` should not be changed,
	//   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
	// To keep the `dividendOf(_user)` unchanged, we add a correction term:
	//   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
	//   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
	//   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
	// So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
	mapping(address => int256) internal magnifiedDividendCorrections;
	mapping(address => uint256) internal withdrawnDividends;

	constructor(
		IERC20 target_,
		string memory name_,
		string memory symbol_,
		uint8 decimals_
	) ERC20(name_, symbol_) {
		_decimals = decimals_;
		target = target_;
	}

	function decimals() public view override returns (uint8) {
		return _decimals;
	}

	/// @notice Distributes target to token holders as dividends.
	/// @dev It reverts if the total supply of tokens is 0.
	/// It emits the `DividendsDistributed` event if the amount of received target is greater than 0.
	/// About undistributed target tokens:
	///   In each distribution, there is a small amount of target not distributed,
	///     the magnified amount of which is
	///     `(amount * MAGNITUDE) % totalSupply()`.
	///   With a well-chosen `MAGNITUDE`, the amount of undistributed target
	///     (de-magnified) in a distribution can be less than 1 wei.
	///   We can actually keep track of the undistributed target in a distribution
	///     and try to distribute it in the next distribution,
	///     but keeping track of such data on-chain costs much more than
	///     the saved target, so we don't do that.
	function distributeDividends(uint256 amount) internal {
		require(totalSupply() > 0, "ZERO SUPPLY");
		require(amount > 0, "!AMOUNT");

		magnifiedDividendPerShare = magnifiedDividendPerShare.add(
			(amount).mul(MAGNITUDE) / totalSupply()
		);

		target.safeTransferFrom(msg.sender, address(this), amount);

		emit DividendsDistributed(msg.sender, amount);
	}

	/// @notice Withdraws the target distributed to the sender.
	/// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn target is greater than 0.
	function withdrawDividend(address user)
		internal
		returns (uint256 _withdrawableDividend)
	{
		_withdrawableDividend = withdrawableDividendOf(user);
		if (_withdrawableDividend > 0) {
			withdrawnDividends[user] = withdrawnDividends[user].add(
				_withdrawableDividend
			);
			emit DividendWithdrawn(user, _withdrawableDividend);
			target.safeTransfer(user, _withdrawableDividend);
		}
	}

	/// @notice View the amount of dividend in wei that an address can withdraw.
	/// @param _owner The address of a token holder.
	/// @return The amount of dividend in wei that `_owner` can withdraw.
	function dividendOf(address _owner) external view returns (uint256) {
		return withdrawableDividendOf(_owner);
	}

	/// @notice View the amount of dividend in wei that an address can withdraw.
	/// @param _owner The address of a token holder.
	/// @return The amount of dividend in wei that `_owner` can withdraw.
	function withdrawableDividendOf(address _owner)
		internal
		view
		returns (uint256)
	{
		return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
	}

	/// @notice View the amount of dividend in wei that an address has withdrawn.
	/// @param _owner The address of a token holder.
	/// @return The amount of dividend in wei that `_owner` has withdrawn.
	function withdrawnDividendOf(address _owner)
		external
		view
		returns (uint256)
	{
		return withdrawnDividends[_owner];
	}

	/// @notice View the amount of dividend in wei that an address has earned in total.
	/// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
	/// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / MAGNITUDE
	/// @param _owner The address of a token holder.
	/// @return The amount of dividend in wei that `_owner` has earned in total.
	function accumulativeDividendOf(address _owner)
		public
		view
		returns (uint256)
	{
		return
			magnifiedDividendPerShare
				.mul(balanceOf(_owner))
				.toInt256Safe()
				.add(magnifiedDividendCorrections[_owner])
				.toUint256Safe() / MAGNITUDE;
	}

	/// @dev Internal function that transfer tokens from one address to another.
	/// Update magnifiedDividendCorrections to keep dividends unchanged.
	/// @param from The address to transfer from.
	/// @param to The address to transfer to.
	/// @param value The amount to be transferred.
	function _transfer(
		address from,
		address to,
		uint256 value
	) internal override {
		super._transfer(from, to, value);

		int256 _magCorrection = magnifiedDividendPerShare
			.mul(value)
			.toInt256Safe();
		magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from]
			.add(_magCorrection);
		magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(
			_magCorrection
		);
	}

	/// @dev Internal function that mints tokens to an account.
	/// Update magnifiedDividendCorrections to keep dividends unchanged.
	/// @param account The account that will receive the created tokens.
	/// @param value The amount that will be created.
	function _mint(address account, uint256 value) internal override {
		super._mint(account, value);

		magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
			account
		].sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
	}

	/// @dev Internal function that burns an amount of the token of a given account.
	/// Update magnifiedDividendCorrections to keep dividends unchanged.
	/// @param account The account whose tokens will be burnt.
	/// @param value The amount that will be burnt.
	function _burn(address account, uint256 value) internal override {
		super._burn(account, value);

		magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
			account
		].add((magnifiedDividendPerShare.mul(value)).toInt256Safe());
	}

	/// @dev This event MUST emit when target is distributed to token holders.
	/// @param from The address which sends target to this contract.
	/// @param weiAmount The amount of distributed target in wei.
	event DividendsDistributed(address indexed from, uint256 weiAmount);

	/// @dev This event MUST emit when an address withdraws their dividend.
	/// @param to The address which withdraws target from this contract.
	/// @param weiAmount The amount of withdrawn target in wei.
	event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract FeeManagerVaultV2 is Ownable {
    address public feeRecipient;
    address public keeper;

    // Used to calculate final fee (denominator)
    uint256 public constant MAX_FEE = 10000;

    // Max value for fees
    uint256 public constant WITHDRAWAL_FEE_CAP = 150; // 1.5%
    uint256 public constant PROFIT_FEE_CAP = 3000; // 30%

    // Initial fee values
    uint256 public withdrawalFee = 10; // 0.1%
    uint256 public profitFee = 2000; // 20% of profits harvested

    // Events to be emitted when fees are charged
    event NewProfitFee(uint256 fee);
    event NewWithdrawalFee(uint256 fee);
    event NewFeeRecipient(address newFeeRecipient);
    event NewKeeper(address newKeeper);

    constructor() {
        feeRecipient = msg.sender;
    }

    // checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == keeper, "!manager");
        _;
    }

    function setProfitFee(uint256 _fee) public onlyManager {
        require(_fee <= PROFIT_FEE_CAP, "!cap");

        profitFee = _fee;
        emit NewProfitFee(_fee);
    }

    function setWithdrawalFee(uint256 _fee) public onlyManager {
        require(_fee <= WITHDRAWAL_FEE_CAP, "!cap");

        withdrawalFee = _fee;
        emit NewWithdrawalFee(_fee);
    }

    function changeFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "ZERO ADDRESS");

        feeRecipient = newFeeRecipient;
        emit NewFeeRecipient(newFeeRecipient);
    }

    function changeKeeper(address newKeeper) external onlyOwner {
        require(newKeeper != address(0), "ZERO ADDRESS");

        keeper = newKeeper;
        emit NewKeeper(newKeeper);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Timelock {
	using SafeMath for uint256;

	event NewAdmin(address indexed newAdmin);
	event NewPendingAdmin(address indexed newPendingAdmin);
	event NewDelay(uint256 indexed newDelay);
	event CancelTransaction(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);
	event ExecuteTransaction(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);
	event QueueTransaction(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);

	uint256 public constant GRACE_PERIOD = 14 days;
	uint256 public constant MINIMUM_DELAY = 0;
	uint256 public constant MAXIMUM_DELAY = 30 days;

	address public admin;
	address public pendingAdmin;
	uint256 public delay;

	mapping(bytes32 => bool) public queuedTransactions;

	constructor(address admin_, uint256 delay_) {
		require(
			delay_ >= MINIMUM_DELAY,
			"Timelock::constructor: Delay must exceed minimum delay."
		);
		require(
			delay_ <= MAXIMUM_DELAY,
			"Timelock::setDelay: Delay must not exceed maximum delay."
		);

		admin = admin_;
		delay = delay_;
	}

	receive() external payable {}

	function setDelay(uint256 delay_) public {
		require(
			msg.sender == address(this),
			"Timelock::setDelay: Call must come from Timelock."
		);
		require(
			delay_ >= MINIMUM_DELAY,
			"Timelock::setDelay: Delay must exceed minimum delay."
		);
		require(
			delay_ <= MAXIMUM_DELAY,
			"Timelock::setDelay: Delay must not exceed maximum delay."
		);
		delay = delay_;

		emit NewDelay(delay);
	}

	function acceptAdmin() public {
		require(
			msg.sender == pendingAdmin,
			"Timelock::acceptAdmin: Call must come from pendingAdmin."
		);
		admin = msg.sender;
		pendingAdmin = address(0);

		emit NewAdmin(admin);
	}

	function setPendingAdmin(address pendingAdmin_) public {
		require(
			msg.sender == address(this),
			"Timelock::setPendingAdmin: Call must come from Timelock."
		);
		pendingAdmin = pendingAdmin_;

		emit NewPendingAdmin(pendingAdmin);
	}

	function queueTransaction(
		address target,
		uint256 value,
		string memory signature,
		bytes memory data,
		uint256 eta
	) public returns (bytes32) {
		require(
			msg.sender == admin,
			"Timelock::queueTransaction: Call must come from admin."
		);
		require(
			eta >= getBlockTimestamp().add(delay),
			"Timelock::queueTransaction: Estimated execution block must satisfy delay."
		);

		bytes32 txHash = keccak256(
			abi.encode(target, value, signature, data, eta)
		);
		queuedTransactions[txHash] = true;

		emit QueueTransaction(txHash, target, value, signature, data, eta);
		return txHash;
	}

	function cancelTransaction(
		address target,
		uint256 value,
		string memory signature,
		bytes memory data,
		uint256 eta
	) public {
		require(
			msg.sender == admin,
			"Timelock::cancelTransaction: Call must come from admin."
		);

		bytes32 txHash = keccak256(
			abi.encode(target, value, signature, data, eta)
		);
		queuedTransactions[txHash] = false;

		emit CancelTransaction(txHash, target, value, signature, data, eta);
	}

	function executeTransaction(
		address target,
		uint256 value,
		string memory signature,
		bytes memory data,
		uint256 eta
	) public payable returns (bytes memory) {
		require(
			msg.sender == admin,
			"Timelock::executeTransaction: Call must come from admin."
		);

		bytes32 txHash = keccak256(
			abi.encode(target, value, signature, data, eta)
		);
		require(
			queuedTransactions[txHash],
			"Timelock::executeTransaction: Transaction hasn't been queued."
		);
		require(
			getBlockTimestamp() >= eta,
			"Timelock::executeTransaction: Transaction hasn't surpassed time lock."
		);
		require(
			getBlockTimestamp() <= eta.add(GRACE_PERIOD),
			"Timelock::executeTransaction: Transaction is stale."
		);

		queuedTransactions[txHash] = false;

		bytes memory callData;

		if (bytes(signature).length == 0) {
			callData = data;
		} else {
			callData = abi.encodePacked(
				bytes4(keccak256(bytes(signature))),
				data
			);
		}

		// solium-disable-next-line security/no-call-value
		(bool success, bytes memory returnData) = target.call{value: value}(
			callData
		);
		require(
			success,
			"Timelock::executeTransaction: Transaction execution reverted."
		);

		emit ExecuteTransaction(txHash, target, value, signature, data, eta);

		return returnData;
	}

	function getBlockTimestamp() internal view returns (uint256) {
		// solium-disable-next-line security/no-block-members
		return block.timestamp;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMasterChefDistribution {
    function setFeeAddress(address _feeAddress) external;

    function setPoolId(address _vault, uint256 _id) external;

    function updateVaultAddresses(address _vaultAddress, bool _status) external;

    function balanceOf(address _user) external returns (uint256);

    function getReward(address _user) external;

    function poolLength() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function rewardPerBlock() external view returns (uint256);

    function fund(uint256 _amount) external;

    function add(
        uint256 _allocPoint,
        IERC20 _vault,
        bool _withUpdate,
        uint16 _depositFeeBP
    ) external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function deposited(uint256 _pid, address _user) external view returns (uint256);

    function pending(uint256 _pid, address _user) external view returns (uint256);

    function getBoosts(address userAddress) external view returns (uint256);

    function vaultToPoolId(address vaultAddress) external view returns (uint256);

    function totalPending() external view returns (uint256);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function stake(address userAddress, uint256 _amount) external;

    function withdraw(address userAddress, uint256 _amount) external;

    function poolInfo(uint256 poolId)
        external
        view
        returns (
            address depositToken,
            uint allocPoint,
            uint lastRewardBlock,
            uint accERC20PerShare
        );
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
	function toInt256Safe(uint256 a) internal pure returns (int256) {
		int256 b = int256(a);
		require(b >= 0);
		return b;
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SafeMathInt
 * @dev Math operations with safety checks that revert on error
 * @dev SafeMath adapted for int256
 * Based on code of  https://github.com/RequestNetwork/requestNetwork/blob/master/packages/requestNetworkSmartContracts/contracts/base/math/SafeMathInt.sol
 */
library SafeMathInt {
	function mul(int256 a, int256 b) internal pure returns (int256) {
		// Prevent overflow when multiplying INT256_MIN with -1
		// https://github.com/RequestNetwork/requestNetwork/issues/43
		require(!(a == -2**255 && b == -1) && !(b == -2**255 && a == -1));

		int256 c = a * b;
		require((b == 0) || (c / b == a));
		return c;
	}

	function div(int256 a, int256 b) internal pure returns (int256) {
		// Prevent overflow when dividing INT256_MIN by -1
		// https://github.com/RequestNetwork/requestNetwork/issues/43
		require(!(a == -2**255 && b == -1) && (b > 0));

		return a / b;
	}

	function sub(int256 a, int256 b) internal pure returns (int256) {
		require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

		return a - b;
	}

	function add(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a + b;
		require((b >= 0 && c >= a) || (b < 0 && c < a));
		return c;
	}

	function toUint256Safe(int256 a) internal pure returns (uint256) {
		require(a >= 0);
		return uint256(a);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.4;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {FixedPointMathLib} from "../libs/FixedPointMathLib.sol";
import {IMasterChefDistribution} from "../interfaces/IMasterChefDistribution.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";

/// @title EIP-4626 Vault for Ethalend(https://ethalend.org/)
/// @author ETHA Labs
/// Based on the sample minimal implementation for Solidity in EIP-4626(https://eips.ethereum.org/EIPS/eip-4626)
contract VRC20Vault is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;
    using FixedPointMathLib for uint256;

    //////////////////////////////////////////////////////////////////
    //                          STRUCTURES                          //
    //////////////////////////////////////////////////////////////////

    struct StratCandidate {
        address implementation;
        uint256 proposedTime;
    }

    //////////////////////////////////////////////////////////////////
    //                        STATE VARIABLES                       //
    //////////////////////////////////////////////////////////////////

    /// @dev Underlying ERC20 token(asset) for the Vault
    ERC20 public immutable asset;

    /// @dev Decimals for the Vault shares
    /// Override for Openzepplin decimals value (which uses hardcoded value of 18 ¯\_(ツ)_/¯)
    uint8 private immutable _decimals;

    /// @dev MasterChef rewards distribution contract
    address public distribution;

    /// @dev Etha withdrawal fee recipient
    address public ethaFeeRecipient;

    /// @dev The last proposed strategy to switch to.
    StratCandidate public stratCandidate;

    /// @dev The strategy currently in use by the vault.
    IStrategy public strategy;

    /// @dev The minimum time it has to pass before a strat candidate can be approved.
    uint256 public immutable approvalDelay;

    /// @dev Used to calculate withdrawal fee (denominator)
    uint256 public immutable MAX_WITHDRAWAL_FEE = 10000;

    /// @dev Max value for fees
    uint256 public immutable WITHDRAWAL_FEE_CAP = 150; // 1.5%

    /// @dev Withdrawal fee for the Vault
    uint256 public withdrawalFee; //1% = 100

    /// @dev To store the timestamp of last user deposit
    mapping(address => uint256) public lastDeposited;

    /// @dev Minimum deposit period before which withdrawals are charged a penalty, default value is 0
    uint256 public minDepositPeriod;

    /// @dev Penalty for early withdrawal in basis points, added to `withdrawalFee` during withdrawals, default value is 0
    uint256 public earlyWithdrawalPenalty;

    /// @dev Address allowed to change withdrawal Fee
    address public keeper;

    //////////////////////////////////////////////////////////////////
    //                          EVENTS                              //
    //////////////////////////////////////////////////////////////////

    /// @dev Emitted when tokens are deposited into the Vault via the mint and deposit methods
    event Deposit(address indexed caller, address indexed ownerAddress, uint256 assets, uint256 shares);

    /// @dev Emitted when shares are withdrawn from the Vault in redeem or withdraw methods
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed ownerAddress,
        uint256 assets,
        uint256 shares
    );

    /// @dev Emitted when a new strategy implementation is proposed
    event NewStratCandidate(address implementation);

    /// @dev Emitted when a proposed implementation is accepted(after approaval delay) and live
    event UpgradeStrat(address implementation);

    /// @dev Emitted when the MasterChef distribution contract is updated
    event NewDistribution(address newDistribution);

    /// @dev Emitted when the withdrawal fee is updated
    event WithdrawalFeeUpdated(uint256 fee);

    /// @dev Emitted when the minimum deposit period is updated
    event MinimumDepositPeriodUpdated(uint256 minPeriod);

    /// @dev Emitted when the keeper address updated
    event NewKeeper(address newKeeper);

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        IStrategy _strategy,
        uint256 _approvalDelay,
        uint256 _withdrawalFee,
        address _ethaFeeRecipient
    ) ERC20(_name, _symbol) {
        asset = _asset;
        _decimals = _asset.decimals();
        strategy = _strategy;
        approvalDelay = _approvalDelay;
        withdrawalFee = _withdrawalFee;
        ethaFeeRecipient = _ethaFeeRecipient;
    }

    // checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == keeper, "!manager");
        _;
    }

    //////////////////////////////////////////////////////////////////
    //                  VIEW  ONLY FUNCTIONS                        //
    //////////////////////////////////////////////////////////////////

    /// @dev Overridden function for ERC20 decimals
    /// @inheritdoc ERC20
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /// @dev Returns the total amount of the underlying asset that is managed by Vault
    /// @return totalManagedAssets Assets managed by the vault
    function totalAssets() public view returns (uint256 totalManagedAssets) {
        uint256 vaultBalance = asset.balanceOf(address(this));
        uint256 strategyBalance = IStrategy(strategy).balanceOfStrategy();
        return (vaultBalance + strategyBalance);
    }

    /// @dev Function for various UIs to display the current value of one of our yield tokens.
    /// Returns an uint256 of how much underlying asset one vault share represents with decimals equal to that asset token.
    /// @return assetsPerUnitShare Asset equivalent of one vault share
    function assetsPerShare() public view returns (uint256 assetsPerUnitShare) {
        uint256 supply = totalSupply();
        if (supply == 0) {
            return 10**_decimals;
        } else {
            return ((totalAssets() * 10**_decimals) / supply);
        }
    }

    /// @dev The amount of shares that the Vault would exchange for the amount of assets provided, in an ideal scenario where all the conditions are met
    /// @param assets Amount of underlying tokens
    /// @return shares Vault shares representing equivalent deposited asset
    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        // return (assets * 10**_decimals) / assetsPerShare();
        uint256 supply = totalSupply();
        if (supply == 0) {
            shares = assets;
        } else {
            shares = assets.mulDivDown(supply, totalAssets());
        }
    }

    /// @dev The amount of assets that the Vault would exchange for the amount of shares provided, in an ideal scenario where all the conditions are met
    /// @param shares Amount of Vault shares
    /// @return assets Equivalent amount of asset tokens for shares
    function convertToAssets(uint256 shares) public view returns (uint256 assets) {
        // return (shares * assetsPerShare()) / 10**_decimals;
        uint256 supply = totalSupply();
        if (supply == 0) {
            assets = shares;
        } else {
            assets = shares.mulDivDown(totalAssets(), supply);
        }
    }

    /// @dev Returns aximum amount of the underlying asset that can be deposited into the Vault for the receiver, through a deposit call
    /// @param receiver Receiver address
    /// @return maxAssets The maximum amount of assets that can be deposited
    function maxDeposit(address receiver) public view returns (uint256 maxAssets) {
        (receiver);
        maxAssets = strategy.getMaximumDepositLimit();
    }

    /// @dev Returns aximum amount of shares that can be minted from the Vault for the receiver, through a mint call.
    /// @param receiver Receiver address
    /// @return maxShares The maximum amount of shares that can be minted
    function maxMint(address receiver) public view returns (uint256 maxShares) {
        (receiver);
        uint256 depositLimit = strategy.getMaximumDepositLimit();
        maxShares = convertToShares(depositLimit);
    }

    /// @dev Returns aximum amount of the underlying asset that can be withdrawn from the owner balance in the Vault, through a withdraw call
    /// @param ownerAddress Owner address of the shares
    /// @return maxAssets The maximum amount of assets that can be withdrawn
    function maxWithdraw(address ownerAddress) public view returns (uint256 maxAssets) {
        return convertToAssets(balanceOf(ownerAddress));
    }

    /// @dev Returns maximum amount of Vault shares that can be redeemed from the owner balance in the Vault, through a redeem call.
    /// @param ownerAddress Owner address
    /// @return maxShares The maximum amount of shares that can be minted
    function maxRedeem(address ownerAddress) public view returns (uint256 maxShares) {
        return balanceOf(ownerAddress);
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given current on-chain conditions.
    /// @param assets Amount of underlying tokens
    /// @return shares Equivalent amount of shares received on deposit
    function previewDeposit(uint256 assets) public view returns (uint256 shares) {
        return convertToShares(assets);
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given current on-chain conditions.
    /// @param shares Amount of vault tokens to mint
    /// @return assets Equivalent amount of assets required for mint
    function previewMint(uint256 shares) public view returns (uint256 assets) {
        // return (shares * assetsPerShare()) / 10**_decimals;
        uint256 supply = totalSupply();
        if (supply == 0) {
            assets = shares;
        } else {
            assets = shares.mulDivUp(totalAssets(), supply);
        }
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions.
    /// @param assets Amount of underlying tokens to withdraw
    /// @return shares Equivalent amount of shares burned during withdraw
    function previewWithdraw(uint256 assets) public view virtual returns (uint256 shares) {
        // return (assets * 10**_decimals) / assetsPerShare();
        uint256 supply = totalSupply();
        if (supply == 0) {
            shares = assets;
        } else {
            shares = assets.mulDivUp(supply, totalAssets());
        }
    }

    /// @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block, given current on-chain conditions.
    /// @param shares Amount of vault tokens to redeem
    /// @return assets Equivalent amount of assets received on redeem
    function previewRedeem(uint256 shares) public view returns (uint256 assets) {
        return convertToAssets(shares);
    }

    //////////////////////////////////////////////////////////////////
    //                       PUBLIC FUNCTIONS                       //
    //////////////////////////////////////////////////////////////////

    /// @dev Claim MasteChef distribution rewards
    function claim() public nonReentrant {
        if (distribution != address(0)) {
            IMasterChefDistribution(distribution).getReward(msg.sender);
        }
    }

    /// @dev Function to send funds into the strategy and put them to work. It's primarily called
    /// by the vault's deposit() function.
    function earn() internal {
        uint256 bal = asset.balanceOf(address(this));
        asset.safeTransfer(address(strategy), bal);
        strategy.deposit();
    }

    /// @dev Mints shares Vault shares to receiver by depositing exact amount of underlying tokens
    /// @param assets Amount of underlying token deposited to the Vault
    /// @param receiver Address that will receive the vault shares
    /// @return shares Amount of vault tokens minted for assets
    function deposit(uint256 assets, address receiver) public nonReentrant returns (uint256 shares) {
        uint256 initialPool = totalAssets();
        uint256 supply = totalSupply();
        asset.safeTransferFrom(msg.sender, address(this), assets);
        earn();
        uint256 currentPool = totalAssets();
        assets = currentPool - initialPool; // Additional check for deflationary tokens
        shares = 0;
        if (supply == 0) {
            shares = assets;
        } else {
            shares = (assets * supply) / initialPool;
        }
        if (distribution != address(0)) {
            IMasterChefDistribution(distribution).stake(receiver, shares);
        }
        _mint(receiver, shares);

        lastDeposited[receiver] = block.timestamp;
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens
    /// @param shares Amount of Vault share tokens to mint
    /// @param receiver Address that will receive the vault tokens
    /// @return assets Amount of underlying tokens used to mint shares
    function mint(uint256 shares, address receiver) public nonReentrant returns (uint256 assets) {
        assets = previewMint(shares);
        asset.safeTransferFrom(msg.sender, address(this), assets);
        earn();

        if (distribution != address(0)) {
            IMasterChefDistribution(distribution).stake(receiver, shares);
        }
        _mint(receiver, shares);

        lastDeposited[receiver] = block.timestamp;
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver
    /// @param assets Amount of underlying tokens to withdraw
    /// @param receiver Address that will receive the tokens
    /// @param ownerAddress Address that holds the share tokens
    /// @return shares Amount of share tokens burned for withdraw
    function withdraw(
        uint256 assets,
        address receiver,
        address ownerAddress
    ) public nonReentrant returns (uint256 shares) {
        shares = previewWithdraw(assets);
        if (msg.sender != ownerAddress) {
            //Checks current allowance and reverts if not enough allowance is available.
            _spendAllowance(ownerAddress, msg.sender, shares);
        }
        _burn(ownerAddress, shares);

        if (distribution != address(0)) {
            IMasterChefDistribution(distribution).withdraw(msg.sender, shares);
        }

        uint256 finalAmount = assets;
        uint256 balanceBefore = asset.balanceOf(address(this));
        if (balanceBefore < assets) {
            uint256 amountToWithdraw = assets - balanceBefore;
            strategy.withdraw(amountToWithdraw);
            uint256 balanceAfter = asset.balanceOf(address(this));
            uint256 diff = balanceAfter - balanceBefore;
            if (diff < amountToWithdraw) {
                finalAmount = balanceBefore + diff;
            }
        }
        uint256 withdrawalFeeAmount;
        if (withdrawalFee > 0) {
            if ((lastDeposited[receiver] + minDepositPeriod) < block.timestamp) {
                withdrawalFeeAmount = (finalAmount * (withdrawalFee + earlyWithdrawalPenalty)) / (MAX_WITHDRAWAL_FEE);
            } else {
                withdrawalFeeAmount = (finalAmount * withdrawalFee) / (MAX_WITHDRAWAL_FEE);
            }
        }
        asset.safeTransfer(ethaFeeRecipient, withdrawalFeeAmount);
        asset.safeTransfer(receiver, finalAmount - withdrawalFeeAmount);
        emit Withdraw(msg.sender, receiver, ownerAddress, finalAmount, shares);
    }

    /// @dev Burns exactly shares from ownerAddress and sends assets of underlying tokens to receiver
    /// @param shares Amount of share tokens to burn
    /// @param receiver Address that will receive the tokens
    /// @param ownerAddress Address that holds the share tokens
    /// @return assets Amount of underlying tokens received on redeem
    function redeem(
        uint256 shares,
        address receiver,
        address ownerAddress
    ) public nonReentrant returns (uint256 assets) {
        assets = previewRedeem(shares);
        require(assets != 0, "ZERO_ASSETS");

        if (msg.sender != ownerAddress) {
            //Checks current allowance and reverts if not enough allowance is available.
            _spendAllowance(ownerAddress, msg.sender, shares);
        }
        _burn(ownerAddress, shares);

        if (distribution != address(0)) {
            IMasterChefDistribution(distribution).withdraw(msg.sender, shares);
        }

        uint256 finalAmount = assets;
        uint256 balanceBefore = asset.balanceOf(address(this));
        if (balanceBefore < assets) {
            uint256 amountToWithdraw = assets - balanceBefore;
            strategy.withdraw(amountToWithdraw);
            uint256 balanceAfter = asset.balanceOf(address(this));
            uint256 diff = balanceAfter - balanceBefore;
            if (diff < amountToWithdraw) {
                finalAmount = balanceBefore + diff;
            }
        }
        uint256 withdrawalFeeAmount;
        if (withdrawalFee > 0) {
            if ((lastDeposited[receiver] + minDepositPeriod) < block.timestamp) {
                withdrawalFeeAmount = (finalAmount * (withdrawalFee + earlyWithdrawalPenalty)) / (MAX_WITHDRAWAL_FEE);
            } else {
                withdrawalFeeAmount = (finalAmount * withdrawalFee) / (MAX_WITHDRAWAL_FEE);
            }
        }
        asset.safeTransfer(ethaFeeRecipient, withdrawalFeeAmount);
        asset.safeTransfer(receiver, finalAmount - withdrawalFeeAmount);
        emit Withdraw(msg.sender, receiver, ownerAddress, finalAmount, shares);
    }

    //////////////////////////////////////////////////////////////////
    //                    ADMIN FUNCTIONS                           //
    //////////////////////////////////////////////////////////////////

    /// @dev Sets the candidate for the new strat to use with this vault.
    /// @param _implementation The address of the candidate strategy.
    function proposeStrat(address _implementation) external onlyOwner {
        require(address(this) == IStrategy(_implementation).vault(), "Proposal not valid for this Vault");
        stratCandidate = StratCandidate({implementation: _implementation, proposedTime: block.timestamp});

        emit NewStratCandidate(_implementation);
    }

    /// @dev It switches the active strat for the strat candidate. After upgrading, the
    /// candidate implementation is set to the 0x00 address, and proposedTime to a time
    /// happening in +100 years for safety.
    function upgradeStrat() external onlyOwner {
        require(stratCandidate.implementation != address(0), "There is no candidate");
        require((stratCandidate.proposedTime + approvalDelay) < block.timestamp, "Delay has not passed");

        emit UpgradeStrat(stratCandidate.implementation);

        strategy.retireStrat();
        strategy = IStrategy(stratCandidate.implementation);
        stratCandidate.implementation = address(0);
        stratCandidate.proposedTime = 5000000000;

        earn();
    }

    /// @dev Rescues random funds stuck that the strat can't handle.
    /// @param _token address of the token to rescue.
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        require(_token != address(asset), "!token");

        uint256 amount = ERC20(_token).balanceOf(address(this));
        ERC20(_token).safeTransfer(msg.sender, amount);
    }

    /// @dev Switches to a new MasterChef distribution contract address
    /// The parameter can be a zero address(0x00) to end the MasterChef deposit rewards
    /// @param _newDistribution updated contract address of Masterchef.
    function updateDistribution(address _newDistribution) external onlyOwner {
        distribution = _newDistribution;
        emit NewDistribution(_newDistribution);
    }

    /// @dev Update withdrawal fees for Vault, can be updated both by owner or keeper
    /// @param _fee updated withdrawal fee
    function updateWithdrawalFee(uint256 _fee) external onlyManager {
        require(_fee <= WITHDRAWAL_FEE_CAP, "WITHDRAWAL_FEE_CAP");
        withdrawalFee = _fee;
        emit WithdrawalFeeUpdated(_fee);
    }

    /// @dev Update withdrawal fees for early withdrawal penalty
    /// @param _fee Early withdrawal penalty fee in basis points
    function updateEarlyWithdrawalPenalty(uint256 _fee) external onlyManager {
        require(_fee <= WITHDRAWAL_FEE_CAP, "WITHDRAWAL_FEE_CAP");
        earlyWithdrawalPenalty = _fee;
        emit WithdrawalFeeUpdated(_fee);
    }

    /// @dev Update minimum deposit period for early withdrawal penalty
    /// @param _minPeriod Minimum deposit period
    function updateMinimumDepositPeriod(uint256 _minPeriod) external onlyManager {
        minDepositPeriod = _minPeriod;
        emit MinimumDepositPeriodUpdated(_minPeriod);
    }

    function changeKeeper(address newKeeper) external onlyOwner {
        require(newKeeper != address(0), "ZERO ADDRESS");

        keeper = newKeeper;
        emit NewKeeper(newKeeper);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import {IERC4626} from "../interfaces/IERC4626.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract GelatoCompound is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private vaults;

    uint public delay = 1 days;

    address public callFeeRecipient;

    uint maxGasPrice = 150 gwei;

    constructor() {
        callFeeRecipient = msg.sender;
    }

    function checker() external view returns (bool canExec, bytes memory execPayload) {
        for (uint256 i = 0; i < vaults.length(); i++) {
            address _vault = getVault(i);
            IStrategy strat = IStrategy(IERC4626(_vault).strategy());

            canExec = (block.timestamp >= strat.lastHarvest() + delay) && tx.gasprice <= maxGasPrice;

            if (canExec) {
                execPayload = abi.encodeWithSelector(this.harvest.selector, address(strat));
                break;
            }
        }
    }

    function harvest(IStrategy strat) external {
        try strat.harvestWithCallFeeRecipient(callFeeRecipient) {} catch {
            // If strategy does not have first fx
            strat.harvest();
        }
    }

    function getVault(uint256 index) public view returns (address) {
        return vaults.at(index);
    }

    function vaultExists(address _vault) external view returns (bool) {
        return vaults.contains(_vault);
    }

    function totalVaults() external view returns (uint256) {
        return vaults.length();
    }

    // OWNER FUNCTIONS

    function addVault(address _newVault) public onlyOwner {
        require(!vaults.contains(_newVault), "EXISTS");

        vaults.add(_newVault);
    }

    function addVaults(address[] memory _vaults) external {
        for (uint256 i = 0; i < _vaults.length; i++) {
            addVault(_vaults[i]);
        }
    }

    function removeVault(address _vault) public onlyOwner {
        require(vaults.contains(_vault), "!EXISTS");

        vaults.remove(_vault);
    }

    function removeVaults(address[] memory _vaults) external {
        for (uint256 i = 0; i < _vaults.length; i++) {
            removeVault(_vaults[i]);
        }
    }

    function setDelay(uint _delay) external onlyOwner {
        delay = _delay;
    }

    function setFeeRecipient(address _callFeeRecipient) external onlyOwner {
        callFeeRecipient = _callFeeRecipient;
    }

    function setMaxGasPrice(uint _maxGasPrice) external onlyOwner {
        maxGasPrice = _maxGasPrice;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import {IHarvester} from "../interfaces/IHarvester.sol";
import {IVault} from "../interfaces/IVault.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract GelatoVolatile is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private vaults;

    IHarvester public harvester;

    uint maxGasPrice = 150 gwei;

    function checker() external view returns (bool canExec, bytes memory execPayload) {
        uint256 delay = harvester.delay();

        for (uint256 i = 0; i < vaults.length(); i++) {
            IVault vault = IVault(getVault(i));
            canExec = (block.timestamp >= vault.lastDistribution() + delay) && tx.gasprice <= maxGasPrice;

            if (canExec) {
                execPayload = abi.encodeWithSelector(IHarvester.harvestVault.selector, address(vault));
                break;
            }
        }
    }

    function getVault(uint256 index) public view returns (address) {
        return vaults.at(index);
    }

    function vaultExists(address _vault) public view returns (bool) {
        return vaults.contains(_vault);
    }

    // OWNER FUNCTIONS

    function addVault(address _newVault) public onlyOwner {
        require(!vaults.contains(_newVault), "EXISTS");

        vaults.add(_newVault);
    }

    function addVaults(address[] memory _vaults) external {
        for (uint256 i = 0; i < _vaults.length; i++) {
            addVault(_vaults[i]);
        }
    }

    function removeVault(address _vault) public onlyOwner {
        require(vaults.contains(_vault), "!EXISTS");

        vaults.remove(_vault);
    }

    function removeVaults(address[] memory _vaults) external {
        for (uint256 i = 0; i < _vaults.length; i++) {
            removeVault(_vaults[i]);
        }
    }

    function setHarvester(IHarvester _harvester) external onlyOwner {
        harvester = _harvester;
    }

    function setMaxGasPrice(uint _maxGasPrice) external onlyOwner {
        maxGasPrice = _maxGasPrice;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IHarvester {
	function harvestVault(address vault) external;

	function delay() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IMultiFeeDistribution.sol";

contract VoteEscrow is ERC20Votes, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    struct LockedBalance {
        uint256 amount;
        uint256 end;
    }

    uint256 public constant MINDAYS = 30;
    uint256 public constant MAXDAYS = 3 * 365;

    uint256 public constant MAXTIME = MAXDAYS * 1 days; // 3 years
    uint256 public constant MAX_WITHDRAWAL_PENALTY = 50000; // 50%
    uint256 public constant PRECISION = 100000; // 5 decimals

    address public lockedToken;
    address public multiFeeDistribution;
    address public penaltyCollector;
    uint256 public minLockedAmount;
    uint256 public earlyWithdrawPenaltyRate;

    uint256 public supply;

    mapping(address => LockedBalance) public locked;
    mapping(address => uint256) public mintedForLock;

    /* =============== EVENTS ==================== */
    event Deposit(address indexed provider, uint256 value, uint256 locktime, uint256 timestamp);
    event Withdraw(address indexed provider, uint256 value, uint256 timestamp);
    event PenaltyCollectorSet(address indexed addr);
    event EarlyWithdrawPenaltySet(uint256 indexed penalty);
    event MinLockedAmountSet(uint256 indexed amount);

    constructor(
        string memory _name,
        string memory _symbol,
        address _lockedToken,
        uint256 _minLockedAmount
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        lockedToken = _lockedToken;
        minLockedAmount = _minLockedAmount;
        earlyWithdrawPenaltyRate = 30000; // 30%
    }

    function setMultiFeeDistribution(address _multiFeeDistribution) external onlyOwner {
        require(multiFeeDistribution == address(0), "VoteEscrow: the MultiFeeDistribution is already set");
        require(
            _multiFeeDistribution != address(0),
            "VoteEscrow: the MultiFeeDistribution contract can't be the address zero"
        );
        multiFeeDistribution = _multiFeeDistribution;
    }

    function create_lock(uint256 _value, uint256 _days) external {
        require(_value >= minLockedAmount, "less than min amount");
        require(locked[_msgSender()].amount == 0, "Withdraw old tokens first");
        require(_days >= MINDAYS, "Voting lock can be 7 days min");
        require(_days <= MAXDAYS, "Voting lock can be 3 years max");
        require(multiFeeDistribution != address(0), "VoteEscrow: need to be set a multi fee distribution");
        _deposit_for(_msgSender(), _value, _days);
    }

    function increase_amount(uint256 _value) external {
        require(_value >= minLockedAmount, "less than min amount");
        _deposit_for(_msgSender(), _value, 0);
    }

    function increase_unlock_time(uint256 _days) external {
        require(_days >= MINDAYS, "Voting lock can be 7 days min");
        require(_days <= MAXDAYS, "Voting lock can be 3 years max");
        _deposit_for(_msgSender(), 0, _days);
    }

    function withdraw() external nonReentrant {
        LockedBalance storage _locked = locked[_msgSender()];
        uint256 _now = block.timestamp;

        require(_locked.amount > 0, "Nothing to withdraw");
        require(_now >= _locked.end, "The lock didn't expire");
        uint256 _amount = _locked.amount;
        _locked.end = 0;
        _locked.amount = 0;
        _burn(_msgSender(), mintedForLock[_msgSender()]);

        /**
         * @dev We simulate also the withdraw for the user, so
         * you are actually withdrawing your voting power.
         */
        IMultiFeeDistribution(multiFeeDistribution).withdraw(mintedForLock[_msgSender()], _msgSender());
        mintedForLock[_msgSender()] = 0;
        IERC20(lockedToken).safeTransfer(_msgSender(), _amount);

        emit Withdraw(_msgSender(), _amount, _now);
    }

    // This will charge PENALTY if lock is not expired yet
    function emergencyWithdraw() external nonReentrant {
        LockedBalance storage _locked = locked[_msgSender()];
        uint256 _now = block.timestamp;
        require(_locked.amount > 0, "Nothing to withdraw");
        uint256 _amount = _locked.amount;
        if (_now < _locked.end) {
            uint256 _fee = _penalize(_amount);
            _amount = _amount - _fee;
        }
        _locked.end = 0;
        supply -= _locked.amount;
        _locked.amount = 0;
        _burn(_msgSender(), mintedForLock[_msgSender()]);

        /**
         * @dev We simulate also the withdraw for the user, so
         * you are actually withdrawing your voting power.
         */
        IMultiFeeDistribution(multiFeeDistribution).withdraw(mintedForLock[_msgSender()], _msgSender());

        mintedForLock[_msgSender()] = 0;

        IERC20(lockedToken).safeTransfer(_msgSender(), _amount);

        emit Withdraw(_msgSender(), _amount, _now);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMinLockedAmount(uint256 _minLockedAmount) external onlyOwner {
        minLockedAmount = _minLockedAmount;
        emit MinLockedAmountSet(_minLockedAmount);
    }

    function setEarlyWithdrawPenaltyRate(uint256 _earlyWithdrawPenaltyRate) external onlyOwner {
        require(_earlyWithdrawPenaltyRate <= MAX_WITHDRAWAL_PENALTY, "withdrawal penalty is too high"); // <= 50%
        earlyWithdrawPenaltyRate = _earlyWithdrawPenaltyRate;
        emit EarlyWithdrawPenaltySet(_earlyWithdrawPenaltyRate);
    }

    function setPenaltyCollector(address _addr) external onlyOwner {
        require(_addr != address(0), "ZERO ADDRESS");
        penaltyCollector = _addr;
        emit PenaltyCollectorSet(_addr);
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function locked__of(address _addr) external view returns (uint256) {
        return locked[_addr].amount;
    }

    function locked__end(address _addr) external view returns (uint256) {
        return locked[_addr].end;
    }

    function voting_power_unlock_time(uint256 _value, uint256 _unlockTime) public view returns (uint256) {
        uint256 _now = block.timestamp;
        if (_unlockTime <= _now) return 0;
        uint256 _lockedSeconds = _unlockTime - _now;
        if (_lockedSeconds >= MAXTIME) {
            return _value;
        }
        return (_value * _lockedSeconds) / MAXTIME;
    }

    function voting_power_locked_days(uint256 _value, uint256 _days) public pure returns (uint256) {
        if (_days >= MAXDAYS) {
            return _value;
        }
        return (_value * _days) / MAXDAYS;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _deposit_for(
        address _addr,
        uint256 _value,
        uint256 _days
    ) internal nonReentrant {
        LockedBalance storage _locked = locked[_addr];
        uint256 _now = block.timestamp;
        uint256 _amount = _locked.amount;
        uint256 _end = _locked.end;
        uint256 _vp;
        if (_amount == 0) {
            _vp = voting_power_locked_days(_value, _days);
            _locked.amount = _value;
            _locked.end = _now + _days * 1 days;
        } else if (_days == 0) {
            _vp = voting_power_unlock_time(_value, _end);
            _locked.amount = _amount + _value;
        } else {
            require(_value == 0, "Cannot increase amount and extend lock in the same time");
            _vp = voting_power_locked_days(_amount, _days);
            _locked.end = _end + _days * 1 days;
            require(_locked.end - _now <= MAXTIME, "Cannot extend lock to more than 3 years");
        }
        require(_vp > 0, "No benefit to lock");
        if (_value > 0) {
            IERC20(lockedToken).safeTransferFrom(_msgSender(), address(this), _value);
        }

        _mint(_addr, _vp);
        mintedForLock[_addr] += _vp;

        /**
         * @dev We simulate the stake for the user, so
         * you are actually staking your voting power.
         */
        IMultiFeeDistribution(multiFeeDistribution).stake(_vp, _msgSender());
        supply += _value;

        emit Deposit(_addr, _locked.amount, _locked.end, _now);
    }

    function _penalize(uint256 _amount) internal returns (uint) {
        require(penaltyCollector != address(0), "Penalty Collector is not set");
        uint256 _fee = (_amount * earlyWithdrawPenaltyRate) / PRECISION;
        IERC20(lockedToken).safeTransfer(penaltyCollector, _fee);

        return _fee;
    }

    /**
     * @dev Restricting the allowance, transfer, approve and also the transferFrom.
     */

    function allowance(address, address) public pure override returns (uint256) {
        return 0;
    }

    function transfer(address, uint256) public pure override returns (bool) {
        return false;
    }

    function approve(address, uint256) public pure override returns (bool) {
        return false;
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Votes.sol)

pragma solidity ^0.8.0;

import "./draft-ERC20Permit.sol";
import "../../../utils/math/Math.sol";
import "../../../governance/utils/IVotes.sol";
import "../../../utils/math/SafeCast.sol";
import "../../../utils/cryptography/ECDSA.sol";

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * NOTE: If exact COMP compatibility is required, use the {ERC20VotesComp} variant of this module.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 *
 * _Available since v4.2._
 */
abstract contract ERC20Votes is IVotes, ERC20Permit {
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual override returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view virtual override returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual override {
        _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= _maxSupply(), "ERC20Votes: total supply risks overflowing votes");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCast.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCast.toUint32(block.number), votes: SafeCast.toUint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMultiFeeDistribution {
    struct Reward {
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        // tracks already-added balances to handle accrued interest in aToken rewards
        // for the stakingToken this value is unused and will always be 0
        uint256 balance;
    }

    struct RewardData {
        address token;
        uint256 amount;
    }

    function stake(uint256 amount, address user) external;

    function withdraw(uint256 amount, address user) external;

    function getReward(address[] memory _rewardTokens, address user) external;

    function exit(address user) external;

    function getRewardTokens() external view returns (address[] memory);

    function rewardData(address) external view returns (Reward memory);

    function claimableRewards(address) external view returns (RewardData[] memory);

    function totalStaked() external view returns (uint);

    function balances(address) external view returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IMultiFeeDistribution.sol";

contract MultiFeeResolver {
    /**
     * @dev claim rewards from the MultiFeeDistribution.
     * @param multiFeeContract address of the contract to claim the rewards.
     * @param user address of the user to claim the rewards.
     */
    function claim(
        address multiFeeContract,
        address user,
        address[] calldata rewardTokens
    ) external {
        require(multiFeeContract != address(0), "MultiFeeLogic: multifee contract cannot be address 0");
        require(user != address(0), "MultiFeeLogic: user cannot be address 0");
        require(rewardTokens.length > 0, "MultiFeeLogic: rewardTokens should be greater than 0");

        IMultiFeeDistribution(multiFeeContract).getReward(rewardTokens, user);
    }
}

contract MultiFeeLogic is MultiFeeResolver {
    string public constant name = "MultiFeeLogic";
    uint8 public constant version = 1;

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IVotingEscrow.sol";
import "../../interfaces/IMultiFeeDistribution.sol";

import {VeEthaInfo, Rewards, Modifiers} from "./AppStorage.sol";

contract SettersFacet is Modifiers {
    function setFeeManager(address _feeManager) external onlyOwner {
        s.feeManager = _feeManager;
    }

    function setRegistry(address _ethaRegistry) external onlyOwner {
        s.ethaRegistry = _ethaRegistry;
    }

    function setPriceFeeds(address[] memory _tokens, address[] memory _feeds) external onlyOwner {
        require(_tokens.length == _feeds.length, "!LENGTH");
        for (uint256 i = 0; i < _tokens.length; i++) {
            s.priceFeeds[_tokens[i]] = _feeds[i];
        }
    }

    function setCurvePool(address[] memory lpTokens, address[] memory pools) external onlyOwner {
        require(lpTokens.length == pools.length, "!LENGTH");
        for (uint256 i = 0; i < lpTokens.length; i++) {
            s.curvePools[lpTokens[i]] = pools[i];
        }
    }

    function setCreamTokens(address[] memory _tokens, address[] memory _crTokens) external onlyOwner {
        require(_tokens.length == _crTokens.length, "!LENGTH");
        for (uint256 i = 0; i < _tokens.length; i++) {
            s.crTokens[_tokens[i]] = _crTokens[i];
        }
    }
}

// SPDX-License-Identifier: MIT

// Standard Curvefi voting escrow interface
// We want to use a standard iface to allow compatibility
pragma solidity ^0.8.0;

interface IVotingEscrow {
    // Following are used in Fee distribution contracts e.g.
    /*
        https://etherscan.io/address/0x74c6cade3ef61d64dcc9b97490d9fbb231e4bdcc#code
    */
    // struct Point {
    //     int128 bias;
    //     int128 slope;
    //     uint256 ts;
    //     uint256 blk;
    // }

    // function user_point_epoch(address addr) external view returns (uint256);

    // function epoch() external view returns (uint256);

    // function user_point_history(address addr, uint256 loc) external view returns (Point);

    // function checkpoint() external;

    /*
    https://etherscan.io/address/0x2e57627ACf6c1812F99e274d0ac61B786c19E74f#readContract
    */
    // Gauge proxy requires the following. inherit from ERC20
    // balanceOf
    // totalSupply

    function deposit_for(address _addr, uint256 _value) external;

    function create_lock(uint256 _value, uint256 _unlock_time) external;

    function increase_amount(uint256 _value) external;

    function increase_unlock_time(uint256 _unlock_time) external;

    function withdraw() external;

    function emergencyWithdraw() external;

    // Extra required views
    function balanceOf(address) external view returns (uint256);

    function supply() external view returns (uint256);

    function minLockedAmount() external view returns (uint256);

    function earlyWithdrawPenaltyRate() external view returns (uint256);

    function MINDAYS() external view returns (uint256);

    function MAXDAYS() external view returns (uint256);

    function MAXTIME() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function locked(address) external view returns (uint256, uint256);

    function delegates(address account) external view returns (address);

    function lockedToken() external view returns (address);

    function penaltyCollector() external view returns (address);

    function multiFeeDistribution() external view returns (address);

    function delegate(address delegatee) external;

    function locked__of(address _addr) external view returns (uint256);

    function locked__end(address _addr) external view returns (uint256);

    function voting_power_unlock_time(uint256 _value, uint256 _unlockTime) external view returns (uint256);

    function voting_power_locked_days(uint256 _value, uint256 _days) external pure returns (uint256);

    // function transferOwnership(address addr) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IVotingEscrow} from "./interfaces/IVotingEscrow.sol";

// Farm distributes the ERC20 rewards based on staked LP to each user.
//
// Cloned from https://github.com/0xlaozi/qidao/blob/main/contracts/StakingRewards.sol
// Modified by Ethalend to work for non-mintable ERC20.
contract MasterChefDistribution is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of ERC20s
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accERC20PerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accERC20PerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 vaultAddress; // Address of vault contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. ERC20s to distribute per block.
        uint256 lastRewardBlock; // Last block number that ERC20s distribution occurs.
        uint256 accERC20PerShare; // Accumulated ERC20s per share, times 1e12.
        uint256 totalStaked; // Amount of tokens "staked" in the pool
    }

    // Address of the ERC20 Token contract.
    IERC20 public rewardsToken;
    // The total amount of ERC20 that's paid out as reward.
    uint256 public paidOut = 0;
    // ERC20 tokens rewarded per block.
    uint256 public rewardPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The block number when farming starts.
    uint256 public startBlock;
    // The block number when farming ends.
    uint256 public endBlock;
    // vote escrow ETHA token
    address public veToken;
    // Mapping to maintain list of approved eVaults
    mapping(address => bool) public approvedVaults;

    // The current boost multiplier
    uint8 public boostMultiplier = 1;

    // The max amount of ETHA tokens to reward boosts
    uint256 public maxBoostedRewards;

    // Remaining ETHA tokens for Boosted rewards
    uint256 public boostedRewardsSpent;

    // Vault Address to Pool ID
    mapping(address => uint256) public vaultToPoolId;

    modifier onlyVault() {
        require(approvedVaults[msg.sender], "Only approved eVAULTs");
        _;
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateVaultAddress(address indexed vault, bool status);
    event UpdateVoteEscrowToken(address indexed oldAddress, address indexed newAddress);
    event UpdateMaxBoostedRewards(uint256 maxAmount);

    event FundVault(address indexed funder, uint256 amount, uint256 endBlock);

    constructor(
        IERC20 _rewardsToken,
        address _veToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _maxBoostedRewards
    ) {
        rewardsToken = _rewardsToken;
        veToken = _veToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        endBlock = _startBlock;
        maxBoostedRewards = _maxBoostedRewards;
    }

    function setMaxBoostedRewards(uint256 _maxBoostedRewards) external onlyOwner {
        maxBoostedRewards = _maxBoostedRewards;
        emit UpdateMaxBoostedRewards(_maxBoostedRewards);
    }

    function setPoolId(address _vault, uint256 _id) public onlyOwner {
        require(approvedVaults[_vault], "Invalid vault");
        vaultToPoolId[_vault] = _id;
    }

    function updateVaultAddresses(address _vaultAddress, bool _status) public onlyOwner {
        require(_vaultAddress != address(0), "Invalid vault");
        approvedVaults[_vaultAddress] = _status;
        emit UpdateVaultAddress(_vaultAddress, _status);
    }

    // Update veToken address
    function updateVoteEscrowToken(address _veTokenAddress) external onlyOwner {
        require(_veTokenAddress != address(0), "Invalid address");
        emit UpdateVoteEscrowToken(veToken, _veTokenAddress);
        veToken = _veTokenAddress;
    }

    function balanceOf(address _user) public view onlyVault returns (uint256) {
        uint256 pid = vaultToPoolId[msg.sender];
        return userInfo[pid][_user].amount;
    }

    // Can only be called by Vault as withdraw has onlyVault modifier
    function getReward(address _user) public {
        withdraw(_user, 0);
    }

    // Number of LP pools
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Fund the farm, increase the end block
    function fund(uint256 _amount) public onlyOwner {
        require(block.number < endBlock, "fund: too late, the farm is closed");

        rewardsToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        endBlock += _amount / rewardPerBlock;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _vault,
        bool _withUpdate
    ) public onlyOwner {
        require(address(_vault) != address(0), "!ZERO ADDRESS");

        // Check if vault already added, when poolId is 0. First pool will be 0, but none exists by that point
        require(vaultToPoolId[address(_vault)] == 0, "EXISTS");

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + (_allocPoint);

        // Mark the new vault as approved and set vault ID
        updateVaultAddresses(address(_vault), true);
        vaultToPoolId[address(_vault)] = poolInfo.length;

        poolInfo.push(
            PoolInfo({
                vaultAddress: _vault,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accERC20PerShare: 0,
                totalStaked: 0
            })
        );
    }

    // Update the given pool's ERC20 allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - (poolInfo[_pid].allocPoint) + (_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Update the boosts multiplier
    function setBoostMultiplier(uint8 _multiplier) external onlyOwner {
        boostMultiplier = _multiplier;
    }

    // View function to see deposited LP for a user.
    function deposited(uint256 _pid, address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        return user.amount;
    }

    // View function to see pending ERC20s for a user.
    function pending(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accERC20PerShare = pool.accERC20PerShare;
        uint256 lpSupply = pool.vaultAddress.totalSupply();

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 lastBlock = block.number < endBlock ? block.number : endBlock;
            uint256 nrOfBlocks = lastBlock - (pool.lastRewardBlock);
            uint256 erc20Reward = (nrOfBlocks * (rewardPerBlock) * (pool.allocPoint)) / (totalAllocPoint);
            accERC20PerShare = accERC20PerShare + ((erc20Reward * (1e12)) / (lpSupply));
        }

        return (user.amount * (accERC20PerShare)) / (1e12) - (user.rewardDebt);
    }

    // View function to see pending ERC20s for a user.
    function getPendingRewards(uint256 _pid, address _user)
        public
        view
        returns (uint256 pendingAmount, uint256 pendingAmountWithBoost)
    {
        pendingAmount = pending(_pid, _user);
        uint256 userBoost = getBoosts(_user);
        pendingAmountWithBoost = (userBoost * pendingAmount) / 1e12;
    }

    // Returns the boosts a user gets by locking ETHA tokens times 1e12
    function getBoosts(address userAddress) public view returns (uint256) {
        if (maxBoostedRewards <= boostedRewardsSpent) {
            return 1e12;
        }
        IVotingEscrow voteEscrow = IVotingEscrow(veToken);
        uint256 userBalance = voteEscrow.balanceOf(userAddress);
        if (userBalance == 0) return 0;

        uint256 lockEnd = voteEscrow.locked__end(userAddress);
        if (lockEnd < block.timestamp) return 0;

        uint256 boost = (userBalance * (lockEnd - block.timestamp) * 1e12) /
            (voteEscrow.totalSupply() * voteEscrow.MAXTIME());

        return (1e12 + boostMultiplier * boost);
    }

    // View function to see pending ERC20s for a user with boosts
    function pendingWithBoost(uint256 _pid, address _user) external view returns (uint256) {
        uint256 pendingRewards = pending(_pid, _user);
        uint256 userBoost = getBoosts(_user);
        return (userBoost * pendingRewards) / 1e12;
    }

    // View function for total reward the farm has yet to pay out.
    function totalPending() external view returns (uint256) {
        if (block.number <= startBlock) {
            return 0;
        }

        uint256 lastBlock = block.number < endBlock ? block.number : endBlock;
        return rewardPerBlock * (lastBlock - startBlock) - (paidOut);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lastBlock = block.number < endBlock ? block.number : endBlock;

        if (lastBlock <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.vaultAddress.totalSupply();

        if (lpSupply == 0) {
            pool.lastRewardBlock = lastBlock;
            return;
        }

        uint256 nrOfBlocks = lastBlock - (pool.lastRewardBlock);
        uint256 erc20Reward = (nrOfBlocks * (rewardPerBlock) * (pool.allocPoint)) / (totalAllocPoint);
        pool.accERC20PerShare = pool.accERC20PerShare + ((erc20Reward * (1e12)) / (lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to Farm for ERC20 allocation.
    function stake(address userAddress, uint256 _amount) public nonReentrant onlyVault {
        uint256 _pid = vaultToPoolId[msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][userAddress];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pendingAmount = (user.amount * (pool.accERC20PerShare)) / (1e12) - (user.rewardDebt);
            uint256 pendingAmountWithBoost = (getBoosts(userAddress) * pendingAmount) / 1e12;
            if (pendingAmountWithBoost > pendingAmount) {
                boostedRewardsSpent = boostedRewardsSpent + (pendingAmountWithBoost - pendingAmount);
                erc20Transfer(userAddress, pendingAmountWithBoost);
            }
        }

        if (_amount > 0) {
            user.amount = user.amount + _amount;
        }
        user.rewardDebt = (user.amount * (pool.accERC20PerShare)) / (1e12);
        pool.totalStaked += _amount;
        emit Deposit(userAddress, _pid, _amount);
    }

    // Withdraw LP tokens from Farm.
    function withdraw(address userAddress, uint256 _amount) public nonReentrant onlyVault {
        uint256 _pid = vaultToPoolId[msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][userAddress];
        require(user.amount >= _amount, "withdraw: can't withdraw more than deposit");
        updatePool(_pid);
        uint256 pendingAmount = (user.amount * (pool.accERC20PerShare)) / (1e12) - (user.rewardDebt);
        uint256 pendingAmountWithBoost = (getBoosts(userAddress) * pendingAmount) / 1e12;

        if (pendingAmountWithBoost > pendingAmount) {
            boostedRewardsSpent = boostedRewardsSpent + (pendingAmountWithBoost - pendingAmount);
            erc20Transfer(userAddress, pendingAmountWithBoost);
        }
        user.amount = user.amount - (_amount);
        user.rewardDebt = (user.amount * (pool.accERC20PerShare)) / (1e12);
        pool.totalStaked -= _amount;
        emit Withdraw(userAddress, _pid, _amount);
    }

    /// @dev Rescues funds stuck only after end block
    /// @param _token address of the token to rescue.
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        require(block.timestamp > endBlock, "!endBlock");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(owner(), amount);
    }

    // Transfer ERC20 and update the required ERC20 to payout all rewards
    function erc20Transfer(address _to, uint256 _amount) internal {
        rewardsToken.transfer(_to, _amount);
        paidOut += _amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {UniversalERC20} from "../../libs/UniversalERC20.sol";
import {IUniswapV2Router} from "../../interfaces/IUniswapV2Router.sol";
import {IUniswapV2ERC20} from "../../interfaces/IUniswapV2ERC20.sol";
import {IQiStakingRewards} from "../../interfaces/IQiStakingRewards.sol";
import {IERC20StablecoinQi} from "../../interfaces/IERC20StablecoinQi.sol";
import {IDelegateRegistry} from "../../interfaces/IDelegateRegistry.sol";

import {CompoundStratManager} from "../../vaults/compounded/CompoundStratManager.sol";
import {CompoundFeeManager} from "../../vaults/compounded/CompoundFeeManager.sol";

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {SimpleMockOracle} from "../oracles/SimpleMockOracle.sol";

contract MockStrategyQiVault is CompoundStratManager, CompoundFeeManager, ReentrancyGuard {
    using UniversalERC20 for IERC20;

    // Mock Aggregator Oracle
    SimpleMockOracle mockTokenOracle;

    // Tokens used
    IERC20 public assetToken; // Final tokens that are deposited to Qi vault: eg. BAL, camWMATIC, camWETH, LINK, etc.
    IERC20 public mai = IERC20(0xa3Fa99A148fA48D14Ed51d610c367C61876997F1); // mai token
    IERC20 public qiToken = IERC20(0x580A84C73811E1839F75d86d75d88cCa0c241fF4); //qi token

    // QiDao addresses
    IERC20StablecoinQi qiVault; // Qi Vault for Asset token
    address public qiVaultAddress; // Qi vault for asset token
    address public qiStakingRewards; //0x574Fe4E8120C4Da1741b5Fd45584de7A5b521F0F for Qi staking rewards masterchef contract
    uint256 public qiVaultId; // Vault ID

    // LP tokens and Swap paths
    address public lpToken0; //WMATIC
    address public lpToken1; //QI
    address public lpPairToken; //LP Pair token address

    address[] public maiToLp0; // MAI to WMATIC token
    address[] public maiToLp1; // MAI to QI token
    address[] public lp0ToMai; // LP0(WMATIC) to MAI
    address[] public lp1ToMai; // LP1(QI) to MAI
    address[] public lp0ToAsset; //LP0(WMATIC) to Deposit token swap Path
    address[] public lp1ToAsset; //LP1(QI) to Deposit token swap Path

    // Config variables
    uint256 public qiRewardsPid = 4; // Staking rewards pool id for WMATIC-QI
    address public qiDelegationContract;

    // Chainlink Price Feed
    mapping(address => address) public priceFeeds;

    uint256 public SAFE_COLLAT_LOW = 180;
    uint256 public SAFE_COLLAT_TARGET = 200;
    uint256 public SAFE_COLLAT_HIGH = 220;

    // Events
    event VoterUpdated(address indexed voter);
    event DelegationContractUpdated(address indexed delegationContract);
    event SwapPathUpdated(address[] previousPath, address[] updatedPath);
    event StrategyRetired(address indexed stragegyAddress);
    event Harvested(address indexed harvester);
    event VaultRebalanced();

    constructor(
        address _assetToken,
        address _qiVaultAddress,
        address _lpToken0,
        address _lpToken1,
        address _lpPairToken,
        address _qiStakingRewards,
        address _keeper,
        address _strategist,
        address _unirouter,
        address _ethaFeeRecipient
    ) CompoundStratManager(_keeper, _strategist, _unirouter, _ethaFeeRecipient) {
        assetToken = IERC20(_assetToken);
        qiVaultAddress = _qiVaultAddress;
        lpToken0 = _lpToken0;
        lpToken1 = _lpToken1;
        lpPairToken = _lpPairToken;
        qiStakingRewards = _qiStakingRewards;

        qiVault = IERC20StablecoinQi(qiVaultAddress);
        qiVaultId = qiVault.createVault();
        require(qiVault.exists(qiVaultId), "ERR: Vault does not exists");
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////      Internal functions      //////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Returns the total supply and market of LP
    /// @dev Will work only if price oracle for either one of the lp tokens is set
    /// @return lpTotalSupply Total supply of LP tokens
    /// @return totalMarketUSD Total market in USD of LP tokens
    function _getLPTotalMarketUSD() internal view returns (uint256 lpTotalSupply, uint256 totalMarketUSD) {
        uint256 market0;
        uint256 market1;

        //// Using Price Feeds
        int256 price0;
        int256 price1;

        IUniswapV2ERC20 pair = IUniswapV2ERC20(lpPairToken);
        lpTotalSupply = pair.totalSupply();
        (uint112 _reserve0, uint112 _reserve1, ) = pair.getReserves();

        if (priceFeeds[lpToken0] != address(0)) {
            (, price0, , , ) = AggregatorV3Interface(priceFeeds[lpToken0]).latestRoundData();
            market0 = (uint256(_reserve0) * uint256(price0)) / (10**8);
        }
        if (priceFeeds[lpToken1] != address(0)) {
            (, price1, , , ) = AggregatorV3Interface(priceFeeds[lpToken1]).latestRoundData();
            market1 = (uint256(_reserve1) * uint256(price1)) / (10**8);
        }

        if (market0 == 0) {
            totalMarketUSD = 2 * market1;
        } else if (market1 == 0) {
            totalMarketUSD = 2 * market0;
        } else {
            totalMarketUSD = market0 + market1;
        }
        require(totalMarketUSD > 0, "ERR: Price Feed");
    }

    /// @notice Returns the LP amount equivalent of assetAmount
    /// @param assetAmount Amount of asset tokens for which equivalent LP tokens need to be calculated
    /// @return lpAmount USD equivalent of assetAmount in LP tokens
    function _getLPTokensFromAsset(uint256 assetAmount) internal view returns (uint256 lpAmount) {
        (uint256 lpTotalSupply, uint256 totalMarketUSD) = _getLPTotalMarketUSD();
        uint256 ethPriceSource = mockTokenOracle.latestAnswer(); // Asset token price
        require(ethPriceSource > 0, "ERR: Invalid data from price source");

        // Calculations
        // usdEquivalentOfEachLp = (totalMarketUSD / totalSupply);
        // usdEquivalentOfAsset = assetAmount * ethPriceSource;
        // lpAmount = usdEquivalentOfAsset / usdEquivalentOfEachLp
        lpAmount = (assetAmount * ethPriceSource * lpTotalSupply) / (totalMarketUSD * 10**8);

        // Return additional 10% of the required LP tokens to account for slippage and future withdrawals
        lpAmount = (lpAmount * 110) / 100;
    }

    /// @notice Deposits the asset token to QiVault from balance of this contract
    /// @notice Asset tokens must be transferred to the contract first before calling this function
    /// @param depositAmount AMount to be deposited to Qi Vault
    function _depositToQiVault(uint256 depositAmount) internal {
        // Deposit to QiDao vault
        assetToken.universalApprove(qiVaultAddress, depositAmount);
        IERC20StablecoinQi(qiVaultAddress).depositCollateral(qiVaultId, depositAmount);
    }

    /// @notice Borrows safe amount of MAI tokens from Qi Vault
    function _borrowTokens() internal {
        uint256 currentCollateralPercent = qiVault.checkCollateralPercentage(qiVaultId);
        require(currentCollateralPercent > SAFE_COLLAT_TARGET, "ERR: SAFE_COLLAT_TARGET");

        uint256 amountToBorrow = safeAmountToBorrow();
        qiVault.borrowToken(qiVaultId, amountToBorrow);

        uint256 updatedCollateralPercent = qiVault.checkCollateralPercentage(qiVaultId);
        require(updatedCollateralPercent >= SAFE_COLLAT_LOW, "ERR: SAFE_COLLAT_LOW");
        require(!qiVault.checkLiquidation(qiVaultId), "ERR: LIQUIDATION");
    }

    /// @notice Repay MAI debt back to the qiVault
    function _repayMaiDebt() internal {
        uint256 maiDebt = qiVault.vaultDebt(qiVaultId);
        uint256 maiBalance = mai.balanceOf(address(this));

        if (maiDebt > maiBalance) {
            mai.universalApprove(qiVaultAddress, maiBalance);
            qiVault.payBackToken(qiVaultId, maiBalance);
        } else {
            mai.universalApprove(qiVaultAddress, maiDebt);
            qiVault.payBackToken(qiVaultId, maiDebt);
        }
    }

    /// @notice Swaps MAI for lpToken0 and lpToken 1 and adds liquidity to the AMM
    function _swapMaiAndAddLiquidity() internal {
        uint256 maiBalance = mai.balanceOf(address(this));
        uint256 outputHalf = maiBalance / 2;

        mai.universalApprove(unirouter, maiBalance);

        IUniswapV2Router(unirouter).swapExactTokensForTokens(outputHalf, 0, maiToLp0, address(this), block.timestamp);
        IUniswapV2Router(unirouter).swapExactTokensForTokens(outputHalf, 0, maiToLp1, address(this), block.timestamp);

        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));

        IERC20(lpToken0).universalApprove(unirouter, lp0Bal);
        IERC20(lpToken1).universalApprove(unirouter, lp1Bal);

        IUniswapV2Router(unirouter).addLiquidity(lpToken0, lpToken1, lp0Bal, lp1Bal, 1, 1, address(this), block.timestamp);
    }

    /// @notice Deposits LP tokens to QiStaking Farm (MasterChef contract)
    /// @param amountToDeposit Amount of LP tokens to deposit to Farm
    function _depositLPToFarm(uint256 amountToDeposit) internal {
        IERC20(lpPairToken).universalApprove(qiStakingRewards, amountToDeposit);
        IQiStakingRewards(qiStakingRewards).deposit(qiRewardsPid, amountToDeposit);
    }

    /// @notice Withdraw LP tokens from QiStaking Farm and removes liquidity from AMM
    /// @param withdrawAmount Amount of LP tokens to withdraw from Farm and AMM
    function _withdrawLpAndRemoveLiquidity(uint256 withdrawAmount) internal {
        IQiStakingRewards(qiStakingRewards).withdraw(qiRewardsPid, withdrawAmount);
        uint256 lpBalance = IERC20(lpPairToken).balanceOf(address(this));
        IERC20(lpPairToken).universalApprove(address(unirouter), lpBalance);
        IUniswapV2Router(unirouter).removeLiquidity(lpToken0, lpToken1, lpBalance, 1, 1, address(this), block.timestamp);
    }

    /// @notice Delegate Qi voting power to another address
    /// @param id   The delegate ID
    /// @param voter Address to delegate the votes to
    function _delegateVotingPower(bytes32 id, address voter) internal {
        IDelegateRegistry(qiDelegationContract).setDelegate(id, voter);
    }

    /// @notice Withdraws assetTokens from the Vault
    /// @param amountToWithdraw  Amount of assetTokens to withdraw from the vault
    function _withdrawFromVault(uint256 amountToWithdraw) internal {
        uint256 vaultCollateral = qiVault.vaultCollateral(qiVaultId);

        require(amountToWithdraw > 0, "ERR: Invalid amount");
        require(vaultCollateral >= amountToWithdraw, "ERR: Amount too high");

        uint256 safeWithdrawAmount = safeAmountToWithdraw();

        if (safeWithdrawAmount > amountToWithdraw) {
            // Withdraw collateral completely from qiVault
            qiVault.withdrawCollateral(qiVaultId, amountToWithdraw);
            require(qiVault.checkCollateralPercentage(qiVaultId) >= SAFE_COLLAT_LOW, "ERR: SAFE_COLLAT_LOW");
            assetToken.universalTransfer(msg.sender, amountToWithdraw);
            return;
        } else {
            // Withdraw partially from qiVault and remaining from LP
            uint256 amountFromQiVault = safeWithdrawAmount;
            uint256 amountFromLP = amountToWithdraw - safeWithdrawAmount;

            //1. Withdraw from qi Vault
            if (amountFromQiVault > 0) {
                qiVault.withdrawCollateral(qiVaultId, amountFromQiVault);
                require(qiVault.checkCollateralPercentage(qiVaultId) >= SAFE_COLLAT_LOW, "ERR: SAFE_COLLAT_LOW");
            }

            //2. Withdraw from LP
            uint256 lpAmount = _getLPTokensFromAsset(amountFromLP);
            _withdrawLpAndRemoveLiquidity(lpAmount);

            //3. Swap WMATIC tokens for asset tokens
            uint256 lp0Balance = IERC20(lpToken0).balanceOf(address(this));
            IERC20(lpToken0).universalApprove(address(unirouter), lp0Balance);
            IUniswapV2Router(unirouter).swapExactTokensForTokens(lp0Balance, 1, lp0ToAsset, address(this), block.timestamp);

            //4. Swap Qi tokens for asset tokens
            uint256 lp1Balance = IERC20(lpToken1).balanceOf(address(this));
            IERC20(lpToken1).universalApprove(address(unirouter), lp1Balance);
            IUniswapV2Router(unirouter).swapExactTokensForTokens(lp1Balance, 1, lp1ToAsset, address(this), block.timestamp);
            assetToken.universalTransfer(msg.sender, amountToWithdraw);
        }
    }

    /// @notice Charge Strategist and Performance fees
    /// @param callFeeRecipient Address to send the callFee (if set)
    function _chargeFees(address callFeeRecipient) internal {
        uint256 assetBal = assetToken.balanceOf(address(this));

        uint256 totalFee = (assetBal * profitFee) / MAX_FEE;
        uint256 callFeeAmount;
        uint256 strategistFeeAmount;

        if (callFee > 0) {
            callFeeAmount = (totalFee * callFee) / MAX_FEE;
            assetToken.universalTransfer(callFeeRecipient, callFeeAmount);
            emit CallFeeCharged(callFeeRecipient, callFeeAmount);
        }

        if (strategistFee > 0) {
            strategistFeeAmount = (totalFee * strategistFee) / MAX_FEE;
            assetToken.universalTransfer(strategist, strategistFeeAmount);
            emit StrategistFeeCharged(strategist, strategistFeeAmount);
        }

        uint256 ethaFeeAmount = (totalFee - callFeeAmount - strategistFeeAmount);
        assetToken.universalTransfer(ethaFeeRecipient, ethaFeeAmount);
        emit ProtocolFeeCharged(ethaFeeRecipient, ethaFeeAmount);
    }

    /// @notice Harvest the rewards earned by Vault for more collateral tokens
    /// @param callFeeRecipient Address to send the callFee (if set)
    function _harvest(address callFeeRecipient) internal {
        //1. Claim accrued Qi rewards from LP farm
        _depositLPToFarm(0);

        //2. Swap Qi tokens for asset tokens
        uint256 qiBalance = qiToken.balanceOf(address(this));
        qiToken.universalApprove(unirouter, qiBalance);
        IUniswapV2Router(unirouter).swapExactTokensForTokens(qiBalance, 1, lp1ToAsset, address(this), block.timestamp);

        //3. Charge performance fee and deposit to Qi vault
        _chargeFees(callFeeRecipient);
        uint256 assetBalance = assetToken.balanceOf(address(this));
        _depositToQiVault(assetBalance);

        emit Harvested(msg.sender);
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////      Admin functions      ///////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Delegate Qi voting power to another address
    /// @param _id   The delegate ID
    /// @param _voter Address to delegate the votes to
    function delegateVotes(bytes32 _id, address _voter) external onlyOwner {
        _delegateVotingPower(_id, _voter);
        emit VoterUpdated(_voter);
    }

    /// @notice Updates the delegation contract for Qi token Lock
    /// @param _delegationContract Updated delegation contract address
    function updateQiDelegationContract(address _delegationContract) external onlyOwner {
        require(_delegationContract != address(0), "Invalid address");
        qiDelegationContract = _delegationContract;
        emit DelegationContractUpdated(_delegationContract);
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateMaiToLp0(address[] memory _swapPath) external onlyOwner {
        require(_swapPath.length > 1);
        emit SwapPathUpdated(maiToLp0, _swapPath);
        maiToLp0 = _swapPath;
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateMaiToLp1(address[] memory _swapPath) external onlyOwner {
        require(_swapPath.length > 1);
        emit SwapPathUpdated(maiToLp1, _swapPath);
        maiToLp1 = _swapPath;
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateLp0ToMai(address[] memory _swapPath) external onlyOwner {
        require(_swapPath.length > 1);
        emit SwapPathUpdated(lp0ToMai, _swapPath);
        lp0ToMai = _swapPath;
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateLp1ToMai(address[] memory _swapPath) external onlyOwner {
        require(_swapPath.length > 1);
        emit SwapPathUpdated(lp1ToMai, _swapPath);
        lp1ToMai = _swapPath;
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateLp0ToAsset(address[] memory _swapPath) external onlyOwner {
        require(_swapPath.length > 1);
        emit SwapPathUpdated(lp0ToAsset, _swapPath);
        lp0ToAsset = _swapPath;
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateLp1ToAsset(address[] memory _swapPath) external onlyOwner {
        require(_swapPath.length > 1);
        emit SwapPathUpdated(lp1ToAsset, _swapPath);
        lp1ToAsset = _swapPath;
    }

    /// @notice Update Qi Rewards Pool ID for Qi MasterChef contract
    /// @param _pid Pool ID
    function updateQiRewardsPid(uint256 _pid) external onlyOwner {
        qiRewardsPid = _pid;
    }

    /// @notice Set Chainlink price feed for LP tokens
    /// @param _token Token for which price feed needs to be set
    /// @param _feed Address of Chainlink price feed
    function setPriceFeed(address _token, address _feed) external onlyOwner {
        priceFeeds[_token] = _feed;
    }

    /// @notice Set mock oracle for token price
    /// @param _oracle Address of price feed
    function setMockTokenOracle(address _oracle) external onlyOwner {
        mockTokenOracle = SimpleMockOracle(_oracle);
    }

    /// @notice Repay Debt by liquidating LP tokens
    /// Should be used to repay MAI debt before strategy migration
    /// @param _lpAmount Amount of LP tokens to liquidate
    function repayDebtLp(uint256 _lpAmount) external onlyOwner {
        //1. Withdraw LP tokens from Farm and remove liquidity
        _withdrawLpAndRemoveLiquidity(_lpAmount);

        uint256 lp0Balance = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Balance = IERC20(lpToken1).balanceOf(address(this));
        IERC20(lpToken0).universalApprove(address(unirouter), lp0Balance);
        IERC20(lpToken1).universalApprove(address(unirouter), lp1Balance);

        //2. Swap LP tokens for MAI tokens
        IUniswapV2Router(unirouter).swapExactTokensForTokens(lp0Balance, 1, lp0ToMai, address(this), block.timestamp);
        IUniswapV2Router(unirouter).swapExactTokensForTokens(lp1Balance, 1, lp1ToMai, address(this), block.timestamp);

        //3. Repay Debt to qiVault
        _repayMaiDebt();
    }

    /// @dev Rescues random funds stuck that the strat can't handle.
    /// @param _token address of the token to rescue.
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        require(_token != address(assetToken), "!token");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).universalTransfer(msg.sender, amount);
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////      External functions      /////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Returns the total supply and market of LP
    /// @dev Will work only if price oracle for either one of the lp tokens is set
    /// @return lpSupply Total supply of LP tokens
    /// @return totalMarketUSD Total market in USD of LP tokens
    function getLPTotalMarketUSD() public view returns (uint256 lpSupply, uint256 totalMarketUSD) {
        (lpSupply, totalMarketUSD) = _getLPTotalMarketUSD();
    }

    /// @notice Returns the safe amount to borrow from qiVault considering Debt and Collateral
    /// @return amountToBorrow Safe amount of MAI to borrow from vault
    function safeAmountToBorrow() public view returns (uint256 amountToBorrow) {
        uint256 tokenPriceSource = qiVault.getTokenPriceSource(); // MAI token price
        uint256 ethPriceSource = mockTokenOracle.latestAnswer(); // Asset token price
        require(ethPriceSource > 0, "ERR: Invalid data from price source");
        require(tokenPriceSource > 0, "ERR: Invalid data from price source");

        uint256 currentDebtValue = qiVault.vaultDebt(qiVaultId) * tokenPriceSource;

        uint256 collateralValueTimes100 = qiVault.vaultCollateral(qiVaultId) * ethPriceSource * 100;
        uint256 targetDebtValue = collateralValueTimes100 / SAFE_COLLAT_TARGET;

        amountToBorrow = (targetDebtValue - currentDebtValue) / (tokenPriceSource);
    }

    /// @notice Returns the safe amount to withdraw from qiVault considering Debt and Collateral
    /// @return amountToWithdraw Safe amount of assetTokens to withdraw from vault
    function safeAmountToWithdraw() public view returns (uint256 amountToWithdraw) {
        uint256 ethPriceSource = mockTokenOracle.latestAnswer();
        uint256 tokenPriceSource = qiVault.getTokenPriceSource();
        require(ethPriceSource > 0, "ERR: Invalid data from price source");
        require(tokenPriceSource > 0, "ERR: Invalid data from price source");

        uint256 currentCollateral = qiVault.vaultCollateral(qiVaultId);
        uint256 debtValue = qiVault.vaultDebt(qiVaultId) * tokenPriceSource;

        uint256 collateralValue = ((SAFE_COLLAT_LOW + 1) * debtValue) / 100;
        uint256 amountCollateral = collateralValue / ethPriceSource;
        amountToWithdraw = currentCollateral - amountCollateral;
    }

    /// @notice Returns the safe Debt for collateral(passed as argument) from qiVault
    /// @param collateral Amount of collateral tokens for which safe Debt is to be calculated
    /// @return safeDebt Safe amount of MAI than can be borrowed from qiVault
    function safeDebtForCollateral(uint256 collateral) public view returns (uint256 safeDebt) {
        uint256 ethPriceSource = mockTokenOracle.latestAnswer();
        uint256 tokenPriceSource = qiVault.getTokenPriceSource();
        require(ethPriceSource > 0, "ERR: Invalid data from price source");
        require(tokenPriceSource > 0, "ERR: Invalid data from price source");

        uint256 safeDebtValue = (collateral * ethPriceSource * 100) / SAFE_COLLAT_TARGET;

        safeDebt = safeDebtValue / tokenPriceSource;
    }

    /// @notice Returns the safe collateral for debt(passed as argument) from qiVault
    /// @param debt Amount of MAI tokens for which safe collateral is to be calculated
    /// @return safeCollateral Safe amount of collateral tokens for qiVault
    function safeCollateralForDebt(uint256 debt) public view returns (uint256 safeCollateral) {
        uint256 ethPriceSource = mockTokenOracle.latestAnswer();
        uint256 tokenPriceSource = qiVault.getTokenPriceSource();
        require(ethPriceSource > 0, "ERR: Invalid data from price source");
        require(tokenPriceSource > 0, "ERR: Invalid data from price source");

        uint256 collateralValue = (SAFE_COLLAT_TARGET * debt * tokenPriceSource) / 100;
        safeCollateral = collateralValue / ethPriceSource;
    }

    /// @notice Deposits the asset token to QiVault from balance of this contract
    /// @dev Asset tokens must be transferred to the contract first before calling this function
    function deposit() public nonReentrant whenNotPaused {
        uint256 depositAmount = assetToken.balanceOf(address(this));
        _depositToQiVault(depositAmount);

        //Check CDR ratio, if below 220% don't borrow, else borrow
        uint256 cdr_percent = qiVault.checkCollateralPercentage(qiVaultId);
        uint256 currentCollateral = qiVault.vaultCollateral(qiVaultId);

        if (cdr_percent > SAFE_COLLAT_HIGH) {
            _borrowTokens();
            _swapMaiAndAddLiquidity();

            uint256 lpAmount = IERC20(lpPairToken).balanceOf(address(this));
            _depositLPToFarm(lpAmount);
        } else if (cdr_percent == 0 && currentCollateral != 0) {
            // Note: Special case for initial deposit(as CDR is returned 0 when Debt is 0)
            // Borrow 1 wei to initialize
            qiVault.borrowToken(qiVaultId, 1);
        }
    }

    /// @notice Withdraw deposited tokens from the Vault
    function withdraw(uint256 withdrawAmount) public nonReentrant whenNotPaused {
        _withdrawFromVault(withdrawAmount);
    }

    /// @notice Harvest the rewards earned by Vault for more assetTokens
    function harvest() external virtual {
        _harvest(tx.origin);
    }

    /// @notice Harvest the rewards earned by Vault passing external callFeeRecipient
    /// @param callFeeRecipient Address that receives the callfee
    function harvestWithCallFeeRecipient(address callFeeRecipient) external virtual {
        _harvest(callFeeRecipient);
    }

    /// @notice Harvest the rewards earned by Vault, can only be called by Strategy Manager
    function managerHarvest() external onlyManager {
        _harvest(tx.origin);
    }

    /// @notice Rebalances the vault to a safe Collateral to Debt ratio
    /// @dev If Collateral to Debt ratio is below SAFE_COLLAT_LOW,
    /// then -> Withdraw lpAmount from Farm > Remove liquidity from LP > swap Qi for WMATIC > Deposit WMATIC to vault
    // If CDR is greater than SAFE_COLLAT_HIGH,
    /// then -> Borrow more MAI > Swap for Qi and WMATIC > Deposit to Quickswap LP > Deposit to Qi Farm
    function rebalanceVault(bool _shouldRepay) public nonReentrant whenNotPaused {
        uint256 cdr_percent = qiVault.checkCollateralPercentage(qiVaultId);

        if (cdr_percent < SAFE_COLLAT_TARGET) {
            // Get amount of LP tokens to sell for asset tokens
            uint256 vaultCollateral = qiVault.vaultCollateral(qiVaultId);
            uint256 vaultDebt = qiVault.vaultDebt(qiVaultId);

            uint256 safeCollateral = safeCollateralForDebt(vaultDebt);
            uint256 collateralRequired = safeCollateral - vaultCollateral;
            uint256 lpAmount = _getLPTokensFromAsset(collateralRequired);

            //1. Withdraw LP tokens from Farm and remove liquidity
            _withdrawLpAndRemoveLiquidity(lpAmount);

            uint256 lp0Balance = IERC20(lpToken0).balanceOf(address(this));
            uint256 lp1Balance = IERC20(lpToken1).balanceOf(address(this));
            IERC20(lpToken0).universalApprove(address(unirouter), lp0Balance);
            IERC20(lpToken1).universalApprove(address(unirouter), lp1Balance);

            if (_shouldRepay) {
                //2. Swap LP tokens for MAI tokens
                IUniswapV2Router(unirouter).swapExactTokensForTokens(
                    lp0Balance,
                    1,
                    lp0ToMai,
                    address(this),
                    block.timestamp
                );
                IUniswapV2Router(unirouter).swapExactTokensForTokens(
                    lp1Balance,
                    1,
                    lp1ToMai,
                    address(this),
                    block.timestamp
                );

                //3. Repay Debt to qiVault
                _repayMaiDebt();
            } else {
                //2. Swap LP tokens for asset tokens
                IUniswapV2Router(unirouter).swapExactTokensForTokens(
                    lp0Balance,
                    1,
                    lp0ToAsset,
                    address(this),
                    block.timestamp
                );
                //3. Swap LP tokens for asset tokens
                IUniswapV2Router(unirouter).swapExactTokensForTokens(
                    lp1Balance,
                    1,
                    lp1ToAsset,
                    address(this),
                    block.timestamp
                );

                //3. Deposit amount to qiVault
                uint256 assetBalance = assetToken.balanceOf(address(this));
                _depositToQiVault(assetBalance);
            }

            //4. Check updated CDR and verify
            uint256 updated_cdr = qiVault.checkCollateralPercentage(qiVaultId);
            require(updated_cdr >= SAFE_COLLAT_TARGET, "Improper lpAmount");
        } else if (cdr_percent > SAFE_COLLAT_HIGH) {
            //1. Borrow tokens
            _borrowTokens();

            //2. Swap and add liquidity
            _swapMaiAndAddLiquidity();

            //3. Deposit LP to farm
            uint256 amountToDeposit = IERC20(lpPairToken).balanceOf(address(this));
            _depositLPToFarm(amountToDeposit);
        } else {
            revert("Vault collateral ratio already within limits");
        }
        emit VaultRebalanced();
    }

    /// @notice Repay MAI debt back to the qiVault
    /// @dev The sender must have sufficient allowance and balance
    function repayDebt(uint256 amount) public nonReentrant {
        mai.universalTransferFrom(msg.sender, address(this), amount);
        _repayMaiDebt();
    }

    /// @notice calculate the total underlying 'want' held by the strat
    /// @dev This is equivalent to the amount of assetTokens deposited in the QiDAO vault
    function balanceOfStrategy() public view returns (uint256 strategyBalance) {
        strategyBalance = qiVault.vaultCollateral(qiVaultId) + assetToken.balanceOf(address(this));
    }

    /// @notice called as part of strat migration. Sends all the available funds back to the vault.
    /// NOTE: All QiVault debt must be paid before this function is called
    function retireStrat() external nonReentrant {
        require(msg.sender == vault, "!vault");
        uint256 maiDebt = qiVault.vaultDebt(qiVaultId);
        require(maiDebt == 0, "ERR: Please repay Debt first");

        // Withdraw asset token balance from vault and strategy
        uint256 vaultCollateral = qiVault.vaultCollateral(qiVaultId);
        qiVault.withdrawCollateral(qiVaultId, vaultCollateral);

        uint256 assetBalance = assetToken.balanceOf(address(this));
        assetToken.universalTransfer(vault, assetBalance);

        // Withdraw LP balance from staking rewards
        IQiStakingRewards qiStaking = IQiStakingRewards(qiStakingRewards);
        uint256 lpBalance = qiStaking.deposited(qiRewardsPid, address(this));
        if (lpBalance > 0) {
            qiStaking.withdraw(qiRewardsPid, lpBalance);
            IERC20(lpPairToken).universalTransfer(vault, lpBalance);
        }

        emit StrategyRetired(address(this));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library UniversalERC20 {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	IERC20 private constant ZERO_ADDRESS =
		IERC20(0x0000000000000000000000000000000000000000);
	IERC20 private constant ETH_ADDRESS =
		IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

	function universalTransfer(
		IERC20 token,
		address to,
		uint256 amount
	) internal returns (bool success) {
		if (amount == 0) {
			return true;
		}

		if (isETH(token)) {
			payable(to).transfer(amount);
		} else {
			token.safeTransfer(to, amount);
			return true;
		}
	}

	function universalTransferFrom(
		IERC20 token,
		address from,
		address to,
		uint256 amount
	) internal {
		if (amount == 0) {
			return;
		}

		if (isETH(token)) {
			require(
				from == msg.sender && msg.value >= amount,
				"Wrong useage of ETH.universalTransferFrom()"
			);
			if (to != address(this)) {
				payable(to).transfer(amount);
			}
			if (msg.value > amount) {
				payable(msg.sender).transfer(msg.value.sub(amount));
			}
		} else {
			token.safeTransferFrom(from, to, amount);
		}
	}

	function universalTransferFromSenderToThis(IERC20 token, uint256 amount)
		internal
	{
		if (amount == 0) {
			return;
		}

		if (isETH(token)) {
			if (msg.value > amount) {
				// Return remainder if exist
				payable(msg.sender).transfer(msg.value.sub(amount));
			}
		} else {
			token.safeTransferFrom(msg.sender, address(this), amount);
		}
	}

	function universalApprove(
		IERC20 token,
		address to,
		uint256 amount
	) internal {
		if (!isETH(token)) {
			if (amount == 0) {
				token.safeApprove(to, 0);
				return;
			}

			uint256 allowance = token.allowance(address(this), to);
			if (allowance < amount) {
				if (allowance > 0) {
					token.safeApprove(to, 0);
				}
				token.safeApprove(to, amount);
			}
		}
	}

	function universalBalanceOf(IERC20 token, address who)
		internal
		view
		returns (uint256)
	{
		if (isETH(token)) {
			return who.balance;
		} else {
			return token.balanceOf(who);
		}
	}

	function universalDecimals(IERC20 token) internal view returns (uint256) {
		if (isETH(token)) {
			return 18;
		}

		(bool success, bytes memory data) =
			address(token).staticcall{gas: 10000}(
				abi.encodeWithSignature("decimals()")
			);
		if (!success || data.length == 0) {
			(success, data) = address(token).staticcall{gas: 10000}(
				abi.encodeWithSignature("DECIMALS()")
			);
		}

		return (success && data.length > 0) ? abi.decode(data, (uint256)) : 18;
	}

	function isETH(IERC20 token) internal pure returns (bool) {
		return (address(token) == address(ZERO_ADDRESS) ||
			address(token) == address(ETH_ADDRESS));
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function getAmountsOut(uint256 amountIn, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	)
		external
		returns (
			uint256 amountA,
			uint256 amountB,
			uint256 liquidity
		);

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2ERC20 {
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function name() external pure returns (string memory);

	function symbol() external pure returns (string memory);

	function decimals() external pure returns (uint8);

	function totalSupply() external view returns (uint256);

	function getReserves()
		external
		view
		returns (
			uint112 _reserve0,
			uint112 _reserve1,
			uint32 _blockTimestampLast
		);

	function balanceOf(address owner) external view returns (uint256);

	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool);

	function DOMAIN_SEPARATOR() external view returns (bytes32);

	function PERMIT_TYPEHASH() external pure returns (bytes32);

	function nonces(address owner) external view returns (uint256);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	function token0() external view returns (address);

	function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQiStakingRewards {
	//Public Variables
	function totalAllocPoint() external view returns (uint256);

	function rewardPerBlock() external view returns (uint256);

	function endBlock() external view returns (uint256);

	function poolInfo(uint256)
		external
		view
		returns (
			address lpToken,
			uint256 allocPoint,
			uint256 lastRewardBlock,
			uint256 accERC20PerShare,
			uint256 depositFeeBP
		);

	function userInfo(uint256 poolId, address user)
		external
		view
		returns (uint256 amount, uint256 rewardDebt);

	// View function to see deposited LP for a user.
	function deposited(uint256 _pid, address _user)
		external
		view
		returns (uint256);

	// Deposit LP tokens to Farm for ERC20 allocation.
	function deposit(uint256 _pid, uint256 _amount) external;

	// Withdraw LP tokens from Farm.
	function withdraw(uint256 _pid, uint256 _amount) external;

	//Pending rewards for an user
	function pending(uint256 _pid, address _user)
		external
		view
		returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20StablecoinQi {
    function _minimumCollateralPercentage() external returns (uint256);

    function vaultCollateral(uint256) external view returns (uint256);

    function vaultDebt(uint256) external view returns (uint256);

    function debtRatio() external returns (uint256);

    function gainRatio() external returns (uint256);

    function collateral() external view returns (address);

    function collateralDecimals() external returns (uint256);

    function maticDebt(address) external returns (uint256);

    function mai() external view returns (address);

    function getDebtCeiling() external view returns (uint256);

    function exists(uint256 vaultID) external view returns (bool);

    function getClosingFee() external view returns (uint256);

    function getOpeningFee() external view returns (uint256);

    function getTokenPriceSource() external view returns (uint256);

    function getEthPriceSource() external view returns (uint256);

    function createVault() external returns (uint256);

    function destroyVault(uint256 vaultID) external;

    function depositCollateral(uint256 vaultID, uint256 amount) external;

    function withdrawCollateral(uint256 vaultID, uint256 amount) external;

    function borrowToken(uint256 vaultID, uint256 amount) external;

    function payBackToken(uint256 vaultID, uint256 amount) external;

    function getPaid() external;

    function checkCost(uint256 vaultID) external view returns (uint256);

    function checkExtract(uint256 vaultID) external view returns (uint256);

    function checkCollateralPercentage(uint256 vaultID) external view returns (uint256);

    function checkLiquidation(uint256 vaultID) external view returns (bool);

    function liquidateVault(uint256 vaultID) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IDelegateRegistry {
    function delegation(address delegator, bytes32 id) external returns (address delegate);

    function setDelegate(bytes32 id, address delegate) external;

    function clearDelegate(bytes32 id) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract CompoundStratManager is Ownable, Pausable {
    /**
     * @dev ETHA Contracts:
     * {keeper} - Address to manage a few lower risk features of the strat
     * {strategist} - Address of the strategy author/deployer where strategist fee will go.
     * {vault} - Address of the vault that controls the strategy's funds.
     * {unirouter} - Address of exchange to execute swaps.
     */
    address public keeper;
    address public strategist;
    address public unirouter;
    address public vault;
    address public ethaFeeRecipient;

    /**
     * @dev Initializes the base strategy.
     * @param _keeper address to use as alternative owner.
     * @param _strategist address where strategist fees go.
     * @param _unirouter router to use for swaps
     * @param _ethaFeeRecipient address where to send Etha's fees.
     */
    constructor(
        address _keeper,
        address _strategist,
        address _unirouter,
        address _ethaFeeRecipient
    ) {
        keeper = _keeper;
        strategist = _strategist;
        unirouter = _unirouter;
        ethaFeeRecipient = _ethaFeeRecipient;

        _pause(); // until strategy is set;
    }

    // checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == keeper, "!manager");
        _;
    }

    // checks that caller is vault contract.
    modifier onlyVault() {
        require(msg.sender == vault, "!vault");
        _;
    }

    /**
     * @dev Updates address of the strat keeper.
     * @param _keeper new keeper address.
     */
    function setKeeper(address _keeper) external onlyOwner {
        require(_keeper != address(0), "!ZERO ADDRESS");
        keeper = _keeper;
    }

    /**
     * @dev Updates address where strategist fee earnings will go.
     * @param _strategist new strategist address.
     */
    function setStrategist(address _strategist) external {
        require(_strategist != address(0), "!ZERO ADDRESS");
        require(msg.sender == strategist, "!strategist");
        strategist = _strategist;
    }

    /**
     * @dev Updates router that will be used for swaps.
     * @param _unirouter new unirouter address.
     */
    function setUnirouter(address _unirouter) external onlyOwner {
        require(_unirouter != address(0), "!ZERO ADDRESS");
        unirouter = _unirouter;
    }

    /**
     * @dev Updates parent vault.
     * @param _vault new vault address.
     */
    function setVault(address _vault) external onlyOwner {
        require(_vault != address(0), "!ZERO ADDRESS");
        require(vault == address(0), "vault already set");
        vault = _vault;
        _unpause();
    }

    /**
     * @dev Updates etja fee recipient.
     * @param _ethaFeeRecipient new etha fee recipient address.
     */
    function setEthaFeeRecipient(address _ethaFeeRecipient) external onlyOwner {
        require(_ethaFeeRecipient != address(0), "!ZERO ADDRESS");
        ethaFeeRecipient = _ethaFeeRecipient;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./CompoundStratManager.sol";

abstract contract CompoundFeeManager is CompoundStratManager {
    // Used to calculate final fee (denominator)
    uint256 public constant MAX_FEE = 10000;
    // Max value for fees
    uint256 public constant STRATEGIST_FEE_CAP = 2500; // 25% of profitFee
    uint256 public constant CALL_FEE_CAP = 1000; // 10% of profitFee
    uint256 public constant PROFIT_FEE_CAP = 3000; // 30% of profits

    // Initial fee values
    uint256 public strategistFee = 2500; // 25% of profitFee so 20% * 25% => 5% of profit
    uint256 public callFee = 0;
    uint256 public profitFee = 2000; // 20% of profits harvested. Etha fee is 20% - strat and call fee %

    // Events to be emitted when fees are charged
    event CallFeeCharged(address indexed callFeeRecipient, uint256 callFeeAmount);
    event StrategistFeeCharged(address indexed strategist, uint256 strategistFeeAmount);
    event ProtocolFeeCharged(address indexed ethaFeeRecipient, uint256 protocolFeeAmount);
    event NewProfitFee(uint256 fee);
    event NewCallFee(uint256 fee);
    event NewStrategistFee(uint256 fee);
    event NewFeeRecipient(address newFeeRecipient);

    function setProfitFee(uint256 _fee) public onlyManager {
        require(_fee <= PROFIT_FEE_CAP, "!cap");

        profitFee = _fee;
        emit NewProfitFee(_fee);
    }

    function setCallFee(uint256 _fee) public onlyManager {
        require(_fee <= CALL_FEE_CAP, "!cap");

        callFee = _fee;
        emit NewCallFee(_fee);
    }

    function setStrategistFee(uint256 _fee) public onlyManager {
        require(_fee <= STRATEGIST_FEE_CAP, "!cap");

        strategistFee = _fee;
        emit NewStrategistFee(_fee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleMockOracle {
  uint256 public s_answer;

  function setLatestAnswer(uint256 answer) public {
    s_answer = answer;
  }

  function latestAnswer() public view returns (uint256) {
    return s_answer;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {LibError} from "../../../../libs/LibError.sol";
import "../../CompoundStrat.sol";

// Interfaces
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router} from "../../../../interfaces/IUniswapV2Router.sol";
import {IUniswapV2ERC20} from "../../../../interfaces/IUniswapV2ERC20.sol";
import {IQiStakingRewards} from "../../../../interfaces/IQiStakingRewards.sol";
import {IERC20StablecoinQi} from "../../../../interfaces/IERC20StablecoinQi.sol";
import {IDelegateRegistry} from "../../../../interfaces/IDelegateRegistry.sol";
import {IVGHST} from "../../../../interfaces/IVGHST.sol";

contract StrategyQiVaultVGHST is CompoundStrat {
    using SafeERC20 for IERC20;
    using SafeERC20 for IVGHST;

    // Address whitelisted to rebalance strategy
    address public rebalancer;

    // Tokens used
    IVGHST public assetToken; // vGHST
    IERC20 public mai = IERC20(0xa3Fa99A148fA48D14Ed51d610c367C61876997F1); // mai token
    IERC20 public qiToken = IERC20(0x580A84C73811E1839F75d86d75d88cCa0c241fF4); //qi token
    IERC20 public ghst = IERC20(0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7); //ghst token

    // QiDao addresses
    IERC20StablecoinQi public qiVault; // Qi Vault for Asset token
    address public qiStakingRewards; // 0xFFD2AA58Cca3A44120aaA42CEA2852348A9c2eA6 for Qi staking rewards masterchef contract
    uint256 public qiVaultId; // Vault ID

    // LP tokens and Swap paths
    address public lpToken0; //WMATIC
    address public lpToken1; //QI
    address public lpPairToken; //LP Pair token address

    address[] public assetToMai; // AssetToken to MAI
    address[] public maiToAsset; // Mai to AssetToken
    address[] public qiToAsset; // Rewards token to AssetToken
    address[] public maiToLp0; // MAI to WMATIC token
    address[] public maiToLp1; // MAI to QI token
    address[] public lp0ToMai; // LP0(WMATIC) to MAI
    address[] public lp1ToMai; // LP1(QI) to MAI

    // Config variables
    uint256 public lpFactor = 5;
    uint256 public qiRewardsPid = 1; // Staking rewards pool id for WMATIC-QI
    address public qiDelegationContract;

    // Chainlink Price Feed
    mapping(address => address) public priceFeeds;

    uint256 public SAFE_COLLAT_LOW = 180;
    uint256 public SAFE_COLLAT_TARGET = 200;
    uint256 public SAFE_COLLAT_HIGH = 220;

    // Events
    event VoterUpdated(address indexed voter);
    event DelegationContractUpdated(address indexed delegationContract);
    event SwapPathUpdated(address[] previousPath, address[] updatedPath);
    event StrategyRetired(address indexed stragegyAddress);
    event Harvested(address indexed harvester);
    event VaultRebalanced();

    constructor(
        address _assetToken,
        address _qiVaultAddress,
        address _lpPairToken,
        address _qiStakingRewards,
        address _keeper,
        address _strategist,
        address _unirouter,
        address _ethaFeeRecipient
    ) CompoundStratManager(_keeper, _strategist, _unirouter, _ethaFeeRecipient) {
        assetToken = IVGHST(_assetToken);
        lpPairToken = _lpPairToken;
        qiStakingRewards = _qiStakingRewards;

        // For Compound Strat
        want = _assetToken;
        output = address(qiToken);
        native = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270); //WMATIC

        lpToken0 = IUniswapV2ERC20(lpPairToken).token0();
        lpToken1 = IUniswapV2ERC20(lpPairToken).token1();

        qiVault = IERC20StablecoinQi(_qiVaultAddress);
        qiVaultId = qiVault.createVault();
        if (!qiVault.exists(qiVaultId)) {
            revert LibError.QiVaultError();
        }
        _giveAllowances();
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////      Internal functions      //////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////

    /// @dev Provides token allowances to Unirouter, QiVault and Qi MasterChef contract
    function _giveAllowances() internal {
        // Asset Token approvals
        assetToken.safeApprove(address(qiVault), 0);
        assetToken.safeApprove(address(qiVault), type(uint256).max);

        // GHST Token Approvals
        ghst.safeApprove(address(assetToken), 0);
        ghst.safeApprove(address(assetToken), type(uint256).max);

        ghst.safeApprove(unirouter, 0);
        ghst.safeApprove(unirouter, type(uint256).max);

        // Rewards token approval
        qiToken.safeApprove(unirouter, 0);
        qiToken.safeApprove(unirouter, type(uint256).max);

        // MAI token approvals
        mai.safeApprove(address(qiVault), 0);
        mai.safeApprove(address(qiVault), type(uint256).max);

        mai.safeApprove(unirouter, 0);
        mai.safeApprove(unirouter, type(uint256).max);

        // LP Token approvals
        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, type(uint256).max);

        IERC20(lpToken1).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, type(uint256).max);

        IERC20(lpPairToken).safeApprove(qiStakingRewards, 0);
        IERC20(lpPairToken).safeApprove(qiStakingRewards, type(uint256).max);

        IERC20(lpPairToken).safeApprove(unirouter, 0);
        IERC20(lpPairToken).safeApprove(unirouter, type(uint256).max);
    }

    /// @dev Revoke token allowances
    function _removeAllowances() internal {
        // Asset Token approvals
        assetToken.safeApprove(address(qiVault), 0);

        // Rewards token approval
        qiToken.safeApprove(unirouter, 0);

        // GHST token approvals
        ghst.safeApprove(address(assetToken), 0);
        ghst.safeApprove(unirouter, 0);

        // MAI token approvals
        mai.safeApprove(address(qiVault), 0);
        mai.safeApprove(unirouter, 0);

        // LP Token approvals
        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, 0);
        IERC20(lpPairToken).safeApprove(qiStakingRewards, 0);
        IERC20(lpPairToken).safeApprove(unirouter, 0);
    }

    function _swap(uint256 amount, address[] memory swapPath) internal {
        if (swapPath.length > 1) {
            IUniswapV2Router(unirouter).swapExactTokensForTokens(amount, 0, swapPath, address(this), block.timestamp);
        } else {
            revert LibError.InvalidSwapPath();
        }
    }

    function _getContractBalance(address token) internal view returns (uint256 tokenBalance) {
        return IERC20(token).balanceOf(address(this));
    }

    /// @notice Returns the total supply and market of LP
    /// @dev Will work only if price oracle for either one of the lp tokens is set
    /// @return lpTotalSupply Total supply of LP tokens
    /// @return totalMarketUSD Total market in USD of LP tokens
    function _getLPTotalMarketUSD() internal view returns (uint256 lpTotalSupply, uint256 totalMarketUSD) {
        uint256 market0;
        uint256 market1;

        //// Using Price Feeds
        int256 price0;
        int256 price1;

        IUniswapV2ERC20 pair = IUniswapV2ERC20(lpPairToken);
        lpTotalSupply = pair.totalSupply();
        (uint112 _reserve0, uint112 _reserve1, ) = pair.getReserves();

        if (priceFeeds[lpToken0] != address(0)) {
            (, price0, , , ) = AggregatorV3Interface(priceFeeds[lpToken0]).latestRoundData();
            market0 = (uint256(_reserve0) * uint256(price0)) / (10**8);
        }
        if (priceFeeds[lpToken1] != address(0)) {
            (, price1, , , ) = AggregatorV3Interface(priceFeeds[lpToken1]).latestRoundData();
            market1 = (uint256(_reserve1) * uint256(price1)) / (10**8);
        }

        if (market0 == 0) {
            totalMarketUSD = 2 * market1;
        } else if (market1 == 0) {
            totalMarketUSD = 2 * market0;
        } else {
            totalMarketUSD = market0 + market1;
        }
        if (totalMarketUSD == 0) revert LibError.PriceFeedError();
    }

    /// @notice Returns the LP amount equivalent of assetAmount
    /// @param assetAmount Amount of asset tokens for which equivalent LP tokens need to be calculated
    /// @return lpAmount USD equivalent of assetAmount in LP tokens
    function _getLPTokensFromAsset(uint256 assetAmount) internal view returns (uint256 lpAmount) {
        (uint256 lpTotalSupply, uint256 totalMarketUSD) = _getLPTotalMarketUSD();

        // Calculations
        // usdEquivalentOfEachLp = (totalMarketUSD / totalSupply);
        // usdEquivalentOfAsset = assetAmount * AssetTokenPrice;
        // lpAmount = usdEquivalentOfAsset / usdEquivalentOfEachLp
        lpAmount = (assetAmount * getAssetTokenPrice() * lpTotalSupply) / (totalMarketUSD * 10**8);

        // Return additional amount(currently 110%) of the required LP tokens to account for slippage and future withdrawals
        lpAmount = (lpAmount * (100 + lpFactor)) / 100;

        // If calculated amount is greater than total deposited, withdraw everything
        uint256 totalLp = getStrategyLpDeposited();
        if (lpAmount > totalLp) {
            lpAmount = totalLp;
        }
    }

    /// @notice Returns the LP amount equivalent of maiAmount
    /// @param maiAmount Amount of asset tokens for which equivalent LP tokens need to be calculated
    /// @return lpAmount USD equivalent of maiAmount in LP tokens
    function _getLPTokensFromMai(uint256 maiAmount) internal view returns (uint256 lpAmount) {
        (uint256 lpTotalSupply, uint256 totalMarketUSD) = _getLPTotalMarketUSD();

        // Calculations
        // usdEquivalentOfEachLp = (totalMarketUSD / totalSupply);
        // usdEquivalentOfAsset = assetAmount * ethPriceSource;
        // lpAmount = usdEquivalentOfAsset / usdEquivalentOfEachLp
        lpAmount = (maiAmount * getMaiTokenPrice() * lpTotalSupply) / (totalMarketUSD * 10**8);

        // Return additional amount(currently 110%) of the required LP tokens to account for slippage and future withdrawals
        lpAmount = (lpAmount * (100 + lpFactor)) / 100;

        // If calculated amount is greater than total deposited, withdraw everything
        uint256 totalLp = getStrategyLpDeposited();
        if (lpAmount > totalLp) {
            lpAmount = totalLp;
        }
    }

    /// @notice Deposits the asset token to QiVault from balance of this contract
    /// @notice Asset tokens must be transferred to the contract first before calling this function
    /// @param depositAmount AMount to be deposited to Qi Vault
    function _depositToQiVault(uint256 depositAmount) internal {
        // Deposit to QiDao vault
        qiVault.depositCollateral(qiVaultId, depositAmount);
    }

    /// @notice Borrows safe amount of MAI tokens from Qi Vault
    function _borrowTokens() internal {
        uint256 currentCollateralPercent = getCollateralPercent();
        if (currentCollateralPercent <= SAFE_COLLAT_TARGET && currentCollateralPercent != 0) {
            revert LibError.InvalidCDR(currentCollateralPercent, SAFE_COLLAT_TARGET);
        }

        uint256 amountToBorrow = safeAmountToBorrow();
        qiVault.borrowToken(qiVaultId, amountToBorrow);

        uint256 updatedCollateralPercent = getCollateralPercent();
        if (updatedCollateralPercent < SAFE_COLLAT_LOW && updatedCollateralPercent != 0) {
            revert LibError.InvalidCDR(updatedCollateralPercent, SAFE_COLLAT_LOW);
        }

        if (qiVault.checkLiquidation(qiVaultId)) revert LibError.LiquidationRisk();
    }

    /// @notice Repay MAI debt back to the qiVault
    function _repayMaiDebt() internal {
        uint256 maiDebt = getStrategyDebt();
        uint256 maiBalance = _getContractBalance(address(mai));

        if (maiDebt > maiBalance) {
            qiVault.payBackToken(qiVaultId, maiBalance);
        } else {
            qiVault.payBackToken(qiVaultId, maiDebt);
            _swap(_getContractBalance(address(mai)), maiToAsset);
            assetToken.enter(_getContractBalance(address(ghst)));
        }
    }

    /// @notice Swaps MAI for lpToken0 and lpToken 1 and adds liquidity to the AMM
    function _swapMaiAndAddLiquidity() internal {
        uint256 outputHalf = _getContractBalance(address(mai)) / 2;

        _swap(outputHalf, maiToLp0);
        _swap(outputHalf, maiToLp1);

        uint256 lp0Bal = _getContractBalance(lpToken0);
        uint256 lp1Bal = _getContractBalance(lpToken1);

        IUniswapV2Router(unirouter).addLiquidity(lpToken0, lpToken1, lp0Bal, lp1Bal, 1, 1, address(this), block.timestamp);

        lp0Bal = _getContractBalance(lpToken0);
        lp1Bal = _getContractBalance(lpToken1);
    }

    /// @notice Deposits LP tokens to QiStaking Farm (MasterChef contract)
    /// @param amountToDeposit Amount of LP tokens to deposit to Farm
    function _depositLPToFarm(uint256 amountToDeposit) internal {
        IQiStakingRewards(qiStakingRewards).deposit(qiRewardsPid, amountToDeposit);
    }

    /// @notice Withdraw LP tokens from QiStaking Farm and removes liquidity from AMM
    /// @param withdrawAmount Amount of LP tokens to withdraw from Farm and AMM
    function _withdrawLpAndRemoveLiquidity(uint256 withdrawAmount) internal {
        IQiStakingRewards(qiStakingRewards).withdraw(qiRewardsPid, withdrawAmount);
        uint256 lpBalance = _getContractBalance(lpPairToken);
        IUniswapV2Router(unirouter).removeLiquidity(lpToken0, lpToken1, lpBalance, 1, 1, address(this), block.timestamp);
    }

    /// @notice Delegate Qi voting power to another address
    /// @param id   The delegate ID
    /// @param voter Address to delegate the votes to
    function _delegateVotingPower(bytes32 id, address voter) internal {
        IDelegateRegistry(qiDelegationContract).setDelegate(id, voter);
    }

    /// @notice Withdraws assetTokens from the Vault
    /// @param amountToWithdraw  Amount of assetTokens to withdraw from the vault
    function _withdrawFromVault(uint256 amountToWithdraw) internal {
        uint256 vaultCollateral = getStrategyCollateral();
        uint256 safeWithdrawAmount = safeAmountToWithdraw();

        if (amountToWithdraw == 0) revert LibError.InvalidAmount(0, 1);
        if (amountToWithdraw > vaultCollateral) revert LibError.InvalidAmount(amountToWithdraw, vaultCollateral);

        // Repay Debt from LP if required
        if (safeWithdrawAmount < amountToWithdraw) {
            // Debt is 50% of value of asset tokens when SAFE_COLLAT_TARGET = 200 (i.e 100/200 => 0.5)
            uint256 amountFromLP = ((amountToWithdraw - safeWithdrawAmount) * (100 + 10)) / SAFE_COLLAT_TARGET;

            //Withdraw from LP and repay debt
            uint256 lpAmount = _getLPTokensFromAsset(amountFromLP);
            _repayDebtLp(lpAmount);
        }

        // Calculate Max withdraw amount after repayment
        // console.log("Minimum collateral percent: ", qiVault._minimumCollateralPercentage());
        uint256 minimumCdr = qiVault._minimumCollateralPercentage() + 10;
        uint256 stratDebt = getStrategyDebt();
        uint256 maxWithdrawAmount = vaultCollateral - safeCollateralForDebt(stratDebt, minimumCdr);

        if (amountToWithdraw < maxWithdrawAmount) {
            // Withdraw collateral completely from qiVault
            qiVault.withdrawCollateral(qiVaultId, amountToWithdraw);
            assetToken.safeTransfer(msg.sender, amountToWithdraw);

            uint256 collateralPercent = getCollateralPercent();
            if (collateralPercent < SAFE_COLLAT_LOW) {
                // Rebalance from collateral
                rebalanceVault(false);
            }
            collateralPercent = getCollateralPercent();
            uint256 minCollateralPercent = qiVault._minimumCollateralPercentage();
            if (collateralPercent < minCollateralPercent && collateralPercent != 0) {
                revert LibError.InvalidCDR(collateralPercent, minCollateralPercent);
            }
        } else {
            revert LibError.InvalidAmount(safeWithdrawAmount, amountToWithdraw);
        }
    }

    /// @notice Charge Strategist and Performance fees
    /// @param callFeeRecipient Address to send the callFee (if set)
    function _chargeFees(address callFeeRecipient) internal {
        if (profitFee == 0) {
            return;
        }
        uint256 totalFee = (_getContractBalance(address(assetToken)) * profitFee) / MAX_FEE;

        _deductFees(address(assetToken), callFeeRecipient, totalFee);
    }

    /// @notice Harvest the rewards earned by Vault for more collateral tokens
    /// @param callFeeRecipient Address to send the callFee (if set)
    function _harvest(address callFeeRecipient) internal override {
        //1. Claim accrued Qi rewards from LP farm
        _depositLPToFarm(0);

        //2. Swap Qi tokens for asset tokens
        uint256 qiBalance = _getContractBalance(address(qiToken));

        if (qiBalance > 0) {
            _swap(qiBalance, qiToAsset);

            //3. Wrap to vGHST
            assetToken.enter(_getContractBalance(address(ghst)));

            //4. Charge performance fee
            _chargeFees(callFeeRecipient);

            //5. deposit to Qi vault
            _depositToQiVault(_getContractBalance(address(assetToken)));

            lastHarvest = block.timestamp;
            emit Harvested(msg.sender);
        } else {
            revert LibError.HarvestNotReady();
        }
    }

    /// @notice Repay Debt by liquidating LP tokens
    /// @param lpAmount Amount of LP tokens to liquidate
    function _repayDebtLp(uint256 lpAmount) internal {
        //1. Withdraw LP tokens from Farm and remove liquidity
        _withdrawLpAndRemoveLiquidity(lpAmount);

        //2. Swap LP tokens for MAI tokens
        _swap(_getContractBalance(lpToken0), lp0ToMai);
        _swap(_getContractBalance(lpToken1), lp1ToMai);

        //3. Repay Debt to qiVault
        _repayMaiDebt();
    }

    /// @notice Repay Debt from deposited collateral tokens
    /// @param collateralAmount Amount of collateral tokens to withdraw
    function _repayDebtCollateral(uint256 collateralAmount) internal {
        //1. Withdraw assetToken from qiVault
        uint256 minimumCdr = qiVault._minimumCollateralPercentage();
        qiVault.withdrawCollateral(qiVaultId, collateralAmount);

        uint256 collateralPercent = getCollateralPercent();
        if (collateralPercent < minimumCdr && collateralPercent != 0) {
            revert LibError.InvalidCDR(collateralPercent, minimumCdr);
        }

        //2. Unwrap vGHST to GHST
        assetToken.leave(_getContractBalance(address(assetToken)));

        //3. Swap GHST for MAI
        _swap(_getContractBalance(address(ghst)), assetToMai);

        //4. Repay Debt to qiVault
        _repayMaiDebt();
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////      Admin functions      ///////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Delegate Qi voting power to another address
    /// @param _id   The delegate ID
    /// @param _voter Address to delegate the votes to
    function delegateVotes(bytes32 _id, address _voter) external onlyOwner {
        _delegateVotingPower(_id, _voter);
        emit VoterUpdated(_voter);
    }

    /// @notice Updates the delegation contract for Qi token Lock
    /// @param _delegationContract Updated delegation contract address
    function updateQiDelegationContract(address _delegationContract) external onlyOwner {
        if (_delegationContract == address(0)) revert LibError.InvalidAddress();
        qiDelegationContract = _delegationContract;
        emit DelegationContractUpdated(_delegationContract);
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateAssetToMai(address[] memory _swapPath) external onlyOwner {
        emit SwapPathUpdated(assetToMai, _swapPath);
        assetToMai = _swapPath;
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateMaiToAsset(address[] memory _swapPath) external onlyOwner {
        emit SwapPathUpdated(maiToAsset, _swapPath);
        maiToAsset = _swapPath;
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateQiToAsset(address[] memory _swapPath) external onlyOwner {
        emit SwapPathUpdated(qiToAsset, _swapPath);
        qiToAsset = _swapPath;
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateMaiToLp0(address[] memory _swapPath) external onlyOwner {
        emit SwapPathUpdated(maiToLp0, _swapPath);
        maiToLp0 = _swapPath;
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateMaiToLp1(address[] memory _swapPath) external onlyOwner {
        emit SwapPathUpdated(maiToLp1, _swapPath);
        maiToLp1 = _swapPath;
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateLp0ToMai(address[] memory _swapPath) external onlyOwner {
        emit SwapPathUpdated(lp0ToMai, _swapPath);
        lp0ToMai = _swapPath;
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateLp1ToMai(address[] memory _swapPath) external onlyOwner {
        emit SwapPathUpdated(lp1ToMai, _swapPath);
        lp1ToMai = _swapPath;
    }

    /// @notice Update Qi Rewards Pool ID for Qi MasterChef contract
    /// @param _pid Pool ID
    function updateQiRewardsPid(uint256 _pid) external onlyOwner {
        qiRewardsPid = _pid;
    }

    /// @notice Update LP factor for LP tokens calculation from assetToken
    /// @param _factor LP factor (in percent) of how much extra tokens to withdraw to account for slippage and future withdrawals
    function updateLpFactor(uint256 _factor) external onlyOwner {
        lpFactor = _factor;
    }

    /// @notice Update Safe collateral ratio percentage for SAFE_COLLAT_LOW
    /// @param _cdr Updated CDR Percent
    function updateSafeCollateralRatioLow(uint256 _cdr) external onlyOwner {
        SAFE_COLLAT_LOW = _cdr;
    }

    /// @notice Update Safe collateral ratio percentage for SAFE_COLLAT_TARGET
    /// @param _cdr Updated CDR Percent
    function updateSafeCollateralRatioTarget(uint256 _cdr) external onlyOwner {
        SAFE_COLLAT_TARGET = _cdr;
    }

    /// @notice Update Safe collateral ratio percentage for SAFE_COLLAT_HIGH
    /// @param _cdr Updated CDR Percent
    function updateSafeCollateralRatioHigh(uint256 _cdr) external onlyOwner {
        SAFE_COLLAT_HIGH = _cdr;
    }

    /// @notice Set Chainlink price feed for LP tokens
    /// @param _token Token for which price feed needs to be set
    /// @param _feed Address of Chainlink price feed
    function setPriceFeed(address _token, address _feed) external onlyOwner {
        priceFeeds[_token] = _feed;
    }

    /// @notice Repay Debt by liquidating LP tokens
    /// @param _lpAmount Amount of LP tokens to liquidate
    function repayDebtLp(uint256 _lpAmount) external onlyOwner {
        _repayDebtLp(_lpAmount);
    }

    /// @notice Repay Debt from deposited collateral tokens
    /// @param _collateralAmount Amount of collateral to repay
    function repayDebtCollateral(uint256 _collateralAmount) external onlyOwner {
        _repayDebtCollateral(_collateralAmount);
    }

    /// @notice Repay Debt by liquidating LP tokens
    function repayMaxDebtLp() external onlyOwner {
        uint256 lpbalance = getStrategyLpDeposited();
        _repayDebtLp(lpbalance);
    }

    /// @notice Repay Debt from deposited collateral tokens
    function repayMaxDebtCollateral() external onlyOwner {
        uint256 minimumCdr = qiVault._minimumCollateralPercentage() + 10;

        uint256 safeCollateralAmount = safeCollateralForDebt(getStrategyDebt(), minimumCdr);
        uint256 collateralToRepay = getStrategyCollateral() - safeCollateralAmount;
        _repayDebtCollateral(collateralToRepay);
    }

    /// @dev Rescues random funds stuck that the strat can't handle.
    /// @param _token address of the token to rescue.
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        if (_token == address(assetToken)) revert LibError.InvalidToken();
        IERC20(_token).safeTransfer(msg.sender, _getContractBalance(_token));
    }

    /// @dev Pause the contracts in case of emergency
    function pause() public onlyManager {
        _pause();
        _removeAllowances();
    }

    /// @dev Unpause the contracts
    function unpause() external onlyManager {
        _unpause();
        _giveAllowances();
    }

    function panic() public override onlyManager {
        pause();
        IQiStakingRewards(qiStakingRewards).withdraw(qiRewardsPid, balanceOfPool());
    }

    function setRebalancer(address _rebalancer) external onlyManager {
        rebalancer = _rebalancer;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////      External functions      /////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Returns the total supply and market of LP
    /// @dev Will work only if price oracle for either one of the lp tokens is set
    /// @return lpSupply Total supply of LP tokens
    /// @return totalMarketUSD Total market in USD of LP tokens
    function getLPTotalMarketUSD() public view returns (uint256 lpSupply, uint256 totalMarketUSD) {
        (lpSupply, totalMarketUSD) = _getLPTotalMarketUSD();
    }

    /// @notice Returns the assetToken Price from QiVault Contract Oracle
    /// @return assetTokenPrice Asset Token Price in USD
    function getAssetTokenPrice() public view returns (uint256 assetTokenPrice) {
        assetTokenPrice = qiVault.getEthPriceSource(); // Asset token price
        if (assetTokenPrice == 0) revert LibError.PriceFeedError();
    }

    /// @notice Returns the assetToken Price from QiVault Contract Oracle
    /// @return maiTokenPrice MAI Token Price in USD
    function getMaiTokenPrice() public view returns (uint256 maiTokenPrice) {
        maiTokenPrice = qiVault.getTokenPriceSource();
        if (maiTokenPrice == 0) revert LibError.PriceFeedError();
    }

    /// @notice Returns the Collateral Percentage of Strategy from QiVault
    /// @return cdr_percent Collateral Percentage
    function getCollateralPercent() public view returns (uint256 cdr_percent) {
        cdr_percent = qiVault.checkCollateralPercentage(qiVaultId);
    }

    /// @notice Returns the Debt of strategy from QiVault
    /// @return maiDebt MAI Debt of strategy
    function getStrategyDebt() public view returns (uint256 maiDebt) {
        maiDebt = qiVault.vaultDebt(qiVaultId);
    }

    /// @notice Returns the total collateral of strategy from QiVault
    /// @return collateral Collateral deposited by strategy into QiVault
    function getStrategyCollateral() public view returns (uint256 collateral) {
        collateral = qiVault.vaultCollateral(qiVaultId);
    }

    /// @notice Returns the total LP deposited balance of strategy from Qifarm
    /// @return lpBalance LP deposited by strategy into Qifarm
    function getStrategyLpDeposited() public view returns (uint256 lpBalance) {
        lpBalance = IQiStakingRewards(qiStakingRewards).deposited(qiRewardsPid, address(this));
    }

    /// @notice Returns the maximum amount of asset tokens that can be deposited
    /// @return depositLimit Maximum amount of asset tokens that can be deposited to strategy
    function getMaximumDepositLimit() public view returns (uint256 depositLimit) {
        uint256 maiAvailable = qiVault.getDebtCeiling();
        depositLimit = (maiAvailable * SAFE_COLLAT_TARGET * 10**8) / (getAssetTokenPrice() * 100);
    }

    /// @notice Returns the safe amount to borrow from qiVault considering Debt and Collateral
    /// @return amountToBorrow Safe amount of MAI to borrow from vault
    function safeAmountToBorrow() public view returns (uint256 amountToBorrow) {
        uint256 safeDebt = safeDebtForCollateral(getStrategyCollateral(), SAFE_COLLAT_TARGET);
        uint256 currentDebt = getStrategyDebt();
        if (safeDebt > currentDebt) {
            amountToBorrow = safeDebt - currentDebt;
        } else {
            amountToBorrow = 0;
        }
    }

    /// @notice Returns the safe amount to withdraw from qiVault considering Debt and Collateral
    /// @return amountToWithdraw Safe amount of assetTokens to withdraw from vault
    function safeAmountToWithdraw() public view returns (uint256 amountToWithdraw) {
        uint256 safeCollateral = safeCollateralForDebt(getStrategyDebt(), (SAFE_COLLAT_LOW + 1));
        uint256 currentCollateral = getStrategyCollateral();
        if (currentCollateral > safeCollateral) {
            amountToWithdraw = currentCollateral - safeCollateral;
        } else {
            amountToWithdraw = 0;
        }
    }

    /// @notice Returns the safe Debt for collateral(passed as argument) from qiVault
    /// @param collateral Amount of collateral tokens for which safe Debt is to be calculated
    /// @return safeDebt Safe amount of MAI than can be borrowed from qiVault
    function safeDebtForCollateral(uint256 collateral, uint256 collateralPercent) public view returns (uint256 safeDebt) {
        uint256 safeDebtValue = (collateral * getAssetTokenPrice() * 100) / collateralPercent;
        safeDebt = safeDebtValue / getMaiTokenPrice();
    }

    /// @notice Returns the safe collateral for debt(passed as argument) from qiVault
    /// @param debt Amount of MAI tokens for which safe collateral is to be calculated
    /// @return safeCollateral Safe amount of collateral tokens for qiVault
    function safeCollateralForDebt(uint256 debt, uint256 collateralPercent) public view returns (uint256 safeCollateral) {
        uint256 collateralValue = (collateralPercent * debt * getMaiTokenPrice()) / 100;
        safeCollateral = collateralValue / getAssetTokenPrice();
    }

    /// @notice Deposits the asset token to QiVault from balance of this contract
    /// @dev Asset tokens must be transferred to the contract first before calling this function
    function deposit() public override whenNotPaused onlyVault {
        _depositToQiVault(_getContractBalance(address(assetToken)));

        //Check CDR ratio, if below 220% don't borrow, else borrow
        uint256 cdr_percent = getCollateralPercent();

        if (cdr_percent > SAFE_COLLAT_HIGH) {
            _borrowTokens();
            _swapMaiAndAddLiquidity();
            _depositLPToFarm(_getContractBalance(lpPairToken));
        } else if (cdr_percent == 0 && getStrategyCollateral() != 0) {
            // Note: Special case for initial deposit(as CDR is returned 0 when Debt is 0)
            // Borrow 1 wei to initialize
            qiVault.borrowToken(qiVaultId, 1);
        }
    }

    /// @notice Withdraw deposited tokens from the Vault
    function withdraw(uint256 withdrawAmount) public override whenNotPaused onlyVault {
        _withdrawFromVault(withdrawAmount);
    }

    /// @notice Rebalances the vault to a safe Collateral to Debt ratio
    /// @dev If Collateral to Debt ratio is below SAFE_COLLAT_LOW,
    /// then -> Withdraw lpAmount from Farm > Remove liquidity from LP > swap Qi for WMATIC > Deposit WMATIC to vault
    // If CDR is greater than SAFE_COLLAT_HIGH,
    /// then -> Borrow more MAI > Swap for Qi and WMATIC > Deposit to Quickswap LP > Deposit to Qi Farm
    function rebalanceVault(bool repayFromLp) public whenNotPaused {
        if (rebalancer != address(0)) require(msg.sender == rebalancer, "!whitelisted");

        uint256 cdr_percent = getCollateralPercent();

        if (cdr_percent < SAFE_COLLAT_TARGET) {
            // Get amount of LP tokens to sell for asset tokens
            uint256 safeDebt = safeDebtForCollateral(getStrategyCollateral(), SAFE_COLLAT_TARGET);
            uint256 debtToRepay = getStrategyDebt() - safeDebt;

            if (repayFromLp) {
                uint256 lpAmount = _getLPTokensFromMai(debtToRepay);
                _repayDebtLp(lpAmount);
            } else {
                // Repay from collateral
                uint256 requiredCollateralValue = ((SAFE_COLLAT_TARGET + 10) * debtToRepay * getMaiTokenPrice()) / 100;
                uint256 collateralToRepay = requiredCollateralValue / getAssetTokenPrice();

                uint256 stratCollateral = getStrategyCollateral();
                uint256 minimumCdr = qiVault._minimumCollateralPercentage() + 5;
                uint256 stratDebt = getStrategyDebt();
                uint256 minCollateralForDebt = safeCollateralForDebt(stratDebt, minimumCdr);
                uint256 maxWithdrawAmount;
                if (stratCollateral > minCollateralForDebt) {
                    maxWithdrawAmount = stratCollateral - minCollateralForDebt;
                } else {
                    revert LibError.InvalidAmount(1, 1);
                }
                if (collateralToRepay > maxWithdrawAmount) {
                    collateralToRepay = maxWithdrawAmount;
                }
                _repayDebtCollateral(collateralToRepay);
            }
            //4. Check updated CDR and verify
            uint256 updated_cdr = getCollateralPercent();
            if (updated_cdr < SAFE_COLLAT_TARGET && updated_cdr != 0)
                revert LibError.InvalidCDR(updated_cdr, SAFE_COLLAT_TARGET);
        } else if (cdr_percent > SAFE_COLLAT_HIGH) {
            //1. Borrow tokens
            _borrowTokens();

            //2. Swap and add liquidity
            _swapMaiAndAddLiquidity();

            //3. Deposit LP to farm
            _depositLPToFarm(_getContractBalance(lpPairToken));
        } else {
            revert LibError.InvalidCDR(0, 0);
        }
        emit VaultRebalanced();
    }

    /// @notice Repay MAI debt back to the qiVault
    /// @dev The sender must have sufficient allowance and balance
    function repayDebt(uint256 amount) public {
        mai.safeTransferFrom(msg.sender, address(this), amount);
        _repayMaiDebt();
    }

    /// @notice calculate the total underlying 'want' held by the strat
    /// @dev This is equivalent to the amount of assetTokens deposited in the QiDAO vault
    function balanceOfStrategy() public view override returns (uint256 strategyBalance) {
        return balanceOfWant() + balanceOfPool();
    }

    /// @notice calculate the total underlying 'want' held by the strat
    /// @dev This is equivalent to the amount of assetTokens deposited in the QiDAO vault
    function balanceOf() public view override returns (uint256 strategyBalance) {
        return balanceOfWant() + balanceOfPool();
    }

    function balanceOfPool() public view override returns (uint256 poolBalance) {
        uint256 assetBalance = getStrategyCollateral();

        // For Debt, also factor in 0.5% repayment fee
        // This fee is charged by QiDao only on the Debt (amount of MAI borrowed)
        uint256 maiDebt = (getStrategyDebt() * (10000 + 50)) / 10000;
        uint256 lpBalance = getStrategyLpDeposited();

        IUniswapV2ERC20 pair = IUniswapV2ERC20(lpPairToken);
        uint256 lpTotalSupply = pair.totalSupply();
        (uint112 _reserve0, uint112 _reserve1, ) = pair.getReserves();

        uint256 balance0 = (lpBalance * _reserve0) / lpTotalSupply;
        uint256 balance1 = (lpBalance * _reserve1) / lpTotalSupply;

        uint256 maiBal0;
        if (balance0 > 0) {
            try IUniswapV2Router(unirouter).getAmountsOut(balance0, lp0ToMai) returns (uint256[] memory amountOut0) {
                maiBal0 = amountOut0[amountOut0.length - 1];
            } catch {}
        }

        uint256 maiBal1;
        if (balance1 > 0) {
            try IUniswapV2Router(unirouter).getAmountsOut(balance1, lp1ToMai) returns (uint256[] memory amountOut1) {
                maiBal1 = amountOut1[amountOut1.length - 1];
            } catch {}
        }
        uint256 totalMaiReceived = maiBal0 + maiBal1;

        if (maiDebt > totalMaiReceived) {
            uint256 diffAsset = ((maiDebt - totalMaiReceived) * 10**8) / getAssetTokenPrice();
            poolBalance = assetBalance - diffAsset;
        } else {
            uint256 diffAsset = ((totalMaiReceived - maiDebt) * 10**8) / getAssetTokenPrice();
            poolBalance = assetBalance + diffAsset;
        }
    }

    function balanceOfWant() public view override returns (uint256 poolBalance) {
        return _getContractBalance(address(assetToken));
    }

    /// @notice called as part of strat migration. Sends all the available funds back to the vault.
    /// NOTE: All QiVault debt must be paid before this function is called
    function retireStrat() external override onlyVault {
        require(getStrategyDebt() == 0, "Debt");

        // Withdraw asset token balance from vault and strategy
        qiVault.withdrawCollateral(qiVaultId, getStrategyCollateral());
        assetToken.safeTransfer(vault, _getContractBalance(address(assetToken)));

        // Withdraw LP balance from staking rewards
        uint256 lpBalance = getStrategyLpDeposited();
        if (lpBalance > 0) {
            IQiStakingRewards(qiStakingRewards).withdraw(qiRewardsPid, lpBalance);
            IERC20(lpPairToken).safeTransfer(vault, lpBalance);
        }
        emit StrategyRetired(address(this));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library LibError {
    error QiVaultError();
    error PriceFeedError();
    error LiquidationRisk();
    error HarvestNotReady();
    error InvalidAddress();
    error InvalidToken();
    error InvalidSwapPath();
    error InvalidAmount(uint256 current, uint256 expected);
    error InvalidCDR(uint256 current, uint256 expected);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {CompoundFeeManager} from "./CompoundFeeManager.sol";
import {CompoundStratManager} from "./CompoundStratManager.sol";

abstract contract CompoundStrat is CompoundStratManager, CompoundFeeManager {
    using SafeERC20 for IERC20;

    address public want;
    address public output;
    address public native;
    uint256 public lastHarvest;
    bool public harvestOnDeposit;

    // Main user interactions
    function deposit() external virtual;

    function withdraw(uint256 _amount) external virtual;

    // Harvest Functions
    function _harvest(address callFeeRecipient) internal virtual;

    function harvestWithCallFeeRecipient(address callFeeRecipient) external virtual whenNotPaused {
        _harvest(callFeeRecipient);
    }

    function harvest() external virtual whenNotPaused {
        _harvest(tx.origin);
    }

    function managerHarvest() external virtual onlyManager {
        _harvest(tx.origin);
    }

    // View Functions
    function balanceOfStrategy() external view virtual returns (uint256);

    function balanceOf() external view virtual returns (uint256);

    function balanceOfWant() external view virtual returns (uint256);

    function balanceOfPool() external view virtual returns (uint256);

    //Other

    function retireStrat() external virtual;

    function panic() external virtual;

    function setHarvestOnDeposit(bool _harvestOnDeposit) external virtual onlyManager {
        harvestOnDeposit = _harvestOnDeposit;
    }

    function beforeDeposit() external virtual onlyVault {
        if (harvestOnDeposit) {
            _harvest(tx.origin);
        }
    }

    function _deductFees(
        address tokenAddress,
        address callFeeRecipient,
        uint256 totalFeeAmount
    ) internal virtual {
        uint256 callFeeAmount;
        uint256 strategistFeeAmount;

        if (callFee > 0) {
            callFeeAmount = (totalFeeAmount * callFee) / MAX_FEE;
            IERC20(tokenAddress).safeTransfer(callFeeRecipient, callFeeAmount);
            emit CallFeeCharged(callFeeRecipient, callFeeAmount);
        }

        if (strategistFee > 0) {
            strategistFeeAmount = (totalFeeAmount * strategistFee) / MAX_FEE;
            IERC20(tokenAddress).safeTransfer(strategist, strategistFeeAmount);
            emit CallFeeCharged(strategist, strategistFeeAmount);
        }

        // Send the rest of native tokens remaining to fee recipient
        uint ethaFeeAmt = totalFeeAmount - callFeeAmount - strategistFeeAmount;
        IERC20(tokenAddress).safeTransfer(ethaFeeRecipient, ethaFeeAmt);

        emit ProtocolFeeCharged(ethaFeeRecipient, ethaFeeAmt);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IVGHST is IERC20 {
    function enter(uint256 amount) external virtual returns (uint256);

    function leave(uint256 shares) external virtual;

    function convertVGHST(uint shares) external view virtual returns (uint256 assets);

    function totalGHST(address _user) external view virtual returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IVGHST.sol";
import "./Helpers.sol";

contract WrapGhstResolver is Helpers {
    using UniversalERC20 for IERC20;

    IVGHST internal constant vGhst = IVGHST(0x51195e21BDaE8722B29919db56d95Ef51FaecA6C);
    IERC20 internal constant Ghst = IERC20(0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7);

    function wrap(
        uint256 amount,
        uint getId,
        uint setId
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId) : amount;

        Ghst.universalApprove(address(vGhst), 0);

        uint shares = vGhst.enter(realAmt);

        if (setId > 0) {
            setUint(setId, shares);
        }
    }

    function unwrap(
        uint256 shares,
        uint getId,
        uint setId
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId) : shares;

        uint balBefore = Ghst.balanceOf(address(this));

        vGhst.leave(realAmt);

        if (setId > 0) {
            setUint(setId, Ghst.balanceOf(address(this)) - balBefore);
        }
    }
}

contract WrapGhstLogic is WrapGhstResolver {
    string public constant name = "WrapGhstLogic";
    uint8 public constant version = 1;

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IZapper.sol";
import "../interfaces/IWETH.sol";
import "../libs/UniversalERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Helpers is Context {
    using UniversalERC20 for IWETH;

    /** 
		@dev Address of Wrapped Matic.
	**/
    IWETH internal constant wmatic = IWETH(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    /**
     * @dev get ethereum address
     */
    function getAddressETH() public pure returns (address eth) {
        eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    /**
     * @dev Return swap fee and recipient
     */
    function getAdapterAddress() public view returns (address adapter) {
        return IZapper(address(this)).adapter();
    }

    /**
     * @dev Return swap fee and recipient
     */
    function getSwapFee()
        public
        view
        returns (
            uint256 fee,
            uint256 maxFee,
            address recipient
        )
    {
        IZapper zapper = IZapper(address(this));

        fee = zapper.hasRole(zapper.PARTNER_ROLE(), _msgSender()) ? 0 : zapper.swapFee();
        maxFee = zapper.MAX_FEE();
        recipient = zapper.feeRecipient();
    }

    /**
     * @dev Get Uint value from Zapper Contract.
     */
    function getUint(uint256 id) internal view returns (uint256) {
        return IZapper(address(this)).getUint(id);
    }

    /**
     * @dev Set Uint value in Zapper Contract.
     */
    function setUint(uint256 id, uint256 val) internal {
        IZapper(address(this)).setUint(id, val);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IZapper {
    function PARTNER_ROLE() external view returns (bytes32);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function adapter() external view returns (address);

    function feeRecipient() external view returns (address);

    function MAX_FEE() external view returns (uint256);

    function swapFee() external view returns (uint256);

    function getUint(uint256) external view returns (uint256);

    function setUint(uint256 id, uint256 value) external;

    function execute(address[] calldata targets, bytes[] calldata datas) external payable;

    function setSwapFee(uint256 _swapFee) external;

    function setAdapterAddress(address _adapter) external;

    function setFeeRecipient(address _feeRecipient) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IWETH is IERC20 {
	function deposit() external payable virtual;

	function withdraw(uint256 amount) external virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Helpers.sol";

contract WrapResolver is Helpers {
    function wrap(uint256 amount) external payable {
        uint256 realAmt = amount == type(uint256).max ? address(this).balance : amount;
        wmatic.deposit{value: realAmt}();
    }

    function unwrap(uint256 amount) external {
        uint256 realAmt = amount == type(uint256).max ? wmatic.balanceOf(address(this)) : amount;
        wmatic.withdraw(realAmt);
    }
}

contract WrapLogic is WrapResolver {
    string public constant name = "WrapLogic";
    uint8 public constant version = 1;

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libs/UniversalERC20.sol";
import "../interfaces/IERC4626.sol";
import "./Helpers.sol";

contract VaultResolverVRC20 is Helpers {
    using UniversalERC20 for IERC20;

    event VaultDeposit(address indexed user, address indexed vault, address indexed erc20, uint256 tokenAmt);
    event VaultWithdraw(address indexed user, address indexed vault, address indexed erc20, uint256 tokenAmt);
    event VaultClaim(address indexed user, address indexed vault, address indexed erc20, uint256 tokenAmt);

    /**
     * @dev Deposit tokens to ETHA Vault
     * @param vault address of vault
     * @param tokenAmt amount of tokens to deposit
     * @param getId read value of tokenAmt from memory contract
     */
    function deposit(
        IERC4626 vault,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId) : tokenAmt;

        require(realAmt > 0, "!AMOUNT");

        IERC20 erc20 = IERC20(address(vault.asset()));
        erc20.universalApprove(address(vault), realAmt);

        uint256 sharesBefore = vault.balanceOf(address(this));

        vault.deposit(realAmt, address(this));

        uint sharesAfter = vault.balanceOf(address(this)) - sharesBefore;

        // Store shares received
        if (setId > 0) {
            setUint(setId, sharesAfter);
        }

        // Send vault tokens to user
        IERC20(address(vault)).universalTransfer(_msgSender(), sharesAfter);

        emit VaultDeposit(_msgSender(), address(vault), address(erc20), realAmt);
    }

    /**
     * @dev Mints shares and deposit tokens to ETHA Vault
     * @param vault address of vault
     * @param shares amount of vault tokens to mint
     * @param getId read value of tokenAmt from memory contract
     */
    function mint(
        IERC4626 vault,
        uint256 shares,
        uint256 getId,
        uint256 setId
    ) external payable {
        uint256 realShares = getId > 0 ? getUint(getId) : shares;
        uint256 realAmt = vault.previewMint(realShares);
        require(realShares > 0, "!AMOUNT");

        IERC20 erc20 = IERC20(address(vault.asset()));
        erc20.universalApprove(address(vault), realAmt);

        uint256 sharesBefore = vault.balanceOf(address(this));

        vault.deposit(realAmt, address(this));

        uint sharesAfter = vault.balanceOf(address(this)) - sharesBefore;

        // Store shares received
        if (setId > 0) {
            setUint(setId, sharesAfter);
        }

        // Send vault tokens to user
        IERC20(address(vault)).universalTransfer(_msgSender(), sharesAfter);

        emit VaultDeposit(_msgSender(), address(vault), address(erc20), realAmt);
    }

    /**
     * @dev Redeems share tokens from ETHA Vault
     * @param vault address of vault
     * @param shares amount of vault tokens to withdraw
     * @param getId read value of shares to withdraw from memory contract
     * @param getId store amount tokens received in memory contract
     */
    function redeem(
        IERC4626 vault,
        uint256 shares,
        uint256 getId,
        uint256 setId
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId) : shares;

        require(vault.balanceOf(address(this)) >= realAmt, "!BALANCE");

        address underlying = address(vault.asset());
        uint256 balanceBefore = IERC20(underlying).balanceOf(address(this));

        vault.redeem(realAmt, address(this), address(this));

        uint256 wantReceived = IERC20(underlying).balanceOf(address(this)) - balanceBefore;

        // set tokens received after paying fees
        if (setId > 0) {
            setUint(setId, wantReceived);
        }

        emit VaultWithdraw(_msgSender(), address(vault), underlying, wantReceived);
    }

    /**
     * @dev Redeems share tokens from ETHA Vault
     * @param vault address of vault
     * @param tokenAmt amount of tokens to withdraw
     * @param getId read value of shares to withdraw from memory contract
     * @param getId store amount tokens received in memory contract
     */
    function withdraw(
        IERC4626 vault,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId) : tokenAmt;

        require(vault.balanceOf(address(this)) >= realAmt, "!BALANCE");

        address underlying = address(vault.asset());
        uint256 balanceBefore = IERC20(underlying).balanceOf(address(this));

        vault.withdraw(realAmt, address(this), address(this));

        uint256 wantReceived = IERC20(underlying).balanceOf(address(this)) - balanceBefore;

        // set tokens received after paying fees
        if (setId > 0) {
            setUint(setId, wantReceived);
        }

        emit VaultWithdraw(_msgSender(), address(vault), underlying, wantReceived);
    }
}

contract VRC20VaultLogic is VaultResolverVRC20 {
    string public constant name = "VRC20VaultLogic";
    uint8 public constant version = 1;

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import {IERC4626} from "../interfaces/IERC4626.sol";
import {IQiStrat} from "../interfaces/IQiStrat.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GelatoRebalance is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private vaults;

    function checker() external view returns (bool canExec, bytes memory execPayload) {
        for (uint256 i = 0; i < vaults.length(); i++) {
            address _vault = getVault(i);
            IQiStrat strat = IQiStrat(IERC4626(_vault).strategy());

            uint safeLow = strat.SAFE_COLLAT_LOW();
            uint safeHigh = strat.SAFE_COLLAT_HIGH();
            uint cdr = strat.getCollateralPercent();

            canExec = cdr < safeLow || cdr > safeHigh;

            if (canExec) {
                execPayload = abi.encodeWithSelector(this.rebalance.selector, address(strat));
                break;
            }
        }
    }

    function rebalance(IQiStrat strat) external {
        strat.rebalanceVault(true);
    }

    function getVault(uint256 index) public view returns (address) {
        return vaults.at(index);
    }

    function vaultExists(address _vault) external view returns (bool) {
        return vaults.contains(_vault);
    }

    function totalVaults() external view returns (uint256) {
        return vaults.length();
    }

    // OWNER FUNCTIONS

    function addVault(address _newVault) public onlyOwner {
        require(!vaults.contains(_newVault), "EXISTS");

        vaults.add(_newVault);
    }

    function addVaults(address[] memory _vaults) external {
        for (uint256 i = 0; i < _vaults.length; i++) {
            addVault(_vaults[i]);
        }
    }

    function removeVault(address _vault) public onlyOwner {
        require(vaults.contains(_vault), "!EXISTS");

        vaults.remove(_vault);
    }

    function removeVaults(address[] memory _vaults) external {
        for (uint256 i = 0; i < _vaults.length; i++) {
            removeVault(_vaults[i]);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IStakingRewards.sol";
import "../../interfaces/IDragonLair.sol";
import "../../interfaces/IDistributionFactory.sol";
import "../../interfaces/IMasterChefDistribution.sol";
import "../../interfaces/IFarmV3.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/IERC4626.sol";
import {Modifiers, IERC20Metadata, SynthData, ChefData, DQUICK, QUICK} from "./AppStorage.sol";

contract StakingFacet is Modifiers {
    /**
        @dev fetch general staking info of a certain synthetix type contract
    */
    function getStakingInfo(IDistributionFactory stakingFactory, address[] calldata poolTokens)
        external
        view
        returns (SynthData[] memory)
    {
        SynthData[] memory _datas = new SynthData[](poolTokens.length);

        IStakingRewards instance;
        uint256 rewardRate;
        uint256 rewardBalance;
        address rewardsToken;
        uint256 periodFinish;
        uint256 totalStaked;

        for (uint256 i = 0; i < _datas.length; i++) {
            instance = IStakingRewards(stakingFactory.stakingRewardsInfoByStakingToken(poolTokens[i]));

            // If poolToken not present in factory, skip
            if (address(instance) == address(0)) continue;

            rewardsToken = instance.rewardsToken();
            rewardBalance = IERC20Metadata(rewardsToken).balanceOf(address(instance));

            // format dQuick to Quick
            if (rewardsToken == DQUICK) {
                rewardRate = IDragonLair(DQUICK).dQUICKForQUICK(instance.rewardRate());
                rewardsToken = QUICK;
                rewardBalance = IDragonLair(DQUICK).dQUICKForQUICK(rewardBalance);
            } else rewardRate = instance.rewardRate();

            periodFinish = instance.periodFinish();
            totalStaked = instance.totalSupply();

            _datas[i] = SynthData(
                poolTokens[i],
                address(instance),
                rewardsToken,
                totalStaked,
                rewardRate,
                periodFinish,
                rewardBalance
            );
        }

        return _datas;
    }

    /**
        @dev fetch reward rate per block for masterchef poolIds
    */
    function getMasterChefInfo(IFarmV3 chef, uint poolId) external view returns (uint ratePerSec, uint totalStaked) {
        uint256 rewardPerSecond = chef.rewardPerSecond();
        (address depositToken, uint allocPoint) = chef.poolInfo(poolId);

        uint256 totalAllocPoint = chef.totalAllocPoint();

        ratePerSec = (rewardPerSecond * allocPoint) / totalAllocPoint;
        totalStaked = IERC20Metadata(depositToken).balanceOf(address(chef));
    }

    /**
        @dev fetch reward rate per block for masterchef poolIds
    */
    function getEthaMasterChefInfo(IMasterChefDistribution chef, IERC4626 vault)
        external
        view
        returns (uint ratePerBlock, uint totalStaked)
    {
        uint poolId = chef.vaultToPoolId(address(vault));

        uint256 rewardPerBlock = chef.rewardPerBlock();
        (, uint allocPoint, , ) = chef.poolInfo(poolId);

        uint256 totalAllocPoint = chef.totalAllocPoint();

        ratePerBlock = (rewardPerBlock * allocPoint) / totalAllocPoint;

        // For Compounding Vaults
        try vault.totalAssets() returns (uint _totalAssets) {
            totalStaked = _totalAssets;
        } catch {
            // For Volatile Vaults
            totalStaked = IVault(address(vault)).totalSupply();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakingRewards {
	// Views
	function lastTimeRewardApplicable() external view returns (uint256);

	function rewardPerToken() external view returns (uint256);

	function earned(address account) external view returns (uint256);

	function getRewardForDuration() external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function claimDate() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function rewardsToken() external view returns (address);

	function stakingToken() external view returns (address);

	function rewardRate() external view returns (uint256);

	function periodFinish() external view returns (uint256);

	// Mutative

	function stake(uint256 amount) external;

	function withdraw(uint256 amount) external;

	function getReward() external;

	function exit() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDragonLair is IERC20 {
	function enter(uint256 _quickAmount) external;

	function leave(uint256 _dQuickAmount) external;

	function QUICKBalance(address _account)
		external
		view
		returns (uint256 quickAmount_);

	function dQUICKForQUICK(uint256 _dQuickAmount)
		external
		view
		returns (uint256 quickAmount_);

	function QUICKForDQUICK(uint256 _quickAmount)
		external
		view
		returns (uint256 dQuickAmount_);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFarmV3 {
    function balanceOf(address _user) external returns (uint256);

    function getReward(address _user) external;

    function poolLength() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function rewardPerSecond() external view returns (uint256);

    function fund(uint256 _amount) external;

    function deposited(uint256 _pid, address _user) external view returns (uint256);

    function pending(uint256 _pid, address _user) external view returns (uint256);

    function totalPending() external view returns (uint256);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint _pid, uint256 _amount) external;

    function poolInfo(uint _pid) external view returns (address lpToken, uint allocPoint);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IStrat.sol";
import "../../interfaces/IVault.sol";
import "./DividendToken.sol";
import "../../utils/Timelock.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../../interfaces/IDistribution.sol";

contract VaultOld is Ownable, Pausable, DividendToken {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Detailed;
    using SafeERC20 for IERC20;

    // EVENTS
    event HarvesterChanged(address newHarvester);
    event FeeUpdate(uint256 newFee);
    event StrategyChanged(address newStrat);
    event DepositLimitUpdated(uint256 newLimit);
    event NewDistribution(address newDistribution);
    event NewFeeRecipient(address newFeeRecipient);

    IERC20Detailed public underlying;
    IERC20 public rewards;
    IStrat public strat;
    Timelock public timelock;

    address public harvester;
    address public feeRecipient;

    uint256 constant MAX_FEE = 10000;
    uint256 public performanceFee = 2000; // 20% of profit

    // if depositLimit = 0 then there is no deposit limit
    uint256 public depositLimit;
    uint256 public lastDistribution;
    address public distribution;

    modifier onlyHarvester() {
        require(msg.sender == harvester);
        _;
    }

    constructor(
        IERC20Detailed underlying_,
        IERC20 target_,
        IERC20 rewards_,
        address harvester_,
        string memory name_,
        string memory symbol_
    ) DividendToken(target_, name_, symbol_, underlying_.decimals()) {
        underlying = underlying_;
        rewards = rewards_;
        harvester = harvester_;
        feeRecipient = msg.sender;
        depositLimit = 20000 * (10**underlying_.decimals()); // 20k initial deposit limit
        timelock = new Timelock(msg.sender, 1 hours);
        _pause(); // paused until a strategy is connected
    }

    function calcTotalValue() public view returns (uint256 underlyingAmount) {
        return strat.calcTotalValue();
    }

    function totalYield() public returns (uint256) {
        return strat.totalYield();
    }

    function _syncDist() internal {
        // If distribution contract exists
        if (distribution != address(0)) {
            uint256 totalSupplied = balanceOf(msg.sender);

            // current staked amount
            uint256 totalStaked = IDistribution(distribution).balanceOf(msg.sender);

            // if total staked is bigger, unstake
            if (totalStaked > totalSupplied) {
                IDistribution(distribution).withdraw(msg.sender, totalStaked.sub(totalSupplied));
            }

            // if total supplied is bigger, stake
            if (totalSupplied > totalStaked) {
                IDistribution(distribution).stake(msg.sender, totalSupplied.sub(totalStaked));
            }
        }
    }

    function deposit(uint256 amount) external whenNotPaused {
        require(amount > 0, "ZERO-AMOUNT");
        if (depositLimit > 0) {
            // if deposit limit is 0, then there is no deposit limit
            require(totalSupply().add(amount) <= depositLimit);
        }

        underlying.safeTransferFrom(msg.sender, address(strat), amount);
        strat.invest();

        _mint(msg.sender, amount);

        // Sync ETHA distribution
        _syncDist();
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "ZERO-AMOUNT");

        _burn(msg.sender, amount);

        strat.divest(amount);
        underlying.safeTransfer(msg.sender, amount);

        // Claim profits when withdrawing
        claim();

        // Sync ETHA distribution
        _syncDist();
    }

    function unclaimedProfit(address user) external view returns (uint256) {
        return withdrawableDividendOf(user);
    }

    function claim() public returns (uint256 claimed) {
        claimed = withdrawDividend(msg.sender);

        if (distribution != address(0)) {
            IDistribution(distribution).getReward(msg.sender);
        }
    }

    // Used to claim on behalf of certain contracts e.g. Uniswap pool
    function claimOnBehalf(address recipient) external {
        require(msg.sender == harvester || msg.sender == owner());
        withdrawDividend(recipient);
    }

    // ==== ONLY OWNER ===== //

    function updateDistribution(address newDistribution) public onlyOwner {
        distribution = newDistribution;
        emit NewDistribution(newDistribution);
    }

    function pauseDeposits(bool trigger) external onlyOwner {
        if (trigger) _pause();
        else _unpause();
    }

    function changeHarvester(address harvester_) external onlyOwner {
        harvester = harvester_;

        emit HarvesterChanged(harvester_);
    }

    function changePerformanceFee(uint256 fee_) external onlyOwner {
        require(fee_ <= MAX_FEE);
        performanceFee = fee_;

        emit FeeUpdate(fee_);
    }

    function changeFeeRecipient(address newFeeRecipient) external onlyOwner {
        feeRecipient = newFeeRecipient;

        emit NewFeeRecipient(newFeeRecipient);
    }

    // if limit == 0 then there is no deposit limit
    function setDepositLimit(uint256 limit) external onlyOwner {
        depositLimit = limit;

        emit DepositLimitUpdated(limit);
    }

    // Any tokens (other than the target) that are sent here by mistake are recoverable by the owner
    function sweep(address _token) external onlyOwner {
        require(_token != address(target));
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    // ==== ONLY HARVESTER ===== //

    function harvest() external onlyHarvester returns (uint256 afterFee) {
        // Divest and claim rewards
        uint256 claimed = strat.claim();

        require(claimed > 0, "Nothing to harvest");

        if (performanceFee > 0) {
            // Calculate fees on underlying
            uint256 fee = claimed.mul(performanceFee).div(MAX_FEE);
            afterFee = claimed.sub(fee);
            rewards.safeTransfer(feeRecipient, fee);
        } else {
            afterFee = claimed;
        }

        // Transfer rewards to harvester
        rewards.safeTransfer(harvester, afterFee);
    }

    function distribute(uint256 amount) external onlyHarvester {
        distributeDividends(amount);
        lastDistribution = block.timestamp;
    }

    // ==== ONLY TIMELOCK ===== //

    // The owner has to wait 2 days to confirm changing the strat.
    // This protects users from an upgrade to a malicious strategy
    // Users must watch the timelock contract on Etherscan for any transactions
    function setStrat(IStrat strat_, bool force) external {
        if (address(strat) != address(0)) {
            require(msg.sender == address(timelock), "Only Timelock");
            uint256 prevTotalValue = strat.calcTotalValue();
            strat.divest(prevTotalValue);
            underlying.safeTransfer(address(strat_), underlying.balanceOf(address(this)));
            strat_.invest();
            if (!force) {
                require(strat_.calcTotalValue() >= prevTotalValue);
                require(strat.calcTotalValue() == 0);
            }
        } else {
            require(msg.sender == owner());
            _unpause();
        }
        strat = strat_;

        emit StrategyChanged(address(strat));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDistribution {
	function stake(address user, uint256 redeemTokens) external;

	function withdraw(address user, uint256 redeemAmount) external;

	function getReward(address user) external;

	function balanceOf(address account) external view returns (uint256);

	function rewardsToken() external view returns (address);

	function earned(address account) external view returns (uint256);

	function rewardPerToken() external view returns (uint256);

	function rewardRate() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IStrat.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/IDistribution.sol";
import "../../interfaces/IFeeManager.sol";
import "../../utils/Timelock.sol";
import "./DividendToken.sol";
import "./FeeManagerVaultV2.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Vault is FeeManagerVaultV2, Pausable, DividendToken {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Detailed;
    using SafeERC20 for IERC20;

    // EVENTS
    event HarvesterChanged(address newHarvester);
    event StrategyChanged(address newStrat);
    event DepositLimitUpdated(uint256 newLimit);
    event NewDistribution(address newDistribution);

    IERC20Detailed public underlying;
    IERC20 public rewards;
    IStrat public strat;
    Timelock public timelock;

    address public harvester;

    // if depositLimit = 0 then there is no deposit limit
    uint256 public depositLimit;
    uint256 public lastDistribution;
    address public distribution;

    modifier onlyHarvester() {
        require(msg.sender == harvester);
        _;
    }

    constructor(
        IERC20Detailed underlying_,
        IERC20 target_,
        IERC20 rewards_,
        address harvester_,
        string memory name_,
        string memory symbol_
    ) DividendToken(target_, name_, symbol_, underlying_.decimals()) {
        underlying = underlying_;
        rewards = rewards_;
        harvester = harvester_;
        // feeRecipient = msg.sender;
        depositLimit = 20000 * (10**underlying_.decimals()); // 20k initial deposit limit
        timelock = new Timelock(msg.sender, 3 days);
        _pause(); // paused until a strategy is connected
    }

    function _payWithdrawalFees(uint256 amt) internal returns (uint256 feesPaid) {
        if (withdrawalFee > 0 && amt > 0) {
            require(feeRecipient != address(0), "ZERO ADDRESS");

            feesPaid = amt.mul(withdrawalFee).div(MAX_FEE);

            underlying.safeTransfer(feeRecipient, feesPaid);
        }
    }

    function _syncDist() internal {
        // If distribution contract exists
        if (distribution != address(0)) {
            uint256 totalSupplied = balanceOf(msg.sender);

            // current staked amount
            uint256 totalStaked = IDistribution(distribution).balanceOf(msg.sender);

            // if total staked is bigger, unstake
            if (totalStaked > totalSupplied) {
                IDistribution(distribution).withdraw(msg.sender, totalStaked.sub(totalSupplied));
            }

            // if total supplied is bigger, stake
            if (totalSupplied > totalStaked) {
                IDistribution(distribution).stake(msg.sender, totalSupplied.sub(totalStaked));
            }
        }
    }

    function calcTotalValue() public view returns (uint256 underlyingAmount) {
        return strat.calcTotalValue();
    }

    function totalYield() public returns (uint256) {
        return strat.totalYield();
    }

    function deposit(uint256 amount) external whenNotPaused {
        require(amount > 0, "ZERO-AMOUNT");

        if (depositLimit > 0) {
            // if deposit limit is 0, then there is no deposit limit
            require(totalSupply().add(amount) <= depositLimit);
        }

        underlying.safeTransferFrom(msg.sender, address(strat), amount);
        strat.invest();

        _mint(msg.sender, amount);

        // Sync ETHA distribution
        _syncDist();
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "ZERO-AMOUNT");

        _burn(msg.sender, amount);

        strat.divest(amount);

        // Withdrawal fees
        uint feesPaid = _payWithdrawalFees(amount);

        underlying.safeTransfer(msg.sender, amount - feesPaid);

        // Sync ETHA distribution
        _syncDist();
    }

    function unclaimedProfit(address user) external view returns (uint256) {
        return withdrawableDividendOf(user);
    }

    function claim() public returns (uint256 claimed) {
        claimed = withdrawDividend(msg.sender);

        if (distribution != address(0)) {
            IDistribution(distribution).getReward(msg.sender);
        }
    }

    // Used to claim on behalf of certain contracts e.g. Uniswap pool
    function claimOnBehalf(address recipient) external {
        require(msg.sender == harvester || msg.sender == owner());
        withdrawDividend(recipient);
    }

    // ==== ONLY OWNER ===== //

    function updateDistribution(address newDistribution) public onlyOwner {
        distribution = newDistribution;
        emit NewDistribution(newDistribution);
    }

    function pauseDeposits(bool trigger) external onlyOwner {
        if (trigger) _pause();
        else _unpause();
    }

    function changeHarvester(address harvester_) external onlyOwner {
        harvester = harvester_;

        emit HarvesterChanged(harvester_);
    }

    // if limit == 0 then there is no deposit limit
    function setDepositLimit(uint256 limit) external onlyOwner {
        depositLimit = limit;

        emit DepositLimitUpdated(limit);
    }

    // Any tokens (other than the target) that are sent here by mistake are recoverable by the owner
    function sweep(address _token) external onlyOwner {
        require(_token != address(target));
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    // ==== ONLY HARVESTER ===== //

    function harvest() external onlyHarvester returns (uint256 afterFee) {
        // Divest and claim rewards
        uint256 claimed = strat.claim();

        require(claimed > 0, "Nothing to harvest");

        if (profitFee > 0) {
            // Calculate fees on underlying
            uint256 fee = claimed.mul(profitFee).div(MAX_FEE);
            afterFee = claimed.sub(fee);
            rewards.safeTransfer(feeRecipient, fee);
        } else {
            afterFee = claimed;
        }

        // Transfer rewards to harvester
        rewards.safeTransfer(harvester, afterFee);
    }

    function distribute(uint256 amount) external onlyHarvester {
        distributeDividends(amount);
        lastDistribution = block.timestamp;
    }

    // ==== ONLY TIMELOCK ===== //

    // The owner has to wait 2 days to confirm changing the strat.
    // This protects users from an upgrade to a malicious strategy
    // Users must watch the timelock contract on Etherscan for any transactions
    function setStrat(IStrat strat_, bool force) external {
        if (address(strat) != address(0)) {
            require(msg.sender == address(timelock), "Only Timelock");
            uint256 prevTotalValue = strat.calcTotalValue();
            strat.divest(prevTotalValue);
            underlying.safeTransfer(address(strat_), underlying.balanceOf(address(this)));
            strat_.invest();
            if (!force) {
                require(strat_.calcTotalValue() >= prevTotalValue);
                require(strat.calcTotalValue() == 0);
            }
        } else {
            require(msg.sender == owner());
            _unpause();
        }
        strat = strat_;

        emit StrategyChanged(address(strat));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../../../../interfaces/IUniswapV2Router.sol";
import "../../../../interfaces/IUniswapV2ERC20.sol";
import "../../../../interfaces/IWETH.sol";
import "../../../../interfaces/IMasterChef.sol";
import "../../CompoundFeeManager.sol";
import "../../CompoundStrat.sol";

contract StrategyTraderJoeDualLP is CompoundFeeManager, CompoundStrat {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Tokens used
    address public lpToken0;
    address public lpToken1;

    // Third party contracts
    address public chef;
    uint256 public poolId;

    // Routes
    address[] public outputToNativeRoute;
    address[] public nativeToLp0Route;
    address[] public nativeToLp1Route;

    /**
     * @dev Event that is fired each time someone harvests the strat.
     */
    event StratHarvest(address indexed harvester, uint256 wantHarvested, uint256 tvl);
    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);
    event ChargedFees(uint256 callFees, uint256 beefyFees, uint256 strategistFees);

    constructor(
        address _want,
        uint256 _poolId,
        address _chef,
        address _unirouter,
        address _keeper,
        address _strategist,
        address _ethaFeeRecipient,
        address[] memory _outputToNativeRoute,
        address[] memory _nativeToLp0Route,
        address[] memory _nativeToLp1Route
    ) CompoundStratManager(_keeper, _strategist, _unirouter, _ethaFeeRecipient) {
        want = _want;
        poolId = _poolId;
        chef = _chef;

        output = _outputToNativeRoute[0];
        native = _outputToNativeRoute[_outputToNativeRoute.length - 1];
        outputToNativeRoute = _outputToNativeRoute;

        // setup lp routing
        lpToken0 = IUniswapV2ERC20(want).token0();
        require(_nativeToLp0Route[0] == native, "nativeToLp0Route[0] != native");
        require(_nativeToLp0Route[_nativeToLp0Route.length - 1] == lpToken0, "nativeToLp0Route[last] != lpToken0");
        nativeToLp0Route = _nativeToLp0Route;

        lpToken1 = IUniswapV2ERC20(want).token1();
        require(_nativeToLp1Route[0] == native, "nativeToLp1Route[0] != native");
        require(_nativeToLp1Route[_nativeToLp1Route.length - 1] == lpToken1, "nativeToLp1Route[last] != lpToken1");
        nativeToLp1Route = _nativeToLp1Route;

        _giveAllowances();
    }

    // puts the funds to work
    function deposit() public override whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal > 0) {
            IMasterChef(chef).deposit(poolId, wantBal);
            uint256 _toWrap = address(this).balance;
            IWETH(native).deposit{value: _toWrap}();
            emit Deposit(balanceOf());
        }
    }

    function withdraw(uint256 _amount) external override {
        require(msg.sender == vault, "!vault");

        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal < _amount) {
            IMasterChef(chef).withdraw(poolId, _amount.sub(wantBal));

            uint256 _toWrap = address(this).balance;

            if (_toWrap > 0) {
                IWETH(native).deposit{value: _toWrap}();
            }

            wantBal = IERC20(want).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        IERC20(want).safeTransfer(vault, wantBal);

        emit Withdraw(balanceOf());
    }

    // compounds earnings and charges performance fee
    function _harvest(address callFeeRecipient) internal override {
        IMasterChef(chef).deposit(poolId, 0);
        uint256 _toWrap = address(this).balance;
        IWETH(native).deposit{value: _toWrap}();
        uint256 outputBal = IERC20(output).balanceOf(address(this));
        if (outputBal > 0) {
            chargeFees(callFeeRecipient);
            addLiquidity();
            uint256 wantHarvested = balanceOfWant();
            deposit();

            lastHarvest = block.timestamp;
            emit StratHarvest(msg.sender, wantHarvested, balanceOf());
        }
    }

    // performance fees
    function chargeFees(address callFeeRecipient) internal {
        uint256 toNative = IERC20(output).balanceOf(address(this));

        if (toNative > 0)
            IUniswapV2Router(unirouter).swapExactTokensForTokens(
                toNative,
                0,
                outputToNativeRoute,
                address(this),
                block.timestamp
            );
        else return;

        uint256 nativeFeeBal = IERC20(native).balanceOf(address(this)).mul(profitFee).div(MAX_FEE);

        _deductFees(native, callFeeRecipient, nativeFeeBal);
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 nativeHalf = IERC20(native).balanceOf(address(this)).div(2);

        if (lpToken0 != native) {
            IUniswapV2Router(unirouter).swapExactTokensForTokens(
                nativeHalf,
                0,
                nativeToLp0Route,
                address(this),
                block.timestamp
            );
        }

        if (lpToken1 != native) {
            IUniswapV2Router(unirouter).swapExactTokensForTokens(
                nativeHalf,
                0,
                nativeToLp1Route,
                address(this),
                block.timestamp
            );
        }

        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
        IUniswapV2Router(unirouter).addLiquidity(lpToken0, lpToken1, lp0Bal, lp1Bal, 1, 1, address(this), block.timestamp);
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOfStrategy() public view override returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() public view override returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view override returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view override returns (uint256) {
        (uint256 _amount, ) = IMasterChef(chef).userInfo(poolId, address(this));
        return _amount;
    }

    function rewardsAvailable()
        public
        view
        returns (
            uint256 outputBal,
            uint256 nativeBal,
            address bonusToken
        )
    {
        (outputBal, bonusToken, , nativeBal) = IMasterChef(chef).pendingTokens(poolId, address(this));
    }

    function callReward() public view returns (uint256) {
        (uint256 outputBal, uint256 nativeBal, ) = rewardsAvailable();
        if (outputBal > 0) {
            try IUniswapV2Router(unirouter).getAmountsOut(outputBal, outputToNativeRoute) returns (
                uint256[] memory amountOut
            ) {
                nativeBal = nativeBal.add(amountOut[amountOut.length - 1]);
            } catch {}
        }

        return nativeBal.mul(profitFee).div(MAX_FEE).mul(callFee).div(MAX_FEE);
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external override {
        require(msg.sender == vault, "!vault");

        IMasterChef(chef).emergencyWithdraw(poolId);

        uint256 wantBal = IERC20(want).balanceOf(address(this));
        IERC20(want).transfer(vault, wantBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public override onlyManager {
        pause();
        IMasterChef(chef).emergencyWithdraw(poolId);
    }

    function pause() public onlyManager {
        _pause();

        _removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function _giveAllowances() internal {
        IERC20(want).safeApprove(chef, type(uint256).max);
        IERC20(output).safeApprove(unirouter, type(uint256).max);
        IERC20(native).safeApprove(unirouter, type(uint256).max);

        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, type(uint256).max);

        IERC20(lpToken1).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, type(uint256).max);
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(chef, 0);
        IERC20(output).safeApprove(unirouter, 0);
        IERC20(native).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, 0);
    }

    function outputToNative() external view returns (address[] memory) {
        return outputToNativeRoute;
    }

    function nativeToLp0() external view returns (address[] memory) {
        return nativeToLp0Route;
    }

    function nativeToLp1() external view returns (address[] memory) {
        return nativeToLp1Route;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function emergencyWithdraw(uint256 _pid) external;

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256,
            address,
            string memory,
            uint256
        );

    function poolInfo(uint256 poolId)
        external
        view
        returns (
            address lpToken,
            uint allocPoint,
            uint accJoePerShare,
            uint accJoePerFactorPerShare,
            uint64 lastRewardTimestamp,
            address rewarder,
            uint32 veJoeShareBp,
            uint totalFactor,
            uint totalLpSupply
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../../interfaces/IUniswapV2Router.sol";
import "../../../../interfaces/IUniswapV2ERC20.sol";
import "../../../../interfaces/IQiStakingRewards.sol";
import "../../../../interfaces/IDelegateRegistry.sol";
import "../../CompoundStrat.sol";
import "../../CompoundFeeManager.sol";

contract StrategyQiChefLP is CompoundFeeManager, CompoundStrat {
    using SafeERC20 for IERC20;

    // Tokens used
    address public lpToken0;
    address public lpToken1;

    // Third party contracts
    address public chef;
    uint256 public poolId;

    string public pendingRewardsFunctionName;

    // Routes
    address[] public outputToNativeRoute;
    address[] public outputToLp0Route;
    address[] public outputToLp1Route;

    address public qiDelegationContract;

    event StratHarvest(address indexed harvester, uint256 wantHarvested, uint256 tvl);
    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);
    event ChargedFees(uint256 callFees, uint256 beefyFees, uint256 strategistFees);
    event VoterUpdated(address indexed voter);
    event DelegationContractUpdated(address indexed delegationContract);

    constructor(
        address _want,
        uint256 _poolId,
        address _chef,
        address _unirouter,
        address _keeper,
        address _strategist,
        address _ethaFeeRecipient,
        address[] memory _outputToNativeRoute,
        address[] memory _outputToLp0Route,
        address[] memory _outputToLp1Route
    ) CompoundStratManager(_keeper, _strategist, _unirouter, _ethaFeeRecipient) {
        want = _want;
        poolId = _poolId;
        chef = _chef;

        output = _outputToNativeRoute[0];
        native = _outputToNativeRoute[_outputToNativeRoute.length - 1];
        outputToNativeRoute = _outputToNativeRoute;

        // setup lp routing
        lpToken0 = IUniswapV2ERC20(want).token0();
        require(_outputToLp0Route[0] == output, "outputToLp0Route[0] != output");
        require(_outputToLp0Route[_outputToLp0Route.length - 1] == lpToken0, "outputToLp0Route[last] != lpToken0");
        outputToLp0Route = _outputToLp0Route;

        lpToken1 = IUniswapV2ERC20(want).token1();
        require(_outputToLp1Route[0] == output, "outputToLp1Route[0] != output");
        require(_outputToLp1Route[_outputToLp1Route.length - 1] == lpToken1, "outputToLp1Route[last] != lpToken1");
        outputToLp1Route = _outputToLp1Route;

        _giveAllowances();
    }

    // puts the funds to work
    function deposit() public override whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal > 0) {
            IQiStakingRewards(chef).deposit(poolId, wantBal);
            emit Deposit(balanceOf());
        }
    }

    function withdraw(uint256 _amount) external override {
        require(msg.sender == vault, "!vault");

        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal < _amount) {
            IQiStakingRewards(chef).withdraw(poolId, _amount - wantBal);
            wantBal = IERC20(want).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        IERC20(want).safeTransfer(vault, wantBal);

        emit Withdraw(balanceOf());
    }

    function beforeDeposit() external override {
        if (harvestOnDeposit) {
            require(msg.sender == vault, "!vault");
            _harvest(tx.origin);
        }
    }

    // compounds earnings and charges performance fee
    function _harvest(address callFeeRecipient) internal override whenNotPaused {
        IQiStakingRewards(chef).deposit(poolId, 0);
        uint256 outputBal = IERC20(output).balanceOf(address(this));
        if (outputBal > 0) {
            chargeFees(callFeeRecipient);
            addLiquidity();
            uint256 wantHarvested = balanceOfWant();
            deposit();

            lastHarvest = block.timestamp;
            emit StratHarvest(msg.sender, wantHarvested, balanceOf());
        }
    }

    // performance fees
    function chargeFees(address callFeeRecipient) internal {
        uint256 toNative = (IERC20(output).balanceOf(address(this)) * profitFee) / MAX_FEE;

        if (toNative > 0)
            IUniswapV2Router(unirouter).swapExactTokensForTokens(
                toNative,
                0,
                outputToNativeRoute,
                address(this),
                block.timestamp
            );
        else return;

        uint256 nativeFeeBal = IERC20(native).balanceOf(address(this));
        _deductFees(native, callFeeRecipient, nativeFeeBal);
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 outputHalf = IERC20(output).balanceOf(address(this)) / 2;
        if (lpToken0 != output) {
            IUniswapV2Router(unirouter).swapExactTokensForTokens(
                outputHalf,
                0,
                outputToLp0Route,
                address(this),
                block.timestamp
            );
        }

        if (lpToken1 != output) {
            IUniswapV2Router(unirouter).swapExactTokensForTokens(
                outputHalf,
                0,
                outputToLp1Route,
                address(this),
                block.timestamp
            );
        }

        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
        IUniswapV2Router(unirouter).addLiquidity(lpToken0, lpToken1, lp0Bal, lp1Bal, 1, 1, address(this), block.timestamp);
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() public view override returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOfStrategy() public view override returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view override returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view override returns (uint256) {
        (uint256 _amount, ) = IQiStakingRewards(chef).userInfo(poolId, address(this));
        return _amount;
    }

    // returns rewards unharvested
    function rewardsAvailable() public view returns (uint256) {
        return IQiStakingRewards(chef).pending(poolId, address(this));
    }

    // returns native reward for calling harvest
    function callReward() public view returns (uint256) {
        if (callFee == 0) return 0;

        uint256 outputBal = rewardsAvailable();
        uint256 nativeOut;
        if (outputBal > 0) {
            try IUniswapV2Router(unirouter).getAmountsOut(outputBal, outputToNativeRoute) returns (
                uint256[] memory amountOut
            ) {
                nativeOut = amountOut[amountOut.length - 1];
            } catch {}
        }

        return (nativeOut * profitFee * callFee) / (MAX_FEE * MAX_FEE);
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external override onlyVault {
        // Claim rewards and compound
        _harvest(ethaFeeRecipient);

        // Withdraw all funds from gauge
        IQiStakingRewards(chef).withdraw(poolId, balanceOfPool());

        uint256 wantBal = balanceOfWant();
        IERC20(want).safeTransfer(vault, wantBal);
    }

    function _giveAllowances() internal {
        IERC20(want).safeApprove(chef, type(uint).max);
        IERC20(output).safeApprove(unirouter, type(uint).max);

        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, type(uint).max);

        IERC20(lpToken1).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, type(uint).max);
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(chef, 0);
        IERC20(output).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, 0);
    }

    /// @notice Delegate Qi voting power to another address
    /// @param id   The delegate ID
    /// @param voter Address to delegate the votes to
    function _delegateVotingPower(bytes32 id, address voter) internal {
        IDelegateRegistry(qiDelegationContract).setDelegate(id, voter);
    }

    function outputToNative() external view returns (address[] memory) {
        return outputToNativeRoute;
    }

    function outputToLp0() external view returns (address[] memory) {
        return outputToLp0Route;
    }

    function outputToLp1() external view returns (address[] memory) {
        return outputToLp1Route;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////      Admin functions      ///////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public override onlyManager {
        pause();
        IQiStakingRewards(chef).withdraw(poolId, balanceOfPool());
    }

    function pause() public onlyManager {
        _pause();

        _removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function setPendingRewardsFunctionName(string calldata _pendingRewardsFunctionName) external onlyManager {
        pendingRewardsFunctionName = _pendingRewardsFunctionName;
    }

    /// @notice Delegate Qi voting power to another address
    /// @param _id   The delegate ID
    /// @param _voter Address to delegate the votes to
    function delegateVotes(bytes32 _id, address _voter) external onlyManager {
        _delegateVotingPower(_id, _voter);
        emit VoterUpdated(_voter);
    }

    /// @notice Updates the delegation contract for Qi token Lock
    /// @param _delegationContract Updated delegation contract address
    function updateQiDelegationContract(address _delegationContract) external onlyManager {
        require(_delegationContract == address(0), "ZERO_ADDRESS");
        qiDelegationContract = _delegationContract;
        emit DelegationContractUpdated(_delegationContract);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../../../interfaces/IStrat.sol";
import "../../../../interfaces/IVault.sol";
import "../../../../interfaces/IQiStakingRewards.sol";
import "../../../../interfaces/IDelegateRegistry.sol";
import "../../../../utils/Timelock.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract QiDaoStrat is IStrat {
    using SafeERC20 for IERC20;

    // ==== STATE ===== //

    IERC20 public constant QI = IERC20(0x580A84C73811E1839F75d86d75d88cCa0c241fF4);

    IVault public vault;

    // QiDao contracts
    address public chef;
    address public qiDelegationContract;
    uint public poolId;

    // LP token to deposit in chef
    IERC20 public underlying;

    Timelock public timelock;

    // Rewards swap details
    address public override router;
    address[] public outputToTargetRoute;

    // EVENTS
    event VoterUpdated(address indexed voter);
    event DelegationContractUpdated(address indexed delegationContract);

    // ==== MODIFIERS ===== //

    modifier onlyVault() {
        require(msg.sender == address(vault), "!vault");
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == address(timelock), "!timelock");
        _;
    }

    // ==== INITIALIZATION ===== //

    constructor(
        IVault vault_,
        IERC20 underlying_,
        address chef_,
        uint poolId_,
        address router_,
        address[] memory outputToTargetRoute_
    ) {
        require(outputToTargetRoute_[0] == address(QI));
        require(outputToTargetRoute_[outputToTargetRoute_.length - 1] == address(vault_.target()));

        vault = vault_;
        underlying = underlying_;
        chef = chef_;
        poolId = poolId_;
        router = router_;
        outputToTargetRoute = outputToTargetRoute_;

        timelock = new Timelock(msg.sender, 3 days);

        // Infite Approvals
        underlying.safeApprove(chef, type(uint256).max);
    }

    // ==== GETTERS ===== //

    /**
		@dev total value of LP tokens staked on QiDao Staking Contract
	*/
    function calcTotalValue() external view override returns (uint256) {
        return IQiStakingRewards(chef).deposited(poolId, address(this));
    }

    /**
		@dev amount of claimable QI
	*/
    function totalYield() external view override returns (uint256) {
        return IQiStakingRewards(chef).pending(poolId, address(this));
    }

    function outputToTarget() external view override returns (address[] memory) {
        return outputToTargetRoute;
    }

    // ==== MAIN FUNCTIONS ===== //

    /**
		@notice Invest LP Tokens into QiDao staking contract
		@dev can only be called by the vault contract
	*/
    function invest() external override onlyVault {
        uint256 balance = underlying.balanceOf(address(this));
        require(balance > 0);

        IQiStakingRewards(chef).deposit(poolId, balance);
    }

    /**
		@notice Redeem LP Tokens from QiDao staking contract
		@dev can only be called by the vault contract
		@param amount amount of LP Tokens to withdraw
	*/
    function divest(uint256 amount) public override onlyVault {
        uint amtBefore = underlying.balanceOf(address(this));

        IQiStakingRewards(chef).withdraw(poolId, amount);

        // If there are withdrawal fees in staking contract
        uint withdrawn = underlying.balanceOf(address(this)) - amtBefore;

        underlying.safeTransfer(address(vault), withdrawn);
    }

    /**
		@notice Claim QI rewards from staking contract
		@dev can only be called by the vault contract
		@dev only used when harvesting
	*/
    function claim() external override onlyVault returns (uint256 claimed) {
        IQiStakingRewards(chef).withdraw(poolId, 0);

        claimed = QI.balanceOf(address(this));
        QI.safeTransfer(address(vault), claimed);
    }

    // ==== RESCUE ===== //

    // IMPORTANT: This function can only be called by the timelock to recover any token amount including deposited cTokens
    // However, the owner of the timelock must first submit their request and wait timelock.delay() seconds before confirming.
    // This gives depositors a good window to withdraw before a potentially malicious escape
    // The intent is for the owner to be able to rescue funds in the case they become stuck after launch
    // However, users should not trust the owner and watch the timelock contract least once a week on Etherscan
    // In the future, the timelock contract will be destroyed and the functionality will be removed after the code gets audited
    function rescue(
        address _token,
        address _to,
        uint256 _amount
    ) external override onlyTimelock {
        IERC20(_token).transfer(_to, _amount);
    }

    function setSwapRoute(address[] memory outputToTargetRoute_) external override onlyTimelock {
        require(outputToTargetRoute_[0] == address(QI));
        require(outputToTargetRoute_[outputToTargetRoute_.length - 1] == address(vault.target()));

        outputToTargetRoute = outputToTargetRoute_;
    }

    function setRouter(address router_) external override onlyTimelock {
        router = router_;
    }

    /// @notice Delegate Qi voting power to another address
    /// @param _id   The delegate ID
    /// @param _voter Address to delegate the votes to
    function delegateVotes(bytes32 _id, address _voter) external onlyTimelock {
        IDelegateRegistry(qiDelegationContract).setDelegate(_id, _voter);
        emit VoterUpdated(_voter);
    }

    /// @notice Updates the delegation contract for Qi token Lock
    /// @param _delegationContract Updated delegation contract address
    function updateQiDelegationContract(address _delegationContract) external onlyTimelock {
        require(_delegationContract == address(0), "ZERO_ADDRESS");
        qiDelegationContract = _delegationContract;
        emit DelegationContractUpdated(_delegationContract);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract NFTReceiver is ERC721Holder {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

contract Memory {
    mapping(uint256 => uint256) values;

    function getUint(uint256 id) external view returns (uint256) {
        return values[id];
    }

    function setUint(uint256 id, uint256 _value) external {
        values[id] = _value;
    }
}

/**
 * @title Logic Auth
 */
contract LogicAuth is AccessControlEnumerable {
    /// @dev Constant State
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant PARTNER_ROLE = keccak256("PARTNER_ROLE");

    /// @notice Map of logic proxy state
    mapping(address => bool) public enabledLogics;

    /**
     * @dev Event List
     */
    event LogicEnabled(address indexed logicAddress);
    event LogicDisabled(address indexed logicAddress);

    /**
     * @dev Throws if the logic is not authorised
     */
    modifier logicAuth(address logicAddr) {
        require(logicAddr != address(0), "ZERO-ADDRES");
        require(enabledLogics[logicAddr], "!AUTHORIZED");
        _;
    }

    /// @dev
    /// @param _logicAddress (address)
    /// @return  (bool)
    function logic(address _logicAddress) external view returns (bool) {
        return enabledLogics[_logicAddress];
    }

    /// @dev Enable logic proxy address
    /// @param _logicAddress (address)
    function enableLogic(address _logicAddress) public onlyRole(MANAGER_ROLE) {
        require(_logicAddress != address(0), "ZERO-ADDRESS");
        enabledLogics[_logicAddress] = true;
        emit LogicEnabled(_logicAddress);
    }

    /// @dev Enable multiple logic proxy addresses
    /// @param _logicAddresses (addresses)
    function enableLogicMultiple(address[] calldata _logicAddresses) external {
        for (uint256 i = 0; i < _logicAddresses.length; i++) {
            enableLogic(_logicAddresses[i]);
        }
    }

    /// @dev Disable logic proxy address
    /// @param _logicAddress (address)
    function disableLogic(address _logicAddress) public onlyRole(MANAGER_ROLE) {
        require(_logicAddress != address(0), "ZERO-ADDRESS");
        enabledLogics[_logicAddress] = false;
        emit LogicDisabled(_logicAddress);
    }

    /// @dev Disable multiple logic proxy addresses
    /// @param _logicAddresses (addresses)
    function disableLogicMultiple(address[] calldata _logicAddresses) external {
        for (uint256 i = 0; i < _logicAddresses.length; i++) {
            disableLogic(_logicAddresses[i]);
        }
    }
}

/**
 * @title Zapper Contract
 */
contract Zapper is Memory, LogicAuth, NFTReceiver {
    using SafeERC20 for IERC20;

    uint public swapFee;
    uint256 public constant MAX_FEE = 10000;
    address public feeRecipient;
    address public adapter;

    /**
     * @dev initializes admin role to deployer
     */
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
    }

    /**
        @dev internal function in charge of executing an action
        @dev checks if the target address is allowed to be called
     */
    function _execute(address _target, bytes memory _data) internal logicAuth(_target) {
        require(_target != address(0), "target-invalid");
        assembly {
            let succeeded := delegatecall(gas(), _target, add(_data, 0x20), mload(_data), 0, 0)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                let size := returndatasize()
                returndatacopy(0x00, 0x00, size)
                revert(0x00, size)
            }
        }
    }

    /**
        @notice main function of the zapper
        @dev executes multiple delegate calls using the internal _execute fx
        @param targets address array of the logic contracts to use
        @param datas bytes array of the encoded function calls
     */
    function execute(address[] calldata targets, bytes[] calldata datas) external payable {
        for (uint256 i = 0; i < targets.length; i++) {
            _execute(targets[i], datas[i]);
        }
    }

    /// @dev Set swap fee (1% = 100)
    /// @param _swapFee new swap fee value
    function setSwapFee(uint256 _swapFee) external onlyRole(MANAGER_ROLE) {
        swapFee = _swapFee;
    }

    /// @dev Set swap fee recipient
    /// @param _adapter address of new fee recipient
    function setAdapterAddress(address _adapter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        adapter = _adapter;
    }

    /// @dev Set swap fee recipient
    /// @param _feeRecipient address of new adapter contract
    function setFeeRecipient(address _feeRecipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeRecipient = _feeRecipient;
    }

    /// @dev Rescues ERC20 tokens
    /// @param _token address of the token to rescue.
    function inCaseTokensGetStuck(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(_token).safeTransfer(_msgSender(), IERC20(_token).balanceOf(address(this)));
    }

    /// @dev Rescues ERC721 tokens
    /// @param _token address of the token to rescue.
    function inCaseERC721GetStuck(address _token, uint tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC721(_token).safeTransferFrom(address(this), _msgSender(), tokenId);
    }

    /// @dev Rescues ERC1155 tokens
    /// @param _token address of the token to rescue.
    function inCaseERC1155GetStuck(address _token, uint tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC1155(_token).safeTransferFrom(
            address(this),
            _msgSender(),
            tokenId,
            IERC1155(_token).balanceOf(address(this), tokenId),
            "0x0"
        );
    }

    /// @dev Don't accept ETH deposits, use execute function
    receive() external payable {
        revert();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/presets/ERC20PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../extensions/ERC20Burnable.sol";
import "../extensions/ERC20Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC20PresetMinterPauser is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../../../interfaces/IStrat.sol";
import "../../../../interfaces/IVault.sol";
import "../../../../interfaces/IMasterChef.sol";
import "../../../../utils/Timelock.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract JoeStratChef is IStrat {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ==== STATE ===== //

    IVault public vault;

    IERC20 public constant JOE = IERC20(0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd);
    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    IMasterChef public constant CHEF = IMasterChef(0x4483f0b6e2F5486D06958C20f8C39A7aBe87bf8F);

    // TraderJoe LP
    IERC20 public underlying;

    Timelock public timelock;

    // Rewards swap details
    address public override router;
    address[] public outputToTargetRoute;

    uint public poolId;

    // ==== MODIFIERS ===== //

    modifier onlyVault() {
        require(msg.sender == address(vault));
        _;
    }

    // ==== INITIALIZATION ===== //

    constructor(
        IVault vault_,
        IERC20 underlying_,
        uint poolId_,
        address router_,
        address[] memory outputToTargetRoute_
    ) {
        require(outputToTargetRoute_[0] == address(JOE));
        require(outputToTargetRoute_[outputToTargetRoute_.length - 1] == address(vault_.target()));
        vault = vault_;
        underlying = underlying_;
        poolId = poolId_;
        router = router_;
        outputToTargetRoute = outputToTargetRoute_;

        timelock = new Timelock(msg.sender, 3 days);

        // Infite Approvals
        underlying.safeApprove(address(CHEF), type(uint256).max);
    }

    // ==== GETTERS ===== //

    /**
		@dev total value of LP tokens staked on Joe Master Chef
	*/
    function calcTotalValue() external view override returns (uint256) {
        (uint256 _amount, ) = CHEF.userInfo(poolId, address(this));
        return _amount;
    }

    /**
		@dev amount of claimable JOE
	*/
    function totalYield() external view override returns (uint256) {
        (uint outputBal, , , ) = CHEF.pendingTokens(poolId, address(this));

        return outputBal;
    }

    function outputToTarget() external view override returns (address[] memory) {
        return outputToTargetRoute;
    }

    // ==== MAIN FUNCTIONS ===== //

    /**
		@notice Invest LP Tokens into Chef staking contract
		@dev can only be called by the vault contract
	*/
    function invest() external override onlyVault {
        uint256 balance = underlying.balanceOf(address(this));
        require(balance > 0, "!BALANCE");

        CHEF.deposit(poolId, balance);
    }

    /**
		@notice Redeem LP Tokens from Quickswap staking contract
		@dev can only be called by the vault contract
		@param amount amount of LP Tokens to withdraw
	*/
    function divest(uint256 amount) public override onlyVault {
        CHEF.withdraw(poolId, amount);

        underlying.safeTransfer(address(vault), amount);
    }

    /**
		@notice Claim QUICK rewards from staking contract
		@dev can only be called by the vault contract
		@dev only used when harvesting
	*/
    function claim() external override onlyVault returns (uint256 claimed) {
        CHEF.deposit(poolId, 0);

        claimed = JOE.balanceOf(address(this));
        JOE.safeTransfer(address(vault), claimed);
    }

    // ==== RESCUE ===== //

    // IMPORTANT: This function can only be called by the timelock to recover any token amount including deposited cTokens
    // However, the owner of the timelock must first submit their request and wait 7 days before confirming.
    // This gives depositors a good window to withdraw before a potentially malicious escape
    // The intent is for the owner to be able to rescue funds in the case they become stuck after launch
    // However, users should not trust the owner and watch the timelock contract least once a week on Etherscan
    // In the future, the timelock contract will be destroyed and the functionality will be removed after the code gets audited
    function rescue(
        address _token,
        address _to,
        uint256 _amount
    ) external override {
        require(msg.sender == address(timelock));
        IERC20(_token).transfer(_to, _amount);
    }

    // Any tokens (other than the lpToken) that are sent here by mistake are recoverable by the vault owner
    function sweep(address _token) external {
        address owner = vault.owner();
        require(msg.sender == owner);
        require(_token != address(underlying));
        IERC20(_token).transfer(owner, IERC20(_token).balanceOf(address(this)));
    }

    function setSwapRoute(address[] memory outputToTargetRoute_) external override {
        require(msg.sender == address(timelock));
        require(outputToTargetRoute_[0] == address(JOE));
        require(outputToTargetRoute_[outputToTargetRoute_.length - 1] == address(vault.target()));

        outputToTargetRoute = outputToTargetRoute_;
    }

    function setRouter(address router_) external override {
        require(msg.sender == address(timelock));
        router = router_;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../../../interfaces/IStrat.sol";
import "../../../../interfaces/IVault.sol";
import "../../../../interfaces/IMiniChefV2.sol";
import "../../../../interfaces/IUniswapV2Router.sol";
import "../../../../utils/Timelock.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SushiStrat is IStrat {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ==== STATE ===== //

    IVault public vault;

    address public constant SUSHI = 0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a;
    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant SUSHI_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    // Masterchef
    address public chef;
    uint public poolId;

    // Sushiswap LP
    IERC20 public underlying;

    Timelock public timelock;

    // Rewards swap details
    address public override router;
    address[] public outputToTargetRoute;

    // ==== MODIFIERS ===== //

    modifier onlyVault() {
        require(msg.sender == address(vault));
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == address(timelock), "!timelock");
        _;
    }

    // ==== INITIALIZATION ===== //

    constructor(
        IVault vault_,
        IERC20 underlying_,
        address chef_,
        uint poolId_,
        address router_,
        address[] memory outputToTargetRoute_
    ) {
        require(outputToTargetRoute_[0] == address(SUSHI));
        require(outputToTargetRoute_[outputToTargetRoute_.length - 1] == address(vault_.target()));

        vault = vault_;
        underlying = underlying_;
        chef = chef_;
        poolId = poolId_;
        router = router_;
        outputToTargetRoute = outputToTargetRoute_;

        timelock = new Timelock(msg.sender, 3 days);

        // Infite Approvals
        underlying.safeApprove(chef, type(uint256).max);
        underlying.safeApprove(address(vault), type(uint256).max);
        IERC20(WMATIC).safeApprove(SUSHI_ROUTER, type(uint256).max);
    }

    // ==== GETTERS ===== //

    /**
		@dev total value of LP tokens staked on Quickswap Staking Contracts
	*/
    function calcTotalValue() external view override returns (uint256) {
        (uint256 _amount, ) = IMiniChefV2(chef).userInfo(poolId, address(this));
        return _amount;
    }

    /**
		@dev amount of claimable SUSHI
	*/
    function totalYield() external view override returns (uint256) {
        return IMiniChefV2(chef).pendingSushi(poolId, address(this));
    }

    function outputToTarget() external view override returns (address[] memory) {
        return outputToTargetRoute;
    }

    // ==== MAIN FUNCTIONS ===== //

    /**
		@notice Invest LP Tokens into Quickswap staking contract
		@dev can only be called by the vault contract
	*/
    function invest() external override onlyVault {
        uint256 balance = underlying.balanceOf(address(this));
        require(balance > 0);

        IMiniChefV2(chef).deposit(poolId, balance, address(this));
    }

    /**
		@notice Redeem LP Tokens from Quickswap staking contract
		@dev can only be called by the vault contract
		@param amount amount of LP Tokens to withdraw
	*/
    function divest(uint256 amount) public override onlyVault {
        IMiniChefV2(chef).withdraw(poolId, amount, address(this));

        underlying.safeTransfer(address(vault), amount);
    }

    /**
		@notice Claim QUICK rewards from staking contract
		@dev can only be called by the vault contract
		@dev only used when harvesting
	*/
    function claim() external override onlyVault returns (uint256 claimed) {
        IMiniChefV2(chef).harvest(poolId, address(this));

        // if wmatic received, swap for sushi
        uint256 wmaticBal = IERC20(WMATIC).balanceOf(address(this));
        if (wmaticBal > 0) {
            address[] memory path = new address[](2);
            path[0] = WMATIC;
            path[1] = SUSHI;
            IUniswapV2Router(SUSHI_ROUTER).swapExactTokensForTokens(wmaticBal, 0, path, address(this), block.timestamp);
        }

        uint256 sushiBal = IERC20(SUSHI).balanceOf(address(this));
        IERC20(SUSHI).safeTransfer(address(vault), sushiBal);

        return sushiBal;
    }

    // ==== RESCUE ===== //

    // IMPORTANT: This function can only be called by the timelock to recover any token amount including deposited cTokens
    // However, the owner of the timelock must first submit their request and wait timelock.delay() seconds before confirming.
    // This gives depositors a good window to withdraw before a potentially malicious escape
    // The intent is for the owner to be able to rescue funds in the case they become stuck after launch
    // However, users should not trust the owner and watch the timelock contract least once a week on Etherscan
    // In the future, the timelock contract will be destroyed and the functionality will be removed after the code gets audited
    function rescue(
        address _token,
        address _to,
        uint256 _amount
    ) external override onlyTimelock {
        IERC20(_token).transfer(_to, _amount);
    }

    function setSwapRoute(address[] memory outputToTargetRoute_) external override onlyTimelock {
        require(outputToTargetRoute_[0] == address(SUSHI));
        require(outputToTargetRoute_[outputToTargetRoute_.length - 1] == address(vault.target()));

        outputToTargetRoute = outputToTargetRoute_;
    }

    function setRouter(address router_) external override onlyTimelock {
        router = router_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISushiRewarder.sol";

interface IMiniChefV2 {
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, ISushiRewarder indexed rewarder);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint, ISushiRewarder indexed rewarder, bool overwrite);
    event LogUpdatePool(uint256 indexed pid, uint64 lastRewardTime, uint256 lpSupply, uint256 accSushiPerShare);
    event LogSushiPerSecond(uint256 sushiPerSecond);

    function poolLength() external view returns (uint256);

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);

    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function withdraw(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function harvest(uint256 pid, address to) external;

    function withdrawAndHarvest(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function emergencyWithdraw(uint256 pid, address to) external;

    function rewarder(uint256 pid) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISushiRewarder {
    function poolLength() external view returns (uint256);

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function pendingToken(uint256 _pid, address _user) external view returns (uint256);

    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function withdraw(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function harvest(uint256 pid, address to) external;

    function withdrawAndHarvest(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function emergencyWithdraw(uint256 pid, address to) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../../../interfaces/IStrat.sol";
import "../../../../interfaces/IVault.sol";
import "../../../../interfaces/IStakingRewards.sol";
import "../../../../interfaces/IDragonLair.sol";
import "../../../../utils/Timelock.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract QuickStratV2 is IStrat {
    using SafeERC20 for IERC20;

    // ==== STATE ===== //

    IVault public vault;

    IERC20 public constant QUICK = IERC20(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);

    IDragonLair public constant DQUICK = IDragonLair(0xf28164A485B0B2C90639E47b0f377b4a438a16B1);

    // Quikswap LP Staking Rewards Contract
    IStakingRewards public staking;

    // Quickswap LP
    IERC20 public underlying;

    Timelock public timelock;

    // Rewards swap details
    address public override router;
    address[] public outputToTargetRoute;

    // ==== MODIFIERS ===== //

    modifier onlyVault() {
        require(msg.sender == address(vault), "!vault");
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == address(timelock), "!timelock");
        _;
    }

    // ==== INITIALIZATION ===== //

    constructor(
        IVault vault_,
        IStakingRewards _staking,
        IERC20 _underlying,
        address router_,
        address[] memory outputToTargetRoute_
    ) {
        require(outputToTargetRoute_[0] == address(QUICK));
        require(outputToTargetRoute_[outputToTargetRoute_.length - 1] == address(vault_.target()));

        vault = vault_;
        staking = _staking;
        underlying = _underlying;
        router = router_;
        outputToTargetRoute = outputToTargetRoute_;

        timelock = new Timelock(msg.sender, 3 days);

        // Infite Approvals
        underlying.safeApprove(address(staking), type(uint256).max);
        underlying.safeApprove(address(vault), type(uint256).max);
        QUICK.safeApprove(address(vault), type(uint256).max);
    }

    // ==== GETTERS ===== //

    /**
		@dev total value of LP tokens staked on Quickswap Staking Contracts
	*/
    function calcTotalValue() public view override returns (uint256) {
        return staking.balanceOf(address(this));
    }

    /**
		@dev amount of claimable QUICK
	*/
    function totalYield() external view override returns (uint256) {
        uint256 _earned = staking.earned(address(this));

        return DQUICK.dQUICKForQUICK(_earned);
    }

    function outputToTarget() external view override returns (address[] memory) {
        return outputToTargetRoute;
    }

    // ==== MAIN FUNCTIONS ===== //

    /**
		@notice Invest LP Tokens into Quickswap staking contract
		@dev can only be called by the vault contract
	*/
    function invest() external override onlyVault {
        uint256 balance = underlying.balanceOf(address(this));
        require(balance > 0);

        staking.stake(balance);
    }

    /**
		@notice Redeem LP Tokens from Quickswap staking contract
		@dev can only be called by the vault contract
		@param amount amount of LP Tokens to withdraw
	*/
    function divest(uint256 amount) public override onlyVault {
        staking.withdraw(amount);

        underlying.safeTransfer(address(vault), amount);
    }

    /**
		@notice Claim QUICK rewards from staking contract
		@dev can only be called by the vault contract
		@dev only used when harvesting
	*/
    function claim() external override onlyVault returns (uint256 claimed) {
        staking.getReward();

        uint256 claimedDQUICK = DQUICK.balanceOf(address(this));
        DQUICK.leave(claimedDQUICK);

        claimed = QUICK.balanceOf(address(this));
        QUICK.safeTransfer(address(vault), claimed);
    }

    // ==== RESCUE ===== //

    // IMPORTANT: This function can only be called by the timelock to recover any token amount including deposited cTokens
    // However, the owner of the timelock must first submit their request and wait timelock.delay() seconds before confirming.
    // This gives depositors a good window to withdraw before a potentially malicious escape
    // The intent is for the owner to be able to rescue funds in the case they become stuck after launch
    // However, users should not trust the owner and watch the timelock contract least once a week on Etherscan
    // In the future, the timelock contract will be destroyed and the functionality will be removed after the code gets audited
    function rescue(
        address _token,
        address _to,
        uint256 _amount
    ) external override onlyTimelock {
        IERC20(_token).transfer(_to, _amount);
    }

    function setSwapRoute(address[] memory outputToTargetRoute_) external override onlyTimelock {
        require(outputToTargetRoute_[0] == address(QUICK));
        require(outputToTargetRoute_[outputToTargetRoute_.length - 1] == address(vault.target()));

        outputToTargetRoute = outputToTargetRoute_;
    }

    function setRouter(address router_) external override onlyTimelock {
        router = router_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../../interfaces/IERC20Extended.sol";
import "../../../../interfaces/IUniswapV2Router.sol";
import "../../../../interfaces/IUniswapV2ERC20.sol";
import "../../../../interfaces/IRewardPool.sol";
import "../../../../interfaces/IDragonLair.sol";
import "../../CompoundStrat.sol";

contract StrategyPolygonQuickLP is CompoundStrat {
    using SafeERC20 for IERC20;

    // Tokens used
    address public lpToken0;
    address public lpToken1;

    // Third party contracts
    address public rewardPool;
    address public constant dragonsLair = address(0xf28164A485B0B2C90639E47b0f377b4a438a16B1);

    // Routes
    address[] public outputToNativeRoute;
    address[] public outputToLp0Route;
    address[] public outputToLp1Route;

    /**
     * @dev Event that is fired each time someone harvests the strat.
     */
    event StratHarvest(address indexed harvester, uint256 wantHarvested, uint256 tvl);
    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);

    constructor(
        address _want,
        address _rewardPool,
        address _unirouter,
        address _keeper,
        address _strategist,
        address _ethaFeeRecipient,
        address[] memory _outputToNativeRoute,
        address[] memory _outputToLp0Route,
        address[] memory _outputToLp1Route
    ) CompoundStratManager(_keeper, _strategist, _unirouter, _ethaFeeRecipient) {
        want = _want;
        rewardPool = _rewardPool;

        require(_outputToNativeRoute.length >= 2);
        output = _outputToNativeRoute[0];
        native = _outputToNativeRoute[_outputToNativeRoute.length - 1];
        outputToNativeRoute = _outputToNativeRoute;

        // setup lp routing
        lpToken0 = IUniswapV2ERC20(want).token0();
        require(_outputToLp0Route[0] == output);
        require(_outputToLp0Route[_outputToLp0Route.length - 1] == lpToken0);
        outputToLp0Route = _outputToLp0Route;

        lpToken1 = IUniswapV2ERC20(want).token1();
        require(_outputToLp1Route[0] == output);
        require(_outputToLp1Route[_outputToLp1Route.length - 1] == lpToken1);
        outputToLp1Route = _outputToLp1Route;

        _giveAllowances();
    }

    // puts the funds to work
    function deposit() public override whenNotPaused {
        uint256 wantBal = balanceOfWant();

        if (wantBal > 0) {
            IRewardPool(rewardPool).stake(wantBal);
            emit Deposit(balanceOf());
        }
    }

    function withdraw(uint256 _amount) external override whenNotPaused onlyVault {
        uint256 wantBal = balanceOfWant();

        if (wantBal < _amount) {
            IRewardPool(rewardPool).withdraw(_amount - wantBal);
            wantBal = balanceOfWant();
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        IERC20(want).safeTransfer(vault, wantBal);
        emit Withdraw(balanceOf());
    }

    // compounds earnings and charges performance fee
    function _harvest(address callFeeRecipient) internal override whenNotPaused {
        IRewardPool(rewardPool).getReward();
        uint256 lairBal = IERC20(dragonsLair).balanceOf(address(this));
        IDragonLair(dragonsLair).leave(lairBal);

        uint256 outputBal = IERC20(output).balanceOf(address(this));

        // If there are profits
        if (outputBal > 0) {
            chargeFees(callFeeRecipient);
            addLiquidity();
            uint256 wantHarvested = balanceOfWant();
            deposit();

            lastHarvest = block.timestamp;
            emit StratHarvest(msg.sender, wantHarvested, balanceOf());
        }
    }

    // performance fees
    function chargeFees(address callFeeRecipient) internal {
        uint256 toNative = (IERC20(output).balanceOf(address(this)) * profitFee) / MAX_FEE;

        if (toNative > 0)
            IUniswapV2Router(unirouter).swapExactTokensForTokens(
                toNative,
                0,
                outputToNativeRoute,
                address(this),
                block.timestamp
            );
        else return;

        uint256 nativeFeeBal = IERC20(native).balanceOf(address(this));

        _deductFees(native, callFeeRecipient, nativeFeeBal);
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 outputHalf = IERC20(output).balanceOf(address(this)) / 2;

        if (lpToken0 != output) {
            IUniswapV2Router(unirouter).swapExactTokensForTokens(
                outputHalf,
                0,
                outputToLp0Route,
                address(this),
                block.timestamp
            );
        }

        if (lpToken1 != output) {
            IUniswapV2Router(unirouter).swapExactTokensForTokens(
                outputHalf,
                0,
                outputToLp1Route,
                address(this),
                block.timestamp
            );
        }

        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
        IUniswapV2Router(unirouter).addLiquidity(lpToken0, lpToken1, lp0Bal, lp1Bal, 1, 1, address(this), block.timestamp);
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() public view override returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view override returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view override returns (uint256) {
        return IRewardPool(rewardPool).balanceOf(address(this));
    }

    /// @notice calculate the total underlying 'want' held by the strat
    /// @dev This is equivalent to the amount of want in the strat and the amount invested in staking contract
    function balanceOfStrategy() public view override returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // returns rewards unharvested
    function rewardsAvailable() public view returns (uint256) {
        uint256 lairReward = IRewardPool(rewardPool).earned(address(this));
        return IDragonLair(dragonsLair).dQUICKForQUICK(lairReward);
    }

    // returns native reward for calling harvest
    function callReward() public view returns (uint256) {
        if (callFee == 0) return 0;

        uint256 outputBal = rewardsAvailable();
        uint256 nativeOut;
        if (outputBal > 0) {
            try IUniswapV2Router(unirouter).getAmountsOut(outputBal, outputToNativeRoute) returns (
                uint256[] memory amountOut
            ) {
                nativeOut = amountOut[amountOut.length - 1];
            } catch {}
        }

        return (nativeOut * profitFee * callFee) / (MAX_FEE * MAX_FEE);
    }

    // Returns the maximum amount of asset tokens that can be deposited
    function getMaximumDepositLimit() public pure returns (uint256) {
        return type(uint256).max;
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external override onlyVault {
        // Claim rewards and compound
        _harvest(ethaFeeRecipient);

        // Withdraw all funds from gauge
        IRewardPool(rewardPool).withdraw(balanceOfPool());

        uint256 wantBal = balanceOfWant();
        IERC20(want).safeTransfer(vault, wantBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public override onlyManager {
        pause();
        IRewardPool(rewardPool).withdraw(balanceOfPool());
    }

    function pause() public onlyManager {
        _pause();

        _removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function _giveAllowances() internal {
        IERC20(want).safeApprove(rewardPool, type(uint256).max);
        IERC20(output).safeApprove(unirouter, type(uint256).max);

        if (output != lpToken0) IERC20(lpToken0).safeApprove(unirouter, type(uint256).max);
        if (output != lpToken1) IERC20(lpToken1).safeApprove(unirouter, type(uint256).max);
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(rewardPool, 0);
        IERC20(output).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Extended {
	function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardPool {
	function deposit(uint256 amount) external;

	function stake(uint256 amount) external;

	function withdraw(uint256 amount) external;

	function earned(address account) external view returns (uint256);

	function getReward() external;

	function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../../interfaces/IUniswapV2Router.sol";
import "../../../../interfaces/IUniswapV2ERC20.sol";
import "../../../../interfaces/IMiniChefV2.sol";
import "../../../../interfaces/ISushiRewarder.sol";
import "../../CompoundStrat.sol";

contract StrategySushiNativeDualLP is CompoundStrat {
    using SafeERC20 for IERC20;

    // Tokens used
    address public lpToken0;
    address public lpToken1;

    // Third party contracts
    address public chef;
    uint256 public poolId;

    // Routes
    address[] public outputToNativeRoute;
    address[] public nativeToLp0Route;
    address[] public nativeToLp1Route;

    /**
     * @dev Event that is fired each time someone harvests the strat.
     */
    event StratHarvest(address indexed harvester, uint256 wantHarvested, uint256 tvl);
    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);

    constructor(
        address _want,
        uint256 _poolId,
        address _chef,
        address _unirouter,
        address _keeper,
        address _strategist,
        address _ethaFeeRecipient,
        address[] memory _outputToNativeRoute,
        address[] memory _nativeToLp0Route,
        address[] memory _nativeToLp1Route
    ) CompoundStratManager(_keeper, _strategist, _unirouter, _ethaFeeRecipient) {
        want = _want;
        poolId = _poolId;
        chef = _chef;

        require(_outputToNativeRoute.length >= 2);
        output = _outputToNativeRoute[0];
        native = _outputToNativeRoute[_outputToNativeRoute.length - 1];
        outputToNativeRoute = _outputToNativeRoute;

        // setup lp routing
        lpToken0 = IUniswapV2ERC20(want).token0();
        require(_nativeToLp0Route[0] == native);
        require(_nativeToLp0Route[_nativeToLp0Route.length - 1] == lpToken0);
        nativeToLp0Route = _nativeToLp0Route;

        lpToken1 = IUniswapV2ERC20(want).token1();
        require(_nativeToLp1Route[0] == native);
        require(_nativeToLp1Route[_nativeToLp1Route.length - 1] == lpToken1);
        nativeToLp1Route = _nativeToLp1Route;

        _giveAllowances();
    }

    // puts the funds to work
    function deposit() public override whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal > 0) {
            IMiniChefV2(chef).deposit(poolId, wantBal, address(this));
            emit Deposit(balanceOf());
        }
    }

    function withdraw(uint256 _amount) external override whenNotPaused onlyVault {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal < _amount) {
            IMiniChefV2(chef).withdraw(poolId, _amount - wantBal, address(this));
            wantBal = IERC20(want).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        IERC20(want).safeTransfer(vault, wantBal);
        emit Withdraw(balanceOf());
    }

    // compounds earnings and charges performance fee
    function _harvest(address callFeeRecipient) internal override whenNotPaused {
        IMiniChefV2(chef).harvest(poolId, address(this));
        uint256 outputBal = IERC20(output).balanceOf(address(this));
        uint256 nativeBal = IERC20(native).balanceOf(address(this));
        if (outputBal > 0 || nativeBal > 0) {
            chargeFees(callFeeRecipient);
            addLiquidity();
            uint256 wantHarvested = balanceOfWant();
            deposit();
            lastHarvest = block.timestamp;
            emit StratHarvest(msg.sender, wantHarvested, balanceOf());
        }
    }

    // performance fees
    function chargeFees(address callFeeRecipient) internal {
        // swap all output to native
        uint256 toNative = IERC20(output).balanceOf(address(this));
        if (toNative > 0) {
            IUniswapV2Router(unirouter).swapExactTokensForTokens(
                toNative,
                0,
                outputToNativeRoute,
                address(this),
                block.timestamp
            );
        } else return;

        uint256 nativeFeeBal = (IERC20(native).balanceOf(address(this)) * profitFee) / MAX_FEE;

        _deductFees(native, callFeeRecipient, nativeFeeBal);
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 nativeHalf = IERC20(native).balanceOf(address(this)) / (2);

        if (lpToken0 != native) {
            IUniswapV2Router(unirouter).swapExactTokensForTokens(
                nativeHalf,
                0,
                nativeToLp0Route,
                address(this),
                block.timestamp
            );
        }

        if (lpToken1 != native) {
            IUniswapV2Router(unirouter).swapExactTokensForTokens(
                nativeHalf,
                0,
                nativeToLp1Route,
                address(this),
                block.timestamp
            );
        }

        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
        IUniswapV2Router(unirouter).addLiquidity(lpToken0, lpToken1, lp0Bal, lp1Bal, 1, 1, address(this), block.timestamp);
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() public view override returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view override returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view override returns (uint256) {
        (uint256 _amount, ) = IMiniChefV2(chef).userInfo(poolId, address(this));
        return _amount;
    }

    /// @notice calculate the total underlying 'want' held by the strat
    /// @dev This is equivalent to the amount of want in the strat and the amount invested in staking contract
    function balanceOfStrategy() public view override returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external override onlyVault {
        // Claim rewards and compound
        _harvest(ethaFeeRecipient);

        // Withdraw all funds
        IMiniChefV2(chef).withdraw(poolId, balanceOfPool(), address(this));

        uint256 wantBal = IERC20(want).balanceOf(address(this));
        IERC20(want).safeTransfer(vault, wantBal);
    }

    // returns rewards unharvested
    function rewardsAvailable() public view returns (uint256) {
        return IMiniChefV2(chef).pendingSushi(poolId, address(this));
    }

    // native reward amount for calling harvest
    function callReward() public view returns (uint256) {
        if (callFee == 0) return 0;

        uint256 pendingReward;
        address rewarder = IMiniChefV2(chef).rewarder(poolId);
        if (rewarder != address(0)) {
            pendingReward = ISushiRewarder(rewarder).pendingToken(poolId, address(this));
        }

        uint256 outputBal = rewardsAvailable();
        uint256 nativeOut;
        if (outputBal > 0) {
            try IUniswapV2Router(unirouter).getAmountsOut(outputBal, outputToNativeRoute) returns (
                uint256[] memory amountOut
            ) {
                nativeOut = amountOut[amountOut.length - 1];
            } catch {}
        }

        uint256 totNative = nativeOut + pendingReward;

        return (totNative * profitFee * callFee) / (MAX_FEE * MAX_FEE);
    }

    // Returns the maximum amount of asset tokens that can be deposited
    function getMaximumDepositLimit() public pure returns (uint256) {
        return type(uint256).max;
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public override onlyManager {
        pause();
        IMiniChefV2(chef).emergencyWithdraw(poolId, address(this));
    }

    function pause() public onlyManager {
        _pause();

        _removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function _giveAllowances() internal {
        IERC20(want).safeApprove(chef, type(uint256).max);
        IERC20(native).safeApprove(unirouter, type(uint256).max);
        IERC20(output).safeApprove(unirouter, type(uint256).max);

        if (output != lpToken0 && native != lpToken0) IERC20(lpToken0).safeApprove(unirouter, type(uint256).max);
        if (output != lpToken1 && native != lpToken1) IERC20(lpToken1).safeApprove(unirouter, type(uint256).max);
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(chef, 0);
        IERC20(native).safeApprove(unirouter, 0);
        IERC20(output).safeApprove(unirouter, 0);

        if (output != lpToken0 && native != lpToken0) IERC20(lpToken0).safeApprove(unirouter, 0);
        if (output != lpToken1 && native != lpToken1) IERC20(lpToken1).safeApprove(unirouter, 0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../../../interfaces/IStrat.sol";
import "../../../../interfaces/IVault.sol";
import {ISavingsContractV2, IBoostedDualVaultWithLockup} from "../../../../interfaces/IMStable.sol";
import "../../../../interfaces/IUniswapV2Router.sol";
import "../../../../utils/Timelock.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MStableStrat {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ==== STATE ===== //

    IVault public vault;

    IERC20 public constant WMATIC = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    IERC20 public constant MTA = IERC20(0xF501dd45a1198C2E1b5aEF5314A68B9006D842E0);

    IUniswapV2Router constant ROUTER = IUniswapV2Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

    // mStable Save contract
    ISavingsContractV2 public savings = ISavingsContractV2(0x5290Ad3d83476CA6A2b178Cd9727eE1EF72432af);

    // mStable Boosted Vault
    IBoostedDualVaultWithLockup public boostedVault =
        IBoostedDualVaultWithLockup(0x32aBa856Dc5fFd5A56Bcd182b13380e5C855aa29);

    // deposit token (mUSD)
    IERC20 public underlying;

    Timelock public timelock;

    // ==== MODIFIERS ===== //

    modifier onlyVault() {
        require(msg.sender == address(vault));
        _;
    }

    // ==== INITIALIZATION ===== //

    constructor(IVault vault_, IERC20 _underlying) {
        vault = vault_;
        underlying = _underlying;

        timelock = new Timelock(msg.sender, 7 days);

        // Approve vault for withdrawals and claims
        underlying.safeApprove(address(vault), type(uint256).max);
        WMATIC.safeApprove(address(vault), type(uint256).max);
        MTA.safeApprove(address(vault), type(uint256).max);
        MTA.safeApprove(address(ROUTER), type(uint256).max);

        // Approve for investing imUSD to vault
        IERC20(address(savings)).safeApprove(address(boostedVault), type(uint256).max);
    }

    // ==== GETTERS ===== //

    /**
		@dev total amount of imUSD tokens staked on mstable's vault
	*/
    function calcTotalValue() external view returns (uint256) {
        return boostedVault.balanceOf(address(this));
    }

    /**
		@dev amount of claimable MATIC
	*/
    function totalYield() external view returns (uint256) {
        (uint256 mtaEarned, uint256 maticEarned) = boostedVault.earned(address(this));

        uint256 mtaToMatic;

        if (mtaEarned > 0) {
            address[] memory path = new address[](2);
            path[0] = address(MTA);
            path[1] = address(WMATIC);

            mtaToMatic = ROUTER.getAmountsOut(mtaEarned, path)[path.length - 1];
        }

        return maticEarned.add(mtaToMatic);
    }

    // ==== MAIN FUNCTIONS ===== //

    /**
		@notice Invest LP Tokens into mStable staking contract
		@dev can only be called by the vault contract
		@dev credits = balance
	*/
    function invest() external onlyVault {
        uint256 balance = underlying.balanceOf(address(this));
        require(balance > 0);

        boostedVault.stake(address(this), balance);
    }

    /**
		@notice Redeem LP Tokens from mStable staking contract
		@dev can only be called by the vault contract
		@param amount amount of LP Tokens to withdraw
	*/
    function divest(uint256 amount) public onlyVault {
        boostedVault.withdraw(amount);

        uint256 received = savings.balanceOf(address(this));

        underlying.safeTransfer(address(vault), received);
    }

    /**
		@notice Redeem underlying assets from curve Aave pool and Matic rewards from gauge
		@dev can only be called by the vault contract
		@dev only used when harvesting
	*/
    function claim() external onlyVault returns (uint256 claimed) {
        boostedVault.claimReward();

        uint256 claimedMTA = MTA.balanceOf(address(this));

        // If received MTA, swap to WMATIC
        if (claimedMTA > 0) {
            address[] memory path = new address[](2);
            path[0] = address(MTA);
            path[1] = address(WMATIC);

            ROUTER.swapExactTokensForTokens(claimedMTA, 1, path, address(this), block.timestamp + 1)[path.length - 1];
        }

        claimed = WMATIC.balanceOf(address(this));
        WMATIC.safeTransfer(address(vault), claimed);
    }

    // ==== RESCUE ===== //

    // IMPORTANT: This function can only be called by the timelock to recover any token amount including deposited cTokens
    // However, the owner of the timelock must first submit their request and wait 7 days before confirming.
    // This gives depositors a good window to withdraw before a potentially malicious escape
    // The intent is for the owner to be able to rescue funds in the case they become stuck after launch
    // However, users should not trust the owner and watch the timelock contract least once a week on Etherscan
    // In the future, the timelock contract will be destroyed and the functionality will be removed after the code gets audited
    function rescue(
        address _token,
        address _to,
        uint256 _amount
    ) external {
        require(msg.sender == address(timelock));
        IERC20(_token).transfer(_to, _amount);
    }

    // Any tokens (other than the lpToken) that are sent here by mistake are recoverable by the vault owner
    function sweep(address _token) external {
        address owner = vault.owner();
        require(msg.sender == owner);
        require(_token != address(underlying));
        IERC20(_token).transfer(owner, IERC20(_token).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISavingsContractV1 {
	function depositInterest(uint256 _amount) external;

	function depositSavings(uint256 _amount)
		external
		returns (uint256 creditsIssued);

	function redeem(uint256 _amount) external returns (uint256 massetReturned);

	function exchangeRate() external view returns (uint256);

	function creditBalances(address) external view returns (uint256);
}

interface ISavingsContractV2 {
	// DEPRECATED but still backwards compatible
	function redeem(uint256 _amount) external returns (uint256 massetReturned);

	function creditBalances(address) external view returns (uint256); // V1 & V2 (use balanceOf)

	function balanceOf(address) external view returns (uint256);

	function earned(address) external view returns (uint256, uint256);

	// --------------------------------------------

	function depositInterest(uint256 _amount) external; // V1 & V2

	function depositSavings(uint256 _amount)
		external
		returns (uint256 creditsIssued); // V1 & V2

	function depositSavings(uint256 _amount, address _beneficiary)
		external
		returns (uint256 creditsIssued); // V2

	function redeemCredits(uint256 _amount)
		external
		returns (uint256 underlyingReturned); // V2

	function redeemUnderlying(uint256 _amount)
		external
		returns (uint256 creditsBurned); // V2

	function exchangeRate() external view returns (uint256); // V1 & V2

	function balanceOfUnderlying(address _user) external view returns (uint256); // V2

	function underlyingToCredits(uint256 _underlying)
		external
		view
		returns (uint256 credits); // V2

	function creditsToUnderlying(uint256 _credits)
		external
		view
		returns (uint256); // V2

	function underlying() external view returns (IERC20 underlyingMasset); // V2
}

interface IBoostedDualVaultWithLockup {
	/**
	 * @dev Stakes a given amount of the StakingToken for the sender
	 * @param _amount Units of StakingToken
	 */
	function stake(uint256 _amount) external;

	/**
	 * @dev Stakes a given amount of the StakingToken for a given beneficiary
	 * @param _beneficiary Staked tokens are credited to this address
	 * @param _amount      Units of StakingToken
	 */
	function stake(address _beneficiary, uint256 _amount) external;

	/**
	 * @dev Withdraws stake from pool and claims any unlocked rewards.
	 * Note, this function is costly - the args for _claimRewards
	 * should be determined off chain and then passed to other fn
	 */
	function exit() external;

	/**
	 * @dev Withdraws stake from pool and claims any unlocked rewards.
	 * @param _first    Index of the first array element to claim
	 * @param _last     Index of the last array element to claim
	 */
	function exit(uint256 _first, uint256 _last) external;

	/**
	 * @dev Withdraws given stake amount from the pool
	 * @param _amount Units of the staked token to withdraw
	 */
	function withdraw(uint256 _amount) external;

	/**
	 * @dev Claims only the tokens that have been immediately unlocked, not including
	 * those that are in the lockers.
	 */
	function claimReward() external;

	/**
	 * @dev Claims all unlocked rewards for sender.
	 * Note, this function is costly - the args for _claimRewards
	 * should be determined off chain and then passed to other fn
	 */
	function claimRewards() external;

	/**
	 * @dev Claims all unlocked rewards for sender. Both immediately unlocked
	 * rewards and also locked rewards past their time lock.
	 * @param _first    Index of the first array element to claim
	 * @param _last     Index of the last array element to claim
	 */
	function claimRewards(uint256 _first, uint256 _last) external;

	/**
	 * @dev Pokes a given account to reset the boost
	 */
	function pokeBoost(address _account) external;

	/**
	 * @dev Gets the last applicable timestamp for this reward period
	 */
	function lastTimeRewardApplicable() external view returns (uint256);

	/**
	 * @dev Calculates the amount of unclaimed rewards per token since last update,
	 * and sums with stored to give the new cumulative reward per token
	 * @return 'Reward' per staked token
	 */
	function rewardPerToken() external view returns (uint256, uint256);

	/**
	 * @dev Returned the units of IMMEDIATELY claimable rewards a user has to receive. Note - this
	 * does NOT include the majority of rewards which will be locked up.
	 * @param _account User address
	 * @return Total reward amount earned
	 */
	function earned(address _account) external view returns (uint256, uint256);

	/**
	 * @dev Calculates all unclaimed reward data, finding both immediately unlocked rewards
	 * and those that have passed their time lock.
	 * @param _account User address
	 * @return amount Total units of unclaimed rewards
	 * @return first Index of the first userReward that has unlocked
	 * @return last Index of the last userReward that has unlocked
	 */
	function unclaimedRewards(address _account)
		external
		view
		returns (
			uint256 amount,
			uint256 first,
			uint256 last,
			uint256 platformAmount
		);

	function balanceOf(address) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../../../interfaces/IStrat.sol";
import "../../../../interfaces/IVault.sol";
import "../../../../interfaces/IStakingRewards.sol";
import "../../../../utils/Timelock.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract QuickStrat {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ==== STATE ===== //

    IVault public vault;

    IERC20 public constant QUICK = IERC20(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);

    // Quikswap LP Staking Rewards Contract
    IStakingRewards public staking;

    // Quickswap LP
    IERC20 public underlying;

    Timelock public timelock;

    // ==== MODIFIERS ===== //

    modifier onlyVault() {
        require(msg.sender == address(vault));
        _;
    }

    // ==== INITIALIZATION ===== //

    constructor(
        IVault vault_,
        IStakingRewards _staking,
        IERC20 _underlying
    ) {
        vault = vault_;
        staking = _staking;
        underlying = _underlying;

        timelock = new Timelock(msg.sender, 3 days);

        // Infite Approvals
        underlying.safeApprove(address(staking), type(uint256).max);
        underlying.safeApprove(address(vault), type(uint256).max);
        QUICK.safeApprove(address(vault), type(uint256).max);
    }

    // ==== GETTERS ===== //

    /**
		@dev total value of LP tokens staked on Curve's Gauge
	*/
    function calcTotalValue() external view returns (uint256) {
        return staking.balanceOf(address(this));
    }

    /**
		@dev amount of claimable QUICK
	*/
    function totalYield() external view returns (uint256) {
        return staking.earned(address(this));
    }

    // ==== MAIN FUNCTIONS ===== //

    /**
		@notice Invest LP Tokens into Quickswap staking contract
		@dev can only be called by the vault contract
	*/
    function invest() external onlyVault {
        uint256 balance = underlying.balanceOf(address(this));
        require(balance > 0);

        staking.stake(balance);
    }

    /**
		@notice Redeem LP Tokens from Quickswap staking contract
		@dev can only be called by the vault contract
		@param amount amount of LP Tokens to withdraw
	*/
    function divest(uint256 amount) public onlyVault {
        staking.withdraw(amount);

        underlying.safeTransfer(address(vault), amount);
    }

    /**
		@notice Claim QUICK rewards from staking contract
		@dev can only be called by the vault contract
		@dev only used when harvesting
	*/
    function claim() external onlyVault returns (uint256 claimed) {
        staking.getReward();
        claimed = QUICK.balanceOf(address(this));
        QUICK.safeTransfer(address(vault), claimed);
    }

    // ==== RESCUE ===== //

    // IMPORTANT: This function can only be called by the timelock to recover any token amount including deposited cTokens
    // However, the owner of the timelock must first submit their request and wait 7 days before confirming.
    // This gives depositors a good window to withdraw before a potentially malicious escape
    // The intent is for the owner to be able to rescue funds in the case they become stuck after launch
    // However, users should not trust the owner and watch the timelock contract least once a week on Etherscan
    // In the future, the timelock contract will be destroyed and the functionality will be removed after the code gets audited
    function rescue(
        address _token,
        address _to,
        uint256 _amount
    ) external {
        require(msg.sender == address(timelock));
        IERC20(_token).transfer(_to, _amount);
    }

    // Any tokens (other than the lpToken) that are sent here by mistake are recoverable by the vault owner
    function sweep(address _token) external {
        address owner = vault.owner();
        require(msg.sender == owner);
        require(_token != address(underlying));
        IERC20(_token).transfer(owner, IERC20(_token).balanceOf(address(this)));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IStakingRewards.sol";
import "../interfaces/IDragonLair.sol";
import "../libs/UniversalERC20.sol";
import "./Helpers.sol";

/**
 * @title Interact with staking contracts
 */
contract StakingResolver is Helpers {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    event Staked(address indexed erc20, uint256 tokenAmt);
    event Unstaked(address indexed erc20, uint256 tokenAmt);
    event Claimed(address indexed erc20, uint256 tokenAmt);

    address public constant ETHA = 0x59E9261255644c411AfDd00bD89162d09D862e38;
    address public constant QUICK = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
    address public constant DQUICK = 0xf28164A485B0B2C90639E47b0f377b4a438a16B1;

    function stake(
        address stakingContract,
        address erc20,
        uint256 amount,
        uint256 getId
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId) : amount;

        IERC20(erc20).universalApprove(stakingContract, realAmt);
        IStakingRewards(stakingContract).stake(realAmt);

        emit Staked(erc20, realAmt);
    }

    function unstake(
        address stakingContract,
        address erc20,
        uint256 amount,
        uint256 getId
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId) : amount;

        IStakingRewards(stakingContract).withdraw(realAmt);

        emit Unstaked(erc20, realAmt);
    }

    function claim(address stakingContract, uint256 setId) external payable {
        address rewardsToken = IStakingRewards(stakingContract).rewardsToken();
        uint256 initialBal = IERC20(rewardsToken).balanceOf(address(this));

        IStakingRewards(stakingContract).getReward();

        uint256 claimed = IERC20(rewardsToken).balanceOf(address(this)).sub(initialBal);

        if (claimed > 0) {
            // If claiming dQUICK, unstake from Dragon Lair
            if (rewardsToken == DQUICK) {
                uint256 initialQuick = IERC20(QUICK).balanceOf(address(this));
                IDragonLair(DQUICK).leave(claimed);
                claimed = IERC20(QUICK).balanceOf(address(this)).sub(initialQuick);
                rewardsToken = QUICK;
            }
            emit Claimed(rewardsToken, claimed);
        }

        // set destTokens received
        if (setId > 0) {
            setUint(setId, claimed);
        }
    }
}

contract StakingLogic is StakingResolver {
    string public constant name = "StakingLogic";
    uint8 public constant version = 1;

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libs/UniversalERC20.sol";
import "./Helpers.sol";
import "../interfaces/IVotingEscrow.sol";
import "./DSMath.sol";

contract VoteEscrowResolver is DSMath {
    using UniversalERC20 for IERC20;

    event VoteEscrowDeposit(address indexed veETHA, uint256 amountToken, uint256 amtDays);
    event VoteEscrowWithdraw(address indexed veETHA, uint256 amountToken);
    event VoteEscrowIncrease(address indexed veETHA, uint256 amountToken, uint256 amtDays);

    // event VaultWithdraw(address indexed vault, address indexed erc20, uint256 tokenAmt);
    // event VaultClaim(address indexed vault, address indexed erc20, uint256 tokenAmt);

    /**
     * @dev Deposit the ETHA tokens to the VoteEscrow contract
     * @param veEthaContract address of VoteEscrow contract.
     * @param tokenAmt amount of tokens to deposit
     * @param noOfDays amount of days to lock.
     * @param getId read value of tokenAmt from memory contract
     */
    function deposit(
        address veEthaContract,
        uint256 tokenAmt,
        uint256 noOfDays,
        uint256 getId
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId) : tokenAmt;

        require(realAmt > 0, "!AMOUNT");

        IVotingEscrow veEtha = IVotingEscrow(veEthaContract);
        IERC20(veEtha.lockedToken()).universalApprove(veEthaContract, realAmt);

        if (veEtha.delegates(msg.sender) == address(0)) veEtha.delegate(msg.sender);
        veEtha.create_lock(realAmt, noOfDays);

        emit VoteEscrowDeposit(veEthaContract, realAmt, noOfDays);
    }

    /**
     * @dev Withdraw tokens from VoteEscrow contract.
     * @param veEthaContract address of veEthaContract.
     */
    function withdraw_unlocked(address veEthaContract) external payable {
        require(veEthaContract != address(0), "ZERO_ADDRESS");

        IVotingEscrow veEtha = IVotingEscrow(veEthaContract);
        uint prevBal = IERC20(veEtha.lockedToken()).balanceOf(address(this));

        veEtha.withdraw();

        uint withdrawn = IERC20(veEtha.lockedToken()).balanceOf(address(this)) - prevBal;

        emit VoteEscrowWithdraw(veEthaContract, withdrawn);
    }

    /**
     * @dev Emergency withdraw tokens from VoteEscrow contract.
     * @param veEthaContract address of veEthaContract.
     * @notice This function will collect a fee penalty for withdrawing before time.
     */
    function emergency_withdraw(address veEthaContract) external payable {
        require(veEthaContract != address(0), "ZERO_ADDRESS");

        IVotingEscrow veEtha = IVotingEscrow(veEthaContract);
        uint prevBal = IERC20(veEtha.lockedToken()).balanceOf(address(this));

        veEtha.emergencyWithdraw();

        uint withdrawn = IERC20(veEtha.lockedToken()).balanceOf(address(this)) - prevBal;

        emit VoteEscrowWithdraw(veEthaContract, withdrawn);
    }

    /**
     * @dev Increase the amount of ETHA tokens in the VoteEscrow contract
     * @param veEthaContract address of VoteEscrow contract.
     * @param tokenAmt amount of tokens to increment.
     * @param getId read value of tokenAmt from memory contract.
     */
    function increase_amount(
        address veEthaContract,
        uint256 tokenAmt,
        uint256 getId
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId) : tokenAmt;

        require(realAmt > 0, "!AMOUNT");

        IVotingEscrow veEtha = IVotingEscrow(veEthaContract);
        IERC20(veEtha.lockedToken()).universalApprove(veEthaContract, realAmt);

        veEtha.increase_amount(realAmt);

        emit VoteEscrowIncrease(veEthaContract, realAmt, 0);
    }

    /**
     * @dev Increase the time to be lock the ETHA tokens in the VoteEscrow contract.
     * @param veEthaContract address of VoteEscrowETHA token.
     * @param noOfDays amount of days to increase the lock.
     */
    function increase_time(address veEthaContract, uint256 noOfDays) external payable {
        IVotingEscrow(veEthaContract).increase_unlock_time(noOfDays);

        emit VoteEscrowIncrease(veEthaContract, 0, noOfDays);
    }
}

contract VoteEscrowLogic is VoteEscrowResolver {
    string public constant name = "VoteEscrowLogic";
    uint8 public constant version = 1;

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Helpers.sol";

contract DSMath is Helpers {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "math-not-safe");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return c;
    }

    uint256 constant WAD = 10**18;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libs/UniversalERC20.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IDistribution.sol";
import "./Helpers.sol";

contract VaultResolver is Helpers {
    using UniversalERC20 for IERC20;

    event VaultDeposit(address indexed user, address indexed vault, address indexed erc20, uint256 tokenAmt);
    event VaultWithdraw(address indexed user, address indexed vault, address indexed erc20, uint256 tokenAmt);
    event VaultClaim(address indexed user, address indexed vault, address indexed erc20, uint256 tokenAmt);

    /**
     * @dev Deposit tokens to ETHA Vault
     * @param _vault address of vault
     * @param tokenAmt amount of tokens to deposit
     * @param getId read value of tokenAmt from memory contract
     */
    function deposit(
        IVault _vault,
        uint256 tokenAmt,
        uint256 getId,
        uint setId
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId) : tokenAmt;

        require(realAmt > 0, "!AMOUNT");

        IERC20 erc20 = IERC20(address(_vault.underlying()));
        erc20.universalApprove(address(_vault), realAmt);

        _vault.deposit(realAmt);

        if (setId > 0) {
            setUint(setId, realAmt);
        }

        // Send vault tokens to user
        IERC20(address(_vault)).universalTransfer(_msgSender(), realAmt);

        emit VaultDeposit(_msgSender(), address(_vault), address(erc20), realAmt);
    }

    /**
     * @dev Withdraw tokens from ETHA Vault
     * @param _vault address of vault
     * @param tokenAmt amount of vault tokens to withdraw
     * @param getId read value of tokenAmt from memory contract
     */
    function withdraw(
        IVault _vault,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId) : tokenAmt;

        require(_vault.balanceOf(address(this)) >= realAmt, "!BALANCE");

        address underlying = address(_vault.underlying());

        // Calculate underlying amount received after fees
        uint256 depositBalBefore = IERC20(underlying).balanceOf(address(this));
        _vault.withdraw(realAmt);
        uint256 depositBalAfter = IERC20(underlying).balanceOf(address(this)) - depositBalBefore;

        emit VaultWithdraw(_msgSender(), address(_vault), underlying, depositBalAfter);

        // set tokens received
        if (setId > 0) {
            setUint(setId, depositBalAfter);
        }
    }

    /**
     * @dev claim rewards from ETHA Vault
     * @param _vault address of vault
     * @param setId store value of rewards received to memory contract
     */
    function claim(IVault _vault, uint256 setId) external {
        uint256 claimed = _vault.claim();

        // set rewards received
        if (setId > 0) {
            setUint(setId, claimed);
        }

        if (claimed > 0) {
            emit VaultClaim(_msgSender(), address(_vault), address(_vault.target()), claimed);
        }
    }
}

contract VaultLogic is VaultResolver {
    string public constant name = "VaultLogic";
    uint8 public constant version = 1;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libs/UniversalERC20.sol";
import "../interfaces/ICurvePool.sol";
import "../interfaces/IAdapter.sol";
import "./Helpers.sol";

contract CurveResolver is Helpers {
    using UniversalERC20 for IERC20;

    // EVENTS
    event LogSwap(address indexed user, address indexed src, address indexed dest, uint256 amount);
    event LogLiquidityAdd(
        address indexed user,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event LogLiquidityRemove(
        address indexed user,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );

    function toInt128(uint256 num) internal pure returns (int128) {
        return int128(int256(num));
    }

    function _paySwapFees(IERC20 erc20, uint256 amt) internal returns (uint256 feesPaid) {
        (uint256 fee, uint256 maxFee, address feeRecipient) = getSwapFee();

        // When swap fee is 0 or sender has partner role
        if (fee == 0) return 0;

        require(feeRecipient != address(0), "ZERO ADDRESS");

        feesPaid = (amt * fee) / maxFee;
        erc20.universalTransfer(feeRecipient, feesPaid);
    }

    /**
     * @notice swap tokens in curve pool
     * @param getId read value from memory contract
     * @param setId set dest tokens received to memory contract
     */
    function swap(
        ICurvePool pool,
        address src,
        address dest,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId,
        uint256 divider
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId) / divider : tokenAmt;

        uint256 i;
        uint256 j;

        for (uint256 x = 1; x <= 3; x++) {
            if (pool.underlying_coins(x - 1) == src) i = x;
            if (pool.underlying_coins(x - 1) == dest) j = x;
        }

        require(i != 0 && j != 0);

        IERC20(src).universalApprove(address(pool), realAmt);

        uint256 received = pool.exchange_underlying(toInt128(i - 1), toInt128(j - 1), realAmt, 0);

        uint256 feesPaid = _paySwapFees(IERC20(dest), received);

        received = received - feesPaid;

        // set j tokens received
        if (setId > 0) {
            setUint(setId, received);
        }

        emit LogSwap(_msgSender(), pool.underlying_coins(i - 1), pool.underlying_coins(j - 1), realAmt);
    }

    /**
     * @notice add liquidity to Curve Pool
     * @param tokenId id of the token to remove liq. Should be 0, 1 or 2
     * @param getId read value from memory contract
     * @param setId set LP tokens received to memory contract
     */
    function addLiquidity(
        address lpToken,
        uint256 tokenAmt,
        uint256 tokenId, // 0, 1 or 2
        uint256 getId,
        uint256 setId,
        uint256 divider
    ) external payable {
        address token;

        ICurvePool pool = ICurvePool(IAdapter(getAdapterAddress()).curvePools(lpToken));

        try pool.underlying_coins(tokenId) returns (address _token) {
            token = _token;
        } catch {
            revert("!TOKENID");
        }

        uint256 realAmt = getId > 0 ? getUint(getId) / divider : tokenAmt;

        uint256[3] memory tokenAmts;
        tokenAmts[tokenId] = realAmt;

        IERC20(token).universalApprove(address(pool), realAmt);

        uint256 liquidity = pool.add_liquidity(tokenAmts, 0, true);

        // set LP tokens received
        if (setId > 0) {
            setUint(setId, liquidity);
        }

        emit LogLiquidityAdd(_msgSender(), token, address(0), realAmt, 0);
    }

    /**
     * @notice add liquidity to Curve Pool
     * @param tokenId id of the token to remove liq. Should be 0, 1 or 2
     * @param getId read value from memory contract
     * @param setId set LP tokens received to memory contract
     */
    function addLiquidity2(
        address lpToken,
        uint256 tokenAmt,
        uint256 tokenId, // 0 or 1
        uint256 getId,
        uint256 setId,
        uint256 divider
    ) external payable {
        address token;

        ICurvePool pool = ICurvePool(IAdapter(getAdapterAddress()).curvePools(lpToken));

        try pool.coins(tokenId) returns (address _token) {
            token = _token;
        } catch {
            revert("!TOKENID");
        }

        uint256 realAmt = getId > 0 ? getUint(getId) / divider : tokenAmt;

        uint256[2] memory tokenAmts;
        tokenAmts[tokenId] = realAmt;

        IERC20(token).universalApprove(address(pool), realAmt);

        uint256 liquidity = pool.add_liquidity(tokenAmts, 0, false);

        // set LP tokens received
        if (setId > 0) {
            setUint(setId, liquidity);
        }

        emit LogLiquidityAdd(_msgSender(), token, address(0), realAmt, 0);
    }

    /**
     * @notice remove liquidity from Curve Pool
     * @param tokenAmt amount of pool Tokens to burn
     * @param tokenId id of the token to remove liq. Should be 0, 1 or 2
     * @param getId read value of amount from memory contract
     * @param setId set value of tokens received in memory contract
     */
    function removeLiquidity(
        address lpToken,
        uint256 tokenAmt,
        uint256 tokenId,
        uint256 getId,
        uint256 setId,
        uint256 divider
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId) / divider : tokenAmt;

        require(realAmt > 0, "ZERO AMOUNT");
        require(tokenId <= 2, "INVALID TOKEN");

        address pool = IAdapter(getAdapterAddress()).curvePools(lpToken);

        IERC20(lpToken).universalApprove(pool, realAmt);

        uint256 amountReceived = ICurvePool(pool).remove_liquidity_one_coin(realAmt, int128(int256(tokenId)), 1, true);

        // set tokens received
        if (setId > 0) {
            setUint(setId, amountReceived);
        }

        emit LogLiquidityRemove(_msgSender(), ICurvePool(pool).underlying_coins(tokenId), address(0), amountReceived, 0);
    }

    /**
     * @notice remove liquidity from Curve Pool
     * @param tokenAmt amount of pool Tokens to burn
     * @param tokenId id of the token to remove liq. Should be 0 or 1
     * @param getId read value of amount from memory contract
     * @param setId set value of tokens received in memory contract
     */
    function removeLiquidity2(
        address lpToken,
        uint256 tokenAmt,
        uint256 tokenId,
        uint256 getId,
        uint256 setId,
        uint256 divider
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId) / divider : tokenAmt;

        require(realAmt > 0, "ZERO AMOUNT");
        require(tokenId <= 1, "INVALID TOKEN");

        address pool = IAdapter(getAdapterAddress()).curvePools(lpToken);

        IERC20(lpToken).universalApprove(pool, realAmt);

        uint256 amountReceived = ICurvePool(pool).remove_liquidity_one_coin(realAmt, tokenId, 1, false);

        // set tokens received
        if (setId > 0) {
            setUint(setId, amountReceived);
        }

        emit LogLiquidityRemove(_msgSender(), ICurvePool(pool).coins(tokenId), address(0), amountReceived, 0);
    }
}

contract CurveLogic is CurveResolver {
    string public constant name = "CurveLogic";
    uint8 public constant version = 1;

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurvePool {
    event TokenExchangeUnderlying(
        address indexed buyer,
        int128 sold_id,
        uint256 tokens_sold,
        int128 bought_id,
        uint256 tokens_bought
    );

    // solium-disable-next-line mixedcase
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external returns (uint256);

    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external returns (uint256);

    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external returns (uint256);

    function remove_liquidity_imbalance(
        uint256[3] calldata amounts,
        uint256 max_burn_amount,
        bool use_underlying
    ) external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 i,
        uint256 min_amount,
        bool use_underlying
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount,
        bool use_eth
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool is_deposit) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function underlying_coins(uint256) external view returns (address);

    function lp_token() external view returns (address);

    function token() external view returns (address);

    function coins(uint arg0) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAdapter {
    function curvePools(address lpToken) external view returns (address);

    function getAToken(address token) external view returns (address);

    function getCrToken(address token) external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/ILendingPool.sol";
import "../interfaces/IAaveAddressProvider.sol";
import "../interfaces/IAToken.sol";
import "../interfaces/IAdapter.sol";
import "../interfaces/IProtocolDistribution.sol";
import "../libs/UniversalERC20.sol";
import "../interfaces/ICToken.sol";
import "./Helpers.sol";

contract AaveHelpers is Helpers {
    using UniversalERC20 for IERC20;

    /**
     * @dev get Aave Lending Pool Address V2
     */
    function getLendingPoolAddress() public view returns (address lendingPoolAddress) {
        IAaveAddressProvider adr = IAaveAddressProvider(0xd05e3E715d945B59290df0ae8eF85c1BdB684744);
        return adr.getLendingPool();
    }

    function getReferralCode() public pure returns (uint16) {
        return uint16(0);
    }
}

contract AaveResolver is AaveHelpers {
    using UniversalERC20 for IERC20;

    event LogMint(address indexed erc20, uint256 tokenAmt);
    event LogRedeem(address indexed erc20, uint256 tokenAmt);
    event LogBorrow(address indexed erc20, uint256 tokenAmt);
    event LogPayback(address indexed erc20, uint256 tokenAmt);

    /**
     * @dev Deposit MATIC/ERC20 and mint Aave V2 Tokens
     * @param erc20 underlying asset to deposit
     * @param tokenAmt amount of underlying asset to deposit
     * @param getId read value of tokenAmt from memory contract
     * @param setId set value of aTokens minted in memory contract
     */
    function mintAToken(
        address erc20,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId,
        uint256 divider
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId) / divider : tokenAmt;

        address aToken = IAdapter(getAdapterAddress()).getAToken(erc20);
        uint256 initialBal = IERC20(aToken).universalBalanceOf(address(this));

        require(aToken != address(0), "INVALID ASSET");

        require(realAmt > 0 && realAmt <= IERC20(erc20).universalBalanceOf(address(this)), "INVALID AMOUNT");

        address realToken = erc20;

        if (erc20 == getAddressETH()) {
            wmatic.deposit{value: realAmt}();
            realToken = address(wmatic);
        }

        ILendingPool _lendingPool = ILendingPool(getLendingPoolAddress());

        IERC20(realToken).universalApprove(address(_lendingPool), realAmt);

        _lendingPool.deposit(realToken, realAmt, address(this), getReferralCode());

        // set aTokens received
        if (setId > 0) {
            setUint(setId, IERC20(aToken).universalBalanceOf(address(this)) - initialBal);
        }

        emit LogMint(erc20, realAmt);
    }

    /**
     * @dev Redeem MATIC/ERC20 and burn Aave V2 Tokens
     * @param erc20 underlying asset to redeem
     * @param tokenAmt Amount of underling tokens
     * @param getId read value of tokenAmt from memory contract
     * @param setId set value of tokens redeemed in memory contract
     */
    function redeemAToken(
        address erc20,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId,
        uint256 divider
    ) external {
        IAToken aToken = IAToken(IAdapter(getAdapterAddress()).getAToken(erc20));
        require(address(aToken) != address(0), "INVALID ASSET");

        uint256 realAmt = getId > 0 ? getUint(getId) / divider : tokenAmt;

        require(realAmt > 0, "ZERO AMOUNT");
        require(realAmt <= aToken.balanceOf(address(this)), "INVALID AMOUNT");

        ILendingPool _lendingPool = ILendingPool(getLendingPoolAddress());
        _lendingPool.withdraw(erc20, realAmt, address(this));

        // set amount of tokens received minus fees
        if (setId > 0) {
            setUint(setId, realAmt);
        }

        emit LogRedeem(erc20, realAmt);
    }

    /**
     * @dev Redeem MATIC/ERC20 and burn Aave Tokens
     * @param erc20 Address of the underlying token to borrow
     * @param tokenAmt Amount of underlying tokens to borrow
     * @param getId read value of tokenAmt from memory contract
     * @param setId set value of tokens borrowed in memory contract
     */
    function borrow(
        address erc20,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId,
        uint256 divider
    ) external payable {
        address realToken = erc20 == getAddressETH() ? address(wmatic) : erc20;

        uint256 realAmt = getId > 0 ? getUint(getId) / divider : tokenAmt;

        ILendingPool(getLendingPoolAddress()).borrow(realToken, realAmt, 2, getReferralCode(), address(this));

        // set amount of tokens received
        if (setId > 0) {
            setUint(setId, realAmt);
        }

        emit LogBorrow(erc20, realAmt);
    }

    /**
     * @dev Redeem MATIC/ERC20 and burn Aave Tokens
     * @param erc20 Address of the underlying token to repay
     * @param tokenAmt Amount of underlying tokens to repay
     * @param getId read value of tokenAmt from memory contract
     * @param setId set value of tokens repayed in memory contract
     */
    function repay(
        address erc20,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId,
        uint256 divider
    ) external payable {
        address realToken = erc20;

        uint256 realAmt = getId > 0 ? getUint(getId) / divider : tokenAmt;

        if (erc20 == getAddressETH()) {
            wmatic.deposit{value: realAmt}();
            realToken = address(wmatic);
        }

        IERC20(realToken).universalApprove(getLendingPoolAddress(), realAmt);

        ILendingPool(getLendingPoolAddress()).repay(realToken, realAmt, 2, address(this));

        // set amount of tokens received
        if (setId > 0) {
            setUint(setId, realAmt);
        }

        emit LogPayback(erc20, realAmt);
    }
}

contract AaveLogic is AaveResolver {
    string public constant name = "AaveLogic";
    uint8 public constant version = 1;

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILendingPool {
	function deposit(
		address asset,
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode
	) external;

	function withdraw(
		address asset,
		uint256 amount,
		address to
	) external returns (uint256);

	function borrow(
		address asset,
		uint256 amount,
		uint256 interestRateMode,
		uint16 referralCode,
		address onBehalfOf
	) external;

	function repay(
		address asset,
		uint256 amount,
		uint256 rateMode,
		address onBehalfOf
	) external returns (uint256);

	function getUserAccountData(address user)
		external
		view
		returns (
			uint256 totalCollateralETH,
			uint256 totalDebtETH,
			uint256 availableBorrowsETH,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAaveAddressProvider {
	function getLendingPool() external view returns (address);

	function getLendingPoolCore() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAToken {
	function redeem(uint256 amount) external;

	function principalBalanceOf(address user) external view returns (uint256);

	function balanceOf(address user) external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function transferFrom(
		address,
		address,
		uint256
	) external returns (bool);

	function transfer(address, uint256) external returns (bool);

	function transferAllowed(address from, uint256 amount)
		external
		returns (bool);

	function decimals() external view returns (uint8);

	function symbol() external view returns (string memory);

	function underlyingAssetAddress() external pure returns (address);

	function UNDERLYING_ASSET_ADDRESS() external pure returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/ILendingPool.sol";
import "../interfaces/IMemory.sol";
import "../interfaces/ICToken.sol";
import "../interfaces/IAaveAddressProvider.sol";
import "../interfaces/IComptroller.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IProtocolDataProvider {
	function getReserveData(address asset)
		external
		view
		returns (
			uint256 availableLiquidity,
			uint256 totalStableDebt,
			uint256 totalVariableDebt,
			uint256 liquidityRate,
			uint256 variableBorrowRate
		);

	function getReserveConfigurationData(address asset)
		external
		view
		returns (
			uint256 decimals,
			uint256 ltv,
			uint256 liquidationThreshold,
			uint256 liquidationBonus,
			uint256 reserveFactor,
			bool usageAsCollateralEnabled,
			bool borrowingEnabled,
			bool stableBorrowRateEnabled,
			bool isActive,
			bool isFrozen
		);
}

contract ProtocolsData is Ownable {
	using SafeMath for uint256;

	IMemory public memoryContract;

	address internal constant MATIC =
		0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
	address internal constant WMATIC =
		0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

	IProtocolDataProvider aaveDataProviderV2 =
		IProtocolDataProvider(0x7551b5D2763519d4e37e8B81929D336De671d46d);

	IComptroller creamComptroller =
		IComptroller(0x20CA53E2395FA571798623F1cFBD11Fe2C114c24);

	struct Data {
		address token;
		uint256 liquidity;
		uint256 supplyRate;
		uint256 borrowRate;
		uint256 utilizationRate;
		uint256 ltv;
		uint256 threshold;
	}

	constructor(IMemory _memoryContract) {
		memoryContract = _memoryContract;
	}

	function setMemoryContract(IMemory _memory) external onlyOwner {
		memoryContract = _memory;
	}

	function getCreamData(address token)
		public
		view
		returns (Data memory data)
	{
		ICToken cToken = ICToken(memoryContract.getCrToken(token));

		if (address(cToken) != address(0)) {
			uint256 supplyRate = cToken.supplyRatePerBlock();
			uint256 borrowRate = cToken.borrowRatePerBlock();
			uint256 liquidity = cToken.getCash();
			uint256 reserves = cToken.totalReserves();
			uint256 totalBorrows = cToken.totalBorrows();

			(, uint256 collateralFactor, ) = creamComptroller.markets(
				address(cToken)
			);

			uint256 utilizationRate = totalBorrows.mul(1 ether).div(
				liquidity.add(totalBorrows).sub(reserves)
			);

			return
				Data(
					token,
					liquidity,
					supplyRate,
					borrowRate,
					utilizationRate,
					collateralFactor,
					0
				);
		}
	}

	function getAaveData(address token) public view returns (Data memory data) {
		address realToken = token == MATIC ? WMATIC : token;
		(
			,
			uint256 ltv,
			uint256 liquidationThreshold,
			,
			,
			,
			,
			,
			bool isActive,

		) = aaveDataProviderV2.getReserveConfigurationData(realToken);

		if (isActive) {
			(
				uint256 liquidity,
				,
				uint256 totalBorrows,
				uint256 supplyRate,
				uint256 borrowRate
			) = aaveDataProviderV2.getReserveData(realToken);

			uint256 utilizationRate = totalBorrows.mul(1 ether).div(
				liquidity.add(totalBorrows)
			);

			return
				Data(
					realToken,
					liquidity,
					supplyRate,
					borrowRate,
					utilizationRate,
					ltv,
					liquidationThreshold
				);
		}
	}

	function getProtocolsData(address token)
		external
		view
		returns (Data memory aave, Data memory cream)
	{
		aave = getAaveData(token);
		cream = getCreamData(token);
	}

	function getProtocolsDataAll(address[] memory tokens)
		external
		view
		returns (Data[] memory aave, Data[] memory cream)
	{
		aave = new Data[](tokens.length);
		cream = new Data[](tokens.length);

		for (uint256 i = 0; i < tokens.length; i++) {
			aave[i] = getAaveData(tokens[i]);
			cream[i] = getCreamData(tokens[i]);
		}
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IComptroller {
	function enterMarkets(address[] calldata cTokens)
		external
		returns (uint256[] memory);

	function exitMarket(address cTokenAddress) external returns (uint256);

	function getAssetsIn(address account)
		external
		view
		returns (address[] memory);

	function getAccountLiquidity(address account)
		external
		view
		returns (
			uint256,
			uint256,
			uint256
		);

	function markets(address cTokenAddress)
		external
		view
		returns (
			bool,
			uint256,
			uint8
		);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IUniswapV2Router.sol";
import "../../interfaces/IUniswapV2Exchange.sol";
import "../../interfaces/IWETH.sol";
import "../../interfaces/IRegistry.sol";
import "../../interfaces/IWallet.sol";
import "../../interfaces/IFeeManager.sol";
import "../../interfaces/IMemory.sol";
import "../../libs/UniversalERC20.sol";
import "./AvaxHelpers.sol";

contract ParaswapResolverAvax is AvaxHelpers {
    using UniversalERC20 for IERC20;

    // EVENTS
    event LogSwap(address indexed src, address indexed dest, uint256 amount);

    /**
     * @dev internal function to charge swap fees
     */
    function _payFees(IERC20 erc20, uint256 amt) internal returns (uint256 feesPaid) {
        (uint256 fee, uint256 maxFee, address feeRecipient) = getSwapFee();

        // When fee recipient is the smart wallet fee
        if (feeRecipient == address(this)) return 0;

        if (fee > 0) {
            require(feeRecipient != address(0), "ZERO ADDRESS");

            feesPaid = (amt * fee) / maxFee;

            erc20.universalTransfer(feeRecipient, feesPaid);
        }
    }

    /**
     * @dev Swap tokens in Paraswap dex
     * @param fromToken address of the source token
     * @param destToken address of the target token
     * @param transferProxy address of proxy contract that handles token transfers
     * @param tokenAmt amount of fromTokens to swap
     * @param swapTarget paraswap swapper contract
     * @param swapData encoded function call
     * @param setId set value of tokens swapped in memory contract
     */
    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        address transferProxy,
        uint256 tokenAmt,
        address swapTarget,
        bytes memory swapData,
        uint256 setId
    ) external payable {
        require(tokenAmt > 0, "ZERO AMOUNT");
        require(fromToken != destToken, "SAME ASSETS");

        uint bal = destToken.balanceOf(address(this));

        // Approve only whats needed
        fromToken.universalApprove(transferProxy, tokenAmt);

        // Execute tx on paraswap Swapper
        (bool success, bytes memory returnData) = swapTarget.call(swapData);

        // Fetch error message if tx not successful
        if (!success) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (returnData.length < 68) revert();
            assembly {
                returnData := add(returnData, 0x04)
            }
            revert(abi.decode(returnData, (string)));
        }

        uint received = destToken.balanceOf(address(this)) - bal;

        assert(received > 0);

        // Pay Fees
        uint256 feesPaid = _payFees(destToken, received);

        // set destTokens received
        if (setId > 0) {
            setUint(setId, received - feesPaid);
        }

        emit LogSwap(address(fromToken), address(destToken), tokenAmt);
    }
}

contract ParaswapLogicAvax is ParaswapResolverAvax {
    string public constant name = "ParaswapLogic";
    uint8 public constant version = 1;

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libs/UniversalERC20.sol";

interface IUniswapV2Exchange {
	function swap(
		uint256 amount0Out,
		uint256 amount1Out,
		address to,
		bytes calldata data
	) external;
}

library UniswapV2ExchangeLib {
	using SafeMath for uint256;
	using UniversalERC20 for IERC20;

	function getReturn(
		IUniswapV2Exchange exchange,
		IERC20 fromToken,
		IERC20 destToken,
		uint256 amountIn
	) internal view returns (uint256) {
		uint256 reserveIn = fromToken.universalBalanceOf(address(exchange));
		uint256 reserveOut = destToken.universalBalanceOf(address(exchange));

		uint256 amountInWithFee = amountIn.mul(997);
		uint256 numerator = amountInWithFee.mul(reserveOut);
		uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
		return (denominator == 0) ? 0 : numerator.div(denominator);
	}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IMemory.sol";
import "../../interfaces/IRegistry.sol";
import "../../interfaces/IWallet.sol";

contract AvaxHelpers {
    /**
     * @dev Return Registry Address
     */
    function getRegistryAddr() public view returns (address) {
        return IWallet(address(this)).registry();
    }

    /**
     * @dev Return Memory Variable Address
     */
    function getMemoryAddr() public view returns (address) {
        return IRegistry(getRegistryAddr()).memoryAddr();
    }

    /**
     * @dev Return Vault fee and recipient
     */
    function getSwapFee()
        public
        view
        returns (
            uint256 fee,
            uint256 maxFee,
            address recipient
        )
    {
        IRegistry registry = IRegistry(getRegistryAddr());

        fee = registry.getFee();
        recipient = registry.feeRecipient();
        maxFee = 10000;
    }

    /**
     * @dev Get Uint value from Memory Contract.
     */
    function getUint(uint256 id) internal view returns (uint256) {
        return IMemory(getMemoryAddr()).getUint(id);
    }

    /**
     * @dev Set Uint value in Memory Contract.
     */
    function setUint(uint256 id, uint256 val) internal {
        IMemory(getMemoryAddr()).setUint(id, val);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IUniswapV2Router.sol";
import "../../interfaces/IUniswapV2Exchange.sol";
import "../../interfaces/IWETH.sol";
import "../../libs/UniversalERC20.sol";
import "./AvaxHelpers.sol";

contract TraderJoeResolver is AvaxHelpers {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;
    using UniversalERC20 for IWETH;

    IUniswapV2Router internal constant router = IUniswapV2Router(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);

    IWETH internal constant wavax = IWETH(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

    // EVENTS
    event LogSwap(address indexed src, address indexed dest, uint256 amount);
    event LogLiquidityAdd(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB);
    event LogLiquidityRemove(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB);

    function _payFees(IERC20 erc20, uint256 amt) internal returns (uint256 feesPaid) {
        (uint fee, uint maxFee, address feeRecipient) = getSwapFee();

        // When fee recipient is the smart wallet fee
        if (feeRecipient == msg.sender) return 0;

        if (fee > 0) {
            require(feeRecipient != address(0), "ZERO ADDRESS");

            feesPaid = (amt * fee) / maxFee;

            erc20.universalTransfer(feeRecipient, feesPaid);
        }
    }

    /**
     * @dev Swap tokens in Quickswap dex
     * @param path swap route fromToken => destToken
     * @param tokenAmt amount of fromTokens to swap
     * @param getId read value of tokenAmt from memory contract
     * @param setId set value of tokens swapped in memory contract
     */
    function swap(
        address[] memory path,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId,
        uint256 divider
    ) external payable {
        require(path.length >= 2, "INVALID PATH");

        uint256 realAmt = getId > 0 ? getUint(getId).div(divider) : tokenAmt;
        require(realAmt > 0, "ZERO AMOUNT");

        IERC20 fromToken = IERC20(path[0]);
        IERC20 destToken = IERC20(path[path.length - 1]);

        if (fromToken.isETH()) {
            wavax.deposit{value: realAmt}();
            wavax.universalApprove(address(router), realAmt);
            path[0] = address(wavax);
        } else fromToken.universalApprove(address(router), realAmt);

        if (destToken.isETH()) path[path.length - 1] = address(wavax);

        require(path[0] != path[path.length - 1], "SAME ASSETS");

        uint256 received = router.swapExactTokensForTokens(realAmt, 1, path, address(this), block.timestamp + 1)[
            path.length - 1
        ];

        uint256 feesPaid = _payFees(destToken, received);

        received = received - feesPaid;

        if (destToken.isETH()) {
            wavax.withdraw(received);
        }

        // set destTokens received
        if (setId > 0) {
            setUint(setId, received);
        }

        emit LogSwap(address(fromToken), address(destToken), realAmt);
    }

    /**
     * @dev Add liquidity to Quickswap pools
     * @param amtA amount of A tokens to add
     * @param amtB amount of B tokens to add
     * @param getId read value of tokenAmt from memory contract position 1
     * @param getId2 read value of tokenAmt from memory contract position 2
     * @param setId set value of LP tokens received in memory contract
     */
    function addLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 amtA,
        uint256 amtB,
        uint256 getId,
        uint256 getId2,
        uint256 setId,
        uint256 divider
    ) external payable {
        uint256 realAmtA = getId > 0 ? getUint(getId).div(divider) : amtA;
        uint256 realAmtB = getId2 > 0 ? getUint(getId2).div(divider) : amtB;

        require(realAmtA > 0 && realAmtB > 0, "INVALID AMOUNTS");

        IERC20 tokenAReal = tokenA.isETH() ? wavax : tokenA;
        IERC20 tokenBReal = tokenB.isETH() ? wavax : tokenB;

        // Wrap Ether
        if (tokenA.isETH()) {
            wavax.deposit{value: realAmtA}();
        }
        if (tokenB.isETH()) {
            wavax.deposit{value: realAmtB}();
        }

        // Approve Router
        tokenAReal.universalApprove(address(router), realAmtA);
        tokenBReal.universalApprove(address(router), realAmtB);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(
            address(tokenAReal),
            address(tokenBReal),
            realAmtA,
            realAmtB,
            1,
            1,
            address(this),
            block.timestamp + 1
        );

        // set aTokens received
        if (setId > 0) {
            setUint(setId, liquidity);
        }

        emit LogLiquidityAdd(address(tokenAReal), address(tokenBReal), amountA, amountB);
    }

    /**
     * @dev Remove liquidity from Quickswap pool
     * @param tokenA address of token A from the pool
     * @param tokenA address of token B from the pool
     * @param poolToken address of the LP token
     * @param amtPoolTokens amount of LP tokens to burn
     * @param getId read value from memory contract
     * @param setId set value of amount tokenB received in memory contract position 1
     * @param setId2 set value of amount tokenB received in memory contract position 2
     */
    function removeLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        IERC20 poolToken,
        uint256 amtPoolTokens,
        uint256 getId,
        uint256 setId,
        uint256 setId2,
        uint256 divider
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId).div(divider) : amtPoolTokens;

        IERC20 tokenAReal = tokenA.isETH() ? wavax : tokenA;
        IERC20 tokenBReal = tokenB.isETH() ? wavax : tokenB;

        // Approve Router
        IERC20(address(poolToken)).universalApprove(address(router), realAmt);

        (uint256 amountA, uint256 amountB) = router.removeLiquidity(
            address(tokenAReal),
            address(tokenBReal),
            realAmt,
            1,
            1,
            address(this),
            block.timestamp + 1
        );

        // set tokenA received
        if (setId > 0) {
            setUint(setId, amountA);
        }

        // set tokenA received
        if (setId2 > 0) {
            setUint(setId2, amountB);
        }

        emit LogLiquidityRemove(address(tokenAReal), address(tokenBReal), amountA, amountB);
    }
}

contract TraderJoeLogic is TraderJoeResolver {
    string public constant name = "TraderJoeLogic";
    uint8 public constant version = 1;

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../../interfaces/IUniswapV2Router.sol";
import "../../../../interfaces/IGaugeFactory.sol";
import "../../../../interfaces/ICurveGauge.sol";
import "../../../../interfaces/ICurveSwap.sol";
import "../../../../interfaces/IWETH.sol";
import "../../CompoundStrat.sol";

contract StrategyCurveLP is CompoundStrat {
    using SafeERC20 for IERC20;

    // Tokens used
    address public depositToken;

    // Third party contracts
    address public gaugeFactory;
    address public rewardsGauge;
    address public pool;
    uint public poolSize;
    uint public depositIndex;
    bool public useUnderlying;
    bool public useMetapool;

    // Routes
    address[] public crvToNativeRoute;
    address[] public nativeToDepositRoute;

    struct Reward {
        address token;
        address[] toNativeRoute;
        uint minAmount; // minimum amount to be swapped to native
    }

    Reward[] public rewards;

    // if no CRV rewards yet, can enable later with custom router
    bool public crvEnabled = true;
    address public crvRouter;

    // if depositToken should be sent as unwrapped native
    bool public depositNative;

    event StratHarvest(address indexed harvester, uint256 wantHarvested, uint256 tvl);
    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);
    event ChargedFees(uint256 callFees, uint256 ethaFees, uint256 strategistFees);

    constructor(
        address _want,
        address _gaugeFactory,
        address _gauge,
        address _pool,
        uint _poolSize,
        uint _depositIndex,
        bool _useUnderlying,
        bool _useMetapool,
        address[] memory _crvToNativeRoute,
        address[] memory _nativeToDepositRoute,
        address[4] memory _stratParams // avoid stack too deep
    ) CompoundStratManager(_stratParams[0], _stratParams[1], _stratParams[2], _stratParams[3]) {
        want = _want;
        gaugeFactory = _gaugeFactory;
        rewardsGauge = _gauge;
        pool = _pool;
        poolSize = _poolSize;
        depositIndex = _depositIndex;
        useUnderlying = _useUnderlying;
        useMetapool = _useMetapool;

        output = _crvToNativeRoute[0];
        native = _crvToNativeRoute[_crvToNativeRoute.length - 1];
        crvToNativeRoute = _crvToNativeRoute;
        crvRouter = unirouter;

        require(_nativeToDepositRoute[0] == native, "_nativeToDepositRoute[0] != native");
        depositToken = _nativeToDepositRoute[_nativeToDepositRoute.length - 1];
        nativeToDepositRoute = _nativeToDepositRoute;

        if (gaugeFactory != address(0)) {
            harvestOnDeposit = true;
        }

        _giveAllowances();
    }

    // puts the funds to work
    function deposit() public override whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal > 0) {
            ICurveGauge(rewardsGauge).deposit(wantBal);
            emit Deposit(balanceOf());
        }
    }

    function withdraw(uint256 _amount) external override whenNotPaused onlyVault {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal < _amount) {
            ICurveGauge(rewardsGauge).withdraw(_amount - wantBal);
            wantBal = IERC20(want).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        IERC20(want).safeTransfer(vault, wantBal);
        emit Withdraw(balanceOf());
    }

    // compounds earnings and charges performance fee
    function _harvest(address callFeeRecipient) internal override {
        if (gaugeFactory != address(0)) {
            IGaugeFactory(gaugeFactory).mint(rewardsGauge);
        }
        ICurveGauge(rewardsGauge).claim_rewards(address(this));
        swapRewardsToNative();
        uint256 nativeBal = IERC20(native).balanceOf(address(this));
        if (nativeBal > 0) {
            chargeFees(callFeeRecipient);
            addLiquidity();
            uint256 wantHarvested = balanceOfWant();
            deposit();
            lastHarvest = block.timestamp;
            emit StratHarvest(msg.sender, wantHarvested, balanceOf());
        }
    }

    function swapRewardsToNative() internal {
        uint256 crvBal = IERC20(output).balanceOf(address(this));
        if (crvEnabled && crvBal > 0) {
            IUniswapV2Router(crvRouter).swapExactTokensForTokens(
                crvBal,
                0,
                crvToNativeRoute,
                address(this),
                block.timestamp
            );
        }
        // extras
        for (uint i; i < rewards.length; i++) {
            uint bal = IERC20(rewards[i].token).balanceOf(address(this));
            if (bal >= rewards[i].minAmount) {
                IUniswapV2Router(unirouter).swapExactTokensForTokens(
                    bal,
                    0,
                    rewards[i].toNativeRoute,
                    address(this),
                    block.timestamp
                );
            }
        }
    }

    // performance fees
    function chargeFees(address callFeeRecipient) internal {
        uint256 nativeFeeBal = (IERC20(native).balanceOf(address(this)) * profitFee) / MAX_FEE;
        _deductFees(native, callFeeRecipient, nativeFeeBal);
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 depositBal;
        uint256 depositNativeAmount;
        uint256 nativeBal = IERC20(native).balanceOf(address(this));
        if (depositToken != native) {
            IUniswapV2Router(unirouter).swapExactTokensForTokens(
                nativeBal,
                0,
                nativeToDepositRoute,
                address(this),
                block.timestamp
            );
            depositBal = IERC20(depositToken).balanceOf(address(this));
        } else {
            depositBal = nativeBal;
            if (depositNative) {
                depositNativeAmount = nativeBal;
                IWETH(native).withdraw(depositNativeAmount);
            }
        }

        if (poolSize == 2) {
            uint256[2] memory amounts;
            amounts[depositIndex] = depositBal;
            if (useUnderlying) ICurveSwap(pool).add_liquidity(amounts, 0, true);
            else ICurveSwap(pool).add_liquidity{value: depositNativeAmount}(amounts, 0);
        } else if (poolSize == 3) {
            uint256[3] memory amounts;
            amounts[depositIndex] = depositBal;
            if (useUnderlying) ICurveSwap(pool).add_liquidity(amounts, 0, true);
            else if (useMetapool) ICurveSwap(pool).add_liquidity(want, amounts, 0);
            else ICurveSwap(pool).add_liquidity(amounts, 0);
        } else if (poolSize == 4) {
            uint256[4] memory amounts;
            amounts[depositIndex] = depositBal;
            if (useMetapool) ICurveSwap(pool).add_liquidity(want, amounts, 0);
            else ICurveSwap(pool).add_liquidity(amounts, 0);
        } else if (poolSize == 5) {
            uint256[5] memory amounts;
            amounts[depositIndex] = depositBal;
            ICurveSwap(pool).add_liquidity(amounts, 0);
        }
    }

    function addRewardToken(address[] memory _rewardToNativeRoute, uint _minAmount) external onlyOwner {
        address token = _rewardToNativeRoute[0];
        require(token != want, "!want");
        require(token != rewardsGauge, "!native");

        rewards.push(Reward(token, _rewardToNativeRoute, _minAmount));
        IERC20(token).safeApprove(unirouter, 0);
        IERC20(token).safeApprove(unirouter, type(uint).max);
    }

    function resetRewardTokens() external onlyManager {
        delete rewards;
    }

    // calculate the total underlying 'want' held by the strat.
    function balanceOfStrategy() public view override returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // calculate the total underlying 'want' held by the strat.
    function balanceOf() public view override returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view override returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view override returns (uint256) {
        return ICurveGauge(rewardsGauge).balanceOf(address(this));
    }

    function crvToNative() external view returns (address[] memory) {
        return crvToNativeRoute;
    }

    function nativeToDeposit() external view returns (address[] memory) {
        return nativeToDepositRoute;
    }

    function rewardToNative() external view returns (address[] memory) {
        return rewards[0].toNativeRoute;
    }

    function rewardToNative(uint i) external view returns (address[] memory) {
        return rewards[i].toNativeRoute;
    }

    function rewardsLength() external view returns (uint) {
        return rewards.length;
    }

    function setCrvEnabled(bool _enabled) external onlyManager {
        crvEnabled = _enabled;
    }

    function setCrvRoute(address _router, address[] memory _crvToNative) external onlyManager {
        require(_crvToNative[0] == output, "!crv");
        require(_crvToNative[_crvToNative.length - 1] == native, "!native");

        _removeAllowances();
        crvToNativeRoute = _crvToNative;
        crvRouter = _router;
        _giveAllowances();
    }

    function setDepositNative(bool _depositNative) external onlyOwner {
        depositNative = _depositNative;
    }

    // returns rewards unharvested
    function rewardsAvailable() public view returns (uint256) {
        return ICurveGauge(rewardsGauge).claimable_reward(address(this), output);
    }

    // returns rewards unharvested
    function rewardsAvailableByToken(address _rewardToken) public view returns (uint256) {
        return ICurveGauge(rewardsGauge).claimable_reward(address(this), _rewardToken);
    }

    // native reward amount for calling harvest
    function callReward() public view returns (uint256) {
        if (callFee == 0) return 0;

        uint256 outputBal = rewardsAvailable();
        uint256[] memory amountOut = IUniswapV2Router(unirouter).getAmountsOut(outputBal, crvToNativeRoute);
        uint256 nativeOut = amountOut[amountOut.length - 1];

        return (nativeOut * profitFee * callFee) / (MAX_FEE * MAX_FEE);
    }

    // extra reward amount for calling harvest
    function callRewardByToken(uint i) public view returns (uint256) {
        if (callFee == 0) return 0;

        uint256 outputBal = rewardsAvailableByToken(rewards[i].token);
        uint256[] memory amountOut = IUniswapV2Router(unirouter).getAmountsOut(outputBal, rewards[i].toNativeRoute);
        uint256 rewardAmt = amountOut[amountOut.length - 1];

        return (rewardAmt * profitFee * callFee) / (MAX_FEE * MAX_FEE);
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external override onlyVault {
        // Claim rewards and compound
        _harvest(ethaFeeRecipient);

        // Withdraw all funds from gauge
        ICurveGauge(rewardsGauge).withdraw(balanceOfPool());

        uint256 wantBal = IERC20(want).balanceOf(address(this));
        IERC20(want).safeTransfer(vault, wantBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public override onlyManager {
        pause();
        ICurveGauge(rewardsGauge).withdraw(balanceOfPool());
    }

    function pause() public onlyManager {
        _pause();

        _removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function _giveAllowances() internal {
        IERC20(want).safeApprove(rewardsGauge, type(uint).max);
        IERC20(native).safeApprove(unirouter, type(uint).max);
        IERC20(output).safeApprove(crvRouter, type(uint).max);
        IERC20(depositToken).safeApprove(pool, type(uint).max);
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(rewardsGauge, 0);
        IERC20(native).safeApprove(unirouter, 0);
        IERC20(output).safeApprove(crvRouter, 0);
        IERC20(depositToken).safeApprove(pool, 0);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGaugeFactory {
    function mint(address _gauge) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 0xe381C25de995d62b453aF8B931aAc84fcCaa7A62

interface ICurveGauge {
    function lp_token() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function reward_tokens(uint256) external view returns (address);

    function claim_rewards() external;

    function claim_rewards(address _addrr) external;

    function deposit(uint256 value) external;

    function withdraw(uint256 value) external;

    function claimable_reward(address user, address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICurveSwap is IERC20 {
    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function calc_withdraw_one_coin(uint256 tokenAmount, int128 i) external view returns (uint256);

    function coins(uint256 arg0) external view returns (address);

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external;

    function add_liquidity(
        address _pool,
        uint256[2] memory amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(
        uint256[3] memory amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external;

    function add_liquidity(
        address _pool,
        uint256[3] memory amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external payable;

    function add_liquidity(
        address _pool,
        uint256[4] memory amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(uint256[5] memory amounts, uint256 min_mint_amount) external payable;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../../../interfaces/IStrat.sol";
import "../../../../interfaces/IVault.sol";
import "../../../../interfaces/ICurveGauge.sol";
import "../../../../interfaces/IGaugeFactory.sol";
import "../../../../interfaces/IUniswapV2Router.sol";
import "../../../../utils/Timelock.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CurveStratV2 is IStrat {
    using SafeERC20 for IERC20;

    // ==== STATE ===== //

    IVault public vault;
    IERC20 public underlying;
    Timelock public timelock;
    ICurveGauge public gauge = ICurveGauge(0x20759F567BB3EcDB55c817c9a1d13076aB215EdC);

    IERC20 public constant WMATIC = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    IERC20 public constant CRV = IERC20(0x172370d5Cd63279eFa6d502DAB29171933a610AF);
    IGaugeFactory public constant GAUGE_FACTORY = IGaugeFactory(0xabC000d88f23Bb45525E447528DBF656A9D55bf5);

    struct Reward {
        address token;
        address router;
        address[] toNativeRoute;
        uint minAmount; // minimum amount to be swapped to native
    }

    Reward[] public rewards;

    // Rewards swap details
    address public override router;
    address[] public outputToTargetRoute;

    // ==== MODIFIERS ===== //

    modifier onlyVault() {
        require(msg.sender == address(vault));
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == address(timelock), "!timelock");
        _;
    }

    // ==== INITIALIZATION ===== //

    constructor(
        IVault vault_,
        Reward memory reward_,
        ICurveGauge gauge_,
        address router_,
        address[] memory outputToTargetRoute_
    ) {
        require(outputToTargetRoute_[0] == address(WMATIC));
        require(outputToTargetRoute_[outputToTargetRoute_.length - 1] == address(vault_.target()));
        vault = vault_;
        gauge = gauge_;
        underlying = IERC20(gauge.lp_token());
        timelock = new Timelock(msg.sender, 3 days);
        rewards.push(reward_);
        router = router_;
        outputToTargetRoute = outputToTargetRoute_;

        // Infite Approvals
        underlying.safeApprove(address(gauge), type(uint256).max);
        IERC20(reward_.token).safeApprove(reward_.router, type(uint256).max);
    }

    // ==== GETTERS ===== //

    /**
		@dev total value of LP tokens staked on Curve's Gauge
	*/
    function calcTotalValue() external view override returns (uint256) {
        return gauge.balanceOf(address(this));
    }

    /**
		@dev amount of claimable CRV
	*/
    function totalYield() external view override returns (uint256) {
        return gauge.claimable_reward(address(this), address(CRV));
    }

    /**
		@dev amount of claimable for extra rewards
	*/
    function totalYieldByIndex(uint i) external view returns (uint256) {
        return gauge.claimable_reward(address(this), rewards[i].token);
    }

    /**
		@dev swap route for reward token
	*/
    function getRewardDetails(uint i) external view returns (address[] memory path, address routerAddress) {
        path = rewards[i].toNativeRoute;
        routerAddress = rewards[i].router;
    }

    function rewardsLength() external view returns (uint) {
        return rewards.length;
    }

    function outputToTarget() external view override returns (address[] memory) {
        return outputToTargetRoute;
    }

    // ==== MAIN FUNCTIONS ===== //

    /**
		@notice Invest LP Tokens into Curve's gauge
		@dev can only be called by the vault contract
	*/
    function invest() external override onlyVault {
        uint256 balance = underlying.balanceOf(address(this));
        require(balance > 0);

        gauge.deposit(balance);
    }

    /**
		@notice Redeem underlying assets from curve Aave pool
		@dev can only be called by the vault contract
		@dev wont always return the exact desired amount
		@param amount amount of underlying asset to withdraw
	*/
    function divest(uint256 amount) public override onlyVault {
        gauge.withdraw(amount);

        underlying.safeTransfer(address(vault), amount);
    }

    /**
		@notice Redeem underlying assets from curve Aave pool and Matic rewards from gauge
		@dev can only be called by the vault contract
		@dev only used when harvesting
	*/
    function claim() external override onlyVault returns (uint256 claimed) {
        GAUGE_FACTORY.mint(address(gauge));
        gauge.claim_rewards(address(this));

        for (uint i; i < rewards.length; i++) {
            uint bal = IERC20(rewards[i].token).balanceOf(address(this));
            if (bal >= rewards[i].minAmount) {
                IUniswapV2Router(rewards[i].router).swapExactTokensForTokens(
                    bal,
                    0,
                    rewards[i].toNativeRoute,
                    address(this),
                    block.timestamp
                );
            }
        }

        claimed = WMATIC.balanceOf(address(this));
        if (claimed > 0) WMATIC.safeTransfer(address(vault), claimed);
    }

    // IMPORTANT: This function can only be called by the timelock to recover any token amount including deposited cTokens
    // However, the owner of the timelock must first submit their request and wait timelock.delay() seconds before confirming.
    // This gives depositors a good window to withdraw before a potentially malicious escape
    // The intent is for the owner to be able to rescue funds in the case they become stuck after launch
    // However, users should not trust the owner and watch the timelock contract least once a week on Etherscan
    // In the future, the timelock contract will be destroyed and the functionality will be removed after the code gets audited
    function rescue(
        address _token,
        address _to,
        uint256 _amount
    ) external override onlyTimelock {
        IERC20(_token).transfer(_to, _amount);
    }

    /**
		@notice Add new reward token in curve gauge
		@dev can only be called by the vault owner
	*/
    function addRewardToken(
        address[] memory _rewardToNativeRoute,
        uint _minAmount,
        address _router
    ) external {
        address owner = vault.owner();
        require(msg.sender == owner, "!owner");

        address token = _rewardToNativeRoute[0];
        require(token != address(underlying), "!underlying");
        require(token != address(WMATIC), "!wmatic");

        rewards.push(Reward(token, _router, _rewardToNativeRoute, _minAmount));
        IERC20(token).safeApprove(address(_router), 0);
        IERC20(token).safeApprove(address(_router), type(uint).max);
    }

    /**
		@notice Reset reward tokens from curve gauge
		@dev can only be called by the vault owner
	*/
    function resetRewardTokens() external {
        address owner = vault.owner();
        require(msg.sender == owner, "!owner");
        delete rewards;
    }

    function setSwapRoute(address[] memory outputToTargetRoute_) external override onlyTimelock {
        require(outputToTargetRoute_[0] == address(WMATIC));
        require(outputToTargetRoute_[outputToTargetRoute_.length - 1] == address(vault.target()));

        outputToTargetRoute = outputToTargetRoute_;
    }

    function setRouter(address router_) external override onlyTimelock {
        router = router_;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../../../interfaces/IStrat.sol";
import "../../../../interfaces/IVault.sol";
import "../../../../interfaces/ICurveGauge.sol";
import "../../../../interfaces/IUniswapV2Router.sol";
import "../../../../utils/Timelock.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CurveStrat {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ==== STATE ===== //

    IVault public vault;

    IERC20 public constant WMATIC = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    IERC20 public constant CRV = IERC20(0x172370d5Cd63279eFa6d502DAB29171933a610AF);

    ICurveGauge public gauge = ICurveGauge(0x19793B454D3AfC7b454F206Ffe95aDE26cA6912c);

    IUniswapV2Router constant ROUTER = IUniswapV2Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

    IERC20 public underlying;

    Timelock public timelock;

    // ==== MODIFIERS ===== //

    modifier onlyVault() {
        require(msg.sender == address(vault));
        _;
    }

    // ==== INITIALIZATION ===== //

    constructor(IVault vault_) {
        vault = vault_;
        underlying = IERC20(gauge.lp_token());
        timelock = new Timelock(msg.sender, 3 days);

        // Infite Approvals
        underlying.safeApprove(address(gauge), type(uint256).max);
        underlying.safeApprove(address(vault), type(uint256).max);
        CRV.safeApprove(address(ROUTER), type(uint256).max);
        WMATIC.safeApprove(address(vault), type(uint256).max);
    }

    // ==== GETTERS ===== //

    /**
		@dev total value of LP tokens staked on Curve's Gauge
	*/
    function calcTotalValue() external view returns (uint256) {
        return gauge.balanceOf(address(this));
    }

    /**
		@dev amount of claimable WMATIC
	*/
    function totalYield() external view returns (uint256) {
        return gauge.claimable_reward(address(this), address(WMATIC));
    }

    /**
		@dev amount of claimable CRV
	*/
    function totalYield2() external view returns (uint256) {
        return gauge.claimable_reward(address(this), address(CRV));
    }

    // ==== MAIN FUNCTIONS ===== //

    /**
		@notice Invest LP Tokens into Curve's Gauge
		@dev can only be called by the vault contract
	*/
    function invest() external onlyVault {
        uint256 balance = underlying.balanceOf(address(this));
        require(balance > 0);

        gauge.deposit(balance);
    }

    /**
		@notice Redeem underlying assets from curve Aave pool
		@dev can only be called by the vault contract
		@dev wont always return the exact desired amount
		@param amount amount of underlying asset to withdraw
	*/
    function divest(uint256 amount) public onlyVault {
        gauge.withdraw(amount);

        underlying.safeTransfer(address(vault), amount);
    }

    /**
		@notice Redeem underlying assets from curve Aave pool and Matic rewards from gauge
		@dev can only be called by the vault contract
		@dev only used when harvesting
	*/
    function claim() external onlyVault returns (uint256 claimed) {
        gauge.claim_rewards();

        uint256 claimedCurve = CRV.balanceOf(address(this));

        // If received CRV, swap to WMATIC
        if (claimedCurve > 0) {
            address[] memory path = new address[](2);
            path[0] = address(CRV);
            path[1] = address(WMATIC);

            ROUTER.swapExactTokensForTokens(claimedCurve, 1, path, address(this), block.timestamp + 1)[path.length - 1];
        }

        claimed = WMATIC.balanceOf(address(this));
        WMATIC.safeTransfer(address(vault), claimed);
    }

    // ==== RESCUE ===== //

    // IMPORTANT: This function can only be called by the timelock to recover any token amount including deposited cTokens
    // However, the owner of the timelock must first submit their request and wait 7 days before confirming.
    // This gives depositors a good window to withdraw before a potentially malicious escape
    // The intent is for the owner to be able to rescue funds in the case they become stuck after launch
    // However, users should not trust the owner and watch the timelock contract least once a week on Etherscan
    // In the future, the timelock contract will be destroyed and the functionality will be removed after the code gets audited
    function rescue(
        address _token,
        address _to,
        uint256 _amount
    ) external {
        require(msg.sender == address(timelock));
        IERC20(_token).transfer(_to, _amount);
    }

    // Any tokens (other than the lpToken) that are sent here by mistake are recoverable by the vault owner
    function sweep(address _token) external {
        address owner = vault.owner();
        require(msg.sender == owner);
        require(_token != address(underlying));
        IERC20(_token).transfer(owner, IERC20(_token).balanceOf(address(this)));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IWETH.sol";

contract WrapResolverAvax {
    IWETH internal constant wMatic = IWETH(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

    function wrap(uint256 amount) external payable {
        uint256 realAmt = amount == type(uint256).max ? address(this).balance : amount;
        wMatic.deposit{value: realAmt}();
    }

    function unwrap(uint256 amount) external {
        uint256 realAmt = amount == type(uint256).max ? wMatic.balanceOf(address(this)) : amount;
        wMatic.withdraw(realAmt);
    }
}

contract WrapLogicAvax is WrapResolverAvax {
    string public constant name = "WrapLogicAvax";
    uint8 public constant version = 1;

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IUniswapV2Exchange.sol";
import "./Helpers.sol";

contract QuickswapResolver is Helpers {
    using UniversalERC20 for IERC20;
    using UniversalERC20 for IWETH;

    IUniswapV2Router internal constant router = IUniswapV2Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

    // EVENTS
    event LogSwap(address indexed user, address indexed src, address indexed dest, uint256 amount);
    event LogLiquidityAdd(
        address indexed user,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event LogLiquidityRemove(
        address indexed user,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );

    function _paySwapFees(IERC20 erc20, uint256 amt) internal returns (uint256 feesPaid) {
        (uint256 fee, uint256 maxFee, address feeRecipient) = getSwapFee();

        // When swap fee is 0 or sender has partner role
        if (fee == 0) return 0;

        require(feeRecipient != address(0), "ZERO ADDRESS");

        feesPaid = (amt * fee) / maxFee;
        erc20.universalTransfer(feeRecipient, feesPaid);
    }

    function _withdrawDust(IERC20 erc20) internal {
        erc20.universalTransfer(_msgSender(), erc20.universalBalanceOf(address(this)));
    }

    /**
     * @dev Swap tokens in Quickswap dex
     * @param path swap route fromToken => destToken
     * @param tokenAmt amount of fromTokens to swap
     * @param getId read value of tokenAmt from memory contract
     * @param setId set value of tokens swapped in memory contract
     */
    function swap(
        address[] memory path,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId,
        uint256 divider
    ) external payable {
        require(path.length >= 2, "INVALID PATH");

        uint256 realAmt = getId > 0 ? getUint(getId) / divider : tokenAmt;
        require(realAmt > 0, "ZERO AMOUNT");

        IERC20 fromToken = IERC20(path[0]);
        IERC20 destToken = IERC20(path[path.length - 1]);

        if (fromToken.isETH()) {
            wmatic.deposit{value: realAmt}();
            wmatic.universalApprove(address(router), realAmt);
            path[0] = address(wmatic);
        } else fromToken.universalApprove(address(router), realAmt);

        if (destToken.isETH()) path[path.length - 1] = address(wmatic);

        require(path[0] != path[path.length - 1], "SAME ASSETS");

        uint256 received = router.swapExactTokensForTokens(realAmt, 1, path, address(this), block.timestamp + 1)[
            path.length - 1
        ];

        uint256 feesPaid = _paySwapFees(destToken, received);

        received = received - feesPaid;

        if (destToken.isETH()) {
            wmatic.withdraw(received);
        }

        // set destTokens received
        if (setId > 0) {
            setUint(setId, received);
        }

        emit LogSwap(_msgSender(), address(fromToken), address(destToken), realAmt);
    }

    /**
     * @dev Add liquidity to Quickswap pools
     * @param amtA amount of A tokens to add
     * @param amtB amount of B tokens to add
     * @param getId read value of tokenAmt from memory contract position 1
     * @param getId2 read value of tokenAmt from memory contract position 2
     * @param setId set value of LP tokens received in memory contract
     */
    function addLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 amtA,
        uint256 amtB,
        uint256 getId,
        uint256 getId2,
        uint256 setId,
        uint256 divider
    ) external payable {
        uint256 realAmtA = getId > 0 ? getUint(getId) / divider : amtA;
        uint256 realAmtB = getId2 > 0 ? getUint(getId2) / divider : amtB;

        require(realAmtA > 0 && realAmtB > 0, "INVALID AMOUNTS");

        IERC20 tokenAReal = tokenA.isETH() ? wmatic : tokenA;
        IERC20 tokenBReal = tokenB.isETH() ? wmatic : tokenB;

        // Wrap Ether
        if (tokenA.isETH()) {
            wmatic.deposit{value: realAmtA}();
        }
        if (tokenB.isETH()) {
            wmatic.deposit{value: realAmtB}();
        }

        // Approve Router
        tokenAReal.universalApprove(address(router), realAmtA);
        tokenBReal.universalApprove(address(router), realAmtB);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(
            address(tokenAReal),
            address(tokenBReal),
            realAmtA,
            realAmtB,
            1,
            1,
            address(this),
            block.timestamp + 1
        );

        // send dust amount remaining after liquidity add to user
        _withdrawDust(tokenAReal);
        _withdrawDust(tokenBReal);

        // set aTokens received
        if (setId > 0) {
            setUint(setId, liquidity);
        }

        emit LogLiquidityAdd(_msgSender(), address(tokenAReal), address(tokenBReal), amountA, amountB);
    }

    /**
     * @dev Remove liquidity from Quickswap pool
     * @param tokenA address of token A from the pool
     * @param tokenA address of token B from the pool
     * @param poolToken address of the LP token
     * @param amtPoolTokens amount of LP tokens to burn
     * @param getId read value from memory contract
     * @param setId set value of amount tokenB received in memory contract position 1
     * @param setId2 set value of amount tokenB received in memory contract position 2
     */
    function removeLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        IERC20 poolToken,
        uint256 amtPoolTokens,
        uint256 getId,
        uint256 setId,
        uint256 setId2,
        uint256 divider
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId) / divider : amtPoolTokens;

        IERC20 tokenAReal = tokenA.isETH() ? wmatic : tokenA;
        IERC20 tokenBReal = tokenB.isETH() ? wmatic : tokenB;

        // Approve Router
        IERC20(address(poolToken)).universalApprove(address(router), realAmt);

        (uint256 amountA, uint256 amountB) = router.removeLiquidity(
            address(tokenAReal),
            address(tokenBReal),
            realAmt,
            1,
            1,
            address(this),
            block.timestamp + 1
        );

        // set tokenA received
        if (setId > 0) {
            setUint(setId, amountA);
        }

        // set tokenA received
        if (setId2 > 0) {
            setUint(setId2, amountB);
        }

        emit LogLiquidityRemove(_msgSender(), address(tokenAReal), address(tokenBReal), amountA, amountB);
    }
}

contract QuickswapLogic is QuickswapResolver {
    string public constant name = "QuickswapLogic";
    uint8 public constant version = 1;

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapV2Exchange.sol";

interface IUniswapV2Factory {
	function getPair(IERC20 tokenA, IERC20 tokenB)
		external
		view
		returns (IUniswapV2Exchange pair);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "./Helpers.sol";

contract SushiswapResolver is Helpers {
    using UniversalERC20 for IERC20;
    using UniversalERC20 for IWETH;

    /**
		@dev This is the address of the router of SushiSwap: SushiV2Router02. 
	**/
    IUniswapV2Router internal constant router = IUniswapV2Router(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    /**
		@dev This is the address of the factory of SushiSwap: SushiV2Factory. 
	**/
    IUniswapV2Factory internal constant factory = IUniswapV2Factory(0xc35DADB65012eC5796536bD9864eD8773aBc74C4);

    /** 
		@dev All the events for the router of SushiSwap:
		addLiquidity, removeLiquidity and swap.
	**/

    event LogSwap(address indexed user, address indexed src, address indexed dest, uint256 amount);
    event LogLiquidityAdd(
        address indexed user,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event LogLiquidityRemove(
        address indexed user,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );

    function _paySwapFees(IERC20 erc20, uint256 amt) internal returns (uint256 feesPaid) {
        (uint256 fee, uint256 maxFee, address feeRecipient) = getSwapFee();

        // When swap fee is 0 or sender has partner role
        if (fee == 0) return 0;

        require(feeRecipient != address(0), "ZERO ADDRESS");

        feesPaid = (amt * fee) / maxFee;
        erc20.universalTransfer(feeRecipient, feesPaid);
    }

    function _withdrawDust(IERC20 erc20) internal {
        erc20.universalTransfer(_msgSender(), erc20.universalBalanceOf(address(this)));
    }

    /**
	  @dev Swap tokens in SushiSwap Dex with the SushiSwap: SushiV2Router02.
	  @param path Path where the route go from the fromToken to the destToken.
	  @param amountOfTokens Amount of tokens to be swapped, fromToken => destToken.
	  @param getId Read the value of tokenAmt from memory contract, if is needed.
	  @param setId Set value of the tokens swapped in memory contract, if is needed.
		@param divider (for now is always 1).
	**/
    function swap(
        address[] memory path,
        uint256 amountOfTokens,
        uint256 getId,
        uint256 setId,
        uint256 divider
    ) external payable {
        uint256 memoryAmount = getId > 0 ? getUint(getId) / divider : amountOfTokens;
        require(memoryAmount > 0, "SwapTokens: ZERO_AMOUNT");
        require(path.length >= 2, "SwapTokens: INVALID_PATH");

        /**
			@dev The two tokens, to swap, the path[0] and the path[1].
		**/
        IERC20 fromToken = IERC20(path[0]);
        IERC20 destToken = IERC20(path[path.length - 1]);

        /**
			@dev If the token is the WMATIC then we should first deposit,
			if not then we should only use the universalApprove to approve
			the router to spend the tokens. 
		**/
        if (fromToken.isETH()) {
            wmatic.deposit{value: memoryAmount}();
            wmatic.universalApprove(address(router), memoryAmount);
            path[0] = address(wmatic);
        } else {
            fromToken.universalApprove(address(router), memoryAmount);
        }

        if (destToken.isETH()) {
            path[path.length - 1] = address(wmatic);
        }

        require(path[0] != path[path.length - 1], "SwapTokens: SAME_ASSETS");

        uint256 received = router.swapExactTokensForTokens(memoryAmount, 1, path, address(this), block.timestamp + 1)[
            path.length - 1
        ];

        uint256 feesPaid = _paySwapFees(destToken, received);

        received = received - feesPaid;

        if (destToken.isETH()) {
            wmatic.withdraw(received);
        }

        if (setId > 0) {
            setUint(setId, received);
        }

        emit LogSwap(_msgSender(), address(fromToken), address(destToken), memoryAmount);
    }

    /**
      @dev Add liquidity to Sushiswap pools.
      @param amountA Amount of tokenA to addLiquidity.
      @param amountB Amount of tokenB to addLiquidity.
      @param getId Read the value of the amount of the token from memory contract position 1.
      @param getId2 Read the value of the amount of the token from memory contract position 2.
      @param setId Set value of the LP tokens received in the memory contract.
      @param divider (for now is always 1).
	  **/
    function addLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 getId,
        uint256 getId2,
        uint256 setId,
        uint256 divider
    ) external payable {
        uint256 realAmtA = getId > 0 ? getUint(getId) / divider : amountA;
        uint256 realAmtB = getId2 > 0 ? getUint(getId2) / divider : amountB;

        require(realAmtA > 0 && realAmtB > 0, "AddLiquidity: INCORRECT_AMOUNTS");

        IERC20 tokenAReal = tokenA.isETH() ? wmatic : tokenA;
        IERC20 tokenBReal = tokenB.isETH() ? wmatic : tokenB;

        // If either the tokenA or tokenB is WMATIC wrap it.
        if (tokenA.isETH()) {
            wmatic.deposit{value: realAmtA}();
        }
        if (tokenB.isETH()) {
            wmatic.deposit{value: realAmtB}();
        }

        // Approve the router to spend the tokenA and the tokenB.
        tokenAReal.universalApprove(address(router), realAmtA);
        tokenBReal.universalApprove(address(router), realAmtB);

        (, , uint256 liquidity) = router.addLiquidity(
            address(tokenAReal),
            address(tokenBReal),
            realAmtA,
            realAmtB,
            1,
            1,
            address(this),
            block.timestamp + 1
        );

        // send dust amount remaining after liquidity add to user
        _withdrawDust(tokenAReal);
        _withdrawDust(tokenBReal);

        if (setId > 0) {
            setUint(setId, liquidity);
        }

        emit LogLiquidityAdd(_msgSender(), address(tokenAReal), address(tokenBReal), amountA, amountB);
    }

    /**
      @dev Remove liquidity from the Sushiswap pool.
      @param tokenA Address of token A from the pool.
      @param tokenA Address of token B from the pool.
      @param amountPoolTokens Amount of the LP tokens to burn. 
      @param getId Read the value from the memory contract. 
      @param setId Set value of the amount of the tokenA received in memory contract position 1.
      @param setId2 Set value of the amount of the tokenB in memory contract position 2.
      @param divider (for now is always 1).
	  **/
    function removeLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 amountPoolTokens,
        uint256 getId,
        uint256 setId,
        uint256 setId2,
        uint256 divider
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId) / divider : amountPoolTokens;

        IERC20 tokenAReal = tokenA.isETH() ? wmatic : tokenA;
        IERC20 tokenBReal = tokenB.isETH() ? wmatic : tokenB;

        // Get the address of the pairPool for the two address of the tokens.
        address poolToken = address(factory.getPair(tokenA, tokenB));

        // Approve the router to spend our LP tokens.
        IERC20(poolToken).universalApprove(address(router), realAmt);

        (uint256 amountA, uint256 amountB) = router.removeLiquidity(
            address(tokenAReal),
            address(tokenBReal),
            realAmt,
            1,
            1,
            address(this),
            block.timestamp + 1
        );

        // Set the tokenA received in the memory contract.
        if (setId > 0) {
            setUint(setId, amountA);
        }

        // Set the tokenB received in the memory contract.
        if (setId2 > 0) {
            setUint(setId2, amountB);
        }

        emit LogLiquidityRemove(_msgSender(), address(tokenAReal), address(tokenBReal), amountA, amountB);
    }
}

contract SushiswapLogic is SushiswapResolver {
    string public constant name = "SushiswapLogic";
    uint8 public constant version = 1;

    /** 
    @dev The fallback function is going to handle
    the Matic sended without any call.
  **/
    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IMemory.sol";
import "../interfaces/ICToken.sol";
import "../interfaces/IProtocolDataProvider.sol";

contract BorrowData {
    using SafeMath for uint256;

    IMemory memoryContract;

    address internal constant MATIC = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    IProtocolDataProvider aaveDataProviderV2 = IProtocolDataProvider(0x7551b5D2763519d4e37e8B81929D336De671d46d);

    struct Balance {
        uint256 aave;
        uint256 cream;
    }

    constructor(IMemory _memoryContract) {
        memoryContract = _memoryContract;
    }

    function getAaveBalanceV2(address token, address account) public view returns (uint256) {
        (, , address debtToken) = aaveDataProviderV2.getReserveTokensAddresses(token == MATIC ? WMATIC : token);

        return IERC20(debtToken).balanceOf(account);
    }

    function getCreamBalance(address token, address user) public view returns (uint256) {
        return ICToken(memoryContract.getCrToken(token)).borrowBalanceStored(user);
    }

    function getBalances(address[] calldata tokens, address user) external view returns (Balance[] memory) {
        Balance[] memory balances = new Balance[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i].aave = getAaveBalanceV2(tokens[i], user);
            balances[i].cream = getCreamBalance(tokens[i], user);
        }

        return balances;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ILendingPoolAddressesProvider} from "./ILendingPoolAddressesProvider.sol";

interface IProtocolDataProvider {
	struct TokenData {
		string symbol;
		address tokenAddress;
	}

	function ADDRESSES_PROVIDER()
		external
		view
		returns (ILendingPoolAddressesProvider);

	function getAllReservesTokens() external view returns (TokenData[] memory);

	function getAllATokens() external view returns (TokenData[] memory);

	function getReserveConfigurationData(address asset)
		external
		view
		returns (
			uint256 decimals,
			uint256 ltv,
			uint256 liquidationThreshold,
			uint256 liquidationBonus,
			uint256 reserveFactor,
			bool usageAsCollateralEnabled,
			bool borrowingEnabled,
			bool stableBorrowRateEnabled,
			bool isActive,
			bool isFrozen
		);

	function getReserveData(address asset)
		external
		view
		returns (
			uint256 availableLiquidity,
			uint256 totalStableDebt,
			uint256 totalVariableDebt,
			uint256 liquidityRate,
			uint256 variableBorrowRate,
			uint256 stableBorrowRate,
			uint256 averageStableBorrowRate,
			uint256 liquidityIndex,
			uint256 variableBorrowIndex,
			uint40 lastUpdateTimestamp
		);

	function getUserReserveData(address asset, address user)
		external
		view
		returns (
			uint256 currentATokenBalance,
			uint256 currentStableDebt,
			uint256 currentVariableDebt,
			uint256 principalStableDebt,
			uint256 scaledVariableDebt,
			uint256 stableBorrowRate,
			uint256 liquidityRate,
			uint40 stableRateLastUpdated,
			bool usageAsCollateralEnabled
		);

	function getReserveTokensAddresses(address asset)
		external
		view
		returns (
			address aTokenAddress,
			address stableDebtTokenAddress,
			address variableDebtTokenAddress
		);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILendingPoolAddressesProvider {
	event MarketIdSet(string newMarketId);
	event LendingPoolUpdated(address indexed newAddress);
	event ConfigurationAdminUpdated(address indexed newAddress);
	event EmergencyAdminUpdated(address indexed newAddress);
	event LendingPoolConfiguratorUpdated(address indexed newAddress);
	event LendingPoolCollateralManagerUpdated(address indexed newAddress);
	event PriceOracleUpdated(address indexed newAddress);
	event LendingRateOracleUpdated(address indexed newAddress);
	event ProxyCreated(bytes32 id, address indexed newAddress);
	event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

	function getMarketId() external view returns (string memory);

	function setMarketId(string calldata marketId) external;

	function setAddress(bytes32 id, address newAddress) external;

	function setAddressAsProxy(bytes32 id, address impl) external;

	function getAddress(bytes32 id) external view returns (address);

	function getLendingPool() external view returns (address);

	function setLendingPoolImpl(address pool) external;

	function getLendingPoolConfigurator() external view returns (address);

	function setLendingPoolConfiguratorImpl(address configurator) external;

	function getLendingPoolCollateralManager() external view returns (address);

	function setLendingPoolCollateralManager(address manager) external;

	function getPoolAdmin() external view returns (address);

	function setPoolAdmin(address admin) external;

	function getEmergencyAdmin() external view returns (address);

	function setEmergencyAdmin(address admin) external;

	function getPriceOracle() external view returns (address);

	function setPriceOracle(address priceOracle) external;

	function getLendingRateOracle() external view returns (address);

	function setLendingRateOracle(address lendingRateOracle) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IUniswapV2ERC20.sol";
import "../../interfaces/ICurvePool.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {LpData, Modifiers, IERC20Metadata, IERC20} from "./AppStorage.sol";

contract LpDataFacet is Modifiers {
    function getUniLpData(address lpPairToken) public view returns (LpData memory data) {
        uint256 market0;
        uint256 market1;

        //// Using Price Feeds
        int256 price0;
        int256 price1;

        //// Get Pair data
        IUniswapV2ERC20 pair = IUniswapV2ERC20(lpPairToken);
        (data.reserves0, data.reserves1, ) = pair.getReserves();
        data.token0 = pair.token0();
        data.token1 = pair.token1();
        data.symbol0 = IERC20Metadata(pair.token0()).symbol();
        data.symbol1 = IERC20Metadata(pair.token1()).symbol();
        data.totalSupply = pair.totalSupply();

        if (s.priceFeeds[data.token0] != address(0)) {
            (, price0, , , ) = AggregatorV3Interface(s.priceFeeds[data.token0]).latestRoundData();
            market0 = (formatDecimals(data.token0, uint256(data.reserves0)) * uint256(price0)) / (10**8);
        }
        if (s.priceFeeds[data.token1] != address(0)) {
            (, price1, , , ) = AggregatorV3Interface(s.priceFeeds[data.token1]).latestRoundData();
            market1 = (formatDecimals(data.token1, uint256(data.reserves1)) * uint256(price1)) / (10**8);
        }

        if (market0 == 0) {
            data.totalMarketUSD = 2 * market1;
        } else if (market1 == 0) {
            data.totalMarketUSD = 2 * market0;
        } else {
            data.totalMarketUSD = market0 + market1;
        }

        if (data.totalMarketUSD == 0) revert("MARKET ZERO");

        data.lpPrice = (data.totalMarketUSD * 1 ether) / data.totalSupply;
    }

    function getCurveLpInfo(address lpToken) public view returns (uint256 lpPrice, uint256 totalSupply) {
        if (s.curvePools[lpToken] != address(0)) {
            lpPrice = ICurvePool(s.curvePools[lpToken]).get_virtual_price();
            totalSupply = IERC20(lpToken).totalSupply();
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IUniswapV2ERC20.sol";
import "../../interfaces/ICurvePool.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {LpData, AvaModifiers, IERC20Metadata, IERC20} from "./AppStorage.sol";

contract AvaLpDataFacet is AvaModifiers {
    function getUniLpData(address lpPairToken) public view returns (LpData memory data) {
        uint256 market0;
        uint256 market1;

        //// Using Price Feeds
        int256 price0;
        int256 price1;

        //// Get Pair data
        IUniswapV2ERC20 pair = IUniswapV2ERC20(lpPairToken);
        (data.reserves0, data.reserves1, ) = pair.getReserves();
        data.token0 = pair.token0();
        data.token1 = pair.token1();
        data.symbol0 = IERC20Metadata(pair.token0()).symbol();
        data.symbol1 = IERC20Metadata(pair.token1()).symbol();
        data.totalSupply = pair.totalSupply();

        if (s.priceFeeds[data.token0] != address(0)) {
            (, price0, , , ) = AggregatorV3Interface(s.priceFeeds[data.token0]).latestRoundData();
            market0 = (formatDecimals(data.token0, uint256(data.reserves0)) * uint256(price0)) / (10**8);
        }
        if (s.priceFeeds[data.token1] != address(0)) {
            (, price1, , , ) = AggregatorV3Interface(s.priceFeeds[data.token1]).latestRoundData();
            market1 = (formatDecimals(data.token1, uint256(data.reserves1)) * uint256(price1)) / (10**8);
        }

        if (market0 == 0) {
            data.totalMarketUSD = 2 * market1;
        } else if (market1 == 0) {
            data.totalMarketUSD = 2 * market0;
        } else {
            data.totalMarketUSD = market0 + market1;
        }

        if (data.totalMarketUSD == 0) revert("MARKET ZERO");

        data.lpPrice = (data.totalMarketUSD * 1 ether) / data.totalSupply;
    }

    function getCurveLpInfo(address lpToken) public view returns (uint256 lpPrice, uint256 totalSupply) {
        if (s.curvePools[lpToken] != address(0)) {
            lpPrice = ICurvePool(s.curvePools[lpToken]).get_virtual_price();
            totalSupply = IERC20(lpToken).totalSupply();
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IStakingRewards.sol";
import "../../interfaces/IDragonLair.sol";
import "../../interfaces/IDistributionFactory.sol";
import "../../interfaces/IMasterChefDistribution.sol";
import "../../interfaces/IFarmV3.sol";
import "../../interfaces/IERC4626.sol";
import {AvaModifiers, IERC20Metadata, SynthData, ChefData} from "./AppStorage.sol";

contract AvaStakingFacet is AvaModifiers {
    /**
        @dev fetch general staking info of a certain synthetix type contract
    */
    function getStakingInfo(IDistributionFactory stakingFactory, address[] calldata poolTokens)
        external
        view
        returns (SynthData[] memory)
    {
        SynthData[] memory _datas = new SynthData[](poolTokens.length);

        IStakingRewards instance;
        uint256 rewardRate;
        uint256 rewardBalance;
        address rewardsToken;
        uint256 periodFinish;
        uint256 totalStaked;

        for (uint256 i = 0; i < _datas.length; i++) {
            instance = IStakingRewards(stakingFactory.stakingRewardsInfoByStakingToken(poolTokens[i]));

            // If poolToken not present in factory, skip
            if (address(instance) == address(0)) continue;

            rewardsToken = instance.rewardsToken();
            rewardBalance = IERC20Metadata(rewardsToken).balanceOf(address(instance));
            rewardRate = instance.rewardRate();
            periodFinish = instance.periodFinish();
            totalStaked = instance.totalSupply();

            _datas[i] = SynthData(
                poolTokens[i],
                address(instance),
                rewardsToken,
                totalStaked,
                rewardRate,
                periodFinish,
                rewardBalance
            );
        }

        return _datas;
    }

    /**
        @dev fetch reward rate per block for masterchef poolIds
    */
    function getMasterChefInfo(IFarmV3 chef, uint poolId) external view returns (uint ratePerSec, uint totalStaked) {
        uint256 rewardPerSecond = chef.rewardPerSecond();
        (address depositToken, uint allocPoint) = chef.poolInfo(poolId);

        uint256 totalAllocPoint = chef.totalAllocPoint();

        ratePerSec = (rewardPerSecond * allocPoint) / totalAllocPoint;
        totalStaked = IERC20Metadata(depositToken).balanceOf(address(chef));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../../../interfaces/IStrat.sol";
import "../../../../interfaces/IVault.sol";
import "../../../../interfaces/IQiStakingRewards.sol";
import "../../../../interfaces/IDelegateRegistry.sol";
import "../../../../utils/Timelock.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AvaQiDaoStrat is IStrat {
    using SafeERC20 for IERC20;

    // ==== STATE ===== //

    IERC20 public constant QI = IERC20(0xA56F9A54880afBc30CF29bB66d2D9ADCdcaEaDD6);

    IVault public vault;

    // QiDao contracts
    address public chef;
    address public qiDelegationContract;
    uint public poolId;

    // LP token to deposit in chef
    IERC20 public underlying;

    Timelock public timelock;

    // Rewards swap details
    address public override router;
    address[] public outputToTargetRoute;

    // EVENTS
    event VoterUpdated(address indexed voter);
    event DelegationContractUpdated(address indexed delegationContract);

    // ==== MODIFIERS ===== //

    modifier onlyVault() {
        require(msg.sender == address(vault), "!vault");
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == address(timelock), "!timelock");
        _;
    }

    // ==== INITIALIZATION ===== //

    constructor(
        IVault vault_,
        IERC20 underlying_,
        address chef_,
        uint poolId_,
        address router_,
        address[] memory outputToTargetRoute_
    ) {
        require(outputToTargetRoute_[0] == address(QI));
        require(outputToTargetRoute_[outputToTargetRoute_.length - 1] == address(vault_.target()));

        vault = vault_;
        underlying = underlying_;
        chef = chef_;
        poolId = poolId_;
        router = router_;
        outputToTargetRoute = outputToTargetRoute_;

        timelock = new Timelock(msg.sender, 3 days);

        // Infite Approvals
        underlying.safeApprove(chef, type(uint256).max);
    }

    // ==== GETTERS ===== //

    /**
		@dev total value of LP tokens staked on QiDao Staking Contract
	*/
    function calcTotalValue() external view override returns (uint256) {
        return IQiStakingRewards(chef).deposited(poolId, address(this));
    }

    /**
		@dev amount of claimable QI
	*/
    function totalYield() external view override returns (uint256) {
        return IQiStakingRewards(chef).pending(poolId, address(this));
    }

    function outputToTarget() external view override returns (address[] memory) {
        return outputToTargetRoute;
    }

    // ==== MAIN FUNCTIONS ===== //

    /**
		@notice Invest LP Tokens into QiDao staking contract
		@dev can only be called by the vault contract
	*/
    function invest() external override onlyVault {
        uint256 balance = underlying.balanceOf(address(this));
        require(balance > 0);

        IQiStakingRewards(chef).deposit(poolId, balance);
    }

    /**
		@notice Redeem LP Tokens from QiDao staking contract
		@dev can only be called by the vault contract
		@param amount amount of LP Tokens to withdraw
	*/
    function divest(uint256 amount) public override onlyVault {
        uint amtBefore = underlying.balanceOf(address(this));

        IQiStakingRewards(chef).withdraw(poolId, amount);

        // If there are withdrawal fees in staking contract
        uint withdrawn = underlying.balanceOf(address(this)) - amtBefore;

        underlying.safeTransfer(address(vault), withdrawn);
    }

    /**
		@notice Claim QI rewards from staking contract
		@dev can only be called by the vault contract
		@dev only used when harvesting
	*/
    function claim() external override onlyVault returns (uint256 claimed) {
        IQiStakingRewards(chef).withdraw(poolId, 0);

        claimed = QI.balanceOf(address(this));
        QI.safeTransfer(address(vault), claimed);
    }

    // ==== RESCUE ===== //

    // IMPORTANT: This function can only be called by the timelock to recover any token amount including deposited cTokens
    // However, the owner of the timelock must first submit their request and wait timelock.delay() seconds before confirming.
    // This gives depositors a good window to withdraw before a potentially malicious escape
    // The intent is for the owner to be able to rescue funds in the case they become stuck after launch
    // However, users should not trust the owner and watch the timelock contract least once a week on Etherscan
    // In the future, the timelock contract will be destroyed and the functionality will be removed after the code gets audited
    function rescue(
        address _token,
        address _to,
        uint256 _amount
    ) external override onlyTimelock {
        IERC20(_token).transfer(_to, _amount);
    }

    function setSwapRoute(address[] memory outputToTargetRoute_) external override onlyTimelock {
        require(outputToTargetRoute_[0] == address(QI));
        require(outputToTargetRoute_[outputToTargetRoute_.length - 1] == address(vault.target()));

        outputToTargetRoute = outputToTargetRoute_;
    }

    function setRouter(address router_) external override onlyTimelock {
        router = router_;
    }

    /// @notice Delegate Qi voting power to another address
    /// @param _id   The delegate ID
    /// @param _voter Address to delegate the votes to
    function delegateVotes(bytes32 _id, address _voter) external onlyTimelock {
        IDelegateRegistry(qiDelegationContract).setDelegate(_id, _voter);
        emit VoterUpdated(_voter);
    }

    /// @notice Updates the delegation contract for Qi token Lock
    /// @param _delegationContract Updated delegation contract address
    function updateQiDelegationContract(address _delegationContract) external onlyTimelock {
        require(_delegationContract == address(0), "ZERO_ADDRESS");
        qiDelegationContract = _delegationContract;
        emit DelegationContractUpdated(_delegationContract);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../../interfaces/IUniswapV2Router.sol";
import "../../../../interfaces/IUniswapV2ERC20.sol";
import "../../../../interfaces/IQiStakingRewards.sol";
import "../../CompoundStrat.sol";

contract StrategySimpleQiDao is CompoundStrat {
    using SafeERC20 for IERC20;

    // Tokens used
    address public lpToken0;
    address public lpToken1;

    // Qi Farm
    address public chef;

    // Routes
    address[] public outputToNativeRoute;
    address[] public outputToLp0Route;
    address[] public outputToLp1Route;

    uint256 public poolId;

    /**
     * @dev Event that is fired each time someone harvests the strat.
     */
    event StratHarvest(address indexed harvester, uint256 wantHarvested, uint256 tvl);
    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);

    constructor(
        address _want,
        address _chef,
        address _unirouter,
        address _keeper,
        address _strategist,
        address _ethaFeeRecipient,
        address[] memory _outputToNativeRoute,
        address[] memory _outputToLp0Route,
        address[] memory _outputToLp1Route,
        uint256 _poolId
    ) CompoundStratManager(_keeper, _strategist, _unirouter, _ethaFeeRecipient) {
        want = _want;
        chef = _chef;
        poolId = _poolId;

        require(_outputToNativeRoute.length >= 2);
        output = _outputToNativeRoute[0];
        native = _outputToNativeRoute[_outputToNativeRoute.length - 1];
        outputToNativeRoute = _outputToNativeRoute;

        // setup lp routing
        lpToken0 = IUniswapV2ERC20(want).token0();
        require(_outputToLp0Route[0] == output);
        require(_outputToLp0Route[_outputToLp0Route.length - 1] == lpToken0);
        outputToLp0Route = _outputToLp0Route;

        lpToken1 = IUniswapV2ERC20(want).token1();
        require(_outputToLp1Route[0] == output);
        require(_outputToLp1Route[_outputToLp1Route.length - 1] == lpToken1);
        outputToLp1Route = _outputToLp1Route;

        _giveAllowances();
    }

    // puts the funds to work
    function deposit() public override whenNotPaused {
        uint256 wantBal = balanceOfWant();

        if (wantBal > 0) {
            IQiStakingRewards(chef).deposit(poolId, wantBal);
            emit Deposit(balanceOfStrategy());
        }
    }

    function withdraw(uint256 _amount) external override whenNotPaused onlyVault {
        uint256 wantBal = balanceOfWant();

        if (wantBal < _amount) {
            IQiStakingRewards(chef).withdraw(poolId, _amount - wantBal);
            wantBal = balanceOfWant();
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        IERC20(want).safeTransfer(vault, wantBal);
        emit Withdraw(balanceOfStrategy());
    }

    // compounds earnings and charges performance fee
    function _harvest(address callFeeRecipient) internal override whenNotPaused {
        // Claiming the rewards from qidao
        IQiStakingRewards(chef).withdraw(poolId, 0);
        uint256 outputBal = IERC20(output).balanceOf(address(this));

        // If there are profits
        if (outputBal > 0) {
            chargeFees(callFeeRecipient);
            addLiquidity();
            uint256 wantHarvested = balanceOfWant();
            deposit();

            lastHarvest = block.timestamp;
            emit StratHarvest(msg.sender, wantHarvested, balanceOfStrategy());
        }
    }

    // performance fees
    function chargeFees(address callFeeRecipient) internal {
        uint256 toNative = (IERC20(output).balanceOf(address(this)) * profitFee) / MAX_FEE;

        if (toNative > 0)
            IUniswapV2Router(unirouter).swapExactTokensForTokens(
                toNative,
                0,
                outputToNativeRoute,
                address(this),
                block.timestamp
            );
        else return;

        uint256 nativeFeeBal = IERC20(native).balanceOf(address(this));

        _deductFees(native, callFeeRecipient, nativeFeeBal);
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 outputHalf = IERC20(output).balanceOf(address(this)) / 2;

        if (lpToken0 != output) {
            IUniswapV2Router(unirouter).swapExactTokensForTokens(
                outputHalf,
                0,
                outputToLp0Route,
                address(this),
                block.timestamp
            );
        }

        if (lpToken1 != output) {
            IUniswapV2Router(unirouter).swapExactTokensForTokens(
                outputHalf,
                0,
                outputToLp1Route,
                address(this),
                block.timestamp
            );
        }

        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
        IUniswapV2Router(unirouter).addLiquidity(lpToken0, lpToken1, lp0Bal, lp1Bal, 1, 1, address(this), block.timestamp);
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() public view override returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOfStrategy() public view override returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view override returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view override returns (uint256) {
        return IQiStakingRewards(chef).deposited(poolId, address(this));
    }

    // returns rewards unharvested
    function rewardsAvailable() public view returns (uint256) {
        return IQiStakingRewards(chef).pending(poolId, address(this));
    }

    // returns native reward for calling harvest
    function callReward() public view returns (uint256) {
        if (callFee == 0) return 0;

        uint256 outputBal = rewardsAvailable();
        uint256 nativeOut;
        if (outputBal > 0) {
            try IUniswapV2Router(unirouter).getAmountsOut(outputBal, outputToNativeRoute) returns (
                uint256[] memory amountOut
            ) {
                nativeOut = amountOut[amountOut.length - 1];
            } catch {}
        }

        return (nativeOut * profitFee * callFee) / (MAX_FEE * MAX_FEE);
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external override onlyVault {
        // Claim rewards and compound
        _harvest(ethaFeeRecipient);

        // Withdraw all funds from gauge
        IQiStakingRewards(chef).withdraw(poolId, balanceOfPool());

        uint256 wantBal = balanceOfWant();
        IERC20(want).safeTransfer(vault, wantBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public override onlyManager {
        pause();
        IQiStakingRewards(chef).withdraw(poolId, balanceOfPool());
    }

    function pause() public onlyManager {
        _pause();

        _removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();

        _giveAllowances();

        deposit();
    }

    // Returns the maximum amount of asset tokens that can be deposited
    function getMaximumDepositLimit() public pure returns (uint256) {
        return type(uint256).max;
    }

    function _giveAllowances() internal {
        IERC20(want).safeApprove(chef, type(uint256).max);
        IERC20(output).safeApprove(unirouter, type(uint256).max);
        if (output != lpToken0) IERC20(lpToken0).safeApprove(unirouter, type(uint256).max);
        if (output != lpToken1) IERC20(lpToken1).safeApprove(unirouter, type(uint256).max);
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(chef, 0);
        IERC20(output).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {LibError} from "../../../../libs/LibError.sol";
import {IUniswapV2Router} from "../../../../interfaces/IUniswapV2Router.sol";
import {IUniswapV2ERC20} from "../../../../interfaces/IUniswapV2ERC20.sol";
import {IQiStakingRewards} from "../../../../interfaces/IQiStakingRewards.sol";
import {IERC20StablecoinQi} from "../../../../interfaces/IERC20StablecoinQi.sol";
import {IDelegateRegistry} from "../../../../interfaces/IDelegateRegistry.sol";

import "../../CompoundStrat.sol";

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract StrategyQiVault is CompoundStrat {
    using SafeERC20 for IERC20;

    // Tokens used
    IERC20 public assetToken; // Final tokens that are deposited to Qi vault: eg. BAL, camWMATIC, camWETH, LINK, etc.
    IERC20 public mai = IERC20(0xa3Fa99A148fA48D14Ed51d610c367C61876997F1); // mai token
    IERC20 public qiToken = IERC20(0x580A84C73811E1839F75d86d75d88cCa0c241fF4); //qi token

    // QiDao addresses
    IERC20StablecoinQi public qiVault; // Qi Vault for Asset token
    address public qiStakingRewards; //0x574Fe4E8120C4Da1741b5Fd45584de7A5b521F0F for Qi staking rewards masterchef contract
    uint256 public qiVaultId; // Vault ID

    // LP tokens and Swap paths
    address public lpToken0; //WMATIC
    address public lpToken1; //QI
    address public lpPairToken; //LP Pair token address

    address[] public assetToMai; // AssetToken to MAI
    address[] public maiToAsset; // Mai to AssetToken
    address[] public qiToAsset; // Rewards token to AssetToken
    address[] public maiToLp0; // MAI to WMATIC token
    address[] public maiToLp1; // MAI to QI token
    address[] public lp0ToMai; // LP0(WMATIC) to MAI
    address[] public lp1ToMai; // LP1(QI) to MAI

    // Config variables
    uint256 public lpFactor = 5;
    uint256 public qiRewardsPid = 1; // Staking rewards pool id for WMATIC-QI
    address public qiDelegationContract;

    // Chainlink Price Feed
    mapping(address => address) public priceFeeds;

    uint256 public SAFE_COLLAT_LOW = 180;
    uint256 public SAFE_COLLAT_TARGET = 200;
    uint256 public SAFE_COLLAT_HIGH = 220;

    // Events
    event VoterUpdated(address indexed voter);
    event DelegationContractUpdated(address indexed delegationContract);
    event SwapPathUpdated(address[] previousPath, address[] updatedPath);
    event StrategyRetired(address indexed stragegyAddress);
    event Harvested(address indexed harvester);
    event VaultRebalanced();

    constructor(
        address _assetToken,
        address _qiVaultAddress,
        address _lpPairToken,
        address _qiStakingRewards,
        address _keeper,
        address _strategist,
        address _unirouter,
        address _ethaFeeRecipient
    ) CompoundStratManager(_keeper, _strategist, _unirouter, _ethaFeeRecipient) {
        assetToken = IERC20(_assetToken);
        lpPairToken = _lpPairToken;
        qiStakingRewards = _qiStakingRewards;

        // For Compound Strat
        want = _assetToken;
        output = address(qiToken);
        native = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270); //WMATIC

        lpToken0 = IUniswapV2ERC20(lpPairToken).token0();
        lpToken1 = IUniswapV2ERC20(lpPairToken).token1();

        qiVault = IERC20StablecoinQi(_qiVaultAddress);
        qiVaultId = qiVault.createVault();
        if (!qiVault.exists(qiVaultId)) {
            revert LibError.QiVaultError();
        }
        _giveAllowances();
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////      Internal functions      //////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////

    /// @dev Provides token allowances to Unirouter, QiVault and Qi MasterChef contract
    function _giveAllowances() internal {
        // Asset Token approvals
        assetToken.safeApprove(address(qiVault), 0);
        assetToken.safeApprove(address(qiVault), type(uint256).max);

        assetToken.safeApprove(unirouter, 0);
        assetToken.safeApprove(unirouter, type(uint256).max);

        // Rewards token approval
        qiToken.safeApprove(unirouter, 0);
        qiToken.safeApprove(unirouter, type(uint256).max);

        // MAI token approvals
        mai.safeApprove(address(qiVault), 0);
        mai.safeApprove(address(qiVault), type(uint256).max);

        mai.safeApprove(unirouter, 0);
        mai.safeApprove(unirouter, type(uint256).max);

        // LP Token approvals
        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, type(uint256).max);

        IERC20(lpToken1).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, type(uint256).max);

        IERC20(lpPairToken).safeApprove(qiStakingRewards, 0);
        IERC20(lpPairToken).safeApprove(qiStakingRewards, type(uint256).max);

        IERC20(lpPairToken).safeApprove(unirouter, 0);
        IERC20(lpPairToken).safeApprove(unirouter, type(uint256).max);
    }

    /// @dev Revoke token allowances
    function _removeAllowances() internal {
        // Asset Token approvals
        assetToken.safeApprove(address(qiVault), 0);
        assetToken.safeApprove(unirouter, 0);

        // Rewards token approval
        qiToken.safeApprove(unirouter, 0);

        // MAI token approvals
        mai.safeApprove(address(qiVault), 0);
        mai.safeApprove(unirouter, 0);

        // LP Token approvals
        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, 0);
        IERC20(lpPairToken).safeApprove(qiStakingRewards, 0);
        IERC20(lpPairToken).safeApprove(unirouter, 0);
    }

    function _swap(uint256 amount, address[] memory swapPath) internal {
        if (swapPath.length > 1) {
            IUniswapV2Router(unirouter).swapExactTokensForTokens(amount, 0, swapPath, address(this), block.timestamp);
        } else {
            revert LibError.InvalidSwapPath();
        }
    }

    function _getContractBalance(address token) internal view returns (uint256 tokenBalance) {
        return IERC20(token).balanceOf(address(this));
    }

    /// @notice Returns the total supply and market of LP
    /// @dev Will work only if price oracle for either one of the lp tokens is set
    /// @return lpTotalSupply Total supply of LP tokens
    /// @return totalMarketUSD Total market in USD of LP tokens
    function _getLPTotalMarketUSD() internal view returns (uint256 lpTotalSupply, uint256 totalMarketUSD) {
        uint256 market0;
        uint256 market1;

        //// Using Price Feeds
        int256 price0;
        int256 price1;

        IUniswapV2ERC20 pair = IUniswapV2ERC20(lpPairToken);
        lpTotalSupply = pair.totalSupply();
        (uint112 _reserve0, uint112 _reserve1, ) = pair.getReserves();

        if (priceFeeds[lpToken0] != address(0)) {
            (, price0, , , ) = AggregatorV3Interface(priceFeeds[lpToken0]).latestRoundData();
            market0 = (uint256(_reserve0) * uint256(price0)) / (10**8);
        }
        if (priceFeeds[lpToken1] != address(0)) {
            (, price1, , , ) = AggregatorV3Interface(priceFeeds[lpToken1]).latestRoundData();
            market1 = (uint256(_reserve1) * uint256(price1)) / (10**8);
        }

        if (market0 == 0) {
            totalMarketUSD = 2 * market1;
        } else if (market1 == 0) {
            totalMarketUSD = 2 * market0;
        } else {
            totalMarketUSD = market0 + market1;
        }
        if (totalMarketUSD == 0) revert LibError.PriceFeedError();
    }

    /// @notice Returns the LP amount equivalent of assetAmount
    /// @param assetAmount Amount of asset tokens for which equivalent LP tokens need to be calculated
    /// @return lpAmount USD equivalent of assetAmount in LP tokens
    function _getLPTokensFromAsset(uint256 assetAmount) internal view returns (uint256 lpAmount) {
        (uint256 lpTotalSupply, uint256 totalMarketUSD) = _getLPTotalMarketUSD();

        // Calculations
        // usdEquivalentOfEachLp = (totalMarketUSD / totalSupply);
        // usdEquivalentOfAsset = assetAmount * AssetTokenPrice;
        // lpAmount = usdEquivalentOfAsset / usdEquivalentOfEachLp
        lpAmount = (assetAmount * getAssetTokenPrice() * lpTotalSupply) / (totalMarketUSD * 10**8);

        // Return additional amount(currently 110%) of the required LP tokens to account for slippage and future withdrawals
        lpAmount = (lpAmount * (100 + lpFactor)) / 100;

        // If calculated amount is greater than total deposited, withdraw everything
        uint256 totalLp = getStrategyLpDeposited();
        if (lpAmount > totalLp) {
            lpAmount = totalLp;
        }
    }

    /// @notice Returns the LP amount equivalent of maiAmount
    /// @param maiAmount Amount of asset tokens for which equivalent LP tokens need to be calculated
    /// @return lpAmount USD equivalent of maiAmount in LP tokens
    function _getLPTokensFromMai(uint256 maiAmount) internal view returns (uint256 lpAmount) {
        (uint256 lpTotalSupply, uint256 totalMarketUSD) = _getLPTotalMarketUSD();

        // Calculations
        // usdEquivalentOfEachLp = (totalMarketUSD / totalSupply);
        // usdEquivalentOfAsset = assetAmount * ethPriceSource;
        // lpAmount = usdEquivalentOfAsset / usdEquivalentOfEachLp
        lpAmount = (maiAmount * getMaiTokenPrice() * lpTotalSupply) / (totalMarketUSD * 10**8);

        // Return additional amount(currently 110%) of the required LP tokens to account for slippage and future withdrawals
        lpAmount = (lpAmount * (100 + lpFactor)) / 100;

        // If calculated amount is greater than total deposited, withdraw everything
        uint256 totalLp = getStrategyLpDeposited();
        if (lpAmount > totalLp) {
            lpAmount = totalLp;
        }
    }

    /// @notice Deposits the asset token to QiVault from balance of this contract
    /// @notice Asset tokens must be transferred to the contract first before calling this function
    /// @param depositAmount AMount to be deposited to Qi Vault
    function _depositToQiVault(uint256 depositAmount) internal {
        // Deposit to QiDao vault
        qiVault.depositCollateral(qiVaultId, depositAmount);
    }

    /// @notice Borrows safe amount of MAI tokens from Qi Vault
    function _borrowTokens() internal {
        uint256 currentCollateralPercent = getCollateralPercent();
        if (currentCollateralPercent <= SAFE_COLLAT_TARGET && currentCollateralPercent != 0) {
            revert LibError.InvalidCDR(currentCollateralPercent, SAFE_COLLAT_TARGET);
        }

        uint256 amountToBorrow = safeAmountToBorrow();
        qiVault.borrowToken(qiVaultId, amountToBorrow);

        uint256 updatedCollateralPercent = getCollateralPercent();
        if (updatedCollateralPercent < SAFE_COLLAT_LOW && updatedCollateralPercent != 0) {
            revert LibError.InvalidCDR(updatedCollateralPercent, SAFE_COLLAT_LOW);
        }

        if (qiVault.checkLiquidation(qiVaultId)) revert LibError.LiquidationRisk();
    }

    /// @notice Repay MAI debt back to the qiVault
    function _repayMaiDebt() internal {
        uint256 maiDebt = getStrategyDebt();
        uint256 maiBalance = _getContractBalance(address(mai));

        if (maiDebt > maiBalance) {
            qiVault.payBackToken(qiVaultId, maiBalance);
        } else {
            qiVault.payBackToken(qiVaultId, maiDebt);
            _swap(_getContractBalance(address(mai)), maiToAsset);
        }
    }

    /// @notice Swaps MAI for lpToken0 and lpToken 1 and adds liquidity to the AMM
    function _swapMaiAndAddLiquidity() internal {
        uint256 outputHalf = _getContractBalance(address(mai)) / 2;

        _swap(outputHalf, maiToLp0);
        _swap(outputHalf, maiToLp1);

        uint256 lp0Bal = _getContractBalance(lpToken0);
        uint256 lp1Bal = _getContractBalance(lpToken1);

        IUniswapV2Router(unirouter).addLiquidity(lpToken0, lpToken1, lp0Bal, lp1Bal, 1, 1, address(this), block.timestamp);

        lp0Bal = _getContractBalance(lpToken0);
        lp1Bal = _getContractBalance(lpToken1);
    }

    /// @notice Deposits LP tokens to QiStaking Farm (MasterChef contract)
    /// @param amountToDeposit Amount of LP tokens to deposit to Farm
    function _depositLPToFarm(uint256 amountToDeposit) internal {
        IQiStakingRewards(qiStakingRewards).deposit(qiRewardsPid, amountToDeposit);
    }

    /// @notice Withdraw LP tokens from QiStaking Farm and removes liquidity from AMM
    /// @param withdrawAmount Amount of LP tokens to withdraw from Farm and AMM
    function _withdrawLpAndRemoveLiquidity(uint256 withdrawAmount) internal {
        IQiStakingRewards(qiStakingRewards).withdraw(qiRewardsPid, withdrawAmount);
        uint256 lpBalance = _getContractBalance(lpPairToken);
        IUniswapV2Router(unirouter).removeLiquidity(lpToken0, lpToken1, lpBalance, 1, 1, address(this), block.timestamp);
    }

    /// @notice Delegate Qi voting power to another address
    /// @param id   The delegate ID
    /// @param voter Address to delegate the votes to
    function _delegateVotingPower(bytes32 id, address voter) internal {
        IDelegateRegistry(qiDelegationContract).setDelegate(id, voter);
    }

    /// @notice Withdraws assetTokens from the Vault
    /// @param amountToWithdraw  Amount of assetTokens to withdraw from the vault
    function _withdrawFromVault(uint256 amountToWithdraw) internal {
        uint256 vaultCollateral = getStrategyCollateral();
        uint256 safeWithdrawAmount = safeAmountToWithdraw();

        if (amountToWithdraw == 0) revert LibError.InvalidAmount(0, 1);
        if (amountToWithdraw > vaultCollateral) revert LibError.InvalidAmount(amountToWithdraw, vaultCollateral);

        // Repay Debt from LP if required
        if (safeWithdrawAmount < amountToWithdraw) {
            // Debt is 50% of value of asset tokens when SAFE_COLLAT_TARGET = 200 (i.e 100/200 => 0.5)
            uint256 amountFromLP = ((amountToWithdraw - safeWithdrawAmount) * (100 + 10)) / SAFE_COLLAT_TARGET;

            //Withdraw from LP and repay debt
            uint256 lpAmount = _getLPTokensFromAsset(amountFromLP);
            _repayDebtLp(lpAmount);
        }

        // Calculate Max withdraw amount after repayment
        // console.log("Minimum collateral percent: ", qiVault._minimumCollateralPercentage());
        uint256 minimumCdr = qiVault._minimumCollateralPercentage() + 10;
        uint256 stratDebt = getStrategyDebt();
        uint256 maxWithdrawAmount = vaultCollateral - safeCollateralForDebt(stratDebt, minimumCdr);

        if (amountToWithdraw < maxWithdrawAmount) {
            // Withdraw collateral completely from qiVault
            qiVault.withdrawCollateral(qiVaultId, amountToWithdraw);
            assetToken.safeTransfer(msg.sender, amountToWithdraw);

            uint256 collateralPercent = getCollateralPercent();
            if (collateralPercent < SAFE_COLLAT_LOW) {
                // Rebalance from collateral
                rebalanceVault(false);
            }
            collateralPercent = getCollateralPercent();
            uint256 minCollateralPercent = qiVault._minimumCollateralPercentage();
            if (collateralPercent < minCollateralPercent && collateralPercent != 0) {
                revert LibError.InvalidCDR(collateralPercent, minCollateralPercent);
            }
        } else {
            revert LibError.InvalidAmount(safeWithdrawAmount, amountToWithdraw);
        }
    }

    /// @notice Charge Strategist and Performance fees
    /// @param callFeeRecipient Address to send the callFee (if set)
    function _chargeFees(address callFeeRecipient) internal {
        if (profitFee == 0) {
            return;
        }
        uint256 totalFee = (_getContractBalance(address(assetToken)) * profitFee) / MAX_FEE;
        _deductFees(address(assetToken), callFeeRecipient, totalFee);
    }

    /// @notice Harvest the rewards earned by Vault for more collateral tokens
    /// @param callFeeRecipient Address to send the callFee (if set)
    function _harvest(address callFeeRecipient) internal override {
        //1. Claim accrued Qi rewards from LP farm
        _depositLPToFarm(0);

        //2. Swap Qi tokens for asset tokens
        uint256 qiBalance = _getContractBalance(address(qiToken));
        if (qiBalance > 0) {
            _swap(qiBalance, qiToAsset);

            //3. Charge performance fee and deposit to Qi vault
            _chargeFees(callFeeRecipient);
            _depositToQiVault(_getContractBalance(address(assetToken)));

            lastHarvest = block.timestamp;
            emit Harvested(msg.sender);
        } else {
            revert LibError.HarvestNotReady();
        }
    }

    /// @notice Repay Debt by liquidating LP tokens
    /// @param lpAmount Amount of LP tokens to liquidate
    function _repayDebtLp(uint256 lpAmount) internal {
        //1. Withdraw LP tokens from Farm and remove liquidity
        _withdrawLpAndRemoveLiquidity(lpAmount);

        //2. Swap LP tokens for MAI tokens
        _swap(_getContractBalance(lpToken0), lp0ToMai);
        _swap(_getContractBalance(lpToken1), lp1ToMai);

        //3. Repay Debt to qiVault
        _repayMaiDebt();
    }

    /// @notice Repay Debt from deposited collateral tokens
    /// @param collateralAmount Amount of collateral tokens to withdraw
    function _repayDebtCollateral(uint256 collateralAmount) internal {
        //1. Withdraw assetToken from qiVault
        uint256 minimumCdr = qiVault._minimumCollateralPercentage();
        qiVault.withdrawCollateral(qiVaultId, collateralAmount);

        uint256 collateralPercent = getCollateralPercent();
        if (collateralPercent < minimumCdr && collateralPercent != 0) {
            revert LibError.InvalidCDR(collateralPercent, minimumCdr);
        }
        //2. Swap assetToken for MAI
        _swap(_getContractBalance(address(assetToken)), assetToMai);

        //3. Repay Debt to qiVault
        _repayMaiDebt();
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////      Admin functions      ///////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Delegate Qi voting power to another address
    /// @param _id   The delegate ID
    /// @param _voter Address to delegate the votes to
    function delegateVotes(bytes32 _id, address _voter) external onlyOwner {
        _delegateVotingPower(_id, _voter);
        emit VoterUpdated(_voter);
    }

    /// @notice Updates the delegation contract for Qi token Lock
    /// @param _delegationContract Updated delegation contract address
    function updateQiDelegationContract(address _delegationContract) external onlyOwner {
        if (_delegationContract == address(0)) revert LibError.InvalidAddress();
        qiDelegationContract = _delegationContract;
        emit DelegationContractUpdated(_delegationContract);
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateAssetToMai(address[] memory _swapPath) external onlyOwner {
        emit SwapPathUpdated(assetToMai, _swapPath);
        assetToMai = _swapPath;
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateMaiToAsset(address[] memory _swapPath) external onlyOwner {
        emit SwapPathUpdated(maiToAsset, _swapPath);
        maiToAsset = _swapPath;
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateQiToAsset(address[] memory _swapPath) external onlyOwner {
        emit SwapPathUpdated(qiToAsset, _swapPath);
        qiToAsset = _swapPath;
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateMaiToLp0(address[] memory _swapPath) external onlyOwner {
        emit SwapPathUpdated(maiToLp0, _swapPath);
        maiToLp0 = _swapPath;
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateMaiToLp1(address[] memory _swapPath) external onlyOwner {
        emit SwapPathUpdated(maiToLp1, _swapPath);
        maiToLp1 = _swapPath;
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateLp0ToMai(address[] memory _swapPath) external onlyOwner {
        emit SwapPathUpdated(lp0ToMai, _swapPath);
        lp0ToMai = _swapPath;
    }

    /// @notice Updates the swap path route for token swaps
    /// @param _swapPath Updated swap path
    function updateLp1ToMai(address[] memory _swapPath) external onlyOwner {
        emit SwapPathUpdated(lp1ToMai, _swapPath);
        lp1ToMai = _swapPath;
    }

    /// @notice Update Qi Rewards Pool ID for Qi MasterChef contract
    /// @param _pid Pool ID
    function updateQiRewardsPid(uint256 _pid) external onlyOwner {
        qiRewardsPid = _pid;
    }

    /// @notice Update LP factor for LP tokens calculation from assetToken
    /// @param _factor LP factor (in percent) of how much extra tokens to withdraw to account for slippage and future withdrawals
    function updateLpFactor(uint256 _factor) external onlyOwner {
        lpFactor = _factor;
    }

    /// @notice Update Safe collateral ratio percentage for SAFE_COLLAT_LOW
    /// @param _cdr Updated CDR Percent
    function updateSafeCollateralRatioLow(uint256 _cdr) external onlyOwner {
        SAFE_COLLAT_LOW = _cdr;
    }

    /// @notice Update Safe collateral ratio percentage for SAFE_COLLAT_TARGET
    /// @param _cdr Updated CDR Percent
    function updateSafeCollateralRatioTarget(uint256 _cdr) external onlyOwner {
        SAFE_COLLAT_TARGET = _cdr;
    }

    /// @notice Update Safe collateral ratio percentage for SAFE_COLLAT_HIGH
    /// @param _cdr Updated CDR Percent
    function updateSafeCollateralRatioHigh(uint256 _cdr) external onlyOwner {
        SAFE_COLLAT_HIGH = _cdr;
    }

    /// @notice Set Chainlink price feed for LP tokens
    /// @param _token Token for which price feed needs to be set
    /// @param _feed Address of Chainlink price feed
    function setPriceFeed(address _token, address _feed) external onlyOwner {
        priceFeeds[_token] = _feed;
    }

    /// @notice Repay Debt by liquidating LP tokens
    /// @param _lpAmount Amount of LP tokens to liquidate
    function repayDebtLp(uint256 _lpAmount) external onlyOwner {
        _repayDebtLp(_lpAmount);
    }

    /// @notice Repay Debt from deposited collateral tokens
    /// @param _collateralAmount Amount of collateral to repay
    function repayDebtCollateral(uint256 _collateralAmount) external onlyOwner {
        _repayDebtCollateral(_collateralAmount);
    }

    /// @notice Repay Debt by liquidating LP tokens
    function repayMaxDebtLp() external onlyOwner {
        uint256 lpbalance = getStrategyLpDeposited();
        _repayDebtLp(lpbalance);
    }

    /// @notice Repay Debt from deposited collateral tokens
    function repayMaxDebtCollateral() external onlyOwner {
        uint256 minimumCdr = qiVault._minimumCollateralPercentage() + 10;

        uint256 safeCollateralAmount = safeCollateralForDebt(getStrategyDebt(), minimumCdr);
        uint256 collateralToRepay = getStrategyCollateral() - safeCollateralAmount;
        _repayDebtCollateral(collateralToRepay);
    }

    /// @dev Rescues random funds stuck that the strat can't handle.
    /// @param _token address of the token to rescue.
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        if (_token == address(assetToken)) revert LibError.InvalidToken();
        IERC20(_token).safeTransfer(msg.sender, _getContractBalance(_token));
    }

    /// @dev Pause the contracts in case of emergency
    function pause() public onlyManager {
        _pause();
        _removeAllowances();
    }

    /// @dev Unpause the contracts
    function unpause() external onlyManager {
        _unpause();
        _giveAllowances();
    }

    function panic() public override onlyManager {
        pause();
        IQiStakingRewards(qiStakingRewards).withdraw(qiRewardsPid, balanceOfPool());
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////      External functions      /////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Returns the total supply and market of LP
    /// @dev Will work only if price oracle for either one of the lp tokens is set
    /// @return lpSupply Total supply of LP tokens
    /// @return totalMarketUSD Total market in USD of LP tokens
    function getLPTotalMarketUSD() public view returns (uint256 lpSupply, uint256 totalMarketUSD) {
        (lpSupply, totalMarketUSD) = _getLPTotalMarketUSD();
    }

    /// @notice Returns the assetToken Price from QiVault Contract Oracle
    /// @return assetTokenPrice Asset Token Price in USD
    function getAssetTokenPrice() public view returns (uint256 assetTokenPrice) {
        assetTokenPrice = qiVault.getEthPriceSource(); // Asset token price
        if (assetTokenPrice == 0) revert LibError.PriceFeedError();
    }

    /// @notice Returns the assetToken Price from QiVault Contract Oracle
    /// @return maiTokenPrice MAI Token Price in USD
    function getMaiTokenPrice() public view returns (uint256 maiTokenPrice) {
        maiTokenPrice = qiVault.getTokenPriceSource();
        if (maiTokenPrice == 0) revert LibError.PriceFeedError();
    }

    /// @notice Returns the Collateral Percentage of Strategy from QiVault
    /// @return cdr_percent Collateral Percentage
    function getCollateralPercent() public view returns (uint256 cdr_percent) {
        cdr_percent = qiVault.checkCollateralPercentage(qiVaultId);
    }

    /// @notice Returns the Debt of strategy from QiVault
    /// @return maiDebt MAI Debt of strategy
    function getStrategyDebt() public view returns (uint256 maiDebt) {
        maiDebt = qiVault.vaultDebt(qiVaultId);
    }

    /// @notice Returns the total collateral of strategy from QiVault
    /// @return collateral Collateral deposited by strategy into QiVault
    function getStrategyCollateral() public view returns (uint256 collateral) {
        collateral = qiVault.vaultCollateral(qiVaultId);
    }

    /// @notice Returns the total LP deposited balance of strategy from Qifarm
    /// @return lpBalance LP deposited by strategy into Qifarm
    function getStrategyLpDeposited() public view returns (uint256 lpBalance) {
        lpBalance = IQiStakingRewards(qiStakingRewards).deposited(qiRewardsPid, address(this));
    }

    /// @notice Returns the maximum amount of asset tokens that can be deposited
    /// @return depositLimit Maximum amount of asset tokens that can be deposited to strategy
    function getMaximumDepositLimit() public view returns (uint256 depositLimit) {
        uint256 maiAvailable = qiVault.getDebtCeiling();
        depositLimit = (maiAvailable * SAFE_COLLAT_TARGET * 10**8) / (getAssetTokenPrice() * 100);
    }

    /// @notice Returns the safe amount to borrow from qiVault considering Debt and Collateral
    /// @return amountToBorrow Safe amount of MAI to borrow from vault
    function safeAmountToBorrow() public view returns (uint256 amountToBorrow) {
        uint256 safeDebt = safeDebtForCollateral(getStrategyCollateral(), SAFE_COLLAT_TARGET);
        uint256 currentDebt = getStrategyDebt();
        if (safeDebt > currentDebt) {
            amountToBorrow = safeDebt - currentDebt;
        } else {
            amountToBorrow = 0;
        }
    }

    /// @notice Returns the safe amount to withdraw from qiVault considering Debt and Collateral
    /// @return amountToWithdraw Safe amount of assetTokens to withdraw from vault
    function safeAmountToWithdraw() public view returns (uint256 amountToWithdraw) {
        uint256 safeCollateral = safeCollateralForDebt(getStrategyDebt(), (SAFE_COLLAT_LOW + 1));
        uint256 currentCollateral = getStrategyCollateral();
        if (currentCollateral > safeCollateral) {
            amountToWithdraw = currentCollateral - safeCollateral;
        } else {
            amountToWithdraw = 0;
        }
    }

    /// @notice Returns the safe Debt for collateral(passed as argument) from qiVault
    /// @param collateral Amount of collateral tokens for which safe Debt is to be calculated
    /// @return safeDebt Safe amount of MAI than can be borrowed from qiVault
    function safeDebtForCollateral(uint256 collateral, uint256 collateralPercent) public view returns (uint256 safeDebt) {
        uint256 safeDebtValue = (collateral * getAssetTokenPrice() * 100) / collateralPercent;
        safeDebt = safeDebtValue / getMaiTokenPrice();
    }

    /// @notice Returns the safe collateral for debt(passed as argument) from qiVault
    /// @param debt Amount of MAI tokens for which safe collateral is to be calculated
    /// @return safeCollateral Safe amount of collateral tokens for qiVault
    function safeCollateralForDebt(uint256 debt, uint256 collateralPercent) public view returns (uint256 safeCollateral) {
        uint256 collateralValue = (collateralPercent * debt * getMaiTokenPrice()) / 100;
        safeCollateral = collateralValue / getAssetTokenPrice();
    }

    /// @notice Deposits the asset token to QiVault from balance of this contract
    /// @dev Asset tokens must be transferred to the contract first before calling this function
    function deposit() public override whenNotPaused onlyVault {
        _depositToQiVault(_getContractBalance(address(assetToken)));

        //Check CDR ratio, if below 220% don't borrow, else borrow
        uint256 cdr_percent = getCollateralPercent();

        if (cdr_percent > SAFE_COLLAT_HIGH) {
            _borrowTokens();
            _swapMaiAndAddLiquidity();
            _depositLPToFarm(_getContractBalance(lpPairToken));
        } else if (cdr_percent == 0 && getStrategyCollateral() != 0) {
            // Note: Special case for initial deposit(as CDR is returned 0 when Debt is 0)
            // Borrow 1 wei to initialize
            qiVault.borrowToken(qiVaultId, 1);
        }
    }

    /// @notice Withdraw deposited tokens from the Vault
    function withdraw(uint256 withdrawAmount) public override whenNotPaused onlyVault {
        _withdrawFromVault(withdrawAmount);
    }

    /// @notice Rebalances the vault to a safe Collateral to Debt ratio
    /// @dev If Collateral to Debt ratio is below SAFE_COLLAT_LOW,
    /// then -> Withdraw lpAmount from Farm > Remove liquidity from LP > swap Qi for WMATIC > Deposit WMATIC to vault
    // If CDR is greater than SAFE_COLLAT_HIGH,
    /// then -> Borrow more MAI > Swap for Qi and WMATIC > Deposit to Quickswap LP > Deposit to Qi Farm
    function rebalanceVault(bool repayFromLp) public whenNotPaused {
        uint256 cdr_percent = getCollateralPercent();

        if (cdr_percent < SAFE_COLLAT_TARGET) {
            // Get amount of LP tokens to sell for asset tokens
            uint256 safeDebt = safeDebtForCollateral(getStrategyCollateral(), SAFE_COLLAT_TARGET);
            uint256 debtToRepay = getStrategyDebt() - safeDebt;

            if (repayFromLp) {
                uint256 lpAmount = _getLPTokensFromMai(debtToRepay);
                _repayDebtLp(lpAmount);
            } else {
                // Repay from collateral
                uint256 requiredCollateralValue = ((SAFE_COLLAT_TARGET + 10) * debtToRepay * getMaiTokenPrice()) / 100;
                uint256 collateralToRepay = requiredCollateralValue / getAssetTokenPrice();

                uint256 stratCollateral = getStrategyCollateral();
                uint256 minimumCdr = qiVault._minimumCollateralPercentage() + 5;
                uint256 stratDebt = getStrategyDebt();
                uint256 minCollateralForDebt = safeCollateralForDebt(stratDebt, minimumCdr);
                uint256 maxWithdrawAmount;
                if (stratCollateral > minCollateralForDebt) {
                    maxWithdrawAmount = stratCollateral - minCollateralForDebt;
                } else {
                    revert LibError.InvalidAmount(1, 1);
                }
                if (collateralToRepay > maxWithdrawAmount) {
                    collateralToRepay = maxWithdrawAmount;
                }
                _repayDebtCollateral(collateralToRepay);
            }
            //4. Check updated CDR and verify
            uint256 updated_cdr = getCollateralPercent();
            if (updated_cdr < SAFE_COLLAT_TARGET && updated_cdr != 0)
                revert LibError.InvalidCDR(updated_cdr, SAFE_COLLAT_TARGET);
        } else if (cdr_percent > SAFE_COLLAT_HIGH) {
            //1. Borrow tokens
            _borrowTokens();

            //2. Swap and add liquidity
            _swapMaiAndAddLiquidity();

            //3. Deposit LP to farm
            _depositLPToFarm(_getContractBalance(lpPairToken));
        } else {
            revert LibError.InvalidCDR(0, 0);
        }
        emit VaultRebalanced();
    }

    /// @notice Repay MAI debt back to the qiVault
    /// @dev The sender must have sufficient allowance and balance
    function repayDebt(uint256 amount) public {
        mai.safeTransferFrom(msg.sender, address(this), amount);
        _repayMaiDebt();
    }

    /// @notice calculate the total underlying 'want' held by the strat
    /// @dev This is equivalent to the amount of assetTokens deposited in the QiDAO vault
    function balanceOfStrategy() public view override returns (uint256 strategyBalance) {
        return balanceOfWant() + balanceOfPool();
    }

    /// @notice calculate the total underlying 'want' held by the strat
    /// @dev This is equivalent to the amount of assetTokens deposited in the QiDAO vault
    function balanceOf() public view override returns (uint256 strategyBalance) {
        return balanceOfWant() + balanceOfPool();
    }

    function balanceOfPool() public view override returns (uint256 poolBalance) {
        uint256 assetBalance = getStrategyCollateral();

        // For Debt, also factor in 0.5% repayment fee
        // This fee is charged by QiDao only on the Debt (amount of MAI borrowed)
        uint256 maiDebt = (getStrategyDebt() * (10000 + 50)) / 10000;
        uint256 lpBalance = getStrategyLpDeposited();

        IUniswapV2ERC20 pair = IUniswapV2ERC20(lpPairToken);
        uint256 lpTotalSupply = pair.totalSupply();
        (uint112 _reserve0, uint112 _reserve1, ) = pair.getReserves();

        uint256 balance0 = (lpBalance * _reserve0) / lpTotalSupply;
        uint256 balance1 = (lpBalance * _reserve1) / lpTotalSupply;

        uint256 maiBal0;
        if (balance0 > 0) {
            try IUniswapV2Router(unirouter).getAmountsOut(balance0, lp0ToMai) returns (uint256[] memory amountOut0) {
                maiBal0 = amountOut0[amountOut0.length - 1];
            } catch {}
        }

        uint256 maiBal1;
        if (balance1 > 0) {
            try IUniswapV2Router(unirouter).getAmountsOut(balance1, lp1ToMai) returns (uint256[] memory amountOut1) {
                maiBal1 = amountOut1[amountOut1.length - 1];
            } catch {}
        }
        uint256 totalMaiReceived = maiBal0 + maiBal1;

        if (maiDebt > totalMaiReceived) {
            uint256 diffAsset = ((maiDebt - totalMaiReceived) * 10**8) / getAssetTokenPrice();
            poolBalance = assetBalance - diffAsset;
        } else {
            uint256 diffAsset = ((totalMaiReceived - maiDebt) * 10**8) / getAssetTokenPrice();
            poolBalance = assetBalance + diffAsset;
        }
    }

    function balanceOfWant() public view override returns (uint256 poolBalance) {
        return _getContractBalance(address(assetToken));
    }

    /// @notice called as part of strat migration. Sends all the available funds back to the vault.
    /// NOTE: All QiVault debt must be paid before this function is called
    function retireStrat() external override onlyVault {
        require(getStrategyDebt() == 0, "Debt");

        // Withdraw asset token balance from vault and strategy
        qiVault.withdrawCollateral(qiVaultId, getStrategyCollateral());
        assetToken.safeTransfer(vault, _getContractBalance(address(assetToken)));

        // Withdraw LP balance from staking rewards
        uint256 lpBalance = getStrategyLpDeposited();
        if (lpBalance > 0) {
            IQiStakingRewards(qiStakingRewards).withdraw(qiRewardsPid, lpBalance);
            IERC20(lpPairToken).safeTransfer(vault, lpBalance);
        }
        emit StrategyRetired(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../../interfaces/IUniswapV2Router.sol";
import "../../../../interfaces/IUniswapV2ERC20.sol";
import "../../../../interfaces/IQiStakingRewards.sol";
import "../../CompoundStrat.sol";
import "../../CompoundFeeManager.sol";

contract StrategyCommonChefLP is CompoundFeeManager, CompoundStrat {
    using SafeERC20 for IERC20;

    // Tokens used
    address public lpToken0;
    address public lpToken1;

    // Third party contracts
    address public chef;
    uint256 public poolId;

    string public pendingRewardsFunctionName;

    // Routes
    address[] public outputToNativeRoute;
    address[] public outputToLp0Route;
    address[] public outputToLp1Route;

    event StratHarvest(address indexed harvester, uint256 wantHarvested, uint256 tvl);
    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);
    event ChargedFees(uint256 callFees, uint256 beefyFees, uint256 strategistFees);

    constructor(
        address _want,
        uint256 _poolId,
        address _chef,
        address _unirouter,
        address _keeper,
        address _strategist,
        address _ethaFeeRecipient,
        address[] memory _outputToNativeRoute,
        address[] memory _outputToLp0Route,
        address[] memory _outputToLp1Route
    ) CompoundStratManager(_keeper, _strategist, _unirouter, _ethaFeeRecipient) {
        want = _want;
        poolId = _poolId;
        chef = _chef;

        output = _outputToNativeRoute[0];
        native = _outputToNativeRoute[_outputToNativeRoute.length - 1];
        outputToNativeRoute = _outputToNativeRoute;

        // setup lp routing
        lpToken0 = IUniswapV2ERC20(want).token0();
        require(_outputToLp0Route[0] == output, "outputToLp0Route[0] != output");
        require(_outputToLp0Route[_outputToLp0Route.length - 1] == lpToken0, "outputToLp0Route[last] != lpToken0");
        outputToLp0Route = _outputToLp0Route;

        lpToken1 = IUniswapV2ERC20(want).token1();
        require(_outputToLp1Route[0] == output, "outputToLp1Route[0] != output");
        require(_outputToLp1Route[_outputToLp1Route.length - 1] == lpToken1, "outputToLp1Route[last] != lpToken1");
        outputToLp1Route = _outputToLp1Route;

        _giveAllowances();
    }

    // puts the funds to work
    function deposit() public override whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal > 0) {
            IQiStakingRewards(chef).deposit(poolId, wantBal);
            emit Deposit(balanceOf());
        }
    }

    function withdraw(uint256 _amount) external override {
        require(msg.sender == vault, "!vault");

        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal < _amount) {
            IQiStakingRewards(chef).withdraw(poolId, _amount - wantBal);
            wantBal = IERC20(want).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        IERC20(want).safeTransfer(vault, wantBal);

        emit Withdraw(balanceOf());
    }

    function beforeDeposit() external override {
        if (harvestOnDeposit) {
            require(msg.sender == vault, "!vault");
            _harvest(tx.origin);
        }
    }

    // compounds earnings and charges performance fee
    function _harvest(address callFeeRecipient) internal override whenNotPaused {
        IQiStakingRewards(chef).deposit(poolId, 0);
        uint256 outputBal = IERC20(output).balanceOf(address(this));
        if (outputBal > 0) {
            chargeFees(callFeeRecipient);
            addLiquidity();
            uint256 wantHarvested = balanceOfWant();
            deposit();

            lastHarvest = block.timestamp;
            emit StratHarvest(msg.sender, wantHarvested, balanceOf());
        }
    }

    // performance fees
    function chargeFees(address callFeeRecipient) internal {
        uint256 toNative = (IERC20(output).balanceOf(address(this)) * profitFee) / MAX_FEE;

        if (toNative > 0)
            IUniswapV2Router(unirouter).swapExactTokensForTokens(
                toNative,
                0,
                outputToNativeRoute,
                address(this),
                block.timestamp
            );
        else return;

        uint256 nativeFeeBal = IERC20(native).balanceOf(address(this));

        _deductFees(native, callFeeRecipient, nativeFeeBal);
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 outputHalf = IERC20(output).balanceOf(address(this)) / 2;
        if (lpToken0 != output) {
            IUniswapV2Router(unirouter).swapExactTokensForTokens(
                outputHalf,
                0,
                outputToLp0Route,
                address(this),
                block.timestamp
            );
        }

        if (lpToken1 != output) {
            IUniswapV2Router(unirouter).swapExactTokensForTokens(
                outputHalf,
                0,
                outputToLp1Route,
                address(this),
                block.timestamp
            );
        }

        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
        IUniswapV2Router(unirouter).addLiquidity(lpToken0, lpToken1, lp0Bal, lp1Bal, 1, 1, address(this), block.timestamp);
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() public view override returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOfStrategy() public view override returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view override returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view override returns (uint256) {
        (uint256 _amount, ) = IQiStakingRewards(chef).userInfo(poolId, address(this));
        return _amount;
    }

    function setPendingRewardsFunctionName(string calldata _pendingRewardsFunctionName) external onlyManager {
        pendingRewardsFunctionName = _pendingRewardsFunctionName;
    }

    // returns rewards unharvested
    function rewardsAvailable() public view returns (uint256) {
        return IQiStakingRewards(chef).pending(poolId, address(this));
    }

    // returns native reward for calling harvest
    function callReward() public view returns (uint256) {
        if (callFee == 0) return 0;

        uint256 outputBal = rewardsAvailable();
        uint256 nativeOut;
        if (outputBal > 0) {
            try IUniswapV2Router(unirouter).getAmountsOut(outputBal, outputToNativeRoute) returns (
                uint256[] memory amountOut
            ) {
                nativeOut = amountOut[amountOut.length - 1];
            } catch {}
        }

        return (nativeOut * profitFee * callFee) / (MAX_FEE * MAX_FEE);
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external override onlyVault {
        // Claim rewards and compound
        _harvest(ethaFeeRecipient);

        // Withdraw all funds from gauge
        IQiStakingRewards(chef).withdraw(poolId, balanceOfPool());

        uint256 wantBal = balanceOfWant();
        IERC20(want).safeTransfer(vault, wantBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public override onlyManager {
        pause();
        IQiStakingRewards(chef).withdraw(poolId, balanceOfPool());
    }

    function pause() public onlyManager {
        _pause();

        _removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function _giveAllowances() internal {
        IERC20(want).safeApprove(chef, type(uint).max);
        IERC20(output).safeApprove(unirouter, type(uint).max);

        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, type(uint).max);

        IERC20(lpToken1).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, type(uint).max);
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(chef, 0);
        IERC20(output).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, 0);
    }

    function outputToNative() external view returns (address[] memory) {
        return outputToNativeRoute;
    }

    function outputToLp0() external view returns (address[] memory) {
        return outputToLp0Route;
    }

    function outputToLp1() external view returns (address[] memory) {
        return outputToLp1Route;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IVault.sol";
import "../../interfaces/IUniswapV2Router.sol";
import "../../interfaces/IStrat.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Harvester is Ownable {
    using SafeERC20 for IERC20;

    event Harvested(address indexed vault, address indexed sender);

    uint256 public delay;

    constructor(uint256 _delay) {
        delay = _delay;
    }

    modifier onlyAfterDelay(IVault vault) {
        require(block.timestamp >= vault.lastDistribution() + delay, "Not ready to harvest");
        _;
    }

    /**
		@notice Harvest vault using quickswap router
		@dev any user can harvest after delay has passed
	*/
    function harvestVault(IVault vault) public onlyAfterDelay(vault) {
        // Amount to Harvest
        uint256 afterFee = vault.harvest();
        require(afterFee > 0, "!Yield");

        IERC20 from = vault.rewards();
        IERC20 to = vault.target();
        address strat = vault.strat();
        address router = IStrat(strat).router();

        // Router path
        address[] memory path = IStrat(strat).outputToTarget();
        require(path[0] == address(from));
        require(path[path.length - 1] == address(to));

        // Swap underlying to target
        from.safeApprove(router, 0);
        from.safeApprove(router, afterFee);
        uint256 received = IUniswapV2Router(router).swapExactTokensForTokens(
            afterFee,
            1,
            path,
            address(this),
            block.timestamp + 1
        )[path.length - 1];

        // Send profits to vault
        to.approve(address(vault), received);
        vault.distribute(received);

        emit Harvested(address(vault), msg.sender);
    }

    /**
		@dev update delay required to harvest vault
	*/
    function setDelay(uint256 _delay) external onlyOwner {
        delay = _delay;
    }

    // no tokens should ever be stored on this contract. Any tokens that are sent here by mistake are recoverable by the owner
    function sweep(address _token) external onlyOwner {
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IStrategy.sol";

interface IVaultV2 is IERC20 {
	function deposit(uint256) external;

	function depositAll() external;

	function withdraw(uint256) external;

	function withdrawAll() external;

	function getPricePerFullShare() external view returns (uint256);

	function upgradeStrat() external;

	function balance() external view returns (uint256);

	function want() external view returns (IERC20);

	function strategy() external view returns (IStrategy);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Rebase {
    uint128 elastic;
    uint128 base;
}

interface IFlashBorrower {
    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

interface IBatchFlashBorrower {
    function onBatchFlashLoan(
        address sender,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        bytes calldata data
    ) external;
}

interface IStrategyBento {
    // Send the assets to the Strategy and call skim to invest them
    function skim(uint256 amount) external;

    // Harvest any profits made converted to the asset and pass them to the caller
    function harvest(uint256 balance, address sender) external returns (int256 amountAdded);

    // Withdraw assets. The returned amount can differ from the requested amount due to rounding.
    // The actualAmount should be very close to the amount. The difference should NOT be used to report a loss. That's what harvest is for.
    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    // Withdraw all assets in the safest way possible. This shouldn't fail.
    function exit(uint256 balance) external returns (int256 amountAdded);
}

interface IBentoBoxV1 {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);
    event LogDeposit(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 share);
    event LogFlashLoan(
        address indexed borrower,
        address indexed token,
        uint256 amount,
        uint256 feeAmount,
        address indexed receiver
    );
    event LogRegisterProtocol(address indexed protocol);
    event LogSetMasterContractApproval(address indexed masterContract, address indexed user, bool approved);
    event LogStrategyDivest(address indexed token, uint256 amount);
    event LogStrategyInvest(address indexed token, uint256 amount);
    event LogStrategyLoss(address indexed token, uint256 amount);
    event LogStrategyProfit(address indexed token, uint256 amount);
    event LogStrategyQueued(address indexed token, address indexed strategy);
    event LogStrategySet(address indexed token, address indexed strategy);
    event LogStrategyTargetPercentage(address indexed token, uint256 targetPercentage);
    event LogTransfer(address indexed token, address indexed from, address indexed to, uint256 share);
    event LogWhiteListMasterContract(address indexed masterContract, bool approved);
    event LogWithdraw(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 share);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function balanceOf(IERC20, address) external view returns (uint256);

    function batch(bytes[] calldata calls, bool revertOnFail)
        external
        payable
        returns (bool[] memory successes, bytes[] memory results);

    function batchFlashLoan(
        IBatchFlashBorrower borrower,
        address[] calldata receivers,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function claimOwnership() external;

    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) external payable;

    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function flashLoan(
        IFlashBorrower borrower,
        address receiver,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) external;

    function harvest(
        IERC20 token,
        bool balance,
        uint256 maxChangeAmount
    ) external;

    function masterContractApproved(address, address) external view returns (bool);

    function masterContractOf(address) external view returns (address);

    function nonces(address) external view returns (uint256);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function pendingStrategy(IERC20) external view returns (IStrategyBento);

    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function registerProtocol() external;

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function setStrategy(IERC20 token, IStrategyBento newStrategy) external;

    function setStrategyTargetPercentage(IERC20 token, uint64 targetPercentage_) external;

    function strategy(IERC20) external view returns (IStrategyBento);

    function strategyData(IERC20)
        external
        view
        returns (
            uint64 strategyStartDate,
            uint64 targetPercentage,
            uint128 balance
        );

    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function totals(IERC20) external view returns (Rebase memory totals_);

    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) external;

    function transferMultiple(
        IERC20 token,
        address from,
        address[] calldata tos,
        uint256[] calldata shares
    ) external;

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function whitelistMasterContract(address masterContract, bool approved) external;

    function whitelistedMasterContracts(address) external view returns (bool);

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IBentoBoxV1.sol";

interface IOracle {
	/// @notice Get the latest exchange rate.
	/// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
	/// For example:
	/// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
	/// @return success if no valid (recent) rate is available, return false else true.
	/// @return rate The rate of the requested asset / pair / pool.
	function get(bytes calldata data)
		external
		returns (bool success, uint256 rate);

	/// @notice Check the last exchange rate without any state changes.
	/// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
	/// For example:
	/// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
	/// @return success if no valid (recent) rate is available, return false else true.
	/// @return rate The rate of the requested asset / pair / pool.
	function peek(bytes calldata data)
		external
		view
		returns (bool success, uint256 rate);

	/// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
	/// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
	/// For example:
	/// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
	/// @return rate The rate of the requested asset / pair / pool.
	function peekSpot(bytes calldata data) external view returns (uint256 rate);

	/// @notice Returns a human readable (short) name about this oracle.
	/// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
	/// For example:
	/// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
	/// @return (string) A human readable symbol name about this oracle.
	function symbol(bytes calldata data) external view returns (string memory);

	/// @notice Returns a human readable name about this oracle.
	/// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
	/// For example:
	/// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
	/// @return (string) A human readable name about this oracle.
	function name(bytes calldata data) external view returns (string memory);
}

interface ISwapper {
	/// @notice Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
	/// Swaps it for at least 'amountToMin' of token 'to'.
	/// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
	/// Returns the amount of tokens 'to' transferred to BentoBox.
	/// (The BentoBox skim function will be used by the caller to get the swapped funds).
	function swap(
		IERC20 fromToken,
		IERC20 toToken,
		address recipient,
		uint256 shareToMin,
		uint256 shareFrom
	) external returns (uint256 extraShare, uint256 shareReturned);

	/// @notice Calculates the amount of token 'from' needed to complete the swap (amountFrom),
	/// this should be less than or equal to amountFromMax.
	/// Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
	/// Swaps it for exactly 'exactAmountTo' of token 'to'.
	/// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
	/// Transfers allocated, but unused 'from' tokens within the BentoBox to 'refundTo' (amountFromMax - amountFrom).
	/// Returns the amount of 'from' tokens withdrawn from BentoBox (amountFrom).
	/// (The BentoBox skim function will be used by the caller to get the swapped funds).
	function swapExact(
		IERC20 fromToken,
		IERC20 toToken,
		address recipient,
		address refundTo,
		uint256 shareFromSupplied,
		uint256 shareToExact
	) external returns (uint256 shareUsed, uint256 shareReturned);
}

interface IKashiPair {
	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint256 _value
	);
	event LogAccrue(
		uint256 accruedAmount,
		uint256 feeFraction,
		uint64 rate,
		uint256 utilization
	);
	event LogAddAsset(
		address indexed from,
		address indexed to,
		uint256 share,
		uint256 fraction
	);
	event LogAddCollateral(
		address indexed from,
		address indexed to,
		uint256 share
	);
	event LogBorrow(
		address indexed from,
		address indexed to,
		uint256 amount,
		uint256 part
	);
	event LogExchangeRate(uint256 rate);
	event LogFeeTo(address indexed newFeeTo);
	event LogRemoveAsset(
		address indexed from,
		address indexed to,
		uint256 share,
		uint256 fraction
	);
	event LogRemoveCollateral(
		address indexed from,
		address indexed to,
		uint256 share
	);
	event LogRepay(
		address indexed from,
		address indexed to,
		uint256 amount,
		uint256 part
	);
	event LogWithdrawFees(address indexed feeTo, uint256 feesEarnedFraction);
	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);
	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	function DOMAIN_SEPARATOR() external view returns (bytes32);

	function accrue() external;

	function accrueInfo()
		external
		view
		returns (
			uint64 interestPerSecond,
			uint64 lastBlockAccrued,
			uint128 feesEarnedFraction
		);

	function addAsset(
		address to,
		bool skim,
		uint256 share
	) external returns (uint256 fraction);

	function addCollateral(
		address to,
		bool skim,
		uint256 share
	) external;

	function allowance(address, address) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function asset() external view returns (IERC20);

	function balanceOf(address) external view returns (uint256);

	function bentoBox() external view returns (IBentoBoxV1);

	function borrow(address to, uint256 amount)
		external
		returns (uint256 part, uint256 share);

	function claimOwnership() external;

	function collateral() external view returns (IERC20);

	function cook(
		uint8[] calldata actions,
		uint256[] calldata values,
		bytes[] calldata datas
	) external payable returns (uint256 value1, uint256 value2);

	function decimals() external view returns (uint8);

	function exchangeRate() external view returns (uint256);

	function feeTo() external view returns (address);

	function getInitData(
		IERC20 collateral_,
		IERC20 asset_,
		IOracle oracle_,
		bytes calldata oracleData_
	) external pure returns (bytes memory data);

	function init(bytes calldata data) external payable;

	function isSolvent(address user, bool open) external view returns (bool);

	function liquidate(
		address[] calldata users,
		uint256[] calldata borrowParts,
		address to,
		ISwapper swapper,
		bool open
	) external;

	function masterContract() external view returns (address);

	function name() external view returns (string memory);

	function nonces(address) external view returns (uint256);

	function oracle() external view returns (IOracle);

	function oracleData() external view returns (bytes memory);

	function owner() external view returns (address);

	function pendingOwner() external view returns (address);

	function permit(
		address owner_,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	function removeAsset(address to, uint256 fraction)
		external
		returns (uint256 share);

	function removeCollateral(address to, uint256 share) external;

	function repay(
		address to,
		bool skim,
		uint256 part
	) external returns (uint256 amount);

	function setFeeTo(address newFeeTo) external;

	function setSwapper(ISwapper swapper, bool enable) external;

	function swappers(ISwapper) external view returns (bool);

	function symbol() external view returns (string memory);

	function totalAsset() external view returns (uint128 elastic, uint128 base);

	function totalBorrow()
		external
		view
		returns (uint128 elastic, uint128 base);

	function totalCollateralShare() external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function transfer(address to, uint256 amount) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 amount
	) external returns (bool);

	function transferOwnership(
		address newOwner,
		bool direct,
		bool renounce
	) external;

	function updateExchangeRate() external returns (bool updated, uint256 rate);

	function userBorrowPart(address) external view returns (uint256);

	function userCollateralShare(address) external view returns (uint256);

	function withdrawFees() external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @title Registry related helper functions
 */
contract RegistryHelper is AccessControlEnumerable {
    /**
     * @dev address registry of system, stores logic and wallet addresses
     */
    address public registry;

    /**
     * @dev Throws if the logic is not authorised
     */
    modifier logicAuth(address logicAddr) {
        require(logicAddr != address(0), "logic-proxy-address-required");
        require(IRegistry(registry).logic(logicAddr), "logic-not-authorised");
        _;
    }
}

/**
 * @title User Auth
 */
contract UserAuth is RegistryHelper {
    bytes32 public constant DELEGATE_ROLE = keccak256("DELEGATE_ROLE");

    /**
     * @dev store user's transaction count
     */
    uint256 public nonce;

    /**
     * @dev emit events when delegates added/removed
     */
    event DelegateAdded(address delegate);
    event DelegateRemoved(address delegate);

    /**
     * @dev Checks if called by delegate, owner or contract itself
     */
    modifier auth() {
        require(hasRole(DELEGATE_ROLE, msg.sender) || msg.sender == address(this), "permission-denied");
        _;
    }

    /**
     * @dev Checks if called by delegate, owner or contract itself
     */
    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "!owner");
        _;
    }

    /**
     * @dev Adds a new address that can control the smart wallet
     */
    function addDelegate(address _delegate) external onlyOwner {
        require(_delegate != address(0x0), "ZERO-ADDRESS");
        grantRole(DELEGATE_ROLE, _delegate);

        emit DelegateAdded(_delegate);
    }

    /**
     * @dev Remove an existing address that can control the smart wallet
     */
    function removeDelegate(address _delegate) external onlyOwner {
        require(hasRole(DELEGATE_ROLE, _delegate), "NOT_DELEGATE");
        revokeRole(DELEGATE_ROLE, _delegate);

        emit DelegateRemoved(_delegate);
    }
}

/**
 * @title User Owned Contract Wallet
 */
contract SmartWallet is UserAuth {
    using SafeMath for uint256;

    /**
     * @dev sets the "address registry", owner's last activity, owner's active period and initial owner
     */
    function initialize(address _registry, address _user) external {
        require(registry == address(0), "ALREADY INITIALIZED");
        require(_user != address(0), "ZERO ADDRESS");

        _setupRole(DEFAULT_ADMIN_ROLE, _user);
        _setupRole(DELEGATE_ROLE, _user);
        registry = _registry;
    }

    /**
        @dev internal function in charge of executing an action
        @dev checks with registry if the target address is allowed to be called
     */
    function _execute(address _target, bytes memory _data) internal logicAuth(_target) {
        require(_target != address(0), "target-invalid");
        assembly {
            let succeeded := delegatecall(gas(), _target, add(_data, 0x20), mload(_data), 0, 0)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                let size := returndatasize()
                returndatacopy(0x00, 0x00, size)
                revert(0x00, size)
            }
        }
    }

    /**
        @notice main function of the wallet
        @dev executes multiple delegate calls using the internal _execute fx
        @param targets address array of the logic contracts to use
        @param datas bytes array of the encoded function calls
     */
    function execute(address[] calldata targets, bytes[] calldata datas) external payable auth {
        for (uint256 i = 0; i < targets.length; i++) {
            _execute(targets[i], datas[i]);
        }
    }

    function getHash(bytes memory data) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), nonce, data));
    }

    function executeMetaTransaction(bytes memory sign, bytes memory data) external {
        bytes32 _hash = getHash(data);
        require(hasRole(DELEGATE_ROLE, address(recover(_hash, sign))), "Invalid Signer");
        address target = address(this);

        (bool success, ) = target.call(data);
        require(success);

        nonce = nonce.add(1);
    }

    function recover(bytes32 hash, bytes memory signature) public pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /// @dev accept ERC721 token transfers
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    /// @dev accept ERC1155 token transfers
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    /// @dev accept ERC1155 token batch transfers
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    /// @dev accept ETH deposits
    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./wallet/SmartWallet.sol";
import "./utils/CloneFactory.sol";

/**
 * @title Logic Registry
 */
contract LogicRegistry is OwnableUpgradeable {
    using SafeMath for uint256;

    /// @dev address timelock contract
    address public timelock;

    /// EVENTS
    event LogEnableLogic(address indexed logicAddress);
    event LogDisableLogic(address indexed logicAddress);

    /// @notice Map of logic proxy state
    mapping(address => bool) public logicProxies;

    /// @dev
    /// @param _logicAddress (address)
    /// @return  (bool)
    function logic(address _logicAddress) external view returns (bool) {
        return logicProxies[_logicAddress];
    }

    /// @dev Enable logic proxy address
    /// @param _logicAddress (address)
    function enableLogic(address _logicAddress) public onlyOwner {
        require(_logicAddress != address(0), "ZERO ADDRESS");
        logicProxies[_logicAddress] = true;
        emit LogEnableLogic(_logicAddress);
    }

    /// @dev Enable multiple logic proxy addresses
    /// @param _logicAddresses (addresses)
    function enableLogicMultiple(address[] calldata _logicAddresses) external {
        for (uint256 i = 0; i < _logicAddresses.length; i++) {
            enableLogic(_logicAddresses[i]);
        }
    }

    /// @dev Disable logic proxy address
    /// @param _logicAddress (address)
    function disableLogic(address _logicAddress) public onlyOwner {
        require(_logicAddress != address(0), "ZERO ADDRESS");
        logicProxies[_logicAddress] = false;
        emit LogDisableLogic(_logicAddress);
    }

    /// @dev Disable multiple logic proxy addresses
    /// @param _logicAddresses (addresses)
    function disableLogicMultiple(address[] calldata _logicAddresses) external {
        for (uint256 i = 0; i < _logicAddresses.length; i++) {
            disableLogic(_logicAddresses[i]);
        }
    }
}

/**
 * @dev Deploys a new proxy instance and sets msg.sender as owner of proxy
 */
contract WalletRegistry is LogicRegistry, CloneFactory {
    event Created(address indexed owner, address proxy);
    event LogRecord(address indexed currentOwner, address indexed nextOwner, address proxy);

    /// @dev implementation address of Smart Wallet
    address public implementation;

    /// @notice Address to UserWallet proxy map
    mapping(address => SmartWallet) public wallets;

    /// @notice Address to Bool registration status map
    mapping(address => bool) public walletRegistered;

    /// @dev Deploys a new proxy instance and sets custom owner of proxy
    /// Throws if the owner already have a UserWallet
    /// @return wallet - address of new Smart Wallet
    function deployWallet() external returns (SmartWallet wallet) {
        require(wallets[msg.sender] == SmartWallet(payable(0)), "multiple-proxy-per-user-not-allowed");
        address payable _wallet = payable((createClone(implementation)));
        wallet = SmartWallet(_wallet);
        wallet.initialize(address(this), msg.sender);
        wallets[msg.sender] = wallet; // will be changed via record() in next line execution
        walletRegistered[address(_wallet)] = true;
        emit Created(msg.sender, address(wallet));
    }

    /// @dev Change the address implementation of the Smart Wallet
    /// @param _impl new implementation address of Smart Wallet
    function setImplementation(address _impl) external onlyOwner {
        implementation = _impl;
    }
}

/// @title ETHA Registry
contract EthaRegistry is WalletRegistry {
    /// @dev address of recipient receiving the protocol fees
    address public feeRecipient;

    /// @dev stores values shared accross logic contracts
    address public memoryAddr;

    /// @dev fee percentage charged when swapping (1% = 1000)
    uint256 fee;

    /// @dev keep track of token addresses not allowed to withdraw (i.e. cETH)
    mapping(address => bool) public notAllowed;

    /// @dev keep track of lending distribution contract per token
    mapping(address => address) public distributionContract;

    // EVENTS
    event FeeUpdated(uint256 newFee);
    event FeeRecipientUpdated(address newRecipient);
    event FeeManagerUpdated(address newFeeManager);

    /// @dev address of feeManager contract
    address feeManager;

    function initialize(
        address _impl,
        address _feeRecipient,
        address _memoryAddr,
        address[] memory _initialLogics,
        uint256 _fee
    ) external initializer {
        require(_feeRecipient != address(0), "ZERO ADDRESS");
        __Ownable_init();

        // Enable Logics for the first time
        for (uint256 i = 0; i < _initialLogics.length; i++) {
            require(_initialLogics[i] != address(0), "ZERO ADDRESS");
            logicProxies[_initialLogics[i]] = true;
        }

        implementation = _impl;
        fee = _fee;
        feeRecipient = _feeRecipient;
        memoryAddr = _memoryAddr;
    }

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
        emit FeeUpdated(_fee);
    }

    function setMemory(address _memoryAddr) public onlyOwner {
        memoryAddr = _memoryAddr;
    }

    function getFee() external view returns (uint256) {
        return fee;
    }

    function getFeeManager() external view returns (address) {
        return feeManager;
    }

    function changeFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }

    function changeFeeManager(address _feeManager) external onlyOwner {
        feeManager = _feeManager;
        emit FeeManagerUpdated(_feeManager);
    }

    /**
     * @dev add erc20 token contract to not allowance set
     */
    function addNotAllowed(address[] memory _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            notAllowed[_tokens[i]] = true;
        }
    }

    /**
     * @dev remove erc20 token contract from not allowance set
     */
    function removeNotAllowed(address[] memory _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            notAllowed[_tokens[i]] = false;
        }
    }

    /**
     * @dev get ethereum address
     */
    function getAddressETH() public pure returns (address eth) {
        eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    /**
     * @dev Set Distribution Contract For Tokens
     */
    function setDistribution(address token, address distAddress) external onlyOwner {
        require(token != address(0) && distAddress != address(0), "ZERO ADDRESS");
        distributionContract[token] = distAddress;
    }

    /**
     * @dev recover tokens sent to contract
     */
    function sweep(
        address erc20,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        require(erc20 != address(0) && recipient != address(0), "ZERO ADDRESS");
        if (erc20 == getAddressETH()) {
            payable(recipient).transfer(amount);
        } else {
            IERC20(erc20).transfer(recipient, amount);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
The MIT License (MIT)

Copyright (c) 2018 Murray Software, LLC.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {
	function createClone(address target) internal returns (address result) {
		bytes20 targetBytes = bytes20(target);
		assembly {
			let clone := mload(0x40)
			mstore(
				clone,
				0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
			)
			mstore(add(clone, 0x14), targetBytes)
			mstore(
				add(clone, 0x28),
				0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
			)
			result := create(0, clone, 0x37)
		}
	}

	function isClone(address target, address query)
		internal
		view
		returns (bool result)
	{
		bytes20 targetBytes = bytes20(target);
		assembly {
			let clone := mload(0x40)
			mstore(
				clone,
				0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
			)
			mstore(add(clone, 0xa), targetBytes)
			mstore(
				add(clone, 0x1e),
				0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
			)

			let other := add(clone, 0x40)
			extcodecopy(query, other, 0, 0x2d)
			result := and(
				eq(mload(clone), mload(other)),
				eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
			)
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FeeManager is OwnableUpgradeable {
	uint256 public constant MAX_FEE = 10000;

	mapping(address => uint256) vaults;
	mapping(address => uint256) lending;

	uint256 private swapFee;

	function initialize() public initializer {
		__Ownable_init();
	}

	function getVaultFee(address _vault) external view returns (uint256) {
		return vaults[_vault];
	}

	function getVaultFeeMultiple(address[] memory _vaults)
		external
		view
		returns (uint256[] memory)
	{
		uint256[] memory _fees = new uint256[](_vaults.length);

		for (uint256 i = 0; i < _vaults.length; i++)
			_fees[i] = vaults[_vaults[i]];

		return _fees;
	}

	function getLendingFee(address _asset) external view returns (uint256) {
		return lending[_asset];
	}

	function getLendingFeeMultiple(address[] memory _assets)
		external
		view
		returns (uint256[] memory)
	{
		uint256[] memory _fees = new uint256[](_assets.length);

		for (uint256 i = 0; i < _assets.length; i++)
			_fees[i] = lending[_assets[i]];

		return _fees;
	}

	function getSwapFee() external view returns (uint256) {
		return swapFee;
	}

	function setVaultFee(address _vault, uint256 _fee) external onlyOwner {
		require(_fee <= MAX_FEE);
		vaults[_vault] = _fee;
	}

	function setVaultFeeMulti(address[] memory _vaults, uint256[] memory _fees)
		external
		onlyOwner
	{
		require(_vaults.length == _fees.length, "!LENGTH");
		for (uint256 i = 0; i < _vaults.length; i++) {
			require(_fees[i] <= MAX_FEE);
			vaults[_vaults[i]] = _fees[i];
		}
	}

	function setLendingFee(address _asset, uint256 _fee) external onlyOwner {
		lending[_asset] = _fee;
	}

	function setLendingFeeMulti(
		address[] memory _assets,
		uint256[] memory _fees
	) external onlyOwner {
		require(_assets.length == _fees.length, "!LENGTH");
		for (uint256 i = 0; i < _assets.length; i++) {
			require(_fees[i] <= MAX_FEE);
			lending[_assets[i]] = _fees[i];
		}
	}

	function setSwapFee(uint256 _swapFee) external onlyOwner {
		swapFee = _swapFee;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MultiFeeDistribution is Ownable {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	/* ========== STATE VARIABLES ========== */
	struct Reward {
		uint256 periodFinish;
		uint256 rewardRate;
		uint256 lastUpdateTime;
		uint256 rewardPerTokenStored;
		// tracks already-added balances to handle accrued interest in aToken rewards
		// for the stakingToken this value is unused and will always be 0
		uint256 balance;
	}

	struct RewardData {
		address token;
		uint256 amount;
	}

	address[] public rewardTokens;
	address public voteEscrow;
	mapping(address => Reward) public rewardData;

	// Duration that rewards are streamed over
	uint256 public constant rewardsDuration = 86400 * 7;

	// user -> reward token -> amount
	mapping(address => mapping(address => uint256))
		public userRewardPerTokenPaid;
	mapping(address => mapping(address => uint256)) public rewards;

	uint256 public totalStaked;

	// Private mappings for balance data
	mapping(address => uint256) public balances;

	/* ========== ADMIN CONFIGURATION ========== */

	modifier onlyVoteEscrow() {
		require(
			msg.sender == voteEscrow,
			"MultiFeeDistribution: not the voteEscrow contract"
		);
		_;
	}

	// Add a new reward token to be distributed to stakers
	function addReward(address _rewardsToken) external onlyOwner {
		require(
			_rewardsToken != address(0),
			"MultiFeeDistribution: reward address cannot be the address 0"
		);
		require(rewardData[_rewardsToken].lastUpdateTime == 0, "MultiFeeDistribution: reward token already added");
		rewardTokens.push(_rewardsToken);
		rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
		rewardData[_rewardsToken].periodFinish = block.timestamp;
	}

	function setVoteEscrow(address _voteEscrow) external onlyOwner {
		require(
			voteEscrow == address(0),
			"MultiFeeDistribution: the voteEscrow contract is already set"
		);
		require(
			_voteEscrow != address(0),
			"MultiFeeDistribution: the voteEscrow contract can't be the address zero"
		);
		voteEscrow = _voteEscrow;
	}

	/* ========== VIEWS ========== */

	function _rewardPerToken(address _rewardsToken, uint256 _supply)
		internal
		view
		returns (uint256)
	{
		if (_supply == 0) {
			return rewardData[_rewardsToken].rewardPerTokenStored;
		}

		return
			rewardData[_rewardsToken].rewardPerTokenStored.add(
				lastTimeRewardApplicable(_rewardsToken)
					.sub(rewardData[_rewardsToken].lastUpdateTime)
					.mul(rewardData[_rewardsToken].rewardRate)
					.mul(1e18)
					.div(_supply)
			);
	}

	function _earned(
		address _user,
		address _rewardsToken,
		uint256 _balance,
		uint256 _currentRewardPerToken
	) internal view returns (uint256) {
		return
			_balance
				.mul(
					_currentRewardPerToken.sub(
						userRewardPerTokenPaid[_user][_rewardsToken]
					)
				)
				.div(1e18)
				.add(rewards[_user][_rewardsToken]);
	}

	function lastTimeRewardApplicable(address _rewardsToken)
		public
		view
		returns (uint256)
	{
		uint256 periodFinish = rewardData[_rewardsToken].periodFinish;
		return block.timestamp < periodFinish ? block.timestamp : periodFinish;
	}

	function rewardPerToken(address _rewardsToken)
		external
		view
		returns (uint256)
	{
		return _rewardPerToken(_rewardsToken, totalStaked);
	}

	function getRewardTokens()
		external
		view
		returns (address[] memory)
	{
		return rewardTokens;
	}

	function getRewardForDuration(address _rewardsToken)
		external
		view
		returns (uint256)
	{
		return
			rewardData[_rewardsToken].rewardRate.mul(rewardsDuration).div(1e12);
	}

	// Address and claimable amount of all reward tokens for the given account
	function claimableRewards(address account)
		external
		view
		returns (RewardData[] memory)
	{
		RewardData[] memory _rewards = new RewardData[](rewardTokens.length);
		for (uint256 i; i < _rewards.length; i++) {
			_rewards[i].token = rewardTokens[i];
			_rewards[i].amount = _earned(
				account,
				_rewards[i].token,
				balances[account],
				_rewardPerToken(rewardTokens[i], totalStaked)
			).div(1e12);
		}

		return _rewards;
	}

	// Total balance of an account, including unlocked, locked and earned tokens
	function stakeOfUser(address user) external view returns (uint256 amount) {
		return balances[user];
	}

	/* ========== MUTATIVE FUNCTIONS ========== */

	// Stake tokens to receive rewards
	// Locked tokens cannot be withdrawn for lockDuration and are eligible to receive stakingReward rewards
	function stake(uint256 amount, address user) external onlyVoteEscrow {
		require(amount > 0, "MultiFeeDistribution: Cannot stake 0");
		require(
			user != address(0),
			"MultiFeeDistribution: Cannot be address zero"
		);

		_updateReward(user);
		totalStaked = totalStaked.add(amount);
		balances[user] = balances[user].add(amount);

		emit Staked(user, amount);
	}

	// @TODO maybe in the future delete this, because we want to totally exit the multifee
	function withdraw(uint256 amount, address user) external onlyVoteEscrow {
		require(amount > 0, "MultiFeeDistribution: cannot withdraw 0");
		require(
			user != address(0),
			"MultiFeeDistribution: Cannot be address zero"
		);

		_updateReward(user);
		balances[user] = balances[user].sub(amount);

		totalStaked = totalStaked.sub(amount);
		emit Withdrawn(user, amount);
	}

	function _getReward(address[] memory _rewardTokens, address user) internal {
		uint256 length = _rewardTokens.length;
		for (uint256 i; i < length; i++) {
			address token = _rewardTokens[i];
			uint256 reward = rewards[user][token].div(1e12);
			// for rewards, every 24 hours we check if new
			// rewards were sent to the contract or accrued via aToken interest
			Reward storage r = rewardData[token];
			uint256 periodFinish = r.periodFinish;
			require(
				periodFinish > 0,
				"MultiFeeDistribution: Unknown reward token"
			);

			uint256 balance = r.balance;

			if (periodFinish < block.timestamp.add(rewardsDuration - 86400)) {
				uint256 unseen = IERC20(token).balanceOf(address(this)).sub(
					balance
				);
				if (unseen > 0) {
					_notifyReward(token, unseen);
					balance = balance.add(unseen);
				}
			}

			r.balance = balance.sub(reward);
			if (reward == 0) continue;
			rewards[user][token] = 0;
			IERC20(token).safeTransfer(user, reward);
			emit RewardPaid(user, token, reward);
		}
	}

	// Claim all pending staking rewards
	function getReward(address[] memory _rewardTokens, address user) public {
		require(
			user != address(0),
			"MultiFeeDistribution: user cannot be address zero"
		);
		_updateReward(user);
		_getReward(_rewardTokens, user);
	}

	function exit(address user) external onlyVoteEscrow {
		require(
			user != address(0),
			"MultiFeeDistribution: user cannot be address zero"
		);
		_updateReward(user);
		uint256 amount = balances[user];
		balances[user] = 0;

		totalStaked = totalStaked.sub(amount);
		_getReward(rewardTokens, user);

		emit Withdrawn(user, amount);
	}

	/* ========== RESTRICTED FUNCTIONS ========== */

	function _notifyReward(address _rewardsToken, uint256 reward) internal {
		Reward storage r = rewardData[_rewardsToken];
		if (block.timestamp >= r.periodFinish) {
			r.rewardRate = reward.mul(1e12).div(rewardsDuration);
		} else {
			uint256 remaining = r.periodFinish.sub(block.timestamp);
			uint256 leftover = remaining.mul(r.rewardRate).div(1e12);
			r.rewardRate = reward.add(leftover).mul(1e12).div(rewardsDuration);
		}

		r.lastUpdateTime = block.timestamp;
		r.periodFinish = block.timestamp.add(rewardsDuration);
	}

	function _updateReward(address account) internal {
		uint256 length = rewardTokens.length;

		for (uint256 i = 0; i < length; i++) {
			address token = rewardTokens[i];
			Reward storage r = rewardData[token];
			r = rewardData[token];
			uint256 rpt = _rewardPerToken(token, totalStaked);
			r.rewardPerTokenStored = rpt;
			r.lastUpdateTime = lastTimeRewardApplicable(token);

			if (account != address(this)) {
				rewards[account][token] = _earned(
					account,
					token,
					balances[account],
					rpt
				);
				userRewardPerTokenPaid[account][token] = rpt;
			}
		}
	}

	/* ========== EVENTS ========== */

	event RewardAdded(uint256 reward);
	event Staked(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 receivedAmount);
	event RewardPaid(
		address indexed user,
		address indexed rewardsToken,
		uint256 reward
	);
	event RewardsDurationUpdated(address token, uint256 newDuration);
	event Recovered(address token, uint256 amount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import {IHarvester} from "../interfaces/IHarvester.sol";
import {IVault} from "../interfaces/IVault.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IFactory {
	function notifyRewardAmounts() external;
}

contract GelatoDist is Ownable {
	using SafeMath for uint256;
	using EnumerableSet for EnumerableSet.AddressSet;

	EnumerableSet.AddressSet private factories;

	address public gelato = 0x527a819db1eb0e34426297b03bae11F2f8B3A19E;

	function updateGelato(address _gelato) external onlyOwner {
		gelato = _gelato;
	}

	function addFactory(address _factory) external onlyOwner {
		require(!factories.contains(_factory), "EXISTS");

		factories.add(_factory);
	}

	function removeFactory(address _factory) external onlyOwner {
		require(factories.contains(_factory), "!EXISTS");

		factories.remove(_factory);
	}

	function getFactory(uint256 index) public view returns (address) {
		return factories.at(index);
	}

	function distribute() external {
		require(msg.sender == gelato, "!GELATO");
		for (uint256 i = 0; i < factories.length(); i++) {
			IFactory(getFactory(i)).notifyRewardAmounts();
		}
	}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Helpers.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Perform arithmetic actions over stored memory values
 */
contract MemoryResolver is Helpers {
    using SafeMath for uint256;

    /**
     * @dev get vault distribution factory address
     */
    function addValues(uint256[] memory ids, uint256 initialVal) external payable {
        uint256 total = initialVal;

        for (uint256 i = 0; i < ids.length; i++) {
            total = total.add(getUint(ids[i]));
        }

        setUint(1, total); // store in first position
    }
}

contract MemoryLogic is MemoryResolver {
    string public constant name = "MemoryLogic";
    uint8 public constant version = 1;

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

/**
 * @title Mock ETHA token
 */
contract ETHAToken is ERC20PresetMinterPauser {
	constructor() ERC20PresetMinterPauser("Test ETHA", "TEST") {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Helpers.sol";

contract TransferResolver is Helpers {
    using SafeERC20 for IERC20;

    event LogDeposit(address indexed user, address indexed erc20, uint256 tokenAmt);
    event LogWithdraw(address indexed user, address indexed erc20, uint256 tokenAmt);

    /**
     * @dev Deposit ERC20 from user
     * @dev user must approve token transfer first
     */
    function deposit(
        address erc20,
        uint256 amount,
        uint getId
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId) : amount;
        require(realAmt > 0, "ZERO AMOUNT");

        if (erc20 != getAddressETH()) {
            IERC20(erc20).safeTransferFrom(_msgSender(), address(this), realAmt);
        }

        emit LogDeposit(_msgSender(), erc20, realAmt);
    }

    /**
     * @dev Withdraw ETH/ERC20 to user
     */
    function withdraw(address erc20, uint256 amount) external payable {
        if (erc20 == getAddressETH()) {
            payable(_msgSender()).transfer(amount);
        } else {
            IERC20(erc20).safeTransfer(_msgSender(), amount);
        }

        emit LogWithdraw(_msgSender(), erc20, amount);
    }

    /**
     * @dev Withdraw All ETH/ERC20 balance to user
     */
    function withdrawAll(address erc20) external payable {
        uint amount;

        if (erc20 == getAddressETH()) {
            amount = address(this).balance;
            if (amount > 0) payable(_msgSender()).transfer(amount);
        } else {
            amount = IERC20(erc20).balanceOf(address(this));
            if (amount > 0) IERC20(erc20).safeTransfer(_msgSender(), amount);
        }

        if (amount > 0) emit LogWithdraw(_msgSender(), erc20, amount);
    }

    /**
     * @dev Withdraw ETH/ERC20 to external wallet
     */
    function withdrawTo(
        address erc20,
        address to,
        uint256 amount,
        uint getId
    ) external payable {
        uint256 realAmt = getId > 0 ? getUint(getId) : amount;
        require(realAmt > 0, "ZERO AMOUNT");

        if (erc20 == getAddressETH()) {
            payable(to).transfer(realAmt);
        } else {
            IERC20(erc20).safeTransfer(to, realAmt);
        }

        emit LogWithdraw(_msgSender(), erc20, realAmt);
    }

    /**
     * @dev Remove ERC20 approval to certain target
     */
    function removeApproval(address erc20, address target) external {
        if (erc20 != getAddressETH()) {
            IERC20(erc20).approve(target, 0);
        }
    }
}

contract TransferLogic is TransferResolver {
    string public constant name = "TransferLogic";
    uint8 public constant version = 3;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Helpers.sol";

contract ParaswapResolver is Helpers {
    using UniversalERC20 for IERC20;

    // EVENTS
    event LogSwap(address indexed user, address indexed src, address indexed dest, uint256 amount);

    /**
     * @dev internal function to charge swap fees
     */
    function _paySwapFees(IERC20 erc20, uint256 amt) internal returns (uint256 feesPaid) {
        (uint256 fee, uint256 maxFee, address feeRecipient) = getSwapFee();

        // When swap fee is 0 or sender has partner role
        if (fee == 0) return 0;

        require(feeRecipient != address(0), "ZERO ADDRESS");

        feesPaid = (amt * fee) / maxFee;
        erc20.universalTransfer(feeRecipient, feesPaid);
    }

    /**
     * @dev Swap tokens in Paraswap dex
     * @param fromToken address of the source token
     * @param destToken address of the target token
     * @param transferProxy address of proxy contract that handles token transfers
     * @param tokenAmt amount of fromTokens to swap
     * @param swapTarget paraswap swapper contract
     * @param swapData encoded function call
     * @param setId set value of tokens swapped in memory contract
     */
    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        address transferProxy,
        uint256 tokenAmt,
        address swapTarget,
        bytes memory swapData,
        uint256 setId
    ) external payable {
        require(tokenAmt > 0, "ZERO AMOUNT");
        require(fromToken != destToken, "SAME ASSETS");

        uint bal = destToken.balanceOf(address(this));

        // Approve only whats needed
        fromToken.universalApprove(transferProxy, tokenAmt);

        // Execute tx on paraswap Swapper
        (bool success, bytes memory returnData) = swapTarget.call(swapData);

        // Fetch error message if tx not successful
        if (!success) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (returnData.length < 68) revert();
            assembly {
                returnData := add(returnData, 0x04)
            }
            revert(abi.decode(returnData, (string)));
        }

        uint received = destToken.balanceOf(address(this)) - bal;

        assert(received > 0);

        // Pay Fees
        uint256 feesPaid = _paySwapFees(destToken, received);

        // set destTokens received
        if (setId > 0) {
            setUint(setId, received - feesPaid);
        }

        emit LogSwap(_msgSender(), address(fromToken), address(destToken), tokenAmt);
    }
}

contract ParaswapLogic is ParaswapResolver {
    string public constant name = "ParaswapLogic";
    uint8 public constant version = 1;

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IVotingEscrow.sol";
import "../../interfaces/IMultiFeeDistribution.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Modifiers, VeEthaInfo, Rewards, MATIC, IERC20} from "./AppStorage.sol";

contract GettersFacet is Modifiers {
    function getPrice(address token) external view returns (int256) {
        (, int256 price, , , ) = AggregatorV3Interface(s.priceFeeds[token]).latestRoundData();
        return price;
    }

    function getAToken(address token) external view returns (address) {
        return s.aTokens[token];
    }

    function getCrToken(address token) external view returns (address) {
        return s.crTokens[token];
    }

    function getBalances(address[] calldata tokens, address user) external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == MATIC) balances[i] = user.balance;
            else balances[i] = IERC20(tokens[i]).balanceOf(user);
        }

        return balances;
    }

    function getGovernanceInfo(address veETHA, address user)
        external
        view
        returns (VeEthaInfo memory info, Rewards[] memory rewards)
    {
        info.feeRecipient = IVotingEscrow(veETHA).penaltyCollector();
        info.minLockedAmount = IVotingEscrow(veETHA).minLockedAmount();
        info.penaltyRate = IVotingEscrow(veETHA).earlyWithdrawPenaltyRate();
        info.totalEthaLocked = IVotingEscrow(veETHA).supply();
        info.totalVeEthaSupply = IVotingEscrow(veETHA).totalSupply();
        info.userVeEthaBalance = IVotingEscrow(veETHA).balanceOf(user);
        (info.userEthaLocked, info.userLockEnds) = IVotingEscrow(veETHA).locked(user);

        info.multiFeeAddress = IVotingEscrow(veETHA).multiFeeDistribution();
        IMultiFeeDistribution multiFee = IMultiFeeDistribution(info.multiFeeAddress);
        info.multiFeeTotalStaked = multiFee.totalStaked();
        info.multiFeeUserStake = multiFee.balances(user);

        address[] memory rewardTokens = multiFee.getRewardTokens(); // only works with new multi fee

        IMultiFeeDistribution.RewardData[] memory userClaimable = multiFee.claimableRewards(user);
        rewards = new Rewards[](rewardTokens.length);

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            IMultiFeeDistribution.Reward memory rewardData = multiFee.rewardData(rewardTokens[i]);
            rewards[i].tokenAddress = rewardTokens[i];
            rewards[i].rewardRate = rewardData.rewardRate;
            rewards[i].periodFinish = rewardData.periodFinish;
            rewards[i].balance = rewardData.balance;
            rewards[i].claimable = userClaimable[i].amount;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IVotingEscrow.sol";
import "../../interfaces/IMultiFeeDistribution.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AvaModifiers, AVAX, IERC20} from "./AppStorage.sol";

contract AvaGettersFacet is AvaModifiers {
    function getRegistryAddress() external view returns (address) {
        return s.ethaRegistry;
    }

    function getPriceFeed(address _token) public view returns (address) {
        return s.priceFeeds[_token];
    }

    function getPrice(address token) external view returns (int256) {
        (, int256 price, , , ) = AggregatorV3Interface(s.priceFeeds[token]).latestRoundData();
        return price;
    }

    function getBalances(address[] calldata tokens, address user) external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == AVAX) balances[i] = user.balance;
            else balances[i] = IERC20(tokens[i]).balanceOf(user);
        }

        return balances;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Memory is Ownable {
	mapping(address => address) aTokens;
	mapping(address => address) crTokens;
	mapping(uint256 => uint256) values;

	function getUint(uint256 id) external view returns (uint256) {
		return values[id];
	}

	function setUint(uint256 id, uint256 _value) external {
		values[id] = _value;
	}

	function getAToken(address asset) external view returns (address) {
		return aTokens[asset];
	}

	function setAToken(address asset, address _aToken) external onlyOwner {
		aTokens[asset] = _aToken;
	}

	function getCrToken(address asset) external view returns (address) {
		return crTokens[asset];
	}

	function setCrToken(address asset, address _crToken) external onlyOwner {
		crTokens[asset] = _crToken;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "./libs/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";

contract Diamond {
    constructor(address _contractOwner, address _diamondCutFacet) payable {
        LibDiamond.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {AvaModifiers} from "./AppStorage.sol";

contract AvaSettersFacet is AvaModifiers {
    function setRegistry(address _ethaRegistry) external onlyOwner {
        s.ethaRegistry = _ethaRegistry;
    }

    function setPriceFeeds(address[] memory _tokens, address[] memory _feeds) external onlyOwner {
        require(_tokens.length == _feeds.length, "!LENGTH");
        for (uint256 i = 0; i < _tokens.length; i++) {
            s.priceFeeds[_tokens[i]] = _feeds[i];
        }
    }

    function setCurvePool(address[] memory lpTokens, address[] memory pools) external onlyOwner {
        require(lpTokens.length == pools.length, "!LENGTH");
        for (uint256 i = 0; i < lpTokens.length; i++) {
            s.curvePools[lpTokens[i]] = pools[i];
        }
    }
}