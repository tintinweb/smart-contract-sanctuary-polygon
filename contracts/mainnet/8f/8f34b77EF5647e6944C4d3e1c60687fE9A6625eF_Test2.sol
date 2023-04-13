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

pragma solidity ^0.8.17;

interface ITest1 {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@opengsn/contracts/src/ERC2771Recipient.sol";

import "./ITest1.sol";

contract Test2 is ERC2771Recipient {
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

    ITest1 private immutable i_core;
    uint256 private s_randomWord;

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
        i_core = ITest1(core);
    }

    modifier onlyOpsOwner() {
        if (_msgSender() != s_opsOwner) {
            revert("Operations__OnlyOwnerMethod");
        }
        _;
    }

    modifier onlySettleSigner() {
        if (!s_settleSigner[_msgSender()]) {
            revert("Operations__OnlySignerMethod");
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

    function setOpsTrustedForwarder(address _trustedForwarder) external onlyOpsOwner {
        _setTrustedForwarder(_trustedForwarder);
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

    function placeBet(address token, uint256 totalStake, uint256 totalPayout, bytes32[4] calldata betDetails, bool[4] calldata controls, uint256[2] calldata operator, bool callOracle) public {
        if (s_placeBetKey[betDetails[3]] == true) revert("Operations__BetKeyUsed");
        if (totalPayout > i_core.getTotalHL(token)) revert("Operations__InsufficientHL");
        address provider = i_core.getBaseProvider(token);
        require(totalPayout <= i_core.getDepositerHLBalance(provider, token), "Insuffcient House Liquidity");
        s_placeBetKey[betDetails[3]] = true;
        if (controls[0]) {
            if (totalStake <= i_core.getUserTips(_msgSender(), token)) {
                i_core.handleUserTips(_msgSender(), token, totalStake, 0);
            } else {
                if (totalStake > i_core.getUserBalance(_msgSender(), token)) revert("Operations__StakeMorethanbal");
                i_core.handleBalance(_msgSender(), token, totalStake, 0);
            }
        }
        if (controls[1]) i_core.handleStakes(_msgSender(), token, totalStake, 1);
        if (controls[2]) i_core.handleHL(provider, token, totalPayout, operator[0]);
        if (controls[3]) i_core.handlePayout(provider, token, totalPayout, operator[1]);
        if (!i_core.getBalancedStatus(token)) revert("Operations__ContractIsNotBalanced");
        s_keyToBetSlip[betDetails[3]] = BetSlip(betDetails[3], _msgSender(), token, totalStake, totalPayout, provider, betDetails[0], betDetails[1], betDetails[2]);
        emit BetPlaced(betDetails[3], _msgSender(), token, totalStake, totalPayout, betDetails[0], betDetails[1], betDetails[2]);
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
}

///