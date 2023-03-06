/**
 *Submitted for verification at polygonscan.com on 2023-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAnimatedApes {
    function totalSupply() external view returns (uint256);
    function mint(uint256 _mintAmount) external payable;
    function setRevealed(bool _state) external;
    function setCost(uint256 _cost) external;
    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) external;
    function setHiddenMetadataUri(string memory _hiddenMetadataUri) external;
    function setUriPrefix(string memory _uriPrefix) external;
    function setUriSuffix(string memory _uriSuffix) external;
    function setPaused(bool _state) external;
}

contract AnimatedApesProxy {
    IAnimatedApes private immutable animatedApesContract;
    address private immutable owner;
    
    constructor(address _animatedApesContractAddress) {
        animatedApesContract = IAnimatedApes(_animatedApesContractAddress);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    function totalSupply() external view returns (uint256) {
        return animatedApesContract.totalSupply();
    }

    function mint(uint256 _mintAmount) external payable {
        animatedApesContract.mint{value: msg.value}(_mintAmount);
    }
    
    function setRevealed(bool _state) external onlyOwner {
        animatedApesContract.setRevealed(_state);
    }

    function setCost(uint256 _cost) external onlyOwner {
        animatedApesContract.setCost(_cost);
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) external onlyOwner {
        animatedApesContract.setMaxMintAmountPerTx(_maxMintAmountPerTx);
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) external onlyOwner {
        animatedApesContract.setHiddenMetadataUri(_hiddenMetadataUri);
    }

    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        animatedApesContract.setUriPrefix(_uriPrefix);
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        animatedApesContract.setUriSuffix(_uriSuffix);
    }

    function setPaused(bool _state) external onlyOwner {
        animatedApesContract.setPaused(_state);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        require(success, "Failed to withdraw balance from contract.");
    }
}