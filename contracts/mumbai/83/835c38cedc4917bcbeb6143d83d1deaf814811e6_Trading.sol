/**
 *Submitted for verification at polygonscan.com on 2023-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://e...content-available-to-author-only...m.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/Polling.sol


pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Trading is Ownable, ReentrancyGuard{

    

    struct Activation{
        bool isActivated;
        uint date;
        uint prevDate;
    }

    struct Pakage{
        uint amount; // Lock amount
        uint unlockTime; // Unlock time
        uint lastRewardClaimTime; // claiming time.
        uint totalRewardClaimed; // total reward claimed.
        address trader;
        uint rewardRatio;
        address[20] friends;
        uint remaining;
    }

    // State Variables 

    mapping(address=> Activation) hasActivated;
    mapping(uint => Pakage) public trades;
    mapping(address => uint[]) public tradeIds;
    uint public totaltrades;
    uint public activationCost = 10;
    uint public activationDuration = 30 days;
    uint public perTime = 1 days;
    uint[5] public payoutPerPakage = [5000, 5000, 5000, 5000, 5000]; 
    uint[5] public unlockTImes = [45, 30, 20, 15, 10];
    uint[5] public rewardRatios = [50, 55, 60, 65, 70];
    uint[20] public referralRatios = [100000, 50000, 30000, 20000, 10000, 10000, 10000, 10000, 10000, 10000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000, 5000];
    uint public tradePercentage = 0;
    mapping(address=> bool) public canWithdraw;
    mapping(address=> uint) public canWithdrawAmount;
    uint public delay = 1;
    uint[5] public pakages_prices  = [100, 500, 1000, 5000, 10000];
    mapping(address=> bool) public affiliate;
    address public remaining;

    
    IERC20 public USDT;

    constructor(address _USDT, address _remainging_address){
        USDT = IERC20(_USDT);
        remaining = _remainging_address;
    }

    function setAffiliate(address _trader, bool _state) public onlyOwner{
        affiliate[_trader] = _state;
    }
    function setReamining(address _address) public onlyOwner{
        remaining = _address;
    }


    function Activate() public{

        Activation storage _activation = hasActivated[msg.sender];

        require(!isActivated(), "You have already activated for this month");

        USDT.transferFrom(msg.sender, address(this), activationCost*10**USDT.decimals());
        if(_activation.date == 0){
            _activation.prevDate = block.timestamp;

        }else{
            _activation.prevDate = _activation.date;
            

        }
        _activation.isActivated = true;
        _activation.date = block.timestamp;

    }

    function addActivate(address _address) public{

        Activation storage _activation = hasActivated[_address];

        if(_activation.date == 0){

            _activation.prevDate = block.timestamp;

        }else{
            _activation.prevDate = _activation.date;
        }
        _activation.isActivated = true;
        _activation.date = block.timestamp;

    }

    function addTrade(address[] memory _traders, uint[] memory _amounts, address[20][] memory _friends ) public onlyOwner{
        for(uint i = 0; i<_traders.length; i++){
            _addTrade(_traders[i], _amounts[i], _friends[i]);
        }
    }


    function _addTrade(address _trader,uint _amount, address[20] memory _friends) private {
        require(_amount == pakages_prices[0]*10**USDT.decimals() ||
                _amount == pakages_prices[1]*10**USDT.decimals() ||
                _amount == pakages_prices[2]*10**USDT.decimals() ||
                _amount == pakages_prices[3]*10**USDT.decimals() ||
                _amount == pakages_prices[4]*10**USDT.decimals(), "Invalid amount for staking");
        uint _timeAmount = 0;
        uint _rewardRatio = 0;
        if(_amount == pakages_prices[0]*10**USDT.decimals()){
            _timeAmount = unlockTImes[0]* 1 days;
            _rewardRatio = rewardRatios[0];
        }else if(_amount == pakages_prices[1]*10**USDT.decimals()){
            _timeAmount = unlockTImes[1]* 1 days;
            _rewardRatio = rewardRatios[1];
        }
        else if(_amount == pakages_prices[2]*10**USDT.decimals()){
            _timeAmount = unlockTImes[2]* 1 days;
            _rewardRatio = rewardRatios[2];
        }
        else if(_amount == pakages_prices[3]*10**USDT.decimals()){
            _timeAmount = unlockTImes[3]* 1 days;
            _rewardRatio = rewardRatios[3];
        }
        else if(_amount == pakages_prices[4]*10**USDT.decimals()){
            _timeAmount = unlockTImes[4]* 1 days;
            _rewardRatio = rewardRatios[4];
        }

    
        Pakage storage _pakage = trades[totaltrades];

        _pakage.amount = _amount;
        _pakage.unlockTime = block.timestamp + _timeAmount;
        _pakage.lastRewardClaimTime = block.timestamp;
        _pakage.trader = _trader;
        _pakage.rewardRatio = _rewardRatio;
        tradeIds[_trader].push(totaltrades);

        totaltrades+=1;

        _pakage.friends = _friends;

        Activation storage _activation = hasActivated[_trader];

        if(_activation.isActivated && _activation.date + activationDuration>block.timestamp){
            // Do nothing. Don't need to reactivate.
        }else{
            if(_activation.date == 0){
            _activation.prevDate = block.timestamp;

            }else{
                _activation.prevDate = _activation.date;
                

            }
            _activation.isActivated = true;
            _activation.date = block.timestamp;
        }

        

    }

    function trade(uint _amount, address[20] memory _friends) public { 

        require(_amount == pakages_prices[0]*10**USDT.decimals() ||
        _amount == pakages_prices[1]*10**USDT.decimals() ||
        _amount == pakages_prices[2]*10**USDT.decimals() ||
        _amount == pakages_prices[3]*10**USDT.decimals() ||
        _amount == pakages_prices[4]*10**USDT.decimals(), "Invalid amount for staking");

        uint _timeAmount = 0;
        uint _rewardRatio = 0;
        if(_amount == pakages_prices[0]*10**USDT.decimals()){
            _timeAmount = unlockTImes[0]* 1 days;
            _rewardRatio = rewardRatios[0];
        }else if(_amount == pakages_prices[1]*10**USDT.decimals()){
            _timeAmount = unlockTImes[1]* 1 days;
            _rewardRatio = rewardRatios[1];
        }
        else if(_amount == pakages_prices[2]*10**USDT.decimals()){
            _timeAmount = unlockTImes[2]* 1 days;
            _rewardRatio = rewardRatios[2];
        }
        else if(_amount == pakages_prices[3]*10**USDT.decimals()){
            _timeAmount = unlockTImes[3]* 1 days;
            _rewardRatio = rewardRatios[3];
        }
        else if(_amount == pakages_prices[4]*10**USDT.decimals()){
            _timeAmount = unlockTImes[4]* 1 days;
            _rewardRatio = rewardRatios[4];
        }

        uint _samount = (_amount*tradePercentage)/100;
        
        USDT.transferFrom(msg.sender, address(this), _amount-_samount);

        if(_samount>0){
            USDT.transferFrom(msg.sender, owner(), _samount);

        }

        Pakage storage _pakage = trades[totaltrades];

        _pakage.amount = _amount;
        _pakage.unlockTime = block.timestamp + _timeAmount;
        _pakage.lastRewardClaimTime = block.timestamp;
        _pakage.trader = msg.sender;
        _pakage.rewardRatio = _rewardRatio;
        tradeIds[msg.sender].push(totaltrades);

        totaltrades+=1;

        _pakage.friends = _friends; 
            
    }

    function ClaimReward(uint _id, address[20] memory _friends)  public { // needs to devide per reward ratio.
        Pakage storage _pakage = trades[_id];
        require(_pakage.trader == msg.sender, "You are not the owner of the Trade");
        _pakage.friends = _friends;
        require(_pakage.amount>0, "Not a valid trade");
        Activation memory _activation = hasActivated[msg.sender];

        (uint _reward, uint _remainingDays) = _CalulateReward(_id);

        _pakage.remaining = _remainingDays;

        require(_reward>0, "There is no reward to claim");

        if(!isActivated()){
            _pakage.lastRewardClaimTime = _activation.date + activationDuration;
        }else{
            _pakage.lastRewardClaimTime = block.timestamp;
        }

        uint _referralBonus = (_pakage.rewardRatio*_reward)/100;
        if(affiliate[msg.sender] == true){
            _referralBonus = 0;
        }
        USDT.transfer(msg.sender, _reward-_referralBonus);


        for(uint i = 0; i<_pakage.friends.length; i=i+1){

            Activation memory _activation_friend = hasActivated[_pakage.friends[i]];
            
            if(_activation_friend.isActivated && _activation_friend.date + activationDuration>block.timestamp){
                 USDT.transfer(_pakage.friends[i], (referralRatios[i]*_referralBonus)/(100*(10**4)));
                _referralBonus = _referralBonus-((referralRatios[i]*_referralBonus)/(100*(10**4)));
            }

        }
        _pakage.totalRewardClaimed = _pakage.totalRewardClaimed + _reward;
        USDT.transfer(remaining, _referralBonus);
    }

    function Untrade(uint _id) public {
        
        Pakage storage _pakage = trades[_id];
        require(_pakage.trader == msg.sender, "Not your trade");
        require(_pakage.unlockTime<block.timestamp, "You can't unloack yet.");
        (uint _reward, uint _remainingDays) = _CalulateReward(_id);
        _pakage.remaining = _remainingDays;
        USDT.transfer(_pakage.trader, _pakage.amount+_reward);
        _pakage.totalRewardClaimed = _pakage.totalRewardClaimed + _reward;

        _pakage.amount = 0;

    }

    function CalulateReward(address _trader) public view returns(uint){
        uint[] memory ids = tradeIds[_trader];
        uint totalReward = 0;
        uint reward = 0;
        uint time = 0;
        for(uint i = 0; i<ids.length ; i++){
            (reward, time) =  _CalulateReward(i);
            totalReward += reward;
        }
        return totalReward;
    }

    function _CalulateReward(uint _id) private view returns(uint, uint){
        Pakage memory _pakage = trades[_id];
        uint _totalReward = 0;
        

        (uint _rewarDays, uint _remainingDays) = CatculateRewardTimes(_id);

        // waiting for 24 hours to start payout.
        if(_pakage.totalRewardClaimed==0){
                if(_rewarDays>delay){
                    _rewarDays = _rewarDays - delay;
                }else{
                    _rewarDays = 0;
                }
            }
        
        if(_pakage.amount == pakages_prices[0]*10**USDT.decimals()){
            _totalReward = (_rewarDays * (payoutPerPakage[0]*_pakage.amount))/(100*(10**4));
            
        }else if(_pakage.amount == pakages_prices[1]*10**USDT.decimals()){
            _totalReward = (_rewarDays * (payoutPerPakage[1]*_pakage.amount))/(100*(10**4));

        }else if(_pakage.amount == pakages_prices[2]*10**USDT.decimals()){
            _totalReward = (_rewarDays * (payoutPerPakage[2]*_pakage.amount))/(100*(10**4));

        }else if(_pakage.amount == pakages_prices[3]*10**USDT.decimals()){
            _totalReward = (_rewarDays * (payoutPerPakage[3]*_pakage.amount))/(100*(10**4));

        }else if(_pakage.amount == pakages_prices[4]*10**USDT.decimals()){
            _totalReward = (_rewarDays * (payoutPerPakage[4]*_pakage.amount))/(100*(10**4)); 

        }

        return (_totalReward , _remainingDays);


    } 

    function setPakagePrice(uint _index, uint _value) public onlyOwner{
        pakages_prices[_index] = _value;
    }

    

    function isActivated() public view returns(bool){
        Activation memory _activation = hasActivated[msg.sender];
        return _activation.isActivated && _activation.date + activationDuration>block.timestamp; 
    }


    function CatculateRewardTimes(uint _id) public view returns(uint, uint){
        Pakage memory _pakage = trades[_id];
        Activation memory _activation = hasActivated[msg.sender];
        uint _totalCurrentActivationDays = 0;
        uint _prevActivaionDays = 0;
        uint _rewarDays = 0;
        uint _totalTime = 0;
        uint _remainingDays = 0;
        if(!isActivated()){

            _totalTime = activationDuration - ((_pakage.lastRewardClaimTime - _activation.date)) + _pakage.remaining;
   
        }else{
            _totalCurrentActivationDays = (block.timestamp - _pakage.lastRewardClaimTime);
            
            if(_activation.date>_pakage.lastRewardClaimTime){
                _prevActivaionDays = activationDuration - ((_pakage.lastRewardClaimTime - _activation.prevDate));
            }
           _totalTime = (_totalCurrentActivationDays + _prevActivaionDays + _pakage.remaining);
                
        }

        _rewarDays = _totalTime/perTime;
        _remainingDays = _totalTime - (_rewarDays*perTime);

        return (_rewarDays, _remainingDays);
    }

    function distributeReward(address[] memory _address, uint[] memory amounts) public onlyOwner{
        
        for(uint i=0;i<_address.length;i++){
            Activation memory _activation = hasActivated[_address[i]];
            if(_activation.isActivated && _activation.date + activationDuration>block.timestamp){
                USDT.transfer(_address[i], amounts[i]);
            }
        }
    }


    function setUnlockTImes(uint _index, uint _value) public onlyOwner{
        require(_index>0 && _index<6, "INVALID INDEX");
        unlockTImes[_index-1] = _value;
    }

    function setRewardRatios(uint _index, uint _value) public onlyOwner{
        require(_index>0 && _index<6, "INVALID INDEX");
        rewardRatios[_index-1] = _value;

    }

    function setActivationCost(uint _value) public onlyOwner{
        activationCost = _value;
    }

    function settradePercentage(uint _value) public onlyOwner{
        tradePercentage = _value;
    }

    function setActivationDuration(uint _value) public onlyOwner{
        activationDuration = _value;
    }

    function setPerTime(uint _perTime) public onlyOwner{
        perTime = _perTime;

    }

    function changeToken(address _token) public onlyOwner{
        USDT = IERC20(_token);
    }

    function withdrawToken(address _token, uint _amount) public onlyOwner{
        IERC20 token = IERC20(_token);
        token.transfer(owner(), _amount);
    }

    function withdrawNativeToken(uint _amount, address payable _receiver) public onlyOwner{
        require(address(this).balance>_amount, "Not enough balance");
        _receiver.transfer(_amount);
    }

    function getUsertrades() public view returns(uint[] memory){
        return tradeIds[msg.sender];
    }

    function setCanWithdraw(address _withdrawer, bool _state, uint _amount) public onlyOwner{
        canWithdraw[_withdrawer] = _state;
        canWithdrawAmount[_withdrawer] = _amount;
    }

    function PermissionedWithdraw() public {
        require(canWithdraw[msg.sender] == true, "You don't have permission to witdraw");
        USDT.transfer(msg.sender, canWithdrawAmount[msg.sender]);
        canWithdrawAmount[msg.sender] = 0;
        canWithdraw[msg.sender] = false;
    }




}