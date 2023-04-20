/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

// File: contracts/web3cert/interfaces/IWeb3CertAttributeRegistry.sol


pragma solidity ^0.8.17;

interface IWeb3CertAttributeRegistry {

    struct Category {
        uint256 id;
        CategoryItem value;
    }

    struct EntityType {
        uint256 id;
        EntityTypeItem value;
    } 
    
    struct CategoryItem {
        string name;
        string description;
        uint256 date;
        uint256 validTo;
    }

    struct EntityTypeItem {
        string name;
        string description;
        uint256 date;
        uint256 validTo;
        uint256[] expectedResources;
    }

    function resourceCategories() external view returns (Category[] memory);

    function resourceCategoriesOfBatch(uint256[] calldata _ids) external view returns (Category[] memory);

    function artifactCategories() external view returns (Category[] memory);

    function artifactCategoriesOfBatch(uint256[] calldata _ids) external view returns (Category[] memory);    

    function entityTypes() external view returns (EntityType[] memory);

    function entityTypesOfBatch(uint256[] calldata _ids) external view returns (EntityType[] memory);     

    function getResourceCategory (uint256 _id) external view returns (CategoryItem memory); 

    function getArtifactCategory (uint256 _id) external view returns (CategoryItem memory);   

    function getEntityType(uint256 _id) external view returns (EntityTypeItem memory);

    function getEntityTypeResources(uint256 _id) external view returns (uint256[] memory);

    function isValidArtifactCategory (uint256 _id) external view returns (bool);

    function isValidResourceCategory (uint256 _id) external view returns (bool);

    function isValidEntityType (uint256 _id) external view returns (bool);    

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
    mapping(uint256 => CategoryItem) private _artifactCategories;

    // supported categories for media resources
    mapping(uint256 => CategoryItem) private _resourceCategories;

    // supported categories for media entity (business element of the web3cert)
    mapping(uint256 => EntityTypeItem) private _entityTypes;

    uint256[] private _resourceCategoriesList;

    uint256[] private _artifactCategoriesList;

    uint256[] private _entityTypesList;    

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

    function addResourceCategory(uint256 _id, string calldata _name, string calldata _description, uint256 _validTo) external onlyOwner {
        require(_id > 0, "invalid id");        
        require(bytes(_name).length > 0, "empty name");
        require(_resourceCategories[_id].date == 0, "already registered");
        _resourceCategories[_id].name = _name;
        _resourceCategories[_id].description = _description;
        _resourceCategories[_id].date = block.timestamp;
        _resourceCategories[_id].validTo = _validTo;
        _resourceCategoriesList.push(_id);
    }

    function updateResourceCategory(uint256 _id, string calldata _name, string calldata _description, uint256 _validTo) external onlyOwner {
        require(_resourceCategories[_id].date > 0, "not registered");
        require(bytes(_name).length > 0, "empty name");
        _resourceCategories[_id].name = _name;
        _resourceCategories[_id].description = _description;
        _resourceCategories[_id].date = block.timestamp;
        _resourceCategories[_id].validTo = _validTo;
    }      

    function addArtifactCategory(uint256 _id, string calldata _name, string calldata _description, uint256 _validTo) external onlyOwner {
        require(_id > 0, "invalid id");        
        require(bytes(_name).length > 0, "empty name");
        require(_artifactCategories[_id].date == 0, "already registered");
        _artifactCategories[_id].name = _name;
        _artifactCategories[_id].description = _description;
        _artifactCategories[_id].date = block.timestamp;
        _artifactCategories[_id].validTo = _validTo;
        _artifactCategoriesList.push(_id);
    }

    function updateArtifactCategory(uint256 _id, string calldata _name, string calldata _description, uint256 _validTo) external onlyOwner {
        require(_artifactCategories[_id].date > 0, "not registered");
        require(bytes(_name).length > 0, "empty name");
        _artifactCategories[_id].name = _name;
        _artifactCategories[_id].description = _description;
        _artifactCategories[_id].date = block.timestamp;
        _artifactCategories[_id].validTo = _validTo;
    }    


    function addEntityType(uint256 _id, string calldata _name, string calldata _description, uint256 _validTo, uint256[] calldata _expectedResources) external onlyOwner {
        require(_id > 0, "invalid id");
        require(_expectedResources.length > 0, "empty resources");
        require(bytes(_name).length > 0, "empty name");
        require(_entityTypes[_id].date == 0, "already registered");
        _entityTypes[_id].name = _name;
        _entityTypes[_id].description = _description;
        _entityTypes[_id].date = block.timestamp;
        _entityTypes[_id].validTo = _validTo;
        _entityTypes[_id].expectedResources = _expectedResources;
        _entityTypesList.push(_id);
    }

