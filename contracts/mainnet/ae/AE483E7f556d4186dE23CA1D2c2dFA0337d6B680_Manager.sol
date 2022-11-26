/**
 *Submitted for verification at polygonscan.com on 2022-11-26
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// File: contracts/utils/SmartWallet.sol


pragma solidity ^0.8.9;


abstract contract SmartWallet { 

  mapping (address => mapping(address => uint)) public userBalances; // UserAddress => TokenAddress => depositedBalance

  function deposit(IERC20 token, uint amount)public {
    token.transferFrom(address(msg.sender), address(this), amount);
    userBalances[msg.sender][address(token)] += amount;
  }

  function withdrawToken(IERC20 token, uint amount) public {
    require(userBalances[msg.sender][address(token)]>= amount, "the user dont have balance");

    token.transferFrom( address(this), address(msg.sender), amount);
    userBalances[msg.sender][address(token)] -= amount;
  }
  
}
// File: contracts/Manager.sol


pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;



//https://dev.sushi.com/docs/Developers/Deployment%20Addresses
// To cover the objectives of the challenge, I will only cover lps that meet the following condition:
// {that have a yield to be deposited in step 4} 
// Example have a yield: eth/link (in poligon) and your allocPoint > 0 (If allocPoint if 0, rewards OF YIELD are 0, pools every have rewards)
// Example dont have a yiel: link/usdc

  // 1~ Approve SushiSwap Router (for each token) () used in swaps
  // 2~ Provide liquidity (make lp) ¿this need a swap first?... need 0x1b02da8cb0d097eb8d57a175b88c7d8b47997506 approves
  // 3~ Approve Master  (minichef for polygon: 0x0769fd68dFb93167989C6f7254cd0D766Fb2841F))
  // step 3 is possible in all cases but only nesesary in cases of yield exist for the pair.
  // 4~ Deposit liquidity in yield 0x598a7e5cb661762b648bb8d9e9b1fae3b81c2a47a339b3e32a996086632f1a8b tx to
  // Step 4 is only posible if the yield exist and your allocPoint > 0.

// The objective is what the user, fund with 2 tokens this contract(2 transactions) need approvals 
// and send this tokens (2 tx more ...) a this contract (with a specific funciton).
// After that, use goYield to automate the proces to make LP and put this lp in a Yield.
// ** In my opinion, this method does not solve or improve the user experience, or I misunderstood the challenge

interface IRouter{
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
}
interface IMinichef{
  struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SUSHI to distribute per block.
        uint256 lastRewardBlock;  // Last block number that SUSHI distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHI per share, times 1e12. See below.
    }
  function deposit(uint256 pid, uint256 amount, address to) external;
  function lpToken(uint256 pid) external view returns (address);
  function poolLength() external view returns (uint256 pools);
  function poolInfo(uint256 pid) external view returns (
    uint256 allocPoint,
    uint256 lastRewardBlock,
    uint256 accSushiPerShare
  );
}
interface IUniswapV2Factory{
  function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract Manager is SmartWallet{
  IRouter router;//0x1b02da8cb0d097eb8d57a175b88c7d8b47997506
  IMinichef minichef;//0x0769fd68dFb93167989C6f7254cd0D766Fb2841F
  IUniswapV2Factory sushiFactory;//0xc35DADB65012eC5796536bD9864eD8773aBc74C4
  uint256 MAX_UINT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff; //max uint256, the best gassless to obtain it

 //Approve SushiSwap Router
  constructor(address _router, address _minichef, address _sushiFactory){
    router = IRouter(_router);
    minichef = IMinichef(_minichef);
    sushiFactory = IUniswapV2Factory(_sushiFactory);
    //A) approve sushi router- (this contract approve the sushiRouter)
    //B) approve Sushi miniChef

    // Tengo que saber si la aprovacion es con un solo token o con varios, para caso A y Caso B
  }

  function goYield(address tokenA, address tokenB) public { 
    // uses 0xc35DADB65012eC5796536bD9864eD8773aBc74C4 to get pair address
    address slp = sushiFactory.getPair( tokenA,  tokenB);
    // Serch Address LP in minichef.lpToken map and if found it, serch allocPoint of pid
    bool rewardsOk;
    uint pid;
    for(uint i; i< minichef.poolLength();i++){
      if(slp == minichef.lpToken(i)){
        pid = i;
        (uint allocPoint,,) = minichef.poolInfo(pid);
        // Foundlp and allocPoint>0 ? GoYield : revert
        if(allocPoint > 0){
          rewardsOk = true;
        }
      }
    }
    require(rewardsOk, "No rewars for this pair");


    //Control balance of msg.sender
    uint balanceA = userBalances[msg.sender][tokenA];
    uint balanceB = userBalances[msg.sender][tokenB];
    require(balanceA > 0 && balanceB > 0, "No tokens in smart wallet");

    // Step 1 approve tokens A and B for router if nesesari
    approvals(IERC20(tokenA), balanceA);
    approvals(IERC20(tokenB), balanceB);

    // Step 2 Provide lp and get amount and address of SLP
    (uint amountA, uint amountB, uint liquidity) = router.addLiquidity(
      tokenA, tokenB, balanceA, balanceB, 0, 0, address(this), block.timestamp+5
    );

    // Step 3 approve slp for minichef
    approvals(IERC20(slp), liquidity);
    // Step 4 minichef.deposit(pid,amount,to)
    minichef.deposit(pid, liquidity, address(this));
    userBalances[msg.sender][tokenA] -=amountA;
    userBalances[msg.sender][tokenB] -=amountB;
    userBalances[msg.sender][slp] +=liquidity;
  }


  function approvals(IERC20 token, uint balance)internal{
    if(token.allowance(address(this), address(router))<= balance){
      token.approve( address(router), MAX_UINT);
    }
  }
 
}