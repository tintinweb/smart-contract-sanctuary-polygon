/**
 *Submitted for verification at polygonscan.com on 2022-07-11
*/

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

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

// File: contracts\TokenMint.sol


pragma solidity >=0.4.22 <0.9.0;

contract TokenMint {
  IERC20 mintToken;

  address public owner;
  address public operator;
  address public tokenSource;
  uint256 public mintPrice;
  uint256 public fee = 400;
  uint256 public feesPending = 0;
  bool public boostEnabled = false;
  bool public paused;
  uint256[] public boostLevels;
  mapping(uint256 => uint256) public boostAmounts;

  event Mint(address user, uint256 amountMinted);

  constructor(address _owner,
              address _operator,
              uint256 _mintPrice,
              address _token,
              address _tokenSource)
  {
    owner = _owner;
    operator = _operator;
    mintPrice = _mintPrice;
    mintToken = IERC20(_token);
    tokenSource = _tokenSource;
  }

  modifier isOwner(){
    require(msg.sender == owner, "Function Restricted to Owner");
    _;
  }

  modifier isOperator(){
    require(msg.sender == operator, "Function Restricted to Operator");
    _;
  }

  modifier isPaused(){
    require(!paused, "Mint is Paused");
    _;
  }

  function mint(uint256 amount) external isPaused payable{
    require((amount * mintPrice) / 1e18 == msg.value, "Incorrect Value");
    require(mintToken.allowance(owner, address(this)) >= amount, "Mint capped or hasnt been approved");
    feesPending += (msg.value * fee)/10000;
    if(boostEnabled && msg.value >= boostLevels[0]){
      for(uint i = 1; i < boostLevels.length ; i++){
        if(boostLevels[i] > msg.value){
          amount = (amount * boostAmounts[i - 1]) / 100;
          break;
        }else if(i == boostLevels.length - 1){
          amount = (amount * boostAmounts[i]) / 100;
        }
      }
    }
    mintToken.transferFrom(tokenSource, msg.sender, amount);
    emit Mint(msg.sender, amount);
  }

  function withdrawProceeds(address to) external isOwner {
    require(address(this).balance - feesPending > 0, "No proceeds pending");
    uint amountToTransfer = address(this).balance - feesPending;

    (bool sent, ) = payable(to).call{value: amountToTransfer}("");
    require(sent, "Failed to Transfer");
  }

  function withdrawFees(address to) external isOperator {
    require(feesPending > 0, "No fees pending");
    (bool sent, ) = payable(to).call{value: feesPending}("");
    require(sent, "Failed to Transfer");

    feesPending = 0;
  }
  
  function enableDisableBoost(uint256[] memory _boostLevels, uint256[] memory _boostAmounts) external isOwner{
    require(_boostAmounts.length == _boostLevels.length, "Must include values for all boost levels");
    if(boostEnabled){
      boostEnabled = false;
    }else if(_boostLevels.length > 0){
      boostEnabled = true;
      boostLevels = _boostLevels;
      for(uint i = 0; i < _boostLevels.length; i++){
        boostAmounts[i] = _boostAmounts[i] + 100;
      }
    }else{
      require(boostLevels.length > 0, "Must pass levels and amounts to enable");
      boostEnabled = true;
    }
  }

  function updatePrice(uint256 newPrice) external isOwner {
    mintPrice = newPrice;
  }

  function updateFee(uint newFee) external isOperator{
    fee = newFee;
  }

  function updatePause(bool _isPaused) external isOwner {
    paused = _isPaused;
  }

  function updateTokenSource(address source) external isOwner {
    tokenSource = source;
  }

}

// File: contracts\MintFactory.sol


pragma solidity >=0.4.22 <0.9.0;

contract MintFactory {
  address public factoryOwner;
  mapping(address => address) private mintAddresses;

  constructor() {
    factoryOwner = msg.sender;
  }

  function createNewMint(address token, address tokenSource, uint256 mintPrice) external returns(address){
    require(mintAddresses[token] == address(0), "cannot create another mint for this token");
    TokenMint mintContract = new TokenMint(msg.sender, factoryOwner, mintPrice, token, tokenSource);

    mintAddresses[token] = address(mintContract);
    return address(mintContract);
  }

  function getMintAddress(address tokenAddr) external view returns(address){
    return mintAddresses[tokenAddr];
  }

  function transferFactory(address newOwner) external {
    require(msg.sender == factoryOwner, "Not Authorized");
    factoryOwner = newOwner;
  }
}