/**
 *Submitted for verification at polygonscan.com on 2022-04-11
*/

// File: @openzeppelin/contracts/utils/Strings.sol


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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/LAUNDRY.sol



pragma solidity ^0.8.0;



 

contract Laundry is Ownable{
   using Strings for uint256;
   using SafeMath for uint256;

   IERC721 NFT;
   IERC20 TOKEN;
   IBLOCKS BLOCKS;

   bool ACTIVE;
 
   uint256 public UNIT_PRICE=100*10**18;
   uint256 highWashed;
   uint256 minWashBlocks=4;
   uint256 maxWashBlocks=12;

   uint256 totalWashed;
   uint256 totalBurned; 
   uint256 totalEarned;
    
    


   uint256[] Rewards;

   struct Game{
      uint256 firstBlock;    
      uint256 secondBlock; 
      uint256 prediction;
      bool claimed; 
      uint256 earned; 
      uint256 played;
      uint256 lasttime;          
   }

   mapping(uint256 => Game) private Games;

   event Washed(address user, uint256 tokenId,uint256 curBlock, uint256 firstBlock,uint256 secondBlock,uint256 prediction, uint256  played,uint256  lasttime );
   event Win(address user, uint256 tokenId, uint256 earnings );
   event UnitPrice( uint256 price );
   event Bonus(address user, uint256 tokenId, uint256 earnings  );
   event DirtClaimed(uint256 tokenId,uint256 dirt,uint256 lasttime);
   event Run(uint256 tokenId,uint256 dirt,uint256 tokens,uint256 lasttime);


   constructor(address _nft, address _token ) {
      NFT=IERC721(_nft);
      TOKEN=IERC20(_token);

       
      BLOCKS=IBLOCKS(0x32C9E907E95E28ecF5f84C45a7A9Ff9bA883e12c);

      Rewards.push(100);
      Rewards.push(50);
      Rewards.push(33);
      Rewards.push(25);
      Rewards.push(20);
      Rewards.push(16);
      Rewards.push(14);
      Rewards.push(12);
      Rewards.push(11);
      Rewards.push(10);

   }


   

   function Wash(uint256 tokenId, uint256 prediction) public {
      require(ACTIVE   , "NotActive");
      require(msg.sender == NFT.ownerOf(tokenId)    , "This sock is not yours");
      require(Games[tokenId].secondBlock < block.number    , "LastGameStillActive");
      uint256 dirt = NFT.getDirt(tokenId);
      require(dirt>0    , "Its clean");
      require(prediction<10    , "NotAllowded");

      NFT.Dirty(tokenId,dirt.sub(1));
      totalWashed=totalWashed.add(1);

      uint256 dur = getDuration(tokenId);

      Games[tokenId].claimed=false;
      Games[tokenId].prediction=prediction;
      Games[tokenId].firstBlock=block.number.add(dur.sub(3));
      Games[tokenId].secondBlock=block.number.add(dur);
      Games[tokenId].played=Games[tokenId].played.add(1);
      Games[tokenId].lasttime=block.timestamp;
      //emit event

      if(Games[tokenId].played>highWashed){
         highWashed=Games[tokenId].played;
      }


      emit Washed(msg.sender, tokenId,block.number, Games[tokenId].firstBlock, Games[tokenId].secondBlock, Games[tokenId].prediction, Games[tokenId].played, Games[tokenId].lasttime );

   }

   function ReadGame(uint256 tokenId) public view returns(uint256 curBlock, uint256 firstBlock, uint256 secondBlock, uint256 prediction, bool claimed, uint256 earned, uint256 played, uint256 lasttime, uint256 dur){
      require(tokenId < NFT.totalSupply()    , "Token not found");
      Game memory CurGame = Games[tokenId];
      dur = getDuration(tokenId);
      return(block.number-1,CurGame.firstBlock,CurGame.secondBlock,CurGame.prediction,CurGame.claimed,CurGame.earned,CurGame.played,CurGame.lasttime,dur);
   }

   function ClaimWin(uint256 tokenId, string memory body0, uint256 num0, string memory rest0, string memory body1, uint256 num1, string memory rest1) public{
      require(msg.sender == NFT.ownerOf(tokenId)    , "This sock is not yours");
      require(Games[tokenId].secondBlock < block.number    , "NotReadyYet");
      BLOCKS.Validate(Games[tokenId].firstBlock,body0,num0,rest0);
      BLOCKS.Validate(Games[tokenId].secondBlock,body1,num1,rest1);
      require(Games[tokenId].claimed==false    , "AlreadyClaimed");
      
      num0=num0.add(num1);
      require(Games[tokenId].prediction==num0    , "YouLost");
      Games[tokenId].claimed=true;
      
 
      uint256 earnings = Rewards[num0].mul(UNIT_PRICE);
      UNIT_PRICE=UNIT_PRICE.sub(10*10**18);
      if(UNIT_PRICE<100*10**18){
         UNIT_PRICE=100*10**18;
      }
      require(TOKEN.mintTo(msg.sender,earnings), "Something Went Wrong");
      Games[tokenId].earned=Games[tokenId].earned.add(earnings);

      totalEarned=totalEarned.add(earnings);

      //emit event   
      emit Win(msg.sender, tokenId, earnings );
      emit UnitPrice(UNIT_PRICE);
   
   }



   function getEarning(uint256 tokenId  ) public view returns (uint256 earnings) {
        require(tokenId < NFT.totalSupply()    , "Token not found");
        return(Games[tokenId].earned );
    }

    
   function getDuration(uint256 tokenId  ) public view returns (uint256) {
      require(tokenId < NFT.totalSupply()    , "Token not found");
      if(Games[tokenId].played<10 ){
         return(16);
      }
 

      uint256 dur =  Games[tokenId].played.mul(1000).div(highWashed).mul(maxWashBlocks).div(1000) ;
      dur=maxWashBlocks.sub(dur).add(minWashBlocks);
      return(dur);
 
    }


    function ClaimBonus(uint256 tokenId ) public{
      require(msg.sender == NFT.ownerOf(tokenId)    , "This sock is not yours");
      require(Games[tokenId].secondBlock == 0  &&  Games[tokenId].claimed==false , "BonusClaimedOrLost");
       
      Games[tokenId].claimed=true;
 
      uint256 bonus = UNIT_PRICE.mul(10);
      require(TOKEN.mintTo(msg.sender,bonus), "Something Went Wrong");
       
      totalEarned=totalEarned.add(bonus);
      //emit event   
      emit Bonus(msg.sender, tokenId, bonus );
   
   }


   function ClaimDirt(uint256 tokenId)public {
      require(msg.sender == NFT.ownerOf(tokenId)    , "This sock is not yours");

       uint256 timeelapsed = block.timestamp.sub(Games[tokenId].lasttime);
       uint256 dirttoclaim;

       if(timeelapsed>15*60){
          dirttoclaim=1;
       }
   
       if(timeelapsed>25*60){
          dirttoclaim=2;
       }

       if(timeelapsed>30*60){
          dirttoclaim=3;
       }
       require(dirttoclaim >0    , "Nothing to claim");
       Games[tokenId].lasttime=block.timestamp;

       uint256 dirt = NFT.getDirt(tokenId);
       dirt=dirt.add(dirttoclaim);
       NFT.Dirty(tokenId,dirt);

       emit DirtClaimed(tokenId,dirttoclaim,block.timestamp);
   }

   function RunOnTheMud(uint256 tokenId,uint256 dirt, uint256 maxTokens)public {
      require(msg.sender == NFT.ownerOf(tokenId)    , "This sock is not yours");
      uint256 currentDirt=NFT.getDirt(tokenId);
      require(currentDirt<100    , "Current dirt must be lower");
      require(dirt<=10    , "Cant buy more than 10");

      uint256 amount = dirt.mul(UNIT_PRICE);
      UNIT_PRICE=UNIT_PRICE.add(dirt*10**18);
      require(amount<=maxTokens    , "Cant spend that much");

      TOKEN.transferFrom(msg.sender,address(this),amount);
      NFT.Dirty(tokenId,dirt.add(currentDirt));
      TOKEN.Burn(amount);
      Games[tokenId].lasttime=block.timestamp;
     
      totalBurned=totalBurned.add(amount);

      emit Run (tokenId, dirt, amount,block.timestamp);
      emit UnitPrice(UNIT_PRICE);

   }

   function getWashBlocks() public view returns(uint256 min, uint256 max, uint256 high ) {
      return(minWashBlocks,maxWashBlocks,highWashed);
   }

   function Activate() public onlyOwner {
      ACTIVE=true;
   }

   function setWashBlocks(uint256 min, uint256 max) public onlyOwner {
      require(max>min);
      require(min>=4);
      maxWashBlocks=max;
      minWashBlocks=min;
   }


   function getStats( ) public view returns(uint256 washed,uint256 earned,uint256 burned ) {
      return(totalWashed,totalEarned,totalBurned);
   }
 

  


}




interface IERC721 {
   function totalSupply() external view returns (uint256);
   function ownerOf(uint256 ) external view returns (address) ;
   function Dirty(uint256 tokenId, uint256 state ) external ;
   function getDirt(uint256 tokenId  ) external view returns (uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom( address from, address to,  uint256 amount  ) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function mintTo(address to, uint256 amount) external returns (bool);
    function Burn( uint256 amount) external returns(bool) ;
}

interface IBLOCKS {
    function Validate(uint256 blck,string memory body, uint256 num, string memory rest) external view returns(bool);
}