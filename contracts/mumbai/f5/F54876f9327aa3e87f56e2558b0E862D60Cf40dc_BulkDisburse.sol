// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint256 balance);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract BulkDisburse is ReentrancyGuard {

    address public admin;
    mapping(address => bool) public owners;

    modifier onlyOwner {
        require(owners[msg.sender] == true, "BA: Unauthorised access");
        _;
    }

    event Disburse(address indexed token, address indexed from, address indexed to, uint256 value);

    constructor(address _owner) {
        admin = _owner;
        owners[_owner] = true;
    }

    function updateOwnerStatus(address _owner, bool _status) external {
        require(msg.sender == admin, "BA: Unauthorised access");
        owners[_owner] = _status;
    }

    function _bulkDisburse(IERC20 token, address[] calldata to, uint256[] calldata value) private {
        require(to.length == value.length, "BA: to & value length mismatch");
        // Removed the code to check the allowance to save on the gas
        for(uint256 i; i < to.length;){
            address toAddresses = to[i];
            uint256 totalValue = value[i];
            require(token.transfer(toAddresses, totalValue), "BA: Disburse Failed");
            emit Disburse(address(token), msg.sender, toAddresses, totalValue);
            unchecked {
                ++i;
            }
        }
    }

    function depositForBulkDisburse(IERC20 token, uint256 totalValue) external onlyOwner nonReentrant {
        require(token.transferFrom(msg.sender, address(this), totalValue), "BA: Transfer Failed");
    }

    function bulkDisburse(IERC20 token, address[] calldata to, uint256[] calldata value) external onlyOwner nonReentrant {
        _bulkDisburse(token, to, value);
    }

    function getTokenBalance(IERC20 token) external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function withdrawNativeToken() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(admin).call{ value: balance }("");
        require(success, "BA: Withdraw native token failed");
    }

    function withdrawERC20(IERC20 token) external onlyOwner nonReentrant {
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(admin, balance));
    }
}