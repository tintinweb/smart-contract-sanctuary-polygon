/**
 *Submitted for verification at polygonscan.com on 2022-03-06
*/

// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.12;

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)
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

// File: @tokensets/interfaces/ISetToken.sol

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

/**
 * @title ISetToken
 * @author Set Protocol
 *
 * Interface for operating with SetTokens.
 */
interface ISetToken is IERC20 {

    /* ============ Enums ============ */

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    /* ============ Structs ============ */
    /**
     * The base definition of a SetToken Position
     *
     * @param component           Address of token in the Position
     * @param module              If not in default state, the address of associated module
     * @param unit                Each unit is the # of components per 10^18 of a SetToken
     * @param positionState       Position ENUM. Default is 0; External is 1
     * @param data                Arbitrary data
     */
    struct Position {
        address component;
        address module;
        int256 unit;
        uint8 positionState;
        bytes data;
    }

    /**
     * A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and 
     * virtual units.
     *
     * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency
     *                                  updating all units at once via the position multiplier. Virtual units are achieved
     *                                  by dividing a "real" value by the "positionMultiplier"
     * @param componentIndex            
     * @param externalPositionModules   List of external modules attached to each external position. Each module
     *                                  maps to an external position
     * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
      int256 virtualUnit;
      address[] externalPositionModules;
      mapping(address => ExternalPosition) externalPositions;
    }

    /**
     * A struct that stores a component's external position details including virtual unit and any
     * auxiliary data.
     *
     * @param virtualUnit       Virtual value of a component's EXTERNAL position.
     * @param data              Arbitrary data
     */
    struct ExternalPosition {
      int256 virtualUnit;
      bytes data;
    }


    /* ============ Functions ============ */
    
    function addComponent(address _component) external;
    function removeComponent(address _component) external;
    function editDefaultPositionUnit(address _component, int256 _realUnit) external;
    function addExternalPositionModule(address _component, address _positionModule) external;
    function removeExternalPositionModule(address _component, address _positionModule) external;
    function editExternalPositionUnit(address _component, address _positionModule, int256 _realUnit) external;
    function editExternalPositionData(address _component, address _positionModule, bytes calldata _data) external;

    function invoke(address _target, uint256 _value, bytes calldata _data) external returns(bytes memory);

    function editPositionMultiplier(int256 _newMultiplier) external;

    function mint(address _account, uint256 _quantity) external;
    function burn(address _account, uint256 _quantity) external;

    function lock() external;
    function unlock() external;

    function addModule(address _module) external;
    function removeModule(address _module) external;
    function initializeModule() external;

    function setManager(address _manager) external;

    function manager() external view returns (address);
    function moduleStates(address _module) external view returns (ModuleState);
    function getModules() external view returns (address[] memory);
    
    function getDefaultPositionRealUnit(address _component) external view returns(int256);
    function getExternalPositionRealUnit(address _component, address _positionModule) external view returns(int256);
    function getComponents() external view returns(address[] memory);
    function getExternalPositionModules(address _component) external view returns(address[] memory);
    function getExternalPositionData(address _component, address _positionModule) external view returns(bytes memory);
    function isExternalPositionModule(address _component, address _module) external view returns(bool);
    function isComponent(address _component) external view returns(bool);
    
    function positionMultiplier() external view returns (int256);
    function getPositions() external view returns (Position[] memory);
    function getTotalComponentRealUnits(address _component) external view returns(int256);

    function isInitializedModule(address _module) external view returns(bool);
    function isPendingModule(address _module) external view returns(bool);
    function isLocked() external view returns (bool);
}

// File: @tokensets/interfaces/ISetValuer.sol

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

interface ISetValuer {
    function calculateSetTokenValuation(ISetToken _setToken, address _quoteAsset) external view returns (uint256);
}

// File: @tokensets/interfaces/IController.sol

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

interface IController {
    function addSet(address _setToken) external;
    function feeRecipient() external view returns(address);
    function getModuleFee(address _module, uint256 _feeType) external view returns(uint256);
    function isModule(address _module) external view returns(bool);
    function isSet(address _setToken) external view returns(bool);
    function isSystemContract(address _contractAddress) external view returns (bool);
    function resourceId(uint256 _id) external view returns(address);
}

// File: ./interfaces/IIntegrationRegistry.sol

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

interface IIntegrationRegistry {
    function addIntegration(address _module, string memory _id, address _wrapper) external;
    function getIntegrationAdapter(address _module, string memory _id) external view returns(address);
    function getIntegrationAdapterWithHash(address _module, bytes32 _id) external view returns(address);
    function isValidIntegration(address _module, string memory _id) external view returns(bool);
}

