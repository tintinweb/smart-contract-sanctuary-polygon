// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IStakingHelper.sol";
import "./interfaces/IwsKLIMA.sol";
import "./interfaces/IKlimaCarbonRetirements.sol";
import "./interfaces/IToucanPool.sol";
import "./interfaces/IToucanCarbonOffsets.sol";
import "./interfaces/IKlimaRetirementAggregator.sol";

contract RetireToucanCarbon is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize() public initializer {
        __Ownable_init();
        __Context_init();
    }

    /** === State Variables and Mappings === */

    /// @notice feeAmount represents the fee to be bonded for KLIMA. 0.1% increments. 10 = 1%

    uint256 public feeAmount;
    address public masterAggregator;
    mapping(address => bool) public isPoolToken;
    mapping(address => address) public poolRouter;

    /** === Event Setup === */

    event ToucanRetired(
        address indexed retiringAddress,
        address indexed beneficiaryAddress,
        string beneficiaryString,
        string retirementMessage,
        address indexed carbonPool,
        address carbonToken,
        uint256 retiredAmount
    );
    event PoolAdded(address indexed carbonPool, address indexed poolRouter);
    event PoolRemoved(address indexed carbonPool);
    event PoolRouterChanged(
        address indexed carbonPool,
        address indexed oldRouter,
        address indexed newRouter
    );
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    event MasterAggregatorUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @notice This function transfers source tokens if needed, swaps to the Toucan
     * pool token, utilizes redeemAuto, then retires the redeemed TCO2. Needed source
     * token amount is expected to be held by the caller to use.
     *
     * @param _sourceToken The contract address of the token being supplied.
     * @param _poolToken The contract address of the pool token being retired.
     * @param _amount The amount being supplied. Expressed in either the total
     *          carbon to offset or the total source to spend. See _amountInCarbon.
     * @param _amountInCarbon Bool indicating if _amount is in carbon or source.
     * @param _beneficiaryAddress Address of the beneficiary of the retirement.
     * @param _beneficiaryString String representing the beneficiary. A name perhaps.
     * @param _retirementMessage Specific message relating to this retirement event.
     * @param _retiree The original sender of the transaction.
     */
    function retireToucan(
        address _sourceToken,
        address _poolToken,
        uint256 _amount,
        bool _amountInCarbon,
        address _beneficiaryAddress,
        string memory _beneficiaryString,
        string memory _retirementMessage,
        address _retiree
    ) public {
        require(isPoolToken[_poolToken], "Not a Toucan Carbon Token");

        // Transfer source tokens

        (
            uint256 sourceAmount,
            uint256 totalCarbon,
            uint256 fee
        ) = _transferSourceTokens(
                _sourceToken,
                _poolToken,
                _amount,
                _amountInCarbon
            );

        // Get the pool tokens

        if (_sourceToken != _poolToken) {
            // Swap the source to get pool
            if (_amountInCarbon) {
                // swapTokensForExactTokens
                _swapForExactCarbon(
                    _sourceToken,
                    _poolToken,
                    totalCarbon,
                    sourceAmount,
                    _retiree
                );
            } else {
                // swapExactTokensForTokens
                (_amount, fee) = _swapExactForCarbon(
                    _sourceToken,
                    _poolToken,
                    sourceAmount
                );
            }
        } else if (!_amountInCarbon) {
            // Calculate the fee and adjust if pool token is provided with false bool
            fee = (_amount * feeAmount) / 1000;
            _amount = _amount - fee;
        }

        // At this point _amount = the amount of carbon to retire

        // Retire the tokens
        _retireCarbon(
            _amount,
            _beneficiaryAddress,
            _beneficiaryString,
            _retirementMessage,
            _poolToken
        );

        // Send the fee to the treasury
        if (feeAmount > 0) {
            IERC20Upgradeable(_poolToken).safeTransfer(
                IKlimaRetirementAggregator(masterAggregator).treasury(),
                fee
            );
        }
    }

    /**
     * @notice Redeems the pool and retires the TCO2 tokens on Polygon.
     *  Emits a retirement event and updates the KlimaCarbonRetirements contract with
     *  retirement details and amounts.
     * @param _totalAmount Total pool tokens being retired. Expected uint with 18 decimals.
     * @param _beneficiaryAddress Address of the beneficiary if different than sender. Value is set to _msgSender() if null is sent.
     * @param _beneficiaryString String that can be used to describe the beneficiary
     * @param _retirementMessage String for specific retirement message if needed.
     * @param _poolToken Address of pool token being used to retire.
     */
    function _retireCarbon(
        uint256 _totalAmount,
        address _beneficiaryAddress,
        string memory _beneficiaryString,
        string memory _retirementMessage,
        address _poolToken
    ) internal {
        // Assign default event values
        if (_beneficiaryAddress == address(0)) {
            _beneficiaryAddress = _msgSender();
        }

        address retirementStorage = IKlimaRetirementAggregator(masterAggregator)
            .klimaRetirementStorage();

        address[] memory listTCO2 = IToucanPool(_poolToken).getScoredTCO2s();

        // Redeem pool tokens
        IToucanPool(_poolToken).redeemAuto(_totalAmount);

        // Retire TCO2
        for (uint256 i = 0; _totalAmount > 0; i++) {
            uint256 balance = IERC20Upgradeable(listTCO2[i]).balanceOf(
                address(this)
            );

            IToucanCarbonOffsets(listTCO2[i]).retire(balance);
            IKlimaCarbonRetirements(retirementStorage).carbonRetired(
                _beneficiaryAddress,
                _poolToken,
                balance,
                _beneficiaryString,
                _retirementMessage
            );
            emit ToucanRetired(
                msg.sender,
                _beneficiaryAddress,
                _beneficiaryString,
                _retirementMessage,
                _poolToken,
                listTCO2[i],
                balance
            );

            _totalAmount -= balance;
        }
    }

    /**
     * @notice Transfers the needed source tokens from the caller to perform any needed
     * swaps and then retire the tokens.
     * @param _sourceToken The contract address of the token being supplied.
     * @param _poolToken The contract address of the pool token being retired.
     * @param _amount The amount being supplied. Expressed in either the total
     *          carbon to offset or the total source to spend. See _amountInCarbon.
     * @param _amountInCarbon Bool indicating if _amount is in carbon or source.
     */
    function _transferSourceTokens(
        address _sourceToken,
        address _poolToken,
        uint256 _amount,
        bool _amountInCarbon
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        address sKLIMA = IKlimaRetirementAggregator(masterAggregator).sKLIMA();
        address wsKLIMA = IKlimaRetirementAggregator(masterAggregator)
            .wsKLIMA();

        uint256 fee;
        uint256 sourceAmount;

        // If submitting the amount in carbon, add fee to transfer amount.
        if (_amountInCarbon) {
            (sourceAmount, fee) = getNeededBuyAmount(
                _sourceToken,
                _poolToken,
                _amount
            );
        } else {
            sourceAmount = _amount;
        }

        if (_sourceToken == sKLIMA || _sourceToken == wsKLIMA) {
            sourceAmount = _stakedToUnstaked(_sourceToken, sourceAmount);
        } else {
            IERC20Upgradeable(_sourceToken).safeTransferFrom(
                _msgSender(),
                address(this),
                sourceAmount
            );
        }

        return (sourceAmount, _amount + fee, fee);
    }

    /**
     * @notice Unwraps/unstakes any KLIMA needed to regular KLIMA.
     * @param _klimaType Address of the KLIMA type being used.
     * @param _amountIn Amount of total KLIMA needed.
     * @return Returns the total number of KLIMA after unwrapping/unstaking.
     */
    function _stakedToUnstaked(address _klimaType, uint256 _amountIn)
        internal
        returns (uint256)
    {
        uint256 unwrappedKLIMA = _amountIn;

        // Get token addresses from master
        address sKLIMA = IKlimaRetirementAggregator(masterAggregator).sKLIMA();
        address wsKLIMA = IKlimaRetirementAggregator(masterAggregator)
            .wsKLIMA();
        address staking = IKlimaRetirementAggregator(masterAggregator)
            .staking();

        if (_klimaType == wsKLIMA) {
            // Get wsKLIMA needed, transfer and unwrap, unstake to KLIMA
            uint256 wsKLIMANeeded = IwsKLIMA(wsKLIMA).sKLIMATowKLIMA(_amountIn);

            IERC20Upgradeable(wsKLIMA).safeTransferFrom(
                _msgSender(),
                address(this),
                wsKLIMANeeded
            );
            IERC20Upgradeable(wsKLIMA).safeIncreaseAllowance(
                wsKLIMA,
                wsKLIMANeeded
            );
            unwrappedKLIMA = IwsKLIMA(wsKLIMA).unwrap(wsKLIMANeeded);
        }

        // If using sKLIMA, transfer in and unstake
        if (_klimaType == sKLIMA) {
            IERC20Upgradeable(sKLIMA).safeTransferFrom(
                _msgSender(),
                address(this),
                unwrappedKLIMA
            );
        }
        IERC20Upgradeable(sKLIMA).safeIncreaseAllowance(
            staking,
            unwrappedKLIMA
        );
        IStaking(staking).unstake(unwrappedKLIMA, false);

        return unwrappedKLIMA;
    }

    /**
     * @notice Call the UniswapV2 routers for needed amounts on token being retired.
     * Also calculates and returns any fee needed in the pool token total.
     * @param _sourceToken Address of token being used to purchase the pool token.
     * @param _poolToken Address of pool token being used.
     * @param _poolAmount Amount of tokens being retired.
     * @return Tuple of the total pool amount needed, followed by the fee.
     */
    function getNeededBuyAmount(
        address _sourceToken,
        address _poolToken,
        uint256 _poolAmount
    ) public view returns (uint256, uint256) {
        uint256 fee = (_poolAmount * feeAmount) / 1000;
        uint256 totalAmount = _poolAmount + fee;

        if (_sourceToken != _poolToken) {
            address[] memory path = getSwapPath(_sourceToken, _poolToken);

            uint256[] memory amountIn = IUniswapV2Router02(
                poolRouter[_poolToken]
            ).getAmountsIn(totalAmount, path);

            // Account for .1% default AMM slippage.
            totalAmount = (amountIn[0] * 1001) / 1000;
        }

        return (totalAmount, fee);
    }

    /**
     * @notice Creates an array of addresses to use in performing any needed
     * swaps to receive the pool token from the source token.
     *
     * @dev This function will produce an invalid path if the source token
     * does not have a direct USDC LP route on the pool's AMM. The resulting
     * transaction would revert.
     *
     * @param _sourceToken Address of token being used to purchase the pool token.
     * @param _poolToken Address of pool token being used.
     * @return Array of addresses to be used as the path for the swap.
     */
    function getSwapPath(address _sourceToken, address _poolToken)
        public
        view
        returns (address[] memory)
    {
        address[] memory path;

        // Get addresses from master.
        address KLIMA = IKlimaRetirementAggregator(masterAggregator).KLIMA();
        address sKLIMA = IKlimaRetirementAggregator(masterAggregator).sKLIMA();
        address wsKLIMA = IKlimaRetirementAggregator(masterAggregator)
            .wsKLIMA();
        address USDC = IKlimaRetirementAggregator(masterAggregator).USDC();

        // Account for sKLIMA and wsKLIMA source tokens - swapping with KLIMA
        if (_sourceToken == sKLIMA || _sourceToken == wsKLIMA) {
            _sourceToken = KLIMA;
        }

        // If the source is KLIMA or USDC do a direct swap, else route through USDC.
        if (_sourceToken == KLIMA || _sourceToken == USDC) {
            path = new address[](2);
            path[0] = _sourceToken;
            path[1] = _poolToken;
        } else {
            path = new address[](3);
            path[0] = _sourceToken;
            path[1] = USDC;
            path[2] = _poolToken;
        }

        return path;
    }

    /**
     * @notice Swaps the source token for an exact number of carbon tokens, and
     * returns any dust to the initiator.
     *
     * @dev This is only called if the _amountInCarbon bool is set to true.
     *
     * @param _sourceToken Address of token being used to purchase the pool token.
     * @param _poolToken Address of pool token being used.
     * @param _carbonAmount Total carbon needed.
     * @param _amountIn Maximum amount of source tokens.
     * @param _retiree Initiator of the retirement to return any dust.
     */
    function _swapForExactCarbon(
        address _sourceToken,
        address _poolToken,
        uint256 _carbonAmount,
        uint256 _amountIn,
        address _retiree
    ) internal {
        address[] memory path = getSwapPath(_sourceToken, _poolToken);

        IERC20Upgradeable(path[0]).safeIncreaseAllowance(
            poolRouter[_poolToken],
            _amountIn
        );

        uint256[] memory amounts = IUniswapV2Router02(poolRouter[_poolToken])
            .swapTokensForExactTokens(
                _carbonAmount,
                _amountIn,
                path,
                address(this),
                block.timestamp
            );

        _returnTradeDust(amounts, _sourceToken, _amountIn, _retiree);
    }

    /**
     * @notice Swaps an exact number of source tokens for carbon tokens.
     *
     * @dev This is only called if the _amountInCarbon bool is set to false.
     *
     * @param _sourceToken Address of token being used to purchase the pool token.
     * @param _poolToken Address of pool token being used.
     * @param _amountIn Total source tokens to swap.
     * @return Returns the resulting carbon amount to retire and the fee from the
     * results of the swap.
     */
    function _swapExactForCarbon(
        address _sourceToken,
        address _poolToken,
        uint256 _amountIn
    ) internal returns (uint256, uint256) {
        address[] memory path = getSwapPath(_sourceToken, _poolToken);

        uint256[] memory amountsOut = IUniswapV2Router02(poolRouter[_poolToken])
            .getAmountsOut(_amountIn, path);

        uint256 totalCarbon = amountsOut[path.length - 1];

        IERC20Upgradeable(_sourceToken).safeIncreaseAllowance(
            poolRouter[_poolToken],
            _amountIn
        );

        uint256[] memory amounts = IUniswapV2Router02(poolRouter[_poolToken])
            .swapExactTokensForTokens(
                _amountIn,
                (totalCarbon * 995) / 1000,
                path,
                address(this),
                block.timestamp
            );

        totalCarbon = amounts[amounts.length - 1] == 0
            ? amounts[amounts.length - 2]
            : amounts[amounts.length - 1];

        uint256 fee = (totalCarbon * feeAmount) / 1000;

        return (totalCarbon - fee, fee);
    }

    /**
     * @notice Returns any trade dust to the designated address. If sKLIMA or
     * wsKLIMA was provided as a source token, it is re-staked and/or wrapped
     * before transferring back.
     *
     * @param _amounts The amounts resulting from the Uniswap tradeTokensForExactTokens.
     * @param _sourceToken Address of token being used to purchase the pool token.
     * @param _amountIn Total source tokens initially provided.
     * @param _retiree Address where to send the dust.
     */
    function _returnTradeDust(
        uint256[] memory _amounts,
        address _sourceToken,
        uint256 _amountIn,
        address _retiree
    ) internal {
        address KLIMA = IKlimaRetirementAggregator(masterAggregator).KLIMA();
        address sKLIMA = IKlimaRetirementAggregator(masterAggregator).sKLIMA();
        address wsKLIMA = IKlimaRetirementAggregator(masterAggregator)
            .wsKLIMA();
        address stakingHelper = IKlimaRetirementAggregator(masterAggregator)
            .stakingHelper();

        uint256 tradeDust = _amountIn -
            (_amounts[0] == 0 ? _amounts[1] : _amounts[0]);

        if (_sourceToken == sKLIMA || _sourceToken == wsKLIMA) {
            IERC20Upgradeable(KLIMA).safeIncreaseAllowance(
                stakingHelper,
                tradeDust
            );

            IStakingHelper(stakingHelper).stake(tradeDust);

            if (_sourceToken == sKLIMA) {
                IERC20Upgradeable(sKLIMA).safeTransfer(_retiree, tradeDust);
            } else if (_sourceToken == wsKLIMA) {
                IERC20Upgradeable(sKLIMA).safeIncreaseAllowance(
                    wsKLIMA,
                    tradeDust
                );
                uint256 wrappedDust = IwsKLIMA(wsKLIMA).wrap(tradeDust);
                IERC20Upgradeable(wsKLIMA).safeTransfer(_retiree, wrappedDust);
            }
        } else {
            IERC20Upgradeable(_sourceToken).safeTransfer(_retiree, tradeDust);
        }
    }

    /**
        @notice Set the fee for the helper
        @param _amount New fee amount, in .1% increments. 10 = 1%
        @return bool
     */
    function setFeeAmount(uint256 _amount) external onlyOwner returns (bool) {
        uint256 oldFee = feeAmount;
        feeAmount = _amount;

        emit FeeUpdated(oldFee, feeAmount);
        return true;
    }

    /**
        @notice Update the router for an existing pool
        @param _poolToken Pool being updated
        @param _router New router address
        @return bool
     */
    function setPoolRouter(address _poolToken, address _router)
        external
        onlyOwner
        returns (bool)
    {
        require(isPoolToken[_poolToken], "Pool not added");

        address oldRouter = poolRouter[_poolToken];
        poolRouter[_poolToken] = _router;
        emit PoolRouterChanged(_poolToken, oldRouter, poolRouter[_poolToken]);
        return true;
    }

    /**
        @notice Add a new carbon pool to retire with helper contract
        @param _poolToken Pool being added
        @param _router UniswapV2 router to route trades through for non-pool retirements
        @return bool
     */
    function addPool(address _poolToken, address _router)
        external
        onlyOwner
        returns (bool)
    {
        require(!isPoolToken[_poolToken], "Pool already added");
        require(_poolToken != address(0), "Pool cannot be zero address");

        isPoolToken[_poolToken] = true;
        poolRouter[_poolToken] = _router;

        emit PoolAdded(_poolToken, _router);
        return true;
    }

    /**
        @notice Remove a carbon pool to retire with helper contract
        @param _poolToken Pool being removed
        @return bool
     */
    function removePool(address _poolToken) external onlyOwner returns (bool) {
        require(isPoolToken[_poolToken], "Pool not added");

        isPoolToken[_poolToken] = false;

        emit PoolRemoved(_poolToken);
        return true;
    }

    /**
        @notice Allow withdrawal of any tokens sent in error
        @param _token Address of token to transfer
        @param _recipient Address where to send tokens.
     */
    function feeWithdraw(address _token, address _recipient)
        public
        onlyOwner
        returns (bool)
    {
        IERC20Upgradeable(_token).safeTransfer(
            _recipient,
            IERC20Upgradeable(_token).balanceOf(address(this))
        );

        return true;
    }

    /**
        @notice Allow the contract owner to update the master aggregator proxy address used.
        @param _newAddress New address for contract needing to be updated.
        @return bool
     */
    function setMasterAggregator(address _newAddress)
        external
        onlyOwner
        returns (bool)
    {
        address oldAddress = masterAggregator;
        masterAggregator = _newAddress;

        emit MasterAggregatorUpdated(oldAddress, _newAddress);

        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStaking {
    function unstake(uint256 _amount, bool _trigger) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStakingHelper {
    function stake(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IwsKLIMA {
    function wrap(uint256 _amount) external returns (uint256);

    function unwrap(uint256 _amount) external returns (uint256);

    function wKLIMATosKLIMA(uint256 _amount) external view returns (uint256);

    function sKLIMATowKLIMA(uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IKlimaCarbonRetirements {
    function carbonRetired(
        address _retiree,
        address _pool,
        uint256 _amount,
        string calldata _beneficiaryString,
        string calldata _retirementMessage
    ) external;

    function getUnclaimedTotal(address _minter) external view returns (uint256);

    function offsetClaimed(address _minter, uint256 _amount)
        external
        returns (bool);

    function getRetirementIndexInfo(address _retiree, uint256 _index)
        external
        view
        returns (
            address,
            uint256,
            string memory
        );

    function getRetirementPoolInfo(address _retiree, address _pool)
        external
        view
        returns (uint256);

    function getRetirementTotals(address _retiree)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IToucanPool {
    function getScoredTCO2s() external view returns (address[] memory);

    function redeemAuto(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IToucanCarbonOffsets {
    function retire(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IKlimaRetirementAggregator {
    function KLIMA() external pure returns (address);

    function sKLIMA() external pure returns (address);

    function wsKLIMA() external pure returns (address);

    function USDC() external pure returns (address);

    function staking() external pure returns (address);

    function stakingHelper() external pure returns (address);

    function klimaRetirementStorage() external pure returns (address);

    function treasury() external pure returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
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

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}