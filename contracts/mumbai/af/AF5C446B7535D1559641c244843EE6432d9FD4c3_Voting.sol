/**
 *Submitted for verification at polygonscan.com on 2023-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Voting {
    // Data Structure for Candidate
    struct Candidate {
        string name;// Name of candidate
        string rollno;// Roll no. of candidate(unique)
        uint256 totalVotes;//Total votes
        string position; // VP, UGR
        string hostel; // hostel name for hostel sec. etc.
        string gender;// Gender :)
        string courseYr; // BT20 for BTECH'20, MT20 for MTECH'20 etc.
    }

    //Data Structure for Position
    struct PositionStood4 {
        string posName;// Position name.. VP, UGR
        string[] allowedCYs;//array of allowed voters CourseYr (BT20, MT20)
        string[] allowedHostels;//array of allowed voters from hostels(for hostel sec and similar posts)
        string[] allowedGenders;//array of allowed voters of same gender(for tech sec M/F and similar posts)
    }

    address owner;
    modifier onlyOwner { // modifier for checking only that function is called by only owner
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    bool private canVote; // check for whether voting can be done or not

    constructor() {
        owner = msg.sender;
        canVote = false;
    }

    Candidate[] private candidates; // main array which will store all the Candidates
    PositionStood4[] private positions; // main array which will store all the positions
    mapping(string => uint256) private roll2index; //mapping to store index of the Candidadtes array corresponding to Rollno
    mapping(string => uint256) private pos2index;//mapping to store index of the position array corresponding to position

    mapping(string => address) private voters;//mapping of roll no. with registered wallet address
    mapping(address => string) private addr2roll;//mapping of address to rollno
    mapping(address => bool) private votedStatus;//mapping of address with voted Status of the voter

    function addVoters(string[] memory _rollno, address[] memory _address) public onlyOwner {
        //function to add Voters to the voters mapping
        require(_rollno.length == _address.length, "Invalid input length");

        for (uint256 i = 0; i < _rollno.length; i++) {
            string memory currRollno = _rollno[i];
            if (voters[currRollno] == address(0)) {
                voters[currRollno] = _address[i];
                addr2roll[_address[i]] = currRollno;
                votedStatus[_address[i]] = false;
            }
        }
    }

    function addCandidate(string memory _name, string memory _rollno, string memory _position, string memory _hostel, string memory _gender, string memory _cy) public onlyOwner {
        //function to add single Candidate to the main candidate array
        candidates.push(Candidate({
            name: _name,
            rollno: _rollno,
            totalVotes: 0,
            position: _position,
            hostel: _hostel,
            gender: _gender,
            courseYr: _cy
        }));

        roll2index[_rollno] = candidates.length - 1;
    }

    function addCandidates(string[] memory _name, string[] memory _rollno, string[] memory _position, string[] memory _hostel, string[] memory _gender, string[] memory _cy) public onlyOwner{
        //function to add multiple candidates to the main candidate array
        for(uint256 i = 0; i < _name.length; i++)
        {
            addCandidate(_name[i], _rollno[i], _position[i], _hostel[i], _gender[i], _cy[i]);
        }
    }

    function addPosition(string memory _posName, string[] memory _allowedCy, string[] memory _allowedHostels, string[] memory _allowedGenders) public onlyOwner {
        // function to add position to main positions array
        positions.push(PositionStood4({
            posName: _posName,
            allowedCYs: _allowedCy,
            allowedHostels: _allowedHostels,
            allowedGenders: _allowedGenders
        }));

        pos2index[_posName] = positions.length - 1;
    }

    function contains(string[] memory arr, string memory value) internal pure returns (bool) {
        //function to check whether a particular value is in the array or not?
        for (uint256 i = 0; i < arr.length; i++) {
            if (keccak256(bytes(arr[i])) == keccak256(bytes(value))) {
                return true;
            }
        }
        return false;
    }

    function vote(string memory _senders_rollno, string memory _voting4pos, string memory _sndrsCy, string memory _sndrsHostel, string memory _gender, string memory _repRoll) public {
        // function to vote
        require(canVote, "Voting is not currently allowed");
        require(voters[_senders_rollno] == msg.sender, "Message not sent by registered wallet address");
        require(!votedStatus[msg.sender], "Already voted by this wallet address");

        uint256 posIndex = pos2index[_voting4pos];
        require(contains(positions[posIndex].allowedCYs, _sndrsCy), "Sender not allowed to vote for this position");
        require(contains(positions[posIndex].allowedHostels, _sndrsHostel), "Sender is not allowed to vote for this position");
        require(contains(positions[posIndex].allowedGenders, _gender), "Sender is not allowed to vote for this position");

        uint256 index = roll2index[_repRoll];
        candidates[index].totalVotes++;
        votedStatus[msg.sender] = true;
    }

    function getRollfromAddress() public view returns (string memory) 
    {
        string memory roll = addr2roll[msg.sender];
        if (bytes(roll).length == 0) {
            return "INVALID";
        }
        return roll;
    }


    function changeVoteAccess() public onlyOwner {
        // function to change vote access
        canVote = !canVote;
    }

    function deleteCandidates() public onlyOwner {
        delete candidates;
    }

    function deletePositions() public onlyOwner {
        delete positions;
    }

    function deleteVoters() public onlyOwner {
        for (uint256 i = 0; i < candidates.length; i++) {
            delete voters[candidates[i].rollno];
        }
    }

    function deleteVotedStatus() public onlyOwner {
        for (uint256 i = 0; i < candidates.length; i++) {
            delete votedStatus[voters[candidates[i].rollno]];
        }
    }

    function showVotes() public view onlyOwner returns (Candidate[] memory) {
        //function to show all the Votes of the candidates
        return candidates;
    }
}