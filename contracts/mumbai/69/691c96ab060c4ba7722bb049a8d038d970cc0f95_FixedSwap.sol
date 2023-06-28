// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "whitelist/interfaces/IWhitelist.sol";
import "./libs/AttoDecimal.sol";
import "./libs/FixedSwapErrors.sol";
import "./interfaces/IFixedSwap.sol";
import "solowei/TwoStageOwnable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/utils/math/Math.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract FixedSwap is IFixedSwap, ReentrancyGuard, TwoStageOwnable, AccessControl {
    using SafeERC20 for IERC20;
    using AttoDecimal for AttoDecimal.Instance;

    bytes32 public constant WITHDRAWAL_ROLE = keccak256("WITHDRAWAL_ROLE");

    bytes32 public constant FINOPS_ROLE = keccak256("FINOPS_ROLE");

    IWhitelist public whitelist;

    enum RedeemOption {
        IMMEDIATE,
        BONDING
    }

    enum Type {
        OPEN,
        CLOSE
    }

    struct Props {
        uint256 issuanceLimit;
        uint256 startsAt;
        uint256 endsAt;
        uint256 bondingPeriod;
        IERC20 paymentToken;
        IERC20 issuanceToken;
        AttoDecimal.Instance fee;
        AttoDecimal.Instance rate;
        bool isEther;
    }

    struct PoolClaimData {
        uint256 fundsDeposited;
        uint256 latestWithdrawalTs;
        mapping(address => bytes32) validUserClaims;
        mapping(address => uint256) userClaimableFunds;
    }

    struct UserClaimData {
        address user;
        uint256 amount;
    }

    struct AccountState {
        uint256 paymentSum;
    }

    struct Account {
        AccountState state;
        bool isLocked;
    }

    struct State {
        uint256 available;
        uint256 issuance;
        uint256 lockedPayments;
        uint256 unlockedPayments;
        uint256 paymentLimit;
        address nominatedOwner;
        address owner;
    }

    struct Pool {
        Type type_;
        uint256 index;
        Props props;
        State state;
        mapping(address => Account) accounts;
    }

    Pool[] private _pools;
    mapping(uint256 => PoolClaimData) private _poolClaimData;

    mapping(IERC20 => uint256) private _collectedFees;
    uint256 private _collectedEtherFees;

    uint8 private constant ETHER_DECIMALS = 18;

    modifier isValidPoolIndex(uint256 poolIndex) {
        if (poolIndex >= _pools.length) {
            revert FixedSwapErrors.FixedSwap__PoolIndexNonExistent(poolIndex, _pools.length);
        }
        _;
    }

    modifier onlyFinOps() {
        if (!hasRole(FINOPS_ROLE, msg.sender)) {
            revert FixedSwapErrors.FixedSwap__CallerNotAuthorized(msg.sender);
        }
        _;
    }

    /**
     * @dev Initializes the contract by setting an owner and a whitelist contract which serves the purpose of
     * whitelisting addresses allowed to deposit in all the pools.
     */
    constructor(address owner_, address whitelistContract_) TwoStageOwnable(owner_) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner_);
        _grantRole(FINOPS_ROLE, owner_);
        whitelist = IWhitelist(whitelistContract_);
    }

    /// @notice Creates a pool that does NOT have an end date (OPEN type)
    /// @dev Caller must be contract owner
    /// @param props Properties of the pool
    /// @param paymentLimit Payment limit (the maximum amount a user can deposit)
    /// @param owner_ Which address will be the owner of the pool
    function createOpenPool(
        Props memory props,
        uint256 paymentLimit,
        address owner_
    )
        external
        onlyOwner
        returns (bool success, uint256 poolIndex)
    {
        return (true, _createPool(props, paymentLimit, owner_, Type.OPEN).index);
    }

    /// @notice Creates a pool that has an end date (CLOSE type)
    /// @dev Caller must be contract owner
    /// @param props Properties of the pool
    /// @param paymentLimit Payment limit (the maximum amount a user can deposit)
    /// @param owner_ Which address will be the owner of the pool
    function createClosePool(
        Props memory props,
        uint256 paymentLimit,
        address owner_
    )
        external
        onlyOwner
        returns (bool success, uint256 poolIndex)
    {
        return (true, _createPool(props, paymentLimit, owner_, Type.CLOSE).index);
    }

    /// @notice Increases the number of issuance tokens the pool `poolIndex `owns
    /// @dev Caller must be pool owner
    /// @dev Caller must have approved this contract to transfer issuance tokens.
    /// @param poolIndex Index of the pool
    /// @param amount amount to increase issuance supply with
    function increaseIssuance(uint256 poolIndex, uint256 amount) external returns (bool success) {
        if (amount == 0) {
            revert FixedSwapErrors.FixedSwap__AmountIsZero();
        }
        Pool storage pool = _getPool(poolIndex);
        if (pool.type_ == Type.CLOSE && getTimestamp() >= pool.props.endsAt) {
            revert FixedSwapErrors.FixedSwap__PoolEnded(poolIndex);
        }
        address caller = msg.sender;
        _assertPoolOwnership(pool, caller);
        pool.state.issuance = pool.state.issuance + amount;
        if (pool.state.issuance > pool.props.issuanceLimit) {
            revert FixedSwapErrors.FixedSwap__IssuanceLimitExceeded(poolIndex);
        }
        pool.state.available = pool.state.available + amount;
        emit IssuanceIncreased(poolIndex, amount);
        pool.props.issuanceToken.safeTransferFrom(caller, address(this), amount);
        return true;
    }

    /// @notice Deposit to the pool `poolIndex`. The currency is an ERC-20 token and is the payment token configured to
    /// the pool.
    /// @dev User must be whitelisted
    /// @dev Pool must NOT be of type `ETHER`
    /// @param poolIndex Index of the pool
    /// @param requestedPaymentAmount request payment amount to deposit
    function swap(
        uint256 poolIndex,
        uint256 requestedPaymentAmount
    )
        external
        nonReentrant
        returns (uint256 paymentAmount, uint256 issuanceAmount)
    {
        if (requestedPaymentAmount == 0) {
            revert FixedSwapErrors.FixedSwap__RequestedPaymentAmountIsZero(poolIndex);
        }
        address caller = msg.sender;
        if (!whitelist.isWhitelisted(caller)) {
            revert FixedSwapErrors.FixedSwap__CallerNotWhitelisted(caller);
        }
        Pool storage pool = _getPool(poolIndex);
        if (pool.props.isEther) {
            revert FixedSwapErrors.FixedSwap__PoolIsEther(poolIndex);
        }
        uint256 timestamp = getTimestamp();
        if (timestamp < pool.props.startsAt) {
            revert FixedSwapErrors.FixedSwap__PoolNotStarted(poolIndex);
        }
        if (pool.type_ == Type.CLOSE && timestamp >= pool.props.endsAt) {
            revert FixedSwapErrors.FixedSwap__PoolEnded(poolIndex);
        }
        if (pool.state.available == 0) {
            revert FixedSwapErrors.FixedSwap__NoIssuanceAvailable(poolIndex);
        }
        (paymentAmount, issuanceAmount) = _calculateSwapAmounts(pool, requestedPaymentAmount, caller);
        Account storage account = pool.accounts[caller];
        if (paymentAmount > 0) {
            pool.state.lockedPayments = pool.state.lockedPayments + paymentAmount;
            account.state.paymentSum = account.state.paymentSum + paymentAmount;
            uint256 contractBalanceBefore = pool.props.paymentToken.balanceOf(address(this));
            pool.props.paymentToken.safeTransferFrom(caller, address(this), paymentAmount);
            if (contractBalanceBefore + paymentAmount != pool.props.paymentToken.balanceOf(address(this))) {
                revert FixedSwapErrors.FixedSwap__FailedToTransferCorrectPaymentTokenAmount();
            }
        }
        if (issuanceAmount > 0) {
            pool.props.issuanceToken.safeTransfer(caller, issuanceAmount);
            pool.state.available = pool.state.available - issuanceAmount;
        }
        emit Swap(poolIndex, caller, requestedPaymentAmount, paymentAmount, issuanceAmount);
    }

    /// @notice Deposit the native blockchain currency to the pool `poolIndex`
    /// @dev Msg data must be greater than 0
    /// @dev User must be whitelisted
    /// @dev Pool must be of type `ETHER`
    /// @param poolIndex Index of the pool
    function swapEther(uint256 poolIndex)
        external
        payable
        nonReentrant
        returns (uint256 paymentAmount, uint256 issuanceAmount)
    {
        if (msg.value == 0) {
            revert FixedSwapErrors.FixedSwap__RequestedPaymentAmountIsZero(poolIndex);
        }
        if (!whitelist.isWhitelisted(msg.sender)) {
            revert FixedSwapErrors.FixedSwap__CallerNotWhitelisted(msg.sender);
        }
        Pool storage pool = _getPool(poolIndex);
        if (!pool.props.isEther) {
            revert FixedSwapErrors.FixedSwap__PoolIsNotEther(poolIndex);
        }
        uint256 timestamp = getTimestamp();
        if (timestamp < pool.props.startsAt) {
            revert FixedSwapErrors.FixedSwap__PoolNotStarted(poolIndex);
        }
        if (pool.type_ == Type.CLOSE && timestamp >= pool.props.endsAt) {
            revert FixedSwapErrors.FixedSwap__PoolEnded(poolIndex);
        }
        if (pool.state.available == 0) {
            revert FixedSwapErrors.FixedSwap__NoIssuanceAvailable(poolIndex);
        }
        (paymentAmount, issuanceAmount) = _calculateSwapAmounts(pool, msg.value, msg.sender);
        Account storage account = pool.accounts[msg.sender];
        if (paymentAmount > 0) {
            pool.state.lockedPayments = pool.state.lockedPayments + paymentAmount;
            account.state.paymentSum = account.state.paymentSum + paymentAmount;
        }
        if (issuanceAmount > 0) {
            pool.props.issuanceToken.safeTransfer(msg.sender, issuanceAmount);
            pool.state.available = pool.state.available - issuanceAmount;
        }
        emit Swap(poolIndex, msg.sender, msg.value, paymentAmount, issuanceAmount);
    }

    /// @notice Request the deposited funds in `poolIndex` to be redeemed
    /// @dev Locks the user account so that he can't deposit more funds while the request is being approved
    /// @dev Account is unlocked after user claims the requested funds using `claimFunds` function
    /// @param poolIndex Index of the pool
    function requestRedeemFunds(uint256 poolIndex, RedeemOption request) external {
        Pool storage pool = _getPool(poolIndex);
        Account storage account = pool.accounts[msg.sender];
        // TODO: As per requirements, this should not be a check ?
        if (account.state.paymentSum == 0) {
            revert FixedSwapErrors.FixedSwap__NoFundsToRedeem(msg.sender, poolIndex);
        }
        account.isLocked = true;
        emit RequestRedeemFunds(msg.sender, poolIndex, account.state.paymentSum, request);
    }

    /// @notice Withdraws the total deposited funds (payment token or ether) of the pool `poolIndex` directly to the
    /// owner address
    /// @dev Caller must be pool owner
    /// @dev The pool must have collected payments in order to withdraw them successfully.
    /// @param poolIndex Index of the pool
    function withdrawPayments(uint256 poolIndex) external returns (bool success) {
        Pool storage pool = _getPool(poolIndex);
        address caller = msg.sender;
        _assertPoolOwnership(pool, caller);
        _unlockPayments(pool);
        uint256 collectedPayments = pool.state.unlockedPayments;
        if (collectedPayments == 0) {
            revert FixedSwapErrors.FixedSwap__NoCollectedPayments(poolIndex);
        }
        pool.state.unlockedPayments = 0;
        emit PaymentsWithdrawn(poolIndex, collectedPayments);
        if (pool.props.isEther) {
            (bool sent,) = caller.call{ value: collectedPayments }("");
            if (!sent) {
                revert FixedSwapErrors.FixedSwap__FailedToSendEther(poolIndex);
            }
        } else {
            pool.props.paymentToken.safeTransfer(caller, collectedPayments);
        }
        return true;
    }

    /// @notice Withdraws the total deposited funds (payment token or ether) of the pool `poolIndex` to a specified
    /// `destination`
    /// @dev Caller must have `WITHDRAWAL_ROLE`
    /// @dev This role is currently being given to a wallet address which is an OZ Defender Relayer
    /// @dev This is done with the purpose of automation. Try to withdraw the funds every X weeks if there is Y payment
    /// amount collected in the pool
    /// @dev The pool must have collected payments in order to withdraw them successfully
    /// @param poolIndex Index of the pool
    /// @param destination Destination address where the collected funds must arrive
    function withdrawPayments(uint256 poolIndex, address destination) external returns (bool success) {
        if (!hasRole(WITHDRAWAL_ROLE, msg.sender)) {
            revert FixedSwapErrors.FixedSwap__CallerNotAuthorized(msg.sender);
        }
        Pool storage pool = _getPool(poolIndex);
        _unlockPayments(pool);
        uint256 collectedPayments = pool.state.unlockedPayments;
        if (collectedPayments == 0) {
            revert FixedSwapErrors.FixedSwap__NoCollectedPayments(poolIndex);
        }
        pool.state.unlockedPayments = 0;
        emit PaymentsWithdrawn(poolIndex, collectedPayments);
        if (pool.props.isEther) {
            (bool sent,) = destination.call{ value: collectedPayments }("");
            if (!sent) {
                revert FixedSwapErrors.FixedSwap__FailedToSendEther(poolIndex);
            }
        } else {
            pool.props.paymentToken.safeTransfer(destination, collectedPayments);
        }
        return true;
    }

    /// @notice Withdraws any left amount of issuance tokens in the pool `poolIndex`
    /// `destionation`
    /// @dev Caller must have be pool owner
    /// @dev If the pool is of type `CLOSE`, pool must have ended
    /// @dev There must be some funds left in order for the transaction to be executed successfully
    /// @param poolIndex Index of the pool
    function withdrawUnsold(uint256 poolIndex) external returns (bool success) {
        Pool storage pool = _getPool(poolIndex);
        address caller = msg.sender;
        _assertPoolOwnership(pool, caller);
        if (pool.type_ == Type.CLOSE && getTimestamp() < pool.props.endsAt) {
            revert FixedSwapErrors.FixedSwap__PoolNotEnded(poolIndex);
        }
        uint256 amount = pool.state.available;
        if (amount == 0) {
            revert FixedSwapErrors.FixedSwap__NoUnsoldAvailable(poolIndex);
        }
        pool.state.available = 0;
        emit UnsoldWithdrawn(poolIndex, amount);
        pool.props.issuanceToken.safeTransfer(caller, amount);
        return true;
    }

    /// @notice Collect/prepare the fee of the pool (if not 0%) to be withdrawn. The fee is some % of the deposited
    /// payment tokens.
    /// @dev Caller must be contract owner
    /// @param poolIndex Index of the pool
    function collectFee(uint256 poolIndex) external onlyOwner returns (bool success) {
        _unlockPayments(_getPool(poolIndex));
        return true;
    }

    /// @notice Withdraw the collected ERC-20 payment token fee across all pools to the owner address
    /// @dev Caller must be contract owner
    /// @param token the ERC-20 payment token that is used as a paymentCurrency across 1 or more pools
    function withdrawFee(IERC20 token) external onlyOwner returns (bool success) {
        uint256 collectedFee = _collectedFees[token];
        if (collectedFee == 0) {
            revert FixedSwapErrors.FixedSwap__NoCollectedFees(address(token));
        }
        _collectedFees[token] = 0;
        emit FeeWithdrawn(address(token), collectedFee);
        token.safeTransfer(owner(), collectedFee);
        return true;
    }

    /// @notice Withdraw the collected ETHER fee of the pool to the owner address
    /// @dev Caller must be contract owner
    function withdrawFee() external onlyOwner returns (bool success) {
        if (_collectedEtherFees == 0) {
            revert FixedSwapErrors.FixedSwap__NoCollectedEtherFees();
        }
        uint256 feeToWithdraw = _collectedEtherFees;
        _collectedEtherFees = 0;
        (bool sent,) = owner().call{ value: feeToWithdraw }("");
        if (!sent) {
            revert FixedSwapErrors.FixedSwap__FailedToWithdrawEtherFee();
        }
        emit FeeWithdrawn(address(0), feeToWithdraw);
        return true;
    }

    /// @notice Nominates a new owner address for the pool `poolIndex`
    /// @notice The nominated owner must accept the ownership through `acceptPoolOwnership` to actually become the owner
    /// @dev Caller must be pool owner
    /// @dev Nominated owner must not be the current owner and must not be the already nominated owner (if != zero
    /// address)
    /// @param poolIndex Index of the pool
    /// @param nominatedOwner_ Address of the owner to be nominated
    function nominateNewPoolOwner(uint256 poolIndex, address nominatedOwner_) external returns (bool success) {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolOwnership(pool, msg.sender);
        if (nominatedOwner_ == pool.state.owner) {
            revert FixedSwapErrors.FixedSwap__NominatedOwnerAlreadyOwner(nominatedOwner_);
        }
        if (pool.state.nominatedOwner == nominatedOwner_) return true;
        pool.state.nominatedOwner = nominatedOwner_;
        emit PoolOwnerNominated(poolIndex, nominatedOwner_);
        return true;
    }

    /// @notice Accepts ownership of the pool `poolIndex`
    /// @dev Caller must be the nominated owner
    /// @param poolIndex Index of the pool
    function acceptPoolOwnership(uint256 poolIndex) external returns (bool success) {
        Pool storage pool = _getPool(poolIndex);
        address caller = msg.sender;
        if (pool.state.nominatedOwner != caller) {
            revert FixedSwapErrors.FixedSwap__NotNominatedForPoolOwnership();
        }
        pool.state.owner = caller;
        pool.state.nominatedOwner = address(0);
        emit PoolOwnerChanged(poolIndex, caller);
        return true;
    }

    function _assertPoolOwnership(Pool storage pool, address account) private view {
        if (account != pool.state.owner) {
            revert FixedSwapErrors.FixedSwap__CallerNotAuthorized(account);
        }
    }

    function _calculateSwapAmounts(
        Pool storage pool,
        uint256 requestedPaymentAmount,
        address account
    )
        private
        view
        returns (uint256 paymentAmount, uint256 issuanceAmount)
    {
        paymentAmount = requestedPaymentAmount;
        Account storage poolAccount_ = pool.accounts[account];
        uint256 paymentLimit = pool.state.paymentLimit;
        uint8 decimals = pool.props.isEther ? ETHER_DECIMALS : ERC20(address(pool.props.paymentToken)).decimals();
        if (poolAccount_.state.paymentSum >= paymentLimit) {
            // TODO: Maybe only == is enough ?
            revert FixedSwapErrors.FixedSwap__AccountPaymentLimitExceeded();
        }
        if (poolAccount_.state.paymentSum + paymentAmount > paymentLimit) {
            paymentAmount = paymentLimit - poolAccount_.state.paymentSum;
        }
        issuanceAmount = pool.props.rate.mul(paymentAmount).floor(decimals);
        if (issuanceAmount > pool.state.available) {
            issuanceAmount = pool.state.available;
            paymentAmount = AttoDecimal.div(issuanceAmount, pool.props.rate, decimals).ceil(decimals);
        }
    }

    function _getPool(uint256 index) private view returns (Pool storage) {
        if (index >= _pools.length) {
            revert FixedSwapErrors.FixedSwap__PoolIndexNonExistent(index, _pools.length);
        }
        return _pools[index];
    }

    function _createPool(
        Props memory props,
        uint256 paymentLimit,
        address owner_,
        Type type_
    )
        private
        returns (Pool storage)
    {
        {
            if (props.isEther && address(props.paymentToken) != address(0)) {
                revert FixedSwapErrors.FixedSwap__NonZeroPaymentTokenInEtherPool();
            }
            uint256 timestamp = getTimestamp();
            uint8 decimals = props.isEther ? ETHER_DECIMALS : ERC20(address(props.paymentToken)).decimals();
            if (decimals == 0) {
                revert FixedSwapErrors.FixedSwap__PaymentTokenDecimalsAreZero();
            }
            if (props.startsAt < timestamp) props.startsAt = timestamp;
            if (props.fee.gte(1, decimals)) {
                revert FixedSwapErrors.FixedSwap__FeeGreaterThanEqual100Percent();
            }
            if (type_ == Type.CLOSE) {
                if (props.startsAt >= props.endsAt) {
                    revert FixedSwapErrors.FixedSwap__InvalidEndingTimestamp();
                }
            } else {
                if (props.endsAt != 0) {
                    revert FixedSwapErrors.FixedSwap__OpenPoolHasNonZeroEndDate();
                }
            }
        }
        uint256 poolIndex = _pools.length;
        _pools.push();
        Pool storage pool = _pools[poolIndex];
        pool.index = poolIndex;
        pool.type_ = type_;
        pool.props = props;
        pool.state.paymentLimit = paymentLimit;
        pool.state.owner = owner_;
        emit PoolCreated(
            type_,
            props.paymentToken,
            props.issuanceToken,
            poolIndex,
            props.issuanceLimit,
            props.startsAt,
            props.endsAt,
            props.fee.mantissa,
            props.rate.mantissa,
            paymentLimit
        );
        emit PoolOwnerChanged(poolIndex, owner_);
        return pool;
    }

    function _unlockPayments(Pool storage pool) private {
        if (pool.state.lockedPayments == 0) return;
        bool isEther = pool.props.isEther;
        uint8 decimals;
        if (isEther) {
            decimals = ETHER_DECIMALS;
        } else {
            decimals = ERC20(address(pool.props.paymentToken)).decimals();
        }
        uint256 fee = pool.props.fee.mul(pool.state.lockedPayments).ceil(decimals);
        if (isEther) {
            _collectedEtherFees += fee;
        } else {
            _collectedFees[pool.props.paymentToken] = _collectedFees[pool.props.paymentToken] + fee;
        }
        uint256 unlockedAmount = pool.state.lockedPayments - fee;
        pool.state.unlockedPayments = pool.state.unlockedPayments + unlockedAmount;
        pool.state.lockedPayments = 0;
        emit PaymentUnlocked(pool.index, unlockedAmount, fee);
    }

    /// @notice Change the whitelist contract address used to reference eligible users to deposit in the pools
    /// @dev Caller must be contract owner
    /// @param _newWhitelistAddress Address of the new whitelist contract
    function changeWhitelistAddress(address _newWhitelistAddress) external onlyOwner {
        if (_newWhitelistAddress == address(0)) {
            revert FixedSwapErrors.FixedSwap__ZeroAddress();
        }
        emit WhitelistContractChanged(address(whitelist), _newWhitelistAddress);
        whitelist = IWhitelist(_newWhitelistAddress);
    }

    /// @notice Deposit ERC-20 funds in the pool that will later be claimable by a user
    /// @dev Only triggerable by FinOps
    /// @param poolIndex Index of the pool
    /// @param amount Amount to deposit in the pool
    function depositFunds(uint256 poolIndex, uint256 amount) external onlyFinOps isValidPoolIndex(poolIndex) {
        if (isEtherPool(poolIndex)) {
            revert FixedSwapErrors.FixedSwap__PoolIsEther(poolIndex);
        }
        if (amount == 0) {
            revert FixedSwapErrors.FixedSwap__ZeroDepositFunds();
        }
        _poolClaimData[poolIndex].fundsDeposited += amount;
        (, Props memory props) = poolProps(poolIndex);
        props.paymentToken.safeTransferFrom(msg.sender, address(this), amount);
        emit FundsDeposited(poolIndex, msg.sender, amount);
    }

    /// @notice Deposit ETH in the pool that will later be claimable by a user
    /// @dev Only triggerable by FinOps
    /// @dev requires msg.value > 0 in order not to revert
    /// @param poolIndex Index of the pool in FixedSwap contract
    function depositEther(uint256 poolIndex) external payable onlyFinOps isValidPoolIndex(poolIndex) {
        if (!isEtherPool(poolIndex)) {
            revert FixedSwapErrors.FixedSwap__PoolIsNotEther(poolIndex);
        }
        if (msg.value == 0) {
            revert FixedSwapErrors.FixedSwap__ZeroDepositFunds();
        }
        _poolClaimData[poolIndex].fundsDeposited += msg.value;
        emit FundsDeposited(poolIndex, msg.sender, msg.value);
    }

    /// @notice Whitelist an address to be able to authorize as a FinOps
    /// @dev Can only be called by the owner
    /// @param finOpsAddresses Array of addresses to be whitelisted
    function whitelistFinOpsAddresses(address[] calldata finOpsAddresses) external onlyOwner {
        uint256 lenAddresses = finOpsAddresses.length;
        for (uint256 i = 0; i < lenAddresses;) {
            _grantRole(FINOPS_ROLE, finOpsAddresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Remove an address so that it can no longer be authorized as FinOps
    /// @dev Can only be called by the owner
    /// @param finOpsAddresses Array of addresses to be blacklisted
    function removeWhitelistedFinOpsAddresses(address[] calldata finOpsAddresses) external onlyOwner {
        uint256 lenAddresses = finOpsAddresses.length;
        for (uint256 i = 0; i < lenAddresses;) {
            _revokeRole(FINOPS_ROLE, finOpsAddresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Marks the users that are eligible to claim funds from a pool
    /// @dev Can only be called by the owner
    /// @dev The reason why there is not a non-zero claim amount check is because the function can be used to reset user
    /// claim balance
    /// @param poolIndex Index of the pool in FixedSwap contract
    /// @param userData Array of {userAddress, amount} objects that's mapped to a user address and his eligible amount
    /// to claim
    function setFundsClaimable(
        uint256 poolIndex,
        UserClaimData[] calldata userData
    )
        external
        onlyOwner
        isValidPoolIndex(poolIndex)
    {
        uint256 dataLen = userData.length;
        for (uint256 i = 0; i < dataLen;) {
            address userAddress = userData[i].user;
            uint256 amount = userData[i].amount;
            if (userAddress == address(0)) {
                revert FixedSwapErrors.FixedSwap__InvalidClaimableUser(address(0));
            }
            _poolClaimData[poolIndex].userClaimableFunds[userAddress] = amount;
            _poolClaimData[poolIndex].validUserClaims[userAddress] =
                keccak256(abi.encodePacked(userAddress, poolIndex, _poolClaimData[poolIndex].latestWithdrawalTs));
            unchecked {
                ++i;
            }
        }
        emit FundsClaimableSet(poolIndex, msg.sender);
    }

    /// @notice Claims all the funds that are eligible to be claimed by the user
    /// @dev If the claiming funds are from a redeem request, the function unlocks the user account to be able to
    /// deposit again
    /// @dev Burns the exact same number of user's issuance tokens that he has deposited
    /// @dev Therefore user (msg.sender) must own them
    /// @param poolIndex Index of the pool
    function claimFunds(uint256 poolIndex) external isValidPoolIndex(poolIndex) {
        uint256 claimAmount = _poolClaimData[poolIndex].userClaimableFunds[msg.sender];
        if (claimAmount == 0) {
            revert FixedSwapErrors.FixedSwap__NoFundsToClaim(poolIndex, msg.sender);
        }
        bool isEthPool = isEtherPool(poolIndex);
        bytes32 userClaimHash =
            keccak256(abi.encodePacked(msg.sender, poolIndex, _poolClaimData[poolIndex].latestWithdrawalTs));
        if (userClaimHash != _poolClaimData[poolIndex].validUserClaims[msg.sender]) {
            revert FixedSwapErrors.FixedSwap__InvalidClaimHash(msg.sender, poolIndex);
        }

        _poolClaimData[poolIndex].userClaimableFunds[msg.sender] = 0;
        _poolClaimData[poolIndex].fundsDeposited -= claimAmount;

        Pool storage pool = _getPool(poolIndex);
        Account storage account = pool.accounts[msg.sender];
        if (account.isLocked) {
            account.isLocked = false;
        }
        ERC20Burnable(address(pool.props.issuanceToken)).burnFrom(msg.sender, account.state.paymentSum);
        if (isEthPool) {
            (bool sent,) = msg.sender.call{ value: claimAmount }("");
            if (!sent) {
                revert FixedSwapErrors.FixedSwap__FailedToSendEther(poolIndex);
            }
        } else {
            (, Props memory props) = poolProps(poolIndex);
            props.paymentToken.safeTransfer(msg.sender, claimAmount);
        }
        emit FundsClaimed(poolIndex, msg.sender, claimAmount);
    }

    /// @notice Claims all the left funds in a pool. This is to be called by FinOps in case users don't claim their
    /// funds on a long period of time
    /// @dev Resets the valid claim timestamp of the pool, so all users who have not claimed their funds until then,
    /// will not be able to claim them anymore
    /// @dev only triggerable by FinOps
    /// @param poolIndex Index of the pool
    function withDrawPoolUnclaimedFunds(uint256 poolIndex) external onlyFinOps isValidPoolIndex(poolIndex) {
        bool isEthPool = isEtherPool(poolIndex);
        uint256 amount = _poolClaimData[poolIndex].fundsDeposited;
        _poolClaimData[poolIndex].fundsDeposited = 0;
        _poolClaimData[poolIndex].latestWithdrawalTs = block.timestamp; // Reset the timestamp to the current block
        // timestamp so that all users trying to claim after this will fail
        if (isEthPool) {
            (bool sent,) = msg.sender.call{ value: amount }("");
            if (!sent) {
                revert FixedSwapErrors.FixedSwap__FailedToSendEther(poolIndex);
            }
        } else {
            (, Props memory props) = poolProps(poolIndex);
            props.paymentToken.safeTransfer(msg.sender, amount);
        }
        emit UnClaimedFundsWithdrawn(poolIndex, msg.sender, amount);
    }

    /// @dev Returns the current block timestamp
    function getTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @notice Returns the total number of pools that ever existed in the contract
    function poolsCount() public view returns (uint256) {
        return _pools.length;
    }

    /// @notice Returns the properties of the pool `poolIndex`
    function poolProps(uint256 poolIndex) public view returns (Type type_, Props memory props) {
        Pool storage pool = _getPool(poolIndex);
        return (pool.type_, pool.props);
    }

    /// @notice Returns the state of the pool `poolIndex`
    function poolState(uint256 poolIndex) public view returns (State memory state) {
        return _getPool(poolIndex).state;
    }

    /// @notice Returns a boolean of whether a pool is type ether or not
    function isEtherPool(uint256 poolIndex) public view returns (bool isEthPool) {
        return _getPool(poolIndex).props.isEther;
    }

    /// @notice Returns the state of a user account for the pool `poolIndex`
    function poolAccount(
        uint256 poolIndex,
        address address_
    )
        public
        view
        returns (Type type_, AccountState memory state)
    {
        Pool storage pool = _getPool(poolIndex);
        return (pool.type_, pool.accounts[address_].state);
    }

    /// @notice Returns the total collected amount of fees for a particular payment token across all pools
    /// @dev Used for non-ETH pools
    function collectedFees(IERC20 token) public view returns (uint256) {
        return _collectedFees[token];
    }

    /// @notice Returns the total ether (in wei) collected as fees from all the pools
    /// @dev Used for ETH pools
    function collectedEtherFees() public view returns (uint256) {
        return _collectedEtherFees;
    }

    /// @notice Returns the total deposited funds in a pool (both ETH and non-ETH pools)
    /// @param poolIndex Index of the pool
    function getPoolFundsDeposited(uint256 poolIndex) external view returns (uint256) {
        return _poolClaimData[poolIndex].fundsDeposited;
    }

    /// @notice Returns the total funds a user is allowed to claim
    /// @param poolIndex Index of the pool
    /// @param user wallet address
    function getUserClaimableFunds(uint256 poolIndex, address user) external view returns (uint256) {
        bytes32 currentHash = keccak256(abi.encodePacked(user, poolIndex, _poolClaimData[poolIndex].latestWithdrawalTs));
        bytes32 latestValidUserHash = _poolClaimData[poolIndex].validUserClaims[user];
        if (currentHash != latestValidUserHash) {
            return 0;
        }
        return _poolClaimData[poolIndex].userClaimableFunds[user];
    }

    /// @notice Returns the total funds a user is allowed to claim
    /// @param poolIndex Index of the pool
    /// @param user wallet address
    function isAccountLocked(
        uint256 poolIndex,
        address user
    )
        external
        view
        isValidPoolIndex(poolIndex)
        returns (bool isLocked)
    {
        return _pools[poolIndex].accounts[user].isLocked;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWhitelist {
    function addWallets(address[] calldata wallets) external;

    function removeWallets(address[] calldata wallets) external;

    function isWhitelisted(address wallet) external view returns (bool);

    event AddressesWhitelisted(address caller);
    event AddressesBlacklisted(address caller);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library AttoDecimal {
    struct Instance {
        uint256 mantissa;
    }

    uint256 constant BASE = 10;

    function ONE_MANTISSA(uint8 decimals) internal pure returns (uint256) {
        return BASE ** decimals;
    }

    function SQUARED_ONE_MANTISSA(uint8 decimals) internal pure returns (uint256) {
        return ONE_MANTISSA(decimals) * ONE_MANTISSA(decimals);
    }

    function MAX_INTEGER(uint8 decimals) internal pure returns (uint256) {
        return type(uint256).max / ONE_MANTISSA(decimals);
    }

    function mul(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({ mantissa: a.mantissa * b });
    }

    function div(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({ mantissa: a.mantissa / b });
    }

    function div(uint256 a, Instance memory b, uint8 decimals) internal pure returns (Instance memory) {
        return Instance({ mantissa: (a * SQUARED_ONE_MANTISSA(decimals)) / b.mantissa });
    }

    function floor(Instance memory a, uint8 decimals) internal pure returns (uint256) {
        return a.mantissa / ONE_MANTISSA(decimals);
    }

    function ceil(Instance memory a, uint8 decimals) internal pure returns (uint256) {
        return (a.mantissa / ONE_MANTISSA(decimals)) + (a.mantissa % ONE_MANTISSA(decimals) > 0 ? 1 : 0);
    }

    function eq(Instance memory a, uint256 b, uint8 decimals) internal pure returns (bool) {
        if (b > MAX_INTEGER(decimals)) return false;
        return a.mantissa == b * ONE_MANTISSA(decimals);
    }

    function gt(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa > b.mantissa;
    }

    function gte(Instance memory a, uint256 b, uint8 decimals) internal pure returns (bool) {
        // TODO: Do we need if (a > MAX_INTEGER(decimals)) return true; here ?
        return a.mantissa >= (b * (ONE_MANTISSA(decimals)));
    }

    function lt(Instance memory a, uint256 b, uint8 decimals) internal pure returns (bool) {
        if (b > MAX_INTEGER(decimals)) return true;
        return a.mantissa < (b * (ONE_MANTISSA(decimals)));
    }

    function lt(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa < b.mantissa;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library FixedSwapErrors {
    error FixedSwap__RequestedPaymentAmountIsZero(uint256 poolIndex);
    error FixedSwap__CallerNotWhitelisted(address caller);
    error FixedSwap__PoolIsNotEther(uint256 poolIndex);
    error FixedSwap__PoolIsEther(uint256 poolIndex);
    error FixedSwap__NoFundsToRedeem(address user, uint256 poolIndex);
    error FixedSwap__AmountIsZero();
    error FixedSwap__PoolNotStarted(uint256 poolIndex);
    error FixedSwap__PoolEnded(uint256 poolIndex);
    error FixedSwap__PoolNotEnded(uint256 poolIndex);
    error FixedSwap__InvalidEndingTimestamp();
    error FixedSwap__IssuanceLimitExceeded(uint256 poolIndex);
    error FixedSwap__NoIssuanceAvailable(uint256 poolIndex);
    error FixedSwap__NoUnsoldAvailable(uint256 poolIndex);
    error FixedSwap__NoCollectedPayments(uint256 poolIndex);
    error FixedSwap__NoCollectedFees(address token);
    error FixedSwap__NoCollectedEtherFees();
    error FixedSwap__FailedToSendEther(uint256 poolIndex);
    error FixedSwap__FailedToWithdrawEtherFee();
    error FixedSwap__NotNominatedForPoolOwnership();
    error FixedSwap__NominatedOwnerAlreadyOwner(address owner);
    error FixedSwap__FeeGreaterThanEqual100Percent();
    error FixedSwap__ZeroAddress();
    error FixedSwap__AccountPaymentLimitExceeded();
    error FixedSwap__PaymentTokenDecimalsAreZero();
    error FixedSwap__OpenPoolHasNonZeroEndDate();
    error FixedSwap__NonZeroPaymentTokenInEtherPool();
    error FixedSwap__FailedToTransferCorrectPaymentTokenAmount();
    error FixedSwap__CallerNotAuthorized(address caller);
    error FixedSwap__NoFundsToClaim(uint256 poolIndex, address user);
    error FixedSwap__PoolIndexNonExistent(uint256 poolIndex, uint256 poolsCount);
    error FixedSwap__ZeroClaimFunds(address user);
    error FixedSwap__InvalidClaimHash(address user, uint256 poolIndex);
    error FixedSwap__InvalidClaimableUser(address user);
    error FixedSwap__ZeroDepositFunds();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../FixedSwap.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

interface IFixedSwap {
    function depositFunds(uint256 poolIndex, uint256 amount) external;

    function whitelistFinOpsAddresses(address[] memory finOpsAddresses) external;

    function removeWhitelistedFinOpsAddresses(address[] memory finOpsAddresses) external;

    function setFundsClaimable(uint256 poolIndex, FixedSwap.UserClaimData[] calldata userData) external;

    function claimFunds(uint256 poolIndex) external;

    function withDrawPoolUnclaimedFunds(uint256 poolIndex) external;

    function getPoolFundsDeposited(uint256 poolIndex) external view returns (uint256);

    function getUserClaimableFunds(uint256 poolIndex, address user) external view returns (uint256);

    function poolsCount() external view returns (uint256);

    function poolProps(uint256 poolIndex) external view returns (FixedSwap.Type type_, FixedSwap.Props memory props);

    function poolState(uint256 poolIndex) external view returns (FixedSwap.State memory state);

    function isEtherPool(uint256 poolIndex) external view returns (bool isEtherPool);

    function poolAccount(
        uint256 poolIndex,
        address address_
    )
        external
        view
        returns (FixedSwap.Type type_, FixedSwap.AccountState memory state);

    function collectedFees(IERC20 token) external view returns (uint256);

    function collectedEtherFees() external view returns (uint256);

    function createOpenPool(
        FixedSwap.Props memory props,
        uint256 paymentLimit,
        address owner_
    )
        external
        returns (bool success, uint256 poolIndex);

    function createClosePool(
        FixedSwap.Props memory props,
        uint256 paymentLimit,
        address owner_
    )
        external
        returns (bool success, uint256 poolIndex);

    function increaseIssuance(uint256 poolIndex, uint256 amount) external returns (bool success);

    function swap(
        uint256 poolIndex,
        uint256 requestedPaymentAmount
    )
        external
        returns (uint256 paymentAmount, uint256 issuanceAmount);

    function swapEther(uint256 poolIndex) external payable returns (uint256 paymentAmount, uint256 issuanceAmount);

    function requestRedeemFunds(uint256 poolIndex, FixedSwap.RedeemOption request) external;

    function withdrawPayments(uint256 poolIndex) external returns (bool success);

    function withdrawPayments(uint256 poolIndex, address destination) external returns (bool success);

    function withdrawUnsold(uint256 poolIndex) external returns (bool success);

    function collectFee(uint256 poolIndex) external returns (bool success);

    function withdrawFee(IERC20 token) external returns (bool success);

    function withdrawFee() external returns (bool success);

    function nominateNewPoolOwner(uint256 poolIndex, address nominatedOwner_) external returns (bool success);

    function acceptPoolOwnership(uint256 poolIndex) external returns (bool success);

    function changeWhitelistAddress(address _newWhitelistAddress) external;

    event FundsClaimed(uint256 indexed poolIndex, address indexed user, uint256 indexed amount);
    event FundsClaimableSet(uint256 poolIndex, address caller);
    event FundsDeposited(uint256 poolIndex, address finOps, uint256 amount);
    event UnClaimedFundsWithdrawn(uint256 poolIndex, address caller, uint256 amount);
    event FixedSwapAddressChanged(address caller, address newAddress);

    event AccountLimitChanged(uint256 indexed poolIndex, address indexed address_, uint256 indexed limitIndex);
    event FeeWithdrawn(address indexed token, uint256 amount);
    event IssuanceIncreased(uint256 indexed poolIndex, uint256 amount);
    event PaymentLimitCreated(uint256 indexed poolIndex, uint256 indexed limitIndex, uint256 limit);
    event PaymentLimitChanged(uint256 indexed poolIndex, uint256 indexed limitIndex, uint256 newLimit);
    event PaymentUnlocked(uint256 indexed poolIndex, uint256 unlockedAmount, uint256 collectedFee);
    event PaymentsWithdrawn(uint256 indexed poolIndex, uint256 amount);
    event PoolOwnerChanged(uint256 indexed poolIndex, address indexed newOwner);
    event PoolOwnerNominated(uint256 indexed poolIndex, address indexed nominatedOwner);
    event UnsoldWithdrawn(uint256 indexed poolIndex, uint256 amount);
    event WhitelistContractChanged(address oldAddress, address newAddress);

    event PoolCreated(
        FixedSwap.Type type_,
        IERC20 indexed paymentToken,
        IERC20 indexed issuanceToken,
        uint256 poolIndex,
        uint256 issuanceLimit,
        uint256 startsAt,
        uint256 endsAt,
        uint256 fee,
        uint256 rate,
        uint256 paymentLimit
    );

    event Swap(
        uint256 indexed poolIndex,
        address indexed caller,
        uint256 requestedPaymentAmount,
        uint256 paymentAmount,
        uint256 issuanceAmount
    );

    event RequestRedeemFunds(address user, uint256 poolIndex, uint256 requestedAmount, FixedSwap.RedeemOption request);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

abstract contract TwoStageOwnable {
    address private _nominatedOwner;
    address private _owner;

    function nominatedOwner() public view returns (address) {
        return _nominatedOwner;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    event OwnerChanged(address indexed newOwner);
    event OwnerNominated(address indexed nominatedOwner);

    constructor(address owner_) {
        require(owner_ != address(0), "Owner is zero");
        _setOwner(owner_);
    }

    function acceptOwnership() external returns (bool success) {
        require(msg.sender == _nominatedOwner, "Not nominated to ownership");
        _setOwner(_nominatedOwner);
        return true;
    }

    function nominateNewOwner(address owner_) external onlyOwner returns (bool success) {
        _nominateNewOwner(owner_);
        return true;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    function _nominateNewOwner(address owner_) internal {
        if (_nominatedOwner == owner_) return;
        require(_owner != owner_, "Already owner");
        _nominatedOwner = owner_;
        emit OwnerNominated(owner_);
    }

    function _setOwner(address newOwner) internal {
        if (_owner == newOwner) return;
        _owner = newOwner;
        _nominatedOwner = address(0);
        emit OwnerChanged(newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
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
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}