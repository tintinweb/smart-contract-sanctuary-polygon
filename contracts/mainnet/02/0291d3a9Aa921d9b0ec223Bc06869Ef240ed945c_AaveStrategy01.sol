// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./../RLib/Funding.sol";

import "../LAave/interfaces/ILendingPool.sol";
import "../LAave/interfaces/IAaveProtocolDataProvider.sol";

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
// import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './ISwapStrategy01.sol';
import './IStakedToken.sol';

struct AavePair {
    address basic;
    address am;
    address variableDebtm;
    uint256 ltv;
    uint256 liqvi;
}

contract AaveStrategy01 is Funding {

    using SafeMath for uint256;

    ISwapStrategy01 public SwapStrategy = ISwapStrategy01(0xfdd39D9bDb75F8b4d9f0895B3ddf0Edf8cDe2A9e);
    function set_SwapStrategy(address _contract) public onlyOwner() {        
        SwapStrategy = ISwapStrategy01(_contract);
    }

    // AavePair storage userStaking = userStakingOf[stakingId];
    mapping(string => AavePair) public AavePairOf;

    // ADMIN ONLY
    function _aave_add_coin(
            string memory name,
            address basic,
            address am,
            address variableDebtm,
            uint256 ltv,
            uint256 liqvi
        ) private {
            AavePairOf[name] = AavePair ({
                basic: basic,
                am: am,
                variableDebtm: variableDebtm,
                ltv: ltv,
                liqvi: liqvi
            });
        assets.push(am);
        assets.push(variableDebtm);
    }

    // ETH
    address public AAVE_LENDING_POOL = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf; // PROXY
    address public AAVE_STAKED_TOKEN = 0x357D51124f59836DeD84c8a1730D72B749d8BC23; // MATIC STAKE
    address public AAVE_DATA_PROVIDER = 0x7551b5D2763519d4e37e8B81929D336De671d46d; // AaveProtocolDataProvider

    IAaveProtocolDataProvider AaveDataProvider = IAaveProtocolDataProvider(AAVE_DATA_PROVIDER);

    IERC20 public WMATIC = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    string public AAVE_BASE_COIN;

    /* ADMIN IS UExecutor */
    constructor(string memory _AAVE_BASE_COIN) Admin(0xC6Df4F19D3a5A6c0365D835b00f52c86e0aB392e) {
        AAVE_BASE_COIN = _AAVE_BASE_COIN;       
        _init_aave();
    }

    function _init_aave() private {
        _aave_add_coin(
            "WBTC",
            0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6, // WBTC
            0x5c2ed810328349100A66B82b78a1791B101C9D61, // amWBTC
            0xF664F50631A6f0D72ecdaa0e49b0c019Fa72a8dC, // variableDebtmWBTC
            7000,
            7500
        );
        _aave_add_coin(
            "DAI",
            0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063, // DAI
            0x27F8D03b3a2196956ED754baDc28D73be8830A6e, // amDAI
            0x75c4d1Fb84429023170086f06E682DcbBF537b7d, // variableDebtmDAI
            7500,
            8000
        );
        _aave_add_coin(
            "USDC",
            0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174, // USDC
            0x1a13F4Ca1d028320A707D99520AbFefca3998b7F, // amUSDC
            0x248960A9d75EdFa3de94F7193eae3161Eb349a12, // variableDebtmUSDC
            8000,
            8500
        );
        _aave_add_coin(
            "WETH",
            0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619, // WETH
            0x28424507fefb6f7f8E9D3860F56504E4e5f5f390, // amWETH
            0xeDe17e9d79fc6f9fF9250D9EEfbdB88Cc18038b5, // variableDebtmWETH
            8000,
            8250
        );
    }

    // 
    // BSC + assets
    //
    ILendingPool private AaveLP = ILendingPool(AAVE_LENDING_POOL);
    IStakedToken private StakedToken = IStakedToken(AAVE_STAKED_TOKEN); // MATIC

    // TODO this istemporary ...
    address[] public assets;
    function aave_matic_claim() public onlyOwner() returns (uint256){        
        return aave_matic_claim_to(address(this));
    }
    function aave_matic_claim_to(address to) public onlyOwner() returns (uint256){
        // claim MATIC
        uint256 amount = StakedToken.getRewardsBalance(assets, to);
        StakedToken.claimRewards(assets, amount, to);
        return amount;
    }


    // FUNCTIONS
    function simple_deposit (string memory Coin) public onlyOwner() {
        _aave_deposit(Coin, IERC20(AavePairOf[Coin].basic).balanceOf(address(this)));
    }


    // MAIN
    function _aave_deposit(string memory Coin, uint256 tokenAmt) private {
        AavePair storage AAVE = AavePairOf[Coin];
        IERC20 SToken = IERC20(AAVE.basic);
        require(SToken.balanceOf(address(this)) >= tokenAmt);
        if (SToken.allowance(address(this), AAVE_LENDING_POOL) < tokenAmt) {
            require(SToken.approve(AAVE_LENDING_POOL, type(uint256).max), "approve error");
        }
        // approve
        AaveLP.deposit(AAVE.basic, tokenAmt, address(this), 0);
    }
    function _aave_withdraw(string memory Coin, uint256 tokenAmt) private {
        AavePair storage AAVE = AavePairOf[Coin];
        AaveLP.withdraw(AAVE.basic, tokenAmt, address(this));        
    }

    function _aave_borrow(string memory Coin, uint256 tokenAmt) private {
        AavePair storage AAVE = AavePairOf[Coin];
        AaveLP.borrow(AAVE.basic, tokenAmt, 2, 0, address(this));
    }

    function _aave_repay(string memory Coin, uint256 tokenAmt) private {
        AavePair storage AAVE = AavePairOf[Coin];
        IERC20 SToken = IERC20(AAVE.basic);
        require(SToken.balanceOf(address(this)) >= tokenAmt);
        if (SToken.allowance(address(this), AAVE_LENDING_POOL) < tokenAmt) {
            require(SToken.approve(AAVE_LENDING_POOL, type(uint256).max), "approve error");
        }

        // approve
        AaveLP.repay(AAVE.basic, tokenAmt, 2, address(this));
    }

    function aave_loop_deposit_001(string memory Coin) private returns(uint256) {
        AavePair storage AAVE = AavePairOf[Coin];
        IERC20 SToken = IERC20(AAVE.basic);

        uint256 tokenAmt = SToken.balanceOf(address(this));

        // 65% => max 70% for BTC
        _aave_deposit(Coin, tokenAmt);
        uint256 B1 = tokenAmt.mul(AAVE.ltv - 100).div(10000);
        _aave_borrow(Coin, B1);

        // _aave_withdraw(Coin, B1);
        return B1;
    }
    function aave_loop_deposit_002(string memory Coin, uint256 tokenAmt) private returns(uint256) {
        AavePair storage AAVE = AavePairOf[Coin];

        // 65% => max 70% for BTC
        _aave_deposit(Coin, tokenAmt);
        uint256 B1 = tokenAmt.mul(AAVE.ltv - 100).div(10000);
        _aave_borrow(Coin, B1);

        // _aave_withdraw(Coin, B1);
        return B1;
    }
    function _loop_deposit_x(string memory Coin, uint Count, uint256 x1) private {
        for(uint256 i; i < Count; i++){
            x1 = aave_loop_deposit_002(Coin, x1);
        }
        _aave_deposit(Coin, x1);
    }


    uint256 private _last_deposit_loop;
    function aave_loop_deposit_x(string memory Coin, uint Count) public onlyOwner() {
        uint256 x1 = aave_loop_deposit_001(Coin);
        _last_deposit_loop = Count;
        _loop_deposit_x(Coin, Count, x1);
    }

    /**
     *
     *   Strength of deposit
     *
     */
    function aave_corrector_add(string memory Coin) public onlyOwner() {
        uint256 borrow = _get_free_to_borrow(Coin);
        require( borrow > 0, "not enough tokens in the pool");
        _last_deposit_loop = _last_deposit_loop + 1;
        _aave_borrow(Coin, borrow);
        _aave_deposit(Coin, borrow);
    }

    function aave_corrector_remove(string memory Coin) public onlyOwner() {
        require( _get_free_to_withdraw(Coin) > 0, "not enough tokens in the pool");
        _last_deposit_loop = _last_deposit_loop - 1;
        _withdraw_001(Coin);
    }

    /**
     *
     *   Matic Reinvest
     *
     */
    function aave_matic_claim_reinvest(string memory Coin, uint256 loopCount) public onlyOwner(){        
        uint256 matic = aave_matic_claim();
        if (WMATIC.allowance(address(this), address(SwapStrategy)) == 0) {
            require(WMATIC.approve(address(SwapStrategy), type(uint256).max), "approve error");
        }
        (uint256 amountOut) = SwapStrategy.swapTo(Coin, matic);
        _loop_deposit_x(Coin, loopCount, amountOut);
    }

    function aave_matic_reinvest_from_balance(string memory Coin, uint256 loopCount) public onlyOwner(){
        // swap WMATIC from balance and reinvest
        if (WMATIC.allowance(address(this), address(SwapStrategy)) < 1) {
            require(WMATIC.approve(address(SwapStrategy), type(uint256).max), "approve error");
        }
        require(WMATIC.balanceOf(address(this)) >= 100000);
        (uint256 amountOut) = SwapStrategy.swapTo( Coin, WMATIC.balanceOf(address(this)) );
        _loop_deposit_x(Coin, loopCount, amountOut);
    }

    function _withdraw_001(string memory Coin) private returns (uint256) {
        ( , , uint256 balance_variableDebtm, , uint256 free_to_withdraw, ) = aave_balances(Coin);            
        _aave_withdraw(Coin, free_to_withdraw);
        if (free_to_withdraw > balance_variableDebtm) {
            // can be close now ...
            if (balance_variableDebtm > 0) {
                _aave_repay(Coin, balance_variableDebtm);
            }
            balance_variableDebtm = 0;
        } else {
            _aave_repay(Coin, free_to_withdraw);
            balance_variableDebtm = balance_variableDebtm - free_to_withdraw;
        }
        return balance_variableDebtm;        
    }

    function aave_loop_withdraw_all(string memory Coin) public onlyOwner() {
        require( _get_free_to_withdraw(Coin) > 0, "not enough tokens in the pool");
        bool stop = true;
        while (stop) {
           if ( _withdraw_001(Coin) == 0) {
               (   ,
                   uint256 balance_am,
                   ,
                   ,
                   uint256 free_to_withdraw,
                   
               ) = aave_balances(Coin);
               if (free_to_withdraw == balance_am) {
                   _aave_withdraw(Coin, balance_am);
                   stop = false;
               } else if (balance_am == 0) {
                   stop = false;
               }
           }
        }
    }

    /* 
     *
     * part withdraw
     *
     */
    function aave_loop_withdraw_x(string memory Coin, address reciver, uint256 amount) public onlyOwner() returns (bool) {
        require(  _get_true_balanse(Coin) >= amount, "not enough tokens in the pool");
        AavePair storage AAVE = AavePairOf[Coin];
        aave_loop_withdraw_all(Coin);
        withdrawERC20sTo(reciver, IERC20(AAVE.basic), amount);
        if (_get_true_balanse(Coin) != amount) {
            aave_loop_deposit_x(Coin, _last_deposit_loop);
        }
        return true;
    }


    function _get_true_balanse(string memory Coin) private view returns (uint256) {
        AavePair storage AAVE = AavePairOf[Coin];
        address _user =         address(this);
        uint256 am =            IERC20(AAVE.am).balanceOf(_user);
        uint256 variableDebtm = IERC20(AAVE.variableDebtm).balanceOf(_user);
        return am - variableDebtm;
    }

    function _get_free_to_borrow(string memory Coin) private view returns (uint256) {
        AavePair storage AAVE = AavePairOf[Coin];
        address _user =         address(this);
        uint256 am =            IERC20(AAVE.am).balanceOf(_user);
        uint256 variableDebtm = IERC20(AAVE.variableDebtm).balanceOf(_user);
        return am.mul(AAVE.ltv - 100).div(10000) - variableDebtm;
    }

    // view #1 PRIVATE
    function _get_free_to_withdraw(string memory Coin) private view returns (uint256) {
        AavePair storage AAVE = AavePairOf[Coin];
        address _user =         address(this);
        uint256 am =            IERC20(AAVE.am).balanceOf(_user);
        uint256 variableDebtm = IERC20(AAVE.variableDebtm).balanceOf(_user);
        uint256 free_to_withdraw;
        if (variableDebtm > 0) {
            free_to_withdraw = am.mul(AAVE.liqvi - 100).div(10000) - variableDebtm;
        } else {
            free_to_withdraw = am;
        }
        return free_to_withdraw;
    }
    function aave_balances(string memory Coin) public view returns (
            uint256 balance_basic,
            uint256 balance_am,
            uint256 balance_variableDebtm,
            uint256 free_to_borrow,
            uint256 free_to_withdraw,
            uint256 true_balance
        ) {
        
        AavePair storage AAVE = AavePairOf[Coin];
        address _user = address(this);

        uint256 basic =         IERC20(AAVE.basic).balanceOf(_user);
        uint256 am =            IERC20(AAVE.am).balanceOf(_user);
        uint256 variableDebtm = IERC20(AAVE.variableDebtm).balanceOf(_user);

        free_to_borrow = am.mul(AAVE.ltv - 100).div(10000) - variableDebtm;

        if (variableDebtm > 0) {
            free_to_withdraw = am.mul(AAVE.liqvi - 100).div(10000) - variableDebtm;
        } else {
            free_to_withdraw = am;
        }

        balance_basic = basic;
        balance_am = am;
        balance_variableDebtm = variableDebtm;
        true_balance = balance_am - balance_variableDebtm;
    }

    // view #2 
    function aave_stat_balances() public view returns (
        uint256 matic,
        uint256 balance_basic,
        uint256 balance_am,
        uint256 balance_variableDebtm,
        uint256 free_to_borrow,
        uint256 free_to_withdraw,
        uint256 true_balance,
        // aave
        uint256 aave_healthFactor,
        uint256 aave_currentLiquidationThreshold,
        uint256 aave_ltv
        ) {
        matic = StakedToken.getRewardsBalance(assets, address(this));
        ( balance_basic,
          balance_am,
          balance_variableDebtm,
          free_to_borrow,
          free_to_withdraw,
          true_balance ) = aave_balances(AAVE_BASE_COIN);

          ( , , ,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        ) = AaveLP.getUserAccountData(address(this));
        aave_healthFactor = healthFactor;
        aave_currentLiquidationThreshold = currentLiquidationThreshold;
        aave_ltv = ltv;
    }



    function _matic_global(address _asset) private view returns (uint128) {
        (uint128 emissionPerSecond, , ) = StakedToken.assets(_asset);
         return emissionPerSecond;
    }

    function _aave_stat_global() private view returns (
            uint256 reserve_liquidityRate,
            uint256 reserve_variableBorrowRate,
            uint256 market_availableLiquidity,
            uint256 market_totalVariableDebt
        )
        { AavePair storage AAVE = AavePairOf[AAVE_BASE_COIN];
           ( uint256 availableLiquidity,,
             uint256 totalVariableDebt,
             uint256 liquidityRate,
             uint256 variableBorrowRate,,,,,
           ) = AaveDataProvider.getReserveData(AAVE.basic);
            reserve_liquidityRate = liquidityRate;
            reserve_variableBorrowRate = variableBorrowRate;
            market_availableLiquidity = availableLiquidity;
            market_totalVariableDebt = totalVariableDebt;
    }

    function aave_stat_global() public view returns (            
        uint256 matic_am,
        uint256 matic_variable,
            uint256 reserve_liquidityRate,
            uint256 reserve_variableBorrowRate,
            uint256 market_availableLiquidity,
            uint256 market_totalVariableDebt) {

        AavePair storage AAVE = AavePairOf[AAVE_BASE_COIN];
        (    reserve_liquidityRate,
             reserve_variableBorrowRate,
             market_availableLiquidity,
             market_totalVariableDebt
        ) = _aave_stat_global();
        matic_am = _matic_global(AAVE.am);
        matic_variable = _matic_global(AAVE.variableDebtm);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './Admin.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
abstract contract Funding is Admin {

    // Withdraw to ...
    function withdrawMatic() public payable onlyOwner {
        require(payable(owner).send(address(this).balance));
    }
    function withdrawMaticTo(address to) public payable onlyOwner {
        require(payable(to).send(address(this).balance));
    }
    function withdrawERC20s(IERC20 _token, uint256 _amount) public onlyOwner {
        require(address(owner) != address(0));
        _token.transfer(owner, _amount);
    }
    function withdrawERC20sTo(address to, IERC20 _token, uint256 _amount) public onlyOwner {
        require(address(to) != address(0));
        _token.transfer(to, _amount);
    }

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

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

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;
interface IAaveProtocolDataProvider {
    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );
    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );
    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );
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
pragma solidity ^0.8.4;
interface ISwapStrategy01 {
    function swapTo( string memory Coin, uint256 _amountIn ) external returns(uint256 amountOut);
    function swapByIndex03( uint256 _amountIn, address _router, address[] memory path ) external returns(uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IStakedToken {

  /**
   * @dev Returns the total of rewards of an user, already accrued + not yet accrued
   * @param user The address of the user
   * @return The rewards
   **/
  function getRewardsBalance(address[] calldata assets, address user)
    external
    view
    returns (uint256);

  /**
   * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
   * @param amount Amount of rewards to claim
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);


    function assets(address asset) external view returns (uint128 emissionPerSecond, uint128 lastUpdateTimestamp, uint256 index);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract Admin {

    constructor (address _owner) {
        owner = _owner;
    }
    
    address public owner;
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    address private receiver;
    modifier onlyReceiver() {
        require(receiver == msg.sender, "Receiver: caller is not the receiver");
        require(receiver != address(0), "Receiver: caller is not the receiver");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner() {
        address oldOwner = owner;
        require(newOwner != oldOwner, "changeOwner: the owner must be different from the current one");
        require(newOwner != address(0), "changeOwner: owner need to be different from zero address");
        receiver = newOwner;
        // emit OwnershipTransferred(oldOwner, newOwner);
    }

    function acceptOwner() public onlyReceiver() {
        address oldOwner = owner;
        address receiverOwner = receiver;
        require(receiverOwner != oldOwner, "changeOwner: the owner must be different from the current one");
        owner = receiverOwner;
        receiver = address(0);
        emit OwnershipTransferred(oldOwner, receiverOwner);
    }

    function renounceOwnership() public onlyOwner() {
        address oldOwner = owner;
        owner = address(0);
        emit OwnershipRenounced(oldOwner);
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipRenounced(address indexed previousOwner);
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