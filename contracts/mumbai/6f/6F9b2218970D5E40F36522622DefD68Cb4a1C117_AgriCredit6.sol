// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.0;
import "./ERC721.sol";
import "./FinControl.sol";
import "./StatusControl.sol";

contract AgriCredit6 is ERC721, FinControl, StatusControl {
    uint256 tokenCounter;
    mapping (uint256 => uint256) private tokenPrice;
    mapping (bytes32 => uint256) private guidToTokenId;
    mapping(uint256 => uint256) private tokenExchangeRates; 
    constructor(uint256 mp) ERC721("AgriCredit6", "VICC6") FinControl(mp){ 
        tokenCounter = 0;
    }
    function isTokenOwner(uint256 tokenId, address msgSender) external view returns (bool) {
        require(_exists(tokenId), "AgriCredit: this token does not exist");
        return msgSender == ERC721.ownerOf(tokenId);
    } 
    function getTokenId(bytes32 _guid) external view returns (uint256) {
        require(guidToTokenId[_guid] != uint256(0), "Viccredit: There is no claim therefore no tokenId.");
        return guidToTokenId[_guid];
    }
    function getSalePrice(uint256 tokenId) external view returns (uint256) {
        return tokenPrice[tokenId]; 
    }
    function getTokenExchangeRate(uint256 tokenId) external view returns (uint256) {
        return tokenExchangeRates[tokenId];
    }
    function mintCredit(bytes32 _guid, uint256 _price, uint256 _newExchangeRate, uint256 status) whenNotPaused allowedToMint public payable returns (uint256) {
        require(msg.value == (mintPrices[msg.sender] == 0 ? mintPrice : mintPrices[msg.sender]), "AgriCredit: Cost to mint credit must equal mint price for this wallet.");
        require(guidToTokenId[_guid] == uint256(0));
        return mintCreditInternal(_guid, _price, _newExchangeRate, msg.value, status);
    }
    function mintCreditInternal(bytes32 _guid, uint256 _price, uint256 _newExchangeRate, uint256 individualMsgValue, uint256 status) internal returns (uint256) {
        tokenCounter++;
        guidToTokenId[_guid] = tokenCounter;
        tokenPrice[tokenCounter] = _price;
        updateStatus(status, tokenCounter);
        _safeMint(msg.sender, tokenCounter);
        tokenExchangeRates[tokenCounter] = _newExchangeRate;
        financialOfficerAddress.transfer(individualMsgValue);
        return(tokenCounter);
    }
    function mintCredits(bytes32[] memory _guid, uint256 _price, uint256 _newExchangeRate, uint256 amount, uint256 status, address transferTo) whenNotPaused allowedToMint external payable returns (uint256[] memory) {
        require(amount > 0, "AgriCredit: Amount must be greater than zero.");
        require(msg.value == (mintPrices[msg.sender] == 0 ? mintPrice * amount : mintPrices[msg.sender] * amount), "AgriCredit: Cost to mint credit must equal mint price for this wallet.");
        uint256[] memory res = new uint256[](amount);
        uint256 individualMsgValue = msg.value / amount; // Calculate value to be used for each mint operation
        for (uint256 i = 0; i < amount; i++) {
            require(guidToTokenId[_guid[i]] == uint256(0));
        }
        for (uint256 i = 0; i < amount; i++) {
            res[i] = mintCreditInternal(_guid[i], _price, _newExchangeRate, individualMsgValue, status);
            if(msg.sender != transferTo){
                safeTransferFrom(msg.sender, transferTo, res[i]);
            }
        }
        return(res);
    }
    function purchaseCredits(uint256[] memory _tokenIds, uint256 _price, uint256 status) whenNotPaused external payable returns (uint256[] memory) {
        require(msg.value > 0, "AgriCredit: Purchase price cannot be zero. Use transfer for no cost ownership changes.");
        uint256 totalCost = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            totalCost += tokenPrice[_tokenIds[i]];
        }
        require(msg.value >= totalCost, "AgriCredit: Did not send enough currency to cover the total cost of the transaction.");
        uint256[] memory res = new uint256[](_tokenIds.length);
        uint256 cost = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            cost = tokenPrice[_tokenIds[i]];
            res[i] = purchaseCreditInternal(_tokenIds[i], _price, cost, status);
        }
        return(res);
    }
    function purchaseCreditInternal(uint256 tokenId, uint256 _price, uint256 cost, uint256 status) internal returns (uint256) {
        uint256 toContract = calculateTransferFee(cost);
        uint256 toOwner = cost - toContract;
        if(_exists(tokenId)){
            address payable owner = payable(ERC721.ownerOf(tokenId));
            if(owner != address(0) && isForSale(tokenId)){
                handleFees(toContract);
                owner.transfer(toOwner);
                approveInternal(_msgSender(), tokenId);
                transferFrom(owner, _msgSender(), tokenId);
                tokenPrice[tokenId] = _price;
                updateStatus(status, tokenId);
                emit SaleComplete(tokenId, toOwner, toContract);
                return tokenId;
            } else { return 0; }
        } else {
            return 0;
        }
    }
    function purchaseCredit(uint256 tokenId, uint256 _price, uint256 status) whenNotPaused external payable {
        require(msg.value > 0, "AgriCredit: Purchase price cannot be zero. Use transfer for no cost ownership changes.");
        require(isForSale(tokenId), "AgriCredit: Token is not for sale.");

        require(msg.value >= tokenPrice[tokenId], "AgriCredit: Amount offered must be >= price set by owner.");
        require((msg.value / 10000) * 10000 == msg.value, 'too small');
        purchaseCreditInternal(tokenId, _price, msg.value, status);
    }
    function burn(uint256 tokenId) whenNotPaused external payable {
        securityCheck(tokenId);
        require(msg.value == tokenPrice[tokenId], "AgriCredit: Must send value of token to burn request.");
        uint256 toContract = calculateTransferFee(msg.value);
        handleFees(toContract);
        burnStatus(tokenId);
        _burn(tokenId);
    }
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        if (balanceOf(_owner) == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](balanceOf(_owner));
            uint256 c = 0;
            for (uint256 i = 1; i <= totalSupply(); i++) {
                if(ownerOf(i) == _owner){
                    result[c] = i;
                    c++;
                }
            }
            return result;
        }
    }
    function securityCheck(uint256 tokenId) internal view {
        require(_exists(tokenId), "AgriCredit: this token does not exist");
        address owner = ERC721.ownerOf(tokenId);
        require(owner != address(0), "AgriCredit: This credit has been burned.");
        require(_msgSender() == owner || _msgSender() == executiveOfficerAddress, "ERC721: approve caller is not owner or CEO.");
    }
    function updateTokenInternal(uint256 tokenId, uint256 price, uint256 _newExchangeRate, uint256 status) internal returns (uint256) {
        securityCheck(tokenId);
        require(price >= 0, "AgriCredit: Price must be positive number.");
        tokenPrice[tokenId] = price;
        tokenExchangeRates[tokenId] = _newExchangeRate;
        updateStatus(status, tokenId);
        return tokenId;
    }
    function updateToken(uint256 tokenId, uint256 price, uint256 _newExchangeRate, uint256 status) external returns (uint256) {
        return updateTokenInternal(tokenId, price, _newExchangeRate, status);
    }
    function updateTokens(uint256[] memory _tokenIds, uint256 price, uint256 _newExchangeRate, uint256 status, bool erAdjust) whenNotPaused external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if(erAdjust){
                updatePriceWithNewExchangeRate(_tokenIds[i], _newExchangeRate);
            } else {
                updateTokenInternal(_tokenIds[i], price, _newExchangeRate, status);
            }
        }
    }
    function updatePriceWithNewExchangeRate(uint256 tokenId, uint256 _newExchangeRate) internal {
        securityCheck(tokenId);
        uint256 newPrice = (tokenPrice[tokenId] * tokenExchangeRates[tokenId]) / _newExchangeRate;
        tokenPrice[tokenId] = newPrice;
        tokenExchangeRates[tokenId] = _newExchangeRate;
    }
    event SaleComplete(uint256 tokenId, uint256 price, uint256 fee);
}