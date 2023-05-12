// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IStakeValidator {
    /**
     * Validate that an incoming transfer notification is a valid stake operation
     * This most likely will involve packing the the input data, hashing it and then validate against
     * a signature provided in the "data" argument"
     *
     * If this method deems the staking operation to be invalid, it *must* revert (since there is no
     * return value)
     */
    function validateERC721(
        address tokenContract, address from, uint256 tokenId, bytes calldata data
    ) external view;

    /**
     * See above
     */
    function validateERC1155(
        address tokenContract, address from, uint256 id, uint256 value, bytes calldata data
    ) external view;

    /**
     * See above
     */
    function validateERC1155Batch(
        address tokenContract, address from, uint256[] calldata ids, uint256[] calldata values,
        bytes calldata data
    ) external view;

    /**
     * Validates a batch stake is a valid stake operation.
     */
    function validateBatchStake(
        address[] calldata contracts, uint256[][] calldata tokens, uint256[][] calldata amounts,
        bytes calldata data
    ) external view;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "../openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import "../openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import "../openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "../openzeppelin-contracts/contracts/access/Ownable.sol";
import "../openzeppelin-contracts/contracts/utils/Counters.sol";
import "../openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "./IStakeValidator.sol";

/**
 * @dev A contract allowing to stake up to 100 ERC721 and ERC1155 tokens per "user" (= address).
 * Stakes can be created using the IERC721Receiver and IERC1155Receiver interface, or via a batch
 * stake function which requires approval before though.
 * Staked tokens can be unstaked upon which they enter a "cooldown period". After the end of the
 * cooldown period they can be claimed which will transfer them back to their original owner.
 * All stake operations are validated using the IStakeValidator interface.
 * For ERC1155 tokens, "non-fungible" stakes increase the amount of staked tokens per the amount
 * transferred, staying in the limit of 100.
 */
