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

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IDexwinCore.sol";

contract DexWinOperationsV3 is ReentrancyGuard {
    /* Type Declarations */
    enum BetStatus {
        Active, //0
        Loss, //1
        Win, //2
        Suspended //3
    }

    struct BetSlip {
        bytes32 betkey;
        address bettor;
        address token;
        uint256 totalStake;
        uint256 totalPayout;
        address provider;
        bytes32 odds;
        bytes32 stake;
        bytes32 payout;
    }

    /* State Variables */

    /* Ops Contract Variables */

    address private s_opsOwner;
    IDexwinCore private immutable i_core;
    uint256 private s_randomWord;
    bool private betAllowed = true;

    mapping(bytes32 => bool) private s_placeBetKey;
    mapping(address => bool) private s_settleSigner;

    mapping(bytes32 => BetSlip) private s_keyToBetSlip;
    mapping(bytes32 => mapping(uint8 => bool)) private isSettled;

    event TransferOpsOwnership(address indexed oldOwner, address indexed newOwner);

    event BetPlaced(bytes32 indexed betkey, address indexed bettor, address indexed token, uint256 totalStake, uint256 totalPayout, bytes32 odds, bytes32 stake, bytes32 payout);

    event BetSettled(bytes32 indexed betkey, uint8 indexed betOrder, address indexed bettor, address token, BetStatus BetStatus, bytes32 odds, uint256 stake, uint256 payout);

    // mapping(uint256 => address) private betIdToProvider;

    constructor(address owner, address payable core) {
        s_opsOwner = owner;
        i_core = IDexwinCore(core);
    }

    modifier onlyOpsOwner() {
        if (msg.sender != s_opsOwner) {
            revert("Operations__OnlyOwnerMethod");
        }
        _;
    }

    modifier onlySettleSigner() {
        if (!s_settleSigner[msg.sender]) {
            revert("Operations__OnlySignerMethod");
        }
        _;
    }

    modifier isBetAllowed() {
        if (!betAllowed) {
            revert("Bets Disabled");
        }
        _;
    }

    /* State Changing Methods */
    function transferOpsOwnership(address _newOwner) public onlyOpsOwner {
        _transferOpsOwnership(_newOwner);
    }

    function _transferOpsOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Incorect address");
        address oldOwner = s_opsOwner;
        s_opsOwner = _newOwner;
        emit TransferOpsOwnership(oldOwner, _newOwner);
    }

    function setCoreOwnershipInOps(address newOwner) public onlyOpsOwner {
        i_core.setCoreOwnership(newOwner);
    }

    function disableCoreOwnershipInOps(address owner) public onlyOpsOwner {
        i_core.disableCoreOwnership(owner);
    }

    function setCoreTrustedForwarder(address trustedForwarder) public onlyOpsOwner {
        i_core.setTrustedForwarder(trustedForwarder);
    }

    function addTokensToCore(address token) public onlyOpsOwner {
        i_core.addTokens(token);
    }

    function disableCoreToken(address token) public onlyOpsOwner {
        i_core.disableToken(token);
    }

    function setBaseProviderInCore(address account, address token) public onlyOpsOwner {
        i_core.setBaseProvider(account, token);
    }

    function setSettleSigner(address account, bool status) public onlyOpsOwner {
        s_settleSigner[account] = status;
    }

    function modifyAllowBet(bool status) public onlyOpsOwner {
        betAllowed = status;
    }

    function placeBet(address token, uint256 totalStake, uint256 totalPayout, bytes32[4] calldata betDetails, uint256[2] calldata operator) public nonReentrant isBetAllowed {
        address provider = i_core.getBaseProvider(token);
        uint256 tips = i_core.getUserTips(msg.sender, token);
        uint256 bal = i_core.getUserBalance(msg.sender, token);
        uint256 tipsToSubtract;
        if (s_placeBetKey[betDetails[3]] == true) revert("Operations__BetKeyUsed");
        if (totalPayout > i_core.getTotalHL(token)) revert("Operations__InsufficientHL");
        if (totalPayout > i_core.getDepositerHLBalance(provider, token)) revert("Insuffcient House Liquidity");
        if (totalStake > tips + bal) revert("Operations__StakeMorethanbal");
        s_placeBetKey[betDetails[3]] = true;
        s_keyToBetSlip[betDetails[3]] = BetSlip(betDetails[3], msg.sender, token, totalStake, totalPayout, provider, betDetails[0], betDetails[1], betDetails[2]);
        emit BetPlaced(betDetails[3], msg.sender, token, totalStake, totalPayout, betDetails[0], betDetails[1], betDetails[2]);
        if (tips > 0) {
            tipsToSubtract = (tips >= totalStake) ? totalStake : tips;
            uint256 stakeLeft = totalStake - tipsToSubtract;
            i_core.handleUserTips(msg.sender, token, tipsToSubtract, 0);
            if (stakeLeft > 0) i_core.handleBalance(msg.sender, token, stakeLeft, 0);
        } else {
            i_core.handleBalance(msg.sender, token, totalStake, 0);
        }
        i_core.handleStakes(msg.sender, token, totalStake, 1);
        i_core.handleHL(provider, token, totalPayout, operator[0]);
        i_core.handlePayout(provider, token, totalPayout, operator[1]);
        if (!i_core.getBalancedStatus(token)) revert("Operations__ContractIsNotBalanced");
    }

    function handleLoss(bytes32 betkey, uint8 betOrder, uint256 stake, uint256 payout, uint256 hl, bytes32 odds, bool[3] calldata controls, uint256[2] calldata operators) public onlySettleSigner {
        BetSlip storage betSlip = s_keyToBetSlip[betkey];
        if (betkey != betSlip.betkey || betkey == 0) revert("Operations__InvalidBetId");
        if (isSettled[betkey][betOrder] == true) revert("Already settled");
        if (stake > i_core.getUserStaked(betSlip.bettor, betSlip.token)) revert("Operations__InsufficentStakes");
        if (stake > i_core.getTotalStakes(betSlip.token)) revert("Operations__InsufficentStakes");
        if (payout > i_core.getProviderPayout(betSlip.provider, betSlip.token)) revert("Operations__InsufficentPayouts");
        if (payout > i_core.getTotalPayout(betSlip.token)) revert("Operations__InsufficentPayouts");
        isSettled[betkey][betOrder] = true;
        if (controls[0]) i_core.handleStakes(betSlip.bettor, betSlip.token, stake, 0);
        if (controls[1]) i_core.handleHL(betSlip.provider, betSlip.token, hl, operators[0]);
        if (controls[2]) i_core.handlePayout(betSlip.provider, betSlip.token, payout, operators[1]);
        if (!i_core.getBalancedStatus(betSlip.token)) revert("Operations__ContractIsNotBalanced");
        emit BetSettled(betSlip.betkey, betOrder, betSlip.bettor, betSlip.token, BetStatus.Loss, odds, stake, payout);
    }

    function handleWin(bytes32 betkey, uint8 betOrder, uint256 stake, uint256 payout, bytes32 odds) public onlySettleSigner {
        BetSlip storage betSlip = s_keyToBetSlip[betkey];
        if (betkey != betSlip.betkey || betkey == 0) revert("Operations__InvalidBetId");
        if (isSettled[betkey][betOrder] == true) revert("Already settled");
        if (stake > i_core.getUserStaked(betSlip.bettor, betSlip.token)) revert("Operations__InsufficentStakes");
        if (stake > i_core.getTotalStakes(betSlip.token)) revert("Operations__InsufficentStakes");
        if (payout > i_core.getProviderPayout(betSlip.provider, betSlip.token)) revert("Operations__InsufficentPayouts");
        if (payout > i_core.getTotalPayout(betSlip.token)) revert("Operations__InsufficentPayouts");
        isSettled[betkey][betOrder] = true;
        i_core.handleBalance(betSlip.bettor, betSlip.token, stake + payout, 1);
        i_core.handleStakes(betSlip.bettor, betSlip.token, stake, 0);
        i_core.handlePayout(betSlip.provider, betSlip.token, payout, 0);
        if (!i_core.getBalancedStatus(betSlip.token)) revert("Operations__ContractIsNotBalanced");
        emit BetSettled(betSlip.betkey, betOrder, betSlip.bettor, betSlip.token, BetStatus.Win, odds, stake, payout);
    }

    function handleSuspension(
        bytes32 betkey,
        uint8 betOrder,
        uint256 stake,
        uint256 hl,
        uint256 payout,
        bytes32 odds,
        bool[2] calldata controls,
        uint256[2] calldata operators
    ) public onlySettleSigner {
        BetSlip storage betSlip = s_keyToBetSlip[betkey];
        if (betkey != betSlip.betkey || betkey == 0) revert("Operations__InvalidBetId");
        if (isSettled[betkey][betOrder] == true) revert("Already settled");
        if (stake > i_core.getUserStaked(betSlip.bettor, betSlip.token)) revert("Operations__InsufficentStakes");
        if (stake > i_core.getTotalStakes(betSlip.token)) revert("Operations__InsufficentStakes");
        isSettled[betkey][betOrder] = true;
        i_core.handleBalance(betSlip.bettor, betSlip.token, stake, 1);
        i_core.handleStakes(betSlip.bettor, betSlip.token, stake, 0);
        if (controls[0]) {
            if (payout > i_core.getProviderPayout(betSlip.provider, betSlip.token)) revert("Operations__InsufficentPayouts");
            if (payout > i_core.getTotalPayout(betSlip.token)) revert("Operations__InsufficentPayouts");
            i_core.handleHL(betSlip.provider, betSlip.token, hl, operators[0]); //1
        }
        if (controls[1]) {
            if (payout > i_core.getProviderPayout(betSlip.provider, betSlip.token)) revert("Operations__InsufficentPayouts");
            if (payout > i_core.getTotalPayout(betSlip.token)) revert("Operations__InsufficentPayouts");
            i_core.handlePayout(betSlip.provider, betSlip.token, payout, operators[1]); //0
        }
        if (!i_core.getBalancedStatus(betSlip.token)) {
            revert("Operations__ContractIsNotBalanced");
        }
        emit BetSettled(betSlip.betkey, betOrder, betSlip.bettor, betSlip.token, BetStatus.Suspended, odds, stake, payout);
    }

    /*Gettor Functions */
    function getOpsOwner() public view returns (address) {
        return s_opsOwner;
    }

    function getSettleSigner(address setlleSigner) public view returns (bool) {
        return (s_settleSigner[setlleSigner]);
    }

    function getBet(bytes32 betkey) public view returns (BetSlip memory) {
        return s_keyToBetSlip[betkey];
    }

    function getIsSettled(bytes32 betkey, uint8 betOrder) public view returns (bool) {
        return isSettled[betkey][betOrder];
    }

    function getIsBetAllowed() public view returns (bool) {
        return betAllowed;
    }
}

