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

pragma solidity 0.8.9;

import "../../interfaces/ISystemPause.sol";

abstract contract AbstractSystemPause {
    /// bool to store system status
    bool public systemPaused;
    /// System pause interface
    ISystemPause system;

    /* ========== ERROR STATEMENTS ========== */

    error UnauthorisedAccess();
    error SystemPaused();

    /**
     @dev this modifier calls the SystemPause contract. SystemPause will revert
     the transaction if it returns true.
     */
    modifier onlySystemPauseContract() {
        if (address(system) != msg.sender) revert UnauthorisedAccess();
        _;
    }

    /**
     @dev this modifier calls the SystemPause contract. SystemPause will revert
     the transaction if it returns true.
     */

    modifier whenSystemNotPaused() {
        if (systemPaused) revert SystemPaused();
        _;
    }

    function pauseSystem() external virtual onlySystemPauseContract {
        systemPaused = true;
    }

    function unpauseSystem() external virtual onlySystemPauseContract {
        systemPaused = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../core/security/AbstractSystemPause.sol";
import "../interfaces/ISystemPause.sol";
import "../interfaces/IGovernanceV1.sol";
import "../interfaces/IAccess.sol";
import "../interfaces/IWeightCalculator.sol";
import "../libraries/WeightCalculatorLib.sol";
import "../libraries/VoteLib.sol";

/**
@title WeightCalculator contract
@notice this contract stores pre normalised vote weight, calculates and stores the normalised weight for proposal votes 
 
 */

contract WeightCalculator is IWeightCalculator, AbstractSystemPause {
    using WeightCalculatorLib for *;
    using VoteLib for *;

    /* ========== STATE VARIABLES ========== */

    IGovernanceV1 governance;
    // Access contract
    IAccess access;
    /// System pause contract
    ISystemPause systemPause;

    //mapping of id to vote weight data
    mapping(uint32 => WeightCalculatorLib.VoteWeightData) voteWeightData;

    /* ========== EVENTS ========== */

    event VotersNormalisedVoteWeight(
        uint32 id,
        address indexed voter,
        uint256 normalisedWeight
    );

    event NormalisedWeightCalculationComplete(uint32 _id);
    event LatestTotalWeight(uint32 id, uint256 weight);
    event VotersPreNormalisedWeight(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _weight,
        address indexed _voter,
        uint256 index
    );
    event GovernanceAddress(address _governanceAddress);

    /* ========== REVERT STATEMENTS ========== */

    error InvalidAddress();
    error NormalisedWeightHasBeenUpdated(
        address voter,
        uint256 normalisedWeight
    );

    /* ========== MODIFIERS ========== */

    /**
     @dev only callable by the Governance contract
     */

    modifier onlyGovernanceContract() {
        require(
            address(governance) != address(0),
            "WeightCalculator: please update WeightCalculator with the governance address"
        );
        require(
            msg.sender == address(governance),
            "WeightCalculator: unauthorised access"
        );
        _;
    }

    /**
     @dev this modifier calls the Access contract. Reverts if caller does not have role
     */

    modifier onlyGovernanceRole() {
        access.onlyGovernanceRole(msg.sender);
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address _access, address _systemPause) {
        access = IAccess(_access);
        systemPause = ISystemPause(_systemPause);
    }

    /* ========== EXTERNAL ========== */

    function setGovernanceAddress(
        address _governance
    ) external virtual override onlyGovernanceRole {
        if (_governance == address(0)) revert InvalidAddress();
        governance = IGovernanceV1(_governance);

        emit GovernanceAddress(_governance);
    }

    /**
     @dev this function will store the voters vote weight after voter has casted their vote
     @param _id. The id for vote weight data 
     @param _vote. The voter's vote choice 
     @param _weight. The voter's vote weight 
     @param _voter. The voter's address
     */

    function storePreNormalisedWeight(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _weight,
        address _voter
    ) external virtual override whenSystemNotPaused onlyGovernanceContract {
        WeightCalculatorLib.VoteWeightData storage data = voteWeightData[_id];
        data.storeVotersPreNormalisedWeight(_vote, _weight, _voter);

        emit VotersPreNormalisedWeight(
            _id,
            _vote,
            _weight,
            _voter,
            data.totalVotersPerVote[_vote]
        );
    }

    /**
     @dev this function will store the voters vote weight after voter has casted their vote
     @param _id. The id for vote weight data 
     @param _vote. The voter's vote choice 
     @param _startIndex. The start index
     @param _endIndex. The end index
     */

    function calculateNormalisedWeight(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _startIndex,
        uint256 _endIndex
    ) external virtual override whenSystemNotPaused onlyGovernanceContract {
        for (uint256 i = _startIndex; i < _endIndex; i++) {
            _calculateNormalisedWeight(_id, _vote, i);
            emit VotersNormalisedVoteWeight(
                _id,
                voteWeightData[_id].voteWeight[_vote][i].voter,
                voteWeightData[_id].voteWeight[_vote][i].normalisedWeight
            );
        }
    }

    /** 
    @dev this function returns the total number of voters for a given vote 
    @param _id. the proposal id.
    @param _vote. The vote to return the total voters for.
    */

    function getTotalVotersByVote(
        uint32 _id,
        VoteLib.Vote _vote
    ) external view virtual override returns (uint256) {
        return voteWeightData[_id].totalVotersPerVote[_vote];
    }

    /** 
    @dev this function returns the vote weight data for a voter
    @param _id. the id.
    @param _vote. The voter's vote choice 
    @param _index. The voter's index
    */

    function getVoteWeightDataForVoter(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _index
    )
        external
        view
        virtual
        override
        returns (WeightCalculatorLib.VoteWeight memory)
    {
        return voteWeightData[_id].voteWeight[_vote][_index];
    }

    function getTotalVoteWeight(
        uint32 _id
    ) external view virtual override returns (uint256) {
        return voteWeightData[_id].totalPreNormalisedWeight;
    }

    /** 
    @dev this function returns the total normalised weight for a vote
    @param _id. the id.
    @param _vote. The vote to return the normalised weight for
    */

    function getNormalisedWeightForVote(
        uint32 _id,
        VoteLib.Vote _vote
    ) external view virtual override returns (uint256) {
        return voteWeightData[_id].normalisedWeight[_vote];
    }

    /** 
    @dev this function returns true if the normalised calculations are completed
    @param _id. the id.
    */

    function calculationsComplete(
        uint32 _id
    )
        external
        virtual
        override
        whenSystemNotPaused
        onlyGovernanceContract
        returns (bool)
    {
        return voteWeightData[_id].calculationsComplete;
    }

    /* ========== INTERNAL ========== */

    /**
    @dev internal function to calculate and store the user's normalised vote weight and update the total weight for the given vote.
    @param _id. The vote data id
    @param _vote. The vote 
    @param _index. The index to access pre normalised weight
     */

    function _calculateNormalisedWeight(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _index
    ) internal {
        if (voteWeightData[_id].voteWeight[_vote][_index].normalisedWeight > 0)
            revert NormalisedWeightHasBeenUpdated(
                voteWeightData[_id].voteWeight[_vote][_index].voter,
                voteWeightData[_id].voteWeight[_vote][_index].normalisedWeight
            );

        WeightCalculatorLib.VoteWeightData storage data = voteWeightData[_id];

        data.storeNormalisedWeight(_vote, _index);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title Access interface
/// @notice Access is the main contract which stores the roles
abstract contract IAccess is ERC165 {
    /* ========== FUNCTIONS ========== */

    function userHasRole(bytes32 _role, address _address)
        external
        view
        virtual
        returns (bool);

    function onlyGovernanceRole(address _caller) external view virtual;

    function onlyEmergencyRole(address _caller) external view virtual;

    function onlyTokenRole(address _caller) external view virtual;

    function onlyBoostRole(address _caller) external view virtual;

    function onlyRewardDropRole(address _caller) external view virtual;

    function onlyStakingRole(address _caller) external view virtual;

    function onlyStakingPauserRole(address _caller) external view virtual;

    function onlyStakingFactoryRole(address _caller) external view virtual;

    function onlyStakingManagerRole(address _caller) external view virtual;

    function executive() public pure virtual returns (bytes32);

    function admin() public pure virtual returns (bytes32);

    function deployer() public pure virtual returns (bytes32);

    function emergencyRole() public pure virtual returns (bytes32);

    function tokenRole() public pure virtual returns (bytes32);

    function pauseRole() public pure virtual returns (bytes32);

    function governanceRole() public pure virtual returns (bytes32);

    function boostRole() public pure virtual returns (bytes32);

    function stakingRole() public pure virtual returns (bytes32);

    function rewardDropRole() public pure virtual returns (bytes32);

    function stakingFactoryRole() public pure virtual returns (bytes32);

    function stakingManagerRole() public pure virtual returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract IGovernanceV1 is ERC165 {
    /* ========== TYPE DECLARATIONS ========== */

    struct ProposalData {
        string proposalRef;
        string url;
        uint256 start;
        uint256 end;
        uint256 created;
        ProposalState state;
        VoteModel voteModel;
        string category;
        bool isExecutable;
        bool paused;
        uint8 threshold;
        string outcome;
    }

    struct ExecutableData {
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
    }

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    enum Proposers {
        Exec,
        High,
        Community
    }

    enum VoteModel {
        ForAgainst,
        ForAgainstAbstain,
        MultiChoice
    }

    /* ========== EVENTS ========== */

    event NewProposal(uint32 indexed id, ProposalData proposal);
    event NewQuorumThreshold(uint96 newThreshold);
    event NewQuorumMinimumAccounts(uint256 newThreshold);
    event NewProposerThreshold(uint256 newThreshold);
    event NewProposers(Proposers proposers);
    event ProposalCancelled(uint32 indexed id);
    event NewProposalState(uint32 indexed id, ProposalState proposalState);
    event ProposalOutcome(
        uint32 indexed id,
        string outcome,
        ProposalState proposalState
    );
    event PausedProposal(uint32 indexed id);
    event UnpausedProposal(uint32 indexed id);

    /* ========== REVERT STATEMENTS ========== */

    error ProposalExists(uint256 proposalHash);
    error AddressError();
    error VotingPeriodError(uint256 start, uint256 end);
    error InvalidProposalState(uint32 id, ProposalState state);
    error VoteCasted(uint32 id, address voter);
    error OutsideVotePeriod();
    error VoteNotEnded();
    error InvalidVoter();
    error ProposalPaused(uint32 id);
    error ProposalUnpaused(uint32 id);
    error HighThresholdIsZero();
    error InvalidThreshold();
    error InvalidId(uint32 id);
    error ReducePageLength(uint32 id, uint16 pageLength, uint256 index);
    error ThresholdTooLow();

    /* ========== FUNCTIONS ========== */

    function proposeNonExecutable(
        string memory _description,
        string memory _url,
        uint256 _start,
        uint256 _end,
        VoteModel _voteModel,
        string memory _category,
        uint8 _threshold
    ) external virtual;

    function setFlatMinimum(uint256 _newThreshold) external virtual;

    function setHighThreshold(uint256 _newThreshold) external virtual;

    function setQuorumThreshold(uint8 _newThreshold) external virtual;

    function setProposers(Proposers _proposers) external virtual;

    function cancelProposal(uint32 _id) external virtual;

    function completeProposal(uint32 _id) external virtual;

    function getProposal(
        uint32 _id
    ) external view virtual returns (ProposalData memory);

    function getPaginatedProposals(
        uint16 _pageLength,
        uint16 _page,
        uint8 _direction
    ) external view virtual returns (ProposalData[] memory);

    function getProposalCount() external view virtual returns (uint32);

    function getProposalOutcome(uint32 _id) external virtual;

    function getTotalVoters(uint32 _id) external view virtual returns (uint256);

    function pauseContract() external virtual;

    function unpauseContract() external virtual;

    function pauseProposal(uint32 _id) external virtual;

    function unpauseProposal(uint32 _id) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title Pause interface
abstract contract ISystemPause is ERC165 {
    /* ========== REVERT STATEMENTS ========== */

    error SystemPaused();
    error UnauthorisedAccess();
    error InvalidAddress();
    error InvalidModuleName();
    error UpdateStakingManagerAddress();
    error CallUnsuccessful(address contractAddress);

    /* ========== EVENTS ========== */

    event PauseStatus(uint indexed moduleId, bool isPaused);
    event NewModule(
        uint indexed moduleId,
        address indexed contractAddress,
        string indexed name
    );
    event UpdatedModule(
        uint indexed moduleId,
        address indexed contractAddress,
        string indexed name
    );

    /* ========== FUNCTIONS ========== */

    function setStakingManager(address _stakingManagerAddress) external virtual;

    function pauseModule(uint id) external virtual;

    function unPauseModule(uint id) external virtual;

    function createModule(
        string memory name,
        address _contractAddress
    ) external virtual;

    function updateModule(uint id, address _contractAddress) external virtual;

    function getModuleStatusWithId(
        uint id
    ) external view virtual returns (bool isActive);

    function getModuleStatusWithAddress(
        address _contractAddress
    ) external view virtual returns (bool isActive);

    function getModuleAddressWithId(
        uint id
    ) external view virtual returns (address module);

    function getModuleIdWithAddress(
        address _contractAddress
    ) external view virtual returns (uint id);

    function getModuleIdWithName(
        string memory name
    ) external view virtual returns (uint id);

    function getModuleNameWithId(
        uint id
    ) external view virtual returns (string memory name);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../libraries/WeightCalculatorLib.sol";

abstract contract IWeightCalculator is ERC165 {
    function setGovernanceAddress(address _governance) external virtual;

    function calculateNormalisedWeight(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _startIndex,
        uint256 _endIndex
    ) external virtual;

    function storePreNormalisedWeight(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _weight,
        address _voter
    ) external virtual;

    function getTotalVotersByVote(
        uint32 _id,
        VoteLib.Vote _vote
    ) external view virtual returns (uint256);

    function getVoteWeightDataForVoter(
        uint32 _id,
        VoteLib.Vote _vote,
        uint256 _index
    ) external view virtual returns (WeightCalculatorLib.VoteWeight memory);

    function getNormalisedWeightForVote(
        uint32 _id,
        VoteLib.Vote _vote
    ) external view virtual returns (uint256);

    function getTotalVoteWeight(
        uint32 _id
    ) external view virtual returns (uint256);

    function calculationsComplete(uint32 _id) external virtual returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
@title VoteLib library
@notice this is a library for counting votes and return the proposal outcome
 
 */

library VoteLib {
    /* ========== TYPE DECLARATIONS ========== */
    struct VoteData {
        uint256 forVotes;
        uint256 againstVotes;
        uint256 aVotes;
        uint256 bVotes;
        uint256 cVotes;
        uint256 abstainVotes;
        uint256 totalVoters;
    }

    enum Vote {
        For,
        Against,
        A,
        B,
        C,
        Abstain
    }

    /* ========== ERROR STATEMENTS ========== */

    error InvalidVote(Vote _vote);

    /* ========== FUNCTIONS ========== */

    /** @dev this functions counts votes for ForAgainst Proposals. 
        It stores the vote weight. Reverts if the vote is not valid for the proposal. 
        It stores that the users has now voted. 
        It increments the total number of voters. 
        @return VoteData struct
     */

    function countVoteForAgainst(
        VoteData storage data,
        VoteLib.Vote vote,
        uint256 weight
    ) internal returns (VoteData storage) {
        if (vote == Vote.For) {
            data.forVotes += weight;
        } else if (vote == Vote.Against) {
            data.againstVotes += weight;
        } else revert InvalidVote(vote);
        ++data.totalVoters;
        return data;
    }

    /** @dev this functions counts votes for ForAgainstAbstain Proposals. 
        It stores the vote weight. Reverts if the vote is not valid for the proposal. 
        It stores that the users has now voted. 
        It increments the total number of voters. 
        @return VoteData struct
     */

    function countVoteForAgainstAbstain(
        VoteData storage data,
        Vote vote,
        uint256 weight
    ) internal returns (VoteData storage) {
        if (vote == Vote.For) {
            data.forVotes += weight;
        } else if (vote == Vote.Against) {
            data.againstVotes += weight;
        } else if (vote == Vote.Abstain) {
            data.abstainVotes += weight;
        } else {
            revert InvalidVote(vote);
        }
        ++data.totalVoters;
        return data;
    }

    /** @dev this functions counts votes for MultiChoice Proposals. 
        It stores the vote weight. Reverts if the vote is not valid for the proposal. 
        It stores that the users has now voted. 
        It increments the total number of voters. 
        @return VoteData struct
     */

    function countVoteMultiChoice(
        VoteData storage data,
        Vote vote,
        uint256 weight
    ) internal returns (VoteData storage) {
        if (vote == Vote.A) {
            data.aVotes += weight;
        } else if (vote == Vote.B) {
            data.bVotes += weight;
        } else if (vote == Vote.C) {
            data.cVotes += weight;
        } else if (vote == Vote.Abstain) {
            data.abstainVotes += weight;
        } else revert InvalidVote(vote);
        ++data.totalVoters;
        return data;
    }

    /** @dev this function returns the outcome for for against proposals */

    function getOutcomeForAgainst(
        VoteData memory data
    ) internal pure returns (string memory outcome) {
        (data.forVotes > data.againstVotes)
            ? outcome = "Succeeded"
            : outcome = "Defeated";
        if (data.forVotes == data.againstVotes) outcome = "Draw";

        return outcome;
    }

    /** @dev this function returns the outcome for multichoice proposals */

    function getOutcomeMultiChoice(
        VoteData memory data
    ) internal pure returns (string memory outcome) {
        uint256 winningVote;
        uint256 drawingVote;

        uint256[3] memory votes;

        votes[0] = data.aVotes;
        votes[1] = data.bVotes;
        votes[2] = data.cVotes;

        for (uint256 i = 0; i < votes.length; i++) {
            if (votes[i] > winningVote) {
                winningVote = votes[i];
            } else if (votes[i] == winningVote) {
                drawingVote = votes[i];
            }
        }

        if (winningVote != 0 && winningVote != drawingVote) {
            outcome = "Succeeded";
        } else if (winningVote == drawingVote) {
            outcome = "Draw";
        } else outcome = "Defeated";

        return outcome;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./VoteLib.sol";

/**
@title WeightCalculatorLib library
@notice this is a library for updating the pre normalised weight, calculating calculating the normalised weight and returning the proposal's outcome
 
 */

library WeightCalculatorLib {
    /* ========== TYPE DECLARATIONS ========== */

    struct VoteWeightData {
        mapping(VoteLib.Vote => mapping(uint256 => VoteWeight)) voteWeight;
        mapping(VoteLib.Vote => uint256) totalVotersPerVote;
        mapping(VoteLib.Vote => uint256) normalisedWeight;
        uint256 totalPreNormalisedWeight;
        bool calculationsComplete;
    }

    struct VoteWeight {
        address voter;
        uint256 preNormalisedWeight;
        uint256 normalisedWeight;
    }
    /* ========== CONSTANTS ========== */

    /// Rebalancing factor to assist with division
    uint256 constant BPS = 1e18;

    /* ========== FUNCTIONS ========== */

    /**
    @dev this function stores the pre normalised weight for the given voter and updates the total weight
    */

    function storeVotersPreNormalisedWeight(
        VoteWeightData storage data,
        VoteLib.Vote vote,
        uint256 weight,
        address voter
    ) internal returns (VoteWeightData storage) {
        data.totalVotersPerVote[vote]++;

        data.voteWeight[vote][data.totalVotersPerVote[vote]].voter = voter;

        data
        .voteWeight[vote][data.totalVotersPerVote[vote]]
            .preNormalisedWeight = weight;

        data.totalPreNormalisedWeight += weight;
        return data;
    }

    /**
    @dev this function calculates and stores the normalised weight, and updates the total normalised weight for the vote
    */

    function storeNormalisedWeight(
        VoteWeightData storage data,
        VoteLib.Vote _vote,
        uint256 _index
    ) internal {
        uint256 normalisedWeight = (data
        .voteWeight[_vote][_index].preNormalisedWeight * BPS) /
            data.totalPreNormalisedWeight;

        data.voteWeight[_vote][_index].normalisedWeight = normalisedWeight;

        data.normalisedWeight[_vote] += normalisedWeight;
    }
}