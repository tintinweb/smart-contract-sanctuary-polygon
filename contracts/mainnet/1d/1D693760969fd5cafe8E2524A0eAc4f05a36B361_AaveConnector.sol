// SPDX-License-Identifier: unlicensed
pragma solidity >=0.7.0 <0.9.0;

import {IAaveProtocolDataProvider,IAaveLendingPool, IAaveLendingPoolAddressesProvider} from "interfaces.sol";
import { Adaptor} from "Adaptor.sol";
import { Registry } from "Registry.sol";
import {IERC20Minimal} from "IERC20Minimal.sol";

contract AaveConnector is Adaptor, Registry {

    address constant internal maticAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant internal wmaticAddr = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    constructor(){}

    function getGrossDebt(address asset,address _target) public override view returns (uint grossDebt) {
        // (address aToken, address aStableDebt, address aVariableDebt) = aaveProvider.getReserveTokensAddresses(asset);
        (uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled) = aaveProvider.getUserReserveData(asset, _target);
        return currentVariableDebt;
    }

    function getGrossValue(address asset, address _target) public override view returns (uint grossValue) {
        // (address aToken, address aStableDebt, address aVariableDebt) = aaveProvider.getReserveTokensAddresses(asset);
        (uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled) = aaveProvider.getUserReserveData(asset, _target);
        return currentATokenBalance;
    }


    /**
     * @dev Deposit ETH/ERC20_Token.
     * @notice Deposit a token to Aave v2 for lending / collaterization.
     * @param token The address of the token to deposit.(For MATIC: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
    */
    function deposit(
        address token,
        uint256 amt
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {

        IAaveLendingPool aave = IAaveLendingPool(aaveAddressProvider.getLendingPool());
        bool isEth = token == maticAddr;
        address _token = isEth ? wmaticAddr : token;

        IERC20Minimal tokenContract = IERC20Minimal(_token);

        approve(tokenContract, address(aave), amt);

        aave.deposit(_token, amt, msg.sender, 0); //referral code here is 0

        _eventName = "LogDeposit(address,uint256)";
        _eventParam = abi.encode(token, amt);
    }

    /**
     * @dev Borrow ETH/ERC20_Token.
     * @notice Borrow a token using Aave v2
     * @param token The address of the token to borrow.(For MATIC: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt The amount of the token to borrow.
     * @param rateMode The type of borrow debt. (For Stable: 1, Variable: 2)
    */
    function borrow(
        address token,
        uint256 amt,
        uint256 rateMode
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {

        IAaveLendingPool aave = IAaveLendingPool(aaveAddressProvider.getLendingPool());
       
        bool isEth = token == maticAddr;
        address _token = isEth ? wmaticAddr : token;

        aave.borrow(_token, amt, rateMode, 0, msg.sender);
        IERC20Minimal tokenContract = IERC20Minimal(_token);
        approve(tokenContract, msg.sender, amt);
        tokenContract.transfer(msg.sender,amt);


        _eventName = "LogBorrow(address,uint256,uint256)";
        _eventParam = abi.encode(token, amt, rateMode);
    }

    function approve(IERC20Minimal token, address spender, uint256 amount) internal {
        try token.approve(spender, amount) {

        } catch {
            token.approve(spender, 0);
            token.approve(spender, amount);
        }
    }

}

// SPDX-License-Identifier: unlicensed
pragma solidity >=0.7.0 <0.9.0;

interface IAaveLendingPool {

    /**
    * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
    * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
    * @param asset The address of the underlying asset to deposit
    * @param amount The amount to be deposited
    * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
    *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
    *   is a different wallet
    * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    *   0 if the action is executed directly by the user, without any middle-man
    **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
    * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
    * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
    * @param asset The address of the underlying asset to withdraw
    * @param amount The underlying amount to be withdrawn
    *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
    * @param to Address that will receive the underlying, same as msg.sender if the user
    *   wants to receive it on his own wallet, or a different address if the beneficiary is a
    *   different wallet
    * @return The final amount withdrawn
    **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);


    /**
    * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
    * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
    * corresponding debt token (StableDebtToken or VariableDebtToken)
    * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
    *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
    * @param asset The address of the underlying asset to borrow
    * @param amount The amount to be borrowed
    * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
    * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    *   0 if the action is executed directly by the user, without any middle-man
    * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
    * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
    * if he has been given credit delegation allowance
    **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
    * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
    * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
    * @param asset The address of the borrowed underlying asset previously borrowed
    * @param amount The amount to repay
    * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
    * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
    * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
    * user calling the function if he wants to reduce/remove his own debt, or the address of any other
    * other borrower whose debt should be removed
    * @return The final amount repaid
    **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
    * @dev Returns the user account data across all the reserves
    * @param user The address of the user
    * @return totalCollateralETH the total collateral in ETH of the user
    * @return totalDebtETH the total debt in ETH of the user
    * @return availableBorrowsETH the borrowing power left of the user
    * @return currentLiquidationThreshold the liquidation threshold of the user
    * @return ltv the loan to value of the user
    * @return healthFactor the current health factor of the user
    **/
    function getUserAccountData(address user)
        external
        view
        returns (
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor);

}

interface IAaveProtocolDataProvider {
    struct TokenData {
        string symbol;
        address tokenAddress;
    }

    struct UserReserveData {
        uint256 currentATokenBalance;
        uint256 currentStableDebt;
        uint256 currentVariableDebt;
        uint256 principalStableDebt;
        uint256 scaledVariableDebt;
        uint256 stableBorrowRate;
        uint256 liquidityRate;
        uint40 stableRateLastUpdated;
        bool usageAsCollateralEnabled;
     }

  function ADDRESSES_PROVIDER() external view returns (IAaveLendingPoolAddressesProvider);
  function getAllReservesTokens() external view returns (TokenData[] memory);
  function getAllATokens() external view returns (TokenData[] memory);
  function getReserveConfigurationData(address asset) external view returns (uint256 decimals, uint256 ltv, uint256 liquidationThreshold, uint256 liquidationBonus, uint256 reserveFactor, bool usageAsCollateralEnabled, bool borrowingEnabled, bool stableBorrowRateEnabled, bool isActive, bool isFrozen);
  function getReserveData(address asset) external view returns (uint256 availableLiquidity, uint256 totalStableDebt, uint256 totalVariableDebt, uint256 liquidityRate, uint256 variableBorrowRate, uint256 stableBorrowRate, uint256 averageStableBorrowRate, uint256 liquidityIndex, uint256 variableBorrowIndex, uint40 lastUpdateTimestamp);
  function getUserReserveData(address asset, address user) external view returns (uint256 currentATokenBalance, uint256 currentStableDebt, uint256 currentVariableDebt, uint256 principalStableDebt, uint256 scaledVariableDebt, uint256 stableBorrowRate, uint256 liquidityRate, uint40 stableRateLastUpdated, bool usageAsCollateralEnabled);
  function getReserveTokensAddresses(address asset) external view returns (address aTokenAddress, address stableDebtTokenAddress, address variableDebtTokenAddress);
}

interface IAaveLendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: unlicensed
pragma solidity >=0.7.0 <0.9.0;

abstract contract Adaptor {

    function getNetAssetValue(address asset, address _target) external view returns (uint256) {
        return getGrossValue(asset, _target) - getGrossDebt(asset,_target);
    }

    function getGrossValue(address asset, address _target) public virtual view returns (uint grossValue);

    function getGrossDebt(address asset, address _target) public virtual view returns (uint grossDebt);

}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {IAaveProtocolDataProvider} from "interfaces.sol";
import {IAaveLendingPoolAddressesProvider} from "interfaces.sol";

contract Registry {
    // Aave Lending Pool Provider
    IAaveProtocolDataProvider constant internal aaveProvider = IAaveProtocolDataProvider(0x7551b5D2763519d4e37e8B81929D336De671d46d);
    IAaveLendingPoolAddressesProvider constant internal aaveAddressProvider = IAaveLendingPoolAddressesProvider(0xd05e3E715d945B59290df0ae8eF85c1BdB684744);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}