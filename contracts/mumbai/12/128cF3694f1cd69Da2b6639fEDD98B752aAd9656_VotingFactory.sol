// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract VotingFactory {
    address payable[] public deployedVotings;
    address public creator;
    uint public minVotingFee = 0.02 ether;

    constructor() {
        creator = msg.sender;
    }

    function createVoting(uint choices, uint fromDate, uint endDate) public payable {
        require(msg.value > minVotingFee);

        address newVoting = address(new Voting(choices, fromDate, endDate, msg.sender));
        (bool sent, ) = newVoting.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        deployedVotings.push(payable(newVoting));
    }

    function getDeployedVotings() public view returns (address payable[] memory) {
        return deployedVotings;
    }

}

contract Voting {
    address public manager;
    string public winner;
    address payable public luckyVoter;

    uint public totalChoices;
    uint public fromDate;
    uint public endDate;
    uint public reward = 0.01 ether;

    bool public completed;

    mapping(address => bool) public votedVoters;
    uint public totalVotersVoted;

    mapping(address => bool) public allowedVoters;
    uint public totalAllowedVoters;

    choicesData[] public choicesDatas;

    struct choicesData {
        string description;
        uint receivedVotes;
        address payable[] voters;
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    constructor(uint totalChoicesInput, uint fromDateInput, uint endDateInput, address creator) payable {
        manager = creator;
        totalChoices = totalChoicesInput;
        fromDate = fromDateInput;
        endDate = endDateInput;

        for (uint i = 1; i <= totalChoices; i++) {
            choicesData storage choicesdata = choicesDatas.push();
            choicesdata.description = string(abi.encodePacked("Pilihan ", _uint2str(i)));
            choicesdata.receivedVotes = 0;
            choicesdata.voters = new address payable[](0);
        }
    }

    function addAllowerdVoters(address newAllowerdVoters) public restricted {
        require(newAllowerdVoters != manager, "Manager Cannot Be Voters");
        require(!allowedVoters[newAllowerdVoters], "This Address is Already a Voter ");

        allowedVoters[newAllowerdVoters] = true;
        totalAllowedVoters++;
    } 

    receive() external payable {}

    function pickChoice(uint index) public {
        require(msg.sender != manager, "Manager Can Not Vote");
        require(allowedVoters[msg.sender], "You Cannot Take Part in This Vote");
        require(!votedVoters[msg.sender], "You Can Only Vote Once");
        require(!completed, "Voting Has Ended");
        require(block.timestamp > fromDate && block.timestamp < endDate, "You Chose at The Wrong Time");

        choicesData storage choicesdata = choicesDatas[index];
        choicesdata.receivedVotes++;
        choicesdata.voters.push(payable(msg.sender));
        votedVoters[msg.sender] = true;
        totalVotersVoted++;
    }

    function completedVoteThenTransfer() public restricted() {
        // require(block.timestamp > endDate, "Voting Time Is Not Over"); /*uncomment this if you need validation endDate to pick Random Voter*/
        require(!completed, "Voting Has Ended");

        if (_getWinnerIndices().length > 1) {
            endDate = endDate + 1 days;
        } else {
            choicesData storage winnerChoice = choicesDatas[_getWinnerIndices()[0]];
            winner = winnerChoice.description;
            uint random = uint(keccak256(abi.encodePacked(block.timestamp, winnerChoice.voters)));
            uint indexRandomVoter = random % winnerChoice.voters.length;

            luckyVoter = payable(winnerChoice.voters[indexRandomVoter]);
            (bool sent, ) = luckyVoter.call{value: reward}("");
            require(sent, "Failed to send Ether");

            payable(msg.sender).transfer(address(this).balance);

            completed = true;   
        }
    }

    // function _getWinnerIndex() internal view restricted returns (uint) {
    //     uint maxVotes = 0;
    //     uint winnerIndex;

    //     for (uint i = 0; i < choicesDatas.length; i++) {
    //         if (choicesDatas[i].receivedVotes > maxVotes) {
    //             maxVotes = choicesDatas[i].receivedVotes;
    //             winnerIndex = i;
    //         }
    //     }
    //     return winnerIndex; /*return 1 winner*/
    // }

    function _getWinnerIndices() internal view restricted returns (uint[] memory) {
        uint maxVotes = 0;
        uint[] memory winnerIndices;
        uint count = 0;

        for (uint i = 0; i < choicesDatas.length; i++) {
            if (choicesDatas[i].receivedVotes > maxVotes) {
                maxVotes = choicesDatas[i].receivedVotes;
                count = 1;
                winnerIndices = new uint[](count);
                winnerIndices[0] = i;
            } else if (choicesDatas[i].receivedVotes == maxVotes) {
                count++;
                uint[] memory newWinnerIndices = new uint[](count);
                for (uint j = 0; j < count - 1; j++) {
                    newWinnerIndices[j] = winnerIndices[j];
                }
                newWinnerIndices[count - 1] = i;
                winnerIndices = newWinnerIndices;
            }
        }

        return winnerIndices; /*return 1 or more winner*/
    }


    function getStructDetail(uint index) public view returns(string memory, uint, address payable[] memory) {
        choicesData storage choicedata = choicesDatas[index];
        return (
            choicedata.description,
            choicedata.receivedVotes,
            choicedata.voters
        );
    }

    function getVotingCount() public view returns (uint) {
        return choicesDatas.length;
    }

    function getContractDetail() public view returns(address, uint, uint, uint, bool, address, uint, uint) {
        return (
            manager,
            totalChoices,
            fromDate,
            endDate,
            completed,
            luckyVoter,
            totalVotersVoted,
            reward
        );
    }

    function _uint2str(uint _i) internal pure returns (string memory str) { /* change uint to string */
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length;
        while (_i != 0) {
            k = k-1;
            uint8 temp = uint8(48 + _i % 10);
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        str = string(bstr);
    }
}