// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 'DisputeResolution' contract will provide a mechanism for dispute resolution 
// between users, evaluating claims and making decisions based on available data.
contract DisputeResolution {
    // 'DisputeStatus' stores the possible status of the dispute
    enum DisputeStatus {
        Created,
        Resolved,
        Rejected
    }

    // 'Dispute' contains the details for the dispute
    struct Dispute {
        uint id;
        uint jobId;
        address complainant;
        address respondent;
        string reason;
        DisputeStatus status;
        uint256 timestamp;
    }

    // 'disputeCounter' provides a counter for automatically generating an ID
    uint private disputeCounter;
    // 'disputes' mapping of dispute ID to the 'Dispute' struct
    mapping(uint => Dispute) private disputes;

    // events for dispute creation, resolution, and rejection
    event DisputeCreated(
        uint indexed disputeId,
        uint indexed jobId,
        address indexed complainant,
        address respondent,
        string reason,
        uint256 timestamp
    );
    event DisputeResolved(uint indexed disputeId);
    event DisputeRejected(uint indexed disputeId);

    // @dev 'createDispute' instantiate a new 'Dispute' struct and map that particular
    //      dispute to the 'disputeCounter' then adds it to the 'dispute' mapping
    // @params '_jobId' the ID of the job posting; for reference
    //         '_respondent' the address of the employer or candidate
    //         '_reason' the reason for the complaint
    function createDispute(
        uint _jobId,
        address _respondent,
        string memory _reason
    ) public {
        disputeCounter++; 

        Dispute memory newDispute = Dispute(
            disputeCounter,
            _jobId,
            msg.sender,
            _respondent,
            _reason,
            DisputeStatus.Created,
            block.timestamp
        );
        disputes[disputeCounter] = newDispute;

        emit DisputeCreated(
            disputeCounter,
            _jobId,
            msg.sender,
            _respondent,
            _reason,
            block.timestamp
        );
    }

    // @dev 'resolveDispute' resolves the dispute by based on the passed ID argument.
    //      If dispute is already resolved or rejected, the transaction will be
    //      reverted
    // @params '_disputeId' ID of the dispute for proper referencing on the 'disputes'
    //         mapping
    function resolveDispute(uint _disputeId) public {
        Dispute storage dispute = disputes[_disputeId];

        // check if dispute status is 'Created'. if not, revert the transaction
        require(
            dispute.status == DisputeStatus.Created,
            "Dispute already resolved or rejected"
        );

        // change the dispute status to 'Resolved'
        dispute.status = DisputeStatus.Resolved;

        emit DisputeResolved(_disputeId);
    }

    // @dev 'rejectDispute' rejects the dispute based on the '_disputeId' passed
    //      as an argument to the function
    // @params '_disputeId' ID of the dispute for proper referencing on the 'disputes'
    //         mapping
    function rejectDispute(uint _disputeId) public {
        Dispute storage dispute = disputes[_disputeId];

        // check if dispute status is 'Created'. if not, revert the transaction
        require(
            dispute.status == DisputeStatus.Created,
            "Dispute already resolved or rejected"
        );

        // change the dispute status to 'Rejected'
        dispute.status = DisputeStatus.Rejected;

        emit DisputeRejected(_disputeId);
    }

    // 'getDispute' returns the 'Dispute' struct for the particular '_disputeId'
    // passed as an argument
    function getDispute(uint _disputeId) public view returns (Dispute memory) {
        return disputes[_disputeId];
    }
}