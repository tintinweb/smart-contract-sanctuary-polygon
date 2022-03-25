/**
 *Submitted for verification at polygonscan.com on 2022-03-25
*/

// File: security/AccessControl.sol

//SPDX-License-Identifier:MIT
pragma solidity >=0.8.0 <0.9.0;

contract AccessControl{

    /// @dev Error message.
    string constant NO_PERMISSION='no permission';
    string constant INVALID_ADDRESS ='invalid address';
    
    /// @dev Administrator with highest authority. Should be a multisig wallet.
    address payable public superAdmin;

    /// @dev Administrator of this contract.
    address payable public admin;

    /// @dev This event is fired after modifying superAdmin.
    event superAdminChanged(address indexed _from,address indexed _to,uint256 _time);

    /// @dev This event is fired after modifying admin.
    event adminChanged(address indexed _from,address indexed _to,uint256 _time);

    /// Sets the original admin and superAdmin of the contract to the sender account.
    constructor(){
        superAdmin=payable(msg.sender);
        admin=payable(msg.sender);
    }

    /// @dev Throws if called by any account other than the superAdmin.
    modifier onlySuperAdmin{
        require(msg.sender==superAdmin,NO_PERMISSION);
        _;
    }

    /// @dev Throws if called by any account other than the admin.
    modifier onlyAdmin{
        require(msg.sender==admin,NO_PERMISSION);
        _;
    }

    /// @dev Allows the current superAdmin to change superAdmin.
    /// @param addr The address to transfer the right of superAdmin to.
    function changeSuperAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        emit superAdminChanged(superAdmin,addr,block.timestamp);
        superAdmin=addr;
    }

    /// @dev Allows the current superAdmin to change admin.
    /// @param addr The address to transfer the right of admin to.
    function changeAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        emit adminChanged(admin,addr,block.timestamp);
        admin=addr;
    }

    /// @dev Called by superAdmin to withdraw balance.
    function withdrawBalance(uint256 amount) external onlySuperAdmin{
        superAdmin.transfer(amount);
    }

    fallback() external {}
}
// File: security/Pausable.sol


pragma solidity >=0.8.0 <0.9.0;


