/**
 *Submitted for verification at polygonscan.com on 2023-03-02
*/

// File: contracts/web3cert/interfaces/IWeb3CertAttributeRegistry.sol


pragma solidity ^0.8.17;

interface IWeb3CertAttributeRegistry {

    struct CategoryEntry {
        uint256 id;
        Category entity;
    }

    struct Category {
        string name;
        string description;
        uint256 validFrom;
        uint256 validTo;
    }

    function addResourceCategory(uint256 _id, string calldata _name, string calldata _description, uint256 _validTo) external;

    function addArtifactCategory(uint256 _id, string calldata _name, string calldata _description, uint256 _validTo) external;

    function getResourceCategories() external view returns (CategoryEntry[] memory);

    function getArtifactCategories() external view returns (CategoryEntry[] memory);

    function getResourceCategory(uint256 _id) external view returns (Category memory); 

    function getArtifactCategory(uint256 _id) external view returns (Category memory);    

    function isValidArtifactCategory (uint256 _id) external view returns (bool);

    function isValidResourceCategory (uint256 _id) external view returns (bool);

    function invalidateArtifactCategory (uint256 _id) external;

    function invalidateResourceCategory (uint256 _id) external;    
}

// File: contracts/web3cert/Web3CertAttributeRegistry.sol


pragma solidity ^0.8.17;


/**
 * @title Contract to handle mapping between attribute id and details
 */
contract Web3CertAttributeRegistry is IWeb3CertAttributeRegistry{

    // owner
    address private _owner;

    // supported categories for features
    mapping(uint256 => Category) private _artifactCategories;

    uint256[] private _artifactCategoriesList;

    // supported categories for media resources
    mapping(uint256 => Category) private _resourceCategories;

    uint256[] private _resourceCategoriesList;

    modifier onlyOwner() {
        require(owner() == msg.sender, "not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function setOwner(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "zero address");
        _owner = newOwner;
    }

    function addResourceCategory(uint256 _id, string calldata _name, string calldata _description, uint256 _validTo) external override  onlyOwner {
        require(bytes(_name).length > 0, "empty name");
        require(_resourceCategories[_id].validFrom == 0, "already registered");
        _resourceCategories[_id].name = _name;
        _resourceCategories[_id].description = _description;
        _resourceCategories[_id].validFrom = block.timestamp;
        _resourceCategories[_id].validTo = _validTo;
        _resourceCategoriesList.push(_id);
    }

    function addArtifactCategory(uint256 _id, string calldata _name, string calldata _description, uint256 _validTo) external override onlyOwner {
        require(bytes(_name).length > 0, "empty name");
        require(_artifactCategories[_id].validFrom == 0, "already registered");
        _artifactCategories[_id].name = _name;
        _artifactCategories[_id].description = _description;
        _artifactCategories[_id].validFrom = block.timestamp;
        _artifactCategories[_id].validTo = _validTo;
        _artifactCategoriesList.push(_id);
    }

    function invalidateArtifactCategory (uint256 _id) external override onlyOwner {
        require(_artifactCategories[_id].validFrom > 0, "not registered");
        require(_artifactCategories[_id].validTo > block.timestamp, "already invalidated");
        _artifactCategories[_id].validTo = block.timestamp;
    }

    function invalidateResourceCategory (uint256 _id) external override onlyOwner {
        require(_resourceCategories[_id].validFrom > 0, "not registered");
        require(_resourceCategories[_id].validTo > block.timestamp, "already invalidated");
        _resourceCategories[_id].validTo = block.timestamp;
    }

    function getResourceCategories() external override view returns (CategoryEntry[] memory) {
        CategoryEntry[] memory res = new CategoryEntry[](_resourceCategoriesList.length);
        for (uint256 i = 0; i < _resourceCategoriesList.length; i++) {
            res[i] = CategoryEntry (_resourceCategoriesList[i], _resourceCategories[_resourceCategoriesList[i]]);
        }
        return res;
    }

    function getArtifactCategories() external override view returns (CategoryEntry[] memory) {
        CategoryEntry[] memory res = new CategoryEntry[](_artifactCategoriesList.length);
        for (uint256 i = 0; i < _artifactCategoriesList.length; i++) {
            res[i] =  CategoryEntry(_artifactCategoriesList[i], _artifactCategories[_artifactCategoriesList[i]]);
        }
        return res;
    }

    function getResourceCategory(uint256 _id) external override view returns (Category memory) {
        require(_resourceCategories[_id].validFrom > 0, "not registered");
        return _resourceCategories[_id];
    }

    function getArtifactCategory(uint256 _id) external override view returns (Category memory) {
        require(_artifactCategories[_id].validFrom > 0, "not registered");
        return _artifactCategories[_id];
    }

    function isValidArtifactCategory (uint256 _id) external view returns (bool) {
        return _artifactCategories[_id].validFrom > 0 && (_artifactCategories[_id].validTo == 0 || _artifactCategories[_id].validTo < block.timestamp);
    }

    function isValidResourceCategory (uint256 _id) external view returns (bool) {
        return _resourceCategories[_id].validFrom > 0 && (_resourceCategories[_id].validTo == 0 || _resourceCategories[_id].validTo < block.timestamp);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
}