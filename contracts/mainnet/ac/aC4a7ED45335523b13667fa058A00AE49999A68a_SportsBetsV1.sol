// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "AggregatorV3Interface.sol";
import "Ownable.sol";
import "AccessControl.sol";

contract SportsBetsV1 is Ownable,AccessControl{
  // Create an admin role identifier
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  // Start taking bets time.
  uint256 public startTime;
  // Start of the match time.
  uint256 public matchStart;
  // Start of the match time.
  uint256 public matchEnd;
  // Contestants:
  string public team1;
  string public team2;
  // Scores:
  uint256 public team1Score;
  uint256 public team2Score;
  // Bet name.
  string public name;
  // Bet description.
  string public description;
  // Array of all players betting on team 1.
  address payable[] public playersBetOnTeam1;
  // Amounts payed by each player.
  uint256[] public playersBetOnTeam1PayedAmount;
  // Total amount bet on team 1.
  uint256 public amountBetOnTeam1;
  // Array of all players betting against.
  address payable[] public playersBetOnTeam2;
  // Amounts payed by each player.
  uint256[] public playersBetOnTeam2PayedAmount;
  // Total amount bet against.
  uint256 public amountBetOnTeam2;
  // Array of all players betting on draw.
  address payable[] public playersBetOnDraw;
  // Amounts payed by each player.
  uint256[] public playersBetOnDrawPayedAmount;
  // Total amount bet on draw.
  uint256 public amountBetOnDraw;
  // Array of all players who won previous bet.
  address payable[] public recentWinners;
  // Array of money payed to players who won previous bet.
  uint256[] public recentWinnersWonAmount;
  // Minimum bet amount.
  uint256 public minimumBet = 1e17;//0.1 MATIC
  // Chainlink exchange rate provider MATIC/USD.
  AggregatorV3Interface internal maticUsdPriceFeed;
  // Possible bet states.
  enum BETTING_STATE {TAKING_BETS,CLOSED,WAITING_FOR_RESULTS}// respectively 0,1,2
  // Contract state (0/1/2)
  BETTING_STATE public bettingState;

  constructor(
    address _maticPriceFeedAddress// Chainlink matic price feed address on current blockchain.
    ){
    // Grant the DEFAULT_ADMIN and ADMIN roles to the owner
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
    maticUsdPriceFeed = AggregatorV3Interface(_maticPriceFeedAddress);
    bettingState = BETTING_STATE.CLOSED;
  }

  //Function for the owner to assign administrators
  function assignAdmin(address _address) external onlyOwner{
    _setupRole(ADMIN_ROLE, _address);
  }

  // Function called by the admin to start a new betting round.
  function startTakingBets(string memory _name,string memory _description,uint256 _matchStart,uint256 _matchEnd) external onlyRole(ADMIN_ROLE){
    require(bettingState == BETTING_STATE.CLOSED, "Cant start a new betting yet!");// Check if previous round has finished.
    bettingState = BETTING_STATE.TAKING_BETS;
    name = _name;
    description = _description;
    matchStart = _matchStart;
    matchEnd = _matchEnd;
    startTime = block.timestamp;
  }

  // Returns minimum bet amount in USD according to chainlink price feed.
  function getMinBetUsd() external view returns (uint256){
    (,int256 price,,,)= maticUsdPriceFeed.latestRoundData();
    uint256 adjustedPrice = uint256(price)*1e10; //8+10 decimals
    return (minimumBet * adjustedPrice)/1e18;//Minimum bet amount in USD per current exchange rate.
  }

  // Returns minimum bet in MATIC.
  function getMinBet() public view returns (uint256){
    return minimumBet;//Minimum bet in MATIC.
  }

  // Functions for users to enter the betting.
  // Transaction must a set minimum amount of token to place a bet.
  function betOnTeam1() external payable{
    require(bettingState == BETTING_STATE.TAKING_BETS,"Not taking bets rn!");// Only allow to enter if the betting has begun.
    require(block.timestamp < matchStart,"Not taking bets anymore! Waiting for the match to end.");//Stop taking bets when the match begins.
    require(msg.value >= minimumBet, "Not enough MATIC! Run getMinBet() to get a minimum bet amount.");
    playersBetOnTeam1.push(payable(msg.sender));// Add player to the array.
    playersBetOnTeam1PayedAmount.push(msg.value);// Remember how much they bet.
    amountBetOnTeam1 += msg.value;// Add amount to total(makes payout easier).
  }

  function betOnTeam2() external payable{
    require(bettingState == BETTING_STATE.TAKING_BETS,"Not taking bets rn!");// Only allow to enter if the betting has begun.
    require(block.timestamp < matchStart,"Not taking bets anymore! Waiting for the match to end.");//Stop taking bets when the match begins.
    require(msg.value >= minimumBet, "Not enough MATIC! Run getMinBet() to get a minimum bet amount.");
    playersBetOnTeam2.push(payable(msg.sender));// Add player to the array.
    playersBetOnTeam2PayedAmount.push(msg.value);// Remember how much they bet.
    amountBetOnTeam2 += msg.value;// Add amount to total(makes payout easier).
  }

  function betOnDraw() external payable{
    require(bettingState == BETTING_STATE.TAKING_BETS,"Not taking bets rn!");// Only allow to enter if the betting has begun.
    require(block.timestamp < matchStart,"Not taking bets anymore! Waiting for the match to end.");//Stop taking bets when the match begins.
    require(msg.value >= minimumBet, "Not enough MATIC! Run getMinBet() to get a minimum bet amount.");
    playersBetOnDraw.push(payable(msg.sender));// Add player to the array.
    playersBetOnDrawPayedAmount.push(msg.value);// Remember how much they bet.
    amountBetOnDraw += msg.value;// Add amount to total(makes payout easier).
  }

  // Function executed by the server automatically after
  // a set amount of time has passed.
  // Takes score as arguments and pays players accordingly.
  // Sets matchStart and matchEnd to 0 and resets arrays and variables.
  function concludeBetting(uint256 _team1Score, uint256 _team2Score) external onlyRole(ADMIN_ROLE){
    require(block.timestamp >= matchEnd,"Betting can not conclude until the match is over and results are known, run .matchEnd() to check when it can be ended.");// Make sure it is supposed to end now.
    bettingState = BETTING_STATE.CLOSED;
    team1Score = _team1Score;
    team2Score = _team2Score;
    uint256 pool = amountBetOnTeam1+amountBetOnTeam2+amountBetOnDraw;
    recentWinnersWonAmount = new uint256[](0);
    if(team1Score>team2Score){
      if(playersBetOnTeam1.length!=0 && amountBetOnTeam1>0){
        recentWinners = playersBetOnTeam1;
        for(uint256 i=0;i<playersBetOnTeam1.length;i++){
          recentWinnersWonAmount.push(((pool*((playersBetOnTeam1PayedAmount[i]*1e18)/amountBetOnTeam1))/1e20)*95);// minus 5% commision(used mainly for paying gas for transfering rewards to winners).
          playersBetOnTeam1[i].transfer(recentWinnersWonAmount[i]);
        }
      }
    }else{
      if(team1Score<team2Score){
        if(playersBetOnTeam2.length!=0 && amountBetOnTeam2>0){
          recentWinners = playersBetOnTeam2;
          for(uint256 i=0;i<playersBetOnTeam2.length;i++){
            recentWinnersWonAmount.push(((pool*((playersBetOnTeam2PayedAmount[i]*1e18)/amountBetOnTeam2))/1e20)*95);// minus 5% commision(used mainly for paying gas for transfering rewards to winners).
            playersBetOnTeam2[i].transfer(recentWinnersWonAmount[i]);
          }
        }
      }else{
        require(team1Score==team2Score, "Its not a draw! teamScore parameters invalid!");
        if(playersBetOnTeam2.length!=0 && amountBetOnTeam2>0){
          recentWinners = playersBetOnDraw;
          for(uint256 i=0;i<playersBetOnDraw.length;i++){
            recentWinnersWonAmount.push(((pool*((playersBetOnDrawPayedAmount[i]*1e18)/amountBetOnDraw))/1e20)*95);// minus 5% commision(used mainly for paying gas for transfering rewards to winners).
            playersBetOnDraw[i].transfer(recentWinnersWonAmount[i]);
          }
        }
      }
    }
    payable(owner()).transfer(address(this).balance);
    matchStart = 0;
    matchEnd = 0;
    playersBetOnTeam1 = new address payable[](0);
    playersBetOnTeam2 = new address payable[](0);
    playersBetOnDraw = new address payable[](0);
    playersBetOnTeam1PayedAmount = new uint256[](0);
    playersBetOnTeam2PayedAmount = new uint256[](0);
    playersBetOnDrawPayedAmount = new uint256[](0);
    amountBetOnTeam1 = 0;
    amountBetOnTeam2 = 0;
    amountBetOnDraw = 0;
  }

 // Returns the amount of players that bet for team1.
 function getAmountOfPlayersBetOnTeam1() public view returns(uint256){
   return playersBetOnTeam1.length;
 }

 // Returns the amount of players that bet on team2.
 function getAmountOfPlayersBetOnTeam2() public view returns(uint256){
   return playersBetOnTeam2.length;
 }

 // Returns the amount of players that bet on draw.
 function getAmountOfPlayersBetOnDraw() public view returns(uint256){
   return playersBetOnDraw.length;
 }

 // Returns the array of all players that bet for team 1.
 function getPlayersBetOnTeam1() public view returns(address payable[] memory){
   return playersBetOnTeam1;
 }

 // Returns the array of all amounts players that bet for team 1.
 function getPlayersBetOnTeam1PayedAmount() public view returns(uint256[] memory){
   return playersBetOnTeam1PayedAmount;
 }

 // Returns the array of all players that bet for team 2.
 function getPlayersBetOnTeam2() public view returns(address payable[] memory){
   return playersBetOnTeam2;
 }

 // Returns the array of all amounts players that bet for team 2.
 function getPlayersBetOnTeam2PayedAmount() public view returns(uint256[] memory){
   return playersBetOnTeam2PayedAmount;
 }

 // Returns the array of all players that bet for team 2.
 function getPlayersBetOnDraw() public view returns(address payable[] memory){
   return playersBetOnDraw;
 }

 // Returns the array of all amounts players that bet for team 2.
 function getPlayersBetOnDrawPayedAmount() public view returns(uint256[] memory){
   return playersBetOnDrawPayedAmount;
 }

 // Returns the array of all players that won the last bet.
 function getRecentWinners() public view returns(address payable[] memory){
   return recentWinners;
 }

 // Returns the array of money payed out to players that won the last bet.
 function getRecentWinnersWonAmount() public view returns(uint256[] memory){
   return recentWinnersWonAmount;
 }

// Returns the bet pool in MATIC.
 function getPoolMatic() public view returns(uint256){
   return amountBetOnTeam1+amountBetOnTeam2+amountBetOnDraw;//amount in wei
 }

// Returns the bet pool in USD.
 function getPoolUsd() public view returns(uint256){
   uint256 pool = amountBetOnTeam1+amountBetOnTeam2+amountBetOnDraw;
   (,int256 price,,,)= maticUsdPriceFeed.latestRoundData();
   uint256 adjustedPrice = uint256(price)*1e10; //18 decimals
   return (pool*adjustedPrice)/1e18;
 }

// Returns amount of money bet on team 1 in USD.
 function getAmountBetOnTeam1Usd() public view returns(uint256){
   (,int256 price,,,)= maticUsdPriceFeed.latestRoundData();
   uint256 adjustedPrice = uint256(price)*1e10; //18 decimals
   return (amountBetOnTeam1*adjustedPrice)/1e18;
 }

// Returns amount of money bet on team 2 in USD.
 function getAmountBetOnTeam2Usd() public view returns(uint256){
   (,int256 price,,,)= maticUsdPriceFeed.latestRoundData();
   uint256 adjustedPrice = uint256(price)*1e10; //18 decimals
   return (amountBetOnTeam2*adjustedPrice)/1e18;
 }

 // Returns amount of money bet on team 2 in USD.
  function getAmountBetOnDrawUsd() public view returns(uint256){
    (,int256 price,,,)= maticUsdPriceFeed.latestRoundData();
    uint256 adjustedPrice = uint256(price)*1e10; //18 decimals
    return (amountBetOnDraw*adjustedPrice)/1e18;
  }

// Emerengency function for the owner to refund all players in case of malfunction.
 function refundAllPlayers() external onlyOwner{
   for(uint256 i=0;i<playersBetOnTeam1.length;i++){
     playersBetOnTeam1[i].transfer(playersBetOnTeam1PayedAmount[i]);
   }
   for(uint256 i=0;i<playersBetOnTeam2.length;i++){
     playersBetOnTeam2[i].transfer(playersBetOnTeam2PayedAmount[i]);
   }
   for(uint256 i=0;i<playersBetOnTeam2.length;i++){
     playersBetOnDraw[i].transfer(playersBetOnDrawPayedAmount[i]);
   }
 }

 // Data aggregators for quicker website loading.
 function getBetInfo() external view returns(BETTING_STATE,string memory,string memory,uint256,uint256,uint256,uint256,uint256){
   return(bettingState,name,description,matchStart,matchEnd,getMinBet(),getPoolMatic(),getPoolUsd());
 }
 function getPlayerInfo() external view returns(address payable[] memory,address payable[] memory,address payable[] memory,address payable[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256,uint256){
   return(getPlayersBetOnTeam1(),getPlayersBetOnTeam2(),getPlayersBetOnDraw(),getRecentWinners(),getRecentWinnersWonAmount(),getPlayersBetOnTeam1PayedAmount(),getPlayersBetOnTeam2PayedAmount(),getPlayersBetOnDrawPayedAmount(),team1Score,team2Score);
 }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

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
        _checkRole(role);
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
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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