// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// Dependencies
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// src
import {BytesLib} from "../../../libraries/BytesLib.sol";
import {BaseStep} from "../../BaseStep.sol";
import {DataTypes} from "../../../libraries/DataTypes.sol";
import {Errors} from "../../../libraries/Errors.sol";
import {IAssetRegistry} from "../../../interfaces/IAssetRegistry.sol";
import {IUniV3SwapRouter} from "../../../interfaces/steps/IUniV3SwapRouter.sol";
import {IUniV3NonFungiblePositionManager} from "../../../interfaces/steps/IUniV3NonFungiblePositionManager.sol";
import {IVault} from "../../../interfaces/IVault.sol";
import {Path} from "./library/Path.sol";
import {UniswapV3Lib} from "./UniswapV3Lib.sol";

/// @title Uniswap V3 Swap Step 
/// @author danyams & naveenailawadi

/**
 * Invariants:
 *  - A reverse path is valid if and only if the original path is valid
 */

contract UniswapV3SwapStep is BaseStep {
    using BytesLib for bytes;

    // vault => stepNodeKey => FixedData
    mapping(address => mapping(uint256 => UniswapV3Lib.SwapFixedData)) private swapStepData;

    constructor(address _dremHub, address _assetRegistry) BaseStep(_dremHub, _assetRegistry) {}

    function init(uint256 _stepNodeKey, bytes memory _encodedFixedArgs) external override canBeLegacied {
        // Only a transfer step can be the root of the stepTree; also can't be null
        if (_stepNodeKey < 2) revert Errors.InvalidStepPosition();

        _initSwap(_stepNodeKey, _encodedFixedArgs);
    }

    /**
     * @dev Swaps along the forward swap path.  Amount out minimum, the deadline, and the Uniswap fee are passed in as encoded variable arguments
     * This function is only meant to be called by a vault. However, if it is called on by an EOA or malicious contract, it will have no 
     * effect on any Drem vault
     * @param _caller the original caller of the vault's windSteps()
     * @param _stepNodeKey the step's node key in the vault's step tree
     * @param _amountIn the amount of this step's 'asset in', which varies based on the path, vault, and step node key, to be used 
     * @param _encodedVariableArgs the abi encoded variable args for this step
     * @return the amount of tokens produced of the step's 'asset out'
     */
    function wind(address _caller, uint256 _stepNodeKey, uint256 _amountIn, bytes memory _encodedVariableArgs)
        external
        override
        canBeDeprecated
        returns (uint256)
    {
        UniswapV3Lib.SwapVariableData memory variableArgs = _decodeSwapVariableData(_encodedVariableArgs);

        // Use the forward path
        bytes memory swapPath = swapStepData[msg.sender][_stepNodeKey].path;

        return UniswapV3Lib.swapExactInput(ASSET_REGISTRY, _caller, _amountIn, variableArgs, swapPath);
    }

    /**
     * @dev Swaps along the reversed swap path.  Amount out minimum, the deadline, and the Uniswap fee are passed in as encoded variable arguments
     * This function is only meant to be called by a vault. However, if it is called on by an EOA or malicious contract, it will have no 
     * effect on any Drem vault
     * @param _caller the original caller of the vault's unwindSteps()
     * @param _stepNodeKey the step's node key in the vault's step tree
     * @param _amountIn the amount of this step's 'asset out', which varies based on the path, vault, and step node key, to be used 
     * @param _encodedVariableArgs the abi encoded variable args for this step
     * @return the amount of tokens produced of the step's 'asset in' 
     */
    function unwind(address _caller, uint256 _stepNodeKey, uint256 _amountIn, bytes memory _encodedVariableArgs)
        external
        override
        canBeDisabled
        returns (uint256)
    {
        UniswapV3Lib.SwapVariableData memory variableArgs = _decodeSwapVariableData(_encodedVariableArgs);

        // Use the reversed path
        bytes memory reversedSwapPath = swapStepData[msg.sender][_stepNodeKey].reversedPath;

        return UniswapV3Lib.swapExactInput(ASSET_REGISTRY, _caller, _amountIn, variableArgs, reversedSwapPath);
    }

    /**
     * @dev Returns the value of the 'tokens produced' of the step's asset out in the vault's denomination asset
     * This function was designed to be called only by the vault. It uses msg.sender, and the _tokensProduced param
     * comes from a vault's internal accounting.  
     * @param _stepNodeKey the step's node key in the vault's step tree
     * @param _tokensProduced the cumulative amount of tokens produced from this step's winds for a given vault
     * @param _denominationAsset the vault's denomination asset
     * @return the value of the '_tokensProduced' in the vault's '_denominationAsset'
     */
    function value(uint256 _stepNodeKey, uint256 _tokensProduced, address _denominationAsset) external view override returns (uint256) {
        // Get the reversed swap path
        bytes memory reversedSwapPath = swapStepData[msg.sender][_stepNodeKey].reversedPath;

        // The token in of the reversed swap path is the token out of the regular path
        address tokenOut = _tokenIn(reversedSwapPath);

        //Price Aggregator
        return PRICE_AGGREGATOR.convertAsset(_tokensProduced, tokenOut, _denominationAsset);
    }

    /**
     * @notice Returns this step's asset in for a given step of a vault
     * @param _stepNodeKey the step's node key in the vault's step tree
     * @param _vault the vault
     * @return the address of the asset in
     */
    function assetIn(uint256 _stepNodeKey, address _vault) external view override returns (address) {
        // The initial token in the forward swap path is the asset in
        bytes memory swapPath = swapStepData[_vault][_stepNodeKey].path;
        return _tokenIn(swapPath);
    }

    /**
     * @notice Returns this step's asset out for a given step of a vault
     * @param _stepNodeKey the step's node key in the vault's step tree
     * @param _vault the vault
     * @return the address of the asset out
     */
    function assetOut(uint256 _stepNodeKey, address _vault) external view override returns (address) {
        // The initial token in the reversed swap path is the asset out
        bytes memory reversedSwapPath = swapStepData[_vault][_stepNodeKey].reversedPath;
        return _tokenIn(reversedSwapPath);
    }

    /**
     * @notice Returns the swap step data for a given step of a vault
     * @param _stepNodeKey the step's node key in the vault's step tree
     * @param _vault the vault
     * @return the UniswapV3Lib.SwapFixedData for the given step
     */
    function getSwapStepData(uint256 _stepNodeKey, address _vault)
        external
        view
        returns (UniswapV3Lib.SwapFixedData memory)
    {
        return swapStepData[_vault][_stepNodeKey];
    }

    /**
     * @dev the only encoded fixed args for the vault is the path, which must remain encoded
     */
    function _initSwap(uint256 _stepNodeKey, bytes memory _path) internal {
        // Validate path, and get tokenIn and tokenOut
        address tokenOut = UniswapV3Lib.validateSwapPath(ASSET_REGISTRY, _path);
        address tokenIn = _tokenIn(_path);

        // Get the reversed path
        bytes memory _reversedPath = UniswapV3Lib.reverseSwapPath(_path);

        // Store
        swapStepData[msg.sender][_stepNodeKey] = UniswapV3Lib.SwapFixedData({path: _path, reversedPath: _reversedPath});

        emit UniswapV3Lib.InitSwap(msg.sender, _stepNodeKey, tokenIn, tokenOut);
    }

    function _tokenIn(bytes memory _path) internal pure returns (address) {
        return _path.toAddress(0);
    }

    function _decodeSwapVariableData(bytes memory _encodedVariableArgs)
        internal
        pure
        returns (UniswapV3Lib.SwapVariableData memory)
    {
        (uint256 _amountOutMinimum, uint256 _deadline) = abi.decode(_encodedVariableArgs, (uint256, uint256));

        return UniswapV3Lib.SwapVariableData({amountOutMinimum: _amountOutMinimum, deadline: _deadline});
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

// Reference: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol

/**
 * Change Log:
 * - Omitted concatStorage(), toUint16(), toUint32(), toUint64(), toUint96(),
 *  toUint128(), toUint256(), toBytes32(), equal(), equalStorage()
 */

/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for { let cc := add(_postBytes, 0x20) } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } { mstore(mc, mload(cc)) }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } { mstore(mc, mload(cc)) }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IAssetRegistry} from "../interfaces/IAssetRegistry.sol";
import {IPriceAggregator} from "../interfaces/IPriceAggregator.sol";
import {IStep} from "./IStep.sol";
import {HubOwnable} from "../base/HubOwnable.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";

