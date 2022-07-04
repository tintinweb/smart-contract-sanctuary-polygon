/**
 *Submitted for verification at polygonscan.com on 2022-07-04
*/

// File: utils/ISpawnContract.sol

pragma solidity >=0.8.0 <0.9.0;

interface ISpawnContract{

    /// @dev This event should be fired whenever the address of CoinB is modified.
    event CoinBChanged(address indexed _from,address indexed _to, uint256 _time);

    /// @dev This event should be fired whenever the address of CoinA is modified.
    event CoinAChanged(address indexed _from,address indexed _to, uint256 _time);

    /// @dev Change CoinA contract.
    ///  Caller should always be superAdmin. _to is the address of new CoinA contract.
    function changeCoinA(address addr) external;

    /// @dev Change CoinB contract.
    ///  Caller should always be superAdmin. _to is the address of new CoinB contract.
    function changeCoinB(address addr) external;

    function setELFCore(address addr) external;

    function spawnEgg(uint256 seed, uint256 momGene, uint256 dadGene, uint256 momChildren, uint256 dadChildren, address caller, bool momFromChaos, bool dadFromChaos) external returns(uint256 gene);
}
// File: utils/IGetter.sol

pragma solidity >=0.8.0 <0.9.0;

interface IGetter {

    /// @dev Interface used by server to check who can use the _tokenId.
    function getUser(address _nftAddress,uint256 _tokenId) external view returns (address);
    
    /// @dev Interface used by server to check who can claim coin B earned by _tokenId.
    function getCoinB(address _nftAddress,uint256 _tokenId) external view returns (address);
}
// File: utils/ICapsuleContract.sol

pragma solidity >=0.8.0 <0.9.0;

interface ICapsuleContract{
    function writePriceInfo(uint256 price) external;
    function getPriceInfo() external view returns(uint256 price,uint256 time);
    function createCapsule(address caller,bool triple) external returns(uint256[] memory, uint256);
    function setELFCoreAddress(address addr) external;
}
// File: utils/Address.sol

pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Utility library of inline functions on addresses.
 * @notice Based on:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
 * Requires EIP-1052.
 */
library AddressUtils{

    /**
    * @dev Returns whether the target address is a contract.
    * @param _addr Address to check.
    * @return addressCheck True if _addr is a contract, false if not.
    */
    function isContract(
    address _addr
    )
    internal
    view
    returns (bool addressCheck)
    {
    // This method relies in extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { codehash := extcodehash(_addr) } // solhint-disable-line
    addressCheck = (codehash != 0x0 && codehash != accountHash);
    }

}
// File: utils/IERC165.sol

pragma solidity >=0.8.0 <0.9.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
// File: token/IERC721Metadata.sol

pragma solidity >=0.8.0 <0.9.0;

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}
// File: token/IERC721TokenReceiver.sol

pragma solidity >=0.8.0 <0.9.0;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}
// File: token/IERC721.sol

pragma solidity >=0.8.0 <0.9.0;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
// File: security/AccessControl.sol

pragma solidity >=0.8.0 <0.9.0;

contract AccessControl{

    /// @dev Error message.
    string constant NO_PERMISSION='no permission';
    string constant INVALID_ADDRESS ='invalid address';
    
    /// @dev Administrator with highest authority. Should be a multisig wallet.
    address payable superAdmin;

    /// @dev Administrator of this contract.
    address payable admin;

    /// Sets the original admin and superAdmin of the contract to the sender account.
    constructor(){
        superAdmin=payable(msg.sender);
        admin=payable(msg.sender);
    }

    /// @dev Throws if called by any account other than the superAdmin.
    modifier onlySuperAdmin{
        require(msg.sender==superAdmin,NO_PERMISSION);
        _;
    }

    /// @dev Throws if called by any account other than the admin.
    modifier onlyAdmin{
        require(msg.sender==admin,NO_PERMISSION);
        _;
    }

    /// @dev Allows the current superAdmin to change superAdmin.
    /// @param addr The address to transfer the right of superAdmin to.
    function changeSuperAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        superAdmin=addr;
    }

    /// @dev Allows the current superAdmin to change admin.
    /// @param addr The address to transfer the right of admin to.
    function changeAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        admin=addr;
    }

    /// @dev Called by superAdmin to withdraw balance.
    function withdrawBalance(uint256 amount) external onlySuperAdmin{
        superAdmin.transfer(amount);
    }

    fallback() external {}
}
// File: security/Pausable.sol

