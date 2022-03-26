//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
* @title Petto Staking
*/
contract PettoStaking  is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Stake{
        uint256 deposit_amount;    //Deposited Amount
        uint256 stake_creation_time;    //The time when the stake was created
        bool returned;    //Specifies if the funds were withdrawed
        uint256 alreadyWithdrawedAmount;    //already withdrawed amount
    }

    //---------------------------------------------------------------------
    //-------------------------- EVENTS -----------------------------------
    //---------------------------------------------------------------------

    /**
    * @notice Emitted when the pot value changes
    */
    event PotUpdated(
        uint256 newPot
    );

    /**
    * @notice Emitted when a new stake is issued
    */
    event NewStake(
        uint256 stakeAmount
    );

    /**
    * @notice Emitted when a new stake is withdrawed
    */
    event StakeWithdraw(
        uint256 stakeID,
        uint256 amount
    );
    
    /**
    *  @notice Emitted when a reward is withdrawed
    */
    event rewardWithdrawed(
        address account
    );

    /**
    *  @notice Emitted when the subscription is stopped
    */
    event subscriptionStopped(
    );

    //--------------------------------------------------------------------
    //-------------------------- GLOBALS -----------------------------------
    //--------------------------------------------------------------------

    mapping (address => Stake[]) private stake; // Map that contains account's stakes

    ERC20 private pettoToken;

    uint256 private pot; //The pot where token are taken

    uint256 private amount_supplied; //Store the remaining token to be supplied

    address[] private activeAccounts; //Store stakers

    uint256 private constant _DECIMALS = 18;

    uint256 private constant _INTEREST_PERIOD = 1 days; //One day
    uint256 private constant _INTEREST_VALUE = 1000; //1% per day

    uint256 private constant _MAX_TOKEN_SUPPLY_LIMIT = 145000000 * (10**_DECIMALS);


    /**
    * @notice The constructor for the Petto Staking.
    * @param _tokenAddress The address to receive all tokens on construction.
    */
    constructor(address _tokenAddress){
        pot = 0;
        amount_supplied = _MAX_TOKEN_SUPPLY_LIMIT; //The total amount of token released
        pettoToken = ERC20(_tokenAddress);
    }

    //--------------------------------------------------------------------
    //-------------------------- ONLY OWNER -----------------------------------
    //--------------------------------------------------------------------

    /**
    * @notice Add token to the pot
    * @param _amount The token amount that will be added to the pot
    * @return bool return true if deposit successfully
    */
    function depositPot(uint256 _amount) external onlyOwner nonReentrant returns (bool){
        pot = pot.add(_amount);

        if(pettoToken.transferFrom(msg.sender, address(this), _amount)){
            //Emit the event to update the UI
            emit PotUpdated(pot);
        }else{
            revert("Unable to tranfer funds");
        }
        return true;
    }

    /**
    * @notice withraw token from the pot
    * @param _amount The token amount that will be withrawed from the pot
    * @return bool return true if return successfully
    */
    function returnPot(uint256 _amount) external onlyOwner nonReentrant returns (bool){
        require(pot.sub(_amount) >= 0, "Not enough token");

        pot = pot.sub(_amount);

        if(pettoToken.transfer(msg.sender, _amount)){
            //Emit the event to update the UI
            emit PotUpdated(pot);
        }else{
            revert("Unable to tranfer funds");
        }
        return true;
    }

    /**
    * @notice Get all accounts
    * @return address[] list of accounts
    */
    function getAllAccount() external onlyOwner view returns (address[] memory){
        return activeAccounts;
    }

    /**
    * @notice Check if the pot has enough balance to satisfy the potential withdraw
    * @return uint256 amount that available to withdraw
    */
    function getPotentialWithdrawAmount() external onlyOwner view returns (uint256){
        uint256 accountNumber = activeAccounts.length;

        uint256 potentialAmount = 0;

        for(uint256 i = 0; i<accountNumber; i++){

            address currentAccount = activeAccounts[i];
            potentialAmount = potentialAmount.add(calculateTotalRewardToWithdraw(currentAccount));
        }

        return potentialAmount;
    }

    //--------------------------------------------------------------------
    //-------------------------- CLIENTS -----------------------------------
    //--------------------------------------------------------------------

    /**
    * @notice Stake token verifying all the contraint
    * @param _amount Amount to stake
    * @return bool return true if stake successfully
    */
    function stakeToken(uint256 _amount) external nonReentrant returns (bool){

        require(!isSubscriptionEnded(), "Subscription ended");

        address staker = msg.sender;
        Stake memory newStake;

        newStake.deposit_amount = _amount;
        newStake.returned = false;
        newStake.stake_creation_time = block.timestamp;
        newStake.alreadyWithdrawedAmount = 0;

        stake[staker].push(newStake);

        activeAccounts.push(msg.sender);

        if(pettoToken.transferFrom(msg.sender, address(this), _amount)){
            emit NewStake(_amount);
        }else{
            revert("Unable to transfer funds");
        }
        return true;
    }

    /**
    * @notice Return the staked tokens, requiring that the stake was not already withdrawed
    * @param _stakeID The ID of the stake to be returned
    * @return bool return true if return successfully
    */
    function returnTokens(uint256 _stakeID) external nonReentrant returns (bool){
        Stake memory selectedStake = stake[msg.sender][_stakeID];

        //Check if the stake were already withdraw
        require(selectedStake.returned == false, "Stake were already returned");

        uint256 deposited_amount = selectedStake.deposit_amount;

        //Only set the withdraw flag in order to disable further withdraw
        stake[msg.sender][_stakeID].returned = true;

        if(pettoToken.transfer(msg.sender, deposited_amount)){
            emit StakeWithdraw(_stakeID, deposited_amount);
        }else{
            revert("Unable to transfer funds");
        }
        return true;
    }

    /**
    * @notice withdraw reward from stake and update the pot value
    * @param _stakeID The ID of the stake to be withdraw
    * @return bool return true if withdraw successfully
    */
    function withdrawReward(uint256 _stakeID) external nonReentrant returns (bool){
        Stake memory _stake = stake[msg.sender][_stakeID];

        uint256 rewardToWithdraw = calculateRewardToWithdraw(_stakeID);

        require(updateSuppliedToken(rewardToWithdraw), "Supplied limit reached");

        if(rewardToWithdraw > pot){
            revert("Pot exhausted");
        }

        pot = pot.sub(rewardToWithdraw);

        stake[msg.sender][_stakeID].alreadyWithdrawedAmount = _stake.alreadyWithdrawedAmount.add(rewardToWithdraw);

        if(pettoToken.transfer(msg.sender, rewardToWithdraw)){
            emit rewardWithdrawed(msg.sender);
        }else{
            revert("Unable to transfer funds");
        }
        return true;
    }

    //--------------------------------------------------------------------
    //-------------------------- VIEWS -----------------------------------
    //--------------------------------------------------------------------

    /**
    * @notice Return the amount of token in the provided caller's stake
    * @param _stakeID The ID of the stake of the caller
    * @return uint256 deposit amount of the stake
    */
    function getCurrentStakeAmount(uint256 _stakeID) external view returns (uint256)  {
        return stake[msg.sender][_stakeID].deposit_amount;
    }

    /**
    * @notice Return sum of all the caller's stake amount
    * @return uint256 Amount of stake
    */
    function getTotalStakeAmount() external view returns (uint256) {
        Stake[] memory currentStake = stake[msg.sender];
        uint256 nummberOfStake = stake[msg.sender].length;
        uint256 totalStake = 0;
        uint256 tmp;
        for (uint256 i = 0; i<nummberOfStake; i++){
            tmp = currentStake[i].deposit_amount;
            totalStake = totalStake.add(tmp);
        }
        return totalStake;
    }

    /**
    * @notice Return all the available stake info
    * @param _stakeID ID of the stake which info is returned
    * @return uint256 1) Amount Deposited
    * @return bool 2) Bool value that tells if the stake was returned
    * @return uint256 3) Stake creation time (Unix timestamp)
    * @return uint256 4) The current reward amount
    */
    function getStakeInfo(uint256 _stakeID) external view returns(uint256, bool, uint256, uint256){

        Stake memory selectedStake = stake[msg.sender][_stakeID];

        uint256 amountToWithdraw = calculateRewardToWithdraw(_stakeID);

        return (
            selectedStake.deposit_amount,
            selectedStake.returned,
            selectedStake.stake_creation_time,
            amountToWithdraw
        );
    }


    /**
    * @notice Get the current pot value
    * @return uint256 The amount of token in the current pot
    */
    function getCurrentPot() external view returns (uint256){
        return pot;
    }

    /**
    * @notice Get the number of stake of the caller
    * @return uint256 Number of active stake
    */
    function getStakeCount() external view returns (uint256){
        return stake[msg.sender].length;
    }

    /**
    * @notice Get the number of active stake of the caller
    * @return uint256 Number of active stake
    */
    function getActiveStakeCount() external view returns(uint256){
        uint256 stakeCount = stake[msg.sender].length;

        uint256 count = 0;

        for(uint256 i = 0; i<stakeCount; i++){
            if(!stake[msg.sender][i].returned){
                count = count + 1;
            }
        }
        return count;
    }

    /**
    * @notice Get already withdrawed amount of stake of the caller
    * @return uint256 already withdrawed amount of stake of the caller
    */
    function getAlreadyWithdrawedAmount(uint256 _stakeID) external view returns (uint256){
        return stake[msg.sender][_stakeID].alreadyWithdrawedAmount;
    }

    /**
    * @notice Get remainning amount supplied of the contract
    * @return uint256 remainning amount supplied of the contract
    */
    function getContractState() external view returns (uint256){
        return amount_supplied;
    }

    /**
    * @notice Get Subscription status
    * @return bool true if amount supplied > 0 otherwise return false
    */
    function isSubscriptionEnded() public view returns (bool){
        if(amount_supplied > 0){
            return false;
        }else{
            return true;
        }
    }

    //--------------------------------------------------------------------
    //-------------------------- INTERNAL -----------------------------------
    //--------------------------------------------------------------------

    /**
    * @notice Calculate the customer reward based on the provided stake
    * @param _stakeID The stake ID where the reward should be calculated
    * @return uint256 The reward value
    */
    function calculateRewardToWithdraw(uint256 _stakeID) public view returns (uint256){
        Stake memory _stake = stake[msg.sender][_stakeID];

        uint256 amount_staked = _stake.deposit_amount;
        uint256 already_withdrawed = _stake.alreadyWithdrawedAmount;

        uint256 periods = calculatePeriods(_stakeID);  //Periods for interest calculation

        uint256 interest = amount_staked.mul(_INTEREST_VALUE);

        uint256 total_interest = interest.mul(periods).div(100000);

        uint256 reward = total_interest.sub(already_withdrawed); //Subtract the already withdrawed amount

        return reward;
    }

    /**
    * @notice Calculate the customer reward based on the provided stake and customer address
    * @param _account stake owner
    * @param _stakeID The stake ID where the reward should be withdrawed
    * @return uint256 amount of reward to withdraw
    */
    function calculateRewardToWithdraw(address _account, uint256 _stakeID) internal view onlyOwner returns (uint256){
        Stake memory _stake = stake[_account][_stakeID];

        uint256 amount_staked = _stake.deposit_amount;
        uint256 already_withdrawed = _stake.alreadyWithdrawedAmount;

        uint256 periods = calculateAccountStakePeriods(_account, _stakeID);  //Periods for interest calculation

        uint256 interest = amount_staked.mul(_INTEREST_VALUE);

        uint256 total_interest = interest.mul(periods).div(100000);

        uint256 reward = total_interest.sub(already_withdrawed); //Subtract the already withdrawed amount

        return reward;
    }

    /**
    * @notice Calculate total customer reward based on customer address
    * @param _account stake owner
    * @return uint256 amount of reward to withdraw
    */
    function calculateTotalRewardToWithdraw(address _account) internal view onlyOwner returns (uint256){
        Stake[] memory accountStakes = stake[_account];

        uint256 stakeNumber = accountStakes.length;
        uint256 amount = 0;

        for( uint256 i = 0; i<stakeNumber; i++){
            amount = amount.add(calculateRewardToWithdraw(_account, i));
        }

        return amount;
    }

    /**
    * @notice Calculate the customer reward and deposit amount based on the provided stake
    * @param _stakeID The stake ID where the reward should be withdrawed
    * @return uint256 amount of reward and deposit to withdraw
    */
    function calculateCompoundInterest(uint256 _stakeID) external view returns (uint256){

        Stake memory _stake = stake[msg.sender][_stakeID];

        uint256 periods = calculatePeriods(_stakeID);
        uint256 amount_staked = _stake.deposit_amount;

        uint256 excepted_amount = amount_staked;

        //Calculate reward
        for(uint256 i = 0; i < periods; i++){

            uint256 period_interest;

            period_interest = excepted_amount.mul(_INTEREST_VALUE).div(100);

            excepted_amount = excepted_amount.add(period_interest);
        }

        assert(excepted_amount >= amount_staked);

        return excepted_amount;
    }

    /**
    * @notice get total periods of a stake
    * @param _stakeID The stake ID where the reward should be withdrawed
    * @return uint256 periods count
    */
    function calculatePeriods(uint256 _stakeID) public view returns (uint256){
        Stake memory _stake = stake[msg.sender][_stakeID];


        uint256 creation_time = _stake.stake_creation_time;
        uint256 current_time = block.timestamp;

        uint256 total_period = current_time.sub(creation_time);

        uint256 periods = total_period.div(_INTEREST_PERIOD);

        return periods;
    }

    /**
    * @notice Calculate the periods the provided stake and customer address
    * @param _account stake owner
    * @param _stakeID The stake ID where the reward should be withdrawed
    * @return uint256 periods count
    */
    function calculateAccountStakePeriods(address _account, uint256 _stakeID) public view onlyOwner returns (uint256){
        Stake memory _stake = stake[_account][_stakeID];


        uint256 creation_time = _stake.stake_creation_time;
        uint256 current_time = block.timestamp;

        uint256 total_period = current_time.sub(creation_time);

        uint256 periods = total_period.div(_INTEREST_PERIOD);

        return periods;
    }

    /**
    * @notice Update supplier amount after reward withdrawed
    * @param _amount The amount should be withdrawed
    * @return uint256 return false if the amount is greater than amount supplied otherwise return true
    */
    function updateSuppliedToken(uint256 _amount) internal returns (bool){
        
        if(_amount > amount_supplied){
            return false;
        }
        
        amount_supplied = amount_supplied.sub(_amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
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