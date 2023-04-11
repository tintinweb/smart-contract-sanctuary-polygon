// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "../lzApp/NonblockingLzApp.sol";
//import "../libraries/LzLib.sol";
import {AddressToString, StringToAddress} from '../libraries/StringAddressUtils.sol';
import "../interfaces/IOmniApp.sol";
import {MintParams, MintDecodedPayload} from "../structs/erc721/ERC721Structs.sol";
import "../interfaces/IOmniseaONFT721A.sol";

/// @title A LayerZero example sending a cross chain message from a source chain to a destination chain to increment a counter
contract OmniseaDropsManager is ReentrancyGuard {
    //    using StringToAddress for string;
    //    using AddressToString for address;

    //    event LzReceived(uint16 srcId);
    event Minted(address collAddr, address rec, uint256 quantity);
    event Paid(address rec);

    error InvalidPrice(address collAddr, address spender, uint256 paid, uint256 quantity);

    //    bytes private constant ESTIMATE_PAYLOAD = "\x01\x02\x03\x04";

    //    enum PacketType {
    //        SEND_TO_APTOS,
    //        RECEIVE_FROM_APTOS
    //    }

    struct LZConfig {
        bool payInZRO;
        address zroPaymentAddress;
    }

    // LayerZero / GMP Properties:
    //    LZConfig public lzConfig;
    //    mapping(uint16 => bool) public pausedChains; // chain id => isPaused
    //    bool public globalPaused;
    //    uint16 public aptosChainId;

    // Contract-level Properties:
    //    mapping(address => mapping(uint16 => uint256)) public mints;
    uint256 private _fee;
    address private _feeManager;
    address private _owner;

    //    modifier whenNotPaused(uint16 _chainId) {
    //        require(!globalPaused && !pausedChains[_chainId], "OmniseaDropsManager: paused");
    //        _;
    //    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        //        aptosChainId = 10108;
        _owner = msg.sender;
        _feeManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
    }

//    function setGlobalPause(bool _isPaused) external onlyOwner {
//        globalPaused = _isPaused;
//    }

//    function setChainPause(uint16 _dstChainId, bool _isPaused) external onlyOwner {
//        pausedChains[_dstChainId] = _isPaused;
//    }

    function setFee(uint256 fee) external onlyOwner {
        require(fee <= 20);
        _fee = fee;
    }

    function setFeeManager(address _newManager) external onlyOwner {
        _feeManager = _newManager;
    }

