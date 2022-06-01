/**
 *Submitted for verification at polygonscan.com on 2022-06-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

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
                /// @solidity memory-safe-assembly
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
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function mint(address to, uint256 amount) external;
    function burn(address owner, uint256 amount) external;
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
interface IPreIDOImmutables {
  function token() external view returns(IERC20Metadata);
}
interface IPreIDOState {
  function orders(uint256 id) external view returns(
        address beneficiary, 
        uint256 amount, 
        uint256 releaseOnBlock, 
        uint256 releaseLongTermOnBlock,
        bool claimed,
        bool claimedLongTerm,
        string memory tEvent
    );
  function investorOrderIds(address investor) external view returns(uint256[] memory ids);
  function balanceOf(address investor) external view returns(uint256 balance);
}
interface IPreIDOEvents {
  event LockTokens(address indexed sender, uint256 indexed id, uint256 amount, uint256 lockOnBlock, uint256 releaseOnBlock);   
  event UnlockTokens(address indexed receiver, uint256 indexed id, uint256 amount);
  event UnlockTokensLongTerm(address indexed receiver, uint256 indexed id, uint256 amount);
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);
  function getRoundData(uint80 _roundId)external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
  function latestRoundData() external view returns ( uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound );
}
contract Evensale is IPreIDOImmutables, IPreIDOState, IPreIDOEvents, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    struct OrderInfo {
        address beneficiary;
        uint256 amount;
        uint256 releaseOnBlock;
        uint256 releaseLongTermOnBlock;
        bool claimed;
        bool claimedLongTerm;
        string tEvent;
    }
    mapping(uint256 => OrderInfo) public override orders;

    uint256 private constant MIN_LOCK = 365 days; // 1 year;

    uint256 private yearPercentedLock = 10;
    uint256 private dayPercentedLock = MIN_LOCK * yearPercentedLock;
    uint256 private percentedLock = 75;

    mapping(uint8 => uint256) public discountsLock;
    mapping(address => uint256) public override balanceOf;
    mapping(address => uint256[]) private orderIds;

    uint256 private latestOrderId = 0;
    uint256 public totalDistributed;
    uint256 public minInvestment = 1000 * (10 ** 18);
    uint256 public tokenPrice = 100;
    string public typeEvent;

    AggregatorV3Interface private priceFeedMaticUsd;

    IERC20Metadata public immutable override token;
    
    uint256 public notBeforeBlock;
    uint256 public notAfterBlock;

    constructor(address _token, string memory tEvents, uint256 _notBeforeBlock, uint256 _notAfterBlock) {

        require(_token != address(0), "invalid contract address"); // ICA
        require( _notAfterBlock > _notBeforeBlock, "invalid presale schedule"); // IPS

        priceFeedMaticUsd = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);

        token = IERC20Metadata(_token);
        notBeforeBlock = _notBeforeBlock;
        notAfterBlock = _notAfterBlock;

        discountsLock[10] = MIN_LOCK;
        discountsLock[20] = 2 * MIN_LOCK;
        discountsLock[30] = 3 * MIN_LOCK;
        discountsLock[50] = 5 * MIN_LOCK;

        typeEvent = tEvents;
    }

    receive() external payable inEventsalePeriod {
        _order(msg.value, 10); // default to 10% discount rate
    }

    function investorOrderIds(address investor) external view override returns (uint256[] memory ids) {
        uint256[] memory arr = orderIds[investor];
        return arr;
    }

    function order(uint8 discountsRate) external payable inEventsalePeriod {
        _order(msg.value, discountsRate);
    }

    function _order(uint256 amount, uint8 discountsRate) internal {

        require(amount >= minInvestment, "the investment amount does not reach the minimum amount required"); 

        uint256 lockDuration = discountsLock[discountsRate];
        uint256 lockDuratioLongTermn = dayPercentedLock;
        
        require(lockDuration >= MIN_LOCK, "the lock duration does not reach the minimum duration required"); // NDR

        uint256 releaseOnBlock = block.timestamp.add(lockDuration);
        uint256 releaseLongTermOnBlock = block.timestamp.add(lockDuratioLongTermn);

        uint256 totalPrice = amount * tokenPrice;
        uint256 calcPrice = (totalPrice / 100) * discountsRate;
        uint256 distributeAmount = totalPrice + calcPrice;

        require(distributeAmount <= token.balanceOf(address(this)), "there is not enough supply token to be distributed"); // NET

        orders[++latestOrderId] = OrderInfo(
            msg.sender, 
            distributeAmount, 
            releaseOnBlock, 
            releaseLongTermOnBlock,
            false,
            false,
            typeEvent
        );

        totalDistributed = totalDistributed.add(distributeAmount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(distributeAmount);
        orderIds[msg.sender].push(latestOrderId);

        emit LockTokens(msg.sender, latestOrderId, distributeAmount, block.timestamp, releaseOnBlock);
    }

    function redeem(uint256 orderId) external {
        require(orderId <= latestOrderId, "the order ID is incorrect"); // IOI

        OrderInfo storage orderInfo = orders[orderId];
        require(msg.sender == orderInfo.beneficiary, "not order beneficiary"); // NOO
        require(orderInfo.amount > 0, "insufficient redeemable tokens"); // ITA
        require(block.timestamp >= orderInfo.releaseOnBlock, "tokens are being locked"); // TIL
        require(!orderInfo.claimed, "tokens are ready to be claimed"); // TAC

        uint256 calcPrice = (orderInfo.amount / 100) * percentedLock;
        uint256 amount = safeTransferToken(orderInfo.beneficiary, calcPrice);
        
        orderInfo.claimed = true;
        orderInfo.amount = orderInfo.amount.sub(amount);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        
        emit UnlockTokens(orderInfo.beneficiary, orderId, amount);
    }

    function redeemLongTerm(uint256 orderId) external {
        require(orderId <= latestOrderId, "the order ID is incorrect"); // IOI

        OrderInfo storage orderInfo = orders[orderId];
        require(msg.sender == orderInfo.beneficiary, "not order beneficiary"); // NOO
        require(orderInfo.amount > 0, "insufficient redeemable tokens"); // ITA
        require(block.timestamp >= orderInfo.releaseLongTermOnBlock, "tokens are being locked"); // TIL
        require(!orderInfo.claimedLongTerm, "tokens are ready to be Long Term claimed"); // TAC

        uint256 amount = safeTransferToken(orderInfo.beneficiary, orderInfo.amount);
        orderInfo.claimedLongTerm = true;
        orderInfo.amount = orderInfo.amount.sub(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);

        emit UnlockTokensLongTerm(orderInfo.beneficiary, orderId, amount);
    }

    function getPrice() public view returns (uint80, int, uint, uint, uint80) {
            (uint80 roundID, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = priceFeedMaticUsd.latestRoundData();
            return (roundID, price, startedAt, timeStamp, answeredInRound);
    }

    function remainingTokens() public view inEventsalePeriod returns (uint256 remainingToken){
        remainingToken = token.balanceOf(address(this)) - totalDistributed;
    }

    function collect() external onlyOwner afterEventsalePeriod{
        uint256 amount = address(this).balance;
        require(amount > 0, "insufficient funds for collection"); // NEC
        payable(msg.sender).transfer(amount);
    }

    function setMinInvestment(uint256 _minInvestment) external onlyOwner beforeEventsaleEnd {
        require(_minInvestment > 0, "Invalid input value"); // IIV
        minInvestment = _minInvestment;
    }
    function setTokenPrices(uint256 _tPrice) external onlyOwner beforeEventsaleEnd {
        require(_tPrice > 0, "Invalid input value"); // IIV
        tokenPrice = _tPrice;
    }
    function setTypeEvents(string memory tEvent) external onlyOwner beforeEventsaleEnd {
        typeEvent = tEvent;
    }

    function setBeforeBlock(uint256 date) external onlyOwner {
        notBeforeBlock = date;
    }
    function setAfterBlock(uint256 date) external onlyOwner {
        notAfterBlock = date;
    }

    function safeTransferToken(address _to, uint256 _amount) private returns (uint256 amount){
        uint256 bal = token.balanceOf(address(this));
        if (bal < _amount) {
            token.safeTransfer(_to, bal);
            amount = bal;
        } else {
            token.safeTransfer(_to, _amount);
            amount = _amount;
        }
    }
    modifier inEventsalePeriod() {
        require(block.timestamp > notBeforeBlock, "Pre-sale has not been started"); 
        require(block.timestamp < notAfterBlock, "Pre-sale has already ended"); 
        _;
    }
    modifier afterEventsalePeriod() {
        require(block.timestamp > notAfterBlock, "Pre-sale is still ongoing"); 
        _;
    }
    modifier beforeEventsaleEnd() {
        require(block.timestamp < notAfterBlock, "Pre-sale has already ended"); 
        _;
    }
}