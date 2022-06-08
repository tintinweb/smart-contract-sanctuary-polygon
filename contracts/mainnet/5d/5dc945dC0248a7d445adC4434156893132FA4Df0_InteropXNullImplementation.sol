// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

contract InteropXNullImplementation {
    struct Spell {
        string connector;
        bytes data;
    }

    struct TokenInfo {
        address sourceToken;
        address targetToken;
        uint256 amount;
    }

    struct Position {
        TokenInfo[] supply;
        TokenInfo[] withdraw;
    }

    function submitAction(
        Position memory position,
        address sourceDsaSender,
        string memory actionId,
        uint64 targetDsaId,
        uint256 targetChainId,
        bytes memory metadata
    ) external {}

    /**
     * @dev cast sourceAction
     */
    function sourceAction(
        Spell[] memory sourceSpells,
        Spell[] memory commonSpells,
        Position memory position,
        string memory actionId,
        address sourceDsaSender,
        uint64 sourceDsaId,
        uint64 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 _vnonce,
        bytes memory metadata
    ) external {}

    /**
     * @dev cast targetAction
     */
    function targetAction(
        Spell[] memory sourceSpells,
        Spell[] memory targetSpells,
        Spell[] memory commonSpells,
        Position memory position,
        string memory actionId,
        address sourceDsaSender,
        uint64 sourceDsaId,
        uint64 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 _vnonce,
        bytes memory metadata
    ) external {}

    function submitSystemAction(
        string memory systemActionId,
        Position memory position,
        bytes memory metadata
    ) external {}

    function sourceSystemAction(
        Spell[] memory commonSpells,
        string memory systemActionId,
        Position memory position,
        uint256 _vnonce,
        bytes memory metadata
    ) external {}

    function submitRevertAction(
        Position memory position,
        address sourceDsaSender,
        string memory actionId,
        uint64 sourceDsaId,
        uint64 targetDsaId,
        uint256 targetChainId,
        uint256 _vnonce,
        bytes memory metadata
    ) external {}

    /**
     * @dev cast sourceActionRevert
     */
    function sourceRevertAction(
        Spell[] memory sourceSpells,
        Spell[] memory sourceRevertSpells,
        Spell[] memory commonSpells,
        Position memory position,
        string memory actionId,
        address sourceDsaSender,
        uint64 sourceDsaId,
        uint64 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 _vnonce,
        bytes memory metadata
    ) external {}

    /**
     * @dev cast targetRevertAction
     */
    function targetRevertAction(
        Spell[] memory sourceSpells,
        Position memory position,
        string memory actionId,
        address sourceDsaSender,
        uint64 sourceDsaId,
        uint64 targetDsaId,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 _vnonce,
        bytes memory metadata
    ) external {}

    receive() external payable {}
}