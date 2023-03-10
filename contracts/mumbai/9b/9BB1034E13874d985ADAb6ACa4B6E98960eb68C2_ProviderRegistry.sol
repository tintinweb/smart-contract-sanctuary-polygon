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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
pragma solidity ^0.8.0;

/**
 * @title IProviderRegistry
 * @author Blockswan
 * @notice Defines the basic interface for an Blockswan Protocol Provider Registry.
 **/
interface IProviderRegistry {
    /**
     * @dev Emitted when a new AddressProvider is registered.
     * @param addressProvider The address of the registered AddressProvider
     * @param id The id of the registered AddressProvider
     */
    event AddressProviderRegistered(
        address indexed addressProvider,
        uint256 indexed id
    );

    /**
     * @dev Emitted when an addressProvider is unregistered.
     * @param addressProvider The address of the unregistered AddressProvider
     * @param id The id of the unregistered AddressProvider
     */
    event AddressProviderUnregistered(
        address indexed addressProvider,
        uint256 indexed id
    );

    /**
     * @notice Returns the list of registered addresses providers
     * @return The list of addresses providers
     **/
    function getAddressProvidersList() external view returns (address[] memory);

    /**
     * @notice Returns the id of a registered AddressProvider
     * @param addressProvider The address of the AddressProvider
     * @return The id of the AddressProvider or 0 if is not registered
     */
    function getAddressProviderIdByAddress(
        address addressProvider
    ) external view returns (uint256);

    /**
     * @notice Returns the address of a registered AddressProvider
     * @param id The id of the marketplace
     * @return The address of the AddressProvider with the given id or zero address if it is not registered
     */
    function getAddressProviderById(uint256 id) external view returns (address);

    /**
     * @notice Registers an addresses provider
     * @dev The protocol AddressesProvider must not already be registered in the registry
     * @dev The id must not be used by an already registered protocol AddressesProvider
     * @param provider The address of the new protocol AddressesProvider
     * @param id The id for the new AddressesProvider, referring to the marketplace it belongs to
     **/
    function registerAddressProvider(address provider, uint256 id) external;

