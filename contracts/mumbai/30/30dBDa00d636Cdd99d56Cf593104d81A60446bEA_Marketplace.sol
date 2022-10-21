/**
 *Submitted for verification at polygonscan.com on 2022-10-20
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721Receiver.sol


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

// File: contracts/Marketplace.sol


pragma solidity 0.8.15;

//NEED THIS FOR THE MARKETPLACE
//import "OpenZeppelin/[email protected]/contracts/token/ERC721/IERC721Receiver.sol";


interface INft {
    function maxLimit() external view returns(uint256);
    function baseTokenUri() external view returns(string memory);
    function ownerAddress() external view returns(address);
    function minterAddress() external view returns(address);
    function version() external view returns(string memory);
    function supportsInterface(bytes4 interfaceId) external view returns(bool);
    function bulkMint(address recipient, address creator, uint96 royaltyFraction, uint256 numberOfNFTs, string memory _baseTokenURI) external payable;
    function bulkMintArray(address[] memory recipient, address[] memory creator, uint96[] memory royaltyFraction, string memory _baseTokenURI) external payable;
    function mintTo(address recipient, address creator, uint96 royaltyFraction, string memory uri) external payable;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function openSteganography(uint256 _tokenId) external;
    function transferOwnership(address _newOwner) external;
    function changeMinterAddress(address _newMinter) external;
    function numberOfTokens() external view returns(uint256);
    function ownerOf(uint256 tokenId) external view returns(address);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns(address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
    function setApprovalForAll(address operator, bool approved) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function balanceOf(address owner) external returns(uint256);
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns(address, uint256);
    function countsOpen(uint256) external returns(uint256);
    function isApprovedForAll(address owner, address operator) external returns(bool);
    function name() external returns(string memory);
    function symbol()external returns(string memory);
}

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }
    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}

contract Marketplace is Proxiable, IERC721Receiver{
    /// @notice address which can claim the service fees
    address public serviceFeeWallet;
    /// @notice address which represents the admin of this smart contract
    address public adminWallet;
    /// @notice setting the numerator for service fees
    uint256 public serviceFeeNum;
    /// @notice storing the service fees that only serviceFeeWallet can claim
    uint256 public collectServiceFee;
    /// @notice setting the name of this marketplace
    string public marketplaceName;
    /// @notice saving the nfts addresses that can be putted on the marketplace
    address[] public belongingNfts;
    /// @notice Using against re-entrancy
    uint16 public locked;
    //storing the number of nfts added to the marketplace
    uint256 public allNftsAdded;
    //storing the status if this contract was already initialized
    bool public initialized = false;

    /// @notice storing the token's asking price when putted on the marketplace
    /// @notice storing the status if the token is for sale
    /// @notice storing the status if the token was claimed by the highest bidder
    /// @notice storing the status if the token was auctioned 
    /// @notice storing when the token's auction ends 
    /// @notice storing the current highest bid for this token
    /// @notice storing the address of the current highest bidder
    /// @notice storing the previous amount of royalty
    /// @notice storing the previous amount of service fee
    /// @notice storing the previous amount of proceed
    struct ForSale{
        uint256 askingPrice;
        bool onSale;
        bool isClaimed;
        bool auctioned;
        uint256 auctionEndTime;
        uint256 currentBid;
        address highestBidder;
        uint256 previousRoyalty;
        uint256 previousServiceFee;
        uint256 previousProceed;
    }

    /// @notice storing the temporary royalties of the token for a specific nft address
    mapping(address => mapping(uint256 => uint256)) public tempRoyalties;

    /// @notice storing the temporary service fees of the token for a specific nft address
    mapping(address => mapping(uint256 => uint256)) public tempServiceFees;

    /// @notice storing the temporary proceeds of the token for a specific nft address
    mapping(address => mapping(uint256 => uint256)) public tempProceeds;

    /// @notice connecting nft's address and its tokenId
    mapping(address => mapping(uint256 => ForSale)) public nftForSale;

    /// @notice storing the seller's proceeds
    mapping(address => uint256) public collectProceeds;

    /// @notice storing the seller's royalties
    mapping(address => uint256) public collectRoyalties;

    /// @notice storing the amount that the outbidders can withdraw
    mapping(address => uint256) public balanceForWithdrawal;

    /// @notice checking that the caller is the owner of the specific token
    modifier OnlyNftOwner(address _nftAddress, uint256 _tokenId){
        require(INft(_nftAddress).ownerOf(_tokenId) == msg.sender); 
        _;
    }

    /// @notice check if only the admin has access
    modifier OnlyAdmin{
        require(msg.sender == adminWallet);
        _; 
    }

    /// @notice check if the address provided is inside the belongingNfts
    modifier OnlyBelongingNfts(address _nftAddress){
        bool isEq = false;
        for(uint256 i = 0; i < belongingNfts.length; i++){
            if(belongingNfts[i] == _nftAddress){
                isEq = true;
                break;
            }
        }
        require(isEq);
        _;
    }

    /// @notice Doesn't allow reentrance attack
    modifier noReentrant{
        require(locked == 1);
        locked = 2;
        _;
        locked = 1;
    }

    event ItemAdded(
        uint256 _askingPrice,
        bool _onSale,
        bool _isClaimed,
        bool _auctioned,
        uint256 _auctionEndTime,
        uint256 _currentBid,
        address _highestBidder,
        uint256 _previousRoyalty,
        uint256 _previousServiceFee,
        uint256 _previousProceed
    );

    event BidAdded(
        address _highestBidder,
        uint256 _bidAmount,
        address _nftAddress,
        uint256 _tokenId
    );

    /// sepravi admin lahko spremeni samo admina

    /// @notice due to UUPS Proxy we can't have constructor, so this function works as one
    //How to make sure that only we can call this? Hardcoded address?
    function initialize() external {
        require(!initialized, "Already initalized");
        //CHANGE IT BEFORE DEPLOYMENT
        serviceFeeWallet = 0xFCf74f23b85aD1a303a89c4C5459434379d39460;
        adminWallet = 0xFCf74f23b85aD1a303a89c4C5459434379d39460;
        serviceFeeNum = 1000;
        marketplaceName = "ArtRev Marketplace";
        initialized = true;
        //DON'T CHANGE THIS
        locked = 1;
    }

    /// @notice making sure that the contract can receive the nft
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @notice store the nft's collection address
    function addBelongingNft(address _nftAddress) external OnlyAdmin {
        belongingNfts.push(_nftAddress);
    }

    /// @notice setting the service fee
    function setServiceFee(uint256 _serviceFee) external OnlyAdmin {
        require(_serviceFee <= 10000);
        serviceFeeNum = _serviceFee;
    }

    /// @notice approve the marketplace for the token and put it for the auction 
    function putNftForSaleByAdmin(
        address _nftAddress, 
        uint256 _tokenFrom, 
        uint256 _tokenTo,   
        uint256 _askingPrice,
        uint256 _auctionTime
        ) 
        external OnlyAdmin() OnlyBelongingNfts(_nftAddress) {
            //put on auction
            if(_auctionTime != 0){
                for(uint256 i = _tokenFrom; i <= _tokenTo; i++){
                //send the token on sale
                putNFTForSale(_nftAddress, i, _askingPrice, _auctionTime, true);
                } 
            //put on sale for fixed price
            } else {
                for(uint256 i = _tokenFrom; i <= _tokenTo; i++){
                //send the token on sale
                putNFTForSale(_nftAddress, i, _askingPrice, 0, false);
                }
            }        
    }
   
    /// @notice approve the marketplace for the token and put it for the auction 
    function putNftForAuctionSale(
        address _nftAddress, 
        uint256 _tokenId,  
        uint256 _askingPrice,
        uint256 _auctionTime
        )
        external OnlyNftOwner(_nftAddress, _tokenId) OnlyBelongingNfts(_nftAddress) returns(bool) {
            //send the token on sale
            putNFTForSale(_nftAddress, _tokenId, _askingPrice, _auctionTime, true);
            return true;      
    }

    /// @notice approve the marketplace for the token and put it on sale for fixed price 
    function putNftForFixedPriceSale(
        address _nftAddress, 
        uint256 _tokenId,  
        uint256 _askingPrice
        ) 
        external OnlyNftOwner(_nftAddress, _tokenId) OnlyBelongingNfts(_nftAddress) returns(bool) {
            //send the token on sale
            putNFTForSale(_nftAddress, _tokenId, _askingPrice, 0, false);
            return true;    
    }
    
    /// @notice put the token for sale
    function putNFTForSale(
        address _nftAddress, 
        uint256 _tokenId, 
        uint256 _askingPrice,
        uint256 _auctionTime,
        bool _auctioned
        ) internal {

        //check if the token's owner is this address, the address has approval for this token or the owner of the token has apporved for all transaction this contract 
        require(INft(_nftAddress).ownerOf(_tokenId) == address(this) || INft(_nftAddress).getApproved(_tokenId) == address(this) ||INft(_nftAddress).isApprovedForAll(INft(_nftAddress).ownerOf(_tokenId), address(this)) == true);
        //check the requirements
        require(
            (nftForSale[_nftAddress][_tokenId].highestBidder != address(0) && block.timestamp >= nftForSale[_nftAddress][_tokenId].auctionEndTime + 2629743) || 
            (block.timestamp >= nftForSale[_nftAddress][_tokenId].auctionEndTime && nftForSale[_nftAddress][_tokenId].highestBidder != address(0) && nftForSale[_nftAddress][_tokenId].isClaimed == true) || 
            (block.timestamp >= nftForSale[_nftAddress][_tokenId].auctionEndTime && nftForSale[_nftAddress][_tokenId].highestBidder == address(0))
        );
        //initialize the struct
        ForSale storage newForSale = nftForSale[_nftAddress][_tokenId];
        newForSale.askingPrice = _askingPrice;
        newForSale.onSale = true;
        newForSale.isClaimed = false;
        newForSale.auctioned = _auctioned;
        if(_auctionTime == 0){
            newForSale.auctionEndTime = 0;
        } else {
            newForSale.auctionEndTime = block.timestamp + _auctionTime;
        }
        newForSale.currentBid = 0;
        newForSale.highestBidder = address(0);
        newForSale.previousRoyalty = 0;
        newForSale.previousServiceFee = 0;
        newForSale.previousProceed = 0;
        //initializing mappings to zero
        tempRoyalties[_nftAddress][_tokenId] = 0;
        tempServiceFees[_nftAddress][_tokenId] = 0;
        tempProceeds[_nftAddress][_tokenId] = 0;
        //increase the number of all nfts added to the marketplace
        allNftsAdded += 1;
        //emit the event
        emit ItemAdded( 
            newForSale.askingPrice, 
            newForSale.onSale, 
            newForSale.isClaimed, 
            newForSale.auctioned,  
            newForSale.auctionEndTime,  
            newForSale.currentBid, 
            newForSale.highestBidder, 
            newForSale.previousRoyalty, 
            newForSale.previousServiceFee, 
            newForSale.previousProceed
        );
    }

    /// @notice place the bids for the tokens in the auction
    function placeBid(address _nftAddress, uint256 _tokenId) external payable returns(bool){
        //check if the nft is on sale
        require(nftForSale[_nftAddress][_tokenId].onSale == true);
        //check if the nft is put on the auction and isn't selling for the fixed price
        require(nftForSale[_nftAddress][_tokenId].auctioned == true);
        //change the status to false, if the auction has ended
        if(nftForSale[_nftAddress][_tokenId].auctionEndTime <= block.timestamp){nftForSale[_nftAddress][_tokenId].onSale = false;}
        //check if the auction hasn't ended yet
        require(nftForSale[_nftAddress][_tokenId].auctionEndTime >= block.timestamp);
        //check if the bid equals or is higher than the asking price
        require(msg.value >= nftForSale[_nftAddress][_tokenId].askingPrice); 
        //check if the bid is higher than the current highest bid
        require(msg.value > nftForSale[_nftAddress][_tokenId].currentBid);
        //check if the caller is the owner of the token or the marketplace is either the owner or is approved 
        if(
            INft(_nftAddress).ownerOf(_tokenId) == address(this) || 
            INft(_nftAddress).getApproved(_tokenId) == address(this) ||
            INft(_nftAddress).isApprovedForAll(INft(_nftAddress).ownerOf(_tokenId), address(this)) == true
        ){
            uint256 royalty;
            uint256 serviceFee;
            uint256 proceed;
            //calculate the royalty
            (, royalty) = INft(_nftAddress).royaltyInfo(_tokenId, msg.value);
            //calculate the service fee
            serviceFee = msg.value * serviceFeeNum / 10000;
            //calculate the proceeds
            proceed = msg.value - royalty - serviceFee;
            //Increase the royalty amount stored in the struct
            tempRoyalties[_nftAddress][_tokenId] += royalty - nftForSale[_nftAddress][_tokenId].previousRoyalty;
            //set the previous royalty to the amount of royalty calculated right now
            nftForSale[_nftAddress][_tokenId].previousRoyalty = royalty;
            //increase the service fee amount in the struct
            tempServiceFees[_nftAddress][_tokenId] += serviceFee - nftForSale[_nftAddress][_tokenId].previousServiceFee;
            //set the previous service fee to the amount of service fee calculated right now
            nftForSale[_nftAddress][_tokenId].previousServiceFee = serviceFee;
            //increase the proceed amount in the struct
            tempProceeds[_nftAddress][_tokenId] += proceed - nftForSale[_nftAddress][_tokenId].previousProceed;
            //set the previous proceed to the amount of proceed calculated right now
            nftForSale[_nftAddress][_tokenId].previousProceed  = proceed;
            //enable outbidders to withdraw their funds
            balanceForWithdrawal[nftForSale[_nftAddress][_tokenId].highestBidder] = nftForSale[_nftAddress][_tokenId].currentBid;
            //set the current bid to the value sent
            nftForSale[_nftAddress][_tokenId].currentBid = msg.value;
            //set the highestBidder to the caller
            nftForSale[_nftAddress][_tokenId].highestBidder = msg.sender;
            //emit the event
            emit BidAdded(
                msg.sender,
                msg.value,
                _nftAddress,
                _tokenId
            );
            return true;
        //if the the caller isn't the owner of the token or the marketplace isn't either the owner or isn't approved , it has to revert
        } else {
            //token isn't for sale anymore
            nftForSale[_nftAddress][_tokenId].onSale = false;
            //highest bidder can withdraw the bid
            balanceForWithdrawal[nftForSale[_nftAddress][_tokenId].highestBidder] = nftForSale[_nftAddress][_tokenId].currentBid;
            //caller can withdraw their bid
            balanceForWithdrawal[msg.sender] = msg.value;
            return false;
        }
    }

    /// @notice enable the highest bidder to claim the nft
    function claimNft(address _nftAddress, uint256 _tokenId) external returns(bool){
        //check if the caller is the highest bidder and the auctionEnded
        require(msg.sender == nftForSale[_nftAddress][_tokenId].highestBidder && block.timestamp > nftForSale[_nftAddress][_tokenId].auctionEndTime && block.timestamp <= nftForSale[_nftAddress][_tokenId].auctionEndTime + 2629743);
        //check if the token hasn't been claimed yet
        require(nftForSale[_nftAddress][_tokenId].isClaimed == false);
        //check if the caller is the owner of the token or the marketplace is either the owner or is approved 
        if(
            INft(_nftAddress).ownerOf(_tokenId) == address(this) || 
            INft(_nftAddress).getApproved(_tokenId) == address(this) ||
            INft(_nftAddress).isApprovedForAll(INft(_nftAddress).ownerOf(_tokenId), address(this)) == true
        ){
            //store the royalty address
            address royaltyAddress;
            (royaltyAddress, ) = INft(_nftAddress).royaltyInfo(_tokenId, nftForSale[_nftAddress][_tokenId].currentBid);
            //transfer the token to the caller
            INft(_nftAddress).safeTransferFrom(INft(_nftAddress).ownerOf(_tokenId), msg.sender, _tokenId);
            //token isn't for sale anymore
            nftForSale[_nftAddress][_tokenId].onSale = false;
            //set isClaimed to true
            nftForSale[_nftAddress][_tokenId].isClaimed = true;
            //enable royalties to be claimed
            collectRoyalties[royaltyAddress] += tempRoyalties[_nftAddress][_tokenId];
            //enable proceeds to be claimed
            collectProceeds[INft(_nftAddress).ownerOf(_tokenId)] += tempProceeds[_nftAddress][_tokenId];
            //enabled service fees to be claimed
            collectServiceFee += tempServiceFees[_nftAddress][_tokenId];
            return true;
        //if the the caller isn't the owner of the token or the marketplace isn't either the owner or isn't approved , it has to revert
        } else {
            //token isn't for sale anymore
            nftForSale[_nftAddress][_tokenId].onSale = false;
            //change the status to claimed
            nftForSale[_nftAddress][_tokenId].isClaimed = true;
            //highest bidder can withdraw the bid
            balanceForWithdrawal[nftForSale[_nftAddress][_tokenId].highestBidder] = nftForSale[_nftAddress][_tokenId].currentBid;
            return false;
        } 
    }

    /// @notice enable users to withdraw the funds that belongs to them
    function withdrawOutbids() external payable noReentrant {
        //check if the caller funds are larger than zero
        require(balanceForWithdrawal[msg.sender] > 0);
        //send the funds
        (bool sent, ) = msg.sender.call{value: balanceForWithdrawal[msg.sender]}("");
        require(sent, "Failed to send Ether");
        //reduce the funds to zero
        balanceForWithdrawal[msg.sender] = 0;

    }

    /// @notice enable sellers to claim their proceeds
    function claimProceeds() external payable noReentrant {
        //check if the caller funds are larger than zero
        require(collectProceeds[msg.sender] > 0);
        //send the funds
        (bool sent, ) = msg.sender.call{value: collectProceeds[msg.sender]}("");
        require(sent, "Failed to send Ether");
        //reduce the funds to zero
        collectProceeds[msg.sender] = 0;
    }

    /// @notice enable admin to claim the service fees
    function claimServiceFee() external payable noReentrant {
        //only the address of service fees can withdraw the funds
        require(serviceFeeWallet == msg.sender);
        //check if the caller funds are larger than zero
        require(collectServiceFee > 0);
        //send the funds
        (bool sent, ) = msg.sender.call{value: collectServiceFee}("");
        require(sent, "Failed to send Ether");
        //reduce the funds to zero
        collectServiceFee = 0;
    }

    /// @notice enable users to claim their royalties
    function claimRoyalties() external payable noReentrant {
        //check if the caller funds are larger than zero
        require(collectRoyalties[msg.sender] > 0);
        //send the funds
        (bool sent, ) = msg.sender.call{value: collectRoyalties[msg.sender]}("");
        require(sent, "Failed to send Ether");
        //reduce the funds to zero
        collectRoyalties[msg.sender] = 0;
    }
   
    /// @notice buying the token which is selling for a fixed price
    function buyAtFixedPrice(
        address _nftAddress, 
        uint256 _tokenId
        ) external payable returns (bool) {
        //check if the buyer is sending the right amount 
        require (msg.value == nftForSale[_nftAddress][_tokenId].askingPrice);
        //check if the token is on sale
        require (nftForSale[_nftAddress][_tokenId].onSale == true);
        ///check if the caller is the owner of the token or the marketplace is either the owner or is approved 
        if(
            INft(_nftAddress).ownerOf(_tokenId) == address(this) || 
            INft(_nftAddress).getApproved(_tokenId) == address(this) ||
            INft(_nftAddress).isApprovedForAll(INft(_nftAddress).ownerOf(_tokenId), address(this)) == true 
        ){
            uint256 royalty;
            uint256 serviceFee;
            uint256 proceed;
            //calculate the royalty
            (, royalty) = INft(_nftAddress).royaltyInfo(_tokenId, msg.value);
            //calculate the service fee
            serviceFee = msg.value * serviceFeeNum / 10000;
            //calculate the proceeds
            proceed = msg.value - royalty - serviceFee;
            //Increase the royalty amount stored in the struct
            tempRoyalties[_nftAddress][_tokenId] += royalty;
            //increase the service fee amount in the struct
            tempServiceFees[_nftAddress][_tokenId] += serviceFee;
            //increase the proceed amount in the struct
            tempProceeds[_nftAddress][_tokenId] += proceed;
            //set the token's highest bidder to msg.sender
            nftForSale[_nftAddress][_tokenId].highestBidder = msg.sender;
            //set the current bid to the amount sent
            nftForSale[_nftAddress][_tokenId].currentBid = msg.value;
            //the token isn't for sale anymore
            nftForSale[_nftAddress][_tokenId].onSale = false;
            //save the date of sold token
            nftForSale[_nftAddress][_tokenId].auctionEndTime = block.timestamp;
            //emit the event
            emit BidAdded(
                msg.sender,
                msg.value,
                _nftAddress,
                _tokenId
            );
            return true;
        //if the the caller isn't the owner of the token or the marketplace isn't either the owner or isn't approved , it has to revert
        } else {
            //token isn't for sale anymore
            nftForSale[_nftAddress][_tokenId].onSale = false;
            //caller can withdraw their bid
            balanceForWithdrawal[msg.sender] = msg.value;  
            return false;          
        }
    }

    /// @notice sending back the token that was accidentally sent here
    function sendNftBack(address _nftAddress, uint256 _tokenId, address _recipient) external OnlyAdmin returns(bool) {
        ///sen back the nft
        INft(_nftAddress).safeTransferFrom(address(this), _recipient, _tokenId);
        return true;
    }

    ///@notice updating where the proxy points to
    function updateCode(address newCode) external OnlyAdmin returns(bool) {
        updateCodeAddress(newCode);
        return true;
    }

}