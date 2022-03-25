/**
 *Submitted for verification at polygonscan.com on 2022-03-25
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

// File: @openzeppelin/contracts/utils/Context.sol



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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/activity/lion/StablePool.sol


pragma solidity 0.8.0;



interface ILion {
    function mintLion(address _owner,uint256 amount) external;
}

/**
   _____ _        _     _      _____            _ 
  / ____| |      | |   | |    |  __ \          | |
 | (___ | |_ __ _| |__ | | ___| |__) |__   ___ | |
  \___ \| __/ _` | '_ \| |/ _ \  ___/ _ \ / _ \| |
  ____) | || (_| | |_) | |  __/ |  | (_) | (_) | |
 |_____/ \__\__,_|_.__/|_|\___|_|   \___/ \___/|_|
                                                  
 */
contract StablePool is Ownable,ReentrancyGuard{
    event Subscribe(address _owner,uint32 _pool,uint256 _amount);
    event Withdraw(address _owner,uint32 _pool,uint256 _count,uint256 _amount);
    event BuyNft(address _owner,uint32 _pool,uint256 _count);
    using SafeMath for uint256;
    mapping(uint32 =>mapping(address => uint256)) public _deposits;
    mapping(uint32 => uint256) poolSizes;
    mapping(uint32 => uint256) poolCounts;
    mapping(uint32 => uint256) poolTargets;
    uint256 public price1;
    uint256 public price2;
    uint256 public maxBuySize = 10;
    uint256 one = 1000000;
    mapping(address => uint256) public buyCounts;
    uint256 public startTime;
    uint256 public pool1;
    uint256 public pool2;

    uint256 public endTime;
    uint256 public buyTime;

    ILion iLion;

    constructor (ILion _iLion,
                uint256 _startTime,
                uint256 _t1,uint256 _t2,
                uint256 _p1,uint256 _p2,
                uint256 _pool1,uint256 _pool2){
        iLion = _iLion;
        startTime = _startTime;
        poolTargets[1] = _t1;
        poolTargets[2] = _t2;
        price1 = _p1;
        price2 = _p2;
        pool1 = _pool1;
        pool2 = _pool2;
        poolCounts[1] = pool1;
        poolCounts[2] = pool2;
        endTime = startTime.add(259200);
        buyTime = endTime.add(172800);
    }

    modifier notContract() {
      require(tx.origin == msg.sender, "Call is contract");
      _;
    }

    function setTime(uint256 _startTime, uint256 _endTime, uint256 _buyTime) external onlyOwner{
      startTime = _startTime;
      endTime = _endTime;
      buyTime = _buyTime;
    } 

    function getTime() public view returns(uint256,uint256,uint256){
      return(startTime,endTime,buyTime);
    }

    function getInitPoolCount() external view returns(uint256,uint256){
      return(pool1,pool2);
    }

    function getPoolTargets() external view returns(uint256,uint256){
      return(poolTargets[1],poolTargets[2]);
    }

    function getPoolCount() external view returns(uint256,uint256){
      return(poolCounts[1],poolCounts[2]);
    }

    function deposits(address account) external view returns (uint256,uint256) {
      return (_deposits[1][account].mul(price1),_deposits[2][account].mul(price2));
    }

    function poolSize() external view returns(uint256,uint256){
      return (poolSizes[1],poolSizes[2]);
    }

    function getPrice(uint32 _pool,uint256 _portion) public view returns(uint256){
      require(_pool==1||_pool==2, "Pool error");
      if(_pool==1){
        return (_portion.mul(price1));
      }else{
        return (_portion.mul(price2));
      }
    }

    function subscribe(uint32 _pool,uint256 _portion) external payable notContract nonReentrant{
      require(_pool==1||_pool==2, "Pool error");
      //add end time
      require(block.timestamp>=startTime,"Not start");
      require(block.timestamp<endTime,"Has end");
      require(_deposits[_pool][msg.sender].add(_portion) <= (_pool==1?1:10),"Over max size");
      uint256 price = getPrice(_pool,_portion);
      require(msg.value == price && price > 0,"Portion amount or price error");
      //user
      _deposits[_pool][msg.sender] = _deposits[_pool][msg.sender].add(_portion);
      //total
      poolSizes[_pool] = poolSizes[_pool].add(_portion.mul(getUintCount(_pool)));
      if(_pool==1){
        require(poolSizes[_pool]<=poolTargets[_pool],"Pool 1 over target");
      }else{
        // 25% over limit
        require(poolSizes[_pool]<=poolTargets[_pool].mul(125).div(100),"25% over target");
      }
      emit Subscribe(msg.sender,_pool,_portion);
    }

    function getUintCount(uint32 _pool) internal view returns(uint256){
      return _pool==1?price1:price2;
    }

    function withdraw(uint32 _pool) external notContract nonReentrant{
      require(_pool==1||_pool==2, "Pool error");
      require(block.timestamp>=endTime,"Stake not end");
      require(block.timestamp<buyTime,"Has end");
      (uint256 _count,uint256 _amount) = getOwnerAmount(_pool,msg.sender);
      require(_deposits[_pool][msg.sender]>0,"Has mint or not player");
      require(poolCounts[_pool] >= _count,"Mint over");
      if(_count!=0){
        //mint nft
        poolCounts[_pool] = poolCounts[_pool].sub(_count);
        iLion.mintLion(msg.sender,_count);
      }
      //has mint
      _deposits[_pool][msg.sender] = 0;
      if(_amount!=0){
        payable(msg.sender).transfer(_amount);
      }
      emit Withdraw(msg.sender,_pool,_count,_amount);
    }

    function buyNft(uint256 _count) external payable notContract nonReentrant{
      require(block.timestamp>=buyTime,"Not start");
      require(buyCounts[msg.sender].add(_count)<=maxBuySize,"Over max size");
      buyCounts[msg.sender] = buyCounts[msg.sender].add(_count);
      uint32 _pool;
      if(poolCounts[1]>0){
        _pool = 1;
      }else if(poolCounts[2]>0){
        _pool = 2;
      }else{
        require(false,"No more nft");
      }
      poolCounts[_pool] = poolCounts[_pool].sub(_count);
      iLion.mintLion(msg.sender,_count);
      emit BuyNft(msg.sender,_pool,_count);
    }

    function getOwnerAmount(uint32 _pool, address _owner) public view returns(uint256,uint256){
      uint256 _portion = _deposits[_pool][_owner];
      if(_portion==0){
        return(0,0);
      }
      if(_pool==1){
        //less per/total*por
        return getPool(_pool,50,pool1,_portion);
      }else{
        //less per/total*por
        return getPool(_pool,1,pool2,_portion);
      }
    }

    function getPool(uint32 _pool,uint256 _base,uint256 _supply,uint256 _portion) public view returns(uint256, uint256){
      if(poolSizes[_pool]<=poolTargets[_pool]){
        //*10
        uint256 targetCount = price2.mul(10).mul(_base).mul(_supply).div(poolSizes[_pool]);
        // div 10
        return (_portion.mul(targetCount).div(10),0);
      }else {
        //over 0~25%
        uint256 subSize = poolSizes[_pool].sub(poolTargets[_pool]);
        uint256 percentCount = subSize.mul(one).div(poolTargets[_pool]);
        uint256 currentPrice = price2.mul(one.sub(percentCount)).div(one);
        uint256 subPrice = price2.sub(currentPrice);
        if(poolCounts[_pool]==0){
          //reback all
          return (0,_portion.mul(price2));
        }else if(poolCounts[_pool]<_portion){
          //pool 2 not enough(happen over target size)
          uint256 _count = poolCounts[_pool];
          return (_count,_count.mul(subPrice).add(price2.mul(_portion.sub(_count))));
        }else{
          return (_portion,_portion.mul(subPrice));
        }
      }
    }

    function withdrawCoin() external onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed.");
    }

    receive () external payable {}
}