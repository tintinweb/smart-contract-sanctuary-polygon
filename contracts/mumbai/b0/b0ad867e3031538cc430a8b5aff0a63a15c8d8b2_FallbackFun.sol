/**
 *Submitted for verification at polygonscan.com on 2022-09-24
*/

// File: contracts/FallbackFun.sol

/**
 *Submitted for verification at polygonscan.com on 2022-03-30
 */

pragma solidity ^0.8.4;

contract FallbackFun  {

    event PaymentReceived(
        string msg
    );

    fallback()  external  {
        emit PaymentReceived("Horray! function called");
    }

}