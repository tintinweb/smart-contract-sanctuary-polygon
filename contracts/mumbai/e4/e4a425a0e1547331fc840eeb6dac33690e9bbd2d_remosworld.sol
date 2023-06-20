// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./contract.sol";
import "./library.sol";

contract remosworld is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    address public treasuryWallet;
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public list_one;

    uint256 public contractState = 0;
    bool public revealed = false;

    mapping (address => uint) public whitelisted;
    mapping(address => uint) public minted;

    string public tokenName = "REMOS WOLRD";
    string public tokenSymbol = "REMO";
    uint256 public mintedNFT;
    uint256 public maxSupply = 500;
    uint256 public maxWalletAmount = 1;
    uint256 public priceNFT = 0.085 ether;
    string public hiddenMetadataUri = "ipfs://QmSmo5bYtZDKrQQdXwobAXwbBUVFUU9DE7AgxCuSUHiCLe.json";
    
    constructor() ERC721A(tokenName, tokenSymbol) {}

    modifier mintCompliance(uint256 _mintAmount) {
        require(contractState > 0, "Mint Disactivated!");
        require(_mintAmount > 0, "Invalid mint amount!");
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded");
        require(checkFaculty(_msgSender()) == true, "Wallet Disabilitated");
        uint256 _mintedAmountWallet = minted[_msgSender()] + _mintAmount;
        if(contractState < 3){
            require(_mintedAmountWallet <= maxWalletAmount, "Max quantity reached");}
        _;}

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= priceNFT * _mintAmount, "Insufficient Funds");
        _;}

    function setPrice(uint256 _price) public onlyOwner {
        //Ether cost
        priceNFT = _price;}

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) nonReentrant {
        minted[_msgSender()] = minted[_msgSender()] + _mintAmount;
        mintedNFT += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);}

    function burn(uint256 tokenId) public {
        _burn(tokenId, true); }

    function mintReserved(uint256 _mintAmount, address _receiver) public onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
        //Minted by Owner without any cost, doesn't count on minted quantity
        mintedNFT += _mintAmount;
        _safeMint(_receiver, _mintAmount);}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;}

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        if (revealed == false) {
            return hiddenMetadataUri;}
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)): '';}
    
    function setRevealed(bool _state) public onlyOwner {
        //Reveal the token URI of the NFTs
        revealed = _state;}

    function setMaxWalletAmount(uint256 _maxWalletAmount) public onlyOwner {
        maxWalletAmount = _maxWalletAmount;}

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;}

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;}

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;}

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;}

    function checkFaculty(address _addr) public view returns (bool) {
        bool _faculty = false;
        uint256 _phase = getPhase();
        uint256 _type = getType(_addr);
        if(_phase == 0) {
            _faculty = false;}
        else if(_phase == 1 && _type == 1) {
            _faculty = true;}
        else if(_phase == 2 && _type > 0){
            _faculty = true;}
        else if(_phase == 3 && _type >= 0){
            _faculty = true;}
        return _faculty;}

    function getMinted() public view returns (uint256, uint256) {
        uint256 _mintedNFT = mintedNFT;
        uint256 _totalSupply = maxSupply;
        return (_mintedNFT, _totalSupply);}
        
    function getType(address _addr) public view returns (uint256) {
        //[0] Non in lista
        //[1] voyager list
        //[2] fcfs list
        uint256 _type =  whitelisted[_addr];
        return _type;}
        
    function whitelist(address _addr, uint256 _type) public onlyOwner {
        require(whitelisted[_addr] == 0, "Account is already Whitlisted");
        whitelisted[_addr] = _type;}

    function changeList(address _addr, uint256 _type) public onlyOwner {
        whitelisted[_addr] = _type;}

    function whitelistBatch(uint256 _type, address[] memory _list) public onlyOwner { 
        for(uint i=0; i< _list.length; i++){  
            whitelisted[_list[i]] = _type;}}

    function getPhase() public view returns (uint256) {
        //[0] contratto non abilitato
        //[1] attivo voyager list
        //[2] attivo anche fcfs list
        //[3] attivo public sale
        uint256 _phase = contractState;
        return _phase;}
        
    function setPhase(uint256 _phase) public onlyOwner {
        contractState = _phase;}
        
    function removeWhitelisted(address _addr) external onlyOwner {
        require(whitelisted[_addr] > 0, "Account is already not in Whitelist");
        whitelisted[_addr] = 0;}

    receive() external payable {}

    fallback() external payable {}

    function setTreasury(address _to) public onlyOwner {
        treasuryWallet = _to;}

    function transferERC20(address _tokenAddr, address _to, uint _amount) public onlyOwner nonReentrant {  
        require(new_type_IERC20(_tokenAddr).transfer(_to, _amount), "Could not transfer out tokens!");}

    function transferERC20O(address _tokenAddr, address _to, uint _amount) public onlyOwner nonReentrant {    
        old_type_IERC20(_tokenAddr).transfer(_to, _amount);}
        
    function withdrawEther() public onlyOwner nonReentrant {
        (bool os, ) = payable(treasuryWallet).call{value: address(this).balance}('');
        require(os);}
    }