// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*
██╗███╗   ██╗███████╗██╗      ██████╗ ██╗    ██╗
██║████╗  ██║██╔════╝██║     ██╔═══██╗██║    ██║
██║██╔██╗ ██║█████╗  ██║     ██║   ██║██║ █╗ ██║
██║██║╚██╗██║██╔══╝  ██║     ██║   ██║██║███╗██║
██║██║ ╚████║██║     ███████╗╚██████╔╝╚███╔███╔╝
╚═╝╚═╝  ╚═══╝╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝ 

@creator:     Inflow Token
@security:    [email protected]
@website:     https://www.inflowtoken.io/

*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Marketplace is ReentrancyGuard,Ownable {
    


    IERC20 private _token;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    // reward pool fee 

    // toplam tutar 100 u tamamlamalı
    uint256  public influencer_direct_share= 600;
    uint256  public community_reward_share = 175;
    uint256  public staking_reward_share = 175;
    uint256  public maintenance_fee_share = 25;
    uint256  public vault_share = 25;

    // pools
    // temporarily made public
    uint256 public community_reward_pool = 0; // 500 FLW
    uint256 public staking_reward_pool = 0; // 900 FLW
    uint256 public maintenance_fee_pool = 0; // 1000 FLW
    uint256 public vault_pool = 0;


    constructor() {}

    
    enum Status{
       PENDING,    
       ACCEPTED,    // Accepted by influencer.
       REJECTED    // Rejected by influencer
    }

    // influencer items 
    mapping(uint256 => Item) public items;
    
    struct Item {  
        uint256 price;
        address influencer;
        bool status; // item status
    }


    // influencer list
    mapping(address => bool) public influencers;
    mapping(address => bool) private admins;
    
    // influencer treasury
    mapping(address => uint256) public influencer_community_rewards;

    // buyer
    mapping(uint256 => Buyer) public buyer;
    struct Buyer{
        address buyer;
        uint256 itemId;
    }
    

    // sale history 
    uint256 public historyId = 0;

    mapping(uint256 => History) public history;
    struct History{
        uint256 itemId;
        address influencer;
        address buyer;
        uint256 amount;
        Status status;
    }
    
   
    //modifier 
    modifier onlyInfluencerOrAdmin {
        require(influencers[_msgSender()] == true || admins[_msgSender()] == true  || _msgSender() == owner(), "Only influencer, admin or owner can call this function.");
        _;
    }

    modifier onlyAdminOrOwner {
        require(admins[_msgSender()] == true || _msgSender() == owner(), "Only admin or owner can call this function.");
        _;
    }
    


    // event
    event changeStatus(address influencer,address buyer, uint256 item, Status status);
    event buyEngagement( address influencer,address buyer, uint256 item, uint256 price, uint256 historyId);
    event rejectEngagement(address influencer, address buyer, uint256 item, uint256 price);
    event acceptEngagement(address influencer,address buyer, uint256 item, uint256 price);

    /* @dev Set erc20 token interface 
     * @param _address Erc20 token address.
     */
    function setErc20 (address _address) public onlyOwner {
      _token = IERC20(_address);
    }

    
    function buy(uint256 _itemId, address _influencer) public returns(uint256){
    
        require(influencers[_influencer] == true , "Influencer is not active");

        require(_token.allowance(_msgSender(), address(this)) >= items[_itemId].price,"Marketplace has not enough allowance to complete exchange.");
        require(_token.balanceOf(_msgSender()) >= items[_itemId].price,"Buyer has not enough balance to complete this.");

        (bool sent) =  _token.transferFrom(_msgSender(), address(this), items[_itemId].price);

        require(sent, "Failed to transfer tokens from user to contract");

        

        history[historyId] = History(_itemId, _influencer, _msgSender(), items[_itemId].price, Status.PENDING);
        buyer[historyId] = Buyer(_msgSender(),_itemId);

        emit buyEngagement(_msgSender(),_influencer, _itemId, items[_itemId].price,(historyId));

        historyId += 1;

        return (historyId-1);
    }


    function approveTransaction(uint256 _historyId) public onlyInfluencerOrAdmin {
        
        require(history[_historyId].status == Status.PENDING, "Status is not Pending");

        require(_msgSender() == history[_historyId].influencer || _msgSender() == owner(), "Only influencer or owner approve this transaction");

        history[_historyId].status = Status.ACCEPTED;

        emit changeStatus( _msgSender(), history[_historyId].buyer, history[_historyId].itemId, history[_historyId].status);

        // send token balance pool variable

        //send 0.6 influencer
        uint256 _influencer_amount = (history[_historyId].amount * influencer_direct_share) / 1000; // %60

        require(_influencer_amount > 0, "Influencer amount must be greater than 0");

        _token.transfer(_msgSender(), _influencer_amount);


        // pools
        // vesting contract -> history[_historyId].amount set 12 VO.

        //if(community_reward_pool < 200000000 * 1e18){

        uint256 community_transaction_value = ((history[_historyId].amount * community_reward_share) / 1000 ) + (history[_historyId].amount / 5);
        community_reward_pool = community_reward_pool + community_transaction_value; // %17.5 + %20 extra
        //}

        staking_reward_pool = staking_reward_pool +  (history[_historyId].amount * staking_reward_share) / 1000 + (history[_historyId].amount / 10);  // %17.5 + %10 extra
        maintenance_fee_pool = maintenance_fee_pool + (history[_historyId].amount * maintenance_fee_share) / 1000 ; 


        vault_pool = vault_pool + (history[_historyId].amount * vault_share) / 1000; // %2.5
        
        history[_historyId].status = Status.ACCEPTED;

        // calculate influencer community treasury
        influencer_community_rewards[history[_historyId].influencer] = influencer_community_rewards[history[_historyId].influencer] + community_transaction_value;
        
    
        emit acceptEngagement(_msgSender(), history[_historyId].buyer, history[_historyId].itemId, history[_historyId].amount);
    }


    function rejectTransaction(uint256 _historyId) public onlyInfluencerOrAdmin{
        
        require(history[_historyId].status == Status.PENDING, "Status is not Pending");
        
        emit changeStatus( _msgSender(), history[_historyId].buyer, history[_historyId].itemId, history[_historyId].status);
        
        (bool sent) =  _token.transfer(history[_historyId].buyer, history[_historyId].amount);

        require(sent, "Failed to transfer tokens from contract to user");
        
        history[_historyId].amount = 0; 
        history[_historyId].status = Status.REJECTED;

        emit rejectEngagement(_msgSender(), history[_historyId].buyer, history[_historyId].itemId, history[_historyId].amount);
        
    }


    // item id si backenden gelmeli            
    function addOrUpdateItem(uint256 _itemId, uint256 _price, address _influencer, bool _status) public onlyAdminOrOwner{
        items[_itemId] = Item(_price, _influencer, _status);
    }

    function addOrUpdateInfluencer(address _address, bool _status) public onlyAdminOrOwner {
        influencers[_address] = _status;
    }

    function addOrUpdateAdmin(address _address, bool _status) public onlyOwner {
        admins[_address] = _status;
    }

    function setInfluencerTreasury(address influencer, uint256 _amount) public onlyAdminOrOwner{
        if(community_reward_pool == 0){
            influencer_community_rewards[influencer] = 0;
        }
        else{
            community_reward_pool = community_reward_pool - influencer_community_rewards[influencer];
            influencer_community_rewards[influencer] = _amount;
            if(_amount > 0){
                community_reward_pool = community_reward_pool + _amount;
            }
        }
    }

    function setInfluencerDirectShare(uint256 _share) public onlyAdminOrOwner{
        influencer_direct_share = _share;
    }

    function setCommunityRewardShare(uint256 _share) public onlyAdminOrOwner {
        community_reward_share = _share;
    }

    function setStakingRewardShare(uint256 _share) public onlyAdminOrOwner{
        staking_reward_share = _share;
    }

    function setMaintenanceFeeShare(uint256 _share) public onlyAdminOrOwner {
        maintenance_fee_share = _share;
    }

    function setVaultShare(uint256 _share) public onlyAdminOrOwner {
        vault_share = _share;
    }


    function resetCommunityRewardPool() public onlyAdminOrOwner{
            community_reward_pool = 0;
    }

    function resetStakingRewardPool() public onlyAdminOrOwner{
            staking_reward_pool = 0;
    }

    function resetMaintenanceFeePool() public onlyAdminOrOwner{
            maintenance_fee_pool = 0;
    }

    function resetVaultPool() public onlyAdminOrOwner{
            vault_pool = 0;
    }

    function withdrawToken(uint256 amount) public nonReentrant onlyOwner {
        require(
            _token.balanceOf(address(this)) >= amount,
            "not enough withdrawable funds"
        );
        _token.transfer(owner(), amount);
    }

    function withdrawMatic() public nonReentrant onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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