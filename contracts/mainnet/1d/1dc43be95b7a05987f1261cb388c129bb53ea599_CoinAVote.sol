/**
 *Submitted for verification at polygonscan.com on 2022-07-04
*/

// File: utils/Imisc.sol

pragma solidity >=0.8.0 <0.9.0;

interface Imisc{
    function changeCapsuleContract(address addr) external;//ELFCore
    function changeSpawnContract(address addr) external;//ELFCore
    function changeCoinA(address addr) external;//SpawnContract
    function changeCoinB(address addr) external;//SpawnContract
    function setELFCore(address addr) external;//SpawnContract
    function changeCoinAddresses(uint256 coinType, address addr) external;//CoinMarket
}
// File: utils/ICapsuleContract.sol

pragma solidity >=0.8.0 <0.9.0;

interface ICapsuleContract{
    function writePriceInfo(uint256 price) external;
    function getPriceInfo() external view returns(uint256 price,uint256 time);
    function createCapsule(address caller,bool triple) external returns(uint256[] memory, uint256);
    function setELFCoreAddress(address addr) external;
}
// File: utils/ISpawnCoin.sol

pragma solidity >=0.8.0 <0.9.0;

interface ISpawnCoin {

    event SpawnContractAddressChanged(address indexed _from, address indexed _to, uint256 time);

    function setSpawnContractAddress(address addr) external;

    function spawnEgg(address addr,uint256 amount) external;
  
}
// File: security/AccessControl.sol

pragma solidity >=0.8.0 <0.9.0;

contract AccessControl{

    /// @dev Error message.
    string constant NO_PERMISSION='no permission';
    string constant INVALID_ADDRESS ='invalid address';
    
    /// @dev Administrator with highest authority. Should be a multisig wallet.
    address payable superAdmin;

    /// @dev Administrator of this contract.
    address payable admin;

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
        superAdmin=addr;
    }

    /// @dev Allows the current superAdmin to change admin.
    /// @param addr The address to transfer the right of admin to.
    function changeAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
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

    /// @dev Called by superAdmin to pause the contract. Used when something goes wrong
    ///  and we need to limit damage.
    function pause() external onlySuperAdmin whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the superAdmin.
    function unpause() external onlySuperAdmin whenPaused {
        paused = false;
    }
}
// File: token/IERC20.sol

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

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

contract ERC20Implementation is IERC20, Pausable {

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
}
// File: CoinABase.sol

pragma solidity ^0.8.4;



