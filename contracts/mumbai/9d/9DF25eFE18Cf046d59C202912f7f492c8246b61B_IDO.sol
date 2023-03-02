/**
 *Submitted for verification at polygonscan.com on 2023-03-01
*/

// SPDX-License-Identifier: MIT
// Developed by https://t.me/LinksUltima
pragma solidity ^0.8.17;

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

library RevertReasonForwarder {
    function reRevert() internal pure {
        // bubble up revert reason from latest external call
        /// @solidity memory-safe-assembly
        assembly {
            // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize())
            revert(ptr, returndatasize())
        }
    }
}

interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

interface IDaiLikePermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

library SafeERC20 {
    error SafeTransferFailed();
    error SafeTransferFromFailed();
    error ForceApproveFailed();
    error SafeIncreaseAllowanceFailed();
    error SafeDecreaseAllowanceFailed();
    error SafePermitBadLength();

    // Ensures method do not revert or return boolean `true`, admits call to non-smart-contract
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bytes4 selector = token.transferFrom.selector;
        bool success;
        /// @solidity memory-safe-assembly
        assembly {
            // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            success := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    // Ensures method do not revert or return boolean `true`, admits call to non-smart-contract
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.transfer.selector, to, value)) {
            revert SafeTransferFailed();
        }
    }

    // If `approve(from, to, amount)` fails, try to `approve(from, to, 0)` before retry
    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.approve.selector, spender, value)) {
            if (
                !_makeCall(token, token.approve.selector, spender, 0) ||
                !_makeCall(token, token.approve.selector, spender, value)
            ) {
                revert ForceApproveFailed();
            }
        }
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > type(uint256).max - allowance)
            revert SafeIncreaseAllowanceFailed();
        forceApprove(token, spender, allowance + value);
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > allowance) revert SafeDecreaseAllowanceFailed();
        forceApprove(token, spender, allowance - value);
    }

    function safePermit(IERC20 token, bytes calldata permit) internal {
        bool success;
        if (permit.length == 32 * 7) {
            success = _makeCalldataCall(
                token,
                IERC20Permit.permit.selector,
                permit
            );
        } else if (permit.length == 32 * 8) {
            success = _makeCalldataCall(
                token,
                IDaiLikePermit.permit.selector,
                permit
            );
        } else {
            revert SafePermitBadLength();
        }
        if (!success) RevertReasonForwarder.reRevert();
    }

    function _makeCall(
        IERC20 token,
        bytes4 selector,
        address to,
        uint256 amount
    ) private returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly {
            // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), to)
            mstore(add(data, 0x24), amount)
            success := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
    }

    function _makeCalldataCall(
        IERC20 token,
        bytes4 selector,
        bytes calldata args
    ) private returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly {
            // solhint-disable-line no-inline-assembly
            let len := add(4, args.length)
            let data := mload(0x40)

            mstore(data, selector)
            calldatacopy(add(data, 0x04), args.offset, args.length)
            success := call(gas(), token, 0, data, len, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
    }
}

interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

interface iIDO {
    function buyTokens(address ref) external payable returns (uint256);

    function buyTokens_WETH(uint256 amount, address ref)
        external
        returns (uint256);

    function usersCanBuy() external view returns (uint256);

    function getMinToBuyInWeth() external view returns (uint256);

    function canClaimTokens() external view returns (bool);
}

interface iLiquidity {
    function getSeconds() external view returns (uint256);

    function WETH() external view returns (address);

    function Token() external view returns (address);
}

library IDOErrors {
    error SendMoreETH();
    error SendSmallerETH();
    error IdoNotOpen();
    error DontHaveSellTokens();
    error EthTransferFailed();
    error cantClaimTokens();
}

