pragma solidity ^0.8.0;

import "SafeMath.sol";
import "IERC20.sol";
using SafeMath for uint256;

contract PirateRace {
    struct Team {
        uint256 totalMoney;
        string teamName;
        uint256 speed;
        uint256 distance;
        uint256 defense;
        uint256 attack;
        uint256 numPirates;
    }

    struct Contribution {
        uint256 money;
        uint256 actions;
    }

    address public owner;
    string public winner= "";
    uint256 public finishLine = 1e6;
    bool gameStarted = false;
    IERC20 public Qi = IERC20(0x580A84C73811E1839F75d86d75d88cCa0c241fF4);
    IERC20 public eQi = IERC20(0x880DeCADe22aD9c58A8A4202EF143c4F305100B3);
    uint256 private lastUpdated;
    Team[] public teams;

    mapping (address => uint256) public userToTeam;
    mapping (address => bool) public jail;
    mapping (address => Contribution) public userScore;
    mapping (uint256 => address) public captain;
    mapping (uint256 => address) public firstMate;

    constructor() public {
        owner = msg.sender;
        teams.push(Team({totalMoney: 0, teamName:"Team Ben", speed:0, distance:0, defense:0, attack:0, numPirates:0}));
        teams.push(Team({totalMoney: 0, teamName:"Team Kila", speed:0, distance:0, defense:0, attack:0, numPirates:0}));
        teams.push(Team({totalMoney: 0, teamName:"Team Nacho", speed:0, distance:0, defense:0, attack:0, numPirates:0}));
        teams.push(Team({totalMoney: 0, teamName:"Team ??", speed:0, distance:0, defense:0, attack:0, numPirates:0}));
        lastUpdated = block.timestamp;
    }

    // owner functions
    function startRace() public {
        require(msg.sender == owner, "Only the owner can start the race.");
        require(!gameStarted, "Game already started.");
        gameStarted = true;
        for (uint256 i = 0; i < teams.length; i++) {
            teams[i].speed = 1;
        }
        lastUpdated = block.timestamp;
    }

    function nameTeam(uint256 teamId, string memory teamName) public {
        require(msg.sender == owner, "Only the owner can name the teams.");
        teams[teamId].teamName = teamName;
    }

    function changeSettings(uint256 _teamId, uint256 _money, uint256 _speed, uint256 _distance, uint256 _defense, uint256 _attack) public {
        require(msg.sender == owner, "Only owner.");
        if (_money != 0)    teams[_teamId].totalMoney = _money;
        if (_speed != 0)    teams[_teamId].speed = _speed;
        if (_distance != 0) teams[_teamId].distance = _distance;
        if (_defense != 0)  teams[_teamId].defense = _defense;
        if (_attack != 0)   teams[_teamId].attack = _attack;
    }

    // player functions
    function join(uint256 teamId) public {
        require(teamId < teams.length, "Invalid team ID.");
        uint256 money = Qi.balanceOf(msg.sender)/1e18 + eQi.balanceOf(msg.sender)/1e18;
        require(money >= 100, "Requires at least 100 Qi + eQi to play.");

        teams[teamId].totalMoney += money;
        teams[teamId].numPirates += 1;
        userToTeam[msg.sender] = teamId;
        userScore[msg.sender].money = money;
        emit TeamJoin(msg.sender, teams[teamId].teamName, money);
    }

    function pickCaptain(uint256 teamId, address user) public {
        require(msg.sender == owner, "Only the owner can pick captains.");
        captain[userToTeam[user]] = user;
    }

    function pickFirstMate(address user) public isCaptain{
        require(userToTeam[msg.sender] == userToTeam[user], "First mate must be on your team.");
        firstMate[userToTeam[user]] = user;
        emit FirstMate (teams[userToTeam[msg.sender]].teamName, user);
    }

    // update the distance for each team
    function updateDistance() public isGameStarted {
        for (uint256 i = 0; i < teams.length; i++) {
            uint256 timePassed = block.timestamp - lastUpdated;
            teams[i].distance += teams[i].speed * timePassed;
            if (teams[i].distance >= finishLine && bytes(winner).length == 0) {
                winner = teams[i].teamName;
            }
        }
        lastUpdated = block.timestamp;
        emit DistanceUpdated(teams[0].distance, teams[1].distance, teams[2].distance, teams[3].distance);
    }

    function upgradeEngine() public isGameStarted notInJail {
        uint256 teamId = userToTeam[msg.sender];
        require(teams[teamId].totalMoney >= 1, "Not enough money to upgrade engine.");
        
        teams[teamId].totalMoney = teams[teamId].totalMoney.sub(1);
        teams[teamId].speed = teams[teamId].speed.add(1);
        
        userScore[msg.sender].actions += 1;
        updateDistance();
        emit EngineUpgraded(msg.sender, teams[teamId].teamName);
    }

    function upgradeDefense() public isGameStarted notInJail {
        uint256 teamId = userToTeam[msg.sender];
        require(teams[teamId].totalMoney >= 1, "Not enough money to upgrade defense.");
        
        teams[teamId].totalMoney = teams[teamId].totalMoney.sub(1);
        teams[teamId].defense = teams[teamId].defense.add(1);
        
        userScore[msg.sender].actions += 1;
        updateDistance();
        emit DefenseUpgraded(msg.sender, teams[teamId].teamName);
    }

    function upgradeAttack() public isGameStarted notInJail {
        uint256 teamId = userToTeam[msg.sender];
        require(teams[teamId].totalMoney >= 1, "Not enough money to upgrade attack.");
        
        teams[teamId].totalMoney = teams[teamId].totalMoney.sub(1);
        teams[teamId].attack = teams[teamId].attack.add(1);
        
        userScore[msg.sender].actions += 1;
        updateDistance();
        emit AttackUpgraded(msg.sender, teams[teamId].teamName);
    }

    function fireCannon(uint256 targetTeam) public isGameStarted notInJail {
        require(targetTeam < teams.length, "Invalid target team.");
        require(targetTeam != userToTeam[msg.sender], "Cannot fire at own team.");
        
        uint256 teamId = userToTeam[msg.sender];
        bool hit = false;
        uint256 hitChance = 33; 
        
        if(hitChance + teams[teamId].attack < teams[targetTeam].defense) hitChance = 1; //overflow, min hitrate, 1%
        else hitChance = 33 + teams[teamId].attack - teams[targetTeam].defense; //default chance 33% + att - def
        if(hitChance > 99) hitChance = 99; //max hitrate, 99%
        
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100;

        if (random < hitChance) {
            teams[targetTeam].distance = teams[targetTeam].distance.mul(98).div(100); //2% distance loss
            if (teams[targetTeam].speed > 3) teams[targetTeam].speed = teams[targetTeam].speed.sub(2); //2 speed loss
            hit = true;
        }
        
        userScore[msg.sender].actions += 1;
        updateDistance();
        emit CannonFired(msg.sender, teams[teamId].teamName, teams[targetTeam].teamName, hit);
    }

    function buyMysteryBox() public isGameStarted notInJail {
        uint256 teamId = userToTeam[msg.sender];
        require(teams[teamId].totalMoney >= 5, "Not enough money to buy a mystery box.");
        teams[teamId].totalMoney -= 5;
        
        uint256 result = 0;
        uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100;
        
        if (randomNum < 50) {
            // nothing happens
        } else if (randomNum < 65) { // more money
            teams[teamId].totalMoney += 200;
            result = 1;
        } else if (randomNum < 85) { // ship upgrades
            teams[teamId].speed += 2;
            teams[teamId].defense += 2;
            teams[teamId].attack += 2;
            result = 2;
        } else { // kraken attacked everybody!
            for (uint256 i = 0; i < teams.length; i++)
                teams[i].distance = teams[i].distance.mul(90).div(100); //10% distance loss
            result = 3;
        }
        
        userScore[msg.sender].actions += 1;
        updateDistance();
        emit MysteryBox(msg.sender, teams[teamId].teamName, result);
    }

    function putInJail(address user) public isCaptainOrFirstMate {
        require(userToTeam[msg.sender] == userToTeam[user], "Cannot put someone on another team in jail.");
        jail[user] = true;
        emit InJail(user, teams[userToTeam[user]].teamName);
    }

    function takeOutOfJail(address user) public isCaptainOrFirstMate {
        require(userToTeam[msg.sender] == userToTeam[user], "Cannot take someone on another team out of jail.");
        jail[user] = false;
        emit OutofJail(user, teams[userToTeam[user]].teamName);
    }

    function checkForgedPapers(address user) public {
        require(!jail[user], "already in jail");
        uint256 currentMoney = Qi.balanceOf(user)/1e18 + eQi.balanceOf(user)/1e18;
        uint256 originalMoney = userScore[user].money;
        uint256 teamId = userToTeam[user];

        if (currentMoney < originalMoney*9/10) {
            jail[user] = true;
            if (teams[teamId].totalMoney > originalMoney * 2) //penalty
                teams[teamId].totalMoney -= originalMoney * 2;
            else {
                teams[teamId].totalMoney = 0;
            }

            emit InJail(user, teams[userToTeam[user]].teamName);
        } 
    }

    modifier isGameStarted() {
        require(gameStarted, "The game has not started yet.");
        _;
    }

    modifier isCaptain() {
        require(captain[userToTeam[msg.sender]] == msg.sender, "Only the captain can do this.");
        _;
    }

    modifier isCaptainOrFirstMate() {
        require(captain[userToTeam[msg.sender]] == msg.sender || firstMate[userToTeam[msg.sender]] == msg.sender, "Only the captain or first mate can do this.");
        _;
    }

    modifier notInJail() {
        require(!jail[msg.sender], "This user is in jail.");
        _;
    }

    event TeamJoin(address user, string teamName, uint256 money);
    event DistanceUpdated(uint256 team0, uint256 team1, uint256 team2, uint256 team3);
    event EngineUpgraded(address user, string teamName);
    event DefenseUpgraded(address user, string teamName);
    event AttackUpgraded(address user, string teamName);
    event CannonFired(address user, string shooter, string target, bool hit);
    event InJail(address user, string teamName);    
    event OutofJail(address user, string teamName);
    event MysteryBox(address user, string teamName, uint256 result);
    event FirstMate (string teamName, address user);

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