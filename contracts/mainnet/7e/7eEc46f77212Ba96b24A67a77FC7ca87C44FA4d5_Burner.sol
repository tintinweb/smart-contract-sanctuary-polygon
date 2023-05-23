pragma solidity 0.8.17;

import "./interfaces/IArtisant.sol";
import "./libs/Owned.sol";

contract Burner is Owned {

    event Burn(address indexed item_owner, uint256 indexed id, uint256 indexed drop);

    IArtisant public artisant;
    address public operator;
    uint256 public refund = 25; // %

    mapping(bytes32 => bool) private _hashUsed;

    //// CONSTRUCTOR ////

    constructor(
        IArtisant _artisant,
        address _operator,
        address owner_
    ) Owned(owner_) {
        artisant = _artisant;
        operator = _operator;
    }

    //// PUBLIC ////

    function burn(
        uint256 id,
        bytes32 hash,
        bytes memory signature
    ) public {
        verifySignature(hash, signature);
        _hashUsed[hash] = true;
        uint256 drop = artisant.idToDrop(id);
        uint256 price = artisant.dropPrice(drop);
        uint256 refundAmount = price * refund / 100;
        artisant.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, id);
        (bool sent,) = msg.sender.call{value: refundAmount}("");
        require(sent, "Failed to refund");
    }

    //// ONLY OWNER ////

    function setRefund(uint256 _refund) public onlyOwner {
        refund = _refund;
    }

    function setOperator(address _operator) public onlyOwner {
        operator = _operator;
    }

    function setArtisant(IArtisant _artisant) public onlyOwner {
        artisant = _artisant;
    }

    function withdraw() public onlyOwner {
        (bool sent,) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to withdraw");
    }

    //// PRIVATE ////

    function verifySignature(
        bytes32 hash,
        bytes memory signature
    ) private view {
        require(signature.length == 65, "INVALID_SIGNATURE_LENGTH");
        require(!_hashUsed[hash], "HASH_ALREADY_USED");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }

        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "INVALID_SIGNATURE_S_PARAMETER");
        require(v == 27 || v == 28, "INVALID_SIGNATURE_V_PARAMETER");

        require(ecrecover(hash, v, r, s) == operator, "INVALID_SIGNER");
    }

    receive() external payable{}

}

pragma solidity 0.8.17;

interface IArtisant {

    function transferFrom(address from, address to, uint256 id) external;
    function idToDrop (uint256 id) external view returns (uint256);
    function dropPrice(uint256 drop) external view returns (uint256);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

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

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}