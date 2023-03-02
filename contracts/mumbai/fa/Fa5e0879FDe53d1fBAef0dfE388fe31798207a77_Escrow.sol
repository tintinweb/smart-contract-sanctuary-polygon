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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Escrow is Pausable, Ownable {
    enum JobStatus {
        PaymentInHold,
        WorkDelivered,
        WorkRejected,
        VerifiedAndPaymentSettled,
        ReclaimNClosed
    }

    struct JobDetails {
        address jobCreator;
        address jobTaker;
        uint[] jobStartTime;
        uint[] jobEndTime;
        IERC20 paymentToken;
        uint[] deposited;
        uint[] withdrawn;
    }

    JobDetails private _jobDetails;
    JobStatus public jobStatus;

    event Deposit(address from, address to, uint amount, uint deadline);
    event ConfirmDelivered(address from, address to);
    event VerifyDelivered(address from, address to, uint amount);
    event RejectDelivered(address from, address to);
    event CloseProject(address from, address to, uint amount);

    modifier inState(JobStatus expected_state) {
        require(jobStatus == expected_state, "Escrow: Unexpected JobStatus");
        _;
    }

    modifier onlyAuthorized(address expected_authorization) {
        require(msg.sender == expected_authorization, "Escrow: Not Authorized");
        _;
    }

    constructor(
        address _jobCreator,
        address _jobTaker,
        uint _amount,
        uint _deadline,
        IERC20 _token
    ) {
        require(_amount > 0, "Factory: Invalid Amount");
        require(_deadline > 0, "Factory: Invalid Deadline");
        require(_jobCreator != address(0), "Factory: Invalid Creator");
        require(_jobTaker != address(0), "Factory: Invalid Seller");
        require(
            _jobCreator != _jobTaker,
            "Factory: Invalid Creator and Seller"
        );
        require(
            address(_token) != address(0),
            "Factory: Invalid Payment Token"
        );

        _jobDetails.jobCreator = _jobCreator;
        _jobDetails.jobTaker = _jobTaker;
        _jobDetails.jobStartTime.push(block.timestamp);
        _jobDetails.jobEndTime.push(_jobDetails.jobStartTime[0] + _deadline);
        _jobDetails.paymentToken = _token;
        _jobDetails.deposited.push(_amount);

        jobStatus = JobStatus.PaymentInHold;
    }

    function jobDetails() public view returns (JobDetails memory) {
        return _jobDetails;
    }

    function deposit(uint _amount, uint _deadline)
        external
        whenNotPaused
        inState(JobStatus.VerifiedAndPaymentSettled)
        onlyAuthorized(_jobDetails.jobCreator)
    {
        require(_amount > 0, "Factory: Invalid Amount");

        _jobDetails.paymentToken.transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        _jobDetails.jobStartTime.push(block.timestamp);
        _jobDetails.jobEndTime.push(
            _jobDetails.jobStartTime[_jobDetails.jobStartTime.length - 1] +
                _deadline
        );
        _jobDetails.deposited.push(_amount);

        jobStatus = JobStatus.PaymentInHold;

        emit Deposit(
            _jobDetails.jobCreator,
            _jobDetails.jobTaker,
            _amount,
            _deadline
        );
    }

    function confirmDelivered()
        external
        whenNotPaused
        inState(JobStatus.PaymentInHold)
        onlyAuthorized(_jobDetails.jobTaker)
    {
        require(
            block.timestamp <=
                _jobDetails.jobEndTime[_jobDetails.jobEndTime.length - 1],
            "Escrow: Deadline Passed"
        );
        jobStatus = JobStatus.WorkDelivered;

        emit ConfirmDelivered(_jobDetails.jobTaker, _jobDetails.jobCreator);
    }

    function verifyDelivered(uint _amount)
        external
        whenNotPaused
        inState(JobStatus.WorkDelivered)
        onlyAuthorized(_jobDetails.jobCreator)
    {
        _settlePayment(_amount);
    }

    function rejectDelivered()
        external
        whenNotPaused
        inState(JobStatus.WorkDelivered)
        onlyAuthorized(_jobDetails.jobCreator)
    {
        jobStatus = JobStatus.WorkRejected;

        emit RejectDelivered(_jobDetails.jobCreator, _jobDetails.jobTaker);
    }

    function releaseFunds(uint _amount)
        external
        whenNotPaused
        inState(JobStatus.WorkRejected)
        onlyAuthorized(_jobDetails.jobCreator)
    {
        _settlePayment(_amount);
    }

    function closeProject() external onlyAuthorized(_jobDetails.jobCreator) {
        if (jobStatus != JobStatus.PaymentInHold || !paused()) {
            revert("Escrow: Cannot close");
        }

        uint amount = _jobDetails.paymentToken.balanceOf(address(this));

        _jobDetails.paymentToken.transfer(_jobDetails.jobCreator, amount);
        jobStatus = JobStatus.ReclaimNClosed;

        emit CloseProject(_jobDetails.jobCreator, _jobDetails.jobTaker, amount);
    }

    function updateDeadline(uint _deadline)
        external
        whenNotPaused
        inState(JobStatus.PaymentInHold)
        onlyAuthorized(_jobDetails.jobCreator)
    {
        require(_deadline > 0, "Escrow: Zero Time");

        _jobDetails.jobEndTime[_jobDetails.jobEndTime.length - 1] =
            _jobDetails.jobStartTime[_jobDetails.jobStartTime.length - 1] +
            _deadline;
    }

    function _settlePayment(uint _amount) private {
        uint amount = _jobDetails.paymentToken.balanceOf(address(this));

        require(_amount <= amount, "Escrow: Insufficient Balance");

        _jobDetails.paymentToken.transfer(_jobDetails.jobTaker, _amount);
        _jobDetails.withdrawn.push(_amount);
        jobStatus = JobStatus.VerifiedAndPaymentSettled;

        emit VerifyDelivered(
            _jobDetails.jobCreator,
            _jobDetails.jobTaker,
            _amount
        );
    }

    function pause() external onlyAuthorized(_jobDetails.jobCreator) {
        _pause();
    }

    function unpause() external onlyAuthorized(_jobDetails.jobCreator) {
        _unpause();
    }
}