/**
 *Submitted for verification at polygonscan.com on 2023-07-31
*/

// File: contracts/Admin/data/DspCharacterControlStruct.sol


pragma solidity ^0.8.18;

    enum Job { MINT, BURN }
    enum CharacterType { NONE, CHARACTER, FATE_CORE }

    struct CharacterInfo {
        string characterName;
        uint256 tokenId;
        bool isValid;
    }

    struct JobInfo {
        address userAddress;
        uint256 characterId;
        string characterName;
        uint256 tokenId;
        string reason;
        CharacterType characterType;
        Job job;
    }

    struct BurnInfo {
        address userAddress;
        uint256 characterId;
        uint256 tokenId;
        uint256 reason;
        CharacterType characterType;
    }

    struct CharacterDecentralizationRoot {
        uint256 round;
        bytes32 root;
    }

    struct CharacterDecentralizationInfo {
        address userAddress;
        uint256 characterId;
        string characterName;
        uint256 reason;
        CharacterType characterType;
        uint256 round;
        bytes32[] userProof;
    }
// File: contracts/LUXON/utils/IERC721LUXON.sol


pragma solidity ^0.8.16;

interface IERC721LUXON {
    function mintByCharacterName(address mintUser, uint256 quantity, string[] memory gachaIds) external;
    function nextTokenId() external view returns (uint256);
    function burn(uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function totalSupply() external view returns (uint256);
    function mint(address mintUser, uint256 quantity) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Admin/LuxOnService.sol


pragma solidity ^0.8.15;


contract LuxOnService is Ownable {
    mapping(address => bool) isInspection;

    event Inspection(address contractAddress, uint256 timestamp, bool live);

    function isLive(address contractAddress) public view returns (bool) {
        return !isInspection[contractAddress];
    }

    function setInspection(address[] memory contractAddresses, bool _isInspection) external onlyOwner {
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            isInspection[contractAddresses[i]] = _isInspection;
            emit Inspection(contractAddresses[i], block.timestamp, _isInspection);
        }
    }
}
// File: contracts/LUXON/utils/LuxOnLive.sol


pragma solidity ^0.8.16;



contract LuxOnLive is Ownable {
    address private luxOnService;

    event SetLuxOnService(address indexed luxOnService);

    constructor(
        address _luxOnService
    ) {
        luxOnService = _luxOnService;
    }

    function getLuxOnService() public view returns (address) {
        return luxOnService;
    }

    function setLuxOnService(address _luxOnService) external onlyOwner {
        luxOnService = _luxOnService;
        emit SetLuxOnService(_luxOnService);
    }

    modifier isLive() {
        require(LuxOnService(luxOnService).isLive(address(this)), "LuxOnLive: not live");
        _;
    }
}
// File: contracts/Admin/LuxOnAuthority.sol


pragma solidity ^0.8.16;


contract LuxOnAuthority is Ownable {
    mapping (address => bool) blacklist;

    event Blacklist(address userAddress, uint256 timestamp, bool live);

    function isBlacklist(address user) public view returns (bool){
        return blacklist[user];
    }

    function setBlacklist(address[] memory userAddresses, bool _isBlacklist) external onlyOwner {
        for (uint256 i = 0; i < userAddresses.length; i++) {
            blacklist[userAddresses[i]] = _isBlacklist;
            emit Blacklist(userAddresses[i], block.timestamp, _isBlacklist);
        }
    }
}


// File: contracts/LUXON/utils/LuxOnBlacklist.sol


pragma solidity ^0.8.16;




contract LuxOnBlacklist is Ownable {
    address private luxOnAuthority;

    event SetLuxOnAuthority (address indexed luxOnAuthority);

    constructor(
        address _luxOnAuthority
    ){
        luxOnAuthority = _luxOnAuthority;
    }

    function getLuxOnAuthority() external view returns(address) {
        return luxOnAuthority;
    }

    function setLuxOnAuthority(address _luxOnAuthority) external onlyOwner{
        luxOnAuthority = _luxOnAuthority;
    }

    function getIsInBlacklist(address _userAddress) external view returns(bool) {
        return LuxOnAuthority(luxOnAuthority).isBlacklist(_userAddress);
    }

    modifier isBlacklist(address _userAddress) {
        // blacklist에 등록된 유저 => true / 등록되지 않은 유저 => false ---> !를 붙여서 반대 값으로 에러 발생 (true면 에러 발생)
        require(LuxOnAuthority(luxOnAuthority).isBlacklist(_userAddress) == false, "LuxOnBlacklist: This user is on the blacklist");
        _;
    }

}


// File: contracts/Admin/data/DataAddress.sol


pragma solidity ^0.8.16;


contract DspDataAddress is Ownable {

    event SetDataAddress(string indexed name, address indexed dataAddress, bool indexed isValid);

    struct DataAddressInfo {
        string name;
        address dataAddress;
        bool isValid;
    }

    mapping(string => DataAddressInfo) private dataAddresses;

    function getDataAddress(string memory _name) public view returns (address) {
        require(dataAddresses[_name].isValid, "this data address is not valid");
        return dataAddresses[_name].dataAddress;
    }

    function setDataAddress(DataAddressInfo memory _dataAddressInfo) external onlyOwner {
        dataAddresses[_dataAddressInfo.name] = _dataAddressInfo;
        emit SetDataAddress(_dataAddressInfo.name, _dataAddressInfo.dataAddress, _dataAddressInfo.isValid);
    }

    function setDataAddresses(DataAddressInfo[] memory _dataAddressInfos) external onlyOwner {
        for (uint256 i = 0; i < _dataAddressInfos.length; i++) {
            dataAddresses[_dataAddressInfos[i].name] = _dataAddressInfos[i];
            emit SetDataAddress(_dataAddressInfos[i].name, _dataAddressInfos[i].dataAddress, _dataAddressInfos[i].isValid);
        }
    }
}
// File: contracts/LUXON/utils/LuxOnData.sol


pragma solidity ^0.8.16;



contract LuxOnData is Ownable {
    address private luxonData;
    event SetLuxonData(address indexed luxonData);

    constructor(
        address _luxonData
    ) {
        luxonData = _luxonData;
    }

    function getLuxOnData() public view returns (address) {
        return luxonData;
    }

    function setLuxOnData(address _luxonData) external onlyOwner {
        luxonData = _luxonData;
        emit SetLuxonData(_luxonData);
    }

    function getDataAddress(string memory _name) public view returns (address) {
        return DspDataAddress(luxonData).getDataAddress(_name);
    }
}
// File: contracts/Admin/LuxOnAdmin.sol


pragma solidity ^0.8.16;


contract LuxOnAdmin is Ownable {

    mapping(string => mapping(address => bool)) private _superOperators;

    event SuperOperator(string operator, address superOperator, bool enabled);

    function setSuperOperator(string memory operator, address[] memory _operatorAddress, bool enabled) external onlyOwner {
        for (uint256 i = 0; i < _operatorAddress.length; i++) {
            _superOperators[operator][_operatorAddress[i]] = enabled;
            emit SuperOperator(operator, _operatorAddress[i], enabled);
        }
    }

    function isSuperOperator(string memory operator, address who) public view returns (bool) {
        return _superOperators[operator][who];
    }
}
// File: contracts/LUXON/utils/LuxOnSuperOperators.sol


pragma solidity ^0.8.16;



contract LuxOnSuperOperators is Ownable {

    event SetLuxOnAdmin(address indexed luxOnAdminAddress);
    event SetOperator(string indexed operator);

    address private luxOnAdminAddress;
    string private operator;

    constructor(
        string memory _operator,
        address _luxOnAdminAddress
    ) {
        operator = _operator;
        luxOnAdminAddress = _luxOnAdminAddress;
    }

    modifier onlySuperOperator() {
        require(LuxOnAdmin(luxOnAdminAddress).isSuperOperator(operator, msg.sender), "LuxOnSuperOperators: not super operator");
        _;
    }

    function getLuxOnAdmin() public view returns (address) {
        return luxOnAdminAddress;
    }

    function getOperator() public view returns (string memory) {
        return operator;
    }

    function setLuxOnAdmin(address _luxOnAdminAddress) external onlyOwner {
        luxOnAdminAddress = _luxOnAdminAddress;
        emit SetLuxOnAdmin(_luxOnAdminAddress);
    }

    function setOperator(string memory _operator) external onlyOwner {
        operator = _operator;
        emit SetOperator(_operator);
    }

    function isSuperOperator(address spender) public view returns (bool) {
        return LuxOnAdmin(luxOnAdminAddress).isSuperOperator(operator, spender);
    }
}
// File: contracts/Admin/data/DspCharacterControlStorage.sol


pragma solidity ^0.8.18;



contract DspCharacterControlStorage is LuxOnSuperOperators {
    event SetMintListBefore(address indexed userAddress, uint256 indexed characterId, string indexed characterName);
    event SetMintListAfter(address indexed userAddress, uint256 indexed characterId, uint256 indexed tokenId, string characterName);
    event SetRoot(uint256 indexed round, bytes32 indexed root);
    event MintCharacter(address indexed userAddress, uint256 indexed characterId, uint256 indexed tokenId, string characterName, uint256 round);
    event SetBurn(address indexed userAddress, uint256 indexed characterId, uint256 indexed tokenId);

    constructor(
        string memory operator,
        address luxOnAdmin
    ) LuxOnSuperOperators(operator, luxOnAdmin) {}

    // user address => character id => true / false
    mapping(address => mapping(uint256 => CharacterInfo)) public mintList;

    mapping(uint256 => bytes32) public rootList;

    function getRoot(uint256 _round) public view returns (bytes32) {
        return rootList[_round];
    }

    function setRoot(CharacterDecentralizationRoot memory _characterDecentralizationRoot) external onlySuperOperator {
        rootList[_characterDecentralizationRoot.round] = _characterDecentralizationRoot.root;
        emit SetRoot(_characterDecentralizationRoot.round, _characterDecentralizationRoot.root);
    }

    function setRootList(CharacterDecentralizationRoot[] memory _characterDecentralizationRoots) external onlySuperOperator {
        for (uint256 i = 0; i < _characterDecentralizationRoots.length; i++) {
            rootList[_characterDecentralizationRoots[i].round] = _characterDecentralizationRoots[i].root;
            emit SetRoot(_characterDecentralizationRoots[i].round, _characterDecentralizationRoots[i].root);
        }
    }

    function getMintList(address userAddress, uint256 characterId) public view returns (string memory, uint256, bool) {
        return (mintList[userAddress][characterId].characterName, mintList[userAddress][characterId].tokenId, mintList[userAddress][characterId].isValid);
    }

    function setBurn(address userAddress, uint256 characterId, uint256 tokenId) external onlySuperOperator {
        mintList[userAddress][characterId].tokenId = tokenId;
        mintList[userAddress][characterId].isValid = true;
        emit SetBurn(userAddress, characterId, tokenId);
    }

    function setMintListBefore(address userAddress, uint256 characterId, string memory characterName) external onlySuperOperator {
        mintList[userAddress][characterId] = CharacterInfo(characterName, 0, true);
        emit SetMintListBefore(userAddress, characterId, characterName);
    }

    function deleteMintList(address userAddress, uint256 characterId) external onlySuperOperator {
        delete mintList[userAddress][characterId];
    }

    function setMintListAfter(address userAddress, uint256 characterId, uint256 tokenId) external onlySuperOperator {
        mintList[userAddress][characterId].tokenId = tokenId;
        mintList[userAddress][characterId].isValid = false;
        emit SetMintListAfter(userAddress, characterId, tokenId, mintList[userAddress][characterId].characterName);
    }

    function mintCharacter(uint256 _tokenId, CharacterDecentralizationInfo memory _characterDecentralizationInfo) external onlySuperOperator {
        require(verifyClaim(_characterDecentralizationInfo), "invalid proof");
        require(!mintList[_characterDecentralizationInfo.userAddress][_characterDecentralizationInfo.characterId].isValid, "round : already claimed");

        mintList[_characterDecentralizationInfo.userAddress][_characterDecentralizationInfo.characterId].characterName = _characterDecentralizationInfo.characterName;
        mintList[_characterDecentralizationInfo.userAddress][_characterDecentralizationInfo.characterId].tokenId = _tokenId;
        mintList[_characterDecentralizationInfo.userAddress][_characterDecentralizationInfo.characterId].isValid = true;

        emit MintCharacter(_characterDecentralizationInfo.userAddress, _characterDecentralizationInfo.characterId, _tokenId, _characterDecentralizationInfo.characterName, _characterDecentralizationInfo.round);
    }

    function verifyClaim(
        CharacterDecentralizationInfo memory _characterDecentralizationInfo
    ) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_characterDecentralizationInfo.userAddress, _characterDecentralizationInfo.characterId, _characterDecentralizationInfo.characterName, _characterDecentralizationInfo.reason, _characterDecentralizationInfo.characterType));
        return verifyProof(_characterDecentralizationInfo.userProof, rootList[_characterDecentralizationInfo.round], leaf);
    }


    function verifyProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    function processProof(bytes32[] memory proof, bytes32 leaf)
    internal
    pure
    returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }
        return computedHash;
    }
}
// File: contracts/Admin/data/Erc721RealOwnerData.sol


