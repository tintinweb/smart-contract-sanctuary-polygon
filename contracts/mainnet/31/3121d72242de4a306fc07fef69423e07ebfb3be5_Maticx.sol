/**
 *Submitted for verification at polygonscan.com on 2022-02-24
*/

// SPDX-License-Identifier: MIT

/* 


███╗   ███╗ █████╗ ████████╗██╗ ██████╗██╗  ██╗
████╗ ████║██╔══██╗╚══██╔══╝██║██╔════╝╚██╗██╔╝
██╔████╔██║███████║   ██║   ██║██║      ╚███╔╝ 
██║╚██╔╝██║██╔══██║   ██║   ██║██║      ██╔██╗ 
██║ ╚═╝ ██║██║  ██║   ██║   ██║╚██████╗██╔╝ ██╗
╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝
                                               


(c) 2022 by maticx.app
Website: https://maticx.app


 */

pragma solidity =0.7.0;
pragma experimental ABIEncoderV2;

contract Helpers {
    using SafeMath for uint256;

    uint256 public LAUNCH_TIME;
    uint256 public DAY_TIME_STEP = 1 days;

    modifier mustStarted() {
        require(block.timestamp > LAUNCH_TIME, "!afterStated");

        _;
    }

    constructor() {
        LAUNCH_TIME = 1646049600;
    }

    function getCurrentDays() public view returns (uint256) {
        if (getNow() < LAUNCH_TIME) return 0;

        return getNow().sub(LAUNCH_TIME).div(DAY_TIME_STEP);
    }

    function getCurrentDayTimes()
        public
        view
        returns (uint256 _startedAt, uint256 _endAt)
    {
        uint256 _pastDays = getCurrentDays();

        /* for (uint256 i = 0; i < _pastDays; i++) {
            _startedAt = _startedAt.add(i.mul(DAY_TIME_STEP));
            _endAt = _startedAt.add(DAY_TIME_STEP);
        } */
        _startedAt = LAUNCH_TIME.add(_pastDays.mul(DAY_TIME_STEP));
        _endAt = _startedAt.add(DAY_TIME_STEP);

        return (_startedAt, _endAt);
    }

    function isCurrentDay(uint256 _timeAt) public view returns (bool) {
        uint256 _startedAt;
        uint256 _endAt;

        (_startedAt, _endAt) = getCurrentDayTimes();

        if (_timeAt >= _startedAt && _timeAt <= _endAt) {
            return true;
        } else {
            return false;
        }
    }

    function getNow() public view returns (uint256) {
        return block.timestamp;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

contract Lotto {
    using SafeMath for uint256;

    address payable public LAST_PLAYER;
    address public MATICX_ADDRESS;
    uint256 public LAST_PLAYER_AT;
    uint256 public LOTTO_TOTAL;
    uint256 public LOTTO_TIME = 20 minutes;
    uint256 public LOTTO_NUMBER;

    struct Winner {
        address player;
        uint256 total;
        uint256 createdAt;
    }

    mapping(uint256 => Winner) public WINNERS;

    event OnExecute(address indexed user, uint256 amount, uint256 createdAt);
    event OnSave(uint256 amount);

    modifier mustMaticx() {
        require(msg.sender == MATICX_ADDRESS, "!mustMaticx");

        _;
    }

    constructor(address _maticx) {
        MATICX_ADDRESS = _maticx;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function save(address payable _player) public payable mustMaticx() {
        if (
            LOTTO_TIME.add(LAST_PLAYER_AT) >= block.timestamp ||
            (LAST_PLAYER == address(0) && LAST_PLAYER_AT == 0)
        ) {
            LAST_PLAYER = _player;
            LAST_PLAYER_AT = block.timestamp;
            LOTTO_TOTAL = LOTTO_TOTAL.add(msg.value);

            emit OnSave(msg.value);
        }
    }

    function execute() public {
        if (LOTTO_TIME.add(LAST_PLAYER_AT) < block.timestamp) {
            uint256 _amount = getBalance();

            if (_amount > 0 && LAST_PLAYER != address(0)) {
                WINNERS[LOTTO_NUMBER] = Winner(
                    LAST_PLAYER,
                    _amount,
                    block.timestamp
                );

                LAST_PLAYER.transfer(getBalance());
                LAST_PLAYER = address(0);
                LAST_PLAYER_AT = 0;

                LOTTO_NUMBER++;

                emit OnExecute(LAST_PLAYER, _amount, block.timestamp);
            }
        }
    }

    function getLottoLastPlayer() external view returns (address, uint256) {
        return (LAST_PLAYER, LAST_PLAYER_AT);
    }

    function getLottoNumber() external view returns (uint256) {
        return LOTTO_NUMBER;
    }

    function getLottoWinner(uint256 _number)
        external
        view
        returns (
            address,
            uint256,
            uint256
        )
    {
        return (
            WINNERS[_number].player,
            WINNERS[_number].total,
            WINNERS[_number].createdAt
        );
    }
}

contract TeamGift is Helpers {
    address payable public MATICX_ADDRESS;
    uint256 public TEAM_REINVEST_DAYS;

    event OnSave(uint256 amount);
    event OnExecute(uint256 amount, uint256 createdAt);

    constructor(address payable _maticx, uint256 _days) {
        MATICX_ADDRESS = _maticx;
        TEAM_REINVEST_DAYS = _days;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function save() public payable {
        emit OnSave(msg.value);
    }

    function execute() public {
        if (Helpers.getCurrentDays() >= TEAM_REINVEST_DAYS) {
            uint256 _totalAmount = getBalance();

            if (_totalAmount > 0) {
                MATICX_ADDRESS.transfer(_totalAmount);

                emit OnExecute(_totalAmount, Helpers.getNow());
            }
        }
    }
}

interface ILotto {
    function getBalance() external view returns (uint256);

    function save(address payable _player) external payable;

    function execute() external;

    function getLottoLastPlayer() external view returns (address, uint256);

    function getLottoNumber() external view returns (uint256);

    function getLottoWinner(uint256 _number)
        external
        view
        returns (
            address,
            uint256,
            uint256
        );
}

interface ITeamGift {
    function getBalance() external view returns (uint256);

    function save() external payable;

    function execute() external;
}

contract Maticx is Helpers {
    using SafeMath for uint256;

    struct Ranker {
        address user;
        uint256 total;
    }

    struct Player {
        bool exists;
        address referrer;
        uint256[2] levels;
        Deposit[] deposits;
        uint256 createdAt;
        uint256 bonus;
        uint256 totalBonus;
    }

    struct Plan {
        uint256 at;
        uint256 time;
        uint256 basePercent;
    }

    struct Deposit {
        uint256 plan;
        uint256 percent;
        uint256 amount;
        uint256 profit;
        uint256 startAt;
        uint256 finishAt;
        bool withdrawProfit;
        bool withdrawDeposit;
    }

    uint256 public constant STAKE_MIN_AMOUNT = 5 ether; // 5 MATIC
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant DAY_PERCENTS = 50; // need div PERCENTS_DIVIDER
    uint256 public constant TEAM_PERCENT = 150;
    uint256 public constant TEAM_GIFT_PERCENT = 300;
    uint256 public constant TEAM_LOTTO_PERCENT = 100;
    uint256 public constant TEAM_REINVEST_DAYS = 13;
    uint256 public constant TIME_FOR_ENABLE_PLAN0 = 0;
    uint256 public constant TIME_FOR_ENABLE_PLAN1 = 72 hours;
    uint256 public constant TIME_FOR_ENABLE_PLAN2 = 144 hours;
    uint256 public constant TIME_FOR_LOCKED_PLAN0 = 9 days;
    uint256 public constant TIME_FOR_LOCKED_PLAN1 = 6 days;
    uint256 public constant TIME_FOR_LOCKED_PLAN2 = 3 days;

    uint256[5] public REFERRAL_PERCENTS = [50, 25, 10, 10, 10]; // need div PERCENTS_DIVIDER
    uint256[3] public PLAN_BASE_PERCENTS = [500, 350, 200]; // need div PERCENTS_DIVIDER
    uint256[3] public PLAN_MAX_PERCENTS = [600, 450, 300]; // need div PERCENTS_DIVIDER

    uint256 public TOTAL_PLAYERS;
    uint256 public TOTAL_STAKED;

    address payable public TEAM_ADDRESS;

    ILotto public LOTTO_ADDRESS;
    ITeamGift public TEAM_GIFT_ADDRESS;

    mapping(address => Player) public PLAYERS; // address => player
    mapping(uint256 => address) public PLAYERS_ID; // id => address

    Plan[3] public PLANS;

    event Newbie(address user);
    event NewStake(
        address indexed user,
        uint8 plan,
        uint256 percent,
        uint256 amount,
        uint256 profit,
        uint256 start,
        uint256 finish
    );
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event OnFeePayed(address indexed user, uint256 totalAmount);
    event OnProfitPayed(address indexed user, uint256 amount);
    event OnBonusPayed(address indexed user, uint256 amount);
    event OnLottoPayed(address indexed user, uint256 amount);
    event OnWithdrawn(address indexed user, uint256 amount);
    event OnGift(uint256 amount);

    modifier mustPlanOpened(uint256 _planID) {
        require(Helpers.getNow() >= PLANS[_planID].at, "!mustPlanOpened");
        _;
    }

    modifier beforeExecute() {
        LOTTO_ADDRESS.execute();
        TEAM_GIFT_ADDRESS.execute();

        _;
    }

    constructor(address payable _team) {
        require(!isContract(_team), "!_team");

        PLANS[0] = Plan(
            LAUNCH_TIME.add(TIME_FOR_ENABLE_PLAN0),
            TIME_FOR_LOCKED_PLAN0,
            PLAN_BASE_PERCENTS[0]
        );
        PLANS[1] = Plan(
            LAUNCH_TIME.add(TIME_FOR_ENABLE_PLAN1),
            TIME_FOR_LOCKED_PLAN1,
            PLAN_BASE_PERCENTS[1]
        );
        PLANS[2] = Plan(
            LAUNCH_TIME.add(TIME_FOR_ENABLE_PLAN2),
            TIME_FOR_LOCKED_PLAN2,
            PLAN_BASE_PERCENTS[2]
        );

        TEAM_ADDRESS = _team;

        address _lotto = address(new Lotto(address(this)));
        address _teamGift =
            address(new TeamGift(address(this), TEAM_REINVEST_DAYS));

        LOTTO_ADDRESS = ILotto(_lotto);
        TEAM_GIFT_ADDRESS = ITeamGift(_teamGift);
    }

    receive() external payable {
        emit OnGift(msg.value);
    }

    function stake(address _referrer, uint8 _plan)
        public
        payable
        mustPlanOpened(_plan)
        beforeExecute()
    {
        require(msg.value >= STAKE_MIN_AMOUNT, "!STAKE_MIN_AMOUNT");
        require(_plan < 3, "!plan");

        uint256 _teamAmount = msg.value.mul(TEAM_PERCENT).div(PERCENTS_DIVIDER);
        uint256 _teamLottoAmount =
            _teamAmount.mul(TEAM_LOTTO_PERCENT).div(PERCENTS_DIVIDER);
        uint256 _teamGiftAmount =
            _teamAmount.mul(TEAM_GIFT_PERCENT).div(PERCENTS_DIVIDER);

        LOTTO_ADDRESS.save{value: _teamLottoAmount}(msg.sender);

        if (Helpers.getCurrentDays() < TEAM_REINVEST_DAYS) {
            TEAM_ADDRESS.transfer(
                _teamAmount.sub(_teamLottoAmount).sub(_teamGiftAmount)
            );

            TEAM_GIFT_ADDRESS.save{value: _teamGiftAmount}();

            emit OnFeePayed(
                msg.sender,
                _teamAmount.sub(_teamLottoAmount).sub(_teamGiftAmount)
            );
        } else {
            TEAM_ADDRESS.transfer(_teamAmount.sub(_teamLottoAmount));

            emit OnFeePayed(msg.sender, _teamAmount.sub(_teamLottoAmount));
        }

        Player storage _player = PLAYERS[msg.sender];

        if (_player.referrer == address(0)) {
            if (_referrer != msg.sender) {
                _player.referrer = _referrer;
            }

            address _upline = _player.referrer;

            for (uint256 i = 0; i < 5; i++) {
                if (_upline != address(0)) {
                    PLAYERS[_upline].levels[i] = PLAYERS[_upline].levels[i].add(
                        1
                    );
                    _upline = PLAYERS[_upline].referrer;
                } else break;
            }
        }

        if (_player.referrer != address(0)) {
            address _upline = _player.referrer;

            for (uint256 i = 0; i < 5; i++) {
                if (_upline != address(0)) {
                    uint256 _amount =
                        msg.value.mul(REFERRAL_PERCENTS[i]).div(
                            PERCENTS_DIVIDER
                        );
                    PLAYERS[_upline].bonus = PLAYERS[_upline].bonus.add(
                        _amount
                    );
                    PLAYERS[_upline].totalBonus = PLAYERS[_upline]
                        .totalBonus
                        .add(_amount);

                    emit RefBonus(_upline, msg.sender, i, _amount);

                    _upline = PLAYERS[_upline].referrer;
                } else break;
            }
        }

        if (_player.deposits.length == 0) {
            _player.exists = true;
            _player.createdAt = Helpers.getNow();

            PLAYERS_ID[TOTAL_PLAYERS] = msg.sender;

            TOTAL_PLAYERS++;

            emit Newbie(msg.sender);
        }

        TOTAL_STAKED = TOTAL_STAKED.add(msg.value);

        (
            uint256 _percent,
            uint256 _startAt,
            uint256 _finishAt,
            uint256 _profit
        ) = getResult(_plan, msg.value);

        _player.deposits.push(
            Deposit(
                _plan,
                _percent,
                msg.value,
                _profit,
                _startAt,
                _finishAt,
                false,
                false
            )
        );

        emit NewStake(
            msg.sender,
            _plan,
            _percent,
            msg.value,
            _profit,
            _startAt,
            _finishAt
        );
    }

    function withdrawForDeposit(uint256 _depositID) public beforeExecute() {
        Player storage _player = PLAYERS[msg.sender];

        require(_depositID < _player.deposits.length, "!_depositID");
        require(
            Helpers.getNow() >= _player.deposits[_depositID].finishAt,
            "!finishAt"
        );
        require(
            !_player.deposits[_depositID].withdrawDeposit,
            "!withdrawDeposit"
        );

        uint256 totalAmount = _player.deposits[_depositID].amount;

        require(totalAmount > 0, "!totalAmount");

        uint256 contractBalance = address(this).balance;

        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        _player.deposits[_depositID].withdrawDeposit = true;

        msg.sender.transfer(totalAmount);

        emit OnWithdrawn(msg.sender, totalAmount);
    }

    function withdrawForProfit(uint256 _depositID) public beforeExecute() {
        Player storage _player = PLAYERS[msg.sender];

        require(_depositID < _player.deposits.length, "!_depositID");
        require(
            !_player.deposits[_depositID].withdrawProfit,
            "!withdrawProfit"
        );

        uint256 totalAmount = _player.deposits[_depositID].profit;

        require(totalAmount > 0, "!totalAmount");

        uint256 contractBalance = address(this).balance;

        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        _player.deposits[_depositID].withdrawProfit = true;

        msg.sender.transfer(totalAmount);

        emit OnProfitPayed(msg.sender, totalAmount);
    }

    function withdrawForBonus() public beforeExecute() {
        Player storage _player = PLAYERS[msg.sender];

        uint256 totalAmount;
        uint256 referralBonus = getPlayerReferralBonus(msg.sender);

        if (referralBonus > 0) {
            _player.bonus = 0;

            totalAmount = totalAmount.add(referralBonus);
        }

        require(totalAmount > 0, "!totalAmount");

        uint256 contractBalance = address(this).balance;

        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        msg.sender.transfer(totalAmount);

        emit OnBonusPayed(msg.sender, totalAmount);
    }

    function withdrawForLotto() public beforeExecute() {
        uint256 totalAmount = LOTTO_ADDRESS.getBalance();

        LOTTO_ADDRESS.execute();

        emit OnLottoPayed(msg.sender, totalAmount);
    }

    function teamGift() public {
        TEAM_GIFT_ADDRESS.execute();
    }

    function getPlayerReferrer(address _playerAddress)
        public
        view
        returns (address)
    {
        return PLAYERS[_playerAddress].referrer;
    }

    function getPlayerDownlineCount(address _playerAddress)
        public
        view
        returns (uint256, uint256)
    {
        return (
            PLAYERS[_playerAddress].levels[0],
            PLAYERS[_playerAddress].levels[1]
        );
    }

    function getPlayerReferralBonus(address _playerAddress)
        public
        view
        returns (uint256)
    {
        return PLAYERS[_playerAddress].bonus;
    }

    function getPlayerReferralTotalBonus(address _playerAddress)
        public
        view
        returns (uint256)
    {
        return PLAYERS[_playerAddress].totalBonus;
    }

    function getPlayerReferralWithdrawn(address _playerAddress)
        public
        view
        returns (uint256)
    {
        return
            PLAYERS[_playerAddress].totalBonus.sub(
                PLAYERS[_playerAddress].bonus
            );
    }

    function getPlayerAmountOfDeposits(address _playerAddress)
        public
        view
        returns (uint256)
    {
        return PLAYERS[_playerAddress].deposits.length;
    }

    function getPlayerTotalDeposits(address _playerAddress)
        public
        view
        returns (uint256 _amount)
    {
        for (uint256 i = 0; i < PLAYERS[_playerAddress].deposits.length; i++) {
            _amount = _amount.add(PLAYERS[_playerAddress].deposits[i].amount);
        }
    }

    function getPlayerAllDeposits(address _playerAddress)
        public
        view
        returns (Deposit[] memory)
    {
        Player memory _player = PLAYERS[_playerAddress];
        Deposit[] memory _deposits = new Deposit[](_player.deposits.length);

        for (uint256 i = 0; i < _player.deposits.length; i++) {
            _deposits[i] = _player.deposits[i];
        }

        return _deposits;
    }

    function getPlayerDepositInfo(address _playerAddress, uint256 _depositID)
        public
        view
        returns (
            uint256 _plan,
            uint256 _percent,
            uint256 _amount,
            uint256 _profit,
            uint256 _startAt,
            uint256 _finishAt,
            bool _withdrawProfit,
            bool _withdrawDeposit
        )
    {
        Player memory _player = PLAYERS[_playerAddress];

        _plan = _player.deposits[_depositID].plan;
        _percent = _player.deposits[_depositID].percent;
        _amount = _player.deposits[_depositID].amount;
        _profit = _player.deposits[_depositID].profit;
        _startAt = _player.deposits[_depositID].startAt;
        _finishAt = _player.deposits[_depositID].finishAt;
        _withdrawProfit = _player.deposits[_depositID].withdrawProfit;
        _withdrawDeposit = _player.deposits[_depositID].withdrawDeposit;
    }

    function getResult(uint256 _plan, uint256 _amount)
        public
        view
        returns (
            uint256 _percent,
            uint256 _startAt,
            uint256 _finishAt,
            uint256 _profit
        )
    {
        _percent = getPlanPercent(_plan);
        _startAt = Helpers.getNow();
        _finishAt = _startAt.add(PLANS[_plan].time);
        _profit = _amount.mul(_percent).div(PERCENTS_DIVIDER);
    }

    function getPlanPercent(uint256 _plan) public view returns (uint256) {
        if (Helpers.getNow() > LAUNCH_TIME) {
            uint256 _percent;
            uint256 _currentDays = Helpers.getCurrentDays();
            uint256 _startDays;

            if (_plan == 1) _startDays = 3;

            if (_plan == 2) _startDays = 6;

            for (uint256 i = _startDays; i < _currentDays; i++) {
                if (
                    PLANS[_plan].basePercent.add(_percent) <
                    PLAN_MAX_PERCENTS[_plan]
                ) {
                    _percent = _percent.add(DAY_PERCENTS);
                }
            }

            return _percent.add(PLANS[_plan].basePercent);
        } else {
            return PLANS[_plan].basePercent;
        }
    }

    function getAllPlanPercent()
        public
        view
        returns (
            uint256 _planPercent1,
            uint256 _planPercent2,
            uint256 _planPercent3
        )
    {
        _planPercent1 = getPlanPercent(0);
        _planPercent2 = getPlanPercent(1);
        _planPercent3 = getPlanPercent(2);

        return (_planPercent1, _planPercent2, _planPercent3);
    }

    function getEnabledForPlans()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            LAUNCH_TIME,
            LAUNCH_TIME.add(TIME_FOR_ENABLE_PLAN1),
            LAUNCH_TIME.add(TIME_FOR_ENABLE_PLAN2)
        );
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getLottoBalance() public view returns (uint256) {
        return LOTTO_ADDRESS.getBalance();
    }

    function getTeamGiftBalance() public view returns (uint256) {
        return TEAM_GIFT_ADDRESS.getBalance();
    }

    function getTotalBalance() public view returns (uint256) {
        return
            getBalance().add(getLottoBalance()).add(
                getTeamGiftBalance()
            );
    }

    function getLottoLastPlayer() public view returns (address, uint256) {
        return LOTTO_ADDRESS.getLottoLastPlayer();
    }

    function getLottoNumber() public view returns (uint256) {
        return LOTTO_ADDRESS.getLottoNumber();
    }

    function getLottoWinner(uint256 _number)
        public
        view
        returns (
            address,
            uint256,
            uint256
        )
    {
        return LOTTO_ADDRESS.getLottoWinner(_number);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}