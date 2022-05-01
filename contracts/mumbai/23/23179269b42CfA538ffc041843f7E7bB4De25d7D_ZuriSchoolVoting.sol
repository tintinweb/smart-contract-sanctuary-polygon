// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Events.sol";
import "./VotingAccess.sol";

/** 
 * @title Zuri School Voting
 * @dev Implements voting process along with vote delegation
 */
contract ZuriSchoolVoting is VotingEvents, VotingAccess {
    
    //@dev this is a proposal on the contract, a proposal is simply an option in an election
    struct Proposal {
        string name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    //@dev this defines a ballot struct which is used to store a single election instance
    struct Election {
        uint256 _id;
        uint256 num_choices;
        string name;
        string description;
        bool active;
        bool computed;
        uint256 startedAt;
        uint256 stopedAt;
    }

    // @dev this is used to keep track of the count of elections
    uint256 public electionCount = 0;

    // @dev store the name of the school
    string public schoolName;

    // @dev keep track of all the registered voters on the contract
    address[] voterAddresses;

    // @dev a mapping that keeps track of an election id to the election struct
    mapping(uint256 => Election) public elections;

    // @dev this is a mapping of mappings used to keep track of if a voter has voted in an election already
    mapping(uint256 => mapping(address=>bool)) hasVoted;

    // @dev this is used to keep track of the weight of the votes of a specific user type
    mapping(Stakeholder => uint256) weights;

    // @dev this is used to keep track of the timers for the various elections
    mapping(uint256 => uint256) timers;

    // @dev this is used to keep track of the winnig proposal for each election
    mapping(uint256 => Proposal) winners;
    
    // @dev this is a mapping to track the choices for various elections
    mapping(uint256 => Proposal[]) choices;

    
    /**
     * @notice setup voting smart contract defaults
     * @dev setup chairperson, stakeholders vote weights & school name
     * @param _schoolName name of school that owns the contract
     */
    constructor(string memory _schoolName, address _chairperson) {
        schoolName = _schoolName;
        chairperson = _chairperson;

        _initializeStakeholdersVoteWeight(1);

        // create director voter for chairperson
        Voter memory _voter = Voter("chairperson", true, Stakeholder.DIRECTOR);
        _addVoter(msg.sender, _voter);

        emit DirectorCreated("chairperson", msg.sender);
    }


    //to change the  chairman
    function changeChairmanship(address _addr)external isChairperson returns(bool){
        chairperson = _addr;
        return true;
    }

    /**
     * @notice check if address belongs to chairperson
     * @dev check if address matches stored chairperson address
     * @param _chairperson address to verify if belongs to chairperson
     * @return bool
     */
    function iamChairperson(address _chairperson) external view returns(bool){
        if(chairperson == _chairperson) { return true; }

        return false;
    }

    /**
     * @notice add a student voter to the system
     * @dev add a student voter to the system
     * @param _name name of the student
     * @param _student student wallet address
     */
    function addStudent(string memory _name, address _student) external isChairperson {
        require(bytes(_name).length > 0, "student name is not valid");
        require(bytes(voters[_student].name).length == 0, "student already exist");

        Voter memory _voter = Voter(_name, true, Stakeholder.STUDENT);
        _addVoter(_student, _voter);

        emit StudentCreated(_name, _student);
    }

    /**
        * @notice add students to the system
        * @dev add students to the system from a list of addresses and names
    */
    function addStudents(address[] memory _students, string[] memory _names) external isChairperson {
        require(_names.length > 0, "0 names");
        require(_students.length > 0, "0 addresses");
        require(_students.length == _names.length, "names != addresses");

        for(uint256 i = 0; i < _students.length; i++) {
            require(bytes(voters[_students[i]].name).length == 0, "student already exist");
            Voter memory _voter = Voter(_names[i], true, Stakeholder.STUDENT);
            _addVoter(_students[i], _voter);
        }

       
    }
    

    // @function that is used to create a teacher voter
    function addTeacher(string memory _name, address _teacher) public isChairperson {
        require(bytes(_name).length > 0, "teacher name is not valid");
        require(bytes(voters[_teacher].name).length == 0, "teacher already exist");

        Voter memory _voter = Voter(_name, true, Stakeholder.TEACHER);
        _addVoter(_teacher, _voter);

        emit TeacherCreated(_name, _teacher);
    }

    /**
        * @notice add teachers to the system
        * @dev add teachers to the system from a list of addresses and names
     */
    // function addTeachers(address[] memory _teachers, string[] memory _names) public isChairperson {
    //     require(_names.length > 0, "0 names");
    //     require(_teachers.length > 0, "0 addresses");
    //     require(_teachers.length == _names.length, "names != addresses");

    //     for(uint256 i = 0; i < _teachers.length; i++) {
    //         require(bytes(voters[_teachers[i]].name).length == 0, "teacher already exist");
    //         Voter memory _voter = Voter(_names[i], true, Stakeholder.TEACHER);
    //         _addVoter(_teachers[i], _voter);
    //     }
    // }


    // @function that is used to create a director voter
    function addDirector(string memory _name, address _director) public isChairperson {
        require(bytes(_name).length > 0, "director name is not valid");
        require(bytes(voters[_director].name).length == 0, "director already exist");

        Voter memory _voter = Voter(_name, true, Stakeholder.DIRECTOR);
        _addVoter(_director, _voter);

        emit DirectorCreated(_name, _director);
    }

    /**
        * @notice add directors to the system
        * @dev add directors to the system from a list of addresses and names
     */
    // function addDirectors(address[] memory _directors, string[] memory _names) public isChairperson {
    //     require(_names.length > 0, "0 names");
    //     require(_directors.length > 0, "0 addresses");
    //     require(_directors.length == _names.length, "names != addresses");

    //     for(uint256 i = 0; i < _directors.length; i++) {
    //         require(bytes(voters[_directors[i]].name).length == 0, "director already exist");
    //         Voter memory _voter = Voter(_names[i], true, Stakeholder.DIRECTOR);
    //         _addVoter(_directors[i], _voter);
    //     }
    // }

    /**
     * @notice check if address has been registered to vote
     * @dev check if address is in the list of voter addresses
     * @param _voter voter address or identifier
     * @return bool
     */
    function _isVoter(address _voter) private view returns(bool) {
        for(uint256 i = 0; i < voterAddresses.length; i++) {
            if(voterAddresses[i] == _voter) { return true; }
        }

        return false;
    }

    /**
     * @notice add a voter to the system
     * @dev add an address to our list of voters on the contract
     * @param _voter voter wallet address
     * @param _voterData voter information including name, canVote & userType
     */
    function _addVoter(address _voter, Voter memory _voterData) private {
        if (!_isVoter(_voter)) {
            voterAddresses.push(_voter);
            voters[_voter] = _voterData;
        }
    }

    /**
     * @notice set stakeholders initial vote weight
     * @dev initialize stakeholders vote weight
     * @param _weight vote weight
     */
    function _initializeStakeholdersVoteWeight(uint _weight) private {
        weights[Stakeholder.STUDENT] = _weight;
        weights[Stakeholder.TEACHER] = _weight;
        weights[Stakeholder.DIRECTOR] = _weight;
    }

    // @function that returns details about a user whose address is passed todo @KC
    function whoami(address _voter) public view returns(string memory name, string memory usertype, bool canVote){
        string memory _userType = "student";

        if(voters[_voter].userType == Stakeholder.TEACHER) {
            _userType = "teacher";
        }
        else if(voters[_voter].userType == Stakeholder.DIRECTOR) {
            _userType = "director";
        }

        return (voters[_voter].name, _userType, voters[_voter].canVote);
    }

    // @dev this function is used for creating an election either by a teacher or director
    function createElection(
        string memory _name, 
        string memory _description, 
        string[] calldata _choices,
        uint256 numHours
    ) public isDirectorOrTeacher {

       require(_choices.length > 1, "choice must be 2 at list");
        uint256 _num_choices = _choices.length;
        uint _id = electionCount;
        uint expirationTime = numHours * (60*60);

        Election memory _election = Election(_id, _num_choices, _name, _description, false, false, 0, 0);
        for (uint256 i = 0; i < _num_choices; i++) {
            Proposal memory _proposal = Proposal(_choices[i], 0);
            choices[_id].push(_proposal);
        }

        timers[electionCount] = expirationTime;
        elections[_id] = _election;
        electionCount++;
        
        emit BallotCreated(_id, _name, expirationTime);
    }

    // modifier for checking eection
    modifier electionStatus(uint256 _electionId){
        if(elections[_electionId].stopedAt == elections[_electionId].startedAt){
                revert("election has not started");
            }
        require(elections[_electionId].stopedAt >= block.timestamp, "election period has expired");
        require(elections[_electionId].active, "election must be active");
        require(!elections[_electionId].computed, "election result has already been computed");
            _;
    }
    // @dev this function is used to cast the vote of an election
    function castVote(uint256 _electionId, uint256 _proposalIndex) external electionStatus(_electionId) {
        require(voters[msg.sender].canVote == true, "you must be allowed to vote to perform this operation");
        require(hasVoted[_electionId][msg.sender] == false, "you have already voted for this election");

        // cast a vote based on the weight of that specific user type
        choices[_electionId][_proposalIndex].voteCount += weights[voters[msg.sender].userType];
        hasVoted[_electionId][msg.sender] = true;

        emit VoteCasted(_electionId, msg.sender);
    }
    //function to return the time remaining for each election
     function electionTimeLeft(uint256 _electionId)public view electionStatus(_electionId) returns(uint256){
         
        uint256 timeLeft =   elections[_electionId].stopedAt - block.timestamp; 
        return timeLeft;
     }

    // @function used to start an election. should only be called by chairperson todo @cptMoh
    function startElection(uint256 _electionId) external isChairperson {
        require(!elections[_electionId].active, "already started election cannot be started again");
        require(!elections[_electionId].computed, "election result has already been computed");
        elections[_electionId].active = true;
        elections[_electionId].startedAt = block.timestamp;
        elections[_electionId].stopedAt = timers[_electionId] + block.timestamp;
        emit BallotStarted(_electionId, elections[_electionId].name, block.timestamp);
    }

    // @dev this is a function to stop an election
    function stopElection(uint256 _electionId) public isChairperson electionStatus(_electionId) {
        elections[_electionId].active = false;
        elections[_electionId].stopedAt = block.timestamp;
        timers[_electionId] = block.timestamp;

        emit BallotStopped(_electionId, elections[_electionId].name, block.timestamp);
    }

    /**
     * @notice view the details of an election
     * @dev view election detailsl
     * @param _electionId the id of the election you want to view its details
     */
    function viewElection(uint256 _electionId) external view returns(
        string memory name, 
        string[] memory props, 
        bool isActive, 
        bool isComputed,
        uint256 startedAt,
        uint256 stopedAt

    ) {
        string[] memory proposals = new string[](choices[_electionId].length);
        for(uint256 i=0; i < choices[_electionId].length; i++) {
            proposals[i] = choices[_electionId][i].name;
        } 
        return (
            elections[_electionId].name, 
            proposals, 
            elections[_electionId].active, 
            elections[_electionId].computed,
            elections[_electionId].startedAt,
            elections[_electionId].stopedAt
        );
    }

    /**
     * @notice view the stats of an ongoing or completed election
     * @dev view election statistics
     * @param _electionId the id of the election you want to view the statistics of
     */
    function viewElectionStats(uint256 _electionId) external view returns(
        string[] memory names, 
        string[] memory user_types, 
        bool[] memory canVotes, 
        bool[] memory hasVoteds
    ) {
        string[] memory _names = new string[](voterAddresses.length);
        bool[] memory _canVotes = new bool[](voterAddresses.length);
        bool[] memory _hasVoteds = new bool[](voterAddresses.length);
        string[] memory _user_types = new string[](voterAddresses.length);

        for(uint256 i = 0; i < voterAddresses.length; i++){
            _names[i] = voters[voterAddresses[i]].name;
            string memory _user_type = "";

            if(voters[voterAddresses[i]].userType == Stakeholder.STUDENT) {
                _user_type = "student";
            } else if (voters[voterAddresses[i]].userType == Stakeholder.TEACHER) {
                _user_type = "teacher";
            } else {
                _user_type = "director";
            }

            _user_types[i] = _user_type;
            _canVotes[i] = voters[voterAddresses[i]].canVote;
            _hasVoteds[i] = hasVoted[_electionId][voterAddresses[i]];
        }
        
        return (_names, _user_types, _canVotes, _hasVoteds);
    }

    /**
     * @notice compile the results of an election, the election is automatically stopped when the result is compiled
     * @dev compile election results
     * @param _electionId the id of the election you want to compile the results for
     */
    function compileResults(uint256 _electionId) external isDirectorOrTeacher {
        elections[_electionId].computed = true;

        Proposal memory _max = choices[_electionId][0];
        for(uint256 i = 1; i < choices[_electionId].length; i++){
          if(choices[_electionId][i].voteCount > _max.voteCount){
              _max = choices[_electionId][i];
          }
        }

        winners[_electionId] = _max;
        
        emit BallotResultCompiled(_electionId, elections[_electionId].name, block.timestamp);
    }

    /**
     * @notice view the results of a completed election
     * @dev view results of an election
     * @param _electionId the id of the election you want to view the results for
     */
    function viewResult(uint256 _electionId) external view returns(
        string memory electionName, 
        string memory proposalName, 
        uint256 voteCount
    ) {
        require(elections[_electionId].computed == true, "results have not yet been compiled");
        return (elections[_electionId].name, winners[_electionId].name, winners[_electionId].voteCount);
    }

    /**
     * @notice manually set the weights for a particular voter type
     * @dev adjust voter type vote weights
     * @param stakeholder is the name of the voter type you want to set the weights for
     * @param weight is the value you want to set the weight to
     */
    function setWeight(string memory stakeholder, uint256 weight) external isChairperson {
        require(weight > 0 && weight <= 10, "weights can only take values 1 to 10");

        if(_stringsEquals(stakeholder,"student")) {
            weights[Stakeholder.STUDENT] = weight;
        } 
        else if(_stringsEquals(stakeholder,"teacher")) {
            weights[Stakeholder.TEACHER] = weight;
        } 
        else if(_stringsEquals(stakeholder,"director")) {
            weights[Stakeholder.DIRECTOR]  = weight;
        }
        else {
            revert("invalid stakeholder name entered");
        }
    }

    /**
     * @notice get the weights for a particular voter type
     * @dev adjust voter type vote weights
     * @param stakeholder is the name of the voter type you want to get the weights for
     */
    function getWeight(string memory stakeholder) external view isChairperson returns(uint256) {
        if(_stringsEquals(stakeholder,"student")) {
            return weights[Stakeholder.STUDENT];
        }
        else if(_stringsEquals(stakeholder,"teacher")) {
            return weights[Stakeholder.TEACHER];
        }
        else if(_stringsEquals(stakeholder,"director")) {
            return weights[Stakeholder.DIRECTOR];
        }
        
        revert("invalid stakeholder name entered");
    }

    /**
     * @notice ban a voter from participating in elections
     * @dev ban a voter from voting
     * @param _voter the voter's wallet address
     */
    function banVoter(address _voter) external isChairperson {
        require(voters[_voter].canVote, "user has already been banned");

        voters[_voter].canVote = false;
        emit BanVoter(voters[_voter].name, _voter);
    }

    /**
     * @notice unban a voter from participating in elections
     * @dev unban a voter from voting
     * @param _voter the voter's wallet address
     */
    function unbanVoter(address _voter) external isChairperson {
        require(!voters[_voter].canVote, "user is not banned");

        voters[_voter].canVote = true;
        emit UnbanVoter(voters[_voter].name, _voter);
    }

    // @function used to check if two strings are equal
    function _stringsEquals(string memory s1, string memory s2) private pure returns (bool) {
        bytes memory b1 = bytes(s1);
        bytes memory b2 = bytes(s2);

        uint256 l1 = b1.length;
        if (b1.length != b2.length) return false;

        for (uint256 i = 0; i < l1; i++) {
            if (b1[i] != b2[i]) return false;
        }

        return true;
    }

}