// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "../interfaces/IOdosRouter.sol";
import "../interfaces/IUnoAssetRouter.sol";   
import "../interfaces/IUnoAutoStrategyFactory.sol";
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';

contract UnoAutoStrategyBanxe is Initializable, ERC20Upgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    /**
     * @dev PoolInfo:
     * {assetRouter} - UnoAssetRouter contract.
     * {pool} - Pool address. 
     * {tokenA} - Pool's first token address.
     * {tokenB} - Pool's second token address.
     */
    struct _PoolInfo {
        address pool;
        IUnoAssetRouter assetRouter;
    }

    struct PoolInfo {
        address pool;
        IUnoAssetRouter assetRouter;
        IERC20Upgradeable tokenA;
        IERC20Upgradeable tokenB;
    }

    /**
     * @dev MoveLiquidityInfo:
     * {leftoverA} - TokenA leftovers after MoveLiquidity() call.
     * {leftoverB} - TokenB leftovers after MoveLiquidity() call. 
     * {totalSupply} - totalSupply after MoveLiquidity() call.
     * {block} - MoveLiquidity() call block.
     */
    struct MoveLiquidityInfo {
        uint256 leftoverA;
        uint256 leftoverB;
        uint256 totalSupply;
        uint256 block;
    }
    
    /**
     * @dev Contract Variables:
     * banxe - Banxe account that can make deposits to autostrats.
     * {OdosRouter} - Contract that executes swaps.

     * {poolID} - Current pool the strategy uses ({pools} index).
     * {pools} - Pools this strategy can use and move liquidity to.

     * {reserveLP} - LP token reserve.
     * {lastMoveInfo} - Info on last MoveLiquidity() block.
     * {blockedLiquidty} - User's blocked LP tokens. Prevents user from stealing leftover tokens by depositing and exiting before moveLiquidity() has been called.

     * {accessManager} - Role manager contract.
     * {factory} - The address of AutoStrategyFactory this contract was deployed by.

     * {MINIMUM_LIQUIDITY} - Ameliorates rounding errors.
     */

    address public banxe;
    IOdosRouter private constant OdosRouter = IOdosRouter(0xa32EE1C40594249eb3183c10792BcF573D4Da47C);

    uint256 public poolID;
    PoolInfo[] public pools;

    uint256 private reserveLP;
    MoveLiquidityInfo private lastMoveInfo;
    mapping(address => mapping(uint256 => uint256)) private blockedLiquidty;
    mapping(address => mapping(uint256 => bool)) private leftoversCollected;

    IUnoAccessManager public accessManager;
    IUnoAutoStrategyFactory public factory;

    uint256 private constant MINIMUM_LIQUIDITY = 10**3;
    bytes32 private constant LIQUIDITY_MANAGER_ROLE = keccak256('LIQUIDITY_MANAGER_ROLE');
    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    event DepositPairTokens(uint256 indexed poolID, uint256 amountA, uint256 amountB);
    event DepositPairTokensETH(uint256 indexed poolID, uint256 amountToken, uint256 amountETH);
    event DepositSingleToken(uint256 indexed poolID, address indexed token, uint256 amount);
    event DepositSingleETH(uint256 indexed poolID, uint256 amountETH);
    // Note: amountLP refers to LP tokens used in farms and staking pools, not UNO-LP this contract is.
    // To get info for UNO-LP use mint/burn events
    event Deposit(uint256 indexed poolID, address indexed from, address indexed recipient, uint256 amountLP);

    event WithdrawPairTokens(uint256 indexed poolID, uint256 amountA, uint256 amountB);
    event WithdrawPairTokensETH(uint256 indexed poolID, uint256 amountToken, uint256 amountETH);
    event WithdrawSingleToken(uint256 indexed poolID, address indexed token, uint256 amount, uint256 amountA, uint256 amountB);
    event WithdrawSingleETH(uint256 indexed poolID, uint256 amountETH, uint256 amountA, uint256 amountB);
    // Note: amountLP refers to LP tokens used in farms and staking pools, not UNO-LP this contract is.
    // To get info for UNO-LP use mint/burn events
    event Withdraw(uint256 indexed poolID, address indexed from, address indexed recipient, uint256 amountLP);

    event MoveLiquidity(uint256 indexed previousPoolID, uint256 indexed nextPoolID);
    event BanxeTransferred(address indexed previousBanxe, address indexed newBanxe);

    modifier whenNotPaused(){
        require(factory.paused() == false, 'PAUSABLE: PAUSED');
        _;
    }

    modifier onlyBanxe(){
        require(msg.sender == banxe || accessManager.hasRole(0x00, msg.sender), "CALLER_NOT_BANXE");
        _;
    }

    // ============ Methods ============
    
    receive() external payable {}

    function initialize(_PoolInfo[] calldata poolInfos, IUnoAccessManager _accessManager, address _banxe) external initializer {
        require (_banxe != address(0), "BAD_BANXE_ADDRESS");
        require ((poolInfos.length >= 2) && (poolInfos.length <= 50), 'BAD_POOL_COUNT');

        __ERC20_init("UNO-Banxe-AutoStrategy", "UNO-BANXE-LP");
        __ReentrancyGuard_init();
        
        for (uint256 i = 0; i < poolInfos.length; i++) {
            address[] memory _tokens = IUnoAssetRouter(poolInfos[i].assetRouter).getTokens(poolInfos[i].pool);
            PoolInfo memory pool = PoolInfo({
                pool: poolInfos[i].pool,
                assetRouter: poolInfos[i].assetRouter,
                tokenA: IERC20Upgradeable(_tokens[0]),
                tokenB: IERC20Upgradeable(_tokens[1])
            });
            pools.push(pool);

            if (pool.tokenA.allowance(address(this), address(pool.assetRouter)) == 0) {
                pool.tokenA.approve(address(OdosRouter), type(uint256).max);
                pool.tokenA.approve(address(pool.assetRouter), type(uint256).max);
            }
            if (pool.tokenB.allowance(address(this), address(pool.assetRouter)) == 0) {
                pool.tokenB.approve(address(OdosRouter), type(uint256).max);
                pool.tokenB.approve(address(pool.assetRouter), type(uint256).max);
            }
        }

        banxe = _banxe;
        emit BanxeTransferred(address(0), _banxe);

        accessManager = _accessManager;
        lastMoveInfo.block = block.number;
        factory = IUnoAutoStrategyFactory(msg.sender);
    }

    /**
     * @dev Deposits tokens in the pools[poolID] pool. Mints tokens representing user share. Emits {Deposit} event.
     * @param pid - Current poolID. Throws revert if moveLiquidity() has been called before the transaction has been mined.
     * @param amountA - Token A amount to deposit.
     * @param amountB  - Token B amount to deposit.
     * @param amountAMin - Bounds the extent to which the B/A price can go up before the transaction reverts.
     * @param amountBMin - Bounds the extent to which the A/B price can go up before the transaction reverts.
     * @param recipient - Address which will receive the deposit.
     
     * @return sentA - Deposited token A amount.
     * @return sentB - Deposited token B amount.
     * @return liquidity - Total liquidity minted for the {recipient}.
     */
    function deposit(uint256 pid, uint256 amountA, uint256 amountB, uint256 amountAMin, uint256 amountBMin, address recipient) onlyBanxe whenNotPaused nonReentrant external returns (uint256 sentA, uint256 sentB, uint256 liquidity) {
        require (pid == poolID, 'BAD_POOL_ID');
        PoolInfo memory pool = pools[poolID];

        pool.tokenA.safeTransferFrom(msg.sender, address(this), amountA);
        pool.tokenB.safeTransferFrom(msg.sender, address(this), amountB);

        uint256 amountLP;
        (sentA, sentB, amountLP) = pool.assetRouter.deposit(pool.pool, amountA, amountB, amountAMin, amountBMin, address(this));
        liquidity = mint(recipient);

        if(amountA > sentA){
            pool.tokenA.safeTransfer(msg.sender, amountA - sentA);
        }
        if(amountB > sentB){
            pool.tokenB.safeTransfer(msg.sender, amountB - sentB);
        }

        emit DepositPairTokens(poolID, sentA, sentB);
        emit Deposit(poolID, msg.sender, recipient, amountLP); 
    }

    /**
     * @dev Deposits tokens in the pools[poolID] pool. Mints tokens representing user share. Emits {Deposit} event.
     * @param pid - Current poolID. Throws revert if moveLiquidity() has been called before the transaction has been mined.
     * @param amountToken - Token amount to deposit.
     * @param amountTokenMin - Bounds the extent to which the TOKEN/WMATIC price can go up before the transaction reverts.
     * @param amountETHMin - Bounds the extent to which the WMATIC/TOKEN price can go up before the transaction reverts.
     * @param recipient - Address which will receive the deposit.
     
     * @return sentToken - Deposited token amount.
     * @return sentETH - Deposited ETH amount.
     * @return liquidity - Total liquidity minted for the {recipient}.
     */
    function depositETH(uint256 pid, uint256 amountToken, uint256 amountTokenMin, uint256 amountETHMin, address recipient) onlyBanxe whenNotPaused nonReentrant external payable returns (uint256 sentToken, uint256 sentETH, uint256 liquidity) {
        require (pid == poolID, 'BAD_POOL_ID');
        PoolInfo memory pool = pools[poolID];

        IERC20Upgradeable token;
        if (address(pool.tokenA) == WMATIC) {
            token = pool.tokenB;
        } else if (address(pool.tokenB) == WMATIC) {
            token = pool.tokenA;
        } else {
            revert("NOT_WMATIC_POOL");
        }
        token.safeTransferFrom(msg.sender, address(this), amountToken);

        uint256 amountLP;
        (sentToken, sentETH, amountLP) = pool.assetRouter.depositETH{value: msg.value}(pool.pool, amountToken, amountTokenMin, amountETHMin, address(this));
        liquidity = mint(recipient);

        if(amountToken > sentToken){
            token.safeTransfer(msg.sender, amountToken - sentToken);
        }
        if(msg.value > sentETH){
            payable(msg.sender).transfer(msg.value - sentETH);
        }

        emit DepositPairTokensETH(poolID, sentToken, sentETH);
        emit Deposit(poolID, msg.sender, recipient, amountLP); 
    }

    /**
     * @dev Deposits tokens in the pools[poolID] pool. Mints tokens representing user share. Emits {Deposit} event.
     * @param pid - Current poolID. Throws revert if moveLiquidity() has been called before the transaction has been mined.
     * @param token - Token to deposit.
     * @param amount - {token} amount to deposit.
     * @param swapData - Parameter with which 1inch router is being called with.
     * @param amountAMin - Bounds the extent to which the B/A price can go up before the transaction reverts.
     * @param amountBMin - Bounds the extent to which the A/B price can go up before the transaction reverts.
     * @param recipient - Address which will receive the deposit.
     
     * @return sent - Total {token} amount sent to the farm. NOTE: Returns dust left from swap in {token}, but if A/B amounts are not correct also returns dust in pool's tokens.
     * @return liquidity - Total liquidity minted for the {recipient}.
     */
    function depositSingleAsset(uint256 pid, address token, uint256 amount, bytes[2] calldata swapData, uint256 amountAMin, uint256 amountBMin, address recipient) onlyBanxe whenNotPaused nonReentrant external returns (uint256 sent, uint256 liquidity) {
        require (pid == poolID, 'BAD_POOL_ID');
        PoolInfo memory pool = pools[poolID];

        uint256 balanceA = pool.tokenA.balanceOf(address(this));
        uint256 balanceB = pool.tokenB.balanceOf(address(this));

        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20Upgradeable(token).approve(address(pool.assetRouter), amount);

        uint256 amountLP;
        (sent, amountLP) = pool.assetRouter.depositSingleAsset(pool.pool, token, amount, swapData, amountAMin, amountBMin, address(this));
        liquidity = mint(recipient);

        IERC20Upgradeable(token).safeTransfer(msg.sender, amount - sent);
        uint256 _balanceA = pool.tokenA.balanceOf(address(this));
        uint256 _balanceB = pool.tokenB.balanceOf(address(this));
        if(_balanceA > balanceA){
            pool.tokenA.safeTransfer(msg.sender, _balanceA - balanceA);
        }
        if(_balanceB > balanceB){
            pool.tokenB.safeTransfer(msg.sender, _balanceB - balanceB);
        }

        emit DepositSingleToken(poolID, token, sent);
        emit Deposit(poolID, msg.sender, recipient, amountLP);
    }

    /**
     * @dev Deposits tokens in the pools[poolID] pool. Mints tokens representing user share. Emits {Deposit} event.
     * @param pid - Current poolID. Throws revert if moveLiquidity() has been called before the transaction has been mined.
     * @param swapData - Parameter with which 1inch router is being called with. NOTE: Use WMATIC as toToken.
     * @param amountAMin - Bounds the extent to which the B/A price can go up before the transaction reverts.
     * @param amountBMin - Bounds the extent to which the A/B price can go up before the transaction reverts.
     * @param recipient - Address which will receive the deposit.
     
     * @return sentETH - Total MATIC amount sent to the farm. NOTE: Returns dust left from swap in MATIC, but if A/B amount are not correct also returns dust in pool's tokens.
     * @return liquidity - Total liquidity minted for the {recipient}.
     */
    function depositSingleETH(uint256 pid, bytes[2] calldata swapData, uint256 amountAMin, uint256 amountBMin, address recipient) onlyBanxe whenNotPaused nonReentrant external payable returns (uint256 sentETH, uint256 liquidity) {
        require (pid == poolID, 'BAD_POOL_ID');
        PoolInfo memory pool = pools[poolID];

        uint256 balanceA = pool.tokenA.balanceOf(address(this));
        uint256 balanceB = pool.tokenB.balanceOf(address(this));

        uint256 amountLP;
        (sentETH, amountLP) = pool.assetRouter.depositSingleETH{value: msg.value}(pool.pool, swapData, amountAMin, amountBMin, address(this));
        liquidity = mint(recipient);

        payable(msg.sender).transfer(msg.value - sentETH);
        uint256 _balanceA = pool.tokenA.balanceOf(address(this));
        uint256 _balanceB = pool.tokenB.balanceOf(address(this));
        if(_balanceA > balanceA){
            pool.tokenA.safeTransfer(msg.sender, _balanceA - balanceA);
        }
        if(_balanceB > balanceB){
            pool.tokenB.safeTransfer(msg.sender, _balanceB - balanceB);
        }

        emit DepositSingleETH(poolID, sentETH);
        emit Deposit(poolID, msg.sender, recipient, amountLP); 
    }

    /**
     * @dev Withdraws tokens from the {pools[poolID]} pool and sends them to the recipient. Burns tokens representing user share. Emits {Withdraw} event.
     * @param pid - Current poolID. Throws revert if moveLiquidity() has been called before the transaction has been mined.
     * @param liquidity - Liquidity to burn from this user.
     * @param amountAMin - The minimum amount of tokenA that must be received from the pool for the transaction not to revert.
     * @param amountBMin - The minimum amount of tokenB that must be received from the pool for the transaction not to revert.
     * @param recipient - Address which will receive withdrawn tokens.
     
     * @return amountA - Token A amount sent to the {recipient}.
     * @return amountB - Token B amount sent to the {recipient}.
     */
    function withdraw(uint256 pid, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address recipient) whenNotPaused nonReentrant external returns (uint256 amountA, uint256 amountB) {
        require (pid == poolID, 'BAD_POOL_ID');
        PoolInfo memory pool = pools[poolID];

        (uint256 leftoverA, uint256 leftoverB) = collectLeftovers(liquidity, recipient);

        uint256 amountLP = burn(liquidity);
        (amountA, amountB) = pool.assetRouter.withdraw(pool.pool, amountLP, amountAMin, amountBMin, recipient);

        amountA += leftoverA;
        amountB += leftoverB;

        emit WithdrawPairTokens(poolID, amountA, amountB);
        emit Withdraw(poolID, msg.sender, recipient, amountLP);
    }

    /**
     * @dev Withdraws tokens from the {pools[poolID]} pool and sends them to the recipient. Burns tokens representing user share. Emits {Withdraw} event.
     * @param pid - Current poolID. Throws revert if moveLiquidity() has been called before the transaction has been mined.
     * @param liquidity - Liquidity to burn from this user.
     * @param amountTokenMin - The minimum amount of tokenA that must be received from the pool for the transaction not to revert.
     * @param amountETHMin - The minimum amount of tokenB that must be received from the pool for the transaction not to revert.
     * @param recipient - Address which will receive withdrawn tokens.
     
     * @return amountToken - Token amount sent to the {recipient}.
     * @return amountETH - MATIC amount sent to the {recipient}.
     */
    function withdrawETH(uint256 pid, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address recipient) whenNotPaused nonReentrant external returns (uint256 amountToken, uint256 amountETH) {
        require (pid == poolID, 'BAD_POOL_ID');
        PoolInfo memory pool = pools[poolID];

        (uint256 leftoverA, uint256 leftoverB) = collectLeftovers(liquidity, recipient);

        uint256 amountLP = burn(liquidity);
        (amountToken, amountETH) = pool.assetRouter.withdrawETH(pool.pool, amountLP, amountTokenMin, amountETHMin, recipient);

        if (address(pool.tokenA) == WMATIC) {
            amountETH += leftoverA;
            amountToken += leftoverB;
        } else if (address(pool.tokenB) == WMATIC) {
            amountToken += leftoverA;
            amountETH += leftoverB;
        } else {
            revert("NOT_WMATIC_POOL");
        }
        
        emit WithdrawPairTokensETH(poolID, amountToken, amountETH);
        emit Withdraw(poolID, msg.sender, recipient, amountLP); 
    }

    /**
     * @dev Withdraws tokens from the {pools[poolID]} pool and sends them to the recipient. Burns tokens representing user share. Emits {Withdraw} event.
     * @param pid - Current poolID. Throws revert if moveLiquidity() has been called before the transaction has been mined.
     * @param liquidity - Liquidity to burn from this user.
     * @param token - Address of a token to exit the pool with.
     * @param swapData - Parameter with which 1inch router is being called with.
     * @param recipient - Address which will receive withdrawn tokens.
     
     * @return amountToken - {token} amount sent to the {recipient}.
     * @return amountA - Token A dust sent to the {recipient}.
     * @return amountB - Token B dust sent to the {recipient}.
     */
    function withdrawSingleAsset(uint256 pid, uint256 liquidity, address token, bytes[2] calldata swapData, address recipient) whenNotPaused nonReentrant external returns (uint256 amountToken, uint256 amountA, uint256 amountB) {
        require (pid == poolID, 'BAD_POOL_ID');
        PoolInfo memory pool = pools[poolID];

        (uint256 leftoverA, uint256 leftoverB) = collectLeftovers(liquidity, recipient);

        uint256 amountLP = burn(liquidity);
        (amountToken, amountA, amountB) = pool.assetRouter.withdrawSingleAsset(pool.pool, amountLP, token, swapData, recipient);

        amountA += leftoverA;
        amountB += leftoverB;

        emit WithdrawSingleToken(poolID, token, amountToken, amountA, amountB);
        emit Withdraw(poolID, msg.sender, recipient, amountLP); 
    }

    /**
     * @dev Withdraws tokens from the {pools[poolID]} pool and sends them to the recipient. Burns tokens representing user share. Emits {Withdraw} event.
     * @param pid - Current poolID. Throws revert if moveLiquidity() has been called before the transaction has been mined.
     * @param liquidity - Liquidity to burn from this user.
     * @param swapData - Parameter with which 1inch router is being called with.
     * @param recipient - Address which will receive withdrawn tokens.
     
     * @return amountETH - MATIC amount sent to the {recipient}.
     * @return amountA - Token A dust sent to the {recipient}.
     * @return amountB - Token B dust sent to the {recipient}.
     */
    function withdrawSingleETH(uint256 pid, uint256 liquidity, bytes[2] calldata swapData, address recipient) whenNotPaused nonReentrant external returns (uint256 amountETH, uint256 amountA, uint256 amountB) {
        require (pid == poolID, 'BAD_POOL_ID');
        PoolInfo memory pool = pools[poolID];

        (uint256 leftoverA, uint256 leftoverB) = collectLeftovers(liquidity, recipient);

        uint256 amountLP = burn(liquidity);
        (amountETH, amountA, amountB) = pool.assetRouter.withdrawSingleETH(pool.pool, amountLP, swapData, recipient);

        amountA += leftoverA;
        amountB += leftoverB;

        emit WithdrawSingleETH(poolID, amountETH, amountA, amountB);
        emit Withdraw(poolID, msg.sender, recipient, amountLP); 
    }

    /**
     * @dev Collects leftover tokens left from moveLiquidity() function.
     * @param recipient - Address which will receive leftover tokens.
     
     * @return leftoverA - Token A amount sent to the {recipient}.
     * @return leftoverB - Token B amount sent to the {recipient}.
     */
    function collectLeftovers(uint256 liquidity, address recipient) internal returns (uint256 leftoverA, uint256 leftoverB){
        uint256 availiableLiquidity = balanceOf(msg.sender) - blockedLiquidty[msg.sender][lastMoveInfo.block];
        if(availiableLiquidity == 0){
            return (0, 0);
        }
        if(liquidity > availiableLiquidity){
            liquidity = availiableLiquidity;
        }

        if(lastMoveInfo.totalSupply != 0){
            PoolInfo memory pool = pools[poolID];
            leftoverA = liquidity * lastMoveInfo.leftoverA / lastMoveInfo.totalSupply;
            leftoverB = liquidity * lastMoveInfo.leftoverB / lastMoveInfo.totalSupply;
            if(leftoverA > 0){
                pool.tokenA.safeTransfer(recipient, leftoverA);
            }
            if(leftoverB > 0){
                pool.tokenB.safeTransfer(recipient, leftoverB);
            }
        }
    }

    /**
     * @dev Moves liquidity from {pools[poolID]} to {pools[_poolID]}. Emits {MoveLiquidity} event.
     * @param _poolID - Pool ID to move liquidity to.
     * @param swapAData - Data for tokenA swap.
     * @param swapBData - Data for tokenB swap.
     * @param amountAMin - The minimum amount of tokenA that must be deposited in {pools[_poolID]} for the transaction not to revert.
     * @param amountBMin - The minimum amount of tokenB that must be deposited in {pools[_poolID]} for the transaction not to revert.
     *
     * Note: This function can only be called by LiquidityManager.
     */
    function moveLiquidity(uint256 _poolID, bytes calldata swapAData, bytes calldata swapBData, uint256 amountAMin, uint256 amountBMin) whenNotPaused nonReentrant external {
        require(accessManager.hasRole(LIQUIDITY_MANAGER_ROLE, msg.sender), 'CALLER_NOT_LIQUIDITY_MANAGER');
        require(totalSupply() != 0, 'NO_LIQUIDITY');
        require(lastMoveInfo.block != block.number, 'CANT_CALL_ON_THE_SAME_BLOCK');
        require((_poolID < pools.length) && (_poolID != poolID), 'BAD_POOL_ID');

        PoolInfo memory currentPool = pools[poolID];
        PoolInfo memory newPool = pools[_poolID];

        (uint256 _totalDeposits,,) = currentPool.assetRouter.userStake(address(this), currentPool.pool);
        currentPool.assetRouter.withdraw(currentPool.pool, _totalDeposits, 0, 0, address(this));

        uint256 tokenABalance = currentPool.tokenA.balanceOf(address(this));
        uint256 tokenBBalance = currentPool.tokenB.balanceOf(address(this));

        if(currentPool.tokenA != newPool.tokenA){
            (
                IOdosRouter.inputToken[] memory inputs, 
                IOdosRouter.outputToken[] memory outputs, 
                ,
                uint256 valueOutMin,
                address executor,
                bytes memory pathDefinition
            ) = abi.decode(swapAData[4:], (IOdosRouter.inputToken[],IOdosRouter.outputToken[],uint256,uint256,address,bytes));

            require((inputs.length == 1) && (outputs.length == 1), 'BAD_SWAP_A_TOKENS_LENGTH');
            require(inputs[0].tokenAddress == address(currentPool.tokenA), 'BAD_SWAP_A_INPUT_TOKEN');
            require(outputs[0].tokenAddress == address(newPool.tokenA), 'BAD_SWAP_A_OUTPUT_TOKEN');

            inputs[0].amountIn = tokenABalance;
            OdosRouter.swap(inputs, outputs, type(uint256).max, valueOutMin, executor, pathDefinition);
        }

        if(currentPool.tokenB != newPool.tokenB){
            (
                IOdosRouter.inputToken[] memory inputs,
                IOdosRouter.outputToken[] memory outputs,
                ,
                uint256 valueOutMin,
                address executor,
                bytes memory pathDefinition
            ) = abi.decode(swapBData[4:], (IOdosRouter.inputToken[],IOdosRouter.outputToken[],uint256,uint256,address,bytes));

            require((inputs.length == 1) && (outputs.length == 1), 'BAD_SWAP_B_TOKENS_LENGTH');
            require(inputs[0].tokenAddress == address(currentPool.tokenB), 'BAD_SWAP_B_INPUT_TOKEN');
            require(outputs[0].tokenAddress == address(newPool.tokenB), 'BAD_SWAP_B_OUTPUT_TOKEN');

            inputs[0].amountIn = tokenBBalance;
            OdosRouter.swap(inputs, outputs, type(uint256).max, valueOutMin, executor, pathDefinition);
        }
        
        (,,reserveLP) = newPool.assetRouter.deposit(newPool.pool, newPool.tokenA.balanceOf(address(this)), newPool.tokenB.balanceOf(address(this)), amountAMin, amountBMin, address(this));
       
        lastMoveInfo = MoveLiquidityInfo({
            leftoverA: newPool.tokenA.balanceOf(address(this)),
            leftoverB: newPool.tokenB.balanceOf(address(this)),
            totalSupply: totalSupply(),
            block: block.number
        });

        emit MoveLiquidity(poolID, _poolID); 
        poolID = _poolID;
    }

    /**
     * @dev Returns tokens staked by the {_address}. 
     * @param _address - The address to check stakes for.

     * @return stakeA - Token A stake.
     * @return stakeB - Token B stake.
     */
    function userStake(address _address) external view returns (uint256 stakeA, uint256 stakeB) {
        PoolInfo memory pool = pools[poolID];
        (, uint256 balanceA, uint256 balanceB) = pool.assetRouter.userStake(address(this), pool.pool);

        uint256 _balance = balanceOf(_address);
        if(_balance != 0){
            uint256 _totalSupply = totalSupply();
            stakeA = _balance * balanceA / _totalSupply; 
            stakeB = _balance * balanceB / _totalSupply; 
            if(lastMoveInfo.totalSupply != 0){
                stakeA += (_balance - blockedLiquidty[_address][lastMoveInfo.block]) * lastMoveInfo.leftoverA / lastMoveInfo.totalSupply;
                stakeB += (_balance - blockedLiquidty[_address][lastMoveInfo.block]) * lastMoveInfo.leftoverB / lastMoveInfo.totalSupply;
            }
        }
    }
        
    /**
     * @dev Returns total amount locked in the pool. 
     * @return totalDepositsA - Token A deposits.
     * @return totalDepositsB - Token B deposits.
     */     
    function totalDeposits() external view returns(uint256 totalDepositsA, uint256 totalDepositsB){
        PoolInfo memory pool = pools[poolID];
        (, totalDepositsA, totalDepositsB) = pool.assetRouter.userStake(address(this), pool.pool);

        // Add leftover tokens.
        totalDepositsA += pool.tokenA.balanceOf(address(this));
        totalDepositsB += pool.tokenB.balanceOf(address(this));
    }

    /**
     * @dev Returns the number of pools in the strategy. 
     */
    function poolsLength() external view returns(uint256){
        return pools.length;
    }

    /**
     * @dev Returns pair of tokens currently in use. 
     */
    function tokens() external view returns(address, address){
        PoolInfo memory pool = pools[poolID];
        return (address(pool.tokenA), address(pool.tokenB));
    }

    function mint(address to) internal returns (uint256 liquidity){
        PoolInfo memory pool = pools[poolID];
        (uint256 balanceLP,,) = pool.assetRouter.userStake(address(this), pool.pool);
        uint256 amountLP = balanceLP - reserveLP;

        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            liquidity = amountLP - MINIMUM_LIQUIDITY;
            _mint(address(1), MINIMUM_LIQUIDITY);
        } else {
            liquidity = amountLP * _totalSupply / reserveLP;
        }

        require(liquidity > 0, 'INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        reserveLP = balanceLP;
    }

    function burn(uint256 liquidity) internal returns (uint256 amountLP) {
        PoolInfo memory pool = pools[poolID];
        (uint256 balanceLP,,) = pool.assetRouter.userStake(address(this), pool.pool);

        amountLP = liquidity * balanceLP / totalSupply(); 
        require(amountLP > 0, 'INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(msg.sender, liquidity);

        reserveLP = balanceLP - amountLP;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        // Decrease blockedLiquidty from {from} address, but no less then 0.
        if(amount > blockedLiquidty[from][lastMoveInfo.block]){
            blockedLiquidty[from][lastMoveInfo.block] = 0;
        } else {
            blockedLiquidty[from][lastMoveInfo.block] -= amount;
        }
        // Block {to} address from withdrawing their share of leftover tokens immediately.
        blockedLiquidty[to][lastMoveInfo.block] += amount;
    }

    /**
     * @dev Transfers banxe rights of the contract to a new account (`_banxe`).
     * @param _banxe - Address to transfer banxe rights to.

     * Note: This function can only be called by Banxe.
     */
    function transferBanxe(address _banxe) external onlyBanxe {
        require(_banxe != address(0), "TRANSFER_TO_ZERO_ADDRESS");
        emit BanxeTransferred(banxe, _banxe);
        banxe = _banxe;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;
import "./IUnoAccessManager.sol"; 

interface IUnoFarmFactory {
    event FarmDeployed(address indexed farmAddress);
    
    function accessManager() external view returns (IUnoAccessManager);
    function assetRouter() external view returns (address);
    function farmBeacon() external view returns (address);
    function pools(uint256) external view returns (address);

    function Farms(address) external view returns (address);
    function createFarm(address pool) external returns (address);
    function poolLength() external view returns (uint256);
    function upgradeFarms(address newImplementation) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import '../interfaces/IUnoAccessManager.sol'; 

interface IUnoAutoStrategyFactory{
    struct PoolInfo {
        address assetRouter;
        address pool;
    }

    event AutoStrategyDeployed(address indexed autoStrategyAddress);
    event AssetRouterApproved(address indexed assetRouter);
    event AssetRouterRevoked(address indexed assetRouter);

    function assetRouterApproved(address) external view returns (bool);
    function accessManager() external view returns (IUnoAccessManager);
    function autoStrategyBeacon() external view returns (address);
    function autoStrategies(uint256) external view returns (address);

    function createStrategy(PoolInfo[] calldata poolInfos, string calldata name, string calldata symbol) external returns (address);
    function approveAssetRouter(address _assetRouter) external;
    function revokeAssetRouter(address _assetRouter) external;

    function upgradeStrategies(address newImplementation) external;
    function autoStrategiesLength() external view returns (uint256);

    function pause() external;
    function unpause() external;
    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

import './IUnoFarmFactory.sol';
import './IUnoAccessManager.sol'; 
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

interface IUnoAssetRouter {
    event Deposit(address indexed lpPool, address indexed from, address indexed recipient, uint256 amount);
    event Withdraw(address indexed lpPool, address indexed from, address indexed recipient, uint256 amount);
    event Distribute(address indexed lpPool, uint256 reward);

    function farmFactory() external view returns(IUnoFarmFactory);
    function accessManager() external view returns(IUnoAccessManager);

    function initialize(address _accessManager, address _farmFactory) external;

    function deposit(address lpPool, uint256 amountA, uint256 amountB, uint256 amountAMin, uint256 amountBMin, address recipient) external returns(uint256 sentA, uint256 sentB, uint256 liquidity);
    function depositETH(address lpPair, uint256 amountToken, uint256 amountTokenMin, uint256 amountETHMin, address recipient) external payable returns(uint256 sentToken, uint256 sentETH, uint256 liquidity);
    function depositSingleAsset(address lpPair, address token, uint256 amount, bytes[2] calldata swapData, uint256 amountAMin, uint256 amountBMin, address recipient) external returns(uint256 sent, uint256 liquidity);
    function depositSingleETH(address lpPair, bytes[2] calldata swapData, uint256 amountAMin, uint256 amountBMin, address recipient) external payable returns(uint256 sentETH, uint256 liquidity);
    function depositLP(address lpPair, uint256 amount, address recipient) external;

    function withdraw(address lpPool, uint256 amount, uint256 amountAMin, uint256 amountBMin, address recipient) external returns(uint256 amountA, uint256 amountB);
    function withdrawETH(address lpPair, uint256 amount, uint256 amountTokenMin, uint256 amountETHMin, address recipient) external returns(uint256 amountToken, uint256 amountETH);
    function withdrawSingleAsset(address lpPair, uint256 amount, address token, bytes[2] calldata swapData, address recipient) external returns(uint256 amountToken, uint256 amountA, uint256 amountB);
    function withdrawSingleETH(address lpPair,  uint256 amount, bytes[2] calldata swapData, address recipient) external returns(uint256 amountETH, uint256 amountA, uint256 amountB);
    function withdrawLP(address lpPair, uint256 amount, address recipient) external;

    function userStake(address _address, address lpPool) external view returns (uint256 stakeLP, uint256 stakeA, uint256 stakeB);
    function totalDeposits(address lpPool) external view returns (uint256 totalDepositsLP, uint256 totalDepositsA, uint256 totalDepositsB);
    function getTokens(address lpPool) external view returns(address[] memory tokens);

    function paused() external view returns(bool);
    function pause() external;
    function unpause() external;

    function upgradeTo(address newImplementation) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

interface IUnoAccessManager {
    event RoleGranted(bytes32 indexed role, address indexed account);
    event RoleRevoked(bytes32 indexed role, address indexed account);

    function hasRole(bytes32 role, address account) external view returns (bool);
    function ADMIN_ROLE() external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IOdosRouter {
    struct inputToken {
      address tokenAddress;
      uint256 amountIn;
      address receiver;
      bytes permit;
    }

    struct outputToken {
      address tokenAddress;
      uint256 relativeValue;
      address receiver;
    }

 function swap(
    inputToken[] memory inputs,
    outputToken[] memory outputs,
    uint256 valueOutQuote,
    uint256 valueOutMin,
    address executor,
    bytes calldata pathDefinition
  ) external payable returns (uint256[] memory amountsOut, uint256 gasLeft);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}