    /**
     * @notice Removes an addresses provider from the list of registered addresses providers
     * @param provider The protocol AddressesProvider address
     **/
    function unregisterAddressProvider(address provider) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "../../imports/openzeppelin/contracts/Ownable.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {IProviderRegistry} from "../../interfaces/IProviderRegistry.sol";

/**
 * @title Provider Registry
 * @author Blockswan
 * @notice Main registry of Addresses_provider of Blockswan marketplaces.
 * @dev Used for indexing purposes of Blockswan protocol's marketplaces. The id assigned to an AddressesProvider refers to the
 * market it is connected with, for example with `1` for the Blockswan main market and `2` for the next created.
 **/

contract ProviderRegistry is Ownable, IProviderRegistry {
    // List of addresses providers
    address[] private _addressProvidersList;
    // Map of address provider ids (addressProvider => id)
    mapping(address => uint256) private _addressProviderToId;
    // Map of id to address provider (id => addressProvider)
    mapping(uint256 => address) private _idToAddressProvider;
    // Map of address provider list indexes (addressProvider => indexInList)
    mapping(address => uint256) private _addressProvidersIndexes;

    /**
     * @dev Constructor.
     * @param owner The owner address of this contract.
     */
    constructor(address owner) {
        transferOwnership(owner);
    }

    /// @inheritdoc IProviderRegistry
    function getAddressProvidersList()
        external
        view
        override
        returns (address[] memory)
    {
        return _addressProvidersList;
    }

    /// @inheritdoc IProviderRegistry
    function registerAddressProvider(
        address provider,
        uint256 id
    ) external override onlyOwner {
        require(id != 0, Errors.INVALID_ADDRESS_PROVIDER_ID);
        require(
            _idToAddressProvider[id] == address(0),
            Errors.INVALID_ADDRESS_PROVIDER_ID
        );
        require(
            _addressProviderToId[provider] == 0,
            Errors.ADDRESS_PROVIDER_ALREADY_ADDED
        );

        _addressProviderToId[provider] = id;
        _idToAddressProvider[id] = provider;

        _addToAddressProviderslist(provider);
        emit AddressProviderRegistered(provider, id);
    }

    /// @inheritdoc IProviderRegistry
    function unregisterAddressProvider(
        address provider
    ) external override onlyOwner {
        require(
            _addressProviderToId[provider] != 0,
            Errors.ADDRESS_PROVIDER_NOT_REGISTERED
        );
        uint256 old_id = _addressProviderToId[provider];
        _idToAddressProvider[old_id] = address(0);
        _addressProviderToId[provider] = 0;

        _removeFromAddressProvidersList(provider);

        emit AddressProviderUnregistered(provider, old_id);
    }

    /// @inheritdoc IProviderRegistry
    function getAddressProviderIdByAddress(
        address addresses_provider
    ) external view override returns (uint256) {
        return _addressProviderToId[addresses_provider];
    }

    /// @inheritdoc IProviderRegistry
    function getAddressProviderById(
        uint256 id
    ) external view override returns (address) {
        return _idToAddressProvider[id];
    }

    /**
     * @notice Adds the addresses provider address to the list.
     * @param provider The address of the protocol AddressesProvider
     */
    function _addToAddressProviderslist(address provider) internal {
        _addressProvidersIndexes[provider] = _addressProvidersList.length;
        _addressProvidersList.push(provider);
    }

    /**
     * @notice Removes the addresses provider address from the list.
     * @param provider The address of the AddressesProvider
     */
    function _removeFromAddressProvidersList(address provider) internal {
        uint256 index = _addressProvidersIndexes[provider];

        _addressProvidersIndexes[provider] = 0;

        // Swap the index of the last addresses provider in the list with the index of the provider to remove
        uint256 last_index = _addressProvidersList.length - 1;
        if (index < last_index) {
            address last_provider = _addressProvidersList[last_index];
            _addressProvidersList[index] = last_provider;
            _addressProvidersIndexes[last_provider] = index;
        }
        _addressProvidersList.pop();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title Errors  library
 * @author Blockswan
 * @notice Defines the error messages emitted by the different contracts of the Blockswan protocol
 */
library Errors {
    string public constant INVALID_ADDRESS_PROVIDER_ID = "1"; // The addresses provider is not valid
    string public constant ADDRESS_PROVIDER_ALREADY_ADDED = "2"; // This addresses provider already exists
    string public constant ADDRESS_PROVIDER_NOT_REGISTERED = "3"; // 'This addresses provider is not registered'
    string public constant CONTRACT_NAME_ALREADY_USED = "4"; // 'Requires that given _name does not already have non-zero registered contract address'
    string public constant ZERO_ADDRESS_IS_INVALID = "5"; // the address provided is 0x00
    string public constant INDEX_OUT_OF_RANGE = "6"; // the index provided is out of range
    string public constant ADDRESS_ALREADY_USED = "7"; // 'The address provided has already been unsed to initialise an account'
    string public constant INVALID_USER_ID = "8"; // 'The userId is incorrect'
    string public constant RESTRICTED_TO_BUYER = "9"; // this function can't  be called by buyers
    string public constant INVALID_INVITER_ID = "10"; // The inviter ID provided is incorrect
    string public constant FAILED_BECOMING_BUYER = "11"; // The execution to becomeBuyer failed
    string public constant RESTRICTED_TO_SELLER = "12"; // this function can't  be called by sellers
    string public constant FAILED_BECOMING_SELLER = "13"; // The execution to becomeSeller failed
    string public constant NO_MATCHING_XP_KEY = "14"; // There is no xp value to give for this byte32
    string public constant GIG_ID_ALREADY_EXISING = "15"; // There is already an id for this gig.
    string public constant ONLY_SELLER = "16"; // Only account with the seller role can call the functions
    string public constant ONLY_BUYER = "17"; // Only buyers can call those functions.
    string public constant NOT_GIG_OWNER = "18"; // The id provided does not match with the gig owner id
    string public constant CALLER_NOT_SELLER_ID = "19"; // The seller id provided is not matching with the account address calling the function
    string public constant CALLER_NOT_BUYER_ID = "20"; // The buyer id provided is not matching with the account address calling the function
    string public constant NOT_ORDER_SELLER = "21"; // The id provided is not the order seller
    string public constant NOT_ORDER_BUYER = "22"; // The id provided is not the order buyer
    string public constant INVALID_ORDER_STATE = "23"; // The function can't be called under the current order state
    string public constant SELF_REFUND_DELAY_NOT_OVER = "24"; // The self refund delay is not over
    string public constant NOT_ORDER_ACTOR = "25"; // The account address calling the function is not matching with the buyerId nor sellerId.
    string public constant DISPUTE_NOT_CREATED = "26"; // The dispute has not been created yet
    string public constant JURY_STAKE_NOT_ENOUGH = "27"; // The jury stake is not enough
    string public constant FAILED_TO_STAKE_JURY = "28"; // The jury stake failed
    string public constant FAILED_TO_WITHDRAW_JURY = "29"; // The jury withdraw failed
    string public constant ROUND_EVIDENCE_ALREADY_SUBMITTED = "30"; // The evidence has already been submitted
    string public constant EVIDENCE_NOT_SUBMITTED = "31"; // The evidence has not been submitted
    string public constant DS_EVIDENCE_PERIOD_OVER = "32"; // The evidence period is over
    // string public constant DS_VOTING_PERIOD_OVER = "33"; // The voting period is over
    // string public constant DS_VOTING_PERIOD_NOT_OVER = "34"; // The voting period is not over
    // string public constant DS_VOTING_PERIOD_NOT_STARTED = "35"; // The voting period has not started yet
    string public constant ONLY_PROVIDER_ALLOWED = "36"; // Only the provider can call this function
    string public constant DS_EVIDENCE_SENDER_NOT_PARTY = "37"; // The sender is not a party of the dispute
    string public constant CALLER_NOT_USER = "38"; // The caller is not the user Id
    string public constant DS_EVIDENCE_ROLE_NOT_VALID = "39"; // The role is not valid
    string public constant RD_ROUND_DOES_NOT_EXIST = "40"; // The round does not exist
    string public constant DS_IN_EXECUTION_PERIOD = "46"; //     The dispute is in execution state
    string public constant VOTE_REVEAL_INCORRECT = "47"; //     The vote reveal is incorrect
    string public constant ROUND_VOTE_ALREADY_COMMITED = "48"; //     The vote has already been commited
    string public constant ROUND_VOTE_NOT_COMMITED = "49"; //     The vote has not been commited
    string public constant ROUND_VOTE_ALREADY_REVEALED = "50"; //     The vote has already been revealed
    string public constant RD_ACCOUNT_NOT_DRAWN_JUROR = "51"; //     The account is not a drawn juror
    string public constant DS_COMMIT_STATE_REQUIRED = "52"; //    The dispute is not in commit state
    string public constant DS_TIME_NOT_PASSED = "53"; //   The time has not passed
    string public constant DS_INVALID_STATE = "54"; //   The state is invalid
    string public constant VOTE_INVALID_CHOICE = "55"; //  The vote choice is invalid
    string public constant DS_NO_COMMITMENTS_MADE_FOR_ROUND = "56"; //  No commitments were made for the round
    string public constant DS_NO_VOTES_MADE_FOR_ROUND = "57"; //  No votes were made for the round
    string public constant RD_VOTE_NOT_FOUND = "58"; //  The vote was not found
    string public constant ROUND_NOT_CLOSED = "59"; //  The round is not closed
    string public constant VOTE_INCORRECT = "60"; //  The vote is incorrect
    string public constant ROUND_NOT_APPEALED = "61"; //  The round is not appealed
    string public constant ROUND_ID_INVALID = "62"; //  The round id is invalid
    string public constant CLAIM_NOT_ALLOWED = "63"; //  The claim is not allowed
    string public constant ROUND_IS_APPEALED = "64"; //  The round is appealed
    string public constant DS_DISPUTE_ALREADY_RULED = "65"; //  The dispute is already ruled
}