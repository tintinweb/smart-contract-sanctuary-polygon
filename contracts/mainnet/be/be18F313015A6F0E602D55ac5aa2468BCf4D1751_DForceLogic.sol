// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "../../../LendingLogic.sol";
import "../../../interfaces/IDForce.sol";

contract DForceLogic is LendingLogic {
    /*** Override internal function ***/

    function _checkMarkets(address xToken)
        internal
        view
        override
        returns (bool isUsedXToken)
    {
        isUsedXToken = IComptrollerDForce(comptroller).hasiToken(xToken);
    }

    function _enterMarkets(address[] calldata xTokens)
        internal
        override
        returns (uint256[] memory)
    {
        bool[] memory results = IComptrollerDForce(comptroller).enterMarkets(
            xTokens
        );

        uint256[] memory resultsUint = new uint256[](results.length);

        for (uint256 i = 0; i < results.length; ) {
            resultsUint[i] = results[i] ? 0 : 1;
            unchecked {
                ++i;
            }
        }

        return resultsUint;
    }

    function _mint(address xToken, uint256 mintAmount)
        internal
        override
        returns (uint256)
    {
        if (xToken == xETH) {
            IiTokenETH(xToken).mint{value: mintAmount}(address(this));
            return 0;
        }

        IiToken(xToken).mint(address(this), mintAmount);
        return 0;
    }

    function _borrow(address xToken, uint256 borrowAmount)
        internal
        override
        returns (uint256)
    {
        // Get my account's total liquidity value in Compound
        (uint256 liquidity, uint256 shortfall, , ) = IComptrollerDForce(
            comptroller
        ).calcAccountEquity(address(this));

        require(liquidity > 0, "E12");
        require(shortfall == 0, "E11");

        IiToken(xToken).borrow(borrowAmount);
        return 0;
    }

    function _repayBorrow(address xToken, uint256 repayAmount)
        internal
        override
        returns (uint256)
    {
        if (xToken == xETH) {
            IiTokenETH(xToken).repayBorrow{value: repayAmount}();
            return 0;
        }

        IiToken(xToken).repayBorrow(repayAmount);
        return 0;
    }

    function _redeemUnderlying(address xToken, uint256 redeemAmount)
        internal
        override
        returns (uint256)
    {
        IiToken(xToken).redeemUnderlying(address(this), redeemAmount);
        return 0;
    }

    function _redeem(address xToken, uint256 redeemTokenAmount)
        internal
        override
        returns (uint256)
    {
        IiToken(xToken).redeem(address(this), redeemTokenAmount);
        return 0;
    }

    function _claim(address[] memory xTokens) internal override {
        address[] memory holders = new address[](1);
        holders[0] = address(this);

        IDistributionDForce(rainMaker).claimReward(holders, xTokens);
    }

    function _getAllMarkets()
        internal
        view
        override
        returns (address[] memory)
    {
        return IComptrollerDForce(comptroller).getAlliTokens();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "./BaseLogic.sol";
import "./interfaces/IXToken.sol";
import "./interfaces/ILogicContract.sol";
import "./interfaces/ICompound.sol";

abstract contract LendingLogic is ILendingLogic, BaseLogic {
    address public comptroller;
    address public rainMaker;

    address internal xETH;
    mapping(address => bool) internal usedXTokens;
    mapping(address => address) internal XTokens;

    function __LendingLogic_init(address _comptroller, address _rainMaker)
        public
        initializer
    {
        UpgradeableBase.initialize();

        comptroller = _comptroller;
        rainMaker = _rainMaker;
    }

    modifier isUsedXToken(address xToken) {
        require(usedXTokens[xToken], "E2");
        _;
    }

    /*** Owner function ***/

    /**
     * @notice Add XToken in Contract and approve token  for storage, venus,
     * pancakeswap/apeswap router, and pancakeswap/apeswap master(Main Staking contract)
     * @param token Address of Token for deposited
     * @param xToken Address of XToken
     */
    function addXTokens(address token, address xToken)
        external
        override
        onlyOwnerAndAdmin
    {
        require(xToken != ZERO_ADDRESS, "E20");
        require(_checkMarkets(xToken), "E5");

        if ((token) != ZERO_ADDRESS) {
            IERC20Upgradeable(token).approve(xToken, type(uint256).max);
            IERC20Upgradeable(token).approve(
                multiLogicProxy,
                type(uint256).max
            );
            approveTokenForSwap(swapGateway, token);

            XTokens[token] = xToken;
        } else {
            xETH = xToken;
        }

        usedXTokens[xToken] = true;
    }

    function isXTokenUsed(address xToken) public view returns (bool) {
        return usedXTokens[xToken];
    }

    /*** LendingSystem function ***/

    /**
     * @notice Get all entered xTokens to comptroller
     */
    function getAllMarkets() external view override returns (address[] memory) {
        return _getAllMarkets();
    }

    /**
     * @notice Enter into a list of markets(address of XTokens) - it is not an
     * error to enter the same market more than once.
     * @param xTokens The addresses of the xToken markets to enter.
     * @return For each market, returns an error code indicating whether or not it was entered.
     * Each is 0 on success, otherwise an Error code
     */
    function enterMarkets(address[] calldata xTokens)
        external
        override
        onlyOwnerAndAdmin
        returns (uint256[] memory)
    {
        return _enterMarkets(xTokens);
    }

    /**
     * @notice Every user accrues rewards for each block
     * Venus : XVS, Ola : BANANA, dForce : DF
     * they are supplying to or borrowing from the protocol.
     */
    function claim() external override onlyOwnerAndAdmin {
        // Get all markets
        address[] memory xTokens = _getAllMarkets();

        // Claim
        _claim(xTokens);
    }

    /**
     * @notice Stake token and mint XToken
     * @param xToken: that mint XTokens to this contract
     * @param mintAmount: The amount of the asset to be supplied, in units of the underlying asset.
     * @return 0 on success, otherwise an Error code
     */
    function mint(address xToken, uint256 mintAmount)
        external
        override
        isUsedXToken(xToken)
        onlyOwnerAndAdmin
        returns (uint256)
    {
        return _mint(xToken, mintAmount);
    }

    /**
     * @notice The borrow function transfers an asset from the protocol to the user and creates a
     * borrow balance which begins accumulating interest based on the Borrow Rate for the asset.
     * The amount borrowed must be less than the user's Account Liquidity and the market's
     * available liquidity.
     * @param xToken: that mint XTokens to this contract
     * @param borrowAmount: The amount of underlying to be borrow.
     * @return 0 on success, otherwise an Error code
     */
    function borrow(address xToken, uint256 borrowAmount)
        external
        override
        isUsedXToken(xToken)
        onlyOwnerAndAdmin
        returns (uint256)
    {
        return _borrow(xToken, borrowAmount);
    }

    /**
     * @notice The repay function transfers an asset into the protocol, reducing the user's borrow balance.
     * @param xToken: that mint XTokens to this contract
     * @param repayAmount: The amount of the underlying borrowed asset to be repaid.
     * A value of -1 (i.e. 2256 - 1) can be used to repay the full amount.
     * @return 0 on success, otherwise an Error code
     */
    function repayBorrow(address xToken, uint256 repayAmount)
        external
        override
        isUsedXToken(xToken)
        onlyOwnerAndAdmin
        returns (uint256)
    {
        return _repayBorrow(xToken, repayAmount);
    }

    /**
     * @notice The redeem underlying function converts xTokens into a specified quantity of the
     * underlying asset, and returns them to the user.
     * The amount of xTokens redeemed is equal to the quantity of underlying tokens received,
     * divided by the current Exchange Rate.
     * The amount redeemed must be less than the user's Account Liquidity and the market's
     * available liquidity.
     * @param xToken: that mint XTokens to this contract
     * @param redeemAmount: The amount of underlying to be redeemed.
     * @return 0 on success, otherwise an Error code
     */
    function redeemUnderlying(address xToken, uint256 redeemAmount)
        external
        virtual
        override
        isUsedXToken(xToken)
        onlyOwnerAndAdmin
        returns (uint256)
    {
        return _redeemUnderlying(xToken, redeemAmount);
    }

    /**
     * @notice The redeem function converts xTokens into a specified quantity of the
     * underlying asset, and returns them to the user.
     * The amount of xTokens redeemed is equal to the quantity of underlying tokens received,
     * divided by the current Exchange Rate.
     * The amount redeemed must be less than the user's xToken baalance.
     * @param xToken: that mint XTokens to this contract
     * @param redeemTokenAmount: The amount of underlying to be redeemed.
     * @return 0 on success, otherwise an Error code
     */
    function redeem(address xToken, uint256 redeemTokenAmount)
        external
        virtual
        override
        isUsedXToken(xToken)
        onlyOwnerAndAdmin
        returns (uint256)
    {
        return _redeem(xToken, redeemTokenAmount);
    }

    /*** Private Virtual Function ***/

    /**
     * @notice Check if xToken is in market
     * for each strategy, this function should be override
     */
    function _checkMarkets(address xToken)
        internal
        view
        virtual
        returns (bool)
    {}

    /**
     * @notice enterMarket with xToken
     */
    function _enterMarkets(address[] calldata xTokens)
        internal
        virtual
        returns (uint256[] memory)
    {
        return IComptrollerCompound(comptroller).enterMarkets(xTokens);
    }

    /**
     * @notice Stake token and mint XToken
     */
    function _mint(address xToken, uint256 mintAmount)
        internal
        virtual
        returns (uint256)
    {
        if (xToken == xETH) {
            IXTokenETH(xToken).mint{value: mintAmount}();
            return 0;
        }

        return IXToken(xToken).mint(mintAmount);
    }

    /**
     * @notice borrow underlying token
     */
    function _borrow(address xToken, uint256 borrowAmount)
        internal
        virtual
        returns (uint256)
    {
        return IXToken(xToken).borrow(borrowAmount);
    }

    /**
     * @notice repayBorrow underlying token
     */
    function _repayBorrow(address xToken, uint256 repayAmount)
        internal
        virtual
        returns (uint256)
    {
        if (xToken == xETH) {
            IXTokenETH(xToken).repayBorrow{value: repayAmount}();
            return 0;
        }

        return IXToken(xToken).repayBorrow(repayAmount);
    }

    /**
     * @notice redeem underlying staked token
     */
    function _redeemUnderlying(address xToken, uint256 redeemAmount)
        internal
        virtual
        returns (uint256)
    {
        return IXToken(xToken).redeemUnderlying(redeemAmount);
    }

    /**
     * @notice redeem underlying staked token
     */
    function _redeem(address xToken, uint256 redeemTokenAmount)
        internal
        virtual
        returns (uint256)
    {
        return IXToken(xToken).redeem(redeemTokenAmount);
    }

    /**
     * @notice Claim strategy rewards token
     * for each strategy, this function should be override
     */
    function _claim(address[] memory xTokens) internal virtual {}

    /**
     * @notice Get all entered xTokens to comptroller
     */
    function _getAllMarkets() internal view virtual returns (address[] memory) {
        return IComptrollerCompound(comptroller).getAllMarkets();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IComptrollerDForce {
    function enterMarkets(address[] calldata iTokens)
        external
        returns (bool[] memory);

    function markets(address iTokenAddress)
        external
        view
        returns (
            uint256 _collateralFactor,
            uint256 _borrowFactor,
            uint256 _borrowCapacity,
            uint256 _supplyCapacity,
            bool mintPaused,
            bool redeemPaused,
            bool borrowPaused
        );

    function getAlliTokens() external view returns (address[] memory);

    function calcAccountEquity(address)
        external
        view
        returns (
            uint256 equity,
            uint256 shortfall,
            uint256 collaterals,
            uint256 borrows
        );

    function priceOracle() external view returns (address);

    function hasiToken(address _iToken) external view returns (bool);

    function rewardDistributor() external view returns (address);
}

interface IDistributionDForce {
    function claimReward(address[] memory _holders, address[] memory _iTokens)
        external;

    function rewardToken() external view returns (address);

    function reward(address _account) external view returns (uint256);

    function distributionBorrowState(address _asset)
        external
        view
        returns (uint256 index, uint256 block);

    function distributionBorrowerIndex(address _asset, address _account)
        external
        view
        returns (uint256);

    function distributionSupplyState(address _asset)
        external
        view
        returns (uint256 index, uint256 block);

    function distributionSupplierIndex(address _asset, address _account)
        external
        view
        returns (uint256);

    function distributionSupplySpeed(address _asset)
        external
        view
        returns (uint256);

    function distributionSpeed(address _asset) external view returns (uint256);
}

interface IiToken {
    function mint(address recipient, uint256 mintAmount) external;

    function borrow(uint256 borrowAmount) external;

    function redeemUnderlying(address from, uint256 redeemAmount) external;

    function redeem(address from, uint256 redeemTokenAmount) external;

    function repayBorrow(uint256 repayAmount) external;

    function borrowBalanceCurrent(address account) external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function underlying() external view returns (address);

    function name() external view returns (string memory);

    function isiToken() external view returns (bool);
}

interface IDForcePriceOracle {
    function priceModel(address _asset) external view returns (address);

    function getUnderlyingPrice(address _asset)
        external
        returns (uint256 _price);
}

interface IDForcePriceModel {
    function getAssetPrice(address _asset) external view returns (uint256);
}

interface IiTokenETH {
    function mint(address recipient) external payable;

    function repayBorrow() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./utils/UpgradeableBase.sol";
import "./interfaces/ISwap.sol";
import "./interfaces/IMultiLogicProxy.sol";
import "./interfaces/ILogicContract.sol";

abstract contract BaseLogic is ILogic, UpgradeableBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address internal constant ZERO_ADDRESS = address(0);
    address public multiLogicProxy;
    address internal blid;
    address public swapGateway;
    address internal expenseAddress;

    event SetBLID(address _blid);
    event SetExpenseAddress(address expenseAddress);
    event SetSwapGateway(address swapGateway);
    event SetMultiLogicProxy(address multiLogicProxy);

    receive() external payable {}

    fallback() external payable {}

    modifier onlyMultiLogicProxy() {
        require(msg.sender == multiLogicProxy, "E14");
        _;
    }

    /*** Owner function ***/

    /**
     * @notice Set expenseAddress
     * @param _expenseAddress Address of Expense Account
     */
    function setExpenseAddress(address _expenseAddress) external onlyOwner {
        require(_expenseAddress != ZERO_ADDRESS, "E20");

        expenseAddress = _expenseAddress;
        emit SetExpenseAddress(_expenseAddress);
    }

    /**
     * @notice Set swapGateway
     * @param _swapGateway Address of SwapGateway
     */
    function setSwapGateway(address _swapGateway) external onlyOwner {
        require(_swapGateway != ZERO_ADDRESS, "E20");

        swapGateway = _swapGateway;
        emit SetSwapGateway(_swapGateway);
    }

    /**
     * @notice Set blid in contract and approve blid for storage, venus, pancakeswap/apeswap/biswap
     * router, and pancakeswap/apeswap/biswap master(Main Staking contract), you can call the
     * function once
     * @param blid_ Address of BLID
     */
    function setBLID(address blid_) external onlyOwner {
        require(blid_ != ZERO_ADDRESS, "E20");

        blid = blid_;
        IERC20Upgradeable(blid).safeApprove(multiLogicProxy, type(uint256).max);
        emit SetBLID(blid_);
    }

    /**
     * @notice Set MultiLogicProxy, you can call the function once
     * @param _multiLogicProxy Address of Storage Contract
     */
    function setMultiLogicProxy(address _multiLogicProxy) external onlyOwner {
        require(_multiLogicProxy != ZERO_ADDRESS, "E20");

        multiLogicProxy = _multiLogicProxy;

        emit SetMultiLogicProxy(_multiLogicProxy);
    }

    /*** Logic function ***/

    /**
     * @notice Transfer amount of token from Storage to Logic contract token - address of the token
     * @param amount Amount of token
     * @param token Address of token
     */
    function takeTokenFromStorage(uint256 amount, address token)
        external
        override
        onlyOwnerAndAdmin
    {
        IMultiLogicProxy(multiLogicProxy).takeToken(amount, token);
        if (token == ZERO_ADDRESS) {
            require(address(this).balance >= amount, "E16");
        }
    }

    /**
     * @notice Transfer amount of token from Logic to Storage contract token - address of token
     * @param amount Amount of token
     * @param token Address of token
     */
    function returnTokenToStorage(uint256 amount, address token)
        external
        override
        onlyOwnerAndAdmin
    {
        if (token == ZERO_ADDRESS) {
            _send(payable(multiLogicProxy), amount);
        }

        IMultiLogicProxy(multiLogicProxy).returnToken(amount, token);
    }

    /**
     * @notice Transfer amount of ETH from Logic to MultiLogicProxy
     * @param amount Amount of ETH
     */
    function returnETHToMultiLogicProxy(uint256 amount)
        external
        override
        onlyOwnerAndAdmin
    {
        _send(payable(multiLogicProxy), amount);
    }

    /**
     * @notice Distribution amount of blid to depositors.
     * @param amount Amount of BLID
     */
    function addEarnToStorage(uint256 amount)
        external
        override
        onlyOwnerAndAdmin
    {
        IERC20Upgradeable(blid).safeTransfer(
            expenseAddress,
            (amount * 3) / 100
        );
        IMultiLogicProxy(multiLogicProxy).addEarn(
            amount - ((amount * 3) / 100),
            blid
        );
    }

    /**
     * @notice Approve swap for token
     * @param _swap Address of swapRouter
     * @param token Address of token
     */
    function approveTokenForSwap(address _swap, address token)
        public
        onlyOwnerAndAdmin
    {
        if (IERC20Upgradeable(token).allowance(address(this), _swap) == 0) {
            IERC20Upgradeable(token).safeApprove(_swap, type(uint256).max);
        }
    }

    /*** Swap function ***/

    /**
     * @notice Swap tokens using swapRouter
     * @param swapRouter Address of swapRouter contract
     * @param amountIn Amount for in
     * @param amountOut Amount for out
     * @param path swap path, path[0] is in, path[last] is out
     * @param isExactInput true : swapExactTokensForTokens, false : swapTokensForExactTokens
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swap(
        address swapRouter,
        uint256 amountIn,
        uint256 amountOut,
        address[] memory path,
        bool isExactInput,
        uint256 deadline
    )
        external
        payable
        override
        onlyOwnerAndAdmin
        returns (uint256[] memory amounts)
    {
        if (path[0] == ZERO_ADDRESS) {
            require(address(this).balance >= amountIn, "E18");

            amounts = ISwapGateway(swapGateway).swap{value: amountIn}(
                swapRouter,
                amountIn,
                amountOut,
                path,
                isExactInput,
                deadline
            );
        } else {
            require(
                IERC20Upgradeable(path[0]).balanceOf(address(this)) >= amountIn,
                "E18"
            );
            require(
                IERC20Upgradeable(path[0]).allowance(
                    address(this),
                    swapGateway
                ) >= amountIn,
                "E19"
            );

            amounts = ISwapGateway(swapGateway).swap(
                swapRouter,
                amountIn,
                amountOut,
                path,
                isExactInput,
                deadline
            );
        }
    }

    /*** Private Function ***/

    /**
     * @notice Send ETH to address
     * @param _to target address to receive ETH
     * @param amount ETH amount (wei) to be sent
     */
    function _send(address payable _to, uint256 amount) private {
        (bool sent, ) = _to.call{value: amount}("");
        require(sent, "E17");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IXToken {
    function mint(uint256 mintAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function redeem(uint256 redeemTokenAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function underlying() external view returns (address);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function borrowIndex() external view returns (uint256);

    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function interestRateModel() external view returns (address);

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function getCash() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalBorrows() external view returns (uint256);
}

interface IXTokenETH {
    function mint() external payable;

    function borrow(uint256 borrowAmount) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function repayBorrow() external payable;

    function borrowBalanceCurrent(address account) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IComptrollerCompound {
    function enterMarkets(address[] calldata xTokens)
        external
        returns (uint256[] memory);

    function getAllMarkets() external view returns (address[] memory);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

interface IInterestRateModel {
    function blocksPerYear() external view returns (uint256);
}

interface IComptrollerOla is IComptrollerCompound {
    function markets(address cTokenAddress)
        external
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getUnderlyingPriceInLen(address underlying)
        external
        view
        returns (uint256);

    function rainMaker() external view returns (address);
}

interface IDistributionOla {
    function claimComp(address holder, address[] calldata cTokens) external;

    function compAccrued(address holder) external view returns (uint256);

    function compInitialIndex() external view returns (uint224);

    function compSupplyState(address xToken)
        external
        view
        returns (uint224, uint32);

    function compSupplierIndex(address xToken, address account)
        external
        view
        returns (uint256);

    function compBorrowState(address xToken)
        external
        view
        returns (uint224, uint32);

    function compBorrowerIndex(address xToken, address account)
        external
        view
        returns (uint256);

    function lnIncentiveTokenAddress() external view returns (address);

    function compSpeeds(address _asset) external view returns (uint256);

    function compSupplySpeeds(address _asset) external view returns (uint256);
}

interface IComptrollerVenus is IComptrollerCompound {
    function markets(address cTokenAddress)
        external
        view
        returns (
            bool,
            uint256,
            bool
        );

    function oracle() external view returns (address);

    function venusInitialIndex() external view returns (uint224);

    function venusAccrued(address account) external view returns (uint256);

    function venusSupplyState(address xToken)
        external
        view
        returns (uint224, uint32);

    function venusSupplierIndex(address xToken, address account)
        external
        view
        returns (uint256);

    function venusBorrowState(address xToken)
        external
        view
        returns (uint224, uint32);

    function venusBorrowerIndex(address xToken, address account)
        external
        view
        returns (uint256);

    function getXVSAddress() external view returns (address);

    function getXVSVTokenAddress() external view returns (address);

    function venusSpeeds(address _asset) external view returns (uint256);

    function venusSupplySpeeds(address _asset) external view returns (uint256);
}

interface IDistributionVenus {
    function claimVenus(address holder, address[] memory vTokens) external;
}

interface IOracleVenus {
    function getUnderlyingPrice(address vToken) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ILogicContract {
    function addXTokens(
        address token,
        address xToken,
        uint8 leadingTokenType
    ) external;

    function approveTokenForSwap(address token) external;

    function claim(address[] calldata xTokens, uint8 leadingTokenType) external;

    function mint(address xToken, uint256 mintAmount)
        external
        returns (uint256);

    function borrow(
        address xToken,
        uint256 borrowAmount,
        uint8 leadingTokenType
    ) external returns (uint256);

    function repayBorrow(address xToken, uint256 repayAmount) external;

    function redeemUnderlying(address xToken, uint256 redeemAmount)
        external
        returns (uint256);

    function swapExactTokensForTokens(
        address swap,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        address swap,
        uint256 amountETH,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        address swap,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        address swap,
        uint256 amountETH,
        uint256 amountOut,
        address[] calldata path,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function addLiquidityETH(
        address swap,
        address token,
        uint256 amountTokenDesired,
        uint256 amountETHDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    )
        external
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidityETH(
        address swap,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH);

    function addEarnToStorage(uint256 amount) external;

    function enterMarkets(address[] calldata xTokens, uint8 leadingTokenType)
        external
        returns (uint256[] memory);

    function returnTokenToStorage(uint256 amount, address token) external;

    function takeTokenFromStorage(uint256 amount, address token) external;

    function returnETHToMultiLogicProxy(uint256 amount) external;

    function deposit(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external;

    function withdraw(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external;

    function returnToken(uint256 amount, address token) external; // for StorageV2 only
}

/************* New Architecture *************/
interface ISwapLogic {
    function swap(
        address swapRouter,
        uint256 amountIn,
        uint256 amountOut,
        address[] memory path,
        bool isExactInput,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

interface ILogic is ISwapLogic {
    function addEarnToStorage(uint256 amount) external;

    function returnTokenToStorage(uint256 amount, address token) external;

    function takeTokenFromStorage(uint256 amount, address token) external;

    function returnETHToMultiLogicProxy(uint256 amount) external;

    function multiLogicProxy() external view returns (address);

    function approveTokenForSwap(address _swap, address token) external;
}

interface ILendingLogic is ILogic {
    function isXTokenUsed(address xToken) external view returns (bool);

    function addXTokens(address token, address xToken) external;

    function comptroller() external view returns (address);

    function getAllMarkets() external view returns (address[] memory);

    function enterMarkets(address[] calldata xTokens)
        external
        returns (uint256[] memory);

    function claim() external;

    function mint(address xToken, uint256 mintAmount)
        external
        returns (uint256);

    function borrow(address xToken, uint256 borrowAmount)
        external
        returns (uint256);

    function repayBorrow(address xToken, uint256 repayAmount)
        external
        returns (uint256);

    function redeemUnderlying(address xToken, uint256 redeemAmount)
        external
        returns (uint256);

    function redeem(address xToken, uint256 redeemTokenAmount)
        external
        returns (uint256);
}

interface IFarmingLogic is ILogic {
    function addLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address swap,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function farmingDeposit(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external;

    function farmingWithdraw(
        address swapMaster,
        uint256 _pid,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IPancakePair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        );
}

interface IPancakeRouter01 {
    function WETH() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

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
}

interface IMasterChef {
    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accCakePerShare
        );

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function userInfo(uint256 _pid, address account)
        external
        view
        returns (uint256, uint256);
}

interface IMasterChefPancakeswap is IMasterChef {
    function pendingCake(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function CAKE() external view returns (address);
}

interface IMasterChefApeswap is IMasterChef {
    function pendingCake(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function cake() external view returns (address);
}

interface IMasterChefBiswap is IMasterChef {
    function pendingBSW(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function BSW() external view returns (address);
}

interface ISwapGateway {
    function swap(
        address swapRouter,
        uint256 amountIn,
        uint256 amountOut,
        address[] memory path,
        bool isExactInput,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quoteExactInput(
        address swapRouter,
        uint256 amountIn,
        address[] memory path
    ) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./OwnableUpgradeableVersionable.sol";
import "./OwnableUpgradeableAdminable.sol";

abstract contract UpgradeableBase is
    Initializable,
    OwnableUpgradeableVersionable,
    OwnableUpgradeableAdminable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    function initialize() public onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IMultiLogicProxy {
    function releaseToken(uint256 amount, address token) external;

    function takeToken(uint256 amount, address token) external;

    function addEarn(uint256 amount, address blidToken) external;

    function returnToken(uint256 amount, address token) external;

    function setLogicTokenAvailable(
        uint256 amount,
        address token,
        uint256 deposit_withdraw
    ) external;

    function getTokenAvailable(address _token, address _logicAddress)
        external
        view
        returns (uint256);

    function getTokenTaken(address _token, address _logicAddress)
        external
        view
        returns (uint256);

    function getUsedTokensStorage() external view returns (address[] memory);

    function multiStrategyLength() external view returns (uint256);

    function multiStrategyName(uint256) external view returns (string memory);

    function strategyInfo(string memory)
        external
        view
        returns (address, address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract OwnableUpgradeableVersionable is OwnableUpgradeable {
    string private _version;
    string private _purpose;

    event UpgradeVersion(string version, string purpose);

    function getVersion() external view returns (string memory) {
        return _version;
    }

    function getPurpose() external view returns (string memory) {
        return _purpose;
    }

    /**
     * @notice Set version and purpose
     * @param version Version string, ex : 1.2.0
     * @param purpose Purpose string
     */
    function upgradeVersion(string memory version, string memory purpose)
        external
        onlyOwner
    {
        require(bytes(version).length != 0, "OV1");

        _version = version;
        _purpose = purpose;

        emit UpgradeVersion(version, purpose);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract OwnableUpgradeableAdminable is OwnableUpgradeable {
    address private _admin;

    event SetAdmin(address admin);

    modifier onlyAdmin() {
        require(msg.sender == _admin, "OA1");
        _;
    }

    modifier onlyOwnerAndAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "OA2");
        _;
    }

    /**
     * @notice Set admin
     * @param newAdmin Addres of new admin
     */
    function setAdmin(address newAdmin) external onlyOwner {
        _admin = newAdmin;
        emit SetAdmin(newAdmin);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

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
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
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
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.3) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.9._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
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