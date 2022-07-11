// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface INFT{
    function changeVolumeLevel(uint256 _tokenId, uint256 _volume, uint256 referalFees) external;
    function ownerOf(uint256 _tokenId) external returns (address);
    function isExists(uint256 _tokenId) external returns (bool);
    function getTokenInfos(uint256 tokenId) external returns (uint256[3] memory);
    function totalSupply() external returns (uint256);
    function getmaxLevel() external view returns (uint256);

}

interface IVRF{
   function getRandomNumber(uint256 gameId) external ;
}

    
contract CoinFlip is Ownable, ReentrancyGuard{
    
  using SafeMath for uint256;

  INFT public NFT;
  IVRF public VRF;

    
  uint256[] public amounts = [0.01 ether, 5 ether, 10 ether, 25 ether, 50 ether, 100 ether ];

  uint256 gasFeesForLink = 0.02 ether;
  uint256 public maxticket = 100;
  uint256 public minticket = 0.01 ether;
  uint256 public housefees = 300;
  uint256 public winstreak = 30;
  uint256 public devFees = 10;
  uint256 public reserve = 10;
  uint256 public gameIdGlobal;
  uint256 public overFlow = 13000 ether;
  uint256 public minAmount = 50 ether;
  address public Automatic;
  bool public Auto;

  uint256 public reserveFunds;
  uint256 public winstreakFunds;

  uint256 public maxWinstreak;
  uint256 public maxLoseStreak;
  uint256 public counterLWStreak;
  uint256 public streakLockTime = 60*60*8;

  uint256 public currentRun;

  address public LoseStreakLeaderBoard;
  address public WinStreakLeaderBoard;

  address public devAddr;
  

  mapping(uint256 => mapping(address => uint256) ) public WinStreak;
  mapping(uint256 => mapping(address => uint256) ) public LoseStreak;

  mapping(uint256 => Game) public games;
  mapping(address => Outcome) public outcomes;
  mapping(address => uint256) public referrers; // account_address => tokenID 
  mapping(uint256 => uint256) public referredCount; // tokenID -> num_of_referred

  uint256 public nextNFTRef;

  struct Outcome{
    uint256 id;
    uint256 bet;
    uint8 random;
    uint256 winAmount;
    uint256 block;
    uint256 amount;
    uint256 fees;
    uint256 totalfees;
  }

  struct Game{
    uint256 id;
    uint256 bet;
    uint256 amount;
    address player;
    bool isSettled;
  }


  event Withdraw(address admin, uint256 amount);
  event Result(uint256 id, uint256 bet, uint256 amount, address player, uint256 winAmount, uint256 randomResult, uint256 loseStreak, uint256 winStreak);
  event Referral(uint256 indexed _tokenId, address indexed _user);
  event SendWLStreak(uint256 ts, address win,uint256 winAmount, address lose, uint256 loseAmount, uint256 maxLoseStreak, uint256 maxWinStreak, uint256 currentRun);
  event sendFunds(address Addr, uint256 Share);
  event sendFundReferal(uint256 tID,uint256 referalFees);
  event sendFundAutomatic(address Automatic,uint256 amount);
 
  constructor(address _devAddr) {
        counterLWStreak = block.timestamp;
        devAddr = payable(_devAddr);
  }


  function claimWLStreak() internal {

        if ( 
            (counterLWStreak.add(streakLockTime)  < block.timestamp) && 
            (maxWinstreak > 0) && 
            (maxLoseStreak > 0) && 
            (WinStreakLeaderBoard != address(0)) && 
            (LoseStreakLeaderBoard != address(0)) 
            )
        {

        uint256 winFees;
        uint256 loseFees;

        if ( maxWinstreak > maxLoseStreak ) winFees = winstreakFunds;
        else if ( maxLoseStreak > maxWinstreak ) loseFees = winstreakFunds;

        else{
             winFees = winstreakFunds.div(2);
             loseFees = winstreakFunds.div(2);
        }

        if (loseFees >0)
            sendFund(payable(LoseStreakLeaderBoard), loseFees);
        if (winFees >0)
            sendFund(payable(WinStreakLeaderBoard), winFees);

        emit SendWLStreak(block.timestamp, WinStreakLeaderBoard, winFees, LoseStreakLeaderBoard, loseFees, maxLoseStreak, maxWinstreak, currentRun);

        winstreakFunds = 0;
        counterLWStreak = block.timestamp;
        maxWinstreak = 0;
        maxLoseStreak = 0;
        WinStreakLeaderBoard = address(0);
        LoseStreakLeaderBoard = address(0);
        currentRun++;
        }
  }


  function selectNFTRef() internal returns (uint256 ) {
        
    if(nextNFTRef.add(1) >= NFT.totalSupply())
            nextNFTRef = 1;
    else
            nextNFTRef = nextNFTRef.add(1);

    return nextNFTRef;
  }


  function setMintAmount(uint256 _overFlow, uint256 _minAmount, address _Automatic, bool _activate) external onlyOwner{
        overFlow = _overFlow;
        minAmount = _minAmount;
        Automatic = _Automatic;
        Auto = _activate;
  }

  function setNFT(address _addr) external onlyOwner{
        NFT = INFT(_addr);
  }


  function setVRF(address _addr) external onlyOwner{
        VRF = IVRF(_addr);
  }


  function setdevAddr(address _addr) external onlyOwner{
        devAddr = _addr;
  }

  function setStreakLockTime(uint256 _streakLockTime) external onlyOwner{
        streakLockTime = _streakLockTime;
  }

    // Set Referral tokenId for a user
    function setReferralAdmin(address _user ,uint256 _tokenId) external onlyOwner {
        require(NFT.isExists(_tokenId), "NFT: nonexistent token");
        if (referrers[_user] == 0 || referrers[_user] != _tokenId && _tokenId != 0) {
            referrers[_user] = _tokenId;
            referredCount[_tokenId] += 1;

            emit Referral(_tokenId, _user);
            }
    }

    // Set Referral tokenId for a user
    function setReferral(uint256 _tokenId) internal {
        require(NFT.isExists(_tokenId), "NFT: nonexistent token");
        if (referrers[msg.sender] == 0 && _tokenId != 0) {
            referrers[msg.sender] = _tokenId;
            referredCount[_tokenId] += 1;

            emit Referral(_tokenId, msg.sender);
            }
    }

    // Get Referral TokenId for a Account
    function getReferral(address _user) public view returns (uint256) {
        return referrers[_user];
    }

  function setFees(uint256 _housefees, uint256 _winstreak, uint256 _reserve, uint256 _devFees) external onlyOwner {
        require( (_housefees + _winstreak + _reserve + _devFees) <= 1000, "too much Fees");
        housefees = _housefees;
        winstreak = _winstreak;
        reserve = _reserve;
        devFees = _devFees;
  }

  function setTicket(uint256 _amount) external onlyOwner {
        require( _amount <= 1000, "too much, too risky");
        maxticket = _amount;
  }


  function setMintTicket(uint256 _amount) external onlyOwner {
        require( _amount > 0, "can't set it too low");
        minticket = _amount;
  }


  function setAmounts(uint256[] memory  _amounts, uint256 _gasFeesForLink) external onlyOwner {
        require(_gasFeesForLink <= 0.02 ether,"too much gasFees");
        amounts = _amounts;
        gasFeesForLink = _gasFeesForLink;
  }


  function vaultBalance() public view returns (uint256){
        return address(this).balance;
  }

  function amountExists(uint256 num) public view returns (bool) {
        for (uint8 i = 0; i < amounts.length; i++) {
            if (amounts[i] == num) {
                return true;
            }
        }
        return false;
    }

  function game(uint256 bet, uint256 _tokenId) public payable nonReentrant {

    require(msg.sender == tx.origin, "NOT EOA");

    setReferral(_tokenId);

    uint256 amount;
    uint256 poolBal;

    uint256 UserValue = msg.value.sub(gasFeesForLink);

    poolBal = address(this).balance;
    amount = maxticket.mul(poolBal).div(10000);

    require( UserValue >= minticket && UserValue <= amount , "wrong ETH");

    require( amountExists(UserValue),  "Wrong ETH + link Fees");

    require( poolBal >= UserValue.mul(2) , "Error, insufficent vault balance");

    require(bet == 0 || bet == 1, 'wrong choice');

    games[gameIdGlobal] = Game(gameIdGlobal, bet, UserValue, payable(msg.sender), false);

    VRF.getRandomNumber(gameIdGlobal);

    gameIdGlobal = gameIdGlobal.add(1);

  }
  
  function sendOverFlow() internal {
        
          uint256 amount = overFlow.add(minAmount);
          if(address(this).balance > amount ){
              
              sendFund(payable(Automatic), minAmount);
              emit sendFundAutomatic(Automatic,minAmount);
          }
  }


   function sendRefFunds(address payable referal, uint256 amount, uint256 tokenId, uint256 referalFees) internal {

      NFT.changeVolumeLevel(tokenId, amount, referalFees);
      sendFund(referal, referalFees);

      emit sendFundReferal(tokenId,referalFees);
  }
 

 function max(uint256 x) private view returns (uint256) {
        return x >= NFT.getmaxLevel() ? NFT.getmaxLevel() : x;
  } 

 function manageRef(uint256 amount, address player) internal {
 
    uint256 tID = referrers[player];
    address referal = NFT.ownerOf(tID);

    uint256 referalFees = amount.mul(housefees).div(10000); 
    uint256 slipFees;

    uint256 maxLevel = NFT.getmaxLevel();
    uint256 Level = max(NFT.getTokenInfos(tID)[1]);

    if ( tID != 0 ){
         slipFees =  referalFees.mul(Level).div(maxLevel);
         sendRefFunds(payable(referal),amount,tID,slipFees);
      }

      uint256 tID2 = selectNFTRef();
      address referaltID2 = NFT.ownerOf(tID2);
      sendRefFunds(payable(referaltID2),0,tID2,referalFees.sub(slipFees));
    }

  function checkWinner(uint256 gameId, uint8 random) external {

      require(msg.sender == address(VRF), "Not the VRF");

      require(!games[gameId].isSettled, "already settled ");

      uint256 winAmount = 0;

      uint256 totalfees = housefees.add(winstreak).add(reserve).add(devFees);
      uint256 fees = games[gameId].amount.mul(totalfees).div(10000); 
      uint256 devFeesAmount = games[gameId].amount.mul(devFees).div(10000);

      reserveFunds = reserveFunds.add(games[gameId].amount.mul(reserve).div(10000));
      winstreakFunds =  winstreakFunds.add(games[gameId].amount.mul(winstreak).div(10000));

      if(
            (random < 50 && games[gameId].bet == 0) || (random >= 50 && games[gameId].bet == 1) 
        )
      {
        winAmount =  games[gameId].amount.mul(2).sub(fees);
        require(address(this).balance >= winAmount, 'Error, contract has insufficent balance');

        sendFund(payable(address(games[gameId].player)), winAmount);

        WinStreak[currentRun][games[gameId].player] += 1;
        LoseStreak[currentRun][games[gameId].player] = 0;

        if ( maxWinstreak < WinStreak[currentRun][games[gameId].player] )
        {
            maxWinstreak = WinStreak[currentRun][games[gameId].player];
            WinStreakLeaderBoard = games[gameId].player;
        }

      }

      else
      {
        WinStreak[currentRun][games[gameId].player] = 0;
        LoseStreak[currentRun][games[gameId].player] += 1;

        if ( maxLoseStreak < LoseStreak[currentRun][games[gameId].player] )
        {
            maxLoseStreak = LoseStreak[currentRun][games[gameId].player];
            LoseStreakLeaderBoard = games[gameId].player;
        }

      }

      manageRef(games[gameId].amount, games[gameId].player);
      sendFund(payable(address(devAddr)), devFeesAmount);

      outcomes[games[gameId].player] = Outcome(games[gameId].id, games[gameId].bet, random,winAmount,block.timestamp,  games[gameId].amount, fees, totalfees);

      games[gameId].isSettled = true;

      uint256 lStreak = LoseStreak[currentRun][games[gameId].player];
      uint256 WStreak = WinStreak[currentRun][games[gameId].player];
      emit Result(games[gameId].id, games[gameId].bet, games[gameId].amount, games[gameId].player, winAmount, random, lStreak, WStreak);

      claimWLStreak();

      if (Auto)
          sendOverFlow();

  }
 
   function sendFund(address payable Addr, uint256 Share) internal {
      (bool success, ) = Addr.call{value: Share}("");
      require(success, "Withdrawal failed");
      
      emit sendFunds(Addr, Share);
  }

  function withdraw() external onlyOwner {
    require(address(this).balance >= 0, 'Error, contract has insufficent balance');
    sendFund(payable(msg.sender), address(this).balance);
   
    emit Withdraw(msg.sender, address(this).balance);
  }

  function withdrawAmount(uint256 amount) external onlyOwner {
    require(address(this).balance >= amount, 'Error, contract has insufficent balance');
    sendFund(payable(msg.sender), amount );
   
    emit Withdraw(msg.sender, address(this).balance);
  }


  function withdrawReserveFunds() external onlyOwner {
    require(address(this).balance >= reserveFunds, 'Error, contract has insufficent balance');

    reserveFunds = 0;
    sendFund(payable(msg.sender), reserveFunds);
   
    emit Withdraw(msg.sender, reserveFunds);
  }

    receive() external payable {}

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