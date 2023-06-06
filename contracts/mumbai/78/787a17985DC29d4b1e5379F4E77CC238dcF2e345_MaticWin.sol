/**
 *Submitted for verification at polygonscan.com on 2023-06-05
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
    // IERC20  public Token; 
    address payable public owner;



    constructor() 
    {
        owner = payable(_msgSender());
        Silver_UserAddress.push(owner);
        silver_Referral[owner].upline = owner;       

        Gold_UserAddress.push(owner);
        Gold_Referral[owner].upline = owner;  

        platinum_UserAddress.push(owner);
        platinum_Referral[owner].upline = owner;  


        diamond_UserAddress.push(owner);
        diamond_Referral[owner].upline = owner;   
        
        Global_Referral[owner].upline = owner;
              
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
        uint256 poolIncome;
        uint256 LevelIncome;
        uint256 TeamIncome;
        uint256 Userincome;
        uint256 RewardIncome;
        uint256 Three_directincome;
        uint256 Nine_directincome;
        uint256 twenty_seven_directincome;
        uint256 eighty_one;
    }
        struct UplineIncome 
    {
        uint40  [] Deposittime;
        uint256 [] Amount;
        uint256 [] dailyReward;
        uint256 totalWithdrawReward;
        uint256 [] withdrawReward;
        address [] SponsorId;
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
        uint256 [] withdrawReward;
        uint256 totalWithdrawReward;
        string  Status;
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
     struct Status_
     {
         bool round1;
         bool round2;
         bool round3;
         bool round4;
         bool round5;
         bool round6;
         bool round7;
         bool round8;
         bool round9;
         bool round10;
         
         
     }

    mapping(address => upline) public silver_Referral;
    mapping(address => upline) public Gold_Referral;
    mapping(address => upline) public platinum_Referral;
    mapping(address => upline) public diamond_Referral;
    mapping(address => upline) public Global_Referral;
    mapping(address => data) public User;
    mapping(address => user) public Pool_User;
    mapping(address => User_team) public Pool_User_team;
    mapping(address => UplineIncome) public sponsorIncome;
    mapping(address => address[]) public check_Silver_address;
    mapping(address => address[]) public check_Gold_address;
    mapping(address => address[]) public check_platinum_address;
    mapping(address => address[]) public check_diamond_address;
    mapping(address => uint256) public Wallet;
    mapping(address => Status_) public RewardIncome;
    
    
    address [] private Silver_UserAddress;
    address [] private Gold_UserAddress;
    address [] private platinum_UserAddress;
    address [] private diamond_UserAddress;
    uint256 private Silver_ActiveID = 0;
    uint256 private Gold_ActiveID = 0;
    uint256 private platinum_ActiveID = 0;
    uint256 private diamond_ActiveID = 0;
    uint256 private withdrawTime = 1 minutes;
    uint256 private Upline_totaldays = 400 ;
    uint256 private selfincome_totaldays = 200 ;
    uint256 private total_Pool_User;
    uint256 private total_Pool2_User;
    uint256 private total_Pool3_User;
    uint256 private total_Pool4_User;
    uint256 private total_Global_User;

    function Check_Total_User() public view returns(uint256 Silver,uint256 Gold , uint256 platinum,uint256 diamond ,uint256 total_Global)
   {
       return(total_Pool_User,total_Pool2_User,total_Pool3_User,total_Pool4_User,total_Global_User);
   }
    function checkrefList() public view returns(address[] memory Silver,address[] memory Gold,address[] memory platinum,address[] memory diamond)
    {
        return (Silver_UserAddress,Gold_UserAddress,platinum_UserAddress,diamond_UserAddress);
    }





    function CheckStatus(address add) public view returns(string memory _Status)
    {
        if(diamond_IsUpline(add) == true)
        {
            _Status = "diamond";
        }
        else if(platinum_IsUpline(add) == true)
        {
           _Status = "platinum"; 
        }
        else if(Gold_IsUpline(add) == true)
        {
           _Status = "Gold"; 
        }
        else if(silver_IsUpline(add) == true)
        {
           _Status = "Silver"; 
        }   
        return _Status;   
    }





//...............................................................................................Gernal pool......................
  function Global_setUpline(address _addr, address payable _upline) internal {
        if(Global_Referral[_addr].upline == address(0) && _upline != _addr && _addr != owner && (Global_Referral[_upline].deposittime > 0 || _upline == owner)) {
            Global_Referral[_addr].upline = _upline;
            Global_Referral[_upline].referrals++;
            total_Global_User++;
        }
    }
      function Global_IsUpline( address _upline) public view returns(bool status)
    {
        if(Global_Referral[msg.sender].upline == address(0) && _upline != msg.sender && msg.sender != owner && (Global_Referral[_upline].deposittime > 0 || _upline == owner)) 
        {
            status = true;  
        }
        return status;
    }
      function Global_ChakUpline( address _upline) public view returns(address add)
    {
        return Global_Referral[_upline].upline;
    }



//...............................................................................................1st of tree.................................................
    function silver_setUpline(address _addr, address payable _upline) internal {
        if(silver_Referral[_addr].upline == address(0) && _upline != _addr && _addr != owner && (silver_Referral[_upline].deposittime > 0 || _upline == owner)) {
            silver_Referral[_addr].upline = _upline;
            silver_Referral[_upline].referrals++;
            total_Pool_User++;
        }
    }
      function silver_IsUpline( address _upline) public view returns(bool status)
    {
        if(silver_Referral[msg.sender].upline == address(0) && _upline != msg.sender && msg.sender != owner && (silver_Referral[_upline].deposittime > 0 || _upline == owner)) 
        {
            status = true;  
        }
        return status;
    }
      function silver_ChakUpline( address _upline) public view returns(address add)
    {
        return silver_Referral[_upline].upline;
    }
          function Silver_Last_Ref() public view returns(address add)
    {
        return Silver_UserAddress[Silver_ActiveID];
    }

    function Pool_check_Direct(address add) public view returns(address,address,address)
    {  
        return (check_Silver_address[add][0],check_Silver_address[add][1],check_Silver_address[add][2]);
    }








//..................................................................................................second pool.....................................



  function Gold_setUpline(address _addr, address payable _upline) internal {
        if(Gold_Referral[_addr].upline == address(0) && _upline != _addr && _addr != owner && (Gold_Referral[_upline].deposittime > 0 || _upline == owner)) {
            Gold_Referral[_addr].upline = _upline;
            Gold_Referral[_upline].referrals++;
            total_Pool2_User++;
        }
    }
      function Gold_IsUpline( address _upline) public view returns(bool status)
    {
        if(Gold_Referral[msg.sender].upline == address(0) && _upline != msg.sender && msg.sender != owner && (Gold_Referral[_upline].deposittime > 0 || _upline == owner)) 
        {
            status = true;  
        }
        return status;
    }
      function Gold_ChakUpline( address _upline) public view returns(address add)
    {
        return Gold_Referral[_upline].upline;
    }

          function Gold_Last_Ref() public view returns(address add)
    {
        return Gold_UserAddress[Gold_ActiveID];
    }




    function pool2(address add) internal 
    {
            address getaddress = Gold_Last_Ref();
        if(Gold_Referral[getaddress].direct <  9)
            {
                Gold_setUpline(add, payable(getaddress));
                Gold_Referral[getaddress].direct += 1;
                Gold_UserAddress.push(add);
                check_Gold_address[getaddress].push(add);
            }
        else
            {
                Gold_Referral[getaddress].Nine_directincome += 40 ether;
                Wallet[getaddress] += 40 ether;
                pool3(getaddress); 
                Gold_ActiveID++;
                getaddress = Gold_Last_Ref();
                Gold_setUpline(add, payable(getaddress));
                Gold_Referral[getaddress].direct = 1;
                Gold_UserAddress.push(add);   
                check_Gold_address[getaddress].push(add);          
            }
             Gold_Referral[add].deposittime = uint40(block.timestamp);   
    }




//.............................................................................................third pool ........................................................................


    function platinum_setUpline(address _addr, address payable _upline) internal {
        if(platinum_Referral[_addr].upline == address(0) && _upline != _addr && _addr != owner && (platinum_Referral[_upline].deposittime > 0 || _upline == owner)) {
            platinum_Referral[_addr].upline = _upline;
            platinum_Referral[_upline].referrals++;
            total_Pool3_User++;
        }
    }
      function platinum_IsUpline( address _upline) public view returns(bool status)
    {
        if(platinum_Referral[msg.sender].upline == address(0) && _upline != msg.sender && msg.sender != owner && (platinum_Referral[_upline].deposittime > 0 || _upline == owner)) 
        {
            status = true;  
        }
        return status;
    }
      function platinum_ChakUpline( address _upline) public view returns(address add)
    {
        return platinum_Referral[_upline].upline;
    }


          function platinum_Last_Ref() public view returns(address add)
    {
        return platinum_UserAddress[platinum_ActiveID];
    }

    function pool3(address add) internal 
    {
            address getaddress = platinum_Last_Ref();
        if(platinum_Referral[getaddress].direct <  27)
            {
                platinum_setUpline(add, payable(getaddress));
                platinum_Referral[getaddress].direct += 1;
                platinum_UserAddress.push(add);
                check_platinum_address[getaddress].push(add);
            }
        else
            {
                platinum_Referral[getaddress].twenty_seven_directincome += 350 ether;
                Wallet[getaddress] += 350 ether;
                pool5(getaddress); 
                platinum_ActiveID++;
                getaddress = platinum_Last_Ref();
                platinum_setUpline(add, payable(getaddress));
                platinum_Referral[getaddress].direct = 1;
                platinum_UserAddress.push(add);   
                check_platinum_address[getaddress].push(add);          
            }
             platinum_Referral[add].deposittime = uint40(block.timestamp);   
    }







//.....................................................................................................pool five...............................................................
    function diamond_setUpline(address _addr, address payable _upline) internal {
        if(diamond_Referral[_addr].upline == address(0) && _upline != _addr && _addr != owner && (diamond_Referral[_upline].deposittime > 0 || _upline == owner)) {
            diamond_Referral[_addr].upline = _upline;
            diamond_Referral[_upline].referrals++;
            total_Pool4_User++;
        }
    }
      function diamond_IsUpline( address _upline) public view returns(bool status)
    {
        if(diamond_Referral[msg.sender].upline == address(0) && _upline != msg.sender && msg.sender != owner && (diamond_Referral[_upline].deposittime > 0 || _upline == owner)) 
        {
            status = true;  
        }
        return status;
    }
      function diamond_ChakUpline( address _upline) public view returns(address add)
    {
        return diamond_Referral[_upline].upline;
    }


          function diamond_Last_Ref() public view returns(address add)
    {
        return diamond_UserAddress[diamond_ActiveID];
    }




    function pool5(address add) internal 
    {
            address getaddress = diamond_Last_Ref();
        if(diamond_Referral[getaddress].direct <  81)
            {
                diamond_setUpline(add, payable(getaddress));
                diamond_Referral[getaddress].direct += 1;
                diamond_UserAddress.push(add);
                check_diamond_address[getaddress].push(add);
            }
        else
            {
                diamond_Referral[getaddress].eighty_one += 81000 ether;
                Wallet[getaddress] += 81000 ether;
                diamond_ActiveID++;
                getaddress = diamond_Last_Ref();
                diamond_setUpline(add, payable(getaddress));
                diamond_Referral[getaddress].direct = 1;
                diamond_UserAddress.push(add);   
                check_diamond_address[getaddress].push(add);          
            }
             diamond_Referral[add].deposittime = uint40(block.timestamp);   
    }








    function Register(address _upline,uint256 _payableamount)   external 
    {
         require(_payableamount % 25 ether == 0 , "Invalid amount");
         require(silver_IsUpline(_upline) == true , "upline not found");
         require(Global_IsUpline(_upline) == true , "upline not found");
         require(User[msg.sender].ActiveID == false , "you are registered");

         uint256 pkgNo = _payableamount/25 ether;
         silver_Referral[_upline].direct += 1;
         Global_setUpline(msg.sender,payable(_upline));
         Global_Referral[msg.sender].deposittime = uint40(block.timestamp);

//......................................................................................Sponsor.........................................................
        silver_Referral[_upline].TeamIncome += _payableamount;
        silver_Referral[msg.sender].Userincome += _payableamount;

        for(uint256 i=0; i<pkgNo;i++)
        {
        address getaddress = Silver_Last_Ref();
        if(silver_Referral[getaddress].direct <  3)
            {
                silver_setUpline(msg.sender, payable(getaddress));
                silver_Referral[getaddress].direct += 1;
                Silver_UserAddress.push(msg.sender);
                check_Silver_address[getaddress].push(msg.sender);
            }
        else
            {
                silver_Referral[getaddress].Three_directincome += 5 ether;
                Wallet[getaddress] += 5 ether;
                pool2(getaddress); 
                Silver_ActiveID++;
                getaddress = Silver_Last_Ref();
                silver_setUpline(msg.sender, payable(getaddress));
                silver_Referral[getaddress].direct = 1;
                Silver_UserAddress.push(msg.sender);   
                check_Silver_address[getaddress].push(msg.sender);          
            }
             silver_Referral[msg.sender].deposittime = uint40(block.timestamp);
             
        }

//......................................................................................uplineIncome..............................................
         sponsorIncome[_upline].Deposittime.push( uint40(block.timestamp));
         sponsorIncome[_upline].Amount.push(_payableamount*100/100);
         sponsorIncome[_upline].dailyReward.push(_payableamount.div(Upline_totaldays));
         sponsorIncome[_upline].withdrawReward.push(0);
         sponsorIncome[_upline].SponsorId.push(msg.sender);

//................................................................................................user Data.............................................
         User[_msgSender()].ActiveID = true;
         User[msg.sender].upline = _upline;
//.................................................................................................self income....................................................
         
         User[_msgSender()].amount_Pool_A.push(_payableamount*200/100);
         User[_msgSender()].depositAmount.push(_payableamount);
         User[_msgSender()].amount_Pool_B += _payableamount*300/100;
         User[_msgSender()].PerdayReward.push((_payableamount*200/100)/selfincome_totaldays);
         User[_msgSender()].deposit_time.push(uint40(block.timestamp));
         User[_msgSender()].withdrawReward.push(0);




        // ........................................................................................Sponsor Income.....................................................................
        Pool_User[msg.sender].L1 = Global_ChakUpline(msg.sender);
        if(Pool_User[msg.sender].L2 != owner)
        {
            Pool_User[msg.sender].L2 = Global_ChakUpline(Pool_User[msg.sender].L1);
        }
        else{
            Pool_User[msg.sender].L2 = owner;
        }
        if(Pool_User[msg.sender].L2 != owner)
        {
            Pool_User[msg.sender].L3 = Global_ChakUpline(Pool_User[msg.sender].L2);
        }
        else{
            Pool_User[msg.sender].L3 = owner;
        }
        if(Pool_User[msg.sender].L3 != owner)
        {
            Pool_User[msg.sender].L4 = Global_ChakUpline(Pool_User[msg.sender].L3);
        }
        else{
            Pool_User[msg.sender].L4 = owner;
        }        
        if(Pool_User[msg.sender].L4 != owner)
        {
            Pool_User[msg.sender].L5 = Global_ChakUpline(Pool_User[msg.sender].L4);
        }
        else{
            Pool_User[msg.sender].L5 = owner;
        } 
        if(Pool_User[msg.sender].L5 != owner)
        {
            Pool_User[msg.sender].L6 = Global_ChakUpline(Pool_User[msg.sender].L5);
        }
        else{
            Pool_User[msg.sender].L6 = owner;
        } 
        if(Pool_User[msg.sender].L6 != owner)
        {
            Pool_User[msg.sender].L7 = Global_ChakUpline(Pool_User[msg.sender].L6);
        }
        else{
            Pool_User[msg.sender].L7 = owner;
        }
        if(Pool_User[msg.sender].L7 != owner)
        {
            Pool_User_team[msg.sender].L8 = Global_ChakUpline(Pool_User[msg.sender].L7);
        }
        else{
            Pool_User_team[msg.sender].L8 = owner;
        }
        if(Pool_User_team[msg.sender].L8 != owner)
        {
            Pool_User_team[msg.sender].L9 = Global_ChakUpline(Pool_User_team[msg.sender].L8);
        }
        else{
            Pool_User_team[msg.sender].L9 = owner;
        }
        if(Pool_User_team[msg.sender].L9 != owner)
        {
            Pool_User_team[msg.sender].L10 = Global_ChakUpline(Pool_User_team[msg.sender].L9);
        }
        else{
            Pool_User_team[msg.sender].L10 = owner;
        }
        if(Pool_User_team[msg.sender].L11 != owner)
        {
            Pool_User_team[msg.sender].L11 = Global_ChakUpline(Pool_User_team[msg.sender].L10);
        }
        else{
            Pool_User_team[msg.sender].L11 = owner;
        }
        if(Pool_User_team[msg.sender].L12 != owner)
        {
            Pool_User_team[msg.sender].L12 = Global_ChakUpline(Pool_User_team[msg.sender].L11);
        }
        else{
            Pool_User_team[msg.sender].L12 = owner;
        }
        if(Pool_User_team[msg.sender].L13 != owner)
        {
            Pool_User_team[msg.sender].L13 = Global_ChakUpline(Pool_User_team[msg.sender].L12);
        }
        else{
            Pool_User_team[msg.sender].L13 = owner;
        }   
        if(Pool_User_team[msg.sender].L14 != owner)
        {
            Pool_User_team[msg.sender].L14 = Global_ChakUpline(Pool_User_team[msg.sender].L13);
        }
        else{
            Pool_User_team[msg.sender].L14 = owner;
        }
        if(Pool_User_team[msg.sender].L15 != owner)
        {
            Pool_User_team[msg.sender].L15 = Global_ChakUpline(Pool_User_team[msg.sender].L14);
        }
        else{
            Pool_User_team[msg.sender].L15 = owner;
        }                  
        
//.....................................................................................Reward Income.......................................
          rewardIncome(msg.sender);
       
    } 


    function rewardIncome(address add) private
    {
         if(silver_Referral[add].TeamIncome >= 2500000 ether && silver_Referral[add].Userincome >= 50000)
        {
            silver_Referral[add].RewardIncome += 100000 ether;
            Wallet[add] += 100000 ether;
            User[_msgSender()].amount_Pool_B = User[_msgSender()].amount_Pool_B.sub(100000 ether);
            RewardIncome[_msgSender()].round10 = true;
        }
        else if (silver_Referral[add].TeamIncome >= 1000000 ether && silver_Referral[add].Userincome >= 25000)
        {
            silver_Referral[add].RewardIncome += 50000 ether;
            Wallet[add] += 50000 ether;
            User[_msgSender()].amount_Pool_B = User[_msgSender()].amount_Pool_B.sub(50000 ether);
            RewardIncome[_msgSender()].round9 = true;
        }
        else if (silver_Referral[add].TeamIncome >= 500000 ether && silver_Referral[add].Userincome >= 20000)
        {
            silver_Referral[add].RewardIncome += 25000 ether;
            Wallet[add] += 25000 ether;
            User[_msgSender()].amount_Pool_B = User[_msgSender()].amount_Pool_B.sub(25000 ether);
            RewardIncome[_msgSender()].round8 = true;
        }        
        else if (silver_Referral[add].TeamIncome >= 250000 ether && silver_Referral[add].Userincome >= 10000)
        {
            silver_Referral[add].RewardIncome += 12500 ether;
            Wallet[add] += 12500 ether;
            User[_msgSender()].amount_Pool_B = User[_msgSender()].amount_Pool_B.sub(12500 ether);
            RewardIncome[_msgSender()].round7 = true;
        }  
        else if (silver_Referral[add].TeamIncome >= 150000 ether && silver_Referral[add].Userincome >= 7500)
        {
            silver_Referral[add].RewardIncome += 7500 ether;
            Wallet[add] += 7500 ether;
            User[_msgSender()].amount_Pool_B = User[_msgSender()].amount_Pool_B.sub(7500 ether);
            RewardIncome[_msgSender()].round6 = true;
        }
        else if (silver_Referral[add].TeamIncome >= 100000 ether && silver_Referral[add].Userincome >= 5000)
        {
            silver_Referral[add].RewardIncome += 5000 ether;
            Wallet[add] += 5000 ether;
            User[_msgSender()].amount_Pool_B = User[_msgSender()].amount_Pool_B.sub(5000 ether);
            RewardIncome[_msgSender()].round5 = true;
        }
        else if (silver_Referral[add].TeamIncome >= 75000 ether && silver_Referral[add].Userincome >= 3500)
        {
            silver_Referral[add].RewardIncome += 3500 ether;
            Wallet[add] += 3500 ether;
            User[_msgSender()].amount_Pool_B = User[_msgSender()].amount_Pool_B.sub(3500 ether);
            RewardIncome[_msgSender()].round4 = true;
        }
        else if (silver_Referral[add].TeamIncome >= 50000 ether && silver_Referral[add].Userincome >= 2500)
        {
            silver_Referral[add].RewardIncome += 2500 ether;
            Wallet[add] += 2500 ether;
            User[_msgSender()].amount_Pool_B = User[_msgSender()].amount_Pool_B.sub(2500 ether);
            RewardIncome[_msgSender()].round3 = true;
        }
        else if (silver_Referral[add].TeamIncome >= 20000 ether && silver_Referral[add].Userincome >= 1000)
        {
            silver_Referral[add].RewardIncome += 1000 ether;
            Wallet[add] += 1000 ether;
            User[_msgSender()].amount_Pool_B = User[_msgSender()].amount_Pool_B.sub(1000 ether);
            RewardIncome[_msgSender()].round2 = true;
        }
        else if (silver_Referral[add].TeamIncome >= 5000 ether && silver_Referral[add].Userincome >= 250)
        {
            silver_Referral[add].RewardIncome += 250 ether;
            Wallet[add] += 250 ether;
            User[_msgSender()].amount_Pool_B = User[_msgSender()].amount_Pool_B.sub(250 ether);
            RewardIncome[_msgSender()].round1 = true;

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
         silver_Referral[User[msg.sender].upline].TeamIncome += _payableamount;
         silver_Referral[msg.sender].Userincome += _payableamount;
         User[_msgSender()].withdrawReward.push(0);

        uint256 pkgNo = _payableamount/25 ether;

        for(uint256 i=0; i<pkgNo;i++)
        {
        address getaddress = Silver_Last_Ref();
        if(silver_Referral[getaddress].direct <  3)
            {
                silver_setUpline(msg.sender, payable(getaddress));
                silver_Referral[getaddress].direct += 1;
                Silver_UserAddress.push(msg.sender);
                check_Silver_address[getaddress].push(msg.sender);
            }
        else
            {
                silver_Referral[getaddress].Three_directincome += 5 ether;
                Wallet[getaddress] += 5 ether;
                pool2(getaddress); 
                Silver_ActiveID++;
                getaddress = Silver_Last_Ref();
                silver_setUpline(msg.sender, payable(getaddress));
                silver_Referral[getaddress].direct = 1;
                Silver_UserAddress.push(msg.sender);   
                check_Silver_address[getaddress].push(msg.sender);          
            }
             silver_Referral[msg.sender].deposittime = uint40(block.timestamp);
        }

//.....................................................................................Reward Income..........................................
        rewardIncome(msg.sender);
    } 



    function CheckDetails(address add,uint256 index) public view returns(uint256 Amount,uint256 depositTime,uint256 dailyReward,uint256 WithdrawReward)
    {
        return(User[add].depositAmount[index], User[add].deposit_time[index],User[add].PerdayReward[index],User[add].withdrawReward[index]);
    }

    function checkReward(address add,uint256 index) public view returns(uint256 reward)
    {
        
       uint256 depositTime = (uint256(block.timestamp).sub(User[add].deposit_time[index])).div(withdrawTime);
        if(depositTime < selfincome_totaldays)
        {
            reward += (depositTime.mul(User[add].PerdayReward[index]));
        }
        else
        {
            reward += (selfincome_totaldays.mul(User[add].PerdayReward[index])).sub(User[add].withdrawReward[index]);
        }
        return (reward);
    }



    function SponsorReward(address add,uint256 index) public view returns(uint256 reward)
    {
        uint256 timeofdeposit;
        timeofdeposit = (uint256(block.timestamp).sub(sponsorIncome[add].Deposittime[index])).div(withdrawTime);
        if(timeofdeposit < selfincome_totaldays)
        {
            reward = (timeofdeposit.mul(sponsorIncome[add].dailyReward[index])).sub(sponsorIncome[add].withdrawReward[index]);
        }
        else
        {
            reward = (selfincome_totaldays.mul(sponsorIncome[add].dailyReward[index])).sub(sponsorIncome[add].withdrawReward[index]);
        }
        return (reward);
    }



    function WithdrawSelfAmount(uint256 _index) external
    {
        uint256 R = checkReward(msg.sender,_index);

        require(R >= 0 ,"error");
        // require(R <= address(this).balance,"balance low");
        // payable(msg.sender).transfer(R);
        User[msg.sender].totalWithdrawReward +=R;
        User[_msgSender()].amount_Pool_B =  User[_msgSender()].amount_Pool_B.sub(R);
        User[_msgSender()].withdrawReward[_index] += R;
        

        if(silver_Referral[Pool_User[msg.sender].L1].direct >= 1)
        {
          silver_Referral[Pool_User[msg.sender].L1].LevelIncome+= R*15/100;
          Wallet[Pool_User[msg.sender].L1] += R*15/100;
        }
        if(silver_Referral[Pool_User[msg.sender].L2].direct >= 2)
        {
          silver_Referral[Pool_User[msg.sender].L2].LevelIncome+= R*10/100;
          Wallet[Pool_User[msg.sender].L2] += R*10/100;
        }
        if(silver_Referral[Pool_User[msg.sender].L3].direct >= 3)
        {
          silver_Referral[Pool_User[msg.sender].L3].LevelIncome+= R*8/100;
          Wallet[Pool_User[msg.sender].L3] += R*8/100;
        }
        if(silver_Referral[Pool_User[msg.sender].L4].direct >= 4)
        {
          silver_Referral[Pool_User[msg.sender].L4].LevelIncome+= R*8/100;
          Wallet[Pool_User[msg.sender].L4] += R*8/100;
        }
        if(silver_Referral[Pool_User[msg.sender].L5].direct >= 5)
        {
          silver_Referral[Pool_User[msg.sender].L5].LevelIncome+= R*8/100;
          Wallet[Pool_User[msg.sender].L5] += R*8/100;
        }
        if(silver_Referral[Pool_User[msg.sender].L6].direct >= 6)
        {
          silver_Referral[Pool_User[msg.sender].L6].LevelIncome+= R*7/100;
          Wallet[Pool_User[msg.sender].L6] += R*7/100;
        }                        
        if(silver_Referral[Pool_User[msg.sender].L7].direct >= 7)
        {
          silver_Referral[Pool_User[msg.sender].L7].LevelIncome+= R*7/100;
          Wallet[Pool_User[msg.sender].L7] += R*7/100;
        }
        if(silver_Referral[Pool_User_team[msg.sender].L8].direct >= 8)
        {
          silver_Referral[Pool_User_team[msg.sender].L8].LevelIncome+= R*7/100;
          Wallet[Pool_User_team[msg.sender].L8] += R*7/100;
        }
        if(silver_Referral[Pool_User_team[msg.sender].L9].direct >= 9)
        {
          silver_Referral[Pool_User_team[msg.sender].L9].LevelIncome+= R*7/100;
          Wallet[Pool_User_team[msg.sender].L9] += R*7/100;
        }
        if(silver_Referral[Pool_User_team[msg.sender].L10].direct >= 10)
        {
          silver_Referral[Pool_User_team[msg.sender].L10].LevelIncome+= R*10/100;
          Wallet[Pool_User_team[msg.sender].L10] += R*10/100;
        }
        if(silver_Referral[Pool_User_team[msg.sender].L11].direct >= 11)
        {
          silver_Referral[Pool_User_team[msg.sender].L11].LevelIncome+= R*10/100;
          Wallet[Pool_User_team[msg.sender].L11] += R*10/100;
        }
        if(silver_Referral[Pool_User_team[msg.sender].L12].direct >= 12)
        {
          silver_Referral[Pool_User_team[msg.sender].L12].LevelIncome+= R*10/100;
          Wallet[Pool_User_team[msg.sender].L12] += R*10/100;
        }
        if(silver_Referral[Pool_User_team[msg.sender].L13].direct >= 13)
        {
          silver_Referral[Pool_User_team[msg.sender].L13].LevelIncome+= R*10/100;
          Wallet[Pool_User_team[msg.sender].L13] += R*10/100;
        }
        if(silver_Referral[Pool_User_team[msg.sender].L14].direct >= 14)
        {
          silver_Referral[Pool_User_team[msg.sender].L14].LevelIncome+= R*10/100;
          Wallet[Pool_User_team[msg.sender].L14] += R*10/100;
        }
        if(silver_Referral[Pool_User_team[msg.sender].L15].direct >= 15)
        {
          silver_Referral[Pool_User_team[msg.sender].L15].LevelIncome+= R*10/100;
          Wallet[Pool_User_team[msg.sender].L15] += R*10/100;
        }
        
    }




//............................................................................................Sponsor used..................................
    function withdraw_Wallet_Amount(uint256 _amount) external
    {
        require(silver_Referral[msg.sender].direct >= 3,"3 Direct not found");
        require(Wallet[msg.sender] >= _amount,"3 Direct not found");
        // require(_amount <= address(this).balance,"balance low");
        require(_amount >= 0,"error");
        // payable(msg.sender).transfer(_amount);
        Wallet[msg.sender] = Wallet[msg.sender].sub(_amount); 
        User[_msgSender()].amount_Pool_B =  User[_msgSender()].amount_Pool_B.sub(_amount);
    }



    function withdrawSponsor(uint256 _index) external
    {
        uint256 R = SponsorReward(msg.sender,_index);
        // require(_index <= address(this).balance,"balance low");
        require(R >= 0,"error");
        // payable(msg.sender).transfer(R);
        sponsorIncome[msg.sender].totalWithdrawReward +=R; 
        User[_msgSender()].amount_Pool_B = User[_msgSender()].amount_Pool_B.sub(R);
        sponsorIncome[_msgSender()].withdrawReward[_index] +=  R;
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
      function Check_Profit_income( address _upline) public view returns(uint256 [] memory Amount,uint256 [] memory PoolA,uint256 PoolB,uint256  [] memory perdayAmount)
    {
        return (User[_upline].depositAmount,User[_upline].amount_Pool_A ,User[_upline].amount_Pool_B,User[_upline].PerdayReward);
    }
          function Check_Profit_income2( address _upline) public view returns(uint40 [] memory Time)
    {
        return (User[_upline].deposit_time);
    }
       function Check_Profit_income_Sponsor( address _upline) public view returns(address [] memory Sponsor,uint256 [] memory PoolA,uint256 PoolB,uint256  [] memory perdayAmount)
    {
        return (sponsorIncome[_upline].SponsorId,sponsorIncome[_upline].Amount ,User[_upline].amount_Pool_B,sponsorIncome[_upline].dailyReward);
    }


}