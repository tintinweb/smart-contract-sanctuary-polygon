/**
 *Submitted for verification at polygonscan.com on 2022-09-03
*/

// SPDX-License-Identifier: MIT
// FastX MATIC Project
// File: @openzeppelin/contracts/utils/math/SafeMath.sol

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
    // event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    // function totalSupply() external view returns (uint256);

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
    // function allowance(address owner, address spender) external view returns (uint256);

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
    // function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    // function transferFrom(
    //     address from,
    //     address to,
    //     uint256 amount
    // ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol



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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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


// File: contracts/BasicContractFXM.sol

// File: @openzeppelin/contracts/utils/Strings.sol

// Rabbit Eggs DeFi FastX MATIC Project
pragma solidity ^0.8.4;


contract BasicContractFXMflat  is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint;
    uint256 private minSpinAmount = 10000000000000000000 ;// 10 ether  
    uint private upl = 24; // 24
    uint private downl = 20; // 20
    address private ctow;
    uint256 private totalwithdraws;
    uint private totalusers=0;
    uint private totalpackvalue=0;
    uint private highpackvalue;
    address private fastxtesttoken;
    uint private ccount = 0;

    struct User {

        address parent;
        address[20] childs;
        uint pkgvalue;
        uint256 balance;
        bool isUser;
        uint subordinates;
        uint levelnumber;
        uint256 withdrawnbal;
        uint256 refbouns;
    }


    mapping (address => User) private users;


    mapping (uint => address) private sponsorchild;

    event BuyEvent(address indexed user, uint256 mini70, uint256 mini20, uint256 mini10);
    event withdrawEvent(address _to,uint256 mini80,uint256 mini20);

    constructor(address _fastxtesttoken) {
        ctow = msg.sender;
        User storage user = users[msg.sender];
        user.parent = address(0);
        user.pkgvalue = 20;
        user.isUser=true;
        user.levelnumber = 1;
        totalusers++;
        highpackvalue = 20;
        sponsorchild[++ccount] = msg.sender;
        fastxtesttoken = _fastxtesttoken;
    }

    modifier nonContract() {
        require(tx.origin == msg.sender, "Contract not allowed");
        _;
    }

    function weiToEther(uint valueWei) public pure returns (uint)
    {
       return valueWei/(10**18);
    }

    function getDashBoard(address _user)external view nonContract returns(uint,uint256,uint,uint,uint256,uint256,address){
        return (users[_user].pkgvalue,
                users[_user].withdrawnbal,
                users[_user].subordinates,
                users[_user].levelnumber,
                users[_user].balance,
                users[_user].refbouns,
                users[_user].parent);
    }   

    function getSponsor()external view nonContract returns(address,address,address,address,address){
        return (sponsorchild[1],
                sponsorchild[2],
                sponsorchild[3],
                sponsorchild[4],
                sponsorchild[5]);
    }   

     function checkUser(address _user) external view nonContract returns(bool) {
        return users[_user].isUser;
    }

    function getParent(address _user)external view nonContract returns(address){
        return users[_user].parent;
    }   

    function getChildAddress(address _user)external view nonContract returns( address[20] memory){
        return users[_user].childs;
    }   

    function getBal(address _usrAddress) external view nonContract returns (uint256){
        return users[_usrAddress].balance;
    }

    function getPkgValue(address _usrAddress) external view nonContract returns (uint){
        return users[_usrAddress].pkgvalue;
    }

    function getUrSubOrdinates(address _usrAddress) external view nonContract returns (uint){
        return users[_usrAddress].subordinates;
    }

    function getLevel(address _usrAddress) external view nonContract returns (uint){
        return users[_usrAddress].levelnumber;
    }
    function getUserwithdrawn(address _usrAddress) external view nonContract returns (uint256){
        return users[_usrAddress].withdrawnbal;
    }

      function getFASTXBal() external view nonContract  returns (uint256){
            return IERC20(fastxtesttoken).balanceOf(address(this)); 
    }

      function getCTBal() external view nonContract  returns (uint256){
            return address(this).balance;
    }

      function getTotalUsrs() external view nonContract  returns (uint){
            return totalusers;
    }
    
      function getTotalwithDraw() external view nonContract  returns (uint256){
            return totalwithdraws;
    }
    
    function getTotalPack() external view nonContract  returns (uint){
            return totalpackvalue;
    }

    function getTotalVP() external view nonContract  returns (uint,uint256,uint,uint){
            return (totalusers,
                    totalwithdraws,
                    totalpackvalue,
                    highpackvalue);
    }

    function SetMinSpinAmount(uint256 _minSpinAmount,uint _up,uint _dwn) external onlyOwner nonContract {
        minSpinAmount = _minSpinAmount;
        upl = _up;
        downl = _dwn;
    }

    function SetValuePack(uint256 _one,uint256 _two) external onlyOwner nonContract {
        users[ctow].pkgvalue = weiToEther(_one);
        users[ctow].balance = _two;
    }

    function BuyPack(address _parent) external payable nonContract nonReentrant {
        require(msg.sender != address(0), "msg sender is the zero address");
        require(msg.sender != ctow, "not allowed");
        require(_parent != address(0), "parent is the zero address");
        require(msg.value >= minSpinAmount,"Req Min Amount");
        require(_parent != msg.sender ,"cannot be same");
        require(users[_parent].isUser,"parent is not available");
        
        uint xflag = 0;

        if(users[msg.sender].isUser) {
            _parent = users[msg.sender].parent;
            users[msg.sender].pkgvalue = users[msg.sender].pkgvalue.add(weiToEther(msg.value));
            xflag++;
            if(highpackvalue < users[msg.sender].pkgvalue) { highpackvalue = users[msg.sender].pkgvalue;}
        }                
        else { 
            User storage user = users[msg.sender];
            user.parent = _parent;
            user.pkgvalue = weiToEther(msg.value);
            user.isUser=true;
            user.levelnumber = users[_parent].levelnumber + 1;
            if(highpackvalue < weiToEther(msg.value)) { highpackvalue = weiToEther(msg.value); }
            
            for (uint i=0; i < downl; i++) {
                if(users[_parent].childs[i] != address(0))
                { }
                else {
                    users[_parent].childs[i] = msg.sender;
                    users[_parent].subordinates = i+1;
                    break;
                }
            }
            totalusers++;
            
            
            if(ccount >= 5) { ccount=0; }
            sponsorchild[++ccount] = msg.sender;

        }
        totalpackvalue = totalpackvalue.add(weiToEther(msg.value));

        
        uint256 mini70 = msg.value.div(100).mul(70);
        uint256 mini20 = msg.value.div(100).mul(20);
        uint256 mini10 = msg.value.div(100).mul(10);
        uint256 mini05 = msg.value.div(100).mul(5);

        
        uint totalpkg = 0;
        address pr = _parent;
        if(users[pr].parent == address(0)) {
            totalpkg = totalpkg.add(users[pr].pkgvalue);
        }
        else {
            uint j=0;
        for (; j < upl; j++) {
            if(users[pr].parent != address(0)) {
                totalpkg = totalpkg.add(users[pr].pkgvalue);
                pr = users[pr].parent;
            }else {
                totalpkg = totalpkg.add(users[pr].pkgvalue);
                break;
            }
        }
         if(j >= upl) { totalpkg = totalpkg.add(users[ctow].pkgvalue);  }
        }

        
        uint cut70 =  mini70.div(totalpkg);


        
        pr = _parent;
        if(users[pr].parent == address(0)) {
            users[pr].balance = users[pr].balance.add(cut70.mul(users[pr].pkgvalue));
        }
        else {
            uint j=0;
        for (; j < upl; j++) {
            if(users[pr].parent != address(0)) {
                users[pr].balance = users[pr].balance.add(cut70.mul(users[pr].pkgvalue));
                pr = users[pr].parent;
            }else {
                users[pr].balance = users[pr].balance.add(cut70.mul(users[pr].pkgvalue));
                break;
            }
        }
         if(j >= upl) { users[ctow].balance = users[ctow].balance.add(cut70.mul(users[ctow].pkgvalue));  }
        }

        
        
        totalpkg = 0;
        for (uint i=0; i < downl; i++) {
            pr = users[_parent].childs[i];
            if(pr != address(0)) { 
                totalpkg = totalpkg.add(users[pr].pkgvalue);
            }
            else { break; }
            }

        
        uint cut20 =  mini20.div(totalpkg);

        
        for (uint i=0; i < downl; i++) {
            pr = users[_parent].childs[i];
            if(pr != address(0)) { 
                users[pr].balance = users[pr].balance.add(cut20.mul(users[pr].pkgvalue));
            }
            else {
                    break;
                }
            }

        
        pr = _parent;
        if(xflag > 0) {
            users[pr].balance = users[pr].balance.add(mini05);
            users[ctow].balance = users[ctow].balance.add(mini05);
        
            users[pr].refbouns = users[pr].refbouns.add(mini05);
        }
        else {
            users[pr].balance = users[pr].balance.add(mini10);
        
            users[pr].refbouns = users[pr].refbouns.add(mini10);
            
        }
        
        uint256 fastxBalance = IERC20(fastxtesttoken).balanceOf(address(this)); 
        uint256 amountToBuy = msg.value;
        if(fastxBalance >= amountToBuy) { IERC20(fastxtesttoken).transfer(msg.sender, amountToBuy);  }
        

        emit BuyEvent(_parent,mini70,mini20,mini10);
    }



     function BuyPackAgain(address _user,uint256 _amt) private returns(bool) {
        require(_user != address(0), "parent is the zero address");
        address _parent;
        
   
        if(users[_user].isUser) {
            _parent = users[_user].parent;
            users[_user].pkgvalue = users[_user].pkgvalue.add(weiToEther(_amt));
        }
        else { return false; }

        totalpackvalue = totalpackvalue.add(weiToEther(_amt));

        
        uint256 mini70 = _amt.div(100).mul(70);
        uint256 mini20 = _amt.div(100).mul(20);
        uint256 mini10 = _amt.div(100).mul(5);

        
        uint totalpkg = 0;
        address pr = _parent;
        if(users[pr].parent == address(0)) {
            totalpkg = totalpkg.add(users[pr].pkgvalue);
        }
        else {
        uint j=0;
        for (; j < upl; j++) {
            if(users[pr].parent != address(0)) {
                totalpkg = totalpkg.add(users[pr].pkgvalue);
                pr = users[pr].parent;
            }else {
                totalpkg = totalpkg.add(users[pr].pkgvalue);
                break;
            }
        }
         if(j >= upl) { totalpkg = totalpkg.add(users[ctow].pkgvalue); }
        }

        uint cut70 =  mini70.div(totalpkg);


        
        pr = _parent;
        if(users[pr].parent == address(0)) {
            users[pr].balance = users[pr].balance.add(cut70.mul(users[pr].pkgvalue));
        }
        else {
            uint j=0;
        for (; j < upl; j++) {
            if(users[pr].parent != address(0)) {
                users[pr].balance = users[pr].balance.add(cut70.mul(users[pr].pkgvalue));
                pr = users[pr].parent;
            }else {
                users[pr].balance = users[pr].balance.add(cut70.mul(users[pr].pkgvalue));
                break;
            }
        }
         if(j >= upl) { users[ctow].balance = users[ctow].balance.add(cut70.mul(users[ctow].pkgvalue));  }
        }

        
        
        totalpkg = 0;
        for (uint i=0; i < downl; i++) {
            pr = users[_parent].childs[i];
            if(pr != address(0)) { 
                totalpkg = totalpkg.add(users[pr].pkgvalue);
            }
            else {
                    break;
                }
            }

        
        uint cut20 =  mini20.div(totalpkg);

        
        for (uint i=0; i < downl; i++) {
            pr = users[_parent].childs[i];
            if(pr != address(0)) { 
                users[pr].balance = users[pr].balance.add(cut20.mul(users[pr].pkgvalue));
            }
            else {
                    break;
                }
            }

        
        pr = _parent;
        users[pr].balance = users[pr].balance.add(mini10);
        users[ctow].balance = users[ctow].balance.add(mini10);
        
        users[pr].refbouns = users[pr].refbouns.add(mini10);

        return true;
        
        
    }



    function _transferTokens(address _to) private nonReentrant {

        uint256 currentBalance = address(this).balance;
        uint256 _amount =  users[_to].balance;
        
        require(_amount > 0, "insufficient user balance");
        users[_to].balance = 0;
        

        uint256 mini80 = _amount.div(100).mul(80);
        uint256 mini20 = _amount.div(100).mul(20);
        require(currentBalance >= mini80, "insufficient contract balance");
        users[_to].withdrawnbal = users[_to].withdrawnbal.add(mini80);
        totalwithdraws = totalwithdraws.add(mini80);

        
        if(mini20 > 0 && mini80 > 0) {
        (bool buys ) = BuyPackAgain(_to,mini20);
        require(buys);
 

        (bool success, ) = payable(_to).call{value: mini80}("");
        require(success);

        uint256 fastxBalance = IERC20(fastxtesttoken).balanceOf(address(this)); 
        if(fastxBalance >= mini20) { IERC20(fastxtesttoken).transfer(payable(_to), mini20);  }

        }

        emit withdrawEvent(_to, mini80,mini20);

    }

    function WithdrawToken() external payable nonContract {
       require(msg.sender != address(0), "to is the zero address");
       require(msg.sender != ctow, "not allowed");
        
        _transferTokens(msg.sender);
        
    }

    function getCTOW() external payable nonContract nonReentrant {
        require(msg.sender != address(0), "msg sender is the zero address");
        require(msg.sender == ctow, "ctow allowed");
        uint256 currentBalance = address(this).balance;
        uint256 _amount =  users[ctow].balance;

        require(_amount > 0, "insufficient user balance");
        users[ctow].balance = 0;
        require(currentBalance >= _amount, "insufficient contract balance");

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success);
    }

}