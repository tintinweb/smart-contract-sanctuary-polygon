// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract AttestationStation {
    /**
     * @notice Maps addresses to attestations. Creator => About => Key => Value.
     */
    mapping(address => mapping(address => mapping(bytes32 => bytes)))
        public attestations;

    /**
     * @notice Struct representing data that is being attested.
     *
     * @custom:field creator Address that made the attestation.
     * @custom:field about Address for which the attestation is about.
     * @custom:field key   A bytes32 key for the attestation.
     * @custom:field val   The attestation as arbitrary bytes.
     */
    struct AttestationData {
        address creator;
        address about;
        bytes32 key;
        bytes val;
    }

    /**
     * @notice Emitted when Attestation is created.
     *
     * @param creator Address that made the attestation.
     * @param about   Address attestation is about.
     * @param key     Key of the attestation.
     * @param val     Value of the attestation.
     */
    event AttestationCreated(
        address indexed creator,
        address indexed about,
        bytes32 indexed key,
        bytes val
    );

    /**
     * @notice Allows anyone to create an attestation.
     *
     * @param _creator Address that the attestation is about.
     * @param _about Address that the attestation is about.
     * @param _key   A key used to namespace the attestation.
     * @param _val   An arbitrary value stored as part of the attestation.
     */
    function attestOne(
        address _creator,
        address _about,
        bytes32 _key,
        bytes memory _val
    ) public {
        attestations[_creator][_about][_key] = _val;
        emit AttestationCreated(_creator, _about, _key, _val);
    }

    /**
     * @notice Allows anyone to create attestations.
     *
     * @param _attestations An array of attestation data.
     */
    function attest(AttestationData[] calldata _attestations) external {
        uint256 length = _attestations.length;
        for (uint256 i = 0; i < length; ) {
            AttestationData memory attestation = _attestations[i];

            attestOne(
                attestation.creator,
                attestation.about,
                attestation.key,
                attestation.val
            );

            unchecked {
                ++i;
            }
        }
    }
}