//    function setLzConfig(LZConfig calldata _lzConfig) external onlyOwner {
//        lzConfig = _lzConfig;
//    }

    //    function estimateFee(uint16 _dstChainId, bool _useZro, bytes calldata _adapterParams) public view returns (uint nativeFee, uint zroFee) {
    //        return lzEndpoint.estimateFees(_dstChainId, address(this), ESTIMATE_PAYLOAD, _useZro, _adapterParams);
    //    }

    function mint(MintParams calldata _params) public payable nonReentrant {
        require(_params.coll != address(0), "OmniseaDropsManager: !collAddr");
        require(_params.quantity > 0, "OmniseaDropsManager: !quantity");

        IOmniseaONFT721A collection = IOmniseaONFT721A(_params.coll);

        uint256 price = collection.mintPrice();
        uint256 quantityPrice = price * _params.quantity;
        if (quantityPrice > 0) {
            require(msg.value == quantityPrice, "OmniseaDropsManager: <price");
            (bool p,) = payable(_params.coll).call{value : msg.value}("");
            require(p, "OmniseaDropsManager: !p");
        }
        collection.mint(msg.sender, _params.quantity, _params.merkleProof, _fee);

        emit Minted(_params.coll, msg.sender, _params.quantity);
    }

    // TODO: (Must) function mintOn(dstChainId)

    //    function _nonblockingLzReceive(
    //        uint16 _srcChainId,
    //        bytes memory,
    //        uint64,
    //        bytes memory _payload
    //    ) internal override whenNotPaused(_srcChainId) nonReentrant {
    //        emit LzReceived(_srcChainId);
    //        require(trustedRemoteLookup[_srcChainId].length != 0, "!remote");
    //
    //        // Message received from Aptos:
    //        (MintDecodedPayload memory params) = _srcChainId == aptosChainId
    //        ? _decodeNonEVMPayload(_payload)
    //        : _decodeEVMPayload(_payload);
    //
    //        IOmniseaONFT721A collection = IOmniseaONFT721A(params.coll);
    //
    //        uint256 price = collection.mintPrice();
    //        uint256 quantityPrice = price * params.quantity;
    //
    //        collection.mint(params.minter, params.quantity, params.merkleProof);
    //        mints[params.coll][_srcChainId] += quantityPrice;
    //        emit Minted(params.coll, params.minter, params.quantity);
    //    }

    // address = 32 bytes (if from Aptos)
    // bool = 1 byte
    // uint8 = 1 byte
    // uint16 = 2 bytes
    // uint64 = 8 bytes
    // uint256 = 32 bytes
    //    function _decodeNonEVMPayload(bytes memory _payload) internal pure returns (MintDecodedPayload memory) {
    //        // require(_payload.length == 129, "TokenBridge: invalid payload length");
    //
    //        PacketType packetType = PacketType(uint8(_payload[0]));
    //        require(packetType == PacketType.RECEIVE_FROM_APTOS, "!packet type");
    //
    //        address coll;
    //        uint256 paid;
    //        address minter;
    //        uint256 quantity;
    //        bytes32[] memory merkleProof;
    //
    //        // TODO: Consider using BytesLib approach instead
    //        assembly {
    //            coll := mload(add(_payload, 33))
    //            paid := mload(add(_payload, 65))
    //            minter := mload(add(_payload, 97))
    //            quantity := mload(add(_payload, 129))
    //        }
    //        merkleProof = new bytes32[](0);
    //        // TODO: (Must) Consider non-EVM incoming WL MT proofs
    //
    //        return MintDecodedPayload(coll, paid, minter, quantity, merkleProof);
    //    }
    //
    //    function _decodeEVMPayload(bytes memory _payload) internal pure returns (MintDecodedPayload memory) {
    //        (address coll, uint256 paid, address minter, uint256 quantity, bytes32[] memory merkleProof)
    //        = abi.decode(_payload, (address, uint256, address, uint256, bytes32[]));
    //
    //        return MintDecodedPayload(coll, paid, minter, quantity, merkleProof);
    //    }
    //
    //    function _encodeMintPayload(
    //        address collectionAddress,
    //        uint256 paid,
    //        uint256 quantity,
    //        bytes32[] memory merkleProof
    //    ) private view returns (bytes memory) {
    //        return abi.encode(collectionAddress, (paid * quantity), msg.sender, quantity, merkleProof);
    //    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library StringToAddress {
    function toAddress(string memory _a) internal pure returns (address) {
        bytes memory tmp = bytes(_a);
        if (tmp.length != 42) return address(0);
        uint160 iaddr = 0;
        uint8 b;
        for (uint256 i = 2; i < 42; i++) {
            b = uint8(tmp[i]);
            if ((b >= 97) && (b <= 102)) b -= 87;
            else if ((b >= 65) && (b <= 70)) b -= 55;
            else if ((b >= 48) && (b <= 57)) b -= 48;
            else return address(0);
            iaddr |= uint160(uint256(b) << ((41 - i) << 2));
        }
        return address(iaddr);
    }
}

library AddressToString {
    function toString(address a) internal pure returns (string memory) {
        bytes memory data = abi.encodePacked(a);
        bytes memory characters = '0123456789abcdef';
        bytes memory byteString = new bytes(2 + data.length * 2);

        byteString[0] = '0';
        byteString[1] = 'x';

        for (uint256 i; i < data.length; ++i) {
            byteString[2 + i * 2] = characters[uint256(uint8(data[i] >> 4))];
            byteString[3 + i * 2] = characters[uint256(uint8(data[i] & 0x0f))];
        }
        return string(byteString);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOmniApp {
    /**
     * @notice Function to be implemented by the Omnichain Application ("OA") utilizing Omnichain Router for receiving
     *         cross-chain messages.
     *
     * @param payload Encoded payload with a data for a target function execution.
     * @param srcOA Address of the remote Omnichain Application ("OA") that can be used for source validation.
     * @param srcChain Name of the source remote chain.
     */
    function omReceive(bytes calldata payload, address srcOA, string memory srcChain) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct CreateParams {
    string name;
    string symbol;
    string uri;
    string tokensURI;
    uint24 maxSupply;
    bool isZeroIndexed;
    uint24 royaltyAmount;
    uint256 endTime;
}

struct MintParams {
    address coll;
    uint24 quantity;
    bytes32[] merkleProof;
}

struct MintDecodedPayload {
    address coll;
    uint256 paid;
    address minter;
    uint24 quantity;
    bytes32[] merkleProof;
}

struct Phase {
    uint256 from;
    uint24 maxPerAddress;
    uint256 price;
    bytes32 merkleRoot;
}

struct Allocation {
    uint8 percentage;
    address recipient;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOmniseaONFT721A {
    function mint(address owner, uint24 quantity, bytes32[] memory _merkleProof, uint256 _currentFee) external payable;
    function mintPrice() external view returns (uint256);
}