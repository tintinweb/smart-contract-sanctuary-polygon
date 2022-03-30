/**
 *Submitted for verification at polygonscan.com on 2022-03-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC165 {

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
    */

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
*/

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
    */
    function royaltyFee(uint256 tokenId) external view returns(uint256);
    function getCreator(uint256 tokenId) external view returns(address);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */

    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function contractOwner() external view returns(address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function createCollectible( address from, string memory tokenURI) external returns (uint256);
    function enableMint() external returns(bool);

}

interface IERC1155 is IERC165 {

    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);
    

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function royaltyFee(uint256 tokenId) external view returns(uint256);
    function getCreator(uint256 tokenId) external view returns(address);
    function mint(address from, string memory uri, uint256 supply) external;
}
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
*/

interface IERC20 {

    /**
     * @dev Returns the amount of tokens in existence.
    */

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
    */

    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
    */

    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
    */

    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
    */

    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
    */ 

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract TransferProxy {

    function erc721safeTransferFrom(IERC721 token, address from, address to, uint256 tokenId) external  {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(IERC1155 token, address from, address to, uint256 id, uint256 value, bytes calldata data) external  {
        token.safeTransferFrom(from, to, id, value, data);
    }
    
    function erc20safeTransferFrom(IERC20 token, address from, address to, uint256 value) external  {
        require(token.transferFrom(from, to, value), "failure while transferring");
    }

    function erc721Mint(IERC721 token, address from, string memory tokenURI) external {
        token.createCollectible(from, tokenURI);
    }

    function erc1155Mint(IERC1155 token, address from, string memory tokenURI, uint256 supply) external {
        token.mint(from, tokenURI, supply);
    }

    function mintEnable(IERC721 token) external {
        token.enableMint();
    }
}

contract Trade {

    enum BuyingAssetType {ERC1155, ERC721}

    enum projectType { corn, cup, ember, elites, jokers, kernal}

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event SellerFee(uint8 sellerFee);

    event BuyerFee(uint8 buyerFee);

    event BuyAsset(address indexed assetOwner , uint256 indexed tokenId, uint256 quantity, address indexed buyer);

    event ExecuteBid(address indexed assetOwner , uint256 indexed tokenId, uint256 quantity, address indexed buyer);

    event MintersAdded(address indexed account);

    event MintersRemoved(address indexed account);

    event SignerChanged( address indexed signer, address indexed newSigner);

    event Paid(address indexed from, address indexed to, uint256 indexed value);

    event FeeUpdated(uint256[] fee);

    event FeeUpdatedForFourPackages(uint256); 

    event Assigned( address indexed from, address indexed , uint256[] indexed URIs);

    event AddedToWhiteList(address indexed from, bool value);

    event RemovedFromWhiteList(address indexed from, bool value);

    uint8 private buyerFeePermille;

    uint8 private sellerFeePermille;

    TransferProxy public transferProxy;

    address public owner;

    address public signer;

    uint256 private eAccess;

    mapping(uint256 => bool) private usedNonce;

    mapping(address => bool) private minters;

    uint256 public cornMintingFee = 0.01 * 10 ** 18;

    mapping(uint256 => uint256) public emberMintingFee;

    uint256 public cupMintingFee = 0.01 * 10 ** 18;

    uint256 public cupMintingFeeFor4Packages = 0.035 * 10 ** 18;

    mapping( address => bool) private isWhiteListedAddress;

    address[] private whiteListedAddresses;

    mapping(address => uint256) private mintedCount;
    mapping(address => bool) private assetHolder;

    struct Fee {
        uint platformFee;
        uint assetFee;
        uint royaltyFee;
        uint price;
        address tokenCreator;
    }

    /* An ECDSA signature. */
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    struct Order {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        BuyingAssetType nftType;
        uint unitPrice;
        uint amount;
        uint tokenId;
        uint256 supply;
        string tokenURI;
        uint256 fee;
        uint qty;
    }

    struct Assign {
        address from;
        address to;
        address nftAddress;
        projectType nftProjectType;
        BuyingAssetType nftAssetType;
        string tokenURI;
        uint256[] tokenIds;
        uint256 supply;
        bool getFees;  
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyMinters() {
        require(minters[msg.sender] == true, "Ownable: caller is not the minter");
        _;
    }

    modifier onlyHolders() {
        require(assetHolder[msg.sender] == true, "Ownable: caller is not the assetHolder");
        _;
    }


    constructor (uint8 _buyerFee, uint8 _sellerFee, TransferProxy _transferProxy) {
        buyerFeePermille = _buyerFee;
        sellerFeePermille = _sellerFee;
        transferProxy = _transferProxy;
        owner = msg.sender;
        signer = msg.sender;

        emberMintingFee[1] = 0.01 * 10 ** 18;
        emberMintingFee[2] = 0.02 * 10 ** 18;
        emberMintingFee[3] = 0.04 * 10 ** 18;
        emberMintingFee[4] = 0.035 * 10 ** 18;
    }

    function buyerServiceFee() external view virtual returns (uint8) {
        return buyerFeePermille;
    }

    function sellerServiceFee() external view virtual returns (uint8) {
        return sellerFeePermille;
    }

    function setBuyerServiceFee(uint8 _buyerFee) external onlyOwner returns(bool) {
        buyerFeePermille = _buyerFee;
        emit BuyerFee(buyerFeePermille);
        return true;
    }

    function setSellerServiceFee(uint8 _sellerFee) external onlyOwner returns(bool) {
        sellerFeePermille = _sellerFee;
        emit SellerFee(sellerFeePermille);
        return true;
    }

    function transferOwnership(address newOwner) external onlyOwner returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function changeSigner(address newSigner) external onlyOwner returns(bool) {
        require(newSigner != address(0) && newSigner != signer, "Signer: new signer should not zero or previous signer");
        address previousSigner = signer;
        signer = newSigner;
        emit SignerChanged(previousSigner, signer);
        return true;
    }

    function getSigner(bytes32 hash, Sign memory sign) internal pure returns(address) {
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s);
    }

    function verifySellerSign(address seller, uint256 tokenId, uint amount, address paymentAssetAddress, address assetAddress, Sign memory sign) internal pure {
        bytes32 hash = keccak256(abi.encodePacked(assetAddress, tokenId, paymentAssetAddress, amount, sign.nonce));
        require(seller == getSigner(hash, sign), "seller sign verification failed");
    }

    function verifyBuyerSign(address buyer, uint256 tokenId, uint amount, address paymentAssetAddress, address assetAddress, uint qty, Sign memory sign) internal pure {
        bytes32 hash = keccak256(abi.encodePacked(assetAddress, tokenId, paymentAssetAddress, amount, qty, sign.nonce));
        require(buyer == getSigner(hash, sign), "buyer sign verification failed");
    }

    function _encode(uint256[] memory data) internal pure returns(bytes memory) {
        bytes memory hash;
        hash = abi.encode(data);
        return hash;
    }

    function verifySign(uint256[] memory tokenIds, address caller, Sign memory sign) internal view {
        bytes memory URIhash = _encode(tokenIds);
        bytes32 hash = keccak256(abi.encodePacked(this, caller, URIhash, sign.nonce));
        require(signer == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s), "Owner sign verification failed");
    }

    function calculateFee(Assign memory assign) internal view returns(uint256) {
        uint256 fee = 0;
        if(assign.nftProjectType == projectType.corn) fee = ((assign.tokenIds).length) * cornMintingFee;

        if(assign.nftProjectType == projectType.ember) {
            fee = emberMintingFee[assign.tokenIds[0]];   
        }
        if(assign.nftProjectType == projectType.cup) {
            if((assign.tokenIds).length == 4) {
                fee =  cupMintingFeeFor4Packages;
            }
            if((assign.tokenIds).length == 6 ) {
                fee = ((assign.tokenIds).length - 1) * cupMintingFee;
            }
            if((assign.tokenIds).length != 6 && (assign.tokenIds).length != 4) {
                fee = (assign.tokenIds).length * cupMintingFee;
            }
        }
        return fee;
    }

    function transferFee(Assign memory assign) internal returns(bool) {
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

    function getFees( Order memory order) internal view returns(Fee memory){
        address tokenCreator;
        uint platformFee;
        uint royaltyFee;
        uint assetFee;
        uint royaltyPermille;
        uint price = order.amount * 1000 / (1000 + buyerFeePermille);
        uint buyerFee = order.amount - price;
        uint sellerFee = price * (sellerFeePermille / 1000);
        platformFee = buyerFee + sellerFee;
        if(order.nftType == BuyingAssetType.ERC721) {
            royaltyPermille = ((IERC721(order.nftAddress).royaltyFee(order.tokenId)));
            tokenCreator = ((IERC721(order.nftAddress).getCreator(order.tokenId)));
        }
        if(order.nftType == BuyingAssetType.ERC1155)  {
            royaltyPermille = ((IERC1155(order.nftAddress).royaltyFee(order.tokenId)));
            tokenCreator = ((IERC1155(order.nftAddress).getCreator(order.tokenId)));
        }
        royaltyFee = price * (royaltyPermille / 1000);
        assetFee = price - (royaltyFee + sellerFee);
        return Fee(platformFee, assetFee, royaltyFee, price, tokenCreator);
    }

    function tradeAsset(Order memory order, Fee memory fee) internal virtual {
        if(order.nftType == BuyingAssetType.ERC721) {
            transferProxy.erc721safeTransferFrom(IERC721(order.nftAddress), order.seller, order.buyer, order.tokenId);
        }
        if(order.nftType == BuyingAssetType.ERC1155)  {
            transferProxy.erc1155safeTransferFrom(IERC1155(order.nftAddress), order.seller, order.buyer, order.tokenId, order.qty, ""); 
        }
        if(fee.platformFee > 0) {
            transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address), order.buyer, owner, fee.platformFee);
        }
        if(fee.royaltyFee > 0) {
            transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address), order.buyer, fee.tokenCreator, fee.royaltyFee);
        }
        transferProxy.erc20safeTransferFrom(IERC20(order.erc20Address), order.buyer, order.seller, fee.assetFee);
    }

    function buyAsset(Order memory order, Sign memory sign) external returns(bool) {
        require(!usedNonce[sign.nonce],"Nonce: Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(order);
        require((fee.price >= order.unitPrice * order.qty), "Paid invalid amount");
        verifySellerSign(order.seller, order.tokenId, order.unitPrice, order.erc20Address, order.nftAddress, sign);
        order.buyer = msg.sender;
        tradeAsset(order, fee);
        emit BuyAsset(order.seller , order.tokenId, order.qty, msg.sender);
        return true;
    }

    function executeBid(Order memory order, Sign memory sign) external returns(bool) {
        require(!usedNonce[sign.nonce],"Nonce: Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(order);
        require((fee.price >= order.unitPrice * order.qty), "Paid invalid amount");
        verifyBuyerSign(order.buyer, order.tokenId, order.amount, order.erc20Address, order.nftAddress, order.qty, sign);
        order.seller = msg.sender;
        tradeAsset(order, fee);
        emit ExecuteBid(msg.sender , order.tokenId, order.qty, order.buyer);
        return true;
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
            paid = transferFee(assign);
            require(paid, "assign: problem on Minting fee transfer");
        }
        if(assign.nftProjectType == projectType.corn) {
           _mint721(assign.nftAddress, assign.from, assign.tokenURI);
        }
        if(assign.nftProjectType == projectType.cup) {
            require(mintedCount[assign.to] + (assign.tokenIds).length <= 12 , "ERC721: reciever limit exceeds");
            mintedCount[assign.to] += (assign.tokenIds).length;
            tradeAsset(assign);
        }
        if(assign.nftProjectType == projectType.ember) {
            tradeAsset(assign);
        }
        emit Assigned(assign.from, assign.to, assign.tokenIds);
        
        usedNonce[sign.nonce] = true;
        return paid;
    }

    function lootTransfer(Assign memory assign, Sign memory sign) external returns(bool) {
        verifySign(assign.tokenIds, msg.sender, sign);
        if(assign.nftAssetType == BuyingAssetType.ERC721) {
            transferProxy.erc721safeTransferFrom(IERC721(assign.nftAddress), assign.from, assign.to, assign.tokenIds[0]);         
        }
        if(assign.nftAssetType == BuyingAssetType.ERC1155) {
            transferProxy.erc1155safeTransferFrom(IERC1155(assign.nftAddress), assign.from, assign.to, assign.tokenIds[0], assign.supply, "");
        }
        return true;
    }

    function tradeAsset(Assign memory assign) internal {
        for(uint256 i = 0; i < (assign.tokenIds).length; i++) {
            if(assign.nftAssetType == BuyingAssetType.ERC1155) {
                transferProxy.erc1155safeTransferFrom(IERC1155(assign.nftAddress), assign.from, assign.to, assign.tokenIds[i], assign.supply, "");
            }
            if(assign.nftAssetType == BuyingAssetType.ERC721) {
                transferProxy.erc721safeTransferFrom(IERC721(assign.nftAddress), assign.from, assign.to, assign.tokenIds[i]);
            }
        }
    }

    function _mint721(address nftAddress, address from, string memory tokenURI) internal {
        transferProxy.erc721Mint(IERC721(nftAddress), from, tokenURI);
    }

    function enableMint(address nftAddress, projectType nftType) external onlyOwner returns(bool) {
        transferProxy.mintEnable(IERC721(nftAddress));
        if(nftType == projectType.corn) eAccess = block.timestamp + 60 minutes;
        return true;
    }

    function addToWhiteList(address[] memory whitelistaddresses) external onlyOwner returns(bool) {
        for( uint256 i = 0; i < whitelistaddresses.length; i++) {
            require(whitelistaddresses[i] != address(0), "WhiteList: address shouldn't be zero");
            require(isWhiteListedAddress[whitelistaddresses[i]], "WhiteList: address already added");
            isWhiteListedAddress[whitelistaddresses[i]] = true;
            emit AddedToWhiteList(whitelistaddresses[i], isWhiteListedAddress[whitelistaddresses[i]]);
        }
        return true;
    }

    function RemoveFromWhiteList(address[] memory whitelistaddresses) external onlyOwner returns(bool) {
        for( uint256 i = 0; i < whitelistaddresses.length; i++) {
            require(whitelistaddresses[i] != address(0), "WhiteList: address shouldn't be zero");
            require(!isWhiteListedAddress[whitelistaddresses[i]], "WhiteList: address already Removed");
            isWhiteListedAddress[whitelistaddresses[i]] = false;
            emit RemovedFromWhiteList(whitelistaddresses[i], isWhiteListedAddress[whitelistaddresses[i]]);
        }
        return true;
    }      

    function setMintingFee(projectType nftProjectType, uint256[] memory fee) external onlyOwner returns(bool) {
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

    function setCupMintingFourPackges(uint256 _mintingFee) external onlyOwner returns(bool){
        cupMintingFeeFor4Packages = _mintingFee;
        emit FeeUpdatedForFourPackages(_mintingFee);
        return true;
    }

    function mint721(address nftAddress, address to, string memory tokenURI) external onlyMinters returns(bool) {
        require(to != address(0),"reciever address is zero address");
        transferProxy.erc721Mint(IERC721(nftAddress), to, tokenURI);
        return true;
    } 

    function mint1155(address nftAddress, address to, string memory tokenURI, uint256 supply) external onlyMinters returns(bool) {
        require(to != address(0),"reciever address is zero address");
        transferProxy.erc1155Mint(IERC1155(nftAddress), to, tokenURI, supply);
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

    function assetTransfer(address to, address nftAddress, BuyingAssetType nftType, uint256 tokenId, uint256 supply) external onlyHolders returns(bool) {
        if(nftType == BuyingAssetType.ERC721) {
            transferProxy.erc721safeTransferFrom(IERC721(nftAddress), msg.sender, to, tokenId);
        }
        if(nftType == BuyingAssetType.ERC1155) {
            transferProxy.erc1155safeTransferFrom(IERC1155(nftAddress), msg.sender, to, tokenId, supply, ""); 
        }
        return true;
    }

    function setWalletAddress(address account) external onlyOwner returns(bool) {
        assetHolder[account] = true;
        return true;
    }

}