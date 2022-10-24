// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./interfaces/IERC20MintableBurnable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ConvivalLocker is Context, ReentrancyGuard {
    uint64 public constant MONTH = 15 minutes; //PROD: 30 days;
    uint256[4] public DURATION = [MONTH * 3, MONTH * 6, MONTH * 9, MONTH * 12];

    address public immutable CVL;
    address public immutable lpCVL;
    IERC20MintableBurnable public immutable gCVL;

    mapping(address => Lock[]) private lockups;

    struct Lock {
        address tokenIn;
        uint256 unlockTimestamp;
        uint256 amountIn;
        uint256 amountOut;
    }

    event LockCreated(
        uint256 indexed id,
        uint256 unlockTimestamp,
        uint256 amountIn,
        uint256 amountOut,
        address account
    );
    event LockRedeemed(uint256 indexed id, address account);

    constructor(
        address _cvl,
        address _lpcvl,
        address _gcvl
    ) {
        require(
            _cvl != address(0) && _gcvl != address(0) && _lpcvl != address(0),
            "ConvivalLocker: zero addresses"
        );

        CVL = _cvl;
        lpCVL = _lpcvl;
        gCVL = IERC20MintableBurnable(_gcvl);
    }

    function getAllLockups(address user) public view returns (Lock[] memory) {
        return lockups[user];
    }

    function lock(
        address token,
        uint256 amount,
        uint8 duration
    ) external nonReentrant {
        require(
            token == address(CVL) || token == address(lpCVL),
            "ConvivalLocker: wrong input token"
        );
        require(amount > 0, "ConvivalLocker: zero amount");
        require(duration < 4, "ConvivalLocker: wrong duration specified");

        uint256 unlockTimestamp = block.timestamp + DURATION[duration];
        uint256 amountOut;
        if (token == CVL) {
            amountOut = (amount * (duration + 1)) / 4;
            IERC20(CVL).transferFrom(_msgSender(), address(this), amount);
        } else {
            amountOut = (amount * (duration + 1)) / 2;
            IERC20(lpCVL).transferFrom(_msgSender(), address(this), amount);
        }
        lockups[_msgSender()].push(
            Lock(token, unlockTimestamp, amount, amountOut)
        );
        gCVL.mint(_msgSender(), amountOut);

        emit LockCreated(
            lockups[_msgSender()].length - 1,
            unlockTimestamp,
            amount,
            amountOut,
            _msgSender()
        );
    }

    function unlock(uint256 index) external nonReentrant {
        require(
            lockups[_msgSender()].length > index,
            "ConvivalLocker: wrong index"
        );
        Lock memory lockup = lockups[_msgSender()][index];
        require(
            block.timestamp > lockup.unlockTimestamp,
            "ConvivalLocker: too early"
        );

        //remove lockup
        if (index == lockups[_msgSender()].length - 1) {
            lockups[_msgSender()].pop();
        } else {
            Lock memory lastLockup = lockups[_msgSender()][
                lockups[_msgSender()].length - 1
            ];
            lockups[_msgSender()][index] = lastLockup;
            lockups[_msgSender()].pop();
        }

        gCVL.burnFrom(_msgSender(), lockup.amountOut);
        IERC20(lockup.tokenIn).transfer(_msgSender(), lockup.amountIn);

        emit LockRedeemed(index, _msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20MintableBurnable is IERC20 {

    function mint(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
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