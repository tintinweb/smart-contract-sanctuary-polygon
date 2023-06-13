// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IWildeventReceiver} from "../interfaces/IWildeventReceiver.sol";

contract LinkedSocialSchemaVerifier is IWildeventReceiver {
    event SocialLinked(uint32 wildfileId, string platform);

    // exactly one Wildfile is allowed to be linked to a social per Wildevent
    error ExactlyOneWildfile();

    function onWildevent(uint32[] calldata wildfileIds, bytes calldata data) external {
        if (wildfileIds.length != 1) {
            revert ExactlyOneWildfile();
        }

        (string memory platform) = abi.decode(data, (string));
        emit SocialLinked(wildfileIds[0], platform);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWildeventReceiver {
    function onWildevent(uint32[] calldata wildfileIds, bytes calldata data) external;
}