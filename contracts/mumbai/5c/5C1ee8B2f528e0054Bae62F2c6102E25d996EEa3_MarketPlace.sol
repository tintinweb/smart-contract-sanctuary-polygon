// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./paymentSplitter.sol";


contract MarketPlace is ERC2771Context, ERC721Holder, ERC165, Ownable{
 
    error zeroAddressNotSupported();
    error notPermittedToEndTheAuction();
    error pleaseCollectTheNFT();
    error tokenAlreadyExist();
    error tokenNotSupported();
    error nftAddressNotSupported();
    error amountMismatchingTxReverted();

    address public contractOwner;
    string private contracturi; 
    address public trustedForwarder;

    // ARRAY
    address[] public tokenContractAddress;
    address[] public nftContractAddress;
    address public splitAddress;

    event NftAuctionListed(uint id);
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    event NftAuctionEnd(address winner, uint nftId);
    event AuctionReverted(address _lister, uint _nftId);
    event LandBought(address to, uint nftId, uint amount);
    event LandListed(address from, uint nftId);

    mapping(address => mapping(uint => bool)) private auctionStarted;
    mapping(address => mapping(uint => uint)) public allBiddedTokens;
    mapping(uint => mapping(address => bool)) private alreadyBidded;
    mapping(uint => address) private holdLandByLister;
    mapping(uint => address) private listedSeller;
    mapping(uint => uint) private nftEndDate;
    mapping(uint => address) private nftListerForAuction;
    mapping(uint => address) private highestBidder;
    mapping(uint => uint) private highestBid;
    mapping(uint => bool) private forceEndAuction;
    mapping(uint => uint) private nftValue;
    mapping(address => bool) public addressExist;
    mapping(address => bool) public nftAddressExist;
    mapping(address => bool) public paymentSplit;

    /**
        * constructor.
        * @param _trustedForwarder - Using Biconomy trusted forwarders. 
        * Forwarder for polygon mumbai : 0x69015912AA33720b842dCD6aC059Ed623F28d9f7, 
        * 0x9399BB24DBB5C4b782C70c2969F58716Ebbd6a3b, 0x5E7Cd3B22701b93D2972914eBF55EB98CB6D66dc 
    */
    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder){
        trustedForwarder = _trustedForwarder;
        contractOwner = _msgSender();
    }

    /**
        * OPTIONAL
        * You should add one setTrustedForwarder(address _trustedForwarder)
        * method with onlyOwner modifier so you can change the trusted
        * forwarder address to switch to some other meta transaction protocol
        * if any better protocol comes tomorrow or the current one is upgraded.
    */
    function setTrustedForwarder(address _newForwarder) external onlyOwner{
        trustedForwarder = _newForwarder;
    }

    function versionRecipient() external pure returns(string memory){
        return "1";
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool){
        return super.supportsInterface(interfaceId);
    }

    function _msgSender() internal view override(Context, ERC2771Context) returns(address){
        return ERC2771Context._msgSender();
    } 

    function _msgData() internal view override(Context, ERC2771Context) returns(bytes calldata){
        return ERC2771Context._msgData();
    }

    /**
        * whitelistToken. (For ERC20 based contract address reading)
        * Whitelist the token address, so that only tokensfrom the whitelist works.
        * @param _tokenContract Enter the token contract address to be logged to the smart contract.
    */
    function whitelistToken(address _tokenContract) external onlyOwner{
        if(_tokenContract == address(0)){ revert zeroAddressNotSupported();}
        if(addressExist[_tokenContract] == true){ revert tokenAlreadyExist();}
        addressExist[_tokenContract] = true;
        tokenContractAddress.push(_tokenContract);
    }

    /**
        * whitelistNftAddress. (For ERC721 based contract address reading)
        * Whitelist the token address, so that only tokensfrom the whitelist works.
        * @param _tokenContract Enter the token contract address to be logged to the smart contract.
    */
    function whitelistNftAddress(address _tokenContract) external onlyOwner{
        if(_tokenContract == address(0)){ revert zeroAddressNotSupported();}
        if(nftAddressExist[_tokenContract] == true){ revert tokenAlreadyExist();}
        nftAddressExist[_tokenContract] = true;
        nftContractAddress.push(_tokenContract);
    }

    /**
        *  whitelistPaymentSplitter
        * @param _paymentSplitterContract enter the payment splitter contract address.
    */
    function whitelistPaymentSplitter(address _paymentSplitterContract) external onlyOwner{
        if(_paymentSplitterContract == address(0)){ revert zeroAddressNotSupported();}
        if(paymentSplit[_paymentSplitterContract] == true){ revert tokenAlreadyExist();}
        paymentSplit[_paymentSplitterContract] = true;
        splitAddress = _paymentSplitterContract;
    } 

    /**
        * setContractURI
        * This is sepcifically for setting royalty.
        * @param _contractURI manually set the contract uri json or ipfs hash 
    */
    function setContractURI(string memory _contractURI) 
    external 
    onlyOwner 
    returns(bool)
    {
        contracturi = _contractURI;
        return true;
    } 

    function contractURI() public view returns (string memory) {
        return contracturi; 
    }

    /**
        * listNftForAuction
        * @param _nftAddress Enter the nft contract address.
        * @param _nftTokenid Enter the token id of the nft.
        * @param _endDate Enter the endDate for the auction.
        * @param _startingBid Enter the bidding price or starting price for the nft.
    */

    function listNftForAuction(address _nftAddress, uint _nftTokenid, uint _endDate, uint _startingBid ) 
    external
    {
        require(auctionStarted[_msgSender()][_nftTokenid] == false, "Auction for the nft is already started");    // This doesnt let the previous owner to re-list the same nft.
        require(IERC721(_nftAddress).ownerOf(_nftTokenid) == _msgSender(),"You are not the owner of NFT");
        if(nftAddressExist[_nftAddress] != true){ revert nftAddressNotSupported();}
        IERC721(_nftAddress).safeTransferFrom(_msgSender(), address(this), _nftTokenid);
        auctionStarted[_msgSender()][_nftTokenid] = true;
        if(block.timestamp > _endDate){
            auctionStarted[_msgSender()][_nftTokenid] == false;
        }
        nftEndDate[_nftTokenid] = block.timestamp + _endDate; // if days enter input as 7 days, if seconds enter input as 60.
        nftListerForAuction[_nftTokenid] = _msgSender();
        highestBid[_nftTokenid] = _startingBid;
        highestBidder[_nftTokenid] = _msgSender();
        listedSeller[_nftTokenid] = _msgSender();
        emit NftAuctionListed(_nftTokenid);
    }

    /**
        * endAuctionForceFully
        * @param _nftTokenid Enter the token id of the nft.
    */
    function endAuctionForceFully(uint _nftTokenid) 
    external
    {
        if(_msgSender() == nftListerForAuction[_nftTokenid]){
            forceEndAuction[_nftTokenid] = true;
        }else{
            revert notPermittedToEndTheAuction();
        }
    }

    /**
        * bid
        * @param _biddingAmount Enter the bidding price for the nft.
        * @param _nftTokenid Enter the token id of the nft.
        * @param _erc20TokenAddress Enter the erc20 token contract address, make sure its whitelisted.
    */
    function bid(uint _biddingAmount, uint _nftTokenid, address _erc20TokenAddress) 
    external 
    {
        require(forceEndAuction[_nftTokenid] == false,"The auction is stopped by the auction creator");
        require(block.timestamp < nftEndDate[_nftTokenid],"Auction for the NFT is ended");
        require(IERC20(_erc20TokenAddress).balanceOf(_msgSender()) >= _biddingAmount,"You don't have enough balance to buy the NFT");
        if(addressExist[_erc20TokenAddress] != true){ revert tokenNotSupported();}
        if(_biddingAmount > highestBid[_nftTokenid] && alreadyBidded[_nftTokenid][_msgSender()] == false){
            highestBidder[_nftTokenid] = _msgSender();
            highestBid[_nftTokenid] = _biddingAmount;
            alreadyBidded[_nftTokenid][_msgSender()] = true; 
            allBiddedTokens[_msgSender()][_nftTokenid] +=  highestBid[_nftTokenid];
            IERC20(_erc20TokenAddress).transferFrom(_msgSender(), address(this), allBiddedTokens[_msgSender()][_nftTokenid]);
            emit Bid(_msgSender(), _biddingAmount);
        }else{   
            uint deduct = _biddingAmount - allBiddedTokens[_msgSender()][_nftTokenid];
            uint add = allBiddedTokens[_msgSender()][_nftTokenid] + deduct;
            highestBid[_nftTokenid] = add;
            allBiddedTokens[_msgSender()][_nftTokenid] += deduct;
            highestBidder[_nftTokenid] = _msgSender();
            IERC20(_erc20TokenAddress).transferFrom(_msgSender(), address(this), deduct);
            emit Bid(_msgSender(), _biddingAmount);
        }
    }

    /**
        * withdrawRemainingTokens
        * @param _erc20TokenAddress Enter the erc20 token contract address, make sure its whitelisted.
        * @param _nftTokenid Enter the token id of the nft.
    */
    function withdrawRemainingTokens(address _erc20TokenAddress, uint _nftTokenid) 
    external
    {
        require(block.timestamp > nftEndDate[_nftTokenid] || forceEndAuction[_nftTokenid] == true, "Either Auction is not ended or Auction is already ended");
        if(addressExist[_erc20TokenAddress] != true){ revert tokenNotSupported();}
        if(_msgSender() == highestBidder[_nftTokenid]){
            revert pleaseCollectTheNFT();
        }
        uint bal = allBiddedTokens[_msgSender()][_nftTokenid];
        IERC20(_erc20TokenAddress).transfer(_msgSender(), bal);
        emit Withdraw(_msgSender(), bal);
    }

    /**
        * collectNftByHighestBidder
        * @param _nftAddress Enter the erc721 token contract address, make sure its whitelisted.
        * @param _erc20TokenAddress Enter the erc20 token contract address, make sure its whitelisted.
        * @param _nftTokenid Enter the nft id.
    */
   
    function collectNftByHighestBidder(address _nftAddress, uint _nftTokenid, address _erc20TokenAddress) 
    external
    {
        require(block.timestamp > nftEndDate[_nftTokenid] || forceEndAuction[_nftTokenid] == true, "Either Auction is not ended or Auction is already ended");
        if(nftAddressExist[_nftAddress] != true){ revert nftAddressNotSupported();}
        if(_msgSender() == highestBidder[_nftTokenid]){
            IERC721(_nftAddress).safeTransferFrom(address(this), highestBidder[_nftTokenid], _nftTokenid);
            // Deduct Royalty;
            paymentSplitter ps = paymentSplitter(splitAddress);
            uint count = ps.addressCount(_nftTokenid, _nftAddress);
            uint remainingBalance = highestBid[_nftTokenid];
            for(uint i = 0; i < count; i++){
                uint split = (highestBid[_nftTokenid] / 10000) * ps.returnRoyaltyTokens(_nftTokenid,_nftAddress,i);
                remainingBalance = remainingBalance - split;
                IERC20(_erc20TokenAddress).transfer(
                    ps.returnRoyaltyAddress(_nftTokenid,_nftAddress,i),
                    split);
            }
            IERC20(_erc20TokenAddress).transfer(
                listedSeller[_nftTokenid],
                remainingBalance);
            emit NftAuctionEnd(_msgSender(), _nftTokenid);
        }else{
            IERC721(_nftAddress).safeTransferFrom(
                address(this),
                listedSeller[_nftTokenid],
                _nftTokenid);
            emit AuctionReverted(listedSeller[_nftTokenid], _nftTokenid);
        }
    }

    /**
        * listLand
        * @param _nftAddress Enter the erc721 token contract address, make sure its whitelisted.
        * @param _nftTokenid Enter the nft id.
        * @param _amountForNFT Enter the amount for the Nft.
    */
    function listLand(address _nftAddress, uint _nftTokenid, uint _amountForNFT) 
    external 
    returns(bool submitted)
    {
        if(_nftAddress == address(0)){ revert zeroAddressNotSupported();}
        if(nftAddressExist[_nftAddress] != true){ revert nftAddressNotSupported();}
        require(IERC721(_nftAddress).ownerOf(_nftTokenid) == _msgSender(),"You are not the owner of NFT");
        holdLandByLister[_nftTokenid] = _msgSender();   // nft lister address holder.
        nftValue[_nftTokenid] = _amountForNFT;   // This is the nft value set for the token.
        IERC721(_nftAddress).safeTransferFrom(_msgSender(), address(this), _nftTokenid);
        emit LandListed(_msgSender(), _nftTokenid);
        return (submitted = true);
    }

    /**
        * BuyLand
        * @param _nftAddress Enter the erc721 token contract address, make sure its whitelisted.
        * @param _nftTokenid Enter the nft id.
        * @param _amountForNFT Enter the amount to buy the nft (erc20 token)
        * @param _erc20TokenAddress Enter the erc20 token contract address, make sure its whitelisted.
    */
    function buyLand(address _nftAddress, uint _nftTokenid, uint _amountForNFT, address _erc20TokenAddress) 
    external
    {
        if(_nftAddress == address(0)){ revert zeroAddressNotSupported();}
        if(addressExist[_erc20TokenAddress] != true){ revert tokenNotSupported();}
        require(IERC20(_erc20TokenAddress).balanceOf(_msgSender()) >= _amountForNFT,"You don't have enough balance to buy the NFT");
        if (_amountForNFT == nftValue[_nftTokenid]){
            IERC721(_nftAddress).safeTransferFrom(address(this), _msgSender(), _nftTokenid);
            // Deduct Royalty;
            paymentSplitter ps = paymentSplitter(splitAddress);
            uint count = ps.addressCount(_nftTokenid,_nftAddress);
            uint remainingBalance = _amountForNFT;
            for(uint i = 0; i < count; i++){
                uint split = (_amountForNFT / 10000) * ps.returnRoyaltyTokens(_nftTokenid,_nftAddress,i);
                remainingBalance = remainingBalance - split;
                IERC20(_erc20TokenAddress).transferFrom(
                    _msgSender(),
                    ps.returnRoyaltyAddress(_nftTokenid,_nftAddress,i),
                    split);
            }
            IERC20(_erc20TokenAddress).transferFrom(
                _msgSender(),
                holdLandByLister[_nftTokenid],
                remainingBalance);
            emit LandBought(_msgSender(), _nftTokenid, _amountForNFT);
        }else{
            revert amountMismatchingTxReverted();
        }
    }

    // struct returnSample{
    //     mapping(uint => address) allAd;
    //     mapping(uint => uint) allTok;
    // }
    // mapping(uint => mapping(address => returnSample)) private status;

    // function royaltyDetails(address _nftAddress, uint _nftTokenid, uint _tokenPrice, uint _i) 
    // external 
    // returns(address allAd,uint allTok)
    // {
    //     paymentSplitter ps = paymentSplitter(splitAddress);
    //         uint count = ps.addressCount(_nftTokenid,_nftAddress);
    //         uint remainingBalance = _tokenPrice;
    //         for(uint i = 0; i < count; i++){
    //             uint split = (_tokenPrice / 10000) * ps.returnRoyaltyTokens(_nftTokenid,_nftAddress,i);
    //             remainingBalance = remainingBalance - split;
    //             status[_nftTokenid][_nftAddress].allAd[i] = ps.returnRoyaltyAddress(_nftTokenid,_nftAddress,i);
    //             status[_nftTokenid][_nftAddress].allTok[i] = split;
    //         }
    //         return(status[_nftTokenid][_nftAddress].allAd[_i],status[_nftTokenid][_nftAddress].allTok[_i]);
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract paymentSplitter is Ownable{
  
    error zeroAddressNotSupported();
    error tokenAlreadyExist();
    error nftAddressNotSupported();
    error maxArraySizeReached();
    error notAdminAddress();
    error royaltyAlreadySetByAdmin();

    address[] public nftContractAddress;
    address[] public adminAddresses;
    uint public restrictedArraySize;

    mapping(uint => mapping(address => royaltyInfo[])) private royaltyOfAdmin;
    mapping(address => bool) private nftAddressExist;
    mapping(address => bool) private adminAddress;
    mapping(address => mapping(uint => bool)) private royaltyAlreadySet;
    mapping(uint => address[]) public allAddress;
    mapping(uint => mapping(address => uint)) public countRoyaltyAddresses;

    struct royaltyInfo{
        address royaltyReceiver;
        uint percentage;
    }

    constructor() {
        restrictedArraySize = 4;
    }

    /**
        * whitelistNftAddress. (For ERC721 based contract address reading)
        * Whitelist the token address, so that only tokensfrom the whitelist works.
        * @param _tokenContract Enter the token contract address to be logged to the smart contract.
    */
    function whitelistNftAddress(address _tokenContract) external onlyOwner{
        if(_tokenContract == address(0)){ revert zeroAddressNotSupported();}
        if(nftAddressExist[_tokenContract] == true){ revert tokenAlreadyExist();}
        nftAddressExist[_tokenContract] = true;
        nftContractAddress.push(_tokenContract);
    }

    /**
        * whitelistAdmin. 
        * @param _admin Enter the admin address to be logged to the smart contract.
    */
    function whitelistAdmin(address _admin) external onlyOwner{
        if(_admin == address(0)){ revert zeroAddressNotSupported();}
        if(adminAddress[_admin] == true){ revert tokenAlreadyExist();}
        adminAddress[_admin] = true;
        adminAddresses.push(_admin);
    }

    /**
        * setRoyaltyInfo
        * There is a maximum restriction for royalty receiver array size = 4.
        * @param _royalty This is a struct, where receiver address and token percentage is feeded.
        * @param _nftAddress Pass the nft smart contract address.
        * @param _nftTokenId pass the nft tokenid.
        * nftAddressExist - checks whether the nft address is already whitelisted.
        * adminAddress - only the admin of the contracts will access to setRoyaltyinfo
        * royaltyAlreadySet - If once royalty is set for the nft id, then again it cannot be set for same id.
        * countRoyaltyAddresses - This is usefull to get the address length
    */
    function setRoyaltyInfo(royaltyInfo[] memory _royalty, address _nftAddress, uint _nftTokenId) external{
        if(_nftAddress == address(0)){ revert zeroAddressNotSupported();}
        if(nftAddressExist[_nftAddress] != true){ revert nftAddressNotSupported();}
        if(adminAddress[msg.sender] != true){ revert notAdminAddress();}
        if(_royalty.length > restrictedArraySize){ revert maxArraySizeReached();}
        if(royaltyAlreadySet[_nftAddress][_nftTokenId] == true){ revert royaltyAlreadySetByAdmin();}
        royaltyAlreadySet[_nftAddress][_nftTokenId] = true;
        countRoyaltyAddresses[_nftTokenId][_nftAddress] = _royalty.length;
        for(uint i = 0; i < _royalty.length; i++){
            royaltyOfAdmin[_nftTokenId][_nftAddress].push(_royalty[i]);
        }
    }

    function returnRoyaltyAddress(uint _nftTokenId, address _nftAddress, uint i) external view returns(address){
        return royaltyOfAdmin[_nftTokenId][_nftAddress][i].royaltyReceiver;
    }

    function returnRoyaltyTokens(uint _nftTokenId, address _nftAddress, uint i) external view returns(uint){
        return royaltyOfAdmin[_nftTokenId][_nftAddress][i].percentage;
    }

    function maxArraySizeForRoyalty() external view returns(uint){
        return restrictedArraySize;
    }

    function royaltyInformation(uint _nftTokenId, address _nftAddress) external view returns(royaltyInfo[] memory){
        return  royaltyOfAdmin[_nftTokenId][_nftAddress];
    }

    function addressCount(uint _nftTokenId, address _nftAddress) external view returns(uint){
        return countRoyaltyAddresses[_nftTokenId][_nftAddress];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /**
        * constructor.
        * @param trustedForwarder - Using Biconomy trusted forwarders. 
        * Forwarder for polygon mumbai : 0x69015912AA33720b842dCD6aC059Ed623F28d9f7, 
        * 0x9399BB24DBB5C4b782C70c2969F58716Ebbd6a3b, 0x5E7Cd3B22701b93D2972914eBF55EB98CB6D66dc 
    */
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}