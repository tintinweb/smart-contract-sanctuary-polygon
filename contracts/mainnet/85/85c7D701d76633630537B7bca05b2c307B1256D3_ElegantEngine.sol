//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../concatenate.sol";

interface RulesInterface{
    function tokenCheck (uint id, uint valToCheck, address _con) external view returns (bool);
    function prizeCheck () external view returns (uint[] calldata);
    function nutPrizeCheck () external view returns (uint[] calldata);
    function scoreCheck () external view returns (uint[] calldata);
}

interface RacerInterface {
    function tokensOfOwner(address _owner) external view returns (uint[] memory);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address _owner, uint256 _id) external view returns (uint);
}

interface AccountInterface {
    function getCaptain(address _wallet) external view returns(uint256);
}

interface StakingInterface {
    function getWeek() external view returns(uint);
    function getBoost(address _wallet,uint _boost) external view returns(uint);
    function addScore(address _wallet, uint _plus) external;
    function walletList() external view returns (address[] memory);
}

interface EngineInterface {
    function racersByEvent(uint256 _week, uint256 _slot) external view returns (uint256);
    function racersByRace(uint256 _week, uint256 _race, uint256 _slot) external view returns (uint256);
    function perfByRacer(uint256 _week, uint256 _id) external view returns(uint, address, uint, uint, uint, uint, uint, uint);
    function rulesByRace(uint _race) external view returns(uint,address,uint,uint,uint);
    function walletToAnchor(address _wal) external view returns(uint);
    function walletToCoach(address _wal) external view returns(uint);
    function walletToVC(address _wal) external view returns(uint);
}

interface CoachInterface {
    function boostCheck(uint cID, uint rID) external view returns(uint);
}

