//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBribePool.sol";

import "../helper/Errors.sol";

////////////////////////////////////////////////////////////////////////////////////////////
///
/// @title Bribe Pool Factory
/// @author [email protected]
/// @notice
///
////////////////////////////////////////////////////////////////////////////////////////////

contract BribePoolFactory is Ownable {
    /// @dev address of the token used to bribe
    address public immutable bidAsset;

    /// @dev implementation address of the bribe pool contract
    address public bribePoolImplementation;

    /// @dev mapping of bribe pools to it's addresses
    mapping(string => address) public bribePools;

    event CreatedNewBribePool(address indexed bribePool, string indexed protocolName);
    event ChangeBribePoolImplementation(address bribePoolImplementation);

    /// @dev initialize the bribe pool factory. can be called only once
    /// @param _admin contract admin
    /// @param _bribePoolImplementation implementation address of the bribe pool contract
    /// @param _bidAsset address of the token used to bribe (will be usdc)
    constructor(
        address _admin,
        address _bribePoolImplementation,
        address _bidAsset
    ) Ownable() {
        require(_bribePoolImplementation != address(0), Errors.ZERO_ADDRESS);
        require(_bidAsset != address(0), Errors.ZERO_ADDRESS);

        super.transferOwnership(_admin);
        bribePoolImplementation = _bribePoolImplementation;
        bidAsset = _bidAsset;
    }

    /// @dev create a new bribe pool (ex: AavePool, CompoundPool)
    /// @param _protocolName name of pool
    /// @param bribePoolOwner owner the new bribe pool that will be created
    /// @param protocolFeeCollector address which recevies the protocol fee generated from the bribe pool
    /// @param _cancellationPenalty cancellation penalty
    /// @param _withdrawFee withdraw fee
    /// @param _rewardFee reward fee
    /// @param _minimumDepositForPotRefund minimum deposit that should be available in pot for refund
    /// @param _potExpirationInDays pot expiration in days
    function createBribePool(
        address bribePoolOwner,
        address protocolFeeCollector,
        uint256 _cancellationPenalty,
        uint256 _withdrawFee,
        uint256 _rewardFee,
        uint256 _minimumDepositForPotRefund,
        uint256 _potExpirationInDays,
        string calldata _protocolName
    ) external onlyOwner returns (address) {
        address newClone = ClonesUpgradeable.clone(bribePoolImplementation);
        IBribePool(newClone).initialize(
            _protocolName,
            bribePoolOwner,
            bidAsset,
            protocolFeeCollector,
            _cancellationPenalty,
            _withdrawFee,
            _rewardFee,
            _minimumDepositForPotRefund,
            _potExpirationInDays
        );
        bribePools[_protocolName] = newClone;
        emit CreatedNewBribePool(newClone, _protocolName);
        return newClone;
    }

    /// @dev change bribe pool implementation address
    /// @param _newBribePoolImplementation implementation address of the new bribe pool contract
    function changeBribePoolImplementation(address _newBribePoolImplementation) external onlyOwner {
        bribePoolImplementation = _newBribePoolImplementation;
        emit ChangeBribePoolImplementation(_newBribePoolImplementation);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IBribePool {
    /// @dev Pot state
    enum PotState {
        NOT_CREATED, // no deposit yet
        ACTIVE, // pot is not expired nor executed
        EXPIRED, // pot is expired with no merkle root is submitted
        NOT_PASSED, // merkle root is submited for another pot, and the pot option is not passed
        EXECUTED, // pot option is executed and recipient can claim rewards
        BRIBE_CAN_CLAIM_REWARDS, // both Bribe team and recipient can claim rewards
        CANCELLED // pot is cancelled
    }

    struct Proposal {
        bool executed;
        bool blocked;
    }

    /// @param totalVotes total votes accumulated by the pot
    /// @param totalDeposits total bribe put in the pot
    /// @param executedAt executed time
    /// @param rewardsRemained rewards remained
    /// @param merkleRoot merkle root
    struct Pot {
        uint256 totalVotes;
        uint256 totalDeposits;
        uint256 executedAt;
        uint256 rewardsRemained;
        uint256 expiry;
        bytes32 merkleRoot;
        bool cancelled;
    }

    /***************** events ****************/

    event BlockedProposal(bytes32 proposalId, bool blocked);
    event CancelledPot(address user, bytes32 indexed proposalId, uint256 optionIndex);
    event DepositedBribe(
        bytes32 indexed proposalId,
        uint256 optionIndex,
        address indexed to,
        uint256 amount
    );
    event SubmittedMerkleRoot(
        bytes32 proposalId,
        uint256 optionIndex,
        bytes32 indexed _merkleRoot,
        uint256 _totalVotes
    );
    event WithdrewDeposit(bytes32 indexed proposalId, uint256 optionIndex, uint256 amountToReceive);
    event ClaimedReward(
        bytes32 indexed proposalId,
        uint256 optionIndex,
        address indexed recipient,
        uint256 reward
    );

    /***************** functions ****************/

    /// @dev initialize the bribe pool
    /// @param _name name of the bribe pool
    /// @param _admin admin/owner of the bribe pool\
    /// @param _bidAsset address of the bribe token
    /// @param _protocolFeeCollector address that receives the protocol fee collected
    /// @param _cancellationPenalty cancellation penalty
    /// @param _withdrawFee withdraw fee
    /// @param _rewardFee reward fee
    /// @param _minimumDepositForPotRefund minimum deposit that should be available in pot for refund
    /// @param _potExpirationInDays pot expiration in days
    function initialize(
        string calldata _name,
        address _admin,
        address _bidAsset,
        address _protocolFeeCollector,
        uint256 _cancellationPenalty,
        uint256 _withdrawFee,
        uint256 _rewardFee,
        uint256 _minimumDepositForPotRefund,
        uint256 _potExpirationInDays
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

library Errors {
    string public constant ZERO_THRESHOLD = "0";
    string public constant ZERO_ADDRESS = "1";
    string public constant ZERO_AMOUNT = "2";
    string public constant ZERO_TOTAL_VOTES = "3";
    string public constant INVALID_MERKLE_ROOT = "4";
    string public constant NO_DEPOSIT = "5";
    string public constant REWARD_ALREADY_CLAIMED = "6";
    string public constant EXCEEDS_MAX_SCALE = "7";
    string public constant POT_DEPOSIT_LESS_THAN_MINIMUM = "8";
    string public constant INALID_MERKLE_PROOF = "9";
    string public constant CANNOT_WITHDRAW_BRIBE = "10";
    string public constant POT_CHOICE_NOT_EXECUTED = "11";
    string public constant POT_NOT_ACTIVE = "12";
    string public constant POT_EXPIRED = "13";
    string public constant INSUFFICIENT_DEPOSIT = "14";
    string public constant PROPOSAL_BLOCKED = "15";
    string public constant CANT_BE_ZERO = "16";
    string public constant ONLY_FEE_COLLECTOR = "17";
    string public constant ONLY_OPERATOR = "18";
    string public constant LESS_THAN_MINIMUM_POT_EXPIRY = "19";
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