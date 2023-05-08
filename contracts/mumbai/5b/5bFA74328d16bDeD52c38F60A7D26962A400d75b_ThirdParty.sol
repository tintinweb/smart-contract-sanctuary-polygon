// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ThirdParty {
    struct Category {
        uint categoryID;
        string cartegoryName;
        uint[] properties;
        bool visible;
    }
    uint categoryCounter;

    struct Package {
        uint categoryID;
        uint packageID;
        string packageName;
        uint price;
        uint period;
        uint dataLimit;
        bool[] propertyVisible;
    }
    uint packageCounter;

    struct Property {
        uint propertyID;
        string propertyName;
    }
    uint propertyCounter;

    Category[] allCategories;

    // all packages by category ID
    mapping(uint => Package[]) allPackages;

    // all properties
    mapping(uint256 => Property) properties;

    // Categories
    function getAllCategories() external view returns (Category[] memory) {
        Category[] memory allCates = new Category[](categoryCounter);
        for (uint i = 0; i < categoryCounter; i++) {
            allCates[i] = allCategories[i];
        }
        return allCates;
    }

    function addCategory(string memory _newCategory, uint[] memory _properties) external {
        allCategories.push(Category(categoryCounter++, _newCategory, _properties, true));
    }

    function editCategory(uint _categoryID, string memory _editCategory, uint[] memory _properties) external {
        Category storage cartegory = allCategories[_categoryID];
        cartegory.cartegoryName = _editCategory;
        cartegory.properties = _properties;
    }

    function deleteCategory(uint _categoryID) external {
        delete allCategories[_categoryID];
        delete allPackages[_categoryID];
    }

    function getProperties() external view returns (Property[] memory) {
        Property[] memory allProperties;

        uint256 j = 0;
        for (uint256 i = 0; i < propertyCounter; i++) {
            Property storage temp_property = properties[i];
            if (isCompare(temp_property.propertyName, '') != true) {
                allProperties[j++] = temp_property;
            }
        }
        return allProperties;
    }

    // Property
    function addProperty(string memory _propertyName) external {
        // Check that the property name is not empty
        require(bytes(_propertyName).length > 0, 'property name cannot be empty');

        // Check that the property does not already exist
        for (uint256 i = 0; i < propertyCounter; i++) {
            require(!isCompare(properties[i].propertyName, _propertyName), 'property already exists');
        }

        Property storage _properties = properties[propertyCounter];

        _properties.propertyID = propertyCounter;
        _properties.propertyName = _propertyName;

        propertyCounter++;
    }

    function editProperty(uint _propertyID, string memory _propertyName) external {
        properties[_propertyID].propertyName = _propertyName;
    }

    function deleteProperty(uint _propertyID) external {
        delete properties[_propertyID];
    }

    // Packages
    function getPackagesByCategory(uint _categoryID) external view returns (Package[] memory) {
        Package[] memory packages = new Package[](allPackages[_categoryID].length);
        for (uint i = 0; i < allPackages[_categoryID].length; i++) {
            packages[i] = allPackages[_categoryID][i];
        }
        return packages;
    }

    function addPackage(
        uint _categoryID,
        string memory _packageName,
        uint _price,
        uint _period,
        uint _dataLimit,
        bool[] memory _propertyVisible
    ) external {
        allPackages[_categoryID].push(
            Package(_categoryID, packageCounter++, _packageName, _price, _period, _dataLimit, _propertyVisible)
        );
    }

    function editPackage(
        uint _categoryID,
        uint _packageID,
        string memory _packageName,
        uint _price,
        uint _period,
        uint _dataLimit,
        bool[] memory _propertyVisible
    ) external {
        Package[] storage packagesByCategory = allPackages[_categoryID];

        for (uint i = 0; i < packagesByCategory.length; i++) {
            if (packagesByCategory[i].packageID == _packageID) {
                packagesByCategory[i].packageName = _packageName;
                packagesByCategory[i].price = _price;
                packagesByCategory[i].period = _period;
                packagesByCategory[i].dataLimit = _dataLimit;
                packagesByCategory[i].propertyVisible = _propertyVisible;
            }
        }
    }

    function deletePackage(uint _categoryID, uint _packageID) external {
        Package[] storage packagesByCategory = allPackages[_categoryID];

        for (uint i = 0; i < packagesByCategory.length; i++) {
            if (packagesByCategory[i].packageID == _packageID) {
                delete packagesByCategory[i];
            }
        }
    }

    function isCompare(string memory a, string memory b) private pure returns (bool) {
        if (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b))) {
            return true;
        } else {
            return false;
        }
    }
}