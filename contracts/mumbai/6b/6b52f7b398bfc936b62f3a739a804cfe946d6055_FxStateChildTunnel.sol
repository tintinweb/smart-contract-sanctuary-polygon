/**
 *Submitted for verification at polygonscan.com on 2022-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;
///////////////////////////////////////////////////////////////////////////////////////////////////
    struct Voter {
        uint weight; //  delegation weight
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal(后期修改为string型，利于投票)
    }

    struct Proposal {
        
        string name;   // short name (最长32 bytes的名字)
        uint voteCount; // number of accumulated votes(Count)
    }

    address public chairperson;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;
//////////////////////////////////////////////////////////////////////////////////////////////////////
    constructor(address _fxChild, string[] memory proposalNames) {
        fxChild = _fxChild;

        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for (uint i = 0; i < proposalNames.length; i++) {
            // 'Proposal creates a temporary
            
            proposals.push(Proposal({
                
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }
///////////////////////////////////////////////////////////////////////////////////////////////////////

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}


pragma solidity ^0.8.0;

/**
 * @title FxStateChildTunnel
 */
contract FxStateChildTunnel is FxBaseChildTunnel {
    uint256 public latestStateId;
    address public latestRootMessageSender;
    bytes public latestData;
    string public latestData_string;
///////////////////////////////////////////////////////////////////////////////////////////
    constructor(address _fxChild, string[] memory proposalNames) FxBaseChildTunnel(_fxChild, proposalNames) {}

    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        latestStateId = stateId;
        latestRootMessageSender = sender;
        latestData = data;
        latestData_string = string(latestData);
    }

    function sendMessageToRoot(bytes memory message) public {
        _sendMessageToRoot(message);
    }

///////////////////////////////////////////////////////////////////////////////////////////////    
    function giveRightToVote(address voter) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."//合约创建者规定参与投票的人
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    function giveRightToMultipleVote(address[] memory voters) public {
        for(uint i = 0; i < voters.length; i++) {
            giveRightToVote(voters[i]);
        }
    }

    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }


    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

      
        proposals[proposal].voteCount += sender.weight;
    }

  
    function winningProposal() public view
            returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

   
    function winnerName() public view
            returns (string memory winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }

    function ChangeProposalName(uint index, string memory NewproposalName) public {
        proposals[index].name = NewproposalName;
    }

    function ChangeProposalBatch(string[] memory NewproposalName) public {
        for (uint i = 0; i < NewproposalName.length; i++){
            proposals[i].name = NewproposalName[i];
        }
    }

    function ProposalsSync() public {
        proposals[0].name = "A";
        proposals[1].name = "B";
        proposals[2].name = "C";
    }

    function Send_winnerName_toRoot() public {
        sendMessageToRoot(bytes(proposals[winningProposal()].name));
    }

}