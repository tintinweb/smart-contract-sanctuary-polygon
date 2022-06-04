// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./PhatLootOracleConsumer.sol";

/**
 * @title Fortune Cookie Dispenser
 * @dev Template consumer contract for the Phat Loot Oracle
 * @author Phat Loot DeFi Developers
 * @custom:version v1.0
 * @custom:date 3 June 2022
 */
contract FortuneCookieDispenser is PhatLootOracleConsumer {
    mapping(address => string) private _cookies;

    // The address supplied in the PhatLootOracleConsumer is the PhatLootOracle address on the respective chain
    // solhint-disable-next-line no-empty-blocks
    constructor() PhatLootOracleConsumer(0x09A806AA3170b74BE957962Cdc3aad9b05Ef51BA) {} // Mumbai

    function requestNewFortuneCookie() external {
        // 1 is the id of the FortuneCookieDispenser service that's attached to the Phat Loot Oracle Router
        // This is a request without a payload. If you need a payload, use oracleRequestWithPayload(1, bytes32)
        _oracleRequest(1);
    }

    function _oracleResponse(
        address caller,
        uint256 opcode,
        bytes memory response
    ) internal override {
        if (opcode == 1) {
            _cookies[caller] = abi.decode(response, (string));
        }
    }

    function getCookie(address owner) public view returns (string memory) {
        return _cookies[owner];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./interface/IPhatLootOracle.sol";
import "./interface/IPhatLootOracleConsumer.sol";

error AccessDenied();

/**
 * @title PhatLoot Oracle Consumer
 * @dev Consumer contract for the Phat Loot Oracle
 * @author Phat Loot DeFi Developers
 * @custom:version v1.0
 * @custom:date 3 June 2022
 */
abstract contract PhatLootOracleConsumer is IPhatLootOracleConsumer {
    IPhatLootOracle private oracle;

    constructor(address oracleAddress) {
        oracle = IPhatLootOracle(oracleAddress);
    }

    function _oracleRequest(uint256 opcode) internal virtual {
        oracle.request(address(this), msg.sender, opcode);
    }

    function _oracleRequestWithPayload(uint256 opcode, bytes memory payload) internal virtual {
        oracle.requestWithPayload(address(this), msg.sender, opcode, payload);
    }

    /** @dev Can only be called by an Oracle node */
    function oracleResponseProtected(
        address caller,
        uint256 opcode,
        bytes memory response
    ) external override {
        if (!oracle.isVerifiedOracleRouter(msg.sender)) revert AccessDenied();
        _oracleResponse(caller, opcode, response);
    }

    /** @dev To be overridden by consumers for consuming Oracle response */
    function _oracleResponse(
        address caller,
        uint256 opcode,
        bytes memory response
    ) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Interface for Phat Loot Oracle
 * @dev Interface for the main contract for the Phat Loot Oracle interface to the Oracle Router
 * @author Phat Loot DeFi Developers
 * @custom:version v1.0
 * @custom:date 1 June 2022
 */
interface IPhatLootOracle {
    function request(
        address consumer,
        address caller,
        uint256 opcode
    ) external;

    function requestWithPayload(
        address consumer,
        address caller,
        uint256 opcode,
        bytes memory payload
    ) external;

    function isVerifiedOracleRouter(address router) external view returns (bool isAllowed);

    event OracleRequest(address consumer, address caller, uint256 opcode);

    event OracleRequestWithPayload(address consumer, address caller, uint256 opcode, bytes payload);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/**
 * @title Phat Loot Oracle Consumer interface
 * @dev Interface for Phat Loot Oracle Consumer
 * @author Phat Loot DeFi Developers
 * @custom:version v1.0
 * @custom:date 3 June 2022
 */
interface IPhatLootOracleConsumer {
    function oracleResponseProtected(
        address caller,
        uint256 opcode,
        bytes memory response
    ) external;
}