pragma solidity ^0.8.18;


contract Erc721RealOwnerData is LuxOnSuperOperators {
    event SetRealOwner(address indexed tokenAddress, uint256 indexed tokenId, address indexed realOwner);

    constructor(
        string memory operator,
        address luxOnAdmin
    ) LuxOnSuperOperators(operator, luxOnAdmin) {}

    // token address => token id => onwer
    mapping(address => mapping(uint256 => address)) private realOwner;

    function getRealOwner(address _tokenAddress, uint256 _tokenId) public view returns (address) {
        return realOwner[_tokenAddress][_tokenId];
    }

    function setRealOwner(address _tokenAddress, uint256 _tokenId, address _realOwner) external onlySuperOperator {
        realOwner[_tokenAddress][_tokenId] = _realOwner;
        emit SetRealOwner(_tokenAddress, _tokenId, _realOwner);
    }

    function setRealOwners(address _tokenAddress, uint256[] memory _tokenIds, address _realOwner) external onlySuperOperator {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            realOwner[_tokenAddress][_tokenIds[i]] = _realOwner;
            emit SetRealOwner(_tokenAddress, _tokenIds[i], _realOwner);
        }
    }
}
// File: contracts/LUXON/myPage/centralization/DspCharacterCentralizationCenter.sol


