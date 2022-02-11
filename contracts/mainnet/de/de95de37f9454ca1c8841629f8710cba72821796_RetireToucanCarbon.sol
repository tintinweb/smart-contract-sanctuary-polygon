// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IToucanCarbonOffsets.sol";
import "./interfaces/IBaseCarbonTonne.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IStakingHelper.sol";
import "./interfaces/IwsKLIMA.sol";
import "./interfaces/IBondDepository.sol";
import "./interfaces/IKlimaCarbonRetirements.sol";

contract RetireToucanCarbon is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(
        address _KLIMA,
        address _sKLIMA,
        address _wsKLIMA,
        address _USDC,
        address _staking,
        address _stakingHelper,
        address _DAO,
        address _KlimaRetirementStorage
    ) public initializer {
        // Null check for constructors
        require(_KLIMA != address(0));
        require(_sKLIMA != address(0));
        require(_wsKLIMA != address(0));
        require(_USDC != address(0));
        require(_staking != address(0));
        require(_stakingHelper != address(0));
        require(_DAO != address(0));
        require(_KlimaRetirementStorage != address(0));

        KLIMA = _KLIMA;
        sKLIMA = _sKLIMA;
        wsKLIMA = _wsKLIMA;
        USDC = _USDC;
        staking = _staking;
        stakingHelper = _stakingHelper;
        DAO = _DAO;
        KlimaRetirementStorage = _KlimaRetirementStorage;

        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    address public KLIMA;
    address public sKLIMA;
    address public wsKLIMA;
    address public USDC;
    address public staking;
    address public stakingHelper;
    address public DAO;
    address public KlimaRetirementStorage;

    // Event setup
    event ToucanRetired(
        address indexed retiringAddress,
        address indexed beneficiaryAddress,
        string beneficiaryString,
        string retirementMessage,
        address indexed carbonPool,
        address carbonToken,
        uint256 retiredAmount
    );
    event PoolAdded(
        address indexed carbonPool,
        address indexed poolRouter,
        address indexed bondDepository
    );
    event PoolRouterChanged(
        address indexed carbonPool,
        address indexed oldRouter,
        address indexed newRouter
    );
    event PoolBondChanged(
        address indexed carbonPool,
        address indexed oldBondDepository,
        address indexed newBondDepository
    );
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    event AddressUpdated(
        uint256 addressIndex,
        address indexed oldAddress,
        address indexed newAddress
    );

    address[] public toucanPools;
    mapping(address => bool) public isToucanPool;
    mapping(address => address) public poolRouter;
    mapping(address => address) public bondDepository;

    /// @notice feeAmount represents the fee to be bonded for KLIMA. 0.1% increments. 10 = 1%
    uint256 feeAmount;

    /**
        @notice Get KLIMA type provided to regular KLIMA, swap, then retire.
        @param _klimaType Address of the original KLIMA token provided (Wrapped/Staked/Unstaked).
        @param _amount Total pool tokens being retired. Expected uint with 18 decimals.
        @param _beneficiaryAddress Address of the beneficiary if different than sender. Value is set to msg.sender if null is sent.
        @param _beneficiaryString String that can be used to describe the beneficiary
        @param _retirementMessage String for specific retirement message if needed.
        @param _listTCO2 List of TCO2 token addresses to redeem pool tokens.
        @param _toucanPool Address of pool token being used to retire.
     */
    function retireWithKLIMA(
        address _klimaType,
        uint256 _amount,
        address _beneficiaryAddress,
        string calldata _beneficiaryString,
        string calldata _retirementMessage,
        address[] calldata _listTCO2,
        address _toucanPool
    ) public {
        require(isToucanPool[_toucanPool], "Not a Toucan Protocol Carbon Pool");

        uint256 totalPoolNeeded = (_amount * (1000 + feeAmount)) / 1000;

        (uint256 amountIn, address[] memory path) = getNeededBuyAmount(
            KLIMA,
            _toucanPool,
            totalPoolNeeded
        );

        // If using KLIMA, transfer directly. Otherwise transfer and unwrap/stake
        if (_klimaType == KLIMA) {
            IERC20Upgradeable(KLIMA).safeTransferFrom(
                msg.sender,
                address(this),
                amountIn
            );
        } else {
            amountIn = _stakedToUnstaked(_klimaType, amountIn);
        }

        IERC20Upgradeable(KLIMA).safeIncreaseAllowance(
            poolRouter[_toucanPool],
            amountIn
        );

        uint256[] memory amounts = IUniswapV2Router02(poolRouter[_toucanPool])
            .swapTokensForExactTokens(
                totalPoolNeeded,
                amountIn,
                path,
                address(this),
                block.timestamp
            );
        // Return any dust remaining (slippage protection)

        _returnKLIMADust(_klimaType, amounts, amountIn);

        // Retire the carbon
        _retireCarbon(
            _amount,
            _beneficiaryAddress,
            _beneficiaryString,
            _retirementMessage,
            _listTCO2,
            _toucanPool
        );

        _bondFees(_toucanPool);
    }

    /**
        @notice Swap from USDC then retire.
        @param _amount Total pool tokens being retired. Expected uint with 18 decimals.
        @param _beneficiaryAddress Address of the beneficiary if different than sender. Value is set to msg.sender if null is sent.
        @param _beneficiaryString String that can be used to describe the beneficiary
        @param _retirementMessage String for specific retirement message if needed.
        @param _listTCO2 List of TCO2 token addresses to redeem pool tokens.
        @param _toucanPool Address of pool token being used to retire.
     */
    function retireWithUSDC(
        uint256 _amount,
        address _beneficiaryAddress,
        string calldata _beneficiaryString,
        string calldata _retirementMessage,
        address[] calldata _listTCO2,
        address _toucanPool
    ) public {
        require(isToucanPool[_toucanPool], "Not a Toucan Protocol Carbon Pool");

        uint256 totalPoolNeeded = (_amount * (1000 + feeAmount)) / 1000;

        (uint256 amountIn, address[] memory path) = getNeededBuyAmount(
            USDC,
            _toucanPool,
            totalPoolNeeded
        );

        // Transfer and swap from USDC to Carbon Pool

        IERC20Upgradeable(USDC).safeTransferFrom(
            msg.sender,
            address(this),
            amountIn
        );

        IERC20Upgradeable(USDC).safeIncreaseAllowance(
            poolRouter[_toucanPool],
            amountIn
        );

        uint256[] memory amounts = IUniswapV2Router02(poolRouter[_toucanPool])
            .swapTokensForExactTokens(
                totalPoolNeeded,
                amountIn,
                path,
                address(this),
                block.timestamp
            );
        // Return any dust remaining (slippage protection)

        uint256 tradeDust = amountIn -
            (amounts[0] == 0 ? amounts[1] : amounts[0]);

        IERC20Upgradeable(USDC).safeTransfer(msg.sender, tradeDust);

        // Retire the carbon
        _retireCarbon(
            _amount,
            _beneficiaryAddress,
            _beneficiaryString,
            _retirementMessage,
            _listTCO2,
            _toucanPool
        );

        _bondFees(_toucanPool);
    }

    /**
        @notice Transfer needed pool tokens to helper contract then retire.
        @param _amount Total pool tokens being retired. Expected uint with 18 decimals.
        @param _beneficiaryAddress Address of the beneficiary if different than sender. Value is set to msg.sender if null is sent.
        @param _beneficiaryString String that can be used to describe the beneficiary
        @param _retirementMessage String for specific retirement message if needed.
        @param _listTCO2 List of TCO2 token addresses to redeem pool tokens.
        @param _toucanPool Address of pool token being used to retire.
     */
    function retireWithPool(
        uint256 _amount,
        address _beneficiaryAddress,
        string calldata _beneficiaryString,
        string calldata _retirementMessage,
        address[] calldata _listTCO2,
        address _toucanPool
    ) public {
        require(isToucanPool[_toucanPool], "Not a Toucan Protocol Carbon Pool");

        uint256 totalPoolNeeded = (_amount * (1000 + feeAmount)) / 1000;

        // Transfer in the pool token to retire
        IERC20Upgradeable(_toucanPool).safeTransferFrom(
            msg.sender,
            address(this),
            totalPoolNeeded
        );

        // Retire the carbon
        _retireCarbon(
            _amount,
            _beneficiaryAddress,
            _beneficiaryString,
            _retirementMessage,
            _listTCO2,
            _toucanPool
        );

        _bondFees(_toucanPool);
    }

    /**
        @notice Retires the underlying TCO2s from the pool using a provided list.
        @notice Emits a retirement event and updates the KlimaCarbonRetirements contract with
        @notice retirement details and amounts.
        @param _totalAmount Total pool tokens being retired. Expected uint with 18 decimals.
        @param _beneficiaryAddress Address of the beneficiary if different than sender. Value is set to msg.sender if null is sent.
        @param _beneficiaryString String that can be used to describe the beneficiary
        @param _retirementMessage String for specific retirement message if needed.
        @param _listTCO2 List of TCO2 token addresses to redeem pool tokens.
        @param _toucanPool Address of pool token being used to retire.
     */
    function _retireCarbon(
        uint256 _totalAmount,
        address _beneficiaryAddress,
        string calldata _beneficiaryString,
        string calldata _retirementMessage,
        address[] calldata _listTCO2,
        address _toucanPool
    ) internal {
        // Assign default event values
        if (_beneficiaryAddress == address(0)) {
            _beneficiaryAddress = msg.sender;
        }

        for (uint256 i = 0; i < _listTCO2.length && _totalAmount > 0; i++) {
            // Start with the first address in the list and work your way down.

            // Get the pools balance of TCO2
            uint256 poolBalance = IERC20Upgradeable(_listTCO2[i]).balanceOf(
                _toucanPool
            );

            // Error check for possible 0 balance / stale lists
            if (poolBalance != 0) {
                address[] memory redeemERC20 = new address[](1);
                redeemERC20[0] = _listTCO2[i];

                uint256[] memory redeemAmount = new uint256[](1);

                // Burn only pool balance if there are more pool tokens than available
                if (_totalAmount > poolBalance) {
                    redeemAmount[0] = poolBalance;
                } else {
                    redeemAmount[0] = _totalAmount;
                }

                // Redeem from pool
                IBaseCarbonTonne(_toucanPool).redeemMany(
                    redeemERC20,
                    redeemAmount
                );

                // Retire TCO2
                IToucanCarbonOffsets(_listTCO2[i]).retire(redeemAmount[0]);
                IKlimaCarbonRetirements(KlimaRetirementStorage).carbonRetired(
                    _beneficiaryAddress,
                    _toucanPool,
                    redeemAmount[0],
                    _beneficiaryString,
                    _retirementMessage
                );
                emit ToucanRetired(
                    msg.sender,
                    _beneficiaryAddress,
                    _beneficiaryString,
                    _retirementMessage,
                    _toucanPool,
                    _listTCO2[i],
                    redeemAmount[0]
                );

                _totalAmount -= redeemAmount[0];
            }
        }

        require(
            _totalAmount == 0,
            "Not all pool tokens were burned. Please submit a larger TCO2 token list."
        );
    }

    /**
        @notice Unwraps/unstakes any KLIMA needed to regular KLIMA.
        @param _klimaType Address of the KLIMA type being used.
        @param _amountIn Amount of pool token needed.
     */
    function _stakedToUnstaked(address _klimaType, uint256 _amountIn)
        internal
        returns (uint256)
    {
        uint256 unwrappedKLIMA;

        if (_klimaType == wsKLIMA) {
            // Get wsKLIMA needed, transfer and unwrap, unstake to KLIMA
            uint256 wsKLIMANeeded = IwsKLIMA(wsKLIMA).sKLIMATowKLIMA(_amountIn);

            IERC20Upgradeable(wsKLIMA).safeTransferFrom(
                msg.sender,
                address(this),
                wsKLIMANeeded
            );
            IERC20Upgradeable(wsKLIMA).approve(wsKLIMA, wsKLIMANeeded);
            unwrappedKLIMA = IwsKLIMA(wsKLIMA).unwrap(wsKLIMANeeded);
            IERC20Upgradeable(sKLIMA).safeIncreaseAllowance(
                staking,
                unwrappedKLIMA
            );
            IStaking(staking).unstake(unwrappedKLIMA, false);
        }

        // If using sKLIMA, transfer in and unstake
        if (_klimaType == sKLIMA) {
            IERC20Upgradeable(sKLIMA).safeTransferFrom(
                msg.sender,
                address(this),
                _amountIn
            );
            IERC20Upgradeable(sKLIMA).safeIncreaseAllowance(staking, _amountIn);
            IStaking(staking).unstake(_amountIn, false);
        }

        return unwrappedKLIMA;
    }

    /**
        @notice Bonds any accumualted fees to the DAO address if the minimum bond size is met.
        @param _klimaType Address of the type of KLIMA provided.
        @param _amounts Swap results.
        @param _amountIn Original KLIMA amount needed.
     */
    function _returnKLIMADust(
        address _klimaType,
        uint256[] memory _amounts,
        uint256 _amountIn
    ) internal {
        uint256 tradeDust;

        if (_klimaType == KLIMA) {
            tradeDust =
                _amountIn -
                (_amounts[0] == 0 ? _amounts[1] : _amounts[0]);
            IERC20Upgradeable(KLIMA).safeTransfer(msg.sender, tradeDust);
        } else {
            tradeDust =
                _amountIn -
                (_amounts[0] == 0 ? _amounts[1] : _amounts[0]);
            IERC20Upgradeable(KLIMA).safeIncreaseAllowance(
                stakingHelper,
                tradeDust
            );

            IStakingHelper(stakingHelper).stake(tradeDust);
        }
        if (_klimaType == sKLIMA) {
            IERC20Upgradeable(sKLIMA).safeTransfer(msg.sender, tradeDust);
        } else if (_klimaType == wsKLIMA) {
            IERC20Upgradeable(sKLIMA).safeIncreaseAllowance(wsKLIMA, tradeDust);
            uint256 wrappedDust = IwsKLIMA(wsKLIMA).wrap(tradeDust);
            IERC20Upgradeable(wsKLIMA).safeTransfer(msg.sender, wrappedDust);
        }
    }

    /**
        @notice Bonds any accumualted fees to the DAO address if the minimum bond size is met.
        @param _toucanPool Address of the pool token being retired.
     */
    function _bondFees(address _toucanPool) internal returns (bool) {
        // Bond cumulative fees to the DAO if bond is large enough
        uint256 poolBalance = IERC20Upgradeable(_toucanPool).balanceOf(
            address(this)
        );

        uint256 bondPrice = IKlimaBondDepository(bondDepository[_toucanPool])
            .bondPriceInUSD();

        // Minimum .01 KLIMA bond size
        if ((poolBalance * (1e9)) / bondPrice > 1e7) {
            IERC20Upgradeable(_toucanPool).safeIncreaseAllowance(
                bondDepository[_toucanPool],
                poolBalance
            );

            IKlimaBondDepository(bondDepository[_toucanPool]).deposit(
                poolBalance,
                bondPrice,
                DAO
            );
        }
        return true;
    }

    /**
        @notice Allow the contract owner to update Klima protocol addresses resulting from possible migrations.
        @param _selection Int to indicate which address is being updated.
        @param _newAddress New address for contract needing to be updated.
        @return bool
     */
    function setAddress(uint256 _selection, address _newAddress)
        external
        onlyOwner
        returns (bool)
    {
        address oldAddress;
        if (_selection == 0) {
            oldAddress = KLIMA;
            KLIMA = _newAddress; // 0; Set new KLIMA address
        } else if (_selection == 1) {
            oldAddress = sKLIMA;
            sKLIMA = _newAddress; // 1; Set new sKLIMA address
        } else if (_selection == 2) {
            oldAddress = wsKLIMA;
            wsKLIMA = _newAddress; // 2; Set new wsKLIMA address
        } else if (_selection == 3) {
            oldAddress = staking;
            staking = _newAddress; // 3; Set new staking address
        } else if (_selection == 4) {
            oldAddress = stakingHelper;
            stakingHelper = _newAddress; // 4; Set new stakingHelper address
        } else if (_selection == 5) {
            oldAddress = KlimaRetirementStorage;
            KlimaRetirementStorage = _newAddress; // 5; Set new storage address
        } else if (_selection == 6) {
            oldAddress = DAO;
            DAO = _newAddress; // 6; Set new DAO address
        } else {
            return false;
        }

        emit AddressUpdated(_selection, oldAddress, _newAddress);

        return true;
    }

    /**
        @notice Update the router for an existing pool
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
        @param _toucanPool Pool being updated
        @param _router New router address
        @return bool
     */
    function setPoolRouter(address _toucanPool, address _router)
        external
        onlyOwner
        returns (bool)
    {
        address oldRouter = poolRouter[_toucanPool];
        poolRouter[_toucanPool] = _router;
        emit PoolRouterChanged(_toucanPool, oldRouter, poolRouter[_toucanPool]);
        return true;
    }

    /**
        @notice Add a new carbon pool to retire with helper contract
        @param _toucanPool Pool being added
        @param _router UniswapV2 router to route trades through for non-pool retirements
        @param _bondDepository Bond depository address
        @return bool
     */
    function addPool(
        address _toucanPool,
        address _router,
        address _bondDepository
    ) external onlyOwner returns (bool) {
        require(!listContains(toucanPools, _toucanPool), "Pool already added");
        require(_toucanPool != address(0), "Pool cannot be zero address");

        toucanPools.push(_toucanPool);
        isToucanPool[_toucanPool] = true;
        poolRouter[_toucanPool] = _router;
        bondDepository[_toucanPool] = _bondDepository;

        emit PoolAdded(_toucanPool, _router, _bondDepository);
        return true;
    }

    /**
        @notice Update the bond depository for a carbon pool
        @param _toucanPool Pool being updated
        @param _bondDepository New depository address
        @return bool
     */
    function updateBondDepository(address _toucanPool, address _bondDepository)
        external
        onlyOwner
        returns (bool)
    {
        require(isToucanPool[_toucanPool], "Not a Toucan Carbon Pool");

        address oldBond = bondDepository[_toucanPool];
        bondDepository[_toucanPool] = _bondDepository;
        emit PoolBondChanged(_toucanPool, oldBond, _bondDepository);
        return true;
    }

    /**
        @notice checks array to ensure against duplicate
        @param _list address[]
        @param _token address
        @return bool
     */
    function listContains(address[] storage _list, address _token)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _list.length; i++) {
            if (_list[i] == _token) {
                return true;
            }
        }
        return false;
    }

    /**
        @notice Call the Uniswap routers for needed amounts on token being retired.
        @param _purchaseToken Address of token being used to purchase the pool token.
        @param _toucanPool Address of pool token being used.
        @param _poolAmount Amount of tokens being retired.
        @return bool
     */
    function getNeededBuyAmount(
        address _purchaseToken,
        address _toucanPool,
        uint256 _poolAmount
    ) public view returns (uint256, address[] memory) {
        address[] memory path = new address[](2);

        path[0] = _purchaseToken;
        path[1] = _toucanPool;

        uint256[] memory amountIn = IUniswapV2Router02(poolRouter[_toucanPool])
            .getAmountsIn(_poolAmount, path);

        // Account for .1% default AMM slippage.
        return ((amountIn[0] * 1001) / 1000, path);
    }

    /**
        @notice Allow withdrawal of any unbonded fees
        @param _token Address of token to transfer
        @return bool
     */
    function feeWithdraw(address _token) public onlyOwner returns (bool) {
        IERC20Upgradeable(_token).safeTransfer(
            msg.sender,
            IERC20Upgradeable(_token).balanceOf(address(this))
        );

        return true;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IwsKLIMA {
    function wrap(uint256 _amount) external returns (uint256);

    function unwrap(uint256 _amount) external returns (uint256);

    function wKLIMATosKLIMA(uint256 _amount) external view returns (uint256);

    function sKLIMATowKLIMA(uint256 _amount) external view returns (uint256);
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IToucanCarbonOffsets {
    function retire(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStakingHelper {
    function stake(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStaking {
    function unstake(uint256 _amount, bool _trigger) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

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

interface IKlimaBondDepository {
    function bondPriceInUSD() external view returns (uint256 price_);

    function deposit(
        uint256 _amount,
        uint256 _maxPrice,
        address _depositor
    ) external returns (uint256);

    function pendingPayoutFor(address _depositor)
        external
        view
        returns (uint256 pendingPayout_);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IBaseCarbonTonne {
    function redeemMany(address[] calldata erc20s, uint256[] calldata amounts)
        external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
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
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}