/**
 *Submitted for verification at polygonscan.com on 2022-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EverErrors {
    /**
    @notice Error returned if the drop already exists
    **/
    error DropAlreadyExists();

    /**
    @notice Error returned if the interface is not supported
    **/
    error InvalidInterface();

    /**
    @notice Error returned if the call is made from unauthorized source
    **/
    error UnauthorizedUpdate();

    /**
    @notice Error returned if the drop is sold-out
    **/
    error DropSoldOut();

    /**
    @notice Error returned if the sale has not started yet
    **/
    error SaleNotStarted();

    /**
    @notice Error returned if the sale has ended
    **/
    error SaleEnded();

    /**
    @notice Error returned if the supply is sold out
    **/
    error NotEnoughTokensAvailable();

    /**
    @notice Error returned if user did not send the correct amount
    **/
    error IncorrectAmountSent();
}