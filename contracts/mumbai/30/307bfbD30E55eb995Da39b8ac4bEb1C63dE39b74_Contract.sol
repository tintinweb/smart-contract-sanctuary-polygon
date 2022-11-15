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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IFcoErc721.sol";
import "./dependencies/Fund.sol";
import "./dependencies/Oracle.sol";

contract Contract is Ownable , Fund, Oracle 
{
    using SafeMath for uint256;

    /**
    @notice The address of the erc721 contract
    */
    address public erc721Address;
    
    /**
    @notice The constructor initialize the usdc or usdeur contract
    */
    constructor(/*address erc20Address,*/ address _erc721Address) 
    /*Fund (
        erc20Address
    )    */
    {
        erc721Address = _erc721Address;
    }

   
    /**
    @notice Deposit function to add msg.sender to the  tournment. The functioon return the nft sent to msg.sender
    */
    function deposit(string memory  _tokenURI) public payable  {
        uint256 balanceOfSender = IFcoErc721(erc721Address).balanceOf(msg.sender);
        require( cupIsEnded        == false                                     , "You cannot deposit if the cup is ended");
        require( msg.value         >= baseQuote                                 , "Please > quote ether");
        require( balanceOfSender   == 0                                         , "You can buy only one");
        
        iswithdrawn[msg.sender] = false; 
        
        //approve(address(this), baseQuote); // if erc20
        //here we will put the erc20 approve flow
      
        IFcoErc721(erc721Address).mint(_tokenURI , msg.sender);
    }

    /**
    @notice Redeem the prize. 
    */
    function redeem() public payable  {
        require ( cupIsEnded == true                                            , "The competition is not ended yet");
        require ( IFcoErc721(erc721Address).isInWhiteList(msg.sender) == true   , "the msg sender is not in white list ");
        require ( IFcoErc721(erc721Address).balanceOf(msg.sender)     == 1      , "You can have only one NFT per address ");    
        
        // require approval if erc20

        uint256 [] memory tokenIds =  IFcoErc721(erc721Address).getUserOwnedTokens(msg.sender);
       
        uint256 rank = getRankof(tokenIds[0]);
     
        if(rank == 0) { payable(msg.sender).transfer( firstPrize   );}
        if(rank == 1) { payable(msg.sender).transfer( secondPrize  );}
        if(rank == 2) { payable(msg.sender).transfer( thirdPrize   );}

        iswithdrawn[msg.sender] = true;
       
    }

    /*
    @notice Recalculate the prize  and update the leaderboard using Oracle contract
    */
    function updateOracle  (uint256 [] memory _tokenIds) public   onlyOwner {
        recalculatePrize();
        _updateRankAll  ( _tokenIds);
        
    }

    /*
    @notice Transfer to the owner to withdraw after an amount of time 
    */
    function withdraw (uint256 tokenId) public payable  onlyOwner {
        address tokenIdOwner  = IFcoErc721(erc721Address).ownerOf(tokenId);

        require ( cupIsEnded                                            == true  , "The cup is not ended so you cannot withdraw");
        require ( iswithdrawn[tokenIdOwner]                             == false , "The owner of nft token id already withdrawn");
        require ( IFcoErc721(erc721Address).isInWhiteList(tokenIdOwner) == true  , "The owner of the nft is not in the whitelist");
      
        payable(tokenIdOwner).transfer(amountDeposited[tokenIdOwner]); // mandare all'utente non all'owner
        
        iswithdrawn[msg.sender] = true;
        
        recalculatePrize();
    
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Fund is Ownable  {

    using SafeMath for uint256;

    /**
    @notice Instantiate a erc20 contract
    */
    IERC20 public erc20Token;

    /**
    @notice The base quote that the address will pay to participate in the tournment
    */
    uint256 public baseQuote ;
    uint256 public baseQuoteErc20 ;
    
    /**
    @notice The variables that store the prize
    */
    uint256 public firstPrize;
    uint256 public secondPrize;
    uint256 public thirdPrize;
    uint256 public firstPrizeErc20;
    uint256 public secondPrizeErc20;
    uint256 public thirdPrizeErc20;
    
    /**
    @notice A variable that say if the tornment is ended 
    */
    bool public cupIsEnded;

    /**
    @notice The cup is ended at block time 
    */
    uint public cupIsEndedAtBlockTimestamp;

    /**
    @notice The constructor initialize the ERC20 contract and the base fee
    */
    constructor(/*address _erc20Token*/)  {
        //erc20Token = IERC20(_erc20Token);        
        baseQuote                       = 1 ;
        firstPrize                      = 0;
        secondPrize                     = 0;
        thirdPrize                      = 0;
        firstPrizeErc20                 = 0;
        secondPrizeErc20                = 0;
        thirdPrizeErc20                 = 0;
        cupIsEnded                      = false;
        cupIsEndedAtBlockTimestamp      = 0;

    }

    mapping(address => uint256) public amountDeposited;

    mapping(address => bool) public iswithdrawn; 

    /**
    @notice A function to set if the tournment is ended 
    */
    function setIsEnded() public onlyOwner {
        cupIsEnded = true;
        cupIsEndedAtBlockTimestamp = block.timestamp;
    }

    /**
    @notice a function that gets the balance of eth.
    */
    function balance() external view returns (uint256 ) {
        return  address(this).balance;
    }


    /**
    @notice a function that sets the base quote
    */
    function setBaseQuote ( uint256 _baseQuote ) external onlyOwner {
        baseQuote = _baseQuote;
    }

    function recalculatePrize() public payable {
        uint256 _balance = address(this).balance;
        firstPrize   = _balance.div(10).mul(5); //50% of balance
        secondPrize  = _balance.div(10).mul(3); //30% of balance
        thirdPrize   = _balance - firstPrize - secondPrize ; //the remeining is the nearly the 20% of balance
    }

    /*
    TODO WITH ERC20
    
    function balanceErc20() external view returns (uint256 ) {
        return  address(this).balance;
    }


    function withdrawErc20 () public payable  onlyOwner {
        require (cupIsEnded == true,"The cup is not ended so you cannot withdraw");
        require (block.timestamp - cupIsEndedAtBlockTimestamp > expiryDaysToWithdraw,"The owner cannot withdraw until 1 year after the cup is ended");
        payable(msg.sender).transfer(address(this).balance); 
    }


    function setBaseQuoteErc20 ( uint256 _baseQuoteErc20 ) external onlyOwner {
        baseQuoteErc20 = _baseQuoteErc20;
    }

    function recalculatePrizeErc20() public {
        uint256 _balance = erc20Token.balanceOf(address(this));
        firstPrizeErc20   = _balance.div(10).mul(5); //50% of balance
        secondPrizeErc20  = _balance.div(10).mul(3); //30% of balance
        thirdPrizeErc20   = _balance - firstPrize - secondPrize ; //the remeining is the nearly the 20% of balance
    }
    */
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Oracle  is Ownable {
/**
    @notice mapping of the leaderboard 
    */
    mapping(uint256 => uint256) private leaderboard;
    
    /**
    @notice Same of leaderboard but switched in order to avoid loops in functions 
    */
    mapping(uint256 => uint256) private rankof;

    /**
    @notice Update the leaderboard for a single position if we need to change the nft
    */
    function updateRank  (    uint256 _index, uint256 _tokenId) private  onlyOwner {
        leaderboard [_index] = _tokenId;
        rankof [_tokenId] = _index;
    }
    /**
    @notice Update the leaderboard passing a list of ordered array. 
    */
    function _updateRankAll  (uint256 [] memory _tokenIds) public virtual  onlyOwner {
        for (uint256 i=0; i<_tokenIds.length; i++) {
            updateRank(i,_tokenIds[i]);            
        }
    }

    
    /**
    @notice Get the leaderboard passing the index
    */
    function getLeaderboard  ( uint256 _index ) public view  returns ( uint256 )  {
        return leaderboard[_index];
    }

    /**
    @notice Get a switched leaderboard passing the tokenURI
    */
    function getRankof( uint256 _tokenId ) public view  returns ( uint256)  {
        return rankof[_tokenId];
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;
interface IFcoErc721 {
    function mint                 ( string memory    , address ) external       returns (uint256 );   
    function getUserOwnedTokens   ( address _address           ) external view  returns (uint256 [] memory  );
    function getTokenIsAtIndex    ( uint256 _index             ) external view  returns (int256  );
    function balanceOf            ( address owner              ) external view  returns (uint256 );
    function isInWhiteList        ( address _address           ) external view  returns (bool    );
    function ownerOf              ( uint256 _tokenId)            external view returns  (address );
}