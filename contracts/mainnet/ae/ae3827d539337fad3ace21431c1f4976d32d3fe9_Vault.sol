// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import "./libraries/AddArrayLib.sol";

import "./interfaces/ITradeExecutor.sol";
import "./interfaces/IYieldExecutor.sol";
import "./interfaces/IVault.sol";

/// @title Polygains Vault (Brahma Vault)
/// @author 0xAd1 and Bapireddy
/// @notice Minimal vault contract to support trades across different protocols.
contract Vault is IVault, ERC20Permit, ReentrancyGuard {
    using AddrArrayLib for AddrArrayLib.Addresses;

    /*///////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev minimum balance used to check when executor is removed.
    uint256 constant DUST_LIMIT = 10**18;
    /// @dev The max basis points used as normalizing factor.
    uint256 constant MAX_BPS = 10000;

    /// @notice wmatic address
    address constant wMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    /*///////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/
    /// @notice The underlying token the vault accepts.
    address public immutable override wantToken;

    uint8 private immutable tokenDecimals;

    /*///////////////////////////////////////////////////////////////
                            MUTABLE ACCESS MODFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice boolean for enabling emergency mode to halt new withdrawal/deposits into vault.
    bool public emergencyMode;

    // // @notice address of batcher used for batching user deposits/withdrawals.
    // address public batcher;
    /// @notice keeper address to move funds between executors.
    address public override keeper;
    /// @notice Governance address to add/remove  executors.
    address public override governance;
    address public pendingGovernance;

    /// @notice Creates a new Vault that accepts a specific underlying token.
    /// @param _wantToken The ERC20 compliant token the vault should accept.
    /// @param _name The name of the vault token.
    /// @param _symbol The symbol of the vault token.
    /// @param _keeper The address of the keeper to move funds between executors.
    /// @param _governance The address of the governance to perform governance functions.
    constructor(
        string memory _name,
        string memory _symbol,
        address _wantToken,
        address _keeper,
        address _governance,
        uint256 _maxDepositLimit
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        tokenDecimals = IERC20Metadata(_wantToken).decimals();
        wantToken = _wantToken;
        keeper = _keeper;
        governance = _governance;
        maxDepositLimit = _maxDepositLimit;
    }

    function decimals() public view override returns (uint8) {
        return tokenDecimals;
    }

    /*///////////////////////////////////////////////////////////////
                       USER DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    event VaultDeposit(
        address indexed depositor,
        address indexed recipient,
        uint256 amountIn
    );
    event VaultWithdraw(
        address indexed depositor,
        address indexed recipient,
        uint256 amountOut
    );

    /// @notice max number of shares mintable in the vault
    uint256 public maxDepositLimit;

    /// @notice Initiates a deposit of want tokens to the vault.
    /// @param amountIn The amount of erc20 wmatic token to deposit.
    /// @param receiver The address to receive vault tokens.
    function deposit(uint256 amountIn, address receiver)
        public
        payable
        override
        nonReentrant
        returns (uint256 shares)
    {
        nonEmergencyMode();
        isValidAddress(receiver);

        if (amountIn > 0) {
            IERC20(wantToken).transferFrom(msg.sender, address(this), amountIn);
        }

        if (msg.value > 0) {
            uint256 oldBal = IERC20(wantToken).balanceOf(address(this));
            (bool success, ) = payable(wantToken).call{value: msg.value}("");
            require(success, "WRAP_UNSUCCESS");
            uint256 newBal = IERC20(wantToken).balanceOf(address(this));

            require(newBal - oldBal == msg.value, "WRAP_UNSUCCESSFULL");
            amountIn += msg.value;
        }

        require(amountIn > 0, "ZERO_AMOUNT");

        _checkReentrancyOnYieldExecutors();
        // calculate the shares based on the amount.
        // amount comprises of total funds in vault + last week's yield
        // added to disincentivize users from timing deposits and withdraws
        // before and after harvest
        shares = totalSupply() > 0
            ? (totalSupply() * amountIn) / (totalVaultFunds() + lastEpochYield)
            : amountIn;
        require(shares != 0, "ZERO_SHARES");

        _mint(receiver, shares);
        require(totalSupply() <= maxDepositLimit, "VAULT_CAP_REACHED");
        emit VaultDeposit(msg.sender, receiver, amountIn);
    }

    /// @notice Initiates a withdrawal of vault tokens to the user.
    /// @param sharesIn The amount of vault tokens to withdraw.
    /// @param receiver The address to receive the vault tokens.
    function withdraw(uint256 sharesIn, address receiver)
        public
        override
        nonReentrant
        returns (uint256 amountOut)
    {
        nonEmergencyMode();
        isValidAddress(receiver);
        _checkReentrancyOnYieldExecutors();
        require(sharesIn > 0, "ZERO_SHARES");
        // calculate proportional amount out based on funds in vault and executors
        amountOut =
            (sharesIn * IERC20(wantToken).balanceOf(address(this))) /
            totalSupply();

        // YieldExecutors always hold LP tokens only and never wantTokens
        for (uint256 i = 0; i < totalYieldExecutors(); i++) {
            IYieldExecutor exec = IYieldExecutor(yieldExecutorByIndex(i));
            uint256 lpOut = (sharesIn * exec.totalLPTokens()) / totalSupply();

            if (lpOut > 0) {
                uint256 wantTokenOut = _withdrawFromYieldExecutor(
                    address(exec),
                    lpOut
                );
                amountOut += wantTokenOut;
            }
        }
        amountOut -= (pendingFee * sharesIn) / totalSupply();

        // burn shares of msg.sender
        _burn(msg.sender, sharesIn);
        /// charging exitFee
        if (exitFee > 0) {
            uint256 fee = (amountOut * exitFee) / MAX_BPS;
            IERC20(wantToken).transfer(governance, fee);
            amountOut = amountOut - fee;
        }

        IERC20(wantToken).transfer(receiver, amountOut);
        emit VaultWithdraw(msg.sender, receiver, amountOut);
    }

    /// @notice Called by keeper after each epoch to manage yeild and allocate capital
    /// @param _claimYieldData array of bytes used for claiming yield from YE list in order of aray
    /// @param _withdrawData bytes required to withdraw data from tradeExecutor
    /// @param _shouldPlaceTrade boolean indicating wether to send this epoch's yield to tradeExecutor or to compound it into the vault
    function harvest(
        bytes[] calldata _claimYieldData,
        bytes calldata _withdrawData,
        bool _shouldPlaceTrade
    ) public nonReentrant {
        onlyKeeper();
        _checkReentrancyOnYieldExecutors();
        isValidAddress(address(tradeExecutor));

        uint256 baseYield = 0;
        // Iterates over all yield executors and collects this epoch's yield
        for (uint256 i = 0; i < totalYieldExecutors(); i++) {
            IYieldExecutor exec = IYieldExecutor(yieldExecutorByIndex(i));
            baseYield += exec.claimYield(_claimYieldData[i]);
        }
        uint256 fee;

        // Collects last epoch's trading yield
        tradeExecutor.initiateWithdraw(_withdrawData);

        // Setting this harvest yield as lastEpochYeild
        lastEpochYield = baseYield;

        uint256 currentSharePrice = (totalVaultFunds() * 1e18) / totalSupply();

        // Fees if new share price is more than last epoch's share price
        if (currentSharePrice > prevSharePrice) {
            fee =
                ((currentSharePrice - prevSharePrice) *
                    totalSupply() *
                    performanceFee) /
                (1e18 * MAX_BPS);
        }
        pendingFee += fee;
        prevSharePrice = currentSharePrice;

        if (_shouldPlaceTrade) {
            IERC20(wantToken).transfer(
                address(tradeExecutor),
                lastEpochYield - fee
            );
        }
    }

    /// @notice Calculates the total amount of underlying tokens the vault holds.
    /// @return The total amount of underlying tokens the vault holds.
    function totalVaultFunds() public view returns (uint256) {
        return
            IERC20(wantToken).balanceOf(address(this)) +
            totalYieldExecutorFunds() -
            pendingFee;
    }

    /*///////////////////////////////////////////////////////////////
                    EXECUTOR DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice list of yield executors connected to vault.
    AddrArrayLib.Addresses private yieldExecutorsList;

    /// @notice trade executor for the vault.
    ITradeExecutor public tradeExecutor;

    /// @notice Emitted after the vault deposits into a executor contract.
    /// @param executor The executor that was deposited into.
    /// @param underlyingAmount The amount of underlying tokens that were deposited.
    event YieldExecutorDeposit(
        address indexed executor,
        uint256 underlyingAmount
    );

    /// @notice Emitted after the vault withdraws funds from a executor contract.
    /// @param executor The executor that was withdrawn from.
    /// @param underlyingAmount The amount of underlying tokens that were withdrawn.
    event YieldExecutorWithdrawal(
        address indexed executor,
        uint256 underlyingAmount
    );

    /// @notice Deposit given amount of want tokens into valid executor.
    /// @param _executor The executor to deposit into.
    /// @param _amount The amount of want tokens to deposit.
    /// @return lp token minted as lp by yieldExecutor
    function _depositIntoYieldExecutor(address _executor, uint256 _amount)
        internal
        returns (uint256 lp)
    {
        isActiveYieldExecutor(_executor);
        require(_amount > 0, "ZERO_AMOUNT");
        IERC20(wantToken).transfer(_executor, _amount);
        lp = IYieldExecutor(_executor).depositIntoExecutor(_amount);
        emit YieldExecutorDeposit(_executor, _amount);
    }

    /// @notice Withdraw given amount of want tokens into valid executor.
    /// @param _executor The executor to withdraw tokens from.
    /// @param _lpTokens The amount of lp tokens to withdraw.
    /// @return amountOut The amount of want tokens received
    function _withdrawFromYieldExecutor(address _executor, uint256 _lpTokens)
        internal
        returns (uint256 amountOut)
    {
        isActiveYieldExecutor(_executor);
        require(_lpTokens > 0, "ZERO_AMOUNT");
        uint256 prevBal = IERC20(wantToken).balanceOf(address(this));
        amountOut = IYieldExecutor(_executor).withdrawfromExecutor(_lpTokens);
        uint256 newBal = IERC20(wantToken).balanceOf(address(this));
        require(newBal - prevBal == amountOut, "UNSUCCESSFULL_WITHDRAW");
        emit YieldExecutorWithdrawal(_executor, amountOut);
    }

    /// @notice Wrapper function for internal withdraw exposed to keeper for manual management
    function depositIntoYieldExecutor(address _executor, uint256 _amount)
        public
        nonReentrant
        returns (uint256 lp)
    {
        onlyKeeper();
        lp = _depositIntoYieldExecutor(_executor, _amount);
    }

    /// @notice Wrapper function for internal withdraw exposed to keeper for manual management
    function withdrawFromYieldExecutor(address _executor, uint256 _lpTokens)
        public
        nonReentrant
        returns (uint256 amountOut)
    {
        onlyKeeper();
        amountOut = _withdrawFromYieldExecutor(_executor, _lpTokens);
    }

    /*///////////////////////////////////////////////////////////////
                           FEE CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @dev holds fees left for vault to claim
    uint256 public pendingFee;
    /// @dev share price during last harvest
    uint256 public prevSharePrice = type(uint256).max;
    /// @dev yield generated by YieldExecutor during last epoch
    uint256 public lastEpochYield;
    /// @dev Perfomance fee for the vault.
    uint256 public performanceFee;
    /// @notice Fee denominated in MAX_BPS charged during exit.
    uint256 public exitFee;

    /// @notice event emitted when fees are collected
    /// @param fees fees collected in last harvest cycle
    event FeesCollected(uint256 fees);

    /// @notice Emitted after perfomance fee updation.
    /// @param oldFee The old performance fee on vault.
    /// @param newFee The new performance fee on vault.
    event UpdatePerformanceFee(uint256 oldFee, uint256 newFee);

    /// @notice Updates the performance fee on the vault.
    /// @param _fee The new performance fee on the vault.
    /// @dev The new fee must be always less than 50% of yield.
    function setPerformanceFee(uint256 _fee) public {
        onlyGovernance();
        require(_fee < MAX_BPS / 2, "FEE_TOO_HIGH");
        emit UpdatePerformanceFee(performanceFee, _fee);
        performanceFee = _fee;
    }

    /// @notice Emitted after exit fee updation.
    /// @param oldFee The old exit fee on vault.
    /// @param newFee The new exit fee on vault.
    event UpdateExitFee(uint256 oldFee, uint256 newFee);

    /// @notice Function to set exit fee on the vault, can only be called by governance
    /// @param _fee Address of fee
    function setExitFee(uint256 _fee) public {
        onlyGovernance();
        require(_fee < MAX_BPS / 2, "EXIT_FEE_TOO_HIGH");
        emit UpdateExitFee(exitFee, _fee);
        exitFee = _fee;
    }

    function collectFee(uint256 feeAmount) public {
        onlyGovernance();
        pendingFee = pendingFee - feeAmount;
        // Send collected fee to governance
        IERC20(wantToken).transfer(governance, feeAmount);
        emit FeesCollected(feeAmount);
    }

    /*///////////////////////////////////////////////////////////////
                    EXECUTOR ADDITION/REMOVAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when tradeExec is changed
    /// @param oldExecutor The address of old trade executor.
    /// @param newExecutor The address of new trade executor.
    event TradeExecutorChanged(
        address indexed oldExecutor,
        address indexed newExecutor
    );

    /// @notice Emitted when executor is added to vault.
    /// @param executor The address of added executor.
    event YieldExecutorAdded(address indexed executor);

    /// @notice Emitted when executor is removed from vault.
    /// @param executor The address of removed executor.
    event YieldExecutorRemoved(address indexed executor);

    function setTradeExecutor(address _tradeExecutor) public {
        onlyGovernance();
        isValidAddress(_tradeExecutor);
        require(
            ITradeExecutor(_tradeExecutor).vault() == address(this),
            "INVALID_VAULT"
        );
        require(
            IERC20(wantToken).allowance(_tradeExecutor, address(this)) > 0,
            "NO_ALLOWANCE"
        );
        emit TradeExecutorChanged(address(tradeExecutor), _tradeExecutor);
        tradeExecutor = ITradeExecutor(_tradeExecutor);
    }

    /// @notice Adds a trade executor, enabling it to execute trades.
    /// @param _yieldExecutor The address of _yieldExecutor contract.
    function addYieldExecutor(address _yieldExecutor) public {
        onlyGovernance();
        isValidAddress(_yieldExecutor);
        require(
            IYieldExecutor(_yieldExecutor).vault() == address(this),
            "INVALID_VAULT"
        );
        require(
            IERC20(wantToken).allowance(_yieldExecutor, address(this)) > 0,
            "NO_ALLOWANCE"
        );
        yieldExecutorsList.pushAddress(_yieldExecutor);
        emit YieldExecutorAdded(_yieldExecutor);
    }

    /// @notice Adds a trade executor, enabling it to execute trades.
    /// @param _yieldExecutor The address of _yieldExecutor contract.
    /// @dev make sure all funds are withdrawn from executor before removing.
    function removeYieldExecutor(address _yieldExecutor) public {
        onlyGovernance();
        isValidAddress(_yieldExecutor);
        // check if executor attached to vault.
        isActiveYieldExecutor(_yieldExecutor);
        IYieldExecutor(_yieldExecutor).checkReentrancy();
        (uint256 executorFunds, uint256 blockUpdated) = IYieldExecutor(
            _yieldExecutor
        ).totalFunds();
        _areFundsUpdated(blockUpdated);
        require(executorFunds < DUST_LIMIT, "FUNDS_TOO_HIGH");
        yieldExecutorsList.removeAddress(_yieldExecutor);
        emit YieldExecutorRemoved(_yieldExecutor);
    }

    /// @notice gives the number of yield executors.
    /// @return The number of yield executors.
    function totalYieldExecutors() public view returns (uint256) {
        return yieldExecutorsList.size();
    }

    /// @notice Returns yield executor at given index.
    /// @return The executor address at given valid index.
    function yieldExecutorByIndex(uint256 _index)
        public
        view
        returns (address)
    {
        return yieldExecutorsList.getAddressAtIndex(_index);
    }

    /// @notice Calculates funds held by all executors in want token.
    /// @return Sum of all funds held by executors.
    function totalYieldExecutorFunds() public view returns (uint256) {
        uint256 totalFunds = 0;
        for (uint256 i = 0; i < totalYieldExecutors(); i++) {
            address executor = yieldExecutorByIndex(i);
            (uint256 executorFunds, uint256 blockUpdated) = IYieldExecutor(
                executor
            ).totalFunds();
            _areFundsUpdated(blockUpdated);
            totalFunds += executorFunds;
        }
        return totalFunds;
    }

    /// @dev This will call a read reentrancy check on yield executors which support it
    /// If a YE does not support reentrancy check, it will return nothing
    function _checkReentrancyOnYieldExecutors() internal {
        for (uint256 i = 0; i < totalYieldExecutors(); i++) {
            address executor = yieldExecutorByIndex(i);
            IYieldExecutor(executor).checkReentrancy();
        }
    }

    /*///////////////////////////////////////////////////////////////
                    GOVERNANCE ACTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Nominates new governance address.
    /// @dev  Governance will only be changed if the new governance accepts it. It will be pending till then.
    /// @param _governance The address of new governance.
    function setGovernance(address _governance) public {
        onlyGovernance();
        pendingGovernance = _governance;
    }

    /// @notice Emitted when governance is updated.
    /// @param oldGovernance The address of the current governance.
    /// @param newGovernance The address of new governance.
    event UpdatedGovernance(
        address indexed oldGovernance,
        address indexed newGovernance
    );

    /// @notice The nomine of new governance address proposed by `setGovernance` function can accept the governance.
    /// @dev  This can only be called by address of pendingGovernance.
    function acceptGovernance() public {
        require(msg.sender == pendingGovernance, "INVALID_ADDRESS");
        emit UpdatedGovernance(governance, pendingGovernance);
        governance = pendingGovernance;
    }

    /// @notice Emitted when keeper is updated.
    /// @param oldKeeper The address of the old keeper.
    /// @param newKeeper The address of the new keeper.
    event UpdatedKeeper(address indexed oldKeeper, address indexed newKeeper);

    /// @notice Sets new keeper address.
    /// @dev  This can only be called by governance.
    /// @param _keeper The address of new keeper.
    function setKeeper(address _keeper) public {
        onlyGovernance();
        emit UpdatedKeeper(keeper, _keeper);
        keeper = _keeper;
    }

    /// @notice Emitted when emergencyMode status is updated.
    /// @param emergencyMode boolean indicating state of emergency.
    event EmergencyModeStatus(bool emergencyMode);

    /// @notice sets emergencyMode.
    /// @dev  This can only be called by governance.
    /// @param _emergencyMode if true, vault will be in emergency mode.
    function setEmergencyMode(bool _emergencyMode) public {
        onlyGovernance();
        emergencyMode = _emergencyMode;
        emit EmergencyModeStatus(_emergencyMode);
    }

    /// @notice sets deposit limit on vault
    /// @dev  This can only be called by governance.
    /// @param _maxDepositLimit max totalSupply of vault tokens
    function setDepositCapLimit(uint256 _maxDepositLimit) public {
        onlyGovernance();
        maxDepositLimit = _maxDepositLimit;
    }

    /// @notice Removes invalid tokens from the vault.
    /// @dev  This is used as fail safe to remove want tokens from the vault during emergency mode
    /// can be called by anyone to send funds to governance.
    /// @param _token The address of token to be removed.
    function sweep(address _token) public {
        isEmergencyMode();
        onlyGovernance();
        IERC20(_token).transfer(
            governance,
            IERC20(_token).balanceOf(address(this))
        );
    }

    /*///////////////////////////////////////////////////////////////
                    ACCESS MODIFERS
    //////////////////////////////////////////////////////////////*/
    /// @dev Checks if the sender is the governance.
    function onlyGovernance() internal view {
        require(msg.sender == governance, "ONLY_GOV");
    }

    /// @dev Checks if the sender is the keeper.
    function onlyKeeper() internal view {
        require(msg.sender == keeper, "ONLY_KEEPER");
    }

    /// @dev Checks if emergency mode is enabled.
    function isEmergencyMode() public view {
        require(emergencyMode, "EMERGENCY_MODE");
    }

    /// @dev Checks if emergency mode is enabled.
    function nonEmergencyMode() internal view {
        require(!emergencyMode, "EMERGENCY_MODE_ACTIVE");
    }

    /// @dev Checks if the address is valid.
    function isValidAddress(address _addr) internal pure {
        require(_addr != address(0), "NULL_ADDRESS");
    }

    /// @dev Checks if the yieldExecutor is valid.
    function isActiveYieldExecutor(address _yieldExecutor)
        public
        view
        override
    {
        require(yieldExecutorsList.exists(_yieldExecutor), "INVALID_EXECUTOR");
    }

    /// @dev Checks if funds are updated.
    function _areFundsUpdated(uint256 _blockUpdated) internal view {
        require(block.number == _blockUpdated, "FUNDS_NOT_UPDATED");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/cryptography/EIP712.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AddrArrayLib {
    using AddrArrayLib for Addresses;

    struct Addresses {
        address[] _items;
    }

    /**
     * @notice push an address to the array
     * @dev if the address already exists, it will not be added again
     * @param self Storage array containing address type variables
     * @param element the element to add in the array
     */
    function pushAddress(Addresses storage self, address element) internal {
        if (!exists(self, element)) {
            self._items.push(element);
        }
    }

    /**
     * @notice remove an address from the array
     * @dev finds the element, swaps it with the last element, and then deletes it;
     * @param self Storage array containing address type variables
     * @param element the element to remove from the array
     */
    function removeAddress(Addresses storage self, address element) internal {
        for (uint256 i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                self._items[i] = self._items[self.size() - 1];
                self._items.pop();
            }
        }
    }

    /**
     * @notice get the address at a specific index from array
     * @dev revert if the index is out of bounds
     * @param self Storage array containing address type variables
     * @param index the index in the array
     */
    function getAddressAtIndex(Addresses memory self, uint256 index)
        internal
        pure
        returns (address)
    {
        require(index < size(self), "INVALID_INDEX");
        return self._items[index];
    }

    /**
     * @notice get the size of the array
     * @param self Storage array containing address type variables
     */
    function size(Addresses memory self) internal pure returns (uint256) {
        return self._items.length;
    }

    /**
     * @notice check if an element exist in the array
     * @param self Storage array containing address type variables
     * @param element the element to check if it exists in the array
     */
    function exists(Addresses memory self, address element)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice get the array
     * @param self Storage array containing address type variables
     */
    function getAllAddresses(Addresses memory self)
        internal
        pure
        returns (address[] memory)
    {
        return self._items;
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

interface ITradeExecutor {
    function vault() external view returns (address);

    /// @notice Called to deposit asset into 3rd party protocol
    function initiateDeposit(bytes calldata _data) external;

    /// @notice Called for the process of removal of asset from 3rd party protocol
    function initiateWithdraw(bytes calldata _data)
        external
        returns (uint256 amountWithdrawn);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

interface IYieldExecutor {
    function vault() external view returns (address);

    // /// @notice Called to initiate the process of depositing of asset into 3rd party protocol
    // function initiateDeposit(bytes calldata _data) external;

    // /// @notice Called to initiate the process of removal of asset from 3rd party protocol
    // function initiateWithdraw(bytes calldata _data) external;

    function totalFunds()
        external
        view
        returns (
            // view
            uint256 posValue,
            uint256 lastUpdatedBlock
        );

    /// @dev send want token to executor and then call
    function depositIntoExecutor(uint256 amount)
        external
        returns (uint256 lpTokens);

    function withdrawfromExecutor(uint256 lpTokens)
        external
        returns (uint256 amountReturned);

    function lpValueInAsset(uint256 lpTokens) external view returns (uint256);

    function assetValueInLpToken(uint256 assets)
        external
        view
        returns (uint256);

    function totalLPTokens() external view returns (uint256);

    function maxSlippage() external view returns (uint256);

    function claimYield(bytes calldata _data) external returns (uint256 yield);

    function checkReentrancy() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IVault {
    function keeper() external view returns (address);

    function governance() external view returns (address);

    function wantToken() external view returns (address);

    function deposit(uint256 amountIn, address receiver)
        external
        payable
        returns (uint256 shares);

    function withdraw(uint256 sharesIn, address receiver)
        external
        returns (uint256 amountOut);

    function isEmergencyMode() external view;

    function isActiveYieldExecutor(address) external view;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}