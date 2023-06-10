/**
 *Submitted for verification at polygonscan.com on 2023-06-09
*/

pragma solidity ^0.8.0;

contract meetingTerms {

    address public user;
    bool public hasAcceptedTerms;

    constructor(address _user) {
        user = _user;
        hasAcceptedTerms = false;
    }

    function acceptTerms() public {
        require(msg.sender == user, "Only the user can accept the terms");
        hasAcceptedTerms = true;
    }

    function checkAcceptance() public view returns(bool) {
        return hasAcceptedTerms;
    }
}