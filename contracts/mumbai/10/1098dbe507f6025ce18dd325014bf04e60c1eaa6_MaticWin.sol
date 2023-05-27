/**
 *Submitted for verification at polygonscan.com on 2023-05-27
*/

//SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
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



interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract AddressChecker {
    function isContract(address _address) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_address) }
        return size > 0;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}




contract MaticWin is ReentrancyGuard , AddressChecker ,Context{
   

    using SafeMath for uint256; 
    address payable internal owner;



    constructor() 
    {
        owner = payable(_msgSender());
        // Referrals[_msgSender()].upline = (_msgSender());
        Pool_UserAddress.push(owner);
        Pool_Referral[owner].upline = owner;        
    }


    modifier onlyOwner() 
    {
        require(_msgSender()==owner, "Only Call by Owner");
        _;
    }


    struct upline 
    {
        address  upline;
        uint256  referrals;
        uint40   deposittime;
        uint256  direct;
        address lastupline;
        uint256 poolIncome;
        uint256 LevelIncome;
        uint256 TeamIncome;
        uint256 Userincome;
        uint256 RewardIncome;
    }
        struct UplineIncome 
    {
        uint40  [] Deposittime;
        uint256 [] Amount;
        uint256 [] dailyReward;
        uint256 totalWithdrawReward;
    }

    struct data 
    {
        bool ActiveID;
        address  upline;
        uint40  [] deposit_time;
        uint256 [] amount_Pool_A;
        uint256 amount_Pool_B;
        uint256 [] depositAmount;
        uint256 [] PerdayReward;
        uint256 totalWithdrawReward;
        uint256 withdrawableReward;
    }

            struct user {
        uint256 Deposittime;
        uint256 amount;
        address L1;
        address L2;
        address L3;
        address L4;
        address L5;
        address L6;
        address L7;
    }
     struct User_team
     {
        address L8;
        address L9;
        address L10;
        address L11;
        address L12;
        address L13;
        address L14;
        address L15;
     }

    mapping(address => upline) public Pool_Referral;
    // mapping(address => upline) public Referrals;
    mapping(address => data) public User;
    mapping(address => user) public Pool_User;
    mapping(address => User_team) public Pool_User_team;
    mapping(address => UplineIncome) public sponsorIncome;
    mapping(address => address[]) public check_Ref_address;
    
    
    address [] public Pool_UserAddress;
    uint256 public Pool_ActiveID = 0;
    uint256 internal withdrawTime = 1 minutes;
    uint256 internal Upline_totaldays = 8;
    uint256 internal selfincome_totaldays = 10;
    uint256 public total_Pool_User;


//...............................................................................................30 of tree.................................................
    function Pool_setUpline(address _addr, address payable _upline) internal {
        if(Pool_Referral[_addr].upline == address(0) && _upline != _addr && _addr != owner && (Pool_Referral[_upline].deposittime > 0 || _upline == owner)) {
            Pool_Referral[_addr].upline = _upline;
            Pool_Referral[_upline].referrals++;
            total_Pool_User++;
        }
    }
      function Pool_IsUpline( address _upline) public view returns(bool status)
    {
        if(Pool_Referral[msg.sender].upline == address(0) && _upline != msg.sender && msg.sender != owner && (Pool_Referral[_upline].deposittime > 0 || _upline == owner)) 
        {
            status = true;  
        }
        return status;
    }
      function Pool_ChakUpline( address _upline) public view returns(address add)
    {
        return Pool_Referral[_upline].upline;
    }

          function Pool_checkrefList() public view returns(address[] memory)
    {
        return Pool_UserAddress;
    }

          function Pool_Last_Ref() public view returns(address add)
    {
        return Pool_UserAddress[Pool_ActiveID];
    }
    function Pool_check_Direct(address add) public view returns(address,address,address)
    {  
        return (check_Ref_address[add][0],check_Ref_address[add][1],check_Ref_address[add][2]);
    }
     


    function Register(address _upline,uint256 _payableamount)   external 
    {
         require(_payableamount % 25 ether == 0 , "Invalid amount");
         require(Pool_IsUpline(_upline) == true , "upline not found");
         require(User[msg.sender].ActiveID == false , "you are registered");

         uint256 pkgNo = _payableamount/25 ether;

//......................................................................................Sponsor.........................................................
        Pool_Referral[_upline].TeamIncome += _payableamount;
        Pool_Referral[msg.sender].Userincome += _payableamount;

        for(uint256 i=0; i<pkgNo;i++)
        {
        address getaddress = Pool_Last_Ref();
        if(Pool_Referral[getaddress].direct <  3)
            {
                Pool_setUpline(msg.sender, payable(getaddress));
                Pool_Referral[getaddress].direct += 1;
                Pool_UserAddress.push(msg.sender);
                check_Ref_address[getaddress].push(msg.sender);
            }
        else
            {
                Pool_ActiveID++;
                getaddress = Pool_Last_Ref();
                Pool_setUpline(msg.sender, payable(getaddress));
                Pool_Referral[getaddress].direct += 1;
                Pool_UserAddress.push(msg.sender);   
                check_Ref_address[getaddress].push(msg.sender);          
            }
             Pool_Referral[msg.sender].deposittime = uint40(block.timestamp);
        }

//......................................................................................uplineIncome..............................................
         sponsorIncome[_upline].Deposittime.push( uint40(block.timestamp));
         sponsorIncome[_upline].Amount.push();
         sponsorIncome[_upline].dailyReward.push(_payableamount.div(Upline_totaldays));

//................................................................................................user Data.............................................
         User[_msgSender()].ActiveID = true;
//.................................................................................................self income....................................................
         User[_msgSender()].amount_Pool_A.push(_payableamount*200/100);
         User[_msgSender()].depositAmount.push(_payableamount);
         User[_msgSender()].amount_Pool_B += _payableamount*300/100;
         User[_msgSender()].PerdayReward.push((_payableamount*200/100)/selfincome_totaldays);
         User[_msgSender()].deposit_time.push(uint40(block.timestamp));




        // ........................................................................................Sponsor Income.....................................................................
        Pool_User[msg.sender].L1 = Pool_ChakUpline(msg.sender);
        if(Pool_User[msg.sender].L2 != owner)
        {
            Pool_User[msg.sender].L2 = Pool_ChakUpline(Pool_User[msg.sender].L1);
        }
        else{
            Pool_User[msg.sender].L2 = owner;
        }
        if(Pool_User[msg.sender].L2 != owner)
        {
            Pool_User[msg.sender].L3 = Pool_ChakUpline(Pool_User[msg.sender].L2);
        }
        else{
            Pool_User[msg.sender].L3 = owner;
        }
        if(Pool_User[msg.sender].L3 != owner)
        {
            Pool_User[msg.sender].L4 = Pool_ChakUpline(Pool_User[msg.sender].L3);
        }
        else{
            Pool_User[msg.sender].L4 = owner;
        }        
        if(Pool_User[msg.sender].L4 != owner)
        {
            Pool_User[msg.sender].L5 = Pool_ChakUpline(Pool_User[msg.sender].L4);
        }
        else{
            Pool_User[msg.sender].L5 = owner;
        } 
        if(Pool_User[msg.sender].L5 != owner)
        {
            Pool_User[msg.sender].L6 = Pool_ChakUpline(Pool_User[msg.sender].L5);
        }
        else{
            Pool_User[msg.sender].L6 = owner;
        } 
        if(Pool_User[msg.sender].L6 != owner)
        {
            Pool_User[msg.sender].L7 = Pool_ChakUpline(Pool_User[msg.sender].L6);
        }
        else{
            Pool_User[msg.sender].L7 = owner;
        }
        if(Pool_User[msg.sender].L7 != owner)
        {
            Pool_User_team[msg.sender].L8 = Pool_ChakUpline(Pool_User[msg.sender].L7);
        }
        else{
            Pool_User_team[msg.sender].L8 = owner;
        }
        if(Pool_User_team[msg.sender].L8 != owner)
        {
            Pool_User_team[msg.sender].L9 = Pool_ChakUpline(Pool_User_team[msg.sender].L8);
        }
        else{
            Pool_User_team[msg.sender].L9 = owner;
        }
        if(Pool_User_team[msg.sender].L9 != owner)
        {
            Pool_User_team[msg.sender].L10 = Pool_ChakUpline(Pool_User_team[msg.sender].L9);
        }
        else{
            Pool_User_team[msg.sender].L10 = owner;
        }
        if(Pool_User_team[msg.sender].L11 != owner)
        {
            Pool_User_team[msg.sender].L11 = Pool_ChakUpline(Pool_User_team[msg.sender].L10);
        }
        else{
            Pool_User_team[msg.sender].L11 = owner;
        }
        if(Pool_User_team[msg.sender].L12 != owner)
        {
            Pool_User_team[msg.sender].L12 = Pool_ChakUpline(Pool_User_team[msg.sender].L11);
        }
        else{
            Pool_User_team[msg.sender].L12 = owner;
        }
        if(Pool_User_team[msg.sender].L13 != owner)
        {
            Pool_User_team[msg.sender].L13 = Pool_ChakUpline(Pool_User_team[msg.sender].L12);
        }
        else{
            Pool_User_team[msg.sender].L13 = owner;
        }   
        if(Pool_User_team[msg.sender].L14 != owner)
        {
            Pool_User_team[msg.sender].L14 = Pool_ChakUpline(Pool_User_team[msg.sender].L13);
        }
        else{
            Pool_User_team[msg.sender].L14 = owner;
        }
        if(Pool_User_team[msg.sender].L15 != owner)
        {
            Pool_User_team[msg.sender].L15 = Pool_ChakUpline(Pool_User_team[msg.sender].L14);
        }
        else{
            Pool_User_team[msg.sender].L15 = owner;
        }                  

//............................................................................transfer pool income...............................
        Pool_Referral[Pool_User[msg.sender].L1].poolIncome+= 1 ether;
        Pool_Referral[Pool_User[msg.sender].L2].poolIncome+= 1 ether;
        if(Pool_Referral[Pool_User[msg.sender].L3].direct <  2)
        {
          Pool_Referral[Pool_User[msg.sender].L3].poolIncome+= 1 ether;
        }
        if(Pool_Referral[Pool_User[msg.sender].L4].direct <  5)
        {
          Pool_Referral[Pool_User[msg.sender].L4].poolIncome+= 2 ether;
        }
        User[_msgSender()].amount_Pool_B -= 6 ether;

        
//.....................................................................................Reward Income.......................................

        if(Pool_Referral[msg.sender].TeamIncome >= 2500000 ether && Pool_Referral[msg.sender].Userincome >= 50000)
        {
            Pool_Referral[msg.sender].RewardIncome += 100000 ether;
        }
        else if (Pool_Referral[msg.sender].TeamIncome >= 1000000 ether && Pool_Referral[msg.sender].Userincome >= 25000)
        {
            Pool_Referral[msg.sender].RewardIncome += 50000 ether;
        }
        else if (Pool_Referral[msg.sender].TeamIncome >= 500000 ether && Pool_Referral[msg.sender].Userincome >= 20000)
        {
            Pool_Referral[msg.sender].RewardIncome += 25000 ether;
        }        
        else if (Pool_Referral[msg.sender].TeamIncome >= 250000 ether && Pool_Referral[msg.sender].Userincome >= 10000)
        {
            Pool_Referral[msg.sender].RewardIncome += 12500 ether;
        }  
        else if (Pool_Referral[msg.sender].TeamIncome >= 150000 ether && Pool_Referral[msg.sender].Userincome >= 7500)
        {
            Pool_Referral[msg.sender].RewardIncome += 7500 ether;
        }
        else if (Pool_Referral[msg.sender].TeamIncome >= 100000 ether && Pool_Referral[msg.sender].Userincome >= 5000)
        {
            Pool_Referral[msg.sender].RewardIncome += 5000 ether;
        }
        else if (Pool_Referral[msg.sender].TeamIncome >= 75000 ether && Pool_Referral[msg.sender].Userincome >= 3500)
        {
            Pool_Referral[msg.sender].RewardIncome += 3500 ether;
        }
        else if (Pool_Referral[msg.sender].TeamIncome >= 50000 ether && Pool_Referral[msg.sender].Userincome >= 2500)
        {
            Pool_Referral[msg.sender].RewardIncome += 2500 ether;
        }
        else if (Pool_Referral[msg.sender].TeamIncome >= 20000 ether && Pool_Referral[msg.sender].Userincome >= 1000)
        {
            Pool_Referral[msg.sender].RewardIncome += 1000 ether;
        }
        else if (Pool_Referral[msg.sender].TeamIncome >= 5000 ether && Pool_Referral[msg.sender].Userincome >= 250)
        {
            Pool_Referral[msg.sender].RewardIncome += 250 ether;
        }
    } 


    function invest(uint256 _payableamount)  external 
    {
         require(User[_msgSender()].ActiveID == true , "you are not register");
         require( _payableamount % 25 ether ==0 , "Invalid amount");
         User[_msgSender()].amount_Pool_A.push(_payableamount*200/100);
         User[_msgSender()].amount_Pool_B += _payableamount*300/100;
         User[_msgSender()].deposit_time.push(uint40(block.timestamp));
         User[_msgSender()].depositAmount.push(_payableamount);
          User[_msgSender()].PerdayReward.push((_payableamount*200/100)/selfincome_totaldays);


//.....................................................................................Reward Income..........................................

        if(Pool_Referral[msg.sender].TeamIncome >= 2500000 ether && Pool_Referral[msg.sender].Userincome >= 50000)
        {
            Pool_Referral[msg.sender].RewardIncome += 100000 ether;
        }
        else if (Pool_Referral[msg.sender].TeamIncome >= 1000000 ether && Pool_Referral[msg.sender].Userincome >= 25000)
        {
            Pool_Referral[msg.sender].RewardIncome += 50000 ether;
        }
        else if (Pool_Referral[msg.sender].TeamIncome >= 500000 ether && Pool_Referral[msg.sender].Userincome >= 20000)
        {
            Pool_Referral[msg.sender].RewardIncome += 25000 ether;
        }        
        else if (Pool_Referral[msg.sender].TeamIncome >= 250000 ether && Pool_Referral[msg.sender].Userincome >= 10000)
        {
            Pool_Referral[msg.sender].RewardIncome += 12500 ether;
        }  
        else if (Pool_Referral[msg.sender].TeamIncome >= 150000 ether && Pool_Referral[msg.sender].Userincome >= 7500)
        {
            Pool_Referral[msg.sender].RewardIncome += 7500 ether;
        }
        else if (Pool_Referral[msg.sender].TeamIncome >= 100000 ether && Pool_Referral[msg.sender].Userincome >= 5000)
        {
            Pool_Referral[msg.sender].RewardIncome += 5000 ether;
        }
        else if (Pool_Referral[msg.sender].TeamIncome >= 75000 ether && Pool_Referral[msg.sender].Userincome >= 3500)
        {
            Pool_Referral[msg.sender].RewardIncome += 3500 ether;
        }
        else if (Pool_Referral[msg.sender].TeamIncome >= 50000 ether && Pool_Referral[msg.sender].Userincome >= 2500)
        {
            Pool_Referral[msg.sender].RewardIncome += 2500 ether;
        }
        else if (Pool_Referral[msg.sender].TeamIncome >= 20000 ether && Pool_Referral[msg.sender].Userincome >= 1000)
        {
            Pool_Referral[msg.sender].RewardIncome += 1000 ether;
        }
        else if (Pool_Referral[msg.sender].TeamIncome >= 5000 ether && Pool_Referral[msg.sender].Userincome >= 250)
        {
            Pool_Referral[msg.sender].RewardIncome += 250 ether;
        }          
    } 



    function checkReward(address add,uint256 index) public view returns(uint256 reward,bool status)
    {
        uint256 totalreward;
        uint256 timeofdeposit;

            totalreward = User[add].amount_Pool_A[index];
            timeofdeposit = (uint256(block.timestamp).sub(User[add].deposit_time[index])).div(withdrawTime);
            if(timeofdeposit < selfincome_totaldays)
            {
            reward += timeofdeposit.mul(User[add].PerdayReward[index]);
            }
            else
            {
                reward += selfincome_totaldays.mul(User[add].PerdayReward[index]);
                status = true;
            }
        
        return (reward,status);
    }
    function SponsorReward(address add , uint256 _index) public view returns(uint256 reward ,bool status)
    {
        uint256 totalreward;
        uint256 timeofdeposit;        
        uint256 a = sponsorIncome[add].Amount.length;
        for(uint256 i=0; i < a ; i++ )
        {
            totalreward = sponsorIncome[add].Amount[_index];
            timeofdeposit = (uint256(block.timestamp).sub(sponsorIncome[add].Deposittime[_index])).div(withdrawTime);
                        if(timeofdeposit < selfincome_totaldays)
            {
            reward += timeofdeposit.mul(sponsorIncome[add].dailyReward[_index]);
            }
            else
            {
                reward += Upline_totaldays.mul(sponsorIncome[add].dailyReward[_index]);
                status = true;
            }
            
        }
        return (reward,status);
    }

    function WithdrawSelfAmount(uint256 _index) external
    {
        (uint256 R,bool S) = checkReward(msg.sender,_index);

        require(S == true ,"error");
        // require(R <= address(this).balance,"balance low");
        // payable(msg.sender).transfer(R);
        User[msg.sender].totalWithdrawReward +=_index;
        User[_msgSender()].amount_Pool_B.sub(R);


       uint256 a = User[_msgSender()].depositAmount[_index];

        if(Pool_Referral[Pool_User[msg.sender].L1].direct >= 1)
        {
          Pool_Referral[Pool_User[msg.sender].L1].LevelIncome+= a*15/100;
        }
        if(Pool_Referral[Pool_User[msg.sender].L2].direct >= 2)
        {
          Pool_Referral[Pool_User[msg.sender].L2].LevelIncome+= a*10/100;
        }
        if(Pool_Referral[Pool_User[msg.sender].L3].direct >= 3)
        {
          Pool_Referral[Pool_User[msg.sender].L3].LevelIncome+= a*8/100;
        }
        if(Pool_Referral[Pool_User[msg.sender].L4].direct >= 4)
        {
          Pool_Referral[Pool_User[msg.sender].L4].LevelIncome+= a*8/100;
        }
        if(Pool_Referral[Pool_User[msg.sender].L5].direct >= 5)
        {
          Pool_Referral[Pool_User[msg.sender].L5].LevelIncome+= a*8/100;
        }
        if(Pool_Referral[Pool_User[msg.sender].L6].direct >= 6)
        {
          Pool_Referral[Pool_User[msg.sender].L6].LevelIncome+= a*7/100;
        }                        

        if(Pool_Referral[Pool_User[msg.sender].L7].direct >= 7)
        {
          Pool_Referral[Pool_User[msg.sender].L7].LevelIncome+= a*7/100;
        }
        if(Pool_Referral[Pool_User_team[msg.sender].L8].direct >= 8)
        {
          Pool_Referral[Pool_User_team[msg.sender].L8].LevelIncome+= a*7/100;
        }
        if(Pool_Referral[Pool_User_team[msg.sender].L9].direct >= 9)
        {
          Pool_Referral[Pool_User_team[msg.sender].L9].LevelIncome+= a*7/100;
        }
        if(Pool_Referral[Pool_User_team[msg.sender].L10].direct >= 10)
        {
          Pool_Referral[Pool_User_team[msg.sender].L10].LevelIncome+= a*10/100;
        }
        if(Pool_Referral[Pool_User_team[msg.sender].L11].direct >= 11)
        {
          Pool_Referral[Pool_User_team[msg.sender].L11].LevelIncome+= a*10/100;
        }
        if(Pool_Referral[Pool_User_team[msg.sender].L12].direct >= 12)
        {
          Pool_Referral[Pool_User_team[msg.sender].L12].LevelIncome+= a*10/100;
        }
        if(Pool_Referral[Pool_User_team[msg.sender].L13].direct >= 13)
        {
          Pool_Referral[Pool_User_team[msg.sender].L13].LevelIncome+= a*10/100;
        }
        if(Pool_Referral[Pool_User_team[msg.sender].L14].direct >= 14)
        {
          Pool_Referral[Pool_User_team[msg.sender].L14].LevelIncome+= a*10/100;
        }
        if(Pool_Referral[Pool_User_team[msg.sender].L15].direct >= 15)
        {
          Pool_Referral[Pool_User_team[msg.sender].L15].LevelIncome+= a*10/100;
        }

        User[_msgSender()].amount_Pool_B.sub(137 ether);

            for(uint i = _index; i <  User[msg.sender].amount_Pool_A.length - 1; i++) 
    {
      User[msg.sender].amount_Pool_A[i] = User[msg.sender].amount_Pool_A[i + 1];
      User[msg.sender].PerdayReward[i] = User[msg.sender].PerdayReward[i + 1];
      User[msg.sender].deposit_time[i] = User[msg.sender].deposit_time[i + 1];
      User[msg.sender].depositAmount[i] = User[msg.sender].depositAmount[i + 1];
    }
     
    User[msg.sender].amount_Pool_A.pop();
    User[msg.sender].PerdayReward.pop();
    User[msg.sender].deposit_time.pop();
    User[msg.sender].depositAmount.pop();
        

    }




//............................................................................................Sponsor used..................................


    function withdrawSponsor(uint256 _index) external
    {
        (uint256 R,bool s) = SponsorReward(msg.sender,_index);
        // require(_index <= address(this).balance,"balance low");
        require(s == true,"error");
        // payable(msg.sender).transfer(R);
        sponsorIncome[msg.sender].totalWithdrawReward +=_index; 
        User[_msgSender()].amount_Pool_B.sub(R);

    for(uint i = _index; i <  sponsorIncome[msg.sender].Deposittime.length - 1; i++) 
    {
      sponsorIncome[msg.sender].Deposittime[i] = sponsorIncome[msg.sender].Deposittime[i + 1];
      sponsorIncome[msg.sender].Amount[i] = sponsorIncome[msg.sender].Amount[i + 1];
      sponsorIncome[msg.sender].dailyReward[i] = sponsorIncome[msg.sender].dailyReward[i + 1];
    }
      sponsorIncome[msg.sender].Deposittime.pop();
      sponsorIncome[msg.sender].Amount.pop();
      sponsorIncome[msg.sender].dailyReward.pop();
    }







    function withDraw (uint256 _amount) onlyOwner external nonReentrant
    {
        require(isContract(msg.sender) == false ,"this is contract");
        payable(msg.sender).transfer(_amount);
    }

        function changeOwner (address payable _add) onlyOwner external nonReentrant
    {
        require(isContract(msg.sender) == false ,"this is contract");
        owner = _add;
    }








//..................................................................sponsor..................................................................
      function Check_Profit_income( address _upline) public view returns(uint256 [] memory PoolA,uint256 PoolB,uint256  [] memory perdayAmount)
    {
        return (User[_upline].amount_Pool_A ,User[_upline].amount_Pool_B,User[_upline].PerdayReward);
    }
    function raferralIncome(address _add)  public view returns (uint256 [] memory)
    {
        return User[_add].PerdayReward;
    }

}