contract IDO is Ownable, iIDO {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable Token;
    IWETH9 public immutable WETH;
    address public immutable liquidityAddress;

    uint256 public immutable price;
    uint256 public immutable ownerPercent;
    uint256[4] private refsPercents;
    uint256 public EthToCollect;
    uint256 public EthCollected;
    uint256 private minToBuyInWeth;
    uint256 public totalUsers;
    bool public isInitialized;
    uint256 public tokensDebt;

    uint256 private constant RATIO_FACTOR = 1e18;
    uint256 private constant VALUES_FACTOR = 10000;

    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 tokensToCollect;
        uint256 tokens;
        uint256 eths;
    }

    mapping(address => address[4]) private referrals;

    event BuyTokens(
        address indexed account,
        uint256 amountEth,
        uint256 tAmount,
        address ref
    );

    /*
        @param: price - If give 1 token, 
        how much WETH will get? (decimals = 18)
    */
    constructor(address _owner, address _liquidityAddress) payable {
        transferOwnership(_owner);

        liquidityAddress = _liquidityAddress;
        Token = iLiquidity(liquidityAddress).Token();
        WETH = IWETH9(iLiquidity(liquidityAddress).WETH());

        ownerPercent = 1000; // 10%
        refsPercents = [uint256(400), uint256(300), uint256(200), uint256(100)]; // 4% 3% 2% 1%
        EthToCollect = 3000e18; // 3000
        price = 300_000_000_000_000; // 0.0003
        minToBuyInWeth = 1e16; // 0.01
    }

    receive() external payable {
        if (msg.sender != address(WETH)) {
            _buy(msg.sender, msg.value, address(0));
        }
    }

    function getRefsPercents() external view returns (uint256[4] memory) {
        return refsPercents;
    }

    function canClaimTokens() public view returns (bool) {
        // If 1 is returned, then the liquidity has not yet been initialized.
        return iLiquidity(liquidityAddress).getSeconds() != 1;
    }

    function getMinToBuyInWeth() external view returns (uint256) {
        return minToBuyInWeth;
    }

    function usersCanBuy() public view returns (uint256) {
        return EthToCollect.sub(EthCollected);
    }

    function getAmountTokens(uint256 amountEth) public view returns (uint256) {
        return amountEth.mul(RATIO_FACTOR).div(price);
    }

    function setAllRefs(address account, address newRef) private {
        if (newRef == account || newRef == address(this)) {
            newRef = owner();
        }
        if (referrals[account][0] == address(0)) {
            referrals[account][0] = newRef;
        }
        if (
            referrals[account][1] == address(0) &&
            referrals[newRef][1] != account
        ) {
            referrals[account][1] = referrals[newRef][0];
        }
        if (
            referrals[account][2] == address(0) &&
            referrals[newRef][2] != account
        ) {
            referrals[account][2] = referrals[newRef][1];
        }
        if (
            referrals[account][3] == address(0) &&
            referrals[newRef][3] != account
        ) {
            referrals[account][3] = referrals[newRef][2];
        }
    }

    function getOwnerAndRefsAmounts(uint256 amount)
        private
        view
        returns (
            uint256 _owner,
            uint256[4] memory _refs,
            uint256 _total
        )
    {
        _owner = amount.mul(ownerPercent).div(VALUES_FACTOR);
        _total += _owner;
        for (uint8 i; i < refsPercents.length; i++) {
            _refs[i] = amount.mul(refsPercents[i]).div(VALUES_FACTOR);
            _total += _refs[i];
        }
    }

    function claimTokens() external {
        if (!canClaimTokens()) revert IDOErrors.cantClaimTokens();
        uint256 tAmount = userInfo[msg.sender].tokensToCollect;
        if (tAmount > 0) {
            tokensDebt = tokensDebt.sub(userInfo[msg.sender].tokensToCollect);
            userInfo[msg.sender].tokensToCollect = 0;
            IERC20(Token).safeTransfer(msg.sender, tAmount);
        }
    }

    function buyTokens(address ref) external payable returns (uint256) {
        return _buy(msg.sender, msg.value, ref);
    }

    function buyTokens_WETH(uint256 amount, address ref)
        external
        returns (uint256)
    {
        IERC20(WETH).safeTransferFrom(msg.sender, address(this), amount);
        WETH.approve(address(WETH), amount);
        WETH.withdraw(amount);
        return _buy(msg.sender, amount, ref);
    }

    function _buy(
        address account,
        uint256 amountEth,
        address ref
    ) private returns (uint256) {
        uint256 amountTokens = getAmountTokens(amountEth);

        if (!isInitialized) revert IDOErrors.IdoNotOpen();
        if (amountEth > usersCanBuy()) revert IDOErrors.SendSmallerETH();
        if (amountEth < 0 || amountEth < minToBuyInWeth)
            revert IDOErrors.SendMoreETH();

        (, , uint256 _totalT) = getOwnerAndRefsAmounts(amountTokens);

        if (
            IERC20(Token).balanceOf(address(this)).sub(tokensDebt) <
            amountTokens.add(amountTokens.sub(_totalT))
        ) revert IDOErrors.DontHaveSellTokens();

        setAllRefs(account, ref);

        UserInfo storage user = userInfo[account];
        if (user.tokens == 0) {
            totalUsers++;
        }

        EthCollected = EthCollected.add(amountEth);
        user.tokens = user.tokens.add(amountTokens);
        user.eths = user.eths.add(amountEth);

        (
            uint256 _ownerE,
            uint256[4] memory _refsE,
            uint256 _totalE
        ) = getOwnerAndRefsAmounts(amountEth);

        safeTransferETH(liquidityAddress, amountEth.sub(_totalE));
        IERC20(Token).safeTransfer(liquidityAddress, amountTokens.sub(_totalT));
        safeTransferETH(owner(), _ownerE);

        if (canClaimTokens()) {
            IERC20(Token).safeTransfer(account, amountTokens);
        } else {
            tokensDebt = tokensDebt.add(amountTokens);
            user.tokensToCollect = user.tokensToCollect.add(amountTokens);
        }

        sendToRefs(account, _refsE);

        emit BuyTokens(account, amountEth, amountTokens, ref);
        return amountTokens;
    }

    function sendToRefs(address account, uint256[4] memory amounts) private {
        for (uint8 i; i < referrals[account].length; i++) {
            safeTransferETH(
                referrals[account][i] == address(0)
                    ? owner()
                    : referrals[account][i],
                amounts[i]
            );
        }
    }

    function safeTransferETH(address to, uint256 value) private {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if (!success) revert IDOErrors.EthTransferFailed();
    }

    function initialize() external onlyOwner {
        (, , uint256 _total) = getOwnerAndRefsAmounts(EthToCollect);
        IERC20(Token).safeTransferFrom(
            msg.sender,
            address(this),
            getAmountTokens(EthToCollect.add(EthToCollect.sub(_total)))
        );
        isInitialized = true;
    }

    function burnTokensAndCloseIDO() external onlyOwner {
        IERC20(Token).safeTransfer(
            0x000000000000000000000000000000000000dEaD,
            IERC20(Token).balanceOf(address(this)).sub(tokensDebt)
        );
    }

    function updateMinToBuyInWeth(uint256 newAmount) external onlyOwner {
        minToBuyInWeth = newAmount;
    }

    function onlyTestnetWithdrawAll() external onlyOwner {
        IERC20(Token).safeTransfer(
            owner(),
            IERC20(Token).balanceOf(address(this))
        );
    }
}