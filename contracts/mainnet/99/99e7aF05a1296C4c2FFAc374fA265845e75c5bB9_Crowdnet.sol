// SPDX-License-Identifier: Unlicensed

import "./IERC20.sol";

pragma solidity >=0.8.0;

contract Crowdnet {
    IERC20 public usdc = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    address public admin = 0xe8884352aC947A58ecfDFd405224ed649090A531;
    address[4] public Heads = [0x444A517AeaE7f2259c9906DB86c6868a0e5A00d9, 0xB320555e2b3a0CBe4f9B74167Ca08d573FCd3bEB, 0x4EE8a924f771693520A2CE0974fB9D358609077B, 0x694905039135E3DA062E7cD49A1Cf67C2d7dca61];
    address public mystery = 0xa2e8b5353753f3726636BA7205c12a2B3caA518f;
    address public Fee;
    address public Fee2;
    uint256[2] public left;
    uint256[6] public APSerial;
    uint256 public autoPool;
    uint256[6] private Level = [40e6, 60e6, 120e6, 360e6, 720e6, 1440e6];
    uint256[6] private Newbies = [0, 4, 2, 2, 2, 8];
    uint256[6] private TPI = [15e5, 2e6, 3e6, 4e6, 5e6, 6e6];
    uint256[6] private Referal = [20e6, 24e6, 48e6, 144e6, 288e6, 576e6];
    uint256[6] private Mystery = [1e6, 77e5, 169e5, 625e5, 1295e5, 255e6];
    uint256[6] private Admin = [2e6, 12e6, 24e6, 96e6, 201e6, 429e6];
    uint256[6] private AutoPool = [2e6, 43e5, 131e5, 335e5, 715e5, 145e6];
    
    uint256[6] private APTeams = [4, 20, 84, 340, 1364, 5460];
    uint256[6] private BeginnerAP = [1e6, 8e6, 352e5, 768e5, 2045e5, 8192e5];
    uint256[6] private BronzeAP = [3e6, 16e6, 64e6, 1536e5, 3584e5, 24576e5];
    uint256[6] private AzuriteAP = [10e6, 40e6, 160e6, 6656e5, 1536e6, 6144e6];
    uint256[6] private SilverAP = [25e6, 100e6, 400e6, 1600e6, 4608e6, 16384e6];
    uint256[6] private PlatiniumAP = [75e6, 208e6, 1024e6, 2400e6, 9600e6, 20480e6];
    uint256[6] private DiamondAP = [200e6, 640e6, 1472e6, 3072e6, 12288e6, 32768e6];
    mapping(uint256 => address[]) public users;
    uint256 public totalUsers;

    struct User {
        address referrer;
        uint256 level;
        uint256 start;
        uint256 revenue;
        uint256 APRevenue;
        uint256 newbies;
        address[6] APUpline;
        uint256[6] APTeam;
        uint256 totalTeam;
        uint256[6] APLevelTeam;
        uint256[6] APTaken;
    } 

    struct Reward { 
        uint256[3] income;
        uint256[6] AP;
        uint256 rebirth;
        uint256 rebirthDistributed;
    }

    mapping(address => Reward) public rewardInfo;
    mapping(address => User) public userInfo;

    modifier onlyOwner {
        require(msg.sender == admin);
        _;
    }

    constructor(address _fee, address _fee2) {
        Fee = _fee;
        Fee2 = _fee2;
    }

    function register(address _ref) public {
        User storage user = userInfo[msg.sender];
        require(userInfo[_ref].level > 0, "Invalid Referrer");
        require(userInfo[msg.sender].level == 0, "Already Registered");
        require(user.referrer == address(0), "referrer bonded");  
        user.referrer = _ref;
    }

    function upgradeLevel(uint256 level) public {
        require(userInfo[msg.sender].referrer != address(0), "Register First");
        require(userInfo[msg.sender].level < level && level <= 6 , "Invalid Level");
        require(userInfo[msg.sender].newbies >= Newbies[level-1], "Not Eligible");
        usdc.transferFrom(msg.sender, address(this), Level[level-1]);
        userInfo[msg.sender].level = level;
        userInfo[msg.sender].newbies -= Newbies[level-1];

        if(level == 1) {
            totalUsers += 1;
            address ref = userInfo[msg.sender].referrer;
            userInfo[ref].newbies += 1;
            userInfo[msg.sender].start = block.timestamp;
        }

        users[level-1].push(msg.sender);
        uint256 _curSerial = APSerial[level-1];
        address _AP = users[level-1][_curSerial];
        userInfo[msg.sender].APUpline[level-1] = _AP;
        userInfo[_AP].APTeam[level-1] += 1;
        if(userInfo[_AP].APTeam[level-1] >= 4) {
            APSerial[level-1] += 1;
        } 

        bool isNew = (level == 1) ? true : false;
        _distribute(msg.sender, level, isNew);
        _updateAP(msg.sender, level);
    }

    function _distribute(address _user, uint256 _level, bool isNew) private {
        uint256 toDistribute = (_level > 1) ? 6 : 10;
        uint256 amount = TPI[_level-1];
        uint256 refAmount = Referal[_level-1];

        left[0] += Admin[_level-1];
        left[1] += Mystery[_level-1];
        autoPool += AutoPool[_level-1];

        address upline = userInfo[_user].referrer;
        for(uint256 i=0; i<toDistribute; i++) {
            if(toDistribute == 10 && upline != address(0)) {
                rewardInfo[upline].income[1] += amount; 
                userInfo[upline].revenue += amount;
                if(isNew) {
                    userInfo[upline].totalTeam += 1;
                }
            } else if(userInfo[upline].level >= _level && toDistribute == 6 && upline != address(0)) {
                rewardInfo[upline].income[2] += amount; 
                userInfo[upline].revenue += amount;
            } else {
                left[0] += amount;
            }

            if(i == _level-1 && userInfo[upline].level >= _level && upline != address(0)) {
                rewardInfo[upline].income[0] += refAmount;
                userInfo[upline].revenue += refAmount;
            } else if(i == _level-1) {
                left[0] += refAmount;
            }

            upline = userInfo[upline].referrer;
        }
    }

    function _updateAP(address _user, uint256 _level) private {
        address upline = userInfo[_user].APUpline[_level-1];

        for(uint256 i=0; i<6; i++) {
            if(upline != address(0)) {
                if(userInfo[upline].level >= _level) {
                    userInfo[upline].APLevelTeam[_level-1] += 1;
                }
                upline = userInfo[upline].APUpline[_level-1];
            } else {
                break;
            }
        }
    }

    function claimAutoPool(uint256 _type) public {
        uint256[6] memory _AP;
        if(_type == 1) {
            _AP = BeginnerAP;
        } else if(_type == 2) {
            _AP = BronzeAP;
        } else if(_type == 3) {
            _AP = AzuriteAP;
        } else if(_type == 4) {
            _AP = SilverAP;
        } else if(_type == 5) {
            _AP = PlatiniumAP;
        } else if(_type == 6) {
            _AP = DiamondAP;
        }

        for(uint256 i=0; i<_AP.length; i++) {
            if(userInfo[msg.sender].APLevelTeam[_type-1] >= APTeams[i] && userInfo[msg.sender].APTaken[_type-1] < APTeams[i]) {
                rewardInfo[msg.sender].AP[_type-1] += _AP[i];
                userInfo[msg.sender].APRevenue += _AP[i];
                userInfo[msg.sender].APTaken[_type-1] = APTeams[i];
            }
        }
    }   

    function withdraw(uint256 _type) public {
        uint256 income = rewardInfo[msg.sender].income[_type];
        require(income >= 10e6, "Income less than 10");

        uint256 charge = (income * 5) / 100;
        uint256 rebirth = (income * 15) / 100;
        usdc.transfer(Fee2, charge);
        rewardInfo[msg.sender].rebirth += rebirth;
        rewardInfo[msg.sender].income[_type] = 0;

        uint256 toDistribute = rewardInfo[msg.sender].rebirth / 40e6;
        for(uint256 i=0; i<toDistribute; i++) {
            _distribute(msg.sender, 1, false);
            rewardInfo[msg.sender].rebirth -= 40e6;
            rewardInfo[msg.sender].rebirthDistributed += 1;
        }

        for(uint256 i=0; i<Heads.length; i++) {
            if(Heads[i] == msg.sender && left[0] >= 38e6) {
                usdc.transfer(Fee, left[0]);
                left[0] = 0;
                usdc.transfer(mystery, left[1]);
                left[1] = 0;
            }
        }

        usdc.transfer(msg.sender, (income - (charge + rebirth)));
    }

    function withdrawAP(uint256 _level) public {
        uint256 income = rewardInfo[msg.sender].AP[_level-1];
        
        bool isAdmin = false;
        for(uint256 i=0; i<Heads.length; i++) {
            if(Heads[i] == msg.sender) {
                isAdmin = true;
            }
        }

        require((userInfo[msg.sender].level > _level || (userInfo[msg.sender].level == 6 && (userInfo[msg.sender].newbies >= 8 || isAdmin))), "Upgrade Your level to Recevie reward");
        
        uint256 charge = (income * 5) / 100;
        usdc.transfer(Fee2, charge);
        rewardInfo[msg.sender].AP[_level-1] = 0;
        
        if(isAdmin && left[0] >= 38e6) {
            usdc.transfer(Fee, left[0]);
            left[0] = 0;
            usdc.transfer(mystery, left[1]);
            left[1] = 0;
        }

        usdc.transfer(msg.sender, (income - charge));
    }

    function getIncome(address _user) public view returns(uint256[9] memory) {
        Reward memory _reward = rewardInfo[_user];
        return [_reward.income[0],_reward.income[1],_reward.income[2],_reward.AP[0],_reward.AP[1],_reward.AP[2],_reward.AP[3],_reward.AP[4],_reward.AP[5]];
    }

    function getAutoPoolTeam(address _user) public view returns(uint256[6] memory) {
        User memory user = userInfo[_user];
        return [user.APLevelTeam[0],user.APLevelTeam[1],user.APLevelTeam[2],user.APLevelTeam[3],user.APLevelTeam[4],user.APLevelTeam[5]];
    }

    function getAutoPoolTaken(address _user) public view returns(uint256[6] memory) {
        User memory user = userInfo[_user];
        return [user.APTaken[0],user.APTaken[1],user.APTaken[2],user.APTaken[3],user.APTaken[4],user.APTaken[5]];
    }

    function updateMysteryBox(address _new) public onlyOwner {
        mystery = _new;
    }

    function updateDistribution(uint256 _type, uint256 _place, uint256 _val) public onlyOwner {
        if(_type == 0) {
            AutoPool[_place] = _val;
        } else if(_type == 1) {
            Mystery[_place] = _val;
        }  else if(_type == 2) {
            Admin[_place] = _val;
        }
    }

    function withdrawAutoPool() public onlyOwner {
        require((block.timestamp - userInfo[users[0][users[0].length - 1]].start) >= 90 days, "Not Eligible");
        uint256 _bal = usdc.balanceOf(address(this));
        usdc.transfer(Fee, _bal);
    }  

    function addNew(address _user, address _referrer ,uint256 _level) public onlyOwner {
        require(userInfo[_user].level == 0, "User already Registered");
        userInfo[_user].level = _level;
        userInfo[_user].start = block.timestamp;
        userInfo[_user].referrer = _referrer;
        if(_referrer != address(0)) userInfo[_referrer].totalTeam += 1;
        totalUsers += 1;
        for(uint256 i=0; i<_level; i++) {
            users[i].push(_user);
            if(totalUsers > 1) {
                uint256 _curSerial = APSerial[i];
                address _AP = users[i][_curSerial];
                userInfo[_user].APUpline[i] = _AP;
                userInfo[_AP].APTeam[i] += 1;
                if(userInfo[_AP].APTeam[i] >= 4) {
                    APSerial[i] += 1;
                } 
                _updateAP(_user, i+1);
            }
        }
        
    }
}