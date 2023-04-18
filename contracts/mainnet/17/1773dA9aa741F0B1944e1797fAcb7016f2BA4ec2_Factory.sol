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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./game.sol";

contract Factory {
  address public tokenAddress;

  address public ownerAddress;
  address public comissionAddress;

  mapping(address => address[]) public userPools;

  event PoolCreated(address indexed newGame);

  struct poolResults {
    address poolAddress;
    string[] firstPlaces;
    string[] secondPlaces; 
    string[] firstPlacesUsernames;
    string[] secondPlacesUsernames;  
  } 

  constructor(address _tokenAddress, address _comissionAddress) {
    require(_tokenAddress != address(0), "invalid token address");
    tokenAddress = _tokenAddress;
    comissionAddress = _comissionAddress;
    ownerAddress = msg.sender;
  }

  modifier onlyOwner(){
    require(msg.sender == ownerAddress, "You do not have an access");
    _;
  }

  function createPool(
    string calldata _poolName,
    string calldata _poolLeague,
    uint256 _entryAmount,
    bool _isPoolPublic,
    uint256 _maxParticipants,
    string memory _creatorId
  ) public returns (address) {
    Game game = new Game(
      _poolName,
      _poolLeague,
      _entryAmount,
      _isPoolPublic,
      _maxParticipants,
      _creatorId,
      msg.sender,
      tokenAddress,
      comissionAddress
    );
    IERC20 tokenInterface = IERC20(tokenAddress);
    require(
      tokenInterface.allowance(msg.sender, address(this)) >= _entryAmount,
      "Contract is not authorized to spend user's tokens"
    );
    require(
      tokenInterface.transferFrom(msg.sender, address(game), _entryAmount),
      "Transfer failed"
    );

    userPools[msg.sender].push(address(game));

    emit PoolCreated(address(game));

    return address(game);
  }

  function getUserPools(address user) public view returns (address[] memory) {
    return userPools[user];
  }

  function returnFunds(address[] calldata pools) public onlyOwner{
    for(uint i = 0; i < pools.length; i++){
        if(pools[i] == address(0) || Game(pools[i]).participantsAmount() > 1){
          continue;
        }

        Game(pools[i]).returnFunds();
    }
  }

  function distributePrizes(poolResults[] calldata pools) public onlyOwner{
    for(uint i = 0; i < pools.length; i++){
        if(pools[i].poolAddress == address(0)){
          continue;
        }

        Game(pools[i].poolAddress).result(pools[i].firstPlaces, pools[i].secondPlaces, pools[i].firstPlacesUsernames, pools[i].secondPlacesUsernames);
    }
  }

  function setComissionAddess(address newAddress) public onlyOwner{
    comissionAddress = newAddress;
  }

  function setOwner(address newAddress) public onlyOwner{
    ownerAddress = newAddress;
  }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Game {

  using SafeMath for uint256;

  string public poolName;
  string public poolLeague;
  uint public entryAmount;
  bool public isPoolPublic;

  mapping (string => address) public participants;
  uint public maxParticipants;
  uint public participantsAmount;

  address public tokenAddress;
  address public factoryAddress;
  address public comissionAddress;

  address public poolCreatorAddress;
  string public poolCreatorId;

  string[] firstPlacesUsernames;
  string[] secondPlacesUsernames;  

  event PoolCreated(
    string poolName,
    string poolLeague,
    uint entryAmount,
    bool isPoolPublic,
    uint maxParticipants,
    address poolCreatorAddress,
    address tokenAddress
  );

  event Transfer(
    address from,
    address to,
    uint256 amount
  );

  event Participate(
    address user,
    address pool
  );

  constructor(string memory _poolName,  string memory _poolLeague,  uint _entryAmount,  bool _isPoolPublic,  uint _maxParticipants, string memory _poolCreatorId, address _poolCreatorAddress, address _tokenAddress, address _comissionAddress){
    poolName = _poolName;
    poolLeague = _poolLeague;
    entryAmount = _entryAmount;
    isPoolPublic = _isPoolPublic;
    maxParticipants = _maxParticipants;
    poolCreatorAddress = _poolCreatorAddress;
    factoryAddress = msg.sender;
    tokenAddress = _tokenAddress;
    comissionAddress = _comissionAddress;
    poolCreatorId = _poolCreatorId;
    participants[_poolCreatorId] = _poolCreatorAddress;
    participantsAmount = 1;

    emit PoolCreated(_poolName, _poolLeague, _entryAmount, _isPoolPublic, _maxParticipants, _poolCreatorAddress, _tokenAddress);
  }

  modifier checkMaxParticipants(){
    require(participantsAmount < maxParticipants, "Pool is full");
    _;
  }

  modifier onlyFactory(){
    require(msg.sender == factoryAddress, "You do not have an access");
    _;
  }

  modifier enoughFunds(){
     require(IERC20(tokenAddress).balanceOf(msg.sender) > entryAmount, "You do not have enough funds to enter the pool");
    _;
  }

  modifier alreadyParticipate(string memory playerId){
    require(participants[playerId] == address(0), "You have already joined");
    _;
   
  }

  function participate(string memory playerId) public payable alreadyParticipate(playerId) checkMaxParticipants enoughFunds{
     require(
      IERC20(tokenAddress).allowance(msg.sender, address(this)) >= entryAmount,
      "Contract is not authorized to spend user's tokens"
    );
    require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), entryAmount));

    emit Transfer(msg.sender, address(this), entryAmount);
    emit Participate(msg.sender, address(this));

    participants[playerId] = msg.sender;
    participantsAmount++;
  }
 
  function getParticipate(string memory playerId) public view returns (address){
    return participants[playerId];
  }

  function getParticipantsAmount() public view returns (uint256){ 
    return participantsAmount;
  }

  function result(string[] memory firstPlacesIds, string[] memory secondPlacesIds, string[] memory _firstPlacesUsernames, string[] memory _secondPlacesUsernames) external onlyFactory {

    uint256 poolTotalSupply = IERC20(tokenAddress).balanceOf(address(this));
    uint256 firstPlacesReward = poolTotalSupply.mul(75).div(100) / firstPlacesIds.length;
    uint256 secondPlacesReward = poolTotalSupply.mul(10).div(100) / secondPlacesIds.length;

    for(uint i = 0; i < firstPlacesIds.length; i++){
        if(participants[firstPlacesIds[i]] == address(0)){
          continue;
        }

        require(IERC20(tokenAddress).transfer(participants[firstPlacesIds[i]], firstPlacesReward));
        emit Transfer(address(this), participants[firstPlacesIds[i]], firstPlacesReward);
    }
  
    for(uint i = 0; i < secondPlacesIds.length; i++){
        if(participants[secondPlacesIds[i]] == address(0)){
          continue;
        }

        require(IERC20(tokenAddress).transfer(participants[secondPlacesIds[i]], secondPlacesReward));
        emit Transfer(address(this), participants[secondPlacesIds[i]], secondPlacesReward);
    }

    firstPlacesUsernames = _firstPlacesUsernames;
    secondPlacesUsernames = _secondPlacesUsernames; 

    require(IERC20(tokenAddress).transfer(comissionAddress, IERC20(tokenAddress).balanceOf(address(this))));
    emit Transfer(address(this), comissionAddress, IERC20(tokenAddress).balanceOf(address(this)));
  }

  function returnFunds() external payable onlyFactory{
    require(IERC20(tokenAddress).transfer(poolCreatorAddress, IERC20(tokenAddress).balanceOf(address(this))));
    emit Transfer(address(this), poolCreatorAddress, IERC20(tokenAddress).balanceOf(address(this)));
  }
}