pragma solidity ^0.8.18;









contract DspCharacterCentralizationCenter is LuxOnSuperOperators, LuxOnLive, LuxOnData, LuxOnBlacklist {

    event Centralization(address indexed owner, address indexed tokenAddress, uint256 indexed tokenId, address previousOwner, address msgSender);
    event Decentralization(address indexed owner, address indexed tokenAddress, uint256 indexed tokenId, address previousOwner, address msgSender);
    event MintDspCharacter(address indexed userAddress, address indexed tokenAddress, uint256 indexed tokenId, uint256 characterId);

    string public luxOnCenter = "LuxOnCenter";
    string public erc721RealOwnerData = "Erc721RealOwnerData";
    string public dspCharacter = "LCT";
    string public dspCharacterControlStorage = "DspCharacterControlStorage";

    constructor(
        address dataAddress,
        string memory operator,
        address luxOnAdmin,
        address luxOnService,
        address luxonAuthority
    ) LuxOnData(dataAddress) LuxOnSuperOperators(operator, luxOnAdmin) LuxOnLive(luxOnService) LuxOnBlacklist(luxonAuthority){}

    function deposit(address from, uint256 _tokenId) external isLive isBlacklist(msg.sender){
        address dspCharacterAddress = getDataAddress(dspCharacter);
        require(
            (from == msg.sender && msg.sender == IERC721LUXON(dspCharacterAddress).ownerOf(_tokenId)) ||
            isSuperOperator(msg.sender),
            "Not owner this token id"
        );
        IERC721LUXON(dspCharacterAddress).transferFrom(from, getDataAddress(luxOnCenter), _tokenId);
        address previousOwner = Erc721RealOwnerData(getDataAddress(erc721RealOwnerData)).getRealOwner(dspCharacterAddress, _tokenId);
        Erc721RealOwnerData(getDataAddress(erc721RealOwnerData)).setRealOwner(dspCharacterAddress, _tokenId, from);
        emit Centralization(from, dspCharacterAddress, _tokenId, previousOwner, msg.sender);
    }

    function depositMany(address from, uint256[] memory _tokenIds) external isLive isBlacklist(msg.sender){
        address dspCharacterAddress = getDataAddress(dspCharacter);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                (from == msg.sender && msg.sender == IERC721LUXON(dspCharacterAddress).ownerOf(_tokenIds[i])) ||
                isSuperOperator(msg.sender),
                "Not owner this token id"
            );
            IERC721LUXON(dspCharacterAddress).transferFrom(from, getDataAddress(luxOnCenter), _tokenIds[i]);
            address previousOwner = Erc721RealOwnerData(getDataAddress(erc721RealOwnerData)).getRealOwner(dspCharacterAddress, _tokenIds[i]);
            Erc721RealOwnerData(getDataAddress(erc721RealOwnerData)).setRealOwner(dspCharacterAddress, _tokenIds[i], from);
            emit Centralization(from, dspCharacterAddress, _tokenIds[i], previousOwner, msg.sender);
        }
    }

    function withdraw(address to, uint256 _tokenId) external isLive isBlacklist(msg.sender){
        address dspCharacterAddress = getDataAddress(dspCharacter);
        address previousOwner = Erc721RealOwnerData(getDataAddress(erc721RealOwnerData)).getRealOwner(dspCharacterAddress, _tokenId);
        require(
            (to == msg.sender && msg.sender == previousOwner) ||
            isSuperOperator(msg.sender),
            "Not real owner this token id"
        );

        IERC721LUXON(dspCharacterAddress).transferFrom(getDataAddress(luxOnCenter), to, _tokenId);
        Erc721RealOwnerData(getDataAddress(erc721RealOwnerData)).setRealOwner(dspCharacterAddress, _tokenId, address(0));
        emit Decentralization(to, dspCharacterAddress, _tokenId, previousOwner, msg.sender);
    }

    function withdrawMany(address to, uint256[] memory _tokenIds) external isLive isBlacklist(msg.sender){
        address dspCharacterAddress = getDataAddress(dspCharacter);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            address previousOwner = Erc721RealOwnerData(getDataAddress(erc721RealOwnerData)).getRealOwner(dspCharacterAddress, _tokenIds[i]);
            require(
                (to == msg.sender && msg.sender == previousOwner) ||
                isSuperOperator(msg.sender),
                "Not real owner this token id"
            );

            IERC721LUXON(dspCharacterAddress).transferFrom(getDataAddress(luxOnCenter), to, _tokenIds[i]);
            Erc721RealOwnerData(getDataAddress(erc721RealOwnerData)).setRealOwner(dspCharacterAddress, _tokenIds[i], address(0));
            emit Decentralization(to, dspCharacterAddress, _tokenIds[i], previousOwner, msg.sender);
        }
    }

    function mintDspCharacter(address to, CharacterDecentralizationInfo memory _characterDecentralizationInfo) external isLive isBlacklist(msg.sender){
        require(to == msg.sender || isSuperOperator(msg.sender), "Not real owner this token id");
        address dspCharacterAddress = getDataAddress(dspCharacter);
        string[] memory characterNames = new string[](1);
        characterNames[0] = _characterDecentralizationInfo.characterName;
        IERC721LUXON(dspCharacterAddress).mintByCharacterName(msg.sender, 1, characterNames);
        uint256 lastTokenId = IERC721LUXON(dspCharacterAddress).nextTokenId() - 1;

        DspCharacterControlStorage(getDataAddress(dspCharacterControlStorage)).mintCharacter(lastTokenId, _characterDecentralizationInfo);

        emit MintDspCharacter(msg.sender, dspCharacterAddress, lastTokenId, _characterDecentralizationInfo.characterId);
    }

    function mintDspCharacters(address to, CharacterDecentralizationInfo[] memory _characterDecentralizationInfo) external isLive isBlacklist(msg.sender){
        require(to == msg.sender || isSuperOperator(msg.sender), "Not real owner this token id");
        address dspCharacterAddress = getDataAddress(dspCharacter);

        string[] memory characterNames = new string[](_characterDecentralizationInfo.length);
        uint256 count = _characterDecentralizationInfo.length;

        for (uint256 i = 0; i < count; i++) {
            characterNames[i] = _characterDecentralizationInfo[i].characterName;
        }
        IERC721LUXON(dspCharacterAddress).mintByCharacterName(msg.sender, count, characterNames);
        uint256 lastTokenId = IERC721LUXON(dspCharacterAddress).nextTokenId() - 1;

        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = lastTokenId - count + i + 1;
            DspCharacterControlStorage(getDataAddress(dspCharacterControlStorage)).mintCharacter(tokenId, _characterDecentralizationInfo[i]);
            emit MintDspCharacter(msg.sender, dspCharacterAddress, tokenId, _characterDecentralizationInfo[i].characterId);
        }
    }
}