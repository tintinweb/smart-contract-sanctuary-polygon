//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "./Ownable.sol";
import "./ERC721.sol";
import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroReceiver.sol";

contract OmniChainNFT is Ownable, ERC721, ILayerZeroReceiver {
    uint256 counter = 0;
    uint256 nextId = 0;
    uint256 MAX = 100;
    uint256 gas = 350000;
    ILayerZeroEndpoint public endpoint;
    event ReceiveNFT(
        uint16 _srcChainId,
        address _from,
        uint256 _tokenId,
        uint256 counter
    );

    constructor(
        address _endpoint,
        uint256 startId,
        uint256 _max
    ) ERC721("OmniChainNFT", "OOCCNFT") {
        endpoint = ILayerZeroEndpoint(_endpoint);
        nextId = startId;
        MAX = _max;
    }

    function mint() external payable {
        require(nextId + 1 <= MAX, "Exceeds supply");
        nextId += 1;
        _safeMint(msg.sender, nextId);
        counter += 1;
    }

    function crossChain(
        uint16 _dstChainId,
        bytes calldata _destination,
        uint256 tokenId
    ) public payable {
        require(msg.sender == ownerOf(tokenId), "Not the owner");
        // burn NFT
        _burn(tokenId);
        counter -= 1;
        bytes memory payload = abi.encode(msg.sender, tokenId);
        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, gas);
        (uint256 messageFee, ) = endpoint.estimateFees(
            _dstChainId,
            address(this),
            payload,
            false,
            adapterParams
        );
        require(
            msg.value >= messageFee,
            "Must send enough value to cover messageFee"
        );
        endpoint.send{value: msg.value}(
            _dstChainId,
            _destination,
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams
        );
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _from,
        uint64,
        bytes memory _payload
    ) external override {
        require(msg.sender == address(endpoint));
        address from;
        assembly {
            from := mload(add(_from, 20))
        }
        (address toAddress, uint256 tokenId) = abi.decode(
            _payload,
            (address, uint256)
        );
        // mint the tokens
        _safeMint(toAddress, tokenId);
        counter += 1;
        emit ReceiveNFT(_srcChainId, toAddress, tokenId, counter);
    }

    // Endpoint.sol estimateFees() returns the fees for the message
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        return
            endpoint.estimateFees(
                _dstChainId,
                _userApplication,
                _payload,
                _payInZRO,
                _adapterParams
            );
    }
}