// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./library/SafeERC20.sol";
import "./owner/Ownable.sol";
import "./utils/ReentrancyGuard.sol";

contract NOMADCollab is Ownable, ReentrancyGuard {
    // prevents over and under flow
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Collab contract status
    enum COLLAB_STATUS {
        CREATED,
        AMOUNT_PAID,
        CANCELLED,
        DISPUTE,
        COMPLETED
    }

    struct Payout {
        uint256 paymentAmount; // Total amount paid
        uint256 paymentDate; // Date on which payment made
        uint256 totalWorkHours; // Total working hours
    }

    struct HiringDetails {
        string recruiterEmail; // Email of the recruiter
        string talenEmail; // Email of the talent
        string jobRole; // Role of the job
        string jobDescription; // Job description
        string jobType; // Type of the job
        uint256 workHours; // Total defined work hours
        string languageWithLevel; // Language with selected level
        string[] skills; // Array of skill set
        string experienceLevel; // Experience level
        string[] specialExpertise; // Special expertise of the talent
        uint256 hourlyRate; // Hourly rate
        uint256 totalRate; // Total rate based on hourly rate
        string platfromTermsAndConditions; // Platform T&C
        string clientTermsAndCondition; // Client/Recruiter T&C if there's any
    }

    struct Hiring {
        HiringDetails hiringDetails;
        COLLAB_STATUS status; // Current status of the collab
        bool isPaid; // true if payment done from the recruiter side
        bool islive; // true when collab contract is creted
        string paymentType; // Type of the payment : fiat or crypto
        string currencySymbol; // Currency symbol
        uint256 paymentAmount; // Total payment of the contract
        string userDispueteReason; // Reason for dispute
        string disputeVerdict; // Verdict of the dispute
        string cancellationReason; // Cancellation reason if one of the entity cancel the collab contract
        uint256 totalPayouts; // Total payouts made by recruiter
        mapping(uint256 => Payout) payouts;
    }

    mapping(string => Hiring) public hirings;

    // Waco platform address
    address public PlatformAddress;

    event TalentAcquired(
        string _contractId,
        string _recruiterEmail,
        string _talentEmail
    );
    event UpdatedContractPaymentDetails(
        string _contractId,
        string _paymentType,
        string _currencySymbol,
        uint256 _paymentAmount
    );
    event UpdatedContractHiringDetails(string _contractId);
    event PaymentFromRecruiter(
        string _contractId,
        uint256 _paymentAmount,
        uint256 _paymentDate
    );
    event PaymentToTalent(
        string _contractId,
        uint256 _paymentAmount,
        uint256 _paymentDate
    );
    event CancelContract(string _contractId, string _cancellationReason);
    event CancelContractWithDisputeVerdict(
        string _contractId,
        string _disputeVerdict
    );
    event DisputeRaised(string _transactionId);
    event DisputeResolved(string _transactionId);

    // Check whether user has rights to cancel the transaction
    modifier hasModificationRights() {
        require(
            msg.sender == owner() ||
                msg.sender == coOwner() ||
                msg.sender == PlatformAddress,
            "Caller don't have modification rights!"
        );
        _;
    }

    /**
     * @notice Initialize the contract
     * @param _coOwnerAddress Co-Owner address of the contract
     * @param _platformAddress: WACO platform wallet
     */
    constructor(address _coOwnerAddress, address _platformAddress) public {
        _co_owner = _coOwnerAddress;
        PlatformAddress = _platformAddress;
    }

    /**
     * @notice This function will create a collab contract between recruiter and talent
     * @dev this function is only called by a wallet who has modification rights
     * @param _contractId unique contract ID
     * @param _hiringDetails: Hiring form values in tuple form
     * @param _paymentType: Payment type
     * @param _currencySymbol: currency cymbol
     * @param _paymentAmount: Total payment amount
     */
    function createContract(
        string memory _contractId,
        HiringDetails memory _hiringDetails,
        string memory _paymentType,
        string memory _currencySymbol,
        uint256 _paymentAmount
    ) external nonReentrant hasModificationRights returns (bool) {
        require(_paymentAmount != 0, "Invalid payment amount");
        require(isContract(_contractId) == false, "Contract already exists.");

        Hiring storage hiring = hirings[_contractId];
        hiring.hiringDetails = _hiringDetails;
        hiring.status = COLLAB_STATUS.CREATED;
        hiring.isPaid = false;
        hiring.islive = true;

        hiring.paymentType = _paymentType;
        hiring.currencySymbol = _currencySymbol;
        hiring.paymentAmount = _paymentAmount;

        emit TalentAcquired(
            _contractId,
            _hiringDetails.recruiterEmail,
            _hiringDetails.talenEmail
        );
        return true;
    }

    /**
     * @notice This function will update payment details of collab contract
     * @dev this function is only called by a wallet who has modification rights
     * @param _contractId unique contract ID
     * @param _paymentType: Payment type
     * @param _currencySymbol: currency cymbol
     * @param _paymentAmount: Total payment amount
     */
    function updateContractPaymentDetails(
        string memory _contractId,
        string memory _paymentType,
        string memory _currencySymbol,
        uint256 _paymentAmount
    ) external nonReentrant hasModificationRights returns (bool) {
        require(_paymentAmount != 0, "Invalid payment amount");
        require(isContract(_contractId), "Invalid contract id");
        Hiring storage hiring = hirings[_contractId];

        hiring.paymentType = _paymentType;
        hiring.currencySymbol = _currencySymbol;
        hiring.paymentAmount = _paymentAmount;
        emit UpdatedContractPaymentDetails(
            _contractId,
            _paymentType,
            _currencySymbol,
            _paymentAmount
        );
        return true;
    }

    /**
     * @notice This function will update hiring details of collab contract
     * @dev this function is only called by a wallet who has modification rights
     * @param _contractId unique contract ID
     * @param _hiringDetails: Hiring form values in tuple form
     */
    function updateContractHiringDetails(
        string memory _contractId,
        HiringDetails memory _hiringDetails
    ) external nonReentrant hasModificationRights returns (bool) {
        require(isContract(_contractId), "Invalid contract id");
        Hiring storage hiring = hirings[_contractId];
        hiring.hiringDetails = _hiringDetails;
        emit UpdatedContractHiringDetails(_contractId);
        return true;
    }

    /**
     * @notice This function will get called once recruiter made payment to waco services
     * @dev this function is only called by a wallet who has modification rights
     * @param _contractId unique contract ID
     * @param _paymentAmount: Total payment amount to be paid
     */
    function makePaymentToWACOServices(
        string memory _contractId,
        uint256 _paymentAmount
    ) external nonReentrant hasModificationRights returns (bool) {
        require(isContract(_contractId), "Invalid contract id");

        Hiring storage hiring = hirings[_contractId];

        require(
            hiring.isPaid == false,
            "Payment to WACO services is already made."
        );
        require(hiring.paymentAmount <= _paymentAmount, "Wrong payment amount");
        hiring.isPaid = true;
        emit PaymentFromRecruiter(_contractId, _paymentAmount, block.timestamp);
        return true;
    }

    /**
     * @notice This function will get called when waco services will release payment to talen on behalf of recruiter
     * @dev this function is only called by a wallet who has modification rights
     * @param _contractId unique contract ID
     * @param _paymentAmount: Total payment amount to be paid
     * @param _totalWorkHours : Total working hours
     */
    function makePaymentToTalent(
        string memory _contractId,
        uint256 _paymentAmount,
        uint256 _totalWorkHours
    ) external nonReentrant hasModificationRights returns (bool) {
        require(isContract(_contractId), "Invalid contract id");

        Hiring storage hiring = hirings[_contractId];

        require(hiring.isPaid == true, "Cannot make payout");
        hiring.payouts[hiring.totalPayouts] = Payout(
            _paymentAmount,
            block.timestamp,
            _totalWorkHours
        );
        hiring.totalPayouts = hiring.totalPayouts.add(1);
        emit PaymentToTalent(_contractId, _paymentAmount, block.timestamp);
        return true;
    }

    /**
     * @notice This function will get called when there's a dispute in between talen and recruiter also to resolve the dispute same function will get called
     * @dev this function is only called by a wallet who has modification rights
     * @param _contractId unique contract ID
     * @param _userDispueteReason: Resoan for the dispute
     */
    function dispute(
        string memory _contractId,
        string memory _userDispueteReason
    ) external nonReentrant hasModificationRights returns (bool) {
        require(isContract(_contractId), "Invalid contract id");

        Hiring storage hiring = hirings[_contractId];

        if (
            hiring.status == COLLAB_STATUS.CANCELLED ||
            hiring.status == COLLAB_STATUS.COMPLETED
        ) {
            revert("Cannot raise a dispute!");
        }

        if (hiring.status == COLLAB_STATUS.DISPUTE) {
            hiring.status = COLLAB_STATUS.CREATED;
            hiring.userDispueteReason = "Resolved";
            emit DisputeResolved(_contractId);
            return false;
        } else {
            hiring.status = COLLAB_STATUS.DISPUTE;
            hiring.userDispueteReason = _userDispueteReason;
            emit DisputeRaised(_contractId);
            return true;
        }
    }

    /**
     * @notice This function will get called when due to some reason contract is getting cancelled
     * @dev this function is only called by a wallet who has modification rights
     * @param _contractId unique contract ID
     * @param _cancellationReason: Resoan for the cancellation
     */
    function cancelContract(
        string memory _contractId,
        string memory _cancellationReason
    ) external nonReentrant hasModificationRights returns (bool) {
        require(isContract(_contractId), "Invalid contract id");

        Hiring storage hiring = hirings[_contractId];

        if (
            hiring.status == COLLAB_STATUS.CANCELLED ||
            hiring.status == COLLAB_STATUS.COMPLETED ||
            hiring.status == COLLAB_STATUS.DISPUTE
        ) {
            revert("Cannot Cancel the contract");
        }

        hiring.cancellationReason = _cancellationReason;
        hiring.status = COLLAB_STATUS.CANCELLED;

        emit CancelContract(_contractId, _cancellationReason);
        return true;
    }

    /**
     * @notice This function will get called when there's a dispute and community has taken a decision on the same
     * @dev this function is only called by a wallet who has modification rights
     * @param _contractId unique contract ID
     * @param _disputeVerdict: Community verdict on the dispute
     */
    function cancelContractWithDisputeVerdict(
        string memory _contractId,
        string memory _disputeVerdict
    ) external nonReentrant hasModificationRights returns (bool) {
        require(isContract(_contractId), "Invalid contract id");

        Hiring storage hiring = hirings[_contractId];

        if (
            hiring.status == COLLAB_STATUS.CANCELLED ||
            hiring.status == COLLAB_STATUS.COMPLETED ||
            hiring.status == COLLAB_STATUS.CREATED
        ) {
            revert("Cannot Cancel the contract");
        }

        hiring.disputeVerdict = _disputeVerdict;
        hiring.status = COLLAB_STATUS.CANCELLED;

        emit CancelContractWithDisputeVerdict(_contractId, _disputeVerdict);
        return true;
    }

    /**
     * @notice Using this owner can update the platform wallet
     * @dev this function is only called by a wallet who has owner rights
     * @param _address new platform address
     */
    function updatePlatformAddress(address _address)
        external
        onlyOwner
        returns (bool)
    {
        PlatformAddress = _address;
        return true;
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @dev This function is only callable by admin.
     * @param _tokenAddress: the address of the token to withdraw
     */
    function recoverWrongTokens(address _tokenAddress)
        external
        onlyOwner
        returns (bool)
    {
        uint256 _tokenAmount = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        return true;
    }

    /**
     * @notice This function will return bool based on dispute status
     * @param _contractId unique contract ID
     * @return true(if dispute)/ false(if not)
     */
    function isDisputed(string memory _contractId)
        external
        view
        returns (bool)
    {
        require(isContract(_contractId), "Invalid contract id");

        Hiring storage hiring = hirings[_contractId];

        if (hiring.status == COLLAB_STATUS.DISPUTE) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice This function will return object containing hiring details
     * @param _contractId unique contract ID
     * @return Hiring object
     */
    function getCollabContractHiringDetails(string memory _contractId)
        external
        view
        returns (HiringDetails memory)
    {
        return hirings[_contractId].hiringDetails;
    }

    /**
     * @dev util function to check Contract Id is valid or not
     */
    function isContract(string memory _contractId)
        private
        view
        returns (bool isIndeed)
    {
        return hirings[_contractId].islive;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./../utils/Context.sol";

contract Ownable is Context {
    address private _owner;
    address internal _co_owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event CoOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
     * @dev Returns the address of the current owner.
     */
    function coOwner() public view returns (address) {
        return _co_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owners.
     */
    modifier onlyOwners() {
        require(
            _owner == _msgSender() || _co_owner == _msgSender(),
            "Ownable: caller is not the owner"
        );
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers co-ownership of the contract to a new account (`newOwner`).
     */
    function transferCoOwnership(address newCoOwner) public onlyOwners {
        require(
            newCoOwner != address(0),
            "Ownable: new co-owner is the zero address"
        );
        emit CoOwnershipTransferred(_co_owner, newCoOwner);
        _co_owner = newCoOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwners {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Address.sol";
import "../interfaces/IERC20.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

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

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256 r) {
        require(m != 0, "SafeMath: to ceil number shall not be zero");
        return ((a + m - 1) / m) * m;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

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
     * @dev Returns the percentage of tokens transfer fees`.
     */
    function FeeRewardPct() external view returns (uint256);

    /**
     * @dev Returns the decimals of token`.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address spender, uint256 amount) external;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}