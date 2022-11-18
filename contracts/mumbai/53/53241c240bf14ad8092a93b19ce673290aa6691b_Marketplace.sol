/**
 *Submitted for verification at polygonscan.com on 2022-11-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

//import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


interface IERC20Reward {
    function transfer(address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

interface IERC721 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function mint(address _to, uint256 _tokenId) external;
}

contract Marketplace {

    IERC20Reward immutable private rewardToken;
    IERC721 immutable private nft;
    address public admin;
    address wallet;
    enum Sale { presale, publicsale }
    Sale saleStatus;
    string saleStat;
    struct SaleInfo {
        uint256 price ;
        uint256 totalSupply;
        uint256 totalSupplied;
    }
    uint256 public constant TOTAL_NFT_SUPPLY = 48;
    SaleInfo preSale;
    SaleInfo publicSale;

    //merkle whitelisting
    bytes32 immutable private merkleRoot;
    mapping(address => bool) private claimed;

    constructor(address _rewardToken, address _nft, address _wallet) {

        //by default admin is owner
        wallet = _wallet;
        admin = msg.sender;
        rewardToken = IERC20Reward(_rewardToken);
        nft = IERC721(_nft);
        saleStatus = Sale.presale;
        saleStat = "presale";
        preSale.price = 50 * 10**8;
        preSale.totalSupply = 25;
        preSale.totalSupplied = 0;
        publicSale.price = 100 * 10**8;
        publicSale.totalSupply = 25;
        publicSale.totalSupplied = 0;
        merkleRoot = 0x09485889b804a49c9e383c7966a2c480ab28a13a8345c4ebe0886a7478c0b73d;
    }

    function switchPresale() private {
        require(msg.sender == admin, "Not Admin");
        saleStatus = Sale.presale;
        saleStat = "presale";
    }

    function switchPublicsale() private {
        require(msg.sender == admin, "Not Admin");
        saleStatus = Sale.publicsale;
        saleStat = "publicsale";
    }

    function getSaleStatus() public view returns (string  memory) {
        return saleStat;
    }

    function useRandomAvailableToken(uint256 _numToFetch, uint256 _i) public view returns (uint256 val){
        uint256 _numAvailableTokens = TOTAL_NFT_SUPPLY;
        uint256[TOTAL_NFT_SUPPLY] memory _availableTokens;
        uint256 randomNum = uint256(
            keccak256(
                abi.encode(msg.sender,tx.gasprice,block.number,block.timestamp,blockhash(block.number - 1),_numToFetch,_i
                )
            )
        );
        uint256 randomIndex = randomNum % _numAvailableTokens;
        uint256 valAtIndex = _availableTokens[randomIndex];
        uint256 result;
        if (valAtIndex == 0) {
            result = randomIndex;
        } else {
            result = valAtIndex;
        }
        uint256 lastIndex = _numAvailableTokens - 1;
        if (randomIndex != lastIndex) {
            uint256 lastValInArray = _availableTokens[lastIndex];
            if (lastValInArray == 0) {
                _availableTokens[randomIndex] = lastIndex;
            } else {
                _availableTokens[randomIndex] = lastValInArray;
            }
        }
        _numAvailableTokens--;
        return result + 1;
    }

    function mint(address _user, uint256 _mintAmount) public {
        require(nft.balanceOf(msg.sender) + _mintAmount <= 3, "Cannot mint more that 3 NFTs with normal rarities");
        if(saleStatus == Sale.presale) {
            require(preSale.totalSupplied < preSale.totalSupply, "Pre sale limit full");
            //(verifyWhitelisted(merkleProof) == true, "Address not whitelisted for presale");
            require(rewardToken.balanceOf(msg.sender) >= preSale.price, "Not enough reward tokens");
            //rewardToken.transferFrom(msg.sender, wallet, preSale.price);
        }
        else {
            require(publicSale.totalSupplied < publicSale.totalSupply, "public sale limit full");
            require(rewardToken.balanceOf(msg.sender) >= publicSale.price, "Not enough reward tokens");
            //rewardToken.transferFrom(msg.sender, wallet, publicSale.price);
        }
        for (uint8 i = 0; i < _mintAmount; i++) {
            uint256 tokenId = useRandomAvailableToken(_mintAmount, i);
            nft.mint(_user, tokenId);
        }
    }

    function mintDiamond(address _user) public {   
        require(nft.balanceOf(msg.sender) == 3, "Not eligible for Diamond");
        
        uint256 tokenId = useRandomAvailableToken(1, 1);
        nft.mint(_user, tokenId);
    }
}