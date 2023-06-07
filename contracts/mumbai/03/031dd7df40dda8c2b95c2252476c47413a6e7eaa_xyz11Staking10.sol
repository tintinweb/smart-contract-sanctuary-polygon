/**
 *Submitted for verification at polygonscan.com on 2023-06-07
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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

pragma solidity ^0.8.0;

contract xyz11Staking10 is Ownable {

    bool public paused = false;

    ERC20 public _xyzToken; //Xyz Token
    ERC20 public _usdToken; //Usd Token

    uint256 totalWithdraw = 0 ;
    uint256 totalInvestment = 0 ;

    address[] public allUsers;

    //Referral//

    struct Referral {
        bool referred;
        address referred_by;
        address[] referrals;
        uint256[] startTime;
        uint256[] usdAmount;
        uint256[] stakingAmount;
        uint256[] stakingRate;
        uint256[] expiryDays;
        uint256[] transactionStatus; //0-Pending, 1-Approved, 2-Disapproved
        bool[] stakingStatus;
        uint256[] withdrawal;
    }

    struct ReferralRewards {
        address temp;
        address[] _addr;
        uint256[] _rewards;
    }

    mapping(address => Referral) public user_info;

    mapping(address => ReferralRewards) public rewards_info;

    constructor(ERC20 xyzToken,ERC20 usdToken) {
        _xyzToken = xyzToken;
        _usdToken = usdToken;
    }

    function stakeTokens(address ref_add,uint _usdAmount,uint _tokenAmount) public {
        require(!paused, "The contract is paused");
        require(_usdAmount > 0, "You cannot stake zero tokens");
        require(_usdToken.balanceOf(msg.sender) >= _usdAmount, "Insufficient Balance");
        addUser(msg.sender);
        addReferral(msg.sender, ref_add);
        user_info[msg.sender].startTime.push(block.timestamp);
        user_info[msg.sender].usdAmount.push(_usdAmount);
        user_info[msg.sender].stakingAmount.push(_tokenAmount);
        user_info[msg.sender].transactionStatus.push(0);
        user_info[msg.sender].withdrawal.push(0);
        user_info[msg.sender].stakingStatus.push(false);
        if(_usdAmount == 100 ether){
            user_info[msg.sender].stakingRate.push(8);
            user_info[msg.sender].expiryDays.push(135);
        } else if(_usdAmount == 250 ether){
            user_info[msg.sender].stakingRate.push(9);
            user_info[msg.sender].expiryDays.push(120);
        } else if(_usdAmount == 500 ether){
            user_info[msg.sender].stakingRate.push(10);
            user_info[msg.sender].expiryDays.push(110);
        } else if(_usdAmount == 1000 ether){
            user_info[msg.sender].stakingRate.push(11);
            user_info[msg.sender].expiryDays.push(100);
        } else if(_usdAmount == 2500 ether){
            user_info[msg.sender].stakingRate.push(12);
            user_info[msg.sender].expiryDays.push(90);
        } else {
            require(false, "Enter Valid Amount");
        }
        _usdToken.transferFrom(msg.sender,address(this), _usdAmount);
    }

    function approveTransaction(address _user, uint256 _pos, bool _status) public onlyOwner {
        if(user_info[_user].transactionStatus[_pos] != 1){
            if (_status){
                uint _tokenAmount = user_info[_user].stakingAmount[_pos];
                totalInvestment += _tokenAmount;
                distributeReferralReward(_user, _tokenAmount);
                user_info[_user].startTime[_pos] = block.timestamp;
                user_info[_user].transactionStatus[_pos] = 1;
                user_info[_user].stakingStatus[_pos] = true;
            } else {
                uint _tokenAmount = 0;
                totalInvestment += _tokenAmount;
                distributeReferralReward(_user, _tokenAmount);
                user_info[_user].startTime[_pos] = block.timestamp;
                user_info[_user].transactionStatus[_pos] = 2;
                user_info[_user].stakingStatus[_pos] = false;
            }
        }
    }

    function withdrawTokens(uint256 _pos) public {
        require(!paused, "The contract is paused");
        require(user_info[msg.sender].transactionStatus[_pos] == 1, "Transaction is not approved");
        require(user_info[msg.sender].stakingStatus[_pos], "Staking Off");
        uint256 _amount = calculateYieldTotal(msg.sender,_pos);
        user_info[msg.sender].withdrawal[_pos] = _amount;
        totalWithdraw += _amount;
        user_info[msg.sender].stakingStatus[_pos] = false;
        require(_xyzToken.balanceOf(address(this)) >= _amount, "Limit Exceeded");
        _xyzToken.transfer(msg.sender, _amount);
    }

    function withdrawRewards() public {
        require(!paused, "The contract is paused");
        uint256 _amount = getRefReward();
        setRefReward();
        require(_xyzToken.balanceOf(address(this)) >= _amount, "Limit Exceeded");
        _xyzToken.transfer(msg.sender, _amount);
    }

    function addReferral(address _user, address ref_add) internal {

        if (ref_add != address(0) && !user_info[_user].referred && ref_add != _user && !checkCircularReferral(_user, ref_add)) {
            user_info[_user].referred_by = ref_add;
            user_info[_user].referred = true;
            user_info[ref_add].referrals.push(_user);
        }
 
    }

    function getAllReferrals(address _addr) public view returns (address[] memory ){
        return user_info[_addr].referrals;
    }

    function getReferral() public view returns (address ){
        return user_info[msg.sender].referred_by;
    }

    function checkCircularReferral(address _user, address ref_add) public view returns (bool) {
        address parent = ref_add;
        for (uint i=0; i < 1; i++) {
            if (parent == address(0)) {
                break;
            }
            if(parent == _user){
                return true;
            }
            parent = user_info[parent].referred_by;
        }
        return false;
    }

    function checkReferralReward(address _user,address _user2) internal view returns(uint256) {
        for (uint i=1; i <= rewards_info[_user2]._addr.length; i++) {
            if(rewards_info[_user2]._addr[i-1] == _user){
                return i;
            }
        }
        return 0;
    }

    function getRefReward() public view returns(uint256){
        uint256 total = 0;
        address[] memory allRef = getAllReferrals(msg.sender);
        for (uint j=0; j < allRef.length; j++) {
            address _user = allRef[j];
            total += getParticularRefReward(_user);
            address[] memory allSubRef = getAllReferrals(_user);
            for (uint k=0; k < allSubRef.length; k++) {
                address _subUser = allSubRef[k];
                total += getParticularRefReward(_subUser);
            }   
        }
        return total;
    }

    function setRefReward() internal {
        address[] memory allRef = getAllReferrals(msg.sender);
        for (uint j=0; j < allRef.length; j++) {
            address _user = allRef[j];
            setParticularRefReward(_user);
            address[] memory allSubRef = getAllReferrals(_user);
            for (uint k=0; k < allSubRef.length; k++) {
                address _subUser = allSubRef[k];
                setParticularRefReward(_subUser);
            }   
        }
    }

    function getParticularRefReward(address _user) internal view returns(uint256){
        for (uint i=0; i < rewards_info[_user]._addr.length; i++) {
            if(rewards_info[_user]._addr[i] == msg.sender){
                return rewards_info[_user]._rewards[i];
            }
        }
        return 0;
    }

    function setParticularRefReward(address _user) internal {
        for (uint i=0; i < rewards_info[_user]._addr.length; i++) {
            if(rewards_info[_user]._addr[i] == msg.sender){
                rewards_info[_user]._rewards[i] = 0;
            }
        }
    }

    function distributeReferralReward(address _user, uint256 _amount) internal {
        address level1 = user_info[_user].referred_by;
        address level2 = user_info[level1].referred_by;

        if ((level1 != _user) && (level1 != address(0))) {
            if(checkReferralReward(level1,_user) == 0){
                rewards_info[_user]._addr.push(level1);
                rewards_info[_user]._rewards.push(_amount*7/100);
            }else{
                rewards_info[_user]._rewards[checkReferralReward(level1,_user)-1] += _amount*7/100;
            }
        }
        if ((level2 != _user) && (level2 != address(0))) {
            if(checkReferralReward(level2,_user) == 0){
                rewards_info[_user]._addr.push(level2);
                rewards_info[_user]._rewards.push(_amount*3/100);
            }else{
                rewards_info[_user]._rewards[checkReferralReward(level2,_user)-1] += _amount*3/100;
            }
        }
    }

    function addUser(address _user) internal {
        if(!checkUser(_user)){
            allUsers.push(_user);
        }
    }

    function checkUser(address _user) public view returns (bool) {
        for (uint256 i = 0; i < allUsers.length; i++) {
            if (allUsers[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getWithdrawableAmount(uint256 _pos) public view returns(uint256) {
        uint256 _amount = calculateYieldTotal(msg.sender,_pos);
        return _amount;
    }

    function getTotalInvestment() public view returns(uint256) {
        return totalInvestment;
    }

    function getTotalWithdraw() public view returns(uint256) {
        return totalWithdraw;
    }

    function getAllUsersLength() public view returns(uint256) {
        return allUsers.length;
    }

    function getAllUsers() public view returns (address[] memory ){
        return allUsers;
    }

    function getAllStartTime(address _addr) public view returns (uint256[] memory ){
        return user_info[_addr].startTime;
    }

    function getAllUsdAmount(address _addr) public view returns (uint256[] memory ){
        return user_info[_addr].usdAmount;
    }

    function getAllStakingAmount(address _addr) public view returns (uint256[] memory ){
        return user_info[_addr].stakingAmount;
    }

    function getAllTransactionStatus(address _addr) public view returns (uint256[] memory ){
        return user_info[_addr].transactionStatus;
    }

    function getAllStakingStatus(address _addr) public view returns (bool[] memory ){
        return user_info[_addr].stakingStatus;
    }

    function getAllWithdrawal(address _addr) public view returns (uint256[] memory ){
        return user_info[_addr].withdrawal;
    }

    function getUsdBalance() public view returns(uint256) {
        return _usdToken.balanceOf(address(this));
    }

    function getCoinBalance() public view returns(uint256) {
        return _xyzToken.balanceOf(address(this));
    }

    function calculateYieldTime(address user,uint256 i) public view returns(uint256){
        if(user_info[user].transactionStatus[i] == 1 && user_info[user].stakingStatus[i]) {
            if(user_info[user].startTime[i] > 0) {
                uint256 end = block.timestamp;
                uint256 totalTime = end - user_info[user].startTime[i];
                uint256 maxTime = user_info[user].expiryDays[i] * 86400;
                if (totalTime <= maxTime) {
                    return totalTime;
                } else {
                    return maxTime;
                }
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }

    function calculateYieldTotal(address user, uint256 _pos) public view returns(uint256) {
        //Hourly
        if(user_info[user].transactionStatus[_pos] == 1 && user_info[user].stakingStatus[_pos]){
            uint256 time = calculateYieldTime(user,_pos) / 3600;
            uint256 _percentage = user_info[user].stakingRate[_pos];
            uint256 totalAmount = user_info[user].stakingAmount[_pos] + ((user_info[user].stakingAmount[_pos] * time * _percentage) / 24000);
            return totalAmount;
        } else {
            return 0;
        }
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdrawTokens(uint256 _isType, uint256 _amount) public onlyOwner {
        if (_isType == 0){
            require(_amount <= _usdToken.balanceOf(address(this)), "You can not withdraw more than contract balance");
            _usdToken.transferFrom(address(this), owner(), _amount);
        } else if (_isType == 1){
            require(_amount <= _xyzToken.balanceOf(address(this)), "You can not withdraw more than contract balance");
            _xyzToken.transfer(owner(), _amount);
        } else {
            require(_amount <= address(this).balance,"You can not withdraw more than contract balance");
            payable(owner()).transfer(_amount);
        }
    }

}