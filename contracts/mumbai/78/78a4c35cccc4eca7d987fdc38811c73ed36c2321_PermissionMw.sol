// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IMiddleware } from "../interfaces/IMiddleware.sol";
import { DataTypes } from "../libraries/DataTypes.sol";
import { Constants } from "../libraries/Constants.sol";
import { EIP712 } from "../base/EIP712.sol";

contract PermissionMw is IMiddleware, EIP712 {
    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Signer that approve meta transactions.
     */
    address public signer;

    /**
     * @notice User nonces that prevents signature replay.
     */
    mapping(address => uint256) public nonces;

    address public immutable NAME_REGISTRY; // solhint-disable-line

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address nameRegistry) {
        require(nameRegistry != address(0), "ZERO_ADDRESS");
        NAME_REGISTRY = nameRegistry;
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Reverts if called by any account other than the name registry.
     */
    modifier onlyNameRegistry() {
        require(NAME_REGISTRY == msg.sender, "NOT_NAME_REGISTRY");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        IMiddleware OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMiddleware
    function setMwData(bytes calldata data) external override onlyNameRegistry {
        signer = abi.decode(data, (address));
    }

    /// @inheritdoc IMiddleware
    function preProcess(
        DataTypes.RegisterNameParams calldata params,
        bytes calldata data
    ) external payable override onlyNameRegistry {
        DataTypes.EIP712Signature memory sig;

        (sig.v, sig.r, sig.s, sig.deadline) = abi.decode(
            data,
            (uint8, bytes32, bytes32, uint256)
        );

        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._REGISTER_TYPEHASH,
                        keccak256(bytes(params.name)),
                        params.to,
                        nonces[params.to]++,
                        sig.deadline
                    )
                )
            ),
            signer,
            sig.v,
            sig.r,
            sig.s,
            sig.deadline
        );
    }

    /// @inheritdoc IMiddleware
    function postProcess(
        DataTypes.RegisterNameParams calldata,
        bytes calldata
    ) external override onlyNameRegistry {}

    /// @inheritdoc IMiddleware
    function namePatternValid(
        string calldata name
    ) external pure returns (bool) {
        bytes memory byteName = bytes(name);

        if (byteName.length > 20 || byteName.length == 0) {
            return false;
        }

        uint256 byteNameLength = byteName.length;
        for (uint256 i = 0; i < byteNameLength; ) {
            bytes1 b = byteName[i];
            if ((b >= "0" && b <= "9") || (b >= "a" && b <= "z") || b == "_") {
                unchecked {
                    ++i;
                }
            } else {
                return false;
            }
        }
        return true;
    }

    function _domainSeparatorName()
        internal
        pure
        override
        returns (string memory)
    {
        return "PermissionMw";
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IMiddleware {
    /**
     * @notice Sets data for middleware.
     *
     * @param data Extra data to set.
     */
    function setMwData(bytes calldata data) external;

    /**
     * @notice Process that runs before the name creation happens.
     *
     * @param params The params for creating name.
     * @param data Extra data to process.
     */
    function preProcess(
        DataTypes.RegisterNameParams calldata params,
        bytes calldata data
    ) external payable;

    /**
     * @notice Process that runs after the name creation happens.
     *
     * @param params The params for creating name.
     * @param data Extra data to process.
     */
    function postProcess(
        DataTypes.RegisterNameParams calldata params,
        bytes calldata data
    ) external;

    /**
     * @notice Validates the name pattern.
     *
     * @param name The name to validate.
     */
    function namePatternValid(
        string calldata name
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

library DataTypes {
    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    struct MetadataPair {
        string key;
        string value;
    }

    struct RegisterNameParams {
        address msgSender;
        string name;
        address to;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

library Constants {
    bytes32 internal constant _REGISTER_TYPEHASH =
        keccak256(
            "register(string name,address to,uint256 nonce,uint256 deadline)"
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

abstract contract EIP712 {
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/
    bytes32 internal constant _HASHED_VERSION = keccak256("1");
    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the contract's {EIP712} domain separator.
     *
     * @return bytes32 the contract's {EIP712} domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _TYPE_HASH,
                    keccak256(bytes(_domainSeparatorName())),
                    _HASHED_VERSION,
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _requiresExpectedSigner(
        bytes32 digest,
        address expectedSigner,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 deadline
    ) internal view {
        require(deadline >= block.timestamp, "DEADLINE_EXCEEDED");
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "INVALID_SIGNATURE_S_VAULE"
        );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == expectedSigner, "INVALID_SIGNATURE");
    }

    function _requiresExpectedSigner(
        bytes32 digest,
        address expectedSigner,
        DataTypes.EIP712Signature calldata sig
    ) internal view {
        _requiresExpectedSigner(
            digest,
            expectedSigner,
            sig.v,
            sig.r,
            sig.s,
            sig.deadline
        );
    }

    function _hashTypedDataV4(
        bytes32 structHash
    ) internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash)
            );
    }

    function _domainSeparatorName()
        internal
        view
        virtual
        returns (string memory);
}