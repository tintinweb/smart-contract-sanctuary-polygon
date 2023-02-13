/**
 *Submitted for verification at polygonscan.com on 2023-02-12
*/

// File: contracts/IEscrow.sol


pragma solidity ^0.8.0;

interface IEscrow {
    event EscrowCreated(uint, address, address);
    event MoneyRecieved(uint, bytes32);
    event MoneyPaid(address payable[], bytes32);

    function createEscrow(
        uint _id,
        address payable _organizer,
        uint _wamount,
        uint _viewerPool,
        uint _organizerFee,
        address _token
    ) payable external;

    function releasePayment(
        uint id,
        address payable[] memory winners,
        uint[] memory distributions
    ) external;

    function refundPayment(uint id) external;

    function recieve() external payable;

    struct Escrow {
        address payable organizer;
        uint wamount;
        uint id;
        uint organizerFee;
        uint viewerPool;
        address token;
    }
}

// File: contracts/IMatchMaker.sol


pragma solidity ^0.8.0;

interface IMatchMakerSE {
    function makeMatches(uint _round, uint _tid) external;
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event MatchMade(uint MatchId, uint team1, uint team2);
    event BracketUpdated(uint MatchId, uint WinnerId, uint TournamentId, uint roundId);
    event RoundStarted(uint roundId, uint TournamentId);
    struct Match {
        uint id;
        uint winner;
        uint tournamentId;
        uint roundId;
    }
    struct Request{
        uint requestId;
        uint tId;
    }
    function matches(uint id) external view returns(Match memory);
    function players(uint _tid,uint _roundId) external view returns(uint[] memory);
    function winners(uint _tid,uint _roundId) external view returns(uint [] memory);
    function _updateWinner(uint _mid,uint _winnerId) external; 
    function getTournamentRoundMatches(uint _tid,uint _rid) external view returns(Match[] memory);
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File: contracts/TournamentController.sol


pragma solidity ^0.8.0;





contract TournamentController is Ownable{
    // counters openzeppelin
    using Counters for Counters.Counter;

    // all the events
    event TeamCreated(uint indexed teamId,address indexed leader,address[] indexed members);
    event TournamentCreated(uint indexed tournmenId,uint indexed prizepool,string indexed organizer );
    event Registered(uint indexed teamId,uint tournamentId);
    // event TournamentStarted();
    // counter for tournament ids
    Counters.Counter internal tournamentCounter;
    Counters.Counter internal teamCounter;
    // escrow contract address
    address payable public escrow;
    // match maker contract address
    address public matchMakerAddress;

    //get all participant teams from a tournament id
    mapping(uint => uint[]) public participants;
    // get the prize distribution for tournament id
    mapping (uint => uint[]) public distributions;
    // tournament wise round wise winners
    mapping (uint => mapping(uint=>uint[])) public winners;
    // get Tournament from Tournament id
    mapping(uint => Tournament) public tournaments;
    // mapping for teams
    mapping(uint=>Team) public teams;
    // mapping for tournamentId to ongoing round
    // mapping(uint => uint16 ) public rounds;

    enum State{
        Created,
        Started,
        Finished
    }

    struct Team {
        string name;
        address[] members;
        address leader;
    }

    struct Organizer{
        string name;
        address Add_org;
    }
    struct RewardToken{
        address tokenAddress;
        string chain;
    }
    struct Prizes{
        uint participantPool;
        uint viewerPool;
        uint organizerFee;
        uint totalPool;
    }


    struct Tournament{
        uint16 round;
        uint16 sizeLimit;
        uint32 maxParticipants;
        bytes32 bracketType;
        State state;
        Organizer org;
        RewardToken token;
        Prizes prize;
    }

    // constructor

    constructor(address payable _escrow) {
        escrow=_escrow;
    }

    function createTournament(Tournament memory _t) external payable {
        require(_t.round==0,"TournamentController: Can only start with round 0!");
        require(_t.org.Add_org== msg.sender,"TournamentController: Only organizer can create a tournament!");
        require(_t.sizeLimit>0,"TournamentController: Can not have a size limit of 0!");
        require(_t.maxParticipants>0,"TournamentController: Can not have max participants as 0!");
        require(_t.state==State.Created,"TournamentController:Can only have the initial state");
        require(_t.round==0,"TournamentController: Can only start from round 0");
        uint allowance=IERC20(_t.token.tokenAddress).allowance(msg.sender,address(this));
        require(allowance>=_t.prize.totalPool,"TournamentController: Not Enough allowance!");
        IERC20(_t.token.tokenAddress).transferFrom(msg.sender,escrow,_t.prize.totalPool);
        IEscrow(escrow).createEscrow(tournamentCounter.current(),payable(_t.org.Add_org),_t.prize.participantPool,_t.prize.viewerPool,_t.prize.organizerFee,_t.token.tokenAddress);
        tournamentCounter.increment();
        tournaments[tournamentCounter.current()]=_t;
        // rounds[tournamentCounter.current()]=0;
        emit TournamentCreated(tournamentCounter.current(),_t.prize.totalPool,_t.org.name);
    }

     /// @param id - tournament's id
     /// @param _dist - the array of prize distribution for the tournament
    function setDistribution(uint [] memory _dist,uint id) external{
        require(id<=tournamentCounter.current(),"TournamentController: Invalid tournament id");
        require(tournaments[id].state==State.Created,"TournamentController: Distribution can not be changed!");
        require(msg.sender == tournaments[id].org.Add_org, "TournamentController: Only the oraganizer can set the distribution");
        uint distTotal;
        for(uint i=0;i<_dist.length;i++){
            distTotal+=_dist[i];
        }
        require(distTotal==tournaments[id].prize.participantPool,"TournamentController: Incorrect distribution!");
        distributions[id]=_dist;
    }

    function createTeam(Team memory _team) public {
        require(msg.sender==_team.leader,"TournamentController: Only the leader can create a team!");
        for(uint i=0;i<_team.members.length;i++){
            for(uint j=i+1;j<_team.members.length;j++){
                if(_team.members[j]==_team.members[i]){
                    revert("TournamentController: Duplicate team members not allowed!");
                }
            }
        }
        teamCounter.increment();
        teams[teamCounter.current()]=_team;
        emit TeamCreated(teamCounter.current(),_team.leader,_team.members);
    }
    function register(uint _tournamentId,uint _teamId) public {
        require(_teamId<=teamCounter.current(),"TournamentController: Team id does not exsist!");
        require(_tournamentId<=tournamentCounter.current(),"TournamentController: Tournament id does not exsist!");
        require(tournaments[_tournamentId].state==State.Created,"TournamentController: Registration time for tournament over!");
        require(msg.sender==teams[_teamId].leader,"TournamentController: Only Team Leader can register!");
        require(teams[_teamId].members.length==tournaments[_tournamentId].sizeLimit,"TournamentController: Invalid team size!");
        require(participants[_tournamentId].length<tournaments[_tournamentId].maxParticipants,"TournamentController: Maximum participants limit reached!");
        for(uint i=0;i<participants[_tournamentId].length;i++){
            if(participants[_tournamentId][i]==_teamId){
                revert("TournamentController: Team already registered for the given Tournament!");
            }
        }
        participants[_tournamentId].push(_teamId);
        emit Registered(teamCounter.current(),tournamentCounter.current());
    }

    function updateMatchWinner(uint _mid, uint _winnerId) public {
        uint _tid=IMatchMakerSE(matchMakerAddress).matches(_mid).tournamentId;
        require(_tid!=0,"TournamentController: Incorrect Match ID!");
        require(msg.sender==tournaments[_tid].org.Add_org,"TournamentController: Only Organizer can update match winner!");
        require(tournaments[_tid].state==State.Started,"TouranmentController: Can only update the state of an ongoing tournament!");
        require(tournaments[_tid].round==IMatchMakerSE(matchMakerAddress).matches(_mid).roundId,"TournamentController: Can only update a match in an ongoing round");
        IMatchMakerSE(matchMakerAddress)._updateWinner(_mid,_winnerId);
        winners[_tid][tournaments[_tid].round].push(_winnerId);
    }

    // function getParticipants(uint _tid) public view returns(uint[] memory) {
    //     require(tournamentCounter.current()>=_tid,"TournamentController: Invalid Tournament Id!");
    //     return participants[_tid];
    // }

    // function getRound(uint _tid) public view returns(uint16){
    //     require(tournamentCounter.current()>=_tid,"TournamentController: Invalid Tournament Id!");
    //     // return rounds[_tid];
    //     return tournaments[_tid].round;
    // }

    // function getTournamentDetails(uint _tid) public view returns(Tournament memory){
    //     require(tournamentCounter.current()>=_tid,"TournamentController: Invalid Tournament Id!");
    //     return tournaments[_tid];
    // }

    // function getTeamDetails(uint _id) public view returns(Team memory){
    //     require(teamCounter.current()>=_id,"TournamentController: Invalid Team Id!");
    //     return teams[_id];
    // }

    function cancelTournament(uint _tid) public {
        require(_tid<tournamentCounter.current(),"TournamentController: Invalid Tournament Id");
        require(tournaments[_tid].org.Add_org==msg.sender,"TournamentController: Only the organizer can cancel the tournament");
        require(tournaments[_tid].state==State.Created,"TournamenController: Can only cancel a tournament which is not started!");
        IEscrow(escrow).refundPayment(_tid);
    }

    // allow to set MatchMaker
    function setMatchMakerAddress(address _matchMaker) public onlyOwner{
        require(_matchMaker!=address(0));
        matchMakerAddress=_matchMaker;
    }
    function updateTournamentState(uint _tid,uint _nextRound) public{
        require(tournamentCounter.current()<=_tid,"TournamentController: Invailid Tournament Id!");
        require(tournaments[_tid].state!=State.Finished,"TouranmentController: Can only update the state of an ongoing tournament!");
        require(tournaments[_tid].round==_nextRound-1,"TournamentController: Can only start the next round!");
        require(tournaments[_tid].org.Add_org==msg.sender,"TournamentController: Only the organizer can update state");
        require(distributions[_tid].length!=0,"TournamentController: Must set up distribution before starting the tournament");
        if(_nextRound==1){
            tournaments[_tid].state=State.Started;
        }
        IMatchMakerSE(matchMakerAddress).makeMatches(_nextRound,_tid);
    }

    
    // to be implemented!
    // function disqualifyTeam(uint _teamId,uint _tournamentId) public{
    //     require(teamCounter.current()>=_teamId,"TournamentController: Invalid Team ID!");
    //     require(tournamentCounter.current()>=_tournamentId,"TournamentController: Invalid tournament Id!");
    //     require(msg.sender == tournaments[_tournamentId].org.Add_org, "TournamenController: Only the organizer can disqualify  a team!");
    //     if(tournaments[_tournamentId].state==State.ended){
    //         revert("TournamentController: Can only disqualify a team from a ongoing tournament!");
    //     }
    //     if(tournaments[_tournamentId].state==State.started){

    //     }
    // }

    

    function endTournament(uint _tid,uint[] memory winnerIds) public{
        require(tournaments[_tid].state==State.Started,"TournamentController: Must start the tournament first!");
        require(winnerIds.length==distributions[_tid].length,"TournamentController: Only as many winners as distributions");
        address payable[] memory winnersAddress;
        for(uint i=0;i<winnerIds.length;i++){
            winnersAddress[i]=payable(teams[winnerIds[i]].leader);
        }
        IEscrow(escrow).releasePayment(_tid,winnersAddress,distributions[_tid]);
        tournaments[_tid].state=State.Finished;
        // uint _round=tournaments[_tid].round;
        // address payable [] memory winnerAddress;
        // uint count=0;
        // while(count<distributions[_tid].length){
        //     uint no_of_winners=winners[_tid][_round].length;
        //     uint i=0;
        //     while(_round>0 && i<no_of_winners && count<distributions[_tid].length){
        //         winnerAddress[count]=teams(winners[_tid][_round][i]).leader;

        //     }
        // }
    }


}