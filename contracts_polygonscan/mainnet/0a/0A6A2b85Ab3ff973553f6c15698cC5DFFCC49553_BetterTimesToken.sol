// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../node_modules/openzeppelin-contracts/token/ERC20/ERC20.sol";
import "../node_modules/openzeppelin-contracts/access/Ownable.sol";
import "./SacredCoin.sol";
import "./SacredStakeable.sol";

contract BetterTimesToken is ERC20, Ownable, SacredCoin, SacredStakeable {

    constructor() ERC20("Better Times Token", "UPNUP") {

        /**
        * @dev minting 679 million coins, an estimate of how much people are living in poverty at the moment of
        * the coin creation
        */
        _mint(msg.sender, 1000000 * 10 ** decimals());

        /**
        * @dev calling the setGuideline function to create 2 guidelines:
        */

        setGuideline("Help to remove poverty", "Every time you share or stake the coin, think of ways in which you can help to remove poverty in the world, and whenever possible act on those thoughts. It can be something at the level of your family, your community, your city, up to the whole world.");
        setGuideline("Share the coin with those in need", "Perhaps one of the best ways to potentially remove poverty is to share the Easier Times Token with those who find themselves fallen on hard times. That way, a high demand of the coin can become synonymous with reducing poverty in the world, since whoever has these coins will have their finances improving.");
    }

    mapping (address => bool) public WhitelistedToCallSacredMessages;


    event SacredEvent(string BetterTimesMessage);

    function SacredMessageOne(string memory yourDeeds) private {
        emit SacredEvent(string(abi.encodePacked("Lately, I helped to remove poverty from the world by ", yourDeeds)));
    }

    function SacredMessageTwo(string memory name, string memory story) private {
        emit SacredEvent(string(abi.encodePacked(name, "'s challenging times story is ", story)));
    }

    function transferSacredOne(address to, uint tokens, string memory yourDeeds) public {
        super.transfer(to, tokens);
        SacredMessageOne(yourDeeds);
    }

    function transferSacredTwo(address to, uint tokens, string memory name, string memory story) public {
        super.transfer(to, tokens);
        SacredMessageTwo(name, story);
    }

    function approveSacredOne(address spender, uint256 amount, string memory yourDeeds) public {
        super.approve(spender, amount);
        SacredMessageOne(yourDeeds);
    }

    function approveSacredTwo(address spender, uint256 amount, string memory name, string memory story) public {
        super.approve(spender, amount);
        SacredMessageTwo(name, story);
    }

    function transferFromSacredOne(address sender, address recipient, uint256 amount, string memory yourDeeds) public {
        super.transferFrom(sender, recipient, amount);
        SacredMessageOne(yourDeeds);
    }

    function transferFromSacredTwo(
        address sender,
        address recipient,
        uint256 amount,
        string memory name,
        string memory story
    ) public {
        super.transferFrom(sender, recipient, amount);
        SacredMessageTwo(name, story);
    }

    /**
    * Add functionality like burn to the _stake afunction
    *
    */
    function stake(uint256 _amount, uint8 timeframe) internal {
        // Make sure staker actually is good for it
        require(_amount <= balanceOf(msg.sender), "BetterTimesToken: Cannot stake more than you own");
        require(totalSupply() <= 679000000000000000000000000, "BetterTimesToken: supply has reached 679 million");

        _stake(_amount, timeframe);
        // Burn the amount of tokens on the sender
        _burn(msg.sender, _amount);
    }

    function stakeOne(uint256 _amount, string memory yourDeeds, uint8 timeframe) public {
        stake(_amount, timeframe);
        SacredMessageOne(yourDeeds);
    }

    function stakeTwo(uint256 _amount, string memory name, string memory story, uint8 timeframe) public {
        stake(_amount, timeframe);
        SacredMessageTwo(name, story);
    }

    /**
    * @notice withdrawStake is used to withdraw stakes from the account holder
     */
    function withdrawStake()  public {

        uint256 amount_to_mint = _withdrawStake();
        // Return staked tokens to user
        _mint(msg.sender, amount_to_mint);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../GSN/Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
* @notice SacredStakeable is a contract meant to be inherited by other Sacred Coins
* adapted from https://github.com/percybolmer/DevToken/tree/stakeable (MIT Licensed)
*/
contract SacredStakeable {

    /**
    * @notice Constructor since this contract is not meant to be used without inheritance
    * push once to stakeholders for it to work properly
     */
    constructor() {
        // This push is needed so we avoid index 0 causing bug of index-1
        stakeholders.push();
    }
    /**
     * @notice
     * A stake struct is used to represent the way we store stakes, 
     * A Stake will contain the users address, the amount staked and a timestamp, 
     * Since which is when the stake was made
     * @notice
     * Customization: Only the Stake struct will be used
     */
    struct Stake{
        address user;
        uint256 amount;
        uint256 since;
        //Customization. This records the rewardPerHour that will determine the rewards
        uint256 rewardPerHour;
        //Customization. This records the choice of staking time: 0=1 week, 1=2 weeks, 2=4 weeks.
        uint256 timeframe;
    }

    /**
    * @notice 
    *   This is a array where we store all Stakes that are performed on the Contract
    *   The stakes for each address are stored at a certain index, the index can be found using the stakes mapping
    */
    Stake[] internal stakeholders;

    /**
    * @notice 
    * stakes is used to keep track of the INDEX for the stakers in the stakeholders array
    */
    mapping(address => uint256) internal stakes;

    /**
    * @notice Staked event is triggered whenever a user stakes tokens, address is indexed to make it filterable
    */
    event Staked(address indexed user, uint256 thisAmount, uint256 entireAmount, uint256 timestamp);

    /**
    * @notice
    *Customization: reward per hour is more the smaller the timeframe:
    *For the month, reward is 0.1%
    *For the two week period, it's 0.14%
    *For a one week period, it's 0.2%
    *So the weekly period offers double the rewards of the monthly period!
    *NOTE: If no compounding is done during this period, either by staking more coins or by removing the stake,
    *then the reward is lost! (see documentation)
    */
    uint256 internal rewardPerHourWeek = 500;
    uint256 internal rewardPerHourTwoWeeks = 625;
    uint256 internal rewardPerHourMonth = 1000;

    /**
    * @notice _addStakeholder takes care of adding a stakeholder to the stakeholders array
     */
    function _addStakeholder(address staker) internal returns (uint256){
        // Push a empty item to the Array to make space for our new stakeholder
        stakeholders.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 userIndex = stakeholders.length - 1;
        // Assign the address to the new index
        stakeholders[userIndex].user = staker;
        // Add index to the stakeHolders
        stakes[staker] = userIndex;
        return userIndex;
    }

    /**
    * @notice
    * _Stake is used to make a stake for an sender. It will remove the amount staked from the stakers account and place those tokens inside a stake container
    * StakeID 
    */
    function _stake(uint256 _amount, uint256 timeframe) internal{
        // Simple check so that user does not stake 0 
        require(_amount > 0, "Cannot stake nothing");

        //check that the right value was entered for timeframe
        require(timeframe == 0 || timeframe == 1 || timeframe == 2, "timeframe value not valid");

        // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 index = stakes[msg.sender];

        // See if the staker already has a staked index or if its the first time
        if(index == 0){
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            index = _addStakeholder(msg.sender);
            stakeholders[index].amount = _amount;
        }
        else {
            //calculating the original amount plus the rewards:
            uint256 originalAmount = calculateStakeReward(stakeholders[index]) + stakeholders[index].amount;

            //adding the original amount plus the newly staked amount to the stakeholders array:
            stakeholders[index].amount=_amount + originalAmount;
        }

        // block.timestamp = timestamp of the current block in seconds since the epoch
        uint256 timestamp = block.timestamp;
        //adding the block.timestamp value to the Stake struct
        stakeholders[index].since = timestamp;

        // Emit an event that the stake has occurred
        emit Staked(msg.sender, _amount, stakeholders[index].amount, timestamp);

        //Modification: set the timeframe and the reward per hour based the timeframe variable:
        if(timeframe==0) {
        stakeholders[index].timeframe = 1 weeks;
        stakeholders[index].rewardPerHour = rewardPerHourWeek;
        }
        else if(timeframe==1) {
            stakeholders[index].timeframe = 2 weeks;
            stakeholders[index].rewardPerHour = rewardPerHourTwoWeeks;
        }
        else if(timeframe==2) {
            stakeholders[index].timeframe = 4 weeks;
            stakeholders[index].rewardPerHour = rewardPerHourMonth;
        }
    }

    /**
      * @notice
      * calculateStakeReward is used to calculate how much a user should be rewarded for their stakes
      * and the duration the stake has been active
     */
    function calculateStakeReward(Stake memory _current_stake) internal view returns(uint256){
        // First calculate how long the stake has been active
        // Use current seconds since epoch - the seconds since epoch the stake was made
        // The output will be duration in SECONDS ,
        // We will reward the user 0.1% per Hour So that's 0.1% per 3600 seconds
        // the algorithm is  seconds = block.timestamp - stake seconds (block.timestamp - _stake.since)
        // hours = Seconds / 3600 (seconds /3600) 3600 is an variable in Solidity names hours
        // we then multiply each token by the hours staked , then divide by the rewardPerHour rate
        //Modification: if block.timestamp is after the staking timeframe, then the user does not receive reward:
        if(block.timestamp > _current_stake.since + _current_stake.timeframe) {
            return 0;
        }
        else {
            return (((block.timestamp - _current_stake.since) / 1 hours)
            * _current_stake.amount) / _current_stake.rewardPerHour;
        }
    }

    /**
     * @notice
     * Customization:
     * function to remove the stake and the stakeholder when the _withdrawStake function is called:
    */
    function removeStakeholder(uint index) private {
        delete stakes[msg.sender];
        delete stakeholders[index];
    }


    /**
     * @notice
     * Customization
     * _withdrawStake withdraws the entire stake to the owner's account:
    */
    function _withdrawStake() internal returns(uint256){

        // Grab user_index which is the index to use to grab the Stake[]
        uint256 user_index = stakes[msg.sender];
        require(user_index!=0,"you do not have any coins staked");
        require(stakeholders[user_index].since+3 days<block.timestamp,
            "you have to wait a minimum of 3 days before you can withdraw a stake");

        uint256 currentAmount = stakeholders[user_index].amount;

        // Calculate available Reward first before we start modifying data
        uint256 reward = calculateStakeReward(stakeholders[user_index]);

        removeStakeholder(user_index);
        return currentAmount+reward;
    }


    /**
    * @notice
     * hasStake is used to check if a account has stakes and the total amount along with all the separate stakes
     */
    function hasStake(address _staker) public view returns(
        bool isStaking,
        uint256 stakedAmount,
        uint256 claimableReward,
        uint256 totalAmount,
        uint256 StakingDeadlineInSeconds,
        uint256 StakingUnlockInSeconds
    )

    {
        uint256 user_index = stakes[_staker];

        if (user_index==0) {
            isStaking = false;
            stakedAmount=0;
            claimableReward=0;
            totalAmount=0;
            StakingDeadlineInSeconds=0;
            StakingUnlockInSeconds=0;
        } else {
            isStaking=true;
            stakedAmount = stakeholders[user_index].amount;
            claimableReward = calculateStakeReward(stakeholders[user_index]);
            totalAmount= stakedAmount+ claimableReward;
            StakingDeadlineInSeconds = stakeholders[user_index].since + stakeholders[user_index].timeframe;
            StakingUnlockInSeconds = stakeholders[user_index].since + 3 days;
        }
        return (isStaking, stakedAmount, claimableReward, totalAmount, StakingDeadlineInSeconds, StakingUnlockInSeconds);
    }
}

// SPDX-License-Identifier: MIT
// Sacred Coin Protocol v0.1.0

pragma solidity ^0.8.9;

/**
 * @title Sacred Coin Protocol v0.1.0
 *
 * @dev A protocol to build an ERC20 token that allows for the creation of guidelines,
 * or recommendations on how to use the coin that are intended for the those who interact with it.
 *
 * Works in conjunction with an ERC20 implementation, such as the OpenZeppelin ERC20 contract.
 *
 * To understand the philosophy behind it, visit:
 * https://sacredcoinprotocol.com
 *
 * To see examples on how to use this contract go to the GitHub page:
 * https://github.com/tokenosopher/sacred-coin-protocol
 *
 */

contract SacredCoin {

    uint public numberOfGuidelines;

    /**
    * @dev A string that holds all of the guidelines, for easy retrieval.
    */
    string [] private mergedGuidelines;

    /**
    * @dev The Guideline struct. Each guideline wil be stored in one.
    */
    struct Guideline {
        string summary;
        string guideline;
    }

    /**
    * @dev An array of Guideline structs that stores all of the guidelines, for easy retrieval.
    */
    Guideline[] public guidelines;

    /**
    * @dev An event that records the fact that a guideline has been created.
    * Because coin guidelines need to be explicitly stated during the coin creation,
    * this event only gets emitted when the coin is created, one event per guideline.
    */
    event GuidelineCreated(string guidelineSummary, string guideline);

    /**
    * @dev The main function of the contract. Should be called in the constructor function of the coin
    *
    * @param _guidelineSummary A summary of the guideline. The summary can be used as a title for
    * the guideline when it is retrieved and displayed on a front-end.
    *
    * @param _guideline The guideline itself.
    */
    function setGuideline(string memory _guidelineSummary, string memory _guideline) internal {

        /**
        * @dev creating a new struct instance of the type Guideline and storing it in memory.
        */
        Guideline memory guideline = Guideline(_guidelineSummary, _guideline);

        /**
        * @dev pushing the struct created above in the guideline_struct array.
        */
        guidelines.push(guideline);


        /**
        * @dev Emit the GuidelineCreated event.
        */
        emit GuidelineCreated(_guidelineSummary, _guideline);

        /**
        * @dev Increment numberOfGuidelines by one.
        */
        numberOfGuidelines++;
    }

    /**
    * @dev Function that returns a single guideline.
    * The element at location 0 of the array will store the guideline summary.
    * The element at location 1 of the array will store the guideline itself.
    */
    function returnSingleGuideline(uint _index) public view returns(string memory, string memory) {
        return (guidelines[_index].summary, guidelines[_index].guideline);
    }

    /**
    * @dev Function that returns all guidelines.
    * This allows iterating over all guidelines for the purpose of retrieval and/or display.
    */
    function returnAllGuidelines() public view returns(Guideline[] memory) {
        return (guidelines);
    }
}