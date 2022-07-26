// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./helpers.sol";

contract InstaAutomationHelper is Helpers {
    constructor(address aavePoolAddressesProvider_, address instaList_)
        Helpers(aavePoolAddressesProvider_, instaList_)
    {}

    modifier onlyOwner() {
        require(msg.sender == _owner, "not-an-auth");
        _;
    }

    modifier onlyExecutor() {
        require(_executors[msg.sender], "not-an-executor");
        _;
    }

    modifier onlyDSA(address user_) {
        require(instaList.accountID(user_) != 0, "not-valid-dsa");
        _;
    }

    function flipExecutor(address[] memory executor_, bool[] memory status_)
        public
        onlyOwner
    {
        uint256 length_ = executor_.length;
        for (uint256 i; i < length_; i++) {
            require(
                executor_[i] != _owner,
                "owner-cant-be-removed-as-executor"
            );
            _executors[executor_[i]] = status_[i];
        }
        emit LogFlipExecutors(executor_, status_);
    }

    function updateBufferHf(uint256 newBufferHf_) public onlyOwner {
        emit LogUpdateBufferHf(_bufferHf, newBufferHf_);
        _bufferHf = newBufferHf_;
    }

    function updateMinHf(uint256 newMinimumThresholdHf_) public onlyOwner {
        emit LogUpdateMinHf(_minimumThresholdHf, newMinimumThresholdHf_);
        _minimumThresholdHf = newMinimumThresholdHf_;
    }

    function updateAutomationFee(uint256 newAutomationFee_) public onlyOwner {
        emit LogUpdateAutomationFee(_automationFee, newAutomationFee_);
        _automationFee = newAutomationFee_;
    }
}