pragma solidity >=0.8.0 <0.9.0;


contract Pausable is AccessControl{

    /// @dev Error message.
    string constant PAUSED='paused';
    string constant NOT_PAUSED='not paused';

    /// @dev Keeps track whether the contract is paused. When this is true, most actions are blocked.
    bool public paused = false;

    /// @dev Modifier to allow actions only when the contract is not paused
    modifier whenNotPaused {
        require(!paused,PAUSED);
        _;
    }

    /// @dev Modifier to allow actions only when the contract is paused
    modifier whenPaused {
        require(paused,NOT_PAUSED);
        _;
    }

    /// @dev Called by superAdmin to pause the contract. Used when something goes wrong
    ///  and we need to limit damage.
    function pause() external onlySuperAdmin whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the superAdmin.
    function unpause() external onlySuperAdmin whenPaused {
        paused = false;
    }
}
// File: ELFCore.sol

pragma solidity >=0.8.0 <0.9.0;










contract ELFBase is Pausable, IERC721TokenReceiver, IERC165, IERC721Metadata{

    /// @dev Used for supportsInterface of ERC165.
    bytes4 constant InterfaceSignature_ERC721=0x80ac58cd;
    bytes4 constant InterfaceSignature_ERC165=0x01ffc9a7;
    bytes4 constant InterfaceSignature_ERC721TokenReceiver=0x150b7a02;
    bytes4 constant InterfaceSignature_ERC721Metadata=0x5b5e139f;
    
    /// @dev Value should be returned when we transfer NFT to a contract via safeTransferFrom.
    bytes4 constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    /// @dev Error message.
    string constant NOT_VALID_NFT ='invalid NFT';

    /// @dev The data type of ELF NFT instance.
    struct ELF{
        uint256 label;
        uint256 dad;
        uint256 mom;
        uint256 gene;
        uint256 bornAt;
    }

    string url='www.roe.com/';

    /// @dev An array contains all existing ELF NFT instances.
    ///  The tokenId of each NFT is actually an index into this array.
    ELF[] ELFs;

    /// @dev Mapping from tokenId to whether it is hatched.
    mapping (uint256 => bool) tokenIdToHatched;

    /// @dev Mapping from tokenId to its children.
    mapping (uint256 => uint256[]) tokenIdToChildren;

    function setURL(string memory _url) external onlyAdmin {
        url=_url;
    }

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external pure override returns (string memory _name){
        return 'ELF';
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external pure override returns (string memory _symbol){
        return 'ELF';
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view override returns (string memory){
        require(_tokenId<ELFs.length && _tokenId!=0,NOT_VALID_NFT);
        uint256 temp = _tokenId;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_tokenId != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_tokenId % 10)));
            _tokenId /= 10;
        }
        return string(abi.encodePacked(url,string(buffer)));
    }

    ///  @dev Returns true for any standardized interfaces implemented by this contract. We implement
    ///  ERC-165, ERC721TokenReceiver and ERC-721.
    function supportsInterface(bytes4 _interfaceID) override external pure returns (bool){
        return ((_interfaceID == InterfaceSignature_ERC165)||(_interfaceID == InterfaceSignature_ERC721)||(_interfaceID==InterfaceSignature_ERC721TokenReceiver)||(_interfaceID == InterfaceSignature_ERC721Metadata));
    }

    /// @dev Required for ERC721TokenReceiver compliance.
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) override pure external returns(bytes4){
        return MAGIC_ON_ERC721_RECEIVED;
    }

    /// @dev Gain information of an ELF instance.
    function gainELF(uint256 _tokenId) external view returns(uint256,uint256,uint256,uint256,uint256,uint256[] memory){
        ELF memory _ELF=ELFs[_tokenId];
        uint256 gene=_ELF.gene;
        if (!tokenIdToHatched[_tokenId]){
            gene=(gene/10000000000000000000000000000000000000000000000000000000000000)%10;
        }
        return(_ELF.label,_ELF.dad,_ELF.mom,gene,_ELF.bornAt,tokenIdToChildren[_tokenId]);
    }
}

