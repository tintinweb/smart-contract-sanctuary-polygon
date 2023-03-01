/**
 *Submitted for verification at polygonscan.com on 2023-03-01
*/

// SPDX-License-Identifier: MIT

// ██╗░░░░░██╗░░░██╗███╗░░██╗██╗░░██╗  ░█████╗░██╗░░██╗░█████╗░██╗███╗░░██╗
// ██║░░░░░╚██╗░██╔╝████╗░██║╚██╗██╔╝  ██╔══██╗██║░░██║██╔══██╗██║████╗░██║
// ██║░░░░░░╚████╔╝░██╔██╗██║░╚███╔╝░  ██║░░╚═╝███████║███████║██║██╔██╗██║
// ██║░░░░░░░╚██╔╝░░██║╚████║░██╔██╗░  ██║░░██╗██╔══██║██╔══██║██║██║╚████║
// ███████╗░░░██║░░░██║░╚███║██╔╝╚██╗  ╚█████╔╝██║░░██║██║░░██║██║██║░╚███║
// ╚══════╝░░░╚═╝░░░╚═╝░░╚══╝╚═╝░░╚═╝  ░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝



pragma solidity 0.8.11;

contract LYNXCHAIN {
    address public marketingWallet;
    address public devWallet;

    struct Deposit {
        uint256 amount;
        uint40 time;
        uint256 withdrawn;
    }

    struct RoiUser {
        uint256 dividends;
        uint256 match_bonus;
        uint40 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_match_bonus;
        address payable upline;
        Deposit[] deposits;
        uint256[3] structure;
        uint256[3] refEarningL;
    }

    mapping(address => RoiUser) public roiUsers;

    mapping(uint256 => uint256) public Payment_Received_List_Pool;
    mapping(uint256 => uint256) public depositeDayWise;
    mapping(uint256 => uint256) public withdrawlDayWise;
    mapping(uint256 => uint256) public roiPercentageDayWise;
    uint256[3] ref_earnings = [50, 25, 5];

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public match_bonus;
    uint256 public total_users;

    uint8 constant BONUS_LINES_COUNT = 3;
    uint16 constant PERCENT_DIVIDER = 1000;
    uint16 constant BASE_PERCENT = 50;
    uint16 constant MAX_PERCENT = 250;
    uint40 constant total_returns = 200;
    uint40 public TIME_STEP = 86400;
    uint40 public IntervalTime = 86400;
    uint256 public startTime;

    event NewDeposit(address indexed addr, uint256 amount);
    event ReInvest(address indexed addr, uint256 amount);
    event MatchPayout(
        address indexed addr,
        address indexed from,
        uint256 amount
    );
    event Withdraw(address indexed addr, uint256 amount);

    constructor(
        address _marketingWallet,
        address _devWallet,
        uint256 _startTime
    ) {
        marketingWallet = _marketingWallet;
        devWallet = _devWallet;
        startTime = _startTime;
    }

    function getCurrentDayIndex() public view returns (uint256) {
        return ((block.timestamp - startTime) / IntervalTime) + 1;
    }

    function setRoiPercentage() internal {
        uint256 _dayIndex =  getCurrentDayIndex();
        if(roiPercentageDayWise[_dayIndex]==0)
        {
            roiPercentageDayWise[_dayIndex]=calculateRoi(_dayIndex);
        }
    }

    function deposit(address payable _upline) external payable {
        require(msg.value >= 10 ether, "Minimum deposit amount is 10 matic");
        _deposit(msg.sender, _upline, msg.value);
    }

    function _deposit(
        address _user,
        address payable _upline,
        uint256 amount
    ) internal {
        setRoiPercentage();
        RoiUser storage player = roiUsers[_user];

        require(player.deposits.length < 100, "Max 100 deposits per address");
        player.deposits.push(
            Deposit({amount: amount, time: uint40(block.timestamp),withdrawn:0})
        );
        if (player.total_invested == 0) {
            total_users++;
        }
        _setUpdaddy(_user, _upline);
        player.total_invested += amount;
        invested += amount;
        _refPayout(_user, amount);

        
        uint256 dayIndex = getCurrentDayIndex();
        depositeDayWise[dayIndex] += msg.value;
        payable(marketingWallet).transfer((amount * 8) / 100);
        payable(devWallet).transfer((amount * 2) / 100);
        emit NewDeposit(_user, amount);
    }

    function _payout(address _addr) private {
        uint256 payout = payoutOf(_addr);

        if (payout > 0) {
            roiUsers[_addr].last_payout = uint40(block.timestamp);
            roiUsers[_addr].dividends += payout;
        }
    }

    function withdraw() external {
        RoiUser storage player = roiUsers[msg.sender];
        setRoiPercentage();
        _payout(msg.sender);

        require(player.dividends > 0 || player.match_bonus > 0, "Zero amount");

        uint256 amount = player.dividends + player.match_bonus;
        require(amount>0,"Nothing to withdraw");
        player.dividends = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

        
        uint256 dayIndex = getCurrentDayIndex();
        withdrawlDayWise[dayIndex] += amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function reInvest() external
    {
        setRoiPercentage();
        RoiUser storage player = roiUsers[msg.sender];
        _payout(msg.sender);
        uint256 amount = player.dividends + player.match_bonus;
        require(amount>0,"Nothing to reinvest");
        player.dividends = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;

        player.deposits.push(
            Deposit({amount: amount, time: uint40(block.timestamp),withdrawn:0})
        );
        player.total_invested += amount;
        invested += amount;
        uint256 dayIndex = getCurrentDayIndex();
        depositeDayWise[dayIndex] += amount;
        emit ReInvest(msg.sender, amount);
    }

    function calculateRoi(uint256 _dayIndex) public view returns(uint256)
    {
        if (_dayIndex > 2) {
            uint256 oldRoi = roiPercentageDayWise[_dayIndex-1];
            if(roiPercentageDayWise[_dayIndex-1]<BASE_PERCENT){
                oldRoi = getRoiPercentageIndexWise(_dayIndex-1,roiPercentageDayWise[_dayIndex-2]);
            }
            return getRoiPercentageIndexWise(_dayIndex,oldRoi);
        }
        return BASE_PERCENT;
    }

    function getRoiPercentageIndexWise(uint256 _dayIndex,uint256 roi) internal view returns (uint256) {
        uint256 day1volume = 0;
        uint256 day2volume = 0;
        
            if (
                depositeDayWise[_dayIndex - 2] > withdrawlDayWise[_dayIndex - 2]
            ) {
                day1volume =
                    depositeDayWise[_dayIndex - 2] -
                    withdrawlDayWise[_dayIndex - 2];
            }
            if (depositeDayWise[_dayIndex-1] > withdrawlDayWise[_dayIndex-1]) {
                day2volume =
                    depositeDayWise[_dayIndex-1] -
                    withdrawlDayWise[_dayIndex-1];
            }
            if (day1volume>0 && day2volume > day1volume) {
                uint256 growth = day2volume - day1volume;
                uint256 percentageGrowth = (growth * 100) / day1volume;
                uint256 percentage = (roi * percentageGrowth) / 100;
                if((roi + percentage)>MAX_PERCENT)
                {
                    return MAX_PERCENT;
                }else{
                return roi + (percentage);
                }
            }
            else if(day2volume>0 && day1volume > day2volume)
            {
                uint256 growth = day1volume - day2volume;
                uint256 percentageGrowth = (growth * 100) / day1volume;
                uint256 percentage = (roi * percentageGrowth) / 100;
                if((roi-percentage)>BASE_PERCENT){
                    return roi - (percentage);
                }
            }
            else if((day1volume>0 && day2volume==0) || (day1volume==0 && day2volume==0)){
                if(roi>BASE_PERCENT*2){
                    return roi-BASE_PERCENT;
                }
            }
            
        return BASE_PERCENT;
    }


    function payoutOf(address _addr) internal returns (uint256 value) {
        uint256 _dayIndex = getCurrentDayIndex();
        RoiUser storage player = roiUsers[_addr];
        uint256 roiPercentage = calculateRoi(_dayIndex);
        for (uint256 i = 0; i < player.deposits.length; i++) {
            uint256 dividends = 0;
            Deposit storage dep = player.deposits[i];

            uint40 from = player.last_payout > dep.time
                ? player.last_payout
                : dep.time;
            uint40 to = uint40(block.timestamp);

            if (from < to) {
                dividends =
                    ((dep.amount * (to - from)) * roiPercentage) /
                    (TIME_STEP * 10000);
            }
            if((dividends+dep.withdrawn)>dep.amount*2)
            {
                dividends = (dep.amount*2)-dep.withdrawn;
            }
            dep.withdrawn += dividends;
            value+= dividends;
        }
        return value;
    }

    function getAvailableRoi(address _addr) external view returns (uint256 value) {
        uint256 _dayIndex = getCurrentDayIndex();
        RoiUser storage player = roiUsers[_addr];
        uint256 roiPercentage = calculateRoi(_dayIndex);
        for (uint256 i = 0; i < player.deposits.length; i++) {
            uint256 dividends = 0;
            Deposit storage dep = player.deposits[i];

            uint40 from = player.last_payout > dep.time
                ? player.last_payout
                : dep.time;
            uint40 to = uint40(block.timestamp);

            if (from < to) {
                dividends =
                    ((dep.amount * (to - from)) * roiPercentage) /
                    (TIME_STEP * 10000);
            }
            if((dividends+dep.withdrawn)>dep.amount*2)
            {
                dividends = (dep.amount*2)-dep.withdrawn;
            }
            value+= dividends;
        }
        return value;
    }

    function _setUpdaddy(address _addr, address payable _upline) private {
        if (
            roiUsers[_addr].upline == address(0) &&
            roiUsers[_upline].deposits.length > 0 && _upline!=address(0)
        ) {
            roiUsers[_addr].upline = _upline;

            for (uint256 i = 0; i < 3; i++) {
                roiUsers[_upline].structure[i]++;

                _upline = roiUsers[_upline].upline;

                if (_upline == address(0)) break;
            }
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = roiUsers[_addr].upline;
        for (uint8 i = 0; i < ref_earnings.length; i++) {
            if (up == address(0)) break;

            uint256 bonus = (_amount * ref_earnings[i]) / PERCENT_DIVIDER;

            roiUsers[up].match_bonus += bonus;
            roiUsers[up].total_match_bonus += bonus;
            roiUsers[up].refEarningL[i]+=bonus;
            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = roiUsers[up].upline;
        }
    }

    function userInfo(address _addr)
        external
        view
        returns (
            uint256 for_withdraw,
            uint256 total_invested,
            uint256 total_withdrawn,
            uint256 total_match_bonus,
            uint256[BONUS_LINES_COUNT] memory structure,
            uint256 [BONUS_LINES_COUNT] memory _refEarningL
        )
    {
        RoiUser storage player = roiUsers[_addr];

        uint256 payout = this.getAvailableRoi(_addr);

        for (uint8 i = 0; i < ref_earnings.length; i++) {
            structure[i] = player.structure[i];
            _refEarningL[i] = player.refEarningL[i];
        }

        return (
            payout + player.dividends + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            structure,
            _refEarningL
        );
    }

    function contractInfo()
        external
        view
        returns (
            uint256 _invested,
            uint256 _withdrawn,
            uint256 _match_bonus,
            uint256 _total_users
        )
    {
        return (invested, withdrawn, match_bonus, total_users);
    }

    function getDepositeList(address _user)
        external
        view
        returns (Deposit[] memory deposits)
    {
        return roiUsers[_user].deposits;
    }
}