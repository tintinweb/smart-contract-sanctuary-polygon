// SPDX-License-Identifier: proprietary
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SafeOwn.sol";
import './ISelfkeyIdAuthorization.sol';
import '../ILockdaoStaking.sol';

contract LockToken is IERC20, SafeOwn {

    ILockdaoStaking public stakingContract;
    ISelfkeyIdAuthorization public authorizationContract;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string public constant name = "Lock Token";
    string public constant symbol = "LOCK";
    uint8 public constant decimals = 18;

    event AuthorizationContractChanged(address indexed _authorizationContractAddress);
    event StakingContractChanged(address indexed _stakingContractAddress);

    constructor(address _authorizationContractAddress) SafeOwn(14400) {
        require(_authorizationContractAddress != address(0), "Invalid authorization contract address");
        authorizationContract = ISelfkeyIdAuthorization(_authorizationContractAddress);
    }

    function setAuthorizationContract(address _authorizationContractAddress) public onlyOwner {
        require(_authorizationContractAddress != address(0), "Invalid authorization contract address");
        authorizationContract = ISelfkeyIdAuthorization(_authorizationContractAddress);
        emit AuthorizationContractChanged(_authorizationContractAddress);
    }

    function setStakingContract(address _stakingContractAddress) public onlyOwner {
        require(_stakingContractAddress != address(0), "Invalid staking contract address");
        stakingContract = ILockdaoStaking(_stakingContractAddress);
        emit StakingContractChanged(_stakingContractAddress);
    }

    /**
     * User initiated minting function
     * _param should be a uint indicating the part of the amount
     */
    function mint(address _to, uint256 _amount, bytes32 _param, uint _timestamp, address _signer, bytes memory signature) external {
        authorizationContract.authorize(address(this), _to, _amount, 'mint:lock:staking', _param, _timestamp, _signer, signature);

        uint param = uint(_param);
        require(param >= 0, "Invalid param value");
        require(param <= _amount, "Invalid param value");

        _mint(_to, _amount);
        stakingContract.notifyRewardMinted(_to, param);
    }

    /**
     * User initiated minting function with multi-amount and multi-authorization
     */
    /*
    function multiMint(address _to, uint256 _amount, uint256 _amount2, uint _timestamp, address _signer, bytes memory signature, bytes memory signature2) external {
        authorizationContract.authorize(address(this), _to, _amount, 'mint:lock:staking', _timestamp, _signer, signature);
        authorizationContract.authorize(address(this), _to, _amount2, 'mint:lock:rewards', _timestamp, _signer, signature2);
        _mint(msg.sender, _amount + _amount2);
        stakingContract.notifyRewardMinted(_to, _amount);
    }
    */

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
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
    function approve(address spender, uint256 amount) public override returns (bool) {
        address owner = msg.sender;
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
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        address spender = msg.sender;
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = msg.sender;
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = msg.sender;
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
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
    function _approve(address owner, address spender, uint256 amount) internal {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// @author Razzor https://twitter.com/razzor_tweet
pragma solidity 0.8.9;
     /**
     * @dev Contract defines a 2-step Access Control for the owner of the contract in order
     * to avoid risks. Such as accidentally transferring control to an undesired address or renouncing ownership.
     * The contracts mitigates these risks by using a 2-step process for ownership transfers and a time margin
     * to renounce ownership. The owner can propose the ownership to the new owner, and the pending owner can accept
     * the ownership in order to become the new owner. If an undesired address has been passed accidentally, Owner
     * can propose the ownership again to the new desired address, thus mitigating the risk of losing control immediately.
     * Also, an owner can choose to retain ownership if renounced accidentally prior to future renounce time.
     * The Owner can choose not to have this feature of time margin while renouncing ownership, by initialising _renounceInterval as 0.
     */
abstract contract SafeOwn{
    bool private isRenounced;
    address private _Owner;
    address private _pendingOwner;
    uint256 private _renounceTime;
    uint256 private _renounceInterval;

     /**
     * @dev Emitted when the Ownership is transferred or renounced. AtTime may hold
     * a future time value, if there exists a _renounceInterval > 0 for renounceOwnership transaction.
     */
    event ownershipTransferred(address indexed currentOwner, address indexed newOwner, uint256 indexed AtTime);
     /**
     * @dev Emitted when the Ownership is retained by the current Owner.
     */
    event ownershipRetained(address indexed currentOwner, uint256 indexed At);

     /**
     * @notice Initializes the Deployer as the Owner of the contract.
     * @param renounceInterval time in seconds after which the Owner will be removed.
     */

    constructor(uint256 renounceInterval){
        _Owner = msg.sender;
        _renounceInterval = renounceInterval;
        emit ownershipTransferred(address(0), _Owner, block.timestamp);
    }
     /**
     * @notice Throws if the caller is not the Owner.
     */

    modifier onlyOwner(){
        require(Owner() == msg.sender, "SafeOwn: Caller is the not the Owner");
        _;
    }

     /**
     * @notice Throws if the caller is not the Pending Owner.
     */

    modifier onlyPendingOwner(){
        require(_pendingOwner == msg.sender, "SafeOwn: Caller is the not the Pending Owner");
        _;
    }

     /**
     * @notice Returns the current Owner.
     * @dev returns zero address after renounce time, if the Ownership is renounced.
     */

    function Owner() public view virtual returns(address){
        if(block.timestamp >= _renounceTime && isRenounced){
            return address(0);
        }
        else{
            return _Owner;
        }
    }
     /**
     * @notice Returns the Pending Owner.
     */

    function pendingOwner() public view virtual returns(address){
        return _pendingOwner;
    }

     /**
     * @notice Returns the renounce parameters.
     * @return bool value determining whether Owner has called renounceOwnership or not.
     * @return Renounce Interval in seconds after which the Ownership will be renounced.
     * @return Renounce Time at which the Ownership was/will be renounced. 0 if Ownership retains.
     */
    function renounceParams() public view virtual returns(bool, uint256, uint256){
        return (isRenounced, _renounceInterval, _renounceTime);
    }
     /**
     * @notice Owner can propose ownership to a new Owner(newOwner).
     * @dev Owner can not propose ownership, if it has called renounceOwnership and
     * not retained the ownership yet.
     * @param newOwner address of the new owner to propose ownership to.
     */
    function proposeOwnership(address newOwner) public virtual onlyOwner{
        require(!isRenounced, "SafeOwn: Ownership has been Renounced");
        require(newOwner != address(0), "SafeOwn: New Owner can not be a Zero Address");
        _pendingOwner = newOwner;
    }

     /**
     * @notice Pending Owner can accept the ownership proposal and become the new Owner.
     */
    function acceptOwnership() public virtual onlyPendingOwner{
        address currentOwner = _Owner;
        address newOwner = _pendingOwner;
        _Owner = _pendingOwner;
        _pendingOwner = address(0);
        emit ownershipTransferred(currentOwner, newOwner, block.timestamp);
    }

     /**
     * @notice Owner can renounce ownership. Owner will be removed from the
     * contract after _renounceTime.
     * @dev Owner will be immediately removed if the _renounceInterval is 0.
     * @dev Pending Owner will be immediately removed.
     */
    function renounceOwnership() public virtual onlyOwner{
        require(!isRenounced, "SafeOwn: Already Renounced");
        if(_pendingOwner != address(0)){
             _pendingOwner = address(0);
        }
        _renounceTime = block.timestamp + _renounceInterval;
        isRenounced = true;
        emit ownershipTransferred(_Owner, address(0), _renounceTime);
    }

     /**
     * @notice Owner can retain its ownership and cancel the renouncing(if initiated
     * by Owner).
     */

    function retainOwnership() public virtual onlyOwner{
        require(isRenounced, "SafeOwn: Already Retained");
        _renounceTime = 0;
        isRenounced = false;
        emit ownershipRetained(_Owner, block.timestamp);
    }

}

// SPDX-License-Identifier: proprietary
pragma solidity >=0.8.0;

interface ISelfkeyIdAuthorization {

    function authorize(address _from, address _to, uint256 _amount, string memory _scope, bytes32 _param, uint _timestamp, address _signer, bytes memory _signature) external;

    function getMessageHash(address _from, address _to, uint256 _amount, string memory _scope, bytes32 _param, uint _timestamp) external view returns (bytes32);

    function getEthSignedMessageHash(bytes32 _messageHash) external view returns (bytes32);

    function verify(address _from, address _to, uint256 _amount, string memory _scope, bytes32 _param, uint _timestamp, address _signer, bytes memory _signature) external view returns (bool);

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) external view returns (address);

    function splitSignature(bytes memory sig) external view returns (bytes32 r, bytes32 s, uint8 v);
}

// SPDX-License-Identifier: proprietary
pragma solidity 0.8.9;

interface ILockdaoStaking {

    event StakeAdded(address _account, uint _amount);
    event StakeWithdraw(address _account, uint _amount);
    event RewardsMinted(address _account, uint _amount);

    function lastTimeRewardApplicable() external view returns (uint);

    function rewardPerToken() external view returns (uint);

    function totalSupply() external view returns (uint);

    function stake(address _account, uint256 _amount, bytes32 _param, uint _timestamp, address _signer,bytes memory signature) external;

    function withdraw(uint amount) external;

    function earned(address _account) external view returns (uint);

    function notifyRewardMinted(address _account, uint _amount) external;

    function balanceOf(address account) external view returns (uint);
}