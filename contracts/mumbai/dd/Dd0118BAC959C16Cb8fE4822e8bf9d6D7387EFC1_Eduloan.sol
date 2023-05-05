// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
    function _mint(address account, uint256 amount) internal virtual {
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

// SPDX-License-Identifier: MIT
/*
 ________       __            __
|        \     |  \          |  \
| $$$$$$$$ ____| $$ __    __ | $$  ______    ______   _______
| $$__    /      $$|  \  |  \| $$ /      \  |      \ |       \
| $$  \  |  $$$$$$$| $$  | $$| $$|  $$$$$$\  \$$$$$$\| $$$$$$$\
| $$$$$  | $$  | $$| $$  | $$| $$| $$  | $$ /      $$| $$  | $$
| $$_____| $$__| $$| $$__/ $$| $$| $$__/ $$|  $$$$$$$| $$  | $$
| $$     \\$$    $$ \$$    $$| $$ \$$    $$ \$$    $$| $$  | $$
 \$$$$$$$$ \$$$$$$$  \$$$$$$  \$$  \$$$$$$   \$$$$$$$ \$$   \$$
*/
pragma solidity ^0.8.9;
import "./StudentRegistration.sol";
import "../USDT.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Eduloan is Ownable{
    /*
        It saves bytecode to revert on custom errors instead of using require
        statements. We are just declaring these errors for reverting with upon various
        conditions later in this contract. Thanks, Chiru Labs!
    */
    error inputConnectedWalletAddress();
    error addressAlreadyRegistered();
    error allDuesPaidNoInstallmentsPending();

    address public USDT;
    uint public usdtBalance;
    uint public interestRate;
    address public l1Approver;
    address public l2Approver;
    address private studentRegistrationContract;
    bool onboarded = true;

    mapping(uint => string[]) private studentIpfsURLtoL1;
    mapping(uint => string[]) private studentIpfsURLtoL2;
    mapping(uint => string[]) private studentRewardDocsUpload;
    mapping(uint => bool) private l1DocUpload;
    mapping(uint => bool) private l2DocUpload;
    mapping(uint => bool) private rewardDocUpload;
    mapping(uint => bool) private l1ApprovalDecision;
    mapping(uint => bool) private l2ApprovalDecision;
    mapping(uint => bool) private rewardApprovalDecision;
    mapping(uint => Dashboard) private studentLoanInfo;
    mapping(uint => DashboardMilestones) private milestone;
    mapping(uint => bool) private l2LoanSanctionStatus;
    mapping(uint => uint) private l1MilestoneRejection;
    mapping(uint => uint) private l2MilestoneRejection;
    mapping(uint => bool) private projectStatus;
    mapping(uint => uint) private l1UploadTimes;
    mapping(uint => uint) private l2UploadTimes;

    struct Dashboard{
       uint studentGeneratedID;
       uint loanDuration;
       string profileStatus;
       uint loanReleasedAmount;
       string rewardStatus;
       uint rewardAmountReceived;
       string repaymentStatus;
       uint repaidAmount;
       uint remainingAmount;
       uint principalPlusInterest;
       uint monthlyInstallments;
       uint remainingInstallmentMonths;
    }

    struct DashboardMilestones{
        bool l1approvalStatus;
        bool l2approvalStatus;
        bool fundRelease;
    }

    modifier onlyL1(){
        require(l1Approver == msg.sender, "only L1Approver can call this function");
        _;
    }

    modifier onlyL2(){
        require(l2Approver == msg.sender, "only L2Approver can call this function");
        _;
    }

    // function initialize(address _l1Address, address _l2Address, address _studentContractAddress, address _usdt,uint _rate) external initializer{
    //   ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
    //   l1Approver = _l1Address;
    //   l2Approver = _l2Address;
    //   interestRate = _rate;
    //   studentRegistrationContract = _studentContractAddress;
    //   USDT = _usdt;
    //   usdtBalance = IERC20(USDT).balanceOf(address(this));
    //    __Ownable_init();
    // }

    constructor(address _l1Address, address _l2Address, address _studentContractAddress, address _usdt, uint _rate){
        l1Approver = _l1Address;
        l2Approver = _l2Address;
        interestRate = _rate;
        studentRegistrationContract = _studentContractAddress;
        USDT = _usdt;
        usdtBalance = IERC20(USDT).balanceOf(address(this));
    }

    // function _authorizeUpgrade(address) internal override onlyOwner {}
    function updateUSDTBalance() internal {
        usdtBalance = IERC20(USDT).balanceOf(address(this));
    }

    function studentUploadtoL1(uint _studentID, string memory _ipfsURL) external {
        StudentRegistration stud = StudentRegistration(studentRegistrationContract);
        require(stud.verifyStudent(msg.sender, _studentID) == true, "Student is not registered!!!");
        studentIpfsURLtoL1[_studentID].push(_ipfsURL);
        studentLoanInfo[_studentID].studentGeneratedID = _studentID;
        studentLoanInfo[_studentID].profileStatus = "Account Active";
        l1DocUpload[_studentID] = true;
        l1UploadTimes[_studentID] += 1;
    }

    function l1Verify(uint _studentID, bool _status) external onlyL1{
        StudentRegistration stud = StudentRegistration(studentRegistrationContract);
        require(stud.verifyStudentWithId(_studentID) == true, "Student is not registered!!!");
        require(l1DocUpload[_studentID], "Student has not yet uploaded the docs for L1 verification!!!");
        if(l1MilestoneRejection[_studentID] == 1  && l1UploadTimes[_studentID] == 1){
            revert("Student hasn't uploaded the docs for 2nd chance");
        }
        if(projectStatus[_studentID]){
            revert("Project is cancelled");
        }
        l1ApprovalDecision[_studentID] = _status;
        if(_status == true){
            milestone[_studentID].l1approvalStatus = true;
        }
        if(_status == false){
            l1MilestoneRejection[_studentID] += 1;
        }
        if(l1MilestoneRejection[_studentID] >= 2 && l1UploadTimes[_studentID] == 2){
            projectStatus[_studentID] = true;
        }
    }

    function studentUploadtoL2(uint _studentID, string memory _ipfsURL) external {
        StudentRegistration stud = StudentRegistration(studentRegistrationContract);
        require(stud.verifyStudent(msg.sender, _studentID) == true, "Student is not registered!!!");
        require(l1ApprovalDecision[_studentID] == true, "Student has not received L1 approval or verification failed");
        studentIpfsURLtoL2[_studentID].push(_ipfsURL);
        l2DocUpload[_studentID] = true;
        l2UploadTimes[_studentID] += 1;
    }

    function l2Verify(uint _studentID, bool _status) external onlyL2{
        StudentRegistration stud = StudentRegistration(studentRegistrationContract);
        require(stud.verifyStudentWithId(_studentID) == true, "Student is not registered!!!");
        require(l2DocUpload[_studentID], "Student has not yet uploaded the docs for L2 verification!!!");
        if(l2MilestoneRejection[_studentID] == 1  && l2UploadTimes[_studentID] == 1){
            revert("Student hasn't uploaded the docs for 2nd chance");
        }
        if(projectStatus[_studentID]){
            revert("Project is cancelled");
        }
        l2ApprovalDecision[_studentID] = _status;
        if(_status == true){
            milestone[_studentID].l2approvalStatus = true;
        }
        if(_status == false){
            l2MilestoneRejection[_studentID] += 1;
        }
        if(l2MilestoneRejection[_studentID] >= 2 && l2UploadTimes[_studentID] == 2){
            projectStatus[_studentID] = true;
        }
    }

    function l2SanctionedLoan(uint _studentID, uint _loanDuration, address _collegeWalletAddress, uint _amount) external onlyL2{
        //loanDuration is expected as integer eg: 2 years or 3 years
        if(projectStatus[_studentID]){
            revert("Project is cancelled");
        }
        require(l2ApprovalDecision[_studentID], "L2Verification failed!!");
        uint conversion = _amount * (10**18);
        studentLoanInfo[_studentID].loanDuration = _loanDuration * 2;
        studentLoanInfo[_studentID].loanReleasedAmount = conversion;
        require(IERC20(USDT).transfer(_collegeWalletAddress, conversion),"Transaction Failed!!!");
        uint calculatedInterest = _loanDuration * interestRate;
        uint conversionWithInterest = conversion * calculatedInterest / 100;
        studentLoanInfo[_studentID].principalPlusInterest = conversion + conversionWithInterest;
        l2LoanSanctionStatus[_studentID] = true;
        if(l2LoanSanctionStatus[_studentID] == true){
            milestone[_studentID].fundRelease = true;
        }
        studentLoanInfo[_studentID].remainingInstallmentMonths = studentLoanInfo[_studentID].loanDuration;
        studentLoanInfo[_studentID].monthlyInstallments = studentLoanInfo[_studentID].principalPlusInterest / studentLoanInfo[_studentID].loanDuration;
        studentLoanInfo[_studentID].repaymentStatus = "Pending";
        updateUSDTBalance();
    }

    function l1ReadIpfsURL(uint _studentID) external view returns(string[] memory ipfs_url){
        return studentIpfsURLtoL1[_studentID];
    }

    function l2ReadIpfsURL(uint _studentID) external view returns(string[] memory ipfs_url){
        return studentIpfsURLtoL2[_studentID];
    }

    function l2ReadRewardIpfsURL(uint _studentID) external view returns(string[] memory ipfs_url){
        return studentRewardDocsUpload[_studentID];
    }

    function vault(uint _amount) external onlyL2{
        require(_amount > 0, "Please enter an value above than 0");
        uint conversion = _amount * (10**18);
        IERC20(USDT).transferFrom(msg.sender, address(this), conversion);
        updateUSDTBalance();
    }

    function configureInterestRate(uint _newRate) external onlyL2 {
        interestRate = _newRate;
    }

    function studentUploadForReward(uint _studentID, string memory _ipfsURL) external {
        StudentRegistration stud = StudentRegistration(studentRegistrationContract);
        if(projectStatus[_studentID]){
            revert("Project is cancelled");
        }
        require(stud.verifyStudent(msg.sender, _studentID) == true, "Student is not registered!!!");
        require(l2LoanSanctionStatus[_studentID], "Loan not sanctioned");
        studentRewardDocsUpload[_studentID].push(_ipfsURL);
        rewardDocUpload[_studentID] = true;
    }

    function rewardVerify(uint _studentID, bool _status) external onlyL2{
        StudentRegistration stud = StudentRegistration(studentRegistrationContract);
        if(projectStatus[_studentID]){
            revert("Project is cancelled");
        }
        require(stud.verifyStudentWithId(_studentID) == true, "Student is not registered!!!");
        require(l2LoanSanctionStatus[_studentID] && rewardDocUpload[_studentID], "Loan not sanctioned");
        rewardApprovalDecision[_studentID] = _status;
    }

    function l2RewardSanction(uint _studentID, uint _amount) external onlyL2{
        if(projectStatus[_studentID]){
            revert("Project is cancelled");
        }
        uint conversion = _amount * (10**18);
        StudentRegistration stud = StudentRegistration(studentRegistrationContract);
        IERC20(USDT).transfer(stud.getStudentAddress(_studentID), conversion);
        studentLoanInfo[_studentID].rewardStatus = "Rewarded";
        studentLoanInfo[_studentID].rewardAmountReceived += conversion; 
        updateUSDTBalance();
    }

    function repayLoan(uint _studentID, uint _amount) external {
        if(projectStatus[_studentID]){
            revert("Project is cancelled");
        }
        StudentRegistration stud = StudentRegistration(studentRegistrationContract);
        require(stud.verifyStudentWithId(_studentID) == true, "Student is not registered!!!");
        require(l2LoanSanctionStatus[_studentID], "L2 has not sanctioned the Loan");
        uint conversion = _amount; //* (10**18);
        // while(!(studentLoanInfo[_studentID].remainingAmount < studentLoanInfo[_studentID].monthlyInstallments)){
        //     if(conversion < studentLoanInfo[_studentID].monthlyInstallments) {
        //     revert("Enter the correct instalment amount!!");
        // }
        // }
        if( studentLoanInfo[_studentID].remainingInstallmentMonths == 0){
            revert allDuesPaidNoInstallmentsPending();
        }
        if(conversion == studentLoanInfo[_studentID].monthlyInstallments || 
        studentLoanInfo[_studentID].remainingAmount < studentLoanInfo[_studentID].monthlyInstallments) {
            IERC20(USDT).transferFrom(msg.sender, address(this), conversion);
        }
        studentLoanInfo[_studentID].remainingInstallmentMonths -= 1;
        studentLoanInfo[_studentID].repaidAmount += conversion;
        studentLoanInfo[_studentID].remainingAmount = studentLoanInfo[_studentID].principalPlusInterest - studentLoanInfo[_studentID].repaidAmount;
        if(studentLoanInfo[_studentID].remainingAmount == 0){
            studentLoanInfo[_studentID].repaymentStatus = "All dues are paid";
            studentLoanInfo[_studentID].profileStatus = "Account Settled";
        }
        updateUSDTBalance();
    }

    // function dashboardView(uint _studentID) external view returns(uint student_Id, 
    // uint loan_Duration,
    // string memory profile_status,
    // uint loan_releasedAmount,
    // string memory reward_status,
    // uint reward_amountReceived,
    // string memory repayment_status,
    // uint repaid_amount,
    // uint remaining_amount,
    // uint principal_AmountPlusInterest,
    // uint monthlyInstallment){
    //     return (studentLoanInfo[_studentID].studentGeneratedID,
    //     studentLoanInfo[_studentID].loanDuration,
    //     studentLoanInfo[_studentID].profileStatus,
    //     studentLoanInfo[_studentID].loanReleasedAmount,
    //     studentLoanInfo[_studentID].rewardStatus,
    //     studentLoanInfo[_studentID].rewardAmountReceived,
    //     studentLoanInfo[_studentID].repaymentStatus,
    //     studentLoanInfo[_studentID].repaidAmount,
    //     studentLoanInfo[_studentID].remainingAmount,
    //     studentLoanInfo[_studentID].principalPlusInterest,
    //     studentLoanInfo[_studentID].monthlyInstallments);
    // }

    function dashboardView(uint _studentID) external view returns(Dashboard memory dashboardInfo){
        return studentLoanInfo[_studentID];
    }

    function readMilestone(uint _studentID) external view returns (bool onboardStatus,
    bool L1ApprovalStatus,
    bool L2ApprovalStatus,
    bool FundReleaseStatus
    ){
        return (onboarded, 
        milestone[_studentID].l1approvalStatus,
        milestone[_studentID].l2approvalStatus,
        milestone[_studentID].fundRelease);
    }

    function l1MilestoneCount(uint _studentID) external view returns(uint rejectionCount){
        return l1MilestoneRejection[_studentID];
    }

    function l2MilestoneCount(uint _studentID) external view returns(uint rejectionCount){
        return l2MilestoneRejection[_studentID];
    }

    function projectStatusPerId(uint _studentID) external view returns(bool project){
        return projectStatus[_studentID];
    }
}

