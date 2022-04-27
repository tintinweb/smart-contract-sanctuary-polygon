// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol"; 
import "./Mana.sol";

contract RAFFLE is ERC721Enumerable, Ownable {
    
    Mana public mana;
    IERC20 public weth;

    string public baseURI;

    uint256 public constant MAX_SUPPLY = 2000;
    uint256 public minted;

    uint256 public manaPrice = 100 ether;
    
    bool public paused = true;

    constructor(string memory _newBaseURI, address _mana) ERC721("RAFFLE", "RAFFLE") {
        baseURI = _newBaseURI;
        mana = Mana(_mana);
    }

    function buy(uint16 amount) external checkIfPaused{
        address tokenMinter = _msgSender();

        require(tx.origin == tokenMinter, "Contracts are not allowed to mint.");
        require(minted + amount <= MAX_SUPPLY, "All available NFT's have beem sold out.");
        require(amount > 0 && amount <= 10, "Maximum of 10 mints per transaction.");

        uint256 priceMana = amount * manaPrice;

        require(mana.allowance(tokenMinter, address(this)) >= priceMana && mana.balanceOf(tokenMinter) >= priceMana, "You need to send enough mana.");
        require(mana.transferFrom(tokenMinter, address(this), priceMana));
        
        mana.burn(address(this), priceMana);

        for (uint16 i; i < amount; i++) {
            minted++;
            _safeMint(tokenMinter, minted);
        }
    }

    function airdrop(address[] memory _wallets) external onlyOwner {
        for(uint256 i; i < _wallets.length; i++){
            minted++;
            _safeMint(_wallets[i], minted);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
	    string memory currentBaseURI = _baseURI();

	    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI,Strings.toString(tokenId),".json")) : "";
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory){
        uint256 tokensOwned = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokensOwned);
        for (uint256 i; i < tokensOwned; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function changeBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function togglePause() external onlyOwner{
        paused = !paused;
    }

    modifier checkIfPaused(){
        require(!paused,"Contract paused!");
        _;
    }
}