// File: ./interfaces/IPriceOracle.sol

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

/**
 * @title IPriceOracle
 * @author Set Protocol
 *
 * Interface for interacting with PriceOracle
 */
interface IPriceOracle {

    /* ============ Functions ============ */

    function getPrice(address _assetOne, address _assetTwo) external view returns (uint256);
    function masterQuoteAsset() external view returns (address);
}

// File: @tokensets/ResourceIdentifier.sol

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

/**
 * @title ResourceIdentifier
 * @author Set Protocol
 *
 * A collection of utility functions to fetch information related to Resource contracts in the system
 */
library ResourceIdentifier {

    // IntegrationRegistry will always be resource ID 0 in the system
    uint256 constant internal INTEGRATION_REGISTRY_RESOURCE_ID = 0;
    // PriceOracle will always be resource ID 1 in the system
    uint256 constant internal PRICE_ORACLE_RESOURCE_ID = 1;
    // SetValuer resource will always be resource ID 2 in the system
    uint256 constant internal SET_VALUER_RESOURCE_ID = 2;

    /* ============ Internal ============ */

    /**
     * Gets the instance of integration registry stored on Controller. Note: IntegrationRegistry is stored as index 0 on
     * the Controller
     */
    function getIntegrationRegistry(IController _controller) internal view returns (IIntegrationRegistry) {
        return IIntegrationRegistry(_controller.resourceId(INTEGRATION_REGISTRY_RESOURCE_ID));
    }

    /**
     * Gets instance of price oracle on Controller. Note: PriceOracle is stored as index 1 on the Controller
     */
    function getPriceOracle(IController _controller) internal view returns (IPriceOracle) {
        return IPriceOracle(_controller.resourceId(PRICE_ORACLE_RESOURCE_ID));
    }

    /**
     * Gets the instance of Set valuer on Controller. Note: SetValuer is stored as index 2 on the Controller
     */
    function getSetValuer(IController _controller) internal view returns (ISetValuer) {
        return ISetValuer(_controller.resourceId(SET_VALUER_RESOURCE_ID));
    }
}

// File: TokenPriceManager.sol

library SpecialMath {
    error MathOverflow();

    // Multiplication technique by Remco Bloemen.
    // https://medium.com/wicketh/mathemagic-full-multiply-27650fec525d
    function safeMul(uint256 x, uint256 y) internal pure returns (uint256 r0) {
        uint256 r1;
        assembly {
            let mm := mulmod(x, y, not(0))
            r0 := mul(x, y)
            r1 := sub(sub(mm, r0), lt(mm, r0))
        }
        if (r1 != 0) revert MathOverflow();
    }
}

