/**
 *Submitted for verification at polygonscan.com on 2023-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address newOwner) {
        _setOwner(newOwner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

abstract contract Pausable is Context {
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract BlueBerryWallet is Ownable, Pausable {
    address public developerWallet;
    uint256 public referralPercentage = 5;

    event NewDeposit(address indexed user, uint256 amount, uint256 timestamp);

    event WithdrawCapitals(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    event TokensClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    event WithdrawReferralRewards(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    event SetPlan(
        uint256 indexed apy,
        uint256 indexed time,
        uint256 minimumDeposit,
        uint256 maximumDeposit,
        bool paused
    );
    event PlanPaused(
        bytes32 indexed key,
        address account,
        uint256 step,
        uint256 timestamp
    );
    event PlanUnpaused(
        bytes32 indexed key,
        address account,
        uint256 step,
        uint256 timestamp
    );

    enum TokenType {
        MATIC
    }

    AggregatorV3Interface priceFeed;

    constructor() Ownable(_msgSender()) {
        priceFeed = AggregatorV3Interface(
            0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
        );
        developerWallet = owner();
        plansData.push(
            plans({
                apy: 500,
                time: 2629743,
                minDeposit: 30000000000000000000,
                maxDeposit: 5000000000000000000000,
                paused: false,
                addPlanTimestamp: block.timestamp
            })
        );
        plansData.push(
            plans({
                apy: 800,
                time: 5259486,
                minDeposit: 40000000000000000000,
                maxDeposit: 10000000000000000000000,
                paused: false,
                addPlanTimestamp: block.timestamp
            })
        );
    }

    struct plans {
        uint256 apy;
        uint256 time;
        uint256 minDeposit;
        uint256 maxDeposit;
        uint256 addPlanTimestamp;
        bool paused;
    }

    struct user {
        uint256 amount;
        uint256 timestamp;
        uint256 step;
        uint256 depositTime;
        TokenType tokenType;
    }
    mapping(address => user[]) public investment;

    mapping(address => uint256) private _referralRewards;
    mapping(address => bool) public checkReferral;

    plans[] public plansData;

    function removeId(uint256 indexnum) internal {
        for (
            uint256 i = indexnum;
            i < investment[_msgSender()].length - 1;
            i++
        ) {
            investment[_msgSender()][i] = investment[_msgSender()][i + 1];
        }
        investment[_msgSender()].pop();
    }

    function pausedPlan(uint256 _step) external onlyOwner {
        require(!plansData[_step].paused, "Plan is already inactive");
        plansData[_step].paused = true;
        emit PlanPaused(
            bytes32("Inactive"),
            _msgSender(),
            _step,
            block.timestamp
        );
    }

    function unpausedPlan(uint256 _step) external onlyOwner {
        require(plansData[_step].paused, "Plan is already active");
        plansData[_step].paused = false;
        emit PlanUnpaused(
            bytes32("active"),
            _msgSender(),
            _step,
            block.timestamp
        );
    }

    function updatePlan(
        uint256 step,
        uint256 _apy,
        uint256 _time,
        uint256 _minDeposit,
        uint256 _maxDeposit
    ) external onlyAdmin {
        require(step < plansData.length, "Invalid step");
        if (_apy > 0) plansData[step].apy = _apy;
        if (_time > 0) plansData[step].time = _time;
        if (_minDeposit > 0) plansData[step].minDeposit = _minDeposit;
        if (_maxDeposit > 0) plansData[step].maxDeposit = _maxDeposit;
        plansData[step].paused = false;
    }

    function setPlans(
        uint256 _apy,
        uint256 _time,
        uint256 _minDeposit,
        uint256 _maxDeposit,
        bool _paused
    ) external onlyOwner {
        require(_apy != 0 && _time != 0, "Please set a valid APY and time");
        plansData.push(
            plans({
                apy: _apy,
                time: _time,
                minDeposit: _minDeposit,
                maxDeposit: _maxDeposit,
                paused: _paused,
                addPlanTimestamp: block.timestamp
            })
        );
        emit SetPlan(_apy, _time, _minDeposit, _maxDeposit, _paused);
    }

    function getContractMaticBalance() public view returns (uint256 MATIC) {
        return address(this).balance;
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        price = price;
        return uint256(price);
    }

    function withdrawMatic() public onlyOwner {
        require(getContractMaticBalance() > 0, "contract balance is ZERO");
        payable(owner()).transfer(getContractMaticBalance());
    }

    function updateReferralPercentage(uint256 _newPercentage)
        external
        onlyOwner
    {
        referralPercentage = _newPercentage;
    }

    function changeDevWallet(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "address cannot be zero");
        require(_newAdmin != developerWallet, "This address is already fixed");
        developerWallet = _newAdmin;
    }

    function invest(
        TokenType tokenType,
        uint8 step,
        address _referral
    ) external payable whenNotPaused {
        require(TokenType.MATIC == tokenType, "Token type unsupported");
        require(step == 0 || step == 1, "Invalid plan for selected currency");
        payable(address(this)).transfer(msg.value);
        investment[_msgSender()].push(
            user({
                amount: msg.value,
                timestamp: block.timestamp,
                step: step,
                depositTime: block.timestamp,
                tokenType: tokenType
            })
        );
        if (
            !checkReferral[_msgSender()] &&
            _referral != address(0) &&
            _referral != _msgSender()
        ) {
            uint256 refferTax = (msg.value * referralPercentage) / 100;
            _referralRewards[_referral] += refferTax;
        }
        checkReferral[_msgSender()] = true;
        emit NewDeposit(_msgSender(), msg.value, block.timestamp);
    }

    modifier onlyAdmin() {
        require(
            owner() == _msgSender() || developerWallet == _msgSender(),
            "Ownable: caller is not the owner or developer"
        );
        _;
    }

    modifier checkWithdrawTime(uint256 id) {
        require(id < investment[_msgSender()].length, "Invalid enter Id");
        user memory users = investment[_msgSender()][id];
        require(
            users.depositTime + plansData[users.step].time < block.timestamp,
            "Withdrawal time has not yet expired."
        );
        _;
    }

    modifier checkPlans(uint256 step, uint256 amount) {
        require(amount > 0, "Please provide a valid value");
        require(step < plansData.length, "Invalid step");
        require(!plansData[step].paused, "This plan is currently inactive");
        uint256 amount1 = (amount * getLatestPrice()) / 1e8;
        require(plansData[step].minDeposit <= amount1, "Min Stake MATIC");
        require(plansData[step].maxDeposit >= amount1, "Max Stake MATIC");
        _;
    }

    function withdrawCapital(uint256 id)
        external
        checkWithdrawTime(id)
        whenNotPaused
        returns (bool success)
    {
        user memory users = investment[_msgSender()][id];
        require(id < investment[_msgSender()].length, "Invalid enter Id");
        uint256 withdrawalAmount;
        uint256 maticRewards = calculateReward(_msgSender(), id);
        withdrawalAmount = users.amount + maticRewards;
        require(
            withdrawalAmount <= getContractMaticBalance(),
            "Insufficient matic amount is in the contract"
        );
        payable(msg.sender).transfer(withdrawalAmount);
        emit WithdrawCapitals(_msgSender(), withdrawalAmount, block.timestamp);
        removeId(id);
        return true;
    }

    function withdrawRewards() external whenNotPaused returns (bool success) {
        uint256 index = investment[_msgSender()].length;
        require(index > 0, "You have not deposited fund");
        uint256 rewards;
        for (uint256 i = 0; i < index; i++) {
            user storage users = investment[_msgSender()][i];
            uint256 maticRewards = calculateReward(_msgSender(), i);
            rewards += maticRewards;
            users.timestamp = block.timestamp;
        }
        require(rewards > 0, "you have no rewards");
        require(
            getContractMaticBalance() >= rewards,
            "Insufficient funds in contract to transfer"
        );
        payable(msg.sender).transfer(rewards);
        emit TokensClaimed(_msgSender(), (rewards), block.timestamp);
        return true;
    }

    function calculateReward(address _user, uint256 id)
        public
        view
        returns (uint256)
    {
        require(id < investment[_user].length, "Invalid Id");
        user memory users = investment[_user][id];
        uint256 time = block.timestamp - users.timestamp;
        uint256 DIVIDER = 10000;
        uint256 maticRewards = (users.amount *
            plansData[users.step].apy *
            time) /
            DIVIDER /
            30.44 days;

        return (maticRewards);
    }

    function usdToMaticHelper(uint256 _usdAmount)
        external
        view
        returns (uint256 matic)
    {
        matic = ((1 ether / getLatestPrice()) * _usdAmount) / 1e10;
        return matic;
    }

    function withdrawReferral() external whenNotPaused {
        uint256 rewards = _referralRewards[_msgSender()];
        require(rewards > 0, "You do not have referral rewards.");
        require(getContractMaticBalance() >= rewards, "Low balance");
        payable(_msgSender()).transfer(rewards);
        emit WithdrawReferralRewards(_msgSender(), rewards, block.timestamp);
        _referralRewards[_msgSender()] = 0;
    }

    function referralOf(address account) external view returns (uint256) {
        return _referralRewards[account];
    }

    function userIndex(address _user) public view returns (uint256) {
        return investment[_user].length;
    }

    function depositAddAmount(address _user)
        public
        view
        returns (uint256 amount)
    {
        uint256 index = investment[_user].length;
        for (uint256 i = 0; i < index; i++) {
            user memory users = investment[_user][i];
            amount += users.amount;
        }
        return amount;
    }

    function numberOfPlans() public view returns (uint256) {
        return plansData.length;
    }

    receive() external payable {}
}