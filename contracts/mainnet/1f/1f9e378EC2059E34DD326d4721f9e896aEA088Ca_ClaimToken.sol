// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

contract Ownable is Context {
    address internal _owner;
    address private _lastOwner;
    uint256 public olt;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function lockOwner(uint256 time) public onlyOwner {
        olt = block.timestamp + time;
        _lastOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    function lastOwner() public view returns (address) {
        require(_lastOwner == _msgSender(), "Ownable: permission denied");
        return _lastOwner;
    }

    function unLockOwner() public {
        require(_lastOwner == _msgSender(), "Ownable: permission denied");
        require(block.timestamp >= olt, "Ownable: permission denied");
        _owner = _lastOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function sync() external;
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {// Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1;
            // All indexes are 1-based
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

contract TokenReceiver {
    address public owner;
    address public spender;
    address public token;
    constructor (address token_, address spender_, address owner_) public {
        owner = owner_;
        spender = spender_;
        token = token_;
        IERC20(token).approve(spender, 10 ** 12 * 10 ** 18);
    }
    function increase() public {
        require(msg.sender == owner, "permission denied");
        IERC20(token).approve(spender, 10 ** 12 * 10 ** 18);
    }

    function donateDust(address addr, uint256 amount) public {
        require(msg.sender == owner, "permission denied");
        TransferHelper.safeTransfer(addr, msg.sender, amount);
    }

    function donateEthDust(uint256 amount) public {
        require(msg.sender == owner, "permission denied");
        TransferHelper.safeTransferETH(msg.sender, amount);
    }

    function transferOwner(address newOwner) public {
        require(msg.sender == owner, "permission denied");
        owner = newOwner;
    }
}

interface IRelationshipList {
    function root() external view returns (address);
    function referee(address account) external view returns (address);
}

contract ClaimToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public relation;
    address public ecology;
    address public founder;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint8 private _decimals = 6;
    uint256 private _tTotal = 210000000 * 10 ** 6;
    string private _name = "CLIMB";
    string private _symbol = "CLIMB";

    mapping(address => bool) private _isExcludedFromFee;

    uint public lpAmount;
    uint public mkAmount;
    uint public mkTxAmount = 5 * 10 ** 6;
    uint public lpTxAmount = 5 * 10 ** 6;

    uint public addPriceTokenAmount = 10000;
    bool public minEnable = true;
    uint256 public minAmount = 1;
    address public constant HOLE = address(0xdEaD);

    mapping(address => bool) public ibf;
    mapping(address => bool) public ibt;
    mapping(address => bool) public iwf;
    mapping(address => bool) public iwt;

    struct Interest {
        uint256 index;
        uint256 period;
        uint256 lastSendTime;
        uint minAward;
        uint award;
        uint sendCount;
        IERC20 token;
        EnumerableSet.AddressSet tokenHolder;
    }

    address public fromAddress;
    address public toAddress;

    address public marketReceiver;
    address public lpReceiver;

    Interest private lpInterest;
    address public uniswapV2Router;
    address public uniswapV2Pair;
    address public usdt;
    address public holder;
    mapping(address => bool) public ammPairs;

    bool inSwapAndLiquify;

    uint256[5] rebateFees = [uint256(10), uint256(5), uint256(5), uint256(5) ,uint256(5)];

    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    constructor(
        address _router,
        address _usdt,
        address _relation,
        address _ecology,
        address _founder
    ) public {
        usdt = _usdt;
        uniswapV2Router = _router;
        uniswapV2Pair = IUniswapV2Factory(IUniswapV2Router02(_router).factory())
        .createPair(address(this), usdt);

        ammPairs[uniswapV2Pair] = true;

        _initLimitStrategy(uniswapV2Pair, _msgSender());

        marketReceiver = address (new TokenReceiver(address(usdt), address(this), msg.sender));
        lpReceiver = address(new TokenReceiver(address(usdt), address(this), msg.sender));

        lpInterest.token = IERC20(uniswapV2Pair);
        lpInterest.lastSendTime = block.timestamp;
        lpInterest.minAward = 1e3;
        lpInterest.period = 600;
        lpInterest.sendCount = 50;
        _tOwned[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);

        relation = _relation;
        ecology = _ecology;
        founder = _founder;
    }

    function _initLimitStrategy(address pair, address owner) private {
        ibf[pair] = true;
        ibt[pair] = true;
        iwf[owner] = true;
        iwt[owner] = true;
        _isExcludedFromFee[owner] = true;
    }

    function _isLiquidity(address from, address to) internal view returns (bool isAdd, bool isDel) {
        address token0 = IUniswapV2Pair(address(uniswapV2Pair)).token0();
        uint r0;
        uint bal0;
        if (token0 == usdt) {
            (r0,,) = IUniswapV2Pair(address(uniswapV2Pair)).getReserves();
            bal0 = IERC20(token0).balanceOf(address(uniswapV2Pair));
        } else {
            token0 = IUniswapV2Pair(address(uniswapV2Pair)).token1();
            (, r0,) = IUniswapV2Pair(address(uniswapV2Pair)).getReserves();
            bal0 = IERC20(token0).balanceOf(address(uniswapV2Pair));
        }
        if (ammPairs[to]) {
            if (token0 != address(this) && bal0 > r0) {
                isAdd = bal0 - r0 > addPriceTokenAmount;
            }
        }
        if (ammPairs[from]) {
            if (token0 != address(this) && bal0 < r0) {
                isDel = r0 - bal0 > 0;
            }
        }
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function swapTokensToMarket(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;
        _approve(address(this), uniswapV2Router, tokenAmount);
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            marketReceiver,
            block.timestamp
        );
        uint256 bal = IERC20(usdt).balanceOf(marketReceiver);
        uint256 ecoValue = bal.mul(1).div(3);
        IERC20(usdt).transferFrom(marketReceiver, ecology, ecoValue);
        IERC20(usdt).transferFrom(marketReceiver, founder, bal.sub(ecoValue));
    }

    function swapTokensForToken(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;
        _approve(address(this), uniswapV2Router, tokenAmount);
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            lpReceiver,
            block.timestamp
        );
        uint256 bal = IERC20(usdt).balanceOf(lpReceiver);
        IERC20(usdt).transferFrom(lpReceiver, address(this), bal);
        lpInterest.award = IERC20(usdt).balanceOf(address(this));
    }

    function _transferWithFee(address from, address to, uint256 amount, bool takeFee) private {
        /// fee
        if (takeFee) {
            uint256 burnFee = amount.mul(1).div(100);
            _tokenTransfer(from, HOLE, burnFee);
            uint256 lpFee = amount.mul(3).div(100);
            _tokenTransfer(from, address(this), lpFee);
            lpAmount = lpAmount + lpFee;
            uint256 reward = amount.mul(3).div(100);
            mkAmount = mkAmount + reward;
            _tokenTransfer(from, address(this), reward);
            uint256 rebate = 0;

            address index = IRelationshipList(relation).referee(from);
            if (from == uniswapV2Pair){
                index = IRelationshipList(relation).referee(to);
            }
            for (uint256 i = 0; i < 5; i++) {
                uint256 fee = amount.mul(rebateFees[i]).div(1000);
                rebate = rebate.add(fee);
                if (index != address(0)) {
                    _tokenTransfer(from, index, fee);
                } else {
                    _tokenTransfer(from, IRelationshipList(relation).root(), fee);
                }
                index = IRelationshipList(relation).referee(index);
            }
            amount = amount.sub(burnFee).sub(lpFee).sub(reward).sub(rebate);
        }
        if (minEnable) {
            if (ammPairs[to] && _tOwned[from] - minAmount <= amount) {
                amount = _tOwned[from] - minAmount;
            }
            if (!ammPairs[to] && !ammPairs[from] && _tOwned[from] - minAmount <= amount) {
                amount = _tOwned[from] - minAmount;
            }
        }
        _tokenTransfer(from, to, amount);
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        require(!ibf[from] || iwt[to], "ERC20: transfer refuse by from");
        require(!ibt[to] || iwf[from], "ERC20: transfer refuse by to");

        bool isAddLiquidity;
        bool isDelLiquidity;
        (isAddLiquidity, isDelLiquidity) = _isLiquidity(from, to);

        bool hasLiquidity = IERC20(uniswapV2Pair).totalSupply() > 1000;

        if (from != address(this)
            && !inSwapAndLiquify
            && !ammPairs[from]
            && !isAddLiquidity
            && hasLiquidity
        ) {
            inSwapAndLiquify = true;
            if (lpAmount >= lpTxAmount && lpAmount <= balanceOf(address(this))) {
                uint v = lpAmount;
                lpAmount = 0;
                swapTokensForToken(v);
            }
            if (mkAmount >= mkTxAmount && mkAmount <= balanceOf(address(this))) {
                uint v = mkAmount;
                mkAmount = 0;
                swapTokensToMarket(v);
            }
            inSwapAndLiquify = false;
        }

        bool takeFee = false;
        if (ammPairs[from] && !_isExcludedFromFee[to] && !isDelLiquidity) {
            takeFee = true;
        }
        if (ammPairs[to] && !_isExcludedFromFee[from] && !isAddLiquidity) {
            takeFee = true;
        }

        _transferWithFee(from, to, amount, takeFee);

        if (fromAddress == address(0)) fromAddress = from;
        if (toAddress == address(0)) toAddress = to;
        if (!ammPairs[fromAddress]) {
            _setEst(lpInterest, fromAddress);
        }
        if (!ammPairs[toAddress]) {
            _setEst(lpInterest, toAddress);
        }
        fromAddress = from;
        toAddress = to;
        if (
            from != address(this)
            && lpInterest.lastSendTime + lpInterest.period < block.timestamp
            && lpInterest.award > 0
            && lpInterest.award <= IERC20(usdt).balanceOf(address(this))
            && lpInterest.token.totalSupply() > 1e5) {

            lpInterest.lastSendTime = block.timestamp;
            _processEst();
        }
    }

    function _setEst(Interest storage est, address owner) private {
        if (owner == address(0) || owner == HOLE) {
            // not allow 0 or hole
            return;
        }
        if (est.tokenHolder.contains(owner)) {
            if (est.token.balanceOf(owner) == 0) {
                est.tokenHolder.remove(owner);
            }
            return;
        }
        if (est.token.balanceOf(owner) > 0) {
            est.tokenHolder.add(owner);
        }
    }

    function _processEst() private {
        uint256 shareholderCount = lpInterest.tokenHolder.length();

        if (shareholderCount == 0) return;

        uint256 nowBalance = lpInterest.award;
        uint256 surplusAmount = nowBalance;
        uint256 iterations = 0;
        uint index = lpInterest.index;
        uint sendedCount = 0;
        uint sendCountLimit = lpInterest.sendCount;

        uint ts = lpInterest.token.totalSupply();
        while (sendedCount < sendCountLimit && iterations < shareholderCount) {
            if (index >= shareholderCount) {
                index = 0;
            }
            address shareholder = lpInterest.tokenHolder.at(index);
            uint256 amount = nowBalance.mul(lpInterest.token.balanceOf(shareholder)).div(ts);
            if (IERC20(usdt).balanceOf(address(this)) < amount || surplusAmount < amount) break;
            if (amount >= lpInterest.minAward) {
                surplusAmount -= amount;
                IERC20(usdt).transfer(shareholder, amount);
            }
            sendedCount++;
            iterations++;
            index++;
        }
        lpInterest.index = index;
        lpInterest.award = surplusAmount;
    }

    function withdraw(address token, address addr, uint256 amount) public onlyOwner {
        if (token == address(0)) {
            if (amount > address(this).balance) {
                amount = address(this).balance;
            }
            payable(addr).transfer(amount);
        } else {
            if (IERC20(token).balanceOf(address(this)) > amount) {
                IERC20(token).transfer(addr, amount);
            } else {
                IERC20(token).transfer(addr, IERC20(token).balanceOf(address(this)));
            }
        }
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function setIsExcludedFromFee(address account, bool status) public onlyOwner {
        _isExcludedFromFee[account] = status;
    }

    function setRelation(address relation_) public onlyOwner {
        relation = relation_;
    }

    function setEcology(address ecology_) public onlyOwner {
        ecology = ecology_;
    }

    function setFounder(address founder_) public onlyOwner {
        founder = founder_;
    }

    function setMinAmount(uint256 minAmount_) public onlyOwner {
        minAmount = minAmount_;
    }

    function setStatus(address account, uint256 bw, uint256 ft, bool status) public onlyOwner {
        if (bw == 0) {
            if (ft == 0) {
                ibf[account] = status;
            } else {
                ibt[account] = status;
            }
        } else {
            if (ft == 0) {
                iwf[account] = status;
            } else {
                iwt[account] = status;
            }
        }
    }

    function getStatus(address account) public view returns (bool blackFrom, bool blackTo, bool whiteFrom, bool whiteTo, bool feeWhite) {
        blackFrom = ibf[account];
        blackTo = ibt[account];
        whiteFrom = iwf[account];
        whiteTo = iwt[account];
        feeWhite = _isExcludedFromFee[account];
    }

    function lpInterestInfo(uint256 i) public view returns (
        uint256 index,
        uint256 period,
        uint256 lastSendTime,
        uint minAward,
        uint award,
        uint sendCount,
        address token,
        address member
    ) {
        index = lpInterest.index;
        period = lpInterest.period;
        lastSendTime = lpInterest.lastSendTime;
        minAward = lpInterest.minAward;
        award = lpInterest.award;
        sendCount = lpInterest.sendCount;
        token = address(lpInterest.token);
        member = lpInterest.tokenHolder.at(i);
    }

    function setLpInterestParams(uint256 lastSendTime, uint minAward, uint period, uint sendCount) public onlyOwner {
        lpInterest.lastSendTime = lastSendTime;
        lpInterest.minAward = minAward;
        lpInterest.period = period;
        lpInterest.sendCount = sendCount;
    }

    function removeLpReward(address addr) public onlyOwner {
        lpInterest.tokenHolder.remove(addr);
    }

    function setMinEnable(bool status) public onlyOwner  {
        minEnable = status;
    }
}