contract Pausable is AccessControl{

    /// @dev Error message.
    string constant PAUSED='paused';
    string constant NOT_PAUSED='not paused';

    /// @dev Keeps track whether the contract is paused. When this is true, most actions are blocked.
    bool public paused = false;

    /// @dev Modifier to allow actions only when the contract is not paused
    modifier whenNotPaused {
        require(!paused,PAUSED);
        _;
    }

    /// @dev Modifier to allow actions only when the contract is paused
    modifier whenPaused {
        require(paused,NOT_PAUSED);
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
// File: token/ERC20.sol


pragma solidity >=0.8.0 <0.9.0;

interface ERC20 {
    /// MUST trigger when tokens are transferred, including zero value transfers.
    /// A token contract which creates new tokens SHOULD trigger a Transfer event with 
    ///  the _from address set to 0x0 when tokens are created.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// MUST trigger on any successful call to approve(address _spender, uint256 _value).
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// Returns the total token supply.
    function totalSupply() external view returns (uint256);

    /// Returns the account balance of another account with address _owner.
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// Transfers _value amount of tokens to address _to, and MUST fire the Transfer event. 
    /// The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
    /// Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
    /// The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf. 
    /// This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies. 
    /// The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism.
    /// Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// Allows _spender to withdraw from your account multiple times, up to the _value amount. 
    /// If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}
// File: token/ERC20Implementation.sol


pragma solidity ^0.8.4;



/// @title Standard ERC20 token

contract ERC20Implementation is ERC20, Pausable {

    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) _allowed;

    uint256 _totalSupply;

    /// @dev Total number of tokens in existence
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /// @dev Gets the balance of the specified address.
    /// @param _owner The address to query the balance of.
    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return _balances[_owner];
    }

    /// @dev Transfer token for a specified address
    /// @param _to The address to transfer to.
    /// @param _value The amount to be transferred.
    function transfer(address _to, uint256 _value) public whenNotPaused override returns (bool success) {
        require(_to != address(0),INVALID_ADDRESS);
        _balances[msg.sender]-=_value;
        _balances[_to]+=_value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @dev Transfer tokens from one address to another
    /// @param _from address The address which you want to send tokens from
    /// @param _to address The address which you want to transfer to
    /// @param _value uint256 the amount of tokens to be transferred
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused override returns (bool success) {
        require(_to != address(0),INVALID_ADDRESS);
        _balances[_from]-=_value;
        _balances[_to]+=_value;
        _allowed[_from][msg.sender]-=_value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    /// @param _spender The address which will spend the funds.
    /// @param _value The amount of tokens to be spent.
    function approve(address _spender, uint256 _value) public whenNotPaused override returns (bool success) {
        require(_spender != address(0),INVALID_ADDRESS);
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @dev Function to check the amount of tokens that an owner allowed to a spender.
    /// @param _owner The address which owns the funds.
    /// @param _spender The address which will spend the funds.
    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return _allowed[_owner][_spender];
    }

    /// @dev Increase the amount of tokens that an owner allowed to a spender.
    /// @param spender The address which will spend the funds.
    /// @param addedValue The amount of tokens to increase the allowance by.
    function increaseAllowance(address spender,uint256 addedValue) public whenNotPaused returns (bool) {
        require(spender != address(0),INVALID_ADDRESS);
        _allowed[msg.sender][spender]+=addedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /// @dev Decrease the amount of tokens that an owner allowed to a spender.
    /// @param spender The address which will spend the funds.
    /// @param subtractedValue The amount of tokens to decrease the allowance by.
    function decreaseAllowance(address spender,uint256 subtractedValue) public whenNotPaused returns (bool) {
        require(spender != address(0),INVALID_ADDRESS);
        _allowed[msg.sender][spender]-=subtractedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /// @dev Internal function that mints an amount of the token and assigns it to an account.
    ///  This encapsulates the modification of balances such that the proper events are emitted.
    /// @param account The account that will receive the created tokens.
    /// @param amount The amount that will be created.
    function _mint(address account, uint256 amount) internal {
        require(account != address(0),INVALID_ADDRESS);
        _totalSupply+=amount;
        _balances[account]+=amount;
        emit Transfer(address(0), account, amount);
    }

    /// @dev Used by admin to mint token.
    function mint(uint256 amount) external onlyAdmin {
        _mint(admin,amount);
    }
}
// File: CoinABase.sol


pragma solidity ^0.8.4;


// import "./stakable.sol";

contract CoinABase is ERC20Implementation {
    string _name = "Rise of Elves";
    string _symbol = "ROE";

    uint256 immutable deployedAt;
    //解鎖階段
    uint256 unlockCounter;
    uint256 initCounter = 0;

    //不同解鎖地址
    address launchpad;
    address privateSell;
    address playToEarn;
    address stakingReward;
    address teamAccount;
    address ecofund;
    address audit;

    string constant WRONG_TIME = "wrong time";
    string constant EXECUTED = "executed";

    event Bought(address _address, uint256 _amount);

    constructor() {
        deployedAt = block.timestamp;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 6;
    }

    //設定帳戶
    function setAddress(
        address _launchpad,
        address _privateSell,
        address _playToEarn,
        address _stakingReward,
        address _teamAccount,
        address _ecofund,
        address _audit
    ) external onlyAdmin {
        launchpad = _launchpad;
        privateSell = _privateSell;
        playToEarn = _playToEarn;
        stakingReward = _stakingReward;
        teamAccount = _teamAccount;
        ecofund = _ecofund;
        audit = _audit;
    }

    function getAddress()
        external
        view
        returns (
            address _launchpad,
            address _privateSell,
            address _playToEarn,
            address _stakingReward,
            address _teamAccount,
            address _ecofund,
            address _audit
        )
    {
        return (
            launchpad,
            privateSell,
            playToEarn,
            stakingReward,
            teamAccount,
            ecofund,
            audit
        );
    }

    function get_unlockCounter() external view returns (uint256) {
        return unlockCounter;
    }

    //初始解鎖
    function initUnlock() public {
        require(initCounter == 0, "already unlock init counter");
        _balances[launchpad] += 30000000 * 1e6;
        _balances[privateSell] += 3000000 * 1e6;
        _balances[playToEarn] += 5000000 * 1e6;
        _balances[stakingReward] += 2000000 * 1e6;
        _balances[teamAccount] += 10000000 * 1e6;
        _balances[ecofund] += 6000000 * 1e6;
        _balances[audit] += 4000000 * 1e6;
        initCounter++;
    }

    /// @dev First phase unlock.
    function unlock_1() public {
        require(block.timestamp >= deployedAt + 182.5 days, WRONG_TIME);
        require(unlockCounter == 0, EXECUTED);
        unlockCounter++;
        _distribute(15000000 * 1e6);
    }

    /// @dev Second phase unlock.
    function secondUnlock() public {
        require(block.timestamp >= deployedAt + 365 days, WRONG_TIME);
        require(unlockCounter == 1, EXECUTED);
        unlockCounter++;
        _distribute(30000000 * 1e6);
    }

    /// @dev Third phase unlock.
    function thirdUnlock() public {
        require(block.timestamp >= deployedAt + 365 days, WRONG_TIME);
        require(unlockCounter == 1, EXECUTED);
        unlockCounter++;
        _distribute(30000000 * 1e6);
    }

    /// @dev Fourth phase unlock.
    function fourthUnlock() public {
        require(block.timestamp >= deployedAt + 730 days, WRONG_TIME);
        require(unlockCounter == 1, EXECUTED);
        unlockCounter++;
        _distribute(30000000 * 1e6);
    }

    /// @dev Fifth phase unlock.
    function fifthUnlock() public {
        require(block.timestamp >= deployedAt + 912.5 days, WRONG_TIME);
        require(unlockCounter == 1, EXECUTED);
        unlockCounter++;
        _distribute(30000000 * 1e6);
    }

    /// @dev Sixth phase unlock.
    function sixthUnlock() public {
        require(block.timestamp >= deployedAt + 1095 days, WRONG_TIME);
        require(unlockCounter == 1, EXECUTED);
        unlockCounter++;
        _distribute(30000000 * 1e6);
    }

    /// @dev Seventh phase unlock.
    function seventhUnlock() public {
        require(block.timestamp >= deployedAt + 1277.5 days, WRONG_TIME);
        require(unlockCounter == 1, EXECUTED);
        unlockCounter++;
        _distribute(15000000 * 1e6);
    }

    /// @dev Eighth phase unlock.
    function eighthUnlock() public {
        require(block.timestamp >= deployedAt + 1460 days, WRONG_TIME);
        require(unlockCounter == 1, EXECUTED);
        unlockCounter++;
        _distribute(15000000 * 1e6);
    }

    /// @dev Ninth phase unlock.
    function ninthUnlock() public {
        require(block.timestamp >= deployedAt + 1642.5 days, WRONG_TIME);
        require(unlockCounter == 1, EXECUTED);
        unlockCounter++;
        _distribute(15000000 * 1e6);
    }

    /// @dev Tenth phase unlock.
    function tenthUnlock() public {
        require(block.timestamp >= deployedAt + 1825 days, WRONG_TIME);
        require(unlockCounter == 1, EXECUTED);
        unlockCounter++;
        _distribute(15000000 * 1e6);
    }

    /// @dev Eleventh phase unlock.
    function eleventhUnlock() public {
        require(block.timestamp >= deployedAt + 2007.5 days, WRONG_TIME);
        require(unlockCounter == 1, EXECUTED);
        unlockCounter++;
        _distribute(15000000 * 1e6);
    }

    function _distribute(uint256 _amount) internal {
        _mint(launchpad, (_amount * 10) / 100);
        _mint(privateSell, (_amount * 5) / 100);
        _mint(playToEarn, (_amount * 20) / 100);
        _mint(stakingReward, (_amount * 30) / 100);
        _mint(teamAccount, (_amount * 20) / 100);
        _mint(ecofund, (_amount * 10) / 100);
        _mint(audit, (_amount * 5) / 100);
    }

    //stake A
    // function stake_A(uint _amount) external returns(bool result){
    //     require(_balances[msg.sender] >= _amount);

    //     result = _stakeA(_amount);
    //     if(result){
    //         _deposit(_amount);
    //     }
    //     return result ;
    // }
    // //claim A
    // function claim_A() external returns(bool){
    //     uint totalAmount ;
    //     totalAmount = _claimA();
    //     _withdraw(totalAmount);
    //     return true ;
    // }

    // //stake B 先把之前質押獎勵提出，再重新質押
    // function stake_B(uint _amount) external returns(bool result, uint){
    //     require(_balances[msg.sender] >= _amount, "Not enough tokens");

    //     uint rewardAmount ;
    //     (result,rewardAmount) = _stakeB(_amount);
    //     if(rewardAmount > 0){
    //         _withdraw(rewardAmount);
    //     }
    //     if(result){
    //         _deposit(_amount);
    //     }
    //     return (result , rewardAmount) ;
    // }
    // //claim B
    // function claim_B() external returns(uint withdrawAmount){
    //     withdrawAmount = _claimB();
    //     _withdraw(withdrawAmount);
    //     return withdrawAmount ;
    // }

    // function _deposit(uint _amount) internal{
    //     require(_balances[msg.sender] >= _amount, "Not enough tokens to deposit");

    //     _balances[msg.sender] -= _amount ;
    //     _balances[admin] += _amount ;
    // }

    // function _withdraw(uint totalAmount) internal {
    //     require(_balances[admin] >= totalAmount, "Not enough tokens to withdraw");

    //     _balances[msg.sender] += totalAmount ;
    //     _balances[admin] -= totalAmount ;
    // }

    // function clearLastStaking() public view returns(bool){
    //     uint length = getTotalstaking_B();
    //     bool result ;
    //     for(uint i=0 ; i<length ; i++){
    //         result = distribute(i);
    //         if(!result) break ;
    //     }
    //     return result ;
    // }
}

// File: CoinA.sol


pragma solidity ^0.8.4;


/// @title Standard ERC20 token
contract CoinA is CoinABase {
    
}