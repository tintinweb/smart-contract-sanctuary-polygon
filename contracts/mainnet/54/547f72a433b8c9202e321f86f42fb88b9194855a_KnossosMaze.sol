// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Metadata.sol";

contract KnossosMaze is ERC721Metadata {
    struct KnossosMazeData {
        uint256 tokenId;
        string tokekUri;
    }
    using Strings for uint256;
    using Strings for uint8;
    using SafeMath for uint256;
    uint256 maxgiveaway = 0;
    bool maxgiveawaystart = false;
    address payable private owned;
    uint32 _mintMaxAmount = 11;
    uint256 private price = 349999999999999999999;
    uint256 private ownerprice = 19999999999999999;
    uint256 private constant _initialSupply = 10100;
    bool private ownerMintNotUsed = true;
    constructor(string memory baseFileUrl)
        ERC721Metadata("KNOSSOS MAZE", "\xce\x9a\xce\x9d\xce\xa3")
    {
        owned = payable(msg.sender);
        _setBaseURI(baseFileUrl);
        pause();
    }

    //reserve tokens for the team members
    function getTeamTokens() public onlyOwner {
        uint256 _totalSupply = totalSupply() + 1;
        uint256 final_totalSupply = _totalSupply + 30;
        checkPriceWithValue(0, 30);
        for (uint256 i = _totalSupply; i < final_totalSupply; i++) {
            _mint(msg.sender, i);
        }
    }

    function getGiveAwayCurrentAmount() external view returns (uint256) {
        return maxgiveaway;
    }

    function getGiveAwayStatus() external view returns (bool) {
        return maxgiveawaystart;
    }
    function startGiveAway(uint256 _maxgiveaway) external onlyOwner {
        maxgiveawaystart = true;
        maxgiveaway = _maxgiveaway;
        emit GiveAwayStatus(maxgiveawaystart);
    }

    function stopGiveAway() external onlyOwner {
        maxgiveaway = 0;
        maxgiveawaystart = false;
        emit GiveAwayStatus(maxgiveawaystart);
    }

    function changeBaseURI(string memory newBaseURI) external onlyOwner {
        _setBaseURI(newBaseURI);
    }

    function changePrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
        emit PriceChange(price);
    }

    function getUserTokens() public view returns (KnossosMazeData[] memory) {
        KnossosMazeData[] memory _tokensOfOwner = new KnossosMazeData[](
            ERC721.balanceOf(_msgSender())
        );
        for (uint256 i = 0; i < ERC721.balanceOf(_msgSender()); i++) {
            uint256 _tokenId = ERC721Enumerable.tokenOfOwnerByIndex(
                _msgSender(),
                i
            );
            _tokensOfOwner[i] = KnossosMazeData(_tokenId, tokenURI(_tokenId));
        }
        return (_tokensOfOwner);
    }

    function mintGiveAway() public {
        require(maxgiveawaystart, "Give away is not started");
        require(
            !Address.isContract(msg.sender),
            "address cannot be a contract"
        );
        require(maxgiveaway > 0, "Give away is finished");
        maxgiveaway -= 1;
        uint256 _id = totalSupply().add(1);
        require(_id < initialSupply(), "Not any more tokens");
        _mint(_msgSender(), _id);
    }
    //used once for test
    function ownerMint() public payable onlyOwner {
        require(
            !Address.isContract(msg.sender),
            "Address cannot be a contract"
        );
        require(
           msg.value> ownerprice,
            "Insufficient funds"
        );
            require(
           ownerMintNotUsed,
            "Test method comleted"
        );
        
        
        uint256 currentsupply = totalSupply().add(1);
        require(currentsupply < initialSupply(), "Not any more tokens");
        uint256 _id = totalSupply().add(1);
        _mint(_msgSender(), _id);
        ownerMintNotUsed = false;
        (bool success,) = owned.call{value:msg.value}("");
        require(success, "Transaction failed");
        
    }

    //our application will provide the link of ipfs where is stored the thanasaki
    function mint(uint256 _mintAmount) public payable {
        require(_mintAmount < _mintMaxAmount, "You can mint a maximum of 10");
        require(
            !Address.isContract(msg.sender),
            "address cannot be a contract"
        );
        require(
            checkPriceWithValue(msg.value, _mintAmount),
            "Insufficient funds"
        );
        uint256 currentsupply = totalSupply().add(_mintAmount);
        require(currentsupply < initialSupply(), "Not any more tokens");
        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 _id = totalSupply().add(1);
            _mint(_msgSender(), _id);
        }
        (bool success,) = owned.call{value:msg.value}("");
        require(success, "Transaction failed");
    }

    function safeMint(uint256 _mintAmount) public payable {
        require(_mintAmount < _mintMaxAmount, "You can mint a maximum of 10");
        require(
            !Address.isContract(msg.sender),
            "Address cannot be a contract"
        );
        require(
            checkPriceWithValue(msg.value, _mintAmount),
            "Insufficient funds"
        );
        uint256 currentsupply = totalSupply().add(_mintAmount);
        require(currentsupply < initialSupply(), "Not any more tokens");
        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 _id = totalSupply().add(1);
            _safeMint(_msgSender(), _id);
        }
        (bool success,) = owned.call{value:msg.value}("");
        require(success, "Transaction failed");
    }

    function getphazeprice(uint8 phase) public view returns(uint256 p){
        if(phase ==1){
            p=price;
        }else if(phase ==2){
            p = getPhase2Price();
        }
        else if(phase ==3){
            p = getPhase3Price();
        }
        return p;
    }

    function checkPriceWithValue(uint256 val, uint256 amount)
        private
        returns (bool)
    {
        uint256 expected_value = 0;
        uint256 current_value = getcurrentPrice();
        uint256 _totalSupply = totalSupply();
        for (uint256 i = 0; i < amount; i++) {
            _totalSupply = _totalSupply.add(1);
            if (_totalSupply > 9000) {
                current_value = getPhase3Price();
                price = current_value;
                emit PriceChange(price);
            } else if (_totalSupply > 5000) {
                current_value = getPhase2Price();
                price = current_value;
                emit PriceChange(price);
            }
            expected_value = expected_value.add(current_value);
        }
        return val >= expected_value;
    }

    function getcurrentPrice() public view returns (uint256) {
        return price;
    }

    function initialSupply() public pure returns (uint256) {
        return _initialSupply;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function Destroy() external onlyOwner {
        selfdestruct(owned);
    }

    fallback() external payable {}

    receive() external payable {}

    function withdrawRemain() external onlyOwner {
        owned.transfer(address(this).balance);
    }
}