contract ELFTransfer is ELFBase, IERC721{

    using AddressUtils for address;

    /// @dev Error message.
    string constant WRONG_PARAMETER='wrong parameter';
    string constant CANT_RECEIVE_NFT='can not receive NFT';

    /// @dev Mapping from tokenId to the address that owns it. There is a valid owner
    ///  for every ELF.
    mapping (uint256 => address) tokenIdToOwner;

    /// @dev Mapping from tokenId to index of arrary storing it.
    mapping (uint256 => uint256) tokenIdToIndex;

    /// @dev Mapping from owner to list of owned tokenIds.
    mapping (address => uint256[]) ownedTokens;

    /// @dev Mapping from tokenId to an address that has been approved to transfer this NFT. 
    ///  A zero value means no approved address.
    mapping (uint256 => address) tokenIdToApproved;

    /// @dev Mapping from owner address to authorized operators of that owner.
    ///  true means authorized, false means unauthorized.
    mapping (address => mapping (address => bool)) ownerToOperators;

    /// @dev Mapping from address to tokenIds usable by the address but not owned by the address.
    mapping (address => uint256[]) ownedByContractTokens;

    /// @dev When the token is owned by smart contract, mapping from tokenId to its usable address.
    ///  Can only be set by the owned smart contract.  
    mapping (uint256 => address) tokenToUsable;

    /// @dev Mapping from tokenId to its index of ownedByContractTokens.
    mapping (uint256 => uint256) tokenToOwnedByContractTokensIndex;

    /// @dev Whether tokenId has been hatched.
    function isHatched(uint256 _tokenId) public view returns(bool res){
        ownerOf(_tokenId);
        res=tokenIdToHatched[_tokenId];
    }

    /// @dev Return owned tokenIds of an address.
    function gainOwnedTokens(address addr) external view returns(uint256[] memory){
        require(addr!=address(0),INVALID_ADDRESS);
        return(ownedTokens[addr]);
    }

    /// @dev Internal function used to add ELF NFT instance to address _to.
    /// @param _to Add token to _to.
    /// @param _tokenId ELF NFT instance we want to operate.
    function _addTo(address _to, uint256 _tokenId) internal{
        tokenIdToOwner[_tokenId]=_to;
        uint256[] storage _ownedTokens=ownedTokens[_to];
        tokenIdToIndex[_tokenId]=_ownedTokens.length;
        _ownedTokens.push(_tokenId);
    }

    /// @dev Internal function used to remove ELF NFT instance.
    /// @param _tokenId ELF NFT instance we want to operate.
    function _removeFrom(address _from,uint256 _tokenId) internal{
        uint256[] storage _ownedTokens=ownedTokens[_from];
        uint256 lastIndex=_ownedTokens.length-1;
        uint256 lastTokenId=_ownedTokens[lastIndex];
        uint256 tokenIndex=tokenIdToIndex[_tokenId];
        delete tokenIdToOwner[_tokenId];
        delete tokenIdToIndex[_tokenId];
        tokenIdToIndex[lastTokenId]=tokenIndex;
        _ownedTokens[tokenIndex]=lastTokenId;
        _ownedTokens.pop();
        if (tokenToUsable[_tokenId]!=address(0)){
            removeFromOwnedByContractTokens(_tokenId);
            tokenToUsable[_tokenId]=address(0);
        }
    }

    function setTokenToUsable(uint256 tokenId, address addr) external{
        require(msg.sender==ownerOf(tokenId) && msg.sender.isContract(),NO_PERMISSION);
        if (tokenToUsable[tokenId]!=address(0)){
            removeFromOwnedByContractTokens(tokenId);
        }
        tokenToUsable[tokenId]=addr;
        tokenToOwnedByContractTokensIndex[tokenId]=ownedByContractTokens[addr].length;
        ownedByContractTokens[addr].push(tokenId);
    }

    function removeFromOwnedByContractTokens(uint256 tokenId) internal{
        address from=tokenToUsable[tokenId];
        uint256 index=tokenToOwnedByContractTokensIndex[tokenId];
        uint256 l=ownedByContractTokens[from].length;
        uint256 lastTokenId=ownedByContractTokens[from][l-1];
        ownedByContractTokens[from][index]=lastTokenId;
        ownedByContractTokens[from].pop();
        tokenToOwnedByContractTokensIndex[lastTokenId]=index;
        delete tokenToOwnedByContractTokensIndex[tokenId];
    }

    /// @dev Return usable tokens of addr.
    function usableTokens(address addr) external view returns(uint256[] memory){
        require(addr!=address(0),INVALID_ADDRESS);
        uint256[] memory temp1=ownedTokens[addr];
        uint256[] memory temp2=ownedByContractTokens[addr];
        uint256 l1=temp1.length;
        uint256 l2=temp2.length;
        uint256[] memory cache1 = new uint256[](l1);
        uint256[] memory cache2 = new uint256[](l2);
        uint256 count1;
        uint256 count2;
        for (uint256 i=0;i<l1;i++){
            if (tokenIdToHatched[temp1[i]]){
                count1++;
                cache1[i]=temp1[i];
            }
        }
        for (uint256 i=0;i<l2;i++){
            if (tokenIdToHatched[temp2[i]]){
                IGetter contractInstance=IGetter(ownerOf(temp2[i]));
                try contractInstance.getUser(address(this),temp2[i]) returns (address tar){
                    if (tar==addr){
                        count2++;
                        cache2[i]=temp2[i];
                    }
                } catch {}
            }
        }
        uint256 index=0;
        uint256[] memory res = new uint256[](count1+count2);
        for (uint256 i=0;i<l1;i++){
            if (cache1[i]!=0){
                res[index]=cache1[i];
                index++;
            }
        }
        for (uint256 i=0;i<l2;i++){
            if (cache2[i]!=0){
                res[index]=cache2[i];
                index++;
            }
        }
        return res;
    }

    /// @dev Required for ERC-721 compliance.
    function balanceOf(address _owner) override external view returns (uint256){
        require(_owner!=address(0),INVALID_ADDRESS);
        return ownedTokens[_owner].length;
    }

    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId) override public view returns (address res){
        res=tokenIdToOwner[_tokenId];
        require(res!=address(0),NOT_VALID_NFT);
    }

    /// @dev Required for ERC-721 compliance.
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) override external payable{
        transferFrom(_from, _to, _tokenId);
        if (_to.isContract()){
            bytes4 retval=IERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data);
            require(retval == MAGIC_ON_ERC721_RECEIVED,CANT_RECEIVE_NFT);
        }
    }

    /// @dev Required for ERC-721 compliance.
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) override external payable{
        transferFrom(_from, _to, _tokenId);
        if (_to.isContract()){
            bytes4 retval=IERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, '');
            require(retval == MAGIC_ON_ERC721_RECEIVED,CANT_RECEIVE_NFT);
        }
    }

    /// @dev Required for ERC-721 compliance.
    function transferFrom(address _from, address _to, uint256 _tokenId) override public payable whenNotPaused{
        address _owner=ownerOf(_tokenId);
        require(msg.sender==_owner||ownerToOperators[_owner][msg.sender]||msg.sender==tokenIdToApproved[_tokenId],NO_PERMISSION);
        require(_from==_owner,WRONG_PARAMETER);
        require(_to!=address(0),INVALID_ADDRESS);
        _removeFrom(_from,_tokenId);
        _addTo(_to,_tokenId);
        if (tokenIdToApproved[_tokenId]!=address(0)){
            delete tokenIdToApproved[_tokenId];
            emit Approval(_from, address(0), _tokenId);
        }
        emit Transfer(_from, _to, _tokenId);
    }

    /// @dev Required for ERC-721 compliance.
    function approve(address _approved, uint256 _tokenId) override external payable whenNotPaused{
        address _owner=ownerOf(_tokenId);
        require(msg.sender==_owner||ownerToOperators[_owner][msg.sender],NO_PERMISSION);
        tokenIdToApproved[_tokenId]=_approved;
        emit Approval(_owner,_approved,_tokenId);
    }

    /// @dev Required for ERC-721 compliance.
    function setApprovalForAll(address _operator, bool _approved) override external whenNotPaused{
        ownerToOperators[msg.sender][_operator]=_approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @dev Required for ERC-721 compliance.
    function getApproved(uint256 _tokenId) override external view returns (address){
        ownerOf(_tokenId);
        return tokenIdToApproved[_tokenId];
    }

    /// @dev Required for ERC-721 compliance.
    function isApprovedForAll(address _owner, address _operator) override external view returns (bool){
        return ownerToOperators[_owner][_operator];
    }

    ///@dev Only res1 can use tokenId. Coin B earned by tokenId should distribute to res2.
    function userOfCoinBTo(uint256[] memory tokenIds) external view returns (address[] memory,address[] memory){
        uint256 l=tokenIds.length;
        address[] memory res1=new address[](l);
        address[] memory res2=new address[](l);
        address owner;
        uint256 tokenId;
        for (uint256 i=0;i<l;i++){
            tokenId=tokenIds[i];
            owner=ownerOf(tokenId);
            if (tokenIdToHatched[tokenId]){
                if (owner.isContract()){
                    IGetter contractInstance=IGetter(owner);
                    try contractInstance.getUser(address(this),tokenId) returns(address temp){
                        res1[i]=temp;
                    }catch{res1[i]=address(0);}
                    try contractInstance.getCoinB(address(this),tokenId) returns(address temp){
                        res2[i]=temp;
                    }catch{res2[i]=address(0);}
                }
                else{
                    res1[i]=owner;
                    res2[i]=owner;
                }
            }
            else{
                res1[i]=address(0);
                res2[i]=address(0);
            }
        }
        return (res1,res2);
    }

    /// @dev Gain all genes of ELFs in tokenIds.
    function gainGenes(uint256[] memory tokenIds) external view returns(uint256[] memory){
        uint256 l=tokenIds.length;
        uint256[] memory res = new uint256[](l);
        for (uint256 i=0;i<l;i++){
            if (isHatched(tokenIds[i])){
                ELF memory _ELF=ELFs[tokenIds[i]];
                res[i]=_ELF.gene;
            }
            else{
                res[i]=0;
            }
        }
        return res;
    }
}

