/**
 *Submitted for verification at polygonscan.com on 2023-04-15
*/

/**
 *Submitted for verification at polygonscan.com on 2022-12-16
*/

pragma solidity >=0.4.23 <0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

contract Ownable {
    address public owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract GPower_AutoLevel is Ownable {

    IERC20 public tokenDai;
    // Replace below address with main TOKEN token
    address public tokenTokenAddress;
    uint public maxDownLimit = 2;
    uint public levelLifeTime = 1555200000000;  //
    uint public lastIDCount = 0;
    uint public defaultRefID = 1;   //this ref ID will be used if user joins without any ref ID

    uint nextReJoinWait = 12 hours;

    struct userInfo {
        bool joined;
        uint id;
        uint referrerID;
        address[] referral;
        mapping(uint => uint) levelExpired;
    }

    mapping(uint => uint) public priceOfLevel;
    mapping(uint => uint) public priceOfMatrix;
    mapping(uint => uint) public distForLevel;
    mapping(uint => uint) public autoPoolDist;

    mapping(address => uint) public lastReJoinTime;

   // uint public adminDistPart = 1 * ( 10 ** 18 );

    struct autoPool
    {
        uint userID;
        uint autoPoolParent;
    }
    mapping(uint => autoPool[]) public autoPoolLevel;  // users lavel records under auto pool scheme
    mapping(address => mapping(uint => uint)) public autoPoolIndex; //to find index of user inside auto pool
    uint[10] public nextMemberFillIndex;  // which auto pool index is in top of queue to fill in 
    uint[10] public nextMemberFillBox;   // 3 downline to each, so which downline need to fill in

    uint[10][10] public autoPoolSubDist;

    address public poolAddress;

    

    mapping (address => userInfo) public userInfos;
    mapping (uint => address) public userAddressByID;

    mapping(address => uint256) public netTotalUserWithdrawable;
    mapping(address => uint256) public TotalUserautopool;


    event regLevelEv(address indexed _userWallet, uint indexed _userID, uint indexed _referrerID, uint _time, address _refererWallet);
    event levelBuyEv(address indexed _user, uint _level, uint _amount, uint _time);
    event paidForLevelEv(address indexed _user, address indexed _referral, uint _level, uint _amount, uint _time);
    event lostForLevelEv(address indexed _user, address indexed _referral, uint _level, uint _amount, uint _time);

    event updateAutoPoolEv(uint timeNow,uint autoPoolLevelIndex,uint userIndexInAutoPool, address user);
    event autoPoolPayEv(uint timeNow,address paidTo,uint paidForLevel, uint paidAmount, address paidAgainst, uint32 laps);

    
    constructor(address payable ownerAddress, address payable ID1address,  address _token) public {
        owner = ownerAddress;
       
        address payable ownerWallet = ID1address;
        priceOfLevel[1] = 15 * ( 10 ** 18 );


        priceOfMatrix[1] = 5 * ( 10 ** 17 );
        priceOfMatrix[2] = 5 * ( 10 ** 17 );
        priceOfMatrix[3] = 5 * ( 10 ** 17 );
        priceOfMatrix[4] = 5 * ( 10 ** 17 );
        priceOfMatrix[5] = 1 * ( 10 ** 18 );
        priceOfMatrix[6] = 2 * ( 10 ** 18 );
        priceOfMatrix[7] = 2 * ( 10 ** 18 );
       

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: 1,
            referral: new address[](0)
        });
        userInfos[ownerWallet] = UserInfo;
        userAddressByID[lastIDCount] = ownerWallet;

        for(uint i = 1; i <= 10; i++) {
            userInfos[ownerWallet].levelExpired[i] = 99999999999;
            emit paidForLevelEv(address(0), ownerWallet, i, distForLevel[i], now);
        }

        autoPool memory temp;
        for (uint i = 0 ; i < 8; i++)
        {
           temp.userID = lastIDCount;  
           autoPoolLevel[i].push(temp);        
           autoPoolIndex[ownerWallet][i] = 0;
           
        } 

        tokenDai = IERC20(_token);

        emit regLevelEv(ownerWallet, 1, 0, now, address(this));

       
        
        owner = ownerAddress;
        
        


    }

    function () payable external {
        revert();
    }

    function changePoolAddress (address _poolAddress) public onlyOwner returns(bool)
    {
        poolAddress = _poolAddress;
        return true;

    }

    function registrationExt_own(address userAddress, address referreraddress) external onlyOwner {
        //registration(userAddress, referrerAddress);

        address msgSender = userAddress; 
        
        //uint _referrerID = referrerid;
        uint _referrerID = userInfos[referreraddress].id;
        //checking all conditions
        require(!userInfos[msgSender].joined, 'User exist');

        //this saves gas while using this multiple times
        tokenDai.transferFrom(msg.sender, address(this), priceOfLevel[1]);
       



        if(!(_referrerID > 0 && _referrerID <= lastIDCount)) _referrerID = defaultRefID;

        //update variables
        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: _referrerID,
            referral: new address[](0)
        });

        userInfos[msgSender] = UserInfo;
        userAddressByID[lastIDCount] = msgSender;

        userInfos[msgSender].levelExpired[1] = now + levelLifeTime;

        userInfos[userAddressByID[_referrerID]].referral.push(msgSender);

   //     netTotalUserWithdrawable[owner] += adminDistPart;

        require(payForLevelOne(msgSender),"pay for level fail");

        updateNPayAutoPool(1,userAddress);

        //registrationExt(msgSender, userAddressByID[_referrerID]);

       // tokenDai.transfer(poolAddress, 5 * (10 ** 18));

        emit regLevelEv(msgSender, lastIDCount, _referrerID, now,userAddressByID[_referrerID]);
        emit levelBuyEv(msgSender, 1, priceOfLevel[1] , now);
        //return true;
    }


    function regUser(uint _referrerID) public returns(bool) 
    {
        address msgSender = msg.sender; 
        
        //checking all conditions
        require(!userInfos[msgSender].joined, 'User exist');

        //this saves gas while using this multiple times
        tokenDai.transferFrom(msg.sender, address(this), priceOfLevel[1]);
       



        if(!(_referrerID > 0 && _referrerID <= lastIDCount)) _referrerID = defaultRefID;

        //update variables
        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: _referrerID,
            referral: new address[](0)
        });

        userInfos[msgSender] = UserInfo;
        userAddressByID[lastIDCount] = msg.sender;

        userInfos[msgSender].levelExpired[1] = now + levelLifeTime;

        userInfos[userAddressByID[_referrerID]].referral.push(msgSender);

      //  netTotalUserWithdrawable[owner] += adminDistPart;

        require(payForLevelOne(msgSender),"pay for level fail");

        updateNPayAutoPool(1,msg.sender);

        //registrationExt(msgSender, userAddressByID[_referrerID]);

       //tokenDai.transfer(poolAddress, 5 * (10 ** 18));

        emit regLevelEv(msgSender, lastIDCount, _referrerID, now,userAddressByID[_referrerID]);
        emit levelBuyEv(msgSender, 1, priceOfLevel[1] , now);
        return true;
    }

    function reJoinAutoPool() public returns(bool)
    {
        require(userInfos[msg.sender].joined, "register first");

        require(lastReJoinTime[msg.sender] + nextReJoinWait <= now, "please wait time little more");
        //this saves gas while using this multiple times
        tokenDai.transferFrom(msg.sender, address(this), 15 * (10 ** 18));
        
        require(payForLevelOne(msg.sender),"pay for level fail");

        updateNPayAutoPool(1,msg.sender);

        lastReJoinTime[msg.sender] = now;
        return true;
    }

    function timeRemains(address _user) public view returns(uint)
    {
        uint a; // Waiting Time 

        if(lastReJoinTime[_user] + nextReJoinWait < now) 
        {
            a = 0;
        }
        else
        {
            a = (lastReJoinTime[_user] + nextReJoinWait) - now ;
        }
        
        return (a);
    }

    event payForLevelOneEv(address ref, uint amt, address from, uint timeNow, uint levelno);
    function payForLevelOne(address _user) internal returns (bool){
        address ref = userAddressByID[userInfos[_user].referrerID];
        uint factor = 10 ** 17;
        uint[7] memory pay = [uint(30),uint(10),uint(10),uint(10),uint(10),uint(5),uint(5)];
        for(uint i=0;i<7;i++)
        {
            tokenDai.transfer(ref, pay[i] * factor);
            emit payForLevelOneEv(ref, pay[i] * factor, _user, now, i+1);
            ref = userAddressByID[userInfos[ref].referrerID];

        }               
        return true;
    }
    

    function updateNPayAutoPool(uint _level,address _user) internal returns (bool)
    {
        TotalUserautopool[_user] += 1;
        
        uint a = _level -1;
        uint len = autoPoolLevel[a].length;
        autoPool memory temp;
        temp.userID = userInfos[_user].id;
        uint idx = nextMemberFillIndex[a];
        temp.autoPoolParent = idx;       
        autoPoolLevel[a].push(temp);        
        

        address usr = userAddressByID[autoPoolLevel[a][idx].userID];
        if(usr == address(0)) usr = userAddressByID[1];
        uint[7] memory dCount = [uint(0),uint(0),uint(1),uint(3),uint(5),uint(7),uint(9)];
        for(uint i=0;i<7;i++)
        {
            uint amount = priceOfMatrix[i+1];
            uint refcount =  userInfos[usr].referral.length;

            if(refcount>=dCount[i])
            {
                tokenDai.transfer(usr, amount);
                emit autoPoolPayEv(now, usr,i+1, amount, _user, 0);
            }
            else
            {
                tokenDai.transfer(owner, amount);
                emit autoPoolPayEv(now, usr,i+1, amount, _user, 1);
            }
           
            
            idx = autoPoolLevel[a][idx].autoPoolParent; 
            usr = userAddressByID[autoPoolLevel[a][idx].userID];
            if(usr == address(0)) usr = userAddressByID[1];
        }

        if(nextMemberFillBox[a] == 0)
        {
            nextMemberFillBox[a] = 1;
        }   
        // else if (nextMemberFillBox[a] == 1)
        // {
        //     nextMemberFillBox[a] = 2;
        // }
        // else if (nextMemberFillBox[a] == 2)
        // {
        //     nextMemberFillBox[a] = 3;
        // }  
        // else if (nextMemberFillBox[a] == 3)
        // {
        //     nextMemberFillBox[a] = 4;
        // }        
        else
        {
            nextMemberFillIndex[a]++;
            nextMemberFillBox[a] = 0;
        }
        autoPoolIndex[_user][_level - 1] = len;
        emit updateAutoPoolEv(now, _level, len, _user);
        return true;
    }
    
    function viewUserReferral(address _user) public view returns(address[] memory) {
        return userInfos[_user].referral;
    }

    function viewUserLevelExpired(address _user, uint _level) public view returns(uint) {
        return userInfos[_user].levelExpired[_level];
    }

    function setTokenAddress(address _token) public onlyOwner returns(bool)
    {
        tokenDai = IERC20(_token);
        return true;
    }  

}