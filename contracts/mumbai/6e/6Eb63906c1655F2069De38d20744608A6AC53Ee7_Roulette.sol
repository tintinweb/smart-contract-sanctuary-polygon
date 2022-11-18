// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Roulette is Ownable, ReentrancyGuard {
  uint256 public BetId;
  uint256 public currentRoomId;
  uint32 private deadlineOfGame = 10000;                
  uint256 private maxBet = 500 * 10 ** 18;
  uint8[] payouts = [2,3,3,2,2,36];
  uint8[] numberRange = [1,2,2,1,1,36];

  enum BetTypes {
    colour,
    column,
    dozen,
    eighteen,
    modulus,
    number
  }

  /*
      Depending on the BetType, number will be:
      color: 0 for black, 1 for red
      column: 0 for left, 1 for middle, 2 for right
      dozen: 0 for first, 1 for second, 2 for third
      eighteen: 0 for low, 1 for high
      modulus: 0 for even, 1 for odd
      number: number
  */

  struct SinglePlayerBet {
    address bettorAddress;
    BetTypes[] betType;
    uint8[] number;
    uint256[] betAmount;
    uint256 winningAmount; 
    uint256 randomNumber;  
  }

  struct Room {
    bool gameStarted;
    uint256 time;
    uint256 randomNumber;
    bool betCompleted;
  }

  struct UserBet {
    address bettorAddress;
    BetTypes[] betType;
    uint8[] number;
    uint256[] betAmount;
    uint256 winningAmount;
    address tokenAddress;
    bool isEther;
  }

  event BetPlacedInEther(
    uint256 _betId,
    address _playerAddress,
    uint256[] _betAmount,
    BetTypes[] _betType,
    uint8[] _number
  );

  event BetPlacedInToken(
    uint256 _betId,
    address _playerAddress,
    address _tokenAddress,
    uint256[] _betAmount,
    BetTypes[] _betType,
    uint8[] _number
  );

  event RouletteStarted(uint256 indexed betId, uint indexed time);
  event SingleBetCompleted(uint256 indexed _betId, address indexed _player, uint256 _randomNumber, uint256 indexed _winningAmount);
  event BetCompleted(uint256 indexed _betId, uint256 indexed _randomNumber);

  mapping(address => bool) public isWhitelistedToken;
  mapping(uint256 => SinglePlayerBet) private betIdToBets;
  mapping(uint256 => Room) public RoomIdToBets;
  mapping(address => uint256[]) private userBets;
  mapping(address => uint256[]) private multiplePlayerBets;
  mapping(uint256 => mapping(address => UserBet)) private players;
  mapping(uint256 => mapping(address => bool)) public participated;
  mapping(uint256 => address[]) private participants;
  mapping (address => uint256) public winningsInEther;
  mapping(address => mapping(address => uint256)) public winningsInToken;

  /** 
   * @dev For placing the bet.
   * @param _betType to choose the bet type. 
   * @param number based on the bet type, a number should be chosen.
   * @param _isEther to check whether is selected network is Ether or ERC20 token.
   * @param ERC20Address to know which token is chosen if the the network connected is not Ether.
   * Only whitelisted tokens are allowed for payments.
   * @param amount amount of token user wants to bet. Should approve the contract to use it first.
   */
  function singlePlayerBet(BetTypes[] memory _betType, uint8[] memory number, bool _isEther, address ERC20Address, uint256[] memory amount) public payable {
    require(_betType.length == number.length && number.length == amount.length); 
      BetId = _inc(BetId); 
      uint256 betValue ;  
      for(uint i = 0; i < _betType.length; i++) {
        uint8 temp = uint8(_betType[i]);
        require(number[i] >= 0 && number[i] <= numberRange[temp], "Number should be within range");
        require(amount[i] > 0, 'Bet Value should be greater than 0');
        betValue += amount[i];
      }
      require(betValue <= maxBet, "Maxium allowed bet is 500");

        SinglePlayerBet storage u = betIdToBets[BetId];
        u.bettorAddress = msg.sender;
        u.betType = _betType;
        u.number = number;
        u.betAmount = amount;

      if(_isEther == false){ 
        require(isWhitelistedToken[ERC20Address] == true, 'Token not allowed for placing bet');
        IERC20(ERC20Address).transferFrom(msg.sender, address(this), betValue);

        emit BetPlacedInToken(BetId, msg.sender, ERC20Address, amount, _betType, number );
        }
    else {     
      require(msg.value == betValue, 'Bet value should be same as the sum of bet amounts');            
        emit BetPlacedInEther(BetId, msg.sender, amount, _betType, number );
        }
        userBets[msg.sender].push(BetId); 
        spinWheel( BetId, _isEther, ERC20Address);     
    }

  //Internal function called by SinglePlayerBet function to update random number and winning value.
  function spinWheel(uint256 _betId, bool isEther, address ERC20Address) internal  {
    SinglePlayerBet storage bet = betIdToBets[_betId];
    uint256 num = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender, _betId, bet.betType.length))) % 36; 
    bet.randomNumber = num; 
    for(uint i = 0; i < bet.betType.length; i++){
    bool won = false;
       if (num == 0) {
        won = (bet.betType[i] == BetTypes.number && bet.number[i] == 0);                   /* bet on 0 */
      } else {
        if (bet.betType[i] == BetTypes.number) { 
          won = (bet.number[i] == num);                              /* bet on number */
        } else if (bet.betType[i] == BetTypes.modulus) {
          if (bet.number[i] == 0) won = (num % 2 == 0);              /* bet on even */
          if (bet.number[i] == 1) won = (num % 2 == 1);              /* bet on odd */
        } else if (bet.betType[i] == BetTypes.eighteen) {            
          if (bet.number[i] == 0) won = (num <= 18);                 /* bet on low 18s */
          if (bet.number[i] == 1) won = (num >= 19);                 /* bet on high 18s */
        } else if (bet.betType[i] == BetTypes.dozen) {                               
          if (bet.number[i] == 0) won = (num <= 12);                 /* bet on 1st dozen */
          if (bet.number[i] == 1) won = (num > 12 && num <= 24);     /* bet on 2nd dozen */
          if (bet.number[i] == 2) won = (num > 24);                  /* bet on 3rd dozen */
        } else if (bet.betType[i] == BetTypes.column) {               
          if (bet.number[i] == 0) won = (num % 3 == 1);              /* bet on left column */
          if (bet.number[i] == 1) won = (num % 3 == 2);              /* bet on middle column */
          if (bet.number[i] == 2) won = (num % 3 == 0);              /* bet on right column */
        } else if (bet.betType[i] == BetTypes.colour) {
          if (bet.number[i] == 0) {                                     /* bet on black */
            if (num <= 10 || (num >= 20 && num <= 28)) {
              won = (num % 2 == 0);
            } else {
              won = (num % 2 == 1);
            }
          } else {                                                 /* bet on red */
            if (num <= 10 || (num >= 20 && num <= 28)) {
              won = (num % 2 == 1);
            } else {
              won = (num % 2 == 0);
            }
          }
        }
      }
      uint256 typeOfBet = uint256(bet.betType[i]);
      /* if winning bet, add to player winnings balance */
      if (won && isEther) {
        winningsInEther[bet.bettorAddress] += bet.betAmount[i] * payouts[typeOfBet];
        bet.winningAmount += bet.betAmount[i] * payouts[typeOfBet];
      }
      else if (won == true && isEther == false) {
        winningsInToken[bet.bettorAddress][ERC20Address] += bet.betAmount[i] * payouts[typeOfBet];
        bet.winningAmount += bet.betAmount[i] * payouts[typeOfBet];
      }
      emit SingleBetCompleted(_betId, bet.bettorAddress, bet.randomNumber, bet.winningAmount);
    }
  }

  //returns struct details for the betId
  function checkBet(uint256 betId) external view returns(SinglePlayerBet memory) {
    return betIdToBets[betId];
  }

  /*
  Roulette game to be started by the owner. 
  Users are allowed to bet after the game is started until the deadline.
  */
  function startGame() external onlyOwner {
      currentRoomId = _inc(currentRoomId);
      Room storage b = RoomIdToBets[currentRoomId];
      b.gameStarted = true;
      b.time = block.timestamp;
      emit RouletteStarted(currentRoomId, block.timestamp);
    }

   /** 
   * @dev For placing the bet.
   * @param _betType to choose the bet type. 
   * @param number based on the bet type, a number should be chosen.
   * Check the comments above for the available betTypes.
   * @param _isEther to check whether is selected network is Ether or ERC20 token.
   * @param ERC20Address to know which token is chosen if the the network connected is not Ether.
   * Only whitelisted tokens are allowed for payments.
   * @param amount amount of token user wants to bet. Should approve the contract to use it first.
   */
    function multiPlayerBet(uint256 roomId, BetTypes[] memory _betType, uint8[] memory number, bool _isEther, address ERC20Address, uint256[] memory amount) public payable {
      require(block.timestamp < RoomIdToBets[roomId].time + deadlineOfGame, 'deadline for this bet is passed');
      require(participants[roomId].length <= 6, "Maxium spots filled");
      Room storage b = RoomIdToBets[roomId];
      require(b.betCompleted == false, "Spinning of wheel is completed"); 
      require(participated[roomId][msg.sender] == false, "Already participated");
      require(_betType.length == number.length && number.length == amount.length);
        uint256 betValue;
        for(uint i = 0; i < _betType.length; i++) {
          uint8 temp = uint8(_betType[i]);
          require(number[i] >= 0 && number[i] <= numberRange[temp], "Number should be within range");
          require(amount[i] > 0, 'Bet Value should be greater than 0');
          betValue += amount[i];
        }
        require(betValue <= maxBet, "Maxium allowed bet is 500");

        UserBet storage bet =  players[roomId][msg.sender];
        bet.bettorAddress = msg.sender;
        bet.betType = _betType;
        bet.number = number;
        bet.betAmount = amount;

        if(_isEther == false){ 
        require(isWhitelistedToken[ERC20Address] == true, 'Token not allowed for placing bet');
        IERC20(ERC20Address).transferFrom(msg.sender, address(this), betValue);
        bet.tokenAddress = ERC20Address;
        bet.isEther = false;
      
        emit BetPlacedInToken(roomId, msg.sender, ERC20Address, amount, _betType, number );
        }
    else {
        require(msg.value == betValue, 'Bet value should be same as the bet amount');       
        bet.isEther = true;
        emit BetPlacedInEther(roomId, msg.sender, amount, _betType, number );
      }
        multiplePlayerBets[msg.sender].push(roomId);
        participants[roomId].push(msg.sender);
        participated[roomId][msg.sender] = true;
    }

     /*
  Checks if the player has won the bet.
  Calculate the payouts for the winners of all bet types.
  Adds the winning amount to the user winnings.
  */
    function spinWheelForRoom(uint256 roomId) public onlyOwner {
    Room storage room = RoomIdToBets[roomId];
    require(room.betCompleted == false, "Spinning of wheel is completed");
    require(participants[roomId].length > 0, "No player joined");
    uint256 num = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender, roomId, participants[roomId].length))) % 36;
    room.randomNumber = num;
    for(uint j = 0; j < participants[roomId].length; j++) {
      address playerAddress = participants[roomId][j];   
      UserBet storage b = players[roomId][playerAddress];
      for(uint i = 0; i < b.betType.length; i++){
      bool won = false;
       if (num == 0) {
        won = (b.betType[i] == BetTypes.number && b.number[i] == 0);                   /* bet on 0 */
      } else {
        if (b.betType[i] == BetTypes.number) { 
          won = (b.number[i] == num);                              /* bet on number */
        } else if (b.betType[i] == BetTypes.modulus) {
          if (b.number[i] == 0) won = (num % 2 == 0);              /* bet on even */
          if (b.number[i] == 1) won = (num % 2 == 1);              /* bet on odd */
        } else if (b.betType[i] == BetTypes.eighteen) {            
          if (b.number[i] == 0) won = (num <= 18);                 /* bet on low 18s */
          if (b.number[i] == 1) won = (num >= 19);                 /* bet on high 18s */
        } else if (b.betType[i] == BetTypes.dozen) {                               
          if (b.number[i] == 0) won = (num <= 12);                 /* bet on 1st dozen */
          if (b.number[i] == 1) won = (num > 12 && num <= 24);  /* bet on 2nd dozen */
          if (b.number[i] == 2) won = (num > 24);                  /* bet on 3rd dozen */
        } else if (b.betType[i] == BetTypes.column) {               
          if (b.number[i] == 0) won = (num % 3 == 1);              /* bet on left column */
          if (b.number[i] == 1) won = (num % 3 == 2);              /* bet on middle column */
          if (b.number[i] == 2) won = (num % 3 == 0);              /* bet on right column */
        } else if (b.betType[i] == BetTypes.colour) {
          if (b.number[i] == 0) {                                     /* bet on black */
            if (num <= 10 || (num >= 20 && num <= 28)) {
              won = (num % 2 == 0);
            } else {
              won = (num % 2 == 1);
            }
          } else {                                                 /* bet on red */
            if (num <= 10 || (num >= 20 && num <= 28)) {
              won = (num % 2 == 1);
            } else {
              won = (num % 2 == 0);
            }
          }
        }
      }
      uint256 typeOfBet = uint256(b.betType[i]);
      /* if winning bet, add to player winnings balance */
      if (won && b.isEther) {
        winningsInEther[b.bettorAddress] += b.betAmount[i] * payouts[typeOfBet];
        b.winningAmount += b.betAmount[i] * payouts[typeOfBet];
      }
      else if (won == true && b.isEther == false) {
        winningsInToken[b.bettorAddress][b.tokenAddress] += b.betAmount[i] * payouts[typeOfBet];
        b.winningAmount += b.betAmount[i] * payouts[typeOfBet];
      }   
     } 
     room.betCompleted = true;
    emit BetCompleted(roomId, room.randomNumber);
    }  
  }

  //returns player details in a room
  function playerBetInRoom(uint256 roomId, address player) external view returns(UserBet memory) {
    return players[roomId][player];
  }

  //Owner can whitelist allowed token for placing bets
  function addWhitelistTokens(address ERC20Address) external onlyOwner {
    require(isWhitelistedToken[ERC20Address] == false, 'Token already whitelisted');
    isWhitelistedToken[ERC20Address] = true;
  }

  //Owner can remove whitelist tokens
  function removeWhitelistTokens(address ERC20Address) external onlyOwner {
    require(isWhitelistedToken[ERC20Address] == true, 'Token is not whitelisted');
    isWhitelistedToken[ERC20Address] = false;
  }

  //Allows users to withdraw their Ether winnings.
  function withdrawEtherWinnings(uint256 amount) external nonReentrant {
    require(winningsInEther[msg.sender] >= amount, "You do not have requested winning amount to withdraw");
    require(ReserveInEther() >= amount,'Sorry, Contract does not have enough reserve');
    winningsInEther[msg.sender] -= amount;
    payable(msg.sender).transfer(amount);
  }

  //Allows users to withdraw their ERC20 token winnings
  function withdrawTokenWinnings(address ERC20Address, uint256 amount) external nonReentrant {
    require(winningsInToken[msg.sender][ERC20Address] >= amount, "You do not have requested winning amount to withdraw");
    require(ReserveInToken(ERC20Address) >= amount,'Sorry, Contract does not have enough reserve');
    winningsInToken[msg.sender][ERC20Address] -= amount;
    IERC20(ERC20Address).transfer(msg.sender, amount);
  }

  //Bets placed by user
  function UserBets(address player) external view returns(uint[] memory){
    return userBets[player];
  }

    //Bets placed by user
  function MultiPlayerBets(address player) external view returns(uint[] memory){
    return multiplePlayerBets[player];
  }

  //Get participants of a room
  function getPlayers(uint roomId) public view returns(address[] memory) {
    return participants[roomId];
  } 

  //Checks Ether balance of the contract
  function ReserveInEther() public view returns (uint256) {
    return address(this).balance;
  }

  //Checks ERC20 Token balance.
  function ReserveInToken(address ERC20Address) public view returns(uint) {
    return IERC20(ERC20Address).balanceOf(address(this));
  }

  //Owner is allowed to withdraw the contract's Ether balance.
  function EtherWithdraw(address _receiver, uint256 _amount) external onlyOwner {
    require(ReserveInEther() >= _amount,'Sorry, Contract does not have enough balance');
    payable(_receiver).transfer(_amount);
  }

  //Owner is allowed to withdraw the contract's token balance.
  function TokenWithdraw(address ERC20Address, address _receiver, uint256 _amount) external onlyOwner {
    require(ReserveInToken(ERC20Address) >= _amount, 'Sorry, Contract does not have enough token balance');
    IERC20(ERC20Address).transfer(_receiver, _amount);
  }

  function _inc(uint256 index) private pure returns (uint256) {
    unchecked {
      return index + 1;
    }
  }

  receive() external payable {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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