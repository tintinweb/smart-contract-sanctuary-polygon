/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

interface IUniswapV2Factory {

  function getPair(address tokenA, address tokenB) external view returns (address pair);
    
}

interface IUniswapV2Router {

  function addLiquidity(
    address tokenA, address tokenB,
    uint amountADesired, uint amountBDesired,
    uint amountAMin, uint amountBMin,
    address to, uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

  function removeLiquidity(
    address tokenA, address tokenB,
    uint liquidity,
    uint amountAMin, uint amountBMin,
    address to, uint deadline) external returns (uint amountA, uint amountB);
    
}

interface MiniChefV2 {
    
    /// @notice Deposit LP tokens to MCV2 for SUSHI allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to deposit.
    /// @param to The receiver of `amount` deposit benefit.
    function deposit(uint256 pid, uint256 amount, address to) external;

    /// @notice Withdraw LP tokens from MCV2.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdraw(uint256 pid, uint256 amount, address to) external;
    
    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of SUSHI rewards.
    function harvest(uint256 pid, address to) external;
    
    /// @notice Withdraw LP tokens from MCV2 and harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens and SUSHI rewards.
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
    
}

contract TestSimpleContract {
    
    address internal constant sushi = 0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a;
    address internal constant wmatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address internal constant factory_address = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    address internal constant router_address = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address internal constant staking_contract_address = 0x0769fd68dFb93167989C6f7254cd0D766Fb2841F;
    
    IUniswapV2Factory public constant factory = IUniswapV2Factory(factory_address);
    IUniswapV2Router public constant router = IUniswapV2Router(router_address);
    MiniChefV2 public constant staking_contract = MiniChefV2(staking_contract_address);
    
    uint256 public pid = 13;
    address public owner;

    event Log(string message, uint val);
    event LogStep(string message);
    // Max amount => 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }
    
    function approveForContract(address _token, address _spender, uint _amount) external ownerOnly {
        IERC20(_token).approve(_spender, _amount);
    }
    
    function changePid(uint _pid) external ownerOnly {
        pid = _pid;
    }
    
    function balanceOf(address _token, address _address) external ownerOnly view returns (uint) {
        return IERC20(_token).balanceOf(_address);
    }
    
    function allowance(address _token, address _owner, address _spender) external ownerOnly view returns (uint) {
        return IERC20(_token).allowance(_owner, _spender);
    }
    
    function transferToContract(address _token, uint _amount) public ownerOnly {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    }
    
    function transferBack(address _token, uint _amount) public ownerOnly {
        IERC20(_token).approve(address(this), _amount);
        IERC20(_token).transferFrom(address(this), msg.sender, _amount);
    }
    
    function addLiquidity(address _tokenA, address _tokenB, uint _amountA, uint _amountB) public ownerOnly returns (uint){
        
        IERC20(_tokenA).approve(router_address, _amountA);
        IERC20(_tokenB).approve(router_address, _amountB);
        
        (uint amountA, uint amountB, uint liquidity) = router.addLiquidity(_tokenA, _tokenB, _amountA, _amountB, 1, 1, address(this), block.timestamp);
        
        emit Log("amountA", amountA);
        emit Log("amountB", amountB);
        emit Log("liquidity", liquidity);
        
        return liquidity;
    }
    
    function deposit(address _tokenLP, uint _amountLP, address _to) public ownerOnly {
        require(_amountLP > 0, "Cannot stake 0");
        IERC20(_tokenLP).approve(staking_contract_address, _amountLP);
        staking_contract.deposit(pid, _amountLP, _to);
    }
    
    function harvest(address _to) public ownerOnly {
        staking_contract.harvest(pid, _to);
    }
    
    function withdraw(uint _amountLP, address _to) public ownerOnly {
        staking_contract.withdraw(pid, _amountLP, _to);
    }
    
    function removeLiquidity(address _tokenLP, address _tokenA, address _tokenB, uint _liquidity) public ownerOnly {
        
        IERC20(_tokenLP).approve(router_address, _liquidity);
        (uint amountA, uint amountB) = router.removeLiquidity(_tokenA, _tokenB, _liquidity, 1, 1, address(this), block.timestamp);
        
        emit Log("amountA", amountA);
        emit Log("amountB", amountB);
    }
    
    function arbitrage(address _tokenA, address _tokenB, uint _amountA, uint _amountB) public ownerOnly {
        
        address _tokenLP = factory.getPair(_tokenA, _tokenB);
        
        // Step 1 transfer from wallet to contract
        transferToContract(_tokenA, _amountA);
        transferToContract(_tokenB, _amountB);
        emit LogStep("Step 1 done.");
        
        // Step 2 add liquidity to get LP token(need calculate LP token amount with slippage)
        uint liquidity = addLiquidity(_tokenA, _tokenB, _amountA, _amountB);
        emit LogStep("Step 2 done.");
        
        // Step 3 use LP token to staking(deposite)
        deposit(_tokenLP, liquidity, address(this));
        emit LogStep("Step 3 done.");
        
        // Step 4 get reward to wallet(harvest)
        harvest(address(this));
        emit LogStep("Step 4 done.");
        
        // Step 5 unstake to get LP token(withdraw)
        withdraw(liquidity, address(this));
        emit LogStep("Step 5 done.");
        
        // Step 6 remove liquidity to get coin back
        removeLiquidity(_tokenLP, _tokenA, _tokenB, liquidity);
        emit LogStep("Step 6 done.");
        
        // Step 7 transfer from contract to wallet
        uint sushi_balance = IERC20(sushi).balanceOf(address(this));
        uint tokenA_balance = IERC20(_tokenA).balanceOf(address(this));
        uint tokenB_balance = IERC20(_tokenB).balanceOf(address(this));
        transferBack(sushi, sushi_balance);
        transferBack(_tokenA, tokenA_balance);
        transferBack(_tokenB, tokenB_balance);
        emit LogStep("Step 7 done.");
    }
    
}