contract CoinABase is ERC20Implementation, ISpawnCoin {

    string constant WRONG_TIME = "wrong time";
    string constant EXECUTED = "executed";

    string _name = "Rise of Elves";
    string _symbol = "ROE";

    uint256 public startAt=99999999999999999999999;

    //bool
    bool isSetAddress = false;
    //解鎖階段
    uint256 public unlockCounter = 0;

    //不同解鎖地址
    address launchpad;
    address privateSell;
    address playToEarn;
    address stakingReward;
    address teamAccount;
    address ecofund;
    address audit;

    event Bought(address _address, uint256 _amount);

    constructor() {
        _totalSupply = 300000000 * 1e6;
    }

    modifier checkAddress() {
        require(
            launchpad != address(0) &&
                privateSell != address(0) &&
                playToEarn != address(0) &&
                stakingReward != address(0) &&
                teamAccount != address(0) &&
                ecofund != address(0) &&
                audit != address(0)
        );
        _;
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
    ) external onlySuperAdmin {
        launchpad = _launchpad;
        privateSell = _privateSell;
        playToEarn = _playToEarn;
        stakingReward = _stakingReward;
        teamAccount = _teamAccount;
        ecofund = _ecofund;
        audit = _audit;

        isSetAddress = true;
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

    function setStartTime(uint256 _uint) external onlySuperAdmin {
        require(block.timestamp<startAt,'expired');
        startAt = _uint;
    }

    //init
    function initUnlock() public onlyAdmin checkAddress {
        require(block.timestamp>=startAt,'too early');
        require(isSetAddress, "Set the Address first");
        require(unlockCounter == 0, "already unlock init counter");
        _balances[launchpad] += 30000000 * 1e6;
        _balances[privateSell] += 3000000 * 1e6;
        _balances[playToEarn] += 5000000 * 1e6;
        _balances[stakingReward] += 2000000 * 1e6;
        _balances[teamAccount] += 10000000 * 1e6;
        _balances[ecofund] += 6000000 * 1e6;
        _balances[audit] += 4000000 * 1e6;
        unlockCounter++;
    }

    /// @dev First phase unlock.
    function unlock_3month() public {
        require(block.timestamp >= startAt + 3 * 30 days, WRONG_TIME);
        require(unlockCounter == 1, EXECUTED);
        _balances[playToEarn] += 5000000 * 1e6;
        _balances[stakingReward] += 5900000 * 1e6;
        unlockCounter++;
    }

    function unlock_6month() public {
        require(block.timestamp >= startAt + 6 * 30 days, WRONG_TIME);
        require(unlockCounter == 2, EXECUTED);
        _balances[privateSell] += 3000000 * 1e6;
        _balances[playToEarn] += 10000000 * 1e6;
        _balances[stakingReward] += 5600000 * 1e6;
        _balances[ecofund] += 6000000 * 1e6;
        _balances[audit] += 2000000 * 1e6;
        unlockCounter++;
    }

    function unlock_12month() public {
        require(block.timestamp >= startAt + 12 * 30 days, WRONG_TIME);
        require(unlockCounter == 3, EXECUTED);
        _balances[privateSell] += 3000000 * 1e6;
        _balances[playToEarn] += 8000000 * 1e6;
        _balances[stakingReward] += 10700000 * 1e6;
        _balances[teamAccount] += 8000000 * 1e6;
        _balances[ecofund] += 6000000 * 1e6;
        _balances[audit] += 2000000 * 1e6;
        unlockCounter++;
    }

    function unlock_18month() public {
        require(block.timestamp >= startAt + 18 * 30 days, WRONG_TIME);
        require(unlockCounter == 4, EXECUTED);
        _balances[privateSell] += 3000000 * 1e6;
        _balances[playToEarn] += 8000000 * 1e6;
        _balances[stakingReward] += 10200000 * 1e6;
        _balances[teamAccount] += 8000000 * 1e6;
        _balances[ecofund] += 6000000 * 1e6;
        _balances[audit] += 2000000 * 1e6;
        unlockCounter++;
    }

    function unlock_24month() public {
        require(block.timestamp >= startAt + 24 * 30 days, WRONG_TIME);
        require(unlockCounter == 5, EXECUTED);
        _balances[privateSell] += 3000000 * 1e6;
        _balances[playToEarn] += 5000000 * 1e6;
        _balances[stakingReward] += 10000000 * 1e6;
        _balances[teamAccount] += 5000000 * 1e6;
        _balances[ecofund] += 5000000 * 1e6;
        _balances[audit] += 2000000 * 1e6;
        unlockCounter++;
    }

    function unlock_30month() public {
        require(block.timestamp >= startAt + 30 * 30 days, WRONG_TIME);
        require(unlockCounter == 6, EXECUTED);
        _balances[playToEarn] += 5000000 * 1e6;
        _balances[stakingReward] += 9000000 * 1e6;
        _balances[teamAccount] += 4000000 * 1e6;
        _balances[ecofund] += 4000000 * 1e6;
        _balances[audit] += 1000000 * 1e6;
        unlockCounter++;
    }

    function unlock_36month() public {
        require(block.timestamp >= startAt + 36 * 30 days, WRONG_TIME);
        require(unlockCounter == 7, EXECUTED);
        _balances[playToEarn] += 4000000 * 1e6;
        _balances[stakingReward] += 8800000 * 1e6;
        _balances[teamAccount] += 3000000 * 1e6;
        _balances[ecofund] += 3000000 * 1e6;
        _balances[audit] += 1000000 * 1e6;
        unlockCounter++;
    }

    function unlock_42month() public {
        require(block.timestamp >= startAt + 42 * 30 days, WRONG_TIME);
        require(unlockCounter == 8, EXECUTED);
        _balances[playToEarn] += 4000000 * 1e6;
        _balances[stakingReward] += 7800000 * 1e6;
        _balances[teamAccount] += 3000000 * 1e6;
        _balances[ecofund] += 3000000 * 1e6;
        _balances[audit] += 1000000 * 1e6;
        unlockCounter++;
    }

    function unlock_48month() public {
        require(block.timestamp >= startAt + 48 * 30 days, WRONG_TIME);
        require(unlockCounter == 9, EXECUTED);
        _balances[playToEarn] += 3000000 * 1e6;
        _balances[stakingReward] += 7625000 * 1e6;
        _balances[teamAccount] += 2000000 * 1e6;
        _balances[ecofund] += 3000000 * 1e6;
        unlockCounter++;
    }

    function unlock_54month() public {
        require(block.timestamp >= startAt + 54 * 30 days, WRONG_TIME);
        require(unlockCounter == 10, EXECUTED);
        _balances[playToEarn] += 3000000 * 1e6;
        _balances[stakingReward] += 6750000 * 1e6;
        _balances[teamAccount] += 2000000 * 1e6;
        _balances[ecofund] += 3000000 * 1e6;
        unlockCounter++;
    }

    function unlock_60month() public {
        require(block.timestamp >= startAt + 60 * 30 days, WRONG_TIME);
        require(unlockCounter == 11, EXECUTED);

        _balances[stakingReward] += 5625000 * 1e6;
        unlockCounter++;
    }

    function getNow() external view returns (uint256) {
        return block.timestamp;
    }

    address public SpawnContractAddress;

    function setSpawnContractAddress(address addr) external override onlySuperAdmin {
        require(addr != address(0), INVALID_ADDRESS);
        emit SpawnContractAddressChanged(SpawnContractAddress, addr, block.timestamp);
        SpawnContractAddress = addr;
    }

    function spawnEgg(address addr, uint256 amount)
        external
        override
        whenNotPaused
    {
        require(ecofund != address(0), INVALID_ADDRESS);
        require(msg.sender == SpawnContractAddress,NO_PERMISSION);
        _balances[addr] -= amount;
        _balances[ecofund] += amount;
        emit Transfer(addr, ecofund, amount);
    }
}

// File: CoinA.sol

pragma solidity ^0.8.4;




contract CoinADAO is CoinABase {

    bool public startDAO;

    /// @dev Total amount of staking.
    uint256 public totalStaking;

    string constant NO_DAO='DAO functions not available now';

    /// @dev Mapping from an address to its amount of staking for vote.
    mapping (address => uint256) public staking;

    /// @dev Mapping from an address to its amount of ballot.
    mapping (address => uint256) public ballot;

    /// @dev Mapping from an address to the address which is assigned stake.
    mapping (address => address) public assignedStaking;

    /// @dev Start DAO. In the meantime, superAdmin should change superAdmin to this contract.
    ///  Cautious! This function is irreversible.
    function activateDAO() external onlySuperAdmin {
        startDAO=true;
    }

    /// @dev Stake for vote.
    /// @param amount Amount of coinA that caller want to stake.
    function stake(uint256 amount) external whenNotPaused{
        require(startDAO,NO_DAO);
        totalStaking+=amount;
        staking[msg.sender]+=amount;
        transfer(address(this),amount);
        if (assignedStaking[msg.sender]!=address(0)){
            ballot[assignedStaking[msg.sender]]+=amount;
        }
        else{
            ballot[msg.sender]+=amount;
        }
    }

    /// @dev Caller assigns all staking to _to.
    /// @param _to If _to==address(0) or _to==msg.sender, cancel assignment.
    function assignStaking(address _to) external whenNotPaused{
        require(startDAO,NO_DAO);
        address assigned=assignedStaking[msg.sender];
        uint256 amount=staking[msg.sender];
        if(_to==address(0) && assigned!=address(0)){
            ballot[assigned]-=amount;
            ballot[msg.sender]+=amount;
        }
        else if(_to!=address(0) && assigned!=address(0)){
            ballot[assigned]-=amount;
            ballot[_to]+=amount;
        }
        else if(_to!=address(0) && assigned==address(0)){
            ballot[msg.sender]-=amount;
            ballot[_to]+=amount;
        }
        assignedStaking[msg.sender]=_to;
    }

    /// @dev Withdraw stake for vote.
    /// @param amount Amount of coinA that caller want to withdraw.
    function withdrawStake(uint256 amount) external whenNotPaused{
        require(startDAO,NO_DAO);
        totalStaking-=amount;
        staking[msg.sender]-=amount;
        this.transfer(msg.sender,amount);
        if (assignedStaking[msg.sender]!=address(0)){
            ballot[assignedStaking[msg.sender]]-=amount;
        }
        else{
            ballot[msg.sender]-=amount;
        }
    }
}

contract CoinAVote is CoinADAO{

    /// @dev Mapping from normal proposal id to a mapping which map address to 
    ///  whether the address has voted for the proposal.
    mapping (uint256 => mapping (address => bool)) normalConfirmations;

    /// @dev Mapping from noraml proposal id to address array which contains all addresses
    ///  that has voted for the proposal. 
    mapping (uint256 => address[]) normalConfirmedAddresses; 

    /// @dev Mapping from normal proposal id to whether vote result has been calculated.
    mapping (uint256 => bool) calculated;

    /// @dev Mapping from normal proposal id to an uint array, where each 
    ///  element is the corresponding ballot of options. 
    mapping (uint256 => uint256[10]) normalProposalResult;

    /// @dev Mapping from normal proposal id to a mapping which map index of options to all addresses approved it.
    mapping (uint256 => mapping(uint256 => address[])) normalOptionsToApproved;

    /// @dev Mapping from proposal id to a mapping which map address to its vote(index of options).
    mapping (uint256 => mapping (address => uint256)) voteTo;

    struct NormalProposal{
        address proposer;
        bool isAnonymous;
        bool isPublic;
        uint256 endAt;
        string[] options;
    }

    NormalProposal[] NormalProposals;

    string constant BALLOT_NOT_ENOUGH='ballot not enough';
    string constant VOTED='you have voted for this proposal';
    string constant VOTE_EXPIRED='vote period expired';
    string constant VOTE_NOT_END='vote period not end';
    string constant ANONYMOUS='This proposal is anonymous';
    string constant PRIVATE='private proposal, check result after conclusion';
    string constant NAMEED_AND_PRIVATE="vote can't be named and private at the same time";
    string constant NO_STAKING='no one staked';

    /// @dev Submit a normal proposal . Only address with more than 10% stake can submit proposals.
    /// @param isAnonymous Is the election anonymous?
    /// @param isPublic Is the elction public?
    /// @param isWeek Is the election last for a week or two weeks?
    /// @param options Options of vote.
    /// @return id Index in NormalProposals.
    function submitNormalProposal(bool isAnonymous, bool isPublic, bool isWeek,string[] memory options) external returns(uint256 id){
        require(totalStaking!=0,NO_STAKING);
        require(ballot[msg.sender]*10>=totalStaking,BALLOT_NOT_ENOUGH);
        require(options.length>=1 && options.length<=10,'length of options must between 1 and 10');
        if (isPublic==false && isAnonymous==false){
            require(false,NAMEED_AND_PRIVATE);
        }
        uint256 interval=1209600;
        if (isWeek){
            interval=604800;
        }
        NormalProposal memory _Proposal=NormalProposal({
            proposer:msg.sender,
            isAnonymous:isAnonymous,
            isPublic:isPublic,
            endAt:interval+block.timestamp,
            options:options
        });
        id=NormalProposals.length;
        NormalProposals.push(_Proposal);
    }

    /// @dev Confirm a normal proposal. Anyone can confirm a normal proposal. 
    ///  Valid ballot will be calculated at the first call of executeProposal after deadline.
    /// @param id Id of normal proposal.
    /// @param optionIndex Index of options.
    function confirmNormalProposal(uint256 id,uint256 optionIndex) external {
        require(NormalProposals[id].endAt>block.timestamp,VOTE_EXPIRED);
        require(!normalConfirmations[id][msg.sender],VOTED);
        require(optionIndex<NormalProposals[id].options.length,'invalid target');
        normalConfirmations[id][msg.sender]=true;
        normalConfirmedAddresses[id].push(msg.sender);
        normalOptionsToApproved[id][optionIndex].push(msg.sender);
        voteTo[id][msg.sender]=optionIndex;
    }

    /// @dev Calulate result of normal proposal. Consequence will be recorded in normalProposalResult.
    /// @param id Id of normal proposal.
    function calculateNormalProposal(uint256 id) external {
        require(NormalProposals[id].endAt<block.timestamp,VOTE_NOT_END);
        require(!calculated[id],'result has been calculated');
        calculated[id]=true;
        address[] memory addrs=normalConfirmedAddresses[id];
        for (uint256 i=0;i<addrs.length;i++){
            normalProposalResult[id][voteTo[id][addrs[i]]]+=ballot[addrs[i]];
        }
    }

    /// @dev Return information about normal proposal.
    function gainNormalProposal(uint256 id) external view returns(address,bool,bool,uint256,string[] memory){
        NormalProposal memory temp=NormalProposals[id];
        return (temp.proposer,temp.isAnonymous,temp.isPublic,temp.endAt,temp.options);
    }

    /// @dev Return addresses which approved optionIndex.
    function gainNormalNamed(uint256 id,uint256 optionIndex) external view returns(address[] memory){
        require(!NormalProposals[id].isAnonymous,ANONYMOUS);
        return normalOptionsToApproved[id][optionIndex];
    }

    /// @dev Return ballot of each option in options. This may not be the final result.
    /// @return res Final result or current result. Depends on isFinal.
    /// @return isFinal If isFinal is true, res is the final result, else res may change in the future.
    function gainNormalBallot(uint256 id) external view returns(uint256[10] memory res,bool isFinal){
        if (calculated[id]){
            res=normalProposalResult[id];
            isFinal=true;
        }
        else{
            require(NormalProposals[id].isPublic,PRIVATE);
            address[] memory addrs=normalConfirmedAddresses[id];
            for (uint256 i=0;i<addrs.length;i++){
                res[voteTo[id][addrs[i]]]+=ballot[addrs[i]];
            }
        }
    }

    /// @dev When an important proposal is executed, emit this event with executed==true.
    ///  When an important proposal is dropped, emit this event with executed==false.
    event importantProposalEvent(uint256 indexed id,
        address indexed proposer,
        address indexed sc,
        uint256 op,
        uint256 endAt,
        bool isAnonymous,
        bool isPublic,
        address param1,
        uint256 param2,
        bool executed);

    /// @dev Mapping from important proposalId to a mapping which map address to wether the address has voted for the proposal.
    mapping (uint256 => mapping (address => bool)) importantConfirmations;
    /// @dev Mapping from important proposalId to all addresses voted for it.
    mapping (uint256 => address[]) importantConfirmedAddresses;

    struct ImportantProposal{
        uint256 id;
        address proposer;
        address sc;
        uint256 op;
        bool isAnonymous;
        bool isPublic;
        uint256 endAt;
        address param1;
        uint256 param2;
    }

    ImportantProposal[] ImportantProposals;

    uint256 importantProposalCount;

    /// @dev Submit a proposal . Only address with more than 10% stake can submit proposal.
    /// @param sc Target smart contract.
    /// @param op Operation type executed by sc.
    /// @param isAnonymous Is the election anonymous?
    /// @param isPublic Is the elction public?
    /// @param isWeek Is the election last for a week or two weeks?
    /// @param param1 Parameter of operation op.
    /// @param param2 Parameter of operation op.
    function submitImportantProposal(address sc, uint256 op, bool isAnonymous, bool isPublic, bool isWeek,address param1, uint256 param2) external returns(uint256 id){
        require(totalStaking!=0,NO_STAKING);
        require(ballot[msg.sender]*10>=totalStaking,BALLOT_NOT_ENOUGH);
        require(op<15,'wrong op');
        if (isPublic==false && isAnonymous==false){
            require(false,NAMEED_AND_PRIVATE);
        }
        uint256 interval=1209600;
        if (isWeek){
            interval=604800;
        }
        ImportantProposal memory _Proposal=ImportantProposal({
            id:importantProposalCount,
            proposer:msg.sender,
            sc:sc,
            op:op,
            isAnonymous:isAnonymous,
            isPublic:isPublic,
            endAt:interval+block.timestamp,
            param1: param1,
            param2: param2
        });
        id=importantProposalCount;
        importantProposalCount++;
        ImportantProposals.push(_Proposal);
        confirmImportantProposal(id);
    }

    /// @dev Confirm a proposal. Anyone can confirm a proposal. 
    ///  Valid ballot will be calculated at the first call of executeProposal after deadline.
    ///  Ensure that _Proposal.sc is correct address.
    function confirmImportantProposal(uint256 id) public {
        removeExpiredProposal();
        uint256 i=findIndex(id);
        require(ImportantProposals[i].endAt>block.timestamp,VOTE_EXPIRED);
        require(!importantConfirmations[id][msg.sender],VOTED);
        importantConfirmations[id][msg.sender]=true;
        importantConfirmedAddresses[id].push(msg.sender);
    }

    function executeProposal(uint256 id) external {
        removeExpiredProposal();
        uint256 i=findIndex(id);
        ImportantProposal memory _Proposal=ImportantProposals[i];
        require(_Proposal.endAt<block.timestamp,VOTE_NOT_END);
        uint256 op=_Proposal.op;
        uint256 l=ImportantProposals.length;
        ImportantProposals[i]=ImportantProposals[l-1];
        ImportantProposals.pop();
        if (op==0) {
            AccessControl sc=AccessControl(_Proposal.sc);
            sc.changeSuperAdmin(payable(_Proposal.param1));
        }
        else if (op==1) {
            AccessControl sc=AccessControl(_Proposal.sc);
            sc.changeAdmin(payable(_Proposal.param1));
        }
        else if (op==2) {
            AccessControl sc=AccessControl(_Proposal.sc);
            sc.withdrawBalance(_Proposal.param2);
        }
        else if (op==3) {
            Pausable sc=Pausable(_Proposal.sc);
            sc.pause();
        }
        else if (op==4) {
            Pausable sc=Pausable(_Proposal.sc);
            sc.unpause();
        }
        else if (op==5) {
            ISpawnCoin sc=ISpawnCoin(_Proposal.sc);
            sc.setSpawnContractAddress(_Proposal.param1);
        }
        else if (op==6) {
            ICapsuleContract sc=ICapsuleContract(_Proposal.sc);
            sc.setELFCoreAddress(_Proposal.param1);
        }
        else if (op==7) {
            Imisc sc=Imisc(_Proposal.sc);
            sc.changeCoinAddresses(_Proposal.param2,_Proposal.param1);
        }
        else if (op==8) {
            ERC20Implementation sc=ERC20Implementation(_Proposal.sc);
            sc.transfer(_Proposal.param1,_Proposal.param2);
        }
        else if (op==9) {
            Imisc sc=Imisc(_Proposal.sc);
            sc.setELFCore(_Proposal.param1);
        }
        else if (op==10) {
            Imisc sc=Imisc(_Proposal.sc);
            sc.changeCapsuleContract(_Proposal.param1);
        }
        else if (op==11) {
            Imisc sc=Imisc(_Proposal.sc);
            sc.changeSpawnContract(_Proposal.param1);
        }
        else if (op==12) {
            Imisc sc=Imisc(_Proposal.sc);
            sc.changeCoinA(_Proposal.param1);
        }
        else if (op==13) {
            Imisc sc=Imisc(_Proposal.sc);
            sc.changeCoinB(_Proposal.param1);
        }
        else if (op==14) {
            payable(_Proposal.param1).transfer(_Proposal.param2);
        }
        emit importantProposalEvent(_Proposal.id,_Proposal.proposer,_Proposal.sc,_Proposal.op,_Proposal.endAt,_Proposal.isAnonymous,_Proposal.isPublic,_Proposal.param1,_Proposal.param2,true);
    }

    /// @dev Return information about important proposal.
    function gainImportantProposal(uint256 id) external view returns(address,address,uint256,bool,bool,uint256,address,uint256){
        uint256 i=findIndex(id);
        ImportantProposal memory temp=ImportantProposals[i];
        return (temp.proposer,temp.sc,temp.op,temp.isAnonymous,temp.isPublic,temp.endAt,temp.param1,temp.param2);
    }

    /// @dev Return addresses which approved the proposal.
    function gainImportantNamed(uint256 id) external view returns(address[] memory){
        uint256 i=findIndex(id);
        require(!ImportantProposals[i].isAnonymous,ANONYMOUS);
        return importantConfirmedAddresses[id];
    }

    /// @dev Return current ballot of the given important proposal.
    function gainImportantBallot(uint256 id) external view returns(uint256 res){
        uint256 i=findIndex(id);
        require(ImportantProposals[i].isPublic,PRIVATE);
        address[] memory addrs=importantConfirmedAddresses[id];
        for (uint256 i2=0;i2<addrs.length;i2++){
            res+=ballot[addrs[i2]];
        }
    }

    /// @dev Find index of id in ImportantProposals.
    function findIndex(uint256 id) internal view returns(uint256 i){
        uint256 l=ImportantProposals.length;
        while (i<l){
            if (ImportantProposals[i].id==id){
                break;
            }
            i++;
        }
        require(i<l,'proposal not found');
    }

    /// @dev If deadline come, and proposal not achieve goal, drop it. Else, pass
    function removeExpiredProposal() internal {
        uint256 l=ImportantProposals.length;
        for (uint256 i=0;i<l;){
            if (ImportantProposals[i].endAt<=block.timestamp && !goalAchieved(i)){
                ImportantProposal memory _Proposal=ImportantProposals[i];
                emit importantProposalEvent(_Proposal.id,_Proposal.proposer,_Proposal.sc,_Proposal.op,_Proposal.endAt,_Proposal.isAnonymous,_Proposal.isPublic,_Proposal.param1,_Proposal.param2,false);
                ImportantProposals[i]=ImportantProposals[l-1];
                ImportantProposals.pop();
                l--;
            }
            else{
                i+=1;
            }
        }
    }

    /// @dev Examine whether the important proposal can be executeed.
    ///  This function doesn't check wether deadline has come.
    /// @param i Index in array ImportantProposals.
    function goalAchieved(uint256 i) internal view returns(bool){
        ImportantProposal memory _Proposal=ImportantProposals[i];
        uint256 id=_Proposal.id;
        address[] memory addrs=importantConfirmedAddresses[id];
        uint256 l=addrs.length;
        uint256 total;
        for (uint256 i2;i2<l;i2++){
            total+=ballot[addrs[i2]];
        }
        return total*2>=totalStaking;
    }
}