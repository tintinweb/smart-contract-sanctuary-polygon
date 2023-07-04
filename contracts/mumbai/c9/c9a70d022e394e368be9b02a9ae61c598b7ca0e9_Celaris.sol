// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./ERC721Royalty.sol";
import "./ERC721.sol";
import "./ERC2981.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./UpdatableOperatorFilterer.sol";
import "./EIP712.sol";


contract Celaris is  ERC721Royalty,  Ownable, ReentrancyGuard, UpdatableOperatorFilterer, EIP712 {

    address public minter;

    uint256 public totalSupply = 0;

    uint256 public maxSupply = 50;

    string public baseURI;

    string public collectionURI;

    address public treasure;

    address constant MYDEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    
    address constant MYOPERATOR_FILTER_REGISTRY = address(0x000000000000AAeB6D7670E522A718067333cd4E);

    mapping(uint256 => uint256) public redeemedTimestamp;

    uint256 redeemStartDate = 0;

    address redeemProxy;

    event BaseURIUpdated(string newURI);

    // ERC4906
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    constructor(address _treasure)
    ERC721("721 cel","CEL")
    EIP712("Cellaris","1")
    UpdatableOperatorFilterer(MYOPERATOR_FILTER_REGISTRY, MYDEFAULT_SUBSCRIPTION, true)
    {
      _setDefaultRoyalty(_treasure, 1000); // 10% fees
      treasure = _treasure;
    }

   function mints(address to,uint256[] memory tokenId) external {
        require(msg.sender == minter || msg.sender == owner(), "not allowed");
        require(totalSupply + tokenId.length <= maxSupply , "not allowed");
        for(uint256 i = 0 ; i < tokenId.length; i++){
            _safeMint(to, tokenId[i]);
            totalSupply = totalSupply + 1;
        }
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }

    function redeem(uint256 tokenId) public {
        require(block.timestamp > redeemStartDate,"Redeem is not open");
        require(ownerOf(tokenId) == msg.sender, "!owner");
        require(0 == redeemedTimestamp[tokenId], "!redeemed");
        redeemedTimestamp[tokenId] = block.timestamp;
    }

    function checkTransfersignature(uint256 tokenId, bytes memory signature) public view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(address(this), tokenId, block.chainid));
        bytes32 signedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(signedMessageHash, signature);
        return signer == ownerOf(tokenId);
    }

    function redeemGasLess(uint256 tokenId, bytes memory signature) public {
        require(block.timestamp > redeemStartDate,"Redeem is not open");
        require(redeemedTimestamp[tokenId] == 0, "Already redeemed");
        require(checkTransfersignature(tokenId, signature) == true, "Bad signature");
        redeemedTimestamp[tokenId] = block.timestamp;
    }

    

    function redeemByProxy(uint256 tokenId) public {
        require(block.timestamp > redeemStartDate,"Redeem is not open");
        require(redeemedTimestamp[tokenId] == 0, "Already redeemed");
        require(redeemProxy == msg.sender, "Not allowed");
        redeemedTimestamp[tokenId] = block.timestamp;
    }

/* test purpose, not use in production
    function transferGasLess(address from, address to, uint256 tokenId, bytes memory data, bytes memory signature) public virtual  {
        require(checkTransfersignature(tokenId, signature) == true, "Bad signature");
        _safeTransfer(from, to, tokenId, data);
    }
 */
    function _beforeTokenTransfer(
        address from,
        address to, 
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override( ERC721) {
        require(redeemedTimestamp[tokenId] == 0 ,   "Token is locked" );
        super._beforeTokenTransfer(from, to, tokenId,batchSize);
    }

    //METADATA URI BUILDER
    function tokenURI(uint256 tokenId) public view override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        // Concatenate the baseURI and the tokenId as the tokenId should
        // just be appended at the end to access the token metadata
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
        emit BaseURIUpdated(uri);
        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    function setContractURI(string memory uri) external onlyOwner {
        collectionURI = uri;
    }
    
    function contractURI() public view returns (string memory) {
      return string(abi.encodePacked(_baseURI(), "contract.json"));
    }

    function setMinter(address  _minter) external onlyOwner {
        minter = _minter;
    }

    function setMaxSupply(uint256  _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setRedeemStartDate(uint256  _redeemStartDate) external onlyOwner {
        redeemStartDate = _redeemStartDate;
    }

    function setRedeemProxy(address _redemmProxy) external onlyOwner {
        redeemProxy = _redemmProxy;
    }

    function setRoyalties(address _treasure, uint96 _amount) external onlyOwner {
        _setDefaultRoyalty(_treasure, _amount); 
    }

    function setOperatorFilter(address  register) external onlyOwner {
        updateOperatorFilterRegistryAddress(register);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Royalty) returns (bool) {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

    function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
            super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
   

}