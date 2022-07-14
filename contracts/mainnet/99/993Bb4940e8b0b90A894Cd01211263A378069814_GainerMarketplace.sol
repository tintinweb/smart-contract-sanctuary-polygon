// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GainerMarketplace is ERC1155Holder, Ownable, ReentrancyGuard{
    constructor (IERC20 erc20token, uint gainerNFTprice, uint rebasePercentage, uint transactionFee) {
        _erc20token = erc20token;
        _gainerNFTprice = gainerNFTprice;
        _rebasePercentage = rebasePercentage;
        _transactionFee = transactionFee;
    }

    IERC20 public _erc20token;                     /// @notice USDT ADDRESS POLYGON
    IERC1155 public _gainerNFT;                    /// @notice GAINER NFT

    uint private _gainerNFTprice;                  /// @notice GAINER NFT BASE PRICE
    uint public _rebasePercentage;                 /// @notice REBASE PERCENTAGE 
    uint private _nextDay;                         /// @notice NEXT DAY
    uint public _transactionFee;                   /// @notice TRANSACTION FEE 
    uint public _feeCollector;                     /// @notice FEE COLLECTOR
    address public _protocolWalletAddr;            /// @notice PROTOCOL WALLET ADDRESS

    mapping(address => uint256) public _userErc20TokenBalanceInGainerProtocol;  /// @notice @param useraddress 
    mapping(uint => mapping(uint => NFTListing)) public Listing;               /// @notice @param tokenId, @param listingId
    mapping(address => mapping(uint=> uint)) public UserListing;               /// @notice @param sellerAddr @param tokenId, @param listingId
    
    uint constant public headGainerOne  = 0; /// @notice IDENTIFIER CURRENT LISTING GAINER ONE
    uint public tailGainerOne           = 0; /// @notice LAST LISTING GAINER ONE
    uint constant public headGainerFive = 0; /// @notice IDENTIFIER CURRENT LISTING GAINER FIVE
    uint public tailGainerFive          = 0; /// @notice LAST LISTING GAINER FIVE
    uint constant public headGainerTen  = 0; /// @notice IDENTIFIER CURRENT LISTING GAINER TEN
    uint public tailGainerTen           = 0; /// @notice LAST LISTING GAINER TEN

    struct NFTListing{
        uint prev;
        uint selfIndex;
        uint next;
        address sellerAddr;
        uint amount;
    }

    event AddListing(address sellerAddr, uint256 listingId, uint256 tokenId, uint256 amount);
    event DoneTrxGainerOne(address indexed sellerAddr, uint256 listingId, uint256 indexed amount, address indexed buyerAddr);
    event DoneTrxGainerFive(address indexed sellerAddr, uint256 listingId, uint256 indexed amount, address indexed buyerAddr);
    event DoneTrxGainerTen(address indexed sellerAddr, uint256 listingId, uint256 indexed amount, address indexed buyerAddr);
    event ModifyListing(address sellerAddr, uint256 listingId, uint256 tokenId, uint256 amount, uint prevListingId);
    
    /// @notice PUBLIC MARKETPLACE MAIN FUNCTION 
    /// @notice PUBLIC MARKETPLACE MAIN FUNCTION
    /// @notice PUBLIC MARKETPLACE MAIN FUNCTION

    function showPrice() public view returns(uint){
        if(block.timestamp > _nextDay){
            uint dayDifferent = (block.timestamp - _nextDay) / 60 / 60 / 24;
            if(dayDifferent == 0){
                return _gainerNFTprice;
            }else{
                uint _gainerBasePrice = _gainerNFTprice;
                for(uint i = 0 ; i < dayDifferent; i++){
                    _gainerBasePrice += _gainerNFTprice * _rebasePercentage / 1000;
                }
                return _gainerBasePrice;
            }
        }else{
             return _gainerNFTprice;
        }
    }

    function updatePrice() internal {
        if(block.timestamp > _nextDay){
            uint dayDifferent = (block.timestamp - _nextDay) / 60 / 60 / 24;
            if(dayDifferent > 0){
                uint _gainerBasePrice = _gainerNFTprice;
                for(uint i = 0 ; i < dayDifferent; i++){
                    _gainerBasePrice += _gainerNFTprice * _rebasePercentage / 1000;
                    _nextDay += 1 days;
                }
                _gainerNFTprice = _gainerBasePrice;
            }
        }
    }
    
    function isListingEmpty(uint tokenId, uint head) public view returns (bool){
        return(Listing[tokenId][head].next == 0);   
    }

    function isUserListingEmpty(uint tokenId) public view returns (bool){
        return(UserListing[msg.sender][tokenId]==0);
    }

    function checkTopListing(uint tokenId) public view returns (NFTListing memory){
        NFTListing memory listing;
        if(tokenId == 0){
            uint _listingId = Listing[tokenId][headGainerOne].next;
            listing = Listing[tokenId][_listingId];
        }else if(tokenId == 1){
            uint _listingId = Listing[tokenId][headGainerFive].next;
            listing = Listing[tokenId][_listingId];
        }else if(tokenId == 2){
            uint _listingId = Listing[tokenId][headGainerTen].next;
            listing = Listing[tokenId][_listingId];
        }
        return listing;
    }
    
    function checkLastListing(uint tokenId) public view returns (NFTListing memory){
        NFTListing memory listing;
        if(tokenId == 0){
            uint _listingId = Listing[tokenId][tailGainerOne].selfIndex;
            listing = Listing[tokenId][_listingId];
        }else if(tokenId == 1){
            uint _listingId = Listing[tokenId][tailGainerFive].selfIndex;
            listing = Listing[tokenId][_listingId];
        }else if(tokenId == 2){
            uint _listingId = Listing[tokenId][tailGainerTen].selfIndex;
            listing = Listing[tokenId][_listingId];
        }
        return listing;
    }

    function addListingNFT(uint tokenId, uint amount) public nonReentrant {
        require(tokenId == 0 || tokenId == 1 || tokenId == 2, "NOT ALLOWED");
        require(isUserListingEmpty(tokenId), "YOU ALREADY HAVE A LISTING");
        require(_gainerNFT.balanceOf(msg.sender, tokenId) >= amount, "NOT enough NFT");
        require( _gainerNFT.isApprovedForAll(msg.sender, address(this)), "YOU NEED TO APPROVE OPERATOR");
        updatePrice();
        _gainerNFT.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        
        if(tokenId == 0){
            if(isListingEmpty(tokenId, headGainerOne)){
                Listing[tokenId][headGainerOne].next = 1;
                Listing[tokenId][1] = NFTListing(0, 1 ,0, msg.sender, amount);
                tailGainerOne = 1;
                UserListing[msg.sender][tokenId] = 1;
                emit AddListing(msg.sender, 1, tokenId, amount);
            }else{
                Listing[tokenId][tailGainerOne].next = tailGainerOne+1;
                Listing[tokenId][tailGainerOne+1] = NFTListing(tailGainerOne, tailGainerOne+1, 0, msg.sender, amount);
                UserListing[msg.sender][tokenId] = tailGainerOne+1;
                if(tailGainerOne == type(uint).max){
                    tailGainerOne = 1;
                }else  {
                    tailGainerOne++;
                }
                emit AddListing(msg.sender, tailGainerOne, tokenId, amount);
            }
        }else if(tokenId == 1){
           if(isListingEmpty(tokenId, headGainerFive)){
                Listing[tokenId][headGainerFive].next = 1;
                Listing[tokenId][1] = NFTListing(0, 1 ,0, msg.sender, amount);
                tailGainerFive = 1;
                UserListing[msg.sender][tokenId] = 1;
                emit AddListing(msg.sender, 1, tokenId, amount);
            }else{
                Listing[tokenId][tailGainerFive].next = tailGainerFive+1;
                Listing[tokenId][tailGainerFive+1] = NFTListing(tailGainerFive, tailGainerFive+1, 0, msg.sender, amount);
                UserListing[msg.sender][tokenId] = tailGainerFive+1;
                if(tailGainerFive == type(uint).max){
                    tailGainerFive = 1;
                }else  {
                    tailGainerFive++;
                }
                emit AddListing(msg.sender, tailGainerFive, tokenId, amount);
            }
        }else{
            if(isListingEmpty(tokenId, headGainerTen)){
                Listing[tokenId][headGainerTen].next = 1;
                Listing[tokenId][1] = NFTListing(0, 1 ,0, msg.sender, amount);
                tailGainerTen = 1;
                UserListing[msg.sender][tokenId] = 1;
                emit AddListing(msg.sender, 1, tokenId, amount);
            }else{
                Listing[tokenId][tailGainerTen].next = tailGainerTen+1;
                Listing[tokenId][tailGainerTen+1] = NFTListing(tailGainerTen, tailGainerTen+1, 0, msg.sender, amount);
                UserListing[msg.sender][tokenId] = tailGainerTen+1;
               if(tailGainerTen == type(uint).max){
                    tailGainerTen = 1;
                }else  {
                    tailGainerTen++;
                }
                emit AddListing(msg.sender, tailGainerTen, tokenId, amount);
            }
        }
    }

    function buyNFT(uint moneyAmount, uint tokenId, uint tokenAmount) public nonReentrant {
        updatePrice();

        uint gainerNFTprice;
        if(tokenId == 0){
            gainerNFTprice = _gainerNFTprice;
        }else if(tokenId == 1){
            gainerNFTprice = _gainerNFTprice * 5;
        }else{
            gainerNFTprice = _gainerNFTprice * 10;
        }
        require(isUserListingEmpty(tokenId), "YOU HAVE A LISTING, CANCEL IT FIRST");
        require(tokenId == 0 || tokenId == 1 || tokenId == 2, "NOT ALLOWED");
        require(moneyAmount == tokenAmount * gainerNFTprice, "MONEY MUST MATCH");
        require(_erc20token.balanceOf(msg.sender) >= moneyAmount, "INSUFFICIENT BALLANCE");
        require(_erc20token.allowance(msg.sender, address(this)) >= moneyAmount, "PLEASE CHECK ALOWANCE");
        require(_gainerNFT.balanceOf(address(this), tokenId) >= tokenAmount , "OUT OF STOCK");

        uint _tokenAmount = tokenAmount;
        NFTListing memory _headListing;

        if(tokenId == 0){
            _headListing = Listing[tokenId][headGainerOne];
        }else if(tokenId == 1){
            _headListing = Listing[tokenId][headGainerFive];
        }else{
            _headListing = Listing[tokenId][headGainerTen];
        }

        NFTListing storage _sellerListing = Listing[tokenId][_headListing.next];
        while(_tokenAmount != 0){
            if(_tokenAmount > _sellerListing.amount){
                     _feeCollector         += (gainerNFTprice * _sellerListing.amount * _transactionFee) / 100;
                uint erc20seller            = (gainerNFTprice * _sellerListing.amount) - ((gainerNFTprice * _sellerListing.amount * _transactionFee) / 100);
                     _tokenAmount          -= _sellerListing.amount;
                uint amountTraded           = _sellerListing.amount;
                     _sellerListing.amount  = 0;

                if(tokenId == 0){
                    if(_sellerListing.selfIndex == tailGainerOne){
                        tailGainerOne = Listing[tokenId][tailGainerOne].prev;
                    }
                }else if(tokenId == 1){
                   if(_sellerListing.selfIndex == tailGainerFive){
                        tailGainerFive = Listing[tokenId][tailGainerFive].prev;
                    }
                }else{
                    if(_sellerListing.selfIndex == tailGainerTen){
                        tailGainerTen = Listing[tokenId][tailGainerTen].prev;
                    }
                }
                
                uint256 a                = Listing[tokenId][_sellerListing.selfIndex].prev;
                uint256 b                = Listing[tokenId][_sellerListing.selfIndex].next;
                Listing[tokenId][a].next = Listing[tokenId][_sellerListing.selfIndex].next;
                Listing[tokenId][b].prev = Listing[tokenId][_sellerListing.selfIndex].prev;

                _userErc20TokenBalanceInGainerProtocol[_sellerListing.sellerAddr] += erc20seller; 

                NFTListing storage nextData = Listing[tokenId][_sellerListing.next];
                
                if(tokenId == 0){
                    emit DoneTrxGainerOne(_sellerListing.sellerAddr, _sellerListing.selfIndex, amountTraded, msg.sender);
                }else if(tokenId == 1){
                    emit DoneTrxGainerFive(_sellerListing.sellerAddr, _sellerListing.selfIndex, amountTraded, msg.sender);
                }else{
                    emit DoneTrxGainerTen(_sellerListing.sellerAddr, _sellerListing.selfIndex, amountTraded, msg.sender);
                }

                delete UserListing[_sellerListing.sellerAddr][tokenId];
                delete Listing[tokenId][_sellerListing.selfIndex];                
                _sellerListing = nextData;

            }else if(_tokenAmount < _sellerListing.amount){
                    _feeCollector          += (gainerNFTprice * _tokenAmount * _transactionFee) / 100;
                uint erc20seller            = (gainerNFTprice * _tokenAmount) - ((gainerNFTprice * _tokenAmount * _transactionFee) / 100);
                uint amountTraded           = _tokenAmount;
                     _sellerListing.amount -= _tokenAmount;
                     _tokenAmount           = 0;

                _userErc20TokenBalanceInGainerProtocol[_sellerListing.sellerAddr] += erc20seller; 

                if(tokenId == 0){
                    emit DoneTrxGainerOne(_sellerListing.sellerAddr, _sellerListing.selfIndex, amountTraded, msg.sender);
                }else if(tokenId == 1){
                    emit DoneTrxGainerFive(_sellerListing.sellerAddr, _sellerListing.selfIndex,  amountTraded, msg.sender);
                }else{
                    emit DoneTrxGainerTen(_sellerListing.sellerAddr, _sellerListing.selfIndex, amountTraded, msg.sender);
                }
  
            }else if(_tokenAmount == _sellerListing.amount){
                     _feeCollector         += (gainerNFTprice * _sellerListing.amount * _transactionFee) / 100;
                uint erc20seller            = (gainerNFTprice * _sellerListing.amount) - (gainerNFTprice * _sellerListing.amount * _transactionFee) / 100;
                uint amountTraded           = _sellerListing.amount;
                     _tokenAmount           = 0;
                     _sellerListing.amount  = 0;

                _userErc20TokenBalanceInGainerProtocol[_sellerListing.sellerAddr] += erc20seller; 

                if(tokenId == 0){
                    if(_sellerListing.selfIndex == tailGainerOne){
                        tailGainerOne =  Listing[tokenId][tailGainerOne].prev;
                    }
                }else if(tokenId == 1){
                   if(_sellerListing.selfIndex == tailGainerFive){
                        tailGainerFive =  Listing[tokenId][tailGainerFive].prev;
                    }
                }else{
                    if(_sellerListing.selfIndex == tailGainerTen){
                        tailGainerTen =  Listing[tokenId][tailGainerTen].prev;
                    }
                }

                uint256 a                = Listing[tokenId][_sellerListing.selfIndex].prev;
                uint256 b                = Listing[tokenId][_sellerListing.selfIndex].next;
                Listing[tokenId][a].next = Listing[tokenId][_sellerListing.selfIndex].next;
                Listing[tokenId][b].prev = Listing[tokenId][_sellerListing.selfIndex].prev;
       
                if(tokenId == 0){
                    emit DoneTrxGainerOne(_sellerListing.sellerAddr, _sellerListing.selfIndex, amountTraded, msg.sender);
                }else if(tokenId == 1){
                    emit DoneTrxGainerFive(_sellerListing.sellerAddr, _sellerListing.selfIndex, amountTraded, msg.sender);
                }else{
                    emit DoneTrxGainerTen(_sellerListing.sellerAddr, _sellerListing.selfIndex,  amountTraded, msg.sender);
                }

                delete UserListing[_sellerListing.sellerAddr][tokenId];
                delete Listing[tokenId][_sellerListing.selfIndex];

            }
        }
        assert(_tokenAmount == 0);
        _erc20token.transferFrom(msg.sender, address(this), moneyAmount); 
        _gainerNFT.safeTransferFrom(address(this), msg.sender, tokenId, tokenAmount, "");
    }

    function buyNFTFromGainerProtocol(uint moneyAmount, uint tokenId, uint tokenAmount) public nonReentrant {
        updatePrice();

        uint gainerNFTprice;
        if(tokenId == 0){
            gainerNFTprice = _gainerNFTprice;
        }else if(tokenId == 1){
            gainerNFTprice = _gainerNFTprice * 5;
        }else{
            gainerNFTprice = _gainerNFTprice * 10;
        }

        require(tokenId == 0 || tokenId == 1 || tokenId == 2, "NOT ALLOWED");
        require(moneyAmount == tokenAmount * gainerNFTprice, "MONEY MUST MATCH");
        require(_erc20token.balanceOf(msg.sender) >= moneyAmount, "INSUFFICIENT BALLANCE");
        require(_erc20token.allowance(msg.sender, address(this)) >= moneyAmount, "PLEASE CHECK ALOWANCE");
        require(_gainerNFT.balanceOf(_protocolWalletAddr, tokenId) >= tokenAmount, "OUT OF STOCK");

        _erc20token.transferFrom(msg.sender, _protocolWalletAddr, moneyAmount); 
        _gainerNFT.safeTransferFrom(_protocolWalletAddr, msg.sender, tokenId, tokenAmount, "");

        if(tokenId == 0){
            emit DoneTrxGainerOne(_protocolWalletAddr, 0, tokenAmount, msg.sender);
        }else if(tokenId == 1){
            emit DoneTrxGainerFive(_protocolWalletAddr, 0, tokenAmount, msg.sender);
        }else{
            emit DoneTrxGainerTen(_protocolWalletAddr, 0,  tokenAmount, msg.sender);
        }
    }

    function cancelListing(uint tokenId) public nonReentrant {
        require(tokenId == 0 || tokenId == 1 || tokenId == 2, "NOT ALLOWED");
        require(isUserListingEmpty(tokenId) == false , "YOU DONT HAVE A LISTING");
        uint       userListingId          = UserListing[msg.sender][tokenId];
        NFTListing storage _sellerListing = Listing[tokenId][userListingId];

        if(tokenId == 0){
            if(_sellerListing.selfIndex == tailGainerOne){
                tailGainerOne =  Listing[tokenId][tailGainerOne].prev;
            }
        }else if(tokenId == 1){
           if(_sellerListing.selfIndex == tailGainerFive){
                tailGainerFive =  Listing[tokenId][tailGainerFive].prev;
            }
        }else{
            if(_sellerListing.selfIndex == tailGainerTen){
                tailGainerTen =  Listing[tokenId][tailGainerTen].prev;
            }
        }

        uint256 a =  Listing[tokenId][_sellerListing.selfIndex].prev;
        uint256 b = Listing[tokenId][_sellerListing.selfIndex].next;

        Listing[tokenId][a].next = Listing[tokenId][_sellerListing.selfIndex].next;
        Listing[tokenId][b].prev = Listing[tokenId][_sellerListing.selfIndex].prev;

        uint amount = _sellerListing.amount;

        delete UserListing[_sellerListing.sellerAddr][tokenId];
        delete Listing[tokenId][_sellerListing.selfIndex];   
        _gainerNFT.safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
    }

    function withdrawUserERC20Token() public nonReentrant {
        uint _balance = _userErc20TokenBalanceInGainerProtocol[msg.sender];
        require(_balance > 0, "Not enough balance");
        _userErc20TokenBalanceInGainerProtocol[msg.sender] = 0;
        _erc20token.transfer(msg.sender, _balance); 
    }

    /// @notice OWNER SETUP MARKETPLACE MAIN FUNCTION 
    /// @notice OWNER SETUP MARKETPLACE MAIN FUNCTION
    /// @notice OWNER SETUP MARKETPLACE MAIN FUNCTION

    function setERC20Token(IERC20 erc20token) public onlyOwner {
        _erc20token = erc20token;
    }

    function setGainerNFTAddr(IERC1155 gainerNFTaddr) public onlyOwner {
        _gainerNFT = gainerNFTaddr;
    }

    function setGainerNFTPrice(uint price) public onlyOwner {
        _gainerNFTprice = price;
    }

    function setRebasePercentage(uint percentage) public onlyOwner {
        _rebasePercentage = percentage;
    }
    
    function setTransactionFee(uint fee) public onlyOwner {
        _transactionFee = fee;
    }

    function setupDay(uint nextDay) public onlyOwner{
        _nextDay = nextDay;
    }

    function setProtocolWalletAddr(address protocolWalletAddr) public onlyOwner{
        _protocolWalletAddr = protocolWalletAddr;
    }

    function withdrawFeeTransaction() public onlyOwner{
        require(_feeCollector > 0, "NOT enough BALANCE");
        _erc20token.transfer(msg.sender, _feeCollector); 
        _feeCollector = 0;
    }

    /// @notice PUBLIC FUNCTION GIVEAWAY
    /// @notice PUBLIC FUNCTION GIVEAWAY
    /// @notice PUBLIC FUNCTION GIVEAWAY

    address public _giveAwayWalletAddr;
    mapping(address => bool) public _userClaimGiveAway;
    bool public _isClaimOpen;
    uint public _gainerOneGiveAwayAmount;
    uint public _gainerFiveGiveAwayAmount;
    uint public _gainerTenGiveAwayAmount;
    
    function claimGiveAway() public nonReentrant {
        require(_isClaimOpen, "NOT CLAIMABLE YET");
        uint _giveAwayWalletAddrGainerOneBalance  = _gainerNFT.balanceOf(_giveAwayWalletAddr, 0);  
        uint _giveAwayWalletAddrGainerFiveBalance = _gainerNFT.balanceOf(_giveAwayWalletAddr, 1);
        uint _giveAwayWalletAddrGainerTenBalance  = _gainerNFT.balanceOf(_giveAwayWalletAddr, 2);        
        require(_giveAwayWalletAddrGainerOneBalance > 0 || _giveAwayWalletAddrGainerFiveBalance > 0 || _giveAwayWalletAddrGainerTenBalance > 0, "ALL NFTs ALREADY CLAIMED") ;
        
        if(_userClaimGiveAway[msg.sender] == false){
            _userClaimGiveAway[msg.sender] = true;
            if(_giveAwayWalletAddrGainerOneBalance > 0){
                _gainerNFT.safeTransferFrom(_giveAwayWalletAddr, msg.sender, 0, _gainerOneGiveAwayAmount, "");
            }else if(_giveAwayWalletAddrGainerFiveBalance > 0){
                _gainerNFT.safeTransferFrom(_giveAwayWalletAddr, msg.sender, 1, _gainerFiveGiveAwayAmount, "");
            }else if(_giveAwayWalletAddrGainerTenBalance > 0){
                _gainerNFT.safeTransferFrom(_giveAwayWalletAddr, msg.sender, 2, _gainerTenGiveAwayAmount, "");
            }
        }else{
            revert("YOU ALREADY CLAIMED");
        }
    }

    /// @notice OWNER FUNCTION SETUP GIVE AWAY 
    /// @notice OWNER FUNCTION SETUP GIVE AWAY
    /// @notice OWNER FUNCTION SETUP GIVE AWAY

    function setGiveAwayWalletAddr(address giveAwayWalletAddr) public onlyOwner {
        _giveAwayWalletAddr = giveAwayWalletAddr;
    }

    function setStatusGiveaway(bool status) public onlyOwner {
        _isClaimOpen = status;
    }

    function setNFTGiveAwayAmount(uint gainerOneGiveAwayAmount, uint gainerFiveGiveAwayAmount, uint gainerTenGiveAwayAmount) public onlyOwner {
        _gainerOneGiveAwayAmount  = gainerOneGiveAwayAmount;
        _gainerFiveGiveAwayAmount = gainerFiveGiveAwayAmount;
        _gainerTenGiveAwayAmount  = gainerTenGiveAwayAmount;
    }

    /// @notice OWNER FUNCTION SETUP OTHER ERC20TOKEN 
    /// @notice OWNER FUNCTION SETUP OTHER ERC20TOKEN
    /// @notice OWNER FUNCTION SETUP OTHER ERC20TOKEN

    IERC20 public _otherERC20Token;

    function showOtherERC20Token() public view returns(IERC20) {
        return _otherERC20Token;
    }

    function setOtherERC20Token(IERC20 addr) public onlyOwner {
        _otherERC20Token = addr;
    }

    function transferOtherERC20Token() public onlyOwner {
        uint _balance = _otherERC20Token.balanceOf(address(this));
        require(_balance > 0, "INSUFFICIENT AMOUNT");
        _otherERC20Token.transfer(msg.sender, _balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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