    function updateEntityType(uint256 _id, string calldata _name, string calldata _description, uint256 _validTo, uint256[] calldata _expectedResources) external onlyOwner {
        require(_entityTypes[_id].date > 0, "not registered");
        require(_expectedResources.length > 0, "empty resources");        
        require(bytes(_name).length > 0, "empty name");            
        _entityTypes[_id].name = _name;
        _entityTypes[_id].description = _description;
        _entityTypes[_id].date = block.timestamp;
        _entityTypes[_id].validTo = _validTo;
        _entityTypes[_id].expectedResources = _expectedResources;
    }      

    function invalidateArtifactCategory (uint256 _id) external onlyOwner {
        require(_artifactCategories[_id].date > 0, "not registered");
        require(_artifactCategories[_id].validTo == 0 || _artifactCategories[_id].validTo > block.timestamp, "already invalidated");
        _artifactCategories[_id].validTo = block.timestamp;
    }

    function invalidateResourceCategory (uint256 _id) external onlyOwner {
        require(_resourceCategories[_id].date > 0, "not registered");
        require(_resourceCategories[_id].validTo == 0 || _resourceCategories[_id].validTo > block.timestamp, "already invalidated");
        _resourceCategories[_id].validTo = block.timestamp;
    }

    function invalidateEntityType (uint256 _id) external onlyOwner {
        require(_entityTypes[_id].date > 0, "not registered");
        require(_entityTypes[_id].validTo == 0 || _entityTypes[_id].validTo > block.timestamp, "already invalidated");
        _entityTypes[_id].validTo = block.timestamp;
    }    

    function resourceCategories() external override view returns (Category[] memory) {
        Category[] memory res = new Category[](_resourceCategoriesList.length);
        for (uint256 i = 0; i < _resourceCategoriesList.length; i++) {
            res[i] = Category (_resourceCategoriesList[i], _resourceCategories[_resourceCategoriesList[i]]);
        }
        return res;
    }

    function artifactCategories() external override view returns (Category[] memory) {
        Category[] memory res = new Category[](_artifactCategoriesList.length);
        for (uint256 i = 0; i < _artifactCategoriesList.length; i++) {
            res[i] =  Category(_artifactCategoriesList[i], _artifactCategories[_artifactCategoriesList[i]]);
        }
        return res;
    }

    function entityTypes() external override view returns (EntityType[] memory) {
        EntityType[] memory res = new EntityType[](_entityTypesList.length);
        for (uint256 i = 0; i < _entityTypesList.length; i++) {
            res[i] =  EntityType(_entityTypesList[i], _entityTypes[_entityTypesList[i]]);
        }
        return res;
    }    

    function resourceCategoriesOfBatch(uint256[] calldata _ids) external view returns (Category[] memory){
        Category[] memory batch = new Category[](_ids.length);
        for (uint256 i = 0; i < _ids.length; ++i) {
            batch[i] = Category(_ids[i], _resourceCategories[_ids[i]]);
        }
        return batch;
    }

    function artifactCategoriesOfBatch(uint256[] calldata _ids) external view returns (Category[] memory){
        Category[] memory batch = new Category[](_ids.length);
        for (uint256 i = 0; i < _ids.length; ++i) {
            batch[i] = Category(_ids[i], _artifactCategories[_ids[i]]);
        }
        return batch;
    }

    function entityTypesOfBatch(uint256[] calldata _ids) external view returns (EntityType[] memory){
        EntityType[] memory batch = new EntityType[](_ids.length);
        for (uint256 i = 0; i < _ids.length; ++i) {
            batch[i] = EntityType(_ids[i], _entityTypes[_ids[i]]);
        }
        return batch;
    }        

    function getResourceCategory(uint256 _id) external override view returns (CategoryItem memory) {
        require(_resourceCategories[_id].date > 0, "not registered");
        return _resourceCategories[_id];
    }

    function getArtifactCategory(uint256 _id) external override view returns (CategoryItem memory) {
        require(_artifactCategories[_id].date > 0, "not registered");
        return _artifactCategories[_id];
    }

    function getEntityType(uint256 _id) external view returns (EntityTypeItem memory) {
        require(_entityTypes[_id].date > 0, "not registered");
        return _entityTypes[_id];
    }

    function getEntityTypeResources(uint256 _id) external view returns (uint256[] memory) {
        return _entityTypes[_id].expectedResources;
    }    

    function isValidArtifactCategory (uint256 _id) external view returns (bool) {
        return _artifactCategories[_id].date > 0 && (_artifactCategories[_id].validTo == 0 || _artifactCategories[_id].validTo > block.timestamp);
    }

    function isValidResourceCategory (uint256 _id) external view returns (bool) {
        return _resourceCategories[_id].date > 0 && (_resourceCategories[_id].validTo == 0 || _resourceCategories[_id].validTo > block.timestamp);
    }

    function isValidEntityType (uint256 _id) external view returns (bool) {
        return _entityTypes[_id].date > 0 && (_entityTypes[_id].validTo == 0 || _entityTypes[_id].validTo > block.timestamp);
    }    

    function owner() public view virtual returns (address) {
        return _owner;
    }
}