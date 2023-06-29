/**
 *Submitted for verification at polygonscan.com on 2023-06-28
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
    IERC20 public busd;
    uint256 public totalTokensSold;

    address public paymentWallet;

    uint256 public referralPercentage = 5;
    uint256[] public APY = [500, 1600, 3000, 6000];
    uint256[] public TIME = [2592000, 5184000, 7776000, 15552000];
    uint256 DIVIDER = 10000;

    event NewDeposit(address indexed user, uint256 amount, uint256 timestamp);
    event WithdrawReferralRewards(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    event TokensBought(
        address indexed user,
        uint256 indexed amountPaid,
        uint256 indexed purchaseToken,
        uint256 timestamp
    );
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

    enum TokenType {
        MATIC
    }


    constructor() Ownable(_msgSender()) {
        busd = IERC20(0xEE781c719ca5F8512310Fa49Ea0d735CB3b2a020);
        paymentWallet = owner();
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

    function changePaymentWallet(address _newPaymentWallet) external onlyOwner {
        require(_newPaymentWallet != address(0), "address cannot be zero");
        require(
            _newPaymentWallet != paymentWallet,
            "This address is already fixed"
        );
        paymentWallet = _newPaymentWallet;
    }

    function updateReferralPercentage(uint256 _newPercentage)
        external
        onlyOwner
    {
        referralPercentage = _newPercentage;
    }


    function updateAPYTIME(uint256[] memory _apy, uint256[] memory _time)
        external
        onlyOwner
    {
        require(
            _apy.length == _time.length,
            "APY and time must be equal length"
        );
        for (uint8 i; i < _apy.length; i++) {
            require(
                _apy[i] != 0 && _time[i] != 0,
                "APY and time not equal ZERO"
            );
        }
        APY = _apy;
        TIME = _time;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(getContractMaticBalance() >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Matic Payment failed");
    }


    function getContractMaticBalance() public view returns (uint256 BNB) {
        return address(this).balance;
    }

    function withdrawMatic() public onlyOwner {
        require(getContractMaticBalance() > 0, "contract balance is ZERO");
        payable(owner()).transfer(getContractMaticBalance());
    }


    function invest(
        TokenType tokenType,
        uint8 step,
        address _referral
    ) external payable whenNotPaused {
        require(
          TokenType.MATIC == tokenType,
            "Token type unsupported"
        );
        require(step < APY.length, "Invalid step");
        require(msg.value > 0,"Please provide a matic value");
        require(step == 0 || step == 1,"Invalid plan for selected currency");
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

    modifier checkWithdrawTime(uint256 id) {
        require(id < investment[_msgSender()].length, "Invalid enter Id");
        user memory users = investment[_msgSender()][id];
        require(
            users.depositTime < block.timestamp,
            "Withdrawal time has not yet expired."
        );
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
        (uint256 maticRewards) = calculateReward(_msgSender(), id);
        withdrawalAmount = users.amount + maticRewards;
        require(
            withdrawalAmount <= getContractMaticBalance(),
            "Insufficient bnb amount is in the contract"
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
        if (rewards > 0) {
            require(getContractMaticBalance() >= rewards,"Insufficient funds in contract to transfer");
            payable(msg.sender).transfer(rewards);
        }
        emit TokensClaimed(
            _msgSender(),
            (rewards),
            block.timestamp
        );
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
        uint256  maticRewards =
                (users.amount * APY[users.step] * time) /
                DIVIDER /
                30.44 days;

        return (maticRewards);
    }

    function withdrawReferral() external whenNotPaused {
        uint256 rewards = _referralRewards[_msgSender()];
        require(rewards > 0, "You do not have referral rewards.");
        busd.transfer(_msgSender(), rewards);
        emit WithdrawReferralRewards(_msgSender(), rewards, block.timestamp);
        _referralRewards[_msgSender()] = 0;
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

    function referralOf(address account) external view returns (uint256) {
        return _referralRewards[account];
    }

    receive() external payable {}
}