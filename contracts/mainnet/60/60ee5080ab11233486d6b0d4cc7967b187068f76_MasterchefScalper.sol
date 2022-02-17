/**
 *Submitted for verification at polygonscan.com on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
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
    constructor() {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

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
}

interface IMasterChef {
    function deposit(uint256 pid, uint256 amount,address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
 // function enterStaking(uint256 _amount) external;
 // function leaveStaking(uint256 _amount) external;
 // function claim(uint256 _pid) external;
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function emergencyWithdraw(uint256 _pid) external;
}



contract MasterchefScalper is ERC20("scalpMATIC-BANANA", "SCLP-MATICBANANA"), Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable baseAsset;
    IERC20 public immutable rewardAsset;
    IERC20 public immutable stableAsset;
    IMasterChef public immutable masterChef;
    uint256 public immutable stakingPid;

    mapping (address => uint256) public share;
    uint256 public totalshares;
    address public treasury;

    address[] public outputToStableRoute;

    address public unirouter;

    uint256 internal constant MAX_PERFORMANCE_FEE = 500;
    uint256 internal constant MAX_CALL_FEE = 100;

    uint256 public performanceFee = 200;
    uint256 public callFee = 5;
    
    bool public hadEmergencyWithdrawn = false;

    event Deposit(address indexed sender, uint256 amount, uint256 mintSupply, uint256 lastDepositedTime);
    event Withdraw(address indexed sender, uint256 currentAmount, uint256 amount);
    event Harvest(address indexed sender, uint256 performanceFee, uint256 callFee);
    event SetTreasury(address indexed treasury);
    event SetPerformanceFee(uint256 performanceFee);
    event SetCallFee(uint256 callFee);
    event EmergencyWithdraw();

    constructor(
        IERC20 _baseAsset,
        IERC20 _rewardAsset,
        IERC20 _stableAsset,
        IMasterChef _masterChef,
        address _unirouter,
        uint256 _stakingPid,
        address _treasury,
        address[] memory _outputToStableRoute

    ) {
        baseAsset = _baseAsset;
        rewardAsset = _rewardAsset;
        stableAsset = _stableAsset;
        masterChef = _masterChef;
        stakingPid = _stakingPid;
        treasury = _treasury;
        unirouter =_unirouter;
        outputToStableRoute = _outputToStableRoute;

        IERC20(_baseAsset).safeApprove(address(_masterChef), type(uint256).max);
        IERC20(_rewardAsset).safeApprove(unirouter, type(uint256).max);
    }

     function depositAll() external {
        deposit(IERC20(baseAsset).balanceOf(msg.sender));
    }
   
    function deposit(uint256 _amount) public whenNotPaused nonReentrant {

        require(_amount > 0, "Nothing to deposit");
        IERC20(baseAsset).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 pool = baseAssetBalanceOf();
        _earn();
        _stabiliseOf();
        uint256 value = pool + stableAssetBalance();
        if(totalshares == 0){
        share[msg.sender] = _amount;
        totalshares = share[msg.sender];
                }
        else {
            uint256 s = share[msg.sender];
            uint256 c = _amount * totalshares / value;
            share[msg.sender] = s + c; 
            totalshares = totalshares + c;
        }

        _mint(msg.sender, _amount);
    
        emit Deposit(msg.sender, _amount, _amount, block.timestamp);
    
    }


        function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    function withdraw(uint256 _amount) public nonReentrant {
   //   require(_amount > 0, "Nothing to withdraw");
        require(_amount <= balanceOf(msg.sender), "Withdraw amount exceeds balance");
        _burn(msg.sender, _amount);
       
        uint256 bal = available();
        if (bal < _amount) {
            uint256 balWithdraw = _amount - bal;
            IMasterChef(masterChef).withdrawAndHarvest(stakingPid, bal, address(this));
            //IMasterChef(masterChef).leaveStaking(bal);
            uint256 balAfter = available();
            uint256 diff = balAfter - bal;
            if (diff < balWithdraw) {
                _amount = balAfter;
            }
        }
        _stabiliseOf();

        uint256 calc = share[msg.sender] * gPPFS();
        uint256 stablepart = calc - balanceOf(msg.sender);
        IERC20(stableAsset).safeTransfer(msg.sender, stablepart);
        IERC20(baseAsset).safeTransfer(msg.sender, _amount);
    
        uint256 tempshare = totalshares-share[msg.sender];
        uint256 tempsupply = baseAssetBalanceOf() - balanceOf(msg.sender);
        uint256 c = balanceOf(msg.sender) * tempshare / tempsupply;
        share[msg.sender] = c; 
        totalshares = tempshare + c;
        
        emit Withdraw(msg.sender, _amount ,stablepart);
    }


   //View function
   

    function baseAssetBalanceOf() public view returns (uint256) {

        (uint256 _amount,) = IMasterChef(masterChef).userInfo(stakingPid, address(this));
        return IERC20(baseAsset).balanceOf(address(this)) + _amount;
    }

    function baseAssetBalanceOfUser() public view returns (uint256) {
        return IERC20(baseAsset).balanceOf(msg.sender);
    }
    
    function rewardAssetBalance() public view returns (uint256) {
        return IERC20(rewardAsset).balanceOf(address(this));
   
    }

    function stableAssetBalance() public view returns (uint256) {
       return IERC20(stableAsset).balanceOf(address(this));
        
    }

      function available() public view returns (uint256) {
        return IERC20(baseAsset).balanceOf(address(this));
    }

    function getPricePerFullShare() external view returns (uint256) {
        return totalSupply() == 0 ? 1e18 : (baseAssetBalanceOf()+stableAssetBalance()) * 1e18 / totalshares;
    }
    function gPPFS() public view returns (uint256) {
        return totalSupply() == 0 ? 1e18 : (baseAssetBalanceOf()+stableAssetBalance()) * 1e18 / totalshares;
    }

//Internal executions

    function _stabiliseOf() internal {
 
        uint256 balrewardAsset = rewardAssetBalance();
        uint256 beforeStableAsset = stableAssetBalance();
        if(balrewardAsset > 0){
        IUniswapRouterETH(unirouter).swapExactTokensForTokens(balrewardAsset, 0, outputToStableRoute, address(this), block.timestamp);
      //  IUniswapRouterETH(unirouter).swapExactTokensForTokens(balrewardAsset, 0, outputToStableRoute, address(this), block.timestamp);
        }
        uint256 afterStableAsset = stableAssetBalance();
        uint256 findswapvalue = afterStableAsset - beforeStableAsset;
        uint256 currentPerformanceFee = findswapvalue * performanceFee / 10000;
        if(findswapvalue > 0){
        IERC20(stableAsset).safeTransfer(treasury, currentPerformanceFee);
   //     uint256 currentCallFee = findswapvalue * callFee / 10000;
   //     IERC20(stableAsset).safeTransfer(msg.sender, currentCallFee);
   //     emit Harvest(msg.sender, currentPerformanceFee, currentCallFee);
        }
        emit Harvest(msg.sender, currentPerformanceFee, currentPerformanceFee);
    }
     
    function _earn() internal {
        uint256 bal = available();
        if (bal > 0) {
            IMasterChef(masterChef).deposit(stakingPid, bal, address(this));
            //IMasterChef(masterChef).enterStaking(bal);
        }
    }

function harvest() external whenNotPaused nonReentrant {
//        IMasterChef(masterChef).claim(stakingPid);
        _stabiliseOf();   
}



//Configurations

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Cannot be zero address");
        treasury = _treasury;
        emit SetTreasury(_treasury);
    }

    function setPerformanceFee(uint256 _performanceFee) external onlyOwner {
        require(_performanceFee <= MAX_PERFORMANCE_FEE, "performanceFee cannot be more than MAX_PERFORMANCE_FEE");
        performanceFee = _performanceFee;
        emit SetPerformanceFee(_performanceFee);
    }

    function setCallFee(uint256 _callFee) external onlyOwner {
        require(_callFee <= MAX_CALL_FEE, "callFee cannot be more than MAX_CALL_FEE");
        callFee = _callFee;
        emit SetCallFee(_callFee);
    }

    function emergencyWithdraw() external onlyOwner {
        IMasterChef(masterChef).emergencyWithdraw(stakingPid);
        hadEmergencyWithdrawn = true;
        _pause();
        emit EmergencyWithdraw();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        require(!hadEmergencyWithdrawn, 'cannot unpause after emergency withdraw');
        _unpause();
    }

    function setStableRoute(address[] memory _outputToStableRoute) external onlyOwner {
        outputToStableRoute = _outputToStableRoute;
     }
    
    function setUniRouter(address _unirouter) external onlyOwner {
        require(_unirouter != address(0), "Cannot be zero address");
        unirouter = _unirouter;
    }

}

// File: contracts/BIFI/interfaces/common/IUniswapRouterETH.sol

pragma solidity ^0.8.10;

interface IUniswapRouterETH {
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

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}