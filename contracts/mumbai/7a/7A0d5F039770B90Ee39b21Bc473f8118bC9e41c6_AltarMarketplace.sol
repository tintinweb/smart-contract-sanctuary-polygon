// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC721.sol";
import "./Ownable.sol";

contract AltarMarketplace is ERC721, Ownable 
{
    event Price(uint256 indexed tokenId, uint256 indexed price);

    struct TokenCreator 
    {
        address creator;
        uint256 fee;
    }

    uint16 public marketPlaceFee = 200;
    uint16 public maxFee = 3000;
    uint256 public minPayment = 1000000000;
    string public baseUrl = "https://m.cyborgs.pro:7791/nft/";
    mapping(uint256 => uint256) public stock;
    mapping(uint256 => TokenCreator) public tokenCreators;
    mapping(uint256 => uint256) public dbTokenId;

    uint token_index = 0;

    constructor() ERC721("AltarMarketplace", "ALTM") {}

    function mintToken(address _creator, uint16 _creator_fee, address _owner, uint256 _db_id) external payable onlyOwner returns (uint256) 
    {
        require(_creator_fee <= maxFee, "Fees too height");
        require(dbTokenId[_db_id] == 0, "DB nft already minted");

        if(msg.value > 0) // если создатель сам оплатил свой токен
            payable(_creator).transfer(msg.value); // переводим создателю его зароботок

        token_index++; // увеличиваем индекс токена
        ERC721._safeMint(_owner, token_index); // чеканим для новго владельца
        tokenCreators[token_index] = TokenCreator(_creator, _creator_fee); // сохраняем процент создателя
        dbTokenId[_db_id] = token_index;
        return token_index;
    }

    function buyToken(uint256 _tokenId) external payable 
    {
        require(ERC721._exists(_tokenId), "Token not minted");
        address payable token_owner = payable(ERC721.ownerOf(_tokenId));
        require(msg.sender != token_owner, "You already owner");
        uint price = stock[_tokenId];
        require(price > 0, "Token not sale");
        if (token_owner != owner())
            require(ERC721.isApprovedForAll(token_owner, owner()), "Operator not approved");

        require(msg.value >= price, "Not enough ETH");

        uint change = msg.value - price;
        if (change > 0) 
        {
            address payable sender = payable(msg.sender);
            sender.transfer(change);
        }

        uint seller_profit = price;
        uint marketplace_fee_value = (price / 10000) * marketPlaceFee;
        seller_profit -= marketplace_fee_value;
        TokenCreator memory token_creator  = tokenCreators[_tokenId];
        if (token_creator.fee > 0 && token_creator.creator != token_owner) 
        {
            uint256 cereator_fee_value = (price / 10000) * token_creator.fee;
            seller_profit -= cereator_fee_value;
            payable(token_creator.creator).transfer(cereator_fee_value);
        }

        if (seller_profit > 0) 
            token_owner.transfer(seller_profit);

        ERC721._transfer(token_owner, msg.sender, _tokenId);
    }

    function _afterTokenTransfer( address _from, address _to, uint256 _firstTokenId, uint256 _batchSize) internal override 
    {
        delete stock[_firstTokenId];
    }

    function setPrice(uint256 _tokenId, uint256 _price) external 
    {
        require(ERC721.ownerOf(_tokenId) == msg.sender, "You are not the owner");
        if (_price == 0) 
            delete stock[_tokenId];
        else
            stock[_tokenId] = _price;
      
        emit Price(_tokenId, _price);
    }

    /* 1% = 100, 2.5% = 250, 100% = 10000 */
    function setMarketplaceFee(uint16 _fee) external onlyOwner 
    {
        require(_fee <= maxFee, "Fee is too high");
        marketPlaceFee = _fee;
    }

    function setMinPayment(uint256 _min_payment) external onlyOwner 
    {
        minPayment = _min_payment;
    }

    function setMaxFee(uint16 _fee) external onlyOwner 
    {
        require( _fee * 2 <= 10000, "Fee is too high");
        maxFee = _fee;
    }

    function _baseURI() internal view virtual override returns (string memory) 
    {
        return baseUrl;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner 
    {
        baseUrl = _baseTokenURI;
    }

    function contractURI() public view returns (string memory) 
    {
        return string.concat(baseUrl, "contract.json");
    }

    function getBalance(address _address) public view returns (uint256) 
    {
        return _address.balance;
    }

    function withdraw(address payable _to) external onlyOwner 
    {
        _to.transfer(address(this).balance);
    }
}