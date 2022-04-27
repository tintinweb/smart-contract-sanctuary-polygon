// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Holding.sol";

import "./libraries/OperationsLib.sol";

import "./interfaces/IDexManager.sol";
import "./interfaces/core/IHoldingManager.sol";
import "./interfaces/core/IHolding.sol";
import "./interfaces/core/IManager.sol";
import "./interfaces/core/IStrategy.sol";
import "./interfaces/core/IStrategyManager.sol";
import "./interfaces/core/IStablesManager.sol";
import "./interfaces/stablecoin/ISharesRegistry.sol";

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

    /// @notice returns the pause state of the contract
    bool public override paused;

    /// @notice contract that contains the address of the manager contract
    IManagerContainer public immutable override managerContainer;

    /// @notice mapping of minters of each holding (holding address => minter address)
    mapping(address => address) public override holdingMinter; // holding => minter

    /// @notice mapping of available holdings by position (position=>holding address)
    mapping(uint256 => address) public override availableHoldings;

    /// @notice position of the first available holding
    uint256 public override availableHoldingsHead;

    /// @notice position of the last available holding
    uint256 public override availableHoldingsTail;

    /// @notice creates a new HoldingManager contract
    /// @param _managerContainer contract that contains the address of the manager contract
    constructor(address _managerContainer) {
        require(_managerContainer != address(0), "3065");
        managerContainer = IManagerContainer(_managerContainer);
    }

    // -- Owner specific methods --
    /// @notice sets a new value for pause state
    /// @param _val the new value
    function setPaused(bool _val) external override onlyOwner {
        emit PauseUpdated(paused, _val);
        paused = _val;
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
        _assignHolding(user);
    }

    // -- View type methods --
    function numAvailableHoldings() public view override returns (uint256) {
        return availableHoldingsTail - availableHoldingsHead;
    }

    // -- User specific methods --
    /// @notice creates holding and leaves it available to be assigned
    function createHolding()
        external
        override
        nonReentrant
        notPaused
        returns (address)
    {
        require(
            numAvailableHoldings() < _getManager().maxAvailableHoldings(),
            "2000"
        );
        address holdingAddress = _createHolding();
        availableHoldings[availableHoldingsTail] = holdingAddress;
        availableHoldingsTail += 1;
        if (msg.sender != owner()) {
            address protocolToken = _getManager().protocolToken();
            require(protocolToken != address(0), "1100");
            uint256 mintingTokenReward = _getManager().mintingTokenReward();
            IERC20(protocolToken).safeTransfer(msg.sender, mintingTokenReward);
        }
        return holdingAddress;
    }

    /// @notice creates holding at assigns it to the user
    function createHoldingForMyself()
        external
        override
        nonReentrant
        notPaused
        returns (address)
    {
        require(userHolding[msg.sender] == address(0), "1101");
        address holdingAddress = _createHolding();
        userHolding[msg.sender] = holdingAddress;
        holdingUser[holdingAddress] = msg.sender;
        emit HoldingAssigned(holdingAddress, msg.sender, msg.sender);
        return holdingAddress;
    }

    /// @notice user grabs an existing holding, with a deposit
    function assignHoldingToMyself() external override nonReentrant notPaused {
        address holding = _assignHolding(msg.sender);

        // solhint-disable-next-line var-name-mixedcase
        address USDC = _getManager().USDC();
        uint256 firstDepositAmount = _getManager().firstDepositAmount();
        IERC20(USDC).safeTransferFrom(msg.sender, holding, firstDepositAmount);

        emit Deposit(holding, USDC, firstDepositAmount);
    }

    /// @notice deposits a whitelisted token into the holding
    /// @param _token token's address
    /// @param _amount amount to deposit
    function deposit(address _token, uint256 _amount)
        external
        override
        validToken(_token)
        validAmount(_amount)
        validHolding(userHolding[msg.sender])
        nonReentrant
        notPaused
    {
        IERC20(_token).safeTransferFrom(
            msg.sender,
            userHolding[msg.sender],
            _amount
        );

        _getStablesManager().addCollateral(
            userHolding[msg.sender],
            _token,
            _amount
        );

        emit Deposit(userHolding[msg.sender], _token, _amount);
    }

    /// @notice withdraws a token from a holding to a user
    /// @param _token token user wants to withdraw
    /// @param _amount withdrawal amount
    function withdraw(address _token, uint256 _amount)
        external
        override
        validAddress(_token)
        validAmount(_amount)
        validHolding(userHolding[msg.sender])
        nonReentrant
        notPaused
    {
        //perform the check to see if this is an airdropped token or user actually has collateral for it
        (, address _tokenRegistry) = _getStablesManager().shareRegistryInfo(
            _token
        );
        if (
            _tokenRegistry != address(0) &&
            ISharesRegistry(_tokenRegistry).collateral(
                userHolding[msg.sender]
            ) >
            0
        ) {
            _getStablesManager().removeCollateral(
                userHolding[msg.sender],
                _token,
                _amount
            );
        }

        IHolding(userHolding[msg.sender]).transfer(_token, msg.sender, _amount);
    }

    /// @notice exchanges an existing token with a whitelisted one
    /// @param _ammId selected AMM id
    /// @param _tokenIn token available in the contract
    /// @param _tokenOut token resulting from the swap operation
    /// @param _amountIn exchange amount
    /// @param _minAmountOut min amount of tokenOut to receive when the swap is performed
    /// @param _data specific amm data
    /// @return the amount obtained
    function exchange(
        uint256 _ammId,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minAmountOut,
        bytes calldata _data
    )
        external
        override
        validAmount(_amountIn)
        validToken(_tokenOut)
        validHolding(userHolding[msg.sender])
        nonReentrant
        notPaused
        returns (uint256)
    {
        require(_minAmountOut > 0, "2100");

        IHolding(userHolding[msg.sender]).approve(
            _tokenIn,
            address(this),
            _amountIn
        );
        IERC20(_tokenIn).safeTransferFrom(
            userHolding[msg.sender],
            address(this),
            _amountIn
        );

        OperationsLib.safeApprove(
            _tokenIn,
            _getManager().dexManager(),
            _amountIn
        );
        uint256 amountSwapped = IDexManager(_getManager().dexManager()).swap(
            _ammId,
            _tokenIn,
            _tokenOut,
            _amountIn,
            _minAmountOut,
            _data
        );
        _getStablesManager().migrateDataToRegistry(
            userHolding[msg.sender],
            _tokenIn,
            _tokenOut,
            _amountIn,
            amountSwapped
        );

        IERC20(_tokenOut).safeTransfer(userHolding[msg.sender], amountSwapped);

        return amountSwapped;
    }

    /// @notice mints stablecoin to the user or to the holding contract
    /// @param _token collateral token
    /// @param _amount the borrowed amount
    /// @param _mintDirectlyToUser if true mints to user instead of holding
    function borrow(
        address _token,
        uint256 _amount,
        bool _mintDirectlyToUser
    )
        external
        override
        nonReentrant
        notPaused
        validHolding(userHolding[msg.sender])
        returns (
            uint256 part,
            uint256 share,
            uint256 fee
        )
    {
        (part, share, fee) = _getStablesManager().borrow(
            userHolding[msg.sender],
            _token,
            _amount,
            _mintDirectlyToUser
        );

        emit Borrowed(
            userHolding[msg.sender],
            _token,
            _amount,
            fee,
            _mintDirectlyToUser
        );
    }

    /// @notice borrows from multiple assets
    /// @param _data struct containing data for each collateral type
    /// @param _mintDirectlyToUser if true mints to user instead of holding
    function borrowMultiple(
        BorrowOrRepayData[] calldata _data,
        bool _mintDirectlyToUser
    )
        external
        override
        validHolding(userHolding[msg.sender])
        nonReentrant
        notPaused
    {
        require(_data.length > 0, "3006");
        for (uint256 i = 0; i < _data.length; i++) {
            (, , uint256 fee) = _getStablesManager().borrow(
                userHolding[msg.sender],
                _data[i].token,
                _data[i].amount,
                _mintDirectlyToUser
            );
            emit Borrowed(
                userHolding[msg.sender],
                _data[i].token,
                _data[i].amount,
                fee,
                _mintDirectlyToUser
            );
        }

        emit BorrowedMultiple(
            userHolding[msg.sender],
            _data.length,
            _mintDirectlyToUser
        );
    }

    /// @notice repays multiple assets
    /// @param _data struct containing data for each collateral type
    /// @param _repayFromUser if true it will burn from user's wallet, otherwise from user's holding
    function repayMultiple(
        BorrowOrRepayData[] calldata _data,
        bool _repayFromUser
    )
        external
        override
        validHolding(userHolding[msg.sender])
        nonReentrant
        notPaused
    {
        require(_data.length > 0, "3006");

        for (uint256 i = 0; i < _data.length; i++) {
            uint256 amount = _getStablesManager().repay(
                userHolding[msg.sender],
                _data[i].token,
                _data[i].amount,
                _repayFromUser,
                false
            );
            emit Repayed(
                userHolding[msg.sender],
                _data[i].token,
                amount,
                _repayFromUser
            );
        }

        emit RepayedMultiple(
            userHolding[msg.sender],
            _data.length,
            _repayFromUser
        );
    }

    /// @notice registers a repay operation
    /// @param _token collateral token
    /// @param _amount the repayed amount
    /// @param _repayFromUser if true it will burn from user's wallet, otherwise from user's holding
    function repay(
        address _token,
        uint256 _amount,
        bool _repayFromUser
    )
        external
        override
        nonReentrant
        notPaused
        validHolding(userHolding[msg.sender])
        returns (uint256 amount)
    {
        amount = _getStablesManager().repay(
            userHolding[msg.sender],
            _token,
            _amount,
            _repayFromUser,
            false
        );
        emit Repayed(userHolding[msg.sender], _token, amount, _repayFromUser);
    }

    /// @notice method used to pay stablecoin debt by using own collateral
    /// @param _token token to be used as collateral
    /// @param _amount the amount of stablecoin to repay
    function selfLiquidate(
        address _token,
        uint256 _amount,
        SelfLiquidateData calldata _data
    )
        external
        override
        nonReentrant
        notPaused
        validHolding(userHolding[msg.sender])
        returns (uint256)
    {
        (, address shareRegistry) = _getStablesManager().shareRegistryInfo(
            _token
        );
        ISharesRegistry registry = ISharesRegistry(shareRegistry);

        uint256 _borrowed = registry.borrowed(userHolding[msg.sender]);
        require(_borrowed >= _amount, "2003");

        (bool updated, ) = registry.updateExchangeRate();
        require(updated, "3005");

        uint256 _collateralNeeded = _getStablesManager()
            .computeNeededCollateral(_token, _amount);
        require(_collateralNeeded > 0, "3004");

        _retrieveCollateral(
            _token,
            userHolding[msg.sender],
            _collateralNeeded,
            _data._strategies,
            _data._strategiesData
        );

        //send collateral to feeAddress
        IHolding(userHolding[msg.sender]).transfer(
            _token,
            _getManager().feeAddress(),
            _collateralNeeded
        );

        //remove debt
        _getStablesManager().repay(
            userHolding[msg.sender],
            _token,
            _amount,
            false,
            true
        );

        //remove collateral
        _getStablesManager().removeCollateral(
            userHolding[msg.sender],
            _token,
            _collateralNeeded
        );

        emit SelfLiquidated(
            userHolding[msg.sender],
            _token,
            _amount,
            _collateralNeeded
        );
        return _collateralNeeded;
    }

    /// @notice liquidate user
    /// @dev if user is solvent liquidation won't work
    /// @param _liquidatedHolding address of the holding which is being liquidated
    /// @param _token collateral token
    /// @param _data liquidation data
    /// @return result true if liquidation happened
    /// @return collateralAmount the amount of collateral to move
    /// @return protocolFeeAmount the protocol fee amount
    function liquidate(
        address _liquidatedHolding,
        address _token,
        LiquidateData calldata _data
    )
        external
        override
        validHolding(_liquidatedHolding)
        validHolding(userHolding[msg.sender])
        nonReentrant
        notPaused
        returns (
            bool result,
            uint256 collateralAmount,
            uint256 protocolFeeAmount
        )
    {
        (result, collateralAmount, protocolFeeAmount) = _getStablesManager()
            .liquidate(
                _liquidatedHolding,
                _token,
                userHolding[msg.sender],
                _data._burnFromUser
            );
        if (_data._maxLoss > 0) {
            uint256 liquidationMaxLossPrecision = IManager(
                managerContainer.manager()
            ).LIQUIDATION_MAX_LOSS_PRECISION();
            require(_data._maxLoss < liquidationMaxLossPrecision, "3027");
            collateralAmount =
                collateralAmount -
                (collateralAmount * _data._maxLoss) /
                liquidationMaxLossPrecision;
            protocolFeeAmount =
                protocolFeeAmount -
                (protocolFeeAmount * _data._maxLoss) /
                liquidationMaxLossPrecision;
        }
        if (result) {
            _retrieveCollateral(
                _token,
                _liquidatedHolding,
                collateralAmount + protocolFeeAmount,
                _data._strategies,
                _data._strategiesData
            );

            _moveCollateral(
                _liquidatedHolding,
                _token,
                userHolding[msg.sender],
                collateralAmount,
                true
            );

            _moveCollateral(
                _liquidatedHolding,
                _token,
                _getManager().feeAddress(),
                protocolFeeAmount,
                false
            );
        }
    }

    // -- Private methods --

    /// @notice creates a new holding contract
    function _createHolding() private returns (address) {
        require(managerContainer.manager() != address(0), "3003");
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender != tx.origin) {
            //EXTCODESIZE is hackable if called from a contract's constructor
            //it will return false since the contract isn't created yet
            require(_getManager().isContractWhitelisted(msg.sender), "1000");
        }
        Holding _holding = new Holding(address(managerContainer));
        isHolding[address(_holding)] = true;
        emit HoldingCreated(msg.sender, address(_holding));
        holdingMinter[address(_holding)] = msg.sender;
        return address(_holding);
    }

    /// @notice assigns an existing holding to user
    function _assignHolding(address user) private returns (address) {
        if (_isContract(user)) {
            require(_getManager().isContractWhitelisted(user), "1000");
        }
        address holding = availableHoldings[availableHoldingsHead];
        require(isHolding[holding], "1002");
        require(holdingUser[holding] == address(0), "1102");
        require(userHolding[user] == address(0), "1101");
        availableHoldingsHead += 1;

        userHolding[user] = holding;
        holdingUser[holding] = user;
        emit HoldingAssigned(holding, holdingMinter[holding], user);
        return holding;
    }

    /// @notice checks if address is a contract
    function _isContract(address addr) private view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(addr) // Note: returns 0 if called from constructor though
        }
        return size > 0;
    }

    /// @dev method used to force withdraw from strategies; if holding has enough balance, strategies are ignored
    function _retrieveCollateral(
        address _token,
        address _holding,
        uint256 _amount,
        address[] calldata _strategies, //strategies to withdraw from
        bytes[] calldata _data
    ) private {
        if (IERC20(_token).balanceOf(_holding) >= _amount) {
            return; //nothing to do; holding already has the necessary balance
        }
        require(_strategies.length > 0, "3025");
        require(_strategies.length == _data.length, "3026");

        for (uint256 i = 0; i < _strategies.length; i++) {
            (, uint256 _shares) = (
                IStrategy(_strategies[i]).recipients(_holding)
            );
            (uint256 withdrawResult, ) = _getStrategyManager().claimInvestment(
                _holding,
                _strategies[i],
                _shares,
                _token,
                _data[i]
            );

            require(withdrawResult > 0, string(abi.encodePacked("3015;", i)));
            emit CollateralRetrieved(_token, _holding, _strategies[i], _shares);
        }

        require(IERC20(_token).balanceOf(_holding) >= _amount, "2002");
    }

    /// @notice moves and fixes colletarl if requested
    function _moveCollateral(
        address _liquidatedHolding,
        address _token,
        address _holdingTo,
        uint256 _amount,
        bool _fixCollateralOnManager
    ) private {
        IHolding(_liquidatedHolding).transfer(_token, _holdingTo, _amount);
        emit CollateralMoved(_token, _liquidatedHolding, _holdingTo, _amount);

        //if accepted loss >0, the ShareRegistry total collateral for `_holdingTo` needs to be decreased by loss
        if (_fixCollateralOnManager) {
            (, address shareRegistry) = _getStablesManager().shareRegistryInfo(
                _token
            );
            ISharesRegistry reg = ISharesRegistry(shareRegistry);

            _getStablesManager().removeCollateral(
                _holdingTo,
                _token,
                reg.collateral(_holdingTo) - _amount
            );
        }
    }

    function _getManager() private view returns (IManager) {
        return IManager(managerContainer.manager());
    }

    function _getStablesManager() private view returns (IStablesManager) {
        return IStablesManager(_getManager().stablesManager());
    }

    function _getStrategyManager() private view returns (IStrategyManager) {
        return IStrategyManager(_getManager().strategyManager());
    }

    // -- modifiers --
    modifier validAddress(address _address) {
        require(_address != address(0), "3000");
        _;
    }

    modifier validHolding(address _holding) {
        require(isHolding[_holding], "3002");
        _;
    }

    modifier onlyHoldingUser(address _holding) {
        require(holdingUser[_holding] == msg.sender, "1001");
        _;
    }

    modifier validAmount(uint256 _amount) {
        require(_amount > 0, "2001");
        _;
    }

    modifier validToken(address _token) {
        require(_getManager().isTokenWhitelisted(_token), "3001");
        _;
    }

    modifier notPaused() {
        require(!paused, "1200");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./libraries/OperationsLib.sol";

import "./interfaces/core/IHolding.sol";
import "./interfaces/core/IManager.sol";
import "./interfaces/core/IStrategyManagerMin.sol";

contract Holding is IHolding {
    using SafeERC20 for IERC20;

    /// @notice returns the managerContainer address
    IManagerContainer public immutable override managerContainer;

    /// @notice Constructor
    /// @param _managerContainer contract that contains the address of the manager contract
    constructor(address _managerContainer) {
        require(_managerContainer != address(0), "3065");
        managerContainer = IManagerContainer(_managerContainer);
    }

    /// @notice approves an amount of a token to another address
    /// @param _tokenAddress token user wants to withdraw
    /// @param _destination destination address of the approval
    /// @param _amount withdrawal amount
    function approve(
        address _tokenAddress,
        address _destination,
        uint256 _amount
    ) external override onlyAllowed {
        OperationsLib.safeApprove(_tokenAddress, _destination, _amount);
    }

    /// @notice generic caller for contract
    /// @dev callable only by HoldingManager, StrategyManager or the strategies to avoid risky situations
    /// @dev used mostly for claim rewards part of the strategies as only the registered staker can harvest
    /// @param _contract the contract address for which the call will be invoked
    /// @param _call abi.encodeWithSignature data for the call
    function genericCall(address _contract, bytes calldata _call)
        external
        override
        onlyAllowed
        returns (bool success, bytes memory result)
    {
        //TODO: change with safeCall but compare the gas cost before & after; not really needed since the called contracts are limited and we know what to expect
        // solhint-disable-next-line avoid-low-level-calls
        (success, result) = _contract.call(_call);
    }

    /// @notice transfers token to another address
    /// @dev used when shares are claimed from strategies
    /// @param _token token address
    /// @param _to address to move token to
    /// @param _amount transferal amount
    function transfer(
        address _token,
        address _to,
        uint256 _amount
    ) external override onlyAllowed {
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        require(_balance >= _amount, "2001");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    modifier onlyAllowed() {
        IManager manager = IManager(managerContainer.manager());
        (, , bool isStrategyWhitelisted) = IStrategyManagerMin(
            manager.strategyManager()
        ).strategyInfo(msg.sender);
        require(
            msg.sender == manager.strategyManager() ||
                msg.sender == manager.holdingManager() ||
                isStrategyWhitelisted,
            "1000"
        );
        _;
    }
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

    function getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
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

    // solhint-disable-next-line func-name-mixedcase
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

import "./IManagerContainer.sol";

interface IHoldingManager {
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
        address indexed token,
        uint256 amount
    );

    /// @notice event emitted when a borrow action was performed
    event Borrowed(
        address indexed holding,
        address indexed token,
        uint256 amount,
        uint256 fee,
        bool mintToUser
    );
    /// @notice event emitted when a repay action was performed
    event Repayed(
        address indexed holding,
        address indexed token,
        uint256 amount,
        bool repayFromUser
    );

    /// @notice event emitted when collateral is retrieved from a strategy in case of liquidation
    event CollateralRetrieved(
        address indexed token,
        address indexed holding,
        address indexed strategy,
        uint256 collateral
    );
    /// @notice event emitted when collateral is moved from liquidated holding to liquidating holding
    event CollateralMoved(
        address indexed token,
        address indexed holdingFrom,
        address indexed holdingTo,
        uint256 amount
    );

    /// @notice event emitted when fee is moved from liquidated holding to fee addres
    event CollateralFeeTaken(
        address token,
        address holdingFrom,
        address to,
        uint256 amount
    );

    /// @notice event emitted when self liquidation happened
    event SelfLiquidated(
        address indexed holding,
        address indexed token,
        uint256 amount,
        uint256 collateralUsed
    );

    /// @notice event emitted when borrow event happened for multiple users
    event BorrowedMultiple(
        address indexed holding,
        uint256 length,
        bool mintedToUser
    );
    /// @notice event emitted when a multiple repay operation happened
    event RepayedMultiple(
        address indexed holding,
        uint256 length,
        bool repayedFromUser
    );
    /// @notice event emitted when pause state is changed
    event PauseUpdated(bool oldVal, bool newVal);

    /// @notice data used for multiple borrow
    struct BorrowOrRepayData {
        address token;
        uint256 amount;
    }
    /// @notice properties used for self liquidation
    /// @dev self liquidation is when a user swaps collateral with the stablecoin
    struct SelfLiquidateData {
        address[] _strategies;
        bytes[] _strategiesData;
    }

    /// @notice properties used for holding liquidation
    struct LiquidateData {
        address[] _strategies;
        bytes[] _strategiesData;
        uint256 _maxLoss;
        bool _burnFromUser;
    }

    /// @notice returns the pause state of the contract
    function paused() external view returns (bool);

    /// @notice sets a new value for pause state
    /// @param _val the new value
    function setPaused(bool _val) external;

    /// @notice returns user for holding
    function holdingUser(address holding) external view returns (address);

    /// @notice returns holding for user
    function userHolding(address _user) external view returns (address);

    /// @notice returns true if holding was created
    function isHolding(address _holding) external view returns (bool);

    /// @notice interface of the manager container contract
    function managerContainer() external view returns (IManagerContainer);

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

    /// @notice deposits a whitelisted token into the holding
    /// @param _token token's address
    /// @param _amount amount to deposit
    function deposit(address _token, uint256 _amount) external;

    /// @notice withdraws a token from the contract
    /// @param _token token user wants to withdraw
    /// @param _amount withdrawal amount
    function withdraw(address _token, uint256 _amount) external;

    /// @notice exchanges an existing token with a whitelisted one
    /// @param _ammId selected AMM id
    /// @param _tokenIn token available in the contract
    /// @param _tokenOut token resulting from the swap operation
    /// @param _amountIn exchange amount
    /// @param _minAmountOut min amount of tokenOut to receive when the swap is performed
    /// @param _data specific amm data
    /// @return the amount obtained
    function exchange(
        uint256 _ammId,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minAmountOut,
        bytes calldata _data
    ) external returns (uint256);

    /// @notice mints stablecoin to the user or to the holding contract
    /// @param _token collateral token
    /// @param _amount the borrowed amount
    function borrow(
        address _token,
        uint256 _amount,
        bool _mintDirectlyToUser
    )
        external
        returns (
            uint256 part,
            uint256 share,
            uint256 fee
        );

    /// @notice borrows from multiple assets
    /// @param _data struct containing data for each collateral type
    /// @param _mintDirectlyToUser if true mints to user instead of holding
    function borrowMultiple(
        BorrowOrRepayData[] calldata _data,
        bool _mintDirectlyToUser
    ) external;

    /// @notice registers a repay operation
    /// @param _token collateral token
    /// @param _amount the repayed amount
    /// @param _repayFromUser if true it will burn from user's wallet, otherwise from user's holding
    function repay(
        address _token,
        uint256 _amount,
        bool _repayFromUser
    ) external returns (uint256 amount);

    /// @notice repays multiple assets
    /// @param _data struct containing data for each collateral type
    /// @param _repayFromUser if true it will burn from user's wallet, otherwise from user's holding
    function repayMultiple(
        BorrowOrRepayData[] calldata _data,
        bool _repayFromUser
    ) external;

    /// @notice method used to pay stablecoin debt by using own collateral
    /// @param _token token to be used as collateral
    /// @param _amount the amount of stablecoin to repay
    function selfLiquidate(
        address _token,
        uint256 _amount,
        SelfLiquidateData calldata _data
    ) external returns (uint256);

    /// @notice liquidate user
    /// @dev if user is solvent liquidation won't work
    /// @param _liquidatedHolding address of the holding which is being liquidated
    /// @param _token collateral token
    /// @param _data liquidation data
    /// @return result true if liquidation happened
    /// @return collateralAmount the amount of collateral to move
    /// @return protocolFeeAmount the protocol fee amount
    function liquidate(
        address _liquidatedHolding,
        address _token,
        LiquidateData calldata _data
    )
        external
        returns (
            bool result,
            uint256 collateralAmount,
            uint256 protocolFeeAmount
        );

    /// @notice creates holding and leaves it available to be assigned
    function createHolding() external returns (address);

    /// @notice creates holding at assigns it to the user
    function createHoldingForMyself() external returns (address);

    /// @notice assigns a new user to an existing holding
    /// @dev callable by owner only
    /// @param _user new user's address
    function assignHolding(address _user) external;

    /// @notice user grabs an existing holding, with a deposit
    function assignHoldingToMyself() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IManagerContainer.sol";

interface IHolding {
    // @notice returns the manager address
    function managerContainer() external view returns (IManagerContainer);

    /// @notice approves an amount of a token to another address
    /// @param _tokenAddress token user wants to withdraw
    /// @param _destination destination address of the approval
    /// @param _amount withdrawal amount
    function approve(
        address _tokenAddress,
        address _destination,
        uint256 _amount
    ) external;

    /// @notice generic caller for contract
    /// @dev callable only by HoldingManager or StrategyManager to avoid risky situations
    /// @dev used mostly for claim rewards part of the strategies as only the registered staker can harvest
    /// @param _contract the contract address for which the call will be invoked
    /// @param _call abi.encodeWithSignature data for the call
    function genericCall(address _contract, bytes calldata _call)
        external
        returns (bool success, bytes memory result);

    /// @dev used when shares are claimed from strategies
    /// @param _token token address
    /// @param _to address to move token to
    /// @param _amount transferal amount
    function transfer(
        address _token,
        address _to,
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

    /// @notice emitted when the USDC address is changed
    event USDCAddressUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the first deposit amount
    event FirstDepositAmountUpdated(
        uint256 indexed oldAmount,
        uint256 indexed newAmount
    );

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

    /// @notice USDC address
    // solhint-disable-next-line func-name-mixedcase
    function USDC() external view returns (address);

    /// @notice Amount necessary to deposit for a user to grab a holding
    function firstDepositAmount() external view returns (uint256);

    /// @dev should be less than exchange rate precision due to optimization in math
    // solhint-disable-next-line func-name-mixedcase
    function COLLATERALIZATION_PRECISION() external view returns (uint256);

    /// @notice exchange rate precision
    // solhint-disable-next-line func-name-mixedcase
    function EXCHANGE_RATE_PRECISION() external view returns (uint256);

    /// @notice used in liquidation operation
    // solhint-disable-next-line func-name-mixedcase
    function LIQUIDATION_MULTIPLIER_PRECISION() external view returns (uint256);

    /// @notice precision used to calculate max accepted loss in case of liquidation
    // solhint-disable-next-line func-name-mixedcase
    function LIQUIDATION_MAX_LOSS_PRECISION() external view returns (uint256);

    /// @notice fee taken when a stablecoin borrow operation is done
    /// @dev can be 0
    // solhint-disable-next-line func-name-mixedcase
    function BORROW_FEE_PRECISION() external view returns (uint256);

    /// @notice share balance for token
    /// @dev to prevent the ratio going off
    // solhint-disable-next-line func-name-mixedcase
    function MINIMUM_SHARE_BALANCE() external view returns (uint256);

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

    /// @notice sets the amount necessary to deposit for a user to grab a holding
    /// @param _amount amount of USDC that will be deposited
    function setFirstDepositAmount(uint256 _amount) external;

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
    //TODO: add asset & token in as separate amounts
    /// @notice emitted when funds are deposited
    event Deposit(
        address indexed asset,
        address indexed tokenIn,
        uint256 assetAmount,
        uint256 tokenInAmount,
        uint256 shares,
        address indexed recipient
    );

    //TODO: add asset & token in as separate amounts
    /// @notice emitted when funds are withdrawn
    event Withdraw(
        address indexed asset,
        address indexed recipient,
        uint256 shares,
        uint256 amount
    );

    /// @notice emitted when rewards are withdrawn
    event Rewards(
        address indexed recipient,
        uint256[] rewards,
        address[] rewardTokens
    );

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

    //returns the address of strategy's receipt token
    function tokenOut() external view returns (address);

    //returns the address of strategy's receipt token
    function rewardToken() external view returns (address);

    /// @notice returns true if tokenOut exists in holding
    function holdingHasTokenOutBalance() external view returns (bool);

    //returns rewards amount
    function getRewards(address _recipient) external view returns (uint256);

    /// @notice deposits funds into the strategy
    /// @dev some strategies won't give back any receipt tokens; in this case 'tokenOutAmount' will be 0
    /// @dev 'tokenInAmount' will be equal to '_amount' in case the '_asset' is the same as strategy 'tokenIn()'
    /// @param _asset token to be invested
    /// @param _amount token's amount
    /// @param _recipient on behalf of
    /// @param _data extra data
    /// @return tokenOutAmount receipt tokens amount/obtained shares
    /// @return tokenInAmount returned token in amount
    function deposit(
        address _asset,
        uint256 _amount,
        address _recipient,
        bytes calldata _data
    ) external returns (uint256 tokenOutAmount, uint256 tokenInAmount);

    /// @notice withdraws deposited funds
    /// @dev some strategies will allow only the tokenIn to be withdrawn
    /// @dev 'assetAmount' will be equal to 'tokenInAmount' in case the '_asset' is the same as strategy 'tokenIn()'
    /// @param _asset token to be invested
    /// @param _shares amount to withdraw
    /// @param _recipient on behalf of
    /// @param _asset token to be withdrawn
    /// @param _data extra data
    /// @return assetAmount returned asset amoumt obtained from the operation
    /// @return tokenInAmount returned token in amount
    function withdraw(
        uint256 _shares,
        address _recipient,
        address _asset,
        bytes calldata _data
    ) external returns (uint256 assetAmount, uint256 tokenInAmount);

    /// @notice claims rewards from the strategy
    /// @param _recipient on behalf of
    /// @param _data extra data
    /// @return amounts reward tokens amounts
    /// @return tokens reward tokens addresses
    function claimRewards(address _recipient, bytes calldata _data)
        external
        returns (uint256[] memory amounts, address[] memory tokens);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IManagerContainer.sol";
import "./IStrategyManagerMin.sol";

/// @title Interface for the Strategy Manager contract
/// @author Cosmin Grigore (@gcosmintech)
interface IStrategyManager is IStrategyManagerMin {
    /// @notice emitted when a new strategy is added to the whitelist
    event StrategyAdded(address indexed strategy);

    /// @notice emitted when an existing strategy is removed from the whitelist
    event StrategyRemoved(address indexed strategy);

    /// @notice emitted when an existing strategy info is updated
    event StrategyUpdated(address indexed strategy, bool active, uint256 fee);

    /// @notice emitted when an investment is created
    event Invested(
        address indexed holding,
        address indexed user,
        address indexed token,
        address strategy,
        uint256 amount,
        uint256 tokenOutResult,
        uint256 tokenInResult
    );

    /// @notice emitted when an investment is withdrawn
    event InvestmentMoved(
        address indexed holding,
        address indexed user,
        address indexed token,
        address strategyFrom,
        address strategyTo,
        uint256 shares,
        uint256 tokenOutResult,
        uint256 tokenInResult
    );

    /// @notice event emitted when collateral is adjusted from a claim investment or claim rewards operation
    event CollateralAdjusted(
        address indexed holding,
        address indexed token,
        uint256 value,
        bool add
    );

    /// @notice emitted when an investment is withdrawn
    event StrategyClaim(
        address indexed holding,
        address indexed user,
        address indexed token,
        address strategy,
        uint256 shares,
        uint256 tokenAmount,
        uint256 tokenInAmount
    );

    /// @notice event emitted when performance fee is taken
    event FeeTaken(
        address indexed token,
        address indexed feeAddress,
        uint256 amount
    );

    /// @notice event emitted when rewards are claimed
    event RewardsClaimed(
        address indexed token,
        address indexed holding,
        uint256 amount
    );

    /// @notice event emitted when pause state is changed
    event PauseUpdated(bool oldVal, bool newVal);

    /// @notice event emitted when invoker is updated
    event InvokerUpdated(address indexed component, bool allowed);

    /// @notice information about strategies
    struct StrategyInfo {
        uint256 performanceFee;
        bool active;
        bool whitelisted;
    }

    /// @notice data used for a move investment operation
    /// @param _strategyTo strategy's address to invest
    /// @param _shares shares amount
    /// @param _dataFrom extra data for claimInvestment
    /// @param _dataTo extra data for invest
    struct MoveInvestmentData {
        address strategyFrom;
        address strategyTo;
        uint256 shares;
        bytes dataFrom;
        bytes dataTo;
    }

    /// @notice interface of the manager container contract
    function managerContainer() external view returns (IManagerContainer);

    /// @notice returns the pause state of the contract
    function paused() external view returns (bool);

    /// @notice sets a new value for pause state
    /// @param _val the new value
    function setPaused(bool _val) external;

    /// @notice returns whitelisted strategies
    function strategyInfo(address _strategy)
        external
        view
        override
        returns (
            uint256,
            bool,
            bool
        );

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

    /// @notice sets invoker as allowed or forbidden
    /// @param _component invoker's address
    /// @param _allowed true/false
    function updateInvoker(address _component, bool _allowed) external;

    // -- User specific methods --
    /// @notice invests in a strategy
    /// @dev some strategies won't give back any receipt tokens; in this case 'tokenOutAmount' will be 0
    /// @dev 'tokenInAmount' will be equal to '_amount' in case the '_asset' is the same as strategy 'tokenIn()'
    /// @param _token token's address
    /// @param _strategy strategy's address
    /// @param _amount token's amount
    /// @param _data extra data
    /// @return tokenOutAmount returned receipt tokens amount
    /// @return tokenInAmount returned token in amount
    function invest(
        address _token,
        address _strategy,
        uint256 _amount,
        bytes calldata _data
    ) external returns (uint256 tokenOutAmount, uint256 tokenInAmount);

    /// @notice claims investment from one strategy and invests it into another
    /// @dev callable by holding's user
    /// @dev some strategies won't give back any receipt tokens; in this case 'tokenOutAmount' will be 0
    /// @dev 'tokenInAmount' will be equal to '_amount' in case the '_asset' is the same as strategy 'tokenIn()'
    /// @param _token token's address
    /// @param _data MoveInvestmentData object
    /// @return tokenOutAmount returned receipt tokens amount
    /// @return tokenInAmount returned token in amount
    function moveInvestment(address _token, MoveInvestmentData calldata _data)
        external
        returns (uint256 tokenOutAmount, uint256 tokenInAmount);

    /// @notice claims a strategy investment
    /// @dev withdraws investment from a strategy
    /// @dev some strategies will allow only the tokenIn to be withdrawn
    /// @dev 'assetAmount' will be equal to 'tokenInAmount' in case the '_asset' is the same as strategy 'tokenIn()'
    /// @param _holding holding's address
    /// @param _strategy strategy to invest into
    /// @param _shares shares amount
    /// @param _asset token address to be received
    /// @param _data extra data
    /// @return assetAmount returned asset amoumt obtained from the operation
    /// @return tokenInAmount returned token in amount
    function claimInvestment(
        address _holding,
        address _strategy,
        uint256 _shares,
        address _asset,
        bytes calldata _data
    ) external returns (uint256 assetAmount, uint256 tokenInAmount);

    /// @notice claim rewards from strategy
    /// @param _strategy strategy's address
    /// @param _data extra data
    /// @return amounts reward amounts
    /// @return tokens reward tokens
    function claimRewards(address _strategy, bytes calldata _data)
        external
        returns (uint256[] memory amounts, address[] memory tokens);

    /// @notice invokes a generic call on holding
    /// @param _holding the address of holding the call is invoked for
    /// @param _contract the external contract called by holding
    /// @param _call the call data
    /// @return success true/false
    /// @return result data obtained from the external call
    function invokeHolding(
        address _holding,
        address _contract,
        bytes calldata _call
    ) external returns (bool success, bytes memory result);

    /// @notice invokes an approve operation for holding
    /// @param _holding the address of holding the call is invoked for
    /// @param _token the asset for which the approval is performed
    /// @param _on the contract's address
    /// @param _amount the approval amount
    function invokeApprove(
        address _holding,
        address _token,
        address _on,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/RebaseLib.sol";

import "./IManagerContainer.sol";
import "../stablecoin/IPandoraUSD.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for stables manager
/// @author Cosmin Grigore (@gcosmintech)
interface IStablesManager {
    /// @notice event emitted when collateral was registered
    event AddedCollateral(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    /// @notice event emitted when collateral was registered by the owner
    event ForceAddedCollateral(
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

    /// @notice event emitted when collateral was unregistered by the owner
    event ForceRemovedCollateral(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    /// @notice event emitted when a borrow action was performed
    event Borrowed(
        address indexed user,
        uint256 amount,
        uint256 part,
        bool mintToUser
    );
    /// @notice event emitted when a repay action was performed
    event Repayed(
        address indexed user,
        uint256 amount,
        uint256 part,
        bool repayFromUser,
        bool selfLiquidation
    );

    /// @notice event emitted when a registry is added
    event RegistryAdded(address indexed token, address indexed registry);

    /// @notice event emitted when a registry is updated
    event RegistryUpdated(address indexed token, address indexed registry);

    /// @notice event emmitted when a liquidation operation happened
    event Liquidated(
        address indexed liquidatedUser,
        address indexed liquidatingUser,
        address indexed token,
        uint256 obtainedCollateral,
        uint256 protocolCollateral,
        uint256 liquidatedAmount
    );

    /// @notice event emitted when data is migrated to another collateral token
    event CollateralMigrated(
        address indexed holding,
        address indexed tokenFrom,
        address indexed tokenTo,
        uint256 borrowedAmount,
        uint256 borrowedShares,
        uint256 collateralTo
    );

    /// @notice emitted when an existing strategy info is updated
    event RegistryConfigUpdated(address indexed registry, bool active);

    struct ShareRegistryInfo {
        bool active;
        address deployedAt;
    }

    /// @notice event emitted when pause state is changed
    event PauseUpdated(bool oldVal, bool newVal);

    /// @notice emitted when the PandoraUSD address is updated
    event StableAddressUpdated(address indexed _old, address indexed _new);

    /// @notice returns the pause state of the contract
    function paused() external view returns (bool);

    /// @notice sets a new value for pause state
    /// @param _val the new value
    function setPaused(bool _val) external;

    /// @notice returns collateral amount
    /// @param _token collateral token
    /// @param _amount stablecoin amount
    function computeNeededCollateral(address _token, uint256 _amount)
        external
        view
        returns (uint256 result);

    /// @notice sets the PandoraUSD address
    /// @param _newAddr contract's address
    function setPandoraUSD(address _newAddr) external;

    /// @notice share -> info
    function shareRegistryInfo(address _registry)
        external
        view
        returns (bool, address);

    /// @notice total borrow per token
    function totalBorrowed(address _token)
        external
        view
        returns (uint128 elastic, uint128 base);

    /// @notice returns totals, base and elastic
    function totals(IERC20 token) external view returns (uint128, uint128);

    /// @notice interface of the manager container contract
    function managerContainer() external view returns (IManagerContainer);

    /// @notice Pandora project stablecoin address
    function pandoraUSD() external view returns (IPandoraUSD);

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
    /// @param _holding the user address
    /// @return true/false
    function isSolvent(address _token, address _holding)
        external
        view
        returns (bool);

    /// @notice get liquidation info for holding and token
    /// @dev returns borrowed amount, collateral amount, collateral's value ratio, current borrow ratio, solvency status; colRatio needs to be >= borrowRaio
    /// @param _holding address of the holding to check for
    /// @param _token address of the token to check for
    function getLiquidationInfo(address _holding, address _token)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        );

    /// @notice migrates collateral and share to a new registry
    /// @param _holding the holding for which collateral is added
    /// @param _tokenFrom collateral token source
    /// @param _tokenTo collateral token destination
    /// @param _collateralFrom collateral amount to be removed from source
    /// @param _collateralTo collateral amount to be added to destination
    function migrateDataToRegistry(
        address _holding,
        address _tokenFrom,
        address _tokenTo,
        uint256 _collateralFrom,
        uint256 _collateralTo
    ) external;

    /// @notice accrues collateral for holding
    /// @dev callable by the owner
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount amount of collateral
    function forceAddCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external;

    /// @notice registers new collateral
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount amount of collateral
    function addCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external;

    /// @notice removes collateral for holding
    /// @dev callable by the owner
    /// @param _holding the holding for which collateral is removed
    /// @param _token collateral token
    /// @param _amount amount of collateral
    function forceRemoveCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external;

    /// @notice unregisters collateral
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount amount of collateral
    function removeCollateral(
        address _holding,
        address _token,
        uint256 _amount
    ) external;

    /// @notice mints stablecoin to the user
    /// @param _holding the holding for which collateral is added
    /// @param _token collateral token
    /// @param _amount the borrowed amount
    function borrow(
        address _holding,
        address _token,
        uint256 _amount,
        bool _mintDirectlyToUser
    )
        external
        returns (
            uint256 part,
            uint256 share,
            uint256 feeAmount
        );

    /// @notice registers a repay operation
    /// @param _holding the holding for which repay is performed
    /// @param _token collateral token
    /// @param _part the repayed amount
    /// @param _repayFromUser if true it will burn from user's wallet, otherwise from user's holding
    /// @param _selfLiquidation if true, nothing is burned
    function repay(
        address _holding,
        address _token,
        uint256 _part,
        bool _repayFromUser,
        bool _selfLiquidation
    ) external returns (uint256 amount);

    /// @notice registers a liquidation event
    /// @dev if user is solvent, there's no need for liqudation;
    /// @param _liquidatedHolding address of the holding which is being liquidated
    /// @param _token collateral token
    /// @param _holdingTo address of the holding which initiated the liquidation
    /// @param _burnFromUser if true, burns stablecoin from the liquidating user, not from the holding
    /// @return result true if liquidation happened
    /// @return collateralAmount the amount of collateral to move
    /// @return protocolFeeAmount the protocol fee amount
    function liquidate(
        address _liquidatedHolding,
        address _token,
        address _holdingTo,
        bool _burnFromUser
    )
        external
        returns (
            bool,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../oracle/IOracle.sol";
import "../core/IManagerContainer.sol";

/// @title Interface for SharesRegistry contract
/// @author Cosmin Grigore (@gcosmintech)
/// @dev based on MIM CauldraonV2 contract
interface ISharesRegistry {
    /// @notice event emitted when contract new ownership is accepted
    event OwnershipAccepted(address indexed newOwner);
    /// @notice event emitted when contract ownership transferal was initated
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );
    /// @notice event emitted when collateral was registered
    event CollateralAdded(address indexed user, uint256 share);
    /// @notice event emitted when collateral was unregistered
    event CollateralRemoved(address indexed user, uint256 share);
    /// @notice event emitted when exchange rate was updated
    event ExchangeRateUpdated(uint256 rate);
    /// @notice event emitted when the borrowing opening fee is updated
    event BorrowingOpeningFeeUpdated(uint256 oldVal, uint256 newVal);
    /// @notice event emitted when the liquidation mutiplier is updated
    event LiquidationMultiplierUpdated(uint256 oldVal, uint256 newVal);
    /// @notice event emitted when the collateralization rate is updated
    event CollateralizationRateUpdated(uint256 oldVal, uint256 newVal);
    /// @notice event emitted when fees are accrued
    event FeesAccrued(uint256 amount);
    /// @notice event emitted when accrue was called
    event Accrued(uint256 updatedTotalBorrow, uint256 extraAmount);
    /// @notice oracle data updated
    event OracleDataUpdated();
    /// @notice event emitted when borrowed amount is set
    event BorrowedSet(address _holding, uint256 oldVal, uint256 newVal);
    /// @notice event emitted when borrowed shares amount is set
    event BorrowedSharesSet(address _holding, uint256 oldVal, uint256 newVal);

    /// @notice accure info data
    struct AccrueInfo {
        uint64 lastAccrued;
        uint128 feesEarned;
        // solhint-disable-next-line var-name-mixedcase
        uint64 INTEREST_PER_SECOND;
    }

    /// @notice exchange and interest rate tracking
    /// this is 'cached' here because calls to oracles can be very expensive
    function exchangeRate() external view returns (uint256);

    /// @notice borrowed amount for holding; holding > amount
    function borrowed(address _holding) external view returns (uint256);

    /// @notice borrowed shares for holding; holding > amount
    function borrowedShares(address _holding) external view returns (uint256);

    /// @notice info about the accrued data
    function accrueInfo()
        external
        view
        returns (
            uint64,
            uint128,
            uint64
        );

    /// @notice current owner
    function owner() external view returns (address);

    /// @notice possible new owner
    /// @dev if different than `owner` an ownership transfer is in  progress and has to be accepted by the new owner
    function temporaryOwner() external view returns (address);

    /// @notice interface of the manager container contract
    function managerContainer() external view returns (IManagerContainer);

    /// @notice returns the token address for which this registry was created
    function token() external view returns (address);

    /// @notice oracle contract associated with this share registry
    function oracle() external view returns (IOracle);

    /// @notice borrowing fee amount
    // solhint-disable-next-line func-name-mixedcase
    function borrowOpeningFee() external view returns (uint256);

    /// @notice collateralization rate for token
    // solhint-disable-next-line func-name-mixedcase
    function collateralizationRate() external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function liquidationMultiplier() external view returns (uint256);

    /// @notice returns the collateral shares for user
    /// @param _user the address for which the query is performed
    function collateral(address _user) external view returns (uint256);

    /// @notice sets a new value for borrowed
    /// @param _holding the address of the user
    /// @param _newVal the new amount
    function setBorrowed(address _holding, uint256 _newVal) external;

    /// @notice sets a new value for borrowedShares
    /// @param _holding the address of the user
    /// @param _newVal the new amount
    function setBorrowedShares(address _holding, uint256 _newVal) external;

    /// @notice Gets the exchange rate. I.e how much collateral to buy 1e18 asset.
    /// @return updated True if `exchangeRate` was updated.
    /// @return rate The new exchange rate.
    function updateExchangeRate() external returns (bool updated, uint256 rate);

    /// @notice updates the AccrueInfo object
    /// @param _totalBorrowBase total borrow amount
    /// @param _totalBorrowElastic total borrow shares
    function accrue(uint256 _totalBorrowBase, uint256 _totalBorrowElastic)
        external
        returns (uint128);

    /// @notice removes collateral share from user
    /// @param _from the address for which the collateral is removed
    /// @param _to the address for which the collateral is added
    /// @param _share share amount
    function updateLiquidatedCollateral(
        address _from,
        address _to,
        uint256 _share
    ) external;

    /// @notice udates only the fees part of AccureInfo object
    function accrueFees(uint256 _amount) external;

    /// @notice registers collateral for token
    /// @param _holding the user's address for which collateral is registered
    /// @param _share amount of shares
    function registerCollateral(address _holding, uint256 _share) external;

    /// @notice unregisters collateral for token
    /// @param _holding the user's address for which collateral is registered
    /// @param _share amount of shares
    /// @param _totalBorrowBase total borrow amount
    /// @param _totalBorrowElastic total borrow shares
    function unregisterCollateral(
        address _holding,
        uint256 _share,
        uint256 _totalBorrowBase,
        uint256 _totalBorrowElastic
    ) external;

    /// @notice initiates the ownership transferal
    /// @param _newOwner the address of the new owner
    function transferOwnership(address _newOwner) external;

    /// @notice finalizes the ownership transferal process
    /// @dev must be called after `transferOwnership` was executed successfully, by the new temporary onwer
    function acceptOwnership() external;
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

interface IStrategyManagerMin {
    /// @notice returns whitelisted strategies
    function strategyInfo(address _strategy)
        external
        view
        returns (
            uint256,
            bool,
            bool
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IManagerContainer {
    /// @notice emitted when the strategy manager is set
    event ManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice returns manager address
    function manager() external view returns (address);

    /// @notice Updates the manager address
    /// @param _address The address of the manager
    function updateManager(address _address) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library RebaseLib {
    struct Rebase {
        uint128 elastic;
        uint128 base;
    }

    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
            if (roundUp && ((base * total.elastic) / total.base) < elastic) {
                base = base + 1;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
            if (roundUp && ((elastic * total.base) / total.elastic) < base) {
                elastic = elastic + 1;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic = uint128(total.elastic + elastic);
        total.base = uint128(total.base + base);
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic = uint128(total.elastic - elastic);
        total.base = uint128(total.base - base);
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = uint128(total.elastic + elastic);
        total.base = uint128(total.base + base);
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = uint128(total.elastic - elastic);
        total.base = uint128(total.base - base);
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic)
        internal
        returns (uint256 newElastic)
    {
        newElastic = total.elastic = uint128(total.elastic + elastic);
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic)
        internal
        returns (uint256 newElastic)
    {
        newElastic = total.elastic = uint128(total.elastic - elastic);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/IManagerContainer.sol";

interface IPandoraUSD {
    /// @notice event emitted when the mint limit is updated
    event MintLimitUpdated(uint256 oldLimit, uint256 newLimit);

    /// @notice sets the manager address
    /// @param _limit the new mint limit
    function updateMintLimit(uint256 _limit) external;

    /// @notice interface of the manager container contract
    function managerContainer() external view returns (IManagerContainer);

    /// @notice returns the max mint limitF
    function mintLimit() external view returns (uint256);

    /// @notice returns total minted so far
    function totalMinted() external view returns (uint256);

    /// @notice mint tokens
    /// @dev no need to check if '_to' is a valid address if the '_mint' method is used
    /// @param _to address of the user receiving minted tokens
    /// @param _amount the amount to be minted
    /// @param _decimals amount's decimals
    function mint(
        address _to,
        uint256 _amount,
        uint8 _decimals
    ) external;

    /// @notice burns token from sender
    /// @param _amount the amount of tokens to be burnt
    /// @param _decimals amount's decimals
    function burn(uint256 _amount, uint8 _decimals) external;

    /// @notice burns token from an address
    /// @param _user the user to burn it from
    /// @param _amount the amount of tokens to be burnt
    /// @param _decimals amount's decimals
    function burnFrom(
        address _user,
        uint256 _amount,
        uint8 _decimals
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @dev MAKE SURE THIS HAS 10^18 decimals
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data)
        external
        returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data)
        external
        view
        returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
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