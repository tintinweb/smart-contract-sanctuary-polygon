/**
 *Submitted for verification at polygonscan.com on 2022-03-02
*/

// SPDX-License-Identifier: MIT
// File: contracts/Helper.sol


pragma solidity ^0.8.0;

contract Helper{

   uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
            if (_i == 0) {
                return "0";
            }
            uint j = _i;
            uint len;
            while (j != 0) {
                len++;
                j /= 10;
            }
            bytes memory bstr = new bytes(len);
            uint k = len;
            while (_i != 0) {
                k = k-1;
                uint8 temp = (48 + uint8(_i - _i / 10 * 10));
                bytes1 b1 = bytes1(temp);
                bstr[k] = b1;
                _i /= 10;
            }
            return string(bstr);
        }

    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

        
}
// File: contracts/Ownable.sol


pragma solidity ^0.8.0;

contract Ownable{
    
      
      mapping(address => uint256) owners;
      
      
      
      modifier onlyOwner{
            require(owners[msg.sender]==1,"Permission denied"); 
            _;
       }
  
    constructor(){
      //deployer is owner
      owners[msg.sender]=1;
    }

    function addOwner(address toAdd) public onlyOwner {
        owners[toAdd]=1;
    }

     function removeOwner(address toRemove) public onlyOwner {
        owners[toRemove]=0;
    }
    
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// File: contracts/Tournaments.sol


pragma solidity ^0.8.0;

/// @title Banger games NFT contract
/// @author Banger games


//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


//import "./Teams.sol";


contract Tournaments is Ownable,Helper {
   
   
using SafeMath for uint;
    
    struct Tournament{
        uint id;
        string name;
        address creatorAddress; 
        uint pricePerPlayer;
        uint playersPerTeam;
        uint numberOfTeams;
        
        
        uint[] teamIds;
        uint[] appliedTeamIds; 
        

        uint status; //0 announced 1 registration  2 started  4 finished  7 canceled
        //remove distribute rewards
        
        uint prizeAmount;
        uint[] placements; //team id from 1st to last 
        IERC20 prizeToken;
        uint[] distributionRules; //banger, publisher, owner, teams... can be called only by the backend
        //Address - same as createTournament
        

        uint revertTimestamp;
        
        address gamePublisherAddress; 
        
    }

        //mapping useraddress+tourId to amount deposited (for each tournament)
        //this is used only for reverted/canceled tournaments
       mapping (bytes=>uint) deposited;
       
        //mapping teammemberadress+tourId to amount paid for that address
        mapping (bytes=>uint) paid;
   

    Tournament[] tournaments;


     
    struct Team{
        uint id;
        address teamOwner;
        string name; 
        address[] memberAddress;

    }

    Team[] teams;

    //move to constructor
    address bangerAddress=0x2E48479cDDEF205B2df644d397358c45105969f6; 
    //add creatorAddress to constructor, remove msg.sender
    function createTournament(string memory _name, uint _pricePerPlayer, uint _playersPerTeam, uint _numberOfTeams,address _prizeToken, uint _daysTillRevert, address _gamePublisherAddress, uint[] memory _distribution) public onlyOwner {
            
            uint[] memory tempIds;
            uint[] memory tempAppliedTeamIds;
            
            uint[] memory tempPlacements; //check for nicer solution
            //Addminutes -> addDays


            //TODO truncate tournament limited to distribution rule length -3
            uint sum=0;
            for (uint i=0;i<_distribution.length;i++){
                sum+=_distribution[i];
            }
            require(sum==100, "Distribution not equal 100");

            Tournament memory t = Tournament(tournaments.length,_name, msg.sender,_pricePerPlayer,_playersPerTeam,_numberOfTeams,tempIds,tempAppliedTeamIds,0,0,tempPlacements,IERC20(_prizeToken),_distribution,addMinutes(block.timestamp,_daysTillRevert),_gamePublisherAddress);
            tournaments.push(t);

    }

    function createTeam(address _teamOwner, string memory _name, address[] memory _memberAddress) public  onlyOwner {
        
        Team memory t = Team(teams.length,_teamOwner,_name, _memberAddress);
        teams.push(t);
       
    }

    
    function openRegistration(uint _tournamentId) public onlyOwner {
        
        require(tournaments[_tournamentId].status==0,"Not in announced status."); 

        tournaments[_tournamentId].status=1;

    }


    function depositPrizeTokens(uint _tournamentId, uint _amount) public {
        tournaments[_tournamentId].prizeToken.transferFrom(msg.sender,address(this),_amount);
        tournaments[_tournamentId].prizeAmount+=_amount;
        bytes memory h=abi.encodePacked(msg.sender,_tournamentId);
        deposited[h]+=_amount;
        
    }

    function cancelTournament(uint _tournamentId) public {  

        require(tournaments[_tournamentId].status!=3 || tournaments[_tournamentId].status!=7, "Tournament finished/canceled.");
        require(block.timestamp>=tournaments[_tournamentId].revertTimestamp, "Tournament can't be reverted yet.");

        bytes memory h=abi.encodePacked(tournaments[_tournamentId].creatorAddress,_tournamentId);
        uint amount=deposited[h];
        if (amount>0) sendToken(_tournamentId,tournaments[_tournamentId].creatorAddress,amount);
        for (uint i=0;i<tournaments[_tournamentId].teamIds.length;i++){
            if (teams[tournaments[_tournamentId].teamIds[i]].teamOwner!=tournaments[_tournamentId].creatorAddress) 
            {
            h=abi.encodePacked(teams[tournaments[_tournamentId].teamIds[i]].teamOwner,_tournamentId);
            amount=deposited[h];
            if (amount>0) sendToken(_tournamentId,teams[tournaments[_tournamentId].teamIds[i]].teamOwner,amount);
            }
        }
        tournaments[_tournamentId].status=7;

    }

    function applyForTournament(uint _teamId, uint _tournamentId) public {
        require(msg.sender==teams[_teamId].teamOwner ,"Permission denied");
        require(tournaments[_tournamentId].status==1,"Tournament not in registration status");
   

        bool joined=false;
        for(uint i=0;i<tournaments[_tournamentId].teamIds.length;i++){
            if (_teamId==tournaments[_tournamentId].teamIds[i]) joined=true;
        }
        require(joined==false, "Team already joined");
        require((teams[_teamId].memberAddress.length)==tournaments[_tournamentId].playersPerTeam,"Team size doesn't match"); //OWNER IS NOT PLAYER
        tournaments[_tournamentId].teamIds.push(_teamId);


    }


    function amountPaid(uint _teamId, uint _tournamentId) private view returns (uint ){
           uint teamPaid=0;
        for(uint i=0;i<teams[_teamId].memberAddress.length;i++){
            teamPaid+=paid[abi.encodePacked(teams[_teamId].memberAddress[i],_tournamentId)];
        }
        return teamPaid;
    }

    //ch notepad //halfpayments revert when tour is full
    function payTournament(uint _teamId, uint _tournamentId, uint _amount) public {
        require(tournaments[_tournamentId].status==1,"Tournament not in registration status");
        require(_amount==tournaments[_tournamentId].pricePerPlayer || _amount==tournaments[_tournamentId].pricePerPlayer*tournaments[_tournamentId].playersPerTeam, "Incorrect amount. (required price per player or full amount)");
        require(tournaments[_tournamentId].appliedTeamIds.length<tournaments[_tournamentId].numberOfTeams, "Tournament full");

         bool joined=false;
        for(uint i=0;i<tournaments[_tournamentId].teamIds.length;i++){
            if (_teamId==tournaments[_tournamentId].teamIds[i]) joined=true;
        }
        require(joined==true,"Not joined.");
        uint teamPaid=amountPaid(_teamId,_tournamentId);
        require(teamPaid<tournaments[_tournamentId].pricePerPlayer*tournaments[_tournamentId].playersPerTeam, "Already paid.");
        paid[abi.encodePacked(msg.sender,_tournamentId)]+=_amount;
        teamPaid+=_amount;

        if (teamPaid>=tournaments[_tournamentId].pricePerPlayer*tournaments[_tournamentId].playersPerTeam){
            tournaments[_tournamentId].appliedTeamIds.push(_teamId); 
        }

        //TOURNAMENT FULL
        if (tournaments[_tournamentId].appliedTeamIds.length==tournaments[_tournamentId].numberOfTeams){
            tournaments[_tournamentId].teamIds=tournaments[_tournamentId].appliedTeamIds;
            //GOTO START STATUS (temp)
            tournaments[_tournamentId].status=2;
        }
        depositPrizeTokens(_tournamentId,_amount);

    }

  
    //only owner
    function setPlacements(uint _tournamentId, uint[] memory _placements) public onlyOwner {
        require(msg.sender==tournaments[_tournamentId].creatorAddress || owners[msg.sender]==1, "Permission denied");
        require(tournaments[_tournamentId].status==2, "Tournament not in started status.");
        tournaments[_tournamentId].placements=_placements;
        //tournaments[_tournamentId].status=3; //old distri rewards
        distributeRewards(_tournamentId);
    }

    //private, called from setPlacements
    function distributeRewards(uint _tournamentId) private {
         Tournament memory tour=tournaments[_tournamentId];


        for (uint i=0;i<tour.distributionRules.length;i++){
            
            uint amount=tour.prizeAmount.div(100).mul(tour.distributionRules[i]);

            if (amount>0){
            if (i==0)  
            {
                sendToken(_tournamentId, bangerAddress,amount); //banger
            }
            else if (i==1){
                 sendToken(_tournamentId, tournaments[_tournamentId].gamePublisherAddress,amount); //publisher
            }
            else if (i==2){
                 sendToken(_tournamentId, tournaments[_tournamentId].creatorAddress,amount); //creator
            }
            else {
                uint numPlayers=teams[tour.placements[i-3]].memberAddress.length;
                for (uint j=0;j<numPlayers;j++){
                    sendToken(_tournamentId,teams[tour.placements[i-3]].memberAddress[j],amount.div(numPlayers));
                }

            }
            }

        }

        tournaments[_tournamentId].status=4;

    }



    
    function sendToken(uint _tournamentId, address _to, uint _amount) private {
        //IERC20 testToken= IERC20(0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1);
        tournaments[_tournamentId].prizeToken.transfer(_to,_amount);

    }

    function getTournament(uint _tournamentId) public view returns(Tournament memory){
        return tournaments[_tournamentId];
    }

     function getTournaments() public view returns(Tournament[] memory){
        return tournaments;
    }

     function getTeams() public view returns(Team[] memory){
        return teams;
    }

     function getTeam(uint _teamId) public view returns(Team memory){
        return teams[_teamId];
    }

  function getDistributionRules(uint _tournamentId) public view returns(uint[] memory){
        return tournaments[_tournamentId].distributionRules;
    }

  
 
}