//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface RaceInterface{
    function returnRacePos(uint256 _race) external view returns(uint[] memory);
    function returnRacers(uint256 _race) external view returns(uint[] memory);
    function currentRace() external view returns (uint);
    function perfByRacer(uint _id) external view returns(uint,uint,address,uint,uint,uint,uint,uint,uint);
}

contract SharkRacing is Ownable {
    using SafeMath for uint256;

    uint deployT;

    uint[] public scorePrizes = new uint[](10);

    struct performance{
        uint id;
        address user;
        uint firstLeg;
        uint secondLeg;
        uint steps;
        uint raceIn;
    }

    mapping(uint => uint[]) public pointsPerRace;
    mapping(uint => performance) public perfByRacer;
    mapping(address => bool) public teamMembers;
    //mapping each race id to the racers
    mapping(uint => uint[]) public racersByRace; 

    uint[] public racers;
    uint[] public racing;

    address public signUp = 0x8FBaD3f428a87543a0C73B0a8eF84dcfD74af9ee;
    
    RaceInterface _OLD = RaceInterface(signUp);

    uint currentRace = 0;
    uint raceNum = 1;

    constructor() {
        racers.push(0);
        deployT = block.timestamp;
        scorePrizes[0] = 25;
        scorePrizes[1] = 20;
        scorePrizes[2] = 16;
        scorePrizes[3] = 12;
        scorePrizes[4] = 10;
        scorePrizes[5] = 7;
        scorePrizes[6] = 5;
        scorePrizes[7] = 3;
        scorePrizes[8] = 1;

        teamMembers[msg.sender] == true;
    }

    uint cDay = 1;

    function grabRacers(uint start, uint end) public onlyOwner {
        uint i = start;
        for( i; i < end; i ++ ) {
            (uint _id, uint _type, address _con, uint _leg1, uint _leg2, uint _steps, uint _pos, uint _event, uint _race) = _OLD.perfByRacer(i);
            racers.push(_id);
        }
    }

    function getWinnersOLD() public onlyOwner {
        uint i = 1;
        for( i; i < 79; i ++ ) {
            uint[] memory _racers = _OLD.returnRacers(i);
            uint[] memory _pos = _OLD.returnRacePos(i);
            uint j = 1;
            for ( j; j < _pos.length; j ++ ) {
                uint _sc;
                _sc = scorePrizes[j];
                uint _ra;
                _ra = _racers[(_pos[j])];
                pointsPerRace[_ra][0] = _sc;
            }
        }
    }

    function getWinners() public onlyOwner {
        uint i = 1;
        for( i; i < 79; i ++ ) {
            uint[] memory _racers = returnRacers(i);
            uint[] memory _pos = returnRacePos(i);
            uint j = 1;
            for ( j; j < _pos.length; j ++ ) {
                uint _sc;
                _sc = scorePrizes[j];
                uint _ra;
                _ra = _racers[(_pos[j])];
                pointsPerRace[_ra][cDay] = _sc;
            }
        }
    }

    function reloadRacers(uint start, uint end) public onlyOwner {
        uint i = start;
        for( i; i < end; i ++ ) {
            racing.push(i);
        }
    }

    function nextDay() public onlyOwner {
        cDay += 1;
    }
    
    //  //
    
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
        uint _rem = 0;
        uint fHundo = 500;
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
        require(teamMembers[msg.sender] == true, "Caller is not a member of the team.");
            currentRace = currentRace + 1;    
    }

    function buildRace() public {
        require(teamMembers[msg.sender] == true, "Caller is not a member of the team.");
        
        uint i = 0;
        uint total = racing.length;
        
        uint _racing = 0;
        uint rMax = 10;
        if (total >= rMax){
            _racing = rMax;
        } else {
            _racing = total;
        }
        for(i; i<_racing; i++){ //go through every racer
            uint rNonce = block.timestamp.sub(deployT)+i;
            uint _r = randomNumber(rNonce, 0, (racing.length));
            uint _racer = racing[_r];

            racersByRace[raceNum].push(_racer);   
            
            uint _nonce = block.timestamp.sub(deployT)+racing.length;
            
            perfByRacer[_racer].firstLeg = randomNumber(_nonce, 4, 11);
            _nonce = _nonce + 1;
            perfByRacer[_racer].secondLeg = randomNumber(_nonce, 6, 13);
            perfByRacer[_racer].steps = returnSteps(perfByRacer[_racer].firstLeg,perfByRacer[_racer].secondLeg);
            perfByRacer[_racer].raceIn = raceNum;
            
            racing[_r] = racing[(racing.length - 1)];
            racing.pop();
        }
        
        raceNum = raceNum.add(1);
   
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