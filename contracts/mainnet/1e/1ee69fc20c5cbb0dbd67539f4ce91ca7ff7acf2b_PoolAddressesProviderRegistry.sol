// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Ownable} from "../../dependencies/openzeppelin/contracts/Ownable.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {IPoolAddressesProviderRegistry} from "../../interfaces/IPoolAddressesProviderRegistry.sol";

/**
 * @title PoolAddressesProviderRegistry
 *
 * @notice Main registry of PoolAddressesProvider of ParaSpace markets.
 * @dev Used for indexing purposes of ParaSpace protocol's markets. The id assigned to a PoolAddressesProvider refers to the
 * market it is connected with, for example with `1` for the ParaSpace main market and `2` for the next created.
 **/
contract PoolAddressesProviderRegistry is
    Ownable,
    IPoolAddressesProviderRegistry
{
    // Map of address provider ids (addressesProvider => id)
    mapping(address => uint256) private _addressesProviderToId;
    // Map of id to address provider (id => addressesProvider)
    mapping(uint256 => address) private _idToAddressesProvider;
    // List of addresses providers
    address[] private _addressesProvidersList;
    // Map of address provider list indexes (addressesProvider => indexInList)
    mapping(address => uint256) private _addressesProvidersIndexes;

    /**
     * @dev Constructor.
     * @param owner The owner address of this contract.
     */
    constructor(address owner) {
        transferOwnership(owner);
    }

    /// @inheritdoc IPoolAddressesProviderRegistry
    function getAddressesProvidersList()
        external
        view
        override
        returns (address[] memory)
    {
        return _addressesProvidersList;
    }

    /// @inheritdoc IPoolAddressesProviderRegistry
    function registerAddressesProvider(address provider, uint256 id)
        external
        override
        onlyOwner
    {
        require(id != 0, Errors.INVALID_ADDRESSES_PROVIDER_ID);
        require(provider != address(0x0), Errors.INVALID_ADDRESSES_PROVIDER);

        require(
            _idToAddressesProvider[id] == address(0),
            Errors.INVALID_ADDRESSES_PROVIDER_ID
        );
        require(
            _addressesProviderToId[provider] == 0,
            Errors.ADDRESSES_PROVIDER_ALREADY_ADDED
        );

        _addressesProviderToId[provider] = id;
        _idToAddressesProvider[id] = provider;

        _addToAddressesProvidersList(provider);
        emit AddressesProviderRegistered(provider, id);
    }

    /// @inheritdoc IPoolAddressesProviderRegistry
    function unregisterAddressesProvider(address provider)
        external
        override
        onlyOwner
    {
        require(
            _addressesProviderToId[provider] != 0,
            Errors.ADDRESSES_PROVIDER_NOT_REGISTERED
        );
        uint256 oldId = _addressesProviderToId[provider];
        _idToAddressesProvider[oldId] = address(0);
        _addressesProviderToId[provider] = 0;

        _removeFromAddressesProvidersList(provider);

        emit AddressesProviderUnregistered(provider, oldId);
    }

    /// @inheritdoc IPoolAddressesProviderRegistry
    function getAddressesProviderIdByAddress(address addressesProvider)
        external
        view
        override
        returns (uint256)
    {
        return _addressesProviderToId[addressesProvider];
    }

    /// @inheritdoc IPoolAddressesProviderRegistry
    function getAddressesProviderAddressById(uint256 id)
        external
        view
        override
        returns (address)
    {
        return _idToAddressesProvider[id];
    }

    /**
     * @notice Adds the addresses provider address to the list.
     * @param provider The address of the PoolAddressesProvider
     */
    function _addToAddressesProvidersList(address provider) internal {
        _addressesProvidersIndexes[provider] = _addressesProvidersList.length;
        _addressesProvidersList.push(provider);
    }

    /**
     * @notice Removes the addresses provider address from the list.
     * @param provider The address of the PoolAddressesProvider
     */
    function _removeFromAddressesProvidersList(address provider) internal {
        uint256 index = _addressesProvidersIndexes[provider];

        _addressesProvidersIndexes[provider] = 0;

        // Swap the index of the last addresses provider in the list with the index of the provider to remove
        uint256 lastIndex = _addressesProvidersList.length - 1;
        if (index < lastIndex) {
            address lastProvider = _addressesProvidersList[lastIndex];
            _addressesProvidersList[index] = lastProvider;
            _addressesProvidersIndexes[lastProvider] = index;
        }
        _addressesProvidersList.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title Errors library
 *
 * @notice Defines the error messages emitted by the different contracts of the ParaSpace protocol
 */
library Errors {
    string public constant CALLER_NOT_POOL_ADMIN = "1"; // 'The caller of the function is not a pool admin'
    string public constant CALLER_NOT_EMERGENCY_ADMIN = "2"; // 'The caller of the function is not an emergency admin'
    string public constant CALLER_NOT_POOL_OR_EMERGENCY_ADMIN = "3"; // 'The caller of the function is not a pool or emergency admin'
    string public constant CALLER_NOT_RISK_OR_POOL_ADMIN = "4"; // 'The caller of the function is not a risk or pool admin'
    string public constant CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN = "5"; // 'The caller of the function is not an asset listing or pool admin'
    string public constant CALLER_NOT_BRIDGE = "6"; // 'The caller of the function is not a bridge'
    string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = "7"; // 'Pool addresses provider is not registered'
    string public constant INVALID_ADDRESSES_PROVIDER_ID = "8"; // 'Invalid id for the pool addresses provider'
    string public constant NOT_CONTRACT = "9"; // 'Address is not a contract'
    string public constant CALLER_NOT_POOL_CONFIGURATOR = "10"; // 'The caller of the function is not the pool configurator'
    string public constant CALLER_NOT_XTOKEN = "11"; // 'The caller of the function is not an PToken or NToken'
    string public constant INVALID_ADDRESSES_PROVIDER = "12"; // 'The address of the pool addresses provider is invalid'
    string public constant RESERVE_ALREADY_ADDED = "14"; // 'Reserve has already been added to reserve list'
    string public constant NO_MORE_RESERVES_ALLOWED = "15"; // 'Maximum amount of reserves in the pool reached'
    string public constant RESERVE_LIQUIDITY_NOT_ZERO = "18"; // 'The liquidity of the reserve needs to be 0'
    string public constant INVALID_RESERVE_PARAMS = "20"; // 'Invalid risk parameters for the reserve'
    string public constant CALLER_MUST_BE_POOL = "23"; // 'The caller of this function must be a pool'
    string public constant INVALID_MINT_AMOUNT = "24"; // 'Invalid amount to mint'
    string public constant INVALID_BURN_AMOUNT = "25"; // 'Invalid amount to burn'
    string public constant INVALID_AMOUNT = "26"; // 'Amount must be greater than 0'
    string public constant RESERVE_INACTIVE = "27"; // 'Action requires an active reserve'
    string public constant RESERVE_FROZEN = "28"; // 'Action cannot be performed because the reserve is frozen'
    string public constant RESERVE_PAUSED = "29"; // 'Action cannot be performed because the reserve is paused'
    string public constant BORROWING_NOT_ENABLED = "30"; // 'Borrowing is not enabled'
    string public constant STABLE_BORROWING_NOT_ENABLED = "31"; // 'Stable borrowing is not enabled'
    string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = "32"; // 'User cannot withdraw more than the available balance'
    string public constant INVALID_INTEREST_RATE_MODE_SELECTED = "33"; // 'Invalid interest rate mode selected'
    string public constant COLLATERAL_BALANCE_IS_ZERO = "34"; // 'The collateral balance is 0'
    string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD =
        "35"; // 'Health factor is lesser than the liquidation threshold'
    string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = "36"; // 'There is not enough collateral to cover a new borrow'
    string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY = "37"; // 'Collateral is (mostly) the same currency that is being borrowed'
    string public constant AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = "38"; // 'The requested amount is greater than the max loan size in stable rate mode'
    string public constant NO_DEBT_OF_SELECTED_TYPE = "39"; // 'For repayment of a specific type of debt, the user needs to have debt that type'
    string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = "40"; // 'To repay on behalf of a user an explicit amount to repay is needed'
    string public constant NO_OUTSTANDING_STABLE_DEBT = "41"; // 'User does not have outstanding stable rate debt on this reserve'
    string public constant NO_OUTSTANDING_VARIABLE_DEBT = "42"; // 'User does not have outstanding variable rate debt on this reserve'
    string public constant UNDERLYING_BALANCE_ZERO = "43"; // 'The underlying balance needs to be greater than 0'
    string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = "44"; // 'Interest rate rebalance conditions were not met'
    string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "45"; // 'Health factor is not below the threshold'
    string public constant COLLATERAL_CANNOT_BE_AUCTIONED_OR_LIQUIDATED = "46"; // 'The collateral chosen cannot be auctioned OR liquidated'
    string public constant SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "47"; // 'User did not borrow the specified currency'
    string public constant SAME_BLOCK_BORROW_REPAY = "48"; // 'Borrow and repay in same block is not allowed'
    string public constant BORROW_CAP_EXCEEDED = "50"; // 'Borrow cap is exceeded'
    string public constant SUPPLY_CAP_EXCEEDED = "51"; // 'Supply cap is exceeded'
    string public constant XTOKEN_SUPPLY_NOT_ZERO = "54"; // 'PToken supply is not zero'
    string public constant STABLE_DEBT_NOT_ZERO = "55"; // 'Stable debt supply is not zero'
    string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO = "56"; // 'Variable debt supply is not zero'
    string public constant LTV_VALIDATION_FAILED = "57"; // 'Ltv validation failed'
    string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = "59"; // 'Price oracle sentinel validation failed'
    string public constant RESERVE_ALREADY_INITIALIZED = "61"; // 'Reserve has already been initialized'
    string public constant INVALID_LTV = "63"; // 'Invalid ltv parameter for the reserve'
    string public constant INVALID_LIQ_THRESHOLD = "64"; // 'Invalid liquidity threshold parameter for the reserve'
    string public constant INVALID_LIQ_BONUS = "65"; // 'Invalid liquidity bonus parameter for the reserve'
    string public constant INVALID_DECIMALS = "66"; // 'Invalid decimals parameter of the underlying asset of the reserve'
    string public constant INVALID_RESERVE_FACTOR = "67"; // 'Invalid reserve factor parameter for the reserve'
    string public constant INVALID_BORROW_CAP = "68"; // 'Invalid borrow cap for the reserve'
    string public constant INVALID_SUPPLY_CAP = "69"; // 'Invalid supply cap for the reserve'
    string public constant INVALID_LIQUIDATION_PROTOCOL_FEE = "70"; // 'Invalid liquidation protocol fee for the reserve'
    string public constant INVALID_DEBT_CEILING = "73"; // 'Invalid debt ceiling for the reserve
    string public constant INVALID_RESERVE_INDEX = "74"; // 'Invalid reserve index'
    string public constant ACL_ADMIN_CANNOT_BE_ZERO = "75"; // 'ACL admin cannot be set to the zero address'
    string public constant INCONSISTENT_PARAMS_LENGTH = "76"; // 'Array parameters that should be equal length are not'
    string public constant ZERO_ADDRESS_NOT_VALID = "77"; // 'Zero address not valid'
    string public constant INVALID_EXPIRATION = "78"; // 'Invalid expiration'
    string public constant INVALID_SIGNATURE = "79"; // 'Invalid signature'
    string public constant OPERATION_NOT_SUPPORTED = "80"; // 'Operation not supported'
    string public constant ASSET_NOT_LISTED = "82"; // 'Asset is not listed'
    string public constant INVALID_OPTIMAL_USAGE_RATIO = "83"; // 'Invalid optimal usage ratio'
    string public constant INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = "84"; // 'Invalid optimal stable to total debt ratio'
    string public constant UNDERLYING_CANNOT_BE_RESCUED = "85"; // 'The underlying asset cannot be rescued'
    string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = "86"; // 'Reserve has already been added to reserve list'
    string public constant POOL_ADDRESSES_DO_NOT_MATCH = "87"; // 'The token implementation pool address and the pool address provided by the initializing pool do not match'
    string public constant STABLE_BORROWING_ENABLED = "88"; // 'Stable borrowing is enabled'
    string public constant SILOED_BORROWING_VIOLATION = "89"; // 'User is trying to borrow multiple assets including a siloed one'
    string public constant RESERVE_DEBT_NOT_ZERO = "90"; // the total debt of the reserve needs to be 0
    string public constant NOT_THE_OWNER = "91"; // user is not the owner of a given asset
    string public constant LIQUIDATION_AMOUNT_NOT_ENOUGH = "92";
    string public constant INVALID_ASSET_TYPE = "93"; // invalid asset type for action.
    string public constant INVALID_FLASH_CLAIM_RECEIVER = "94"; // invalid flash claim receiver.
    string public constant ERC721_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "95"; // ERC721 Health factor is not below the threshold. Can only liquidate ERC20.
    string public constant UNDERLYING_ASSET_CAN_NOT_BE_TRANSFERRED = "96"; //underlying asset can not be transferred.
    string public constant TOKEN_TRANSFERRED_CAN_NOT_BE_SELF_ADDRESS = "97"; //token transferred can not be self address.
    string public constant INVALID_AIRDROP_CONTRACT_ADDRESS = "98"; //invalid airdrop contract address.
    string public constant INVALID_AIRDROP_PARAMETERS = "99"; //invalid airdrop parameters.
    string public constant CALL_AIRDROP_METHOD_FAILED = "100"; //call airdrop method failed.
    string public constant SUPPLIER_NOT_NTOKEN = "101"; //supplier is not the NToken contract
    string public constant CALL_MARKETPLACE_FAILED = "102"; //call marketplace failed.
    string public constant INVALID_MARKETPLACE_ID = "103"; //invalid marketplace id.
    string public constant INVALID_MARKETPLACE_ORDER = "104"; //invalid marketplace id.
    string public constant CREDIT_DOES_NOT_MATCH_ORDER = "105"; //credit doesn't match order.
    string public constant PAYNOW_NOT_ENOUGH = "106"; //paynow not enough.
    string public constant INVALID_CREDIT_SIGNATURE = "107"; //invalid credit signature.
    string public constant INVALID_ORDER_TAKER = "108"; //invalid order taker.
    string public constant MARKETPLACE_PAUSED = "109"; //marketplace paused.
    string public constant INVALID_AUCTION_RECOVERY_HEALTH_FACTOR = "110"; //invalid auction recovery health factor.
    string public constant AUCTION_ALREADY_STARTED = "111"; //auction already started.
    string public constant AUCTION_NOT_STARTED = "112"; //auction not started yet.
    string public constant AUCTION_NOT_ENABLED = "113"; //auction not enabled on the reserve.
    string public constant ERC721_HEALTH_FACTOR_NOT_ABOVE_THRESHOLD = "114"; //ERC721 Health factor is not above the threshold.
    string public constant TOKEN_IN_AUCTION = "115"; //tokenId is in auction.
    string public constant AUCTIONED_BALANCE_NOT_ZERO = "116"; //auctioned balance not zero.
    string public constant LIQUIDATOR_CAN_NOT_BE_SELF = "117"; //user can not liquidate himself.
    string public constant INVALID_RECIPIENT = "118"; //invalid recipient specified in order.
    string public constant FLASHCLAIM_NOT_ALLOWED = "119"; //flash claim is not allowed for UniswapV3 & Stakefish
    string public constant NTOKEN_BALANCE_EXCEEDED = "120"; //ntoken balance exceed limit.
    string public constant ORACLE_PRICE_NOT_READY = "121"; //oracle price not ready.
    string public constant SET_ORACLE_SOURCE_NOT_ALLOWED = "122"; //source of oracle not allowed to set.
    string public constant INVALID_LIQUIDATION_ASSET = "123"; //invalid liquidation asset.
    string public constant XTOKEN_TYPE_NOT_ALLOWED = "124"; //the corresponding xTokenType not allowed in this action
    string public constant GLOBAL_DEBT_IS_ZERO = "125"; //liquidation is not allowed when global debt is zero.
    string public constant ORACLE_PRICE_EXPIRED = "126"; //oracle price expired.
    string public constant APE_STAKING_POSITION_EXISTED = "127"; //ape staking position is existed.
    string public constant SAPE_NOT_ALLOWED = "128"; //operation is not allow for sApe.
    string public constant TOTAL_STAKING_AMOUNT_WRONG = "129"; //cash plus borrow amount not equal to total staking amount.
    string public constant NOT_THE_BAKC_OWNER = "130"; //user is not the bakc owner.
    string public constant CALLER_NOT_EOA = "131"; //The caller of the function is not an EOA account
    string public constant MAKER_SAME_AS_TAKER = "132"; //maker and taker shouldn't be the same address
    string public constant TOKEN_ALREADY_DELEGATED = "133"; //token is already delegted
    string public constant INVALID_STATE = "134"; //invalid token status
    string public constant INVALID_TOKEN_ID = "135"; //invalid token id
    string public constant SENDER_SAME_AS_RECEIVER = "136"; //sender and receiver shouldn't be the same address
    string public constant INVALID_YIELD_UNDERLYING_TOKEN = "137"; //invalid yield underlying token
    string public constant CALLER_NOT_OPERATOR = "138"; // The caller of the function is not operator
    string public constant INVALID_FEE_VALUE = "139"; // invalid fee rate value
    string public constant TOKEN_NOT_ALLOW_RESCUE = "140"; // token is not allow rescue
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPoolAddressesProviderRegistry
 *
 * @notice Defines the basic interface for an ParaSpace Pool Addresses Provider Registry.
 **/
interface IPoolAddressesProviderRegistry {
    /**
     * @dev Emitted when a new AddressesProvider is registered.
     * @param addressesProvider The address of the registered PoolAddressesProvider
     * @param id The id of the registered PoolAddressesProvider
     */
    event AddressesProviderRegistered(
        address indexed addressesProvider,
        uint256 indexed id
    );

    /**
     * @dev Emitted when an AddressesProvider is unregistered.
     * @param addressesProvider The address of the unregistered PoolAddressesProvider
     * @param id The id of the unregistered PoolAddressesProvider
     */
    event AddressesProviderUnregistered(
        address indexed addressesProvider,
        uint256 indexed id
    );

    /**
     * @notice Returns the list of registered addresses providers
     * @return The list of addresses providers
     **/
    function getAddressesProvidersList()
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns the id of a registered PoolAddressesProvider
     * @param addressesProvider The address of the PoolAddressesProvider
     * @return The id of the PoolAddressesProvider or 0 if is not registered
     */
    function getAddressesProviderIdByAddress(address addressesProvider)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the address of a registered PoolAddressesProvider
     * @param id The id of the market
     * @return The address of the PoolAddressesProvider with the given id or zero address if it is not registered
     */
    function getAddressesProviderAddressById(uint256 id)
        external
        view
        returns (address);

    /**
     * @notice Registers an addresses provider
     * @dev The PoolAddressesProvider must not already be registered in the registry
     * @dev The id must not be used by an already registered PoolAddressesProvider
     * @param provider The address of the new PoolAddressesProvider
     * @param id The id for the new PoolAddressesProvider, referring to the market it belongs to
     **/
    function registerAddressesProvider(address provider, uint256 id) external;

    /**
     * @notice Removes an addresses provider from the list of registered addresses providers
     * @param provider The PoolAddressesProvider address
     **/
    function unregisterAddressesProvider(address provider) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}