contract Staking is IERC165, IERC721Receiver, IERC1155Receiver, Ownable, Initializable {
    using Counters for Counters.Counter;

    /**
     * @dev Helps to differentiate types of stakes between the supported (N)FT standards
     */
    enum TokenType{ERC721, ERC1155}

    /**
     * @dev Structure for storing a staked token
     */
    struct StakeRecord {
        /**
         * @dev Stake record id, this can later be used to unstake and claim the stake.
         */
        uint256 id;
        /**
         * @dev Address of the smart contract managing the token
         */
        address tokenContract;
        /**
         * @dev Token id in the smart contract
         */
        uint256 tokenId;
        /**
         * @dev Unix timestamp in seconds at which the token can be claimed. If 0, the token must be
         * unstaked first.
         */
        uint256 claimableAt;
        /**
         * @dev Type of the token
         */
        TokenType tokenType;
    }

    /**
     * @dev Event emitted whenever a token is staked. For ERC1155 one event "per amount" is emitted.
     * @param from The address who staked the token
     * @param id The id of the record storing the stake
     * @param tokenAddress Address of the smart contract managing the token
     * @param tokenId The id of the token in its smart contract
     * @param tokenType The type of the token
     * @param totalStaked The total amount of tokens the "from" address has staked (including the
     * new stake)
     */
    event TokenStaked(
        address indexed from, uint256 id, address tokenAddress, uint256 tokenId,
        TokenType tokenType, uint256 totalStaked
    );

    /**
     * @dev Event emitted whenever a token is unstaked.
     * @param from The address who unstaked the token
     * @param id The id of the record storing the stake
     * @param tokenAddress Address of the smart contract managing the token
     * @param tokenId The id of the token in its smart contract
     * @param tokenType The type of the token
     * @param claimableAt The timestamp in seconds when the token will be claimable
     * @param totalStaked The total amount of tokens the "from" address has staked (excluding the
     * now unstaked token)
     */
    event TokenUnstaked(
        address indexed from, uint256 id, address tokenAddress, uint256 tokenId,
        TokenType tokenType, uint256 claimableAt, uint256 totalStaked
    );

    /**
     * @dev Event emitted whenever a token is claimed, i.e. transferred back to the stakers wallet
     * @param from The address who claimed the token
     * @param id The id of the record storing the stake
     * @param tokenAddress Address of the smart contract managing the token
     * @param tokenId The id of the token in its smart contract
     * @param tokenType The type of the token
     */
    event TokenClaimed(
        address indexed from, uint256 id, address tokenAddress, uint256 tokenId, TokenType tokenType
    );

    /**
     * @dev Amount of seconds it takes for an unstaked NFT to become claimable
     */
    uint256 public unstakePeriodSeconds;

    /**
     * @dev The maximum amount of NFTs a user can stake
     */
    uint256 constant MAX_ACTIVE_STAKES = 100;

    /**
     * @dev Sequence for stake record identifiers
     */
    Counters.Counter private nextId;

    /**
     * @dev Staked and unstaked tokens of an address, i.e. the owner.
     */
    mapping(address => StakeRecord[]) private stakes;

    /**
     * @dev Mapping of stake record identifiers to the index in the array of records of the owner.
     * This mapping contains the indexes offset by adding 1 (so index 0 is stored as 1, index 1 as 2
     * and so on). This is done since the default value of the mapping is 0 and does not allow us to
     * check for missing values if we also "use" 0.
     * So e.g. if record id "5" is mapped to "2" here, it means in the array of the owner it will
     * look like this:
     * [ { "id": 0, ... }, { "id": 5, ... } ]
     * So the record with id 5 is at index 1.
     */
    mapping(uint256 => uint256) private idToIndex;

    /**
     * @dev Mapping of amount of active (i.e. not unstaked) tokens for an address
     */
    mapping(address => uint256) private activeStakes;

    /**
     * @dev Reference to the smart contract implementing staking validation
     */
    IStakeValidator public validator;

    /**
     * @dev When this is set to true, validation using the validator can be skipped. This is used
     * internally for batch staking where the validation happens once at the beginning, but the
     * onERC721/1155Received callbacks must not validate again.
     */
    bool private skipValidation = false;

    /**
     * @dev Since we will not interact with this contract directly, but instead use it as
     * implementation referenced for a Proxy, we simply lock this contract so no one can call
     * `initialize`.
     * This step is not critical, since the state of the implementation contract is never used, but
     * recommended as a best practice.
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Pseudo-constructor for this contract. Since this contract serves as implementation for a
     * Proxy contract, we can not use a real constructor, as we would not be able to run it in the
     * context of the proxy.
     * @param _validator Address of the initial staking validation smart contract.
     * @param _owner The owner/admin of this contract. This address is allowed to call setValidator
     * @param _unstakePeriodSeconds Initial unstaking time in seconds
     */
    function initialize(
        address _validator, address _owner, uint256 _unstakePeriodSeconds
    ) initializer external {
        unstakePeriodSeconds = _unstakePeriodSeconds;
        validator = IStakeValidator(_validator);
        // Ownable implicitly grants ownership to the deployer in the constructor. Since
        // constructors are not working in combination with Proxies, we do it here explicitly. We
        // could use msg.sender but this should be handled carefully as the admin of the proxy can
        // not be the owner
        _transferOwnership(_owner);
    }

    /**
     * @dev Updates the staking validation smart contract
     */
    function setValidator(address _validator) external onlyOwner {
        validator = IStakeValidator(_validator);
    }

    /**
     * @dev Implementation of @link IERC165#supportsInterface
     */
    function supportsInterface(bytes4 interfaceId) external override pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId ||
        interfaceId == type(IERC721Receiver).interfaceId ||
        interfaceId == type(IERC1155Receiver).interfaceId;
    }

    /**
     * @dev Called when an ERC721 NFT is received. Records the stake.
     * @param from The owner who sent the NFT
     * @param tokenId The identifier of the NFT
     * @param data Arbitrary transfer data. Might be used depending on the @link validator and based
     * on it have certain restrictions.
     */
    function onERC721Received(
        address /*operator*/, address from, uint256 tokenId, bytes calldata data
    ) external override returns (bytes4) {
        // The NFT smart contract is the one "calling us", and thus the message sender
        address tokenContract = msg.sender;
        // Check if the validation can be skipped. This is set to true during batch stakes.
        if (!skipValidation) {
            // Validate that the NFT can be staked
            validator.validateERC721(tokenContract, from, tokenId, data);
        }
        // Record the stake. This will fail if the limit for the address is reached
        _recordStake(from, tokenContract, tokenId, TokenType.ERC721);
        // As per the IERC721Receiver interface this has to be returned on success
        return this.onERC721Received.selector;
    }

    /**
     * @dev Called when an ERC1155 token is received. Records the stake(s). If multiple of the token
     * are received each one is recorded as a separate stake.
     * @param from The owner who sent the token
     * @param id The identifier of the token
     * @param value The amount of the token received.
     * @param data Arbitrary transfer data. Might be used depending on the @link validator and based
     * on it have certain restrictions.
     */
    function onERC1155Received(
        address /*operator*/, address from, uint256 id, uint256 value, bytes calldata data
    ) external override returns (bytes4) {
        // The token smart contract is the one "calling us", and thus the message sender
        address tokenContract = msg.sender;
        // Check if the validation can be skipped. This is set to true during batch stakes.
        if (!skipValidation) {
            // Validate that the token can be staked
            validator.validateERC1155(tokenContract, from, id, value, data);
        }
        // Record each "amount" of the token as a separate stake
        for (uint i = 0; i < value; i++) {
            _recordStake(from, tokenContract, id, TokenType.ERC1155);
        }
        // As per the IERC1155Receiver interface this has to be returned on success
        return this.onERC1155Received.selector;
    }

    /**
     * @dev Called when multiple ERC1155 tokens are received. Records the stakes. Multiple of one
     * token are recorded as separate stakes
     * @param from The owner who sent the token
     * @param ids The identifiers of the tokens
     * @param values The amounts of the tokens received.
     * @param data Arbitrary transfer data. Might be used depending on the @link validator and based
     * on it have certain restrictions.
     */
    function onERC1155BatchReceived(
        address /*operator*/, address from, uint256[] calldata ids, uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        // The token smart contract is the one "calling us", and thus the message sender
        address tokenContract = msg.sender;
        // Check if the validation can be skipped. This is set to true during batch stakes.
        if (!skipValidation) {
            // Validate that the tokens can be staked
            validator.validateERC1155Batch(tokenContract, from, ids, values, data);
        }
        // Ensure the data is valid
        require(ids.length == values.length, "different ids and values");
        // Record each separate token
        for (uint i = 0; i < ids.length; i++) {
            // The identifier of the token in the token smart contract
            uint256 id = ids[i];
            uint256 amount = values[i];
            // Record each "amount" of the token as a separate stake
            for (uint j = 0; j < amount; j++) {
                _recordStake(from, tokenContract, id, TokenType.ERC1155);
            }
        }
        // As per the IERC1155Receiver interface this has to be returned on success
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Stake multiple tokens in batch. Both ERC721 and ERC1155 tokens can be mixed. This
     * requires prior approval for _each_ address in contracts, preferably using setApprovalForAll.
     * This is not explicitly checked by this function. If an approval is missing the transaction
     * will revert.
     * @param contracts The addresses of the token smart contracts to stake
     * @param tokens The ids of the tokens per contract to stake
     * @param amounts The amounts of tokens per contract to stake, only relevant for ERC1155.
     * For ERC721 the "inner" array must be empty.
     * @param data Validation data for the stake operation. Might be used depending on the @link
     * validator and based on it have certain restrictions.
     */
    function stake(
        address[] calldata contracts, uint256[][] calldata tokens, uint256[][] calldata amounts,
        bytes calldata data
    ) external {
        // Batch stake works by transferring the tokens on behalf of the user. This requires
        // approval of the individual tokens/the collection using the ERC721/ERC1155
        // approve/setApprovalForAll functions. The actual stake record is created by the "normal"
        // receive callbacks.
        require(contracts.length == tokens.length, "incorrect length of tokens");
        require(contracts.length == amounts.length, "incorrect length of amounts");
        validator.validateBatchStake(contracts, tokens, amounts, data);
        // Temporary set the validation skip to true so the callbacks being triggered by
        // safeTransferFrom do not validate again. This works as callbacks are executed
        // synchronously.
        skipValidation = true;
        for (uint i = 0; i < contracts.length; i++) {
            address contractAddress = contracts[i];
            // Use the contract as an ERC165 to check if its ERC721 or ERC1155
            IERC165 tokenContract = IERC165(contractAddress);
            // Variable holding the token ids to be transferred for the given contract
            uint256[] memory contractTokens = tokens[i];
            if (tokenContract.supportsInterface(type(IERC721).interfaceId)) {
                // For ERC721, iterate over all tokens and transfer them one by one
                IERC721 erc721 = IERC721(contractAddress);
                for (uint j = 0; j < contractTokens.length; j++) {
                    // The data parameter can be set to empty. Since skipValidation is true it won't
                    // be used.
                    erc721.safeTransferFrom(msg.sender, address(this), contractTokens[j], "");
                }
            } else if (tokenContract.supportsInterface(type(IERC1155).interfaceId)) {
                // For ERC1155 use the batch transfer facility to stake all tokens.
                IERC1155 erc1155 = IERC1155(contractAddress);
                // The ERC1155 contract validates that the tokens and amounts array have the same
                // length. The data parameter can be set to empty. Since skipValidation is true it
                // won't be used.
                erc1155.safeBatchTransferFrom(msg.sender, address(this), contractTokens, amounts[i],
                    "");
            } else {
                revert("unsupported contract");
            }
        }
        // Reset the temporary change to the validation skip
        skipValidation = false;
    }

    /**
     * @dev Unstake multiple staked tokens. This will make them enter the unstake status and they
     * can be claimed after unstakePeriodSeconds.
     * @param recordIds The stake record ids to unstake
     */
    function unstake(uint256[] calldata recordIds) external {
        uint256 totalStaked = activeStakes[msg.sender];
        // This does not just call "unstake(recordId)" in a loop to avoid modifying state in a loop,
        // the activeStake count. This would cost more gas.
        for (uint256 i = 0; i < recordIds.length; i++) {
            StakeRecord storage record = _getStake(recordIds[i], msg.sender);
            // Ensure the token is not already unstaked
            require(record.claimableAt == 0, "already unstaking");
            // Set the claimable at time in the future
            record.claimableAt = block.timestamp + unstakePeriodSeconds;
            // Subtract one from the amount of active stakes as there is one less now
            totalStaked--;
            emit TokenUnstaked(
                msg.sender, record.id, record.tokenContract, record.tokenId, record.tokenType,
                record.claimableAt, totalStaked
            );
        }
        // Store the total amount staked
        activeStakes[msg.sender] = totalStaked;
    }

    /**
     * @dev Claim a unstaked tokens. This will send it back to the original owner.
     * @param recordIds The stake record ids to claim
     */
    function claim(uint256[] calldata recordIds) external {
        for (uint256 i = 0; i < recordIds.length; i++) {
            uint256 recordId = recordIds[i];
            StakeRecord memory record = _getStake(recordId, msg.sender);
            // Verify the token was unstaked
            require(record.claimableAt != 0, "token not unstaked");
            // Verify the unstake period has passed
            require(record.claimableAt <= block.timestamp, "token not claimable yet");
            // Erase the record of the stake
            _erase(recordId, msg.sender);

            if (record.tokenType == TokenType.ERC721) {
                IERC721(record.tokenContract).safeTransferFrom(address(this), msg.sender,
                    record.tokenId);
            } else {
                IERC1155(record.tokenContract).safeTransferFrom(address(this), msg.sender,
                    record.tokenId, 1, "");
            }
            emit TokenClaimed(
                msg.sender, record.id, record.tokenContract, record.tokenId, record.tokenType
            );
        }
    }

    /**
     * @dev Get a stake record by record id and owner. Uses the index mapping to find the record.
     * @param recordId The stake record if of the record to find
     * @param owner The address owning the stake
     */
    function _getStake(
        uint256 recordId, address owner
    ) private view returns (StakeRecord storage)  {
        // Get the index in the record array of the owner.
        uint256 index = idToIndex[recordId];
        require(index != 0, "record does not exist");
        // Remove the offset from the index to get the actual value. see _recordStake
        index -= 1;
        // Verify the index can exist
        require(index < stakes[owner].length, "record does not belong to owner - index impossible");
        // Access the actual record
        StakeRecord storage record = stakes[owner][index];
        // Check again that the id is the one we expect, since the index can be ambiguous
        require(record.id == recordId, "record does not belong to owner - wrong id");
        return record;
    }

    /**
     * @dev Stores the stake of a token
     * @param owner The original owner of the token
     * @param tokenContract The token smart contract
     * @param tokenId The id of the token in its smart contract
     * @param tokenType The type of token
     */
    function _recordStake(
        address owner, address tokenContract, uint256 tokenId, TokenType tokenType
    ) private {
        // Verify the owner does not exceed their maximum number of stakes
        require(activeStakes[owner] < MAX_ACTIVE_STAKES, "cannot stake more");
        // Get a new id for the stake record
        uint256 id = nextId.current();
        nextId.increment();
        StakeRecord memory record = StakeRecord(id, tokenContract, tokenId, 0, tokenType);
        // Get the other stakes of the owner
        StakeRecord[] storage stakesForOwner = stakes[owner];
        stakesForOwner.push(record);
        // Store the index of the new record in the index mapping. The stored index is offset by 1
        // so we can use the default "0" as non-existent, hence the usage of length after adding
        // the element.
        idToIndex[record.id] = stakesForOwner.length;
        // Increase the amount of active stakes for the owner
        uint256 totalStaked = activeStakes[owner]++;
        emit TokenStaked(owner, id, tokenContract, tokenId, tokenType, totalStaked);
    }

    /**
     * @dev Erase a stake record. Does not send the NFT back!
     * @param recordId The stake record if of the record to find
     * @param owner The address owning the stake
     */
    function _erase(uint256 recordId, address owner) private {
        // Get the index in the record array of the owner.
        uint256 index = idToIndex[recordId];
        require(index > 0, "record does not exist");
        // Remove the offset from the index to get the actual value. see _recordStake
        index -= 1;
        StakeRecord[] storage _stakes = stakes[owner];
        // Verify the index can exist and if it does, the entry belonging to it has the same record
        // id that is to be deleted.
        require(index < _stakes.length && _stakes[index].id == recordId,
            "record does not belong to caller");

        // Check if the last element of the array is being deleted. If not, reorganize the array so
        // the element to delete is at the end of it, to be able to use "pop".
        if (index != _stakes.length - 1) {
            // Move the last item in the array to the gap created by deletion
            StakeRecord storage reorgItem = _stakes[_stakes.length - 1];
            _stakes[index] = reorgItem;

            // Update the id->index mapping for moved item, again with the index offset by +1
            idToIndex[reorgItem.id] = index + 1;
        }
        // Delete the element which is now guaranteed to be at the end of the array
        _stakes.pop();
        // Delete the id to index mapping
        delete idToIndex[recordId];
    }

    /**
     * @dev Get all staked and unstaked tokens for an address.
     * @param owner The address owning the stakes
     */
    function getStakesForAddress(address owner) public view returns (StakeRecord[] memory) {
        return stakes[owner];
    }
}

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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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