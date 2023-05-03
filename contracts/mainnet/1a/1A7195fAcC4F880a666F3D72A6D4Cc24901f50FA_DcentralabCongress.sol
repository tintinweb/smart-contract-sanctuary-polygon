/**
 *Submitted for verification at polygonscan.com on 2023-05-03
*/

// File contracts/governance/ICongressMembersRegistry.sol

pragma solidity 0.6.12;

/**
 * ICongressMembersRegistry contract.
 * @author Nikola Madjarevic
 * Date created: 13.9.21.
 * Github: madjarevicn
 */

interface ICongressMembersRegistry {
    function isMember(address _address) external view returns (bool);
    function getMinimalQuorum() external view returns (uint256);
}


// File contracts/governance/DcentralabCongress.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
 * DcentralabarmCongress contract.
 * @author Nikola Madjarevic
 * Date created: 13.9.21.
 * Github: madjarevicn
 */

contract DcentralabCongress {
    // The name of this contract
    string public constant name = "DcentralabCongress";

    // Members registry contract
    ICongressMembersRegistry membersRegistry;

    // The total number of proposals
    uint public proposalCount;

    struct Proposal {
        // Unique id for looking up a proposal
        uint id;

        // Creator of the proposal
        address proposer;

        // The ordered list of target addresses for calls to be made
        address[] targets;

        // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint[] values;

        // The ordered list of function signatures to be called
        string[] signatures;

        // The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        // Current number of votes in favor of this proposal
        uint forVotes;

        // Current number of votes in opposition to this proposal
        uint againstVotes;

        // Flag marking whether the proposal has been canceled
        bool canceled;

        // Flag marking whether the proposal has been executed
        bool executed;

        // Timestamp when proposal is created
        uint timestamp;

        // Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;
    }

    // Ballot receipt record for a voter
    struct Receipt {
        // Whether or not a vote has been cast
        bool hasVoted;

        // Whether or not the voter supports the proposal
        bool support;
    }

    // The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;

    // An event emitted when a new proposal is created
    event ProposalCreated(uint id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, string description);

    // An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint proposalId, bool support);

    // An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    // An event emitted when a proposal has been executed
    event ProposalExecuted(uint id);

    // An event emitted everytime ether is received
    event ReceivedEther(address sender, uint amount);

    // Event which will fire every time transaction is executed
    event ExecuteTransaction(address indexed target, uint value, string signature,  bytes data);

    // Modifiers
    modifier onlyMember {
        require(
            membersRegistry.isMember(msg.sender) == true,
            "Only DcentralabCongress member can call this function"
        );
        _;
    }

    /**
     * @notice function to set members registry address
     *
     * @param _membersRegistry - address of members registry
     */
    function setMembersRegistry(
        address _membersRegistry
    )
    external
    {
        require(
            address(membersRegistry) == address(0x0),
            "DcentralabCongress:setMembersRegistry: membersRegistry is already set"
        );
        membersRegistry = ICongressMembersRegistry(_membersRegistry);
    }

    /**
     * @notice function to propose
     *
     * @param targets - array of address
     * @param values - array of values
     * @param signatures - array of signatures
     * @param calldatas - array of data
     * @param description - array of descriptions
     *
     * @return id of proposal
     */
    function propose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    )
    external
    onlyMember
    returns (uint)
    {
        require(
            targets.length == values.length &&
            targets.length == signatures.length &&
            targets.length == calldatas.length,
            "DcentralabCongress::propose: proposal function information arity mismatch"
        );

        require(targets.length != 0, "DcentralabCongress::propose: must provide actions");

        proposalCount++;

        Proposal memory newProposal = Proposal({
        id: proposalCount,
        proposer: msg.sender,
        targets: targets,
        values: values,
        signatures: signatures,
        calldatas: calldatas,
        forVotes: 0,
        againstVotes: 0,
        canceled: false,
        executed: false,
        timestamp: block.timestamp
        });

        proposals[newProposal.id] = newProposal;

        emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, description);
        return newProposal.id;
    }

    /**
     * @notice function to cast vote
     *
     * @param proposalId - id proposal
     * @param support - agree or don't agree on proposal
     */
    function castVote(
        uint proposalId,
        bool support
    )
    external
    onlyMember
    {
        return _castVote(msg.sender, proposalId, support);
    }

    function _castVote(
        address voter,
        uint proposalId,
        bool support
    )
    internal
    {
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(!receipt.hasVoted, "DcentralabCongress::_castVote: voter already voted");

        if (support) {
            proposal.forVotes = add256(proposal.forVotes, 1);
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, 1);
        }

        receipt.hasVoted = true;
        receipt.support = support;

        emit VoteCast(voter, proposalId, support);
    }

    /**
     * @notice function to execute on what is voted
     *
     * @param proposalId - id of proposal
     */
    function execute(
        uint proposalId
    )
    external
    onlyMember
    payable
    {
        // load the proposal
        Proposal storage proposal = proposals[proposalId];
        // Require that proposal is not previously executed neither cancelled
        require(!proposal.executed && !proposal.canceled, "Proposal was canceled or executed");
        // Mark that proposal is executed
        proposal.executed = true;
        // Require that votes in favor of proposal are greater or equal to minimalQuorum
        require(proposal.forVotes >= membersRegistry.getMinimalQuorum(), "Not enough votes in favor");

        for (uint i = 0; i < proposal.targets.length; i++) {
            bytes memory callData;

            if (bytes(proposal.signatures[i]).length == 0) {
                callData = proposal.calldatas[i];
            } else {
                callData = abi.encodePacked(
                    bytes4(keccak256(bytes(proposal.signatures[i]))),
                    proposal.calldatas[i]
                );
            }

            // solium-disable-next-line security/no-call-value
            (bool success,) = proposal.targets[i].call{value:proposal.values[i]}(callData);

            // Require that transaction went through
            require(
                success,
                "DcentralabCongress::executeTransaction: Transaction execution reverted."
            );

            // Emit event that transaction is being executed
            emit ExecuteTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i]
            );
        }

        // Emit event that proposal executed
        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice function to cancel proposal
     *
     * @param proposalId - id of proposal
     */
    function cancel(
        uint proposalId
    )
    external
    onlyMember
    {
        Proposal storage proposal = proposals[proposalId];
        // Require that proposal is not previously executed neither cancelled
        require(!proposal.executed && !proposal.canceled, "DcentralabCongress:cancel: Proposal already executed or canceled");
        // 3 days after proposal can get cancelled
        require(block.timestamp >= proposal.timestamp + 259200, "DcentralabCongress:cancel: Time lock hasn't ended yet");
        // Proposal with reached minimalQuorum cant be cancelled
        require(proposal.forVotes < membersRegistry.getMinimalQuorum(), "DcentralabCongress:cancel: Proposal already reached quorum");
        // Set that proposal is cancelled
        proposal.canceled = true;
        // Emit event
        emit ProposalCanceled(proposalId);
    }

    /**
     * @notice function to see what was voted on
     *
     * @param proposalId - id proposal
     *
     * @return targets
     * @return values
     * @return signatures
     * @return calldatas
     */
    function getActions(
        uint proposalId
    )
    external
    view
    returns (
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    )
    {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /**
     * @notice function to see address of members registry
     *
     * @return address of members registry
     */
    function getMembersRegistry()
    external
    view
    returns (address)
    {
        return address(membersRegistry);
    }

    /**
     * @notice function to check addition
     *
     * @param a - number1
     * @param b - number2
     *
     * @return result of addition
     */
    function add256(
        uint256 a,
        uint256 b
    )
    internal
    pure
    returns (uint)
    {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    receive()
    external
    payable
    {
        emit ReceivedEther(msg.sender, msg.value);
    }
}