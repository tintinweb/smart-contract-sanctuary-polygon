// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@opengsn/contracts/src/ERC2771Recipient.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function name() external returns (string memory);
}

contract DexwinCore is ERC2771Recipient, ReentrancyGuard {
    /* State Variables */

    /* Core Variables */
    mapping(address => bool) private s_coreOwner;
    //address private s_coreOwner;

    mapping(address => bool) private s_allowedTokens;
    mapping(address => address) private s_baseProvider;
    mapping(address => address) private s_randomProvider;

    //Individual
    // user => token => amount
    mapping(address => mapping(address => uint256)) private s_userBalance;
    mapping(address => mapping(address => uint256)) private s_userTips;
    mapping(address => mapping(address => uint256)) private s_userStaked;
    mapping(address => mapping(address => uint256)) private s_houseLiquidity;
    mapping(address => mapping(address => uint256)) private s_payout;

    // Totals
    // token => total
    mapping(address => uint256) private s_totalUserFunds;
    mapping(address => uint256) private s_totalUserTips;
    mapping(address => uint256) private s_totalStaked;
    mapping(address => uint256) private s_totalHL;
    mapping(address => uint256) private s_totalPayout;

    //user => token => id
    mapping(address => mapping(address => uint256)) private s_providerToId;
    mapping(address => address[]) private s_tokenToLiquidityProvider;
    mapping(address => uint256) public tokenToLiquidityProviderCount;

    /* Events */
    event SetCoreOwnership(address indexed owner, bool indexed status);
    event BaseProvider(address indexed token, address indexed oldBaseDepositor, address indexed newBaseDepositor);
    event Deposit(address indexed token, address indexed sender, uint256 indexed amount);
    event Tips(address indexed tipper, address indexed receiver, address indexed token, uint256 amount);
    event Withdrawal(address indexed token, address indexed withdrawee, uint256 indexed amount);
    event HouseLiquidityDeposit(address indexed token, address indexed depositer, uint256 indexed amount);
    event Liquidated(address indexed token, address indexed liquidator, uint256 indexed amount);

    constructor(address owner) {
        s_coreOwner[owner] = true;
        emit SetCoreOwnership(owner, true);
    }

    modifier onlyCoreOwner() {
        if (!s_coreOwner[_msgSender()]) {
            revert("Core__OnlyOwnerMethod");
        }
        _;
    }

    modifier isTokenValid(address token) {
        if (!s_allowedTokens[token]) {
            revert("Core__TokenNotUsed");
        }
        _;
    }

    modifier amountIsValid(uint256 amount) {
        if (!(amount > 0)) {
            revert("Core__AmountIsInvalid");
        }
        _;
    }

    /*State changing methods*/

    /*setting trusted forwarder for meta tx eip 2771*/
    function setTrustedForwarder(address _trustedForwarder) external onlyCoreOwner {
        _setTrustedForwarder(_trustedForwarder);
    }

    function setCoreOwnership(address _newOwner) external onlyCoreOwner {
        _setCoreOwnership(_newOwner);
    }

    function _setCoreOwnership(address _newOwner) internal {
        if (_newOwner == address(0)) {
            revert("Core_InvalidAddress");
        }
        s_coreOwner[_newOwner] = true;
        emit SetCoreOwnership(_newOwner, true);
    }

    function disableCoreOwnership(address _owner) external onlyCoreOwner {
        _disableCoreOwnership(_owner);
    }

    function _disableCoreOwnership(address _owner) internal {
        if (_owner == address(0)) revert("Core_InvalidAddress");
        if (_msgSender() != _owner) revert("Only Owner");
        s_coreOwner[_owner] = false;
        emit SetCoreOwnership(_owner, false);
    }

    function addTokens(address _token) external onlyCoreOwner {
        s_allowedTokens[_token] = true;
    }

    function disableToken(address _token) external onlyCoreOwner isTokenValid(_token) {
        s_allowedTokens[_token] = false;
    }

    function setBaseProvider(address baseProvider, address token) external onlyCoreOwner isTokenValid(token) {
        if (baseProvider == address(0)) {
            revert("Core_InvalidAddress");
        }
        address oldBaseProvider = s_baseProvider[token];
        s_baseProvider[token] = baseProvider;
        emit BaseProvider(token, oldBaseProvider, baseProvider);
    }

    function getRandomProvider(address token, uint256 randomWord) external onlyCoreOwner isTokenValid(token) returns (address) {
        uint256 randomProviderIndex = randomWord % getLiquidtyProvidersCount(token);
        s_randomProvider[token] = getLiquidtyProvidersAddress(token, randomProviderIndex);
        return s_randomProvider[token];
    }

    receive() external payable onlyCoreOwner {}

    fallback() external payable onlyCoreOwner {}

    function deposit(address _token, uint256 amount) public isTokenValid(_token) amountIsValid(amount) {
        IERC20 token = IERC20(_token);
        s_userBalance[_msgSender()][_token] += amount;
        s_totalUserFunds[_token] += amount;
        bool success = token.transferFrom(_msgSender(), address(this), amount);
        if (!success) revert("Core__TransferFailed");
        emit Deposit(_token, _msgSender(), amount);
    }

    function depositTips(address receiver, address _token, uint256 amount) public isTokenValid(_token) amountIsValid(amount) {
        IERC20 token = IERC20(_token);
        s_userTips[receiver][_token] += amount;
        s_totalUserTips[_token] += amount;
        bool success = token.transferFrom(_msgSender(), address(this), amount);
        if (!success) revert("Core__UTipsFailed");
        emit Tips(_msgSender(), receiver, _token, amount);
    }

    function sendTips(address receiver, address _token, uint256 amount) public isTokenValid(_token) amountIsValid(amount) {
        if (amount > s_userBalance[_msgSender()][_token]) revert("Tips Greater than bal");
        s_userTips[receiver][_token] += amount;
        s_totalUserTips[_token] += amount;
        s_userBalance[_msgSender()][_token] -= amount;
        s_totalUserFunds[_token] -= amount;
        emit Tips(_msgSender(), receiver, _token, amount);
    }

    function depositHL(address _token, uint256 amount) public isTokenValid(_token) amountIsValid(amount) {
        IERC20 token = IERC20(_token);
        if (s_houseLiquidity[_msgSender()][_token] == 0) {
            s_tokenToLiquidityProvider[_token].push(_msgSender());
            tokenToLiquidityProviderCount[_token]++;
            s_providerToId[_msgSender()][_token] = tokenToLiquidityProviderCount[_token];
        }
        s_houseLiquidity[_msgSender()][_token] += amount;
        s_totalHL[_token] += amount;
        bool success = token.transferFrom(_msgSender(), address(this), amount);
        if (!success) revert("Core__TransferFailed");
        emit HouseLiquidityDeposit(_token, _msgSender(), amount);
    }

    function withdraw(address _token, uint256 amount) public nonReentrant isTokenValid(_token) amountIsValid(amount) {
        if (s_userBalance[_msgSender()][_token] >= amount) {
            IERC20 token = IERC20(_token);
            s_userBalance[_msgSender()][_token] -= amount;
            s_totalUserFunds[_token] -= amount;
            bool success = token.transfer(_msgSender(), amount);
            if (!success) revert("Core__TransferFailed");
            emit Withdrawal(_token, _msgSender(), amount);
        } else {
            revert("Core__WithdrawAmtGreaterThanBalance");
        }
    }

    function withdrawHL(address _token, uint256 amount) public nonReentrant isTokenValid(_token) amountIsValid(amount) {
        if (s_houseLiquidity[_msgSender()][_token] >= amount) {
            IERC20 token = IERC20(_token);

            if (s_houseLiquidity[_msgSender()][_token] == amount) {
                uint256 index = s_providerToId[_msgSender()][_token] - 1;
                address provider = s_tokenToLiquidityProvider[_token][index];
                if (_msgSender() == provider) {
                    delete s_tokenToLiquidityProvider[_token][index];
                }
            }
            s_houseLiquidity[_msgSender()][_token] -= amount;
            s_totalHL[_token] -= amount;
            bool success = token.transfer(_msgSender(), amount);
            if (!success) revert("Core__TransferFailed");
            emit Liquidated(_token, _msgSender(), amount);
        } else {
            revert("Core__WithdrawAmtGreaterThanBalance");
        }
    }

    /* Methods called in Ops contract */

    function handleBalance(address account, address token, uint256 amount, uint256 operator) external onlyCoreOwner isTokenValid(token) {
        if (operator == 1) {
            s_userBalance[account][token] += amount;
            s_totalUserFunds[token] += amount;
        } else if (operator == 0) {
            s_userBalance[account][token] -= amount;
            s_totalUserFunds[token] -= amount;
        } else {
            revert("Core_InvalidOperator");
        }
    }

    function handleUserTips(address account, address token, uint256 amount, uint256 operator) external onlyCoreOwner isTokenValid(token) {
        if (operator == 1) {
            s_userTips[account][token] += amount;
            s_totalUserTips[token] += amount;
        } else if (operator == 0) {
            s_userTips[account][token] -= amount;
            s_totalUserTips[token] -= amount;
        } else {
            revert("Core_InvalidOperator");
        }
    }

    function handleStakes(address account, address token, uint256 amount, uint256 operator) external onlyCoreOwner isTokenValid(token) {
        if (operator == 1) {
            s_userStaked[account][token] += amount;
            s_totalStaked[token] += amount;
        } else if (operator == 0) {
            s_userStaked[account][token] -= amount;
            s_totalStaked[token] -= amount;
        } else {
            revert("Core_InvalidOperator");
        }
    }

    function handleHL(address depositer, address token, uint256 amount, uint256 operator) external onlyCoreOwner isTokenValid(token) {
        if (operator == 1) {
            s_houseLiquidity[depositer][token] += amount;
            s_totalHL[token] += amount;
        } else if (operator == 0) {
            s_houseLiquidity[depositer][token] -= amount;
            s_totalHL[token] -= amount;
        } else {
            revert("Core_InvalidOperator");
        }
    }

    function handlePayout(address account, address token, uint256 amount, uint256 operator) external onlyCoreOwner isTokenValid(token) {
        if (operator == 1) {
            s_payout[account][token] += amount;
            s_totalPayout[token] += amount;
        } else if (operator == 0) {
            s_payout[account][token] -= amount;
            s_totalPayout[token] -= amount;
        } else {
            revert("Core_InvalidOperator");
        }
    }

    // Gettor Functions

    function getCoreOwner(address owner) public view returns (bool) {
        return s_coreOwner[owner];
    }

    function getAllowedTokens(address token) public view returns (bool) {
        return s_allowedTokens[token];
    }

    function getBaseProvider(address token) public view isTokenValid(token) returns (address) {
        return s_baseProvider[token];
    }

    function getLiquidtyProvidersCount(address token) public view isTokenValid(token) returns (uint256) {
        return tokenToLiquidityProviderCount[token];
    }

    function getLiquidtyProvidersId(address account, address token) public view isTokenValid(token) returns (uint256) {
        return s_providerToId[account][token];
    }

    function getLiquidtyProvidersAddress(address token, uint256 index) public view isTokenValid(token) returns (address) {
        return s_tokenToLiquidityProvider[token][index];
    }

    function getUserBalance(address account, address token) public view isTokenValid(token) returns (uint256) {
        return s_userBalance[account][token];
    }

    function getTotalFunds(address token) public view isTokenValid(token) returns (uint256) {
        return s_totalUserFunds[token];
    }

    function getUserTips(address account, address token) public view isTokenValid(token) returns (uint256) {
        return s_userTips[account][token];
    }

    function getTotalUserTips(address token) public view isTokenValid(token) returns (uint256) {
        return s_totalUserTips[token];
    }

    function getUserStaked(address account, address token) public view isTokenValid(token) returns (uint256) {
        return s_userStaked[account][token];
    }

    function getTotalStakes(address token) public view isTokenValid(token) returns (uint256) {
        return s_totalStaked[token];
    }

    function getDepositerHLBalance(address depositer, address token) public view isTokenValid(token) returns (uint256) {
        return s_houseLiquidity[depositer][token];
    }

    function getTotalHL(address token) public view isTokenValid(token) returns (uint256) {
        return s_totalHL[token];
    }

    function getProviderPayout(address account, address token) public view returns (uint256) {
        return s_payout[account][token];
    }

    function getTotalPayout(address token) public view returns (uint256) {
        return s_totalPayout[token];
    }

    function getBalancedStatus(address token) public view isTokenValid(token) returns (bool) {
        uint256 contractBal = IERC20(token).balanceOf(address(this));
        return contractBal == s_totalUserFunds[token] + s_totalUserTips[token] + s_totalStaked[token] + s_totalHL[token] + s_totalPayout[token];
    }
}
////Mainnet