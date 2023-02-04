/**
 *Submitted for verification at polygonscan.com on 2023-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;

library Address {
function isContract(address account) internal view returns (bool) {
bytes32 codehash;
bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
assembly { codehash := extcodehash(account) }
return (codehash != accountHash && codehash != 0x0);
}
}

contract Context {
constructor () internal { }
function _msgSender() internal view returns (address payable) {
return msg.sender;
}
}

contract ReentrancyGuard {
bool private _notEntered;
constructor () internal {
_notEntered = true;
}

modifier nonReentrant() {
require(_notEntered, "ReentrancyGuard: reentrant call");
_notEntered = false;

_;

_notEntered = true;
}
}

library SafeMath {
function add(uint256 a, uint256 b) internal pure returns (uint256) {
uint256 c = a + b;
require(c >= a, "SafeMath: addition overflow");

return c;
}

function sub(uint256 a, uint256 b) internal pure returns (uint256) {
return sub(a, b, "SafeMath: subtraction overflow");
}

function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
require(b <= a, errorMessage);
uint256 c = a - b;

return c;
}

function mul(uint256 a, uint256 b) internal pure returns (uint256) {
if (a == 0) {
return 0;
}

uint256 c = a * b;
require(c / a == b, "SafeMath: multiplication overflow");

return c;
}
}

interface ERC20 {
function totalSupply() external view returns (uint256);
function balanceOf(address account) external view returns (uint256);
function transfer(address recipient, uint256 amount) external returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
function approve(address spender, uint256 amount) external returns (bool);
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
using SafeMath for uint256;
using Address for address;

function safeTransfer(ERC20 token, address to, uint256 value) internal {
callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
}

function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
}

function callOptionalReturn(ERC20 token, bytes memory data) private {
require(address(token).isContract(), "SafeERC20: call to non-contract");

(bool success, bytes memory returndata) = address(token).call(data);
require(success, "SafeERC20: low-level call failed");

if (returndata.length > 0) { // Return data is optional
require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
}
}
}

contract ICO is Context, ReentrancyGuard {
using SafeMath for uint256;
using SafeERC20 for ERC20;
ERC20 private _mytoken;
address payable private _wallet;
uint256 private _ethRate;
uint256 private _mytokenDelivered;
event MyTokenPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
constructor (uint256 ethRate, address payable wallet, ERC20 mytoken) public {

require(ethRate > 0, "ICO: ethRate shouldn't be Zero");
require(wallet != address(0), "ICO: wallet is the Zero address");
require(address(mytoken) != address(0), "ICO: token is the Zero address");
_ethRate = ethRate;
_wallet = wallet;
_mytoken = mytoken;
}

function mytokenAddress() public view returns (ERC20) {
return _mytoken;
}

function teamWallet() public view returns (address payable) {
return _wallet;
}

function ethRate() public view returns (uint256) {
return _ethRate;
}

function mytokenDelivered() public view returns (uint256) {
return _mytokenDelivered;
}

function () external payable {
buyMyTokenWithEther();
}

function buyMyTokenWithEther() public nonReentrant payable {
address beneficiary = _msgSender();
uint256 ethAmount = msg.value;
uint256 ContractBalance = _mytoken.balanceOf(address(this));
require(ethAmount > 0, "You need to sendo at least some Ether");
uint256 _mytokenAmount = _getEthRate(ethAmount);
_preValidatePurchase(beneficiary, _mytokenAmount);
require(_mytokenAmount <= ContractBalance, "Not enough MyToken in the reserve");
_mytokenDelivered = _mytokenDelivered.add(_mytokenAmount);
_processPurchase(beneficiary, _mytokenAmount);
emit MyTokenPurchased(_msgSender(), beneficiary, ethAmount, _mytokenAmount);
_updatePurchasingState(beneficiary, _mytokenAmount);
_forwardEtherFunds();
_postValidatePurchase(beneficiary, _mytokenAmount);
}

function _preValidatePurchase(address beneficiary, uint256 Amount) internal view {
require(beneficiary != address(0), "ICO: beneficiary is the zero address");
require(Amount != 0, "ICO: Amount is 0");
this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
}

function _postValidatePurchase(address beneficiary, uint256 Amount) internal view {
}

function _deliverMyToken(address beneficiary, uint256 mytokenAmount) internal {
_mytoken.safeTransfer(beneficiary, mytokenAmount);
}

function _processPurchase(address beneficiary, uint256 mytokenAmount) internal {
_deliverMyToken(beneficiary, mytokenAmount);
}

function _updatePurchasingState(address beneficiary, uint256 Amount) internal {
}

function _getEthRate(uint256 ethAmount) internal view returns (uint256) {
return ethAmount.mul(_ethRate);
}

function _forwardEtherFunds() internal {
_wallet.transfer(msg.value);
}
}

contract LimitedUnitsIco is ICO {
using SafeMath for uint256;

uint256 private _maxMyTokenUnits;

constructor (uint256 maxMyTokenUnits) public {
require(maxMyTokenUnits > 0, "Max Capitalization shouldn't be Zero");
_maxMyTokenUnits = maxMyTokenUnits;
}

function maxMyTokenUnits() public view returns (uint256) {
return _maxMyTokenUnits;
}

function icoReached() public view returns (bool) {
return mytokenDelivered() >= _maxMyTokenUnits;
}

function _preValidatePurchase(address beneficiary, uint256 Amount) internal view {
super._preValidatePurchase(beneficiary, Amount);
require(mytokenDelivered().add(Amount) <= _maxMyTokenUnits, "Max MyToken Units exceeded");
}
}