// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IPancakeV2Pair {

    function allowance(address owner, address spender) external view returns(uint256);

    function approve(address spender, uint256 value) external returns(bool);

    function balanceOf(address owner) external view returns(uint256);

    function burn(address to) external returns(uint256 amount0, uint256 amount1);

    function decimals() external pure returns(uint8);

    function DOMAIN_SEPARATOR() external view returns(bytes32);

    function factory() external view returns(address);

    function getReserves() external view returns(uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function initialize(address, address) external;

    function kLast() external view returns(uint256);

    function MINIMUM_LIQUIDITY() external pure returns(uint256);

    function mint(address to) external returns(uint256 liquidity);

    function name() external pure returns(string memory);

    function nonces(address owner) external view returns(uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    function PERMIT_TYPEHASH() external pure returns(bytes32);

    function price0CumulativeLast() external view returns(uint256);

    function price1CumulativeLast() external view returns(uint256);

    function symbol() external pure returns(string memory);

    function token0() external view returns(address);

    function token1() external view returns(address);

    function totalSupply() external view returns(uint256);

    function transfer(address to, uint256 value) external returns(bool);

    function transferFrom(address from, address to, uint256 value) external returns(bool);

    function skim(address to) external;

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function sync() external;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);

    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);

    event Sync(uint112 reserve0, uint112 reserve1);
    
    event Transfer(address indexed from, address indexed to, uint256 value);

}

interface IPancakeV2Factory {

    function allPairs(uint256) external view returns(address pair);

    function allPairsLength() external view returns(uint256);

    function createPair(address tokenA, address tokenB) external returns(address pair);

    function feeTo() external view returns(address);

    function feeToSetter() external view returns(address);

