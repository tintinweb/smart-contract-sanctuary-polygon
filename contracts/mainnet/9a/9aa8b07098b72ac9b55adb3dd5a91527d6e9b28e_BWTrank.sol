/**
 *Submitted for verification at polygonscan.com on 2023-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface Token{
    function transferFrom(address,address,uint) external;
    function transfer(address,uint) external;
    function balanceOf(address) external view returns(uint);
}
interface LockLike{
    function getLock(address) external view returns(uint);
}
contract BWTrank  {

    mapping (address => uint) public wards;
    function rely(address usr) external  auth { wards[usr] = 1; }
    function deny(address usr) external  auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "BWTrank/not-authorized");
        _;
    }
    uint256                                           public  day;
    uint256                                           public  cycle = 86400;
    uint256[6]                                        public  rank;
    uint256[6]                                        public  reward;
    mapping (address => address)                      public  recommend;
    mapping (address => bool)                         public  realName; 
    mapping (uint256 => bool)                         public  verification;
    mapping (address => address[])                    public  under;
    mapping (uint256 => uint256)                      public  lasttime;
    mapping (address => mapping (uint256 =>bool))     public  isAttendance;
    mapping (address => uint256)                      public  attendanceed;
    mapping (address => uint256)                      public  nftLevel;
    Token                                             public  bwt = Token(0x7EFcf6320b26158C2A09C86eB4B604EBc2a7bFe7);
    LockLike                                          public  lockContract= LockLike(0x6986C36A01Ed672e436aaA2a61d557E80F7d8988);
    struct UnderInfo {
        address    owner;   
        uint256    balance;
        uint256    level;
    }
    struct UserInfo { 
        uint256    balance;
        uint256    level;
        uint256    lockAmount;
        uint256    totalSignin;
        uint256    amount;
        bool       real;
        bool       signin;
        bool       signin1;
        bool       signin2;
        bool       signin3;
        bool       signin4;
    }
    constructor() {
        wards[msg.sender] = 1;
    }
    function setRank(uint[6] memory wad) external  auth {
        rank = wad;
    }
    function setReward(uint[6] memory wad) external  auth {
        reward = wad;
    }
    function setCycle(uint256 data) external  auth {
        cycle = data;
    }
    function setLastTime(uint _day, uint256 data) external auth {
        lasttime[_day] = data;
    }
    function setLevel(address usr, uint256 level) external auth {
        nftLevel[usr] = level;
    }
    function setlockContract(address ust) external auth {
        lockContract = LockLike(ust);
    }
    function setBwt(address ust) external auth {
        bwt = Token(ust);
    }
    function registered(uint256 telephone,address usr,address recommender) public auth {
        require(!verification[telephone],'1');
        require(!realName[usr],'2');
        verification[telephone] = true;
        realName[usr] = true;
        bwt.transfer(usr,reward[5]);
        if (recommender != address(0) && recommend[usr] == address(0)){
            recommend[usr] = recommender;
            under[recommender].push(usr);
            uint256 wad = getReward(recommender);
            bwt.transfer(recommender,3*wad);
            address Level2 = recommend[recommender];
            if (Level2 != address(0)) {
                uint256 wad2 = getReward(Level2);
                bwt.transfer(Level2,wad2);
            } 
        }
    }
    function logoutReal(address usr) public auth{
        realName[usr] = false;
    }
    function logoutTel(uint256 telephone) public auth{
        verification[telephone] = false;
    }
    function attendance() public{
        require(realName[msg.sender],'3');
        if(block.timestamp >lasttime[day]+cycle){
           day +=1;
           lasttime[day]= lasttime[day-1]+cycle; 
        }
        require(!isAttendance[msg.sender][day],'4');
        uint256 wad = getReward(msg.sender);
        bwt.transfer(msg.sender,wad);
        isAttendance[msg.sender][day] = true;
        attendanceed[msg.sender] +=1;
    }
    function getReward(address usr) public view returns(uint rewardAmount) {
        uint256 level = getLevel(usr);
        if(level >=6) rewardAmount = reward[0];
        else if(level >=5) rewardAmount = reward[1];
        else if(level >=4) rewardAmount = reward[2];
        else if(level >=3) rewardAmount = reward[3];
        else if(level >=2) rewardAmount = reward[4];
        else if(level >=1) rewardAmount = reward[5];
        else rewardAmount = 0;  
    }
    function getLevel(address usr) public view returns(uint level) {
        uint256 wad = bwt.balanceOf(usr) + lockContract.getLock(usr);
        uint256 Level = nftLevel[usr];
        if(wad >= rank[0] &&  Level >=5) level = 6;
        else if(wad >= rank[1]  &&  Level >=4) level = 5;
        else if(wad >= rank[2]  &&  Level >=3) level = 4;
        else if(wad >= rank[3]  &&  Level >=2) level = 3;
        else if(wad >= rank[4]  &&  Level >=1) level = 2;
        else if(wad >= rank[5]) level = 1;
        else level = 0;   
    }

    function getUnderInfo(address usr) public view returns(UnderInfo[] memory unders,uint256 total){
        uint length = under[usr].length;
        UnderInfo[] memory underInfo = new UnderInfo[](length);
        for (uint i = 0; i <length ; ++i) {
            address underAddress = under[usr][i];
            underInfo[i].owner  = underAddress;
            underInfo[i].balance  = bwt.balanceOf(underAddress) + lockContract.getLock(underAddress);
            underInfo[i].level = getLevel(underAddress);
            total += underInfo[i].balance;
        }
        unders = underInfo;
    }
    function getUserInfo(address usr) public view returns(UserInfo memory user){
        user.balance = bwt.balanceOf(usr);
        user.level = getLevel(usr);
        user.lockAmount = lockContract.getLock(usr);
        user.totalSignin =  attendanceed[usr];
        user.amount = getReward(usr);
        user.real = realName[usr];
        user.signin = isAttendance[usr][day];
        user.signin1 = isAttendance[usr][day-1];
        if(day >= 2) user.signin2 = isAttendance[usr][day-2];
        if(day >= 3) user.signin3 = isAttendance[usr][day-3];
        if(day >= 4) user.signin4 = isAttendance[usr][day-4];
    }
    function withdraw(address asset,uint256 wad, address  usr) public auth {
        Token(asset).transfer(usr,wad);
    }
}