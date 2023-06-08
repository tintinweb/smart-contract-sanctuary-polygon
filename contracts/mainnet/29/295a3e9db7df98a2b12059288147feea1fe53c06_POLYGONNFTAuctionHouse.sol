/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// File: nftauction/IERC165.sol


pragma solidity ^0.5.17;

/**
 * @title IERC165
 * @dev https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// File: nftauction/IERC721.sol


pragma solidity ^0.5.17;


/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}
// File: nftauction/Ownable.sol


pragma solidity ^0.5.17;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}
// File: nftauction/AddressUtils.sol


pragma solidity ^0.5.17;
/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
  }

}
// File: nftauction/SafeMath.sol


pragma solidity ^0.5.17;
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}
// File: nftauction/ERC721.sol


pragma solidity ^0.5.17;




contract ERC721Receiver {
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

  function onERC721Received(address _from, uint256 _tokenId, bytes memory _data) public returns(bytes4);
}


contract ERC721Interface {
    // events
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // interface
    function balanceOf(address _owner) public view returns (uint256);
    function ownerOf(uint256 _tokenId) public view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function approve(address _approved, uint256 _tokenId) public;
    function setApprovalForAll(address _operator, bool _approved) public;
    function getApproved(uint256 _tokenId) public view returns (address);
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);
}

contract ERC721 is ERC721Interface {
    using SafeMath for uint256;
    using AddressUtils for address;

    // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

    // who owns which NFT
    mapping(uint256 => address) internal tokenOwner;

    // how many NFT an owner has (ownerAddress => tokenCounter)
    mapping (address => uint256) internal ownedTokensCount;

    // which account is approved to transfer a NFT (tokenId => approvedAddress)
    mapping (uint256 => address) internal tokenApprovals;

    // Mapping from owner to operator approvals
    // address "A" allows address "B" to operate all A's assets
    mapping (address => mapping (address => bool)) internal operatorApprovals;


    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
        return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokensCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public {
        // if target address is a contract, make sure it supports ERC721 interface
        if (_to.isContract()) {
            bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, data);
            require(retval == ERC721_RECEIVED);
        }
        transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
        }
    }

    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }

    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        require(_from != address(0));
        require(_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require(_approved != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        if (getApproved(_tokenId) != address(0) || _approved != address(0)) {
            tokenApprovals[_tokenId] = _approved;
            emit Approval(owner, _approved, _tokenId);
        }
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        require(_operator != msg.sender);
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    function onERC721Received(address, uint256, bytes memory) public pure returns (bytes4) {
        return ERC721_RECEIVED;
    }
}
// File: nftauction/ERC20.sol


pragma solidity ^0.5.17;



contract ERC20Interface {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Interface {

    // who owns how many tokens
    mapping(address => uint256) balances;

    // account "A" allows account "B" to extract "X" amount
    mapping(address => mapping(address => uint256)) internal allowed;

    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(balances[msg.sender] >= value);

        balances[msg.sender] = SafeMath.sub(balances[msg.sender], value);
        balances[to] = SafeMath.add(balances[to], value);

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(from != address(0));
        require(balances[from] >= value);
        require(allowed[from][msg.sender] >= value);

        balances[from] = SafeMath.sub(balances[from], value);
        balances[to] = SafeMath.add(balances[to], value);
        allowed[from][msg.sender] = SafeMath.sub(allowed[from][msg.sender], value);

        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }
}
// File: nftauction/auction.sol


pragma solidity ^0.5.17;







contract POLYGONNFTAuctionHouse is Ownable {
    mapping(address => bool) public authorized;
    using SafeMath for uint256;
    using AddressUtils for address;

    uint256 public saleFee = 100; // 1% sale fee
    address public saleFeeWalletAddress = 0x2A8B5A587F60c0EE39d85df41590BAD8c2aCB55e;

    event AuctionCreated(
        uint256 _index, address _asset, uint256 _assetId, address _token, 
        address _creator, uint256 _startPrice, uint256 _startTime, uint256 _duration, 
        uint256 _currentBidAmount, address _currentBidOwner, uint256 _bidCount
    );
    event AuctionBid(uint256 _index, address _bidder, uint256 _amount, uint256 _bidCount);
    event ClaimTokens(uint256 _index, address _tokensClaimer);
    event ClaimAsset(uint256 _index, address _assetClaimer);

    enum Status { pending, active, finished }
    struct Auction {
        address assetAddress;
        uint256 assetId;
        address tokenAddress;
        address creator;
        uint256 startPrice;
        uint256 startTime;
        uint256 duration;
        uint256 currentBidAmount;
        address currentBidOwner;
        uint256 bidCount;
    }
    Auction[] public auctions;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner == msg.sender);
        _;
    }

    function addAuthorized(address _toAdd) onlyAuthorized public {
        require(_toAdd != address(0));
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) onlyAuthorized public {
        require(_toRemove != address(0));
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

    function setSaleFee(uint256 _newSaleFee) public onlyAuthorized {
        saleFee = _newSaleFee;
    }

    function setSaleFeeWalletAddress(address _newAddress) public onlyAuthorized {
        saleFeeWalletAddress = _newAddress;
    }

    function createAuction(address _assetAddress,
                           uint256 _assetId,
                           address _tokenAddress,
                           uint256 _startPrice,
                           uint256 _startTime,
                           uint256 _duration) public returns (uint256) {

        require(_assetAddress.isContract());
        ERC721 asset = ERC721(_assetAddress);
        require(asset.ownerOf(_assetId) == msg.sender);
        require(asset.getApproved(_assetId) == address(this));
        asset.transferFrom(msg.sender, address(this), _assetId);

        require(_tokenAddress.isContract());

        if (_startTime == 0) { _startTime = now; }

        Auction memory auction = Auction({
            creator: msg.sender,
            assetAddress: _assetAddress,
            assetId: _assetId,
            tokenAddress: _tokenAddress,
            startPrice: _startPrice,
            startTime: _startTime,
            duration: _duration,
            currentBidAmount: 0,
            currentBidOwner: address(0),
            bidCount: 0
        });
        uint256 index = auctions.push(auction) - 1;

        emit AuctionCreated(
            index, auction.assetAddress, auction.assetId, auction.tokenAddress, 
            auction.creator, auction.startPrice, auction.startTime, auction.duration,
            auction.currentBidAmount, auction.currentBidOwner, auction.bidCount
        );

        return index;
    }

    function bid(uint256 auctionIndex, uint256 amount) public {
        Auction storage auction = auctions[auctionIndex];
        require(auction.creator != address(0));
        require(isActive(auctionIndex));

        require(amount >= auction.startPrice);
        require(amount > auction.currentBidAmount);
        ERC20 token = ERC20(auction.tokenAddress);
        token.transferFrom(msg.sender, address(this), amount);
        if (auction.currentBidAmount != 0) {
            token.transfer(
                auction.currentBidOwner,
                auction.currentBidAmount
            );
        }
        auction.currentBidAmount = amount;
        auction.currentBidOwner = msg.sender;
        auction.bidCount = auction.bidCount.add(1);
        
        emit AuctionBid(auctionIndex, msg.sender, amount, auction.bidCount);
    }

    function getTotalAuctions() public view returns (uint256) { return auctions.length; }

    function isActive(uint256 index) public view returns (bool) { return getStatus(index) == Status.active; }

    function isFinished(uint256 index) public view returns (bool) { return getStatus(index) == Status.finished; }

    function getStatus(uint256 index) public view returns (Status) {
        Auction storage auction = auctions[index];
        if (now < auction.startTime) {
            return Status.pending;
        } else if (now < auction.startTime.add(auction.duration)) {
            return Status.active;
        } else {
            return Status.finished;
        }
    }

    function getCurrentBidOwner(uint256 auctionIndex) public view returns (address) { return auctions[auctionIndex].currentBidOwner; }

    function getCurrentBidAmount(uint256 auctionIndex) public view returns (uint256) { return auctions[auctionIndex].currentBidAmount; }

    function getBidCount(uint256 auctionIndex) public view returns (uint256) { return auctions[auctionIndex].bidCount; }

    function getWinner(uint256 auctionIndex) public view returns (address) {
        require(isFinished(auctionIndex));
        Auction storage auction = auctions[auctionIndex];
        if (auction.currentBidOwner == address(0)) {
            return auctions[auctionIndex].creator;
        }
        else {
            return auctions[auctionIndex].currentBidOwner;
        }
    }

    function claimTokens(uint256 auctionIndex) public {
        require(isFinished(auctionIndex));
        Auction storage auction = auctions[auctionIndex];

        require(auction.creator == msg.sender);
        ERC20 token = ERC20(auction.tokenAddress);
        require(token.transfer(auction.creator, (auction.currentBidAmount) - ((auction.currentBidAmount) * saleFee / 10000)));
        require(token.transfer(saleFeeWalletAddress, (auction.currentBidAmount) * saleFee / 10000 ));

        emit ClaimTokens(auctionIndex, auction.creator);
    }

    function claimAsset(uint256 auctionIndex) public {
        require(isFinished(auctionIndex));
        Auction storage auction = auctions[auctionIndex];

        address winner = getWinner(auctionIndex);
        require(winner == msg.sender);

        ERC721 asset = ERC721(auction.assetAddress);
        asset.transferFrom(address(this), winner, auction.assetId);

        emit ClaimAsset(auctionIndex, winner);
    }

    // withdraw function for erc721 tokens if a nft is sent by accident to this contract, also for emergency bug cases / recovery
    function withdrawERC721(address _tokenContract, address _from, address _to, uint256 _tokenId) public payable onlyAuthorized {
        IERC721 tokenContract = IERC721(_tokenContract);
        
        tokenContract.transferFrom(_from, _to, _tokenId);
    }
    
}