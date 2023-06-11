/**
 *Submitted for verification at polygonscan.com on 2023-06-10
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Blockocean {
    IERC20 public USDT = IERC20(0x1f3ca1e22E1A5c83a7820b0e1f2FFb5EcbdD3B9f);
    address public defaultRefer;
    uint256[7] public slots = [50e6, 100e6, 250e6, 500e6, 1000e6, 2500e6, 5000e6];
    uint256[7] public AP4x2Layer1 = [5e6, 10e6, 25e6, 50e6, 100e6, 200e6, 400e6];
    uint256[7] public AP4x2Layer2 = [20e6, 40e6, 100e6, 200e6, 400e6, 800e6, 1600e6];
    uint256[7] public AP3x3Layer1 = [20e6, 40e6, 100e6, 200e6, 400e6, 800e6, 1600e6];
    uint256[7] public AP3x3Layer2 = [20e6, 40e6, 100e6, 200e6, 400e6, 800e6, 1600e6];
    uint256[7] public AP3x3Layer3 = [60e6, 120e6, 300e6, 600e6, 1200e6, 2400e6, 4800e6];
    uint256[7] private charges = [2e6, 5e6, 5e6, 5e6, 5e6, 5e6, 5e6];
    uint256[4] private rankDirect = [8, 8, 8, 8];
    uint256[4] private rankLayer2 = [16, 16, 16, 16];
    uint256[4] private rankLayer3 = [0, 0, 0, 32];
    uint256[4] private rankTotalTeam = [100, 200, 500, 1000]; 
    uint256 private constant refPercent = 50;
    uint256 private constant otherPercent = 50;
    uint256 private constant GPDirectRequired = 4;
    address[] public users;
    uint256 public totalUsers;
    uint256 private idSerial = 100000;
    uint256 public Left;
    mapping(uint256 => address[]) public globalpool4x2;
    mapping(uint256 => address[]) public globalpool3x3;
    uint256 private APIndex4x2;
    uint256 private APIndex3x3;
    uint256 private APLayer4x2;
    uint256 private APLayer3x3;

    struct User {
        uint256 id;
        uint256 rank;
        uint256 slots;
        uint256 start;
        address referrer;
        address mainUpline;
        uint256 directTeam;
        uint256 totalTeam;
        uint256 passUpTeam;
        uint256 directBusiness;
        uint256 totalBusiness;
        uint256[7] APTeam4x2;
        uint256[7] APTeam3x3;
        address[7] APUpline4x2;
        address[7] APUpline3x3;
    }

    struct Reward {
        uint256 refIncome;
        uint256 layerIncome;
        uint256 rankIncome;
        uint256 totalRevenue;
        uint256 selfUpgrade;
        uint256[3] incomeTaken;
        uint256[7] serial;
        uint256[7] APIncome4x2;
        uint256[7] APIncome3x3;
        uint256[7] APTaken4x2;
        uint256[7] APTaken3x3;
    }

    mapping(address => User) public userInfo;
    mapping(address => Reward) public rewardInfo;
    mapping(uint256 => address[]) public rankedUsers;
    mapping(address => address[]) public passUpTeam;
    mapping(address => mapping(uint256 => address[])) public teamUsers;
    mapping(uint256 => address) public ids;
    uint256[4] public rankPool;

    constructor() {
        defaultRefer = address(this);
    }

    function register(address _ref) external {
        User storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "Referrer Boned");
        require(userInfo[_ref].slots > 0 || _ref == defaultRefer, "Invalid Referrer");
        user.referrer = _ref;
        user.start = block.timestamp;
        user.id = idSerial + 1;
        ids[user.id] = msg.sender;
        idSerial += 1;
    }

    function buySlot(uint256 _slot) external {
        uint256 totalAmount = slots[_slot - 1] + charges[_slot - 1];
        if(rewardInfo[msg.sender].selfUpgrade >= totalAmount) {
            totalAmount -= slots[_slot - 1];
        } else {
            totalAmount -= rewardInfo[msg.sender].selfUpgrade;
        }
        
        USDT.transferFrom(msg.sender, address(this), totalAmount);
        Left += charges[_slot - 1];
        _buySlot(msg.sender, _slot);
    }

    function _buySlot(address _user, uint256 _slot) private {
        User storage user = userInfo[_user];
        require(user.referrer != address(0), "Register First");
        require(_slot == user.slots + 1 && _slot < 8, "Invalid Slot Purchase");

        if(user.slots == 0) {
            users.push(_user);
            totalUsers += 1;
            userInfo[user.referrer].directTeam += 1;
            userInfo[user.referrer].directBusiness += slots[_slot - 1];
            if((userInfo[user.referrer].directTeam == 1 || userInfo[user.referrer].directTeam == 3) && user.referrer != defaultRefer) {
                user.mainUpline = userInfo[user.referrer].mainUpline;
                userInfo[user.mainUpline].passUpTeam += 1;
            } else {
                user.mainUpline = user.referrer;
            }
        }

        _updateUpline(_user, _slot);
        updateLevel(user.referrer);
        if(userInfo[user.referrer].directTeam == GPDirectRequired && _slot == 1) _updateAP4x2(user.referrer, _slot);
        if(_slot > 1) _updateAP4x2(_user, _slot);
        user.slots += 1;

        if(user.mainUpline != address(0) && userInfo[user.mainUpline].slots >= user.slots) {
            uint256 curPercent = 100;
            if(rewardInfo[user.mainUpline].serial[_slot - 1] == 0) {
                uint256 distAmt = ((slots[_slot - 1] * otherPercent)/100)/5;
                for(uint256 i=0; i<4; i++) {
                    rankPool[i] += distAmt;
                }
                Left += distAmt;
                curPercent = refPercent;
            } else if(rewardInfo[user.mainUpline].serial[_slot - 1] == 1) {
                curPercent = refPercent;
            } else if(rewardInfo[user.mainUpline].serial[_slot - 1] > 1 && rewardInfo[user.mainUpline].selfUpgrade < slots[_slot - 1] && user.slots == userInfo[user.mainUpline].slots) {
                rewardInfo[user.mainUpline].selfUpgrade += (slots[_slot - 1] * otherPercent)/100;
                curPercent = refPercent;
            }

            rewardInfo[user.mainUpline].refIncome += (slots[_slot - 1] * curPercent)/100;
            rewardInfo[user.mainUpline].totalRevenue += (slots[_slot - 1] * curPercent)/100;
            rewardInfo[user.referrer].serial[_slot - 1] += 1;
        } else {
            Left += slots[_slot - 1];
        }
    }

    function _updateUpline(address _user, uint256 _slot) private {
        address upline = userInfo[_user].referrer;
        for(uint256 i=0; i<29; i++) {
            if(upline != address(0)) {
                if(i < 3) {
                    teamUsers[upline][i+1].push(_user);
                }
                userInfo[upline].totalTeam += 1;
                userInfo[upline].totalBusiness += slots[_slot - 1];
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    } 

    function _updateAP4x2(address _user, uint256 _slot) private {
        globalpool4x2[_slot].push(_user);
        if(globalpool4x2[_slot].length > 1) {
            address _curUpline = globalpool4x2[_slot][APIndex4x2];
            userInfo[_user].APUpline4x2[_slot - 1] = _curUpline;
            userInfo[_curUpline].APTeam4x2[_slot - 1] += 1;
            if(userInfo[_curUpline].APTeam4x2[_slot - 1] == 4) {
                APIndex4x2 += 1;
            }
            rewardInfo[_curUpline].APIncome4x2[_slot - 1] += AP4x2Layer1[_slot - 1];
            rewardInfo[_curUpline].totalRevenue += AP4x2Layer1[_slot - 1];

            address secondUpline = userInfo[_curUpline].APUpline4x2[_slot - 1];
            if(secondUpline != address(0)) {
                userInfo[secondUpline].APTeam4x2[_slot - 1] += 1;
                if(userInfo[secondUpline].APTeam4x2[_slot - 1] > 8) {
                    rewardInfo[secondUpline].APIncome4x2[_slot - 1] += AP4x2Layer2[_slot - 1];
                    rewardInfo[secondUpline].totalRevenue += AP4x2Layer2[_slot - 1];
                }
                if(userInfo[secondUpline].APTeam4x2[_slot - 1] == 8) {
                    _updateAP3x3(secondUpline, _slot);
                }
            }
        }
    }

    function _updateAP3x3(address _user, uint256 _slot) private { 
        if(globalpool3x3[_slot].length > 1) {
            globalpool3x3[_slot].push(_user);
            address _curUpline = globalpool3x3[_slot][APIndex3x3];
            userInfo[_user].APUpline3x3[_slot - 1] = _curUpline;
            userInfo[_curUpline].APTeam3x3[_slot - 1] += 1;
            if(userInfo[_curUpline].APTeam3x3[_slot - 1] == 3) {
                APIndex3x3 += 1;
            }
            rewardInfo[_curUpline].APIncome3x3[_slot - 1] += AP3x3Layer1[_slot - 1];
            rewardInfo[_curUpline].totalRevenue += AP3x3Layer1[_slot - 1];

            address secondUpline = userInfo[_curUpline].APUpline3x3[_slot - 1];
            if(secondUpline != address(0)) {
                rewardInfo[secondUpline].APIncome3x3[_slot - 1] += AP3x3Layer2[_slot - 1];
                rewardInfo[secondUpline].totalRevenue += AP3x3Layer2[_slot - 1];
            }

            address thirdUpline = userInfo[secondUpline].APUpline3x3[_slot - 1];
            if(thirdUpline != address(0)) {
                rewardInfo[thirdUpline].APIncome3x3[_slot - 1] += AP3x3Layer3[_slot - 1];
                rewardInfo[thirdUpline].totalRevenue += AP3x3Layer3[_slot - 1];
            }
        }
    }

    function updateLevel(address _user) public {
        User storage user = userInfo[_user];
        if(user.rank < 4) {
            (uint256[2] memory layer, uint256[3] memory total, uint256[2] memory strong) = checkRankTeams(_user);

            bool isValid;
            if(
                total[0] >= (rankTotalTeam[user.rank] * 20)/100 
                && total[1] >= (rankTotalTeam[user.rank] * 20)/100 
                && strong[0] >= (rankTotalTeam[user.rank] * 30)/100
                && strong[1] >= (rankTotalTeam[user.rank] * 30)/100
            ){
                isValid = true;
            } else if(
                (total[0] >= (rankTotalTeam[user.rank] * 40)/100 || total[1] >= (rankTotalTeam[user.rank] * 40)/100)
                && strong[0] >= (rankTotalTeam[user.rank] * 40)/100
                && strong[1] >= (rankTotalTeam[user.rank] * 40)/100
            ){
                isValid = true;
            }

            if(user.directTeam >= rankDirect[user.rank] 
            && layer[0] >= rankLayer2[user.rank] 
            && layer[1] >= rankLayer3[user.rank] 
            && total[2] >= rankTotalTeam[user.rank]
            && isValid) 
            {
                user.rank += 1;
                rankedUsers[user.rank].push(_user);
            }
        } 
    }

    function withdraw() external {
        Reward storage reward = rewardInfo[msg.sender];
        uint256 total = reward.refIncome + reward.layerIncome + reward.rankIncome;
        reward.incomeTaken[0] += reward.refIncome;
        reward.incomeTaken[1] += reward.layerIncome;
        reward.incomeTaken[2] += reward.rankIncome;
        reward.refIncome = 0;
        reward.layerIncome = 0;
        reward.rankIncome = 0;
        for(uint256 i=0; i<7; i++) {
            total += reward.APIncome4x2[i];
            reward.APTaken4x2[i] += reward.APIncome4x2[i];
            reward.APIncome4x2[i] = 0;
        }
        for(uint256 i=0; i<7; i++) {
            total += reward.APIncome3x3[i];
            reward.APTaken3x3[i] += reward.APIncome3x3[i];
            reward.APIncome3x3[i] = 0;
        }
        USDT.transfer(msg.sender, total);
    }

    function distributeRankPool(uint256 _rank) external {
        if(rankedUsers[_rank].length > 0 && rankPool[_rank - 1] > 0) {
            uint256 totalDist;
            uint256 toDist = rankPool[_rank - 1]/rankedUsers[_rank].length;
            for(uint256 i=0; i<rankedUsers[_rank].length; i++) {
                if(userInfo[rankedUsers[_rank][i]].rank == _rank) {
                    rewardInfo[rankedUsers[_rank][i]].rankIncome += toDist;
                    rewardInfo[rankedUsers[_rank][i]].totalRevenue += toDist;
                    totalDist += toDist;
                }
            }

            if(totalDist < rankPool[_rank]) {
                rankPool[_rank] = rankPool[_rank] - totalDist;
            } else {
                rankPool[_rank] = 0;
            }
        }
    }

    function checkRankTeams(address _user) public view returns(uint256[2] memory layer, uint256[3] memory total, uint256[2] memory strong) {
        for(uint256 i=0; i<userInfo[_user].directTeam; i++) {
            address _curUser = teamUsers[_user][1][i];

            if(i < 4) {
                if(userInfo[_curUser].directTeam >= 4) {
                    layer[0] += 4;
                } else {
                    layer[0] += userInfo[_curUser].directTeam;
                }

                layer[1] += teamUsers[_curUser][2].length; 
            }

            if(i == 0) total[0] += userInfo[_curUser].totalTeam;   
            if(i == 2) total[1] += userInfo[_curUser].totalTeam;   
            total[2] += userInfo[_curUser].totalTeam + 1;

            if(userInfo[_curUser].totalTeam > strong[0]) {
                strong[1] = strong[0];
                strong[0] = userInfo[_curUser].totalTeam;
            } else if(userInfo[_curUser].totalTeam > strong[1]) {
                strong[1] = userInfo[_curUser].totalTeam;
            }
        }
    }

    function getUsersLength(address _user, uint256 _layer) external view returns(uint256 length) {
        length = teamUsers[_user][_layer].length;
    }

    function getGPTeam(address _user) external view returns(uint256[7] memory, uint256[7] memory) {
        return (userInfo[_user].APTeam4x2, userInfo[_user].APTeam3x3);
    }

    function getGPTaken(address _user) external view returns(uint256[7] memory, uint256[7] memory) {
        return (rewardInfo[_user].APTaken4x2, rewardInfo[_user].APTaken3x3);
    }

    function getGPIncome(address _user) external view returns(uint256[7] memory, uint256[7] memory) {
        return (rewardInfo[_user].APIncome4x2, rewardInfo[_user].APIncome3x3);
    }

    function getIncomeTaken(address _user) external view returns(uint256[3] memory) {
        return rewardInfo[_user].incomeTaken;
    }
}