/**
 *Submitted for verification at polygonscan.com on 2022-08-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

pragma solidity ^0.8.4;
pragma abicoder v2;

/** @title Blockfantasy Point Contract.
 * @notice A contract for calculating blockfantasy fantasy 
 *  team results from a chainlink external adapter.
 */

 contract Blockfantasy is Ownable{
     using SafeMath for uint256;


     uint256 public currenteventId;
     uint256 public currentpoolId;
     uint256 private currentteamid;
     uint256 public commission1;
     uint256 private eventuserscount;
     uint256 private totaluserpoint; //make private later
     uint256 private userpoint; //make private later
     uint256 private vicemultiplier;
     uint256 private captainmultiplier;
     address public operatorAddress;
     address private we;
     uint256 private userresultcount;
     address[] private emptyaddress;
     uint256[] private empty;
     string[] private emptystring;

     struct Event{
         uint256 eventid; //would be an increment for each new event
         string eventname;
         uint256[] eventspool;
         uint256[] playerslist;
         address[] users;
         uint256 closetime;
         uint256 matchtime;
         address[] playersrank;
         uint256[] prizeDistribution;
         bool canceled;
     }

     struct Users{
         uint256 eventid;
         address user;
         //uint256[] selectedplayers;
         uint256 userscore;
         uint256[] teamnames;
         uint256[] userpool;
         //totaluserpoint() function to get players point
     }

     struct Team{
         address user;
         uint256 teamid;
         string teamname;
         uint256 selectedcaptain;
         uint256 selectedvicecaptain;
         uint256[] selectedplayers;
     }

     struct Pool{
         uint256 poolid;
         uint256 poolamount;
         uint256[] teamsarray;
         uint256 entryfee;
         uint256 pooluserlimt;
         address[] userarray; 
         bool canceled;
     }

     struct Players{
         uint256 eventid;
         uint256 player; //players pid
         uint256 playerscore; //players score
     }

     struct Userresult{
         address user;
         uint256 score;
         uint256 count;
     }
     
     struct Usercount{
        uint256[] teamcount;
     }

     //mapping
     mapping(uint256 => Event) private _events;
     mapping(uint256 => Users) private _user;
     mapping(uint256 => Players) private _player;
     mapping(address => mapping(uint256 => Team)) private teams;
     mapping(uint256 => Pool) private pools;
     mapping(uint256 => Userresult) private _userresult;
     mapping(uint256 => address) private usertoteam;
     mapping(uint256 => uint256) private userinpoolcount; //this for our chainlink keeper
     mapping(uint256 => mapping(uint256 => uint256)) private playerpoints; //event to players to points
     mapping(address => mapping(uint256 => uint256[])) private selectedusers; //event to players to selected players array
     mapping(address => mapping(uint256 => uint256)) private userpointforevent; //users point for a particular event     
     mapping(address => mapping(uint256 => Usercount)) private userteamcount; //used for team count required

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "Not operator");
        _;
    }
     constructor(address operator, uint256 _commission){
         operatorAddress = operator;
         commission1 = _commission;
     }

     function CreateEvents(
         string memory name,
         uint256[] calldata playerspid,
         uint256 starttime,
         uint256 poolonefee,
         uint256 poolonetotalpool,
         uint256 pooloneuserlimit,
         uint256 pooltwofee,
         uint256 pooltwototalpool,
         uint256 pooltwouserlimit
         ) external onlyOwner{
             require(starttime > block.timestamp, "Start time needs to be higher than the current time");
             require(poolonefee > 0, "Add a fee for pool one");
             require(pooltwofee > 0, "Add a fee for pool two");
             require(pooloneuserlimit > 0, "pool must have a userlimit");
             require(pooltwouserlimit > 0, "pool must have a userlimit");
             require(playerspid.length > 0, "Add a player");
             //add requirements statement
             currenteventId++;
             _events[currenteventId] = Event({
                 eventid : currenteventId,
                 eventname : name,
                 eventspool : empty, 
                 playerslist : playerspid,
                 users : emptyaddress,
                 closetime : 3600 + starttime,
                 matchtime : starttime,
                 playersrank : emptyaddress,
                 prizeDistribution: empty,
                 canceled : false
             });
             for (uint256 i = 0; i < playerspid.length; i++){
                 uint256 but = playerspid[i];
                 playerpoints[currenteventId][but] = 0; 
                 _player[currenteventId] = Players ({
                     eventid : currenteventId,
                     player : but,
                     playerscore : 0
                 });
             }
            Createpool(poolonetotalpool, poolonefee, currenteventId, pooloneuserlimit);
            Createpool(pooltwototalpool, pooltwofee, currenteventId,pooltwouserlimit);
    }

    function Createpool(
        uint256 amount,
        uint256 fee,
        uint256 eventid,
        uint256 userlimit
        ) public onlyOwner{
            currentpoolId++;
            pools[currentpoolId] = Pool({
                poolid : currentpoolId,
                poolamount : amount,
                teamsarray : empty,
                entryfee : fee,
                pooluserlimt : userlimit,
                userarray : emptyaddress,
                canceled : false
            });
            _events[eventid].eventspool.push(currentpoolId);
        }

    function Joinevent(
        uint256 eventid,
        address user,
        uint256 team,
        uint256 pool
    ) public payable{
        //requirement statement for close time
        //check if event has been canceled
        require(_events[eventid].canceled = false, "Event has been canceled");
        //requirement statement to check user team count for an event
        uint256[] memory fit = userteamcount[user][eventid].teamcount;
        require(fit.length < 3, "User team count is more than 3");
        //requirement statement to check users fee
        require(pools[pool].entryfee == msg.value, "Enter the exact entry fee");
        //check if users team exist
        require(usertoteam[team] == user, "user doesn't have such team");
        require(pools[pool].canceled = false, "pool has been canceled");
        eventuserscount++;
        _user[eventid] = Users({
            eventid : eventid,
            user : user,
            userscore : 0,
            teamnames : empty,
            userpool : empty
        });
        userteamcount[user][eventid].teamcount.push(team);
        _user[eventid].userpool.push(pool);
        _events[eventid].users.push(user);
        pools[pool].teamsarray.push(team);
        pools[pool].userarray.push(user);
        uint256 count;
        userinpoolcount[pool] = count.add(1);
    }

    function getusersinpool(uint256 pool) public view returns (uint256) {
        uint256 count = userinpoolcount[pool];
        return count;
    }

    function Createteam(
        address useraddress,
        uint256 eventid,
        uint256 captain,
        string memory _teamname,
        uint256 vicecaptain,
        uint256[] calldata playersselected
        ) external {
             require(captain > 0, "You must have a captain");
             require(vicecaptain > 0, "You must have a vice-captain");
             require(playersselected.length > 0, "You must have a captain");
            currentteamid++;
            teams[useraddress][eventid] = Team({
                user : useraddress,
                teamid : currentteamid,
                teamname : _teamname,
                selectedcaptain : captain,
                selectedvicecaptain : vicecaptain,
                selectedplayers : playersselected
            });
            selectedusers[useraddress][eventid] = playersselected;
            usertoteam[currentteamid] = useraddress;
        } 

        //cancel event
    function cancelevent(uint256 eventid) public onlyOwner{
        require(_events[eventid].canceled = false, "Event has been already canceled");
        _events[eventid].canceled = true;
        for(uint256 i=0; i < _events[eventid].eventspool.length; i++){
            cancelpool(_events[eventid].eventspool[i]);
        }
    }
    function cancelpool(uint256 poolid) public onlyOwner{
        //check if competition has been canceled
        require(pools[poolid].canceled = false, "Pool has already been canceled");
        // check if competition has already started
        pools[poolid].canceled = true;
        for(uint256 i=0; i < pools[poolid].userarray.length; i++){
            returnentryfee(poolid, address (uint160(pools[poolid].userarray[i])));
        }
    }

    function returnentryfee(uint256 poolid, address user) internal {
        uint256 fee = pools[poolid].entryfee;
        payable(user).transfer(fee);
    }

    function changecommision(uint256 rate) public onlyOwner{
        //require commision must not be abobe so limit
        require(rate > 300, "Commission must have a value Or cannpt be greater than 300");
        commission1 = rate;
    }

    function updateplayerscore(uint256[] calldata scores, uint256 eventid) public onlyOwner{
        require(scores.length > 0, "Score array must have a value");
        uint256[] memory playerspid = _events[eventid].playerslist;
        for (uint256 i = 0; i < playerspid.length; i++){
            uint256 but = playerspid[i];
            playerpoints[eventid][but] = scores[i];
        }
    }

    function getCommission() public view returns (uint256) {
        return commission1;
    }

    function getEvent(uint256 eventid) public view returns (string memory, uint256[] memory, uint[] memory, uint256, uint256, address[] memory, uint256[] memory) {
        return ( _events[eventid].eventname,
        _events[eventid].eventspool,
        _events[eventid].playerslist,
        _events[eventid].closetime,
        _events[eventid].matchtime,
        _events[eventid].playersrank,
        _events[eventid].prizeDistribution);
    }

    function getalluserspoint(uint256 eventid) public {
        address[] storage boy = _events[eventid].users;
        for (uint256 i = 0; i < boy.length; i++){
            _events[eventid].users[i];
            address few = _events[eventid].users[i];
            uint256[] memory tip=teams[few][eventid].selectedplayers;
            geteachuserspoint(tip,eventid,few, teams[few][eventid].selectedcaptain, teams[few][eventid].selectedvicecaptain);
        }
    }

    function geteachuserspoint(uint256[] memory userarray, uint256 eventid, address meet, uint256 cpid, uint256 vpid) public returns (uint256) {
        for (uint256 i = 0; i < userarray.length; i++){
            uint256 me = userarray[i];
            totaluserpoint += playerpoints[eventid][me];
            uint256 vp = playerpoints[eventid][vpid];
            uint256 cp = playerpoints[eventid][cpid];
            uint256 removedpoint = vp.add(cp);
            uint256 vicecaptainpoint = vp.mul(vicemultiplier);
            uint256 captainpoint = cp.mul(captainmultiplier);
            uint256 removedcaptainandvice = totaluserpoint.sub(removedpoint);
            userpoint = removedcaptainandvice.add(captainpoint).add(vicecaptainpoint);
            userpointforevent[meet][eventid] = userpoint;
            //look for a way to update user struct
            _user[eventid].userscore = userpoint;
            _userresult[eventid] = Userresult({
                user : meet,
                score : userpoint,
                count : userresultcount++
            });
        }
        uint256 wip = _user[eventid].userscore;
        return wip;
    }

    function getalluserresult(uint256 eventid) public view returns (Userresult[] memory){
        uint256 count = _events[eventid].users.length;
        Userresult[] memory results = new Userresult[](count);
        for (uint i = 0; i < count; i++) {
            Userresult storage result = _userresult[i];
            results[i] = result; 
        }
        return results;
    }

    function getusersplayers(address user, uint256 eventid) public view returns (uint256[] memory){
        uint256[] memory score = selectedusers[user][eventid];
        return score;
    }

    function testdata(uint256 test, uint256 eventid) public returns (uint256){
        uint256[] memory playerspid = _events[eventid].playerslist;
        for (uint256 i = 0; i < playerspid.length; i++){
            uint256 but = playerspid[i];
            playerpoints[currenteventId][but] = test; 
        }
        return test;
    }

     function buildDistribution(uint256 _playerCount, uint256 _stakeToPrizeRatio,uint256 eventid, uint256 poolid, uint256 _skew) internal view returns (uint256[] memory){
         uint256[] memory prizeModel = buildFibPrizeModel(_playerCount, _skew);
         uint256[] memory distributions = new uint[](_playerCount);
         uint256 prizePool = getPrizePoolLessCommission(eventid, poolid);
          for (uint256 i=0; i<prizeModel.length; i++){
              uint256 constantPool = prizePool.mul(_stakeToPrizeRatio).div(100);
              uint256 variablePool = prizePool.sub(constantPool);
              uint256 constantPart = constantPool.div(_playerCount);
              uint256 variablePart = variablePool.mul(prizeModel[i]).div(100);
              uint256 prize = constantPart.add(variablePart);
              distributions[i] = prize;
          }
          return distributions;
     }

    function buildFibPrizeModel (uint256 _playerCount, uint256 _skew) internal pure returns (uint256[] memory){
        uint256[] memory fib = new uint[](_playerCount);
        uint256 skew = _skew;
        for (uint256 i=0; i<_playerCount; i++) {
             if (i <= 1) {
                 fib[i] = 1;
                } else {
                     // as skew increases, more winnings go towards the top quartile
                     fib[i] = ((fib[i.sub(1)].mul(skew)).div(_playerCount)).add(fib[i.sub(2)]);
                }
        }
        uint256 fibSum = getArraySum(fib);
        for (uint256 i=0; i<fib.length; i++) {
            fib[i] = (fib[i].mul(100)).div(fibSum);
        }
        return fib;
    }
    function getCommission(uint256 eventid, uint256 poolid) public view returns(uint256){
        address[] memory me = _events[eventid].users;
        return me.length.mul(pools[poolid].entryfee)
                        .mul(commission1)
                        .div(1000);
    }

    function getPrizePoolLessCommission(uint256 eventid, uint256 poolid) public view returns(uint256){
        address[] memory me = _events[eventid].users;
        uint256 totalPrizePool = (me.length
                                    .mul(commission1))
                                    .sub(getCommission(eventid, poolid));
        return totalPrizePool;
    }

    function submitPlayersByRank(uint256 eventid, address[] memory users, uint256 poolid, uint256 stakeToPrizeRatio, uint256 _skew) public {
        address[] memory me = _events[eventid].users;
        _events[eventid].prizeDistribution = buildDistribution(me.length, stakeToPrizeRatio, eventid, poolid, _skew);
        for(uint i=0; i < users.length; i++){
            _events[eventid].playersrank.push(users[i]);
        }
    }

    function getArraySum(uint256[] memory _array) internal pure returns (uint256){
        uint256 sum = 0;
        for (uint256 i=0; i<_array.length; i++){
            sum = sum.add(_array[i]);
        }
        return sum;
    }

    function getPrizeDistribution(uint256 eventid) public view returns(uint256[] memory){
        return _events[eventid].prizeDistribution;
    }

     function withdrawPrizes(uint256 eventid) public {
         address[] memory me = _events[eventid].users;
         for(uint256 i=0; i < me.length; i++){
              payable(address(uint160(_events[eventid].playersrank[i])))
              .transfer(_events[eventid].prizeDistribution[i]);
        }
     }

     receive() external payable {}
 }