contract InstaAutomationImplementation is InstaAutomationHelper {
    using SafeERC20 for IERC20;

    constructor(address aavePoolAddressesProvider_, address instaList_)
        InstaAutomationHelper(aavePoolAddressesProvider_, instaList_)
    {}

    function initialize(
        address owner_,
        uint256 minimumThresholdHf_,
        uint256 bufferHf_,
        uint256 automationFee_
    ) public {
        _owner = owner_;
        _minimumThresholdHf = minimumThresholdHf_;
        _bufferHf = bufferHf_;
        _automationFee = automationFee_;
        _id = 1;

        _executors[owner_] = true;
        require(_status == 0, "already-initialized");
        _status = 1;
    }

    function submitAutomationRequest(
        uint256 safeHealthFactor_,
        uint256 thresholdHealthFactor_
    ) public onlyDSA(msg.sender) {
        require(thresholdHealthFactor_ < safeHealthFactor_, "invalid-inputs");

        require(
            thresholdHealthFactor_ >= _minimumThresholdHf,
            "threshold-health-factor < minimum-Health-factor"
        );

        require(
            _userAutomationConfigs[_userLatestId[msg.sender]].status !=
                Status.AUTOMATED,
            "position-already-in-protection"
        );

        uint256 currentHf_ = getHealthFactor(msg.sender);

        emit LogSubmitAutomation(
            msg.sender,
            _id,
            safeHealthFactor_,
            thresholdHealthFactor_,
            currentHf_
        );

        _userAutomationConfigs[_id] = Automation({
            user: msg.sender,
            id: _id,
            status: Status.AUTOMATED,
            safeHF: safeHealthFactor_,
            thresholdHF: thresholdHealthFactor_
        });

        _userLatestId[msg.sender] = _id;
        _id++;
    }

    function cancelAutomationRequest() external onlyDSA(msg.sender) {
        Automation storage _userAutomationConfig = _userAutomationConfigs[
            _userLatestId[msg.sender]
        ];

        require(
            _userAutomationConfig.user != address(0),
            "automation-not-initialised-for-user"
        );

        require(
            _userAutomationConfig.user == msg.sender,
            "not-authorized-to-make-this-call"
        );

        require(
            _userAutomationConfig.status == Status.AUTOMATED,
            "already-executed-or-canceled"
        );

        emit LogCancelAutomation(
            msg.sender,
            _userAutomationConfig.id,
            _userAutomationConfig.safeHF,
            _userAutomationConfig.thresholdHF,
            _executionCount[_userAutomationConfig.id]
        );

        _userAutomationConfig.status = Status.USER_CANCELLED;
        _userLatestId[msg.sender] = 0;
    }

    function executeAutomation(
        address user_,
        address collateralToken_,
        address debtToken_,
        uint256 collateralAmount_,
        uint256 debtAmount_,
        uint256 collateralAmtWithTotalFee_,
        uint256 rateMode_,
        uint256 route_,
        Swap memory swap_
    ) external onlyDSA(user_) onlyExecutor {
        Automation storage _userAutomationConfig = _userAutomationConfigs[
            _userLatestId[user_]
        ];

        require(
            _userAutomationConfig.user != address(0),
            "automation-not-initialised-for-user"
        );

        require(
            _userAutomationConfig.status == Status.AUTOMATED,
            "already-executed-or-canceled"
        );

        Spell memory spells_ = _buildSpell(
            collateralToken_,
            debtToken_,
            collateralAmtWithTotalFee_,
            collateralAmount_,
            debtAmount_,
            rateMode_,
            route_,
            swap_
        );

        uint256 initialHf_ = getHealthFactor(user_);

        require(
            _userAutomationConfig.safeHF >= initialHf_ + _bufferHf,
            "position-not-ready-for-automation"
        );

        require(cast(AccountInterface(user_), spells_), "cast-failed");

        uint256 finalHf_ = getHealthFactor(user_);

        require(
            finalHf_ > initialHf_,
            "automation-failed: Final-Health-Factor <= Initial-Health-factor"
        );

        _executionCount[_userAutomationConfig.id]++;

        if (finalHf_ < (_userAutomationConfig.safeHF - _bufferHf)) {
            emit LogExecuteNextAutomation(
                user_,
                _userAutomationConfig.id,
                _userAutomationConfig.safeHF,
                _userAutomationConfig.thresholdHF,
                finalHf_
            );
        } else {
            _userAutomationConfig.status = Status.SUCCESS;

            emit LogExecuteAutomation(
                user_,
                _userAutomationConfig.id,
                _userAutomationConfig.safeHF,
                _userAutomationConfig.thresholdHF,
                finalHf_,
                initialHf_
            );
        }

        emit LogExecuteAutomationParams(
            user_,
            _userAutomationConfig.id,
            collateralToken_,
            debtToken_,
            collateralAmount_,
            debtAmount_,
            collateralAmtWithTotalFee_,
            _executionCount[_userAutomationConfig.id],
            finalHf_,
            initialHf_,
            _automationFee,
            spells_
        );
    }

    function systemCancel(address user_, uint256 errorCode)
        external
        onlyDSA(user_)
        onlyExecutor
    {
        Automation storage _userAutomationConfig = _userAutomationConfigs[
            _userLatestId[user_]
        ];

        require(
            _userAutomationConfig.user != address(0),
            "automation-not-initialised-for-user"
        );

        require(
            _userAutomationConfig.status == Status.AUTOMATED,
            "already-executed-or-canceled"
        );

        emit LogSystemCancelAutomation(
            user_,
            _userAutomationConfig.id,
            _userAutomationConfig.safeHF,
            _userAutomationConfig.thresholdHF,
            _executionCount[_userAutomationConfig.id],
            errorCode
        );

        _userAutomationConfig.status = Status.DROPPED;
        _userLatestId[user_] = 0;
    }

    function systemUpdateAutomation(address[] memory users_)
        public
        onlyExecutor
    {
        uint256 length_ = users_.length;
        for (uint256 i; i < length_; i++) {
            Automation storage _userAutomationConfig = _userAutomationConfigs[
                _userLatestId[users_[i]]
            ];

            require(
                _executionCount[_userAutomationConfig.id] >= 1,
                "can-update-status: use CancelAutomation"
            );
            require(
                _userAutomationConfig.status == Status.AUTOMATED,
                "already-executed-or-canceled"
            );

            uint256 healthFactor = getHealthFactor(users_[i]);

            emit LogExecuteAutomation(
                users_[i],
                _userAutomationConfig.id,
                _userAutomationConfig.safeHF,
                _userAutomationConfig.thresholdHF,
                healthFactor,
                healthFactor
            );

            _userAutomationConfig.status = Status.SUCCESS;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./events.sol";

contract Helpers is Events {
    constructor(address aavePoolAddressesProvider_, address instaList_)
        Variables(aavePoolAddressesProvider_, instaList_)
    {}

    function _buildSpell(
        address collateralToken_,
        address debtToken_,
        uint256 collateralAmountWithTotalFee_,
        uint256 collateralAmount_,
        uint256 debtAmount_,
        uint256 rateMode_,
        uint256 route_,
        Swap memory swap_
    ) internal view returns (Spell memory spells) {
        bool isSameToken_ = collateralToken_ == debtToken_;
        uint256 id_ = 87562384628;

        uint256 automationFee_ = (collateralAmount_ * _automationFee) / 1e4;

        if (isSameToken_) {
            (spells._targets, spells._datas) = (
                new string[](3),
                new bytes[](3)
            );

            (spells._targets[0], spells._datas[0]) = (
                "AAVE-V3-A",
                abi.encodeWithSignature(
                    "paybackWithATokens(address,uint256,uint256,uint256,uint256)",
                    collateralToken_, // debt = collateral token
                    collateralAmount_, // collateral atoken to be used as payback
                    rateMode_, // rate mode
                    0,
                    0
                )
            );

            (spells._targets[1], spells._datas[1]) = (
                "AAVE-V3-A",
                abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    collateralToken_, // withdraw the collateral now
                    automationFee_, // the amount of collateral token to withdraw
                    0,
                    0
                )
            );

            (spells._targets[2], spells._datas[2]) = (
                "BASIC-A",
                abi.encodeWithSignature(
                    "withdraw(address,uint256,address,uint256,uint256)",
                    collateralToken_, // transfer the collateral
                    automationFee_, // the automation fee
                    address(this),
                    0,
                    0
                )
            );
        } else if (route_ > 0) {
            /**
             * if we are taking the flashloan, then this case
             * This case if the user is doesn't have enough collateral to payback the debt
             * will be used most of the time
             * flashBorrowAndCast: Take the flashloan of collateral token
             * swap: swap the collateral token into the debt token
             * payback: payback the debt
             * withdraw: withdraw the collateral
             * flashPayback: payback the flashloan
             */
            Spell memory flashloanSpell_;
            uint256 loanAmtWithFee_ = collateralAmountWithTotalFee_ -
                automationFee_;

            (flashloanSpell_._targets, flashloanSpell_._datas) = (
                new string[](5),
                new bytes[](5)
            );

            (spells._targets, spells._datas) = (
                new string[](1),
                new bytes[](1)
            );

            (flashloanSpell_._targets[0], flashloanSpell_._datas[0]) = (
                "1INCH-A",
                abi.encodeWithSignature(
                    "sell(address,address,uint256,uint256,bytes,uint256)",
                    swap_.buyToken, // debt token
                    swap_.sellToken, // collateral token
                    swap_.sellAmt, // amount of collateral withdrawn to swap
                    swap_.unitAmt,
                    swap_.callData,
                    id_
                )
            );

            (flashloanSpell_._targets[1], flashloanSpell_._datas[1]) = (
                "AAVE-V3-A",
                abi.encodeWithSignature(
                    "payback(address,uint256,uint256,uint256,uint256)",
                    debtToken_, // debt
                    debtAmount_,
                    rateMode_,
                    id_,
                    0
                )
            );

            (flashloanSpell_._targets[2], flashloanSpell_._datas[2]) = (
                "AAVE-V3-A",
                abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    collateralToken_, // withdraw the collateral now
                    collateralAmountWithTotalFee_, // the amount of collateral token to withdraw
                    0,
                    0
                )
            );

            (flashloanSpell_._targets[3], flashloanSpell_._datas[3]) = (
                "INSTAPOOL-C",
                abi.encodeWithSignature(
                    "flashPayback(address,uint256,uint256,uint256)",
                    collateralToken_, // collateral token
                    loanAmtWithFee_,
                    0,
                    0
                )
            );

            (flashloanSpell_._targets[4], flashloanSpell_._datas[4]) = (
                "BASIC-A",
                abi.encodeWithSignature(
                    "withdraw(address,uint256,address,uint256,uint256)",
                    collateralToken_, // transfer the collateral
                    automationFee_, // the automation fee,
                    address(this),
                    0,
                    0
                )
            );

            bytes memory encodedFlashData_ = abi.encode(
                flashloanSpell_._targets,
                flashloanSpell_._datas
            );

            (spells._targets[0], spells._datas[0]) = (
                "INSTAPOOL-C",
                abi.encodeWithSignature(
                    "flashBorrowAndCast(address,uint256,uint256,bytes,bytes)",
                    collateralToken_,
                    collateralAmount_,
                    route_,
                    encodedFlashData_,
                    "0x"
                )
            );
        } else {
            (spells._targets, spells._datas) = (
                new string[](4),
                new bytes[](4)
            );

            /**
             * This case if the user have enough collateral to payback the debt
             */
            (spells._targets[0], spells._datas[0]) = (
                "AAVE-V3-A",
                abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    collateralToken_, // collateral token to withdraw
                    collateralAmountWithTotalFee_, // amount to withdraw
                    0,
                    0
                )
            );

            (spells._targets[1], spells._datas[1]) = (
                "1INCH-A",
                abi.encodeWithSignature(
                    "sell(address,address,uint256,uint256,bytes,uint256)",
                    swap_.buyToken, // debt token
                    swap_.sellToken, // collateral that we withdrawn
                    swap_.sellAmt, // amount of collateral withdrawn to swap
                    swap_.unitAmt,
                    swap_.callData,
                    id_
                )
            );

            (spells._targets[2], spells._datas[2]) = (
                "AAVE-V3-A",
                abi.encodeWithSignature(
                    "payback(address,uint256,uint256,uint256,uint256)",
                    debtToken_,
                    debtAmount_,
                    rateMode_,
                    id_,
                    0
                )
            );

            (spells._targets[3], spells._datas[3]) = (
                "BASIC-A",
                abi.encodeWithSignature(
                    "withdraw(address,uint256,address,uint256,uint256)",
                    collateralToken_, // transfer the collateral
                    automationFee_, // the automation fee,
                    address(this),
                    0,
                    0
                )
            );
        }
    }

    function cast(AccountInterface dsa, Spell memory spells)
        public
        returns (bool success)
    {
        (success, ) = address(dsa).call(
            abi.encodeWithSignature(
                "cast(string[],bytes[],address)",
                spells._targets,
                spells._datas,
                address(this)
            )
        );
    }

    function getHealthFactor(address user)
        public
        view
        returns (uint256 healthFactor)
    {
        (, , , , , healthFactor) = aave.getUserAccountData(user);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./variables.sol";

abstract contract Events is Variables {
    event LogSubmitAutomation(
        address indexed user,
        uint256 indexed id,
        uint256 safeHF,
        uint256 thresholdHF,
        uint256 currentHf
    );

    event LogCancelAutomation(
        address indexed user,
        uint256 indexed id,
        uint256 safeHF,
        uint256 thresholdHF,
        uint256 executionCount
    );

    event LogExecuteAutomation(
        address indexed user,
        uint256 indexed id,
        uint256 safeHF,
        uint256 thresholdHF,
        uint256 finalHf,
        uint256 initialHf
    );

    event LogExecuteAutomationParams(
        address indexed user,
        uint256 indexed id,
        address collateralToken,
        address debtToken,
        uint256 collateralAmount,
        uint256 debtAmount,
        uint256 collateralAmtWithTotalFee,
        uint256 executionCount,
        uint256 finalHf,
        uint256 initialHf,
        uint256 automationFee,
        Spell spells
    );

    event LogExecuteNextAutomation(
        address indexed user,
        uint256 indexed id,
        uint256 safeHF,
        uint256 thresholdHF,
        uint256 currentHf
    );

    event LogSystemCancelAutomation(
        address indexed user,
        uint256 indexed id,
        uint256 safeHF,
        uint256 thresholdHF,
        uint256 executionCount,
        uint256 errorCode
    );

    event LogFlipExecutors(address[] executors, bool[] status);

    event LogUpdateBufferHf(uint256 oldBufferHf, uint256 newBufferHf);

    event LogUpdateMinHf(uint256 oldMinHf, uint256 newMinHf);

    event LogUpdateAutomationFee(
        uint256 oldAutomationFee,
        uint256 newAutomationFee
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./interfaces.sol";

contract ConstantVariables {
    AaveInterface internal immutable aave;

    AavePoolProviderInterface internal immutable aavePoolAddressProvider;

    ListInterface internal immutable instaList;

    constructor(address aavePoolAddressesProvider_, address instaList_) {
        aavePoolAddressProvider = AavePoolProviderInterface(
            aavePoolAddressesProvider_
        );

        aave = AaveInterface(
            AavePoolProviderInterface(aavePoolAddressesProvider_).getPool()
        );

        instaList = ListInterface(instaList_);
    }
}

contract Structs {
    enum Status {
        NOT_INITIATED, // no automation enabled for user
        AUTOMATED, // User enabled automation
        SUCCESS, // Automation executed
        DROPPED, // Automation dropped by system
        USER_CANCELLED // user cancelled the automation
    }

    struct Spell {
        string[] _targets;
        bytes[] _datas;
    }

    struct Swap {
        address buyToken;
        address sellToken;
        uint256 sellAmt;
        uint256 unitAmt;
        bytes callData;
    }

    struct Automation {
        address user;
        uint256 safeHF;
        uint256 thresholdHF;
        uint256 id;
        Status status;
    }
}

contract Variables is ConstantVariables, Structs {
    address public _owner; // The owner of address(this)
    uint256 public _status; // initialise status check
    uint256 public _id; // user automation id

    mapping(uint256 => Automation) public _userAutomationConfigs; // user automation config

    mapping(address => uint256) public _userLatestId; // user latest automation id

    mapping(uint256 => uint256) public _executionCount; // execution count for user automation

    mapping(address => bool) public _executors; // executors enabled by _owner

    uint256 public _minimumThresholdHf; // minimum threshold Health required for enabled automation
    uint256 public _bufferHf; // buffer health factor for next automaion check
    uint256 public _automationFee; // Automation fees in BPS

    constructor(address aavePoolAddressesProvider_, address instaList_)
        ConstantVariables(aavePoolAddressesProvider_, instaList_)
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface AaveInterface {
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

interface AavePoolProviderInterface {
    function getPool() external view returns (address);
}

interface AccountInterface {
    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32);
}

interface ListInterface {
    function accountID(address) external returns (uint64);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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