// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;
//import "hardhat/console.sol"; // DEV_MODE

import "./Storage.sol";
import "./Events.sol";
import "./Proxy.sol";

abstract contract Base is Storage, Events {
    // Modules

    function _createProxy(uint proxyModuleId) internal returns (address) {
        require(proxyModuleId != 0, "e/create-proxy/invalid-module");
        require(proxyModuleId <= MAX_EXTERNAL_MODULEID, "e/create-proxy/internal-module");

        // If we've already created a proxy for a single-proxy module, just return it:

        if (proxyLookup[proxyModuleId] != address(0)) return proxyLookup[proxyModuleId];

        // Otherwise create a proxy:

        address proxyAddr = address(new Proxy());

        if (proxyModuleId <= MAX_EXTERNAL_SINGLE_PROXY_MODULEID) proxyLookup[proxyModuleId] = proxyAddr;

        trustedSenders[proxyAddr] = TrustedSenderInfo({ moduleId: uint32(proxyModuleId), moduleImpl: address(0) });

        emit ProxyCreated(proxyAddr, proxyModuleId);

        return proxyAddr;
    }

    function callInternalModule(uint moduleId, bytes memory input) internal returns (bytes memory) {
        (bool success, bytes memory result) = moduleLookup[moduleId].delegatecall(input);
        if (!success) revertBytes(result);
        return result;
    }



    // Modifiers

    modifier nonReentrant() {
        require(reentrancyLock == REENTRANCYLOCK__UNLOCKED, "e/reentrancy");

        reentrancyLock = REENTRANCYLOCK__LOCKED;
        _;
        reentrancyLock = REENTRANCYLOCK__UNLOCKED;
    }

    modifier reentrantOK() { // documentation only
        _;
    }

    // Used to flag functions which do not modify storage, but do perform a delegate call
    // to a view function, which prohibits a standard view modifier. The flag is used to
    // patch state mutability in compiled ABIs and interfaces.
    modifier staticDelegate() {
        _;
    }

    // WARNING: Must be very careful with this modifier. It resets the free memory pointer
    // to the value it was when the function started. This saves gas if more memory will
    // be allocated in the future. However, if the memory will be later referenced
    // (for example because the function has returned a pointer to it) then you cannot
    // use this modifier.

    modifier FREEMEM() {
        uint origFreeMemPtr;

        assembly {
            origFreeMemPtr := mload(0x40)
        }

        _;

        /*
        assembly { // DEV_MODE: overwrite the freed memory with garbage to detect bugs
            let garbage := 0xDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF
            for { let i := origFreeMemPtr } lt(i, mload(0x40)) { i := add(i, 32) } { mstore(i, garbage) }
        }
        */

        assembly {
            mstore(0x40, origFreeMemPtr)
        }
    }



    // Error handling

    function revertBytes(bytes memory errMsg) internal pure {
        if (errMsg.length > 0) {
            assembly {
                revert(add(32, errMsg), mload(errMsg))
            }
        }

        revert("e/empty-error");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

abstract contract Constants {
    // Universal

    uint internal constant SECONDS_PER_YEAR = 365.2425 * 86400; // Gregorian calendar


    // Protocol parameters

    uint internal constant MAX_SANE_AMOUNT = type(uint112).max;
    uint internal constant MAX_SANE_SMALL_AMOUNT = type(uint96).max;
    uint internal constant MAX_SANE_DEBT_AMOUNT = type(uint144).max;
    uint internal constant INTERNAL_DEBT_PRECISION = 1e9;
    uint internal constant MAX_ENTERED_MARKETS = 10; // per sub-account
    uint internal constant MAX_POSSIBLE_ENTERED_MARKETS = 2**32; // limited by size of AccountStorage.numMarketsEntered
    uint internal constant CONFIG_FACTOR_SCALE = 4_000_000_000; // must fit into a uint32
    uint internal constant RESERVE_FEE_SCALE = 4_000_000_000; // must fit into a uint32
    uint32 internal constant DEFAULT_RESERVE_FEE = uint32(0.23 * 4_000_000_000);
    uint internal constant INITIAL_RESERVES = 1e6;
    uint internal constant INITIAL_INTEREST_ACCUMULATOR = 1e27;
    uint internal constant AVERAGE_LIQUIDITY_PERIOD = 24 * 60 * 60;
    uint16 internal constant MIN_UNISWAP3_OBSERVATION_CARDINALITY = 144;
    uint24 internal constant DEFAULT_TWAP_WINDOW_SECONDS = 30 * 60;
    uint32 internal constant DEFAULT_BORROW_FACTOR = uint32(0.28 * 4_000_000_000);
    uint32 internal constant SELF_COLLATERAL_FACTOR = uint32(0.95 * 4_000_000_000);


    // Implementation internals

    uint internal constant REENTRANCYLOCK__UNLOCKED = 1;
    uint internal constant REENTRANCYLOCK__LOCKED = 2;

    uint8 internal constant DEFERLIQUIDITY__NONE = 0;
    uint8 internal constant DEFERLIQUIDITY__CLEAN = 1;
    uint8 internal constant DEFERLIQUIDITY__DIRTY = 2;


    // Pricing types

    uint16 internal constant PRICINGTYPE__PEGGED = 1;
    uint16 internal constant PRICINGTYPE__UNISWAP3_TWAP = 2;
    uint16 internal constant PRICINGTYPE__FORWARDED = 3;
    uint16 internal constant PRICINGTYPE__CHAINLINK = 4;
    uint16 internal constant PRICINGTYPE__FORWARDED__QUADRAT = 5;

    // Correct pricing types are always less than this value
    uint16 internal constant PRICINGTYPE__OUT_OF_BOUNDS = 5;


    // Modules

    // Public single-proxy modules
    uint internal constant MODULEID__INSTALLER = 1;
    uint internal constant MODULEID__MARKETS = 2;
    uint internal constant MODULEID__LIQUIDATION = 3;
    uint internal constant MODULEID__GOVERNANCE = 4;
    uint internal constant MODULEID__EXEC = 5;
    uint internal constant MODULEID__SWAP = 6;
    uint internal constant MODULEID__SWAPHUB = 7;

    uint internal constant MAX_EXTERNAL_SINGLE_PROXY_MODULEID = 499_999;

    // Public multi-proxy modules
    uint internal constant MODULEID__ETOKEN = 500_000;
    uint internal constant MODULEID__DTOKEN = 500_001;

    uint internal constant MAX_EXTERNAL_MODULEID = 999_999;

    // Internal modules
    uint internal constant MODULEID__RISK_MANAGER = 1_000_000;

    // Interest rate models
    //   Default for new markets
    uint internal constant MODULEID__IRM_DEFAULT = 2_000_000;
    //   Testing-only
    uint internal constant MODULEID__IRM_ZERO = 2_000_001;
    uint internal constant MODULEID__IRM_FIXED = 2_000_002;
    uint internal constant MODULEID__IRM_LINEAR = 2_000_100;
    //   Classes
    uint internal constant MODULEID__IRM_CLASS__STABLE = 2_000_500;
    uint internal constant MODULEID__IRM_CLASS__MAJOR = 2_000_501;
    uint internal constant MODULEID__IRM_CLASS__MIDCAP = 2_000_502;
    uint internal constant MODULEID__IRM_CLASS__MEGA = 2_000_503;
    uint internal constant MODULEID__IRM_CLASS__LIDO = 2_000_504;
    uint internal constant MODULEID__IRM_CLASS__USDT = 2_000_505;
    uint internal constant MODULEID__IRM_CLASS__OHM = 2_000_506;

    // Swap types
    uint internal constant SWAP_TYPE__UNI_EXACT_INPUT_SINGLE = 1;
    uint internal constant SWAP_TYPE__UNI_EXACT_INPUT = 2;
    uint internal constant SWAP_TYPE__UNI_EXACT_OUTPUT_SINGLE = 3;
    uint internal constant SWAP_TYPE__UNI_EXACT_OUTPUT = 4;
    uint internal constant SWAP_TYPE__1INCH = 5;

    uint internal constant SWAP_TYPE__UNI_EXACT_OUTPUT_SINGLE_REPAY = 6;
    uint internal constant SWAP_TYPE__UNI_EXACT_OUTPUT_REPAY = 7;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./Base.sol";


/// @notice Main storage contract for the Euler system
contract Euler is Base {
    constructor(address admin, address installerModule) {
        emit Genesis();

        reentrancyLock = REENTRANCYLOCK__UNLOCKED;
        upgradeAdmin = admin;
        governorAdmin = admin;

        moduleLookup[MODULEID__INSTALLER] = installerModule;
        address installerProxy = _createProxy(MODULEID__INSTALLER);
        trustedSenders[installerProxy].moduleImpl = installerModule;
    }

    string public constant name = "Euler Protocol";

    /// @notice Lookup the current implementation contract for a module
    /// @param moduleId Fixed constant that refers to a module type (ie MODULEID__ETOKEN)
    /// @return An internal address specifies the module's implementation code
    function moduleIdToImplementation(uint moduleId) external view returns (address) {
        return moduleLookup[moduleId];
    }

    /// @notice Lookup a proxy that can be used to interact with a module (only valid for single-proxy modules)
    /// @param moduleId Fixed constant that refers to a module type (ie MODULEID__MARKETS)
    /// @return An address that should be cast to the appropriate module interface, ie IEulerMarkets(moduleIdToProxy(2))
    function moduleIdToProxy(uint moduleId) external view returns (address) {
        return proxyLookup[moduleId];
    }

    function dispatch() external reentrantOK {
        uint32 moduleId = trustedSenders[msg.sender].moduleId;
        address moduleImpl = trustedSenders[msg.sender].moduleImpl;

        require(moduleId != 0, "e/sender-not-trusted");

        if (moduleImpl == address(0)) moduleImpl = moduleLookup[moduleId];

        uint msgDataLength = msg.data.length;
        require(msgDataLength >= (4 + 4 + 20), "e/input-too-short");

        assembly {
            let payloadSize := sub(calldatasize(), 4)
            calldatacopy(0, 4, payloadSize)
            mstore(payloadSize, shl(96, caller()))

            let result := delegatecall(gas(), moduleImpl, 0, add(payloadSize, 20), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
                case 0 { revert(0, returndatasize()) }
                default { return(0, returndatasize()) }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./Storage.sol";

abstract contract Events {
    event Genesis();


    event ProxyCreated(address indexed proxy, uint moduleId);
    event MarketActivated(address indexed underlying, address indexed eToken, address indexed dToken);
    event PTokenActivated(address indexed underlying, address indexed pToken);

    event EnterMarket(address indexed underlying, address indexed account);
    event ExitMarket(address indexed underlying, address indexed account);

    event Deposit(address indexed underlying, address indexed account, uint amount);
    event Withdraw(address indexed underlying, address indexed account, uint amount);
    event Borrow(address indexed underlying, address indexed account, uint amount);
    event Repay(address indexed underlying, address indexed account, uint amount);

    event Liquidation(address indexed liquidator, address indexed violator, address indexed underlying, address collateral, uint repay, uint yield, uint healthScore, uint baseDiscount, uint discount);

    event TrackAverageLiquidity(address indexed account);
    event UnTrackAverageLiquidity(address indexed account);
    event DelegateAverageLiquidity(address indexed account, address indexed delegate);

    event PTokenWrap(address indexed underlying, address indexed account, uint amount);
    event PTokenUnWrap(address indexed underlying, address indexed account, uint amount);

    event AssetStatus(address indexed underlying, uint totalBalances, uint totalBorrows, uint96 reserveBalance, uint poolSize, uint interestAccumulator, int96 interestRate, uint timestamp);


    event RequestDeposit(address indexed account, uint amount);
    event RequestWithdraw(address indexed account, uint amount);
    event RequestMint(address indexed account, uint amount);
    event RequestBurn(address indexed account, uint amount);
    event RequestTransferEToken(address indexed from, address indexed to, uint amount);
    event RequestDonate(address indexed account, uint amount);

    event RequestBorrow(address indexed account, uint amount);
    event RequestRepay(address indexed account, uint amount);
    event RequestTransferDToken(address indexed from, address indexed to, uint amount);

    event RequestLiquidate(address indexed liquidator, address indexed violator, address indexed underlying, address collateral, uint repay, uint minYield);


    event InstallerSetUpgradeAdmin(address indexed newUpgradeAdmin);
    event InstallerSetGovernorAdmin(address indexed newGovernorAdmin);
    event InstallerInstallModule(uint indexed moduleId, address indexed moduleImpl, bytes32 moduleGitCommit);


    event GovSetAssetConfig(address indexed underlying, Storage.AssetConfig newConfig);
    event GovSetIRM(address indexed underlying, uint interestRateModel, bytes resetParams);
    event GovSetPricingConfig(address indexed underlying, uint16 newPricingType, uint32 newPricingParameter);
    event GovSetReserveFee(address indexed underlying, uint32 newReserveFee);
    event GovConvertReserves(address indexed underlying, address indexed recipient, uint amount);
    event GovSetChainlinkPriceFeed(address indexed underlying, address chainlinkAggregator);

    event RequestSwap(address indexed accountIn, address indexed accountOut, address indexed underlyingIn, address underlyingOut, uint amount, uint swapType);
    event RequestSwapHub(address indexed accountIn, address indexed accountOut, address indexed underlyingIn, address underlyingOut, uint amountIn, uint amountOut, uint mode, address swapHandler);
    event RequestSwapHubRepay(address indexed accountIn, address indexed accountOut, address indexed underlyingIn, address underlyingOut, uint targetDebt, address swapHandler);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

contract Proxy {
    address immutable creator;

    constructor() {
        creator = msg.sender;
    }

    // External interface

    fallback() external {
        address creator_ = creator;

        if (msg.sender == creator_) {
            assembly {
                mstore(0, 0)
                calldatacopy(31, 0, calldatasize())

                switch mload(0) // numTopics
                    case 0 { log0(32,  sub(calldatasize(), 1)) }
                    case 1 { log1(64,  sub(calldatasize(), 33),  mload(32)) }
                    case 2 { log2(96,  sub(calldatasize(), 65),  mload(32), mload(64)) }
                    case 3 { log3(128, sub(calldatasize(), 97),  mload(32), mload(64), mload(96)) }
                    case 4 { log4(160, sub(calldatasize(), 129), mload(32), mload(64), mload(96), mload(128)) }
                    default { revert(0, 0) }

                return(0, 0)
            }
        } else {
            assembly {
                mstore(0, 0xe9c4a3ac00000000000000000000000000000000000000000000000000000000) // dispatch() selector
                calldatacopy(4, 0, calldatasize())
                mstore(add(4, calldatasize()), shl(96, caller()))

                let result := call(gas(), creator_, 0, 0, add(24, calldatasize()), 0, 0)
                returndatacopy(0, 0, returndatasize())

                switch result
                    case 0 { revert(0, returndatasize()) }
                    default { return(0, returndatasize()) }
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./Constants.sol";

abstract contract Storage is Constants {
    // Dispatcher and upgrades

    uint internal reentrancyLock;

    address upgradeAdmin;
    address governorAdmin;

    mapping(uint => address) moduleLookup; // moduleId => module implementation
    mapping(uint => address) proxyLookup; // moduleId => proxy address (only for single-proxy modules)

    struct TrustedSenderInfo {
        uint32 moduleId; // 0 = un-trusted
        address moduleImpl; // only non-zero for external single-proxy modules
    }

    mapping(address => TrustedSenderInfo) trustedSenders; // sender address => moduleId (0 = un-trusted)



    // Account-level state
    // Sub-accounts are considered distinct accounts

    struct AccountStorage {
        // Packed slot: 1 + 5 + 4 + 20 = 30
        uint8 deferLiquidityStatus;
        uint40 lastAverageLiquidityUpdate;
        uint32 numMarketsEntered;
        address firstMarketEntered;

        uint averageLiquidity;
        address averageLiquidityDelegate;
    }

    mapping(address => AccountStorage) accountLookup;
    mapping(address => address[MAX_POSSIBLE_ENTERED_MARKETS]) marketsEntered;



    // Markets and assets

    struct AssetConfig {
        // Packed slot: 20 + 1 + 4 + 4 + 3 = 32
        address eTokenAddress;
        bool borrowIsolated;
        uint32 collateralFactor;
        uint32 borrowFactor;
        uint24 twapWindow;
    }

    struct UserAsset {
        uint112 balance;
        uint144 owed;

        uint interestAccumulator;
    }

    struct AssetStorage {
        // Packed slot: 5 + 1 + 4 + 12 + 4 + 2 + 4 = 32
        uint40 lastInterestAccumulatorUpdate;
        uint8 underlyingDecimals; // Not dynamic, but put here to live in same storage slot
        uint32 interestRateModel;
        int96 interestRate;
        uint32 reserveFee;
        uint16 pricingType;
        uint32 pricingParameters;

        address underlying;
        uint96 reserveBalance;

        address dTokenAddress;

        uint112 totalBalances;
        uint144 totalBorrows;

        uint interestAccumulator;

        mapping(address => UserAsset) users;

        mapping(address => mapping(address => uint)) eTokenAllowance;
        mapping(address => mapping(address => uint)) dTokenAllowance;
    }

    mapping(address => AssetConfig) internal underlyingLookup; // underlying => AssetConfig
    mapping(address => AssetStorage) internal eTokenLookup; // EToken => AssetStorage
    mapping(address => address) internal dTokenLookup; // DToken => EToken
    mapping(address => address) internal pTokenLookup; // PToken => underlying
    mapping(address => address) internal reversePTokenLookup; // underlying => PToken
    mapping(address => address) internal chainlinkPriceFeedLookup; // underlying => chainlinkAggregator
}