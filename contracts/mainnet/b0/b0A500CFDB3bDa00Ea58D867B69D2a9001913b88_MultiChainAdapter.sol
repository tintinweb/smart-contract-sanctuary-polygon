// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";

interface ILZEndpoint {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint specified by our chainId.
    // @param _dstChainId - the destination chain identifier
    // @param _dstContractAddress - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId, 
        bytes calldata _dstContractAddress, 
        bytes calldata _payload, 
        address payable _refundAddress, 
        address _zroPaymentAddress, 
        bytes calldata _adapterParams
    ) external payable;
}

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

interface IAdapter {
    struct RoyaltyData {
        address royaltyReceiver;
        uint16 royaltyRate;
    }
    function send (uint256 chainId, address nft, uint256 tokenId, string calldata name, string calldata symbol, string calldata tokenURI, address recipient, IAdapter.RoyaltyData calldata royalty) external payable;
}

interface IReceiver {
    struct RoyaltyData {
        address royaltyReceiver;
        uint16 royaltyRate;
    }
    function receiveNFT (address nft, string calldata name, string calldata symbol, string calldata tokenURI, uint256 tokenId, address recipient, RoyaltyData calldata royalty) external;
}

contract MultiChainAdapter is IAdapter, BoringOwnable, ILayerZeroReceiver {

    mapping(uint256 => uint16) public connections;
    event LogAddConnection(uint256 chainId, uint16 chainIdLZ);

    IReceiver immutable public receiver;
    ILZEndpoint immutable public endpoint;

    constructor (IReceiver receiver_, ILZEndpoint endpoint_) {
        receiver = receiver_;
        endpoint = endpoint_;
    }

    function init(bytes calldata) public payable {}

    function send(uint256 chainId, address nft, uint256 tokenId, string calldata name, string calldata symbol, string calldata tokenURI, address recipient, IAdapter.RoyaltyData calldata royalty) external payable override {
        require(msg.sender == address(receiver));

        bytes memory payload;
        {
            payload = abi.encode(nft, tokenId, name, symbol, tokenURI, recipient, royalty);
        }

        uint16 chainIdLz = connections[chainId];
        require(chainIdLz != 0);
        // expectancy of sender/receiver deployed at the same address across networks
        // fee refund to the EOA that originated the tx
        // change gas amount being relayed potentially
        // TODO: TEST amount of gas needed for LZ
        endpoint.send(chainIdLz, abi.encodePacked(address(this)), payload, payable(tx.origin), address(0), bytes(""));
    }

    function lzReceive(uint16 _srcChainId, bytes memory _srcAddress,uint64 _nonce, bytes calldata _payload) external override {
        require(msg.sender == address(endpoint));
        address fromAddress;
        assembly {
            fromAddress := mload(add(_srcAddress, 20))
        }
        require(fromAddress == address(this));

        (address nft, uint256 tokenId, string memory name, string memory symbol, string memory tokenURI, address recipient, IReceiver.RoyaltyData memory royalty) = abi.decode(_payload, (address, uint256, string, string, string, address, IReceiver.RoyaltyData));

        receiver.receiveNFT(nft, name, symbol, tokenURI, tokenId, recipient, royalty);
    }

    function addConnection(uint256 chainId, uint16 chainIdLZ) external onlyOwner {
        connections[chainId] = chainIdLZ;
        emit LogAddConnection(chainId, chainIdLZ);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <=0.8.12;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Simplified by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}