// this is really where any useful modifiers and universal data goes
abstract contract BaseStep is IStep, HubOwnable {
    IAssetRegistry public immutable ASSET_REGISTRY;
    IPriceAggregator public immutable PRICE_AGGREGATOR;

    constructor(address _dremHub, address _assetRegistry) HubOwnable(_dremHub) {
        if (_assetRegistry == address(0)) revert Errors.ZeroAddress();

        ASSET_REGISTRY = IAssetRegistry(_assetRegistry);
        PRICE_AGGREGATOR = ASSET_REGISTRY.PRICE_AGGREGATOR();

        if (address(PRICE_AGGREGATOR) == address(0)) revert Errors.ZeroAddress();
    }

    // Note: Using internal functions cuts down on bytecode size

    /**
     * Step Key:
     *  - Unwind function use 'canBeDisabled' modifier
     *  - Wind function use 'canBeDeprecated' modifier
     *  - Init function use 'canBeLegacied' modifier
     */

    modifier canBeDisabled() {
        _validateStepNotDisabled();
        _;
    }

    modifier canBeDeprecated() {
        _validateStepNotDeprecated();
        _;
    }

    // 'legacied' isn't a real word, but it's okay
    modifier canBeLegacied() {
        _validateStepNotLegacied();
        _;
    }

    function init(uint256 stepNodeKey, bytes calldata encodedFixedArgs) external virtual canBeLegacied {}

    function wind(address caller, uint256 stepNodeKey, uint256 amountIn, bytes memory encodedVariableArgs)
        external
        virtual
        canBeDeprecated
        returns (uint256)
    {}

    function unwind(address caller, uint256 stepNodeKey, uint256 amountIn, bytes memory encodedVariableArgs)
        external
        virtual
        canBeDisabled
        returns (uint256)
    {}

    function value(uint256 stepNodeKey, uint256 tokensProduced, address denominationAsset) external view virtual returns (uint256) {}

    function assetIn(uint256 stepNodeKey, address vault) external view virtual returns (address) {}

    function assetOut(uint256 stepNodeKey, address vault) external view virtual returns(address) {}

    function _validateAssetIsDenominationAsset(address _asset) internal view {
        if (!(ASSET_REGISTRY.isAssetDenominationAsset(_asset))) revert Errors.AssetNotDenominationAsset();
    }

    function _validateAssetIsWhitelisted(address _asset) internal view {
        if (!(ASSET_REGISTRY.isAssetWhitelisted(_asset))) revert Errors.AssetNotWhitelisted();
    }

    /**
     * StepState Key:
     * 0: Disabled
     * 1: Deprecated
     * 2: Legacy
     * 3: Enabled
     */

    function _validateStepNotDisabled() internal view {
        if (DREM_HUB.getStepState(address(this)) == DataTypes.StepState.Disabled) revert Errors.StepDisabled();
    }

    function _validateStepNotDeprecated() internal view {
        // If step's state is less than legacy, it is either deprecated or disabled
        if (DREM_HUB.getStepState(address(this)) < DataTypes.StepState.Legacy) revert Errors.StepDeprecatedOrDisabled();
    }

    function _validateStepNotLegacied() internal view {
        // If step's state is less than enabled, it is legacied, deprecated, or disabled
        if (DREM_HUB.getStepState(address(this)) < DataTypes.StepState.Enabled) revert Errors.StepLegaciedDeprecatedOrDisabled();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";

// To Do: Order alphabetically
library DataTypes {
    /////////////////////////////
    ///   Global Data Types   ///
    ////////////////////////////

    // basic step routing information
    struct StepInfo {
        address interactionAddress;
        uint8 parentIndex;
        uint256 windPercent;
        bytes fixedArgData;
    }

    // user expectations for the withdrawal assets (can't check with oracles in worst-case)
    // note: the amount is not being stored or used often, so best to keep it as a uint256 in case users have a ton of a bespoke token
    struct AssetExpectation {
        address assetAddress;
        uint256 amount;
    }

    /**
     *  Unpaused: All protocol actions enabled
     *  Paused: Creation of new trade paused.  Copying and exiting trades still possible.
     *  Frozen: Copying and creating new trades paused.  Exiting trades still possible
     */
    enum ProtocolState {
        Unpaused,
        Paused,
        Frozen
    }

    /**
     *  Disabled: No functionality
     *  Deprecated: Unwind existing strategies
     *  Legacy: Wind and unwind existing strategies
     *  Enabled: Wind, unwind, create new strategies
     */
    enum StepState {
        Disabled,
        Deprecated,
        Legacy,
        Enabled
    }

    ///////////////////////////////////////
    ///   Price Aggregator Data Types   ///
    ///////////////////////////////////////

    enum RateAsset {
        USD,
        ETH
    }

    struct SupportedAssetInfo {
        AggregatorV3Interface aggregator;
        RateAsset rateAsset;
        uint256 units;
    }

    /////////////////////////////////////
    ///   Fee Controller Data Types   ///
    /////////////////////////////////////

    struct FeeInfo {
        uint24 entranceFee;
        uint24 exitFee;
        uint24 performanceFee;
        uint24 managementFee;
        address collector;
    }

    struct FeesPayable {
        uint256 dremFee;
        uint256 adminFee;
    }

    /////////////////////////////////////
    ///   Vault Deployer Data Types   ///
    /////////////////////////////////////

    struct DeploymentInfo {
        address admin;
        string name;
        string symbol;
        address denominationAsset;
        StepInfo[] steps;
        FeeInfo feeInfo;
    }

    //////////////////////////////////
    ///   Global Step Data Types   ///
    //////////////////////////////////

    struct UnwindInfo {
        uint256 sharesRedeemed;
        uint256 totalSupply;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Errors {
    /////////////////////////
    ///   Global Errors   ///
    /////////////////////////

    /**
     *  Asset passed into removeDenominationAssets() is not a denomination asset
     */
    error AssetNotDenominationAsset();

    /**
     *  Asset passed into removeWhitelistedAssets() is not a whitelisted asset
     */
    error AssetNotWhitelisted();

    /**
     *  Asset is not supported (i.e. does not have an aggregator in Price Aggregator)
     */
    error AssetNotSupported();

    /**
     * Empty array
     */
    error EmptyArray();

    /**
     *  Multiple cases...
     */
    error StepNotWhitelisted();

    /**
     *  Input is address(0)
     */
    error ZeroAddress();

    ////////////
    /// Base ///
    ////////////

    /**
     * Msg sender is not hub owner
     */
    error NotHubOwner();

    /**
     * Protocol is paused or frozen
     */
    error ProtocolPausedOrFrozen();

    /**
     * Protocol is frozen
     */
    error ProtocolFrozen();

    //////////////////
    ///  Drem Hub  ///
    //////////////////

    /**
     *  Invalid step parameters passed in
     */
    error InvalidParam();

    /**
     * Passed in Vault Deployer address is not a contract
     */
    error InvalidVaultDeployerAddress();

    /**
     *  'isTradingnAllowed' is set to false
     */
    error TradingDisabled();

    /////////////////
    ///   Vault   ///
    /////////////////

    /**
     * Wind did not create value
     */
    error EndValueLessThanStartValue();

    /**
     * Low level call failed in execute
     */
    error ExecuteCallFailed();

    /**
     * msg.sender is not the Drem Hub
     */
    error MsgSenderIsNotHub();

    /**
     * msg.sender is not a step
     */
    error MsgSenderIsNotStep();

    /**
     * Invalid number of steps
     */
    error InvalidNumberOfSteps();

    /**
     * Step is disabled or not whitelisted
     */
    error InvalidStep();

    /**
     * The initial deposit was too small
     */
    error InsufficcientInitialDeposit();

    /**
     * Steps array and args array is not the same length
     */
    error StepsAndArgsNotSameLength();

    error EmptyFixedArgData();

    error UntrackedStep();
    /**
     * int too big & too small (need room for cumulative mappings)
     */
    error TooManyShares();
    error TooFewShares();

    error ValueTooLarge();

    /**
     * Not the vault admin
     */
    error NotVaultAdmin();

    // Fee Controller

    /**
     * Invalid Fee (more than the decimals)
     */
    error InvalidFee();

    /**
     * Invalid collector (address(0))
     */
    error InvalidCollector();

    /**
     * Fees have already been set (cannot change after setting)
     */
    error FeesAlreadySet();

    ////////////////////////////
    ///   Price Aggregator   ///
    ////////////////////////////

    /**
     * Answer from Chainlink Oracle is <= 0
     */
    error InvalidAggregatorRate();

    /**
     * Total conversion comes out to zero
     */
    error InvalidConversion();

    /**
     *  Asset, aggregator, and rate asset arrays do not match in length
     */
    error InvalidAssetArrays();

    /**
     * Input ammounts and input asset arrays do not match in length
     */
    error InvalidInputArrays();

    /**
     * Output asset is not supported
     */
    error InvalidOutputAsset();

    /**
     * USD rate is stale (updated at more than 30 seconds ago)
     */
    error StaleUSDRate();

    /**
     * ETH rate is stale (updated at more than 24 hours ago)
     */
    error StaleEthRate();

    ////////////////////////////
    ///    Asset Registry    ///
    ////////////////////////////

    /**
     *  Asset passed into addDenominationAssets() is already a denomination asset
     */
    error AssetAlreadyDenominationAsset();

    /**
     *  Asset passed into whitelistAssets() is already a whitelisted asset
     */
    error AssetAlreadyWhitelisted();

    ////////////////////////////////
    ///    Global Step Errors    ///
    ////////////////////////////////

    /**
     * The approval of a token amount failed when calling vault.execute() from a step
     */
    error ApprovalFailed();

    /**
     *  Initialization of step used invalid index for the step's position
     */
    error InvalidStepPosition();

    /**
     *  The vault balance percent, which is used to determine what % of the vault's balance
     *  to use for the step, is invalid (i.e. 0 or > PRECISION_FACTOR)
     */
    error InvalidVaultBalancePercent();

    /**
     * Step is disabled
     */
    error StepDisabled();

    /**
     * Step is deprecated or disabled
     */
    error StepDeprecatedOrDisabled();

    /**
     * Step is legacied, deprecated or disabled
     */
    error StepLegaciedDeprecatedOrDisabled();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {DataTypes} from "../libraries/DataTypes.sol";
import {IPriceAggregator} from "./IPriceAggregator.sol";

interface IAssetRegistry {
    /////////////////////////////
    ///     View Functions    ///
    /////////////////////////////

    /**
     * @notice returns whether or not an asset is a denomination asset
     * @param _asset the asset
     * @return true if whitelisted, denomination asset, and supported in Price Aggregator, false if not
     */
    function isAssetDenominationAsset(address _asset) external view returns (bool);

    /**
     * @notice returns whether or not an asset is whitelisted
     * @param _asset the asset
     * @return true if whitelisted and supported in price aggregator, false if not
     */
    function isAssetWhitelisted(address _asset) external view returns (bool);

    /**
     * @notice returns all denomination assets
     * @return address array containing all denomination assets
     */
    function getDenominationAssets() external view returns (address[] memory);

    /**
     * @notice returns all whitelisted assets
     * @return address array containing all whitelisted assets
     */
    function getWhitelistedAssets() external view returns (address[] memory);

    /**
     * @notice built in getter by Solidity for the price aggregator contract
     */
    function PRICE_AGGREGATOR() external view returns (IPriceAggregator);

    ////////////////////
    ///     Admin    ///
    ////////////////////

    /**
     * @dev Admin function to add denomination assets. Only callable by the Hub Owner
     * @param _denominationAssets the denomination assets to add
     */
    function addDenominationAssets(address[] calldata _denominationAssets) external;

    /**
     * @dev Admin function to remove denomination assets
     * @param _denominationAssets the denomination assets to remove
     */
    function removeDenominationAssets(address[] calldata _denominationAssets) external;

    /**
     * @dev Admin function to whitelist assets
     * @param _assets the assets to whitelist
     */
    function addWhitelistedAssets(address[] calldata _assets) external;

    /**
     * @dev Admin function to remove whitelisted assets
     * @param _assets the assets to remove
     */
    function removeWhitelistedAssets(address[] calldata _assets) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Reference: https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/ISwapRouter.sol
interface IUniV3SwapRouter {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Reference: https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/INonfungiblePositionManager.sol

interface IUniV3NonFungiblePositionManager {
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(MintParams calldata params)
        external
        payable
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

interface IVault is IERC20Upgradeable, IERC721Receiver, IERC1155Receiver {
    // constants
    function MAX_STEPS() external view returns (uint256);
    function MIN_SHARES() external view returns (uint256);
    function MAX_SHARES() external view returns (uint256);
    function DECIMAL_SHARE_BUFFER() external view returns (uint256);
    function MAX_VALUE() external view returns (uint256);

    // steps and assets
    function getAdmin() external view returns (address);
    function getDenominationAsset() external view returns (address);
    function getTotalSteps() external view returns (uint256);
    function getSteps() external view returns (address[] memory);

    // share information (for fees)
    function cumulativePaid(address) external view returns (uint256);
    function cumulativeTime(address) external view returns (uint256);
    function totalValue() external view returns (uint256);
    function stakeValue(address investor) external view returns (uint256);

    // init
    function init(
        address _admin,
        string memory _name,
        string memory _symbol,
        address _denominationAsset,
        DataTypes.StepInfo[] calldata _steps,
        DataTypes.FeeInfo calldata _feeInfo
    ) external;

    function windSteps(uint256 amountIn, bytes[] calldata _variableDataPerStep) external;

    function unwindSteps(uint256 sharesRedeemed, bytes[] calldata _variableDataPerStep) external;

    // executing transactions (for steps to access)
    function execute(address to, bytes memory data) external returns (bytes memory);

    // safegaurding funds
    function withdraw(uint256 shareAmount, DataTypes.AssetExpectation[] calldata expectations) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

// Modified from: https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/Path.sol

/**
 * Change log:
 *  - Changed constants from private to internal
 *  - TO DO: Delete getFirstPool(), skipToken(), and decodeFirstPool() once tests are finished
 */

import {BytesLib} from "../../../../libraries/BytesLib.sol";

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;

    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns the number of pools in the path
    /// @param path The encoded swap path
    /// @return The number of pools in the path
    function numPools(bytes memory path) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path) internal pure returns (address tokenA, address tokenB, uint24 fee) {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// Dependencies
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// src
import {BytesLib} from "../../../libraries/BytesLib.sol";
import {DataTypes} from "../../../libraries/DataTypes.sol";
import {Errors} from "../../../libraries/Errors.sol";
import {IAssetRegistry} from "../../../interfaces/IAssetRegistry.sol";
import {IUniV3SwapRouter} from "../../../interfaces/steps/IUniV3SwapRouter.sol";
import {IVault} from "../../../interfaces/IVault.sol";
import {Path} from "./library/Path.sol";

library UniswapV3Lib {
    using BytesLib for bytes;

    /**
     * The addresses for the Uniswap V3 Swap Router are the same across testnets, mainnet,
     * Polygon, Arbitrum, and Optimism.  These values will need to be manually reset when
     * redeploying the protocol in the future
     */
    // Reference: https://docs.uniswap.org/contracts/v3/reference/deployments
    address internal constant UNIV3_SWAP_ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    uint256 internal constant PRECISION_FACTOR = 10_000;

    /// @dev The following errors are used both by the Swap step and Liquidity step
    /**
     * Block.timestamp is greater than the deadline passed in from the encoded variable args 
     */
    error InvalidDeadline();
    /**
     * The passed in Uniswap fee is invalid: it is not 100, 500, 3_000, or 10_000, i.e. 0.01%, 0.05%, 0.3% or 1.0%
     */
    error InvalidUniFee();
    /**
     * The amount out minimum passed in from the encoded variable args is zero
     */
    error InvalidAmountOutMinimum();

    ////////////////////
    ///     Swap     ///
    ////////////////////
    event InitSwap(address indexed vault, uint256 stepIndex, address tokenIn, address tokenOut);
    event Swap(address indexed caller, address indexed vault, address tokenOut, uint256 amountOut);

    struct SwapFixedData {
        bytes path;
        bytes reversedPath;
    }

    struct SwapVariableData {
        uint256 amountOutMinimum;
        uint256 deadline;
    }

    ////////////////////////
    ///     Liquidity    ///
    ////////////////////////

    /**
     * MIN_TICK and MAX_TICK are constants from Uniswap V3's TickMath.sol
     * Reference: https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/TickMath.sol
     */
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    error InvalidAmountDesired();
    error InvalidAmountMin();
    error InvalidTick();
    error InvalidTokens();

    event InitLiquidityProvision(address indexed vault, uint256 stepIndex, address token0, address token1);
    event MintedUniPosition(address indexed caller, address indexed vault, uint256 indexed tokenId, uint256 liquidity);

    struct LiquidityProvisionFixedData {
        address inputToken;
        uint24 uniFee;
        int24 tickLower;
        int24 tickUpper;
        uint256 nftTokenId; // Set on the initial wind...
        bytes swapPath;
    }

    struct LiquidityProvisionVariableData {
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    ////////////////////////
    ///     Functions    ///
    ////////////////////////

    /// The following functions are used by both the swap step and liquidity step
    function reverseSwapPath(bytes memory _path) internal pure returns (bytes memory) {
        uint256 numPools = Path.numPools(_path);

        // Start with tokenOut as tokenIn for the reversed path
        address tokenOut = _path.toAddress(Path.NEXT_OFFSET * numPools);
        bytes memory reversedPath = abi.encodePacked(tokenOut);

        // Iteratively add the fee and token for each pool to the reversed path
        for (uint256 i; i < numPools;) {
            // Start towards the end of _path. Token out is already accounted for, so need to start at the last offset
            uint256 reversedOffset = (numPools - i - 1) * Path.NEXT_OFFSET;

            // Get the token and fee from the path
            address token = _path.toAddress(reversedOffset);
            uint24 uniFee = _path.toUint24(reversedOffset + Path.ADDR_SIZE);

            // Add the uni fee first then the token to construct the correct reversed path
            reversedPath = reversedPath.concat(abi.encodePacked(uniFee, token));

            unchecked {
                ++i;
            }
        }

        return reversedPath;
    }
    
    function swapExactInput(
        IAssetRegistry _assetRegistry,
        address _caller,
        uint256 _amountIn,
        UniswapV3Lib.SwapVariableData memory _variableArgs,
        bytes memory _path
    ) internal returns (uint256) {
        // Validate variable args
        validateSwapVariableData(_variableArgs);

        // Cache the path and validate
        address tokenOut = validateSwapPath(_assetRegistry, _path);

        // Approve the swap router
        address tokenIn = _path.toAddress(0);

        approveSwapRouter(tokenIn, _amountIn);

        IUniV3SwapRouter.ExactInputParams memory params = IUniV3SwapRouter.ExactInputParams({
            path: _path,
            recipient: msg.sender,
            deadline: _variableArgs.deadline,
            amountIn: _amountIn,
            amountOutMinimum: _variableArgs.amountOutMinimum
        });

        bytes memory encodedSwapParams = abi.encodeWithSelector(IUniV3SwapRouter.exactInput.selector, params);

        // Amount out is already validated by UNI
        // Reference: https://github.com/Uniswap/v3-periphery/blob/6cce88e63e176af1ddb6cc56e029110289622317/contracts/SwapRouter.sol#L128
        bytes memory returnData = IVault(msg.sender).execute(UniswapV3Lib.UNIV3_SWAP_ROUTER_ADDRESS, encodedSwapParams);
        (uint256 amountOut) = abi.decode(returnData, (uint256));

        emit UniswapV3Lib.Swap(_caller, msg.sender, tokenOut, amountOut);

        return amountOut;
    }

    function approveSwapRouter(address _tokenIn, uint256 _amount) internal {
        bytes memory encodedApprovalParams =
            abi.encodeWithSelector(IERC20.approve.selector, UniswapV3Lib.UNIV3_SWAP_ROUTER_ADDRESS, _amount);
        bytes memory returnData = IVault(msg.sender).execute(_tokenIn, encodedApprovalParams);
        bool approvalSuccess = (returnData.length == 0 || abi.decode(returnData, (bool)));

        // Revert if the approval did not execute correctly
        if (!(approvalSuccess)) revert Errors.ApprovalFailed();
    }

    function validateUniFee(uint24 _uniFee) internal pure {
        if ((_uniFee != 100) && (_uniFee != 500) && (_uniFee != 3_000) && (_uniFee != 10_000)) {
            revert InvalidUniFee();
        }
    }

    function validateSwapPath(IAssetRegistry _assetRegistry, bytes memory _path) internal view returns (address) {
        uint256 numPools = Path.numPools(_path);

        // Validates all pools in the path except token out
        for (uint256 i; i < numPools;) {
            uint256 offset = i * Path.NEXT_OFFSET;

            address token = _path.toAddress(offset);
            uint24 uniFee = _path.toUint24(offset + Path.ADDR_SIZE);

            // address(0) will never be whitelisted
            if (!(_assetRegistry.isAssetWhitelisted(token))) revert Errors.AssetNotWhitelisted();
            validateUniFee(uniFee);
            
            unchecked {
                ++i;
            }
        }

        address tokenOut = _path.toAddress(Path.NEXT_OFFSET * numPools);
        if (!(_assetRegistry.isAssetWhitelisted(tokenOut))) revert Errors.AssetNotWhitelisted();

        return tokenOut;
    }

    function validateSwapVariableData(SwapVariableData memory _variableArgs) internal view {
        if (_variableArgs.amountOutMinimum == 0) {
            revert InvalidAmountOutMinimum();
        }
        if (_variableArgs.deadline < block.timestamp) revert UniswapV3Lib.InvalidDeadline();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

interface IPriceAggregator {
    /////////////////////////////
    ///     View Functions    ///
    /////////////////////////////

    /**
     * @notice Converts given amounts of input assets into an output asset
     * @param _inputAmounts the amounts of the input assets to convert
     * @param _inputAssets the input assets
     * @param _outputAsset the output asset
     * @return the output amount denominated in the output asset
     */
    function convertAssets(uint256[] calldata _inputAmounts, address[] calldata _inputAssets, address _outputAsset)
        external
        view
        returns (uint256);

    /**
     * @notice Converts amount of an input asset into an output asset
     * @param _inputAmount the amount of the input asset to convert
     * @param _inputAsset the input asset
     * @param _outputAsset the output asset
     * @return the output amount denominated in the output asset
     */
    function convertAsset(uint256 _inputAmount, address _inputAsset, address _outputAsset)
        external
        view
        returns (uint256);

    /**
     * @notice returns the ETH to USD aggregator
     * @return the ETH to USD aggregator as an AggregatorV3Interface
     */
    function ETH_TO_USD_AGGREGATOR() external view returns (AggregatorV3Interface);

    /**
     * @notice Returns whether or not an asset is supported
     * @return returns true if an asset is supported, false otherwise
     */
    function isAssetSupported(address _asset) external view returns (bool);

    /**
     * @notice Returns the supported asset's aggregator, rate asset, and units
     * @param _asset the asset to get the info for
     * @return the supported asset info
     */
    function getSupportedAssetInfo(address _asset) external view returns (DataTypes.SupportedAssetInfo memory);

    ////////////////////
    ///     Admin    ///
    ////////////////////
    /**
     * @dev Admin function to add supported assets
     * @param _assets the addresses of the supported assets to add
     * @param _aggregators the addresses of the aggregators corresponding to each asset
     * @param _rateAssets the rate assets for the corresponding aggregators
     */
    function addSupportedAssets(
        address[] calldata _assets,
        AggregatorV3Interface[] calldata _aggregators,
        DataTypes.RateAsset[] calldata _rateAssets
    ) external;

    /**
     * @dev Admin function to remove supported assets
     * @param _assets the addresses of the supported assets to remove
     */
    function removeSupportedAssets(address[] calldata _assets) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IStep {
    // initialize the step (unknown amount of bytes --> must be decoded)
    function init(uint256 stepIndex, bytes calldata fixedArgs) external;

    // wind and unwind the step to move forwards and backwards
    function wind(address caller, uint256 argIndex, uint256 amountIn, bytes memory variableArgs)
        external
        returns (uint256);

    function unwind(address caller, uint256 argIndex, uint256 amountIn, bytes memory variableArgs)
        external
        returns (uint256);

    // get the value based on the step's interactions
    function value(uint256 stepNodeKey, uint256 tokensProduced, address denominationAsset) external view returns (uint256);

    function assetIn(uint256 stepNodeKey, address vault) external view returns (address);

    function assetOut(uint256 stepNodeKey, address vault) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../libraries/Errors.sol";
import {HubAware} from "./HubAware.sol";

abstract contract HubOwnable is HubAware {
    constructor(address _dremHub) HubAware(_dremHub) {}

    modifier onlyHubOwner() {
        _validateMsgSenderHubOwner();
        _;
    }

    function _validateMsgSenderHubOwner() internal view {
        if (msg.sender != DREM_HUB.owner()) revert Errors.NotHubOwner();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IDremHub} from "../interfaces/IDremHub.sol";
import {DremHub} from "../core/DremHub.sol";
import {Errors} from "../libraries/Errors.sol";

abstract contract HubAware {
    DremHub public immutable DREM_HUB;

    constructor(address _hub) {
        if (_hub == address(0)) revert Errors.ZeroAddress();
        DREM_HUB = DremHub(_hub);
    }
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
pragma solidity ^0.8.10;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IDremHub {
    /////////////////////////////
    ///     View Functions    ///
    /////////////////////////////

    /**
     * @notice Transfer hook used by DremERC20s. Reverts transfers if trading is disabled or the protocol state is frozen
     */
    function dremHubBeforeTransferHook() external view;

    /**
     * @notice Checks if a step is whitelisted
     * @param _step the address of the step
     * @return returns true if the step is whitelisted. False otherwise
     */
    function isStepWhitelisted(address _step) external view returns (bool);

    /**
     * @notice Returns the Drem protocol's state
     * @return the protocol state
     */
    function getProtocolState() external view returns (DataTypes.ProtocolState);

    /**
     * @notice Returns a step's state
     * @param _step the address of the step
     * @return the step state
     */
    function getStepState(address _step) external view returns (DataTypes.StepState);

    // price aggregator
    function priceAggregator() external view returns (address);

    ////////////////////
    ///     Admin    ///
    ////////////////////

    /**
     * @dev Admin function to add a whitelisted step. Sets the step's state to enabled
     * @param _step the address of the step to add
     */
    function addWhitelistedStep(address _step) external;

    /**
     * @dev Admin function to remove a whitelisted step. Set's the step's state to disabled
     * @param _step the address of the step to disable
     */
    function removeWhitelistedStep(address _step) external;

    /**
     * @dev Admin function to enable or disable trading of Vault ERC20s
     * @param _isTradingAllowed the new setting for global trading
     */
    function setGlobalTrading(bool _isTradingAllowed) external;

    /**
     * @dev Admin function to set the protocol's state
     * @param _state the new setting of the protocol's state
     */
    function setProtocolState(DataTypes.ProtocolState _state) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable2StepUpgradeable} from "@openzeppelin-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IDremHub} from "../interfaces/IDremHub.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";

/**
 *  Invariants:
 *  - If an address is not whitelisted, it should have a disabled step state
 *  - Only whitelisted addresses can have a step state that is not disabled
 */

// Initializable is inherited from Ownable2StepUpgradeable
contract DremHub is Ownable2StepUpgradeable, UUPSUpgradeable, IDremHub {
    // just checking if it is a drem-verified step contract
    mapping(address => bool) private whitelistedSteps;
    mapping(address => DataTypes.StepState) private stepToStepState;

    bool private isTradingAllowed;
    address private vaultDeployer;
    DataTypes.ProtocolState private protocolState;

    // keep the price aggregator here, so we don't need to store it in every vault
    address public priceAggregator;
    address public assetRegistry;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;

    constructor() {
        _disableInitializers();
    }

    function init() external initializer {
        __Ownable2Step_init();
        // Technically unnecessary but good practice...
        __UUPSUpgradeable_init();
    }

    /**
     * @dev Admin function to enable or disable trading of Vault ERC20s
     * @param _isTradingAllowed the new setting for global trading
     */
    function setGlobalTrading(bool _isTradingAllowed) external onlyOwner {
        isTradingAllowed = _isTradingAllowed;
        emit Events.GlobalTradingSet(_isTradingAllowed);
    }

    /**
     * @dev Admin function to add a whitelisted step. Sets the step's state to enabled
     * @param _step the address of the step to add
     */
    function addWhitelistedStep(address _step) external onlyOwner {
        _setWhitelistedStep(_step, true);
        _setStepState(_step, DataTypes.StepState.Enabled);
        emit Events.WhitelistedStepAdded(_step);
    }

    /**
     * @dev Admin function to remove a whitelisted step. Set's the step's state to disabled
     * @param _step the address of the step to disable
     */
    function removeWhitelistedStep(address _step) external onlyOwner {
        _setWhitelistedStep(_step, false);
        _setStepState(_step, DataTypes.StepState.Disabled);
        emit Events.WhitelistedStepRemoved(_step);
    }

    /**
     * @dev Admin function to set a step's state
     * @param _step the address of the step
     */
    function setStepState(address _step, DataTypes.StepState _setting) external onlyOwner {
        if (!(_isStepWhitelisted(_step))) revert Errors.StepNotWhitelisted();
        _setStepState(_step, _setting);
    }

    // Unpaused: Anything is possible!
    // Paused: Deposits and withdrawls enabled. No new trades can be opened
    // Frozen: New trades and deposits are disabled.  Withdraws enabled

    /**
     * @dev Admin function to set the protocol's state
     * @param _state the new setting of the protocol's state
     */
    function setProtocolState(DataTypes.ProtocolState _state) external onlyOwner {
        protocolState = _state;
        emit Events.ProtocolStateSet(_state);
    }

    ////////////////////////////////
    ///     Internal Function    ///
    ////////////////////////////////
    function _isStepWhitelisted(address _step) internal view returns (bool) {
        return whitelistedSteps[_step];
    }

    function _setStepState(address _step, DataTypes.StepState _setting) internal {
        stepToStepState[_step] = _setting;
        emit Events.StepStateSet(_step, _setting);
    }

    function _setWhitelistedStep(address _step, bool _setting) internal {
        whitelistedSteps[_step] = _setting;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /////////////////////////////
    ///     View Functions    ///
    /////////////////////////////

    /**
     * @notice Transfer hook used by DremERC20s. Reverts transfers if trading is disabled or the protocol state is frozen
     */
    function dremHubBeforeTransferHook() external view {
        if ((!(isTradingAllowed)) || protocolState == DataTypes.ProtocolState.Frozen) revert Errors.TradingDisabled();
    }

    /**
     * @notice Checks if a step is valid
     * @param _step the address of the step
     * @return returns true if the step is whitelisted and the step's state is not disabled. False otherwise
     */
    function isValidStep(address _step) external view returns (bool) {
        return _isStepWhitelisted(_step) && (stepToStepState[_step] != DataTypes.StepState.Disabled);
    }

    /**
     * @notice Checks if a step is whitelisted
     * @param _step the address of the step
     * @return returns true if the step is whitelisted. False otherwise
     */
    function isStepWhitelisted(address _step) external view returns (bool) {
        return _isStepWhitelisted(_step);
    }

    /**
     * @notice Returns the Drem protocol's state
     * @return the protocol state
     */
    function getProtocolState() external view returns (DataTypes.ProtocolState) {
        return protocolState;
    }

    /**
     * @notice Returns a step's state
     * @param _step the address of the step
     * @return the step state
     */
    function getStepState(address _step) external view returns (DataTypes.StepState) {
        return stepToStepState[_step];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {DataTypes} from "./DataTypes.sol";

library Events {
    /////////////////////////////
    //     Drem Hub Events     //
    /////////////////////////////

    /**
     * @dev Emitted when global trading is set
     * @param setting the new setting
     */
    event GlobalTradingSet(bool setting);

    /**
     * @dev Emitted when protocol state is set
     * @param state the new protocol state
     */
    event ProtocolStateSet(DataTypes.ProtocolState state);

    /**
     * @dev Emitted when a step's state is set
     */
    event StepStateSet(address indexed step, DataTypes.StepState setting);

    /**
     * @dev Emitted when whitelisted step is added
     * @param interactionAddress the contract address associated with the step
     */
    event WhitelistedStepAdded(address interactionAddress);

    /**
     * @dev Emitted when whitelisted step is removed
     * @param interactionAddress the contract address associated with the step
     */
    event WhitelistedStepRemoved(address interactionAddress);

    /////////////////////////////////////
    //     Price Aggregator Events     //
    /////////////////////////////////////
    /**
     * @dev Emitted when the EthToUSDAggregator is reset
     * @param ethToUSDAggregator the newly set aggregator
     */
    event EthToUSDAggregatorSet(AggregatorV3Interface ethToUSDAggregator);

    /**
     *
     */
    event SupportedAssetAdded(address indexed asset, AggregatorV3Interface aggregator, DataTypes.RateAsset rateAsset);

    /**
     *
     */
    event SupportedAssetRemoved(address indexed asset, AggregatorV3Interface aggregator, DataTypes.RateAsset rateAsset);

    ///////////////////////////////////
    //     Asset Registry Events     //
    ///////////////////////////////////
    event DenominationAssetsAdded(address[] denominationAssets);
    event DenominationAssetsRemoved(address[] denominationAssets);
    event WhitelistedAssetsAdded(address[] whitelistedAssets);
    event WhitelistedAssetsRemoved(address[] whitelistedAssets);

    ///////////////////////////////////
    //     Fee Controller Events     //
    ///////////////////////////////////
    /**
     * @dev Emitted when the Drem fees are collected from the fee collector
     * @param asset the asset the fees were collected in
     * @param amount the amount of fees collected
     */
    event DremFeesCollected(address indexed asset, uint256 amount);

    /**
     * @dev Emitted when the Drem fees are set
     * @param stepLen the corresponding step length for the drem fees
     * @param dremEntranceFee the new drem entrance fee
     * @param dremExitFee the new drem exit fee
     * @param dremPerformanceFee the new drem performance fee
     * @param dremManagementFee the new drem management fee
     */
    event DremFeesSet(
        uint256 indexed stepLen,
        uint24 dremEntranceFee,
        uint24 dremExitFee,
        uint24 dremPerformanceFee,
        uint24 dremManagementFee
    );

    /**
     * @dev Emitted when the max vault fees are set
     * @param maxEntranceFee the new max entrance fee
     * @param maxExitFee the new max exit fee
     * @param maxPerformanceFee the new max performance fee
     * @param maxManagementFee the new max management fee
     */
    event MaxVaultFeesSet(uint24 maxEntranceFee, uint24 maxExitFee, uint24 maxPerformanceFee, uint24 maxManagementFee);

    /**
     * @dev Emitted when the vault fees are set during initialization
     * @param vault the vault the fees are being set for
     * @param entranceFee the entrance fee
     * @param exitFee the exit fee
     * @param performanceFee the performance fee
     * @param managementFee the management fee
     */
    event VaultFeesSet(
        address indexed vault, uint24 entranceFee, uint24 exitFee, uint24 performanceFee, uint24 managementFee
    );

    /**
     * @dev Emitted when the vault collector is set after initialization
     * @param vault the vault the collector is being set for
     * @param collector the new collector
     */
    event VaultCollectorSet(address vault, address collector);

    ///////////////////////////////////
    //     Vault Deployer Events     //
    ///////////////////////////////////
    event VaultDeployed(address indexed creator, address vault, string name, string symbol);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}