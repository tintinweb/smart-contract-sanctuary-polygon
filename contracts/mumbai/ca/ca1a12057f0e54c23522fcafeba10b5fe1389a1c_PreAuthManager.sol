/**
 *Submitted for verification at polygonscan.com on 2023-02-05
*/

// File: contracts/interfaces/constants.sol

// 
pragma solidity ^0.8.0;

enum PeriodUnit {
    SECOND,
    MINUTE,
    HOUR,
    DAY,
    MONTH
}

// File: contracts/preauth/PreAuthManager.sol

// 
pragma solidity ^0.8.0;

//    enum PeriodUnit {
//        SECOND,
//        MINUTE,
//        HOUR,
//        DAY,
//        MONTH
//    }

struct PreAuthorizationObject {
    uint nonce; // random 256bits
    uint timestamp;
    uint chainID; // prevent replay attack
    uint templateID;
    uint totalLimit;
    uint singleLimit;
    address settleTokenAddress;
    uint expires;
    uint frequency;
    PeriodUnit periodUnit;
}

struct PreAuthorizationTemplate {
    string metadataURI; // description & serviceName
    address creator;
    // point to App, but calldata can be modified
    address caller;
    address callAddress;
}

contract PreAuthManager {
    mapping(uint => PreAuthorizationTemplate) public preAuthorizationTemplates;
    uint templateID;

    event PreAuthorizationTemplateCreated(uint templateID);

    function getPreAuthorizationTemplate(
        uint nonce
    ) public view returns (PreAuthorizationTemplate memory) {
        return preAuthorizationTemplates[nonce];
    }

    function createPreAuthorizationTemplate(
        string memory metadataURI,
        address caller,
        address callAddress
    ) public {
        preAuthorizationTemplates[templateID] = PreAuthorizationTemplate(
            metadataURI,
            msg.sender,
            caller,
            callAddress
        );
        emit PreAuthorizationTemplateCreated(templateID);
        templateID += 1;
    }
}