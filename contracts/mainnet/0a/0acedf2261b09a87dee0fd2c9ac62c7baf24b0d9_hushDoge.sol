/**
 *Submitted for verification at polygonscan.com on 2023-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8 .0;

interface IUniswapV2Router02 {
   function swapExactTokensForETHSupportingFeeOnTransferTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
   ) external returns(uint[] memory amounts);

   function WETH() external pure returns(address);
}

contract hushDoge {
   uint256 constant private FLOAT_SCALAR = 2 ** 64;
   uint256 constant private INITIAL_SUPPLY = 1e27; // 1B
   uint256 public HOLD_FEE = 2;
   uint256 public DIP_FEE = 0; 
   string constant public name = "H1";
   string constant public symbol = "H1";
   uint8 constant public decimals = 18;

   address payable public adminWallet;

   struct User {
      bool whitelisted;
      uint256 balance;
      mapping(address => uint256) allowance;
      int256 scaledPayout;
   }

   struct Info {
      uint256 totalSupply;
      mapping(address => User) users;
      uint256 scaledPayoutPerToken;
      address admin;
   }
   Info private info;

   uint256 private collectedFees;
   uint256 private swapThreshold = 1e22; // 10000 tokens

   address private constant UNISWAP_ROUTER_ADDRESS = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
   IUniswapV2Router02 private uniswapRouter;

   event Transfer(address indexed from, address indexed to, uint256 tokens);
   event Approval(address indexed owner, address indexed spender, uint256 tokens);
   event Whitelist(address indexed user, bool status);
   event Collect(address indexed owner, uint256 tokens);
   event Fee(uint256 tokens);
   event HoldFeeUpdated(uint256 oldHoldFee, uint256 newHoldFee);
   event DipFeeUpdated(uint256 oldDipFee, uint256 newDipFee);

   constructor() {
      info.admin = msg.sender;
      adminWallet = payable(msg.sender);
      info.totalSupply = INITIAL_SUPPLY;
      info.users[msg.sender].balance = INITIAL_SUPPLY;
      emit Transfer(address(0x0), msg.sender, INITIAL_SUPPLY);
      whitelist(msg.sender, true);
      uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
  }

   function collect() external returns(uint256) {
      uint256 _dividends = dividendsOf(msg.sender);
      require(_dividends >= 0);
      info.users[msg.sender].scaledPayout += int256(_dividends * FLOAT_SCALAR);
      info.users[msg.sender].balance += _dividends;
      emit Transfer(address(this), msg.sender, _dividends);
      emit Collect(msg.sender, _dividends);
      return _dividends;
   }

   function distribute(uint256 _tokens) external {
      require(info.totalSupply > 0);
      require(balanceOf(msg.sender) >= _tokens);
      info.users[msg.sender].balance -= _tokens;
      info.scaledPayoutPerToken += _tokens * FLOAT_SCALAR / info.totalSupply;
      emit Transfer(msg.sender, address(this), _tokens);
   }

   function transfer(address _to, uint256 _tokens) external returns(bool) {
      _transfer(msg.sender, _to, _tokens);
      return true;
   }

   function approve(address _spender, uint256 _tokens) external returns(bool) {
      info.users[msg.sender].allowance[_spender] = _tokens;
      emit Approval(msg.sender, _spender, _tokens);
      return true;
   }

   function transferFrom(address _from, address _to, uint256 _tokens) external returns(bool) {
      require(info.users[_from].allowance[msg.sender] >= _tokens);
      info.users[_from].allowance[msg.sender] -= _tokens;
      _transfer(_from, _to, _tokens);
      return true;
   }

   function bulkTransfer(address[] calldata _receivers, uint256[] calldata _amounts) external {
      require(_receivers.length == _amounts.length);
      for (uint256 i = 0; i < _receivers.length; i++) {
         _transfer(msg.sender, _receivers[i], _amounts[i]);
      }
   }

   function whitelist(address _user, bool _status) public {
      require(msg.sender == info.admin);
      info.users[_user].whitelisted = _status;
      emit Whitelist(_user, _status);
   }

   function setHoldFee(uint256 _holdFee) external {
      require(msg.sender == info.admin, "Only admin can update fees");
      require(_holdFee <= 100, "Fee cannot be more than 100%");
      uint256 oldHoldFee = HOLD_FEE;
      HOLD_FEE = _holdFee;
      emit HoldFeeUpdated(oldHoldFee, _holdFee);
   }

   function setDipFee(uint256 _dipFee) external {
      require(msg.sender == info.admin, "Only admin can update fees");
      require(_dipFee <= 100, "Fee cannot be more than 100%");
      uint256 oldDipFee = DIP_FEE;
      DIP_FEE = _dipFee;
      emit DipFeeUpdated(oldDipFee, _dipFee);
   }

   function totalSupply() public view returns(uint256) {
      return info.totalSupply;
   }

   function balanceOf(address _user) public view returns(uint256) {
      return info.users[_user].balance;
   }

   function dividendsOf(address _user) public view returns(uint256) {
      return uint256(int256(info.scaledPayoutPerToken * info.users[_user].balance) - info.users[_user].scaledPayout) / FLOAT_SCALAR;
   }

   function allowance(address _user, address _spender) public view returns(uint256) {
      return info.users[_user].allowance[_spender];
   }

   function isWhitelisted(address _user) public view returns(bool) {
      return info.users[_user].whitelisted;
   }

   function allInfoFor(address _user) public view returns(uint256 totalTokenSupply, uint256 userBalance, uint256 userDividends) {
      return (totalSupply(), balanceOf(_user), dividendsOf(_user));
   }

   function _transfer(address _from, address _to, uint256 _tokens) internal returns(uint256) {
      require(balanceOf(_from) >= _tokens);
      info.users[_from].balance -= _tokens;
      uint256 _feeAmount = _tokens * HOLD_FEE / 100;
      uint256 _dipAmount = _tokens * DIP_FEE / 100;
      uint256 _transferred = _tokens - _feeAmount - _dipAmount;
      info.users[_to].balance += _transferred;
      emit Transfer(_from, _to, _transferred);
      info.scaledPayoutPerToken += _feeAmount * FLOAT_SCALAR / info.totalSupply;
      info.users[address(this)].balance += _dipAmount;
      emit Transfer(_from, address(this), _feeAmount + _dipAmount);
      if (info.users[address(this)].balance >= swapThreshold) {
         swapTokensForETH(_dipAmount);
      }
      return _transferred;
   }

   function swapTokensForETH(uint256 tokenAmount) private {
      // Generate the uniswap pair path of token -> weth
      address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = uniswapRouter.WETH();
      info.users[address(this)].balance -= tokenAmount;

      // Approve the router to spend the tokens
      info.users[address(this)].allowance[address(uniswapRouter)] = tokenAmount;
      uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
         tokenAmount,
         0, // Accept any amount of ETH
         path,
         adminWallet,
         block.timestamp
      );
   }
}