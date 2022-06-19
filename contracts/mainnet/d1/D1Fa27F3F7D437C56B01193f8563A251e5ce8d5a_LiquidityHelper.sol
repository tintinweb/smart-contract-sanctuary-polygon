// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "../interfaces/IERC20.sol";
import "../interfaces/IWrappedAToken.sol";
import "../interfaces/IUniswapV2Router01.sol";
import "../interfaces/ILiquidityHelper.sol";
import "../interfaces/IMasterChef.sol";

/*******************************************************************************
This contract contains many helper functions to manage liquidity for the
gotchiverse tokens and some wrappers to help automate the process

It has two main modes of operation:
- Automated:
  As a thirdparty address who receives alchemica directly and is
  called regularily by an EOA to stake it for GLTR (in the contract)

- Manual:
  As a tool to facilitate the operation of getting the liquidity tokens
  required to stake for GLTR (outside of the contract) or converting to GHST

Optionnally it can:
- convert a portion of the alchemica to wapGHST for single staking
- pool GLTR with GHST to get more GLTR

1. Deploy the contract by providing
   - GLTR token address
   - list of alchemica token addresses
   - list of LP token address for each GHST pair
   - the GLTR staking contract address
   - the DEX router address
   - the GHST token address
   - the wapGHST token address
   - the owner address
   - the operator address (for manual use this could be the owner)
   - the recipient address (for manual use this could be the owner)

2. Configure the contract for your use case
   Automated:
   - make sure doStaking is set to true
   - set a singlePercentGHST to stake a portion as wapGHST
   - set poolGLTR to true if you want to stake GLTR-GHST too
     or set a recipient for the collected GLTR (if not sent to owner)
   - set the operator address if using a bot to call the contract
   - set returnLPTokens to false to leave the pool when unstaking
   Manual:
   - make sure doStaking is set to false
   - make sure returnLPTokens is set to true
   - set poolGLTR to true if you want to LP GLTR-GHST too
   - set a singlePercentGHST to convert a portion to wapGHST

3. Use the contract
   Automated:
   - use the address of the contract as recipient for farmed alchemica
   - call processAllTokens function regularily from the operator address
     if poolGLTR is false accrued GLTR will be sent to the recipient address
   - when done staking call returnAllTokens to retrieve your liquidity
   Manual:
   - send some tokens to the contract OR
     set allowance for the contract to spend each token
     and transfer them the using either of
     - transferAllPoolableTokensFromOwner
     - transferPercentageOfAllPoolableTokensFromOwner
     note: those include alchemica and GLTR
   - call processAllTokens to swap and pool all tokens
     OR
     call swapAllPoolableTokensForGHST to convert all tokens to GHST
   - call returnAllTokens
   - got to https://app.aavegotchi.com/stake-gltr and stake your LP tokens
*******************************************************************************/
contract LiquidityHelper is ILiquidityHelper {
    error LengthMismatch();
    // pool 0 is single wapGHST staking
    uint256[] pools = [0,1,2,3,4,7];
    address GLTR;
    //0--fud
    //1--fomo
    //2--alpha
    //3--kek
    address[4] alchemicaTokens;
    //0--ghst-fud (pid 1)
    //1--ghst-fomo (pid 2)
    //2--ghst-alpha (pid 3)
    //3--ghst-kek (pid 4)
    //4--ghst-gltr (pid 7)
    address[] lpTokens;
    // staking contract
    IMasterChef farm;
    // quickswap router
    IUniswapV2Router01 router;
    address GHST;
    address wapGHST;
    // owner can change settings and withdraw
    address owner;
    // operator can only execute the contract
    address operator;
    // address where to send GLTR (if not LPing it)
    address recipient;
    // use generated GLTR to add liquidity to the GHST-GLTR pool
    bool poolGLTR = false;
    // stake LP tokens for GLTR in the contract
    bool doStaking = true;
    // when withdrawing return LP tokens for staking
    bool returnLPTokens = false;
    // do not swap balance lower than this
    uint256 minAmount = 100000000000000000; // do not set to 0, 1 means any amount
    // percentage of tokens to stake as wapGHST (single side staking)
    uint256 singleGHSTPercent = 0;

    constructor(
        address _gltr,
        address[4] memory _alchemicaTokens,
        address[] memory _pairAddresses, //might be more than 4 pairs
        address _farmAddress,
        address _routerAddress,
        address _ghst,
        address _wrappedAmGhst,
        address _owner,
        address _operator,
        address _recipient
    ) {
        //approve GHST for deposit and wrapping as amToken
        require(IERC20(_ghst).approve(_routerAddress, type(uint256).max));
        require(IERC20(_ghst).approve(_wrappedAmGhst, type(uint256).max));
        //approve wapGHST for deposit and staking
        require(IERC20(_wrappedAmGhst).approve(_routerAddress, type(uint256).max));
        require(IERC20(_wrappedAmGhst).approve(_farmAddress, type(uint256).max));
        //approve GLTR for deposit
        require(IERC20(_gltr).approve(_routerAddress, type(uint256).max));
        //approve each alchemica for deposit
        for (uint256 i; i < _alchemicaTokens.length; i++) {
            require(
                IERC20(_alchemicaTokens[i]).approve(
                    _routerAddress,
                    type(uint256).max
                )
            );
        }
        //approve each lp tokens for withdrawal
        for (uint256 i; i < _pairAddresses.length; i++) {
            require(
                IERC20(_pairAddresses[i]).approve(
                    _routerAddress,
                    type(uint256).max
                )
            );
        }
        //approve each lp tokens for staking
        for (uint256 i; i < _pairAddresses.length; i++) {
            require(
                IERC20(_pairAddresses[i]).approve(
                    _farmAddress,
                    type(uint256).max
                )
            );
        }
        GLTR = _gltr;
        alchemicaTokens = _alchemicaTokens;
        lpTokens = _pairAddresses;
        farm = IMasterChef(_farmAddress);
        router = IUniswapV2Router01(_routerAddress);
        GHST = _ghst;
        wapGHST = _wrappedAmGhst;
        owner = _owner;
        operator = _operator;
        recipient = _recipient;
    }

    //
    // modifiers
    //

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Not Operator");
        _;
    }

    modifier onlyOperatorOrOwner() {
        require(
            msg.sender == operator || msg.sender == owner,
            "Not Operator or Owner"
        );
        _;
    }

    //
    // events
    //

    event receiveGHST(uint256 _amount);

    event processToken(address _token, uint256 _amount);

    event sendReward(uint256 _amount);

    event unwrapGHST(uint256 _shares, uint256 _assets);

    event returnToken(address _token, uint256 _amount);

    //
    // getters
    //

    /// @notice Get balance of LP tokens staked in a pool
    /// @param _poolId ID of the pool to query
    /// @return ui A struct containing the balance and accrued reward
    function getStakingPoolBalance(uint256 _poolId)
        public
        view
        returns(IMasterChef.UserInfo memory ui)
    {
        ui = farm.userInfo(
            _poolId,
            address(this)
        );
        return (ui);
    }

    /// @notice Retrieve pooling of GLTR with GHST status
    function getPoolGLTR() external view returns (bool) {
        return poolGLTR;
    }

    /// @notice Retrieve staking for GLTR status
    function getDoStaking() external view returns (bool) {
        return doStaking;
    }

    /// @notice Retrieve wether to return LP receipts or tokens
    function getReturnLPTokens() external view returns (bool) {
        return returnLPTokens;
    }

    /// @notice Retrieve owner address
    function getContractOwner() external view returns (address) {
        return owner;
    }

    /// @notice Retrieve operator address
    function getOperator() external view returns (address) {
        return operator;
    }

    /// @notice Retrieve recipient address
    function getRecipient() external view returns (address) {
        return recipient;
    }

    /// @notice Retrieve minimum amount for swaps
    function getMinAmount() external view returns (uint256) {
        return minAmount;
    }

    /// @notice Retrieve percentage of token to swap for wapGHST
    function getSingleGHSTPercent() external view returns (uint256) {
        return singleGHSTPercent;
    }

    //
    // setters
    //

    /// @notice Allow another contract to spend this contract tokens
    /// @param _token Address of token to spend
    /// @param _spender Address of the contract to allow
    function setApproval(address _token, address _spender) public onlyOwner {
        require(IERC20(_token).approve(_spender, type(uint256).max));
    }

    /// @notice Set operator address
    /// @param _operator Address of the operator
    function setOperator(address _operator) external onlyOwner {
        assert(_operator != address(0));
        operator = _operator;
    }

    /// @notice Set recipient address.
    /// @param _recipient Address of the recipient
    function setRecipient(address _recipient) external onlyOwner {
        assert(_recipient != address(0));
        recipient = _recipient;
    }

    /// @notice Turn pooling of GLTR on or off
    /// @param _poolGLTR If true use accrued GLTR to add
    ///  liquidity to the GHST-GLTR pool
    function setPoolGLTR(bool _poolGLTR) external onlyOwner {
        poolGLTR = _poolGLTR;
    }

    /// @notice Enable staking for GLTR
    /// @param _doStaking If true wapGHST and LP tokens will
    ///  be staked for GLTR when processAllTokens is called
    function setDoStaking(bool _doStaking) external onlyOwner {
        doStaking = _doStaking;
    }

    /// @notice Specify to return LP token receipts instead
    ///  of the underlying tokens when withdrawing all tokens.
    ///  Useful if planning to stake outside of the contract
    /// @param _returnLPTokens If true return LP tokens
    function setReturnLPTokens(bool _returnLPTokens) external onlyOwner {
        returnLPTokens = _returnLPTokens;
    }

    /// @notice Set minimum amount for swaps
    ///  Avoid wasting gas on dust amounts
    ///  Set to 1 for no minimum
    /// @param _amount Minimum amount (in wei)
    function setMinAmount(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Minimum amount should be greater than 0");
        minAmount = _amount;
    }

    /// @notice Set percentage of tokens that will be converted to wapGHST
    ///  Set to 0 to disable
    /// @param _percent Percentage of tokens to swap
    function setSingleGHSTPercent(uint256 _percent) external onlyOwner {
        require(_percent >= 0 && _percent < 100, "Percentage should between 1-99 or 0 to disable");
        singleGHSTPercent = _percent;
    }

    /// @notice Set contract owner
    /// @param _owner Address of new owner
    function transferOwnership(address _owner) external onlyOwner {
        assert(_owner != address(0));
        owner = _owner;
    }

    //
    // helpers
    //

    /// @notice Transfer tokens from owner wallet
    /// @param _token Address of the token to transfer
    /// @param _amount Amount of tokens to transfer (in wei)
    function transferTokenFromOwner(address _token, uint256 _amount) public onlyOwner {
        uint256 allowance = IERC20(_token).allowance(msg.sender, address(this));
        require(allowance >= _amount, "Insufficient allowance");
        require(
            IERC20(_token).transferFrom(
                msg.sender,
                address(this),
                _amount
            )
        );
    }

    /// @notice Return tokens to owner.
    ///  Number of amounts must match number of tokens.
    ///  Index of amounts and tokens must correspond
    /// @param _tokens List of tokens to return
    /// @param _amounts List of respective amount of tokens to return
    function returnTokens(
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external onlyOwner {
        if (_tokens.length != _amounts.length) revert LengthMismatch();
        for (uint256 i; i < _tokens.length; i++) {
            require(IERC20(_tokens[i]).transfer(owner, _amounts[i]));
        }
    }

    /// @notice Stake LP receipt token for GLTR
    /// @param _args A StakePoolTokenArgs struct containing
    ///  the pool and the amount of tokens to stake
    function stakePoolToken(StakePoolTokenArgs memory _args)
        public
        onlyOperatorOrOwner
    {
        farm.deposit(
            _args._poolId,
            _args._amount
        );
    }

    function batchStakePoolToken(StakePoolTokenArgs[] memory _args)
        external
    {
        for (uint256 i; i < _args.length; i++) {
            stakePoolToken(_args[i]);
        }
    }

    /// @notice Unstake LP receipt token from GLTR farm
    /// @param _args A UnstakePoolTokenArgs struct containing
    ///  the pool and the amount of tokens to retrieve
    function unstakePoolToken(UnstakePoolTokenArgs memory _args)
        public
        onlyOwner
    {
        farm.withdraw(
            _args._poolId,
            _args._amount
        );
    }

    function batchUnstakePoolToken(UnstakePoolTokenArgs[] memory _args)
        external
    {
        for (uint256 i; i < _args.length; i++) {
            unstakePoolToken(_args[i]);
        }
    }

    /// @notice Claim GLTR rewards from a pool.
    ///  The tokens are returned to the contract
    /// @param _poolId The ID of the pool to harvest
    function claimReward(uint256 _poolId)
        external
        onlyOperatorOrOwner
    {
        farm.harvest(_poolId);
    }

    function batchClaimReward(uint256[] memory _pools)
        external
    {
        farm.batchHarvest(_pools);
    }

    /// @notice Swap a token for its GHST equivalent value
    /// @param _args A SwapTokenForGHSTArgs struct containing
    ///  the amounts desired in and out and the routing path
    function swapTokenForGHST(SwapTokenForGHSTArgs memory _args)
        public
        onlyOperatorOrOwner
    {
        address[] memory path = new address[](2);
            path[0] = _args._token;
            path[1] = GHST;
        uint256[] memory amounts = router.swapExactTokensForTokens(
            _args._amount,
            _args._amountMin,
            path,
            address(this),
            block.timestamp + 3000
        );
        emit receiveGHST(amounts[1]);
    }

    function batchSwapTokenForGHST(SwapTokenForGHSTArgs[] memory _args)
        external
    {
        for (uint256 i; i < _args.length; i++) {
            swapTokenForGHST(_args[i]);
        }
    }

    /// @notice Provide liquidity to a pool
    /// @param _args A AddLiquidityArgs struct containing:
    ///  the tokens pair,
    ///  the amount of token to supply for each,
    ///  the minimum amounts to supply for each token
    function addLiquidity(AddLiquidityArgs memory _args) public onlyOperatorOrOwner {
        router.addLiquidity(
            _args._tokenA,
            _args._tokenB,
            _args._amountADesired,
            _args._amountBDesired,
            _args._amountAMin,
            _args._amountBMin,
            address(this),
            block.timestamp + 3000
        );
    }

    function batchAddLiquidity(AddLiquidityArgs[] memory _args) external {
        for (uint256 i; i < _args.length; i++) {
            addLiquidity(_args[i]);
        }
    }

    /// @notice Withdraw liquidity from a pool
    /// @param _args A RemoveLiquidityArgs struct containing:
    ///  pair of token to retrieve,
    ///  amount of LP token to redeem,
    ///  minimum amounts of each token to receive
    function removeLiquidity(RemoveLiquidityArgs memory _args)
        public
        onlyOwner
    {
        router.removeLiquidity(
            _args._tokenA,
            _args._tokenB,
            _args._liquidity,
            _args._amountAMin,
            _args._amountBMin,
            address(this),
            block.timestamp + 3000
        );
    }

    function batchRemoveLiquidity(RemoveLiquidityArgs[] memory _args)
        external
    {
        for (uint256 i; i < _args.length; i++) {
            removeLiquidity(_args[i]);
        }
    }

    //
    // wrappers
    //

    /// @notice Transfer tokens directly from owner wallet.
    ///  The caller is responsible for making sure the contract
    ///  has sufficient allowance to each token.
    ///  Transfer the balance of all alchemica tokens to the contract.
    ///  Also transfer GLTR balance if poolGLTR is true
    function transferAllPoolableTokensFromOwner() external onlyOwner {
        uint256 balance;
        // transfer alchemica
        for (uint256 i; i < alchemicaTokens.length; i++) {
            balance = IERC20(alchemicaTokens[i]).balanceOf(msg.sender);
            if (balance > 0) {
                transferTokenFromOwner(alchemicaTokens[i], balance);
            }
        }
        // transfer GLTR if to be pooled
        if (poolGLTR) {
            balance = IERC20(GLTR).balanceOf(msg.sender);
            if (balance > 0) {
                transferTokenFromOwner(GLTR, balance);
            }
        }
    }

    /// @notice Transfer a percentage of tokens directly from owner wallet.
    ///  The caller is responsible for making sure the contract
    ///  has sufficient allowance to each token.
    ///  Transfer a portion of all alchemica tokens to the contract.
    ///  Also transfer a portion of GLTR if poolGLTR is true
    /// @param _percent Percentage of tokens to transfer
    function transferPercentageOfAllPoolableTokensFromOwner(uint256 _percent) external onlyOwner {
        require(_percent > 0 && _percent < 100, "Percentage need to be between 1-99");
        uint256 balance;
        uint256 amount;
        // transfer alchemica
        for (uint256 i; i < alchemicaTokens.length; i++) {
            balance = IERC20(alchemicaTokens[i]).balanceOf(msg.sender);
            if (balance > 0) {
                amount = balance*_percent/100;
                transferTokenFromOwner(alchemicaTokens[i], amount);
            }
        }
        // transfer GLTR if to be pooled
        if (poolGLTR) {
            balance = IERC20(GLTR).balanceOf(msg.sender);
            if (balance > 0) {
                amount = balance*_percent/100;
                transferTokenFromOwner(GLTR, amount);
            }
        }
    }

    /// @notice Withdraw liquidity from all pools
    function unpoolAllTokens() public onlyOwner {
        uint256 balance;
        RemoveLiquidityArgs memory arg;
        // remove liquidity from all alchmicas pools
        for (uint256 i; i < alchemicaTokens.length; i++) {
            balance = IERC20(lpTokens[i]).balanceOf(address(this));
            if (balance > 0) {
                arg = RemoveLiquidityArgs(
                    GHST,
                    alchemicaTokens[i],
                    balance,
                    0,
                    0
                );
                removeLiquidity(arg);
            }
        }
        // remove liquidity for GLTR pool (5th pair)
        balance = IERC20(lpTokens[4]).balanceOf(address(this));
        if (balance > 0) {
            arg = RemoveLiquidityArgs(
                GHST,
                GLTR,
                balance,
                0,
                0
            );
            removeLiquidity(arg);
        }
    }

    /// @notice Recover all tokens from GLTR staking contract
    function unstakeAllPools() public onlyOwner {
        uint256 pool;
        uint256 balance;
        UnstakePoolTokenArgs memory arg;
        for (uint256 i; i < pools.length; i++) {
            pool = pools[i];
            balance = getStakingPoolBalance(pool).amount;
            if (balance > 0) {
                arg = UnstakePoolTokenArgs(
                    pool,
                    balance
                );
                unstakePoolToken(arg);
            }
        }
    }

    /// @notice Withdraw all tokens from contract.
    ///  Remove liquidity from the pools unless returnLPTokens is true
    function returnAllTokens() external onlyOwner {
        uint256 balance;
        // unstake and claim GLTR from all pools
        unstakeAllPools();
        if (returnLPTokens) {
            // return lp tokens
            for (uint256 i; i < lpTokens.length; i++) {
                balance = IERC20(lpTokens[i]).balanceOf(address(this));
                if (balance > 0) {
                    require(IERC20(lpTokens[i]).transfer(owner, balance));
                    emit returnToken(lpTokens[i], balance);
                }
            }
        } else {
            // remove liquidity from all pools
            unpoolAllTokens();
        }
        // unwrap wapGHST
        balance = IERC20(wapGHST).balanceOf(address(this));
        if (balance > 0) {
            uint256 assets;
            assets = IWrappedAToken(wapGHST).leaveToUnderlying(balance);
            emit unwrapGHST(balance, assets);
        }
        // return GHST
        balance = IERC20(GHST).balanceOf(address(this));
        if (balance > 0) {
            require(IERC20(GHST).transfer(owner, balance));
            emit returnToken(GHST, balance);
        }
        // return GLTR
        balance = IERC20(GLTR).balanceOf(address(this));
        if (balance > 0) {
            require(IERC20(GLTR).transfer(owner, balance));
            emit returnToken(GLTR, balance);
        }
        // return alchemica
        for (uint256 i; i < alchemicaTokens.length; i++) {
            balance = IERC20(alchemicaTokens[i]).balanceOf(address(this));
            if (balance > 0) {
                require(IERC20(alchemicaTokens[i]).transfer(owner, balance));
                emit returnToken(alchemicaTokens[i], balance);
            }
        }
    }

    /// @notice Swap a portion of all alchemica in the contract for GHST
    /// @param _percent Percentage of tokens to swap
    function swapPercentageOfAllAlchemicaTokensForGHST(uint256 _percent) public onlyOperatorOrOwner {
        require(_percent > 0 && _percent < 100, "Percentage need to be between 1-99");
        uint256 balance;
        uint256 amount;
        SwapTokenForGHSTArgs memory arg;
        // swap all alchemica tokens
        for (uint256 i; i < alchemicaTokens.length; i++) {
            balance = IERC20(alchemicaTokens[i]).balanceOf(address(this));
            if (balance >= minAmount) {
                amount = balance*_percent/100;
                // swap token for GHST
                arg = SwapTokenForGHSTArgs(
                    alchemicaTokens[i],
                    // swap half of the balance
                    amount,
                    0
                );
                swapTokenForGHST(arg);
            }
        }
    }

    /// @notice swap all alchemica and GLTR in the contract for GHST
    function swapAllPoolableTokensForGHST() external onlyOwner {
        uint256 balance;
        SwapTokenForGHSTArgs memory arg;
        // swap all alchemica tokens for GHST
        for (uint256 i; i < alchemicaTokens.length; i++) {
            balance = IERC20(alchemicaTokens[i]).balanceOf(address(this));
            if (balance >= minAmount) {
                arg = SwapTokenForGHSTArgs(
                    alchemicaTokens[i],
                    balance,
                    0
                );
                swapTokenForGHST(arg);
            }
        }
        // swap GLTR for GHST
        balance = IERC20(GLTR).balanceOf(address(this));
        if (balance >= minAmount) {
            arg = SwapTokenForGHSTArgs(
                GLTR,
                balance,
                0
            );
            swapTokenForGHST(arg);
        }
    }

    /// @notice Swap, pool and optionally stake all tokens.
    ///  Swap a portion of each alchemica for wapGHST if
    //   singleGHSTPercent is not set to 0.
    ///  Stake wapGHST and LP tokens for GLTR if doStaking is true.
    ///  Swap and pool collected GLTR with GHST if poolGLTR is true
    ///  otherwise send it to the recipient address
    /// @dev To save gas no explicit claiming is done in this function
    ///  because adding to the stake claims automatically but this
    ///  has some implications:
    ///  - if some token balance is lower than minAmount claiming will not be
    ///    done for that pool
    ///  - if doStaking is set to false after some liquidities have been staked
    ///    rewards will need to be claimed independently by calling claimReward
    ///  - if poolGLTR is true claimed GLTR will be autocompouned only next time
    ///    this function is called
    function processAllTokens() external onlyOperatorOrOwner {
        SwapTokenForGHSTArgs memory swapArg;
        AddLiquidityArgs memory poolArg;
        uint256 balance;
        if (singleGHSTPercent > 0) {
            // swap alchemica for single staking first
            swapPercentageOfAllAlchemicaTokensForGHST(singleGHSTPercent);
            balance = IERC20(GHST).balanceOf(address(this));
            if (balance > 0) {
                // wrap GHST
                IWrappedAToken(wapGHST).enterWithUnderlying(balance);
                // stake wapGHST
                if (doStaking) {
                    StakePoolTokenArgs memory stakeArg = StakePoolTokenArgs(
                        0, // pool 0 = single staking wapGHST for gltr
                        IERC20(wapGHST).balanceOf(address(this))
                    );
                    stakePoolToken(stakeArg);
                }
                emit processToken(wapGHST, balance);
            }
        }

        // swap, pool (and optionally stake) all the alchemica that is left
        // done one by one to always have the right amount of GHST for each
        for (uint256 i; i < alchemicaTokens.length; i++) {
            balance = IERC20(alchemicaTokens[i]).balanceOf(address(this));
            if (balance >= minAmount) {
                // swap tokens for GHST
                swapArg = SwapTokenForGHSTArgs(
                    alchemicaTokens[i],
                    // swap half
                    balance/2,
                    0
                );
                swapTokenForGHST(swapArg);
                // pool tokens with GHST
                poolArg = AddLiquidityArgs(
                    GHST,
                    alchemicaTokens[i],
                    IERC20(GHST).balanceOf(address(this)),
                    IERC20(alchemicaTokens[i]).balanceOf(address(this)),
                    0,
                    0
                );
                addLiquidity(poolArg);
                // if staking pool tokens in contract
                if (doStaking) {
                    // stake liquidity pool receipt for GLTR
                    StakePoolTokenArgs memory stakeArg = StakePoolTokenArgs(
                        i+1, // pools 1-4 = ghst-fud, ghst-fomo, ghst-alpha, ghst-kek
                        IERC20(lpTokens[i]).balanceOf(address(this))
                    );
                    stakePoolToken(stakeArg);
                }
                emit processToken(alchemicaTokens[i], balance);
            }
        }

        // get final GLTR balance
        balance = IERC20(GLTR).balanceOf(address(this));
        // if pooling GLTR with GHST
        if (poolGLTR) {
            if (balance >= minAmount) {
                // split GLTR for GHST
                swapArg = SwapTokenForGHSTArgs(
                    GLTR,
                    // swap half of the balance
                    balance/2,
                    0
                );
                swapTokenForGHST(swapArg);
                // pool GLTR with GHST
                poolArg = AddLiquidityArgs(
                    GHST,
                    GLTR,
                    IERC20(GHST).balanceOf(address(this)),
                    IERC20(GLTR).balanceOf(address(this)),
                    0,
                    0
                );
                addLiquidity(poolArg);
                // if staking stake GLTR too
                if (doStaking) {
                    // stake LP receipt
                    StakePoolTokenArgs memory stakeArg = StakePoolTokenArgs(
                        // 5th pair: ghst-gltr (pid 7)
                        7,
                        IERC20(lpTokens[4]).balanceOf(address(this))
                    );
                    stakePoolToken(stakeArg);
                }
                emit processToken(GLTR, balance);
            }
        } else {
            // send GLTR to recipient
            if (balance > 0) {
                require(IERC20(GLTR).transfer(recipient, balance));
                emit sendReward(balance);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC20 {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IWrappedAToken {
    function enterWithUnderlying(uint256 assets) external returns (uint256);
    function leaveToUnderlying(uint256 shares) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ILiquidityHelper {

  struct StakePoolTokenArgs {
    uint256 _poolId;
    uint256 _amount;
  }

  struct UnstakePoolTokenArgs {
    uint256 _poolId;
    uint256 _amount;
  }

  struct SwapTokenForGHSTArgs {
    address _token;
    uint256 _amount;
    uint256 _amountMin;
  }

  struct AddLiquidityArgs {
    address _tokenA;
    address _tokenB;
    uint256 _amountADesired;
    uint256 _amountBDesired;
    uint256 _amountAMin;
    uint256 _amountBMin;
    // bool _legacy;
  }

  struct RemoveLiquidityArgs {
    address _tokenA;
    address _tokenB;
    uint256 _liquidity;
    uint256 _amountAMin;
    uint256 _amountBMin;
    // bool _legacy;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IMasterChef {
    
    struct UserInfo {
      uint256 amount; // How many LP tokens the user has provided.
      uint256 rewardDebt; // Reward debt.
    }

    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function harvest(uint256 _pid) external;
    function batchHarvest(uint256[] memory _pids) external;
    function userInfo(uint256 _pid, address _user)
        external
        view
        returns
    (
        UserInfo memory ui
    );
    
}