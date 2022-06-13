// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../Interfaces/ISmartChefInitalizable.sol";
import "../Interfaces/IOptVaultFactory.sol";
import "../Interfaces/IReceipt.sol";
import "../Interfaces/IEvents.sol";
import "../Interfaces/IAdmin.sol";
import "../Interfaces/IBYSL.sol";

contract OptVaultAuto is AccessControl, Initializable,ReentrancyGuard, Pausable,IEvents {
    using SafeERC20 for IERC20;

    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE"); //role byte for setter functions
    // enum for calling functions in a symmetry
    enum LiqStatus {
        SWAP_WANT_TO_BUSD,
        CONTROLLER_FEE,
        OPTIMIZATION_TAX
    }
    uint totalStaked;//totalStaked as uint
    uint tax;//tax as uint
    uint S;// Reward share per amount as uint
    uint[3] _setOptimizationTaxFEE;
    uint256 public exchangeRatio ; //exchange ratio of cake multiplied by cofficient 100
    uint256 public epochTime ;//epochTime as uint
    uint256 epochNumber;//epochNumber as uint
    uint256 public id; // pid
    uint256 byslPrice; // bYSL price
    uint256 usdyPrice ; // USDy price
    address public recieptToken; //reciept token against deposit token
    address public teamAddress; // address of team address wallet
    address public router; // Router address
    address public smartChef;
    address public operator;
    address public BUSD;
    LiqStatus public liqStatusValue; // enum 
    IAdmin public  Admin; //admin address
    IERC20 public token; //address of deposit token
    IERC20 public want; // Reward token from smartChef

    mapping(uint => uint32) public multiplierLevel; // level => deduction value of deposit (for level 7 it is 50%).
    mapping(address => uint) public UserLevel;
    mapping(address => uint) public UserReciept;
    mapping(address => uint) public stakedAmount;
    mapping(address => uint) public share;
    mapping(address => uint) public pendingReward;

    /**
    @dev One time called while deploying 
 
    @param _id Pool id
    @param _token Token for vault address
    @param _want Reward token address from smartChef
    @param _Admin admin address

    Note this function set owner as Admin of the contract
     */

    function initialize(uint256 _id, address _token,
     address _want, address _Admin) external initializer {
        id = _id;
        want = IERC20(_want);
        token = IERC20(_token);
        Admin= IAdmin(_Admin);
        exchangeRatio = 100;
        usdyPrice = 1 * 10**18;
        epochTime = 8 hours;
        liqStatusValue = LiqStatus.SWAP_WANT_TO_BUSD;
        teamAddress = Admin.TeamAddress();
        BUSD = Admin.BUSD();
    }

    modifier _isAdmin(){
        require(Admin.hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _;
    }

    modifier _isAdminOrFactory(){
        require(Admin.hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(SETTER_ROLE,msg.sender));
        _;
    }

    modifier _lastExchangeRatio(){
        uint256 lastExchangeRatio = exchangeRatio;
        _;
        if(lastExchangeRatio > exchangeRatio){
            require(lastExchangeRatio > exchangeRatio, "OptVaultAuto: exchangeRatio decreased.");        
            _pause();
        }
    }

    /**
    @dev deposit cake tokens
    @param user address of user
    @param amount amount to be deposited
    */

    function deposit(address user,uint amount,uint32 _level,bool isBUSD) external _isAdminOrFactory _lastExchangeRatio() whenNotPaused() {

        require(amount > 0, 'OptVault: Amount must be greater than zero');
        require(Admin.Treasury() != address(0),'OptVault: Treasury address must be set');
        if(UserLevel[user] == 0 || (UserLevel[user] == _level)) {
        }
        else{
            IOptVaultFactory(Admin.optVaultFactory()).withdraw(user,address(token),false, UserReciept[user],address(this));
            amount = amount + UserReciept[user];
            UserReciept[user] = 0;
        }
        UserLevel[user] = _level;
        IERC20(token).transferFrom(user, address(this), amount);
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = BUSD;
        token.approve(router, ((amount*multiplierLevel[_level])/2000));
        uint256 convertedBUSD = IUniswapV2Router02(router).swapExactTokensForTokens(((amount*multiplierLevel[_level])/2000), 0, path, address(this), block.timestamp+1000)[1];
        path[0] = BUSD;
        path[1] = Admin.USDy();

        uint poolPriceUSDy = IUniswapV2Router02(router).getAmountsOut(1*10**18, path)[1];
        if(usdyPrice < poolPriceUSDy) {
            usdyPrice = poolPriceUSDy * 100;
        } else {
            usdyPrice = 100 * 10**18; //1 dollar coffcient by 100
        }
        uint mintedUSDy = convertedBUSD * 100/usdyPrice;        
        IReceipt(Admin.USDy()).mint(address(this), mintedUSDy);
        IERC20(Admin.USDy()).approve(router, mintedUSDy);
        IERC20(BUSD).approve(router, convertedBUSD);
        IUniswapV2Router02(router).addLiquidity(path[0], path[1], convertedBUSD, mintedUSDy, 1, 1,Admin.Treasury(), block.timestamp + 1678948210);
        uint mintRecieptToken;
        exchangeRatio = (ISmartChefInitalizable(smartChef).userInfo(address(this)).amount == 0 || IERC20(recieptToken).totalSupply() == 0)? 100 : (ISmartChefInitalizable(smartChef).userInfo(address(this)).amount * 100)/IERC20(recieptToken).totalSupply();
        mintRecieptToken = (amount - (amount * (multiplierLevel[_level]/1000))) * 100/exchangeRatio;
        IReceipt(recieptToken).mint(address(this), mintRecieptToken);
        UserReciept[user] += mintRecieptToken;

        // fetch price of bysl
        path[1] = address(Admin.bYSL());
        IReceipt(Admin.BShare()).mint(user, (amount * (multiplierLevel[_level]/1000))/  IBYSL(Admin.bYSL()).protocolPrice() * 100);
        IERC20(token).approve(smartChef,(amount -((amount*multiplierLevel[_level])/2000)));
        // depositing amount by subtracting the percentage of which is being used for add liquidity of USDY BUSD pair.
        ISmartChefInitalizable(smartChef).deposit(amount -((amount*multiplierLevel[_level])/2000));
        exchangeRatio = (ISmartChefInitalizable(smartChef).userInfo(address(this)).amount * 100)/IERC20(recieptToken).totalSupply();
        if(stakedAmount[user] != 0){
            pendingReward[user] += (stakedAmount[user] * (S - share[user]))/10**18;
        }
        stakedAmount[user] += (amount -((amount*multiplierLevel[_level])/2000));
        totalStaked += (amount -((amount*multiplierLevel[_level])/2000));
        share[user] = S;
        emit OptDeposit("Opt Vault Auto",address(this),user, amount,_level,block.number,block.timestamp);     

    }

    

    /**
    @dev withdraw from vault
    @param user user address
    @param isReciept reciept or not
    @param _amount withdraw amount
    */

    function withdraw(address user, bool isReciept, uint _amount , address sendTo) external _isAdminOrFactory _lastExchangeRatio() whenNotPaused() {
        require(UserReciept[user] > 0,"OptVault: You need to first deposit");
        require(_amount <= UserReciept[user],"OptVault: Invalid Amount");
        IOptVaultFactory(Admin.optVaultFactory()).optimizationRewards(user,address(token));
        address sendTo = msg.sender == Admin.optVaultFactory() ? address(this) : msg.sender;
        (,uint balance) = rewardState(user, _amount);
        if(isReciept){
            IERC20(recieptToken).safeTransfer(sendTo,_amount);
        }else{
            ISmartChefInitalizable(smartChef).withdraw(balance);
            IERC20(token).safeTransfer(sendTo, balance);
            IReceipt(recieptToken).burn(address(this), _amount);
            // exchangeRatio = (ISmartChefInitalizable(smartChef).userInfo(id, address(this)).amount * 100)/IERC20(recieptToken).totalSupply();

        }
        UserReciept[user] -= _amount;
        emit Optwithdraw("Opt Vault Auto",address(this),user, _amount,block.number,block.timestamp);     

    }

    /**
    @dev purchase cake receipt tokens
    @param user address of user
    @param amount purchase amount
    */

    function purchase(address user, uint amount) nonReentrant external _lastExchangeRatio() whenNotPaused() returns(uint){
        IERC20(token).safeTransferFrom(user, address(this),amount);
        IERC20(token).approve(smartChef, amount);
        ISmartChefInitalizable(smartChef).deposit(amount);
        uint balance = purchaseOf(amount);
        IReceipt(recieptToken).mint(user, balance);
        exchangeRatio = (ISmartChefInitalizable(smartChef).userInfo(address(this)).amount * 100)/IERC20(recieptToken).totalSupply();
        return(balance);
        emit purchaseORsell("optVaultAuto",user,amount,block.number,block.timestamp);

    }

    /**
    @dev sell cake receipt tokens and acquire cake tokens
    @param user address of user
    @param amount sell amount
    */

    function sell(address user, uint amount) nonReentrant external _lastExchangeRatio() whenNotPaused() returns(uint){
        IERC20(recieptToken).safeTransferFrom(user, address(this),amount);
        uint balance = sellOf(amount);
        IERC20(token).approve(smartChef, amount);
        ISmartChefInitalizable(smartChef).withdraw(balance);
        IERC20(token).safeTransfer(user,balance);
        // exchangeRatio = (ISmartChefInitalizable(smartChef).userInfo(id, address(this)).amount * 100)/IERC20(recieptToken).totalSupply();
        return(balance);
        emit purchaseORsell("optVaultAuto",user,amount,block.number,block.timestamp);

    }

    /**
    @dev  Function for purchaseOf
    @param amount amount as parameter.
    */

    function purchaseOf(uint amount) public view returns(uint){
        return((amount * (exchangeRatio - tax))/100);
    }
    /**
    @dev  Function for sellOf
    @param amount amount as parameter.
    */

    function sellOf(uint amount) public view returns(uint){
        return((amount * exchangeRatio * (100 - tax))/10000);

    }

    /**
    @dev Setter Function for setTax
    @param value amount as parameter.
    */

    function setTax(uint value) external _isAdminOrFactory{
        require(tax != 0,"OptVaultAuto : Tax can't be zero");
        emit setterForUint("optVaultAuto",address(this),tax,value,block.number,block.timestamp);
        tax = value;
    }

    /**
    @dev Setter Function for setting receipt address
    @param _reciept , reciept address
    */

    function setreciept(address _reciept) external onlyRole(SETTER_ROLE){
        require(_reciept != address(0),"OptVaultAuto : RecieptToken can't be zero");
        emit setterForAddress("OptVaultAuto",address(this),recieptToken,_reciept,block.number,block.timestamp);
        recieptToken = _reciept;
    }


    function swapWantToBUSD() nonReentrant external onlyRole(SETTER_ROLE) {
        require(liqStatusValue == LiqStatus.SWAP_WANT_TO_BUSD, 'OptVault: Initialize your OptVault first');
        address[] memory path = new address[](2);
        path[0] = address(want);
        path[1] = BUSD;
        uint256 wantBalance = ISmartChefInitalizable(smartChef).userInfo(address(this)).amount - totalStaked;
        // Get current APR from the protocol
        withdrawAcc(wantBalance);
        if (wantBalance > 0) {
            want.approve(router, wantBalance);
            IUniswapV2Router02(router).swapExactTokensForTokens(
                wantBalance,
                1,
                path,
                address(this),
                block.timestamp + 10000
            );
        }
            liqStatusValue = LiqStatus.CONTROLLER_FEE;
    }

    /**
    @dev Setter Function for deducting controller fee
    @param fee , fee amount
    */

    function deductControllerFee(uint fee) nonReentrant external onlyRole(SETTER_ROLE) {
        require(fee > 0, 'OptVault: fee can not be zero.');
        require(liqStatusValue == LiqStatus.CONTROLLER_FEE, 'OptVault: Swap want to BUSD first');
        IERC20(BUSD).transfer(teamAddress, fee);
        liqStatusValue = LiqStatus.OPTIMIZATION_TAX;
    }

    function collectOptimizationTax() nonReentrant external onlyRole(SETTER_ROLE) {
        require(liqStatusValue == LiqStatus.OPTIMIZATION_TAX, 'OptVault: Pay controller fee first');
        address[] memory path = new address[](2);
        uint balanceUSD = IERC20(BUSD).balanceOf(address(this));
        S += (balanceUSD * 10 ** 18)/ totalStaked;
        path[0] = BUSD;
        path[1] = Admin.YSL();
        IERC20(BUSD).approve(router, balanceUSD); //BSC Testnetapeswap router address
        uint convertedYSL = IUniswapV2Router02(router).swapExactTokensForTokens( 
            (balanceUSD*_setOptimizationTaxFEE[0])/100,
            0,
            path,
            address(this),
            block.timestamp + 1000
        )[1];
        path[1] = Admin.xYSL();
        uint convertedxYSL = IUniswapV2Router02(router).swapExactTokensForTokens( 
            (balanceUSD*_setOptimizationTaxFEE[1])/100,
            0,
            path,
            address(this),
            block.timestamp + 1000
        )[1];
        IERC20(Admin.YSL()).transfer(Admin.temporaryHolding(), (convertedYSL*20)/100);
        IERC20(Admin.YSL()).transfer(Admin.YSLVault(), (convertedYSL*80)/100);
        IERC20(Admin.xYSL()).transfer(Admin.temporaryHolding(), (convertedxYSL*20)/100);
        IERC20(Admin.xYSL()).transfer(Admin.xYSLVault(), (convertedxYSL*80)/100);
        IERC20(BUSD).transfer(Admin.Treasury(),(balanceUSD*_setOptimizationTaxFEE[2])/(100 * 2));
        IERC20(BUSD).transfer(Admin.TeamAddress(),(balanceUSD*_setOptimizationTaxFEE[2])/(100 * 2));
        liqStatusValue = LiqStatus.SWAP_WANT_TO_BUSD;
    }

    /**
    @dev function for optimizaation reward
    @param user user address
    @param optMultiplier multiplier amount
    */

    function optimizationReward(address user, uint optMultiplier) nonReentrant external onlyRole(SETTER_ROLE) {
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = Admin.USDy();
        uint poolPriceUSDy = IUniswapV2Router02(router).getAmountsOut(1 * 10**18, path)[1];
        if(usdyPrice < poolPriceUSDy) {
            usdyPrice = poolPriceUSDy * 100;
        } else {
            usdyPrice = 100 * 10**18; //1 dollar coffcient by 100
        }
        uint BUSDAmount = pendingReward[user] + (stakedAmount[user] * (S - share[user]))/10**18;
        share[user] = S;
        uint mintReward = BUSDAmount * optMultiplier/usdyPrice;
        IReceipt(Admin.USDy()).mint(user, mintReward);
        emit OptimizationRewards(address(this), user, mintReward,block.number,block.timestamp);

    }

    /**
    @dev  detter function for optimizationTAXfee
    @param getOptimizationTaxFEE , tax fee as parameter.
    */

    function setOptimizationTaxFEE(uint[3] calldata getOptimizationTaxFEE) external _isAdminOrFactory{
        require(getOptimizationTaxFEE[0]+getOptimizationTaxFEE[1]+getOptimizationTaxFEE[2] == 100 ,"OptVault: Total value should be equal to 100");
        emit setterForOptimizationTaxFee("OptvaultAuto", address(this), _setOptimizationTaxFEE, getOptimizationTaxFEE,block.number,block.timestamp);
        _setOptimizationTaxFEE[0] = getOptimizationTaxFEE[0];
        _setOptimizationTaxFEE[1] = getOptimizationTaxFEE[1];
        _setOptimizationTaxFEE[2] = getOptimizationTaxFEE[2];
    }

 /**
    @dev Setter Function for router
    @param _router , router address as parameter.
    */

    function setRouter(address _router) external _isAdmin{
        require(_router != address(0),"OptVaultAuto : Router address can not be null");
        emit setterForAddress("OptVaultAuto",address(this),router,_router,block.number,block.timestamp);
        router = _router;
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
    */
    
    function unpause() external _isAdmin{
        _unpause();
    }

    function setOperator(address _operator) external _isAdmin{
        operator = _operator;
    }

    function setMultiplierLevel(uint32 _level,uint32 amount) external _isAdminOrFactory returns(uint32){
        require(_level !=0,"optvaultAuto : Level can't be Zero");
        emit setterForMultiplierLevel("optVaultAuto", address(this), _level, multiplierLevel[_level], amount,block.number,block.timestamp);
        multiplierLevel[_level] = amount;
        return amount;
    }
    function setRole(address Admin) external {
        require(msg.sender == IAdmin(Admin).optVaultFactory(),"optvaultAuto: Only Factory can call");
        _setupRole(SETTER_ROLE, msg.sender);
    }

    function setPoolDetails(address _smartChef, address _wantToken) external {
        require(msg.sender == operator || hasRole(SETTER_ROLE, msg.sender),"Only operator can call");
        smartChef = _smartChef;
        want = IERC20(_wantToken);
    }

    function vaultToken() external view returns(address) {
        return address(token);
    }

    /**
    @dev Function for withdrawAcc
    @param _amount , amount as parameter
    */

    function withdrawAcc(uint256 _amount)  internal {
        uint256 totalCompounds = ISmartChefInitalizable(smartChef).userInfo(address(this)).amount;
        if (totalCompounds > 0) {
            ISmartChefInitalizable(smartChef).withdraw(_amount);
        }
    }

    /**
    @dev Reward state
    @param user user address
    @param _amount amount
    */

    function rewardState(address user,uint _amount) internal returns(uint,uint){
        uint totalBalance = (UserReciept[user] * exchangeRatio)/100;
        uint balance = (_amount * exchangeRatio)/100;
        pendingReward[user] += (stakedAmount[user] * (S - share[user]))/10**18;
        share[user] = S;
        totalStaked -= (UserReciept[user] * balance) / totalBalance;
        stakedAmount[user] -= (UserReciept[user] * balance) / totalBalance;
        return (totalBalance,balance);
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
                        Strings.toHexString(uint160(account), 20),
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ISmartChefInitalizable {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }
    function accTokenPerShare() external returns(uint256);
    function userInfo(address _user) external view returns (UserInfo memory);
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOptVaultFactory{
     struct UserInfo {
        uint256 time;
        bool phoenixNFTStatus;
        nftStatus NFT;
        uint256 amount;
    }
    enum nftStatus {
        NOT_MINTED,
        ACTIVE
    }
    struct PoolInfo {
        IERC20 token;
        address vault;
        address recieptInstance;
        bool status;
        bool isLp;
        bool isAuto;
        bool isCustomVault;
        uint32[] multiplier;
    }

    enum LiqStatus {
        SWAP_WANT_TO_BUSD,
        CONTROLLER_FEE,
        OPTIMIZATION_TAX,
        OPTIMIZATION_REWARDS
    }
     function initialize(address owner,address _BUSD,address _distributor,address _tempHolding,address _USDy,address _masterNTT,address nft,address phoenix,address _masterChef) external;
     function add( IERC20 _token, address _strat,string memory _name,string memory _symbol,uint32[] memory _multiplier) external;
     function setMultipliersLevel(address _token,uint32[] calldata _multiplier,uint32[] memory deductionValue) external;
     function Deposit(address user,address _token,uint _level,uint256 _amount) external ;
     function withdraw(address user,address _token,bool isReceipt,uint _recieptAmount,address sendTo) external ;
     function userInfo(uint pid,address user) external returns(UserInfo memory);
     function getPoolInfo(uint index) external view returns(address vaultAddress, bool isLP, address recieptInstance, IERC20 token,bool isCustomVault);
     function PIDsOfRewardVault(address token) external returns(uint256);
     function optimizationRewards(address user,address _token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IReceipt {
    function mint(address account, uint amount) external;
    function burn(address account, uint amount) external;
    function setMinter(address _operator) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function initialize(address _admin, address operator, string memory name_, string memory symbol_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IEvents{
    event Deposit(string Vault,address receiver,address user,uint amount, uint blocknumber,uint blockTimestamp);
    event Withdraw(string Vault,address receiver,address user,uint amount,uint blocknumber,uint blockTimestamp);
    event purchaseORsell(string Vault,address user,uint amount,uint blocknumber,uint blockTimestamp);
    event OptDeposit(string Vault,address receiver,address user,uint amount,uint32 level,uint blocknumber,uint blockTimestamp);
    event Optwithdraw(string Vault,address receiver,address user,uint amount,uint blocknumber,uint blockTimestamp);
    event OptAdd(address token, bool isLptoken, bool isAuto, address smartchef,address strat,address instance,uint blocknumber,uint blockTimestamp);
    event OptAddCustomVaults(address token,address vault,uint blocknumber,uint blockTimestamp);
    event CalculateAPR(address vault, uint value,uint blocknumber,uint blockTimestamp);
    event BUSDcollected(uint busdCollected,uint blocknumber,uint blockTimestamp);
    event ControllerFee(address vault,uint amount,uint blocknumber,uint blockTimestamp);
    event OptimizationRewards(address optvault, address user, uint reward,uint blocknumber,uint blockTimestamp);
    event LottoDeposit(string Vault,address user, uint amount,uint blocknumber,uint blockTimestamp);
    event setterForUint(string contractName,address contractAddress,uint previousValue, uint currentValue,uint blocknumber,uint blockTimestamp);
    event setterForAddress(string contractName,address contractAddress,address previousAddress, address currentAddress,uint blocknumber,uint blockTimestamp);
    event setterForRefferer(string contractName,address contractAddress,address previousRefferAddress,address RefferAddress, address UserAddress,uint blocknumber,uint blockTimestamp);
    event TaxAllocation(string contractName,address contractAddress,uint previousTax,uint currentTax, uint[] perviousAllocationTax,uint[] currentAllocationTax,uint blocknumber,uint blockTimestamp);
    event setterForMultiplierLevel(string contractName,address contractAddress,uint level,uint multiplierLevel,uint amount, uint blocknumber,uint blockTimestamp);
    event OptMultiplier(string contractName, uint pid, uint32[] number,uint blocknumber,uint blockTimestamp);
    event OptMultiplierLevel(string contractName, address token, uint32[] multiplier,uint32[] deductionValue,uint blocknumber,uint blockTimestamp);
    event setterForOptimizationTaxFee(string contractName,address contractAddress,uint[3] previousArray,uint[3] currentArray,uint blocknumber,uint blockTimestamp);
    event BiddingNFT(string contractName,address user, uint amount,uint totalAmount,uint blocknumber,uint blockTimestamp);
    event claimBID(string contractName, address user, uint wonAddress, uint totalAmount,uint blocknumber,uint blockTimestamp);
    event EndAuction(string contractName, bool rank, address TopofAuction,uint tokenId,uint blocknumber,uint blockTimestamp);
    event resetNewAuction(string contractName, uint highestbid, address winnerofTokenID,uint biddingArray,uint blocknumber,uint blockTimestamp);
    event Buy(string contractName, uint counter,uint lockPeriod,uint blocknumber,uint blockTimestamp);
    event ReactivateNFT(string contractName, address user,uint userTokenID,uint blocknumber,uint blockTimestamp);
    event RewardDistribute(string contractName,address user, uint reward,uint TotalRewardPercentage,address UserRefferer, uint Leftamount,uint blocknumber,uint blockTimestamp);
    event rewardpercentage(string contractName, address user, uint128[4] amount,uint blocknumber,uint blockTimestamp);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/IAccessControl.sol";
interface IAdmin is IAccessControl{
    function lpDeposit() external returns(bool);
    function admin() external returns(address);
    function operator() external returns(address);
    function Trigger() external returns(address);
    function POL() external  view returns(address);
    function Treasury() external view returns(address);
    function BShareBUSDVault() external returns(address);
    function bYSLVault() external returns(address);
    function USDyBUSDVault() external returns(address);
    function USDyVault() external returns(address);
    function xYSLBUSDVault() external returns(address);
    function xYSLVault() external returns(address);
    function YSLBUSDVault() external returns(address);
    function YSLVault() external returns(address);
    function BShare() external returns(address);
    function bYSL() external returns(address);
    function USDs() external returns(address);
    function USDy() external returns(address);
    function YSL() external returns(address);
    function xYSL() external returns(address);
    function xYSLS() external returns(address);
    function YSLS() external returns(address);
    function swapPage() external returns(address);
    function PhoenixNFT() external returns(address);
    function Opt1155() external returns(address);
    function EarlyAccess() external returns(address);
    function helperSwap() external returns(address);
    function optVaultFactory() external returns(address);
    function swap() external returns(address);
    function temporaryHolding() external returns(address);
    function whitelist() external returns(address);
    function Blacklist() external returns(address);
    function BUSD() external view returns(address);
    function WBNB() external returns(address);
    function BShareVault() external returns(address);
    function masterNTT() external returns (address);
    function biswapRouter() external returns (address);
    function ApeswapRouter() external returns (address);
    function pancakeRouter() external returns (address);
    function TeamAddress() external returns (address);
    function MasterChef() external returns (address);
    function Refferal() external returns (address);
    function liquidityProvider() external returns(address);
    function temporaryReferral() external returns(address);
    function initialize(address owner) external;
    function setLpDeposit(bool deposit) external;
    function setRefferal(address _refferal)  external;
    function setWBNB(address _WBNB) external;
    function setBUSD(address _BUSD) external;
    function setLiquidityProvider(address _liquidityProvider) external;
    function setWhitelist(address _whitelist) external;
    function setBlacklist(address _blacklist) external;
    function sethelperSwap(address _helperSwap) external;
    function setTemporaryHolding(address _temporaryHolding) external;
    function setSwap(address _swap) external;
    function setOptVaultFactory(address _optVaultFactory) external;
    function setEarlyAccess(address _EarlyAccess) external;
    function setOpt1155(address _Opt1155) external;
    function setPhoenixNFT(address _PhoenixNFT) external;
    function setSwapPage(address _swapPage) external;
    function setYSL(address _YSL) external;
    function setYSLS(address _YSLS) external;
    function setxYSLs(address _xYSLS) external;
    function setxYSL(address _xYSL) external;
    function setUSDy(address _USDy) external;
    function setUSDs(address _USDs) external;
    function setbYSL(address _bYSL) external;
    function setBShare(address _BShare) external;
    function setYSLVault(address _YSLVault) external;
    function setYSLBUSDVault(address _YSLBUSDVault) external;
    function setxYSLVault(address _xYSLVault) external;
    function setxYSLBUSDVault(address _xYSLBUSDVault) external;
    function setUSDyVault(address _USDyVault) external;
    function setUSDyBUSDVault(address _USDyBUSDVault) external;
    function setbYSLVault(address _bYSLVault) external;
    function setBShareBUSD(address _BShareBUSD) external;
    function setPOL(address setPOL) external;
    function setBShareVault(address _BShareVault) external;
    function setTrigger(address _Trigger) external;
    function setmasterNTT(address _masterntt) external;
    function setbiswapRouter(address _biswapRouter)external;
    function setApeswapRouter(address _ApeswapRouter)external;
    function setpancakeRouter(address _pancakeRouter)external;
    function setTeamAddress(address _TeamAddress)external;
    function setMasterChef(address _MasterChef)external;
    function setTemporaryReferral(address _temporaryReferral)external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IBYSL {

    function isMinter(address _address) external view returns (bool result);
    function mint(address account, uint amount) external;
    function burn(address account, uint amount) external;
    function setMinter(address _minter) external;
    function removeMinter(address _minter) external; 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function protocolPrice() external view returns(uint);
    function backedPrice() external view returns(uint);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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