// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

contract EIP712 {
    bytes32 public constant salt =
        0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558;

    bytes32 private domainSeparator;
    bytes32 public messageHash;

    string public version;
    string public messageContent;

    event VersionUpdated(string, string);
    event MessageContentUpdated(string);

    // @notice - Sets the version of the project
    // @param _version - the version of the project
    function setVersion(string memory _version) external {
        string memory previousVersion = version;
        version = _version;
        emit VersionUpdated(previousVersion, _version);
    }

    // @notice - Sets the message content to be signed
    // @param _messageContent - the message to be signed
    function setMessageContent(string memory _messageContent) external {
        messageContent = _messageContent;
        emit MessageContentUpdated(_messageContent);
    }

    // @notice - Calculates the domain separator and sets its value
    function setDomainSeparator() external {
        domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    abi.encodePacked(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
                    )
                ),
                keccak256(bytes("Carbon XYZ")),
                keccak256(bytes(version)),
                getChainId(),
                address(this),
                salt
            )
        );
    }

    // @notice - Calculate the message hash using domain separator and then sets its value
    function setMessageHash() external {
        messageHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        keccak256("mail(string content)"),
                        keccak256(bytes(messageContent))
                    )
                )
            )
        );
    }

    /*
     * @notice - To verify the signature with the help of message hash and the signature.
     * @param - signer - address of one who signed the message
     * @param- v, r, s - values from the signature
     * @returns - true if signer address matches with the address returned on using
     * ecrecover *for the message hash and the signature
     */
    function verify(
        address signer,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external view returns (bool) {
        require(
            signer == ecrecover(messageHash, v, r, s),
            "EIP712: Invalid Signer"
        );
        return true;
    }

    // @notice returns the chain id of the network
    function getChainId() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}