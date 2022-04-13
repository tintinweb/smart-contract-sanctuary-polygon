// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IChildERC20} from "./external/IChildERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ISaver} from "@orionterra/core/contracts/ISaver.sol";
import {IStableRateFeeder} from "./external/IStableRateFeeder.sol";
import {IWormhole} from "./external/IWormhole.sol";

// TODO: withdrawLocal restrictions
// TODO: canDepositLocal/canWithdrawLocal
contract ChildChainConnector is Initializable, AccessControlUpgradeable, ISaver {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Balance {
        uint256 originalAmount;
        uint256 orionedAmount;
    }

    struct TokenInfo {
        address rootToken;
        IStableRateFeeder orionRateFeeder;
        uint256 tenPowDecimals;
    }

    struct WithdrawOperation {
        IERC20 token;
        address investor;
        uint256 requestedAmount;
        uint256 requestedOrionedAmount;
    }

    event AddToken(address token, address rootToken, address orionRateFeeder, uint256 tenPowDecimals);
    event UpdateToken(address token, address rootToken, address orionRateFeeder, uint256 tenPowDecimals);
    event RemoveToken(address token, address rootToken, address orionRateFeeder, uint256 tenPowDecimals);
    event Deposit(address token, address investor, uint256 originalAmount, uint256 orionedAmount);
    event WithdrawInit(uint32 index, address token, address investor, uint256 requestedAmount, uint256 requestedOrionedAmount);
    event WithdrawLocal(address token, address investor, uint256 requestedAmount, uint256 requestedOrionedAmount);
    event WithdrawFinalized(uint32 index);
    event TransferFinalized(address token);
    event SetTransferBuffer(address transferBuffer);
    event SetDepositLimit(uint256 depositLimit);
    event SetDepositMinTransferLimit(uint256 depositMinTransferLimit);
    event SetDepositMaxTransferLimit(uint256 depositMaxTransferLimit);
    event SetWithdrawLimit(uint256 withdrawLimit);
    event SetWithdrawMinTransferLimit(uint256 withdrawMinTransferLimit);
    event SetWithdrawMaxTransferLimit(uint256 withdrawMaxTransferLimit);
    event SetWithdrawLocalLimit(uint256 withdrawLocalLimit);
    event SetLocalPoolSize(uint256 localPoolSize);
    event SetWithdrawFee(uint256 minFee, uint256 maxFee, uint256 feeFractionNumerator);
    event DepositToEthereum(address token, uint256 amount);
    event WithdrawFromEthereum(address token, uint256 amount);
    event ResetWithdrawFromEthereum(address token, uint256 amount);
    event PublishMessage(address token, uint256 amount, uint32 nonce, uint64 sequence);

    modifier only(bytes32 role) {
        require(hasRole(role, msg.sender), "INSUFFICIENT_PERMISSIONS");
        _;
    }

    modifier withToken(IERC20 token) {
        require(tokens[token].rootToken != address(0), "token not added");
        _;
    }

    modifier withTransferBuffer {
        require(transferBuffer != address(0), "transferBuffer not set");
        _;
    }

    modifier nonReentrant {
        require(!reentrancyGuard, "ReentrancyGuard: reentrant call");
        reentrancyGuard = true;
        _;
        reentrancyGuard = false;
    }

    IWormhole private wormhole;
    uint32 private wormholeNonce;

    uint32 private woLeftPointer;
    uint32 private woRightPointer;

    uint256 private depositLimit;
    uint256 private depositMinTransferLimit;
    uint256 private depositMaxTransferLimit;

    uint256 private withdrawLimit;
    uint256 private withdrawMinTransferLimit;
    uint256 private withdrawMaxTransferLimit;
    uint256 private withdrawLocalLimit;

    uint256 private localPoolSize;

    uint256 private minFee;
    uint256 private maxFee;
    uint256 private feeFractionNumerator;
    uint256 constant feeFractionDenominator = 100_000;

    mapping(IERC20 => TokenInfo) private tokens;
    mapping(IERC20 => mapping(address => Balance)) private balances;
    mapping(IERC20 => uint256) private totalOrionedSum;
    mapping(uint32 => WithdrawOperation) private withdrawOperations;
    mapping(IERC20 => mapping(address => uint32)) private activeWithdrawOperations;
    mapping(IERC20 => uint256) private activeWithdrawOperationsSum;
    mapping(IERC20 => uint256) private pendingWithdrawOperationsSum;
    mapping(IERC20 => uint256) private requestedWithdrawOperationsSum;

    address private transferBuffer;

    bool private reentrancyGuard;

    function initialize(address _wormhole) public initializer {
        wormhole = IWormhole(_wormhole);
        wormholeNonce = 0;

        woLeftPointer = 1;
        woRightPointer = 1;

        depositLimit = 5_000;
        depositMinTransferLimit = 100_000;
        depositMaxTransferLimit = 1_000_000;

        withdrawLimit = 2_500;
        withdrawMinTransferLimit = 100_000;
        withdrawMaxTransferLimit = 1_000_000;
        withdrawLocalLimit = 1_000;

        localPoolSize = 5_000;

        minFee = 1;
        maxFee = 1000;
        feeFractionNumerator = 100;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /*
        ------------------------------------------------------------------------------------------------
                                        CONFIGURATION FUNCTIONS
        ------------------------------------------------------------------------------------------------
    */

    function addToken(
        IERC20 token,
        address rootToken,
        IStableRateFeeder orionRateFeeder,
        uint8 decimals
    ) external only(DEFAULT_ADMIN_ROLE) {
        require(tokens[token].rootToken == address(0), "token already added");

        tokens[token].rootToken = rootToken;
        tokens[token].orionRateFeeder = orionRateFeeder;
        tokens[token].tenPowDecimals = 10 ** uint256(decimals);

        emit AddToken(
            address(token),
            rootToken,
            address(orionRateFeeder),
            tokens[token].tenPowDecimals
        );
    }

    function updateToken(
        IERC20 token,
        address rootToken,
        IStableRateFeeder orionRateFeeder,
        uint8 decimals
    ) external only(DEFAULT_ADMIN_ROLE) withToken(token) {
        tokens[token].rootToken = rootToken;
        tokens[token].orionRateFeeder = orionRateFeeder;
        tokens[token].tenPowDecimals = 10 ** uint256(decimals);

        emit UpdateToken(
            address(token),
            rootToken,
            address(orionRateFeeder),
            tokens[token].tenPowDecimals
        );
    }

    function removeToken(IERC20 token) external only(DEFAULT_ADMIN_ROLE) withToken(token) {
        require(totalOrionedSum[token] == 0, "there are deposits in the token");
        require(activeWithdrawOperationsSum[token] == 0, "there are withdraws in the token");

        emit RemoveToken(
            address(token),
            tokens[token].rootToken,
            address(tokens[token].orionRateFeeder),
            tokens[token].tenPowDecimals
        );

        delete tokens[token];
    }

    function setTransferBuffer(address _transferBuffer) external only(DEFAULT_ADMIN_ROLE) {
        transferBuffer = _transferBuffer;

        emit SetTransferBuffer(_transferBuffer);
    }

    function setDepositLimit(uint256 _depositLimit) external only(DEFAULT_ADMIN_ROLE) {
        depositLimit = _depositLimit;

        emit SetDepositLimit(_depositLimit);
    }

    function setDepositMinTransferLimit(uint256 _depositMinTransferLimit) external only(DEFAULT_ADMIN_ROLE) {
        depositMinTransferLimit = _depositMinTransferLimit;

        emit SetDepositMinTransferLimit(_depositMinTransferLimit);
    }

    function setDepositMaxTransferLimit(uint256 _depositMaxTransferLimit) external only(DEFAULT_ADMIN_ROLE) {
        depositMaxTransferLimit = _depositMaxTransferLimit;

        emit SetDepositMaxTransferLimit(_depositMaxTransferLimit);
    }

    function setWithdrawLimit(uint256 _withdrawLimit) external only(DEFAULT_ADMIN_ROLE) {
        withdrawLimit = _withdrawLimit;

        emit SetWithdrawLimit(withdrawLimit);
    }

    function setWithdrawMinTransferLimit(uint256 _withdrawMinTransferLimit) external only(DEFAULT_ADMIN_ROLE) {
        withdrawMinTransferLimit = _withdrawMinTransferLimit;

        emit SetWithdrawMinTransferLimit(_withdrawMinTransferLimit);
    }

    function setWithdrawMaxTransferLimit(uint256 _withdrawMaxTransferLimit) external only(DEFAULT_ADMIN_ROLE) {
        withdrawMaxTransferLimit = _withdrawMaxTransferLimit;

        emit SetWithdrawMaxTransferLimit(_withdrawMaxTransferLimit);
    }

    function setWithdrawLocalLimit(uint256 _withdrawLocalLimit) external only(DEFAULT_ADMIN_ROLE) {
        withdrawLocalLimit = _withdrawLocalLimit;

        emit SetWithdrawLocalLimit(_withdrawLocalLimit);
    }

    function setLocalPoolSize(uint256 _localPoolSize) external only(DEFAULT_ADMIN_ROLE) {
        localPoolSize = _localPoolSize;

        emit SetLocalPoolSize(_localPoolSize);
    }

    function setWithdrawFee(uint256 _minFee, uint256 _maxFee, uint256 _feeFractionNumerator) external only(DEFAULT_ADMIN_ROLE) {
        require(_minFee <= _maxFee, "_minFee greater than _maxFee");
        require(_feeFractionNumerator <= feeFractionDenominator, "feeFraction greater than 1");

        minFee = _minFee;
        maxFee = _maxFee;
        feeFractionNumerator = _feeFractionNumerator;

        emit SetWithdrawFee(_minFee, _maxFee, _feeFractionNumerator);
    }

    /*
        ------------------------------------------------------------------------------------------------
                                        USER INTERFACE FUNCTIONS
        ------------------------------------------------------------------------------------------------
    */

    function deposit(IERC20 token, uint256 amount) public override withToken(token) nonReentrant {
        require(amount <= depositLimit.mul(tokens[token].tenPowDecimals), "amount above deposit limit");
        require(activeWithdrawOperations[token][msg.sender] == 0, "withdraw pending");

        uint256 tokenBalanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        require(token.balanceOf(address(this)).sub(tokenBalanceBefore) == amount,
            "ERC20 hasn't transferred the same amount as requested");

        uint256 orionedAmount = convertTokensToOrionedAmount(token, amount);

        balances[token][msg.sender].originalAmount = balances[token][msg.sender].originalAmount.add(amount);
        balances[token][msg.sender].orionedAmount = balances[token][msg.sender].orionedAmount.add(orionedAmount);
        totalOrionedSum[token] = totalOrionedSum[token].add(orionedAmount);

        emit Deposit(address(token), msg.sender, amount, orionedAmount);
    }

    function depositLocal(IERC20 token, uint256 amount) public override {
        deposit(token, amount);
    }

    function canDepositLocal(IERC20, uint256) public override pure returns (bool) {
        return true;
    }

    function withdraw(IERC20 token, uint256 requestedAmount) public override withToken(token) nonReentrant {
        require(activeWithdrawOperations[token][msg.sender] == 0, "one withdraw allowed per user/token");
        require(requestedAmount <= withdrawLimit.mul(tokens[token].tenPowDecimals), "amount above withdraw limit");

        (uint256 originalAmount, uint256 orionedAmount, uint256 currentAmount) = balanceOf(token, msg.sender);
        require(currentAmount >= requestedAmount, "insufficient funds on user current balance");
        uint256 requestedOrionedAmount = convertTokensToOrionedAmount(token, requestedAmount);
        require(orionedAmount >= requestedOrionedAmount, "insufficient funds on user orioned balance");

        balances[token][msg.sender].originalAmount = (currentAmount.sub(requestedAmount)).min(originalAmount);
        balances[token][msg.sender].orionedAmount = balances[token][msg.sender].orionedAmount.sub(requestedOrionedAmount);
        totalOrionedSum[token] = totalOrionedSum[token].sub(requestedOrionedAmount);

        WithdrawOperation memory withdrawOperation = WithdrawOperation(
            token,
            msg.sender,
            requestedAmount,
            requestedOrionedAmount
        );
        withdrawOperations[woRightPointer] = withdrawOperation;
        activeWithdrawOperations[token][msg.sender] = woRightPointer;

        uint256 requestedAmountAfterFee = applyWithdrawFee(token, requestedAmount);
        activeWithdrawOperationsSum[token] = activeWithdrawOperationsSum[token].add(requestedAmountAfterFee);
        pendingWithdrawOperationsSum[token] = pendingWithdrawOperationsSum[token].add(requestedAmount);

        emit WithdrawInit(woRightPointer, address(token), msg.sender, requestedAmount, requestedOrionedAmount);
        woRightPointer++;
    }

    function withdrawLocal(IERC20 token, uint256 requestedAmount) public override withToken(token) nonReentrant {
        require(activeWithdrawOperations[token][msg.sender] == 0, "one withdraw allowed per user/token");
        require(requestedAmount <= withdrawLimit.mul(tokens[token].tenPowDecimals), "amount above withdraw limit");

        (uint256 originalAmount, uint256 orionedAmount, uint256 currentAmount) = balanceOf(token, msg.sender);
        require(currentAmount >= requestedAmount, "insufficient funds on user current balance");
        uint256 requestedOrionedAmount = convertTokensToOrionedAmount(token, requestedAmount);
        require(orionedAmount >= requestedOrionedAmount, "insufficient funds on user orioned balance");

        require(requestedAmount <= withdrawLocalLimit.mul(tokens[token].tenPowDecimals), "amount above withdraw local limit");
        require(token.balanceOf(address(this)) >= activeWithdrawOperationsSum[token].add(requestedAmount), "insufficient funds in local pool");

        balances[token][msg.sender].originalAmount = (currentAmount.sub(requestedAmount)).min(originalAmount);
        balances[token][msg.sender].orionedAmount = balances[token][msg.sender].orionedAmount.sub(requestedOrionedAmount);
        totalOrionedSum[token] = totalOrionedSum[token].sub(requestedOrionedAmount);

        token.safeTransfer(msg.sender, requestedAmount);

        emit WithdrawLocal(address(token), msg.sender, requestedAmount, requestedOrionedAmount);
    }

    function canWithdrawLocal(IERC20 token, uint256 amount) public override view returns (bool) {
        return token.balanceOf(address(this)) >= activeWithdrawOperationsSum[token].add(amount);
    }

    /*
        ------------------------------------------------------------------------------------------------
                                        TRANSFER FUNCTIONS
        ------------------------------------------------------------------------------------------------
    */

    function autoDepositToEthereum(IERC20 token) external {
        (bool available, uint256 availableFunds) = getFundsAvailableToDepositToEthereum(token);
        require(available, "autoDepositToEthereum not available");

        _depositToEthereum(token, availableFunds);
    }

    function manualDepositToEthereum(IERC20 token, uint256 amount) external only(DEFAULT_ADMIN_ROLE) {
        _depositToEthereum(token, amount);
    }

    function _depositToEthereum(IERC20 token, uint256 amount) internal withToken(token) {
        require(amount > 0, "cannot deposit zero amount");

        uint256 toDeposit = amount.min(depositMaxTransferLimit.mul(tokens[token].tenPowDecimals));
        IChildERC20(address(token)).withdraw(toDeposit);

        emit DepositToEthereum(address(token), amount);
    }

    function autoWithdrawFromEthereum(IERC20 token) external {
        (bool available, uint256 availableFunds) = getFundsAvailableToWithdrawFromEthereum(token);
        require(available, "autoWithdrawFromEthereum not available");

        _withdrawFromEthereum(token, availableFunds);
    }

    function manualWithdrawFromEthereum(IERC20 token) external only(DEFAULT_ADMIN_ROLE) {
        (, uint256 availableFunds) = getFundsAvailableToWithdrawFromEthereum(token);
        _withdrawFromEthereum(token, availableFunds);
    }

    function manualWithdrawFromEthereum(IERC20 token, uint256 amount) external only(DEFAULT_ADMIN_ROLE) {
        _withdrawFromEthereum(token, amount);
    }

    function _withdrawFromEthereum(IERC20 token, uint256 availableFunds) internal withToken(token) withTransferBuffer {
        require(requestedWithdrawOperationsSum[token] == 0, "already requested");
        require(availableFunds > 0, "no available funds to withdraw");

        uint256 toWithdraw = availableFunds.min(withdrawMaxTransferLimit.mul(tokens[token].tenPowDecimals));
        requestedWithdrawOperationsSum[token] = toWithdraw;
        publishMessage(token, toWithdraw);

        emit WithdrawFromEthereum(address(token), toWithdraw);
    }

    function resetWithdrawFromEthereum(IERC20 token) external withToken(token) only(DEFAULT_ADMIN_ROLE) {
        require(requestedWithdrawOperationsSum[token] > 0, "nothing requested");
        emit ResetWithdrawFromEthereum(address(token), requestedWithdrawOperationsSum[token]);
        requestedWithdrawOperationsSum[token] = 0;
    }

    /*
        ------------------------------------------------------------------------------------------------
                                        FINALIZATION FUNCTIONS
        ------------------------------------------------------------------------------------------------
    */

    function finalizeTransfer(IERC20 token) public withTransferBuffer {
        require(canFinalizeTransfer(token), "transfer finalization not available");

        requestedWithdrawOperationsSum[token] = 0;
        token.safeTransferFrom(transferBuffer, address(this), token.balanceOf(transferBuffer));

        emit TransferFinalized(address(token));
    }

    function canFinalizeTransfer(IERC20 token) public view returns (bool) {
        uint256 requestedSumAfterFee = applyWithdrawFee(token, requestedWithdrawOperationsSum[token]);
        return transferBuffer != address(0) && requestedSumAfterFee > 0 && token.balanceOf(transferBuffer) >= requestedSumAfterFee;
    }

    function finalizeWithdraws() public nonReentrant {
        require(canFinalizeWithdraw(), "withdraw finalization not available");

        while (canFinalizeWithdraw()) {
            WithdrawOperation memory withdrawOperation = withdrawOperations[woLeftPointer];
            IERC20 token = withdrawOperation.token;
            uint256 requestedAmountAfterFee = applyWithdrawFee(token, withdrawOperation.requestedAmount);

            delete activeWithdrawOperations[token][withdrawOperation.investor];
            activeWithdrawOperationsSum[token] = activeWithdrawOperationsSum[token].sub(requestedAmountAfterFee);
            pendingWithdrawOperationsSum[token] = pendingWithdrawOperationsSum[token].sub(withdrawOperation.requestedAmount);

            emit WithdrawFinalized(woLeftPointer);
            woLeftPointer++;

            token.safeTransfer(withdrawOperation.investor, requestedAmountAfterFee);
        }
    }

    function canFinalizeWithdraw() public view returns (bool) {
        if (woLeftPointer >= woRightPointer) return false;

        WithdrawOperation memory withdrawOperation = withdrawOperations[woLeftPointer];
        IERC20 token = withdrawOperation.token;
        uint256 requestedAmountAfterFee = applyWithdrawFee(token, withdrawOperation.requestedAmount);

        return token.balanceOf(address(this)) >= requestedAmountAfterFee;
    }

    /*
        ------------------------------------------------------------------------------------------------
                                        PUBLIC VIEW FUNCTIONS
        ------------------------------------------------------------------------------------------------
    */

    function balanceOf(IERC20 token, address investor) public override view withToken(token) returns (
        uint256 originalAmount,
        uint256 orionedAmount,
        uint256 currentAmount
    ) {
        originalAmount = balances[token][investor].originalAmount;
        orionedAmount = balances[token][investor].orionedAmount;
        currentAmount = tokens[token].orionRateFeeder.multiplyByCurrentRate(orionedAmount);
    }

    function getTokenInfo(IERC20 token) public view withToken(token) returns (
        address rootToken,
        IStableRateFeeder orionRateFeeder,
        uint256 tenPowDecimals
    ) {
        rootToken = tokens[token].rootToken;
        orionRateFeeder = tokens[token].orionRateFeeder;
        tenPowDecimals = tokens[token].tenPowDecimals;
    }

    function getWormholeNonce() public view returns (uint32) {
        return wormholeNonce;
    }

    function getLeftPointer() public view returns (uint256) {
        return woLeftPointer;
    }

    function getRightPointer() public view returns (uint256) {
        return woRightPointer;
    }

    function getActiveWithdrawOperation(IERC20 token, address investor) public view returns (uint32) {
        return activeWithdrawOperations[token][investor];
    }

    function getWithdrawOperation(uint32 index) public view returns (
        IERC20 token,
        address investor,
        uint256 requestedAmount,
        uint256 requestedOrionedAmount
    ) {
        token = withdrawOperations[index].token;
        investor = withdrawOperations[index].investor;
        requestedAmount = withdrawOperations[index].requestedAmount;
        requestedOrionedAmount = withdrawOperations[index].requestedOrionedAmount;
    }

    function getTotalOrionedSum(IERC20 token) public view returns (uint256) {
        return totalOrionedSum[token];
    }

    function getActiveWithdrawOperationsSum(IERC20 token) public view returns (uint256) {
        return activeWithdrawOperationsSum[token];
    }

    function getPendingWithdrawOperationsSum(IERC20 token) public view returns (uint256) {
        return pendingWithdrawOperationsSum[token];
    }

    function getRequestedWithdrawOperationsSum(IERC20 token) public view returns (uint256) {
        return requestedWithdrawOperationsSum[token];
    }

    function getDepositLimit() public override view returns (uint256) {
        return depositLimit;
    }

    function getDepositMinTransferLimit() public view returns (uint256) {
        return depositMinTransferLimit;
    }

    function getDepositMaxTransferLimit() public view returns (uint256) {
        return depositMaxTransferLimit;
    }

    function getDepositLocalLimit() public view returns (uint256) {
        return getDepositLimit();
    }

    function getLocalDepositLimit() public override view returns (uint256) {
        return getDepositLocalLimit();
    }

    function getWithdrawLimit() public override view returns (uint256) {
        return withdrawLimit;
    }

    function getWithdrawMinTransferLimit() public view returns (uint256) {
        return withdrawMinTransferLimit;
    }

    function getWithdrawMaxTransferLimit() public view returns (uint256) {
        return withdrawMaxTransferLimit;
    }

    function getWithdrawLocalLimit() public view returns (uint256) {
        return withdrawLocalLimit;
    }

    function getLocalWithdrawLimit() public override view returns (uint256) {
        return getWithdrawLocalLimit();
    }

    function getLocalPoolSize() public view returns (uint256) {
        return localPoolSize;
    }

    function getWithdrawFee() public view returns (uint256 _minFee, uint256 _maxFee, uint256 _feeFractionNumerator) {
        _minFee = minFee;
        _maxFee = maxFee;
        _feeFractionNumerator = feeFractionNumerator;
    }

    function getWithdrawFee(IERC20 token, uint256 amount) public view returns (uint256) {
        return amount
        .mul(feeFractionNumerator).div(feeFractionDenominator)
        .max(minFee * tokens[token].tenPowDecimals)
        .min(maxFee * tokens[token].tenPowDecimals);
    }

    function applyWithdrawFee(IERC20 token, uint256 amount) public view returns (uint256) {
        uint256 withdrawFee = getWithdrawFee(token, amount);
        return amount >= withdrawFee ? amount.sub(withdrawFee) : 0;
    }

    function getFundsAvailableToDepositToEthereum(IERC20 token) public view returns (bool available, uint256 availableFunds ) {
        uint256 balance = token.balanceOf(address(this));
        uint256 pool = localPoolSize.mul(tokens[token].tenPowDecimals);
        uint256 activeWithdrawSum = activeWithdrawOperationsSum[token];

        availableFunds = balance >= pool.add(activeWithdrawSum) ? balance.sub(pool).sub(activeWithdrawSum) : 0;
        available = availableFunds >= depositMinTransferLimit.mul(tokens[token].tenPowDecimals);
    }

    function getFundsAvailableToWithdrawFromEthereum(IERC20 token) public view returns (bool available, uint256 availableFunds) {
        uint256 balance = token.balanceOf(address(this));
        uint256 pool = localPoolSize.mul(tokens[token].tenPowDecimals);

        availableFunds = balance >= pool.add(pendingWithdrawOperationsSum[token]) ? 0 : pool.add(pendingWithdrawOperationsSum[token]).sub(balance);
        available = requestedWithdrawOperationsSum[token] == 0 && availableFunds >= withdrawMinTransferLimit.mul(tokens[token].tenPowDecimals);
    }

    function getTransferBuffer() public view returns (address) {
        return transferBuffer;
    }

    /*
        ------------------------------------------------------------------------------------------------
                                        INTERNAL FUNCTIONS
        ------------------------------------------------------------------------------------------------
    */

    function convertTokensToOrionedAmount(IERC20 token, uint256 amount) internal view returns (uint256) {
        return amount.mul(1e18).div(tokens[token].orionRateFeeder.multiplyByCurrentRate(1e18));
    }

    function publishMessage(IERC20 token, uint256 amount) internal {
        bytes memory payload = abi.encode(tokens[token].rootToken, amount);
        uint64 sequence = wormhole.publishMessage(wormholeNonce, payload, 255);

        emit PublishMessage(address(token), amount, wormholeNonce, sequence);
        wormholeNonce++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Structs {
    struct Provider {
        uint16 chainId;
        uint16 governanceChainId;
        bytes32 governanceContract;
    }

    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;

        uint32 guardianSetIndex;
        Signature[] signatures;

        bytes32 hash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Structs.sol";

interface IWormhole is Structs {
    function publishMessage(uint32 nonce, bytes calldata payload, uint8 consistencyLevel) external returns (uint64 sequence);

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (Structs.VM memory vm, bool valid, string memory reason);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStableRateFeeder {
    function multiplyByCurrentRate(uint256 value) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChildERC20 {
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISaver {
  function balanceOf(IERC20 token, address user) external view returns (uint256 original_amount, uint256 orioned_amount, uint256 current_amount);

  function getDepositLimit() external view returns (uint256);

  function getLocalDepositLimit() external view returns (uint256);

  function deposit(IERC20 token, uint256 amount) external;

  function depositLocal(IERC20 token, uint256 amount) external;

  function canDepositLocal(IERC20 token, uint256 amount) external view returns(bool);

  function getWithdrawLimit() external view returns (uint256);

  function getLocalWithdrawLimit() external view returns (uint256);

  function withdraw(IERC20 token, uint256 requested_amount) external;

  function withdrawLocal(IERC20 token, uint256 requested_amount) external;

  function canWithdrawLocal(IERC20 token, uint256 amount) external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}