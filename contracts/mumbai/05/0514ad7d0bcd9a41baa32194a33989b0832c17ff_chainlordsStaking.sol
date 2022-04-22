/**
 *Submitted for verification at polygonscan.com on 2022-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// update names to the design getTotalRewards -> getUnclaimedRewards
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


/**
* @title chainlordsStaking
* @dev The chainlordsStaking is a constract used for staking GLORY and LP tokens 
* and rewards users with GLORY".
*/
contract chainlordsStaking is  Ownable {

    using SafeMath for uint256;
    mapping (address => uint256) public ratePerToken;
    uint256 numerOfUsers=0;
    mapping(uint256 => address) public listOfUsers;
    mapping (address => UserInfo) private users;
    uint256 public numberOfTokens = 0;
    mapping (uint256 => address) public acceptableTokens;
    uint256 public constant  NUMBEROFBLOCKSPERDAY = 40000;
    address public rewardToken;
    bool public openForStaking = false;
    mapping(address=>uint256) public stakedAmountPerToken;
    /**
    * @dev This modifier is used to check if the contract is open for staking.
    */
    modifier whenOpenForStaking() {
    require(openForStaking, "Contract is not open for staking");
    _;
    }

    /**
    * @dev This modifier is used to check if the contract is not open for staking.
    */
    modifier whenNotOpenForStaking() {
    require(!openForStaking, "Contract is open for staking");
    _;
    }

    /**
    * @dev Sets the contract open for staking. 
    *  Requirments : The caller of the function is the contract owner.
    */
    function openStaking() onlyOwner whenNotOpenForStaking public {
        openForStaking = true;
    }

    /**
    * @dev Sets the contract closed for staking. 
    *  Requirments : The caller of the function is the contract owner.
    */
    function closeStaking() onlyOwner whenOpenForStaking public {
        openForStaking = false;
    }

    struct UserInfo {
        bool exists;
        uint256 rewardAmount;
        mapping (address => uint256)  _depositBlocks;
        mapping (address => uint256)  amountPerToken; 
        uint256 claimedRewards;       
    }

    /**
    * @dev Sets the rewardToken address and the rewardToken's APY.
    *  Because the contract inherites from ownable,
    *  the caller becomes the contract owner.
    */
    constructor(address _rewardToken, uint256 rewardAPY){
        rewardToken = _rewardToken;
        addToken(rewardToken,rewardAPY);
    }

    /**
    * @dev Enables caller to stake an amount of the token that is specified in tokenAddress.
    * Creates a user to keep track of user's funds, if the caller does not exist, otherwise
    * updates user's current information.
    *
    *  Visibility : Public.  
    *  
    *  Requirments : 
    *        - Contract is open for staking.
    *        - The staking amount is greater than one token.
    *        - The allowance of the contract is greater or equal to the staking amount.
    */
    function stake(address tokenAddress, uint256 amount) public  whenOpenForStaking{
        require(amount >= (1e18), "Can not stake less than 1 token");  
        require(tokenIsInTheList(tokenAddress), "This token is not supported");
        uint256 allowance = IERC20(tokenAddress).allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

       if(users[msg.sender].exists == false )
       { 
            UserInfo storage user = users[msg.sender];
            user._depositBlocks[tokenAddress] = block.number; 
            user.amountPerToken[tokenAddress] = amount;
            user.rewardAmount = 0;
            user.claimedRewards = 0;
            user.exists = true;
        }else 
        {
            uint256 currentAmmount = users[msg.sender].amountPerToken[tokenAddress];
            users[msg.sender].rewardAmount = users[msg.sender].rewardAmount.add(calculateRewards(users[msg.sender]._depositBlocks[tokenAddress], tokenAddress, currentAmmount));
            users[msg.sender].amountPerToken[tokenAddress] = currentAmmount.add(amount);
            users[msg.sender]._depositBlocks[tokenAddress] = block.number;           
        }

        listOfUsers[numerOfUsers] = msg.sender;
        numerOfUsers++;

        if(stakedAmountPerToken[tokenAddress] ==0){
            stakedAmountPerToken[tokenAddress] = amount;
        }else{
            stakedAmountPerToken[tokenAddress] = stakedAmountPerToken[tokenAddress].add(amount); 
        }
        
    }

    /**
    * @dev Enables caller to unstake an amount of the token that is specified in tokenAddress.
    * The contract updates caller's infromation and sends the amount to the caller.
    *
    *  Visibility : Public.  
    *  
    *  Requirments : 
    *        - Contract is open for staking.
    *        - Caller is an existing user.
    *        - The tokenAddress is not the zero address.
    *        - The unstaking amount is less or equal to user's staked amount.
    */
    function unstake(address tokenAddress, uint256 amount) public whenOpenForStaking{
        require(tokenIsInTheList(tokenAddress), "Token is not supported");
        require(users[msg.sender].exists,"User does not exist");
        require(tokenAddress != address(0));
        require(amount<= users[msg.sender].amountPerToken[tokenAddress], "Cannot unstake more than what you have");
        users[msg.sender].rewardAmount =  users[msg.sender].rewardAmount.add(calculateRewards(users[msg.sender]._depositBlocks[tokenAddress], tokenAddress, users[msg.sender].amountPerToken[tokenAddress]));
        users[msg.sender].amountPerToken[tokenAddress] = users[msg.sender].amountPerToken[tokenAddress].sub(amount);
        users[msg.sender]._depositBlocks[tokenAddress] = block.number;
        IERC20(tokenAddress).transfer(msg.sender,amount);
        if(amount>stakedAmountPerToken[tokenAddress]){
            stakedAmountPerToken[tokenAddress] = 0;
        }else{
            stakedAmountPerToken[tokenAddress] = stakedAmountPerToken[tokenAddress].sub(amount); 
        }
        
    }

    /**
    * @dev Enables caller to claim his latest rewards.
    * The contract updates caller's funds and sends the rewards to the caller.
    *
    *  Visibility : Public.  
    *  
    *  Requirments : 
    *        - Contract is open for staking.
    *        - Caller is an existing user.
    *        - User's current rewards are greater than 0.
    */
    function claimRewards() public whenOpenForStaking{
        require(users[msg.sender].exists,"User does not exist");
        calculateUserTotalRewards(msg.sender);
        require(users[msg.sender].rewardAmount>0,"Not enough rewards to claim");
        uint256 currentAmmount = users[msg.sender].rewardAmount;
        users[msg.sender].claimedRewards = users[msg.sender].claimedRewards.add(currentAmmount);
        users[msg.sender].rewardAmount = 0;
        IERC20(rewardToken).transfer(msg.sender,currentAmmount);
    }
    
    /**
    * @dev Returns the amount of user's claimed rewards.
    *
    *  Visibility : Public.  
    *  
    *  Requirments : 
    *        - User address is not the zero address.
    *        - Caller is an existing user.
    *
    *   Return Type : uint256.
    */
    function getUserClaimedRewards(address userAddress) view public returns(uint256) {
        require(userAddress!= address(0));
        require(users[userAddress].exists,"User does not exist");
        return users[userAddress].claimedRewards;
    }

    /**
    * @dev Enables caller to stake his latest rewards.
    * The contract updates caller's funds and stakes rewards to the contract.
    *
    *  Visibility : Public.  
    *  
    *  Requirments : 
    *        - Contract is open for staking.
    *        - Caller is an existing user.
    *        - User's current rewards are greater than 0.
    */
    function stakeRewards() public whenOpenForStaking{
        require(users[msg.sender].exists,"User does not exist");
        calculateUserTotalRewards(msg.sender);
        require(users[msg.sender].rewardAmount>0,"Nothing to stake");
        uint256 currentRewards = users[msg.sender].rewardAmount;
        users[msg.sender].rewardAmount = 0;
        users[msg.sender].amountPerToken[rewardToken] = users[msg.sender].amountPerToken[rewardToken].add(currentRewards);
        stakedAmountPerToken[rewardToken] = stakedAmountPerToken[rewardToken].add(currentRewards); 
    }

    /**
    * @dev Sets userAddress's reward amount to the latest 
    * and sets all deposits to the current block number.
    *
    *  Visibility : Internal. 
    *
    *  Return Type : uint256.
    */
    function calculateUserTotalRewards(address userAddress) public returns(uint256){
        users[userAddress].rewardAmount = users[userAddress].rewardAmount.add(getUserNewRewards(userAddress));
        address[] memory tokenList = getListOfTokens();
        for(uint256 i=0; i<tokenList.length;i++){
            address tokenAddress = tokenList[i];
            if(users[userAddress].amountPerToken[tokenAddress]>0){
                users[userAddress]._depositBlocks[tokenAddress] = block.number;
            }
        }
        
        return users[userAddress].rewardAmount;
    }    

    /**
    * @dev Returns userAddress's latest rewards after the last they were calculated.
    *
    *  Visibility : Internal.  
    *  
    *  Requirments : 
    *        - User with 'userAddress' is an existing user.
    *
    *  Return Type : uint256.
    */
    function getUserNewRewards(address userAddress) public view returns(uint256){
        require(users[userAddress].exists,"User does not exist");
        address[] memory tokenList = getListOfTokens();
        uint256 rewards =0;
        for(uint256 i=0; i<numberOfTokens;i++){
            address tokenAddress = tokenList[i];
            if(users[userAddress].amountPerToken[tokenAddress]>0){
                uint256 currentAmmount = getUserStakedAmountPerToken(userAddress,tokenAddress);
                rewards = rewards.add(calculateRewards(getDepositBlock(userAddress, tokenAddress), tokenAddress, currentAmmount));
            }
        }
        return rewards;
    }

    //This will be removed
    function getRewUs(address user) public view returns(uint256){
        uint256 rewaAmount = users[user].rewardAmount;
        return rewaAmount;
    }

    /**
    * @dev Returns userAddress's total rewards.
    *
    *  Visibility : Public.  
    *  
    *  Requirments : 
    *        - User with 'user' is an existing user.
    *
    *  Return Type : uint256.
    */
    function getUserUnclaimedRewards(address user) public view returns(uint256){
        require(users[user].exists,"User does not exist");
        uint256 tempAmount = users[user].rewardAmount.add(getUserNewRewards(user));
        return tempAmount;
    }
    
    /**
    * @dev Returns staked amount of a user's token.
    *
    *  Visibility : Public.  
    *  
    *  Return Type : uint256.
    */
    function getUserStakedAmountPerToken(address user, address tokenAddress) public view returns(uint256){
        return users[user].amountPerToken[tokenAddress];
    }

    /**
    * @dev Returns deposit block number of a user's token.
    *
    *  Visibility : Internal.  
    *  
    *  Return Type : uint256.
    */
    function getDepositBlock(address user, address tokenAddress) public view returns(uint256){
        return users[user]._depositBlocks[tokenAddress];
    }

    //this will be removed
    function getCurrentBlock() public view returns(uint256){
        return block.number;
    }

    /**
    * @dev Returns the amount of tokens, that should be rewarded to the user, per block, depending on the token APY.
    *
    *  Visibility : Internal.  
    *  
    *  Requirments :
    *        - The rate is greater than 0.  
    *
    *  Return Type : uint256.
    */
    function calculateRewardPerBlock(uint256 rate) public view returns(uint256){
        require(rate>0);
        uint256 tempRate = (rate.mul(1e18)).div(365).div(100);
        return (tempRate.div(NUMBEROFBLOCKSPERDAY));
    }

    /**
    * @dev Returns the amount of tokens, that should be rewarded to the user 
    * for the time period between the current block and the deposit block,
    * based on the rewards per Block.
    *
    *  Visibility : Internal.  
    *
    *  Return Type : uint256.
    */
    function calculateRewards(uint256 depositBlockNumber, address tokenAddress, uint256 amount) public view returns(uint256){
        uint256  tokenAPY = ratePerToken[tokenAddress];
        uint256 tokensPerBlock = calculateRewardPerBlock(tokenAPY);
        // uint256 rewards = (tokensPerBlock).mul( depositBlockNumber).mul(amount.div(1e18));
        uint256 rewards = tokensPerBlock.mul(block.number.sub(depositBlockNumber)).mul(amount.div(1e18));
        return rewards;
    }

    //this will be removed
    function checkingCalcRewPerBlock( uint256 amount, uint256 rate) public returns(uint256){
        return (((calculateRewardPerBlock(rate).mul(NUMBEROFBLOCKSPERDAY)).mul(365)).mul(amount));
    }

    /**
    * @dev Enables caller to add a Token in the acceptable token list and set its APY.
    *
    *  Visibility : Public.  
    *  
    *  Requirments : 
    *        - Caller is the contract owner.
    *        - Token address is not the zero address.
    *        - Token does not already exist in the acceptable token list.
    */
    function addToken(address tokenAddress, uint256 tokenAPY) public onlyOwner {
        require(tokenAddress != address(0));
        require(!tokenIsInTheList(tokenAddress), "Token already exists");
        ratePerToken[tokenAddress] = tokenAPY;
        acceptableTokens[numberOfTokens] = tokenAddress;
        numberOfTokens++;
    }

    /**
    * @dev Enables caller to set token's APY.
    *
    *  Visibility : Public.  
    *  
    *  Requirments : 
    *        - Caller is the contract owner.
    *        - Token address is not the zero address.
    *        - Token does not already exist in the acceptable token list.
    */
    function setRewards(address tokenAddress, uint256 tokenAPY) public onlyOwner{
        require(tokenAddress != address(0));
        require(tokenIsInTheList(tokenAddress), "Token does not exist");
        ratePerToken[tokenAddress] = tokenAPY;
        acceptableTokens[numberOfTokens] = tokenAddress;
        numberOfTokens++;
    }

    /**
    * @dev Enables caller to set the reward token and its APY.
    *
    *  Visibility : Public.  
    *  
    *  Requirments : 
    *        - Caller is the contract owner.
    *        - Token address is not the zero address.
    *        - Token does not already exist in the acceptable token list.
    */
    function setRewardToken(address rewardTokenAddress, uint256 rewardTokenAPY) public onlyOwner{
        require(rewardTokenAddress != address(0));
        require(tokenIsInTheList(rewardTokenAddress), "Token does not exist");
        rewardToken = rewardTokenAddress;
        ratePerToken[rewardToken] = rewardTokenAPY;
        addToken(rewardTokenAddress,rewardTokenAPY);
    }

    /**
    * @dev Checks if a token is part of the acceptable token list.
    *
    *  Visibility : Internal.  
    *  
    *  Return Type : bool.
    */
    function tokenIsInTheList(address tokenAddress) public view returns (bool){
        address[] memory tokenList = getListOfTokens();
        for(uint256 i =0; i<numberOfTokens;i++){
            if(tokenAddress == tokenList[i]){
                return true;
            }
        }
        return false;
    }

    /**
    * @dev Returns the list of acceptable tokens.
    *
    *  Visibility : Public.  
    *  
    *  Return Type : address array.
    */
    function getListOfTokens() public view returns(address [] memory) {
        address[] memory tokenList = new address[] (numberOfTokens);
        for (uint256 i=0; i<numberOfTokens;i++){
            tokenList[i] = acceptableTokens[i];
        }
        return tokenList;
    }
    
    /**
    * @dev Sends all contract's reward tokens to the caller.
    *
    *  Visibility : Public.  
    *  
    *  Requirments : 
    *        - Caller is the contract owner.
    *        - The remaining reward balance is greater than 0.
    */
    function withrdawRewardsToken() public onlyOwner{
        uint256 remainingBalance = IERC20(rewardToken).balanceOf(address(this));
        require(remainingBalance>0,"Remaining balance needs to be greater than 0");
        IERC20(rewardToken).transfer(msg.sender,remainingBalance);
    }
    
    /**
    * @dev Sends all staked amount back to the users.
    *
    *  Visibility : Public.  
    *  
    *  Requirments : 
    *        - Caller is the contract owner.
    */
    function returnAllUserFunds() public onlyOwner{
        address[] memory tokenList = getListOfTokens();
        for(uint256 i=0;i<numerOfUsers;i++){
            for(uint256 x=0;x<numberOfTokens;x++){
                uint256 stakedAmount = users[listOfUsers[i]].amountPerToken[tokenList[x]];
                if(stakedAmount>0){
                    users[listOfUsers[i]].amountPerToken[tokenList[x]] = 0;
                    stakedAmountPerToken[tokenList[x]] = stakedAmountPerToken[tokenList[x]].sub(stakedAmount); 
                    IERC20(tokenList[x]).transfer(listOfUsers[i],stakedAmount);
                }
            }
            
        }
    }
}