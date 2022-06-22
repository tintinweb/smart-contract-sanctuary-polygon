// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {IValidator} from "./Validator/IValidator.sol";

/// @title Wiki
/// @author kesar.eth
/// @notice A contract to publish wikis
contract Wiki is Owned {

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error WikiNotValid();
    error InvalidSignature();
    error DeadlineExpired();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Posted(address indexed _from, string _ipfs);

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice contract that validates if wiki should be pushed
    IValidator private validator;

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @dev keccak256("SignedPost(string ipfs,address user,uint256 deadline)")
    bytes32 private constant SIGNED_POST_TYPEHASH = 0x2786d465b1ae76a678938e05e206e58472f266dfa9f8534a71c3e35dc91efb45;

    /// @notice the EIP-712 domain separator
    bytes32 private immutable EIP_712_DOMAIN_SEPARATOR =
    keccak256(
        abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("EP")),
            keccak256(bytes("1")),
            _chainID(),
            address(this)
        )
    );

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address _validator) Owned(msg.sender) {
        validator = IValidator(_validator);
    }

    /// @notice Set a validator for wikis
    /// @param _validator validator contract address
    function setValidator(IValidator _validator) onlyOwner external {
        validator = _validator;
    }

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    /// @notice Post IPFS hash
    /// @param ipfs The IPFS Hash
    function post(string calldata ipfs) external {
        if (validator.validate(msg.sender, ipfs) == false) {
            revert WikiNotValid();
        }
        emit Posted(msg.sender, ipfs);
    }

    /// @notice Post IPFS hash given an EIP-712 signature
    /// @param ipfs The IPFS Hash
    /// @param _user The user to approve the module for
    /// @param _deadline The deadline at which point the given signature expires
    /// @param _v The 129th byte and chain ID of the signature
    /// @param _r The first 64 bytes of the signature
    /// @param _s Bytes 64-128 of the signature
    function postBySig(
        string calldata ipfs,
        address _user,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        if (_deadline < block.timestamp) {
            revert DeadlineExpired();
        }

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                EIP_712_DOMAIN_SEPARATOR,
                keccak256(abi.encode(SIGNED_POST_TYPEHASH, keccak256(bytes(ipfs)), _user, _deadline))
            )
        );

        address recoveredAddress = ecrecover(digest, _v, _r, _s);

        if (recoveredAddress == address(0) || recoveredAddress != _user) {
            revert InvalidSignature();
        }

        if (validator.validate(_user, ipfs) == false) {
            revert WikiNotValid();
        }

        emit Posted(recoveredAddress, ipfs);
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    function _chainID() private view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    /// -----------------------------------------------------------------------
    /// Getters
    /// -----------------------------------------------------------------------

    /// @notice DOMAIN_SEPARATOR to generate signatures
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return EIP_712_DOMAIN_SEPARATOR;
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

interface IValidator {
    function validate(address _user, string calldata _ipfs) external returns (bool);
}