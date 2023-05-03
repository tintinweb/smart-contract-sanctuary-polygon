// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.0;
import "./ERC721.sol";
import "./AccessControl.sol";

contract AgriCredit is ERC721, AccessControl {
    uint256 tokenCounter;
    uint256[] public tokensForSale;
    uint256 private mintPrice;
    uint256 private transferFee; //150 = 1.5% fee
    uint256 private transferFeeSplit; //4-digit's, i.e., 8000 = 80% to the contract, 20% to the split
    address private walletToSplitTo;
    mapping (uint256 => uint8) public tokenStatus;
    mapping (uint256 => uint256) private tokenToPrice;
    mapping(address => uint256) private mintPrices;
    mapping(address => uint256) private transferFees;
    mapping(uint256 => uint256) private tokenExchangeRates; //32 digit number, 16 left of the decimal, 16 right of the decimal, i.e., 1 MATIC = 0.94 USD then exchange rate is 000000000000000094000000000000000
    mapping(address => bool) private canMint; 

    constructor(uint256 mp) ERC721("AgriCredit", "VICC2") { 
        mintPrice = mp; //300000000000000; //0.0003 ether;
        transferFee = 150; //1.5%
        canMint[msg.sender] = true;
        transferFeeSplit = 0;
        walletToSplitTo = address(0);
        tokenCounter = 0;
    }

    function isTokenOwner(uint256 tokenId, address msgSender) external view returns (bool) {
        return msgSender == ERC721.ownerOf(tokenId);
    } 

    function setTokenStatus(uint256 id, uint8 status) external {
        tokenStatus[id] = status;
        if(status > 99){
            tokensForSale.push(id);
        } else {
            delete tokensForSale[id];
        }
    }
    function getSalePrice(uint256 tokenId) external view returns (uint256) {
        return tokenToPrice[tokenId];
    }
    function mintCredit(uint256 _price, uint256 _newExchangeRate) whenNotPaused public payable returns (uint256) {
        require(canMint[msg.sender], "AgriCredit: This wallet address does not have permission to mint.");
        require(msg.value == (mintPrices[msg.sender] == 0 ? mintPrice : mintPrices[msg.sender]), "AgriCredit: Cost to mint credit must equal mint price for this wallet.");
        tokenCounter++;
        tokenToPrice[tokenCounter] = _price;
        tokenStatus[tokenCounter] = 0;
        _safeMint(msg.sender, tokenCounter);
        tokenExchangeRates[tokenCounter] = _newExchangeRate;
        financialOfficerAddress.transfer(msg.value);
        return(tokenCounter);
    }
    function mintCreditInternal(uint256 _price, uint256 _newExchangeRate, uint256 individualMsgValue) internal returns (uint256) {
        tokenCounter++;
        tokenToPrice[tokenCounter] = _price;
        tokenStatus[tokenCounter] = 0;
        _safeMint(msg.sender, tokenCounter);
        tokenExchangeRates[tokenCounter] = _newExchangeRate;
        financialOfficerAddress.transfer(individualMsgValue);
        return(tokenCounter);
    }
    function mintCredits(uint256 _price, uint256 _newExchangeRate, uint256 amount) whenNotPaused external payable returns (uint256[] memory) {
        require(amount > 0, "AgriCredit: Amount must be greater than zero.");
        require(canMint[msg.sender], "AgriCredit: This wallet address does not have permission to mint.");
        require(msg.value == (mintPrices[msg.sender] == 0 ? mintPrice * amount : mintPrices[msg.sender] * amount), "AgriCredit: Cost to mint credit must equal mint price for this wallet.");
        uint256[] memory res = new uint256[](amount);
        uint256 individualMsgValue = msg.value / amount; // Calculate value to be used for each mint operation
        for (uint256 i = 0; i < amount; i++) {
            res[i] = mintCreditInternal(_price, _newExchangeRate, individualMsgValue);
        }
        return(res);
    }
    function purchaseCredit(uint256 tokenId, uint256 _price) whenNotPaused external payable {
        require(msg.value > 0, "AgriCredit: Purchase price cannot be zero. Use transfer for no cost ownership changes.");
        require(tokenStatus[tokenId] > 99, "AgriCredit: Token is not for sale.");

        require(msg.value >= tokenToPrice[tokenId], "AgriCredit: Amount offered must be >= price set by owner.");
        require((msg.value / 10000) * 10000 == msg.value, 'too small');
        uint256 toContract = msg.value * (transferFees[msg.sender] > 0 ? transferFees[msg.sender] : transferFee) / 10000;
        uint256 toOwner = msg.value - toContract;

        address payable owner = payable(ERC721.ownerOf(tokenId));
        require(owner != address(0), "AgriCredit: This credit has been burned.");
        handleFees(toContract);
        owner.transfer(toOwner);
        approveInternal(msg.sender, tokenId);
        transferFrom(owner, msg.sender, tokenId);
        tokenToPrice[tokenId] = _price;
        tokenStatus[tokenId] = 0;
        emit SaleComplete(tokenId, toOwner, toContract);
    }
    function sellCredit(uint256 tokenId, uint256 _newPrice, address _purchaser) whenNotPaused external payable {
        require(msg.value > 0, "AgriCredit: Sale price cannot be zero. Use transfer for no cost ownership changes.");
        
        address checkowner = ERC721.ownerOf(tokenId);
        require(_msgSender() == checkowner || _msgSender() == executiveOfficerAddress, "ERC721: Seller is not owner or CEO.");
        require(checkowner != address(0), "AgriCredit: This credit has been burned.");

        require((msg.value / 10000) * 10000 == msg.value, 'AgriCredit: Sale price is too small.');
        uint256 toContract = msg.value * (transferFees[_purchaser] > 0 ? transferFees[_purchaser] : transferFee) / 10000;
        uint256 toOwner = msg.value - toContract;

        address payable owner = payable(ERC721.ownerOf(tokenId));
        owner.transfer(toOwner);
        handleFees(toContract);
        approveInternal(checkowner, tokenId);
        transferFrom(owner, _purchaser, tokenId);
        tokenToPrice[tokenId] = _newPrice;
        emit SaleComplete(tokenId, toOwner, toContract);
    }
    function handleFees(uint256 feeToOwners) internal {
        if(walletToSplitTo != address(0) && transferFeeSplit > 0){
            uint256 toContract = feeToOwners * transferFeeSplit / 10000;
            payable(walletToSplitTo).transfer(feeToOwners - toContract);
            payable(financialOfficerAddress).transfer(toContract);
        } else {
            payable(financialOfficerAddress).transfer(feeToOwners);
        }
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
    function setSplitValues(address _wallet, uint256 fee) external onlyExecutiveOfficer {
        walletToSplitTo = _wallet;
        transferFeeSplit = fee;
    }
    function addToCanMint(address _wallet) external onlyExecutiveOfficer {
        canMint[_wallet] = true;
    }
    function removeFromCanMint(address _wallet) external onlyExecutiveOfficer {
        delete canMint[_wallet];
    }
    function setTransferFee(uint amount) external onlyExecutiveOfficer {
        transferFee = amount;
    }
    function setMintPrice(uint256 amount) external onlyExecutiveOfficer {
        mintPrice = amount;
    }
    function setWalletSpecificMintPrice(address _wallet, uint256 _price) external onlyExecutiveOfficer {
        mintPrices[_wallet] = _price;
    }
    function setWalletSpecificTransferFee(address _wallet, uint256 _fee) external onlyExecutiveOfficer {
        transferFees[_wallet] = _fee;
    }
    function setNewSalePrice(uint256 tokenId, uint256 price) external {
        securityCheck(tokenId);
        require(price >= 0, "AgriCredit: Price must be positive number.");
        tokenToPrice[tokenId] = price;
        approveInternal(financialOfficerAddress, tokenId);
    }
    function increaseSalePriceByPercent(uint256 tokenId, uint256 percentage) external {
        securityCheck(tokenId);
        uint256 salePrice = tokenToPrice[tokenId];
        uint256 increaseAmount = (salePrice * percentage) / 10000;
        tokenToPrice[tokenId] = salePrice + increaseAmount;
    }
    function securityCheck(uint256 tokenId) internal view {
        address owner = ERC721.ownerOf(tokenId);
        require(owner != address(0), "AgriCredit: This credit has been burned.");
        require(_msgSender() == owner || _msgSender() == executiveOfficerAddress, "ERC721: approve caller is not owner or CEO.");
    }
    function setNewSalePriceAndExchangeRate(uint256 tokenId, uint256 price, uint256 _newExchangeRate) external {
        securityCheck(tokenId);
        require(price >= 0, "AgriCredit: Price must be positive number.");
        tokenToPrice[tokenId] = price;
        require(tokenToPrice[tokenId] == price, "AgriCredit: Price must be properly set.");
        tokenExchangeRates[tokenId] = _newExchangeRate;
    }
    function updatePriceWithNewExchangeRate(uint256 tokenId, uint256 _newExchangeRate) internal {
        uint256 newPrice = (tokenToPrice[tokenId] * tokenExchangeRates[tokenId]) / _newExchangeRate;
        tokenToPrice[tokenId] = newPrice;
        tokenExchangeRates[tokenId] = _newExchangeRate;
    }
    function updateSalePrices(uint256 _newExchangeRate) external onlyExecutiveOfficer {
        for (uint256 i = 1; i <= totalSupply(); i++) {
            if(ERC721.ownerOf(i) != address(0)) {
                updatePriceWithNewExchangeRate(i, _newExchangeRate);
            }
        }
    }
    event SaleComplete(uint256 tokenId, uint256 price, uint256 fee);
}