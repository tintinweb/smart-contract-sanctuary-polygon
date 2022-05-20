//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IBEP20.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract OT000 is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping(address => bool) private _isExcludedFromFee; // wallets excluded from fee
  mapping (address => uint256) private _tokenSold;

  mapping (address => uint256) private _startTime;
  mapping (address => uint256) private _blockTime;

  mapping(address => bool) public adminAddresses;
  

  uint256 public _maxSoldAmount;
  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;  
  uint256 public _taxFee;
  uint256 public _minBalance;

  address public uniswapV2Pair;
  address payable public _teamWallet;
  address payable public _buybackWallet;

  bool public inSwap = false;
  bool public swapEnabled = true;

  IUniswapV2Router02 public uniswapV2Router; // pancakeswap v2 router

  modifier lockTheSwap {
    inSwap = true;
    _;
    inSwap = false;
  }

  /**
   * @dev Initialize params for tokenomics
   */

  constructor() {
    _name = unicode"OT000";
    _symbol = "OT000";
    _decimals = 18;
    _totalSupply = 1 * 10**18;
    _balances[msg.sender] = _totalSupply;    
    _taxFee = 600;
    _minBalance = 1 * 10**18;
    _maxSoldAmount = 10 * 14500000 * 10**18;

    _teamWallet = payable(0xc005eF0Ebf220e3824a5739F5085885dC8A00115); 
    _buybackWallet = payable(0x9418d04a2f6A89c2d6031b5C2E1D04cb26459349);

    // Polygon MainNet router
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    uniswapV2Router = _uniswapV2Router;

    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcludedFromFee[_teamWallet] = true;
    _isExcludedFromFee[_buybackWallet] = true;
    adminAddresses[0x436b5742D34D76A501cc4d2eA71a78f37bc9171b] = true;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  /**
   * @dev Returns the bep token owner.
   */

  function getOwner() external override view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */

  function decimals() external override view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */


  function symbol() external override view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */

  function name() external override view returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */

  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */

  //function balanceOf(address account) external override view returns (uint256) {
  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function excludeFromFee(address account) external onlyOwner {
    _isExcludedFromFee[account] = true;
  }
  
  function includeInFee(address account) external onlyOwner {
    _isExcludedFromFee[account] = false;
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
   
  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */

  function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

event Mint(uint256 amount, address mintAddress);
    event Burn(uint256 amount, address burnAddress);
    event LiquidityFeePercentUpdated(uint256 liquidityFee , address updatedBy);
    event MaxTxPercentUpdated(uint256 maxTxPercent , address updatedBy);
    event ContentFeePercentUpdated(uint256 contentFee , address updatedBy);
    event TaxFeePercentUpdated(uint256 taxFee, address updatedBy);


  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */

  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */

  function _transfer(address from, address to, uint256 amount) internal {

    require(from != address(0), "BEP20: transfer from the zero address");
    require(to != address(0), "BEP20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    bool takeFee = true;

    if (!inSwap && swapEnabled && to == uniswapV2Pair){      
      // limit max sold
      if(_tokenSold[from] == 0){
        _startTime[from] = block.timestamp;
      }

      _tokenSold[from] = _tokenSold[from] + amount;

      if( block.timestamp < _startTime[from] + (1 days)){
          require(_tokenSold[from] <= _maxSoldAmount, "Sold amount exceeds the maxTxAmount.");
      }else{
          _startTime[from] = block.timestamp;
          _tokenSold[from] = 0;
      }

      // transfer tokens
      uint256 obsBalance = balanceOf(address(this));
      if(obsBalance > _minBalance){                    
        transferTokens(obsBalance);
      }
      
      if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
        takeFee = false;
      }
    } else {
      takeFee = false;
    }

    _tokenTransfer(from, to, amount, takeFee);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.   
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
    * @dev transfer tokens to liqudity, team wallet and buyback wallet.
   */

  function transferTokens(uint256 tokenBalance) private lockTheSwap {
    uint256 liquidityTokens = tokenBalance.div(4); // 0.75%
    uint256 otherBNBTokens = tokenBalance - liquidityTokens; // 2.25%

    uint256 initialBalance = address(this).balance;
    swapTokensForEth(otherBNBTokens);

    uint256 newBalance = address(this).balance.sub(initialBalance);
    uint256 liquidityCapacity = newBalance.div(3);
    addLiqudity(liquidityTokens, liquidityCapacity);

    uint256 teamCapacity = newBalance - liquidityCapacity;    
    uint256 teamBNB = teamCapacity.mul(2).div(3);
    _teamWallet.transfer(teamBNB);

    uint256 buybackBNB = teamCapacity - teamBNB;
    _buybackWallet.transfer(buybackBNB);
  }

  /**
    * @dev Swap tokens from obs to eth
   */

  function swapTokensForEth(uint256 tokenAmount) private{
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
  }

  /**
    * @dev Add obs token and bnb as same ratio on uniswap router
   */

  function addLiqudity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // add amount to contract
    uniswapV2Router.addLiquidityETH{value: ethAmount}(
        address(this),
        tokenAmount,
        0, // slippage is unavoidable
        0, // slippage is unavoidable
        owner(),
        block.timestamp
    );
  }

  /**
    * @dev the Owner can swap regarding the obs token's amount of contract balance
    * this is for manual function
   */

  function contractBalanceSwap() external onlyOwner{
      uint256 contractBalance = balanceOf(address(this));
      swapTokensForEth(contractBalance);
  }

  /**
    * @dev the Owner can send regarding the obs token's amount of contract balance
    * this is for manual function
    * we need to remain 0.1BNB in contract balance for swap and transfer fees.
   */

  function contractBalanceSend(uint256 amount, address payable _destAddr) external onlyOwner{
    uint256 contractETHBalance = address(this).balance - 1 * 10**17;
    if(contractETHBalance > amount){
      _destAddr.transfer(amount);
    }
  }

  /**
    * @dev remove all fees
   */

  function removeAllFee() private {
    if (_taxFee == 0) return;
    _taxFee = 0;
  }

  /**
    * @dev set all fees
   */

  function restoreAllFee() private {
    _taxFee = 600;
  }

  /**
    * @dev transfer tokens with amount 
   */

  function _tokenTransfer(address sender, address recipient, uint256 amount, bool isTakeFee) private {
    if (!isTakeFee) removeAllFee();
    _transferStandard(sender, recipient, amount);
    if (!isTakeFee) restoreAllFee();
  }

  function _transferStandard(address sender, address recipient, uint256 amount) private {    
    uint256 fee = amount.mul(_taxFee).div(10000); // for 3% fee
    //_beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
    _balances[sender] = senderBalance - amount;
    uint256 amountnew = amount - fee;
    _balances[recipient] += (amountnew);

    if (fee>0) {
      _balances[address(this)] += (fee);
      emit Transfer(sender, address(this), fee);
    }

    emit Transfer(sender, recipient, amountnew);
  }

  /**
    * @dev set Max sold amount
   */

  function _setMaxSoldAmount(uint256 maxvalue) external onlyOwner {
      _maxSoldAmount = maxvalue;
  }

  /**
    * @dev set min balance for transferring
   */

  function _setMinBalance(uint256 minValue) external onlyOwner {
    _minBalance = minValue;
  }

  /**
    * @dev determine whether we apply tax fee or not
   */

  function _setApplyContractFee(bool isFee) external onlyOwner {
    if(isFee) {
        _taxFee = 600;
    } else {
        _taxFee = 0;
    }
  }

  function _setTeamWalletAddress(address teamWalletAddr) external onlyOwner {
    _teamWallet = payable(teamWalletAddr);
  }

  function _setBuybackWalletAddress(address buybackWalletAddr) external onlyOwner {
    _buybackWallet = payable(buybackWalletAddr);
  }


    function adminConfig(address adminAddress , bool isAdmin) external onlyOwner {
        adminAddresses[adminAddress] = isAdmin;
    }
    modifier onlyAdmin() {
        require(adminAddresses[_msgSender()], "Caller is not an owner.");
        _;
    }
    function _mint(address recipient, uint256 amount) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_totalSupply + amount <= 14500000 * 10**18, "Total supply cannot exceed 14 Millions");
    }
    function _burn(address senderAddress, uint256 amount) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(senderAddress), "Insufficient balance");
    }
    function mint(address recipient, uint256 value) external onlyAdmin  
    {
        _mint(recipient, value);
        emit Mint(value, recipient);
    }
    function burn(address fromAddress, uint256 value) external onlyAdmin 
    {
        _burn(fromAddress, value);
        emit Burn(value, fromAddress);
    }

  receive() external payable {}
}