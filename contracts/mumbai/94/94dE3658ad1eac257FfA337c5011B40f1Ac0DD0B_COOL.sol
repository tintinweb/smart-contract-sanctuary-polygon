/**
 *Submitted for verification at polygonscan.com on 2023-02-15
*/

// SPDX-License-Identifier: MIT
// Developed by t.me/LinksUltima
pragma solidity ^0.8.17;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

abstract contract Ownable {
    error NotOwner();

    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract COOL is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    string private constant _NAME = "Coolness";
    string private constant _SYMBOL = "COOL";
    uint8 private constant _DECIMALS = 18;
    address public FeeAddress;
    address public LiqAddress;
    address public constant dEaD = 0x000000000000000000000000000000000000dEaD;

    uint256 private constant _MAX = ~uint256(0);
    uint256 private constant _DECIMALFACTOR = 10**_DECIMALS;
    uint8 private constant _GRANULARITY = 100;

    uint256 private constant _tTotal = 40_000_000 * _DECIMALFACTOR;
    uint256 private _rTotal;

    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;
    uint256 private _tMTotal;
    uint256 private _tLiqTotal;

    uint256 public _TAX_FEE;
    uint256 public _BURN_FEE;
    uint256 public _M_FEE;
    uint256 public _LIQ_FEE;

    uint256 private ORIG_TAX_FEE;
    uint256 private ORIG_BURN_FEE;
    uint256 private ORIG_M_FEE;
    uint256 private ORIG_LIQ_FEE;

    constructor(
        uint256 _txFee,
        uint256 _burnFee,
        uint256 _mFee,
        uint256 _LiqFee,
        address tokenOwner
    ) payable {
        _isExcluded[dEaD] = true;
        _isExcluded[tokenOwner] = true;

        _excluded.push(dEaD);
        _excluded.push(tokenOwner);

        _rTotal = (_MAX - (_MAX % _tTotal));
        _TAX_FEE = _txFee;
        _BURN_FEE = _burnFee;
        _M_FEE = _mFee;
        _LIQ_FEE = _LiqFee;
        ORIG_TAX_FEE = _TAX_FEE;
        ORIG_BURN_FEE = _BURN_FEE;
        ORIG_M_FEE = _M_FEE;
        ORIG_LIQ_FEE = _LIQ_FEE;

        _rOwned[tokenOwner] = _rTotal;
        _tOwned[tokenOwner] = _tTotal;
        emit Transfer(address(0), tokenOwner, _tTotal);

        transferOwnership(tokenOwner);
    }

    function name() external pure returns (string memory) {
        return _NAME;
    }

    function symbol() external pure returns (string memory) {
        return _SYMBOL;
    }

    function decimals() external pure returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() external pure returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) external view returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "Transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "Decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcluded(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function totalBurn() external view returns (uint256) {
        return _tBurnTotal;
    }

    function totalMfee() external view returns (uint256) {
        return _tMTotal;
    }

    function totalLiqfee() external view returns (uint256) {
        return _tLiqTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        private
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , , , ) = _getValues(tAmount);
            return rAmount;
        }
        (, uint256 rTransferAmount, , , , , , ) = _getValues(tAmount);
        return rTransferAmount;
    }

    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        return rAmount.div(_getRate());
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        bool takeFee = true;
        if (
            _isExcluded[recipient] ||
            _isExcluded[sender] ||
            (_TAX_FEE.add(_BURN_FEE).add(_M_FEE) == 0)
        ) {
            takeFee = false;
        }

        if (!takeFee) removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount, takeFee);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount, takeFee);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount, takeFee);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount, takeFee);
        } else {
            _transferStandard(sender, recipient, amount, takeFee);
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tBurn,
            uint256 tMfee,
            uint256 tLiqFee
        ) = _getValues(tAmount);

        _standardTransferContent(sender, recipient, rAmount, rTransferAmount);
        if (takeFee) {
            _sendFees(tMfee, tLiqFee, sender);
        }
        _reflectFee(rFee, tFee, tBurn, tMfee, tLiqFee, takeFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _standardTransferContent(
        address sender,
        address recipient,
        uint256 rAmount,
        uint256 rTransferAmount
    ) private {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tBurn,
            uint256 tMFee,
            uint256 tLiqFee
        ) = _getValues(tAmount);

        _excludedFromTransferContent(
            sender,
            recipient,
            tTransferAmount,
            rAmount,
            rTransferAmount
        );
        if (takeFee) {
            _sendFees(tMFee, tLiqFee, sender);
        }
        _reflectFee(rFee, tFee, tBurn, tMFee, tLiqFee, takeFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _excludedFromTransferContent(
        address sender,
        address recipient,
        uint256 tTransferAmount,
        uint256 rAmount,
        uint256 rTransferAmount
    ) private {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tBurn,
            uint256 tMFee,
            uint256 tLiqFee
        ) = _getValues(tAmount);

        _excludedToTransferContent(
            sender,
            recipient,
            tAmount,
            rAmount,
            rTransferAmount
        );
        if (takeFee) {
            _sendFees(tMFee, tLiqFee, sender);
        }
        _reflectFee(rFee, tFee, tBurn, tMFee, tLiqFee, takeFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _excludedToTransferContent(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 rAmount,
        uint256 rTransferAmount
    ) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tBurn,
            uint256 tMFee,
            uint256 tLiqFee
        ) = _getValues(tAmount);

        _bothTransferContent(
            sender,
            recipient,
            tAmount,
            rAmount,
            tTransferAmount,
            rTransferAmount
        );
        if (takeFee) {
            _sendFees(tMFee, tLiqFee, sender);
        }
        _reflectFee(rFee, tFee, tBurn, tMFee, tLiqFee, takeFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _bothTransferContent(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 rAmount,
        uint256 tTransferAmount,
        uint256 rTransferAmount
    ) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    function _reflectFee(
        uint256 rFee,
        uint256 tFee,
        uint256 tBurn,
        uint256 tMFee,
        uint256 tLiqFee,
        bool takeFee
    ) private {
        _rTotal = _rTotal.sub(rFee);

        if (takeFee) {
            _tFeeTotal = _tFeeTotal.add(tFee);
            _tBurnTotal = _tBurnTotal.add(tBurn);
            _tMTotal = _tMTotal.add(tMFee);
            _tLiqTotal = _tLiqTotal.add(tLiqFee);

            uint256 currentRate = _getRate();
            uint256 rBurnFee = tBurn.mul(currentRate);
            _rOwned[dEaD] = _rOwned[dEaD].add(rBurnFee);
            _tOwned[dEaD] = _tOwned[dEaD].add(tBurn);
            emit Transfer(address(this), address(dEaD), tBurn);
        }
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256[4] memory tFees = _getTBasics(tAmount);
        uint256 tTransferAmount = getTTransferAmount(tAmount, tFees);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rFee) = _getRBasics(
            tAmount,
            tFees[0],
            currentRate
        );
        uint256 rTransferAmount = _getRTransferAmount(
            rAmount,
            rFee,
            [tFees[1], tFees[2], tFees[3]],
            currentRate
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFees[0],
            tFees[1],
            tFees[2],
            tFees[3]
        );
    }

    function _getTBasics(uint256 tAmount)
        private
        view
        returns (uint256[4] memory)
    {
        return [
            ((tAmount.mul(_TAX_FEE)).div(_GRANULARITY)).div(_GRANULARITY),
            ((tAmount.mul(_BURN_FEE)).div(_GRANULARITY)).div(_GRANULARITY),
            ((tAmount.mul(_M_FEE)).div(_GRANULARITY)).div(_GRANULARITY),
            ((tAmount.mul(_LIQ_FEE)).div(_GRANULARITY)).div(_GRANULARITY)
        ];
    }

    function getTTransferAmount(uint256 tAmount, uint256[4] memory fees)
        private
        pure
        returns (uint256)
    {
        return tAmount.sub(fees[0]).sub(fees[1]).sub(fees[2]).sub(fees[3]);
    }

    function _getRBasics(
        uint256 tAmount,
        uint256 tFee,
        uint256 currentRate
    ) private pure returns (uint256, uint256) {
        return (tAmount.mul(currentRate), tFee.mul(currentRate));
    }

    function _getRTransferAmount(
        uint256 rAmount,
        uint256 rFee,
        uint256[3] memory tFees,
        uint256 currentRate
    ) private pure returns (uint256) {
        uint256[4] memory rFees = [
            rFee,
            tFees[0].mul(currentRate),
            tFees[1].mul(currentRate),
            tFees[2].mul(currentRate)
        ];

        return rAmount.sub(rFees[0]).sub(rFees[1]).sub(rFees[2]).sub(rFees[3]);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _sendFees(
        uint256 tMFee,
        uint256 tLiqFee,
        address sender
    ) private {
        uint256 currentRate = _getRate();
        uint256 rMFee = tMFee.mul(currentRate);
        _rOwned[FeeAddress] = _rOwned[FeeAddress].add(rMFee);
        _tOwned[FeeAddress] = _tOwned[FeeAddress].add(tMFee);
        emit Transfer(sender, FeeAddress, tMFee);

        uint256 rLiqFee = tLiqFee.mul(currentRate);
        _rOwned[LiqAddress] = _rOwned[LiqAddress].add(rLiqFee);
        _tOwned[LiqAddress] = _tOwned[LiqAddress].add(tLiqFee);
        emit Transfer(sender, LiqAddress, tLiqFee);
    }

    function removeAllFee() private {
        if (_TAX_FEE == 0 && _BURN_FEE == 0 && _M_FEE == 0 && _LIQ_FEE == 0)
            return;

        ORIG_TAX_FEE = _TAX_FEE;
        ORIG_BURN_FEE = _BURN_FEE;
        ORIG_M_FEE = _M_FEE;
        ORIG_LIQ_FEE = _LIQ_FEE;

        _TAX_FEE = 0;
        _BURN_FEE = 0;
        _M_FEE = 0;
        _LIQ_FEE = 0;
    }

    function restoreAllFee() private {
        _TAX_FEE = ORIG_TAX_FEE;
        _BURN_FEE = ORIG_BURN_FEE;
        _M_FEE = ORIG_M_FEE;
        _LIQ_FEE = ORIG_LIQ_FEE;
    }

    function excludeAccount(address account) external onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function setFeesRecipients(address _fee, address _liq) external onlyOwner {
        FeeAddress = _fee;
        LiqAddress = _liq;

        //Exclude addresses from paying the fees
        if (!_isExcluded[FeeAddress]) {
            if (_rOwned[FeeAddress] > 0) {
                _tOwned[FeeAddress] = tokenFromReflection(_rOwned[FeeAddress]);
            }
            _isExcluded[FeeAddress] = true;
            _excluded.push(FeeAddress);
        }

        if (!_isExcluded[LiqAddress]) {
            if (_rOwned[LiqAddress] > 0) {
                _tOwned[LiqAddress] = tokenFromReflection(_rOwned[LiqAddress]);
            }
            _isExcluded[LiqAddress] = true;
            _excluded.push(LiqAddress);
        }
    }

    function updateFee(
        uint256 _txFee,
        uint256 _burnFee,
        uint256 _MFee,
        uint256 _LiqFee
    ) external onlyOwner {
        require(
            _txFee + _burnFee + _MFee + _LiqFee <= 2500,
            "The total commission should not exceed 25%"
        );
        _TAX_FEE = _txFee;
        _BURN_FEE = _burnFee;
        _M_FEE = _MFee;
        _LIQ_FEE = _LiqFee;
        ORIG_TAX_FEE = _TAX_FEE;
        ORIG_BURN_FEE = _BURN_FEE;
        ORIG_M_FEE = _M_FEE;
        ORIG_LIQ_FEE = _LIQ_FEE;
    }
}