/// @title Price maintainer for arbitrary tokens
/// @author Peter T. Flynn
/// @notice Maintains a common interface for requesting the price of the given token, with special functionality for TokenSets.
/// @dev Contract must be initialized before use. Price should always be requested using getPrice(bool), rather than viewing the [price] variable. Price returned is dependent on the transactor's SWD balance. Constants require adjustment for deployment outside Polygon.
contract TokenPriceManager {
    using ResourceIdentifier for IController;

    // Storing small variables within a single slot to save gas.
    struct Slot0 {
        // Current owner
        address owner;
        // Balance of SWD required before getPrice() returns spot
        uint80 swdThreshold;
        // Buy/sell spread (in tenths of a percent)
        uint8 pricePercentFeeSpread;
        // Whether [tokenPrimary] is a TokenSet or not
        bool isTokenset;
    }

    address constant SWD = 0xaeE24d5296444c007a532696aaDa9dE5cE6caFD0;
    IController constant TOKENSET_CONTROLLER =
        IController(0x75FBBDEAfE23a48c0736B2731b956b7a03aDcfB2);

    /// @notice Gas-saving storage slot
    Slot0 public slot0;
    /// @notice New owner for ownership transfer
    /// @dev May contain the max address for unlocking contract destruction
    address public ownerNew;
    /// @notice Timestamp for ownership transfer timeout
    uint256 public ownerTransferTimeout;
    /// @notice Address of the token to be priced
    address public immutable tokenPrimary;
    /// @notice Token address that denominates the primary token's pricing (ex. USDC/wETH)
    /// @dev In the vast majority of cases, USDC is recommended. Using a token with no TokenSet oracle coverage is not supported, and will result in undefined behavior.
    address public immutable tokenDenominator;
    /// @notice Internal variable used for price tracking
    uint256 public price;
    /// @notice Timestamp timeout for allowing large price changes
    uint256 public priceOverride;

    /// @notice Emitted when the contract is created
    /// @param sender The contract creator
    /// @param primary The token configured as [tokenPrimary]
    /// @param denominator The token configured as [tokenDenominator]
    event ContractCreation(
        address indexed sender,
        address primary,
        address denominator
    );
    /// @notice Emitted when the price is manually changed
    /// @param sender The transactor
    /// @param _price The new price
    event SetPrice(address indexed sender, uint256 _price);
    /// @notice Emitted when the price override is engaged
    /// @param sender The transactor
    /// @param endTime The timestamp when the override expires
    event SetPriceOverride(address indexed sender, uint256 endTime);
    /// @notice Emitted when the buy/sell fee is changed
    /// @param sender The transactor
    /// @param fee The new fee
    event SetPriceFeeSpread(address indexed sender, uint8 fee);
    /// @notice Emitted when primary token's TokenSet status is changed
    /// @param sender The transactor
    /// @param _isTokenset The new TokenSet status
    event SetTokenset(address indexed sender, bool _isTokenset);
    /// @notice Emitted when the SWD threshold is changed
    /// @param sender The transactor
    /// @param threshold The new SWD threshold
    event SetSwdThreshold(address indexed sender, uint80 threshold);
    /// @notice Emitted when an ownership transfer has been initiated
    /// @param sender The transactor
    /// @param newOwner The address designated as the potential new owner
    event OwnerTransfer(address indexed sender, address newOwner);
    /// @notice Emitted when an ownership transfer is confirmed
    /// @param sender The transactor, and new owner
    /// @param oldOwner The old owner
    event OwnerConfirm(address indexed sender, address oldOwner);
    /// @notice Emitted when a mis-sent token is rescued from the contract
    /// @param sender The transactor
    /// @param token The token rescued
    event WithdrawToken(address indexed sender, address indexed token);
    /// @notice Emitted when the contract is destroyed
    /// @param sender The transactor
    event SelfDestruct(address sender);
    /// @notice Emitted when an unauthorized transaction is attempted
    /// @param sender The transactor
    /// @param origin The transaction's origin
    event UnauthorizedAttempt(address indexed sender, address indexed origin);

    /// @notice Returned when the sender is not authorized to call a specific function
    error Unauthorized();
    /// @notice Returned when the contract has not been initialized
    error NotInitialized();
    /// @notice Returned when one, or more, of the parameters is required to be a contract, but is not
    error AddressNotContract();
    /// @notice Returned when a requested configuration would result in no state change.
    error AlreadySet();
    /// @notice Returned when manual pricing is attempted on a TokenSet
    error TokensetPricing();
    /// @notice Returned when TokenSet-based pricing is requested for a token that is not a Set.
    error NotTokenset();
    /// @notice Returned when the external TokenSet Controller fails
    error TokensetContractError();
    /// @notice Returned when the requested pricing change requires an override
    error RequiresOverride();
    /// @notice Returned when the block's timestamp is passed the expiration timestamp for the requested action
    error TimerExpired();
    /// @notice Returned when the requested contract destruction requires an unlock
    error UnlockDestruction();
    /// @notice Returned when the requested token can not be transferred
    error TransferFailed();

    /// @dev Requires that the specified address is a contract
    modifier onlyContract(address _address) {
        if (isNotContract(_address)) revert AddressNotContract();
        _;
    }

    /// @notice See respective variable descriptions for appropriate values. Both tokens must exist prior to contract creation. The msg.sender is the initial contract owner.
    constructor(address _tokenPrimary, address _tokenDenominator)
        onlyContract(_tokenPrimary)
        onlyContract(_tokenDenominator)
    {
        slot0.owner = msg.sender;
        tokenPrimary = _tokenPrimary;
        tokenDenominator = _tokenDenominator;
        emit ContractCreation(msg.sender, _tokenPrimary, _tokenDenominator);
    }

    /// @notice Sets all variables that are required to operate the contract (Can only be called once) (Can only be called by the owner)
    /// @dev Setting [_isTokenset] to "true" will cause [_price] to be ignored
    /// @param _price The starting price, per [tokenDenominator]
    /// @param _isTokenset Whether the priced token is a TokenSet or not
    /// @param _fee The buy/sell spread fee (in tenths of a percent)
    /// @param _threshold The number of SWD required before getPrice() returns spot
    function initialize(
        uint256 _price,
        bool _isTokenset,
        uint8 _fee,
        uint80 _threshold
    ) external {
        Slot0 memory _slot0 = slot0;
        onlyOwner(_slot0.owner);
        if ((price != 0) || _slot0.isTokenset) revert AlreadySet();
        if (_isTokenset) {
            setTokenset(true);
            _slot0.isTokenset = true;
        } else {
            price = _price;
            emit SetPrice(_slot0.owner, _price);
        }
        _slot0.pricePercentFeeSpread = _fee;
        emit SetPriceFeeSpread(_slot0.owner, _fee);
        _slot0.swdThreshold = _threshold;
        emit SetSwdThreshold(_slot0.owner, _threshold);
        slot0 = _slot0;
    }

    /// @notice Sets the price (Can only be called by the owner)
    /// @param _price The starting price, per [tokenDenominator], which can only be 10% off from the previous price without an override (in UInt256 format, accounting for the primary token's decimals)
    function setPrice(uint256 _price) external {
        Slot0 memory _slot0 = slot0;
        onlyOwner(_slot0.owner);
        if (_slot0.isTokenset) revert TokensetPricing();
        if (_price == 0) revert NotTokenset();
        requiresOverride(_price);
        if (priceOverride != 0) priceOverride = 0;
        price = _price;
        emit SetPrice(_slot0.owner, _price);
    }

    /// @notice Initiates a pricing override (Can only be called by the owner)
    function setPriceOverride() external {
        address _owner = slot0.owner;
        onlyOwner(_owner);
        uint256 _endTime = block.timestamp + 1 hours;
        priceOverride = _endTime;
        emit SetPriceOverride(_owner, _endTime);
    }

    /// @notice Sets the buy/sell fee, in the form of a price spread (Can only be called by the owner)
    /// @dev Fee can range from 0% to 25.5%, in 0.1% increments, and is stored as such to fit into [slot0]
    /// @param _fee The fee, with a max of 25.5% (in tenths of a percent: ex. 1 = 0.1%)
    function setPriceFeeSpread(uint8 _fee) external {
        Slot0 memory _slot0 = slot0;
        onlyOwner(_slot0.owner);
        _slot0.pricePercentFeeSpread = _fee;
        slot0 = _slot0;
        emit SetPriceFeeSpread(_slot0.owner, _fee);
    }

    /// @notice Sets whether the primary token is treated as a TokenSet (Can only be called by the owner)
    /// @param _isTokenset "True" for TokenSet, or "false" for standard
    function setTokenset(bool _isTokenset) public {
        Slot0 memory _slot0 = slot0;
        address _tokenPrimary = tokenPrimary;
        onlyOwner(_slot0.owner);
        if (_isTokenset) {
            if (_slot0.isTokenset) revert AlreadySet();
            if (!TOKENSET_CONTROLLER.isSet(_tokenPrimary)) revert NotTokenset();
            uint256 _price = getTokensetPrice();
            requiresOverride(_price);
            _slot0.isTokenset = true;
            price = 0;
            emit SetPrice(_slot0.owner, _price);
        } else {
            if (!_slot0.isTokenset) revert AlreadySet();
            _slot0.isTokenset = false;
            uint256 _price = getTokensetPrice();
            requiresOverride(_price);
            price = _price;
            emit SetPrice(_slot0.owner, _price);
        }
        slot0 = _slot0;
        emit SetTokenset(_slot0.owner, _isTokenset);
    }

    /// @notice  Sets the number of SWD in a transactor's address required for getPrice() to return spot, rather than charging a fee (Can only be called by the owner)
    /// @dev Stored as uint80 to fit into [slot0], as SWD's max supply is sufficiently low 
    /// @param _threshold Number of SWD (UInt256 format, with 18 decimals)
    function setSwdThreshold(uint80 _threshold) external {
        Slot0 memory _slot0 = slot0;
        onlyOwner(_slot0.owner);
        _slot0.swdThreshold = _threshold;
        slot0 = _slot0;
        emit SetSwdThreshold(_slot0.owner, _threshold);
    }

    /// @notice Initiates an ownership transfer, but the new owner must call ownerConfirm() within 36 hours to finalize (Can only be called by the owner)
    /// @param _ownerNew The new owner's address
    function ownerTransfer(address _ownerNew) external {
        onlyOwner(slot0.owner);
        ownerNew = _ownerNew;
        ownerTransferTimeout = block.timestamp + 36 hours;
        emit OwnerTransfer(msg.sender, _ownerNew);
    }

    /// @notice Finalizes an ownership transfer (Can only be called by the new owner)
    function ownerConfirm() external {
        if (msg.sender != ownerNew) revert Unauthorized();
        if (block.timestamp > ownerTransferTimeout) revert TimerExpired();
        address _ownerOld = slot0.owner;
        slot0.owner = ownerNew;
        ownerNew = address(0);
        ownerTransferTimeout = 0;
        emit OwnerConfirm(msg.sender, _ownerOld);
    }

    /// @notice Used to rescue mis-sent tokens from the contract address (Can only be called by the contract owner)
    /// @param _token The address of the token to be rescued
    function withdrawToken(address _token) external {
        address _owner = slot0.owner;
        onlyOwner(_owner);
        bool success = IERC20(_token).transfer(
            _owner,
            IERC20(_token).balanceOf(address(this))
        );
        if (!success) revert TransferFailed();
        emit WithdrawToken(_owner, _token);
    }

    /// @notice Destroys the contract when it's no longer needed (Can only be called by the owner)
    /// @dev Only allows selfdestruct() after the variable [ownerNew] has been set to its max value, in order to help mitigate human error
    function destroyContract() external {
        address payable _owner = payable(slot0.owner);
        onlyOwner(_owner);
        if (ownerNew != 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF)
            revert UnlockDestruction();
        emit SelfDestruct(_owner);
        selfdestruct(_owner);
    }

    /// @notice Gets the current price of the primary token, denominated in [tokenDenominator]
    /// @dev Returns a different value, depending on the SWD balance of tx.origin's wallet. If the balance is over the threshold, getPrice() will return the price unmodified, otherwise it adds the dictated fee. Tx.origin is purposefully used over msg.sender, so as to be compatible with DEx aggregators. As a side effect, this makes it incompatible with relays.
    /// @param _buySell "True" for selling, "false" for buying.
    /// @return uint256 Current price, per [tokenDenominator]
    /// @return address Current [tokenDenominator]
    function getPrice(bool _buySell) public view returns (uint256, address) {
        Slot0 memory _slot0 = slot0;
        uint256 _price;
        if (_slot0.isTokenset) {
            _price = getTokensetPrice();
            if (_price == 0) revert TokensetContractError();
            return (
                addSubFee(
                    _price,
                    _slot0.pricePercentFeeSpread,
                    _buySell,
                    _slot0.swdThreshold
                ),
                tokenDenominator
            );
        }
        _price = price;
        if (_price == 0) revert NotInitialized();
        return (
            addSubFee(
                _price,
                _slot0.pricePercentFeeSpread,
                _buySell,
                _slot0.swdThreshold
            ),
            tokenDenominator
        );
    }

    // Prevents calls from non-owner. Purposefully not made a modifier, so as to work well with [slot0], and save gas.
    function onlyOwner(address _owner) private {
        if (msg.sender != _owner) {
            emit UnauthorizedAttempt(msg.sender, tx.origin);
            revert Unauthorized();
        }
    }

    // Abstraction for better readability. 
    function getTokensetPrice() private view returns (uint256) {
        return
            TOKENSET_CONTROLLER.getSetValuer().calculateSetTokenValuation(
                ISetToken(tokenPrimary),
                tokenDenominator
            );
    }

    // Requires on override if the price is to be changed by more than 10%. Done to mitigate human error.
    function requiresOverride(uint256 _price) private view {
        if (price == 0) return;
        if (block.timestamp > priceOverride) {
            if (
                (_price > SpecialMath.safeMul(price, 11) / 10) ||
                (_price < SpecialMath.safeMul(price, 9) / 10)
            ) revert RequiresOverride();
        }
    }

    // Checks if a given address is not a contract.
    function isNotContract(address _addr) private view returns (bool) {
        return (_addr.code.length == 0);
    }

    // Adds a fee, dependent on whether tx.origin holds SWD above the threshold, and whether it's a buy/sell.
    function addSubFee(
        uint256 _price,
        uint8 _fee,
        bool addSub,
        uint80 _threshold
    ) private view returns (uint256) {
        if (IERC20(SWD).balanceOf(tx.origin) >= _threshold) return _price;
        // Values below are not arbitrary. Math utilizes [_fee] as a percentage in tenths of a percent.
        return
            SpecialMath.safeMul(
                _price,
                addSub ? 10000 - (_fee * 10) : 10000 + (_fee * 10)
            ) / 10000;
    }
}