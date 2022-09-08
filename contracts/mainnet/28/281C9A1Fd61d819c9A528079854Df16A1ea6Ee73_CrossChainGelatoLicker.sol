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

import "./NonblockingLzApp.sol";
import "./LibIceCreamNFTAddress.sol";

interface IIceCreamNFT {
    function lick(uint256 _tokenId) external;
}

contract CrossChainGelatoLicker is NonblockingLzApp {
    mapping(uint16 => uint256) public lastLicked;
    mapping(address => bool) public whitelistedCaller;

    modifier onlyWhitelistedCaller() {
        require(
            whitelistedCaller[msg.sender],
            "CrossChainGelatoLicker: Not whitelisted"
        );
        _;
    }

    constructor(address _endpoint) NonblockingLzApp(_endpoint) {}

    receive() external payable {}

    //@dev called by Gelato whenever `checker` returns true
    function initiateCCLick(uint16 _dstLzChainId, uint256 _tokenId)
        external
        payable
        onlyWhitelistedCaller
    {
        bytes memory lickPayload = abi.encode(_tokenId);

        (uint256 lzFee, ) = lzEndpoint.estimateFees(
            _dstLzChainId,
            address(this),
            lickPayload,
            false,
            bytes("")
        );

        require(
            address(this).balance >= lzFee,
            "CrossChainGelatoLicker: Not enough funds to pay for lz fee"
        );

        _lzSend(_dstLzChainId, lzFee, lickPayload);
        lastLicked[_dstLzChainId] = block.timestamp;
    }

    function setWhitelistedCaller(address[] calldata _addr, bool _whitelist)
        external
        onlyOwner
    {
        uint256 length = _addr.length;
        for (uint256 i; i < length; i++)
            whitelistedCaller[_addr[i]] = _whitelist;
    }

    //@dev called by Gelato check if it is time to call `initiateCCLick`
    function checker(uint16 _dstLzChainId, uint256 _tokenId)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        if (block.timestamp < lastLicked[_dstLzChainId] + 600) {
            execPayload = bytes(
                "CrossChainGelatoLicker: Not time to cross chain lick"
            );
            return (canExec, execPayload);
        }

        canExec = true;
        execPayload = abi.encodeWithSelector(
            this.initiateCCLick.selector,
            _dstLzChainId,
            _tokenId
        );

        return (canExec, execPayload);
    }

    function _lick(uint256 _tokenId) internal {
        IIceCreamNFT iceCreamNFT = IIceCreamNFT(
            LibIceCreamNFTAddress.getIceCreamNFTAddress()
        );

        iceCreamNFT.lick(_tokenId);
    }

    function _lzSend(
        uint16 _dstLzChainId,
        uint256 _lzFee,
        bytes memory _payload
    ) internal {
        bytes memory trustedRemote = trustedRemoteLookup[_dstLzChainId];
        require(
            trustedRemote.length != 0,
            "LzApp: destination chain is not a trusted source"
        );

        address payable refundAddress = payable(owner());

        lzEndpoint.send{value: _lzFee}(
            _dstLzChainId,
            trustedRemote,
            _payload,
            refundAddress,
            address(0),
            bytes("")
        );
    }

    function _nonblockingLzReceive(
        uint16,
        bytes memory,
        uint64,
        bytes memory lickPayload
    ) internal override {
        uint256 tokenId = abi.decode(lickPayload, (uint256));

        _lick(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
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

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    ) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress)
        external
        view
        returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication)
        external
        view
        returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication)
        external
        view
        returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint256 _configType
    ) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication)
        external
        view
        returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication)
        external
        view
        returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

