//SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;

import './security/Pausable.sol';
import './token/ERC20Implementation.sol';

contract GenesisStaking is Pausable {
    ERC20Implementation token;

    struct Stake {
        uint256 amount;
        uint256 since;
        uint256 month;
        bool executed;
    }
    address[] public stakers;
    mapping(address => Stake[3]) stakes;
    mapping(address => bool) isStake;

    //time
    uint256 startCampaign;
    uint256 startStaking;
    uint256 endStaking;

    //interest
    uint256 three_month_interest;
    uint256 six_month_interest;
    uint256 twelve_month_interest;

    //staking detail
    uint256 totalReward;
    uint256 restReward;
    uint256 totalStaking;

    struct RestStakingDetail {
        uint256 threeMonth;
        uint256 sixMonth;
        uint256 twelveMonth;
    }

    RestStakingDetail restStakingDetail;

    //bonus reward
    uint256 bonusReward;

    //matic swap rate
    // uint256 swapRate = 2;

    event Bought(address _address, uint256 _amount);
    event Staked(address indexed user, uint256 amount, uint256 timestamp);

    constructor(address _coinA_Address) {
        token = ERC20Implementation(_coinA_Address);
    }

    receive() external payable {}

    modifier basicCheck(uint256 _amount, uint256 _index) {
        require(_amount > 0, 'Stake amount should bigger than 0');
        require(token.balanceOf(msg.sender) >= _amount, "Don't have enough amount for the staking");
        require(stakes[msg.sender][_index].since == 0, 'Already stake');
        //need in the period
        require(block.timestamp >= startCampaign, "It's too early for the staking");
        require(block.timestamp <= startStaking, "It's too late for the staking");
        _;
    }

    //設定A幣兌換兌換比率、質押利率、總獎勵、兌換/質押上限
    function setDetails(
        uint256 _three_month_interest,
        uint256 _six_month_interest,
        uint256 _twelve_month_interest,
        uint256 _totalReward
    ) external onlyAdmin {
        require(token.balanceOf(address(this)) >= _totalReward, 'Contract have not enough token');
        three_month_interest = _three_month_interest;
        six_month_interest = _six_month_interest;
        twelve_month_interest = _twelve_month_interest;

        totalReward = _totalReward;
        restReward = totalReward;
        totalStaking = 0;

        uint256 threeMonthAmount = (totalReward / three_month_interest) * 100;
        uint256 sixMonthAmount = (totalReward / six_month_interest) * 100;
        uint256 twelveMonthAmount = (totalReward / twelve_month_interest) * 100;

        restStakingDetail = RestStakingDetail(threeMonthAmount, sixMonthAmount, twelveMonthAmount);
    }

    function getDetails()
        external
        view
        returns (
            uint256 _three_month_interest,
            uint256 _six_month_interest,
            uint256 _twelve_month_interest,
            uint256 _totalReward,
            uint256 _restReward,
            uint256 _totalStaking,
            RestStakingDetail memory _restStakingDetail
        )
    {
        return (three_month_interest, six_month_interest, twelve_month_interest, totalReward, restReward, totalStaking, restStakingDetail);
    }

    function addReward(uint256 _amount) external onlyAdmin {
        require(token.balanceOf(address(this)) >= restReward + _amount, 'Add the reward first');
        bonusReward += _amount;
    }

    function getTotalBonus() external view returns (uint256) {
        return bonusReward;
    }

    //設定質押開始以及結束時間
    function setTime(
        uint256 _startCampaign,
        uint256 _startStaking,
        uint256 _endStaking
    ) external onlyAdmin {
        startCampaign = _startCampaign;
        startStaking = _startStaking;
        endStaking = _endStaking;
    }

    function getTime()
        external
        view
        returns (
            uint256 _startCampaign,
            uint256 _startStaking,
            uint256 _endStaking
        )
    {
        return (startCampaign, startStaking, endStaking);
    }

    function stake_3month(uint256 _amount) public whenNotPaused basicCheck(_amount, 0) returns (bool) {
        require(_amount <= restStakingDetail.threeMonth, 'Staking is up to limit');

        stakes[msg.sender][0] = Stake(_amount, startStaking, 3, false);
        // uint256 index = stakes[msg.sender].length - 1;

        _stake(_amount, three_month_interest);

        emit Staked(msg.sender, _amount, block.timestamp);

        return true;
    }

    function stake_6month(uint256 _amount) public whenNotPaused basicCheck(_amount, 1) returns (bool) {
        require(_amount <= restStakingDetail.sixMonth, 'Staking is up to limit');

        stakes[msg.sender][1] = Stake(_amount, startStaking, 6, false);
        // uint256 index = stakes[msg.sender].length - 1;

        _stake(_amount, six_month_interest);

        emit Staked(msg.sender, _amount, block.timestamp);

        return true;
    }

    function stake_12month(uint256 _amount) public whenNotPaused basicCheck(_amount, 2) returns (bool) {
        require(_amount <= restStakingDetail.sixMonth, 'Staking is up to limit');

        stakes[msg.sender][2] = Stake(_amount, startStaking, 12, false);
        // uint256 index = stakes[msg.sender].length - 1;

        _stake(_amount, twelve_month_interest);

        emit Staked(msg.sender, _amount, block.timestamp);

        return true;
    }

    function _stake(uint256 _amount, uint256 _rewardInterest) internal {
        require(token.allowance(msg.sender, address(this)) > 0, 'Should approve first');
        token.transferFrom(msg.sender, address(this), _amount);
        totalStaking += _amount;
        uint256 stakingReward = (_amount * _rewardInterest) / 100;
        restReward -= stakingReward;

        if (isStake[msg.sender] != true) {
            stakers.push(msg.sender);
            isStake[msg.sender] = true;
        }
        resetRestStakingDetail(restReward);
    }

    function resetRestStakingDetail(uint256 _restReward) internal {
        uint256 threeMonthAmount = (_restReward / three_month_interest) * 100;
        uint256 sixMonthAmount = (_restReward / six_month_interest) * 100;
        uint256 twelveMonthAmount = (_restReward / twelve_month_interest) * 100;
        restStakingDetail.threeMonth = threeMonthAmount;
        restStakingDetail.sixMonth = sixMonthAmount;
        restStakingDetail.twelveMonth = twelveMonthAmount;
    }

    function claimReward_ROE(uint256 _index) external {
        require(isStake[msg.sender], 'No staking');
        // require(!stakes[msg.sender][0].executed, 'Already claim');
        require(block.timestamp >= startStaking + stakes[msg.sender][_index].month * 30 * 1 days, 'Claim time is not achieved');

        uint256 totalAmount;
        uint256 originAmount;
        uint256 rewardAmount;
        uint256 bonusAmount;
        if (bonusReward == 0) {
            originAmount = calOriginAmount(msg.sender, _index);
            rewardAmount = calReward(msg.sender, _index);
            totalAmount = originAmount + rewardAmount;
        } else {
            originAmount = calOriginAmount(msg.sender, _index);
            rewardAmount = calReward(msg.sender, _index);
            bonusAmount = calBonus(msg.sender, _index);
            totalAmount = originAmount + rewardAmount + bonusAmount;
        }
        //distribute ROE
        require(token.balanceOf(address(this)) >= totalAmount, 'This contract balance is not enough');
        bonusReward -= bonusAmount;
        stakes[msg.sender][_index].executed = true;
        token.transfer(msg.sender, totalAmount);
    }

    function estimate_Reward(address _address, uint256 _index) external view returns (uint256) {
        uint256 totalAmount;
        uint256 originAmount;
        uint256 rewardAmount;
        uint256 bonusAmount;
        if (bonusReward == 0) {
            originAmount = calOriginAmount(_address, _index);
            rewardAmount = calReward(_address, _index);
            totalAmount = originAmount + rewardAmount;
        } else {
            originAmount = calOriginAmount(_address, _index);
            rewardAmount = calReward(_address, _index);
            bonusAmount = calBonus(_address, _index);
            totalAmount = originAmount + rewardAmount + bonusAmount;
        }
        return totalAmount;
    }

    function calOriginAmount(address _address, uint256 _index) internal view returns (uint256) {
        return stakes[_address][_index].amount;
    }

    function calReward(address _address, uint256 _index) internal view returns (uint256) {
        uint256 reward;

        uint256 stakePeriod = stakes[_address][_index].month;
        if (stakePeriod == 3) {
            reward += (stakes[_address][_index].amount * three_month_interest) / 100;
        } else if (stakePeriod == 6) {
            reward += (stakes[_address][_index].amount * six_month_interest) / 100;
        } else if (stakePeriod == 12) {
            reward += (stakes[_address][_index].amount * twelve_month_interest) / 100;
        }

        return reward;
    }

    function calBonus(address _address, uint256 _index) public view returns (uint256) {
        uint256 allWeight = getAllWeight();
        uint256 userWeight = getUserWeight(_address, _index);
        uint256 totalAmount = (bonusReward * userWeight) / allWeight;
        return totalAmount;
    }

    function getAllWeight() internal view returns (uint256) {
        uint256 allWeights = 0;
        for (uint256 i = 0; i < stakers.length; i++) {
            address _address = stakers[i];
            for (uint256 j = 0; j < stakes[_address].length; j++) {
                if (stakes[_address][j].executed == false) {
                    allWeights += stakes[_address][j].amount * (block.timestamp - stakes[_address][j].since);
                }
            }
        }
        return allWeights;
    }

    function getUserWeight(address _address, uint256 _index) internal view returns (uint256) {
        uint256 userWeight = 0;

        if (stakes[_address][_index].executed == false) {
            userWeight = stakes[_address][_index].amount * (block.timestamp - stakes[_address][_index].since);
        }

        return userWeight;
    }

    function getStakes(address _address) external view returns (Stake[3] memory) {
        return stakes[_address];
    }

    function getNow() public view returns (uint256) {
        return block.timestamp;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function withdrawToken(uint256 _amount) external onlyAdmin {
        token.transfer(msg.sender, _amount);
    }
}

pragma solidity >=0.8.0 <0.9.0;

import "./AccessControl.sol";

contract Pausable is AccessControl {
    /// @dev Error message.
    string constant PAUSED = "paused";
    string constant NOT_PAUSED = "not paused";

    /// @dev Keeps track whether the contract is paused. When this is true, most actions are blocked.
    bool public paused = false;

    /// @dev Modifier to allow actions only when the contract is not paused
    modifier whenNotPaused() {
        require(!paused, PAUSED);
        _;
    }

    /// @dev Modifier to allow actions only when the contract is paused
    modifier whenPaused() {
        require(paused, NOT_PAUSED);
        _;
    }

    /// @dev Called by admin to pause the contract. Used when something goes wrong
    ///  and we need to limit damage.
    function pause() external onlyAdmin whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the admin.
    function unpause() external onlyAdmin whenPaused {
        paused = false;
    }
}

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "../security/Pausable.sol";

/// @title Standard ERC20 token

contract ERC20Implementation is IERC20, Pausable {
    mapping(address => uint256) _balances;

    mapping(address => mapping(address => uint256)) _allowed;

    uint256 _totalSupply;

    /// @dev Total number of tokens in existence
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /// @dev Gets the balance of the specified address.
    /// @param _owner The address to query the balance of.
    function balanceOf(address _owner)
        public
        view
        override
        returns (uint256 balance)
    {
        return _balances[_owner];
    }

    /// @dev Transfer token for a specified address
    /// @param _to The address to transfer to.
    /// @param _value The amount to be transferred.
    function transfer(address _to, uint256 _value)
        public
        override
        whenNotPaused
        returns (bool success)
    {
        require(_to != address(0), INVALID_ADDRESS);
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @dev Transfer tokens from one address to another
    /// @param _from address The address which you want to send tokens from
    /// @param _to address The address which you want to transfer to
    /// @param _value uint256 the amount of tokens to be transferred
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override whenNotPaused returns (bool success) {
        require(_to != address(0), INVALID_ADDRESS);
        _balances[_from] -= _value;
        _balances[_to] += _value;
        _allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    /// @param _spender The address which will spend the funds.
    /// @param _value The amount of tokens to be spent.
    function approve(address _spender, uint256 _value)
        public
        override
        whenNotPaused
        returns (bool success)
    {
        require(_spender != address(0), INVALID_ADDRESS);
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @dev Function to check the amount of tokens that an owner allowed to a spender.
    /// @param _owner The address which owns the funds.
    /// @param _spender The address which will spend the funds.
    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return _allowed[_owner][_spender];
    }

    /// @dev Increase the amount of tokens that an owner allowed to a spender.
    /// @param spender The address which will spend the funds.
    /// @param addedValue The amount of tokens to increase the allowance by.
    function increaseAllowance(address spender, uint256 addedValue)
        public
        whenNotPaused
        returns (bool)
    {
        require(spender != address(0), INVALID_ADDRESS);
        _allowed[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /// @dev Decrease the amount of tokens that an owner allowed to a spender.
    /// @param spender The address which will spend the funds.
    /// @param subtractedValue The amount of tokens to decrease the allowance by.
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        whenNotPaused
        returns (bool)
    {
        require(spender != address(0), INVALID_ADDRESS);
        _allowed[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /// @dev Internal function that mints an amount of the token and assigns it to an account.
    ///  This encapsulates the modification of balances such that the proper events are emitted.
    /// @param account The account that will receive the created tokens.
    /// @param amount The amount that will be created.
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), INVALID_ADDRESS);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}

pragma solidity >=0.8.0 <0.9.0;

contract AccessControl {
    /// @dev Error message.
    string constant NO_PERMISSION = "no permission";
    string constant INVALID_ADDRESS = "invalid address";

    /// @dev Administrator with highest authority. Should be a multisig wallet.
    address payable public superAdmin;

    /// @dev Administrator of this contract.
    address payable public admin;

    /// @dev This event is fired after modifying superAdmin.
    event superAdminChanged(
        address indexed _from,
        address indexed _to,
        uint256 _time
    );

    /// @dev This event is fired after modifying admin.
    event adminChanged(
        address indexed _from,
        address indexed _to,
        uint256 _time
    );

    /// Sets the original admin and superAdmin of the contract to the sender account.
    constructor() {
        superAdmin = payable(msg.sender);
        admin = payable(msg.sender);
    }

    /// @dev Throws if called by any account other than the superAdmin.
    modifier onlySuperAdmin() {
        require(msg.sender == superAdmin, NO_PERMISSION);
        _;
    }

    /// @dev Throws if called by any account other than the admin.
    modifier onlyAdmin() {
        require(msg.sender == admin, NO_PERMISSION);
        _;
    }

    /// @dev Allows the current superAdmin to change superAdmin.
    /// @param addr The address to transfer the right of superAdmin to.
    function changeSuperAdmin(address payable addr) external onlySuperAdmin {
        require(addr != payable(address(0)), INVALID_ADDRESS);
        emit superAdminChanged(superAdmin, addr, block.timestamp);
        superAdmin = addr;
    }

    /// @dev Allows the current superAdmin to change admin.
    /// @param addr The address to transfer the right of admin to.
    function changeAdmin(address payable addr) external onlySuperAdmin {
        require(addr != payable(address(0)), INVALID_ADDRESS);
        emit adminChanged(admin, addr, block.timestamp);
        admin = addr;
    }

    /// @dev Called by superAdmin to withdraw balance.
    function withdrawBalance(uint256 amount) external onlySuperAdmin {
        superAdmin.transfer(amount);
    }

    fallback() external {}
}

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    /// MUST trigger when tokens are transferred, including zero value transfers.
    /// A token contract which creates new tokens SHOULD trigger a Transfer event with
    ///  the _from address set to 0x0 when tokens are created.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// MUST trigger on any successful call to approve(address _spender, uint256 _value).
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    /// Returns the total token supply.
    function totalSupply() external view returns (uint256);

    /// Returns the account balance of another account with address _owner.
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
    /// The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
    /// Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    /// Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
    /// The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf.
    /// This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies.
    /// The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism.
    /// Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    /// Allows _spender to withdraw from your account multiple times, up to the _value amount.
    /// If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    /// Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
}