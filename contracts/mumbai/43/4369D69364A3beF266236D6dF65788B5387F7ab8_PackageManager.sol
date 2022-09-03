// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract PackageManager {
    struct Package {
        address owner;
        mapping(string => string) versionToDataHash;
    }

    event PackageCreated(address owner, string pkgName);
    event PackageVersionCreated(
        string pkgName,
        string versionName,
        string dataHash
    );

    mapping(string => Package) public nameToPackage;

    modifier onlyPackageOwner(string memory packageName) {
        address packageOwner = nameToPackage[packageName].owner;
        require(msg.sender == packageOwner, "sender is not owner of package");
        _;
    }

    modifier onlyPackageNotExist(string memory packageName) {
        address packageOwner = nameToPackage[packageName].owner;
        require(address(0) == packageOwner, "package already exist");
        _;
    }

    modifier onlyVersionNotExist(
        string memory packageName,
        string memory version
    ) {
        string memory dataHash = nameToPackage[packageName].versionToDataHash[
            version
        ];
        require(bytes(dataHash).length == 0, "version already exist");
        _;
    }

    function createPackage(string memory packageName)
        public
        onlyPackageNotExist(packageName)
    {
        nameToPackage[packageName].owner = msg.sender;
        emit PackageCreated(msg.sender, packageName);
    }

    function releaseNewVersion(
        string memory packageName,
        string memory versionName,
        string memory dataHash
    )
        public
        onlyPackageOwner(packageName)
        onlyVersionNotExist(packageName, versionName)
    {
        require(
            bytes(dataHash).length != 0,
            "data hash cannot be empty string"
        );
        nameToPackage[packageName].versionToDataHash[versionName] = dataHash;
        emit PackageVersionCreated(packageName, versionName, dataHash);
    }
}