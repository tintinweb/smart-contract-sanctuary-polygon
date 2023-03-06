/**
 *Submitted for verification at polygonscan.com on 2023-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AnimatedApesProxy {
    address public animatedApes;

    constructor(address _animatedApes) {
        animatedApes = _animatedApes;
    }

    function mint(uint256 _mintAmount) external payable {
        bytes memory payload = abi.encodeWithSignature("mint(uint256)", _mintAmount);
        (bool success, ) = animatedApes.call{value: msg.value}(payload);
        require(success, "AnimatedApesProxy: call to AnimatedApes failed");
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) external {
        bytes memory payload = abi.encodeWithSignature("mintForAddress(uint256,address)", _mintAmount, _receiver);
        (bool success, ) = animatedApes.call(payload);
        require(success, "AnimatedApesProxy: call to AnimatedApes failed");
    }

    function setRevealed(bool _state) external {
        bytes memory payload = abi.encodeWithSignature("setRevealed(bool)", _state);
        (bool success, ) = animatedApes.call(payload);
        require(success, "AnimatedApesProxy: call to AnimatedApes failed");
    }

    function setCost(uint256 _cost) external {
        bytes memory payload = abi.encodeWithSignature("setCost(uint256)", _cost);
        (bool success, ) = animatedApes.call(payload);
        require(success, "AnimatedApesProxy: call to AnimatedApes failed");
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) external {
        bytes memory payload = abi.encodeWithSignature("setMaxMintAmountPerTx(uint256)", _maxMintAmountPerTx);
        (bool success, ) = animatedApes.call(payload);
        require(success, "AnimatedApesProxy: call to AnimatedApes failed");
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) external {
        bytes memory payload = abi.encodeWithSignature("setHiddenMetadataUri(string)", _hiddenMetadataUri);
        (bool success, ) = animatedApes.call(payload);
        require(success, "AnimatedApesProxy: call to AnimatedApes failed");
    }

    function setUriPrefix(string memory _uriPrefix) external {
        bytes memory payload = abi.encodeWithSignature("setUriPrefix(string)", _uriPrefix);
        (bool success, ) = animatedApes.call(payload);
        require(success, "AnimatedApesProxy: call to AnimatedApes failed");
    }

    function setUriSuffix(string memory _uriSuffix) external {
        bytes memory payload = abi.encodeWithSignature("setUriSuffix(string)", _uriSuffix);
        (bool success, ) = animatedApes.call(payload);
        require(success, "AnimatedApesProxy: call to AnimatedApes failed");
    }

    function setPaused(bool _state) external {
        bytes memory payload = abi.encodeWithSignature("setPaused(bool)", _state);
        (bool success, ) = animatedApes.call(payload);
        require(success, "AnimatedApesProxy: call to AnimatedApes failed");
    }

    function withdraw() external {
        (bool success, ) = animatedApes.call{value: address(this).balance}(abi.encodeWithSignature("withdraw()"));
        require(success, "AnimatedApesProxy: call to AnimatedApes failed");
    }

}