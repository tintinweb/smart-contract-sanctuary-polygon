// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract ProjectRoomDAOContract {
    struct ProjectRoom {
        address creator;
        string name;
        string description;
        string link;
        uint256 dateCreated;
        bool isCompleted;
        Participant[] participants;
        Comment[] comments;
        Proposal[] proposals;
        Task[] tasks;
        uint256 id;
    }

    struct Participant {
        address participant;
        string name;
        uint256 dateJoined;
    }

    struct Comment {
        address commenter;
        string name;
        string commentText;
        uint256 dateCommented;
    }

    struct Proposal {
        address proposer;
        string name;
        string description;
        uint256 dateSubmitted;
        uint256 yesVoted;
        uint256 noVoted;
        uint256 abstained;
    }

    struct Task {
        address assignedTo;
        string name;
        string description;
        uint256 dateCreated;
        string status;
        bool isCompletedRequested;
        bool isAbandonedRequested;
        uint256 yesVoted;
        uint256 noVoted;
        bool autoTrigger;
        uint256 autoTriggerTimestamp;
    }

    mapping(uint256 => ProjectRoom) public rooms;

    uint256 public numberOfRooms = 0;

    function createRoom(
        uint256 _id,
        string memory _name,
        string memory _description,
        string memory _link
    ) public returns (uint256) {
        require(bytes(_name).length > 0, "Room name cannot be empty");
        require(
            bytes(_description).length > 0,
            "Room description cannot be empty"
        );

        ProjectRoom storage newRoom = rooms[_id];

        newRoom.creator = msg.sender;
        newRoom.name = _name;
        newRoom.description = _description;
        newRoom.link = _link;
        newRoom.dateCreated = block.timestamp;
        newRoom.isCompleted = false;
        newRoom.id = _id;

        numberOfRooms++;

        return _id;
    }

    function getProjectRoom(
        uint256 _roomId
    ) public view returns (ProjectRoom memory) {
        return rooms[_roomId];
    }

    function completeProjectRoom(uint256 _roomId) public {
        require(
            rooms[_roomId].creator == msg.sender,
            "Only creator can complete the room"
        );

        rooms[_roomId].isCompleted = true;
    }

    function addParticipant(
        uint256 _roomId,
        string memory _name,
        address _address
    ) public {
        require(bytes(_name).length > 0, "Participant name cannot be empty");

        Participant memory newParticipant;
        newParticipant.participant = _address;
        newParticipant.name = _name;
        newParticipant.dateJoined = block.timestamp;

        rooms[_roomId].participants.push(newParticipant);
    }

    function leaveOrKickParticipant(
        uint256 _roomId,
        address _participant
    ) public {
        for (uint256 i = 0; i < rooms[_roomId].participants.length; i++) {
            if (rooms[_roomId].participants[i].participant == _participant) {
                delete rooms[_roomId].participants[i];
                break;
            }
        }
    }

    function getProjectRoomParticipants(
        uint256 _roomId
    ) public view returns (Participant[] memory) {
        return rooms[_roomId].participants;
    }

    function addComment(
        uint256 _roomId,
        string memory _name,
        string memory _commentText,
        address _commenter
    ) public {
        require(bytes(_name).length > 0, "Comment name cannot be empty");
        require(bytes(_commentText).length > 0, "Comment text cannot be empty");

        Comment memory newComment;
        newComment.commenter = _commenter;
        newComment.name = _name;
        newComment.commentText = _commentText;
        newComment.dateCommented = block.timestamp;

        rooms[_roomId].comments.push(newComment);
    }

    function getProjectRoomComments(
        uint256 _roomId
    ) public view returns (Comment[] memory) {
        return rooms[_roomId].comments;
    }

    function addProposal(
        uint256 _roomId,
        string memory _name,
        string memory _description,
        address _proposer
    ) public {
        require(bytes(_name).length > 0, "Proposal name cannot be empty");
        require(
            bytes(_description).length > 0,
            "Proposal description cannot be empty"
        );

        Proposal memory newProposal;
        newProposal.proposer = _proposer;
        newProposal.name = _name;
        newProposal.description = _description;
        newProposal.dateSubmitted = block.timestamp;
        newProposal.yesVoted = 0;
        newProposal.noVoted = 0;
        newProposal.abstained = 0;

        rooms[_roomId].proposals.push(newProposal);
    }

    function getProjectRoomProposals(
        uint256 _roomId
    ) public view returns (Proposal[] memory) {
        return rooms[_roomId].proposals;
    }

    function voteOnProposal(
        uint256 _roomId,
        uint256 _proposalId,
        uint256 _vote
    ) public {
        require(
            _proposalId < rooms[_roomId].proposals.length,
            "Proposal does not exist"
        );
        require(_vote >= 0 && _vote <= 2, "Vote must be between 0 and 2");

        if (_vote == 0) {
            rooms[_roomId].proposals[_proposalId].yesVoted++;
        } else if (_vote == 1) {
            rooms[_roomId].proposals[_proposalId].noVoted++;
        } else {
            rooms[_roomId].proposals[_proposalId].abstained++;
        }
    }

    // Automation
    function performActionOnProposalAfterVoting(
        uint256 _roomId,
        uint256 _proposalId
    ) external {
        require(
            _proposalId < rooms[_roomId].proposals.length,
            "Proposal does not exist"
        );

        if (
            rooms[_roomId].proposals[_proposalId].yesVoted >
            rooms[_roomId].proposals[_proposalId].noVoted
        ) {
            // create task and add to room
            Task memory newTask;
            newTask.name = rooms[_roomId].proposals[_proposalId].name;
            newTask.description = rooms[_roomId]
                .proposals[_proposalId]
                .description;
            newTask.dateCreated = block.timestamp;
            newTask.status = "todo";
            newTask.isCompletedRequested = false;
            newTask.isAbandonedRequested = false;
            newTask.yesVoted = 0;
            newTask.noVoted = 0;
            newTask.autoTrigger = false;
            newTask.autoTriggerTimestamp = 0;

            rooms[_roomId].tasks.push(newTask);

            delete rooms[_roomId].proposals[_proposalId];
        } else {
            // delete proposal
            delete rooms[_roomId].proposals[_proposalId];
        }
    }

    function getProjectRoomTasks(
        uint256 _roomId
    ) public view returns (Task[] memory) {
        return rooms[_roomId].tasks;
    }

    function assignTaskToParticipant(uint256 _roomId, uint256 _taskId) public {
        require(_taskId < rooms[_roomId].tasks.length, "Task does not exist");

        rooms[_roomId].tasks[_taskId].assignedTo = msg.sender;
        rooms[_roomId].tasks[_taskId].status = "in_progress";
    }

    function changeTaskStatus(
        uint256 _roomId,
        uint256 _taskId,
        uint256 _status
    ) public {
        require(_taskId < rooms[_roomId].tasks.length, "Task does not exist");
        require(
            _status >= 0 && _status <= 1,
            "Status must be between 0 (Completed) and 1 (Abandoned)"
        );

        if (_status == 0) {
            rooms[_roomId].tasks[_taskId].isCompletedRequested = true;
            rooms[_roomId].tasks[_taskId].autoTrigger = true;
            rooms[_roomId].tasks[_taskId].autoTriggerTimestamp =
                block.timestamp +
                1 days;
        } else {
            rooms[_roomId].tasks[_taskId].isAbandonedRequested = true;
            rooms[_roomId].tasks[_taskId].autoTrigger = true;
            rooms[_roomId].tasks[_taskId].autoTriggerTimestamp =
                block.timestamp +
                1 days;
        }
    }

    function voteOnTask(
        uint256 _roomId,
        uint256 _taskId,
        uint256 _vote
    ) public {
        require(_taskId < rooms[_roomId].tasks.length, "Task does not exist");
        require(_vote >= 0 && _vote <= 1, "Vote must be between 0 and 1");

        if (_vote == 0) {
            rooms[_roomId].tasks[_taskId].yesVoted++;
        } else {
            rooms[_roomId].tasks[_taskId].noVoted++;
        }
    }

    // Automation
    function performActionOnTaskAfterVoting(
        uint256 _roomId,
        uint256 _taskId
    ) external {
        require(_taskId < rooms[_roomId].tasks.length, "Task does not exist");

        if (
            rooms[_roomId].tasks[_taskId].autoTriggerTimestamp <=
            block.timestamp &&
            rooms[_roomId].tasks[_taskId].autoTrigger &&
            keccak256(abi.encodePacked(rooms[_roomId].tasks[_taskId].status)) ==
            "in_progress"
        ) {
            if (
                rooms[_roomId].tasks[_taskId].yesVoted >
                rooms[_roomId].tasks[_taskId].noVoted
            ) {
                if (rooms[_roomId].tasks[_taskId].isCompletedRequested) {
                    rooms[_roomId].tasks[_taskId].status = "completed";
                } else {
                    rooms[_roomId].tasks[_taskId].status = "abandoned";
                }
            } else {
                if (rooms[_roomId].tasks[_taskId].isCompletedRequested) {
                    rooms[_roomId].tasks[_taskId].isCompletedRequested = false;
                } else {
                    rooms[_roomId].tasks[_taskId].isAbandonedRequested = false;
                }
            }
        }

        rooms[_roomId].tasks[_taskId].isCompletedRequested = false;
        rooms[_roomId].tasks[_taskId].isAbandonedRequested = false;
        rooms[_roomId].tasks[_taskId].yesVoted = 0;
        rooms[_roomId].tasks[_taskId].noVoted = 0;
        rooms[_roomId].tasks[_taskId].autoTrigger = false;
        rooms[_roomId].tasks[_taskId].autoTriggerTimestamp = 0;
    }
}