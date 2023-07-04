// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


import "./INFT.sol";
import "./ReentrancyGuard.sol";
import "./NERC721.sol";
import "./NERC1155.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";

contract Store is ReentrancyGuard,Ownable {

    using SafeMath for uint256;

    mapping(address => bool) public platformSupport;
    mapping(address => address) public nftOwner;
    mapping(address => bool) public platformContract;

    struct MintParams {
        address recipient;
        uint256 amount;
        string tokenUri;
    }

    struct Config {
        address feeWallet;
        uint deployAmount;
        uint mintAmount;
    }
    
    Config public config;

    event Deploy(address nft,address deployer,bool isPlatform,uint price);

    event MintRoute(uint uid,address nft,address recipient,uint256 tokenId,uint256 amount,string tokenUri,uint price);

    event Update(address feeWallet,uint deployAmount,uint mintAmount);

    event UpdateRoyalty(address nft,address author,uint96 royalty);

    // 接收ETH NFT
    receive() external payable {}

    fallback() external payable {}

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }


    function mint(
        uint uid,
        address nft,
        MintParams[] memory params
    ) public payable nonReentrant {
        require(nftOwner[nft] == msg.sender || platformContract[nft],"Store:: Access denied");

        require(msg.value == config.mintAmount.mul(params.length),"Store::Abnormal input amount");
        Address.sendValue(payable(config.feeWallet),msg.value);

        for (uint i = 0; i < params.length; i++) {
            uint tokenId = INFT(nft).mintAlone(
                params[i].recipient,
                params[i].amount,
                params[i].tokenUri
            );
            emit MintRoute(
                uid,
                nft,
                params[i].recipient,
                tokenId,
                params[i].amount,
                params[i].tokenUri,
                config.mintAmount
            );
        }
    }

    function updateConfig(
        address feeWallet,
        uint deployAmount,
        uint mintAmount
    ) public onlyOwner {
        config = Config({
            feeWallet:feeWallet,
            deployAmount:deployAmount,
            mintAmount:mintAmount
        });
        emit Update(feeWallet,deployAmount,mintAmount);
    }
    

    function deployPlatform(
        uint contractType,
        string memory name, 
        string memory symbol,
        address defaultAuthor,
        uint96 feeNumerator
    ) public onlyOwner {
        address nftContract = _deployContract(contractType,name,symbol);
        platformSupport[nftContract] = true;
        nftOwner[nftContract] = msg.sender;
        platformContract[nftContract] = true;

        _setDefaultRoyalty(nftContract,defaultAuthor,feeNumerator);
        emit Deploy(nftContract,msg.sender,true,config.deployAmount);
    }

    function deploy(
        uint contractType,
        string memory name, 
        string memory symbol,
        address defaultAuthor,
        uint96 feeNumerator
    ) public payable {
        require(msg.value == config.deployAmount,"Store::Abnormal input amount");
        Address.sendValue(payable(config.feeWallet),msg.value);

        address nftContract = _deployContract(contractType,name,symbol);
        platformSupport[nftContract] = true;
        nftOwner[nftContract] = msg.sender;

        _setDefaultRoyalty(nftContract,defaultAuthor,feeNumerator);
        emit Deploy(nftContract,msg.sender,false,config.deployAmount);
    }

    function setDefaultRoyalty(
        address nft,
        address defaultAuthor,
        uint96 feeNumerator
    ) public {
        require(nftOwner[nft] == msg.sender,"Store: caller is not the nft owner");
        _setDefaultRoyalty(nft,defaultAuthor,feeNumerator);
    }


    function _setDefaultRoyalty(
        address nft,
        address defaultAuthor,
        uint96 feeNumerator
    ) private {
        INFT(nft).setDefaultRoyalty(defaultAuthor,feeNumerator);
        emit UpdateRoyalty(nft,defaultAuthor,feeNumerator);
    }


    function _deployContract(
        uint contractType,
        string memory name, 
        string memory symbol
    ) private returns (address) {
        address nftContract;
        if(contractType == 721){
            nftContract = address(new NERC721(name,symbol,msg.sender,address(this)));
        }else if(contractType == 1155){
            nftContract = address(new NERC1155(name,symbol,msg.sender,address(this)));
        }else{
            revert("Store::I won't support it");
        }
        return nftContract;
    }
   
}