    function getPair(address tokenA, address tokenB) external view returns(address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

}

interface IPancakeV2Router01 {

    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns(uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns(uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function factory() external pure returns(address);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns(uint256 amountIn);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns(uint256 amountOut);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns(uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns(uint256[] memory amounts);

    function removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns(uint256 amountA, uint256 amountB);

    function removeLiquidityETH(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external returns(uint256 amountToken, uint256 amountETH);

    function removeLiquidityETHWithPermit(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns(uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns(uint256 amountA, uint256 amountB);

    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline) external payable returns(uint256[] memory amounts);

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable returns(uint256[] memory amounts);

    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns(uint256[] memory amounts);

    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns(uint256[] memory amounts);

    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external returns(uint256[] memory amounts);

    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external returns(uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns(uint256 amountB);

    function WETH() external pure returns(address);

}

interface IPancakeV2Router02 is IPancakeV2Router01 {

    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;

    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external returns(uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns(uint256 amountETH);

}

contract liquidityTimeLock is Context, Ownable {

    IPancakeV2Router02 public SwapRouter;

    address public pairAddress;
    address public token1;
    address public token2;
    address payable feeAddress;

    uint256 public fees;
    uint256 public feeBalance;
    uint256 public minLockTimeInSeconds = 60;

    mapping(address => tokenLP) public LPtokens;
    mapping(address => mapping(address => userLPlock)) public userLPlocks;
    mapping(address => address[]) userLPlocksAddress;
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public _ExcludedFromFee;

    struct tokenLP {
        address LPAddress;
        address token1;
        address token2;
        uint256 totalValueLocked;
        uint256 lockBalance;
        uint256 totalLocks;
        uint256 totalActiveLocks;
        uint256 isActive;
        uint256 islocked;
        bool isSet;
    }

    struct lpLock {
        uint256 amount;
        address reciever;
        uint256 unlockTime;
        bool isActive;
        bool isSet;
    }

    struct userLPlock {
        address LPAddress;
        uint256 locks;
        uint256[] activeLocksID;
        uint256 totalValueLocked;
        uint256 lockBalance;
        mapping(uint256 => lpLock) lpLocks;
    }

    event liquidityLocked(address pairAddress, address indexed locker, address indexed owner, uint256 amount, uint256 unlockTime, uint256 lockID);
    event liquidityUnLocked(address pairAddress, address indexed reciever, uint256 amount, uint256 lockID);
    event liquidityMigrated(address pairAddress, address indexed oldOwner, address indexed newOwner, uint256 lockID);

    modifier onlyAdmin() {
        require(isAdmin[_msgSender()] || _msgSender() == owner(), "unathourized");
        _;
    }

    //Constructor
    constructor(address _pairAddress, address _token1, address _token2) {
        isAdmin[_msgSender()] = true;
        pairAddress = _pairAddress;
        token1 = _token1;
        token2 = _token2;
    }

    //User
    function lockLiquidity(uint256 amount, uint256 periodInSeconds, address _reciever) public payable {
        address lockowner = _reciever;
        require(periodInSeconds >= minLockTimeInSeconds, "duration too Short");
        if (pairAddress == address(0)) {
            _filterPair(token1, token2);
            pairAddress = getPairAddress(token1, token2);
        } else {
            pairAddress = pairAddress;
            (token1, token2) = getTokens(pairAddress);
            addLpPair(pairAddress, token1, token2);
        }
        require(processPayment(pairAddress, amount), "insuficient balance approved");
        //   amount = deductFees( pairAddress ,amount);
        bool inArray;
        for (uint256 index; index < userLPlocksAddress[_reciever].length; index++) {
            if (userLPlocksAddress[_reciever][index] == pairAddress) {
                inArray = true;
                break;
            }
        }
        if (!inArray) userLPlocksAddress[_reciever].push(pairAddress);
        userLPlock storage newLpLock = userLPlocks[pairAddress][lockowner];
        newLpLock.LPAddress = pairAddress;
        newLpLock.locks++;
        newLpLock.activeLocksID.push(newLpLock.locks);
        newLpLock.totalValueLocked += amount;
        newLpLock.lockBalance += amount;
        lpLock storage newlplock = newLpLock.lpLocks[newLpLock.locks];
        newlplock.amount = amount;
        newlplock.reciever = lockowner;
        newlplock.unlockTime = block.timestamp + (periodInSeconds * 1 seconds);
        newlplock.isActive = true;
        newlplock.isSet = true;
        LPtokens[pairAddress].totalValueLocked += amount;
        LPtokens[pairAddress].lockBalance += amount;
        LPtokens[pairAddress].totalLocks++;
        LPtokens[pairAddress].totalActiveLocks++;
        emit liquidityLocked(pairAddress, _msgSender(), _reciever, amount, newlplock.unlockTime, newLpLock.locks);
    }

    function migrateLiquidity(address _pairAddress, uint256 lockID, address to) public {
        lpLock storage currentLpLock = userLPlocks[_pairAddress][_msgSender()].lpLocks[lockID];
        userLPlock storage currentUserLpLock = userLPlocks[_pairAddress][_msgSender()];
        require(currentLpLock.isSet, "invalid lock ID");
        require(currentLpLock.isActive, "lock not active");
        currentLpLock.isActive = false;
        currentUserLpLock.lockBalance -= currentLpLock.amount;
        currentUserLpLock.totalValueLocked -= currentLpLock.amount;
        for (uint256 index = 0; index < currentUserLpLock.activeLocksID.length; index++) {
            if (currentUserLpLock.activeLocksID[index] == lockID) {
                currentUserLpLock.activeLocksID[index] = currentUserLpLock.activeLocksID[currentUserLpLock.activeLocksID.length - 1];
                currentUserLpLock.activeLocksID.pop();
            }
        }
        bool inArray;
        for (uint256 index; index < userLPlocksAddress[to].length; index++) {
            if (userLPlocksAddress[to][index] == _pairAddress) {
                inArray = true;
                break;
            }
        }
        if (!inArray) userLPlocksAddress[to].push(_pairAddress);
        userLPlock storage newLpLock = userLPlocks[_pairAddress][to];
        newLpLock.LPAddress = _pairAddress;
        newLpLock.locks++;
        newLpLock.activeLocksID.push(newLpLock.locks);
        newLpLock.totalValueLocked += currentLpLock.amount;
        newLpLock.lockBalance += currentLpLock.amount;
        lpLock storage newlplock = newLpLock.lpLocks[newLpLock.locks];
        newlplock.amount = currentLpLock.amount;
        newlplock.reciever = to;
        newlplock.unlockTime = currentLpLock.unlockTime;
        newlplock.isActive = currentLpLock.isActive;
        newlplock.isSet = currentLpLock.isSet;
        emit liquidityMigrated(_pairAddress, _msgSender(), to, lockID);
    }

    function unLockLiquidity(address _pairAddress, uint256 lockID) public {
        require(userLPlocks[_pairAddress][_msgSender()].activeLocksID.length > 0, "no active lock for pair address");
        if (lockID == 0) {
            for (uint256 index = 0; index < userLPlocks[_pairAddress][_msgSender()].activeLocksID.length; index++) {
                _unLockLiquidity(_pairAddress, userLPlocks[_pairAddress][_msgSender()].activeLocksID[index]);
            }
        } else {
            require(_unLockLiquidity(_pairAddress, lockID), "Unlock time not reached");
        }
    }

    //View
    function getActiveLPLockIDs(address _pairAddress) public view returns(uint256[] memory) {
        return userLPlocks[_pairAddress][_msgSender()].activeLocksID;
    }

    function getLockInfo(address user, uint256 lockId) public view returns (uint256, address, uint256, bool) {
        require(lockId > 0 && lockId <= userLPlocks[pairAddress][user].locks, "Invalid lock ID");
        lpLock storage lock = userLPlocks[pairAddress][user].lpLocks[lockId];
        require(lock.isSet, "Lock does not exist");
        return (lock.amount, lock.reciever, lock.unlockTime, lock.isActive);
    }

    function getLPLock(address _pairAddress, uint256 lockID) public view returns(lpLock memory) {
        require(userLPlocks[_pairAddress][_msgSender()].lpLocks[lockID].isSet, "invalid lockID");
        return userLPlocks[_pairAddress][_msgSender()].lpLocks[lockID];
    }

    function getPairAddress(address _token1, address _token2) public view returns(address) {
        return IPancakeV2Factory(SwapRouter.factory()).getPair(_token1, _token2);
    }

    function getTotalLocksBalance(address _pairAddress) public view returns(uint256) {
        return userLPlocks[_pairAddress][_msgSender()].lockBalance;
    }

    function getTotalLocksValue(address _pairAddress) public view returns(uint256) {
        return userLPlocks[_pairAddress][_msgSender()].totalValueLocked;
    }

    function getTokens(address _pairAddress) public view returns(address _token1, address _token2) {
        IPancakeV2Pair pair = IPancakeV2Pair(_pairAddress);
        _token1 = pair.token0();
        _token2 = pair.token1();
        require(_token1 != address(0) || _token2 != address(0), "invalid lp pair address");
    }

    function userActiveLocksids(address _user) public view returns(uint256[] memory) {
        userLPlock storage newLpLock = userLPlocks[pairAddress][_user];
        return newLpLock.activeLocksID;
    }

    function getUserLPlocksAddress() public view returns(address[] memory) {
        return userLPlocksAddress[_msgSender()];
    }

    //Internal
    function _filterPair(address _token1, address _token2) private {
        // address pairAddress = getPairAddress(token1, token2);
        require(pairAddress != address(0), "pair not created");
        addLpPair(pairAddress, _token1, _token2);
    }

    function _unLockLiquidity(address _pairAddress, uint256 lockID) private returns(bool) {
        lpLock storage currentLpLock = userLPlocks[_pairAddress][_msgSender()].lpLocks[lockID];
        userLPlock storage currentUserLpLock = userLPlocks[_pairAddress][_msgSender()];
        if (!currentLpLock.isSet) return false;
        if (!currentLpLock.isActive) return false;
        if (currentLpLock.unlockTime > block.timestamp) return false;
        //unlock and send token;
        currentLpLock.isActive = false;
        IERC20 token = IERC20(_pairAddress);
        token.transfer(currentLpLock.reciever, currentLpLock.amount);
        //deduct balances
        currentUserLpLock.lockBalance -= currentLpLock.amount;
        for (uint256 index = 0; index < currentUserLpLock.activeLocksID.length; index++) {
            if (currentUserLpLock.activeLocksID[index] == lockID) {
                currentUserLpLock.activeLocksID[index] = currentUserLpLock.activeLocksID[currentUserLpLock.activeLocksID.length - 1];
                currentUserLpLock.activeLocksID.pop();
                break;
            }
        }
        tokenLP storage currentLpToken = LPtokens[_pairAddress];
        currentLpToken.lockBalance -= currentLpLock.amount;
        currentLpToken.totalActiveLocks--;
        emit liquidityUnLocked(_pairAddress, currentLpLock.reciever, currentLpLock.amount, lockID);
        if (currentUserLpLock.lockBalance == 0) {
            //   userLPlocksAddress[_reciever].push(pairAddress)
            for (uint256 index; index < userLPlocksAddress[_msgSender()].length; index++) {
                if (userLPlocksAddress[_msgSender()][index] == _pairAddress) {
                    userLPlocksAddress[_msgSender()][index] = userLPlocksAddress[_msgSender()][userLPlocksAddress[_msgSender()].length - 1];
                    userLPlocksAddress[_msgSender()].pop();
                    break;
                }
            }
        }
        return true;
    }

    function addLpPair(address _pairAddress, address _token1, address _token2) private {
        if (!LPtokens[_pairAddress].isSet) {
            tokenLP storage newLpToken = LPtokens[_pairAddress];
            newLpToken.LPAddress = _pairAddress;
            newLpToken.token1 = _token1;
            newLpToken.token2 = _token2;
            newLpToken.isSet = true;
        }
    }

    function processPayment(address _pairAddress, uint256 amount) private returns(bool) {
        if (fees > 0 && !_ExcludedFromFee[_msgSender()]) {
            require(msg.value >= fees, "insuficient fiat fee balance");
            feeBalance += msg.value;
        }
        IERC20 currentPair = IERC20(_pairAddress);
        if (currentPair.allowance(_msgSender(), address(this)) >= amount) {
            currentPair.transferFrom(_msgSender(), address(this), amount);
            return true;
        } else {
            return false;
        }
    }

    //Admin
    function setAdmin(address _admin, bool _isAdmin) public onlyOwner {
        isAdmin[_admin] = _isAdmin;
    }

    function setExcludeFromFees(address account, bool _exclude) external onlyAdmin {
        _ExcludedFromFee[account] = _exclude;
    }

    function setFees(uint256 _fees) public onlyAdmin {
        fees = _fees;
    }

    function setFeeAddress(address payable _feeAddress) public onlyAdmin {
        feeAddress = _feeAddress;
    }

    function setminLockTimeInSeconds(uint256 _minLockTimeInSeconds) public onlyAdmin {
        minLockTimeInSeconds = _minLockTimeInSeconds;
    }

    function setPairAddress(address _pairAddress) public onlyAdmin() {
        pairAddress = _pairAddress;

    }

    function setToken1(address _token1) public onlyAdmin() {
        token1 = _token1;

    }

    function setToken2(address _token2) public onlyAdmin() {
        token2 = _token2;

    }

    function updateSwapRouter(address _router) public onlyAdmin() {
        SwapRouter = IPancakeV2Router02(_router);

    }

    function withdrawFees() public onlyOwner {
        require(feeBalance > 0, "insufient funds");
        feeAddress.transfer(feeBalance);
        feeBalance = 0;
    }

}