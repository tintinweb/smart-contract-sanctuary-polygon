// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDexManager.sol";
import "./interfaces/core/IHoldingManager.sol";
import "./interfaces/core/IHolding.sol";
import "./interfaces/core/IManager.sol";
import "./interfaces/core/IStrategy.sol";
import "./interfaces/core/IStrategyManager.sol";
import "./interfaces/core/IStablesManager.sol";
import "./libraries/OperationsLib.sol";
import "./Holding.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//TODO: should we add a way for the factory's owner to save funds from the holding contract?

/// @title HoldingManager contract
/// @author Cosmin Grigore (@gcosmintech)
contract HoldingManager is IHoldingManager, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    /// @notice returns holding for user
    mapping(address => address) public override userHolding;

    /// @notice returns user for holding
    mapping(address => address) public override holdingUser;

    /// @notice returns true if holding was created
    mapping(address => bool) public override isHolding;

    /// @notice returns the manager address
    address public override manager;

    /// @notice mapping of minters of each holding (holding address => minter address)
    mapping(address => address) public override holdingMinter; // holding => minter

    /// @notice mapping of available holdings by position (position=>holding address)
    mapping(uint256 => address) public override availableHoldings;

    /// @notice position of the first available holding
    uint256 public override availableHoldingsHead;

    /// @notice position of the last available holding
    uint256 public override availableHoldingsTail;

    /// @notice creates a new HoldingManager contract
    /// @param _manager the global manager's address
    constructor(address _manager) {
        manager = _manager;
    }

    // -- User specific methods --
    /// @notice withdraws a token from a holding to a user
    /// @param _holding holding's address
    /// @param _token token user wants to withdraw
    /// @param _amount withdrawal amount
    function withdraw(
        address _holding,
        address _token,
        uint256 _amount
    )
        external
        override
        validHolding(_holding)
        onlyHoldingUser(_holding)
        validAddress(_token)
        validAmount(_amount)
    {
        IHolding(_holding).withdraw(_token, _amount);
    }

    /// @notice deposits a whitelisted token into the holding
    /// @param _holding holding's address
    /// @param _token token's address
    /// @param _amount amount to deposit
    function deposit(
        address _holding,
        address _token,
        uint256 _amount
    )
        external
        override
        validHolding(_holding)
        onlyHoldingUser(_holding)
        validToken(_token)
        validAmount(_amount)
    {
        IERC20(_token).safeTransferFrom(msg.sender, _holding, _amount);

        emit Deposit(_holding, msg.sender, _token, _amount);
    }

    /// @notice invests token into one of the whitelisted strategies
    /// @param _holding holding's address
    /// @param _token token's address
    /// @param _strategy strategy's address
    /// @param _amount token's amount
    /// @param _data extra data
    function invest(
        address _holding,
        address _token,
        address _strategy,
        uint256 _amount,
        bytes calldata _data
    )
        public
        override
        validHolding(_holding)
        onlyHoldingUser(_holding)
        validAmount(_amount)
        validToken(_token)
        returns (uint256)
    {
        address strategyManager = _getManager().strategyManager();

        IHolding(_holding).approve(_token, strategyManager, _amount);

        uint256 investmentResult = IStrategyManager(strategyManager).invest(
            _holding,
            _token,
            _strategy,
            _amount,
            _data
        );

        emit Invested(
            _holding,
            msg.sender,
            _token,
            _strategy,
            _amount,
            investmentResult
        );
        return investmentResult;
    }

    /// @notice claims a strategy investment
    /// @param _holding holding's address
    /// @param _strategy strategy to invest into
    /// @param _shares shares amount
    /// @param _asset token address to be received
    /// @param _data extra data
    function claimInvestment(
        address _holding,
        address _strategy,
        uint256 _shares,
        address _asset,
        bytes calldata _data
    )
        public
        override
        validHolding(_holding)
        onlyHoldingUser(_holding)
        validAmount(_shares)
        returns (uint256)
    {
        uint256 withdrawResult = IStrategyManager(
            _getManager().strategyManager()
        ).withdraw(_holding, _strategy, _shares, _asset, _data);

        emit StrategyClaim(
            _holding,
            msg.sender,
            _asset,
            _strategy,
            _shares,
            withdrawResult
        );
        return withdrawResult;
    }

    /// @notice exchanges an existing token with a whitelisted one
    /// @param _holding holding's address
    /// @param _ammId selected AMM id
    /// @param _tokenIn token available in the contract
    /// @param _tokenOut token resulting from the swap operation
    /// @param _amountIn exchange amount
    /// @param _minAmountOut min amount of tokenOut to receive when the swap is performed
    /// @param _data specific amm data
    /// @return the amount obtained
    function exchange(
        address _holding,
        uint256 _ammId,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minAmountOut,
        bytes calldata _data
    )
        external
        override
        validHolding(_holding)
        onlyHoldingUser(_holding)
        validAmount(_amountIn)
        validToken(_tokenOut)
        returns (uint256)
    {
        //TODO: check what we need to do with collateral in this case; do we move it?
        require(_minAmountOut > 0, "ERR: INVALID MIN_AMOUNT");
        IHolding(_holding).approve(_tokenIn, address(this), _amountIn);
        IERC20(_tokenIn).safeTransferFrom(_holding, address(this), _amountIn);
        OperationsLib.safeApprove(
            _tokenIn,
            _getManager().dexManager(),
            _amountIn
        );

        uint256 amountSwapped = _getDexManager().swap(
            _ammId,
            _tokenIn,
            _tokenOut,
            _amountIn,
            _minAmountOut,
            _data
        );
        IERC20(_tokenOut).safeTransfer(_holding, amountSwapped);
        return amountSwapped;
    }

    /// @notice claims investment from one strategy and invests it into another
    /// @param _holding holding's address
    /// @param _token token's address
    /// @param _strategyFrom strategy's address to claimInvestment from
    /// @param _strategyTo strategy's address to invest
    /// @param _shares shares amount
    /// @param _dataFrom extra data for claimInvestment
    /// @param _dataTo extra data for invest
    function moveInvestment(
        address _holding,
        address _token,
        address _strategyFrom,
        address _strategyTo,
        uint256 _shares,
        bytes calldata _dataFrom,
        bytes calldata _dataTo
    )
        external
        override
        validHolding(_holding)
        onlyHoldingUser(_holding)
        returns (uint256 investmentResult)
    {
        uint256 claimResult = claimInvestment(
            _holding,
            _strategyFrom,
            _shares,
            _token,
            _dataFrom
        );
        require(claimResult > 0, "ERR: CLAIM RESULT");
        investmentResult = invest(
            _holding,
            _token,
            _strategyTo,
            claimResult,
            _dataTo
        );
        require(investmentResult > 0, "ERR: INVESTMENT RESULT");
        emit InvestmentMoved(
            _holding,
            msg.sender,
            _token,
            _strategyFrom,
            _strategyTo,
            _shares,
            investmentResult
        );
    }

    /// @notice creates holding and leaves it available to be assigned
    function createHolding() external override nonReentrant returns (address) {
        require(
            numAvailableHoldings() < IManager(manager).maxAvailableHoldings(),
            "ERR: MAX AVAILABLE HOLDINGS REACHED"
        );
        address holdingAddress = _createHolding();
        availableHoldings[availableHoldingsTail] = holdingAddress;
        availableHoldingsTail += 1;
        if (msg.sender != owner()) {
            address protocolToken = IManager(manager).protocolToken();
            require(protocolToken != address(0), "ERR: NO PROTOCOL TOKEN");
            uint256 mintingTokenReward = IManager(manager).mintingTokenReward();
            IERC20(protocolToken).safeTransfer(msg.sender, mintingTokenReward);
        }
        return holdingAddress;
    }

    /// @notice creates holding at assigns it to the user
    function createHoldingForMyself()
        external
        override
        nonReentrant
        returns (address)
    {
        require(
            userHolding[msg.sender] == address(0),
            "ERR: USER ALREADY HAS HOLDING"
        );
        address holdingAddress = _createHolding();
        userHolding[msg.sender] = holdingAddress;
        holdingUser[holdingAddress] = msg.sender;
        emit HoldingAssigned(holdingAddress, msg.sender, msg.sender);
        return holdingAddress;
    }

    // -- Owner specific methods --
    /// @notice sets the manager address
    /// @param _manager contract's address
    function setManager(address _manager) external override onlyOwner {
        require(_manager != address(0), "ERR: INVALID ADDRESS");
        emit ManagerUpdated(manager, _manager);
        manager = _manager;
    }

    /// @notice assigns a new user to an existing holding
    /// @dev callable by owner only
    /// @param user user's address
    function assignHolding(address user)
        external
        override
        onlyOwner
        nonReentrant
        validAddress(user)
    {
        if (_isContract(user)) {
            require(
                IManager(manager).isContractWhitelisted(user),
                "ERR: NOT AUTHORIZED"
            );
        }
        address holding = availableHoldings[availableHoldingsHead];
        require(isHolding[holding], "ERR: NO HOLDING AVAILABLE");
        require(
            holdingUser[holding] == address(0),
            "ERR: HOLDING ALREADY ASSIGNED"
        );
        require(
            userHolding[user] == address(0),
            "ERR: USER ALREADY HAS HOLDING"
        );
        availableHoldingsHead += 1;

        userHolding[user] = holding;
        holdingUser[holding] = user;
        emit HoldingAssigned(holding, holdingMinter[holding], user);
    }

    function numAvailableHoldings() public view override returns (uint256) {
        return availableHoldingsTail - availableHoldingsHead;
    }

    function _createHolding() private returns (address) {
        require(manager != address(0), "ERR: INVALID MANAGER");
        if (msg.sender != tx.origin) {
            //EXTCODESIZE is hackable if called from a contract's constructor
            //it will return false since the contract isn't created yet
            require(
                IManager(manager).isContractWhitelisted(msg.sender),
                "ERR: NOT AUTHORIZED"
            );
        }
        Holding _holding = new Holding();
        isHolding[address(_holding)] = true;
        emit HoldingCreated(msg.sender, address(_holding));
        holdingMinter[address(_holding)] = msg.sender;
        return address(_holding);
    }

    function _getManager() private view returns (IManager) {
        return IManager(manager);
    }

    function _getDexManager() private view returns (IDexManager) {
        address dexManagerAddress = _getManager().dexManager();
        require(dexManagerAddress != address(0), "ERR: INVALID DEX");
        return IDexManager(dexManagerAddress);
    }

    function _isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    // -- modifiers --

    modifier validAddress(address _address) {
        require(_address != address(0), "ERR: INVALID ADDRESS");
        _;
    }

    modifier validHolding(address _holding) {
        require(isHolding[_holding], "ERR: INVALID HOLDING");
        _;
    }

    modifier onlyHoldingUser(address _holding) {
        require(holdingUser[_holding] == msg.sender, "ERR: NOT HOLDING USER");
        _;
    }

    modifier validAmount(uint256 _amount) {
        require(_amount > 0, "ERR: INVALID AMOUNT");
        _;
    }

    modifier validToken(address _token) {
        require(_getManager().isTokenWhitelisted(_token), "ERR: INVALID TOKEN");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for the DEX manager
/// @author Cosmin Grigore (@gcosmintech)
interface IDexManager {
    /// @notice Event emitted when a new AMM wrapper has been registered
    event AMMRegistered(
        address indexed owner,
        address indexed ammWrapper,
        uint256 id
    );
    /// @notice Event emitted when a registered AMM is paused
    event AMMPaused(address indexed owner);
    /// @notice Event emitted when a registered AMM is unpaused
    event AMMUnpaused(address indexed owner);
    /// @notice Event emitted when a swap has been performed
    event SwapPerformed(
        address sender,
        address indexed tokenA,
        address indexed tokenB,
        uint256 ammId,
        uint256 amountIn,
        uint256 amountOutObtained
    );
    event AddLiquidityPerformed(
        address indexed tokenA,
        address indexed tokenB,
        uint256 ammId,
        uint256 amountAIn,
        uint256 amountBIn,
        uint256 usedA,
        uint256 usedB,
        uint256 liquidityObtained
    );
    event RemovedLiquidityPerformed(
        address sender,
        uint256 lpAmount,
        uint256 obtainedA,
        uint256 obtainedB
    );

    /// @notice Amount data needed for an add liquidity operation
    struct AddLiquidityParams {
        uint256 _amountADesired;
        uint256 _amountBDesired;
        uint256 _amountAMin;
        uint256 _amountBMin;
    }
    /// @notice Amount data needed for a remove liquidity operation
    struct RemoveLiquidityData {
        uint256 _amountAMin;
        uint256 _amountBMin;
        uint256 _lpAmount;
    }

    /// @notice Internal data used only in the add liquidity method
    struct AddLiquidityTemporaryData {
        uint256 lpBalanceBefore;
        uint256 lpBalanceAfter;
        uint256 usedA;
        uint256 usedB;
        uint256 obtainedLP;
    }

    function AMMs(uint256 id) external view returns (address);

    function isAMMPaused(uint256 id) external view returns (bool);

    /// @notice View method to return the next id in line
    function getNextId() external view returns (uint256);

    /// @notice Returns the amount one would obtain from a swap
    /// @param _ammId AMM id
    /// @param _tokenIn Token in address
    /// @param _tokenOut Token to be ontained from swap address
    /// @param _amountIn Amount to be used for swap
    /// @return Token out amount
    function getAmountsOut(
        uint256 _ammId,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        bytes calldata data
    ) external view returns (uint256);

    /// @notice Removes liquidity and sends obtained tokens to sender
    /// @param _ammId AMM id
    /// @param _lp LP token address
    /// @param _tokenA Token A address
    /// @param _tokenB Token B address
    /// @param amountParams Amount info (Min amount for token A, Min amount for token B, LP amount to be burnt)
    /// @param _data AMM specific data
    function removeLiquidity(
        uint256 _ammId,
        address _lp,
        address _tokenA,
        address _tokenB,
        RemoveLiquidityData calldata amountParams,
        bytes calldata _data
    ) external returns (uint256, uint256);

    /// @notice Adds liquidity and sends obtained LP & leftovers to sender
    /// @param _ammId AMM id
    /// @param _lp LP token address
    /// @param _tokenA Token A address
    /// @param _tokenB Token B address
    /// @param amountParams Amount info (Desired amount for token A, Desired amount for token B, Min amount for token A, Min amount for token B)
    /// @param _data AMM specific data
    function addLiquidity(
        uint256 _ammId,
        address _lp,
        address _tokenA,
        address _tokenB,
        AddLiquidityParams calldata amountParams,
        bytes calldata _data
    )
        external
        returns (
            uint256, //amountADesired-usedA
            uint256, //amountBDesired-usedB
            uint256 //amountLP
        );

    /// @notice Performs a swap
    /// @param _ammId AMM id
    /// @param _tokenA Token A address
    /// @param _tokenB Token B address
    /// @param _amountIn Token A amount
    /// @param _amountOutMin Min amount for Token B
    /// @param _data AMM specific data
    function swap(
        uint256 _ammId,
        address _tokenA,
        address _tokenB,
        uint256 _amountIn,
        uint256 _amountOutMin,
        bytes calldata _data
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMinHoldingManager.sol";

interface IHoldingManager is IMinHoldingManager {
    /// @notice emitted when a new holding is crated
    event HoldingCreated(address indexed user, address indexed holdingAddress);

    /// @notice emitted when a new user is assigned for the holding contract
    event HoldingAssigned(
        address indexed holding,
        address indexed minter,
        address indexed user
    );

    event HoldingUninitialized(address indexed holding);

    /// @notice emitted when rewards are sent to the holding contract
    event ReceivedRewards(
        address indexed holding,
        address indexed strategy,
        address indexed token,
        uint256 amount
    );

    /// @notice emitted when rewards were exchanged to another token
    event RewardsExchanged(
        address indexed holding,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @notice emitted when rewards are withdrawn by the user
    event RewardsWithdrawn(
        address indexed holding,
        address indexed token,
        uint256 amount
    );

    /// @notice emitted when a deposit is created
    event Deposit(
        address indexed holding,
        address indexed user,
        address indexed token,
        uint256 amount
    );

    /// @notice emitted when an investment is created
    event Invested(
        address indexed holding,
        address indexed user,
        address indexed token,
        address strategy,
        uint256 amount,
        uint256 result
    );

    /// @notice emitted when an investment is withdrawn
    event StrategyClaim(
        address indexed holding,
        address indexed user,
        address indexed token,
        address strategy,
        uint256 shares,
        uint256 result
    );

    /// @notice emitted when an investment is withdrawn
    event InvestmentMoved(
        address indexed holding,
        address indexed user,
        address indexed token,
        address strategyFrom,
        address strategyTo,
        uint256 shares,
        uint256 result
    );

    /// @notice emitted when the Manager address is updated
    event ManagerUpdated(address indexed _old, address indexed _new);

    /// @notice returns holding for user
    function userHolding(address _user) external view returns (address);

    /// @notice returns true if holding was created
    function isHolding(address _holding) external view returns (bool);

    /// @notice address of the holding config contract
    function manager() external view returns (address);

    /// @notice mapping of minters of each holding (holding address => minter address)
    function holdingMinter(address) external view returns (address);

    /// @notice mapping of available holdings by position (position=>holding address)
    function availableHoldings(uint256) external view returns (address);

    /// @notice position of the first available holding
    function availableHoldingsHead() external view returns (uint256);

    /// @notice position of the last available holding
    function availableHoldingsTail() external view returns (uint256);

    /// @notice number of available holding contracts (tail - head)
    function numAvailableHoldings() external view returns (uint256);

    // -- User specific methods --

    /// @notice withdraws a token from the contract
    /// @param _holding holding's address
    /// @param _token token user wants to withdraw
    /// @param _amount withdrawal amount
    function withdraw(
        address _holding,
        address _token,
        uint256 _amount
    ) external;

    /// @notice deposits a whitelisted token into the holding
    /// @param _holding holding's address
    /// @param _token token's address
    /// @param _amount amount to deposit
    function deposit(
        address _holding,
        address _token,
        uint256 _amount
    ) external;

    /// @notice invests token into one of the whitelisted strategies
    /// @param _holding holding's address
    /// @param _token token's address
    /// @param _strategy strategy's address
    /// @param _amount token's amount
    /// @param _data extra data
    function invest(
        address _holding,
        address _token,
        address _strategy,
        uint256 _amount,
        bytes calldata _data
    ) external returns (uint256);

    /// @notice claims a strategy investment
    /// @param _holding holding's address
    /// @param _strategy strategy to invest into
    /// @param _shares shares amount
    /// @param _asset token address to be received
    /// @param _data extra data
    function claimInvestment(
        address _holding,
        address _strategy,
        uint256 _shares,
        address _asset,
        bytes calldata _data
    ) external returns (uint256);

    /// @notice exchanges an existing token with a whitelisted one
    /// @param _holding holding's address
    /// @param _ammId selected AMM id
    /// @param _tokenIn token available in the contract
    /// @param _tokenOut token resulting from the swap operation
    /// @param _amountIn exchange amount
    /// @param _minAmountOut min amount of tokenOut to receive when the swap is performed
    /// @param _data specific amm data
    /// @return the amount obtained
    function exchange(
        address _holding,
        uint256 _ammId,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minAmountOut,
        bytes calldata _data
    ) external returns (uint256);

    /// @notice claims investment from one strategy and invests it into another
    /// @param _holding holding's address
    /// @param _token token's address
    /// @param _strategyFrom strategy's address to claimInvestment from
    /// @param _strategyTo strategy's address to invest
    /// @param _shares shares amount
    /// @param _dataFrom extra data for claimInvestment
    /// @param _dataTo extra data for invest
    function moveInvestment(
        address _holding,
        address _token,
        address _strategyFrom,
        address _strategyTo,
        uint256 _shares,
        bytes calldata _dataFrom,
        bytes calldata _dataTo
    ) external returns (uint256);

    /// @notice creates holding and leaves it available to be assigned
    function createHolding() external returns (address);

    /// @notice creates holding at assigns it to the user
    function createHoldingForMyself() external returns (address);

    /// @notice assigns a new user to an existing holding
    /// @dev callable by owner only
    /// @param _user new user's address
    function assignHolding(address _user) external;

    /// @notice sets the manager address
    /// @param _manager contract's address
    function setManager(address _manager) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHolding {

    /// @notice returns the holding factory address
    function factory() external returns (address);

    /// @notice withraws a token to the user
    /// @param _tokenAddress token user wants to withdraw
    /// @param _amount withdrawal amount
    function withdraw(
        address _tokenAddress,
        uint256 _amount
    ) external;

    /// @notice approves an amount of a token to another address
    /// @param _tokenAddress token user wants to withdraw
    /// @param _destination destination address of the approval
    /// @param _amount withdrawal amount
    function approve(
        address _tokenAddress,
        address _destination,
        uint256 _amount
    ) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for a the manager contract
/// @author Cosmin Grigore (@gcosmintech)
interface IManager {
    /// @notice emitted when the dex manager is set
    event DexManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the strategy manager is set
    event StrategyManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the holding manager is set
    event HoldingManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the stablecoin manager is set
    event StablecoinManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the protocol token address is changed
    event ProtocolTokenUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the protocol token reward for minting is updated
    event MintingTokenRewardUpdated(
        uint256 indexed oldFee,
        uint256 indexed newFee
    );

    /// @notice emitted when the max amount of available holdings is updated
    event MaxAvailableHoldingsUpdated(
        uint256 indexed oldFee,
        uint256 indexed newFee
    );

    /// @notice emitted when the fee address is changed
    event FeeAddressUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );
    /// @notice emitted when the default fee is updated
    event PerformanceFeeUpdated(uint256 indexed oldFee, uint256 indexed newFee);

    /// @notice emitted when a new contract is whitelisted
    event ContractWhitelisted(address indexed contractAddress);

    /// @notice emitted when a contract is removed from the whitelist
    event ContractBlacklisted(address indexed contractAddress);

    /// @notice emitted when a new token is whitelisted
    event TokenWhitelisted(address indexed token);

    /// @notice emitted when a new token is removed from the whitelist
    event TokenRemoved(address indexed token);

    /// @notice returns true/false for contracts' whitelist status
    function isContractWhitelisted(address _contract)
        external
        view
        returns (bool);

    /// @notice returns true/false for token's whitelist status
    function isTokenWhitelisted(address _token) external view returns (bool);

    /// @notice returns holding manager address
    function holdingManager() external view returns (address);

    /// @notice returns stablecoin manager address
    function stablesManager() external view returns (address);

    /// @notice returns the available strategy manager
    function strategyManager() external view returns (address);

    /// @notice returns the available dex manager
    function dexManager() external view returns (address);

    /// @notice returns the protocol token address
    function protocolToken() external view returns (address);

    /// @notice returns the default performance fee
    function performanceFee() external view returns (uint256);

    /// @notice returns the amount of protocol tokens
    ///         rewarded for pre-minting a holding contract
    function mintingTokenReward() external view returns (uint256);

    /// @notice returns the max amount of available holdings
    function maxAvailableHoldings() external view returns (uint256);

    /// @notice returns the fee address
    function feeAddress() external view returns (address);

    /// @notice updates the fee address
    /// @param _fee the new address
    function setFeeAddress(address _fee) external;

    /// @notice updates the strategy manager address
    /// @param _strategy strategy manager's address
    function setStrategyManager(address _strategy) external;

    /// @notice updates the dex manager address
    /// @param _dex dex manager's address
    function setDexManager(address _dex) external;

    /// @notice sets the holding manager address
    /// @param _holding strategy's address
    function setHoldingManager(address _holding) external;

    /// @notice sets the protocol token address
    /// @param _protocolToken protocol token address
    function setProtocolToken(address _protocolToken) external;

    /// @notice sets the stablecoin manager address
    /// @param _stables strategy's address
    function setStablecoinManager(address _stables) external;

    /// @notice sets the performance fee
    /// @param _fee fee amount
    function setPerformanceFee(uint256 _fee) external;

    /// @notice sets the protocol token reward for pre-minting holdings
    /// @param _amount protocol token amount
    function setMintingTokenReward(uint256 _amount) external;

    /// @notice sets the max amount of available holdings
    /// @param _amount max amount of available holdings
    function setMaxAvailableHoldings(uint256 _amount) external;

    /// @notice whitelists a contract
    /// @param _contract contract's address
    function whitelistContract(address _contract) external;

    /// @notice removes a contract from the whitelisted list
    /// @param _contract contract's address
    function blacklistContract(address _contract) external;

    /// @notice whitelists a token
    /// @param _token token's address
    function whitelistToken(address _token) external;

    /// @notice removes a token from whitelist
    /// @param _token token's address
    function removeToken(address _token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for a strategy
/// @author Cosmin Grigore (@gcosmintech)
interface IStrategy {
    /// @notice emitted when funds are deposited
    event Deposit(
        address indexed asset,
        uint256 amount,
        address indexed recipient
    );

    /// @notice emitted when funds are withdrawn
    event Withdraw(
        address indexed asset,
        address indexed recipient,
        uint256 shares
    );

    /// @notice emitted when rewards are withdrawn
    event Rewards(address indexed recipient, uint256 rewards);

    /// @notice emitted when funds are saved in case of an emergency
    event SavedFunds(address indexed token, uint256 amount);
    /// @notice participants info
    struct RecipientInfo {
        uint256 investedAmount;
        uint256 totalShares;
    }

    //returns investments details
    function recipients(address _recipient)
        external
        view
        returns (uint256, uint256);

    //returns the address of the token accepted by the strategy as input
    function tokenIn() external view returns (address);

    //returns rewards amount
    function getRewards(address _recipient) external view returns (uint256);

    /// @notice deposits funds into the strategy
    /// @param _asset token to be invested
    /// @param _amount token's amount
    /// @param _recipient on behalf of
    /// @param _data extra data
    function deposit(
        address _asset,
        uint256 _amount,
        address _recipient,
        bytes calldata _data
    ) external returns (uint256);

    /// @notice withdraws funds and claims rewards
    /// @param _shares amount to withdraw
    /// @param _recipient on behalf of
    /// @param _asset token to be withdrawn
    /// @param _data extra data
    function withdraw(
        uint256 _shares,
        address _recipient,
        address _asset,
        bytes calldata _data
    ) external returns (uint256);

    /// @notice save funds
    /// @param _token token address
    /// @param _amount token amount
    function emergencySave(address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for the Strategy Manager contract
/// @author Cosmin Grigore (@gcosmintech)
interface IStrategyManager {
    /// @notice emitted when a new strategy is added to the whitelist
    event StrategyAdded(address indexed strategy);

    /// @notice emitted when an existing strategy is removed from the whitelist
    event StrategyRemoved(address indexed strategy);

    /// @notice emitted when an existing strategy info is updated
    event StrategyUpdated(
        address indexed strategy,
        bool indexed active,
        uint256 indexed fee
    );

    /// @notice emitted when the manager address is updated
    event ManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice information about strategies
    struct StrategyInfo {
        uint256 performanceFee;
        bool active;
    }

    /// @notice returns the manager address
    function manager() external view returns (address);

    /// @notice returns the fee factor used in computing the actual fee
    function feeFactor() external view returns (uint256);

    /// @notice returns whitelisted strategies
    function strategies(address _strategy) external view returns (bool);

    /// @notice returns whitelisted strategies
    function strategyInfo(address _strategy)
        external
        view
        returns (uint256, bool);

    /// @notice returns total investment per strategy
    function investments(address _strategy) external view returns (uint256);

    /// @notice sets the manager address
    /// @param _manager manager's address
    function setManager(address _manager) external;

    /// @notice adds a new strategy to the whitelist
    /// @param _strategy strategy's address
    function addStrategy(address _strategy) external;

    /// @notice removes a strategy from the whitelist
    /// @param _strategy strategy's address
    function removeStrategy(address _strategy) external;

    /// @notice updates an existing strategy info
    /// @param _strategy strategy's address
    /// @param _info info
    function updateStrategy(address _strategy, StrategyInfo calldata _info)
        external;

    // -- User specific methods --
    /// @notice invests in a strategy
    /// @param _holding holding that is investing
    /// @param _token token's address
    /// @param _strategy strategy's address
    /// @param _amount token's amount
    /// @param _data extra data
    function invest(
        address _holding,
        address _token,
        address _strategy,
        uint256 _amount,
        bytes calldata _data
    ) external returns (uint256);

    /// @notice withdraws from a strategy
    /// @param _holding holding that is withdrawing
    /// @param _strategy strategy's address
    /// @param _shares shares amount
    /// @param _asset token address to be received
    /// @param _data extra data
    function withdraw(
        address _holding,
        address _strategy,
        uint256 _shares,
        address _asset,
        bytes calldata _data
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for stables manager
/// @author Cosmin Grigore (@gcosmintech)
/// @dev based on MIM implementation
interface IStablesManager {
    /// @notice event emitted when collateral was registered
    event AddedCollateral(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    /// @notice event emitted when collateral was unregistered
    event RemovedCollateral(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    /// @notice event emitted when a borrow action was performed
    event Borrowed(address indexed user, uint256 amount, uint256 part);
    /// @notice event emitted when a repay action was performed
    event Repayed(address indexed user, uint256 amount, uint256 part);

    /// @notice Returns amount to share transformation
    /// @param _token token for which the exchange is done
    /// @param _amount token's amount
    /// @param _roundUp if the resulted shares are rounded up
    /// @return _share obtained shares
    function toShare(
        IERC20 _token,
        uint256 _amount,
        bool _roundUp
    ) external view returns (uint256 _share);

    /// @dev Returns share to amount transformation
    /// @param _token token for which the exchange is done
    /// @param _share amount of shares
    /// @param _roundUp if the resulted amount is rounded up
    /// @return _amount obtained amount
    function toAmount(
        IERC20 _token,
        uint256 _share,
        bool _roundUp
    ) external view returns (uint256 _amount);

    /// @notice Returns true if user is solvent for the specified token
    /// @param _token the token for which the check is done
    /// @param _user the user address
    /// @param _collateral the amount of collateral the user has
    /// @param _collateralizationRate the collateralization rate for the specified token
    /// @return true/false
    function isUserSolvent(
        address _token,
        address _user,
        uint256 _collateral,
        uint256 _collateralizationRate
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OperationsLib {
    uint256 internal constant FEE_FACTOR = 10000;

    function getFeeAbsolute(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return (amount * fee) / FEE_FACTOR;
    }

    function getRatio(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) internal pure returns (uint256) {
        if (numerator == 0 || denominator == 0) {
            return 0;
        }
        uint256 _numerator = numerator * 10**(precision + 1);
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "OperationsLib::safeApprove: approve failed"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./libraries/OperationsLib.sol";

import "./interfaces/core/IHolding.sol";
import "./interfaces/core/IMinHoldingManager.sol";

contract Holding is IHolding {
    using SafeERC20 for IERC20;

    /// @notice returns the holding factory address
    address public immutable override factory;

    /// @notice Constructor
    constructor() {
        factory = msg.sender;
    }

    /// @notice withraws a token to the user
    /// @param _tokenAddress token user wants to withdraw
    /// @param _amount withdrawal amount
    function withdraw(address _tokenAddress, uint256 _amount)
        external
        override
        onlyFactory
    {
        uint256 _balance = IERC20(_tokenAddress).balanceOf(address(this));
        require(_balance >= _amount, "ERR: INVALID AMOUNT");
        address userAddress = IMinHoldingManager(factory).holdingUser(
            address(this)
        );
        require(userAddress != address(0), "ERR: NO USER");
        IERC20(_tokenAddress).safeTransfer(userAddress, _amount);
    }

    /// @notice approves an amount of a token to another address
    /// @param _tokenAddress token user wants to withdraw
    /// @param _destination destination address of the approval
    /// @param _amount withdrawal amount
    function approve(
        address _tokenAddress,
        address _destination,
        uint256 _amount
    ) external override onlyFactory {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        require(balance >= _amount, "ERR: BALANCE");

        OperationsLib.safeApprove(_tokenAddress, _destination, _amount);
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "ERR: NOT FACTORY");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
pragma solidity ^0.8.0;

interface IMinHoldingManager {

    /// @notice returns user for holding
    function holdingUser(address _holding) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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