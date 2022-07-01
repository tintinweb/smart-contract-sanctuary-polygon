// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./helpers.sol";

contract InstaAutomationImplementation is Helpers {
    using SafeERC20 for IERC20;
    modifier onlyOwner() {
        // require(msg.sender == _owner, "caller-not-owner");
        _;
    }

    constructor(address _aavePoolAddressesProvider, address _instaList)
        Helpers(_aavePoolAddressesProvider, _instaList)
    {}

    // function initialize(address owner_) public virtual {
    //     _owner = owner_;
    //     require(_status == 0, "already-initialized");
    //     _status = 1;
    // }

    modifier onlyDSA(address user) {
        // require(instaList.accountID(user) != 0, "zero-caller: not-valid-dsa");
        _;
    }

    function submitAutomationRequest(
        uint256 safeHealthFactor,
        uint256 thresholdHealthFactor
    ) public onlyDSA(msg.sender) {
        require(thresholdHealthFactor < safeHealthFactor, "invalid-inputs");

        require(
            thresholdHealthFactor >= 105 * 1e16,
            "threshold-health-factor < 1.05"
        ); // TODO: update

        uint256 currentHf = _getHealthFactor(msg.sender);

        require(
            currentHf >= 105 * 1e16,
            "current HF not safe to enable automation"
        ); // TODO: update

        emit LogSubmitAutomation(
            msg.sender,
            _vnonce,
            safeHealthFactor,
            thresholdHealthFactor,
            currentHf
        );

        automationMap[_vnonce] = Automation({
            user: msg.sender,
            vnonce: _vnonce,
            status: Status.AUTOMATED,
            safeHF: safeHealthFactor,
            thresholdHF: thresholdHealthFactor
        });

        userMap[msg.sender] = _vnonce;
        _vnonce++;
    }

    function submitAutomationRequestMock(
        address user,
        uint256 safeHealthFactor,
        uint256 thresholdHealthFactor
    ) public {
        // require(thresholdHealthFactor < safeHealthFactor, "invalid-inputs");

        // require(
        //     thresholdHealthFactor >= 105 * 1e16,
        //     "threshold-health-factor < 1.05"
        // ); // TODO: update

        uint256 currentHf = _getHealthFactor(user);

        // require(
        //     currentHf >= 105 * 1e16,
        //     "current HF not safe to enable automation"
        // ); // TODO: update

        emit LogSubmitAutomation(
            user,
            _vnonce,
            safeHealthFactor,
            thresholdHealthFactor,
            currentHf
        );

        automationMap[_vnonce] = Automation({
            user: user,
            vnonce: _vnonce,
            status: Status.AUTOMATED,
            safeHF: safeHealthFactor,
            thresholdHF: thresholdHealthFactor
        });

        userMap[user] = _vnonce;
        _vnonce++;
    }

    function cancelAutomationRequest() external onlyDSA(msg.sender) {
        Automation memory currentUserMap = automationMap[userMap[msg.sender]];

        require(
            currentUserMap.user != address(0),
            "no automation initialised for this caller"
        );

        require(
            currentUserMap.user == msg.sender,
            "not authorised to cancel automation"
        );

        require(executionCnt[currentUserMap.vnonce] > 0, "automation executed");

        require(
            currentUserMap.status == Status.AUTOMATED,
            "automation already canceled or executed"
        );

        currentUserMap.status = Status.USER_CANCELLED;

        emit LogCancelAutomation(
            msg.sender,
            currentUserMap.vnonce,
            currentUserMap.safeHF,
            currentUserMap.thresholdHF
        );
    }

    function executeAutomation(
        bool isIsolated,
        address user,
        uint256 debtAmts_,
        uint256 loanAmt_,
        uint256 loanAmtWithFee_,
        uint256 rateMode_,
        uint256 route_,
        Swap memory swap
    ) external onlyDSA(user) onlyOwner {
        Automation memory currentUserMap = automationMap[userMap[user]];

        require(
            currentUserMap.user != address(0),
            "no automation initialised for this caller"
        );

        require(
            currentUserMap.status == Status.AUTOMATED,
            "automation already canceled or executed"
        );

        Spell memory spells = _buildSpell(
            isIsolated,
            debtAmts_,
            loanAmt_,
            loanAmtWithFee_,
            rateMode_,
            route_,
            swap
        );

        require(
            cast(AccountInterface(user), spells),
            "automation execution failed"
        );

        uint256 currentHf = _getHealthFactor(user);

        executionCnt[currentUserMap.vnonce]++;

        if (currentHf < currentUserMap.safeHF) {
            emit LogExecuteNextAutomation(
                user,
                currentUserMap.vnonce,
                currentUserMap.safeHF,
                currentUserMap.thresholdHF
            );
        } else {
            currentUserMap.status = Status.SUCCESS;

            emit LogExecuteAutomation(
                user,
                currentUserMap.vnonce,
                currentUserMap.safeHF,
                currentUserMap.thresholdHF
            );
        }
    }

    function systemRevert(address user) external onlyDSA(user) onlyOwner {
        Automation memory currentUserMap = automationMap[userMap[user]];

        require(
            currentUserMap.user != address(0),
            "no automation initialised for this caller"
        );

        require(
            currentUserMap.status == Status.AUTOMATED,
            "automation already canceled or executed"
        );

        emit LogSystemCancelAutomation(
            user,
            currentUserMap.vnonce,
            currentUserMap.safeHF,
            currentUserMap.thresholdHF
        );

        currentUserMap.status = Status.DROPPED;
    }

    function updateAutomation(
        uint256 safeHealthFactor,
        uint256 thresholdHealthFactor
    ) external onlyDSA(msg.sender) {
        Automation memory currentUserMap = automationMap[userMap[msg.sender]];

        require(
            currentUserMap.user != address(0),
            "no automation initialised for this caller"
        );

        require(
            currentUserMap.status == Status.AUTOMATED,
            "automation already canceled or executed"
        );

        require(
            thresholdHealthFactor >= 105 * 1e16,
            "threshold-health-factor < 1.05"
        );

        require(thresholdHealthFactor < safeHealthFactor, "invalid-inputs");

        uint256 currentHf = _getHealthFactor(msg.sender);

        require(
            currentHf >= 105 * 1e16,
            "current HF not safe to enable automation"
        );

        currentUserMap.status = Status.DROPPED;

        emit LogUpdateAutomation(
            msg.sender,
            currentUserMap.vnonce,
            currentUserMap.safeHF,
            currentUserMap.thresholdHF,
            currentHf
        );

        automationMap[_vnonce] = Automation({
            user: msg.sender,
            vnonce: _vnonce,
            status: Status.AUTOMATED,
            safeHF: safeHealthFactor,
            thresholdHF: thresholdHealthFactor
        });

        userMap[msg.sender] = _vnonce;
        _vnonce++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./events.sol";

contract Helpers is Events {
    constructor(address _aavePoolAddressesProvider, address _instaList)
        Variables(_aavePoolAddressesProvider, _instaList)
    {}

    function _buildSpell(
        bool isIsolated,
        uint256 debtAmt_,
        uint256 loanAmt_,
        uint256 loanAmtWithFee_,
        uint256 rateMode_,
        uint256 route_,
        Swap memory swap
    ) internal pure returns (Spell memory spell) {
        if (loanAmt_ > 0) {
            /**
             * if we are taking the flashloan, then this case
             * This case if the user is doesn't have enough collateral to payback the debt
             * will be used most of the time
             */
            Spell memory flashloanSpell;
            (flashloanSpell._targets, flashloanSpell._datas) = (
                new string[](4),
                new bytes[](4)
            );

            (spell._targets, spell._datas) = (new string[](1), new bytes[](1));

            if (isIsolated) {
                /**
                 * If the user is in isolation mode
                 * The spell for this case is as follows
                 * flashBorrowAndCast: Take the flashloan of debt token
                 * payback: the debt token
                 * withdraw: the collteral token
                 * sell: swap it into debt token
                 * flashPayback: payback the flashlaon
                 */
                (flashloanSpell._targets[0], flashloanSpell._datas[0]) = (
                    "AAVE-V3-A",
                    abi.encodeWithSignature(
                        "payback(address,uint256,uint256,uint256,uint256)",
                        swap.buyToken, // debt
                        loanAmt_,
                        rateMode_,
                        0,
                        0
                    )
                );

                (flashloanSpell._targets[1], flashloanSpell._datas[1]) = (
                    "AAVE-V3-A",
                    abi.encodeWithSignature(
                        "withdraw(address,uint256,uint256,uint256)",
                        swap.sellToken, // collateral token to convert into debt token
                        swap.sellAmt, // the amount of collateral token to withdraw
                        0,
                        0
                    )
                );

                (flashloanSpell._targets[2], flashloanSpell._datas[2]) = (
                    "1INCH-A",
                    abi.encodeWithSignature(
                        "sell(address,address,uint256,uint256,bytes,uint256)",
                        swap.buyToken, // debt token
                        swap.sellToken, // collateral that we withdrawn
                        swap.sellAmt, // amount of collateral withdrawn to swap
                        swap.unitAmt,
                        swap.callData,
                        0
                    )
                );

                (flashloanSpell._targets[3], flashloanSpell._datas[3]) = (
                    "INSTAPOOL-C",
                    abi.encodeWithSignature(
                        "flashPayback(address,uint256,uint256,uint256)",
                        swap.buyToken, // debt token
                        loanAmtWithFee_,
                        0,
                        0
                    )
                );
            } else {
                /**
                 * If the user is not in isolation mode
                 * The spell for this case is as follows:
                 * flashBorrowAndCast: Take the flashloan of debt token
                 * deposit: deposit the debt token to increase the HF
                 * withdraw: withdraw the collateral
                 * sell: swap the collateral into debt token
                 * flashPayback: payback the flashloan
                 */
                uint256 swapSetID = 4983934594387987932859;
                (flashloanSpell._targets[0], flashloanSpell._datas[0]) = (
                    "1INCH-A",
                    abi.encodeWithSignature(
                        "sell(address,address,uint256,uint256,bytes,uint256)",
                        swap.sellToken, // collateral token
                        swap.buyToken, // debt token
                        swap.sellAmt, // amount of collateral withdrawn to swap
                        swap.unitAmt,
                        swap.callData,
                        swapSetID
                    )
                );

                (flashloanSpell._targets[1], flashloanSpell._datas[1]) = (
                    "AAVE-V3-A",
                    abi.encodeWithSignature(
                        "payback(address,uint256,uint256,uint256,uint256)",
                        swap.buyToken, // debt
                        0,
                        rateMode_,
                        swapSetID,
                        0
                    )
                );

                (flashloanSpell._targets[2], flashloanSpell._datas[2]) = (
                    "AAVE-V3-A",
                    abi.encodeWithSignature(
                        "withdraw(address,uint256,uint256,uint256)",
                        swap.sellToken, // withdraw the collateral now
                        swap.sellAmt, // the amount of collateral token to withdraw
                        0,
                        0
                    )
                );

                (flashloanSpell._targets[3], flashloanSpell._datas[3]) = (
                    "INSTAPOOL-C",
                    abi.encodeWithSignature(
                        "flashPayback(address,uint256,uint256,uint256)",
                        swap.sellToken, // collateral token
                        loanAmtWithFee_,
                        0,
                        0
                    )
                );
            }

            bytes memory encodedFlashData_ = abi.encode(
                flashloanSpell._targets,
                flashloanSpell._datas
            );

            (spell._targets[0], spell._datas[0]) = (
                "INSTAPOOL-C",
                abi.encodeWithSignature(
                    "flashBorrowAndCast(address,uint256,uint256,bytes,bytes)",
                    swap.sellToken,
                    loanAmt_,
                    route_,
                    encodedFlashData_,
                    "0x"
                )
            );
        } else {
            (spell._targets, spell._datas) = (new string[](3), new bytes[](3));

            /**
             * This case if the user have enough collateral to payback the debt
             */
            (spell._targets[0], spell._datas[0]) = (
                "AAVE-V3-A",
                abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256,uint256)",
                    swap.sellToken, // collateral token to withdraw
                    swap.sellAmt, // amount to withdraw
                    0,
                    0
                )
            );

            (spell._targets[1], spell._datas[1]) = (
                "1INCH-A",
                abi.encodeWithSignature(
                    "sell(address,address,uint256,uint256,bytes,uint256)",
                    swap.buyToken, // debt token
                    swap.sellToken, // collateral that we withdrawn
                    swap.sellAmt, // amount of collateral withdrawn to swap
                    swap.unitAmt,
                    swap.callData,
                    0
                )
            );

            (spell._targets[2], spell._datas[2]) = (
                "AAVE-V3-A",
                abi.encodeWithSignature(
                    "payback(address,uint256,uint256,uint256,uint256)",
                    swap.buyToken,
                    debtAmt_,
                    rateMode_,
                    0,
                    0
                )
            );
        }
    }

    function cast(AccountInterface dsa, Spell memory spells)
        internal
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

    function _getHealthFactor(address user)
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
        address user,
        uint256 vnonce,
        uint256 safeHF,
        uint256 thresholdHF,
        uint256 currentHf
    );

    event LogCancelAutomation(
        address user,
        uint256 vnonce,
        uint256 safeHF,
        uint256 thresholdHF
    );

    event LogExecuteAutomation(
        address user,
        uint256 vnonce,
        uint256 safeHF,
        uint256 thresholdHF
    );

    event LogExecuteNextAutomation(
        address user,
        uint256 vnonce,
        uint256 safeHF,
        uint256 thresholdHF
    );

    event LogSystemCancelAutomation(
        address user,
        uint256 vnonce,
        uint256 safeHF,
        uint256 thresholdHF
    );

    event LogUpdateAutomation(
        address user,
        uint256 vnonce,
        uint256 safeHF,
        uint256 thresholdHF,
        uint256 currentHf
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

contract Variables is ConstantVariables {
    address _owner;
    uint256 _status;
    uint256 _vnonce;

    enum Status {
        AUTOMATED,
        SUCCESS,
        DROPPED,
        USER_CANCELLED
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
        uint256 vnonce;
        Status status;
    }

    mapping(uint256 => Automation) automationMap;

    mapping(address => uint256) userMap;

    mapping(uint256 => uint256) executionCnt;

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