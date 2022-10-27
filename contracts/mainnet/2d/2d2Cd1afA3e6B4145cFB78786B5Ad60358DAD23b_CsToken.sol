// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {UUPSUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20Upgradeable, IERC20Upgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";

import "./interfaces/IWETH9.sol";
import "./interfaces/IClayManager.sol";
import "./interfaces/IRoleManager.sol";
import "./interfaces/IClayTunnel.sol";
import "./interfaces/ICSToken.sol";
import "./interfaces/IClaimVault.sol";

import {IFxRoot} from "./interfaces/IFxRoot.sol";
import {UserProxy} from "./UserProxy.sol";
import {FxBaseChildTunnel} from "./tunnel/FxBaseChildTunnel.sol";
import "./interfaces/IChildToken.sol";

/// @title ClayManager
/// @author ClayStack
contract ClayManager is
    IClayManager,
    UUPSUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    FxBaseChildTunnel
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Event for new deposit.
    /// @param user : Address of depositor.
    /// @param amount : Amount of Token deposited.
    /// @param amountCs : Amount of csToken minted.
    /// @param fee : Fee paid by user on deposit in Token
    event LogDeposit(address indexed user, uint256 amount, uint256 amountCs, uint256 fee);

    /// @notice Event for swapping V1 tokens to V2.
    /// @param user : Address of depositor.
    /// @param amount : Amount of tokens swapped.
    event LogSwap(address indexed user, uint256 amount);

    /// @notice Event for new withdraw request.
    /// @param user : Address of user withdrawing.
    /// @param orderId : Withdraw order id.
    /// @param amountCs : Amount of csTokenV2 burned.
    /// @param amount : Amount of Token withdrawn.
    /// @param fee : Fee percentage to be paid by the user
    /// @param timestamp : Epoch at the moment of request
    event LogWithdraw(
        address indexed user,
        uint256 orderId,
        uint256 amountCs,
        uint256 amount,
        uint256 fee,
        uint256 timestamp
    );

    /// @notice Event for new deposit.
    /// @param updatedBy : Address of Updating entity.
    /// @param feeType : Fee type being updated.
    /// @param oldFee : Existing fee percent for given fee type.
    /// @param newFee : New fee percent for given fee type.
    event LogFeeUpdate(address indexed updatedBy, SetFee feeType, uint256 oldFee, uint256 newFee);

    /// @notice Event for withdraw claims by user.
    /// @param user : Address of user.
    /// @param orderId : Withdraw order id.
    /// @param amount : Amount of MATIC unstaked in order.
    /// @param received : Amount of MATIC received in order.
    /// @param fee : Fee paid by user.
    event LogClaim(address indexed user, uint256 orderId, uint256 amount, uint256 received, uint256 fee);

    /// @notice Event emitted when AutoBalance is run.
    /// @param batchId : Id of the current processed batch.
    /// @param isNetStaking : Flag denoting net tx type of batch.
    /// @param amount : Amount of MATIC to be deposited or expected at claim.
    /// @param amountCs : Exact amount of csMatic minted or burned.
    /// @param amountCsV1 : Exact amount of v1 csMatic bridged.
    event LogAutoBalance(
        uint256 indexed batchId,
        bool indexed isNetStaking,
        uint256 amount,
        uint256 amountCs,
        uint256 amountCsV1
    );

    /// @notice When increases in rate creates a pendingMatic mismatch
    /// @param mismatch amount from deposits
    event LogDepositMismatch(uint256 mismatch);

    /// @notice Token sent to contract through the donate function.
    /// @param amount of Token donated.
    event LogDonation(uint256 amount);

    /// @notice ClayStack's default list of access-control roles.
    bytes32 private constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");
    bytes32 private constant TIMELOCK_UPGRADES_ROLE = keccak256("TIMELOCK_UPGRADES_ROLE");
    bytes32 private constant CS_SERVICE_ROLE = keccak256("CS_SERVICE_ROLE");

    uint256 private constant MAX_DEPOSIT_FEE = 500;
    uint256 private constant MAX_WITHDRAW_FEE = 500;
    uint256 private constant MAX_INSTANT_WITHDRAW_FEE = 2000;
    uint256 private constant MAX_EARLY_CLAIM_FEE = 2000;
    uint256 private constant MAX_DAYS_LOW_FREQ = 90;
    uint256 private constant MAX_UNBONDING_DAYS = 15;
    uint256 private constant MIN_WITHDRAW_THRESHOLD = 500 ether;
    uint256 private constant PERCENTAGE_BASE = 10000;
    uint256 private constant MAX_DECIMALS = 1e18;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant DEPOSIT_CODE = 1;
    uint256 private constant WITHDRAW_CODE = 2;
    uint256 private constant REGISTER_CLAIM_CODE = 3;

    /// @notice WithdrawOrder struct
    /// @param amount : Total amount unstaked from from ethereum.
    /// @param fee : Fee percentage to be paid by the user at claim time.
    /// @param batchId : Id of the batch process to be sent to ethereum.
    struct WithdrawOrder {
        uint256 amount;
        uint256 fee;
        uint256 batchId;
    }

    /// @notice information about values send and received on a batch
    /// @dev Ratio received/requested will be used to compute slashing
    /// in case of net staking, ratio of price rates will be used
    /// @param requested amount of MATIC in batch
    /// @param received actual received MATIC in batch
    /// @param claimableAt timestamp when batch claims can be processed
    /// @param exchangeRate at the moment of first tx in the batch
    /// @param batchReserves are the MATIC reserved from deposits towards withdraws
    struct BatchWithdraw {
        uint256 requested;
        uint256 received;
        uint256 claimableAt;
        uint256 exchangeRate;
        uint256 batchReserves;
    }

    /// @notice Frequency requirements in of csMATIC and days for bridge autobalance.
    /// @param amountHigh threshold for high frequency batches
    /// @param amountMedium threshold for medium frequency batches
    /// @param daysHigh time between batches given threshold for high amount
    /// @param daysMedium time between batches given threshold for medium amount
    /// @param daysLow time between batches beyond which bridging is possible
    /// @param withdrawsThreshold when unstake will bridge despite low pending withdraws
    struct BatchRequirements {
        uint256 amountHigh;
        uint256 amountMedium;
        uint256 daysHigh;
        uint256 daysMedium;
        uint256 daysLow;
        uint256 withdrawsThreshold;
    }

    /// @notice Instance on Polygon's native POS Child token
    IChildToken private constant MATIC = IChildToken(0x0000000000000000000000000000000000001010);

    /// @notice Stores all fee info.
    Fees public fees;

    /// @notice Wrapped matic instance
    IWETH9 wMatic;

    /// @notice address of clayTunnel contract providing csMATIC to MATIC rate
    IClayTunnel public clayTunnel;

    /// @notice RoleManager instance.
    IRoleManager private roleManager;

    /// @notice csToken instance.
    ICSToken private csToken;

    /// @notice csTokenV1 instance.
    IChildToken private csTokenV1;

    /// @notice Minimum threshold in amount and days for executing bridge transfers
    BatchRequirements public batchRequirements;

    /// @notice Mapping of all unstaking withdraw order by users.
    mapping(address => mapping(uint256 => WithdrawOrder)) public withdrawOrders;

    /// @notice maps id to Batch withdrawal structures
    mapping(uint256 => BatchWithdraw) public batchWithdrawOrders;

    /// @notice maps user to the list of claims they have
    mapping(address => uint256[]) public userWithdrawIds;

    /// @notice address of the contract that hold claim funds
    address public claimVault;

    /// @notice treasury address
    address public treasury;

    /// @notice Sum of MATIC to be transferred to ethereum
    uint256 public pendingMatic;

    /// @notice Sum of csMATIC minted in exchange to be staked
    uint256 public pendingCsMatic;

    /// @notice Sum of csMATIC burned to be unstaked
    uint256 public pendingWithdrawCs;

    /// @notice Sum of MATIC to be unstaked in batch
    uint256 public pendingWithdrawMatic;

    /// @notice Total current withdrawals on current batch
    uint256 public currentWithdrawn;

    /// @notice Active batch id
    uint256 public batchId;

    /// @notice timestamp of the latest data transfer
    uint256 public latestBatchTime;

    /// @notice fee to manually trigger the bridge by user
    uint256 public bridgeFee;

    /// @notice Linear incremental order nonce. Increases by one after each withdraw request.
    uint256 orderNonce;

    /// @notice Minimum number of days to claim locally netted withdrawal orders
    uint256 public minClaimDays;

    /// @notice Keeps track of Polygon's latest state transfer message id
    mapping(uint256 => bool) private stateIdReceived;

    /// @notice Check if the msg.sender has permission.
    /// @param _roleName : bytes32 hash of the role.
    modifier onlyRole(bytes32 _roleName) {
        _onlyRole(_roleName);
        _;
    }

    /// @notice Checks for slashing and closes batch if needed
    modifier checkSlashing() {
        _checkBatches();
        _;
    }

    /// @notice Initializes the contract's state vars.
    /// @param _wMatic : wMATIC on Polygon.
    /// @param _csToken : Address of ClayStack's erc20 compliant synthetic token v2.
    /// @param _csTokenV1 : Address of ClayStack's erc20 compliant synthetic token.
    /// @param _roleManager : Address of ClayStack's role manager contract.
    /// @param _fxChild : Address of Polygon's child state channel contract.
    /// @param _clayTunnel : Address of ClayStack's exchange tunnel with official rate.
    /// @param _treasury : Address of ClayStack's treasury.
    function initialize(
        address _wMatic,
        address _csToken,
        address _csTokenV1,
        address _roleManager,
        address _fxChild,
        address _clayTunnel,
        address _treasury
    ) external initializer onlyProxy {
        require(_wMatic != address(0), "Invalid wMatic");
        require(_csToken != address(0), "Invalid csToken address");
        require(_csTokenV1 != address(0), "Invalid v1 address");
        require(_roleManager != address(0), "Invalid roleManager address");
        require(_fxChild != address(0), "Invalid fxChild address");
        require(_clayTunnel != address(0), "Invalid tunnel address");
        require(_treasury != address(0), "Invalid treasury address");

        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        setFxRootTunnel(address(this));

        wMatic = IWETH9(_wMatic);
        roleManager = IRoleManager(_roleManager);
        csToken = ICSToken(_csToken);
        csTokenV1 = IChildToken(_csTokenV1);
        fxChild = _fxChild;
        clayTunnel = IClayTunnel(_clayTunnel);
        treasury = _treasury;

        // Default settings
        fees.depositFee = 10; // 0.1% to cover bridge exchange risk
        minClaimDays = 2 days;

        //set initial requirements
        batchRequirements = BatchRequirements({
            amountHigh: 10_000 ether,
            amountMedium: 5_000 ether,
            daysHigh: 1,
            daysMedium: 2,
            daysLow: 7,
            withdrawsThreshold: 10_000 ether
        });
    }

    /** USER OPERATIONS **/

    /// @notice Sends `_amountToken` Token to ClayMain contract and mints csToken to msg.sender.
    /// @param _amountToken WMATIC to be deposited
    /// @return True if valid
    function deposit(uint256 _amountToken) external override whenNotPaused nonReentrant checkSlashing returns (bool) {
        require(wMatic.transferFrom(address(msg.sender), address(this), _amountToken), "Transfer Failed");
        wMatic.withdraw(_amountToken);
        return _deposit(_amountToken, msg.sender);
    }

    /// @notice Sends Token to contract and mints csToken to `_delegatedTo`.
    /// @param _amountToken WMATIC to be deposited
    /// @param _delegatedTo Address of entity receiving csToken.
    /// @return True if valid
    function depositDelegate(uint256 _amountToken, address _delegatedTo)
        external
        override
        whenNotPaused
        nonReentrant
        checkSlashing
        returns (bool)
    {
        require(_delegatedTo != address(0), "Invalid delegatedTo");
        require(wMatic.transferFrom(address(msg.sender), address(this), _amountToken), "Transfer Failed");
        wMatic.withdraw(_amountToken);
        return _deposit(_amountToken, _delegatedTo);
    }

    /// @notice Sends Token to contract and mints csTokenV2 to msg.sender.
    /// @return True if valid
    function depositETH() external payable whenNotPaused nonReentrant checkSlashing returns (bool) {
        return _deposit(msg.value, msg.sender);
    }

    /// @notice Internal for processing deposits
    /// @param _depositAmount MATIC to be deposited
    /// @param _delegatedTo Address of entity receiving csToken.
    function _deposit(uint256 _depositAmount, address _delegatedTo) internal returns (bool) {
        require(_depositAmount != 0, "Invalid deposit amount");

        uint256 depositFee = (fees.depositFee * _depositAmount) / PERCENTAGE_BASE;
        uint256 amountToken = _depositAmount - depositFee;
        uint256 amountToMint = _exchangeToken(amountToken);

        // Update effect of action
        pendingMatic += _depositAmount;
        pendingCsMatic += amountToMint;
        _balance();

        require(csToken.mint(_delegatedTo, amountToMint), "Minting failed");

        emit LogDeposit(_delegatedTo, amountToken, amountToMint, depositFee);
        return true;
    }

    /// @notice Burns csToken from user and instantly returns Token to user.
    /// @param _amountCsV2 Amount of csToken to be withdrawn.
    /// @return Bool confirmation of transaction
    function instantWithdraw(uint256 _amountCsV2) external whenNotPaused nonReentrant checkSlashing returns (bool) {
        uint256 orderId = _withdraw(_amountCsV2);
        require(isClaimable(orderId, msg.sender), "Instant withdraw not available");
        return _claim(orderId, fees.instantWithdrawFee);
    }

    /// @notice Burns csToken from user and starts unstaking process from Ethereum
    /// @param _amountCsV2 Amount of csToken to be withdrawn.
    /// @return Returns withdraw id.
    function withdraw(uint256 _amountCsV2)
        external
        override
        whenNotPaused
        nonReentrant
        checkSlashing
        returns (uint256)
    {
        return _withdraw(_amountCsV2);
    }

    /// @notice Burns csToken from user and starts unstaking process from Ethereum
    /// @param _amountCsV2 Amount of csToken to be withdrawn.
    /// @return Returns withdraw id.
    function _withdraw(uint256 _amountCsV2) internal returns (uint256) {
        require(_amountCsV2 != 0, "Withdraw amount cannot be zero");
        require(csToken.balanceOf(msg.sender) >= _amountCsV2, "Insufficient csToken user balance");

        uint256 amountTokenWithdraw = _exchangeCsToken(_amountCsV2);

        pendingWithdrawCs += _amountCsV2;
        pendingWithdrawMatic += amountTokenWithdraw;
        currentWithdrawn += amountTokenWithdraw;
        _balance();

        require(csToken.burn(msg.sender, _amountCsV2), "Burn failed");

        uint256 id = ++orderNonce;
        withdrawOrders[msg.sender][id] = WithdrawOrder({
            amount: amountTokenWithdraw,
            fee: fees.withdrawFee,
            batchId: batchId
        });

        userWithdrawIds[msg.sender].push(id);

        emit LogWithdraw(msg.sender, id, _amountCsV2, amountTokenWithdraw, fees.withdrawFee, block.timestamp);
        return id;
    }

    /// @notice Allows the user to claim several orders at once.
    /// @param _orderIds - array of number of ids issued at withdraw()
    /// @return Bool confirmation of transaction
    function claim(uint256[] calldata _orderIds) external override whenNotPaused nonReentrant returns (bool) {
        for (uint256 i = 0; i < _orderIds.length; i++) {
            uint256 _orderId = _orderIds[i];
            WithdrawOrder memory order = withdrawOrders[msg.sender][_orderId];
            BatchWithdraw memory batchOrder = batchWithdrawOrders[order.batchId];
            require(batchOrder.claimableAt != 0 && batchOrder.claimableAt <= block.timestamp, "Order is not claimable");
            _claim(_orderId, 0);
        }
        return true;
    }

    /// @notice single claim implementation
    /// @param _orderId id issued at withdraw
    /// @param _extraFee in addition to the withdraw fee instant withdraw fee or early claim fee
    function _claim(uint256 _orderId, uint256 _extraFee) internal returns (bool) {
        require(claimVault != address(0), "ClaimVault has not been set");
        if (address(claimVault).balance != 0) {
            IClaimVault cv = IClaimVault(claimVault);
            cv.claimFunds();
        }

        WithdrawOrder storage order = withdrawOrders[msg.sender][_orderId];
        require(order.amount != 0, "Invalid Order");

        BatchWithdraw memory batchOrder = batchWithdrawOrders[order.batchId];

        uint256 received = batchOrder.received;
        uint256 requested = batchOrder.requested;

        // if open batch adjust multiplier to 1
        uint256 multiplier = received == 0 ? 1 ether : (received * PRECISION) / requested;

        uint256 amount = (order.amount * multiplier) / PRECISION;
        require(amount != 0, "Withdraw amount cannot be zero");
        require(address(this).balance >= amount, "Insufficient balance");

        uint256 orderFee = (amount * (order.fee + _extraFee)) / PERCENTAGE_BASE;
        emit LogClaim(msg.sender, _orderId, order.amount, amount, orderFee);

        // early claims / instant withdraws update reserves
        if (_extraFee != 0) {
            batchWithdrawOrders[order.batchId].batchReserves -= amount;
        }

        // reduce withdrawn if open batch
        if (order.batchId == batchId) {
            currentWithdrawn -= order.amount;
        }

        order.amount = 0;
        order.batchId = 0;
        order.fee = 0;

        bool success;
        (success, ) = msg.sender.call{value: amount - orderFee}("");
        require(success, "Transfer of funds to user failed");

        if (orderFee > 0) {
            (success, ) = treasury.call{value: orderFee}("");
            require(success, "Transfer of fees to treasury failed");
        }

        return true;
    }

    /// @notice Returns if order is claimable either early or standard
    /// @param _orderId id issued at withdraw
    function isClaimable(uint256 _orderId, address _user) public view returns (bool) {
        WithdrawOrder memory order = withdrawOrders[_user][_orderId];
        BatchWithdraw memory batchOrder = batchWithdrawOrders[order.batchId];

        // determine amount adjusting for slashing
        uint256 received = batchOrder.received;
        uint256 requested = batchOrder.requested;

        // if open batch adjust multiplier to rates                                                                                                                                                                                           = 0, calculate current expected
        if (received == 0) {
            uint256 exchangeRate = batchOrder.exchangeRate;
            uint256 currentExchangeRate = _exchangeCsToken(MAX_DECIMALS);
            requested = exchangeRate;

            // slashing happens, then disable
            received = currentExchangeRate < exchangeRate ? 0 : requested;
        }

        uint256 multiplier = (received * PRECISION) / requested;
        uint256 amount = (order.amount * multiplier) / PRECISION;

        bool canEarlyClaim = batchOrder.batchReserves >= amount;
        bool canStandard = batchOrder.claimableAt != 0 && batchOrder.claimableAt <= block.timestamp;
        return amount != 0 && address(this).balance >= amount && canEarlyClaim && !canStandard;
    }

    /// @notice Allows user to claim early (no unbonding) if local contract has reserves to use
    /// @param _orderId of withdrawing order
    /// @return Bool confirmation of transaction
    function earlyClaim(uint256 _orderId) public override whenNotPaused nonReentrant checkSlashing returns (bool) {
        require(isClaimable(_orderId, msg.sender), "Order cannot be claimed early");
        return _claim(_orderId, fees.earlyClaimFee);
    }

    /// @notice Used for unwrapping of tokens
    receive() external payable {}

    /** VIEWS **/

    /// @notice Returns the current exchange rate accounting for any slashing or donations on ethereum.
    /// @dev Polygon's case slashing will always be false. When Ethereum sends the realized rate
    /// it will already include the slashing rate decrease
    /// @return Exchange Rate csToken to Token, Slashing occurred.
    function getExchangeRate() external view returns (uint256, bool) {
        bool slashed = false;
        return (_exchangeCsToken(MAX_DECIMALS), slashed);
    }

    /// @notice Returns amount of Token for given `_amountCs`.
    /// @dev Gets csToken supply and deposits from ClayTunnel
    /// @param _amountCs : Amount of csToken.
    /// @return Amount of Tokens
    function _exchangeCsToken(uint256 _amountCs) internal view returns (uint256) {
        (uint256 totalCsToken, uint256 currentDeposits) = clayTunnel.getFunds();
        if (totalCsToken != currentDeposits && totalCsToken != 0 && currentDeposits != 0) {
            return (_amountCs * currentDeposits) / totalCsToken;
        } else {
            return _amountCs;
        }
    }

    /// @notice Returns amount of csTokens for given `_amountToken`.
    /// @dev Gets csToken supply and deposits from ClayTunnel
    /// @param _amountToken : Amount of Token.
    /// @return Amount of csTokens
    function _exchangeToken(uint256 _amountToken) internal view returns (uint256) {
        (uint256 totalCsToken, uint256 currentDeposits) = clayTunnel.getFunds();
        if (totalCsToken != currentDeposits && currentDeposits != 0 && totalCsToken != 0) {
            return (_amountToken * totalCsToken) / currentDeposits;
        } else {
            return _amountToken;
        }
    }

    /// @dev Returns total liquidity of csToken available for Instant Withdrawal.
    function getLiquidityCsToken() external view returns (uint256) {
        BatchWithdraw memory batchOrder = batchWithdrawOrders[batchId];
        uint256 maxMatic = _min(pendingMatic, _exchangeCsToken(pendingCsMatic));
        uint256 amount = _min(address(this).balance, batchOrder.batchReserves + maxMatic);
        return amount != 0 ? _exchangeToken(amount) : 0;
    }

    /// @notice Returns the given page of the withdraw orders in descending order
    /// @dev Max 10 results starting at page 0
    /// @param _user : Address of user.
    /// @param _page : Page to query.
    /// @return info Array for struct of user withdraw orders
    /// @return timeStamp current time of current chain
    /// @return totalPages supported for given user.
    function getUserOrders(address _user, uint256 _page)
        external
        view
        returns (
            UserWithdrawOrderInfo[] memory,
            uint256,
            uint256
        )
    {
        UserWithdrawOrderInfo[] memory info = new UserWithdrawOrderInfo[](10);
        uint256 pageSize = 10;
        uint256 length = userWithdrawIds[_user].length;
        uint256 totalPages = length / pageSize;
        if (_page <= totalPages && length != 0) {
            for (uint256 i = 0; i < pageSize; i++) {
                uint256 index = length - _page * pageSize - i - 1;

                uint256 orderId = userWithdrawIds[_user][index];
                bool isEarlyClaimableFlag = isClaimable(orderId, _user);

                WithdrawOrder memory order = withdrawOrders[_user][orderId];
                BatchWithdraw memory batchOrder = batchWithdrawOrders[order.batchId];
                bool isClaimableFlag = order.amount != 0 &&
                    batchOrder.claimableAt != 0 &&
                    batchOrder.claimableAt <= block.timestamp;

                info[i] = UserWithdrawOrderInfo({
                    orderId: orderId,
                    amount: order.amount,
                    fee: order.fee,
                    batchId: order.batchId,
                    claimableAt: batchOrder.claimableAt,
                    isClaimable: isClaimableFlag,
                    isEarlyClaimable: isEarlyClaimableFlag
                });

                if (index == 0) break;
            }
        }

        return (info, block.timestamp, totalPages);
    }

    /** BATCH PROCESS **/

    /// @notice Initiates transfer process to Ethereum while sends a message on expected tokens
    /// @dev A minimum amount or time is required for it to execute unless paid fee
    function autoBalance() external payable whenNotPaused nonReentrant returns (bool) {
        bool activeBridge = false;

        // Activate the bridge
        if (msg.value >= bridgeFee) {
            (bool status, ) = treasury.call{value: msg.value}("");
            require(status, "transfer to treasury failed");
            activeBridge = true;
        } else if (pendingWithdrawCs != 0 && currentWithdrawn >= batchRequirements.withdrawsThreshold) {
            activeBridge = true;
        } else {
            uint256 pendingAmount = pendingWithdrawCs + pendingCsMatic;
            uint256 passedDays = latestBatchTime == 0 ? 0 : (block.timestamp - latestBatchTime) / (1 days);

            if (
                (passedDays > batchRequirements.daysHigh && pendingAmount >= batchRequirements.amountHigh) ||
                (passedDays > batchRequirements.daysMedium && pendingAmount >= batchRequirements.amountMedium) ||
                (passedDays > batchRequirements.daysLow && pendingAmount > 0) ||
                (latestBatchTime == 0 && pendingAmount > 0) //Handle first time case before any batch is ever run
            ) {
                activeBridge = true;
            }
        }

        _autoBalance(activeBridge);
        return true;
    }

    /// @notice Determines net stake/unstake and burns on bridge
    function _autoBalance(bool _activeBridge) internal {
        uint256 currentBatchId = batchId;
        bool isNetStaking = pendingMatic != 0 && pendingCsMatic != 0 && pendingCsMatic >= pendingWithdrawCs;
        bool isNetUnstaking = pendingWithdrawMatic != 0 && pendingWithdrawCs != 0 && pendingWithdrawCs > pendingCsMatic;

        // Net Unstaking
        if (isNetUnstaking && _activeBridge) {
            // Sends csTokenV1 to Ethereum for unstakes and UserProxy to hold
            uint256 v1Balance = csTokenV1.balanceOf(address(this));
            if (v1Balance != 0) {
                csTokenV1.withdraw(v1Balance);
            }

            // Sends withdraw message to UserProxy
            bytes memory data = abi.encode(WITHDRAW_CODE, pendingWithdrawCs, pendingWithdrawMatic, currentBatchId);
            _sendMessageToRoot(data);
            emit LogAutoBalance(currentBatchId, false, pendingWithdrawMatic, pendingWithdrawCs, v1Balance);

            batchWithdrawOrders[currentBatchId].requested = pendingWithdrawMatic;
            pendingWithdrawCs = 0;
            pendingWithdrawMatic = 0;
            currentWithdrawn = 0;
            latestBatchTime = block.timestamp;

            batchId++;

            // Net Staking
        } else {
            // Mark current batch as claimable from reserves
            uint256 requested = batchWithdrawOrders[currentBatchId].exchangeRate;
            bool active = isNetStaking && _activeBridge;
            if (requested != 0 && ((!isNetUnstaking && currentWithdrawn != 0) || active)) {
                // Sets multiplier either to 1 or less if slashing happened
                uint256 received = _min(requested, _exchangeCsToken(MAX_DECIMALS));
                uint256 multiplier = (received * PRECISION) / requested;

                batchWithdrawOrders[currentBatchId].requested = requested;
                batchWithdrawOrders[currentBatchId].received = received;
                batchWithdrawOrders[currentBatchId].claimableAt = block.timestamp + minClaimDays;

                // Slashing case withdraws will produce surplus that is added as donation
                if (multiplier < 1 ether) {
                    uint256 donation = (currentWithdrawn * (1 ether - multiplier)) / PRECISION;
                    pendingMatic += donation;
                    emit LogDonation(donation);

                    // adjusts reserves when slashing
                    uint256 reserves = batchWithdrawOrders[currentBatchId].batchReserves;
                    if (reserves != 0) {
                        uint256 newReserves = (reserves * multiplier) / PRECISION;
                        batchWithdrawOrders[currentBatchId].batchReserves = newReserves;
                    }
                }

                currentWithdrawn = 0;
                batchId++;
            }

            if (active) {
                // Burns MATIC on Polygon side
                MATIC.withdraw{value: pendingMatic}(pendingMatic);

                // Sends message to UserProxy
                bytes memory data = abi.encode(DEPOSIT_CODE, pendingMatic, pendingCsMatic, currentBatchId);
                _sendMessageToRoot(data);
                emit LogAutoBalance(currentBatchId, true, pendingMatic, pendingCsMatic, 0);

                pendingMatic = 0;
                pendingCsMatic = 0;
                latestBatchTime = block.timestamp;
            }
        }
    }

    /// @notice Balances between net staking/unstaking
    function _balance() internal {
        // Max MATIC that can be swapped between deposits and withdrawals depends on csMATIC
        uint256 maxMatic = _min(pendingMatic, _exchangeCsToken(pendingCsMatic));
        uint256 toReserve = _min(pendingWithdrawMatic, maxMatic);
        uint256 toReserveCs = _exchangeToken(toReserve);

        // Adjust swap accordingly to both sides
        pendingWithdrawMatic -= toReserve;
        pendingWithdrawCs -= toReserveCs;
        pendingMatic -= toReserve;
        pendingCsMatic -= toReserveCs;
        batchWithdrawOrders[batchId].batchReserves += toReserve;

        // Emit when increase rate creates mismatch
        if (pendingCsMatic != 0 && pendingMatic < _exchangeCsToken(pendingCsMatic)) {
            uint256 mismatch = _exchangeCsToken(pendingCsMatic) - pendingMatic;
            emit LogDepositMismatch(mismatch);
        }
    }

    /// @notice Checks for slashing and for unassigned batch rates
    function _checkBatches() internal {
        uint256 activeRate = batchWithdrawOrders[batchId].exchangeRate;
        uint256 currentRate = _exchangeCsToken(MAX_DECIMALS);
        if (activeRate == 0) {
            batchWithdrawOrders[batchId].exchangeRate = currentRate;
        } else if (activeRate > currentRate) {
            _autoBalance(true);
            batchWithdrawOrders[batchId].exchangeRate = currentRate;
        }
    }

    /// @notice Allows for donated MATIC to be tracked
    /// @return True if valid
    function donate() external payable whenNotPaused nonReentrant returns (bool) {
        pendingMatic += msg.value;
        emit LogDonation(msg.value);
        _balance();
        return true;
    }

    /// @notice Receives message form root and executes action
    /// @param _stateId id of the message, increases with each message received
    /// @param _sender should be RootTunnel (UserProxy).
    /// @param _data body of the message
    function _processMessageFromRoot(
        uint256 _stateId,
        address _sender,
        bytes memory _data
    ) internal override validateSender(_sender) {
        if (stateIdReceived[_stateId]) return;
        stateIdReceived[_stateId] = true;
        uint256 messageCode = abi.decode(_data, (uint256));
        if (messageCode == REGISTER_CLAIM_CODE) {
            (, uint256 _batchId, uint256 amount) = abi.decode(_data, (uint256, uint256, uint256));
            _registerClaimProceeded(_batchId, amount);
        } else {
            revert("Invalid Message Code");
        }
    }

    /// @notice Marks batch as claimable once balance is available
    /// @param _batchId list of claimed batches
    /// @param _amount actually received
    function _registerClaimProceeded(uint256 _batchId, uint256 _amount) internal {
        require(batchWithdrawOrders[_batchId].claimableAt == 0, "batchId already processed");
        batchWithdrawOrders[_batchId].received = _amount;
        batchWithdrawOrders[_batchId].claimableAt = block.timestamp;

        // when slashing, donate surplus of reserves
        uint256 requested = batchWithdrawOrders[_batchId].requested;
        uint256 reserves = batchWithdrawOrders[_batchId].batchReserves;
        if (requested > _amount && reserves != 0) {
            uint256 multiplier = (_amount * PRECISION) / requested;
            uint256 newReserves = (reserves * multiplier) / PRECISION;
            batchWithdrawOrders[_batchId].batchReserves = newReserves;

            uint256 donation = reserves - newReserves;
            pendingMatic += donation;
            _balance();
            emit LogDonation(donation);
        }
    }

    /** SWAP PROCESS **/

    /// @notice Accepts csTokenV1 from user & mints exact same number csTokenV2
    /// @return Bool confirmation of transaction.
    function swapTokens() public whenNotPaused nonReentrant returns (bool) {
        uint256 amountTokenV1 = csTokenV1.balanceOf(msg.sender);
        require(amountTokenV1 != 0, "Zero V1 Tokens");
        require(csTokenV1.transferFrom(msg.sender, address(this), amountTokenV1), "Transfer failed");
        require(csToken.mint(msg.sender, amountTokenV1), "Minting failed");
        emit LogSwap(msg.sender, amountTokenV1);
        return true;
    }

    /** ADMIN **/

    /// @notice fee to manually trigger the bridge by user in MATIC
    function setBridgeFee(uint256 _fee) external onlyRole(CS_SERVICE_ROLE) {
        bridgeFee = _fee;
    }

    /// @notice set the days and amounts required for bridge transfers
    /// @dev amounts in matic, days in integers (1 = 1 day)
    function setBridgeRequirements(BatchRequirements memory _requirements) external onlyRole(CS_SERVICE_ROLE) {
        require(_requirements.daysLow <= MAX_DAYS_LOW_FREQ, "daysLow too high");
        require(_requirements.daysLow > _requirements.daysMedium, "daysLow must be greater than daysMedium");
        require(_requirements.daysMedium > _requirements.daysHigh, "daysMedium must be greater than daysHigh");

        require(_requirements.amountHigh > _requirements.amountMedium, "amountHigh must be greater than amountMedium");

        require(
            _requirements.withdrawsThreshold >= MIN_WITHDRAW_THRESHOLD,
            "withdrawsThreshold must be greater than 500 MATIC"
        );

        batchRequirements = _requirements;
    }

    /// @notice set the min number of day to claim tokens when netted locally.
    /// @param _nDays is the minimum number of days.
    function setMinClaimDays(uint256 _nDays) external onlyRole(CS_SERVICE_ROLE) {
        require(_nDays <= MAX_UNBONDING_DAYS, "Minimum claim days too high");
        minClaimDays = _nDays * (1 days);
    }

    /// @notice set the treasury wallet
    /// @param _treasuryAddress new address for treasury
    function setTreasury(address _treasuryAddress) external onlyRole(TIMELOCK_UPGRADES_ROLE) {
        require(_treasuryAddress != address(0), "Invalid treasury address");
        treasury = _treasuryAddress;
    }

    /// @notice sets the vault to which matic tokens will be sent
    /// @param _claimVault address of the vault contract
    function setClaimVault(address _claimVault) external onlyRole(TIMELOCK_UPGRADES_ROLE) {
        require(_claimVault != address(0), "Invalid claimVault");
        claimVault = _claimVault;
    }

    /// @notice Sets new fee percent for given `feeType_` to `fee_`.
    /// @param _feeType : Index of `feeType` to be updated.
    /// @param _fee : New fee percent.
    function setFee(SetFee _feeType, uint256 _fee) external onlyRole(TIMELOCK_ROLE) {
        require(_fee < PERCENTAGE_BASE, "Invalid fee");
        uint256 oldFee = 0;
        if (_feeType == SetFee.DepositFee) {
            require(_fee <= MAX_DEPOSIT_FEE, "Invalid deposit fee");
            oldFee = fees.depositFee;
            fees.depositFee = _fee;
        } else if (_feeType == SetFee.WithdrawFee) {
            oldFee = fees.withdrawFee;
            require(_fee <= MAX_WITHDRAW_FEE, "Invalid withdraw fee");
            fees.withdrawFee = _fee;
        } else if (_feeType == SetFee.EarlyClaimFee) {
            oldFee = fees.earlyClaimFee;
            require(_fee <= MAX_EARLY_CLAIM_FEE, "Early Claim fee above max limit");
            fees.earlyClaimFee = _fee;
        } else if (_feeType == SetFee.InstantWithdrawFee) {
            oldFee = fees.instantWithdrawFee;
            require(_fee <= MAX_INSTANT_WITHDRAW_FEE, "Instant Withdraw fee above max limit");
            fees.instantWithdrawFee = _fee;
        }

        emit LogFeeUpdate(msg.sender, _feeType, oldFee, _fee);
    }

    /** SUPPORT **/

    /// @notice returns the smaller number between a and b
    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a > _b ? _b : _a;
    }

    /// @notice Triggers stopped state.
    function pause() external onlyRole(CS_SERVICE_ROLE) whenNotPaused {
        _pause();
    }

    /// @notice Returns to normal state.
    function unpause() external onlyRole(CS_SERVICE_ROLE) whenPaused {
        _unpause();
    }

    /// @notice Checks caller has the given `_roleName` or not.
    /// @param _roleName supported by RoleManager
    function _onlyRole(bytes32 _roleName) internal view {
        require(roleManager.checkRole(_roleName, msg.sender), "Auth Failed");
    }

    /// @notice Upgrade the implementation of the proxy to `_newImplementation`.
    /// @param _newImplementation : Address of new implementation of the contract
    function upgradeTo(address _newImplementation)
        external
        virtual
        override
        onlyRole(TIMELOCK_UPGRADES_ROLE)
        onlyProxy
    {
        _authorizeUpgrade(_newImplementation);
        _upgradeTo(_newImplementation);
    }

    /// @notice Function that should revert when `msg.sender` is not authorized to upgrade the contract or
    /// @param _newImplementation : Address of new implementation of the contract.
    function _authorizeUpgrade(address _newImplementation) internal virtual override onlyRole(TIMELOCK_UPGRADES_ROLE) {
        require(_newImplementation.code.length > 0, "!contract");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface IWETH9 {
    /// @notice Deposits native tokens & mints respective of wrapped tokens.
    function deposit() external payable;

    /// @notice Burns wrapped tokens & transfers respective of native tokens.
    function withdraw(uint256 _value) external;

    /// @notice Returns wrapped token balance of `_user`.
    function balanceOf(address _user) external view returns (uint256);

    /// @notice Approve `_spender` to spend `_amount` of tokens from `msg.sender`.
    function approve(address _spender, uint256 _amount) external returns (bool);

    /// @notice Transfers `_amount` of tokens from `_src` to `_dst`.
    function transferFrom(
        address _src,
        address _dst,
        uint256 _amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "./IClayBase.sol";

interface IClayManager is IClayBase {
    /// @notice Supported fee types. Matches fees ordering.
    enum SetFee {
        DepositFee,
        WithdrawFee,
        EarlyClaimFee,
        InstantWithdrawFee
    }

    /// @notice Struct used on ClayMatic fees
    struct Fees {
        uint256 depositFee;
        uint256 withdrawFee;
        uint256 earlyClaimFee;
        uint256 instantWithdrawFee;
    }

    /// @notice Struct used on ClayMatic for returning user withdraw order
    struct UserWithdrawOrderInfo {
        uint256 orderId;
        uint256 amount;
        uint256 fee;
        uint256 batchId;
        uint256 claimableAt;
        bool isClaimable;
        bool isEarlyClaimable;
    }

    function earlyClaim(uint256 _orderId) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface IRoleManager {
    /// @dev Returns a boolean value indicating whether `_account` has role `_roleName` or not.
    function checkRole(bytes32 _roleName, address _account) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface IClayTunnel {
    /// @notice Returns csMATIC supply and MATIC deposits on ClayMatic
    function getFunds() external view returns (uint256, uint256);

    /// @notice Entry point to receive and relay messages originating from the fxChild.
    /// @param _stateId unique state id.
    /// @param _rootMessageSender Address of Root message sender.
    /// @param _data bytes message that will be sent to Tunnel.
    function processMessageFromRoot(
        uint256 _stateId,
        address _rootMessageSender,
        bytes calldata _data
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface ICSToken {
    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `_account`.
    function balanceOf(address _account) external view returns (uint256);

    /// @notice Mints `_amount` of tokens `_to` user.
    function mint(address _to, uint256 _amount) external returns (bool);

    /// @notice Burns `_amount` of tokens `_from` user.
    function burn(address _from, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface IClaimVault {
    /// @notice Method to transfer funds to owner ClayManager
    function claimFunds() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface IFxRoot {
    /// @notice Send bytes message to Child Tunnel.
    /// @param _childContract Address of child contract.
    /// @param _message Bytes message that will be sent to Child Tunnel.
    function sendMessageToChild(address _childContract, bytes memory _message) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {UUPSUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20Upgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";

import "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

import "./tunnel/FxBaseRootTunnel.sol";
import "./interfaces/IRoleManager.sol";
import "./interfaces/IClayMain.sol";
import "./interfaces/IDepositManager.sol";
import "./interfaces/IERC20Predicate.sol";

contract UserProxy is UUPSUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, FxBaseRootTunnel {
    using SafeERC20Upgradeable for IERC20;

    /// @notice ClayStack's default list of access-control roles.
    bytes32 private constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");
    bytes32 private constant TIMELOCK_UPGRADES_ROLE = keccak256("TIMELOCK_UPGRADES_ROLE");
    bytes32 private constant CS_SERVICE_ROLE = keccak256("CS_SERVICE_ROLE");

    /// @notice Percentage precision used in ClayMatic
    uint256 private constant PERCENTAGE_BASE = 10000;
    uint256 private constant MAX_DECIMALS = 1e18;
    uint256 private constant DEPOSIT_CODE = 1;
    uint256 private constant WITHDRAW_CODE = 2;
    uint256 private constant REGISTER_CLAIM_CODE = 3;

    /// @notice Event for new deposit on ClayMatic
    /// @param batchID cross-chain id for this batch
    /// @param amount matic sent from polygon contract
    /// @param amountCs amount of CsMatic that was minted in polygon
    /// @param donation amount added to insurance
    event LogDeposit(uint256 indexed batchID, uint256 amount, uint256 amountCs, uint256 donation);

    /// @notice Event for new withdraw request on ClayMatic
    /// @param batchID cross-chain id for this batch
    /// @param amount matic expected
    /// @param amountCs amount of CsMatic to be withdraw
    event LogWithdraw(uint256 indexed batchID, uint256 amount, uint256 amountCs);

    /// @notice Event for withdraw claims on ClayMatic and send to bridge
    /// @param batchID cross-chain id for this batch
    /// @param amount of MATIC claimed
    /// @param orderIds list of ClayMatic orders claimed
    /// @param donation amount added to insurance
    event LogClaim(uint256 indexed batchID, uint256 amount, uint256[] orderIds, uint256 donation);

    /// @notice Event when insurance is used to cover mismatches given rate increases
    /// @param mismatch amount from deposits
    event LogDepositMismatch(uint256 mismatch);

    /// @notice RoleManager instance.
    IRoleManager private roleManager;

    /// @notice Ethereum's Polygon contract for Plasma deposits.
    IDepositManager private depositManager;

    /// @notice ClayMatic contract instance
    IClayMain private clayMatic;

    /// @notice instance for matic token
    IERC20 private maticToken;

    /// @notice instance for csMatic token
    IERC20 private csMaticToken;

    /// @notice Polygon's ERC20Predicate contract for ERC20 tokens in ethereum
    address private erc20Predicate;

    /// @notice address of the vault that receive matic in polygon
    address public claimVault;

    /// @notice treasury address
    address public treasury;

    /// @notice Maps batchID in polygon to orderIDs in ethereum
    mapping(uint256 => uint256[]) public batchOrder;

    /// @notice Maps batchID to expected MATIC from withdraws
    mapping(uint256 => uint256) public withdrawMaticExpected;

    /// @notice Maps batchID to withdraw epoch
    mapping(uint256 => uint256) public batchWithdrawEpoch;

    /// @notice MATIC kept for insurance and treasury purposes
    uint256 public insurance;

    /// @notice Check if the msg.sender has permission.
    /// @param _roleName : bytes32 hash of the role.
    modifier onlyRole(bytes32 _roleName) {
        _onlyRole(_roleName);
        _;
    }

    /// @notice Initializes the contract and adds approval for token transfer
    /// @param _clayMatic : Address of clayMatic contract.
    /// @param _depositManager : Address of Plasma deposits contract.
    /// @param _checkpointManager : Address of Polygon's checkPointManager contract.
    /// @param _fxRoot : Address of Polygon's root state channel contract.
    /// @param _maticToken : Address of matic token.
    /// @param _csMaticToken : Address of csMatic token.
    /// @param _erc20Predicate : Address of ERC20Predicate contract in ethereum.
    /// @param _roleManager : Address of ClayStack's RoleManager.
    /// @param _treasury : Address of ClayStack's treasury.
    function initialize(
        address _clayMatic,
        address _depositManager,
        address _checkpointManager,
        address _fxRoot,
        address _maticToken,
        address _csMaticToken,
        address _erc20Predicate,
        address _roleManager,
        address _treasury
    ) external initializer onlyProxy {
        require(_clayMatic != address(0), "Invalid ClayMatic");
        require(_depositManager != address(0), "Invalid Deposit Manager");
        require(_checkpointManager != address(0), "Invalid checkpointManager");
        require(_fxRoot != address(0), "Invalid fxRoot");
        require(_maticToken != address(0), "Invalid maticToken");
        require(_csMaticToken != address(0), "Invalid csMaticToken");
        require(_erc20Predicate != address(0), "Invalid erc20Predicate");
        require(_roleManager != address(0), "Invalid roleManager");
        require(_treasury != address(0), "Invalid treasury address");

        clayMatic = IClayMain(_clayMatic);
        depositManager = IDepositManager(_depositManager);

        initializeRootTunnel(_checkpointManager, _fxRoot);
        setFxChildTunnel(address(this));

        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        maticToken = IERC20(_maticToken);
        csMaticToken = IERC20(_csMaticToken);
        roleManager = IRoleManager(_roleManager);
        treasury = _treasury;

        erc20Predicate = _erc20Predicate;

        require(maticToken.approve(_clayMatic, type(uint256).max), "Failed Approval Matic");
        require(csMaticToken.approve(_clayMatic, type(uint256).max), "Failed Approval CsMatic");
    }

    /// @notice Deposits tokens on ClayMatic based on given csMATIC amount minted on polygon.
    /// @param _amountMatic : amount deposited in polygon in exchange of csMatic.
    /// @param _amountCsMatic : amount of csMatic that was minted.
    /// @param _batchId : Identifies the batch from net staking
    function deposit(
        uint256 _amountMatic,
        uint256 _amountCsMatic,
        uint256 _batchId
    ) private {
        (uint256 rate, ) = clayMatic.getExchangeRate(); // matic/csMatic
        IClayMain.Fees memory fees = clayMatic.fees();
        uint256 amount = (_amountCsMatic * rate * PERCENTAGE_BASE) / (PERCENTAGE_BASE - fees.depositFee) / MAX_DECIMALS;
        require(
            maticToken.balanceOf(address(this)) >= amount && _amountMatic + insurance >= amount,
            "Deposit ClayMatic mismatch"
        );

        // Calculate extra and keep track in insurance
        uint256 donation = 0;
        if (_amountMatic > amount) {
            donation = _amountMatic - amount;
            insurance += donation;
        } else {
            uint256 mismatch = amount - _amountMatic;
            if (mismatch != 0 && mismatch <= insurance) {
                insurance -= mismatch;
                emit LogDepositMismatch(mismatch);
            }
        }

        require(clayMatic.deposit(amount), "ClayMatic deposit failed");

        emit LogDeposit(_batchId, amount, _amountCsMatic, donation);
    }

    /// @notice Withdraws tokens as part of a batch which will be claimed.
    /// @param _amountCsMatic : amount of csMatic to withdraw.
    /// @param _amountMatic : amount of MATIC expected.
    /// @param _batchId : Identifies the batch to be withdrawn (a group of withdraw orders are included in a batch).
    function withdraw(
        uint256 _amountCsMatic,
        uint256 _amountMatic,
        uint256 _batchId
    ) private {
        uint256 totalAmount = 0;
        while (totalAmount < _amountCsMatic) {
            uint256 maxAmount = clayMatic.getMaxWithdrawAmountCs();
            uint256 value = _min(maxAmount, _amountCsMatic - totalAmount);
            totalAmount += value;
            uint256 orderId = clayMatic.withdraw(value);
            batchOrder[_batchId].push(orderId);
        }

        (uint256 currentEpoch, ) = clayMatic.getEpoch();
        batchWithdrawEpoch[_batchId] = currentEpoch;

        withdrawMaticExpected[_batchId] = _amountMatic;
        emit LogWithdraw(_batchId, _amountMatic, _amountCsMatic);
    }

    /// @notice Claims completed withdraw orders from ClayMatic & sends tokens to polygon.
    /// @dev Accounts for any slashing event receiving less than expected.
    /// @param _batchId : batch to be claimed.
    function claim(uint256 _batchId) external whenNotPaused nonReentrant {
        require(claimVault != address(0), "ClaimVault has not been set");

        uint256[] memory _orderIds = batchOrder[_batchId];
        require(_orderIds.length != 0, "Invalid batch");

        // Claims from ClayMatic
        uint256 balanceBefore = maticToken.balanceOf(address(this));
        require(clayMatic.claim(_orderIds), "Claim Failed");
        uint256 totalAmount = maticToken.balanceOf(address(this)) - balanceBefore;

        // Calculate whether more than expected and donate
        uint256 expectedMatic = withdrawMaticExpected[_batchId];
        uint256 donation = 0;
        if (totalAmount > expectedMatic) {
            donation = totalAmount - expectedMatic;
            insurance += donation;
            totalAmount = expectedMatic;
        }

        // Deposit MATIC through plasma, using same address as self
        require(maticToken.approve(address(depositManager), totalAmount), "Failed Approval DepositManager");
        depositManager.depositERC20ForUser(address(maticToken), claimVault, totalAmount);

        bytes memory data = abi.encode(REGISTER_CLAIM_CODE, _batchId, totalAmount);
        _sendMessageToChild(data);

        emit LogClaim(_batchId, totalAmount, _orderIds, donation);
    }

    /// @notice Pass-through for bridging tokens from Polygon to Ethereum
    /// @dev Requirement to be called by the same address of burn tokens
    /// @param _data : Proof of burn Payload from Polygon's bridge
    function startExitWithBurntTokens(bytes calldata _data) external {
        IERC20Predicate predicate = IERC20Predicate(erc20Predicate);
        predicate.startExitWithBurntTokens(_data);
    }

    /// @notice Process insurance towards ClayMatic donation and fees
    /// @param _amountFees to be transferred towards the bridge cost coverage
    /// @param _amountDonation to be transferred as donation to ClayMatic
    function processInsurance(uint256 _amountFees, uint256 _amountDonation)
        external
        nonReentrant
        onlyRole(TIMELOCK_ROLE)
    {
        require(_amountFees + _amountDonation <= insurance, "Amount exceeds insurance");
        insurance -= (_amountFees + _amountDonation);
        require(maticToken.transfer(address(clayMatic), _amountDonation), "Donation transfer failed");
        require(maticToken.transfer(treasury, _amountFees), "Treasury transfer failed");
    }

    /// @notice Allows for donated MATIC to be added as insurance
    /// @param _amount of MATIC to add
    function donate(uint256 _amount) external whenNotPaused nonReentrant {
        require(maticToken.transferFrom(msg.sender, address(this), _amount), "Donation transfer failed");
        insurance += _amount;
    }

    /// @notice sets the vault to which matic tokens will be sent
    /// @param _claimVault address of the vault contract
    function setClaimVault(address _claimVault) external onlyRole(TIMELOCK_UPGRADES_ROLE) {
        require(_claimVault != address(0), "Invalid claimVault");
        claimVault = _claimVault;
    }

    /// @notice set the treasury wallet
    /// @param _treasuryAddress new address for treasury
    function setTreasury(address _treasuryAddress) external onlyRole(TIMELOCK_UPGRADES_ROLE) {
        require(_treasuryAddress != address(0), "Invalid treasury address");
        treasury = _treasuryAddress;
    }

    /// @notice Runs function signature encoded data received as a message.
    /// @param _data : Encoded data in bytes.
    function _processMessageFromChild(bytes memory _data) internal override whenNotPaused {
        uint256 messageCode = abi.decode(_data, (uint256));
        if (messageCode == DEPOSIT_CODE) {
            (, uint256 amountMatic, uint256 amountCsMatic, uint256 batchId) = abi.decode(
                _data,
                (uint256, uint256, uint256, uint256)
            );
            deposit(amountMatic, amountCsMatic, batchId);
        } else if (messageCode == WITHDRAW_CODE) {
            (, uint256 amountCsMatic, uint256 amountMatic, uint256 batchId) = abi.decode(
                _data,
                (uint256, uint256, uint256, uint256)
            );
            withdraw(amountCsMatic, amountMatic, batchId);
        } else {
            revert("Invalid Message Code");
        }
    }

    /** SUPPORT **/

    /// @notice returns the smaller number between a and b
    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a > _b ? _b : _a;
    }

    /// @notice Triggers stopped state.
    function pause() external onlyRole(CS_SERVICE_ROLE) whenNotPaused {
        _pause();
    }

    /// @notice Returns to normal state.
    function unpause() external onlyRole(CS_SERVICE_ROLE) whenPaused {
        _unpause();
    }

    /// @notice Checks caller has the given `_roleName` or not.
    /// @param _roleName supported by RoleManager
    function _onlyRole(bytes32 _roleName) internal view {
        require(roleManager.checkRole(_roleName, msg.sender), "Auth Failed");
    }

    /// @notice Checks if given batch is claimable or not.
    /// @param _batchId batch to be checked.
    function isClaimable(uint256 _batchId) public view returns (bool) {
        uint256 batchEpoch = batchWithdrawEpoch[_batchId];
        (uint256 currentEpoch, uint256 currentDelay) = clayMatic.getEpoch();
        return currentEpoch >= batchEpoch + currentDelay;
    }

    /// @notice Upgrade the implementation of the proxy to `_newImplementation`.
    /// @param _newImplementation : Address of new implementation of the contract
    function upgradeTo(address _newImplementation)
        external
        virtual
        override
        onlyRole(TIMELOCK_UPGRADES_ROLE)
        onlyProxy
    {
        _authorizeUpgrade(_newImplementation);
        _upgradeTo(_newImplementation);
    }

    /// @notice Function that should revert when `msg.sender` is not authorized to upgrade the contract or
    /// @param _newImplementation : Address of new implementation of the contract.
    function _authorizeUpgrade(address _newImplementation) internal virtual override onlyRole(TIMELOCK_UPGRADES_ROLE) {
        require(_newImplementation.code.length > 0, "!contract");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) internal {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

interface IChildToken is IERC20 {
    /// @notice called when token is deposited on root chain.
    /// @dev Callable only by ChildChainManager
    /// Should handle deposit by minting the required amount for user
    /// Make sure minting is done only by this function
    /// @param _user user address for whom deposit is being done
    /// @param _depositData abi encoded amount
    function deposit(address _user, bytes calldata _depositData) external;

    /// @notice called when user wants to withdraw tokens back to root chain.
    /// @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
    /// @param _amount amount of tokens to withdraw
    function withdraw(uint256 _amount) external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface IClayBase {
    /// @notice Sends `_amountToken` Token to ClayMain contract and mints csToken to msg.sender.
    function deposit(uint256 _amountToken) external returns (bool);

    /// @notice Sends `_amountToken` Token to ClayMain contract and mints csToken to `_delegator`.
    function depositDelegate(uint256 _amountToken, address _delegator) external returns (bool);

    /// @notice Burns `_amountCs` csToken tokens from user and unstake respective amounts of Token tokens from node.
    function withdraw(uint256 _amountCs) external returns (uint256);

    /// @notice Allows user to claim unstaked tokens.
    function claim(uint256[] calldata _orderIds) external returns (bool);

    /// @notice Performs claiming of rewards & staking of Token tokens for ClayStack.
    function autoBalance() external payable returns (bool);

    /// @notice Exchange rate accounting for any slashing or donations. Reports if slashed
    function getExchangeRate() external view returns (uint256, bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RLPReader} from "../lib/RLPReader.sol";
import {MerklePatriciaProof} from "../lib/MerklePatriciaProof.sol";
import {Merkle} from "../lib/Merkle.sol";
import "../lib/ExitPayloadReader.sol";

interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

contract ICheckpointManager {
    struct HeaderBlock {
        bytes32 root;
        uint256 start;
        uint256 end;
        uint256 createdAt;
        address proposer;
    }

    /**
     * @notice mapping of checkpoint header numbers to block details
     * @dev These checkpoints are submited by plasma contracts
     */
    mapping(uint256 => HeaderBlock) public headerBlocks;
}

abstract contract FxBaseRootTunnel {
    using RLPReader for RLPReader.RLPItem;
    using Merkle for bytes32;
    using ExitPayloadReader for bytes;
    using ExitPayloadReader for ExitPayloadReader.ExitPayload;
    using ExitPayloadReader for ExitPayloadReader.Log;
    using ExitPayloadReader for ExitPayloadReader.LogTopics;
    using ExitPayloadReader for ExitPayloadReader.Receipt;

    // keccak256(MessageSent(bytes))
    bytes32 public constant SEND_MESSAGE_EVENT_SIG = 0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036;

    // state sender contract
    IFxStateSender public fxRoot;
    // root chain manager
    ICheckpointManager public checkpointManager;
    // child tunnel contract which receives and sends messages
    address public fxChildTunnel;

    // storage to avoid duplicate exits
    mapping(bytes32 => bool) public processedExits;

    function initializeRootTunnel(address _checkpointManager, address _fxRoot) internal {
        checkpointManager = ICheckpointManager(_checkpointManager);
        fxRoot = IFxStateSender(_fxRoot);
    }

    // set fxChildTunnel if not set already
    function setFxChildTunnel(address _fxChildTunnel) public virtual {
        require(fxChildTunnel == address(0x0), "FxBaseRootTunnel: CHILD_TUNNEL_ALREADY_SET");
        fxChildTunnel = _fxChildTunnel;
    }

    /**
     * @notice Send bytes message to Child Tunnel
     * @param message bytes message that will be sent to Child Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToChild(bytes memory message) internal {
        fxRoot.sendMessageToChild(fxChildTunnel, message);
    }

    function _validateAndExtractMessage(bytes memory inputData) internal returns (bytes memory) {
        ExitPayloadReader.ExitPayload memory payload = inputData.toExitPayload();

        bytes memory branchMaskBytes = payload.getBranchMaskAsBytes();
        uint256 blockNumber = payload.getBlockNumber();
        // checking if exit has already been processed
        // unique exit is identified using hash of (blockNumber, branchMask, receiptLogIndex)
        bytes32 exitHash = keccak256(
            abi.encodePacked(
                blockNumber,
                // first 2 nibbles are dropped while generating nibble array
                // this allows branch masks that are valid but bypass exitHash check (changing first 2 nibbles only)
                // so converting to nibble array and then hashing it
                MerklePatriciaProof._getNibbleArray(branchMaskBytes),
                payload.getReceiptLogIndex()
            )
        );
        require(processedExits[exitHash] == false, "FxRootTunnel: EXIT_ALREADY_PROCESSED");
        processedExits[exitHash] = true;

        ExitPayloadReader.Receipt memory receipt = payload.getReceipt();
        ExitPayloadReader.Log memory log = receipt.getLog();

        // check child tunnel
        require(fxChildTunnel == log.getEmitter(), "FxRootTunnel: INVALID_FX_CHILD_TUNNEL");

        bytes32 receiptRoot = payload.getReceiptRoot();
        // verify receipt inclusion
        require(
            MerklePatriciaProof.verify(receipt.toBytes(), branchMaskBytes, payload.getReceiptProof(), receiptRoot),
            "FxRootTunnel: INVALID_RECEIPT_PROOF"
        );

        // verify checkpoint inclusion
        _checkBlockMembershipInCheckpoint(
            blockNumber,
            payload.getBlockTime(),
            payload.getTxRoot(),
            receiptRoot,
            payload.getHeaderNumber(),
            payload.getBlockProof()
        );

        ExitPayloadReader.LogTopics memory topics = log.getTopics();

        require(
            bytes32(topics.getField(0).toUint()) == SEND_MESSAGE_EVENT_SIG, // topic0 is event sig
            "FxRootTunnel: INVALID_SIGNATURE"
        );

        // received message data
        bytes memory message = abi.decode(log.getData(), (bytes)); // event decodes params again, so decoding bytes to get message
        return message;
    }

    function _checkBlockMembershipInCheckpoint(
        uint256 blockNumber,
        uint256 blockTime,
        bytes32 txRoot,
        bytes32 receiptRoot,
        uint256 headerNumber,
        bytes memory blockProof
    ) private view returns (uint256) {
        (bytes32 headerRoot, uint256 startBlock, , uint256 createdAt, ) = checkpointManager.headerBlocks(headerNumber);

        require(
            keccak256(abi.encodePacked(blockNumber, blockTime, txRoot, receiptRoot)).checkMembership(
                blockNumber - startBlock,
                headerRoot,
                blockProof
            ),
            "FxRootTunnel: INVALID_HEADER"
        );
        return createdAt;
    }

    /**
     * @notice receive message from  L2 to L1, validated by proof
     * @dev This function verifies if the transaction actually happened on child chain
     *
     * @param inputData RLP encoded data of the reference tx containing following list of fields
     *  0 - headerNumber - Checkpoint header block number containing the reference tx
     *  1 - blockProof - Proof that the block header (in the child chain) is a leaf in the submitted merkle root
     *  2 - blockNumber - Block number containing the reference tx on child chain
     *  3 - blockTime - Reference tx block time
     *  4 - txRoot - Transactions root of block
     *  5 - receiptRoot - Receipts root of block
     *  6 - receipt - Receipt of the reference transaction
     *  7 - receiptProof - Merkle proof of the reference receipt
     *  8 - branchMask - 32 bits denoting the path of receipt in merkle tree
     *  9 - receiptLogIndex - Log Index to read from the receipt
     */
    function receiveMessage(bytes memory inputData) public virtual {
        bytes memory message = _validateAndExtractMessage(inputData);
        _processMessageFromChild(message);
    }

    /**
     * @notice Process message received from Child Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param message bytes message that was sent from Child Tunnel
     */
    function _processMessageFromChild(bytes memory message) internal virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "./IClayBase.sol";

interface IClayMain is IClayBase {
    /// @notice Supported fee types. Matches fees ordering.
    enum SetFee {
        DepositFee,
        WithdrawFee,
        InstantWithdrawFee,
        RewardFee,
        StakingFee
    }

    /// @notice Struct used on ClayMatic fees
    struct Fees {
        uint256 depositFee;
        uint256 withdrawFee;
        uint256 instantWithdrawFee;
        uint256 rewardFee;
    }

    /// @notice Current ClayMatic fees
    function fees() external view returns (Fees memory);

    // @notice Calculates and returns max amount of csToken that can be withdrawn in a given transaction
    function getMaxWithdrawAmountCs() external view returns (uint256);

    /// @notice returns current epoch and withdraw delay
    function getEpoch() external view returns (uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface IDepositManager {
    /// @notice Deposit `_amount` of `_token` tokens on `_user` behalf via bridge,.
    /// @param _token Depositing token address.
    /// @param _user Depositing user address.
    /// @param _amount Amount of tokens deposited.
    function depositERC20ForUser(
        address _token,
        address _user,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

// https://github.com/maticnetwork/contracts/blob/main/contracts/root/predicates/ERC20Predicate.sol#L71

interface IERC20Predicate {
    function startExitWithBurntTokens(bytes calldata _data) external;
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

// SPDX-License-Identifier: UNLICENSED
/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 */
pragma solidity ^0.8.0;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    struct Iterator {
        RLPItem item; // Item that's being iterated over.
        uint256 nextPtr; // Position of the next item in the list.
    }

    /*
     * @dev Returns the next element in the iteration. Reverts if it has not next element.
     * @param self The iterator.
     * @return The next element in the iteration.
     */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint256 ptr = self.nextPtr;
        uint256 itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
     * @dev Returns true if the iteration has more elements.
     * @param self The iterator.
     * @return true if the iteration has more elements.
     */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint256 memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
     * @dev Create an iterator. Reverts if item is not a list.
     * @param self The RLP item.
     * @return An 'Iterator' over the item.
     */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint256 ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
     * @param item RLP encoded bytes
     */
    function rlpLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function payloadLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len - _payloadOffset(item.memPtr);
    }

    /*
     * @param item RLP encoded list in bytes
     */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint256 items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START) return false;
        return true;
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        uint256 ptr = item.memPtr;
        uint256 len = item.len;
        bytes32 result;
        assembly {
            result := keccak256(ptr, len)
        }
        return result;
    }

    function payloadLocation(RLPItem memory item) internal pure returns (uint256, uint256) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 memPtr = item.memPtr + offset;
        uint256 len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the item payload.
     */
    function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint256 result;
        uint256 memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(item.len > 0 && item.len <= 33);

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset;

        uint256 result;
        uint256 memPtr = item.memPtr + offset;
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
        // one byte prefix
        require(item.len == 33);

        uint256 result;
        uint256 memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint256 destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }

    /*
     * Private Helpers
     */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint256) {
        if (item.len == 0) return 0;

        uint256 count = 0;
        uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint256 memPtr) private pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) itemLen = 1;
        else if (byte0 < STRING_LONG_START) itemLen = byte0 - STRING_SHORT_START + 1;
        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte
                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) return 1;
        else if (byte0 < LIST_SHORT_START)
            // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /*
     * @param src Pointer to source
     * @param dest Pointer to destination
     * @param len Amount of memory to copy from the source
     */
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len == 0) return;

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint256 mask = 256**(WORD_SIZE - len) - 1;

        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";

library MerklePatriciaProof {
    /*
     * @dev Verifies a merkle patricia proof.
     * @param value The terminating value in the trie.
     * @param encodedPath The path in the trie leading to value.
     * @param rlpParentNodes The rlp encoded stack of nodes.
     * @param root The root hash of the trie.
     * @return The boolean validity of the proof.
     */
    function verify(
        bytes memory value,
        bytes memory encodedPath,
        bytes memory rlpParentNodes,
        bytes32 root
    ) internal pure returns (bool) {
        RLPReader.RLPItem memory item = RLPReader.toRlpItem(rlpParentNodes);
        RLPReader.RLPItem[] memory parentNodes = RLPReader.toList(item);

        bytes memory currentNode;
        RLPReader.RLPItem[] memory currentNodeList;

        bytes32 nodeKey = root;
        uint256 pathPtr = 0;

        bytes memory path = _getNibbleArray(encodedPath);
        if (path.length == 0) {
            return false;
        }

        for (uint256 i = 0; i < parentNodes.length; i++) {
            if (pathPtr > path.length) {
                return false;
            }

            currentNode = RLPReader.toRlpBytes(parentNodes[i]);
            if (nodeKey != keccak256(currentNode)) {
                return false;
            }
            currentNodeList = RLPReader.toList(parentNodes[i]);

            if (currentNodeList.length == 17) {
                if (pathPtr == path.length) {
                    if (keccak256(RLPReader.toBytes(currentNodeList[16])) == keccak256(value)) {
                        return true;
                    } else {
                        return false;
                    }
                }

                uint8 nextPathNibble = uint8(path[pathPtr]);
                if (nextPathNibble > 16) {
                    return false;
                }
                nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[nextPathNibble]));
                pathPtr += 1;
            } else if (currentNodeList.length == 2) {
                uint256 traversed = _nibblesToTraverse(RLPReader.toBytes(currentNodeList[0]), path, pathPtr);
                if (pathPtr + traversed == path.length) {
                    //leaf node
                    if (keccak256(RLPReader.toBytes(currentNodeList[1])) == keccak256(value)) {
                        return true;
                    } else {
                        return false;
                    }
                }

                //extension node
                if (traversed == 0) {
                    return false;
                }

                pathPtr += traversed;
                nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[1]));
            } else {
                return false;
            }
        }
    }

    function _nibblesToTraverse(
        bytes memory encodedPartialPath,
        bytes memory path,
        uint256 pathPtr
    ) private pure returns (uint256) {
        uint256 len = 0;
        // encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
        // and slicedPath have elements that are each one hex character (1 nibble)
        bytes memory partialPath = _getNibbleArray(encodedPartialPath);
        bytes memory slicedPath = new bytes(partialPath.length);

        // pathPtr counts nibbles in path
        // partialPath.length is a number of nibbles
        for (uint256 i = pathPtr; i < pathPtr + partialPath.length; i++) {
            bytes1 pathNibble = path[i];
            slicedPath[i - pathPtr] = pathNibble;
        }

        if (keccak256(partialPath) == keccak256(slicedPath)) {
            len = partialPath.length;
        } else {
            len = 0;
        }
        return len;
    }

    // bytes b must be hp encoded
    function _getNibbleArray(bytes memory b) internal pure returns (bytes memory) {
        bytes memory nibbles = "";
        if (b.length > 0) {
            uint8 offset;
            uint8 hpNibble = uint8(_getNthNibbleOfBytes(0, b));
            if (hpNibble == 1 || hpNibble == 3) {
                nibbles = new bytes(b.length * 2 - 1);
                bytes1 oddNibble = _getNthNibbleOfBytes(1, b);
                nibbles[0] = oddNibble;
                offset = 1;
            } else {
                nibbles = new bytes(b.length * 2 - 2);
                offset = 0;
            }

            for (uint256 i = offset; i < nibbles.length; i++) {
                nibbles[i] = _getNthNibbleOfBytes(i - offset + 2, b);
            }
        }
        return nibbles;
    }

    function _getNthNibbleOfBytes(uint256 n, bytes memory str) private pure returns (bytes1) {
        return bytes1(n % 2 == 0 ? uint8(str[n / 2]) / 0x10 : uint8(str[n / 2]) % 0x10);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Merkle {
    function checkMembership(
        bytes32 leaf,
        uint256 index,
        bytes32 rootHash,
        bytes memory proof
    ) internal pure returns (bool) {
        require(proof.length % 32 == 0, "Invalid proof length");
        uint256 proofHeight = proof.length / 32;
        // Proof of size n means, height of the tree is n+1.
        // In a tree of height n+1, max #leafs possible is 2 ^ n
        require(index < 2**proofHeight, "Leaf index is too big");

        bytes32 proofElement;
        bytes32 computedHash = leaf;
        for (uint256 i = 32; i <= proof.length; i += 32) {
            assembly {
                proofElement := mload(add(proof, i))
            }

            if (index % 2 == 0) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }

            index = index / 2;
        }
        return computedHash == rootHash;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";

library ExitPayloadReader {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    uint8 constant WORD_SIZE = 32;

    struct ExitPayload {
        RLPReader.RLPItem[] data;
    }

    struct Receipt {
        RLPReader.RLPItem[] data;
        bytes raw;
        uint256 logIndex;
    }

    struct Log {
        RLPReader.RLPItem data;
        RLPReader.RLPItem[] list;
    }

    struct LogTopics {
        RLPReader.RLPItem[] data;
    }

    // copy paste of private copy() from RLPReader to avoid changing of existing contracts
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }
        
        if (len == 0) return;

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint256 mask = 256**(WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }

    function toExitPayload(bytes memory data) internal pure returns (ExitPayload memory) {
        RLPReader.RLPItem[] memory payloadData = data.toRlpItem().toList();

        return ExitPayload(payloadData);
    }

    function getHeaderNumber(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[0].toUint();
    }

    function getBlockProof(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[1].toBytes();
    }

    function getBlockNumber(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[2].toUint();
    }

    function getBlockTime(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[3].toUint();
    }

    function getTxRoot(ExitPayload memory payload) internal pure returns (bytes32) {
        return bytes32(payload.data[4].toUint());
    }

    function getReceiptRoot(ExitPayload memory payload) internal pure returns (bytes32) {
        return bytes32(payload.data[5].toUint());
    }

    function getReceipt(ExitPayload memory payload) internal pure returns (Receipt memory receipt) {
        receipt.raw = payload.data[6].toBytes();
        RLPReader.RLPItem memory receiptItem = receipt.raw.toRlpItem();

        if (receiptItem.isList()) {
            // legacy tx
            receipt.data = receiptItem.toList();
        } else {
            // pop first byte before parsting receipt
            bytes memory typedBytes = receipt.raw;
            bytes memory result = new bytes(typedBytes.length - 1);
            uint256 srcPtr;
            uint256 destPtr;
            assembly {
                srcPtr := add(33, typedBytes)
                destPtr := add(0x20, result)
            }

            copy(srcPtr, destPtr, result.length);
            receipt.data = result.toRlpItem().toList();
        }

        receipt.logIndex = getReceiptLogIndex(payload);
        return receipt;
    }

    function getReceiptProof(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[7].toBytes();
    }

    function getBranchMaskAsBytes(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[8].toBytes();
    }

    function getBranchMaskAsUint(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[8].toUint();
    }

    function getReceiptLogIndex(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[9].toUint();
    }

    // Receipt methods
    function toBytes(Receipt memory receipt) internal pure returns (bytes memory) {
        return receipt.raw;
    }

    function getLog(Receipt memory receipt) internal pure returns (Log memory) {
        RLPReader.RLPItem memory logData = receipt.data[3].toList()[receipt.logIndex];
        return Log(logData, logData.toList());
    }

    // Log methods
    function getEmitter(Log memory log) internal pure returns (address) {
        return RLPReader.toAddress(log.list[0]);
    }

    function getTopics(Log memory log) internal pure returns (LogTopics memory) {
        return LogTopics(log.list[1].toList());
    }

    function getData(Log memory log) internal pure returns (bytes memory) {
        return log.list[2].toBytes();
    }

    function toRlpBytes(Log memory log) internal pure returns (bytes memory) {
        return log.data.toRlpBytes();
    }

    // LogTopics methods
    function getField(LogTopics memory topics, uint256 index) internal pure returns (RLPReader.RLPItem memory) {
        return topics.data[index];
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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (governance/TimelockController.sol)

pragma solidity ^0.8.0;

import "../access/AccessControl.sol";
import "../token/ERC721/IERC721Receiver.sol";
import "../token/ERC1155/IERC1155Receiver.sol";
import "../utils/Address.sol";

/**
 * @dev Contract module which acts as a timelocked controller. When set as the
 * owner of an `Ownable` smart contract, it enforces a timelock on all
 * `onlyOwner` maintenance operations. This gives time for users of the
 * controlled contract to exit before a potentially dangerous maintenance
 * operation is applied.
 *
 * By default, this contract is self administered, meaning administration tasks
 * have to go through the timelock process. The proposer (resp executor) role
 * is in charge of proposing (resp executing) operations. A common use case is
 * to position this {TimelockController} as the owner of a smart contract, with
 * a multisig or a DAO as the sole proposer.
 *
 * _Available since v3.3._
 */
contract TimelockController is AccessControl, IERC721Receiver, IERC1155Receiver {
    bytes32 public constant TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant CANCELLER_ROLE = keccak256("CANCELLER_ROLE");
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(bytes32 => uint256) private _timestamps;
    uint256 private _minDelay;

    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(bytes32 indexed id);

    /**
     * @dev Emitted when the minimum delay for future operations is modified.
     */
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /**
     * @dev Initializes the contract with a given `minDelay`, and a list of
     * initial proposers and executors. The proposers receive both the
     * proposer and the canceller role (for backward compatibility). The
     * executors receive the executor role.
     *
     * NOTE: At construction, both the deployer and the timelock itself are
     * administrators. This helps further configuration of the timelock by the
     * deployer. After configuration is done, it is recommended that the
     * deployer renounces its admin position and relies on timelocked
     * operations to perform future maintenance.
     */
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) {
        _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(CANCELLER_ROLE, TIMELOCK_ADMIN_ROLE);

        // deployer + self administration
        _setupRole(TIMELOCK_ADMIN_ROLE, _msgSender());
        _setupRole(TIMELOCK_ADMIN_ROLE, address(this));

        // register proposers and cancellers
        for (uint256 i = 0; i < proposers.length; ++i) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
            _setupRole(CANCELLER_ROLE, proposers[i]);
        }

        // register executors
        for (uint256 i = 0; i < executors.length; ++i) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }

        _minDelay = minDelay;
        emit MinDelayChange(0, minDelay);
    }

    /**
     * @dev Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AccessControl) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns whether an id correspond to a registered operation. This
     * includes both Pending, Ready and Done operations.
     */
    function isOperation(bytes32 id) public view virtual returns (bool registered) {
        return getTimestamp(id) > 0;
    }

    /**
     * @dev Returns whether an operation is pending or not.
     */
    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns the timestamp at with an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    /**
     * @dev Returns the minimum delay for an operation to become valid.
     *
     * This value can be changed by executing an operation that calls `updateDelay`.
     */
    function getMinDelay() public view virtual returns (uint256 duration) {
        return _minDelay;
    }

    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    /**
     * @dev Returns the identifier of an operation containing a batch of
     * transactions.
     */
    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, payloads, predecessor, salt));
    }

    /**
     * @dev Schedule an operation containing a single transaction.
     *
     * Emits a {CallScheduled} event.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    /**
     * @dev Schedule an operation containing a batch of transactions.
     *
     * Emits one {CallScheduled} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == payloads.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, payloads, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], payloads[i], predecessor, delay);
        }
    }

    /**
     * @dev Schedule an operation that is to becomes valid after a given delay.
     */
    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= getMinDelay(), "TimelockController: insufficient delay");
        _timestamps[id] = block.timestamp + delay;
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'canceller' role.
     */
    function cancel(bytes32 id) public virtual onlyRole(CANCELLER_ROLE) {
        require(isOperationPending(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    // This function can reenter, but it doesn't pose a risk because _afterCall checks that the proposal is pending,
    // thus any modifications to the operation during reentrancy should be caught.
    // slither-disable-next-line reentrancy-eth
    function execute(
        address target,
        uint256 value,
        bytes calldata payload,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, payload, predecessor, salt);

        _beforeCall(id, predecessor);
        _execute(target, value, payload);
        emit CallExecuted(id, 0, target, value, payload);
        _afterCall(id);
    }

    /**
     * @dev Execute an (ready) operation containing a batch of transactions.
     *
     * Emits one {CallExecuted} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == payloads.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, payloads, predecessor, salt);

        _beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            address target = targets[i];
            uint256 value = values[i];
            bytes calldata payload = payloads[i];
            _execute(target, value, payload);
            emit CallExecuted(id, i, target, value, payload);
        }
        _afterCall(id);
    }

    /**
     * @dev Execute an operation's call.
     */
    function _execute(
        address target,
        uint256 value,
        bytes calldata data
    ) internal virtual {
        (bool success, ) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Changes the minimum timelock duration for future operations.
     *
     * Emits a {MinDelayChange} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function updateDelay(uint256 newDelay) external virtual {
        require(msg.sender == address(this), "TimelockController: caller must be timelock");
        emit MinDelayChange(_minDelay, newDelay);
        _minDelay = newDelay;
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {TimelockController} from "../lib/openzeppelin-contracts/contracts/governance/TimelockController.sol";

/// @title TimeLock.
/// @author ClayStack.
/// @notice Implementation of TimelockController.
/// @dev By default, this contract is self administered, meaning administration tasks
/// have to go through the Timelock process. The proposer (resp executor) role
/// is in charge of proposing (resp executing) operations.

contract TimeLock is TimelockController {
    /// @notice Initializes the contract with a given `_minDelay` and sets `_proposers` & `_executors`.
    /// @param _minDelay : Minimum delay for execution of the scheduled operation.
    /// @param _proposers : List of addresses that can schedule operations.
    /// @param _executors : List of addresses that can cancel/execute scheduled operations.
    constructor(
        uint256 _minDelay,
        address[] memory _proposers,
        address[] memory _executors
    ) TimelockController(_minDelay, _proposers, _executors) {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import {UUPSUpgradeable, AddressUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {AccessControl} from "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {IRoleManager} from "./interfaces/IRoleManager.sol";

/// @title RoleManager.
/// @author ClayStack.
/// @notice Implementation of Access right management on the basis of roles.
/// @dev Contract module that allows to implement role-based access control mechanisms.
/// Roles are referred by their `bytes32` identifier.
/// Roles can be used to represent a set of permissions.
/// Roles can be granted and revoked dynamically by `admin` & `timelock` respectively.
contract RoleManager is Initializable, UUPSUpgradeable, AccessControl, IRoleManager {
    /// @notice ClayStack's default list of access-control roles.
    bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");
    bytes32 public constant TIMELOCK_UPGRADES_ROLE = keccak256("TIMELOCK_UPGRADES_ROLE");
    bytes32 public constant CS_SERVICE_ROLE = keccak256("CS_SERVICE_ROLE");

    /// @notice Initializes the contract's defined roles with initial role entities.
    /// @param _timeLock : ClayStack's timelock contract address.
    /// @param _csService : List of whitelisted ClayStack's service entities.
    /// @param _upgrades : Address of entity with upgrade role.
    function initialize(
        address _timeLock,
        address[] calldata _csService,
        address _upgrades
    ) external initializer onlyProxy {
        _setRoleAdmin(TIMELOCK_ROLE, TIMELOCK_ROLE);
        _setRoleAdmin(TIMELOCK_UPGRADES_ROLE, TIMELOCK_UPGRADES_ROLE);
        _setRoleAdmin(CS_SERVICE_ROLE, TIMELOCK_ROLE);

        // adding entities in role
        _setupRole(TIMELOCK_ROLE, _timeLock);

        // adding entities to upgrades
        _setupRole(TIMELOCK_UPGRADES_ROLE, _upgrades);

        for (uint256 i = 0; i < _csService.length; ++i) {
            _setupRole(CS_SERVICE_ROLE, _csService[i]);
        }
    }

    /// @notice Sets `_roleAdmin` as admin role for given role `_newRole`.
    /// @dev only `timelock` callable.
    /// Inorder to create new role in Access control list & add enitity in role,
    /// first setupRoleAdmin()` & then `grantRole()` to entity.
    /// @param _newRole : bytes32 hash of new role.
    /// @param _roleAdmin : bytes32 hash of `_newRole` admin.
    function setupRoleAdmin(bytes32 _newRole, bytes32 _roleAdmin) external virtual onlyRole(TIMELOCK_ROLE) {
        _setRoleAdmin(_newRole, _roleAdmin);
    }

    /// @notice Grants/add `_account` to given `_role`.
    /// @dev Only `_role` admin callable.
    /// `TIMELOCK_ROLE` can't be granted via `grantRole`.
    /// `TIMELOCK_UPGRADES_ROLE` can't be granted via `grantRole`.
    /// @param _role : bytes32 hash of role.
    /// @param _account : Address of entity.
    function grantRole(bytes32 _role, address _account) public virtual override onlyRole(getRoleAdmin(_role)) {
        require(_role != TIMELOCK_ROLE, "TimeLock Role Can't Be Granted");
        require(_role != TIMELOCK_UPGRADES_ROLE, "TimeLock Upgrade Role Can't Be Granted");
        super.grantRole(_role, _account);
    }

    /// @notice Upgrade the implementation of the proxy to `_newImplementation`.
    /// @dev only `TIMELOCK_UPGRADES_ROLE` callable.
    /// @param _newImplementation : Address of new implementation of the contract.
    function upgradeTo(address _newImplementation)
        external
        virtual
        override
        onlyRole(TIMELOCK_UPGRADES_ROLE)
        onlyProxy
    {
        _authorizeUpgrade(_newImplementation);
        _upgradeTo(_newImplementation);
    }

    /// @notice Returns a boolean value indicating whether `_account` has role `_role` or not.
    /// @param _role : bytes32 hash of role.
    /// @param _account : Address of entity to be checked.
    function checkRole(bytes32 _role, address _account) external view override returns (bool) {
        return super.hasRole(_role, _account);
    }

    /// @notice Returns bytes32 hash of `role_`.
    /// @param _role : `_role` name in bytes.
    function getRoleHash(bytes memory _role) external pure returns (bytes32) {
        return keccak256(_role);
    }

    /// @notice Function that should revert when `msg.sender` is not authorized to upgrade the contract or
    /// _newImplementation` is not contract.
    /// @param _newImplementation : Address of new implementation of the contract.
    function _authorizeUpgrade(address _newImplementation) internal virtual override onlyRole(TIMELOCK_UPGRADES_ROLE) {
        require(AddressUpgradeable.isContract(_newImplementation), "Implementation Not Contract");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {UUPSUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20Upgradeable, IERC20Upgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {OwnableUpgradeable as Ownable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

import {IUniswapV2Router} from "./IUniswapV2Router.sol";
import {IWETH9} from "../interfaces/IWETH9.sol";
import {IClayManager} from "../interfaces/IClayManager.sol";

/// @title ClaySwap.
/// @author ClayStack.
/// @dev Contracts allows user to swap supported tokens for csToken.
contract ClaySwap is UUPSUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, Ownable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Event for new swap & deposit of swapped token.
    /// @param user : Address of depositor.
    /// @param token : Address of Token.
    /// @param amount : Amount of Token.
    /// @param swappedAmount : Amount of swapped Tokens used for deposit in exchange.
    event LogSwapDeposit(address indexed user, address token, uint256 amount, uint256 swappedAmount);

    /// @notice Event for updating supported token list.
    /// @param token : Address of Token.
    /// @param flag : Boolean value denoting adding/removal of token.
    event LogTokenSupport(address indexed token, bool indexed flag);

    /// @notice Event for updating router.
    /// @param newRouter : Address of new router contract.
    event LogRouterUpdate(address indexed newRouter);

    /// @notice clayManager instance.
    IClayManager public clayManager;

    /// @notice swapRouter instance.
    IUniswapV2Router public swapRouter;

    /// @notice wrapped token instance.
    IWETH9 public wMatic;

    /// @notice Max unit value.
    uint256 constant MAX_INT = 2**256 - 1;

    /// @notice Mapping of all supported tokens for swap.
    mapping(address => bool) public supportedTokens;

    /// @notice Initializes the contract's state vars.
    /// @param _swapRouter : Address of supported dex router contract .
    /// @param _wMatic : Address of wrapped matic token.
    /// @param _clayManager: Address of clayManager contract.
    function initialize(
        address _swapRouter,
        address _wMatic,
        address _clayManager
    ) external initializer onlyProxy {
        require(_swapRouter != address(0), "Invalid router");
        require(_wMatic != address(0), "Invalid wMatic");
        require(_clayManager != address(0), "Invalid clayManager");

        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        swapRouter = IUniswapV2Router(_swapRouter);
        wMatic = IWETH9(_wMatic);
        clayManager = IClayManager(_clayManager);

        swapRouter = IUniswapV2Router(_swapRouter);
        wMatic = IWETH9(_wMatic);
        clayManager = IClayManager(_clayManager);

        // adding wMatic as default supported token
        supportedTokens[_wMatic] = true;
        wMatic.approve(address(clayManager), MAX_INT);
    }

    /// @notice Main function that facilitates deposit to the contract.
    /// @dev Emits an {LogSwapDeposit} event.
    /// @param _token Address of depositing token.
    /// @param _amount Amount to deposit.
    /// @param _minOutputAmount Minimum amount of output token required.
    /// @param _delegator Address of entity receiving csToken.
    /// @param _deadlineDelay Deadline for swap tx to complete.
    /// @return Bool confirmation of transaction.
    function tokenDeposit(
        address _token,
        uint256 _amount,
        uint256 _minOutputAmount,
        address _delegator,
        uint256 _deadlineDelay
    ) external whenNotPaused nonReentrant returns (bool) {
        uint256 depositAmount = 0;

        require(supportedTokens[_token], "Unsupported token");
        require(_amount != 0, "Zero amount");
        require(_minOutputAmount != 0, "Zero minOuput amount");
        require(_delegator != address(0x0), "Invalid delegator");
        require(_deadlineDelay > block.timestamp, "Invalid deadlineDelay");

        IERC20Upgradeable tokenInstance = IERC20Upgradeable(_token);

        // check user balance & approval
        require(tokenInstance.balanceOf(msg.sender) >= _amount, "Insufficient user balance");
        require(tokenInstance.allowance(msg.sender, address(this)) >= _amount, "Invalid allowance");

        if (tokenInstance.allowance(address(this), address(swapRouter)) < _amount) {
            tokenInstance.safeApprove(address(swapRouter), MAX_INT);
        }

        // get tokens in contract
        tokenInstance.safeTransferFrom(address(msg.sender), address(this), _amount);

        if (_token == address(wMatic)) {
            depositAmount = _amount;
        } else {
            // NOTE : Using only direct pairs
            address[] memory tradePath = new address[](2);
            tradePath[0] = address(_token);
            tradePath[1] = address(wMatic);

            // swap tokens for wMatic
            uint256[] memory resAmount = swapRouter.swapExactTokensForETH(
                _amount,
                _minOutputAmount,
                tradePath,
                address(this),
                _deadlineDelay
            );
            depositAmount = resAmount[resAmount.length - 1];
        }

        if (depositAmount != 0) {
            _clayManagerDeposit(depositAmount, _delegator);
        }
        emit LogSwapDeposit(_delegator, _token, _amount, depositAmount);

        return true;
    }

    /// @notice Helper function to perform deposit in clayManager on claySwap's behalf.
    function _clayManagerDeposit(uint256 _amount, address _delegator) internal {
        bool res = clayManager.depositDelegate(_amount, _delegator);
        require(res, "Manager deposit failed");
    }

    /// @notice Updates list of supported tokens for swap.
    /// @dev Emits an {LogSwapDeposit} event.
    /// @param _tokens List of Token addresses.
    /// @param _flag Bool value denoting add/remove of tokens.
    /// @return Bool confirmation of transaction.
    function updateTokenSupport(address[] calldata _tokens, bool _flag) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_tokens[i] != address(0x0), "Invalid token");
            supportedTokens[_tokens[i]] = _flag;
            if (!_flag) {
                IERC20Upgradeable(_tokens[i]).safeApprove(address(swapRouter), 0);
            }
            emit LogTokenSupport(_tokens[i], _flag);
        }
        return true;
    }

    /// @notice Updates dex swap router address.
    /// @dev Emits an {LogRouterUpdate} event.
    /// @param _newRouter Address of new router contract.
    /// @return Bool confirmation of transaction.
    function updateRouter(address _newRouter) external onlyOwner whenPaused returns (bool) {
        require(_newRouter != address(0x0), "Invalid router");
        swapRouter = IUniswapV2Router(_newRouter);
        emit LogRouterUpdate(_newRouter);
        return true;
    }

    /// @notice Fetch chained getAmountOut calculations on any number of pairs from router.
    function getReceivingAmount(uint256 _amountIn, address[] memory _path)
        external
        view
        returns (uint256[] memory rAmount)
    {
        rAmount = swapRouter.getAmountsOut(_amountIn, _path);
    }

    /// @notice Triggers stopped state.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Returns to normal state.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Upgrade the implementation of the proxy to `_newImplementation`.
    /// @param _newImplementation Address of new implementation of the contract
    function upgradeTo(address _newImplementation) external virtual override onlyOwner onlyProxy {
        _authorizeUpgrade(_newImplementation);
        _upgradeTo(_newImplementation);
    }

    /// @notice Function that should revert when `msg.sender` is not authorized to upgrade the contract or
    /// @param _newImplementation Address of new implementation of the contract.
    function _authorizeUpgrade(address _newImplementation) internal virtual override onlyOwner {
        require(_newImplementation.code.length > 0, "!contract");
    }

    /// @notice Function to receive Ether.
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/*
Implementation Reference
https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-02
*/

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {UUPSUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20Upgradeable, IERC20Upgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {OwnableUpgradeable as Ownable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {IClayTunnel} from "../interfaces/IClayTunnel.sol";
import {IClayManagerExtended} from "./IClayManagerExtended.sol";

/// @title ClayExchange
/// @author ClayStack
/// @dev Contracts allows to interact on non-validating chains with csTokens
contract ClayExchange is UUPSUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, Ownable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Event for explicit fund transfer.
    /// @param clayTreasury : Address of the ClayStack treasury.
    /// @param amount : Amount of token transferred.
    /// @param isNativeToken : Flag denoting type of token transferred.
    event LogFundTransfer(address indexed clayTreasury, uint256 amount, bool indexed isNativeToken);

    /// @notice ClayStack constants.
    uint256 internal constant MAX_DECIMALS = 1e18;
    uint256 private constant PERCENTAGE_BASE = 10000;

    /// @notice Instance of clayManager
    IClayManagerExtended private clayManager;

    /// @notice csToken instance.
    IERC20Upgradeable public csToken;

    /// @notice address of clayTunnel contract
    address public clayTunnel;

    /// @notice address of ClayStack treasury
    address public clayTreasury;

    /// @notice array of pending orders to claim from clayManager
    uint256[] public pendingOrders;

    /// @notice Max unit value.
    uint256 constant MAX_INT = 2**256 - 1;

    /// @notice Initializes the contract's state vars.
    /// @param _csToken Address of ClayStack's erc20 complaint token.
    /// @param _clayManager Address of ClayManager contract.
    /// @param _clayTreasury Address of ClayTreasury contract.
    /// @param _clayTunnel Address of ClayTunnel contract.
    function initialize(
        address _csToken,
        address _clayManager,
        address _clayTreasury,
        address _clayTunnel
    ) external initializer onlyProxy {
        require(_csToken != address(0), "Invalid csToken");
        require(_clayManager != address(0), "Invalid manager");
        require(_clayTreasury != address(0), "Invalid treasury");
        require(_clayTunnel != address(0), "Invalid tunnel");

        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        csToken = IERC20Upgradeable(_csToken);
        clayManager = IClayManagerExtended(_clayManager);
        clayTreasury = _clayTreasury;
        clayTunnel = _clayTunnel;

        // clayManager approval for IW
        require(csToken.approve(_clayManager, type(uint256).max), "Failed Approval csMATIC");
    }

    /** USER OPERATIONS **/

    /// @notice Deposits csToken from user and instantly returns Token to user,
    /// @dev Emits an {LogInstantWithdraw} event.
    /// @param _amountCs - Amount of csToken to be withdrawn.
    /// @return Bool confirmation of transaction.
    function instantWithdraw(uint256 _amountCs) external payable whenNotPaused nonReentrant returns (bool) {
        // todo add call to unstake any csMATIC balance and claim any ready pending
        uint256 amountTokenWithdraw = _exchangeCsToken(_amountCs);

        require(_amountCs != 0, "Zero amount");
        require(csToken.balanceOf(msg.sender) >= _amountCs, "Insufficient user balance");
        require(_amountCs <= getLiquidityCsToken(), "Insufficient csToken liquidity");
        require(amountTokenWithdraw != 0, "Invalid amount of matic to withdraw");

        // Transfer csToken
        csToken.safeTransferFrom(msg.sender, address(this), _amountCs);

        // Withdraw using ClayExchange
        uint256 amountTokenWithdrawExchange = _min(amountTokenWithdraw, address(this).balance);
        uint256 amountTokenWithdrawToUser = amountTokenWithdrawExchange;
        uint256 payableFee = 0;
        IClayManagerExtended.Fees memory fee = clayManager.fees();
        uint256 applicableFee = fee.instantWithdrawFee + fee.withdrawFee;
        if (applicableFee != 0 && amountTokenWithdrawExchange != 0) {
            payableFee = _getPercentValue(applicableFee, amountTokenWithdrawExchange);
            (bool status, ) = payable(clayTreasury).call{value: payableFee}("");
            require(status, "Fee transfer failed");
            amountTokenWithdrawToUser -= payableFee;
        }

        // Withdraw using ClayManager
        if (amountTokenWithdrawExchange < amountTokenWithdraw) {
            uint256 amountCsTokensManager = _amountCs - _exchangeToken(amountTokenWithdrawExchange);
            uint256 balanceBefore = address(this).balance;
            require(clayManager.instantWithdraw(amountCsTokensManager), "Manager instant withdraw failed");
            amountTokenWithdrawToUser += address(this).balance - balanceBefore;
        }

        // Transfer token to user
        (bool sent, ) = payable(msg.sender).call{value: amountTokenWithdrawToUser}("");
        require(sent, "User transfer failed");

        return true;
    }

    /** PUBLIC VIEWS **/

    /// @notice Returns the current exchange rate accounting for any slashing or donations.
    function getExchangeRate() external view returns (uint256, bool) {
        return (_exchangeCsToken(MAX_DECIMALS), false);
    }

    /// @notice Returns total liquidity of csToken available.
    function getLiquidityCsToken() public view returns (uint256) {
        // todo add MATIC amounts from pending claims that can be claimed already
        uint256 baseAmount = address(this).balance;
        uint256 totalCsLiquidity = clayManager.getLiquidityCsToken();
        if (baseAmount != 0) {
            totalCsLiquidity += _exchangeToken(baseAmount);
        }
        return totalCsLiquidity;
    }

    /** ClayStack STAKING **/

    /// @notice Returns amount of csTokens for given `amountToken`.
    /// @dev Returns `_amountToken` if ,
    /// `currentDeposits` is zero
    /// `totalCsToken` is zero
    /// `totalCsToken` is same as `currentDeposits`
    /// @param _amountToken : Amount of Token.
    function _exchangeToken(uint256 _amountToken) internal view returns (uint256) {
        (uint256 totalCsToken, uint256 currentDeposits) = IClayTunnel(clayTunnel).getFunds();
        if (totalCsToken != currentDeposits && currentDeposits != 0 && totalCsToken != 0) {
            return (_amountToken * totalCsToken) / currentDeposits;
        } else {
            return _amountToken;
        }
    }

    /// @notice Returns amount of Token for given `_amountCs`.
    /// @dev Returns `_amountCs` if ,
    /// `currentDeposits` is zero
    /// `totalCsToken` is zero
    /// `totalCsToken` is same as `currentDeposits`
    /// @param _amountCs : Amount of csToken.
    function _exchangeCsToken(uint256 _amountCs) internal view returns (uint256) {
        (uint256 totalCsToken, uint256 currentDeposits) = IClayTunnel(clayTunnel).getFunds();
        if (totalCsToken != currentDeposits && totalCsToken != 0 && currentDeposits != 0) {
            return (_amountCs * currentDeposits) / totalCsToken;
        } else {
            return _amountCs;
        }
    }

    /// @notice Returns current exchange rate i.e. csToken to 1 unit of Token
    function _getExchangeRate() internal view returns (uint256) {
        return _exchangeCsToken(MAX_DECIMALS);
    }

    /** ClayStack OPERATIONS **/

    /// @notice Sets clay treasury address.
    /// @param _clayTreasury New treasury address.
    function setClayTreasury(address _clayTreasury) external onlyOwner whenPaused {
        require(_clayTreasury != address(0), "Invalid treasury");
        clayTreasury = _clayTreasury;
    }

    /// @notice sends tokens in this contract to clayManager to be withdrawn as matic.
    function balanceFunds() external onlyOwner {
        uint256 csBalance = csToken.balanceOf(address(this));
        require(csBalance != 0, "Invalid withdraw amount");
        uint256 orderId = clayManager.withdraw(csBalance);
        pendingOrders.push(orderId);
    }

    /// @notice claims all pending orders for matic from clayManager.
    function claim() external onlyOwner {
        clayManager.claim(pendingOrders);
        delete pendingOrders;
    }

    /// @notice Transfer Native Token/csToken tokens to clayTreasury.
    /// @dev Emits an {LogTransfer} event.
    /// @param _amount Amount of Token to be transferred.
    /// @param _isNativeToken Token transferred is native network token or csToken.
    /// @return Bool confirmation of transaction.
    function transferTokens(uint256 _amount, bool _isNativeToken)
        external
        payable
        nonReentrant
        onlyOwner
        whenPaused
        returns (bool)
    {
        require(_amount != 0, "Zero amount");

        if (_isNativeToken) {
            require(address(this).balance >= _amount, "Insufficient funds");
            (bool sent, ) = payable(clayTreasury).call{value: _amount}("");
            require(sent, "Transfer to treasury failed");
        } else {
            require(csToken.balanceOf(address(this)) >= _amount, "Insufficient funds");
            csToken.safeTransfer(clayTreasury, _amount);
        }
        emit LogFundTransfer(clayTreasury, _amount, _isNativeToken);
        return true;
    }

    /** SUPPORT **/

    /// @notice Calculate & returns `_amount` value on given `_amount`
    /// uses `PERCENTAGE_BASE` for 2 decimal precision (i.e, 100.00).
    function _getPercentValue(uint256 _percent, uint256 _amount) internal pure returns (uint256) {
        return (_amount * _percent) / PERCENTAGE_BASE;
    }

    /// @notice returns the smaller number between a and b
    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a > _b ? _b : _a;
    }

    /// @notice Triggers stopped state.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Returns to normal state.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Upgrade the implementation of the proxy to `_newImplementation`.
    /// @param _newImplementation Address of new implementation of the contract
    function upgradeTo(address _newImplementation) external virtual override onlyOwner onlyProxy {
        _authorizeUpgrade(_newImplementation);
        _upgradeTo(_newImplementation);
    }

    /// @notice Function that should revert when `msg.sender` is not authorized to upgrade the contract or
    /// @param _newImplementation Address of new implementation of the contract.
    function _authorizeUpgrade(address _newImplementation) internal virtual override onlyOwner {
        require(_newImplementation.code.length > 0, "!contract");
    }

    /// @notice Receive function trigger when the call data is empty.
    receive() external payable {}

    /// @notice When not match is found for the selectors.
    fallback() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "../interfaces/IClayManager.sol";

interface IClayManagerExtended is IClayManager {
    /// @notice returns fee struct.
    function fees() external view returns (Fees memory);

    /// @notice returns csToken liquidity available in manager.
    function getLiquidityCsToken() external view returns (uint256);

    /// @notice Facilitates Instant Withdrawal.
    function instantWithdraw(uint256 _amountCsV2) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @title CsToken.
/// @author ClayStack.
/// @notice Implementation ClayStack's synthetic ERC20 compliant token.
contract CsToken is ERC20 {
    /// @notice address of clayMain contract.
    address public clayMain;

    /// @notice Checks if the msg.sender is the clayMain contract.
    modifier onlyClayMain() {
        require(msg.sender == clayMain, "Auth Failed");
        _;
    }

    /// @notice Initializes the values for `name`, `symbol` and `clayMain`.
    /// @dev The default value of `decimals` is 18.
    /// @param _name : Name of the token.
    /// @param _symbol : Symbol of the token.
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    /// @notice Mints `_amount` tokens to `_to`, increasing the total supply.
    /// @dev Only `clayMain` callable.
    /// @param _to : Address to which tokens will be minted.
    /// @param _amount : Number of tokens to be minted.
    /// @return Boolean value indicating whether the operation succeeded.
    function mint(address _to, uint256 _amount) external onlyClayMain returns (bool) {
        _mint(_to, _amount);
        return true;
    }

    /// @notice Burns `_amount` tokens from `_from`, reducing the total supply.
    /// @dev only `clayMain` callable.
    /// @param _from : Address from which tokens will be burned.
    /// @param _amount : Number of tokens to be burned.
    /// @return Boolean value indicating whether the operation succeeded.
    function burn(address _from, uint256 _amount) external onlyClayMain returns (bool) {
        _burn(_from, _amount);
        return true;
    }

    /// @notice Sets `_clayMain` address.
    /// @dev ClayMain can be set only once.
    /// @param _clayMain : Address of new ClayMain contract.
    function setClayMain(address _clayMain) external {
        require(_clayMain != address(0x0), "Invalid ClayMain");
        require(clayMain == address(0x0), "ClayMain Already Set");
        clayMain = _clayMain;
    }
}