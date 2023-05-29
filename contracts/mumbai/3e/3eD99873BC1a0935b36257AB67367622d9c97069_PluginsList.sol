// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @title Contract of Page.PluginsList
/// @notice This contract contains a list of plugin names.
/// @dev Constants from this list are used to access plugins settings.
library PluginsList {

    bytes32 public constant COMMUNITY_CREATE = keccak256(abi.encode("COMMUNITY_CREATE"));
    bytes32 public constant COMMUNITY_JOIN = keccak256(abi.encode("COMMUNITY_JOIN"));
    bytes32 public constant COMMUNITY_QUIT = keccak256(abi.encode("COMMUNITY_QUIT"));
    bytes32 public constant COMMUNITY_INFO = keccak256(abi.encode("COMMUNITY_INFO"));
    bytes32 public constant COMMUNITY_PROFIT = keccak256(abi.encode("COMMUNITY_PROFIT"));

    bytes32 public constant USER_INFO_ONE_COMMUNITY = keccak256(abi.encode("USER_INFO_ONE_COMMUNITY"));
    bytes32 public constant USER_INFO_ALL_COMMUNITIES = keccak256(abi.encode("USER_INFO_ALL_COMMUNITIES"));

    bytes32 public constant COMMUNITY_WRITE_POST = keccak256(abi.encode("COMMUNITY_WRITE_POST"));
    bytes32 public constant COMMUNITY_READ_POST = keccak256(abi.encode("COMMUNITY_READ_POST"));
    bytes32 public constant COMMUNITY_BURN_POST = keccak256(abi.encode("COMMUNITY_BURN_POST"));
    bytes32 public constant COMMUNITY_TRANSFER_POST = keccak256(abi.encode("COMMUNITY_TRANSFER_POST"));
    bytes32 public constant COMMUNITY_CHANGE_VISIBILITY_POST = keccak256(abi.encode("COMMUNITY_CHANGE_VISIBILITY_POST"));
    bytes32 public constant COMMUNITY_POST_GAS_COMPENSATION = keccak256(abi.encode("COMMUNITY_POST_GAS_COMPENSATION"));
    bytes32 public constant COMMUNITY_EDIT_MODERATORS = keccak256(abi.encode("COMMUNITY_EDIT_MODERATORS"));
    bytes32 public constant COMMUNITY_REPOST = keccak256(abi.encode("COMMUNITY_REPOST"));

    bytes32 public constant SINGLE_WRITE_POST = keccak256(abi.encode("SINGLE_WRITE_POST"));
    bytes32 public constant SINGLE_WRITE_COMMENT = keccak256(abi.encode("SINGLE_WRITE_COMMENT"));
    bytes32 public constant SINGLE_READ_POST = keccak256(abi.encode("SINGLE_READ_POST"));
    bytes32 public constant SINGLE_READ_ALL_COMMENT = keccak256(abi.encode("SINGLE_READ_ALL_COMMENT"));
    bytes32 public constant SINGLE_BURN_POST = keccak256(abi.encode("SINGLE_BURN_POST"));
    bytes32 public constant SINGLE_BURN_COMMENT = keccak256(abi.encode("SINGLE_BURN_COMMENT"));
    bytes32 public constant SINGLE_TRANSFER_POST = keccak256(abi.encode("SINGLE_TRANSFER_POST"));
    bytes32 public constant SINGLE_CHANGE_VISIBILITY_POST = keccak256(abi.encode("SINGLE_CHANGE_VISIBILITY_POST"));
    bytes32 public constant SINGLE_CHANGE_VERIFICATION = keccak256(abi.encode("SINGLE_CHANGE_VERIFICATION"));

    bytes32 public constant COMMUNITY_WRITE_COMMENT = keccak256(abi.encode("COMMUNITY_WRITE_COMMENT"));
    bytes32 public constant COMMUNITY_READ_COMMENT = keccak256(abi.encode("COMMUNITY_READ_COMMENT"));
    bytes32 public constant COMMUNITY_READ_ALL_COMMENT = keccak256(abi.encode("COMMUNITY_READ_ALL_COMMENT"));
    bytes32 public constant COMMUNITY_BURN_COMMENT = keccak256(abi.encode("COMMUNITY_BURN_COMMENT"));
    bytes32 public constant COMMUNITY_CHANGE_VISIBILITY_COMMENT = keccak256(abi.encode("COMMUNITY_CHANGE_VISIBILITY_COMMENT"));
    bytes32 public constant COMMUNITY_COMMENT_GAS_COMPENSATION = keccak256(abi.encode("COMMUNITY_COMMENT_GAS_COMPENSATION"));

    bytes32 public constant BANK_DEPOSIT = keccak256(abi.encode("BANK_DEPOSIT"));
    bytes32 public constant BANK_WITHDRAW = keccak256(abi.encode("BANK_WITHDRAW"));
    bytes32 public constant BANK_BALANCE_OF = keccak256(abi.encode("BANK_BALANCE_OF"));
    bytes32 public constant FAUCET_TEST_MINT = keccak256(abi.encode("FAUCET_TEST_MINT"));

    bytes32 public constant SOULBOUND_GENERATE = keccak256(abi.encode("SOULBOUND_GENERATE"));
    bytes32 public constant SOULBOUND_BALANCE_OF = keccak256(abi.encode("SOULBOUND_BALANCE_OF"));

    bytes32 public constant SUBSCRIPTION_BUY = keccak256(abi.encode("SUBSCRIPTION_BUY"));
    bytes32 public constant SUBSCRIPTION_BUY_FOR_SINGLE_POST = keccak256(abi.encode("SUBSCRIPTION_BUY_FOR_SINGLE_POST"));
    bytes32 public constant SUBSCRIPTION_INFO = keccak256(abi.encode("SUBSCRIPTION_INFO"));

    bytes32 public constant SAFE_DEAL_MAKE = keccak256(abi.encode("SAFE_DEAL_MAKE"));
    bytes32 public constant SAFE_DEAL_READ = keccak256(abi.encode("SAFE_DEAL_READ"));
    bytes32 public constant SAFE_DEAL_CANCEL = keccak256(abi.encode("SAFE_DEAL_CANCEL"));
    bytes32 public constant SAFE_DEAL_FINISH = keccak256(abi.encode("SAFE_DEAL_FINISH"));
    bytes32 public constant SAFE_DEAL_ADD_MESSAGE = keccak256(abi.encode("SAFE_DEAL_ADD_MESSAGE"));
    bytes32 public constant SAFE_DEAL_SET_ISSUE = keccak256(abi.encode("SAFE_DEAL_SET_ISSUE"));
    bytes32 public constant SAFE_DEAL_CLEAR_ISSUE = keccak256(abi.encode("SAFE_DEAL_CLEAR_ISSUE"));
    bytes32 public constant SAFE_DEAL_SET_APPROVE = keccak256(abi.encode("SAFE_DEAL_SET_APPROVE"));
    bytes32 public constant SAFE_DEAL_CHANGE_TIME = keccak256(abi.encode("SAFE_DEAL_CHANGE_TIME"));
    bytes32 public constant SAFE_DEAL_CHANGE_DESCRIPTION = keccak256(abi.encode("SAFE_DEAL_CHANGE_DESCRIPTION"));

    function version() external pure returns (string memory) {
        return "1";
    }
}