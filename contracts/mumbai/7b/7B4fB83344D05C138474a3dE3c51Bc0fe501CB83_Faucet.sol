// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Authorizable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
error MaxClaimed();
error NotYet();
error InsufficentFundsInFaucets();

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Faucet is Authorizable, ReentrancyGuard {
    struct User {
        address account;
        bool flag;
        string role;
        uint256 tokensAssigned;
        uint256 claimLimit;
        uint256 claimFrequency;
        uint256 claimedTokens;
        uint256 lastClaimedAt;
    }

    event Withdrawal(address indexed to, uint256 indexed amount);
    event Deposit(address indexed from, uint256 indexed amount);

    event UserAssigned(
        address indexed account,
        bool flag,
        string role,
        uint256 indexed tokensAssigned,
        uint256 claimLimit,
        uint256 claimFrequency,
        uint256 claimedTokens,
        uint256 lastClaimedAt
    );

    event UserClaimed(
        address indexed account,
        bool flag,
        string role,
        uint256 indexed tokensAssigned,
        uint256 claimLimit,
        uint256 claimFrequency,
        uint256 claimedTokens,
        uint256 lastClaimedAt
    );

    IERC20 private immutable i_dexwinToken;
    uint8 private s_decimals;
    string[] private roles = ["agent", "adopter", "investor"];
    mapping(address => User) private addressToUser;

    constructor(address tokenAddress, address _owner) payable Authorizable(_owner) {
        i_dexwinToken = IERC20(tokenAddress);
        s_decimals = i_dexwinToken.decimals();
    }

    function assignUser(
        address account,
        uint256 roleValue,
        uint256 tokensAssigned,
        uint256 claimLimit,
        uint256 claimFrequency
    ) public onlyAuthorized {
        require(!addressToUser[account].flag, "User Already exists");
        string memory role = roles[roleValue];
        addressToUser[account] = User(
            account,
            true,
            role,
            tokensAssigned,
            claimLimit,
            claimFrequency,
            0,
            block.timestamp
        );
        emit UserAssigned(
            account,
            true,
            role,
            tokensAssigned,
            claimLimit,
            claimFrequency,
            0,
            block.timestamp
        );
    }

    function claimReward() public nonReentrant {
        require(addressToUser[msg.sender].flag, "Cannot claim since you have no role");
        User storage userAccount = addressToUser[msg.sender];

        uint256 tokensAssigned = userAccount.tokensAssigned;
        uint256 claimedTokens = userAccount.claimedTokens;
        uint256 lastClaimedAt = userAccount.lastClaimedAt;
        uint256 claimFrequency = userAccount.claimFrequency;
        uint256 claimLimit = userAccount.claimLimit;
        if (claimedTokens == 0) {
            firstClaim(userAccount);
        } else if (claimedTokens != tokensAssigned) {
            uint256 pendingClaims = (block.timestamp - lastClaimedAt) / claimFrequency;
            if (pendingClaims > 0) {
                uint256 claimAble = pendingClaims * claimLimit;
                if (claimAble <= (tokensAssigned - claimedTokens)) {
                    normalClaims(userAccount, claimAble);
                } else {
                    allClaims(userAccount);
                }
            } else {
                revert NotYet();
            }
        } else {
            revert MaxClaimed();
        }
    }

    receive() external payable onlyOwner {
        emit Deposit(msg.sender, msg.value);
    }

    function firstClaim(User memory user) internal {
        if (i_dexwinToken.balanceOf(address(this)) < (user.claimLimit * (10**s_decimals))) {
            revert InsufficentFundsInFaucets();
        }
        addressToUser[user.account].lastClaimedAt = block.timestamp;
        addressToUser[user.account].claimedTokens = user.claimLimit;

        i_dexwinToken.transfer(user.account, (user.claimLimit * (10**s_decimals)));
        emit UserClaimed(
            user.account,
            true,
            user.role,
            user.tokensAssigned,
            user.claimLimit,
            user.claimFrequency,
            user.claimLimit,
            addressToUser[user.account].lastClaimedAt
        );
    }

    function normalClaims(User memory user, uint256 claimAble) internal {
        if (i_dexwinToken.balanceOf(address(this)) < (claimAble * (10**s_decimals))) {
            revert InsufficentFundsInFaucets();
        }
        addressToUser[user.account].lastClaimedAt = block.timestamp;
        addressToUser[user.account].claimedTokens += claimAble;

        i_dexwinToken.transfer(user.account, (claimAble * (10**s_decimals)));
        emit UserClaimed(
            user.account,
            true,
            user.role,
            user.tokensAssigned,
            user.claimLimit,
            user.claimFrequency,
            (user.claimedTokens + claimAble),
            addressToUser[user.account].lastClaimedAt
        );
    }

    function allClaims(User memory user) internal {
        if (
            i_dexwinToken.balanceOf(address(this)) <
            ((user.tokensAssigned - user.claimedTokens) * (10**s_decimals))
        ) {
            revert InsufficentFundsInFaucets();
        }
        addressToUser[user.account].lastClaimedAt = block.timestamp;
        addressToUser[user.account].claimedTokens += (user.tokensAssigned - user.claimedTokens);

        i_dexwinToken.transfer(
            user.account,
            ((user.tokensAssigned - user.claimedTokens) * (10**s_decimals))
        );
        emit UserClaimed(
            user.account,
            true,
            user.role,
            user.tokensAssigned,
            user.claimLimit,
            user.claimFrequency,
            user.claimedTokens + (user.tokensAssigned - user.claimedTokens),
            addressToUser[user.account].lastClaimedAt
        );
    }

    function withdraw() public onlyOwner {
        emit Withdrawal(msg.sender, i_dexwinToken.balanceOf(address(this)));
        i_dexwinToken.transfer(msg.sender, i_dexwinToken.balanceOf(address(this)));
    }

    function transferDxt(address to, uint256 amount) public onlyAuthorized {
        i_dexwinToken.transfer(to, amount * (10**s_decimals));
    }

    function getUser(address account) public view returns (User memory) {
        return addressToUser[account];
    }

    function getRoles() public view returns (string[] memory) {
        return roles;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Ownable.sol";

contract Authorizable is Ownable {
    mapping(address => bool) authorized;

    event Authorized(address indexed authorizedAddress);
    event RemoveAuthorized(address indexed removeAddress);

    constructor(address _address) Ownable(_address) {}

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || (msg.sender == getOwner()), "not authorized not owner");
        _;
    }

    function addAuthorized(address _toAdd) public onlyOwner {
        require(_toAdd != address(0), "Inccorect address");
        authorized[_toAdd] = true;
        emit Authorized(_toAdd);
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != address(0), "Inccorect address");
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
        emit RemoveAuthorized(_toRemove);
    }

    function getAuthorized(address _address) public view returns (bool) {
        return authorized[_address];
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

pragma solidity ^0.8.17;

contract Ownable {
    /*State variables */
    address private s_owner;

    /*events */
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    constructor(address _owner) {
        s_owner = _owner;
        emit TransferOwnership(address(0), s_owner);
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner, "Only Owner can call this function");
        _;
    }

    function getOwner() public view returns (address) {
        return s_owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Inccorect address");
        s_owner = newOwner;
        emit TransferOwnership(s_owner, newOwner);
    }
}