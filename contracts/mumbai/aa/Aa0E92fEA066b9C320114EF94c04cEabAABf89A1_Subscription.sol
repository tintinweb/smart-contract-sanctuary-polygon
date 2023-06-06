// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "IERC20.sol";
import "ReentrancyGuard.sol";

contract Subscription is ReentrancyGuard {
    struct Plan {
        uint256 id;
        uint256 price;
        IERC20 token;
    }

    address payable public owner;
    IERC20 public token;

    mapping(uint256 => Plan) public plans;
    mapping(uint256 => bool) public isPlanExist;
    uint256[] public planIds;

    event PaymentMade(address indexed user, uint256 planId, uint256 amount);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can set the plan");
        _;
    }

    function setPlan(uint256 _planId, uint256 _price, IERC20 _token) public onlyOwner {
        if (!isPlanExist[_planId]) {
            planIds.push(_planId);
        }
        plans[_planId] = Plan(_planId, _price, _token);
        isPlanExist[_planId] = true;
    }

    function getPlans() public view returns (uint256[] memory, uint256[] memory, address[] memory) {
        uint256[] memory ids = new uint256[](planIds.length);
        uint256[] memory prices = new uint256[](planIds.length);
        address[] memory tokens = new address[](planIds.length);

        for (uint i = 0; i < planIds.length; i++) {
            ids[i] = plans[planIds[i]].id;
            prices[i] = plans[planIds[i]].price;
            tokens[i] = address(plans[planIds[i]].token);
        }

        return (ids, prices, tokens);
    }

    function pay(uint256 _planId) public nonReentrant {
        Plan storage plan = plans[_planId];
        require(isPlanExist[_planId], "Plan does not exist");
        uint256 allowance = plan.token.allowance(msg.sender, address(this));
        uint256 balance = plan.token.balanceOf(msg.sender);
        require(balance >= plan.price, "Insufficient token balance");
        require(allowance >= plan.price, "Not enough allowed tokens");

        plan.token.transferFrom(msg.sender, address(this), plan.price);
        emit PaymentMade(msg.sender, _planId, plan.price);
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    function withdrawToken(address tokenAddress) public onlyOwner {
        IERC20 withdraw_token = IERC20(tokenAddress);
        uint256 balance = withdraw_token.balanceOf(address(this));
        require(balance > 0, "Contract has no tokens");
        withdraw_token.transfer(owner, balance);
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Contract has no money");
        owner.transfer(address(this).balance);
    }

    function updatePlan(uint256 _planId, uint256 _newPrice, IERC20 _newToken) public onlyOwner {
        require(isPlanExist[_planId], "Plan does not exist");
        Plan storage plan = plans[_planId];
        plan.price = _newPrice;
        plan.token = _newToken;
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}