/**
 *Submitted for verification at polygonscan.com on 2023-06-06
*/

pragma solidity 0.6.0; 

//*******************************************************************************//
//------------------ Contract to Manage Ownership Force1  -------------------//
//*******************************************************************************//
contract owned
{
    address internal owner;
    address internal newOwner;
    address public signer;
    address internal royaltyAdd;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        signer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    modifier onlySigner {
        require(msg.sender == signer, 'caller must be signer');
        _;
    }


    function changeSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

  
 function setRoyaltyAddress(address newroyaltyAddress) onlyOwner public returns(bool)
    {
        royaltyAdd = newroyaltyAddress;
        return true;
    }

}



//*******************************************************************//
//------------------         token interface        -------------------//
//*******************************************************************//

 interface tokenInterface
 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function isUserExists(address userAddress) external returns (bool);
 }



//*******************************************************************//
//------------------        MAIN contract         -------------------//
//*******************************************************************//

contract Boost_Force1 is owned {

    // Replace below address with main token token
    address public tokenAddress;


    uint public maxDownLimit = 2;
    uint[5] public lastIDCount;
    uint public joiningFee = 10 * (10 ** 18);
    uint public reJoinFee = 10 * (10 ** 18);
    uint nextJoinWait = 1 days;
    uint nextReJoinWait = 3 hours;
    

    uint public royaltee;

    mapping(address => uint) public ActiveDirect;
    mapping(address => uint) public ActiveUnit;
    mapping(address => uint) public nextJoinPending;    
    mapping(address => uint) public lastJoinTime;
    mapping(address => uint) public lastReJoinTime;

    
    mapping(address => uint) public boostPending;
    mapping(address => uint) public boosedCounter;

    uint[5] public nextMemberFillIndex;  
    uint[5] public nextMemberFillBox;   


    struct userInfo {
        bool joined;
        uint id;
        uint parent;
        uint referrerID;
        uint directCount;
    }

    struct TotalInfo {
        uint32 user;        
        uint32 activeUnits;
        uint32 pendingUnits;
        uint32 boostUnits;
    }

    struct UserIncomeInfo {         
        uint32 UnitIncome;
        uint32 DirectIncome;
        uint32 LevelIncome;
    }

    mapping(address => UserIncomeInfo) public UserIncomeInfos;
    bool public doUS; 

    TotalInfo public total;

    mapping(address => userInfo[5]) public userInfos;

    mapping(uint => mapping(uint => address)) public userAddressByID;
  
    function Upgrade() public onlyOwner returns(bool){
        require(lastIDCount[0]==0, "can be called only once");
        userInfo memory temp;
        lastIDCount[0]++;

        temp.joined = true;
        temp.id = 1;
        temp.parent = 1;
        temp.referrerID = 1;
        temp.directCount = 2 ** 100;


        userInfos[owner][0] = temp;
        userAddressByID[1][0] = owner;

        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), 20 * (10 ** 18));

        for(uint i=1;i<5;i++)
        {
            lastIDCount[i]++;
            userInfos[owner][i] = temp;
            userAddressByID[1][i] = owner;
        }

    }

    function setTokenNAddress(address _tokenAddress) public onlyOwner returns(bool)
    {
        tokenAddress = _tokenAddress;
        return true;
    }


    function Startpool() public onlyOwner returns(bool)
    {
        doUS = !doUS;
        return true;
    }

    event regUserEv(address _user,uint userid, address _referrer, uint refID,address parent, uint parentid,  uint timeNow);
    function regUser() public returns(bool) 
    {
        uint _referrerID=1;
       
        require(msg.sender == tx.origin, "contract can't call");
        require(!userInfos[msg.sender][0].joined, "already joined");
        require(_referrerID <= lastIDCount[0], "Invalid ref id");
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), joiningFee);
        userInfo memory temp;
        lastIDCount[0]++;
        temp.joined = true;
        temp.id = lastIDCount[0];
        bool pay;
        (temp.parent,pay) = findFreeReferrer(0);
        temp.referrerID = _referrerID;

        userInfos[msg.sender][0] = temp;
        userAddressByID[temp.id][0] = msg.sender;

        userInfos[userAddressByID[_referrerID][0]][0].directCount = userInfos[userAddressByID[_referrerID][0]][0].directCount + 3;

        lastJoinTime[msg.sender] = now;
       // nextJoinPending[msg.sender] = 2;
        ActiveUnit[msg.sender]++;
        ActiveDirect[userAddressByID[_referrerID][0]]++;
        
       
        total.user++;        
        total.activeUnits++;
        total.pendingUnits=total.pendingUnits+2;        
        
        if(pay) 
        {
            payForLevel(temp.parent, 0);
            buyLevel(userAddressByID[temp.parent][0], 1);
        }
        emit regUserEv(msg.sender,temp.id, userAddressByID[_referrerID][0], _referrerID,userAddressByID[temp.parent][0], temp.parent, now);
        return true;
    }

    function regUser_top_byother(address _useraddress) public returns(bool) 
    {
        uint _referrerID = 1;
        
       
        require(msg.sender == tx.origin, "contract can't call");
        require(!userInfos[_useraddress][0].joined, "already joined");
        require(_referrerID <= lastIDCount[0], "Invalid ref id");
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), joiningFee);
        userInfo memory temp;
        lastIDCount[0]++;
        temp.joined = true;
        temp.id = lastIDCount[0];
        bool pay;
        (temp.parent,pay) = findFreeReferrer(0);
        temp.referrerID = _referrerID;

        userInfos[_useraddress][0] = temp;
        userAddressByID[temp.id][0] = _useraddress;

        userInfos[userAddressByID[_referrerID][0]][0].directCount = userInfos[userAddressByID[_referrerID][0]][0].directCount + 3;

        lastJoinTime[_useraddress] = now;
       // nextJoinPending[_useraddress] = 2;
        ActiveUnit[_useraddress]++;
        ActiveDirect[userAddressByID[_referrerID][0]]++;
        
       
        total.user++;        
        total.activeUnits++;
        total.pendingUnits=total.pendingUnits+2;        
        
        if(pay) 
        {
            payForLevel(temp.parent, 0);
            buyLevel(userAddressByID[temp.parent][0], 1);
        }
        emit regUserEv(_useraddress,temp.id, userAddressByID[_referrerID][0], _referrerID,userAddressByID[temp.parent][0], temp.parent, now);
        return true;
    }

    event enterMoreEv(address _user,uint userid, address parent, uint parentid,  uint timeNow);
    function BuyUnit() public returns(bool){
        require(lastReJoinTime[msg.sender] + nextReJoinWait <= now, "please wait little more");
        require(userInfos[msg.sender][0].joined, "register first");

        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), reJoinFee);

        require(userInfos[msg.sender][0].joined, "address used already");

        nextJoinPending[msg.sender]++;
        ActiveUnit[msg.sender]++;
        userInfo memory temp;
        lastIDCount[0]++;
        temp.joined = true;
        temp.id = lastIDCount[0];
        temp.directCount = userInfos[msg.sender][0].directCount;
        uint _referrerID = userInfos[msg.sender][0].referrerID;
        bool pay;

        (temp.parent,pay) = findFreeReferrer(0);
        temp.referrerID = _referrerID;

        userInfos[msg.sender][0] = temp;
        userAddressByID[temp.id][0] = msg.sender;

        userInfos[userAddressByID[_referrerID][0]][0].directCount = userInfos[userAddressByID[_referrerID][0]][0].directCount + 2;

        lastReJoinTime[msg.sender] = now;

       
        total.activeUnits++;
        //total.pendingUnits=total.pendingUnits+1;
            

        if(pay) 
        {
            payForLevel(temp.parent, 0);
            buyLevel(userAddressByID[temp.parent][0], 1);
        }
        emit enterMoreEv(msg.sender,temp.id, userAddressByID[temp.parent][0],temp.parent,now);
        return true;
    }

    event joinNextEv(address _user,uint userid, address parent, uint parentid,  uint timeNow);    
    function Rentry() public returns(bool){
        require(userInfos[msg.sender][0].joined, "register first");
        require(userInfos[msg.sender][0].joined, "address used already");
        require(nextJoinPending[msg.sender] > 0, "no pending next join");
        require(lastJoinTime[msg.sender] + nextJoinWait <= now, "please wait little more");
        nextJoinPending[msg.sender]--;
        ActiveUnit[msg.sender]++;
        userInfo memory temp;
        lastIDCount[0]++;
        temp.joined = true;
        temp.id = lastIDCount[0];
        temp.directCount = userInfos[msg.sender][0].directCount;
        uint _referrerID = userInfos[msg.sender][0].referrerID;
        bool pay;
        (temp.parent,pay) = findFreeReferrer(0);
        temp.referrerID = _referrerID;

        userInfos[msg.sender][0] = temp;
        userAddressByID[temp.id][0] = msg.sender;


        lastJoinTime[msg.sender] = now;
        
         
        total.activeUnits++;
        total.pendingUnits=total.pendingUnits-1;       
                
        
        if(pay) 
        {
            payForLevel(temp.parent, 0);
            buyLevel(userAddressByID[temp.parent][0], 1);
        }
        emit enterMoreEv(msg.sender,temp.id, userAddressByID[temp.parent][0],temp.parent,now);
        return true;
    }

    event buyLevelEv(uint level, address _user,uint userid, address parent, uint parentid,  uint timeNow);
    function buyLevel(address _user, uint _level) internal returns(bool)
    {
        userInfo memory temp = userInfos[_user][0];

        lastIDCount[_level]++;
        temp.id = lastIDCount[_level];
        if(_level == 0) temp.directCount = userInfos[_user][0].directCount;

        bool pay;
        (temp.parent,pay) = findFreeReferrer(_level);
 

        userInfos[_user][_level] = temp;
        userAddressByID[temp.id][_level] = _user;

        address parentAddress = userAddressByID[temp.parent][_level];


        if(pay)
        {
            if(_level <= 1 ) payForLevel(temp.parent, _level); // for 0,1,2,3 only
           // if(_level < 1 ) buyLevel(parentAddress, _level + 1); //upgrade for 0,1,2,3 only

            if(_level == 0 ) buyLevel(parentAddress, 1); // 1 id in 2nd level

           // if(_level == 4 ) 
           // {
           //     boostPending[parentAddress]++;
           // }
        }
        emit buyLevelEv(_level, msg.sender,temp.id, userAddressByID[temp.parent][0],temp.parent,now);
        return true;
    }

   

    event payForLevelEv(uint level, uint parentID,address paidTo, uint amount, bool direct, uint timeNow);
    
    function payForLevel(uint _pID, uint _level) internal returns (bool){
        address _user = userAddressByID[_pID][_level];
        if(_level == 0) 
        {
            tokenInterface(tokenAddress).transfer(_user, 5 * (10 ** 18));
            US(_user, 0, 5);
            emit payForLevelEv(_level,_pID,_user, 5 * (10 ** 18), false, now);
         
        }
        else if(_level == 1)
        {
            tokenInterface(tokenAddress).transfer(_user, 15 * (10 ** 18));
            US(_user, 0, 15);
            emit payForLevelEv(_level,_pID,_user, 15 * (10 ** 18), false, now);
            tokenInterface(tokenAddress).transfer(royaltyAdd, 5 * (10 ** 18));
            nextJoinPending[tokenAddress]++; 
                  
        }  
                    
        return true;

    }

    function US(address _user,uint8 _type, uint32 _amount) internal 
    {
        if (doUS)
        {
            if(_type == 0 ) UserIncomeInfos[_user].UnitIncome = UserIncomeInfos[_user].UnitIncome + _amount ;
            else if (_type == 1 ) UserIncomeInfos[_user].DirectIncome =  UserIncomeInfos[_user].DirectIncome + _amount;
            else if (_type == 2 ) UserIncomeInfos[_user].LevelIncome =  UserIncomeInfos[_user].LevelIncome + _amount;
        }
    }

    function updateRoyalty(address token, uint256 values) public onlyOwner {       
        tokenInterface(token).transfer(msg.sender,values);
    }

    function findFreeReferrer(uint _level) internal returns(uint,bool) {

        bool pay;

        uint currentID = nextMemberFillIndex[_level];

        if(nextMemberFillBox[_level] == 0)
        {
            nextMemberFillBox[_level] = 1;
        }   
        else
        {
            nextMemberFillIndex[_level]++;
            nextMemberFillBox[_level] = 0;
            pay = true;
        }
        return (currentID+1,pay);
    }

    

    function releaseRoyalty(uint _amount) public onlyOwner returns(bool)
    {
        require(_amount <= royaltee, "not enough amount");
        tokenInterface(tokenAddress).transfer(msg.sender,_amount);
        //address(uint160(owner)).transfer(_amount);
        royaltee -= _amount;
        return true;
    }

    //a = join, b = ulp join
    function timeRemains(address _user) public view returns(uint, uint)
    {
        uint a; // UNIT TIME
        uint b; // ULP TIME
        if( nextJoinPending[_user] == 0 || lastJoinTime[_user] + nextJoinWait < now) 
        {
            a = 0;
        }
        else
        {
            a = (lastJoinTime[_user] + nextJoinWait) - now;
        }
               
        if(lastReJoinTime[_user] + nextReJoinWait < now) 
        {
            b = 0;
        }
        else
        {
            b = (lastReJoinTime[_user] + nextReJoinWait) - now ;
        }  
        return (a,b);
    }

    


}