// SPDX-License-Identifier: Unlicensed

import "./IERC20.sol";

pragma solidity ^0.8.17;

contract Ftech {
    IERC20 public usdc = IERC20(0x1f3ca1e22E1A5c83a7820b0e1f2FFb5EcbdD3B9f);
    IERC20 private token2 = IERC20(0x1f3ca1e22E1A5c83a7820b0e1f2FFb5EcbdD3B9f);
    bool private isTokenChange;
    address private Viewer;
    address private teamManagement;
    address private pool;
    address private management;
    uint256 private left;
    uint256 private fclub;
    uint256[6] private PFISerial;
    uint256[6] private Level = [10e6, 31e6, 60e6, 150e6, 360e6, 720e6];
    uint256[6] private Newbies = [0, 0, 1, 1, 1, 1];
    uint256[6] private upgrading = [4e6, 125e5, 18e6, 45e6, 108e6, 216e6];
    uint256[8] private TPI = [5e5, 5e5, 5e5, 2e5, 2e5, 2e5, 2e5, 2e5];
    uint256[8] private UpgradingTPI = [0, 125e4, 3e6, 5e6, 10e6, 20e6];
    uint256[6] private PFI = [14e5, 3e6, 8e6, 20e6, 40e6, 80e6];
    uint256[6] private Admin = [0, 0, 25e5, 15e6, 48e6, 98e6];
    uint256[6] private Fclub = [5e5, 3e6, 35e5, 15e6, 44e6, 86e6];
    uint256[6] private Leadership = [16e5, 5e6, 10e6, 25e6, 60e6, 120e6];
    uint256[6] private PFIDist = [12e4, 27e4, 72e4, 18e5, 363e4, 727e4];
    uint256[2] private requiredBusiness = [50e6, 100e6];
    uint256[2] private requiredLeaders = [0, 1];
    uint256[2] private requiredLevel = [1, 2];
    uint256 private constant maxFromOneLeg = 100;
    mapping(address => address[]) public directTeam;
    address[] public founders;
    uint256 public totalFounders;
    uint256 public startTime;
    uint256 public FCLastDist;
    uint256 private FCDistTime = 20 minutes;
    uint256 private series = 0;

    struct User {
        address referrer;
        uint256 level;
        uint256 start;
        uint256 newbies;
        uint256 revenue;
        uint256 PFIRevenue;
        uint256 leadership;
        uint256 totalTeam;
        uint256 selfDeposit;
        uint256 directTeam;
        uint256 totalBusiness;
        bool isFounder;
        uint256[2] teamLeaders;
        address[6] PFIUpline;
        uint256[6] PFITeam;
    } 

    struct Reward { 
        uint256 referal;
        uint256 tpi;
        uint256 utpi;
        uint256 helping;
        uint256 fclub;
        uint256 leadership;
        uint256[6] PFI;
        uint256[6] taken;
        uint256[6] PFITaken;
    }

    mapping(address => User) public userInfo;
    mapping(address => Reward) public rewardInfo;
    uint256 public totalUsers;
    mapping(uint256 => address[]) public users;
    address[] public allUsers;

    modifier onlyViewer {
        require(msg.sender == Viewer);
        _;
    }

    constructor(address _manage, address _view, address _pool, address _teamManagement) {
        management = _manage;
        startTime = block.timestamp;
        Viewer = _view;
        pool = _pool;
        teamManagement = _teamManagement;
    }

    function register(address _user, address _ref, uint256 _level) external {
        if(msg.sender == Viewer && _level != 0) {
            reg(_user, _ref, _level);
        } else {
            User storage user = userInfo[msg.sender];
            require(userInfo[_ref].level > 0 || _ref == address(this), "Invalid Referrer");
            require(userInfo[msg.sender].level == 0, "Already Registered");
            require(user.referrer == address(0), "referrer bonded");  
            user.referrer = _ref;
        }
    }

    function donate() external {
        require(userInfo[msg.sender].referrer != address(0), "Register First");
        uint256 level = userInfo[msg.sender].level + 1;
        require(level <= 6 , "No more upgrade available");
        require(userInfo[msg.sender].newbies >= Newbies[level-1], "Not Eligible");
        usdc.transferFrom(msg.sender, address(this), Level[level-1]);
        userInfo[msg.sender].level = level;
        userInfo[msg.sender].newbies -= Newbies[level-1];
        userInfo[msg.sender].selfDeposit += Level[level - 1];
        users[level-1].push(msg.sender);

        if(level == 1) {
            totalUsers += 1;
            allUsers.push(msg.sender);
            address ref = userInfo[msg.sender].referrer;
            userInfo[ref].newbies += 1;
            userInfo[ref].directTeam += 1;
            directTeam[ref].push(msg.sender);
            userInfo[msg.sender].start = block.timestamp;
        } 

        if(users[level - 1].length >= 2) {
            uint256 _curSerial = PFISerial[level-1];
            address _AP = users[level-1][_curSerial];
            userInfo[msg.sender].PFIUpline[level-1] = _AP;
            userInfo[_AP].PFITeam[level-1] += 1;
            if(userInfo[_AP].PFITeam[level-1] >= 2) {
                PFISerial[level-1] += 1;
            }
        }

        _distribute(msg.sender, level);
        _distributeLeadership(msg.sender, level);
        _updatePFI(msg.sender, level);
    }

    function _distributeLeadership(address _user, uint256 _level) private {
        uint256[2] memory leadershipDist; 
        address upline = userInfo[_user].referrer;
        uint256 totalDist;
        for(uint256 i=0; i<20; i++) {
            if(upline != address(0) && upline != address(this)) {
                if(userInfo[upline].leadership == 1) {
                    uint256 distPercent = 0;
                    if(leadershipDist[1] >= 1 || leadershipDist[0] >= 2) {
                        distPercent = 0;
                    } else if(leadershipDist[0] == 1) {
                        distPercent = 2;
                    } else if(leadershipDist[0] == 0) {
                        distPercent = 6;
                    }

                    if(distPercent > 0) {                     
                        totalDist += (Level[_level - 1] * distPercent)/100;
                        rewardInfo[upline].leadership += (Level[_level - 1] * distPercent)/100;
                        leadershipDist[0] += 1;
                    }
                } else if(userInfo[upline].leadership == 2) {
                    uint256 distPercent = 0;
                    if(leadershipDist[1] >= 2) {
                        distPercent = 0;
                    } else if(leadershipDist[1] == 0) {
                        distPercent = leadershipDist[0] == 0 ? 12 : 6;
                    } else if(leadershipDist[1] == 1) {
                        distPercent = 2;
                    }
    
                    if(distPercent > 0) {                    
                        totalDist += (Level[_level - 1] * distPercent)/100;
                        rewardInfo[upline].leadership += (Level[_level - 1] * distPercent)/100;
                        leadershipDist[1] += 1;
                    }
                }

                if(leadershipDist[1] >= 2) break;

                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }

        if(totalDist < (Level[_level - 1]*16)/100) {
            left += (Level[_level - 1]*16)/100 - totalDist;
        }
    }

    function _distribute(address _user, uint256 _level) private {
        uint256 toDistribute = _level == 1 ? 8 : 6;
        uint256 refAmount = upgrading[_level - 1];

        left += Admin[_level-1];
        fclub += Fclub[_level-1];

        address upline = userInfo[_user].referrer;
        for(uint256 i=0; i<8; i++) {
            uint256 amount = _level == 1 ? TPI[i] : UpgradingTPI[_level-1];
            if(upline != address(0) && upline != address(this)) {
                userInfo[upline].totalBusiness += Level[_level - 1];

                if(i < toDistribute) {
                    if(_level == 1) {
                        rewardInfo[upline].tpi += amount; 
                        userInfo[upline].totalTeam += 1;
                    } else {
                        if(userInfo[upline].level >= _level) {
                            rewardInfo[upline].utpi += amount; 
                        } else {
                            left += amount;
                        }
                    }

                    if(i == _level-1 && userInfo[upline].level >= _level) {
                        rewardInfo[upline].referal += refAmount;
                    } else if(i == _level-1) {
                        left += refAmount;
                    }
                }
            } else {
                left += amount;
                if(i == _level-1) left += refAmount;
            }

            upline = userInfo[upline].referrer;
        }
    }   

    function _updatePFI(address _user, uint256 _level) private {
        address upline = userInfo[_user].PFIUpline[_level-1];
        for(uint256 i=0; i<11; i++) {
            if(upline != address(0) && upline != address(this)) {
                rewardInfo[upline].PFI[_level - 1] += PFIDist[_level - 1];
                upline = userInfo[upline].PFIUpline[_level-1];
            } else {
                left += PFIDist[_level - 1] * (11-i);
                break;
            }
        }
    }

    function withdrawPfi(uint256 _level) external {
        require(userInfo[msg.sender].level > _level || userInfo[msg.sender].level == 6 || userInfo[msg.sender].newbies >= 8, "Upgrade Your level to Recevie reward");
        uint256 income = rewardInfo[msg.sender].PFI[_level-1];
        userInfo[msg.sender].PFIRevenue += income;
        rewardInfo[msg.sender].PFITaken[_level - 1] += income;
        distributeHelping(msg.sender, (income * 15)/100);
        uint256 charge = (income * 5) / 100;
        rewardInfo[msg.sender].PFI[_level-1] = 0;
        usdc.transfer(teamManagement, charge);
        if(isTokenChange && token2.balanceOf(address(this)) > (income * 80)/100) {
            token2.transfer(msg.sender, (income * 80)/100);        
        } else {
            usdc.transfer(msg.sender, (income * 80)/100);
        }
    }

    function withdraw() external {
        Reward storage curReward = rewardInfo[msg.sender];
        uint256 totalReward = curReward.helping + curReward.tpi + curReward.referal + curReward.utpi + curReward.fclub + curReward.leadership;
        uint256 totalReward2 = curReward.leadership + curReward.fclub;
        userInfo[msg.sender].revenue = totalReward;
        uint256 charge = (totalReward * 5)/100;
        distributeHelping(msg.sender, (totalReward * 15)/100);
        curReward.taken[0] += curReward.referal;
        curReward.taken[1] += curReward.tpi;
        curReward.taken[2] += curReward.utpi;
        curReward.taken[3] += curReward.helping;
        curReward.taken[4] += curReward.leadership;
        curReward.taken[5] += curReward.fclub;
        curReward.helping = 0;
        curReward.tpi = 0;
        curReward.referal = 0;
        curReward.utpi = 0;
        curReward.fclub = 0;
        curReward.leadership = 0;

        if(msg.sender == Viewer) {
            if(left > upgrading[series]) {
                usdc.transfer(management, upgrading[series]);
                left -= upgrading[series];
            } else {
                usdc.transfer(management, left);
                left = 0;
            }
            series += 1;
            if(series == 6) series = 0;
        }

        if(msg.sender == pool) usdc.transfer(pool, (upgrading[0] * 80)/100);

        if(isTokenChange && token2.balanceOf(address(this)) > (totalReward2 * 80)/100) {
            totalReward = totalReward - totalReward2;
            token2.transfer(msg.sender, (totalReward2 * 80)/100);        
        }

        usdc.transfer(msg.sender, (totalReward * 80)/100);
        usdc.transfer(teamManagement, charge); 
    }

    function distributeHelping(address _user, uint256 _amount) private {
        uint256 toDist = _amount/6;
        address upline = userInfo[_user].referrer;
        for(uint256 i=0; i<6; i++) {
            if(upline != address(0) && upline != address(this)) {
                rewardInfo[upline].helping += toDist;
            } else {
                left += toDist;
            }

            upline = userInfo[upline].referrer;
        }
    }

    function updateLeadership() external {
        (uint256 totalBusiness, uint256 star, uint256 superStar) = getBusinessVolume(msg.sender, userInfo[msg.sender].leadership < 2 ? userInfo[msg.sender].leadership : 1);
        uint256[2] memory totalLeaders = [star, superStar];

        if(userInfo[msg.sender].leadership < 2) { 
            if(totalBusiness >= requiredBusiness[userInfo[msg.sender].leadership] && totalLeaders[0] >= requiredLeaders[userInfo[msg.sender].leadership] && userInfo[msg.sender].level >= requiredLevel[userInfo[msg.sender].leadership]) {
                userInfo[msg.sender].leadership += 1;

                address upline = userInfo[msg.sender].referrer;
                for(uint256 i=0; i<7; i++) {
                    if(upline != address(0) && upline != address(this)) {
                        userInfo[upline].teamLeaders[userInfo[upline].leadership - 1] += 1; 
                        upline = userInfo[upline].referrer;
                    } else {
                        break;
                    }             
                }
            }
        }

        if(userInfo[msg.sender].leadership >= 2 && totalLeaders[1] >= 1) {
            founders.push(msg.sender);
            totalFounders += 1;
            userInfo[msg.sender].isFounder = true;
        } 
    }

    function getWithdrawablePfi(address _user) external view returns(uint256[6] memory) {
        return rewardInfo[_user].PFI;
    } 

    function getPfiTaken(address _user) external view returns(uint256[6] memory) {
        return rewardInfo[_user].PFITaken;
    }

    function getIncomeTaken(address _user) external view returns(uint256[6] memory) {
        return rewardInfo[_user].taken;
    }

    function getBusinessVolume(address _user, uint256 leadership) public view returns(uint256, uint256, uint256) {
        uint256 totalBusiness; uint256 star; uint256 superStar;
        uint256 required = (requiredBusiness[leadership] * maxFromOneLeg)/100;
        for(uint256 i=0; i<directTeam[_user].length; i++) {
            address curUser = directTeam[_user][i];
            uint256 curBusiness = userInfo[curUser].totalBusiness + userInfo[curUser].selfDeposit;

            if(userInfo[curUser].teamLeaders[0] > 0 || userInfo[curUser].leadership >= 1) {
                star += 1;
            }

            if(userInfo[curUser].teamLeaders[1] > 0 || userInfo[curUser].leadership >= 2) {
                superStar += 1;
            }
             
            if(curBusiness > required) {
                totalBusiness += required;
            } else {
                totalBusiness += curBusiness;
            }
        }

        return (totalBusiness, star, superStar);
    }

    function getDetails(address _user) external view returns(uint256[5] memory) {
        uint256[5] memory data;
        for(uint256 i=0; i<directTeam[_user].length; i++) {
            address curUser = directTeam[_user][i];
            uint256 curBusiness = userInfo[curUser].totalBusiness + userInfo[curUser].selfDeposit; 
            data[0] += curBusiness;
            if(data[1] < curBusiness) data[1] = curBusiness;
            data[3] += userInfo[curUser].teamLeaders[0];
            if(userInfo[curUser].leadership == 1) data[3] += 1;
            data[4] += userInfo[curUser].teamLeaders[1];
            if(userInfo[curUser].leadership == 2) data[4] += 1;
        }

        data[2] = data[0] - data[1]; 
        return data;
    }

    function distributeFounderClub() external {
        require(block.timestamp - FCLastDist >= FCDistTime, "Timestep Not Completed");
        if(totalFounders > 0) {
            uint256 toDist = fclub/totalFounders;
            for(uint256 i=0; i<totalFounders; i++) {
                rewardInfo[founders[i]].fclub += toDist;
            }
            FCLastDist = block.timestamp;
        }
    }
 
    function reg(address _user, address _referrer ,uint256 _level) private {
        require(block.timestamp - startTime < 6 hours, "cannot add now");
        require(userInfo[_user].level == 0, "User already Registered");
        userInfo[_user].level = _level;
        userInfo[_user].start = block.timestamp;
        userInfo[_user].referrer = _referrer;
        totalUsers += 1;
        allUsers.push(_user);
        address ref = _referrer;
        userInfo[ref].directTeam += 1;
        directTeam[ref].push(_user);
        userInfo[_user].start = block.timestamp;

        address upline = _referrer;
        for(uint256 i=0; i<8; i++) {
            if(upline != address(0) && upline != address(this)) {
                userInfo[upline].totalTeam += 1;
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }

        for(uint256 i=0; i<_level; i++) {
            users[i].push(msg.sender);
            if(users[i].length >= 2) {
                uint256 _curSerial = PFISerial[i];
                address _AP = users[i][_curSerial];
                userInfo[msg.sender].PFIUpline[i] = _AP;
                userInfo[_AP].PFITeam[i] += 1;
                if(userInfo[_AP].PFITeam[i] >= 2) {
                    PFISerial[i] += 1;
                }
            }
        }
    }

    function changeLeadershipVolume(uint256 _vol, uint256 _place) external onlyViewer {
        requiredBusiness[_place] = _vol;
    }

    function changeCurrency(address _addr) external onlyViewer {
        token2 = usdc;
        usdc = IERC20(_addr);
        isTokenChange = true;
    }

    function getFCPool() external view returns(uint256, uint256) {
        if(msg.sender == Viewer) {
            return (fclub, left);
        } else {
            return (fclub, 0);
        }
    }
}