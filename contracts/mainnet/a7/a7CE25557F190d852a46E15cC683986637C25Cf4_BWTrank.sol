/**
 *Submitted for verification at polygonscan.com on 2023-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface Token{
    function transferFrom(address,address,uint) external;
    function transfer(address,uint) external;
    function balanceOf(address) external view returns(uint);
    function lockAmount(address) external view returns(uint);
    function unLockTime(address) external view returns(uint);
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
    uint256                                           public  cycle;
    uint256[6]                                        public  rank;
    uint256[6]                                        public  reward;
    uint256[6]                                        public  balanceOfLp;
    mapping (address => address)                      public  recommend;
    mapping (address => bool)                         public  realName; 
    mapping (uint256 => bool)                         public  verification;
    mapping (address => address[])                    public  under;
    mapping (uint256 => uint256)                      public  lasttime;
    mapping (address => uint256)                      public  attendanceed;
    Token                                             public  bwt = Token(0x04a3554cE5DBf9EB3f02633e8fe5246A093BFCc9);
    Token                                             public  LP = Token(0x62940cEEeB43324F135561fFDf9c0fF40Ac75534);
    struct UnderInfo {
        address    owner;   
        uint256    balance;
        uint256    level;
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
    function setLpAmount(uint[6] memory wad) external  auth {
        balanceOfLp = wad;
    }
    function setCycle(uint256 data) external  auth {
        cycle = data;
    }
    function setLastTime(uint _day, uint256 data) external auth {
        lasttime[_day] = data;
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
            uint256 wad = recommendReward(recommender);
            bwt.transfer(recommender,wad);
        }
    }
    function logout(address usr) public auth{
        realName[usr] = false;
    }
    function attendance() public{
        require(realName[msg.sender],'3');
        require(bwt.unLockTime(msg.sender) ==0,'4');
        if(block.timestamp >lasttime[day]+cycle){
           day +=1;
           lasttime[day]= lasttime[day-1]+cycle; 
        }
        require(attendanceed[msg.sender] != day,'5');
        uint256 wad = getRank(msg.sender);
        bwt.transfer(msg.sender,wad);
        attendanceed[msg.sender] = day;
    }
    function getRank(address usr) public view returns(uint rewardAmount) {
        uint256 wad = bwt.lockAmount(usr);
        uint256 lpAmount = LP.balanceOf(usr);
        if(wad >= rank[0] && lpAmount >=balanceOfLp[0]) rewardAmount = reward[0];
        else if(wad >= rank[1] && lpAmount >=balanceOfLp[1]) rewardAmount = reward[1];
        else if(wad >= rank[2] && lpAmount >=balanceOfLp[2]) rewardAmount = reward[2];
        else if(wad >= rank[3] && lpAmount >=balanceOfLp[3]) rewardAmount = reward[3];
        else if(wad >= rank[4] && lpAmount >=balanceOfLp[4]) rewardAmount = reward[4];
        else if(wad >= rank[5] && lpAmount >=balanceOfLp[5]) rewardAmount = reward[5];
        else rewardAmount = 0; 
    }
    function recommendReward(address usr) public view returns(uint rewardAmount) {
        uint256 wad = bwt.balanceOf(usr);
        if(wad >= rank[0] ) rewardAmount = reward[0];
        else if(wad >= rank[1]) rewardAmount = reward[1];
        else if(wad >= rank[2]) rewardAmount = reward[2];
        else if(wad >= rank[3]) rewardAmount = reward[3];
        else if(wad >= rank[4]) rewardAmount = reward[4];
        else if(wad >= rank[5]) rewardAmount = reward[5];
        else rewardAmount = 0;  
    }
    function getLevel(address usr) public view returns(uint level) {
        uint256 wad = bwt.balanceOf(usr);
        if(wad >= rank[0] ) level = 1;
        else if(wad >= rank[1]) level = 2;
        else if(wad >= rank[2]) level = 3;
        else if(wad >= rank[3]) level = 4;
        else if(wad >= rank[4]) level = 5;
        else if(wad >= rank[5]) level = 6;
        else level = 0;  
    }

    function getUnderInfo(address usr) public view returns(UnderInfo[] memory unders,uint256 total){
        uint length = under[usr].length;
        UnderInfo[] memory underInfo = new UnderInfo[](length);
        for (uint i = 0; i <length ; ++i) {
            address underAddress = under[usr][i];
            underInfo[i].owner  = underAddress;
            underInfo[i].balance  = bwt.balanceOf(underAddress);
            underInfo[i].level = getLevel(underAddress);
            total += underInfo[i].balance;
        }
        unders = underInfo;
    }
    function getUserInfo(address usr) public view returns(uint balance,uint level, uint lockAmount,uint unlock, bool real,bool signin){
        balance = bwt.balanceOf(usr);
        level = getLevel(usr);
        lockAmount = bwt.lockAmount(usr);
        unlock = bwt.unLockTime(usr);
        real = realName[usr];
        signin = attendanceed[msg.sender] == day;
    }
    function withdraw(address asset,uint256 wad, address  usr) public  auth {
        Token(asset).transfer(usr,wad);
    }
}