library LibIceCreamNFTAddress {
    uint16 private constant _ID_BSC = 56;
    uint16 private constant _ID_AVAX = 43114;
    uint16 private constant _ID_POLYGON = 137;
    uint16 private constant _ID_ARBITRUM = 42161;
    uint16 private constant _ID_OPTIMISM = 10;
    uint16 private constant _ID_FANTOM = 250;

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

    function getIceCreamNFTAddress() internal view returns (address) {
        if (block.chainid == _ID_BSC) return _ICE_CREAM_BSC;
        if (block.chainid == _ID_AVAX) return _ICE_CREAM_AVAX;
        if (block.chainid == _ID_POLYGON) return _ICE_CREAM_POLYGON;
        if (block.chainid == _ID_ARBITRUM) return _ICE_CREAM_ARBITRUM;
        if (block.chainid == _ID_OPTIMISM) return _ICE_CREAM_OPTIMISM;
        if (block.chainid == _ID_FANTOM) return _ICE_CREAM_FANTOM;
        else revert("LibIceCreamNFTAddress: Not supported by LZ");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ILayerZeroReceiver.sol";
import "./ILayerZeroUserApplicationConfig.sol";
import "./ILayerZeroEndpoint.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is
    Ownable,
    ILayerZeroReceiver,
    ILayerZeroUserApplicationConfig
{
    ILayerZeroEndpoint public immutable lzEndpoint;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint16 => mapping(uint256 => uint256)) public minDstGasLookup;

    event SetTrustedRemote(uint16 _srcChainId, bytes _srcAddress);
    event SetMinDstGasLookup(
        uint16 _dstChainId,
        uint256 _type,
        uint256 _dstGasAmount
    );

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(
            _msgSender() == address(lzEndpoint),
            "LzApp: invalid endpoint caller"
        );

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(
            _srcAddress.length == trustedRemote.length &&
                keccak256(_srcAddress) == keccak256(trustedRemote),
            "LzApp: invalid source sending contract"
        );

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        require(
            trustedRemote.length != 0,
            "LzApp: destination chain is not a trusted source"
        );
        lzEndpoint.send{value: msg.value}(
            _dstChainId,
            trustedRemote,
            _payload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    function _checkGasLimit(
        uint16 _dstChainId,
        uint256 _type,
        bytes memory _adapterParams,
        uint256 _extraGas
    ) internal view {
        uint256 providedGasLimit = getGasLimit(_adapterParams);
        uint256 minGasLimit = minDstGasLookup[_dstChainId][_type] + _extraGas;
        require(minGasLimit > 0, "LzApp: minGasLimit not set");
        require(providedGasLimit >= minGasLimit, "LzApp: gas limit is too low");
    }

    function getGasLimit(bytes memory _adapterParams)
        internal
        pure
        returns (uint256 gasLimit)
    {
        require(_adapterParams.length >= 34, "LzApp: invalid adapterParams");
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address,
        uint256 _configType
    ) external view returns (bytes memory) {
        return
            lzEndpoint.getConfig(
                _version,
                _chainId,
                address(this),
                _configType
            );
    }

    // generic config for LayerZero user Application
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        override
        onlyOwner
    {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // allow owner to set it multiple times.
    function setTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        onlyOwner
    {
        trustedRemoteLookup[_srcChainId] = _srcAddress;
        emit SetTrustedRemote(_srcChainId, _srcAddress);
    }

    function setMinDstGasLookup(
        uint16 _dstChainId,
        uint256 _type,
        uint256 _dstGasAmount
    ) external onlyOwner {
        require(_dstGasAmount > 0, "LzApp: invalid _dstGasAmount");
        minDstGasLookup[_dstChainId][_type] = _dstGasAmount;
        emit SetMinDstGasLookup(_dstChainId, _type, _dstGasAmount);
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (bool)
    {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./LzApp.sol";

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
    constructor(address _endpoint) LzApp(_endpoint) {}

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32)))
        public failedMessages;

    event MessageFailed(
        uint16 _srcChainId,
        bytes _srcAddress,
        uint64 _nonce,
        bytes _payload
    );

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual override {
        // try-catch all errors/exceptions
        try
            this.nonblockingLzReceive(
                _srcChainId,
                _srcAddress,
                _nonce,
                _payload
            )
        {
            // do nothing
        } catch {
            // error / exception
            failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(
                _payload
            );
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public virtual {
        // only internal transaction
        require(
            _msgSender() == address(this),
            "NonblockingLzApp: caller must be LzApp"
        );
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    //@notice override this function
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    function retryMessage(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public payable virtual {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(
            payloadHash != bytes32(0),
            "NonblockingLzApp: no stored message"
        );
        require(
            keccak256(_payload) == payloadHash,
            "NonblockingLzApp: invalid payload"
        );
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }
}