contract ELFCore is ELFTransfer{

    /// @dev This is the spawan of chaos. Whether it is an ELF is still a mystery. 
    ///  No one has the ability to own it.
    constructor(){
        ELF memory _ELF=ELF({
            label:777,
            dad:0,
            mom:0,
            gene:0,
            bornAt:block.timestamp
        });
        ELFs.push(_ELF);
        tokenIdToHatched[0]=true;
    }

    /// @dev Error message.
    string constant WRONG_MONEY='money not enough';
    string constant EXCEED_MAX_SPAWN_TIMES ='exceed maximum spawan time';
    string constant CLOSE_BREEDING='close breeding';
    string constant NOT_MATURE='egg not mature';
    string constant HATCHED='egg hatched';

    /// @dev This event should be fired whenever the address of capsule contract is modified.
    event CapsuleContractChanged(address indexed _from,address indexed _to, uint256 _time);

    /// @dev The address of current capsule contract.
    address public capsuleContractAddress;

    /// @dev Total capsule number. Can't bigger than 5000.
    uint256 public capsuleCount;

    /// @dev Change capsule contract.
    ///  Caller should always be administrator. addr is the address of new capsule contract.
    function changeCapsuleContract(address addr) external onlySuperAdmin{
        require(addr!=address(0),INVALID_ADDRESS);
        emit CapsuleContractChanged(capsuleContractAddress,addr,block.timestamp);
        capsuleContractAddress=addr;
    }

    /// @dev Capsule machine. Capsule contract is assigned by superAdmin, 
    ///  so we do not have to worry about reentrancy attack here.
    function capsuleMachine(bool triple) external payable whenNotPaused {
        uint256 count=1;
        if (triple){
            count=3;
        }
        capsuleCount+=count;
        require(capsuleCount<=5000,'capsule limit exceeded');
        ICapsuleContract capsuleContractInstance=ICapsuleContract(capsuleContractAddress);
        (uint256 price,)=capsuleContractInstance.getPriceInfo();
        require(msg.value>=price*count,WRONG_MONEY);
        uint256 label;
        uint256[] memory genes = new uint256[](count);
        (genes,label)=capsuleContractInstance.createCapsule(msg.sender,triple);
        for(uint256 i=0;i<count;i++){
            ELF memory _ELF=ELF({
                label:label,
                dad:0,
                mom:0,
                gene:genes[i],
                bornAt:block.timestamp+432000
            });
            _addTo(msg.sender,ELFs.length);
            emit Transfer(address(0),msg.sender,ELFs.length);
            ELFs.push(_ELF);
        }
        if (msg.value>price*count){
            payable(msg.sender).transfer(msg.value-price*count);
        }
    }

    /// @dev This event should be fired whenever the address of SpawnContract is modified.
    event SpawnContractChanged(address indexed _from,address indexed _to, uint256 _time);

    /// @dev The address of SpawnContract.
    address public SpawnContractAddress;

    /// @dev Change SpawnContract address. 
    ///  Caller should always be superAdmin. addr is the address of new SpawnContract address.
    function changeSpawnContract(address addr) external onlySuperAdmin{
        require(addr!=address(0),INVALID_ADDRESS);
        emit SpawnContractChanged(SpawnContractAddress,addr,block.timestamp);
        SpawnContractAddress=addr;
    }

    /// @dev Maximun spawning time of an ELF.
    uint256 public constant maxSpawnTimes=7;
    
    /// @dev Spawn an egg of ELF. Mint NFT. Spawn contract is assigned by superAdmin, 
    ///  so we do not have to worry about reentrancy attack here.
    /// @param momTokenId tokenId of one of parent of new ELF. ELF has no gender, mom and dad is used for convinience.
    /// @param dadTokenId tokenId of one of parent of new ELF.
    function spawnEgg(uint256 momTokenId,uint256 dadTokenId) external whenNotPaused returns (uint256 tokenId){
        require(msg.sender==ownerOf(momTokenId),NO_PERMISSION);
        require(msg.sender==ownerOf(dadTokenId),NO_PERMISSION);
        uint256 dadChildrenCount=tokenIdToChildren[dadTokenId].length;
        uint256 momChildrenCount=tokenIdToChildren[momTokenId].length;
        require(momChildrenCount<maxSpawnTimes,EXCEED_MAX_SPAWN_TIMES);
        require(dadChildrenCount<maxSpawnTimes,EXCEED_MAX_SPAWN_TIMES);
        require(tokenIdToHatched[momTokenId]&&tokenIdToHatched[dadTokenId],WRONG_PARAMETER);
        require(momTokenId!=dadTokenId,WRONG_PARAMETER);
        ELF memory _mom=ELFs[momTokenId];
        ELF memory _dad=ELFs[dadTokenId];
        if (!(fromChaos(_mom) && fromChaos(_dad))){
            require(_mom.mom!=dadTokenId,CLOSE_BREEDING);
            require(_mom.dad!=dadTokenId,CLOSE_BREEDING);
            require(_dad.mom!=momTokenId,CLOSE_BREEDING);
            require(_dad.dad!=momTokenId,CLOSE_BREEDING);
        }
        if (!fromChaos(_mom) && !fromChaos(_dad)){
            require(_mom.mom!=_dad.mom,CLOSE_BREEDING);
            require(_mom.mom!=_dad.dad,CLOSE_BREEDING);
            require(_mom.dad!=_dad.mom,CLOSE_BREEDING);
            require(_mom.dad!=_dad.dad,CLOSE_BREEDING);
        } 
        uint256 seed=block.timestamp+dadChildrenCount+momChildrenCount;
        uint256 gene=ISpawnContract(SpawnContractAddress).spawnEgg(seed,_mom.gene,_dad.gene,momChildrenCount,dadChildrenCount,msg.sender,fromChaos(_mom),fromChaos(_dad));
        ELF memory _ELF=ELF({
            label:0,
            dad:dadTokenId,
            mom:momTokenId,
            gene:gene,
            bornAt:seed+432000
        });
        tokenId=ELFs.length;
        ELFs.push(_ELF);
        _addTo(msg.sender,tokenId);
        tokenIdToChildren[momTokenId].push(tokenId);
        tokenIdToChildren[dadTokenId].push(tokenId);
        emit Transfer(address(0),msg.sender,tokenId);
    }

    /// @dev Hatch an egg.
    function hatchELF(uint256 tokenId) external whenNotPaused{
        ELF memory _ELF=ELFs[tokenId];
        require(!tokenIdToHatched[tokenId],HATCHED);
        require(msg.sender==ownerOf(tokenId),NO_PERMISSION);
        require(block.timestamp>=_ELF.bornAt,NOT_MATURE);
        tokenIdToHatched[tokenId]=true;
    }

    /// @dev Whether the given ELF is from chaos.
    function fromChaos(ELF memory _ELF) internal pure returns(bool){
        return _ELF.mom==0;
    }
}