contract ElegantEngine is Ownable, Concatenate {
    using SafeMath for uint256;

    //peanuts
    address public tokenAddress = address(0xCAf44e62003De4B8bD17c724f2B78CC532550C2F); 
    IERC20 rewardToken = IERC20(tokenAddress);
    //Racers
    address public erc721Contract = address(0x72106Bbe2b447ECB9b52370Ddc63cfa8e553B08C);
    IERC721 stakeableNFT = IERC721(erc721Contract);
    address public accounts = 0x43BBB06C258279b791422Be1B5c66f6EB13D2f25;
    
    address public customAddress = 0x2953399124F0cBB46d2CbACD8A89cF0599974963;
    IERC1155 public customContract = IERC1155(customContract);

    address public stakingAddress = address(0);
    address public coachAddress = 0x71Ef0488d78ed490C8fFA3112Fb3D7B4614F76b5;
    address public coachIntAddress = 0xa1be14De29C3DedCac40dbEC96cEBcFaF75e33EE;

    address public tierAddress = 0x40e613Be9591A4ae1b60a2AAaB65235C2F9DEf1F;


    //data//
    uint deployT;
    uint public raceNum = 1;
    uint public currentRace = 0;
    uint public currentEvent = 0;

    uint firstL = 2250;
    uint secondL = 500;
    uint thirdL = 2250;

    struct performance{
        uint id;
        address nftContract;
        uint firstLeg;
        uint secondLeg;
        uint thirdLeg;
        uint steps;
        uint finishPos;
        uint eventWanted;
        uint raceIn;
    }

    //Required for race building in order to avoid
    //the stack too deep error
    struct racerTemp{
        uint tempID;
        address tempCon;
        uint tempEvent;
        address tempOwner;
        uint tempBoost;
        uint tempRID;
        uint newN;
        uint week;
    }

    struct rewardTemp{
        uint[] matic;
        uint[] pearls;
        uint[] points;
    }

    struct raceRules{
        uint gridSize;
        address conCheck;
        uint conValue;
        uint matPrice;
        uint prlPrice;     
    }

    struct boostTemp {
        uint boost;
        uint cBoost;
        uint coach;
        uint accel;
    }

    mapping(uint => raceRules) public rulesByRace;

    mapping(address => bool) public isTeamMember;
    
    //tierFilled[week][wallet][tier] = id
    mapping(uint => mapping(address => mapping(uint => uint))) public tierFilled;

    mapping(uint => mapping(address => uint)) public walletByScore;

    mapping(uint => mapping(uint => uint[])) public racersByRace; 

    //perfByRacer[week][racer].var
    mapping(uint => mapping(uint => performance)) public perfByRacer;

    mapping(uint => uint[]) public racersByEvent;

    mapping(uint => mapping(uint => uint)) public racesByEvent;

    mapping(address => mapping(uint => uint)) public slotByRacer;

    mapping(address => uint) public walletToID;

    mapping (address => uint) public walletToAnchor;
    mapping (address => uint) public walletToVC;
    mapping (address => uint) public walletToCoach;
    address[] public walletID;

    mapping(address => uint) public contractByType;

    uint public currentlyStaked;

    constructor() {
        deployT = block.timestamp;
        isTeamMember[msg.sender] = true;
    }


    // ADMIN //
    function teamUpdate(address to, bool member) public {
        require(isTeamMember[msg.sender] == true, "Caller is not a member of the team.");
        isTeamMember[to] = member;
    }

    function createEvent(uint _id, uint _size, address _conCheck, uint _conValue, uint _matP, uint _nutP) public {
        raceRules memory _rules;
        _rules.gridSize = _size;
        _rules.conCheck = _conCheck;
        _rules.conValue = _conValue;
        _rules.matPrice = _matP;
        _rules.prlPrice = _nutP;
        rulesByRace[_id] = _rules;
    }

    function setLegs(uint _first, uint _second, uint _third) public {
        require(isTeamMember[msg.sender] == true, "Caller is not a member of the team.");
        firstL = _first;
        secondL = _second;
        thirdL = _third;
    }

    function nextWeek() external {
        require(msg.sender == stakingAddress);
        raceNum = 1;
        currentRace = 0;
        currentEvent = 0;
    }

    function setCoachInfo(address _con) public onlyOwner {
        coachIntAddress = _con;
    }

    function newStaking(address _stake) public onlyOwner {
        stakingAddress = _stake;
    }

    function setCoach(uint _token) public {
        RacerInterface nft = RacerInterface(coachAddress);
        address _own = nft.ownerOf(_token);
        require(_own == msg.sender, "That coach isn't yours");
        walletToCoach[msg.sender] = _token;
    }

    function addRacers(address _sender, address _con, uint[] calldata _id, uint[] calldata _ev) external { 
        StakingInterface _staking = StakingInterface(stakingAddress);
        racerTemp memory _temp;

        uint _week = _staking.getWeek();
        uint _count = _id.length;

        for(uint i=0; i<_count; i++){
            bool ownership;
            _temp.tempID = _id[i];
            _temp.tempCon = _con;
            _temp.tempEvent = _ev[i];
            _temp.tempOwner = _sender;
            if (_temp.tempCon == erc721Contract){
                address _own = stakeableNFT.ownerOf(_temp.tempID);
                ownership = (_own == _temp.tempOwner);
            } else if (_temp.tempCon == customAddress) {
                uint v = customContract.balanceOf(_sender,_temp.tempID);
                ownership = (v > 0);
            }
        
            string memory _err;
            string memory _uid;
            _uid = Strings.toString(_temp.tempID);
            _err = concat("Following token does not belong to you: ",_uid);

            uint teehee;
            teehee = slotByRacer[_temp.tempCon][_temp.tempID];

            if (teehee == 0){
                teehee = currentlyStaked;
                currentlyStaked = currentlyStaked + 1;
                slotByRacer[_temp.tempCon][_temp.tempID] = teehee;
            }

            perfByRacer[_week][teehee].id = _temp.tempID;
            perfByRacer[_week][teehee].nftContract = _temp.tempCon;
            perfByRacer[_week][teehee].eventWanted = _temp.tempEvent;
            
            racersByEvent[_temp.tempEvent].push(teehee);            

            if (_temp.tempEvent > 0 && _temp.tempEvent < 18){
                uint takenBy = tierFilled[_week][_temp.tempOwner][_temp.tempEvent];
                if (takenBy != 0){
                    uint[] memory temp = new uint[](1);
                    temp[0] = takenBy;
                    returnTokens(temp);
                }
                tierFilled[_week][_temp.tempOwner][_temp.tempEvent] = teehee;
            }

            require(ownership == true, _err);
            bool answer = RulesInterface(rulesByRace[_temp.tempEvent].conCheck).tokenCheck(_id[i],rulesByRace[_temp.tempEvent].conValue,_temp.tempCon);
        }
    }

    function returnTokens(uint256[] memory _tokenID) public {
        StakingInterface _staking = StakingInterface(stakingAddress);
        uint _week = _staking.getWeek();
        uint[] memory _racers = _tokenID;
        for( uint i = 0; i < _racers.length; i ++ ) {
            uint _tok = _racers[i];
            performance storage staking = perfByRacer[_week][_tok];

            uint _tt = staking.id;
            uint _ev = staking.eventWanted;
            uint256[] storage eventNFTs = racersByEvent[_ev];
            address _owner = stakeableNFT.ownerOf(_tt);
            require(_owner == msg.sender, "One of those NFTs does not belong to you.");
            
            uint j = 0;
            if (eventNFTs.length > 0) {
            
                for(j; j< eventNFTs.length; j++){
                    if (eventNFTs[j] == _tok){
                        eventNFTs[j] = eventNFTs[(eventNFTs.length-1)];
                        eventNFTs.pop();
                        break;
                    }
                }
            
            }
            perfByRacer[_week][_tok].eventWanted = 100;
            //slotByRacer[_week][_tt] = 0;
            //staking.id = 0;
        }
    }

    function getOwnerStaked(address _owner) public view returns ( uint [] memory){
        StakingInterface _staking = StakingInterface(stakingAddress);
        uint _week = _staking.getWeek();
        uint[] memory ownersTokens = RacerInterface(erc721Contract).tokensOfOwner(_owner);
        uint[] memory ownersStaked = new uint[](ownersTokens.length);
        uint index;
        for ( uint i = 0; i < ownersTokens.length; i ++ ) {
            uint t = (ownersTokens[i]);
            uint _slot = slotByRacer[erc721Contract][t];
            uint _id = perfByRacer[_week][_slot].id;
            if (_id == t && perfByRacer[_week][_slot].eventWanted != 100 ){
                ownersStaked[index] = _id;
                index = index + 1;
            }
        }

        uint[] memory _return = new uint[](index);
        uint j;
        for(j; j < index; j++){
            _return[j] = ownersStaked[j];
        }

        return _return;
    }

    function getOwnerUnstaked(address _owner) public view returns ( uint [] memory){
        StakingInterface _staking = StakingInterface(stakingAddress);
        uint _week = _staking.getWeek();
        uint[] memory ownersTokens = RacerInterface(erc721Contract).tokensOfOwner(_owner);
        uint[] memory ownersUnstaked = new uint[](ownersTokens.length);
        uint index;
        
        for ( uint i = 0; i < ownersTokens.length; i ++ ) {
            uint t = (ownersTokens[i]);
            address oh;
            
            uint _slot = slotByRacer[erc721Contract][t];
            uint _id = perfByRacer[_week][_slot].id;
            if (_id != ownersTokens[i] || perfByRacer[_week][_slot].eventWanted == 100 ){
                ownersUnstaked[index] = ownersTokens[i];
                index = index + 1;
            }
        }
        uint[] memory _return = new uint[](index);
        uint j;
        for(j; j < index; j++){
            _return[j] = ownersUnstaked[j];
        }
        return _return;
    }

    function getOwnerStakedCount(address _owner) public view returns (uint){
        uint[] memory _temp = getOwnerStaked(_owner);
        uint _return = _temp.length;
        return _return;
    }

    function returnRacers(uint _week,uint _num) public view returns(uint[] memory){
        uint[] memory _racers = racersByRace[_week][_num];
        return _racers;
    }

    function returnSteps(uint first, uint second, uint third) public view returns(uint){
        uint _steps = 0;
        uint _rem = 0;
        
        _rem = firstL.mod(first);
        if (_rem > 0){_rem = 1;}               
        _steps = firstL.div(first) + _rem;

        _rem = secondL.mod(second);
        if (_rem > 0){_rem = 1;}              
        _steps = _steps + secondL.div(second) + _rem;

        _rem = thirdL.mod(third);
        if (_rem > 0){_rem = 1;}              
        _steps = _steps + thirdL.div(third) + _rem;

        return _steps;
    }

    function returnRacePos(uint _week, uint _num) public view returns(uint[] memory){
        StakingInterface _staking = StakingInterface(stakingAddress);
        
        uint[] memory _racers = racersByRace[_week][_num];
        uint _size = _racers.length;
        uint[] memory _steps  = new uint[](_size);
        uint[] memory positions = new uint[](_size);
        bool[] memory done = new bool[](_size);

        for (uint i=0; i<_size; i++){
            uint _rc = _racers[i];
            uint first = perfByRacer[_week][_rc].firstLeg;
            uint second = perfByRacer[_week][_rc].secondLeg;
            uint third = perfByRacer[_week][_rc].thirdLeg;
            _steps[i] = returnSteps(first, second, third);
        }

        uint _gogo;
        uint _c;
        for (uint j=0; j<_size; j++){
            _gogo = 0;
            _c = 500;
            for (uint h=0; h<_size; h++){
                if (_steps[h] < _c && done[h] == false){
                    _gogo = h;
                    _c = _steps[h];
                }
            }
            positions[j] = _gogo;
            done[_gogo] = true;
            
        }

        return positions;
    }

    function nextRace() public {
        StakingInterface _staking = StakingInterface(stakingAddress);
        uint _week = _staking.getWeek();
        require(isTeamMember[msg.sender] == true, "Caller is not a member of the team.");
        
        if (currentRace < (raceNum-1)){
            currentRace = currentRace + 1;
            rewardTemp memory _temp;

            uint _ev = racesByEvent[_week][currentRace];

            uint[] memory positions = returnRacePos(_week,currentRace);
            uint[] memory _racers = returnRacers(_week,currentRace);
            address _con = rulesByRace[_ev].conCheck;
            RulesInterface _rules = RulesInterface(_con);

            _temp.matic = _rules.prizeCheck();
            _temp.pearls = _rules.nutPrizeCheck();
            _temp.points = _rules.scoreCheck();
            

            uint i = 0;
            for (i; i < positions.length; i ++){ 
                uint _lane = positions[i];
                uint _tok = _racers[_lane];
                uint payOut = ( _temp.matic[i] );
                uint payNut = ( _temp.pearls[i] );
                address winner;
                uint _token = perfByRacer[_week][_tok].id;
                winner = stakeableNFT.ownerOf(_token);

                _staking.addScore(winner,_temp.points[i]);
                if (payOut > 0){
                    (bool success, ) = (winner).call{value: payOut}("");
                    require(success, "Transfer failed.");
                }
                if (payNut > 0){
                    rewardToken.transfer(winner, payNut);
                }
                
            }

        }
    }

    function nextFew(uint amount) public {
        require(isTeamMember[msg.sender] == true, "Caller is not a member of the team.");
        uint i = 0;
        for(i; i<amount; i++){
            nextRace();
        }
    }

    function build(uint _amount, uint _event) public {
        require(isTeamMember[msg.sender] == true, "Caller is not a member of the team.");
        for (uint i=0; i<_amount; i++){
            buildRace(_event);
        }
    }

    function getSpeedBoost(uint _id, bool _ext) public view returns(uint) {
        StakingInterface _staking = StakingInterface(stakingAddress);
        uint _week = _staking.getWeek();
        address ruleBook = rulesByRace[1].conCheck;
        RulesInterface _rules = RulesInterface(tierAddress);

        address _con = 0x72106Bbe2b447ECB9b52370Ddc63cfa8e553B08C;
        uint _tokenID = _id;
        if (_ext == false) {
            _tokenID = perfByRacer[_week][_id].id;
        }
         
        
        uint _boost = 5; 

        return _boost;
        
    }

    function getAccelBoost(uint _id, bool _ext) public view returns(uint) {
        StakingInterface _staking = StakingInterface(stakingAddress);
        uint _week = _staking.getWeek();
        address ruleBook = rulesByRace[1].conCheck;
        RulesInterface _rules = RulesInterface(tierAddress);

        address _con = 0x72106Bbe2b447ECB9b52370Ddc63cfa8e553B08C;
        uint _tokenID = _id;
        if (_ext == false) {
            _tokenID = perfByRacer[_week][_id].id;
        }
        uint _boost;
        uint i = 1;
        for (i; i <= 18; i ++){
            bool isBoosted = _rules.tokenCheck(_tokenID,i,_con);
            if (isBoosted == true){
                
                if (i == 2 || i == 5 || i == 8 || i == 11  || i == 14 || i == 16){
                    _boost += 1;
                } else if (i == 3 || i == 6 || i == 9 || i == 12 || i == 15 || i == 17 || i == 18){
                    _boost += 2;
                }
                
            }
        }

        return _boost;
        
    }
    
    function buildRace(uint _event) internal {
        CoachInterface _coach = CoachInterface(coachIntAddress);
        
        require(isTeamMember[msg.sender] == true, "Caller is not a member of the team.");
        
        racerTemp memory _temp;
        boostTemp memory boosts;
        uint _nonce = block.timestamp.sub(deployT);

        StakingInterface _staking = StakingInterface(stakingAddress);
        _temp.week = _staking.getWeek();

        uint i = 0;
        uint total = racersByEvent[_event].length;
        
        uint racing = 0;
        uint rMax = rulesByRace[_event].gridSize;
        if (total >= rMax){
            racing = rMax;
        } else {
            racing = total;
        }

        for(i; i<racing; i++){ //go through every racer
            uint _r = randomNumber(_nonce, 0, (racersByEvent[_event].length));
            
            _temp.tempID = racersByEvent[_event][_r];
            _temp.tempRID = perfByRacer[_temp.week][_temp.tempID].id;
            racersByRace[_temp.week][raceNum].push(_temp.tempID);   
            
            _temp.tempOwner = stakeableNFT.ownerOf(_temp.tempRID);
            boosts.coach = walletToCoach[_temp.tempOwner];
            boosts.boost = getSpeedBoost(_temp.tempID,false);
            if (boosts.coach != 0){
                boosts.cBoost = _coach.boostCheck(boosts.coach, _temp.tempRID);
            }
            
            boosts.boost = boosts.boost + boosts.cBoost;
            boosts.accel = getAccelBoost(_temp.tempID,false);
            
            _nonce = _nonce + racersByEvent[_event].length;            
            _temp.newN = randomNumber(_nonce, 5, 12);           
            perfByRacer[_temp.week][_temp.tempID].firstLeg = _temp.newN + boosts.boost + boosts.accel;
            
            _nonce = _nonce + 1;
            _temp.newN = randomNumber(_nonce, 5, 12);  
            perfByRacer[_temp.week][_temp.tempID].secondLeg = _temp.newN + boosts.boost;
            
            _nonce = _nonce + 1;
            _temp.newN = randomNumber(_nonce, 8, 14);  
            perfByRacer[_temp.week][_temp.tempID].thirdLeg = _temp.newN + boosts.boost;


            perfByRacer[_temp.week][_temp.tempID].steps = returnSteps(perfByRacer[_temp.week][_temp.tempID].firstLeg,perfByRacer[_temp.week][_temp.tempID].secondLeg,perfByRacer[_temp.week][_temp.tempID].thirdLeg);
            perfByRacer[_temp.week][_temp.tempID].raceIn = raceNum;
            uint lMinus = (racersByEvent[_event].length - 1);
            racersByEvent[_event][_r] = racersByEvent[_event][lMinus];
            racersByEvent[_event].pop();

        }

        racesByEvent[_temp.week][raceNum] = _event;
        raceNum = raceNum.add(1);
        
    }

    // DEBUG AND MANAGEMENT //
    fallback() external payable {}

    receive() external payable {
    }

    function randomNumber(uint _nonce, uint _start, uint _end) private view returns (uint){
        uint _far = _end.sub(_start);
        uint random = uint(keccak256(abi.encodePacked(deployT, msg.sender, _nonce))).mod(_far);
        random = random.add(_start);
        return random;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.0;
contract Concatenate {
    function concat(string memory a,string memory b) public pure returns (string memory){
        return string(bytes.concat(bytes(a), "", bytes(b)));
    } 
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}