///

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IDexwinCore {
    function getBaseProvider(address token) external view returns (address);

    function getRandomProvider(address token, uint256 randomWord) external returns (address);

    function getUserBalance(address account, address token) external view returns (uint256);

    function getTotalFunds(address token) external view returns (uint256);

    function getUserTips(address account, address token) external view returns (uint256);

    function getTotalUserTips(address token) external view returns (uint256);

    function getUserStaked(address account, address token) external view returns (uint256);

    function getTotalStakes(address token) external view returns (uint256);

    function getDepositerHLBalance(address depositer, address token) external view returns (uint256);

    function getTotalHL(address token) external view returns (uint256);

    function getProviderPayout(address account, address token) external view returns (uint256);

    function getTotalPayout(address token) external view returns (uint256);

    function getBalancedStatus(address token) external view returns (bool);

    function setCoreOwnership(address newOwner) external;

    function disableCoreOwnership(address owwner) external;

    function setTrustedForwarder(address trustedForwarder) external;

    function addTokens(address token) external;

    function disableToken(address token) external;

    function setBaseProvider(address account, address token) external;

    function handleBalance(address bettor, address token, uint256 amount, uint256 operator) external;

    function handleUserTips(address bettor, address token, uint256 amount, uint256 operator) external;

    function handleStakes(address bettor, address token, uint256 amount, uint256 operator) external;

    function handleHL(address bettor, address token, uint256 amount, uint256 operator) external;

    function handlePayout(address bettor, address token, uint256 amount, uint256 operator) external;
}