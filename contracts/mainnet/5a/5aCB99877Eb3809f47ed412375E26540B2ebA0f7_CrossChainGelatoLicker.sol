// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./LibIceCreamNFTAddress.sol";

interface ILayerZeroEndpoint {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;
}

contract CrossChainGelatoLicker is Ownable {
    using LibIceCreamNFTAddress for uint256;

    address public immutable ops;
    ILayerZeroEndpoint public immutable lzEndpoint;

    mapping(uint256 => mapping(uint256 => uint256)) public lastLicked;

    modifier onlyOps() {
        require(msg.sender == ops, "CrossChainGelatoLicker: Only ops");
        _;
    }

    constructor(address _ops, ILayerZeroEndpoint _lzEndpoint) {
        ops = _ops;
        lzEndpoint = _lzEndpoint;
    }

    receive() external payable {}

    //@dev called by Gelato whenever `checker` returns true
    function initiateCCLick(
        uint256 _chainId,
        address _dstLicker,
        uint256 _tokenId
    ) external payable onlyOps {
        bytes memory lickPayload = abi.encode(_tokenId);

        lastLicked[_chainId][_tokenId] = block.timestamp;
        uint16 lzChainId = _chainId.getLzChainId();

        lzEndpoint.send{value: address(this).balance}(
            lzChainId,
            abi.encodePacked(_dstLicker),
            lickPayload,
            payable(this),
            address(0),
            bytes("")
        );
    }

    //@dev called by Gelato check if it is time to call `initiateCCLick`
    function checker(
        uint256 _chainId,
        address _dstLicker,
        uint256 _tokenId
    ) external view returns (bool canExec, bytes memory execPayload) {
        if (block.timestamp < lastLicked[_chainId][_tokenId] + 600) {
            canExec = false;
            execPayload = bytes(
                "CrossChainGelatoLicker: Not time to cross chain lick"
            );
            return (canExec, execPayload);
        }

        canExec = true;
        execPayload = abi.encodeWithSelector(
            this.initiateCCLick.selector,
            _chainId,
            _dstLicker,
            _tokenId
        );

        return (canExec, execPayload);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

library LibIceCreamNFTAddress {
    uint256 private constant _ID_BSC = 56;
    uint256 private constant _ID_AVAX = 43114;
    uint256 private constant _ID_POLYGON = 137;
    uint256 private constant _ID_ARBITRUM = 42161;
    uint256 private constant _ID_OPTIMISM = 10;
    uint256 private constant _ID_FANTOM = 250;

    uint16 private constant _LZ_ID_BSC = 2;
    uint16 private constant _LZ_ID_AVAX = 6;
    uint16 private constant _LZ_ID_POLYGON = 9;
    uint16 private constant _LZ_ID_ARBITRUM = 10;
    uint16 private constant _LZ_ID_OPTIMISM = 11;
    uint16 private constant _LZ_ID_FANTOM = 12;

    address private constant _ICE_CREAM_BSC =
        address(0x915E840ce933dD1dedA87B08C0f4cCE46916fd01);
    address private constant _ICE_CREAM_AVAX =
        address(0x915E840ce933dD1dedA87B08C0f4cCE46916fd01);
    address private constant _ICE_CREAM_POLYGON =
        address(0xb74de3F91e04d0920ff26Ac28956272E8d67404D);
    address private constant _ICE_CREAM_ARBITRUM =
        address(0x0f44eAAC6B802be1A4b01df9352aA9370c957f5a);
    address private constant _ICE_CREAM_OPTIMISM =
        address(0x63C51b1D80B209Cf336Bec5a3E17D3523B088cdb);
    address private constant _ICE_CREAM_FANTOM =
        address(0x255F82563b5973264e89526345EcEa766DB3baB2);

    function getLzChainId(uint256 _chainId) internal pure returns (uint16) {
        if (_chainId == _ID_BSC) return _LZ_ID_BSC;
        if (_chainId == _ID_AVAX) return _LZ_ID_AVAX;
        if (_chainId == _ID_POLYGON) return _LZ_ID_POLYGON;
        if (_chainId == _ID_ARBITRUM) return _LZ_ID_ARBITRUM;
        if (_chainId == _ID_OPTIMISM) return _LZ_ID_OPTIMISM;
        if (_chainId == _ID_FANTOM) return _LZ_ID_FANTOM;
        else revert("LibIceCreamNFTAddress: Not supported by LZ");
    }

    function getIceCreamNFTAddress(uint256 _chainId)
        internal
        pure
        returns (address)
    {
        if (_chainId == _ID_BSC) return _ICE_CREAM_BSC;
        if (_chainId == _ID_AVAX) return _ICE_CREAM_AVAX;
        if (_chainId == _ID_POLYGON) return _ICE_CREAM_POLYGON;
        if (_chainId == _ID_ARBITRUM) return _ICE_CREAM_ARBITRUM;
        if (_chainId == _ID_OPTIMISM) return _ICE_CREAM_OPTIMISM;
        if (_chainId == _ID_FANTOM) return _ICE_CREAM_FANTOM;
        else revert("LibIceCreamNFTAddress: Not supported by LZ");
    }
}