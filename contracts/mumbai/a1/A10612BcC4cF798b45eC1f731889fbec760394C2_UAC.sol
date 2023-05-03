// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

interface IECDSASignature2 {
    function verifyMessage(bytes32 messageHash, uint256 nonce, uint256 timestamp, bytes[] memory signatures) external;
    function signatureStatus(bytes32 messageHash, uint256 nonce, uint256 timestamp, bytes[] memory signatures) external view returns(uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

interface IUAC {
    function verifyUser(address user) external view;

    function verifyGameStatus(uint _panicLevel) external view;

    function verifyAll(address user, uint _panicLevel) external view;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

library ECDSALib {
    function hash(bytes memory encodePackedMsg) internal pure returns (bytes32) {
        return keccak256(encodePackedMsg);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

import "./Interfaces/IECDSASignature2.sol";
import "./libs/ECDSALib.sol";
import "./Interfaces/IUAC.sol";

contract UAC is IUAC {
    using ECDSALib for bytes;
    IECDSASignature2 private signature;

    uint private panicLevel = 0;

    struct Status {
        bool banned;
        string reason;
    }

    mapping(address => Status) private uac_users;
    mapping(uint => string) private panic_msg;

    event BannedUser(address indexed user, string reason);
    event UnbannedUser(address indexed user, string reason);
    event GameStopped(string reason, uint panicLevel);

    constructor(IECDSASignature2 _signature) {
        signature = _signature;
        panic_msg[1] = "-All marketplace operations are stopped";
        panic_msg[2] = "--All stake operations are stopped";
        panic_msg[3] = "---All ERC20 withdrawal operations are stopped";
        panic_msg[4] = "----All NFT transfer operations are stopped";
        panic_msg[5] = "-----The whole game is stopped*";
    }

    function banUser(
        address user,
        string memory reason,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external {
        require(user != address(0), "The address cannot be 0");
        signature.verifyMessage(
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
        signature.verifyMessage(
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
        require(_panicLevel > 0, "Panic level must be greater than 0");
        signature.verifyMessage(
            abi.encodePacked(_panicLevel, msg.sender).hash(),
            nonce,
            timestamp,
            signatures
        );
        panicLevel = _panicLevel;
        emit GameStopped(reason, _panicLevel);
    }

    function resumeGame(
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external {
        signature.verifyMessage(
            abi.encodePacked(msg.sender).hash(),
            nonce,
            timestamp,
            signatures
        );
        panicLevel = 0;
    }

    function setPanicLevelMsg(
        string memory message,
        uint level,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external {
        signature.verifyMessage(
            abi.encodePacked(level, msg.sender).hash(),
            nonce,
            timestamp,
            signatures
        );
        panic_msg[level] = message;
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