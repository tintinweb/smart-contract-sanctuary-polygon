// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./AbstractBridge.sol";
import "./mint/IMint.sol";
import "../ERC20/IERC20.sol";
import "../Mutex.sol";

contract SafeERC20Bridge is AbstractBridge, Mutex {
    uint256 constant DECIMALS = 6;

    mapping(uint128 => mapping(address => BindingInfo)) public bindings;
    mapping(address => uint256) public fees;
    mapping(address => uint256) public balances;

    event LockTokens(
        uint16 feeChainId,
        address token,
        uint256 amount,
        string recipient,
        uint256 gaslessReward,
        string referrer,
        uint256 referrerFee,
        uint256 fee
    );

    event ReleaseTokens(
        address token,
        uint256 amount,
        address recipient,
        uint256 gaslessReward,
        address caller
    );

    event Fee(
        uint16 feeChainId,
        address token,
        uint256 amount,
        string recipient
    );

    function lockTokens(
        address token_,
        uint256 amount_,
        uint16 executionChainId_,
        string calldata recipient_,
        string calldata referrer_,
        uint256 gaslessReward_
    ) external mutex whenNotPaused whenInitialized {
        require(token_ != address(0), "unavaliable token");
        require(chains[executionChainId_], "execution chain is disable");

        require(
            bindings[executionChainId_][token_].enabled,
            "token is disabled"
        );
        require(
            amount_ >= bindings[executionChainId_][token_].minAmount,
            "less than min amount"
        );
        uint256 fee = calculateFee_(executionChainId_, token_, amount_);
        require(amount_ > fee, "fee more than amount");
        unchecked {
            amount_ = amount_ - fee;
        }
        require(amount_ > gaslessReward_, "gassless reward more than amount");
        uint256 referrerFee = (fee *
            referrersFeeInPercent[executionChainId_][referrer_]) /
            PERCENT_FACTOR;
        fees[token_] += fee - referrerFee;
        balances[token_] += amount_ + referrerFee;

        uint256 divider = 10**(IERC20(token_).decimals() - DECIMALS);
        emit LockTokens(
            executionChainId_,
            token_,
            amount_,
            recipient_,
            gaslessReward_,
            referrer_,
            referrerFee,
            fee - referrerFee
        );

        IMint(adapter).mintTokens(
            executionChainId_,
            bindings[executionChainId_][token_].executionAsset,
            amount_ / divider,
            recipient_,
            gaslessReward_ / divider,
            referrer_,
            referrerFee / divider
        );
        safeCall_(
            token_,
            abi.encodeWithSelector(
                IERC20(token_).transferFrom.selector,
                msg.sender,
                address(this),
                amount_ + fee
            )
        );
    }

    function calculateFee_(
        uint16 executionChainId_,
        address token_,
        uint256 amount_
    ) private view returns (uint256) {
        uint128 percent = amount_ >
            bindings[executionChainId_][token_].thresholdFee
            ? bindings[executionChainId_][token_].afterPercentFee
            : bindings[executionChainId_][token_].beforePercentFee;

        return
            bindings[executionChainId_][token_].minFee +
            (amount_ * percent) /
            PERCENT_FACTOR;
    }

    function releaseTokens(
        bytes32 callerContract_,
        address token_,
        address payable recipient_,
        uint256 amount_,
        uint256 gaslessReward_
    ) external mutex whenNotPaused whenInitialized onlyExecutor {
        require(token_ != address(0), "zero address");
        require(callerContract == callerContract_, "only caller contract");

        IERC20 token = IERC20(token_);
        uint256 divider = 10**(token.decimals() - DECIMALS);
        uint256 balance_ = balances[token_];
        amount_ *= divider;
        gaslessReward_ *= divider;
        require(balance_ >= amount_, "insufficient funds");
        unchecked {
            balances[token_] = balance_ - amount_;
        }

        // slither-disable-start tx-origin
        emit ReleaseTokens(
            token_,
            amount_,
            recipient_,
            gaslessReward_,
            tx.origin
        );
        if (gaslessReward_ > 0 && recipient_ != tx.origin) {
            safeCall_(
                token_,
                abi.encodeWithSelector(
                    IERC20(token_).transfer.selector,
                    recipient_,
                    amount_ - gaslessReward_
                )
            );
            safeCall_(
                token_,
                abi.encodeWithSelector(
                    IERC20(token_).transfer.selector,
                    tx.origin,
                    gaslessReward_
                )
            );
        } else {
            safeCall_(
                token_,
                abi.encodeWithSelector(
                    IERC20(token_).transfer.selector,
                    recipient_,
                    amount_
                )
            );
        }
        // slither-disable-end tx-origin
    }

    function transferFee(address token_)
        external
        mutex
        whenNotPaused
        whenInitialized
    {
        uint16 feeChainId_ = feeChainId;
        require(chains[feeChainId_], "chain is disable");
        BindingInfo memory binding = bindings[feeChainId_][token_];
        require(binding.enabled, "token is disabled");
        uint256 fee_ = fees[token_];
        require(fee_ >= binding.minAmount, "less than min amount");
        balances[token_] += fee_;
        fees[token_] = 0;
        fee_ /= 10**(IERC20(token_).decimals() - DECIMALS);
        string memory feeRecipient_ = feeRecipient;

        emit Fee(feeChainId_, token_, fee_, feeRecipient_);
        IMint(adapter).mintTokens(
            feeChainId_,
            binding.executionAsset,
            fee_,
            feeRecipient_,
            0,
            "",
            0
        );
    }

    function updateBindingInfo(
        uint16 executionChainId_,
        address token_,
        string calldata executionAsset_,
        uint256 minAmount_,
        uint256 minFee_,
        uint256 thresholdFee_,
        uint128 beforePercentFee_,
        uint128 afterPercentFee_,
        bool enabled_
    ) external onlyAdmin {
        require(token_ != address(0), "zero address");
        require(
            !enabled_ || IERC20(token_).decimals() >= DECIMALS,
            "invalid token decimals"
        );
        bindings[executionChainId_][token_] = BindingInfo(
            executionAsset_,
            minAmount_,
            minFee_,
            thresholdFee_,
            beforePercentFee_,
            afterPercentFee_,
            enabled_
        );
    }

    function safeCall_(address target_, bytes memory callData_) private {
        (bool success_, bytes memory data_) = target_.call{value: 0}(callData_);
        if (success_) {
            require(
                data_.length == 0 || abi.decode(data_, (bool)),
                "call did not succeed"
            );
        } else {
            if (data_.length > 0) {
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(data_)
                    revert(add(32, data_), returndata_size)
                }
            } else {
                revert("no error");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Pausable.sol";
import "../Initializable.sol";

abstract contract AbstractBridge is Initializable, Pausable {
    struct BindingInfo {
        string executionAsset;
        uint256 minAmount;
        uint256 minFee;
        uint256 thresholdFee;
        uint128 beforePercentFee;
        uint128 afterPercentFee;
        bool enabled;
    }

    event ExecutionChainUpdated(uint128 feeChainId, address caller);
    event FeeChainUpdated(uint128 feeChainId, address caller);
    event CallerContractUpdated(bytes32 executorContract, address caller);
    event FeeRecipientUpdated(string feeRecipient, address caller);
    event SignerUpdated(address caller, address oldSigner, address signer);
    event ReferrerFeeUpdated(
        uint128 chainId,
        string referrer,
        uint128 feeInPercent
    );

    uint128 constant PERCENT_FACTOR = 10 ** 6;

    uint16 public feeChainId;
    string public feeRecipient;
    address public adapter;
    address public executor;
    bytes32 callerContract;
    mapping(uint128 => bool) public chains;
    mapping(uint128 => mapping(string => uint128)) public referrersFeeInPercent;

    modifier onlyExecutor() {
        require(msg.sender == executor, "only executor");
        _;
    }

    function init(
        address admin_,
        address adapter_,
        uint16 feeChainId_,
        string calldata feeRecipient_,
        address executor_,
        bytes32 callerContract_
    ) external whenNotInitialized {
        require(admin_ != address(0), "zero address");
        require(adapter_ != address(0), "zero address");
        require(executor_ != address(0), "zero address");
        feeChainId = feeChainId_;
        pauser = admin_;
        admin = admin_;
        feeRecipient = feeRecipient_;
        adapter = adapter_;
        executor = executor_;
        callerContract = callerContract_;
        isInited = true;
    }

    function updateExecutionChain(
        uint128 executionChainId_,
        bool enabled
    ) external onlyAdmin {
        emit ExecutionChainUpdated(executionChainId_, msg.sender);
        chains[executionChainId_] = enabled;
    }

    function updateFeeChain(uint16 feeChainId_) external onlyAdmin {
        emit FeeChainUpdated(feeChainId_, msg.sender);
        feeChainId = feeChainId_;
    }

    function updateCallerContract(bytes32 callerContract_) external onlyAdmin {
        emit CallerContractUpdated(callerContract_, msg.sender);
        callerContract_ = callerContract_;
    }

    function updateFeeRecipient(
        string calldata feeRecipient_
    ) external onlyAdmin {
        emit FeeRecipientUpdated(feeRecipient_, msg.sender);
        feeRecipient = feeRecipient_;
    }

    function updateReferrer(
        uint128 executionChainId_,
        string calldata referrer_,
        uint128 percentFee_
    ) external onlyAdmin {
        require(percentFee_ <= 2e5); // up 20% max
        require(chains[executionChainId_], "execution chain is disable");
        emit ReferrerFeeUpdated(executionChainId_, referrer_, percentFee_);
        referrersFeeInPercent[executionChainId_][referrer_] = percentFee_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IMint {
    function mintTokens(
        uint16 executionChainId_,
        string calldata token_,
        uint256 amount_,
        string calldata recipient_,
        uint256 gaslessClaimReward_,
        string calldata referrer_,
        uint256 referrerFee_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account_) external view returns (uint256);

    function transfer(address to_, uint256 amount_) external returns (bool);

    function allowance(address owner_, address spender_)
        external
        view
        returns (uint256);

    function approve(address spender_, uint256 amount_) external returns (bool);

    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Mutex {
    bool private _lock;

    modifier mutex() {
        require(!_lock, "mutex lock");
        _lock = true;
        _;
        _lock = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Adminable.sol";

abstract contract Pausable is Adminable {
    event Paused(address account);
    event Unpaused(address account);
    event PauserUpdated(address sender, address oldPauser, address pauser);

    bool public isPaused;
    address public pauser;

    constructor() {
        isPaused = false;
    }

    modifier whenNotPaused() {
        require(!isPaused, "paused");
        _;
    }

    modifier whenPaused() {
        require(isPaused, "not paused");
        _;
    }

    modifier onlyPauser() {
        require(pauser == msg.sender, "only pauser");
        _;
    }

    function pause() external whenNotPaused onlyPauser {
        isPaused = true;
        emit Paused(msg.sender);
    }

    function unpause() external whenPaused onlyPauser {
        isPaused = false;
        emit Unpaused(msg.sender);
    }

    function updatePauser(address pauser_) external onlyAdmin {
        require(pauser_ != address(0), "zero address");
        emit PauserUpdated(msg.sender, pauser, pauser_);
        pauser = pauser_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Initializable {
    bool internal isInited;

    modifier whenInitialized() {
        require(isInited, "not initialized");
        _;
    }

    modifier whenNotInitialized() {
        require(!isInited, "already initialized");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Adminable {
    event AdminUpdated(address sender, address oldAdmin, address admin);

    address public admin;

    modifier onlyAdmin() {
        require(admin == msg.sender, "only admin");
        _;
    }

    function updateAdmin(address admin_) external onlyAdmin {
        require(admin_ != address(0), "zero address");
        emit AdminUpdated(msg.sender, admin, admin_);
        admin = admin_;
    }
}