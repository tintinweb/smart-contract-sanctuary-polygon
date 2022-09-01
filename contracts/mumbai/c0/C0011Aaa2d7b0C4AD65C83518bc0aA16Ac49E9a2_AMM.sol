/**
 *Submitted for verification at polygonscan.com on 2022-08-31
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT
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


// File contracts/Amm.sol

pragma solidity ^0.8.0;

contract AMM {
	// The IERC20 interface allows us to import the token contracts
  IERC20 private immutable matic;
  IERC20 private immutable goflow;

  uint256 totalShares; // Stores the total amount of share issued for the pool
  uint256 totalMatic; // Stores the amount of Token1 locked in the pool
  uint256 totalGoflow; // Stores the amount of Token2 locked in the pool
  uint256 K; // Algorithmic constant used to determine price

  mapping(address => uint256) shares; // Stores the share holding of each provider

	// Pass the token addresses to the constructor
  constructor(IERC20 _matic, IERC20 _goflow) {
    matic = _matic; 
    goflow = _goflow;
  }

  // Liquidity must be provided before we can make swaps from the pool
  modifier activePool() {
    require(totalShares > 0, "Zero Liquidity");
    _;
  }

  modifier validAmountCheck(IERC20 _token, uint256 _amount) {
    require(_amount > 0, "Amount cannot be zero!");
    require(_amount <= _token.balanceOf(msg.sender), "Insufficient amount");
    _;
  }

  modifier validSharesCheck(uint256 _amount) {
    require(_amount > 0, "Share amount cannot be zero!");
    require(_amount <= shares[msg.sender], "Insufficient share amount");
    _;
  }

	// Redefine state variables so we don't get a shadow warning
	function getPoolDetails() external view returns(uint256 maticAmount, uint256 goflowAmount, uint256 ammShares) {
    maticAmount = totalMatic;
    goflowAmount = totalGoflow;
    ammShares = totalShares;
  }

  // Allows a user to provide liquidity to the pool
  function provide(uint256 _amountMatic, uint256 _amountGoflow) external validAmountCheck(matic, _amountMatic) validAmountCheck(goflow, _amountGoflow) returns(uint256 share) {
    if(totalShares == 0) { // Initial liquidity provider is issued 100 Shares
        share = 100 * 10**18;
    } else {
        uint256 share1 = totalShares * (_amountMatic / totalMatic);
        uint256 share2 = totalShares * (_amountGoflow / totalGoflow);
        require(share1 == share2, "Equivalent value of tokens not provided...");
        share = share1;
    }

    require(share > 0, "Asset value less than threshold for contribution!");
    // Important! The frontend must call the token contract's approve function first.
    matic.transferFrom(msg.sender, address(this), _amountMatic);
    goflow.transferFrom(msg.sender, address(this), _amountGoflow);

    totalMatic += _amountMatic;
    totalGoflow += _amountGoflow;
    K = totalMatic * totalGoflow;

    totalShares += share;
    shares[msg.sender] += share;
  }

  function getMyHoldings(address user) external view returns(uint256 maticAmount, uint256 goflowAmount, uint256 myShare) {
    maticAmount = matic.balanceOf(user);
    goflowAmount = goflow.balanceOf(user);
    myShare = shares[user];
  }

  // How much MATIC you should also provide when putting _amountGoflow tokens in the pool
  function getEquivalentMaticEstimate(uint256 _amountGoflow) public view activePool returns(uint256 reqMatic) {
    reqMatic = totalMatic * (_amountGoflow / totalGoflow);
  }

  // How much GOFLOW you should also provide when putting _amountMatic tokens in the pool
  function getEquivalentGoflowEstimate(uint256 _amountMatic) public view activePool returns(uint256 reqGoflow) {
    reqGoflow = totalGoflow * (_amountMatic / totalMatic);
  }

  // Returns the amoung of TOKENS you'll be given back with withdrawing your shares
  function getWithdrawEstimate(uint256 _share) public view activePool returns(uint256 amountMatic, uint256 amountGoflow) {
    require(_share <= totalShares, "Share should be less than totalShare");
    amountMatic = _share * totalMatic / totalShares;
    amountGoflow = _share * totalGoflow / totalShares;
  }

  // Removes proportional amount of liquidity from the pool
  function withdraw(uint256 _share) external activePool validSharesCheck(_share) returns(uint256 amountMatic, uint256 amountGoflow) {
    (amountMatic, amountGoflow) = getWithdrawEstimate(_share);
    
    shares[msg.sender] -= _share;
    totalShares -= _share;

    totalMatic -= amountMatic;
    totalGoflow -= amountGoflow;
    K = totalMatic * totalGoflow;

    matic.transfer(msg.sender, amountMatic);
    goflow.transfer(msg.sender, amountGoflow);
  }

  // Returns the amount of GOFLOW user will get for given amount of MATIC
  function getSwapMaticEstimate(uint256 _amountMatic)
    public
    view
    activePool
    returns (uint256 amountGoflow)
{
    uint256 maticAfter = totalMatic + _amountMatic;
    uint256 goflowAfter = K / maticAfter;
    amountGoflow = totalGoflow - goflowAfter;

    // We don't want to completely empty the pool
    if (amountGoflow == totalGoflow) amountGoflow--;
  }

  // Swaps given amount of MATIC for GOFLOW
  function swapMatic(uint256 _amountMatic)
    external
    activePool
    validAmountCheck(matic, _amountMatic)
    returns (uint256 amountGoflow)
  {
    amountGoflow = getSwapMaticEstimate(_amountMatic);
    require(
        matic.allowance(msg.sender, address(this)) >= _amountMatic,
        "Insufficient allowance"
    );

    matic.transferFrom(msg.sender, address(this), _amountMatic);
    totalMatic += _amountMatic;
    totalGoflow -= amountGoflow;
    goflow.transfer(msg.sender, amountGoflow);
  }

  // Returns the amount of MATIC user will get for given amount of GOFLOW
  function getSwapGoflowEstimate(uint256 _amountGoflow)
    public
    view
    activePool
    returns (uint256 amountMatic)
{
    uint256 GoflowAfter = totalGoflow + _amountGoflow;
    uint256 maticAfter = K / GoflowAfter;
    amountMatic = totalMatic - maticAfter;

    // We don't want to completely empty the pool
    if (amountMatic == totalMatic) amountMatic--;
  }

  // Swaps given amount of GOFLOW for MATIC
  function swapGoflow(uint256 _amountGoflow)
    external
    activePool
    validAmountCheck(goflow, _amountGoflow)
    returns (uint256 amountMatic)
{
    amountMatic = getSwapGoflowEstimate(_amountGoflow);

    goflow.transferFrom(msg.sender, address(this), _amountGoflow);
    totalGoflow += _amountGoflow;
    totalMatic -= amountMatic;
    matic.transfer(msg.sender, amountMatic);
  }
}