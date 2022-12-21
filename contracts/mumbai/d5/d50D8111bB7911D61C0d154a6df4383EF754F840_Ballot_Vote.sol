pragma solidity 0.8.9;
contract Ballot_Vote { // Variables
    struct Vote {
        address voterAddress;
        bool choice;
    }

    struct Voter {
        string voterName;
        bool voted;
    }

    uint private countResult = 0;
    uint public finalResult = 0;
    uint public totalVoter = 0;
    uint public totalVote = 0;

    address public balottOfficialAddress;
    string public ballotOfficeName;
    string public proposal;

    mapping(uint => Vote)private votes;
    mapping(address => Voter)public voterRegister;

    enum State {
        Created,
        Voting,
        Ended
    }
    State public state;


    // Modifier
    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    modifier onlyOfficial() {
        require(msg.sender == balottOfficialAddress);
        _;
    }

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    // Function
    constructor(string memory _ballotofficalName, string memory _prposol)public {
        balottOfficialAddress = msg.sender;
        ballotOfficeName = _ballotofficalName;
        proposal = _prposol;
        state = State.Created;
    }

    function addVotter(address _voterAddress, string memory _voterName)public inState(State.Created)onlyOfficial {
        Voter memory v;
        v.voterName = _voterName;
        v.voted = false;
        voterRegister[_voterAddress] = v;
        totalVoter ++;
    }

    function startVote() public inState(State.Created) onlyOfficial {
        state = State.Voting;
    }

    function doVote(bool _choice)public inState(State.Voting) returns(bool voted) {
        bool isFound = false;
        if(bytes(voterRegister[msg.sender].voterName).length!=0 && 
        voterRegister[msg.sender].voted == false )
        {
            voterRegister[msg.sender].voted = true;  
            Vote memory v;
            v.voterAddress = msg.sender;
            v.choice = _choice;
            if(_choice){
                countResult++;
            }
            votes[totalVote] = v;
            totalVoter++;
            isFound = true;
        }
        return isFound;
    }
    
    
    function endVote() public inState(State.Voting) onlyOfficial {
        state = State.Ended;
        finalResult =  countResult;
    }
 
}