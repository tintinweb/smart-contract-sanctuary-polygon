pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/ILinearPool.sol";

contract Governor is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    uint256 public proposalCount;
    uint256 public delayPeriod;
    uint256 public votingPeriod;
    address public stakingPool;

    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public proposalCountsByUsers;
    mapping(address => uint256[]) public proposalsByUsers;
    mapping(uint256 => mapping(address => Voting)) public votingDetails;
    mapping(uint256 => string) public adminCanceledProposals;
    mapping(address => uint256) public lastProposalCreateTime;
    mapping(address => bool) public banList;

    struct Proposal {
        uint256 id;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        string name;
        string description;
        bytes hashData;
        bool canceled;
        bool executed;
    }

    struct Voting {
        bool hasVoted;
        bool support;
        uint256 weight;
    }

    struct AdminCanceledProposal {
        uint256 proposalId;
        string cancelingReason;
    }

    struct BannedUserStruct {
        address user;
        string reason;
        bool isBanned;
    }

    event ProposalAdded(
        uint256 proposalId,
        address proposer,
        uint256 startTime,
        uint256 endTime,
        string name,
        string description,
        bytes hashData
    );
    event Voted(address user, uint256 proposalId, uint256 weight, bool support);
    event ProposalCanceledByAdmin(uint256 proposalId, string reason);
    event UserBanned(address user, string reason, bool isBanned);

    function initialize(
        address _stakingPool,
        uint256 _delayPeriod,
        uint256 _votingPeriod
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        stakingPool = _stakingPool;
        delayPeriod = _delayPeriod;
        votingPeriod = _votingPeriod;
    }

    function addProposal(
        string memory _name,
        string memory _description,
        bytes calldata _hashData
    ) external nonReentrant {
        require(
            lastProposalCreateTime[msg.sender] + delayPeriod + votingPeriod <
                block.timestamp ||
                msg.sender == owner(),
            "Governor: You have added proposal recently"
        );
        require(
            !banList[msg.sender],
            "Governor: You have been banned from adding proposals"
        );
        require(
            bytes(_name).length != bytes("").length,
            "Governor: Name cannot be empty"
        );
        require(
            bytes(_description).length != bytes("").length,
            "Governor: Description cannot be empty"
        );

        proposalCount += 1;
        proposals[proposalCount].id = proposalCount;
        proposals[proposalCount].proposer = msg.sender;
        proposals[proposalCount].startTime = block.timestamp + delayPeriod;
        proposals[proposalCount].endTime =
            block.timestamp +
            delayPeriod +
            votingPeriod;
        proposals[proposalCount].name = _name;
        proposals[proposalCount].description = _description;
        proposals[proposalCount].hashData = _hashData;

        lastProposalCreateTime[msg.sender] = block.timestamp;
        
        proposalCountsByUsers[msg.sender] += 1;
        proposalsByUsers[msg.sender].push(proposalCount);

        emit ProposalAdded(
            proposalCount,
            msg.sender,
            block.timestamp + delayPeriod,
            block.timestamp + delayPeriod + votingPeriod,
            _name,
            _description,
            _hashData
        );
    }

    function adminProposalCancel(bytes calldata data) external onlyOwner {
        AdminCanceledProposal[] memory canceledProposals = abi.decode(
            data,
            (AdminCanceledProposal[])
        );
        uint256 arrLength = canceledProposals.length;
        require(arrLength > 0, "Empty array");
        for (uint256 i = 0; i < arrLength; i++) {
            uint256 id = canceledProposals[i].proposalId;
            adminCanceledProposals[id] = canceledProposals[i].cancelingReason;
            proposals[id].canceled = true;
            emit ProposalCanceledByAdmin(
                id,
                canceledProposals[i].cancelingReason
            );
        }
    }

    function ban(bytes calldata data) external onlyOwner {
        BannedUserStruct[] memory bannedUser = abi.decode(
            data,
            (BannedUserStruct[])
        );
        uint256 arrLength = bannedUser.length;
        require(arrLength > 0, "Empty array");
        for (uint256 i = 0; i < arrLength; i++) {
            banList[bannedUser[i].user] = bannedUser[i].isBanned;
            emit UserBanned(
                bannedUser[i].user,
                bannedUser[i].reason,
                bannedUser[i].isBanned
            );
        }
    }

    function markAsExecuted(bytes calldata data) external onlyOwner {
        uint256[] memory executedProposals = abi.decode(data, (uint256[]));
        uint256 arrLength = executedProposals.length;
        require(arrLength > 0, "Empty array");
        for (uint256 i = 0; i < arrLength; i++) {
            uint256 id = executedProposals[i];
            require(
                proposals[id].endTime < block.timestamp,
                "Governor: Voting has not finished yet"
            );
            proposals[id].executed = true;
        }
    }

    function vote(uint256 proposalId, bool support) external nonReentrant {
        require(
            !banList[msg.sender],
            "Governor: You have been banned from voting"
        );
        require(
            !votingDetails[proposalId][msg.sender].hasVoted,
            "Governor: You have already voted for this proposal"
        );
        require(
            proposals[proposalId].startTime < block.timestamp,
            "Governor: Voting for this proposal has not been started yet"
        );
        require(
            proposals[proposalId].endTime > block.timestamp,
            "Governor: Voting for this proposal is close"
        );

        uint256 share = weight(msg.sender);

        votingDetails[proposalId][msg.sender].hasVoted = true;
        votingDetails[proposalId][msg.sender].support = support;
        votingDetails[proposalId][msg.sender].weight = share;

        if (support) {
            proposals[proposalId].forVotes += share;
        } else {
            proposals[proposalId].againstVotes += share;
        }

        emit Voted(msg.sender, proposalId, share, support);
    }

    function weight(address user) public returns (uint256 share) {
        require(!banList[msg.sender], "Governor: You have been banned");
        share = 5000;
    }

    function canVote(address user)
        external
        view
        returns (bool isBanned, bool isStaker)
    {
        isBanned = banList[user];
        isStaker = true;
    }

    function userVoteInfo(address user, uint256 proposalId)
        external
        view
        returns (Voting memory voting)
    {
        voting = votingDetails[proposalId][user];
    }

    function getProposalStatus(uint256 proposalId)
        external
        view
        returns (uint8 status)
    {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.executed) {
            status = 2;
        } else if (
            proposal.canceled ||
            (block.timestamp > proposal.endTime &&
                proposal.againstVotes > proposal.forVotes)
        ) {
            status = 3;
        } else if (
            block.timestamp > proposal.startTime &&
            block.timestamp < proposal.endTime
        ) {
            status = 0;
        } else {
            status = 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

pragma solidity ^0.8.0;

interface ILinearPool {
    function commonAmount() external returns (uint256);
    function commonBalanceOf(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}