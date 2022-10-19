/**
 *Submitted for verification at polygonscan.com on 2022-10-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

abstract contract Owned {
    
    event SetOwner(address indexed user, address indexed newOwner);

    address public owner;

    error Unauthorised();

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorised();
        _;
    }

    constructor(address _owner) {
        owner = _owner;
        emit SetOwner(address(0), _owner);
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
        emit SetOwner(msg.sender, newOwner);
    }
}

abstract contract Authorised is Owned {
    
    event SetAuthorised(address indexed user, bool isAuthorised);

    mapping(address => bool) public authorised;

    modifier onlyAuthorised() {
        if (!authorised[msg.sender]) revert Unauthorised();
        _;
    }

    constructor(address _owner) Owned(_owner) {
        authorised[_owner] = true;
        emit SetAuthorised(_owner, true);
    }

    function setAuthorised(address user, bool _authorised) public onlyOwner {
        authorised[user] = _authorised;
        emit SetAuthorised(user, _authorised);
    }
}

contract Base is Authorised {

    using SafeTransferLib for ERC20;

    ERC20 internal constant usdc = ERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    ERC20 internal constant weth = ERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);

    constructor() Authorised(msg.sender) {}

    function balances() public view returns (uint256 amountUSDC, uint256 amountWETH) {
        amountUSDC = usdc.balanceOf(address(this));
        amountWETH = weth.balanceOf(address(this));
    }

    function transferOut(ERC20 asset, address to, uint256 amount) external onlyOwner() {
        asset.transfer(to, amount);
    }

    function execute(address target, uint256 val, bytes memory data) external onlyOwner returns (bool ok, bytes memory res) {
        (ok, res) = target.call{value: val}(data);
        require(ok, "failed");
    }

}

library DataTypes {
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

//import {ILendingPoolAddressesProvider} from './ILendingPoolAddressesProvider.sol';

interface ILendingPool {
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
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

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
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;
  function getReservesList() external view returns (address[] memory);
  function getAddressesProvider() external view returns (address);
  function setPause(bool val) external;
  function paused() external view returns (bool);
}

contract AaveActions is Base {

    using SafeTransferLib for ERC20;
    ILendingPool internal constant lendingPool = ILendingPool(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);
    ERC20 internal variableDebtTokenAddress = ERC20(0xeDe17e9d79fc6f9fF9250D9EEfbdB88Cc18038b5); // WETH debt
    ERC20 internal aUSDC = ERC20(0x1a13F4Ca1d028320A707D99520AbFefca3998b7F);
    uint256 public targetHealthFactor = 115 * 1e16;
    uint256 public allowOverHealthFactor = 25e15; // 2.5%
    uint256 public allowUnderHealthFactor = 25e15;

    function getAaveData() public view returns (
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    ) {
        return lendingPool.getUserAccountData(address(this));
    }

    function healthFactorStatus() public view returns (bool needsRebalancing, uint256 factor, uint256 ethAmount) {
        (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,,
            uint256 currentLiquidationThreshold,,
            uint256 healthFactor
        ) = getAaveData();
        factor = healthFactor;
        needsRebalancing = factor > targetHealthFactor + allowOverHealthFactor || factor < targetHealthFactor - allowUnderHealthFactor; // ± 5%
        uint256 a = 1e18 * totalCollateralETH * currentLiquidationThreshold / 1e4;
        uint256 b = targetHealthFactor * totalDebtETH;
        if (factor > targetHealthFactor) {
            if (a > b) ethAmount = (a - b) / targetHealthFactor;
        } else {
            if (b > a) ethAmount = (b - a) / targetHealthFactor;
        }
    }

    function availableToBorrow() public view returns (uint256 canBorrow) {
        (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,,
            uint256 currentLiquidationThreshold,,
        ) = getAaveData();
        uint256 effectiveCollateral = totalCollateralETH * currentLiquidationThreshold / 1e4;
        uint256 effectiveBorrows = totalDebtETH * targetHealthFactor / 1e18;
        if (effectiveBorrows > effectiveCollateral) return 0;
        canBorrow = 1e18 * (effectiveCollateral - effectiveBorrows) / targetHealthFactor;
    }

    function targetCollateralisationRatio() public view returns (uint256) { // todo test
        (,,, uint256 currentLiquidationThreshold,,) = getAaveData();
        currentLiquidationThreshold = currentLiquidationThreshold == 0 ? 8500 : currentLiquidationThreshold;
        return targetHealthFactor * 1e4 / 8500;
    }

    function wethDebt() public view returns (uint256) {
        return variableDebtTokenAddress.balanceOf(address(this));
    }

    function aUsdcBalance() public view returns (uint256) {
        return aUSDC.balanceOf(address(this));
    }

    function setHealthFactorParameters(uint256 target, uint256 over, uint256 under) external onlyAuthorised {
        targetHealthFactor = target;
        allowOverHealthFactor = over;
        allowUnderHealthFactor = under;
    }

    function _depositAvailable(ERC20 asset) internal returns (uint256) {
        uint256 amount = asset.balanceOf(address(this));
        if (amount > 0) _deposit(asset, amount);
        return amount;
    }

    function _sendMaxToAave() internal returns (uint256 amount0, uint256 amount1) {
        amount0 = _depositAvailable(usdc);
        amount1 = _repayMaximum(weth);
    }

    function _repayAvailable(ERC20 asset) internal returns (uint256) {
        uint256 amount = asset.balanceOf(address(this));
        if (amount > 0) _repay(asset, amount);
        return amount;
    }

    function _repayMaximum(ERC20 asset) internal returns (uint256) {
        uint256 debt = variableDebtTokenAddress.balanceOf(address(this));
        uint256 available = asset.balanceOf(address(this));
        if (available > debt) available = debt;
        if (available > 0) _repay(asset, available);
        return available;
    }

    function _withdrawMaximumUSDC() internal returns (uint256 amount) {
        amount = aUsdcBalance();
        _withdraw(usdc, amount);
    }

    function _withdraw(ERC20 asset, uint256 amount) internal {
        lendingPool.withdraw(address(asset), amount, address(this));
    }

    function _deposit(ERC20 asset, uint256 amount) internal {
        asset.safeApprove(address(lendingPool), amount);
        lendingPool.deposit(address(asset), amount, address(this), 0);
    }

    function _borrow(ERC20 asset, uint256 amount) internal {
        lendingPool.borrow(address(asset), amount, 2, 0, address(this));
    }

    function _repay(ERC20 asset, uint256 amount) internal {
        asset.safeApprove(address(lendingPool), amount);
        lendingPool.repay(address(asset), amount, 2, address(this));
    }

}

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3Pool {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );
}

interface IUniswapV2Pool {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!

interface IMiniChef {

    function SUSHI() external view returns (address);

    function add(
        uint256 allocPoint,
        address _lpToken,
        address _rewarder
    ) external;

    function batch(bytes[] memory calls, bool revertOnFail)
        external
        payable
        returns (bool[] memory successes, bytes[] memory results);

    function claimOwnership() external;

    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function emergencyWithdraw(uint256 pid, address to) external;

    function harvest(uint256 pid, address to) external;

    function lpToken(uint256) external view returns (address);

    function massUpdatePools(uint256[] memory pids) external;

    function migrate(uint256 _pid) external;

    function migrator() external view returns (address);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256 pending);

    function permitToken(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function poolInfo(uint256)
        external
        view
        returns (
            uint128 accSushiPerShare,
            uint64 lastRewardTime,
            uint64 allocPoint
        );

    function poolLength() external view returns (uint256 pools);

    function rewarder(uint256) external view returns (address);

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        address _rewarder,
        bool overwrite
    ) external;

    function setMigrator(address _migrator) external;

    function setSushiPerSecond(uint256 _sushiPerSecond) external;

    function sushiPerSecond() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function updatePool(uint256 pid)
        external
        returns (MiniChefV2.PoolInfo memory pool);

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, int256 rewardDebt);

    function withdraw(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function withdrawAndHarvest(
        uint256 pid,
        uint256 amount,
        address to
    ) external;
}

interface MiniChefV2 {
    struct PoolInfo {
        uint128 accSushiPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }
}

library FullMath {

    /// @notice Contains 512-bit math functions
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            // https://ethereum.stackexchange.com/questions/96642/unary-operator-minus-cannot-be-applied-to-type-uint256
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;

            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
        }
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            result++;
        }
    }

}

/// @notice Math library for computing sqrt price for ticks of size 1.0001, i.e., sqrt(1.0001^tick) as fixed point Q64.96 numbers - supports
/// prices between 2**-128 and 2**128 - 1.
/// @author Adapted from https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/TickMath.sol.
library UniV3Math {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128.
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128 - 1.
    int24 internal constant MAX_TICK = -MIN_TICK;
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick - equivalent to getSqrtRatioAtTick(MIN_TICK).
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick - equivalent to getSqrtRatioAtTick(MAX_TICK).
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    error TickOutOfBounds();
    error PriceOutOfBounds();

    /// @notice Calculates sqrt(1.0001^tick) * 2^96.
    /// @dev Throws if |tick| > max tick.
    /// @param tick The input tick for the above formula.
    /// @return sqrtPriceX96 Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick.
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        if (absTick > uint256(uint24(MAX_TICK))) revert TickOutOfBounds();
        unchecked {
            uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;
            // This divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // We then downcast because we know the result always fits within 160 bits due to our tick input constraint.
            // We round up in the division so getTickAtSqrtRatio of the output price is always consistent.
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    function validatePrice(uint160 price) internal pure {
        if (price < MIN_SQRT_RATIO || price >= MAX_SQRT_RATIO) revert PriceOutOfBounds();
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio.
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96.
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio.
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // Second inequality must be < because the price can never reach the price at the max tick.
        if (sqrtPriceX96 < MIN_SQRT_RATIO || sqrtPriceX96 >= MAX_SQRT_RATIO) revert PriceOutOfBounds();
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }
        unchecked {
            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number.

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }

    function getFeeGrowthInside(
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128,
        uint256 l_feeGrowthOutside0X128,
        uint256 l_feeGrowthOutside1X128,
        uint256 u_feeGrowthOutside0X128,
        uint256 u_feeGrowthOutside1X128
    ) internal pure returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        uint256 feeGrowthBelow0X128;
        uint256 feeGrowthBelow1X128;
        if (tickCurrent >= tickLower) {
            feeGrowthBelow0X128 = l_feeGrowthOutside0X128;
            feeGrowthBelow1X128 = l_feeGrowthOutside1X128;
        } else {
            feeGrowthBelow0X128 = feeGrowthGlobal0X128 - l_feeGrowthOutside0X128;
            feeGrowthBelow1X128 = feeGrowthGlobal1X128 - l_feeGrowthOutside1X128;
        }
        uint256 feeGrowthAbove0X128;
        uint256 feeGrowthAbove1X128;
        if (tickCurrent < tickUpper) {
            feeGrowthAbove0X128 = u_feeGrowthOutside0X128;
            feeGrowthAbove1X128 = u_feeGrowthOutside1X128;
        } else {
            feeGrowthAbove0X128 = feeGrowthGlobal0X128 - u_feeGrowthOutside0X128;
            feeGrowthAbove1X128 = feeGrowthGlobal1X128 - u_feeGrowthOutside1X128;
        }

        feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
        feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
    }

    function getPendingFees(
        uint128 liquidity,
        uint256 feeGrowthInside0Last,
        uint256 feeGrowthInside1Last,
        uint256 feeGrowthInside0,
        uint256 feeGrowthInside1
    ) pure internal returns (uint256 amount0, uint256 amount1) {
        amount0 = FullMath.mulDiv(feeGrowthInside0 - feeGrowthInside0Last, liquidity, 0x100000000000000000000000000000000);
        amount1 = FullMath.mulDiv(feeGrowthInside1 - feeGrowthInside1Last, liquidity, 0x100000000000000000000000000000000);
    }
}

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

library PositionKey {
    /// @dev Returns the key of the position in the core library
    function compute(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
    }
}

contract UniswapActions is Base {

    using SafeTransferLib for ERC20;

    IUniswapV3Pool public constant pool = IUniswapV3Pool(0x45dDa9cb7c25131DF268515131f647d726f50608); // Polygon 5bp weth usdc pool.
    IUniswapV2Pool public constant v2pool = IUniswapV2Pool(0x34965ba0ac2451A34a0471F04CCa3F990b8dea27); // Polygon Sushiswap weth usdc pool
    IMiniChef public minichef = IMiniChef(0x0769fd68dFb93167989C6f7254cd0D766Fb2841F);
    int24 internal constant tickSpacing = 10;
    uint24 public buffer = 500; // 5%
    int24 public distanceLower = 5000;
    int24 public distanceUpper = 5000;
    int24 public tickLower = 200_000;
    int24 public tickUpper = 210_000;
    uint32 public movingAverageDuration = 43200;

    function getNearestTick() public view returns (int24 nearestTick) {
        (,nearestTick,,,,,) = pool.slot0();
    }

    // With 4 decimals
    function getEthPrice() public view returns (uint256) {
        (uint256 sqrtPriceX96,,,,,,) = pool.slot0();
        return 1e22 / (((sqrtPriceX96 / 2 ** 64) ** 2) * 1e6 / 2 ** 64);
    }

    function getUnclaimedFees() public view returns (uint256, uint256) {
        return getUnclaimedFees(address(this), tickLower, tickUpper);
    }

    function getUnclaimedFees(address owner, int24 lowerTick, int24 upperTick) public view returns (uint256, uint256) {
        (
            uint128 liquidity,
            uint256 feeGrowthInside0Last,
            uint256 feeGrowthInside1Last,,
        ) = pool.positions(PositionKey.compute(owner, lowerTick, upperTick));
        (,int24 currentTick,,,,,) = pool.slot0();
        (,, uint256 l_feeGrowthOutside0, uint256 l_feeGrowthOutside1,,,,) = pool.ticks(lowerTick);
        (,, uint256 u_feeGrowthOutside0, uint256 u_feeGrowthOutside1,,,,) = pool.ticks(tickUpper);
        (uint256 feeGrowthInside0, uint256 feeGrowthInside1) = UniV3Math.getFeeGrowthInside(
            lowerTick,
            upperTick,
            currentTick,
            pool.feeGrowthGlobal0X128(),
            pool.feeGrowthGlobal1X128(),
            l_feeGrowthOutside0,
            l_feeGrowthOutside1,
            u_feeGrowthOutside0,
            u_feeGrowthOutside1);
        return UniV3Math.getPendingFees(
            liquidity,
            feeGrowthInside0Last,
            feeGrowthInside1Last,
            feeGrowthInside0,
            feeGrowthInside1
        );
    }

    function getLiquidity() public view returns (uint128 liquidity) {
        (liquidity,,,,) = pool.positions(PositionKey.compute(address(this), tickLower, tickUpper));
    }

    function getIdealRange() public view returns (int24 lower, int24 upper) {
        int24 currentTick = getAveragePriceTick();
        currentTick = currentTick - (currentTick % tickSpacing);
        lower = currentTick - distanceLower;
        upper = currentTick + distanceUpper;
    }

    function getAveragePriceTick() public view returns (int24 tick) {
        uint32[] memory secondsAgo = new uint32[](2);
        secondsAgo[0] = 0;
        secondsAgo[1] = movingAverageDuration;
        (int56[] memory tickCumulatives, ) = pool.observe(secondsAgo);
        tick = int24((tickCumulatives[0] - tickCumulatives[1]) / int56(uint56(movingAverageDuration)));
    }

    function getNextRange() public view returns (bool needsToUpdate, int24 lower, int24 upper) {
        (int24 idealLower, int24 idealUpper) = getIdealRange();
        needsToUpdate = diff(idealLower, tickLower) > buffer || diff(idealUpper, tickUpper) > buffer;
        (lower, upper) = needsToUpdate ? (idealLower, idealUpper) : (tickLower, tickUpper);
    }

    function getAmountIn(uint256 amount0, uint256 amount1) public view returns (bool zeroForOne, uint256 amountIn) {
        uint256 desiredRatio = getRangeRatio();
        (uint256 reserve0, uint256 reserve1,) = v2pool.getReserves();
        zeroForOne = amount1 == 0 || (desiredRatio < amount0 * 1e18 / amount1);
        if (zeroForOne) {
            amountIn = 1e18 * amount0 / (1e18 + desiredRatio * reserve1 / reserve0);
        } else {
            amountIn = 1e18 * amount1 / (1e18 + reserve0 * 1e36 / (reserve1 * desiredRatio));
        }
    }

    function getSimpleQuote(bool zeroForOne, uint256 amountIn) public view returns (uint256 amountOut) {
        (uint256 reserve0, uint256 reserve1,) = v2pool.getReserves();
        if (zeroForOne) {
            amountOut = amountIn * reserve1 / reserve0;
        } else {
            amountOut = amountIn * reserve0 / reserve1;
        }
    }

    // Value ratio of 1.05 (*1e18) meand we have to supply 1.05 eth worth of usdc and 1 eth to the range.
    function getValueRatio() public view returns (uint256) {
        uint256 ratio = getRangeRatio();
        (uint256 reserve0, uint256 reserve1,) = v2pool.getReserves();
        return ratio * reserve1 / reserve0;
    }

    function getRangeRatio() public view returns (uint256) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint160 sqrtRatioAX96 = UniV3Math.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = UniV3Math.getSqrtRatioAtTick(tickUpper);
        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96, 1e18);
        return amount0 * 1e18 / amount1;
    }

    function matchAmountForAmount(bool isZero, uint256 amount) public view returns (uint256 otherAmount) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint160 sqrtRatioAX96 = UniV3Math.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = UniV3Math.getSqrtRatioAtTick(tickUpper);
        if (isZero) {
            uint128 liquidity = LiquidityAmounts.getLiquidityForAmount0(sqrtPriceX96, sqrtRatioBX96, amount);
            otherAmount = LiquidityAmounts.getAmount1ForLiquidity(sqrtRatioAX96, sqrtPriceX96, liquidity);
        } else {
            uint128 liquidity = LiquidityAmounts.getLiquidityForAmount1(sqrtRatioAX96, sqrtPriceX96, amount);
            otherAmount = LiquidityAmounts.getAmount0ForLiquidity(sqrtPriceX96, sqrtRatioBX96, liquidity);
        }
    }

    function assetsInV3() public view returns (uint256 amount0, uint256 amount1) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint160 sqrtRatioAX96 = UniV3Math.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = UniV3Math.getSqrtRatioAtTick(tickUpper);
        uint128 liquidity = getLiquidity();
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96, liquidity);
    }

    function balanceInMiniChef() public view returns (uint256 amount) {
        (amount,) = minichef.userInfo(1, address(this));
    }

    function assetsInV2() public view returns (uint256 amount0, uint256 amount1, uint256 balance) {
        (uint256 reserve0, uint256 reserve1,) = v2pool.getReserves();
        uint256 totalSupply = v2pool.totalSupply();
        balance = v2pool.balanceOf(address(this));
        balance += balanceInMiniChef();
        amount0 += reserve0 * balance / totalSupply;
        amount1 += reserve1 * balance / totalSupply;
    }

    function setMovingAverageDuration(uint32 maDuration) external onlyAuthorised {
        movingAverageDuration = maDuration;
    }

    function setRangeParameters(int24 _distanceLower, int24 _distanceUpper, uint24 _buffer) external onlyAuthorised {
        require(_distanceLower > 0 && _distanceUpper > 0, "gt0");
        require(_distanceLower % tickSpacing == 0, "tick spacing lower");
        require(_distanceUpper % tickSpacing == 0, "tick spacing upper");
        distanceLower = _distanceLower;
        distanceUpper = _distanceUpper;
        buffer = _buffer;
    }

    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata
    ) external {
        require(msg.sender == address(pool), "nok");
        if (amount0Owed > 0) usdc.safeTransfer(address(pool), amount0Owed);
        if (amount1Owed > 0) weth.safeTransfer(address(pool), amount1Owed);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external {
        require(msg.sender == address(pool), "nok");
        if (amount0Delta > 0) usdc.safeTransfer(address(pool), uint256(amount0Delta));
        if (amount1Delta > 0) weth.safeTransfer(address(pool), uint256(amount1Delta));
    }

    function _preventPriceSlippage(int24 requiredTick, uint24 maxDifference) internal view {
        int24 currentTick = getNearestTick();
        require(diff(requiredTick, currentTick) <= maxDifference);
    }

    function _miniChefDeposit() internal returns (uint256 amount) {
        v2pool.balanceOf(address(this));
        if (amount > 0) {
            minichef.deposit(1, amount, address(this));
        }
        minichef.harvest(1, address(this));
    }

    function _miniChefWithdraw(bool emergency, bool harvest) internal returns (uint256 amount) {
        (amount, ) = minichef.userInfo(1, address(this));
        if (emergency) {
            minichef.emergencyWithdraw(1, address(this));
        } else if (harvest) {
            minichef.withdrawAndHarvest(1, amount, address(this));
        } else {
            minichef.withdraw(1, amount, address(this));
        }
    }

    function _addV2Liquidity(uint256 min) internal returns (uint256 minted) {
        (uint256 balance0, uint256 balance1) = _balances();
        return _addV2Liquidity(balance0, balance1, min);
    }

    function _addV2Liquidity(uint256 amount0, uint256 amount1, uint256 min) internal returns (uint256 minted) {
        (uint256 reserve0, uint256 reserve1,) = v2pool.getReserves();
        if (1e18 * amount0 / amount1 > 1e18 * reserve0 / reserve1) {
            amount0 = amount1 * reserve0 / reserve1;
        } else {
            amount1 = amount0 * reserve1 / reserve0;
        }
        usdc.transfer(address(v2pool), amount0);
        weth.transfer(address(v2pool), amount1);
        minted = v2pool.mint(address(this));
        require(minted >= min, "slippage");
    }

    function _removeV2Liquidity(uint256 amount) internal returns (uint256 amount0, uint256 amount1) {
        v2pool.transfer(address(v2pool), amount);
        return v2pool.burn(address(this));
    }

    function _addLiquidity(uint256 amount0Desired, uint256 amount1Desired, uint128 min) internal returns (uint256 amount0, uint256 amount1, uint128 liquidityMinted) {
        liquidityMinted = _getLiquidityForAmounts(tickLower, tickUpper, amount0Desired, amount1Desired);
        if (liquidityMinted > 0) {   
            (amount0, amount1) = pool.mint(address(this), tickLower, tickUpper, liquidityMinted, "");
        }
        require(liquidityMinted >= min, "liq slippage");
    }

    function _removeLiquidity(uint128 amount) internal returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = pool.burn(tickLower, tickUpper, amount);
        pool.collect(address(this), tickLower, tickUpper, type(uint128).max, type(uint128).max);
    }

    function _collectFees() internal returns (uint128 amount0, uint128 amount1) {
        (uint128 liquidity,,,,) = pool.positions(PositionKey.compute(address(this), tickLower, tickUpper));
        if (liquidity > 0) pool.burn(tickLower, tickUpper, 0);
        (amount0, amount1) = pool.collect(address(this), tickLower, tickUpper, type(uint128).max, type(uint128).max);
    }

    function _swap(bool zeroForOne, uint256 amountIn, uint256 minimumAmountOut) internal returns (uint256 amountOut) {
        (int256 a, int256 b) = pool.swap(
            address(this),
            zeroForOne,
            int256(amountIn),
            zeroForOne ? UniV3Math.MIN_SQRT_RATIO + 1 : UniV3Math.MAX_SQRT_RATIO - 1,
            ""
        );
        amountOut = uint256(zeroForOne ? -b : -a);
        require(amountOut >= minimumAmountOut);
    }

    // Should collect fees first.
    function _resetRange() internal returns (uint256 amount0, uint256 amount1, uint128 liquidity) {
        (bool shouldUpdate, int24 nextTickLower, int24 nextTickUpper) = getNextRange();
        if (shouldUpdate) {
            liquidity = getLiquidity();
            if (liquidity > 0) (amount0, amount1) = _removeLiquidity(liquidity);
            (tickLower, tickUpper) = (nextTickLower, nextTickUpper);
        }
    }

    function _addMaxLiquidity(uint128 min) internal returns (uint256 amount0, uint256 amount1, uint128 liquidity) {
        (uint256 balance0, uint256 balance1) = _balances();
        (uint256 _amount0, uint256 _amount1, uint128 _liquidity) = _addLiquidity(balance0, balance1, 0);
        (uint256 __amount0, uint256 __amount1, uint128 __liquidity) = _swapAndAddLiquidity(balance0 - _amount0, balance1 - _amount1);
        amount0 = _amount0 + __amount0;
        amount1 = _amount1 + __amount1;
        liquidity = _liquidity + __liquidity;
        require(liquidity >= min, "slippage");
    }

    // Assumes one of the balances is near 0; use _addMaxLiquidity otherwise.
    function _swapAndAddLiquidity(uint256 balance0, uint256 balance1) internal returns (uint256 amount0, uint256 amount1, uint128 liquidity) {
        (bool zeroForOne, uint256 amountIn) = getAmountIn(balance0, balance1);
        uint256 amountOut = _swap(zeroForOne, amountIn, 0);
        if (zeroForOne) {
            return _addLiquidity(balance0 - amountIn, balance1 + amountOut, 0);
        } else {
            return _addLiquidity(balance0 + amountOut, balance1 - amountIn, 0);
        }
    }

    function _getLiquidityAndAmounts(int24 a, int24 b, uint256 max0, uint256 max1) internal view returns (uint256 amount0, uint256 amount1, uint128 liq) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint160 sqrtRatioAX96 = UniV3Math.getSqrtRatioAtTick(a);
        uint160 sqrtRatioBX96 = UniV3Math.getSqrtRatioAtTick(b);
        liq = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            max0,
            max1
        );
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96, liq);
    }

    function getLiquidityForAmount0(uint256 amount) public view returns (uint128 liquidity) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint160 sqrtRatioBX96 = UniV3Math.getSqrtRatioAtTick(tickUpper);
        liquidity = LiquidityAmounts.getLiquidityForAmount0(sqrtPriceX96, sqrtRatioBX96, amount);
    }

    function getLiquidityForAmount1(uint256 amount) public view returns (uint128 liquidity) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint160 sqrtRatioAX96 = UniV3Math.getSqrtRatioAtTick(tickLower);
        liquidity = LiquidityAmounts.getLiquidityForAmount1(sqrtRatioAX96, sqrtPriceX96, amount);
    }

    function _getLiquidityForAmounts(int24 a, int24 b, uint256 amount0, uint256 amount1) internal view returns(uint128 liquidity) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint160 sqrtRatioAX96 = UniV3Math.getSqrtRatioAtTick(a);
        uint160 sqrtRatioBX96 = UniV3Math.getSqrtRatioAtTick(b);
        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            amount0,
            amount1
        );
    }

    function _getAmountsForLiquidity(int24 a, int24 b, uint128 liquidity) internal view returns(uint256 amount0, uint256 amount1) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint160 sqrtRatioAX96 = UniV3Math.getSqrtRatioAtTick(a);
        uint160 sqrtRatioBX96 = UniV3Math.getSqrtRatioAtTick(b);
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96, liquidity);
    }

    function _balances() internal view returns (uint256 balance0, uint256 balance1) {
        balance0 = usdc.balanceOf(address(this));
        balance1 = weth.balanceOf(address(this));
    }

    function diff(int24 a, int24 b) internal pure returns (uint24) {
        if (a < b) return diff(b, a);
        if (a > 0 && b < 0) return uint24(a) + uint24(-b);
        return uint24(a - b);
    }

}

contract AaveUniStrategy is UniswapActions, AaveActions {

    using SafeTransferLib for ERC20;

    uint256 public totalDeposited;
    uint256 public targetHedgeFactor = 1e18 - 5e15; // 99.5%
    uint256 public allowOverHedge = 1e16; // 1e16/1e18 ~ 1% We are long.
    uint256 public allowUnderHedge = 1e16; // 1e16/1e18 ~ 1% We are short.

    function getVirtualPrice() external view returns (uint256 virtualPrice) {
        virtualPrice = 1e18 * getTotalValue() / totalDeposited;
    }

    function getTotalValue() public view returns (uint256 usdValue) {
        uint256 ethPrice = getEthPrice();
        (uint256 amount0, uint256 amount1,) = assetsInV2();
        usdValue += amount0 + amount1 * ethPrice / 1e16; // uni v2
        (amount0, amount1) = balances();
        usdValue += amount0 + amount1 * ethPrice / 1e16; // balances
        (amount0, amount1) = assetsInV3(); // lp value
        usdValue += amount0 + amount1 * ethPrice / 1e16;
        (amount0, amount1) = getUnclaimedFees(); // unclaimed fees
        usdValue += amount0 + amount1 * ethPrice / 1e16;
        usdValue += aUsdcBalance();
        usdValue -= wethDebt() * ethPrice / 1e16;
    }

    // not accounting accrued fees.
    function getTotalWETH() public view returns (uint256) {
        (, uint256 lp) = assetsInV3();
        (, uint256 inactive) = balances();
        return lp + inactive;
    }

    function hedgeStatus() public view returns (bool needsRebalancing, uint256 factor, uint256 ethAmount) {
        uint256 available = getTotalWETH();
        uint256 debt = wethDebt();
        if (debt == 0) debt++;
        if (available == 0) available++;
        factor = 1e18 * available / debt;
        needsRebalancing = factor > targetHedgeFactor + allowOverHedge || factor < targetHedgeFactor - allowUnderHedge; // ± 1%
        uint256 adjustedDebt = debt * targetHedgeFactor / 1e18;
        ethAmount = available > adjustedDebt ? available - adjustedDebt : adjustedDebt - available;
    }

    function setHedgeParameters(uint256 target, uint256 over, uint256 under) external onlyAuthorised {
        targetHedgeFactor = target;
        allowOverHedge = over;
        allowUnderHedge = under;
    }

    function deploy(uint256 usdcAmount, uint128 minLiquidityAddeed) external onlyAuthorised returns (uint256 amount0, uint256 amount1, uint128 liquidityAdded) {
        usdc.safeTransferFrom(msg.sender, address(this), usdcAmount);
        totalDeposited += usdcAmount;
        uint256 ratio = getValueRatio(); // ratio > 1e18 means we have to supply more usdc to univ3 than eth
        uint256 collateralisationRatio = targetCollateralisationRatio();
        uint256 collateralAmount = 1e18 * usdcAmount / (1e18 + 1e18 * ratio / collateralisationRatio);
        _deposit(usdc, collateralAmount);
        usdcAmount -= collateralAmount;
        uint256 wethAmount = matchAmountForAmount(true, usdcAmount);
        _borrow(weth, wethAmount);
        (amount0, amount1, liquidityAdded) = _addLiquidity(usdcAmount, wethAmount, minLiquidityAddeed);
    }

    function exit(uint256 usdcAmount) external onlyAuthorised {
        uint128 liquidity = getLiquidityForAmount0(usdcAmount / 2);
        _removeLiquidity(liquidity);
        _sendMaxToAave();
        _withdraw(usdc, usdcAmount);
    }

    function compound(uint256 minimumLiquidityAdded, bool sendRemainingToAave) external onlyAuthorised returns (uint256 liquidityAdded) {
        _collectFees();
        liquidityAdded = _addV2Liquidity(minimumLiquidityAdded);
        _miniChefDeposit();
        if (sendRemainingToAave) _sendMaxToAave();
    }

    function maintainHedge(int24 priceTick, uint24 maxDifference) external onlyAuthorised returns (int256 liquidityChange, int256 collateralChange, int256 debtChange) {
        _preventPriceSlippage(priceTick, maxDifference);
        (bool fixHedge, uint256 hedgeFactor, uint256 amount) = hedgeStatus();
        if (!fixHedge) return (0, 0, 0);
        (, uint256 healthFactor,) = healthFactorStatus();
        uint256 valueRatio = getValueRatio();

        if (hedgeFactor > targetHedgeFactor && healthFactor > targetHealthFactor) { // borrow weth, sell to usdc, lp

            _borrow(weth, amount);
            uint256 usdcAmount = _swap(false, amount, 0);
            uint256 extraBorrow = matchAmountForAmount(true, usdcAmount);
            _borrow(weth, extraBorrow);
            (,, uint128 liquidity) = _addMaxLiquidity(0);
            return (int256(uint256(liquidity)), 0, -int256(amount));
        
        } else if (hedgeFactor > targetHedgeFactor && healthFactor <= targetHealthFactor) { // remove lp, sell weth, deposit usdc
        
            uint128 liquidity = getLiquidityForAmount1(amount);
            (, uint256 amount1) = _removeLiquidity(liquidity);
            _swap(false, amount1, 0);
            return (-int256(uint256(liquidity)), int256(_depositAvailable(usdc)), 0);
        
        } else if (hedgeFactor < targetHedgeFactor && healthFactor > targetHealthFactor) { // withdraw usdc, buy weth, lp
        
            uint256 usdcAmount = matchAmountForAmount(false, amount);
            usdcAmount = usdcAmount + usdcAmount * 1e18 / valueRatio;
            _withdraw(usdc, usdcAmount);
            (,, uint128 liquidity) = _addMaxLiquidity(0);
            return (int256(uint256(liquidity)), -int256(usdcAmount), 0);
        
        } else if (hedgeFactor < targetHedgeFactor && healthFactor <= targetHealthFactor) { // remove lp, buy weth, repay        

            uint128 liquidity = getLiquidityForAmount1(amount * 1e18 / valueRatio);
            (uint256 amount0,) = _removeLiquidity(liquidity);
            _swap(true, amount0, 0);
            return (-int256(uint256(liquidity)), 0, int256(_repayMaximum(weth)));

        }
    }

    function maintainHealthFactor(int24 priceTick, uint24 maxDifference) external onlyAuthorised returns (int256 liquidityChange, int256 collateralChange, int256 debtChange) {
        _preventPriceSlippage(priceTick, maxDifference);
        (bool fixHealthFactor, uint256 healthFactor, uint256 ethAmount) = healthFactorStatus();
        if (!fixHealthFactor) return (0, 0, 0);
        ethAmount = 1e18 * ethAmount / (1e18 + 8500 * getValueRatio() / 1e4);
        if (healthFactor > targetHealthFactor) {
            _borrow(weth, ethAmount);
            uint256 usdcAmount = matchAmountForAmount(false, ethAmount);
            _withdraw(usdc, usdcAmount);
            (,,uint128 liquidity) = _addMaxLiquidity(0);
            return (int256(uint256(liquidity)), -int256(usdcAmount), -int256(ethAmount));
        } else {
            uint128 liquidity = getLiquidityForAmount1(ethAmount);
            _removeLiquidity(liquidity);
            uint256 ethRepaid = _repayAvailable(weth);
            uint256 usdcDeposited = _depositAvailable(usdc);
            return (-int256(uint256(liquidity)), int256(usdcDeposited), int256(ethRepaid));
        }
    }

    function resetRange(uint128 minLiquidityAdded) external onlyAuthorised returns (uint256 amount0, uint256 amount1, uint128 liquidity) {
        _collectFees();
        (amount0, amount1, liquidity) = _resetRange();
        if (liquidity > 0) {
            (amount0, amount1, liquidity) = _addLiquidity(amount0, amount1, minLiquidityAdded);
            _sendMaxToAave();
        }
    }

    // standalone:
    function depositInMiniChef() external onlyAuthorised {
        _miniChefDeposit();
    }
    function withdrawFromMiniChef(bool emergency, bool harvest) external onlyAuthorised {
        _miniChefWithdraw(emergency, harvest);
    }
    function addLiquidity(uint256 desired0, uint256 desired1, uint128 minimum) external onlyAuthorised returns (uint256 amount0, uint256 amount1, uint128 minted) {
        return _addLiquidity(desired0, desired1, minimum);
    }
    function removeLiquidity(uint128 amount) external onlyAuthorised returns (uint256 amount0, uint256 amount1) {
        return _removeLiquidity(amount);
    }
    function addMaxLiquidity(uint128 min) external onlyAuthorised returns (uint256 amount0, uint256 amount1, uint128 liquidity) {
        return _addMaxLiquidity(min);
    }
    function collectFees() external onlyAuthorised returns (uint256 amount0, uint256 amount1) {
        return _collectFees();
    }
    function depositUSDC(uint256 amount) external onlyAuthorised {
        _deposit(usdc, amount);
    }
    function withdrawUSDC(uint256 amount) external onlyAuthorised {
        _withdraw(usdc, amount);
    }
    function withdrawMaxUSDC() external onlyAuthorised {
        _withdrawMaximumUSDC();
    }
    function borrowWETH(uint256 amount) external onlyAuthorised {
        _borrow(weth, amount);
    }
    function repayWETH(uint256 amount) external onlyAuthorised {
        _repay(weth, amount);
    }
    function depositMaxUSDC() external onlyAuthorised {
        _depositAvailable(usdc);
    }
    function repayMaxWETH() external onlyAuthorised {
        _repayMaximum(weth);
    }
    function swap(bool zeroForOne, uint256 amountIn, uint256 minimumAmountOut) external onlyAuthorised returns (uint256 amountOut) {
        return _swap(zeroForOne, amountIn, minimumAmountOut);
    }
    function addV2Liquidity(uint256 amount0, uint256 amount1, uint256 min) external onlyAuthorised returns (uint256 minted) {
        return _addV2Liquidity(amount0, amount1, min);
    }
    function removeLiquidityV2(uint256 liquidity) external onlyAuthorised returns (uint256 amount0, uint256 amoutn1) {
        return _removeV2Liquidity(liquidity);
    }
}