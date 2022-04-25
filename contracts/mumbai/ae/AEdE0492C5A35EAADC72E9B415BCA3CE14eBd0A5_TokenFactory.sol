// SPDX-License-Identifier: MIT
// NFTZero Contracts v0.0.1

pragma solidity ^0.8.7;

import "../interfaces/IOmniERC721.sol";
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenFactory is ILayerZeroReceiver {

    event LzReceiveLog(string omniId);

    ILayerZeroEndpoint public endpoint;
    mapping(uint16 => bytes) public remotes;
    mapping(string => uint256) private _chainSymbolToId;
    address private _owner;
    uint256 private _contractChainId;
    IERC20 private _baseAsset;
    address private _treasury;

    constructor() {
        endpoint = ILayerZeroEndpoint(address(0xf69186dfBa60DdB133E91E9A4B5673624293d8F8)); // 0x79a63d6d8BBD5c6dfc774dA79bCcD948EAcb53FA Rinkeby
        _contractChainId = 10009;
        _owner = msg.sender;
        _baseAsset = IERC20(address(0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b)); // Rinkeby USDC
        _treasury = address(0x2fAAAa87963fdE26B42FB5CedB35a502d3ee09B3); // Testing Treasury

        _chainSymbolToId["eth"] = 10001;
        _chainSymbolToId["bsc"] = 10002;
        _chainSymbolToId["avalanche"] = 10006;
        _chainSymbolToId["polygon"] = 10009;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    function mintToken(
        string memory chainSymbol,
        address contractAddress, // Address of the existing "collection" - existing ERC721
        string memory tokenURI,
        address destinationAddress,
        uint256 mintPrice,
        address creator
    ) public payable {
        require(bytes(chainSymbol).length > 0 && contractAddress != address(0), "Token data incomplete");
        require(_chainSymbolToId[chainSymbol] > 0, "Invalid chain symbol");

        address tokenOwner = destinationAddress != address(0) ? destinationAddress : msg.sender;
        bytes memory payload = abi.encode(contractAddress, tokenURI, tokenOwner, mintPrice, creator);
        uint16 mappedChainId = uint16(_chainSymbolToId[chainSymbol]);

        if (_chainSymbolToId[chainSymbol] == _contractChainId) {
            IOmniERC721 omniNft = IOmniERC721(contractAddress);
            uint256 price = omniNft.getMintPrice();

            if (price > 0) {
                uint256 usdcAllowance = _baseAsset.allowance(msg.sender, address(this));
                require(usdcAllowance >= price, "Insufficient allowance");
                _baseAsset.transferFrom(msg.sender, omniNft.getCreator(), price * 99 / 100);
                _baseAsset.transferFrom(msg.sender, _treasury, price * 1 / 100);
            }

            omniNft.mint(tokenOwner, tokenURI);
            return;
        }

        if (mintPrice > 0) {
            uint256 usdcAllowance = _baseAsset.allowance(msg.sender, address(this));
            require(usdcAllowance >= mintPrice, "Insufficient allowance");
            _baseAsset.transferFrom(msg.sender, creator, mintPrice * 99 / 100);
            _baseAsset.transferFrom(msg.sender, _treasury, mintPrice * 1 / 100);
        }

        endpoint.send{value : msg.value}(
            mappedChainId,
            remotes[mappedChainId], // destination address of OmniMint LzReceiver Contract
            payload,
            payable(msg.sender),
            address(0x0),
            bytes("")
        );
    }

    function setRemote(uint16 _chainId, bytes calldata _remoteAddress) external onlyOwner {
        require(remotes[_chainId].length == 0, "The remote address has already been set for the chainId!");
        remotes[_chainId] = _remoteAddress;
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64,
        bytes memory _payload
    ) override external {
        emit LzReceiveLog("Receiver log");

        require(msg.sender == address(endpoint));
        require(
            _srcAddress.length == remotes[_srcChainId].length && keccak256(_srcAddress) == keccak256(remotes[_srcChainId]),
            "Invalid remote sender address. owner should call setRemote() to enable remote contract"
        );

        (address contractAddress, string memory tokenURI, address receiver, uint256 paid, address creator) = abi.decode(_payload, (address, string, address, uint256, address));

        require(contractAddress != address(0), "ERC721 contract address is invalid");
        IOmniERC721 omniNft = IOmniERC721(contractAddress);
        uint256 price = omniNft.getMintPrice();

        if (price > 0) {
            require(paid >= price, "Not paid for mint");
        }
        require(creator == omniNft.getCreator(), "Invalid payment receiver (not creator)");

        omniNft.mint(receiver, tokenURI);
    }
}

pragma solidity ^0.8.7;

interface IOmniERC721 {
    function mint(address owner, string memory tokenURI) external;
    function exists() external view returns (bool);
    function getMintPrice() external view returns (uint256);
    function getCreator() external view returns (address);
    function getDetails() external view returns (string memory, address, uint256, uint256, uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: BUSL-1.1

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
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

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
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}