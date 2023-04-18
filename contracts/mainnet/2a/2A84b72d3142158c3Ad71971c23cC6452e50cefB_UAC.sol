// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IECDSASignature2 {
    function verifyMessage(bytes32 messageHash, uint256 nonce, uint256 timestamp, bytes[] memory signatures) external;
    function signatureStatus(bytes32 messageHash, uint256 nonce, uint256 timestamp, bytes[] memory signatures) external view returns(uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUAC {
    function verifyUser(address user) external view;

    function verifyGameStatus(uint _panicLevel) external view;

    function verifyAll(address user, uint _panicLevel) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library ECDSALib {
    function hash(bytes memory encodePackedMsg) internal pure returns (bytes32) {
        return keccak256(encodePackedMsg);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Interfaces/IECDSASignature2.sol";
import "./libs/ECDSALib.sol";
import "./Interfaces/IUAC.sol";

contract UAC is IUAC {
    using ECDSALib for bytes;
    IECDSASignature2 private Signature;

    uint private panicLevel = 0;

    struct Status {
        bool banned;
        string reason;
    }

    mapping(address => Status) uac_users;
    mapping(uint => string) panic_msg;

    event BannedUser(address indexed user, string reason);
    event UnbannedUser(address indexed user, string reason);
    event GameStopped(string reason);

    constructor(IECDSASignature2 _signature) {
        Signature = _signature;
        panic_msg[1] = "All marketplace operations are stopped";
    }

    function banUser(
        address user,
        string memory reason,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external {
        require(user != address(0), "The address cannot be 0");
        Signature.verifyMessage(
            abi.encodePacked(user).hash(),
            nonce,
            timestamp,
            signatures
        );
        uac_users[user].banned = true;
        uac_users[user].reason = reason;
        emit BannedUser(user, reason);
    }

    function unbanUser(
        address user,
        string memory reason,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external {
        require(user != address(0), "The address cannot be 0");
        Signature.verifyMessage(
            abi.encodePacked(user).hash(),
            nonce,
            timestamp,
            signatures
        );
        uac_users[user].banned = false;
        uac_users[user].reason = "";
        emit UnbannedUser(user, reason);
    }

    function stopGame(
        uint _panicLevel,
        string memory reason,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external {
        Signature.verifyMessage(
            abi.encodePacked(msg.sender).hash(),
            nonce,
            timestamp,
            signatures
        );
        panicLevel = _panicLevel;
        emit GameStopped(reason);
    }
    
    function verifyUser(address user) external view {
        _verifyUser(user);
    }

    function verifyGameStatus(uint _panicLevel) external view {
        _verifyGameStatus(_panicLevel);
    }

    function verifyAll(address user, uint _panicLevel) external view {
        _verifyUser(user);
        _verifyGameStatus(_panicLevel);
    }

    function _verifyUser(address user) private view {
        require(uac_users[user].banned == false, "User banned");
    }

    function _verifyGameStatus(uint _panicLevel) private view {
        require(panicLevel < _panicLevel, panic_msg[_panicLevel]);
    }
}