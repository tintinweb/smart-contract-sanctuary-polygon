//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../concatenate.sol";

interface RulesInterface{
    function tokenCheck (uint id, uint valToCheck) external view returns (bool);
    function prizeCheck () external view returns (uint[] calldata);
    function nutPrizeCheck () external view returns (uint[] calldata);
}

interface RacerInterface {
    function tokensOfOwner(address _owner) external view returns (uint[] memory);
}



contract ElegantStaking is Ownable, AccessControl, Concatenate {
    using SafeMath for uint256;

    //peanuts
    address public tokenAddress = address(0x56C025A10C5F28611fbF6AAfd225Be702B335289); 
    IERC20 rewardToken = IERC20(tokenAddress);
    //Racers
    address public erc721Contract = address(0x72106Bbe2b447ECB9b52370Ddc63cfa8e553B08C);
    IERC721 stakeableNFT = IERC721(erc721Contract);

    uint deployT;

    //data//
    uint public raceNum = 1;
    uint public currentRace = 0;
    uint public currentEvent = 0;

    struct performance{
        uint id;
        uint contractType;
        address nftContract;
        uint firstLeg;
        uint secondLeg;
        uint steps;
        uint finishPos;
        uint eventWanted;
        uint raceIn;
    }

    struct raceRules{
        uint gridSize;
        address conCheck;
        uint conValue;
        uint pointsGiven;
        uint matPrice;
        uint nutPrice;
        uint devMat;
        uint refNut;       
    }

    uint public _week = 0;
    mapping(uint => mapping(address => uint)) public walletByScore;

    mapping(address => uint[])  public nftByOwner;

    mapping(uint => uint[]) public racersByRace; 

    mapping(uint => performance) public perfByRacer;

    mapping(uint => raceRules) public rulesByRace;

    mapping(uint => uint[]) public racersByEvent;

    mapping(uint => uint) public racesByEvent;

    mapping(uint => uint) public slotByRacer;

    uint[] public currentlyStaked;

    //team addresses go here//
    struct theTeam {
        bool member;
        uint maticEarned;
        uint maticTaken;
        uint nutsEarned;
        uint nutsTaken;
    }

    bool public paused;
    mapping(address => theTeam) public teamInfo;
    uint256 public totalEarned = 0;
    uint256 public nutsToRef = 0;

    bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(TEAM_ROLE, msg.sender);
        deployT = block.timestamp;
        teamInfo[msg.sender].member = true;
        teamInfo[0x3e3F56c7C4873A4516b78FE989e9f8be18968a38].member = true;
        currentlyStaked.push(1);
    }

    // ADMIN //
    function teamUpdate(address to, bool _member, uint _perc, uint _nutperc) public {
        require(teamInfo[msg.sender].member == true, "Caller is not a member of the team.");
        teamInfo[to].member = _member;
    }

    function createEvent(uint _id, uint _size, address _conCheck, uint _conValue,uint _points, uint _matP, uint _nutP, uint _dev, uint _ref) public {
        raceRules memory _rules;
        _rules.gridSize = _size;
        _rules.conCheck = _conCheck;
        _rules.conValue = _conValue;
        _rules.pointsGiven = _points;
        _rules.matPrice = _matP;
        _rules.nutPrice = _nutP;
        _rules.devMat = _dev;
        _rules.refNut = _ref;
        rulesByRace[_id] = _rules;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    // STORAGE AND RACE MANAGEMENT //
    function addRacer(uint _tokenID, uint _event) internal { 
        address _own = stakeableNFT.ownerOf(_tokenID);
        string memory _err;
        string memory _uid;
        _uid = Strings.toString(_tokenID);
        _err = concat("Following token does not belong to you: ",_uid);
        uint teehee = currentlyStaked.length;

        nftByOwner[msg.sender].push(teehee);
        perfByRacer[teehee].id = _tokenID;
        //perfByRacer[teehee].user = msg.sender; 
        perfByRacer[teehee].eventWanted = _event;
        currentlyStaked.push(teehee);
        racersByEvent[_event].push(teehee);
        slotByRacer[_tokenID] = teehee;

        require(!paused, "Racing is currently not open.");
        require(_own == msg.sender, _err);
    }

    function signUp (uint[] calldata _racers, uint _event) public payable{
        uint _count = _racers.length;
        uint money = _count.mul(rulesByRace[_event].matPrice);
        uint nutso = _count.mul(rulesByRace[_event].nutPrice);
        
        require(msg.value >= money, "Not enough matic to race that many.");
        require(rewardToken.balanceOf(msg.sender) >= nutso, "You don't have enough Peanuts for that.");
        require(rewardToken.transferFrom(msg.sender, address(this), nutso), "You need to allow transfer of Peanuts.");
        for(uint i=0; i<_count; i++){
            addRacer(_racers[i], _event);
            if (rulesByRace[_event].conCheck != address(0)){
                bool answer = RulesInterface(rulesByRace[_event].conCheck).tokenCheck(_racers[i],rulesByRace[_event].conValue);
                require(answer == true, "At least one chosen token does not meet the event requirements.");
            }
        }
        uint moolah = money.mul(rulesByRace[_event].devMat).div(100);
        uint nards = nutso.mul(rulesByRace[_event].refNut).div(100);

        teamInfo[0x84C06895E37A0c5CdB2196D204d7EF8eA0a4fF4F].maticEarned = teamInfo[0x84C06895E37A0c5CdB2196D204d7EF8eA0a4fF4F].maticEarned.add(moolah);
        teamInfo[0x3e3F56c7C4873A4516b78FE989e9f8be18968a38].nutsEarned = teamInfo[0x3e3F56c7C4873A4516b78FE989e9f8be18968a38].nutsEarned.add(nards);
    }

    function onERC721Received(address _op, address _from, uint256 _token, bytes memory) public virtual returns (bytes4) {
        //require((msg.sender == erc721Contract),"Contract not recognised!");
        require(!paused, "the contract is paused");

        return this.onERC721Received.selector;
    }

    function getOwnerStaked(address _owner) public view returns ( uint [] memory){
        uint[] memory ownersTokens = RacerInterface(erc721Contract).tokensOfOwner(_owner);
        uint[] memory ownersStaked = new uint[](ownersTokens.length);
        uint index;
        for ( uint i = 0; i < ownersTokens.length; i ++ ) {
            uint t = (ownersTokens[i]);
            uint _slot = slotByRacer[t];
            uint _id = perfByRacer[_slot].id;
            if (_id == t){
                ownersStaked[index] = _id;
                index = index + 1;
            }
        }
        return ownersStaked;
    }

    function getOwnerUnstaked(address _owner) public view returns ( uint [] memory){
        uint[] memory ownersTokens = RacerInterface(erc721Contract).tokensOfOwner(_owner);
        uint[] memory ownersUnstaked = new uint[](ownersTokens.length);
        uint index;
        for ( uint i = 0; i < ownersTokens.length; i ++ ) {
            uint _slot = slotByRacer[ownersTokens[i]];
            uint _id = perfByRacer[_slot].id;
            if (_id != ownersTokens[i]){
                ownersUnstaked[index] = ownersTokens[i];
                index = index + 1;
            }
        }
        return ownersUnstaked;
    }


    function returnRacers(uint _num) public view returns(uint[] memory){
        uint[] memory _racers = racersByRace[_num];
        return _racers;
    }

    function returnSteps(uint first, uint second) public view returns(uint){
        uint _steps = 0;
        uint _rem = 0;
        uint fHundo = 500;
        
        _rem = fHundo.mod(first);
        if (_rem > 0){_rem = 1;}
                
        _steps = fHundo.div(first) + _rem;
        _rem = fHundo.mod(second);
        if (_rem > 0){_rem = 1;}
                
        _steps = _steps + fHundo.div(second) + _rem;

        return _steps;
    }

    function getSteps(uint _id) public view returns(uint){
        uint _steps;
        _steps = perfByRacer[_id].steps;
        return _steps;
    }

    function getRaceSize(uint _num) public view returns(uint){
        uint[] memory _racers = racersByRace[_num];
        uint _size = _racers.length;
        return _size;
    }

    function returnRace(uint _num) public view returns(uint[] memory){
        uint[] memory _racers = racersByRace[_num];
        uint _size = _racers.length;
        uint[] memory _steps  = new uint[](_size);
        uint i;
        for (i = 0; i < _size; i ++ ) {              
            _steps[i] = getSteps(_racers[i]);
        }

        return _steps; 
    }

    function returnRacePos(uint _num) public view returns(uint[] memory){
        
        uint[] memory _racers = racersByRace[_num];
        uint _size = _racers.length;
        uint[] memory _steps  = new uint[](_size);
        uint[] memory positions = new uint[](_size);
        bool[] memory done = new bool[](_size);

        for (uint i=0; i<_size; i++){
            uint _rc = _racers[i];
            uint first = perfByRacer[_rc].firstLeg;
            uint second = perfByRacer[_rc].secondLeg;
            _steps[i] = returnSteps(first, second);
        }
        
        //run through all finish positions
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
        require(hasRole(TEAM_ROLE, msg.sender), "Caller is not a member of the team.");
        
        if (currentRace < (raceNum-1)){
            currentRace = currentRace + 1;

            uint _ev = racesByEvent[currentRace];
            uint[] memory positions = returnRacePos(currentRace);
            uint[] memory _racers = returnRacers(currentRace);
            address _con = rulesByRace[_ev].conCheck;
            RulesInterface _rules = RulesInterface(_con);
            uint[] memory prizes = _rules.prizeCheck();
            uint[] memory nutses = _rules.nutPrizeCheck();

            uint i = 0;
            for (i; i < positions.length; i ++){ 
                uint _lane = positions[i];
                uint _tok = _racers[_lane];
                uint payOut = ( prizes[i] / 100 * (rulesByRace[_ev].matPrice * positions.length) );
                uint payNut = ( nutses[i] / 100 * (rulesByRace[_ev].nutPrice * positions.length) );
                address winner;
                uint _token = perfByRacer[_tok].id;
                winner = stakeableNFT.ownerOf(_token);
                if (i == 0) {
                    walletByScore[_week][winner] = walletByScore[_week][winner] + rulesByRace[_ev].pointsGiven;
                }
                if (payOut > 0){
                    (bool success, ) = (winner).call{value: payOut}("");
                    require(success, "Transfer failed.");
                }
                if (payNut > 0){
                    require(rewardToken.transfer(winner, payNut));
                }
                
            }

        }
    }

    function build(uint _amount, uint _event) public {
        require(hasRole(TEAM_ROLE, msg.sender), "Caller is not a member of the team.");
        for (uint i=0; i<_amount; i++){
            buildRace(_event);
        }
    }

    function buildRace(uint _event) internal {
        require(hasRole(TEAM_ROLE, msg.sender), "Caller is not a member of the team.");
        
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
            uint rNonce = block.timestamp.sub(deployT)+i;
            uint _r = randomNumber(rNonce, 0, (racersByEvent[_event].length));
            uint _racer = racersByEvent[_event][_r];

            racersByRace[raceNum].push(_racer);   
            
            uint _nonce = block.timestamp.sub(deployT)+racersByEvent[_event].length;
            
            perfByRacer[_racer].firstLeg = randomNumber(_nonce, 4, 11);
            _nonce = _nonce + 1;
            perfByRacer[_racer].secondLeg = randomNumber(_nonce, 6, 13);
            perfByRacer[_racer].steps = returnSteps(perfByRacer[_racer].firstLeg,perfByRacer[_racer].secondLeg);
            perfByRacer[_racer].raceIn = raceNum;
            
            racersByEvent[_event][_r] = racersByEvent[_event][(racersByEvent[_event].length - 1)];
            racersByEvent[_event].pop();
        }
        racesByEvent[raceNum] = _event;
        raceNum = raceNum.add(1);
  
    }

    function nextWeek() public {
        require(hasRole(TEAM_ROLE, msg.sender), "Caller is not a member of the team.");
        _week = _week + 1;
    }

    function returnTokens(uint256[] calldata _tokenID) public {
        uint[] memory _racers = _tokenID;
        for( uint i = 0; i < _racers.length; i ++ ) {
            uint _tok = slotByRacer[_racers[i]];
            performance storage staking = perfByRacer[_tok];

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

            staking.id = 0;
        }
    }
    
    


    function withdraw() public {
        require(teamInfo[msg.sender].member == true, "Caller is not a member of the team.");
        uint _mat = 0;
        uint _nut = 0;
        _mat = teamInfo[msg.sender].maticEarned.sub(teamInfo[msg.sender].maticTaken);
        _nut = teamInfo[msg.sender].nutsEarned.sub(teamInfo[msg.sender].nutsTaken);
        teamInfo[msg.sender].maticTaken = _mat;
        teamInfo[msg.sender].nutsTaken = _nut;
  
        if (_mat > 0){
            (bool success, ) = (msg.sender).call{value: _mat}("");
            require(success, "Transfer failed.");
        }
        if (_nut > 0){
            require(rewardToken.transfer(msg.sender, _nut));
        }
    }

    function emergencyWithdraw() public onlyOwner {
        (bool success, ) = (msg.sender).call{value: address(this).balance}("");
            require(success, "Transfer failed.");

            uint _nut = rewardToken.balanceOf(address(this));
            require(rewardToken.transfer(msg.sender, _nut));
    }
    
    function randomNumber(uint _nonce, uint _start, uint _end) private view returns (uint){
        uint _far = _end.sub(_start);
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _nonce))).mod(_far);
        random = random.add(_start);
        return random;
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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