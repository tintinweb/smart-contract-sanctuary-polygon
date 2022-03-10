/**
 *Submitted for verification at polygonscan.com on 2022-03-10
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC721 {
    function createCollectible( address from, string memory tokenURI) external returns (uint256);
    
    function enableMint() external returns(bool);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC1155 {

    function mint(address from, string memory uri, uint256 supply) external;

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

}


contract operator {
    
    event assigned( address indexed from, address indexed , uint256[] indexed URIs);

    event OwnershipTransfered( address indexed owner, address indexed newOwner);

    event SignerChanged( address indexed signer, address indexed newSigner);

    event Paid(address indexed from, address indexed to, uint256 indexed value);

    event AddedToWhiteList(address indexed from, bool value);

    event RemovedFromWhiteList(address indexed from, bool value);

    event MintersAdded(address indexed account);

    event MintersRemoved(address indexed account);

    mapping(address => bool) private minters;

    event FeeUpdated(uint256[] fee);

    uint256 public cornMintingFee;

    mapping(uint256 => uint256) public emberMintingFee;

    uint256 public cupMintingFee;

    address public owner;

    address public signer;

    uint256 private eAccess;

    mapping(uint256 => bool) private usedNonce;

    mapping( address => bool) private isWhiteListedAddress;

    mapping(address => uint256) private mintedCount;

    address[] private whiteListedAddresses;

    enum projectType {
        corn,
        cup,
        ember,
        elites,
        jokers,
        kernal
    }

    enum assetType { 
        ERC1155,
        ERC721
    }

    modifier onlyMinters() {
        require(minters[msg.sender] == true, "Ownable: caller is not the minter");
        _;
    }

    struct Assign {
        address from;
        address to;
        address nftAddress;
        projectType nftProjectType;
        assetType nftAssetType;
        string tokenURI;
        uint256[] tokenIds;
        uint256 supply;
        bool getFees;  
    }

    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    constructor() {

        owner = msg.sender;
        signer = msg.sender;
        cornMintingFee = 1 * 10**18;
        emberMintingFee[1] = 15 * 10 ** 18;
        emberMintingFee[2] = 20 * 10 ** 18;
        emberMintingFee[3] = 40 * 10 ** 18;
        emberMintingFee[4] = 350 * 10 ** 18;
        cupMintingFee = 100 * 10 ** 18;

    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner returns(bool) {
        require(newOwner != address(0) && newOwner != owner, "Signer: new signer should not zero or previous signer");
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransfered(previousOwner, owner);
        return true;
    }
    
    function _encode(uint256[] memory data) internal pure returns(bytes memory) {
        bytes memory hash;
        hash = abi.encode(data);
        return hash;
    }

    function verifySign(uint256[] memory tokenIds, address caller, Sign memory sign) public view returns(bytes32) {
        bytes memory URIhash = _encode(tokenIds);
        bytes32 hash = keccak256(abi.encodePacked(this, caller, URIhash, sign.nonce));
        require(signer == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s), "Owner sign verification failed");
        return hash;
    }

    function changeSigner(address newSigner) external onlyOwner returns(bool) {
        require(newSigner != address(0) && newSigner != signer, "Signer: new signer should not zero or previous signer");
        address previousSigner = signer;
        signer = newSigner;
        emit SignerChanged(previousSigner, signer);
        return true;
    }

    function calculateFee(Assign memory assign) public view returns(uint256) {
        uint256 fee;
        if(assign.nftProjectType == projectType.corn) fee = ((assign.tokenIds).length) * cornMintingFee;

        if(assign.nftProjectType == projectType.ember) {
            fee = emberMintingFee[assign.tokenIds[0]];   
        }
        if(assign.nftProjectType == projectType.cup) {
            (assign.tokenIds).length == 6 ? fee = ((assign.tokenIds).length - 1) * cupMintingFee 
                                          : fee = (assign.tokenIds).length * cupMintingFee;   
        }

        return fee;
    }

    function getFee(Assign memory assign) internal returns(bool) {
        uint256 assignfee = calculateFee(assign);
        bool isAllowed = false;
        require(msg.value >= assignfee, "assign: Minting value is invalid");
        if(assignfee < msg.value){
            if((payable(owner).send(assignfee))) isAllowed = true;
            emit Paid(msg.sender,owner,assignfee);
        } else {
            if((payable(owner).send(msg.value))) isAllowed = true;
            emit Paid(msg.sender,owner,msg.value);
        }
        return isAllowed;
    }

    function assignNFT(Assign memory assign, Sign memory sign) public payable returns(bool) {
        require(!usedNonce[sign.nonce],"Nonce : Invalid Nonce");
        require((assign.tokenIds).length <= 6,"Transfer: tokenIds length must be equals/less than to 6");
        require(assign.from != address(0) && assign.to != address(0), "Transfer: from address shouldn't be Zero");
        verifySign(assign.tokenIds, msg.sender, sign);

        if(assign.nftProjectType == projectType.corn && block.timestamp <= eAccess) {
            require(isWhiteListedAddress[msg.sender], "WhiteList: Caller doesn't have role to assign");
        }
        bool paid;
        if(assign.getFees) {
            paid = getFee(assign);
            require(paid, "assign: problem on Minting fee transfer");
        }
        if(assign.nftProjectType == projectType.corn) {
           _mint721(assign.nftAddress, assign.from, assign.tokenURI);
        }
        else if(assign.nftProjectType == projectType.cup) {
            require(mintedCount[assign.to] + 1 <= 6 , "ERC721: reciever limit exceeds");
            tradeAsset(assign);
            mintedCount[assign.to] += 1;
        }
        else if(assign.nftProjectType == projectType.ember) {
            tradeAsset(assign);
        }
        else if(assign.nftProjectType == projectType.elites) {
            tradeAsset(assign);
        }else if(assign.nftProjectType == projectType.jokers) {
            tradeAsset(assign);
        }
        else if(assign.nftProjectType == projectType.kernal) {
            tradeAsset(assign);
        }
        emit assigned(assign.from, assign.to, assign.tokenIds);
        
        usedNonce[sign.nonce] = true;
        return paid;
    } 

    function tradeAsset(Assign memory assign) public {
        for(uint256 i = 0; i < (assign.tokenIds).length; i++) {
            assign.nftAssetType == assetType.ERC1155 ?IERC1155(assign.nftAddress).safeTransferFrom(assign.from, assign.to, assign.tokenIds[i], assign.supply, "")
                                                     :IERC721(assign.nftAddress).safeTransferFrom(assign.from, assign.to, assign.tokenIds[i]);
        }
    }

    function _mint721(address nftAddress, address from, string memory tokenURI) internal {
        IERC721(nftAddress).createCollectible(from, tokenURI);
    }

    function enableMint(address nftAddress, projectType nftType) external onlyOwner returns(bool) {
        IERC721(nftAddress).enableMint();
        if(nftType == projectType.corn) eAccess = block.timestamp + 60 minutes;
        return true;
    }

    function addToWhiteList(address[] memory whitelistaddresses) public onlyOwner returns(bool) {
        for( uint256 i = 0; i < whitelistaddresses.length; i++) {
            require(whitelistaddresses[i] != address(0), "WhiteList: address shouldn't be zero");
            require(isWhiteListedAddress[whitelistaddresses[i]], "WhiteList: address already added");
            isWhiteListedAddress[whitelistaddresses[i]] = true;
            emit AddedToWhiteList(whitelistaddresses[i], isWhiteListedAddress[whitelistaddresses[i]]);
        }
        return true;
    }

    function RemoveFromWhiteList(address[] memory whitelistaddresses) public onlyOwner returns(bool) {
        for( uint256 i = 0; i < whitelistaddresses.length; i++) {
            require(whitelistaddresses[i] != address(0), "WhiteList: address shouldn't be zero");
            require(!isWhiteListedAddress[whitelistaddresses[i]], "WhiteList: address already Removed");
            isWhiteListedAddress[whitelistaddresses[i]] = false;
            emit RemovedFromWhiteList(whitelistaddresses[i], isWhiteListedAddress[whitelistaddresses[i]]);
        }
        return true;
    }      

    function setMintingFee(projectType nftProjectType, uint256[] memory fee) public returns(bool) {
        if(nftProjectType == projectType.corn) {
            cornMintingFee = fee[0];
        }
        else if(nftProjectType == projectType.cup) {
            cupMintingFee = fee[0];
        }
        else if(nftProjectType == projectType.ember) {
            for(uint i = 0; i < fee.length; i++) {
                emberMintingFee[i+1] = fee[i];
            }
        }
        emit FeeUpdated(fee);
        return true;
    }

    function mint721(address nftAddress, address to, string memory tokenURI) external onlyMinters returns(bool) {
        require(to != address(0),"reciever address is zero address");
        IERC721(nftAddress).createCollectible(to, tokenURI);
        return true;
    } 

    function mint1155(address nftAddress, address to, string memory tokenURI, uint256 supply) external onlyMinters returns(bool) {
        require(to != address(0),"reciever address is zero address");
        IERC1155(nftAddress).mint(to, tokenURI, supply);
        return true;
    }

    function addMinters(address account) external onlyOwner returns(bool) {
        require(address(0) != account, "reciever address is zero address");
        minters[account] = true;
        emit MintersAdded(account);
        return true;
    }

    function removeMinters(address account) external onlyOwner returns(bool) {
        require(address(0) != account, "reciever address is zero address");
        minters[account] = false;
        emit MintersRemoved(account);
        return true;
    }

}