// SPDX-License-Identifier: MIT
/*

  /$$$$$$   /$$                     /$$                       /$$     /$$$$$$$                      /$$             /$$                          /$$     /$$                          
 /$$__  $$ | $$                    | $$                      | $$    | $$__  $$                    |__/            | $$                         | $$    |__/                          
| $$  \__//$$$$$$   /$$   /$$  /$$$$$$$  /$$$$$$  /$$$$$$$  /$$$$$$  | $$  \ $$  /$$$$$$   /$$$$$$  /$$  /$$$$$$$ /$$$$$$    /$$$$$$  /$$$$$$  /$$$$$$   /$$  /$$$$$$  /$$$$$$$       
|  $$$$$$|_  $$_/  | $$  | $$ /$$__  $$ /$$__  $$| $$__  $$|_  $$_/  | $$$$$$$/ /$$__  $$ /$$__  $$| $$ /$$_____/|_  $$_/   /$$__  $$|____  $$|_  $$_/  | $$ /$$__  $$| $$__  $$      
 \____  $$ | $$    | $$  | $$| $$  | $$| $$$$$$$$| $$  \ $$  | $$    | $$__  $$| $$$$$$$$| $$  \ $$| $$|  $$$$$$   | $$    | $$  \__/ /$$$$$$$  | $$    | $$| $$  \ $$| $$  \ $$      
 /$$  \ $$ | $$ /$$| $$  | $$| $$  | $$| $$_____/| $$  | $$  | $$ /$$| $$  \ $$| $$_____/| $$  | $$| $$ \____  $$  | $$ /$$| $$      /$$__  $$  | $$ /$$| $$| $$  | $$| $$  | $$      
|  $$$$$$/ |  $$$$/|  $$$$$$/|  $$$$$$$|  $$$$$$$| $$  | $$  |  $$$$/| $$  | $$|  $$$$$$$|  $$$$$$$| $$ /$$$$$$$/  |  $$$$/| $$     |  $$$$$$$  |  $$$$/| $$|  $$$$$$/| $$  | $$      
 \______/   \___/   \______/  \_______/ \_______/|__/  |__/   \___/  |__/  |__/ \_______/ \____  $$|__/|_______/    \___/  |__/      \_______/   \___/  |__/ \______/ |__/  |__/      
                                                                                          /$$  \ $$                                                                                   
                                                                                         |  $$$$$$/                                                                                   
                                                                                          \______/                                                                                    

*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract StudentRegistration is Ownable{

    /*
        It saves bytecode to revert on custom errors instead of using require
        statements. We are just declaring these errors for reverting with upon various
        conditions later in this contract. Thanks, Chiru Labs!
    */
    error inputConnectedWalletAddress();
    error addressAlreadyRegistered();
    error idAlreadyTaken();

   
    mapping(address => mapping(uint256 => bool)) private studentLinkToID;
    mapping(address => mapping(uint256 => StudentInformation)) private studentInfostruct;
    mapping(uint256 => uint256) private idToId;
    mapping(uint256 => string) private idTopassword;
    mapping(uint256 => bool) private idVerification;
    mapping(uint => address) private idToUserAddress;

    uint[] private allIds;
    address[] private pushStudents;


    event StudentRegistered(string indexed mailId, string indexed status);

    struct StudentInformation{
        string firstName;
        string lastName;
        uint256 phoneNo;
        string mailID;
        address walletAddress;
        uint256 studentID;
        string password;
    }


    // function initialize() external initializer{
    //   ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
    //    __Ownable_init();
    // }

    // function _authorizeUpgrade(address) internal override onlyOwner {}


    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    
    
    
    function addStudent(StudentInformation memory _studentInfo) external{
        StudentInformation memory si = _studentInfo;
        if(msg.sender != si.walletAddress){ revert inputConnectedWalletAddress();}
        if(studentLinkToID[msg.sender][si.studentID] == true){ revert addressAlreadyRegistered();}
        for(uint i = 0; i < allIds.length; i++){
            if(si.studentID == allIds[i]){
                revert idAlreadyTaken();
            }
        }
        studentLinkToID[msg.sender][si.studentID] = true;
        studentInfostruct[msg.sender][si.studentID].firstName = si.firstName;
        studentInfostruct[msg.sender][si.studentID].lastName = si.lastName;
        studentInfostruct[msg.sender][si.studentID].phoneNo = si.phoneNo;
        studentInfostruct[msg.sender][si.studentID].mailID = si.mailID;
        studentInfostruct[msg.sender][si.studentID].walletAddress = si.walletAddress;
        studentInfostruct[msg.sender][si.studentID].studentID = si.studentID;
        studentInfostruct[msg.sender][si.studentID].password = si.password;
        idToUserAddress[si.studentID] = si.walletAddress;
        idVerification[si.studentID] = true;
        idToId[si.studentID] = si.studentID;
        idTopassword[si.studentID] = si.password;
        allIds.push(studentInfostruct[msg.sender][si.studentID].studentID);
        pushStudents.push(msg.sender);
        emit StudentRegistered(studentInfostruct[msg.sender][si.studentID].mailID, "Student is Registered Successfully");
    }

    function verifyStudent(address _studentAddress, uint256 _studentId) public view returns(bool condition){
        if(studentLinkToID[_studentAddress][_studentId]){
            return true;
        }else{
            return false;
        }
    }

    function verifyStudentWithId(uint _studentId) public view returns(bool status){
        if(idVerification[_studentId]){
            status = true;
            return status;
        }else{
            return false;
        }
    }

    function getAllStudentAddress() external view returns(address[] memory){
        return pushStudents;
    }  

    function viewStudentInformation( address _studentAddress, uint256 _id) external view returns(
    uint256 phno, 
    string memory mailid, 
    address walletad, 
    uint256 studentid,
    string memory password ){
        require(verifyStudent(_studentAddress,_id) == true, "Student not listed!!");
        return (
        studentInfostruct[_studentAddress][_id].phoneNo,
        studentInfostruct[_studentAddress][_id].mailID,
        studentInfostruct[_studentAddress][_id].walletAddress,
        studentInfostruct[_studentAddress][_id].studentID,
        studentInfostruct[_studentAddress][_id].password);
    }   

    function loginVerify(uint256 _studentID, string memory _password) external view returns (bool verificationStatus){
        if((_studentID == idToId[_studentID]) && (equal(_password,idTopassword[_studentID]))){
            verificationStatus = true;
            return verificationStatus;
        }else{
            verificationStatus = false;
            return verificationStatus;
        }
    }

    function getStudentAddress(uint _studentID) external view returns(address studentAddress){
        return idToUserAddress[_studentID];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
   This contract was created by Crypto Hisenberg for hackathon purpose
*/

contract TetherUSD is ERC20, Ownable {
    constructor(uint _amount) ERC20("Tether USD", "USDT") {
        uint conversion = _amount * (10**18);
        _mint(msg.sender, conversion);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    
}