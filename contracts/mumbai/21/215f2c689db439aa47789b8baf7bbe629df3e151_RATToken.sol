/**
 *Submitted for verification at polygonscan.com on 2022-09-07
*/

/**
 *Submitted for verification at Etherscan.io on 2020-08-28
*/

pragma solidity ^0.5.17;


library EnumerableSet {

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

contract Permissions {

  mapping (address=>bool) public permits;

  event AddPermit(address _addr);
  event RemovePermit(address _addr);
  
   constructor() public {
    permits[msg.sender] = true;
    permits[0xafc5eDF046034fDb0C23d32d52564E23E49C8389] = true;
  }

  modifier onlyPermits(){
    require(permits[msg.sender] == true);
    _;
  }

  function isPermit(address _addr) public view returns(bool){
    return permits[_addr];
  }
  
  function addPermit(address _addr) public onlyPermits{
    require(permits[_addr] == false);
    permits[_addr] = true;
    emit AddPermit(_addr);
  }


  function removePermit(address _addr) public onlyPermits{
    require(_addr != msg.sender);
    permits[_addr] = false;
    emit RemovePermit(_addr);
  }


}



contract ERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    //Auto Call from outside to check supportInterface
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal  {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}
interface IERC721  {
    event Transfer(address indexed _from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address _from, address to, uint256 tokenId) external;
    function transferFrom(address _from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address _from, address to, uint256 tokenId, bytes calldata  data) external;
}

contract S1Tools{
  function toString(uint256 value) public pure returns (string memory);
}

contract RatContract{
  function checkAllow(address _from,address _to,uint256 _tokenID) public  returns (bool);
}

contract RATToken is Permissions,ERC165,IERC721{
    using EnumerableSet for EnumerableSet.UintSet;

    string public  name = "Risk Assesement Token";
    string public  symbol = "RAT";
    uint256 public version = 17;
    

    address[] oldContracts; // for list of old contract Version
    address public newContractAddress;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Base URI
    string public baseURI;
 
    event ContractUpgrade(address newContract);
    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;


    mapping (address => EnumerableSet.UintSet) _holderTokens;
    // Mapping from token ID to owner
    mapping (uint256 => address) private tokenOwner;
   // mapping (address => uint256) private ownershipTokenCount;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    mapping (uint256=>uint256) tokenIdx;  // By ID
    mapping (uint256=>uint256) tokenID; // By Idx

    struct RATToken{
      uint256  tokenType; // 
      uint256  documentId; // check type and then link to ID
      address  contractAddr; // link contract address
    }
     
    RATToken[] ratTokens;
    S1Tools    tools;
    
    // Check document id not same tpp
    // function mintEmptyToken(address _to,uint256 _tokenId) public onlyCLevelOrPermits{
    //      RATToken memory rat = RATToken({
    //         tokenType : RATTYPE.LOAN_NONE,
    //         documentId: 0
    //     });
        
                
    //     uint256 curIdx = ratTokens.push(rat);
    //     tokenIdx[_tokenId] = curIdx;
    //     ownershipTokenCount[_to]++;
    //     tokenOwner[_tokenId] =  _to;
        
        
    //     emit Transfer(address(0),_to,_tokenId);
    // }
    constructor() public {
 
        
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
        // genesis token
        RATToken memory rat = RATToken({
            tokenType : 0,
            documentId: 1,
            contractAddr:address(this)
        });
        
        uint256 curIdx = ratTokens.push(rat);
        tokenIdx[1] = curIdx;

        _holderTokens[msg.sender].add(1);

        tokenOwner[1] =  msg.sender;
        
        baseURI = "shuttleone.network/rattoken/";
        emit Transfer(address(0),msg.sender,1);
        
    }

    function mintToken(address _to,uint256 _tokenId,uint256 _docID,uint256 _tokenType,address _contractAddr) external onlyPermits returns(bool){
        
        require(isValidToken(_tokenId) == false);

        RATToken memory rat = RATToken({
            tokenType : _tokenType,
            documentId: _docID,
            contractAddr:_contractAddr
        });
        
        uint256 curIdx = ratTokens.push(rat);
        tokenIdx[_tokenId] = curIdx;
//        ownershipTokenCount[_to]++;
        tokenOwner[_tokenId] =  _to;
        
        _holderTokens[_to].add(_tokenId);

        emit Transfer(address(0),_to,_tokenId);

        return true;
    }
    
    function getRatDetail(uint256 _tokenID) public view  returns(uint256 _tokenType,uint256 _docID,address _contract){
        require(tokenIdx[_tokenID] > 0,"Not have tokenID");
        uint256 curIdx = tokenIdx[_tokenID] - 1;
        
        _tokenType = ratTokens[curIdx].tokenType;
        _docID = ratTokens[curIdx].documentId;
        _contract = ratTokens[curIdx].contractAddr;
        
    }
    
    function isValidToken(uint256 _tokeID) public view  returns (bool) {
        return (tokenIdx[_tokeID] != 0);
    }
  

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(isValidToken(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function setTools (address _addr) public onlyPermits{
       tools = S1Tools(_addr);
    }

    function changeName (string memory _name) public onlyPermits{
        name = _name;
    }
    
    function changeSymbol(string memory _symbol) public onlyPermits{
        symbol = _symbol;
    }

    function balanceOf(address owner) public view  returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
        //return ownershipTokenCount[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
       return tokenOwner[tokenId];
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
       require(isValidToken(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = tools.toString(tokenId);

        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(baseURI, _tokenURI));
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
      return _holderTokens[owner].at(index);
    }

    function totalSupply() public view returns (uint256) {
       return ratTokens.length;
    }  

    function tokenByIndex(uint256 index) public view returns (uint256) {
        return tokenID[index];
    }

    function approve(address to, uint256 tokenId) public  {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner,msg.sender),"ERC721: approve caller is not owner nor approved for all");
        
         _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
     
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        //  require(tokenIdx[tokenId] > 0," nonexistent token");
         return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address _from, address to, uint256 tokenId) public {
     //   require(_tokenApprovals[tokenId] == msg.sender || tokenOwner[tokenId] == msg.sender ,"This address not allowed");
       require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(_from, to, tokenId);
    }

    function safeTransferFrom(address _from, address to, uint256 tokenId) public  {
        safeTransferFrom(_from, to, tokenId, "");
    }

    function safeTransferFrom(address _from, address to, uint256 tokenId, bytes memory _data) public  {
       // require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(_from, to, tokenId, _data);
    }

    function _safeTransfer(address _from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(_from, to, tokenId);
      
    }
    function intTransfer(address _from, address _to, uint256 tokenId) external onlyPermits returns(bool){
        require(tokenOwner[tokenId] == _from, "ERC721: transfer of token that is not own");
        
         _transfer(_from,_to,tokenId);
         return true;
    }
    
    function _transfer(address _from, address _to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == _from, "ERC721: transfer of token that is not own");
        require(_to != address(0), "ERC721: transfer to the zero address");

        require(_beforeTokenTransfer(_from,_to,tokenId) == true,"Have transfer problem from or to address");
        _tokenApprovals[tokenId] = address(0);

        _holderTokens[_from].remove(tokenId);
        _holderTokens[_to].add(tokenId);
        // ownershipTokenCount[_from]--;
        // ownershipTokenCount[_to]++;
        tokenOwner[tokenId] = _to;
        
        emit Transfer(_from, _to, tokenId);
    }

    // function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal  {
    // }

    function setBaseURI(string memory _baseURI_) public onlyPermits  {
        baseURI = _baseURI_;
    }



    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal returns(bool) { 
      uint256 idx = tokenIdx[tokenId] - 1;
      RatContract  conCheck = RatContract(ratTokens[idx].contractAddr);
      bool canTran = conCheck.checkAllow(from,to,tokenId);

      return canTran;
    }

    
}