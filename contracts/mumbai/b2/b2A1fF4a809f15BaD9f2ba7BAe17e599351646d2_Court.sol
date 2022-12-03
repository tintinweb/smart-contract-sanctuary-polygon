pragma solidity ^0.8.5;

interface IERC20 {
	function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Court {

	uint256 public constant DISPUTE_EXPIRY = 7 days;

	address marketAddress;
	address marketOwner;

	mapping(address => bool) juries;
	mapping(uint256 => address) juriesByIndex;
	mapping(address => uint256) indexByJury;

	struct Votes {
		uint256 countVotesFor;
		uint256 countVotesAgainst;
		uint256[] juryVotes; // 0 - for, 1 - against
	}

	enum DisputePeriod {
		EvidenceSubmission,
		Voting,
		Execution,
		Settled
	}

	struct Dispute {
		uint256 id;
		uint256 raisedAt;
		uint256 amount;
		address raisedBy;
		address raisedAgainst;
		Votes votes;
		DisputePeriod period;
		string[] dealerEvidenceURIs;
		string[] opponentEvidenceURIs;
	}

	uint256 disputesCount;

	mapping(uint256 => mapping(uint256 => Dispute)) dealDisputes;

	event DisputeRaised(
		uint256 dealId,
		address raisedBy,
		address raisedAgainst
	);

	event EvidenceSubmitted(
		uint256 dealId,
		uint256 dipsuteId,
		string[] evidenceURIs
	);

	event VoteCasted(
		address jury,
		uint256 vote,
		uint256 dealId,
		uint256 dipsuteId
	);

	event DisputeSettled(uint256 dealId, uint256 dipsuteId);

	constructor(address _marketAddress, address _marketOwner, address[] memory _juries) {
		marketAddress = _marketAddress;
		marketOwner = _marketOwner;
		for(uint256 i=0; i<_juries.length; i++) {
			juries[_juries[i]] = true;
			juriesByIndex[i] = _juries[i];
			indexByJury[_juries[i]] = i;
		}
	}

	function createDispute(uint256 dealId, address raisedBy, address raisedAgainst, uint256 amount) external {
		require(msg.sender == marketAddress, "Can only be invoked by market contract");
		Dispute memory dispute;
		dispute.id = disputesCount;
		dispute.raisedBy = raisedBy;
		dispute.raisedAgainst = raisedAgainst;
		dispute.raisedAt = block.timestamp;
		dispute.amount = amount;

		dealDisputes[dealId][disputesCount] = dispute;
		disputesCount++;

		emit DisputeRaised(
			dealId,
			raisedBy,
			raisedAgainst
		);
	}

	function submitEvidences(uint256 dealId, uint256 dipsuteId, string[] memory evidenceURIs) external {
		Dispute storage dispute = dealDisputes[dealId][dipsuteId];
		require(dispute.period == DisputePeriod.EvidenceSubmission, "Evidence submission period is over");

		if (msg.sender == dispute.raisedBy) {
			require(dispute.dealerEvidenceURIs.length + evidenceURIs.length <= 10, "Evidence limit reached");
			for(uint256 i=0; i<evidenceURIs.length; i++) {
				dispute.dealerEvidenceURIs.push(evidenceURIs[i]);
			}
		} else if (msg.sender == dispute.raisedAgainst) {
			require(dispute.opponentEvidenceURIs.length + evidenceURIs.length <= 10, "Evidence limit reached");
			for(uint256 i=0; i<evidenceURIs.length; i++) {
				dispute.opponentEvidenceURIs.push(evidenceURIs[i]);
			}
		} else {
			revert("Not authorised to submit evidence");
		}

		if (dispute.dealerEvidenceURIs.length > 0 && dispute.opponentEvidenceURIs.length > 0) {
			// move to voting
			dispute.period = DisputePeriod.Voting;
		}

		emit EvidenceSubmitted(dealId, dipsuteId, evidenceURIs);
	}

	function _completeVotingPeriod(Dispute memory _dispute) private returns (Dispute memory) {
		if (_dispute.raisedAt + 7 days <= block.timestamp) {
			_dispute.period = DisputePeriod.Execution;
		}

		return _dispute;
	}

	function castVote(uint256 vote, uint256 dealId, uint256 dipsuteId) external {
		require(juries[msg.sender], "Not authorised to vote");
		// add check for only the specific juror is allowed to vote who is picked randomly

		Dispute storage dispute = dealDisputes[dealId][dipsuteId];
		require(dispute.period == DisputePeriod.Voting, "Cannot vote, period over");

		if (dispute.raisedAt + DISPUTE_EXPIRY <= block.timestamp) {
			dispute.period = DisputePeriod.Execution;
			return;
		}

		if (vote == 0) {
			dispute.votes.countVotesFor += 1;
		} else if (vote == 1) {
			dispute.votes.countVotesAgainst += 1;
		} else {
			revert("Invalid vote option");
		}

		dispute.votes.juryVotes[indexByJury[msg.sender]] = vote;

		emit VoteCasted(msg.sender, vote, dealId, dipsuteId);
	}



	function requestSettlement(uint256 dealId, uint256 dipsuteId) external {
		Dispute storage dispute = dealDisputes[dealId][dipsuteId];
		require(dispute.period == DisputePeriod.Execution, "Dispute in non-execution period");

		IERC20 market = IERC20(marketAddress);
		if (dispute.votes.countVotesFor >= dispute.votes.countVotesAgainst) {
			market.transfer(dispute.raisedBy, dispute.amount);
		} else {
			market.transfer(dispute.raisedAgainst, dispute.amount);
		}

		dispute.period = DisputePeriod.Settled;

		emit DisputeSettled(dealId, dipsuteId);
	}
}