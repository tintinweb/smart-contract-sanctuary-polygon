// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/IVEXT.sol";
import "../interfaces/ISystemPause.sol";
import "../interfaces/IAccess.sol";
import "../rewards/staking/StakingFactory.sol";
import "./Proposal.sol";
import "./Vote.sol";

/**
@title Veloce Governance contract
@notice this contract is the core contract for governance V1.
@author MDRxTech
 */

contract VeloceGovernanceV1 is
    Proposal,
    Vote,
    Initializable,
    PausableUpgradeable
{
    using VoteLib for *;

    /* ========== CONSTANTS ========== */

    uint256 constant REBALANCING_FACTOR = 10e18;

    /* ========== STATE VARIABLES ========== */

    /// Main access contract
    IAccess access;
    /// System pause contract
    ISystemPause system;
    /// VEXT interface
    IVEXT vext;
    /// Staking factory
    StakingFactory staking;
    /// Proposers is set to Proposers.Vext on deployment
    Proposers proposers;
    /// Mapping of ID => proposals
    mapping(uint256 => ProposalData) private _proposals;
    /// Mapping of ID hash => bool to indicate whether the proposal exists
    mapping(uint256 => bool) private _proposalExists;
    /// Flat minimum number of accounts that must have voted in order for a proposal to be accepted
    uint256 flatMinimum;
    /// VEXT threshold for Proposers.HighVext
    uint256 highVextThreshold;
    /// Counter for generating a human readable reference to the proposal
    uint32 id;
    /// Percentage threshold of total accounts that must have voted in order for a proposal to be accepted
    uint8 quorumThreshold;

    /* ========== MODIFIERS ========== */

    modifier onlyProposers() {
        _onlyProposers();
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    function initialize(
        address _accessAddress,
        address _systemPauseAddress,
        address _vextAddress,
        address _stakingFactoryAddress,
        uint256 _flatMinimum,
        uint256 _highVextThreshold,
        uint8 _quorumThreshold,
        Proposers _proposers
    ) public initializer {
        __Pausable_init();
        if (
            _vextAddress == address(0) ||
            _accessAddress == address(0) ||
            _stakingFactoryAddress == address(0)
        ) revert AddressError();

        if (_quorumThreshold == uint8(0) || _quorumThreshold == uint8(100))
            revert QuorumOutOfBounds();

        access = IAccess(_accessAddress);
        system = ISystemPause(_systemPauseAddress);
        vext = IVEXT(_vextAddress);
        staking = StakingFactory(_stakingFactoryAddress);
        flatMinimum = _flatMinimum;
        highVextThreshold = _highVextThreshold;
        quorumThreshold = _quorumThreshold;
        proposers = _proposers;
    }

    /**
    @dev this function is for creating a non executable proposal.
    @param _description. The description for proposal
    @param _start. Unix timestamp for voting start
    @param _end. Unix timestamp for voting end
    @param _voteModel. The model for voting
    @param _category. The proposal's category
    @param _threshold. The proposal's threshold
    */
    function proposeNonExecutable(
        string memory _description,
        uint256 _start,
        uint256 _end,
        VoteModel _voteModel,
        string memory _category,
        uint8 _threshold
    ) external virtual override onlyProposers whenNotPaused {
        system.isNotPaused();

        if (_votingPeriodError(_start, _end))
            revert VotingPeriodError(_start, _end);

        if (_thresholdBelowFlatMinimum(_threshold)) revert ThresholdTooLow();
        if (_threshold < quorumThreshold) revert QuorumOutOfBounds();

        uint256 proposalHash = uint256(keccak256(bytes(_description)));
        if (_proposalHashExists(proposalHash))
            revert ProposalExists(proposalHash);

        string memory proposalRef = string(
            abi.encodePacked(id, "_", _category)
        );

        ProposalData memory proposal = _proposal(
            proposalRef,
            _start,
            _end,
            _voteModel,
            _category,
            false,
            _threshold
        );

        _proposals[id] = proposal;
        _proposalExists[proposalHash] = true;

        emit NewProposal(id, proposal);

        id++;
    }

    /**
    @dev this function enables executive to cancel proposals
    @param _id. The id of the proposal

    Callable when system and governance is unpaused
    */
    function cancelProposal(uint256 _id)
        external
        virtual
        override
        whenNotPaused
    {
        system.isNotPaused();
        access.solelyRole(access.executive(), msg.sender);

        _changeProposalState(_id, ProposalState.Canceled);

        emit ProposalCancelled(_id);
    }

    /** 
    @dev this function is called when the user cast their vote during voting window.
    @param _id. The id hash for the proposal 
    @param _vote. The user's vote

    Callable when system and governance is unpaused
     */

    function castVote(uint256 _id, VoteLib.Vote _vote) external whenNotPaused {
        system.isNotPaused();

        if (vext.balanceOf(msg.sender) < 1e18) revert Unauthorised();
        if (hasVoted[_id][msg.sender]) revert VoteCasted(_id, msg.sender);

        uint256 current = block.timestamp;
        ProposalData storage proposal = _proposals[_id];

        if (proposal.state == ProposalState.Canceled)
            revert InvalidProposalState(_id, proposal.state);

        if (
            _outsideVotePeriod(proposal.start, current) ||
            _outsideVotePeriod(current, proposal.end)
        ) revert OutsideVotePeriod();

        if (proposal.state == ProposalState.Pending)
            _changeProposalState(_id, ProposalState.Active);

        uint256 weight = _getWeight(_id, msg.sender);

        _storeVote(_id, _vote, weight, msg.sender);
    }

    /**
    @dev this function returns the proposal outcome after the voting window has closed. 
    @param _id. The id of the proposal

    Only admin can get the proposal outcome

    Callable when system and governance is unpaused

    This function checks whether the voting window has closed
    It checks that flat minimum has been exceeded
    It checks whether the total voters is above the proposal threshold

    It returns the proposal outcome and the proposal state. 
    */
    function getProposalOutcome(uint256 _id)
        external
        virtual
        override
        whenNotPaused
    {
        system.isNotPaused();
        access.solelyRole(access.admin(), msg.sender);

        ProposalData memory proposal = _proposals[_id];
        VoteLib.VoteData memory votes = voteData[_id];
        string memory outcome;

        if (block.timestamp <= proposal.end) revert VoteNotEnded();
        if (proposal.state != ProposalState.Active)
            revert InvalidProposalState(_id, proposal.state);

        if (_thresholdBelowFlatMinimum(proposal.threshold)) {
            outcome = "Flat minimum not reached";
            _changeProposalState(_id, ProposalState.Defeated);
        } else if (_belowThreshold(votes.totalVoters, proposal.threshold)) {
            outcome = "Total voters below threshold";
            _changeProposalState(_id, ProposalState.Defeated);
        } else {
            outcome = _getOutcome(_id);
        }

        _storeOutcome(_id, outcome);

        keccak256(abi.encodePacked(outcome)) ==
            keccak256(abi.encodePacked("Succeeded"))
            ? _changeProposalState(_id, ProposalState.Succeeded)
            : _changeProposalState(_id, ProposalState.Defeated);

        emit ProposalOutcome(_id, proposal.outcome, proposal.state);
    }

    /** 
    @dev this functions is called by admin when the proposal has been completed
    @param _id. The proposal's id

    Callable when system and governance is unpaused
     */

    function completeProposal(uint256 _id)
        external
        virtual
        override
        whenNotPaused
    {
        system.isNotPaused();
        access.solelyRole(access.admin(), msg.sender);
        ProposalData memory proposal = _proposals[_id];

        if (proposal.state != ProposalState.Succeeded)
            revert InvalidProposalState(_id, proposal.state);

        _changeProposalState(_id, ProposalState.Executed);
    }

    /* ========== SETTINGS ========== */

    /**
    @dev this function sets the quorum minimum number of accounts
    @param _newThreshold. The new minimum number of accounts

    Only callable by executive. 
    Callable when system and governance is unpaused
    */
    function setFlatMinimum(uint256 _newThreshold)
        external
        virtual
        override
        whenNotPaused
    {
        system.isNotPaused();
        access.solelyRole(access.executive(), msg.sender);
        if (_newThreshold >= vext.getTotalAccounts()) revert ThresholdTooHigh();

        flatMinimum = _newThreshold;

        emit NewQuorumMinimumAccounts(flatMinimum);
    }

    /**
    @dev this function sets the minimum tokens a VEXT holder should hold to make a proposal
    @param _newThreshold. The amount in VEXT that a user should own in order to make a proposal

    _newThreshold is converted to wei internally. 

    Only callable by executive. 
    Callable when system and governance is unpaused
    */
    function setHighVextThreshold(uint256 _newThreshold)
        external
        virtual
        override
        whenNotPaused
    {
        system.isNotPaused();
        access.solelyRole(access.executive(), msg.sender);

        highVextThreshold = _newThreshold * 1e18;
        emit NewProposerThreshold(highVextThreshold);
    }

    /**
    @dev this function enables executive to change proposers
    @param _proposers. The new category of proposers allowed to make proposals

    Only callable by executive. 
    Callable when system and governance is unpaused
    */
    function setProposers(Proposers _proposers)
        external
        virtual
        override
        whenNotPaused
    {
        system.isNotPaused();
        access.solelyRole(access.executive(), msg.sender);

        proposers = _proposers;
        emit NewProposers(_proposers);
    }

    /** 
    @dev this function sets the quorum % threshold for all proposals.
    @param _newThreshold. The new global threshold that all proposal must meet in order for a proposal to pass.

    Only callable by executive. 
    Callable when system and governance is unpaused

    It checks that _newThreshold is a valid input and that it is not below the flat minimum.
     */

    function setQuorumThreshold(uint8 _newThreshold)
        external
        virtual
        override
        whenNotPaused
    {
        system.isNotPaused();
        access.solelyRole(access.executive(), msg.sender);

        if (_newThreshold == uint8(0) || _newThreshold >= uint8(100))
            revert QuorumOutOfBounds();
        if (_thresholdBelowFlatMinimum(_newThreshold)) revert ThresholdTooLow();
        quorumThreshold = _newThreshold;
        emit NewQuorumThreshold(quorumThreshold);
    }

    /**
     * @dev function to pause contract only callable by admin
     */
    function pauseContract() external virtual override {
        access.solelyRole(access.admin(), msg.sender);

        _pause();
    }

    /**
     * @dev function to unpause contract only callable by admin
     */
    function unpauseContract() external virtual override {
        access.solelyRole(access.admin(), msg.sender);

        _unpause();
    }

    /* ========== INTERNAL ========== */

    /**
     @dev this is an internal function which returns the proposal's outcome
    @param _id. The id of the proposal
     */
    function _getOutcome(uint256 _id)
        internal
        view
        returns (string memory outcome)
    {
        ProposalData memory proposal = _proposals[_id];

        if (proposal.voteModel == VoteModel.ForAgainst) {
            outcome = _outcomeForAgainst(_id);
            (_id);
        } else if (proposal.voteModel == VoteModel.ForAgainstAbstain) {
            outcome = _outcomeForAgainstAbstain(_id);
        } else {
            outcome = _outcomeMultiChoice(_id);
        }

        return (outcome);
    }

    /**
     @dev this is an internal function which store's the proposal's outcome
    @param _id. The id of the proposal
    @param _outcome. The outcome of the proposal
     */

    function _storeOutcome(uint256 _id, string memory _outcome) internal {
        ProposalData storage proposal = _proposals[_id];
        proposal.outcome = _outcome;
    }

    /**
    @dev internal function which returns the weight. The weight is the square root of the voter's balance at the point of proposal's creation (blocknumber creation).
    @param _id. The id for the proposal
    @param _voter. The voter's account
    */
    function _getWeight(uint256 _id, address _voter)
        internal
        view
        returns (uint256)
    {
        ProposalData memory proposal = _proposals[_id];
        uint256 checkpoint = proposal.created;

        uint256 weight = Math.sqrt(
            ((vext.getPastVotes(_voter, checkpoint)) +
                staking.getUserBalanceAtBlockNumber(_voter, checkpoint)) / 1e18
        );
        return weight;
    }

    /** 
    @dev internal function which calls the required count method depending on the Vote Model.
    @param _id. The id of the proposal
    @param _vote. The vote to store 
    @param _weight. The weight for the vote. 
    @param _voter. The voter's address.
    */

    function _storeVote(
        uint256 _id,
        VoteLib.Vote _vote,
        uint256 _weight,
        address _voter
    ) internal {
        ProposalData memory proposal = _proposals[_id];

        if (proposal.voteModel == VoteModel.ForAgainst) {
            _storeVoteForAgainst(_id, _vote, _weight, _voter);
        } else if (proposal.voteModel == VoteModel.ForAgainstAbstain) {
            _storeVoteForAgainstAbstain(_id, _vote, _weight, _voter);
        } else {
            _storeVoteMultiChoice(_id, _vote, _weight, _voter);
        }
    }

    /** @dev internal function which checks that the % threshold is greater than the flat minimum.
    @param _percentageThreshold. The % threshold.
    numberAccountsInThreshold is calculated by returning (total accounts * 10000) /1000 to return 1% of totalAccounts. It returns decimals by two. 
    We then multiply the return value by % threshold.
    If the returned numberAccounts is less than the flat minimum, return true.
    */

    function _thresholdBelowFlatMinimum(uint16 _percentageThreshold)
        internal
        view
        returns (bool thresholdTooLow)
    {
        uint256 numberAccountsInThreshold = ((vext.getTotalAccounts() *
            REBALANCING_FACTOR) / 1000) * uint256(_percentageThreshold);

        return
            numberAccountsInThreshold <
            ((uint256(flatMinimum) * REBALANCING_FACTOR) / 100);
    }

    /**
    @dev this function returns true if the total number of voters is below the quorum threshold.
    @param _totalVoters. The total number of voters for proposal 
    @param _proposalThreshold. The quorum threshold for the proposal
    */
    function _belowThreshold(uint256 _totalVoters, uint256 _proposalThreshold)
        internal
        view
        returns (bool belowThreshold)
    {
        uint256 numberAccountsInThreshold = ((vext.getTotalAccounts() *
            REBALANCING_FACTOR) / 1000) * uint256(_proposalThreshold);
        if (
            (_totalVoters * REBALANCING_FACTOR) / 100 <
            numberAccountsInThreshold
        ) return true;
    }

    /**
    @dev internal function to change the proposal's state
    @param _id. The proposal's id 
    @param _newState. The proposal's new state
     */
    function _changeProposalState(uint256 _id, ProposalState _newState)
        internal
    {
        ProposalData memory proposal = _proposals[_id];
        proposal.state = _newState;
        _proposals[_id] = proposal;
        emit NewProposalState(_id, _proposals[_id].state);
    }

    /**
    @dev this is an internal function that checks for any inconsistencies in the voting start and end date.
    @param _start. The proposed voting start time 
    @param _end. The proposed voting end time

    It checks that the start time and end time are in the future. 
    It checks that the start time is greater than the end time
     */
    function _votingPeriodError(uint256 _start, uint256 _end)
        internal
        virtual
        returns (bool)
    {
        uint256 current = block.timestamp;
        return (_start <= current || _end <= current || _end <= _start);
    }

    /**
    @dev this is an internal function which returns true if the proposal hash already exists 
    @param _proposalHash. The proposal hash for the proposed proposal
     */
    function _proposalHashExists(uint256 _proposalHash)
        internal
        virtual
        returns (bool)
    {
        return _proposalExists[_proposalHash];
    }

    /**
    @dev this is an internal function which reverts if the caller is not a valid proposer
    
    SuperAdmin are not authorised to make proposals. 

    It accounts for staked and unstaked balances. 

    Executive and Admin are able to make proposals regardless of eligible Proposers. 

     */
    function _onlyProposers() internal view {
        require(
            !access.userHasRole(access.superAdmin(), msg.sender),
            "Unauthorised"
        );

        if (proposers == Proposers.Veloce) {
            require(
                access.userHasRole(access.executive(), msg.sender) ||
                    access.userHasRole(access.admin(), msg.sender),
                "Unauthorised"
            );
        } else if (proposers == Proposers.HighVext) {
            require(
                (vext.balanceOf(msg.sender) +
                    staking.getUserBalanceAtBlockNumber(
                        msg.sender,
                        block.number
                    )) >=
                    highVextThreshold * 1e18 ||
                    access.userHasRole(access.executive(), msg.sender) ||
                    access.userHasRole(access.admin(), msg.sender),
                "Unauthorised"
            );
        } else {
            require(
                (vext.balanceOf(msg.sender) +
                    staking.getUserBalanceAtBlockNumber(
                        msg.sender,
                        block.number
                    )) >
                    1e18 ||
                    access.userHasRole(access.executive(), msg.sender) ||
                    access.userHasRole(access.admin(), msg.sender),
                "Unauthorised"
            );
        }
    }

    /* ========== READ FUNCTIONS ========== */

    /**
    @dev this function returns the proposal core data for the given proposal id
    @param _id. The proposal id
    */
    function getProposal(uint256 _id)
        external
        view
        virtual
        override
        returns (ProposalData memory)
    {
        ProposalData memory proposal = _proposals[_id];
        return proposal;
    }

    /**
    @dev this function returns an array of proposal data
    */
    function getProposals()
        external
        view
        virtual
        override
        returns (ProposalData[] memory)
    {
        ProposalData[] memory proposalsArray = new ProposalData[](id);
        ProposalData memory proposal;
        for (uint256 i = 0; i < proposalsArray.length; i++) {
            proposal = _proposals[i];
            proposalsArray[i] = proposal;
        }
        return proposalsArray;
    }

    /**
    @dev this function returns the proposal count by returning id. 
    */

    function getProposalCount()
        external
        view
        virtual
        override
        returns (uint32)
    {
        return id;
    }

    /**
    @dev this function returns the total number of voters by id.
    @param _id. the proposal id.
    */
    function getTotalVoters(uint256 _id)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _getTotalVoters(_id);
    }

    /** 
    @dev this function returns the vote data by id
    @param _id. the proposal id.
    */

    function getVoteData(uint256 _id)
        public
        view
        returns (VoteLib.VoteData memory)
    {
        return _getVoteData(_id);
    }

    /** 
    @dev this function returns all vote data 
    */

    function getAllVoteData() public view returns (VoteLib.VoteData[] memory) {
        return _getAllVoteData(id);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract IVEXT is ERC165 {
    function mint(address to, uint256 amount) external virtual;

    function burn(address from, uint256 amount) external virtual;

    function getTotalAccounts() external view virtual returns (uint256);

    function getPastVotes(address account, uint256 blockNumber)
        external
        view
        virtual
        returns (uint256);

    function getVotes(address account) external view virtual returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view virtual returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view virtual returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount)
        external
        virtual
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        virtual
        returns (uint256);

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
    function approve(address spender, uint256 amount)
        external
        virtual
        returns (bool);

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
    ) external virtual returns (bool);

    function pauseContract() external virtual;

    function unpauseContract() external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title Pause interface
/// @notice Pause is the emergency pause mechanism for Veloce's ecosystem
abstract contract ISystemPause is ERC165 {
    /* ========== REVERT STATEMENTS ========== */

    error SystemPaused();

    /* ========== FUNCTIONS ========== */

    event PauseStatus(bool status);

    function pause() external virtual;

    function unpause() external virtual;

    function isNotPaused() external virtual;

    function getSystemStatus() external virtual returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// import "../../node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title Access interface
/// @notice Access is the main contract which stores the roles
abstract contract IAccess is ERC165 {
    /* ========== REVERT STATEMENTS ========== */

    error AccessForbidden();

    /* ========== FUNCTIONS ========== */

    function solelyRole(bytes32 _role, address _address) external view virtual;

    function userHasRole(bytes32 _role, address _address)
        external
        view
        virtual
        returns (bool);

    function executive() external pure virtual returns (bytes32);

    function admin() external pure virtual returns (bytes32);

    function superAdmin() external pure virtual returns (bytes32);

    function deployer() external pure virtual returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/IVEXT.sol";
import "../../interfaces/ISystemPause.sol";
import "../../interfaces/IAccess.sol";
import "./Staking.sol";

/**
@title StakingFactory contract
@notice this contract is the staking factory contract for creating staking contracts.
@author MDRxTech
 */

contract StakingFactory {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    struct poolMetadata {
        address poolAddress;
        address rewardsPool;
        uint256 interestRateInBasisPoints;
        uint256 _startTime;
        uint256 timeForDeposits;
        uint256 minimumStakePerUser;
        uint256 maximumPoolSize;
        uint256 numberOfIntervals;
        uint256 maximumVestingDays;
        bool isActive;
    }

    IAccess access;
    ISystemPause system;
    uint256 public totalCount = 0; //count of all pools
    uint256 public retiredCount = 0; //count of all retired pools
    uint256 public maximumActivePools = 6; // users are not allowed to have more than the maximum number of Active pools

    mapping(uint256 => address) private idToPoolAddress;
    mapping(address => poolMetadata) private poolData;

    /* ========== EVENTS ========== */

    event NewPool(
        address stakingPoolAddress,
        uint256 _interestInBasisPoints,
        uint256 _startTime,
        uint256 _timeForDeposits,
        uint256 _minStaking,
        uint256 _maxPoolSize,
        uint8 _interval,
        uint256 _maxVestingDays
    );
    event RetiredPool(
        address stakingPoolAddress,
        address caller,
        uint256 timeOfRetirement
    );
    event FundedRewardPool(address admin, address token, uint256 amount);

    /* ========== CONSTRUCTOR ========== */

    constructor(address _accessAddress, address _systemPauseAddress) {
        access = IAccess(_accessAddress);
        system = ISystemPause(_systemPauseAddress);
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @dev Create a new staking pool
     * @param _vextTokenAddress: The address of the vext token
     * @param _pool: The address of the reward pool
     * @param _interestInBasisPoints: The interest rate per annum for the staking pool in basis points
     * @param _timeForDeposits: The number of days for which the users can stake before the vesting cliff begins
     * @param _minStaking: The minimum amount a single user must stake
     * @param _maxPoolSize: The maximum amount that can be staked in a single people
     * @param _interval: The number of intervals in the staking period
     * @param _maxVestingDays: The total number of days for which staking is allowed!
     * @notice This function allows the admin to create a new staking pool.
     */
    function createNewStakingPool(
        address _vextTokenAddress,
        address payable _pool,
        uint256 _interestInBasisPoints,
        uint256 _startTime,
        uint256 _timeForDeposits,
        uint256 _minStaking,
        uint256 _maxPoolSize,
        uint8 _interval,
        uint256 _maxVestingDays
    ) external {
        access.solelyRole(access.admin(), msg.sender);

        require(
            totalCount - retiredCount <= maximumActivePools,
            "Retire an old pool to create a new pool!"
        );
        Staking newObject = new Staking(
            address(access),
            address(system),
            address(this),
            _vextTokenAddress,
            _pool,
            _interestInBasisPoints,
            _startTime,
            _timeForDeposits,
            _minStaking,
            _maxPoolSize,
            _interval,
            _maxVestingDays
        );
        poolMetadata memory poolObject;
        address contractAddr = address(newObject);
        poolObject = poolMetadata(
            contractAddr,
            _pool,
            _interestInBasisPoints,
            _startTime,
            _timeForDeposits,
            _minStaking,
            _maxPoolSize,
            _interval,
            _maxVestingDays,
            true
        );

        idToPoolAddress[totalCount] = contractAddr;
        poolData[contractAddr] = poolObject;
        totalCount++;

        emit NewPool(
            address(newObject),
            _interestInBasisPoints,
            _startTime,
            _timeForDeposits,
            _minStaking,
            _maxPoolSize,
            _interval,
            _maxVestingDays
        );
    }

    /**
     * @dev Retire an expired pool.
     * @notice This function allows a user to retire a pool by receiving the index number.
     * @param _index: This is the index number for the created pool.
     */
    function retirePool(uint256 _index) external {
        access.solelyRole(access.admin(), msg.sender);

        address val = idToPoolAddress[_index];
        poolMetadata storage pool = poolData[val];
        pool.isActive = false;
        retiredCount++;

        Staking(val).retirePool();
        emit RetiredPool(idToPoolAddress[_index], msg.sender, block.timestamp);
    }

    /**
     * @dev Retire all expired pools.
     * @notice This function allows the admin to retire pools that have exceeded their endtime.
     * This function retires all such pools in a single transaction.
     * The function also updates the struct Metadata state for isActive to FALSE
     */
    function retireExpiredPools() external {
        access.solelyRole(access.admin(), msg.sender);

        (, uint256 expired) = poolCounter();

        poolMetadata[] memory expiredPools = new poolMetadata[](expired);
        (expiredPools, ) = this.viewPoolStatus();
        for (uint256 i; i < expiredPools.length; i++) {
            expiredPools[i].isActive = false;
            retiredCount++;
            poolData[expiredPools[i].poolAddress] = expiredPools[i];

            Staking(expiredPools[i].poolAddress).retirePool();
            emit RetiredPool(
                expiredPools[i].poolAddress,
                msg.sender,
                block.timestamp
            );
        }
    }

    /**
     * @dev fund the reward pool
     * @notice This function allows the admin to fund the reward pool with the reward tokens.
     * @param _tokenAddress: The address for the token that is being transferred to the reward pool.
     * @param _pool: The address for the pool that will dispense the rewards.
     * @param _amount: The amount that is being transferred from the caller's balance to the reward pool.
     *
     */
    function fundRewardPool(
        address _tokenAddress,
        address _pool,
        uint256 _amount
    ) external {
        access.solelyRole(access.admin(), msg.sender);

        IVEXT token = IVEXT(_tokenAddress);

        IERC20 stakingToken = IERC20(address(token));
        stakingToken.safeTransferFrom(msg.sender, _pool, _amount);
        emit FundedRewardPool(msg.sender, _pool, _amount);
    }

    /**
     * @dev Setter for maximum active pools.
     * @notice Only callable by the admins, this function sets the maximum amount of active pools that may co-exist
     */
    function setMaximumActivePools(uint256 amount) external {
        access.solelyRole(access.admin(), msg.sender);

        maximumActivePools = amount;
    }

    /* ========== READ FUNCTIONS ========== */

    /**
     * @dev View the count of the total active pools
     * @notice This function allows the user to view the total number of pools
     * @return totalCount This is the total number of pools
     */
    function viewPoolCount() external view returns (uint256) {
        return totalCount;
    }

    /**
     * @dev View the count of the total inaactive pools
     * @notice This function allows the user to view the total number retired pools
     * @return retiredCount This is the total number of pools
     */
    function viewRetiredPoolCount() external view returns (uint256) {
        return retiredCount;
    }

    /**
     * @dev View all pools.
     * @notice This function allows the user to view all the pool object.
     * @return pools This is an array of pool objects.
     */
    function viewAllPools() external view returns (poolMetadata[] memory) {
        poolMetadata[] memory pools = new poolMetadata[](totalCount);
        for (uint256 i = 0; i < pools.length; i++) {
            poolMetadata memory pool = poolData[idToPoolAddress[i]];
            pools[i] = pool;
        }
        return pools;
    }

    /**
     * @dev View all pools status.
     * @notice The function will return an array of pool objects.
     * The function will return 2 arrays, the first with a list of all expired pools, and the second with a list of all active pools.
     * The function returns a tuple of arrays
     * @return expiredPools This is an array of pools that have exceeded their endTime
     * @return activePools This is an array of pools that have yet to exceed their endTime
     */
    function viewPoolStatus()
        external
        view
        returns (poolMetadata[] memory, poolMetadata[] memory)
    {
        (uint256 active, uint256 expired) = poolCounter();
        poolMetadata[] memory expiredPools = new poolMetadata[](expired);
        poolMetadata[] memory activePools = new poolMetadata[](active);
        uint256 assigner1;
        uint256 assigner2;
        for (uint256 i = 0; i < totalCount; i++) {
            if (this.hasPoolExpired(idToPoolAddress[i])) {
                expiredPools[assigner1] = poolData[idToPoolAddress[i]];
                assigner1++;
            } else {
                activePools[assigner2] = poolData[idToPoolAddress[i]];
                assigner2++;
            }
        }
        return (expiredPools, activePools);
    }

    /**
     * @dev view the reward pool balance
     * @notice This function allows the admin to check the balance of tokens in a specific reward pool
     * @param _tokenAddress: This is the address for the token we seek to check
     * @param _pool: This is the address of the pool we seek to check
     * @return tokenBalance This is the token balance of the pool address in uint256
     */
    function viewRewardPoolTokenBalance(address _tokenAddress, address _pool)
        external
        view
        returns (uint256)
    {
        IVEXT token = IVEXT(_tokenAddress);
        return token.balanceOf(_pool);
    }

    /**
     * @dev Check if pool has exceeded limit
     * @notice This function allows a user to check whether a pool has exceeded it's deposit limit
     * @param poolAddress: This is the address of a pool that we seek to check.
     * @return hasPoolExceededLimit This is a boolean that shows whether or not a pool has exceeded limit.
     */
    function hasStakingPoolExceededLimit(address poolAddress)
        external
        view
        returns (bool)
    {
        return Staking(poolAddress).hasPoolExceededLimit();
    }

    /**
     * @dev Check if pool has expired
     * @notice This function checks whether a pool has expired or not.
     * @param poolAddress: This is the address of a pool that we seek to check.
     * @return hasPoolExceededLimit This is a boolean that shows whether or not a pool has exceeded it's staking endtime.
     */
    function hasPoolExpired(address poolAddress) external view returns (bool) {
        return Staking(poolAddress).hasPoolExpired();
    }

    /**
     * @dev Getter to view a pool using index
     * @notice This function allows a user to view a pool object by requesting the parameter.
     * @param _index: This is the index for the pool we seek to view.
     * @return poolMetadata This is the struct object for the pool.
     */
    function viewPool(uint256 _index)
        external
        view
        returns (poolMetadata memory)
    {
        address val = idToPoolAddress[_index];
        poolMetadata memory pool = poolData[val];
        return pool;
    }

    /**
     * @dev View a user's balance across all pools, returns an array.
     * @notice This function allows a user to view the balance of a user across all pools (active & inactive).
     * @param _user: This is the address we seek to check the balance of.
     * @return userAccumulatedBalance This is the accumulated balance for a user across all pools.
     */
    function viewUserBalanceAcrossAllPools(address _user)
        external
        view
        returns (uint256)
    {
        //iterate through each pool
        uint256 accumulatedBalance;
        uint256 length = totalCount;
        for (uint256 i = 0; i < length; i++) {
            uint256 userBalance = Staking(idToPoolAddress[i]).viewUserBalance(
                _user
            );
            accumulatedBalance += userBalance;
        }
        return accumulatedBalance;
    }

    /**
     * @dev View a user's balance across ACTIVE pools ONLY, returns an array.
     * @notice This function allows a user to view the balance of a user across all ACTIVE pools.
     * @param _user: This is the address we seek to check the balance of.
     * @return userAccumulatedBalance This is the accumulated balance for a user across all ACTIVE pools.
     */
    function viewUserBalanceAcrossActivePools(address _user)
        external
        view
        returns (uint256)
    {
        (uint256 active, ) = poolCounter();
        poolMetadata[] memory activePools = new poolMetadata[](active);
        (, activePools) = this.viewPoolStatus();
        uint256 accumulatedBalance;
        for (uint256 i = 0; i < active; i++) {
            uint256 userBalance = Staking(activePools[i].poolAddress)
                .viewUserBalance(_user);
            accumulatedBalance += userBalance;
        }
        return accumulatedBalance;
    }

    /**
     * @dev View a user's balance across EXPIRED pools ONLY, returns an array.
     * @notice This function allows a user to view the balance of a user across all EXPIRED pools.
     * @param _user: This is the address we seek to check the balance of.
     * @return userAccumulatedBalance This is the accumulated balance for a user across all EXPIRED pools.
     */
    function viewUserBalanceAcrossRetiredPools(address _user)
        external
        view
        returns (uint256)
    {
        (, uint256 expired) = poolCounter();
        poolMetadata[] memory expiredPools = new poolMetadata[](expired);
        (expiredPools, ) = this.viewPoolStatus();
        uint256 accumulatedBalance;
        for (uint256 i = 0; i < expired; i++) {
            uint256 userBalance = Staking(expiredPools[i].poolAddress)
                .viewUserBalance(_user);
            accumulatedBalance += userBalance;
        }
        return accumulatedBalance;
    }

    /**
     * @notice This function allows a user to view the balance of a user across all pools at a specific blocknumber
     * @param account: This is the account we seek to investigate
     * @param blockNumber: This is the block number where we a probing the user balance's at.
     * @return userAccumulatedBalance This is the accumulated balance for a user across all pools, at a specific blockNUmber.
     */
    function getUserBalanceAtBlockNumber(address account, uint256 blockNumber)
        external
        view
        returns (uint256)
    {
        uint256 accumulatedBalance;
        poolMetadata[] memory pools = new poolMetadata[](totalCount);
        pools = this.viewAllPools();
        for (uint256 i; i < pools.length; i++) {
            accumulatedBalance += Staking(pools[i].poolAddress)
                .getPastCheckpoint(account, blockNumber);
        }
        return accumulatedBalance;
    }

    // * ========== HELPER FUNCTIONS =========== *

    /**
     * @dev Get count of active and expired pools.
     * @notice This is the count of both active and expired pools
     * @return active The count of the active pools.
     * @return expired The count of the active pools.
     */
    function poolCounter()
        internal
        view
        returns (uint256 active, uint256 expired)
    {
        for (uint256 i = 0; i < totalCount; i++) {
            if (this.hasPoolExpired(idToPoolAddress[i])) {
                expired++;
            } else {
                active++;
            }
        }
    }

    function poolChecker(address _pool) public view returns (bool) {
        return poolData[_pool].maximumVestingDays > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/IVeloceGovernanceV1.sol";

/**
@title Proposal contract
@notice this contract is an abstract contract for VeloceGovernanceV1. 
*/

abstract contract Proposal is IVeloceGovernanceV1 {
    /**
    @dev internal function which stores and returns a new proposal
     */
    function _proposal(
        string memory _proposalRef,
        uint256 _start,
        uint256 _end,
        VoteModel _voteModel,
        string memory _category,
        bool _isExecutable,
        uint8 _threshold
    ) internal view returns (ProposalData memory) {
        ProposalData memory proposal = ProposalData(
            _proposalRef,
            _start,
            _end,
            block.number,
            ProposalState.Pending,
            _voteModel,
            _category,
            _isExecutable,
            _threshold,
            ""
        );

        return proposal;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../libraries/VoteLib.sol";

/**
@title Vote contract
@notice this contract is an abstract contract for VeloceGovernanceV1. 
*/

abstract contract Vote {
    using VoteLib for *;
    /* ========== STATE VARIABLES ========== */

    /// stores voteData for proposal Id
    mapping(uint256 => VoteLib.VoteData) voteData;
    /// stored when user has voted for proposal Id
    mapping(uint256 => mapping(address => bool)) hasVoted;

    /* ========== EVENTS ========== */

    event TotalVotesForAgainst(
        uint256 id,
        uint256 forVotes,
        uint256 againstVotes
    );
    event TotalVotesForAgainstAbstain(
        uint256 id,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 abstainVotes
    );
    event TotalVotesMultiChoice(
        uint256 id,
        uint256 aVotes,
        uint256 bVotes,
        uint256 cVotes,
        uint256 abstainVotes
    );
    event NewVote(uint256 id, address voter, VoteLib.Vote vote, uint256 weight);

    /** 
    @dev internal function which stores votes for ForAgainst proposals. 
    @param _id. The vote data id
    @param _vote. The vote to store 
    @param _weight. The vote's weight
    @param _voter. The voter's address
     */
    function _storeVoteForAgainst(
        uint256 _id,
        VoteLib.Vote _vote,
        uint256 _weight,
        address _voter
    ) internal {
        VoteLib.VoteData storage data = voteData[_id];
        data.countVoteForAgainst(_vote, _weight);

        hasVoted[_id][_voter] = true;

        emit TotalVotesForAgainst(_id, data.forVotes, data.againstVotes);
        emit NewVote(_id, _voter, _vote, _weight);
    }

    /**
    @dev internal function which stores votes for ForAgainstAbstain proposals. 
    @param _id. The vote data id
    @param _vote. The vote to store 
    @param _weight. The vote's weight
    @param _voter. The voter's address
     */
    function _storeVoteForAgainstAbstain(
        uint256 _id,
        VoteLib.Vote _vote,
        uint256 _weight,
        address _voter
    ) internal {
        VoteLib.VoteData storage data = voteData[_id];
        data.countVoteForAgainstAbstain(_vote, _weight);

        hasVoted[_id][_voter] = true;

        emit TotalVotesForAgainstAbstain(
            _id,
            data.forVotes,
            data.againstVotes,
            data.abstainVotes
        );
        emit NewVote(_id, _voter, _vote, _weight);
    }

    /**
    @dev internal function which stores votes for MultiChoice proposals. 
    @param _id. The vote data id
    @param _vote. The vote to store 
    @param _weight. The vote's weight
    @param _voter. The voter's address
     */
    function _storeVoteMultiChoice(
        uint256 _id,
        VoteLib.Vote _vote,
        uint256 _weight,
        address _voter
    ) internal {
        VoteLib.VoteData storage data = voteData[_id];
        data.countVoteMultiChoice(_vote, _weight);

        hasVoted[_id][_voter] = true;

        emit TotalVotesMultiChoice(
            _id,
            data.aVotes,
            data.bVotes,
            data.cVotes,
            data.abstainVotes
        );
        emit NewVote(_id, _voter, _vote, _weight);
    }

    /** 
    @dev internal function which returns outcome for for against proposals 
    @param _id. The vote data id.
    */

    function _outcomeForAgainst(uint256 _id)
        internal
        view
        returns (string memory outcome)
    {
        VoteLib.VoteData memory data = voteData[_id];

        return data.getOutcomeForAgainst();
    }

    /** 
    @dev internal function which returns outcome for for against abstain proposals 
    @param _id. The vote data id.
    */

    function _outcomeForAgainstAbstain(uint256 _id)
        internal
        view
        returns (string memory outcome)
    {
        VoteLib.VoteData memory data = voteData[_id];

        return data.getOutcomeForAgainstAbstain();
    }

    /** 
    @dev internal function which returns outcome for multichoice proposals 
    @param _id. The vote data id.
    */

    function _outcomeMultiChoice(uint256 _id)
        internal
        view
        returns (string memory outcome)
    {
        VoteLib.VoteData memory data = voteData[_id];
        return data.getOutcomeMultiChoice();
    }

    /**
    @dev internal function which returns true if a > b.
    @param a. The current time
    @param b. The end time for voting
     */

    function _outsideVotePeriod(uint256 a, uint256 b)
        internal
        pure
        returns (bool)
    {
        return (a > b);
    }

    /** 
    @dev external function which returns the total votes for the given proposal
    @param _id. The vote data id.
     */
    function _getTotalVoters(uint256 _id) internal view returns (uint256) {
        return voteData[_id].totalVoters;
    }

    /**
    @dev internal function that returns vote data 
    @param _id. Vote data id
    */

    function _getVoteData(uint256 _id)
        internal
        view
        returns (VoteLib.VoteData storage)
    {
        return voteData[_id];
    }

    /**
    @dev internal function that returns all vote data 
    @param _id. The latest proposal id.
    */
    function _getAllVoteData(uint256 _id)
        internal
        view
        returns (VoteLib.VoteData[] memory)
    {
        VoteLib.VoteData[] memory voteDataArray = new VoteLib.VoteData[](_id);
        VoteLib.VoteData memory voteDatum;
        uint256 numberItems = _id;
        for (uint256 i = 1; i <= numberItems; i++) {
            voteDatum = voteData[i];
            voteDataArray[i] = voteDatum;
        }
        return voteDataArray;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/IStaking.sol";
import "../../interfaces/IVEXT.sol";
import "../../interfaces/ISystemPause.sol";
import "../../interfaces/IAccess.sol";
import "./RewardPool.sol";

import "./StakingCheckpoint.sol";

/**
@title Staking contract
@notice This contract is the staking contract.
@author MDRxTech
 */

contract Staking is IStaking, StakingCheckpoint, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IVEXT token;
    RewardPool pool;
    ISystemPause system;
    IAccess access;

    uint256 public interestRateInBps;
    uint256 numberOfStakers;

    /// TIME VARIABLES
    /// Time at which pool begins and the pool can begin receiving deposits
    uint256 public immutable startTime;

    /// End of deposits and begining of first vesting cliff
    uint256 public immutable vestingStartTime;

    /// Start and end dates of each vesting cliffs
    uint256[] public vestingDates;

    /// The length of each vesting cliff -- in secs
    uint256 public vestingDuration;

    /// The end time of the final vesting cliff
    uint256 public immutable endTime;

    /// TOKEN STAKED VARIABLES
    /// Total amount of tokens staked
    uint256 totalAmountStaked;

    /// Minimum number of tokens that can be staked per user
    uint256 public immutable minimumStaking;

    /// Maximum staking per user that can be staked per user address
    uint256 public immutable maximumStakingPerUser;

    /// Maximum number of tokens that can be staked in the enitre pool
    uint256 public immutable maximumPoolSize;

    /// The full value of the APR of the maximum pool size
    uint256 maximumReward;

    /// REBALANCING VARIABLES
    /// The accuracy factor to assist with division
    uint256 constant rebalancingFactor = 10e18;

    /// The reward rate per second per dollar multiplied by the rebalancing factor
    uint256 public immutable unbalancedRewardRatePerSecondPerDollar;

    /// MAPPINGS
    /// Address to user balance in storage
    mapping(address => uint256) public s_userBalance;

    /// Address to user reward earned, stored in storage
    mapping(address => uint256) public s_rewards;

    /// Address to user reward paid, storesd in storage
    mapping(address => uint256) public s_rewardPaid;

    /// Holds the state of the pool, false when pool is ACTIVE, true when pool is closed.
    bool public isRetired;

    /// Holds the address of the factory contract that created the pool.
    address public immutable factoryAddress;

    /* ========== MODIFIERS ========== */

    /**
     * @dev The modifier does a check for whether the pool is retired or not.
     * An active pool has a FALSE state, a retired pool has a TRUE state
     */
    modifier isPoolRetired() {
        require(!isRetired, "Pool is retired!");
        _;
    }

    modifier onlyOwner() {
        access.solelyRole(access.admin(), msg.sender);
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _accessAddress, // the contract address for global access control
        address _systemPauseAddress, // the contract address for gloabl pause control
        address _factoryAddress, // the contract address for the factory that created the pool
        address _vextTokenAddress, //token address
        address payable _pool, //reward pool address
        uint256 _interestInBasisPoints, //Interest Rate in basis points
        uint256 _startTime, // the desired time at which the contract ought to begin to receive deposits
        uint256 _timeForDeposits, // the length of period for which stakers may stake/unstake before the races start
        uint256 _minStaking, // the minimum stake per user
        uint256 _maxPoolSize, // the maximum pool size
        uint8 _interval, // the number of intervals in the pool
        uint256 _maxVestingDays //the total number of days for all vesting cliffs
    ) ReentrancyGuard() {
        require(
            _interestInBasisPoints > 99,
            "Minimum interest rate is 100 bps"
        );

        startTime = _startTime;
        vestingStartTime = startTime + (1 days * _timeForDeposits);
        token = IVEXT(_vextTokenAddress);
        pool = RewardPool(_pool);
        access = IAccess(_accessAddress);
        system = ISystemPause(_systemPauseAddress);
        interestRateInBps = _interestInBasisPoints;
        minimumStaking = _minStaking;
        maximumStakingPerUser = _minStaking * 3; //3 multiples of the minimal staking amount
        unbalancedRewardRatePerSecondPerDollar = calculateRewardsPerSecondPerDollar(
            _maxVestingDays,
            _interestInBasisPoints
        );

        maximumPoolSize = _maxPoolSize;
        maximumReward = (_interestInBasisPoints * _maxPoolSize) / 10000;
        calculateVestingDates(_maxVestingDays, _interval);
        endTime = finalVestingPeriod();
        factoryAddress = _factoryAddress;
    }

    /* ========== FUNCTIONS ========== */

    /**
     *
     *
     * @notice This function allows a user to deposit VEXT tokens into the the staking pool
     * This function only works when the contract is not paused, and the pool is still active i.e isRetired is FALSE.
     * This function is open before the races start(before the vesting period), and will  not work (revert) once the race has begun.
     * @param amount: This specifies the amount the user seeks to deposit
     */
    function deposit(uint256 amount)
        external
        override
        nonReentrant
        whenNotPaused
        isPoolRetired
    {
        system.isNotPaused();
        if (block.timestamp < startTime) {
            revert Staking__WaitForDepositToBegin();
        }

        if (block.timestamp > vestingStartTime) {
            revert Staking__DepositPeriodHasPassed();
        }

        //check 0 amount not allowed
        if (amount == 0) {
            revert Staking__ZeroAmountNotAllowed();
        }
        //check user has enough balance
        if (token.balanceOf(msg.sender) < amount) {
            revert Staking__InsufficientTokens();
        }

        if (totalAmountStaked + amount > maximumPoolSize) {
            revert Staking__PoolLimitReached();
        }

        if (amount < minimumStaking) {
            revert Staking__BelowMinimumStake();
        }

        if (amount > maximumStakingPerUser) {
            revert Staking__AboveMaximumStakePerUser();
        }

        incrementCountStakers(msg.sender);
        s_userBalance[msg.sender] += amount;
        uint256 bal = s_userBalance[msg.sender];
        totalAmountStaked += amount;
        _addCheckpoint(msg.sender, bal, block.number);
        IERC20 stakingToken = IERC20(address(token));
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount, bal, totalAmountStaked);
    }

    /**
     * @notice This function allows a caller to claim rewards.
     * This function only works when the contract is not paused, and the pool is still active i.e isRetired is FALSE.
     * If the caller has no balance and no rewards to claim, the function reverts.
     * This function is only callable after the race is over.
     */
    function payClaimableReward()
        external
        override
        nonReentrant
        whenNotPaused
        isPoolRetired
    {
        system.isNotPaused();
        if (block.timestamp < endTime) {
            revert Staking__WaitTillRaceIsOver();
        }

        if (s_userBalance[msg.sender] == 0 && s_rewards[msg.sender] == 0) {
            revert Staking__NoClaimableRewards();
        } else if (
            s_userBalance[msg.sender] == 0 && s_rewards[msg.sender] > 0
        ) {
            uint256 rewardDue = s_rewards[msg.sender];
            s_rewards[msg.sender] = 0;
            bool success = pool.fundStaker(msg.sender, rewardDue);
            require(success, "Transaction Failed");
        } else {
            uint256 rewardDue = _viewClaimableRewards(msg.sender);
            rewardDue = rewardDue - s_rewardPaid[msg.sender];
            s_rewardPaid[msg.sender] += rewardDue;
            bool success = pool.fundStaker(msg.sender, rewardDue);
            require(success, "Transaction Failed");
        }
    }

    /**
     *
     * @notice This function allows a user withdraw all the funds previously staked.
     * This function only works when the contract is not paused, and the pool is still active i.e isRetired is FALSE.
     * A user may unstake at anytime. Once a user unstakes, the user stops earning rewards.
     */
    function unstake()
        external
        override
        nonReentrant
        whenNotPaused
        isPoolRetired
    {
        system.isNotPaused();

        require(s_userBalance[msg.sender] > 0, "You have zero balance");
        uint256 amount = s_userBalance[msg.sender];
        if (block.timestamp <= startTime) {
            s_userBalance[msg.sender] = 0;
            totalAmountStaked -= amount;
            _addCheckpoint(msg.sender, 0, block.number);
            decrementCountStakers(msg.sender);
            IERC20 stakingToken = IERC20(address(token));
            stakingToken.safeTransfer(msg.sender, amount);
        } else {
            uint256 rewards = viewClaimableRewards();
            s_rewards[msg.sender] = rewards - s_rewardPaid[msg.sender];
            s_userBalance[msg.sender] = 0;
            totalAmountStaked -= amount;
            _addCheckpoint(msg.sender, 0, block.number);
            decrementCountStakers(msg.sender);
            IERC20 stakingToken = IERC20(address(token));
            stakingToken.safeTransfer(msg.sender, amount);
        }
        emit Unstaked(
            msg.sender,
            amount,
            s_userBalance[msg.sender],
            totalAmountStaked
        );
    }

    /**
     * @notice This function allows a user to both unstake their tokens and claim their rewards.
     * @notice This function only works when the contract is not paused, and the pool is still active i.e isRetired is FALSE.
     * This function is only callable after the race is over.
     */
    function exitPosition() external override nonReentrant whenNotPaused {
        system.isNotPaused();

        if (block.timestamp < endTime) {
            revert Staking__WaitTillRaceIsOver();
        }
        require(
            s_userBalance[msg.sender] > 0,
            "Requires balance to be greater than zero"
        );
        this.unstake();
        this.payClaimableReward();
    }

    /**
     * @notice This function calculates the unix time that conincides with the start of each new vesting cliff
     * @notice This function is used to initialise the vestingDates array that holds all the vesting dates associated witht his pool.
     * @param vestingDays: This is the total number of days the vesting is supposed to hold for.
     * @param intervals: This is the number of intervals for which the user is supposed to earn rewards for.
     */
    function calculateVestingDates(uint256 vestingDays, uint8 intervals)
        private
    {
        uint256 const = (vestingDays * 24 * 60 * 60) / intervals;
        intervals = intervals + 1; //to get end internal
        vestingDates = new uint256[](intervals);
        for (uint8 i; i < intervals; i++) {
            vestingDates[i] = vestingStartTime + (i * const);
        }
        vestingDuration = const;
    }

    /**
     * @dev function to pause contract only callable by admin
     * This is a local pause that allows this specific pool to be paused.
     *
     */
    function pauseContract() external override onlyOwner {
        _pause();
    }

    /**
     * @dev function to unpause contract only callable by admin
     * This is a local unpause that allows this specific pool to be unpaused.
     */
    function unpauseContract() external override onlyOwner {
        _unpause();
    }

    /**
     * @dev function to retire staking pool, only callable by the factory
     * @notice This function allows the admin to retire the pool via the factory contract.
     */
    function retirePool() public override {
        require(msg.sender == factoryAddress, "Access Forbidden");

        isRetired = true;
    }

    /**
     * @param vestingDays: This is the total number of days the vesting is supposed to hold for.
     * @param interest: This is the interest earned per year, in basis points (APR in basis points).
     * @notice This function returns the amount paid out per second per vext token invested
     * This function is used to calculate the fixed amount paid out per second per dollar staked. This is a fixed amount.
     */
    function calculateRewardsPerSecondPerDollar(
        uint256 vestingDays,
        uint256 interest
    ) private pure returns (uint256 rewardRatePerSecondPerDollar) {
        uint256 vestingDaysInSeconds = vestingDays * 24 * 60 * 60;
        uint256 unbalancedInterestRate = interest * rebalancingFactor;
        rewardRatePerSecondPerDollar =
            unbalancedInterestRate /
            vestingDaysInSeconds;
    }

    /* ========== HELPERS ========== */

    /**
     * @dev The increment part of the counter feature for stakers
     * @notice This is a counter to increment the count for the number of stakers.
     */
    function incrementCountStakers(address beneficiary) private {
        if (s_userBalance[beneficiary] == 0) {
            numberOfStakers++;
        }
    }

    /**
     * @dev The decrement part of the counter feature for stakers
     * @notice This is a counter to decrement the count for the number of stakers.
     */
    function decrementCountStakers(address beneficiary) private {
        if (s_userBalance[beneficiary] == 0) {
            numberOfStakers--;
        }
    }

    /**
     * @dev This function is a helper function used to get the last vesting time
     * @notice This function allows the user get the final vesting period.
     */
    function finalVestingPeriod() private view returns (uint256) {
        uint256 val = vestingDates.length;
        return vestingDates[val - 1];
    }

    /**
     * @dev This function is a helper function that allows the caller to view all the vesting dates for the pool.
     * @return array: This function returns an array of vesting dates
     * @notice The first item in the array is start date of the vesting cliff
     */
    function printVestingDates()
        external
        view
        override
        returns (uint256[] memory)
    {
        return vestingDates;
    }

    /* ========== INTERNAL ========== */

    /**
     *
     * @dev This function allows a caller to view the rewards claimable by a user.
     * @param account: Pass in the account address you seek to view rewards for.
     * @notice This function returns the rewards that a user can claim.
     *
     */
    function _viewClaimableRewards(address account)
        internal
        view
        isPoolRetired
        returns (uint256 rewardsDue)
    {
        uint256 index = 0;
        for (uint256 i = 0; i < vestingDates.length; i++) {
            if (block.timestamp > vestingDates[i]) {
                index = i;
            }
        }

        rewardsDue =
            unbalancedRewardRatePerSecondPerDollar *
            vestingDuration *
            index;

        return ((rewardsDue * s_userBalance[account]) /
            (rebalancingFactor * 100));
    }

    /* ========== READ FUNCTIONS ========== */

    /**
     * @notice This function allows the admin to view the rewards that can be claimed by a user.
     */
    function viewClaimableRewardsAdmin(address account)
        public
        view
        override
        returns (uint256)
    {
        access.solelyRole(access.admin(), msg.sender);

        return _viewClaimableRewards(account);
    }

    /**
     * @notice This function allow the user to get the balance for a user at a particular blocknumber
     */
    function getPastCheckpoint(address account, uint256 blockNumber)
        external
        view
        override
        returns (uint256)
    {
        return _getPastCheckpoint(account, blockNumber);
    }

    /**
     * @dev function to check whether pool has expired
     * @notice This function allows a user to check whether this pool has exceeded its endtime.
     */
    function hasPoolExpired() public view override returns (bool) {
        return block.timestamp > endTime ? true : false;
    }

    /**
     * @dev function to check whether pool has exceeded its maximum limit
     * @notice This function allows a user to check whether this pool has exceeded its deposit limit.
     */
    function hasPoolExceededLimit() public view override returns (bool) {
        return totalAmountStaked < maximumPoolSize ? false : true;
    }

    /**
     * @dev This function is called to view the staked balance of a user
     * @param account: This function takes the address we seek to check the balance of
     * @notice This function allows the admin to view a user's balance
     */
    function viewUserBalance(address account)
        public
        view
        override
        returns (uint256)
    {
        return s_userBalance[account];
    }

    /**
     * @dev This function returns the total number of stakers in uint
     * @notice This function allows a user view the total number of unique addresses
     */
    function totalStakers() public view override returns (uint256) {
        return numberOfStakers;
    }

    /**
     * @dev This function returns the total number of tokens staked
     * @notice This function allows a user view the total amount of tokens staked in the contract.
     */
    function totalStaked() public view override returns (uint256) {
        return totalAmountStaked;
    }

    /**
     * @notice This function allows a user to view the rewards that can be claimed by the caller.
     */
    function viewClaimableRewards() public view override returns (uint256) {
        return _viewClaimableRewards(msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract IStaking is ERC165 {
    /* ========== EVENTS ========== */
    event Staked(
        address staker,
        uint256 amount,
        uint256 userBalance,
        uint256 totalBalance
    );
    event StakedFor(
        address benefactor,
        address beneficiary,
        uint256 amount,
        uint256 userBalance,
        uint256 totalBalance
    );
    event Unstaked(
        address staker,
        uint256 amount,
        uint256 userBalance,
        uint256 totalBalance
    );
    event ClaimedRewards(
        address staker,
        uint256 amount,
        uint256 userBalance,
        uint256 totalBalance
    );

    /* ========== REVERT STATEMENTS ========== */

    error Staking__InsufficientTokens();
    error Staking__ZeroAmountNotAllowed();
    error Staking__PoolLimitReached();
    error Staking__BelowMinimumStake();
    error Staking__AboveMaximumStakePerUser();
    error Staking__AboveMaximumStake();
    error Staking__DepositPeriodHasPassed();
    error Staking__NoClaimableRewardsLeftInThePreviousPeriod();
    error Staking__NoClaimableRewards();
    error Staking__CannotRolloverWithdrawInstead();
    error Staking__StillInWaitingPeriod();
    error Staking__WaitTillRaceIsOver();
    error Staking__WaitForDepositToBegin();
    error Staking__AccessForbidden();

    /* ========== FUNCTIONS ========== */

    function deposit(uint256 amount) external virtual;

    function viewUserBalance(address account)
        external
        view
        virtual
        returns (uint256);

    function viewClaimableRewards() external view virtual returns (uint256);

    function viewClaimableRewardsAdmin(address account)
        external
        view
        virtual
        returns (uint256);

    function payClaimableReward() external virtual;

    function unstake() external virtual;

    function exitPosition() external virtual;

    function totalStakers() external view virtual returns (uint256);

    function totalStaked() external view virtual returns (uint256);

    function printVestingDates()
        external
        view
        virtual
        returns (uint256[] memory);

    function pauseContract() external virtual;

    function unpauseContract() external virtual;

    function retirePool() external virtual;

    function getPastCheckpoint(address account, uint256 blockNumber)
        external
        view
        virtual
        returns (uint256);

    function hasPoolExpired() external view virtual returns (bool);

    function hasPoolExceededLimit() external view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../interfaces/IVEXT.sol";
import "../../interfaces/IAccess.sol";
import "./Staking.sol";
import "./StakingFactory.sol";

/**
@title RewardPool contract
@notice this contract is the reward pool contract for staking.
@author MDRxTech
 */

contract RewardPool is ReentrancyGuard {
    /* ========== STATE VARIABLES ========== */

    IAccess access;
    IVEXT vext; // the reward token
    StakingFactory factory;
    address public stakingAddresss; //the address for the staking contract

    /* ========== EVENTS ========== */

    event FallbackLog(string func, address sender, uint256 amount, bytes data);

    /* ========== MODIFIERS ========== */

    modifier IsStakingContract(address _pool) {
        bool isPool = validatePool(_pool);
        require(isPool, "Not a pool!");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _vext,
        address _accessAddress,
        address _factory
    ) ReentrancyGuard() {
        vext = IVEXT(_vext);
        access = IAccess(_accessAddress);
        factory = StakingFactory(_factory);
    }

    /* ========== FUNCTIONS ========== */

    // fallback() external payable {
    //     emit FallbackLog("fallback", msg.sender, msg.value, msg.data);
    // }

    /**
     * @dev This function can only be called by the staking contract
     * @notice This function allows the staking contract to fund a user's reward claim.
     * @param to: This is the address being funded
     * @param amount: This is the amount to be paid out
     * @return bool: This function returns a boolean based on whether or not the transfer was succesful.
     *
     */
    function fundStaker(address to, uint256 amount)
        public
        nonReentrant
        IsStakingContract(msg.sender)
        returns (bool)
    {
        bool success = vext.transfer(to, amount); //Please refer to the first test case in claimRewards.test.ts, it demonstrates that the rewardpool is debited for this function call.
        return success;
    }

    /**
     * @dev This function allows the reward pool to validate that the caller for fund staker is one of the pools created by the factory
     * @param _pool The function takes in the address of a staking pool.
     * @return The function returns a boolean.
     */

    function validatePool(address _pool) public view returns (bool) {
        return factory.poolChecker(_pool);
    }

    /**
     * @dev This function allows the Admin to withdraw any left over tokens not used
     * @param amount This specifies the amount to be withdrawn
     * @param recepient This specifies the destination address to receive the tokens
     * @return bool: This function returns a boolean based on whether or not the transfer was succesful.
     */
    function withdraw(uint256 amount, address recepient)
        external
        returns (bool)
    {
        access.solelyRole(access.executive(), msg.sender);

        bool success = vext.transfer(recepient, amount);
        return success;
    }

    /* ========== READ FUNCTIONS ========== */

    /**
     * @notice This function calls the balance left in the pool.
     * @return uint This function returns the balance of the ERC20 tokens in the contract in uint.
     */
    function poolBalance() public view returns (uint256) {
        return vext.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (governance/utils/Votes.sol)
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Checkpoints.sol";

abstract contract StakingCheckpoint {
    using Checkpoints for Checkpoints.History;

    /* ========== STATE VARIABLES ========== */

    mapping(address => Checkpoints.History) private _stakeCheckpoints;

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @dev Create a staking snapshot.
     */
    function _addCheckpoint(
        address account,
        uint256 amount,
        uint256 blockNumber
    ) internal {
        uint32 _blockNumber = SafeCast.toUint32(blockNumber);
        uint224 _amount = SafeCast.toUint224(amount);
        _stakeCheckpoints[account]._checkpoints.push(
            Checkpoints.Checkpoint(_blockNumber, _amount)
        );
    }

    /**
     * @dev Returns the amount of VEXT that `account` had at the end of a past block (`blockNumber`).
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function _getPastCheckpoint(address account, uint256 blockNumber)
        internal
        view
        virtual
        returns (uint256)
    {
        return _stakeCheckpoints[account].getAtProbablyRecentBlock(blockNumber);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Checkpoints.sol)
// This file was procedurally generated from scripts/generate/templates/Checkpoints.js.

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SafeCast.sol";

/**
 * @dev This library defines the `History` struct, for checkpointing values as they change at different points in
 * time, and later looking up past values by block number. See {Votes} as an example.
 *
 * To create a history of checkpoints define a variable type `Checkpoints.History` in your contract, and store a new
 * checkpoint for the current transaction block using the {push} function.
 *
 * _Available since v4.5._
 */
library Checkpoints {
    struct History {
        Checkpoint[] _checkpoints;
    }

    struct Checkpoint {
        uint32 _blockNumber;
        uint224 _value;
    }

    /**
     * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
     * before it is returned, or zero otherwise.
     */
    function getAtBlock(History storage self, uint256 blockNumber) internal view returns (uint256) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");
        uint32 key = SafeCast.toUint32(blockNumber);

        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
     * before it is returned, or zero otherwise. Similar to {upperLookup} but optimized for the case when the searched
     * checkpoint is probably "recent", defined as being among the last sqrt(N) checkpoints where N is the number of
     * checkpoints.
     */
    function getAtProbablyRecentBlock(History storage self, uint256 blockNumber) internal view returns (uint256) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");
        uint32 key = SafeCast.toUint32(blockNumber);

        uint256 len = self._checkpoints.length;

        uint256 low = 0;
        uint256 high = len;

        if (len > 5) {
            uint256 mid = len - Math.sqrt(len);
            if (key < _unsafeAccess(self._checkpoints, mid)._blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        uint256 pos = _upperBinaryLookup(self._checkpoints, key, low, high);

        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Pushes a value onto a History so that it is stored as the checkpoint for the current block.
     *
     * Returns previous value and new value.
     */
    function push(History storage self, uint256 value) internal returns (uint256, uint256) {
        return _insert(self._checkpoints, SafeCast.toUint32(block.number), SafeCast.toUint224(value));
    }

    /**
     * @dev Pushes a value onto a History, by updating the latest value using binary operation `op`. The new value will
     * be set to `op(latest, delta)`.
     *
     * Returns previous value and new value.
     */
    function push(
        History storage self,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) internal returns (uint256, uint256) {
        return push(self, op(latest(self), delta));
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(History storage self) internal view returns (uint224) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(History storage self)
        internal
        view
        returns (
            bool exists,
            uint32 _blockNumber,
            uint224 _value
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._blockNumber, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(History storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(
        Checkpoint[] storage self,
        uint32 key,
        uint224 value
    ) private returns (uint224, uint224) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint memory last = _unsafeAccess(self, pos - 1);

            // Checkpoints keys must be increasing.
            require(last._blockNumber <= key, "Checkpoint: invalid key");

            // Update or push new checkpoint
            if (last._blockNumber == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint({_blockNumber: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint({_blockNumber: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._blockNumber > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._blockNumber < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    function _unsafeAccess(Checkpoint[] storage self, uint256 pos) private pure returns (Checkpoint storage result) {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }

    struct Trace224 {
        Checkpoint224[] _checkpoints;
    }

    struct Checkpoint224 {
        uint32 _key;
        uint224 _value;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into a Trace224 so that it is stored as the checkpoint.
     *
     * Returns previous value and new value.
     */
    function push(
        Trace224 storage self,
        uint32 key,
        uint224 value
    ) internal returns (uint224, uint224) {
        return _insert(self._checkpoints, key, value);
    }

    /**
     * @dev Returns the value in the oldest checkpoint with key greater or equal than the search key, or zero if there is none.
     */
    function lowerLookup(Trace224 storage self, uint32 key) internal view returns (uint224) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _lowerBinaryLookup(self._checkpoints, key, 0, len);
        return pos == len ? 0 : _unsafeAccess(self._checkpoints, pos)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint with key lower or equal than the search key.
     */
    function upperLookup(Trace224 storage self, uint32 key) internal view returns (uint224) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(Trace224 storage self) internal view returns (uint224) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(Trace224 storage self)
        internal
        view
        returns (
            bool exists,
            uint32 _key,
            uint224 _value
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint224 memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._key, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(Trace224 storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(
        Checkpoint224[] storage self,
        uint32 key,
        uint224 value
    ) private returns (uint224, uint224) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint224 memory last = _unsafeAccess(self, pos - 1);

            // Checkpoints keys must be increasing.
            require(last._key <= key, "Checkpoint: invalid key");

            // Update or push new checkpoint
            if (last._key == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint224({_key: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint224({_key: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint224[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint224[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    function _unsafeAccess(Checkpoint224[] storage self, uint256 pos)
        private
        pure
        returns (Checkpoint224 storage result)
    {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }

    struct Trace160 {
        Checkpoint160[] _checkpoints;
    }

    struct Checkpoint160 {
        uint96 _key;
        uint160 _value;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into a Trace160 so that it is stored as the checkpoint.
     *
     * Returns previous value and new value.
     */
    function push(
        Trace160 storage self,
        uint96 key,
        uint160 value
    ) internal returns (uint160, uint160) {
        return _insert(self._checkpoints, key, value);
    }

    /**
     * @dev Returns the value in the oldest checkpoint with key greater or equal than the search key, or zero if there is none.
     */
    function lowerLookup(Trace160 storage self, uint96 key) internal view returns (uint160) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _lowerBinaryLookup(self._checkpoints, key, 0, len);
        return pos == len ? 0 : _unsafeAccess(self._checkpoints, pos)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint with key lower or equal than the search key.
     */
    function upperLookup(Trace160 storage self, uint96 key) internal view returns (uint160) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(Trace160 storage self) internal view returns (uint160) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(Trace160 storage self)
        internal
        view
        returns (
            bool exists,
            uint96 _key,
            uint160 _value
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint160 memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._key, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(Trace160 storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(
        Checkpoint160[] storage self,
        uint96 key,
        uint160 value
    ) private returns (uint160, uint160) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint160 memory last = _unsafeAccess(self, pos - 1);

            // Checkpoints keys must be increasing.
            require(last._key <= key, "Checkpoint: invalid key");

            // Update or push new checkpoint
            if (last._key == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint160({_key: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint160({_key: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint160[] storage self,
        uint96 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint160[] storage self,
        uint96 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    function _unsafeAccess(Checkpoint160[] storage self, uint256 pos)
        private
        pure
        returns (Checkpoint160 storage result)
    {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

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
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
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
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
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
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
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
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
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
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
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
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
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
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
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
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract IVeloceGovernanceV1 is ERC165 {
    /* ========== VARIABLE DEFINITIONS ========== */

    struct ProposalData {
        string proposalRef;
        uint256 start;
        uint256 end;
        uint256 created;
        ProposalState state;
        VoteModel voteModel;
        string category;
        bool isExecutable;
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
        Veloce,
        HighVext,
        Community
    }

    enum VoteModel {
        ForAgainst,
        ForAgainstAbstain,
        MultiChoice
    }

    /* ========== EVENTS ========== */

    event NewProposal(uint256 id, ProposalData proposal);
    event NewQuorumThreshold(uint96 newThreshold);
    event NewQuorumMinimumAccounts(uint256 newThreshold);
    event NewProposerThreshold(uint256 newThreshold);
    event NewProposers(Proposers proposers);
    event ProposalCancelled(uint256 id);
    event NewProposalState(uint256 id, ProposalState proposalState);
    event ProposalOutcome(
        uint256 id,
        string outcome,
        ProposalState proposalState
    );

    /* ========== REVERT STATEMENTS ========== */

    error ProposalExists(uint256 id);
    error AddressError();
    error VotingPeriodError(uint256 start, uint256 end);
    error InvalidProposalState(uint256 id, ProposalState state);
    error ThresholdTooLow();
    error ThresholdTooHigh();
    error VoteCasted(uint256 _id, address _voter);
    error QuorumOutOfBounds();
    error OutsideVotePeriod();
    error VoteNotEnded();
    error Unauthorised();

    /* ========== FUNCTIONS ========== */

    function proposeNonExecutable(
        string memory _description,
        uint256 _start,
        uint256 _end,
        VoteModel _voteModel,
        string memory _category,
        uint8 _threshold
    ) external virtual;

    function setFlatMinimum(uint256 _newThreshold) external virtual;

    function setHighVextThreshold(uint256 _newThreshold) external virtual;

    function setQuorumThreshold(uint8 _newThreshold) external virtual;

    function setProposers(Proposers _proposers) external virtual;

    function cancelProposal(uint256 _id) external virtual;

    function completeProposal(uint256 _id) external virtual;

    function getProposal(uint256 _id)
        external
        view
        virtual
        returns (ProposalData memory);

    function getProposals()
        external
        view
        virtual
        returns (ProposalData[] memory);

    function getProposalCount() external view virtual returns (uint32);

    function getProposalOutcome(uint256 _id) external virtual;

    function getTotalVoters(uint256 _id)
        external
        view
        virtual
        returns (uint256);

    function pauseContract() external virtual;

    function unpauseContract() external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
@title VoteLib library
@notice this is a library for counting votes and return the proposal outcome
@author MDRxTech
 */

library VoteLib {
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

    error InvalidVote(Vote _vote);

    /** @dev this functions counts votes for ForAgainst Proposals. 
        It stores the vote weight. Reverts if the vote is not valid for the proposal. 
        It stores that the users has now voted. 
        It increments the total number of voters. 
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

    function getOutcomeForAgainst(VoteData memory data)
        internal
        pure
        returns (string memory outcome)
    {
        (data.forVotes > data.againstVotes)
            ? outcome = "Succeeded"
            : outcome = "Defeated";
        if (data.forVotes == data.againstVotes) outcome = "Draw";

        return outcome;
    }

    /** @dev this function returns the outcome for for against abstain proposals */

    function getOutcomeForAgainstAbstain(VoteData memory data)
        internal
        pure
        returns (string memory outcome)
    {
        uint256 winningVote;
        uint256 drawingVote;

        uint256[3] memory votes;

        votes[0] = data.forVotes;
        votes[1] = data.againstVotes;
        votes[2] = data.abstainVotes;

        for (uint256 i = 0; i < votes.length; i++) {
            if (votes[i] > winningVote) {
                winningVote = votes[i];
            } else if (votes[i] == winningVote) {
                drawingVote = votes[i];
            }
        }

        if (
            winningVote != 0 &&
            winningVote == data.forVotes &&
            winningVote != drawingVote
        ) {
            outcome = "Succeeded";
        } else if (winningVote == drawingVote) {
            outcome = "Draw";
        } else outcome = "Defeated";

        return outcome;
    }

    /** @dev this function returns the outcome for multichoice proposals */

    function getOutcomeMultiChoice(VoteData memory data)
        internal
        pure
        returns (string memory outcome)
    {
        uint256 winningVote;
        uint256 drawingVote;

        uint256[4] memory votes;

        votes[0] = data.aVotes;
        votes[1] = data.bVotes;
        votes[2] = data.cVotes;
        votes[3] = data.abstainVotes;

        for (uint256 i = 0; i < votes.length; i++) {
            if (votes[i] > winningVote) {
                winningVote = votes[i];
            } else if (votes[i] == winningVote) {
                drawingVote = votes[i];
            }
        }

        if (
            winningVote != 0 &&
            winningVote != drawingVote &&
            winningVote != data.abstainVotes
        ) {
            outcome = "Succeeded";
        } else if (winningVote == drawingVote) {
            outcome = "Draw";
        } else outcome = "Defeated";

        return outcome;
    }
}