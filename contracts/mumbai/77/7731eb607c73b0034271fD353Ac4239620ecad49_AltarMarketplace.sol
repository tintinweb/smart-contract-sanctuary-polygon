// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC721.sol";
import "./Ownable.sol";

contract AltarMarketplace is ERC721, Ownable 
{

    event Fee(uint256 indexed tokenId, uint16 indexed fee);
    event Price(uint256 indexed tokenId, uint256 indexed price);

    struct TokenCreator 
    {
        address creator;
        uint256 fee;
    }

    uint16 public marketPlaceFee = 200;
    uint16 public maxFee = 3000;
    uint256 public tokenLimit = 1000000000;
    uint256 public tokenFixedPrice = 1000000000000000000;
    string public baseUrl = "https://m.cyborgs.pro:7791/nft/";
    mapping(uint256 => uint256) public stock;
    mapping(uint256 => TokenCreator) public tokenCreators;

    constructor() ERC721("AltarToken", "ALT") {}

    function mintToken(uint256 _tokenId, uint16 _fee) external payable 
    {
        require(!ERC721._exists(_tokenId), "Token exists");
        require(_tokenId > 0 && _tokenId <= tokenLimit, "Token limit");
        require(_fee <= maxFee, "Fees too height");
        uint256 token_price = tokenFixedPrice;
        if (stock[_tokenId] > 0) 
            token_price = stock[_tokenId];
        require(msg.value >= token_price, "Not enough ETH");
        ERC721._safeMint(msg.sender, _tokenId);
        tokenCreators[_tokenId] = TokenCreator(msg.sender, _fee);
        uint256 change = msg.value - token_price;
        if (change > 0) {
            address payable sender = payable(msg.sender);
            sender.transfer(change);
        }

        emit Fee(_tokenId, _fee);
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

    function mintTokens(uint256[] memory _tokens, uint16 _fee) external payable 
    {
        require(_tokens.length > 0, "Invalid token count");
        require(_fee <= maxFee, "Fees too height");
        uint256 total_price = 0;
        for (uint256 i = 0; i < _tokens.length; i++) 
        {
            uint256 token_idx = _tokens[i];
            if (token_idx > 0 && token_idx <= tokenLimit && !ERC721._exists(token_idx)) 
            {
                uint256 token_price = tokenFixedPrice;
                if (stock[token_idx] > 0)
                    token_price = stock[token_idx];
                total_price += token_price;
            } 
            else 
            {
                _tokens[i] = 0;
            }
        }

        require(total_price > 0, "No available token ids");

        require(msg.value >= total_price, "Not enough ETH");

        for (uint256 i = 0; i < _tokens.length; i++) 
        {
            uint256 token_idx = _tokens[i];
            if (token_idx > 0) 
            {
                ERC721._safeMint(msg.sender, token_idx);
                tokenCreators[token_idx] = TokenCreator(msg.sender, _fee);
                emit Fee(token_idx, _fee);
            }
        }
        uint256 change = msg.value - total_price;
        if (change > 0) 
        {
            address payable sender = payable(msg.sender);
            sender.transfer(change);
        }
    }

    function _afterTokenTransfer( address _from, address _to, uint256 _firstTokenId, uint256 _batchSize) internal override 
    {
        delete stock[_firstTokenId];
    }

    function setPrice(uint256 _tokenId, uint256 _price) external 
    {
        require(ERC721.ownerOf(_tokenId) == msg.sender, "You are not the owner");
        if (_price == 0) 
        {
            delete stock[_tokenId];
            emit Price(_tokenId, 0);
        }
        else
        { 
            stock[_tokenId] = _price;
            emit Price(_tokenId, _price);
        }
    }

    function setPriceRange( uint256 _from, uint256 _to, uint256 _price ) external onlyOwner 
    {
        require(_from <= _to, "Invalid range");
        if (_price == 0) 
        {
            for (uint256 token_i = _from; token_i <= _to; token_i++) 
            {
                if (!ERC721._exists(token_i)) 
                {
                    delete stock[token_i];
                    emit Price(token_i, 0);
                }
            }
        } 
        else 
        {
            for (uint256 token_i = _from; token_i <= _to; token_i++) 
            {
                if (!ERC721._exists(token_i))
                {
                    stock[token_i] = _price;
                    emit Price(token_i, _price);
                }
            }
        }
    }

    /* 1% = 100, 2.5% = 250, 100% = 10000 */
    function setMarketplaceFee(uint16 _fee) external onlyOwner 
    {
        require(_fee <= maxFee, "Fee is too high");
        marketPlaceFee = _fee;
    }

    function setMaxFee(uint16 _fee) external onlyOwner 
    {
        require( _fee * 2 <= 10000, "Fee is too high");
        maxFee = _fee;
    }

    function setCreatorTokenFee(uint256 _tokenId, uint16 _fee) external
    {
        require(tokenCreators[_tokenId].creator == msg.sender, "You are not the owner");
        require( _fee <= maxFee, "Fee is too high");
        tokenCreators[_tokenId].fee = _fee;
        emit Fee(_tokenId, _fee);
    }

    function setTokenLimit(uint256 _tokenLimit) external onlyOwner 
    {
        tokenLimit = _tokenLimit;
    }

    function setFixedPrice(uint256 _price) external onlyOwner 
    {
        require(_price > 0, "Fixed price is too low");
        tokenFixedPrice = _price;
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